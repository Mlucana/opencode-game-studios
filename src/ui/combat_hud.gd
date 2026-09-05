class_name CombatHud
extends CanvasLayer

## HUD de Combate NOVENA — coordinador display-only (hud.md completa).
##
## Escena `CombatHud.tscn`: CanvasLayer layer 10, `follow_viewport_enabled`
## false, `process_mode` ALWAYS (C14: el HUD sigue a 60Hz durante el
## hitstop del mundo). Zonas: `HudVignette` (bordes) + `HudNW` (Vida +
## Gracia, persistente) + `HudNE` (Postura + Vida jefe, solo duelo) +
## `HudS` (Timer castigo, solo Aturdido). Centro 60% siempre libre.
## Budget: 5 simultáneos en duelo, 6 en pico; HUD total ≤15% a 1280x800
## (NW ≤6%, NE ≤6%, S ≤3%); draws UI 1-3.
##
## REGLAS: display-only (nunca posee estado, emite eventos, jamás llama al
## FSM); cero strings hardcodeados (todo vía `tr()`); teclado + mando
## completos, nada depende de hover (`mouse_filter` IGNORE en todo);
## parry DIGITAL (ningún eje analógico mapeable, ver `_verificar_parry_digital`);
## animaciones skippables + reduced-motion (sin shake/vignette pulsante;
## el hitstop se mantiene porque es gameplay del mundo, no de la UI).

## Prioridad visual (hud.md, 6 niveles). Nunca dos flashes en el mismo
## tick: el de menor prioridad se retrasa 1 tick.
enum Prioridad { MUERTE = 1, FALLO = 2, FIRMA_VE = 3, CAIDA_POSTURA = 4, PRELIGHT_VE = 5, TIMER_CONTINUO = 6 }
## Fases de la firma VE (inv. #7, eventos 14-16, V5-V7).
enum FaseVE { CERRADA = 0, PRELIGHT = 1, PARADA = 2, CIERRE_SIN_PARAR = 3 }
## Estados de présentation (hud.md §Dynamic Behaviors).
enum EstadoHUD { COMBATE = 0, PAUSA = 1, HUB = 2, ABSORBER_DECISION = 3, CUTSCENE = 4 }

## Knobs de jugador (hud.md §Tuning Knobs).
@export_range(0.6, 1.0, 0.01) var hud_opacity: float = 1.0:
	set(valor):
		hud_opacity = clampf(valor, 0.6, 1.0)
		_aplicar_opacidad()
@export_range(0.9, 1.15, 0.01) var hud_scale: float = 1.0:
	set(valor):
		hud_scale = clampf(valor, 0.9, 1.15)
		_aplicar_escala()
## Nunca baja la luminancia del timer bajo 4.5:1 (solo sube en Deck).
@export var timer_high_contrast: bool = false:
	set(valor):
		timer_high_contrast = valor
		if is_node_ready() and _hud_s != null:
			_hud_s.set_alto_contraste(valor)
## Fotosensibilidad: sustituye el flash #C75C4A por icono con forma.
@export var disable_damage_flash: bool = false:
	set(valor):
		disable_damage_flash = valor
		_aplicar_modo_flash()
## Reduced-motion: sin vignette pulsante ni shake. Hitstop intacto.
@export var reduced_motion: bool = false:
	set(valor):
		reduced_motion = valor
		_aplicar_reduced_motion()

var _hud_nw: HudNW
var _hud_ne: HudNE
var _hud_s: HudS
var _vignette: HudVignette

var _estado: int = EstadoHUD.COMBATE
var _en_duelo: bool = false
var _fase_ve: int = FaseVE.CERRADA
## Cache de solo-lectura para el readout On Demand (no es estado de juego).
var _cache_vida: float = 100.0
var _cache_vida_max: float = 100.0
var _cache_gracia: int = 0
var _cache_gracia_total: int = 4
var _cache_timer_rest: int = 0
var _cache_timer_total: int = 120
## Latch+hold 2 frames de render anti-40Hz (hud.md Open Questions).
var _hold_cola_ms: int = 0
var _cola_prioridad: int = 0
## Efecto pendiente para RE-DESPACHO real (no solo limpiar cola).
## Guarda el Callable del evento suprimido; _procesar_cola lo ejecuta.
var _cola_efecto: Callable = Callable()
## Supresiones de prioridad (muerte 800ms, fallo suprime firma VE 200ms).
var _supresion_hasta_ms: int = 0
var _suprimido_por: int = 0
var _reloj_ms: int = 0


## Resuelve las zonas hijas y aplica knobs. Sin strings hardcodeados.
func _ready() -> void:
	layer = 10
	follow_viewport_enabled = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hud_nw = get_node_or_null(^"HudNW") as HudNW
	_hud_ne = get_node_or_null(^"HudNE") as HudNE
	_hud_s = get_node_or_null(^"HudS") as HudS
	_vignette = get_node_or_null(^"HudVignette") as HudVignette
	_forzar_mouse_ignore(self)
	# Autodetect Deck para timer_high_contrast (default false → true en Deck
	# sin romper PC): Steam Deck o viewport ≤1300px. Solo auto-sube, nunca baja.
	if not timer_high_contrast and _es_deck():
		timer_high_contrast = true
		if _hud_s != null:
			_hud_s.set_alto_contraste(true)
	_aplicar_opacidad()
	_aplicar_escala()
	_aplicar_modo_flash()
	_aplicar_reduced_motion()
	_aplicar_estado()
	_configurar_foco_lineal()
	_verificar_parry_digital()


## `_process` SEPARADO y exclusivo del readout On Demand
## (`hud_values_exact`): no mezcla lógica event-driven con sondeo.
## Acción digital `hud_values_exact` (Tab / Touchpad / Back según InputMap).
func _process(delta: float) -> void:
	_reloj_ms += int(delta * 1000.0)
	_procesar_cola_retrasada()
	var pide_exacta := false
	if InputMap.has_action(&"hud_values_exact"):
		pide_exacta = Input.is_action_pressed(&"hud_values_exact")
	# En Pausa/Cutscene no hay readout (timer pausado / HUD oculto).
	if _estado == EstadoHUD.PAUSA or _estado == EstadoHUD.CUTSCENE:
		pide_exacta = false
	if _hud_nw != null:
		_hud_nw.set_exact_visible(pide_exacta, _cache_vida, _cache_vida_max, _cache_gracia, _cache_gracia_total)
	if _hud_s != null:
		_hud_s.set_exact_visible(pide_exacta and _hud_s.visible)


# ─── API pública display-only (la llama `HudPresenter`, nunca el FSM) ───

## Vida del jugador (inv. #1). Cambios críticos en 1-2 ticks, sin ease-in.
func set_vida(actual: float, maxima: float) -> void:
	_cache_vida = actual
	_cache_vida_max = maxima
	if _hud_nw != null:
		_hud_nw.set_vida(actual, maxima)
	# Vignette progresiva por vida baja; muerte = tinta total (ev.13).
	if _vignette != null and _estado != EstadoHUD.CUTSCENE:
		if maxima > 0.0:
			var fraccion: float = clampf(actual / maxima, 0.0, 1.0)
			if actual <= 0.0:
				_anunciar(Prioridad.MUERTE, 800)
				_vignette.set_intensidad(1.0)
			elif fraccion < 0.3:
				_vignette.set_intensidad(1.0 - fraccion / 0.3 * 0.6)
			else:
				_vignette.set_intensidad(0.0)


## Gracia / corrupción (inv. #5, propiedad sistema 5). Único vitral.
func set_gracia(encendidas: int, total: int) -> void:
	_cache_gracia = encendidas
	_cache_gracia_total = total
	if _hud_nw != null:
		_hud_nw.set_gracia(encendidas, total)


## Postura (inv. #2). En VE no se llama: la ausencia ES la firma (V6).
## GATEADA por prioridad: si hay supresor activo se encola con tick y se
## re-despacha el efecto real (no solo se limpia la cola).
func set_postura(actual: float, maxima: float) -> void:
	if _fase_ve == FaseVE.PRELIGHT or _fase_ve == FaseVE.PARADA:
		return
	var efecto := Callable(self, "_aplicar_caida_postura").bind(actual, maxima)
	if not _anunciar(Prioridad.CAIDA_POSTURA, 0, efecto):
		return
	_aplicar_caida_postura(actual, maxima)


## Vida del jefe (inv. #3, F6). Solo daño bruto, sin pulso propio.
func set_vida_jefe(actual: float, maxima: float) -> void:
	if _hud_ne != null:
		_hud_ne.set_vida_jefe(actual, maxima)


## Timer castigo 120 ticks (inv. #4, R5). Continuo, fondo, nunca suprime.
func set_timer(restantes: int, total: int) -> void:
	_cache_timer_rest = restantes
	_cache_timer_total = total
	if _estado == EstadoHUD.PAUSA:
		return
	if _hud_s != null and _hud_s.visible:
		_hud_s.set_timer(restantes, total)


## Duelo: muestra/colapsa NE. Hub/entre duelos = solo NW.
func set_en_duelo(en_duelo: bool) -> void:
	_en_duelo = en_duelo
	_aplicar_estado()


## Fallo de parry (inv. #6, evento 5). Flash único, suprime firma VE 200ms.
## Evento lógico ÚNICO NW+vignette con misma prioridad: una sola llamada
## dispara ambos como un evento (gateado y re-despachado junto).
func notificar_fallo() -> void:
	var efecto := Callable(self, "_disparar_flash_fallo")
	if not _anunciar(Prioridad.FALLO, 200, efecto):
		return
	_disparar_flash_fallo()


## Firma VE (inv. #7): Gracia se mueve, Postura no (ev.15). Pre-light (ev.14)
## ilumina Gracia; cierre sin parar (ev.16) repliega la luz.
## PARADA distinguible: MUEVE Gracia (avanza fill/count + prelight off +
## tick de forma) manteniendo Postura idéntica (aquí jamás se toca Postura).
func set_firma_ve(fase: int) -> void:
	_fase_ve = fase
	match fase:
		FaseVE.PRELIGHT:
			var ef_pre := Callable(self, "_aplicar_prelight_ve")
			if not _anunciar(Prioridad.PRELIGHT_VE, 0, ef_pre):
				return
			_aplicar_prelight_ve()
		FaseVE.PARADA:
			var ef_par := Callable(self, "_aplicar_firma_parada")
			if not _anunciar(Prioridad.FIRMA_VE, 0, ef_par):
				return
			_aplicar_firma_parada()
		_:
			if _hud_nw != null:
				_hud_nw.limpiar_firma_ve()
				_hud_nw.set_prelight_ve(false)


## Estados: pausa (atenuado 40%, S oculto, timer pausado, sin vignette
## animada ni rumble) · hub (solo NW) · absorber (solo Gracia en alta
## luminancia) · cutscene (oculto total, retorno por corte 1 tick, sin fade).
func set_estado(estado: int) -> void:
	_estado = estado
	_aplicar_estado()


## Corta animaciones al estado final (skippables + reduced-motion).
## Propagación COMPLETA: HudNW (+Gracia), HudNE (+Postura), HudS, vignette.
func skip_animations() -> void:
	if _hud_nw != null:
		_hud_nw.skip_animations()
	if _hud_ne != null:
		_hud_ne.skip_animations()
	if _hud_s != null:
		_hud_s.skip_animations()
	if _vignette != null:
		_vignette.skip_animations()
	_cola_prioridad = 0
	_cola_efecto = Callable()
	_hold_cola_ms = 0


# ─── Internos ─────────────────────────────────────────────────────────────

func _aplicar_estado() -> void:
	if not is_node_ready():
		return
	var en_combate_real: bool = _estado == EstadoHUD.COMBATE
	# Pausa congela vignette (además de S oculto + timer congelado).
	if _vignette != null:
		_vignette.pausado = (_estado == EstadoHUD.PAUSA)
	match _estado:
		EstadoHUD.PAUSA:
			modulate.a = hud_opacity * 0.4
			if _hud_s != null:
				_hud_s.set_visible_timer(false)
			if _hud_nw != null:
				_hud_nw.visible = true
				_hud_nw.set_modo_decision(false)
			if _hud_ne != null:
				_hud_ne.visible = _en_duelo
		EstadoHUD.HUB:
			# Guarda 4.5:1: opacidad a fondos, críticos opacos (ver _aplicar_opacidad).
			modulate.a = 1.0
			if _hud_nw != null:
				_hud_nw.visible = true
				_hud_nw.set_modo_decision(false)
				_hud_nw.set_opacidad_fondos(hud_opacity)
			if _hud_ne != null:
				_hud_ne.visible = false
				_hud_ne.set_opacidad_fondos(hud_opacity)
			if _hud_s != null:
				_hud_s.set_visible_timer(false)
				_hud_s.set_opacidad_fondos(hud_opacity)
			if _vignette != null:
				_vignette.set_intensidad(0.0)
		EstadoHUD.ABSORBER_DECISION:
			modulate.a = 1.0
			if _hud_nw != null:
				_hud_nw.visible = true
				# SOLO Gracia: oculta VidaBar + labels Vida, alta luminancia.
				_hud_nw.set_modo_decision(true)
				_hud_nw.set_opacidad_fondos(hud_opacity)
			if _hud_ne != null:
				_hud_ne.visible = false
				_hud_ne.set_opacidad_fondos(hud_opacity)
			if _hud_s != null:
				_hud_s.set_visible_timer(false)
				_hud_s.set_opacidad_fondos(hud_opacity)
		EstadoHUD.CUTSCENE:
			visible = true
			modulate.a = 0.0
			for hijo in get_children():
				(hijo as CanvasItem).visible = false
			return
		_:
			# COMBATE: opacidad a fondos, críticos opacos (guarda 4.5:1).
			modulate.a = 1.0
			if _hud_nw != null:
				_hud_nw.set_modo_decision(false)
				_hud_nw.set_opacidad_fondos(hud_opacity)
			if _hud_ne != null:
				_hud_ne.set_opacidad_fondos(hud_opacity)
			if _hud_s != null:
				_hud_s.set_opacidad_fondos(hud_opacity)
	for hijo in get_children():
		(hijo as CanvasItem).visible = true
	if _hud_ne != null:
		_hud_ne.visible = _en_duelo and en_combate_real
	if _hud_s != null and _estado != EstadoHUD.COMBATE:
		_hud_s.set_visible_timer(false)


## Muestra el timer S solo en Aturdido (lo llama el presentador vía duelo/timer).
func mostrar_timer_en_aturdido(en_aturdido: bool) -> void:
	if _estado != EstadoHUD.COMBATE:
		return
	if _hud_s != null:
		_hud_s.set_visible_timer(en_aturdido)


func _anunciar(prioridad: int, suprime_ms: int, efecto: Callable = Callable()) -> bool:
	# Regla: nunca dos flashes en el mismo tick; el de menor prioridad
	# (número mayor) se encola 1 tick (~16ms) y se RE-DESPACHA el efecto
	# real (no solo se limpia la cola). Retorna false = encolado.
	if _reloj_ms < _supresion_hasta_ms and prioridad > _suprimido_por:
		_cola_prioridad = prioridad
		_cola_efecto = efecto
		_hold_cola_ms = 16
		return false
	if suprime_ms > 0:
		_supresion_hasta_ms = _reloj_ms + suprime_ms
		_suprimido_por = prioridad
	return true


func _procesar_cola_retrasada() -> void:
	if _hold_cola_ms > 0:
		_hold_cola_ms -= 16
		if _hold_cola_ms <= 0 and _cola_prioridad > 0:
			var efecto := _cola_efecto
			_cola_prioridad = 0
			_cola_efecto = Callable()
			if efecto.is_valid():
				efecto.call()


## Efecto real de caída de Postura (re-despachable desde la cola).
func _aplicar_caida_postura(actual: float, maxima: float) -> void:
	if _hud_ne != null:
		_hud_ne.set_postura(actual, maxima)


## Evento lógico ÚNICO de fallo: dispara NW + vignette juntos, misma prioridad.
func _disparar_flash_fallo() -> void:
	if _hud_nw != null:
		_hud_nw.flash_fallo()
	if _vignette != null:
		_vignette.flash_fallo()


## Pre-light VE (ev.14): solo contorno de Gracia.
func _aplicar_prelight_ve() -> void:
	if _hud_nw != null:
		_hud_nw.set_prelight_ve(true)


## Firma VE parada (ev.15): MUEVE Gracia, Postura idéntica (no se toca NE).
func _aplicar_firma_parada() -> void:
	if _hud_nw != null:
		_hud_nw.avanzar_firma_ve()


func _aplicar_opacidad() -> void:
	if not is_node_ready():
		return
	if _estado == EstadoHUD.PAUSA:
		# Pausa: atenuado 40% por diseño (S oculto, timer congelado).
		modulate.a = hud_opacity * 0.4
		return
	# Guarda 4.5:1: la opacidad va a FONDOS, nunca a fills/labels críticos
	# (que quedan opacos). El modulate global NO se baja para no fundir
	# contraste (a 0.6, #C7CDD6 fundido = 4.08:1, no pasa; opaco = 8.51:1).
	modulate.a = 1.0
	if _hud_nw != null:
		_hud_nw.set_opacidad_fondos(hud_opacity)
	if _hud_ne != null:
		_hud_ne.set_opacidad_fondos(hud_opacity)
	if _hud_s != null:
		_hud_s.set_opacidad_fondos(hud_opacity)


func _aplicar_escala() -> void:
	if is_node_ready():
		# Guarda 18px aparente: la capa escala barras, las fuentes se
		# compensan a ceil(18/scale) para nunca bajar de 18px aparente.
		scale = Vector2(hud_scale, hud_scale)
		if _hud_nw != null:
			_hud_nw.set_compensacion_fuente(hud_scale)
		if _hud_ne != null:
			_hud_ne.set_compensacion_fuente(hud_scale)
		if _hud_s != null:
			_hud_s.set_compensacion_fuente(hud_scale)


func _aplicar_modo_flash() -> void:
	if not is_node_ready():
		return
	if _vignette != null:
		_vignette.usar_icono_en_vez_de_flash = disable_damage_flash
	if _hud_nw != null:
		_hud_nw.usar_icono_en_vez_de_flash = disable_damage_flash


func _aplicar_reduced_motion() -> void:
	if not is_node_ready():
		return
	if _vignette != null:
		_vignette.reduced_motion = reduced_motion
	if _hud_nw != null:
		_hud_nw.reduced_motion = reduced_motion
	if _hud_ne != null:
		_hud_ne.reduced_motion = reduced_motion
	if _hud_s != null:
		_hud_s.reduced_motion = reduced_motion


## Deck autodetect (sin romper PC): Steam Deck o viewport estrecho ≤1300px.
func _es_deck() -> bool:
	if OS.has_feature("steam_deck"):
		return true
	var ancho := 0.0
	if get_viewport() != null:
		ancho = get_viewport().get_visible_rect().size.x
	if ancho <= 0.0:
		ancho = get_viewport_rect().size.x
	return ancho > 0.0 and ancho <= 1300.0


## Foco mínimo On Demand (no menú): cadena lineal NW → NE → S.
## Solo los readouts exactos son focables; el resto del HUD sigue IGNORE.
func _configurar_foco_lineal() -> void:
	var foco_nw: Control = null
	var foco_ne: Control = null
	var foco_s: Control = null
	if _hud_nw != null:
		foco_nw = _hud_nw.get_exact_focusable()
	if _hud_ne != null:
		foco_ne = _hud_ne.get_focusable()
	if _hud_s != null:
		foco_s = _hud_s.get_exact_focusable()
	if foco_nw != null and foco_ne != null:
		foco_nw.focus_neighbor_bottom = foco_ne.get_path()
		foco_nw.focus_next = foco_ne.get_path()
		foco_ne.focus_neighbor_top = foco_nw.get_path()
		foco_ne.focus_previous = foco_nw.get_path()
	if foco_ne != null and foco_s != null:
		foco_ne.focus_neighbor_bottom = foco_s.get_path()
		foco_ne.focus_next = foco_s.get_path()
		foco_s.focus_neighbor_top = foco_ne.get_path()
		foco_s.focus_previous = foco_ne.get_path()


func _forzar_mouse_ignore(nodo: Node) -> void:
	# Nada depende de hover: todo el HUD es MOUSE_FILTER_IGNORE.
	if nodo is Control:
		(nodo as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for hijo in nodo.get_children():
		_forzar_mouse_ignore(hijo)


## Parry digital (C24): ningún eje analógico puede disparar acciones del
## HUD. Si `hud_values_exact` tuviera un evento de eje, se avisa y se
## ignora ese binding (el HUD sigue con teclado + botones digitales).
func _verificar_parry_digital() -> void:
	if not InputMap.has_action(&"hud_values_exact"):
		return
	for evento in InputMap.action_get_events(&"hud_values_exact"):
		if evento is InputEventJoypadMotion:
			push_warning("HUD: accion hud_values_exact con eje analogico ignorada (C24 parry digital).")

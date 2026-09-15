class_name MenuPausa
extends CanvasLayer

## Overlay Pausa duelo-only — superficie pura M-003 (MENU-04, GDD Menú R5/R6/R7).
##
## Implementa `design/gdd/menu-principal-y-flujo-de-pantallas.md` §States (fila
## Pausa) + UI Requirements (fila Pausa) + historia
## `production/epics/menu-principal/story-m003-pausa-muerte-hub.md` AC MENU-04.
## Espeja la disciplina modal de `decision_gracia.gd` (consume + swallow 200ms,
## focus trap + restore, foco 2px sin glow, dual-focus, todo `tr()`, audio por
## bus) sin duplicar su lógica: esta es la overlay de pausa, aquella la de Decisión.
##
## CONTRATO DISPLAY-Only (`ui-code.md`): nunca posee ni modifica estado de juego.
## Emite intenciones (`pausa_reanudar` / `pausa_abandonar` / `pausa_ajustes`) y
## audio por `menu_audio_requested`; jamás `change_scene` (el router único de
## M-001a posee las transiciones), jamás E/S de disco (MENU-08: la persistencia
## vive en `persistencia/` tras la fachada de Guardado), jamás reproductores
## directos, jamás hilos bloqueados.
##
## CONTENIDO NORMATIVO (MENU-04): exactamente {Reanudar, Abandonar, Ajustes} en
## ese orden de foco. Continuar y reintento están AUSENTES del árbol por
## construcción (nunca se crean — no deshabilitados). `botones_en_orden()` y el
## tree-dump del test lo aseveran como ausencia, no como estado.
##
## ABANDONAR SOLO SE LISTA: el press emite `pausa_abandonar` + `ui_armar_destructivo`
## y la overlay QUEDA ABIERTA; la firma destructiva Tipo-A vive en M-004
## (`firma_hold.gd`) y el borrado en el backend de Guardado. Esta overlay no firma
## nada y no borra nada.
##
## PAUSA CONGELA TIMER S SIN CONTARLO (ADR-001 R12 / hud.md Dynamic Behaviors):
## el congelado real lo ejecuta `CombatHud.set_estado(PAUSA)` (S oculto, timer
## ignorado, vignette congelada) ordenado por `MenuPresenter`; sin vignette
## animada ni rumble; retorno por corte (cero Tweens/Timers aquí por construcción
## — `skip_animations()` es no-op documentado).
##
## SUPERFICIE PURA contra mock M-001a (M-001a Blocked por ADR arranque/router):
## la UI se autoconstruye en `_ready` (sin `.tscn`) para ser testeable sin shell.
## TODO(M-001a): cableado final `set_pausa_visual` + foco post-splash vía router.
## TODO(router): `change_scene` único; esta overlay solo emite intenciones.
##
## SEAMS DE TEST: `set_reloj_manual()` + `avanzar_reloj_manual()` vuelven
## determinista el swallow de 200ms (producción usa reloj real).
## `intentar_mover_foco/intentar_activar/intentar_cancelar` son la traducción
## testeable de los flancos de input. El input que ABRIÓ la pausa ya fue consumido
## por el invocador (`set_input_as_handled`); esta vista no re-inhibe por frame,
## el swallow 200ms cubre el post-acción (sin `_process`: cero coste por frame).

## Opciones en orden normativo de foco (MENU-04). El orden es lógico, no visual:
## no depende de layout ni de RTL (el visual lo posee `/localize`).
enum Opcion { REANUDAR = 0, ABANDONAR = 1, AJUSTES = 2 }

## Intención Reanudar (retorno por corte; cierra la overlay).
signal pausa_reanudar
## Abandonar LISTADO (firma destructiva owner M-004; la overlay queda abierta).
signal pausa_abandonar
## Intención Ajustes (overlay encima, retorno al invocador — owner router M-001a).
signal pausa_ajustes
## Intención de audio por el bus (timbres propiedad Audio #16). Nunca directo.
signal menu_audio_requested(clave: StringName)
## El foco se movió dentro de la tríada (hook lector/tests).
signal foco_cambiado(elemento: StringName)

## Paleta compartida (deuda previa intacta: mismos hex que Decisión/HUD, sin nuevos).
const FONDO_TINTA := Color("14110E")
const GRIS_FONDO := Color("2A2E36")
const GRIS_BORDE := Color("8C94A0")
const GRIS_LUZ := Color("C7CDD6")
## Alias de GRIS_MEDIO (#9AA2AF, gracia_shards.gd:17) — no es hex nuevo.
const GRIS_SUAVE := Color("9AA2AF")

## Tallas base. Piso aparente 18px con hud_scale 0.9–1.15.
const TALLA_TITULO: int = 36
const TALLA_ETIQUETA: int = 24
const FUENTE_MIN: int = 18

## Ventana swallow post-acción: todo input consumido/inhibido (Menú R6-INPUT).
const SWALLOW_MS: int = 200
## Safe-zone 5% por borde sobre base 1280×800 (GDD R7; mínimo absoluto 3%).
const SAFE_FRACCION: float = 0.05

## Escala con compensación de fuente (piso 18px aparente). Opacidad NO expuesta:
## fondos opacos por contraste (guarda 4.5:1, mismo criterio que Decisión).
@export_range(0.9, 1.15, 0.01) var hud_scale: float = 1.0:
	set(valor):
		hud_scale = clampf(valor, 0.9, 1.15)
		_aplicar_escala()
## Corte puro por construcción: sin shake/vignette pulsante que colapsar.
## Se acepta y propaga por simetría con Decisión/HUD (hitstop intacto: es
## gameplay del mundo, no de la UI).
@export var reduced_motion: bool = false

var _abierta: bool = false
## -1 cerrada (intencional); 0 Reanudar, 1 Abandonar, 2 Ajustes.
var _foco: int = -1
var _foco_guardado: int = -1
var _swallow_hasta_ms: int = 0

## Reloj manual para tests deterministas (producción: siempre reloj real).
var _reloj_manual: bool = false
var _reloj_manual_ms: int = 0

var _fuente_base: SystemFont
var _fuente_foco: SystemFont
var _sb_foco: StyleBoxFlat

var _fondo: ColorRect
var _safe: Control
var _titulo: Label
var _btn_reanudar: Button
var _btn_abandonar: Button
var _btn_ajustes: Button
var _cuneta_reanudar: ColorRect
var _cuneta_abandonar: ColorRect
var _cuneta_ajustes: ColorRect


## Construye la superficie pura (sin .tscn: testeable sin shell M-001a).
## Sin `grab_focus` inicial (el foco lo fija `abrir()` en Reanudar, GDD R7).
func _ready() -> void:
	layer = 20
	follow_viewport_enabled = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_fuente_base = SystemFont.new()
	_fuente_base.font_weight = 600
	_fuente_foco = SystemFont.new()
	_fuente_foco.font_weight = 800
	_sb_foco = _estilo_boton(GRIS_FONDO, GRIS_LUZ, 2)
	_construir()
	_configurar_trampa_foco()
	_aplicar_tallas()
	_aplicar_escala()


## Abre la overlay: visible + foco inicial en Reanudar (mapa de foco GDD R7).
## No emite audio (el timbre de transición lo posee el invocador/router).
func abrir() -> void:
	if not is_node_ready():
		return
	if _abierta:
		return
	_abierta = true
	_refrescar_textos()
	visible = true
	_fijar_foco(Opcion.REANUDAR, false)


## Cierra por corte (sin fade): libera focos, oculta cunetas, esconde.
## La restauración al invocador la posee el router (TODO M-001a: foco post-splash).
func cerrar() -> void:
	if not _abierta:
		return
	_abierta = false
	_foco = -1
	_liberar_focos()
	visible = false


## Overlay visible y atrapando foco.
func esta_abierta() -> bool:
	return _abierta


## Foco lógico actual (-1 cerrada, 0/1/2 tríada). Solo lectura para tests.
func foco_actual() -> int:
	return _foco


## Los 3 botones en orden normativo (MENU-04). Solo lectura para tests.
func botones_en_orden() -> Array[Button]:
	return [_btn_reanudar, _btn_abandonar, _btn_ajustes]


## Todas las claves de texto de la overlay (provisionales hasta `/localize`+writer).
func claves_texto() -> Array[StringName]:
	return [&"MENU_PAUSA_TITULO", &"MENU_PAUSA_REANUDAR", &"MENU_PAUSA_ABANDONAR", &"MENU_PAUSA_AJUSTES"]


## Flanco `ui_up/down` (o next/prev): mueve dentro de la tríada con trampa
## (jamás escapa). En swallow se consume en silencio. Cerrada: no consume.
func intentar_mover_foco(direccion: int) -> bool:
	if not _abierta:
		return false
	if _en_swallow() or direccion == 0:
		return true
	var paso: int = 1 if direccion > 0 else -1
	_fijar_foco(posmod(_foco + paso, 3), true)
	return true


## Flanco `ui_accept` (o click con flanco fresco): despacha la opción enfocada.
## Enfocado inválido/neutro: no-op + error sordo. Siempre consume si abierta.
func intentar_activar() -> bool:
	if not _abierta:
		return false
	if _en_swallow():
		return true
	if _foco < 0:
		menu_audio_requested.emit(&"ui_error_bloqueado")
		return true
	_despachar(_foco)
	return true


## `ui_cancel`: retorno seguro = Reanudar por corte (sin atrás apilado).
## Post-acción se consume en silencio. Cerrada: no consume.
func intentar_cancelar() -> bool:
	if not _abierta:
		return false
	if _en_swallow():
		return true
	_swallow_hasta_ms = _ahora_ms() + SWALLOW_MS
	pausa_reanudar.emit()
	menu_audio_requested.emit(&"ui_atras")
	cerrar()
	return true


## Corte puro por construcción: no hay animaciones que acortar (sin Tweens ni
## Timers en esta overlay). Existe por contrato skip global (M-006a).
func skip_animations() -> void:
	return


## Reloj manual determinista para tests (swallow 200ms). Producción no lo usa.
## Al activarlo resetea el swallow: aísla casos de swallow heredado del reloj real.
func set_reloj_manual(activo: bool, ahora_ms: int = 0) -> void:
	_reloj_manual = activo
	_reloj_manual_ms = ahora_ms
	if activo:
		_swallow_hasta_ms = 0


## Avanza el reloj manual sin pared real (determinismo).
func avanzar_reloj_manual(delta_ms: int) -> void:
	_reloj_manual_ms += delta_ms


func _unhandled_input(evento: InputEvent) -> void:
	if not is_inside_tree():
		return
	if not _abierta or not visible:
		return
	if evento.is_echo():
		return
	# Motion continuo/gyro jamás disparan (Menú R6-INPUT): solo flancos
	# discretos de tecla, botón de mando, D-Pad o click.
	if evento is InputEventMouseMotion or evento is InputEventScreenDrag:
		return
	if evento.is_action_pressed(&"ui_down") or evento.is_action_pressed(&"ui_focus_next"):
		intentar_mover_foco(1)
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed(&"ui_up") or evento.is_action_pressed(&"ui_focus_prev"):
		intentar_mover_foco(-1)
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed(&"ui_accept"):
		intentar_activar()
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed(&"ui_cancel"):
		intentar_cancelar()
		get_viewport().set_input_as_handled()
		return
	# Right-click = no-op definido (ni despacho ni audio).
	if evento is InputEventMouseButton:
		var raton := evento as InputEventMouseButton
		if raton.button_index == MOUSE_BUTTON_RIGHT and raton.pressed:
			get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	# Evita focus-steal en vistas sustituidas sin liberar: si la conexión de
	# mando sigue viva al salir del árbol, se suelta aquí.
	if Input.joy_connection_changed.is_connected(_al_mando_cambiado):
		Input.joy_connection_changed.disconnect(_al_mando_cambiado)


func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_WINDOW_FOCUS_OUT:		# Sleep en modal (GDD Edge): modal preservado con foco, jamás auto-despacho.
		_foco_guardado = _foco
	elif que == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_foco = _foco_guardado
		if _abierta and _foco >= 0:
			_fijar_foco_visual(_foco)


func _al_mando_cambiado(_dispositivo: int, conectado: bool) -> void:
	# Desconexión: foco almacenado + fallback a teclado (automático, las
	# acciones ui_* sirven a ambos). Reconexión: re-grab al almacenado.
	if conectado and _abierta and _foco >= 0 and visible:
		_fijar_foco_visual(_foco)


## Click con flanco fresco: enfoca + despacha en un solo gesto.
func _al_boton_pulsado(lado: int) -> void:
	if not _abierta or _en_swallow():
		return
	_fijar_foco(lado, false)
	_despachar(lado)


## Despacha la opción: emite intención + audio + swallow 200ms. Reanudar además
## cierra por corte; Abandonar/Ajustes quedan abiertas (firma M-004 / overlay
## Ajustes con retorno al invocador — owner router).
func _despachar(lado: int) -> void:
	_swallow_hasta_ms = _ahora_ms() + SWALLOW_MS
	match lado:
		Opcion.REANUDAR:
			pausa_reanudar.emit()
			menu_audio_requested.emit(&"ui_confirmar_neutro")
			cerrar()
		Opcion.ABANDONAR:
			pausa_abandonar.emit()
			menu_audio_requested.emit(&"ui_armar_destructivo")
		Opcion.AJUSTES:
			pausa_ajustes.emit()
			menu_audio_requested.emit(&"ui_confirmar_neutro")
		_:  # Fail-closed (conforme a intentar_activar): sin intención, error sordo.
			menu_audio_requested.emit(&"ui_error_bloqueado")


func _ahora_ms() -> int:
	if _reloj_manual:
		return _reloj_manual_ms
	return Time.get_ticks_msec()


func _en_swallow() -> bool:
	return _ahora_ms() < _swallow_hasta_ms


func _fijar_foco(lado: int, anunciar: bool) -> void:
	_foco = lado
	_fijar_foco_visual(lado)
	if anunciar:
		menu_audio_requested.emit(&"ui_foco")
		match lado:
			Opcion.REANUDAR:
				foco_cambiado.emit(&"REANUDAR")
			Opcion.ABANDONAR:
				foco_cambiado.emit(&"ABANDONAR")
			_:
				foco_cambiado.emit(&"AJUSTES")


func _fijar_foco_visual(lado: int) -> void:
	_cuneta_reanudar.visible = lado == Opcion.REANUDAR
	_cuneta_abandonar.visible = lado == Opcion.ABANDONAR
	_cuneta_ajustes.visible = lado == Opcion.AJUSTES
	_btn_reanudar.add_theme_font_override(&"font", _fuente_foco if lado == Opcion.REANUDAR else _fuente_base)
	_btn_abandonar.add_theme_font_override(&"font", _fuente_foco if lado == Opcion.ABANDONAR else _fuente_base)
	_btn_ajustes.add_theme_font_override(&"font", _fuente_foco if lado == Opcion.AJUSTES else _fuente_base)
	var objetivo: Button = _btn_reanudar
	if lado == Opcion.ABANDONAR:
		objetivo = _btn_abandonar
	elif lado == Opcion.AJUSTES:
		objetivo = _btn_ajustes
	if visible and is_inside_tree() and not objetivo.disabled:
		objetivo.grab_focus()


func _liberar_focos() -> void:
	for boton: Button in [_btn_reanudar, _btn_abandonar, _btn_ajustes]:
		boton.release_focus()
	_cuneta_reanudar.visible = false
	_cuneta_abandonar.visible = false
	_cuneta_ajustes.visible = false


# ─── Textos: todo vía tr() (provisionales es-MX en tabla GDD; fija /localize) ───

func _refrescar_textos() -> void:
	_titulo.text = tr("MENU_PAUSA_TITULO")
	_btn_reanudar.text = tr("MENU_PAUSA_REANUDAR")
	_btn_abandonar.text = tr("MENU_PAUSA_ABANDONAR")
	_btn_ajustes.text = tr("MENU_PAUSA_AJUSTES")


# ─── Construcción pura (sin .tscn) + estilos gemelos, foco 2px sin glow ───

func _construir() -> void:
	_fondo = ColorRect.new()
	_fondo.name = "Fondo"
	_fondo.color = FONDO_TINTA
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Modal: consume clicks fuera de los botones (la overlay atrapa todo).
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)
	_safe = Control.new()
	_safe.name = "SafeZone"
	_safe.anchor_left = SAFE_FRACCION
	_safe.anchor_top = SAFE_FRACCION
	_safe.anchor_right = 1.0 - SAFE_FRACCION
	_safe.anchor_bottom = 1.0 - SAFE_FRACCION
	_safe.offset_left = 0.0
	_safe.offset_top = 0.0
	_safe.offset_right = 0.0
	_safe.offset_bottom = 0.0
	_safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe)
	var centro := CenterContainer.new()
	centro.name = "Centro"
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe.add_child(centro)
	var columna := VBoxContainer.new()
	columna.name = "Columna"
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override(&"separation", 12)
	columna.custom_minimum_size = Vector2(480.0, 0.0)
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(columna)
	_titulo = Label.new()
	_titulo.name = "Titulo"
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(_titulo)
	var filas: Array[Button] = []
	filas.append(_crear_fila(columna, "FilaReanudar", "BtnReanudar", "CunetaReanudar"))
	_btn_reanudar = filas[0]
	_btn_abandonar = _crear_fila(columna, "FilaAbandonar", "BtnAbandonar", "CunetaAbandonar")
	_btn_ajustes = _crear_fila(columna, "FilaAjustes", "BtnAjustes", "CunetaAjustes")
	_cuneta_reanudar = columna.get_node(^"FilaReanudar/CunetaReanudar") as ColorRect
	_cuneta_abandonar = columna.get_node(^"FilaAbandonar/CunetaAbandonar") as ColorRect
	_cuneta_ajustes = columna.get_node(^"FilaAjustes/CunetaAjustes") as ColorRect
	_refrescar_textos()
	_btn_reanudar.pressed.connect(_al_boton_pulsado.bind(Opcion.REANUDAR))
	_btn_abandonar.pressed.connect(_al_boton_pulsado.bind(Opcion.ABANDONAR))
	_btn_ajustes.pressed.connect(_al_boton_pulsado.bind(Opcion.AJUSTES))
	Input.joy_connection_changed.connect(_al_mando_cambiado)


## Crea una fila (marcador de cuneta + botón gemelo) y retorna el botón.
func _crear_fila(columna: VBoxContainer, nombre_fila: String, nombre_boton: String, nombre_cuneta: String) -> Button:
	var fila := HBoxContainer.new()
	fila.name = nombre_fila
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override(&"separation", 8)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(fila)
	var cuneta := ColorRect.new()
	cuneta.name = nombre_cuneta
	cuneta.color = GRIS_LUZ
	cuneta.custom_minimum_size = Vector2(6.0, 0.0)
	cuneta.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuneta.visible = false
	cuneta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(cuneta)
	var boton := Button.new()
	boton.name = nombre_boton
	boton.focus_mode = Control.FOCUS_ALL
	boton.custom_minimum_size = Vector2(440.0, 56.0)
	boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boton.clip_text = true
	var normal := _estilo_boton(GRIS_FONDO, GRIS_BORDE, 1)
	boton.add_theme_stylebox_override(&"normal", normal)
	# Dual-focus: hover jamás roba foco de mando ni cambia el botón.
	boton.add_theme_stylebox_override(&"hover", normal)
	boton.add_theme_stylebox_override(&"pressed", _estilo_boton(GRIS_FONDO, GRIS_LUZ, 2))
	boton.add_theme_stylebox_override(&"focus", _sb_foco)
	boton.add_theme_stylebox_override(&"disabled", _estilo_boton(GRIS_FONDO, GRIS_BORDE, 1))
	boton.add_theme_color_override(&"font_color", GRIS_LUZ)
	boton.add_theme_color_override(&"font_focus_color", GRIS_LUZ)
	boton.add_theme_color_override(&"font_hover_color", GRIS_LUZ)
	boton.add_theme_color_override(&"font_pressed_color", GRIS_LUZ)
	boton.add_theme_color_override(&"font_disabled_color", GRIS_SUAVE)
	boton.add_theme_font_override(&"font", _fuente_base)
	fila.add_child(boton)
	return boton


func _estilo_boton(fondo: Color, borde: Color, grosor: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fondo
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(grosor)
	sb.border_color = borde
	# Sin glow: solo lo divino emite luz (art-bible 2). Sin sombra tampoco.
	sb.shadow_size = 0
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb


func _configurar_trampa_foco() -> void:
	# Trampa en tríada: todo vecino lleva a otro botón (Tab incluido).
	# Inicial Reanudar: lo fija abrir(), no los vecinos.
	var botones: Array[Button] = [_btn_reanudar, _btn_abandonar, _btn_ajustes]
	for i in range(3):
		var a: Button = botones[i]
		var anterior: Button = botones[posmod(i - 1, 3)]
		var siguiente: Button = botones[posmod(i + 1, 3)]
		a.focus_neighbor_top = anterior.get_path()
		a.focus_neighbor_bottom = siguiente.get_path()
		a.focus_neighbor_left = anterior.get_path()
		a.focus_neighbor_right = siguiente.get_path()
		a.focus_previous = anterior.get_path()
		a.focus_next = siguiente.get_path()


func _aplicar_tallas() -> void:
	if not is_node_ready():
		return
	var s := clampf(hud_scale, 0.9, 1.15)
	# Guarda 18px aparente: compensa a ceil(18/scale) cuando scale < 1.
	var f := func(base: int) -> int: return maxi(base, int(ceil(float(FUENTE_MIN) / s)))
	_titulo.add_theme_font_size_override(&"font_size", f.call(TALLA_TITULO))
	_btn_reanudar.add_theme_font_size_override(&"font_size", f.call(TALLA_ETIQUETA))
	_btn_abandonar.add_theme_font_size_override(&"font_size", f.call(TALLA_ETIQUETA))
	_btn_ajustes.add_theme_font_size_override(&"font_size", f.call(TALLA_ETIQUETA))
	_titulo.add_theme_color_override(&"font_color", GRIS_LUZ)


func _aplicar_escala() -> void:
	if not is_node_ready():
		return
	scale = Vector2(hud_scale, hud_scale)
	_aplicar_tallas()

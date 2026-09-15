class_name MenuHub
extends CanvasLayer

## Líneas Hub — superficie pura M-003 (GDD Menú UI Requirements, filas Hub).
##
## Implementa `design/gdd/menu-principal-y-flujo-de-pantallas.md` UI Requirements
## (línea SUS + aviso de stakes) + historia
## `production/epics/menu-principal/story-m003-pausa-muerte-hub.md` AC Hub.
## Espeja la disciplina de `decision_gracia.gd` (consume + swallow 200ms, foco
## visible 2px sin glow, dual-focus, todo `tr()`, audio por bus).
##
## CONTRATO DISPLAY-Only (`ui-code.md`): nunca posee ni modifica estado de juego.
## Lee un resumen de lectura vía `configure()` (display owned Menú; la composición
## del resumen la posee Guardado §Fachada) y emite intenciones (`hub_entrar_duelo`)
## + audio por `menu_audio_requested`; jamás `change_scene` (router M-001a),
## jamás E/S de disco (MENU-08), jamás reproductores directos, jamás hilos.
##
## CONTENIDO MÍNIMO M-003 (el Hub completo es de M-001a/#18):
## - Línea SUS persistente sobria (`MENU_HUB_SUS_LINE`, "La novena espera en
##   {coro} · {mm_ss}"): visible solo con SUS vigente; oculta sin SUS (S1).
## - Aviso de stakes (`MENU_HUB_STAKES`, "Al entrar, la suspensión se invalida:
##   en duelo no hay red"): SIEMPRE visible, junto a la entrada a duelo.
## - Entrada a duelo (`MENU_HUB_ENTRAR_DUELO`): emite la intención; la
##   invalidación de la SUS (rename síncrono fail-closed) la ejecuta Guardado R5,
##   no esta vista. Salir-al-menú y Abandonar viven en M-001a/M-004 (no aquí).
## Foco inicial provisional en Entrar a duelo (hasta #18 — TODO explícito).
##
## SUPERFICIE PURA contra mock M-001a (M-001a Blocked por ADR arranque/router):
## la UI se autoconstruye en `_ready` (sin `.tscn`) para ser testeable sin shell.
## TODO(M-001a): Hub completo (contenido mínimo owner #18) + `change_scene` único.
## TODO(#18): foco inicial definitivo del Hub (provisional: Entrar a duelo).
##
## SEAMS DE TEST: `configure()` retorna si la línea SUS quedó visible;
## `textos_actuales()` + `sus_visible()` son lectura para tests. Sin `_process`.

## Intención Entrar a duelo (la SUS la invalida Guardado R5, no la UI).
signal hub_entrar_duelo
## Intención de audio por el bus (timbres propiedad Audio #16). Nunca directo.
signal menu_audio_requested(clave: StringName)
## El foco se fijó en la entrada (hook lector/tests).
signal foco_cambiado(elemento: StringName)

## Paleta compartida (deuda previa intacta: mismos hex que Decisión/HUD, sin nuevos).
const FONDO_TINTA := Color("14110E")
const GRIS_FONDO := Color("2A2E36")
const GRIS_BORDE := Color("8C94A0")
const GRIS_LUZ := Color("C7CDD6")
## Alias de GRIS_MEDIO (#9AA2AF, gracia_shards.gd:17) — no es hex nuevo.
const GRIS_SUAVE := Color("9AA2AF")

## Tallas base. Piso aparente 18px con hud_scale 0.9–1.15.
const TALLA_ETIQUETA: int = 24
const TALLA_DESC: int = 20
const FUENTE_MIN: int = 18

## Ventana swallow post-acción en Entrar (vista; el dedupe autoritativo es del
## backend Guardado R9/CONSUMIENDO + Menú M11 — aquí solo anti-doble-gesto).
const SWALLOW_MS: int = 200
## Safe-zone 5% por borde sobre base 1280×800 (GDD R7; mínimo absoluto 3%).
const SAFE_FRACCION: float = 0.05

## Escala con compensación de fuente (piso 18px aparente). Opacidad NO expuesta:
## fondos opacos por contraste (guarda 4.5:1, mismo criterio que Decisión).
@export_range(0.9, 1.15, 0.01) var hud_scale: float = 1.0:
	set(valor):
		hud_scale = clampf(valor, 0.9, 1.15)
		_aplicar_escala()
## Corte puro por construcción: sin animaciones que colapsar.
@export var reduced_motion: bool = false

var _sus_vigente: bool = false
var _foco_guardado: int = 0
var _swallow_hasta_ms: int = 0

## Reloj manual para tests deterministas (producción: siempre reloj real).
var _reloj_manual: bool = false
var _reloj_manual_ms: int = 0

var _fuente_base: SystemFont
var _fuente_foco: SystemFont
var _sb_foco: StyleBoxFlat

var _fondo: ColorRect
var _safe: Control
var _lbl_sus: Label
var _lbl_stakes: Label
var _btn_entrar: Button
var _cuneta_entrar: ColorRect


## Construye la superficie pura (sin .tscn: testeable sin shell M-001a).
func _ready() -> void:
	layer = 5
	follow_viewport_enabled = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_fuente_base = SystemFont.new()
	_fuente_base.font_weight = 600
	_fuente_foco = SystemFont.new()
	_fuente_foco.font_weight = 800
	_sb_foco = _estilo_boton(GRIS_FONDO, GRIS_LUZ, 2)
	_construir()
	_configurar_foco_unico()
	_aplicar_tallas()
	_aplicar_escala()


## Configura las líneas desde el resumen de lectura (display owned Menú).
## `datos`: `{sus_vigente: bool, coro_label: String, mm_ss: String}`.
## Sin SUS vigente (o datos inválidos): línea SUS oculta, stakes + entrada
## intactos (nunca bloquea). Retorna si la línea SUS quedó visible.
## TODO(#18): foco inicial definitivo (provisional: Entrar a duelo).
func configure(datos: Dictionary) -> bool:
	if not is_node_ready():
		return false
	_sus_vigente = datos.get("sus_vigente", false) is bool and bool(datos.get("sus_vigente"))
	# Estricto de tipos: coercionar con str() mostraría SUS con "123"/'["x"]'
	# indebidamente; lo no-String es dato inválido y deja la SUS oculta.
	var coro_raw: Variant = datos.get("coro_label", "")
	var mmss_raw: Variant = datos.get("mm_ss", "")
	var coro: String = ""
	if coro_raw is String:
		coro = coro_raw
	var mmss: String = ""
	if mmss_raw is String:
		mmss = mmss_raw
	if _sus_vigente and coro != "" and mmss != "":
		_lbl_sus.text = tr("MENU_HUB_SUS_LINE").format({"coro": coro, "mm_ss": mmss})
		_lbl_sus.visible = true
	else:
		_sus_vigente = false
		_lbl_sus.visible = false
	_lbl_stakes.text = tr("MENU_HUB_STAKES")
	_btn_entrar.text = tr("MENU_HUB_ENTRAR_DUELO")
	visible = true
	_fijar_foco_visual()
	foco_cambiado.emit(&"ENTRAR_DUELO")
	return _sus_vigente


## Oculta (la posee el router al salir del Hub — TODO M-001a).
func ocultar() -> void:
	_btn_entrar.release_focus()
	_cuneta_entrar.visible = false
	visible = false


## Línea SUS visible ahora (S2 punto seguro). Solo lectura para tests.
func sus_visible() -> bool:
	return _sus_vigente and _lbl_sus.visible


## Textos renderizados ahora (lectura para tests; claves vía `claves_texto()`).
func textos_actuales() -> Dictionary:
	return {
		"sus": _lbl_sus.text,
		"stakes": _lbl_stakes.text,
		"entrar": _btn_entrar.text,
		"sus_visible": sus_visible(),
	}


## Todas las claves de texto (provisionales hasta `/localize`+writer).
func claves_texto() -> Array[StringName]:
	return [&"MENU_HUB_SUS_LINE", &"MENU_HUB_STAKES", &"MENU_HUB_ENTRAR_DUELO"]


## Trampa trivial de foco único: no hay a dónde moverse; se consume en silencio.
## Oculta: no consume.
func intentar_mover_foco(_direccion: int) -> bool:
	if not visible:
		return false
	return true


## Flanco `ui_accept` (o click): intención Entrar a duelo + swallow 200ms.
## La vista QUEDA VISIBLE: la transición la confirma el juego y la ejecuta el
## router (TODO M-001a); el swallow evita el doble-gesto (dedupe autoritativo:
## Guardado R9/CONSUMIENDO).
func intentar_entrar() -> bool:
	if not visible:
		return false
	if _en_swallow():
		return true
	_swallow_hasta_ms = _ahora_ms() + SWALLOW_MS
	hub_entrar_duelo.emit()
	menu_audio_requested.emit(&"ui_confirmar_neutro")
	return true


## `ui_cancel`: no-op + error sordo (sin atrás aquí: Salir-al-menú y Abandonar
## viven en M-001a/M-004, no en esta superficie mínima). Siempre consume si visible.
func intentar_cancelar() -> bool:
	if not visible:
		return false
	menu_audio_requested.emit(&"ui_error_bloqueado")
	return true


## Corte puro por construcción: no hay animaciones que acortar.
## Existe por contrato skip global (M-006a).
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
	if not visible:
		return
	if evento.is_echo():
		return
	# Motion continuo/gyro jamás disparan (Menú R6-INPUT): solo flancos discretos.
	if evento is InputEventMouseMotion or evento is InputEventScreenDrag:
		return
	if evento.is_action_pressed(&"ui_accept"):
		intentar_entrar()
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed(&"ui_cancel"):
		intentar_cancelar()
		get_viewport().set_input_as_handled()
		return
	# Right-click = no-op definido (ni intención ni audio).
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
	if que == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		# Sleep: líneas + foco preservados, jamás auto-entrada a duelo.
		_foco_guardado = 0
	elif que == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		if visible:
			_fijar_foco_visual()


func _al_mando_cambiado(_dispositivo: int, conectado: bool) -> void:
	# Desconexión: fallback a teclado (automático). Reconexión: re-grab.
	if conectado and visible:
		_fijar_foco_visual()


## Click con flanco fresco sobre la entrada.
func _al_boton_pulsado() -> void:
	if not visible or _en_swallow():
		return
	_swallow_hasta_ms = _ahora_ms() + SWALLOW_MS
	hub_entrar_duelo.emit()
	menu_audio_requested.emit(&"ui_confirmar_neutro")


func _ahora_ms() -> int:
	if _reloj_manual:
		return _reloj_manual_ms
	return Time.get_ticks_msec()


func _en_swallow() -> bool:
	return _ahora_ms() < _swallow_hasta_ms


func _fijar_foco_visual() -> void:
	_cuneta_entrar.visible = true
	_btn_entrar.add_theme_font_override(&"font", _fuente_foco)
	if visible and is_inside_tree() and not _btn_entrar.disabled:
		_btn_entrar.grab_focus()


# ─── Construcción pura (sin .tscn): SUS + fila duelo/stakes ───

func _construir() -> void:
	_fondo = ColorRect.new()
	_fondo.name = "Fondo"
	_fondo.color = FONDO_TINTA
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	columna.add_theme_constant_override(&"separation", 16)
	columna.custom_minimum_size = Vector2(560.0, 0.0)
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(columna)
	_lbl_sus = Label.new()
	_lbl_sus.name = "LblSus"
	_lbl_sus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_sus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_sus.visible = false
	_lbl_sus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(_lbl_sus)
	# Fila duelo: aviso de stakes JUNTO a la entrada (UI Requirements Hub).
	var fila := HBoxContainer.new()
	fila.name = "FilaDuelo"
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override(&"separation", 12)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(fila)
	_cuneta_entrar = ColorRect.new()
	_cuneta_entrar.name = "CunetaEntrar"
	_cuneta_entrar.color = GRIS_LUZ
	_cuneta_entrar.custom_minimum_size = Vector2(6.0, 0.0)
	_cuneta_entrar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cuneta_entrar.visible = false
	_cuneta_entrar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(_cuneta_entrar)
	_btn_entrar = Button.new()
	_btn_entrar.name = "BtnEntrarDuelo"
	_btn_entrar.focus_mode = Control.FOCUS_ALL
	_btn_entrar.custom_minimum_size = Vector2(320.0, 56.0)
	_btn_entrar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_entrar.clip_text = true
	var normal := _estilo_boton(GRIS_FONDO, GRIS_BORDE, 1)
	_btn_entrar.add_theme_stylebox_override(&"normal", normal)
	# Dual-focus: hover jamás roba foco de mando ni cambia el botón.
	_btn_entrar.add_theme_stylebox_override(&"hover", normal)
	_btn_entrar.add_theme_stylebox_override(&"pressed", _estilo_boton(GRIS_FONDO, GRIS_LUZ, 2))
	_btn_entrar.add_theme_stylebox_override(&"focus", _sb_foco)
	_btn_entrar.add_theme_stylebox_override(&"disabled", _estilo_boton(GRIS_FONDO, GRIS_BORDE, 1))
	_btn_entrar.add_theme_color_override(&"font_color", GRIS_LUZ)
	_btn_entrar.add_theme_color_override(&"font_focus_color", GRIS_LUZ)
	_btn_entrar.add_theme_color_override(&"font_hover_color", GRIS_LUZ)
	_btn_entrar.add_theme_color_override(&"font_pressed_color", GRIS_LUZ)
	_btn_entrar.add_theme_color_override(&"font_disabled_color", GRIS_SUAVE)
	_btn_entrar.add_theme_font_override(&"font", _fuente_base)
	fila.add_child(_btn_entrar)
	_lbl_stakes = Label.new()
	_lbl_stakes.name = "LblStakes"
	_lbl_stakes.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_lbl_stakes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_stakes.custom_minimum_size = Vector2(220.0, 0.0)
	_lbl_stakes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(_lbl_stakes)
	_btn_entrar.pressed.connect(_al_boton_pulsado)
	Input.joy_connection_changed.connect(_al_mando_cambiado)


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


func _configurar_foco_unico() -> void:
	# Trampa trivial de foco único: todo vecino es la propia entrada.
	_btn_entrar.focus_neighbor_left = _btn_entrar.get_path()
	_btn_entrar.focus_neighbor_right = _btn_entrar.get_path()
	_btn_entrar.focus_neighbor_top = _btn_entrar.get_path()
	_btn_entrar.focus_neighbor_bottom = _btn_entrar.get_path()
	_btn_entrar.focus_next = _btn_entrar.get_path()
	_btn_entrar.focus_previous = _btn_entrar.get_path()


func _aplicar_tallas() -> void:
	if not is_node_ready():
		return
	var s := clampf(hud_scale, 0.9, 1.15)
	# Guarda 18px aparente: compensa a ceil(18/scale) cuando scale < 1.
	var f := func(base: int) -> int: return maxi(base, int(ceil(float(FUENTE_MIN) / s)))
	_lbl_sus.add_theme_font_size_override(&"font_size", f.call(TALLA_DESC))
	_lbl_stakes.add_theme_font_size_override(&"font_size", f.call(TALLA_DESC))
	_btn_entrar.add_theme_font_size_override(&"font_size", f.call(TALLA_ETIQUETA))
	_lbl_sus.add_theme_color_override(&"font_color", GRIS_LUZ)
	_lbl_stakes.add_theme_color_override(&"font_color", GRIS_SUAVE)
	_btn_entrar.add_theme_color_override(&"font_color", GRIS_LUZ)


func _aplicar_escala() -> void:
	if not is_node_ready():
		return
	scale = Vector2(hud_scale, hud_scale)
	_aplicar_tallas()

class_name MenuMuerte
extends CanvasLayer

## Pantalla Muerte muda Rev2 — superficie pura M-003 (GDD Menú R5, Rev2 decidida).
##
## Implementa `design/gdd/menu-principal-y-flujo-de-pantallas.md` §States (fila
## Muerte) + UI Requirements (fila "Muerte muda") + historia
## `production/epics/menu-principal/story-m003-pausa-muerte-hub.md` AC muerte +
## Open Questions (objeto ¿anillo o zapato? — owner narrative/world-builder).
## Espeja la disciplina modal de `decision_gracia.gd` (consume + swallow 200ms,
## foco visible 2px sin glow, dual-focus, todo `tr()`, audio por bus).
##
## CONTRATO DISPLAY-Only (`ui-code.md`): nunca posee ni modifica estado de juego.
## PER ya reconciliado y SUS borrada ANTES de mostrar (ya es S1 — owner Guardado
## R10); esta pantalla no lee disco, no borra nada, no reintenta nada. Emite la
## única salida (`muerte_volver`) y audio por `menu_audio_requested`; jamás
## `change_scene` (el router único de M-001a posee las transiciones), jamás E/S
## de disco (MENU-08), jamás reproductores directos, jamás hilos bloqueados.
##
## MUDA (Pilar 4, tono): Hub-object mudo + solo "Volver al menú". Sin cita —
## `es_muda()` lo asevera como invariante (cero nodos de cita en el árbol).
## OBJETO PLACEHOLDER DOCUMENTADO: el objeto del Hub (¿anillo o zapato? TBD
## narrative) se representa con un marco neutro vacío (`ObjetoHubPlaceholder`)
## + etiqueta sobria. NO se inventa ningún diseño: sin icono, sin arte, sin
## forma evocadora. Cuando narrative adjudique, esta pantalla solo sustituye el
## contenido del marco; el contrato (una salida, muda) no cambia.
##
## SUPERFICIE PURA contra mock M-001a (M-001a Blocked por ADR arranque/router):
## la UI se autoconstruye en `_ready` (sin `.tscn`) para ser testeable sin shell.
## TODO(M-001a): transición Volver→MenuPrincipal vía router (S1 ya garantizado).
## TODO(narrative): objeto anillo/zapato — sustituir placeholder sin tocar contrato.
##
## SEAMS DE TEST: `set_reloj_manual()` + `avanzar_reloj_manual()` vuelven
## determinista el swallow de 200ms (producción usa reloj real).
## (Sin `_process`: cero coste por frame, puramente event-driven.)

## Única salida (ya S1 vía MenuPrincipal — owner router M-001a).
signal muerte_volver
## Intención de audio por el bus (timbres propiedad Audio #16). Nunca directo.
signal menu_audio_requested(clave: StringName)
## El foco se fijó en la única salida (hook lector/tests).
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
## Corte puro por construcción: sin animaciones que colapsar. Se acepta por
## simetría con Decisión/HUD (Muerte = corte seco + tinta, GDD R5).
@export var reduced_motion: bool = false

var _abierta: bool = false
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
## Marco neutro del objeto del Hub. Vacío por diseño: placeholder documentado
## hasta adjudicación narrative (anillo/zapato). Sin arte, sin icono, sin forma.
var _objeto: Panel
var _desc_objeto: Label
var _btn_volver: Button
var _cuneta_volver: ColorRect


## Construye la superficie pura (sin .tscn: testeable sin shell M-001a).
## Foco inicial en la única salida (mapa de foco GDD R7: Muerte→Volver).
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
	_configurar_foco_unico()
	_aplicar_tallas()
	_aplicar_escala()


## Muestra la muerte muda (ya S1): objeto placeholder + única salida enfocada.
## No emite audio (el corte duelo→muerte <20ms lo posee Audio #16, handoff).
func abrir() -> void:
	if not is_node_ready():
		return
	if _abierta:
		return
	_abierta = true
	_refrescar_textos()
	visible = true
	_fijar_foco_visual()
	foco_cambiado.emit(&"VOLVER")


## Oculta (la posee el router al transicionar a MenuPrincipal — TODO M-001a).
func cerrar() -> void:
	if not _abierta:
		return
	_abierta = false
	_btn_volver.release_focus()
	_cuneta_volver.visible = false
	visible = false


## Pantalla visible con su única salida.
func esta_abierta() -> bool:
	return _abierta


## Invariante Rev2 (Pilar 4): muda por construcción. Scan ejecutable: cero Labels
## fuera de `DescObjeto` (el texto de `BtnVolver` es texto de botón, no Label —
## no cuenta) + ninguna clave de cita en `claves_texto()`. Rompe si alguien añade
## un Label de cita al árbol (ver `test_muerte_es_muda_rompe_si_cita_anadida`).
func es_muda() -> bool:
	for clave: StringName in claves_texto():
		if String(clave).to_lower().contains("cita"):
			return false
	var pendientes: Array[Node] = [self]
	while not pendientes.is_empty():
		var n: Node = pendientes.pop_back()
		if n is Label and n.name != &"DescObjeto":
			return false
		for hijo in n.get_children():
			pendientes.append(hijo)
	return true


## Todas las claves de texto (provisionales hasta `/localize`+writer).
## Nótese la ausencia normativa: ninguna clave de cita (muda, Pilar 4).
func claves_texto() -> Array[StringName]:
	return [&"MENU_MUERTE_OBJETO_DESC", &"MENU_MUERTE_VOLVER"]


## Trampa trivial de foco único: no hay a dónde moverse; se consume en silencio.
## Cerrada: no consume.
func intentar_mover_foco(_direccion: int) -> bool:
	if not _abierta:
		return false
	return true


## Flanco `ui_accept` (o click): única salida. Siempre consume si abierta.
func intentar_activar() -> bool:
	if not _abierta:
		return false
	if _en_swallow():
		return true
	_despachar_volver(&"ui_confirmar_neutro")
	return true


## `ui_cancel`: misma única salida (sin atrás apilado, sin omitir).
func intentar_cancelar() -> bool:
	if not _abierta:
		return false
	if _en_swallow():
		return true
	_despachar_volver(&"ui_atras")
	return true


## Corte puro por construcción: no hay animaciones que acortar (Muerte = corte
## seco + tinta, GDD R5). Existe por contrato skip global (M-006a).
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
	# Motion continuo/gyro jamás disparan (Menú R6-INPUT): solo flancos discretos.
	if evento is InputEventMouseMotion or evento is InputEventScreenDrag:
		return
	if evento.is_action_pressed(&"ui_accept"):
		intentar_activar()
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed(&"ui_cancel"):
		intentar_cancelar()
		get_viewport().set_input_as_handled()
		return
	# Right-click = no-op definido (ni salida ni audio).
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
		# Sleep: pantalla + foco preservados, jamás auto-salida.
		_foco_guardado = 0
	elif que == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		if _abierta:
			_fijar_foco_visual()


func _al_mando_cambiado(_dispositivo: int, conectado: bool) -> void:
	# Desconexión: fallback a teclado (automático). Reconexión: re-grab.
	if conectado and _abierta and visible:
		_fijar_foco_visual()


## Click con flanco fresco sobre la única salida.
func _al_boton_pulsado() -> void:
	if not _abierta or _en_swallow():
		return
	_despachar_volver(&"ui_confirmar_neutro")


## Emite la única salida + audio + swallow 200ms. La overlay QUEDA ABIERTA: el
## router la cierra al transicionar (TODO M-001a); el swallow evita doble salida.
func _despachar_volver(clave_audio: StringName) -> void:
	_swallow_hasta_ms = _ahora_ms() + SWALLOW_MS
	muerte_volver.emit()
	menu_audio_requested.emit(clave_audio)


func _ahora_ms() -> int:
	if _reloj_manual:
		return _reloj_manual_ms
	return Time.get_ticks_msec()


func _en_swallow() -> bool:
	return _ahora_ms() < _swallow_hasta_ms


func _fijar_foco_visual() -> void:
	_cuneta_volver.visible = true
	_btn_volver.add_theme_font_override(&"font", _fuente_foco)
	if visible and is_inside_tree() and not _btn_volver.disabled:
		_btn_volver.grab_focus()


# ─── Textos: todo vía tr() (provisionales es-MX en tabla GDD; fija /localize) ───

func _refrescar_textos() -> void:
	_desc_objeto.text = tr("MENU_MUERTE_OBJETO_DESC")
	_btn_volver.text = tr("MENU_MUERTE_VOLVER")


# ─── Construcción pura (sin .tscn): marco neutro + una salida ───

func _construir() -> void:
	_fondo = ColorRect.new()
	_fondo.name = "Fondo"
	_fondo.color = FONDO_TINTA
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	columna.add_theme_constant_override(&"separation", 16)
	columna.custom_minimum_size = Vector2(480.0, 0.0)
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(columna)
	# Marco neutro del objeto: contorno sin relleno, sin arte, sin icono.
	# Placeholder documentado — owner narrative (anillo/zapato TBD).
	_objeto = Panel.new()
	_objeto.name = "ObjetoHubPlaceholder"
	_objeto.custom_minimum_size = Vector2(160.0, 160.0)
	_objeto.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_objeto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objeto.add_theme_stylebox_override(&"panel", _estilo_marco())
	columna.add_child(_objeto)
	_desc_objeto = Label.new()
	_desc_objeto.name = "DescObjeto"
	_desc_objeto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_objeto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_objeto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(_desc_objeto)
	var fila := HBoxContainer.new()
	fila.name = "FilaVolver"
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override(&"separation", 8)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(fila)
	_cuneta_volver = ColorRect.new()
	_cuneta_volver.name = "CunetaVolver"
	_cuneta_volver.color = GRIS_LUZ
	_cuneta_volver.custom_minimum_size = Vector2(6.0, 0.0)
	_cuneta_volver.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cuneta_volver.visible = false
	_cuneta_volver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(_cuneta_volver)
	_btn_volver = Button.new()
	_btn_volver.name = "BtnVolver"
	_btn_volver.focus_mode = Control.FOCUS_ALL
	_btn_volver.custom_minimum_size = Vector2(440.0, 56.0)
	_btn_volver.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_volver.clip_text = true
	var normal := _estilo_boton(GRIS_FONDO, GRIS_BORDE, 1)
	_btn_volver.add_theme_stylebox_override(&"normal", normal)
	# Dual-focus: hover jamás roba foco de mando ni cambia el botón.
	_btn_volver.add_theme_stylebox_override(&"hover", normal)
	_btn_volver.add_theme_stylebox_override(&"pressed", _estilo_boton(GRIS_FONDO, GRIS_LUZ, 2))
	_btn_volver.add_theme_stylebox_override(&"focus", _sb_foco)
	_btn_volver.add_theme_stylebox_override(&"disabled", _estilo_boton(GRIS_FONDO, GRIS_BORDE, 1))
	_btn_volver.add_theme_color_override(&"font_color", GRIS_LUZ)
	_btn_volver.add_theme_color_override(&"font_focus_color", GRIS_LUZ)
	_btn_volver.add_theme_color_override(&"font_hover_color", GRIS_LUZ)
	_btn_volver.add_theme_color_override(&"font_pressed_color", GRIS_LUZ)
	_btn_volver.add_theme_color_override(&"font_disabled_color", GRIS_SUAVE)
	_btn_volver.add_theme_font_override(&"font", _fuente_base)
	fila.add_child(_btn_volver)
	_refrescar_textos()
	_btn_volver.pressed.connect(_al_boton_pulsado)
	Input.joy_connection_changed.connect(_al_mando_cambiado)


## Marco neutro: anillo sin relleno, sin arte. El objeto lo pone narrative.
func _estilo_marco() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(2)
	sb.border_color = GRIS_BORDE
	sb.shadow_size = 0
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb


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
	# Trampa trivial de foco único: todo vecino es el propio botón.
	_btn_volver.focus_neighbor_left = _btn_volver.get_path()
	_btn_volver.focus_neighbor_right = _btn_volver.get_path()
	_btn_volver.focus_neighbor_top = _btn_volver.get_path()
	_btn_volver.focus_neighbor_bottom = _btn_volver.get_path()
	_btn_volver.focus_next = _btn_volver.get_path()
	_btn_volver.focus_previous = _btn_volver.get_path()


func _aplicar_tallas() -> void:
	if not is_node_ready():
		return
	var s := clampf(hud_scale, 0.9, 1.15)
	# Guarda 18px aparente: compensa a ceil(18/scale) cuando scale < 1.
	var f := func(base: int) -> int: return maxi(base, int(ceil(float(FUENTE_MIN) / s)))
	_desc_objeto.add_theme_font_size_override(&"font_size", f.call(TALLA_DESC))
	_btn_volver.add_theme_font_size_override(&"font_size", f.call(TALLA_ETIQUETA))
	_desc_objeto.add_theme_color_override(&"font_color", GRIS_SUAVE)
	_btn_volver.add_theme_color_override(&"font_color", GRIS_LUZ)


func _aplicar_escala() -> void:
	if not is_node_ready():
		return
	scale = Vector2(hud_scale, hud_scale)
	_aplicar_tallas()

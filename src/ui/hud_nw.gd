class_name HudNW
extends Control

## Esquina NW persistente: Vida del jugador + Gracia (hud.md Must Show).
##
## Display-only: nunca posee estado. Recibe valores del presentador y los
## refleja en `ProgressBar` (Vida, StyleBoxFlat) y `GraciaShards` (_draw).
## No congela en hitstop (C14): este control no lee `Engine.time_scale`.

const GRIS_OSCURO := Color("2A2E36")
const GRIS_MEDIO := Color("9AA2AF")
const GRIS_LUZ := Color("C7CDD6")
## Alerta #C75C4A = 3.28:1 solo → siempre con borde grueso + forma (no solo color).
const FALLO := Color("C75C4A")
const TINTA := Color("14110E")

## Ancho de barra NW (budget NW ≤6% a 1280x800).
const ANCHO_BARRA: float = 260.0
const ALTO_BARRA: float = 12.0
## Tamaño mínimo de fuente aparente (legible en Deck 7" a 30-40cm).
const FUENTE_MIN: int = 18

var _vida_bar: ProgressBar
var _vida_label: Label
var _gracia_label: Label
var _gracia: GraciaShards
var _exact_label: Label
var _flash_vida_ms: int = 0
## Fotosensibilidad: si true, cero cambio de color como señal (forma + outline).
var usar_icono_en_vez_de_flash: bool = false
## Marca de forma (rombo/triángulo) cuando el flash es no-cromático.
var _flash_forma_ms: int = 0
## Decisión absorber/rechazar: SOLO Gracia visible (hud.md).
var _modo_decision: bool = false
## Reduced-motion: se propaga a GraciaShards.
var reduced_motion: bool = false:
	set(valor):
		reduced_motion = valor
		if is_node_ready() and _gracia != null:
			_gracia.reduced_motion = valor


## Construye estilos y textos localizados. Sin strings hardcodeados.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vida_label = _nueva_etiqueta(&"VidaBar")
	_vida_bar = _nueva_barra(100.0, GRIS_LUZ, GRIS_OSCURO)
	_gracia_label = _nueva_etiqueta(&"GraciaShards")
	_gracia = GraciaShards.new()
	_gracia.name = &"GraciaShards"
	_gracia.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exact_label = Label.new()
	_exact_label.name = &"ExactLabel"
	_exact_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exact_label.add_theme_font_size_override(&"font_size", FUENTE_MIN)
	_exact_label.add_theme_color_override(&"font_color", GRIS_LUZ)
	_exact_label.visible = false
	# Foco mínimo On Demand (no menú): FOCUS_ALL + borde 2px #C7CDD6.
	# Orden lineal documentado: NW (ExactLabel) → NE (Postura) → S (TimerExact).
	# El HUD no es menú: solo el readout exacto es focable, nada más.
	_exact_label.focus_mode = Control.FOCUS_ALL
	_exact_label.add_theme_stylebox_override(&"focus", _estilo_foco())
	for hijo in [_vida_label, _vida_bar, _gracia_label, _gracia, _exact_label]:
		add_child(hijo)
	_gracia.reduced_motion = reduced_motion
	_recolocar()
	_refrescar_textos()
	_aplicar_modo_decision()


## Vida 0..max. Event-driven en cada cambio (daño 25/golpe, F5/F8).
func set_vida(actual: float, maxima: float) -> void:
	_vida_bar.max_value = maxima
	_vida_bar.value = clampf(actual, 0.0, maxima)
	_actualizar_exacta(actual, maxima)


## Gracia por absorción (cantidades propiedad del sistema 5, pendiente).
func set_gracia(encendidas: int, total: int) -> void:
	_gracia.set_shards(encendidas, total)


## Pre-light de VE (ev.14): la Gracia se ilumina, nada más.
func set_prelight_ve(activa: bool) -> void:
	_gracia.set_prelight(activa)


## Firma VE parada (ev.15): MUEVE Gracia (avanza fill/count + prelight off
## + tick de forma) manteniendo Postura idéntica (aquí no se toca Postura).
func avanzar_firma_ve() -> void:
	_gracia.mostrar_firma_parada()


## Limpia firma VE (cierre sin parar).
func limpiar_firma_ve() -> void:
	_gracia.limpiar_firma()


## Decisión absorber/rechazar (hud.md): SOLO Gracia a alta luminancia.
## Oculta VidaBar + labels Vida; activa highlight_decision en GraciaShards.
func set_modo_decision(solo_gracia: bool) -> void:
	_modo_decision = solo_gracia
	_aplicar_modo_decision()


## Flash único al fallar (ev.5), 1-2 ticks, sin ease-in.
## Respeta disable_damage_flash: si true → FORMA (rombo/triángulo +
## outline grueso 3px) con CERO cambio de color como señal.
## Si false → #C75C4A + borde grueso claro + forma (respaldo no-cromático).
func flash_fallo() -> void:
	_flash_vida_ms = 33
	_flash_forma_ms = 33
	if usar_icono_en_vez_de_flash:
		# Cero cambio de color: fill intacto, solo outline grueso + forma.
		_restaurar_fill_vida()
		_aplicar_outline_grueso()
	else:
		var fill := _vida_bar.get_theme_stylebox(&"fill") as StyleBoxFlat
		if fill != null:
			fill.bg_color = FALLO
			# Respaldo no-cromático permanente: borde grueso claro.
			fill.border_color = GRIS_LUZ
			fill.set_border_width_all(3)
	queue_redraw()


## Estado final inmediato (animaciones skippables).
## Propaga a GraciaShards (cancela hold a valor final) y limpia forma.
func skip_animations() -> void:
	_flash_vida_ms = 0
	_flash_forma_ms = 0
	_restaurar_fill_vida()
	if _gracia != null:
		_gracia.skip_animations()
	queue_redraw()


## Visibilidad del readout exacto On Demand (Tab / Touchpad / Back).
func set_exact_visible(visible_exacta: bool, vida: float, maxima: float, gracia: int, gracia_total: int) -> void:
	_exact_label.visible = visible_exacta
	if visible_exacta:
		# Clave de localización con placeholders; sin números hardcodeados
		# en el formato (los valores vienen del juego).
		_exact_label.text = tr("HUD_NW_EXACT").format({"vida": int(vida), "max": int(maxima), "gracia": gracia, "gtotal": gracia_total})


func _process(delta: float) -> void:
	if _flash_vida_ms > 0:
		_flash_vida_ms -= int(delta * 1000.0)
		if _flash_vida_ms <= 0:
			_restaurar_fill_vida()
	if _flash_forma_ms > 0:
		_flash_forma_ms -= int(delta * 1000.0)
		if _flash_forma_ms <= 0:
			queue_redraw()
		else:
			queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED or what == NOTIFICATION_RESIZED:
		_recolocar()


func _nueva_etiqueta(nodo_gracia_o_vida: StringName) -> Label:
	var etiqueta := Label.new()
	etiqueta.name = nodo_gracia_o_vida
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.add_theme_font_size_override(&"font_size", FUENTE_MIN)
	etiqueta.add_theme_color_override(&"font_color", GRIS_LUZ)
	return etiqueta


func _nueva_barra(maximo: float, relleno: Color, fondo: Color) -> ProgressBar:
	var barra := ProgressBar.new()
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra.min_value = 0.0
	barra.max_value = maximo
	barra.value = maximo
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(ANCHO_BARRA, ALTO_BARRA)
	var estilo_fondo := StyleBoxFlat.new()
	estilo_fondo.bg_color = fondo
	estilo_fondo.set_corner_radius_all(0)
	var estilo_fill := StyleBoxFlat.new()
	estilo_fill.bg_color = relleno
	estilo_fill.set_corner_radius_all(0)
	barra.add_theme_stylebox_override(&"background", estilo_fondo)
	barra.add_theme_stylebox_override(&"fill", estilo_fill)
	return barra


func _restaurar_fill_vida() -> void:
	var fill := _vida_bar.get_theme_stylebox(&"fill") as StyleBoxFlat
	if fill != null:
		fill.bg_color = GRIS_LUZ
		fill.set_border_width_all(0)


## Outline grueso sin cambio de color (modo icono): borde 3px claro.
func _aplicar_outline_grueso() -> void:
	var fill := _vida_bar.get_theme_stylebox(&"fill") as StyleBoxFlat
	if fill != null:
		fill.border_color = GRIS_LUZ
		fill.set_border_width_all(3)


## _draw SOLO para la marca de forma del flash (rombo/triángulo recto).
## No reescribe rendering: un polígono extra 1-2 ticks, reversible.
func _draw() -> void:
	if _flash_forma_ms <= 0:
		return
	# Triángulo de aviso recto sobre la barra de Vida + rombo lateral.
	# Visible con y sin color (respaldo no-cromático permanente).
	var bx := 0.0
	var by := 24.0
	var marca := GRIS_LUZ
	if not usar_icono_en_vez_de_flash:
		marca = GRIS_LUZ
	# Triángulo recto (3 puntos, sin curvas) encima de la barra.
	var tri := PackedVector2Array([
		Vector2(bx + ANCHO_BARRA + 10.0, by - 4.0),
		Vector2(bx + ANCHO_BARRA + 22.0, by - 4.0),
		Vector2(bx + ANCHO_BARRA + 16.0, by + ALTO_BARRA + 4.0),
	])
	draw_colored_polygon(tri, marca)
	# Barra de aviso: 3px claras bajo la vida (respaldo de forma).
	draw_rect(Rect2(bx, by + ALTO_BARRA + 2.0, ANCHO_BARRA, 3.0), marca, true)


func _recolocar() -> void:
	# Safe-zone 5% a 1280x800 = (64, 40). Periferia NW, formas rectas.
	position = Vector2(64, 40)
	_vida_label.position = Vector2.ZERO
	_vida_bar.position = Vector2(0, 24)
	_gracia_label.position = Vector2(0, 44)
	_gracia.position = Vector2(0, 68)
	_gracia.size = Vector2(4 * 28.0, 24.0)
	_exact_label.position = Vector2(0, 96)


func _refrescar_textos() -> void:
	_vida_label.text = tr("HUD_HP_LABEL")
	_gracia_label.text = tr("HUD_GRACIA_LABEL")


## Opacidad solo a fondos, nunca a fills críticos (guarda 4.5:1).
func set_opacidad_fondos(opacidad: float) -> void:
	var fondo := _vida_bar.get_theme_stylebox(&"background") as StyleBoxFlat
	if fondo != null:
		var c: Color = GRIS_OSCURO
		c.a = clampf(opacidad, 0.6, 1.0)
		fondo.bg_color = c


## Compensación de escala: texto nunca bajo 18px aparente.
func set_compensacion_fuente(escala: float) -> void:
	var s := clampf(escala, 0.9, 1.15)
	var talla := maxi(FUENTE_MIN, int(ceil(float(FUENTE_MIN) / s)))
	_vida_label.add_theme_font_size_override(&"font_size", talla)
	_gracia_label.add_theme_font_size_override(&"font_size", talla)
	_exact_label.add_theme_font_size_override(&"font_size", talla)


## Accesor para la cadena de foco lineal NW → NE → S.
func get_exact_focusable() -> Control:
	return _exact_label


## Estilo de foco visible: borde 2px #C7CDD6.
func _estilo_foco() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(2)
	sb.border_color = GRIS_LUZ
	sb.bg_color = Color(0, 0, 0, 0)
	sb.draw_center = false
	return sb


## Aplica el modo decisión: oculta Vida, muestra solo Gracia en alta luz.
func _aplicar_modo_decision() -> void:
	if not is_node_ready():
		return
	_vida_bar.visible = not _modo_decision
	_vida_label.visible = not _modo_decision
	# Gracia siempre visible; en decisión a alta luminancia.
	_gracia_label.visible = true
	_gracia.visible = true
	_gracia.highlight_decision = _modo_decision
	_gracia.queue_redraw()


func _actualizar_exacta(actual: float, maxima: float) -> void:
	if _exact_label.visible:
		_exact_label.text = tr("HUD_NW_EXACT").format({"vida": int(actual), "max": int(maxima), "gracia": 0, "gtotal": 0})

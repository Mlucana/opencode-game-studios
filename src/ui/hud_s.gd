class_name HudS
extends Control

## Zona S (abajo-centro): Timer de castigo 120 ticks como BARRA (hud.md C1).
##
## Display-only. Barra gris frío de alta luminancia, 400x8, lineal
## izquierda→derecha, sin número (la periferia lee luminancia/movimiento,
## no croma). Aparece/desaparece sin ease; nunca en el centro 60%.
## Continuo durante Aturdido; pausado en Pausa (lo congela `CombatHud`).

const GRIS_OSCURO := Color("2A2E36")
const GRIS_LUZ := Color("C7CDD6")
const GRIS_CONTRASTE := Color("E8ECF1")

const ANCHO_TIMER: float = 400.0
const ALTO_TIMER: float = 8.0
const FUENTE_MIN: int = 18

var timer_alto_contraste: bool = false
## Reduced-motion: sin pulso. Timer es barra lineal inmediata por diseño.
var reduced_motion: bool = false

var _timer_bar: ProgressBar
var _exact_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_bar = ProgressBar.new()
	_timer_bar.name = &"TimerBar"
	_timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_bar.min_value = 0.0
	_timer_bar.max_value = 120.0
	_timer_bar.value = 120.0
	_timer_bar.show_percentage = false
	_timer_bar.custom_minimum_size = Vector2(ANCHO_TIMER, ALTO_TIMER)
	_timer_bar.fill_mode = ProgressBar.FILL_BEGIN_TO_END
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = GRIS_OSCURO
	fondo.set_corner_radius_all(0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = GRIS_LUZ
	fill.set_corner_radius_all(0)
	_timer_bar.add_theme_stylebox_override(&"background", fondo)
	_timer_bar.add_theme_stylebox_override(&"fill", fill)
	_exact_label = Label.new()
	_exact_label.name = &"TimerExact"
	_exact_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exact_label.add_theme_font_size_override(&"font_size", FUENTE_MIN)
	_exact_label.add_theme_color_override(&"font_color", GRIS_LUZ)
	_exact_label.visible = false
	# Foco mínimo On Demand (no menú): FOCUS_ALL + borde 2px #C7CDD6.
	# Orden lineal documentado: NW (ExactLabel) → NE (Postura/VidaJefe) → S (TimerExact).
	_exact_label.focus_mode = Control.FOCUS_ALL
	_exact_label.add_theme_stylebox_override(&"focus", _estilo_foco())
	add_child(_timer_bar)
	add_child(_exact_label)
	_recolocar()
	_aplicar_contraste()


## Tick continuo del Aturdido. `restantes` y `total` en ticks enteros.
func set_timer(restantes: int, total: int) -> void:
	_timer_bar.max_value = float(maxi(1, total))
	_timer_bar.value = clampf(float(restantes), 0.0, float(total))
	if _exact_label.visible:
		_exact_label.text = tr("HUD_TIMER_EXACT").format({"rest": restantes, "total": total})


## Solo Aturdido. Sin ease de entrada/salida.
func set_visible_timer(visible_timer: bool) -> void:
	visible = visible_timer


## Knob `timer_high_contrast` (default true en Deck). Nunca bajo 4.5:1
## de luminancia: aquí solo se SUBE hacia #E8ECF1, nunca se baja.
func set_alto_contraste(activo: bool) -> void:
	timer_alto_contraste = activo
	_aplicar_contraste()


func set_exact_visible(visible_exacta: bool) -> void:
	_exact_label.visible = visible_exacta


## Estado final inmediato: el timer ya es directo (sin drenaje animado);
## este método existe para el contrato skip_animations() completo.
func skip_animations() -> void:
	# Sin animación pendiente: el valor ya es final. Solo redibuja.
	queue_redraw()


## Opacidad solo a fondos, nunca a fills críticos (guarda 4.5:1).
## El fill del timer y el label crítico quedan opacos siempre.
func set_opacidad_fondos(opacidad: float) -> void:
	var fondo := _timer_bar.get_theme_stylebox(&"background") as StyleBoxFlat
	if fondo != null:
		var c: Color = GRIS_OSCURO
		c.a = clampf(opacidad, 0.6, 1.0)
		fondo.bg_color = c


## Compensación de escala: el texto nunca baja de 18px aparente.
## Si hud_scale < 1.0, se sube la fuente base a ceil(18/scale).
func set_compensacion_fuente(escala: float) -> void:
	var s := clampf(escala, 0.9, 1.15)
	_exact_label.add_theme_font_size_override(&"font_size", maxi(FUENTE_MIN, int(ceil(float(FUENTE_MIN) / s))))


## Accesor para la cadena de foco lineal NW → NE → S (gestionada por CombatHud).
func get_exact_focusable() -> Control:
	return _exact_label


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED or what == NOTIFICATION_RESIZED:
		_recolocar()


func _aplicar_contraste() -> void:
	var fill := _timer_bar.get_theme_stylebox(&"fill") as StyleBoxFlat
	if fill != null:
		fill.bg_color = GRIS_CONTRASTE if timer_alto_contraste else GRIS_LUZ


## Estilo de foco visible: borde 2px #C7CDD6 (8.51:1 sobre #2A2E36).
func _estilo_foco() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(2)
	sb.border_color = GRIS_LUZ
	sb.bg_color = Color(0, 0, 0, 0)
	sb.draw_center = false
	return sb


func _recolocar() -> void:
	# Abajo-centro, safe-zone 5% inferior (40px a 800). Nunca centro 60%.
	var vista := get_viewport_rect().size
	if vista.x <= 0.0:
		vista = Vector2(1280, 800)
	position = Vector2((vista.x - ANCHO_TIMER) * 0.5, vista.y - 40.0 - ALTO_TIMER - 20.0)
	_timer_bar.position = Vector2.ZERO
	_timer_bar.size = Vector2(ANCHO_TIMER, ALTO_TIMER)
	_exact_label.position = Vector2(0, ALTO_TIMER + 4.0)

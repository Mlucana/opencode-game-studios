class_name HudNE
extends Control

## Esquina NE contextual: Postura + Vida del jefe (hud.md, solo en duelo).
##
## Display-only. Fuera de duelo, colapsada (`set_en_duelo(false)` la
## oculta sin animación invasiva). Postura vía `PosturaBlocks` (_draw,
## 4 bloques); Vida del jefe vía `ProgressBar` + StyleBoxFlat, sin pulso
## propio, solo daño bruto (ev.11).

const GRIS_OSCURO := Color("2A2E36")
## Fill informativo Vida jefe + outlines Postura: #9AA2AF = 5.29:1 (≥4.5:1).
const GRIS_MEDIO := Color("9AA2AF")
const GRIS_LUZ := Color("C7CDD6")

const ANCHO_BARRA: float = 260.0
const ALTO_BARRA_FINA: float = 8.0
const FUENTE_MIN: int = 18

var _postura_label: Label
var _postura: PosturaBlocks
var _jefe_label: Label
var _jefe_bar: ProgressBar
## Reduced-motion: se propaga a PosturaBlocks (sin pulso).
var reduced_motion: bool = false:
	set(valor):
		reduced_motion = valor
		if is_node_ready() and _postura != null:
			_postura.reduced_motion = valor


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_postura_label = _nueva_etiqueta(&"PosturaBlocks")
	_postura = PosturaBlocks.new()
	_postura.name = &"PosturaBlocks"
	_postura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_jefe_label = _nueva_etiqueta(&"VidaJefeBar")
	_jefe_bar = ProgressBar.new()
	_jefe_bar.name = &"VidaJefeBar"
	_jefe_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_jefe_bar.min_value = 0.0
	_jefe_bar.max_value = 100.0
	_jefe_bar.value = 100.0
	_jefe_bar.show_percentage = false
	_jefe_bar.custom_minimum_size = Vector2(ANCHO_BARRA, ALTO_BARRA_FINA)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = GRIS_OSCURO
	fondo.set_corner_radius_all(0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = GRIS_MEDIO
	fill.set_corner_radius_all(0)
	_jefe_bar.add_theme_stylebox_override(&"background", fondo)
	_jefe_bar.add_theme_stylebox_override(&"fill", fill)
	for hijo in [_postura_label, _postura, _jefe_label, _jefe_bar]:
		add_child(hijo)
	_postura_label.text = tr("HUD_POSTURA_LABEL")
	_jefe_label.text = tr("HUD_JEFE_LABEL")
	# Foco mínimo On Demand (no menú): eslabón intermedio NW → NE → S.
	# PosturaBlocks como contenedor exacto NE + VidaJefe como segundo foco.
	_postura.focus_mode = Control.FOCUS_ALL
	_postura.add_theme_stylebox_override(&"focus", _estilo_foco())
	_jefe_bar.focus_mode = Control.FOCUS_ALL
	_jefe_bar.add_theme_stylebox_override(&"focus", _estilo_foco())
	_postura.reduced_motion = reduced_motion
	_recolocar()


## En cada parry / ruptura / restauración. En VE no se llama (firma V6).
func set_postura(actual: float, maxima: float) -> void:
	_postura.set_postura(actual, maxima)


## Solo en Castigo conectado (F6). Sin pulso propio.
func set_vida_jefe(actual: float, maxima: float) -> void:
	_jefe_bar.max_value = maxima
	_jefe_bar.value = clampf(actual, 0.0, maxima)


## Colapso NE fuera de duelo / hub. Sin animación de entrada invasiva.
func set_en_duelo(en_duelo: bool) -> void:
	visible = en_duelo


## Estado final inmediato: propaga a PosturaBlocks (cancela hold a final).
func skip_animations() -> void:
	if _postura != null:
		_postura.skip_animations()


## Opacidad solo a fondos, nunca a fills críticos (guarda 4.5:1).
func set_opacidad_fondos(opacidad: float) -> void:
	var fondo := _jefe_bar.get_theme_stylebox(&"background") as StyleBoxFlat
	if fondo != null:
		var c: Color = GRIS_OSCURO
		c.a = clampf(opacidad, 0.6, 1.0)
		fondo.bg_color = c


## Compensación de escala: texto nunca bajo 18px aparente.
func set_compensacion_fuente(escala: float) -> void:
	var s := clampf(escala, 0.9, 1.15)
	var talla := maxi(FUENTE_MIN, int(ceil(float(FUENTE_MIN) / s)))
	_postura_label.add_theme_font_size_override(&"font_size", talla)
	_jefe_label.add_theme_font_size_override(&"font_size", talla)


## Accesor para la cadena de foco lineal NW → NE → S.
func get_focusable() -> Control:
	return _postura


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED or what == NOTIFICATION_RESIZED:
		_recolocar()


func _nueva_etiqueta(nombre: StringName) -> Label:
	var etiqueta := Label.new()
	etiqueta.name = nombre
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.add_theme_font_size_override(&"font_size", FUENTE_MIN)
	etiqueta.add_theme_color_override(&"font_color", GRIS_LUZ)
	return etiqueta


## Estilo de foco visible: borde 2px #C7CDD6.
func _estilo_foco() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(2)
	sb.border_color = GRIS_LUZ
	sb.bg_color = Color(0, 0, 0, 0)
	sb.draw_center = false
	return sb


func _recolocar() -> void:
	# Espejo de NW: safe-zone 5% desde arriba-der. (64, 40) a 1280x800.
	var ancho_vista := 1280.0
	if get_viewport_rect().size.x > 0.0:
		ancho_vista = get_viewport_rect().size.x
	position = Vector2(ancho_vista - 64.0 - ANCHO_BARRA, 40.0)
	_postura_label.position = Vector2.ZERO
	_postura.position = Vector2(0, 24)
	_postura.size = Vector2(ANCHO_BARRA, 14.0)
	_jefe_label.position = Vector2(0, 44)
	_jefe_bar.position = Vector2(0, 68)

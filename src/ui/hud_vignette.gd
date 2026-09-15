class_name HudVignette
extends Control

## Bordes del HUD: vignette de tinta + flash único de fallo (hud.md #6).
##
## Display-only. Regla de oro: lo que sale mal = ausencia de luz, nunca
## flash de luz punitivo. El único flash permitido es #C75C4A sobre el
## HUD de vida al fallar (evento 5). Muerte = tinta total + corte seco.
## Reduced-motion: sin vignette pulsante ni shake; el hitstop (gameplay)
## se mantiene y lo gobierna el mundo, nunca este control.

const TINTA := Color("14110E")
## Alerta #C75C4A = 3.28:1 sobre #2A2E36 (no pasa solo) → siempre con
## forma gruesa + patrón además de color. Hex final inalterado (paleta alerta).
const FALLO := Color("C75C4A")
const GRIS_LUZ := Color("C7CDD6")

## Intensidad 0..1 de vignette por vida baja (progresiva) o muerte (1.0).
var intensidad: float = 0.0
## Flash de fallo activo (un disparo, 2 frames enteros, sin ease-in).
## Frames, nunca ms: `delta` escala en hitstop y truncaba a 3 frames (hud-001 B1).
const FLASH_FRAMES: int = 2
var _flash_restante_frames: int = 0
## Alternativa no-cromática al flash (knob `disable_damage_flash`).
var usar_icono_en_vez_de_flash: bool = false
## Reduced-motion (precedencia story-005): sin pulsación y cero flashes.
## Al activarse colapsa cualquier flash en vuelo a estado final (corte 1 frame).
var reduced_motion: bool = false:
	set(valor):
		reduced_motion = valor
		if valor:
			_flash_restante_frames = 0
			if is_node_ready():
				queue_redraw()
## Pausa: congela vignette (no queue_redraw pulsante, no avanza reloj).
## Lo fija CombatHud._aplicar_estado (PAUSA → true). S oculto + timer
## congelado ya existen en CombatHud.
var pausado: bool = false

var _tiempo_ms: int = 0


## Dispara el flash único de fallo (evento 5). 2 frames exactos.
## Precedencia story-005: con reduced-motion, cero flashes — el feedback
## viaja por bus y la vignette queda en su intensidad estática.
func flash_fallo() -> void:
	if reduced_motion:
		return
	_flash_restante_frames = FLASH_FRAMES
	queue_redraw()


## Fija la vignette de tinta (vida baja progresiva / muerte total).
func set_intensidad(valor: float) -> void:
	intensidad = clampf(valor, 0.0, 1.0)
	queue_redraw()


## Corta toda animación al estado final (animaciones skippables).
func skip_animations() -> void:
	_flash_restante_frames = 0
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	# Pausa congela vignette: early-return, ni reloj ni redraw pulsante.
	if pausado:
		return
	_tiempo_ms += int(delta * 1000.0)
	if _flash_restante_frames > 0:
		_flash_restante_frames -= 1
		queue_redraw()
	elif intensidad > 0.0 and not reduced_motion:
		# Sin pulso en reduced-motion. Fuera de él, latido solo como
		# modulación de alfa de tinta (nunca flash de luz).
		queue_redraw()


func _draw() -> void:
	if intensidad <= 0.0 and _flash_restante_frames <= 0:
		return
	var rect := Rect2(Vector2.ZERO, size)
	if intensidad > 0.0:
		var alfa := intensidad * 0.55
		# Tinta desde bordes: 4 bandas rectas (1 draw por banda, total ≤3
		# draws UI junto al resto del HUD en la práctica; sin texturas).
		var grosor := 48.0 * intensidad + 8.0
		var c := TINTA
		c.a = alfa
		draw_rect(Rect2(0, 0, size.x, grosor), c, true)
		draw_rect(Rect2(0, size.y - grosor, size.x, grosor), c, true)
		draw_rect(Rect2(0, 0, grosor, size.y), c, true)
		draw_rect(Rect2(size.x - grosor, 0, grosor, size.y), c, true)
	if _flash_restante_frames > 0:
		if usar_icono_en_vez_de_flash:
			# Sustituto FORMA distinta (fotosensibilidad): patrón diagonal
			# recto en GRIS_LUZ + marco grueso, estático sin parpadeo.
			# No es la misma barra 6→10px en #C75C4A: cambia forma Y color
			# base (tinta/gris, cero señal cromática de alerta).
			var marca := GRIS_LUZ
			marca.a = 0.95
			draw_rect(Rect2(0, 0, size.x, 4.0), marca, true)
			# Patrón diagonal: 10 rombos rectos (sin vocabulario circular).
			var n := 10
			var paso := size.x / float(maxi(1, n))
			for i in range(n):
				var cx := paso * float(i) + paso * 0.5
				var d := 7.0
				var rombo := PackedVector2Array([
					Vector2(cx, 8.0),
					Vector2(cx + d, 14.0),
					Vector2(cx, 20.0),
					Vector2(cx - d, 14.0),
				])
				draw_colored_polygon(rombo, marca)
		else:
			var f := FALLO
			f.a = 0.85
			draw_rect(Rect2(0, 0, size.x, 6.0), f, true)
			# Borde grueso + forma además de color (4.5:1): línea inferior
			# de 3px en GRIS_LUZ como respaldo no-cromático permanente.
			var respaldo := GRIS_LUZ
			respaldo.a = 0.9
			draw_rect(Rect2(0, 6.0, size.x, 3.0), respaldo, true)

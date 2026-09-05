class_name PosturaBlocks
extends Control

## Postura del enemigo — 4 bloques segmentados (hud.md B1, evento 8).
##
## Display-only: `set_postura()` cachea y pide `queue_redraw()`
## (event-driven). Caída visible en combo completo. NO reacciona en VE:
## esa ausencia es la firma (V6) y la gestiona `CombatHud`, no este control.
## Latch+hold de 2 frames de render contra fusión de ticks a 40Hz en Deck.

const GRIS_OSCURO := Color("2A2E36")
## Fill informativo parcial + outlines: #9AA2AF = 5.29:1 sobre #2A2E36 (≥4.5:1).
## Antes #8C94A0 = 4.45:1 (no pasaba). GRIS_LUZ #C7CDD6 = 8.51:1.
const GRIS_MEDIO := Color("9AA2AF")
const GRIS_LUZ := Color("C7CDD6")

## Retención mínima en frames de render (latch+hold anti-40Hz).
const HOLD_FRAMES: int = 2
## Segmentos fijos de la dirección B1.
const SEGMENTOS: int = 4

var _fraccion: float = 1.0
var _latched_fraccion: float = 1.0
var _hold_restante: int = 0
## Reduced-motion: sin pulso/latido. Hold anti-40Hz intacto (no es decoración).
var reduced_motion: bool = false


## Fija la fracción 0..1 a mostrar. Solo lectura; no muta estado externo.
func set_postura(actual: float, maxima: float) -> void:
	if maxima <= 0.0:
		_fraccion = 0.0
	else:
		_fraccion = clampf(actual / maxima, 0.0, 1.0)
	_latched_fraccion = _fraccion
	_hold_restante = HOLD_FRAMES
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(4 * 44.0 + 3 * 8.0, 14.0)


## Estado final inmediato: cancela hold a valor final (skippable).
func skip_animations() -> void:
	_hold_restante = 0
	_latched_fraccion = _fraccion
	queue_redraw()


func _process(_delta: float) -> void:
	if _hold_restante > 0:
		_hold_restante -= 1
		queue_redraw()


func _draw() -> void:
	# El latch retiene la caída para que 2 ticks fundidos en 1 frame
	# a 40Hz no se pierdan: se muestra el mínimo (la caída) durante el hold.
	var f: float = minf(_fraccion, _latched_fraccion if _hold_restante > 0 else _fraccion)
	var ancho_bloque := 44.0
	var alto := 14.0
	var gap := 8.0
	var y := (size.y - alto) * 0.5
	for i in range(SEGMENTOS):
		var umbral: float = float(i + 1) / float(SEGMENTOS)
		var x := float(i) * (ancho_bloque + gap)
		var rect := Rect2(x, y, ancho_bloque, alto)
		# Bloque lleno si la fracción alcanza su umbral; formas rectas.
		if f >= umbral - 0.001:
			draw_rect(rect, GRIS_LUZ, true)
		elif f > float(i) / float(SEGMENTOS):
			# Bloque parcial: relleno proporcional sin ease, 1-2 ticks.
			var parcial: float = (f - float(i) / float(SEGMENTOS)) * float(SEGMENTOS)
			draw_rect(rect, GRIS_OSCURO, true)
			draw_rect(Rect2(x, y, ancho_bloque * parcial, alto), GRIS_MEDIO, true)
			draw_rect(rect, GRIS_MEDIO, false, 2.0)
		else:
			draw_rect(rect, GRIS_OSCURO, true)
			draw_rect(rect, GRIS_MEDIO, false, 2.0)

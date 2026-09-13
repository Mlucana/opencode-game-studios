class_name GraciaShards
extends Control

## Medidor de Gracia — único vitral permitido (hud.md A1, art bible 3.4).
##
## Display-only: nunca posee estado. `set_shards()` solo cachea el valor
## y pide `queue_redraw()` (event-driven). El dibujo vive en `_draw()`
## con esquirlas en rombo (dirección A1: ◆◆◇◇), formas rectas, sin
## vocabulario circular (no compite con telegrafiados).
## Latch+hold de 2 frames de render: el valor crítico se retiene para no
## perder ticks de absorción si el render baja a 40Hz en Deck.

## Paleta hud.md (grises fríos + tinta; vitral solo aquí).
## Contrastes sobre #2A2E36: GRIS_LUZ 8.51:1, GRIS_MEDIO 5.29:1 (≥4.5:1).
const TINTA := Color("14110E")
const GRIS_OSCURO := Color("2A2E36")
const GRIS_MEDIO := Color("9AA2AF")
const GRIS_LUZ := Color("C7CDD6")
## Vitral de Gracia (art-bible §4.5): arco violeta pálido casi neutro en
## corrupción baja → vino saturado #6B1F5C en alta, con densidad de grieta
## interna en paralelo. GRACIA_LUZ #C9B8E8 = 7.46:1 sobre #2A2E36 (pasa).
## GRACIA_VINO #6B1F5C = 1.28:1 SOLO → nunca fill único; solo acento de
## grieta interna + borde claro #C7CDD6 + forma (no depende solo de color).
const GRACIA_LUZ := Color("C9B8E8")
const GRACIA_VINO := Color("6B1F5C")

## Retención mínima en frames de render (latch+hold anti-40Hz).
const HOLD_FRAMES: int = 2

## Esquirlas encendidas (lectura). Total fijado por sistema 5 (pendiente).
var _lit: int = 0
var _total: int = 4
## Pre-light de Ventana Especial (ev.14): contorno, sin cambiar conteo.
var _prelit: bool = false
## Latch del último cambio + contador de hold en frames de render.
var _latched_lit: int = 0
var _hold_restante: int = 0
## Luminancia alta en decisión absorber/rechazar (hud.md: la decisión ES gracia).
var highlight_decision: bool = false
## Firma VE parada (ev.15): tick/forma además de color. No muta Postura.
var _firma_parada: bool = false
## Reduced-motion: sin pulso/latido; hold anti-40Hz intacto (no es decoración).
var reduced_motion: bool = false


## Fija el valor a mostrar. Solo lectura del juego; no muta estado externo.
func set_shards(encendidas: int, total: int) -> void:
	_total = maxi(1, total)
	_lit = clampi(encendidas, 0, _total)
	_latched_lit = _lit
	_hold_restante = HOLD_FRAMES
	# El valor real sustituye la anticipación visual de firma parada.
	_firma_parada = false
	queue_redraw()


## Pre-iluminación de VE (ev.14). No cambia el conteo, solo el contorno.
func set_prelight(activa: bool) -> void:
	_prelit = activa
	if activa:
		_firma_parada = false
	queue_redraw()


## Firma VE parada (ev.15): MUEVE Gracia (avanza fill/count visible +1 con
## hold, apaga prelight) manteniendo Postura idéntica (este control jamás
## toca Postura). Añade FORMA (tick triangular sobre la última encendida +
## contorno grueso) además de color, para no depender solo de croma.
func mostrar_firma_parada() -> void:
	_prelit = false
	_firma_parada = true
	# Sin pre-incremento: el +1 visible lo aplica `_draw()` (una sola vez),
	# dentro y fuera del hold. Pre-incrementar aquí mostraba +2 con hold.
	_latched_lit = _lit
	_hold_restante = HOLD_FRAMES
	queue_redraw()


## Limpia la marca de firma (cierre VE sin parar / nuevo ciclo).
func limpiar_firma() -> void:
	_firma_parada = false
	_prelit = false
	queue_redraw()


## Estado final inmediato: cancela hold a valor final (skippable).
## Reversible: solo fija latch = valor lógico y redibuja.
func skip_animations() -> void:
	_hold_restante = 0
	_latched_lit = _lit
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(4 * 28.0, 24.0)


func _process(_delta: float) -> void:
	# Hold de 2 frames: retiene el latch aunque lleguen ticks fundidos a 40Hz.
	if _hold_restante > 0:
		_hold_restante -= 1
		queue_redraw()


func _draw() -> void:
	var dibujadas: int = maxi(_lit, _latched_lit if _hold_restante > 0 else _lit)
	# Firma parada MUEVE Gracia: +1 visible con hold (sin mutar _lit lógico).
	if _firma_parada:
		dibujadas = mini(maxi(dibujadas + 1, _latched_lit), _total)
	var paso := 28.0
	var radio := Vector2(9.0, 11.0)
	var centro_y := size.y * 0.5
	for i in range(_total):
		var cx := 12.0 + float(i) * paso
		var rombo := PackedVector2Array([
			Vector2(cx, centro_y - radio.y),
			Vector2(cx + radio.x, centro_y),
			Vector2(cx, centro_y + radio.y),
			Vector2(cx - radio.x, centro_y),
		])
		var encendida: bool = i < dibujadas
		var relleno: Color = GRACIA_LUZ if encendida else GRIS_OSCURO
		# Alta luminancia en Decisión por borde/contorno (línea 134), jamás
		# grisando el vitral: el fill sigue GRACIA_LUZ (DEC-17, art-bible 3.4).
		draw_colored_polygon(rombo, relleno)
		# Grieta interna vino (art-bible §4.5): densidad crece con índice.
		# Vino nunca solo (1.28:1) — siempre sobre fill claro + borde claro.
		# Intacto también en highlight_decision (respaldo de forma DEC-17).
		if encendida:
			var grieta := GRACIA_VINO
			grieta.a = 0.9
			# 1 línea en mitad baja, 2ª línea si corrupción alta (i >= total/2).
			draw_line(Vector2(cx - 4.0, centro_y + 1.0), Vector2(cx + 4.0, centro_y - 3.0), grieta, 1.5)
			if i >= _total / 2:
				draw_line(Vector2(cx - 4.0, centro_y + 5.0), Vector2(cx + 4.0, centro_y + 1.0), grieta, 1.5)
		var borde: Color = GRIS_LUZ if (_prelit or highlight_decision or _firma_parada) else GRIS_MEDIO
		var grosor_borde := 3.0 if _firma_parada and encendida else 2.0
		# Polilínea cerrada: 5 puntos (repite el primero).
		var contorno := PackedVector2Array([rombo[0], rombo[1], rombo[2], rombo[3], rombo[0]])
		draw_polyline(contorno, borde, grosor_borde)
		# FORMA además de color (firma parada): tick triangular recto sobre
		# la última encendida — legible sin croma, sin vocabulario circular.
		if _firma_parada and i == dibujadas - 1 and dibujadas > 0:
			var tick := PackedVector2Array([
				Vector2(cx - 5.0, centro_y - radio.y - 4.0),
				Vector2(cx + 5.0, centro_y - radio.y - 4.0),
				Vector2(cx, centro_y - radio.y - 10.0),
			])
			draw_colored_polygon(tick, GRIS_LUZ)

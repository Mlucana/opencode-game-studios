class_name MockResolver
extends RefCounted

## Mock del CombatResolver para tests — emite las C-* canónicas (ADR-002 §3).
##
## SOLO para tests (hud-002/hud-003 y futuros gates de cableado). No resuelve
## nada: el test decide qué resultado emitir y cuándo. Determinista y sin escena
## (RefCounted): el orden lo fija el test, nunca el árbol de nodos — la misma
## razón por la que `BossStub.avanzar_tick()` es público.
##
## Canónico: ADR-002 §3. Si una firma difiere del ADR, manda el ADR.
## Payloads cerrados: ni un campo más sin enmienda bilateral (ADR-002 §3-notas).

## Resultado de `parry_resuelto`. Orden y valores = ADR-002 §4 (enum propio).
enum Resultado {
	EXITO_GOLPE = 0,
	EXITO_VENTANA_ESPECIAL = 1,
	WHIFF = 2,
	FALLO_CONECTADO = 3,
}

## Ver ADR-002 §3. `delta_ticks = -1` si no aplica (VE, whiff).
signal parry_resuelto(resultado: int, window_id: int, tick_deteccion: int, delta_ticks: int, postura_resultante: float)
## Press ya clasificado como Castigo (borde inclusivo, nunca literal — ADR-002 §5).
signal castigo_iniciado(tick_pulsacion: int)
## El resolver posee la Vida: la derrota la emite él (ADR-002 §1).
signal duelo_perdido(tick: int)

## Tick sellado (DiegeticTick) que viaja en los payloads. Solo avanza vía
## `avanzar_tick()` / `fijar_tick()` — nunca reloj de motor.
var _tick: int = 0


## Avanza un tick de simulación. Para tests puros sin gate.
func avanzar_tick() -> void:
	_tick += 1


## Fija el tick desde un gate autoritativo (WallTick/DiegeticTick). Para
## integración: así el tick del mock y el del gate no derivan en silencio.
func fijar_tick(t: int) -> void:
	assert(t >= 0, "El tick del gate no puede ser negativo")
	_tick = t


## Tick actual del mock (último avanzado o fijado).
func tick_actual() -> int:
	return _tick


## Éxito contra Golpe: Gracia + hitstop + daño de Postura + Repliegue (el
## consumidor decide; aquí solo viaja el payload).
func emitir_exito_golpe(window_id: int, delta_ticks: int, postura: float) -> void:
	parry_resuelto.emit(Resultado.EXITO_GOLPE, window_id, _tick, delta_ticks, postura)


## Éxito contra Ventana Especial: `delta_ticks = -1` SIEMPRE (sin calidad,
## sin Justo, sin bono — ADR-002 §3-notas). Un VE con delta ≥ 0 es corrupto.
func emitir_exito_ve(window_id: int, postura: float) -> void:
	parry_resuelto.emit(Resultado.EXITO_VENTANA_ESPECIAL, window_id, _tick, -1, postura)


## Whiff: sin ventana (`window_id = -1`), sin delta. `postura` es la vigente
## (el whiff no la toca; viaja para que el consumidor no infiera nada).
func emitir_whiff(postura: float) -> void:
	parry_resuelto.emit(Resultado.WHIFF, -1, _tick, -1, postura)


## Fallo conectado: el Golpe conecta (25 de daño en producción). Viaja delta
## y postura igual que el éxito — el consumidor distingue por `resultado`.
func emitir_fallo(window_id: int, delta_ticks: int, postura: float) -> void:
	parry_resuelto.emit(Resultado.FALLO_CONECTADO, window_id, _tick, delta_ticks, postura)


## Press clasificado como Castigo. Sella el tick de pulsación.
func emitir_castigo() -> void:
	castigo_iniciado.emit(_tick)


## Derrota del jugador (Vida agotada). Terminal del duelo por el lado Combate.
func emitir_derrota() -> void:
	duelo_perdido.emit(_tick)

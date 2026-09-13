class_name MockWallTick
extends RefCounted

## Mock del WallTick (reloj de pared) para tests — doble contador pared/diegético
## con freeze (ADR-001 Pattern-A, `architecture.md` TimeAuthority).
##
## SOLO para tests (hud-003 C14 y futuros gates de freeze). Regla de oro: la
## PARED avanza siempre (el HUD vive a 60Hz durante el hitstop); lo DIEGÉTICO
## se detiene mientras el freeze está activo. El árbol pausado de verdad
## (`SceneTree.paused`, `PROCESS_MODE_ALWAYS/PAUSABLE`) es problema del test de
## hud-003 con `scene_runner` — este mock da relojes deterministas, no nodos.
##
## NO es `TimeAuthority` (`src/core/`): aquel es un stub provisional
## pre-arquitectura (`ticked`/escala de apariencia) pendiente de reescritura.
## Cuando el ADR de tiempo aterrice, este mock se adapta a sus nombres; los
## tests que solo lean `tick_pared()`/`tick_diegetico()` no cambian.

## Pared: un tick por `avanzar_tick()`, con freeze o sin él (C14).
signal pared_tick(tick: int)
## Se abre un freeze de `duracion_ticks` (mundo al 0%, HUD a 1.0x).
signal freeze_started(duracion_ticks: int)
## El freeze se agota. Punto de confirmación (shards/shake ≤10, owner #4).
signal freeze_finalizado()

var _pared: int = 0
var _diegetico: int = 0
var _freeze_restante: int = 0


## Avanza un tick de pared. Si hay freeze activo, lo diegético NO avanza y el
## freeze descuenta; al agotarse emite `freeze_finalizado` exactamente una vez.
func avanzar_tick() -> void:
	_pared += 1
	pared_tick.emit(_pared)
	if _freeze_restante > 0:
		_freeze_restante -= 1
		if _freeze_restante == 0:
			freeze_finalizado.emit()
	else:
		_diegetico += 1


## Abre un freeze de `duracion` ticks. `duracion >= 1` (un freeze de 0 ticks
## no congela nada y escondería un bug de conteo en el test).
func iniciar_freeze(duracion: int) -> void:
	assert(duracion >= 1, "Un freeze dura al menos 1 tick")
	_freeze_restante = duracion
	freeze_started.emit(duracion)


## `true` mientras el mundo está congelado (diegético detenido, pared viva).
func esta_congelado() -> bool:
	return _freeze_restante > 0


## Ticks restantes del freeze en curso (0 fuera de freeze).
func freeze_restante() -> int:
	return _freeze_restante


## Reloj de pared (presentación, HUD, espías). Nunca se detiene.
func tick_pared() -> int:
	return _pared


## Reloj diegético (resolución, FSM, contadores de diseño). Detenido en freeze.
func tick_diegetico() -> int:
	return _diegetico


## Resetea ambos relojes y cancela el freeze sin emitir. Para `setup()` de tests.
## Sin emisión a propósito: resetear no es un suceso del juego.
func reiniciar() -> void:
	_pared = 0
	_diegetico = 0
	_freeze_restante = 0

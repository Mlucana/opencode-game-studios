class_name TimeAuthority
extends Node

## STUB pendiente de `/create-architecture` — NO definitivo.
##
## Autoridad de tiempo provisional para desacoplar el HUD del reloj global.
## `hud.md` Open Questions exige un mecanismo de tiempo diegético sin
## `Engine.time_scale` (global en Godot 4.7) que deje el HUD a velocidad
## normal (C14: hitstop mundo al 4% 5 ticks, HUD sigue a 60Hz).
## Este stub existe SOLO para que `src/ui/` compile y los tests de
## presentador puedan inyectar ticks enteros sin depender del ADR real.
##
## Contrato provisional (sujeto a reescritura total por arquitectura):
## - Todo lo temporal se expresa en TICKS ENTEROS de simulación fija a 60Hz.
## - `game_scale` es un escalar de APARIENCIA para el mundo, nunca para el HUD.
## - El HUD (`CombatHud`, `process_mode = ALWAYS`) NO lee `game_scale`.
##
## NO usar `Engine.time_scale` desde la UI. NO tratar este fichero como
## decisión de arquitectura: requiere ADR propio (`docs/architecture/`).

## Tick entero de simulación. Solo crece vía `advance_tick()`.
var tick: int = 0

## Escala de juego provisional para el MUNDO. El HUD la ignora por diseño.
var game_scale: float = 1.0

## Emitida en cada tick avanzado. Conexión directa (no diferida) por defecto.
signal ticked(new_tick: int)


## Avanza un tick entero de simulación y notifica.
func advance_tick() -> void:
	tick += 1
	ticked.emit(tick)


## Fija la escala del mundo. Solo apariencia; el HUD no la consume.
func set_game_scale(nueva_escala: float) -> void:
	game_scale = nueva_escala

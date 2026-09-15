class_name RunGatewayStub
extends RefCounted

## Stub Run #3 C1 frozen — solo tests (M-002).
##
## Congela las firmas stub de Run #3 sin implementar su interior (Out of Scope
## M-002: cuerpo `instantiate_run`, timeout/rechazo `run_viva_visible`):
## `instantiate_run(snapshot: Dictionary) -> String` retorna `run_uuid` y solo
## cuenta `instantiations` (nunca instancia nada real); la confirmación viaja por
## `MenuContinuarController.confirmar_run_viva_visible(payload)` con payload
## exacto `{run_uuid: String, coro_idx: int}`.
## Timeout y ruta de rechazo (pantalla+motivo keyed; sin confirmación no hay
## transición — GDD Menú §#3 Run) documentados como STUB sin enforce: este stub
## no expira nada ni rechaza nada; el controlador no transiciona sin confirmación
## por construcción (el test lo asevera como no-transición).
## Señal `run_viva_visible` incluida como costura observable para el futuro Run
## real (hoy el test la emite a mano vía `emitir_run_viva_visible()` o llama
## directo al controlador; ambas vías portan el mismo payload pineado).

## Costura observable futura (hoy la emite el test a mano; Run #3 la hará suya).
signal run_viva_visible(payload: Dictionary)

var _instantiations: int = 0
var _ultimo_snapshot: Dictionary = {}
var _ultimo_run_uuid: String = ""
var _secuencia: int = 0


## Stub `instantiate_run`: cuenta UNA instanciación y retorna `run_uuid`
## determinista (`run-<n>`). Copia profunda del snapshot (el stub nunca muta al
## llamador). Sin timeout, sin rechazo, sin escena — a propósito.
func instantiate_run(snapshot: Dictionary) -> String:
	_instantiations += 1
	_secuencia += 1
	_ultimo_snapshot = (snapshot as Dictionary).duplicate(true)
	_ultimo_run_uuid = "run-%d" % _secuencia
	return _ultimo_run_uuid


## Emite la costura `run_viva_visible` con el payload pineado C1. Retorna el
## payload emitido (el test lo reenvía al controlador).
func emitir_run_viva_visible(coro_idx: int, run_uuid: String = "") -> Dictionary:
	var uuid: String = run_uuid if run_uuid != "" else _ultimo_run_uuid
	var payload: Dictionary = {"run_uuid": uuid, "coro_idx": coro_idx}
	run_viva_visible.emit(payload)
	return payload


## Instanciaciones contadas (dedupe MENU-11: doble-press ⇒ `==1`).
## Solo lectura para tests.
func instantiations() -> int:
	return _instantiations


## Último snapshot recibido (copia). Solo lectura para tests.
func ultimo_snapshot() -> Dictionary:
	return (_ultimo_snapshot as Dictionary).duplicate(true)


## Último `run_uuid` retornado (""). Solo lectura para tests.
func ultimo_run_uuid() -> String:
	return _ultimo_run_uuid


## Pone a cero contadores (aislamiento entre casos). No emite.
func reiniciar() -> void:
	_instantiations = 0
	_ultimo_snapshot = {}
	_ultimo_run_uuid = ""
	_secuencia = 0

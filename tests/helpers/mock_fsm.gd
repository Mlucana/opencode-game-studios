class_name MockFSM
extends RefCounted

## Mock de la Máquina de Estados de Jefe para tests — emite las B-* canónicas
## (ADR-002 §2). SOLO para tests (hud-002/hud-003 y futuros gates C4a/E2/C5a/C3b).
##
## QUÉ NO ES. No valida transiciones, no posee Postura, no reacciona al parry:
## el test emite aperturas, cierres y transiciones en el orden que quiera medir.
## Esa pobreza es deliberada — igual que `BossStub` no valida el rango de N para
## que C16 pueda construirse un combo ilegal, este mock NO valida payloads para
## que AC-e de hud-002 pueda emitir un `combo_abortado` corrupto.
##
## Canónico: ADR-002 §§2/4. Si algo difiere del ADR, manda el ADR.
## `accion_especial_completada` NO se declara aquí: el ADR la reserva hasta la
## 4ª pasada del sistema 2 — emitirla hoy desde un mock la bautizaría antes de
## tiempo en dos historias distintas, justo lo que la reserva impide.

## Conjunto CERRADO top-level (ADR-002 §4). ASCII, sin tildes; `EN_COMBO` y
## `ACCION_ESPECIAL` resuelven los espacios. Décimo valor = enmienda Regla 7.
enum EstadoJefe {
	REPOSO,
	TELEGRAFIADO,
	GOLPE,
	EN_COMBO,
	REPLIEGUE,
	ENFRIAMIENTO,
	ATURDIDO,
	ACCION_ESPECIAL,
	MUERTO,
}

## Ver ADR-002 §2. `window_id` = entero opaco por ventana (correlaciona apertura
## con cierre y con el `parry_resuelto` del resolver). Tres hechos, tres señales,
## un mismo stack, orden fijo: cierre → resultado → transición (lo asevera C4a).
signal golpe_iniciado(window_id: int, tick_apertura: int)
signal golpe_finalizado(window_id: int, tick_cierre: int)
signal ventana_especial_abierta(window_id: int, tick_apertura: int)
signal ventana_especial_cerrada(window_id: int, fue_parada: bool, tick_cierre: int)
## 1 ≤ i ≤ N, N ∈ 3..5 en producción; el mock NO lo valida (ver cabecera).
signal combo_abortado(indice_i: int, longitud_n: int)
signal estado_ingresado(nuevo_estado: int, tick: int)
signal estado_abandonado(estado_previo: int, tick: int)
signal accion_especial_interrumpida(window_id: int, tick: int)
## Hoy solo `tick`: el payload adicional lo resuelve el sistema 3 (ADR-002 §2).
signal duelo_ganado(tick: int)

## Tick sellado que viaja en los payloads. Solo vía `avanzar_tick()`/`fijar_tick()`.
var _tick: int = 0
## `window_id` monótono por duelo (ADR-002 §5-guía 5). Se reinicia con `reiniciar()`.
var _next_window_id: int = 1


## Avanza un tick de simulación. Para tests puros sin gate.
func avanzar_tick() -> void:
	_tick += 1


## Fija el tick desde un gate autoritativo (WallTick del test de integración).
func fijar_tick(t: int) -> void:
	assert(t >= 0, "El tick del gate no puede ser negativo")
	_tick = t


## Tick actual del mock.
func tick_actual() -> int:
	return _tick


## Reinicia `window_id` y tick (nuevo duelo). Congelar en derrota descarta el
## índice en curso (ADR-002 §5-guía 5, Edge de derrota).
func reiniciar() -> void:
	_tick = 0
	_next_window_id = 1


## Abre un Golpe. Retorna su `window_id` para correlacionar el cierre.
func abrir_golpe() -> int:
	var id: int = _next_window_id
	_next_window_id += 1
	golpe_iniciado.emit(id, _tick)
	return id


## Cierra el Golpe (el resultado viaja en la C-* del resolver, nunca aquí).
func cerrar_golpe(window_id: int) -> void:
	golpe_finalizado.emit(window_id, _tick)


## Abre una Ventana Especial. Retorna su `window_id`.
func abrir_ve() -> int:
	var id: int = _next_window_id
	_next_window_id += 1
	ventana_especial_abierta.emit(id, _tick)
	return id


## Cierra la VE. `fue_parada` distingue parada (ev.15) de cierre sordo (ev.16).
func cerrar_ve(window_id: int, fue_parada: bool) -> void:
	ventana_especial_cerrada.emit(window_id, fue_parada, _tick)


## Aborto de combo con payload `i`/`N`. SIN VALIDACIÓN a propósito: el test de
## AC-e (hud-002) emite `(i,N)` corruptos para verificar RUNTIME_DROP + WARN +
## counter — un mock que se negara lo haría inejecutable.
func abortar_combo(indice_i: int, longitud_n: int) -> void:
	combo_abortado.emit(indice_i, longitud_n)


## Transición: el test emite el par abandono→ingreso en el orden que mide
## (el orden fijo cierre→resultado→transición lo orquesta el test con el
## resolver, nunca este mock).
func ingresar_estado(estado: int) -> void:
	estado_ingresado.emit(estado, _tick)


func abandonar_estado(estado: int) -> void:
	estado_abandonado.emit(estado, _tick)


## Empate interrupción/vencimiento a favor de interrupción (E2): UNA emisión,
## cero `accion_especial_completada` (que ni existe aún).
func interrumpir_ve(window_id: int) -> void:
	accion_especial_interrumpida.emit(window_id, _tick)


## Terminal del duelo por el lado jefe (estado MUERTO). Exactamente una vez.
func ganar_duelo() -> void:
	duelo_ganado.emit(_tick)

class_name BossStub
extends Node

## Stub de jefe para tests — emite los eventos de ventana con duraciones
## controladas, sin depender de la Máquina de Estados de Jefe (sistema 2).
##
## POR QUÉ EXISTE. Nueve ACs del GDD de Combate están bloqueados por la falta de
## este fixture: C12b, C19, C20, C21, C22, C23, V5, V6 y V7. La 3ª pasada de
## `/design-review` reclasificó el stub como **dependencia de calendario del
## sistema 1, no del 20**, y a C12b como **puerta de release**. Este fichero es
## ese fixture.
##
## QUÉ NO ES. No es una IA de jefe ni una máquina de estados: no valida
## transiciones, no tiene Postura, no reacciona al parry. Solo emite el par de
## eventos de `Golpe` y el par de `Ventana Especial` en los ticks que se le
## pidan, de forma determinista y repetible. Esa pobreza es deliberada — es lo
## que permite que C12a y los ACs de Ventana Especial corran **en aislamiento**,
## sin el sistema 20, que no existe.
##
## CONTRATO DE TIEMPO. Todas las duraciones son **conteos enteros de ticks de
## `_physics_process`**, nunca segundos ni frames de render (Regla 2 del GDD,
## regla normativa 1). El contador se incrementa (`_ticks_en_fase += 1`) y
## **nunca acumula `delta`**: un acumulador quedaría casi congelado durante un
## hitstop y reintroduciría exactamente el drift que esa regla existe para
## evitar.
##
## NOMBRES DE SEÑAL. Provisionales, tomados de `design/registry/entities.yaml`.
## El ADR de la Regla 8 debe fijar los nombres canónicos y el payload; hasta
## entonces estos son los del registry y cambiarlos exige actualizarlo.

## Emitido en el primer tick de una fase de tipo GOLPE.
signal golpe_iniciado()

## Emitido en el tick en que la fase GOLPE termina sin haber sido interrumpida.
signal golpe_terminado()

## Emitido en el primer tick de una fase de tipo VENTANA_ESPECIAL.
signal ventana_especial_iniciada()

## Emitido en el tick en que la Ventana Especial se cierra sin ser parada.
signal ventana_especial_terminada()

## Emitido al empezar un combo, antes del `golpe_iniciado` de su primer golpe.
## `total` es la N del combo — legal solo en `3 <= N <= 5` (Regla 9), pero el stub
## **no valida el rango**: eso es trabajo del AC C16, y un fixture que se negara a
## construir un combo ilegal impediría escribir el test que comprueba que se
## rechaza.
signal combo_iniciado(total: int)

## Emitido cuando los N golpes del combo se han emitido sin abortarse.
signal combo_completado(total: int)

## Emitido cuando el combo se corta porque el golpe `indice` conectó.
## Payload `i`/`N` — el que el registry declara y que Impacto (4) y Sonoro (16)
## consumirán.
signal combo_abortado(indice: int, total: int)

## Tipos de fase que el stub sabe representar.
##
## TELEGRAFIADO, GOLPE y ENFRIAMIENTO son el ciclo de la Regla 1. La
## VENTANA_ESPECIAL vive dentro de una `Acción Especial` y está **fuera** de ese
## ciclo, así que el stub la trata como una fase más de la secuencia en vez de
## anidarla: para lo que los ACs necesitan medir, anidar no aporta nada y sí
## acoplaría el fixture a la topología del sistema 2, que está congelado.
enum Fase {
	TELEGRAFIADO,
	GOLPE,
	ENFRIAMIENTO,
	VENTANA_ESPECIAL,
}

## Índice de `secuencia` donde empieza el combo, o −1 si la secuencia no tiene.
## Generalizado para que un ciclo en bucle (Telegrafiado → combo → Enfriamiento)
## pueda emitir `combo_iniciado` **una vez por vuelta**, que es lo que C12b
## necesita para medir 30 segundos de patrón real.
var _combo_inicio: int = -1
var _combo_total: int = 0
var _combo_indice: int = 0
var _abortar_combo_pendiente: bool = false

## Secuencia de fases a reproducir. Cada entrada es
## `{ "fase": Fase, "ticks": int }`, con `ticks >= 1`.
##
## Data-driven por exigencia de `coding-standards.md`: ningún test debe depender
## de duraciones incrustadas en este fichero. Los tests declaran su propia
## secuencia; el stub solo la ejecuta.
@export var secuencia: Array[Dictionary] = []

## Si es `true`, la secuencia vuelve a empezar al terminar. Necesario para C12a
## y C12b, que miden cobertura y tasa de acierto sobre 1800 ticks continuos.
@export var en_bucle: bool = true

## Si es `false`, el stub no avanza. Permite construir el escenario antes de
## empezar a medir, sin que el primer tick se pierda.
@export var activo: bool = false

var _indice_fase: int = 0
var _ticks_en_fase: int = 0
var _fase_iniciada: bool = false


func _physics_process(_delta: float) -> void:
	avanzar_tick()


## Avanza un tick de simulación. **Público a propósito.**
##
## Los tests llaman a esto directamente en vez de depender de `_physics_process`,
## por dos razones. Primera: así el orden entre el stub y lo que lo consume lo
## fija el test y no el árbol de nodos — que es exactamente el modo de fallo
## silencioso que la Regla 8 describe y que ningún test debería heredar sin
## querer. Segunda: sin `SceneTree` de por medio, estos dejan de ser tests de
## integración y pasan a ser **unitarios ejecutables headless**, sin escena.
func avanzar_tick() -> void:
	if not activo or secuencia.is_empty():
		return

	if _abortar_combo_pendiente:
		# El combo se corta: los golpes restantes NO llegan a ejecutarse. Se
		# salta directamente a la fase posterior al combo, que en un ciclo en
		# bucle es el Enfriamiento — el jefe "pasa a Repliegue y luego a su
		# ciclo normal" (Regla 9).
		combo_abortado.emit(_combo_indice, _combo_total)
		_abortar_combo_pendiente = false
		_fase_iniciada = false
		_indice_fase = _combo_inicio + _combo_total
		_combo_indice = 0
		if _indice_fase >= secuencia.size():
			if en_bucle:
				_indice_fase = 0
			else:
				activo = false
				return

	if not _fase_iniciada:
		_fase_iniciada = true
		_ticks_en_fase = 0
		if _combo_inicio >= 0 and _indice_fase == _combo_inicio:
			_combo_indice = 0
			combo_iniciado.emit(_combo_total)
		if _en_fase_de_combo():
			_combo_indice += 1
		_emitir_inicio(_fase_actual())

	_ticks_en_fase += 1

	if _ticks_en_fase >= _duracion_actual():
		_emitir_fin(_fase_actual())
		_avanzar()


## Arranca la secuencia desde el principio. Idempotente y determinista: dos
## llamadas producen exactamente la misma traza de eventos.
func iniciar() -> void:
	_indice_fase = 0
	_ticks_en_fase = 0
	_fase_iniciada = false
	_combo_indice = 0
	_abortar_combo_pendiente = false
	activo = true


## Detiene el stub sin emitir el evento de fin de la fase en curso.
##
## Es deliberado: un test que necesite el fin debe dejar que la fase venza. Un
## `detener()` que emitiera el cierre haría indistinguible "la ventana se cerró
## sola" de "el test la cortó", que es justo la distinción que C21 y C22 miden.
func detener() -> void:
	activo = false


## Programa un **combo** de `n` golpes consecutivos de `ticks_por_golpe` cada uno.
##
## Sin fase de Enfriamiento ni Repliegue entre ellos: la Regla 9 exige que sean
## "realmente consecutivos, sin hueco de respiro" — es lo que distingue un combo
## de una cadena de golpes simples.
func programar_combo(n: int, ticks_por_golpe: int) -> void:
	assert(n >= 1, "Un combo tiene al menos un golpe")
	secuencia = []
	for i in range(n):
		secuencia.append({ "fase": Fase.GOLPE, "ticks": ticks_por_golpe })
	_combo_inicio = 0
	_combo_total = n
	en_bucle = false
	iniciar()


## Programa un **ciclo completo en bucle** con un combo dentro:
## Telegrafiado → N golpes consecutivos → Enfriamiento → (repite).
##
## Es el patrón que **C12b** necesita: sin telegrafiado no hay nada a lo que
## "reaccionar", y sin bucle no se pueden medir los 30 segundos que el AC pide.
func programar_ciclo_con_combo(
		n: int,
		ticks_por_golpe: int,
		ticks_telegrafiado: int,
		ticks_enfriamiento: int) -> void:
	secuencia = [{ "fase": Fase.TELEGRAFIADO, "ticks": ticks_telegrafiado }]
	for i in range(n):
		secuencia.append({ "fase": Fase.GOLPE, "ticks": ticks_por_golpe })
	secuencia.append({ "fase": Fase.ENFRIAMIENTO, "ticks": ticks_enfriamiento })
	_combo_inicio = 1
	_combo_total = n
	en_bucle = true
	iniciar()


## Corta el combo en curso: los golpes restantes **no llegan a ejecutarse**.
##
## Lo invoca el consumidor cuando un golpe del combo conecta (Regla 9: "el combo
## se aborta por completo... un fallo cuesta UN golpe recibido, nunca N"). El
## corte se hace efectivo antes de emitir el siguiente `golpe_iniciado`, no en
## mitad del despacho, para no introducir reentrada en el fixture.
func abortar_combo() -> void:
	if _en_fase_de_combo():
		_abortar_combo_pendiente = true


## Disparador de depuración de Ventana Especial — **exclusivo de QA**.
##
## Emite el par `inicio`/`fin de Ventana Especial` de forma determinista y
## **sin depender de ningún patrón real del sistema 20**, que hoy no existe.
## Es el fixture compartido que los ACs C19–C23 y V5–V7 declaran necesitar; sin
## él esos siete criterios son inejecutables.
##
## `ticks` es la duración de la ventana. El stub queda inactivo al terminar, de
## modo que el test controla exactamente cuántas ventanas ocurren.
func disparar_ventana_especial(ticks: int) -> void:
	assert(ticks >= 1, "Una Ventana Especial dura al menos 1 tick")
	secuencia = [{ "fase": Fase.VENTANA_ESPECIAL, "ticks": ticks }]
	en_bucle = false
	iniciar()


## Ticks transcurridos dentro de la fase actual, base 1 durante `_physics_process`.
## Expuesto para que los tests puedan aseverar sobre el instante exacto de un
## evento sin duplicar el contador.
func ticks_en_fase() -> int:
	return _ticks_en_fase


## `true` si la fase actual es uno de los golpes del combo.
func _en_fase_de_combo() -> bool:
	if _combo_inicio < 0:
		return false
	return _indice_fase >= _combo_inicio and _indice_fase < _combo_inicio + _combo_total


func _fase_actual() -> Fase:
	return secuencia[_indice_fase]["fase"] as Fase


func _duracion_actual() -> int:
	return secuencia[_indice_fase]["ticks"] as int


func _emitir_inicio(fase: Fase) -> void:
	match fase:
		Fase.GOLPE:
			golpe_iniciado.emit()
		Fase.VENTANA_ESPECIAL:
			ventana_especial_iniciada.emit()
		_:
			pass


func _emitir_fin(fase: Fase) -> void:
	match fase:
		Fase.GOLPE:
			golpe_terminado.emit()
		Fase.VENTANA_ESPECIAL:
			ventana_especial_terminada.emit()
		_:
			pass


func _avanzar() -> void:
	_fase_iniciada = false
	_indice_fase += 1
	# ¿Se acaba de cerrar el último golpe del combo?
	if _combo_inicio >= 0 and _indice_fase == _combo_inicio + _combo_total:
		if _abortar_combo_pendiente:
			# El golpe que falló era el REMATE: el conjunto de golpes restantes
			# es vacío, pero el combo se abortó igual. C15 exige que aun así se
			# dispare Repliegue una vez y no haya Postura.
			combo_abortado.emit(_combo_indice, _combo_total)
			_abortar_combo_pendiente = false
		else:
			combo_completado.emit(_combo_total)
		_combo_indice = 0

	if _indice_fase >= secuencia.size():
		if en_bucle:
			_indice_fase = 0
		else:
			activo = false

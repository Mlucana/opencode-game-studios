class_name ParryHarness
extends RefCounted

## Banco de pruebas del ciclo de parry — **solo para tests**.
##
## QUÉ ES. Una implementación mínima de las Reglas 3, 4 y 7 del GDD de Combate,
## suficiente para que los ACs midan **comportamiento**. No es el sistema de
## combate: no hay animación, no hay feedback, no hay señales hacia fuera.
##
## POR QUÉ NO PREJUZGA EL ADR DE LA REGLA 8. El harness **consume los eventos del
## stub por señal y resuelve dentro de su propio `avanzar_tick()`**, que el test
## invoca explícitamente después del stub. Es decir: el orden lo fija el test, no
## el árbol de nodos ni una prioridad de proceso. Los ACs que esto verifica
## —C12a, C19, C20, C21, C24— miden **qué ocurre**, no **en qué call stack
## ocurre**; esa segunda pregunta es del ADR y sigue abierta. Cuando el ADR
## exista, la producción usará su mecanismo y estos tests seguirán siendo
## válidos porque nunca aseveraron sobre el mecanismo.
##
## LÍMITE DECLARADO. No modela la completación de la `Acción Especial` (no existe
## evento declarado para ese instante en ningún GDD — deuda abierta contra el
## sistema 2), así que **C22 y C23 no son ejecutables con este harness**.

## Emitida cuando un golpe conecta. El stub la consume para abortar el combo:
## es el contrato mínimo que la Regla 9 exige en el sentido jugador → jefe.
signal golpe_conectado(indice: int)

enum Estado { LIBRE, PARRY, RECUPERACION_EXITO, RECUPERACION_WHIFF }
enum Ventana { NINGUNA, GOLPE, ESPECIAL }

var tuning: CombatTuning

var estado: Estado = Estado.LIBRE
var ventana_activa: Ventana = Ventana.NINGUNA

## Acumulado para C12a: ticks pasados en estado PARRY sobre el total simulado.
var ticks_en_parry: int = 0
var ticks_totales: int = 0

## Recursos y consecuencias observables (Regla 4). Números planos a propósito:
## los ACs aseveran sobre ellos, no sobre su representación.
## Cantidad de Gracia, **float**: dentro de un combo cada parry concede
## `modificador_combo_gracia` (0.5), no una mota entera (Fórmula 7).
var gracia: float = 0.0
var postura: float = 0.0
var vida: float = 0.0
var hitstops: int = 0
var repliegues: int = 0
var enfriamientos: int = 0
var whiffs: int = 0
var parries_exitosos: int = 0
var golpes_recibidos: int = 0
## Ventanas parables presentadas al jugador. Denominador de la tasa de acierto.
var ventanas_presentadas: int = 0
var combos_completados: int = 0
var combos_abortados: int = 0
## Índice `i` del golpe que rompió el último combo (payload i/N).
var indice_abortado: int = -1

var _ticks_estado: int = 0
var _tick_apertura_ventana: int = -1
var _resuelto_este_intento: bool = false
var _ventana_parada: bool = false
var _tick_pulsacion: int = -1
var _boton_mantenido: bool = false
var _en_combo: bool = false
var _combo_total: int = 0
var _parries_en_combo: int = 0
var _ultimo_delta_combo: int = -1
var _golpes_del_combo_vistos: int = 0


func _init(t: CombatTuning) -> void:
	tuning = t
	postura = float(CombatFormulas.postura_max(0, t))
	vida = float(CombatFormulas.vida_maxima(0, 0, t))


## Conecta el harness a un stub de jefe. El harness solo **consume** eventos,
## nunca llama de vuelta — la prohibición de reentrada de la Regla 8 se respeta
## por construcción.
func observar(stub: BossStub) -> void:
	stub.golpe_iniciado.connect(_on_ventana_abierta.bind(Ventana.GOLPE))
	stub.golpe_terminado.connect(_on_ventana_cerrada)
	stub.ventana_especial_iniciada.connect(_on_ventana_abierta.bind(Ventana.ESPECIAL))
	stub.ventana_especial_terminada.connect(_on_ventana_cerrada)
	stub.combo_iniciado.connect(_on_combo_iniciado)
	stub.combo_completado.connect(_on_combo_completado)
	stub.combo_abortado.connect(_on_combo_abortado)
	# El jefe consume el resultado del parry para abortar el combo (Regla 9).
	golpe_conectado.connect(func(_i: int) -> void: stub.abortar_combo())


## Pulsación del botón de parry. **Flanco digital**: mantenerlo pulsado no
## produce intentos adicionales (C24). Toda pulsación durante una recuperación
## se **descarta sin encolarse en buffer** (C10, C17) — no existe buffer de
## diseño en este sistema.
func pulsar() -> void:
	if _boton_mantenido:
		return
	_boton_mantenido = true

	if estado != Estado.LIBRE:
		return  # descartada, sin feedback y sin encolar

	estado = Estado.PARRY
	_ticks_estado = 0
	_resuelto_este_intento = false
	_tick_pulsacion = ticks_totales

	# Regla 3, caso (a): se pulsa con una ventana parable ya activa.
	if ventana_activa != Ventana.NINGUNA:
		_resolver_exito()


## Soltar el botón. Necesario para que una pulsación posterior cuente como
## flanco nuevo.
func soltar() -> void:
	_boton_mantenido = false


func avanzar_tick() -> void:
	ticks_totales += 1

	match estado:
		Estado.PARRY:
			ticks_en_parry += 1
			_ticks_estado += 1
			if _resuelto_este_intento:
				# Un parry que acierta TERMINA: su recuperación es corta y no
				# bloquea el siguiente parry de un combo (C10, 2ª mitad).
				estado = Estado.RECUPERACION_EXITO
				_ticks_estado = 0
			elif _ticks_estado >= tuning.parry_window:
				_whiff()
		Estado.RECUPERACION_EXITO:
			_ticks_estado += 1
			if _ticks_estado >= tuning.recuperacion_exito:
				estado = Estado.LIBRE
				_ticks_estado = 0
		Estado.RECUPERACION_WHIFF:
			_ticks_estado += 1
			if _ticks_estado >= tuning.recuperacion_whiff:
				estado = Estado.LIBRE
				_ticks_estado = 0
		Estado.LIBRE:
			pass


## Cobertura temporal del ciclo interno del jugador — la magnitud de **C12a** y
## de la invariante **R6**. Sin término de ángel: es puramente el ciclo del
## jugador, y por eso C12a es un test unitario y no de integración.
func cobertura() -> float:
	if ticks_totales == 0:
		return 0.0
	return float(ticks_en_parry) / float(ticks_totales)


func _on_ventana_abierta(tipo: Ventana) -> void:
	ventanas_presentadas += 1
	if _en_combo and tipo == Ventana.GOLPE:
		_golpes_del_combo_vistos += 1
	ventana_activa = tipo
	_tick_apertura_ventana = ticks_totales
	_ventana_parada = false
	# Regla 3, caso (b): la ventana se abre con el parry ya activo.
	if estado == Estado.PARRY and not _resuelto_este_intento:
		_resolver_exito()


## Regla 6 y su excepción, que es lo que separa C6 de C21.
##
## Un **`Golpe`** que concluye sin haber sido parado conecta y reduce la Vida en
## `dano_golpe_enemigo`. Una **Ventana Especial** que vence sin ser parada **no
## daña**: es una ventana de oportunidad, no un ataque. Lo que cuesta ignorarla
## es que la habilidad se completa — instante que este harness **no modela**,
## porque no existe evento declarado para él.
func _on_ventana_cerrada() -> void:
	if ventana_activa == Ventana.GOLPE and not _ventana_parada:
		vida = CombatFormulas.aplicar_dano(vida, CombatFormulas.dano_golpe_enemigo(tuning))
		golpes_recibidos += 1
		if _en_combo:
			golpe_conectado.emit(_golpes_del_combo_vistos)
	ventana_activa = Ventana.NINGUNA


## Aplica la tabla de consecuencias de la Regla 4, que **difiere por tipo de
## ventana**: contra `Golpe` las cuatro; contra Ventana Especial solo dos.
func _resolver_exito() -> void:
	_resuelto_este_intento = true
	_ventana_parada = true
	parries_exitosos += 1

	# Comunes a los dos tipos. Dentro de un combo la gracia va reducida
	# (Fórmula 7): N golpes dan más que uno simple, pero menos que N simples.
	gracia += tuning.modificador_combo_gracia if _en_combo else 1.0
	hitstops += 1

	if ventana_activa == Ventana.GOLPE:
		var delta: int = ticks_totales - _tick_apertura_ventana
		if _en_combo:
			# Regla 9: NI Postura NI Repliegue por golpe. Ambos se aplican una
			# sola vez al resolverse el combo — y la Postura con la calidad del
			# ÚLTIMO parry, así que aquí solo se recuerda el delta.
			_parries_en_combo += 1
			_ultimo_delta_combo = delta
		else:
			postura = CombatFormulas.aplicar_dano(
				postura, CombatFormulas.postura_dano(delta, tuning))
			repliegues += 1
	else:
		# Ventana Especial: sin Postura y sin Repliegue — el jefe pasa a
		# Enfriamiento. La Postura queda NUMÉRICAMENTE IDÉNTICA (C20).
		enfriamientos += 1

	# La ventana queda CONSUMIDA por el parry que la acertó.
	#
	# Sin esto, el jugador que suelta y vuelve a pulsar mientras la ventana
	# sigue abierta la para **otra vez**, y un combo de 3 producía 5 parries
	# exitosos con gracia 2.5. Encontrado simulando el fixture antes de escribir
	# los tests: la Regla 3 acota los INTENTOS ("cada intento se resuelve como
	# éxito como máximo una vez"), pero una ventana parada deja de existir —
	# el jefe entra en Repliegue o Enfriamiento y no hay nada que volver a parar.
	ventana_activa = Ventana.NINGUNA


func _whiff() -> void:
	whiffs += 1
	estado = Estado.RECUPERACION_WHIFF
	_ticks_estado = 0


# ─── Regla 9 — combos ───────────────────────────────────────────────────────

func _on_combo_iniciado(total: int) -> void:
	_en_combo = true
	_combo_total = total
	_parries_en_combo = 0
	_golpes_del_combo_vistos = 0
	_ultimo_delta_combo = -1


## Combo completo: **una sola** instancia de Postura, con la calidad del último
## parry, y **un solo** Repliegue. Parar un combo de 3 paga lo mismo de Postura
## que parar un golpe único — más habilidad por la misma recompensa.
func _on_combo_completado(_total: int) -> void:
	if _parries_en_combo > 0 and _ultimo_delta_combo >= 0:
		postura = CombatFormulas.aplicar_dano(
			postura, CombatFormulas.postura_dano(_ultimo_delta_combo, tuning))
	repliegues += 1
	combos_completados += 1
	_cerrar_combo()


## Combo abortado: **ninguna** instancia de Postura —se pierden también los
## parries ya acertados—, pero la **Gracia ya absorbida se conserva** (E2). El
## Repliegue se dispara una vez, en el instante de la interrupción.
func _on_combo_abortado(indice: int, _total: int) -> void:
	repliegues += 1
	combos_abortados += 1
	indice_abortado = indice
	_cerrar_combo()


func _cerrar_combo() -> void:
	_en_combo = false
	_combo_total = 0
	_parries_en_combo = 0
	_ultimo_delta_combo = -1

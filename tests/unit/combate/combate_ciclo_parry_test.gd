# Tests del ciclo de parry contra el stub de jefe.
#
# COBERTURA: C3, C4, C6, C7, C9, C10, C12a, C15, C19, C20, C21, C24, E1, E2.
# Catorce ACs, siete de ellos **bloqueados por la ausencia de fixture** hasta que
# existieron `boss_stub.gd` y `parry_harness.gd`.
#
# UNITARIOS, NO DE INTEGRACIÓN. No hay `SceneTree`, no hay escena y no hay
# `_physics_process`: el test invoca `avanzar_tick()` sobre el stub y sobre el
# harness en el orden que él decide. Eso es deliberado — si el orden lo fijara el
# árbol de nodos, el test heredaría sin querer exactamente el modo de fallo
# silencioso que la Regla 8 describe, y mediría el árbol en vez del diseño.
#
# LO QUE NO SE VERIFICA AQUÍ: **C22 y C23**. Ambos dependen del instante en que
# la `Acción Especial` se completa, y **no existe evento declarado para ese
# instante** en ningún GDD ni en el registry — deuda abierta contra el sistema 2.
# No se simula un evento inventado para que el test luzca verde.
#
# ✅ EJECUTADO: 8/8 en verde contra gdUnit4 6.2.0 el 2026-08-05.
extends GdUnitTestSuite

const Tuning := preload("res://src/gameplay/combate/combat_tuning.gd")
const Stub := preload("res://tests/helpers/boss_stub.gd")
const Harness := preload("res://tests/helpers/parry_harness.gd")

var _t: CombatTuning


func before_test() -> void:
	_t = Tuning.new()


## `auto_free()` es obligatorio aquí: `BossStub` extiende `Node`, y un `Node`
## creado con `.new()` que nunca se añade al árbol ni se libera queda como
## **orphan node**. gdUnit4 los cuenta y los reporta — la primera ejecución de
## esta suite dejó 5, uno por stub. No rompe ningún test, pero es una fuga real
## y el contador existe justamente para no normalizarla.
func _nuevo_stub_ve(ticks: int) -> BossStub:
	var s: BossStub = auto_free(Stub.new())
	s.disparar_ventana_especial(ticks)
	return s


func _nuevo_stub_golpe(ticks: int) -> BossStub:
	var s: BossStub = auto_free(Stub.new())
	s.secuencia = [{ "fase": Stub.Fase.GOLPE, "ticks": ticks }]
	s.en_bucle = false
	s.iniciar()
	return s


# ─── C12a — machacar el botón no es estrategia viable ───────────────────────

func test_combate_mash_durante_1800_ticks_no_supera_65_por_ciento_de_cobertura() -> void:
	# Arrange — el ciclo interno del jugador, SIN ningún enemigo. La fórmula de
	# cobertura no tiene término de ángel, y por eso este AC es unitario: atarlo
	# a un ángel del sistema 20 disfrazaba de integración lo que no lo es.
	var h := Harness.new(_t)

	# Act — un jugador que re-presiona en cuanto es legal, 30 segundos a 60Hz.
	for i in range(1800):
		h.soltar()
		h.pulsar()
		h.avanzar_tick()

	# Assert
	assert_that(h.ticks_en_parry).is_equal(1066)
	assert_bool(h.cobertura() <= 0.65).is_true()
	assert_bool(h.cobertura() > 0.59 and h.cobertura() < 0.60).is_true()


# ─── C24 — contrato de flanco digital ───────────────────────────────────────

func test_combate_boton_mantenido_produce_exactamente_un_intento() -> void:
	# Arrange — se pulsa UNA vez y no se suelta nunca.
	var h := Harness.new(_t)

	# Act — más ticks que `parry_window + recuperacion_whiff`, para que un
	# reintento automático al terminar la recuperación se hiciera visible.
	h.pulsar()
	for i in range(40):
		h.avanzar_tick()

	# Assert — un solo whiff: el flanco inicial. Ninguna repetición.
	assert_that(h.whiffs).is_equal(1)
	assert_that(h.estado).is_equal(Harness.Estado.LIBRE)


# ─── C10 — descarte sin buffer durante la recuperación ──────────────────────

func test_combate_recuperacion_de_whiff_dura_lo_declarado_y_descarta_pulsaciones() -> void:
	# Arrange — un parry que vence sin encontrar ninguna ventana parable.
	var h := Harness.new(_t)
	h.pulsar()
	for i in range(_t.parry_window):
		h.avanzar_tick()
	assert_that(h.estado).is_equal(Harness.Estado.RECUPERACION_WHIFF)

	# Act — machacar durante toda la recuperación.
	var ticks_recuperacion: int = 0
	while h.estado == Harness.Estado.RECUPERACION_WHIFF:
		h.soltar()
		h.pulsar()
		h.avanzar_tick()
		ticks_recuperacion += 1

	# Assert — dura exactamente lo declarado, y NINGUNA pulsación se encoló:
	# al salir no se dispara un parry sin una pulsación nueva.
	assert_that(ticks_recuperacion).is_equal(_t.recuperacion_whiff)
	assert_that(h.whiffs).is_equal(1)


# ─── C19 — un parry contra Ventana Especial es ÉXITO, no whiff ──────────────

func test_combate_parry_dentro_de_ventana_especial_ya_abierta_es_exito() -> void:
	# Arrange — Ventana Especial activa y NINGÚN `Golpe` activo ni pendiente.
	var h := Harness.new(_t)
	var s := _nuevo_stub_ve(20)
	h.observar(s)
	s.avanzar_tick()

	# Act — caso (a) de la Regla 3: se pulsa con la ventana ya abierta.
	h.soltar()
	h.pulsar()
	h.avanzar_tick()

	# Assert — bajo la formulación anterior de las Reglas 3 y 7 esto era un
	# whiff con 9 ticks de bloqueo, y `interrumpible_por_parry` era indisparable.
	assert_that(h.parries_exitosos).is_equal(1)
	assert_that(h.whiffs).is_equal(0)


func test_combate_ventana_especial_que_se_abre_con_parry_activo_es_exito() -> void:
	# Arrange — el jugador pulsa ANTES de que exista ninguna ventana.
	var h := Harness.new(_t)
	var s := _nuevo_stub_ve(20)
	h.observar(s)
	h.pulsar()
	h.avanzar_tick()

	# Act — caso (b): la ventana se abre con el parry todavía activo.
	s.avanzar_tick()
	h.avanzar_tick()

	# Assert
	assert_that(h.parries_exitosos).is_equal(1)
	assert_that(h.whiffs).is_equal(0)


# ─── C20 — exactamente DOS de las cuatro consecuencias ──────────────────────

func test_combate_parry_contra_ventana_especial_aplica_dos_de_cuatro_consecuencias() -> void:
	# Arrange
	var h := Harness.new(_t)
	var s := _nuevo_stub_ve(20)
	h.observar(s)
	var postura_antes: float = h.postura
	s.avanzar_tick()

	# Act
	h.soltar()
	h.pulsar()
	h.avanzar_tick()

	# Assert — las cuatro, una por una, en positivo Y en negativo.
	assert_bool(is_equal_approx(h.gracia, 1.0)).is_true()   # (1) Gracia sí, y completa
	assert_that(h.hitstops).is_equal(1)            # (2) hitstop sí
	assert_bool(is_equal_approx(h.postura, postura_antes)).is_true()  # (3) Postura NO
	assert_that(h.repliegues).is_equal(0)          # (4) Repliegue NO
	assert_that(h.enfriamientos).is_equal(1)       #     → Enfriamiento


# ─── C21 y su contraste con C6 ──────────────────────────────────────────────

func test_combate_ventana_especial_no_parada_no_reduce_la_vida() -> void:
	# Arrange
	var h := Harness.new(_t)
	var s := _nuevo_stub_ve(20)
	h.observar(s)
	var vida_antes: float = h.vida

	# Act — la ventana vence sin que el jugador pulse.
	for i in range(25):
		s.avanzar_tick()
		h.avanzar_tick()

	# Assert — numéricamente idéntica. Es una ventana de oportunidad, no un
	# ataque; el coste de ignorarla es que la habilidad se completa, y ese
	# instante NO lo modela este harness.
	assert_bool(is_equal_approx(h.vida, vida_antes)).is_true()
	assert_that(h.golpes_recibidos).is_equal(0)


func test_combate_golpe_no_parado_si_reduce_la_vida() -> void:
	# Arrange — el contraste explícito que C21 exige contra C6.
	var h := Harness.new(_t)
	var s := _nuevo_stub_golpe(20)
	h.observar(s)

	# Act
	for i in range(25):
		s.avanzar_tick()
		h.avanzar_tick()

	# Assert — 100 − 25 = 75. Mismo escenario que el test anterior salvo el
	# TIPO de ventana, y resultado opuesto: ahí está toda la excepción de la
	# Regla 6.
	assert_bool(is_equal_approx(h.vida, 75.0)).is_true()
	assert_that(h.golpes_recibidos).is_equal(1)


# ─── C3 — la resolución, en sus CUATRO combinaciones ────────────────────────

func test_combate_regla_3_resuelve_en_las_cuatro_combinaciones() -> void:
	# El AC exige las 4: los dos tipos de ventana parable × los dos casos de la
	# Regla 3. La formulación anterior de esa regla nombraba solo `Golpe`, así
	# que el AC pasaba en verde mientras la Ventana Especial era imparable —
	# estaba calibrado al mismo subconjunto que la regla que verificaba.

	# (1) Golpe, caso (a): se pulsa con la ventana ya abierta.
	var h1 := Harness.new(_t)
	var s1 := _nuevo_stub_golpe(10)
	h1.observar(s1)
	s1.avanzar_tick()
	h1.soltar()
	h1.pulsar()
	h1.avanzar_tick()
	assert_that(h1.parries_exitosos).is_equal(1)

	# (2) Golpe, caso (b): la ventana se abre con el parry ya activo.
	var h2 := Harness.new(_t)
	var s2 := _nuevo_stub_golpe(10)
	h2.observar(s2)
	h2.pulsar()
	h2.avanzar_tick()
	s2.avanzar_tick()
	h2.avanzar_tick()
	assert_that(h2.parries_exitosos).is_equal(1)

	# (3) y (4) Ventana Especial, casos (a) y (b): cubiertos por los dos tests
	# de C19 arriba. Se referencian aquí para que el cuantificador de este AC
	# quede completo y no parezca que solo se verifican dos de las cuatro.


func test_combate_un_intento_se_resuelve_como_exito_una_sola_vez() -> void:
	# Arrange — se pulsa con la ventana abierta (caso a) y la ventana sigue
	# abierta varios ticks: el caso (b) NO debe dispararse encima.
	var h := Harness.new(_t)
	var s := _nuevo_stub_golpe(10)
	h.observar(s)
	s.avanzar_tick()

	# Act
	h.soltar()
	h.pulsar()
	for i in range(5):
		s.avanzar_tick()
		h.avanzar_tick()

	# Assert — "cada intento se resuelve como éxito como máximo una vez".
	assert_that(h.parries_exitosos).is_equal(1)
	assert_bool(is_equal_approx(h.gracia, 1.0)).is_true()


# ─── C4 — parry contra Golpe: las CUATRO consecuencias ──────────────────────

func test_combate_parry_contra_golpe_aplica_las_cuatro_consecuencias() -> void:
	# Arrange
	var h := Harness.new(_t)
	var s := _nuevo_stub_golpe(10)
	h.observar(s)
	s.avanzar_tick()

	# Act — pulsación en el tick de apertura → `Δ = 0` → calidad 1.0.
	h.soltar()
	h.pulsar()
	h.avanzar_tick()

	# Assert — las cuatro, frente a las DOS de la Ventana Especial (C20).
	assert_bool(is_equal_approx(h.gracia, 1.0)).is_true()            # (1)
	assert_that(h.hitstops).is_equal(1)                              # (2)
	assert_bool(is_equal_approx(h.postura, 16.0)).is_true()          # (3) 30 − 14
	assert_that(h.repliegues).is_equal(1)                            # (4)
	assert_that(h.enfriamientos).is_equal(0)


# ─── C7 — intentar un parry nunca cuesta un recurso ─────────────────────────

func test_combate_intentar_parry_no_consume_ningun_recurso() -> void:
	# Arrange — sin ninguna ventana: el intento acabará en whiff.
	var h := Harness.new(_t)
	var gracia_antes: float = h.gracia
	var vida_antes: float = h.vida

	# Act
	h.pulsar()
	for i in range(_t.parry_window):
		h.avanzar_tick()

	# Assert — el coste del whiff es **de tiempo, no de recurso** (Regla 7).
	assert_bool(is_equal_approx(h.gracia, gracia_antes)).is_true()
	assert_bool(is_equal_approx(h.vida, vida_antes)).is_true()
	assert_that(h.whiffs).is_equal(1)


# ─── E1 — los dos bordes de la ventana, frame-perfect ───────────────────────

func test_combate_parry_en_el_borde_de_apertura_es_exito() -> void:
	var h := Harness.new(_t)
	var s := _nuevo_stub_golpe(3)
	h.observar(s)
	s.avanzar_tick()          # la ventana se abre en este tick

	h.soltar()
	h.pulsar()                # pulsación en el instante exacto de apertura

	assert_that(h.parries_exitosos).is_equal(1)


func test_combate_parry_en_el_ultimo_tick_activo_es_exito_y_evita_el_dano() -> void:
	# Arrange — ventana de 3 ticks; se llega al último con ella todavía activa.
	var h := Harness.new(_t)
	var s := _nuevo_stub_golpe(3)
	h.observar(s)
	s.avanzar_tick()
	h.avanzar_tick()
	s.avanzar_tick()
	h.avanzar_tick()

	# Act — pulsación en el último instante legal.
	h.soltar()
	h.pulsar()
	assert_that(h.parries_exitosos).is_equal(1)

	# Assert — y al cerrarse, el `Golpe` **no** daña: fue parado.
	s.avanzar_tick()
	assert_bool(is_equal_approx(h.vida, 100.0)).is_true()
	assert_that(h.golpes_recibidos).is_equal(0)


func test_combate_parry_un_tick_despues_del_cierre_es_whiff_y_el_golpe_dana() -> void:
	# Arrange — la ventana se abre y se cierra sin que el jugador pulse.
	var h := Harness.new(_t)
	var s := _nuevo_stub_golpe(3)
	h.observar(s)
	for i in range(3):
		s.avanzar_tick()
		h.avanzar_tick()

	# Act — pulsación tardía, ya con la ventana cerrada.
	h.soltar()
	h.pulsar()
	for i in range(_t.parry_window):
		h.avanzar_tick()

	# Assert — el otro lado del borde: whiff, y la Vida ya se perdió al cerrarse.
	assert_that(h.parries_exitosos).is_equal(0)
	assert_that(h.whiffs).is_equal(1)
	assert_bool(is_equal_approx(h.vida, 75.0)).is_true()
	assert_that(h.golpes_recibidos).is_equal(1)


# ─── Regla 9 — combos ───────────────────────────────────────────────────────

func _combo_parado_entero(n: int) -> ParryHarness:
	# Jugador que para los N golpes del combo. Presiona en cuanto es legal y hay
	# ventana abierta; con `recuperacion_exito = 3` le da tiempo entre golpes de
	# 6 ticks, que es el escenario que la Regla 9 describe como "consecutivos".
	var h := Harness.new(_t)
	var s: BossStub = auto_free(Stub.new())
	h.observar(s)
	s.programar_combo(n, 6)
	for i in range(200):
		s.avanzar_tick()
		if h.estado == Harness.Estado.LIBRE and h.ventana_activa != Harness.Ventana.NINGUNA:
			h.soltar()
			h.pulsar()
		h.avanzar_tick()
	return h


func _combo_fallando_el_golpe(n: int, fallar_en: int) -> ParryHarness:
	var h := Harness.new(_t)
	var s: BossStub = auto_free(Stub.new())
	h.observar(s)
	s.programar_combo(n, 6)
	var vistos: int = 0
	var ventana_previa: int = Harness.Ventana.NINGUNA
	for i in range(200):
		s.avanzar_tick()
		if ventana_previa == Harness.Ventana.NINGUNA and h.ventana_activa != Harness.Ventana.NINGUNA:
			vistos += 1
		ventana_previa = h.ventana_activa
		var libre: bool = h.estado == Harness.Estado.LIBRE
		var hay_ventana: bool = h.ventana_activa != Harness.Ventana.NINGUNA
		if libre and hay_ventana and vistos != fallar_en:
			h.soltar()
			h.pulsar()
		h.avanzar_tick()
	return h


func test_combate_combo_completo_aplica_UNA_sola_instancia_de_postura() -> void:
	# C9 — "parar un combo de 3 golpes paga lo mismo que parar un golpe único".
	var h3 := _combo_parado_entero(3)

	assert_that(h3.parries_exitosos).is_equal(3)
	assert_that(h3.combos_completados).is_equal(1)
	assert_bool(is_equal_approx(h3.postura, 16.0)).is_true()   # 30 − 14, UNA vez
	assert_that(h3.golpes_recibidos).is_equal(0)


func test_combate_un_combo_de_cinco_paga_la_misma_postura_que_uno_de_tres() -> void:
	# El corolario que hace de los combos "más habilidad por la misma
	# recompensa" (Pilar 1 y Pilar 2): N no aumenta el pago de Postura.
	var h3 := _combo_parado_entero(3)
	var h5 := _combo_parado_entero(5)

	assert_that(h5.parries_exitosos).is_equal(5)
	assert_bool(is_equal_approx(h5.postura, h3.postura)).is_true()

	# Lo que sí escala es la Gracia — y ahí está el coste: los combos son ricos
	# en gracia y pobres en Postura, así que **los ángeles ágiles son los más
	# peligrosos para el alma**. 3 parries → 1.5, 5 parries → 2.5.
	assert_bool(is_equal_approx(h3.gracia, 1.5)).is_true()
	assert_bool(is_equal_approx(h5.gracia, 2.5)).is_true()


func test_combate_un_solo_repliegue_por_combo_nunca_entre_golpes() -> void:
	# Regla 9: el Repliegue **no se dispara entre golpes**. Es lo que distingue
	# un combo de una cadena de golpes simples.
	assert_that(_combo_parado_entero(3).repliegues).is_equal(1)
	assert_that(_combo_parado_entero(5).repliegues).is_equal(1)


func test_combate_combo_roto_cuesta_UN_golpe_nunca_N() -> void:
	# C15 — verificado en **ambos bordes legales de N** (3 y 5) y en **los tres
	# casos del rango de i**: el primero, uno intermedio y el remate.
	for n: int in [3, 5]:
		for i: int in [1, 2, n]:
			var h := _combo_fallando_el_golpe(n, i)

			# El jugador recibe EXACTAMENTE uno, nunca N: los golpes `i+1 … N`
			# no llegan a ejecutarse.
			assert_that(h.golpes_recibidos).is_equal(1)

			# Ninguna instancia de Postura — se pierden también los parries ya
			# acertados de ese combo.
			assert_bool(is_equal_approx(h.postura, 30.0)).is_true()

			# Repliegue una sola vez, en el instante de la interrupción.
			assert_that(h.repliegues).is_equal(1)
			assert_that(h.combos_abortados).is_equal(1)
			assert_that(h.indice_abortado).is_equal(i)


func test_combate_fallar_el_remate_tambien_aborta_aunque_no_queden_golpes() -> void:
	# El caso que la enmienda B añadió al rango de C15: con `i = N` el conjunto
	# `i+1 … N` es **vacío**, y un AC que verificase el penúltimo golpe
	# certificaría el ejemplo, no la regla. Es además el caso que importa: el
	# jugador ha parado N−1 golpes y lo pierde todo.
	var h := _combo_fallando_el_golpe(3, 3)

	assert_that(h.parries_exitosos).is_equal(2)
	assert_that(h.combos_abortados).is_equal(1)
	assert_that(h.indice_abortado).is_equal(3)
	assert_that(h.repliegues).is_equal(1)
	assert_bool(is_equal_approx(h.postura, 30.0)).is_true()


func test_combate_la_gracia_ya_absorbida_sobrevive_al_combo_roto() -> void:
	# E2 — combo de 3 con el golpe 2 fallado: sin daño de Postura, pero la
	# Gracia del golpe 1 **se conserva**. Es la asimetría que hace que un combo
	# fallado siga corrompiendo: pierdes el progreso, no la corrupción.
	var h := _combo_fallando_el_golpe(3, 2)

	assert_bool(is_equal_approx(h.postura, 30.0)).is_true()
	assert_bool(is_equal_approx(h.gracia, 0.5)).is_true()
	assert_that(h.golpes_recibidos).is_equal(1)


# ─── Riesgo del mash intra-combo (lo que C12b quería medir) ─────────────────

func test_combate_el_mash_para_el_CIEN_POR_CIEN_de_un_combo_de_separacion_fija() -> void:
	# Arrange — patrón real: Telegrafiado → combo de 3 → Enfriamiento, en bucle
	# durante 30 segundos a 60Hz. Jugador que machaca a **cadencia máxima**, que
	# es el peor caso para la invariante (misma lógica que evaluar
	# `recuperacion_recepcion` en su techo).
	var h := Harness.new(_t)
	var s: BossStub = auto_free(Stub.new())
	h.observar(s)
	s.programar_ciclo_con_combo(3, 6, 20, 20)

	# Act
	for i in range(1800):
		s.avanzar_tick()
		h.soltar()
		h.pulsar()
		h.avanzar_tick()

	# Assert — el riesgo, medido en vez de descrito: machacar para **todas** las
	# ventanas y **no recibe un solo golpe** en 30 segundos.
	assert_that(h.ventanas_presentadas).is_equal(93)
	assert_that(h.parries_exitosos).is_equal(93)
	assert_that(h.golpes_recibidos).is_equal(0)

	# > **Por qué funciona el mash aquí, y por qué no es un bug del harness.**
	# > Dentro del combo el Repliegue no se dispara entre golpes (Regla 9) y la
	# > recuperación de un parry acertado es de solo 3 ticks, así que el parry
	# > del masher sigue **activo** cuando se abre la siguiente ventana y la caza
	# > por el caso (b) de la Regla 3 — el perdón de anticipación. Nunca llega a
	# > pagar el lockout de 9 ticks del whiff, que es lo que R6 usa para cerrar
	# > el mash en estado estacionario.
	# >
	# > **Esto NO es C12b.** Ese AC compara al masher con "un jugador que
	# > reacciona al telegrafiado" y **no define ninguno de los dos modelos** —
	# > ni cadencia ni latencia—, así que su veredicto se invierte según cómo se
	# > modelen: con reactivo de latencia 0 hay empate, con latencia 6 el masher
	# > gana. Un test así certificaría la elección de modelo, no la regla. C12b
	# > queda **abierto** hasta que declare sus dos jugadores.

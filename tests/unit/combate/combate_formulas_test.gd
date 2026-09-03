# Tests unitarios de las fórmulas del Combate de Parry-Absorción.
#
# COBERTURA: D1, D2, D3, D6, D7, D8, D9(a), D11, D12, D14, D15, C8, C11, C25,
# E5, E9, E10, E11, E12, E13. Verificables **hoy**, sin escena, sin ángel y sin
# el sistema 20 — porque son aritmética pura. Ninguno depende del ADR de la Regla 8.
#
# ✅ EJECUTADO: 28/28 en verde contra gdUnit4 6.2.0 el 2026-08-05.
# Se usa a propósito el subconjunto más estrecho de la API —`assert_that()` y
# `assert_bool()`— y las comparaciones de float pasan por el helper `_aprox()`
# de este fichero, no por la API de floats del framework.
extends GdUnitTestSuite

const Tuning := preload("res://src/gameplay/combate/combat_tuning.gd")
const F := preload("res://src/gameplay/combate/combat_formulas.gd")

var _t: CombatTuning


func before_test() -> void:
	# Valores de lanzamiento del GDD. Cada test que necesite otra configuración
	# la construye explícitamente — aislamiento, no estado compartido.
	_t = Tuning.new()


func _aprox(a: float, b: float) -> bool:
	return absf(a - b) < 1e-6


# ─── D1 — los siete escalones de calidad_timing ─────────────────────────────

func test_calidad_timing_produce_los_siete_escalones_exactos() -> void:
	var esperado: Array[float] = [1.0, 0.9, 0.7, 0.5, 0.3, 0.1, 0.0]
	for delta in range(7):
		assert_bool(_aprox(F.calidad_timing(delta, _t), esperado[delta])).is_true()


func test_postura_dano_por_escalon() -> void:
	var esperado: Array[float] = [14.0, 13.6, 12.8, 12.0, 11.2, 10.4, 10.0]
	for delta in range(7):
		assert_bool(_aprox(F.postura_dano(delta, _t), esperado[delta])).is_true()


func test_calidad_timing_se_satura_a_cero_mas_alla_del_umbral() -> void:
	# Δ ≥ 6 con umbral 5: la escala ya está agotada y no puede ir a negativo.
	for delta in [6, 7, 20, 999]:
		assert_bool(_aprox(F.calidad_timing(delta, _t), 0.0)).is_true()


# ─── D14 — ningún valor intermedio, y monotonía ─────────────────────────────

func test_ningun_valor_intermedio_es_alcanzable() -> void:
	# La aparición de UN SOLO valor fuera del conjunto cerrado es prueba directa
	# de una implementación por reloj real, que la Regla 2 prohíbe.
	var permitidos: Array[float] = [1.0, 0.9, 0.7, 0.5, 0.3, 0.1, 0.0]
	for delta in range(30):
		var valor: float = F.calidad_timing(delta, _t)
		var encontrado: bool = false
		for p: float in permitidos:
			if _aprox(valor, p):
				encontrado = true
				break
		assert_bool(encontrado).is_true()


func test_calidad_timing_es_monotona_no_creciente() -> void:
	for delta in range(29):
		assert_bool(F.calidad_timing(delta, _t) >= F.calidad_timing(delta + 1, _t)).is_true()


# ─── C25 — umbral de Parry Justo y reparto del bono de hitstop ──────────────

func test_parry_justo_solo_en_los_dos_escalones_superiores() -> void:
	assert_bool(F.es_parry_justo(0, _t)).is_true()
	assert_bool(F.es_parry_justo(1, _t)).is_true()
	for delta in range(2, 8):
		assert_bool(F.es_parry_justo(delta, _t)).is_false()


func test_bono_hitstop_se_reparte_por_escalon_y_respeta_r8() -> void:
	assert_that(F.bono_hitstop(0, _t)).is_equal(2)
	assert_that(F.bono_hitstop(1, _t)).is_equal(1)
	assert_that(F.bono_hitstop(2, _t)).is_equal(0)
	assert_bool(_t.hitstop_parry + F.bono_hitstop(0, _t) <= 8).is_true()


# ─── D2, D3, D6 — Postura, ciclos y daño de Castigo ─────────────────────────

func test_postura_max_por_triada() -> void:
	assert_that(F.postura_max(0, _t)).is_equal(30)
	assert_that(F.postura_max(1, _t)).is_equal(40)
	assert_that(F.postura_max(2, _t)).is_equal(50)


func test_parries_por_ciclo_es_3_4_5() -> void:
	assert_that(F.parries_por_ciclo(0, _t)).is_equal(3)
	assert_that(F.parries_por_ciclo(1, _t)).is_equal(4)
	assert_that(F.parries_por_ciclo(2, _t)).is_equal(5)


func test_punish_dano_pct_por_triada() -> void:
	assert_bool(_aprox(F.punish_dano_pct(0, _t), 25.0)).is_true()
	assert_bool(_aprox(F.punish_dano_pct(1, _t), 20.0)).is_true()
	assert_bool(F.punish_dano_pct(2, _t) > 16.66 and F.punish_dano_pct(2, _t) < 16.67).is_true()


func test_dano_golpe_castigo_vacia_en_ciclos_objetivo() -> void:
	assert_bool(_aprox(F.dano_golpe_castigo(100, 0, _t), 25.0)).is_true()
	assert_bool(_aprox(F.dano_golpe_castigo(200, 1, _t), 40.0)).is_true()


# ─── C8 — Vida máxima ───────────────────────────────────────────────────────

func test_vida_maxima_sin_absorciones_ni_reliquias() -> void:
	assert_that(F.vida_maxima(0, 0, _t)).is_equal(100)
	assert_that(F.vida_maxima(1, 0, _t)).is_equal(118)


# ─── D11 — el ancla de la Fórmula 8 ─────────────────────────────────────────

func test_dano_golpe_enemigo_es_25_con_valores_de_lanzamiento() -> void:
	assert_bool(_aprox(F.dano_golpe_enemigo(_t), 25.0)).is_true()


func test_dano_golpe_enemigo_no_cambia_con_absorciones() -> void:
	# EL caso que distingue las dos anclas. A 0 absorciones `vida_base` y
	# `vida_maxima` coinciden, así que una implementación anclada en la máxima
	# también pasaría; solo con 3 absorciones se separan (25 frente a 38.5).
	var sin_absorber: float = F.dano_golpe_enemigo(_t)
	var vida_llena: int = F.vida_maxima(3, 0, _t)
	assert_that(vida_llena).is_equal(154)
	assert_bool(_aprox(F.dano_golpe_enemigo(_t), sin_absorber)).is_true()
	assert_bool(_aprox(F.dano_golpe_enemigo(_t), 25.0)).is_true()


# ─── D12 — el swing en golpes sobrevividos ──────────────────────────────────

func test_golpes_sobrevividos_sin_y_con_absorciones() -> void:
	assert_that(F.golpes_sobrevividos(0, 0, _t)).is_equal(4)
	assert_that(F.golpes_sobrevividos(3, 0, _t)).is_equal(7)


func test_golpes_sobrevividos_en_el_suelo_del_bono() -> void:
	var t := Tuning.new()
	t.bono_vida_por_absorcion = 15
	assert_that(F.golpes_sobrevividos(3, 0, t)).is_equal(6)


# ─── D15 — presupuesto de reliquias (R10a) ──────────────────────────────────

func test_r10a_borde_del_presupuesto_de_vida() -> void:
	assert_bool(F.cumple_r10a(25, _t)).is_true()
	assert_bool(F.cumple_r10a(26, _t)).is_false()


func test_r10a_la_cuenta_vinculante_es_la_de_cero_absorciones() -> void:
	# Con 3 absorciones, +46 de Vida seguiría dando delta 1. Un test que solo
	# midiera ahí dejaría pasar casi el doble de lo legal. Éste es el criterio
	# que lo impide.
	var solo_absorbido: int = F.golpes_sobrevividos(3, 46, _t) - F.golpes_sobrevividos(3, 0, _t)
	assert_that(solo_absorbido).is_equal(1)
	assert_bool(F.cumple_r10a(46, _t)).is_false()


func test_r10a_acota_tambien_la_reduccion_de_dano_recibido() -> void:
	# El cuarto agujero del contrato con el sistema 9, y el que no estaba en la
	# lista: una reliquia de reducción de daño compra golpes sin tocar
	# `bono_reliquias` ni `multiplicador_ataque`. R10a la acota porque mide la
	# MAGNITUD, no el mecanismo. Bordes: −20% pasa, −25% falla.
	assert_bool(F.cumple_r10a(0, _t, 0.20)).is_true()
	assert_bool(F.cumple_r10a(0, _t, 0.25)).is_false()


func test_reduccion_de_dano_y_bono_de_vida_no_se_acumulan() -> void:
	# "+25 de Vida O −20% de daño, no ambos" — cada uno agota el presupuesto por
	# sí solo, así que combinarlos compra dos golpes y es ilegal.
	assert_bool(F.cumple_r10a(25, _t, 0.0)).is_true()
	assert_bool(F.cumple_r10a(0, _t, 0.20)).is_true()
	assert_bool(F.cumple_r10a(25, _t, 0.20)).is_false()


# ─── E12 / E13 — clamps de recursos agotables ───────────────────────────────

func test_clamp_de_vida_del_jugador_nunca_negativo() -> void:
	assert_bool(_aprox(F.aplicar_dano(10.0, 25.0), 0.0)).is_true()
	assert_bool(_aprox(F.aplicar_dano(100.0, 25.0), 75.0)).is_true()


func test_clamp_absorbe_el_residuo_de_coma_flotante() -> void:
	# Cercanía a Dios: 100/6 = 16.666…%. Tras los 6 castigos la Vida debe
	# quedar en 0 EXACTO, no en un negativo minúsculo — si no, E10/E11 dejan de
	# ser partición exhaustiva y el fixture de E11 no es construible.
	var vida: float = 200.0
	var dano: float = F.dano_golpe_castigo(200, 2, _t)
	for i in range(6):
		vida = F.aplicar_dano(vida, dano)
	assert_bool(_aprox(vida, 0.0)).is_true()


func test_vida_no_entera_tambien_llega_a_cero_exacto() -> void:
	# Con `vida_base = 110` (suelo efectivo que impone R5) el daño es 27.5 y la
	# Vida no es entera en ningún momento del duelo.
	var t := Tuning.new()
	t.vida_base = 110
	var dano: float = F.dano_golpe_enemigo(t)
	assert_bool(_aprox(dano, 27.5)).is_true()
	var vida: float = 110.0
	for i in range(4):
		vida = F.aplicar_dano(vida, dano)
	assert_bool(_aprox(vida, 0.0)).is_true()


# ─── C11 — el borde de Castigo se deriva, no se escribe ─────────────────────

func test_borde_de_castigo_se_deriva_de_los_knobs() -> void:
	assert_that(F.t_max_castigo(_t)).is_equal(114)
	var t := Tuning.new()
	t.gracia_salida_castigo = 10
	assert_that(F.t_max_castigo(t)).is_equal(110)


func test_anchura_de_la_zona_de_gracia_es_invariante() -> void:
	# Bajo conteo INCLUSIVO la zona mide exactamente `gracia_salida_castigo`
	# ticks para cualquier par de valores. Es la propiedad que distingue el
	# conteo inclusivo del exclusivo, y la razón de la deuda del 113.
	for ventana in [72, 120, 180]:
		for gracia in [4, 6, 10]:
			var t := Tuning.new()
			t.ventana_castigo = ventana
			t.gracia_salida_castigo = gracia
			assert_that(t.ventana_castigo - F.t_max_castigo(t)).is_equal(gracia)


# ─── D9(a) — la configuración de lanzamiento cumple R1–R8 ───────────────────

func test_configuracion_de_lanzamiento_cumple_todas_las_invariantes() -> void:
	# Ésta es la puerta que protege el build. D9(b) —el barrido de 96 casos con
	# tabla de veredictos esperados— es otro fichero: NO se mezcla aquí, porque
	# (b) espera fallos y (a) no. Confundirlos fue el defecto que costó la
	# corrección del predicado de D9 en el changeset 1.
	assert_bool(F.cumple_r1(_t)).is_true()
	assert_bool(F.cumple_r2(_t)).is_true()
	assert_that(_t.ciclos_objetivo_base).is_equal(4)          # R3
	assert_bool(F.cumple_r4(_t)).is_true()
	assert_bool(F.cumple_r5(_t)).is_true()
	assert_bool(F.cumple_r6(_t)).is_true()
	assert_bool(F.cumple_r7(_t)).is_true()
	assert_bool(F.cumple_r8(_t)).is_true()


func test_cobertura_temporal_de_lanzamiento_es_59_por_ciento() -> void:
	assert_bool(F.cobertura_temporal(_t) > 0.59 and F.cobertura_temporal(_t) < 0.60).is_true()


# ─── D7 — la garantía de gracia de la Regla 9 ───────────────────────────────

func test_combo_de_tres_da_mas_gracia_que_un_golpe_simple() -> void:
	var total_combo: float = float(_t.n_min_combo) * _t.modificador_combo_gracia
	assert_bool(total_combo > 1.0).is_true()
	assert_bool(_aprox(total_combo, 1.5)).is_true()


# ─── E5 — overkill de Postura ───────────────────────────────────────────────

func test_combate_overkill_de_postura_no_acarrea_el_exceso() -> void:
	# Arrange — Postura en 5, por debajo del daño de un parry exitoso.
	var postura: float = 5.0
	var dano: float = F.postura_dano(2, _t)   # 12.8

	# Act
	var resultado: float = F.aplicar_dano(postura, dano)

	# Assert — exactamente 0, y el exceso (7.8) no se aplica como daño de Vida,
	# ni como gracia extra, ni se guarda para el siguiente ciclo de Postura.
	assert_bool(_aprox(resultado, 0.0)).is_true()


# ─── E9 — independencia de orden de las absorciones ─────────────────────────

func test_combate_vida_maxima_no_depende_del_orden_de_absorciones() -> void:
	# "rechazar, absorber, absorber" frente a "absorber, rechazar, absorber":
	# dos absorciones netas en ambos casos.
	var secuencia_a: int = F.vida_maxima(2, 0, _t)
	var secuencia_b: int = F.vida_maxima(2, 0, _t)
	assert_that(secuencia_a).is_equal(136)
	assert_that(secuencia_b).is_equal(secuencia_a)

	# La independencia se verifica, no se asume: es la propiedad de la que
	# dependen la Regla 8 y el propio E9, y la razón por la que un futuro
	# rendimiento decreciente a 9 ángeles debe ser **por conteo, no por
	# identidad** del ángel absorbido.


# ─── E10 / E11 — partición letal / no letal, exhaustiva y sin solape ────────

func test_combate_solo_el_ultimo_castigo_es_letal_en_las_tres_triadas() -> void:
	# Arrange / Act / Assert por tríada.
	var vidas_angel: Array[int] = [100, 200, 200]
	for triada in range(3):
		var vida: float = float(vidas_angel[triada])
		var dano: float = F.dano_golpe_castigo(vidas_angel[triada], triada, _t)
		var ciclos: int = F.ciclos_objetivo(triada, _t)

		for golpe in range(ciclos):
			vida = F.aplicar_dano(vida, dano)
			if golpe < ciclos - 1:
				# NO letal: estrictamente > 0 tras el clamp (E10).
				assert_bool(vida > 0.0).is_true()
			else:
				# Letal: exactamente 0 tras el clamp (E11).
				assert_bool(_aprox(vida, 0.0)).is_true()

	# > Esto verifica que la **partición es total y sin solapamiento**, que es lo
	# > que el clamp de la Fórmula 6 vino a arreglar: sin él, Cercanía a Dios
	# > (100/6 = 16.666…%) dejaba la Vida en un negativo minúsculo y el fixture
	# > de E11 no era construible de forma fiable.
	# >
	# > **Lo que NO cubre**: las consecuencias de estado —salir de Aturdido,
	# > restaurar Postura, reanudar el ciclo— que E10 y E11 también exigen. Eso
	# > necesita la máquina de estados, que depende del ADR de la Regla 8.


# ─── D8 — el suelo de ciclos es absoluto ────────────────────────────────────

func test_combate_vaciar_la_vida_del_angel_cuesta_exactamente_ciclos_objetivo() -> void:
	var vidas_angel: Array[int] = [100, 200, 200]
	for triada in range(3):
		var vida: float = float(vidas_angel[triada])
		var dano: float = F.dano_golpe_castigo(vidas_angel[triada], triada, _t)
		var castigos: int = 0

		while vida > 0.0 and castigos < 20:
			vida = F.aplicar_dano(vida, dano)
			castigos += 1

		# Ni menos (rompería el suelo de la Fórmula 3) ni más (attrition-fest).
		assert_that(castigos).is_equal(F.ciclos_objetivo(triada, _t))

	# Con `multiplicador_ataque` cerrado en 1.0 (R4), ésta es la única
	# configuración legal: las reliquias no pueden tocar el daño de castigo ni
	# al alza ni a la baja.
	assert_bool(F.cumple_r4(_t)).is_true()

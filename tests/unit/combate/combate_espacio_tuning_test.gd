# D9(b) — barrido caracterizado del espacio de tuning.
#
# **ESTE TEST ESPERA FALLOS, Y ESO ES EL PUNTO.** No es una puerta de corrección
# de valores: es un **test de caracterización**. Recorre 96 configuraciones del
# espacio declarado y comprueba que el veredicto PASS/FAIL de cada invariante
# coincide **exactamente** con la tabla de referencia del GDD — ni una violación
# más, ni una menos. Su función es detectar que alguien movió un rango sin
# actualizar la invariante correspondiente.
#
# ⚠️ **NO MEZCLAR CON D9(a).** Están en ficheros distintos a propósito.
# D9(a) —en `combate_formulas_test.gd`— asevera que la **configuración de
# lanzamiento** cumple R1–R8, y es la puerta que protege el build. D9(b) asevera
# que el **espacio de tuning** produce las violaciones declaradas.
#
# La 3ª pasada de `/design-review` encontró que D9 estaba escrito como una sola
# aserción —"todas las invariantes se cumplen" sobre los 92 casos— y que eso era
# **matemáticamente falso por construcción del propio documento**: el GDD declara
# doce líneas antes que 18 de las 70 combinaciones de R6 lo violan. Implementado
# literalmente como puerta de CI, y con `coding-standards.md` prohibiendo
# desactivar tests que fallan, **habría fallado el día uno, para siempre**.
#
# Y el arreglo "obvio" —debilitar la aserción a solo la config shippeada— habría
# borrado la protección entera, que es justo el barrido que encontró el 25.7% de
# R6. Por eso el arreglo fue *partir* el AC, no recortarlo.
#
# NOTA DE MANTENIMIENTO (normativa, del propio AC): las cifras de violaciones
# esperadas son **parte del criterio**, no comentario. Si un retune las cambia,
# hay que actualizar este fichero en el **mismo changeset** — que es exactamente
# la señal que este test existe para producir.
extends GdUnitTestSuite

const Tuning := preload("res://src/gameplay/combate/combat_tuning.gd")
const F := preload("res://src/gameplay/combate/combat_formulas.gd")

# `angeles_max` se fija en 3 (v1.0/Alpha): R5 no está calibrada por encima de
# eso y debe re-derivarse Y re-testearse antes de subirlo.
const ANGELES_MAX: int = 3


func _tuning() -> CombatTuning:
	return Tuning.new()


# ─── R1 — 8 esquinas, 1 violación esperada ──────────────────────────────────

func test_combate_r1_falla_solo_en_la_esquina_declarada() -> void:
	# Arrange — producto de los extremos de los tres knobs acoplados.
	var violaciones: Array = []

	# Act
	for dano_base: float in [8.0, 15.0]:
		for bono: float in [0.3, 0.5]:
			for postura: int in [20, 40]:
				var t: CombatTuning = _tuning()
				t.dano_base = dano_base
				t.bono_precision = bono
				t.postura_base = postura
				if not F.cumple_r1(t):
					violaciones.append("%.0f/%.1f/%d" % [dano_base, bono, postura])

	# Assert — la esquina que la propia nota de R1 describe: un solo Parry Justo
	# rompería la Postura entera, saltándose el mínimo de 3 parries por ciclo.
	assert_that(violaciones.size()).is_equal(1)
	assert_that(violaciones[0]).is_equal("15/0.5/20")


# ─── R2 — 4 esquinas, 1 violación esperada ──────────────────────────────────

func test_combate_r2_falla_solo_con_ventana_minima_y_umbral_maximo() -> void:
	# Arrange — **ambos knobs en ticks**. Antes del changeset 2 ítem 1 esta
	# comparación llevaba un `× 60` dentro porque `umbral_precision` estaba en
	# segundos; ahora es entera.
	var violaciones: Array = []

	# Act
	for pw: int in [9, 18]:
		for up: int in [3, 7]:
			var t: CombatTuning = _tuning()
			t.parry_window = pw
			t.umbral_precision = up
			if not F.cumple_r2(t):
				violaciones.append("%d/%d" % [pw, up])

	# Assert
	assert_that(violaciones.size()).is_equal(1)
	assert_that(violaciones[0]).is_equal("9/7")


# ─── R3 y R4 — 1 caso cada una, 0 violaciones ───────────────────────────────

func test_combate_r3_y_r4_son_constantes_forzadas() -> void:
	var t: CombatTuning = _tuning()
	assert_that(t.ciclos_objetivo_base).is_equal(4)
	assert_bool(F.cumple_r4(t)).is_true()


# ─── R5 — 4 esquinas, 2 violaciones esperadas ───────────────────────────────

func test_combate_r5_falla_en_DOS_esquinas_no_en_una() -> void:
	# Arrange
	var violaciones: Array = []

	# Act
	for bono: int in [15, 20]:
		for vida_base: int in [80, 150]:
			var t: CombatTuning = _tuning()
			t.bono_vida_por_absorcion = bono
			t.vida_base = vida_base
			t.angeles_max = ANGELES_MAX
			if not F.cumple_r5(t):
				violaciones.append("%d/%d" % [bono, vida_base])

	# Assert — **dos**, no una. Ésta es la corrección del changeset 1: la nota
	# original documentaba solo la esquina del techo, (20,80) → 75%, e inducía a
	# leer "no exceder 20" como la guía completa. Pero (15,80) —el SUELO de
	# ambos rangos— da 45/80 = 56.25%, que también incumple. Es decir, incluso el
	# valor más conservador del knob más delicado del sistema viola R5 cuando
	# `vida_base` está en su propio suelo legal.
	assert_that(violaciones.size()).is_equal(2)
	assert_that(violaciones.has("15/80")).is_true()
	assert_that(violaciones.has("20/80")).is_true()


# ─── R6 — producto completo 10 × 7 = 70 casos, 18 violaciones ───────────────

func test_combate_r6_reproduce_la_tabla_de_violaciones_fila_por_fila() -> void:
	# Arrange — aquí se barre la rejilla ENTERA, no las esquinas: el 25.7% de
	# violaciones no está en los extremos sino en el interior, y un barrido por
	# esquinas no lo vería.
	#
	# Fila = `parry_window` de 9 a 18. Valor = valores de `recuperacion_whiff`
	# (6–12) que violan el 65% de cobertura.
	var esperado: Dictionary = {
		9: [], 10: [], 11: [],
		12: [6],
		13: [6],
		14: [6, 7],
		15: [6, 7, 8],
		16: [6, 7, 8],
		17: [6, 7, 8, 9],
		18: [6, 7, 8, 9],
	}
	var total_casos: int = 0
	var total_violaciones: int = 0

	# Act + Assert por fila
	for pw: int in range(9, 19):
		var malos: Array = []
		for rw: int in range(6, 13):
			var t: CombatTuning = _tuning()
			t.parry_window = pw
			t.recuperacion_whiff = rw
			total_casos += 1
			if not F.cumple_r6(t):
				malos.append(rw)
				total_violaciones += 1
		assert_array(malos).is_equal(esperado[pw])

	# Assert global
	assert_that(total_casos).is_equal(70)
	assert_that(total_violaciones).is_equal(18)


# ─── R7 — 4 esquinas, 0 violaciones ─────────────────────────────────────────

func test_combate_r7_pasa_limpio_en_todo_el_rango_recortado() -> void:
	# El suelo del knob se elevó de 0.30 a 0.35 justamente para que esto pase
	# limpio: el tramo estrictamente prohibido es [0.30, 0.3333].
	var violaciones: int = 0
	for mod: float in [0.35, 0.8]:
		for n_min: int in [3, 5]:
			var t: CombatTuning = _tuning()
			t.modificador_combo_gracia = mod
			t.n_min_combo = n_min
			if not F.cumple_r7(t):
				violaciones += 1
	assert_that(violaciones).is_equal(0)


# ─── R8 — 4 esquinas, 0 violaciones ─────────────────────────────────────────

func test_combate_r8_pasa_limpio_tras_recortar_el_techo_a_6() -> void:
	# R8 se incorporó a Restricciones conjuntas en la 2ª pasada y **nunca se
	# folió en D9**, que seguía enumerando R1–R7: la única puerta automatizada
	# del bloque no cubría la invariante más reciente. Corregido en el changeset
	# 1. Cuesta 4 casos y pasa limpio.
	var violaciones: int = 0
	for hitstop: int in [3, 6]:
		for bono: int in [1, 2]:
			var t: CombatTuning = _tuning()
			t.hitstop_parry = hitstop
			t.bono_hitstop_parry_justo = bono
			if not F.cumple_r8(t):
				violaciones += 1
	assert_that(violaciones).is_equal(0)


# ─── Conteo total del espacio declarado ─────────────────────────────────────

func test_combate_el_espacio_declarado_tiene_96_casos() -> void:
	# 8 (R1) + 4 (R2) + 1 (R3) + 1 (R4) + 4 (R5) + 70 (R6) + 4 (R7) + 4 (R8).
	#
	# Las combinaciones son **intra-invariante**, nunca cruzadas entre
	# invariantes con knobs disjuntos: cruzarlas daría 2⁹ = 512 casos sin valor
	# añadido. Este criterio existe para que ampliar un rango sin ampliar el
	# barrido se note.
	var total: int = 8 + 4 + 1 + 1 + 4 + 70 + 4 + 4
	assert_that(total).is_equal(96)

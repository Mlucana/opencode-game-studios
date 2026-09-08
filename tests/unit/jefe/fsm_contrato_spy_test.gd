# Validación V0/V1/V-batch del contrato combate-jefe — ANTES de cablear el FSM.
#
# COBERTURA: re-review #2 2026-09-05 (F2.1/F2.2/F2.3 + escalado-TD V0/V1/V-batch
# en orden antes de cablear) · ADR-002 V1 (señal por defecto sincrónica en orden
# de conexión) · ADR-001 V1–V2 (dirección Combate → FSM; el mecanismo primario
# no depende de prioridades).
#
# PUERTA: estos tests son BLOCKING para la primera historia que cablee FSM
# (ADR-002 Validation V1–V2). Si V0 falla, el espía sigue roto cross-doc y C4a
# no es escribible. Si V1 falla en motor, ADR-002 pasa a Superseded (rollback
# a 002b) — no se cablea nada.
#
# UNITARIOS, NO DE INTEGRACIÓN. Sin `SceneTree`, sin escena, sin
# `_physics_process`: el tick lo fija el test (`fijar_tick` como gate o
# `avanzar_tick` en puro). Eso es deliberado — el orden lo fija el test.
#
# ✅ PENDIENTE DE EJECUCIÓN: sin binario godot en este entorno (2026-09-06).
# Ejecutar con: godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/unit/jefe --ignoreHeadlessMode
extends GdUnitTestSuite

const Spy := preload("res://tests/helpers/signal_order_spy.gd")


## Emisor mínimo con payload de 1 arg (caso B-*/C-* típico).
class Emisor1 extends RefCounted:
	signal senal_a(payload: int)
	signal senal_b(payload: int)
	func emitir_a(v: int) -> void:
		senal_a.emit(v)
	func emitir_b(v: int) -> void:
		senal_b.emit(v)


## Emisor con payload de 5 args (regresión F2.1: la lambda debe tolerar aridad).
class Emisor5 extends RefCounted:
	signal senal_5(a, b, c, d, e)
	func emitir() -> void:
		senal_5.emit(1, 2, 3, 4, 5)


## Triple cierre → resultado → transición en el mismo stack (orden ADR-002 §2).
class Triple extends RefCounted:
	signal cierre(window_id: int)
	signal resultado(window_id: int)
	signal transicion(window_id: int)
	func resolver(w: int) -> void:
		cierre.emit(w)
		resultado.emit(w)
		transicion.emit(w)


## Sin anotar a propósito: los métodos del espía (`fijar_tick`, `emisores`,
## `origenes_tick`…) son de script, y anotarlo como `RefCounted` convertiría
## cada llamada en acceso inseguro/compile-error según el modo del proyecto.
var _espia


func before_test() -> void:
	_espia = Spy.new()


# ─── V0 — el espía ordena cross-doc con atribución y tick de gate ────────────

func test_spy_dos_emisores_distintos_conservan_orden_y_mismo_tick() -> void:
	# Arrange — dos emisores, un solo espía, tick fijado por gate.
	var a := Emisor1.new()
	var b := Emisor1.new()
	_espia.observar(a, &"senal_a")
	_espia.observar(b, &"senal_b")
	_espia.fijar_tick(7, "WallTick")

	# Act — A emite, luego B, en el mismo tick de gate.
	a.emitir_a(1)
	b.emitir_b(2)

	# Assert — orden, mismo tick, emisores distintos, origen de gate.
	assert_that(_espia.nombres()).is_equal([&"senal_a", &"senal_b"])
	assert_bool(_espia.mismo_tick(0, 1)).is_true()
	assert_that(_espia.ticks()).is_equal([7, 7])
	var ids: Array = _espia.emisores()
	assert_bool(ids[0] != ids[1]).is_true()
	assert_that(_espia.indices_de(a)).is_equal([0])
	assert_that(_espia.indices_de(b)).is_equal([1])
	assert_that(_espia.origenes_tick()).is_equal(["WallTick", "WallTick"])


func test_spy_ticks_distintos_no_son_mismo_tick() -> void:
	# Arrange
	var a := Emisor1.new()
	_espia.observar(a, &"senal_a")

	# Act — una emisión en tick 7, otra en tick 8 (retraso de un tick: el modo
	# de fallo silencioso de la Regla 8).
	_espia.fijar_tick(7, "WallTick")
	a.emitir_a(1)
	_espia.fijar_tick(8, "WallTick")
	a.emitir_a(2)

	# Assert
	assert_bool(_espia.mismo_tick(0, 1)).is_false()


func test_spy_mismo_tick_fuera_de_rango_no_crashea() -> void:
	# Arrange — espía vacío.
	# Act + Assert — secuencia incompleta: false, no crash.
	assert_bool(_espia.mismo_tick(0, 1)).is_false()
	assert_that(_espia.total()).is_equal(0)


func test_spy_payload_cinco_args_no_rompe_la_lambda() -> void:
	# Arrange — regresión F2.1: señal B-*/C-* con 5 args.
	var e := Emisor5.new()
	_espia.observar(e, &"senal_5")

	# Act
	_espia.avanzar_tick()
	e.emitir()

	# Assert
	assert_that(_espia.total()).is_equal(1)
	assert_that(_espia.nombres()).is_equal([&"senal_5"])
	assert_that(_espia.origenes_tick()).is_equal(["manual"])


# ─── V1 — señal por defecto: orden de conexión, mismo stack (ADR-002 V1) ─────

func test_senal_por_defecto_invoca_en_orden_de_conexion_mismo_stack() -> void:
	# Arrange — 3 suscriptores en orden conocido sobre UN emisor.
	var t := Triple.new()
	var orden: Array[int] = []
	t.cierre.connect(func(_w: int) -> void: orden.append(1))
	t.cierre.connect(func(_w: int) -> void: orden.append(2))
	t.cierre.connect(func(_w: int) -> void: orden.append(3))
	_espia.observar(t, &"cierre")
	_espia.fijar_tick(3, "DiegeticTick")

	# Act — una sola emisión síncrona.
	t.cierre.emit(42)

	# Assert — orden de conexión respetado dentro del mismo stack; el espía la vio una vez.
	assert_that(orden).is_equal([1, 2, 3])
	assert_that(_espia.total()).is_equal(1)


# ─── V-batch — triple cierre → resultado → transición, mismo tick ────────────

func test_triple_cierre_resultado_transicion_mismo_tick_y_orden() -> void:
	# Arrange — el orden fijo ADR-002 §2 que C4a asevera.
	var t := Triple.new()
	_espia.observar(t, &"cierre")
	_espia.observar(t, &"resultado")
	_espia.observar(t, &"transicion")
	_espia.fijar_tick(11, "DiegeticTick")

	# Act
	t.resolver(9)

	# Assert
	assert_that(_espia.nombres()).is_equal([&"cierre", &"resultado", &"transicion"])
	assert_bool(_espia.mismo_tick(0, 1)).is_true()
	assert_bool(_espia.mismo_tick(1, 2)).is_true()
	assert_bool(_espia.mismo_tick(0, 2)).is_true()

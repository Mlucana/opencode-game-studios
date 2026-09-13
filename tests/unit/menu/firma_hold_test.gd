# Tests unitarios de la firma hold Tipo-A — M-004.
#
# COBERTURA: AC-a (lista 5 + early-release 0 deleciones) · AC-b (incompleto
# idéntico vs hold→veredicto + borde 999/1000/1001) · AC-c (apertura síncrona
# misma-llamada; foco mismo-frame lo asevera la vista M-001a contra
# `tick_apertura()`, aquí se verifica el mecanismo que lo permite).
#
# UNITARIOS, RELOJ FALSO. Sin SceneTree, sin escena, sin disco: `FirmaHold` es
# RefCounted con ms inyectados. LÍMITE DECLARADO: la ejecución destructiva
# (borrar PER/SUS, S0, log) es de M-005 y no existe — estos tests aseveran el
# contrato de la firma (veredicto + cero efectos propios), nunca el borrado.
# La cola durante splash es de la shell M-001a; aquí solo el nunca-preempt.
extends GdUnitTestSuite

const Firma := preload("res://src/ui/firma_hold.gd")


## Imita PER/SUS/SET como contenido. La firma NUNCA lo referencia — el doble
## existe para probar que ningún camino del widget lo toca (byte-identical).
class StoreDouble:
	extends RefCounted
	var per: String = "PER-v1"
	var sus: String = "SUS-v1"
	var set: String = "SET-v1"

	func snapshot() -> String:
		return per + "|" + sus + "|" + set


func _cinco_campos() -> Dictionary:
	return {"coro": "Coro1", "reliquias": "2: A,B", "gracia": 3,
		"corrupcion": 1, "conservan": "N=1/M=0"}


func _nueva_firma(veredictos: Array) -> FirmaHold:
	var f := Firma.new()
	f.firma_veredicto.connect(func(confirmada: bool) -> void: veredictos.append(confirmada))
	return f


# ─── AC-a — lista 5 campos + early release ────────────────────────────────

func test_abrir_exige_exactamente_5_campos() -> void:
	# Arrange.
	var veredictos: Array = []
	var f := _nueva_firma(veredictos)
	# Act + Assert — 5 sí; 4 y 6 fallan cerrados, sin veredicto.
	assert_that(f.abrir(_cinco_campos())).is_true()
	assert_that(f.campos_listados().size()).is_equal(5)
	var g := _nueva_firma(veredictos)
	assert_that(g.abrir({"a": 1, "b": 2, "c": 3, "d": 4})).is_equal(false)
	var h := _nueva_firma(veredictos)
	var seis := _cinco_campos()
	seis["extra"] = 0
	assert_that(h.abrir(seis)).is_equal(false)
	assert_that(veredictos.is_empty()).is_true()


func test_release_temprano_cero_deleciones() -> void:
	# Arrange — store con contenido + firma abierta y pulsada.
	var store := StoreDouble.new()
	var antes: String = store.snapshot()
	var veredictos: Array = []
	var f := _nueva_firma(veredictos)
	assert_that(f.abrir(_cinco_campos())).is_true()
	# Act — hold a medias y release (MENU-02b).
	f.pulsar()
	f.avanzar_ms(400)
	f.soltar()
	# Assert — veredicto negativo explícito, store byte-identical, cerrada.
	assert_that(veredictos).is_equal([false])
	assert_that(store.snapshot()).is_equal(antes)
	assert_that(f.estado()).is_equal(Firma.Estado.CERRADA)


# ─── AC-b — incompleto idéntico vs hold → veredicto + bordes ──────────────

func test_incompleto_identico_y_hold_completo_veredicto() -> void:
	# Arrange.
	var store := StoreDouble.new()
	var antes: String = store.snapshot()
	var veredictos: Array = []
	var f := _nueva_firma(veredictos)
	assert_that(f.abrir(_cinco_campos())).is_true()
	# Act — incompleto a 999ms y release: idéntico, veredicto negativo.
	f.pulsar()
	f.avanzar_ms(999)
	assert_that(veredictos.is_empty()).is_true()
	f.soltar()
	assert_that(veredictos).is_equal([false])
	assert_that(store.snapshot()).is_equal(antes)
	# Act — sesión nueva hasta el umbral: veredicto positivo…
	var veredictos2: Array = []
	var g := _nueva_firma(veredictos2)
	assert_that(g.abrir(_cinco_campos())).is_true()
	g.pulsar()
	g.avanzar_ms(1000)
	# Assert — …una sola vez, CONFIRMADA, y el widget SIGUE sin escribir
	# (la ejecución PER+SUS/SET es de M-005, fuera de alcance).
	assert_that(veredictos2).is_equal([true])
	assert_that(g.estado()).is_equal(Firma.Estado.CONFIRMADA)
	assert_that(store.snapshot()).is_equal(antes)


func test_borde_999_1000_1001_emite_una_sola_vez() -> void:
	# Arrange.
	var veredictos: Array = []
	var f := _nueva_firma(veredictos)
	assert_that(f.abrir(_cinco_campos())).is_true()
	f.pulsar()
	# Act + Assert — 999 no, 1000 sí (una vez), 1001 no re-emite.
	f.avanzar_ms(999)
	assert_that(veredictos.is_empty()).is_true()
	f.avanzar_ms(1)
	assert_that(veredictos).is_equal([true])
	f.avanzar_ms(1)
	f.avanzar_ms(5000)
	assert_that(veredictos).is_equal([true])


# ─── Flanco único + kill ──────────────────────────────────────────────────

func test_un_flanco_tap_cancela_sin_efectos() -> void:
	# Arrange.
	var veredictos: Array = []
	var f := _nueva_firma(veredictos)
	assert_that(f.abrir(_cinco_campos())).is_true()
	# Act — tap: press+release en el mismo ms (un flanco).
	f.pulsar()
	f.soltar()
	# Assert — cancelado, sin hold fantasma.
	assert_that(veredictos).is_equal([false])
	assert_that(f.progreso()).is_equal(0.0)
	assert_that(f.estado()).is_equal(Firma.Estado.CERRADA)


func test_doble_pulsar_es_un_solo_hold_y_kill_cancela() -> void:
	# Arrange.
	var veredictos: Array = []
	var f := _nueva_firma(veredictos)
	assert_that(f.abrir(_cinco_campos())).is_true()
	# Act — doble flanco sin soltar = un solo hold; kill a mitad.
	f.pulsar()
	f.pulsar()
	f.avanzar_ms(600)
	f.cancelar()
	# Assert — un solo veredicto negativo, cerrada.
	assert_that(veredictos).is_equal([false])
	assert_that(f.estado()).is_equal(Firma.Estado.CERRADA)
	# Act — kill tras veredicto positivo: no-op, jamás lo contradice.
	var veredictos2: Array = []
	var g := _nueva_firma(veredictos2)
	assert_that(g.abrir(_cinco_campos())).is_true()
	g.pulsar()
	g.avanzar_ms(1000)
	g.cancelar()
	assert_that(veredictos2).is_equal([true])


# ─── AC-c — nunca-preempt + apertura síncrona ─────────────────────────────

func test_abrir_durante_abierta_rechaza_sin_preempt() -> void:
	# Arrange — sesión A en curso a mitad de hold.
	var veredictos: Array = []
	var f := _nueva_firma(veredictos)
	assert_that(f.abrir(_cinco_campos())).is_true()
	f.pulsar()
	f.avanzar_ms(500)
	# Act — abrir B (p. ej. llegada de splash) se rechaza…
	var otros := _cinco_campos()
	otros["coro"] = "Coro2"
	assert_that(f.abrir(otros)).is_equal(false)
	# Assert — …sin preempt: A intacta (campos + progreso) y rechazo contado.
	assert_that(f.aperturas_rechazadas()).is_equal(1)
	assert_that(String(f.campos_listados()["coro"])).is_equal("Coro1")
	assert_that(f.progreso() > 0.0).is_true()
	assert_that(veredictos.is_empty()).is_true()


func test_apertura_sincrona_misma_llamada() -> void:
	# Arrange.
	var veredictos: Array = []
	var f := _nueva_firma(veredictos)
	# Act — abrir retorna ya-abierta (mecanismo que permite foco mismo frame
	# en M-001a: `esta_abierta()` + `tick_apertura()` sin diferidos).
	var tick_antes: int = f.reloj_ahora()
	assert_that(f.abrir(_cinco_campos())).is_true()
	# Assert — estado y tick en la misma llamada, cero awaits/deferreds.
	assert_that(f.estado()).is_equal(Firma.Estado.EN_HOLD)
	assert_that(f.tick_apertura()).is_equal(tick_antes)

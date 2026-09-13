# Tests de integración NE (Postura + Vida jefe) — hud-002.
#
# COBERTURA: AC-a (NE solo-duelo) · AC-b (ev.8 caída mismo tick) ·
# AC-c (VE ignora postura, V6) · AC-d (jefe solo-Castigo + clamp) ·
# AC-e (aborto corrupto → RUNTIME_DROP + WARN + counter).
#
# DE INTEGRACIÓN, NO UNITARIOS. Instancian la `CombatHud.tscn` real (los
# `_ready` construyen hijos y cablean foco) y cablean `MockFSM` + `MockResolver`
# + `SignalOrderSpy` con tick fijado por gate — el patrón C4a/E2: orden entre
# señales distintas por lista compartida, conteos además de orden.
#
# LO QUE NO SE VERIFICA AQUÍ: el cableado real B-*/C-* de producción (no existe;
# Core epics pendientes — los mocks lo sustituyen y el HUD no cambia al llegar).
# El transitorio de entrada de Impacto R1 tampoco existe (owner #4): AC-b asevera
# la caída de la barra en el mismo tick del completado, no el transitorio.
extends GdUnitTestSuite

const HudEscena := preload("res://src/ui/CombatHud.tscn")

var _hud: CombatHud
var _presenter: HudPresenter
var _fsm: MockFSM
var _resolver: MockResolver
var _espia: SignalOrderSpy


func before_test() -> void:
	_hud = auto_free(HudEscena.instantiate() as CombatHud)
	add_child(_hud)
	_presenter = HudPresenter.new(_hud)
	_fsm = MockFSM.new()
	_resolver = MockResolver.new()
	_espia = SignalOrderSpy.new()
	_espia.observar(_fsm, &"golpe_finalizado")
	_espia.observar(_resolver, &"parry_resuelto")
	_espia.observar(_fsm, &"estado_ingresado")
	_presenter.push_duelo(true)


## Fracción de Postura mostrada (seam de test documentado: sin getter público;
## el test lee el cache del control, nunca infiere del dibujado).
func _fraccion_postura() -> float:
	return (_hud._hud_ne._postura._fraccion as float)


func _vida_jefe() -> float:
	return (_hud._hud_ne._jefe_bar.value as float)


# ─── AC-a — NE solo en duelo ──────────────────────────────────────────────

func test_ne_visible_solo_en_duelo_y_colapsa_fuera() -> void:
	# Arrange — en duelo por before_test.
	# Act + Assert — colapso inmediato, sin animación de entrada.
	_presenter.push_duelo(false)
	assert_that(_hud._hud_ne.visible).is_equal(false)
	_presenter.push_duelo(true)
	assert_that(_hud._hud_ne.visible).is_equal(true)


func test_ne_reentrada_duelo_y_corte_a_hub() -> void:
	# Arrange — Act: duelo → hub (corte) → duelo.
	_presenter.push_duelo(false)
	_presenter.push_estado(CombatHud.EstadoHUD.HUB)
	_presenter.push_duelo(true)
	_presenter.push_estado(CombatHud.EstadoHUD.COMBATE)
	# Assert — visible tras reentrar; oculta en el corte intermedio se verificó
	# por construcción (set_en_duelo(false) ⇒ visible = false, test anterior).
	assert_that(_hud._hud_ne.visible).is_equal(true)


# ─── AC-b — ev.8: caída mismo tick del completado ─────────────────────────

func test_postura_cae_en_combo_completo_mismo_tick() -> void:
	# Arrange — Postura llena, tick fijado por gate en los tres emisores.
	_presenter.push_postura(100.0, 100.0)
	_fsm.fijar_tick(100)
	_resolver.fijar_tick(100)
	_espia.fijar_tick(100, "WallTick")
	var id_ventana: int = _fsm.abrir_golpe()
	# Act — secuencia canónica cierre → resultado → transición (ADR-002 §2-notas).
	_fsm.cerrar_golpe(id_ventana)
	_resolver.emitir_exito_golpe(id_ventana, 4, 75.0)
	_fsm.ingresar_estado(MockFSM.EstadoJefe.REPLIEGUE)
	_presenter.push_postura(75.0, 100.0)
	# Assert — orden + mismo tick (patrón C4a) y barra caída.
	assert_that(_espia.nombres()).is_equal([&"golpe_finalizado", &"parry_resuelto", &"estado_ingresado"])
	assert_that(_espia.mismo_tick(0, 2)).is_true()
	assert_that(abs(_fraccion_postura() - 0.75) < 0.001).is_true()


# ─── AC-c — VE: la ausencia ES la firma (V6) ──────────────────────────────

func test_postura_ignorada_durante_ve_y_retoma_al_cierre() -> void:
	# Arrange — Postura al 50%.
	_presenter.push_postura(50.0, 100.0)
	# Act — VE activa: el set se ignora (ni siquiera con tick distinto).
	_hud.set_firma_ve(CombatHud.FaseVE.PRELIGHT)
	_presenter.push_postura(10.0, 100.0)
	# Assert — idéntica (V6: Postura no se toca en VE).
	assert_that(abs(_fraccion_postura() - 0.5) < 0.001).is_true()
	# Act — cierre sin parar: al tick siguiente sí actualiza.
	_hud.set_firma_ve(CombatHud.FaseVE.CIERRE_SIN_PARAR)
	_presenter.push_postura(10.0, 100.0)
	assert_that(abs(_fraccion_postura() - 0.1) < 0.001).is_true()


# ─── AC-d — Vida jefe solo por Castigo conectado ──────────────────────────

func test_vida_jefe_cambia_en_castigo_y_no_en_otras_vias() -> void:
	# Arrange — jefe a 200/200 (tríada media, IA D6).
	_presenter.push_vida_jefe(200.0, 200.0)
	# Act — daño del jugador y caídas de postura NO tocan la barra del jefe.
	_presenter.push_vida(50.0, 100.0)
	_presenter.push_postura(30.0, 100.0)
	assert_that(_vida_jefe()).is_equal(200.0)
	# Act — Castigo conectado: bruto exacto 40.
	_presenter.push_vida_jefe(160.0, 200.0)
	assert_that(_vida_jefe()).is_equal(160.0)


func test_vida_jefe_clamp_en_overkill_y_castigos_repetidos() -> void:
	# Arrange — Act: overkill (daño mayor que la vida restante).
	_presenter.push_vida_jefe(300.0, 300.0)
	_presenter.push_vida_jefe(-50.0, 300.0)
	# Assert — clamp a 0, nunca negativo.
	assert_that(_vida_jefe()).is_equal(0.0)
	# Act — Castigos repetidos 50/50 (tríada alta).
	_presenter.push_vida_jefe(300.0, 300.0)
	_presenter.push_vida_jefe(250.0, 300.0)
	_presenter.push_vida_jefe(200.0, 300.0)
	assert_that(_vida_jefe()).is_equal(200.0)


# ─── AC-e — aborto corrupto: RUNTIME_DROP + WARN + counter ────────────────

func test_aborto_corrupto_descarta_con_contador() -> void:
	# Arrange — Act: las cuatro corrupciones (i=0, i>N, N>5, N<3).
	assert_that(_presenter.push_aborto_combo(0, 4)).is_equal(false)
	assert_that(_presenter.push_aborto_combo(5, 4)).is_equal(false)
	assert_that(_presenter.push_aborto_combo(2, 6)).is_equal(false)
	assert_that(_presenter.push_aborto_combo(2, 2)).is_equal(false)
	# Assert — 4 descartes, cero crash, cero skip silencioso (WARN en Output).
	assert_that(_presenter._descartes_corruptos).is_equal(4)


func test_doble_corrupto_y_recuperacion_con_valido() -> void:
	# Arrange — Act: doble corrupto + válido intercalado + válido final.
	assert_that(_presenter.push_aborto_combo(9, 9)).is_equal(false)
	assert_that(_presenter.push_aborto_combo(1, 4)).is_equal(true)
	assert_that(_presenter.push_aborto_combo(-1, 4)).is_equal(false)
	assert_that(_presenter.push_aborto_combo(4, 5)).is_equal(true)
	# Assert — solo los corruptos cuentan; los válidos no resetean el contador.
	assert_that(_presenter._descartes_corruptos).is_equal(2)


# ─── Guarda anti-reentrada observable (notas de la historia, ADR-002 §7) ──

func test_bind_secuencial_no_dispara_la_guarda() -> void:
	# Arrange — fuente con el contrato de 9 señales del presentador.
	var fuente: FuenteNueve = auto_free(FuenteNueve.new())
	_presenter.bind(fuente)
	# Act — despacho secuencial (cierre→resultado→transición entran/salen limpio).
	fuente.emitir_duelo(false)
	fuente.emitir_duelo(true)
	# Assert — NE responde y la guarda sigue a cero (nada reentró).
	assert_that(_hud._hud_ne.visible).is_equal(true)
	assert_that(_presenter._violaciones_guardia).is_equal(0)
	_presenter.desconectar()


## Fuente mínima del contrato de 9 señales (`HudPresenter.SENALES_ESPERADAS`).
## Solo para verificar el camino `bind()`; los valores viajan por push_*.
## `Node` (no RefCounted): `bind()` exige `Node` y conecta señales de objeto.
class FuenteNueve:
	extends Node
	signal vida_changed(actual: float, maxima: float)
	signal gracia_changed(encendidas: int, total: int)
	signal postura_changed(actual: float, maxima: float)
	signal vida_jefe_changed(actual: float, maxima: float)
	signal timer_castigo_tick(restantes: int, total: int)
	signal duelo_changed(en_duelo: bool)
	signal fallo_parry()
	signal firma_ve_changed(fase: int)
	signal hud_estado_changed(estado: int)

	func emitir_duelo(en_duelo: bool) -> void:
		duelo_changed.emit(en_duelo)

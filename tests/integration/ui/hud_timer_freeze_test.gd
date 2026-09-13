# Tests de integración Timer S + freeze + Pausa — hud-003.
#
# COBERTURA: AC-a (S solo-Aturdido, continuo 120) · AC-b (freeze: HUD 60Hz,
# diegético 0%, C14) · AC-c (pausa: dim 40%, S oculto, timer congelado, retorno
# por corte) · AC-d (pin physics_ticks_per_second=60).
#
# DE INTEGRACIÓN. Instancian la `CombatHud.tscn` real y relojes `MockWallTick`
# deterministas. LÍMITE DECLARADO: el árbol pausado de verdad (`SceneTree.paused`
# con el runner dentro) no se prueba aquí — pausar el árbol pausaría el propio
# test. C14 se verifica a dos niveles: (1) lógica pared/diegético vía mock y
# (2) config `PROCESS_MODE_ALWAYS` heredado por todas las zonas. El freeze real
# con hardware (Deck) queda para la sesión de Sprint 2.
#
# LO QUE NO SE VERIFICA AQUÍ: duraciones de freeze (owner #4), audio duck
# (owner #16), gating R12 freeze-vs-menu-pausa (owner #15).
extends GdUnitTestSuite

const HudEscena := preload("res://src/ui/CombatHud.tscn")

var _hud: CombatHud
var _presenter: HudPresenter
var _reloj: MockWallTick
var _espia: SignalOrderSpy


func before_test() -> void:
	_hud = auto_free(HudEscena.instantiate() as CombatHud)
	add_child(_hud)
	_presenter = HudPresenter.new(_hud)
	_reloj = MockWallTick.new()
	_espia = SignalOrderSpy.new()
	_espia.observar(_reloj, &"pared_tick")
	_espia.observar(_reloj, &"freeze_finalizado")


func _valor_timer() -> float:
	return (_hud._hud_s._timer_bar.value as float)


# ─── AC-a — S solo en Aturdido, sin ease ──────────────────────────────────

func test_s_visible_solo_en_aturdido_sin_ease() -> void:
	# Arrange — fuera de Aturdido por defecto (tscn visible=false).
	assert_that(_hud._hud_s.visible).is_equal(false)
	# Act — entrar a Aturdido muestra en la misma llamada (sin ease).
	_hud.mostrar_timer_en_aturdido(true)
	assert_that(_hud._hud_s.visible).is_equal(true)
	# Act — salir oculta igual de seco.
	_hud.mostrar_timer_en_aturdido(false)
	assert_that(_hud._hud_s.visible).is_equal(false)


func test_timer_continuo_120_bordes_y_restun() -> void:
	# Arrange.
	_hud.mostrar_timer_en_aturdido(true)
	# Act — ventana completa 120 + bordes 119/121 (121 clampa al total).
	_presenter.push_timer(120, 120)
	assert_that(_valor_timer()).is_equal(120.0)
	_presenter.push_timer(119, 120)
	assert_that(_valor_timer()).is_equal(119.0)
	_presenter.push_timer(121, 120)
	assert_that(_valor_timer()).is_equal(120.0)
	_presenter.push_timer(0, 120)
	assert_that(_valor_timer()).is_equal(0.0)
	# Act — re-stun a mitad de cuenta resetea a 120.
	_presenter.push_timer(37, 120)
	_hud.mostrar_timer_en_aturdido(false)
	_hud.mostrar_timer_en_aturdido(true)
	_presenter.push_timer(120, 120)
	assert_that(_valor_timer()).is_equal(120.0)


# ─── AC-b — freeze: pared 60, diegético 0, HUD vivo (C14) ─────────────────

func test_freeze_pared_avanza_diegetico_cero_y_hud_actualiza() -> void:
	# Arrange — S visible con timer a 120.
	_hud.mostrar_timer_en_aturdido(true)
	_presenter.push_timer(120, 120)
	_reloj.iniciar_freeze(60)
	# Act — 60 ticks de pared con el mundo congelado; a mitad, el HUD recibe
	# un tick de timer (vía presenter, como en producción).
	for i in range(60):
		_reloj.avanzar_tick()
		if i == 30:
			_presenter.push_timer(90, 120)
	# Assert — pared avanzó 60, diegético 0, un solo finalizado…
	assert_that(_reloj.tick_pared()).is_equal(60)
	assert_that(_reloj.tick_diegetico()).is_equal(0)
	assert_that(_espia.nombres().count(&"freeze_finalizado")).is_equal(1)
	# …y el HUD siguió vivo en mitad del freeze (C14 a nivel lógico).
	assert_that(_valor_timer()).is_equal(90.0)


func test_hud_always_heredado_por_todas_las_zonas() -> void:
	# Arrange — Act: nada que disparar; es config (C14 estructural).
	# Assert — la capa es ALWAYS y ninguna zona lo sobrescribe (INHERIT ⇒ ALWAYS).
	assert_that(_hud.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
	assert_that(_hud._hud_nw.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_that(_hud._hud_ne.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_that(_hud._hud_s.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_that(_hud._vignette.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_that(_hud.layer).is_equal(10)


# ─── AC-c — pausa: dim, S oculto, timer congelado, corte ──────────────────

func test_pausa_dim40_oculta_s_congela_timer_y_vignette() -> void:
	# Arrange — duelo con S a 90.
	_hud.mostrar_timer_en_aturdido(true)
	_presenter.push_timer(90, 120)
	# Act — Pausa.
	_presenter.push_estado(CombatHud.EstadoHUD.PAUSA)
	# Assert — atenuado 40%, S oculto, vignette congelada.
	assert_that(abs(_hud._hud_nw.modulate.a - 0.4) < 0.001).is_true()
	assert_that(_hud._hud_s.visible).is_equal(false)
	assert_that(_hud._vignette.pausado).is_equal(true)
	# Act — ticks de timer durante la pausa se ignoran (valor congelado).
	_presenter.push_timer(50, 120)
	assert_that(_valor_timer()).is_equal(90.0)


func test_retorno_por_corte_restaura_exactos() -> void:
	# Arrange — S a 90, Pausa.
	_hud.mostrar_timer_en_aturdido(true)
	_presenter.push_timer(90, 120)
	_presenter.push_estado(CombatHud.EstadoHUD.PAUSA)
	# Act — volver a COMBATE.
	_presenter.push_estado(CombatHud.EstadoHUD.COMBATE)
	# Assert — restauración inmediata y exacta (corte, sin fade): opacidad,
	# S visible de nuevo (el flag de Aturdido persistía) y valor intacto.
	assert_that(abs(_hud._hud_nw.modulate.a - 1.0) < 0.001).is_true()
	assert_that(_hud._hud_s.visible).is_equal(true)
	assert_that(_valor_timer()).is_equal(90.0)


func test_mostrar_timer_respeta_pausa() -> void:
	# Arrange — S visible, luego Pausa (S oculto).
	_hud.mostrar_timer_en_aturdido(true)
	_presenter.push_estado(CombatHud.EstadoHUD.PAUSA)
	# Act — pedir mostrar en Pausa no lo enseña (puerta de estado).
	_hud.mostrar_timer_en_aturdido(true)
	# Assert — sigue oculto hasta volver a COMBATE.
	assert_that(_hud._hud_s.visible).is_equal(false)


# ─── AC-d — pin 60Hz ──────────────────────────────────────────────────────

func test_pin_60hz_en_project_settings() -> void:
	# Arrange — Act: lectura directa de config (determinista, sin I/O).
	var ticks: int = int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	# Assert — invariante de arquitectura (init order paso 0).
	assert_that(ticks).is_equal(60)

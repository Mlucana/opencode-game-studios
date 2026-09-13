# Tests de integración cola 7 niveles + vignette + latch — hud-004.
#
# COBERTURA: AC-a (cola: nunca dos flashes mismo tick, diferido 1 tick) ·
# AC-b (muerte suprime 800ms, fallo suprime VE 200ms) · AC-c (vignette tinta
# progresiva, sin flash de luz) · AC-d (latch+hold 2 frames).
#
# DE INTEGRACIÓN con RELOJ MANUAL. Instancian la `CombatHud.tscn` real pero con
# `_process` DESACTIVADO en capa + NW + vignette + gracia (`set_process(false)`):
# el `_process` del motor avanzaría `_reloj_ms` y los contadores de frames en
# momentos impredecibles y haría flaky cualquier aserción de ventanas — la misma
# razón por la que `BossStub.avanzar_tick()` es público. El test fija `_reloj_ms`
# y bombea `_procesar_cola_retrasada()` a mano; determinista al frame.
#
# Supera lo exigido (frame-step manual, ADVISORY): la cola y los bordes de
# supresión quedan bajo test automatizado y repetible.
extends GdUnitTestSuite

const HudEscena := preload("res://src/ui/CombatHud.tscn")

var _hud: CombatHud
var _presenter: HudPresenter


func before_test() -> void:
	_hud = auto_free(HudEscena.instantiate() as CombatHud)
	add_child(_hud)
	_presenter = HudPresenter.new(_hud)
	# Reloj manual: sin esto el _process del motor movería las ventanas.
	_hud.set_process(false)
	_hud._hud_nw.set_process(false)
	_hud._vignette.set_process(false)
	_hud._hud_nw._gracia.set_process(false)
	_hud._reloj_ms = 1000
	_hud._supresion_hasta_ms = 0


func _bombea_cola() -> void:
	_hud._procesar_cola_retrasada()


# ─── AC-a — nunca dos flashes el mismo tick ───────────────────────────────

func test_cola_alto_suprime_bajo_y_redespacha_efecto_real() -> void:
	# Arrange — FALLO ejecuta y abre supresión 200ms.
	_presenter.push_fallo()
	assert_that(_hud._hud_nw._flash_vida_frames).is_equal(2)
	# Act — FIRMA_VE (prioridad 3 > 2) en el mismo tick: se encola, NO ejecuta.
	_hud.set_firma_ve(CombatHud.FaseVE.PARADA)
	assert_that(_hud._hud_nw._gracia._firma_parada).is_equal(false)
	# Act — bombear la cola RE-DESPACHA el efecto real (no solo limpia).
	_hud._reloj_ms += 16
	_bombea_cola()
	assert_that(_hud._hud_nw._gracia._firma_parada).is_equal(true)


func test_pares_adyacentes_respetan_prioridad() -> void:
	# Arrange — pares (alto, bajo) de los 7 niveles (1=mayor prioridad).
	var pares: Array = [[1, 2], [2, 3], [3, 4], [4, 5], [5, 6]]
	for par in pares:
		var ejecutados: Array = []
		var fx_alto := func() -> void: ejecutados.append("alto")
		var fx_bajo := func() -> void: ejecutados.append("bajo")
		# Act — alto ejecuta (el caller dispara el efecto si la puerta abre),
		# bajo se encola; al bombear ejecuta.
		var abre: bool = _hud._anunciar(int(par[0]), 200, fx_alto)
		assert_that(abre).is_equal(true)
		if abre:
			fx_alto.call()
		assert_that(_hud._anunciar(int(par[1]), 0, fx_bajo)).is_equal(false)
		_hud._reloj_ms += 16
		_bombea_cola()
		# Assert — orden alto→bajo, ambos ejecutados exactamente una vez.
		assert_that(ejecutados).is_equal(["alto", "bajo"])
		# Limpia la supresión para el siguiente par.
		_hud._supresion_hasta_ms = 0


func test_nunca_dos_flashes_mismo_tick_muerte_gana() -> void:
	# Arrange — MUERTE ejecuta (supresión 800).
	_presenter.push_vida(0.0, 100.0)
	# Act — FALLO en el mismo tick: suprimido, sin flash.
	_presenter.push_fallo()
	assert_that(_hud._hud_nw._flash_vida_frames).is_equal(0)
	# Act — al bombear, el fallo encolado ejecuta después (diferido 1 tick).
	_hud._reloj_ms += 16
	_bombea_cola()
	assert_that(_hud._hud_nw._flash_vida_frames).is_equal(2)


# ─── AC-b — supresiones exactas ───────────────────────────────────────────

func test_muerte_suprime_todo_800ms() -> void:
	# Arrange — muerte a tick 1000 → muda hasta 1800.
	_presenter.push_vida(0.0, 100.0)
	assert_that(_hud._vignette.intensidad).is_equal(1.0)
	# Act + Assert — a 1799 sigue muda; a 1800 ejecuta.
	_hud._reloj_ms = 1799
	_presenter.push_fallo()
	assert_that(_hud._hud_nw._flash_vida_frames).is_equal(0)
	_hud._reloj_ms = 1800
	_presenter.push_fallo()
	assert_that(_hud._hud_nw._flash_vida_frames).is_equal(2)


func test_fallo_suprime_firma_200ms_bordes() -> void:
	# Arrange — fallo a tick 1000 → suprime VE hasta 1200.
	_presenter.push_fallo()
	# Act — a 1199 la firma se encola (no ejecuta)…
	_hud._reloj_ms = 1199
	_hud.set_firma_ve(CombatHud.FaseVE.PARADA)
	assert_that(_hud._hud_nw._gracia._firma_parada).is_equal(false)
	# …pero el diferido de 1 tick la ejecuta igual (diseño: diferir, no perder).
	_hud._reloj_ms += 16
	_bombea_cola()
	assert_that(_hud._hud_nw._gracia._firma_parada).is_equal(true)
	# Act — a 1200 exactos ejecuta directa (borde: `<`, no `<=`).
	_hud.set_firma_ve(CombatHud.FaseVE.CIERRE_SIN_PARAR)
	_hud._hud_nw.limpiar_firma_ve()
	_hud._reloj_ms = 1200
	_hud.set_firma_ve(CombatHud.FaseVE.PARADA)
	assert_that(_hud._hud_nw._gracia._firma_parada).is_equal(true)


# ─── AC-c — vignette tinta progresiva, sin flash de luz ───────────────────

func test_vignette_progresiva_por_vida_baja_y_muerte() -> void:
	# Arrange — Act: vida llena → sin tinta.
	_presenter.push_vida(100.0, 100.0)
	assert_that(_hud._vignette.intensidad).is_equal(0.0)
	# Act — vida baja (29%): tinta parcial 0 < i < 1 (progresiva, no binaria).
	_presenter.push_vida(29.0, 100.0)
	var parcial: float = _hud._vignette.intensidad
	assert_that(parcial > 0.0 and parcial < 1.0).is_true()
	# Act — muerte: tinta total + corte (el flash de fallo NO se usa aquí).
	_presenter.push_vida(0.0, 100.0)
	assert_that(_hud._vignette.intensidad).is_equal(1.0)
	# Regla de oro: la tinta vive en `intensidad`; el flash vive en su propio
	# contador — ningún camino de vida-baja/muerte toca el flash de luz.
	assert_that(_hud._vignette._flash_restante_frames).is_equal(0)


func test_flash_dura_2_frames_y_skip_lo_corta() -> void:
	# Arrange — _process desactivado: el contador solo lo mueve este test.
	_presenter.push_fallo()
	assert_that(_hud._hud_nw._flash_vida_frames).is_equal(2)
	assert_that(_hud._vignette._flash_restante_frames).is_equal(2)
	# Act — un frame manual…
	_hud._hud_nw._process(0.016)
	_hud._vignette._process(0.016)
	assert_that(_hud._hud_nw._flash_vida_frames).is_equal(1)
	assert_that(_hud._vignette._flash_restante_frames).is_equal(1)
	# Act — skip corta a final en ambos (skippables).
	_hud.skip_animations()
	assert_that(_hud._hud_nw._flash_vida_frames).is_equal(0)
	assert_that(_hud._vignette._flash_restante_frames).is_equal(0)


# ─── AC-d — latch+hold 2 frames ───────────────────────────────────────────

func test_latch_hold_2_frames_gracia() -> void:
	# Arrange — Act: absorción cachea + arma hold de 2.
	_presenter.push_gracia(3, 4)
	assert_that(_hud._hud_nw._gracia._hold_restante).is_equal(2)
	# Act + Assert — dos frames manuales lo agotan; ni uno antes ni después.
	_hud._hud_nw._gracia._process(0.016)
	assert_that(_hud._hud_nw._gracia._hold_restante).is_equal(1)
	_hud._hud_nw._gracia._process(0.016)
	assert_that(_hud._hud_nw._gracia._hold_restante).is_equal(0)


# ─── Pausa congela vignette (nota de la historia) ─────────────────────────

func test_pausa_congela_vignette() -> void:
	# Arrange — Act: Pausa congela; COMBATE reanuda.
	_presenter.push_estado(CombatHud.EstadoHUD.PAUSA)
	assert_that(_hud._vignette.pausado).is_equal(true)
	_presenter.push_estado(CombatHud.EstadoHUD.COMBATE)
	assert_that(_hud._vignette.pausado).is_equal(false)

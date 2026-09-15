# Tests de integración firma VE + gasto + knobs + reduced-motion — hud-005.
#
# COBERTURA: AC-a (firma ev.14→15→16 exacta, Postura quieta en VE, gasto
# ilegal mid-VE rechazado no-buffer con cap/cooldown intactos, cap Σ≤3 con
# log, `gracia==coste`→0.0) · AC-b (knobs live sin restart, barrido sin bajar
# de 4.5:1, piso 18px) · AC-c (reduced-motion desactiva latch+hold, cero
# flashes, solo bus). AC-d DEFERRED a Deck real (sin test, ver evidencia).
#
# DE INTEGRACIÓN con RELOJ MANUAL (patrón hud-004): `CombatHud.tscn` real,
# `_process` desactivado, `_reloj_ms` fijado a mano. Emisores: `MockFSM` +
# `MockResolver` (INFRA-01) como B-*/C-* y `MockLedgerGracia` (stand-in de #5)
# como fuente de verdad del gasto. El puente B-*/C-*→fases VE vive AQUÍ (las
# lambdas `_al_*`): stand-in del cableado Core futuro; el HUD no cambia al
# llegar. P5: los ints de display los fija el test a mano — el mock solo decide.
extends GdUnitTestSuite

const HudEscena := preload("res://src/ui/CombatHud.tscn")

var _hud: CombatHud
var _presenter: HudPresenter
var _fsm: MockFSM
var _resolver: MockResolver
var _ledger: MockLedgerGracia
var _claves: Array = []


func before_test() -> void:
	_hud = auto_free(HudEscena.instantiate() as CombatHud)
	add_child(_hud)
	_presenter = HudPresenter.new(_hud)
	_fsm = MockFSM.new()
	_resolver = MockResolver.new()
	_ledger = MockLedgerGracia.new()
	_claves = []
	# Reloj manual: sin esto el _process del motor movería ventanas y holds.
	_hud.set_process(false)
	_hud._hud_nw.set_process(false)
	_hud._hud_ne._postura.set_process(false)
	_hud._vignette.set_process(false)
	_hud._hud_nw._gracia.set_process(false)
	_hud._reloj_ms = 1000
	_hud._supresion_hasta_ms = 0
	_presenter.push_duelo(true)
	_presenter.hud_audio_requested.connect(func(clave: StringName) -> void: _claves.append(clave))
	# Puente test-only B-*/C-* → `firma_ve_changed(fase)` (ver cabecera).
	_fsm.ventana_especial_abierta.connect(_al_abrir_ve)
	_resolver.parry_resuelto.connect(_al_resolver_parry)
	_fsm.ventana_especial_cerrada.connect(_al_cerrar_ve)


func _al_abrir_ve(_id: int, _tick: int) -> void:
	_presenter.push_firma_ve(CombatHud.FaseVE.PRELIGHT)


func _al_resolver_parry(resultado: int, _wid: int, _tick: int, _delta: int, _postura: float) -> void:
	if resultado == MockResolver.Resultado.EXITO_VENTANA_ESPECIAL:
		_presenter.push_firma_ve(CombatHud.FaseVE.PARADA)


func _al_cerrar_ve(_id: int, fue_parada: bool, _tick: int) -> void:
	if not fue_parada:
		_presenter.push_firma_ve(CombatHud.FaseVE.CIERRE_SIN_PARAR)


## Seams de test (sin getters públicos; se lee el cache, nunca el dibujado).
func _lit_gracia() -> int:
	return _hud._hud_nw._gracia._lit


func _prelit() -> bool:
	return _hud._hud_nw._gracia._prelit


func _firma_parada() -> bool:
	return _hud._hud_nw._gracia._firma_parada


func _fraccion_postura() -> float:
	return _hud._hud_ne._postura._fraccion


func _contiene_tipo(n: Node, clase: StringName) -> bool:
	if n.get_class() == clase:
		return true
	for hijo in n.get_children():
		if _contiene_tipo(hijo, clase):
			return true
	return false


# ─── AC-a — firma VE ev.14 → ev.15 → ev.16 ─────────────────────────────────

func test_firma_secuencia_prelight_move_fold_exacta() -> void:
	# Arrange — Postura 50%, Gracia 2/4.
	_presenter.push_postura(50.0, 100.0)
	_presenter.push_gracia(2, 4)
	# Act — ev.14: pre-light (ilumina contorno, conteo intacto).
	var id_ve: int = _fsm.abrir_ve()
	assert_that(_prelit()).is_equal(true)
	assert_that(_lit_gracia()).is_equal(2)
	# Act — ev.15 en orden canónico cierre→resultado: Gracia SE MUEVE…
	_fsm.cerrar_ve(id_ve, true)
	_resolver.emitir_exito_ve(id_ve, 0.0)
	assert_that(_firma_parada()).is_equal(true)
	assert_that(_prelit()).is_equal(false)
	# …y Postura QUIETA (V6: la ausencia es la firma).
	assert_that(abs(_fraccion_postura() - 0.5) < 0.001).is_true()
	# Act — ev.16 (otra VE, cierre sordo): repliegue sobrio, todo limpio.
	var id_ve2: int = _fsm.abrir_ve()
	_fsm.cerrar_ve(id_ve2, false)
	assert_that(_firma_parada()).is_equal(false)
	assert_that(_prelit()).is_equal(false)
	assert_that(abs(_fraccion_postura() - 0.5) < 0.001).is_true()


# ─── AC-a — gasto ilegal mid-VE rechazado no-buffer ─────────────────────────

func test_gasto_ilegal_mid_ve_rechazado_sin_buffer() -> void:
	# Arrange — medidor en 2/4; VE abierta (gasto ilegal, G7).
	_presenter.push_gracia(2, 4)
	_ledger.abrir_ve()
	var spends_antes: int = _ledger.spends
	var cd_antes: int = _ledger.ticks_desde_gasto
	var gracia_antes: float = _ledger.gracia
	var veredictos: Array = []
	_ledger.gasto_resuelto.connect(func(aceptado: bool) -> void: veredictos.append(aceptado))
	# Act — intento ilegal aunque el contexto diga "legal" (la VE manda, G7).
	assert_that(_ledger.intentar_gasto(MockLedgerGracia.COSTE_PURGA, true)).is_equal(false)
	# Assert — cap/cooldown/gracia observably intactos (frontera #5; el test
	# de corrección de la decisión es de #5, aquí solo su reflejo).
	assert_that(_ledger.spends).is_equal(spends_antes)
	assert_that(_ledger.ticks_desde_gasto).is_equal(cd_antes)
	assert_that(_ledger.gracia).is_equal(gracia_antes)
	assert_that(veredictos).is_equal([false])
	# Act — reflejo HUD: blip por bus, medidor intacto, cero flashes nuevos.
	_presenter.push_gasto(false, 2, 4)
	assert_that(_lit_gracia()).is_equal(2)
	assert_that(_claves).is_equal([&"hud_gasto_denegado"])
	assert_that(_hud._hud_nw._flash_vida_frames).is_equal(0)
	assert_that(_hud._vignette._flash_restante_frames).is_equal(0)


func test_gasto_legal_acepta_mueve_medidor_y_click() -> void:
	# Arrange — Act: Purga legal (Telegrafiado, cooldown satisfecho).
	assert_that(_ledger.intentar_gasto(MockLedgerGracia.COSTE_PURGA, true)).is_equal(true)
	assert_that(_ledger.gracia).is_equal(12.0)
	assert_that(_ledger.spends).is_equal(1)
	# Act — reflejo HUD con ints a mano (P5): el medidor EXISTENTE se mueve,
	# sin zona ni flash nuevos; click seco por bus.
	_presenter.push_gasto(true, 1, 4)
	assert_that(_lit_gracia()).is_equal(1)
	assert_that(_claves).is_equal([&"hud_gasto_aceptado"])


func test_cap_ve_cuarta_a_uno_da_cero_con_log() -> void:
	# Arrange — 3 VE paradas: +1/+1 cada una (stub D13 s≡1.0 → Σ=3).
	for i in range(3):
		_ledger.abrir_ve()
		assert_that(_ledger.cerrar_ve(true)).is_equal(1.0)
	assert_that(_ledger.gracia).is_equal(23.0)
	# Act — 4ª VE a 1.0: +0/+0 CON log (GR-08, gate Σ+s>3).
	_ledger.abrir_ve()
	assert_that(_ledger.cerrar_ve(true)).is_equal(0.0)
	assert_that(_ledger.gracia).is_equal(23.0)
	assert_that(_ledger.registro.back().contains("cap_ve")).is_true()
	# Reflejo HUD del +0/+0: el medidor no se mueve (ints a mano, iguales).
	_presenter.push_gracia(3, 4)
	assert_that(_lit_gracia()).is_equal(3)


func test_gracia_igual_coste_acepta_a_cero() -> void:
	# Arrange — bolsa exacta (GF-S1: `gracia==coste` ACEPTA, estado legal).
	var justo := MockLedgerGracia.new(8.0, 20.0, 0.0)
	# Act + Assert.
	assert_that(justo.intentar_gasto(MockLedgerGracia.COSTE_PURGA, true)).is_equal(true)
	assert_that(justo.gracia).is_equal(0.0)


func test_dos_gastos_mismo_tick_solo_uno_acepta() -> void:
	# Arrange — Act: dos gastos el mismo tick (serializados, GR-27).
	assert_that(_ledger.intentar_gasto(MockLedgerGracia.COSTE_PURGA, true)).is_equal(true)
	assert_that(_ledger.intentar_gasto(MockLedgerGracia.COSTE_PURGA, true)).is_equal(false)
	# Assert — como máximo uno ACEPTA (el 2º ve cooldown 0<360, no-buffer).
	assert_that(_ledger.spends).is_equal(1)


func test_audio_gasto_inmediato_bajo_supresion() -> void:
	# Arrange — fallo abre supresión 200ms (la firma visual se diferiría).
	_presenter.push_fallo()
	assert_that(_claves).is_equal([&"hud_fallo"])
	# Act — el click de gasto NO se encola: es inmediato por bus (P4; el
	# solape lo arbitra el ducking, owner #16, fuera de alcance).
	_presenter.push_gasto(true, 2, 4)
	assert_that(_claves).is_equal([&"hud_fallo", &"hud_gasto_aceptado"])


# ─── AC-b — knobs live sin restart, nunca bajo 4.5:1 ────────────────────────

func test_knobs_barrido_nunca_baja_luminancia() -> void:
	# Arrange — Act: barrido completo sobre LA MISMA instancia (live).
	var opacidades: Array = [0.6, 0.8, 1.0]
	var escalas: Array = [0.9, 1.0, 1.15]
	for op in opacidades:
		for esc in escalas:
			for contraste in [false, true]:
				for sin_flash in [false, true]:
					_hud.hud_opacity = op
					_hud.hud_scale = esc
					_hud.timer_high_contrast = contraste
					_hud.disable_damage_flash = sin_flash
					# Assert — fills críticos siempre opacos (la opacidad
					# vive SOLO en fondos: a 0.6 fundido no pasaría 4.5:1).
					var fill := _hud._hud_nw._vida_bar.get_theme_stylebox(&"fill") as StyleBoxFlat
					assert_that(fill.bg_color.a).is_equal(1.0)
					var fondo := _hud._hud_nw._vida_bar.get_theme_stylebox(&"background") as StyleBoxFlat
					assert_that(abs(fondo.bg_color.a - float(op)) < 0.001).is_true()
					# Assert — texto nunca bajo 18px aparente (compensa ceil).
					var talla: int = _hud._hud_nw._vida_label.get_theme_font_size(&"font_size")
					assert_that(float(talla) * float(esc) >= 18.0 - 0.001).is_true()
	# Assert — clamps de rango (hud.md Tuning Knobs).
	_hud.hud_opacity = 0.5
	assert_that(_hud.hud_opacity).is_equal(0.6)
	_hud.hud_opacity = 1.2
	assert_that(_hud.hud_opacity).is_equal(1.0)
	_hud.hud_scale = 0.5
	assert_that(_hud.hud_scale).is_equal(0.9)
	_hud.hud_scale = 2.0
	assert_that(_hud.hud_scale).is_equal(1.15)


func test_knobs_aplican_live_sin_restart() -> void:
	# Arrange — Act: cada knob aplica en el mismo frame, misma instancia.
	_hud.hud_opacity = 0.6
	var fondo := _hud._hud_nw._vida_bar.get_theme_stylebox(&"background") as StyleBoxFlat
	assert_that(abs(fondo.bg_color.a - 0.6) < 0.001).is_true()
	_hud.hud_opacity = 1.0
	assert_that(abs(fondo.bg_color.a - 1.0) < 0.001).is_true()
	# timer_high_contrast SOLO SUBE hacia #E8ECF1, nunca baja de #C7CDD6.
	_hud.timer_high_contrast = true
	var fill_timer := _hud._hud_s._timer_bar.get_theme_stylebox(&"fill") as StyleBoxFlat
	assert_that(fill_timer.bg_color).is_equal(HudS.GRIS_CONTRASTE)
	_hud.timer_high_contrast = false
	assert_that(fill_timer.bg_color).is_equal(HudS.GRIS_LUZ)
	# disable_damage_flash se propaga a las dos zonas del evento lógico único.
	_hud.disable_damage_flash = true
	assert_that(_hud._hud_nw.usar_icono_en_vez_de_flash).is_equal(true)
	assert_that(_hud._vignette.usar_icono_en_vez_de_flash).is_equal(true)


func test_escala_compensa_fuente_piso_18px_en_tres_zonas() -> void:
	# Arrange — Act: escala mínima 0.9 (peor caso aparente).
	_hud.hud_scale = 0.9
	# Assert — las tres zonas compensan a ceil(18/0.9)=20px base.
	assert_that(_hud._hud_nw._vida_label.get_theme_font_size(&"font_size")).is_equal(20)
	assert_that(_hud._hud_ne._postura_label.get_theme_font_size(&"font_size")).is_equal(20)
	assert_that(_hud._hud_s._exact_label.get_theme_font_size(&"font_size")).is_equal(20)
	# Y a escala máxima el aparente sigue ≥18 sin inflar la base.
	_hud.hud_scale = 1.15
	assert_that(_hud._hud_nw._vida_label.get_theme_font_size(&"font_size")).is_equal(18)


# ─── AC-c — reduced-motion: corte exacto, cero flashes, solo bus ────────────

func test_reduced_motion_desactiva_hold_corte_exacto() -> void:
	# Arrange — hold de 2 armado en movimiento completo…
	_presenter.push_gracia(3, 4)
	assert_that(_hud._hud_nw._gracia._hold_restante).is_equal(2)
	# Act — activar reduced-motion colapsa en vuelo + desactiva el hold…
	_hud.reduced_motion = true
	assert_that(_hud._hud_nw._gracia._hold_restante).is_equal(0)
	# …y todo cambio posterior es corte exacto (precedencia story-005: el
	# tick crítico se verifica por corte, nunca por hold).
	_presenter.push_gracia(2, 4)
	assert_that(_hud._hud_nw._gracia._hold_restante).is_equal(0)
	_presenter.push_postura(50.0, 100.0)
	assert_that(_hud._hud_ne._postura._hold_restante).is_equal(0)
	_hud.set_firma_ve(CombatHud.FaseVE.PARADA)
	assert_that(_hud._hud_nw._gracia._hold_restante).is_equal(0)
	assert_that(_hud._hud_nw._gracia._firma_parada).is_equal(true)


func test_reduced_motion_cero_flashes_bus_lleva_feedback() -> void:
	# Arrange — Act: fallo con reduced-motion ON.
	_hud.reduced_motion = true
	_presenter.push_fallo()
	# Assert — cero flashes en ambas zonas del evento lógico único…
	assert_that(_hud._hud_nw._flash_vida_frames).is_equal(0)
	assert_that(_hud._hud_nw._flash_forma_frames).is_equal(0)
	assert_that(_hud._vignette._flash_restante_frames).is_equal(0)
	var fill := _hud._hud_nw._vida_bar.get_theme_stylebox(&"fill") as StyleBoxFlat
	assert_that(fill.bg_color).is_equal(HudNW.GRIS_LUZ)
	# …y el feedback viaja por bus (0 players directos, ver siguiente test).
	assert_that(_claves).is_equal([&"hud_fallo"])


func test_reduced_motion_solo_bus_cero_players_y_brasas_estaticas() -> void:
	# Arrange — Act: tres eventos con sonido asociado.
	_hud.reduced_motion = true
	_presenter.push_fallo()
	_presenter.push_firma_ve(CombatHud.FaseVE.PARADA)
	_presenter.push_gasto(true, 2, 4)
	# Assert — claves al bus, cero hijos players en el presentador…
	assert_that(_claves).is_equal([&"hud_fallo", &"hud_firma_ve", &"hud_gasto_aceptado"])
	assert_that(_presenter.get_child_count()).is_equal(0)
	# …cero players directos y cero emisores bajo el HUD. Brasas: N/A por
	# ausencia — CombatHud no instancia partículas (las CPUParticles2D viven
	# en Decisión, otra pantalla fuera de este epic).
	assert_that(_contiene_tipo(_hud, &"AudioStreamPlayer")).is_equal(false)
	assert_that(_contiene_tipo(_hud, &"CPUParticles2D")).is_equal(false)
	assert_that(_contiene_tipo(_hud, &"GPUParticles2D")).is_equal(false)

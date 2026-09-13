# Tests de integración reduced-motion + legibilidad — M-006a.
#
# COBERTURA: AC-a (reduced-motion: 0 flashes de color, vignette estática,
# audio por bus) · AC-b proxy automatizable (labels ≥18px, nada depende de
# hover). Sin cambios en src/: el colapso ya existe y aquí se verifica.
#
# LÍMITE DECLARADO: la sesión en hardware Deck 7" (30–40cm) y el foco
# mismo-frame de las transiciones son de M-001a/Sprint 2 — aquí el proxy
# automatizado + evidence con la parte hardware PENDING.
extends GdUnitTestSuite

const HudEscena := preload("res://src/ui/CombatHud.tscn")

var _hud: CombatHud
var _presenter: HudPresenter


func before_test() -> void:
	_hud = auto_free(HudEscena.instantiate() as CombatHud)
	add_child(_hud)
	_presenter = HudPresenter.new(_hud)
	# Determinismo: los contadores de frames solo los mueve este test.
	_hud.set_process(false)
	_hud._hud_nw.set_process(false)
	_hud._vignette.set_process(false)
	_hud._hud_nw._gracia.set_process(false)
	_hud._reloj_ms = 1000
	_hud._supresion_hasta_ms = 0


func _controles(n: Node, salida: Array) -> void:
	if n is Control:
		salida.append(n)
	for hijo in n.get_children():
		_controles(hijo, salida)


# ─── AC-a — reduced-motion: cero color, forma intacta ─────────────────────

func test_reduced_motion_se_propaga_a_las_6_zonas() -> void:
	# Arrange — Act.
	_hud.reduced_motion = true
	# Assert — NW, NE, S, vignette, esquirlas y bloques (hold intacto: no es
	# decoración, es anti-40Hz y no se toca).
	assert_that(_hud._hud_nw.reduced_motion).is_equal(true)
	assert_that(_hud._hud_ne.reduced_motion).is_equal(true)
	assert_that(_hud._hud_s.reduced_motion).is_equal(true)
	assert_that(_hud._vignette.reduced_motion).is_equal(true)
	assert_that(_hud._hud_nw._gracia.reduced_motion).is_equal(true)
	assert_that(_hud._hud_ne._postura.reduced_motion).is_equal(true)


func test_flash_icono_cero_color_con_forma() -> void:
	# Arrange — modo no-cromático (fotosensibilidad).
	_hud.disable_damage_flash = true
	assert_that(_hud._hud_nw.usar_icono_en_vez_de_flash).is_equal(true)
	assert_that(_hud._vignette.usar_icono_en_vez_de_flash).is_equal(true)
	# Act — fallo.
	_presenter.push_fallo()
	# Assert — fill intacto (cero cambio de color como señal)…
	var fill := _hud._hud_nw._vida_bar.get_theme_stylebox(&"fill") as StyleBoxFlat
	assert_that(fill.bg_color).is_equal(HudNW.GRIS_LUZ)
	# …pero la forma se activa (outline + marca, respaldo no-cromático).
	assert_that(_hud._hud_nw._flash_forma_frames > 0).is_equal(true)
	assert_that(_hud._vignette._flash_restante_frames).is_equal(2)


func test_audio_solo_por_bus_sin_players() -> void:
	# Arrange — Act: dos eventos con sonido asociado.
	var claves: Array = []
	_presenter.hud_audio_requested.connect(func(clave: StringName) -> void: claves.append(clave))
	_presenter.push_fallo()
	_presenter.push_firma_ve(CombatHud.FaseVE.PARADA)
	# Assert — claves emitidas al bus…
	assert_that(claves).is_equal([&"hud_fallo", &"hud_firma_ve"])
	# …y el presentador jamás instancia players (cero hijos).
	assert_that(_presenter.get_child_count()).is_equal(0)


# ─── AC-b proxy — legibilidad sin hardware ────────────────────────────────

func test_labels_nunca_bajo_18px() -> void:
	# Arrange — Act: barrido del árbol real.
	var controles: Array = []
	_controles(_hud, controles)
	var vistos: int = 0
	for c in controles:
		if c is Label:
			vistos += 1
			assert_that((c as Label).get_theme_font_size(&"font_size") >= 18).is_equal(true)
	# Assert — proxy 0/0 con al menos los labels funcionales recorridos.
	assert_that(vistos >= 5).is_equal(true)


func test_nada_depende_de_hover() -> void:
	# Arrange — Act: todo Control del HUD…
	var controles: Array = []
	_controles(_hud, controles)
	# Assert — …es MOUSE_FILTER_IGNORE (incluidos los readouts focables: el
	# foco es de mando/teclado, nunca de hover).
	for c in controles:
		assert_that((c as Control).mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)


func test_skip_global_inmediato() -> void:
	# Arrange — flash + prelight + holds armados.
	_presenter.push_gracia(2, 4)
	_presenter.push_postura(50.0, 100.0)
	_presenter.push_fallo()
	_hud.set_firma_ve(CombatHud.FaseVE.PRELIGHT)
	# Act.
	_hud.skip_animations()
	# Assert — todo a estado final en la misma llamada.
	assert_that(_hud._hud_nw._flash_vida_frames).is_equal(0)
	assert_that(_hud._vignette._flash_restante_frames).is_equal(0)
	assert_that(_hud._hud_nw._gracia._hold_restante).is_equal(0)
	assert_that(_hud._hud_ne._postura._hold_restante).is_equal(0)

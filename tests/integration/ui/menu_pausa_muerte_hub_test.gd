# Tests de integración Pausa + Muerte muda + Hub — M-003.
#
# COBERTURA: AC MENU-04 (pausa duelo-only: 3 exactas en orden, Continuar/reintento
# ausentes del árbol por construcción) · disciplina modal Decisión (swallow 200ms,
# trap + restore) · gating ADR-001 R12 (timer S congelado sin contar vía CombatHud
# real: S oculto + valor intacto + retorno por corte) · AC muerte (muda Rev2: solo
# Volver, placeholder TBD, sin cita) · AC hub (SUS persistente + stakes junto a
# entrada, claves tabla) · AC MENU-14 (solo settings.save muta; PER/SUS en 0) +
# S4/S5 no-editable · presenter display-only (reemite 1:1, sin change_scene, bus).
#
# DE INTEGRACIÓN con RELOJ MANUAL en las 3 vistas (patrón Decisión): determinismo
# total del swallow 200ms. LÍMITES DECLARADOS: MENU-05 DEFERRED (p95 ≤300ms con
# fake-clock + Deck real en integración, sin test aquí — ver evidencia) · la
# sustitución {coro}/{mm_ss} con literales es-MX la fija `/localize` (sin tablas
# aún: aquí claves + placeholders, no literales) · trauma-decay/latch-stamps R12
# son owner WallTick/Feedback (aquí solo el lado UI: timer S) · foco post-splash
# y `change_scene` único son owner router M-001a (aquí TODOs explícitos).
extends GdUnitTestSuite

const HudEscena := preload("res://src/ui/CombatHud.tscn")

var _pausa: MenuPausa
var _muerte: MenuMuerte
var _hub: MenuHub
var _presenter: MenuPresenter
var _store: MenuSettingsStore
var _hud: CombatHud


func before_test() -> void:
	_pausa = auto_free(MenuPausa.new())
	_muerte = auto_free(MenuMuerte.new())
	_hub = auto_free(MenuHub.new())
	add_child(_pausa)
	add_child(_muerte)
	add_child(_hub)
	_presenter = auto_free(MenuPresenter.new())
	add_child(_presenter)
	_store = MenuSettingsStore.new()
	_hud = auto_free(HudEscena.instantiate() as CombatHud)
	add_child(_hud)
	# Determinismo: swallow 200ms solo avanza a mano en estos tests.
	_pausa.set_reloj_manual(true, 10000)
	_muerte.set_reloj_manual(true, 10000)
	_hub.set_reloj_manual(true, 10000)
	_hud.set_process(false)


func _textos(n: Node, salida: Array) -> void:
	if n is Button:
		salida.append((n as Button).text)
	if n is Label:
		salida.append((n as Label).text)
	for hijo in n.get_children():
		_textos(hijo, salida)


func _nombres(n: Node, salida: Array) -> void:
	salida.append(n.name)
	for hijo in n.get_children():
		_nombres(hijo, salida)


func _botones(n: Node, salida: Array) -> void:
	if n is Button:
		salida.append(n)
	for hijo in n.get_children():
		_botones(hijo, salida)


func _etiquetas(n: Node, salida: Array) -> void:
	if n is Label:
		salida.append(n)
	for hijo in n.get_children():
		_etiquetas(hijo, salida)


func _contiene_tipo(n: Node, clase: StringName) -> bool:
	if n.get_class() == clase:
		return true
	for hijo in n.get_children():
		if _contiene_tipo(hijo, clase):
			return true
	return false


# ─── MENU-04 — pausa duelo-only: 3 exactas en orden ──────────────────────────

func test_pausa_tres_opciones_en_orden_exactas() -> void:
	# Arrange — Act.
	var botones: Array[Button] = _pausa.botones_en_orden()
	# Assert — exactamente 3, en orden normativo, vía tr() (sin locale: la clave).
	assert_that(botones.size()).is_equal(3)
	assert_that([botones[0].text, botones[1].text, botones[2].text]).is_equal(
		["MENU_PAUSA_REANUDAR", "MENU_PAUSA_ABANDONAR", "MENU_PAUSA_AJUSTES"])


func test_pausa_sin_continuar_ni_reintento_en_arbol() -> void:
	# Arrange — overlay abierta (el árbol completo existe solo visible).
	_pausa.abrir()
	# Act — volcado total de textos + nombres.
	var textos: Array = []
	var nombres: Array = []
	_textos(_pausa, textos)
	_nombres(_pausa, nombres)
	var junto := " | ".join(PackedStringArray(textos + nombres)).to_lower()
	# Assert — ausencia por construcción (no deshabilitados): ni Continuar ni
	# reintento aparecen en ningún texto ni nombre de nodo.
	assert_that(junto.contains("continuar")).is_equal(false)
	assert_that(junto.contains("reinten")).is_equal(false)
	assert_that(junto.contains("retry")).is_equal(false)


# ─── Disciplina modal Decisión: foco inicial, trampa, restore, swallow ───────

func test_pausa_foco_inicial_trampa_y_restaura() -> void:
	# Arrange — Act: abrir fija Reanudar (mapa de foco GDD R7).
	_pausa.abrir()
	assert_that(_pausa.foco_actual()).is_equal(MenuPausa.Opcion.REANUDAR)
	# Act — trampa: avanzar 3 envuelve a Reanudar; retroceder 1 cae en Ajustes.
	_pausa.intentar_mover_foco(1)
	_pausa.intentar_mover_foco(1)
	_pausa.intentar_mover_foco(1)
	assert_that(_pausa.foco_actual()).is_equal(MenuPausa.Opcion.REANUDAR)
	_pausa.intentar_mover_foco(-1)
	assert_that(_pausa.foco_actual()).is_equal(MenuPausa.Opcion.AJUSTES)
	# Act — cerrar restaura: overlay fuera, foco lógico a -1, nada atrapado.
	_pausa.cerrar()
	assert_that(_pausa.esta_abierta()).is_equal(false)
	assert_that(_pausa.foco_actual()).is_equal(-1)


func test_pausa_swallow_200ms_consume_doble_gesto() -> void:
	# Arrange — Abandonar (queda abierta: la firma vive en M-004).
	var lista: Array = []
	_pausa.pausa_abandonar.connect(func() -> void: lista.append(1))
	_pausa.abrir()
	_pausa.intentar_mover_foco(1)
	# Act — primer gesto despacha…
	_pausa.intentar_activar()
	assert_that(lista).is_equal([1])
	# …el segundo inmediato se consume en silencio (swallow 200ms)…
	_pausa.intentar_activar()
	assert_that(lista).is_equal([1])
	# …a 199ms sigue inhibido, a 200ms despacha de nuevo (borde exacto).
	_pausa.avanzar_reloj_manual(199)
	_pausa.intentar_activar()
	assert_that(lista).is_equal([1])
	_pausa.avanzar_reloj_manual(1)
	_pausa.intentar_activar()
	assert_that(lista).is_equal([1, 1])


func test_pausa_cancelar_es_reanudar_por_corte() -> void:
	# Arrange.
	var reanuda: Array = []
	var audio: Array = []
	_pausa.pausa_reanudar.connect(func() -> void: reanuda.append(1))
	_pausa.menu_audio_requested.connect(func(c: StringName) -> void: audio.append(c))
	# Act — ui_cancel = retorno seguro (sin atrás apilado), por corte.
	_pausa.abrir()
	assert_that(_pausa.intentar_cancelar()).is_equal(true)
	# Assert — intención + timbre atrás + overlay fuera en la misma llamada.
	assert_that(reanuda).is_equal([1])
	assert_that(audio).is_equal([&"ui_atras"])
	assert_that(_pausa.esta_abierta()).is_equal(false)


# ─── Gating ADR-001 R12 (lado UI): timer S congelado sin contarlo ────────────

func test_pausa_congela_timer_s_sin_contarlo_y_retorna_por_corte() -> void:
	# Arrange — duelo con S a 90 (Aturdido).
	_hud.mostrar_timer_en_aturdido(true)
	_hud.set_timer(90, 120)
	_presenter.set_vistas(_pausa, _muerte, _hub)
	_presenter.set_hud(_hud)
	# Act — abrir Pausa ordena al HUD (TODO M-001a: el router hará suya la orden).
	_presenter.abrir_pausa()
	# Assert — atenuado 40%, S oculto, vignette congelada (hud.md + R12).
	assert_that(abs(_hud._hud_nw.modulate.a - 0.4) < 0.001).is_true()
	assert_that(_hud._hud_s.visible).is_equal(false)
	assert_that(_hud._vignette.pausado).is_equal(true)
	# Act — ticks de timer durante la pausa se ignoran (valor congelado, no cuenta).
	_hud.set_timer(50, 120)
	assert_that(float(_hud._hud_s._timer_bar.value)).is_equal(90.0)
	# Act — cerrar restaura por corte: opacidad, S visible, valor intacto.
	_presenter.cerrar_pausa()
	assert_that(abs(_hud._hud_nw.modulate.a - 1.0) < 0.001).is_true()
	assert_that(_hud._hud_s.visible).is_equal(true)
	assert_that(float(_hud._hud_s._timer_bar.value)).is_equal(90.0)


# ─── Muerte muda Rev2: placeholder TBD + solo Volver, sin cita ───────────────

func test_muerte_muda_solo_volver_sin_cita() -> void:
	# Arrange — Act.
	_muerte.abrir()
	var botones: Array = []
	_botones(_muerte, botones)
	var textos: Array = []
	_textos(_muerte, textos)
	var junto := " | ".join(PackedStringArray(textos)).to_lower()
	# Assert — un solo botón (Volver), placeholder presente, muda por construcción.
	assert_that(botones.size()).is_equal(1)
	assert_that((botones[0] as Button).text).is_equal("MENU_MUERTE_VOLVER")
	assert_that(_muerte.get_node_or_null(^"SafeZone/Centro/Columna/ObjetoHubPlaceholder") != null).is_equal(true)
	assert_that(_muerte.es_muda()).is_equal(true)
	assert_that(junto.contains("cita")).is_equal(false)
	assert_that(_muerte.claves_texto()).is_equal([&"MENU_MUERTE_OBJETO_DESC", &"MENU_MUERTE_VOLVER"])


func test_muerte_unica_salida_con_swallow() -> void:
	# Arrange.
	var salidas: Array = []
	_muerte.muerte_volver.connect(func() -> void: salidas.append(1))
	_muerte.abrir()
	# Act — activar y cancelar van a la misma única salida; el 2º gesto se traga.
	_muerte.intentar_activar()
	_muerte.intentar_cancelar()
	assert_that(salidas).is_equal([1])
	_muerte.avanzar_reloj_manual(200)
	_muerte.intentar_cancelar()
	assert_that(salidas).is_equal([1, 1])


# ─── Hub: SUS persistente sobria + stakes junto a la entrada ─────────────────

func test_hub_sus_visible_con_sus_y_oculta_sin_ella_stakes_siempre() -> void:
	# Arrange — Act: punto seguro con SUS vigente.
	var con_sus := _hub.configure({"sus_vigente": true, "coro_label": "Coro II", "mm_ss": "12:34"})
	# Assert — línea SUS visible; stakes + entrada intactos y adyacentes.
	assert_that(con_sus).is_equal(true)
	assert_that(_hub.sus_visible()).is_equal(true)
	var t := _hub.textos_actuales()
	assert_that(t["stakes"]).is_equal("MENU_HUB_STAKES")
	assert_that(t["entrar"]).is_equal("MENU_HUB_ENTRAR_DUELO")
	assert_that(_hub.get_node(^"SafeZone/Centro/Columna/FilaDuelo/BtnEntrarDuelo") != null).is_equal(true)
	assert_that(_hub.get_node(^"SafeZone/Centro/Columna/FilaDuelo/LblStakes").get_parent()).is_equal(
		_hub.get_node(^"SafeZone/Centro/Columna/FilaDuelo/BtnEntrarDuelo").get_parent())
	# Act — S1 sin SUS: la línea se oculta, stakes + entrada persisten (sobrio).
	_hub.configure({"sus_vigente": false})
	assert_that(_hub.sus_visible()).is_equal(false)
	assert_that(_hub.textos_actuales()["stakes"]).is_equal("MENU_HUB_STAKES")
	assert_that(_hub.visible).is_equal(true)


func test_hub_entrar_emite_con_swallow_y_cancela_es_sordo() -> void:
	# Arrange.
	var entrar: Array = []
	var audio: Array = []
	_hub.hub_entrar_duelo.connect(func() -> void: entrar.append(1))
	_hub.menu_audio_requested.connect(func(c: StringName) -> void: audio.append(c))
	_hub.configure({"sus_vigente": true, "coro_label": "Coro II", "mm_ss": "12:34"})
	# Act — entrar despacha una vez; el 2º gesto <200ms se consume (dedupe
	# autoritativo: Guardado R9/CONSUMIENDO; aquí solo anti-doble-gesto).
	_hub.intentar_entrar()
	_hub.intentar_entrar()
	assert_that(entrar).is_equal([1])
	_hub.avanzar_reloj_manual(200)
	_hub.intentar_entrar()
	assert_that(entrar).is_equal([1, 1])
	# Act — cancelar: no-op + error sordo (Salir/Abandonar viven en M-001a/M-004).
	_hub.avanzar_reloj_manual(200)
	assert_that(_hub.intentar_cancelar()).is_equal(true)
	assert_that(entrar).is_equal([1, 1])
	assert_that(audio.back()).is_equal(&"ui_error_bloqueado")


# ─── MENU-14: solo settings.save muta; S4/S5 no editable; JSON-safe ──────────

func test_settings_cambio_muta_solo_settings_save() -> void:
	# Arrange — Act: dos ajustes en S0 (espía FS: PER/SUS ausentes por diseño).
	assert_that(_store.aplicar_ajuste("volumen", 0.5)).is_equal(true)
	assert_that(_store.aplicar_ajuste("idioma", "es-MX")).is_equal(true)
	# Assert — SOLO settings.save tocado (MENU-14 + MENU-08).
	assert_that(_store.writes_settings()).is_equal(2)
	assert_that(_store.writes_profile()).is_equal(0)
	assert_that(_store.writes_suspend()).is_equal(0)
	assert_that(_store.solo_settings_mutado()).is_equal(true)
	assert_that(_store.leer("volumen")).is_equal(0.5)


func test_settings_s4_s5_no_editable_y_rechaza_no_json() -> void:
	# Arrange — Act: S4/S5 (perfil ilegible) bloquea edición sin mutar ni contar.
	_store.set_editable(false)
	assert_that(_store.aplicar_ajuste("volumen", 0.5)).is_equal(false)
	assert_that(_store.writes_settings()).is_equal(0)
	assert_that(_store.solo_settings_mutado()).is_equal(true)
	# Arrange — Act: valores no JSON-safe se rechazan (fail-closed, Guardado R6).
	_store.set_editable(true)
	assert_that(_store.aplicar_ajuste("", 0.5)).is_equal(false)
	assert_that(_store.aplicar_ajuste("x", NAN)).is_equal(false)
	assert_that(_store.aplicar_ajuste("x", INF)).is_equal(false)
	assert_that(_store.writes_settings()).is_equal(0)


# ─── Presenter display-only: reemite 1:1, sin change_scene, solo bus ─────────

func test_presenter_reemite_intenciones_por_bus_sin_escena_ni_players() -> void:
	# Arrange — cableado completo contra mocks (superficie pura, sin router).
	_presenter.set_vistas(_pausa, _muerte, _hub)
	_presenter.set_hud(_hud)
	_presenter.set_store(_store)
	assert_that(_presenter.esta_listo()).is_equal(true)
	var got: Dictionary = {"reanudar": [], "abandonar": [], "ajustes": [], "volver": [], "entrar": [], "audio": []}
	_presenter.pausa_reanudar.connect(func() -> void: (got["reanudar"] as Array).append(1))
	_presenter.pausa_abandonar.connect(func() -> void: (got["abandonar"] as Array).append(1))
	_presenter.pausa_ajustes.connect(func() -> void: (got["ajustes"] as Array).append(1))
	_presenter.muerte_volver.connect(func() -> void: (got["volver"] as Array).append(1))
	_presenter.hub_entrar_duelo.connect(func() -> void: (got["entrar"] as Array).append(1))
	_presenter.audio_solicitado.connect(func(c: StringName) -> void: (got["audio"] as Array).append(c))
	# Act — cada intención atraviesa el presenter 1:1 (relojes manuales a mano).
	_presenter.abrir_pausa()
	_pausa.intentar_cancelar()
	_pausa.avanzar_reloj_manual(300)
	_presenter.abrir_pausa()
	_pausa.intentar_mover_foco(1)
	_pausa.intentar_activar()
	_pausa.avanzar_reloj_manual(300)
	_pausa.intentar_mover_foco(1)
	_pausa.intentar_activar()
	_presenter.abrir_muerte()
	_muerte.intentar_activar()
	_presenter.configurar_hub({"sus_vigente": false})
	_hub.intentar_entrar()
	assert_that(_presenter.aplicar_ajuste("volumen", 0.5)).is_equal(true)
	# Assert — reemisiones exactas + audio por bus (0 players directos).
	assert_that(got["reanudar"]).is_equal([1])
	assert_that(got["abandonar"]).is_equal([1])
	assert_that(got["ajustes"]).is_equal([1])
	assert_that(got["volver"]).is_equal([1])
	assert_that(got["entrar"]).is_equal([1])
	assert_that(got["audio"]).is_equal([&"ui_atras", &"ui_foco", &"ui_armar_destructivo",
		&"ui_foco", &"ui_confirmar_neutro", &"ui_confirmar_neutro", &"ui_confirmar_neutro"])
	assert_that(_presenter.get_child_count()).is_equal(0)
	assert_that(_contiene_tipo(_pausa, &"AudioStreamPlayer")).is_equal(false)
	assert_that(_contiene_tipo(_muerte, &"AudioStreamPlayer")).is_equal(false)
	assert_that(_contiene_tipo(_hub, &"AudioStreamPlayer")).is_equal(false)
	assert_that(_contiene_tipo(_pausa, &"CPUParticles2D")).is_equal(false)


# ─── Foco visible + legibilidad (GDD R7, sin hardware): borde 2px, 0 glow ─────

func test_foco_borde_2px_sin_glow_labels_18px_safe_5pct() -> void:
	# Arrange — Act: barrido de las 3 superficies.
	_pausa.abrir()
	_muerte.abrir()
	_hub.configure({"sus_vigente": true, "coro_label": "Coro II", "mm_ss": "12:34"})
	var botones: Array = []
	_botones(_pausa, botones)
	_botones(_muerte, botones)
	_botones(_hub, botones)
	assert_that(botones.size()).is_equal(5)
	for b in botones:
		var boton := b as Button
		# Assert — foco = borde 2px #C7CDD6 + marcador, 0 glow (GDD R7 Visual).
		var foco := boton.get_theme_stylebox(&"focus") as StyleBoxFlat
		assert_that(foco.border_color).is_equal(Color("C7CDD6"))
		assert_that(foco.border_width_left).is_equal(2)
		assert_that(foco.shadow_size).is_equal(0)
		# Assert — dual-focus: hover idéntico a normal (nada hover-only).
		var normal := boton.get_theme_stylebox(&"normal") as StyleBoxFlat
		var hover := boton.get_theme_stylebox(&"hover") as StyleBoxFlat
		assert_that(hover.bg_color).is_equal(normal.bg_color)
		assert_that(boton.focus_mode).is_equal(Control.FOCUS_ALL)
	# Assert — texto funcional ≥18px en las 3 superficies (proxy MENU-13).
	var etiquetas: Array = []
	_etiquetas(_pausa, etiquetas)
	_etiquetas(_muerte, etiquetas)
	_etiquetas(_hub, etiquetas)
	assert_that(etiquetas.size() >= 4).is_equal(true)
	for e in etiquetas:
		assert_that((e as Label).get_theme_font_size(&"font_size") >= 18).is_equal(true)
	# Los textos de botón no son nodos Label: se verifican aparte (proxy MENU-13 completo).
	for b in botones:
		assert_that((b as Button).get_theme_font_size(&"font_size") >= 18).is_equal(true)
	# Assert — safe-zone 5% en las 3 (proxy Deck 1280×800).
	for vista: CanvasLayer in [_pausa, _muerte, _hub]:
		var safe := vista.get_node(^"SafeZone") as Control
		assert_that(abs(safe.anchor_left - 0.05) < 0.0001).is_true()
		assert_that(abs(safe.anchor_right - 0.95) < 0.0001).is_true()
		assert_that(abs(safe.anchor_top - 0.05) < 0.0001).is_true()
		assert_that(abs(safe.anchor_bottom - 0.95) < 0.0001).is_true()
		assert_that(vista.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)


# ─── Fixes post-code-review (2026-09-13): W2/W3 + endurecido ─────────────────

func test_pausa_abandonar_queda_abierta_espera_firma() -> void:
	# Arrange — reloj manual, fuera de swallow (el reset de set_reloj_manual
	# aísla del reloj real).
	var lista: Array = []
	_pausa.pausa_abandonar.connect(func() -> void: lista.append(1))
	# Act — activar sobre ABANDONAR lista (la firma destructiva vive en M-004).
	_pausa.abrir()
	_pausa.intentar_mover_foco(1)
	_pausa.intentar_activar()
	# Assert — señal emitida Y overlay abierta (no cierra: espera la firma).
	assert_that(lista).is_equal([1])
	assert_that(_pausa.esta_abierta()).is_equal(true)
	assert_that(_pausa.foco_actual()).is_equal(MenuPausa.Opcion.ABANDONAR)


func test_muerte_es_muda_rompe_si_cita_anadida() -> void:
	# Arrange — Act: invariante intacta en el árbol tal cual se construye.
	_muerte.abrir()
	assert_that(_muerte.es_muda()).is_equal(true)
	# Act — alguien añade un Label de cita: el scan lo delata (fail-closed).
	var cita: Node = auto_free(Label.new())
	cita.name = "LblCita"
	cita.text = "una cita"
	_muerte.get_node(^"SafeZone/Centro/Columna").add_child(cita)
	# Assert — ya no es muda (el test rompería en CI ante la regresión).
	assert_that(_muerte.es_muda()).is_equal(false)


func test_hub_configure_invalido_oculta_sus_stakes_intactos() -> void:
	# Arrange — Act: SUS vigente pero sin coro/mm_ss → sin línea SUS.
	assert_that(_hub.configure({"sus_vigente": true, "coro_label": "", "mm_ss": ""})).is_equal(false)
	# Assert — SUS oculta, stakes + entrada intactos y visibles.
	assert_that(_hub.sus_visible()).is_equal(false)
	assert_that(_hub.textos_actuales()["stakes"]).is_equal("MENU_HUB_STAKES")
	assert_that(_hub.textos_actuales()["entrar"]).is_equal("MENU_HUB_ENTRAR_DUELO")
	assert_that(_hub.visible).is_equal(true)
	# Act — tipos raros (int/Array en vez de String) no muestran SUS indebidamente.
	assert_that(_hub.configure({"sus_vigente": true, "coro_label": 123, "mm_ss": ["x"]})).is_equal(false)
	assert_that(_hub.sus_visible()).is_equal(false)


func test_foco_cambiado_se_emite_en_tres_vistas() -> void:
	# Arrange — señales de VISTA directamente (no el pass del presenter).
	var focos_pausa: Array = []
	var focos_muerte: Array = []
	var focos_hub: Array = []
	_pausa.foco_cambiado.connect(func(e: StringName) -> void: focos_pausa.append(e))
	_muerte.foco_cambiado.connect(func(e: StringName) -> void: focos_muerte.append(e))
	_hub.foco_cambiado.connect(func(e: StringName) -> void: focos_hub.append(e))
	# Act — abrir no anuncia (silencio); mover/configurar sí.
	_pausa.abrir()
	_pausa.intentar_mover_foco(1)
	_muerte.abrir()
	_hub.configure({"sus_vigente": false})
	# Assert — una emisión por fijado, con el elemento exacto.
	assert_that(focos_pausa).is_equal([&"ABANDONAR"])
	assert_that(focos_muerte).is_equal([&"VOLVER"])
	assert_that(focos_hub).is_equal([&"ENTRAR_DUELO"])

# Suite de interacción de la pantalla Decisión de Gracia (P4, díada ceremonial).
#
# COBERTURA: DEC-02, DEC-03, DEC-04, DEC-09, DEC-10, DEC-12, DEC-14, DEC-15, DEC-18.
# Tipo UI → test de interacción (ADVISORY). Determinista: reloj manual inyectado
# (cero pared real), cada test monta su escena y `auto_free` la desmonta.
# Se usa el subconjunto estrecho `assert_that()` / `assert_bool()` como en
# `combate_formulas_test.gd`.
extends GdUnitTestSuite

const VistaScript := preload("res://src/ui/decision_gracia.gd")
const PresenterScript := preload("res://src/ui/decision_gracia_presenter.gd")
const ESCENA := "res://src/ui/DecisionGracia.tscn"
const SRC_VISTA := "res://src/ui/decision_gracia.gd"
const SRC_PRESENTER := "res://src/ui/decision_gracia_presenter.gd"

const R_TOMAR := "SafeZone/Columna/Diada/TomarCol/TomarFila/BtnTomar"
const R_DEJAR := "SafeZone/Columna/Diada/DejarCol/DejarFila/BtnDejarIr"
const R_SUCCION := "SafeZone/SuccionFX"
const R_ASCENSO := "SafeZone/AscensoFX"
const R_ROSETON := "SafeZone/RosetonNuevo"
const R_ANGEL := "SafeZone/Columna/AngelBrasas"

var _vista
var _tomados: Array = []
var _dejados: Array = []
var _audios: Array = []
var _transiciones: Array = []
var _invalidos: Array = []


func before_test() -> void:
	_tomados = []
	_dejados = []
	_audios = []
	_transiciones = []
	_invalidos = []
	var escena: PackedScene = load(ESCENA)
	_vista = auto_free(escena.instantiate())
	add_child(_vista)
	_vista.set_reloj_manual(true, 1000)
	_vista.decision_commit_tomar.connect(func(p: Dictionary) -> void: _tomados.append(p))
	_vista.decision_commit_dejar_ir.connect(func(p: Dictionary) -> void: _dejados.append(p))
	_vista.decision_audio_requested.connect(func(c: StringName) -> void: _audios.append(c))
	_vista.transicion_solicitada.connect(func(o: StringName, d: StringName) -> void: _transiciones.append([o, d]))
	_vista.snapshot_invalido.connect(func(m: StringName) -> void: _invalidos.append(m))


func _snapshot_valido() -> Dictionary:
	return {
		"gracia_actual": 30.0,
		"corrupcion_actual": 20.0,
		"poso_irreversible": 12.0,
		"angeles_absorbidos": 1,
		"decision_absorber": [1],
		"coro_idx": 0,
		"poder_desbloqueable": {"id": "coro_1", "nombre_key": "MENU_DECISION_DATO_AUSENTE"},
	}


func _btn_tomar() -> Button:
	return _vista.get_node(R_TOMAR) as Button


func _btn_dejar() -> Button:
	return _vista.get_node(R_DEJAR) as Button


# ─── DEC-02 — foco neutro al abrir ────────────────────────────────────────────

func test_abrir_valido_foco_neutro_y_diada_habilitada() -> void:
	assert_bool(_vista.configure(_snapshot_valido())).is_true()
	assert_bool(_vista.esta_configurada()).is_true()
	assert_that(_vista.foco_actual()).is_equal(-1)
	assert_bool(_btn_tomar().has_focus()).is_false()
	assert_bool(_btn_dejar().has_focus()).is_false()
	assert_bool(_btn_tomar().disabled).is_false()
	assert_bool(_btn_dejar().disabled).is_false()


# ─── DEC-02 / DEC-15 — agarra + trampa en díada ───────────────────────────────

func test_primer_flanco_agarra_y_trampa_atrapa() -> void:
	_vista.configure(_snapshot_valido())
	assert_bool(_vista.intentar_agarrar_foco(-1)).is_true()
	assert_that(_vista.foco_actual()).is_equal(0)
	assert_bool(_btn_tomar().has_focus()).is_true()
	_vista.intentar_agarrar_foco(1)
	assert_that(_vista.foco_actual()).is_equal(1)
	assert_bool(_btn_dejar().has_focus()).is_true()
	# Trampa: avanzar desde DEJAR IR cicla a TOMAR, jamás escapa.
	_vista.intentar_agarrar_foco(1)
	assert_that(_vista.foco_actual()).is_equal(0)
	_vista.intentar_agarrar_foco(-1)
	assert_that(_vista.foco_actual()).is_equal(1)
	assert_that(_audios.size()).is_equal(4)


# ─── DEC-03 — commit atómico mismo frame + payload + dedupe ──────────────────

func test_commit_tomar_deshabilita_mismo_frame_y_emite_payload() -> void:
	_vista.configure(_snapshot_valido())
	_vista.intentar_agarrar_foco(-1)
	_vista.intentar_commit()
	assert_bool(_vista.esta_commiteada()).is_true()
	assert_that(_tomados.size()).is_equal(1)
	assert_that(_dejados.size()).is_equal(0)
	assert_bool(_btn_tomar().disabled).is_true()
	assert_bool(_btn_dejar().disabled).is_true()
	var carga: Dictionary = _tomados[0]
	assert_that(carga["coro_idx"]).is_equal(0)
	assert_that(carga["n_previo"]).is_equal(1)
	assert_that((carga["triple_previo"] as Dictionary)["g"]).is_equal(30.0)
	assert_that((carga["triple_previo"] as Dictionary)["c"]).is_equal(20.0)
	assert_that((carga["triple_previo"] as Dictionary)["poso"]).is_equal(12.0)
	assert_that(carga["poder_id"]).is_equal(&"coro_1")
	assert_that(_audios[_audios.size() - 1]).is_equal(&"ui_cometer_irrevocable")
	# 2º input del mismo tick tumbado; y tras el swallow sigue tumbado.
	_vista.intentar_commit()
	_vista.avanzar_reloj_manual(500)
	_vista.intentar_commit()
	assert_that(_tomados.size()).is_equal(1)


func test_commit_dejar_ir_emite_variante_sobria() -> void:
	_vista.configure(_snapshot_valido())
	_vista.intentar_agarrar_foco(1)
	_vista.intentar_commit()
	assert_that(_dejados.size()).is_equal(1)
	assert_that(_tomados.size()).is_equal(0)
	assert_that((_dejados[0] as Dictionary)["coro_idx"]).is_equal(0)
	assert_bool((_dejados[0] as Dictionary).has("poder_id")).is_false()
	assert_that(_audios[_audios.size() - 1]).is_equal(&"ui_resolucion_sobria")


# ─── DEC-03 — swallow 200 ms consume en silencio ─────────────────────────────

func test_swallow_200ms_consume_en_silencio() -> void:
	_vista.configure(_snapshot_valido())
	_vista.intentar_agarrar_foco(-1)
	_vista.intentar_commit()
	var audios_tras_commit: int = _audios.size()
	_vista.avanzar_reloj_manual(100)
	assert_bool(_vista.intentar_cancelar()).is_true()
	assert_that(_tomados.size()).is_equal(1)
	assert_that(_audios.size()).is_equal(audios_tras_commit)
	_vista.avanzar_reloj_manual(200)
	_vista.intentar_commit()
	assert_that(_tomados.size()).is_equal(1)


# ─── DEC-04 — cancel no-op + accept en neutro no-op ───────────────────────────

func test_cancel_es_noop_con_error_sordo() -> void:
	_vista.configure(_snapshot_valido())
	assert_bool(_vista.intentar_cancelar()).is_true()
	assert_that(_audios.size()).is_equal(1)
	assert_that(_audios[0]).is_equal(&"ui_error_bloqueado")
	assert_bool(_vista.esta_commiteada()).is_false()
	assert_that(_transiciones.size()).is_equal(0)


func test_accept_en_neutro_es_noop_sin_commit() -> void:
	_vista.configure(_snapshot_valido())
	assert_bool(_vista.intentar_commit()).is_true()
	assert_that(_tomados.size()).is_equal(0)
	assert_that(_dejados.size()).is_equal(0)
	assert_bool(_vista.esta_commiteada()).is_false()
	assert_that(_audios.size()).is_equal(1)


# ─── DEC-12 — validación bloqueante ───────────────────────────────────────────

func test_validacion_bloqueante_rechaza_ledger_roto() -> void:
	var nan_g := _snapshot_valido()
	nan_g["gracia_actual"] = 0.0 / 0.0
	var ausente := _snapshot_valido()
	ausente.erase("coro_idx")
	var mismatch := _snapshot_valido()
	mismatch["decision_absorber"] = [1, 0]
	var n_grande := _snapshot_valido()
	n_grande["angeles_absorbidos"] = 4
	n_grande["decision_absorber"] = [1, 1, 1, 1]
	var poso_malo := _snapshot_valido()
	poso_malo["poso_irreversible"] = 8.0
	var invariante := _snapshot_valido()
	invariante["poso_irreversible"] = 24.0
	invariante["corrupcion_actual"] = 20.0
	var coro_malo := _snapshot_valido()
	coro_malo["coro_idx"] = -1
	var casos: Array = [
		[nan_g, &"no_finito"],
		[ausente, &"ausente"],
		[mismatch, &"n_mismatch"],
		[n_grande, &"n_fuera_de_rango"],
		[poso_malo, &"fuera_de_rango"],
		[invariante, &"invariante_rota"],
		[coro_malo, &"coro_invalido"],
	]
	for caso: Array in casos:
		assert_bool(_vista.configure(caso[0])).is_false()
		assert_that(_vista.motivo_invalido()).is_equal(caso[1])
		_vista.intentar_agarrar_foco(-1)
		_vista.intentar_commit()
		assert_that(_tomados.size()).is_equal(0)
		assert_that(_dejados.size()).is_equal(0)
	assert_that(_invalidos.size()).is_equal(casos.size())
	assert_bool(_btn_tomar().disabled).is_true()
	assert_bool(_btn_dejar().disabled).is_true()


# ─── DEC-09 — confirm sin commit se ignora ────────────────────────────────────

func test_confirm_sin_commit_previo_se_ignora() -> void:
	_vista.configure(_snapshot_valido())
	assert_bool(_vista.notificar_confirmacion(0, {}, 1)).is_false()
	assert_that(_transiciones.size()).is_equal(0)


# ─── DEC-09 — sustain TOMAR: succión + rosetón → Hub ──────────────────────────

func test_sustain_tomar_succion_roseton_y_transicion() -> void:
	_vista.configure(_snapshot_valido())
	_vista.intentar_agarrar_foco(-1)
	_vista.intentar_commit()
	assert_bool(_vista.notificar_confirmacion(0, {"g": 30.0, "c": 24.0, "poso": 24.0}, 2)).is_true()
	assert_bool((_vista.get_node(R_SUCCION) as CPUParticles2D).emitting).is_true()
	assert_bool((_vista.get_node(R_ASCENSO) as CPUParticles2D).emitting).is_false()
	_vista._process(0.016)
	_vista._process(0.016)
	assert_bool(_vista.intentar_skip()).is_true()
	assert_that(_transiciones.size()).is_equal(1)
	assert_that(_transiciones[0][0]).is_equal(&"Decision")
	assert_that(_transiciones[0][1]).is_equal(&"Hub")
	assert_bool((_vista.get_node(R_ROSETON) as Panel).visible).is_true()
	assert_bool(absf((_vista.get_node(R_ANGEL) as Panel).modulate.a - 0.55) < 0.01).is_true()
	assert_bool((_vista.get_node(R_SUCCION) as CPUParticles2D).emitting).is_false()


# ─── DEC-09 — sustain DEJAR IR: ascenso sin rosetón → Hub ─────────────────────

func test_sustain_dejar_ascenso_sin_roseton_y_transicion() -> void:
	_vista.configure(_snapshot_valido())
	_vista.intentar_agarrar_foco(1)
	_vista.intentar_commit()
	assert_bool(_vista.notificar_confirmacion(1, {"g": 30.0, "c": 14.0, "poso": 12.0}, 1)).is_true()
	assert_bool((_vista.get_node(R_ASCENSO) as CPUParticles2D).emitting).is_true()
	_vista._process(0.016)
	_vista._process(0.016)
	_vista.intentar_skip()
	assert_that(_transiciones.size()).is_equal(1)
	assert_bool((_vista.get_node(R_ROSETON) as Panel).visible).is_false()
	assert_bool(absf((_vista.get_node(R_ANGEL) as Panel).modulate.a - 0.0) < 0.01).is_true()


# ─── DEC-10 — reduced-motion: corte, cero partículas ──────────────────────────

func test_reduced_motion_corte_sin_particulas() -> void:
	_vista.reduced_motion = true
	_vista.configure(_snapshot_valido())
	_vista.intentar_agarrar_foco(-1)
	_vista.intentar_commit()
	assert_bool(_vista.notificar_confirmacion(0, {"g": 30.0, "c": 24.0, "poso": 24.0}, 2)).is_true()
	assert_that(_transiciones.size()).is_equal(1)
	assert_bool((_vista.get_node(R_SUCCION) as CPUParticles2D).emitting).is_false()
	assert_bool((_vista.get_node(R_ASCENSO) as CPUParticles2D).emitting).is_false()
	assert_bool((_vista.get_node(R_ROSETON) as Panel).visible).is_true()


# ─── DEC-14 — assembly sin E/S de disco ───────────────────────────────────────
# Nota: el FileAccess vive en el TEST, jamás en el assembly de pantalla.

func test_fuentes_sin_io_de_disco() -> void:
	for ruta: String in [SRC_VISTA, SRC_PRESENTER]:
		var texto := FileAccess.open(ruta, FileAccess.READ).get_as_text()
		assert_bool(texto.contains("FileAccess")).is_false()
		assert_bool(texto.contains("DirAccess")).is_false()
		assert_bool(texto.contains("ConfigFile")).is_false()


# ─── DEC-01/09/14 — escena: CPU sí, GPU no, sin sistemas ajenos ───────────────

func test_assembly_escena_solo_particulas_cpu_y_sin_sistemas_ajenos() -> void:
	var escena: PackedScene = load(ESCENA)
	var inst := escena.instantiate()
	var cpus: Array = []
	var gpus: Array = []
	var guiones: Array = []
	_caminar(inst, cpus, gpus, guiones)
	inst.free()
	assert_bool(cpus.size() >= 2).is_true()
	assert_that(gpus.size()).is_equal(0)
	for veto: String in ["hud_ne.gd", "hud_s.gd", "postura_blocks.gd", "hud_vignette.gd", "combat_hud.gd"]:
		assert_bool(guiones.has(veto)).is_false()
	assert_bool(guiones.has("gracia_shards.gd")).is_true()
	assert_bool(guiones.has("decision_gracia.gd")).is_true()


# ─── DEC-18 — todo texto por claves MENU_DECISION_* ───────────────────────────

func test_textos_solo_por_claves() -> void:
	var claves: Array = _vista.claves_texto()
	assert_that(claves.size()).is_equal(10)
	for clave: StringName in claves:
		assert_bool(String(clave).begins_with("MENU_DECISION_")).is_true()
	_vista.configure(_snapshot_valido())
	var textos: Array = []
	_recoger_textos(_vista, textos)
	assert_bool(textos.size() > 0).is_true()
	for texto: String in textos:
		assert_bool(texto.begins_with("MENU_DECISION_")).is_true()
	# La .tscn no fija ningún texto: todo se asigna vía tr() en código.
	var tscn := FileAccess.open(ESCENA, FileAccess.READ).get_as_text()
	assert_that(_contar(tscn, "text = \"")).is_equal(_contar(tscn, "text = \"\""))


# ─── Presentador: abre, reenvía, cierra ───────────────────────────────────────

func test_presenter_abre_reenvia_y_cierra() -> void:
	var hud_escena: PackedScene = load("res://src/ui/CombatHud.tscn")
	var hud = auto_free(hud_escena.instantiate())
	add_child(hud)
	var presentador = auto_free(PresenterScript.new(_vista))
	# Inyección del HUD (DI opcional): sin esto `abrir()` no tiene qué ocultar.
	presentador.set_hud(hud)
	var reenviados: Array = []
	var chegadas: Array = []
	presentador.commit_tomar.connect(func(p: Dictionary) -> void: reenviados.append(p))
	presentador.transicion_solicitada.connect(func(o: StringName, d: StringName) -> void: chegadas.append([o, d]))
	assert_bool(presentador.abrir(_snapshot_valido())).is_true()
	assert_bool(hud.visible).is_false()
	_vista.intentar_agarrar_foco(-1)
	_vista.intentar_commit()
	assert_that(reenviados.size()).is_equal(1)
	assert_bool(presentador.al_confirmar(0, {"g": 30.0, "c": 24.0, "poso": 24.0}, 2)).is_true()
	_vista._process(0.016)
	_vista._process(0.016)
	_vista.intentar_skip()
	assert_that(chegadas.size()).is_equal(1)
	presentador.cerrar()
	assert_bool(hud.visible).is_true()


func _caminar(nodo: Node, cpus: Array, gpus: Array, guiones: Array) -> void:
	if nodo is CPUParticles2D:
		cpus.append(nodo)
	if nodo is GPUParticles2D:
		gpus.append(nodo)
	var scr := nodo.get_script() as Script
	if scr != null and String(scr.resource_path) != "":
		guiones.append(String(scr.resource_path).get_file())
	for hijo: Node in nodo.get_children():
		_caminar(hijo, cpus, gpus, guiones)


func _recoger_textos(nodo: Node, textos: Array) -> void:
	if nodo is Label:
		var t := (nodo as Label).text
		if t != "":
			textos.append(t)
	if nodo is Button:
		var b := (nodo as Button).text
		if b != "":
			textos.append(b)
	for hijo: Node in nodo.get_children():
		_recoger_textos(hijo, textos)


func _contar(texto: String, aguja: String) -> int:
	var n := 0
	var desde := 0
	while true:
		var i := texto.find(aguja, desde)
		if i < 0:
			break
		n += 1
		desde = i + aguja.length()
	return n


# ─── Polish Fase 5 — regresión fixes UX/Art ───────────────────────────────────

func test_polish_fixes_sin_tooltip_press_y_foco_liberado() -> void:
	# Arrange
	assert_bool(_vista.configure(_snapshot_valido())).is_true()
	var tomar := _btn_tomar()
	var dejar := _btn_dejar()
	# Act: foco + commit TOMAR
	_vista.intentar_agarrar_foco(-1)
	_vista.intentar_commit()
	# Assert: single-press en press (no release), sin tooltip hover, elipsis,
	# foco GUI liberado post-commit pero foco lógico preservado
	assert_that(tomar.action_mode).is_equal(Button.ACTION_MODE_BUTTON_PRESS)
	assert_that(dejar.action_mode).is_equal(Button.ACTION_MODE_BUTTON_PRESS)
	assert_that(tomar.text_overrun_behavior).is_equal(TextServer.OVERRUN_TRIM_ELLIPSIS)
	assert_that(dejar.text_overrun_behavior).is_equal(TextServer.OVERRUN_TRIM_ELLIPSIS)
	assert_that(tomar.tooltip_text).is_equal("")
	assert_that(dejar.tooltip_text).is_equal("")
	assert_bool(tomar.has_focus()).is_false()
	assert_bool(dejar.has_focus()).is_false()
	assert_that(_vista.foco_actual()).is_equal(0)

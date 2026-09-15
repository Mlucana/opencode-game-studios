# Tests de integración Continuar + SUS lifecycle — M-002 (BLOCKING).
#
# COBERTURA (story-m002 4 ACs + Sprint-2 additions, cada AC ≥1 test + edges):
# AC-a consume: rename(save→validating) < instantiate_run + `validating` borrado
#   en `run_viva_visible` + rehidratación igual-por-comparador (eps 1e-9 excl
#   timestamp/playtime) + edge SUS inválida → descarte → S1 + `MENU_REASON_*` exacto.
# AC-b doble-press <200ms incl. dos dispositivos mismo tick → 2º no-op
#   `SUS_CONSUMED`, `instantiations==1`, botón deshabilitado mismo frame (dedupe
#   por tick; consume la suspensión) + edge segundo Continuar relee disco.
# AC-c Comenzar-con-SUS: firma cancel/soltar/kill mid-firma → sha256 idéntico,
#   sigue S2 (consume veredicto M-004, no reimplementa hold); firma completa →
#   S2→S3 atómico.
# AC-d Hub→menú sin acción (no-bloqueante `SINCRONIZANDO`→S2, P4); sha idéntico
#   al confirmar flush.
# Sprint-2: staged-journal rename<validate<promote<delete; crash-validating ONE
#   recovery sin marcador → S2 (`SUS_RECOVERED`); second strike con marcador →
#   S1 PER intacto; comparador interim `posicion_rng` avanza / `semilla` preserva.
#
# INTEGRACIÓN con RELOJ MANUAL + TICK MANUAL (patrón menu_pausa/muerte/hub):
# determinismo total de swallow 200ms y dedupe por tick. FS-spy en memoria
# (FS real permitido solo en `tests/integration/` — este suite ni lo necesita:
# determinismo). Sin `scene_runner` con escena: el controlador es RefCounted puro
# (superficie pura contra mock M-001a) — el runner no aportaría escena; la
# integración es SaveIo+Run+Firma+comparador. Sin binarios, sin disco, sin hilos.
# LÍMITES DECLARADOS (Out of Scope): interior Run #3 (cuerpo `instantiate_run`,
# timeout/rechazo `run_viva_visible` = stub sin enforce — aquí no-transición) y
# mecánica hold M-004 (aquí solo su veredicto).
extends GdUnitTestSuite


func _nuevo_s2() -> Dictionary:
	# Arrange común: S2 vigente con SUS válida + seams inyectados + reloj manual.
	var save_io := SaveIoSpy.new()
	save_io.set_per_actual(SaveIoSpy.PER_DEFECTO)
	save_io.sembrar_save(SaveIoSpy.snapshot_valida())
	var run := RunGatewayStub.new()
	var ctrl := MenuContinuarController.new(save_io, run)
	ctrl.set_reloj_manual(true, 10000)
	ctrl.fijar_tick(7)
	ctrl.set_estado_inicial(MenuContinuarController.Estado.S2_VIGENTE)
	return {"ctrl": ctrl, "save_io": save_io, "run": run}


# ─── AC-a — orden consume + commit-point ────────────────────────────────────

func test_ac_a_consume_ordena_rename_antes_que_instancia_y_borra_en_viva() -> void:
	# Arrange.
	var f: Dictionary = _nuevo_s2()
	var ctrl: MenuContinuarController = f["ctrl"]
	var save_io: SaveIoSpy = f["save_io"]
	var run: RunGatewayStub = f["run"]
	var iniciados: Array = []
	ctrl.consumo_iniciado.connect(func(uuid: String) -> void: iniciados.append(uuid))
	var audios: Array = []
	ctrl.audio_solicitado.connect(func(c: StringName) -> void: audios.append(c))
	var cambios: Array = []
	ctrl.estado_cambiado.connect(func(e: int) -> void: cambios.append(e))
	var vivas: Array = []
	ctrl.run_viva_confirmada.connect(func(u: String) -> void: vivas.append(u))
	# Act — Continuar arranca el consumo.
	var r: String = ctrl.continuar(0)
	# Assert — consumo arrancó (""), UNA instanciación, rename staged primero y
	# emisión posterior (rename < instantiate_run por construcción + evidencia).
	assert_that(r).is_equal("")
	assert_that(run.instantiations()).is_equal(1)
	assert_that(iniciados.size()).is_equal(1)
	assert_that(save_io.orden()[0]).is_equal("rename_save_a_validating")
	assert_that(ctrl.estado()).is_equal(MenuContinuarController.Estado.S2B_CONSUMIENDO)
	assert_that(ctrl.continuar_habilitado()).is_equal(false)
	assert_that(audios).is_equal([&"ui_confirmar_neutro"])
	assert_that(cambios).is_equal([MenuContinuarController.Estado.S2B_CONSUMIENDO])
	# Assert — transporte verbatim a Run (G7): snapshot instanciado igual a la
	# semilla por comparador + loadout ordenado exacto.
	assert_that(SusComparatorInterim.iguales(run.ultimo_snapshot(), SaveIoSpy.snapshot_valida())).is_equal(true)
	assert_that(run.ultimo_snapshot()["loadout_reliquias_ids"]).is_equal(["REL_01", "REL_02"])
	# Act — Run confirma vida visible (payload C1 pineado).
	var payload: Dictionary = run.emitir_run_viva_visible(1)
	assert_that(ctrl.confirmar_run_viva_visible(payload)).is_equal(true)
	# Assert — commit-point: `save`+`validating` borrados → S3.
	assert_that(save_io.tiene_suspend_save()).is_equal(false)
	assert_that(save_io.tiene_validating()).is_equal(false)
	assert_that(save_io.orden().back()).is_equal("delete_save_y_validating")
	assert_that(ctrl.estado()).is_equal(MenuContinuarController.Estado.S3_EN_RUN)
	assert_that(cambios).is_equal([MenuContinuarController.Estado.S2B_CONSUMIENDO, MenuContinuarController.Estado.S3_EN_RUN])
	assert_that(vivas).is_equal([iniciados[0]])
	assert_that(audios).is_equal([&"ui_confirmar_neutro"])


func test_ac_a_sus_invalida_descarta_a_s1_con_motivo_exacto() -> void:
	# Arrange — tres filas inválidas con su código causal exacto.
	var filas: Array = [
		["SUS_FOREIGN_REF", &"MENU_REASON_OTHER_RUN"],
		["SUS_VERSION_DISCARD", &"MENU_REASON_VERSION_DISCARD"],
		["PROFILE_CORRUPTO", &"MENU_REASON_MEMORY_DAMAGED"],
	]
	for fila: Array in filas:
		var codigo: String = fila[0]
		var clave: StringName = fila[1]
		var f: Dictionary = _nuevo_s2()
		var ctrl: MenuContinuarController = f["ctrl"]
		var save_io: SaveIoSpy = f["save_io"]
		var run: RunGatewayStub = f["run"]
		save_io.forzar_validez(false, codigo)
		var descartadas: Array = []
		ctrl.sus_descartada.connect(func(m: String) -> void: descartadas.append(m))
		var cambios: Array = []
		ctrl.estado_cambiado.connect(func(e: int) -> void: cambios.append(e))
		# Act — Continuar con SUS inválida al pulsar.
		var r: String = ctrl.continuar(0)
		# Assert — descarte sin resurrección → S1 + código exacto + clave exacta,
		# cero instanciaciones, `validating` borrado.
		assert_that(r).is_equal(codigo)
		assert_that(ctrl.estado()).is_equal(MenuContinuarController.Estado.S1_SIN_RUN)
		assert_that(ctrl.ultimo_motivo()).is_equal(codigo)
		assert_that(ctrl.clave_menu_para(codigo)).is_equal(clave)
		assert_that(descartadas).is_equal([codigo])
		assert_that(cambios).is_equal([MenuContinuarController.Estado.S1_SIN_RUN])
		assert_that(run.instantiations()).is_equal(0)
		assert_that(save_io.tiene_validating()).is_equal(false)
		assert_that(save_io.writes_profile()).is_equal(0)


func test_ac_a_rehidratacion_igual_por_comparador_excluye_tiempo() -> void:
	# Arrange — snapshot original vs rehidratada con tiempo distinto + eps.
	var original: Dictionary = SaveIoSpy.snapshot_valida()
	var rehidratada: Dictionary = (original as Dictionary).duplicate(true)
	rehidratada["timestamp"] = "BASURA-IGNORADA"
	rehidratada["playtime_acumulado"] = 9999.9
	rehidratada["gracia_actual"] = float(original["gracia_actual"]) + 0.0000000005
	# Act + Assert — iguales (eps + exclusiones R9).
	assert_that(SusComparatorInterim.iguales(rehidratada, original)).is_equal(true)
	# Act — `posicion_rng` avanza (válido), `semilla` cambia (inválido).
	var avanza: Dictionary = (original as Dictionary).duplicate(true)
	avanza["posicion_rng"] = int(original["posicion_rng"]) + 3
	assert_that(SusComparatorInterim.iguales(avanza, original)).is_equal(true)
	var reroll: Dictionary = (original as Dictionary).duplicate(true)
	reroll["semilla_rng"] = 111
	assert_that(SusComparatorInterim.iguales(reroll, original)).is_equal(false)
	# Act — `extras_run{unknown:1}` round-trip (R11 verbatim).
	var extra: Dictionary = (original as Dictionary).duplicate(true)
	extra["extras_run"] = {"unknown": 1}
	var extra2: Dictionary = (extra as Dictionary).duplicate(true)
	assert_that(SusComparatorInterim.iguales(extra2, extra)).is_equal(true)


# ─── AC-b — doble-press + dedupe por tick ───────────────────────────────────

func test_ac_b_doble_press_menor_200ms_segundo_noop_boton_mismo_frame() -> void:
	# Arrange.
	var f: Dictionary = _nuevo_s2()
	var ctrl: MenuContinuarController = f["ctrl"]
	var run: RunGatewayStub = f["run"]
	var noops: Array = []
	ctrl.continuar_noop.connect(func(m: String) -> void: noops.append(m))
	var audios: Array = []
	ctrl.audio_solicitado.connect(func(c: StringName) -> void: audios.append(c))
	# Act — 1er press consume (botón deshabilitado MISMO frame, antes de IO).
	assert_that(ctrl.continuar(0)).is_equal("")
	assert_that(ctrl.continuar_habilitado()).is_equal(false)
	# Act — 2º press <200ms (mismo reloj manual, sin avanzar).
	var r2: String = ctrl.continuar(0)
	# Assert — no-op `SUS_CONSUMED`, UNA sola run, botón sigue deshabilitado.
	assert_that(r2).is_equal("SUS_CONSUMED")
	assert_that(noops).is_equal(["SUS_CONSUMED"])
	assert_that(run.instantiations()).is_equal(1)
	assert_that(ctrl.continuar_habilitado()).is_equal(false)
	assert_that(ctrl.clave_menu_para(r2)).is_equal(&"MENU_REASON_ALREADY_USED")
	# Sin blip en re-press S2b por construcción: el botón se deshabilitó mismo
	# frame (MENU-11, inalcanzable por UI); el blip vive en swallow/tick.
	assert_that(audios).is_equal([&"ui_confirmar_neutro"])


func test_ac_b_dos_dispositivos_mismo_tick_una_instancia() -> void:
	# Arrange — mismo tick lógico, dos dispositivos (mando + teclado/ratón).
	var f: Dictionary = _nuevo_s2()
	var ctrl: MenuContinuarController = f["ctrl"]
	var run: RunGatewayStub = f["run"]
	ctrl.fijar_tick(42)
	# Act — dispositivo 0 consume; dispositivo 1 mismo tick es no-op.
	assert_that(ctrl.continuar(0)).is_equal("")
	assert_that(ctrl.continuar(1)).is_equal("SUS_CONSUMED")
	# Assert — dedupe por tick: UNA instanciación, botón mismo frame.
	assert_that(run.instantiations()).is_equal(1)
	assert_that(ctrl.continuar_habilitado()).is_equal(false)
	# Act — tick siguiente sigue no-op (ya S2b/CONSUMIENDO, suspensión consumida).
	ctrl.fijar_tick(43)
	ctrl.avanzar_reloj_manual(500)
	assert_that(ctrl.continuar(1)).is_equal("SUS_CONSUMED")
	assert_that(run.instantiations()).is_equal(1)


func test_ac_b_segundo_continuar_relee_disco_sus_consumed() -> void:
	# Arrange — consumo completo hasta S3 (suspensión consumida).
	var f: Dictionary = _nuevo_s2()
	var ctrl: MenuContinuarController = f["ctrl"]
	var save_io: SaveIoSpy = f["save_io"]
	var run: RunGatewayStub = f["run"]
	assert_that(ctrl.continuar(0)).is_equal("")
	var payload: Dictionary = run.emitir_run_viva_visible(1)
	assert_that(ctrl.confirmar_run_viva_visible(payload)).is_equal(true)
	# Act — segundo Continuar (mismo tick o posterior) sobre el mismo consumo.
	ctrl.fijar_tick(99)
	ctrl.avanzar_reloj_manual(1000)
	var r: String = ctrl.continuar(0)
	# Assert — no-op `SUS_CONSUMED`, sin segunda instanciación ni resurrección.
	assert_that(r).is_equal("SUS_CONSUMED")
	assert_that(run.instantiations()).is_equal(1)
	assert_that(save_io.tiene_suspend_save()).is_equal(false)
	# Act — relectura fresca: nuevo controlador sobre el mismo disco (save ya
	# consumido) en S2 relee y aborta `SUS_CONSUMED` sin instanciar.
	var ctrl2 := MenuContinuarController.new(save_io, run)
	ctrl2.set_reloj_manual(true, 20000)
	ctrl2.fijar_tick(100)
	ctrl2.set_estado_inicial(MenuContinuarController.Estado.S2_VIGENTE)
	var reads_pre: int = save_io.reads_save()
	assert_that(ctrl2.continuar(0)).is_equal("SUS_CONSUMED")
	assert_that(run.instantiations()).is_equal(1)
	assert_that(save_io.reads_save()).is_equal(reads_pre + 1)


# ─── AC-c — Comenzar-con-SUS consume veredicto M-004 ────────────────────────

func test_ac_c_firma_cancel_soltar_kill_sha_identico_sigue_s2() -> void:
	# Arrange — tres vías de no-firma (cancel/soltar/kill mid-firma).
	for modo: String in ["cancelar", "soltar", "kill"]:
		var f: Dictionary = _nuevo_s2()
		var ctrl: MenuContinuarController = f["ctrl"]
		var save_io: SaveIoSpy = f["save_io"]
		var firma := FirmaHold.new()
		assert_that(firma.abrir({"coro": "C1", "reliquias": "2: A,B", "gracia": 3, "corrupcion": 1, "conservan": "N=1/M=0"})).is_equal(true)
		var sha_antes: String = save_io.sha_snapshot()
		var veredictos: Array = []
		firma.firma_veredicto.connect(func(c: bool) -> void: veredictos.append(c))
		var audios: Array = []
		ctrl.audio_solicitado.connect(func(c: StringName) -> void: audios.append(c))
		var firmadas: Array = []
		ctrl.firma_consumida.connect(func(s: String) -> void: firmadas.append(s))
		# Act — hold a medias + interrupción (M-004 mecánica, aquí solo veredicto).
		firma.pulsar()
		firma.avanzar_ms(400)
		if modo == "soltar":
			firma.soltar()
		else:
			firma.cancelar()
		assert_that(veredictos).is_equal([false])
		var r: String = ctrl.consumir_veredicto_firma(false)
		# Assert — sha256 idéntico, sigue S2, cero borrados, PER intacto.
		assert_that(r).is_equal("S2_INTACTA")
		assert_that(save_io.sha_snapshot()).is_equal(sha_antes)
		assert_that(ctrl.estado()).is_equal(MenuContinuarController.Estado.S2_VIGENTE)
		assert_that(ctrl.continuar_habilitado()).is_equal(true)
		assert_that(save_io.orden().is_empty()).is_equal(true)
		assert_that(save_io.writes_profile()).is_equal(0)
		assert_that(audios).is_equal([&"ui_atras"])
		assert_that(firmadas).is_equal(["S2_INTACTA"])


func test_ac_c_firma_completa_s2_s3_atomico() -> void:
	# Arrange.
	var f: Dictionary = _nuevo_s2()
	var ctrl: MenuContinuarController = f["ctrl"]
	var save_io: SaveIoSpy = f["save_io"]
	var firma := FirmaHold.new()
	assert_that(firma.abrir({"coro": "C1", "reliquias": "2: A,B", "gracia": 3, "corrupcion": 1, "conservan": "N=1/M=0"})).is_equal(true)
	var veredictos: Array = []
	firma.firma_veredicto.connect(func(c: bool) -> void: veredictos.append(c))
	var audios: Array = []
	ctrl.audio_solicitado.connect(func(c: StringName) -> void: audios.append(c))
	var firmadas: Array = []
	ctrl.firma_consumida.connect(func(s: String) -> void: firmadas.append(s))
	var cambios: Array = []
	ctrl.estado_cambiado.connect(func(e: int) -> void: cambios.append(e))
	# Act — hold completo → veredicto M-004 `true` → consumo atómico.
	firma.pulsar()
	firma.avanzar_ms(1000)
	assert_that(veredictos).is_equal([true])
	var r: String = ctrl.consumir_veredicto_firma(true)
	# Assert — S2→S3 atómico, Continuar deshabilitado, SUS borrada vía fachada.
	assert_that(r).is_equal("S2_S3_ATOMICO")
	assert_that(ctrl.estado()).is_equal(MenuContinuarController.Estado.S3_EN_RUN)
	assert_that(ctrl.continuar_habilitado()).is_equal(false)
	assert_that(save_io.tiene_suspend_save()).is_equal(false)
	assert_that(save_io.writes_profile()).is_equal(0)
	assert_that(audios).is_equal([&"ui_cometer_irrevocable"])
	assert_that(firmadas).is_equal(["S2_S3_ATOMICO"])
	assert_that(cambios).is_equal([MenuContinuarController.Estado.S3_EN_RUN])


# ─── AC-d — Hub→menú no-bloqueante ──────────────────────────────────────────

func test_ac_d_hub_a_menu_sin_accion_sha_identico_a_flush() -> void:
	# Arrange.
	var f: Dictionary = _nuevo_s2()
	var ctrl: MenuContinuarController = f["ctrl"]
	var save_io: SaveIoSpy = f["save_io"]
	var sha_antes: String = save_io.sha_snapshot()
	var salidas: Array = []
	var flushes: Array = []
	ctrl.hub_salida_solicitada.connect(func() -> void: salidas.append(1))
	ctrl.hub_flush_confirmado.connect(func() -> void: flushes.append(1))
	# Act — salir no requiere acción: retorna de inmediato (no bloquea).
	var marca: String = ctrl.salir_hub_a_menu()
	assert_that(marca).is_equal("SINCRONIZANDO")
	assert_that(salidas).is_equal([1])
	assert_that(ctrl.es_hub_sincronizando()).is_equal(true)
	# Act — al confirmar flush, sha idéntico (nada borrado en esta vía).
	assert_that(ctrl.confirmar_flush_hub()).is_equal(true)
	assert_that(flushes).is_equal([1])
	assert_that(save_io.sha_snapshot()).is_equal(sha_antes)
	assert_that(ctrl.es_hub_sincronizando()).is_equal(false)
	# Act — confirmar sin solicitud: false sin efectos.
	assert_that(ctrl.confirmar_flush_hub()).is_equal(false)


# ─── Edges Sprint-2 — staged journal + crash-validating ─────────────────────

func test_edge_staged_journal_orden_rename_validate_promote_delete() -> void:
	# Arrange.
	var f: Dictionary = _nuevo_s2()
	var ctrl: MenuContinuarController = f["ctrl"]
	var save_io: SaveIoSpy = f["save_io"]
	var run: RunGatewayStub = f["run"]
	# Act — consumo + viva.
	assert_that(ctrl.continuar(0)).is_equal("")
	assert_that(ctrl.confirmar_run_viva_visible(run.emitir_run_viva_visible(2))).is_equal(true)
	# Assert — orden staged R9 (relativo; el delete cierra en viva).
	var o: Array[String] = save_io.orden()
	assert_that(o.find("rename_save_a_validating") < o.find("validate")).is_equal(true)
	assert_that(o.find("validate") < o.find("promote_validating_a_save")).is_equal(true)
	assert_that(o.find("promote_validating_a_save") < o.find("delete_save_y_validating")).is_equal(true)


func test_edge_crash_validating_un_intento_recupera_a_s2() -> void:
	# Arrange — kill tras el rename sin live confirmado: `validating` residual
	# sin `save` ni marcador (equivale a crash durante (1)–(3) — R9-4).
	var save_io := SaveIoSpy.new()
	save_io.set_per_actual(SaveIoSpy.PER_DEFECTO)
	save_io.sembrar_save(SaveIoSpy.snapshot_valida())
	assert_that(save_io.rename_save_a_validating()).is_equal(true)
	assert_that(save_io.tiene_suspend_save()).is_equal(false)
	assert_that(save_io.tiene_validating()).is_equal(true)
	save_io.reiniciar_espia()
	var run := RunGatewayStub.new()
	var ctrl := MenuContinuarController.new(save_io, run)
	ctrl.set_reloj_manual(true, 10000)
	# Act — arranque sin marcador: UN intento → S2 (consumo fresco posterior).
	var r: String = ctrl.arranque_con_validating_residual()
	# Assert — S2 + motivo `SUS_RECOVERED`, save restaurado, Continuar habilitado.
	assert_that(r).is_equal("SUS_RECOVERED")
	assert_that(ctrl.estado()).is_equal(MenuContinuarController.Estado.S2_VIGENTE)
	assert_that(ctrl.ultimo_motivo()).is_equal("SUS_RECOVERED")
	assert_that(ctrl.clave_menu_para("SUS_RECOVERED")).is_equal(&"MENU_REASON_RECOVERED")
	assert_that(ctrl.continuar_habilitado()).is_equal(true)
	assert_that(save_io.tiene_suspend_save()).is_equal(true)
	# Act — el jugador pulsa Continuar de nuevo: consumo fresco válido.
	ctrl.fijar_tick(3)
	assert_that(ctrl.continuar(0)).is_equal("")
	assert_that(run.instantiations()).is_equal(1)


func test_edge_segundo_strike_borra_a_s1_per_intacto() -> void:
	# Arrange — `validating` residual CON marcador (segundo strike — R9-4).
	var save_io := SaveIoSpy.new()
	save_io.set_per_actual(SaveIoSpy.PER_DEFECTO)
	save_io.sembrar_save(SaveIoSpy.snapshot_valida())
	assert_that(save_io.rename_save_a_validating()).is_equal(true)
	assert_that(save_io.crear_marcador_recovered()).is_equal(true)
	save_io.reiniciar_espia()
	var run := RunGatewayStub.new()
	var ctrl := MenuContinuarController.new(save_io, run)
	ctrl.set_reloj_manual(true, 10000)
	ctrl.set_estado_inicial(MenuContinuarController.Estado.S1_SIN_RUN)
	# Act — arranque con marcador: borrar `validating` + marcador → S1.
	var r: String = ctrl.arranque_con_validating_residual()
	# Assert — S1, sin `validating` ni marcador, PER intacto, nunca rehidratación.
	assert_that(ctrl.estado()).is_equal(MenuContinuarController.Estado.S1_SIN_RUN)
	assert_that(save_io.tiene_validating()).is_equal(false)
	assert_that(save_io.tiene_marcador_recovered()).is_equal(false)
	assert_that(save_io.writes_profile()).is_equal(0)
	assert_that(run.instantiations()).is_equal(0)
	assert_that(r).is_equal("NO_SUSPEND")


func test_edge_hilos_todo_en_llamador_cero_fuera() -> void:
	# Arrange (P3 thread-id spy, patrón AC-R4-02a: sync en menú, sin workers).
	var f: Dictionary = _nuevo_s2()
	var ctrl: MenuContinuarController = f["ctrl"]
	var save_io: SaveIoSpy = f["save_io"]
	var run: RunGatewayStub = f["run"]
	var hilo_llamador: int = OS.get_thread_caller_id()
	# Act — consumo + viva + firma-atómica en otro fixture + flush hub.
	assert_that(ctrl.continuar(0)).is_equal("")
	assert_that(ctrl.confirmar_run_viva_visible(run.emitir_run_viva_visible(0))).is_equal(true)
	# Assert — todo staged en el hilo llamador (cero fuera por construcción).
	assert_that(save_io.hilos_por_op().size()).is_equal(save_io.orden().size())
	for h: int in save_io.hilos_por_op():
		assert_that(h).is_equal(hilo_llamador)


func test_edge_sin_confirmacion_no_hay_transicion_timeout_stub() -> void:
	# Arrange (Out of Scope Run #3: timeout/rechazo = stub sin enforce).
	var f: Dictionary = _nuevo_s2()
	var ctrl: MenuContinuarController = f["ctrl"]
	var save_io: SaveIoSpy = f["save_io"]
	assert_that(ctrl.continuar(0)).is_equal("")
	# Act — payload ajeno / coro no-int / fuera de S2b: false sin efectos.
	assert_that(ctrl.confirmar_run_viva_visible({"run_uuid": "run-OTRA", "coro_idx": 1})).is_equal(false)
	assert_that(ctrl.confirmar_run_viva_visible({"run_uuid": ctrl.run_uuid_en_curso(), "coro_idx": "x"})).is_equal(false)
	# Assert — sigue S2b, `validating`+`save` intactos (promovido, sin borrar).
	assert_that(ctrl.estado()).is_equal(MenuContinuarController.Estado.S2B_CONSUMIENDO)
	assert_that(save_io.tiene_suspend_save()).is_equal(true)
	assert_that(save_io.tiene_validating()).is_equal(true)


# ─── Fixes post-code-review (2026-09-13): G1/G2/G3 ────────────────────────────

func test_g1_veredicto_firma_fuera_de_s2_noop_sin_efectos() -> void:
	# Arrange — tres estados no-S2 con su motivo vigente.
	var f2b: Dictionary = _nuevo_s2()
	var ctrl2b: MenuContinuarController = f2b["ctrl"]
	assert_that(ctrl2b.continuar(0)).is_equal("")
	var firmadas2b: Array = []
	ctrl2b.firma_consumida.connect(func(s: String) -> void: firmadas2b.append(s))
	var orden2b: int = (f2b["save_io"] as SaveIoSpy).orden().size()
	# Act — veredicto en S2b: no-op con motivo vigente, sin efectos.
	assert_that(ctrl2b.consumir_veredicto_firma(true)).is_equal("NO_SUSPEND")
	assert_that(ctrl2b.estado()).is_equal(MenuContinuarController.Estado.S2B_CONSUMIENDO)
	assert_that(firmadas2b).is_equal([])
	assert_that((f2b["save_io"] as SaveIoSpy).orden().size()).is_equal(orden2b)
	# Arrange — S3 vía commit-point.
	var payload: Dictionary = (f2b["run"] as RunGatewayStub).emitir_run_viva_visible(1)
	assert_that(ctrl2b.confirmar_run_viva_visible(payload)).is_equal(true)
	# Act — veredicto en S3: no-op, sin efectos.
	assert_that(ctrl2b.consumir_veredicto_firma(false)).is_equal("NO_SUSPEND")
	assert_that(ctrl2b.estado()).is_equal(MenuContinuarController.Estado.S3_EN_RUN)
	assert_that(firmadas2b).is_equal([])
	# Arrange — S1 con motivo causal.
	var f1: Dictionary = _nuevo_s2()
	var ctrl1: MenuContinuarController = f1["ctrl"]
	ctrl1.set_estado_inicial(MenuContinuarController.Estado.S1_SIN_RUN, "PROFILE_CORRUPTO")
	# Act — veredicto en S1: motivo vigente, sin efectos.
	assert_that(ctrl1.consumir_veredicto_firma(true)).is_equal("PROFILE_CORRUPTO")
	assert_that(ctrl1.estado()).is_equal(MenuContinuarController.Estado.S1_SIN_RUN)


func test_g2_viva_fuera_de_s2b_false_sin_efectos() -> void:
	# Arrange — S2 sin consumo en curso (save+validating sembrados vía staged manual).
	var f: Dictionary = _nuevo_s2()
	var ctrl: MenuContinuarController = f["ctrl"]
	var save_io: SaveIoSpy = f["save_io"]
	var run: RunGatewayStub = f["run"]
	save_io.rename_save_a_validating()
	var vivas: Array = []
	ctrl.run_viva_confirmada.connect(func(u: String) -> void: vivas.append(u))
	var orden: int = save_io.orden().size()
	# Act — confirmar en S2 (no S2b): false sin efectos.
	assert_that(ctrl.confirmar_run_viva_visible({"run_uuid": "run-1", "coro_idx": 1})).is_equal(false)
	assert_that(ctrl.estado()).is_equal(MenuContinuarController.Estado.S2_VIGENTE)
	assert_that(save_io.tiene_suspend_save()).is_equal(false)
	assert_that(save_io.tiene_validating()).is_equal(true)
	assert_that(vivas).is_equal([])
	assert_that(save_io.orden().size()).is_equal(orden)
	assert_that(run.instantiations()).is_equal(0)


func test_g3_set_estado_inicial_mid_s2b_pinea_reset() -> void:
	# Arrange — consumo en curso (S2b, uuid vivo).
	var f: Dictionary = _nuevo_s2()
	var ctrl: MenuContinuarController = f["ctrl"]
	var save_io: SaveIoSpy = f["save_io"]
	assert_that(ctrl.continuar(0)).is_equal("")
	assert_that(ctrl.run_uuid_en_curso() != "").is_equal(true)
	var orden: int = save_io.orden().size()
	# Act — re-seed a mitad de S2b (comportamiento observado pineado;
	# TODO Run #3: prohibir o auditar el re-seed mid-consumo).
	ctrl.set_estado_inicial(MenuContinuarController.Estado.S2_VIGENTE)
	# Assert — reset limpio: S2 habilitado, uuid/snapshot/tick reseteados, sin IO extra.
	assert_that(ctrl.estado()).is_equal(MenuContinuarController.Estado.S2_VIGENTE)
	assert_that(ctrl.continuar_habilitado()).is_equal(true)
	assert_that(ctrl.run_uuid_en_curso()).is_equal("")
	assert_that(ctrl.ultimo_motivo()).is_equal("NO_SUSPEND")
	assert_that(save_io.orden().size()).is_equal(orden)

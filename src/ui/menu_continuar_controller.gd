class_name MenuContinuarController
extends RefCounted

## Orquestador Continuar + SUS lifecycle — M-002 (Presentation, Integration).
##
## Implementa `design/gdd/menu-principal-y-flujo-de-pantallas.md` MENU-02c/11/15,
## Edge doble-pulsación y firma-cancel, R6-INPUT (swallow 200ms), R9 Menú; y
## `design/gdd/guardado-de-progreso.md` R9 staged journal completa: orden
## rename→validar→promover→borrar en `run_viva_visible`; crash-validating UN
## intento con marcador `suspend.recovered`, segundo strike→S1 PER intacto;
## segundo Continuar relee disco→`SUS_CONSUMED`; "todo idéntico" excluye
## timestamp/playtime. Historia
## `production/epics/menu-principal/story-m002-continuar-sus.md` (4 ACs).
##
## CONTRATO DISPLAY-Only (`ui-code.md`): nunca posee ficheros ni los lee; toda
## persistencia vive tras la fachada `SaveIo` inyectada (MENU-08: cero IO directo
## en este assembly — sin `FileAccess`/`DirAccess`/`ConfigFile` en código, solo
## mención en este comentario como oracle). Jamás `change_scene` (el router único
## de M-001a posee las transiciones; aquí solo intenciones + señales). Sin
## singletons: `SaveIo` + `RunGateway` se inyectan (coding-standards: DI).
## Sin `_process`: puramente event-driven. Todo en main thread, sin worker
## threads (ADR-001 gating pausa/threads, patrón AC-R4-02a).
##
## M-004 SE CONSUME, NO SE REIMPLEMENTA: la mecánica hold vive en `firma_hold.gd`
## (M-004 done); aquí solo `consumir_veredicto_firma(confirmada)` — `false`
## (cancel/soltar/kill mid-firma) ≡ cero efectos + S2, `true` ≡ S2→S3 atómico.
##
## C1 FROZEN Run #3 stub (cuerpo Out of Scope, Run #3 sin GDD): `RunGateway`
## expone `instantiate_run(snapshot: Dictionary) -> String` (retorna `run_uuid`,
## solo cuenta `instantiations`) y la confirmación llega por
## `confirmar_run_viva_visible(payload: {run_uuid: String, coro_idx: int})`.
## Timeout y ruta de rechazo (pantalla+motivo keyed; sin confirmación no hay
## transición — GDD Menú §#3 Run) documentados como STUB sin enforce hasta Run #3.
## Orden normativo pineado: rename < validate < promote < instantiate_run <
## delete-en-`run_viva_visible`.
##
## COMPARADOR: nada interim en `src/` (P2) — la igualdad por comparador
## (eps 1e-9, excluye timestamp/playtime; `posicion_rng` avanza, `semilla_run`
## se preserva — AC-R9-03 BLOCKED-note) vive en
## `tests/helpers/sus_comparator_interim.gd` y la asevera el test, no este fichero.
## Este controlador transporta el snapshot verbatim y restaura `posicion_rng`.
##
## Sin manifest (`docs/architecture/control-manifest.md` no existe — N/A en historia).
##
## SEAMS DE TEST: `set_reloj_manual()` + `avanzar_reloj_manual()` + `fijar_tick()`
## vuelven deterministas el swallow 200ms y el dedupe por tick (dos dispositivos
## mismo tick). Producción usa reloj real.
##
## SUPERFICIE PURA contra mock M-001a (M-001a Blocked por ADR arranque/router):
## RefCounted sin escena, testeable sin shell. TODO(M-001a): wiring botón
## deshabilitado mismo frame + foco aparcado vía router (aquí la señal + flag).

## Ventana swallow post-press: todo input consumido (Menú R6-INPUT).
const SWALLOW_MS: int = 200

## Estados Guardado S0–S5 + S2b CONSUMIENDO (proveedor R9: input bloqueado, foco
## aparcado en opción no-destructiva, segundo intento = no-op `SUS_CONSUMED`).
enum Estado { S0_SIN_PERFIL = 0, S1_SIN_RUN = 1, S2_VIGENTE = 2, S2B_CONSUMIENDO = 3, S3_EN_RUN = 4, S4_CORRUPTO = 5, S5_MIGRACION = 6 }

## Códigos Guardado §Fachada (enum estable; literales los posee `/localize`).
const CODIGO_NO_SUSPEND: String = "NO_SUSPEND"
const CODIGO_DUEL_NO_WAIT: String = "DUEL_NO_WAIT"
const CODIGO_PROFILE_CORRUPTO: String = "PROFILE_CORRUPTO"
const CODIGO_PROFILE_ILEGIBLE: String = "PROFILE_ILEGIBLE"
const CODIGO_PROFILE_FUTURO: String = "PROFILE_FUTURO"
const CODIGO_SUS_CONSUMED: String = "SUS_CONSUMED"
const CODIGO_SUS_FOREIGN_REF: String = "SUS_FOREIGN_REF"
const CODIGO_SUS_RECOVERED: String = "SUS_RECOVERED"
const CODIGO_SUS_VERSION_DISCARD: String = "SUS_VERSION_DISCARD"
const CODIGO_SUS_VERSION_OLD: String = "SUS_VERSION_OLD"
const CODIGO_PROFILE_LOCKED: String = "PROFILE_LOCKED"

## Mapeo normativo códigos→claves (GDD Menú §mapeo; P5: sin inventar claves).
const MAPEO_MOTIVO_A_CLAVE: Dictionary = {
	"NO_SUSPEND": &"MENU_REASON_NO_SUSPEND",
	"DUEL_NO_WAIT": &"MENU_REASON_RUN_LOST",
	"PROFILE_CORRUPTO": &"MENU_REASON_MEMORY_DAMAGED",
	"PROFILE_ILEGIBLE": &"MENU_REASON_UNREADABLE",
	"PROFILE_FUTURO": &"MENU_REASON_OLD_VERSION",
	"SUS_CONSUMED": &"MENU_REASON_ALREADY_USED",
	"SUS_FOREIGN_REF": &"MENU_REASON_OTHER_RUN",
	"SUS_RECOVERED": &"MENU_REASON_RECOVERED",
	"SUS_VERSION_DISCARD": &"MENU_REASON_VERSION_DISCARD",
	"SUS_VERSION_OLD": &"MENU_REASON_OLD_VERSION",
	"PROFILE_LOCKED": &"MENU_REASON_IN_USE",
}

## Marca Hub→menú no-bloqueante (P4): transición procede, `MenuPrincipal`
## muestra `SINCRONIZANDO`→S2 al confirmar (push de fachada; distinto del
## `CONSUMIENDO` de Guardado, reservado a la vía de consumo).
const HUB_SINCRONIZANDO: String = "SINCRONIZANDO"

## Seams SaveIo usados (W1 fail-closed): todo lo que `continuar()` y el arranque
## invocan vía `call()`. Ausente → `continuar()` falla cerrado a `NO_SUSPEND`.
const SAVE_IO_METODOS: Array[String] = ["tiene_suspend_save", "rename_save_a_validating",
	"leer_snapshot_validating", "validar_snapshot", "promover_validating_a_save",
	"borrar_validating", "borrar_save_y_validating", "tiene_validating",
	"tiene_marcador_recovered", "crear_marcador_recovered", "borrar_validating_y_marcador",
	"solicitar_flush_hub", "confirmar_flush_hub"]
## Seams RunGateway usados (W1 fail-closed).
const RUN_METODOS: Array[String] = ["instantiate_run"]

## Continuar arrancó el consumo (S2→S2b): botón ya deshabilitado mismo frame.
signal consumo_iniciado(run_uuid: String)
## Segundo Continuar (o Continuar fuera de S2): no-op con código causal.
signal continuar_noop(motivo_codigo: String)
## SUS inválida al pulsar: descarte sin resurrección → S1 con motivo exacto.
signal sus_descartada(motivo_codigo: String)
## Run confirmó vida visible: commit-point, `save`+`validating` borrados → S3.
signal run_viva_confirmada(run_uuid: String)
## Comenzar-con-SUS: veredicto M-004 consumido (cancel≡intacta / full≡atómico).
signal firma_consumida(resultado: String)
## Hub→menú: salida solicitada (no bloquea) y flush confirmado (sha idéntico).
signal hub_salida_solicitada
signal hub_flush_confirmado
## Estado S0–S5/S2b cambió (el router/foco observa; aquí no se transiciona escena).
signal estado_cambiado(nuevo_estado: int)
## Intención de audio por el bus (timbres propiedad Audio #16). Nunca directo.
signal audio_solicitado(clave: StringName)

var _save_io: Object = null
var _run: Object = null

var _estado: int = Estado.S1_SIN_RUN
var _ultimo_motivo: String = CODIGO_NO_SUSPEND
## Botón Continuar habilitado (vista M-001a lo refleja; se deshabilita MISMO frame
## del primer press — MENU-11 — antes de cualquier IO).
var _continuar_habilitado: bool = false
var _run_uuid_en_curso: String = ""
var _snapshot_en_curso: Dictionary = {}
var _hub_sincronizando: bool = false

var _swallow_hasta_ms: int = 0
## Reloj manual para tests deterministas (producción: siempre reloj real).
var _reloj_manual: bool = false
var _reloj_manual_ms: int = 0
## Tick lógico para dedupe por tick (dos dispositivos mismo tick — MENU-11).
## El test lo fija con `fijar_tick()`; producción lo avanza el caller por frame.
var _tick_actual: int = 0
var _ultimo_tick_consumo: int = -1


## Inyección sin singletons. Ambos opcionales en construcción para tests de
## estado puro; `continuar()` falla cerrado sin ellos (retorna motivo, sin IO).
## Seams ausentes se denuncian aquí (W1) y bloquean `continuar()` fail-closed.
func _init(save_io: Object = null, run_gateway: Object = null) -> void:
	_save_io = save_io
	_run = run_gateway
	if save_io != null:
		for metodo: String in SAVE_IO_METODOS:
			if not save_io.has_method(metodo):
				push_error("MenuContinuarController: SaveIo sin seam '%s'" % metodo)
	if run_gateway != null:
		for metodo: String in RUN_METODOS:
			if not run_gateway.has_method(metodo):
				push_error("MenuContinuarController: RunGateway sin seam '%s'" % metodo)


## Reasigna seams (tests / reconstrucción). No emite (solo `push_error` si falta
## algún seam W1; el bloqueo real lo hace `continuar()` fail-closed).
func set_seams(save_io: Object, run_gateway: Object) -> void:
	_save_io = save_io
	_run = run_gateway
	if save_io != null:
		for metodo: String in SAVE_IO_METODOS:
			if not save_io.has_method(metodo):
				push_error("MenuContinuarController: SaveIo sin seam '%s'" % metodo)
	if run_gateway != null:
		for metodo: String in RUN_METODOS:
			if not run_gateway.has_method(metodo):
				push_error("MenuContinuarController: RunGateway sin seam '%s'" % metodo)


## Estado S inicial del fixture (S2 para Continuar, S1/S0/S4/S5 para vetos).
## S2 habilita el botón; cualquier otro lo deja deshabilitado con su motivo.
## Estado fuera de 0..6 o motivo vacío → `push_error` + return sin mutar (W4).
func set_estado_inicial(estado: int, motivo: String = CODIGO_NO_SUSPEND) -> void:
	if estado < Estado.S0_SIN_PERFIL or estado > Estado.S5_MIGRACION or motivo == "":
		push_error("MenuContinuarController.set_estado_inicial: estado/motivo inválido")
		return
	_estado = estado
	_ultimo_motivo = motivo
	_run_uuid_en_curso = ""
	_snapshot_en_curso = {}
	_hub_sincronizando = false
	_ultimo_tick_consumo = -1
	_swallow_hasta_ms = 0
	_continuar_habilitado = (estado == Estado.S2_VIGENTE)


## Estado actual (S0–S5/S2b). Solo lectura para tests/router.
func estado() -> int:
	return _estado


## Botón Continuar habilitado ahora (deshabilitado mismo frame del 1er press).
## Solo lectura para tests/vista M-001a.
func continuar_habilitado() -> bool:
	return _continuar_habilitado


## Último motivo causal Guardado (enum estable). Solo lectura para tests.
func ultimo_motivo() -> String:
	return _ultimo_motivo


## Clave `MENU_REASON_*` para un código (tabla GDD; desconocido → NO_SUSPEND).
## Solo lectura para vistas/tests.
func clave_menu_para(codigo: String) -> StringName:
	return MAPEO_MOTIVO_A_CLAVE.get(codigo, &"MENU_REASON_NO_SUSPEND")


## Todas las claves de motivo que esta vía puede mostrar (fijas hasta `/localize`).
func claves_texto() -> Array[StringName]:
	return [&"MENU_REASON_NO_SUSPEND", &"MENU_REASON_RUN_LOST",
		&"MENU_REASON_MEMORY_DAMAGED", &"MENU_REASON_OLD_VERSION",
		&"MENU_REASON_ALREADY_USED", &"MENU_REASON_OTHER_RUN",
		&"MENU_REASON_IN_USE", &"MENU_REASON_UNREADABLE",
		&"MENU_REASON_RECOVERED", &"MENU_REASON_VERSION_DISCARD"]


## `true` en S2b (input bloqueado, foco aparcado — proveedor CONSUMIENDO).
## Solo lectura para tests.
func es_consumiendo() -> bool:
	return _estado == Estado.S2B_CONSUMIENDO


## `true` mientras Hub→menú espera flush-confirm (no-bloqueante P4).
## Solo lectura para tests.
func es_hub_sincronizando() -> bool:
	return _hub_sincronizando


## `run_uuid` del consumo en curso ("" fuera de S2b). Solo lectura para tests.
func run_uuid_en_curso() -> String:
	return _run_uuid_en_curso


## Reloj manual determinista (swallow 200ms + dedupe). Producción no lo usa.
## Al activarlo resetea el swallow: aísla casos de swallow heredado real.
func set_reloj_manual(activo: bool, ahora_ms: int = 0) -> void:
	_reloj_manual = activo
	_reloj_manual_ms = ahora_ms
	if activo:
		_swallow_hasta_ms = 0


## Avanza el reloj manual sin pared real (determinismo).
func avanzar_reloj_manual(delta_ms: int) -> void:
	_reloj_manual_ms += delta_ms


## Fija el tick lógico actual (dedupe por tick, dos dispositivos mismo tick).
func fijar_tick(tick: int) -> void:
	_tick_actual = tick


## Continuar (AC-a/AC-b + R9 staged journal). Retorna "" si el consumo arrancó
## (S2→S2b, botón deshabilitado mismo frame); si no, el código causal del no-op
## (`SUS_CONSUMED` para doble-press <200ms incl. dos dispositivos mismo tick).
## Orden pineado: rename(save→validating) < validate < promote < instantiate_run;
## `validating` se borra en `confirmar_run_viva_visible`, nunca aquí. SUS inválida
## → borrar `validating` → S1 + motivo exacto, sin segunda instanciación.
func continuar(origen_dispositivo: int = 0) -> String:
	if _estado != Estado.S2_VIGENTE:
		var motivo_fuera: String = CODIGO_SUS_CONSUMED if _estado == Estado.S2B_CONSUMIENDO or _estado == Estado.S3_EN_RUN else _ultimo_motivo
		_continuar_habilitado = false
		continuar_noop.emit(motivo_fuera)
		return motivo_fuera
	if not _continuar_habilitado:
		continuar_noop.emit(CODIGO_SUS_CONSUMED)
		return CODIGO_SUS_CONSUMED
	if _en_swallow():
		continuar_noop.emit(CODIGO_SUS_CONSUMED)
		audio_solicitado.emit(&"ui_error_bloqueado")
		return CODIGO_SUS_CONSUMED
	if _tick_actual == _ultimo_tick_consumo and _ultimo_tick_consumo >= 0:
		continuar_noop.emit(CODIGO_SUS_CONSUMED)
		audio_solicitado.emit(&"ui_error_bloqueado")
		return CODIGO_SUS_CONSUMED
	if _save_io == null or _run == null:
		_continuar_habilitado = false
		_ultimo_motivo = CODIGO_NO_SUSPEND
		continuar_noop.emit(CODIGO_NO_SUSPEND)
		return CODIGO_NO_SUSPEND
	# Seam ausente → fail-closed a `NO_SUSPEND` ANTES de mutar disable/tick/
	# swallow (W1): sin consumo, sin estado corrupto, reintentable al re-seed.
	if not _seams_listos():
		_ultimo_motivo = CODIGO_NO_SUSPEND
		continuar_noop.emit(CODIGO_NO_SUSPEND)
		return CODIGO_NO_SUSPEND
	# Deshabilitar MISMO frame, antes de cualquier IO (MENU-11): aunque el
	# rename falle, no hay segundo consumo en este tick.
	_continuar_habilitado = false
	_ultimo_tick_consumo = _tick_actual
	_swallow_hasta_ms = _ahora_ms() + SWALLOW_MS
	# Segundo Continuar relee disco tras el rename: sin `suspend.save` → no-op
	# `SUS_CONSUMED`, sin segunda instanciación, sin resucitar.
	# NOTA (W5): S2 con botón muerto tras relectura vacía requiere re-seed del
	# router (livelock UI conocido, no pérdida: aquí nada se borró).
	if not bool(_save_io.call("tiene_suspend_save")):
		_ultimo_motivo = CODIGO_SUS_CONSUMED
		continuar_noop.emit(CODIGO_SUS_CONSUMED)
		audio_solicitado.emit(&"ui_error_bloqueado")
		return CODIGO_SUS_CONSUMED
	_save_io.call("rename_save_a_validating")
	var snapshot: Dictionary = _save_io.call("leer_snapshot_validating")
	var veredicto: Dictionary = _save_io.call("validar_snapshot", snapshot)
	if veredicto.get("valida", false) != true:
		var motivo: String = _motivo_saneado(veredicto.get("motivo", CODIGO_NO_SUSPEND))
		_save_io.call("borrar_validating")
		_estado = Estado.S1_SIN_RUN
		_ultimo_motivo = motivo
		_run_uuid_en_curso = ""
		_snapshot_en_curso = {}
		estado_cambiado.emit(_estado)
		sus_descartada.emit(motivo)
		audio_solicitado.emit(&"ui_error_bloqueado")
		return motivo
	_save_io.call("promover_validating_a_save")
	var run_uuid: String = String(_run.call("instantiate_run", snapshot))
	_run_uuid_en_curso = run_uuid
	_snapshot_en_curso = (snapshot as Dictionary).duplicate(true)
	_estado = Estado.S2B_CONSUMIENDO
	estado_cambiado.emit(_estado)
	consumo_iniciado.emit(run_uuid)
	audio_solicitado.emit(&"ui_confirmar_neutro")
	return ""


## Commit-point R9: la run confirma vida visible (la confirma Run, no este
## sistema). Payload exacto `{run_uuid: String, coro_idx: int}` (C1 frozen).
## Éxito: borra `save`+`validating` → S3, retorna true. Sin confirmación no hay
## transición (timeout/rechazo = stub documentado, Out of Scope Run #3):
## payload ajeno o fuera de S2b → false sin efectos.
func confirmar_run_viva_visible(payload: Dictionary) -> bool:
	if _estado != Estado.S2B_CONSUMIENDO:
		return false
	# Sin SaveIo no hay commit-point que borrar: fail-closed sin mutar (W6).
	if _save_io == null:
		return false
	if String(payload.get("run_uuid", "")) != _run_uuid_en_curso or _run_uuid_en_curso == "":
		return false
	if not (payload.get("coro_idx") is int):
		return false
	_save_io.call("borrar_save_y_validating")
	_estado = Estado.S3_EN_RUN
	_run_uuid_en_curso = ""
	_snapshot_en_curso = {}
	estado_cambiado.emit(_estado)
	run_viva_confirmada.emit(String(payload.get("run_uuid", "")))
	return true


## Arranque con `suspend.validating` residual (R9-4, AC-R9-01e). Sin `validating`:
## "" sin efectos. Sin marcador `suspend.recovered`: crearlo, re-validar,
## promover a `save` → S2 (el jugador pulsa Continuar de nuevo, consumo fresco;
## motivo `SUS_RECOVERED`). Con marcador (segundo strike): borrar `validating` +
## marcador → S1, PER intacto por construcción (este assembly jamás toca PER).
func arranque_con_validating_residual() -> String:
	if _save_io == null:
		return ""
	if not bool(_save_io.call("tiene_validating")):
		# Huérfano: marcador sin `validating` — limpieza idempotente sin efectos
		# de juego (sin cambio de estado/motivo/señales). El backend real debe
		# borrar marcador+`validating` atómico para no dejar este huérfano (W7).
		if bool(_save_io.call("tiene_marcador_recovered")):
			_save_io.call("borrar_validating_y_marcador")
		return ""
	if not bool(_save_io.call("tiene_marcador_recovered")):
		_save_io.call("crear_marcador_recovered")
		var snapshot: Dictionary = _save_io.call("leer_snapshot_validating")
		var veredicto: Dictionary = _save_io.call("validar_snapshot", snapshot)
		if veredicto.get("valida", false) != true:
			_save_io.call("borrar_validating_y_marcador")
			_estado = Estado.S1_SIN_RUN
			_ultimo_motivo = _motivo_saneado(veredicto.get("motivo", CODIGO_NO_SUSPEND))
			_continuar_habilitado = false
			estado_cambiado.emit(_estado)
			sus_descartada.emit(_ultimo_motivo)
			return _ultimo_motivo
		_save_io.call("promover_validating_a_save")
		_estado = Estado.S2_VIGENTE
		_ultimo_motivo = CODIGO_SUS_RECOVERED
		_continuar_habilitado = true
		_ultimo_tick_consumo = -1
		estado_cambiado.emit(_estado)
		return CODIGO_SUS_RECOVERED
	_save_io.call("borrar_validating_y_marcador")
	_estado = Estado.S1_SIN_RUN
	_ultimo_motivo = CODIGO_NO_SUSPEND
	_continuar_habilitado = false
	_run_uuid_en_curso = ""
	_snapshot_en_curso = {}
	estado_cambiado.emit(_estado)
	return CODIGO_NO_SUSPEND


## Comenzar-con-SUS: consume el veredicto M-004 (AC-c/MENU-02c). `false`
## (cancel/soltar/kill mid-firma) ≡ cancelar: cero borrados, sha idéntico, sigue
## S2. `true` (hold completo) ≡ S2→S3 atómico. Fuera de S2: no-op con el motivo
## vigente, sin efectos. La mecánica hold NO vive aquí (owner `firma_hold.gd`).
func consumir_veredicto_firma(confirmada: bool) -> String:
	if _estado != Estado.S2_VIGENTE:
		return _ultimo_motivo
	if not confirmada:
		audio_solicitado.emit(&"ui_atras")
		firma_consumida.emit("S2_INTACTA")
		return "S2_INTACTA"
	# Sin SaveIo no hay SUS que destruir: fail-closed con el motivo vigente (W6).
	if _save_io == null:
		return _ultimo_motivo
	_save_io.call("borrar_save_y_validating")
	_estado = Estado.S3_EN_RUN
	_continuar_habilitado = false
	_ultimo_tick_consumo = _tick_actual
	estado_cambiado.emit(_estado)
	audio_solicitado.emit(&"ui_cometer_irrevocable")
	firma_consumida.emit("S2_S3_ATOMICO")
	return "S2_S3_ATOMICO"


## Salir Hub→menú (AC-d/MENU-15, P4 no-bloqueante). Sin acción requerida: solicita
## flush prioritario y retorna `SINCRONIZANDO` de inmediato (la transición
## procede); `MenuPrincipal` muestra `SINCRONIZANDO`→S2 al confirmar. Sha idéntico
## se asevera en `confirmar_flush_hub()`. Llamadas repetidas: no-op mismas marca.
func salir_hub_a_menu() -> String:
	if _hub_sincronizando:
		return HUB_SINCRONIZANDO
	_hub_sincronizando = true
	if _save_io != null:
		_save_io.call("solicitar_flush_hub")
	hub_salida_solicitada.emit()
	return HUB_SINCRONIZANDO


## Confirmación del flush Hub (push de fachada). Retorna true y emite; el test
## asevera sha idéntico (nada se borra en esta vía, solo flush). Sin solicitud
## previa: false sin efectos.
func confirmar_flush_hub() -> bool:
	if not _hub_sincronizando:
		return false
	if _save_io != null:
		_save_io.call("confirmar_flush_hub")
	_hub_sincronizando = false
	hub_flush_confirmado.emit()
	return true


## Todos los seams usados presentes (W1). Sin `push_error`: el llamador decide.
func _seams_listos() -> bool:
	if _save_io == null or _run == null:
		return false
	for metodo: String in SAVE_IO_METODOS:
		if not _save_io.has_method(metodo):
			return false
	for metodo: String in RUN_METODOS:
		if not _run.has_method(metodo):
			return false
	return true


## Sanea un motivo del backend contra el enum estable (W3): desconocido o no
## String → `NO_SUSPEND` antes de propagar a `_ultimo_motivo`/`sus_descartada`.
func _motivo_saneado(motivo: Variant) -> String:
	if not (motivo is String):
		return CODIGO_NO_SUSPEND
	match String(motivo):
		CODIGO_NO_SUSPEND, CODIGO_DUEL_NO_WAIT, CODIGO_PROFILE_CORRUPTO, \
		CODIGO_PROFILE_ILEGIBLE, CODIGO_PROFILE_FUTURO, CODIGO_SUS_CONSUMED, \
		CODIGO_SUS_FOREIGN_REF, CODIGO_SUS_RECOVERED, CODIGO_SUS_VERSION_DISCARD, \
		CODIGO_SUS_VERSION_OLD, CODIGO_PROFILE_LOCKED:
			return String(motivo)
	return CODIGO_NO_SUSPEND


func _ahora_ms() -> int:
	if _reloj_manual:
		return _reloj_manual_ms
	return Time.get_ticks_msec()


func _en_swallow() -> bool:
	return _ahora_ms() < _swallow_hasta_ms

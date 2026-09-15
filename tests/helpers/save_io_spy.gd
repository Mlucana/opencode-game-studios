class_name SaveIoSpy
extends RefCounted

## Doble SaveIo en memoria + espía observable — solo tests (M-002).
##
## Espeja `menu_settings_store.gd` (fachada inyectable pura + espía): memoria +
## contadores, CERO E/S de disco por construcción (ningún `FileAccess`/
## `DirAccess`/`ConfigFile` en este fichero — el FS real solo está permitido en
## `tests/integration/`, y este doble ni lo usa: determinismo total).
## P3 adjudicado: dict reads/writes + `reiniciar_espia()` + `orden()` staged +
## thread-id spy (patrón AC-R4-02a: todo sync en el hilo llamador, sin workers).
##
## Qué registra. `orden()` solo contiene tokens staged R9 (para aseverar
## `rename < validate < promote < delete` sin ruido de lecturas):
## `rename_save_a_validating`, `validate`, `promote_validating_a_save`,
## `delete_validating`, `delete_save_y_validating`, `delete_validating_y_marcador`,
## `create_recovered`, `flush_hub_solicitado`, `flush_hub_confirmado`.
## `reads/writes` cuentan por fichero (`suspend.save`, `suspend.validating`,
## `suspend.recovered`, `profile.save` siempre 0 — PER intacto por construcción).
## `hilos_por_op()` guarda `OS.get_thread_caller_id()` por token (mismo índice
## que `orden()`): permite aseverar cero escrituras en hilo de gameplay.
##
## Validación simplificada pero fiel (el backend Guardado posee la real):
## `version != actual` → `SUS_VERSION_DISCARD`; `per_checksum_ref != per_actual`
## → `SUS_FOREIGN_REF`; override forzado vía `forzar_validez()` para el resto de
## filas AC-R9-02 (checksum, punto seguro, invariantes de carta). `timestamp` y
## `playtime_acumulado` NUNCA invalidan (se reparan, no descartan — GDD Edge).
##
## Sha test-double (NO el canónico SHA-256 Guardado R6, owner backend): estable
## para aseverar byte-idéntico (`MENU-02c`, `MENU-15`) vía `JSON.stringify`
## ordenado + `sha256_text()` (API Godot pre-cutoff, sin referencia post-4.3).

const SAVE: String = "suspend.save"
const VALIDATING: String = "suspend.validating"
const RECOVERED: String = "suspend.recovered"
const VERSION_ACTUAL: int = 1
const PER_DEFECTO: String = "PER-ACTUAL"

var _tiene_save: bool = false
var _snapshot_save: Dictionary = {}
var _tiene_validating: bool = false
var _snapshot_validating: Dictionary = {}
var _tiene_recovered: bool = false
var _per_actual: String = PER_DEFECTO

var _forzar_validez_activa: bool = false
var _forzar_valida: bool = true
var _forzar_motivo: String = "NO_SUSPEND"

var _orden: Array[String] = []
var _hilos: Array[int] = []
var _reads: Dictionary = {SAVE: 0, VALIDATING: 0, RECOVERED: 0, "profile.save": 0, "settings.save": 0}
var _writes: Dictionary = {SAVE: 0, VALIDATING: 0, RECOVERED: 0, "profile.save": 0, "settings.save": 0}
var _flush_solicitado: bool = false


## Siembra S2 vigente (el test posee el fixture R3). Copia profunda.
func sembrar_save(snapshot: Dictionary) -> void:
	_snapshot_save = (snapshot as Dictionary).duplicate(true)
	_tiene_save = true


## Referencia PER actual contra la que se chequea `per_checksum_ref`.
func set_per_actual(ref: String) -> void:
	_per_actual = ref


## Override para filas inválidas AC-R9-02 (checksum, punto, invariantes).
## Activa: `validar_snapshot()` retorna esto sin mirar el contenido.
## Desactiva con `limpiar_validez_forzada()`.
func forzar_validez(valida: bool, motivo: String) -> void:
	_forzar_validez_activa = true
	_forzar_valida = valida
	_forzar_motivo = motivo


## Limpia el override (vuelve a la validación automática).
func limpiar_validez_forzada() -> void:
	_forzar_validez_activa = false
	_forzar_valida = true


## Relee disco (el segundo Continuar relee tras el rename — R9). No contamina
## `orden()` (las lecturas no son staged); cuenta en `reads[SAVE]`.
func tiene_suspend_save() -> bool:
	_reads[SAVE] = int(_reads[SAVE]) + 1
	return _tiene_save


## Solo lectura para arranque R9-4. Cuenta en `reads[VALIDATING]`.
func tiene_validating() -> bool:
	_reads[VALIDATING] = int(_reads[VALIDATING]) + 1
	return _tiene_validating


## Solo lectura para arranque R9-4. Cuenta en `reads[RECOVERED]`.
func tiene_marcador_recovered() -> bool:
	_reads[RECOVERED] = int(_reads[RECOVERED]) + 1
	return _tiene_recovered


## (0) staged: `suspend.save` → rename a `suspend.validating` (intención durable,
## antes de instanciar nada). Sin `save`: false sin efectos.
func rename_save_a_validating() -> bool:
	if not _tiene_save:
		return false
	_snapshot_validating = _snapshot_save.duplicate(true)
	_tiene_validating = true
	_tiene_save = false
	_writes[VALIDATING] = int(_writes[VALIDATING]) + 1
	_anotar("rename_save_a_validating")
	return true


## Snapshot en `validating` (copia). Cuenta lectura, no contamina `orden()`.
func leer_snapshot_validating() -> Dictionary:
	_reads[VALIDATING] = int(_reads[VALIDATING]) + 1
	return (_snapshot_validating as Dictionary).duplicate(true)


## (1) staged: valida checksum/versión/`per_checksum_ref`/punto/invariantes.
## Retorna `{valida: bool, motivo: String}` (código Guardado §Fachada).
## NOTA (W9): este doble es leniente a propósito (acepta cursor no-entero); el backend real exigirá `is int`.
func validar_snapshot(snapshot: Dictionary) -> Dictionary:
	_anotar("validate")
	if _forzar_validez_activa:
		return {"valida": _forzar_valida, "motivo": _forzar_motivo}
	if (snapshot as Dictionary).is_empty():
		return {"valida": false, "motivo": "NO_SUSPEND"}
	if int((snapshot as Dictionary).get("save_format_version", -1)) != VERSION_ACTUAL:
		return {"valida": false, "motivo": "SUS_VERSION_DISCARD"}
	if int((snapshot as Dictionary).get("version_contenido_run", -1)) != VERSION_ACTUAL:
		return {"valida": false, "motivo": "SUS_VERSION_DISCARD"}
	if String((snapshot as Dictionary).get("per_checksum_ref", "")) != _per_actual:
		return {"valida": false, "motivo": "SUS_FOREIGN_REF"}
	return {"valida": true, "motivo": ""}


## (3) staged válida: promover `validating → suspend.save` + rehidratar.
## Tras promover coexisten `save` y `validating` hasta `run_viva_visible`.
func promover_validating_a_save() -> bool:
	if not _tiene_validating:
		return false
	_snapshot_save = _snapshot_validating.duplicate(true)
	_tiene_save = true
	_writes[SAVE] = int(_writes[SAVE]) + 1
	_anotar("promote_validating_a_save")
	return true


## (2) staged inválida: borrar `validating`, tratar como "sin suspensión".
func borrar_validating() -> bool:
	_tiene_validating = false
	_snapshot_validating = {}
	_writes[VALIDATING] = int(_writes[VALIDATING]) + 1
	_anotar("delete_validating")
	return true


## Commit-point `run_viva_visible` + firma-atómica Comenzar: borra ambos.
func borrar_save_y_validating() -> bool:
	_tiene_save = false
	_snapshot_save = {}
	_tiene_validating = false
	_snapshot_validating = {}
	_writes[SAVE] = int(_writes[SAVE]) + 1
	_writes[VALIDATING] = int(_writes[VALIDATING]) + 1
	_anotar("delete_save_y_validating")
	return true


## R9-4: crear marcador `suspend.recovered` (UN único intento de recuperación).
func crear_marcador_recovered() -> bool:
	_tiene_recovered = true
	_writes[RECOVERED] = int(_writes[RECOVERED]) + 1
	_anotar("create_recovered")
	return true


## R9-4 segundo strike: borrar `validating` + marcador → S1, PER intacto.
func borrar_validating_y_marcador() -> bool:
	_tiene_validating = false
	_snapshot_validating = {}
	_tiene_recovered = false
	_writes[VALIDATING] = int(_writes[VALIDATING]) + 1
	_writes[RECOVERED] = int(_writes[RECOVERED]) + 1
	_anotar("delete_validating_y_marcador")
	return true


## Hub→menú no-bloqueante (P4): solicita flush prioritario (sin bloquear).
func solicitar_flush_hub() -> String:
	_flush_solicitado = true
	_anotar("flush_hub_solicitado")
	return "SINCRONIZANDO"


## Hub→menú: confirma el flush (el test asevera sha idéntico). Sin solicitud: false.
func confirmar_flush_hub() -> bool:
	if not _flush_solicitado:
		return false
	_flush_solicitado = false
	_anotar("flush_hub_confirmado")
	return true


## Sha estable del estado (save si existe, si no validating, si no ""). Solo
## lectura para aseverar byte-idéntico; no contamina `orden()` ni cuenta writes.
func sha_snapshot() -> String:
	var base: Dictionary = _snapshot_save if _tiene_save else _snapshot_validating
	if (base as Dictionary).is_empty() and not _tiene_save and not _tiene_validating:
		return "VACIO".sha256_text()
	return JSON.stringify(base, "", true, true).sha256_text()


## Tokens staged en orden de emisión. Solo lectura para tests.
func orden() -> Array[String]:
	return _orden.duplicate()


## Thread-id por token (mismo índice que `orden()`). Solo lectura para tests.
func hilos_por_op() -> Array[int]:
	return _hilos.duplicate()


## Ops staged ejecutadas en el hilo `hilo_id`. Solo lectura para tests.
func ops_en_hilo(hilo_id: int) -> int:
	var n: int = 0
	for h: int in _hilos:
		if h == hilo_id:
			n += 1
	return n


## Lecturas por fichero. Solo lectura para tests (re-chequeo post-rename).
func reads_save() -> int:
	return int(_reads[SAVE])


## Escrituras a `suspend.save`. Solo lectura para tests.
func writes_save() -> int:
	return int(_writes[SAVE])


## Escrituras a `suspend.validating`. Solo lectura para tests.
func writes_validating() -> int:
	return int(_writes[VALIDATING])


## Siempre 0 por construcción (este doble jamás toca PER). Solo tests.
func writes_profile() -> int:
	return int(_writes["profile.save"])


## Pone a cero orden/hilos/reads/writes + flush (aislamiento entre casos).
## No borra el sembrado (el fixture lo re-siembra cada test vía `sembra_save` o
## vaciado explícito con `vaciar_todo()`).
func reiniciar_espia() -> void:
	_orden.clear()
	_hilos.clear()
	for k: Variant in _reads.keys():
		_reads[k] = 0
	for k: Variant in _writes.keys():
		_writes[k] = 0
	_flush_solicitado = false
	_forzar_validez_activa = false
	_forzar_valida = true


## Vacía save + validating + marcador (fixture S1/S0). No toca contadores.
func vaciar_todo() -> void:
	_tiene_save = false
	_snapshot_save = {}
	_tiene_validating = false
	_snapshot_validating = {}
	_tiene_recovered = false
	_flush_solicitado = false


func _anotar(token: String) -> void:
	_orden.append(token)
	_hilos.append(OS.get_thread_caller_id())


## Fixture S2 válida R3 (18 claves pineadas; `timestamp`/`playtime` cosméticos).
## El test ajusta `per_checksum_ref` vía `set_per_actual()` (aquí PER_DEFECTO).
static func snapshot_valida(per_ref: String = PER_DEFECTO) -> Dictionary:
	return {
		"save_format_version": VERSION_ACTUAL,
		"version_contenido_run": VERSION_ACTUAL,
		"timestamp": "2026-09-13T00:00:00Z",
		"playtime_acumulado": 1234.5,
		"coro_siguiente_idx": 1,
		"representantes_derrotados": ["REP_A"],
		"decision_absorber": [1],
		"representantes_pendientes": ["REP_B", "REP_C"],
		"loadout_reliquias_ids": ["REL_01", "REL_02"],
		"gracia_actual": 30.0,
		"corrupcion_actual": 10.0,
		"poso_irreversible": 12.0,
		"angeles_absorbidos": 1,
		"semilla_rng": 987654321,
		"posicion_rng": 7,
		"punto_seguro_id": "hub",
		"per_checksum_ref": per_ref,
		"extras_run": {},
	}

class_name FirmaHold
extends RefCounted

## Firma hold Tipo-A para acciones destructivas (GDD Menú R4, story M-004).
##
## QUÉ ES. El widget de firma + veredicto de M-004, NADA más: press-and-hold con
## progreso en vivo y consecuencias listadas; soltar = cancelar, nunca commit
## parcial. La ejecución destructiva (borrar PER/SUS, S0, log) es de M-005; el
## consumo atómico del veredicto (S2→S3), de M-002. Este widget NO toca disco,
## NO toca estado de juego y NO construye UI: la superficie modal y el foco son
## de M-001a (bloqueada — este widget es puro a propósito, ver sprint-1).
##
## RELOJ FALSO. Todo el tiempo son ms enteros de un reloj inyectado (`avanzar_ms`),
## nunca pared ni `_process` (Engine Notes de la historia). Determinista y sin
## escena: los tests controlan cada ms, incluido el borde 999/1000/1001.
##
## 5 CAMPOS. `abrir()` exige un dict con EXACTAMENTE 5 entradas (coro, reliquias
## n+ids, gracia, corrupción, llaves/fragmentos conservados). Con otro conteo
## falla cerrado (fail-closed): una firma que lista mal es peor que no firmar.
## El widget nunca interpreta los valores — son opacos, propiedad del menú.
##
## SIN PREEMPT. `abrir()` con firma abierta (p. ej. durante splash) se rechaza y
## cuenta (`aperturas_rechazadas`), sin tocar la sesión en curso. La COLA es de
## la shell M-001a; aquí solo el nunca-preempt.
##
## TEXTOS. Cero strings de usuario aquí: la vista (M-001a) renderiza vía `tr()`
## con las claves `MENU_HOLD_*` que expone `claves_texto()`.
## DECISIÓN ≠ HOLD. El commit de Decisión (Gracia) es single-press por diseño
## (Pilar 4) y NUNCA pasa por aquí — confundirlos viola el carve-out de M-004.

## Hold por defecto y rango permitido (qa pin normativo hasta /quick-design).
const HOLD_DEFECTO_MS: int = 1000
const HOLD_MIN_MS: int = 800
const HOLD_MAX_MS: int = 1500
## Campos exactos que la firma debe listar (AC-a).
const CAMPOS_EXACTOS: int = 5

enum Estado { CERRADA, EN_HOLD, CONFIRMADA }

## Veredicto para M-002/M-005. `confirmada=true` UNA sola vez por firma;
## `false` = cancelación o kill (cero efectos en ambos casos).
signal firma_veredicto(confirmada: bool)

var _estado: Estado = Estado.CERRADA
var _hold_ms: int = HOLD_DEFECTO_MS
var _reloj_ms: int = 0
var _inicio_hold_ms: int = -1
var _pulsado: bool = false
var _veredicto_emitido: bool = false
var _campos: Dictionary = {}
## Aperturas rechazadas por sesión en curso (nunca-preempt observable).
var _aperturas_rechazadas: int = 0


## Crea la firma con su umbral. Fuera de [800,1500] = assert (fail-closed en
## construcción, no en runtime: un umbral ilegal no debe existir).
func _init(hold_ms: int = HOLD_DEFECTO_MS) -> void:
	assert(hold_ms >= HOLD_MIN_MS and hold_ms <= HOLD_MAX_MS,
		"firma_hold_ms fuera de rango [800,1500]")
	_hold_ms = hold_ms


## Abre la firma con sus 5 campos. Síncrona: al retornar ya está abierta
## (AC-c: apertura ≤100ms, foco mismo frame — la vista lo asevera en M-001a
## contra `esta_abierta()` + `tick_apertura()`).
## Retorna false SIN efectos si: ya hay sesión (cuenta rechazo) o los campos
## no son exactamente 5.
func abrir(campos: Dictionary) -> bool:
	if _estado != Estado.CERRADA:
		_aperturas_rechazadas += 1
		return false
	if campos.size() != CAMPOS_EXACTOS:
		return false
	_campos = campos.duplicate()
	_estado = Estado.EN_HOLD
	_inicio_hold_ms = -1
	_pulsado = false
	_veredicto_emitido = false
	return true


## Flanco de press: arranca el hold. Segundo flanco sin soltar = ignorado
## (single-flank edge consume, Engine Notes).
func pulsar() -> void:
	if _estado != Estado.EN_HOLD or _pulsado:
		return
	_pulsado = true
	_inicio_hold_ms = _reloj_ms


## Release antes del umbral = cancelar: cero efectos, cero veredicto parcial.
## Estado resultante CERRADA (la sesión se descarta; reabrir exige `abrir()`).
func soltar() -> void:
	_pulsado = false
	if _estado != Estado.EN_HOLD or _veredicto_emitido:
		return
	_descartar(false)


## Kill externo (cambio de escena, splash que interrumpe): cancela con cero
## efectos aunque el hold estuviera completo pero sin veredicto emitido.
## Tras veredicto emitido es no-op: jamás contradice un `true` ya consumido.
func cancelar() -> void:
	_pulsado = false
	if _estado == Estado.CERRADA or _veredicto_emitido:
		return
	_descartar(false)


## Avanza el reloj falso. Al alcanzar el umbral confirma EXACTAMENTE una vez
## (emite `firma_veredicto(true)`); avances posteriores no re-emiten.
func avanzar_ms(ms: int) -> void:
	assert(ms >= 0, "El reloj falso no retrocede")
	_reloj_ms += ms
	if _estado != Estado.EN_HOLD or not _pulsado or _veredicto_emitido:
		return
	if _reloj_ms - _inicio_hold_ms >= _hold_ms:
		_veredicto_emitido = true
		_estado = Estado.CONFIRMADA
		firma_veredicto.emit(true)


## Progreso en vivo 0..1 para la barra de la vista (M-001a). 0 sin press.
func progreso() -> float:
	if _estado != Estado.EN_HOLD or not _pulsado or _inicio_hold_ms < 0:
		return 0.0
	return clampf(float(_reloj_ms - _inicio_hold_ms) / float(_hold_ms), 0.0, 1.0)


## Estado actual (la vista decide foco/presentación; nunca decide el widget).
func estado() -> Estado:
	return _estado


## Copia de los 5 campos listados (la vista los renderiza vía tr()).
func campos_listados() -> Dictionary:
	return _campos.duplicate()


## Tick (ms falsos) de apertura — la vista M-001a asevera foco mismo frame.
func tick_apertura() -> int:
	return _reloj_ms


## Reloj falso actual (tests + vista).
func reloj_ahora() -> int:
	return _reloj_ms


## Rechazos por sesión en curso. Solo lectura para tests.
func aperturas_rechazadas() -> int:
	return _aperturas_rechazadas


## Claves de localización que la vista debe resolver (fijas hasta /localize).
func claves_texto() -> Array[StringName]:
	return [&"MENU_HOLD_TITLE", &"MENU_HOLD_LIST", &"MENU_HOLD_HINT",
		&"MENU_HOLD_CONFIRMED", &"MENU_HOLD_CANCELLED"]


## Cierre con veredicto negativo: emite UNA vez y deja CERRADA. Cero efectos
## colaterales por construcción — este objeto no referencia ningún store.
func _descartar(confirmada: bool) -> void:
	_estado = Estado.CERRADA
	_campos = {}
	_inicio_hold_ms = -1
	_pulsado = false
	firma_veredicto.emit(confirmada)

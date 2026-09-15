class_name HudPresenter
extends Node

## Puente display-only entre el juego y el HUD (hud.md §Information Architecture).
##
## REGLAS INVIOLABLES (ui-code.md):
## - Nunca posee ni modifica estado de juego: solo LEE los argumentos de las
##   9 señales y los reenvía a `CombatHud`. Jamás llama de vuelta al FSM.
## - Emite eventos (`hud_audio_requested`), no invoca lógica de juego.
## - Las 9 conexiones son NO-diferidas (directas) y de solo lectura, con
##   guarda anti-reentrada (`_aplicando`): un tick a 40Hz no debe reentrar.
##
## CONTRATO DE LAS 9 SEÑALES (el emisor es el juego/FSM, no la UI):
##  1. `vida_changed(actual, maxima)` — inv. #1, en cada cambio.
##  2. `gracia_changed(encendidas, total)` — inv. #5, en cada absorción.
##  3. `postura_changed(actual, maxima)` — inv. #2, parry/ruptura/restauración.
##  4. `vida_jefe_changed(actual, maxima)` — inv. #3, Castigo conectado.
##  5. `timer_castigo_tick(restantes, total)` — inv. #4, continuo en Aturdido.
##  6. `duelo_changed(en_duelo)` — colapsa/muestra NE.
##  7. `fallo_parry()` — inv. #6, evento 5.
##  8. `firma_ve_changed(fase)` — inv. #7, fases `CombatHud.FaseVE`.
##  9. `hud_estado_changed(estado)` — pausa/hub/absorber/cutscene (`CombatHud.EstadoHUD`).
##
## El presentador NO define estas señales: las consume de la fuente vía
## `bind()`. Si la fuente no existe (tests), los `set_*` públicos permiten
## inyección directa sin singletons (coding-standards: DI sobre singletons).

## Evento de audio vía sistema de eventos, nunca directo (ui-code.md).
signal hud_audio_requested(clave_evento: StringName)

const SENALES_ESPERADAS: Array[StringName] = [
	&"vida_changed",
	&"gracia_changed",
	&"postura_changed",
	&"vida_jefe_changed",
	&"timer_castigo_tick",
	&"duelo_changed",
	&"fallo_parry",
	&"firma_ve_changed",
	&"hud_estado_changed",
]

var _hud: CombatHud
var _aplicando: bool = false
var _fuente: Node

## Contador observable de violaciones de la guarda anti-reentrada (ADR-002 §7,
## patrón Feedback D3). Solo lectura para tests: un tick a 40Hz no debe reentrar;
## si lo intenta, el push se descarta y este contador lo delata (C4a/E2 aseveran
## conteos, no solo orden — un duplicado que respete el orden pasaría sin esto).
var _violaciones_guardia: int = 0

## Descartes RUNTIME_DROP de payloads `combo_abortado` corruptos (hud-002 AC-e).
## Clase RUNTIME_DROP del glosario C16: descarte + WARN + contador, nunca
## FAIL_LOAD, nunca skip silencioso. Solo lectura para tests.
var _descartes_corruptos: int = 0


## Inyección del HUD a gobernar. Sin singleton.
func _init(hud: CombatHud = null) -> void:
	_hud = hud


## Reasigna el HUD (tests / reconstrucción de escena).
func set_hud(hud: CombatHud) -> void:
	_hud = hud


## Conecta las 9 señales de la fuente en modo directo (no diferido).
## Solo lectura: los callbacks nunca escriben en la fuente ni reentran.
func bind(fuente: Node) -> void:
	desconectar()
	_fuente = fuente
	_conectar(&"vida_changed", _al_recibir_vida)
	_conectar(&"gracia_changed", _al_recibir_gracia)
	_conectar(&"postura_changed", _al_recibir_postura)
	_conectar(&"vida_jefe_changed", _al_recibir_vida_jefe)
	_conectar(&"timer_castigo_tick", _al_recibir_timer)
	_conectar(&"duelo_changed", _al_recibir_duelo)
	_conectar(&"fallo_parry", _al_recibir_fallo)
	_conectar(&"firma_ve_changed", _al_recibir_firma_ve)
	_conectar(&"hud_estado_changed", _al_recibir_estado)


## Desconecta la fuente actual. Sin efectos si no hay fuente.
func desconectar() -> void:
	if _fuente == null or not is_instance_valid(_fuente):
		_fuente = null
		return
	for metodo in [_al_recibir_vida, _al_recibir_gracia, _al_recibir_postura, _al_recibir_vida_jefe, _al_recibir_timer, _al_recibir_duelo, _al_recibir_fallo, _al_recibir_firma_ve, _al_recibir_estado]:
		if _fuente.is_connected(SENALES_ESPERADAS[_indice_de(metodo)], metodo):
			_fuente.disconnect(SENALES_ESPERADAS[_indice_de(metodo)], metodo)
	_fuente = null


# ─── Entrada directa (también usable por tests sin fuente) ────────────────

## Cada `push_*` es idempotente y sin reentrada: si ya se está aplicando
## un tick, el nuevo se ignora (el latch del HUD retiene el anterior y el
## hold de 2 frames evita perderlo a 40Hz).
func push_vida(actual: float, maxima: float) -> void:
	if not _entrar():
		return
	_hud.set_vida(actual, maxima)
	_salir()


func push_gracia(encendidas: int, total: int) -> void:
	if not _entrar():
		return
	_hud.set_gracia(encendidas, total)
	_salir()


func push_postura(actual: float, maxima: float) -> void:
	if not _entrar():
		return
	_hud.set_postura(actual, maxima)
	_salir()


func push_vida_jefe(actual: float, maxima: float) -> void:
	if not _entrar():
		return
	_hud.set_vida_jefe(actual, maxima)
	_salir()


func push_timer(restantes: int, total: int) -> void:
	if not _entrar():
		return
	_hud.set_timer(restantes, total)
	_salir()


func push_duelo(en_duelo: bool) -> void:
	if not _entrar():
		return
	_hud.set_en_duelo(en_duelo)
	_salir()


func push_fallo() -> void:
	if not _entrar():
		return
	_hud.notificar_fallo()
	hud_audio_requested.emit(&"hud_fallo")
	_salir()


func push_firma_ve(fase: int) -> void:
	if not _entrar():
		return
	_hud.set_firma_ve(fase)
	hud_audio_requested.emit(&"hud_firma_ve")
	_salir()


## Reflejo de gasto de Gracia (story-005, frontera G7): el HUD no decide.
## La legalidad vive en el sistema #5 (en tests, el mock Ledger como fuente
## de verdad); aquí solo se refleja su veredicto con valores dados a mano por
## el emisor (P5: sin cuantización en el mock — los ints los fija el test):
## ACEPTA → mueve el medidor NW existente + click seco por bus; RECHAZO →
## blip de denegación por bus, sin tocar medidor, cap ni cooldown (el HUD no
## los posee; el rechazo es no-buffer por construcción: no hay cola aquí).
## Audio inmediato por bus (ducking owner #16); sin zona ni flash nuevos
## (reusa NW + throb de vetas del cuerpo + click — hud.md Feedback gasto).
func push_gasto(aceptado: bool, encendidas: int, total: int) -> void:
	if not _entrar():
		return
	if aceptado:
		_hud.set_gracia(encendidas, total)
		hud_audio_requested.emit(&"hud_gasto_aceptado")
	else:
		hud_audio_requested.emit(&"hud_gasto_denegado")
	_salir()


func push_estado(estado: int) -> void:
	if not _entrar():
		return
	_hud.set_estado(estado)
	_salir()


## Aborto de combo (B-* `combo_abortado`, ADR-002 §2). Defensa de borde: valida
## `1 ≤ i ≤ N` y `N ∈ 3..5`; lo corrupto se descarta con WARN + contador
## (RUNTIME_DROP, hud-002 AC-e). Lo válido se acepta SIN efecto visual: el HUD
## no consume `i`/`N` (la escalera late=heavier es de Feedback-4/Sonoro-16);
## este push existe para que el descarte sea observable y testeable.
func push_aborto_combo(indice_i: int, longitud_n: int) -> bool:
	if longitud_n < 3 or longitud_n > 5 or indice_i < 1 or indice_i > longitud_n:
		_descartes_corruptos += 1
		push_warning("HudPresenter: combo_abortado corrupto descartado (i=%d, N=%d)" % [indice_i, longitud_n])
		return false
	return true


# ─── Callbacks directos de la fuente (solo lectura) ───────────────────────

func _al_recibir_vida(actual: float, maxima: float) -> void:
	push_vida(actual, maxima)


func _al_recibir_gracia(encendidas: int, total: int) -> void:
	push_gracia(encendidas, total)


func _al_recibir_postura(actual: float, maxima: float) -> void:
	push_postura(actual, maxima)


func _al_recibir_vida_jefe(actual: float, maxima: float) -> void:
	push_vida_jefe(actual, maxima)


func _al_recibir_timer(restantes: int, total: int) -> void:
	push_timer(restantes, total)


func _al_recibir_duelo(en_duelo: bool) -> void:
	push_duelo(en_duelo)


func _al_recibir_fallo() -> void:
	push_fallo()


func _al_recibir_firma_ve(fase: int) -> void:
	push_firma_ve(fase)


func _al_recibir_estado(estado: int) -> void:
	push_estado(estado)


func _entrar() -> bool:
	if _hud == null or not is_instance_valid(_hud):
		return false
	if _aplicando:
		_violaciones_guardia += 1
		return false
	_aplicando = true
	return true


func _salir() -> void:
	_aplicando = false


func _conectar(senal: StringName, metodo: Callable) -> void:
	if _fuente != null and _fuente.has_signal(senal) and not _fuente.is_connected(senal, metodo):
		# Sin CONNECT_DEFERRED: conexión directa (no diferida) por contrato.
		_fuente.connect(senal, metodo)


func _indice_de(metodo: Callable) -> int:
	var orden: Array = [_al_recibir_vida, _al_recibir_gracia, _al_recibir_postura, _al_recibir_vida_jefe, _al_recibir_timer, _al_recibir_duelo, _al_recibir_fallo, _al_recibir_firma_ve, _al_recibir_estado]
	return orden.find(metodo)

class_name DecisionGraciaPresenter
extends Node

## Puente display-only entre el juego y la pantalla Decisión de Gracia.
##
## Espeja `hud_presenter.gd`: nunca posee ni modifica estado de juego, solo
## inyecta el snapshot de lectura en la vista y reenvía sus eventos hacia el
## juego (Gracia #5 → Guardado → router #15). Sin singletons: la vista y el
## HUD se inyectan (coding-standards: DI sobre singletons).
##
## La vista NO define las señales del juego: `al_confirmar()` es el punto de
## entrada de `decision_confirmada` (el emisor es Gracia #5, no la UI).

## Reemisiones 1:1 de la vista hacia el juego (ver `decision_gracia.gd`).
signal commit_tomar(payload: Dictionary)
signal commit_dejar_ir(payload: Dictionary)
signal audio_solicitado(clave: StringName)
signal transicion_solicitada(origen: StringName, destino: StringName)
signal snapshot_invalido(motivo: StringName)

var _vista: DecisionGracia
var _hud: CombatHud
var _hud_oculto_por_decision: bool = false


## Inyección de la vista a gobernar. Sin singleton.
func _init(vista: DecisionGracia = null) -> void:
	_vista = vista


## Reasigna la vista (tests / reconstrucción de escena).
func set_vista(vista: DecisionGracia) -> void:
	desconectar()
	_vista = vista


## HUD de combate a ocultar durante la Decisión (opcional, DI).
## La Decisión es dueña de su propio NW (GraciaShards en alta luminancia);
## el fondo ceremonial opaco taparía el HUD igualmente, así que se oculta
## para no duplicar el vitral ni el readout.
func set_hud(hud: CombatHud) -> void:
	_hud = hud


## Abre la pantalla con el snapshot de lectura. Conecta los eventos de la
## vista en modo directo y oculta el HUD. Retorna lo que diga `configure()`.
func abrir(snapshot: Dictionary) -> bool:
	if _vista == null or not is_instance_valid(_vista):
		return false
	_conectar_vista()
	var ok: bool = _vista.configure(snapshot)
	if ok and _hud != null and is_instance_valid(_hud):
		_hud.set_estado(CombatHud.EstadoHUD.ABSORBER_DECISION)
		_hud.visible = false
		_hud_oculto_por_decision = true
	return ok


## Entrada de `decision_confirmada` (Gracia #5 → UI). Anima el sustain y
## emite la transición a Hub. Retorna false si la vista la rechaza.
func al_confirmar(opcion: int, triple_nuevo: Dictionary, n_nuevo: int) -> bool:
	if _vista == null or not is_instance_valid(_vista):
		return false
	return _vista.notificar_confirmacion(opcion, triple_nuevo, n_nuevo)


## Cierra la pantalla y restaura el HUD. El estado del HUD lo restaura el
## flujo Hub/router (pendiente ADR arranque/router); aquí solo visibilidad.
func cerrar() -> void:
	if _hud != null and is_instance_valid(_hud) and _hud_oculto_por_decision:
		_hud.visible = true
		_hud_oculto_por_decision = false
	desconectar()


## Desconecta la vista actual. Sin efectos si no hay vista.
func desconectar() -> void:
	if _vista == null or not is_instance_valid(_vista):
		_vista = null
		return
	for datos: Array in [
		[&"decision_commit_tomar", _al_commit_tomar],
		[&"decision_commit_dejar_ir", _al_commit_dejar],
		[&"decision_audio_requested", _al_audio],
		[&"transicion_solicitada", _al_transicion],
		[&"snapshot_invalido", _al_invalido],
	]:
		var senal: StringName = datos[0]
		var metodo: Callable = datos[1]
		if _vista.is_connected(senal, metodo):
			_vista.disconnect(senal, metodo)
	_vista = null


## Propaga knobs a la vista (el presentador no guarda estado propio).
func aplicar_knobs(escala: float, opacidad: float, sin_movimiento: bool) -> void:
	if _vista == null or not is_instance_valid(_vista):
		return
	_vista.hud_scale = escala
	_vista.hud_opacity = opacidad
	_vista.reduced_motion = sin_movimiento


func _conectar_vista() -> void:
	desconectar_preservando()
	if _vista == null:
		return
	if not _vista.is_connected(&"decision_commit_tomar", _al_commit_tomar):
		_vista.decision_commit_tomar.connect(_al_commit_tomar)
	if not _vista.is_connected(&"decision_commit_dejar_ir", _al_commit_dejar):
		_vista.decision_commit_dejar_ir.connect(_al_commit_dejar)
	if not _vista.is_connected(&"decision_audio_requested", _al_audio):
		_vista.decision_audio_requested.connect(_al_audio)
	if not _vista.is_connected(&"transicion_solicitada", _al_transicion):
		_vista.transicion_solicitada.connect(_al_transicion)
	if not _vista.is_connected(&"snapshot_invalido", _al_invalido):
		_vista.snapshot_invalido.connect(_al_invalido)


func desconectar_preservando() -> void:
	var guardada := _vista
	desconectar()
	_vista = guardada


func _al_commit_tomar(payload: Dictionary) -> void:
	commit_tomar.emit(payload)


func _al_commit_dejar(payload: Dictionary) -> void:
	commit_dejar_ir.emit(payload)


func _al_audio(clave: StringName) -> void:
	audio_solicitado.emit(clave)


func _al_transicion(origen: StringName, destino: StringName) -> void:
	transicion_solicitada.emit(origen, destino)


func _al_invalido(motivo: StringName) -> void:
	snapshot_invalido.emit(motivo)

class_name MenuPresenter
extends Node

## Puente display-only entre el juego y las superficies M-003 (Pausa/Muerte/Hub).
##
## Espeja `decision_gracia_presenter.gd`: nunca posee ni modifica estado de juego,
## solo gobierna las vistas puras y reenvía sus intenciones hacia el juego
## (Run/Guardado → router #15). Sin singletons: vistas, HUD y store se inyectan
## (coding-standards: DI sobre singletons). Sin `change_scene` por construcción:
## las transiciones las posee el router único de M-001a; aquí solo intenciones.
##
## CABLEADO PAUSA↔HUD: `abrir_pausa()` ordena `set_estado(PAUSA)` al HUD
## (atenuado 40%, S oculto, timer congelado — propiedad del HUD, hud.md) y
## `cerrar_pausa()` restaura COMBATE por corte.
## TODO(M-001a): cableado final `set_pausa_visual` + foco post-splash vía router
## (superficie pura contra mock: la orden existe, el router la hará suya).
##
## Las 5 conexiones de vista son directas (no diferidas) y de solo lectura.
## Sin `_process`: puramente event-driven.

## Reemisiones 1:1 de las vistas hacia el juego (ver `menu_pausa.gd`,
## `menu_muerte.gd`, `menu_hub.gd`). Sin payload: las intenciones no cargan estado.
signal pausa_reanudar
signal pausa_abandonar
signal pausa_ajustes
signal muerte_volver
signal hub_entrar_duelo
## Audio reemitido al bus (timbres propiedad Audio #16). Nunca directo.
signal audio_solicitado(clave: StringName)

var _pausa: MenuPausa
var _muerte: MenuMuerte
var _hub: MenuHub
var _hud: CombatHud
var _store: MenuSettingsStore


## Inyección sin singletons. Todo opcional salvo las vistas al usar cada vía.
func _init(pausa: MenuPausa = null, muerte: MenuMuerte = null, hub: MenuHub = null) -> void:
	_pausa = pausa
	_muerte = muerte
	_hub = hub


## Reasigna las vistas (tests / reconstrucción de escena).
func set_vistas(pausa: MenuPausa, muerte: MenuMuerte, hub: MenuHub) -> void:
	desconectar()
	_pausa = pausa
	_muerte = muerte
	_hub = hub


## HUD de combate a atenuar en Pausa (opcional, DI). La Muerte no toca el HUD:
## la vignette ya muestra tinta total (el router posee la disposición final).
func set_hud(hud: CombatHud) -> void:
	_hud = hud


## Store de ajustes para MENU-14 (opcional, DI). Solo memoria; el flush físico
## vive fuera de duelo y nunca es IO síncrono en pausa (hud.md Dynamic Behaviors).
func set_store(store: MenuSettingsStore) -> void:
	_store = store


## Todo inyectado y conectado. Solo lectura para tests.
func esta_listo() -> bool:
	return _pausa != null and is_instance_valid(_pausa) \
		and _muerte != null and is_instance_valid(_muerte) \
		and _hub != null and is_instance_valid(_hub)


# ─── Pausa (ordena al HUD; TODO M-001a cableado final vía router) ───

## Abre la Pausa duelo-only: overlay + HUD atenuado (orden `set_pausa_visual`).
## TODO(M-001a): el router hará suya esta orden + foco post-splash.
func abrir_pausa() -> void:
	_conectar_vistas()
	if _pausa != null and is_instance_valid(_pausa):
		_pausa.abrir()
	if _hud != null and is_instance_valid(_hud):
		_hud.set_estado(CombatHud.EstadoHUD.PAUSA)


## Cierra por corte: overlay + HUD a COMBATE (S reaparece si Aturdido persistía).
func cerrar_pausa() -> void:
	if _pausa != null and is_instance_valid(_pausa):
		_pausa.cerrar()
	if _hud != null and is_instance_valid(_hud):
		_hud.set_estado(CombatHud.EstadoHUD.COMBATE)


# ─── Muerte (muda; el HUD lo deja intacto — vignette ya en tinta total) ───

## Muestra la muerte muda (ya S1). Sin orden al HUD por diseño (ver cabecera).
func abrir_muerte() -> void:
	_conectar_vistas()
	if _muerte != null and is_instance_valid(_muerte):
		_muerte.abrir()


## Oculta la muerte (la transición a MenuPrincipal la posee el router).
func cerrar_muerte() -> void:
	if _muerte != null and is_instance_valid(_muerte):
		_muerte.cerrar()


# ─── Hub (display del resumen; la SUS la invalidan otros) ───

## Configura las líneas del Hub desde el resumen de lectura. Retorna lo que
## diga `MenuHub.configure()` (true = línea SUS visible).
func configurar_hub(datos: Dictionary) -> bool:
	_conectar_vistas()
	if _hub != null and is_instance_valid(_hub):
		return _hub.configure(datos)
	return false


## Oculta el Hub (la transición la posee el router — TODO M-001a).
func ocultar_hub() -> void:
	if _hub != null and is_instance_valid(_hub):
		_hub.ocultar()


# ─── Ajustes vía store (MENU-14; memoria, sin IO, editable fuera de S4/S5) ───

## Aplica un ajuste al store inyectado. Retorna false sin store o si el store
## lo rechaza (S4/S5 no-editable, clave vacía, valor no JSON-safe). Nunca toca
## disco: el flush físico vive en `persistencia/` fuera de duelo (MENU-08).
func aplicar_ajuste(clave: String, valor: Variant) -> bool:
	if _store == null:
		return false
	return _store.aplicar_ajuste(clave, valor)


## Propaga knobs a las tres vistas (el presentador no guarda estado propio).
## Sin opacidad: fondos de menú opacos por contraste (guarda 4.5:1).
func aplicar_knobs(escala: float, sin_movimiento: bool) -> void:
	if _pausa != null and is_instance_valid(_pausa):
		_pausa.hud_scale = escala
		_pausa.reduced_motion = sin_movimiento
	if _muerte != null and is_instance_valid(_muerte):
		_muerte.hud_scale = escala
		_muerte.reduced_motion = sin_movimiento
	if _hub != null and is_instance_valid(_hub):
		_hub.hud_scale = escala
		_hub.reduced_motion = sin_movimiento


## Desconecta las vistas actuales. Sin efectos si no hay vistas.
## (HUD y store son referencias puras sin señales: basta soltarlas.)
func desconectar() -> void:
	for datos: Array in [
		[_pausa, &"pausa_reanudar", _al_pausa_reanudar],
		[_pausa, &"pausa_abandonar", _al_pausa_abandonar],
		[_pausa, &"pausa_ajustes", _al_pausa_ajustes],
		[_pausa, &"menu_audio_requested", _al_audio],
		[_pausa, &"foco_cambiado", _al_foco],
		[_muerte, &"muerte_volver", _al_muerte_volver],
		[_muerte, &"menu_audio_requested", _al_audio],
		[_hub, &"hub_entrar_duelo", _al_hub_entrar],
		[_hub, &"menu_audio_requested", _al_audio],
	]:
		var vista: Node = datos[0]
		var senal: StringName = datos[1]
		var metodo: Callable = datos[2]
		if vista != null and is_instance_valid(vista) and vista.is_connected(senal, metodo):
			vista.disconnect(senal, metodo)
	_pausa = null
	_muerte = null
	_hub = null


func _conectar_vistas() -> void:
	# Reconexión idempotente en modo directo (sin CONNECT_DEFERRED) por contrato.
	var pares: Array = [
		[_pausa, &"pausa_reanudar", _al_pausa_reanudar],
		[_pausa, &"pausa_abandonar", _al_pausa_abandonar],
		[_pausa, &"pausa_ajustes", _al_pausa_ajustes],
		[_pausa, &"menu_audio_requested", _al_audio],
		[_pausa, &"foco_cambiado", _al_foco],
		[_muerte, &"muerte_volver", _al_muerte_volver],
		[_muerte, &"menu_audio_requested", _al_audio],
		[_hub, &"hub_entrar_duelo", _al_hub_entrar],
		[_hub, &"menu_audio_requested", _al_audio],
	]
	for datos: Array in pares:
		var vista: Node = datos[0]
		var senal: StringName = datos[1]
		var metodo: Callable = datos[2]
		if vista != null and is_instance_valid(vista) and not vista.is_connected(senal, metodo):
			vista.connect(senal, metodo)


## Sin transición propia: las intenciones viajan al juego; el router decide y
## ejecuta `change_scene`. Este hook existe para el futuro lector/pipeline sin
## inventar hoy ninguna transición (foco solo informativo, sin audio).
func _al_foco(_elemento: StringName) -> void:
	pass


func _al_pausa_reanudar() -> void:
	pausa_reanudar.emit()


func _al_pausa_abandonar() -> void:
	pausa_abandonar.emit()


func _al_pausa_ajustes() -> void:
	pausa_ajustes.emit()


func _al_muerte_volver() -> void:
	muerte_volver.emit()


func _al_hub_entrar() -> void:
	hub_entrar_duelo.emit()


func _al_audio(clave: StringName) -> void:
	audio_solicitado.emit(clave)

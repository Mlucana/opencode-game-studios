class_name DecisionGracia
extends CanvasLayer

## Pantalla Decisión de Gracia — díada ceremonial TOMAR / DEJAR IR.
##
## Implementa `design/ux/decision-gracia.md` (normativa §§4–10) con el visual
## de Fase 2 y las notas de engine de Fase 3. Pantalla discreta modal de
## commit obligatorio: NO es HUD (admite centro ocupado, Gracia G4/G5).
##
## CONTRATO DISPLAY-ONLY (ui-code.md): nunca posee ni modifica estado de
## juego. Lee un snapshot vía `configure()`, commitea vía eventos
## (`decision_commit_tomar` / `decision_commit_dejar_ir`) y anima solo al
## recibir `notificar_confirmacion()` del juego. Cero E/S de disco, cero
## reproductores de audio directos (todo por `decision_audio_requested`),
## cero hilos bloqueados.
##
## PROTOCOLO DE COMMIT (§7): foco neutro inicial (ningún `grab_focus` al
## abrir) → primer `ui_left/right` discreto agarra (trampa en díada) →
## `ui_accept` en flanco fresco commitea en single-press SIN hold (carve-out
## justificado a Menú R4, ver §7.3 del spec). Mismo frame: ambos botones
## deshabilitados + swallow 200 ms + evento emitido. `ui_cancel` = no-op +
## error sordo. Segundo input del mismo tick tumbado por guarda de estado.
##
## SNAPSHOT (solo lectura, owned Gracia #5). Claves:
##  `gracia_actual: float`, `corrupcion_actual: float`,
##  `poso_irreversible: float`, `angeles_absorbidos: int`,
##  `decision_absorber: Array[int]` (source of truth, n su checksum),
##  `coro_idx: int`, `poder_desbloqueable: {id, nombre_key}`,
##  opcionales `rtl: bool` (seam /localize), `bonos: {vida, poso, purga}`
##  (override owned #5, precede a las constantes de display),
##  `esquirlas: {encendidas, total}` (mapeo bolsa→rombos owned #5).
##
## SEAMS DE TEST: `set_reloj_manual()` + `avanzar_reloj_manual()` vuelven
## determinista la ventana swallow de 200 ms (producción usa siempre el
## reloj real). `intentar_agarrar_foco/commit/cancelar/skip()` son la
## traducción testeable de los flancos de input.

## Lados de la díada. El orden es visual izq→der (TOMAR primero en LTR).
enum Lado { TOMAR = 0, DEJAR_IR = 1 }

## Commit TOMAR. Payload `{coro_idx, n_previo, triple_previo{g,c,poso}, poder_id}`.
signal decision_commit_tomar(payload: Dictionary)
## Commit DEJAR IR. Payload `{coro_idx, triple_previo{g,c,poso}}`.
signal decision_commit_dejar_ir(payload: Dictionary)
## Intención de audio por el bus (timbres propiedad Audio #16). Nunca directo.
signal decision_audio_requested(clave: StringName)
## Cierre solicitado. Payload `{origen: Decision, destino: Hub}`.
signal transicion_solicitada(origen: StringName, destino: StringName)
## Snapshot inválido: sin commit posible, escala a descarte (sin defaults).
## Motivos: ausente / no_finito / fuera_de_rango / invariante_rota /
## n_mismatch / n_fuera_de_rango / coro_invalido.
signal snapshot_invalido(motivo: StringName)
## El foco agarró o se movió dentro de la díada (hook lector/tests).
signal foco_cambiado(elemento: StringName)

## Paleta Fase 2: fondo tinta + díada gris frío, esquinas a 0, foco sin glow.
## Tricromía Polish (Art): FONDO_ANGEL (#1E1A16) eliminado — el panel ángel
## usa FONDO_TINTA; no existe un cuarto tono de fondo.
const FONDO_TINTA := Color("14110E")
const GRIS_FONDO := Color("2A2E36")
const GRIS_BORDE := Color("8C94A0")
const GRIS_LUZ := Color("C7CDD6")
## Alias de GRIS_MEDIO (#9AA2AF, gracia_shards.gd:17) — no es hex nuevo.
const GRIS_SUAVE := Color("9AA2AF")
const VITRAL_GRACIA := Color("C9B8E8")

## Tallas base Fase 2. Piso aparente 18px con hud_scale 0.9–1.15.
const TALLA_TITULO: int = 36
const TALLA_ETIQUETA: int = 24
const TALLA_DESC: int = 20
const TALLA_SUR: int = 18
const FUENTE_MIN: int = 18

## Ventana swallow post-commit: todo input consumido/inhibido (Gracia GX-07).
const SWALLOW_MS: int = 200
## Duración del sustain ceremonial (skippable; reduced-motion lo colapsa).
const SUSTAIN_SEG: float = 0.9

## Reglas de validación (Gracia §8 / Edge round-trip). Poso v1.0 ∈ {0,12,24,36}.
const N_MAX_V1: int = 3
const EPS_IDENTIDAD: float = 1e-9
const POSO_ESCALONES: Array[float] = [0.0, 12.0, 24.0, 36.0]

## Magnitudes de superficie v1.0 (Gracia §8; +18 Vida de Combate F5 plano).
## SOLO display: la pantalla interpola, jamás recalcula deltas. `bonos` del
## snapshot (owned #5) tiene precedencia; si se retunean, va
## `/propagate-design-change` + revalidar DEC-05/DEC-06/DEC-18 (OQ GX-13/14).
const VIDA_BONUS_DEF: float = 18.0
const POSO_BONUS_DEF: float = 12.0
const PURGA_DEF: float = 6.0

## Knobs de jugador (heredados hud.md). Opacidad SOLO a decorativos para no
## bajar nunca de 4.5:1; escala con compensación de fuente (piso 18px).
@export_range(0.6, 1.0, 0.01) var hud_opacity: float = 1.0:
	set(valor):
		hud_opacity = clampf(valor, 0.6, 1.0)
		_aplicar_opacidad()
@export_range(0.9, 1.15, 0.01) var hud_scale: float = 1.0:
	set(valor):
		hud_scale = clampf(valor, 0.9, 1.15)
		_aplicar_escala()
## Conmutación en runtime (A11y O2): el setter re-aplica + propaga a
## GraciaShards (mismo patrón que hud_nw.gd).
@export var reduced_motion: bool = false:
	set(valor):
		reduced_motion = valor
		_aplicar_reduced_motion()
## Puente lector de pantalla (A11y B1-B3): anuncios por hook, apagados por
## defecto. TODO(TTS): `docs/engine-reference/` NO pinea API TTS a 2026-09-03
## (VERSION.md: cutoff May 2025, gap HIGH 4.5–4.7; ui.md solo documenta
## AccessKit vía Control nodes, sin firma tts_speak). NO inventar llamada a
## DisplayServer hasta que la firma esté pineada; mientras tanto los anuncios
## viajan por `foco_cambiado` / `claves_texto()`, sin crash.
@export var anuncios_lector: bool = false

var _snapshot: Dictionary = {}
var _valida: bool = false
var _motivo_invalido: StringName = &""
var _g: float = 0.0
var _c: float = 0.0
var _poso: float = 0.0
var _n: int = 0
var _coro_idx: int = 0
var _poder_id: StringName = &""
var _poder_nombre_key: StringName = &""
var _es_rtl: bool = false
var _bono_vida: float = VIDA_BONUS_DEF
var _bono_poso: float = POSO_BONUS_DEF
var _purga: float = PURGA_DEF

## -1 neutro (intencional), 0 TOMAR, 1 DEJAR IR.
var _foco: int = -1
var _foco_guardado: int = -1
var _commiteado: bool = false
var _lado_commiteado: int = -1
var _swallow_hasta_ms: int = 0
var _animando: bool = false
var _transicionada: bool = false
var _frame: int = 0
var _skip_bloqueado_hasta: int = -1
var _tween: Tween = null

## Reloj manual para tests deterministas (producción: siempre reloj real).
var _reloj_manual: bool = false
var _reloj_manual_ms: int = 0

var _fuente_base: SystemFont
var _fuente_foco: SystemFont
var _sb_foco: StyleBoxFlat
var _brasas: Array[ColorRect] = []

@onready var _fondo: ColorRect = $Fondo
@onready var _safe: Control = $SafeZone
@onready var _diada: HBoxContainer = $SafeZone/Columna/Diada
@onready var _tomar_col: VBoxContainer = $SafeZone/Columna/Diada/TomarCol
@onready var _dejar_col: VBoxContainer = $SafeZone/Columna/Diada/DejarCol
@onready var _btn_tomar: Button = $SafeZone/Columna/Diada/TomarCol/TomarFila/BtnTomar
@onready var _btn_dejar: Button = $SafeZone/Columna/Diada/DejarCol/DejarFila/BtnDejarIr
@onready var _cuneta_tomar: ColorRect = $SafeZone/Columna/Diada/TomarCol/TomarFila/CunetaTomar
@onready var _cuneta_dejar: ColorRect = $SafeZone/Columna/Diada/DejarCol/DejarFila/CunetaDejar
@onready var _desc_tomar: Label = $SafeZone/Columna/Diada/TomarCol/DescTomar
@onready var _desc_dejar: Label = $SafeZone/Columna/Diada/DejarCol/DescDejar
@onready var _titulo: Label = $SafeZone/Columna/ScreenTitle
@onready var _ledger: Label = $SafeZone/Columna/LedgerMed
@onready var _irreversible: Label = $SafeZone/Columna/Sur/LblIrreversible
@onready var _quit: Label = $SafeZone/Columna/Sur/LblQuit
@onready var _angel: Panel = $SafeZone/Columna/AngelBrasas
@onready var _gracia: GraciaShards = $SafeZone/Columna/NWGracia/GraciaShards
@onready var _fx_succion: CPUParticles2D = $SafeZone/SuccionFX
@onready var _fx_ascenso: CPUParticles2D = $SafeZone/AscensoFX
@onready var _roseton: Panel = $SafeZone/RosetonNuevo


## Cablea estilos gemelos, foco atrapado y señales. Sin `grab_focus` inicial.
func _ready() -> void:
	layer = 20
	follow_viewport_enabled = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_fuente_base = SystemFont.new()
	_fuente_base.font_weight = 600
	_fuente_foco = SystemFont.new()
	_fuente_foco.font_weight = 800
	_sb_foco = _estilo_boton(GRIS_FONDO, GRIS_LUZ, 2)
	_configurar_botones_gemelos()
	_configurar_trampa_foco()
	_aplicar_tallas()
	_aplicar_opacidad()
	_aplicar_reduced_motion()
	_recoger_brasas()
	_btn_tomar.pressed.connect(_al_boton_pulsado.bind(Lado.TOMAR))
	_btn_dejar.pressed.connect(_al_boton_pulsado.bind(Lado.DEJAR_IR))
	Input.joy_connection_changed.connect(_al_mando_cambiado)
	_recolocar_fx()


## Contador de frames para el inhibido de skip (el input que dispara no
## cuenta como skip, Menú R6). Sin sondeo de juego.
func _process(_delta: float) -> void:
	_frame += 1


## Entrada de la pantalla: valida el snapshot y pinta. Retorna false con
## estado inválido bloqueante (sin commit posible) si falla la validación.
func configure(snapshot: Dictionary) -> bool:
	_snapshot = snapshot.duplicate()
	_commiteado = false
	_lado_commiteado = -1
	_animando = false
	_transicionada = false
	_foco = -1
	_motivo_invalido = _validar(_snapshot)
	_valida = _motivo_invalido == &""
	if _valida:
		_extraer_lectura()
		_aplicar_rtl()
		_refrescar_textos()
		_habilitar_diada(true)
		# A11y B1-B3 al abrir: TITLE + ledger + dos opciones sin selección
		# (foco neutro) + QUIT_LINE, una sola vez (hook no-op sin TTS).
		_anunciar_lector("\n".join(PackedStringArray([_titulo.text, _ledger.text, _btn_tomar.text, _btn_dejar.text, _quit.text])))
	else:
		_pintar_estado_invalido()
		snapshot_invalido.emit(_motivo_invalido)
	visible = true
	call_deferred("_recolocar_fx")
	return _valida


## Confirmación del sistema (escucha `decision_confirmada`, no emite).
## Anima el sustain post-commit y emite la transición a Hub. Retorna false
## si no había commit previo, si la opción no coincide o si ya se cerró
## (defensa en profundidad contra doble-commit).
func notificar_confirmacion(opcion: int, _triple_nuevo: Dictionary, _n_nuevo: int) -> bool:
	if not _commiteado or _animando or _transicionada:
		return false
	if opcion != _lado_commiteado or (opcion != Lado.TOMAR and opcion != Lado.DEJAR_IR):
		return false
	_animando = true
	_skip_bloqueado_hasta = _frame + 1
	# A11y B1-B3 al confirmar: lado elegido (el triple nuevo + destino Hub
	# viajan en las señales; hook no-op sin TTS pineado).
	_anunciar_lector(_btn_tomar.text if opcion == Lado.TOMAR else _btn_dejar.text)
	if reduced_motion:
		_aplicar_estado_final()
		_finalizar_transicion()
		return true
	if opcion == Lado.TOMAR:
		_fx_succion.restart()
	else:
		_fx_ascenso.restart()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_ignore_time_scale(true)
	var alfa_final: float = 0.55 if opcion == Lado.TOMAR else 0.0
	_tween.tween_property(_angel, "modulate:a", alfa_final, SUSTAIN_SEG)
	_tween.tween_callback(_finalizar_transicion)
	_tween.bind_node(self)
	return true


## Estado final inmediato (animaciones skippables). Si hay sustain en curso
## lo completa y transiciona; si no, propaga a GraciaShards (contrato skip).
func skip_animations() -> void:
	if _transicionada:
		return
	_gracia.skip_animations()
	if not _animando:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	_fx_succion.emitting = false
	_fx_ascenso.emitting = false
	_aplicar_estado_final()
	_finalizar_transicion()


## Flanco fresco `ui_left` (-1) / `ui_right` (+1): agarra desde neutro y
## mueve dentro de la díada con trampa (jamás escapa). Siempre consume.
func intentar_agarrar_foco(direccion: int) -> bool:
	if _commiteado or _en_swallow() or not _valida or _animando:
		return true
	var objetivo: int
	if _foco < 0:
		objetivo = _indice_desde_neutro(direccion)
	else:
		objetivo = posmod(_foco + direccion, 2)
	_fijar_foco(objetivo, true)
	return true


## Flanco fresco `ui_accept` (o click con flanco fresco): commitea el lado
## enfocado. En neutro o inválido es no-op (sordo). Siempre consume.
func intentar_commit() -> bool:
	if _commiteado or _en_swallow() or _animando:
		return true
	if not _valida or _foco < 0:
		decision_audio_requested.emit(&"ui_error_bloqueado")
		return true
	_commitear(_foco)
	return true


## `ui_cancel`: no-op + error sordo (sin atrás, sin omitir, sin commit).
## Post-commit se consume en silencio (pantalla en salida).
func intentar_cancelar() -> bool:
	if _commiteado or _en_swallow() or _animando:
		return true
	decision_audio_requested.emit(&"ui_error_bloqueado")
	return true


## Flanco discreto durante el sustain: acorta el velo, nunca el commit ni
## la carga a Hub. Fuera de sustain no consume (deja pasar).
func intentar_skip() -> bool:
	if not _animando or _transicionada:
		return false
	if _frame <= _skip_bloqueado_hasta:
		return true
	skip_animations()
	return true


## Reloj manual determinista para tests (swallow 200 ms). Producción no lo usa.
func set_reloj_manual(activo: bool, ahora_ms: int = 0) -> void:
	_reloj_manual = activo
	_reloj_manual_ms = ahora_ms


## Avanza el reloj manual sin pared real (determinismo, DEC-03).
func avanzar_reloj_manual(delta_ms: int) -> void:
	_reloj_manual_ms += delta_ms


## Todas las claves de texto de la pantalla (inventario DEC-18 / back-link #15).
func claves_texto() -> Array[StringName]:
	return [
		&"MENU_DECISION_TITLE",
		&"MENU_DECISION_TOMAR_LABEL",
		&"MENU_DECISION_TOMAR_DESC",
		&"MENU_DECISION_DEJAR_LABEL",
		&"MENU_DECISION_DEJAR_DESC",
		&"MENU_DECISION_LEDGER",
		&"MENU_DECISION_IRREVERSIBLE",
		&"MENU_DECISION_QUIT_LINE",
		&"MENU_DECISION_LEDGER_INVALIDO",
		&"MENU_DECISION_DATO_AUSENTE",
	]


func esta_configurada() -> bool:
	return _valida


func foco_actual() -> int:
	return _foco


func esta_commiteada() -> bool:
	return _commiteado


func lado_commiteado() -> int:
	return _lado_commiteado


func motivo_invalido() -> StringName:
	return _motivo_invalido


func transicion_emitida() -> bool:
	return _transicionada


## Hook de anuncio a lector (A11y B1-B3, puente AT inexistente).
## Try-safe por diseño: con `anuncios_lector` apagado (defecto) o sin backend
## TTS pineado es no-op — la info ya viaja por `foco_cambiado` y
## `claves_texto()`. TODO(TTS): cablear aquí DisplayServer.tts_speak() cuando
## `docs/engine-reference/godot/` pine la firma (ver nota en `anuncios_lector`).
func _anunciar_lector(_texto: String) -> void:
	if not anuncios_lector:
		return
	# Sin backend pineado: no-op intencional (sin crash, sin señales extra).
	pass


func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_echo():
		return
	# Motion continuo/gyro jamás disparan (Menú R6-INPUT): solo flancos
	# discretos de tecla, botón de mando, D-Pad, stick discreto o click.
	# El stick discreto SÍ navega (UX D1, spec §7.1): entra por
	# is_action_pressed(ui_left/right) con la deadzone del InputMap; el held
	# no repite (filtro echo + flanco + guarda de estado). Se descarta solo
	# motion continuo de ratón/táctil.
	if evento is InputEventMouseMotion or evento is InputEventScreenDrag:
		return
	if evento.is_action_pressed(&"ui_left"):
		intentar_agarrar_foco(-1)
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed(&"ui_right"):
		intentar_agarrar_foco(1)
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed(&"ui_focus_next"):
		intentar_agarrar_foco(1)
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed(&"ui_focus_prev"):
		intentar_agarrar_foco(-1)
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed(&"ui_accept"):
		if _animando:
			intentar_skip()
		else:
			intentar_commit()
		get_viewport().set_input_as_handled()
		return
	if evento.is_action_pressed(&"ui_cancel"):
		intentar_cancelar()
		get_viewport().set_input_as_handled()
		return
	# Right-click = no-op definido (ni commit ni audio).
	if evento is InputEventMouseButton:
		var raton := evento as InputEventMouseButton
		if raton.button_index == MOUSE_BUTTON_RIGHT and raton.pressed:
			get_viewport().set_input_as_handled()


func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_SIZE_CHANGED or que == Control.NOTIFICATION_RESIZED:
		_recolocar_fx()
	elif que == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		# Sleep: preserva pantalla + foco, jamás auto-commit.
		_foco_guardado = _foco
	elif que == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_foco = _foco_guardado
		if _foco >= 0 and _valida and not _commiteado:
			_fijar_foco_visual(_foco)


func _al_mando_cambiado(_dispositivo: int, conectado: bool) -> void:
	# Desconexión: foco almacenado + fallback a teclado (automático, las
	# acciones ui_* sirven a ambos). Reconexión: re-grab al almacenado.
	if conectado and _foco >= 0 and _valida and not _commiteado and visible:
		_fijar_foco_visual(_foco)


## Click con flanco fresco: enfoca + commitea en un solo gesto. El handler
## consume e inhibe destino 1 frame + swallow 200 ms (vía _commitear).
func _al_boton_pulsado(lado: int) -> void:
	if _commiteado or _en_swallow() or not _valida or _animando:
		return
	_fijar_foco(lado, false)
	_commitear(lado)


func _commitear(lado: int) -> void:
	_commiteado = true
	_lado_commiteado = lado
	_swallow_hasta_ms = _ahora_ms() + SWALLOW_MS
	# Mismo frame: ambos botones deshabilitados (igualdad hasta el final).
	_habilitar_diada(false)
	if lado == Lado.TOMAR:
		decision_commit_tomar.emit(_payload_tomar())
		decision_audio_requested.emit(&"ui_cometer_irrevocable")
	else:
		decision_commit_dejar_ir.emit(_payload_dejar())
		decision_audio_requested.emit(&"ui_resolucion_sobria")


func _payload_tomar() -> Dictionary:
	return {
		"coro_idx": _coro_idx,
		"n_previo": _n,
		"triple_previo": {"g": _g, "c": _c, "poso": _poso},
		"poder_id": _poder_id,
	}


func _payload_dejar() -> Dictionary:
	return {
		"coro_idx": _coro_idx,
		"triple_previo": {"g": _g, "c": _c, "poso": _poso},
	}


func _aplicar_estado_final() -> void:
	_fx_succion.emitting = false
	_fx_ascenso.emitting = false
	if _lado_commiteado == Lado.TOMAR:
		_angel.modulate.a = 0.55
		_roseton.visible = true
	else:
		_angel.modulate.a = 0.0
		_roseton.visible = false


func _finalizar_transicion() -> void:
	if _transicionada:
		return
	_transicionada = true
	_animando = false
	_fx_succion.emitting = false
	_fx_ascenso.emitting = false
	transicion_solicitada.emit(&"Decision", &"Hub")


func _ahora_ms() -> int:
	if _reloj_manual:
		return _reloj_manual_ms
	return Time.get_ticks_msec()


func _en_swallow() -> bool:
	return _commiteado and _ahora_ms() < _swallow_hasta_ms


func _indice_desde_neutro(direccion: int) -> int:
	# LTR: left→TOMAR, right→DEJAR IR. RTL espeja díada + mapeo (/localize).
	if _es_rtl:
		return Lado.TOMAR if direccion > 0 else Lado.DEJAR_IR
	return Lado.DEJAR_IR if direccion > 0 else Lado.TOMAR


func _fijar_foco(lado: int, anunciar: bool) -> void:
	_foco = lado
	_fijar_foco_visual(lado)
	if anunciar:
		decision_audio_requested.emit(&"ui_foco")
		foco_cambiado.emit(&"TOMAR" if lado == Lado.TOMAR else &"DEJAR_IR")
		# A11y B1-B3 al fijar foco: label + desc + ledger del lado.
		var etiqueta: String = _btn_tomar.text if lado == Lado.TOMAR else _btn_dejar.text
		var detalle: String = _desc_tomar.text if lado == Lado.TOMAR else _desc_dejar.text
		_anunciar_lector("\n".join(PackedStringArray([etiqueta, detalle, _ledger.text])))


func _fijar_foco_visual(lado: int) -> void:
	_cuneta_tomar.visible = lado == Lado.TOMAR
	_cuneta_dejar.visible = lado == Lado.DEJAR_IR
	_btn_tomar.add_theme_font_override(&"font", _fuente_foco if lado == Lado.TOMAR else _fuente_base)
	_btn_dejar.add_theme_font_override(&"font", _fuente_foco if lado == Lado.DEJAR_IR else _fuente_base)
	if lado == Lado.TOMAR and _btn_tomar.visible and not _btn_tomar.disabled:
		_btn_tomar.grab_focus()
	elif lado == Lado.DEJAR_IR and _btn_dejar.visible and not _btn_dejar.disabled:
		_btn_dejar.grab_focus()


func _habilitar_diada(habilitada: bool) -> void:
	_btn_tomar.disabled = not habilitada
	_btn_dejar.disabled = not habilitada
	# Post-commit (UX D5): sin foco GUI sobre botones disabled. El _foco
	# lógico se preserva (puede quedar); cunetas ya se ocultan aquí.
	if not habilitada:
		_btn_tomar.release_focus()
		_btn_dejar.release_focus()
		_cuneta_tomar.visible = false
		_cuneta_dejar.visible = false


# ─── Validación bloqueante (DEC-12; espejo GX-04/GX-05/GR-29) ───

func _validar(s: Dictionary) -> StringName:
	for clave: String in ["gracia_actual", "corrupcion_actual", "poso_irreversible", "angeles_absorbidos", "decision_absorber", "coro_idx", "poder_desbloqueable"]:
		if not s.has(clave):
			return &"ausente"
	if not (_es_num(s["gracia_actual"]) and _es_num(s["corrupcion_actual"]) and _es_num(s["poso_irreversible"])):
		return &"no_finito"
	var g := float(s["gracia_actual"])
	var c := float(s["corrupcion_actual"])
	var poso := float(s["poso_irreversible"])
	if is_nan(g) or is_inf(g) or is_nan(c) or is_inf(c) or is_nan(poso) or is_inf(poso):
		return &"no_finito"
	if g < -EPS_IDENTIDAD or c < -EPS_IDENTIDAD or c > 100.0 + EPS_IDENTIDAD:
		return &"fuera_de_rango"
	if not _es_escalon_poso(poso):
		return &"fuera_de_rango"
	if poso > c + EPS_IDENTIDAD:
		return &"invariante_rota"
	if not (s["angeles_absorbidos"] is int) or s["angeles_absorbidos"] < 0 or s["angeles_absorbidos"] > N_MAX_V1:
		return &"n_fuera_de_rango"
	if not (s["decision_absorber"] is Array):
		return &"n_mismatch"
	var registro: Array = s["decision_absorber"]
	if registro.size() != s["angeles_absorbidos"]:
		return &"n_mismatch"
	for voto: Variant in registro:
		if not (voto is int) or (voto != 0 and voto != 1):
			return &"n_mismatch"
	if not (s["coro_idx"] is int) or s["coro_idx"] < 0:
		return &"coro_invalido"
	if not (s["poder_desbloqueable"] is Dictionary):
		return &"ausente"
	return &""


func _es_num(v: Variant) -> bool:
	return v is float or v is int


func _es_escalon_poso(poso: float) -> bool:
	for escalon: float in POSO_ESCALONES:
		if absf(poso - escalon) <= EPS_IDENTIDAD:
			return true
	return false


func _extraer_lectura() -> void:
	_g = float(_snapshot["gracia_actual"])
	_c = float(_snapshot["corrupcion_actual"])
	_poso = float(_snapshot["poso_irreversible"])
	_n = int(_snapshot["angeles_absorbidos"])
	_coro_idx = int(_snapshot["coro_idx"])
	_es_rtl = bool(_snapshot.get("rtl", false))
	var poder: Dictionary = _snapshot["poder_desbloqueable"]
	_poder_id = StringName(str(poder.get("id", "")))
	_poder_nombre_key = StringName(str(poder.get("nombre_key", "")))
	_bono_vida = VIDA_BONUS_DEF
	_bono_poso = POSO_BONUS_DEF
	_purga = PURGA_DEF
	if _snapshot.get("bonos") is Dictionary:
		var bonos: Dictionary = _snapshot["bonos"]
		_bono_vida = float(bonos.get("vida", VIDA_BONUS_DEF))
		_bono_poso = float(bonos.get("poso", POSO_BONUS_DEF))
		_purga = float(bonos.get("purga", PURGA_DEF))


# ─── Textos: todo vía tr() con placeholders con nombre (DEC-18) ───

func _refrescar_textos() -> void:
	_titulo.text = tr("MENU_DECISION_TITLE")
	_btn_tomar.text = tr("MENU_DECISION_TOMAR_LABEL")
	_btn_dejar.text = tr("MENU_DECISION_DEJAR_LABEL")
	var poder_txt: String = tr(_poder_nombre_key) if _poder_nombre_key != &"" else tr("MENU_DECISION_DATO_AUSENTE")
	_desc_tomar.text = tr("MENU_DECISION_TOMAR_DESC").format({
		"poder": poder_txt, "vida": _num(_bono_vida), "poso": _num(_bono_poso),
	})
	_desc_dejar.text = tr("MENU_DECISION_DEJAR_DESC").format({"purga": _num(_purga)})
	_ledger.text = tr("MENU_DECISION_LEDGER").format({
		"gracia": _num(_g), "corrupcion": _num(_c), "poso": _num(_poso),
	})
	_irreversible.text = tr("MENU_DECISION_IRREVERSIBLE")
	_quit.text = tr("MENU_DECISION_QUIT_LINE")
	# Sin tooltips dependientes (spec §7.1, UX D3; Hover: nada): el nombre
	# accesible viaja por `claves_texto()` / `foco_cambiado`, no por hover.
	_gracia.highlight_decision = true
	var esquirlas: Dictionary = {"encendidas": _n, "total": 4}
	if _snapshot.get("esquirlas") is Dictionary:
		esquirlas = _snapshot["esquirlas"]
	_gracia.set_shards(int(esquirlas.get("encendidas", _n)), int(esquirlas.get("total", 4)))
	_gracia.queue_redraw()


func _pintar_estado_invalido() -> void:
	# Diagnóstico sobrio sin tecnicismos en superficie (el motivo viaja solo
	# por `snapshot_invalido` hacia logs/escalado a descarte).
	_titulo.text = tr("MENU_DECISION_TITLE")
	_btn_tomar.text = tr("MENU_DECISION_TOMAR_LABEL")
	_btn_dejar.text = tr("MENU_DECISION_DEJAR_LABEL")
	_desc_tomar.text = ""
	_desc_dejar.text = ""
	_ledger.text = tr("MENU_DECISION_LEDGER_INVALIDO")
	_irreversible.text = tr("MENU_DECISION_IRREVERSIBLE")
	_quit.text = tr("MENU_DECISION_QUIT_LINE")
	_habilitar_diada(false)


## Normaliza -0.0 → 0 (DEC-11). Crudos, sin recalcular nada.
func _num(v: float) -> String:
	if is_zero_approx(v):
		return "0"
	return str(v)


func _aplicar_rtl() -> void:
	# RTL espeja orden de la díada + mapeo left/right (fija /localize).
	if _es_rtl and _tomar_col.get_index() < _dejar_col.get_index():
		_diada.move_child(_dejar_col, _tomar_col.get_index())
	elif not _es_rtl and _tomar_col.get_index() > _dejar_col.get_index():
		_diada.move_child(_tomar_col, _dejar_col.get_index())


# ─── Estilos Fase 2: gemelos estrictos, foco 2px sin glow, hover = normal ───

func _configurar_botones_gemelos() -> void:
	var normal := _estilo_boton(GRIS_FONDO, GRIS_BORDE, 1)
	for boton: Button in [_btn_tomar, _btn_dejar]:
		boton.add_theme_stylebox_override(&"normal", normal)
		# Dual-focus: hover jamás roba foco de mando ni cambia el botón.
		boton.add_theme_stylebox_override(&"hover", normal)
		boton.add_theme_stylebox_override(&"pressed", _estilo_boton(GRIS_FONDO, GRIS_LUZ, 2))
		boton.add_theme_stylebox_override(&"focus", _sb_foco)
		boton.add_theme_stylebox_override(&"disabled", _estilo_boton(GRIS_FONDO, GRIS_BORDE, 1))
		boton.add_theme_color_override(&"font_color", GRIS_LUZ)
		boton.add_theme_color_override(&"font_focus_color", GRIS_LUZ)
		boton.add_theme_color_override(&"font_hover_color", GRIS_LUZ)
		boton.add_theme_color_override(&"font_pressed_color", GRIS_LUZ)
		boton.add_theme_color_override(&"font_disabled_color", GRIS_SUAVE)
		boton.add_theme_font_override(&"font", _fuente_base)
		# Hover: nada (UX D4) — cursor flecha por defecto, sin mano.
		# Overflow (Art 8a): el truncado con elipsis vive en la .tscn
		# (text_overrun_behavior + clip_text; Button no envuelve por diseño);
		# el shrink para alemán vive en reescritura (DEC-18), nunca en
		# truncado silencioso.
	_angel.add_theme_stylebox_override(&"panel", _estilo_boton(FONDO_TINTA, GRIS_BORDE, 1))
	_roseton.add_theme_stylebox_override(&"panel", _estilo_roseton())
	_roseton.visible = false
	_fondo.color = FONDO_TINTA


func _estilo_boton(fondo: Color, borde: Color, grosor: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fondo
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(grosor)
	sb.border_color = borde
	# Sin glow: solo lo divino emite luz (art-bible 2). Sin sombra tampoco.
	sb.shadow_size = 0
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb


func _estilo_roseton() -> StyleBoxFlat:
	# +1 rosetón de veta permanente (art-bible fila 5): anillo, sin relleno.
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(2)
	sb.border_color = VITRAL_GRACIA
	sb.shadow_size = 0
	return sb


func _configurar_trampa_foco() -> void:
	# Trampa en díada: todo vecino lleva al otro botón (Tab incluido).
	# Neutro inicial: el primer ui_left/right agarra vía input, no por vecinos.
	for par: Array in [[_btn_tomar, _btn_dejar], [_btn_dejar, _btn_tomar]]:
		var a: Button = par[0]
		var b: Button = par[1]
		a.focus_neighbor_left = b.get_path()
		a.focus_neighbor_right = b.get_path()
		a.focus_neighbor_top = a.get_path()
		a.focus_neighbor_bottom = a.get_path()
		a.focus_next = b.get_path()
		a.focus_previous = b.get_path()


func _recoger_brasas() -> void:
	_brasas.clear()
	var fila := $SafeZone/Columna/AngelBrasas/BrasasRow as HBoxContainer
	if fila == null:
		return
	for hijo: Node in fila.get_children():
		if hijo is ColorRect:
			_brasas.append(hijo)


func _aplicar_tallas() -> void:
	if not is_node_ready():
		return
	var s := clampf(hud_scale, 0.9, 1.15)
	# Guarda 18px aparente: compensa a ceil(18/scale) cuando scale < 1.
	var f := func(base: int) -> int: return maxi(base, int(ceil(float(FUENTE_MIN) / s)))
	_titulo.add_theme_font_size_override(&"font_size", f.call(TALLA_TITULO))
	_btn_tomar.add_theme_font_size_override(&"font_size", f.call(TALLA_ETIQUETA))
	_btn_dejar.add_theme_font_size_override(&"font_size", f.call(TALLA_ETIQUETA))
	_desc_tomar.add_theme_font_size_override(&"font_size", f.call(TALLA_DESC))
	_desc_dejar.add_theme_font_size_override(&"font_size", f.call(TALLA_DESC))
	_ledger.add_theme_font_size_override(&"font_size", f.call(TALLA_DESC))
	_irreversible.add_theme_font_size_override(&"font_size", f.call(TALLA_SUR))
	_quit.add_theme_font_size_override(&"font_size", f.call(TALLA_SUR))
	_titulo.add_theme_color_override(&"font_color", GRIS_LUZ)
	_desc_tomar.add_theme_color_override(&"font_color", GRIS_LUZ)
	_desc_dejar.add_theme_color_override(&"font_color", GRIS_LUZ)
	_ledger.add_theme_color_override(&"font_color", GRIS_LUZ)
	_irreversible.add_theme_color_override(&"font_color", GRIS_SUAVE)
	_quit.add_theme_color_override(&"font_color", GRIS_SUAVE)


func _aplicar_escala() -> void:
	if not is_node_ready():
		return
	# CanvasLayer escala desde origen (sin pivote): el no-desborde a 1.15
	# queda PENDIENTE de verificación en Deck real + screenshots (Fase 5).
	scale = Vector2(hud_scale, hud_scale)
	_aplicar_tallas()


func _aplicar_opacidad() -> void:
	# Guarda 4.5:1: la opacidad va SOLO a brasas decorativas. Fondo, botones
	# y textos quedan opacos siempre (un fondo semitransparente sobre un
	# detrás desconocido rompería el contraste medido de Fase 2).
	if not is_node_ready():
		return
	for brasa: ColorRect in _brasas:
		var c: Color = brasa.color
		c.a = clampf(hud_opacity, 0.6, 1.0)
		brasa.color = c


func _aplicar_reduced_motion() -> void:
	if not is_node_ready():
		return
	_gracia.reduced_motion = reduced_motion


func _recolocar_fx() -> void:
	# FX pineados al centro del ángel en brasas (válido a cualquier resolución).
	if not is_node_ready():
		return
	var centro: Vector2 = _angel.get_global_rect().get_center() - _safe.global_position
	_fx_succion.position = centro
	_fx_ascenso.position = centro
	# Offset escalado (Art 8b): el desplazamiento fijo se multiplica por
	# hud_scale para no derivar con la escala.
	_roseton.position = centro + Vector2(96.0, -56.0) * hud_scale

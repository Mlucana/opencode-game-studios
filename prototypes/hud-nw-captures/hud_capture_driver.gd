## Driver de capturas para la evidencia manual de hud-001 (THROWAWAY).
##
## NO es código de producción: vive en prototypes/ y nada de src/ lo referencia.
## Instancia la CombatHud real + HudPresenter y expone teclas que disparan los
## estados de los ACs con auto-captura del viewport a production/qa/evidence/.
## Teclas: 1 = ciclar Vida · 2 = ciclar Gracia · 3 = flash de fallo ·
## 4 = prelight VE on/off · 0 = reset · 5 = captura manual.
extends Node

const HUD_SCENE: PackedScene = preload("res://src/ui/CombatHud.tscn")

const VIDA_VALORES: Array[float] = [100.0, 75.0, 57.0, 25.0]
const GRACIA_TOTAL: int = 4
const EVIDENCE_DIR := "res://production/qa/evidence"

var _hud: CombatHud
var _presenter: HudPresenter
var _idx_vida: int = 0
var _lit_gracia: int = 2
var _prelight: bool = false
var _captura_pendiente: String = ""
var _frames_espera: int = 0
var _contador_manual: int = 0


func _ready() -> void:
	get_tree().root.size = Vector2i(1280, 800)
	DisplayServer.window_set_size(Vector2i(1280, 800))
	_hud = HUD_SCENE.instantiate() as CombatHud
	add_child(_hud)
	_presenter = HudPresenter.new(_hud)
	add_child(_presenter)
	_presenter.push_vida(VIDA_VALORES[_idx_vida], 100.0)
	_presenter.push_gracia(_lit_gracia, GRACIA_TOTAL)
	_mostrar_ayuda()
	print("[capturas] viewport: ", get_viewport().get_visible_rect().size)
	print("[capturas] 1=Vida 2=Gracia 3=Flash-fallo 4=Prelight 0=Reset 5=Manual → ", EVIDENCE_DIR)


func _unhandled_key_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if tecla == null or not tecla.pressed or tecla.echo:
		return
	match tecla.physical_keycode:
		KEY_1:
			_idx_vida = (_idx_vida + 1) % VIDA_VALORES.size()
			_presenter.push_vida(VIDA_VALORES[_idx_vida], 100.0)
			_programar_captura("hud-nw-vida.png", 2)
		KEY_2:
			_lit_gracia = (_lit_gracia + 1) % (GRACIA_TOTAL + 1)
			_presenter.push_gracia(_lit_gracia, GRACIA_TOTAL)
			_programar_captura("hud-nw-gracia.png", 2)
		KEY_3:
			_presenter.push_fallo()
			# 2 frames: el _process del driver corre ANTES que el del HUD y que
			# el dibujado; con 1 frame se capturaba el fotograma previo al flash.
			_programar_captura("hud-nw-flash.png", 2)
		KEY_4:
			_prelight = not _prelight
			_presenter.push_firma_ve(CombatHud.FaseVE.PRELIGHT if _prelight else CombatHud.FaseVE.CERRADA)
			_programar_captura("hud-nw-prelight.png", 2)
		KEY_5:
			_contador_manual += 1
			_programar_captura("hud-nw-manual-%d.png" % _contador_manual, 2)
		KEY_0:
			_idx_vida = 0
			_lit_gracia = 2
			_prelight = false
			_presenter.push_vida(100.0, 100.0)
			_presenter.push_gracia(_lit_gracia, GRACIA_TOTAL)
			_presenter.push_firma_ve(CombatHud.FaseVE.CERRADA)


func _process(_delta: float) -> void:
	if _captura_pendiente == "":
		return
	_frames_espera -= 1
	if _frames_espera <= 0:
		_guardar_captura(_captura_pendiente)
		_captura_pendiente = ""


func _programar_captura(nombre: String, frames: int) -> void:
	_captura_pendiente = nombre
	_frames_espera = frames


func _guardar_captura(nombre: String) -> void:
	var imagen := get_viewport().get_texture().get_image()
	var ruta := EVIDENCE_DIR + "/" + nombre
	var error := imagen.save_png(ruta)
	if error == OK:
		print("[capturas] guardada: ", ruta, " (", imagen.get_size(), ")")
	else:
		push_error("[capturas] no se pudo guardar %s (error %d)" % [ruta, error])


func _mostrar_ayuda() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 20
	add_child(capa)
	var ayuda := Label.new()
	ayuda.text = "1=Vida  2=Gracia  3=Flash-fallo  4=Prelight  0=Reset  5=Manual (auto-guarda en production/qa/evidence/)"
	ayuda.add_theme_font_size_override(&"font_size", 14)
	ayuda.position = Vector2(400, 4)
	capa.add_child(ayuda)

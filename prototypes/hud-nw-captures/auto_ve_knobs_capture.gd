## Auto-capturas throwaway QA Sprint 2 — hud-005 (3 PNG).
##
## NO es código de producción: vive en prototypes/ y nada de src/ lo referencia.
## Uso (con ventana — el capture necesita render):
##   godot --resolution 1280x800 --path . -s res://prototypes/hud-nw-captures/auto_ve_knobs_capture.gd
## Secuencia: f1 baseline+duelo / f8 hud-ve-firma.png (ev.15) / f9 knobs sweep /
## f16 hud-ve-knobs.png / f17 reduced-motion+fallo+firma / f23 A temporal /
## f24 hud-ve-reduced.png. Pushes en frames (en _init no hay _ready).
extends SceneTree

var _hud: CanvasLayer
var _frames: int = 0


func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 800))
	root.size = Vector2i(1280, 800)
	RenderingServer.set_default_clear_color(Color(0, 0, 0))
	var packed: PackedScene = load("res://src/ui/CombatHud.tscn")
	_hud = packed.instantiate()
	root.add_child(_hud)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_hud.set_en_duelo(true)
		_hud.set_vida(100.0, 100.0)
		_hud.set_gracia(2, 4)
		_hud.set_postura(80.0, 100.0)
		_hud.set_vida_jefe(100.0, 100.0)
		_hud.set_firma_ve(1)
		_hud.set_gracia(3, 4)
		_hud.set_firma_ve(2)
	if _frames == 8:
		_capturar("hud-ve-firma.png")
	if _frames == 9:
		_hud.set_firma_ve(0)
		_hud.mostrar_timer_en_aturdido(true)
		_hud.set_timer(90, 120)
		_hud.hud_opacity = 0.6
		_hud.hud_scale = 0.9
		_hud.timer_high_contrast = true
	if _frames == 16:
		_capturar("hud-ve-knobs.png")
	if _frames == 17:
		_hud.reduced_motion = true
		_hud.notificar_fallo()
		_hud.set_firma_ve(2)
	if _frames == 23:
		_capturar("hud-ve-reduced-A.png")
	if _frames == 24:
		_capturar("hud-ve-reduced.png")
		return true
	return false


func _capturar(nombre: String) -> void:
	var img := root.get_texture().get_image()
	var err := img.save_png("res://production/qa/evidence/" + nombre)
	print("[auto-captura] ", nombre, " err=", err, " size=", img.get_size())

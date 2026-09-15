## Auto-capturas throwaway QA Sprint 2 — m-003 (3 PNG).
##
## NO es código de producción: vive en prototypes/ y nada de src/ lo referencia.
## Uso (con ventana — el capture necesita render):
##   godot --resolution 1280x800 --path . -s res://prototypes/hud-nw-captures/auto_menu_capture.gd
## Secuencia: f1 pausa.abrir / f8 menu-pausa.png / f9 cerrar+muerta.abrir /
## f16 menu-muerte.png / f17 cerrar+hub.configure(SUS) / f24 menu-hub.png.
## Pushes en frames (abrir/configure hacen early-return sin _ready).
extends SceneTree

var _pausa: CanvasLayer
var _muerte: CanvasLayer
var _hub: CanvasLayer
var _frames: int = 0


func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 800))
	root.size = Vector2i(1280, 800)
	RenderingServer.set_default_clear_color(Color(0, 0, 0))
	_pausa = load("res://src/ui/menu_pausa.gd").new()
	_muerte = load("res://src/ui/menu_muerte.gd").new()
	_hub = load("res://src/ui/menu_hub.gd").new()
	root.add_child(_pausa)
	root.add_child(_muerte)
	root.add_child(_hub)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		_pausa.abrir()
	if _frames == 8:
		_capturar("menu-pausa.png")
	if _frames == 9:
		_pausa.cerrar()
		_muerte.abrir()
	if _frames == 16:
		_capturar("menu-muerte.png")
	if _frames == 17:
		_muerte.cerrar()
		_hub.configure({"sus_vigente": true, "coro_label": "Coro IX", "mm_ss": "04:37"})
	if _frames == 24:
		_capturar("menu-hub.png")
		return true
	return false


func _capturar(nombre: String) -> void:
	var img := root.get_texture().get_image()
	var err := img.save_png("res://production/qa/evidence/" + nombre)
	print("[auto-captura] ", nombre, " err=", err, " size=", img.get_size())

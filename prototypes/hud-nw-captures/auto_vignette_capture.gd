## Auto-captura throwaway QA-COND Sprint 2 (hud-nw-vignette.png, vida 25).
##
## NO es código de producción: vive en prototypes/ y nada de src/ lo referencia.
## Uso (una vez, con ventana — el capture necesita render):
##   godot --path . -s res://prototypes/hud-nw-captures/auto_vignette_capture.gd
## Instancia CombatHud real, fija Vida 25/100 (vignette progresiva, fraccion 0.25),
## espera 5 frames y guarda el viewport en production/qa/evidence/hud-nw-vignette.png.
## Equivale al driver interactivo (tecla 1×3) sin pulsar nada.
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
		# En _init el árbol aún no reparte _ready (los setters hacen
		# early-return): los pushes van en el primer frame, ya con _ready.
		# Vida 25 → vignette progresiva (fraccion 0.25 < 0.3); Gracia 2/4.
		_hud.set_vida(25.0, 100.0)
		_hud.set_gracia(2, 4)
	if _frames >= 8:
		var img := root.get_texture().get_image()
		var err := img.save_png("res://production/qa/evidence/hud-nw-vignette.png")
		print("[auto-captura] hud-nw-vignette.png err=", err, " size=", img.get_size())
		return true
	return false

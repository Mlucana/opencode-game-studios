# Godot Input — Quick Reference

Last verified: 2026-09-03 | Engine: Godot 4.7

## What Changed Since ~4.3 (LLM Cutoff)

### 4.7 Changes
- **Device IDs reworked**: mouse/keyboard device IDs changed from `0` to
  `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD`
  - Code hardcoding `device == 0` to mean keyboard/mouse BREAKS — use the constants
  - Joypad device indices are unaffected
- **4.7.2 high-polling-rate mouse fix** (GH-109639): performance issues when
  moving the mouse with high polling rate on Windows are fixed — but parry
  timing must still be verified with real hardware (Steam Deck + high-Hz mice)

### 4.6 Changes
- **Dual-focus system**: Mouse/touch focus is now separate from keyboard/gamepad focus
  - Visual feedback differs by input method
  - Custom focus implementations may need updating
- **Select Mode keybind changed**: "Select Mode" is now `v` key; old mode renamed "Transform Mode" (`q` key)

### 4.5 Changes
- **SDL3 gamepad driver**: Gamepad handling delegated to SDL library for better cross-platform support
- **Recursive Control disable**: Single property disables mouse/focus for entire node hierarchies

### 4.3 Changes (in training data)
- **InputEventShortcut**: Dedicated event type for menu shortcuts (optional)

## Current API Patterns

### Input Actions (unchanged)
```gdscript
func _physics_process(delta: float) -> void:
    var input_dir: Vector2 = Input.get_vector(
        &"move_left", &"move_right", &"move_forward", &"move_back"
    )
    if Input.is_action_just_pressed(&"jump"):
        jump()
```

### Device Detection (4.7 — CHANGED)
```gdscript
# NEVER hardcode `device == 0` for keyboard/mouse — breaks in 4.7+
func _input(event: InputEvent) -> void:
    if event.device == InputEvent.DEVICE_ID_KEYBOARD:
        handle_keyboard(event)
    elif event.device == InputEvent.DEVICE_ID_MOUSE:
        handle_mouse(event)
    # Joypad indices (0, 1, ...) are unaffected by the rework
```

### Input Events (unchanged)
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            handle_click(event.position)
    elif event is InputEventKey:
        if event.keycode == KEY_ESCAPE and event.pressed:
            toggle_pause()
```

### Focus Management (4.6 — CHANGED)
```gdscript
# Mouse/touch and keyboard/gamepad focus are now SEPARATE
# Visual styles may differ depending on which input method is active
# If you have custom focus drawing, test with both input methods

# Standard approach still works:
func _ready() -> void:
    %StartButton.grab_focus()  # Keyboard/gamepad focus

# But be aware: mouse hover focus != keyboard focus in 4.6
```

### Gamepad (4.5+ — SDL3 backend)
```gdscript
# API unchanged, but SDL3 provides:
# - Better device detection across platforms
# - Improved rumble support
# - More consistent button mapping

func _input(event: InputEvent) -> void:
    if event is InputEventJoypadButton:
        if event.button_index == JOY_BUTTON_A and event.pressed:
            confirm_selection()
```

## Common Mistakes
- Hardcoding `device == 0` for keyboard/mouse detection (breaks in 4.7 — use `DEVICE_ID_*`)
- Not testing both mouse and keyboard focus paths (dual-focus in 4.6)
- Assuming `grab_focus()` affects mouse focus (it only affects keyboard/gamepad in 4.6)
- Using string literals instead of `StringName` (`&"action"`) for action names in hot paths

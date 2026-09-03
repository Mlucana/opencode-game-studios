# Godot Engine — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Godot 4.7 |
| **Release Date** | ~Mid 2026 |
| **Project Pinned** | 2026-07-31 |
| **Last Docs Verified** | 2026-07-31 |
| **LLM Knowledge Cutoff** | May 2025 |

## Knowledge Gap Warning

The LLM's training data likely covers Godot up to ~4.3. Versions 4.4 through
4.7 introduced significant changes that the model does NOT know about.
Always cross-reference this directory before suggesting Godot API calls.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 4.4 | ~Mid 2025 | MEDIUM | Jolt physics option, FileAccess return types, shader texture type changes |
| 4.5 | ~Late 2025 | HIGH | Accessibility (AccessKit), variadic args, @abstract, shader baker, SMAA |
| 4.6 | Jan 2026 | HIGH | Jolt default, glow rework, D3D12 default on Windows, IK restored |
| 4.7 | ~Mid 2026 | HIGH | Mouse/keyboard device ID rework, RichTextLabel image unit rework, Jolt SoftBody3D/WorldBoundaryShape3D behavior changes |

## Migration Notes — 4.6 → 4.7

**Migration guide**: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html

**Pre-upgrade audit result**: `src/` was empty at the time of this upgrade (no
production code existed yet). No deprecated API usage found. This was a
version realignment, not a code migration.

**Key breaking changes to watch for going forward**:

| Subsystem | Change |
|-----------|--------|
| Input | Mouse/keyboard device IDs changed from `0` to `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD`. Breaks code that hardcodes `device == 0` to mean keyboard/mouse. Joypad device indices are unaffected. |
| Audio | `AudioEffectSpectrumAnalyzer.tap_back_pos` removed |
| UI | `RichTextLabel.add_image()` / `update_image()`: width/height changed `int` → `float`; `width_in_percent`/`height_in_percent` renamed to `width_unit`/`height_unit` with a new enum type |
| Physics (Jolt) | `WorldBoundaryShape3D` plane distance sign interpretation reversed; `SoftBody3D` mass/stiffness behavior changed |
| Animation | `Animation.length` property metadata changed `float` → `double` |
| Editor | `EditorSceneFormatImporter` constants moved to `ImportFlags` enum |
| New-project defaults | Window stretch mode/aspect changes from `disabled`/`keep` to `canvas_items`/`expand`; `LookAtModifier3D.relative` changes from `true` to `false` |

**Recommended migration order**: N/A — no existing code to migrate. Any new
input-remapping or device-detection code should use the new `DEVICE_ID_*`
constants from the start rather than hardcoding `0`.

## Verified Sources

- Official docs: https://docs.godotengine.org/en/stable/
- 4.6→4.7 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
- 4.5→4.6 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html
- 4.4→4.5 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html
- Changelog: https://github.com/godotengine/godot/blob/master/CHANGELOG.md
- Release notes: https://godotengine.org/releases/4.7/

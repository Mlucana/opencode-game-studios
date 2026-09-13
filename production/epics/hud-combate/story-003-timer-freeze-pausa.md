# Story 003: Timer S + freeze-ALWAYS + Pausa

> **Epic**: HUD de Combate (`hud-combate`)
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M (4h)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` not yet created
> **Last Updated**: 2026-09-10

## Context

**Diseño**: `design/ux/hud.md` Rev-2 (§HUD Elements Timer castigo; §Dynamic Behaviors Freeze + Pausa; corrige §stale Rev-1: freeze = pausa total 0%, HUD 1.0x ALWAYS)
**Requirement**: `TR-hud-???` *(warning: no TR baseline — register via `/architecture-review` Fase 8)*

**ADR Governing Implementation**: ADR-001 Pattern-A (freeze = `SceneTree.paused=true`, diegetic PAUSABLE 0%, presentation ALWAYS: HUD `CanvasLayer` + `WallTick` + latch; double counter WallTick pared vs DiegeticTick resolver-owned; resolver call-stack order seals tick BEFORE dispatch, `paused=true` LAST)
**ADR Decision Summary**: HUD never freezes with the world (Combate R2 + Impacto R1, verified by C14); transient-onset ≤2 wall ticks = juicio; `physics_ticks_per_second=60` pinned in project.godot.

**Engine**: Godot 4.7.2-stable | **Risk**: HIGH
**Engine Notes**: `SceneTree.paused` + `PROCESS_MODE_ALWAYS/PAUSABLE` + `process_physics_priority` unverified at 4.7.2 (HIGH — no core/SceneTree reference module); `Engine.get_physics_frames()` LOW; Tween/AnimationPlayer physics-mode alignment for freeze edges.

**Control Manifest Rules (this layer)**: N/A (manifest missing) — fallback: HUD reads WallTick clocks, never owns time.

---

## Acceptance Criteria

*From `design/ux/hud.md`, scoped to this story:*

- [ ] S bar (gray frío high-luminance, linear, NOT numeric) appears only in Aturdido, continuous 120 ticks, show/hide with no ease
- [ ] During freeze: HUD ticks at full 60Hz while diegetic subtree is paused 0% (C14)
- [ ] Pausa: HUD dimmed 40%, S hidden, timer paused (not counting), no animated vignette, no rumble, return by cut
- [ ] `physics_ticks_per_second = 60` pinned in `project.godot` (config grep gate)

---

## Implementation Notes

*Derived from ADR-001 Decision §§1–3:*

- HUD root `CanvasLayer` layer 10, `follow_viewport_enabled=false`, `process_mode=ALWAYS` (P1 impl note); WallTick autoload precedes scene in dispatch.
- Timer reads DiegeticTick-sealed `restantes(T)` — never counts with `_process` or pausable probes (Impacto D1 oracle rule).
- Freeze edges: entry transient 1 tick = juicio (≤2 wall); shards/shake at close = confirmación (≤10). Durations owned by #4 — this story wires, never tunes ticks.
- WallTick/DiegeticTick mechanism final shape pending time-ADR detail — implement against ADR-001 §§1–3 exactly; flag deviations.

---

## Out of Scope

- Story 001/002/004/005; freeze *durations* tuning (owner #4); audio duck (owner #16)

---

## QA Test Cases

*qa-lead QL-STORY-READY ADEQUATE 2026-09-08 — automated:*

- **AC-a — S-bar Aturdido-only**
  - Given: HUD bound to FSM stub
  - When: enter/exit Aturdido (120-tick window)
  - Then: bar shows continuous progress, hides with no ease
  - Edge cases: re-stun mid-count resets to 120; 119/121 boundary ticks
- **AC-b — freeze HUD ticks (C14)**
  - Given: active freeze, diegetic paused
  - When: 60 wall ticks elapse
  - Then: HUD advanced 60 ticks @60Hz, diegetic advanced 0
  - Edge cases: freeze opened during S-bar active
- **AC-c — Pausa**
  - Given: Aturdido + S active
  - When: Pausa on, then off
  - Then: dim 40%, S hidden, timer value frozen, zero rumble, return by cut
  - Edge cases: pausa opened mid-freeze (gating R12: freeze-counter vs menu-pause)
- **AC-d — 60Hz pin**
  - Given: `project.godot`
  - When: config grep in CI
  - Then: `physics_ticks_per_second=60`
  - Edge cases: export-preset override attempt fails loudly

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/ui/hud_timer_freeze_test.gd` — must exist and pass (OR documented playtest)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (HUD root + presenter)
- Unlocks: Story 004 (queue defers relative to freeze edges)
- External: WallTick autoload + resolver pause wiring (Foundation/Core — stub until landed)

## Completion Notes
**Completed**: 2026-09-10
**Criteria**: 4/4 passing (integration test, BLOCKING gate)
**Deviations**: C14 verificado a nivel lógico+config (árbol pausado real no testeable con el runner dentro — documentado en el test; Deck Sprint 2); flash vignette en ms diferido a hud-004; `run/main_scene` apunta al driver throwaway (flag pte. decisión)
**Test Evidence**: tests/integration/ui/hud_timer_freeze_test.gd — 8/8 verde, 112ms (suite integration/ui 17/17 con hud_ne_test)
**Code Review**: APPROVED (cambios mínimos: solo pin 60Hz en config + test nuevo; S/pausa/ALWAYS preexistentes verificados)

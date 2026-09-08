# Story M-001b: Splash ≤2.0s + A-spam guard

> **Epic**: Menú Principal y Flujo de Pantallas (`menu-principal`)
> **Status**: Blocked — BLOCKED: preload/baker/veil ADR unwritten (splash assets, veil progress undefined)
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: S (2h)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` not yet created
> **Last Updated**: —

## Context

**GDD**: `design/gdd/menu-principal-y-flujo-de-pantallas.md` (splash estático: título + tinta, skippable discreto — Rev2 decidido)
**Requirement**: `TR-menu-???` *(warning: no TR baseline)*

**ADR Governing Implementation**: (unwritten: preload/baker/veil) — placeholder.
**ADR Decision Summary**: Pending ADR must define splash asset preload, veil progress reporting, Hub→Duelo budget split.

**Engine**: Godot 4.7.2-stable | **Risk**: MEDIUM
**Engine Notes**: `load_threaded_*` MEDIUM; skip only on discrete flanks `{ui_accept, ui_cancel, click}` — motion/hold/gyro/connection ignored; firing input never counts as skip (Menú R6).

**Control Manifest Rules (this layer)**: N/A.

---

## Acceptance Criteria

- [ ] Splash auto-dismisses ≤2.0s; each discrete pulse skips; splash + A-spam = 0 menu activations (MENU-12)
- [ ] Focus lands per focus-map only after splash completes (no pre-splash activation)

---

## Implementation Notes

Static splash (no vela); consume + inhibit destination 1 frame + swallow 200ms on skip (Menú R6 pattern, mirrors Decisión commit guard).

---

## Out of Scope

- M-001a (shell), M-006b (PERF budgets)

---

## QA Test Cases

*qa-lead 2026-09-08 — manual + fake-clock unit:*

- **AC-a — splash**
  - Setup: cold boot, timer; A-spam harness during splash
  - Verify: auto-dismiss ≤2.0s; discrete pulse skips; 0 menu activations under spam
  - Pass condition: counters exact

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/menu-splash-evidence.md`

**Status**: [ ] Not yet created (Blocked — see top)

---

## Dependencies

- Depends on: preload/baker/veil ADR (unwritten); M-001a (surface lands after splash)
- Unlocks: M-006b (PERF boot budget measured over this path)

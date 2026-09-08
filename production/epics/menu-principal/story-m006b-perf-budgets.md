# Story M-006b: PERF-MENU budgets

> **Epic**: Menú Principal y Flujo de Pantallas (`menu-principal`)
> **Status**: Blocked — BLOCKED: PERF-MENU-01..04 provisional (need producer ratification) + preload/baker/veil ADR unwritten (splash/veil asset path undefined)
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: S (2h)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` not yet created
> **Last Updated**: —

## Context

**GDD**: `design/gdd/menu-principal-y-flujo-de-pantallas.md` (PERF-MENU-01..04 provisional, a ratificar por producer)
**Requirement**: `TR-menu-???` *(warning: no TR baseline)*

**ADR Governing Implementation**: (unwritten: preload/baker/veil) + producer ratification of budgets — placeholders.
**ADR Decision Summary**: Pending: preload jobs + veil progress + Hub→Duelo budget split; ratified p95 numbers replace provisionals.

**Engine**: Godot 4.7.2-stable | **Risk**: MEDIUM
**Engine Notes**: Timing via fake clock in unit, Deck p95 manual only; FS via spy; input via gamepad virtual (determinism note in GDD).

**Control Manifest Rules (this layer)**: N/A.

---

## Acceptance Criteria

- [ ] Cold boot → interactive menu p95 <3s PC / <5s Deck with skip (PERF-MENU-01)
- [ ] Hub/Muerte→Menu p95 <200ms Deck (PERF-MENU-02)
- [ ] (Covered in M-004: modal ≤100ms same-frame focus; focus-move ≤1 frame — referenced, not re-owned)

---

## Implementation Notes

Budgets provisional until producer ratifies — this story tracks the ratification + measurement; do not tune assets to hit unratified numbers.

---

## Out of Scope

- M-004 perf asserts (owned there); asset optimization (owner technical-artist post-ratification)

---

## QA Test Cases

*qa-lead 2026-09-08 — manual Deck + fake-clock unit:*

- **AC-a — boot budget**
  - Setup: cold boot, n=10, PC + Deck
  - Verify: p95 <3s / <5s with skip
  - Pass condition: metered, logged
- **AC-b — transition budget**
  - Setup: Hub→Menu, Muerte→Menu on Deck
  - Verify: p95 <200ms
  - Pass condition: metered, logged

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/menu-perf-evidence.md` (measurements + ratification note)

**Status**: [ ] Not yet created (Blocked — see top)

---

## Dependencies

- Depends on: producer ratification; preload ADR; M-001b (boot path measured)
- Unlocks: none

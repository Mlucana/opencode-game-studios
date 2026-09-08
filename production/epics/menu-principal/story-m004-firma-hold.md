# Story M-004: Firma hold Tipo-A

> **Epic**: Menú Principal y Flujo de Pantallas (`menu-principal`)
> **Status**: Ready (closest to shippable — GDD APPROVED still required per PR-EPIC point 5)
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: M (3h)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` not yet created
> **Last Updated**: —

## Context

**GDD**: `design/gdd/menu-principal-y-flujo-de-pantallas.md` R4 (firma hold + listado; hold protects run/SUS destruction — NEVER Decisión, which is single-press by design)
**Requirement**: `TR-menu-???` *(warning: no TR baseline)*

**ADR Governing Implementation**: ADR: N/A — hold-to-confirm signature is a Menu R4 design rule (destructive irreversibility communicated by friction + explicit listing), no architectural pattern required.
**ADR Decision Summary**: N/A — see above. Pinned: `firma_hold_ms` (800–1500, default 1000); 5-field list + `MENU_HOLD_*` keys frozen via `/localize` (qa-lead revision applied).

**Engine**: Godot 4.7.2-stable | **Risk**: LOW
**Engine Notes**: Fake-clock unit (no wall timing in tests); single-flank edge consume; release-early = cancel with zero side effects.

**Control Manifest Rules (this layer)**: N/A.

---

## Acceptance Criteria

- [ ] Comenzar-with-SUS firma lists exactly 5 fields (coro, n+ids reliquias, gracia, corrupción, "se conservan N llaves / M fragmentos"); release before hold completes = 0 deletions (MENU-02b)
- [ ] Incomplete Reset firma (release/1 flank) → byte-identical 0 deletions; full hold → PER+SUS deleted, SET intact → S0 + log (MENU-10)
- [ ] Modal opens ≤100ms with focus same frame (PERF-MENU-03); focus movement ≤1 frame @60fps (PERF-MENU-04)

---

## Implementation Notes

*From GDD R4 + qa-lead pin:*

- `firma_hold_ms=1000` default (range 800–1500, player-adjustable? No — fixed; qa pin is normative until `/quick-design` retunes).
- Hold is a *press-and-hold with live progress + listed consequences*; release = cancel, never partial commit. Applies to: Comenzar-with-SUS, Abandonar (duelo/Hub), Reset, Migración, Restaurar.
- Verdict event consumed by M-002 (atomic S2→S3) and M-005 (Reset/Restore execution).

---

## Out of Scope

- Decisión commit (single-press + fresh-flank, SIN hold — Gracia #15 adjudication; confusing the two violates Pilar 4)
- M-005 execution backends (this story owns the signature widget + verdict only)

---

## QA Test Cases

*qa-lead 2026-09-08 — automated `tests/unit/menu/firma_hold_test.gd` (fake clock):*

- **AC-a — firma lists + early release**
  - Given: S2, `firma_hold_ms=1000`
  - When: hold-release early / cancel
  - Then: 0 deletions, sha identical; modal listed the 5 fields
  - Edge cases: 1-flank tap; kill mid-hold
- **AC-b — Reset completeness**
  - Given: any state with PER+SUS
  - When: incomplete vs full hold
  - Then: incomplete → byte-identical; full → PER+SUS deleted, SET intact → S0 + log
  - Edge cases: hold across frame boundary at 999/1000/1001ms
- **AC-c — perf**
  - Given: fake clock
  - When: open modal, move focus
  - Then: open ≤100ms focus same-frame; focus-move ≤1 frame @60fps
  - Edge cases: open during splash (must queue, never pre-empt)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/menu/firma_hold_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: M-001a (modal surface)
- Unlocks: M-002 (consume verdict), M-005 (destructive execution)

# Story M-001a: Shell S0/S1/S2 + foco por mando

> **Epic**: Menú Principal y Flujo de Pantallas (`menu-principal`)
> **Status**: Blocked — BLOCKED: arranque/router ADR unwritten (single `change_scene` owner, focus-after-splash, swallow 200ms undefined). Run `/architecture-decision` to advance it.
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M (3h)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` not yet created
> **Last Updated**: —

## Context

**GDD**: `design/gdd/menu-principal-y-flujo-de-pantallas.md` (Needs Revision)
**Requirement**: `TR-menu-???` *(warning: no TR baseline — register via `/architecture-review` Fase 8)*

**ADR Governing Implementation**: (unwritten: arranque/router) — placeholder. MENU-08 oracle + focus rules come from GDD R6/R7 only.
**ADR Decision Summary**: Pending ADR must define: sole `change_scene` owner, splash ≤2.0s + focus-after-splash, discrete-pulse skip + swallow 200ms, A-spam guard.

**Engine**: Godot 4.7.2-stable | **Risk**: MEDIUM
**Engine Notes**: `Control.focus` + focus-trap + `set_input_as_handled` + inhibit (MenuShell row); no hover-dependent paths; `mouse_filter` discipline per P4.

**Control Manifest Rules (this layer)**: N/A (manifest missing).

---

## Acceptance Criteria

- [ ] Cold boot without saves → exactly {Comenzar la novena, Ajustes}; Continuar/Migrar/Reset absent from tree; 0 error modals in 5s (MENU-01)
- [ ] S2 → Continuar enabled with subtitle `{coro mm_ss}`, initial focus on Continuar (MENU-02a)
- [ ] S1 post-death → Continuar visible-disabled-focusable with `MENU_REASON_RUN_LOST` (MENU-03)
- [ ] Gamepad-only traversal of Menu S0/S1/S2 in focus-map order; focus = 2px `#C7CDD6` border + marker, 0 glow; modals trap + restore focus (MENU-06 partial)

---

## Implementation Notes

GDD R7 focus rules (border+cuneta, 0 glow, dual-focus hover-never-steals); es-MX keys provisional per key table (`/localize` fixes copy). Split from M-001b (splash owns preload timing).

---

## Out of Scope

- M-001b (splash), M-002 (Continuar backend), M-004 (firma hold), M-005 (S4/S5)

---

## QA Test Cases

*qa-lead GAPS (ceiling — GDD unstable, no TRs, no Run #3, no qa-plan) 2026-09-08 — manual, gamepad virtual, capture to `production/qa/evidence/`:*

- **AC-a/b/c — surfaces**
  - Setup: cold boot no-saves; S2 fixture; S1 post-death
  - Verify: exact option sets per state; subtitle + focus-on-Continuar in S2; disabled-focusable + RUN_LOST in S1
  - Pass condition: tree dumps match; 0 error modals in 5s
- **AC-d — focus**
  - Setup: gamepad-only traversal
  - Verify: order = focus map; 2px border 0 glow; modal trap + restore
  - Pass condition: full loop with no escapes

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/menu-shell-evidence.md` (tree dumps + captures + sign-off)

**Status**: [ ] Not yet created (Blocked — see top)

---

## Dependencies

- Depends on: arranque/router ADR (unwritten) — unblocks wiring
- Unlocks: M-002 (Continuar backend behind this surface)

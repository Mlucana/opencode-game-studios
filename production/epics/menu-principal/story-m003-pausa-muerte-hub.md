# Story M-003: Pausa + Muerte muda + Hub

> **Epic**: Menú Principal y Flujo de Pantallas (`menu-principal`)
> **Status**: Complete (opens tracked as TODOs: narrative object, #18 Hub-focus, Run #3 Abandonar semantics, MENU-05 p95 + Deck)
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M (3h)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` not yet created
> **Last Updated**: 2026-09-13

## Context

**GDD**: `design/gdd/menu-principal-y-flujo-de-pantallas.md` (Pausa duelo-only, Muerte muda Rev2-decided, Hub lines)
**Requirement**: `TR-menu-???` *(warning: no TR baseline)*

**ADR Governing Implementation**: ADR-001 (pause gating: freeze-counter ticks in freeze-pause, frozen in menu-pause; trauma-decay skipped in both; latch-stamps suppressed in menu — Feedback R12)
**ADR Decision Summary**: Pausa is the only duel overlay; timers (120-tick castigo) pause without counting; no vignette animation, no rumble in Pausa; return by cut.

**Engine**: Godot 4.7.2-stable | **Risk**: LOW
**Engine Notes**: Standard Control focus + modal trap; `set_pausa_visual` final wiring pending arranque/router ADR (surface implementable, wiring flagged).

**Control Manifest Rules (this layer)**: N/A.

---

## Acceptance Criteria

- [ ] Mid-duel pausa → exactly {Reanudar, Abandonar, Ajustes} in that focus order; Continuar and retry absent from tree (MENU-04)
- [ ] Death → mute Hub-object + only Volver al menú (already S1; no cita — Rev2 decided; object anillo/zapato TBD by narrative, tracked)
- [ ] Hub: persistent sober SUS line (`MENU_HUB_SUS_LINE`) + stakes warning (`MENU_HUB_STAKES`) next to duel entry
- [ ] Settings change mutates only `settings.save`; `profile.save`/`suspend.save` stay absent (MENU-14)

---

## Implementation Notes

Pausa assembly mirrors Decisión modal discipline (consume/inhibit 200ms, focus trap + restore); muerte muda carries no quote — Pilar 4 tone rule. Active-memory tag corner: menus only, never duel (GDD row).

---

## Out of Scope

- M-002 (SUS backend), M-004 (destructive firma on Abandonar — Pausa lists Abandonar, firma lives in M-004)

---

## QA Test Cases

*qa-lead 2026-09-08 — manual:*

- **AC-a — pausa**
  - Setup: mid-duel, gamepad
  - Verify: exact 3 options in order; no Continuar/retry in tree dump
  - Pass condition: order + content exact
- **AC-b — muerte**
  - Setup: post-death S1
  - Verify: mute Hub-object + single Volver option
  - Pass condition: no quote, no extra options
- **AC-c — hub**
  - Setup: Hub with live SUS
  - Verify: SUS line + stakes warning persistent and sober
  - Pass condition: es-MX keys match table
- **AC-d — settings isolation**
  - Setup: S0, FS spy
  - Verify: adjusting a setting mutates only `settings.save`
  - Pass condition: profile/suspend still absent
- **Sprint 2 additions (qa-plan 2026-09-13, GDD-derived):**
  - Pausa gating: 120-tick castigo pauses without counting; trauma-decay skipped in both freezes; latch-stamps suppressed in menu (ADR-001 Feedback R12)
  - Surface built pure against M-001a mock; `set_pausa_visual` final wiring flagged TODO (arranque/router ADR)
  - Continuar/retry absent from pausa tree by construction (MENU-04 + R9: tree dump asserts absence, not disabled state)

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/menu-pausa-muerte-hub-evidence.md`

**Status**: [x] Created `production/qa/evidence/menu-pausa-muerte-hub-evidence.md` (automatizado PASS 18/18; 3 capturas + Deck PENDING por diseño)

---

## Dependencies

- Depends on: M-001a (shell focus infra)
- Open (non-blocking): narrative object choice; #18 Hub-focus; #3 Abandonar semantics

---

## Completion Notes
**Completed**: 2026-09-13
**Criteria**: 4/4 passing (MENU-04, muerte muda, Hub, MENU-14) + gating R12 lado-UI
**Deviations**: 1 menor intencional — sin `transicion_solicitada` (el router M-001a decide; documentado en presenter). Advisory → tech-debt: asimetría connect-`_construir`/disconnect-`_exit_tree` (re-add sin free pierde hook mando).
**Test Evidence**: UI — `tests/integration/ui/menu_pausa_muerte_hub_test.gd` (18/18 green; suite ui 63/63) + `production/qa/evidence/menu-pausa-muerte-hub-evidence.md` (3 capturas + Deck + es-MX final + R12-full pendientes)
**Code Review**: APPROVED WITH SUGGESTIONS 1ª pasada → fixes W1/W2/W4/W5 + es_muda scan + 3 tests → LP-CODE-REVIEW APPROVE + QL-TEST-COVERAGE ADEQUATE 2ª pasada

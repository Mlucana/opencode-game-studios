# Story M-006a: Reduced-motion + legibilidad Deck

> **Epic**: Menú Principal y Flujo de Pantallas (`menu-principal`)
> **Status**: Ready (ADVISORY gate — evidence + sign-off, never blocking)
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: S (2h + Deck session)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` not yet created
> **Last Updated**: —

## Context

**GDD**: `design/gdd/menu-principal-y-flujo-de-pantallas.md` (MENU-13 proxy + MENU-17)
**Requirement**: `TR-menu-???` *(warning: no TR baseline)*

**ADR Governing Implementation**: ADR: N/A — reduced-motion collapse + readability checklist are presentation/evidence concerns, no architectural pattern.
**ADR Decision Summary**: N/A. Budgets live in M-006b; this story is the human-hardware half.

**Engine**: Godot 4.7.2-stable | **Risk**: LOW
**Engine Notes**: Deck 7" @30–40cm is the constraint; verify on hardware, never editor-only (art-bible 7.2).

**Control Manifest Rules (this layer)**: N/A.

---

## Acceptance Criteria

- [ ] Reduced-motion ON → 0 flashes, static vignette, UI sounds via bus (0 direct players) on every transition (MENU-17)
- [ ] Deck 7" readability checklist + captures in `production/qa/evidence/`; proxy: 0 functional labels <18px base, 0 nodes outside 5% safe-zone (MENU-13, ADVISORY gate)

---

## Implementation Notes

Mirror hud.md reduced-motion collapse (1-frame cuts); motion/hold/gyro/connection inputs never skip; firing input never counts as skip.

---

## Out of Scope

- M-006b (timing budgets); hud.md A2 contrast metering (Story 005's Deck session — combine hardware sessions)

---

## QA Test Cases

*qa-lead 2026-09-08 — manual:*

- **AC-a — reduced-motion**
  - Setup: reduced-motion ON, all transitions
  - Verify: 0 flashes, static vignette, bus-only sounds
  - Pass condition: frame captures clean
- **AC-b — readability**
  - Setup: Deck 7" 30–40cm + proxy grep (labels <18px, nodes outside safe-zone)
  - Verify: checklist + captures filed
  - Pass condition: proxy 0/0 + human sign-off (ADVISORY)

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/menu-motion-readability-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: M-001a (transitions to collapse)
- Combine hardware session with hud Story 005 AC-d

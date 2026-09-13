# Story 004: Alertas + cola visual + vignette

> **Epic**: HUD de Combate (`hud-combate`)
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: S (2h)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` not yet created
> **Last Updated**: 2026-09-10

## Context

**Diseño**: `design/ux/hud.md` Rev-2 (§HUD Elements Bordes/vignette; §Notification Priority 7-level queue; P2)
**Requirement**: `TR-hud-???` *(warning: no TR baseline — register via `/architecture-review` Fase 8)*

**ADR Governing Implementation**: ADR: N/A — 7-level visual arbitration is a presentation rule from hud.md, no architectural pattern required. (Freeze edges that feed the queue come from ADR-001; audio ducking coordination is owner #16.)
**ADR Decision Summary**: N/A — see above.

**Engine**: Godot 4.7.2-stable | **Risk**: MEDIUM
**Engine Notes**: `hud_vignette.gd` `_draw()` banded; latch+hold 2 render frames covers Deck 40Hz render vs 60Hz physics skew (judgment stays in identical wall ticks, +1 render-frame tolerance — Impacto C1).

**Control Manifest Rules (this layer)**: N/A (manifest missing).

---

## Acceptance Criteria

*From `design/ux/hud.md`, scoped to this story:*

- [ ] 7-level queue enforced: Muerte > Fallo > Firma-VE > Caída-Postura > Pre-light > Timer > Gasto-feedback; never two flashes same tick (lower deferred 1 tick, still within 1–2 tick budget)
- [ ] Death ev.13 suppresses everything 800ms; fail ev.5 suppresses VE signature 200ms
- [ ] Vignette tinta (`#14110E`) progressive on low HP + alpha-only pulse; golden rule: failure = absence of light, never punitive light flash
- [ ] Latch+hold 2 render frames: no critical tick lost at Deck 40Hz

---

## Implementation Notes

*Derived from hud.md + P2:*

- Central arbiter `combat_hud.gd::_anunciar()` owns the queue; `flash_fallo()` in `hud_nw.gd`; same-priority audio ducking proposed to #16 (tails ≤4, voces ≤12 interim).
- Death = hard cut + crack (ev.13); low-HP heartbeat alpha-only, accelerating.
- In Pausa: no animated vignette, no rumble.
- Reduced-motion interplay owned by Story 005; this story implements the full-motion baseline + latch.

---

## Out of Scope

- Story 005 (VE signature motion, knobs, reduced-motion collapse, Deck contrast metering)

---

## QA Test Cases

*qa-lead QL-STORY-READY ADEQUATE 2026-09-08 — manual (frame-step):*

- **AC-a — queue**
  - Setup: fire two priorities in the same tick
  - Verify: exactly one flash; lower-priority deferred 1 tick
  - Pass condition: all 7 levels hold under pairwise collision sweep
- **AC-b — suppression**
  - Setup: fire ev.13, then ev.5 in separate runs
  - Verify: death mutes all for 800ms; fail mutes VE signature 200ms
  - Pass condition: timers exact, frame-stepped
- **AC-c — vignette**
  - Setup: drive HP low
  - Verify: progressive tinta vignette from edges, alpha-only pulse
  - Pass condition: zero light-flash frames
- **AC-d — latch**
  - Setup: Deck 40Hz mode, frame-step
  - Verify: critical tick held 2 render frames
  - Pass condition: none lost across 50-trial sweep

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/hud-alert-queue-evidence.md` (frame-step log + screenshots + sign-off)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (freeze edges feed the queue)
- Unlocks: Story 005 (reduced-motion collapse overrides these behaviors)

## Completion Notes
**Completed**: 2026-09-10
**Criteria**: 4/4 passing (automated test — supera el frame-step manual exigido, ADVISORY)
**Deviations**: test de pares asumía que `_anunciar()` ejecuta (es solo la puerta; el caller dispara) → fix con patrón caller; vignette-25 captura pendiente + qa-lead Sprint 2
**Test Evidence**: tests/integration/ui/hud_cola_vignette_test.gd — 9/9 verde (suite ui 26/26); production/qa/evidence/hud-alert-queue-evidence.md
**Code Review**: APPROVED (vignette flash a frames cierra deuda B1; reloj manual documentado)

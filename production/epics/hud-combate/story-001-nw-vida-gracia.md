# Story 001: NW Vida + Gracia widgets

> **Epic**: HUD de Combate (`hud-combate`)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M (3h)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` not yet created (run `/create-control-manifest`)
> **Last Updated**: —

## Context

**Diseño**: `design/ux/hud.md` Rev-2 (§HUD Elements: Vida jugador, Medidor Gracia; §Layout Zones NW)
**Requirement**: `TR-hud-???` *(warning: no TR-hud-* baseline in `docs/architecture/tr-registry.yaml` — register via `/architecture-review` Fase 8)*

**ADR Governing Implementation**: ADR-002 (contrato-eventos) — Ledger level/event signals are read-only (±1e-9); observer setters fail. Layout itself: ADR N/A — pure presentation, no architectural pattern required.
**ADR Decision Summary**: Subscribers only read/present (reentrancy forbidden); HUD consumes Resolver HP + Ledger levels+events, exposes nothing gameplay-readable (architecture.md CombatHUD row).

**Engine**: Godot 4.7.2-stable | **Risk**: MEDIUM
**Engine Notes**: `CanvasLayer` + `PROCESS_MODE_ALWAYS` (HUD alive during freeze); `ProgressBar` + `StyleBoxFlat` square corners; locale via `tr()`; dual-focus: hover never steals gamepad focus.

**Control Manifest Rules (this layer)**: N/A (manifest missing) — fallback: Presentation presents, never decides; no state writes from UI.

---

## Acceptance Criteria

*From `design/ux/hud.md`, scoped to this story:*

- [ ] Vida bar NW tracks every HP change event (F5: base 100 +18/absorber + relic passthrough) in 1–2 ticks, no ease-in
- [ ] Gracia shards NW below Vida (rombos ◆◆◇◇ + `set_prelight`); earn/spend/saturation interpolate only — never compute (owner #5)
- [ ] Single #C75C4A flash on fail event ev.5; death = hard cut + candle-out, suppress all 800ms
- [ ] Zero hardcoded strings in NW assembly (grep: all text via `tr()`)
- [ ] NW bounding box ≤6% screen area @1280×800, 5% safe-zone clear

---

## Implementation Notes

*Derived from ADR-002 + hud.md + P1/P2:*

- `gracia_shards.gd` / posture-equivalent draw in `_draw()`, event-driven via `queue_redraw()` — never poll.
- `HudPresenter`-style bridge: re-emit read-only signals, emit `hud_audio_requested` for clicks — sound via event bus, never direct players.
- Palette `#2A2E36` bg / `#8C94A0` mid / `#C7CDD6` light; fonts ≥18px apparent Deck.
- `mouse_filter` IGNORE on non-interactive; keyboard+gamepad complete, no hover states.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: NE Postura/Vida jefe + ev.8 drop
- Story 003: Timer S + freeze-ALWAYS + Pausa dimming
- Story 004: alert queue arbitration + vignette progression
- Story 005: VE signature + spend feedback + knobs + reduced-motion

---

## QA Test Cases

*Written by qa-lead at story creation (QL-STORY-READY ADEQUATE 2026-09-08).*

- **AC-a — Vida tracking**
  - Setup: mock HP change events via Resolver stub
  - Verify: bar tracks every change in 1–2 ticks, hard cut
  - Pass condition: no ease-in observable frame-stepped
- **AC-b — Gracia interp-only**
  - Setup: earn/spend/saturate sequences on mocked Ledger
  - Verify: shards below Vida, smooth interp, match Ledger ±1e-9 after settle
  - Pass condition: HUD never computes (no local earn math)
- **AC-c — fail flash**
  - Setup: trigger ev.5
  - Verify: single #C75C4A flash on Vida
  - Pass condition: exactly once, 1–2 ticks
- **AC-d — tr()**
  - Setup: `rg` for string literals in NW assembly
  - Verify: all user-facing text via `tr()`
  - Pass condition: zero hardcoded hits
- **AC-e — layout budget**
  - Setup: 1280×800 screenshot
  - Verify: NW box ≤6% area, 5% safe-zone clear
  - Pass condition: measured pass, artifact in evidence

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/hud-nw-evidence.md` (walkthrough + screenshots + sign-off) or interaction test

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (first story; uses Ledger/Resolver stubs until Core epics exist)
- Unlocks: Story 002 (NE reuses P1 bar infra + presenter pattern)

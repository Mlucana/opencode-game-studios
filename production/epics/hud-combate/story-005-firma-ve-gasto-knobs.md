# Story 005: Firma VE + gasto + knobs + reduced-motion + contraste Deck

> **Epic**: HUD de Combate (`hud-combate`)
> **Status**: Ready (AC-d DEFERRED to real Deck hardware — not blocked, scheduled for Vertical Slice)
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M (3h + Deck session)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` not yet created
> **Last Updated**: —

## Context

**Diseño**: `design/ux/hud.md` Rev-2 (§HUD Elements Firma VE + Feedback gasto; §Tuning Knobs; §Accessibility; §Platform & Input Variants)
**Requirement**: `TR-hud-???` *(warning: no TR baseline — register via `/architecture-review` Fase 8)*

**ADR Governing Implementation**: ADR-002 partial (VE signals ev.14/15/16 open/parry/close; spend legality states owned by #5 G7) + ADR N/A for player knobs (pure presentation preferences, no architectural pattern).
**ADR Decision Summary**: VE ⇒ delta −1; illegal spend in active VE discarded no-buffer (G7); `gracia==coste` ACCEPTS to 0.0; same-tick order earn→clamp+saturación→gasto; knobs `hud_opacity`/`hud_scale`/`timer_high_contrast`/`disable_damage_flash` never drop luminance below 4.5:1.

**Engine**: Godot 4.7.2-stable | **Risk**: MEDIUM
**Engine Notes**: CPUParticles2D pinned deterministic (`finished` reliable) — cost validation pre-sprint is a `technical-artist` question (Impacto P0-DEF); gamepad-primary, parry DIGITAL (no analog axis mappable — C24); spend binding discrete, never parry button.

**Control Manifest Rules (this layer)**: N/A (manifest missing).

---

## Acceptance Criteria

*From `design/ux/hud.md`, scoped to this story:*

- [ ] VE signature: pre-light ev.14 → move-on-parry ev.15 (Gracia moves, Postura still) → sober fold on close-without-parry ev.16; illegal spend during active VE rejected no-buffer without consuming cap/cooldown
- [ ] Knobs live: `hud_opacity` 0.6–1.0, `hud_scale` 0.9–1.15 (respects 18px floor), `timer_high_contrast` (Deck `#E8ECF1` only if applicable), `disable_damage_flash` → shape icon substitute
- [ ] Reduced-motion ON: every transition/certainty collapses to 1-frame cut, static embers, zero flashes, bus sounds only (0 direct players)
- [ ] [DEFERRED — real Deck 7" hardware] Contrast ≥4.5:1 on the 5 §12 text elements, measured (not TBD) + screenshots in evidence (closes ux-review advisory A2)

---

## Implementation Notes

*Derived from ADR-002 + hud.md + P3:*

- `HudPresenter` forwards `firma_ve_changed`, emits `hud_audio_requested` (never plays directly); VE cap Σ≤3/duelo with log (4th VE at 1.0 → +0/+0).
- Spend feedback reuses existing NW meter + body-vein throb + dry bus click — NO new zone, NO new flash (Gracia Visual).
- Saturation: one-time break to full-spectrum vitreous (handoff #6), then frozen (Gracia freezes ledgers).
- On Demand exact-numbers hold-binding stays UNCONFIRMED — do not invent; never collide with C24 or G7.

---

## Out of Scope

- #6 Clímax continuation past 94-tras-100 (owner Clímax #6); audio timbres/ducking detail (owner #16)

---

## QA Test Cases

*qa-lead QL-STORY-READY ADEQUATE 2026-09-08 — manual:*

- **AC-a — VE firma**
  - Setup: drive ev.14/15/16 + attempt illegal spend mid-VE
  - Verify: pre-light → move → fold sequence; spend rejected no-buffer
  - Pass condition: sequence exact, cap/cooldown untouched
- **AC-b — knobs**
  - Setup: sweep opacity 0.6–1.0, scale 0.9–1.15, contrast toggle, disable_flash
  - Verify: ranges clamp, floor 18px holds, shape icon replaces flash
  - Pass condition: all apply live without restart
- **AC-c — reduced-motion**
  - Setup: reduced-motion ON
  - Verify: 1-frame cuts, static embers, zero flashes across all transitions
  - Pass condition: no motion frames in capture
- **AC-d — contrast [DEFERRED]**
  - Setup: real Deck 7" @30–40cm
  - Verify: ≥4.5:1 on 5 §12 elements + screenshots to `production/qa/evidence/`
  - Pass condition: metered values logged, advisory A2 closed

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/hud-ve-knobs-evidence.md` (checklist + Deck captures + sign-off; AC-d appended at Deck session)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (VE absence behavior), Story 004 (queue baseline that reduced-motion overrides)
- Unlocks: none (last in epic)
- External: Deck hardware session for AC-d; `technical-artist` P0 emitter-cost validation pre-sprint

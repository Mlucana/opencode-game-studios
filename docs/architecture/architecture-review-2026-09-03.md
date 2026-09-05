# Architecture Review Report

> **Date**: 2026-09-03
> **Mode**: `/architecture-review` (full)
> **Engine**: Godot 4.7 (`docs/engine-reference/godot/VERSION.md`)
> **GDDs Reviewed**: 2 (`combate-parry-absorcion.md`, `maquina-estados-jefe.md`)
> **ADRs Reviewed**: 0 (none exist yet)

---

## Traceability Summary

- Total requirements: 22
- ✅ Covered: 0
- ⚠️ Partial: 0
- ❌ Gaps: 22

Every requirement below is a GAP — no ADR exists to cover it. This is the
expected state before the first `/architecture-decision`: the review's value
here is the numbered baseline (stable TR-IDs) that all future ADRs and stories
will reference.

---

## Coverage Gaps (no ADR exists)

### System 1 — combate-parry-absorcion.md

| Requirement ID | Requirement | Suggested ADR | Domain | Engine Risk |
|---|---|---|---|---|
| TR-parry-001 | Tick authority: integer-tick durations at 60Hz physics, hitstop-immune counter | `/architecture-decision tiempo-autoritativo-y-hitstop` | Timing | HIGH |
| TR-parry-002 | Diegetic time-scale without `Engine.time_scale` (scaled delta, per-node speed_scale, no `Timer`, TIME uniform, physics priority, diegetic audio) | `/architecture-decision tiempo-autoritativo-y-hitstop` | Timing/Engine | HIGH |
| TR-parry-003 | Digital-only input with binding validation, single edge-triggered attempt, `_physics_process` read, no-buffer discard | `/architecture-decision contrato-eventos-combate-jefe` | Input | MEDIUM |
| TR-parry-004 | Player state machine + bidirectional anticipation forgiveness, lockouts, interrupt table, inclusive clamps | `/architecture-decision estructura-fsm-jefe` | Gameplay | LOW |
| TR-parry-005 | Formulas F1–F8 + invariants R1–R10 as data-driven config with load-time validation gates | `/architecture-decision tuning-data-driven-y-validacion` | Data/Config | LOW |
| TR-parry-006 | Synchronous combat event bus (emits result/posture/duelo-perdido; consumes boss windows) | `/architecture-decision contrato-eventos-combate-jefe` | Events | MEDIUM |
| TR-parry-007 | Hitstop + camera + rumble contract (5-tick base, Justo bonus ≤8, physics-mode Tweens) | `/architecture-decision tiempo-autoritativo-y-hitstop` | Feedback | MEDIUM |
| TR-parry-008 | Particle pool by `finished`, ~20 draw-call worst case, semantic-direction recycle | `/architecture-decision feedback-audio-vfx-hud` | Rendering/VFX | MEDIUM |
| TR-parry-009 | Diegetic vs UI/music audio layers, harmonic precedence, bus/ducking + Deck voice budget | `/architecture-decision feedback-audio-vfx-hud` | Audio | MEDIUM |
| TR-parry-010 | Hitstop-immune HUD data contract (HP/postures/timer/grace, 40Hz coalescing) | `/architecture-decision feedback-audio-vfx-hud` | UI | LOW |
| TR-parry-011 | Cross-system contracts (consumes `angeles_absorbidos`/`bono_reliquias`, exposes event+modulator to Grace, duelo-perdido to Run, knob pair to Accessibility) | `/architecture-decision contratos-gracia-reliquias-run` | Integration | LOW |
| TR-parry-012 | Real-Deck budgets (33/50ms, P0–P5, 20-min thermal soak) | `/architecture-decision estrategia-perf-test-deck` | Performance | MEDIUM |

### System 2 — maquina-estados-jefe.md

| Requirement ID | Requirement | Suggested ADR | Domain | Engine Risk |
|---|---|---|---|---|
| TR-jefe-001 | Hierarchical FSM: 9 closed states, `En Combo` container with index, 10th-state amendment, Lucifer path | `/architecture-decision estructura-fsm-jefe` | Architecture | LOW |
| TR-jefe-002 | Synchronous dispatch (nothing outside originating call stack; no reentrancy; canonical signal names) | `/architecture-decision contrato-eventos-combate-jefe` | Events | HIGH |
| TR-jefe-003 | Combat-result bifurcation; Aturdido replaces Repliegue only at resolution instant | `/architecture-decision estructura-fsm-jefe` | Gameplay | LOW |
| TR-jefe-004 | Combo abort on any `i` → Repliegue, remainder never executes, abort event carries `i`+`N` | `/architecture-decision estructura-fsm-jefe` | Gameplay | LOW |
| TR-jefe-005 | Aturdido exits: cushion after connected punish, direct after expiry, terminal `Muerto` after lethal | `/architecture-decision estructura-fsm-jefe` | Gameplay | LOW |
| TR-jefe-006 | `Acción Especial` contract (bool + mandatory/forbidden window, own event pair, 2-of-4 split, illegal configs fail at load) | `/architecture-decision tuning-data-driven-y-validacion` | Gameplay | LOW |
| TR-jefe-007 | Fairness floor `Enfriamiento+Telegrafiado ≥ 12+margen` validated at load over system-20 data | `/architecture-decision tuning-data-driven-y-validacion` | Data validation | LOW |
| TR-jefe-008 | Owned feedback rows (start/interrupt/complete, distinct post-punish Repliegue, `Muerto`) + VE-close vs completion distinguishability | `/architecture-decision feedback-audio-vfx-hud` | Presentation | LOW |
| TR-jefe-009 | Freeze on player defeat mid-state (no further transitions or signals) | `/architecture-decision contratos-gracia-reliquias-run` | Gameplay | LOW |
| TR-jefe-010 | Dual test gates (mocked-event unit Logic + 2-case wiring integration), placeholders, debug triggers | `/architecture-decision estrategia-perf-test-deck` | Testing | LOW |

---

## Cross-ADR Conflicts

None — 0 ADRs. (Dependency cycles 1↔5 and 2↔20 are documented as data
contracts in the GDDs and need no resolution.)

## ADR Dependency Order

Empty — built as ADRs are authored. Suggested authorship order is under
Required ADRs below (time model first; everything synchronous depends on it).

## GDD Revision Flags

1. `maquina-estados-jefe.md` (E3b + tick-120 Edge row): declares border **113**
   under exclusive counting; Combate (amendment E) fixes **inclusive** counting
   with border **114**. Correct to 114 in its 4th pass — registered as debt in
   Combate itself. No index change needed (both systems already `Needs Revision`).
2. None other — `Engine.time_scale` discarded, sub-tick discarded, and
   `max_physics_steps_per_frame` as measurement confounder are already verified
   inside the GDDs against the 4.7 reference.

## Engine Compatibility Issues

- ADRs with Engine Compatibility section: 0 / 0 (none exist yet)
- Deprecated API references: none
- Stale version references: none
- `godot-specialist` consultation skipped with reason: no ADR contains
  engine-specific decisions to second-opinion.
- Inherited HIGH risk: every future ADR touching timing/input must be checked
  against `docs/engine-reference/godot/` (4.7 is beyond the training cutoff).

## Architecture Document Coverage

No `architecture.md` exists — write it via `/create-architecture` once ADRs exist.

---

## Verdict: FAIL (expected — 0 ADRs, Foundation/Core layers uncovered)

### Blocking Issues (must resolve before PASS)

1. No authoritative-time + hitstop ADR (TR-parry-001/002/007, TR-jefe-002)
2. No Combat↔Boss event-contract ADR (TR-parry-006, TR-jefe-002/003)
3. No boss-FSM-structure ADR (TR-jefe-001/003/004/005)
4. No data-driven-tuning + load-validation ADR (TR-parry-005, TR-jefe-006/007)

### Required ADRs (authorship order)

1. `/architecture-decision tiempo-autoritativo-y-hitstop`
2. `/architecture-decision contrato-eventos-combate-jefe`
3. `/architecture-decision estructura-fsm-jefe`
4. `/architecture-decision tuning-data-driven-y-validacion`
5. `/architecture-decision feedback-audio-vfx-hud`
6. `/architecture-decision contratos-gracia-reliquias-run`
7. `/architecture-decision estrategia-perf-test-deck`

Re-run `/architecture-review` after each new ADR to verify coverage improves.

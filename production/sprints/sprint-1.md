# Sprint 1 — 2026-09-08 to 2026-09-19

## Sprint Goal

HUD de combate visible en duelo con freeze correcto + firma hold verificada + CI resucitado.

## Capacity

- Total days: 10 (solo dev, ~3h/day ≈ 30h)
- Buffer (20%): ~6h reserved for unplanned work
- Available: ~24h

## Tasks

### Must Have (Critical Path, ~18h)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| hud-001 | NW Vida+Gracia widgets | gameplay-programmer | 0.4d (3h) | None (stubs) | 5 ACs story-001; evidence hud-nw-evidence.md |
| hud-002 | NE Postura+Vida jefe + ev.8 | gameplay-programmer | 0.7d (5h re-est) | hud-001; INFRA-01 stubs | 5 ACs story-002; tests/integration/ui/hud_ne_test.gd passes |
| hud-003 | Timer S + freeze-ALWAYS + Pausa | gameplay-programmer | 0.7d (5h re-est) | hud-001; INFRA-01 stubs | 4 ACs story-003; hud_timer_freeze_test.gd passes (C14) |
| M-004 | Firma hold Tipo-A | gameplay-programmer | 0.4d (3h) | M-001a surface (mock) | 3 ACs story M-004; tests/unit/menu/firma_hold_test.gd passes |
| INFRA-01 | Core/WallTick signal stubs | gameplay-programmer | 0.15d (1h) | None | Mock Resolver C-* + FSM B-* + WallTick emitters for hud-002/003 tests |
| INFRA-02 | Fix CI branch (master) | devops-engineer | 0.15d (1h) | None | tests.yml triggers on master; first green run on push |

### Should Have (4h)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| hud-004 | Alertas + cola visual + vignette | gameplay-programmer | 0.3d (2h) | hud-003 | 4 ACs story-004; frame-step evidence |
| M-006a | Reduced-motion + legibilidad | ux-designer | 0.3d (2h) | M-001a surface | MENU-17 + MENU-13 proxy 0/0 (ADVISORY) |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| — | (none committed) | | | | Deferred to Sprint 2 (see below) |

## Sprint 2 backlog (descoped by PR-SPRINT)

hud-005 (VE firma, Deck AC deferred) · M-003 (blocked by M-001a) · M-002 (partial Run #3 block) · M-001a/b, M-005, M-006b (all Blocked — unwritten ADRs + unratified budgets).

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|--------------|
| (none — Sprint 1) | | |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| No local godot binary — tests unrunnable locally | High | High | INFRA-02 first: validate via CI; install godot 4.7.2 locally in buffer time |
| Unwritten required ADRs (HUD-40Hz, arranque, checksum, preload) | Certain | Med | Stories carry Blocked placeholders; ADR track runs parallel, never inside sprint |
| Serial HUD chain 001→002→003 slips | Med | High | Re-estimated 5h Integration; Should Have absorbs spillover |
| M-003 needs Blocked M-001a surface | Certain | Low | Already descoped to Sprint 2 |
| No milestones/risk-register process debt | Certain | Low | Create skeleton dirs in buffer; no burndown baseline this sprint |

## Dependencies on External Factors

- Real Deck 7" hardware session (hud-005 AC-d + M-006a captures) — scheduled Sprint 2
- `technical-artist` P0 emitter-cost validation pre-sprint (CPUParticles2D)

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-1.md`)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged

## Gate record

- PR-SPRINT: UNREALISTIC 2026-09-08 → descoped per prescription (M-003 + hud-005 → Sprint 2; +stubs + CI fix) → plan as-written accepted by user.
- PR-EPIC: UNREALISTIC accepted-risk (see epics/index.md).
- QL-STORY-READY: hud 5/5 ADEQUATE; menu ceiling GAPS (see EPICs).

> **Scope check:** If this sprint includes stories added beyond the original epic scope, run `/scope-check [epic]` to detect scope creep before implementation begins. (INFRA-01/02 are process debt, not epic scope — no creep.)

# Sprint 2 — 2026-09-13 to 2026-09-27

## Sprint Goal

Cerrar el backlog implementable de menú+HUD (firma VE, pausa/muerte/hub, continuar/SUS) y saldar las condiciones del QA del Sprint 1; ADRs de desbloqueo en track paralelo.

## Capacity

- Total days: 10 (solo dev, ~3h/day ≈ 30h)
- Buffer (20%): ~6h reserved for unplanned work
- Available: ~24h

## Tasks

### Must Have (Critical Path, ~11h)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| hud-005 | Firma VE + gasto + knobs | gameplay-programmer | 0.4d (3h) | story-002/004 done | VE ev.14/15/16 + gasto ilegal no-buffer + knobs live + reduced-motion; AC-d Deck deferred; evidence hud-ve-knobs-evidence.md |
| m-003 | Pausa + Muerte muda + Hub | gameplay-programmer | 0.4d (3h) | M-001a surface (mock, patrón M-004) | MENU-04/14 + muerte muda + Hub SUS/stakes; evidence menu-pausa-muerte-hub-evidence.md |
| m-002 | Continuar + SUS lifecycle | gameplay-programmer | 0.7d (5h) | M-001a (mock) + M-004 done; Run #3 stub interface | spy-order + double-press SUS_CONSUMED + firma-cancel sha idéntico; tests/integration/menu/continuar_sus_test.gd passes |

Orden de ejecución: hud-005 → m-003 (define el mock M-001a una vez) → m-002 (consume M-004 done + mock).

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| QA-COND | Cierre condiciones QA Sprint 1 (captura vignette-25, verificar CI verde Run #2, sesión Deck si hay hardware) | qa-tester | 0.3d (2h) | driver F6 + Deck hw | captura en evidence + CI verde confirmado; Deck como carryover explícito si no hay acceso |
| ADR-TRACK | arranque/router, preload/baker/veil, checksum + ratificación PERF-MENU (paralelo, fuera del burndown) | technical-director | — | — | ADRs Accepted; desbloquean el Nice (`/architecture-decision`) |

### Nice to Have (condicional — SOLO si su ADR aterriza mid-sprint; orden de pull: m-001a → m-001b → m-006b → m-005)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| m-001a | Shell S0/S1/S2 + foco | gameplay-programmer | 0.4d | arranque/router ADR Accepted | ACs story-m001a-shell-focus.md |
| m-001b | Splash + A-spam | gameplay-programmer | 0.3d | preload/baker/veil ADR + m-001a | ACs story-m001b-splash.md |
| m-006b | PERF-MENU budgets | gameplay-programmer | 0.3d | ratificación budgets + preload ADR + m-001b | ACs story-m006b-perf-budgets.md |
| m-005 | S4/S5 + cero-IO | gameplay-programmer | 0.7d | checksum ADR + M-002 done + M-004 | ACs story-m005-s4-s5-zeroio.md |

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|--------------|
| hud-005 AC-d (contraste Deck medido) | Sin hardware Deck en Sprint 1 | Incluido en hud-005 (deferred a sesión Deck) |
| m-001a/b, m-005, m-006b | ADRs sin escribir (arranque, preload, checksum, budgets) | Condicional (ver Nice to Have) |
| QA conds Sprint 1 (captura vignette-25, Deck, sign-off, CI) | Pendientes al cierre | Should Have QA-COND |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| m-002 subestimado (Integration L, 4 ACs; hud-002/003 pidieron re-est a 5h) | Med | Med | m-002 último; congelar stub `instantiate_run`/`run_viva_visible` antes de codificar; slack ~13h absorbe |
| Deriva del mock M-001a → rework al llegar router real (deuda ya asumida en M-004) | High | Low | Contrato mock documentado; prohibido `change_scene` real; wiring como TODO explícito |
| Sin hardware Deck 7" (hud-005 AC-d + M-006a) | High | Low | Timebox; carryover explícito, no bloquea cierre |
| Deuda proceso heredada: sin milestones/, risk-register/, TR baseline, control-manifest | Certain | Low | Anotado; esqueleto de dirs en buffer si sobra tiempo |

## Dependencies on External Factors

- Sesión hardware Deck 7" (hud-005 AC-d + M-006a) — timebox, carryover explícito si no hay acceso
- `technical-artist` P0 emitter-cost validation pre-sprint (hud-005, heredado Sprint 1)
- Run #3 diseñado (desbloqueo total de m-002; stub de interfaz hasta entonces)

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-2.md`)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged

## Gate record

- PR-SPRINT: REALISTIC 2026-09-13 (full mode) → Must 1.5d ≈11h vs ~24h disponibles (~46% carga); bloqueos correctamente fuera del compromiso; sin prescripción de descope. Orden de pull del Nice si el track ADR entrega: m-001a → m-001b → m-006b → m-005.
- Pull order note: m-005 exige además M-002 done.

> **Scope check:** If this sprint includes stories added beyond the original epic scope, run `/scope-check [epic]` to detect scope creep before implementation begins. (QA-COND/ADR-TRACK are process debt, not epic scope — no creep.)

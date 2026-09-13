# QA Sign-Off Report: Sprint 1
**Date**: 2026-09-10
**Goal**: HUD de combate visible en duelo con freeze correcto + firma hold verificada + CI resucitado

## Test Coverage Summary

| Story | Type | Auto Test | Manual QA | Result |
|---|---|---|---|---|
| hud-001 NW Vida+Gracia | UI | — | PASS (3 capturas 1280×800) | PASS |
| hud-002 NE Postura+Vida jefe | Integration | PASS 9/9 | — | PASS |
| hud-003 Timer+freeze+Pausa | Integration | PASS 8/8 | — | PASS |
| hud-004 Alertas+cola+vignette | UI | PASS 9/9 | PARTIAL (1 captura pte.) | PASS WITH NOTES |
| M-004 Firma hold Tipo-A | Logic | PASS 8/8 | — | PASS |
| M-006a Reduced-motion | UI | PASS 6/6 (proxy) | PARTIAL (Deck pte.) | PASS WITH NOTES |
| INFRA-01 stubs | proceso | (ejercitados por hud-002/003) | — | PASS |
| INFRA-02 CI | proceso | YAML válido, triggers master | run pte. push | PASS WITH NOTES |

Suite total: 125/125 verde (primer verde total del proyecto).

## Bugs Found

Ninguno. (Deuda registrada, no bugs: paleta GRIS_MEDIO sin ruling, vignette-acoplada-a-vida, readout ≤1-frame stale, l10n runtime sin tablas, main_scene→driver, TR-hud/menu sin baseline.)

## Verdict: APPROVED WITH CONDITIONS

**Conditions**:
1. Captura `hud-nw-vignette.png` (vida 25, driver tecla 1×3).
2. Sesión hardware Deck 7" combinada (story-005 + M-006a).
3. Sign-off qa-lead formal.
4. Primer run CI verde tras el push (triggers ya en master).

## Next Step

Commit + push (dispara el CI). Luego `/sprint-plan new` (Sprint 2: backlog Nice + deuda) o `/retrospective` del Sprint 1.

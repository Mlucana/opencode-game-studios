# Epic: HUD de Combate

> **Layer**: Presentation
> **Diseño**: `design/ux/hud.md` Rev-2 (el spec UX ES el diseño — sin GDD; systems-index #13 Designed 2026-09-08)
> **Architecture Module**: CombatHUD (13)
> **Status**: Ready (implementation Blocked — required ADRs unwritten, see below)
> **Stories**: 5 stories (QL-STORY-READY 5/5 ADEQUATE 2026-09-08)
> **PR-EPIC**: UNREALISTIC 2026-09-08 — proceeding per user risk acceptance (7 structural points acknowledged; stories will carry Blocked placeholders until required ADRs exist)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | NW Vida + Gracia widgets | UI | Ready | ADR-002 parcial |
| 002 | NE Postura + Vida jefe + caída ev.8 | Integration | Ready | ADR-002 |
| 003 | Timer S + freeze-ALWAYS + Pausa | Integration | Ready | ADR-001 |
| 004 | Alertas + cola visual + vignette | UI | Ready | N/A (presentation rule) |
| 005 | Firma VE + gasto + knobs + Deck contraste | UI | Ready (AC-d deferred Deck) | ADR-002 parcial |

## Overview

Overlay persistente durante el duelo activo + Hub/entre-duelos: Vida jugador (NW), Medidor Gracia vitral (NW), Postura + Vida jefe (NE, solo en duelo), Timer castigo 120 ticks como barra (S, solo Aturdido), alertas flash+vignette, firma VE y feedback de gasto reutilizando el medidor existente. Centro 60% libre siempre; HUD a 1.0x durante freeze total diegético 0%.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: tiempo-autoritativo-y-hitstop | WallTick pared-clock + freeze counter; DiegeticTick held by resolver | HIGH (SceneTree.paused / PROCESS_MODE_ALWAYS unverified at pin 4.7.2) |
| ADR-002: contrato-eventos-combate-jefe | B-*/C-* naming, payload closure, orden cierre→resultado→transición | HIGH (default-sync dispatch V1 pending) |
| (required, unwritten): HUD-40Hz | Latch+hold 2 frames render, juicio en ticks pared idénticos | HIGH — BLOCKS implementation |
| (required, unwritten): arranque/router | `change_scene` único, splash, cableado final `set_pausa_visual` | MEDIUM — BLOCKS Pausa wiring |
| (required, unwritten): checksum/canonicalización | SHA-256, verify poso decreciente / n>3 sin fabricar monotonicidad | LOW — BLOCKS Decisión-adjacent verifies |

## GDD Requirements

Sin TR-hud-* en `docs/architecture/tr-registry.yaml` (v2: solo parry+jefe). Requisitos fuente (untraced — registrar vía `/architecture-review` Fase 8 antes de Producción):

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-hud-??? | Vida jugador NW event-driven + flash #C75C4A ev.5 + HUD ALWAYS en freeze (C14) | ❌ No ADR (HUD-40Hz pending) |
| TR-hud-??? | Postura NE 4 bloques, caída en ev.8, quieta en VE (firma V6) | ADR-002 ✅ (partial — orden de señales) |
| TR-hud-??? | Vida jefe NE solo en Castigo conectado (daño bruto IA D6) | ❌ No ADR |
| TR-hud-??? | Timer castigo S como barra luminancia 120 ticks, pausado en Pausa | ❌ No ADR (HUD-40Hz pending) |
| TR-hud-??? | Medidor Gracia NW vitral, earn/gasto/saturación solo interpola (owner #5) | ADR-002 ✅ (partial — Ledger events read-only) |
| TR-hud-??? | Cola visual 7 niveles, nunca dos flashes mismo tick (retrasa 1 tick) | ❌ No ADR |
| TR-hud-??? | Budget ≤15% pantalla, draws 1–3, texto ≥18px Deck, knobs hud_opacity/scale | ❌ No ADR |
| TR-hud-??? | Reduced-motion corte 1 frame, contraste 4.5:1 medido en Deck | ❌ No ADR (medición Deck pending) |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/ux/hud.md` (DEC-adjacent + Cross-Reference Check) are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`
- Contrast ratios measured on real Deck hardware (A2 advisory closed)
- Required ADRs (HUD-40Hz, arranque/router, checksum) Accepted

## Next Step

Run `/create-stories hud-combate` to break this epic into implementable stories.

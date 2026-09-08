# Epic: Menú Principal y Flujo de Pantallas

> **Layer**: Presentation
> **GDD**: `design/gdd/menu-principal-y-flujo-de-pantallas.md` (Needs Revision — Rev2 accepted without re-review)
> **Architecture Module**: MenuShell (15)
> **Status**: Ready (implementation Blocked — required ADRs unwritten + Run #3 undesigned, see below)
> **Stories**: 8 stories (QL-STORY-READY ceiling GAPS 2026-09-08 — GDD unstable, no TRs, no Run #3, no qa-plan; revisions applied at write time)
> **PR-EPIC**: UNREALISTIC 2026-09-08 — proceeding per user risk acceptance. Known hard-block: dura dependency on Gestión de Run #3 (no GDD); shell-only stories first, Run-integration stories Blocked until #3 designed.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| M-001a | Shell S0/S1/S2 + foco | UI | Blocked | arranque/router (unwritten) |
| M-001b | Splash + A-spam | UI | Blocked | preload/baker/veil (unwritten) |
| M-002 | Continuar + SUS lifecycle | Integration | Ready (partial Run #3 block) | ADR-001 parcial |
| M-003 | Pausa + Muerte muda + Hub | UI | Ready (open items tracked) | ADR-001 |
| M-004 | Firma hold Tipo-A | Logic | Ready (`firma_hold_ms`=1000) | N/A (R4 rule) |
| M-005 | S4/S5 + cero-IO | Integration | Blocked | checksum (unwritten) |
| M-006a | Reduced-motion + legibilidad | UI | Ready (ADVISORY) | N/A |
| M-006b | PERF-MENU budgets | UI | Blocked | preload + ratify pending |

## Overview

Shell de destinos y fachada de Guardado: MenuPrincipal (Comenzar/Continuar/Ajustes + estados S0–S5 + firma hold Tipo-A), Pausa duelo-only, Hub lines, Muerte muda, Decisión enrutada (router #15 post-reliquia→Decisión→Hub), splash ≤2.0s skippable. Foco borde 2px + cuneta 0 glow, trampa en modales, navegación completa por mando, cero IO directo desde assembly (MENU-08).

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: tiempo-autoritativo-y-hitstop | Reloj pared vs diegético; Pausa congela timers (120 ticks no cuenta) | HIGH |
| ADR-002: contrato-eventos-combate-jefe | `transicion_solicitada`, intenciones a Run/Audio | MEDIUM |
| ADR-003: bus Hitstop | Timbres/crossfades por bus, propiedad #16 | LOW |
| (required, unwritten): arranque/router | `change_scene` único, splash ≤2.0s, foco tras splash, swallow 200ms | MEDIUM — BLOCKS shell wiring |
| (required, unwritten): checksum/canonicalización | Códigos S4/S5, resumen display-safe, catálogo de motivos | LOW — BLOCKS S4/S5 stories |
| (required, unwritten): preload/baker/veil | Splash assets, veil progress, Hub→Duelo budgets | MEDIUM — BLOCKS PERF-MENU stories |

## GDD Requirements

Sin TR-menu-* en `docs/architecture/tr-registry.yaml` (menu TRs propuestos en architecture baseline, no registrados). Cobertura UNCERTAIN hasta `/architecture-review` Fase 8; GDD fuente inestable (Needs Revision):

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-menu-??? | MENU-01/02 boot frío + Continuar S2 con subtítulo y foco inicial | ❌ No ADR (arranque pending) |
| TR-menu-??? | MENU-04 Pausa duelo-only {Reanudar, Abandonar, Ajustes}, sin Continuar | ❌ No ADR (arranque pending) |
| TR-menu-??? | MENU-06 foco gamepad-only, trampa modal, 0 glow | ❌ No ADR |
| TR-menu-??? | MENU-08 cero IO directo (oracle FS fuera de persistencia/) | ADR-001 ✅ (partial — SaveIo seam) |
| TR-menu-??? | MENU-11 doble-press mismo-tick dedupe + AC-R9-01 backend | ❌ No ADR |
| TR-menu-??? | MENU-12 splash ≤2.0s + A-spam 0 activaciones | ❌ No ADR (preload pending) |
| TR-menu-??? | MENU-13 Deck 7" legibilidad + proxy 18px/safe-zone (ADVISORY) | ❌ No ADR |
| TR-menu-??? | PERF-MENU-01..04 budgets provisionales (ratificar producer) | ❌ No ADR |
| TR-menu-??? | Back-link Decisión: tabla + inventario MENU_DECISION_* + foco neutro | ❌ No ADR (owner #5/#15 joint) |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria MENU-01..18 + PERF-MENU from the GDD are verified
- All Logic and Integration stories have passing test files in `tests/`
- UI stories have evidence docs with sign-off in `production/qa/evidence/`
- GDD re-review to APPROVED (PR-EPIC point 5 closed)
- Run #3 designed (PR-EPIC point 2 closed) before Run-integration stories start
- Required ADRs (arranque/router, checksum, preload/baker/veil) Accepted

## Next Step

Run `/create-stories menu-principal` to break this epic into implementable stories.

# Story 002: NE Postura + Vida jefe + caída ev.8

> **Epic**: HUD de Combate (`hud-combate`)
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M (4h)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` not yet created
> **Last Updated**: 2026-09-10

## Context

**Diseño**: `design/ux/hud.md` Rev-2 (§HUD Elements: Postura enemigo, Vida jefe; §Dynamic Behaviors duelo/VE)
**Requirement**: `TR-hud-???` *(warning: no TR baseline — register via `/architecture-review` Fase 8)*

**ADR Governing Implementation**: ADR-002 §2–§3 (señales B-*/C-*, orden fijo cierre→resultado→transición; `parry_resuelto(resultado, window_id, tick, delta, postura_resultante)`; payloads corruptos → RUNTIME_DROP + WARN + counter, nunca skip silencioso)
**ADR Decision Summary**: BossFSM emits windows/transitions (B-*), CombatResolver emits resolution (C-*); HUD subscribes read-only with reentrancy guard; VE ⇒ delta −1; `combo_abortado(i,N)` payload is normative (C3b reads it, never infers).

**Engine**: Godot 4.7.2-stable | **Risk**: HIGH
**Engine Notes**: Default-sync signal dispatch unverified at pin (V1 tests pending); test seams use `signal_order_spy.gd` shared-list spy (assert order *between* distinct signals — no framework covers this natively).

**Control Manifest Rules (this layer)**: N/A (manifest missing) — fallback: no cross-module state touches; HUD reads, never writes.

---

## Acceptance Criteria

*From `design/ux/hud.md`, scoped to this story:*

- [ ] NE zone (Postura + Vida jefe) appears only in duel; collapses outside (no entry animation)
- [ ] Postura 4-block bar drops visibly on combo-complete ev.8, simultaneous with entry transient (Impacto R1)
- [ ] `set_postura()` ignored during active VE — absence IS the signature (V6)
- [ ] Boss HP thin bar changes only on connected Castigo damage (bruto `dano` 30/40/50; `vida_max_angel` 120/200/300 per tríada — IA D6)
- [ ] Corrupt `combo_abortado` payload (i/N out of range) → RUNTIME_DROP + WARN + counter, no crash, no silent skip

---

## Implementation Notes

*Derived from ADR-002 Decision §§1–3:*

- Connect B-*/C-* with default flags (synchronous, same-stack); assert fixed order `golpe_finalizado/cerrada → parry_resuelto → estado_ingresado` via `signal_order_spy` (count + order, never final-state inspection — C4a/E2 pattern).
- Reentrancy guard: HUD handlers assert read-only (mirror Feedback D3 `_in_resolution` pattern); never emit gameplay signals from HUD.
- `postura_blocks.gd`: 4 segmented blocks + latch+hold; `CombatHud.set_postura()` early-returns while VE active.
- Until Core epics exist, drive with harness stubs (mock Resolver/FSM emitters); swap to real emitters without HUD changes.

---

## Out of Scope

- Story 001 (NW), 003 (timer/freeze), 004 (queue), 005 (VE spend/knobs)
- Boss HP *numbers* On Demand (unconfirmed binding — hud.md OQ)

---

## QA Test Cases

*qa-lead QL-STORY-READY ADEQUATE 2026-09-08 — automated (gdUnit4 scene_runner + signal_order_spy):*

- **AC-a — NE duel-only**
  - Given: HUD + mock Ledger/FSM
  - When: enter/exit duel
  - Then: NE visible only in duel, collapsed otherwise
  - Edge cases: duel re-entry, duel→Hub cut
- **AC-b — ev.8 Postura drop**
  - Given: duel, Postura 4 blocks
  - When: emit combo-complete ev.8
  - Then: bar −1 same tick the entry transient shows
  - Edge cases: ev.8 at Postura 0 (→ Aturdido path, not negative)
- **AC-c — VE absence V6**
  - Given: VE active
  - When: `set_postura()` called
  - Then: bar unchanged
  - Edge cases: VE close resumes updates next tick
- **AC-d — Boss HP Castigo-only**
  - Given: boss HP 100
  - When: chip/non-Castigo damage vs Castigo 30/40/50
  - Then: bar changes only on Castigo, exact bruto amounts
  - Edge cases: overkill clamp, repeated Castigos
- **AC-e — corrupt abort payload**
  - Given: RUNTIME_DROP counter 0
  - When: emit malformed `combo_abortado`
  - Then: drop + WARN + counter+1, no crash
  - Edge cases: double-corrupt stream, valid-after-corrupt recovery

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/ui/hud_ne_test.gd` — must exist and pass (OR documented playtest)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (presenter pattern + P1 bar infra)
- Unlocks: Story 005 (VE signature builds on NE absence behavior)
- External: CombatResolver C-* + BossFSM B-* emitters (stubbed until Core epics land)

## Completion Notes
**Completed**: 2026-09-10
**Criteria**: 5/5 passing (integration test, BLOCKING gate)
**Deviations**: test de reentrada duelo→hub solo asevera estado final (intermedio no capturado — follow-up menor); `push_aborto_combo` válido sin efecto visual (i/N es de Feedback-4/Sonoro-16, documentado); TR-hud-* sin baseline (pte. architecture-review Fase 8)
**Test Evidence**: tests/integration/ui/hud_ne_test.gd — 9/9 verde, 232ms, gdUnit4 6.2.0 (requirió instalar addons/gdUnit4, perdido en la migración)
**Code Review**: APPROVED WITH SUGGESTIONS (guarda solo-cuenta-reentrada; fix `FuenteNueve: Node` para `bind()`; fix `:=` Variant en test)

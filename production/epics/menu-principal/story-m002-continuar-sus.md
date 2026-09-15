# Story M-002: Continuar + SUS lifecycle

> **Epic**: Menú Principal y Flujo de Pantallas (`menu-principal`)
> **Status**: Complete (partial block resuelto vía stub C1 frozen; interior Run #3 sigue Out of Scope)
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L (5h)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` not yet created
> **Last Updated**: 2026-09-13

## Context

**GDD**: `design/gdd/menu-principal-y-flujo-de-pantallas.md` + `design/gdd/guardado-de-progreso.md` §R9 (AC-R9-01a/b/e backend)
**Requirement**: `TR-menu-???` *(warning: no TR baseline)*

**ADR Governing Implementation**: ADR-001 partial (SaveIo seam: FS real only in `tests/integration/`, in-memory double in unit; `SaveIoSpy` reads/writes observable) + Guardado R9 design (rename save→validating, comparator eps 1e-9 excl timestamp/playtime).
**ADR Decision Summary**: Menu never touches disk (MENU-08) — all persistence via facade calls; `per_checksum_ref` freshness rules owned by #12.

**Engine**: Godot 4.7.2-stable | **Risk**: MEDIUM
**Engine Notes**: `FileAccess.store_*→bool` LOW; thread-id spy for sync-writes-on-gameplay-thread assertion (AC-R4-02a pattern).

**Control Manifest Rules (this layer)**: N/A.

---

## Acceptance Criteria

- [ ] Continuar → spy order `rename(save→validating)` < `instantiate_run`; rehydration by comparator (eps 1e-9 excl timestamp/playtime); `validating` deleted at `run_viva_visible` (AC-R9-01a)
- [ ] Second continuar (double-press <200ms incl. two-device same-tick) → no-op `SUS_CONSUMED`, `instantiations==1`, button disabled same frame (AC-R9-01b + MENU-11)
- [ ] Comenzar-with-SUS firma cancel/soltar/kill mid-firma → sha256 identical, still S2 (MENU-02c); S2→S3 atomic on full firma
- [ ] Hub→menu exit needs no action; sha identical at flush confirm (MENU-15)

---

## Implementation Notes

*From ADR-001 SaveIo seam + Guardado R9:*

- Facade-injectable `SaveIo`; unit tests use in-memory double, integration uses real FS in `tests/integration/`.
- Comparator interim field-by-field until official run-vs-rehydrated comparator lands (AC-R9-03 BLOCKED-note honored: RNG `posicion_rng` advances, `semilla_run` preserved).
- Crash-validating without live marker: ONE recovery iff no `suspend.recovered` marker; second press → `SUS_CONSUMED` no-op (AC-R9-01e).

---

## Out of Scope

- Run #3 internals (`instantiate_run` body, timeout/rechazo of `run_viva_visible` — partial block)
- M-004 (firma hold mechanics — this story consumes its verdict)

---

## QA Test Cases

*qa-lead 2026-09-08 — automated `tests/integration/menu/continuar_sus_test.gd` (scene_runner + fake clock + FS-spy):*

- **AC-a — consume order**
  - Given: S2 mock + `validating` present
  - When: press Continuar
  - Then: spy `rename(save→validating)` < `instantiate_run`; `validating` deleted at `run_viva_visible`
  - Edge cases: invalid SUS → discard → S1 + exact `MENU_REASON_*`; comparator eps 1e-9 excl timestamp/playtime
- **AC-b — double-press**
  - Given: S2
  - When: double-press <200ms incl. two-device same-tick
  - Then: 2nd = no-op `SUS_CONSUMED`, `instantiations==1`, button disabled same-frame
  - Edge cases: cancel/kill mid-firma → sha256 identical, still S2; Hub→menu exit → sha identical at flush-confirm
- **Sprint 2 additions (qa-plan 2026-09-13, GDD-derived):**
  - Staged-journal order per Guardado R9: rename(save→validating) < validate < promote < delete at `run_viva_visible`; second Continuar re-reads disk → SUS_CONSUMED no-op
  - Crash-validating without live marker: ONE recovery iff no `suspend.recovered` marker; second strike → S1, PER intact (AC-R9-01e)
  - Comparator interim field-by-field: `posicion_rng` advances, `semilla_run` preserved (AC-R9-03 BLOCKED-note honored)
  - "Todo idéntico" excludes timestamp/playtime; invalid SUS → discard → S1 + exact `MENU_REASON_*`

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/menu/continuar_sus_test.gd` — must exist and pass (OR documented playtest)

**Status**: [x] Created `tests/integration/menu/continuar_sus_test.gd` — 17/17 green (suite total 173/173)

---

## Dependencies

- Depends on: M-001a (surface), M-004 (firma verdict protocol)
- Partial block: Run #3 (`instantiate_run`, `run_viva_visible`) — stub interface until #3 designed
- Unlocks: M-005 (S4/S5 reuse the validating/consume machinery)

---

## Completion Notes
**Completed**: 2026-09-13
**Criteria**: 4/4 passing (consume, doble-press, firma, Hub) + edges (staged, ONE-recovery, second-strike, hilos, timeout-stub, G1/G2/G3)
**Deviations**: None blocking. C1/C2 pineados (stub Run #3 frozen, comparador interim solo-test). Advisory → tech-debt: comparador oficial, FS real, interior Run #3, vista M-001a, endurecer null-checks en Run #3.
**Test Evidence**: Integration — `tests/integration/menu/continuar_sus_test.gd` (17/17 green; suite total 173/173, 0 failures)
**Code Review**: APPROVED WITH SUGGESTIONS → fixes W1-W12 + G1-G3 + asserts → QL-TEST-COVERAGE ADEQUATE + LP-CODE-REVIEW APPROVE (2ª pasada)

# Story M-005: S4/S5 + cero-IO

> **Epic**: Menú Principal y Flujo de Pantallas (`menu-principal`)
> **Status**: Blocked — BLOCKED: checksum/canonicalización ADR unwritten (S4/S5 codes, display-safe resumen, motivo catalog, sha-oracle undefined)
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: L (5h)
> **Manifest Version**: N/A — `docs/architecture/control-manifest.md` not yet created
> **Last Updated**: —

## Context

**GDD**: `design/gdd/menu-principal-y-flujo-de-pantallas.md` (S4/S5 flows) + Guardado §Fachada (codes, `detalle_perdida`, `estado_red`)
**Requirement**: `TR-menu-???` *(warning: no TR baseline)*

**ADR Governing Implementation**: (unwritten: checksum/canonicalización — SHA-256, auto-excluido R6 Guardado) — placeholder. MENU-08 oracle defined in GDD (fail any FS outside `persistencia/`).
**ADR Decision Summary**: Pending ADR must define: canonical bytes for sha, code catalog (S4 causes, S5 outcomes incl `SUS_VERSION_DISCARD`), display-safe resumen fields + cache/invalidation policy (ratify with Guardado).

**Engine**: Godot 4.7.2-stable | **Risk**: MEDIUM
**Engine Notes**: FS-spy oracle identical to Guardado AC-R1-02/MENU-08; `.bak` integrity pre-restore checksum; never auto-overwrite, never auto-restore.

**Control Manifest Rules (this layer)**: N/A.

---

## Acceptance Criteria

- [ ] S4 → exactly {Reset, Restaurar .bak (only if intact), Diagnóstico+cause+version}; Continuar/Migrar/Comenzar absent (not disabled); 30s idle + diag open/close → sha identical, 0 writes (MENU-07a/b)
- [ ] S4 with intact `.bak` → Restore via firma → S1 with pre-restore checksum + log, never automatic; without intact `.bak` the option does not exist (MENU-07c)
- [ ] S5 → exactly {Migrar, Reset}; migrate-OK → S1; no-route/fail → S4 surface (MENU-09/18)
- [ ] Full S0–S5 walk incl. firma-cancel with FS oracle → 0 direct reads AND writes from menu assembly (MENU-08)

---

## Implementation Notes

Reset/Migrar execute ONLY as facade calls (menu never implements deletion); S4-future (version newer than build): no parse, hash intact, surface Reset/documented-only path. EACCES-real protocol (AC-R8-01g) stays manual.

---

## Out of Scope

- Guardado backend implementations (owner #12); M-006b PERF

---

## QA Test Cases

*qa-lead 2026-09-08 — automated `tests/integration/menu/s4_s5_zeroio_test.gd`:*

- **AC-a — S4 surface**
  - Given: S4 fixture (sha pinned) ± intact `.bak`
  - When: walk + 30s idle + diag open/close
  - Then: exact option set; sha identical; 0 writes
  - Edge cases: `.bak` corrupt → option absent; S4-future → no parse
- **AC-b — S5 flow**
  - Given: S5 N-1 fixture
  - When: migrate OK / no-route / fail
  - Then: S1 / S4-surface respectively; run suspended lost is announced pre-migrate
  - Edge cases: kill mid-migrate → S4, never half-state
- **AC-c — zero-IO**
  - Given: FS-spy failing any `FileAccess/DirAccess/ConfigFile/ResourceLoader-user://` outside `persistencia/`
  - When: full S0–S5 walk incl. firma-cancel
  - Then: 0 direct reads AND writes from menu assembly
  - Edge cases: Reset/Migrar issued only as facade calls (spy asserts call-target)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/menu/s4_s5_zeroio_test.gd` — must exist and pass (OR documented playtest)

**Status**: [ ] Not yet created (Blocked — see top)

---

## Dependencies

- Depends on: checksum ADR (unwritten); M-002 (validating machinery); M-004 (firma widget)
- Unlocks: none (terminal backend story)

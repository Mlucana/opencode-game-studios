# Review Log — Guardado de Progreso (`design/gdd/guardado-de-progreso.md`)

## Review — 2026-09-04 — Verdict: MAJOR REVISION NEEDED
Scope signal: L (presión al alza hacia XL por 9 sistemas declarados; con contratos provisionales acotados se mantiene en L)
Specialists: game-designer, systems-designer, qa-lead, ux-designer, godot-specialist + creative-director (síntesis senior)
Blocking items: 12 | Recommended: 7
Summary: La irreversibilidad era condicional a la suerte del filesystem (R4), el consumo-por-intención borraba runs honestas de 30–45 min para frenar un dupe ya aceptado (R9), y el pipeline embarcaba `per_checksum_ref` rancia en cada escritura (R6) — combinado con dos fórmulas incorrectas, matriz de transiciones inimplementable, fachada con Menú ausente y plan de tests no ejecutable. Sello CD-GDD-ALIGN 2026-09-03 revocado.
Prior verdict resolved: First review.

## Revisión — 2026-09-04 — Verdict: APPROVED (Rev 2)
Revisión conjunta en la misma sesión: 12 bloques resueltos (frontera de durabilidad R4, staged journal R9, ref pre-escritura + SHA-256 canónico R6, fórmulas playtime/contador/fragmentos corregidas, matriz S0–S5b reescrita + R7a, §Fachada publicada, validador pre-`stringify`, sin-hilos + lockfile best-effort + Cloud re-etiquetado, ~45 ACs partidos con seams `SaveIo`/`Clock`, restore consentido S4) + 7 recomendados (señal segura, códigos de motivo, validador por niveles, R5 fail-closed, round-trip verbatim). Adjudicaciones de usuario: staged journal · R5 hardline + señal segura · PER-first · restore consentido.
Re-review omitida por decisión de usuario ([B] Accept and mark Approved). Deuda viva: artefactos N-1 (GAP-09), comparador oficial, ADR checksum (confirmación), sidecar `save_health.json`, decisión de lock, catálogos #3/#5/#9/#10/#17, contraparte Menú Rev 2 (§Fachada).

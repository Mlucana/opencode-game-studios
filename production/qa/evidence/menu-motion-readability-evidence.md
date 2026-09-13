# Evidencia — M-006a Reduced-motion + legibilidad

**Story**: `production/epics/menu-principal/story-m006a-motion-readability.md`
**Fecha draft**: 2026-09-10
**Engine**: Godot 4.7.2-stable (gdUnit4 6.2.0)

**Estado**: PARCIAL — proxy automatizado escrito (pendiente corrida);
hardware Deck PENDING Sprint 2 (combinada con story-005 AC-d).

## Automatizado (proxy AC-a + AC-b sin hardware)

`tests/integration/ui/menu_motion_readability_test.gd` — 6 tests, tscn real:

- Propagación reduced-motion a 6 zonas (NW/NE/S/vignette/esquirlas/bloques).
- Flash-icono: fill intacto `#C7CDD6` + forma activa (2f) en NW y vignette.
- Audio: claves `hud_fallo` + `hud_firma_ve` al bus; 0 hijos en el presenter.
- Proxy legibilidad: labels ≥18px barriendo el árbol (0/0); todo Control en
  IGNORE (nada de hover, foco solo mando/teclado); skip global inmediato.
- Resultado corrida: PASS 2026-09-10 — 6/6 verde, 82ms (suite integration/ui 32/32).

## Hardware (PENDING — sin Deck en esta estación)

- [ ] Deck 7" @30–40cm: checklist art-bible 7.2 + capturas (combinar con
  story-005 sesión Deck).
- [ ] Transiciones M-001a: foco mismo-frame con reduced-motion (la shell no
  existe; el mecanismo `tick_apertura()` ya está verificado en M-004).

## Sign-off

- [ ] Corrida 6/6 verde + sesión Deck + ux-designer (ADVISORY, Sprint 2)

# Evidencia — hud-004 Alertas + cola visual + vignette

**Story**: `production/epics/hud-combate/story-004-alertas-cola-vignette.md`
**Fecha draft**: 2026-09-10
**Engine**: Godot 4.7.2-stable (gdUnit4 6.2.0)

**Estado**: PARCIAL — test automatizado escrito (supera el frame-step manual
exigido, que era ADVISORY); pendiente de corrida en Godot + 1 captura.

## Automatizado (supera lo exigido)

`tests/integration/ui/hud_cola_vignette_test.gd` — 9 tests, tscn real, reloj
manual (`set_process(false)` en capa/NW/vignette/gracia para determinismo):

- Cola: alto-suprime-bajo + re-despacho ejecuta el efecto REAL; 5 pares
  adyacentes de los 7 niveles; muerte+fails mismo tick (gana muerte, fallo
  diferido 1 tick).
- Supresión: muerte 800ms (1799 muda / 1800 ejecuta); fallo→VE 200ms
  (1199 encola / 1200 ejecuta — borde `<`, no `<=`).
- Vignette: progresiva por vida (0 → 0.42 → 1.0); tinta y flash en contadores
  separados (regla de oro); flash 2 frames + skip; latch-hold 2f; pausa congela.
- Resultado corrida: PASS 2026-09-10 — 9/9 verde, 130ms (suite integration/ui 26/26 con hud_ne + timer_freeze).

## Manual

- `hud-nw-flash.png` (hud-001): flash #C75C4A + triángulo + franja superior de
  `HudVignette.flash_fallo()` — evidencia de que el evento lógico único
  NW+vignette dispara junto. PASS (revisado 2026-09-10).
- Vignette progresiva a vida baja: PENDING — 1 captura con driver (tecla `1`×3
  hasta 25/100) mostrando tinta en bordes sin flash. Archivo esperado:
  `hud-nw-vignette.png`.

## Deuda cerrada aquí

- Flash vignette en ms (33ms = 3 frames + congelaba en hitstop, clase B1 de
  hud-001) → convertido a `FLASH_FRAMES=2` (`hud_vignette.gd`). Reloj de pulso
  decorativo `_tiempo_ms` intacto a propósito (fuera de alcance).

## Sign-off

- [ ] Corrida 9/9 verde + captura `hud-nw-vignette.png` + qa-lead (Sprint 2 Deck)

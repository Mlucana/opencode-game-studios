# Evidencia — hud-005 Firma VE + gasto + knobs + reduced-motion

**Story**: `production/epics/hud-combate/story-005-firma-ve-gasto-knobs.md`
**Fecha draft**: 2026-09-13
**Engine**: Godot 4.7.2-stable (gdUnit4 6.2.0)
**Código revisado**: `src/ui/hud_presenter.gd` (`push_gasto`), `src/ui/combat_hud.gd`
(CIERRE arbitrado + `_aplicar_cierre_ve`), `src/ui/gracia_shards.gd` + `src/ui/postura_blocks.gd`
(hold gateado por reduced-motion), `src/ui/hud_nw.gd` + `src/ui/hud_vignette.gd`
(cero flashes con reduced-motion), `tests/helpers/mock_ledger_gracia.gd` (stand-in #5),
`tests/integration/ui/hud_ve_gasto_knobs_test.gd` (13 tests).
**Manifiesto**: N/A — `docs/architecture/control-manifest.md` no existe (anotado, no penalizado).
**Estado**: PARCIAL — suite 13/13 verde (ui 63/63); 3 capturas PASS revisadas 2026-09-13 (auto-drivers Sprint 2); pendiente sesión Deck (AC-d).

> Nota: sin baseline TR (`TR-hud-???` pendiente de `/architecture-review` Fase 8,
> como en las 4 stories previas). La corrección de la *decisión* de gasto es de #5/G7
> (gate Logic BLOCKING suyo); aquí solo se verifica su *reflejo* en el HUD vía mock
> Ledger como fuente de verdad.

## AC-a — firma VE + gasto (ev.14/15/16, G7)

**Estático PASS (revisión)**: `HudPresenter.push_gasto()` refleja sin decidir
(`hud_presenter.gd`, tras `push_firma_ve`): ACEPTA → `set_gracia` existente + `hud_gasto_aceptado`;
RECHAZO → `hud_gasto_denegado`, sin tocar medidor/cap/cooldown (no-buffer por construcción:
sin cola en este path). `CombatHud.set_firma_ve` arbitra CIERRE_SIN_PARAR como nivel FIRMA_VE
(`combat_hud.gd:set_firma_ve` + `_aplicar_cierre_ve`): pre-light(5) → parada(3) → fold(3)
pasan por `_anunciar`, nunca dos flashes el mismo tick. Clave VE única `hud_firma_ve`
(sin cambios — la fija `menu_motion_readability_test.gd:75`). Sin zona ni flash nuevos
para gasto (reusa NW + click por bus; el throb de vetas es dominio cuerpo, fuera del HUD).
On Demand intacto y sin binding nuevo (no colisiona con C24 parry DIGITAL ni G7).

**Automatizado PASS 2026-09-13 (suite ui 45/45 verde)** (`hud_ve_gasto_knobs_test.gd`, 7 tests):
secuencia pre-light→move→fold exacta con Postura quieta (V6); ilegal mid-VE rechazado con
spends/cooldown/gracia intactos + medidor intacto + solo blip; legal acepta y mueve medidor;
4ª VE a 1.0 → +0/+0 con log; `gracia==coste` → 0.0; 2 gastos mismo tick → 1 acepta;
audio de gasto inmediato bajo supresión (P4: ducking owner #16).

**Manual PASS 2026-09-13** (`hud-ve-firma.png`, 1280×800, auto-driver): ev.15 visible — Gracia con tick de forma
+ contorno grueso, Postura idéntica; tras ev.16 todo limpio. Archivo esperado en esta carpeta.

## AC-b — knobs live sin restart, nunca bajo 4.5:1

**Estático PASS (revisión)**: sin cambios `src/` (ya completo en stories previas): `hud_opacity`
0.6–1.0 solo a fondos (fills/labels siempre alfa 1.0 — a 0.6 fundido `#C7CDD6` = 4.08:1, no pasa;
opaco = 8.51:1); `hud_scale` 0.9–1.15 con compensación a `ceil(18/s)` (piso 18px aparente);
`timer_high_contrast` solo sube a `#E8ECF1` (default true en Deck vía `_es_deck`, false en PC);
`disable_damage_flash` → icono-forma en NW + vignette (evento lógico único).

**Automatizado PASS 2026-09-13 (suite ui 45/45 verde)** (3 tests): barrido 3×2×2×2 sobre la misma instancia
(fondos a `op`, fills alfa 1.0, aparente ≥18px en todo punto + clamps); live-apply por knob;
piso 18px en las tres zonas a 0.9 (=20px base) y a 1.15 (=18px base).

**Manual PASS 2026-09-13** (`hud-ve-knobs.png`, 1280×800, auto-driver): barrido con `hud_opacity=0.6`,
`hud_scale=0.9`, contraste ON — legible sin caídas. Archivo esperado en esta carpeta.

## AC-c — reduced-motion ON (precedencia 005)

**Estático PASS (revisión)**: `GraciaShards` + `PosturaBlocks` gatean el hold
(`0 if reduced_motion else HOLD_FRAMES`) y sus setters colapsan holds en vuelo;
`HudNW` + `HudVignette` hacen `flash_fallo` no-op con reduced-motion (cero flashes ni de
color ni de forma; el bus lleva el feedback); la firma parada sigue siendo marca *estática*
(forma persistente hasta el cierre, no transitorio — corte 1 frame por construcción).
Cero `AudioStreamPlayer`/partículas bajo `CombatHud` (brasas: N/A por ausencia — las
CPUParticles2D viven en Decisión, otra pantalla). Skip global intacto (M-006a).

**Automatizado PASS 2026-09-13 (suite ui 45/45 verde)** (3 tests): hold a 0 + colapso en vuelo + firma exacta;
cero contadores de flash con fill intacto + clave bus emitida; solo-bus con barrido de tipos.

**Manual PASS 2026-09-13** (`hud-ve-reduced.png` + `hud-ve-reduced-A.png`, 1280×800, auto-driver): con reduced-motion ON, fallo + firma
en capturas consecutivas — cambio de estado en 1 frame, cero frames intermedios.
Archivo esperado en esta carpeta.

## AC-d — contraste Deck [DEFERRED a hardware real]

**NO implementada medición alguna** (decisión P6/contrato). Gancho para la sesión Deck 7":
medir con fotómetro/software ≥4.5:1 sobre los 5 elementos §12 (Vida, Gracia, Postura,
Vida jefe, Timer) a 30–40cm, viewport 1280×800, `hud_scale=1.0`, contraste ON;
volcar valores + capturas aquí y cerrar el advisory A2 de ux-review. Esta sección se
completa en la sesión Vertical Slice — la historia no se marca Done sin ella
(su Status ya lo prevé: Ready, AC-d scheduled).

## Riesgo abierto aceptado (P2): tick crítico a 40Hz sin hold

Con reduced-motion ON el latch+hold anti-40Hz queda desactivado: un tick crítico fundido
con otro en render Deck 40Hz puede no mostrarse (antes lo retenía 2 frames). Aceptado por
el usuario el 2026-09-13 — **medir en la sesión Deck** (barrido 50-trial del AC-d de story-004
bajo reduced-motion ON) en lugar de mitigar con código. Si el barrido pierde ticks, reabrir
como historia de pulido (ej. hold de 1 frame solo-reduced, o marca estática persistente).

## Out of Scope respetado (sin desviaciones)

- Nada de #6 Clímax past-94-tras-100 (saturación-quiebre OUT, P6).
- Nada de timbres/ducking (owner #16): se emiten `hud_gasto_aceptado`/`hud_gasto_denegado`
  + `hud_firma_ve`/`hud_fallo` existentes; jamás se reproduce directo (0 players).
- Sin zona/flash nuevos para gasto (reusa NW + body-vein throb + dry bus click).
- On Demand hold-binding UNCONFIRMED: sin binding nuevo, sin colisión C24/G7.
- Deuda previa intacta: paleta `GRIS_MEDIO #9AA2AF`, `set_vida`↔`_vignette`, readout ≤1-frame stale.

## Sign-off

- [x] Corrida `tests/integration/ui` verde (32/32 previas + 13 nuevas = 45/45) en Godot 4.7.1 + qa-lead QL-TEST-COVERAGE ADEQUATE (Sprint 2)
- [x] 3 capturas (`hud-ve-firma.png`, `hud-ve-knobs.png`, `hud-ve-reduced.png`) revisadas 2026-09-13 (firma+tick con Postura quieta — visible 4/4 = 3 lógicos +1 anticipación por diseño; sweep legible; A==final cero transitorios)
- [ ] Sesión Deck: AC-d medida + barrido tick-crítico del riesgo P2 + A2 cerrado

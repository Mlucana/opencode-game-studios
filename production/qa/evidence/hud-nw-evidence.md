# Evidencia manual — hud-001 NW Vida + Gracia widgets

**Story**: `production/epics/hud-combate/story-001-nw-vida-gracia.md`
**Fecha draft**: 2026-09-09
**Engine**: Godot 4.7.2-stable
**Código revisado**: `src/ui/hud_nw.gd` (flash a frames, `FLASH_FRAMES=2`),
`src/ui/gracia_shards.gd`, `src/ui/hud_presenter.gd`, `src/ui/combat_hud.gd`,
`src/ui/CombatHud.tscn` (sin hijos estáticos duplicados).
**Estado**: COMPLETO 2026-09-10 — checks estáticos PASS + 3 capturas verificadas
a 1280×800 (ventana propia, embed desactivado). Sesión Deck (legibilidad 7")
sigue pendiente en Sprint 2 (story-005/M-006a).

> Nota: el checklist del QA plan (`qa-plan-sprint-1-2026-09-08.md:86`) aún
> redacta AC-b como "interp ±1e-9". La historia se reformuló a discreto + hold
> 2 frames (API `(int,int)`, sin interpolación). Vale la redacción de la
> historia; el QA plan queda superseded en ese punto.

## AC-a — Vida tracking 1–2 ticks, hard cut

**Estático PASS**: `HudNW.set_vida()` escribe `ProgressBar.value` directo
(`hud_nw.gd:72-77`), sin Tween/ease. `HudPresenter.push_vida()` reenvía
sin-cómputo (`hud_presenter.gd:90-94`). Flash dura 2 frames exactos
(`FLASH_FRAMES`, `hud_nw.gd:20-21,163-171`).

**Manual PASS** (`hud-nw-vida.png`, 1280×800): tras `push_vida(75,100)` la barra
muestra 75/100 en corte duro, sin ease; gracia 2/4 bajo Vida; caja NW pequeña en
(64,40), resto del centro libre.

## AC-b — Gracia discreta + hold, nunca computa

**Estático PASS**: `set_shards(encendidas,total)` solo cachea + `queue_redraw`
(`gracia_shards.gd:47-54`); hold 2 render-frames anti-40Hz (`HOLD_FRAMES`,
`gracia_shards.gd:28,99-103`); rombos ◆◆◇◇ en `_draw`
(`gracia_shards.gd:106-150`); `set_prelight` solo contorno
(`gracia_shards.gd:58-62`). Sin math de earn en UI.

**Manual PASS** (`hud-nw-gracia.png`, 1280×800): `push_gracia(3,4)` → 3/4 rombos
encendidos con grieta vino + borde claro, cambio discreto (2→3 entre capturas),
sin math local. Saturación/gasto visual pertenecen a story-005.

## AC-c — fail flash único #C75C4A, 2 frames

**Estático PASS**: `flash_fallo()` = `FLASH_FRAMES` (2), color `#C75C4A` +
borde 3px `#C7CDD6` + marca de forma (`hud_nw.gd:118-138,222-242`); restauración
al expirar (`hud_nw.gd:163-171`); `skip_animations()` corta a final
(`hud_nw.gd:143-151`). Medido sin supresor activo (`CombatHud._anunciar`
encola a 16ms bajo supresión — ver story). Candle-out + supresión 800ms
pertenecen a story-004, fuera de alcance.

**Manual PASS** (`hud-nw-flash.png`, 1280×800, frame 1 de 2): fill `#C75C4A` +
borde 3px claro + triángulo lateral (respaldo no-cromático) + franja superior de
`HudVignette.flash_fallo()` (evento lógico único NW+vignette, documentado).

## AC-d — cero strings hardcodeados (`tr()`)

**Estático PASS** (grep `tr\(` sobre `src/ui`, 2026-09-09): los 4 `.text` de la
asamblea NW van por `tr()` — `hud_nw.gd:158` (`HUD_NW_EXACT`), `hud_nw.gd:257-258`
(`HUD_HP_LABEL`, `HUD_GRACIA_LABEL`), `hud_nw.gd:310` (`HUD_NW_EXACT`).
`CombatHud.tscn` no contiene literales de texto (solo offsets/mouse_filter).
El `push_warning` de `combat_hud.gd:496` es dev-only, no user-facing.

**Manual PASS** (grep 2026-09-09 + capturas): únicos `.text` por `tr()`;
`CombatHud.tscn` sin literales. Nota: en runtime se ven las CLAVES
(`HUD_HP_LABEL`) porque aún no hay tablas l10n (LocalizationService futuro) —
el código cumple (todo vía `tr()`), las traducciones quedan pendientes.

## AC-e — layout ≤6% @1280×800, safe-zone 5%

**Estático PASS (math)**: viewport 1280×800 = 1.024.000 px²; 6% = 61.440.
Caja NW `.tscn` 300×140 = 42.000 (**4,1%**). Contenido visible: barra 260×12
+ shards 112×24 + 2 labels ~18px ≈ 17k px² (**~1,7%**). Origen (64,40) =
safe-zone 5%. Válido a `hud_scale=1.0`, `EstadoHUD.COMBATE`.

**Manual PASS** (`hud-nw-vida.png`, 1280×800): caja NW 300×140 = 42.000 px²
(4,1% ≤ 6%) en (64,40) = safe-zone 5%; contenido visible ~1,7%; centro libre.
Medido a `hud_scale=1.0`, `EstadoHUD.COMBATE`. (La línea superior de ayuda es
overlay del driver de capturas, no del HUD.)

## Deuda conocida (no bloquea cierre UI, gate ADVISORY)

- `CombatHud._reloj_ms` (cola prioridad) sigue en ms escalados — C14 total
  pendiente de story-003/004.
- `_violaciones_guardia` observable (ADR-002 §7) pendiente.
- `HudNE.JefeBar` con `FOCUS_ALL` fuera de la cadena lineal — toca story-002.
- `ext_resource` 6/7 sin uso en `CombatHud.tscn` (cosmético).
- Paleta `GRIS_MEDIO #9AA2AF` en código vs `#8C94A0` en historia — falta ruling
  canónico (hud.md/art-bible).

## Sign-off

- [x] Verificación manual: PASS 2026-09-10 (3/3 capturas a 1280×800 revisadas)
- [ ] qa-lead formal + sesión Deck 7": pendiente Sprint 2 (story-005/M-006a)

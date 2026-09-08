# Interaction Patterns — HUD de Combate NOVENA

> **Status**: New (2026-09-03, ui-programmer)
> **Origen**: `design/ux/hud.md` + changeset "HUD con stub"
> **Decisión de usuario**: "seguir sin librería" — estos 3 patrones se tratan
> como NUEVOS y propios del proyecto, sin dependencia externa.
> **Escena**: `src/ui/CombatHud.tscn` · **Lógica**: `src/ui/*.gd`

Los 3 patrones comparten la filosofía "NOVENA se lee en el ángel, no en la
interfaz": periferia screen-space, centro 60% libre, formas rectas y finas,
sin vocabulario circular, cambios críticos en 1–2 ticks sin ease-in, todo
texto vía `tr()` (cero strings hardcodeados), `mouse_filter` IGNORE en todo,
teclado + mando completos sin hover, parry digital (ningún eje analógico),
animaciones skippables + reduced-motion (sin shake/vignette pulsante;
el hitstop se mantiene por ser gameplay).

---

## P1 — Barra periférica recta (Vida / Vida jefe / Timer)

**Qué es**: barra horizontal recta y fina en periferia, sin números, que lee
luminancia/movimiento en vez de croma. Aplica a Vida jugador (NW, gris frío),
Vida jefe (NE, fina bajo Postura) y Timer castigo (S, 400×8 lineal izq→der,
gris frío de alta luminancia).

**Cuándo**: Vida siempre en combate; Vida jefe solo en duelo y solo cambia
con daño bruto de Castigo (sin pulso propio); Timer solo en Aturdido,
continuo 120 ticks, aparece/desaparece sin ease, pausado en Pausa.

**Reglas**:
- `ProgressBar` + `StyleBoxFlat`, esquinas a 0 (rectas), 1–3 draws UI.
- Paleta `#2A2E36` fondo / `#8C94A0` medio / `#C7CDD6` luz (`#E8ECF1` solo si
  `timer_high_contrast` en Deck; nunca bajo 4.5:1).
- Fuentes funcionales ≥18px; safe-zone 5% ((64,40) a 1280×800).
- Budget: NW ≤6%, NE ≤6%, S ≤3%, total ≤15%.
- Knobs: `hud_opacity` 0.6–1.0, `hud_scale` 0.9–1.15 (respeta 18px mínimo).

**Implementación**: `hud_nw.gd` / `hud_ne.gd` / `hud_s.gd` sobre
`CombatHud.tscn` (CanvasLayer layer 10, `follow_viewport_enabled` false,
`process_mode` ALWAYS para C14).

---

## P2 — Flash + vignette de fallo (ausencia de luz)

**Qué es**: el único flash permitido del HUD (`#C75C4A` sobre Vida al fallar,
evento 5) + vignette de tinta (`#14110E`) desde bordes por vida baja
(progresiva) y muerte (total + corte seco + grieta, ev.13).

**Cuándo**: fallo → flash único 1–2 ticks sin ease-in, suprime firma VE
200ms (prioridad 2/6); vida baja → tinta progresiva + latido (solo alfa,
nunca luz); muerte → suprime todo 800ms (prioridad 1/6).

**Reglas**:
- Regla de oro: lo que sale mal = ausencia de luz, nunca flash punitivo.
- Prioridad 6 niveles: 1 Muerte → 2 Fallo → 3 Firma VE → 4 Caída Postura →
  5 Pre-light VE → 6 Timer (fondo, nunca suprime). Nunca dos flashes en el
  mismo tick: el menor se retrasa 1 tick.
- Latch+hold 2 frames de render: ningún tick crítico se pierde a 40Hz Deck.
- Knob `disable_damage_flash` → sustituye flash por icono con forma
  (fotosensibilidad). Reduced-motion → sin vignette pulsante ni shake.
- En Pausa: sin vignette animada ni rumble; retorno por corte.

**Implementación**: `hud_vignette.gd` (`_draw()` por bandas) + `flash_fallo()`
en `hud_nw.gd`, arbitrado por `combat_hud.gd::_anunciar()`.

---

## P3 — Firma VE ("Gracia se mueve / Postura no")

**Qué es**: la Ventana Especial se firma con movimiento asimétrico: la Gracia
(pre-light ev.14 → se mueve al parar ev.15 → repliegue de luz + cue
irresoluto al cerrar sin parar ev.16) mientras la Postura queda quieta
(ev.8 no reacciona en VE, V6). Distinguible con ojos cerrados en audio
(capa sin cuerpo físico, ev.15).

**Cuándo**: solo en Ventana Especial (contextual). Formas: Gracia en
esquirlas rombo ◆◆◇◇ (dirección A1, único vitral permitido); Postura en
4 bloques segmentados (dirección B1).

**Reglas**:
- `gracia_shards.gd` y `postura_blocks.gd` dibujan en `_draw()`,
  event-driven vía `queue_redraw()` (nunca sondeo).
- `CombatHud.set_postura()` ignora llamadas durante VE: la ausencia es la
  firma, no un olvido.
- `HudPresenter` reenvía `firma_ve_changed` y emite `hud_audio_requested`
  (sonido vía sistema de eventos, nunca directo).
- En decisión absorber/rechazar: HUD oculto salvo Gracia en NW a alta
  luminancia (la decisión ES gracia).

**Implementación**: `gracia_shards.gd` (rombos + `set_prelight`) /
`postura_blocks.gd` (4 bloques + latch+hold) / `hud_presenter.gd` (9 señales
directas, solo lectura, anti-reentrada).

---

## P4 — Díada ceremonial en igualdad (TOMAR / DEJAR IR)

**Qué es**: dos botones gemelos en igualdad visual estricta (misma métrica,
mismo peso, misma luminancia base) para un commit moral irrevocable, con
foco neutro inicial, trampa de foco y single-press + flanco fresco SIN hold.
Aplica a `DecisionGracia` (decisión absorber/rechazar post-reliquia).

**Cuándo**: solo en pantallas discretas de commit moral (modo UI, no HUD).
No aplica a destrucción de run/SUS (eso es hold Tipo-A, Menú R4) ni a
combate (centro 60% libre, P1–P3).

**Reglas**:
- Foco neutro al abrir (carve-out justificado a Menú R7: ambos commits son
  single-press irrevocables y el flanco fresco no para mash heredado del
  duelo; mover primero rompe la cadena). `ui_accept` en neutro = no-op.
- Primer `ui_left/right` discreto agarra (LTR: left→TOMAR, right→DEJAR IR;
  RTL espeja orden + mapeo); trampa: navegar cicla dentro de la díada
  (vecinos + next/previous cruzados, top/bottom a sí mismo).
- Commit: mismo frame ambos deshabilitados + swallow 200 ms + evento;
  2º input del mismo tick tumbado por guarda de estado. SIN hold (la
  fricción castigaría el Pilar 4; la irreversibilidad se comunica por línea
  explícita + atomicidad + imposibilidad de re-elegir por recarga).
- `ui_cancel` = no-op + error sordo por bus. Right-click = no-op definido.
- Foco = borde 2px `#C7CDD6` + cuneta 8×24 + peso de etiqueta, 0 glow
  (principio art-bible 2), nada por hover (hover = estilo normal).
- Enfocar uno jamás atenúa al otro (el rechazo jamás se presenta menor).
- Confirmación como sustain skippable (succión inward + rosetón en TOMAR,
  ascenso outward sin rosetón en DEJAR IR); reduced-motion = corte 1 frame.
- Todo texto vía `tr()` (`MENU_DECISION_*`, ≤120 chars post-interpolación);
  `mouse_filter` IGNORE en todo salvo botones STOP (sin grab en hover);
  sonidos por bus; `CPUParticles2D` pineado (sin glow, sin números
  flotantes, sin E/S de disco desde el assembly).

**Implementación**: `decision_gracia.gd` (vista display-only, validación
bloqueante NaN/mismatch/poso/n>3) / `decision_gracia_presenter.gd` (puente
estilo `hud_presenter.gd`, oculta/restaura `CombatHud`) sobre
`DecisionGracia.tscn` (CanvasLayer layer 20, `process_mode` ALWAYS).
Reutiliza `gracia_shards.gd` (`highlight_decision`); NO duplica NW ni usa
`hud_ne/s`, `postura_blocks`, `vignette` ni `flash_fallo`.

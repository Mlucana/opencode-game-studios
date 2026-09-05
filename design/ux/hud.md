# HUD Design — HUD de Combate NOVENA

> **Status**: In Design
> **Author**: usuario + ux-designer
> **Last Updated**: 2026-09-03
> **Template**: HUD Design
> **Systems**: #13 HUD de Combate (depende de #1 Combate Parry-Absorción, #5 Gracia — pendiente)

---

## HUD Philosophy

NOVENA se lee en el ángel, no en la interfaz. El HUD solo sostiene las decisiones
que los ojos no pueden leer en el cuerpo — Vida, Postura, Gracia — y desaparece
de la atención en cuanto el jugador vuelve al centro.

**Implicaciones:**
- **Centro sagrado:** ningún elemento permanente invade el 60% central. Todo vive
  en periferia screen-space, nunca diegético (GDD Combate, UI Requirements).
- **Solo lo divino emite luz:** HUD en gris frío / tinta. Única excepción con
  licencia vitral: el medidor de Gracia (art bible 3.4).
- **Dato antes que decoración:** cambios críticos en 1–2 ticks, sin ease-in.
  Formas rectas y finas, sin vocabulario circular (no competir con telegrafiados).
  Texto funcional ≥18px aparente en Steam Deck 7" a 30–40cm.
- **La corrupción no se duplica:** el cuerpo del protagonista ES el mapa de
  corrupción (game-concept). El medidor solo cuantifica lo que el cuerpo ya muestra.

**Prohíbe:** timers permanentes, números flotantes sobre el ángel, flashes
punitivos de luz (regla de oro: lo que sale mal = ausencia de luz, nunca flash),
cualquier elemento circular que compita con telegrafiados.

---

## Information Architecture

### Full Information Inventory

Fuente: GDD Combate UI Requirements + Visual/Audio eventos 3,5,8,10,13–16.
Sistema 2 declara sin UI propia. Sistema 5 (Gracia) pendiente — cantidades provisionales.

| # | Información | Fuente GDD | Update |
|---|---|---|---|
| 1 | Vida jugador (0–100+, daño 25/golpe) | Combate F5/F8, evento 5/13 | En cada cambio |
| 2 | Postura enemigo (daño por parry) | Combate F1, evento 8 | En cada parry / ruptura / restauración |
| 3 | Vida enemigo (solo Castigo) | Combate F6 | En cada Castigo conectado |
| 4 | Timer ventana castigo 120 ticks (2.0s) | Combate R5, evento 10 | Continuo durante Aturdido |
| 5 | Medidor Gracia / corrupción | Combate F7, eventos 14–15 (propiedad sist.5) | En cada absorción |
| 6 | Alertas: flash #C75C4A + vignette tinta | Eventos 5 y 13 | Al fallar / vida baja |
| 7 | Firma VE: "Gracia se mueve / Postura no" | Eventos 14–16, V5–V7 | Al abrir/parar/cerrar VE |

### Categorization

Chequeo filosofía: 2 Must Show + 5 Contextual = compatible con "mínimo pero presente".
Sin conflicto.

| Categoría | Elementos |
|---|---|
| **Must Show** (siempre en combate) | 1 Vida jugador · 5 Medidor Gracia |
| **Contextual** (solo cuando aplica) | 2 Postura (en duelo) · 3 Vida enemigo (en duelo) · 4 Timer (solo Aturdido) · 6 Alertas (fallo/vida baja) · 7 Firma VE |
| **On Demand** (provisional) | Valores numéricos exactos al mantener botón (ej. Tab / Touchpad). Sin confirmar con sist.5 |
| **Hidden** (mundo/audio, nunca texto HUD) | Mapa de corrupción corporal · telegrafiados/fisuras · tells sonoros por tríada · hitstop/cámara/rumble |

---

## Layout Zones

**Decisión:** esquinas espejadas. Centro 60% libre siempre.

- **NW (arriba-izq, persistente):** Vida jugador (barra recta fina, gris frío)
  + Medidor Gracia debajo (único vitral permitido).
- **NE (arriba-der, solo en duelo):** Postura enemigo (barra) + Vida jefe
  (barra fina debajo). Fuera de duelo, colapsada.
- **S (abajo-centro, solo Aturdido):** Timer castigo 120 ticks como **barra**,
  no numérico — periferia lee luminancia/movimiento, no croma (nota ux-designer
  en GDD). Gris frío de alta luminancia, nunca centro.
- **Bordes:** vignette tinta (vida baja/muerte) + flash único #C75C4A en HUD
  vida al fallar (evento 5). Sin flash de luz punitivo.
- **Centro:** prohibido permanente. Solo VFX diegético (fisuras, esquirlas).

### ASCII Wireframe

```text
┌────────────────────────────────────────┐
│ [Vida PJ ████░░]      [Postura ███░░]  │
│ [Gracia ◆◆◇◇]         [Vida Jefe ██░░] │
│                                        │
│           CENTRO LIBRE                 │
│          (solo ángel + VFX)            │
│                                        │
│         [Timer castigo ━━━━━━]         │
└────────────────────────────────────────┘
Bordes = vignette tinta + flash #C75C4A
```

### Visual Budget

- **Max simultáneos:** 5 en duelo normal (Vida, Gracia, Postura, Vida jefe + 1 efímero), 6 en pico absoluto (timer o alerta, nunca dos efímeros salvo muerte que suprime todo).
- **% pantalla a 1280x800 Deck:** HUD total ≤15% (NW ≤6%, NE ≤6%, S ≤3%), centro 0% permanente.
- **Draw calls UI:** 1–3 (heredado art bible 8.6, VFX = resto hasta 40–80).

---

## HUD Elements

| Elemento | Cat. | Forma | Update | Trigger | Animación |
|---|---|---|---|---|---|
| Vida jugador | Must | Barra recta fina, gris frío NW | Event-driven en cada cambio (25/daño) | Siempre en combate | Flash único #C75C4A al fallar (ev.5), 1–2 ticks sin ease-in. No congela en hitstop (C14) |
| Postura enemigo | Contextual | Barra recta NE | En cada parry / ruptura / restauración | Solo en duelo | Caída visible en combo completo (ev.8). **No reacciona en VE** — esa ausencia es la firma (V6) |
| Vida jefe | Contextual | Barra fina bajo Postura | Solo en Castigo conectado | Solo en duelo | Sin pulso propio; cambia solo con daño bruto (ev.11) |
| Timer castigo | Contextual | **Barra** gris frío alta-luminancia S, no numérico | Continuo 120 ticks | Solo Aturdido | Aparece/desaparece sin ease; nunca centro. Periferia lee luminancia, no croma |
| Medidor Gracia | Must | Único vitral permitido, NW bajo Vida | En cada absorción | Siempre en combate | Pre-light al abrir VE (ev.14); se mueve al parar VE (ev.15). Cantidad propiedad sist.5 |
| Bordes / vignette | Contextual | Tinta desde bordes | Progresivo vida baja; total en muerte | Vida baja / muerte | Sin flash de luz. Muerte = grabado puro + grieta (ev.13) |
| Firma VE | Contextual | Gracia se mueve + Postura quieta | Al abrir/parar/cerrar VE | Ventana Especial | Distinguible con ojos cerrados en audio (capa sin cuerpo físico, ev.15) |

---

## Dynamic Behaviors

- **Fuera de duelo:** solo NW (Vida + Gracia). NE colapsada.
- **En duelo:** NE aparece (Postura + Vida jefe). Sin animación de entrada invasiva.
- **Aturdido:** S aparece (timer 120 ticks). Al conectar Castigo → colchón Repliegue con lectura propia (jefe acusa golpe, no reposiciona).
- **Ventana Especial:** Gracia pre-iluminada (ev.14) → al parar: Gracia se mueve, Postura no (ev.15) → al cerrar sin parar: repliegue de luz "esto ya va a ocurrir", cue irresoluto (ev.16).
- **Hitstop:** mundo al 4% 5 ticks (+2/+1 en Parry Justo solo en Golpe, nunca en VE); **HUD sigue a 60Hz** (C14).
- **Vida baja:** vignette tinta progresiva + latido acelerado; muerte = corte seco + vela apagándose.
- **Pausa:** HUD atenuado 40%, S oculto, timer pausado (no cuenta), sin vignette animada ni rumble. Retorno por corte.
- **Hub / entre duelos:** solo NW (Vida + Gracia). NE colapsada, S oculto, bordes limpios.
- **Decisión absorber / rechazar:** HUD oculto salvo medidor Gracia en NW a alta luminancia (la decisión ES gracia). Sin Postura / Vida jefe / timer.
- **Cutscene / diálogo Lucifer:** HUD oculto total. Retorno por corte 1 tick, sin fade.

### Notification Priority (cola visual)

Orden: 1 Muerte (ev.13) suprime todo 800ms → 2 Fallo flash #C75C4A (ev.5) suprime firma VE 200ms → 3 Firma VE parada/cierre (ev.15/16) → 4 Caída Postura (ev.8) → 5 Pre-light VE (ev.14) → 6 Timer continuo (fondo, nunca suprime).
Regla: nunca dos flashes en el mismo tick; el de menor prioridad se retrasa 1 tick (sigue cumpliendo 1–2 ticks). Misma prioridad propuesta a sist.16 para ducking de audio.

---

## Platform & Input Variants

- **Targets:** PC Steam 16:9 + Steam Deck 7" (~30–40cm). Texto funcional ≥18px aparente. Safe-zone 5%.
- **Sin hover:** nada depende de hover o tooltip. On Demand por mantener (Tab / Touchpad / Back — a confirmar en implementación).
- **Gamepad primario:** navegación completa por mando; HUD no interactivo salvo On Demand. Parry **digital** — ningún eje analógico mapeable (C24).
- **Rumble:** 80ms agudo en acierto / 200ms grave difuso en fallo — canal háptico distintivo.
- **Tiempo:** física 60Hz invariante (no bajar a 40Hz para batería). Render Deck puede ir a 40Hz → riesgo de fundir 2 ticks en 1 frame (ver Open Questions).
- **Verificación:** timing de parry y legibilidad HUD en hardware Deck real, no solo PC.

### Tuning Knobs (jugador)

| Knob | Rango | Default | Notas |
|---|---|---|---|
| `hud_opacity` | 0.6–1.0 | 1.0 | No baja luminancia del timer bajo 4.5:1 |
| `hud_scale` | 0.9–1.15 | 1.0 | Respeta mínimo 18px aparente |
| `timer_high_contrast` | bool | true en Deck, false en PC | Sube luminancia del gris frío |
| `disable_damage_flash` | bool | false | Sustituye flash #C75C4A por icono con forma (fotosensibilidad) |

---

## Accessibility

> Tier no definido en proyecto — se propone **WCAG-AA como baseline**. Revisar en `/gate-check`.

- **Navegación:** teclado + mando llegan a todo lo interactivo (On Demand) en orden lógico, con foco visible.
- **No solo color:** Postura/Vida con forma + posición + movimiento, no solo croma. Timer como barra de luminancia, no número de color. Periferia no lee croma.
- **Contraste:** fijar luminancia explícita para timer gris frío y barras sobre fondo tinta (pendiente valor en implementación).
- **Reduced-motion:** alternativa sin sacudida de cámara ni vignette pulsante; hitstop diferencial se mantiene (es gameplay, no decoración).
- **Deuda heredada GDD:** Parry Justo hoy solo micro-color #FFF8E7 + hitstop — necesita respaldo no-cromático/no-temporal (forma o háptico reforzado) para sist.21.

---

## Open Questions

- [ ] Cantidades de Gracia por parry / techo saturación — propiedad sistema 5 (GDD pendiente). Este HUD solo declara que el valor cambia.
- [ ] Mecanismo de tiempo diegético sin `Engine.time_scale` (global en Godot 4.7) que deje HUD a velocidad normal — decisión de `/create-architecture`.
- [ ] ¿Cómo no pierde el HUD transiciones a render 40Hz (2 ticks en 1 frame)? — contradice "1–2 ticks sin ease" si se funden.
- [ ] Player journey map no existe (`design/player-journey.md`). Template en `.claude/docs/templates/player-journey.md`. Sin él, fase emocional de llegada al duelo es suposición.
- [ ] Accessibility tier sin definir (`design/accessibility-requirements.md` no existe). Propuesto WCAG-AA.
- [ ] Binding On Demand (números exactos) sin confirmar; no colisionar con parry digital.
- [ ] ¿Bastan 3 emisores GPUParticles2D con reciclado semántico por dirección + señal `finished`? — pregunta a `technical-artist` (GDD Combate, P0/P5).

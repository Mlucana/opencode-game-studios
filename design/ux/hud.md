# HUD Design — HUD de Combate NOVENA

> **Status**: In Design (Rev-2 retrofit 2026-09-05 — auto; `/ux-review hud` APPROVED 2026-09-05, 0 blocking / 5 advisory)
> **Author**: usuario + ux-designer
> **Last Updated**: 2026-09-05
> **Template**: HUD Design
> **Systems**: #13 HUD de Combate (depende de #1 Combate Parry-Absorción APPROVED, #5 Gracia APPROVED 2026-09-05 lean Rev-1)
> **Related GDDs**: `combate-parry-absorcion.md` §UI Requirements (C14, R2, contraste periférico) · `gracia-tres-capas.md` §UI Requirements + G4/G5/G6/G7/G8/G10 (cantidades APPROVED, ya no provisionales) · `feedback-impacto.md` §UI Requirements + R1/R2 (juicio ≤2 / confirmación ≤10, freeze 0%, HUD ALWAYS) · `feedback-sonoro-parry.md` (co-emite alerta 5/13, timbres propiedad #16, presupuestos interinos) · `ia-combate-jefes.md` Rev-1 APPROVED (duraciones que el HUD no debe tapar) · `menu-principal-y-flujo-de-pantallas.md` R4/R6/R7 (firma Tipo-A vs single-press Decisión, skip cerrado, foco sin brillo) · `maquina-estados-jefe.md` §UI Requirements (sin UI propia — Postura/Vida son propiedad #13)
> **Related ADRs**: ADR-001 + ADR-002 Accepted · ADR-003 bus Hitstop Accepted (propiedad final #16; #4 lo creó provisional). Pendientes que bloquean implementar: ADR de tiempo (Pattern-A 0% + WallTick/DiegeticTick) · ADR de arranque/router (`change_scene` único, splash) · ADR checksum/canonicalización
> **Related UX Specs**: `design/ux/decision-gracia.md` Draft (Decisión: HUD oculto salvo Gracia NW alta luminancia) · `design/ux/interaction-patterns.md` P1/P2/P3 (filosofía compartida)
> **Accessibility Tier**: WCAG-AA propuesto como baseline (sin `design/accessibility-requirements.md`; pendiente `/gate-check` + sistema #21)

> **Scope boundary**: Este spec cubre el overlay persistente durante duelo activo + Hub/entre-duelos. La pantalla Decisión absorber/rechazar NO es HUD (modo ceremonial con centro ocupado, propiedad #5) — ver `decision-gracia.md`. Este HUD jamás muestra Continuar/estado_red (propiedad Menú/Guardado).

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
  corrupción (game-concept + Gracia G-marco). El medidor solo cuantifica lo que el cuerpo ya muestra.
- **El HUD muestra, no puntúa:** el juicio (qué pasó) y la confirmación (cuánto valió)
  los poseen #4 (visual) y #16 (sonoro). El HUD reacciona (caída Postura en ev.8,
  alerta en 5/13) pero no añade elementos propios de feedback.

**Prohíbe:** timers permanentes, números flotantes sobre el ángel, flashes
punitivos de luz (regla de oro: lo que sale mal = ausencia de luz, nunca flash),
cualquier elemento circular que compita con telegrafiados, celebraciones de
absorción (`¡NUEVA FORMA!`), tercer lenguaje visual fuera de tinta/vitral/UI-frío.

---

## Information Architecture

### Full Information Inventory

Fuente: Combate UI Requirements (5 filas) + Gracia G1–G10 APPROVED (cantidades ya no
provisionales) + Impacto UI Requirements (sin UI propia; exige HUD ALWAYS + caída
Postura en ev.8) + Sonoro (co-emite alerta 5/13) + IA #20 (duraciones que condicionan
legibilidad) + Menú (Pausa ordena `set_pausa_visual`). Sistema 2 declara sin UI propia.

| # | Información | Fuente GDD | Update |
|---|---|---|---|
| 1 | Vida jugador (base 100 + 18/absorber plano v1.0 + reliquias passthrough; daño por Golpe según tríada) | Combate F5/F8, evento 5/13; Gracia G5 (floor-lift `C'=max(C,poso')`) | En cada cambio |
| 2 | Postura enemigo (daño por parry; intermedios excluidos C4/C9) | Combate F1/R7, evento 8 | En cada parry / ruptura / restauración |
| 3 | Vida enemigo (solo Castigo; `vida_max_angel` 120/200/300 por tríada, `dano` 30/40/50 × ciclos 4/5/6 — IA D6) | Combate F6; IA #20 D6 | En cada Castigo conectado |
| 4 | Timer ventana castigo 120 ticks (2.0s) | Combate R5, evento 10 | Continuo durante Aturdido |
| 5 | Medidor Gracia / corrupción / poso (earn simple +1.0/+1.0, combo +0.5/parry, VE +1.0/+1.0 cap Σ≤3/duelo; gasto Purga 8 / Amparo 12, alivio `C'=poso+(C−poso)/2`, cap 2/duelo + cooldown 360 + máx 1 amparo; TOMAR +12 poso sin lump; DEJAR −6 hasta suelo; techo 100 clamp + gasto off) | Gracia G1/G3/G5/G6/G7/G8/G10, eventos `gracia/currupcion/poso_cambiada` + `saturacion_alcanzada` (solo-lectura; setter desde observador falla GR-31) | En cada earn / gasto / commit (Decisión solo expone, no calcula) |
| 6 | Alertas: flash #C75C4A + vignette tinta | Eventos 5 y 13; Impacto C13 (peso-golpe-sin-freeze: vignette 12 ticks + punch ≤2 + alerta HUD ≤2); Sonoro co-emite pata 5/13 | Al fallar / vida baja |
| 7 | Firma VE: "Gracia se mueve / Postura no" | Eventos 14–16, V5–V7; Gracia G3/G7 (VE peor intercambio, gasto ilegal en VE activa, cap Σ≤3) | Al abrir/parar/cerrar VE |
| 8 | Feedback de gasto (vetas laten en cuerpo + click seco por bus por coste; blip denegación si RECHAZO; Purga-en-suelo ACEPTA alivio 0 — anotación UX, no regla) | Gracia G7 + Visual (sin flash nuevo); Sonoro D-D (transients secos por coste) | Al gastar / al denegar |
| 9 | Saturación (C≥100: clamp, `saturacion_alcanzada` una vez con snapshot, gasto off, handoff a #6; TOMAR/DEJAR posterior no retracta) | Gracia G8/G10 | Una vez por entrada |

### Categorization

Chequeo filosofía: 2 Must Show + 6 Contextual = compatible con "mínimo pero presente".
Sin conflicto. El gasto y la saturación son contextuales (no añaden elementos
permanentes nuevos: reutilizan medidor NW + cuerpo + bus sonoro).

| Categoría | Elementos |
|---|---|
| **Must Show** (siempre en combate) | 1 Vida jugador · 5 Medidor Gracia |
| **Contextual** (solo cuando aplica) | 2 Postura (en duelo) · 3 Vida jefe (en duelo) · 4 Timer (solo Aturdido) · 6 Alertas (fallo/vida baja) · 7 Firma VE · 8 Feedback gasto (al gastar/denegar) · 9 Saturación (handoff visual una vez) |
| **On Demand** (provisional) | Valores numéricos exactos al mantener botón (ej. Tab / Touchpad). Sin confirmar; no colisionar con parry digital ni con binding de gasto G7 |
| **Hidden** (mundo/audio, nunca texto HUD) | Mapa de corrupción corporal (venas/rosetones, overlay 4–6 anclajes, recompuesto solo en eventos) · telegrafiados/fisuras · tells sonoros por tríada · freeze/pausa diegética + cámara/rumble · bed musical |

---

## Layout Zones

**Decisión:** esquinas espejadas. Centro 60% libre siempre.

- **NW (arriba-izq, persistente):** Vida jugador (barra recta fina, gris frío)
  + Medidor Gracia debajo (único vitral permitido). El gasto no crea zona nueva:
  latido de vetas en cuerpo + click por bus + movimiento del medidor existente.
- **NE (arriba-der, solo en duelo):** Postura enemigo (barra) + Vida jefe
  (barra fina debajo). Fuera de duelo, colapsada.
- **S (abajo-centro, solo Aturdido):** Timer castigo 120 ticks como **barra**,
  no numérico — periferia lee luminancia/movimiento, no croma (nota ux-designer
  en GDD Combate, normativa). Gris frío de alta luminancia, nunca centro.
- **Bordes:** vignette tinta (vida baja/muerte) + flash único #C75C4A en HUD
  vida al fallar (evento 5). Sin flash de luz punitivo. Muerte = grabado puro +
  grieta (ev.13), suprime todo 800ms.
- **Centro:** prohibido permanente. Solo VFX diegético (fisuras, esquirlas).
  Excepción declarada en art bible: la Decisión (`decision-gracia.md`) SÍ admite
  centro ocupado — es otro modo UI, no este HUD.

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
Gasto = mismo NW (medidor se mueve) + vetas laten + click seco (sin zona nueva)
```

### Visual Budget

- **Max simultáneos:** 5 en duelo normal (Vida, Gracia, Postura, Vida jefe + 1 efímero), 6 en pico absoluto (timer o alerta o feedback-gasto, nunca dos efímeros salvo muerte que suprime todo).
- **% pantalla a 1280x800 Deck:** HUD total ≤15% (NW ≤6%, NE ≤6%, S ≤3%), centro 0% permanente.
- **Draw calls UI:** 1–3 (heredado art bible 8.6, VFX = resto hasta 40–80).

---

## HUD Elements

| Elemento | Cat. | Forma | Update | Trigger | Animación |
|---|---|---|---|---|---|
| Vida jugador | Must | Barra recta fina, gris frío NW | Event-driven en cada cambio (F5: base 100 +18/absorber + reliquias; floor-lift Gracia J3 no toca Vida salvo +18) | Siempre en combate | Flash único #C75C4A al fallar (ev.5), 1–2 ticks sin ease-in. No congela en freeze (C14: HUD ALWAYS). Muerte = corte seco + vela apagándose |
| Postura enemigo | Contextual | Barra recta NE, 4 bloques segmentados (P3) | En cada parry / ruptura / restauración; intermedios de combo no puntúan (C4/C9) | Solo en duelo | Caída visible en combo completo (ev.8) simultánea al transient de entrada (Impacto R1). **No reacciona en VE** — esa ausencia es la firma (V6) |
| Vida jefe | Contextual | Barra fina bajo Postura | Solo en Castigo conectado (daño bruto `dano` 30/40/50; `vida` 120/200/300 por tríada — IA D6) | Solo en duelo | Sin pulso propio; cambia solo con daño bruto (ev.11) |
| Timer castigo | Contextual | **Barra** gris frío alta-luminancia S, no numérico | Continuo 120 ticks | Solo Aturdido | Aparece/desaparece sin ease; nunca centro. Periferia lee luminancia, no croma. Pausado en Pausa (timer pausado, no cuenta) |
| Medidor Gracia | Must | Único vitral permitido, NW bajo Vida (rombos ◆◆◇◇ + `set_prelight`, P3) | Earn: simple +1.0/+1.0, combo +0.5/parry, VE +1.0/+1.0 (cap Σ≤3/duelo); Gasto: −8 Purga / −12 Amparo con alivio `/2` hasta suelo; TOMAR/DEJAR no mueven este medidor en duelo (son de Decisión) | Siempre en combate | Pre-light al abrir VE (ev.14); se mueve al parar VE (ev.15); repliegue sobrio al cerrar sin parar (ev.16). Saturación: quiebre a blanco-espectro una vez (handoff #6), luego congela (Gracia congela ledgers). Cantidad propiedad #5 — este spec solo interpola |
| Bordes / vignette | Contextual | Tinta desde bordes (`#14110E`) | Progresivo vida baja (12 ticks + punch ≤2 en golpe — Impacto C13); total en muerte | Vida baja / muerte | Sin flash de luz. Latch+hold 2 frames render: ningún tick crítico se pierde a 40Hz Deck (P2) |
| Firma VE | Contextual | Gracia se mueve + Postura quieta | Al abrir/parar/cerrar VE; cap Σ≤3 con log (G3/G8: 4ª VE a 1.0 = +0/+0) | Ventana Especial | Distinguible con ojos cerrados en audio (capa sin cuerpo físico, ev.15; Sonoro SN-06: forced-choice 9/10). Gasto ilegal en VE activa → descartado sin buffer (G7) |
| Feedback gasto | Contextual | Sin elemento nuevo: medidor existente + vetas + click seco por bus | Al aceptar (spends+1, cooldown=0) o denegar (sin cambio salvo blip) | Telegrafiado/Enfriamiento/Repliegue/Hub/post (legal); Parry/Aturdido/Recepción/whiff/VE/Decisión (ilegal, sin buffer) | Vetas laten (cuerpo, sin flash nuevo); Purga-en-suelo: ACEPTA con alivio 0 (UX anota). Binding gasto ≠ botón parry |

---

## Dynamic Behaviors

- **Fuera de duelo:** solo NW (Vida + Gracia). NE colapsada.
- **En duelo:** NE aparece (Postura + Vida jefe). Sin animación de entrada invasiva.
- **Aturdido:** S aparece (timer 120 ticks). Al conectar Castigo → colchón Repliegue con lectura propia (jefe acusa golpe, no reposiciona).
- **Ventana Especial:** Gracia pre-iluminada (ev.14) → al parar: Gracia se mueve, Postura no (ev.15, peor intercambio G7: +1/+1 sin postura ni repliegue) → al cerrar sin parar: repliegue de luz "esto ya va a ocurrir", cue irresoluto (ev.16). Cap Σ≤3/duelo: la 4ª VE a 1.0 da +0/+0 con log.
- **Freeze (corrige §stale Rev-1):** ya NO "mundo al 4%". **Freeze = pausa total del subárbol diegético 0% (`SceneTree.paused` por `WallTick`), HUD a 1.0x (`ALWAYS`)** (Combate R2 + Impacto R1). Transient de entrada 1 tick = juicio (≤2 ticks pared); esquirlas/shake al cierre = confirmación (≤10 ticks). Duraciones de freeze propiedad #4 (este spec no fija ticks). **HUD sigue a 60Hz** (C14). Mecanismo WallTick/DiegeticTick pendiente de ADR de tiempo — bloquea implementar, no diseñar.
- **Gasto en duelo:** solo en Telegrafiado/Enfriamiento/Repliegue (G7). Ilegal en Parry/Aturdido/Recepción/whiff/VE → RECHAZO sin buffer, sin consumir cap/cooldown, blip denegación opcional. Orden mismo-tick: earn→clamp+saturación→gasto (el gasto concurrente con saturación se RECHAZA). Dos gastos mismo tick: máximo uno ACEPTA. `gracia==coste` ACEPTA a 0.0.
- **Saturación:** al llegar C=100: clamp, `saturacion_alcanzada` una vez con snapshot, gasto off desde ese instante, handoff visual a #6 (quiebre a vitral pleno). TOMAR/DEJAR posterior no retracta (DEJAR a 94-tras-100 es de #6).
- **Vida baja:** vignette tinta progresiva + latido acelerado (solo alfa, nunca luz); muerte = corte seco + vela apagándose, suprime todo 800ms.
- **Pausa:** HUD atenuado 40%, S oculto, timer pausado (no cuenta), sin vignette animada ni rumble. Retorno por corte. Ajustes encima retorna al invocador. SET con flush fuera de duelo (nunca IO síncrono en pausa).
- **Hub / entre duelos:** solo NW (Vida + Gracia). NE colapsada, S oculto, bordes limpios. Gastos en Hub cargan al duelo siguiente a efectos de cap (spends), cooldown no resetea (monótono, SUS inicia SATISFECHO).
- **Decisión absorber / rechazar:** HUD oculto salvo medidor Gracia en NW a alta luminancia (la decisión ES gracia). Sin Postura / Vida jefe / timer. Ver `decision-gracia.md` (foco neutro, single-press + flanco fresco, SIN hold — carve-out a Menú R4).
- **Cutscene / diálogo Lucifer:** HUD oculto total. Retorno por corte 1 tick, sin fade.

### Notification Priority (cola visual)

Orden: 1 Muerte (ev.13) suprime todo 800ms → 2 Fallo flash #C75C4A (ev.5) suprime firma VE 200ms → 3 Firma VE parada/cierre (ev.15/16) → 4 Caída Postura (ev.8) → 5 Pre-light VE (ev.14) → 6 Timer continuo (fondo, nunca suprime) → 7 Feedback gasto (click/blip, nunca suprime a 1–4; si coincide con 2/3, se retrasa 1 tick).
Regla: nunca dos flashes en el mismo tick; el de menor prioridad se retrasa 1 tick (sigue cumpliendo 1–2 ticks). Misma prioridad propuesta a #16 para ducking de audio (tails ≤4, voces ≤12 — interinos hasta medición Deck).

---

## Platform & Input Variants

- **Targets:** PC Steam 16:9 + Steam Deck 7" (~30–40cm). Texto funcional ≥18px aparente. Safe-zone 5% (rango 3–7%, mínimo absoluto 3%).
- **Sin hover:** nada depende de hover o tooltip. On Demand por mantener (Tab / Touchpad / Back — a confirmar en implementación; no colisionar con parry digital C24 ni con binding de gasto G7).
- **Gamepad primario:** navegación completa por mando; HUD no interactivo salvo On Demand. Parry **digital** — ningún eje analógico mapeable (C24). Gasto en binding discreto dedicado (nunca botón parry).
- **Legibilidad vs IA #20 (el HUD no tapa lo que la IA exige leer):** telegrafiado 42 ticks (30–60), golpe 14 (10–20), enfriamiento 32 (20–50), S_base 24 + J16 (suelo J=14 normativo, conjunta `S−J/2≥11`). Silueta de telegrafiado >15–20% altura vertical (art bible 3.5). Si el HUD invadiese el centro, rompería el piso Regla 9 — por eso el centro es 0% permanente.
- **Rumble:** 80ms agudo en acierto / 200ms grave difuso en fallo — canal háptico distintivo. En Pausa: sin rumble.
- **Tiempo:** física 60Hz invariante (no bajar a 40Hz para batería). Render Deck puede ir a 40Hz → latch+hold 2 frames (P2) para no perder ticks; juicio sigue en ticks pared idénticos, tolerancia wall +1 frame render (Impacto C1).
- **Audio budgets (informativo para HUD):** peor caso = máx variante intra + tails cross + fragmento aborto + capa VE + click_gasto legal (máx 1 Amparo + 1 Purga por ventana, cooldown 360 + cap 2) + HUD + bed → interinos tails ≤4, voces ≤12, DSP ≤20% batería (heredados #4 P5-DEF, #16 solo estrecha hasta medir en Deck batería 40Hz con profiler/buffer/rate nombrados).
- **Verificación:** timing de parry y legibilidad HUD en hardware Deck real, no solo PC. Emisores: `CPUParticles2D` pineado (determinista, `finished` fiable) — validar coste pre-sprint (Impacto P0-DEF).

### Tuning Knobs (jugador)

| Knob | Rango | Default | Notas |
|---|---|---|---|
| `hud_opacity` | 0.6–1.0 | 1.0 | No baja luminancia del timer bajo 4.5:1 |
| `hud_scale` | 0.9–1.15 | 1.0 | Respeta mínimo 18px aparente |
| `timer_high_contrast` | bool | true en Deck, false en PC | Sube luminancia del gris frío (`#E8ECF1` solo si aplica) |
| `disable_damage_flash` | bool | false | Sustituye flash #C75C4A por icono con forma (fotosensibilidad) |

---

## Accessibility

> Tier no definido en proyecto — se propone **WCAG-AA como baseline**. Propiedad final sistema #21. Revisar en `/gate-check`.

- **Navegación:** teclado + mando llegan a todo lo interactivo (On Demand) en orden lógico, con foco visible (borde 2px `#C7CDD6` + cuneta, 0 glow — Menú R7).
- **No solo color:** Postura/Vida con forma + posición + movimiento, no solo croma. Timer como barra de luminancia, no número de color. Periferia no lee croma (luminancia + movimiento). Medidor Gracia con respaldo de forma obligatorio: densidad de grieta/esquirlas ◆◆◇◇ + posición NW + movimiento (succión/ascenso/latido gasto); color redundante, jamás único (Gracia UI + art bible 7.3).
- **Contraste:** fijar luminancia explícita para timer gris frío y barras sobre fondo tinta con mínimo 4.5:1 texto funcional (pendiente valor medido en Deck real, no solo editor — art bible 7.2).
- **Reduced-motion:** alternativa sin sacudida de cámara ni vignette pulsante; corte 1 frame, sin fades/flashes; hitstop/freeze diferencial se mantiene (es gameplay, no decoración). Decisión y Pausa colapsan a corte.
- **Deudas heredadas:** Parry Justo hoy solo micro-color #FFF8E7 + hitstop — necesita respaldo no-cromático/no-temporal (forma o háptico reforzado) para #21. Ciegas Sonoro SN-06 (forced-choice 9/10 aperturas 2 vs 14 a oído) pendiente playtest externo. IA: `parry_window` + `recuperacion_whiff` se exponen a #21 como par (bajar solo el segundo viola R6); ninguna duración #20 sin reverificar piso Regla 9 + R6 efectiva. SET inválido: fallback con aviso persistente no-modal (propiedad #21).

---

## Open Questions

- [x] ~~Cantidades de Gracia por parry / techo saturación~~ — RESUELTO lado-Gracia (APPROVED 2026-09-05): simple +1.0/+1.0, combo +0.5/parry, VE +1.0/+1.0 cap Σ≤3, Purga 8 / Amparo 12, alivio `/2` hasta suelo, TOMAR +12 poso +18 Vida + floor-lift, DEJAR −6 hasta suelo, techo 100 + gasto off + handoff #6. Este HUD solo interpola.
- [ ] Mecanismo de tiempo diegético sin `Engine.time_scale` (global en Godot 4.7) que deje HUD a velocidad normal — decisión de `/create-architecture` (ADR tiempo Pattern-A 0% + WallTick/DiegeticTick). **Bloquea implementar** (Feedback OQ).
- [ ] ADR arranque/router (`change_scene` único, splash ≤2.0s, foco tras splash, swallow 200ms) — bloquea Pausa/HUD `set_pausa_visual` cableado final.
- [ ] ADR checksum/canonicalización (SHA-256, auto-excluido R6 Guardado) —verify `poso` decreciente / n>3 / log≠n sin fabricar monotonicidad con defaults.
- [ ] ¿Qué hace #6 con 94-tras-100 (DEJAR IR en Saturada)? — owner Clímax #6 (Gracia Edge B3). Este HUD no cambia layout en Saturada.
- [ ] Medición Deck batería 40Hz: pineo `V_max`/`D_max`/`tails`/`voces` (peor caso exacto + profiler/buffer/rate nombrados) antes del Vertical Slice — owners #4/#16. Interinos: tails ≤4, voces ≤12, DSP ≤20%.
- [ ] Ciegas SN-06 + SN-13 (¿9/10 distinguen VE parada vs apertura y TOMAR solemne vs premio a oído?) — owner Audio #16 + playtest externo.
- [ ] Evento completación Acción Especial (sin evento hasta 4ª pasada sistema 2; variante sorda provisional Impacto R5) — ¿nuevo elemento HUD o solo sustain existente? Va a 4ª pasada, no a este spec.
- [ ] Player journey map no existe (`design/player-journey.md`). Template en `.claude/docs/templates/player-journey.md`. Sin él, fase emocional de llegada al duelo es suposición.
- [ ] Accessibility tier sin definir (`design/accessibility-requirements.md` no existe; sistema #21 Not Started). Propuesto WCAG-AA.
- [ ] Binding On Demand (números exactos) sin confirmar; no colisionar con parry digital (C24) ni con binding gasto G7.
- [ ] ¿Bastan 3 emisores GPUParticles2D con reciclado por `finished` + `pool_log`? ¿Coste CPUParticles2D validado pre-sprint? — pregunta a `technical-artist` (Impacto P0/P4/P5).
- [ ] Back-links pendientes que tocan este HUD: #15 tabla + inventario `MENU_DECISION_*` + foco neutro; Guardado fila AC rechazo por `poso` decreciente; R10e supervivencia conjunta (absorbs+reliquias+Amparo ≤+1, no-normativo hasta #9).

---

## Cross-Reference Check (Rev-2 auto 2026-09-05)

- **GDD requirements:** 5/5 Combate cubiertos (Vida/Postura/Vida-jefe/timer/Gracia) + Gracia G4/G5/G6/G7/G8/G10 cubiertos (earn/gasto/Decisión-solo-Gracia/saturación/poso) + Impacto (HUD ALWAYS + caída Postura ev.8) + Sonoro (co-alerta 5/13, timbres por bus) + IA (duraciones como constraint, no elemento) + Menú (Pausa `set_pausa_visual`, Decisión enrutada). Sistema 2: sin UI propia (correcto — no se añade nada por VE-completada hasta 4ª pasada).
- **New patterns to library:** ninguno nuevo — P1 (barra periférica) cubre timer/Vida, P2 (flash+vignette) cubre alertas/gasto-denegación-visual, P3 (firma VE) cubre Gracia/Postura. Feedback-gasto reutiliza P1+P3 + bus (no requiere P4).
- **Navigation mismatches:** ninguno — Decisión (`decision-gracia.md`) y Pausa (Menú R6) coinciden en HUD-oculto-salvo-Gracia y atenuado-40%+S-oculto.
- **Accessibility gaps:** tier sin definir (#21 Not Started); contraste luminancia timer sin valor medido; respaldo Justo no-cromático pendiente; ciegas SN-06/SN-13 pendientes.
- **Missing empty states:** N/A para HUD persistente (sin estado vacío; Purga-en-suelo es ACEPTA-alivio-0 anotado, no error; Saturada no cambia layout).

## Handoff

- **Next:** `/ux-review hud` validado 2026-09-05 (APPROVED, 0 blocking / 5 advisory). Gate Pre-Producción ya dispone del verdict para este spec.
- **No editar otros specs sin preguntar:** `decision-gracia.md` e `interaction-patterns.md` ya referencian este HUD correctamente; si `/ux-review` pide cambios, propagar vía `/propagate-design-change`.
- **Épicas:** systems-index #13 sigue `Not Started` (sin GDD — correcto: el spec UX ES el diseño). Al crear épicas (`/create-epics`), citar `design/ux/hud.md` Rev-2, no un GDD inexistente.

# ADR-003: Propiedad final del bus `Hitstop` (sistema 16) y frontera con Feedback de Impacto (sistema 4)

## Status

Accepted (2026-09-05, avance automático)

> Las historias de bus/mezcla pueden referenciar esta decisión como guía. Valores PROVISIONALES hasta SN-11/P5-DEF.

## Date

2026-09-05

## Last Verified

2026-09-05 — verificado contra `design/gdd/feedback-impacto.md` (Approved 2026-09-04, Supuesto (d) + OQ bus + Interactions), `design/gdd/feedback-sonoro-parry.md` (Draft 2026-09-05, Reglas 1/6 + OQ ★), ADR-001 (Accepted, fila 6 de consumidores) y `docs/architecture/tr-registry.yaml` (TR-parry-007/009). Sin verificación en motor real ni medición Deck en este acto.

## Decision Makers

- `technical-director` (autor de la decisión técnica)
- Usuario (aceptado 2026-09-05 — avance automático)

## Summary

Los GDDs #4 y #16 describen el mismo bus `Hitstop` desde lados opuestos y ambos lo marcan provisional. Se decide dueño único: el sistema 16 (Feedback Sonoro) posee timbre, mezcla, cadena de duck, steals y todos los valores del bus; el sistema 4 (Feedback de Impacto) posee triggers, ventanas, orden de prioridad y oráculos. Esto confirma —no corrige— lo que ambos GDDs ya pactaron y cierra la doble contabilidad sin enmienda normativa a #4.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (4.7.2-stable; proyecto pineado en línea 4.7) |
| **Domain** | Audio (AudioServer, buses, `playback_speed_scale`, ducking) + Core (pausa, `PROCESS_MODE_ALWAYS`) |
| **Knowledge Risk** | **MEDIUM** — buses y `playback_speed_scale` son comportamiento estable desde 3.x; pero no se consultó el módulo audio de la referencia en este acto y la medición Deck (profiler/buffer/rate) está sin nombrar |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, ADR-001 §Decision-fila 6, `design/gdd/feedback-impacto.md` (R1/R3/X3a/OQ-bus), `design/gdd/feedback-sonoro-parry.md` (R1/R6/Fórmulas/OQ-★) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Sí — criterio Deck en Validation Criteria (SN-11/P5-DEF). Sin ella, solo la propiedad queda fijada; los valores siguen PROVISIONALES |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (Accepted: pausa 0% Pattern-A, `Engine.time_scale == 1.0` y `AudioServer.playback_speed_scale == 1.0` pineados, transient a rate intacto, driver `WallTick` ALWAYS). Sin ADR-001 este ADR no tiene mecanismo sobre el que aplicar duck |
| **Enables** | Implementación del bus `Hitstop` por el sistema 16; medición P5-DEF/SN-11 en Deck |
| **Blocks** | Historias que creen, renombren, retuneen o escriban en el bus `Hitstop` (mezcla, duck, steals, gains) · historias #4 que fijen valores audio (gains/ms/cutoffs/semitones) |
| **Ordering Note** | Independiente de ADR-002 (contrato de eventos). No modifica ADR-001 ni ADR-002; los lee |

## Context

### Problem Statement

Doble contabilidad del mismo nombre `Hitstop`:

1. #4 (Approved) crea el bus provisionalmente (Supuesto (d)), fija profundidades interinas (−6 dB duck / −3 dBFS techo) y declara en su OQ: "propiedad final + cadena duck → sistema 16 al autorar 16".
2. #16 (Draft) reclama en su Regla 6: "la propiedad final se fija aquí: bus `Hitstop` propiedad de este sistema", con cadena documentada en Fórmulas, y deja OQ ★ espejo pendiente de ADR.

Sin ADR, ambas descripciones son prosa sin fuerza vinculante: un programador de #4 podría retunear gains y uno de #16 podría redefinir prioridades, rompiendo el pacto "qué/cuándo" vs "cómo suena" sin que ningún gate lo detecte. El coste de no decidir es divergencia silenciosa mezcla-vs-triggers.

### Current State

- Ambos GDDs **ya convergen** en el reparto (ver Decisión §1): #4 posee triggers/ventanas/prioridad/oráculos; #16 posee timbre/mezcla/steals/valores. La recomendación esperada del encargo se **confirma**; no hay corrección de reparto que hacer.
- Lo provisional no es el reparto sino su fuerza: #4 lo declara provisional hasta #16; #16 lo reclama unilateralmente en Draft. Falta el acto de arquitectura que lo haga bilateral y vinculante.
- ADR-001 ya anticipó este desenlace (fila 6: "propiedad final del sistema 16; bus `Hitstop` provisional en Feedback") pero no fijó la interfaz entre ambos.
- Colisión nominal aclarada en este ADR: `Hitstop.play(duracion)` (controlador de freeze, propiedad `WallTick`/triggers #4) ≠ bus audio `Hitstop` (cadena de duck, propiedad #16). Mismo StringName, dos objetos, dos dueños.

### Constraints

- **Diseño fijo heredado**: dominancia 11>4>3>8>15 con 9 en rango fondo; transient único intra-dirección (detector: pico secundario >−6 dB en 100 ms = FAIL); cross-dirección exento con ambos transients; `Engine.time_scale == 1.0` y `AudioServer.playback_speed_scale == 1.0` pineados (ADR-001/X3a, propiedad technical-director); bus `Hitstop` en `ALWAYS` para duck diegético durante el freeze.
- **Proceso**: prohibido commitear; prohibido tocar otro fichero; #4 está Approved (toda edición normativa = enmienda); #16 está Draft.
- **Valores**: todos los dB/ms/cutoffs/semitones/voces siguen PROVISIONALES hasta medición Deck (P5-DEF/SN-11). Este ADR fija propiedad e interfaz, nunca valores finales.

### Requirements

- TR-parry-007: contrato hitstop + cámara + rumble (base 5 ticks, bono Justo acotado por R8, Tweens en modo física) — lado #4 de la frontera.
- TR-parry-009: capas audio diegético vs UI/música, precedencia armónica, arquitectura bus/ducking con presupuesto de voces Deck — lado #16 de la frontera.

## Decision

**Dueño único: sistema 16.** El bus audio `Hitstop` es propiedad final del Feedback Sonoro del Parry (#16). El Feedback de Impacto (#4) es su cliente normativo y su oráculo, nunca su autor.

### §1. Reparto confirmado (sin corrección contra los GDDs)

| Posee #16 (cómo suena) | Posee #4 (qué/cuándo/piso medible) |
|---|---|
| Timbre, mezcla, armonía, buses (absorber/arrancar + `Hitstop`), cadena de duck, steals/robos de voz, todos los valores (gains, ms, cutoffs, semitonos, rates, `P`/`R`/`T_mezcla`/`voces_max`/`tails_max`/`DSP_bat_max`) | Triggers, ventanas de duración (juicio ≤2 / confirmación ≤10), orden de prioridad (11>4>3>8>15, 9 fondo), requisitos de discriminabilidad, oráculos de stems (C2 pico único, C5b-DEF sorda, C6-DEF peldaños), presupuestos interinos hasta medición |

Base GDD: #4 Interactions ("Sonoro posee timbre, mezcla, armonía, steals y valores; este GDD, el qué, el cuándo y el piso medible") + #16 Regla 1 (misma frase en espejo). Confirmado, no corregido.

### §2. Interfaz entre ambos

**#4 expone a #16** (consume #16 sin redecidir): evento resuelto + `freeze_total` (H_ref+B_ref, fusión `max()`, corte-por-golpe pre-emisión) + rango del set + ventana de juicio/confirmación + oráculo que lo verifica. Llama a `Hitstop.play(duracion_ticks)` (controlador `WallTick`, ALWAYS) y a `paused = true` en último lugar (R1 heredada).

**#16 expone a #4** (consume #4 sin redecidir): stems pre-master para los tres oráculos + método de ID ciega + cadena que cumple el techo. Implementa los buses por dirección y el duck por rango (ataque ≤1 tick normativo heredado, profundidad interina −6 dB, techo −3 dBFS, tails ≤4 / voces ≤12 / DSP ≤20% batería — interinos que solo #16 estrecha tras medir).

**Lo que nunca toca el otro:**

- #4 NUNCA escribe gains, cutoffs, releases, steals, layout de buses ni retunea valores audio. Sus cifras dB son pisos/caps interinos documentados como tales, no mezcla.
- #16 NUNCA decide veredictos, reinterpreta calidad/Justo, retunea H_ref/B_ref/ventanas, reordena la dominancia ni relaja guardas `1≤i≤N`, `N∈3..5`. Todo valor #1/#4 se consume por referencia viva; si #1/#4 retunean, #16 re-verifica, no re-declara.
- Invariantes compartidas (propiedad technical-director vía ADR-001, ambos respetan): `physics_ticks_per_second = 60`, `Engine.time_scale == 1.0`, `AudioServer.playback_speed_scale == 1.0`, transient de entrada a rate intacto, BT excluido de gates de timing.

### Architecture

```
  Combate (1) resuelve ──▶ Feedback-4: trigger + ventana + rango + freeze_total(max)
                                │  Hitstop.play(dur) [WallTick ALWAYS] + paused=true último
                                ▼
                         Bus audio `Hitstop` (ALWAYS) — PROPIEDAD #16
                         absorber (3,4,8,15) / arrancar (11) / fondo (9)
                         duck sustains bajo transient rank-1 (A≤1 tick, P/R, techo)
                                │
                                ▼
                         Stems pre-master ──▶ oráculos #4 (C2/C5b/C6-DEF) + ID ciega #16
```

### Key Interfaces

```gdscript
# #4 — lado trigger (lo que #4 emite; #16 nunca lo redecide):
# Hitstop.play(freeze_ticks: int)  # freeze_total = H_ref + B_ref(evt), fusión max(), corte pre-emisión
# signal freeze_started(duracion_ticks: int)  # una sola emisión por tick fusionado (WallTick)

# #16 — lado mezcla (lo que #16 implementa; #4 nunca lo escribe):
# bus_layout: ["Absorber", "Arrancar", "Hitstop"]  # Hitstop en ALWAYS, duck diegético en freeze
# duck(transient_rank_superior, sustain) -> G_duck(t) en [-P, 0] dB, A <= 1 tick, release R
# steal_policy: por dominancia 11>4>3>8>15 (9 fondo); nunca robar al 11 ni a un onset de freeze
# stems_pre_master: oráculo para C2 (pico único -6dB/100ms), C5b-DEF (sorda), C6-DEF (peldaños)
```

### Implementation Guidelines

1. El bus `Hitstop` se crea una sola vez por el sistema 16 (layout + cadena + defaults interinos). Ninguna historia #4 crea, renombra ni escribe parámetros del bus.
2. Ninguna historia #16 emite, fusiona ni corta freezes; consume `freeze_started` y ventanas #4 por referencia.
3. Todo knob audio vive en `assets/data/` (data-files, nunca hardcodeado); el juicio ≤2 ticks es presupuesto, no knob (espejo #4 X3a / #16 SN-15).
4. Hasta P5-DEF/SN-11: rigen los interinos (−6 dB / −3 dBFS / 4 tails / 12 voces / 20% DSP); #16 solo puede estrecharlos.

## Alternatives Considered

### Alternative 1: Propiedad final en #4 (el provisional se vuelve definitivo)

- **Description**: #4 conserva el bus y #16 le pide cambios de mezcla por propuesta.
- **Pros**: Un solo GDD Approved lo contiene todo; cero coordinación.
- **Cons**: Invierte la especialidad (diseño de feel escribiendo cadenas de mezcla), contradice la OQ ya aprobada de #4 ("propiedad final en 16"), la Regla 6 de #16 y la anticipación de ADR-001 fila 6. Obliga a enmienda normativa de #4 Approved.
- **Estimated Effort**: Menor hoy, mayor siempre (cada ajuste de mezcla reabre diseño de feel).
- **Rejection Reason**: Rechazada — rompe el pacto qué/cuándo vs cómo suena que ambos GDDs ya firmaron.

### Alternative 2: Propiedad compartida (ambos escriben el bus)

- **Description**: #4 fija duck/techo y #16 fija timbre/steals sobre el mismo bus sin barrera.
- **Pros**: Ningún GDD cede nada.
- **Cons**: Doble escritura sin árbitro: dos historias tocan la misma cadena y ningún test distingue quién rompió el techo. El detector −6 dB/100 ms no atribuye culpa.
- **Estimated Effort**: Nulo (es el estado actual sin ADR).
- **Rejection Reason**: Rechazada — perpetúa la doble contabilidad que este ADR existe para cerrar.

## Consequences

### Positive

- Un solo escritor del bus: toda regresión de mezcla (techo, duck, steals) atribuye a #16; toda regresión de trigger (ventana, fusión, prioridad) atribuye a #4. Los oráculos dejan de ser tierra de nadie.
- Cero reescritura de diseño: el reparto ya pactado en prosa se vuelve arquitectura vinculante sin tocar una sola regla normativa.
- P5-DEF/SN-11 quedan desbloqueables: hay un dueño medible del peor caso exacto en Deck.

### Negative

- #16 Draft asume una obligación con fecha (medición Deck pre-Vertical Slice con profiler/buffer/rate nombrados); hasta entonces sus valores son promesas, no norma — el proyecto convive con interinos.
- Carga de revisión permanente: cada historia #4 que mencione dB y cada historia #16 que mencione ticks debe redirigirse al dueño correcto (`story-readiness` lo exige).

### Neutral

- **Impacto en #4 (Approved): NO requiere enmienda normativa — solo back-link de trazabilidad.** Su Supuesto (d) y su OQ-bus ya dicen "provisional aquí, propiedad final en 16": este ADR les da la razón. Al aceptarse, su OQ pasa a "Resuelta por ADR-003 (propiedad); valores pendientes de P5-DEF" mediante addendum de trazabilidad (`design/gdd/feedback-impacto-amend-[fecha].md` solo si el proceso lo exige para tocar un Approved), sin reabrir `design-review` ni cambiar reglas, fórmulas o ACs.
- **Impacto en #16 (Draft): ratificación, no reescritura.** Su Regla 6 deja de ser reclamo unilateral y pasa a "ratificada por ADR-003"; su OQ ★ pasa a "propiedad cerrada por ADR-003; valores (P/R/T_mezcla/presupuestos) pendientes de medición SN-11". Sin cambio de medios ni de firmas por evento.
- Desambiguación nominal permanente: `Hitstop.play()` (freeze, #4/WallTick) vs bus `Hitstop` (duck, #16) — documentada aquí para que nadie los confunda en `dev-story`.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| #16 tarda en medir en Deck y los interinos se fosilizan como definitivos | Media | Medio (mezcla subóptima pineada por inercia) | P5-DEF/SN-11 como gate pre-Vertical Slice; interinos marcados PROVISIONAL en código y datos |
| Historia #4 retunea un gain "de pasada" y rompe el techo sin que el gate atribuya | Media | Medio | Payloads/buses cerrados: `story-readiness` rechaza valores audio en historias #4; SN-11 atribuye por stems |
| Historia #16 reordena prioridad o ventana "para que suene mejor" | Baja | Alto (rompe C2/C3/V1b de #4) | Barrera §2 "nunca toca": prioridad y ventanas se leen por referencia; cambio exige enmienda bilateral #4+#16 |
| `playback_speed_scale` o duck-en-pausa se comporta distinto en 4.7 (sin módulo audio consultado) | Baja | Medio (transient no intacto bajo freeze) | Validación Deck (transient ≤2 ticks en stems pre-master, altavoces + cable, BT excluido) antes de dar valores por finales |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | N/A (sin implementar) | Duck + stems solo en ventana de juicio/confirmación; sin varispeed global | ≤ 16.6 ms dock / ≤ 25 ms batería-40Hz (P1), P99 global y P99 ventana |
| Memory | N/A | Layout de 3 buses + stems de oráculo (solo debug; strip en release) | 1.5 GB techo proyecto |
| Load Time | N/A | Validación de layout al cargar (FAIL_LOAD si falta bus `Hitstop` o un emisor UI reproduce directo) | Sin presupuesto propio |
| Network (if applicable) | N/A | N/A (sin red) | N/A |
| Audio DSP (batería) | Interino sin medir | Voces ≤12, tails ≤4, DSP ≤20%, pico_suma ≤−3 dBFS (todos PROVISIONALES, solo se estrechan) | V_max/D_max definitivos en P5-DEF (Deck batería, perfil 40 Hz, peor caso exacto) |

## Migration Plan

Sin código que migrar (cero buses en `src/` hoy; el bus existe solo en prosa de GDD):

1. Al `Accepted`: #16 crea el bus `Hitstop` + absorber/arrancar con interinos y expone stems (historia bloqueada hasta entonces). Verificar: SN-01/SN-02.
2. Trazabilidad sin enmienda: back-links propuestos — fila "bus `Hitstop` propiedad #16 (ADR-003)" en #4 OQ/Supuesto (d) y cierre de OQ ★ en #16 — vía addendum, no edición silenciosa de un Approved.
3. Medición Deck pre-Vertical Slice (P5-DEF/SN-11) con profiler/buffer/rate nombrados en el plan de test; solo entonces los interinos se sustituyen por V_max/D_max. Verificar: SN-11.

**Rollback plan**: Si la medición Deck demuestra cadena inviable (techo incumplible con duck A≤1 tick), este ADR pasa a `Superseded` y se escribe ADR-003b (cadena alternativa con nuevo ataque/profundidad). La propiedad (#16) sobrevive al rollback; solo cambian los parámetros.

## Validation Criteria

- [ ] **V1 (BLOCKING, propiedad)**: en build limpia, el bus `Hitstop` existe una sola vez y su layout/cadena solo cambia desde historias #16; una historia #4 que intente escribir un parámetro del bus falla `story-readiness`.
- [ ] **V2 (BLOCKING, interfaz)**: trigger→duck de extremo a extremo en stems pre-master — `freeze_started(f)` ⇒ duck aplicado en la ventana de juicio con ataque ≤1 tick y transient intacto (oráculos #4 C1/C2 espejo #16 SN-02/SN-03).
- [ ] **V3 (BLOCKING, Deck)**: peor caso exacto (#4 P1 + #16 SN-11: máx variante intra + tails cross + fragmento aborto + capa VE + HUD + bed) en Deck real batería perfil 40 Hz, altavoces + cable (BT excluido), runs dock/batería separadas: voces≤V_max ∧ tails≤T_max ∧ DSP≤D_max ∧ pico_suma≤T_mezcla, con profiler/buffer/rate nombrados. Interinos hasta entonces.
- [ ] **V4 (ADVISORY, ciega)**: #16 SN-05/SN-12 (≥9/10 distingue 3/4/15 y 4+8 como variante, cross 8→11 legible) — confirma que la frontera qué/cómo preserva legibilidad, no bloquea la propiedad.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/feedback-impacto.md` | Impacto, Interactions + Supuesto (d) + OQ bus | Bus `Hitstop` provisional aquí, propiedad final en 16; Sonoro posee timbre/mezcla/steals/valores | Ratifica el reparto como arquitectura vinculante; #4 conserva triggers/ventanas/prioridad/oráculos y pierde toda escritura audio |
| `design/gdd/feedback-sonoro-parry.md` | Sonoro, Reglas 1/6 + OQ ★ | Propiedad final del bus `Hitstop` reclamada por #16; buses por dirección + duck por rango | Acepta el reclamo como dueño único bilateral; fija interfaz consumida (triggers/ventanas) y expuesta (stems/cadena) |
| TR-parry-007 | Parry (hitstop+cámara) | Contrato hitstop 5 ticks + bono Justo ≤8, Tweens físicos | Lado #4 de la frontera: duraciones y fusión `max()` entran al bus solo como `freeze_total`, nunca como mezcla |
| TR-parry-009 | Parry (audio/ducking) | Capas diegético/UI/música, precedencia, bus/ducking con presupuesto Deck | Lado #16 de la frontera: capas, precedencia ejecutada como duck/steal y presupuesto medido en Deck (P5-DEF/SN-11) |

## Related

- ADR-001 (tiempo autoritativo y hitstop — Accepted; fija pausa 0%, `time_scale`/`playback_speed_scale == 1.0`, transient intacto y driver `WallTick` que este ADR usa)
- ADR-002 (contrato de eventos combate-jefe — Accepted; audio-16 como suscriptor solo-lectura; este ADR añade el lado mezcla de ese suscriptor)
- `design/gdd/feedback-impacto.md` (Approved — back-link de trazabilidad al aceptar, sin enmienda normativa)
- `design/gdd/feedback-sonoro-parry.md` (Draft — Regla 6 ratificada, OQ ★ cerrada en propiedad al aceptar)
- `docs/architecture/tr-registry.yaml` (TR-parry-007 lado #4, TR-parry-009 lado #16 — sin altas/bajas/renumeraciones en este acto)

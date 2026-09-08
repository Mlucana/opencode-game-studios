# Cross-GDD Review Report — NOVENA

**Date:** 2026-09-07
**Mode:** consistency (Phase 2 + Phase 4; Phase 3 design-theory skipped)
**GDDs Reviewed:** 8
**Systems Covered:** #1 Combate de Parry-Absorción · #2 Máquina de Estados de Jefe · #4 Feedback de Impacto · #5 Sistema de Gracia de Tres Capas · #12 Guardado de Progreso · #15 Menú Principal y Flujo de Pantallas · #16 Feedback Sonoro del Parry · #20 IA de Combate de Jefes
**Also loaded:** `design/gdd/game-concept.md` (visión, MDA, pilares 1–5 + anti-pilares, MVP) · `design/gdd/systems-index.md` (21 sistemas, dependencias, estados) · `design/registry/entities.yaml` v15 (baseline, no vacía) · `.claude/docs/technical-preferences.md` + `docs/engine-reference/godot/VERSION.md` (Godot 4.7.2, GDScript, física 60 Hz invariante, parry DIGITAL, gamepad primario, Deck 7") · prior report `design/gdd/gdd-cross-review-2026-09-06.md` (verdict FAIL, 1 blocker) as baseline
**Pillars:** P1 El poder duele · P2 La maestría está en las manos, no en la ficha · P3 Cada enemigo es alguien · P4 El amor por encima de la cruzada · P5 La fe no es el villano.
**Anti-pillars:** NO relleno · NO resolver dificultad con números · NO sátira anticristiana · NO mundo abierto · NO multijugador/servicio en vivo.

> Método: Fase 1 carga completa (8 GDDs + concepto + índice + registry v15 + reporte previo). Fase 2 (2a–2f) ejecutada sobre inputs completos con el reporte 2026-09-06 como baseline a verificar. Fase 3 omitida por foco `consistency` — los warnings de diseño [3b]/[3e]/[3c] del reporte full siguen vivos sin re-verificar y viajan como constraints de arquitectura. Fase 4 walkthrough lean de 5 escenarios por el coordinador. Este informe no adjudica razón en contradicciones: presenta opciones.
> Nota de árbol: a fecha del review hay 5 GDDs + `systems-index.md` modificados sin commitear (`combate`, `gracia`, `ia`, `maquina`, `menu`); este veredicto aplica al working tree, no a HEAD. Se recomienda commitear antes de entrar a arquitectura para trazar a un commit pineado.

---

## Consistency Issues

### Blocking — none. ✅

**[2b-02] GR-08 (conteo de VEs) vs R9a/D13 (suma de severidades) — CLOSED in working tree.**
El blocker FAIL del 2026-09-06 (GR-08 con gate-OR por conteo dejaba pasar Σ=4>3) está corregido: Gracia G3 *"el gate es Σ+s > 3 con el `s` declarado del patrón (stub D13 hasta el loader del sistema 20), nunca un tope de conteo"*, GR-08 *"si Σ+s > 3 → +0/+0 con log (cap agregado R9a); si no → +1.0/+1.0. Sin cláusula de conteo: con s≡1.0 caben hasta 3 VE/duelo como consecuencia de Σ, no como gate; con s=2.0 la 2ª VE ya puede bloquearse (Σ=4>3)"*, F-C1/GF-C1 *"con s≡1.0 hasta 3 VE/duelo = 3.0 (3% techo) como consecuencia de Σ≤3, nunca como tope propio"*. Combate R9a (banda 1.0–2.0 + Σ≤3, D13 a/b/c con bordes 0.99-falla/1.0-pasa/2.0-pasa/2.01-falla) e IA F4 (Cosmos 40→1.12 ✓ / 80→2.24 ✗, techo robusto H≤66) sin cambios y de acuerdo. Ninguna otra contradicción bloqueante encontrada (ver INFO).

### Warnings (should resolve, but won't block)

⚠️ **[2a-01] Etiqueta "Requiere dos enmiendas" stale.** `maquina-estados-jefe.md` Dependencies: *"Requiere dos enmiendas en el doc de Combate — ver Interactions"* vs su propio header (5ª pasada 2026-09-06): *"las dos enmiendas pendientes… fueron APLICADAS (enmiendas A–G + CS8, 8ª pasada 2026-09-04)"*, y Combate L11–12 lista enmiendas A–G aplicadas con Regla 1 (emisor canónico = sistema 2) + Regla 4 (excepción VE). Cambio: reescribir la celda → "Enmiendas A–G aplicadas en Combate 8ª pasada 2026-09-04; verificado". Owner: systems-designer. Edición de 30 segundos.

⚠️ **[2a-02] OQ "fila reversa" stale — fila ya existe.** `feedback-impacto.md` OQ *"¿Fila reversa 'depended on by Feedback de Impacto' en Máquina (2)? … Pendiente"* + trazabilidad *"Máquina (2) 'depended on by Feedback' pendiente 4ª pasada (congelado)"* vs Máquina Dependencies 5ª pasada: *"Feedback de Impacto (4) + Feedback Sonoro (16) | Consumen (fila reversa)… Evento de completación ÚNICO y declarado"*. Cambio: cerrar/actualizar la OQ ("Resuelta 5ª pasada #2; pendiente solo re-review formal"). Owner: systems-designer.

⚠️ **[2a-03] Contraparte Guardado↔Menú existe; OQ pendiente stale.** `guardado-de-progreso.md` Dependencies *"Contraparte pendiente en #15 (ver Open Questions)"* + OQ *"Contraparte Menú: consumir fachada… | #15 Menú | Al revisar Menú Rev 2"* vs Menú Interactions: *"Este consume de Guardado… Simétrico al contrato declarado en Guardado"* + *"El menú no lee disco jamás"* + mapeo códigos→claves normativo. Cambio: marcar OQ como resuelta Rev2; verificación puntual de códigos (ver 2c-06). Owner: systems-designer.

⚠️ **[2a-04] Back-links Sonoro propuestos + Cross-refs "(no existe aún)" stale + registry "previsto".** `feedback-sonoro-parry.md` ↔ `combate-parry-absorcion.md` ↔ `menu-principal-y-flujo-de-pantallas.md` + registry. Sonoro: 'Back-link pendiente: fila "consumed by Sonoro (16)" en #1 (propuesta, no editada)' + 'timbres y ducking como propiedad de #16 en #15 (propuesta, no editada)'; Combate Dependencies: "Audio depende de Combate | Consume los mismos eventos" (genérico, sin fila explícita); Combate Cross-refs: `sistema-de-gracia.md` (path erróneo → `gracia-tres-capas.md`), `ia-combate-jefes.md (no existe aún)` (existe), `feedback-sonoro-parry.md (no existe aún)` (existe; `eleccion-de-reliquias/gestion-de-run/accesibilidad` correctamente ausentes). Registry: `parry_resuelto`/`combo_abortado` listan a `feedback-sonoro-parry.md` como "(no existe aún)"/PREVISTO aunque el GDD está Approved Rev-1. Cambios: (a) fila explícita consumed-by-16 + corregir paths en Combate; (b) "propiedad de Audio (#16)" en Menú; (c) confirmar sonoro como consumidor confirmado en registry. Owner: systems-designer.

⚠️ **[2a-05/06] Back-links Gracia + contratos anticipados Menú → futuros; etiqueta "#16 provisional" stale.** Gracia Dependencies: "Consistencia bidireccional pendiente: al autorar #3, #6, #9…" y Menú: "Todas las referencias a GDDs inexistentes son contratos declarados por anticipado" — correctos para futuros (#3 Run, #6 Clímax incl. 94-tras-100, #9 Reliquias incl. R10e + faucet prohibido, #7 Overlay, #13 HUD, #21 Accesibilidad). Pero la fila Audio de Menú *"Provisional hasta GDD #16"* está stale — #16 existe (Approved Rev-1) y realiza el catálogo (Sonoro Regla 10 + SN-14). Cambio: retirar solo la etiqueta #16-provisional. No BLOCKER por regla de futuros.

⚠️ **[2a-07] IA "declarado-no-cableado" + X1 literal-114 — lean re-confirmación post-5ª pasada.** `ia-combate-jefes.md` Regla 6/X1: `accion_especial_completada` + `castigo_conectado` "declarados-no-cableados" — escrito en Rev-1 (2026-09-05), antes de la 5ª pasada de Máquina (2026-09-06) que cerró nombres+payloads+órdenes por ADR-002 §2/§5. Además acotar X1 → "falla ante literal desnudo (sin derivación de ventana−gracia); casos 114/115 derivados de knobs declarados permitidos". Owner: systems-designer. El índice ya anota "veredicto pendiente de lean re-confirmación".

⚠️ **[2a-09] Flags R2.1/R2.2 + ADR de tiempo.** `feedback-impacto.md` Interactions conserva la fila conjunta (owner systems-designer + godot-specialist, pre-producción): "(a) R2.1… falsa bajo time_scale global; (b) R2.2… 4% + audio-escalado para los mismos ticks H_ref que este R1 congela a 0%" + OQ "¿ADR de tiempo…? | technical-director | Vertical Slice (bloquea implementar)". `docs/architecture/` contiene `adr-tiempo-autoritativo-y-hitstop.md` — confirmar que cubre la fila conjunta; al confirmar el ADR, reformular el flag (b) pues el "4%" está retirado en Combate ("semántica antigua, retirada"; rige 0% Pattern-A). Owners: technical-director (ADR), systems-designer + godot-specialist (fila conjunta).

⚠️ **[2a-10] Ciclo 2↔20 no foliado en el índice.** `systems-index.md` documenta solo 1↔5; Máquina propone añadir 2↔20 ("Se propone añadir este ciclo a esa misma sección en la Fase 5"); IA declara "Bidireccional, asimétrica (2↔20)". Cambio: añadir el ciclo en Fase 5. Owner: producer/systems-designer.

⚠️ **[2a-11] Columna Status del índice vs su propio Progress Tracker.** La tabla Systems Enumeration marca "Needs Revision" en las 8 filas (#1, #2, #4, #5, #12, #15, #16, #20), pero el Progress Tracker del mismo fichero lista 7 aprobados (#1 8ª pasada CS8 · #15 Rev2 · #4 Rev2 · #12 Rev2 · #5 lean Rev-1 · #20 lean Rev-1 · #16 lean Rev-1; solo #2 pendiente de re-review). Hallazgo de este review al verificar la pregunta de actualización de estados de Fase 6. Cambio: sincronizar la columna Status con el tracker (7 → Approved, #2 queda Needs Revision). Owner: producer/systems-designer.

⚠️ **[2b-04] R9b "pendiente" stale.** Combate R9b: "pendiente del GDD de Gracia" vs Gracia G3 + F-C1: "corrupcion_VE = 1.0 ∧ gracia_VE = 1.0", "Output {0.5,1.0} ⊂ (0,1.5] (banda_R9b); satisfecha por igualdad", GR-07. Cambio: una línea en Combate → "satisfecha por Gracia G3/F-C1 (igualdad 1.0 en banda_R9b owned-#5)". Owner: systems-designer. Edición de 30 segundos.

⚠️ **[2b-06] "Muerto solo desde Aturdido" + E5 vs daño futuro #19.** Máquina: "El jefe solo puede entrar en Muerto desde Aturdido" + E5 (Logic BLOCKING, aserción blanda en runtime + WARN) + nota "el Sistema de Efectos de Estado (19) introducirá daño fuera de Aturdido… y romperá E5 por diseño" + OQ al sistema 19 + IA Edge (E5 en rojo como alarma hasta que el 19 lo reescriba). Consistente hoy; owner: sistema 19 al autorarlo (reescribir E5, declarar interacción con Muerto, fijar desempate castigo-letal vs derrota simultánea). No BLOCKER.

⚠️ **[2b-07/2d-02] Literal "+18 Vida" en UI de Decisión.** Gracia UI TOMAR: "+18 Vida máx, +12 poso" vs No-knobs "+18 Vida (F5)" + GX-02 "passthrough, jamás calculado en #5". Cambio: referenciar por símbolo (+bono_vida_por_absorcion, F5 Combate, v1.0 18) o anotar lectura viva. Owner: systems-designer. Edición de 30 segundos.

⚠️ **[2c-04] Registry sin los 2 eventos de la 5ª pasada.** Máquina: `accion_especial_completada(habilidad_id: StringName, tick: int)` (ADR-002 §2) + `castigo_conectado(vida_restante: float, fue_letal: bool)` (§5, evento DISTINTO); IA Regla 6 los lista; registry `events:` termina en `run_viva_visible`. Cambio: añadir ambas filas (emitter #2; consumers #4/#16). Owner: systems-designer.

⚠️ **[2c-05] Nombre canónico vs prosa ("parry exitoso" vs `parry_resuelto`).** Registry `canonical_name: parry_resuelto` / `combo_abortado` (provisionales, pendientes de ADR) vs Gracia GX-01 "Combate emite parry_exitoso" (Sonoro/IA usan `parry_resuelto`). Cambio: al fijar ADR de eventos, unificar prosa; hasta entonces anotar equivalencia en registry. Owner: technical-director (ADR) + systems-designer.

⚠️ **[2c-06] Claves `MENU_DECISION_*` sin back-link en #15.** Gracia UI: `MENU_DECISION_TITLE / …_TOMAR/DEJAR_LABEL/DESC / MENU_DECISION_LEDGER / MENU_DECISION_IRREVERSIBLE / MENU_DECISION_QUIT_LINE` (≤120 chars; fija /localize) + "Requiere back-link en #15 (tabla + alcance R4) + claves MENU_*" vs Menú (solo `MENU_REASON_*`, `MENU_HOLD_*`, `MENU_HUB_*`, `MENU_NET_*`; verificado cero `MENU_DECISION_*` en el fichero). Cambio: inventariar en Menú (propiedad #5, enrutado #15) o declarar owned-#5 con copia informativa. Owner: systems-designer + writer (/localize).

⚠️ **[2c-07] `Hitstop.play` vs bus `Hitstop` / ADR-003.** Feedback R1 dispatch "`Hitstop.play()`…" + OQ "¿Bus Hitstop…? | sistema 16 | Provisional aquí" vs Sonoro Regla 6: "Bus Hitstop dedicado en ALWAYS… (propiedad cerrada por ADR-003 — dueño único #16…; interfaz Hitstop.play vs bus Hitstop per ADR-003…)". Cambios: (a) confirmar que `docs/architecture/adr-bus-hitstop.md` cubre la distinción llamada-vs-bus; (b) alinear creador provisional (#4) con dueño final (#16). Valores provisionales hasta SN-11/P5-DEF. Owners: technical-director + audio-director.

⚠️ **[2c-08] `set_pausa_visual` (owner HUD #13) + `run_viva_visible` (owner Run #3).** Menú: "Pausa ordena set_pausa_visual… (propiedad del HUD)" + "Spec en design/ux/hud.md (sin GDD aún)"; Guardado R9: "señal explícita run_viva_visible de Gestión de Run (la confirma Run)" + Menú "confirma run_viva_visible {run_uuid, coro_idx} con timeout y ruta de rechazo… Provisional: Run aún sin GDD" + registry "emisor provisional". Owners: HUD #13 y Run #3 respectivamente. No BLOCKER.

⚠️ **[2e-03] Freeze 5+2=7 con cero margen (R8 ≤ 8).** Combate R8 + Feedback: "esquina f=6+2 = 8 exacto: satisfacible con cero margen — frágil, documentado". Actual 7≤8 pasa. Opciones (owner systems-designer): (a) aceptar fragilidad documentada y fijar tolerancia de medición en D1/C13; (b) recortar `hitstop_parry` a 3–5 o el bono a +1 máx (re-deriva R8/D9-barrido/C13/D1). No BLOCKER.

⚠️ **[2e-04] H=30 (Humanidad) inalcanzable bajo R9a — latente.** IA Tuning: "curacion_por_accion_H | 30 (Hum.) / 40 (Cosmos) / 50 (Cercanía) con dano 30/40/50" vs F4: s = parries_extra_forzados × (1−0.72), parries_extra = (H/dano) × parries_por_ciclo (3/4/5), banda 1.0–2.0. Humanidad máx extra=(30/30)×3=3 → s=0.84 <1.0 (con H≤dano por F3, imposible alcanzar 1.0). Latente: la tabla de arquetipos asigna curación solo al Oficiante (Cercanía). Opciones (owner game-designer, OQ4): (a) declarar "sin curación interrumpible en Humanidad"; (b) retirar el provisional 30; (c) revisar banda solo-Humanidad (reabre R9a — desaconsejado).

⚠️ **[2e-05] Registry `piso_regla9` sin suelo.** Registry `piso_regla9` "output_range: [null, 40]" vs IA F1 "piso_exigido en [20, 40]" (12+margen, margen 8–28). Cambio: `output_range: [20, 40]` en `entities.yaml`. Owner: systems-designer. Una línea. (Techo 40<42 colchón post-Castigo: consistente.)

⚠️ **[2f-02] Redacción sorda-VE.** C5a/C4b/SN-10/C17 (whiff=6/6b, cero feedback) vs Regla 5 sorda (completación natural, excepción provisional única) + C5b-DEF/SN-09: sin conflicto (eventos distintos). Pero Máquina 5ª pasada dice "variante sorda provisional queda retirada a nivel de diseño (el runtime la sigue hasta la historia de cableado)" mientras Feedback/Sonoro dicen "provisional hasta entonces": unificar a "retirada a nivel de diseño / vigente en runtime hasta cableado" en los tres GDDs. Owner: systems-designer.

⚠️ **[2f-07] Tipo de emisor VFX sin unificar (bloquea P0-DEF).** Combate P0: "(Tipo de emisor pendiente de reconciliar: aquí GPUParticles2D ×3; Feedback R4 pinea CPUParticles2D 2+1 — unificar antes de P0-DEF.)" vs Feedback R4: "tipo pineado CPUParticles2D… con validación de coste pre-sprint". Owners: technical-artist + performance-analyst, pre-sprint. No bloquea arquitectura.

Notas INFO (sin cambio): R9a-equivalencia vs "nunca reduce Vida" RESUELTO (#1/#2/#20 coinciden); R5/R10a, R4 ambos lados, R6-efectivos, R8, techo/poso, caps/cooldown, freeze/trauma, S0–S5, firma Tipo-A vs carve-out Decisión single-press consistentes; derrota-congela (#2) vs teardown R11 (#4) vs E5/E7 (#1) con reparto documentado (restaura reloj = Feedback; supresión combo_abortado en derrota explícita); restantes(T)/borde 114-115 convergido (owner Combate, nunca literal); sin doble reclamo normativo de knobs (splits severidad banda/valor, N rango/asignación, vida_max cita/fijación, gracia_base consumo/propiedad, whiff-tail lectura-viva verificados); cadena daño/supervivencia/R9a + economía Gracia (103 > techo > 67 > 30 > 3.0) + retry/playtime/upsert/append/trauma/gasto compatibles; techo H 71 nominal vs 66 robusto documentado (puntero a tolerancia ±0.02); one-shot sin par contra-exigible; "idéntico" excluye timestamp/playtime explícitamente; hold vs single-press con carve-out bilateral; intra un-pico vs cross ambos-completan (ámbitos distintos); Muerto-solo-Aturdido vs derrota-congela (empate hoy inalcanzable); C5 "cualquier momento" vs cierre C5d (sugerencia: citar C5d en C5).

---

## Game Design Issues

### Fase 3 omitida por foco `consistency` — no re-verificado en este pase.
Viajan como constraints de arquitectura los 3 warnings del reporte full 2026-09-06: **[3b]** atención 7 activas > 4 (pico Oficiante) · **[3e]** curva "no-números" como curva de duración 12→30 parries + poso 0→36 vs anti-pilar A2 · **[3c]** R10e no-normativo + GX-13 gamesim sin archivar (no-dominancia bilateral sin evidencia). Ver dicho reporte para el detalle.

---

## Cross-System Scenario Issues

Scenarios walked: 5 — (1) VE parada al límite de Σ · (2) Castigo letal → victoria → reliquias → decisión → hub → SUS · (3) Golpe durante freeze con Amparo + derrota · (4) Mash-whiff + gasto en lockout + latch · (5) Earn saturante + gasto mismo tick + TOMAR en Saturada.

### Blockers — none.

**[S1] VE parada al límite de Σ — #1 + #2 + #5 + #20 — CLOSED.** Misma raíz que [2b-02], verificada en runtime: con Σ=2.0 consumida y siguiente VE s=2.0, GR-08 (Σ+s=4>3) concede +0/+0 con log en vez de +1.0/+1.0. Nota: la puerta primaria es validación de roster (Combate D13(b): un patrón cuyas VEs sumen >3 falla al cargar; con roster válido el gate-Σ es defensa en profundidad que nunca dispara). Sin cambio necesario.

### Warnings

⚠️ **[S2] Quit/kill en Decisión abierta — #5 + #12 + #15.** Trigger: quit/kill con Decisión abierta sin SUS nueva. Activación: #5 commit solo en memoria → #12 sin commit (pre_eleccion nunca suspendible, R5) → rearranque en última SUS post_decision o S1 (deltas perdidos, anti-scum). #15 muestra `MENU_DECISION_QUIT_LINE` ("Si sales ahora, esta elección queda sin guardar"). Unintended outcome: la promesa anti-scum vive en tres GDDs pero `MENU_DECISION_*` no está inventariado en #15 (2c-06) — la superficie puede prometer de más o de menos. Recomendación: cerrar 2c-06 + walkthrough GX-06/GX-12 con texto final /localize.

⚠️ **[S3] Amparo vs daño mismo tick — #1 + #2 + #4 + #5.** Trigger: Golpe conecta (25) con Amparo activo; en el mismo tick, segundo Golpe. Activación: #1 daño primer Golpe → #5 Amparo niega (1 vez, identidad-de-evento; VE lo atraviesa por corolario Regla 6) → segundo Golpe aplica pleno → #2 bifurca (Recepción 8-12, piso Regla 9 en techo) → #4 corte-por-golpe + vignette 12 + trauma conservado (no-letales) → #16 sordo sin cristal. Unintended outcome si el harness no existe: GR-24/GX-11 (stub VE-daño-0 + Golpe-daño-25) es hoy papel mojado — la identidad-de-evento es sutil y sin fixture se romperá en silencio al añadir daño-VE futuro. Recomendación: exigir el harness antes del primer sprint de Gracia.

⚠️ **[S5] 94-tras-100 sin dueño — #5 → #6.** Trigger: DEJAR IR (−6) en estado Saturada (C=100). Activación: #5 aritmética max(poso, 94) aplica pero handoff NO se retracta ("#6 posee la continuación (back-link: ¿qué hace #6 con 94-tras-100?)"). GASTO off en techo; TOMAR en Saturada legal (n+=1, poso min(+12,techo), C clamped). Unintended outcome: #6 sin GDD debe decidir si 94-tras-100 es paz-mantenida, recaída o desgarro-contado. No blocker (fuera de MVP) pero la aritmética post-saturación debe declararse al autorar #6.

### Info

ℹ️ **[S4] Mash + gasto-ilegal + latch-pierde-Justo — #1 + #4 + #5.** Trigger: mash durante lockout-whiff + intento de gasto + press en freeze. Activación: #1 descarta inputs en lockout (Regla 7, C17 cero feedback) → #5 descarta gasto en lockout/VE/Decisión sin buffer ni castigo (G7, GR-16) → #4 latch single-consume con t_press := tick detección (latcheados nunca Justo) → hold-a-través prohibido. Minor note: coherente por construcción; riesgo de incentivo ya en OQs con dueño (observar, no regular aquí).

---

## GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|---|---|---|---|
| gracia-tres-capas.md (#5) | GR-08 vs R9a — FIXED in working tree (Σ-gate, sin cláusula de conteo); solo esta confirmación, sin cambio de fichero | Consistency | Resolved |
| maquina-estados-jefe.md (#2) | Etiqueta "dos enmiendas" stale [2a-01]; ya Needs Revision (re-review pendiente) — solo fix de etiqueta | Consistency | Warning |
| combate-parry-absorcion.md (#1) | R9b "pendiente" stale [2b-04]; Cross-refs stale [2a-04]; fila consumed-by-16 genérica | Consistency | Warning |
| feedback-impacto.md (#4) | OQ fila-reversa [2a-02]; redacción sorda [2f-02]; flag R2.2-4% [2a-09]; bus Hitstop [2c-07] | Consistency | Warning |
| feedback-sonoro-parry.md (#16) | Back-links propuestos [2a-04]; redacción D-C sorda [2f-02]; ADR-003 confirm [2c-07] | Consistency | Warning |
| ia-combate-jefes.md (#20) | Lean re-confirmación post-5ª pasada [2a-07]; H-Humanidad latente [2e-04]; OQ1–OQ4 vigentes | Consistency | Warning |
| menu-principal-y-flujo-de-pantallas.md (#15) | Etiqueta #16-provisional [2a-05/06]; MENU_DECISION_* [2c-06]; set_pausa_visual #13 [2c-08] | Consistency | Warning |
| guardado-de-progreso.md (#12) | OQ contraparte #15 stale [2a-03] | Consistency | Warning |
| systems-index.md | Añadir ciclo 2↔20 (Fase 5) [2a-10]; sincronizar Status con tracker (7 Approved) [2a-11] | Consistency | Warning |
| design/registry/entities.yaml | 2 eventos 5ª pasada [2c-04]; consumidores sonoro previsto→confirmado [2a-04]; piso_regla9 [20,40] [2e-05]; equivalencia parry_resuelto [2c-05] | Consistency | Warning |
| — (diseño, no re-verificado) | Atención 7>4 [3b]; curva duración vs A2 [3e]; R10e + GX-13 sin evidencia [3c] | Design Theory | Warning (constraints) |

---

## Verdict: CONCERNS

0 blocking consistency issues in the working tree — the 2026-09-06 FAIL blocker ([2b-02]/[S1]) is closed. Remaining items are warnings with owners: label fixes, one-line registry edits, and future-GDD contracts. Un-re-verified design warnings [3b]/[3e]/[3c] travel as architecture constraints. Working tree dirty (5 GDDs + index uncommitted): commit before architecture so it traces to a pinned commit.

## Required actions before re-running:
None blocking. Re-run `/review-all-gdds` (full) only after: (a) the #2 re-review lands, or (b) any GDD is significantly revised, or (c) before `/create-architecture` if more than a few warnings above were edited — otherwise enter `/create-architecture` directly carrying [3b]/[3e]/[3c] + S3-harness-gate + S5-note as constraints.

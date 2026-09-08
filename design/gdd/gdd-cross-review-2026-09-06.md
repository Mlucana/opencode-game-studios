# Cross-GDD Review Report — NOVENA

**Date:** 2026-09-06
**Mode:** full (consistency + design-theory + scenario walkthrough)
**GDDs Reviewed:** 8
**Systems Covered:** #1 Combate de Parry-Absorción (Approved) · #2 Máquina de Estados de Jefe (Needs Revision) · #4 Feedback de Impacto (Approved Rev2) · #5 Sistema de Gracia de Tres Capas (Approved lean Rev-1) · #12 Guardado de Progreso (Approved Rev2) · #15 Menú Principal y Flujo de Pantallas (Approved Rev2) · #16 Feedback Sonoro del Parry (Approved lean Rev-1) · #20 IA de Combate de Jefes (Approved lean Rev-1)
**Also loaded:** `design/gdd/game-concept.md` (visión, MDA, pilares 1–5 + anti-pilares, MVP) · `design/gdd/systems-index.md` (21 sistemas, dependencias, estados) · `design/registry/entities.yaml` v15 (baseline, no vacía) · `.claude/docs/technical-preferences.md` + `docs/engine-reference/godot/VERSION.md` (Godot 4.7.2, GDScript, física 60 Hz invariante, parry DIGITAL, gamepad primario, Deck 7")
**Pillars:** P1 El poder duele · P2 La maestría está en las manos, no en la ficha · P3 Cada enemigo es alguien · P4 El amor por encima de la cruzada · P5 La fe no es el villano.
**Anti-pillars:** NO relleno · NO resolver dificultad con números · NO sátira anticristiana · NO mundo abierto · NO multijugador/servicio en vivo.

> Método: Fase 1 carga completa (8 GDDs + concepto + índice + registry v15). Fases 2 y 3 ejecutadas en paralelo por dos agentes (consistencia 2a–2f; holismo 3a–3g) sobre los mismos inputs. Fase 4 walkthrough de 5 escenarios multi-sistema por el coordinador. Este informe no adjudica razón en contradicciones: presenta opciones.

---

## Consistency Issues

### Blocking (must resolve before architecture begins)

🔴 **[2b-02] GR-08 (conteo de VEs) vs R9a/D13 (suma de severidades)**
- GDDs: `gracia-tres-capas.md` ↔ `combate-parry-absorcion.md` (+ #20).
- Citas: Gracia G3: "cap efectivo es min(3 VE, Σ ≤ 3)" pero GR-08: "GIVEN Σ severidad = 3 consumida (stub D13…) OR 3 VE a 1.0, WHEN siguiente VE mismo duelo, THEN +0/+0…; GIVEN Σ < 3, THEN +1.0/+1.0 (cap efectivo min(3 VE, Σ ≤ 3))" vs Combate R9a: "1.0 ≤ severidad_accion_especial ≤ 2.0 por Ventana Especial, y Σ severidad ≤ golpes_para_morir_base − 1 (= 3)" + D13: "se comprueban las dos cláusulas por separado… Un patrón que viole cualquiera de las dos falla al cargar" + IA F4 (Cosmos H=80 → s=2.24 ✗).
- Contra-ejemplo: primera VE con s=2.0 (Σ=2<3, conteo 1<3) → GR-08 concede la 2ª VE +1.0/+1.0 → Σ=4>3, violando R9a aunque cada término esté en banda.
- Qué debe cambiar (opciones, sin adjudicar): (a) en `gracia-tres-capas.md`, reescribir GR-08 para evaluar Σ vía stub D13 (bloquear cuando Σ+s>3, sin cláusula de conteo independiente); (b) alternativamente, pinnear s≡1.0 para toda VE (colapsa la banda R9a — desaconsejado: destruye F4/OQ4); (c) si se mantiene algún cap de conteo, formularlo como consecuencia documentada de Σ (p. ej. "≤3 VEs solo cuando s≡1.0"), nunca como gate OR. Owner: systems-designer (Gracia) con D13 de Combate como oráculo.

### Warnings (should resolve, but won't block)

⚠️ **[2a-01/2c-01] Etiqueta "Requiere dos enmiendas" stale — sustancia RESUELTA** — `maquina-estados-jefe.md` ↔ `combate-parry-absorcion.md`. Máquina Dependencies: "Requiere dos enmiendas en el doc de Combate" vs Combate L11–12: "Enmiendas forzadas del 2026-08-04 (A) ventana parable… (B) i<N → 1≤i≤N… (C) recuperacion_recepcion… (D) duelo ganado/perdido… (E) restantes(T) inclusivo borde 114… (F)… (G)…" + Regla 1 (emisor canónico = sistema 2) + Regla 4 (excepción VE). Cambio: editar la celda de Máquina → "Enmiendas A–G aplicadas en Combate 8ª pasada 2026-09-04; verificado". Owner: systems-designer.

⚠️ **[2a-02] OQ "fila reversa en #2" stale — fila ya existe** — `feedback-impacto.md` ↔ `maquina-estados-jefe.md`. Feedback OQ: "¿Fila reversa depended on by Feedback en Máquina (2)? … Pendiente" vs Máquina Dependencies: "Feedback de Impacto (4) + Feedback Sonoro (16) | Consumen (fila reversa)… Evento de completación ÚNICO y declarado (5ª pasada 2026-09-06)". Cambio: cerrar/actualizar la OQ ("Resuelta 5ª pasada #2; pendiente solo re-review formal"). Owner: systems-designer.

⚠️ **[2a-03] Contraparte Guardado↔Menú existe; OQ pendiente stale** — `guardado-de-progreso.md` ↔ `menu-principal-y-flujo-de-pantallas.md`. Guardado L219 + OQ "Contraparte pendiente en #15" vs Menú Interactions: "Este consume de Guardado… Simétrico al contrato declarado en Guardado" + "El menú no lee disco jamás" + mapeo códigos→claves normativo. Cambio: marcar OQ como resuelta Rev2; verificación puntual de códigos (2c-06). Owner: systems-designer.

⚠️ **[2a-04+2a-08] Back-links Sonoro propuestos + Cross-refs "(no existe aún)" stale** — `feedback-sonoro-parry.md` ↔ `combate-parry-absorcion.md` ↔ `menu-principal-y-flujo-de-pantallas.md` + registry. Sonoro: 'Back-link pendiente: fila "consumed by Sonoro (16)" en #1 (propuesta, no editada)' + 'timbres y ducking como propiedad de #16 en #15 (propuesta, no editada)'; Combate Dependencies: "Audio depende de Combate | Consume los mismos eventos" (genérico, sin fila explícita); Combate Cross-refs: "sistema-de-gracia.md / eleccion-de-reliquias.md / ia-combate-jefes.md (no existe aún)" (los tres existen hoy). Cambios: (a) fila explícita consumed-by-16 + corregir paths en Combate; (b) "propiedad de Audio (#16)" en Menú; (c) confirmar `feedback-sonoro-parry.md` como consumidor confirmado de `parry_resuelto`/`combo_abortado` en registry (hoy "previsto"). Owner: systems-designer.

⚠️ **[2a-05/2a-06] Back-links Gracia + contratos anticipados Menú → futuros** — Gracia Dependencies: "Consistencia bidireccional pendiente: al autorar #3, #6, #9 (y enmiendas de #1, #12, #15)… Verificará /consistency-check". Menú: "Todas las referencias a GDDs inexistentes son contratos declarados por anticipado". Owners: #3 Run, #6 Clímax (94-tras-100), #9 Reliquias (R10e + faucet prohibido), #7 Overlay, #13 HUD, #21 Accesibilidad. #16 ya existe (Approved Rev-1) y realiza el catálogo (Sonoro Regla 10 + SN-14): retirar etiqueta "Provisional hasta GDD #16". No BLOCKER por regla de futuros.

⚠️ **[2a-07/2c-03] IA "declarado-no-cableado" + X1 literal-114** — `ia-combate-jefes.md` ↔ `maquina-estados-jefe.md`. IA Regla 6/X1: `accion_especial_completada` + `castigo_conectado` "declarados-no-cableados" vs Máquina 5ª pasada 2026-09-06 (nombres + payloads + órdenes cerrados por ADR-002 §2/§5). Rev-1 IA (2026-09-05) precede a la 5ª pasada (2026-09-06): lean re-confirmación de que "no cableado" sigue cierto y nombres/payloads/órdenes coinciden. Además acotar X1 → "falla ante literal desnudo (sin derivación de ventana−gracia); casos 114/115 derivados de knobs declarados permitidos". Owner: systems-designer. Index ya anota "veredicto pendiente de lean re-confirmación".

⚠️ **[2a-09] Flags R2.1/R2.2 + ADR de tiempo pendientes** — `feedback-impacto.md` ↔ `combate-parry-absorcion.md`. Feedback Interactions: "Flags cruzados (una fila, owner systems-designer + godot-specialist, pre-producción): (a) R2.1… falsa bajo time_scale global; (b) R2.2… 4% + audio-escalado para los mismos ticks H_ref que este R1 congela a 0%… Precedencia interina aquí… condicionales al ADR de tiempo (pendiente)" + OQ "¿ADR de tiempo…? | technical-director | Vertical Slice (bloquea implementar)". Al crear el ADR: el "4%" está retirado en Combate ("semántica antigua, retirada"; rige 0% Pattern-A) — reformular el flag (b). Owners: technical-director (ADR), systems-designer + godot-specialist (fila conjunta).

⚠️ **[2a-10] Ciclo 2↔20 no foliado en el índice** — `systems-index.md` documenta solo 1↔5; Máquina propone añadir 2↔20 ("Se propone añadir este ciclo a esa misma sección en la Fase 5"); IA declara "Bidireccional, asimétrica (2↔20)". Cambio: añadir el ciclo en Fase 5. Owner: producer/systems-designer.

⚠️ **[2b-04] R9b "pendiente" stale** — Combate R9b: "pendiente del GDD de Gracia" vs Gracia G3 + F-C1: "corrupcion_VE = 1.0 ∧ gracia_VE = 1.0", "Output {0.5,1.0} ⊂ (0,1.5] (banda_R9b); satisfecha por igualdad", GR-07. Cambio: una línea en Combate → "satisfecha por Gracia G3/F-C1 (igualdad 1.0 en banda_R9b owned-#5)". Owner: systems-designer.

⚠️ **[2b-06] "Muerto solo desde Aturdido" + E5 vs daño futuro #19** — Máquina: "El jefe solo puede entrar en Muerto desde Aturdido" + E5 + nota "el Sistema de Efectos de Estado (19) introducirá daño fuera de Aturdido… y romperá E5 por diseño" + OQ al sistema 19 + IA Edge (E5 en rojo como alarma hasta que el 19 lo reescriba). Owner: sistema 19 (al autorarlo: reescribir E5, declarar interacción con Muerto, fijar desempate castigo-letal vs derrota simultánea). No BLOCKER.

⚠️ **[2b-07/2d-02] Literal "+18 Vida" en UI de Decisión** — Gracia UI TOMAR: "+18 Vida máx, +12 poso" vs No-knobs "+18 Vida (F5)" + GX-02 "passthrough, jamás calculado en #5". Cambio: referenciar por símbolo (+bono_vida_por_absorcion, F5 Combate, v1.0 18) o anotar lectura viva. Owner: systems-designer.

⚠️ **[2c-04] Registry sin los 2 eventos de la 5ª pasada** — Máquina: `accion_especial_completada(habilidad_id: StringName, tick: int)` (ADR-002 §2) + `castigo_conectado(vida_restante: float, fue_letal: bool)` (§5, evento DISTINTO); IA Regla 6 los lista; registry `events:` termina en `run_viva_visible`. Cambio: añadir ambas filas (emitter #2; consumers #4/#16). Owner: systems-designer.

⚠️ **[2c-05] Nombre canónico vs prosa ("parry exitoso" vs `parry_resuelto`)** — registry `canonical_name: parry_resuelto` / `combo_abortado` (provisionales, pendientes de ADR) vs Gracia GX-01 "Combate emite parry_exitoso", Sonoro/IA usan `parry_resuelto`. Cambio: al fijar ADR de eventos, unificar prosa; hasta entonces anotar equivalencia en registry. Owner: technical-director (ADR) + systems-designer.

⚠️ **[2c-06] Claves `MENU_DECISION_*` sin back-link en #15** — Gracia UI: `MENU_DECISION_TITLE / …_TOMAR/DEJAR_LABEL/DESC / MENU_DECISION_LEDGER / MENU_DECISION_IRREVERSIBLE / MENU_DECISION_QUIT_LINE` (≤120 chars; fija /localize) + "Requiere back-link en #15 (tabla + alcance R4) + claves MENU_*" vs Menú (solo `MENU_REASON_*`, `MENU_HOLD_*`, `MENU_HUB_*`, `MENU_NET_*`; cero `MENU_DECISION_*`). Cambio: inventariar en Menú (propiedad #5, enrutado #15) o declarar owned-#5 con copia informativa. Owner: systems-designer + writer (/localize).

⚠️ **[2c-07] `Hitstop.play` vs bus `Hitstop` / ADR-003** — Feedback R1 dispatch "`Hitstop.play()`…" + OQ "¿Bus Hitstop…? | sistema 16 | Provisional aquí" vs Sonoro Regla 6: "Bus Hitstop dedicado en ALWAYS… (propiedad cerrada por ADR-003 — dueño único #16…; interfaz Hitstop.play vs bus Hitstop per ADR-003…)". Cambios: (a) confirmar que ADR-003 existe en `docs/architecture/` y cubre la distinción llamada-vs-bus; (b) alinear creador provisional (#4) con dueño final (#16). Valores provisionales hasta SN-11/P5-DEF. Owners: technical-director + audio-director.

⚠️ **[2c-08/2c-09] `set_pausa_visual` (owner HUD #13) + `run_viva_visible` (owner Run #3)** — Menú: "Pausa ordena set_pausa_visual… (propiedad del HUD)" + "Spec en design/ux/hud.md (sin GDD aún)"; Guardado R9: "señal explícita run_viva_visible de Gestión de Run (la confirma Run)" + Menú "confirma run_viva_visible {run_uuid, coro_idx} con timeout y ruta de rechazo… Provisional: Run aún sin GDD" + registry "emisor provisional". Owners: HUD #13 y Run #3 respectivamente. No BLOCKER.

⚠️ **[2e-03] Freeze 5+2=7 con cero margen (R8 ≤ 8)** — Combate R8 + Feedback: "esquina f=6+2 = 8 exacto: satisfacible con cero margen — frágil, documentado". Opciones (owner systems-designer): (a) aceptar fragilidad documentada y fijar tolerancia de medición en D1/C13; (b) recortar `hitstop_parry` a 3–5 o el bono a +1 máx (re-deriva R8/D9-barrido/C13/D1). Hoy se cumple (7≤8): no BLOCKER.

⚠️ **[2e-04] H=30 (Humanidad) inalcanzable bajo R9a** — IA Tuning: "curacion_por_accion_H | 30 (Hum.) / 40 (Cosmos) / 50 (Cercanía) con dano 30/40/50" vs F4: s = parries_extra_forzados × (1−0.72), parries_extra = (H/dano) × parries_por_ciclo (3/4/5), banda 1.0–2.0. Humanidad máx extra=(30/30)×3=3 → s=0.84 <1.0 (con H≤dano por F3, imposible alcanzar 1.0). Latente: la tabla de arquetipos asigna curación solo al Oficiante (Cercanía). Opciones (owner game-designer, OQ4): (a) declarar "sin curación interrumpible en Humanidad"; (b) retirar el provisional 30; (c) revisar banda solo-Humanidad (reabre R9a — desaconsejado).

⚠️ **[2e-05] Registry `piso_regla9` sin suelo** — registry `piso_regla9` "output_range: [null, 40]" vs IA F1 "piso_exigido en [20, 40]" (12+margen, margen 8–28). Cambio: `output_range: [20, 40]` en `entities.yaml`. Owner: systems-designer. (Techo 40<42 colchón post-Castigo: consistente.)

⚠️ **[2f-02] Redacción sorda-VE** — C5a/C4b/SN-10/C17 (whiff=6/6b, cero feedback) vs Regla 5 sorda (completación natural, excepción provisional única) + C5b-DEF/SN-09: sin conflicto (eventos distintos). Pero Máquina 5ª pasada dice "variante sorda provisional queda retirada a nivel de diseño (el runtime la sigue hasta la historia de cableado)" mientras Feedback/Sonoro dicen "provisional hasta entonces": unificar a "retirada a nivel de diseño / vigente en runtime hasta cableado" en los tres GDDs. Owner: systems-designer.

⚠️ **[2f-07] Tipo de emisor VFX sin unificar (bloquea P0-DEF)** — Combate P0: "(Tipo de emisor pendiente de reconciliar: aquí GPUParticles2D ×3; Feedback R4 pinea CPUParticles2D 2+1 — unificar antes de P0-DEF.)" vs Feedback R4: "tipo pineado CPUParticles2D… con validación de coste pre-sprint". Owners: technical-artist + performance-analyst, pre-sprint. No bloquea arquitectura.

Notas INFO (sin cambio o menor): R9a-equivalencia vs "nunca reduce Vida" RESUELTO (ítem 0 corregido; #1/#2/#20 coinciden); R5/R10a, R4 ambos lados, R6-efectivos, R8, techo/poso, caps/cooldown, freeze/trauma, S0–S5, firma Tipo-A vs carve-out Decisión single-press consistentes; derrota-congela (#2) vs teardown R11 (#4) vs E5/E7 (#1) con reparto documentado (restaura reloj = Feedback; supresión combo_abortado en derrota explícita); restantes(T)/borde 114-115 convergido (owner Combate, nunca literal); sin doble reclamo normativo de knobs (splits severidad banda/valor, N rango/asignación, vida_max cita/fijación, gracia_base consumo/propiedad, whiff-tail lectura-viva verificados); cadena daño/supervivencia/R9a + economía Gracia (103 > techo > 67 > 30 > 3.0) + retry/playtime/upsert/append/trauma/gasto compatibles; techo H 71 nominal vs 66 robusto documentado (puntero a tolerancia ±0.02); one-shot sin par contra-exigible; "idéntico" excluye timestamp/playtime explícitamente; hold vs single-press con carve-out bilateral; intra un-pico vs cross ambos-completan (ámbitos distintos); Muerto-solo-Aturdido vs derrota-congela (empate hoy inalcanzable); C5 "cualquier momento" vs cierre C5d (sugerencia: citar C5d en C5).

---

## Game Design Issues

### Blocking — ninguno. (Fase 3: 0 blockers.)

### Warnings

⚠️ **[3b] Presupuesto de atención: 7 activas > 4 en duelo** — #1+#2+#20+#5+#4+#16+#13. Activas: A1 leer telegrafiado (tele 30-60, golpe 10-20) · A2 timing parry digital (13 activo / 9 lockout) · A3 gestión whiff-lockout · A4 conteo combo i/N (N 3-5, S 17-31) · A5 dilema VE en vivo (+1.0/+1.0 vs s 1.0-2.0) · A6 gasto Purga/Amparo (cooldown 360, cap 2/duelo, gating 6 estados) · A7 borde Castigo 114/115 + recuperación 10-14 vs colchón 42. Pasivas ~8 (vignette 12+punch ≤2, HUD, trauma/shake 0.30/0.55/0.70 S_max 24 decay 12, tells por tríada, earn auto, freeze 0% + rampa 2, esquirlas, cuerpo-corrupción): no deciden. Redundancia ojos-cerrados (#4+#16 mismo veredicto por dos canales, transient ≤2 ticks) resta carga, no suma. Pico: Oficiante (50% simples / 30% combos N 4-5 / 20% VE + curación) junta A4+A5+A6. Opciones: (a) regla de autoría: ningún patrón mezcla combo N≥4 y VE en la misma rotación de 2 ciclos (intervalo_min 2 ciclos ya provisional); (b) gasto-en-Hub por defecto (G7: "primero decidir, gastar en el Hub"), mid-duelo solo emergencia; (c) HUD #13 colapsa A4+A5 en una sola firma ("Gracia se mueve / Postura no" extendida a combo-remate); (d) validar Deck V1b/SN-12 (N=10, ≥9/10) antes de cerrar #20 OQ2/OQ3 — si falla, escala a BLOCKER de arquitectura HUD.

⚠️ **[3e] Curva "no-números" es curva de duración 12→30 parries + poso 0→36** — #1+#20+#5. Tabla lanzamiento: postura_max 30/40/50 (+67%) · ciclos 4/5/6 · parries totales 12/20/30 (+150%) · dano_golpe_enemigo 25 fijo ✅ · punish 25%/20%/16.7% (inverso) · dano/castigo vs vida_max proporcional (ciclos exactos) · telegrafiado/golpe/enfriamiento por arquetipo (rango, no rampa) · S_base 18-30 + J 14-24 · margen 8-28 · H proporcional a dano · techo 100 fijo vs earn ~20-30/duelo · poso 0/12/24/36 (headroom 100→64). Sin divergencia exponencial: jugador +18/duelo lineal vs enemigo en duración (tolerancia 33%→13% emerge de la longitud — F8, Pilar 1 literal). Pero 12→30 (+150%) ES escalado numérico aunque sea de duración; gramáticas aún PROVISIONALES (OQ1 Vigilante/Coro/Oficiante). Si OQ1 colapsa a mismos patrones con más Vida, el anti-pilar A2 se viola de facto; el poso es presión numérica pura (defendible como P1, no como legibilidad). Opciones: (a) renombrar en arquitectura a "curva de duración/resistencia" y medir legibilidad aparte (playtest "¿leen la gramática antes que la silueta?"); (b) acotar A2 a "no escalar letalidad ni stats del jugador" (daño 25 fijo, multiplicador_ataque=1.0, R10); (c) recortar duración y mover dificultad a gramática (exige OQ1 cerrada).

⚠️ **[3c] Dos válvulas anti-dominancia sin evidencia: R10e (no-normativo) + GX-13 gamesim sin archivar** — #5+#9+#20. Cerrados por invariante+AC: mash (R6 59% + lockout 9 + digital C24 + J≥14 + C12b; residual 84% en racha mitigado por varianza), ignorar-VE (R9a banda+suma + R9b + C22/C23/D13; exige `s` declarada como FAIL_LOAD), spam Purga (coste 8 + cap 2 + cooldown 360 + floor-stop), whiff-farming (faucet único GR-06/GX-10), espera pasiva (sin faucet fuera de parry). Abiertos: absorber-siempre (R5 + R10a + purga 6 evitan colapso mecánico, pero no-dominancia bilateral exige GX-13: LOW 0.45 win_rate absorb>pura Δ≥1 duelo; HIGH 0.90 saturation absorb>pura Δ≥1 o ≥25pp — [M con protocolo], sin evidencia) y spam Amparo (1/duelo + duel-scoped + identidad-de-evento, pero cap conjunto en R10e propuesto no-normativo ≤+1). Run pura válida y más dura (GR-15: n=0, C=49, R10-safe) pero diversión sin probar. Opciones: (a) correr GX-13 antes de arquitectura #9; (b) derivar R10e al autorar #9 o fallback Amparo-consume-R10a; (c) mantener `s`-declarada como FAIL_LOAD.

INFO (resto Fase 3): un solo core con dos caras (parry→gracia→corrupción→saturación→clímax; victoria→reliquia→decisión→hub en serie estricta; "parar bien = condenarse" legible — no hay 3 cores); retención largo-plazo en sistemas Not Started (#9/#10/#17/#3/#6) con deuda ya nombrada en concepto e índice (arquitectura: hojas que solo añaden faucets/sinks tipados; MVP-slice ~5 reliquias utilitarias-cero-daño); economía intencionalmente desbordante (earn/duelo ~20-30 vs spend máx 24 con /2 diminishing → 67+36=103>100 tardío duelo-3; exceso destruido; floor-stop sin loop; poso monótono exige G9 decreciente antes del 4º ángel; feedbacks positivos TOMAR/curación-VE temáticamente correctos — contar earn-VE en el protocolo de techo OQ); sin catch-up numérico (correcto P2); 8/8 GDDs sirven ≥1 pilar (#2/#12 infraestructuras con habilitación declarada, no drift; 0 violaciones anti-pilar duras; roce A2 documentado arriba); 8 fantasías compatibles (soy hábil / máquina invisible / cargo luz que quema / peso irreversible / clavar el Cielo + tragar luz / sacramento robado / carácter aprendible / cruzada que esperaba) con fricciones hábil-vs-paciente (el juego; canal Overlay+cuerpo ya previsto + test legibilidad OQ#5 con fallback una-barra+tick-poso) e invisible-vs-alguien (bien resuelta: 9 cerrados + sub-estados) y sobriedad-vs-exceso (partición duelo-Menú: muerte pesada-en-duelo + muda-en-menú; no reabrir coro en menú).

---

## Cross-System Scenario Issues

Scenarios walked: 5 — (1) VE parada al límite de Σ · (2) Castigo letal → victoria → reliquias → decisión → hub → SUS · (3) Golpe durante freeze con Amparo + derrota · (4) Mash-whiff + gasto en lockout + latch · (5) Earn saturante + gasto mismo tick + TOMAR en Saturada.

### Blockers

🔴 **[S1] VE parada al límite de Σ — #1 + #2 + #5 + #20.** Trigger: parry exitoso contra Ventana Especial con Σ severidad = 2.0 previa (una VE a 2.0 ya consumida). Activación: #2 emite `ventana_especial_cerrada(fue_parada=true)` → #1 resuelve (0 Postura, 0 Repliegue, veredicto VE) → #5 earn +1.0/+1.0 por GR-08 (Σ=2<3, conteo 1<3) → #4 freeze f=5 + firma "Gracia se mueve / Postura no" → #16 percusión sin cuerpo. Data flow issue: el earn de #5 no consulta Σ+s>3 (stub D13); Σ resultante = 4.0 > 3 viola R9a agregada con cada término en banda. Player experience: "Gracia se mueve / Postura no" sobre estado ilegal + Gracia que financia Purga/Amparo con moneda que R9a prohíbe. Mismo BLOCKER que 2b-02 visto en runtime. Resolución: reescribir GR-08 sobre Σ (ver arriba).

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
| gracia-tres-capas.md (#5) | GR-08 vs R9a — gate por conteo deja pasar violación de suma | Consistency | Blocking |
| maquina-estados-jefe.md (#2) | Etiqueta "dos enmiendas" stale; OQ i/N + margen cerrables; sigue a re-review + V1 ADR motor | Consistency | Warning (ya Needs Revision) |
| combate-parry-absorcion.md (#1) | R9b "pendiente" stale; Cross-refs "(no existe aún)"; fila consumed-by-16 | Consistency | Warning |
| feedback-impacto.md (#4) | OQ fila-reversa cerrable; redacción sorda; flag R2.2-4%; bus Hitstop; emisores | Consistency | Warning |
| feedback-sonoro-parry.md (#16) | Back-links propuestos; redacción D-C; ADR-003 confirm | Consistency | Warning |
| ia-combate-jefes.md (#20) | X1/literal-114 + placeholders post-5ª pasada; H-Humanidad latente; OQ1–OQ4 vigentes | Consistency | Warning |
| menu-principal-y-flujo-de-pantallas.md (#15) | Etiqueta #16-provisional; MENU_DECISION_*; set_pausa_visual #13 | Consistency | Warning |
| guardado-de-progreso.md (#12) | OQs stale (contraparte #15, rangos-Gracia, R9b) | Consistency | Warning |
| systems-index.md | Añadir ciclo 2↔20 (Fase 5) | Consistency | Warning |
| design/registry/entities.yaml | 2 eventos 5ª pasada; consumidores sonoro; piso_regla9 [20,40] | Consistency | Warning |
| — (diseño) | Atención 7>4 (pico Oficiante); curva duración vs A2; R10e + GX-13 sin evidencia | Design Theory | Warning |

---

## Verdict: FAIL

1 blocking issue ([2b-02]/[S1]) must be resolved before architecture begins. Todo lo demás son warnings con owner/deadline o pendientes de GDDs futuros (#3/#6/#7/#9/#10/#11/#13/#14/#17/#19/#21) y ADRs (tiempo, eventos, ADR-003).

## If FAIL — required actions before re-running:
1. En `gracia-tres-capas.md`: reescribir GR-08 para evaluar Σ vía stub D13 (bloquear cuando Σ+s>3, sin cláusula de conteo independiente) — owner systems-designer. Alternativas documentadas en [2b-02].
2. Re-run `/review-all-gdds consistency` (solo Fase 2) para confirmar el cierre; si pasa, el veredicto pasa a CONCERNS (warnings de diseño vivos) y se puede entrar a `/create-architecture` con los 3 warnings de Fase 3 ([3b], [3e], [3c]) como constraints de arquitectura.

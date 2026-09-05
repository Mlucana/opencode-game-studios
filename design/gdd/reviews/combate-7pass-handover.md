# Handover — revisión 7ª pasada `combate-parry-absorcion.md` (2026-09-04)

> Revisión NEEDS REVISION (8 especialistas + CD, top-10 + D-1..D-20 adjudicados).
> Revisión propia pausada por colisión con track concurrente tras 1 edit aplicado
> (R2.1 → condicional-al-mecanismo, sin solape). Este documento es el handover completo.

## Decisiones de usuario ya tomadas (no reabrir)

Forbid quality-relics · absorb visual+run-level only · fallback haptic-first ·
timer-bar+stance+V8a · HUD-preillum tercer canal · R1 load-WARN (no narrow) ·
banda R9a scoped 65–80% · C4 orden causal Postura→Gracia→Hitstop→Repliegue.

## 1. Freeze conformance (godot B1/B2/B4/B6/B7)

R2.2 → 0% Pattern-A; reemplazar bucket-audio por transient-intacto/sustain
(draft: *"El SFX de impacto (3,4,7,8,11,15) se divide en transient de entrada
—antes del freeze, rate intacto, juicio <100ms— y sustain/cola que resuelve al
cierre con rampa. Durante freeze a 0% no hay escala que aplicar. UI/música
siempre normal. Buses/ducking en sistema 16; qué/cuándo en Feedback R1/R13.
`playback_speed_scale`=1.0 vía ADR"*). Tocar: filas eventos 3/8/15, Impact
Moments, paréntesis C14 (+frase agnóstica al régimen), sección UI-hitstop,
renombrar 5× `GPUParticles2D`→`CPUParticles2D` (pin Feedback R4 salvo medición),
OQ (a)–(g) rewrite mundo-pausa, reframe Sobre-R8.

## 2. P1 (perf B1/B2)

Trigger canónico = solape secuencial 8 T0→11 T+6 (mismo-tick degradado a unit
test lógico); tabla 6 gates (a/b/c × dock16.6/batería25), per-forcing, ventana
±5 ticks-física anclada inicio-rampa+0, warmup 120 + profiler remoto + 600.
P0→puntero (total en art bible), P4→puntero a soak de Feedback. Nuevo **T0
fixture-AC** (trigger spec + owner + split trigger/loader).

## 3. V-package (ux B1–B4, game B5, qa F7/F10)

V5: N=10/k≥9 forced-choice + tercer canal HUD-preillum ≤2 ticks normativo +
V5-isolated/V5-loaded + concesión arte. V6→V6a-first-exposure + V6b + contrato
tutorial (staging primera VE; trigger debug extensible). **V8a provisional
aquí:** 3 estados × forced-choice 3AFC+“no sé”, ≥8/10 por estado + behavioral
(castigos accidentales <5%, hesitación <10%); V8b canónico en tutorial.
V7→V7a (cierre≠alivio) + V7b (cierre≠completación, atado a sistema 2).

## 4. R9a (game B1/B2, economy B1)

Σ≤gpm−2 (margen, era igualdad exacta); scope “tuned 65–80%”; pins worst-case
(parries_por_ciclo a calidad 0 + factor combo + H-ceil); rate owner (sistema 20
cadencia + qa-lead tasa viva; salir de 0.70–0.74 fuerza re-derivar); semántica
esperanza/agregado-peor-caso-ceil explícita; **D13(d)** recomputación
independiente + verificación tercera.

## 5. R10 (economy B2–B4, qa F6)

R9b floor ≥1 parry-quantum (declara sistema 5). **FORBID** reliquias intra-duelo
recovery + reliquias quality/precision (extensión R10). C26 + **C26-bis
equip-time** (set ilegal no se equipa) + mandato enumeración D15 (pares
co-equipables mínimo) + D8 acotado a configs legales (solo mecanismo) + línea
de orden C26→D8.

## 6. Audio (audio B1–B8)

Precedencia: borrar −12dB/+40ms → ambos mensajes sobreviven + detector stems +
prioridad transient-4 (variante tímbrica = candidata de 16). V4 bloqueado-a-16
(método+oráculo+protocolo) + barra 3-vías ≥7/10 N=10. P5: copiar caps interinos
(tails≤4/voces≤12/DSP≤20%/no-BT) + stack conjunto (VE+aborto+HUD+bed).
Evento 9: línea “nunca el thud del 5” + cerrar OQ (+ frase espejo: 5-thud del
golpe + 9-disolver como cues separadas). Regla conjunta freeze-vs-sustain
(sustain duckea, ventana en pared) + **C28** continuidad de sustain.

## 7. Ticks (godot B3/B5, qa F3/F11/F12)

Espejar latch-consumidor + **C27**: intento sintético único,
`t_press`:=detección (latcheados nunca Justo), whiff/launder/hold guards.
C13a: borrar waiver 40Hz + ticks de knob + wall-clock por perfil; C18
operativo + scope fuera-de-freeze. **C4**: orden causal
Postura→Gracia→Hitstop→Repliegue + spy pineado
(`tests/helpers/signal_order_spy.gd`) + emisión pre-pausa.

## 8. QA (qa F1/F4–F8/F10 + R)

C22/C23/D13 headers de dos niveles; **C6**: `vida_actual -=
dano_golpe_enemigo` (F8=25 derivado) + clamp + “duelo perdido”, DADO ampliado.
Purga segundos (C5/D4/E8/C8/evento-10/UI; C11 exento como modelo). E8
baseline mismo-patrón ±0. Header refresh (Status/AC≈74/R1–R10).

## 9. Mash/corners (game B6/R2–R4, systems R2/R3)

C12b: stub owner + métrica de varianza + release-gate. R1: WARN en carga +
D9b exacto (no narrow). R2: malla 50 celdas en D9b (total 96→142). Absorb:
declaración visual+run-level.

## 10. Higiene (game B4/N, systems R1/R5/R6/NITs)

Evento 9 → OUTSIDE (gana el nuevo). **C25**: salvo 4+8 (rige precedencia/V4).
F5 ejemplo 146 (no 128); bono 19–20 guidance (19→≥104, 20→≥110; † en celdas +
CI). Filas drift → orden juicio-antes/confirmación-cierre (evento 7 fuera de
Pattern-A). Pins producción por referencia. Rango D9 exacto (R1: exactamente 1
en (15,0.5,20)).

## Ojo con el frente en vuelo

El stub sub-regla-2 (0%) convive con R2.1 ya aplicada; los splits C7/C8/C13/C16
+ fixture-levels + glosario tocan los mismos ACs que los rewrites C6/C22/C4 —
integrar, no duplicar.

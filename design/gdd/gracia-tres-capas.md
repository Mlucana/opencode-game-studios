# Sistema de Gracia de Tres Capas

> **Status**: In Design
> **Author**: [user + agents]
> **Last Updated**: 2026-09-04
> **Implements Pillar**: Pilar 1 (El poder duele) — también sostiene la ambivalencia del Pilar 2 y el Pilar 4 (lo que persiste es memoria)

## Overview

El Sistema de Gracia de Tres Capas es la economía moral de NOVENA: convierte cada parry exitoso en gracia robada que corrompe al protagonista (acumulación), deja elegir tras cada ángel si absorber su esencia o rechazarla (elección explícita) y permite gastar gracia para desatar poderes robados, aliviando parcialmente la corrupción pero dejando siempre un poso irreversible (recurso gastable). Como capa de datos expone `angeles_absorbidos` a Combate (Fórmula 5), emite niveles a HUD, Overlay y Clímax, y persiste vía Guardado sin tocar disco; como experiencia es lo que hace que jugar bien duela — la barra de progresión y la de sufrimiento son la misma barra (Pilar 1). Sin este sistema el parry sería defensa con premio y la tragedia no existiría.

## Player Fantasy

El jugador debe sentir que carga una luz que no era para él: no hacerse más fuerte, sino seguir en pie cuando debería haber caído. Cada parry deja gracia ardiendo donde no cabe; cada victoria obliga a decidir — tomarla (poder real, veta permanente) o dejarla ir (digno, nunca castigo); cada gasto alivia sin borrar, porque el poso permanece. El momento ancla: tras dos o tres absorciones el jugador se ve — tinta atravesada por vetas violeta que laten al gastar — y entiende sin tutorial que puede frenar la caída pero nunca detenerla. El ángel sigue siendo luminoso y bueno mientras lo tomas; el dolor viene de que era bueno (Pilar 5). La pregunta nunca es a quién vas a matar, sino a quién se lo llevas (Pilar 4). Verba de duelo, no de botín: tomar, cargar, aliviar, poso.

## Detailed Design

### Core Rules

1. **G1 — Ledger triple y vocabulario. Propiedad de #5.** El estado es exactamente tres floats `≥0` JSON-safe: `gracia_actual` (bolsa gastable), `corrupcion_actual` (progreso hacia el Clímax #6), `poso_irreversible` (suelo). Invariantes: `poso ≤ corrupcion ≤ techo`, `0 ≤ gracia ≤ techo`. No existe otro estado de gracia. Verba: `tomar / cargar / aliviar / poso / dejar ir`; jamás loot/almas/maná (Pilar 5).
2. **G2 — ACUMULACIÓN: faucet único, event-driven.** Ante cada `parry_exitoso` de Combate (simples, intermedios de combo y VE-parada), ejecución atómica: `gracia_ganada = 1.0 × modificador_combo` (`1.0` simple/VE, `0.5` por parry en combo — consumido verbatim de Combate, R7); `gracia_actual += gracia_ganada; corrupcion_actual += gracia_ganada`. La misma barra es progresión y sufrimiento (Pilar 1). Combo N=3–5 rinde `1.5–2.5` por 1 instancia de Postura: rico en gracia, pobre en postura, por construcción.
3. **G3 — VE-parada: el peor intercambio, nunca gratis (R9b).** Concede `1.0` a ambos ledgers con cero Postura y cero Repliegue (Regla 4 Combate): corrupción-por-progreso infinita. Mata la dominación invertida (parar dominaría a ignorar). Acotado por R9a (`Σ severidad ≤ 3` por duelo → ≤3 motas VE/duelo). Si #5 descontase jamás la gracia de VE, R9a debe re-derivarse (constraint-handoff declarado).
4. **G4 — ELECCIÓN EXPLÍCITA: independiente, irrevocable, post-reliquia.** Tras cada ángel, pantalla Decisión (propiedad de #5, enrutada por #15): exactamente `TOMAR / DEJAR IR`. Independiente por ángel (`decision_absorber[i] ∈ {0,1}`, `angeles_absorbidos = suma`). Commit atómico e inmediato en memoria; Guardado solo escribe SUS en `post_decision`, jamás `pre_eleccion` (R5 Guardado). Sin re-elegir por recarga, sin absorción parcial, sin omitir.
5. **G5 — TOMAR: los tres efectos disparan juntos, nunca selectivos.** (a) `angeles_absorbidos += 1` → Fórmula 5 Combate (`+18` Vida Máx v1.0, plano); (b) `poso_irreversible += 12.0` plano v1.0 (visión-9: decreciente por conteo, G9); (c) desbloquea el poder robado de ese coro (ficción por identidad, magnitudes idénticas — preserva independencia de orden). Sin lump inmediato de gracia (evita doble-contar el ingreso por parry). Reparación de invariante: TOMAR eleva `C`: `C' = max(C, poso')` — si el suelo adelantó a `C` (gasto hasta el suelo + TOMAR), el commit levanta `C` al nuevo suelo; nunca al revés.
6. **G6 — DEJAR IR: la pureza tiene mecánica, no solo narrativa.** Sin Vida, sin poso, sin poder. En su lugar: `corrupcion_actual = max(poso, corrupcion_actual − 6.0)`. Sin purga, absorber dominaría estrictamente en supervivencia y el dilema colapsaría; con purga: TOMAR = +supervivencia/+inevitabilidad, DEJAR IR = −supervivencia/−inevitabilidad. La run pura (`absorbidos = 0`) es válida y la más dura. R10-safe: no toca Vida, ciclos, parries/ciclo ni cobertura.
7. **G7 — GASTO: alivio y amparo, nunca daño. Con compuerta.** Acciones gastables consumen `gracia_actual` (exige `gracia ≥ coste`, sin deuda ni parciales) y alivian proporcional: `corrupcion := poso + (corrupcion − poso) / 2`. Plantilla MVP cerrada a dos poderes: **Purga** (coste 8, solo alivio, sin efecto de combate) y **Amparo** (coste 12, niega el daño del próximo Golpe fallado una vez, máx 1/duelo). Prohibidos: daño a Vida, daño a Postura, castigos extra, ventanas, robo de vida, conversión daño→gracia. Trigger: binding discreto dedicado (nunca el botón de parry); legal en `Telegrafiado / Enfriamiento / Repliegue / Hub / post-reliquia / post-decisión`; ilegal en `Parry activo / Aturdido / Recepción / lockout-whiff / VE activa / Decisión abierta` → descartado sin buffer (anti-mash, espejo de Regla 7 Combate). La decisión commitea contra ledger estable: primero decidir, gastar en el Hub. Cooldown 360 ticks (6 s) + cap 2 gastos/duelo + máx 1 amparo activo.
8. **G8 — TECHO: la saturación es handoff, no muerte.** Si `corrupcion_actual ≥ 100.0`: clamp sin overflow, emite `saturacion_alcanzada` al Clímax #6 y deshabilita GASTO (no se gasta para esquivar la oferta). Seguir tras la paz cuesta desgarro permanente (propiedad de #6).
9. **G9 — Extrapolación a 9 coros: decreciente POR CONTEO, no por identidad.** v1.0 congela HP lineal (`+18`) y poso plano (`+12`) para n≤3 (R5). Visión: funciones solo de `n` (conmutan → independencia de orden, Regla 8/AC E9); dirección preferida: HP legible + poso superlineal, con R5_9 re-derivada antes del 4º ángel — nunca extrapolación silenciosa.
10. **G10 — Persistencia opaca + contrato de lectura.** #5 jamás toca disco; expone a Guardado el triple + `angeles_absorbidos + decision_log[]` verbatim cada `post_decision`. A HUD/Overlay/Clímax expone niveles y eventos de solo-lectura (`gracia_cambiada, corrupcion_cambiada, poso_cambiado, saturacion_alcanzada`), jamás setters. Epsilons: `1e-9` identidad (round-trip Guardado R9), `1e-6` para cero (patrón E13).

### States and Transitions

| Estado | Definición | Entrada | Salida / guardia |
|---|---|---|---|
| `Latente` | `C = 0, P = 0` (inicio de run) | Reset run-scoped (Run) | Primer `parry_exitoso` o primer absorber → `Cargada` |
| `Cargada` | `0 < C < 100` | Parry / gasto / decisión | Clamp bilateral; gasto legal solo según compuerta G7 |
| `Saturada` | `C ≥ 100` (clamped, sin overflow) | Techo alcanzado | GASTO deshabilitado; `saturacion_alcanzada` → #6; continuar = desgarro (#6) |
| `Decisión` (por duelo) | Post-reliquia, pre-Hub | Commit TOMAR / DEJAR IR → Hub | Irrevocable; jamás punto `pre_eleccion` de SUS |

Compuerta de gasto (G7): **legal** en `Telegrafiado / Enfriamiento / Repliegue / Hub / post-reliquia / post-decisión`; **ilegal** (descartado sin buffer) en `Parry activo / Aturdido / Recepción / lockout-whiff / VE activa`.

### Interactions with Other Systems

| Sistema | Dirección | Interfaz (qué fluye, quién posee qué) |
|---|---|---|
| #1 Combate | Bidireccional (contrato) | Consume `parry_exitoso {calidad_timing, tipo}` ya resuelto + `modificador_combo` verbatim; expone `angeles_absorbidos` (Fórmula 5); declara R9b (coste VE = 1.0 en ambos ledgers); poderes jamás tocan Vida/Postura (contrato R10). Simétrico a F7/R7/F5/R9b de Combate |
| #2 Máquina | Este consume (veredicto) | VE distinguida vía veredicto de Combate; VE no parada = `+0/+0` (corolario R6) |
| #3 Run | Bidireccional (provisional) | Reset run-scoped al iniciar (triple a 0, n = 0, log vacío). Asunción abierta de Combate: regla de Vida por duelo (este GDD no la toca) |
| #12 Guardado | Este expone a Guardado | Triple + `n` + `decision_log[]` verbatim cada `post_decision`; opaco (`≥ 0`, JSON-safe). Requiere fila AC en Guardado: rechazo por `poso` decreciente + rango `0–9` (back-link a anotar) |
| #9 Reliquias | Este restringe (contrato) | Prohibido faucet de gracia en reliquias (sin tick pasivo, sin farm de hub, sin gracia de reliquia). Propuesto **R10e**: supervivencia conjunta (absorbs + reliquias + Amparo) ≤ +1 sobre absorbs; todo poder declara deltas R10 (extiende C26) |
| #13 HUD | Este expone (solo-lectura) | Niveles + 4 eventos; Decisión muestra solo Gracia en alta luminancia (spec HUD) |
| #7 Overlay | Este expone a Overlay | Mapa permanente lee `C/P`; esquirlas temporales del evento 9 quedan en Combate (sin doble sangrado) |
| #6 Clímax | Este emite a Clímax | `saturacion_alcanzada {triple snapshot, absorbidos}`; GASTO off en techo |
| #15 Menú | Hermanos (presentación) | Enruta victoria → reliquias → decisión → hub. Decisión propiedad de #5 con **single-press + flanco fresco, SIN hold** (el hold protege destrucción de run/SUS; aquí la fricción castigaría P4). Requiere back-link en #15 + claves `MENU_*` |
| #16 Sonoro | Este emite a Sonoro | Capas por gasto/decisión/saturación (propiedad de #16) |
| #21 Accesibilidad | Este consume (fallo) | Assist que ensancha ventana acelera corrupción: debe escalar `gracia_base` proporcionalmente (fallo #21) |

## Formulas

The `gracia_ganada` formula is defined as:

`gracia_ganada = gracia_base * modificador_combo`

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| gracia base | `gracia_base` | float | `= 1.0` locked | motas por parry simple, propiedad de #5 |
| modificador combo | `modificador_combo` | float | `{1.0, 0.5}` locked | 1.0 simple/VE, 0.5 por parry en combo (Combate, R7) |

**Output Range:** discreto bilateral `{0.5, 1.0}` por parry; conjunto cerrado, sin clamp.
**Example:** simple `1.0 × 1.0 = 1.0`; en combo `1.0 × 0.5 = 0.5`; combo N=3 → `3 × 0.5 = 1.5 > 1.0` ✓ R7.

The `corrupcion_ganada` formula is defined as:

`corrupcion_ganada = gracia_ganada` · `corrupcion_VE = 1.0 ∧ gracia_VE = 1.0`

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| gracia ganada | `gracia_ganada` | float | `{1.0, 0.5}` | entrada desde F-G1 |
| corrupción ganada | `corrupcion_ganada` | float | `{1.0, 0.5}` | salida al ledger de corrupción |
| banda VE | `banda` | float | `0 < x ≤ 1.5` bilateral | banda legal por ganancia (R9b) |

**Output Range:** `{0.5, 1.0} ⊂ (0, 1.5]`; satisfecha por igualdad en ambos lados.
**Example:** simple → ambos ledgers `+1.0`; en combo → ambos `+0.5`; VE-parada → ambos `+1.0` sin Postura ni daño; máx 3 VE/duelo → `3.0`.

The `gasto` formula is defined as:

```
si coste > gracia → RECHAZAR (sin cambio de estado)
si no: gracia' = gracia − coste
       corrupcion' = max(poso, poso + (corrupcion − poso) / 2)
```

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| gracia actual | `gracia` | float | `[0, +∞)` | saldo antes del gasto |
| corrupción actual | `corrupcion` | float | `[poso, 100]` | antes del gasto (≥ poso por invariante) |
| suelo | `poso` | float | `{0, 12, 24, 36}` | floor desde F-P1 |
| coste | `coste` | float | `{8, 12}` | 8 Purga / 12 Amparo |
| gastos/duelo | `spends` | int | `[0, 2]` | cap 2 gastos/duelo |
| amparos/duelo | `amparos` | int | `[0, 1]` | máx 1 Amparo/duelo |
| cooldown | `ticks_desde_gasto` | int | exige `≥ 360` | ticks entre gastos |

**Output Range:** bilateral: `gracia' ≥ 0`; `poso ≤ corrupcion' ≤ corrupcion` (decreciente, parada en floor). Sin deuda, sin parciales; `max()` es el floor anti-flotante.
**Example:** `(gracia 20, corrupcion 50, poso 24)` + Purga(8) → `(12, 37.0)`; segundo gasto → `30.5`; en floor `(24, poso 24)` → `24`, alivio 0.

The `poso` formula is defined as:

```
absorber:  poso' = poso + 12.0 ; n' = n + 1 ; corrupcion sin lump
rechazar:  poso' = poso ; n' = n ; corrupcion' = max(poso, corrupcion − 6.0)
```

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| suelo | `poso` | float | `{0, 12, 24, 36}` | `n × 12` v1.0 |
| absorbidos | `n` | int | `[0, 3]` v1.0 | `angeles_absorbidos` |
| delta suelo | `Δposo` | float | `{0, 12}` bilateral | 12 absorber / 0 rechazar |
| purga rechazo | `purga_rechazo` | float | `= 6.0` | alivio exclusivo de rechazar |

**Output Range:** `0 ≤ poso ≤ 36`; `n` 0–3; `corrupcion'` nunca bajo `poso`.
**Example:** absorber #2 → `(poso 12→24, n 1→2, vida 118→136)`; rechazar con `(50, P24)` → `44.0`; rechazar en `(26, P24)` → `max(24, 20) = 24`.

The `saturacion` formula is defined as:

`clamped = min(max(cruda, 0.0), 100.0)` · `saturado = (cruda ≥ 100.0)`

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| corrupción cruda | `cruda` | float | `[0, +∞)` | pre-clamp |
| techo | `techo_saturacion` | float | `= 100.0` locked | techo de saturación |
| clampeada | `clamped` | float | `[0, 100]` bilateral | valor efectivo |
| saturado | `saturado` | bool | `{false, true}` | predicado (banda `100 ± 1e-6` ≡ 100) |

**Output Range:** `[0, 100]` en ambos lados; sin overflow, sin transferencia.
**Example:** `103 → 100 + true`; `67 → 67 + false`.

Referencia locked (sin matemática nueva): `vida_maxima = 100 + n × 18 + bono_reliquias` (Combate F5; `n` es el de F-P1).

Fronteras verificadas: 3-absorb spendless típico `67 + 36 = 103` → satura tardío duelo-3 ✓ · reject-all spendless `67` evita ✓ · floor-stop: alivio 0 con earn > 0 → loop imposible ✓ · flood full-combo N=5 duelo-1 `30 < 100` ✓ · VE máx `3.0` (3% techo) ✓ · 0 parries: estado invariante, sin negativos ✓.

## Edge Cases

**Cero / máximo / fuera de rango**
- **Si gasto con `gracia < coste`**: RECHAZO sin efecto colateral — no resetea cooldown, no consume cap, no emite eventos (salvo blip de denegación de #13). Evaluar compuertas nunca castiga.
- **Si gasto en `C = P` exacto**: ACEPTA (si compuerta/cap/cooldown/coste pasan). Purga desperdicia (uniforme, sin caso especial); Amparo protege igual. #13 lo anota en UI, no es regla.
- **Si earn llega en `Saturada`**: aplica, re-clamp ambos ledgers a 100 (sin wallet de overflow); exceso destruido, no banqueado; `saturacion_alcanzada` NO se re-emite (una vez por entrada).
- **Si `modificador_combo ∉ {1.0, 0.5}` (incl. negativo, cero, NaN)**: violación de contrato — fail-closed: descarta el evento, no toca ledgers, log + contador, escala a Combate. Jamás clampar-y-aceptar.
- **Si `-0.0` en ledger**: normaliza a `+0.0` al serializar (higiene SUS).

**Simultaneidad**
- **Si earn saturante y gasto caen el mismo tick**: orden estricto earn → clamp+saturación → evalúa gasto. El gasto concurrente se RECHAZA (G8 precede a G7), sin consumir cap ni cooldown.
- **Si TOMAR en `Saturada`**: legal. `n += 1`, Vida +18, `poso' = min(poso + 12, techo)`; `C` sigue clamped; la saturación NO se desengancha.
- **Si DEJAR IR en `Saturada`**: aritmética aplica (`max(poso, 94)`) pero el handoff NO se retracta: #6 posee la continuación (back-link: ¿qué hace #6 con 94-tras-100?).
- **Si VE-parada satura**: earn saturante normal (clamp, emite una vez, gasto off). Sin caso especial: gastar era ilegal durante `VE activa`, así que el "peor intercambio" es inesquivable por construcción.
- **Invariante probada**: TOMAR/DEJAR IR jamás saturan (sin lump / purga estricta). Solo la vía parry-earn alcanza el techo.

**Frontera float**
- **Si `cruda` en `100 ± 1e-6`**: snap a `100.0` antes del predicado (valor limpio para round-trip Guardado).
- **Aritmética exacta v1.0**: earns (`0.5/1.0`), costes (`8/12`) y `/2` son exactos en binario; el `1e-9` existe solo por round-trip JSON y se vuelve load-bearing con assist-scaling (K1). No "limpiarlo".

**Round-trip Guardado**
- **Si `poso` cargado < `poso` en memoria, NaN en cualquier campo, campo ausente o `len(log) ≠ n ≠ TOMARs`**: descarta la SUS entera (sin defaults que fabriquen monotonicidad; el log es source of truth, `n` su checksum).
- **Si SUS con `n > 3` en build v1.0**: rechazo forward-incompatible (sin clampar ni recomputar). Inversa (save viejo `n ≤ 3` en build futura): acepta solo si `poso == n × 12`.
- **Tras cargar**: re-verifica `poso ≤ C ≤ 100`, `0 ≤ g ≤ 100`, `poso ∈ {0,12,24,36}`, `n ∈ [0,3]`; cualquier fallo → descarte. Higiene: snap a `0.5` más cercano si dentro de `1e-9` (único sitio donde el epsilon toca gameplay).

**Doble commit / coste exacto / cooldown**
- **Si dos gastos mismo tick**: serializados; como máximo uno por tick (el 2º ve cooldown 0 < 360 → RECHAZO sin buffer).
- **Si doble TOMAR o TOMAR+DEJAR mismo tick**: el flanco fresco de Menú tumba el 2º en presentación; defensa en profundidad: el 1º sale de `Decisión` → Hub y el 2º se descarta por guardia de estado.
- **Si `gracia == coste` exacto**: ACEPTA, `gracia' = 0.0` (estado legal; próximos gastos rechazan hasta nuevo earn).
- **Si gasto en tick 359/360 de cooldown**: 359 RECHAZA, 360 ACEPTA (comparación entera). El contador solo resetea en aceptados; es monótono (no resetea por duelo); al cargar SUS inicia SATISFECHO.
- **Cooldown normativo**: 360 ticks @ física fija 60 Hz; si la tasa cambia, escala proporcional.

**Amparo vivo al fin de duelo**
- **Si victoria con Amparo sin consumir**: expira (duel-scoped, jamás serializado). Sin refund: el desperdicio es parte de su precio.
- **Si derrota con Amparo**: se limpia con el reset de run (triple en derrota: propiedad de #3 — back-link).
- **Amparo solo niega daño de `Golpe` fallado, por nombre**; daño de VE lo atraviesa sin consumirlo (requiere tag de fuente en Combate — back-link). Múltiples Golpes mismo tick: el 1º consume, el resto aplica.

**Saturación en Hub / Decisión**
- **No hay vía Hub a saturación**: sin faucet en Hub (prohibición G), TOMAR sin lump, gastos solo bajan `C`. Trayectoria Hub monótona no-creciente.
- **Gasto ilegal con Decisión abierta** (I2): decidir contra ledger estable; gastar en el Hub.

**Quit / kill — ventana de volatilidad (diseñado, no data loss)**
- **Si quit/kill con Decisión abierta (sin SUS nueva)**: al recargar, estado = última SUS `post_decision`; los deltas del duelo recién ganado se PIERDEN (fail-closed anti-scum).
- **Si quit/kill en Hub tras gastos**: deltas inter-SUS volátiles por diseño (gracia refundida Y alivio deshecho — neto cero). No "arreglar" con SUS por gasto (sería punto `pre_eleccion`, prohibido R5 Guardado; renegociar contrato, no parche #5).
- **Si Abandonar en cualquier punto**: wipe run-scoped total (triple a 0, n a 0, log vacío, Amparo huérfano, cooldown/caps reset).

**Assist-mode**
- **Si preset assist ensancha ventana**: `gracia_base_assist = 1.0 × (ventana_base / ventana_assist)` (proxy lineal, propiedad de #21). Solo vía earn (simple/combo/VE); jamás poso/purga/costes/caps. Base resultante fuera de `[0.5, 2.0]` exige re-derivar R7/R9b.

## Dependencies

| Sistema | Dirección | Dura / Blanda | Interfaz |
|---|---|---|---|
| #1 Combate | Bidireccional | Dura | Consume `parry_exitoso` + modificador verbatim; expone `angeles_absorbidos` (F5); R9b igualdad 1.0; cero poderes de daño (R10). Back-links: tag Golpe-vs-VE (Amparo H3); timing F5 vs floor-lift J3 (ledgers independientes, documentar orden) |
| #2 Máquina | Consume | Blanda | VE distinguida vía veredicto; VE no parada = 0/0 |
| #3 Run | Bidireccional | Dura | Reset run-scoped; triple en derrota con Amparo (back-link). Provisional (sin GDD) |
| #12 Guardado | Expone | Dura | Triple + n + log cada `post_decision`; taxonomía de descarte D1–D7 (requiere fila AC: poso-decreciente + rango 0–9) |
| #9 Reliquias | Restringe | Dura | Prohibido faucet de gracia; R10e propuesto (supervivencia conjunta ≤ +1; extiende C26) |
| #13 HUD | Expone lectura | Blanda | Niveles + 4 eventos; anotación Purga-en-suelo (UX, no regla) |
| #7 Overlay | Expone | Blanda | Mapa permanente lee C/P |
| #6 Clímax | Emite | Dura | `saturacion_alcanzada`; aritmética post-saturación (B3: 94-tras-100) |
| #15 Menú | Hermanos | Dura (práctica) | Enruta; Decisión propiedad #5 (foco neutro + `MENU_DECISION_*`; back-link: actualizar tabla + inventario) |
| #16 Sonoro | Emite | Blanda | Capas por gasto/decisión/saturación (propiedad #16) |
| #21 Accesibilidad | Consume fallo | Blanda | Medición ratio-ventana tras K1 |

**Consistencia bidireccional pendiente:** al autorar #3, #6, #9 (y enmiendas de #1, #12, #15), cada uno declara su mitad (tag de daño, 94-tras-100, R10e, fila AC poso, foco neutro + claves). Verificará `/consistency-check`.

## Tuning Knobs

| Knob | Lanzamiento | Rango seguro | Si muy alto | Si muy bajo | Interacciones |
|---|---|---|---|---|---|
| `gracia_base` (default locked, variable viva por #21) | 1.0 | 0.5–2.0 | Earn/duelo duplica → techo en duelo 1–2; >1.5 rompe banda R9b → re-derivar | Purga (8) inasequible → wallet muerta | R7, R9a, costes, techo (`techo ≈ earn_3 + 3×step + margen`) |
| `techo_saturacion` | 100.0 LOCKED | 70–140 | Arco 3-duelos (ref 103) no satura → #6 inanido, Pilar 1 sin payoff | Saturación duelo-1 → tragedia no ganada | Conjunto con poso/purga/base; < 3×step rompe `poso ≤ techo` (HARD) |
| `poso_step` | 12.0 LOCKED plano v1.0 | 6–24 | Floor-lift castiga TOMAR-tras-gasto → colapso a rechazar; 3×step > techo = HARD | Irreversible no se siente; Pilar 4 sin peso | Ratio 12:6 con purga (dial de asimetría); G9 superlineal en visión |
| `purga_rechazo` (el más balance-sensible) | 6.0 | (0, 12) exclusivo | ≥ step: TOMAR gratis (+Vida+poder) → absorber domina | 0: rechazo narrativo-only → pura inviable → colapso inverso | Colapso de dos lados: ambos extremos matan la elección |
| `coste_purga` | 8 | 4–16 | Gasto código muerto | Spam fija `C` al suelo; ≤ 0 vacía el Pilar 1 | Base, cap 2, cooldown (trío conjunto); orden `amparo > purga` invariante |
| `coste_amparo` | 12 | 9–20 | Degrada a solo-Purga | ≤ purga: Purga muerta → solo-Amparo (orden estricto invariante) | R10e (frecuencia ya acotada 1/duelo) |
| `cooldown_ticks` | 360 (~6 s @60Hz) | 120–900 | 2º gasto inalcanzable → arco caliente | Burst intra-ventana trivializa picos | `min(cap, floor(duelo/cooldown)+1)`; escala con Hz |
| `cap_spends / cap_amparos / cap_activo` | 2 / 1 / 1 LOCKED | spends 1–4; amparos 0–1 | amparos ≥ 2 rompe R10e → re-derivar | spends 0 = kill-switch playtest (jamás ship) | Costes × caps × cooldown (trío) |
| `divisor_alivio` (el /2) | 2 | 2–4 (factor 1/4–1/2) | Suelo trivial, solo queda poso | ≤ 1: alivio nulo/negativo → rompe `C' ≤ C` + prueba floor-stop | Reabre las 4 fronteras si se mueve |

**No-knobs (fijados por regla, contrato o aritmética — jamás tunear):** epsilons `1e-9/1e-6` (cota de error JSON+binario) · `modificador_combo {1.0,0.5}` (R7 Combate) · `+18 Vida` (F5) · cap R9a `Σ ≤ 3` · magnitudes R10 · `n ∈ [0,3]` (lock de versión; knob solo vía G9).
**Prohibido forkar aquí:** cualquier valor de la fila anterior se referencia, no se re-declara.

## Visual/Audio Requirements

Regla marco (art-bible §§1–2, 4.5, 5.2): la corrupción se lee en el **cuerpo** (venas de vitral violeta en rosetones desde cada absorción, overlay 4–6 anclajes, recompuesto solo en eventos de cambio — jamás por frame); el medidor HUD **cuantifica** lo que el cuerpo ya muestra. Solo brilla lo divino o la gracia robada; protagonista, mundo y UI jamás emiten luz.

| Evento | Visual (propiedad compartida) | Audio (propiedad #16) |
|---|---|---|
| Earn por parry | Esquirlas que se clavan en tinta (Combate ev. 3; este GDD no añade emisores) | Capa cristalina (existe) |
| TOMAR (commit) | Luz remanente succionada a la silueta (art-bible fila 5); +1 rosetón de veta permanente | Sting de commit `ui_cometer_irrevocable` (familia sobria, no error) |
| DEJAR IR (commit) | Luz que asciende y se desvanece (fila 5); sin veta nueva | Variante resolución sobria (misma familia, nunca error) |
| Gasto Purga/Amparo | Vetas laten al gastar (cuerpo); sin flash nuevo | Transients secos por bus |
| Saturación | Quiebre a vitral pleno (fila 7, propiedad #6); este GDD congela ledgers | Handoff a #6 |

Prohibido: celebraciones de absorción (`¡NUEVA FORMA!`), vitral cool sin duelo, números flotantes de gracia sobre el ángel (prohibición HUD), tercer lenguaje visual fuera de tinta/vitral/UI-frío.

## UI Requirements

Pantalla Decisión (propiedad #5, enrutada por #15; modo UI distinto del HUD de combate — admite composición ceremonial y centro ocupado). Base 1280×800, safe-zone 5%.

| Elemento | Requisito |
|---|---|
| Layout | NW: medidor Gracia alta luminancia (solo HUD, propiedad #13); centro: ángel en brasas inmóvil sin timer; centro-bajo: díada `TOMAR / DEJAR IR` en igualdad visual (rechazo jamás menor/apologético); S: línea irreversibilidad + línea quit |
| Foco | **Neutro inicial (ninguno)** — excepción justificada a Menú R7: ambos commits son single-press irrevocables y el flanco fresco no para mash fresco; mover primero rompe la cadena. Orden: primer `ui_left/right` discreto agarra; trampa en díada; `ui_accept` (flanco fresco) commitea; `ui_cancel` = no-op + error sordo (sin atrás, sin omitir). Borde 2px `#C7CDD6` + cuneta, 0 glow, sin hover |
| TOMAR | `+18 Vida máx`, `+12 poso`, `desbloquea: {poder}`, línea ledger `gracia/corrupción/poso`; nombra el coste (el gasto solo alivia hasta el suelo) |
| DEJAR IR | `purga −6 hasta suelo`, explícito `sin Vida, sin poso, sin poder`; digno, jamás castigo (sin dimming, sin timbre menor) |
| Confirm | Single-press + flanco fresco + dedupe por tick + consume/inhibe/swallow 200 ms; ambos botones se deshabilitan el mismo frame; commit atómico en memoria → animación → Hub. SIN hold (reservado a destrucción run/SUS) |
| Quit/kill | Sin botón salir; línea `MENU_DECISION_QUIT_LINE` ("Si sales ahora, esta elección queda sin guardar"); kill ≡ cancelar (sin SUS mutada); sleep preserva pantalla+foco, jamás auto-commit |
| Prohibido mostrar | Vida/Postura/timer/peek numérico/`estado_red`/Continuar/flash `#C75C4A`/hold prompt/lista destructiva R4 |
| Claves | `MENU_DECISION_TITLE` ("El coro espera tu mano") · `..._TOMAR/DEJAR_LABEL/DESC` (placeholders `{poder} {vida} {poso} {purga}`) · `MENU_DECISION_LEDGER` · `MENU_DECISION_IRREVERSIBLE` · `MENU_DECISION_QUIT_LINE` (todas ≤120 caracteres post-interpolación; fija `/localize`) |
| a11y | Nombre accesible = label+desc+ledger; foco anunciado; medidor con respaldo de forma (densidad grieta); contraste ≥4.5:1; teclado+mando; reduced-motion: corte + brasas estáticas + sonidos por bus |

> **📌 UX Flag — Decisión Gracia**: pantalla con requisitos UI reales. En Pre-Producción, `/ux-design` para esta pantalla (citará `design/ux/decision-gracia.md`, no este GDD). Nota para systems-index al actualizar.

## Acceptance Criteria

Gate levels: Logic/Integration = BLOCKING (`tests/unit/gracia/`, `tests/integration/gracia/`); Visual/Feel/UI = ADVISORY (`production/qa/evidence/` + sign-off); Config = ADVISORY smoke. Tags: `[A]` automatizable, `[M]` manual.

**Reglas G1–G10**
- [ ] **GR-01 [A]** — GIVEN run tras reset, WHEN snapshot + grep de escrituras, THEN claves exactamente `{gracia_actual, corrupcion_actual, poso_irreversible}` floats ≥0 JSON-safe (sin NaN/Inf/`-0.0`) + `{angeles_absorbidos, decision_log[]}`, cero escrituras fuera del módulo.
- [ ] **GR-02 [A]** — GIVEN P=12,C=20,G=10, WHEN secuencia earn+Purga+TOMAR+DEJAR, THEN tras cada paso `poso ≤ corrupcion ≤ 100` y `0 ≤ gracia ≤ 100` (clamp/reject, sin breach observable).
- [ ] **GR-03 [A-parcial+M]** — GIVEN código + tablas + claves Decisión, WHEN grep `loot|alma|mana`, THEN cero hits (salvo notas históricas); verbos visibles solo tomar/cargar/aliviar/poso/dejar ir (tono: sign-off manual).
- [ ] **GR-04 [A]** — GIVEN G=5,C=10,P=0, WHEN `parry_exitoso` simple, THEN G=6, C=11, P=0 en commit atómico (jamás G-solo o C-solo).
- [ ] **GR-05 [A]** — GIVEN cero, WHEN 3 parries combo (mod 0.5), THEN G=C=1.5; con 5 → 2.5 (rico/pobre por construcción).
- [ ] **GR-06 [A]** — GIVEN fuera de resolución de parry, WHEN whiff, daño recibido, hub idle 600 ticks o pickup reliquia, THEN ΔG=ΔC=0 en los cuatro (faucet único).
- [ ] **GR-07 [A]** — GIVEN G=2,C=5,P=0, WHEN VE-parada, THEN G=3, C=6, postura_delta=0, repliegue=0 (el peor intercambio).
- [ ] **GR-08 [A]** — GIVEN 3 VE-paradas consumidas, WHEN 4ª VE mismo duelo, THEN +0/+0 con log (R9a Σ≤3).
- [ ] **GR-09 [A]** — GIVEN stub 3 duelos, WHEN TOMAR/DEJAR IR/pendiente, THEN log=[1,0], n=1=suma, pendiente ofrece exactamente {TOMAR, DEJAR IR}.
- [ ] **GR-10 [A]** — GIVEN TOMAR committed + SUS `post_decision` + Hub, WHEN recargar e intentar re-decidir u omitir commit, THEN log=[1], 2º commit RECHAZADO por guardia, cero rutas victoria→Hub sin commit.
- [ ] **GR-11 [A]** — GIVEN Decisión abierta sin SUS nueva, WHEN TOMAR, THEN memoria actualiza síncrona pre-animación; espía: 1 write `post_decision`, 0 `pre_eleccion`.
- [ ] **GR-12 [A]** — GIVEN (G10,C20,P12,n1,vida118), WHEN TOMAR 2º ángel, THEN n=2, P=24, vida=136, poder on, G=10, C=max(20,24)=24 en un commit (nunca 1-de-3), sin lump.
- [ ] **GR-13 [A]** — GIVEN Latente (0,0,0,n0) en Decisión, WHEN TOMAR, THEN P=12, n=1, C=max(0,12)=12; y GIVEN (G5,C12,P12,n1), WHEN TOMAR, THEN P=24, C=max(12,24)=24 (floor-lift).
- [ ] **GR-14 [A]** — GIVEN (C50,P24,n1,G7), WHEN DEJAR IR, THEN C=44, resto igual; y GIVEN (C26,P24), THEN C=max(24,20)=24.
- [ ] **GR-15 [A]** — GIVEN stub earn 67 + 3×DEJAR + 0 gastos, WHEN run completa, THEN n=0, P=0, vida=100, C=49, deltas Combate (parries/cobertura) = 0, Hub sin saturación (pura válida, R10-safe).
- [ ] **GR-16 [A]** — GIVEN (G7,C30,P12,spends0,cooldown ok), WHEN Purga(8), THEN RECHAZO sin cambio (spends, contador, eventos intactos; solo blip denegación).
- [ ] **GR-17 [A]** — GIVEN (G8,C30,P12), WHEN Purga(8), THEN ACEPTA: G'=0.0, C'=21.0, spends=1, cooldown=0.
- [ ] **GR-18 [A]** — GIVEN (G20,C50,P24), WHEN Purga, THEN (12, 37.0); y GIVEN en suelo (24,24,24), WHEN Purga legal, THEN ACEPTA con C'=24, alivio 0 (desperdicio uniforme, sin caso especial).
- [ ] **GR-19 [A]** — GIVEN spends=2 (resto legal), WHEN 3º gasto, THEN RECHAZO; y GIVEN amparo_used=1, WHEN 2º Amparo o amparo activo, THEN RECHAZO.
- [ ] **GR-20 [A]** — GIVEN cooldown 359, WHEN gasto, THEN RECHAZO (entero); GIVEN 360, THEN ACEPTA y resetea (solo en aceptados; cruza duelos; SUS inicia SATISFECHO; 360 = 6×physics_hz).
- [ ] **GR-21 [A-parcial+M]** — GIVEN legalidad, WHEN gasto en Telegrafiado/Enfriamiento/Repliegue/Hub/post, THEN ACEPTA; WHEN en Parry/Aturdido/Recepción/whiff/VE/Decisión-abierta, THEN RECHAZO sin cola (mash manual confirma); binding gasto ≠ botón parry.
- [ ] **GR-22 [A]** — GIVEN cualquier gasto aceptado, WHEN deltas vía espía Combate, THEN Δvida=Δpostura=0, sin lifesteal, G baja exactamente el coste, cero timers extra.
- [ ] **GR-23 [A]** — GIVEN Amparo activo, WHEN próximo Golpe fallado, THEN daño 0 una vez y amparo=0; el siguiente aplica; dos Golpes mismo tick: 1º consume, 2º aplica. Victoria con Amparo sin consumir → expira sin refund, ausente de SUS. Derrota → wipe con run (#3).
- [ ] **GR-24 [A, blocked-on-backlink]** — GIVEN Amparo activo, WHEN daño VE con tag, THEN aplica pleno sin consumir (requiere tag Golpe-vs-VE en Combate; harness stub marca integración BLOCKED).
- [ ] **GR-25 [A]** — GIVEN (C99.5,G20), WHEN +1.0 earn, THEN C=100 clamped, saturado=true, `saturacion_alcanzada` una vez con snapshot; gasto posterior RECHAZADO; más earn mantiene 100 sin re-emitir.
- [ ] **GR-26 [A]** — GIVEN Saturada (100,24,1), WHEN TOMAR, THEN n=2, P=min(36,100), C=100, saturado sigue; WHEN DEJAR IR, THEN C=94 pero handoff NO se retracta (#6 posee continuación); y sin earn, TOMAR/DEJAR jamás saturan (P+12≤36).
- [ ] **GR-27 [A]** — GIVEN (C99.5,G20,spends0,cooldown ok) + earn/gasto mismo tick, WHEN resuelve en orden earn→clamp+emit→gasto, THEN gasto RECHAZADO (spends/cooldown intactos); dos gastos mismo tick → como máximo uno ACEPTA.
- [ ] **GR-28 [A]** — GIVEN permutaciones de orden con n=2, WHEN run completa, THEN P=24, vida=136 (+reliquias aparte); magnitudes idénticas, solo identidades permutan.
- [ ] **GR-29 [A]** — GIVEN build v1.0 con n=3 + 4º TOMAR o SUS n=4, WHEN commit/carga, THEN BLOQUEO/RECHAZO total (sin clampar; exige re-derivar G9).
- [ ] **GR-30 [A]** — GIVEN commit Decisión + espía FS, WHEN earn/gasto/hub/`pre_eleccion` vs `post_decision`, THEN cero IO de #5; payload `post_decision` = {triple exacto, n, log verbatim}.
- [ ] **GR-31 [A]** — GIVEN observadores HUD/Overlay/Clímax, WHEN eventos disparan, THEN niveles = ledgers ±1e-9; setter desde observador falla; ledgers intactos tras su tick.
- [ ] **GR-32 [A]** — GIVEN `-0.0` tras aritmética, WHEN serializa, THEN `0.0` bit-exacto; múltiplos 0.5 ±5e-10 round-trip en 1e-9; `100±1e-6` satura, `99.9` no.

**Fórmulas (≥1 por F)**
- [ ] **GF-G1-01/02/03 [A]** — simple → 1.0 exacto; combo → 0.5/parry (N=3 → 1.5, conjunto cerrado); mod ∈ {0,−1,0.7,2,NaN} → descarta evento, ledgers intactos, log+contador, escala.
- [ ] **GF-C1-01/02 [A]** — igualdad exacta en (0,1.5]; VE → 1.0/1.0; 3 VE/duelo = 3.0 (3% techo).
- [ ] **GF-S1-01/02 [A]** — (20,50,P24)+Purga → (12,37.0); 2ª → (4,30.5); suelo → 24 alivio 0; coste>gracia RECHAZA; gracia==coste ACEPTA a 0.0.
- [ ] **GF-P1-01/02 [A]** — 3 TOMAR → poso 0→12→24→36, n 0→3, sin lump; rechazar (50,P24) → 44; (26,P24) → 24.
- [ ] **GF-T1-01/02 [A]** — 103 → 100+true con exceso destruido; 67 → 67+false; `100±1e-6` satura limpio; 99.9 no.

**Cross-system**
- [ ] **GX-01 [A]** — Combate emite `parry_exitoso`: mod verbatim, timing preservado, VE distinguida; VE-no-parada +0/+0.
- [ ] **GX-02 [A]** — n=1→2 (bonus 0→10): vida 118→136 (128→146 con bonus; passthrough, jamás calculado en #5).
- [ ] **GX-03 [A]** — Round-trip {12.5,37.0,24,n2,[1,0]}: igualdad ±1e-9, snap 0.5, re-verifica rangos/conjuntos o descarta.
- [ ] **GX-04 [A]** — Variantes (poso<memoria, NaN, ausente, log≠n): cada una descarta SUS entera sin defaults.
- [ ] **GX-05 [A]** — SUS n=4 en v1.0: RECHAZO forward-incompatible; save viejo n≤3 en futuro: acepta iff poso==n×12.
- [ ] **GX-06 [A-parcial+M]** — victoria→reliquias→decisión→Hub exacto (FSM + walkthrough); trayectoria Hub monótona no-creciente.
- [ ] **GX-07 [A-parcial+M]** — Decisión: foco neutro inicial, primer left/right agarra con trampa, accept flanco-fresco, cancel no-op+error, sin hold, disable mismo frame + swallow 200 ms, doble commit tumba el 2º.
- [ ] **GX-08 [A-parcial+M]** — HUD niveles+4 eventos, Decisión solo-Gracia, setter falla, Purga-en-suelo ACEPTA, cero números flotantes (screenshot).
- [ ] **GX-09 [A]** — `saturacion_alcanzada` = {snapshot, absorbidos}, una vez por entrada, gasto off, TOMAR/DEJAR posterior no retracta.
- [ ] **GX-10 [A]** — Auditoría no-faucet: reliquia/hub-idle/passive sin `parry_exitoso` → Δ=0; call-sites == handler de parry.
- [ ] **GX-11 [A, blocked]** — Amparo-vs-VE (duplicado cross de GR-24; BLOCKED hasta tag en #1).
- [ ] **GX-12 [A]** — Quit/kill en Decisión abierta → estado = última SUS (deltas perdidos, anti-scum); Hub volátil neto-cero; Abandonar = wipe total.
- [ ] **GX-13a/b [M con protocolo]** — Gamesim 20 runs/mezcla (seeds archivadas): LOW 0.45 → win_rate(absorb) > win_rate(pura) con Δ≥1 duelo; HIGH 0.90 → saturation_rate(absorb) > saturation_rate(pura) con Δ≥1 duelo o ≥25pp. Evidencia en `production/qa/evidence/dilemma-{low,high}.md`. Prueba no-dominancia bilateral.
- [ ] **GX-14 [A]** — Ordenamientos (no literal): 103 > techo > 67 > 30 > 3.0 > 0; floor-stop sin loop; al retunear techo se re-deriva, 100 jamás sagrado.
- [ ] **GX-15 [A-parcial+M]** — Assist: base_assist = 1.0×(base/assist) solo-earn; fuera de [0.5,2.0] → FAIL exige re-derivar R7/R9b.
- [ ] **GX-16 [M]** — Ceremonia ADVISORY: screenshots 1280×800 (succión+rosetón / ascenso sin rosetón / latido sin flash / vitral-congela), claves ≤120 chars, contraste ≥4.5:1, reduced-motion, sign-off en evidence/.

## Open Questions

| Pregunta | Owner | Deadline | Resolución |
|---|---|---|---|
| Calibración `techo` por protocolo (media gracia/run a 0.72 hit-rate, 20 runs por mezcla; techo = 0.95×media non-spender) | systems-designer + playtest | Prototipo Vertical Slice | Provisional 100.0; ACs aseveran ordenamientos, no literal |
| Legibilidad 3-capas con testers externos (¿narran earn/gasto-suelo/absorb-suelo sin tutorial?) | game-designer | Playtest externo | Si falla: fusionar display (una barra + tick de poso; math dual intacta) |
| Función decreciente-9 + R5_9 + schedules poso conjuntos | Este GDD + #6 + #9 | Antes del 4º ángel | G9 congela lineal v1.0 |
| ¿Lucifer lee `poso` en vivo? (coste 5-shaders Deck) | #11 + performance | Full Vision | Fuera de MVP |
| Medición ratio-ventana tras K1 (assist) | #21 | Al autorar #21 | Base fuera de [0.5,2.0] → re-derivar R7/R9b |
| R10e (supervivencia conjunta ≤ +1) ratificado por #9 | #9 + qa | Al autorar #9 | Propuesto aquí; C26 extendido |
| Back-links pendientes (lista en Dependencies) | Cada autoría | Al autorar cada GDD | Verificará `/consistency-check` |
| Ventana commit-animación→Hub-flush (decisión perdida si kill intermedio) | Este GDD + Guardado | Playtest | Honesto hoy; sin SUS `post_decision` sin aprobación conjunta |

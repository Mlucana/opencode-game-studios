# IA de Combate de Jefes — Patrones de Ataque y Movimiento

> **Status**: **Draft — pendiente de adjudicaciones** (creado 2026-09-05; no ha pasado `/design-review`; ninguna cifra PROVISIONAL es normativa hasta su adjudicación)
> **Author**: usuario + `systems-designer`
> **Last Updated**: 2026-09-05
> **Implements Pillar**: Pilar 2 (La maestría está en las manos, no en la ficha) — sostiene Pilar 3 (Cada enemigo es alguien) y Pilar 1 (El poder duele, vía R9a/R9b)
> **Layer / Priority**: Núcleo / MVP · **Sistema**: 20/21

## Summary

La IA de Combate de Jefes es el autor de patrones que vive sobre el esqueleto de la Máquina de Estados de Jefe (sistema 2): elige **qué** hace cada jefe (arquetipo, secuencia de patrones, qué golpes forman combo, qué habilidades usan `Acción Especial`) y **cuánto dura** cada fase (`Telegrafiado`/`Golpe`/`Enfriamiento`, separaciones intra-combo), sin emitir ninguna señal propia y sin introducir ningún estado top-level nuevo. Existe porque el esqueleto garantiza que "estar en Aturdido" signifique lo mismo para todos los jefes, pero no decide si un jefe es un centinela predecible, un coro que encadena combos o un oficiante que intenta curarse — esa personalidad (Pilar 3) y esa cadencia legible-pero-no-macheable (Pilar 2) son este sistema. Opera bajo cinco techos que no posee: `3 ≤ N ≤ 5`, el piso Regla 9, la banda R9a en equivalencia, `multiplicador_ataque = 1.0` y la resolución síncrona Regla 8.

> **Quick reference** — Layer: `Núcleo` · Priority: `MVP` · Key deps: `Máquina de Estados de Jefe (2, dura)`, `Combate de Parry-Absorción (1, dura-vía-2)`

## Overview

Cada jefe de NOVENA expresa su personalidad eligiendo patrones de un vocabulario cerrado —golpes simples, combos de 3 a 5 golpes y acciones especiales interrumpibles o intocables— y calibrando sus duraciones para que cada ataque sea legible en una pantalla de 7" pero ninguna cadencia fija de machacar el botón pueda sobrevivir a un duelo. Este sistema fija los arquetipos de la v1.0, las duraciones por patrón, la varianza de separación intra-combo que rompe el mash (calibrada contra el dato medido: nada por debajo de 12 ticks muerde), el piso de justicia que alimenta la Regla 9 del sistema 2, y las dos cotas que cierran la mitad cuantitativa del riesgo de curación: tasa de curación acotada contra `dano_golpe_castigo` y severidad por habilidad dentro de la banda R9a en equivalencia.

## Player Fantasy

El jugador debe sentir que **cada ángel pelea con carácter propio y que ese carácter se puede aprender** — no que los números suben, sino que la gramática cambia: uno mide distancias con golpes simples espaciados, otro encadena frases de tres a cinco golpes que hay que rematar bien, otro abre una ventana de oportunidad para robarle su milagro antes de que lo complete. La sensación objetivo es la del duelo de esgrima donde el rival "tiene estilo": la primera vez sorprende, la quinta se lee, la décima se clava — y clavar un combo de 5 o arrancar una curación de un dios es la forma más pura del "soy hábil" del Pilar 2, con el poso de "me estoy destruyendo" (los combos pagan gracia 0.5× por parry, la Ventana Especial paga gracia completa por cero Postura). El test negativo, espejo del sistema 2: si el jugador siente que el jefe "hace trampa por aritmética" —un segundo golpe imparable tras conectar el primero, un mash que sobrevive a todo un duelo, una curación que anula tres castigos— este sistema ha fallado, aunque cada fórmula individual esté en verde.

> **Frontera de propiedad de la fantasía.** Este GDD posee la mitad "cada enemigo es alguien" **en su gramática de patrones** (qué secuencias usa cada arquetipo, con qué cadencia). No posee: la topología de estados (sistema 2), la resolución del parry ni el daño (sistema 1), el juicio audiovisual del intercambio (sistemas 4/16), ni la corrupción acumulada (sistema 5). La truncadura de la animación de `Golpe` cuando el perdón de anticipación la corta antes de su duración nominal es requisito de presentación **sin propietario hasta hoy**: se asigna aquí (sistema 20 + dirección de arte), cerrando la consecuencia sin propietario que el sistema 2 anotó.

## Detailed Rules

### Regla 0 — Qué posee este sistema y qué solo consume (contrato de tres partes)

1. **Posee (datos, nunca señales):** por patrón — `duracion_telegrafiado`, `duracion_golpe` (ventana activa nominal), `duracion_enfriamiento`, `longitud_combo_N` y su composición, `separacion_intra_combo` y su `jitter`, `interrumpible_por_parry` + declaración de Ventana Especial (duración y colocación), `vida_max_angel` por jefe/tríada, `curacion_por_accion_H` + `intervalo_min_entre_especiales` + `max_especiales_por_duelo`, `severidad_equivalente_s` por habilidad interrumpible, `margen_reaccion_min` (valor, pendiente de suelo — ver Fórmula 1), cadencia del encuentro tutorial.
2. **Consume por referencia, jamás redefine:** `parry_window` (13), `recuperacion_whiff` (9), `recuperacion_recepcion` techo 12, `recuperacion_castigo` techo 14, `retreat_base` (42), `ventana_castigo` (120) + `gracia_salida_castigo` (6) + borde derivado `T_max = ventana − gracia` (**nunca literal 114**), `dano_golpe_enemigo` (25), `dano_golpe_castigo` (Fórmula 6, con `multiplicador_ataque = 1.0` exacto), `postura_max` (30/40/50), `parries_por_ciclo` a calidad 0 (3/4/5), `tasa_acierto_objetivo = 0.72 ± 0.02` (prototipo), `golpes_para_morir_base = 4`, invariantes R2/R6/R7/R8/R9a/R9b/R10.
3. **No emite señales.** Todo lo observable de un patrón cruza la frontera como límites de estado del sistema 2 (señales `B-*` canónicas del ADR-002, orden fijo cierre → resultado → transición, `window_id` opaco). Este sistema es configuración leída por el FSM, no emisor. Añadir un campo a cualquier señal exige enmienda bilateral — la presión de "un datito extra" (p. ej. severidad dentro de `ventana_especial_abierta`) se resuelve leyendo configuración de este sistema, nunca engordando payloads.

### Regla 1 — Arquetipos v1.0 (PROVISIONAL — ver OQ1)

La v1.0 trae 3 jefes (un coro por tríada implementada). Cada jefe instancia **un** arquetipo; ningún jefe mezcla dos gramáticas en el mismo duelo. Tabla PROVISIONAL (composición por duelo, no por patrón suelto):

| Arquetipo (PROVISIONAL) | Tríada sugerida | Gramática | Combos | Acción Especial |
|---|---|---|---|---|
| **Vigilante** | Humanidad | 70% golpes simples, 30% combos | Solo `N = 3`, separación ancha | Ninguna |
| **Coro** | Cosmos | 40% simples, 60% combos | `N ∈ {3, 4}`, varianza alta (Fórmula 2) | Ninguna |
| **Oficiante** | Cercanía a Dios | 50% simples, 30% combos `N ∈ {4, 5}`, 20% Acción Especial | `N ∈ {4, 5}` | 1 habilidad de curación, `interrumpible_por_parry = true`, con Ventana Especial declarada (Regla 5) |

- La asignación arquetipo↔tríada es PROVISIONAL y conmutable; lo normativo es que **los tres arquetipos existan en la v1.0** (el tutorial necesita el Vigilante, el riesgo de curación necesita el Oficiante, la varianza anti-mash necesita el Coro).
- Ningún patrón declara `N` fuera de `3 ≤ N ≤ 5`. Un patrón con `N = 2` no es un combo degradado: son dos golpes simples con `Repliegue` entre ellos y dos instancias de Postura. La validación en carga la posee el AC C16 de Combate (gate primario); este sistema la re-asevera al autorar (defensa en profundidad, AC C7 del sistema 2).
- `vida_max_angel` la fija este sistema por jefe de modo que `dano_golpe_castigo = vida_max_angel × punish_dano_pct` produzca exactamente `ciclos_objetivo` castigos (4/5/6). Ejemplo normativo: Cosmos con `punish = 20%` y 5 ciclos → `vida_max_angel = 5 × dano_golpe_castigo`; si se quiere `dano_golpe_castigo = 40`, `vida_max_angel = 200`. Este sistema **no** toca `punish_dano_pct` ni `multiplicador_ataque`.

### Regla 2 — Duraciones por fase y piso de justicia (alimenta la Core Rule 9)

1. Cada patrón declara `duracion_telegrafiado`, `duracion_golpe` (nominal; el perdón de anticipación la trunca rutinariamente — ver frontera de fantasía) y `duracion_enfriamiento`, todas en **ticks enteros** a 60 Hz (`physics_ticks_per_second = 60` invariante).
2. **Piso normativo (forma del sistema 2, número de este sistema):** para todo patrón que pueda seguir a un `Golpe` que conectó, `duracion_enfriamiento + duracion_telegrafiado ≥ 12 + margen_reaccion_min`, evaluado en el **techo** de Recepción (12), nunca en nominal ni suelo. Un patrón que lo incumpla falla la validación de datos al cargar (AC C9 del sistema 2 + AC propio D1).
3. Rangos PROVISIONALES (ver Tuning Knobs; toda invariante nace con los dos lados): `telegrafiado 30–60`, `golpe 10–20`, `enfriamiento 20–50`. La suma mínima del rango (50) cubre el piso máximo (`12 + 28 = 40`) con 10 ticks de aire — margen deliberado para que el piso muerda solo a patrones degenerados, no a la autoría normal.
4. `Enfriamiento` no acelera ni ralentiza por el resultado anterior (Combate, Edge Cases): la cadencia es legible en su estructura aunque varíe en tiempos. Tras parry exitoso o aborto de combo el jefe no pasa por `Enfriamiento` sino por `Repliegue` (42, propiedad de Combate) — este sistema no lo acorta, alarga ni sustituye.

### Regla 3 — Composición de combos y separación intra-combo anti-mash

1. Un combo es `N` repeticiones `Telegrafiado → Golpe` envueltas en `En Combo`, sin `Repliegue` ni `Enfriamiento` entre repeticiones internas. La Postura se evalúa una sola vez al resolverse el combo (calidad del último parry); la Gracia se concede por parry a `0.5×` (Fórmula 7 de Combate); el `Repliegue` se paga una sola vez al resolverse o abortarse.
2. **Separación intra-combo:** sea `S_k` los ticks entre el cierre del `Golpe k` y la apertura del `Golpe k+1` (es decir, el `Telegrafiado` interno). Cada combo declara `S_base` (media) y `jitter_J` (amplitud total): cada `S_k` se sortea uniforme en `[S_base − J/2, S_base + J/2]`, con sorteo por duelo (semilla fijada al cargar el duelo; determinista en tests).
3. **Cota anti-mash (calibrada contra el dato medido):** el session-state mide que un masher a cadencia máxima para 93/93 ventanas (100%, 0 golpes) y que varianzas de 2/4/6/9 ticks **siguen al 100%**, bajando solo a 12 (90.9%, 7 golpes); la varianza solo muerde por encima de `parry_window` (13) porque dentro del combo no hay `Repliegue` y la recuperación de acierto son 2–3 ticks, así que el parry sigue activo y caza la siguiente ventana por el caso (b) de la Regla 3 sin pagar nunca el lockout de whiff. Por tanto: **`J ≥ 14 ticks` para todo combo** (Fórmula 2). `J ≤ 13` es configuración ilegal (falla al cargar). El techo de `J` lo fija la legibilidad (ver Tuning Knobs) — invariante de dos lados desde el primer día.
4. `S_base` PROVISIONAL 24 ticks (rango 18–30). Con `J = 14`, un combo con base 24 separa sus golpes en [17, 31]: el hueco mínimo (17) sigue siendo parable con reacción, el máximo (31) fuerza al masher a un whiff + lockout de 9 que lo desincroniza. Ver worked example en Fórmula 2.

### Regla 4 — Acción Especial, curación y severidad (mitad cuantitativa del riesgo)

1. Cada `Acción Especial` declara `interrumpible_por_parry` (booleano) y, si y solo si es `true`, una **Ventana Especial** interna con su propio par de eventos (distinto del de `Golpe`). `true` sin ventana y `false` con ventana son configuraciones ilegales (fallan al cargar: E1/C5d del sistema 2). `calidad_timing` no se calcula para Ventana Especial; nunca hay Parry Justo ni bono de hitstop sobre ella.
2. **El estado `Acción Especial` nunca reduce la Vida del jugador, en ninguna rama.** El parry fallido contra la ventana cierra la ventana sin daño y la acción se completa; el coste de ignorarla se paga en la moneda de la habilidad, acotado por R9a en equivalencia (punto 4), nunca en Vida directa.
3. **Tasa de curación acotada (cierra la mitad cuantitativa de `systems-index.md`):** sea `H` la Vida restaurada por una completación y `T_ciclo_medio` el tiempo medio entre dos Golpes de Castigo del duelo (ticks). La curación es legal si y solo si `H ≤ dano_golpe_castigo` por completación **y** `ΣH_completadas_por_duelo ≤ (ciclos_objetivo − 1) × dano_golpe_castigo` (Fórmula 3). La primera cláusula impide que una sola habilidad anule más de un castigo entero; la segunda garantiza que `Muerto` siga alcanzable aunque todas las especiales del duelo se completen (queda al menos un castigo de progreso neto). Una habilidad no interrumpible (`false`) **no puede ser curación** — solo efectos de arena/buff sin restauración de Vida (ver Edge Cases).
4. **Severidad en equivalencia (R9a, consumida, no redefinida):** toda habilidad interrumpible declara `s` en unidades de `dano_golpe_enemigo` vía `s = parries_extra_forzados × (1 − 0.72)`, con banda `1.0 ≤ s ≤ 2.0` por ventana y `Σs ≤ golpes_para_morir_base − 1 = 3` por duelo. Para curación, `parries_extra_forzados = (H / dano_golpe_castigo) × parries_por_ciclo`. Sin declaración de `s` no hay patrón interrumpible — no existe "coste no cuantificado" (espejo del AC D13 de Combate). Ver Fórmula 4 y ejemplo Cosmos 40 ✓ / 80 ✗.

### Regla 5 — Cadencia del encuentro tutorial (Vigilante)

El primer duelo debe enseñar el ciclo de whiff sin matar por él (`game-concept.md`: whiffear es el método de aprendizaje de los primeros 10 minutos; `recuperacion_whiff` castiga desproporcionadamente al que aprende). Por tanto, todos los patrones del Vigilante cumplen: `separacion_entre_golpes ≥ parry_window + recuperacion_whiff + margen_reaccion_min` (13 + 9 + margen; con margen PROVISIONAL 12 → ≥34 ticks entre el cierre de una ventana y la apertura de la siguiente, fuera de combo). El tutorial no usa combos de `N > 3` ni Acción Especial. Es la única cadencia que este GDD fija como suelo absoluto en vez de rango — el resto de jefes pueden apretar hasta el piso de la Regla 2.

### Regla 6 — Contrato de datos explícito con el sistema 2 (placeholders del congelado)

| Este sistema expone al sistema 2 (lectura de configuración) | El sistema 2 expone a este sistema (eventos/límites) | Placeholder hasta la 4ª pasada del #2 |
|---|---|---|
| duraciones por patrón, `N`, `S_base`/`J`, `interrumpible_por_parry` + ventana declarada, `s`, `H`, intervalos y máximos | `golpe_iniciado/finalizado`, `ventana_especial_abierta/cerrada`, `combo_abortado(i,N)`, `estado_ingresado/abandonado`, `duelo_ganado`; resultado `parry_resuelto` vía Combate | `accion_especial_completada(habilidad_id, tick)` — nombre + payload **reservados** por ADR-002 §2, no implementados: hasta entonces la completación usa la variante sorda provisional de Feedback Regla 5 y este sistema no asume su firma; `castigo_conectado(vida_restante, fue_letal)` — mitad contacto del §5, a declarar en la 4ª pasada; corrección E3b 113→114 y `restantes(T)` inclusivo (`ventana + 1 − T`) — este GDD consume la forma inclusiva de Combate y nunca el literal |
| Validación propia al autorar/cargar: `3 ≤ N ≤ 5`, `J ≥ 14`, piso Regla 9, banda + suma R9a, tasa de curación, tutorial | Orden fijo cierre → resultado → transición; resolución síncrona Regla 8 (nada fuera del call stack de origen; sin `await`/`Tween`/`SceneTreeTimer`/`animation_finished`/cola; sin reentrada de suscriptores) | La fila reversa "depended on by Feedback" y la fila de feedback de completación distinguible del evento 16 (V7) las escribe el #2; este GDD no las duplica |

## Formulas

> Formato mandatory: cada fórmula trae expresión nombrada, tabla de variables, rango de salida y ejemplo trabajado. Lo consumido por referencia nombra su dueño; lo poseído aquí nombra su rango PROVISIONAL y su OQ.

### F1. Piso de justicia del patrón siguiente (`piso_regla9`)

`enfriamiento + telegrafiado ≥ recuperacion_recepcion_max + margen_reaccion_min`

| Symbol | Type | Range | Description |
|---|---|---|---|
| `enfriamiento` | int | 20–50 ticks (PROVISIONAL, OQ2) | `duracion_enfriamiento` declarada por el patrón que sigue a un Golpe que conectó |
| `telegrafiado` | int | 30–60 ticks (PROVISIONAL, OQ2) | `duracion_telegrafiado` del mismo patrón siguiente |
| `recuperacion_recepcion_max` | int | 12 fijo (consumido de Combate, techo del rango 8–12) | Peor caso de compromiso del jugador tras Golpe conectado; se evalúa siempre en techo por regla de consumo de Combate |
| `margen_reaccion_min` | int | 8–28 ticks (PROVISIONAL: suelo 8 nuevo, cota sup 28 heredada de session-state) | Aire de reacción garantizado tras recuperar el control; propiedad de este sistema, a fijar por playtesting |
| `piso_exigido` | int | 20–40 ticks (derivado) | Suma mínima admisible `12 + margen` |

**Output range:** booleano de validación (pasa/falla al cargar) + `piso_exigido` en [20, 40]. Clamp: ninguno — el fallo es FAIL_LOAD, nunca degradación silenciosa.

**Worked example:** patrón con `enfriamiento = 22`, `telegrafiado = 34`, `margen = 12` (PROVISIONAL) → suma 56 ≥ 24 ✓ pasa con 32 ticks de aire. Contra-ejemplo: `enfriamiento = 10`, `telegrafiado = 12`, `margen = 12` → 22 < 24 ✗ falla al cargar aunque cada duración aislada "parezca razonable" — es exactamente el agujero que la Core Rule 9 existe para cerrar.

> **Doble lado de la invariante (doctrina R4/R5/R8: nace con los dos lados).** Suelo: sin piso, el segundo golpe es imparable por aritmética (Pilar 2 roto de forma indistinguible de "leí mal"). Techo: `12 + margen ≤ retreat_base + recuperacion_recepcion_max` en la práctica — con cota sup `margen ≤ 28`, el piso máximo es 40 < 42 (`retreat_base`): el camino simple nunca exige más aire que el colchón post-Castigo ya validado (42 = 14 + 28, techo de Castigo + cota sup). Un `margen > 28` invertiría la jerarquía (el caso menos comprometido pediría más aire que el más comprometido) y diluiría la tensión entre golpes.

### F2. Separación intra-combo anti-mash (`separacion_antimash`)

`S_k ~ Uniforme(S_base − J/2, S_base + J/2), con J ≥ 14; S_base ∈ [18, 30]`

| Symbol | Type | Range | Description |
|---|---|---|---|
| `S_k` | int | 11–37 ticks (derivado del rango) | Ticks entre cierre de `Golpe k` y apertura de `Golpe k+1` dentro del mismo `En Combo` (el Telegrafiado interno) |
| `S_base` | int | 18–30 ticks (PROVISIONAL, OQ3) | Media de separación del combo; fija la legibilidad base |
| `J` | int | 14–24 ticks (PROVISIONAL: suelo 14 normativo, techo 24 por legibilidad) | Amplitud total del jitter; la única palanca que queda contra el mash intra-combo (R6 no aplica dentro de aciertos) |
| `parry_window` | int | 13 fijo (consumido) | Ventana activa del jugador; umbral que el jitter debe superar para forzar whiffs al masher |

**Output range:** cada `S_k` entero en `[S_base − J/2, S_base + J/2]`; `J < 14` → FAIL_LOAD. Sin clamp runtime — el sorteo es al autorar/cargar el duelo.

**Worked example:** `S_base = 24`, `J = 14` → `S_k ∈ [17, 31]`. Masher a cadencia fija 16 (13 activo + 3 recuperación de acierto): si `S_1 = 17`, su parry sigue activo y acierta por caso (b); si `S_2 = 31`, su ventana expiró 18 ticks antes de la apertura → whiff + lockout 9 → llega 9 ticks tarde al siguiente Golpe → Golpe conecta (25) y combo aborta. Con `J = 9` (ilegal desde hoy): `S_k ∈ [20, 28]` — el masher nunca paga lockout y el dato medido lo confirma (100% a 2/4/6/9, solo 12 muerde).

### F3. Tasa de curación acotada (`tasa_curacion`)

`H ≤ dano_golpe_castigo  AND  ΣH_completadas ≤ (ciclos_objetivo − 1) × dano_golpe_castigo`

| Symbol | Type | Range | Description |
|---|---|---|---|
| `H` | float | (0, `dano_golpe_castigo`] por completación (PROVISIONAL en magnitud absoluta; ver ejemplo) | Vida restaurada por una `Acción Especial` de curación completada; propiedad de este sistema por habilidad |
| `dano_golpe_castigo` | float | consumido de Combate F6 (p. ej. 40 en Cosmos con `vida_max_angel = 200`) | Único drenaje del jugador; ancla de la cota |
| `ciclos_objetivo` | int | 4/5/6 por tríada (consumido, F3 de Combate) | Castigos necesarios sin curación |
| `ΣH_completadas` | float | [0, `(ciclos−1) × dano`] (presupuesto por duelo) | Suma sobre las completaciones reales del duelo; peor caso = `max_especiales_por_duelo × H` |
| `max_especiales_por_duelo` | int | 1–3 (PROVISIONAL, OQ4; ≤3 por Σ R9a) | Tope de especiales emitidas por duelo; con `H` en techo, 1–2 según tríada |

**Output range:** validación bilateral + `H` efectiva. Si `H > dano` → FAIL_LOAD (anularía un castigo entero de un golpe). Si `H` demasiado baja (< 0.25×dano, PROVISIONAL) → WARNING de diseño (la especial deja de amenazar y su Ventana se vuelve decorativa) — no falla la carga, pero exige justificación en el patrón.

**Worked example (Cosmos):** `dano_golpe_castigo = 40`, `ciclos = 5` → presupuesto `4 × 40 = 160`. Curación `H = 40` con `max = 2` → peor caso 80 ≤ 160 ✓; cada completación anula exactamente 1 castigo, el duelo pasa de 5 a 6 castigos efectivos si ambas se completan. Curación `H = 80` → 80 ≤ 40 ✗ falla en la primera cláusula aunque el agregado cupiera — una sola habilidad no puede costar dos castigos.

### F4. Severidad en equivalencia (`severidad_equivalente` — R9a consumida)

`s = parries_extra_forzados × (1 − tasa_acierto_objetivo), con 1.0 ≤ s ≤ 2.0 y Σs ≤ 3; parries_extra_forzados = (H / dano_golpe_castigo) × parries_por_ciclo`

| Symbol | Type | Range | Description |
|---|---|---|---|
| `s` | float | 1.0–2.0 por ventana; Σ ≤ 3 por duelo (R9a, consumida de Combate) | Coste equivalente de ignorar la Ventana en unidades de `dano_golpe_enemigo`; lo declara este sistema por habilidad |
| `parries_extra_forzados` | float | ≥0 (derivado) | Parries adicionales que la habilidad completada obliga a jugar |
| `H` | float | ver F3 | Curación (u otra magnitud propia) de la habilidad |
| `dano_golpe_castigo` | float | consumido | Convierte `H` a ciclos extra |
| `parries_por_ciclo` | int | 3/4/5 a calidad 0 (consumido: ⌈postura/dano_base⌉) | Convierte ciclos extra a parries extra |
| `tasa_acierto_objetivo` | float | 0.72 ± 0.02 (consumida del prototipo; re-medir si cambian `parry_window`, `umbral_precision` o shake) | Fracción de parries que el jugador objetivo acierta; cada parry extra cuesta `0.28` unidades de presupuesto en esperanza |
| `dano_golpe_enemigo` | float | 25 con valores de lanzamiento (consumido, F8) | Unidad de la equivalencia: un Golpe no parado = 1.0 por definición |

**Output range:** `s` en [1.0, 2.0]; fuera → FAIL_LOAD. `Σs > 3` → FAIL_LOAD aunque cada término esté en banda (la suma es lo que mata). Semántica: la banda se evalúa en esperanza, el agregado en peor caso (ceil).

**Worked example (el caso que importa, Cosmos):** `H = 40`, `dano = 40`, `parries = 4` → `extra = 4`, `s = 4 × 0.28 = 1.12` ✓ en banda. `H = 80` → `extra = 8`, `s = 2.24` ✗ fuera. Techo robusto de la banda para esa tríada: `H ≤ 66` (67–71 zona de re-medida bajo tolerancia ±0.02). Tres VEs a 2.0 sumarían 6.0 > 3 ✗ — el agregado obliga a elegir: una VE a 2.0, o hasta tres a 1.0.

## Edge Cases

| Escenario | Comportamiento esperado | Justificación |
|---|---|---|
| Patrón declara `N ∉ {3,4,5}` | Falla la validación de datos al cargar (FAIL_LOAD, exit non-zero + ERROR + no arranca el duelo); nunca se degrada a combo truncado ni a simples | Gate primario C16 de Combate + defensa en profundidad C7 del sistema 2. Rango de autoría, no condición runtime |
| Patrón declara `J ≤ 13` o no declara `J` en un combo | FAIL_LOAD con el mismo formato; el combo nunca se ejecuta | Dato medido: 2/4/6/9 no muerden (100% mash). Un combo sin jitter declarado es un combo macheable por construcción |
| Patrón viola el piso Regla 9 (`enfriamiento + telegrafiado < 12 + margen`) | FAIL_LOAD; nunca se ejecuta degradado | C9 del sistema 2. Evaluado en techo 12, nunca en nominal — evaluarlo en suelo lo vuelve auto-satisfacible |
| Habilidad interrumpible sin `s` declarada, o con `s` fuera de [1.0, 2.0], o con `Σs > 3` en el duelo | FAIL_LOAD en los tres casos; no existe "coste no cuantificado" | Espejo del D13 de Combate. La banda acota un término, el agregado acota la magnitud que mata (raíz C) |
| Habilidad con `H > dano_golpe_castigo` o con `ΣH > (ciclos−1) × dano` en peor caso | FAIL_LOAD; el patrón no entra en el roster | Sin esto, `Muerto` es inalcanzable sin violar ninguna fórmula individual — el mismo modo de fallo que `multiplicador → 0` por el extremo opuesto |
| `Acción Especial` no interrumpible (`false`) que restaura Vida (`H > 0`) | FAIL_LOAD: una curación intocable es estancamiento infinito sin vía de robo | R9a solo acota lo interrumpible. Lo intocable con curación no tiene techo — prohibido por construcción, no balanceado por números |
| `interrumpible = true` sin Ventana Especial, o `false` con Ventana | FAIL_LOAD (E1/C5d del sistema 2); este sistema no lo resuelve en runtime | Configuración incoherente/semánticamente vacía. Hacerla ilegal cierra la colisión con el C5 de Combate por construcción |
| El jugador derrota al jefe a mitad de `En Combo` o `Acción Especial` (Vida jugador a 0) | El FSM se congela de inmediato, libera temporizadores, descarta `i`/`window_id` en curso, no emite ninguna señal de transición (nunca `duelo_ganado`) | Espejo del E7 de Combate. `En Combo` es el único contenedor con bucle contado — donde filtraría estado a la siguiente run |
| Interrupción y vencimiento natural de `Acción Especial` empatan en el mismo tick | Gana la interrupción: se emite `accion_especial_interrumpida` una vez, `accion_especial_completada` cero veces, en el mismo paso de resolución | Un parry exitoso nunca se ignora por empate de temporización (E2 del sistema 2, orden y conteo por señales, no estado final) |
| Golpe de Castigo contacta en el último tick de `ventana_castigo` (120) | Cuenta como conexión (→ `Repliegue` 42), no como expiración; este sistema gobierna el contacto, Combate la pulsación (borde `T_max = ventana − gracia`, nunca literal) | Precedente `parry_window`: nunca excluir un evento válido por un tick. Banda de contacto 116–124 por inicio 6–8 + activos 4–6 (Feel Targets, por referencia) |
| Efecto de Estado futuro (sistema 19) daña fuera de `Aturdido` | Este GDD no lo consume ni lo reemite: ese daño viaja por eventos propios del 19, nunca reutilizando `golpe_iniciado`; el test E5 del sistema 2 sigue en rojo como alarma (gate Logic BLOCKING) con runtime en aserción blanda + WARN hasta que el 19 lo reescriba | Protocolo ADR-002 §6.5 ratificado. Romper E5 por diseño sin reescribirlo es violación de proceso |
| Patrón tutorial con separación < `parry + whiff + margen` o con `N > 3` | FAIL_LOAD en la validación del encuentro tutorial (AC D5) | El tutorial es el único suelo absoluto de este GDD — enseñar el whiff sin matar por él |
| `margen_reaccion_min`, `S_base`, `H` o `s` fuera de sus rangos seguros bilaterales | FAIL_LOAD si rompe invariante dura (piso, `J`, R9a, tasa); WARNING + justificación obligada en el patrón si cae en zona blanda (curación < 0.25×dano, `J` en techo de legibilidad) | Distinción FAIL_LOAD (corrupción/división por cero/rango ilegal) vs sweep-gated (degeneración de feel) — glosario C16 de Combate |

## Dependencies

| Sistema | Dirección | Naturaleza |
|---|---|---|
| Máquina de Estados de Jefe (2) | **Bidireccional, asimétrica (2↔20)** | Este sistema depende **duro** del #2 (conjunto cerrado de 9 estados Regla 7, resolución síncrona Regla 8, Ventana Especial Regla 5, piso Regla 9 — sin el esqueleto no hay dónde expresar un patrón). El #2 depende **blando** de este (duraciones y composición; opera con placeholders hasta que este GDD exista). El #2 impone a este: `3 ≤ N ≤ 5`, piso `12 + margen`, Ventana obligatoria bajo `true` / prohibida bajo `false`, C8 por identidad |
| Combate de Parry-Absorción (1) | Este depende de Combate (vía #2) | Dura — consume `parry_window`, `recuperacion_whiff/recepcion/castigo`, `retreat_base`, `ventana_castigo/gracia`, `dano_golpe_enemigo/castigo`, `postura_max`, `ciclos_objetivo`, R2/R4/R6/R7/R8/R9a/R10. Combate impone a este: `3 ≤ N ≤ 5`, varianza intra-combo (nota de R6), hueco de whiff en tutorial, banda + suma R9a en equivalencia. Este no impone nada a Combate |
| Feedback de Impacto (4) + Sonoro (16) | Estos consumen (previsto) | Informativa — este sistema no emite ni posee feedback; solo garantiza que los datos que esos sistemas necesitan existan (`i`/`N` vía #2, `window_id`, distinguibilidad cierre-vs-completación vía #2). Oráculos y triggers los poseen el #4; timbre/mezcla/valores el #16 |
| Sistema de Gracia (5) | Co-consumidor | Informativa — ambos consumen `parry_resuelto`; R9b (coste no nulo de la Gracia de VE) es precondición de que R9a signifique algo. Si el #5 la violase, R9a debe re-derivarse |
| Gestión de Run (3) | Run depende (transitivo) | Informativa — consume `duelo_ganado` del #2; el payload adicional (qué jefe, tríada, duración) lo decide el #3, con campos al final con defaults |
| Efectos de Estado (19) | Futura | El #19 romperá E5 por diseño con eventos propios; este GDD no le presta `golpe_iniciado` ni le consume nada |
| Lucifer (11) | Futura | Vía declarada por el #2 (sub-estado anidado en `Acción Especial false`, sin enmienda); este sistema le proveerá patrones de transición cuando el #11 se autore |
| HUD (13), Guardado (12), Accesibilidad (21) | Estos dependen / exponen | `parry_window` + `recuperacion_whiff` se exponen al #21 como par (bajar solo el segundo viola R6); ninguna duración de este GDD se expone a accesibilidad sin reverificar piso Regla 9 y R6 efectiva |

> **Clasificación por rigidez:** dura — #2 (sin esqueleto no hay patrón) y #1-vía-#2 (sin ventanas no hay nada que parar). Blanda — ninguna en esta dirección: este sistema es hoja de datos y no necesita placeholders de otros para autorarse, solo valores consumidos por referencia.

## Tuning Knobs

> Todos los rangos son **bilaterales** (qué se rompe por arriba y por abajo). PROVISIONAL = pendiente de adjudicación en OQ; no usar en producción sin playtest externo en Deck 7".

| Knob (propiedad del 20 salvo nota) | Valor PROVISIONAL | Rango seguro bilateral | Si muy alto | Si muy bajo |
|---|---|---|---|---|
| `margen_reaccion_min` ⚠️ (suelo fijado aquí) | **12 ticks** | **8–28** (suelo 8 nuevo + cota sup 28 heredada) | >28 invierte la jerarquía de colchones (el simple pediría más aire que el colchón post-Castigo 42) y el duelo se vuelve flotante; cada +4 ticks ≈ +6.7% de tiempo muerto por ciclo | <8 el segundo golpe tras conectar es imparable por borde para el percentil de reacción objetivo; por debajo de 6 ni el tutorial lo salva |
| `duracion_telegrafiado` | 42 ticks | 30–60 | >60 el patrón se vuelve trivial y el duelo se alarga sin pedir más habilidad (grind de espera, aviso Pilar 1) | <30 ilegible en Deck 7" y por debajo del presupuesto de onset del #4 (juicio ≤2 + confirmación ≤10); se siente aleatorio |
| `duracion_golpe` (ventana activa nominal) | 14 ticks | 10–20 | >20 el perdón de anticipación cubre tanto que la lectura deja de importar; picos de concurrencia de audio/VFX crecen | <10 la ventana es más corta que `parry_window` (13) y solo el caso (b) salva — el parry reactivo desaparece |
| `duracion_enfriamiento` | 32 ticks | 20–50 | >50 el duelo pierde presión y la Gracia por minuto cae (interacción con #5) | <20 solo viable con telegrafiados largos; si la suma viola el piso → FAIL_LOAD, no tuning |
| `S_base` (separación media intra-combo) | 24 ticks | 18–30 | >30 el combo deja de sentirse combo (dos simples con pausa) y el cue ascendente 7→8 se rompe | <18 las ventanas se solapan con la recuperación de acierto (2–3) y el combo es una sola ventana larga macheable |
| `J` (jitter intra-combo) ⚠️ | 16 ticks | **14–24** (suelo 14 normativo, techo por legibilidad) | >24 el combo se vuelve impredecible en vez de legible-con-varianza; el jugador deja de intentar leer y espera (estrategia de espera, no de mash pero igual de degenerada) | <14 (incluido "sin jitter") el mash a cadencia fija sobrevive — medido 100% a ≤9; FAIL_LOAD, no preferencia |
| `longitud_combo_N` (consumida de Combate) | por patrón | **3–5 ambos lados** | >5 el cue ascendente es inimplementable (clipping/loop/meseta) y se excede el presupuesto de 250 partículas | <3 la Fórmula 7 incumple su garantía (`2 × 0.5 = 1.0`, igual que un simple; a 0.3 → 0.6, peor) |
| `curacion_por_accion_H` | 30 (Hum.) / 40 (Cosmos) / 50 (Cercanía) con `dano` 30/40/50 | (0.25×dano, 1.0×dano] por completación + agregado `(ciclos−1) × dano` | >1.0×dano anula un castigo entero de un golpe (FAIL_LOAD); agregado >presupuesto hace `Muerto` inalcanzable | <0.25×dano la especial deja de amenazar (WARNING: justificar por qué existe su Ventana) |
| `intervalo_min_entre_especiales` | 2 ciclos | 1–4 ciclos | >4 la especial es tan rara que su Ventana no se aprende | <1 (especial cada ciclo) el duelo es una cadena de dilemas sin respiro; además presiona Σ R9a |
| `max_especiales_por_duelo` | 2 | 1–3 (techo 3 por Σ≤3 con `s ≥ 1.0`) | >3 imposible en banda mínima (3 × 1.0 = 3 ya es el techo agregado) | 0 equivale a no tener Oficiante — válido solo fuera de Cercanía |
| `severidad_equivalente_s` (por habilidad) | por habilidad | **1.0–2.0 por ventana y Σ ≤ 3 por duelo (R9a, ambos lados)** | >2.0 o Σ>3 pararla pasa a ser obligatoria y el dilema muere por el lado opuesto | <1.0 ignorarla domina estrictamente (mismo beneficio de combate, menos coste) |
| `vida_max_angel` | 120/200/300 (para `dano` 30/40/50 × ciclos 4/5/6) | por tríada, derivado de F6 (no rango libre) | >derivado alarga el duelo sin pedir más aciertos por ciclo (grind de Vida, prohibido por Pilar 1) | <derivado rompe el suelo de ciclos 4/5/6 por abajo |
| `separacion_tutorial` (Vigilante) | `13 + 9 + margen` (≥34 con margen 12) | suelo absoluto, sin techo propio (el techo es el de legibilidad) | más aire solo hace el tutorial más lento, sin riesgo de justicia | por debajo el whiff de aprendizaje cuesta 25 y el tutorial enseña a no intentarlo |

**Interacciones:** `enfriamiento × telegrafiado × margen` determinan el piso (F1) — tocar cualquiera sin recalcular los otros dos desactualiza el aire real; `S_base × J` determinan la firma anti-mash (F2) — subir la base sin subir el jitter recentra pero no desincroniza; `H × max_especiales × dano × ciclos` determinan la alcanzabilidad de `Muerto` (F3) — el agregado manda sobre el término; `s × Σ` determinan el dilema (F4) — la banda sin el agregado es la raíz C por cuarta vez.

## Acceptance Criteria

> Puertas: **Gate 1 Logic (BLOCKING)** en `tests/unit/ia-combate-jefes/` con eventos de Combate/sistema 2 **mockeados** (inyecta `parry_resuelto` sintéticos y límites `B-*` sintéticos; determinista, semilla fijada) — cubre topología de datos y validación. **Gate 2 Integration (BLOCKING)** en `tests/integration/ia-combate-jefes/` con Combate + FSM reales cableados (verifica que los eventos crucen la frontera y que la Regla 8 se cumpla fuera del mock — un mock sincrónico pasaría el Gate 1 aunque la implementación fuese asíncrona). Patrón transversal: **TR-jefe-010** (patrones de IA sobre el esqueleto cerrado). Prefijos: C = comportamiento, D = fórmula/dato, E = borde, X = contrato.

- [ ] **D1 piso_regla9 (Logic, TR-jefe-010)** — GIVEN cualquier patrón que pueda seguir a un Golpe que conectó con `margen` declarado, WHEN se valida al cargar, THEN `enfriamiento + telegrafiado ≥ 12 + margen` exacto en enteros; un patrón con suma 22 y piso 24 falla con FAIL_LOAD y nunca se ejecuta. Se prueba en los cuatro bordes del rango `margen ∈ {8, 28}` × suma ±1.
- [ ] **D2 antimash_J (Logic, TR-jefe-010)** — GIVEN un combo con `S_base = 24`, WHEN `J ∈ {13, 14}`, THEN `J = 13` falla al cargar y `J = 14` pasa; AND el barrido `J ∈ {2, 4, 6, 9, 12}` documenta en el log que todos ≤13 fallan (regresión del dato medido 93/93). No se asevera tasa de mash aquí (eso es C12b de Combate con harness reactivo) — aquí solo la guarda de datos.
- [ ] **D3 tasa_curacion (Logic, TR-jefe-010)** — GIVEN tríada Cosmos (`dano = 40`, `ciclos = 5`), WHEN `H ∈ {40, 41, 80}` y `max = 2`, THEN `H = 40` pasa (peor caso 80 ≤ 160), `H = 80` falla en la primera cláusula, y `H = 40` con `max = 5` (peor caso 200 > 160) falla en la segunda aunque cada término sea legal — prueba de que el agregado no es redundante.
- [ ] **D4 severidad_R9a (Logic, TR-jefe-010)** — GIVEN las habilidades del roster, WHEN se validan, THEN cada `s ∈ [1.0, 2.0]` y `Σs ≤ 3` por duelo; AND un duelo con tres VEs a 2.0 (Σ = 6.0) falla aunque cada término esté en banda; AND toda habilidad interrumpible sin `s` declarada falla ("coste no cuantificado"). Casos Cosmos 40 → 1.12 ✓ / 80 → 2.24 ✗ del ejemplo como fixtures fijos.
- [ ] **D5 tutorial (Logic, TR-jefe-010)** — GIVEN todos los patrones del Vigilante, WHEN se validan, THEN `separacion ≥ 13 + 9 + margen` con los knobs vivos (no literales) y `N ≤ 3` y cero especiales; un patrón tutorial con separación 33 y piso 34 falla.
- [ ] **C1 composicion_N (Logic)** — GIVEN el roster v1.0, WHEN se carga, THEN todo `N ∈ {3, 4, 5}`; `N = 2` falla al cargar (no se degrada a simples) y `N = 6` falla; AND ningún patrón introduce un estado top-level fuera de los 9 (verificación documental `/design-review` hasta que el enum compilado exista, luego C8 del sistema 2 por identidad).
- [ ] **C2 arquetipos_cubiertos (Logic)** — GIVEN el roster cargado, WHEN se inspecciona, THEN existen al menos un patrón simple, un combo por cada `N ∈ {3, 4, 5}` en algún jefe, y exactamente un Oficiante con curación interrumpible + Ventana declarada; AND ninguna curación con `interrumpible = false`.
- [ ] **C3 no_emite_senales (Integration)** — GIVEN un duelo completo con FSM + Combate reales, WHEN se espía el bus con `signal_order_spy`, THEN cero señales emitidas con emisor "sistema 20"; todas las `B-*` las emite el FSM y todas las `C-*` el resolver, en orden cierre → resultado → transición con `window_id` correlacionado.
- [ ] **X1 contrato_placeholders (Integration)** — GIVEN build limpia con el sistema 2 congelado, WHEN se listan los símbolos que este GDD asume del #2, THEN `accion_especial_completada` y `castigo_conectado` constan como **reservados-no-implementados** (cero referencias de código, solo mención documental) y `restantes(T)` se evalúa en forma inclusiva (`ventana + 1 − T`, borde `ventana − gracia`, nunca literal); AND el test falla si aparece el literal 114 o el conteo exclusivo en cualquier fixture nuevo.
- [ ] **X2 config_externa (Logic)** — GIVEN build limpia, WHEN cada knob propio (`margen_reaccion_min`, duraciones, `S_base`, `J`, `H`, intervalos, máximos, `s`, `vida_max_angel`) se altera en su fichero de datos, THEN el valor en runtime cambia sin tocar código (12/12); AND `physics_ticks_per_second == 60` es inalcanzable desde configuración (gate P3 de Combate).
- [ ] **E1 aborto_remate (Integration, TR-jefe-004)** — GIVEN `En Combo N = 5` real, WHEN el jugador falla `i = 5` (remate) tras parar 4, THEN los golpes 6+ son conjunto vacío, no hay daño de Postura parcial, el FSM emite `combo_abortado(5, 5)` leído del payload (no inferido) y entra en `Repliegue` 42 — espejo del C3b/E4 del sistema 2 desde el lado de los datos.
- [ ] **E2 plasmar_truncado (Integration)** — GIVEN un `Golpe` con duración nominal 14 resuelto por perdón de anticipación en el tick 4, WHEN se observa presentación, THEN la animación se trunca sin error ni VFX huérfano y el estado cierra en el instante de resolución (convención "resolución = límite") — verifica que la consecuencia sin propietario tiene dueño.
- [ ] **Visual/Feel (ADVISORY, evidencia en `production/qa/evidence/`)** — GIVEN 5 playtesters × 2 jefes distintos (Vigilante + Coro u Oficiante), WHEN se les observa sin preguntar dirigidamente, THEN ninguno describe un patrón como "imparable por ritmo" ni el mash como "estrategia viable", y al menos 4/5 distinguen espontáneamente los tres arquetipos por su forma de pelear ("el que mide / el que encadena / el que se cura").

> **Nota de cobertura (dos gates, no uno):** el Gate 1 prueba **qué datos son legales** (rápido, determinista, con mocks); el Gate 2 prueba **que los cables están puestos** (eventos reales, orden Regla 8 en sus dos casos C4a + E2 del sistema 2). Un mock sincrónico pasaría el Gate 1 aunque la implementación real fuese asíncrona — por eso el Gate 2 exige C3/X1/E1 fuera del mock.

## Open Questions

| # | Pregunta | Opciones (recomendada ★) | Owner / Deadline |
|---|---|---|---|
| OQ1 | ¿Arquetipos finales y reparto por tríada? Tabla PROVISIONAL Vigilante/Coro/Oficiante. | (a) ★ Mantener los 3 propuestos (tutorial necesita Vigilante, curación necesita Oficiante) — menor riesgo, Pilar 3 visible en v1.0. (b) 2 arquetipos (fusionar Coro+Oficiante) — menos autoría pero el duelo de Cercanía pierde su dilema propio. (c) 4+ con sub-variantes por jefe — especulación de año 2, rechazar para v1.0 | `game-designer` + `creative-director` / antes del slice vertical |
| OQ2 | ¿Duraciones finales y `margen_reaccion_min` definitivo? PROVISIONALES: tele 30–60 (42), golpe 10–20 (14), enfri 20–50 (32), margen 8–28 (12). | (a) ★ Fijar en playtest externo en Deck 7" con protocolo de reacción (suelo = percentil 90 + 2 ticks de aire) — único método que mide lo que el piso protege. (b) Fijar analíticamente desde Recepción 12 + latencia media — rápido pero certifica el modelo, no al jugador (lección C12b). (c) Heredar de Sekiro sin medir — rechazar: presupuestos de error distintos (4 vs posture propia) | sistema 20 + playtest / slice vertical |
| OQ3 | ¿`S_base` y techo de `J` finales? PROVISIONALES 24 y 14–24. | (a) ★ Barrido `S_base × J` contra harness masher + reactivo con latencia 6 (el veredicto se invierte según latencia — lección C12b) y elegir la celda con mash <60% y reactivo >80%. (b) Fijar `J = 14` mínimo y no medir techo — deja la ilegibilidad sin cota. (c) Varianza por jefe en vez de global — rechazar hasta que el barrido global exista | `systems-designer` + `qa-lead` / pre-sprint de IA |
| OQ4 | ¿Frecuencia de especiales (`intervalo_min`, `max/duelo`) y `H` por tríada? PROVISIONALES 2 ciclos / max 2 / H 30-40-50. | (a) ★ `max = 2` con `H ≤ dano` (el duelo se alarga como máximo en 2 castigos; Σ R9a manda) — conserva el dilema sin amenazar `Muerto`. (b) `max = 1` (una sola oportunidad de robo por duelo) — más seguro pero la Ventana se vuelve anécdota. (c) Especiales no-curativas ilimitadas — solo si son buffs/arena sin `H`, con `s` igualmente declarada | `game-designer` / al autorar Oficiante |
| OQ5 | ¿Payload adicional de `duelo_ganado` (qué jefe, tríada, duración)? | (a) ★ Solo `tick` hoy; añadir campos al final con defaults al autorar el sistema 3 — compatible hacia atrás, no bloquea combate. (b) Fijarlo hoy — especular sobre necesidades de Run/Meta sin su GDD (rechazar) | sistema 3 / al autorar Run |
| OQ6 | ¿Mecanismo Regla 8 (nodo autoritativo / `process_physics_priority` / llamada directa)? | Decisión de `/create-architecture` (ADR-001/002 ya aceptan dirección Combate→FSM + señales síncronas obligatorias; falta V1 de 10 líneas en 4.7.2). Este GDD no prejuzga mecanismo — solo exige orden y conteos por señales | `technical-director` / antes del primer sprint (bloquea historias FSM) |

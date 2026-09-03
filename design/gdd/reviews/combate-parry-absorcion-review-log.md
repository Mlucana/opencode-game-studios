# Review Log — Combate de Parry-Absorción

Historial de revisiones de `design/gdd/combate-parry-absorcion.md` (sistema 1/21,
capa Fundación, prioridad MVP). Una entrada por pasada de `/design-review`.

---

## Review — 2026-08-04 (3ª pasada, primera propia) — Verdict: NEEDS REVISION

Scope signal: L (reparación del documento, en dos changesets) / XL (implementación)
Specialists: game-designer, systems-designer, **qa-lead** (obligatorio por el header —
entregó), ux-designer, audio-director, performance-analyst, godot-specialist,
**economy-designer** (voz nueva, nunca había revisado este documento) + síntesis senior
de creative-director
Blocking items: 11 | Recomendados: 11 | Nice-to-have: 5
Prior verdict resolved: **N/A** — es la primera revisión adversarial propia desde la
aprobación. Las 4 enmiendas post-aprobación (A–G) nunca habían pasado por una.

**Summary**: `creative-director` reagrupó ~35 hallazgos en **4 clases raíz**, y **tres
son recurrencias**. La arquitectura vuelve a salir intacta —nadie ha atacado en tres
pasadas el bucle central, la fantasía, la frontera de propiedad con Gracia, el modelo
duras/blandas ni la clasificación de capa—, así que el veredicto **no** es MAJOR: *"el
diseño no es el problema; etiquetarlo MAJOR sería un diagnóstico falso."* Lo que falla
por tercera vez es el **procedimiento de enmienda**.

### Las 4 raíces

| Raíz | Descripción | Hallazgos | Recurrencia de |
|---|---|---|---|
| **A** | Se introdujo un **tipo suma** («ventana parable» = `Golpe` ∪ Ventana Especial) y solo se visitaron los sitios que **nombraban** uno de sus constructores. El barrido de la enmienda A fue **léxico sobre la palabra "Golpe"** | **8** | la propia enmienda A |
| **B** | Las enmiendas se detienen en la frontera normativa/experiencial. La prueba **sí** se escribe ahora (C19–C21, E11, bien construidos) y el barrido para justo después: de las cuatro enmiendas post-aprobación, **solo la C cruzó a Visual/Audio** | **7** | Clase A de la 2ª pasada, un piso más abajo |
| **C** | La guarda se puso sobre un **término**, no sobre la **magnitud** | **5** | 3ª aparición (la propia Fórmula 6: `< 100` → `≤ 1.0` → constante) |
| **D** | La capa de input se especificó a resolución de **tick** para un consumidor que exige **sub-tick** | **4** | nueva |

> **La lección de proceso estaba bien enunciada y mal aplicada.** El log de la enmienda
> A celebra que *"solo un barrido léxico encuentra todas sus copias"* — correcto para
> las cinco copias que decían la palabra, **invisible para todo lo que expresa el mismo
> cuantificador sin decirla**: D4 y la Fórmula 4 (no usan "Golpe"), `calidad_timing`
> sobre `t_strike_start` (símbolo, no palabra), el contrato al sistema 16 (nombra el
> *resultado*, no la ventana), la tabla de eventos, P0/P5. **Un tipo suma obliga a
> visitar cada consumidor, no cada aparición de un constructor.**

### Verificación aritmética independiente (`creative-director` recalculó antes de aceptar)

| Comprobación | Resultado |
|---|---|
| **D9** afirma que R1–R7 se cumplen en sus 92 casos | **Falso, y sin necesidad de ir a las esquinas**: D9 enumera el producto completo 10×7 de R6 y el documento declara **doce líneas más arriba** que 18 de esas 70 lo violan. El AC se contradecía dentro de su propia tabla |
| R1 esquina (15, 0.5, 20) | `15 × 1.5 = 22.5 < 20` → **FALLA**, y es la esquina que la propia nota de R1 describe |
| R2 esquina (9 ticks, 0.12s) | `9 > 14.4` → **FALLA** |
| R5 esquina (15, 80) | `(15×3)/80 = 56.25% > 55%` → **FALLA, y no estaba documentado.** 2 de 4 esquinas de R5 fallan, no 1 |
| `hitstop_parry` | Contradicción confirmada: 3–6 en Tuning Knobs y R8, **3–8 en Impact Moments** |
| `punish_dano_pct = 100/6` | `6 × (200/6) = 200.00000000000003` en doble precisión → E10/E11 no eran partición exhaustiva |
| `restantes(T)`, enmienda E | **Resiste**. `restantes(114)=7 > 6` → Castigo; `restantes(115)=6` → Parry; zona = 6 ticks. Las tres formulaciones coinciden |
| R7 en toda la matriz `N∈{3,4,5} × mod∈{0.35,0.8}` | **Limpio.** Peor caso `3×0.35 = 1.05 > 1` |

### Adjudicaciones y desacuerdos (registrados, no silenciados)

- **`audio-director` escala "prioridad plana" a bloqueante** — **RECHAZADA en sus
  términos, premisa falsa**. Su argumento era que P5 ya declara un techo y por tanto el
  fundamento del downgrade de la 2ª pasada es nulo. **P5 no declara un techo**: declara
  un *procedimiento de medición* con condición de fallo contingente a una cifra que aún
  no existe; los "4–6 capas" son la **demanda**, no el presupuesto, y la Open Question
  del presupuesto sigue Abierta. Sigue en Recomendado. **Se le concede** lo que sí
  tiene: el precedente correcto ya existe en este documento (Regla de precedencia
  armónica) — declarar precedencia para los pares que *este* GDD crea, sin clasificar
  las 14 filas.
- **`godot-specialist` #2, premisa falsa** — dijo "recortar el suelo a 3 ticks cambia el
  perfil de riesgo". **El suelo nunca se recortó**: el rango era 3–8 y R8 bajó el
  **techo** a 6. El hallazgo técnico (25ms de desalineación Tween/AnimationPlayer = 50%
  de un hitstop de 3 ticks) es correcto y se aplica; su atribución causal a R8, no.
- **`ux-designer`: analógico/digital no es diferible** — **ACEPTADA como bloqueante**,
  pero no por su razón sola: lo vuelve no diferible la **conjunción con
  `godot-specialist` #3**. `umbral_precision` = 4.8 ticks, luego un tick es el **20.8%**
  de la ventana entera de `calidad_timing`; sin sub-tick el Parry Justo deja de medir
  precisión y pasa a ser lotería de cuantización. La única vía a sub-tick
  (`InputEvent.get_timestamp()`) parece **prohibida por la redacción normativa vigente**
  de la Regla 2. Precedente exacto y de este mismo documento: la 2ª pasada revirtió
  `Engine.time_scale` porque *un GDD de capa Fundación no puede publicar una norma
  inconstruible*.
- **`economy-designer` #1 (R5 / `bono_reliquias`)** — **BLOQUEANTE, no diferible al
  sistema 9.** Tres razones: (1) el término sin tope está en una fórmula que **este GDD
  posee**; (2) diferirlo aplicaría de forma inconsistente el patrón que este documento
  ya usa cuatro veces, y *"aplicarlo inconsistentemente es literalmente la raíz #1 de la
  1ª pasada"*; (3) la colisión es **predecible, no casual** — al cerrar R4 en ambos
  sentidos, el documento **recomienda explícitamente** a las reliquias la vía de la Vida
  máxima, empujando al sistema 9 hacia el único término que dejó sin guardar.
- **`economy-designer` #2 (asimetría temporal beneficio/coste)** — **re-litigio** de una
  Open Question co-adjudicada dos veces. Que una voz nueva llegue a la misma conclusión
  sin haber leído las anteriores es *"evidencia fuerte de que la pregunta es real —
  tres especialistas, tres pasadas, independientes"*, pero no cambia su estado. **Sí se
  adopta** su afinación de propiedad: este GDD posee la Vida, luego está mejor
  posicionado que Gracia para definir la contrapartida numérica — lo que vuelve
  **decidible** una pregunta perpetuamente diferible.
- **`qa-lead`: C12b vs D10** — **ACEPTADA y afilada**. No son el mismo bloqueo y la 2ª
  pasada los aplanó. C12b está bloqueado por un **fixture** pero su riesgo lo producen
  mecánicas que **existen hoy** (los combos son de la Regla 9, no del sistema 20) → el
  stub de jefe es **dependencia de calendario de este sistema** y C12b es **puerta de
  release**. D10 está bloqueado por un **artefacto inexistente** → diferido legítimo.
- **`qa-lead`: la ordenación `Recepción de golpe > Golpe de Castigo` es inalcanzable** —
  **confirmada**: el Castigo solo existe con el jefe Aturdido y C5 interrumpe cualquier
  ataque al romperse la Postura. Se anota para no escribir un test con fixture
  imposible.

### Decisión de usuario tomada en esta pasada

**Ventana Especial → opción C** (de tres presentadas). La VE **reutiliza el perfil VFX
del evento 3** —ningún emisor nuevo, así que la Open Question de los 3 emisores **no
escala** y P0/P5 no cambian— y su firma distintiva es **positiva y ya cierta
mecánicamente: el medidor de Gracia se mueve y la barra de Postura no.** Eso convierte
la ausencia en una lectura en vez de en un hueco, que era exactamente la objeción de
`ux-designer` ("una barra que no se mueve se lee como bug"). Más una capa de audio
diferenciada y la cláusula anti-silencio calcada del evento 12. **Ejecución diferida al
changeset 2.** Se descartaron: **A** completarla entera (escalaría la pregunta de los
emisores, y la salida declarada si no bastan es reducir concurrencia de eventos) y **B**
recortar su alcance reabriendo con el sistema 2 (revertiría una decisión deliberada del
usuario del 2026-08-03).

### La decisión de proceso: dos changesets, dos sesiones

`creative-director`: *"Escribí tras la 2ª pasada que lo que no sobrevivió no era la
arquitectura sino la reparación. Tengo que decirlo más fuerte: **a la tercera tampoco.**
El componente defectuoso de este proyecto no es el documento: es el procedimiento de
enmienda."*

**Prueba empírica de que el remedio funciona**: la contradicción de `hitstop_parry` se
encontró el 2026-08-04, se **difirió deliberadamente** bajo la regla *"ningún hallazgo se
cierra en la sesión en que se encuentra"*, y llegó a esta pasada **intacta y confirmada
por dos especialistas independientes**. La regla de diferimiento funcionó; la de
reparación en caliente lleva tres pasadas fallando.

**Changeset 1 — mecánico, sin decisiones. APLICADO en esta sesión (16 arreglos):**

| # | Arreglo | Fuente |
|---|---|---|
| 1 | `hitstop_parry` 3–8 → **3–6** en Impact Moments | `systems-designer` + `godot-specialist` |
| 2 | Fila de Edge Cases del castigo **acotada a no letal** + **fila hermana letal** nueva | `qa-lead` |
| 3 | **Regla de clamp de la Vida del jefe** (Fórmula 6) + fila de Edge Cases + **AC E12** nuevo; E10/E11 reformulados "tras el clamp" | `systems-designer` + `qa-lead` |
| 4 | Fórmula 4 y **D4** acotados a `Golpe`, con excepción de VE explícita | `qa-lead` |
| 5 | **C19–C21 marcados `bloqueado`** + fixture compartido de disparador de depuración (patrón de P1) | `qa-lead` |
| 6 | **D9 con predicado corregido**: partido en **(a)** config de lanzamiento y **(b)** barrido caracterizado contra **tabla de veredictos esperados** | `systems-designer` |
| 7 | **R8 añadido a D9** (4 esquinas, pasa limpio) → **96 casos** | `systems-designer` |
| 8 | **2ª esquina fallida de R5** documentada + suelos efectivos de `vida_base` derivados (110 / 82) | `systems-designer` |
| 9 | **Audio clasificado en el bucket diegético** de la Regla 2 (efecto, no mecanismo) | `audio-director` |
| 10 | `Engine.max_physics_steps_per_frame` como **confundidor declarado** de C13/P4, con obligación de protocolo QA | `godot-specialist` |
| 11 | **C12b (riesgo vivo → puerta de release) separado de D10 (diferido)** | `qa-lead` |
| 12 | Nota **"Sobre R8"** + Open Question del tiempo ampliada (e/f/g) | `godot-specialist` |
| 13 | `(instrumentado)` en **D9** y **C16** | `qa-lead` |
| 14 | **P1 declarado fixture de E11** (3 castigos letales por construcción) | `performance-analyst` |
| 15 | Ordenación inalcanzable de la tabla de prioridad **anotada** (no escribir test) | `qa-lead` |
| 16 | Pool de emisores por `one_shot` + señal **`finished`**, nunca por `emitting` | `godot-specialist` |

**Changeset 2 — decisiones. Sesión aparte, con re-review. PENDIENTE:**
1. **Granularidad de input + analógico/digital**, con reverificación de R2/R6/C2/C13/C18.
2. **Restricciones al sistema 9 reformuladas a nivel de magnitud** — cierra
   R5/`bono_reliquias`, la reliquia estructural (*"un Golpe de Castigo extra por
   aturdimiento"* rompe el suelo de ciclos sin tocar `multiplicador_ataque`) y la
   colisión R4→Vida **de una sola edición**.
3. **Ejecución de la opción C de Ventana Especial** y su cascada a P0/P5.

> **Regla obligatoria para el changeset 2: los ACs primero, la prosa normativa después.**
> Es la lección registrada al cierre de la 2ª pasada. **Tres pasadas escribiéndola, cero
> ejecutándola.**

### Las 5 prioridades (orden de ejecución, no de severidad)

1. **Las tres falsedades vivas** — los tres sitios donde el documento **afirma algo
   falso**. `godot-specialist` se negó explícitamente a certificar implementabilidad
   contra un documento que no ha convergido. *(Hecho en el changeset 1.)*
2. **El predicado de D9** — única puerta automatizada sobre R1–R8, fallaba el día uno, y
   **su arreglo "obvio" —debilitar la aserción— habría borrado la protección entera**,
   que es justo el barrido que encontró el 25.7% de R6. *(Hecho en el changeset 1.)*
3. **Granularidad de input + analógico/digital** — único ítem capaz de dejar
   inconstruible un GDD de capa Fundación; aguas arriba de R2, R6, C2, C13, C18 y de la
   spec de UX.
4. **La decisión de Ventana Especial** — 8 hallazgos, 6 departamentos, una decisión.
   *(Decidida: opción C. Ejecución en el changeset 2.)* Prerrequisito de `/asset-spec`,
   P0 y P5.
5. **Restricciones al sistema 9 a nivel de magnitud** — cierra la tercera recurrencia de
   la raíz C antes de que el sistema 9 se autore encima de ella.

### Recomendados que NO entran en ningún changeset todavía

**Legibilidad prospectiva** (`ux-designer`) — V2/V3 miden percepción *retrospectiva*; con
un botón que cambia de significado según tres estados invisibles, *"¿sabe el jugador
antes de pulsar qué va a salir?"* es la pregunta que más amenaza la Player Fantasy.
`creative-director` la señala como **la aportación más valiosa de la pasada**: el único
hallazgo que *añade* verificación en vez de reparar · **evento 5 vs evento 9**
(`audio-director` tiene razón en que el patrón de este documento exige resolverlo aquí:
la Regla 9 ya dice literalmente "ese golpe conecta") · **no existe fila de "duelo
ganado"** en ninguna parte del documento · croma/luminancia del **medidor de Gracia** ·
**forma** de la Fórmula 5 a 9 ángeles (rendimiento decreciente **por conteo, no por
identidad**, para preservar la independencia de orden de la Regla 8 y E9 —
`creative-director`: *"la mejor idea del lote"*, pero es cambio de diseño) · afinación de
propiedad del coste in-combat de absorber hacia este GDD.

### Fallo de síntesis detectado tras cerrar la pasada — los hallazgos de `game-designer`

**Corrección al propio informe de esta pasada.** De los 8 especialistas, los hallazgos de
`game-designer` **no llegaron al output de la Fase 4** — ni a bloqueantes, ni a
recomendados, ni a nice-to-have. La síntesis de `creative-director` tampoco los recogió,
porque se organizó alrededor de las 4 raíces y éstos no encajaban en ninguna. Es un fallo
del orquestador, no del especialista, y se registra aquí porque es el mismo modo de fallo
que la pasada entera diagnostica: **un barrido que cubre la estructura que ya se está
mirando y calla sobre lo que queda fuera de ella.**

Los tres que se perdieron comparten forma — **la retórica del documento ha derivado de lo
que el sistema hace**, que es una variante de la raíz **B** (la enmienda toca la norma y
no la capa experiencial) aplicada al texto que describe la sensación:

1. **BLOQUEANTE-adjacent — la Ventana Especial está dominada por ignorarla.** Pararla
   concede **Gracia completa** (= corrupción) y **cero beneficio de combate** (ni Postura
   ni Repliegue, Regla 4). **No** pulsarla no cuesta nada: no hay whiff sin pulsación
   (Regla 7), y el corolario de la Regla 6 declara que una VE no parada no daña. El único
   coste de ignorarla es *"el jefe completa su habilidad"* — una severidad que este GDD
   **nunca exige a nadie garantizar**. Un jugador que lee patrones aprende racionalmente
   *"pararla solo me corrompe para nada"*. Estrategia degenerada en sentido estricto,
   sobre una interacción que el documento trata como ventana parable de primera clase.
   **Arreglo propuesto por `game-designer`**: constraint-handoff explícito —mismo patrón
   que `3 ≤ N ≤ 5` y R4— exigiendo que la `Acción Especial` completada imponga un coste
   suficiente para que ignorar la VE nunca domine estrictamente sobre pararla.
2. **RECOMENDADO — "el jugador que lee el patrón no paga nada" (Game Feel) es falso.**
   Siguiendo la tabla de prioridad de interrupción: si un `Golpe` real abre mientras el
   jugador está en los 9 ticks de Recuperación de whiff, no puede pararlo y **pierde
   Vida**. El coste temporal se convierte en **coste de recurso** exactamente en la fase
   de aprendizaje que `game-concept.md` prescribe. La salvedad existe, pero solo como nota
   al pie de la Regla 7; la versión sin matizar se repite en Weight and Responsiveness
   Profile, que es la sección donde un programador o un level-designer va a buscar "cuán
   punitivo es fallar".
3. **RECOMENDADO — "crispa y binaria" ya no describe el sistema.** Un solo botón tiene hoy
   **seis** resoluciones cualitativamente distintas, todas dependientes de estado
   invisible: parry contra `Golpe` (4/4 consecuencias) · parry contra VE (2/4) · whiff
   (lockout de 9 ticks) · Castigo no letal · Castigo letal · input reinterpretado como
   Parry en la ventana de gracia. No es petición de simplificar las reglas —hacen falta
   así— sino de que las afirmaciones sobre la sensación declaren su dominio de validez.

### Encargos de la fase 3 — corrección de estado

**Solo uno sigue sin cubrir**, no dos. El encargo de la **economía de riesgo de la Ventana
Especial** **sí se abordó**: es exactamente el hallazgo 1 de `game-designer` — se perdió en
la síntesis, no en la revisión. Lo que sigue abierto es la **fórmula de daño de golpe
enemigo**, que no existe en ningún GDD pese a que tres reglas normativas del sistema 2
razonan sobre ella — y que **no es independiente del hallazgo 1**: sin ella no se puede
cuantificar el coste de dejar que el jefe complete su habilidad, que es justo el número
del que depende que la VE deje de estar dominada.

### Efectos colaterales

- **`design/registry/entities.yaml` → v4**, sincronizado en la misma sesión (no diferido,
  precisamente porque desincronizarlo el mismo día es el modo de fallo que ya costó la
  reversión 113→114). `dano_golpe_castigo`: **regla de clamp de la Vida del jefe** ·
  `bono_vida_por_absorcion`: **2ª esquina fallida de R5** + el aviso de que a 9 ángeles
  hay que cambiar la **forma** de la fórmula, no la constante · `vida_base`: acoplamiento
  con R5 y **suelos efectivos derivados (110 / 82)** · `vida_maxima`: el hueco de alcance
  de R5 frente a `bono_reliquias`, marcado como **bloqueante abierto del changeset 2** ·
  `hitstop_parry`: divergencia cerrada — **el registry llevaba el rango correcto (3–6) y
  el desalineado era el GDD**, más la exposición del extremo corto documentada.
- `design/gdd/systems-index.md`: sistema 1 → **NEEDS REVISION**, cabecera y Progress
  Tracker actualizados.
- `production/session-state/active.md`: podado de 208 a **199 líneas** (bajo el umbral del
  hook). Corregido de paso el título, que decía "DÉCIMA" en vez de **NOVENA**.

**Criterio de éxito de esta pasada**: *"Sabremos que acertó si la 4ª no encuentra
ninguna recurrencia de A, B ni C — no si encuentra menos hallazgos."*

---

## Enmiendas forzadas — 2026-08-04 — Origen: `/design-review` del sistema 2 (3ª pasada)

**No fue una revisión de este documento**, y es importante que conste: es la fase 2 del
plan de 5 fases acordado tras la 3ª pasada del sistema 2, que decidió **aplicar primero
las enmiendas y revisar después**, para no someter este GDD a revisión adversarial
mientras un montón de enmiendas forzadas contra él esperaba en el log de otro documento.
Ver `maquina-estados-jefe-review-log.md`, entrada del 2026-08-04.

**Tres de las cinco raíces de aquella pasada viven total o parcialmente aquí** — R2 y R5
en Combate, R1 en ambos. Las 7 enmiendas de abajo son forzadas **con independencia de lo
que decida el sistema 2**.

**Efecto sobre el estado del documento**: la **aprobación queda retirada**. Este GDD
acumuló cuatro enmiendas post-aprobación sin ninguna revisión adversarial propia; la
siguiente fase es `/design-review --depth full` en sesión limpia con **`qa-lead`
obligatorio**, y será la primera que reciba desde que se aprobó.

### Las 7 enmiendas

| # | Enmienda | Raíz | Qué estaba roto |
|---|---|---|---|
| **A** | Término normativo **«ventana parable»** (`Golpe` ∪ Ventana Especial); Reglas 3 y 7 requantificadas | **R2** | Ambas reglas se cuantificaban literalmente sobre `Golpe`, así que un parry contra una Ventana Especial **no podía resolverse como éxito jamás** y siempre vencía "sin encontrar ningún `Golpe`" → whiff con 9 ticks de bloqueo. `interrumpible_por_parry = true` era indisparable y la Core Rule 5 del sistema 2 quedaba anulada entera |
| **B** | AC C15: `i < N` → **`1 ≤ i ≤ N`**, y verificación en `i=1` / intermedio / `i=N` | — | La Regla 9 dice "**cualquier** golpe del combo". El rango **y** la cláusula de verificación excluían el remate, por partida doble |
| **C** | `recuperacion_recepcion` promovido de prosa a **símbolo** con propietario, rango y regla de consumo | — | Existía en el registry desde el 2026-08-03 pero **no como símbolo en su propio GDD fuente** — solo prosa "8–12" en dos tablas. El AC C9 del sistema 2 dice consumirlo "por referencia, no duplicado": era inimplementable |
| **D** | Propiedad única del par **"duelo ganado" / "duelo perdido"** | — | Ambos GDDs se adjudicaban "duelo ganado" |
| **E** | **`restantes(T)` declarado por este GDD**, conteo inclusivo, borde **114** | **R5** | El sistema 2 definió normativamente un término que **no posee**, y con el conteo invertido |
| **F** | Los **2 ACs** que la enmienda de Ventana Especial nunca añadió (C20, C21) | R1 parcial | La excepción se escribió el 2026-08-03 con **cero criterios propios** — solo la acotación *negativa* de C4 |
| **G** | Regla 5 y AC E10 acotados al **Golpe de Castigo no letal**; **E11** nuevo | — | Se cuantificaban sobre *todo* castigo conectado, incluido el que mata al jefe, para el cual no hay salida de Aturdido, ni restauración, ni ciclo siguiente |

### La reversión 113 → 114, verificada por tercera vez

Con `ventana_castigo = 120` y conteo **inclusivo** `restantes(T) = 121 − T`, la zona de
gracia es `restantes(T) ≤ 6` ⟺ `T ∈ {115…120}` → **6 ticks exactos**, que es lo que la
Regla 5 declara. Con el conteo **exclusivo** que el sistema 2 introdujo (`120 − T`), sale
`T ∈ {114…120}` → **7 ticks**: el defecto exacto que aquella corrección decía prevenir.

Las **tres** formulaciones de este documento —la prosa de la Regla 5, la desambiguación
de input y el AC C11, que contiene ambas y las declara equivalentes— son consistentes
entre sí **solo** bajo conteo inclusivo. **Último tick de Castigo: 114. Primero de Parry:
115.** Se retira, por falsa, la acusación de "causa raíz señalada a Combate".

### ACs nuevos

**C19** (parry contra Ventana Especial sin `Golpe` → éxito, **no** whiff) · **C20** (las
2-de-4 consecuencias, verificadas una a una en positivo y en negativo) · **C21** (Ventana
Especial no parada → Vida numéricamente idéntica) · **E11** (castigo letal: sin
restauración, sin reanudación, sin nueva ventana parable).

Los cuatro se escribieron siguiendo la **regla operativa impuesta por la 3ª pasada**:
primero el AC desde el **cuantificador completo** de la regla, después la comprobación de
que el arreglo lo pasa. C19 es el caso testigo — es el AC que la formulación anterior de
las Reglas 3 y 7 **fallaba**, y que ningún AC existente detectaba porque **todos estaban
cuantificados sobre el mismo subconjunto que las reglas que verificaban**.

### Cláusulas hermanas editadas en el mismo changeset

Exigido por la misma regla operativa. **Enmienda A — cinco cláusulas hermanas**, no una:
fila de Recuperación de whiff en States and Transitions · fila de whiff en Edge Cases ·
reinterpretación de input de la Regla 5 ("no hay ningún `Golpe` activo que parar") · y
sobre todo el **AC E4**, que estaba cuantificado sobre `Golpe` y por tanto quedaba en
**contradicción directa con el C19 recién escrito**: con una Ventana Especial activa y
ningún `Golpe`, E4 afirmaba whiff y C19 exige éxito. Las cuatro decían "ningún Golpe" en
sitios distintos del documento. **Enmienda C**: States and Transitions y Animation Feel
Targets pasan a citar el símbolo. **Enmienda E**: la nota de desambiguación de input, que
expresa el mismo borde en su tercera formulación.

> La cuenta importa como dato de proceso: una regla mal cuantificada tenía **cinco**
> puntos de aparición, y el barrido de texto completo encontró dos de ellos *después* de
> que el changeset pareciera terminado. Escribir el AC desde el cuantificador completo
> detecta el defecto; solo un barrido léxico encuentra todas sus copias.

### Corregido en `design/registry/entities.yaml` (v2 → v3)

El registry **codificaba como normativa la convención invertida**: `ventana_castigo`
llevaba `restantes(T) = ventana_castigo − T` con borde 113, y `gracia_salida_castigo`
una nota titulada *"DEFECTO CONOCIDO, NO CORREGIDO"* que declaraba discrepante la prosa
de Combate y adjudicaba la razón a la regla importada — **exactamente al revés**.
Ambas revertidas. Añadidos: la fórmula `restantes` y el evento `duelo perdido`. Ampliadas:
`recuperacion_recepcion` (regla de consumo por techo) y `longitud_combo` (la segunda
mitad del contrato de `i`).

### Auditoría de la propia enmienda (misma sesión, a petición del usuario)

Se revisó la reversión del registry antes de continuar. **La aritmética resistió**
(`restantes(114) = 7 > 6` ✓, `restantes(115) = 6` ✗, zona exclusiva de 7 ticks ✓, banda
de contacto `T+6…T+14` ✓) y la acusación falsa se confirmó ausente del GDD de Combate:
vivía solo en el registry. Pero la auditoría encontró **cuatro defectos en la enmienda
misma**, uno de ellos sustantivo:

**El borde 114 se había escrito como literal en cinco sitios en vez de derivarse de los
knobs.** `ventana_castigo` tiene rango seguro 72–180 y `gracia_salida_castigo` 4–10: el
borde es `ventana_castigo − gracia_salida_castigo`, y se mueve con cualquier retune. Es
**el mismo defecto de literal-en-vez-de-knob que este registry ya corrigió dos veces**
(`postura_max`, `punish_dano_pct`). La nota original del 113 lo cometía y la enmienda lo
heredó sin verlo.

La corrección no se limitó a sustituir el número. Derivando `restantes(T) > g` se obtiene
`T ≤ ventana_castigo − g`, y de ahí una propiedad que no depende de ningún valor:

> **Bajo conteo inclusivo la zona de gracia mide exactamente `gracia_salida_castigo`
> ticks, para cualquier par de valores. Bajo conteo exclusivo mide `g + 1`.**

Ese tick de más **no era un error de cuenta puntual sino una propiedad del conteo
elegido** — que es exactamente por qué reaparecía cada vez que alguien recalculaba el
borde a mano, y por qué dos pasadas de revisión lo dejaron pasar. Escrita como invariante,
la clase entera de defecto queda cerrada. Es el mismo movimiento por propiedad que la 3ª
pasada aplicó a la Core Rule 9 y a la Regla 8.

Los otros tres eran menores: `revised:` de `ventana_castigo` sin actualizar, `output_range`
de `restantes` fijado a `[1, 120]` sin declarar que es config de lanzamiento, y sus notas
fijando «T=120 último» en vez de `T = ventana_castigo`. Los cuatro, corregidos.

> **Dato de proceso**: la enmienda que corrige un borde mal contado reprodujo, en el
> mismo changeset, un defecto documentado dos veces en el archivo que estaba editando. Lo
> encontró una auditoría pedida explícitamente **después** de darla por terminada —
> ninguna de las comprobaciones que la enmienda hizo sobre sí misma lo habría detectado,
> porque todas verificaban la **aritmética**, que era correcta, y ninguna la **forma**.

### Lo que este changeset NO cierra, y por qué

- **El 113 del AC E3b del sistema 2.** La regla operativa exige editar ambos lados de un
  contrato en el mismo changeset; aquí es **imposible** porque ese GDD está congelado.
  Anotado en tres sitios (Regla 5 de Combate, registry, aquí) para que la excepción no se
  pierda. Va en la 4ª pasada, raíz **R5**.
- **El hallazgo A4** (la banda de contacto del Castigo rebasa `ventana_castigo`). Es un
  borde **distinto** del de la pulsación; la enmienda E no lo toca. Sigue abierto.
- **`hitstop_parry` 3–8 en Impact Moments vs. R8, que lo recorta a 3–6.** Contradicción
  interna encontrada **en esta misma sesión**. No se cierra aquí por el criterio adoptado
  en la 3ª pasada — *ningún hallazgo se cierra en la sesión en que se encuentra*— y entra
  como ítem para el `/design-review`.

---

## Enmienda post-aprobación — 2026-08-03 — Origen: `/design-review` del sistema 2 (2ª pasada)

**No fue una revisión de este documento.** Las dos enmiendas siguientes se
originaron en la 2ª pasada de `/design-review` de
`design/gdd/maquina-estados-jefe.md`, donde 5 especialistas encontraron
contradicciones cruzadas entre ambos GDDs. Ver
`design/gdd/reviews/maquina-estados-jefe-review-log.md` para el análisis completo.

### Enmienda 1 — no semántica (cierra el bloqueante B5 del sistema 2)

**Problema**: este documento atribuía los eventos "inicio de Golpe" / "fin de Golpe"
al **sistema 20** en tres sitios, y —verificado por búsqueda de texto completo— **no
mencionaba al sistema 2 en ninguna parte**. Incumplía la regla de dependencias
bidireccionales de `.claude/rules/design-docs.md`. Causa: este GDD se aprobó el
2026-08-01, antes de que existiera el del sistema 2, y usaba "sistema 20" como
marcador de "el lado del jefe".

**Cambio**: reparto de tres partes explicitado — el **20** posee duraciones y
composición, el **2** es el emisor canónico de los eventos (sus límites de estado son
lo que los dispara), y este GDD es el consumidor. Tocados: Regla 1, Interactions
(bullet nuevo para el sistema 2 + acotación del bullet del 20) y Dependencies (fila
nueva).

**Riesgo**: ninguno. No cambia ninguna regla, fórmula, constante ni AC.

### Enmienda 2 — **semántica** (cierra el bloqueante B3 del sistema 2)

**Problema**: el sistema 2 declara un estado `Acción Especial` cuya interrupción por
parry no debe aplicar daño de Postura ni Repliegue. El **AC C4** de este documento
verifica que un parry exitoso aplica sus **cuatro** consecuencias en el mismo
fotograma, como paquete atómico, sin excepción declarada — y este GDD no tiene ningún
concepto de `Acción Especial` con el que distinguir un caso del otro. Las dos
especificaciones eran **mutuamente incumplibles**.

**Cambio**: nueva **excepción de Ventana Especial** en la Regla 4 — un parry exitoso
resuelto contra el par de eventos propio "inicio/fin de Ventana Especial" (declarado
por el sistema 2) aplica **solo 2 de las 4** consecuencias: Gracia ✓, hitstop ✓,
Postura ✗, Repliegue ✗. Corolario en la Regla 6: una Ventana Especial no parada **no
daña al jugador** (es ventana de oportunidad, no ataque). AC **C4** acotado a "parry
exitoso resuelto contra un Golpe".

**Decisiones de usuario que la fijaron** (2026-08-03): la Gracia se concede
**completa** (Pilar 1 — el triunfo también corrompe; y mantiene la excepción en 2 de
4 en vez de 3 de 4); y fallar la Ventana Especial **no daña**, porque el castigo es
que el jefe completa su habilidad, y que una curación fuese además un ataque sería
doble castigo por un solo error.

**Riesgo, declarado explícitamente**: esta enmienda **no ha pasado revisión
adversarial**. El clúster **Regla 4 / Regla 6 / AC C4** pasó dos pasadas de
`/design-review` en su forma anterior y esta modificación no ha pasado ninguna. El
Status del documento se degradó a *"Aprobado — con enmienda, pendiente de
re-verificación del clúster Regla 4 / C4"*.

`creative-director` había **recomendado la alternativa opuesta** (recortar el alcance
de `Acción Especial` para no tocar este documento); el usuario eligió especificar el
contrato completo, asumiendo esta enmienda como coste. Decisión registrada, no
discutida.

### Verificado y sin cambios en esta pasada

- El destino `Repliegue` del **aborto de combo** (Regla 4 excepción, Regla 9, Fórmula
  4, AC **D4**) es **correcto** y se mantiene. Fue el sistema 2 quien cedió: había
  generalizado la regla del golpe simple (→ `Enfriamiento`, AC **E8**) por encima de
  esta excepción declarada.
- El **AC C5** ("incluso a mitad de Golpe, interrumpiendo cualquier animación en
  curso") se mantiene sin cambios. La aparente contradicción con el sistema 2 era
  colisión de vocabulario (animación vs. estado FSM) y se resolvió con una cláusula
  en el documento del sistema 2, no aquí.
- **Defecto menor anotado, no corregido**: la prosa de la Regla 5 ("durante los
  últimos `gracia_salida_castigo` fotogramas") describe los ticks 115–120, mientras
  que su propia regla normativa de desambiguación de input (`restantes > 6`) sitúa el
  último tick legal de Castigo en el **113**. Discrepan en un tick. La regla
  normativa es la que manda; la prosa debería alinearse en una pasada futura.

---

## Review — 2026-08-01 — Verdict: NEEDS REVISION

Scope signal: XL (implementación) / L (reparación del documento)
Specialists: game-designer, systems-designer, qa-lead, ux-designer, audio-director,
performance-analyst, godot-specialist + síntesis senior de creative-director
Blocking items: 8 | Recommended: 6
Prior verdict resolved: First review

**Summary**: primera revisión formal del GDD fundacional. `creative-director`
identificó **dos clases raíz** que explicaban 15 síntomas dispersos: (1) *delegación
sin cota* — el documento cede a los sistemas 20/9/16 sin declarar el límite que su
propia especificación necesita, aplicando de forma inconsistente el buen patrón que
ya usaba con `multiplicador_ataque`; y (2) *knobs presentados como independientes que
no lo son* — la tabla de rangos seguros mentía por omisión, con varias combinaciones
de valores individualmente válidos produciendo resultados degenerados. La
arquitectura del sistema se juzgó **sólida**; los defectos, quirúrgicos y reparables
en una sesión. Los dos hallazgos más graves fueron aritméticos, no de criterio: la
cobertura temporal del parry (81–87%) hacía el mash imbatible por **cualquier**
cadencia enemiga —invalidando una adjudicación previa que lo delegaba al sistema 20—
y la restricción declarada en la Fórmula 6 era literalmente la desigualdad
equivocada, permitiendo que cualquier reliquia de daño rompiera el suelo de ciclos
mientras pasaba el chequeo escrito.

### Bloqueantes resueltos en la misma sesión

| # | Hallazgo | Fuente | Resolución |
|---|---|---|---|
| 1 | Cobertura temporal del parry 81–87% → machacar el botón es estrategia viable e imbatible por cadencia | `game-designer`, corregido por `creative-director` | **Decisión de usuario**: `recuperacion_whiff = 9` fotogramas, solo en whiff. Cobertura → 59%. Cadenas de combo intactas. Open Question del sistema 20 cerrada como invalidada |
| 2 | `punish_dano_pct × multiplicador_ataque < 100` es la desigualdad equivocada; la real reduce a `mult ≤ 1.0` | `systems-designer` | **Decisión de usuario**: suelo de ciclos absoluto, techo duro `multiplicador_ataque ≤ 1.0` (R4). Restricción traspasada formalmente al sistema 9 |
| 3 | Rangos "seguros" por knob, inseguros en combinación (4 hallazgos, un solo defecto) | `systems-designer` | Bloque normativo **R1–R5** de restricciones conjuntas + aviso de que R5 solo está calibrada para 3 ángeles |
| 4 | F2/F3 hardcodean literales en vez de sus propios knobs | `systems-designer` | Reescritas con símbolos + nota de implementación data-driven |
| 5 | `time_scale` global congelaría el HUD, contradiciendo el requisito de 1–2 fotogramas sin ease-in en el evento 8 | `performance-analyst` (BLOQ.) vs `godot-specialist` (ADV.) | Adjudicado a favor de `performance-analyst`. 3 reglas normativas de autoridad del tiempo en Regla 2 |
| 6 | Borde de salida del Aturdimiento indefinido → golpe inevitable por error de borde | `qa-lead` + `ux-designer`, reformulado por `creative-director` | **Decisión de usuario**: `gracia_salida_castigo = 6` fotogramas + orden normativo de desambiguación de **input** (la tabla de prioridad solo resolvía **estados**) |
| 7 | P1 no reproducible a demanda → no es una puerta | `qa-lead` + `performance-analyst` | Reescrito con trigger de depuración determinista, 3–5 repeticiones, dock **y** batería/40Hz. Nuevo **P0** (coste de draw calls por emisor) como prerrequisito de validez |
| 8 | Referencia colgante: la sección de partículas remitía a una fila de Open Questions inexistente | Verificado en la sesión de revisión (ningún especialista lo vio) | Fila creada con propietario `technical-artist` + AC **V1** para el bug de dirección semántica de emisores |

### ACs añadidos

C10 (recuperación de whiff), C11 (borde de gracia), C12 (cobertura de mash ≤ 65%),
D8 (techo de multiplicador), D9 (test parametrizado de R1–R5), P0, V1 (dirección
semántica de partículas), V2 (el whiff no debe leerse como lag). Etiquetados
`(instrumentado)`: C2, C4, D4, E1, E4.

### Discrepancias registradas (no silenciadas)

- **`performance-analyst` vs `godot-specialist`** — mismo hallazgo de `time_scale`,
  severidades distintas. Adjudicado a BLOQUEANTE: rompe un requisito ya escrito, y
  un GDD de capa Fundación debe ser implementable sin adivinar.
- **`creative-director` vs `game-designer` #3** — RECHAZADO como bloqueante: es
  re-litigio de una Open Question ya co-adjudicada (coste in-combat de absorber).
- **`creative-director` vs `game-designer` #2** — parcialmente rechazado: es falso
  que la corrupción carezca de presencia mecánica en este GDD; **la Fórmula 7 la
  tiene** (combos ricos en gracia y pobres en Postura → los ángeles rápidos corrompen
  más por punto de progreso). Se aplicó solo el arreglo de higiene: declarar la
  frontera de propiedad de la fantasía en Player Fantasy.
- **`creative-director` vs `ux-designer` #1** — sobre si +1–2 fotogramas de hitstop
  son perceptibles (+20–40% sobre 4.8 fotogramas vs. JND típico del 10–15%).
  **No resoluble en papel**: queda registrado como gap de testabilidad 7, con la
  causa raíz prediagnosticada por si falla el Feel AC de Parry Justo en el primer
  playtest.
- **`audio-director` #4** — degradado a Recomendado: la columna de prioridad plana
  (11 de 13 en "Alta") es síntoma de una Open Question ya abierta del sistema 16.

### Recomendados no aplicados (siguen abiertos)

Feedback de fallo graduado —con la restricción de `creative-director` de resolverlo
**sin luz**, por la regla de oro del art bible—; separación de rango de frecuencia
entre fallo/whiff/combo-roto; colisión armónica de Parry Justo sobre cierre de combo;
convergencia de F7 en su techo de tuning.

### Efectos colaterales

- `design/registry/entities.yaml` actualizado: 3 constantes nuevas, 4 fórmulas
  corregidas, y saneada una contradicción **preexistente** (las notas de
  `bono_vida_por_absorcion` decían ">25" contra el rango canónico 15–20 del GDD).
- `production/session-state/active.md` actualizado con decisiones y discrepancias.

**Estado al cierre**: 8/8 bloqueantes aplicados. Pendiente re-review de confirmación
en sesión limpia — las decisiones 1, 2 y 6 **cambian el diseño** y no han pasado aún
por una lectura adversarial.

---

## Review — 2026-08-01 (2ª pasada) — Verdict: NEEDS REVISION → resuelto en sesión

Scope signal: L (reparación del documento) / XL (implementación)
Specialists: game-designer, systems-designer, qa-lead, godot-specialist, ux-designer,
audio-director, performance-analyst + síntesis senior de creative-director
Blocking items: 10 clústeres (≈24 hallazgos subyacentes) | Recomendados: 10
Prior verdict resolved: **Sí** — los 8 bloqueantes de la 1ª pasada se verificaron
aplicados. Ninguno reapareció.

**Summary**: re-review de confirmación de las tres decisiones que cambiaron el diseño.
`creative-director` identificó **tres clases raíz, y dos son recurrencias producidas
por la reparación anterior**: (A) *"se escribió la norma, no la prueba"* — cinco
bloqueantes de la 1ª pasada se cerraron con prosa normativa sin ningún gancho de
verificación, que es el patrón exacto que este GDD critica en otros sitios; (B) *"el
coste nuevo se evaluó en un solo bucle"* — `recuperacion_whiff` se derivó de un único
modelo aritmético y seis departamentos encontraron el mismo agujero desde su lado, lo
que es **la reaparición literal de la clase raíz #2 de la 1ª pasada aplicada al knob
que introdujo el arreglo de esa misma clase**; (C) *"coincidencias estructurales
tratadas como accidentales"* — cuatro recursos compartidos se disputan en instantes
que el diseño garantiza que coincidan, y el patrón de prerrequisito se aplicó a
exactamente uno de los cuatro.

> **Veredicto de `creative-director` sobre la arquitectura**: *"lo que no sobrevivió a
> la segunda pasada no es la arquitectura: es la reparación."* Nadie atacó en dos
> pasadas adversariales el bucle central, la fantasía, la frontera de propiedad con
> Gracia, el modelo de dependencias duras/blandas ni la clasificación de capa. El
> juicio de la 1ª pasada — "arquitectura sólida, defectos quirúrgicos" — se confirma.

### Bloqueantes resueltos en la misma sesión

| # | Hallazgo | Fuente | Resolución |
|---|---|---|---|
| 1 | La Regla 2.2 (el HUD exento de `time_scale`) es **inconstruible en Godot 4.7**: no existe exención por subárbol, `process_mode` gobierna la pausa. + hitstop de 4.8 ticks no enteros + tick rate no declarado + **cero ACs** para las tres reglas de tiempo | `godot-specialist` (revirtiendo parcialmente la adjudicación de la 1ª pasada) + `qa-lead` | Regla 2 reescrita a **cuatro** reglas que especifican el *efecto*, no la API. El documento ya no nombra `Engine.time_scale`. Hitstop → **5 ticks**. `physics_ticks_per_second = 60` invariante. Regla normativa de lectura de input. ACs **C13/C14** |
| 2 | **P0 contrastaba contra el presupuesto equivocado por ~30×**: `<1000` cuando el art bible 8.6 fija el pico de combate en 40–80 con el desglose repartido (~20 reales para VFX). Sin condición de fallo. P99 global diluye el estrés localizado | `performance-analyst` (**autocorrigiéndose**) + `qa-lead` | P0 con condición de fallo explícita (>~20 draw calls → invalida P1). P1 gana 2ª métrica obligatoria: P99 sobre ventanas de ±5 frames |
| 3 | Falta invariante de cobertura: **18 de 70 combinaciones (25.7%)** violan el objetivo <65% con ambos knobs en rango "seguro". Cobertura intra-combo del 84% sin medir. Reliquias podían reabrir el mash vía modificadores de ventana | `systems-designer` + `game-designer` | Invariante **R6** con la tabla del barrido completo. Restricción de valores *efectivos* al sistema 9 + AC **D10**. Varianza intra-combo traspasada al sistema 20 + AC **C12b** |
| 4 | **La Fórmula 7 rompía la garantía de la Regla 9 con el valor shippeado**: `mod=0.5`, N=2 → `1.0`, igual que un golpe simple. Con `mod=0.3` → 0.6, menos por más riesgo. `N_min` sin declarar | `systems-designer` | **Decisión de usuario: `N_min = 3`** + invariante **R7** (`mod > 1/N_min`). Rango del knob elevado a 0.35–0.8 |
| 5 | **R4 sin suelo**: `mult → 0` hace el duelo inganable siendo el Golpe de Castigo la única fuente de daño | `systems-designer` | **Decisión de usuario: `multiplicador_ataque` pasa a constante 1.0**, cerrada en ambos sentidos. Se cierra el arquetipo de reliquia maldita de daño |
| 6 | R2 mezclaba unidades: evaluaba en segundos cuando el runtime son ticks redondeados hacia abajo. `floor(0.24×60)=14 ticks` ya falla | `systems-designer` | R2 se evalúa **en ticks**. Límite real 0.25s (15 ticks), región insegura **66.7%** del rango, no 60% |
| 7 | **Regla núcleo ausente**: nada declaraba qué pasa con la Postura tras un Golpe de Castigo **exitoso** — todo el conteo 12/20/30 lo asumía | `systems-designer` (promovido de Recomendado por `creative-director`) | Regla añadida en Regla 5 + fila de Edge Cases + AC **E10** |
| 8 | La Recuperación de whiff no existía en ninguna tabla de feedback ni en el contrato de Accesibilidad. El input descartado es silencioso — lo que el AC V2 prohíbe percibir | `ux-designer` + `audio-director` | Evento **6b** con la distinción "reacción del mundo" vs. "cola del gesto" + nota de producción. `recuperacion_whiff` expuesto a Accesibilidad **como par con `parry_window`** |
| 9 | C12 no ejecutable: la fórmula de cobertura no tiene término de ángel, pero el AC la ataba a un ángel del sistema 20 inexistente — test unitario disfrazado de integración | `qa-lead` | Separado en **C12a** (unitario, ejecutable hoy) y **C12b** (integración, marcado como bloqueado) |
| 10 | **La colisión armónica evento 4 × evento 8 es estructural**: la Fórmula 1 calcula el Parry Justo sobre el último parry del combo, así que ambos coinciden **siempre** en el pico de ejecución | `audio-director` | **Regla de precedencia armónica** normativa (el Parry Justo se subordina como variante tímbrica) + AC **V4** + prerrequisito **P5** (equivalente de audio a P0) |

### Decisiones de usuario

`multiplicador_ataque` = **constante 1.0** · **`N_min = 3`** con invariante R7 ·
**rechazo confirmado** del perdón simétrico del whiff (+ aborto de combo hecho
explícito) · **`3 ≤ N ≤ 5`** fijado en este GDD, cerrando una Open Question que
bloqueaba la autoría del sistema 16 (MVP).

### Discrepancias registradas (no silenciadas)

- **`godot-specialist` vs. la adjudicación de `creative-director` en la 1ª pasada** —
  **reversión parcial**: la adjudicación fue *correcta en el qué* (el HUD no puede
  congelarse) pero produjo un *cómo imposible*. El fallo fue dejar que el documento
  siguiera nombrando `Engine.time_scale` mientras exigía una exención que el motor no
  ofrece. Un GDD de capa Fundación no puede publicar una regla inconstruible.
- **`audio-director` acusa de doble estándar visual/audio** — **parcialmente
  aceptado**. Su BLOQ3 (prioridad plana) sigue en Recomendado, ahora con la razón
  explícita que se le debía: partículas tienen un techo declarado en el art bible que
  este GDD ya gasta; audio **no tiene techo en ningún documento** — no se puede
  arbitrar contra un presupuesto inexistente. Pero su BLOQ2 y REC5 **sí prueban la
  asimetría** y se aplicaron íntegros.
- **`game-designer` vs. la Decisión 1 del usuario** — **efecto secundario legítimo, no
  re-litigio; remedio rechazado**. Su premisa fáctica en BLOQ1 era incorrecta (la
  Regla 9 sí especifica que el combo se interrumpe). El perdón simétrico se rechaza
  porque anularía el lockout justo cuando importa. Su BLOQ3 (cobertura intra-combo)
  se sostiene entero y es bloqueante.
- **`ux-designer` vs. `creative-director` sobre la perceptibilidad del hitstop** —
  **cerrada hasta el primer playtest**. Sin evidencia nueva; el gap de testabilidad 7
  ya registra ambas posiciones. Reabrirla en papel una tercera vez es ruido por
  inercia.
- **Rechazado como precisión falsa**: `systems-designer` REC6 ("~35–40 debería ser 40
  exacto") — el rango es cobertura honesta mientras la mezcla de combos por ángel no
  exista. Convertirlo en entero haría el documento *menos* verdadero.

### Verificación de alcance reducido (misma sesión)

Ejecutada con 3 especialistas sobre el documento reparado, según recomendó
`creative-director` para evitar hallazgos marginales por inercia.

**Los 10 clústeres se confirman cerrados**, con verificación aritmética explícita: la
tabla de R6 es exacta (18/70), el umbral `≤ 1.857 × recuperacion_whiff` bien derivado,
R2 correcta, D9 suma 92 casos y cubre R1–R7, las conversiones a ticks exactas.
`godot-specialist`: *"el bloqueante original queda cerrado"* — certeza alta.

**11 residuos encontrados y aplicados.** El más sustantivo fue **una instancia nueva
de la Clase B introducida por la propia reparación**: `hitstop_parry`, el knob añadido
para canonicalizar el hitstop, declaraba 8 ticks como su punto de ruptura mientras
Impact Moments le suma +1–2 de Parry Justo sin tope. Corregido con la invariante **R8**
y el rango recortado a 3–6. El resto: 3 referencias obsoletas a R4 unilateral · el
umbral de R7 era 0.3333, no 0.34 · **C16** (validación del rango de N al cargar) ·
**C17** (extiende C10 a la recuperación de Castigo + cubre el "cero feedback por
pulsación descartada") · **C18** (input con render/física desacoplados) · D10 marcado
como bloqueado igual que C12b · C15 verificable en ambos bordes de N · tolerancia de
C13 por perfil · C14 etiquetado `(instrumentado)` · y la heterogeneidad del enfoque de
autoload documentada (`Tween`/`AnimationPlayer`/`GPUParticles2D` usan `speed_scale`
por nodo, `Timer` no tiene hook, el `TIME` de shader no respeta ninguno).

### Métricas

**ACs: 31 → 49.** Invariantes: **R1–R5 → R1–R8.** Nuevos: C12a/C12b, C13–C18, D10,
E10, P4, P5, V3, V4. Etiquetados `(instrumentado)`: C13, C14, C18.

### Recomendados aplicados

D9 con espacio de casos enumerado (92 casos) · P4 térmico + rango de intención de
duración de duelo (2–4 min) · onboarding como Open Question con restricción al
tutorial · analógico/digital reclasificado de "terminología" a decisión de diseño con
propietario · croma vs. luminancia en UI · numeración D7 reordenada · firmantes de
V1–V4 nominados · "esquivar" eliminado (verbo fantasma: aparecía una sola vez y el
juego no tiene esquiva) y Feel AC #1 reescrito con componente observacional ·
`retreat_base`/`ventana_castigo`/`hitstop_parry` canonicalizados en ticks · convención
global "fotograma = tick" · truncamiento de emisores y colapso de frames a 40Hz como
Open Questions.

### Recomendados no aplicados (siguen abiertos)

Feedback de fallo graduado sin luz · colisión armónica de Parry Justo **resuelta** vía
la regla de precedencia · convergencia de F7 en su techo · F7 experiencialmente
invisible en UI (propiedad de los sistemas 5 y 13) · prioridad plana de audio (11 de 14
en "Alta", sigue en Recomendado por falta de presupuesto contra el que arbitrar).
**Cerrado por su propio autor**: `audio-director` retiró el ítem de separación de
frecuencia fallo/whiff/combo-roto por considerarlo ya adecuado al nivel de un GDD.

### Efectos colaterales

- `design/registry/entities.yaml`: 3 constantes nuevas (`hitstop_parry`,
  `physics_ticks_per_second`, `longitud_combo`), 4 revisadas (`multiplicador_ataque`,
  `parry_window`, `retreat_base`, `ventana_castigo`, `recuperacion_whiff`), 3 fórmulas
  actualizadas (`gracia_ganada` con R7, `dano_golpe_castigo` con R4 bilateral).
- `design/gdd/systems-index.md`: sistema 1 → **Approved**.

**Estado al cierre**: 10/10 clústeres aplicados y **verificados por lectura adversarial
independiente**. Los 11 residuos de esa verificación también aplicados. Ningún
bloqueante abierto. **Aprobado.**

### Lección de proceso registrada

Las dos pasadas produjeron el mismo patrón: **reparar N bloqueantes en la misma sesión
en que se descubren produce prosa normativa sin ganchos de verificación** (Clase A) y
**arreglos evaluados en un solo bucle** (Clase B). La 2ª pasada lo repitió en pequeño —
`hitstop_parry` reintrodujo la Clase B — y solo lo detectó porque la verificación de
alcance reducido se ejecutó de verdad en vez de darse por buena. Para el próximo GDD:
escribir los ACs **antes** que la prosa normativa, y barrer cada knob nuevo contra el
bloque de restricciones conjuntas en el momento de añadirlo, no en la revisión
siguiente.

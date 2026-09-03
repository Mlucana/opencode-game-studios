# Review Log — Máquina de Estados de Jefe (sistema 2)

Historial de revisiones de `design/gdd/maquina-estados-jefe.md`.
Una entrada por pasada de `/design-review`.

---

## Review — 2026-08-04 (3ª pasada) — Verdict: **MAJOR REVISION NEEDED** — sistema 2 **CONGELADO**

**Scope signal**: **XL** (subió desde L: 5 raíces, 3 de ellas en un GDD ajeno; una exige
un ADR antes de poder cerrarse; enmiendas 3ª y 4ª a un documento Aprobado)
**Modo**: full — **4 especialistas de 5**
**Especialistas**: `game-designer`, `systems-designer`, `ai-programmer`,
`godot-specialist` + `creative-director` (veredicto senior)
**⚠️ `qa-lead` NO ENTREGÓ** — cortado por límite de sesión. La cobertura de
testabilidad de ACs de esta pasada está **incompleta**, y es el ángulo que el
hallazgo de proceso señala como crítico. Ningún resultado de esta pasada sobre
testabilidad debe considerarse concluyente.
**Bloqueantes reales (Tier A)**: 6 | **Tier B**: 9 | **Tier C (deuda documental)**: 7
**Prior verdict resolved**: **No.** El criterio de éxito declarado por la 2ª pasada
—"cero defectos originados en los arreglos de ésta"— **no se cumple**: los cuatro
especialistas reportaron entre 10 y 13 descendientes cada uno.
**Completeness**: 8/8 secciones

### El reencuadre que cambia la decisión: no son 13 defectos, son 5 raíces

Los especialistas contaron síntomas. `creative-director` los reagrupó por causa:

| Raíz | Qué está roto de verdad | Dónde vive |
|---|---|---|
| **R1** | El contrato de eventos de `En Combo` no existe — nadie declara qué emite un combo ni si sus golpes internos son distinguibles | **Ambos** |
| **R2** | Combate no reconoce la Ventana Especial en sus **propios predicados** (Reglas 3 y 7, cuantificadas solo sobre `Golpe`) | **Combate** |
| **R3** | El modelo de despacho es insatisfacible y no tiene base temporal declarada | Sistema 2 + ADR |
| **R4** | La Core Rule 9 es una propiedad escrita como lista: variable libre sin cota, validada sobre el objeto equivocado, enumeración falsa | Sistema 2 |
| **R5** | El borde **exterior** de la ventana de Castigo no está definido | **Ambos** |

**Tres de las cinco raíces viven total o parcialmente en Combate.** Ésa es la razón
de fondo del veredicto y del plan: seguir iterando el sistema 2 es iterar sobre el
síntoma.

### Bloqueantes Tier A — impiden escribir código correcto

| # | Hallazgo | Fuente |
|---|---|---|
| A1 | **`En Combo` plano vs. jerárquico.** La tabla y C3c describen una máquina plana; la nota de contenedor y C8 una jerárquica. Bajo la lectura jerárquica estricta no se emite evento de ventana para los golpes 2..N → el jugador para al aire, todo se resuelve como whiff, **el combo entero conecta** | `ai-programmer` |
| A2 | **El contrato no distingue `Golpe` intra-combo de simple.** El razonamiento que separó la Ventana Especial se aplica idéntico a `En Combo` y no se aplicó → Combate dispara `Repliegue` entre golpes; su **D4** y su **Fórmula 4** fallan y el combo se descompone en golpes simples | `ai-programmer` |
| A3 | **Reglas 3 y 7 de Combate siguen cuantificadas solo sobre `Golpe`.** La Enmienda 2 tocó las tres cláusulas donde el conflicto *se veía* y ninguna de las dos donde *reside*. Literal: `interrumpible_por_parry = true` **no puede dispararse nunca**, y todo intento contra la Ventana Especial es **whiff** (9 ticks de bloqueo). Anula C5a, C5c, E1 y la Core Rule 5 entera | `systems-designer` |
| A4 | **La banda de contacto del Castigo rebasa `ventana_castigo`.** Una pulsación legal produce contacto en 121–127, con el jefe ya fuera de `Aturdido` **sin colchón**: el golpe no hace nada y no avisa (E5 es aserción blanda) mientras el jugador queda 10–14 ticks comprometido. Es lo que la Regla 5 de Combate prohíbe textualmente | 3 de 4 especialistas |
| A5 | **Regla 8 + cláusula de reentrada: no existe implementación legal.** La propiedad se ancla a "la resolución de Combate", pero 5–6 salidas son por vencimiento de duración y todos los temporizadores están prohibidos. Y por el perdón de anticipación —que **B8 declaró el caso normal**— resolver viola la reentrada y diferir viola la Regla 8. **B4 y B8, escritos en la misma sesión, son mutuamente insatisfacibles** | `ai-programmer`, `godot-specialist` |
| A6 | **Base temporal de los contadores sin declarar.** Combate dice que un contador entero es inmune al hitstop *y* que el ángel avanza al 4%. Los primeros 5–7 ticks de **toda** `ventana_castigo` transcurren bajo hitstop → la aritmética de bordes de la 2ª pasada está sin anclar. Arreglo: una frase declarativa | `ai-programmer`, `godot-specialist` |

### Tier B — anulan una garantía declarada

`margen_reaccion_min` sin suelo (invariante auto-satisfacible: el sistema 20 fija a la
vez el margen y lo que debe cumplirlo; C9 pasa en verde con 0) · la invariante de la
Core Rule 9 se asevera sobre el objeto equivocado (el par peligroso es
`Enfriamiento(A) + Telegrafiado(B)`, patrones **distintos**; C9 valida un patrón
aislado) · la enumeración de "caminos ya cubiertos" es falsa (falta la salida de
`Aturdido` por expiración, donde la **propia regla de gracia de Combate induce** un
input que produce whiff) · **la cifra 113 está invertida** (ver D1) ·
`recuperacion_recepcion` **no existe como símbolo en Combate**, pese a que C9 dice
consumirlo "por referencia, no duplicado" · **C3c verifica por inspección de estado
final** — la formulación que B7 declaró bloqueante en C4a/E2, reintroducida en el
camino más frecuente del juego · derrota del jugador simultánea al aborto de combo
(C3b y "no emite ninguna señal" son incumplibles a la vez, y no hay canal declarado) ·
**el AC C15 de Combate conserva `i < N`** · "la señal no diferida es conforme" es una
exención por categoría (la conformidad depende del call stack del **emisor**;
`Area2D.body_entered` la pasa y no cumple la propiedad — y este GDD se adjudica "el
instante de contacto" sin declarar cómo se detecta) · `Acción Especial` sin predecesor
declarado, cerrado activamente por C1b · `Enfriamiento` de duración indefinida tras
interrupción · **`fin de Golpe` al truncar por perdón de anticipación** sin
especificar: si se emite, Combate puede dañar al jugador por un parry **acertado**
(verificar en la 4ª pasada; si se confirma, sube a Tier A).

### Desacuerdos entre especialistas y su adjudicación

1. **D1 — ¿113 o 114? Es 114. La corrección de la 2ª pasada estaba invertida.**
   `systems-designer` lo detectó; `creative-director` lo verificó de forma
   independiente. Bajo el conteo **exclusivo** que el sistema 2 inventó
   (`restantes(T) = 120 − T`), la zona de gracia mide **7 ticks** — que es
   exactamente el defecto que la nota de corrección decía estar previniendo. Las tres
   formulaciones de Combate (Regla 5 "los últimos 6", desambiguación de input ">6",
   AC **C11** que contiene ambas y las declara equivalentes) **son consistentes entre
   sí bajo conteo inclusivo**. Acciones: E3b vuelve a **114** (verificable en ambos
   bordes: 114 → Castigo, 115 → Parry); **se retira la acusación de "causa raíz
   señalada a Combate"**, que es falsa y quedó escrita en un GDD ajeno; y —el defecto
   de fondo— el sistema 2 **definió normativamente un término que no posee**:
   `restantes(T)` debe declararse en Combate y consumirse aquí. E3 (pulsación en 110)
   no se ve afectado.

2. **D2 — El destino del aborto de combo no cambia; cambian las razones. Ahora 4–0.**
   `game-designer` demostró que las tres razones caen —y la razón 2 está **refutada
   por la Core Rule 9, escrita dos párrafos más abajo en la misma sesión**—, pero el
   destino nunca fue una decisión de este GDD. Se sustituyen las tres por la única
   verdadera: *"Combate lo manda en cuatro sitios; este GDD no lo decide."* El
   `Repliegue` proporcional `retreat_base × (i−1)/N` se **rechaza**: en `i = 1` da 0
   ticks y reabre, en su caso más frecuente, el agujero de justicia que la Core Rule 9
   cierra en el camino simple; además contradice el AC D4 de Combate. La pregunta
   temática de `ai-programmer` (`Repliegue` es en el resto de Combate la ventana que
   *premia*) se reabre como Open Question **dirigida a Combate**.

3. **D3 — El colchón de 42 ticks no se elimina, pero la Core Rule 9 lo absorbe.**
   Se rechaza el remedio de `game-designer` (sustituirlo por un piso sobre
   `Telegrafiado`): obligaría al jefe a acusar el golpe **durante el telegrafiado**,
   ensuciando la lectura más importante del juego. Se acepta el diagnóstico —dos
   mecanismos incompatibles para el mismo problema— con esta resolución:
   **la Core Rule 9 pasa a ser la propiedad general y el colchón de la Core Rule 4 una
   *instancia* que la satisface**:
   > Para **toda** transición hacia un estado que pueda producir una ventana de `Golpe`
   > activa: `ticks_hasta_ventana_activa ≥ compromiso_restante_del_jugador + margen_reaccion_min`
   > (Recepción 12, Castigo 14, whiff 9, parry exitoso 3, libre 0)

   Efectos: da a `margen_reaccion_min` una **cota superior de 28** derivada de una
   constante existente (42 ≥ 14 + margen), que junto al suelo cierra la variable libre
   por ambos lados; cubre sin enumerarlos los caminos de expiración de `Aturdido` y de
   `Enfriamiento` tras interrupción; y `retreat_base` recupera un solo significado.
   Es el mismo movimiento por propiedad que `godot-specialist` impuso a la Regla 8.

4. **D4 — Sí a congelar el sistema 2; no a revisar Combate *todavía*.** Revisarlo hoy
   repetiría el error de esta pasada: someter un documento a revisión adversarial
   mientras un montón de enmiendas forzadas a ese mismo documento espera en el log de
   otro. Primero se aplican las enmiendas, después se revisa. Ver plan.

### El hallazgo de proceso

> **Cada arreglo se escribió contra el caso denunciado, y cada AC se escribió contra
> el arreglo. Un AC calibrado al arreglo certifica el ejemplo, nunca la regla.**

| Regla | Cuantificador real | Qué verifica su AC |
|---|---|---|
| Core Rule 4 ("la Postura **solo** cambia en…") | 9 estados | C4d enumera **5** — justo los que hacen cierta la frase |
| Core Rule 9 | todos los pares de patrones | C9 valida **un patrón aislado**, con la variable que el propio validado suministra |
| E3 (borde de Castigo) | la banda de contacto completa | **el tick 120** |
| Contrato de eventos propios | `Acción Especial` **y** `En Combo` | solo `Acción Especial` |
| Verificación por señales | C4a, E2 **y** C3c | C4a y E2 |
| `1 ≤ i ≤ N` | sistema 2 **y** C15 de Combate | solo sistema 2 |
| C15 de Combate | "cualquier golpe" | "`i` intermedio y **penúltimo**" — excluye el remate, que era el punto |

Los "descendientes" son la consecuencia mecánica: si parcheas la frase denunciada,
nunca miras la extensión completa de la regla, así que nunca ves la cláusula hermana
que acabas de contradecir. Por eso la Core Rule 9 refuta a la Core Rule 3 dos párrafos
más abajo sin que nadie lo notara: **nadie leyó la regla, solo la frase.**

Corolario a escala documental: cuatro de los peores hallazgos (A3, C15, "duelo
ganado", `recuperacion_recepcion`) son casos en que el sistema 2 arregló **su lado**
de un contrato de dos lados y dejó el otro intacto. Misma enfermedad, con documentos
en vez de frases.

**Regla operativa impuesta para adelante:**
> Al arreglar una regla, escribe primero el AC **desde el cuantificador completo de la
> regla**, y solo después comprueba si el arreglo lo pasa. Nunca al revés. Si la regla
> tocada tiene una cláusula hermana en la misma sección o una cláusula espejo en otro
> GDD, ambas se editan en el mismo changeset o el arreglo no está completo.

**Se retira el criterio de éxito de la 2ª pasada.** "Cero defectos originados en los
arreglos" premia cerrar ítems, que es justo lo que produjo estos defectos. El criterio
de la 4ª pasada es otro: **ningún hallazgo se cierra en la sesión en que se
encuentra**, y cada arreglo declara por escrito la extensión de la regla que toca.

*(Ironía anotada por `creative-director`: el hallazgo de proceso de esta pasada es un
hallazgo sobre ACs, y el especialista de ACs es el que no entregó.)*

### Sobrealcance rechazado

Diseñar un "contexto de ataque" general en el payload (basta un flag intra-combo + el
índice) · formalizar el grafo de sucesión de patrones (con 3 jefes basta la validación
por pares en carga) · rediseñar la autoridad temporal completa aquí (es del ADR) ·
reequilibrar la economía de combos (bloqueado por la fórmula de daño de golpe enemigo,
que **no existe en ningún GDD**) · ampliar los ejes de `interrumpible_por_parry`
(rechazado por tercera vez) · acotar la tasa de curación aquí (es del sistema 20) ·
bloquear el GDD hasta que exista referencia pinneada de core/SceneTree (es
prerrequisito del **ADR**; se anota, no bloquea).

### Lo verificado y limpio

**La topología sigue siendo correcta.** Ninguno de los hallazgos exige rediseñar la
máquina de estados: los nueve estados, las bifurcaciones y la convención "resolución =
límite de estado" se sostienen tras **tres** lecturas adversariales. Lo que está roto
es el **contrato con Combate, en los dos sentidos**. También se sostienen: el
procedimiento de enmienda de la Regla 7 y la vía declarada para Lucifer; el payload
`i`/`N` como decisión de diseño; la congelación ante derrota del jugador como espejo
del AC E7 (aunque su *implementación* tenga los defectos A5/B13); y la conclusión de
que ningún cambio de Godot 4.4→4.7 afecta al documento — con la matización de
`godot-specialist` de que hoy es un **negativo no verificado**, por el hueco de
engine-reference.

### Plan acordado con el usuario — 5 fases, en este orden

1. **Congelar el sistema 2.** Sin ediciones hasta que Combate cierre.
2. **Aplicar a Combate las enmiendas forzadas** (sesión propia, sin revisión). Son
   forzadas con independencia de lo que decida el sistema 2: Reglas 3 y 7 + ACs C3 y
   C10 (R2) · `i < N` → `1 ≤ i ≤ N` en C15 · `recuperacion_recepcion` promovido a
   símbolo con propietario y rango seguro · propiedad única de "duelo ganado" ·
   `restantes(T)` declarado en Combate · los ACs que la Enmienda 2 nunca añadió ·
   acotación de la Regla 5 y el AC E10 para el Castigo letal.
3. **`/design-review design/gdd/combate-parry-absorcion.md --depth full`**, sesión
   limpia, **`qa-lead` obligatorio**, con dos encargos explícitos: la fórmula de daño
   de golpe enemigo ausente, y la economía de riesgo de la Ventana Especial / "comerse
   el primer golpe del combo". Es la primera revisión adversarial que Combate tiene
   desde que se aprobó.
4. **Sistema 2, 4ª pasada**, por raíces en este orden: **R1 → R3 → R4 → R5**. R3 puede
   exigir que el ADR se escriba antes de que el GDD pueda cerrar.
5. **Re-review del sistema 2 en sesión separada de los arreglos.** Innegociable.

**Criterio de éxito de la 4ª pasada**: que la revisión de Combate encuentre la mayoría
de R1, R2 y R5 en su propio terreno; que la 4ª pasada del sistema 2 cierre con menos
de 4 bloqueantes; y que **ninguno** sea descendiente de un arreglo de la 3ª.
Y que `qa-lead` se ejecute **primero, no último**, con el encargo: *"para cada AC, di
sobre qué subconjunto del cuantificador de su regla se pronuncia, y sobre cuál calla."*

---

## Review — 2026-08-03 (2ª pasada) — Verdict: NEEDS REVISION (resuelto en la misma sesión)

**Scope signal**: L (subió desde M: requiere enmendar un GDD Aprobado e impone una
invariante nueva al sistema 20)
**Modo**: full (5 especialistas en paralelo + síntesis de `creative-director`)
**Especialistas**: `game-designer`, `systems-designer`, `qa-lead`, `ai-programmer`,
`godot-specialist` + `creative-director` (veredicto senior)
**Bloqueantes**: 9 | **Recomendados**: 5 | **Sobrealcance rechazado**: 5
**Prior verdict resolved**: **Sí** — los 14 arreglos de la 1ª pasada se verificaron
y se sostienen (42/14 = 3 correcto; sin deriva en las constantes; C4a verificable;
C7/C8 correctos)
**Completeness**: 8/8 secciones

### El hallazgo de proceso, que importa más que cualquier bloqueante individual

La 1ª pasada verificó que los **números** cuadraban con Combate y nunca verificó que
las **reglas** cuadraran. El síntoma fue literal: una fila de Edge Cases decía
*"Coincide con la Regla 9 de Combate"* mientras mandaba al jefe al estado **opuesto**
al que manda esa regla. Nadie abrió Combate a comprobarlo, porque la cita *afirmaba*
la comprobación. **Una referencia cruzada afirmada no es una referencia cruzada
verificada.**

Peor: **6 de los ~12 defectos internos nuevos son descendientes directos de los
arreglos de la 1ª pasada** — Y2/Y3 y la nota de E4 nacieron del desdoble B2; Y4 del
arreglo R2; Y5 de aplicar B1 solo a la mitad de los casos que la Regla 8 nombra; Y9
de suavizar E5 en R7. No es mala suerte: es la consecuencia de cerrar 14 ítems en la
misma sesión en que se encuentran, sin que nada verifique los arreglos. **Cerrar en
la misma sesión está permitido; darlo por cerrado sin re-review, no.**

### Bloqueantes y su resolución

| # | Hallazgo | Fuente | Resolución |
|---|---|---|---|
| B1 | Aborto de combo → `Enfriamiento`, contradiciendo a Combate en 4 sitios (Regla 4, Regla 9, Fórmula 4, AC D4); cita falsa de "coincidencia"; cota `i < N` dejaba fuera el fallo del golpe N | los 5 especialistas | Corregido a **`Repliegue`** con las tres razones (Repliegue diferido / justicia / paridad de ritmo); cota ampliada a `1 ≤ i ≤ N`; tabla de estados, C3b, E4 y Edge Case alineados; cita falsa sustituida por las 4 ubicaciones reales |
| B2 | `Enfriamiento` sin piso: un golpe conectado deja al jugador 8–12 ticks sin poder parar, y su duración es del sistema 20 sin mínimo declarado | `game-designer` | **Core Rule 9** nueva + AC **C9**: `Enfriamiento + Telegrafiado ≥ 12 + margen_reaccion_min`. El GDD declara la forma, el sistema 20 el número |
| B3 | `Acción Especial` exigía reutilizar el contrato de `Golpe` y a la vez suprimir 2 de las 4 consecuencias que el AC C4 de Combate verifica como paquete atómico | `systems-designer`, `ai-programmer`, `qa-lead` | **Ventana Especial** con par de eventos propio; 2 de 4 consecuencias; parry fallido no daña; `false` + ventana = configuración ilegal. ACs C5a reescrito, C5c/C5d nuevos |
| B4 | Regla 8 prohibía polling y señales diferidas pero dejaba pasar `await`, `Tween`, `SceneTreeTimer` y callbacks de `AnimationMixer` (que además procesa en *idle*, acoplado al render) | `godot-specialist` | Prohibición **por propiedad** con lista de ejemplos no exhaustiva; señal no diferida declarada conforme; cláusula de reentrada; alcance acotado a la ruta de despacho |
| B5 | Combate atribuía los eventos al sistema 20 y **nunca mencionaba al sistema 2** — incumple la bidireccionalidad de `.claude/rules/design-docs.md` | `systems-designer`, `ai-programmer`, `godot-specialist` | Reparto de **tres partes** (20 = duraciones, 2 = emisión, 1 = consumo) + **Enmienda 1** aplicada a Combate |
| B6 | `114` resolvía `restantes > 6` como igualdad (correcto: **113**); el ejemplo de E3 daba `110+8 = 118 ≠ 120` | `systems-designer` | Cifra corregida; convención `restantes(T) = 120 − T` declarada normativa; banda de contacto 116–124 derivada de inicio + fotogramas activos |
| B7 | Payload `i`/`N` sin AC que lo verificara; E2 conservaba la forma inverificable que C4a corrigió; E5 suavizado hasta dejar de bloquear en CI | `qa-lead` | C3b asevera el payload leyéndolo; E2 reescrito por orden/conteo de señales; E5 con capa de test (dura) separada de la de producción (blanda) |
| B8 | "ningún estado se interrumpe a mitad de duración" era **falso** (el perdón de anticipación trunca `Golpe` rutinariamente); nunca se cruzó contra el AC C5 de Combate | `ai-programmer` | Convención **"resolución = límite de estado"** + tabla duración nominal vs. resolución + reconciliación explícita con C5. Truncamiento de animación asignado al sistema 20 |
| B9 | Derrota del jugador a mitad de `En Combo`/`Acción Especial` sin comportamiento definido | `ai-programmer` | Fila de Edge Cases: congelar, liberar temporizadores, descartar `i`, no emitir nada — espejo del AC **E7** de Combate |

### Recomendados aplicados

C1 con cota de ≥50 ciclos (mismo defecto de forma que C1b ya había corregido) ·
C8 por **identidad de nombres**, no cardinalidad (un test de `size() == 9` dejaba
pasar una sustitución) · **C4d** nuevo: la Postura no cambia fuera de la resolución
de `Golpe`/`En Combo`, que era la premisa silenciosa de toda la Regla 4 ·
propietario del truncamiento de animación · sistemas 4 y 16 nombrados como
consumidores previstos de `i`/`N`.

### Desacuerdos entre especialistas y su adjudicación

1. **¿Quién cede en el aborto de combo? (3–1).** `ai-programmer` sostuvo en solitario
   que el error estaba en **Combate** — que `Repliegue` es en todo el resto de ese
   documento la ventana que *premia* un parry, y mandar ahí al jefe tras conectar un
   golpe es temáticamente invertido. `creative-director` **le concedió la pregunta y
   le negó la conclusión**, tras verificar que **Combate no se contradice a sí
   mismo**: distingue deliberadamente golpe simple que conecta (→ `Enfriamiento`, su
   AC **E8**) de combo abortado (→ `Repliegue`, su AC **D4**). Tres razones: el
   Repliegue quedó *diferido* durante el combo y al abortarse se paga lo ya debido;
   eliminarlo abriría en el camino de combo el agujero que B2 cierra en el simple; y
   si un combo roto y uno clavado devolvieran al jefe a compases distintos, el
   jugador leería su propio fallo por la cadencia antes que por el feedback.

2. **¿Es real la contradicción de preempción de `Aturdido`?** `ai-programmer` propuso
   reescribir el AC C5 de Combate; `qa-lead` ofreció dos lecturas sin elegir.
   `creative-director` lo resolvió como **colisión de vocabulario** (animación vs.
   estado FSM) y rechazó reabrir un doc Aprobado por ello — pero rescató el defecto
   colateral, que sí era real, como **B8**.

3. **`interrumpible_por_parry = false` vs. AC C5 de Combate**: en vez de adjudicar
   precedencia entre dos documentos, `creative-director` la **cerró por
   construcción** — prohibir la Ventana Especial bajo `false` hace la colisión
   estructuralmente inalcanzable. Mismo patrón que C7 con el rango de `N`.

### Sobrealcance rechazado

Especificar el contrato completo de `Acción Especial` hoy · matriz de cobertura por
tipo de transición en el AC Visual/Feel · exigir consumidor declarado para `i`/`N`
(decisión ya adjudicada en la 1ª pasada, sin evidencia nueva) · reescribir el AC C5
de Combate · ampliar los ejes de `interrumpible_por_parry`.

> **Nota**: el usuario eligió **Opción B en B3** (especificar el contrato completo
> ahora) frente a la recomendación de `creative-director` de recortar alcance. La
> consecuencia asumida es la **Enmienda 2 a Combate**, que es semántica.

### Enmiendas aplicadas a `combate-parry-absorcion.md` (GDD Aprobado)

1. **No semántica** — reconocimiento del sistema 2 como emisor canónico de los
   eventos de ventana activa (Regla 1, Interactions, Dependencies). Cierra B5.
2. **Semántica** — excepción de **Ventana Especial** en la Regla 4 (2 de 4
   consecuencias), corolario en la Regla 6 (no daña al jugador) y acotación del AC
   **C4**. **No ha pasado revisión adversarial**; el clúster Regla 4 / Regla 6 / C4
   queda pendiente de re-verificación.

### Estado tras la sesión

Los 9 bloqueantes y los 5 recomendados quedaron **aplicados en la misma sesión**.
**Pendiente: `/consistency-check` y luego re-review en sesión limpia** — con la
lección de esta pasada muy presente: 14 arreglos nuevos y una enmienda semántica a
un GDD aprobado son exactamente el material del que salieron los defectos de hoy.

**Criterio de éxito de la próxima pasada**: que encuentre **cero** defectos
originados en los arreglos de ésta. Esta vez fueron seis.

---

## Review — 2026-08-03 — Verdict: NEEDS REVISION (resuelto en la misma sesión)

**Scope signal**: M (el producer debe verificarlo antes de planificar sprint)
**Modo**: full (5 especialistas en paralelo + síntesis de `creative-director`)
**Especialistas**: `game-designer`, `systems-designer`, `qa-lead`, `ai-programmer`,
`godot-specialist` + `creative-director` (veredicto senior)
**Bloqueantes**: 7 | **Recomendados**: 7 | **Nice-to-have**: 6
**Prior verdict resolved**: primera revisión — no había log previo
**Completeness**: 8/8 secciones

### Resumen del veredicto senior

La topología es correcta, las constantes cuadran con el GDD de Combate y el
hallazgo del colchón de `Aturdido` es diseño de primera. Ningún hallazgo exigió
rediseñar nada: los 14 se resolvieron con texto. El defecto más importante lo
encontraron **tres especialistas por caminos independientes** — `qa-lead`
(intesteable), `ai-programmer` (sin contrato de señales) y `godot-specialist`
(sin garantía de orden en Godot 4.7) — y era el mismo: **C4a declaraba una
garantía de mismo-tick sin ningún contrato que la hiciera cierta ni verificable**.

`creative-director` marcó explícitamente como **sobrealcance** —y por tanto
fuera de esta pasada— diseñar estados de invocación de esbirros, expandir el
contrato de interrupción más allá del booleano, y añadir primitivas de
posicionamiento: son contenido de año 2 para un esqueleto cuya v1.0 son 3 jefes.

### Bloqueantes y su resolución

| # | Hallazgo | Fuente | Resolución |
|---|---|---|---|
| B1 | C4a sin contrato de implementación: garantía semántica de mismo-tick, sin directiva de señales/`process_priority`, y no verificable por polling de estado | `qa-lead`, `ai-programmer`, `godot-specialist` | **Regla 8 nueva** (resolución síncrona normativa: prohíbe polling desde `_physics_process` independiente y señales diferidas). Especifica efecto, no mecanismo. Open Question nueva marcando el mecanismo como material de ADR |
| B2 | Edge case E3 ambiguo entre instante de pulsación e instante de contacto | `systems-designer` (lo leyó como contradicción) vs `qa-lead` (lo dio por válido) | Declarado que **este GDD gobierna el contacto**. AC desdoblado en E3 (contacto en tick 120) y E3b (pulsación en 120 = Parry; último tick legal de pulsación = **114**) |
| B3 | `En Combo` tratado como hoja cuando es un contenedor con bucle contado | `ai-programmer` | Nota normativa en la Regla 3: el conjunto de 9 describe una máquina **jerárquica**. Los sub-estados no cuentan como top-level a efectos de la Regla 7 |
| B4 | Fórmula 6 (`dano_golpe_castigo`) ausente de la tabla de consumos, siendo la única fuente de daño que hace alcanzable `Muerto` | `systems-designer` | Fila añadida + nota de que la alcanzabilidad de `Muerto` es **contingente de la invariante R4** de Combate |
| B5 | Sin AC para N fuera del rango legal 3–5 (única fila de Edge Cases sin AC) | `qa-lead` | Fila apunta al **AC C16 de Combate** como gate primario; **C7** nuevo como aserción defensiva al entrar en `En Combo` |
| B6 | Error aritmético: "cuadriplica" para 42/14 | `systems-designer` | Corregido a "**triplica exactamente**" (42/14 = 3.0). La conclusión de diseño se sostiene igual |
| B7 | Regla 7 exigía "revisar este GDD" sin definir cómo | `creative-director` (síntesis) | **Procedimiento de enmienda ligero** de 3 pasos + **vía declarada para Lucifer** (sub-estado anidado, sin enmienda) |

### Recomendados y su resolución

| # | Hallazgo | Fuente | Resolución |
|---|---|---|---|
| R1 | El `Repliegue`-colchón se ve idéntico al rutinario, pese a premiar el acierto | `game-designer` | Fila nueva en Visual/Audio + preámbulo justificando por qué es de este GDD (el colchón lo inventó este documento) |
| R2 | Aborto de combo indistinguible entre "fallé todo" y "clavé 4 de 5" | `game-designer` | El evento de aborto emite **índice `i` y longitud `N`**. El feedback sigue siendo de Combate/sistema 4; el dato es de aquí |
| R3 | Solo el test de integración resultaba exigible; la topología podía saltarse | `qa-lead` | Desdoblado en **dos gates BLOCKING**: Logic (`tests/unit/`) e Integration (`tests/integration/`, solo cableado) |
| R4 | C1b decía "indefinidamente" sin condición de parada | `qa-lead` | Cota de **≥50 ciclos consecutivos** sin deriva |
| R5 | AC Visual/Feel sin tamaño de muestra | `qa-lead` | **≥5 playtesters, ≥2 jefes cada uno**, por observación espontánea |
| R6 | Precondición de sub-ventana solo en Edge Cases | `qa-lead` | Movida a la Core Rule 5 + acotación de que el booleano es el mínimo v1 |
| R7 | E5 como `assert()` duro reventaría builds al llegar el sistema 19 | `ai-programmer` | **Aserción blanda con log de aviso** |

### Desacuerdos entre especialistas y su adjudicación

1. **E3 — `systems-designer` (BLOQUEANTE) vs `qa-lead` (pasa).** Ambos acertaban
   sobre cosas distintas. La lectura de la regla de input de Combate de
   `systems-designer` es correcta y verificada, pero ninguno vio que el edge case
   dice "conecta" y no "se pulsa": con 6–8 ticks de anticipación de animación, un
   Castigo pulsado en el tick 110 puede impactar en el 120. **El defecto real era
   la ambigüedad**, no la contradicción. Resuelto desdoblando en E3/E3b.

2. **`Acción Especial` — `ai-programmer` (BLOQUEANTE ×2) vs `game-designer`
   (IMPORTANTE).** `creative-director` falló a favor de `game-designer`. El
   argumento de que "el sistema 20 violará la Regla 7 el día uno" describe la
   puerta de gobernanza **funcionando**, no fallando. Se aceptó la mitad válida:
   faltaba el procedimiento de enmienda (B7), no un estado de invocación.

### Verificado y limpio

- Las **6 constantes** que este GDD cita (`retreat_base`=42, `ventana_castigo`=120,
  `gracia_salida_castigo`=6, `longitud_combo` 3–5, `physics_ticks_per_second`=60,
  `postura_max`) coinciden exactamente con el GDD de Combate. Sin deriva numérica.
- Límites de combo **N=3 y N=5** consistentes con la invariante R7 de Combate
  (0.5 > 1/3).
- **Ningún cambio de Godot 4.4→4.7** afecta a este documento (`godot-specialist`).
- `enum` + `match` confirmado como patrón correcto; `AnimationTree` sería erróneo
  (pensado para blending, modo de proceso no-físico por defecto, timing
  incompatible con la garantía de mismo-tick).

### Estado tras la sesión

Los 7 bloqueantes y los 7 recomendados quedaron **aplicados en la misma sesión**.
El GDD no tiene bloqueantes ni recomendados abiertos. **Pendiente: re-review en
sesión limpia** para verificar que los 14 arreglos se sostienen ante una lectura
adversarial fresca.

**Riesgo técnico principal heredado a arquitectura**: el mecanismo concreto que
garantiza la Regla 8 (resolución síncrona) debe resolverse con un ADR en
`/create-architecture`. El modo de fallo es un tick de retraso silencioso, no un
crash — precisamente el test negativo que la Player Fantasy declara como
criterio de fracaso del sistema.

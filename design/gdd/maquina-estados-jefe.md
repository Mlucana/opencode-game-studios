# Máquina de Estados de Jefe

> **Status**: In Review — revisado y corregido, pendiente de re-review
> **Author**: usuario + agentes especialistas (`systems-designer`, `qa-lead`)
> **Last Updated**: 2026-08-03
> **Last Reviewed**: 2026-08-03 — **2ª pasada** de `/design-review` completo (mismos 5 especialistas + síntesis de `creative-director`). Veredicto: NEEDS REVISION con 9 bloqueantes, **los 9 resueltos en esta pasada**, más los 5 recomendados. Los 14 arreglos de la 1ª pasada se sostienen; lo que la 1ª pasada no buscó fueron **contradicciones cruzadas con el GDD de Combate ya Aprobado** (verificó constantes, no reglas). Cambios: aborto de combo corregido a `Repliegue` y cota ampliada a `1 ≤ i ≤ N` (B1) · **Core Rule 9** nueva, piso de justicia de `Enfriamiento`+`Telegrafiado` (B2) · `Acción Especial` con **Ventana Especial** de evento propio, rama de parry fallido y configuraciones ilegales (B3) · Regla 8 reformulada como prohibición **por propiedad**, con `await`/`Tween`/`SceneTreeTimer`/`AnimationMixer` y reentrada (B4) · relación de tres partes en la propiedad de eventos (B5) · aritmética del borde de Castigo corregida a **113** y banda de contacto 116–124 (B6) · payload `i`/`N` aseverado en C3b, E2 reescrito, E5 con capas separadas (B7) · convención "resolución = límite de estado" y reconciliación con el AC C5 de Combate (B8) · derrota del jugador a mitad de estado (B9). ACs nuevos: **C3c, C4d, C5c, C5d, C9**.
> **Bloqueante externo abierto**: dos enmiendas pendientes en `combate-parry-absorcion.md` (ver Interactions) — una no semántica (dependencia bidireccional) y una semántica (excepción a su Regla 4 para la Ventana Especial).
> **Implements Pillar**: Pilar 2 (La maestría está en las manos, no en la ficha) — también sostiene el Pilar 3 (Cada enemigo es alguien)

## Summary

La Máquina de Estados de Jefe es el esqueleto de estados y transiciones que
gobierna a cualquier jefe de NOVENA: define los estados genéricos (Reposo,
Telegrafiado, Golpe, En Combo, Repliegue, Enfriamiento, Aturdido, Acción
Especial, Muerto) y las reglas de transición entre ellos, sin fijar timings ni composición de
patrones concretos — eso es propiedad de la IA de Combate de Jefes (sistema 20).
Existe porque sin un esqueleto común, cada jefe reinventaría su propia lógica de
estado, haciendo imposible garantizar que los eventos que Combate de
Parry-Absorción ya consume ("inicio de Golpe", "fin de Golpe") signifiquen lo
mismo para los 27 jefes de la visión completa del juego.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

Cada jefe de NOVENA — desde el primer ángel del tutorial hasta Lucifer — se
ejecuta sobre la misma máquina de estados subyacente: un ciclo de fases
(telegrafiar, golpear, recuperarse) más los estados que el Combate de
Parry-Absorción ya le impone desde fuera (entrar en Aturdido cuando su Postura
llega a 0, recibir un Golpe de Castigo, replegarse tras un parry exitoso). Este
sistema no decide *qué* ataque usa un jefe ni *cuánto* dura cada fase — eso
pertenece a la IA de Combate de Jefes, que se apoya en este esqueleto para
expresar la personalidad de cada ángel (Pilar 3) sin tener que resolver, jefe
por jefe, cómo entrelazar su ciclo de ataque con las interrupciones que le
impone el jugador. Existe porque, sin un contrato de estados común y
determinista, no hay forma de garantizar que "el jefe está en Aturdido" o "el
jefe fue interrumpido" signifiquen lo mismo para todos los jefes del juego — y
Combate ya depende de esos eventos para funcionar.

## Player Fantasy

> `creative-director` no consultado — modo Lean. Revisar manualmente antes de
> producción.

Este sistema no tiene fantasía propia: es infraestructura pura. El jugador
nunca "siente la máquina de estados" — siente lo que ella habilita, transferido
íntegramente a los sistemas que se apoyan en ella: la lectura de un
Telegrafiado y el momento de vulnerabilidad del Aturdido pertenecen a la
fantasía del Combate de Parry-Absorción (Pilar 2); que cada jefe tenga una
gramática de estados propia, sin sentirse una plantilla reutilizada, pertenece
a la fantasía de "cada enemigo es alguien" (Pilar 3, propiedad de la IA de
Combate de Jefes y del roster de jefes). El único test de diseño que este GDD
aporta a esa fantasía compartida es negativo: si un jugador puede *notar* la
máquina de estados como tal — una transición que se siente mecánica, un estado
que "se traba", una interrupción que llega tarde o pronto de forma
inconsistente entre jefes — el sistema ha fallado, porque su trabajo es ser
invisible y confiable, nunca protagonista.

## Detailed Design

### Core Rules

1. **Ciclo base de un jefe (sin combos ni acciones especiales)**:
   `Reposo → Telegrafiado → Golpe → (Enfriamiento | Repliegue) → Telegrafiado`,
   en bucle continuo mientras el jefe tenga Vida y el duelo no haya terminado.
   `Reposo` es el único estado que no forma parte del ciclo de ataque: se entra
   al comenzar el duelo y no se vuelve a él salvo diseño explícito de un futuro
   sistema (ver Open Questions).
2. **Bifurcación de salida de Golpe**: al terminar la ventana activa de Golpe,
   la salida depende del resultado que ya resuelve el Combate de
   Parry-Absorción (sistema 1), no de este GDD:
   - Golpe **parado con éxito** → `Repliegue` (duración `retreat_base`,
     propiedad de Combate) antes de retomar `Telegrafiado`.
   - Golpe **conecta** (no parado) → `Enfriamiento` (duración propiedad de la
     IA de Combate de Jefes, sistema 20, por patrón) antes de retomar
     `Telegrafiado`.
   Este GDD no decide *cuál* ocurre — solo el par de estados hacia el que
   bifurca cada resultado. Cuál se dispara es evento consumido de Combate
   ("parry exitoso" / "parry fallido").
3. **Combos — estado `En Combo`** (implementa la Regla 9 de Combate): un
   patrón de ataque puede componerse como `En Combo`, que envuelve entre 3 y 5
   repeticiones consecutivas de `Telegrafiado → Golpe` (rango impuesto por
   Combate — Fórmula 7/R7 y diseño de audio), sin pasar por `Repliegue` ni
   `Enfriamiento` entre repeticiones internas — la transición intermedia es
   directamente `Golpe → Telegrafiado` del siguiente golpe del combo. Se
   resuelve de una de dos formas, nunca a mitad:
   - **Éxito total** (los N golpes fueron parados): al golpe final, la
     bifurcación de la Regla 2 se evalúa **una sola vez** para el combo
     completo → `Repliegue` o `Aturdido` (Regla 4).
   - **Fallo en el golpe `i`** (cualquier `i`, `1 ≤ i ≤ N` — **incluido el
     golpe final**): el combo se aborta de inmediato; los golpes `i+1…N` nunca
     se ejecutan (conjunto vacío si `i = N`); el jefe sale a **`Repliegue`**
     (`retreat_base`), y el evento de aborto emite `i` y `N`.

   > **Por qué `Repliegue` y no `Enfriamiento`, pese a que el golpe conectó**
   > (corregido en la 2ª pasada de `/design-review`, 2026-08-03; los 5
   > especialistas y `creative-director` convergieron). La versión anterior de
   > esta regla mandaba el jefe a `Enfriamiento` razonando que "un fallo es, por
   > definición, un golpe que conectó", restringía el aborto a `i < N`, y
   > afirmaba **coincidir con la Regla 9 de Combate**. Contradecía a Combate en
   > **cuatro** sitios: su Regla 4 (excepción de combos), su Regla 9 ("Fallo a
   > mitad de combo"), su Fórmula 4 (excepción de combos) y su AC **D4**.
   >
   > **Combate no se contradice a sí mismo**: distingue deliberadamente el golpe
   > **simple** que conecta (→ `Enfriamiento`; su Edge Case correspondiente y su
   > AC **E8**) del combo **abortado** (→ `Repliegue`). El error de este GDD era
   > generalizar la primera regla por encima de una excepción que Combate había
   > declarado explícitamente. Las tres razones por las que la excepción es
   > correcta:
   > 1. **Contable** — durante el combo el `Repliegue` quedó *diferido*
   >    (Combate, Fórmula 4: "no se dispara entre golpes"). Al abortarse se paga
   >    el diferido, una sola vez. No es un `Repliegue` nuevo concedido por
   >    fallar; es el que ya se debía.
   > 2. **De justicia** — el jugador que falla el golpe `i` entra en Recepción
   >    de golpe (8–12 ticks) sin poder parar. Los 42 ticks de `Repliegue` son
   >    hoy el único colchón que protege ese camino. Mandarlo a `Enfriamiento`
   >    —duración sin piso, propiedad del sistema 20— abriría en el camino de
   >    combo exactamente el agujero que la Core Rule 9 cierra en el simple.
   > 3. **De ritmo** — un combo roto y un combo clavado devuelven al jefe al
   >    mismo compás. Si divergieran, el jugador aprendería a leer su propio
   >    fallo por la cadencia del jefe antes de que el feedback se lo dijera.
   >
   > El combo es una **unidad de resolución única**: Combate ya lo trata así en
   > Postura, en gracia y en calidad de timing. Este GDD aceptaba la unicidad en
   > las tres y la rompía solo en la cuarta.
   >
   > La cota `i < N` era además un defecto por sí sola: fallar el golpe **N**
   > (el remate — el caso con más peso emocional del combo) no caía en ninguna
   > de las dos ramas. Combate usa la redacción correcta y más amplia: "si el
   > jugador falla **cualquier** golpe del combo".

   > **`En Combo` es un estado contenedor, no una hoja** (hallazgo de
   > `ai-programmer` en `/design-review`). A diferencia de los otros ocho, este
   > estado envuelve un **bucle contado** de N sub-repeticiones
   > `Telegrafiado → Golpe` con su propio índice interno (`i`), y ese índice es
   > parte del contrato: determina el aborto (Regla 3) y debe emitirse en el
   > evento de aborto. Es decir, el conjunto cerrado de 9 estados de la Regla 7
   > describe una máquina **jerárquica**, no una máquina plana de 9 hojas.
   > Se declara explícitamente aquí porque una implementación ingenua de
   > `enum` plano + `match` funciona para los otros ocho estados y **solo se
   > rompe al llegar a este**, obligando a rediseñar el controlador entero a
   > mitad de sprint. El contenedor y sus sub-estados no cuentan como estados
   > top-level nuevos a efectos de la Regla 7.

   > **El evento de aborto de combo debe llevar el índice `i`** (hallazgo de
   > `game-designer`, adjudicado por `creative-director`). Cuando un combo se
   > aborta, este esqueleto emite el índice del golpe que falló **y** la
   > longitud `N` del combo. Sin ese dato, ningún sistema aguas abajo puede
   > distinguir "el jugador falló el primer golpe" de "el jugador paró 4 de 5 y
   > falló el último" — dos experiencias con peso emocional opuesto que hoy
   > producirían feedback idéntico. **El feedback en sí no es propiedad de este
   > GDD** (los eventos de combo son de Combate; el impacto es del sistema 4);
   > la obligación de este esqueleto es puramente **exponer el dato** para que
   > puedan diferenciarlo. Es contrato de eventos, no diseño audiovisual.
4. **Ruptura de Postura → `Aturdido` reemplaza a `Repliegue`, nunca interrumpe
   otro estado** (aclara una ambigüedad que Combate deja abierta desde el lado
   del jefe — su Regla 5 solo especifica "sin importar el estado del
   **jugador**"): la Postura solo puede cambiar de valor en el instante de
   resolución de un `Golpe` o de un `En Combo` completo (Reglas 2/3) — nunca
   durante `Telegrafiado`, `Enfriamiento` o `Repliegue`, porque esos estados no
   son ventanas de parry activas. Por tanto `Aturdido` **nunca preempta un
   estado en curso**: solo puede sustituir a `Repliegue` en el instante exacto
   en que ese golpe (o combo) ya se resolvió con éxito y la Postura resultante
   es 0. Mientras el jefe está en `Aturdido`, el Golpe de Castigo del jugador
   se resuelve contra su Vida.

   **Salida de `Aturdido` — colchón obligatorio si el Castigo conectó**
   (hallazgo de `systems-designer` en la fase de Formulas): las dos salidas de
   `Aturdido` no son simétricas. Si `ventana_castigo` **expira sin conectar**,
   el jefe sale directo a `Telegrafiado` — el jugador no está comprometido con
   ninguna recuperación, así que no hay problema de justicia. Pero si el Golpe
   de Castigo **conecta**, el jugador entra en su propia recuperación de
   Castigo (10–14 ticks, propiedad de Combate) durante la cual **no puede
   iniciar Parry**. Si el jefe retomara `Telegrafiado` de inmediato en ese
   caso, un ataque que se resuelva dentro de esos 10–14 ticks conectaría contra
   un jugador que no tiene forma de pararlo — no por leer mal el patrón, sino
   por un borde de estado, exactamente la clase de fallo que
   `gracia_salida_castigo` ya existe para prevenir en el extremo opuesto de
   este mismo estado. Por tanto: **cuando el Golpe de Castigo conecta, la
   Postura se restaura por completo (Combate, Fórmula 2) y el jefe pasa por
   `Repliegue`** (42 ticks, la misma constante `retreat_base` que ya usa la
   Regla 2) **antes de retomar `Telegrafiado`** — reutiliza infraestructura ya
   validada en vez de introducir una constante nueva, y su margen (42 ticks)
   triplica exactamente el máximo de recuperación de Castigo (14 ticks) —
   margen sobrado, aunque la versión anterior de esta frase decía
   "cuadriplica", que era aritméticamente falso. Si
   la ventana expira sin conectar, no hay colchón: la Postura se restaura igual
   y el ciclo retoma en `Telegrafiado` directamente.
5. **Estado genérico `Acción Especial`** (extensión reservada para la IA de
   Combate de Jefes, sistema 20 — p. ej. una habilidad de curación): cualquier
   patrón puede declarar una fase como `Acción Especial` en vez de
   `Telegrafiado`/`Golpe`. Cada instancia declara, por patrón, un atributo
   booleano **`interrumpible_por_parry`**:
   - Si `true`: el patrón **debe** declarar además una **Ventana Especial**
     interna (ver abajo). Un evento "parry exitoso" resuelto contra esa ventana
     corta la `Acción Especial` de inmediato y el jefe pasa a `Enfriamiento`.
   - Si `false`: `Acción Especial` ignora cualquier evento de Combate hasta
     completar su propia duración (propiedad de sistema 20), y **tiene prohibido
     declarar una Ventana Especial** (ver "Configuraciones ilegales").

   > **Precondición: el booleano por sí solo no crea nada que parar.**
   > `interrumpible_por_parry = true` **no genera automáticamente una ventana de
   > parry**: el patrón del sistema 20 debe declarar además, explícitamente, una
   > **Ventana Especial** interna para que exista algo contra lo que resolver el
   > parry. Ver Edge Cases y el AC **E1**.
   >
   > *(Movido aquí desde Edge Cases en `/design-review` 2026-08-03 a
   > señalamiento de `qa-lead`: quien leyera solo las Core Rules asumía que el
   > flag bastaba. El contrato de interrupción son en realidad **dos** cosas
   > —booleano + ventana declarada—, no una.)*

   **La Ventana Especial emite su propio par de eventos, NO los de `Golpe`**
   (decisión de usuario en la 2ª pasada de `/design-review`, 2026-08-03 —
   resuelve la Open Question que este GDD tenía abierta sobre el contrato
   compartido). La ventana declara:

   > `inicio de Ventana Especial` / `fin de Ventana Especial`

   — un par **distinto** de `inicio de Golpe` / `fin de Golpe`. Reutiliza su
   **semántica de temporización** (ventana activa contra la que Combate resuelve
   un parry, con el mismo perdón de anticipación de la Regla 3 de Combate) pero
   **no su identidad de evento**.

   > **Por qué era obligatorio separarlos** (hallazgo convergente de
   > `systems-designer`, `ai-programmer` y `qa-lead`). La versión anterior de
   > esta regla exigía "reutilizar el contrato de eventos de la Regla 2" y a la
   > vez garantizaba "sin daño de Postura y sin pasar por `Repliegue`". **Es
   > inimplementable**: el AC **C4** de Combate verifica que un parry exitoso
   > aplica sus cuatro consecuencias *en el mismo fotograma* —Postura, Gracia,
   > hitstop y `Repliegue`— como paquete atómico, y Combate no tiene ningún
   > concepto de `Acción Especial` con el que distinguir un caso del otro. Si la
   > sub-ventana emitía literalmente "inicio de Golpe", Combate aplicaba las
   > cuatro, sin forma de saber que no debía. Con un evento propio, Combate
   > distingue los dos casos por el evento mismo y no hace falta que inspeccione
   > el estado del jefe.

   **Consecuencias de un parry exitoso contra una Ventana Especial** — 2 de las
   4 del paquete de Combate, no las 4:

   | Consecuencia | ¿Se aplica? | Razón |
   |---|---|---|
   | Gracia absorbida | **Sí, completa** | Arrebatarle a un ángel su habilidad divina es la fantasía de robo del Pilar 2 en su forma más pura, y por el Pilar 1 el triunfo debe también corromper. La cantidad la fija el Sistema de Gracia (5), como en cualquier parry |
   | Hitstop y feedback | **Sí** | Es un momento de impacto real — ya especificado en Visual/Audio Requirements ("el aura se fractura y se arranca de golpe") |
   | Daño de Postura | **No** | No es un `Golpe`: la `Acción Especial` está fuera del ciclo de ataque, y la Postura es la moneda de ese ciclo. Preserva la premisa de la Core Rule 4 (la Postura solo cambia en la resolución de un `Golpe`/`En Combo`) |
   | `Repliegue` | **No** — va a `Enfriamiento` | Nada quedó diferido que pagar (a diferencia del aborto de combo, Core Rule 3), y el jugador que acierta el parry queda en recuperación mínima de 2–3 ticks, así que la Core Rule 9 no exige colchón |

   **Parry fallido contra una Ventana Especial** (decisión de usuario, 2ª
   pasada): la ventana **se cierra sin dañar al jugador** y la `Acción Especial`
   continúa hasta su duración natural. La Ventana Especial es una ventana de
   *oportunidad*, no un ataque: el castigo por fallarla es que el jefe consigue
   su habilidad — no Vida perdida. Una habilidad de curación no debe ser además
   un ataque; sería doble castigo por un solo error, y agravaría el riesgo de
   estancamiento ya anotado en `systems-index.md`. **Corolario**: el estado
   `Acción Especial` nunca reduce la Vida del jugador, en ninguna de sus ramas.

   **Configuraciones ilegales** (defensa en profundidad, misma forma que la
   Core Rule 3 y el AC **C7** aplican al rango de `N` — hacer ilegal la
   configuración en vez de resolver el conflicto en runtime):
   1. `interrumpible_por_parry = true` **sin** Ventana Especial declarada — la
      interrupción no puede dispararse nunca. Cubierto por el AC **E1**.
   2. `interrumpible_por_parry = false` **con** Ventana Especial declarada — una
      ventana que nada puede interrumpir es semánticamente vacía. Cubierto por
      el AC **C5d**.

   > **Por qué la ilegalidad nº 2 no es burocracia: cierra una colisión real con
   > el AC C5 de Combate** (hallazgo de `systems-designer` y `ai-programmer`).
   > El C5 de Combate exige entrar en `Aturdido` cuando la Postura llega a 0
   > "sin importar el estado"; esta regla dice que con `false` la `Acción
   > Especial` "ignora cualquier evento de Combate". Si ambas pudieran aplicarse
   > a la vez, los documentos mandarían cosas opuestas **precisamente en el
   > escenario que el flag existe para proteger** (la curación intocable).
   > Prohibiendo la ventana bajo `false`, la Postura no puede cambiar durante
   > ese estado (Core Rule 4: solo cambia en la resolución de un `Golpe`/`En
   > Combo`), la colisión es **estructuralmente inalcanzable**, y no hace falta
   > adjudicar precedencia entre los dos documentos.

   **Calidad de timing**: `calidad_timing` (Combate, Fórmula 1) **no juega
   ningún papel** en una Ventana Especial. Es una entrada de `postura_dano`, y
   aquí no hay daño de Postura; la Gracia (Fórmula 7 de Combate) no la consume.
   La interrupción es binaria: se paró o no se paró.

   > **`interrumpible_por_parry` es el mínimo v1, no la forma final del
   > contrato** (acotación de `creative-director` frente al hallazgo de
   > `ai-programmer`). Un único eje booleano no expresa interrupción parcial
   > (progreso reducido en vez de cancelado), interrumpibilidad dependiente del
   > estado (canalización que deja de ser interrumpible pasados N ticks), ni
   > fuentes de interrupción distintas de "parry exitoso". **Eso es deliberado
   > para v1.0**: los 3 jefes de la versión 1.0 no tienen ninguna de esas
   > necesidades confirmadas, y diseñarlas hoy es especular sobre contenido de
   > año 2. Si el sistema 20 necesita más ejes, la vía correcta es **escalar
   > este contrato aquí** (procedimiento de enmienda, Regla 7), nunca ramificar
   > lógica por jefe — eso reintroduciría exactamente el código ad-hoc por jefe
   > que este esqueleto existe para eliminar.

   Este GDD **no decide** qué habilidades usan `Acción Especial` ni si son
   interrumpibles — solo declara la capacidad genérica y su contrato de
   interrupción, para que el sistema 20 tenga dónde resolver el riesgo de
   "jefe con curación sin castigo" ya anotado en `systems-index.md`.
6. **Estado terminal `Muerto`**: se entra cuando un Golpe de Castigo deja la
   Vida del jefe en 0. Es terminal — sin transición de salida dentro de este
   sistema. Este GDD **posee y emite** el evento "duelo ganado" al entrar en
   `Muerto`; la secuencia de post-duelo (pantalla, persistencia) es propiedad
   de Gestión de Run (sistema 3).
7. **Restricción impuesta a la IA de Combate de Jefes (sistema 20)**: el
   conjunto de estados top-level de esta sección es **cerrado** — `Reposo`,
   `Telegrafiado`, `Golpe`, `En Combo`, `Repliegue`, `Enfriamiento`, `Aturdido`,
   `Acción Especial`, `Muerto`. El sistema 20 asigna duraciones, composición de
   patrones, qué golpes forman combos (dentro de `3 ≤ N ≤ 5`) y qué habilidades
   usan `Acción Especial` — pero no puede introducir un estado top-level nuevo
   sin revisar este GDD primero. Mismo patrón que Combate ya aplica sobre el
   propio sistema 20.

   **Procedimiento de enmienda** (decisión de usuario en `/design-review`,
   2026-08-03 — antes la Regla 7 exigía "revisar este GDD" sin decir cómo, lo
   que la hacía inaplicable). Para añadir un décimo estado top-level:
   1. Quien lo proponga escribe **qué comportamiento concreto no cabe** en los 9
      actuales y **por qué no puede expresarse como sub-estado** de uno
      existente (ver Regla 3: los contenedores y sus sub-estados no cuentan como
      estados top-level nuevos).
   2. Si esa justificación se sostiene, se aprueba editando este GDD y
      registrando la entrada en `design/gdd/reviews/maquina-estados-jefe-review-log.md`.
      **No hace falta un `/design-review` completo** — el coste de una revisión
      adversarial de 5 especialistas por cada estado nuevo desincentivaría
      cambios legítimos en un proyecto de un solo desarrollador.
   3. La carga de la prueba recae en la propuesta, no en el esqueleto: por
      defecto, la respuesta es "modélalo como sub-estado".

   **Vía declarada para Lucifer (sistema 11)** (misma decisión): la transición
   entre sus dos formas se modela como **sub-estado anidado dentro de un estado
   existente** — típicamente una `Acción Especial` con
   `interrumpible_por_parry = false`— y por tanto **no requiere enmienda ni abre
   el conjunto cerrado**. Esto cierra la crítica de que la Regla 7 era en
   realidad "cerrada a la espera de una enmienda que ya sabemos que viene":
   la extensión conocida más probable tiene ahora una vía declarada que no
   rompe el contrato. El sistema 11 sigue siendo dueño de *qué* hace esa
   transición; este GDD solo fija *dónde* vive.
8. **Resolución síncrona — las transiciones de este esqueleto no son
   observaciones, son consecuencias** (hallazgo convergente de `qa-lead`,
   `ai-programmer` y `godot-specialist` en `/design-review`; los tres llegaron
   al mismo defecto por caminos distintos). Toda transición que este GDD declara
   como "en el mismo tick" —la sustitución `Repliegue → Aturdido` de la Regla 4,
   y el desempate de `Acción Especial` de Edge Cases— **debe resolverse
   sincrónicamente dentro de una única llamada de transición disparada por la
   resolución de Combate**.

   **La prohibición se define por propiedad, no por lista** (reformulado en la
   2ª pasada de `/design-review` a hallazgo de `godot-specialist`; la versión
   anterior enumeraba solo dos mecanismos y dejaba pasar al menos cuatro más del
   mismo defecto):

   > **Queda prohibido cualquier mecanismo cuya ejecución quede fuera del call
   > stack síncrono que originó la resolución de Combate.**

   La lista siguiente son **ejemplos nombrados, no exhaustivos**:
   - polling de un flag desde un `_physics_process` propio e independiente del
     de Combate;
   - señales diferidas (`call_deferred`, `CONNECT_DEFERRED`);
   - **`await`** y cualquier corrutina que ceda el control — suspende la función
     y devuelve el control al scheduler, que es exactamente la propiedad que
     esta regla prohíbe;
   - **`Tween`** (`finished`, `tween_completed`) y **`SceneTreeTimer`**
     (`timeout`) — se disparan en un tick posterior por construcción;
   - **callbacks de `AnimationPlayer`/`AnimationTree`** (`animation_finished`) —
     además de llegar tarde, `AnimationMixer` procesa en modo *idle* por
     defecto, es decir acoplado al framerate de **renderizado**, lo que viola
     también la Regla 2 de Combate ("nunca frames de render"). Es la tentación
     más probable, porque el colchón de la Core Rule 4 y el aura de `Acción
     Especial` son ambos visualmente animados;
   - un bus de eventos con cola, aunque se vacíe "casi inmediatamente".

   **Sí es conforme**: una señal de Godot **no diferida** (conexión por defecto,
   sin flags), porque invoca todos los `Callable` conectados de forma síncrona,
   en orden de conexión, dentro del mismo call stack. También lo es la llamada
   directa a método. La elección entre ambas es de `/create-architecture`.

   **Prohibición de reentrada**: ningún suscriptor de una señal de transición
   (`state_entered`, `state_exited` o equivalente) puede disparar sincrónicamente
   una nueva resolución de transición durante el mismo despacho. Los suscriptores
   —HUD de Combate (13), Feedback de Impacto (4), audio (16)— se limitan a
   lectura y efectos de presentación, nunca invocan de vuelta al FSM. Sin esta
   cláusula, una reentrada podría producir una secuencia de emisiones que respeta
   el orden que el AC **C4a** exige pero con conteos duplicados o intercalados.

   > **Alcance de la prohibición**: aplica **únicamente al mecanismo de despacho
   > de la transición**, no a otros usos legítimos de `call_deferred` en el resto
   > de la implementación del jefe (p. ej. mutaciones del árbol de escena durante
   > callbacks de física, que Godot exige diferir).

   **Por qué es normativo y no una nota de implementación**: si Combate y este
   esqueleto son nodos separados, cada uno con su propio `_physics_process`, el
   orden de ejecución entre ambos **no está garantizado** salvo por
   `process_priority` — fácil de olvidar y de romper al reordenar la escena. El
   fallo resultante no es un crash: es **un tick de retraso silencioso** en
   exactamente la garantía que la Regla 4 existe para dar, y se manifestaría
   como el `Repliegue` de un fotograma que el jugador percibe antes del
   `Aturdido`. Es decir, el modo de fallo es precisamente el test negativo que
   la Player Fantasy declara como criterio de fracaso del sistema.

   Este GDD especifica **el efecto, no el mecanismo** — mismo patrón que Combate
   aplica en su Regla 2 al hitstop. El *cómo* concreto (nodo autoritativo,
   `process_priority`, orden de despacho) es decisión de `/create-architecture`
   — ver Open Questions. Cubierto por los ACs **C4a** y **E2** — la Regla 8
   nombra **dos** casos, y ambos necesitan verificación por contrato de señales.
9. **Piso de justicia tras un golpe que conecta** (hallazgo de `game-designer`,
   adjudicado como bloqueante por `creative-director` en la 2ª pasada de
   `/design-review`). La Core Rule 4 introdujo un colchón de 42 ticks para que
   el jefe no pudiera atacar mientras el jugador está comprometido en su
   recuperación de Castigo (10–14 ticks). **El mismo agujero existía, sin tapar,
   en el camino mucho más frecuente**: cuando un `Golpe` simple conecta, el
   jugador entra en Recepción de golpe (**8–12 ticks**, Combate) durante los
   cuales no puede iniciar Parry, y el jefe pasa a `Enfriamiento`, cuya duración
   es propiedad del sistema 20 y **no tenía mínimo declarado en ningún
   documento**. Nada impedía que el siguiente `Golpe` entrara en ventana activa
   antes de que el jugador recuperara el control.

   **Invariante impuesta al sistema 20** (mismo patrón con que Combate impone
   `3 ≤ N ≤ 5` y `multiplicador_ataque = 1.0`: el documento que posee la
   invariante que se rompería es quien declara la restricción):

   > Para **todo** patrón que pueda seguir a un `Golpe` que conectó:
   > `duración(Enfriamiento) + duración(Telegrafiado) ≥ recuperacion_recepcion_max + margen_reaccion_min`
   >
   > donde `recuperacion_recepcion_max` = **12 ticks** (techo del rango 8–12 de
   > Recepción de golpe, propiedad de Combate) y `margen_reaccion_min` es un
   > valor **propiedad del sistema 20**, a fijar por playtesting.

   **Este GDD declara la forma de la restricción, no el número.** Elegir
   `margen_reaccion_min` es diseño de cadencia y pertenece al sistema 20 — igual
   que este GDD no elige las duraciones de `Telegrafiado`. Lo que sí posee es la
   garantía topológica de que ningún borde de estado sea injusto, y esa garantía
   es verificable sin conocer el número: la desigualdad se asevera sobre los
   valores que el patrón declare. Cubierto por el AC **C9**.

   > **No es una regla nueva: es aplicar un principio que Combate ya declaró
   > general.** Su Regla 5 justifica `gracia_salida_castigo` con esta frase:
   > *"ningún borde de estado puede convertir un input razonable en un castigo
   > inevitable"*. Está escrita sin excepción para "el jugador ya había fallado
   > antes" — y aun así el único camino al que nadie se la había aplicado es el
   > que ocurre varias veces por ciclo. Toca el **Pilar 2** de lleno: si el
   > segundo golpe es imparable por aritmética de estado, la maestría dejó de
   > estar en las manos del jugador, y del modo más corrosivo posible — el
   > jugador no puede distinguirlo de haber leído mal, así que ni siquiera
   > aprende del fallo.
   >
   > **Por qué los otros caminos ya están cubiertos y no necesitan cláusula**:
   > tras un parry exitoso el jugador queda en recuperación mínima de 2–3 ticks
   > y el jefe en `Repliegue` (42) o `Aturdido` (120); tras un combo abortado el
   > jefe pasa por `Repliegue` (42 > 12, Core Rule 3); tras un Castigo conectado
   > actúa el colchón de la Core Rule 4 (42 > 14). `Enfriamiento` era el único
   > estado de salida sin piso.

### States and Transitions

| Estado | Entry Condition | Exit Condition | Behavior |
|---|---|---|---|
| Reposo | Inicio del duelo | Comienza el primer Telegrafiado | Sin ataque activo; único punto de entrada al ciclo (ver Open Questions sobre transiciones de fase) |
| Telegrafiado | Fin de Enfriamiento/Repliegue/Reposo, o siguiente repetición dentro de En Combo | Comienza la ventana activa de Golpe | Duración y telegrafía visual por patrón — propiedad de sistema 20 |
| Golpe | Fin de Telegrafiado | El jugador para el golpe o el golpe conecta — evento consumido de Combate (sistema 1) | Ventana activa consumida por Combate como "inicio de Golpe"/"fin de Golpe". Duración propiedad de sistema 20 |
| En Combo | El patrón activo es un combo (composición de sistema 20); se entra en el primer Telegrafiado del combo | Los N golpes se paran (éxito total), **o** cualquier golpe `i` (`1 ≤ i ≤ N`, incluido el final) conecta (fallo, aborta los restantes) | Envuelve 3–5 repeticiones internas de Telegrafiado→Golpe sin Repliegue/Enfriamiento entre ellas; la Postura solo se evalúa una vez, al resolverse el combo completo. **Ambas salidas van a `Repliegue`** (o a `Aturdido` en el caso de éxito con Postura resultante 0) — ver Core Rule 3 |
| Repliegue | Golpe simple se resuelve con parry exitoso y la Postura resultante es > 0; **o** un `En Combo` se resuelve (éxito total con Postura > 0, **o** aborto por fallo — el Repliegue diferido se paga aquí, Core Rule 3); **o** el Golpe de Castigo conectó en Aturdido (colchón obligatorio, ver Core Rule 4) | Vencen `retreat_base` ticks (42, propiedad de Combate) | Ventana de bajo riesgo antes del siguiente Telegrafiado; duración fija, no varía por patrón ni por cuál de las tres entradas se usó |
| Enfriamiento | Un `Golpe` **simple** conecta sin ser parado (Combate, AC E8), **o** una `Acción Especial` es interrumpida (Core Rule 5) | Vence la duración de Enfriamiento (propiedad de sistema 20, por patrón; con el piso de la Core Rule 9) | Cadencia normal de recuperación; no acelera ni ralentiza por el resultado (Combate, Edge Cases). **No se entra aquí por aborto de combo** — ver Core Rule 3 |
| Aturdido | Golpe (o En Combo) se resuelve con parry exitoso y la Postura resultante llega a 0 — reemplaza a Repliegue en ese instante | Golpe de Castigo del jugador conecta → sale a **Repliegue** (colchón obligatorio, Core Rule 4). Vencen `ventana_castigo` (120 ticks) sin conectar → sale directo a **Telegrafiado** (sin colchón, el jugador no está comprometido) | Ventana de vulnerabilidad total (propiedad de Combate); ambas salidas restauran la Postura por completo, pero difieren en si pasan por un colchón antes de Telegrafiado |
| Acción Especial | Sistema 20 declara esta fase para un patrón concreto (p. ej. curación) | Termina su propia duración → `Telegrafiado`; **o** un parry exitoso contra su Ventana Especial la corta (solo si `interrumpible_por_parry = true`) → `Enfriamiento` | Extensión genérica para habilidades fuera del ciclo estándar. Si es interrumpible, declara una **Ventana Especial** con su propio par de eventos (`inicio`/`fin de Ventana Especial`), distinto del de `Golpe`. Un parry exitoso contra ella concede Gracia y hitstop pero **no** Postura ni `Repliegue`; un parry fallido **no daña al jugador** y la acción se completa. Este estado nunca reduce la Vida del jugador — ver Core Rule 5 |
| Muerto | La Vida del jefe llega a 0 durante la resolución de un Golpe de Castigo (dentro de Aturdido) | — (terminal) | Emite el evento "duelo ganado"; sin transición de salida dentro de este sistema |

> **Convención normativa: "resolución = límite de estado".** A diferencia de
> Combate (que sí tiene tabla de prioridad de interrupción porque el jugador
> puede actuar en cualquier momento), este esqueleto **no tiene ningún estado
> que se interrumpa a mitad de _resolución_**: toda transición ocurre en el
> instante en que un evento de Combate resuelve el estado, y ese instante **es**
> el límite del estado, nunca su interior.
>
> **Lo que esto NO significa** (corregido en la 2ª pasada de `/design-review`,
> hallazgo de `ai-programmer` y `creative-director`): la versión anterior de
> esta nota decía que "no hay estados que se interrumpan a mitad de duración,
> salvo `Acción Especial`", y **era falsa**. Por el perdón de anticipación
> (Combate, Regla 3, caso b — "el Golpe comienza mientras el parry del jugador
> sigue activo"), un `Golpe` se resuelve **rutinariamente antes de agotar su
> duración nominal**, que es propiedad del sistema 20. Truncar la duración
> nominal es el caso normal, no la excepción. Hay que distinguir:
>
> | | ¿Se trunca? |
> |---|---|
> | **Duración nominal / animación** de `Golpe` y `En Combo` | **Sí, rutinariamente** — es el funcionamiento normal del perdón de anticipación |
> | **Resolución** de cualquier estado | **Nunca a medias** — el evento de Combate llega, se resuelve, y esa resolución cierra el estado |
>
> **Reconciliación explícita con el AC C5 de Combate.** El C5 de Combate dice
> que la ruptura de Postura hace entrar al enemigo en Aturdido "en cualquier
> momento del ciclo (incluso a mitad de `Golpe`), interrumpiendo cualquier
> animación de ataque en curso". Eso **no contradice** a la Core Rule 4 de este
> GDD: C5 habla de la **animación / ventana nominal** (que sí se trunca) y de en
> qué golpe del patrón se rompe la Postura; la Core Rule 4 habla del **estado de
> la FSM** (que se cierra en el instante de resolución). Bajo la convención de
> arriba, ambas son ciertas a la vez y `Aturdido` sigue sin preemptar nada.
> *(La 1ª pasada declaró reconciliar con la Regla 5 de Combate —que solo habla
> del estado del **jugador**— y nunca cruzó contra el AC C5, que sí habla del
> jefe. Este párrafo cierra ese hueco.)*
>
> **Consecuencia sin propietario, anotada aquí**: el truncamiento de la
> animación de `Golpe` cuando se resuelve antes de su duración nominal es un
> requisito real de presentación que hoy no posee ningún documento. Se asigna al
> sistema 20 / dirección de arte al autorar los patrones — no se resuelve aquí.

### Interactions with Other Systems

- **Combate de Parry-Absorción (1)**: Bidireccional. Este sistema **provee**
  los eventos "inicio de Golpe" / "fin de Golpe" y —cuando un patrón la
  declara— "inicio de Ventana Especial" / "fin de Ventana Especial" (Core Rule
  5), que Combate consume. Combate **provee de vuelta** el resultado de cada
  Golpe ("parry exitoso"/"parry fallido") y la Postura resultante, que este
  sistema consume para bifurcar Repliegue/Aturdido/Enfriamiento. Las duraciones
  de `Repliegue` (`retreat_base`) y `Aturdido` (`ventana_castigo`,
  `gracia_salida_castigo`) son propiedad de Combate — este sistema las consume,
  no las redefine.

  > **Relación de tres partes, explicitada en la 2ª pasada de `/design-review`**
  > (hallazgo de `systems-designer`, `ai-programmer` y `godot-specialist`).
  > Combate atribuye los eventos "inicio/fin de Golpe" al **sistema 20** en tres
  > sitios y —verificado por búsqueda de texto completo— **nunca menciona al
  > sistema 2 en ninguna parte de su documento**, lo que incumple la regla de
  > dependencias bidireccionales de `.claude/rules/design-docs.md`. La causa es
  > cronológica: Combate se aprobó el 2026-08-01, antes de que este GDD
  > existiera, y usó "sistema 20" como marcador de "el lado del jefe". El
  > reparto correcto es de **tres** partes:
  >
  > | Parte | Qué posee |
  > |---|---|
  > | Sistema 20 (IA de patrones) | **Duraciones y composición** — cuánto dura cada fase, qué golpes forman combo, qué patrones usan `Acción Especial` |
  > | Sistema 2 (este GDD) | **El emisor canónico** — los límites de estado de la FSM son lo que dispara los eventos |
  > | Combate (1) | **El consumidor** — resuelve el parry contra la ventana activa |
  >
  > **Enmienda pendiente en Combate** (edición mínima y no semántica): añadir al
  > sistema 2 a su tabla de Dependencies y reatribuir el origen de los eventos.
  > **Segunda enmienda, esta sí semántica**: la excepción declarada a su Regla 4
  > para el evento de Ventana Especial (Core Rule 5) — sin ella, su AC **C4**
  > (las cuatro consecuencias como paquete atómico) y la Core Rule 5 de este GDD
  > son mutuamente incumplibles.
- **IA de Combate de Jefes — Patrones (20)**: IA depende de este sistema.
  Consume el conjunto cerrado de estados top-level (Regla 7) y asigna, por
  patrón: duración de Telegrafiado/Golpe/Enfriamiento, composición de En Combo
  (`3 ≤ N ≤ 5`), y qué patrones usan Acción Especial (y si son interrumpibles).
- **Gestión de Run / Estructura de Ascenso (3)**: Gestión de Run depende de
  este sistema. Consume el evento "duelo ganado", emitido al entrar en
  `Muerto`. La secuencia completa de post-duelo no es propiedad de este GDD.
- **Lucifer — Dos Formas y Reactividad (11)**: dependencia futura, diferida.
  Este esqueleto **no** incluye un estado de transición de fase top-level, pero
  **sí declara la vía por la que el sistema 11 debe extenderlo**: sub-estado
  anidado dentro de un estado existente (típicamente `Acción Especial` con
  `interrumpible_por_parry = false`), sin enmienda y sin abrir el conjunto
  cerrado — ver Regla 7. El sistema 11 sigue siendo dueño de *qué* hace esa
  transición; este GDD solo fija *dónde* vive.
- **Sistema de Efectos de Estado (19)**: dependencia futura, no resuelta aquí.

## Formulas

Este sistema, en su rol de esqueleto de estados puro, **no posee cantidades
matemáticas propias**: todas sus "variables" son estados (enum) o flags
booleanos (`interrumpible_por_parry`), y todas las duraciones/umbrales que
menciona son propiedad declarada de otro GDD. No es una laguna — es el rol
esperable de un sistema de infraestructura cuyo trabajo es la topología de
transiciones, no el balance numérico.

Fórmulas y constantes que este sistema **consume sin poseer** (no redefinir
aquí si cambian — actualizar la referencia, no duplicar el valor):

| Fórmula/Constante | Fuente | Qué consume este sistema |
|---|---|---|
| `postura_dano` | Combate de Parry-Absorción (Fórmula 1) | Se aplica una sola vez por Golpe simple o por En Combo completo resuelto con éxito (Core Rule 3) |
| `postura_max` | Combate de Parry-Absorción (Fórmula 2) | Valor al que se restaura la Postura en ambas salidas de Aturdido |
| `dano_golpe_castigo` | Combate de Parry-Absorción (Fórmula 6) | **Única fuente de daño a la Vida del jefe.** Su salida acumulada es lo que hace alcanzable el estado `Muerto` (Core Rule 6, AC C6) |
| `retreat_base` | Combate de Parry-Absorción (constante, 42 ticks) | Duración de `Repliegue` en sus **tres** entradas: parry exitoso de un `Golpe`/`En Combo` (Core Rule 2), aborto de combo — el Repliegue diferido (Core Rule 3), y colchón tras Castigo conectado (Core Rule 4) |
| `gracia_ganada` | Combate de Parry-Absorción (Fórmula 7) | Se concede **completa** al interrumpir una `Acción Especial` con parry exitoso (Core Rule 5). Este GDD no fija la cantidad — solo declara que el evento la dispara |
| `recuperacion_recepcion` | Combate de Parry-Absorción (Recepción de golpe, 8–12 ticks) | Techo (**12**) usado como cota inferior de la invariante de la Core Rule 9 (piso de justicia de `Enfriamiento` + `Telegrafiado`) |
| `ventana_castigo` / `gracia_salida_castigo` | Combate de Parry-Absorción (constantes, 120 / 6 ticks) | Duración y ventana de gracia de salida de Aturdido |
| `longitud_combo` | Combate de Parry-Absorción (constante, rango 3–5) | Rango legal de repeticiones internas de En Combo |
| `physics_ticks_per_second` | Combate de Parry-Absorción (invariante, 60) | Toda duración de este esqueleto se autoriza en ticks enteros, nunca segundos de reloj real |

> **La alcanzabilidad de `Muerto` es contingente, no incondicional** (hallazgo
> de `systems-designer` en `/design-review`). Este GDD declara `Muerto` como
> estado terminal alcanzable, pero no posee ninguna de las cantidades que lo
> hacen alcanzable. Con la configuración actual está garantizado: la invariante
> **R4** de Combate cierra `multiplicador_ataque = 1.0` **por ambos lados**, así
> que `dano_golpe_castigo` no puede redondear a 0 ni ser negativo, y toda Vida
> finita se agota en un número finito de Golpes de Castigo. **Pero si un cambio
> futuro reabriera `multiplicador_ataque` por debajo de 1.0 hacia 0** —peligro
> que el propio GDD de Combate señala explícitamente en su Fórmula 6— el duelo
> se vuelve inganable y `Muerto` inalcanzable, sin que nada en *este* documento
> lo detecte. Cualquier retune de R4 debe reverificar esta sección.
>
> **Segunda contingencia, por la vía opuesta** (añadida en la 2ª pasada a
> hallazgo de `systems-designer`): R4 solo garantiza que **cada** Golpe de
> Castigo hace daño estrictamente positivo — no que la Vida del jefe converja a
> 0. Una `Acción Especial` de curación (Core Rule 5) que restaure Vida más
> deprisa de lo que el jugador puede quitarla hace el duelo **mecánicamente
> inganable** sin violar ninguna fórmula individual: exactamente el mismo modo de
> fallo que `multiplicador_ataque → 0`, por el otro extremo. Este esqueleto no
> puede detectarlo (no posee ni la curación ni la Vida del jefe); el sistema 20
> debe acotar la tasa de curación contra `dano_golpe_castigo` al autorar
> cualquier patrón que la use. Es la mitad cuantitativa del riesgo de "jefe con
> curación sin castigo" que `systems-index.md` ya anota en su mitad cualitativa.

> **Nota de alcance** (verificado por `systems-designer` en la fase de diseño):
> se evaluaron cuatro candidatos a fórmula propia de este sistema — piso de
> legibilidad de Telegrafiado, acoplamiento Repliegue/Enfriamiento tipo R6,
> conteo de Postura en combos, y un guard temporal en la salida de Aturdido.
> Los tres primeros pertenecen a otro sistema (sistema 20) o ya están resueltos
> en prosa sin necesidad de fórmula. El cuarto sí era un hallazgo real, pero se
> resolvió reutilizando `retreat_base` como colchón (Core Rule 4) en vez de
> introducir una fórmula/invariante nueva — ver la sección Core Rules.

## Edge Cases

| Escenario | Comportamiento esperado | Justificación |
|---|---|---|
| El jugador intenta un parry durante `Acción Especial`, y esa instancia no declaró ninguna Ventana Especial | Se resuelve como **whiff** (Combate, Regla 7) — `Acción Especial` por sí sola no es una ventana de parry activa. `interrumpible_por_parry = true` **no crea automáticamente** una Ventana Especial: el patrón de sistema 20 debe declararla explícitamente para que exista algo que parar | Evita una contradicción latente entre esta Core Rule y la Regla 3 de Combate. Si `interrumpible_por_parry = true` pero el patrón no declara ninguna ventana, la interrupción nunca puede dispararse — es una configuración incoherente que sistema 20 debe evitar, no algo que este GDD resuelva en runtime |
| El jugador **falla** el parry contra una Ventana Especial declarada (la ventana se cierra sin parry exitoso) | La ventana se cierra **sin dañar al jugador**; la `Acción Especial` continúa hasta su duración natural y se completa (el jefe consigue su habilidad) → `Telegrafiado`. **El estado `Acción Especial` nunca reduce la Vida del jugador, en ninguna rama** | Decisión de usuario en la 2ª pasada de `/design-review`. La Ventana Especial es una ventana de *oportunidad*, no un ataque: el castigo por fallarla es que la habilidad se completa. Que una curación fuese además un ataque sería doble castigo por un solo error y agravaría el riesgo de "jefe con curación sin castigo" de `systems-index.md`. Es también la razón por la que la Ventana Especial no puede reutilizar el contrato de `Golpe`: la Regla 6 de Combate hace que todo `Golpe` no parado reduzca la Vida del jugador |
| Sistema 20 configura `interrumpible_por_parry = false` **y además** declara una Ventana Especial | **Configuración ilegal**: falla ruidosamente al cargar/entrar (AC **C5d**). Una ventana que nada puede interrumpir es semánticamente vacía | Hacer ilegal la configuración cierra por construcción la colisión entre esta Core Rule ("con `false` ignora cualquier evento de Combate") y el **AC C5 de Combate** ("entra en Aturdido sin importar el estado"). Sin Ventana Especial bajo `false`, la Postura no puede cambiar durante ese estado (Core Rule 4) y la colisión es inalcanzable — no hay precedencia que adjudicar entre los dos documentos |
| El duelo termina por **derrota del jugador** (su Vida llega a 0) mientras el jefe está a mitad de `En Combo` o de `Acción Especial` | La FSM del jefe **se congela de inmediato**: no ejecuta ninguna transición más, libera sus temporizadores, descarta el índice `i` del combo en curso, y **no emite ninguna señal de transición** (en particular, nunca "duelo ganado"). El estado del jefe no impide, retrasa ni revierte la derrota | Espejo del **AC E7 de Combate**, que ya declara la prioridad absoluta de la derrota desde su lado pero no dice qué debe hacer esta FSM. `En Combo` es el único estado contenedor con bucle contado y temporizadores propios — es exactamente donde una terminación abrupta filtraría estado a la siguiente run si nadie declara el comportamiento |
| La interrupción de `Acción Especial` (parry exitoso) y su finalización natural por duración vencen en el mismo tick | Se prioriza la **interrupción** — se registra como interrumpida, nunca como completada | Un evento "parry exitoso" nunca debe ignorarse silenciosamente por un empate de temporización; es más seguro y consistente que la lectura "el jugador rompió esto" gane siempre el empate |
| El jefe llega a `Muerto` (Vida = 0) durante la resolución de un Golpe de Castigo | Transición directa e inmediata a `Muerto` — la Postura **no** se restaura en ese caso (a diferencia de la salida normal de Aturdido, que sí la restaura) | `Muerto` es terminal y tiene prioridad absoluta: restaurar la Postura de un jefe que ya no existe no tiene efecto útil y complicaría la implementación sin ninguna ganancia de diseño |
| El jefe solo puede entrar en `Muerto` desde `Aturdido` | Ninguna otra transición hacia `Muerto` existe en este esqueleto — `Telegrafiado`, `Golpe`, `En Combo`, `Repliegue`, `Enfriamiento` y `Acción Especial` nunca exponen la Vida del jefe a daño | El Golpe de Castigo es la única fuente de daño del jugador (Combate, Fórmula 6), y solo puede ejecutarse mientras el jefe está en `Aturdido` |
| El Golpe de Castigo **conecta** (instante de contacto) exactamente en el último tick de `ventana_castigo` | Se prioriza la **conexión** sobre la expiración — cuenta como Golpe de Castigo exitoso, no como ventana expirada. **Este esqueleto gobierna el instante de _contacto_, no el de _pulsación_** | Límite inclusivo, coherente con el precedente ya fijado por Combate para `parry_window`: nunca excluir un evento válido por un solo tick de borde. **Convención de conteo (normativa para este GDD)**: `restantes(T) = ventana_castigo − T`; en el tick 110 restan 10. El escenario es real pese a la regla de input de Combate: los Animation Feel Targets de Combate dan al Golpe de Castigo **6–8 ticks de inicio + 4–6 fotogramas activos**, así que un Castigo pulsado en el tick 110 (legal: restan 10 > 6) tiene su banda de contacto en los ticks **116–124** — el tick 120 cae dentro. *(La justificación anterior apelaba solo a "6–8 ticks de anticipación", con lo que el máximo era 110+8 = **118 ≠ 120** y el ejemplo no cerraba. Corregido en la 2ª pasada de `/design-review`: los ticks que faltaban salen de los fotogramas activos, que el texto no mencionaba.)* |
| El jugador **pulsa** el botón en el último tick de `ventana_castigo` (tick 120) | **No es un Golpe de Castigo** — la pulsación se reinterpreta como Parry, según la regla de desambiguación de input de Combate. Este esqueleto nunca ve un evento de Castigo en ese tick, así que no hay transición que resolver | Propiedad de Combate, no de este GDD: su regla exige `restantes > gracia_salida_castigo` (6) para clasificar la pulsación como Castigo, y en el tick 120 restan 0. **El último tick en que una pulsación puede clasificarse como Castigo es el 113**: con la convención `restantes(T) = 120 − T` de la fila anterior, en 113 restan **7 > 6** ✓, y en 114 restan **6**, y `6 > 6` es **falso** ✗. Se documenta aquí porque la fila anterior habla de "conectar" y sin esta aclaración las dos se leen como contradictorias. *(La versión anterior decía **114** resolviendo `120 − 6` como una igualdad en vez de la desigualdad **estricta** que la regla de Combate exige — habría desplazado el borde Castigo/Parry un tick, haciendo que `gracia_salida_castigo` se comportara como 7 en vez de 6. Corregido en la 2ª pasada. **Causa raíz señalada a Combate**: su prosa "los últimos 6 fotogramas" (= ticks 115–120) discrepa en un tick de su propia regla normativa de desambiguación, que es la que manda.)* |
| El jugador para 2 de 3 golpes de un combo y falla el tercero (`i = N = 3`) | El combo se aborta (Core Rule 3): el jefe sale a **`Repliegue`**, **sin** daño de Postura parcial por los 2 golpes ya parados. Fallar el golpe **final** es un aborto como cualquier otro — no una cuarta rama | Combate manda `Repliegue` en el aborto de combo en cuatro sitios: su **Regla 4** (excepción de combos), su **Regla 9** ("Fallo a mitad de combo"), su **Fórmula 4** (excepción) y su **AC D4**. La gracia de esos 2 parries sí se conserva (propiedad de Combate, ya absorbida); la consecuencia de estado es propiedad de este GDD, pero el destino lo fija Combate. *(La versión anterior de esta fila decía `Enfriamiento` y afirmaba "Coincide con la Regla 9 de Combate" — una cita que afirmaba una comprobación que nadie había hecho. Corregido en la 2ª pasada de `/design-review`.)* |
| Sistema 20 configura un patrón `En Combo` con N fuera del rango legal 3–5 | **Gate primario**: la validación en carga la posee el **AC C16 de Combate**, que ya exige que un patrón con `N=2` o `N≥6` falle la validación de datos al cargar, sin degradarse en silencio. **Defensa en profundidad**: además, al entrar en `En Combo`, este esqueleto asevera `3 ≤ N ≤ 5` y falla ruidosamente si no se cumple (AC **C7**) — nunca ejecuta un combo de longitud ilegal | El rango `3 ≤ N ≤ 5` es una restricción de autoría de contenido (Combate, R7 + diseño de audio), no una condición que pueda ocurrir válidamente en juego. La aserción propia no duplica la *propiedad* de la regla (sigue siendo de Combate): evita que un fallo del gate primario se manifieste como comportamiento indefinido silencioso dentro del bucle contado de la Regla 3 |

## Dependencies

| Sistema | Dirección | Naturaleza de la dependencia |
|---|---|---|
| Combate de Parry-Absorción (1) | Bidireccional | Este sistema provee los eventos "inicio/fin de Golpe" y "inicio/fin de Ventana Especial"; Combate provee de vuelta el resultado de cada Golpe ("parry exitoso"/"parry fallido") y la Postura resultante, que este sistema consume para bifurcar Repliegue/Aturdido/Enfriamiento. **Requiere dos enmiendas en el doc de Combate** — ver Interactions |
| IA de Combate de Jefes — Patrones (20) | Bidireccional, asimétrica | IA depende de este sistema para el conjunto cerrado de estados. Este sistema depende de IA para duraciones concretas y composición de patrones. **Este sistema le impone**: rango `3 ≤ N ≤ 5` (Regla 7), el piso de justicia de la **Core Rule 9**, y la prohibición de declarar Ventana Especial bajo `interrumpible_por_parry = false` (Core Rule 5) |
| Gestión de Run / Estructura de Ascenso (3) | Gestión de Run depende de este sistema | Consume el evento "duelo ganado", emitido al entrar en `Muerto` |
| Lucifer — Dos Formas y Reactividad (11) | Futura, diferida | Sin interfaz concreta, pero **con vía de extensión declarada**: sub-estado anidado (típicamente `Acción Especial` no interrumpible), no estado top-level nuevo — ver Regla 7 |
| Sistema de Efectos de Estado (19) | Futura, no resuelta | Si un futuro efecto de estado añade daño fuera del Golpe de Castigo, deberá declarar su interacción con `Muerto` |

**Clasificación por rigidez:**

- **Dura** (el sistema no puede funcionar sin ella): **Combate de Parry-Absorción
  (1)** — sin el resultado de cada Golpe (parry exitoso/fallido) y el valor de
  Postura, este esqueleto no puede resolver ninguna transición de salida.
- **Blanda** (el sistema funciona con valores por defecto hasta que exista):
  **IA de Combate de Jefes (20)** — este esqueleto puede operar con duraciones
  de placeholder para `Telegrafiado`/`Golpe`/`Enfriamiento` y sin ningún patrón
  usando `En Combo` o `Acción Especial` hasta que el sistema 20 exista. Esto es
  lo que permite que este sistema siga siendo capa Fundación pese a la
  dependencia mutua con el sistema 20 — mismo patrón que el ciclo
  Combate↔Gracia ya documentado en `systems-index.md`.

> **Nota de ciclo nuevo**: la dependencia mutua asimétrica con el sistema 20
> (dura en su dirección, blanda en la de este GDD) es del mismo tipo que el
> ciclo Combate↔Gracia (1↔5) que `systems-index.md` ya documenta
> explícitamente. Se propone añadir este ciclo (2↔20) a esa misma sección en la
> Fase 5 de este GDD (actualización del índice).

## Tuning Knobs

| Parámetro | Valor actual | Rango seguro | Efecto de aumentar | Efecto de disminuir |
|---|---|---|---|---|
| `interrumpible_por_parry` (por instancia de `Acción Especial`) | Decidido por patrón, propiedad de sistema 20 | Booleano — sin rango continuo | `true`: mitiga el riesgo de "jefe con curación sin castigo" ya anotado en `systems-index.md`, dando al jugador una vía de romper la habilidad — pero diluye la tensión de esa fase si se abusa en muchos patrones | `false`: la acción es intocable, más tensión dramática — pero reintroduce el riesgo de estancamiento si se usa en una habilidad de recuperación de Vida sin otro contrapeso |

> **Nota de alcance**: el resto de cantidades mencionadas en este GDD
> (`retreat_base`, `ventana_castigo`, `gracia_salida_castigo`, `longitud_combo`,
> y las duraciones de Telegrafiado/Golpe/Enfriamiento) son tuning knobs de
> otros sistemas (Combate o IA de Combate de Jefes) — ver Formulas y
> Dependencies para las referencias cruzadas. Este esqueleto no los redefine
> ni les añade un rango propio.

## Visual/Audio Requirements

> Extiende, sin contradecir, la "Regla de oro" y la filosofía de color ya
> fijadas en `design/art/art-bible.md` y en el Visual/Audio Requirements de
> Combate de Parry-Absorción: solo lo divino emite luz; silueta antes que
> detalle; lo que sale bien se comunica con vitral, lo que sale mal con
> ausencia de luz. Combate ya cubre el feedback de Telegrafiado, Golpe, Parry
> Justo, Fallo, Whiff, eventos de combo y Aturdido/Ventana de Castigo — esta
> sección solo cubre lo que Combate no toca: `Acción Especial` (nuevo),
> `Muerto` (Combate solo cubre la muerte del jugador) y el **`Repliegue`-colchón
> post-Castigo** (nuevo: lo inventó la Core Rule 4 de este GDD, así que Combate
> no sabe que existe).
>
> **Por qué el colchón necesita lectura propia** (hallazgo de `game-designer`,
> adjudicado a este GDD por `creative-director`): la Core Rule 4 hace que
> **acertar** el Golpe de Castigo conceda al jefe 42 ticks de `Repliegue`,
> mientras que **fallarlo** lo devuelve directo a `Telegrafiado`. La
> justificación mecánica es sólida —proteger la recuperación de 10–14 ticks del
> propio jugador—, pero si ese repliegue se ve y suena **idéntico** al repliegue
> rutinario post-parry, el jugador que acaba de clavar el golpe más grande del
> intercambio lee "lo hice genial y el jefe se llevó un respiro gratis". Es
> decir: una transición estructuralmente correcta percibida como arbitraria —
> exactamente el test negativo que la Player Fantasy declara como criterio de
> fracaso de este sistema.

| Evento | Feedback Visual | Feedback Audio | Prioridad |
|---|---|---|---|
| **Acción Especial inicia** | El jefe gana un aura sostenida y estable (no una fisura de ataque como el Telegrafiado) — debe ser distinguible por silueta de un Telegrafiado en el primer instante, sin esperar al tell sonoro | Tono sostenido/drone, distinto de los tells percusivos de Telegrafiado — comunica "esto no es un ataque" antes de que el jugador identifique el patrón | Alta |
| **Acción Especial interrumpida por parry** (`interrumpible_por_parry = true`) | El aura se fractura y se arranca de golpe — mismo lenguaje de "arrancar luz" que el evento 11 de Combate (Golpe de Castigo), no el de absorción del jugador | Corte abrupto y disonante — nunca una resolución suave, para que se lea como ruptura, no como final natural | Alta |
| **Acción Especial se completa sin interrupción** | El aura se resuelve con calma hacia su efecto (p. ej. curación aplicada) — contraste deliberado frente al corte de la interrupción | Cadencia resolutiva, no disonante — el jefe "lo consiguió" | Media |
| **`Repliegue` tras un Golpe de Castigo conectado** (el colchón de la Core Rule 4) | Debe leerse **distinto de un `Repliegue` post-parry rutinario**: el jefe retrocede acusando el golpe (postura quebrada, silueta encogida), no reposicionándose con compostura. El jugador debe leer "le hice daño y se está recomponiendo", nunca "se me escapó" | Cola de resonancia del impacto de Castigo que se apaga durante el repliegue — continuidad sonora con el evento 11 de Combate, no un cue nuevo e independiente | Alta |
| **El jefe entra en `Muerto`** | Su vitral se apaga y fragmenta por completo de una vez — inverso del evento de muerte del jugador (Combate, evento 13: ahí la tinta avanza; aquí la luz se extingue) | Acorde grave final, sin resonancia — silencio deliberado después, coherente con el peso dramático del duelo | Alta |

> **Nota de alcance**: el tratamiento narrativo/moral de la muerte del jefe
> (absorber/rechazar su esencia) pertenece al Sistema de Gracia (sistema 5),
> no a este GDD — aquí solo se especifica el flash de resolución de combate,
> no la decisión posterior.

## UI Requirements

Este sistema no tiene información propia que mostrar en pantalla — la Postura
y la Vida del enemigo ya son propiedad y responsabilidad de HUD de Combate
(sistema 13), que las consume directamente de Combate de Parry-Absorción, no
de este esqueleto de estados. Sin requisitos de UI propios.

## Acceptance Criteria

- [ ] **C1**: GIVEN un jefe entra en un duelo (`Reposo`), WHEN comienza el
      primer ataque, THEN transiciona a `Telegrafiado` y **no vuelve a `Reposo`
      en ninguno de los ≥50 ciclos simulados por C1b**, mientras la Vida del
      jefe sea > 0.
      *(Cota añadida en la 2ª pasada de `/design-review`: "en el resto del
      duelo" tenía el mismo defecto de forma —reclamo sin condición de parada—
      que motivó la corrección de C1b en la 1ª pasada, y nadie se la aplicó
      también a C1.)*
- [ ] **C1b**: GIVEN `Repliegue` o `Enfriamiento` vencen sus ticks, THEN
      transiciona a `Telegrafiado` y el ciclo continúa **durante al menos 50
      ciclos consecutivos en simulación sin desviarse de la topología ni
      acumular deriva de estado**, mientras la Vida del jefe sea > 0.
      *(Cota añadida en `/design-review` 2026-08-03: "indefinidamente" es
      correcto como intención de diseño pero no da a un test automatizado
      ninguna condición de parada.)*
- [ ] **C2a**: GIVEN un jefe en `Golpe`, WHEN el jugador lo para con éxito,
      THEN transiciona a `Repliegue` (si la Postura resultante es > 0) durante
      exactamente `retreat_base` ticks (actualmente 42).
- [ ] **C2b**: GIVEN un jefe en `Golpe`, WHEN el golpe conecta sin ser parado,
      THEN transiciona a `Enfriamiento` durante la duración asignada por el
      patrón (sistema 20).
- [ ] **C3a**: GIVEN `En Combo` de N golpes (3–5), WHEN los N golpes se paran
      con éxito, THEN se aplica daño de Postura exactamente una vez (calidad
      del último parry) y el jefe bifurca a `Repliegue` o `Aturdido`.
- [ ] **C3b**: GIVEN `En Combo` de longitud `N`, WHEN el golpe `i`
      (cualquier `i`, `1 ≤ i ≤ N`, **incluido `i = N`**) conecta, THEN el combo
      se aborta de inmediato, los golpes `i+1…N` nunca se ejecutan (conjunto
      vacío si `i = N`), no se aplica daño de Postura, el jefe transiciona a
      **`Repliegue`** (duración `retreat_base`, no `Enfriamiento`), **y el
      evento de aborto emitido incluye explícitamente los valores `i` y `N`** —
      verificado **leyendo el payload del evento capturado**, no infiriéndolo
      del estado resultante. Se prueba con al menos `i=1`, `i` intermedio e
      `i=N`.
      *(Destino corregido y cota `i < N` ampliada a `1 ≤ i ≤ N` en la 2ª pasada
      de `/design-review` — ver Core Rule 3. La aserción de payload se añade
      porque la Core Rule 3 la declara normativa desde la 1ª pasada y ningún AC
      la verificaba: un test pasaba en verde con el evento vacío, la misma forma
      de defecto que C4a corrigió.)*
- [ ] **C3c**: GIVEN `En Combo` de longitud `N`, WHEN el golpe `j` (`j < N`) se
      para con éxito y el combo continúa, THEN el jefe **no** transiciona a
      `Repliegue` ni a `Enfriamiento`, **no** se evalúa la bifurcación de la
      Regla 2, **no** se aplica daño de Postura, y transiciona directamente a
      `Telegrafiado` del golpe `j+1`, con el índice interno incrementado a
      `j+1`.
      *(Añadido en la 2ª pasada a señalamiento de `qa-lead`: la transición
      interna del combo —el caso más frecuente dentro del estado contenedor— no
      tenía ningún AC. Es el espejo de la segunda cláusula del AC **D4** de
      Combate, "no se dispara Repliegue en absoluto".)*
- [ ] **C4a**: GIVEN `Golpe`/`En Combo` se resuelve con éxito y la Postura
      resultante llega a 0, THEN **nunca se emite la señal/callback
      `state_entered(Repliegue)`** — la máquina despacha directamente
      `state_entered(Aturdido)`, y ambas comprobaciones se verifican
      aseverando el **orden y el conteo de señales dentro del mismo paso de
      resolución**, no consultando el estado tras el tick.
      *(Reescrito en `/design-review` 2026-08-03 a señalamiento de `qa-lead`.
      La formulación anterior —"en el mismo tick, sin frames intermedios"— era
      inverificable: un test que consulta `current_state` después del tick no
      puede detectar un `Repliegue.on_enter()` transitorio que ya arrancó un
      timer o disparó un VFX antes de ser sobrescrito, así que pasaría en
      verde con el bug presente. Nótese además "ticks", no "frames": este
      proyecto nunca cuenta frames de renderizado — ver Combate, Regla 2.)*
- [ ] **C4b**: GIVEN el jefe en `Aturdido` y el Golpe de Castigo conecta, THEN
      la Postura se restaura por completo y el jefe transiciona a `Repliegue`
      (duración `retreat_base`) antes de `Telegrafiado`.
- [ ] **C4c**: GIVEN el jefe en `Aturdido` y `ventana_castigo` expira sin
      conectar, THEN la Postura se restaura por completo y el jefe transiciona
      directo a `Telegrafiado`, sin colchón.
- [ ] **C4d**: GIVEN el jefe en `Telegrafiado`, `Enfriamiento`, `Repliegue`,
      `Reposo` o `Acción Especial`, WHEN llega cualquier evento de Combate,
      THEN la Postura del jefe **nunca cambia de valor**.
      *(Añadido en la 2ª pasada a señalamiento de `qa-lead`: "la Postura solo
      cambia en la resolución de un `Golpe`/`En Combo`" es la premisa silenciosa
      sobre la que descansa toda la garantía de no-preempción de la Core Rule 4,
      y no tenía ningún AC. E5 hacía lo análogo para la Vida; la Postura estaba
      sin cubrir.)*
- [ ] **C5a**: GIVEN `Acción Especial` con `interrumpible_por_parry = true` y
      una **Ventana Especial** declarada, WHEN el jugador la para con éxito,
      THEN se corta de inmediato y transiciona a `Enfriamiento`, **y se aplican
      exactamente 2 de las 4 consecuencias** del paquete de la Regla 4 de
      Combate: Gracia absorbida ✓ e hitstop ✓; daño de Postura ✗ y `Repliegue`
      ✗. Las cuatro se verifican explícitamente, las dos ausentes por conteo de
      llamadas en cero — no basta con comprobar el estado resultante.
- [ ] **C5b**: GIVEN `interrumpible_por_parry = false`, WHEN llega cualquier
      evento de Combate durante `Acción Especial`, THEN se ignora hasta
      completar su propia duración.
- [ ] **C5c**: GIVEN `Acción Especial` con Ventana Especial declarada, WHEN la
      ventana se cierra **sin** parry exitoso, THEN la Vida del jugador **no
      cambia**, la `Acción Especial` continúa hasta su duración natural, se
      completa, y transiciona a `Telegrafiado`. Se asevera además la invariante
      general: en ninguna rama de `Acción Especial` cambia la Vida del jugador.
- [ ] **C5d** (Config/Data, defensa en profundidad): GIVEN un patrón declara
      `interrumpible_por_parry = false` **y** una Ventana Especial, WHEN se
      carga o se entra en el estado, THEN **falla ruidosamente** y la
      configuración nunca se ejecuta. A diferencia de **E5**, aquí un `assert()`
      duro en build de debug/test **sí es correcto**: no se espera que se
      dispare nunca en producción, y su disparo indica un bug real de pipeline
      de datos, no un cambio de diseño previsto.
- [ ] **C6**: GIVEN un Golpe de Castigo deja la Vida del jefe en 0, THEN
      transiciona a `Muerto` de inmediato (sin restaurar Postura) y emite el
      evento "duelo ganado" exactamente una vez.
- [ ] **C7** (Config/Data, defensa en profundidad): GIVEN un patrón `En Combo`
      con `N` fuera del rango legal (`N ≤ 2` o `N ≥ 6`), WHEN el jefe intenta
      entrar en `En Combo`, THEN la entrada **falla ruidosamente** (aserción /
      error de carga) y el combo **nunca se ejecuta** — nunca se degrada en
      silencio a un combo truncado ni a un golpe simple. El gate primario sigue
      siendo el **AC C16 de Combate** (validación de datos al cargar); este AC
      solo verifica que un fallo de ese gate no produzca comportamiento
      indefinido dentro del bucle contado de la Regla 3.
- [ ] **C8**: GIVEN el enum de estados top-level compilado, THEN el **conjunto
      de sus nombres** es exactamente igual —comparado por identidad, no por
      cardinalidad— a la lista literal de la Regla 7: `Reposo`, `Telegrafiado`,
      `Golpe`, `En Combo`, `Repliegue`, `Enfriamiento`, `Aturdido`, `Acción
      Especial`, `Muerto`. Ni uno más, ni uno menos, ni uno **sustituido**.
      *(Reforzado en la 2ª pasada a hallazgo de `godot-specialist`: un test que
      comprobara solo `size() == 9` pasaría en verde si alguien renombra o
      sustituye un estado manteniendo el conteo — exactamente la regresión
      silenciosa que C8 dice existir para prevenir, solo que por sustitución en
      vez de por adición. La sub-fase interna y el índice `i` de `En Combo`
      (Regla 3) se representan como campos separados, **nunca** como valores
      adicionales de este enum.)*
      *(Añadido a propuesta de `qa-lead`: la comprobación cruzada contra los
      patrones del sistema 20 no puede ejecutarse hasta que ese sistema exista,
      pero el cierre del propio enum sí es automatizable hoy, y es el guardián
      de regresión el día que alguien añada un décimo estado sin pasar por el
      procedimiento de enmienda de la Regla 7.)*
- [ ] **C9** (Config/Data, defensa en profundidad — Core Rule 9): GIVEN
      cualquier patrón declarado por el sistema 20 que pueda seguir a un `Golpe`
      que conectó, WHEN se valida su configuración al cargar, THEN se cumple
      `duración(Enfriamiento) + duración(Telegrafiado) ≥ 12 + margen_reaccion_min`,
      y un patrón que la incumpla **falla la validación de datos**, nunca se
      ejecuta degradado en silencio. El test **no fija** `margen_reaccion_min`
      (es propiedad del sistema 20): asevera la desigualdad sobre los valores que
      el patrón declare. `12` es el techo del rango 8–12 de Recepción de golpe,
      consumido de Combate por referencia, no duplicado.
      *(Añadido en la 2ª pasada. Sin este AC, la Core Rule 9 sería prosa
      normativa sin criterio verificable — exactamente el patrón que este
      documento critica en otros sitios.)*
- [ ] **E1**: GIVEN `Acción Especial` sin Ventana Especial declarada, WHEN
      el jugador intenta un parry, THEN se resuelve como whiff, nunca como
      interrupción.
- [ ] **E2**: GIVEN la interrupción (parry exitoso contra la Ventana Especial)
      y la finalización natural por duración de `Acción Especial` vencen en el
      mismo tick, THEN se asevera el **orden y el conteo de señales dentro del
      mismo paso de resolución**: la señal/callback de finalización natural
      (`state_completed` o equivalente) **nunca se emite**, y la máquina
      despacha directamente la de interrupción — verificado sobre la secuencia
      de emisiones capturada, **no** consultando el estado tras el tick.
      *(Reescrito en la 2ª pasada de `/design-review` a señalamiento de
      `qa-lead`. La Regla 8 nombra **dos** casos que exigen verificación por
      contrato de señales —la sustitución `Repliegue → Aturdido` (C4a) y este
      desempate— y la 1ª pasada solo corrigió el primero. E2 conservaba la misma
      formulación inverificable que C4a tenía: con una implementación que llama
      `on_complete()` y luego `on_interrupted()`, o que dispara un VFX de "acción
      completada" antes de sobrescribirlo, un test que lee el estado final ve
      "interrumpida" y pasa en verde con el bug presente.)*
- [ ] **E3**: GIVEN el Golpe de Castigo **impacta** (instante de contacto)
      exactamente en el último tick de `ventana_castigo` (tick 120), THEN cuenta
      como conexión (→ `Repliegue`), no como expiración. Caso de prueba
      concreto: pulsación en el tick 110 (legal: `restantes = 120 − 110 = 10 > 6`)
      cuyo contacto cae en el tick 120, dentro de la banda de contacto 116–124
      que producen los 6–8 ticks de inicio más los 4–6 fotogramas activos del
      Golpe de Castigo (Combate, Animation Feel Targets).
- [ ] **E3b**: GIVEN el jugador **pulsa** el botón en el tick 120, THEN este
      esqueleto **no recibe ningún evento de Golpe de Castigo** (Combate lo
      reinterpreta como Parry) y el jefe sale de `Aturdido` por expiración
      (→ `Telegrafiado`, sin colchón, per C4c). El último tick en que una
      pulsación puede clasificarse como Castigo es el **113**: la regla de
      Combate exige `restantes > gracia_salida_castigo` (desigualdad
      **estricta**), y con `restantes(T) = 120 − T` eso da `T < 114`, es decir
      `T ≤ 113`. Verificable en ambos lados del borde: 113 → Castigo, 114 →
      Parry.
      *(Cifra corregida de 114 a 113 en la 2ª pasada de `/design-review`: la
      versión anterior resolvía `120 − 6` como igualdad en vez de la desigualdad
      estricta, desplazando el borde un tick.)*
      *(E3/E3b desdoblados en `/design-review` 2026-08-03: `systems-designer`
      leyó el AC original como una contradicción con la regla de input de
      Combate y `qa-lead` lo dio por válido. Ambas lecturas eran correctas
      sobre cosas distintas — el AC original no decía si gobernaba la pulsación
      o el contacto, y esa ambigüedad es exactamente la que Combate se molestó
      en resolver para el input.)*
- [ ] **E4**: GIVEN el jugador para 2 de 3 golpes de un combo y falla el
      tercero, THEN no se aplica ningún daño de Postura parcial y el jefe sale a
      **`Repliegue`**.
      **Nota de cobertura**: es la **instancia `i = N` de C3b** (`i=3, N=3`) —
      el caso del remate fallado. Se conserva por su valor como test de
      regresión legible, pero `/regression-suite audit` no debe contarlo como
      cobertura adicional sobre C3b.
      *(La nota anterior lo etiquetaba como "instancia de C3b (`i < N` con
      `i=3, N=3`)" — y `3 < 3` es falso. El ejemplo que ilustraba la regla
      violaba la condición literal de la regla, revelando que fallar el último
      golpe no caía en ninguna rama. Corregido en la 2ª pasada.)*
- [ ] **E5**: GIVEN el jefe está en cualquier estado ≠ `Aturdido`, WHEN se
      resuelve cualquier evento de Combate, THEN la Vida del jefe nunca
      cambia y no puede producirse una transición a `Muerto`.
      **El test automatizado (gate Logic) debe aseverar esto de forma dura —
      fallar en rojo si se viola**, con independencia de cómo se comporte el
      código de producción. Cuando el sistema 19 introduzca daño fuera de
      `Aturdido` por diseño, este AC debe **reescribirse o retirarse
      explícitamente**, nunca dejarse fallando en rojo de forma permanente ni
      relajarse hasta dejar de bloquear.
      *(Separación de capas añadida en la 2ª pasada a señalamiento de `qa-lead`:
      E5 está clasificado Logic BLOCKING, pero la nota de abajo —correcta para
      producción— podía leerse como que el propio test tampoco debía fallar en
      rojo, con lo que el gate dejaba de bloquear nada en CI.)*
      **Nota de implementación de producción, no aplica al test**
      (`ai-programmer`): la comprobación en runtime
      debe ser una **aserción blanda con log de aviso**, nunca un `assert()`
      duro que aborte la ejecución. Esta garantía es verdadera **hoy** porque el
      Golpe de Castigo es la única fuente de daño, pero el Sistema de Efectos de
      Estado (19) introducirá daño fuera de `Aturdido` (quemadura/veneno por
      tríada) y **romperá E5 por diseño**. Un `assert()` duro convertiría la
      llegada del sistema 19 en builds que revientan; un aviso registrado
      convierte esa misma llegada en la señal de que toca revisar esta sección
      — ver Open Questions.
- [ ] **Config/Data**: `retreat_base`, `ventana_castigo`,
      `gracia_salida_castigo` y `longitud_combo` se consumen por referencia
      desde el recurso de datos de Combate — ningún valor literal duplicado en
      el código de la máquina de estados.
- [ ] **Visual/Feel** (ADVISORY, evidencia de playtest en
      `production/qa/evidence/`, no automatizable): con **un mínimo de 5
      playtesters**, cada uno habiendo jugado **al menos 2 jefes distintos**
      (para que la consistencia entre jefes sea observable), **ninguno** describe
      espontáneamente una transición de estado como "mecánica", "que se traba" o
      inconsistente entre jefes — verifica el test negativo ya declarado en
      Player Fantasy. Se registra por observación espontánea, no preguntando
      dirigidamente "¿te pareció mecánico?", que induce la respuesta.
      *(Protocolo añadido en `/design-review` 2026-08-03: tal como estaba, la
      opinión de un solo playtester podía voltear el veredicto del AC.)*

> **Nota sobre la restricción arquitectónica (Core Rule 7 — conjunto cerrado
> de 9 estados)**: se verifica en **dos mitades**, una automatizable hoy y otra
> diferida.
> - **Cierre del enum — automatizable ya**: el AC **C8** asevera que el enum
>   compilado contiene exactamente los 9 valores. No depende del sistema 20 y es
>   el guardián de regresión si alguien añade un décimo estado sin pasar por el
>   procedimiento de enmienda de la Regla 7.
> - **Conformidad de los patrones — gate documental diferido**: que ningún
>   patrón del sistema 20 introduzca un estado top-level fuera de los 9 no puede
>   probarse hasta que ese sistema exista. Cuando se autore su GDD,
>   `/design-review` (o `/story-readiness` de sus historias) debe verificarlo.
>
> *(La versión anterior de esta nota declaraba la Regla 7 entera como no
> ejecutable por QA. Era cierto solo para la segunda mitad — `qa-lead` señaló en
> `/design-review` que nada impedía cerrar la primera hoy mismo.)*
>
> **Nota de tipo de test — DOS gates obligatorios, no uno** (`qa-lead`,
> reformulado en `/design-review` 2026-08-03). La versión anterior clasificaba
> el sistema solo como **Integration** y mencionaba el test unitario como
> "recomendado". Eso hacía que, en la práctica, únicamente el test de
> integración fuera exigible — y la cobertura de topología, que abarca **casi
> todos los ACs de este documento** (C1–C8, E1–E5), pudiera saltarse en
> silencio sin que ningún gate lo detectara. Se desdobla explícitamente
> *(cobertura ampliada en la 2ª pasada con C3c, C4d, C5c, C5d y C9)*:
>
> | Gate | Tipo | Ubicación | Cubre |
> |---|---|---|---|
> | **1** | **Logic** (BLOCKING) | `tests/unit/maquina-estados-jefe/` | Toda la topología de estados con los eventos de Combate **mockeados**: C1, C1b, C2a/b, C3a/b/c, C4a/b/c/d, C5a/b/c/d, C6, C7, C8, C9, E1–E5 |
> | **2** | **Integration** (BLOCKING) | `tests/integration/maquina-estados-jefe/` | Únicamente el **contrato de cableado** con Combate real: que los eventos "inicio/fin de Golpe", "inicio/fin de Ventana Especial" y "parry exitoso/fallido" crucen la frontera correctamente, y que la resolución síncrona de la Regla 8 se cumpla de verdad fuera del mock — **en sus dos casos nombrados: C4a (`Repliegue → Aturdido`) y E2 (desempate de `Acción Especial`)**, no solo el primero |
>
> El reparto no es burocracia: el gate 1 es donde se prueba **qué debe pasar**, y
> es rápido y determinista; el gate 2 es donde se prueba **que los cables están
> puestos**, y es el único capaz de cazar el fallo de orden de proceso que la
> Regla 8 previene — un mock que llama sincrónicamente al FSM **pasaría el gate 1
> aunque la implementación real fuese asíncrona**. Justificación original de la
> mockeabilidad, que sigue vigente: inyectar los eventos de Combate como
> dependencia sustituible para poder testear la topología de estados como
> **Logic** pura en
> `tests/unit/maquina-estados-jefe/`, reservando un test de integración más
> ligero para el ciclo completo con Combate real.

## Open Questions

| Pregunta | Propietario | Resolución objetivo | Estado |
|---|---|---|---|
| Si un futuro Sistema de Efectos de Estado (sistema 19) añade daño a la Vida del jefe fuera del Golpe de Castigo (p. ej. quemadura/veneno por tríada), ¿cómo interactúa con `Muerto` y con la restricción E5 ("la Vida solo cambia en Aturdido")? | GDD de Sistema de Efectos de Estado (sistema 19) | Al autorar sistema 19 | Abierta — este GDD asume una única fuente de daño (Combate, Fórmula 6); un efecto de estado que dañe fuera de Aturdido rompería E5 tal como está escrito hoy |
| ~~¿Cómo extiende Lucifer (sistema 11) este esqueleto para sus dos formas?~~ | ~~Sistema 11~~ → **este GDD** | — | **RESUELTA** (`/design-review` 2026-08-03, decisión de usuario). Sigue sin haber estado de transición de fase top-level, pero la **vía** ya no está indefinida: sub-estado anidado dentro de un estado existente, sin enmienda (Regla 7). Cierra la crítica de `ai-programmer` de que el conjunto cerrado estaba "cerrado a la espera de una enmienda que ya sabemos que viene". Lo que sigue siendo propiedad del sistema 11 es *qué* hace la transición, no *dónde* vive |
| ¿Qué valores de placeholder usa un ingeniero para probar este esqueleto de forma aislada (duraciones de Telegrafiado/Golpe/Enfriamiento) antes de que exista el sistema 20? | `/test-setup` / `dev-story` | Antes del primer sprint de implementación | Abierta — dependencia blanda ya documentada en Dependencies, pero sin valores concretos de prueba |
| ¿Cuál es el **mecanismo concreto** que garantiza la resolución síncrona de la Regla 8? Es decir: ¿nodo autoritativo de tiempo que llama al FSM, `process_priority` explícito entre el nodo de Combate y el del jefe, o despacho directo por llamada de método sin señal intermedia? La Regla 8 fija **qué debe ser cierto** (nada fuera del call stack síncrono que originó la resolución) pero deliberadamente no elige el cómo — y declara conformes **tanto** la llamada directa **como** la señal no diferida | `/create-architecture` (probable ADR) | Antes del primer sprint de implementación | Abierta — **es el punto de mayor riesgo técnico de este GDD**. `godot-specialist` confirmó que Godot 4.7 no garantiza orden de ejecución entre nodos con `_physics_process` independientes salvo vía `process_priority`, y que el modo de fallo es un tick de retraso silencioso, no un crash. Debe resolverse con un ADR, no improvisarse en `dev-story`. El ADR debe además fijar los **nombres canónicos de señal** (`snake_case`, tiempo pasado, per `coding-standards.md`), que hoy solo existen en prosa |
| ~~La sub-ventana de Golpe que `Acción Especial` puede declarar internamente — ¿reutiliza el contrato de eventos de un Golpe normal o necesita su propio evento distinto?~~ | ~~Sistema 20~~ → **este GDD** | — | **RESUELTA** (2ª pasada de `/design-review`, 2026-08-03, decisión de usuario). **Evento propio**: `inicio`/`fin de Ventana Especial`, distinto del par de `Golpe`. Reutiliza la semántica de temporización, no la identidad de evento. `calidad_timing` (Fórmula 1) no juega ningún papel — no hay daño de Postura que modular. Ver Core Rule 5. Era la única vía de cumplir a la vez la garantía de "sin Postura ni Repliegue" y el AC **C4** de Combate |
| ¿Qué valor toma `margen_reaccion_min` en la invariante de la Core Rule 9 (piso de justicia)? Este GDD declara la forma de la desigualdad pero deliberadamente no elige el número | Sistema 20 / playtesting | Al autorar sistema 20 | Abierta — el AC **C9** asevera la desigualdad sobre los valores que el patrón declare, así que es verificable sin fijar el número hoy |
| ¿Qué sistema **consume** el índice `i` y la longitud `N` del evento de aborto de combo para diferenciar el feedback de "fallé el primero" vs. "clavé 4 de 5"? Este GDD solo expone el dato | Feedback de Impacto (4) y Feedback Sonoro (16), coordinado por `/architecture-review` | Al autorar los sistemas 4 y 16 | Abierta — señalado por `game-designer` en la 2ª pasada: el dato está expuesto pero ningún GDD declara todavía que vaya a leerlo, así que el problema de percepción original podría reaparecer intacto pese al arreglo del esqueleto. Es un hueco de **trazabilidad**, no un defecto de este documento |
| ¿Debe el evento "duelo ganado" llevar algún dato adicional (qué jefe, qué tríada, tiempo del duelo) que Gestión de Run o Meta-progresión de Llaves necesiten, o basta con la señal booleana? | GDD de Gestión de Run (sistema 3) | Al autorar sistema 3 | Abierta — este GDD solo declara que el evento se emite, no su payload |
| ¿Debe el colchón de `Repliegue` tras un Castigo conectado (42 ticks, reutilizando `retreat_base`) tener su propia duración distinta a la del Repliegue post-parry normal, si el playtesting revela que el contexto (justo tras un Golpe de Castigo pesado) se siente distinto a un parry en medio de un intercambio? | Playtesting | Tras el slice vertical | Abierta — decisión deliberada de reutilizar la constante existente en vez de crear una nueva; revisar si el feel lo justifica |

# Combate de Parry-Absorción

> **Status**: **NEEDS REVISION (2026-08-04, 3ª pasada de `/design-review --depth full`)** — 8 especialistas + síntesis de `creative-director`, con `qa-lead` entregando. **Changeset 1 (mecánico, sin decisiones) está APLICADO**; queda pendiente el **changeset 2 (decisiones), que por decisión de proceso NO se ejecuta en la sesión que lo descubre.** Los tres ítems del changeset 2 son: **(1)** granularidad de input + decisión analógico/digital, con reverificación de R2/R6/C2/C13/C18; **(2)** restricciones al sistema 9 reformuladas **a nivel de magnitud** (cierra R5/`bono_reliquias`, la reliquia estructural y la colisión R4→Vida de una vez); **(3)** ejecución de la **opción C** de Ventana Especial ya decidida por el usuario — perfil VFX reutilizado del evento 3, firma perceptual "Gracia se mueve / Postura no", una capa de audio diferenciada y cláusula anti-silencio calcada del evento 12 — con su cascada a P0/P5. **Regla obligatoria para el changeset 2: los ACs primero, la prosa normativa después** (lección registrada al cierre de la 2ª pasada, tres veces escrita y cero veces ejecutada). Ver `reviews/combate-parry-absorcion-review-log.md`, entrada del 2026-08-04 (3ª pasada).
> **Changeset 1 — aplicado el 2026-08-04**: 3 falsedades vivas corregidas (`hitstop_parry` 3–8→3–6 en Impact Moments · fila de Edge Cases del castigo acotada a no letal + fila hermana letal · **clamp de Vida del jefe**, que faltaba pese a que E5 ya clampaba la Postura) · Fórmula 4 y **D4** acotados a `Golpe` · **C19–C21 marcados bloqueado** con fixture de disparador de depuración · **D9 con predicado corregido** (partido en (a) config de lanzamiento y (b) barrido caracterizado contra tabla de veredictos) **+ R8 añadido** · **E12** nuevo (overkill de Vida) · segunda esquina fallida de **R5** documentada (`(15×3)/80 = 56.25%`) · audio clasificado en el bucket diegético de la Regla 2 · `Engine.max_physics_steps_per_frame` como confundidor declarado de C13/P4 · **C12b (riesgo vivo, puerta de release) separado de D10 (diferido)** · nota "Sobre R8" · P1 declarado fixture de E11 · ordenación inalcanzable de la tabla de prioridad anotada · pool de emisores por `finished`, no por `emitting`.
> **Changeset 2 — ítem 0 aplicado el 2026-08-04** *(los ACs primero, la prosa normativa después — la regla se ejecutó, no solo se escribió)*: **Fórmula 8 (`dano_golpe_enemigo`)** creada, anclada en `vida_base` y **no** en `vida_maxima`, sin escalado por tríada ni multiplicador por tipo de ataque, con `golpes_para_morir_base = 4` → **25** · **R9a** (al sistema 20: banda `1.0 ≤ severidad_accion_especial ≤ 2.0` por Ventana Especial **y** `Σ ≤ golpes_para_morir_base − 1` por duelo, pagada en Vida) y **R9b** (al sistema 5: la Gracia de una VE parada debe tener coste no nulo), que juntas cierran la **Ventana Especial dominada por ignorarla** — el hallazgo de `game-designer` perdido en la síntesis de la 3ª pasada · **regla de clamp de la Vida del jugador**, que nunca existió pese a que el changeset 1 la escribió para la del jefe (4ª aparición de la raíz **C**) · corolario de la Regla 6 acotado a **la ventana**, separado de la completación de la habilidad · 6 ACs nuevos (**C22, C23, D11, D12, D13, E13**) · 2 knobs nuevos · **R9 declarada fuera de D9 explícitamente**, para no repetir la omisión silenciosa que sufrió R8. **Hallazgo registrado y NO cerrado**: R5 acota la razón en Vida (54%) pero el swing en golpes sobrevividos es +75% por redondeo — va a la 4ª pasada. **Pendientes del changeset 2**: ítems 1, 2 y 3 (el 3 queda **desbloqueado** por éste).
> **Changeset 2 — ítem 1 aplicado el 2026-08-04** *(ACs primero, otra vez)*: **el control de parry es DIGITAL** —ningún eje analógico mapeable, validación de bindings que falla al cargar— y `technical-preferences.md` corregido en el mismo changeset · **`umbral_precision` canonicalizado a 5 ticks** (rango 3–7): era la **última duración del documento declarada en segundos**, con el mismo defecto de 4.8 ticks no enteros que la regla normativa 3 de la Regla 2 ya había corregido para `hitstop_parry` — el barrido visitó las duraciones de la máquina de estados y se saltó la única que vive dentro de una fórmula (**raíz A**) · **`calidad_timing` declarada escalonada**: 7 valores exactos indexados por `Δ` en ticks, con corrección de medio tick por el sesgo de muestreo · **umbral de Parry Justo declarado** (`umbral_parry_justo = 0.9`) y `bono_hitstop_parry_justo` promovido de prosa a knob con reparto por escalón — el término tenía **cinco consumidores y ninguna magnitud** (**raíz C**, 5ª aparición) · **sub-tick descartado y declarado descartado**: `InputEvent.get_timestamp()` no aparece en la referencia de motor, que además está desfasada a 4.6 · **R2 reescrita como comparación entera** (desaparece el `× 60`) · 4 ACs nuevos (**C24, C25, D14** + **D1 reescrito**) · 3 knobs · 2 Open Questions cerradas, 1 abierta como tarea de referencia de motor · gap 1 de testabilidad cerrado.
> **Changeset 2 — ítem 2 aplicado el 2026-08-04** *(ACs primero, tercera vez)*: **el contrato con el sistema 9 se reescribe sobre MAGNITUDES, no sobre mecanismos** — invariante **R10** con cuatro cláusulas: `golpes_sobrevividos` (+1 como máximo sobre el valor sin reliquias, **para las cuatro cuentas de absorción**), `ciclos_efectivos` exacto **contando ciclos de Aturdido, no golpes de castigo**, `parries_por_ciclo` exacto a `calidad_timing = 0`, y cobertura temporal efectiva (R6/D10, foliada aquí). Cierra los **tres** agujeros de una edición y **uno más que no estaba en la lista**: la reducción de daño recibido, que la Fórmula 8 del ítem 0 acababa de hacer posible y que además aflojaba en silencio la cláusula agregada de R9a. Decisiones de usuario: reliquias **+1 golpe máximo**, magnitudes ofensivas **cerradas exactamente**. Espacio que le queda al sistema 9: **+25 de Vida** o **−20% de daño recibido** (no ambos), modificadores de ventana bajo R10d, utilidad pura · **hallazgo de R5 CERRADO**: medía puntos donde la magnitud son golpes; R10a lo mide en la unidad correcta y sobre los tres términos de la suma, y R5 queda como guarda del par de knobs · 3 ACs nuevos (**C26, D15, D16**) · `bono_reliquias` deja de ser "0+" · **R10 declarada fuera de D9 explícitamente**, como R9. **Pendiente del changeset 2**: solo el ítem 3.
> **Changeset 2 — ítem 3 aplicado el 2026-08-04. CHANGESET 2 COMPLETO.** Ejecución de la **opción C** de Ventana Especial: **eventos 14, 15 y 16** en la tabla de Visual/Audio —la VE era una ventana parable de primera clase **sin una sola fila**, raíz **B** y uno de los ocho sitios de la raíz **A**— con perfil VFX del evento 3 reutilizado íntegro, firma **"Gracia se mueve / Postura no"**, capa de audio diferenciada y cláusula anti-silencio calcada del evento 12 · **nota de propiedad del feedback** (los tres instantes de parry son de este GDD; la completación y la interrupción son del sistema 2) · **P0/P5 declarados sin cambio con su justificación normativa**, no supuesta: ningún emisor nuevo y ningún pico de concurrencia nuevo, porque la `Acción Especial` está fuera del ciclo · 3 ACs nuevos (**V5, V6, V7**). **Dos correcciones que este ítem destapó**: **(1)** el ítem 1 dejó `calidad_timing` y **C25** cuantificados sobre la **unión**, de modo que un parry preciso contra una VE disparaba la firma completa de Parry Justo sobre la única interacción que no concede beneficio de combate — raíz **A** dentro de una enmienda escrita para cerrar la raíz A; acotados a `Golpe`. **(2)** **R9a contradecía frontalmente al sistema 2**, que declara dos veces que la `Acción Especial` **nunca reduce la Vida del jugador**: el ítem 0 fijó la moneda sin comprobar su tabla de Edge Cases. **Decisión de usuario: la severidad pasa a ser una EQUIVALENCIA**, no un pago en Vida, con regla de conversión derivada de la tasa de acierto del prototipo (0.72) — reescritos **R9a, C22, C23 y D13**. Acota además, por primera vez, el riesgo alto sin mitigación de la curación de jefes. **Deuda registrada**: el sistema 2 no tiene fila de feedback para la completación ni evento declarado para ella — va a su 4ª pasada.
> **Author**: usuario + agentes especialistas
> **Last Updated**: 2026-08-04
> **Enmiendas forzadas del 2026-08-04** *(aplicadas sin revisión, por decisión de plan — ver `reviews/maquina-estados-jefe-review-log.md`, entrada del 2026-08-04, fase 2)*: **(A)** término normativo **«ventana parable»** y requantificación de las Reglas 3 y 7, que estaban cuantificadas solo sobre `Golpe` y hacían indisparable `interrumpible_por_parry` (raíz **R2**) · **(B)** `i < N` → `1 ≤ i ≤ N` en el AC C15 · **(C)** `recuperacion_recepcion` promovido de prosa a símbolo con propietario, rango y regla de consumo · **(D)** propiedad única del par «duelo ganado» / «duelo perdido» · **(E)** `restantes(T)` declarado por este GDD, con conteo **inclusivo** y borde en **114** (raíz **R5**) · **(F)** los dos ACs que la enmienda de Ventana Especial nunca añadió · **(G)** acotación de la Regla 5 y el AC E10 al Golpe de Castigo **no letal**.
> **Enmiendas anteriores**: 2026-08-03, durante la 2ª pasada de `/design-review` de `maquina-estados-jefe.md` (sistema 2). **(1) No semántica**: se reconoce al sistema 2 como emisor canónico de los eventos de ventana activa (Regla 1, Interactions, Dependencies) — este documento se aprobó antes de que ese GDD existiera y atribuía los eventos al sistema 20, incumpliendo la regla de dependencias bidireccionales. **(2) Semántica**: nueva **excepción de Ventana Especial** en la Regla 4 (solo 2 de las 4 consecuencias del parry exitoso), con su corolario en la Regla 6 (no daña al jugador) y la acotación correspondiente del AC **C4**. Sin ella, C4 y la Core Rule 5 del sistema 2 eran mutuamente incumplibles. **La enmienda (2) no ha pasado revisión adversarial** — el clúster Regla 4 / Regla 6 / C4 debe re-verificarse.
> **Last Verified**: 2026-08-01 — 2ª pasada de `/design-review` (7 especialistas + síntesis de `creative-director`; 10 clústeres bloqueantes resueltos, 4 decisiones de diseño del usuario) **+ verificación de alcance reducido** (`systems-designer`, `qa-lead`, `godot-specialist`) que confirmó los 10 cerrados y aportó 11 residuos, también aplicados. 49 ACs, invariantes R1–R8. Sin bloqueantes abiertos.
> **Implements Pillar**: Pilar 2 (La maestría está en las manos, no en la ficha) — también sostiene el Pilar 1 (El poder duele)

## Summary

El Combate de Parry-Absorción es el verbo central de NOVENA: el jugador para el
ataque de un ángel en el instante exacto, y ese parry no solo lo protege — le
arrebata al ángel una fracción de su gracia. Es el sistema del que absolutamente
todo lo demás depende: sin un parry que se sienta justo y satisfactorio, ninguna
capa narrativa o de progresión tiene sobre qué construirse.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

Cada duelo contra un ángel es una conversación de temporización: el ángel
telegrafía un ataque, y el jugador tiene una ventana breve para presionar el botón
de parry. Mecánicamente, el sistema define una ventana de tiempo durante la cual el
input del jugador queda "activo" y puede resolverse contra el golpe entrante,
otorgando perdón tanto si el jugador se anticipa como si reacciona en el instante
justo del impacto — nunca exige precisión de fotograma único. Para el jugador esto
no se siente como bloquear un golpe: se siente como robarle algo a un ser superior
en el único instante en que es vulnerable. Este sistema existe porque es la
fantasía central del juego (Pilar 2): la maestría del jugador, no un árbol de
habilidades, es lo que determina si sobrevive — y cada parry exitoso alimenta
directamente el Sistema de Gracia, haciendo que el momento de habilidad pura sea
también el motor de la tragedia del protagonista.

## Player Fantasy

El jugador debe sentir que está desarmando a un ser superior con las manos
desnudas y el tiempo justo — no defendiéndose, sino ganando terreno en cada
intercambio. La sensación objetivo es la misma que reportó el desarrollador tras
el prototipo: **superación** — el instante en que el timing deja de sentirse
aleatorio y empieza a sentirse gobernado por la propia destreza. No es la
satisfacción de un bloqueo tipo escudo; es más cercana a un duelo de esgrima
donde parar **es** atacar. La referencia explícita de sensación es Sekiro: la
ventana de parry castiga con dureza el error, pero recompensa con una claridad
brutal el acierto.

A diferencia de Sekiro, aquí cada acierto tiene un segundo significado no
deseado: el jugador no solo gana el intercambio, también pierde un poco de sí
mismo. Esa ambivalencia —soy hábil / me estoy destruyendo— es la fantasía
completa, no un efecto secundario de ella.

> **Frontera de propiedad de la fantasía** (aclaración de revisión adversarial). Este
> GDD **posee y verifica la mitad "soy hábil"**: sus Feel Acceptance Criteria prueban
> la superación, la legibilidad y la justicia del timing. La mitad "me estoy
> destruyendo" se **manifiesta** aquí —de forma mecánica y real, vía la Fórmula 7:
> los combos son ricos en gracia y pobres en Postura, así que los ángeles rápidos te
> corrompen más deprisa por cada punto de progreso— pero se **verifica** en el GDD
> del Sistema de Gracia (5), que es quien posee la acumulación y la transformación.
> Esta división es deliberada y es lo que permite que Combate siga siendo capa
> Fundación: un sistema Fundación que dependiera duro de un sistema Núcleo sin
> escribir rompería el layering que hace posible construirlo primero. Ver la
> clasificación dura/blanda en Dependencies.

## Detailed Design

### Core Rules

El bucle "parar → romper compostura → castigar" ya está declarado en
`game-concept.md` — este sistema implementa esa cadena, no la inventa.

1. **Ciclo de golpe enemigo**: cada ataque pasa por Telegrafiado → Golpe (ventana
   activa) → Enfriamiento, en bucle. Las duraciones de fase las define la IA de
   Combate de Jefes (sistema 20); el **emisor canónico** de los eventos es la
   **Máquina de Estados de Jefe (sistema 2)**, cuyos límites de estado son lo
   que los dispara; este GDD solo los consume. *(Atribución corregida en la 2ª
   pasada de `/design-review` del sistema 2, 2026-08-03: este documento se
   aprobó antes de que ese GDD existiera y usaba "sistema 20" como marcador de
   "el lado del jefe".)*

   > **Término normativo — «ventana parable»** *(añadido el 2026-08-04, enmienda A)*.
   > Una **ventana parable** es cualquier intervalo emitido por el sistema 2 durante el
   > cual un parry del jugador puede resolverse como éxito. Hoy son **exactamente dos**:
   > el `Golpe` (esta regla) y la **Ventana Especial** (Regla 4). Las Reglas 3 y 7 se
   > cuantifican sobre *toda ventana parable*, **nunca sobre `Golpe`**.
   >
   > Lo que cada tipo de ventana produce **al resolverse** sí difiere, y eso lo decide la
   > Regla 4, no ésta: **la clasificación como parable y las consecuencias del parry son
   > cuestiones separadas.** Si el sistema 2 declarase un tercer tipo de ventana
   > interrumpible por parry, entra en este término por definición y las Reglas 3 y 7 lo
   > cubren sin necesidad de enmienda.
   >
   > **Por qué existe este término.** Hasta el 2026-08-04 las Reglas 3 y 7 estaban
   > cuantificadas literalmente sobre `Golpe`, de modo que un parry contra una Ventana
   > Especial **no podía resolverse como éxito en ninguna circunstancia** y siempre
   > vencía "sin encontrar ningún `Golpe`" — es decir, se resolvía como **whiff**, con
   > sus 9 ticks de bloqueo. Eso hacía `interrumpible_por_parry = true` (sistema 2, Core
   > Rule 5) literalmente indisparable y anulaba la Core Rule 5 entera. La enmienda de
   > Ventana Especial del 2026-08-03 tocó las tres cláusulas donde el conflicto **se
   > veía** (Reglas 4 y 6, AC C4) y ninguna de las dos donde **residía**. Es la raíz
   > **R2** de la 3ª pasada del sistema 2.
2. **Ventana de parry**: al presionar el botón, el jugador entra en estado Parry
   por `parry_window` segundos, durante los cuales el parry permanece activo.
   **Fuente de verdad canónica**: todas las duraciones de este sistema se
   autorizan y almacenan en runtime como conteos enteros de **ticks de simulación
   fija** (`_physics_process` a 60Hz, desacoplado del framerate de renderizado) —
   nunca como tiempo real ni como conteo de frames de renderizado. Esto es
   especialmente crítico en Steam Deck, donde el refresco variable (VRR) del panel
   OLED o el modo 40Hz de ahorro de batería podrían reintroducir exactamente el
   drift que esta regla busca evitar si se contaran frames de render en su lugar.
   Los valores en segundos que aparecen en Tuning Knobs y Fórmulas son valores de
   diseño/legibilidad derivados (`ticks / 60.0`), no la fuente de verdad — ver la
   fila de `parry_window` en Tuning Knobs para la conversión canónica (13 ticks).

   > **Convención de vocabulario (normativa)**: en este documento, "**fotograma**"
   > significa siempre **tick de simulación fija a 60Hz**, nunca frame de renderizado.
   > Las dos únicas excepciones, marcadas explícitamente allí donde aparecen, son la
   > tolerancia de medición del AC C13 y las métricas de frame time de P1/P4, que son
   > wall-clock de render por definición. Se declara aquí porque el documento usa
   > ambos términos y la ambigüedad es precisamente el drift que la Regla 2 previene.

   **Autoridad única del tiempo — cuatro reglas normativas** (revalidadas contra
   Godot 4.7 por `godot-specialist` en la re-review de 2026-08-01):

   1. **Incrementar por tick, nunca acumular delta.** Escalar el tiempo de juego
      escala el valor de `delta` que recibe `_physics_process`, pero **no** cambia
      cuántas veces se dispara por segundo real (eso depende solo de
      `physics_ticks_per_second`). Un contador entero (`ticks += 1`) es por tanto
      inmune al hitstop; un acumulador `elapsed += delta` **no lo es** y se quedaría
      casi congelado durante cada hitstop — reintroduciendo silenciosamente, en cada
      parry exitoso y cada golpe de combo, exactamente el drift que esta regla existe
      para evitar. Esta es la diferencia entre que la regla funcione o sea decorativa.
   2. **El hitstop escala la simulación diegética, nunca la capa de HUD/UI.** Durante
      un hitstop, el mundo (jugador, ángel, VFX, cámara) avanza al 4% de velocidad
      mientras la capa de HUD/UI sigue avanzando a velocidad normal. Es obligatorio
      porque el evento 8 (combo completo) exige congelación diegética **y** reacción
      de HUD inmediata a la vez, y el requisito ya escrito de "cambios de estado
      crítico en 1–2 fotogramas, sin ease-in" (UI Requirements) no admite excepción
      durante el hitstop.

      > **El audio pertenece al bucket diegético** *(clasificación añadida el
      > 2026-08-04, changeset 1 de la 3ª pasada; hallazgo de `audio-director`)*. Esta
      > regla enumeraba dos buckets —"el mundo" y "la capa de HUD/UI"— y **el audio no
      > estaba en ninguno de los dos**, pese a que la ambigüedad tiene consecuencia de
      > sensación directa. Se declara aquí: **el SFX diegético de impacto (eventos 3,
      > 4, 7, 8, 11) escala con la simulación diegética**, igual que el resto del
      > mundo; la UI sonora y la música **no**. Un impacto que suena a velocidad plena
      > sobre imagen congelada al 4% es exactamente lo contrario de lo que el resto de
      > la Regla 2 persigue, y contradice el "sacramento robado" que el evento 3 exige.
      > **Como todo en esta regla, esto especifica el efecto, no el mecanismo**: cómo
      > se consigue (pitch/time-stretch, bus dedicado, `AudioStreamPlayer` alimentado
      > por el delta escalado) es decisión de `/create-architecture`, igual que el
      > resto de consumidores del tiempo autoritativo — ver Open Questions.

      > **Este GDD especifica el efecto, no el mecanismo — y deliberadamente.** La
      > versión anterior de esta regla nombraba `Engine.time_scale` como mecanismo.
      > `godot-specialist` verificó en la re-review que **Godot 4.7 no ofrece ninguna
      > forma de eximir un subárbol de `Engine.time_scale`**: es un escalar global
      > único aplicado al `delta` de todos los nodos, y `process_mode` gobierna la
      > *pausa* (`SceneTree.paused`), no la escala. Es decir, esta regla y el uso de
      > `Engine.time_scale` global son **mutuamente excluyentes**, y publicar ambas
      > a la vez era publicar una norma inconstruible. El mecanismo (p. ej. un
      > autoload autoritativo de tiempo que exponga un delta escalado consumido solo
      > por los nodos de gameplay, dejando el HUD con el delta del motor) es decisión
      > de `/create-architecture` — ver Open Questions. **Ningún valor de este
      > documento debe leerse como el valor literal de una propiedad de motor.**
   3. **Las duraciones de hitstop se canonicalizan en ticks, igual que todo lo demás.**
      El hitstop de parry exitoso dura **5 ticks de simulación fija (0.0833s)**, no
      "0.08s". La formulación anterior lo declaraba en segundos de reloj real, lo que
      creaba una contradicción interna con la regla 1: 0.08s × 60 = **4.8 ticks**, un
      valor no entero que ninguna implementación basada en el contador entero
      autoritativo puede producir. 5 ticks recibe el mismo tratamiento que
      `parry_window` (13 ticks): el valor en segundos es derivado y de legibilidad, el
      tick es la fuente de verdad. Lo que sigue vigente de la formulación anterior:
      esos 5 ticks son **5 ticks de reloj real**, no 5 ticks de tiempo diegético
      escalado — interpretarlos como tiempo de juego a velocidad 0.04 daría ~2
      segundos reales, que obviamente no es la intención.
   4. **`physics_ticks_per_second = 60` es invariante de proyecto, no un ajuste.**
      Toda la canonicalización en ticks de este documento (13, 9, 6, 5, 42, 120)
      descansa en esa tasa. Bajarla —una palanca real de ahorro de batería en Steam
      Deck— convertiría silenciosamente `parry_window` de 0.2167s a 0.325s a 40Hz sin
      tocar una sola línea de este GDD. Cualquier cambio de esa tasa obliga a
      rederivar **todos** los valores en ticks del documento. Ver la fila
      correspondiente en Tuning Knobs.

      > **Hz de pantalla ≠ Hz de física.** El "modo 40Hz" del Steam Deck es una
      > limitación de *refresco de pantalla*, y es justamente la razón por la que este
      > documento no cuenta frames de render. La tasa de *física* debe permanecer en
      > 60 en todos los perfiles de energía; bajarla "para ir a la par" con el render
      > rompería toda la calibración de timing.

   > Estas cuatro reglas son de diseño, no de implementación: fijan **qué debe ser
   > cierto**. El *cómo* (nodo autoritativo de tiempo, modos de proceso concretos) es
   > decisión de `/create-architecture` — ver Open Questions. Están cubiertas por los
   > ACs **C13** y **C14**; la versión anterior de este bloque era prosa normativa sin
   > ningún criterio verificable, que es exactamente el patrón que este documento
   > critica en otros sitios.

   **Lectura de input (normativa)**: el input de parry se lee con
   `Input.is_action_just_pressed()` **dentro de `_physics_process`**, nunca mediante
   flags dirigidos por frame de renderizado — el camino de render reintroduciría, en
   el input, exactamente el drift que la regla 1 evita en las duraciones. Esto **no**
   choca con la prohibición de buffer de la Regla 7: aquélla prohíbe el buffer de
   **diseño** (encolar una acción para ejecutarla al salir de una recuperación); el
   mecanismo de motor que garantiza que una pulsación ocurrida entre dos ticks no se
   pierda es una cosa distinta, y es necesario para cumplir el presupuesto de ≤33ms
   de Input Responsiveness.

   > **El control de parry es DIGITAL — normativo** *(decisión de usuario del 2026-08-04,
   > changeset 2 ítem 1)*. La acción de parry se mapea a un control binario y **ningún eje
   > analógico** (gatillo, stick) puede mapearse a ella; no existe conversión implícita de
   > eje a botón. Un intento de hacerlo debe **fallar la validación de bindings al
   > cargar** (AC **C24**).
   >
   > **Por qué es normativo y no una preferencia de mando.** Un gatillo analógico mete la
   > **distancia de recorrido** dentro de `t_press`: la misma intención produce un instante
   > distinto según dónde descanse el dedo del jugador y según el mando concreto — habilidad
   > medida por el hardware, que es lo que el Pilar 2 rechaza. Y obliga a umbral e
   > histéresis, con lo que **"una pulsación" deja de estar bien definido**: C10 (descarte
   > sin buffer), C17 (cero feedback durante la recuperación) y la aritmética de cobertura
   > de **R6** están todos cuantificados sobre ese término. El ruido cerca del umbral
   > durante el lockout de 9 ticks produciría descartes indistinguibles de un bug de input.
   > Hallazgo de `ux-designer`, 3ª pasada. **`technical-preferences.md` decía lo contrario
   > y se corrige en este mismo changeset.**

   > **La resolución sub-tick queda descartada, y se declara aquí para que nadie la
   > reabra por descuido** *(changeset 2 ítem 1)*. `calidad_timing` se mide en ticks
   > enteros (Fórmula 1) y **este documento no exige ni permite** una resolución más fina.
   > Dos razones, en este orden:
   >
   > 1. **No está verificada.** La vía que la 3ª pasada señaló como "la única"
   >    (`InputEvent.get_timestamp()`) **no aparece en ninguna parte** de
   >    `docs/engine-reference/godot/`, y `modules/input.md` está verificado contra **4.6**
   >    mientras el proyecto fija **4.7** — versión que además trae un cambio incompatible
   >    de Input que ese fichero no cubre. Publicar una norma sobre esa API sería repetir
   >    exactamente el fallo de `Engine.time_scale`, en el mismo documento y por el mismo
   >    motivo: **un GDD de capa Fundación no publica normas sobre mecanismos no
   >    verificados.**
   > 2. **No haría falta aunque existiera.** La cuantización a tick aporta una desviación
   >    típica de ~4.8ms (uniforme sobre 16.7ms) frente a una varianza humana del orden de
   >    15–25ms contra una señal telegrafiada: es **~3% del ruido total**, no el término
   >    dominante. Lo que la resolución de tick produce no es aleatoriedad sino una
   >    **escala de recompensa gruesa**, y esa se resuelve declarando los escalones (D1),
   >    no persiguiendo precisión que el jugador no puede ejercer.
   >
   > Verificar si Godot 4.7 expone un timestamp de input sub-tick, y refrescar
   > `modules/input.md` de 4.6 a 4.7, queda registrado como **tarea de referencia de
   > motor** — no como bloqueante de este GDD. Ver Open Questions.
3. **Regla de resolución (perdón de anticipación, validada por el prototipo)**: un
   parry se resuelve como ÉXITO si (a) se presiona mientras una **ventana parable**
   está activa, O (b) una **ventana parable** comienza mientras el parry del jugador
   sigue activo. Cada intento se resuelve como éxito como máximo una vez. *(Cuantificador
   ampliado de `Golpe` a **toda ventana parable** el 2026-08-04, enmienda A — ver el
   término normativo en la Regla 1. Esta regla decide **si** un parry acierta; **qué
   produce** el acierto lo decide la Regla 4, que sí distingue por tipo de ventana.)*
4. **Consecuencia de parry exitoso**: absorbe una mota de Gracia (evento consumido
   por el Sistema de Gracia, sistema 5 — este GDD no decide cuánta gracia se gana);
   aplica daño de Postura al enemigo; dispara hitstop y feedback visual/sonoro; el
   enemigo entra en un breve Repliegue antes de su próximo golpe, evitando combos
   de golpes consecutivos injustos. **Excepción (combos)**: si el golpe parado
   forma parte de un combo (Regla 9) y el combo no ha concluido todavía, el
   Repliegue **no** se dispara entre golpes — se aplica una única vez, al resolverse
   el combo completo (tras el último golpe exitoso, o en el momento de la
   interrupción si el combo se rompe a mitad). Ver Regla 9.

   **Excepción (Ventana Especial)** *(añadida en la 2ª pasada de `/design-review`
   del sistema 2, 2026-08-03, decisión de usuario)*: si el parry exitoso se
   resuelve contra una **Ventana Especial** —el par de eventos propio que declara
   una `Acción Especial` interrumpible (sistema 2, Core Rule 5)— en vez de contra
   un `Golpe`, se aplican **solo dos** de las cuatro consecuencias:

   | Consecuencia | Golpe | Ventana Especial |
   |---|---|---|
   | Gracia absorbida | ✓ | ✓ (completa) |
   | Hitstop y feedback | ✓ | ✓ |
   | Daño de Postura | ✓ | ✗ |
   | Repliegue | ✓ | ✗ (→ Enfriamiento) |

   La `Acción Especial` está **fuera del ciclo de ataque**, y la Postura es la
   moneda de ese ciclo. Los eventos son deliberadamente **distintos** de los de
   `Golpe` para que este GDD pueda distinguir ambos casos por el evento mismo, sin
   inspeccionar el estado del jefe. **Corolario (excepción a la Regla 6)**: una
   Ventana Especial no parada **no daña al jugador** — es una ventana de
   oportunidad, no un ataque; el coste de fallarla es que el jefe completa su
   habilidad.

   > **Acotación del corolario — qué es exactamente lo que no daña** *(añadida el
   > 2026-08-04, changeset 2; cierra el hallazgo de `game-designer` sobre la Ventana
   > Especial dominada)*. El corolario se cuantifica sobre **la ventana**, no sobre la
   > habilidad. Son **dos instantes distintos** de la máquina de estados del sistema 2:
   >
   > | Instante | Efecto sobre la Vida del jugador | Qué sí cambia | AC |
   > |---|---|---|---|
   > | La Ventana Especial **se cierra** sin ser parada | ninguno | nada | **C21** |
   > | La `Acción Especial` **se completa** después | **ninguno tampoco** — el sistema 2 declara que ese estado nunca reduce la Vida | la **magnitud propia de la habilidad** (p. ej. la Vida del jefe si es una curación), acotada por R9a | **C22** |
   >
   > **La severidad no es libre**: la acota la invariante **R9a**, que este GDD impone al
   > sistema 20 — banda `1.0 ≤ severidad ≤ 2.0` **en equivalencia**, no en Vida, y
   > `Σ ≤ golpes_para_morir_base − 1` por duelo. Sin ella, "el jefe completa su
   > habilidad" era un coste que este
   > documento **nombraba sin exigir a nadie que lo garantizase**, y por eso **ignorar la
   > Ventana Especial dominaba estrictamente a pararla**: mismo beneficio de combate
   > (ninguno, por esta misma tabla de consecuencias) y menos coste — pararla gasta Gracia
   > = corrupción, ignorarla no gastaba nada. Ver el bloque "Sobre R9" en Restricciones
   > conjuntas para el razonamiento completo.
   >
   > **Un tester que mida ambos instantes como uno solo hará fallar C21 o C22 sin que
   > haya ningún defecto.** El corolario sigue siendo literalmente cierto, y también la
   > prohibición del sistema 2: **ninguno de los dos instantes toca la Vida del jugador**.
   > Lo que la habilidad cuesta se paga en su propia moneda, y R9a acota su equivalencia.
   >
   > **Propiedad del feedback**: la señal perceptual del **cierre de la ventana** es de
   > este GDD (evento 16, es un evento de parry); la de la **completación de la
   > habilidad** es del **sistema 2**, que ya posee la fila de feedback del estado
   > `Acción Especial`. Que ambas sean **distinguibles entre sí** es una restricción que
   > este documento declara porque es quien crea la coincidencia — mismo patrón que la
   > Regla de precedencia armónica. Ver el AC **V7** y la nota de propiedad en
   > Visual/Audio Requirements.
5. **Ruptura de Postura**: cuando la Postura del enemigo llega a 0, entra en estado
   Aturdido durante `ventana_castigo` segundos (2.0s) — una ventana prolongada y de
   bajo riesgo en la que el jugador ejecuta un Golpe de Castigo con su arma,
   aplicando daño real a la Vida del enemigo. Si la ventana expira sin que el
   jugador conecte, la Postura se restaura por completo (ver Edge Cases).

   **Reinicio de Postura tras un Golpe de Castigo exitoso**: cuando el Golpe de
   Castigo conecta, el enemigo sale de Aturdido, su Postura se restaura **por
   completo** a `postura_max`, y reanuda su ciclo normal de ataque. Es decir, la
   Postura se restaura íntegra en **ambas** salidas posibles del Aturdimiento —
   conectar el castigo y dejar expirar la ventana— y la diferencia entre una y otra
   está exclusivamente en si se aplicó daño a la Vida del ángel. Esto es la premisa
   silenciosa de la Fórmula 3 y del conteo 12/20/30: cada ciclo cuesta el mismo
   número de parries que el anterior, sin acarreo. *(Regla añadida en la re-review de
   2026-08-01: hasta entonces solo se declaraba la restauración del caso de
   expiración, y el caso más común —el castigo exitoso— quedaba inferido desde la
   aritmética de la Fórmula 3 en vez de declarado.)*

   > **Acotación — Golpe de Castigo letal** *(añadida el 2026-08-04, enmienda G)*. Todo
   > lo anterior aplica al Golpe de Castigo **no letal**. Si el Golpe de Castigo deja la
   > Vida del jefe en **0**, el jefe **no** sale de Aturdido a su ciclo, **no** restaura
   > Postura, **no** reanuda su cadencia de ataque y **no** vuelve a emitir ninguna
   > ventana parable: entra en el estado terminal `Muerto` del sistema 2, que es quien
   > emite "duelo ganado" (ver Dependencies).
   >
   > La restauración íntegra de Postura y la premisa de "cada ciclo cuesta el mismo
   > número de parries que el anterior" describen el **caso general**; el último castigo
   > de cada duelo es, por definición, la excepción. **No es un borde raro**: con
   > `ciclos_objetivo` de 4/5/6 según tríada, es **uno de cada 4, 5 o 6 castigos**, y es
   > además el único que el jugador recuerda. La formulación anterior se cuantificaba
   > sobre *todo* castigo conectado, incluido el que mata al jefe — para el cual no hay
   > salida de Aturdido, ni restauración, ni ciclo siguiente que contar. Verificado por
   > los ACs **E10** (no letal) y **E11** (letal), que contrastan en las tres
   > consecuencias.

   **Input**: el Golpe de Castigo se ejecuta con el **mismo botón de parry** —
   mientras el enemigo está Aturdido no hay **ninguna ventana parable** activa que parar
   —`Aturdido` y `Acción Especial` son estados distintos del sistema 2—, así que
   ese input se reinterpreta sin ambigüedad como Golpe de Castigo en vez de un
   intento de parry. No existe un botón dedicado adicional. **Una vez iniciado, el
   Golpe de Castigo bloquea la entrada a Parry hasta que su recuperación termina**
   (ver States and Transitions) — es **una de las dos** excepciones a "el parry puede
   intentarse en cualquier momento, sin coste" (Regla 7; la otra es la Recuperación
   de whiff, ver esa misma regla): el compromiso del castigo
   es real, coherente con el contraste "ligero y reactivo" (parry) vs. "pesado y
   deliberado" (castigo) ya declarado en Game Feel.

   **Ventana de gracia de salida**: durante los últimos `gracia_salida_castigo`
   fotogramas de `ventana_castigo`, y en el instante exacto en que la Postura se
   restaura, la pulsación **deja de interpretarse como Golpe de Castigo y vuelve a
   interpretarse como Parry**. Sin esta regla, una pulsación 2 fotogramas tarde
   compromete al jugador a una recuperación de 10–14 fotogramas justo cuando el
   enemigo reanuda su ciclo y vuelve a haber algo que parar — un golpe inevitable
   por un error de borde, no por una lectura equivocada. Es el mismo principio de
   perdón de anticipación que el prototipo validó (Regla 3), aplicado al borde
   opuesto: **ningún borde de estado puede convertir un input razonable en un
   castigo inevitable.**

   > **Símbolo `restantes(T)` — declarado y poseído por este GDD** *(añadido el
   > 2026-08-04, enmienda E)*. Sea `T` el índice de tick, **base 1**, transcurrido
   > dentro de `Aturdido`: `T = 1` es el primer tick del estado y `T = ventana_castigo`
   > el último. Entonces:
   >
   > `restantes(T) = ventana_castigo + 1 − T`
   >
   > El conteo es **inclusivo**: `restantes(T)` cuenta el tick `T` mismo como todavía
   > disponible. `restantes(1) = ventana_castigo` y `restantes(ventana_castigo) = 1`.
   >
   > **Borde derivado — expresado en knobs, nunca como literal.** La ventana de gracia
   > de salida es `restantes(T) ≤ gracia_salida_castigo`. Despejando sobre la condición
   > de Castigo (`restantes(T) > gracia_salida_castigo`, estricta):
   >
   > `T_max_castigo = ventana_castigo − gracia_salida_castigo`
   >
   > Con los valores de lanzamiento (120 y 6): **el último tick de Golpe de Castigo es
   > el 114 y el primero de Parry es el 115**, con zona de gracia `T ∈ {115 … 120}`.
   >
   > **Invariante de anchura** — es la razón estructural del defecto, no una cifra
   > corregida: bajo este conteo inclusivo la zona de gracia mide **exactamente
   > `gracia_salida_castigo` ticks para cualquier par de valores**, porque su anchura es
   > `ventana_castigo − T_max_castigo = gracia_salida_castigo` idénticamente. Bajo
   > conteo **exclusivo** mide `gracia_salida_castigo + 1`. Ese tick de más no era un
   > error de cuenta puntual sino una **propiedad del conteo elegido** — por eso
   > reaparecía cada vez que alguien recalculaba el borde a mano.
   >
   > `ventana_castigo` tiene rango seguro 72–180 ticks y `gracia_salida_castigo` 4–10,
   > así que **el borde se mueve con cualquier retune**: subir `gracia_salida_castigo` a
   > su techo lo lleva a 110 sin tocar nada más. **No escribir 114 como literal**;
   > derivarlo. Los ACs sí fijan la cifra, pero nombrando los knobs de los que depende.
   >
   > **Por qué se declara aquí.** El sistema 2 definió normativamente `restantes(T)` en
   > la 2ª pasada de su `/design-review` **sin poseer el término**, y lo hizo con conteo
   > **exclusivo** (`ventana_castigo − T`). Bajo ese conteo la zona de gracia mide **7
   > ticks** (`T ∈ {114 … 120}`) — que es exactamente el defecto que aquella corrección
   > decía estar previniendo, y una contradicción con las tres formulaciones de este
   > documento: los "últimos `gracia_salida_castigo` fotogramas" de esta regla, el
   > "quedan más de `gracia_salida_castigo`" de la desambiguación de input, y el AC
   > **C11**, que contiene ambas y las declara equivalentes. **Las tres son consistentes
   > entre sí solo bajo conteo inclusivo.** `ventana_castigo` es propiedad de este GDD,
   > así que el término derivado de ella también lo es: el sistema 2 lo **consume**, no
   > lo define.
   >
   > **Deuda registrada, no cerrable aquí**: el sistema 2 tiene hoy escrito **113** como
   > último tick de Castigo (su AC E3b). Debe corregirse a **114** en su 4ª pasada —
   > raíz **R5**. No puede editarse en este changeset porque ese documento está
   > congelado, pese a que la regla operativa exige editar ambos lados de un contrato a
   > la vez. Queda anotado aquí precisamente para que la excepción no se pierda.
6. **Consecuencia de fallo de parry**: si el **Golpe** del enemigo concluye sin haber
   sido parado, conecta contra el jugador y reduce su Vida actual en
   `dano_golpe_enemigo` (**Fórmula 8**, 25 con los valores de lanzamiento), con la
   regla de clamp declarada allí. *(Hasta el changeset 2 del 2026-08-04 esta regla
   decía "reduce su Vida actual" **sin fórmula ni magnitud**, pese a que tres reglas
   normativas del sistema 2 razonan sobre ese daño y a que era imposible cuantificar el
   coste de dejar que el jefe complete una `Acción Especial` sin ella — ver R9.)*
   **Excepción**:
   una **Ventana Especial** no parada no daña al jugador — ver la excepción de la
   Regla 4. Este sistema
   declara y posee el recurso **Vida del jugador** (ver Fórmula 5 — Vida Máxima),
   pero **no define aquí** la secuencia completa de muerte/game over (transición a
   pantalla de derrota, persistencia entre runs) — eso sigue siendo cross-sistema
   con Gestión de Run (ver Open Questions).
7. **Sin costo de recurso para intentar el parry**: intentar un parry nunca cuesta
   un recurso gastable (estamina, maná). Es puramente una prueba de habilidad de
   timing, en cumplimiento estricto del Pilar 2.

   **Único coste: temporal, y solo al fallar en vacío.** Un parry que se resuelve
   como whiff (su ventana entera venció sin encontrar **ninguna ventana parable** —
   ver el término normativo en la Regla 1) entra en una
   recuperación de `recuperacion_whiff` fotogramas durante la cual **no puede
   iniciarse otro parry**. Un parry **exitoso contra cualquier tipo de ventana
   parable** conserva la recuperación mínima de
   2–3 fotogramas, de modo que las cadenas de parry consecutivo dentro de un combo
   (Regla 9) no se ven afectadas en absoluto. *(Cuantificador ampliado el 2026-08-04,
   enmienda A: la formulación anterior decía "sin encontrar ningún Golpe", lo que
   convertía **todo** intento contra una Ventana Especial en un whiff con 9 ticks de
   bloqueo — castigando al jugador por acertar.)*

   > **Justificación (hallazgo de revisión adversarial, `game-designer` +
   > `creative-director`)**: con la recuperación uniforme de 2–3 fotogramas de la
   > versión anterior, la ventana activa de 13 ticks sobre un ciclo de 15–16 cubría
   > el **81–87% del tiempo**. A esa cobertura, machacar el botón a ritmo fijo es
   > una estrategia de supervivencia que **ninguna variabilidad de cadencia del
   > sistema 20 puede derrotar** — es un problema aritmético, no de diseño de IA, y
   > por tanto no era diferible a ese GDD. Con `recuperacion_whiff = 9`, el ciclo
   > del jugador que machaca pasa a 13 activos sobre 22 → **~59% de cobertura**,
   > mientras que el jugador que lee el patrón no paga absolutamente nada. Es un
   > coste de **tiempo**, no de recurso: el Pilar 2 queda intacto.
   >
   > **Tres límites de esta decisión, hallados en la re-review y ahora acotados**:
   > (1) la cobertura del 59% describe el bucle de whiff puro; **dentro de una cadena
   > de aciertos sube legítimamente al ~84%** (la recuperación de un parry exitoso es
   > de 2–3 ticks), lo que hace que un masher afortunado entre en cobertura casi total
   > durante un combo — mitigado por la varianza intra-combo exigida al sistema 20 y
   > medido por C12b; (2) `recuperacion_whiff` es un coste que el **jugador que
   > aprende** paga desproporcionadamente, porque whiffear *es* el método de
   > aprendizaje que `game-concept.md` declara para los primeros 10 minutos — de ahí
   > la restricción impuesta al encuentro tutorial (ver Open Questions) y la
   > exposición del knob a Accesibilidad (21); (3) el knob nunca entró en el bloque de
   > restricciones conjuntas, y el 25.7% de su rejilla violaba el objetivo de
   > cobertura — corregido con la invariante **R6**.
   >
   > **Lo que la re-review NO cambió, y por qué**: `game-designer` propuso cancelar el
   > lockout si un Golpe empieza dentro de él (perdón simétrico al de
   > `gracia_salida_castigo`). **Rechazado por `creative-director` y confirmado por el
   > usuario**: eso haría que el lockout no costara nada exactamente en el único
   > momento en que importa — el masher vería su recuperación cancelada precisamente
   > por los golpes que necesita parar. No debilitaría la decisión: la anularía. La
   > analogía tampoco se sostiene: `gracia_salida_castigo` protege un **borde de
   > estado** donde un input correcto produce la acción equivocada; un whiff no es un
   > borde, es una lectura errónea genuina, que es justo lo que el coste castiga.
8. **Vida del jugador**: el jugador tiene una Vida actual (0 a Vida Máxima) que
   comienza en Vida Máxima al inicio de cada duelo/run. La Vida Máxima puede
   crecer durante la run mediante dos fuentes externas a este sistema: absorber
   la esencia de un ángel derrotado (elección del Sistema de Gracia, sistema 5) o
   equipar reliquias con bono de Vida (sistema 9) — ver Fórmula 5. Rechazar la
   esencia de un ángel no concede este bono: el jugador permanece "puro" pero más
   vulnerable en duelos posteriores. **La decisión es independiente por ángel**:
   absorber a uno no obliga a absorber a los siguientes, ni rechazar a uno impide
   absorber después. `angeles_absorbidos` es un contador acumulativo de las
   decisiones "absorber" tomadas, en cualquier orden y combinación.

9. **Combos de ataque — parries consecutivos, una sola instancia de Postura**: un
   patrón de ataque puede ser un **combo** de N golpes encadenados (modelo Sekiro).
   El jugador debe parar cada golpe del combo de forma consecutiva. Reglas:
   - **Longitud legal: `3 ≤ N ≤ 5`** (restricción normativa impuesta al sistema 20,
     ver justificación abajo). Un patrón de 2 golpes encadenados **no es un combo** —
     es una cadena de dos golpes simples, con Repliegue entre ellos y dos instancias
     de Postura.
   - **Postura**: el combo completo aplica **una sola instancia** de daño de
     Postura (Fórmula 1), no N. Parar un combo de 3 golpes paga lo mismo que parar
     un golpe único.
   - **Fallo a mitad de combo**: si el jugador falla cualquier golpe del combo, ese
     golpe conecta, **el combo se aborta por completo** — los golpes restantes del
     patrón (`i+1 … N`) **no llegan a ejecutarse**; el ángel pasa directamente a
     Repliegue y luego a su ciclo normal. No se aplica daño de Postura alguno, y se
     pierden también los parries ya acertados de ese combo. *(Aclaración explícita
     añadida en la re-review de 2026-08-01: la versión anterior decía solo "el combo
     se interrumpe", lo que dejaba abierto si los golpes restantes seguían llegando
     mientras el jugador estaba en recuperación de Recepción de golpe. Sí se abortan:
     un fallo cuesta **un** golpe recibido, nunca N.)*
   - **Gracia**: cada parry del combo sí concede gracia, pero **reducida** — ver
     Fórmula 7. Un combo genera más gracia total que un golpe simple, pero menos
     que N golpes simples.
   - **Calidad de timing**: el bono de "Parry Justo" (Fórmula 1) se calcula sobre
     el **último parry del combo** — recompensa rematar bien la secuencia.
   - **Repliegue (Fórmula 4)**: **no se dispara entre golpes del combo.** Los
     golpes deben ser realmente consecutivos, sin hueco de respiro — es lo que
     distingue a un combo de una cadena de golpes simples y lo que lo hace "más
     habilidad por la misma recompensa" (ver nota de diseño). El Repliegue se
     aplica una única vez, al resolverse el combo completo (última entrada
     exitosa) o en el instante en que el combo se interrumpe por fallo.

   > **Nota de diseño**: los combos son la palanca de dificultad correcta según el
   > Pilar 1 y el Pilar 2 — exigen más habilidad por la misma recompensa, en lugar
   > de inflar números. La **composición** de combos por ángel la define la IA de
   > Combate de Jefes (sistema 20); este GDD solo fija el **rango legal de N**.
   >
   > **Por qué `3 ≤ N ≤ 5` se fija aquí y no se delega** (hallazgos de
   > `systems-designer` y `audio-director`, re-review 2026-08-01). Es el mismo patrón
   > que `multiplicador_ataque = 1.0` (R4): este GDD no posee los patrones de ataque,
   > pero sí posee las dos invariantes que se romperían.
   > - **Suelo `N ≥ 3`**: lo exige la Fórmula 7. Con `modificador_combo_gracia = 0.5`,
   >   un combo de 2 golpes produce `2 × 0.5 = 1.0 × gracia_base` — **exactamente lo
   >   mismo** que un golpe simple, incumpliendo la garantía de esta misma regla ("un
   >   combo genera más gracia total que un golpe simple"). Peor, en el suelo del
   >   rango de tuning (0.3) daría 0.6: **menos** gracia por más riesgo. Ver la
   >   invariante **R7**.
   > - **Techo `N ≤ 5`**: lo exige el diseño de audio. Los eventos 7→8 especifican un
   >   cue ascendente que "cierra" armónicamente en el último golpe; sin techo, esa
   >   frase musical es inimplementable — obliga a elegir entre clipping, un loop que
   >   rompe la ilusión de frase única, o una meseta muda en la racha más recompensada
   >   del jugador. 5 también acota el peor caso de acumulación de esquirlas contra el
   >   presupuesto de 250 partículas del art bible 8.6.
   >
   > **Implicación de conteo**: los valores de la Fórmula 2 y 3 (12/20/30 —
   > `ciclos_objetivo(tríada) × postura_max(tríada)/dano_base`, es decir Humanidad
   > 4×3=12, Cosmos 5×4=20, Cercanía a Dios 6×5=30) cuentan **instancias de
   > Postura**, no parries individuales. Un ángel cuyos patrones incluyan combos
   > exigirá bastantes más parries reales que esa cifra. Ejemplo: un ángel de
   > Cosmos con 4 instancias por ciclo y mitad de sus patrones en combos de 3
   > golpes puede requerir ~35–40 parries reales en el duelo completo.
   >
   > **Estos números son válidos únicamente en la configuración de lanzamiento
   > actual** (`dano_base=10`, `postura_base=30`, `incremento_postura_triada=10`).
   > Solo `dano_base=10` produce conteos de parry enteros para las tres tríadas
   > simultáneamente dentro de sus rangos de tuning respectivos — cualquier retune
   > de `dano_base`, `postura_base` o `incremento_postura_triada` debe recalcular
   > estas cifras antes de comunicarlas a diseño de IA de jefes (sistema 20) o a QA.

### States and Transitions

| Estado | Entry Condition | Exit Condition | Behavior |
|---|---|---|---|
| Idle | Sin input de movimiento | Se detecta movimiento o parry | Sin desplazamiento; puede transicionar a Parry en cualquier momento |
| Movimiento | Input de movimiento activo | Input de parry, o el movimiento cesa | Desplazamiento según velocidad; puede transicionar a Parry en cualquier momento |
| Parry | Botón de parry presionado (desde Idle o Movimiento; **no** disponible mientras el jugador está en Golpe de Castigo ni en Recuperación de whiff) | Vence `parry_window`, se resuelve un éxito, o el combo re-arma para el siguiente golpe (sin pasar por Idle/Movimiento — ver Regla 9) | Ventana activa; el movimiento se congela durante este estado (confirmado por el prototipo). Al resolverse con **éxito**, recuperación mínima de 2–3 fotogramas |
| Recuperación de whiff | La ventana de Parry venció **sin haber encontrado ninguna ventana parable** (whiff, Regla 7 — cuantificador ampliado el 2026-08-04) | Vencen `recuperacion_whiff` fotogramas | Movimiento permitido; **Parry bloqueado**. Es el único coste de un intento fallido en vacío, y es de tiempo, no de recurso |
| Golpe de Castigo | Botón de parry presionado mientras el enemigo está Aturdido (Regla 5) **y** fuera de la ventana de gracia de salida (`gracia_salida_castigo`) | Fin de la recuperación (10–14 fotogramas, ver Animation Feel Targets) | Movimiento bloqueado; el jugador está comprometido. **Parry no puede interrumpir esta recuperación** — ver Prioridad de Interrupción abajo |
| Recepción de golpe | El Golpe del enemigo conecta sin haber sido parado (Regla 6) | Fin de la recuperación (`recuperacion_recepcion`, 8–12 ticks — ver Tuning Knobs) | **Interrumpe cualquier estado en curso** (Parry, Golpe de Castigo, Movimiento); movimiento bloqueado durante la recuperación |

**Prioridad de interrupción** (de mayor a menor): Recepción de golpe > transición
del enemigo a Aturdido (Regla 5, se dispara "sin importar el estado del jugador")
> Parry > Golpe de Castigo > Recuperación de whiff > Movimiento > Idle. Hay
exactamente **dos** momentos en los que Parry no puede iniciarse (excepciones a la
Regla 7, ambas de tiempo y ninguna de recurso): durante la recuperación de un Golpe
de Castigo (Regla 5) y durante la Recuperación de whiff (Regla 7).

> **Anotación — la ordenación `Recepción de golpe > Golpe de Castigo` es
> estructuralmente inalcanzable** *(añadida el 2026-08-04, changeset 1; hallazgo de
> `qa-lead`, confirmado por `creative-director`)*. El Golpe de Castigo solo existe con
> el jefe **Aturdido**, y el AC **C5** hace que la entrada en Aturdido interrumpa
> cualquier animación de ataque en curso — de modo que ningún `Golpe` puede conectar
> mientras el jugador ejecuta un Castigo. Ese par de la tabla **nunca se disputa en
> runtime**. Se anota, en vez de borrarse, para que la ordenación siga siendo total y
> legible; pero **no debe escribirse un test para él** (el fixture es imposible de
> construir) ni implementarse como rama defensiva viva. El resto de la tabla sí es
> alcanzable.

**Nota de desambiguación de input** — el botón de parry se resuelve en este orden:

1. ¿El jugador está en recuperación de Castigo o de whiff? → el input se descarta.
2. ¿El enemigo está Aturdido **y** `restantes(T) > gracia_salida_castigo` (es decir,
   quedan más de `gracia_salida_castigo` ticks de `ventana_castigo`, contados de forma
   **inclusiva** — ver el símbolo `restantes(T)` en la Regla 5)? → Golpe de Castigo.
   Equivale a `T ≤ ventana_castigo − gracia_salida_castigo`, que con los valores de
   lanzamiento es `T ≤ 114`.
3. En cualquier otro caso (incluida la ventana de gracia de salida y el instante de
   restauración de Postura) → Parry.

Este orden es normativo: resuelve la ambigüedad de **input**, que la tabla de
prioridad de interrupción de arriba no cubre porque aquélla solo resuelve conflictos
de **estado**.

### Interactions with Other Systems

- **Sistema de Gracia de Tres Capas (5)**: consume el evento "parry exitoso" para
  incrementar la gracia acumulada — este GDD no decide cuánta gracia se gana por
  parry, eso vive en la GDD de Gracia.
- **Máquina de Estados de Jefe (2)**: provee los eventos "inicio de Golpe" / "fin
  de Golpe" y —cuando un patrón la declara— "inicio de Ventana Especial" / "fin de
  Ventana Especial". Consume de vuelta el resultado de cada Golpe ("parry
  exitoso"/"parry fallido") y la Postura resultante, con los que resuelve sus
  transiciones. **El sistema 2 impone a este GDD**: la Ventana Especial exige la
  excepción declarada en la Regla 4.
- **IA de Combate de Jefes — Patrones (20)**: define la duración de cada fase por
  patrón de ataque y la composición de combos (los **eventos** los emite el
  sistema 2). Coordina con este GDD el umbral de Postura por patrón (a formalizar
  en Cross-References cuando ese GDD exista).
- **Feedback de Impacto — Hitstop/Cámara (4)**: consume el evento "parry exitoso"
  para disparar hitstop y sacudida de cámara.
- **Feedback Sonoro del Parry (16)**: consume "parry exitoso" y "parry fallido"
  para disparar el sonido correspondiente.
- **HUD de Combate (13)**: consume el estado de Postura del enemigo (y la Vida del
  jugador, si el sistema correspondiente se define) para mostrarlos en pantalla.
- **Accesibilidad (21)**: este sistema debe exponer **dos** tuning knobs accesibles
  externamente para un futuro modo de asistencia: `parry_window` (ampliar la ventana)
  y **`recuperacion_whiff`** (reducir el lockout tras un parry en vacío). El segundo se
  añadió en la re-review de 2026-08-01 a señalamiento de `ux-designer`: el coste
  temporal introducido en la revisión anterior **no distingue entre "el jugador
  machacó" y "el jugador con dificultad motora o de tiempo de reacción falló la ventana
  honestamente"** — ambos pagan 9 ticks cada vez, y el segundo los paga mucho más a
  menudo. Exponer solo `parry_window` dejaba ese gap heredado en silencio al sistema
  21. **Nota para el sistema 21**: bajar `recuperacion_whiff` en modo asistencia viola
  R6 a partir de cierto punto; el modo de asistencia debe ajustar **ambos knobs como
  par** o aceptar explícitamente que R6 no aplica en ese modo.
- **Sistema de Gracia de Tres Capas (5)** *(dependencia nueva, ver nota de ciclo
  abajo)*: este GDD consume `angeles_absorbidos` (un conteo entero expuesto por
  Gracia) para calcular la Vida Máxima (Fórmula 5). Gracia, a su vez, ya consumía
  el evento "parry exitoso" de este GDD — esto forma un **ciclo de dependencia
  mutua 1↔5**, documentado y resuelto como contrato de datos (cada sistema
  declara su propia mitad del contrato; ninguno necesita leer el archivo del
  otro para poder escribirse). Ver `systems-index.md`, sección Circular
  Dependencies.
- **Elección de Reliquias entre Duelos (9)** *(dependencia nueva)*: este GDD
  consume `bono_reliquias` (suma de bonos de Vida de reliquias equipadas) para
  la Fórmula 5, y `multiplicador_ataque` para la Fórmula 6. **Restricción que este
  GDD impone al sistema 9**: `multiplicador_ataque = 1.0` como **constante, cerrada
  en ambos sentidos** (invariante R4) — subirlo rompe el suelo de ciclos de la
  Fórmula 3; bajarlo alarga los duelos sin límite y, en el extremo, los hace
  inganables. Además, cualquier modificador de `parry_window` o `recuperacion_whiff`
  debe reverificar R6 sobre los valores efectivos (AC D10).

> **Nota abierta**: la Vida del jugador como recurso ya está definida en este
> GDD (Regla C.8, Fórmula 5), pero la secuencia completa de muerte/game over
> (transición de pantalla, qué persiste entre runs) sigue sin sistema propio —
> ver Open Questions.

## Formulas

> Todas las fórmulas de esta sección fueron propuestas por `systems-designer` y
> ajustadas con el usuario. Ninguna escala la dificultad subiendo estadísticas
> del jugador (Pilar 1) — la dificultad entre tríadas viene de exigir más
> parries y más ciclos, nunca de números artificialmente más grandes.

### 1. Daño de Postura por parry exitoso

`postura_dano = dano_base * (1 + calidad_timing * bono_precision)`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Daño base | `dano_base` | float | 8–15 | Daño de Postura fijo por cualquier parry exitoso (no depende de stats) |
| Calidad de timing | `calidad_timing` | float **escalonado** | conjunto cerrado de 7 valores (tabla abajo) | `clamp(1 − (Δ − 0.5) / umbral_precision, 0, 1)`, con **`Δ` = distancia en ticks enteros** entre el tick de detección del input y el tick de inicio del **`Golpe`** — **no de toda ventana parable**, ver la acotación abajo. Mide cercanía al instante exacto; NO determina éxito/fallo (eso ya es binario, Regla 3) |
| Umbral de precisión | `umbral_precision` | int (**ticks**) | 3–7 ticks (actual: **5** = 0.0833s) | Ancho de la escala de calidad, en ticks de simulación fija |
| Bono de precisión | `bono_precision` | float | 0.3–0.5 | Multiplicador de recompensa por "Parry Justo" |

> **`calidad_timing` es una cantidad escalonada por ticks, no continua** *(canonicalizado
> el 2026-08-04, changeset 2 ítem 1)*. `Δ` solo puede tomar valores enteros: la Regla 2
> obliga a leer el input dentro de `_physics_process`, así que la posición de la pulsación
> dentro del tick **no es observable por diseño**. Escribir la fórmula como si fuese
> continua invitaba a implementarla con reloj real — que es exactamente el drift que la
> Regla 2 existe para evitar. Con `umbral_precision = 5` los escalones son:
>
> | `Δ` (ticks) | 0 | 1 | 2 | 3 | 4 | 5 | ≥6 |
> |---|---|---|---|---|---|---|---|
> | `calidad_timing` | 1.0 | 0.9 | 0.7 | 0.5 | 0.3 | 0.1 | 0.0 |
> | `postura_dano` (con `dano_base = 10`, `bono_precision = 0.4`) | 14.0 | 13.6 | 12.8 | 12.0 | 11.2 | 10.4 | 10.0 |
>
> **El término `− 0.5`** compensa el muestreo: detectar la pulsación en el tick `T`
> implica que ocurrió en `(T−1, T]`, así que el `Δ` medido sobrepasa al real en medio
> tick de media, **siempre en la dirección que castiga**. Restar medio tick devuelve el
> estimador centrado y es coherente con "refuerzo positivo puro, nunca penaliza un parry
> tardío pero válido": un parry a un tick vale 0.9, no 0.8. Verificado por **D1** (los
> pares exactos) y **D14** (que ningún valor intermedio sea alcanzable — la aparición de
> uno es prueba directa de una implementación por reloj real).
>
> **`umbral_precision` era la última duración del documento declarada en segundos.** Valía
> `0.08s`, que a 60Hz son **4.8 ticks** — el mismo valor no entero, por la misma razón,
> que la regla normativa 3 de la Regla 2 corrigió para `hitstop_parry`. El barrido de
> canonicalización visitó las duraciones de la máquina de estados (`parry_window`,
> `recuperacion_whiff`, `retreat_base`, `ventana_castigo`, `gracia_salida_castigo`,
> `recuperacion_recepcion`, `hitstop_parry`) y **se saltó la única que vive dentro de una
> fórmula**. Raíz **A**. La invariante **R2** lo delataba desde entonces: multiplicaba
> `× 60` dentro de sí misma, es decir sabía que necesitaba ticks y dejaba el knob en
> segundos.

**Output Range:** con el valor de lanzamiento `bono_precision = 0.4`, el rango real
es `[dano_base, dano_base * 1.4]` — con `dano_base=10` (default), `[10, 14]`. El
límite teórico `dano_base * 1.5` solo se alcanza en el techo del rango de tuning de
`bono_precision` (0.5), **no en la configuración actual** — no usar 1.5x como
referencia de output salvo que ese knob se reconfigure explícitamente. Nunca
negativo, nunca cero — todo parry exitoso hace algo.

**Ejemplo**: `dano_base = 10`, pulsación detectada **2 ticks** después del inicio de
la ventana parable → `calidad_timing = 1 − (2 − 0.5)/5 = 0.7` →
`postura_dano = 10 * (1 + 0.7*0.4) = 12.8`.

> **Esta fórmula entera se cuantifica sobre `Golpe`, nunca sobre toda ventana parable**
> *(acotado el 2026-08-04, changeset 2 ítem 3)*. Un parry resuelto contra una **Ventana
> Especial** no aplica daño de Postura (Regla 4), así que `calidad_timing` **no se
> calcula** para él y **no puede clasificarse como Parry Justo**: ni esquirla `#FFF8E7`,
> ni capa de audio del evento 4, ni bono de hitstop. El hitstop de una VE parada es el
> `hitstop_parry` base, sin bono.
>
> **Por qué importa, y por qué era un defecto y no una omisión.** El ítem 1 de este mismo
> changeset reescribió esta tabla y cuantificó `Δ` sobre "la ventana parable" —la unión—,
> de modo que un parry preciso contra una Ventana Especial disparaba **la firma completa
> de Parry Justo**: la señal más enfática que este sistema tiene para decir "lo has hecho
> perfecto", sobre la única interacción que el ítem 0 acaba de establecer que **no
> concede ningún beneficio de combate** y solo corrompe. Habría enseñado exactamente lo
> contrario de lo que el ítem 0 diseñó. El review log ya listaba `calidad_timing` entre
> los **ocho sitios de la raíz A**; el arreglo que pedía era **nombrar `Golpe`**, y
> ensanchar a la unión es el error simétrico. Raíz **A**, en una enmienda escrita para
> cerrar la raíz A.

**Umbral de Parry Justo**: un parry exitoso **resuelto contra un `Golpe`** se clasifica
como **Parry Justo** cuando `calidad_timing ≥ umbral_parry_justo` (**0.9**). Es el predicado único del que
dependen las tres señales de precisión —variante de esquirla `#FFF8E7`, capa de audio
del evento 4 y bono de hitstop— y el reparto del bono por escalón (`1.0` → +2 ticks,
`0.9` → +1, por debajo → +0). Ver **C25**. **Se expresa en calidad, nunca en ticks**:
con `umbral_precision` de 5 a 7 equivale a `Δ ≤ 1`, y con 3 o 4 a `Δ = 0`.

Esta capa añade maestría (cuán ajustado, dentro de la ventana ya generosa) sin
tocar la resolución binaria de la Regla 3 — refuerzo positivo puro, nunca
penaliza un parry tardío pero válido.

**Aplicación en combos** (Regla C.9): un combo de N golpes aplica esta fórmula
**una sola vez**, usando la `calidad_timing` del **último** parry del combo. Los
parries intermedios no aportan daño de Postura adicional.

### 2. Postura máxima por tríada

`postura_max(tríada) = postura_base + incremento_postura_triada * índice_tríada`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Postura base | `postura_base` | int | 20–40 (actual: 30) | Postura de la tríada de índice 0 — **es el knob de Tuning Knobs, no un literal** |
| Incremento por tríada | `incremento_postura_triada` | int | 5–15 (actual: 10) | Postura añadida por cada escalón de tríada — **es el knob de Tuning Knobs, no un literal** |
| Índice de tríada | `índice_tríada` | int | {0,1,2} | 0=Humanidad, 1=Cosmos, 2=Cercanía a Dios |

> **Nota de implementación**: esta fórmula debe leer `postura_base` e
> `incremento_postura_triada` desde la configuración externa (Tuning Knobs), nunca
> hardcodear 30 y 10. La versión anterior de este GDD escribía los literales, lo que
> desincronizaba silenciosamente la fórmula de su propia tabla de knobs y violaba el
> estándar "los valores de gameplay deben ser data-driven" (`coding-standards.md`).

**Output Range:** con los valores actuales (30/10): 30 (Humanidad), 40 (Cosmos),
50 (Cercanía a Dios). Con `dano_base = 10`, equivale a 3, 4 y 5 parries exitosos
respectivamente.

**Ejemplo**: Cosmos (`índice_tríada = 1`) con los valores actuales →
`postura_max = postura_base + incremento_postura_triada × 1 = 30 + 10 = 40` → 4
parries para romper.

> **Aviso de riesgo Pilar 1**: subir solo este número sin acompañarlo de mayor
> variabilidad de cadencia/patrón (propiedad de "IA de Combate de Jefes") sería
> indistinguible de un *grind* de resistencia. La dificultad real debe vivir en
> que sea más difícil *acertar* esos parries, no en que haya más.

### 3. Ciclos objetivo y % de daño de Golpe de Castigo

`punish_dano_pct = 100 / ciclos_objetivo(tríada)`, donde
`ciclos_objetivo(tríada) = ciclos_objetivo_base + índice_tríada`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Ciclos objetivo base | `ciclos_objetivo_base` | int | **4 (constante forzada, ver Interacciones entre knobs)** | Término base de la fórmula — **es el knob de Tuning Knobs, no un literal** |
| Ciclos objetivo | `ciclos_objetivo` | int | 4–6 | Nº de ciclos parry→ruptura→castigo para vencer al ángel (Humanidad=4, Cosmos=5, Cercanía a Dios=6) |

**Output Range:** 25% (Humanidad), 20% (Cosmos), 16.7% (Cercanía a Dios) de vida
máxima por golpe de castigo. Nunca permite matar en 1 ciclo (mínimo 4), nunca
exige más de 6 (evita attrition-fest).

**Ejemplo**: Cercanía a Dios, `ciclos_objetivo=6` → `punish_dano_pct ≈ 16.7%` → 6
Golpes de Castigo para vaciar la Vida.

El % de daño por golpe *baja* ligeramente en tríadas altas — se comunica como
"el ángel es más resiliente" (Pilar 3), no como debilidad del jugador.

### 4. Duración de Retreat post-parry

`retreat_time = retreat_base` (constante, no derivada)

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Retreat base | `retreat_base` | float (const) | 0.6–0.9s | Ventana de bajo riesgo tras cada parry exitoso, antes del siguiente Telegraph |

**Output Range:** actualmente 0.7s (ajustable dentro del rango seguro 0.5–1.2s de
Tuning Knobs — no es un valor arquitectónicamente fijo, solo no se deriva de otra
fórmula). No escala por tríada — la dificultad diferencial vive en
telegraph/cadencia (sistema 20), no en el descanso post-parry.

**Excepción (combos)**: `retreat_time` **no** se aplica entre golpes de un mismo
combo (Regla 9) — se dispara una única vez al resolverse el combo completo (éxito
total o interrupción por fallo), nunca entre golpes intermedios. Ver Regla 9 y
C.4.

**Excepción (Ventana Especial)** *(añadida el 2026-08-04, changeset 1 de la 3ª
pasada de `/design-review`)*: esta fórmula se cuantifica sobre parries resueltos
contra un **`Golpe`**. Un parry exitoso resuelto contra una **Ventana Especial**
**no dispara Repliegue en absoluto** — el jefe pasa a `Enfriamiento` (Regla 4,
tabla de consecuencias; verificado por el AC **C20** punto 4), así que
`retreat_time` no llega a evaluarse. *(La formulación anterior no decía "Golpe" en
ninguna parte y por eso **evadió el barrido léxico de la enmienda A**: expresaba el
cuantificador incompleto sin nombrar al constructor. Es la raíz **A** de la 3ª
pasada — un tipo suma obliga a visitar cada consumidor, no cada aparición de una
palabra.)*

**Ejemplo**: parry exitoso en t=1.00s (golpe simple, no en combo) → próximo
Telegraph inicia en t=1.70s.

### 5. Vida Máxima del Jugador

`vida_maxima = vida_base + (angeles_absorbidos * bono_vida_por_absorcion) + bono_reliquias`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Vida base | `vida_base` | int | 100 | Vida al inicio de cada run |
| Ángeles absorbidos | `angeles_absorbidos` | int | 0–3 en v1.0/Alpha (un ángel por tríada implementada); 0–9 en visión completa (un ángel por cada uno de los 9 coros del ascenso, ver `game-concept.md` — no 26; esa cifra era incorrecta y se corrige aquí) | Cuenta de elecciones "absorber" tomadas esta run (evento del Sistema de Gracia, sistema 5 — no decidido en este GDD) |
| Bono por absorción | `bono_vida_por_absorcion` | int | **15–20 (rango canónico único — ver Tuning Knobs, antes había dos rangos contradictorios)** | Vida ganada por cada absorción — provisional, a validar junto con el GDD de Gracia |
| Bono de reliquias | `bono_reliquias` | int | **0–25 con los valores de lanzamiento — acotado por R10a, no "0+"** | Suma de bonos de Vida de reliquias equipadas (owned por sistema 9). El techo **no es un número fijo**: se deriva de R10a, que exige que las reliquias no compren más de **un golpe sobrevivido**. La cuenta vinculante es la de **0 absorciones** — a 3 absorciones la misma invariante dejaría +46, y evaluarla solo ahí dejaría pasar casi el doble de lo legal |

**Output Range:** 100–200 con los valores de lanzamiento. El techo **ya no queda abierto
a la GDD de Reliquias**: lo fija **R10a** sobre la magnitud (máximo 8 golpes
sobrevividos), no sobre ningún término de esta fórmula. *(Hasta el 2026-08-04 decía
"100+ sin límite superior fijado en este GDD", que era literalmente cierto y
operativamente falso: `bono_reliquias` está en una suma que este GDD posee.)*

**Ejemplo**: `vida_base=100`, 2 ángeles absorbidos de 3 (bono=18 c/u), 1 reliquia
de +10 vida → `vida_maxima = 100 + 36 + 10 = 146`. Rechazar el tercer ángel deja
al jugador en 128 — más débil, pero sin ese peso de corrupción.

> **Decisión de diseño clave**: absorber concede poder de supervivencia real
> (Vida máxima); rechazar no lo concede. El dilema moral del Sistema de Gracia
> deja de ser solo narrativo — es la única palanca de supervivencia para duelos
> posteriores más difíciles. Esto crea una dependencia formal de este GDD hacia
> el Sistema de Gracia (5) y Elección de Reliquias (9) — ver Dependencies.

### 6. Daño Real del Golpe de Castigo

`dano_golpe_castigo = vida_max_angel * (punish_dano_pct / 100) * multiplicador_ataque`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Vida máxima del ángel | `vida_max_angel` | int | según tríada (owned por IA de Combate de Jefes, sistema 20) | El 100% de vida de ese ángel específico |
| % de daño de castigo | `punish_dano_pct` | float | 16.7%–25% | De la Fórmula 3 |
| Multiplicador de ataque | `multiplicador_ataque` | float | **= 1.0 exactamente (constante, no rango — ver invariante abajo)** | Gancho de integración con el sistema 9, **cerrado en ambos sentidos**: ninguna reliquia puede subirlo ni bajarlo |

**Output Range:** depende de `vida_max_angel` (no fijado aquí). Con
`multiplicador_ataque` fijado en 1.0, `dano_golpe_castigo` queda determinado
únicamente por `vida_max_angel` y la tríada.

**Ejemplo**: ángel de Cosmos con 200 de vida, `punish_dano_pct=20%`,
`multiplicador=1.0` → `dano_golpe_castigo = 200 * 0.20 * 1.0 = 40`, es decir
exactamente los 5 ciclos que la Fórmula 3 exige para Cosmos.

> **Regla de clamp de la Vida del jefe (normativa)** *(añadida el 2026-08-04,
> changeset 1 de la 3ª pasada)*. Si al aplicar `dano_golpe_castigo` la Vida
> resultante queda **por debajo de 0**, se **clampa a 0**; el exceso no se
> transfiere, no se acumula y no produce efecto alguno. Un residuo de valor absoluto
> `≤ 1e-6` se trata como 0 a todos los efectos. **Tras el clamp**, `Vida == 0`
> clasifica el golpe como **letal** (Regla 5, acotación de la enmienda G; AC
> **E11**) y `Vida > 0` como **no letal** (AC **E10**): la partición es total y sin
> solapamiento.
>
> **Por qué hace falta.** `punish_dano_pct = 100 / ciclos_objetivo` no es
> representable en binario para dos de las tres tríadas: Cosmos da 20% (exacto en
> decimal, no en binario) y **Cercanía a Dios da `100/6 = 16.666…%`**. En doble
> precisión, `6 × (200/6) = 200.00000000000003` — el sexto castigo deja la Vida en un
> **negativo minúsculo, no en 0 exacto**. La Postura ya tenía su regla de overkill
> desde la primera versión (Edge Cases, AC **E5**); la Vida del jefe **nunca la
> tuvo**, así que E10 (`> 0`) y E11 (`= 0`) no eran partición exhaustiva y el fixture
> de E11 no era construible de forma fiable. Es la raíz **C** de la 3ª pasada — la
> guarda puesta sobre un recurso y no sobre el otro. Hallazgo convergente de
> `systems-designer` y `qa-lead`.

> **Invariante corregida (hallazgo de `systems-designer`, adjudicado por
> `creative-director`)**: la versión anterior de este GDD declaraba la restricción
> `punish_dano_pct × multiplicador_ataque < 100`. **Esa desigualdad es la
> equivocada**: solo previene matar de un golpe. Como `punish_dano_pct` ya es
> `100 / ciclos_objetivo`, el número real de ciclos necesarios es
> `ciclos_objetivo / multiplicador_ataque`, así que la invariante que de verdad
> protege el suelo de 4 ciclos es:
>
> ```text
> ciclos_objetivo(tríada) / multiplicador_ataque ≥ ciclos_objetivo(tríada)
>   ⟺  multiplicador_ataque ≤ 1.0
> ```
>
> Con el rango antiguo (1.0–1.5+), una reliquia de daño a 1.5 mataba a un ángel de
> Cercanía a Dios en **4 golpes en vez de 6**, y a uno de Humanidad en **3 en vez de
> 4** — violando el suelo de la Fórmula 3 mientras pasaba tranquilamente el chequeo
> `< 100` (37.5 < 100). **Decisión tomada en revisión: el suelo de ciclos es
> absoluto.** Alinea con el Pilar 2 y con el anti-pilar "la dificultad no se resuelve
> con números".
>
> **Corrección de la re-review (2026-08-01): la desigualdad de un solo lado también
> era insuficiente.** `systems-designer` señaló que `multiplicador_ataque ≤ 1.0` no
> acota por abajo, y el Golpe de Castigo es *la única fuente de daño del jugador*. Con
> 0.5, Cercanía a Dios pasaría de 6 a **12** golpes de castigo (attrition-fest, lo que
> la Fórmula 3 dice evitar explícitamente); con `multiplicador_ataque → 0`,
> `dano_golpe_castigo → 0` y **el duelo se vuelve mecánicamente inganable** sin violar
> ninguna regla escrita. **Decisión de usuario: `multiplicador_ataque` deja de ser un
> rango y pasa a ser la constante 1.0.** El sistema 9 no puede tocar el daño de
> castigo en absoluto — ni al alza ni a la baja. Es la formulación más simple que
> cierra la clase entera de bug, y es coherente con lo que este GDD ya declaraba: las
> reliquias no son la vía de personalización del daño de castigo. Coste aceptado: se
> cierra el arquetipo de "reliquia maldita de daño"; el sistema 9 debe expresar esa
> fantasía en otra dimensión (ver Open Questions).

Esta es la **única fuente de daño del jugador** — no hay ataque básico fuera de
la ventana de Aturdimiento (Regla C.5), coherente con arma única y fija.

> **Consecuencia para el sistema 9 (Elección de Reliquias)**: las reliquias **no
> pueden ser la vía de personalización del daño de castigo**, porque cualquier
> aumento rompe el suelo de ciclos. Este GDD declara la restricción aunque no
> posea las reliquias, exactamente por la misma razón que ya lo hacía antes: es
> quien posee la invariante que se rompería.
>
> ⚠️ **Esta consecuencia, tal y como estaba escrita, causó el siguiente agujero**
> *(corregido el 2026-08-04, changeset 2 ítem 2)*. La formulación anterior remataba
> recomendando *"otra dimensión — p. ej. Vida máxima, que este GDD ya soporta vía
> `bono_reliquias`"*: es decir, al cerrar el daño **empujaba al sistema 9 hacia el único
> término de la Fórmula 5 que R5 dejaba sin guardar**. La colisión era predecible, no
> casual. Y R4 sigue sin cubrir la reliquia **estructural**: un Golpe de Castigo extra
> por aturdimiento rompe el suelo de ciclos **sin tocar `multiplicador_ataque`**, y
> **D8 pasa en verde** mientras ocurre.
>
> **El contrato real con el sistema 9 es ahora R10**, escrito sobre cuatro magnitudes
> observables y no sobre mecanismos: `golpes_sobrevividos` · `ciclos_efectivos` ·
> `parries_por_ciclo` · cobertura temporal efectiva. Espacio que le queda: hasta **+25
> de Vida** o **−20% de daño recibido** (no ambos), modificadores de ventana bajo R10d,
> y utilidad pura. Ver Restricciones conjuntas y los ACs **C26**, **D15**, **D16**.

### 7. Gracia por parry (incluyendo combos)

`gracia_ganada = gracia_base * modificador_combo`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Gracia base | `gracia_base` | float | valor owned por Sistema de Gracia (5) | Mota de gracia por un parry de golpe simple. Este GDD **no fija su valor** — solo define cómo se modula en combos |
| Modificador de combo | `modificador_combo` | float | 1.0 (golpe simple) / 0.5 (cada parry dentro de un combo) | Reduce la gracia por parry dentro de una secuencia encadenada |

**Output Range:** un golpe simple concede `gracia_base`. Un combo de N golpes
concede `N * gracia_base * 0.5` en total.

**Ejemplo**: con `gracia_base = 1.0` — un golpe simple parado concede 1.0 de
gracia. Un combo de 3 golpes completamente parado concede `3 * 1.0 * 0.5 = 1.5`
de gracia total: más que un golpe simple, pero menos que 3 golpes simples.

> **Invariante R7 — la garantía de la Regla 9 no se cumple sola** (hallazgo de
> `systems-designer`, re-review 2026-08-01). La Regla 9 promete que "un combo genera
> más gracia total que un golpe simple". Eso equivale a `N × modificador_combo > 1`,
> es decir `modificador_combo > 1 / N`. **Con el valor de lanzamiento `0.5` y un combo
> de N=2, el producto es exactamente `1.0` — igual, no mayor: la garantía fallaba en
> el propio valor shippeado**, no en un extremo de tuning. En el suelo del rango
> antiguo (0.3) daba `0.6`, es decir **menos** gracia que un golpe simple a cambio de
> dos parries consecutivos sin margen y de perderlo todo si se falla el segundo.
>
> **Decisión de usuario**: fijar `N_min = 3` (Regla 9) en vez de retunear un valor ya
> calibrado. Con `N_min = 3`, la invariante es `modificador_combo > 1/3 = 0.333`, que
> el valor actual (0.5) cumple con holgura y que recorta el rango seguro del knob a
> **0.35–0.8** (antes 0.3–0.8). El umbral matemático exacto es `1/3 = 0.3333…`, no
> 0.34: el tramo estrictamente prohibido es `[0.30, 0.3333]`, y el suelo se fija en
> 0.35 por margen de seguridad, no porque 0.34 fuera ilegal. Formalizado como **R7**
> en Restricciones conjuntas.

**Consecuencia de diseño**: los combos son ricos en gracia y pobres en postura —
enfrentarse a ángeles de ataques rápidos te corrompe más rápido por cada punto de
progreso que consigues. Los ángeles con patrones de combo son, literalmente, los
más peligrosos para el alma del protagonista, no solo para su vida.

### 8. Daño de Golpe enemigo

*(Añadida el 2026-08-04, changeset 2 de la 3ª pasada. Punto de entrada del changeset:
esta fórmula y la economía de riesgo de la Ventana Especial se bloqueaban mutuamente
—ver R9— y se resolvieron como una sola tarea.)*

`dano_golpe_enemigo = vida_base / golpes_para_morir_base`

| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| Vida base | `vida_base` | int | 100 (rango 80–150; suelo efectivo 110 por R5) | **El ancla de esta fórmula — nunca `vida_maxima`.** De la Fórmula 5 |
| Golpes para morir | `golpes_para_morir_base` | int | 3–6 (actual: **4**) | `Golpe`s no parados que matan a un jugador **a Vida base**, sin absorciones ni reliquias. Es el **presupuesto de error del duelo** |

**Output Range:** con los valores de lanzamiento, **25 exacto**. En el rango completo
de `vida_base` (80–150) y `golpes_para_morir_base` (3–6): 13.3–50.

**Ejemplo**: `vida_base = 100`, `golpes_para_morir_base = 4` →
`dano_golpe_enemigo = 25`. Un jugador sin absorciones muere al cuarto `Golpe` no
parado (100 → 75 → 50 → 25 → 0); con las 3 absorciones de v1.0 (`vida_maxima = 154`)
muere al séptimo. Verificado por **D11** y **D12**.

> **Por qué la división directa y no `vida_base × (pct / 100)`.** La forma en
> porcentaje es la que usa la Fórmula 3 para el lado del jefe, y es exactamente la que
> obligó a escribir la regla de clamp de la Vida del jefe: el viaje de ida y vuelta
> por un porcentaje no representable en binario (`100/6 = 16.666…`) deja residuos que
> convierten un 0 exacto en un negativo minúsculo. `vida_base / golpes_para_morir_base`
> hace la división **una sola vez** y con los valores de lanzamiento da un entero
> exacto. **No elimina la necesidad del clamp** —fuera de `vida_base = 100` el cociente
> deja de ser entero— y por eso el clamp de la Vida del jugador se declara abajo; lo
> que elimina es la clase de residuo *adicional* que la forma en porcentaje introduce
> gratis.

> **El ancla es `vida_base`, y es una decisión de diseño, no una conveniencia
> aritmética.** Si esta fórmula colgase de `vida_maxima`, el daño escalaría junto con
> la Vida ganada al absorber y el jugador moriría **siempre en el mismo número de
> golpes**, hiciera lo que hiciera. Absorber dejaría de comprar supervivencia y la
> "decisión de diseño clave" de la Fórmula 5 —el pivote mecánico del dilema moral
> entero— se volvería decorativa. Anclando en `vida_base`, el swing de R5 adquiere
> contenido operativo: el 54% de Vida extra que compran tres absorciones **son golpes
> encajados de más**, que es la moneda en la que el jugador percibe su propia
> corrupción. Fijado por **D11**, cuyo caso de 3 absorciones es el único que distingue
> las dos anclas — a 0 absorciones ambas implementaciones pasan.

> **El daño no escala por tríada, y eso es el Pilar 1 aplicado literalmente.** Los tres
> índices producen el mismo número. La dificultad diferencial ya está en la longitud
> del duelo: el mismo presupuesto de 4 errores se estira sobre **12** parries en
> Humanidad y sobre **30** en Cercanía a Dios, es decir, la tolerancia al error cae del
> 33% al 13% sin tocar una sola cifra. Es exactamente lo que el preámbulo de esta
> sección exige — "la dificultad entre tríadas viene de exigir más parries y más
> ciclos, nunca de números artificialmente más grandes". Por la misma razón **no existe
> un `severidad_golpe` por tipo de ataque**: un multiplicador sin acotar por ambos
> lados ya ha mordido a este documento en `multiplicador_ataque` (R4, corregido dos
> veces) y en `bono_reliquias` (bloqueante abierto). Si el sistema 20 lo necesita más
> adelante, entra con banda de dos lados desde el primer día, no después.

> **Regla de clamp de la Vida del jugador (normativa).** Si al aplicar
> `dano_golpe_enemigo` —o la severidad de una `Acción Especial` completada, ver R9— la
> Vida resultante queda **por debajo de 0**, se **clampa a 0**; el exceso no se
> transfiere, no se acumula y no produce efecto alguno. Un residuo de valor absoluto
> `≤ 1e-6` se trata como 0 a todos los efectos. **Tras el clamp**, `Vida == 0` es la
> condición exacta que dispara **"duelo perdido"** (Regla 6, Dependencies), sin
> depender de ninguna comparación `< 0`. Verificado por **E13**.
>
> **Por qué hace falta, y por qué no se detectó antes.** El changeset 1 le dio regla de
> overkill a la Vida del jefe justificándola como "el único recurso agotable del
> sistema sin ella" — afirmación **falsa en el momento de escribirse**: la Vida del
> jugador tampoco la tenía. Pasó desapercibido porque hasta este changeset **el daño al
> jugador no era una cantidad calculada**: la Regla 6 decía "reduce su Vida actual" sin
> fórmula, así que no había magnitud capaz de desbordar. Esta fórmula la crea, y con
> `vida_base` en 80–150 el cociente **no es entero en la mayor parte del rango** (con
> el suelo efectivo 110 que impone R5, `110/4 = 27.5`). Es la cuarta aparición de la
> raíz **C** —la guarda puesta sobre un recurso y no sobre el otro— y la simetría con
> E5 (Postura), E12 (Vida del jefe) y ésta (Vida del jugador) queda ahora completa.

**Relación con el resto del sistema**: es la **única fuente de daño al jugador**
junto con la severidad de una `Acción Especial` completada (R9). Una **Ventana
Especial** no parada **no** usa esta fórmula — no daña en absoluto (corolario de la
Regla 6); lo que daña es la habilidad que esa ventana ofrecía interrumpir, y su
magnitud la acota R9, no esta fórmula.

## Edge Cases

| Escenario | Comportamiento esperado | Justificación |
|---|---|---|
| El jugador intenta parry sin **ninguna ventana parable** activa ni pendiente dentro de la ventana (durante Telegrafiado, Enfriamiento o Repliegue) *(cuantificador ampliado el 2026-08-04, enmienda A: antes decía "sin Golpe", lo que hacía whiff todo intento contra una Ventana Especial)* | El intento se resuelve como "vacío" (whiff): sin daño de Postura, sin Gracia, **sin coste de recurso alguno**, pero entra en Recuperación de whiff (`recuperacion_whiff` fotogramas) durante la cual no puede iniciarse otro parry | Distinto de un fallo real — no había amenaza que leer mal. El coste es **de tiempo, no de recurso**, y existe únicamente para cerrar el ciclo de mash (Regla 7): sin él la cobertura temporal del parry era del 81–87% y machacar el botón dominaba la lectura de patrones. El jugador que explora el timing paga una pausa breve; el que machaca paga el 41% de su tiempo |
| El jugador pulsa el botón en los últimos `gracia_salida_castigo` fotogramas de `ventana_castigo`, o en el instante exacto en que la Postura se restaura | La pulsación se interpreta como **Parry**, no como Golpe de Castigo (Regla 5, ventana de gracia de salida) | Sin esta regla, pulsar 2 fotogramas tarde compromete al jugador a 10–14 fotogramas de recuperación justo cuando el enemigo reanuda su ciclo — un golpe inevitable por un borde de estado, no por una lectura equivocada. Mismo principio de perdón que la Regla 3, aplicado al borde opuesto |
| El jugador pulsa el botón durante la recuperación de un Golpe de Castigo o durante la Recuperación de whiff | El input se **descarta por completo**: no se almacena en buffer ni se ejecuta al terminar la recuperación | Un input en buffer aquí reintroduciría el mash por la puerta de atrás — el jugador machacaría durante la recuperación y saldría de ella con un parry ya encolado. El descarte es lo que hace que el coste temporal sea real |
| El jugador falla el parry y el Golpe conecta | El enemigo continúa su ciclo normal (pasa a Enfriamiento según su propia cadencia, sistema 20); no recibe Repliegue extra ni bonificación | Fallar no debe acelerar ni ralentizar al enemigo — la cadencia debe seguir siendo legible y predecible en su estructura, aunque varíe en tiempos |
| El daño de Postura deja el valor por debajo de 0 (overkill) | Se clampa a 0; el exceso no se transfiere ni se acumula para el siguiente ciclo | Mantiene consistente el valor de cada ciclo — un ciclo excepcional no adelanta trabajo del siguiente |
| El input de parry llega exactamente en el límite de `parry_window`, o en el instante exacto de inicio del Golpe | El límite es **inclusivo** en ambos extremos (`<=` y `>=`) | Nunca excluir un parry por un solo fotograma en el borde — coherente con el hallazgo del prototipo de que el perdón de timing es lo que separa "justo" de "aleatorio" |
| La Postura llega a 0 mientras el jugador está en medio de un estado Parry de otro intento | El Aturdimiento del enemigo se dispara de inmediato, sin importar el estado del jugador; la ventana de Golpe de Castigo se abre sin demora | La recompensa nunca debe retrasarse por un tecnicismo de estado del jugador |
| El jugador no conecta el Golpe de Castigo antes de que expire la ventana de Aturdimiento | El enemigo sale del Aturdimiento, su Postura se restaura **por completo** a `postura_max`, y retoma su ciclo normal | La apertura se pierde entera, sin reset parcial — mantiene consistentes las apuestas de cada ciclo y hace que la ventana de castigo importe de verdad |
| El jugador **sí** conecta el Golpe de Castigo dentro de la ventana y el golpe es **no letal** (la Vida del jefe queda **> 0** tras el clamp) | El enemigo sale del Aturdimiento, recibe daño de Vida (Fórmula 6), su Postura se restaura **por completo** a `postura_max`, y retoma su ciclo normal | Cada ciclo cuesta el mismo número de parries que el anterior, sin acarreo — es la premisa silenciosa de la Fórmula 3 y del conteo 12/20/30. La Postura se restaura íntegra en **ambas** salidas *no letales* del Aturdimiento; lo único que cambia es si se aplicó daño de Vida *(fila añadida en la re-review; **acotada a "no letal" el 2026-08-04, changeset 1**: la enmienda G acotó la Regla 5 y el AC E10 pero **no esta fila**, que duplicaba la afirmación de forma independiente y seguía siendo incondicionalmente falsa para el castigo letal. Raíz **B**, hallazgo de `qa-lead`)* |
| El jugador conecta el Golpe de Castigo y el golpe es **letal** (deja la Vida del jefe en **0** tras el clamp) | El enemigo **no** sale de Aturdido hacia su ciclo, **no** restaura Postura, **no** reanuda su cadencia de ataque y **no** vuelve a emitir ninguna ventana parable: entra en el estado terminal `Muerto` del sistema 2, que es quien emite "duelo ganado". El duelo termina en victoria | El último castigo de cada duelo es, por definición, la excepción al caso general — y **no es un borde raro**: con `ciclos_objetivo` de 4/5/6 es uno de cada 4, 5 o 6 castigos, y es el único que el jugador recuerda. Ver la acotación de la Regla 5 (enmienda G) y el AC **E11** *(fila añadida el 2026-08-04, changeset 1)* |
| El daño del Golpe de Castigo deja la Vida calculada del jefe **por debajo de 0** (overkill), o en un residuo de coma flotante distinto de 0 exacto | Se clampa a **0**. El exceso no se transfiere, no se acumula ni produce efecto alguno. Un valor absoluto `≤ 1e-6` se trata como 0 a todos los efectos. Tras el clamp, `Vida == 0` clasifica el golpe como **letal** y `Vida > 0` como **no letal** — la partición es total y sin solapamiento | **Simetría con E5**, que ya clampa la Postura: la Vida del jefe carecía de la regla equivalente. No es un borde teórico: `punish_dano_pct = 100/6 = 16.666…%` para Cercanía a Dios no es representable en binario, y en doble precisión `6 × (200/6) = 200.00000000000003`, de modo que el sexto castigo deja un negativo minúsculo en vez de 0 exacto. Sin esta regla, **E10 ("> 0") y E11 ("= 0") no forman partición exhaustiva** y el fixture de E11 no es construible de forma fiable *(fila añadida el 2026-08-04, changeset 1; hallazgo convergente de `systems-designer` y `qa-lead`, verificado por `creative-director`)* |
| El jugador falla un golpe intermedio de un combo y los golpes restantes seguirían llegando mientras está en recuperación de Recepción de golpe | **No llegan**: el combo se aborta por completo (Regla 9). El ángel pasa a Repliegue. El jugador recibe **exactamente un** golpe, nunca N | Un whiff mal cronometrado antes de un combo cuesta un golpe, no el combo entero. Sin esta aclaración, los 9 ticks de Recuperación de whiff podían leerse como una sentencia encadenada de N golpes inevitables |
| La Vida del jugador llega a 0 durante la ventana de Aturdimiento del enemigo | La derrota del jugador tiene prioridad absoluta sobre cualquier estado del enemigo; el duelo termina en derrota | Sin excepciones dramáticas ni "muerte heroica" — el Pilar 2 exige que el fallo sea fallo |
| El jugador falla un golpe a mitad de un combo (Regla C.9) | Ese golpe conecta, el combo se interrumpe, y **no se aplica daño de Postura alguno** — se pierden también los parries ya acertados de ese combo | Es lo que hace que los combos sean la palanca de dificultad correcta: exigen ejecución completa, no parcial. La gracia ya concedida por los parries acertados **sí se conserva** (ya fue absorbida) |
| Un combo completo es parado con éxito | Se aplica **una sola** instancia de daño de Postura (Fórmula 1, usando la calidad del último parry) y gracia reducida por cada parry (Fórmula 7) | Más habilidad por la misma recompensa de progreso — Pilar 1 y Pilar 2 en conjunto |
| El jugador rechaza la esencia de algunos ángeles y absorbe la de otros | Cada decisión es **independiente**: `angeles_absorbidos` cuenta solo las decisiones "absorber", en cualquier orden y combinación. Rechazar a uno no impide absorber a los siguientes | Es el núcleo del dilema moral del juego — debe poder ejercerse ángel por ángel, no como un compromiso irreversible de una vez |
| El jugador rechaza la esencia de **todos** los ángeles de una run | `angeles_absorbidos = 0` durante toda esa run; la Vida Máxima depende solo de `bono_reliquias` (Fórmula 5) | Configuración de juego válida y deliberada (pureza total), no un estado de error — es la ruta más difícil y temáticamente la más pura |

## Dependencies

| Sistema | Dirección | Naturaleza de la dependencia |
|---|---|---|
| Sistema de Gracia de Tres Capas (5) | **Bidireccional** — ciclo documentado | Gracia consume el evento "parry exitoso" y el valor `gracia_ganada` (Fórmula 7). Combate consume `angeles_absorbidos` (Fórmula 5). Contrato de datos mutuo — ver `systems-index.md`, Circular Dependencies. **Combate impone a Gracia**: la Gracia obtenida al parar una Ventana Especial debe tener **coste no nulo** en la economía de corrupción (**R9b**) — si Gracia fuese beneficio sin contrapartida, parar la Ventana Especial dominaría a ignorarla y R9a no lo detectaría |
| Elección de Reliquias entre Duelos (9) | Combate depende de Reliquias | Consume `bono_reliquias` (Fórmula 5) y `multiplicador_ataque` (Fórmula 6). **Combate impone a Reliquias**: la invariante **R10 sobre cuatro magnitudes** —`golpes_sobrevividos` (+1 como máximo, R10a), `ciclos_efectivos` exacto (R10b), `parries_por_ciclo` exacto (R10c) y cobertura temporal efectiva (R10d)—, **independiente del mecanismo**, más la obligación de declarar todo efecto como delta sobre esas cuatro (AC **C26**). `multiplicador_ataque = 1.0` (R4) y R6 sobre efectivos (D10) siguen vigentes como guardas de mecanismo, subsumidas por R10 |
| Máquina de Estados de Jefe (2) | Bidireccional | Consume sus eventos de ventana activa ("inicio/fin de Golpe", "inicio/fin de Ventana Especial"); le provee de vuelta el resultado del parry y la Postura resultante. Reparto de tres partes: el **20** posee duraciones y composición, el **2** posee la emisión de los eventos, y este GDD el consumo y la resolución. **El 2 impone a este GDD**: la excepción de Ventana Especial en la Regla 4 |
| IA de Combate de Jefes — Patrones (20) | Combate depende de IA | Consume la composición de combos por patrón, `vida_max_angel`, y la cadencia variable por ángel (los eventos de ventana los emite el sistema 2). **Combate impone a IA**: `3 ≤ N ≤ 5` de longitud de combo (R7 + audio), varianza de separación intra-combo (nota de R6), hueco para el ciclo de whiff en el encuentro tutorial, y **la severidad de toda `Acción Especial` interrumpible — banda `1.0 ≤ s ≤ 2.0` por ventana y `Σ s ≤ golpes_para_morir_base − 1` por duelo, pagada en Vida (R9a, AC D13)** |
| Feedback de Impacto — Hitstop/Cámara (4) | Feedback depende de Combate | Consume "parry exitoso", "parry fallido", "ruptura de Postura", "golpe de castigo conectado" |
| Feedback Sonoro del Parry (16) | Audio depende de Combate | Consume los mismos eventos que Feedback de Impacto |
| HUD de Combate (13) | HUD depende de Combate | Consume Postura enemiga actual, Vida del jugador, Vida enemiga |
| Accesibilidad (21) | Accesibilidad depende de Combate | Requiere que **`parry_window` y `recuperacion_whiff`** sean configurables externamente para un modo de asistencia, y tuneados como par (bajar solo el segundo viola R6) |
| Gestión de Run / Estructura de Ascenso (3) | Gestión de Run depende de Combate | Consume **"duelo perdido"**, que este GDD emite cuando la Vida del jugador llega a 0 (Regla 6, Fórmula 5). **"duelo ganado" NO es de este GDD** — lo posee y lo emite la Máquina de Estados de Jefe (2) al entrar en su estado terminal `Muerto`. Ver la nota de propiedad abajo |

> **Propiedad del par "duelo ganado" / "duelo perdido"** *(desambiguada el 2026-08-04,
> enmienda D)*. Los dos eventos son simétricos para Gestión de Run, pero **no tienen el
> mismo dueño** — y hasta esta enmienda **ambos GDDs se adjudicaban "duelo ganado"**: el
> sistema 2 de forma explícita (su Core Rule 6 y su estado terminal `Muerto`, en tres
> sitios distintos), y éste por implicación, al listarlo como evento que Gestión de Run
> le consume a Combate.
>
> **Criterio adoptado: cada evento lo emite el GDD que posee el recurso cuyo agotamiento
> lo causa.** La Vida del jefe la agota la Fórmula 6 de este GDD, pero el **estado
> terminal** que reconoce ese agotamiento es `Muerto`, del sistema 2 — y un evento de fin
> de duelo es una **transición de estado**, no un cálculo de daño. Por tanto:
>
> - **"duelo ganado" → sistema 2**, que posee `Muerto`.
> - **"duelo perdido" → este GDD**, que posee la Vida del jugador.
>
> **Ningún cambio es necesario en el sistema 2**: su mitad del contrato ya está escrita
> correctamente. Toda la corrección cae en este documento, que es lo que permitió
> aplicarla mientras aquél sigue congelado.

**Clasificación por rigidez:**

- **Duras** (el sistema no puede funcionar sin ellas): **IA de Combate de Jefes
  (20)** — sin los eventos de Golpe no hay absolutamente nada que parar.
- **Blandas** (el sistema funciona con valores por defecto hasta que existan):
  **Sistema de Gracia (5)** y **Elección de Reliquias (9)** — la Fórmula 5 opera
  correctamente con `angeles_absorbidos = 0` y `bono_reliquias = 0`, y la Fórmula 6
  con `multiplicador_ataque = 1.0`. Esto es lo que permite que Combate siga siendo
  capa Fundación pese al ciclo con Gracia.

## Tuning Knobs

| Parámetro | Valor actual | Rango seguro | Efecto de aumentar | Efecto de disminuir |
|---|---|---|---|---|
| `parry_window` | **0.22s → 13 fotogramas a 60fps (0.2167s), valor runtime canónico** *(medido en prototipo: 72% acierto)* | 0.15–0.30s (en fotogramas: 9–18 a 60fps, redondeando siempre hacia abajo — nunca más generoso que el valor de diseño en segundos) | Más perdón; por encima de 0.28 el reto desaparece (~90%+ acierto) | Menos perdón; por debajo de 0.15 se siente aleatorio (45% medido en prototipo) |
| `recuperacion_whiff` | **9 fotogramas** (0.15s a 60Hz) | 6–12 fotogramas | Machacar se castiga más; por encima de 12 el jugador que explora el timing se siente atascado | Menos castigo al mash; **por debajo de 6 la cobertura temporal vuelve a superar el 68% y el mash reaparece como estrategia viable** — es el suelo duro de este knob, no una preferencia |
| `recuperacion_recepcion` | **8–12 ticks** (0.133–0.2s a 60Hz) — el valor efectivo lo fija la animación de Recepción de golpe dentro de ese rango *(promovido de prosa a símbolo el 2026-08-04)* | 8–12 ticks | Más castigo por golpe recibido; por encima de 12 el jugador pierde también el turno siguiente y el fallo deja de ser proporcional a su causa | Menos castigo; por debajo de 8 la Recepción deja de leerse como "perdiste el turno" y el golpe recibido pierde el peso que Game Feel le exige |
| `gracia_salida_castigo` | **6 fotogramas** (0.1s a 60Hz) | 4–10 fotogramas | Más protección contra el compromiso accidental de Castigo; por encima de 10 se pierden castigos legítimos pulsados tarde | Menos protección; por debajo de 4 reaparece el golpe inevitable por borde de estado |
| `umbral_precision` | **5 ticks** (0.0833s), valor runtime canónico | **3–7 ticks** (antes "0.05–0.12s" — canonicalizado a ticks en el changeset 2 ítem 1; era la última duración del documento declarada en segundos, con el mismo defecto de 4.8 ticks no enteros que ya se corrigió en `hitstop_parry`) | Escala de calidad más ancha: más escalones y más fácil quedarse lejos del techo; por encima de 7 la escala excede la propia `parry_window` útil y R2 falla | Escala más estrecha y exigente; **por debajo de 3 quedan menos de 4 escalones** y `calidad_timing` deja de discriminar precisión — el bono se vuelve casi binario |
| `umbral_parry_justo` | **0.9** | 0.7–1.0 | Menos parries califican como Justos; el guiño `#FFF8E7` y la capa de audio se vuelven raros | Más califican; **a 0.7 o menos deja de ser una distinción de precisión** y el Feel AC "los playtesters lo distinguen sin que se les explique" se vuelve infalsable |
| `bono_hitstop_parry_justo` | **+2 ticks** en `calidad_timing = 1.0`, **+1** en `0.9`, **+0** por debajo *(promovido de prosa a knob el 2026-08-04: R8 y D9 lo nombraban desde el changeset 1 sin que existiera fila propia — mismo defecto de tipo que tuvo `recuperacion_recepcion`)* | +1–2 ticks, **acotado por R8** (`hitstop_parry + bono ≤ 8`) | Más peso al acierto preciso; por encima de 2 rompe R8 con el `hitstop_parry` actual | Por debajo de 1 el Parry Justo pierde su canal háptico y queda solo en color y audio |
| `bono_precision` | 0.4 | 0.3–0.5 | Mayor recompensa por precisión; por encima de 0.6 los duelos se acortan demasiado con buen juego | Menor incentivo a afinar el timing dentro de la ventana |
| `dano_base` (postura) | 10 | 8–15 | Menos parries por ciclo; acorta duelos | Más parries por ciclo; alarga duelos, riesgo de fatiga |
| `postura_base` | 30 | 20–40 | Duelos más largos en toda la progresión | Duelos más cortos; por debajo de 20 un ciclo se rompe en 2 parries |
| `incremento_postura_triada` | 10 | 5–15 | Curva de dificultad más pronunciada entre tríadas | Curva más plana; las tríadas se sienten intercambiables |
| `ciclos_objetivo_base` | 4 | **4 (constante — ver Interacciones entre knobs; no es un rango independiente con la estructura actual de la Fórmula 3)** | N/A — retunear exige rediseñar el término `+ índice_tríada` de la Fórmula 3 | N/A |
| `retreat_base` | 0.7s → **42 ticks**, valor runtime canónico | 0.5–1.2s (30–72 ticks) | Más aire para leer el feedback; por encima de 1.2 diluye la tensión entre golpes | Ritmo más agresivo; por debajo de 0.5 no da margen de lectura |
| `ventana_castigo` | 2.0s → **120 ticks**, valor runtime canónico | 1.2–3.0s (72–180 ticks) | Golpe de Castigo casi garantizado; la recompensa deja de exigir ejecución | Más exigente; por debajo de 1.2 se pierden aperturas ganadas con 3–5 parries, lo que se siente injusto |
| `hitstop_parry` | **5 ticks** (0.0833s) | **3–6 ticks** (techo bajado de 8 por R8 — ver abajo) | Más peso por golpe; **el total con el bono de Parry Justo (+1–2) no puede exceder 8 ticks**, por encima de lo cual el flujo del combate se entrecorta | Menos peso; por debajo de 3 el hitstop deja de leerse como impacto |
| `physics_ticks_per_second` | **60 — invariante de proyecto, no ajustable** | N/A (constante) | N/A — cambiarlo obliga a rederivar **todos** los valores en ticks del documento (ver Regla 2, regla normativa 4) | N/A |
| `vida_base` (jugador) | 100 | 80–150 | Más margen de error; diluye la presión de aprender el patrón | Menos margen; por debajo de 80 un solo fallo puede ser letal |
| `golpes_para_morir_base` | **4** → `dano_golpe_enemigo = 25` con `vida_base = 100` | 3–6 | Más presupuesto de error; por encima de 6 el duelo deja de castigar la lectura equivocada del patrón y la fase de aprendizaje pierde su función | Menos presupuesto; **por debajo de 4 el lockout de whiff se vuelve desproporcionado** — un `Golpe` que abre durante los 9 ticks de Recuperación es imparable por construcción, así que a 3 golpes el jugador que explora el timing puede perder un duelo por un coste que la Regla 7 declara "de tiempo, no de recurso" |
| `severidad_accion_especial` | N/A — la declara el sistema 20 por habilidad | **1.0–2.0 por ventana (banda legal impuesta por este GDD), con `Σ ≤ golpes_para_morir_base − 1` por duelo — invariante R9a** | Ignorar la Ventana Especial duele más; por encima de 2.0, o si la suma del duelo supera el presupuesto, **pararla pasa a ser obligatoria** y el dilema se destruye por el lado opuesto | Por debajo de 1.0 ignorar la Ventana Especial vuelve a dominar estrictamente a pararla (ver R9) |
| `bono_vida_por_absorcion` | 18 | **15–20 (rango canónico único, igual al de Fórmula 5)** | Absorber se vuelve casi obligatorio; **debilita el dilema moral** — no exceder 20 sin revisar el balance con `game-designer` | Absorber deja de compensar; el dilema pierde peso mecánico |
| `modificador_combo_gracia` | 0.5 | **0.35–0.8** (suelo elevado desde 0.3 — ver R7) | Los combos corrompen más rápido | Los combos pierden su identidad de gracia; **por debajo de 0.3333 un combo de 3 da menos gracia que un golpe simple** y la garantía de la Regla 9 se rompe (el suelo declarado es 0.35, por margen) |
| `N` (longitud de combo) | N/A — la fija el sistema 20 por patrón | **3–5 (rango legal impuesto por este GDD)** | Frases de audio más largas, más esquirlas acumuladas; por encima de 5 el cue ascendente del evento 7→8 es inimplementable | Por debajo de 3 la Fórmula 7 incumple la garantía de la Regla 9 (ver R7) |

> **`recuperacion_recepcion` — propietario y regla de consumo** *(enmienda C,
> 2026-08-04)*. Hasta esta enmienda la cifra "8–12 fotogramas" existía únicamente como
> prosa en la tabla de States and Transitions y en Animation Feel Targets: **sin nombre,
> sin propietario y sin rango declarado** — pese a que el AC **C9 del sistema 2** dice
> consumirla "por referencia, no duplicada", lo cual era literalmente imposible. No es
> una anomalía de valor sino **de tipo**: el contrato nombraba algo que no existía.
>
> **Propietario: este GDD.**
>
> **Regla de consumo (normativa)**: todo sistema que use `recuperacion_recepcion` dentro
> de una **invariante de seguridad** —cualquier propiedad de la forma "el jugador debe
> tener tiempo de reaccionar"— debe evaluarla en su **techo (12 ticks)**, nunca en el
> valor nominal ni en el suelo. Una invariante de ese tipo tiene que sostenerse en el
> **peor caso de compromiso del jugador**, y evaluarla en el suelo la vuelve
> auto-satisfacible. Es exactamente lo que la Core Rule 9 del sistema 2 ya hace al usar
> "Recepción 12" en su término `compromiso_restante_del_jugador`.

### Restricciones conjuntas (normativas)

> **Los rangos "seguros" de la tabla de arriba son seguros por knob, no en
> combinación.** Un hallazgo de `systems-designer` en revisión adversarial demostró
> que varias combinaciones de valores individualmente válidos producen resultados
> degenerados. Las siguientes desigualdades son **normativas**: cualquier retune debe
> verificarlas explícitamente, y deben cubrirse con tests automatizados de rango, no
> solo con criterio humano.

| # | Invariante | Con los valores actuales | Qué se rompe si falla |
|---|---|---|---|
| **R1** | `dano_base × (1 + bono_precision) < postura_base` | 10 × 1.4 = 14 < 30 ✓ | En los techos (`dano_base=15`, `bono_precision=0.5` → **22.5**) contra el suelo `postura_base=20`, **un solo Parry Justo rompe la Postura entera**, saltándose el mínimo de 3 parries por ciclo. **Ojo**: ese Parry Justo incluye el remate de un combo (Fórmula 1 calcula la calidad sobre el último parry), que es un input **entrenable y repetible** contra un patrón conocido — en los extremos, romper R1 no sería un accidente de borde sino una estrategia deliberada de one-shot de Postura |
| **R2** | `parry_window_ticks > 2 × umbral_precision_ticks` — **ambos knobs en ticks; el `× 60` desaparece** | 13 > 10 ✓ | El bono de Parry Justo se vuelve trivial y deja de premiar la precisión. **Región de fallo**: con `umbral_precision` en su techo (**7 ticks**) hacen falta >14 ticks, es decir **15 ticks (`parry_window` de diseño ≥ 0.25s)**; con `parry_window` en 13 la invariante falla desde `umbral_precision = 7`. La región insegura sigue siendo `[0.15, 0.25)`, el **66.7%** del rango declarado seguro. *(Reescrita el 2026-08-04, changeset 2 ítem 1: la conversión `× 60` vivía dentro de la invariante porque `umbral_precision` estaba en segundos — la invariante ya sabía que necesitaba ticks. Al canonicalizar el knob, la conversión sobra y la comparación pasa a ser entera.)* |
| **R3** | `ciclos_objetivo_base = 4` exactamente | 4 ✓ | Ver nota abajo — es una constante forzada, no un rango |
| **R4** | `multiplicador_ataque = 1.0` exactamente (**ambos lados**, no solo techo) | 1.0 ✓ | Por arriba: el suelo de ciclos de la Fórmula 3. Por abajo: con 0.5 son 12 ciclos en Cercanía a Dios, y con →0 el duelo es **inganable** siendo el Golpe de Castigo la única fuente de daño. Ver la invariante corregida en la Fórmula 6 |
| **R5** | `(bono_vida_por_absorcion × angeles_max) / vida_base ≤ 0.55` | (18×3)/100 = **54%** ✓ | El Pilar 1. **Dos de las cuatro esquinas la violan, no una**: con `bono=20, vida_base=80` el swing llega al **75%**, y con `bono=15, vida_base=80` —el **suelo** de ambos rangos— llega al **56.25%**, que también incumple. Absorber deja de ser una elección |
| **R6** | `parry_window_ticks / (parry_window_ticks + recuperacion_whiff) ≤ 0.65`, equivalente a `parry_window_ticks ≤ 1.857 × recuperacion_whiff` | 13 / 22 = **59%** ✓ | El cierre del mash — el hallazgo más grave de la revisión anterior. **Aplica también a los valores *efectivos tras reliquias*, no solo a los de lanzamiento** (ver nota R6 abajo) |
| **R7** | `modificador_combo_gracia > 1 / N_min` | 0.5 > 0.3333 ✓ | La garantía de la Regla 9 ("un combo genera más gracia que un golpe simple"). Ver la nota de invariante en la Fórmula 7 |
| **R8** | `hitstop_parry + bono_hitstop_parry_justo ≤ 8 ticks` | 5 + 2 = 7 ✓ | El flujo del combate. `hitstop_parry` declara 8 ticks como su propio punto de ruptura, pero Impact Moments **suma +1–2 ticks** de Parry Justo encima sin tope: en el techo antiguo (8) un Parry Justo daba 9–10 ticks, por encima del límite que el propio knob declara. Por eso el rango de `hitstop_parry` se recorta a **3–6** |
| **R9a** | *(al sistema 20)* `1.0 ≤ severidad_accion_especial ≤ 2.0` por Ventana Especial, **y** `Σ severidad ≤ golpes_para_morir_base − 1` sobre un duelo. **La severidad es una EQUIVALENCIA en unidades de `dano_golpe_enemigo`, no un pago en Vida** — ver la regla de conversión abajo | banda ✓ · suma ≤ 3 ✓ | La no-dominación de la Ventana Especial, **por los dos lados**: sin el suelo, ignorarla domina; sin el techo agregado, pararla se vuelve obligatoria. Ver el bloque abajo |
| **R9b** | *(al sistema 5)* la Gracia obtenida al parar una Ventana Especial debe tener **coste no nulo** en la economía de corrupción | pendiente del GDD de Gracia | La misma no-dominación, invertida. Ver el bloque abajo |
| **R10a** | *(al sistema 9)* `⌈vida_maxima / dano_golpe_enemigo⌉` con reliquias **excede como máximo en 1** al valor sin reliquias, **para las cuatro cuentas de absorción** | 4/5/6/7 sin reliquias; techo 8 | La premisa que justifica R5: absorber es **la** palanca de supervivencia. Presupuesto vinculante: **+25 de Vida** o **−20% de daño recibido** |
| **R10b** | *(al sistema 9)* `ciclos_efectivos(tríada) = ciclos_objetivo(tríada)` exactamente, **contando ciclos de Aturdido, no golpes de castigo** | 4/5/6 ✓ | El suelo de ciclos, por **cualquier** mecanismo. R4 solo cierra el multiplicador; un castigo extra por aturdimiento lo rompe sin tocarlo |
| **R10c** | *(al sistema 9)* `parries_por_ciclo(tríada)` a `calidad_timing = 0` `= ⌈postura_max / dano_base⌉` exactamente | 3/4/5 ✓ | La progresión 3/4/5 y el conteo 12/20/30 que la Fórmula 3 presupone |
| **R10d** | *(al sistema 9)* R6 sobre los valores **efectivos** de `parry_window` y `recuperacion_whiff` | 59% ✓ | El cierre del mash. Ya existía como nota de R6; se folia aquí para que las cuatro magnitudes estén en un solo sitio (AC **D10**) |

**Sobre R5 — dos knobs que nadie había declarado acoplados**: la guía previa de "no
exceder 20" se calibró contra `vida_base = 100` (54% de swing) y **nunca se
cruzó con el propio suelo de `vida_base` (80)**. `bono_vida_por_absorcion` y
`vida_base` deben tunearse **como par**, no como filas independientes.

> ⚠️ **El suelo de `bono_vida_por_absorcion` tampoco es seguro** *(hallazgo de
> `systems-designer`, 3ª pasada; corregido el 2026-08-04, changeset 1)*. La
> formulación anterior de esta nota y de la fila R5 documentaban **solo la esquina del
> techo** —`(20×3)/80 = 75%`— y con ello inducían a leer "no exceder 20" como la
> guía completa, es decir, a creer que el suelo del rango (15) es seguro en toda
> circunstancia. **No lo es**: `(15×3)/80 = 45/80 = 56.25% > 55%`. Es decir, **incluso
> el valor más conservador del knob más delicado del sistema viola R5 cuando
> `vida_base` está en su propio suelo legal.** Ninguna de las dos revisiones
> anteriores lo detectó porque ambas evaluaron el acoplamiento en la dirección de "qué
> pasa si subimos el bono", nunca en la de "qué pasa si bajamos la vida base".
>
> **Consecuencia operativa**: `vida_base = 80` no es un valor de tuning libre mientras
> `angeles_max = 3`. Para que R5 se cumpla en **todo** el rango de
> `bono_vida_por_absorcion`, el suelo efectivo de `vida_base` es
> `⌈(20×3)/0.55⌉ = 110`; para que se cumpla al menos en el suelo del bono, es
> `⌈(15×3)/0.55⌉ = 82`. La fila de `vida_base` en Tuning Knobs sigue declarando 80–150
> **por knob**, que es correcto — pero **no en combinación**, y ése es exactamente el
> contrato que este bloque existe para expresar. Verificado por D9(b), que ahora
> declara 2 violaciones esperadas en R5, no 1.

> ✅ **CERRADO en el ítem 2 por R10a — R5 acotaba la razón en Vida, no la magnitud que el
> jugador percibe** *(detectado el 2026-08-04 al derivar la Fórmula 8, registrado sin
> cerrar por la regla "ningún hallazgo se cierra en la sesión en que se encuentra", y
> cerrado en la sesión siguiente al reescribir el contrato con el sistema 9 sobre
> magnitudes)*. R5 mide el swing de corrupción como razón de
> **puntos de Vida** (54%, bajo el techo de 55%). Pero la moneda en la que el jugador
> percibe ese swing son **golpes sobrevividos**, y el redondeo hacia arriba la
> amplifica: `⌈100/25⌉ = 4` golpes sin absorber frente a `⌈154/25⌉ = 7` con las tres
> absorciones — un **+75%**, no un +54%. R5 se calibró sobre el término y no sobre la
> magnitud; es la misma forma de la raíz **C**, aplicada a la invariante que guarda el
> knob más delicado del juego. Verificado numéricamente por **D12**, que es el AC que
> hace visible la discrepancia.
>
> **Cómo se cerró, y por qué no tocando el techo de R5.** Mover el 0.55 arrastraría
> `bono_vida_por_absorcion`, `vida_base` y los suelos efectivos 110/82 a la vez, y no
> arreglaría la unidad — seguiría midiendo puntos. En vez de eso, **R10a** declara la
> invariante directamente en golpes sobrevividos y sobre los **tres** términos de la
> suma. R5 se conserva intacta como guarda del par de knobs de este GDD; lo que pierde
> es el papel de proteger la premisa de que absorber es la palanca de supervivencia.
> Una invariante por unidad: R5 en puntos para el tuning propio, R10a en golpes para el
> contrato con el sistema 9.

> ⚠️ **R5 solo está calibrada para `angeles_max = 3` (v1.0/Alpha).** En la visión
> completa (9 coros) los valores actuales darían (18×9)/100 = **162% de swing** —
> absorber sería obligatorio y el dilema moral desaparecería por completo. R5 debe
> re-derivarse antes de pasar de 3 ángeles; no es una extrapolación segura.

**Sobre R6 — el arreglo del mash quedó fuera del bloque que lo hacía seguro**
(hallazgo de `systems-designer`, confirmado por `game-designer`, re-review
2026-08-01). `recuperacion_whiff` se introdujo en la revisión anterior para cerrar el
agujero del mash, con la fórmula de cobertura documentada en Interacciones entre
knobs — pero **nunca se promovió a invariante normativa**, así que no quedó cubierta
por el AC D9. Barrido completo del producto `parry_window` (9–18 ticks) ×
`recuperacion_whiff` (6–12 ticks), 70 combinaciones:

| `parry_window` (ticks) | Valores de `recuperacion_whiff` que violan el 65% | # |
|---|---|---|
| 9, 10, 11 | ninguno | 0 |
| 12 | 6 | 1 |
| 13 (actual) | 6 | 1 |
| 14 | 6, 7 | 2 |
| 15 | 6, 7, 8 | 3 |
| 16 | 6, 7, 8 | 3 |
| 17 | 6, 7, 8, 9 | 4 |
| 18 | 6, 7, 8, 9 | 4 |

**18 de 70 combinaciones (25.7%) violan el objetivo pese a que cada knob por separado
está dentro de su rango "seguro" individual.** Es literalmente la misma clase de
defecto que motivó el bloque R1–R5 en la revisión anterior, reaparecida en el knob que
introdujo el arreglo de esa misma clase.

> **R6 aplica a los valores *efectivos*, no a los de lanzamiento** (hallazgo de
> `game-designer`). El techo `multiplicador_ataque = 1.0` (R4) impide que las
> reliquias toquen el daño, pero **nada impedía que tocaran `parry_window` o
> `recuperacion_whiff`** — y el propio GDD sugiere "modificadores de ventana" como
> vía legítima para el sistema 9 ahora que el daño está cerrado. Una reliquia de
> "+2 fotogramas de ventana" reabriría el agujero del mash en silencio, sin que
> ningún AC lo detectase. **Restricción impuesta al sistema 9**: cualquier reliquia
> que modifique `parry_window` o `recuperacion_whiff` debe verificar R6 sobre los
> valores resultantes, no sobre los de lanzamiento.

**Sobre la cobertura *intra-combo* — R6 no la cubre, y es deliberado** (hallazgo de
`game-designer`). La recuperación de un parry **exitoso** es de 2–3 fotogramas, así
que dentro de una cadena de aciertos la cobertura sube a `13/(13+2.5) ≈ 84%`. Eso es
**intencional**: parar los N golpes de un combo exige precisamente que la ventana esté
casi siempre disponible, y R6 no debe cerrarlo. Pero tiene un efecto secundario real:
un jugador que machaca y acierta el primer golpe de un combo por azar entra en
cobertura casi total para el resto del combo, y el Repliegue no se dispara entre
golpes. **Restricción impuesta al sistema 20**: la separación temporal entre golpes de
un mismo combo debe variar lo suficiente como para que una cadencia de mash fija no
pueda mantenerla — es la única palanca que queda, porque bajar la cobertura intra-combo
rompería los combos como mecánica. Medido por el AC **C12b**.

**Sobre R8 — el extremo corto del rango está desproporcionadamente expuesto**
(hallazgo de `godot-specialist`, 3ª pasada). R8 recortó el **techo** de
`hitstop_parry` de 8 a 6; el **suelo** siempre fue 3. Pero el suelo importa más de lo
que parecía: `Tween` y `AnimationPlayer`/`AnimationMixer` evalúan por defecto en
**frames de render**, no en ticks de física (`TWEEN_PROCESS_IDLE`,
`ANIMATION_CALLBACK_MODE_PROCESS_IDLE`). Si el conmutador de hitstop se acciona desde
el contador de ticks pero un `Tween` se deja en su modo por defecto, el instante en que
ese nodo **reacciona** al cambio de escala queda cuantizado al siguiente frame de
render: a 40Hz, hasta **25ms** de desalineación. Contra un hitstop de 8 ticks (133ms)
eso es un ~19% de error relativo; **contra el suelo de 3 ticks (50ms) es hasta el
50%**. No es un defecto de R8 —la invariante es correcta— sino una restricción de
implementación que el extremo corto del rango vuelve no negociable: todo `Tween` y
`AnimationPlayer` de gameplay que participe del hitstop debe fijarse explícitamente en
modo de física. Registrado en Open Questions como parte del mecanismo de tiempo
autoritativo, no como pregunta nueva.

**Sobre R9 — la Ventana Especial estaba dominada por ignorarla** (hallazgo de
`game-designer`, 3ª pasada; perdido en la síntesis y recuperado al cerrar la pasada —
ver el review log, "Fallo de síntesis detectado". Cerrado el 2026-08-04, changeset 2).

Antes de esta invariante, el balance de la Ventana Especial era éste:

| | Pararla | Ignorarla |
|---|---|---|
| Beneficio de combate | **ninguno** — ni Postura ni Repliegue (Regla 4) | ninguno |
| Coste | **Gracia completa** = corrupción | **ninguno**: sin pulsación no hay whiff (Regla 7) y la ventana no daña (corolario de la Regla 6) |

Ignorarla **dominaba estrictamente**: mismo beneficio, menos coste. Un jugador que
lee patrones aprende racionalmente *"pararla solo me corrompe para nada"* — estrategia
degenerada en sentido estricto, sobre una interacción que este documento trata como
ventana parable de primera clase. El único coste declarado de ignorarla era la frase
**"el jefe completa su habilidad"**, una severidad que este GDD nombraba sin exigir a
nadie que la garantizase.

**La corrección no es "que la habilidad duela", sino que su coste esté acotado y
declarado.** Con un coste garantizado, parar e ignorar dejan de ser comparables en una
sola dimensión: parar evita ese coste y gasta corrupción; ignorar conserva corrupción y
lo paga. La Ventana Especial pasa a ser **la instancia por-encuentro del dilema
por-duelo** que la Fórmula 5 plantea (absorber = poder + corrupción / rechazar =
debilidad + pureza), en vez de una mecánica parcheada. Medido por **C23**, que verifica
la oposición de signos entre las dos monedas en vez de dar por buena la conclusión.

> ⚠️ **Corregido el 2026-08-04 (changeset 2 ítem 3): la severidad es una EQUIVALENCIA,
> no un pago en Vida.** La formulación del ítem 0 exigía que el coste se pagase en
> **Vida**, por testabilidad. Eso **contradecía frontalmente al sistema 2**, que declara
> dos veces y en negrita que *"el estado `Acción Especial` nunca reduce la Vida del
> jugador, en ninguna rama"* — decisión de usuario del 2026-08-03 con una razón que
> sigue siendo buena: *"que una curación fuese además un ataque sería **doble castigo por
> un solo error**"*. El ítem 0 fijó la moneda sin comprobar la tabla de Edge Cases del
> sistema 2. Como ese GDD está congelado y su regla es correcta, **la corrección cae
> entera en este documento**, que es además el que puede editarse hoy.
>
> **Regla de conversión (normativa)**: el coste se paga en la moneda en la que la
> habilidad opera —curación del jefe, buff, cambio de arena—, y el sistema 20 debe
> **declarar su equivalencia** en unidades de `dano_golpe_enemigo`. La conversión canónica
> pasa por la **exposición** que la habilidad fuerza:
>
> ```text
> coste_equivalente = parries_extra_forzados × (1 − tasa_acierto_objetivo)
> ```
>
> con `tasa_acierto_objetivo = 0.72`, **la tasa medida en el prototipo** (Regla 3), no un
> número inventado: cada parry adicional al que la habilidad obliga cuesta al jugador
> `0.28` unidades de presupuesto de error en esperanza, porque ésa es la fracción de
> parries que falla. Un `Golpe` no parado cuesta exactamente **1 unidad** por definición.
>
> **Ejemplo, y es el caso que importa.** Una `Acción Especial` de curación que restaure
> `H` de Vida al jefe fuerza `H / dano_golpe_castigo` ciclos extra, es decir
> `(H / dano_golpe_castigo) × parries_por_ciclo` parries extra. Para Cosmos
> (`dano_golpe_castigo = 40`, `parries_por_ciclo = 4`): una curación de **40** (un castigo
> entero) equivale a `4 × 0.28 = 1.12` unidades ✓ dentro de banda; una de **80** da
> `2.24` ✗ fuera. El techo de la banda cae en **H ≤ 71** para esa tríada.
>
> **Esto acota por primera vez el riesgo alto sin mitigación del proyecto** — *"la
> curación de jefes en su eje cuantitativo: curar más deprisa de lo que el jugador daña
> hace el duelo inganable"* (`systems-index.md`). No lo cierra —una habilidad **no**
> interrumpible sigue fuera de esta banda— pero fija el techo de toda curación que se
> ofrezca como Ventana Especial.

**Por qué la banda tiene dos cláusulas y no una.** La banda por ventana
(`1.0 ≤ s ≤ 2.0`) acota **un término**; lo que puede matar al jugador es **la suma**, y
cuántas Ventanas Especiales emite un duelo es propiedad del sistema 20. Con solo la
banda, un patrón con tres VEs a 2.0 impone 150 de daño ignorable a un jugador de 100
de Vida: parar dejaría de ser una elección y pasaría a ser **obligatorio**, destruyendo
el dilema por el lado opuesto al que la invariante existe para cerrar. La cláusula
agregada `Σ severidad ≤ golpes_para_morir_base − 1` fija el contrato real —**ignorar
todas las Ventanas Especiales de un duelo nunca puede ser letal por sí solo**— y deja
al sistema 20 elegir la forma: una VE a 2.0, o hasta tres a 1.0. Verificado por **D13**,
que comprueba las dos cláusulas por separado.

> Escribir solo la banda habría sido la cuarta aparición de la raíz **C** en este
> documento —guarda sobre un término, no sobre la magnitud— y la cuarta inecuación de
> un solo lado tras R4 (corregida dos veces), R5 (dos esquinas, no una) y R8. Se
> detectó haciendo la aritmética del techo elegido en vez de confiar en la banda.

**Sobre R10 — el contrato con el sistema 9 se reescribe sobre magnitudes, no sobre
mecanismos** (hallazgo de `economy-designer`, 3ª pasada, declarado bloqueante y no
diferible; cerrado el 2026-08-04, changeset 2 ítem 2).

Hasta aquí, las tres restricciones que este GDD imponía al sistema 9 nombraban
**mecanismos**: `multiplicador_ataque` (R4), `bono_reliquias` (R5), `parry_window` y
`recuperacion_whiff` (R6). Una reliquia que produjera el mismo efecto por otra vía se
escapaba **por construcción**, y hay al menos tres vías reales:

| Reliquia | Qué rompe | Por qué se escapaba |
|---|---|---|
| "Un Golpe de Castigo extra por aturdimiento" | El suelo de ciclos | No toca `multiplicador_ataque`: cambia el **número de aplicaciones**, no la magnitud de cada una. D8 pasa en verde |
| Bono de Vida máxima | La premisa de R5 | `bono_reliquias` entra **aditivamente y sin tope** en una suma de tres términos de la que R5 guarda **uno** |
| Reducción de daño recibido | El presupuesto de error **y** la cláusula agregada de R9a | No existía cuando se escribieron R4–R6; la creó la **Fórmula 8** en el ítem 0 de este mismo changeset |

**Y la colisión era predecible, no casual**: al cerrar R4 en ambos sentidos, este
documento **recomienda explícitamente** a las reliquias la vía de la Vida máxima — es
decir, empuja al sistema 9 hacia el único término que dejó sin guardar. El arreglo de un
agujero creó el siguiente.

**La reformulación**: se declaran **cuatro magnitudes observables** que definen la forma
del duelo —supervivencia, ciclos, parries por ciclo y cobertura temporal— y una reliquia
es legal **si y solo si** las deja dentro de banda, sea cual sea el mecanismo. El AC
**C26** cierra la puerta trasera exigiendo que todo efecto se declare como delta sobre
esas cuatro: **no existe la categoría "efecto no clasificado"**. Verificado además por
**D15** (supervivencia) y **D16** (ciclos y parries por ciclo).

**Lo que le queda al sistema 9**, y es un espacio real: hasta **+25 de Vida** o **−20% de
daño recibido** (no ambos), modificadores de ventana bajo R10d, y utilidad pura. Lo que
no puede tocar en absoluto es la **forma ofensiva** del duelo — decisión de usuario del
2026-08-04, extensión coherente de la que ya cerró R4 en ambos sentidos, llevada del
mecanismo a la magnitud.

> **R5 no desaparece, cambia de papel.** Sigue siendo la guarda del **par de knobs**
> `bono_vida_por_absorcion` × `vida_base`, que es tuning de este GDD. Lo que deja de ser
> es la invariante que protege la premisa "absorber es la palanca de supervivencia": eso
> lo hace **R10a**, y lo hace sobre los tres términos de la suma y sobre cualquier
> mecanismo, en la unidad que el jugador percibe. Con ello queda cerrado el hallazgo
> registrado la sesión anterior —R5 medía puntos de Vida donde la magnitud son golpes
> sobrevividos—, porque arreglar su **alcance** sin arreglar su **unidad** habría sido
> hacer media reparación sobre la misma invariante por segunda vez.

**R9b — la mitad que este GDD no puede verificar.** Toda la no-dominación se apoya en
que la Gracia sea un **coste**. Si el sistema 5 acabase diseñándola como beneficio sin
contrapartida, `ΔGracia` dejaría de ser negativo para el jugador y la dominación
reaparecería **invertida**: parar pasaría a dominar a ignorar, y R9a no lo detectaría.
Este GDD no posee la Gracia, pero sí la invariante que se rompería — mismo patrón de
constraint-handoff que ya usa cuatro veces (`3 ≤ N ≤ 5`, R4, precedencia armónica, R6
sobre valores efectivos). **Restricción impuesta al sistema 5**: la Gracia absorbida al
parar una Ventana Especial debe tener coste no nulo en la economía de corrupción. Si el
GDD de Gracia decidiera lo contrario, R9a debe re-derivarse, no ignorarse.

### Interacciones entre knobs

- **`dano_base` × `postura_base` × `incremento_postura_triada`** determinan juntos
  los parries por ciclo (interacción de **tres** vías, no dos). Tocar cualquiera
  sin recalcular los otros dos rompe la progresión de 3/4/5 parries por tríada y
  desactualiza las cifras "12/20/30" citadas en la nota de conteo de combos —
  actualmente solo `dano_base=10` con los valores por defecto de los otros dos
  produce conteos enteros en las tres tríadas.
- **`bono_vida_por_absorcion` es el knob más delicado del sistema.** Rango seguro
  fijado en **15–20** (ver Fórmula 5 y Tuning Knobs — un único rango canónico, no
  dos distintos). Si sube por encima de eso, absorber deja de ser una elección y
  pasa a ser obligatorio, destruyendo el Pilar 1 (el poder debe doler, no ser
  gratis). Es el valor prioritario a vigilar en playtesting. **No basta con
  respetar su rango: debe verificarse R5 junto a `vida_base`** — el rango 15–20 solo
  es seguro con `vida_base` en su valor por defecto.
- **`parry_window` y `umbral_precision`** — ver **R2** arriba. La versión anterior
  de este GDD enunciaba esta invariante correctamente pero solo señalaba **un punto**
  de fallo (`parry_window = 0.15`), cuando en realidad falla sobre una **región**
  amplia del rango declarado seguro. Se ha reexpresado en R2 como restricción del
  par, no como enumeración de casos: enumerar puntos hizo que el resto de la región
  pareciera segura durante dos revisiones. **Corrección de la re-review**: además, R2
  se evaluaba en segundos continuos cuando `parry_window` se autoriza en runtime como
  ticks enteros redondeados hacia abajo — la misma mezcla de unidades que la Regla 2
  fue escrita para prevenir, colándose en la invariante que la cita. R2 se evalúa
  ahora **en ticks**, y su límite real es 0.25s (15 ticks), no 0.24s.
  **Cierre (changeset 2 ítem 1)**: la mezcla de unidades no se arregló del todo en la
  re-review — se arregló la *invariante*, dejando el *knob* en segundos y la conversión
  `× 60` dentro de R2. Ahora `umbral_precision` es él mismo un entero de ticks (5, rango
  3–7), R2 es una comparación entera y **no queda ninguna duración en segundos en el
  documento**. El síntoma de que el arreglo estaba a medias llevaba escrito desde
  entonces en la propia invariante: nadie convierte unidades dentro de una guarda si el
  dato ya está en las unidades correctas.
- **`ciclos_objetivo_base`**: pese a listarse con rango "seguro" 3–5, la Fórmula 3
  exige `4 ≤ ciclos_objetivo_base + índice_tríada ≤ 6` para las tres tríadas
  (índice 0–2) simultáneamente. Con la estructura actual de la fórmula
  (`base + índice_tríada`), el único valor que satisface esa restricción para las
  tres tríadas a la vez es **`ciclos_objetivo_base = 4`** — no es un rango
  tunable independiente, es efectivamente una constante salvo que también se
  reajuste el término `+ índice_tríada` por tríada. Ver fila corregida en Tuning
  Knobs.
- **`multiplicador_ataque`** (Fórmula 6, gancho hacia Reliquias/sistema 9) — ver **R4**
  arriba y la invariante corregida en la Fórmula 6. La restricción que este GDD
  declaraba en su primera versión (`punish_dano_pct × multiplicador_ataque < 100`) era
  **la desigualdad equivocada**: protegía solo contra el one-shot, no contra el suelo
  de ciclos. La corrección de la primera revisión (`≤ 1.0`) era la desigualdad
  correcta pero **de un solo lado**, y dejaba abierto el colapso del daño a 0. Tras la
  re-review es la **constante 1.0**: no es un knob, no tiene rango, y no debe aparecer
  en ninguna tabla de tuning del sistema 9. El instinto de declarar la restricción sin
  poseer el sistema fue correcto las tres veces; el álgebra tardó dos pasadas en serlo.

- **`recuperacion_whiff` y `parry_window`** determinan juntos la cobertura temporal
  del parry, que es la métrica que decide si machacar el botón es viable:
  `cobertura = parry_window_ticks / (parry_window_ticks + recuperacion_whiff)`.
  Con los valores actuales (13 y 9) → **59%**. El objetivo de diseño es
  **mantenerla por debajo del 65%**. Subir `parry_window` sin subir
  `recuperacion_whiff` reabre el agujero del mash: a `parry_window = 0.30` (18
  ticks) con `recuperacion_whiff = 6`, la cobertura vuelve al **75%**. Son un par,
  no dos filas independientes. **Formalizado como invariante R6 en la re-review** —
  hasta entonces esto vivía solo como prosa en esta sección y no estaba cubierto por
  D9, que es exactamente por lo que el 25.7% de la rejilla pasaba desapercibido.

## Visual/Audio Requirements

> Especificado por `art-director` contra las reglas ya fijadas en
> `design/art/art-bible.md`.

**Regla de oro que separa éxito de fallo**: todo lo que sale bien (parry, parry
justo, punish hit) se comunica con **aparición o desprendimiento de vitral** — luz
que llega o luz que se arranca del ángel. Todo lo que sale mal (fallo, combo roto,
ventana desperdiciada) se comunica con **ausencia de luz** — la tinta avanza, nunca
un flash de color nuevo. Esto es obligatorio: "solo lo divino emite luz" (art bible
Sección 1, Principio 2) prohíbe usar un destello para castigar al jugador.

**Regla que separa fallo de whiff**: el fallo real tiene consecuencia física (daño,
oscurecimiento, reacción de cámara); el whiff es **ausencia total de reacción del
mundo** — ni luz, ni oscurecimiento, ni hitstop, ni cámara.

| Evento | Feedback Visual | Feedback Audio | Prioridad |
|---|---|---|---|
| **1. Telegrafiado inicia** | Fisura de vitral con la silueta exacta del ataque, coloreada por coro, que se espesa hasta el golpe. >15–20% de altura de pantalla, sin detalle superpuesto (art bible 3.5) | Tell sonoro distintivo por tríada (cuerdas/coro=Humanidad, metal/viento=Cosmos, casi inarmónico=Cercanía a Dios) que crece con la fisura — segunda vía de lectura del timing | Alta |
| **2. Ventana de parry se abre** | La fisura alcanza espesor máximo y su brillo pulsa una vez con más fuerza — intensificación, no adición de elementos | "Tick" seco y corto, distinto del tell de telegrafiado — marca el instante exacto de apertura para calibración por oído | Alta |
| **3. Parry exitoso** | Freeze-frame, hitstop de **5 ticks** con la simulación diegética al 4% de velocidad (ver Regla 2, autoridad del tiempo — el HUD **no** se congela); el brillo del ángel estalla en esquirlas de vitral que se clavan en la silueta del protagonista como **herida de color, no power-up**. 150–200 partículas | Impacto de dos capas: cristalina + cuerpo/impacto físico. Nunca un "ding" genérico — debe sentirse como sacramento robado | Alta |
| **4. Parry Justo (timing preciso)** — **dispara si y solo si `calidad_timing ≥ umbral_parry_justo`** *(predicado declarado el 2026-08-04, changeset 2 ítem 1; ver Fórmula 1 y AC **C25**)* | **No añadir partículas** sobre el evento 3 — usar el margen hasta 250 con esquirlas de mayor tamaño individual + micro-extensión del hitstop (**+2 ticks en `calidad_timing = 1.0`, +1 en `0.9`**, `bono_hitstop_parry_justo`, acotado por R8). La esquirla incrustada usa una micro-variante hacia el blanco-espectro de Lucifer (`#FFF8E7`) en vez del color puro de coro — guiño reservado solo a la precisión máxima | Capa de audio adicional superpuesta (armónico que "florece" tras el golpe) — debe distinguirse con los ojos cerrados | Alta |
| **5. Fallo (el golpe conecta)** | **Sin flash de luz.** La tinta invade brevemente los bordes de pantalla (vignette de menor intensidad que el evento 13) + parpadeo único del color de alerta UI `#C75C4A` en el HUD de vida. Sacudida de cámara corta y seca | Sonido sordo, de tela/carne rasgada — sin ningún componente cristalino o musical, para no confundirse con impacto divino | Alta |
| **6. Whiff (parry sin ataque activo)** | **Cero reacción del mundo**: sin flash, sin oscurecimiento, sin hitstop, sin cámara. Solo la animación de gesto vacío del protagonista — pose icónica que explícitamente no resuelve en impacto | Sonido hueco y corto (aire, no contacto) — nunca comparte capa de audio con el fallo; su ausencia de peso ES el mensaje | Alta |
| **6b. Recuperación de whiff (los 9 ticks siguientes)** | Continuación de la animación del evento 6: el gesto vacío **se asienta visiblemente** — el brazo baja y el peso se reasienta, con duración suficiente para leerse como final de un gesto y no como congelación. **Ninguna reacción del mundo** (sigue aplicando la regla del evento 6). **Ninguna pulsación adicional durante el lockout produce feedback de ningún tipo**: ni flash de "denegado", ni click, ni rumble | La cola/decay natural del sonido de aire del evento 6 se extiende sobre parte de la recuperación. **Esto no viola "cero reacción del mundo"**: no es el mundo reaccionando, es el gesto del jugador terminando de sonar. **Las pulsaciones descartadas no disparan sonido alguno** — ni siquiera el primero repetido | Alta |
| **7. Golpe de combo parado (no el último)** | Esquirlas se incrustan parcialmente (menor volumen que 3/8) **sin hitstop completo** — micro-freeze de 1–2 fotogramas máximo; la fisura del siguiente golpe empieza a formarse de inmediato, comunicando continuidad sin corte | Cue ascendente o encadenado (nota que sube respecto al golpe anterior del combo) — nunca el cierre armónico reservado al último | Media |
| **8. Combo completo parado (último golpe)** | Tratamiento completo del evento 3 (freeze-frame, hitstop, esquirlas al tope) **más** la caída visible de la barra de compostura en el HUD — único evento que combina freeze-frame diegético con reacción de HUD inmediata | Resolución armónica clara (el cue ascendente del evento 7 "cierra" aquí) + sonido de daño de compostura distinto del de vida | Alta |
| **9. Combo roto a mitad** | Las esquirlas ya incrustadas *de ese combo* se agrietan y caen como polvo de tinta (se desaturan y son reabsorbidas por la silueta) — efecto **temporal y de menor fidelidad**, deliberadamente distinto del mapa de corrupción permanente | Cristal cayendo/disolviéndose — corto, sin resonancia, marcadamente anticlimático frente al cierre del evento 8 | Alta |
| **10. Quiebre de compostura (ventana de castigo 2.0s)** | El brillo del ángel se desestabiliza y parpadea (primera grieta visible en su vitral, sin romperse del todo). HUD: temporizador de 2.0s en gris frío periférico, nunca invade el centro de lectura | Quiebre grave y sostenido, distinto de cualquier impacto puntual — comunica apertura de estado, no un golpe más | Alta |
| **11. Golpe de Castigo conecta** | Esquirlas de vitral se desprenden **del ángel hacia afuera** (nunca hacia el protagonista) — imagen invertida del parry: aquí no se absorbe gracia, se arranca luz | Impacto más sólido/percusivo, con menor componente cristalino — daño bruto, no sacramento | Media |
| **12. Ventana de castigo expira sin usar** | La grieta del evento 10 se resella y el brillo del ángel se estabiliza, con un breve **refuerzo de intensidad al sellar** (gesto casi desafiante) — contraste directo contra el desprendimiento del evento 11, para que la pérdida se sienta como retroceso real | Cue de cierre suave con timbre ligeramente disonante o irresoluto — nunca silencio total, que se leería como ausencia de evento | Alta |
| **13. Vida baja / muerte** | Vida baja: vignette de tinta que avanza gradualmente desde los bordes. Muerte: tratamiento del art bible Sección 2 fila 8 (toda luz divina se extingue de golpe, pantalla cae a grabado puro y se agrieta como sobre-entintado) | Vida baja: motivo tipo latido que se acelera. Muerte: corte seco de toda música/ambiente divino, dejando solo un sonido de vela apagándose — el silencio es parte del diseño | Alta |
| **14. Ventana Especial se abre** *(añadido el 2026-08-04, changeset 2 ítem 3 — ejecución de la opción C)* | **Gramática invertida respecto al evento 1/2, y ésa es toda la señal**: no se forma una fisura *hacia el jugador* con la silueta de un ataque, sino que el vitral **del propio ángel se abre** — una apertura en su superficie, luz que se ofrece en vez de amenaza que se dirige. **Ningún emisor nuevo**: reutiliza el material del evento 2 con la máscara invertida. La barra de Postura **no** reacciona (no habrá daño de Postura), el medidor de Gracia **se pre-ilumina** anticipando lo único que sí está en juego | **Sostenido, no puntual** — contrapuesto al "tick" seco del evento 2. La VE es una ventana de *decisión* con duración, no un instante que golpear; el sonido debe durar mientras la oportunidad dure | Alta |
| **15. Ventana Especial parada** | **Perfil VFX del evento 3 reutilizado íntegro** (freeze-frame, hitstop base, esquirlas que se clavan en la silueta) — **ningún emisor nuevo, ninguna partícula adicional**. La firma distintiva es **positiva y ya cierta mecánicamente: el medidor de Gracia se mueve y la barra de Postura no** (Regla 4). **Nunca la variante `#FFF8E7` ni el bono de hitstop**: un parry contra VE no puede ser Parry Justo (Fórmula 1, AC **C25**) | Capa diferenciada sobre el impacto del evento 3: **misma percusión cristalina, sin el cuerpo de impacto físico** — se arranca gracia, no se detiene un golpe. Debe distinguirse del evento 3 con los ojos cerrados | Alta |
| **16. Ventana Especial se cierra sin ser parada** | La apertura del evento 14 **se cierra sobre sí misma y el ángel se compromete**: la luz que se ofrecía se repliega hacia dentro y su brillo se concentra. **No es un sello tranquilo** (eso es el evento 12) — debe leerse como *"esto ya va a ocurrir"*, no como *"no pasó nada"*. Sin daño, sin vignette, sin sacudida: la Vida no cambia (**C21**) y el feedback no puede sugerir lo contrario | **Cláusula anti-silencio, calcada del evento 12**: cue de cierre breve, con timbre irresoluto que **no cierra la frase** — deja tensión pendiente porque literalmente queda algo por ocurrir. **Nunca silencio total**, que se leería como ausencia de evento; **nunca un cue de alivio**, que mentiría | Alta |

### Ventana Especial: propiedad del feedback y presupuesto (normativa)

*(Añadido el 2026-08-04, changeset 2 ítem 3 — ejecución de la opción C decidida el
2026-08-04. Hasta aquí, la Ventana Especial era una **ventana parable de primera clase
sin una sola fila** en esta tabla: la enmienda que la creó tocó la norma y los ACs y se
detuvo en la frontera experiencial. Raíz **B**, y uno de los ocho sitios de la raíz **A**
que el review log listaba como "la tabla de eventos".)*

**Reparto de propiedad.** La `Acción Especial` tiene cuatro instantes perceptibles y
**no todos son de este GDD**:

| Instante | Feedback | Dueño |
|---|---|---|
| La Ventana Especial se abre | evento **14** | este GDD |
| Parada con parry exitoso | evento **15** | este GDD |
| Se cierra sin ser parada | evento **16** | este GDD |
| La `Acción Especial` **se completa** | fila propia de `maquina-estados-jefe.md` | **sistema 2** |
| La `Acción Especial` es **interrumpida** por el parry | fila ya existente del sistema 2 | **sistema 2** |

El criterio es el mismo que resolvió "duelo ganado": **cada GDD posee el feedback de los
sucesos de su propio dominio**. Los tres primeros son eventos de *parry*, que es lo que
este documento posee; los dos últimos son transiciones del estado `Acción Especial`, que
posee el sistema 2 — y que **ya tiene fila para la interrupción**, así que la asimetría
sería nuestra, no suya.

> **Restricción impuesta al sistema 2**: el feedback de la **completación** debe ser
> distinguible del **cierre de ventana** (evento 16), y ninguno de los dos puede leerse
> como alivio. Este GDD la declara sin poseer esa fila por la misma razón que declara la
> Regla de precedencia armónica: **es quien crea la coincidencia** — los dos instantes se
> siguen inmediatamente y solo existen juntos. Verificado por **V7**. **Deuda registrada,
> no cerrable aquí**: el sistema 2 está congelado y no tiene todavía fila para la
> completación; entra en su 4ª pasada.

**Por qué P0 y P5 no cambian — y no es una suposición.** La opción C se eligió
precisamente para que el presupuesto no escalara, así que la afirmación se declara
normativa y no se da por hecha:

1. **Ningún emisor nuevo.** El evento 14 reutiliza el material del evento 2 con máscara
   invertida; el 15 reutiliza el **perfil íntegro del evento 3**, sin partículas
   adicionales; el 16 reutiliza el tratamiento de sellado del evento 12. La pregunta
   abierta de si **3 emisores `GPUParticles2D`** bastan (Open Questions) **no escala**:
   sigue siendo sobre los mismos tres.
2. **Ningún pico de concurrencia nuevo.** El pico que P5 acota lo producen las
   coincidencias **4+8** y **8+11**, todas dentro del ciclo de ataque. La `Acción
   Especial` está **fuera del ciclo** (Regla 4) y sus ventanas no coinciden con `Golpe`,
   combo ni Golpe de Castigo, así que la capa de audio diferenciada del evento 15 **no se
   suma a ningún pico existente**.

Si alguna de las dos deja de ser cierta —por ejemplo si el sistema 20 declarase una
`Acción Especial` solapada con el ciclo—, **P0 y P5 deben re-evaluarse**, y esta nota es
el gancho que lo hace detectable.

### Regla de precedencia armónica: evento 4 sobre evento 8 (normativa)

> **La coincidencia de Parry Justo con el cierre de combo no es un caso raro — el
> diseño la garantiza** (hallazgo de `audio-director`, re-review 2026-08-01). La
> Fórmula 1 calcula el bono de Parry Justo sobre el **último parry del combo**, que es
> exactamente el golpe del evento 8. Es decir: rematar un combo con precisión máxima
> —el pico de ejecución que todo este sistema recompensa— dispara **siempre** el
> "armónico que florece" del evento 4 y la "resolución armónica clara" del evento 8 en
> el mismo instante. Sin regla de arbitraje, ambas capas se enmascaran justo donde el
> evento 4 exige "distinguirse con los ojos cerrados".
>
> **Decisión**: el Parry Justo se subordina al cierre de combo. Cuando ambos
> coinciden, **no se superponen dos capas armónicas**: el cierre del evento 8 se
> ejecuta con una **variante tímbrica** que codifica la precisión (misma frase, mismo
> punto de resolución, timbre más brillante/cristalino), no con una capa añadida. El
> "florecimiento" del evento 4 solo suena como capa independiente cuando el Parry
> Justo ocurre sobre un **golpe simple**, fuera de combo.
>
> Este GDD declara la regla aunque no posea la mezcla, por la misma razón que declara
> R4 y el rango de N: **es este documento quien crea la coincidencia**. La
> implementación (ducking, buses, prioridades) es del Feedback Sonoro del Parry
> (sistema 16). Es el equivalente sonoro del AC **V1** para partículas — mismo patrón
> de bug, mismo instante de máxima densidad, y hasta esta re-review tratado con doble
> estándar entre dominios.

### Notas sobre los eventos con riesgo de confusión

- **Evento 4 (Parry Justo)**: la tentación fácil sería "más partículas = más
  recompensa", pero choca con el tope de 250 que el evento 3/8 ya roza. La
  diferenciación debe vivir en **calidad** (tamaño de esquirla, color de acabado,
  duración de hitstop), no en cantidad. Esto también evita que Parry Justo + combo
  completo simultáneos excedan el presupuesto duro.
- **Evento 6 (Whiff)**: el error más fácil en producción es darle *algo* de reacción
  "para que no se sienta raro". Resistir esa tentación **es** la especificación.
- **Evento 6b (Recuperación de whiff)**: aquí la tentación es la contraria y hay que
  resistirla igual — dar un "denied click" o un flash a cada pulsación descartada.
  Sería spam, y además **mentiría**: sugeriría cuatro acciones válidas cuando el
  sistema entero (Regla 7, R6) existe precisamente para que machacar no sea gratis.
  Pero **tampoco vale el silencio absoluto**, que es lo que el AC V2 prohíbe que se
  perciba. La solución está en la distinción entre *reacción del mundo* (prohibida) y
  *cola del propio gesto del jugador* (obligatoria): el gesto vacío debe **terminar de
  sonar y terminar de moverse** durante los 9 ticks, no cortarse en seco y dejar un
  hueco mudo. La diferencia entre "esto acabó" y "esto se colgó" vive entera en esa
  cola. Es el evento con mayor riesgo de fallar su AC en el primer playtest.
- **Evento 9 (Combo roto)**: riesgo real de confusión con el mapa de corrupción
  permanente si un desarrollador reutiliza el mismo shader/decal por conveniencia.
  Debe implementarse como sistema **separado y temporal**, aunque comparta
  vocabulario visual superficial.
- **Evento 12 (Ventana expirada)**: el riesgo es que "nada malo pasa visualmente" se
  lea como "no importa". El breve refuerzo de brillo al sellar es la única forma de
  comunicar pérdida sin violar "solo lo divino emite luz" con un flash punitivo — el
  ángel se está fortaleciendo, no el jugador siendo castigado con un efecto nuevo.
- **Evento 14 (VE se abre) vs evento 2 (ventana de parry se abre)**: es la confusión más
  cara del documento, porque **cambia lo que el jugador debe decidir**. Ante un `Golpe`
  la respuesta correcta es siempre parar; ante una Ventana Especial hay **elección**, y
  un jugador que no distingue las aperturas parea por reflejo y **nunca decide nada** —
  con lo que toda la economía de R9a queda muerta en la práctica aunque esté bien
  escrita. La diferenciación no puede vivir en intensidad ni en color de coro (ambos ya
  están ocupados por la tríada): vive en la **gramática de la forma** — fisura dirigida
  al jugador frente a apertura del vitral del ángel — y en la duración del audio. Medido
  por **V5**.
- **Evento 15 (VE parada)**: la tentación aquí es *añadir* algo que compense la ausencia
  de daño de Postura, y sería un error doble: rompería el presupuesto de partículas que
  la opción C existe para no tocar, y **mentiría** sobre lo que acaba de pasar. La
  ausencia de reacción de la barra de Postura **es** la información. La opción C funciona
  porque esa ausencia va acompañada de una presencia —la Gracia sí se mueve—, así que el
  hueco se lee como contraste y no como fallo. Medido por **V6**. Riesgo secundario y
  concreto: reutilizar el perfil del evento 3 **entero**, incluida la variante `#FFF8E7`
  del Parry Justo; está explícitamente prohibido (C25).
- **Evento 16 (VE se cierra sin parar)**: mismo riesgo que el evento 12 pero **invertido
  en el tiempo**. Allí lo que ya pasó fue una pérdida; aquí lo que va a pasar es el
  coste, y el instante en sí no cambia nada. Un cue de cierre bien resuelto —o el
  silencio— se leería como *"te has librado"*, exactamente lo contrario de lo que ocurre.
  Debe quedar **irresuelto**. Es el evento con más riesgo de que un implementador lo
  "arregle" hacia el alivio por sonar mejor aislado. Medido por **V7**.

### Riesgo de presupuesto de partículas

Punto de mayor riesgo: **coincidencia de eventos 8 (combo completo) + 11 (punish
hit)** en ventanas comprimidas — hasta 3 sistemas de partículas distintos podrían
solicitar emisores simultáneamente, tocando el límite de 3 GPUParticles2D activos
del art bible 8.6.

**Corrección respecto a la primera versión de este GDD**: la mitigación propuesta
originalmente ("el evento más reciente recicla el emisor más antiguo") queda
**retirada** — un reciclado puramente cronológico puede truncar a mitad de vuelo
el estallido hacia el protagonista del evento 8 justo cuando el evento 11 necesita
emitir su estallido hacia afuera, **invirtiendo o cortando la regla de oro del art
bible** ("luz hacia el jugador = acierto, luz desde el ángel = daño arrancado") en
el instante de mayor densidad de eventos. Ningún AC de rendimiento (P1–P2)
detectaría esto, porque es un bug de corrección visual, no de frame time.

*Recomendación revisada*: la prioridad de reciclado del pool debe ser **semántica
por dirección del efecto** (un emisor "hacia el jugador" nunca recicla a mitad de
vuelo a costa de uno "hacia afuera", y viceversa), no cronológica. La asignación
concreta (p. ej. reservar un emisor por dirección y dejar solo el tercero en pool
compartido) es una decisión técnica de `technical-artist`, pendiente — no se fija
aquí para no imponer una solución que podría volver a violar la regla de arte.
Ver Open Questions.

**Segunda corrección (re-review 2026-08-01, `godot-specialist`)**: la política de
reciclado semántico es necesaria pero **no suficiente**. Reiniciar un
`GPUParticles2D` que sigue emitiendo corta sus partículas vivas de inmediato — no hay
crossfade nativo en Godot 4.7. Es decir, incluso con la política correcta, dos eventos
de la **misma** dirección semántica que se solapen truncarán si solo hay un emisor
reservado para esa dirección. La pregunta para `technical-artist` no es solo "qué
prioridad de reciclado", sino **si 3 emisores dan margen suficiente para que la
coincidencia 8+11 no fuerce truncamiento en absoluto**. Si la respuesta es que no, la
salida no es una política mejor: es reducir la concurrencia de eventos o el número de
sistemas de partículas distintos. Registrado en Open Questions.

**Tercera corrección (3ª pasada, `godot-specialist`) — cómo se detecta que un emisor
está libre**: la disponibilidad del pool debe seguirse con `one_shot = true` más la
señal **`finished`**, **nunca con la propiedad `emitting`**. `emitting` pasa a false en
el instante en que la emisión se detiene, pero las partículas ya emitidas siguen
decayendo en pantalla durante todo su `lifetime` — un pool que consulte `emitting`
creerá que el hueco está libre mientras aún hay partículas vivas, y **reintroducirá una
versión más sutil del mismo truncamiento** que la política de reciclado semántico existe
para evitar. Detalle de implementación para `technical-artist`, anotado aquí porque el
modo de fallo es idéntico al que este bloque ya documenta dos veces.

**Presupuesto real de draw calls disponible para VFX** (corrección de
`performance-analyst`): el art bible 8.6 fija el pico de combate en **40–80 draw
calls**, con el desglose ya repartido — protagonista 3–5, jefe 2 (+1 por color de
coro), arena atlasada 5–10, UI 1–3, y **"VFX = resto"**. En la composición de escena
más cara eso deja del orden de **~20 draw calls** para todos los VFX de combate, no
1000. Esta es la cifra contra la que P0 debe contrastar; ver el AC corregido.

> 📌 **Asset Spec** — Los requisitos visuales/audio están definidos. Ejecutar
> `/asset-spec system:combate-parry-absorcion` para producir descripciones
> por-asset, dimensiones y prompts de generación a partir de esta sección.

## Game Feel

### Feel Reference

**Referencia**: el deflect de Sekiro — específicamente la cualidad de que parar
**es** atacar, no defenderse. La ventana castiga con dureza el error pero recompensa
con claridad brutal el acierto, y el sonido metálico del deflect es co-responsable
de esa satisfacción, no un adorno.

**Anti-referencia**: NO debe sentirse como un bloqueo con escudo (mantener pulsado,
mitigación pasiva, sin compromiso). Tampoco como un parry de juego de lucha con
ventana de 3 fotogramas — el perdón de anticipación validado en el prototipo es
innegociable.

### Input Responsiveness

| Acción | Latencia máx. input→respuesta | Presupuesto de fotogramas (60fps) | Notas |
|---|---|---|---|
| Parry (entrada a estado PARRY) | 33ms | 2 fotogramas | Debe registrarse visual y sonoramente antes de que el jugador pueda dudar de si el input entró |
| Resolución de parry exitoso | 50ms | 3 fotogramas | Incluye el disparo del hitstop |
| Golpe de Castigo | 50ms | 3 fotogramas | Ventana de 2.0s da margen, pero el input debe sentirse inmediato |
| Movimiento | 33ms | 2 fotogramas | Sin aceleración/rampa — respuesta arcade |

### Animation Feel Targets

| Animación | Fotogramas de inicio | Fotogramas activos | Fotogramas de recuperación | Objetivo de sensación |
|---|---|---|---|---|
| Parry (resuelto con éxito) | 0–1 (sin windup real) | 13 (`parry_window` — 13 ticks canónicos, ver Tuning Knobs) | 2–3 | Instantáneo al presionar; la ventana ES la animación. Recuperación mínima para no romper cadenas de combo |
| Parry (resuelto como whiff) | 0–1 (sin windup real) | 13 | **9** (`recuperacion_whiff`, ver Regla 7) | El gesto vacío se "asienta" visiblemente — la recuperación debe leerse como consecuencia del error, no como lag |
| Golpe de Castigo | 6–8 | 4–6 | 10–14 | Pesado y comprometido — contraste deliberado con la agilidad del parry |
| Recepción de golpe | 0 | — | **8–12** (`recuperacion_recepcion`, ver Tuning Knobs) | Interrumpe cualquier acción en curso; el jugador debe sentir que perdió el turno |

### Impact Moments

| Tipo de impacto | Duración | Descripción | ¿Configurable? |
|---|---|---|---|
| Hitstop (parry exitoso) | **5 ticks de reloj real** (0.0833s), simulación diegética al 4% (ver Regla 2, reglas normativas 2 y 3) | Congela el mundo; validado en prototipo como contribuyente clave al peso. **No congela la capa de HUD/UI.** 5 ticks, no 0.08s: 0.08 × 60 = 4.8 no es entero y contradiría el contador autoritativo | Sí (`hitstop_parry`, **3–6 ticks** — techo recortado de 8 por R8; ver Tuning Knobs) |
| Hitstop (Parry Justo) | **+2 ticks en `calidad_timing = 1.0`, +1 en `0.9`** → total 6–7 ticks; **+0 por debajo de `umbral_parry_justo`** | Diferenciación por calidad, no por cantidad de partículas. El reparto por escalón se declaró en el changeset 2 ítem 1: antes decía "+1–2" **sin decir qué elegía entre 1 y 2**, sobre una `calidad_timing` que además era continua | Sí (`bono_hitstop_parry_justo`, acotado por R8) |
| Hitstop (combo intermedio) | 1–2 ticks | Micro-freeze que no rompe el flujo del combo | Sí |
| Sacudida de cámara (fallo) | ~150ms, direccional, decayendo | Corta y seca — comunica golpe recibido | Sí |
| Rumble de mando (parry exitoso) | ~80ms, corto y agudo | Refuerza el acierto en el input primario (mando) | Sí |
| Rumble de mando (fallo) | ~200ms, grave y difuso | Timbre háptico deliberadamente distinto del acierto | Sí |

### Weight and Responsiveness Profile

- **Peso**: el parry es **ligero y reactivo**; el Golpe de Castigo es **pesado y
  deliberado**. El contraste entre ambos es intencional — el jugador debe sentir que
  el castigo cuesta compromiso, mientras que parar es puro reflejo.
- **Control del jugador**: **alto durante el parry** — puede intentarlo en cualquier
  momento y nunca cuesta un recurso gastable; el único coste es **temporal y solo al
  fallar en vacío** (`recuperacion_whiff`, Regla 7), de modo que el jugador que lee el
  patrón no paga nada. **Bajo durante el Golpe de Castigo** (comprometido, con
  recuperación real). *(Redacción corregida en la re-review: esta línea seguía diciendo
  "sin coste" a secas después de que la revisión anterior introdujera el coste
  temporal — `game-designer` la detectó como contradicción viva con la Regla 7.)*
- **Cualidad de snap**: **crispa y binaria**. El parry acierta o no acierta — sin
  mitigación parcial, sin bloqueo a medias.
- **Modelo de aceleración**: arcade. El movimiento arranca al instante, sin rampa.
  El combate de precisión no admite inercia que el jugador no pidió.
- **Textura del fallo**: debe sentirse **justo, nunca arbitrario**. El jugador tiene
  que poder decir "leí mal ese patrón" y no "el juego no registró mi input". Ese es
  precisamente el hallazgo del prototipo: sin perdón de anticipación, el fallo se
  siente aleatorio (45% de acierto medido) en vez de merecido (72%).

### Feel Acceptance Criteria

- [ ] Los playtesters responden al telegrafiado **intentando el parry**, no
      retrocediendo ni manteniendo distancia con el input de Movimiento, sin que se les
      indique. *(Verificado por observación de sesión grabada + tagging de la respuesta
      al telegrafiado, no por cuestionario: preguntarlo después no mide conducta
      espontánea. La redacción anterior decía "en vez de esquivar", pero **este juego
      no tiene acción de esquiva** — no existe en States and Transitions ni en ninguna
      regla; el verbo era un fantasma heredado de otro género.)*
- [ ] Ningún playtester describe el parry como "aleatorio", "no responde" o "injusto"
- [ ] Tasa de acierto entre 65% y 80% tras 5 minutos de práctica (validado en
      prototipo: 72% con `parry_window = 0.22s`)
- [ ] El hitstop se lee como satisfactorio, no como lag o tartamudeo del juego
- [ ] Los playtesters distinguen un Parry Justo de un parry normal sin que se les
      explique la diferencia
- [ ] Los playtesters distinguen un whiff de un fallo real sin que se les explique
- [ ] La latencia de input es imperceptible a 60fps en **hardware real de Steam
      Deck**, no solo en PC de escritorio

## UI Requirements

| Información | Ubicación | Frecuencia de actualización | Condición |
|---|---|---|---|
| Vida del jugador | HUD periférico (gris frío, art bible 4.5/7.1) | En cada cambio | Siempre visible en combate |
| Postura del enemigo | HUD periférico | En cada parry exitoso / ruptura / restauración | Visible durante el duelo |
| Vida del enemigo | HUD periférico | En cada Golpe de Castigo conectado | Visible durante el duelo |
| Temporizador de ventana de castigo (2.0s) | HUD periférico, nunca en el centro de lectura | Continua durante Aturdido | Solo mientras el enemigo está Aturdido |
| Medidor de Gracia/corrupción | Esquina periférica, único elemento con licencia de vocabulario vitral (art bible 3.4) | En cada absorción | Siempre visible en combate — *propiedad del Sistema de Gracia (5), este GDD solo declara que su valor cambia por parry* |

**Restricciones heredadas del art bible (Sección 7)**:
- El HUD es screen-space y periférico, **nunca diegético** — no se marca sobre el
  ángel ni sobre el suelo de la arena.
- Formas rectas y finas, sin vocabulario circular (evita confusión figura-fondo con
  los telegrafiados durante la ventana de parry).
- Cambios de estado crítico se registran en 1–2 fotogramas, **sin ease-in** — el
  jugador necesita el dato antes de poder actuar sobre él.
- Ningún texto funcional por debajo de ~18px aparentes a distancia real de Steam
  Deck (7", ~30–40 cm).

**Contraste periférico — croma vs. luminancia** (señalado por `ux-designer` en la
re-review): el temporizador de castigo se especifica como "gris frío periférico", pero
la visión periférica tiene **mala agudeza cromática y buena sensibilidad a luminancia
y movimiento**. Un elemento de bajo croma en la periferia no es legible por su color;
solo lo es por su contraste de **luminancia** y su cambio temporal. La spec de UX
(`/ux-design`, sistema 13) debe fijar contraste de luminancia explícito para este
elemento, y decidir si es barra (preferible: el cambio temporal se lee en periferia) o
numérico — el numérico cuenta como texto funcional y arrastra el mínimo de 18px.

**Reacción del HUD durante el hitstop**: la capa de HUD **no** se congela cuando el
mundo lo hace (Regla 2, regla normativa 2). El evento 8 es el único que exige
congelación diegética y reacción de HUD inmediata a la vez, y es la razón por la que
esa regla existe. Verificado por el AC **C14**.

> **📌 UX Flag — Combate de Parry-Absorción**: este sistema tiene requisitos de UI.
> En Pre-Producción, ejecutar `/ux-design` para crear una spec de UX del HUD de
> combate **antes** de escribir épicas. Las historias que referencien UI deben citar
> `design/ux/[pantalla].md`, no este GDD directamente. Anotado también en
> `systems-index.md` para el sistema 13 (HUD de Combate).

## Cross-References

| Este documento referencia | GDD objetivo | Elemento específico | Naturaleza |
|---|---|---|---|
| `angeles_absorbidos` alimenta Vida Máxima (F5) | `design/gdd/sistema-de-gracia.md` *(no existe aún)* | Contador de decisiones "absorber" | Data dependency |
| Evento "parry exitoso" y `gracia_ganada` (F7) | `design/gdd/sistema-de-gracia.md` *(no existe aún)* | Entrada de gracia por parry | Ownership handoff |
| `bono_reliquias` alimenta Vida Máxima (F5) | `design/gdd/eleccion-de-reliquias.md` *(no existe aún)* | Bono de Vida de reliquias equipadas | Data dependency |
| `multiplicador_ataque` alimenta daño de castigo (F6) — **fijado en la constante 1.0 por este GDD, cerrada en ambos sentidos (R4)** | `design/gdd/eleccion-de-reliquias.md` *(no existe aún)* | Multiplicador de ataque por reliquia | Data dependency **+ constraint handoff** |
| Eventos "inicio/fin de Golpe", composición de combos, `vida_max_angel`, cadencia | `design/gdd/ia-combate-jefes.md` *(no existe aún)* | Ciclo de ataque y patrones por ángel | State trigger |
| Evento **"duelo perdido"** — emitido por este GDD al llegar la Vida del jugador a 0 | `design/gdd/gestion-de-run.md` *(no existe aún)* | Transición de run | Ownership handoff |
| Evento **"duelo ganado"** — **este GDD NO lo emite** | `design/gdd/maquina-estados-jefe.md` | Estado terminal `Muerto` | **Aclaración de propiedad** *(2026-08-04)* — anotado aquí porque este documento lo reclamaba por implicación hasta esa fecha. Ver la nota de propiedad en Dependencies |
| **Longitud legal de combo `3 ≤ N ≤ 5`** (Regla 9) | `design/gdd/ia-combate-jefes.md` *(no existe aún)* | Rango de N por patrón | **Constraint handoff** — impuesto por R7 (Fórmula 7) y por la frase musical de los eventos 7→8 |
| **Varianza de separación intra-combo** suficiente para que una cadencia de mash fija no la mantenga (nota de R6) | `design/gdd/ia-combate-jefes.md` *(no existe aún)* | Timing entre golpes de un mismo combo | **Constraint handoff** — es la única palanca contra el mash intra-combo, porque bajar la cobertura rompería los combos |
| **Cadencia del encuentro tutorial** con hueco explícito para el ciclo de whiff (9 ticks) | `design/gdd/ia-combate-jefes.md` *(no existe aún)* | Patrón del primer enemigo | **Constraint handoff** — el jugador que aprende whiffea por diseño (`game-concept.md`, curva de entrada) |
| **R6 sobre valores efectivos**: toda reliquia que modifique `parry_window` o `recuperacion_whiff` debe reverificar la cobertura ≤65% | `design/gdd/eleccion-de-reliquias.md` *(no existe aún)* | Modificadores de ventana | **Constraint handoff** — verificado por el AC D10 |
| **Regla de precedencia armónica**: el Parry Justo se subordina al cierre de combo como variante tímbrica, nunca como capa superpuesta | `design/gdd/feedback-sonoro-parry.md` *(no existe aún)* | Mezcla de eventos 4 y 8 | **Constraint handoff** — este GDD crea la coincidencia (Fórmula 1), luego declara la regla; verificado por el AC V4 |
| **Exposición de `parry_window` y `recuperacion_whiff`** como knobs de asistencia, tuneados como par para no violar R6 | `design/gdd/accesibilidad.md` *(no existe aún)* | Modo de asistencia de timing | **Constraint handoff** |
| Regla visual "solo lo divino emite luz" | `design/art/art-bible.md` | Sección 1, Principio 2 | Rule dependency |
| Presupuesto de partículas y emisores | `design/art/art-bible.md` | Sección 8.6 | Rule dependency |
| Ancho de silueta de telegrafiado (>15–20% altura) | `design/art/art-bible.md` | Sección 3.5 | Rule dependency |

> Todas las referencias a GDDs inexistentes son **contratos declarados por
> anticipado**. Cuando esos GDDs se autoren, deben declarar la mitad simétrica del
> contrato (ver `systems-index.md`, Circular Dependencies).

## Acceptance Criteria

> Validados por `qa-lead`. Todos los criterios deben ser verificables por un tester
> que **no haya leído este GDD**, salvo los explícitamente marcados como
> instrumentados.

### Reglas núcleo

- [ ] **C1** — DADO un enemigo activo, CUANDO comienza un ciclo, ENTONCES el estado avanza en orden Telegrafiado → Golpe → Enfriamiento → (repite), sin poder saltar fases ni repetir Golpe sin pasar por Enfriamiento.
- [ ] **C2** *(instrumentado)* — DADO que el jugador presiona parry fuera de un Golpe, CUANDO se registra el input, ENTONCES entra en estado PARRY y permanece activo exactamente **13 ticks de simulación fija a 60Hz** (0.2167s — la fuente de verdad canónica; `parry_window=0.22s` en Tuning Knobs es el valor de diseño/legibilidad del que se deriva, no el valor runtime), medido en ticks de `_physics_process`, nunca en tiempo real ni en frames de renderizado (ver nota de Fuente de Verdad Canónica en Regla 2).
- [ ] **C3** — DADO un parry activo, CUANDO una **ventana parable** comienza dentro de la ventana activa (caso b) O el jugador presiona durante una **ventana parable** activa (caso a), ENTONCES el intento se resuelve como éxito **una única vez**, sin doble resolución si ambas condiciones se cumplen. **Verificable en las 4 combinaciones**: los dos tipos de ventana parable (`Golpe`, Ventana Especial) × los dos casos (a) y (b). *(Requantificado el 2026-08-04, enmienda A: la formulación anterior nombraba solo `Golpe` y por tanto el AC pasaba en verde mientras la Ventana Especial era imparable — el AC estaba calibrado al mismo subconjunto que la regla que verificaba.)*
- [ ] **C4** *(instrumentado)* — DADO un parry exitoso **resuelto contra un Golpe**, CUANDO se resuelve, ENTONCES se aplican las cuatro consecuencias en el mismo fotograma: daño de Postura, Gracia otorgada, hitstop disparado, enemigo en Repliegue. *(Acotación añadida en la 2ª pasada de `/design-review` del sistema 2: para un parry resuelto contra una **Ventana Especial** se aplican solo 2 de las 4 — ver la excepción de la Regla 4 y el AC **C5a** del sistema 2. Sin esta acotación, C4 y la Core Rule 5 del sistema 2 eran mutuamente incumplibles.)*
- [ ] **C5** — DADO que la Postura llega a 0, CUANDO ocurre en cualquier momento del ciclo (incluso a mitad de Golpe), ENTONCES el enemigo entra en Aturdido inmediatamente, interrumpiendo cualquier animación de ataque en curso, durante `ventana_castigo` (2.0s).
- [ ] **C6** — DADO que el jugador no está en PARRY activo cuando el Golpe conecta, CUANDO impacta, ENTONCES el jugador pierde Vida según el daño del ataque, sin aplicar daño de Postura al enemigo.
- [ ] **C7** — DADO cualquier estado del jugador, CUANDO presiona parry, ENTONCES el intento se ejecuta sin consumir Gracia, Vida ni ningún otro recurso, incluso si falla.
- [ ] **C8** — DADO 0 ángeles absorbidos y 0 bonos de reliquia, CUANDO se calcula `vida_maxima`, ENTONCES el resultado es exactamente 100; añadir un ángel absorbido suma exactamente 18.
- [ ] **C9** — DADO un patrón de N golpes encadenados, CUANDO el jugador parea los N consecutivamente, ENTONCES se aplica **una única** instancia de daño de Postura calculada con la calidad del último parry, no N instancias.
- [ ] **C10** *(instrumentado)* — DADO un parry que vence **sin encontrar ninguna ventana parable** (whiff), CUANDO expira la ventana, ENTONCES el jugador entra en Recuperación de whiff durante exactamente `recuperacion_whiff` ticks, durante los cuales **toda pulsación del botón de parry se descarta sin encolarse en buffer**; y DADO un parry que se resuelve con éxito **contra cualquiera de los dos tipos de ventana parable**, ENTONCES la recuperación es de 2–3 fotogramas y **no** bloquea el siguiente parry de un combo. **La segunda mitad se verifica por separado para `Golpe` y para Ventana Especial.** *(Requantificado el 2026-08-04, enmienda A.)*
- [ ] **C11** — DADO un enemigo Aturdido, CUANDO el jugador pulsa el botón con `restantes(T) > gracia_salida_castigo`, ENTONCES se ejecuta un Golpe de Castigo; CUANDO lo pulsa con `restantes(T) ≤ gracia_salida_castigo` o en el instante de restauración de Postura, ENTONCES se ejecuta un **Parry**, no un Castigo. **Verificable en el borde exacto**, que es `T_max_castigo = ventana_castigo − gracia_salida_castigo` — con los valores de lanzamiento (`ventana_castigo = 120`, `gracia_salida_castigo = 6`): **`T = 114` → Castigo, `T = 115` → Parry**; y en los dos extremos del estado: `T = 1` → Castigo, `T = 120` → Parry. **El test debe derivar el borde de los dos knobs, no codificar 114**: ambos son configurables (72–180 y 4–10) y un retune de cualquiera lo mueve — con `gracia_salida_castigo = 10` el borde cae en 110. Verifica además la **invariante de anchura**: la zona de gracia mide exactamente `gracia_salida_castigo` ticks, que es lo que distingue el conteo inclusivo del exclusivo. *(Ampliado el 2026-08-04, enmienda E: la formulación anterior era correcta pero solo exigía "ambos lados del borde" sin fijar en qué tick cae — que es exactamente el punto donde este GDD y el sistema 2 divergían, y donde un AC sin cifra no podía detectar la divergencia.)*
- [ ] **C12a** *(test unitario — ejecutable hoy, sin dependencias)* — DADO el ciclo interno PARRY → whiff → Recuperación de whiff **en aislamiento, sin ningún enemigo ni sistema 20**, CUANDO se simula un jugador que re-presiona el botón en cuanto es legal durante 1800 ticks de simulación fija (30s a 60Hz), ENTONCES `ticks_en_PARRY / 1800 ≤ 0.65` (con los valores actuales: 59%). Es el criterio que impide que machacar sea una estrategia de supervivencia viable.

  > **Por qué se separó de C12b**: la fórmula de cobertura (`parry_window_ticks / (parry_window_ticks + recuperacion_whiff)`, ver Interacciones entre knobs) **no tiene ningún término de ángel** — es puramente el ciclo interno del jugador. La versión anterior de C12 la ataba a "un ángel de cadencia fija" del sistema 20, que no existe, disfrazando de test de integración lo que es un test unitario ejecutable desde el primer sprint. Hallazgo de `qa-lead`.

- [ ] **C12b** *(integración — **bloqueado** hasta que exista un stub de IA de jefes)* — DADO un ángel con patrones que incluyan combos (stub de test con fases de duración controlada, no el sistema 20 final), CUANDO un jugador machaca a cadencia fija durante 30 segundos, ENTONCES su tasa de parries exitosos **no supera** la de un jugador que reacciona al telegrafiado. Mide el agujero que C12a no cubre: dentro de un combo la cobertura sube legítimamente al ~84% (recuperación de éxito de 2–3 ticks) y el Repliegue no se dispara entre golpes, así que un masher que acierta el primer golpe por azar entra en cobertura casi total para el resto. La palanca de mitigación es la varianza de separación intra-combo, propiedad del sistema 20 — ver la nota de R6.

  > ⚠️ **C12b es riesgo VIVO, no diferido — no equiparar con D10** *(distinción
  > añadida el 2026-08-04, changeset 1; hallazgo de `qa-lead`, afilado por
  > `creative-director`)*. La 2ª pasada marcó ambos ACs como "bloqueados" y los trató
  > igual. **No son el mismo tipo de bloqueo:**
  >
  > - **C12b** está bloqueado por un **fixture** (falta un stub de jefe). Pero el
  >   riesgo que mide —cobertura intra-combo del ~84% con el Repliegue sin dispararse
  >   entre golpes— **lo producen mecánicas que existen en este documento hoy**: los
  >   combos son propiedad de la Regla 9, no del sistema 20. Riesgo vivo, prueba
  >   ausente.
  > - **D10** está bloqueado por un **artefacto de diseño inexistente** (las
  >   reliquias). Su riesgo **no puede materializarse** hasta que exista el sistema 9.
  >
  > **Consecuencias operativas**: (1) el stub de jefe es una **dependencia de
  > calendario de este sistema**, no del 20, y debe planificarse como tal; (2) C12b es
  > **puerta de release** con disparador de desbloqueo declarado, no un AC diferido
  > sin fecha; (3) cualquier build que shippee patrones de combo **antes** de que el
  > sistema 20 declare su varianza de separación intra-combo debe aportar un playtest
  > manual documentado que confirme que machacar dentro del combo no domina, como
  > sustituto interino de C12b. Esto va en el plan de QA de la épica que implemente la
  > Regla 9, no en este GDD.

- [ ] **C13** *(instrumentado)* — DADO un parry exitoso que dispara hitstop, CUANDO se mide su duración en **reloj real**, ENTONCES dura exactamente **5 ticks de simulación fija (0.0833s)**, y esa duración medida **no varía** entre una ejecución a 60Hz de refresco y otra a 40Hz (perfil de batería de Steam Deck). **Tolerancia**: ±1 frame de render *del perfil que se está midiendo* — ±16.6ms a 60Hz, ±25ms a 40Hz. La ventana absoluta cambia con el perfil; lo que no puede cambiar es la duración medida. Verifica las reglas normativas 1 y 3 de la Regla 2 a la vez: si la implementación acumulase `delta` en vez de contar ticks, la duración se dispararía bajo la escala de tiempo diegética; si interpretase los ticks como tiempo escalado, duraría ~2 segundos.

  > **Confundidor declarado — `Engine.max_physics_steps_per_frame`** *(añadido el
  > 2026-08-04, changeset 1; hallazgo de `godot-specialist`)*. Godot limita por defecto
  > a **8** los ticks de física que puede ejecutar por frame renderizado (guarda contra
  > la espiral de la muerte). Bajo un stall severo en Steam Deck —streaming de assets,
  > pausa de GC, throttling térmico— los ticks quedan limitados respecto al tiempo
  > real: **el contador de ticks no se corrompe ni salta**, pero la duración
  > *wall-clock* de una ventana de N ticks fijos puede estirarse muy por encima de su
  > longitud de diseño. El modelo de la Regla 2 sigue siendo correcto; lo que se rompe
  > es la **medición** de este AC. **Obligación de protocolo para QA**: un fallo de C13
  > (y de P4) debe distinguir explícitamente entre *defecto de conteo de ticks* y
  > *confundidor por hitch de frame* —registrando frame time y conteo de ticks por
  > frame junto a la medición— porque ambos producen exactamente el mismo síntoma y
  > solo uno es un bug.

- [ ] **C14** *(instrumentado — requiere captura frame-accurate o contador de depuración; 5 ticks son ~3 frames de render a 40Hz y no son verificables a ojo)* — DADO un hitstop activo (simulación diegética al 4%), CUANDO se observan los nodos de HUD (Postura, Vida, temporizador de ventana de castigo), ENTONCES **siguen actualizándose a velocidad de proceso normal**, no escalada — contando las actualizaciones de HUD durante los 5 ticks de hitstop y comparándolas con las esperadas a framerate real. Es el AC que faltaba para la regla normativa 2 de la Regla 2: la revisión anterior resolvió ese bloqueante con prosa normativa y **sin ningún criterio que la hiciera verificable**.

- [ ] **C15** — DADO un combo de N golpes en el que el jugador falla el golpe `i` (con **`1 ≤ i ≤ N`**), CUANDO ese golpe conecta, ENTONCES los golpes restantes `i+1 … N` **no se ejecutan**: el ángel pasa a Repliegue y luego a su ciclo normal. El jugador recibe **exactamente un** golpe, nunca N. **Verificable en ambos bordes legales de N (3 y 5) y en los tres casos del rango de `i`: el primero (`i = 1`), uno intermedio, y el remate (`i = N`).** En `i = N` el conjunto `i+1 … N` es **vacío**, y el criterio verifica que aun así se dispara Repliegue **una sola vez** y **no** se aplica daño de Postura alguno. (Regla 9 — aclaración añadida en la re-review; hasta entonces "el combo se interrumpe" dejaba abierto si los golpes restantes seguían llegando mientras el jugador estaba en recuperación de Recepción de golpe.)

  > **Rango corregido de `i < N` a `1 ≤ i ≤ N` el 2026-08-04 (enmienda B).** La Regla 9 se cuantifica sobre "**cualquier** golpe del combo", y tanto el rango como su cláusula de verificación —que decía "`i` intermedio y **penúltimo**"— **excluían el remate**. El remate es justo el caso que importa: es donde el jugador ha parado `N−1` golpes y lo pierde todo, y es el que distingue "combo abortado" de "combo completado". Un AC que verifica el penúltimo golpe certifica el ejemplo, no la regla.

- [ ] **C16** *(instrumentado — requiere inyectar datos de patrón malformados; no ejecutable por un tester de caja negra sin herramienta de carga)* — DADO un patrón de ataque encadenado instanciado por el sistema 20, CUANDO se valida su longitud, ENTONCES `3 ≤ N ≤ 5` (Regla 9). Un patrón con N=2 o N≥6 debe **fallar la validación de datos al cargar**, no degradarse en silencio. Es la restricción que este GDD impone al sistema 20; sin este AC, violarla no rompería nada visible hasta que fallase R7 o el cue de audio.

- [ ] **C17** — DADO un jugador en Recuperación de whiff **o** en recuperación de un Golpe de Castigo, CUANDO pulsa el botón de parry una o varias veces, ENTONCES **ninguna pulsación produce feedback de ningún tipo** — ni visual, ni sonoro, ni háptico (evento 6b) — y **ninguna se ejecuta al terminar la recuperación**. Verificable por caja negra: mantener pulsado o repetir pulsaciones durante toda la recuperación y comprobar que al terminar **no** se dispara ningún parry sin una pulsación nueva. Extiende C10, que solo instrumentaba el caso de whiff, a la otra mitad de la fila de Edge Cases; y cubre la regla de "cero feedback por pulsación descartada" del evento 6b, que hasta ahora no tenía criterio (V2 solo mide que la recuperación no se sienta como lag, lo cual es distinto).

- [ ] **C18** *(instrumentado)* — DADO un build con **render y física desacoplados** (perfil de 40Hz del Steam Deck contra `physics_ticks_per_second = 60`), CUANDO el jugador pulsa el botón de parry, ENTONCES el input se registra en el tick de física correcto y `parry_window` sigue durando exactamente 13 ticks — sin inputs perdidos entre ticks ni ventanas alargadas. Verifica la regla normativa de lectura de input de la Regla 2 en el escenario que la motiva; C2 y P2 miden el resultado, pero solo en el caso acoplado.

> **Fixture compartido de C19–C21 — disparador de depuración de Ventana Especial**
> *(añadido el 2026-08-04, changeset 1 de la 3ª pasada; hallazgo de `qa-lead`)*. Los
> tres ACs siguientes requieren una **Ventana Especial** activa, que hoy solo puede
> nacer de un patrón con `interrumpible_por_parry = true` — propiedad de la **IA de
> Combate de Jefes (20)**, que **no existe todavía**. Se aplica el mismo patrón que
> P1 ya usa: un **disparador de depuración exclusivo de QA** que emita
> determinísticamente el par de eventos propio "inicio/fin de Ventana Especial"
> definido por el sistema 2, **sin depender de ningún patrón real del sistema 20**
> (mismo aislamiento que C12a). Con ese disparador, los tres son ejecutables desde el
> primer sprint; **sin él están bloqueados**.
>
> **Por qué se anota**: los tres ACs se escribieron el 2026-08-04 (enmiendas A y F)
> precisamente para verificar la enmienda que costó la aprobación de este documento,
> y **eran inejecutables sin decirlo**. `creative-director` lo calificó como el peor
> fallo de trazabilidad del documento. El coste de la corrección es una etiqueta.

- [ ] **C19** *(**bloqueado** hasta que exista el disparador de depuración de Ventana Especial — ver el fixture compartido arriba)* — DADO una **Ventana Especial** activa y **ningún `Golpe`** activo ni pendiente, CUANDO el jugador presiona parry dentro de ella, ENTONCES el intento se resuelve como **ÉXITO** (Regla 3) y el jugador **no** entra en Recuperación de whiff (Regla 7). Verificable en los dos casos de la Regla 3 por separado: pulsación dentro de la Ventana Especial ya abierta (caso a), y Ventana Especial que se abre con el parry ya activo (caso b).

  > Es el AC que la formulación anterior de las Reglas 3 y 7 **fallaba**: bajo ella este caso era un whiff con 9 ticks de bloqueo, y `interrumpible_por_parry = true` no podía dispararse jamás. Ningún AC existente lo detectaba porque **todos estaban cuantificados sobre `Golpe`, igual que las reglas que verificaban** — el patrón que el hallazgo de proceso de la 3ª pasada describe. Añadido el 2026-08-04, enmienda A.

- [ ] **C20** *(instrumentado; **bloqueado** hasta que exista el disparador de depuración de Ventana Especial — ver el fixture compartido arriba)* — DADO un parry exitoso resuelto contra una **Ventana Especial**, CUANDO se resuelve, ENTONCES se aplican **exactamente dos** de las cuatro consecuencias de la Regla 4, verificadas **una por una, en positivo y en negativo**: (1) Gracia absorbida **sí**, y completa —no reducida—; (2) hitstop y feedback **sí**; (3) daño de Postura **no** — la Postura del jefe queda **numéricamente idéntica** a la del fotograma anterior, no "aproximadamente igual"; (4) Repliegue **no** — el jefe pasa a `Enfriamiento`. *(Añadido el 2026-08-04, enmienda F: la excepción de Ventana Especial se introdujo el 2026-08-03 y hasta hoy no tenía ningún AC propio — solo la acotación **negativa** de C4, que dice de qué no responde pero no verifica nada.)*

- [ ] **C21** *(**bloqueado** hasta que exista el disparador de depuración de Ventana Especial — ver el fixture compartido arriba)* — DADO una **Ventana Especial** que vence **sin ser parada**, CUANDO se cierra, ENTONCES la Vida del jugador es **numéricamente idéntica** a la del fotograma anterior (corolario de la Regla 6: una Ventana Especial no parada no daña — es una ventana de oportunidad, no un ataque) y el jefe completa su habilidad. Contrasta explícitamente con **C6**, que verifica el caso `Golpe`, donde sí hay pérdida de Vida. *(Añadido el 2026-08-04, enmienda F: el corolario de la Regla 6 se escribió el 2026-08-03 sin ningún criterio que lo verificara.)*

- [ ] **C22** *(**bloqueado** hasta que exista el disparador de depuración de Ventana Especial — ver el fixture compartido arriba)* — DADO una **Ventana Especial** que vence **sin ser parada**, CUANDO **se cierra la ventana**, ENTONCES la Vida del jugador es numéricamente idéntica a la del fotograma anterior (ya cubierto por **C21**); y CUANDO la `Acción Especial` **se completa**, ENTONCES **la Vida del jugador sigue siendo numéricamente idéntica** —el sistema 2 declara que ese estado nunca la reduce— y la **magnitud que la habilidad declara perturbar** cambia exactamente en la cantidad declarada, cuya conversión a unidades de `dano_golpe_enemigo` cae dentro de la banda de **R9a**. **Verificable en los dos bordes**: severidad equivalente 1.0 y 2.0.

  > **Los dos instantes son distintos, y ninguno de los dos toca la Vida — C21, C22 y el sistema 2 son consistentes.** El cierre de la ventana y la completación de la habilidad son **dos transiciones separadas de la máquina de estados del sistema 2**, y este AC existe para forzar que se midan por separado: la primera no cambia **nada**, la segunda cambia la magnitud propia de la habilidad. El corolario de la Regla 6 sigue siendo literalmente cierto, y la prohibición del sistema 2 también. Un tester que mida ambos instantes como uno solo hará fallar C21 o C22 sin que haya ningún defecto.
  >
  > *(Reescrito el 2026-08-04, changeset 2 ítem 3. La versión del ítem 0 exigía una reducción de Vida de 25–50 y **contradecía frontalmente** al sistema 2, que declara dos veces que la `Acción Especial` nunca reduce la Vida del jugador. Ver la regla de conversión en el bloque "Sobre R9".)*

- [ ] **C23** *(instrumentado; mismo bloqueo de fixture que C19–C22)* — DADO un patrón con `interrumpible_por_parry = true` y severidad dentro de la banda de R9a, CUANDO se registran las **dos líneas de juego sobre la misma Ventana Especial** —(a) pararla, (b) ignorarla— y se comparan sus deltas en las dos monedas, ENTONCES **los signos son opuestos**: (a) evita el coste equivalente y gasta corrupción (Gracia absorbida completa, Regla 4); (b) conserva corrupción y paga al menos **1 unidad** de coste equivalente, medida sobre la magnitud que la habilidad declara perturbar. **Ninguna de las dos líneas es mejor o igual que la otra en ambas monedas a la vez.**

  > **Es la definición operativa de "no domina estrictamente", y es medible sin juicio humano**: se instrumentan `ΔGracia` y `Δ(magnitud declarada)` de ambas líneas y se comprueba la oposición de signos. No mide que la elección sea *interesante* —eso es playtest— sino que **existe**. *(La moneda del coste dejó de ser `ΔVida` el 2026-08-04, changeset 2 ítem 3 — ver C22 y la regla de conversión de R9a.)*
  >
  > **La aserción se apoya en una premisa que este GDD no posee** — ver **R9b**: que la Gracia sea un coste real. Si el sistema 5 acabase haciendo que absorber Gracia fuese beneficio sin contrapartida, `ΔGracia` dejaría de ser negativo para el jugador, los signos dejarían de oponerse y la dominación reaparecería **invertida** (parar dominaría a ignorar). Por eso R9a y R9b son una sola invariante escrita hacia dos sistemas, y por eso este AC verifica los signos en vez de dar por hecho el de la Gracia.

- [ ] **C24** — DADO el control de parry **mantenido pulsado** durante `N` ticks consecutivos (con `N` mayor que `parry_window + recuperacion_whiff`), CUANDO se cuentan los intentos de parry registrados, ENTONCES es **exactamente uno**: el flanco de bajada inicial. Ninguna repetición, ningún reintento automático al terminar la recuperación. Y DADO un **eje analógico** (gatillo, stick) mapeado a la acción de parry, CUANDO se validan los bindings al cargar, ENTONCES la validación **falla ruidosamente** — no existe conversión implícita de eje a botón.

  > **Es el AC que hace real el contrato de flanco digital que otros tres ACs ya asumían sin declararlo.** C10 (descarte sin buffer), C17 (cero feedback durante la recuperación) y la aritmética de cobertura de **R6** están todos cuantificados sobre "una pulsación", término que solo está bien definido si el control es digital: sobre un eje analógico hace falta umbral e histéresis, y el ruido cerca del umbral durante el lockout de 9 ticks produciría **descartes que el jugador no puede percibir** — indistinguibles de un bug de input. La segunda mitad usa el mismo patrón de validación de datos que **C16** y **D13**. Decisión de usuario del 2026-08-04; ver la regla de input de la Regla 2 y la corrección de `technical-preferences.md`.

- [ ] **C25** — DADO un parry exitoso **resuelto contra un `Golpe`**, CUANDO `calidad_timing ≥ umbral_parry_justo` (0.9 con los valores de lanzamiento), ENTONCES se clasifica como **Parry Justo** y disparan **las tres** señales a la vez y sobre el mismo predicado: la variante de esquirla hacia `#FFF8E7`, la capa de audio adicional (evento 4) y el bono de hitstop. CUANDO `calidad_timing < umbral_parry_justo`, ENTONCES **ninguna de las tres** dispara. El bono de hitstop se reparte por escalón: `calidad_timing = 1.0` → **+2 ticks**, `= 0.9` → **+1 tick**, por debajo → **+0**; en todos los casos se cumple **R8** (`hitstop_parry + bono ≤ 8`: 5+2 = 7 ✓).

  **Y DADO un parry exitoso resuelto contra una Ventana Especial**, ENTONCES **ninguna de las tres dispara nunca**, sea cual sea el timing: `calidad_timing` no se calcula para ese caso (ver la acotación de la Fórmula 1) y el hitstop es el base, sin bono. *(Acotación añadida el 2026-08-04, changeset 2 ítem 3, corrigiendo el cuantificador con el que este AC se escribió en el ítem 1.)*

  > **Cierra un término que tenía cinco consumidores y ninguna magnitud.** "Parry Justo" se nombra en doce sitios del documento —variante de VFX, capa de audio, bono de hitstop, **V4**, el Feel AC de "los playtesters lo distinguen sin que se les explique" y el peor caso de **P0**— y hasta el 2026-08-04 **ningún sitio decía qué valor de `calidad_timing` lo produce**, ni qué distinguía el +1 del +2. Era la raíz **C** con la escala de recompensa más visible del sistema: cinco capas reaccionando a un predicado que no existía. Solo se volvió cerrable al escalonar `calidad_timing` (D1). **El umbral se expresa en calidad, nunca en ticks**: con `umbral_precision` entre 5 y 7 equivale a `Δ ≤ 1`, y con 3 o 4 a `Δ = 0` — igual que el borde de Castigo, se deriva de los knobs y no se escribe como literal.

- [ ] **C26** — DADO cualquier reliquia o combinación de reliquias del sistema 9, CUANDO se validan al cargar, ENTONCES se evalúan **las cuatro magnitudes de R10** sobre la configuración resultante y la validación **falla ruidosamente** si cualquiera sale de banda. Una reliquia cuyo efecto declarado **no sea expresable como delta sobre esas cuatro magnitudes falla también**: no existe la categoría "efecto no clasificado".

  > **Es la cláusula que hace la restricción independiente del mecanismo, y sin ella R10 sería otra guarda sobre términos.** Las restricciones anteriores al sistema 9 nombraban *mecanismos* —`multiplicador_ataque` (R4), `bono_reliquias` (R5), `parry_window`/`recuperacion_whiff` (R6)— así que cualquier reliquia que produjera el mismo efecto por otra vía quedaba fuera por construcción: un Golpe de Castigo extra por aturdimiento rompe el suelo de ciclos **sin tocar el multiplicador**, y una reducción de daño recibido amplía el presupuesto de error **sin tocar `bono_reliquias`**. Al exigir que **todo** efecto se declare como delta sobre las cuatro magnitudes, un mecanismo nuevo no puede escaparse: o se expresa en esas unidades, o no carga. Mismo patrón de validación de datos que **C16** y **D13**.

### Fórmulas

- [ ] **D1** *(instrumentado)* — DADO `dano_base = 10`, `bono_precision = 0.4` y `umbral_precision = 5 ticks` (valores de lanzamiento), CUANDO se resuelve un parry exitoso con distancia medida `Δ` en ticks enteros, ENTONCES `calidad_timing` y `postura_dano` toman **exactamente** estos pares y ningún otro:

  | `Δ` (ticks) | 0 | 1 | 2 | 3 | 4 | 5 | ≥6 |
  |---|---|---|---|---|---|---|---|
  | `calidad_timing` | 1.0 | 0.9 | 0.7 | 0.5 | 0.3 | 0.1 | 0.0 |
  | `postura_dano` | 14.0 | 13.6 | 12.8 | 12.0 | 11.2 | 10.4 | 10.0 |

  (El límite teórico de 15 solo es alcanzable con `bono_precision = 0.5`, el techo del rango de tuning — no usarlo como criterio pasa/falla salvo que ese knob se reconfigure explícitamente para la prueba.) *(Reescrito el 2026-08-04, changeset 2 ítem 1: la formulación anterior solo fijaba los dos extremos de una escala tratada como continua, y por tanto **pasaba en verde con cualquier resolución de medición**, incluida una implementación por reloj real que la Regla 2 prohíbe.)*

- [ ] **D2** — DADO tríada de índice 0/1/2, CUANDO se instancia el enemigo, ENTONCES `postura_max` = 30/40/50 exactamente.
- [ ] **D3** — DADO tríada de índice 0, CUANDO se calcula `punish_dano_pct`, ENTONCES el valor es 25% (100/4); verificable para los tres índices.
- [ ] **D4** *(instrumentado)* — DADO un parry exitoso **resuelto contra un `Golpe`** que **no** forma parte de un combo en curso (o que es el golpe final/de interrupción de un combo — ver Regla 9), CUANDO el enemigo entra en Repliegue, ENTONCES su duración es 0.7s ± 1 tick (a 60Hz de simulación fija — ver Fuente de Verdad Canónica, Regla 2). DADO un parry exitoso intermedio dentro de un combo activo, ENTONCES no se dispara Repliegue en absoluto. DADO un parry exitoso resuelto contra una **Ventana Especial**, ENTONCES **tampoco** se dispara Repliegue en ningún caso — el jefe pasa a `Enfriamiento` (ya verificado por **C20** punto 4; se referencia aquí para que el cuantificador de este AC sea completo y no quede ambiguo qué debe medir el tester).

  > **Acotado a `Golpe` el 2026-08-04 (changeset 1, 3ª pasada).** Ni este AC ni la Fórmula 4 usaban la palabra "Golpe", así que **el barrido léxico de la enmienda A no los encontró** pese a que ambos expresaban el mismo cuantificador incompleto que aquella enmienda existía para cerrar. Raíz **A**. Hallazgo de `qa-lead`.
- [ ] **D5** — Cubierto por C8 (`vida_maxima`).
- [ ] **D6** — DADO `vida_max_angel = 100`, `punish_dano_pct = 25%`, `multiplicador_ataque = 1.0`, CUANDO se ejecuta el Golpe de Castigo, ENTONCES `dano_golpe_castigo = 25`.
- [ ] **D7** — DADO un combo de 3 golpes pareados, CUANDO se calcula `gracia_ganada` por cada golpe, ENTONCES cada uno otorga `0.5 × gracia_base`, no `gracia_base` completa; y el total del combo (`1.5 × gracia_base`) es **estrictamente mayor** que el de un golpe simple (`1.0 × gracia_base`) — la garantía de la Regla 9, verificada, no asumida.
- [ ] **D8** — DADO cualquier configuración de reliquias, CUANDO se resuelve `multiplicador_ataque`, ENTONCES su valor es **exactamente 1.0** (invariante R4, constante en ambos sentidos), y el número de Golpes de Castigo necesarios para vaciar la Vida del ángel es **exactamente `ciclos_objetivo(tríada)`** — 4/5/6 según tríada, ni menos (rompería el suelo de la Fórmula 3) ni más (attrition-fest). Test de rango sobre todas las configuraciones de reliquias, no de caso puntual.
- [ ] **D9** *(instrumentado)* — **Dos aserciones distintas, ambas obligatorias:**

  **(a) Configuración de lanzamiento.** DADO el conjunto de valores actuales de Tuning Knobs, CUANDO se evalúan las invariantes **R1–R8**, ENTONCES **todas se cumplen**. Ésta es la puerta que protege el build.

  **(b) Barrido del espacio declarado.** DADO el conjunto de casos enumerado abajo, CUANDO se evalúa cada caso, ENTONCES el veredicto PASS/FAIL calculado **coincide exactamente con el veredicto declarado en la tabla de referencia** de este AC — ni una violación más, ni una menos. Ésta no es una puerta de corrección de valores: es un **test de caracterización del espacio de tuning**, y su función es detectar que alguien ha movido un rango sin actualizar la invariante correspondiente.

  > ⚠️ **Corrección del predicado (2026-08-04, changeset 1 de la 3ª pasada).** La
  > formulación anterior era **"ENTONCES todas [las invariantes] se cumplen" sobre los
  > 92 casos**, y eso es **matemáticamente falso por construcción del propio documento**:
  >
  > | Invariante | Esquina | Cálculo | Veredicto |
  > |---|---|---|---|
  > | R1 | `dano_base=15`, `bono_precision=0.5`, `postura_base=20` | `15 × 1.5 = 22.5 < 20` | **FALLA** — y es la esquina que la propia nota de R1 describe |
  > | R2 | `parry_window=9 ticks`, `umbral_precision=7 ticks` | `9 > 2 × 7 = 14` | **FALLA** — la nota de R2 ya declara insegura el 66.7% de la región |
  > | R5 | `bono_vida_por_absorcion=15`, `vida_base=80` | `(15×3)/80 = 56.25% > 55%` | **FALLA — y no estaba documentado.** La nota "Sobre R5" solo documenta la esquina del techo (75%) e induce a creer que el suelo 15 es seguro. **2 de las 4 esquinas de R5 fallan, no 1** |
  > | R6 | rejilla completa | 18 de 70 | **FALLAN** — declarado por el propio documento doce líneas antes de este AC |
  >
  > No hacía falta ir a las esquinas para verlo: **D9 enumera el producto completo de
  > R6 y el documento declara doce líneas más arriba que 18 de esas 70 lo violan.** El
  > AC se contradecía a sí mismo dentro de su propia tabla de casos. Implementado
  > literalmente como puerta de CI —y `coding-standards.md` prohíbe desactivar tests
  > que fallan— **habría fallado el día uno, para siempre**.
  >
  > **La trampa del arreglo obvio**: debilitar la aserción a "verificar solo la
  > configuración shippeada" **borraría la protección entera**, que es justo el barrido
  > que encontró el 25.7% de R6. Por eso el arreglo es *partir* el AC en (a) y (b), no
  > recortarlo. Hallazgo de `systems-designer`, verificado independientemente por
  > `creative-director`.

  > **Espacio de casos (normativo — no "los extremos" a interpretación del implementador).** Las combinaciones son **intra-invariante**, nunca cruzadas entre invariantes con knobs disjuntos; cruzarlas daría 2⁹ = 512 casos sin valor añadido. `angeles_max` se fija en **3** (v1.0/Alpha) — R5 no está calibrada por encima de eso y debe re-derivarse *y* re-testearse antes de subirlo.
  >
  > | Invariante | Knobs | Casos | Violaciones esperadas en el barrido |
  > |---|---|---|---|
  > | R1 | `dano_base`, `bono_precision`, `postura_base` | 2³ = 8 esquinas | **≥1** — la esquina (15, 0.5, 20) |
  > | R2 | `parry_window`, `umbral_precision` | 2² = 4 esquinas, **ambos knobs ya en ticks** | **≥1** — la esquina (9 ticks, 7 ticks) |
  > | R3 | constante | 1 | 0 |
  > | R4 | `multiplicador_ataque` | 1 (constante) | 0 |
  > | R5 | `bono_vida_por_absorcion`, `vida_base` (con `angeles_max = 3` fijo) | 2² = 4 esquinas | **2** — (20, 80) → 75% y (15, 80) → 56.25% |
  > | R6 | `parry_window_ticks` × `recuperacion_whiff` | **producto completo, 10 × 7 = 70** — aquí sí se barre la rejilla entera, porque el 25.7% de violaciones no está en las esquinas sino en el interior | **18** — exactamente las de la tabla de la sección R6 |
  > | R7 | `modificador_combo_gracia`, `N_min` | 2² = 4 esquinas | 0 — verificado limpio en toda la matriz `N∈{3,4,5} × mod∈{0.35,0.8}` |
  > | **R8** | `hitstop_parry`, `bono_hitstop_parry_justo` | 2² = **4 esquinas** | 0 — pasa limpio (`6+2 = 8 ≤ 8`, `3+1 = 4`) |
  >
  > **Total: 96 casos.** Corre en segundos y es mantenible.
  >
  > **R8 añadido el 2026-08-04 (changeset 1).** Se incorporó a las Restricciones
  > Conjuntas en la verificación de alcance reducido de la 2ª pasada pero **nunca se
  > folió en D9**, que seguía enumerando R1–R7 — de modo que la única puerta
  > automatizada del bloque no cubría la invariante más reciente. Cuesta 4 casos y
  > pasa limpio. Hallazgo de `systems-designer`.
  >
  > **R9 y R10 están deliberadamente fuera de este barrido, y se declara por qué**
  > *(2026-08-04, changeset 2)*. D9 barre **combinaciones de knobs de este GDD**;
  > R9a se cuantifica sobre `severidad_accion_especial`, que **no es un knob de este
  > documento** —lo declara el sistema 20 por habilidad— y su verificación es de
  > **validación de datos al cargar**, no de barrido de rangos: está cubierta por
  > **D13**, con la misma forma que **C16** usa para `3 ≤ N ≤ 5`. R9b no es verificable
  > por este GDD en absoluto hasta que exista el GDD de Gracia; su verificación
  > indirecta es **C23**, que comprueba la oposición de signos en vez de asumir el de
  > la Gracia.
  >
  > **R10a–R10d** son el contrato con el **sistema 9** y se cuantifican sobre
  > configuraciones de **reliquias**, que no son knobs de este documento y hoy **no
  > existen**. Su verificación es validación de datos al cargar (**C26**) más dos tests
  > de magnitud (**D15**, **D16**), y está bloqueada por el **mismo tipo de artefacto
  > inexistente que D10** — no por un fixture, así que su riesgo tampoco puede
  > materializarse todavía. Cuando exista el GDD del sistema 9, D15/D16 corren sobre su
  > catálogo real; **no** procede añadirlas a este barrido, que seguiría enumerando
  > knobs propios.
  >
  > Se anota explícitamente porque **la omisión silenciosa es el defecto que este mismo
  > AC ya sufrió con R8**: se incorporó a Restricciones conjuntas y nunca se folió aquí,
  > de modo que la única puerta automatizada del bloque no cubría la invariante más
  > reciente. Una invariante fuera de D9 es aceptable; **una invariante fuera de D9 sin
  > decirlo, no**.

  > **Nota de mantenimiento**: la columna "violaciones esperadas" es parte normativa
  > del AC, no comentario. Si un retune cambia esas cifras, **hay que actualizar esta
  > tabla en el mismo changeset** — que es precisamente la señal que la aserción (b)
  > existe para producir.
- [ ] **D10** *(**diferido** hasta que exista el GDD de Elección de Reliquias — bloqueado por un **artefacto de diseño inexistente**, no por un fixture, así que su riesgo no puede materializarse todavía. **No equiparar con C12b**, que sí es riesgo vivo — ver la nota bajo C12b; equipararlos fue un error de la 2ª pasada, corregido el 2026-08-04)* — DADO cualquier reliquia del sistema 9 que modifique `parry_window` o `recuperacion_whiff`, CUANDO se calcula la cobertura con los valores **efectivos resultantes**, ENTONCES R6 se sigue cumpliendo (`≤ 65%`). Este AC cubre el agujero que R4 no cerraba: el techo de daño impide escalar el castigo, pero nada impedía que una reliquia de "+2 fotogramas de ventana" reabriera el mash en silencio.

- [ ] **D11** *(instrumentado)* — DADO `vida_base = 100` y `golpes_para_morir_base = 4`, CUANDO un `Golpe` conecta sin haber sido parado, ENTONCES la Vida del jugador se reduce en exactamente **25** (Fórmula 8). Y DADO **el mismo jugador con 3 ángeles absorbidos** (`vida_maxima = 154`, Fórmula 5), CUANDO conecta un `Golpe` idéntico, ENTONCES la reducción sigue siendo exactamente **25**, **no 38.5** — la Fórmula 8 se ancla en `vida_base`, nunca en `vida_maxima`. **Verificable además en los tres índices de tríada: el valor es idéntico en los tres**, sin escalado alguno por tríada.

  > **Un solo AC contra tres modos de fallo distintos, y ninguno es el valor.** (1) **Ancla equivocada**: si la fórmula colgase de `vida_maxima`, el jugador moriría siempre en el mismo número de golpes hiciera lo que hiciera, y absorber dejaría de comprar supervivencia — se destruiría la "decisión de diseño clave" de la Fórmula 5, que es el pivote del dilema moral entero. (2) **Escalado por tríada**: violaría el preámbulo de esta sección ("la dificultad entre tríadas viene de exigir más parries y más ciclos, nunca de números artificialmente más grandes") y el Pilar 1. (3) El valor. El caso de las 3 absorciones no es decoración: es el **único** que distingue las dos anclas, porque a 0 absorciones `vida_base` y `vida_maxima` coinciden y cualquiera de las dos implementaciones pasa.

- [ ] **D12** — DADO un jugador sin absorciones ni reliquias (`vida_maxima = 100`), CUANDO recibe `Golpe`s consecutivos sin parar ninguno, ENTONCES muere **en el cuarto** (100 → 75 → 50 → 25 → 0). DADO un jugador con las 3 absorciones de v1.0 y `bono_vida_por_absorcion = 18` (`vida_maxima = 154`), ENTONCES muere **en el séptimo** (tras el sexto le quedan 4 puntos). Verificable también en el **suelo del knob** (`bono = 15` → `vida_maxima = 145` → muere en el sexto). Es el AC que le da contenido operativo a R5: el swing de corrupción se mide aquí en golpes sobrevividos, que es la moneda que el jugador percibe.

- [ ] **D13** — DADO un patrón del sistema 20 con `interrumpible_por_parry = true`, CUANDO se valida al cargar, ENTONCES se comprueban **las dos cláusulas de R9a por separado**: **(a)** la severidad declarada de cada `Acción Especial` cumple `1.0 ≤ severidad_accion_especial ≤ 2.0` — verificable en los cuatro bordes: **0.99 falla, 1.0 pasa, 2.0 pasa, 2.01 falla**; y **(b)** la suma de severidades de todas las Ventanas Especiales que ese patrón puede emitir en un duelo cumple `Σ severidad ≤ golpes_para_morir_base − 1` (= **3** con los valores de lanzamiento). Un patrón que viole cualquiera de las dos **falla la validación de datos al cargar**, no se degrada en silencio. **Y (c)**: el patrón debe **declarar la magnitud que la habilidad perturba y su equivalencia** en unidades de `dano_golpe_enemigo` (regla de conversión de R9a); una `Acción Especial` interrumpible **sin equivalencia declarada falla también** — no existe la categoría "coste no cuantificado", que es exactamente lo que era *"el jefe completa su habilidad"* antes del changeset 2.

  > **Por qué (b) no es redundante con (a)** — y por qué (a) sola sería la cuarta aparición de la raíz **C** en este documento. La banda por ventana acota **un término**; lo que puede matar al jugador es **la suma**, y cuántas Ventanas Especiales emite un duelo es propiedad del sistema 20, no de este GDD. Con solo (a), un patrón con tres VEs a 2.0 impone 150 de daño ignorable a un jugador de 100 de Vida: parar dejaría de ser una elección y pasaría a ser obligatorio, destruyendo el dilema por el lado opuesto al que R9a existe para cerrar. La cláusula (b) fija el contrato real: **ignorar todas las Ventanas Especiales de un duelo nunca puede ser letal por sí solo.** Deja al sistema 20 elegir la forma —una VE a 2.0, o hasta tres a 1.0— sin poder salirse del presupuesto.
  >
  > Mismo patrón de validación de datos que **C16** usa para `3 ≤ N ≤ 5`: una restricción que este GDD impone a otro sistema solo es real si su violación falla ruidosamente al cargar.

- [ ] **D14** *(instrumentado)* — DADO cualquier secuencia de parries exitosos, CUANDO se registran todos los valores de `calidad_timing` producidos, ENTONCES **(a)** todo valor pertenece al conjunto cerrado de **7 escalones** de D1 — **ningún valor intermedio es alcanzable**; y **(b)** la función es **monótona no creciente en `Δ`**: nunca un `Δ` mayor produce una calidad mayor.

  > **La cláusula (a) es un test de la Regla 2 disfrazado de test de fórmula, y es su verificación más barata.** `calidad_timing` solo puede tomar valores intermedios si `Δ` se midió con una resolución más fina que el tick — es decir, si la implementación leyó reloj real en vez de contar ticks de `_physics_process`. **La aparición de un solo valor intermedio es prueba directa de una implementación por wall-clock**, que es exactamente el drift que la Regla 2 existe para evitar y que ningún otro AC detecta en el camino del input (C13 y C18 miden duraciones y registro de input, no la resolución de la medida). Hallazgo del changeset 2 ítem 1.

- [ ] **D15** *(instrumentado)* — DADO cualquier configuración de reliquias equipadas, CUANDO se calcula `golpes_sobrevividos = ⌈vida_maxima / dano_golpe_enemigo⌉` **para los cuatro valores de `angeles_absorbidos` (0, 1, 2, 3)**, ENTONCES en **todos** ellos el resultado excede como máximo en **1** al de la misma cuenta de absorciones **sin ninguna reliquia** (invariante **R10a**). El techo absoluto es **8 golpes**.

  **El cálculo usa `dano_golpe_enemigo` efectivo tras reliquias**, no el de lanzamiento: una reliquia de reducción de daño recibido entra por esta vía y se cuenta aquí. Bordes verificables con los valores de lanzamiento: una reliquia de **+25 de Vida pasa** y una de **+26 falla**; una de **−20% de daño recibido pasa** y una de **−25% falla**.

  > **La configuración vinculante es la de 0 absorciones, y ése es el punto del test.** Sin reliquias el jugador sobrevive 4/5/6/7 golpes según absorciones. El presupuesto de Vida que deja la invariante es **+25** a 0 absorciones, pero **+46** a 3 — porque el redondeo hacia arriba deja más holgura cuanto mayor es la Vida base. **Un test que solo midiera al jugador totalmente absorbido dejaría pasar casi el doble de lo legal**, y es la lectura natural si el AC no obliga a barrer las cuatro cuentas. Es el mismo modo de fallo que la nota "Sobre R5" documenta: evaluar el acoplamiento en una sola dirección.
  >
  > **Cierra el hallazgo registrado sobre R5** (detectado al derivar la Fórmula 8, sesión anterior; ver la nota "Sobre R5"): R5 mide el swing en **puntos de Vida** y la magnitud que el jugador percibe son **golpes sobrevividos**. R10a mide directamente la magnitud, así que R5 queda como guarda del **par de knobs** de este GDD y **deja de ser** la que protege la premisa "absorber es la palanca de supervivencia" — eso lo hace ahora R10a, y lo hace sobre todos los términos y todos los mecanismos, no sobre uno.

- [ ] **D16** *(instrumentado)* — DADO cualquier configuración de reliquias, CUANDO se cuentan **(a)** los **ciclos de Aturdido** necesarios para vaciar la Vida del ángel y **(b)** los **parries** necesarios para romper la Postura evaluados a `calidad_timing = 0`, ENTONCES para los tres índices de tríada **(a)** es exactamente `ciclos_objetivo(tríada)` — 4/5/6 — y **(b)** es exactamente `⌈postura_max(tríada) / dano_base⌉` — 3/4/5 (invariantes **R10b** y **R10c**). Ninguna configuración legal de reliquias altera ninguno de los dos.

  > **(a) cuenta CICLOS, no Golpes de Castigo, y ésa es toda la diferencia con D8.** D8 verifica que `multiplicador_ataque` valga 1.0 y que hagan falta `ciclos_objetivo` **golpes de castigo** — pero una reliquia que conceda **un Golpe de Castigo extra por aturdimiento** deja el multiplicador intacto, sigue necesitando 4/5/6 golpes de castigo, y **mata en la mitad de ciclos**. D8 pasa en verde mientras el suelo de ciclos se rompe. Contar ciclos captura las dos vías con una sola medida. Hallazgo de `economy-designer`, 3ª pasada; **tercera recurrencia de la raíz C** sobre el contrato con el sistema 9.
  >
  > **(b) se evalúa a `calidad_timing = 0` deliberadamente.** Un jugador que encadena Parries Justos rompe Cosmos en 3 parries en vez de 4 (`40 / 14 = 2.86`), y eso es **maestría, no una reliquia**: la reducción por calidad es la recompensa que la Fórmula 1 existe para dar. Fijar el suelo de calidad separa las dos causas, que es justo lo que un AC sin cuantificador dejaría confundidas.

### Casos límite críticos

- [ ] **E1** *(instrumentado)* — DADO que el jugador presiona parry exactamente en el fotograma de apertura o de cierre de la ventana, CUANDO se evalúa, ENTONCES el resultado es éxito en **ambos** extremos (test frame-perfect en los dos bordes).
- [ ] **E2** — DADO un combo de 3 golpes donde el golpe 2 falla, CUANDO se resuelve, ENTONCES no se aplica daño de Postura alguno, pero la Gracia del golpe 1 ya absorbida **se conserva**.
- [ ] **E3** — DADO Postura en 0 (Aturdido), CUANDO expira `ventana_castigo` sin que el jugador golpee, ENTONCES la Postura se restaura **por completo** a `postura_max`, no parcialmente.
- [ ] **E4** *(instrumentado — requiere acceso a logs/telemetría, no verificable solo por observación)* — DADO **ninguna ventana parable** activa ni pendiente dentro de la ventana de parry, CUANDO el jugador presiona parry, ENTONCES no hay daño, gracia ni coste de recurso (whiff — sí hay coste temporal, ver C10), y este resultado debe distinguirse explícitamente de un fallo real en logs/telemetría, no solo en el resultado visual. *(Requantificado el 2026-08-04, enmienda A: la formulación anterior decía "DADO ningún Golpe activo", lo que la ponía en **contradicción directa con C19** — con una Ventana Especial activa y ningún `Golpe`, E4 afirmaba whiff y C19 exige éxito. Es la misma cláusula hermana, en su tercera aparición.)*
- [ ] **E5** — DADO que la Postura del enemigo está en un valor menor que `postura_dano` de un parry exitoso (p. ej. Postura=5, `postura_dano=12`), CUANDO se aplica el daño, ENTONCES la Postura resultante es exactamente 0 (nunca negativa) y el exceso (7 en el ejemplo) no se aplica como daño de Vida, gracia extra, ni se acumula para el siguiente ciclo de Postura.
- [ ] **E6** — DADO que el jugador está en estado PARRY (de un intento nuevo, no relacionado con el golpe que rompió Postura), CUANDO la Postura del enemigo llega a 0 en ese mismo instante, ENTONCES el enemigo entra en Aturdido inmediatamente y la ventana de Golpe de Castigo se abre sin demora ni bloqueo por parte del estado PARRY del jugador; el estado PARRY del jugador no se cancela ni se extiende por este evento — sigue su propio ciclo de vida independientemente. (Distinto de C5, que cubre la interrupción de la animación de ataque del **enemigo**, no el estado del jugador.)
- [ ] **E7** — DADO que la Vida del jugador llega a 0 en el mismo fotograma en que el enemigo está en estado Aturdido (o en cualquier otro estado), CUANDO se resuelven ambos eventos, ENTONCES el duelo termina en derrota del jugador inmediatamente; el estado del enemigo (Aturdido, restauración de Postura, ventana de Golpe de Castigo abierta) no impide, retrasa ni revierte la transición a derrota.
- [ ] **E8** — DADO que el Golpe del enemigo conecta sin haber sido parado, CUANDO el enemigo transiciona a Enfriamiento, ENTONCES la duración de ese Enfriamiento es idéntica a la que tendría tras un parry exitoso del jugador (sin bonificación de velocidad ni Repliegue adicional atribuible al fallo del jugador).
- [ ] **E9** — DADO 3 ángeles con decisiones "rechazar, absorber, absorber" en ese orden, CUANDO se calcula `vida_maxima`, ENTONCES el resultado es idéntico al de la secuencia "absorber, rechazar, absorber" con las mismas 2 absorciones netas (`100 + 2*18 = 136` en ambos casos) — la independencia de orden declarada en Edge Cases se verifica explícitamente, no solo se asume.

- [ ] **E10** — DADO un Golpe de Castigo **no letal** (la Vida del jefe queda **estrictamente > 0 tras el clamp** — ver la regla de clamp en la Fórmula 6) que **conecta** dentro de la ventana de Aturdimiento, CUANDO el enemigo sale del estado Aturdido, ENTONCES su Postura es exactamente `postura_max` (restauración íntegra, sin acarreo del ciclo anterior) y el número de parries necesarios para el siguiente ciclo es idéntico al del primero. Verificable para los tres índices de tríada. *(Acotado a "no letal" el 2026-08-04, enmienda G: la formulación anterior se cuantificaba sobre **todo** castigo conectado, incluido el que mata al jefe — para el cual no hay salida de Aturdido, ni restauración, ni ciclo siguiente que contar. Ver **E11**.)*

- [ ] **E11** — DADO un Golpe de Castigo **letal** (deja la Vida del jefe en **0 tras el clamp**, lo que incluye el caso de overkill y el de residuo de coma flotante `≤ 1e-6` — ver la regla de clamp en la Fórmula 6), CUANDO se resuelve, ENTONCES el jefe **no** restaura Postura, **no** reanuda su ciclo de ataque y **no** vuelve a emitir ninguna ventana parable; el duelo termina en victoria y el evento "duelo ganado" lo emite el sistema 2 al entrar en `Muerto`, **no este sistema** (ver la nota de propiedad en Dependencies). Verificable en el caso más frecuente —el castigo número `ciclos_objetivo(tríada)`— para los tres índices de tríada. **Contrasta con E10 en las tres consecuencias**, y entre ambos cubren el rango completo del cuantificador de la Regla 5. *(Añadido el 2026-08-04, enmienda G. No es un borde raro: con `ciclos_objetivo` de 4/5/6 es uno de cada 4, 5 o 6 castigos.)*

- [ ] **E12** *(instrumentado)* — DADO un Golpe de Castigo cuyo daño calculado **excede** la Vida restante del jefe (overkill), CUANDO se aplica, ENTONCES la Vida resultante es exactamente **0**, nunca negativa, y el exceso no se transfiere, no se acumula ni produce efecto alguno (simetría estricta con **E5** para la Postura). **Verificable además en el caso que motiva la regla**: para la tríada de Cercanía a Dios (`punish_dano_pct = 100/6 = 16.666…%`, no representable en binario), tras los `ciclos_objetivo = 6` castigos la Vida es **0 exacto tras el clamp**, y el golpe se clasifica como **letal** (E11), no como no letal (E10) por culpa de un residuo. Verificable para los tres índices de tríada. *(Añadido el 2026-08-04, changeset 1 de la 3ª pasada: la Vida del jefe era el único recurso agotable del sistema sin regla de overkill declarada, lo que dejaba a E10/E11 sin ser partición exhaustiva. Raíz **C**.)*

- [ ] **E13** *(instrumentado)* — DADO una Vida del jugador de **10** y un `Golpe` no parado de **25** (Fórmula 8), CUANDO se aplica el daño, ENTONCES la Vida resultante es exactamente **0**, nunca negativa; el exceso (15) no se transfiere, no se acumula y no produce efecto alguno. Un residuo de valor absoluto `≤ 1e-6` se trata como 0 a todos los efectos. **Tras el clamp**, `Vida == 0` es la condición **exacta** que dispara **"duelo perdido"** (Regla 6, Dependencies), sin depender de ninguna comparación `< 0`. **Verificable además fuera de `vida_base = 100`**: con `vida_base = 110` (el suelo efectivo que impone la nota de R5), `dano_golpe_enemigo = 27.5` y la Vida del jugador **no es entera en ningún momento del duelo** — el cuarto golpe la deja en 0 exacto tras el clamp, no en un negativo minúsculo.

  > **Simetría estricta con la regla de clamp de la Vida del jefe (Fórmula 6) y con E12/E5 — y su ausencia era la cuarta aparición de la raíz C.** El changeset 1 le dio regla de overkill a la Vida del jefe precisamente porque era "el único recurso agotable del sistema sin ella"; esa afirmación **era falsa al escribirse**: la Vida del jugador tampoco la tenía. Nadie lo detectó porque hasta el changeset 2 **el daño al jugador no era una cantidad calculada** — la Regla 6 decía "reduce su Vida actual" sin fórmula, así que no había magnitud que pudiera desbordar. La Fórmula 8 la crea, y con `vida_base` en su rango 80–150 el cociente `vida_base / golpes_para_morir_base` **no es entero en la mayor parte del rango**. Sin este AC, el fixture de **E7** (muerte del jugador en el mismo fotograma que un estado del jefe) no es construible de forma fiable, exactamente el mismo defecto que E12 corrigió para E11.

### Rendimiento

- [ ] **P0** *(prerrequisito de P1 — **con condición de fallo propia**)* — DADO los materiales de partículas reales de este sistema, CUANDO `technical-artist` mide el coste de **draw calls por emisor `GPUParticles2D`** en el peor caso de concurrencia (3 emisores simultáneos, incluyendo la variante `#FFF8E7` de Parry Justo), ENTONCES esa cifra se contrasta contra el **presupuesto real de VFX en combate**, no contra el techo global. **P0 falla** si los 3 emisores concurrentes superan **~20 draw calls** en la composición de escena más cara ya comprometida por el art bible 8.6. Un P0 fallido **invalida P1 como puerta de rendimiento** y obliga a rediseñar el presupuesto de partículas (menos emisores concurrentes, o menos materiales por emisor) antes de que la sección de Rendimiento pueda certificarse.

  > **Por qué cambió (re-review, `performance-analyst` corrigiéndose a sí mismo)**: la versión anterior contrastaba contra "<1000 draw calls por escena" y no declaraba ninguna condición de fallo. Pero el art bible 8.6 ya fija el **pico de combate en 40–80 draw calls** con el desglose repartido (protagonista 3–5, jefe 2 +1 por coro, arena 5–10, UI 1–3, **"VFX = resto"**) — el resto real es del orden de **~20**, no 1000. Era una puerta que pasaba siempre, aunque los 3 emisores costasen 45 draw calls y reventasen el presupuesto de combate. Un prerrequisito que solo exige "documentar la cifra" no protege nada.
- [ ] **P1** — DADO un build en **hardware real de Steam Deck** (no PC) y un **disparador de depuración exclusivo de QA que fuerce determinísticamente la coincidencia de los eventos visuales 8 (combo completo) + 11 (punish hit)**, CUANDO el jugador completa 3 duelos consecutivos sin pausas de carga entre ellos — uno por tríada (Humanidad, Cosmos, Cercanía a Dios, en ese orden) — y el peor caso se fuerza **entre 3 y 5 veces** a lo largo de la sesión, ENTONCES el frame time no excede 16.6ms en **todas** las activaciones, medido con **dos métricas que deben pasar por separado**: (a) percentil 99 sobre la sesión completa, y (b) **percentil 99 calculado solo sobre la ventana de ±5 frames alrededor de cada activación forzada del disparador**. La prueba se ejecuta además **dos veces: en modo dock y en modo portátil/batería (incluido el perfil de 40Hz)**, y las cuatro combinaciones deben pasar por separado. Toda medición de frame time es **wall-clock de render**, no derivada de ticks de simulación.

  > **Por qué la métrica (b)** (hallazgo de `performance-analyst`, re-review): con ~5 ticks de hitstop por parry y 35–40 parries por duelo alto, los frames "en riesgo" son una fracción minúscula de los miles de frames de una sesión de 3 duelos. Un par de picos de 20ms en el instante de transición de escala de tiempo —justo donde coinciden spawn de partículas, disparo de audio en capas y resincronización— quedaría **diluido y sería invisible** en un P99 global. El P99 global no prueba lo que P1 dice probar.

  > **P1 es además el fixture natural de E11** *(anotado el 2026-08-04, changeset 1; hallazgo de `performance-analyst`)*: los 3 duelos forzados terminan, por construcción, en un Golpe de Castigo **letal** cada uno — uno por tríada. E11 queda ejercitado 3 veces sin coste adicional, y conviene declararlo para que no se lea después como rama sin probar.

  > **Por qué cambió**: la versión anterior exigía que la coincidencia 8+11 ocurriera "dentro del duelo de Cercanía a Dios" en juego en vivo, lo que dependía del RNG del sistema 20 (sin escribir) y de la habilidad del tester para provocarla. Una puerta que no se puede reproducir a demanda no es una puerta. Además, una sola ocurrencia es una señal estadística débil dado el refresco variable y el modo de batería del Steam Deck, ya señalados como fuente de varianza real en este mismo documento.
- [ ] **P2** — DADO un build en hardware real de Steam Deck, CUANDO el jugador presiona el botón de parry, ENTONCES la entrada a estado PARRY se registra en ≤33ms (2 fotogramas a 60fps) y la resolución de un parry exitoso (incluyendo disparo de hitstop) ocurre en ≤50ms (3 fotogramas a 60fps) — umbrales ya definidos en Input Responsiveness — medido con instrumentación de timestamp de input, no solo con percepción del tester.
- [ ] **P3** — Sin valores hardcodeados en la implementación: todos los tuning knobs de la Sección G deben ser configurables externamente. **Incluye explícitamente `postura_base`, `incremento_postura_triada` y `ciclos_objetivo_base`**, que hasta esta revisión aparecían como literales dentro de las Fórmulas 2 y 3. **Excepción declarada**: `physics_ticks_per_second` (60) y `multiplicador_ataque` (1.0) son constantes de proyecto, no knobs — deben ser inalcanzables desde la configuración externa, no configurables.
- [ ] **P4** — DADO un build en hardware real de Steam Deck en **modo portátil/batería**, CUANDO se juega combate continuo en bucle durante **≥20 minutos sin pausas de carga**, ENTONCES la **tendencia** del frame time medio por minuto no muestra degradación monótona: el minuto 20 no excede en más de un 10% al minuto 5, y en ningún minuto se supera 16.6ms de P99.

  > **Por qué P1 no cubre esto** (hallazgo de `performance-analyst`): P1 mide picos instantáneos en 3 duelos consecutivos, pero **este GDD nunca declara cuánto dura un duelo en minutos** — solo cuenta parries (35–40 en tríada alta). Si un duelo dura 2–3 minutos, 3 duelos son 6–9 minutos, probablemente **por debajo** del umbral de throttling térmico del Steam Deck (~10–15 min de carga sostenida). P1 daría un OK falso mientras el juego se degrada a partir del minuto 12 de una sesión real. La duración objetivo de un duelo depende de la cadencia del sistema 20, pero este GDD sí declara su **rango de intención: 2–4 minutos por duelo**, para que P4 y el diseño de patrones se calibren contra la misma cifra.
- [ ] **P5** *(prerrequisito de la producción de audio — equivalente sonoro de P0)* — DADO el hardware de Steam Deck en modo batería, CUANDO se mide el número máximo de voces de audio simultáneas y el coste de mezcla/DSP sostenible, ENTONCES esa cifra queda documentada como presupuesto explícito, y **P5 falla** si el pico ya identificado en este documento (4–6 capas simultáneas en la coincidencia de eventos 4/8/11) no cabe en él. El art bible cubre draw calls, partículas y texturas (8.6–8.7) pero **no audio**, y ningún AC de rendimiento actual lo cubre porque P1/P2 están escritos en términos de frame time y latencia de input. Mismo razonamiento que llevó a crear P0 para partículas.

### Visual / Feel (advisory — evidencia por captura + sign-off nominado)

> **Firmante por AC** (la versión anterior decía "sign-off de lead" sin nombrar cuál, lo que en la práctica produce una puerta advisory que nadie firma): **V1** → `technical-artist`, que es quien implementa el reciclado del pool, con visto bueno de `art-director` como dueño de la regla de oro visual que V1 protege. **V2, V3** → `game-designer`, dueño de la sensación. **V4** → `audio-director`. **V5, V6, V7** → `ux-designer`, que es quien levantó las tres objeciones que verifican, con visto bueno de `audio-director` en V7 por su mitad sonora. Evidencia en `production/qa/evidence/`.

- [ ] **V1** — DADO los eventos 8 (combo completo, esquirlas **hacia el jugador**) y 11 (golpe de castigo, esquirlas **desde el ángel hacia afuera**) disparados simultáneamente mediante el disparador de depuración de P1, CUANDO el pool de emisores recicla, ENTONCES **ningún emisor "hacia el jugador" se trunca a mitad de vuelo a costa de uno "hacia afuera", ni viceversa** — la regla de oro del art bible ("luz hacia el jugador = acierto, luz desde el ángel = daño arrancado") se mantiene legible en el instante de máxima densidad de eventos. Verificado por grabación cuadro a cuadro guardada en `production/qa/evidence/`.

  > Este AC existe porque el propio documento identificó esta clase de bug (sección "Riesgo de presupuesto de partículas") y señaló que **ningún AC de rendimiento la detectaría** — es un fallo de corrección visual, no de frame time. Hasta esta revisión no existía ningún criterio de ningún tipo que lo cubriera.

- [ ] **V2** — DADO un parry resuelto como whiff, CUANDO el jugador lo observa, ENTONCES la Recuperación de whiff se lee como **consecuencia del gesto vacío**, no como pérdida de respuesta del juego. Ningún playtester debe describirla como "se quedó pillado" o "no respondía" (mismo protocolo de muestra que los Feel Acceptance Criteria: N ≥ 10, cuestionario cerrado).

- [ ] **V3** — DADO una pulsación que cae dentro de la ventana de gracia de salida del Aturdimiento (`gracia_salida_castigo`, Regla 5), CUANDO el sistema la reinterpreta como Parry en vez de Golpe de Castigo, ENTONCES la transición de animación (del gesto pesado y comprometido del Castigo al ligero y reactivo del Parry) **no se lee como una respuesta discordante o como un input mal registrado**. Ningún playtester debe describir ese momento como "hizo algo raro" o "no hizo lo que le pedí". Mismo protocolo de muestra que los Feel Acceptance Criteria (N ≥ 10, cuestionario cerrado). La ventana de gracia es forgiveness invisible y estrictamente beneficioso —`ux-designer` la validó como buen diseño en la re-review— pero hasta ahora no tenía ningún criterio que verificara que se *siente* bien, solo que se comporta bien (C11).

- [ ] **V4** — DADO un Parry Justo que además cierra un combo (coincidencia que la Fórmula 1 **garantiza**, no que ocurra por azar), CUANDO ambos disparan su audio, ENTONCES **no suenan dos capas armónicas superpuestas**: se ejecuta el cierre del evento 8 con la variante tímbrica de precisión (ver Regla de precedencia armónica). Un oyente con los ojos cerrados debe poder distinguir "combo cerrado con precisión" de "combo cerrado sin precisión" y de "Parry Justo sobre golpe simple" — tres resultados, tres señales distintas, ninguna enmascarando a otra.

- [ ] **V5** *(**bloqueado** hasta que exista el disparador de depuración de Ventana Especial)* — DADO un jugador que **no ha leído este GDD**, CUANDO se le presentan alternadamente aperturas de `Golpe` (evento 2) y de **Ventana Especial** (evento 14), ENTONCES **acierta cuál es cuál a partir de la apertura sola**, antes de que la ventana se cierre y sin que se le explique la diferencia. Mismo protocolo de muestra que los Feel Acceptance Criteria (N ≥ 10).

  > **Es el AC del que depende que el dilema exista jugablemente.** El ítem 0 estableció que parar o ignorar una Ventana Especial es una **elección real** con monedas opuestas. Una elección que el jugador no puede *ver* que se le está ofreciendo no es una elección: si la apertura de la VE se confunde con la de un `Golpe`, el jugador parea por reflejo —correcto ante un `Golpe`, obligatorio incluso— y nunca llega a decidir nada. Toda la economía de riesgo de R9a descansa sobre esta legibilidad, y hasta el changeset 2 ítem 3 **la VE no tenía ninguna fila de feedback propia** en la tabla de eventos: era una ventana parable de primera clase, invisible.

- [ ] **V6** *(**bloqueado** hasta que exista el disparador de depuración de Ventana Especial)* — DADO un parry exitoso contra una **Ventana Especial**, CUANDO el jugador observa el HUD, ENTONCES lee la firma **"el medidor de Gracia se mueve y la barra de Postura no"** como **consecuencia intencional** y no como un fallo. **Ningún playtester debe describir ese momento como "no me contó el golpe", "la barra se quedó pegada" o "creo que es un bug"** (protocolo N ≥ 10, cuestionario cerrado).

  > **Es la objeción textual de `ux-designer` a la opción C —*"una barra que no se mueve se lee como bug"*— convertida en criterio.** La respuesta de la opción C no fue añadir un efecto que rellenara el hueco, sino apoyarse en que **la ausencia de daño de Postura ya viene acompañada de una presencia**: la Gracia sí se mueve. Eso convierte el hueco en una **lectura** —"esto te da gracia, no progreso"—, que es exactamente lo que la Regla 4 dice mecánicamente. Verificado en positivo por **C20**, que exige que la Postura quede numéricamente idéntica; V6 verifica que además **se entienda**.

- [ ] **V7** *(**bloqueado** hasta que exista el disparador de depuración de Ventana Especial; **cruza al sistema 2**)* — DADO una **Ventana Especial** que vence sin ser parada, CUANDO se observan sus **dos instantes** —el cierre de la ventana (evento 16, este GDD) y la completación de la `Acción Especial` (feedback propiedad del sistema 2)— ENTONCES **se leen como dos sucesos distintos**, y el primero **no se lee como "te has librado"**: debe comunicar compromiso, que la habilidad va a completarse. Un oyente con los ojos cerrados debe distinguir los dos cues.

  > **El riesgo que mide es específico y contraintuitivo**: el cierre de la ventana **no cambia nada** (C21, C22) y por tanto es el candidato perfecto a leerse como alivio — justo antes del único instante en el que el jugador paga. Si el cierre se lee como "no pasó nada", el coste llega sin causa percibida y la elección que R9a construye se vuelve invisible en el momento en que se cobra. Este GDD declara la restricción aunque no posea la mitad del sistema 2, por la misma razón que declara la Regla de precedencia armónica: **es quien crea la coincidencia**.

### Gaps de testabilidad identificados (no bloquean implementación, sí requieren resolución)

1. ~~**`calidad_timing` no es verificable manualmente.**~~ — **cerrado el 2026-08-04
   (changeset 2 ítem 1)**. El gap era real pero su causa no era la instrumentación:
   era que la fórmula se había escrito como **continua** sobre una medida que la Regla 2
   solo permite tomar **en ticks enteros**. Al declararla escalonada (7 valores, tabla en
   la Fórmula 1), el test deja de necesitar resolución sub-100ms: se inyecta la pulsación
   en un tick conocido y se compara contra la tabla de **D1**. Sigue siendo un test
   automatizado con inputs simulados —un tester humano sigue sin poder confirmar "0.7 de
   calidad" a ojo—, pero es un test unitario ordinario, no instrumentación de precisión.
   **D14** añade la guarda de que ningún valor intermedio sea alcanzable, que es lo que
   detecta una implementación por reloj real.
2. **Falta criterio de tasa de éxito con cadencia variable.** El 72% se midió con un
   único enemigo de cadencia fija. Hay que especificar el rango objetivo 65–80% como
   criterio medible por muestreo estadístico, y definir el tamaño de muestra válido.
   → Pendiente para el GDD de IA de Combate de Jefes (sistema 20).
3. ~~**`multiplicador_ataque` no tiene fórmula ni tabla de valores**~~ — **resuelto
   por vía distinta (2026-08-01)**: al fijarse `multiplicador_ataque` como la
   constante 1.0 (R4, cerrada en ambos sentidos tras la re-review), el caso base **es**
   literalmente el único caso legal, así que D6 pasa a ser
   plenamente testable y D8 verifica el techo. Lo que queda abierto no es un gap de
   testabilidad sino una pregunta de diseño para el sistema 9 (¿qué palanca usan las
   reliquias en su lugar?) — ver Open Questions.
4. ~~Duración de la ventana de Castigo no definida~~ — **resuelto**: `ventana_castigo
   = 2.0s`, añadido a Reglas Núcleo (C5) y Tuning Knobs.
5. **Los 7 ítems de "Feel Acceptance Criteria" no tienen protocolo de muestra
   definido**, no solo el de tasa de acierto (65-80%). "Ningún playtester
   describe el parry como aleatorio..." es trivialmente cierto con N=0.
   **Protocolo mínimo antes del primer playtest**: N ≥ 10 playtesters sin
   exposición previa, 5 minutos de práctica libre contra un ángel de Humanidad
   de cadencia fija, cuestionario cerrado (Likert) post-sesión para los ítems
   subjetivos; el ítem de latencia debe usar como proxy objetivo los umbrales ya
   definidos en P2 (33ms/50ms) en vez de "imperceptible" sin métrica. Señalado
   por revisión adversarial (`qa-lead`).
   **Ampliación (re-review)**: el protocolo Likert cubre los ítems de autorreporte,
   pero **no** el primero, que exige conducta espontánea no señalada ("responden al
   telegrafiado intentando el parry"). Preguntarlo después no mide lo mismo que
   observarlo. El protocolo debe añadir un **componente observacional**: grabación de
   sesión + tagging de la respuesta al telegrafiado (parry vs. movimiento) sobre los
   primeros 5 minutos de cada sujeto.
6. **El coste de draw calls por emisor `GPUParticles2D` es desconocido** — los draw
   calls escalan por batching de material/textura, no por número de partículas, así
   que el peor caso de 3 emisores simultáneos podría costar 3 o bastantes más.
   Mientras esa cifra no exista, **P1 no es una puerta de rendimiento fiable**;
   formalizado como prerrequisito P0. Señalado por `performance-analyst`.
   **Corrección de la re-review**: además, P0 contrastaba contra el presupuesto
   equivocado —el techo global de <1000— cuando el art bible 8.6 ya fija el pico de
   combate en 40–80 con el desglose repartido, dejando **~20 draw calls reales para
   VFX**. Era una puerta que pasaba siempre. P0 tiene ahora condición de fallo
   explícita contra la cifra correcta.
8. **El presupuesto de voces de audio simultáneas en Steam Deck sigue sin medirse**
   — mismo patrón que el gap 6 aplicado al dominio sonoro, ahora formalizado como
   prerrequisito **P5**. Señalado por `audio-director` y `performance-analyst` desde
   ángulos distintos.
9. **No existe ningún contrato declarado con un sistema de tutorial/onboarding**,
   pese a que este es el primer verbo que aprende todo jugador y a que un único botón
   cambia de significado según un estado interno invisible (Parry / Golpe de Castigo /
   descartado). El documento declara contratos por anticipado con cinco sistemas no
   escritos, pero no con éste. Señalado por `ux-designer` y `game-designer`. Ver Open
   Questions.
7. **La distinción perceptual entre Parry Justo y parry normal descansa hoy en tres
   canales todos débiles**: +1–2 fotogramas de hitstop, un micro-desplazamiento de
   color hacia `#FFF8E7`, y una capa armónica añadida. `ux-designer` argumentó que
   los tres están cerca o por debajo del umbral perceptual; `creative-director`
   discrepó sobre el hitstop (+20–40% de duración sobre 4.8 fotogramas, por encima
   del JND típico del 10–15%, y el cese de movimiento es señal fuerte). **La
   discrepancia no se resuelve en papel** — es exactamente lo que mide el Feel AC
   "los playtesters distinguen un Parry Justo sin que se les explique". Si ese AC
   falla en el primer playtest, la causa raíz ya está diagnosticada y la palanca
   recomendada es háptica antes que visual o sonora (ver Open Questions).

## Open Questions

| Pregunta | Propietario | Resolución objetivo | Estado |
|---|---|---|---|
| ¿Cuál es la secuencia completa de muerte/game over? (transición de pantalla, qué persiste entre runs) | GDD de Gestión de Run (sistema 3) | Al autorar sistema 3 | Abierta — este GDD define la Vida como recurso pero no el flujo de derrota |
| ¿Cuánta gracia exactamente concede un parry (`gracia_base`)? | GDD de Sistema de Gracia (sistema 5) | Al autorar sistema 5 | Abierta — este GDD solo define el modulador de combo (0.5×) |
| ¿Es correcto `bono_vida_por_absorcion = 18`, o rompe el dilema moral? | Playtesting | Tras el slice vertical | Abierta — señalado como el knob más delicado del sistema |
| ~~¿Cómo se instrumenta el test de `calidad_timing` (sub-100ms)?~~ | ~~qa-lead / test-setup~~ | — | **RESUELTA por vía distinta (changeset 2 ítem 1)**: `calidad_timing` dejó de ser una cantidad continua sub-100ms y pasó a ser un **conjunto cerrado de 7 escalones indexados por `Δ` en ticks enteros**. Ya no hace falta medir décimas de milisegundo: basta inyectar la pulsación en un tick conocido y comparar contra la tabla de **D1**. Lo que queda es un test unitario ordinario con inputs simulados, no instrumentación de precisión. **D14** cubre además que ningún valor intermedio sea alcanzable |
| ¿Cuál es la tasa de acierto objetivo con cadencia **variable** (no fija)? | GDD de IA de Combate de Jefes (sistema 20) | Al autorar sistema 20 | Abierta — el 72% se midió con cadencia fija; falta definir muestreo estadístico |
| Dado que `multiplicador_ataque` es ahora la **constante 1.0** (R4, cerrada en ambos sentidos), **¿en qué dimensión expresan su poder las reliquias de "daño"?** | GDD de Elección de Reliquias (sistema 9) | Al autorar sistema 9 | Abierta — **reformulada dos veces**. En la revisión de 2026-08-01 pasó de "¿qué tabla de valores?" a "¿qué palanca?"; en la re-review el techo se cerró también por abajo, así que las reliquias no pueden tocar el daño **en absoluto**. Vías que este GDD sí soporta: `bono_reliquias` sobre Vida máxima (F5), utilidad, o modificadores de ventana — **estos últimos sujetos a R6 y verificados por el AC D10**, no libres. **Acotada definitivamente el 2026-08-04 (changeset 2 ítem 2)**: la pregunta ya no es "qué palanca" sino "dentro de qué presupuesto", y el presupuesto está declarado — hasta **+25 de Vida** o **−20% de daño recibido** (no ambos), modificadores de ventana bajo R10d, y utilidad pura; la forma **ofensiva** del duelo queda cerrada por completo (R10b/R10c). Lo que sigue abierto es puramente el **contenido** de las reliquias, que sí es del sistema 9 |
| ¿Cuál es la **prioridad de reciclado del pool de emisores** por dirección semántica del efecto (hacia el jugador vs. hacia afuera), y cómo se asignan los 3 emisores del presupuesto? | `technical-artist` | Antes de implementar VFX de combate | Abierta — la sección "Riesgo de presupuesto de partículas" remitía a esta tabla desde 2026-07-31, **pero la fila nunca se creó** (referencia colgante detectada en la revisión de 2026-08-01). Cubierta ahora por el AC V1 |
| ~~¿Cuál es la **longitud máxima de combo** (N golpes)?~~ | ~~Sistema 20~~ → **este GDD** | — | **RESUELTA (re-review 2026-08-01)**. Esperar al sistema 20 bloqueaba al sistema 16, que es igual de MVP. Se aplica el mismo patrón que R4: este GDD no posee los patrones pero sí las dos invariantes que se romperían. **Decisión de usuario: `3 ≤ N ≤ 5`** — suelo por la Fórmula 7 (R7), techo por la frase musical ascendente y el presupuesto de partículas. Ver Regla 9 |
| ¿Suena también el golpe sordo del evento 5 cuando un combo se rompe a mitad (evento 9)? Mecánicamente es el mismo suceso físico, pero el evento 9 solo especifica el cristal disolviéndose | Feedback Sonoro del Parry (sistema 16) | Al autorar sistema 16 | Abierta — señalada por revisión adversarial (`audio-director`). Si **no** suena, el combo roto pierde la consecuencia física que lo distingue de un whiff; si **sí** suena, se apilan 2 capas de prioridad Alta en el camino de fallo — espejo del problema ya conocido en el camino de éxito |
| ¿El compositing de corrupción vive como nodo dedicado o recurso de datos? | `/create-architecture` | Fase de Arquitectura | Abierta — heredada del art bible 8.10 |
| ¿Debe absorber tener algún coste **in-combat** (no solo narrativo/diferido), para que el dilema "soy hábil / me estoy destruyendo" se sienta duelo a duelo y no solo al final? La palanca de supervivencia (Vida Máxima, F5) vive en este GDD; el coste narrativo vive en Gracia | Co-propiedad: este GDD + GDD de Sistema de Gracia (sistema 5) | Antes de cerrar el GDD de Gracia | Abierta — señalada por revisión adversarial (`game-designer`), validada por `creative-director` como el único problema de diseño real (no de precisión) de este documento |
| ~~¿La cadencia de ataque puede ser suficientemente variable como para que "machacar el botón de parry a ritmo fijo" deje de ser una estrategia viable de supervivencia?~~ | ~~Sistema 20~~ → **este GDD** | — | **RESUELTA (revisión 2026-08-01)**. La adjudicación previa era incorrecta: con 81–87% de cobertura temporal el mash es imbatible por **cualquier** cadencia — es aritmética, no diseño de IA, y por tanto no era diferible. Resuelto aquí con `recuperacion_whiff` (Regla 7) + invariante **R6** + ACs **C12a/C12b**. **Matiz de la re-review**: el sistema 20 no hereda el problema del mash *en estado estacionario*, pero sí hereda la exigencia de **varianza de separación intra-combo**, porque dentro de una cadena de aciertos la cobertura sube legítimamente al ~84% y ahí la aritmética ya no basta |
| ¿Qué arquitectura de prioridad/ducking de audio resuelve la columna "Prioridad" de la tabla de eventos (11 de 14 filas en "Alta" no clasifica nada), y cómo se mezcla el pico de 4–6 capas simultáneas? | Feedback Sonoro del Parry (sistema 16) | Al autorar sistema 16 | Abierta — señalada por `audio-director` en ambas pasadas. **Acotada en la re-review**: el caso concreto del apilamiento Parry Justo + cierre de combo ya **no** es parte de esta pregunta — lo resuelve la Regla de precedencia armónica de este GDD (AC V4), porque es este documento quien garantiza la coincidencia. Lo que queda para el sistema 16 es la arquitectura general de buses y ducking, con el presupuesto de P5 como techo |
| ¿Cuál es el presupuesto de voces de audio simultáneas en Steam Deck? El art bible cubre draw calls/partículas/texturas (8.6-8.7) pero no audio | `technical-director` / `audio-director` / art bible | Antes de producción de audio | Abierta, pero **formalizada en la re-review como prerrequisito P5** con condición de fallo propia — mismo tratamiento que P0 recibió para partículas. Señalada por `performance-analyst` y `audio-director` |
| **¿Qué mecanismo concreto implementa la escala de tiempo diegética sin tocar el HUD?** `Engine.time_scale` **queda descartado** — es global y Godot 4.7 no permite eximir subárboles. La vía candidata es un autoload autoritativo de tiempo que exponga un delta escalado consumido solo por gameplay — pero **"consumir el delta" no es un mecanismo único, son cuatro**: (a) los scripts propios multiplican `delta` a mano; (b) `AnimationPlayer`, `Tween` y `GPUParticles2D` tienen su propia `speed_scale` nativa que hay que fijar **por nodo**, no consumen el delta del autoload; (c) `Timer` **no tiene** hook de escala — todo timer de gameplay activo durante hitstop debe sustituirse por un contador de ticks; (d) el uniform `TIME` de shader no se ve afectado por nada de lo anterior, así que cualquier VFX de esquirlas que anime por `TIME` **no respetará el 4%** salvo que se le inyecte un uniform de instancia. Incluye también el stacking de hitstop entre Parry Justo (+1–2 ticks) y cierre de combo. **Ampliaciones de la 3ª pasada** (`godot-specialist`): (e) el autoload de tiempo debe correr con un `process_physics_priority` **menor** que todo nodo de gameplay que consuma su delta escalado en el mismo tick — Godot no garantiza orden de árbol una vez hay prioridades, y equivocarse produce un retardo de 1 tick en el delta escalado justo en los ticks de borde (inicio/fin de hitstop), que es donde importa; (f) el **audio diegético** entra ahora explícitamente en el bucket escalado (Regla 2, regla normativa 2), así que es un consumidor más a resolver; (g) con el suelo de `hitstop_parry` en 3 ticks, fijar `Tween`/`AnimationPlayer` en modo de física **deja de ser opcional** — ver "Sobre R8" | `godot-gdscript-specialist` / `/create-architecture` | **Antes del primer sprint** — es prerrequisito de implementación, no de diseño | Abierta, pero **reformulada y acotada en la re-review**: la Regla 2 fija ahora cuatro reglas normativas verificables (ACs C13/C14) y el documento ya no nombra ninguna API de motor. Lo que queda es puramente arquitectura. `godot-specialist` verificó que la formulación anterior (Regla 2.2 + `Engine.time_scale` global) era **mutuamente contradictoria e inconstruible** |
| **¿Qué mecanismo garantiza que el HUD no pierda transiciones de estado en modo 40Hz?** Con física a 60Hz y render a 40Hz la proporción es 3:2, así que algunos frames renderizados cubren 2 ticks — dos cambios de Postura en ticks consecutivos pueden fundirse en un solo frame, contradiciendo el requisito ya escrito de "cambios de estado crítico en 1–2 fotogramas, sin ease-in". ¿Interpolación visual, cola de eventos, o algo más? | `/create-architecture` + HUD de Combate (13) | Antes del primer sprint | Abierta — señalada por `performance-analyst` en la re-review. También queda documentado que desacoplar **no ahorra CPU** en modo batería: la física sigue pagando 60 ticks por segundo real |
| ¿Dan **3 emisores `GPUParticles2D` margen suficiente** para que la coincidencia de eventos 8+11 no fuerce truncamiento en absoluto? Reiniciar un emisor corta sus partículas vivas y Godot 4.7 no tiene crossfade nativo, así que incluso la política de reciclado semántico trunca si dos efectos de la **misma** dirección se solapan | `technical-artist` | Antes de implementar VFX de combate | Abierta — señalada por `godot-specialist` en la re-review. Si la respuesta es que no, la salida no es una política mejor de reciclado sino **reducir la concurrencia de eventos**. Relacionada con P0 |
| ¿Qué elementos de gameplay animados por `TIME` de shader, `Tween`, `AnimationPlayer` o `Timer` existirán en combate, y cuáles de ellos **deben** congelarse con el hitstop? | `technical-artist` + `/create-architecture` | Antes de implementar hitstop | Abierta — corolario directo de la pregunta anterior. Sin este inventario, el mecanismo de tiempo se implementará cubriendo solo los scripts propios y el resto se descubrirá desincronizado a mitad de sprint |
| **¿Cómo aprende el jugador este sistema?** Un único botón cambia de significado según un estado interno invisible (Parry / Golpe de Castigo / input descartado), y el orden normativo de desambiguación de 3 pasos no es autoevidente. `game-concept.md` declara que los primeros 10 minutos enseñan la mecánica "negándose a admitir otra solución", pero no existe ningún contrato declarado con un sistema de tutorial | `game-designer` + `ux-designer`; posible sistema nuevo en `systems-index.md` | Antes de Pre-Producción | Abierta — señalada por `ux-designer` y `game-designer`. **Restricción que este GDD impone al encuentro tutorial**: su cadencia debe dejar hueco explícito para el ciclo de whiff (`recuperacion_whiff` = 9 ticks) — el jugador que aprende whiffea por diseño, y el encuentro no puede castigar la conducta que él mismo exige |
| ~~El proyecto declara en `technical-preferences.md` que el parry se diseña "primero para stick/gatillos analógicos", pero este GDD lo trata como botón binario digital en todo momento~~ | ~~`game-designer` + `ux-designer` + este GDD~~ | — | **RESUELTA (changeset 2 ítem 1, 2026-08-04, decisión de usuario): el control de parry es DIGITAL**, y `technical-preferences.md` se corrigió en el mismo changeset. Razón: un eje analógico mete la **distancia de recorrido** dentro de `t_press` —habilidad medida por hardware, contra el Pilar 2— y obliga a umbral e histéresis, con lo que "una pulsación" deja de estar bien definido para C10, C17 y la aritmética de **R6**. Normativa en la Regla 2; verificada por el AC **C24**, que además exige que mapear un eje a la acción de parry **falle la validación de bindings al cargar** |
| **¿Expone Godot 4.7 algún timestamp de input con resolución sub-tick, y qué cambió en Input entre 4.6 y 4.7?** `modules/input.md` está verificado contra **4.6** mientras el proyecto fija **4.7**, y la referencia no menciona la palabra `timestamp` en ninguna parte — incluido el cambio incompatible de device IDs que 4.7 sí trae | `/setup-engine` (refresco de `docs/engine-reference/godot/modules/input.md`) | Cuando se refresque la referencia de motor | Abierta — **explícitamente NO es bloqueante de este GDD**. La Regla 2 descarta el sub-tick por dos razones independientes, y la segunda (la cuantización aporta ~3% del ruido total frente a la varianza humana) **se sostiene aunque la API exista**. Se registra para que el refresco de la referencia no se olvide, no para reabrir la decisión |
| ¿Qué respaldo no-cromático/no-temporal necesita el Parry Justo (hoy solo un micro-desplazamiento de color) y los eventos intermedios de combo (hoy solo 1-2 fotogramas de diferencia) para cumplir accesibilidad? Recomendación de `creative-director`: reforzar el canal háptico (hitstop diferencial) antes que visual o sonoro | Accesibilidad (sistema 21) | Al autorar sistema 21 | Abierta — señalada independientemente por `ux-designer` y `audio-director` desde ángulos distintos |
| ¿Cómo se mide la degradación sostenida/térmica en un duelo completo de tríada alta (35-40 parries), no solo picos instantáneos? Riesgo conocido de Steam Deck en modo portátil | `performance-analyst` / `qa-lead` | Antes del primer sprint de implementación | Abierta — señalada por revisión adversarial (`performance-analyst`) |

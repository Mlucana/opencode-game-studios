---
name: feedback-novena-hud-review-gaps
description: Hallazgos abiertos de la revisión adversarial Phase 3b sobre UI Requirements de combate-parry-absorcion.md — pendientes para /ux-design del sistema 13 (HUD de Combate)
metadata:
  type: project
---

Revisión adversarial (2026-07-31) de `design/gdd/combate-parry-absorcion.md`, sección
UI Requirements, contra `technical-preferences.md` y `art-bible.md` §§3.4/3.5/4.5/7.1-7.4.
Ver [[project-novena]] para contexto general del proyecto.

Hallazgos que **/ux-design** (sistema 13, HUD de Combate) debe resolver, no repetir el
análisis:

1. **Conflicto foveal/periferia durante combos**: los combos encadenan golpes
   sin pausa (sin retreat entre ellos) — no hay hueco visual para consultar HUD
   periférico durante esa secuencia. El GDD marca Vida/Postura como "siempre
   visible" pero nunca declara en qué fases del ciclo se espera que el jugador
   realmente las consulte. Falta AC tipo "playtester reporta su Vida aproximada
   tras un combo de 3+ golpes sin pausar".

2. **Densidad de HUD sin wireframe validado a 18px/7"**: 5 elementos (Vida
   jugador, Postura enemiga, Vida enemiga, timer de castigo, medidor de gracia)
   compiten por el espacio periférico que queda tras reservar >15-20% de altura
   al telegrafiado (art bible 3.5) y excluir vocabulario diegético/circular. No
   se ha hecho el ejercicio de encaje geométrico en resolución real de Steam
   Deck. Alto costo si se descubre después de que UI-programmer construya
   layout fijo — hacer wireframe de peor-caso (Aturdido + timer + medidor cerca
   de saturación + Vida baja parpadeando) ANTES de cerrar spec.

3. **"Siempre visible" para Vida/Postura del enemigo es una decisión no
   examinada**, no un hecho dado — el GDD la fija en la columna Condición sin
   considerar divulgación progresiva (ej. ocultar Vida exacta del enemigo hasta
   el primer Golpe de Castigo) como alternativa de Player Fantasy ("arrebatarle
   algo a un ser superior"). Reabrir como pregunta en /ux-design, coordinar con
   game-designer antes de cerrar.

4. **Gancho de accesibilidad único (`parry_window`) insuficiente**: el sistema
   depende fuertemente de diferenciación solo-color (evento 4, Parry Justo:
   micro-variante `#FFF8E7` sin respaldo de forma, a diferencia del medidor de
   gracia que SÍ tiene respaldo obligatorio por art-bible 7.3) y solo-timing
   (1-2 fotogramas de diferencia entre eventos 7/8). También falta respaldo
   para jugadores sin audio (el "tick" de apertura de ventana es la única
   calibración auditiva) y no hay cross-reference de accesibilidad hacia la
   duración del Telegrafiado (owned por sistema 20, IA de Jefes) como palanca
   complementaria a `parry_window`. **Riesgo de costo alto**: Accesibilidad
   (sistema 21) vive en capa Pulido/Alpha, después de que MVP ya implemente
   shaders/partículas — si el respaldo de forma no se construye desde el shader
   inicial, el retrofit es caro.

**Por qué importa**: estos son gaps de secuenciación — el GDD delega
correctamente la spec completa a `/ux-design`, pero ya fija suficientes
decisiones vinculantes (siempre-visible, densidad implícita, único gancho de
accesibilidad) como para que el futuro spec de UX las herede sin cuestionarlas
si no se marcan explícitamente como abiertas.

**Cómo aplicar**: al ejecutar `/ux-design` para system 13 (HUD de Combate) o al
revisar el futuro GDD de Accesibilidad (sistema 21) o IA de Combate de Jefes
(sistema 20), verificar estos 4 puntos antes de darlos por resueltos.

### Hallazgos añadidos en re-review 2026-08-01 (tras `recuperacion_whiff=9`, `gracia_salida_castigo=6`, orden de desambiguación de 3 pasos)

5. **Input machacado durante Recuperación de whiff no tiene NINGÚN feedback**:
   la Edge Case dice que la pulsación "se descarta por completo... no se
   almacena en buffer ni se ejecuta al terminar", pero no especifica ninguna
   señal (visual/sonora/háptica) que distinga "no presioné" de "presioné y fue
   rechazado". El primer whiff sí tiene señal (la animación de gesto vacío,
   evento 6), pero las pulsaciones repetidas dentro de esos 9 fotogramas caen
   en silencio total — exactamente para la población de jugadores que
   machacan, a quienes el mecanismo pretende enseñar a leer el patrón en vez
   de mashear. Riesgo de que se lea como "el juego no responde" (justo lo que
   el AC V2 prohíbe). `/ux-design` debe decidir una señal de "rechazado"
   mínima (p. ej. un tono seco distinto, sin luz) para el segundo+ intento
   dentro del lockout.
6. **`recuperacion_whiff` no está declarado como knob expuesto a Accesibilidad
   (sistema 21)** — la sección Interactions solo nombra `parry_window`. Este
   nuevo coste temporal (introducido en la re-review para cerrar el agujero
   de mash) penaliza también, sin distinción, a jugadores con dificultades
   motoras/de reacción que fallan la ventana por motivos legítimos, no por
   mashear. Añadir `recuperacion_whiff` como segundo knob accesible antes de
   que Accesibilidad (21) se autore, o el gap queda heredado silenciosamente.
7. **Ventana de gracia de salida (6 fotogramas) es invisible pero, a
   diferencia de la Recuperación de whiff, esto se evalúa como diseño
   correcto** (mismo principio que el perdón de anticipación de la Regla 3:
   forgiveness invisible que es siempre estrictamente beneficioso no necesita
   ser percibido). Gap real: no existe un AC de Feel/Visual paralelo a V2 que
   verifique que el cambio de animación (Castigo pesado comprometido ↔ Parry
   ligero) no se lea como una respuesta inesperada/discordante cuando el
   input cae dentro de la ventana de gracia. Añadir ese AC antes de cerrar el
   spec de combate.
8. **Discrepancia analógico/digital escalada a bloqueante para `/ux-design`**:
   la Open Question del GDD la trataba como "discrepancia de terminología, no
   de diseño". Con el nuevo orden normativo de desambiguación de 3 pasos y el
   descarte sin buffer de la Recuperación de whiff, el modelo asume un flanco
   digital limpio. Si el input real es gatillo analógico (como pide
   `technical-preferences.md`), hace falta definir umbral/histéresis de
   pulsación antes de escribir la spec de interacción — el ruido analógico
   cerca del umbral durante un lockout de 9 fotogramas podría generar
   descartes invisibles para el jugador que un botón digital no produciría.
   No escribir la sección de Interaction Design de `/ux-design` para el
   combate sin que esto se resuelva primero.

**Onboarding (nota aparte, no específica de HUD)**: el GDD no declara ningún
contrato con un sistema de tutorial/onboarding pese a ser el primer verbo
central que todo jugador aprende, con un único botón que cambia de
significado (Parry / Golpe de Castigo / descartado) según un estado interno
invisible. Inconsistente con el propio patrón del GDD de declarar contratos
por anticipado a sistemas no escritos (gracia, reliquias, IA de jefes,
gestión de run). Señalar en la próxima revisión del GDD o al autorar el
sistema de onboarding.

### Hallazgos añadidos en la revisión adversarial 2026-08-04 (tras enmiendas A-G forzadas desde el sistema 2, aprobación retirada)

9. **Ventana Especial parada es visualmente indistinguible de un parry normal
   — gap de Player Fantasy, no solo de HUD**: la Regla 4 (excepción) y los ACs
   C20/C21 verifican que el parry exitoso contra una Ventana Especial aplica
   Gracia completa + hitstop pero **ni** daño de Postura **ni** Repliegue. La
   tabla de eventos Visual/Audio (event 3, "Parry exitoso") no tiene una
   variante ni una fila dedicada para este caso — mecánicamente los dos
   eventos que sí se disparan (Gracia, hitstop) son los mismos que en un
   parry contra `Golpe`. Ningún AC de Feel/Visual (V1-V4) ni Open Question
   cubre la legibilidad perceptual de este caso — a diferencia de Parry Justo
   (gap 7, con Open Question dedicada) y de la ventana de gracia de salida
   (V3). El Player Fantasy del documento declara explícitamente que "cada
   acierto tiene un segundo significado no deseado" (soy hábil / me estoy
   destruyendo) como "la fantasía completa, no un efecto secundario" — si el
   jugador no puede notar en el momento que acaba de alimentar el lado
   "corrupción" sin ganancia táctica (la barra de Postura del jefe no se
   mueve), el diseño no comunica exactamente el momento que más le importa
   comunicar. Falta: (a) una fila de evento dedicada en Visual/Audio
   Requirements, (b) un AC tipo V5 que verifique que los playtesters
   distinguen "parreé una Ventana Especial" de "parreé un Golpe normal" sin
   que se les explique, (c) una entrada en Open Questions si se prefiere
   diferir el diseño concreto a `/ux-design` (sistema 13) o a Feedback de
   Impacto (sistema 4). Marcado como **bloqueante** en la revisión de
   2026-08-04 por afectar directamente al Player Fantasy raíz del documento,
   no solo a la legibilidad de HUD.
10. **El fix croma-vs-luminancia se aplicó solo al temporizador de castigo,
    nunca generalizado como regla** (UI Requirements, tabla de Información):
    la fila de Vida del jugador usa el mismo patrón de riesgo ("gris frío",
    descriptor de matiz/croma) y el medidor de Gracia/corrupción es
    explícitamente **rico en croma** (única licencia de vocabulario vitral en
    el HUD) y vive en la esquina periférica — exactamente la combinación
    (bajo croma o iconografía cromática + posición periférica) que motivó el
    fix del temporizador. Ninguna de las dos filas tiene un requisito de
    contraste de luminancia explícito como sí lo tiene ahora el temporizador.
    Recomendado (no bloqueante, porque el detalle de color se defiere
    formalmente a `/ux-design`): reescribir el hallazgo como regla general de
    UI Requirements ("todo elemento periférico debe declarar su respaldo de
    luminancia, no solo de croma") en vez de como nota puntual sobre una sola
    fila, para que `/ux-design` (sistema 13) no la aplique solo donde ya está
    escrita literalmente.

**Nota de proceso (2026-08-04)**: en esta misma pasada se escaló a
**bloqueante** la Open Question analógico/digital (última fila de la tabla),
con el argumento de que varios ACs ya escritos (C2, C10, C17, C18) asumen un
flanco digital limpio y no pueden verificarse de forma estable si la
resolución final introduce un umbral/histéresis distinto al que esos ACs ya
codifican con cifras exactas (13, 9, 114/115 ticks). Ver detalle en el informe
de revisión de esa fecha si se necesita el razonamiento completo — no
duplicado aquí porque es específico de esa pasada, no un gap estructural
nuevo del HUD.

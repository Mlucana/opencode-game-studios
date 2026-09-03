# Concepto de Juego: NOVENA

*Creado: 2026-07-30*
*Estado: Borrador*

---

## Elevator Pitch

> Es un roguelike de duelos donde paras los ataques de los ángeles para robarles
> su poder — y cada fragmento de gracia robada te va convirtiendo en aquello que
> has venido a destruir.

Una novena es la oración de nueve días que se reza por un enfermo o un difunto.
Este juego son nueve coros angelicales. El título es la premisa: un demonio
rezando de la única forma que sabe, matando.

---

## Core Identity

| Aspecto | Detalle |
| ---- | ---- |
| **Género** | Roguelike de acción 2D / boss-rush de precisión |
| **Plataforma** | PC (Steam), con objetivo de verificación en Steam Deck |
| **Público objetivo** | Ver sección *Perfil del Jugador Objetivo* |
| **Número de jugadores** | Un jugador |
| **Duración de sesión** | 30–45 minutos por run |
| **Monetización** | Premium (pago único) |
| **Alcance estimado** | Grande — visión completa multi-año en solitario; versión 1.0 de 3 ángeles en 5–7 meses |
| **Títulos comparables** | Furi, Blasphemous, Sekiro (feel de combate), Hades (estructura de run) |

---

## Core Fantasy

Ser lo bastante preciso como para arrebatarle el poder a un ser superior, y lo
bastante terco como para soportar lo que ese poder te hace por dentro.

El jugador es un demonio que perdió a su esposa y a su hija por culpa de su
propia naturaleza corruptora: todo lo que ama se marchita a su alrededor. Guiado
por falsas promesas de demonios superiores, emprende una cruzada contra el Cielo
para recuperarlas.

La promesa emocional no es la venganza ni el poder. Es esta: **querer a alguien
con tanta terquedad que ni el perdón de Dios logre detenerte.** El juego no
ofrece redención como recompensa — la ofrece como *tentación*, y deja que el
jugador la rechace una y otra vez.

---

## Unique Hook

Es como Sekiro, **y además** el parry que te mantiene vivo es también lo que te
condena: cada parada perfecta absorbe la gracia del ángel, y esa benevolencia
robada va transformando físicamente a un demonio que no puede tolerarla.

Por qué el gancho funciona:

- **Se explica en una frase.** "Parar sus ataques te roba su poder, y su poder te
  está borrando."
- **Invierte una convención central del género.** En casi todo roguelike, subir de
  poder es beneficio puro. Aquí, la barra de progresión y la barra de sufrimiento
  son la misma barra.
- **Nace de la ficción, no está atornillada encima.** La corrupción es literalmente
  la maldición del protagonista, la misma que mató a su familia. La mecánica y la
  historia dicen exactamente lo mismo.
- **Jugar bien te condena más rápido.** No hay forma de esquivar la corrupción
  siendo hábil; la habilidad la acelera.

---

## Player Experience Analysis (MDA Framework)

### Estéticas objetivo (lo que el jugador SIENTE)

| Estética | Prioridad | Cómo la entregamos |
| ---- | ---- | ---- |
| **Reto** (superación, maestría) | 1 | Parry de ventana estrecha, duelos de ritmo, castigo alto por fallar. La dificultad se resuelve enseñando a leer al enemigo, nunca subiendo estadísticas |
| **Narrativa** (drama, arco) | 2 | Tragedia de duelo contada en fragmentos entre duelos; el clímax moral de la saturación se repite cada run |
| **Sensación** (placer sensorial) | 3 | Impacto audiovisual del parry en menos de 100 ms; contraste visual entre grabado y vitral |
| **Expresión** (creatividad) | 4 | Configuración de reliquias y decisión de absorber/rechazar por cada ángel |
| **Fantasía** (rol, identidad) | 5 | Encarnar a un monstruo cuya monstruosidad es amor |
| **Descubrimiento** (secretos) | 6 | Descubrir qué arma, sello o libro hiere a cada coro |
| **Sumisión** (relajación) | N/A | Explícitamente fuera de alcance |
| **Compañerismo** (social) | N/A | Sin multijugador (ver anti-pilares) |

### Dinámicas clave (comportamientos emergentes deseados)

- El jugador aprende a **arriesgar parries en vez de esquivar**, aun sabiendo que
  cada acierto lo acerca a la saturación.
- El jugador empieza a **gastar gracia deliberadamente para aliviarse**, no solo
  para atacar — convirtiendo el recurso ofensivo en válvula de escape.
- El jugador desarrolla una postura personal ante el dilema de absorber o rechazar,
  y esa postura se convierte en su estilo de juego.
- El jugador reconoce a los ángeles por su gramática de ataque antes que por su
  silueta.

### Mecánicas centrales (sistemas que construimos)

1. **Combate de parry-absorción.** Parada en ventana estrecha que devuelve el ataque
   y absorbe una mota de gracia. Rotura de compostura y castigo.
2. **Sistema de Gracia de tres capas.** (a) *Elección explícita*: tras vencer a cada
   ángel, absorber su esencia o rechazarla. (b) *Acumulación*: la gracia acumulada
   transforma progresivamente al protagonista durante la run. (c) *Recurso gastable*:
   la gracia se consume para desatar poderes angelicales robados, y gastarla **alivia
   parcialmente** la corrupción — cada absorción deja un poso irreversible, de modo
   que la caída puede frenarse pero nunca detenerse.
3. **Clímax de saturación.** Al llegar al techo de corrupción, el protagonista siente
   el amor de Dios, se perdona y comprende que su esposa —siempre devota— no querría
   esta masacre. El juego ofrece parar: un final real, tranquilo, disponible siempre.
   Continuar exige arrancarse la gracia de encima a un coste permanente.
4. **Elección de reliquias entre duelos.** Tras cada encuentro, el jugador elige una
   reliquia que modula la run (estructura tipo Hades).
5. **Meta-progresión de llaves.** Cada coro solo puede ser derrotado tras descubrir y
   desbloquear el arma, sello o libro específico que lo hiere.

---

## Player Motivation Profile

### Necesidades psicológicas primarias

| Necesidad | Cómo la satisface el juego | Fuerza |
| ---- | ---- | ---- |
| **Autonomía** | Absorber o rechazar es una decisión moral con consecuencia mecánica real, tomada una vez por ángel. La elección de reliquias y la gestión de gracia añaden agencia continua | Central |
| **Competencia** | El parry es habilidad pura: mejora en las manos del jugador, no en la ficha de personaje. El techo de destreza es alto y visible | Central |
| **Relación** | Punto débil estructural de un boss-rush: no hay NPCs ni mundo. El vínculo debe venir enteramente de la esposa y la hija, conocidas solo a través de fragmentos recuperados | De apoyo — requiere atención de diseño explícita |

### Tipos de jugador (taxonomía de Bartle)

- [x] **Conquistadores / Competidores** — Público primario. Buscan dominar un sistema
      exigente. Es el público de Sekiro, Furi, Hollow Knight y Blasphemous.
- [x] **Narradores / Exploradores** — Apelación secundaria. Atraídos por la premisa y la
      iconografía. Se conservan o se pierden según las opciones de accesibilidad.
- [ ] **Logradores de colección** — Apelación marginal vía meta-progresión de llaves.
- [ ] **Socializadores** — Explícitamente fuera de público.

### Diseño de estado de flow

- **Curva de entrada**: los primeros 10 minutos son un único enemigo menor que solo
  puede vencerse parando. El juego enseña la mecánica negándose a admitir otra
  solución.
- **Escalado de dificultad**: cada coro introduce una nueva gramática de ataque, no
  más números. La dificultad crece en legibilidad requerida, no en cifras.
- **Claridad de feedback**: confirmación audiovisual del parry por debajo de 100 ms;
  la corrupción se lee en el propio cuerpo del protagonista sin necesidad de HUD.
- **Recuperación tras el fallo**: reinicio de run rápido (menos de 10 segundos hasta el
  primer duelo). El fallo es educativo: mueres porque leíste mal un patrón concreto,
  y sabes cuál.

---

## Core Loop

### Momento a momento (30 segundos)

Aproximar → leer el patrón del ángel → parar en el instante exacto (cada parry
absorbe una mota de gracia) → romper su compostura → castigar. La gracia entra
sola, sin pedirla, como consecuencia de jugar bien. El jugador decide cuándo
gastarla para desatar poderes angelicales robados, sabiendo que gastar también
lo alivia.

### Corto plazo (5–15 minutos)

Un duelo completo contra un ángel. Al vencer, la decisión explícita: **absorber
su esencia o rechazarla.** Absorber concede su poder y eleva la corrupción de
forma permanente para la run; rechazar mantiene íntegro al protagonista pero lo
deja débil para lo que viene. Después, la elección de reliquia.

### Sesión (30–120 minutos)

Una run es un ascenso por los coros hasta morir, caer o aceptar la paz. Dura
30–45 minutos, con puntos de parada naturales tras cada coro. Una sesión típica
son dos o tres runs.

### Progresión a largo plazo

Entre runs, el jugador descubre y desbloquea el arma, sello o libro específico
que hiere a cada coro superior. No se trata de subir estadísticas: se trata de
adquirir la **llave** que hace posible un encuentro previamente imposible. En
paralelo, se recuperan fragmentos de la vida perdida del protagonista.

### Ganchos de retención

- **Curiosidad**: qué llave abre el siguiente coro; qué fue exactamente de su esposa
  e hija; qué hay al final de la novena.
- **Inversión**: llaves desbloqueadas, fragmentos recuperados, finales vistos.
- **Social**: N/A por diseño.
- **Maestría**: el parry siempre puede ejecutarse mejor; llegar un coro más arriba;
  completar una run rechazando toda absorción.

---

## Jerarquía Celestial y Estructura de Encuentros

### Las tres tríadas y los nueve coros

**Primera Tríada — Cercanía a Dios**

| Coro | Función teológica |
| ---- | ---- |
| **Serafines** | Ángeles de fuego que alaban a Dios |
| **Querubines** | Guardianes de la sabiduría divina |
| **Tronos** | Portadores del juicio y la justicia de Dios |

**Segunda Tríada — Gobierno del Cosmos**

| Coro | Función teológica |
| ---- | ---- |
| **Dominaciones** | Gobiernan y regulan las tareas de los ángeles inferiores |
| **Virtudes** | Mantienen el orden de la naturaleza y realizan milagros |
| **Potestades** | Luchan contra las fuerzas del mal |

**Tercera Tríada — Relación con la Humanidad**

| Coro | Función teológica |
| ---- | ---- |
| **Principados** | Guían a naciones y líderes |
| **Arcángeles** | Mensajeros de grandes misiones divinas |
| **Ángeles** | Protectores y guardianes cercanos a las personas |

### Regla de representante aleatorio

Cada coro cuenta con **varios representantes diseñados**. En cada run, un
representante distinto es seleccionado al azar para defender su coro.

Esta es la fuente principal de rejugabilidad del juego, y lo consigue **sin
añadir un solo sistema nuevo**: la partida cambia porque cambia el oponente, no
porque cambie el nivel. Sustituye por completo a la generación procedural de
mazmorras, que queda excluida por anti-pilar.

Cada representante debe cumplir el pilar 3 — nombre propio, teología propia y
gramática de combate propia. Un representante no es una variante de estadísticas
de otro: es otro personaje.

### Orden de ascenso

El ascenso va de lo humano a lo divino: **Tercera Tríada → Segunda Tríada →
Primera Tríada**. Dentro de la Primera, el orden es **Tronos → Serafines →
Querubines**, situando a los Querubines como noveno y último coro.

Esto se desvía deliberadamente de la jerarquía tradicional, donde los Serafines
ocupan el rango superior. La desviación está justificada: Ezequiel 28 llama a
Lucifer *"querubín protector"*, y este juego toma esa designación de forma
literal.

### Regla de Lucifer

**Lucifer es siempre el representante de los Querubines, y por tanto siempre el
jefe final.** No entra en la rotación aleatoria.

- **Es un antiguo querubín.** Su naturaleza como guardián de lo divino permanece
  intacta pese a su caída — no puede evitar proteger a Dios ante cualquier amenaza,
  aunque sea su antítesis. No defiende el Cielo por lealtad, sino porque su ser no
  le permite otra cosa.
- **Es el espejo del protagonista.** Ambos son demonios encadenados a una naturaleza
  que no eligieron y que actúa contra lo que desean.
- **Es la última puerta antes de la audiencia con Dios.**
- **Te conoce.** A diferencia de los otros ocho coros, Lucifer sabe quién eres, qué
  perdiste y exactamente qué decir para quebrarte. Su combate incorpora un vector de
  ataque psicológico ausente en el resto del juego — el único jefe cuya arma
  principal no es un arma.

> **Nota de diseño**: la presión psicológica de Lucifer debe interactuar con el
> clímax de saturación. Es el único personaje capaz de burlarse de la paz que el
> protagonista estuvo a punto de aceptar.

### Roster candidato

Nombres extraídos de la tradición judeocristiana, **pendientes de confirmación**.
La asignación de un mismo ángel a coros distintos varía según la tradición; eso es
latitud de diseño, no un error a corregir.

| Coro | Representantes candidatos |
| ---- | ---- |
| Ángeles | Fanuel, Chamuel, Adnaquiel |
| Arcángeles | Miguel, Gabriel, Rafael, Raguel |
| Principados | Nisroc, Cerviel, Requel |
| Potestades | Camael, Verchiel, Samael |
| Virtudes | Rafael, Bariel, Peliel |
| Dominaciones | Zadkiel, Hashmal, Muriel |
| Tronos | Ofaniel, Zafkiel, Oriphiel |
| Serafines | Serafiel, Jehoel, Uriel |
| **Querubines** | **Lucifer (fijo, sin rotación)** |

La ambigüedad de Samael —identificado en algunas tradiciones con Satán y en otras
con un ángel de la justicia divina— es una oportunidad narrativa, no un problema.

### Nota de alcance

El roster completo debe **diseñarse en papel**: es barato, es lore, y es lo que
hace que el mundo se sienta habitado. Pero la versión 1.0 **implementa un único
representante por cada coro construido**.

Los representantes adicionales son el eje natural de expansión post-lanzamiento:
añaden partidas nuevas sin exigir sistemas nuevos. Es el tipo de contenido más
eficiente que puede tener un juego con esta estructura.

Aritmética a tener presente: 3 representantes × 9 coros = **27 jefes**. Con 3 jefes
estimados en 5–7 meses, el roster completo es contenido de varios años. Diseñar
todo y construir por capas es la única vía sostenible.

---

## Game Pillars

### Pilar 1: El poder duele

Ninguna ganancia de poder es gratuita: todas cobran algo sobre quién es el
protagonista.

*Test de diseño*: si dudamos entre un objeto que solo mejora y uno que mejora **y**
te cambia, elegimos el segundo.

### Pilar 2: La maestría está en las manos, no en la ficha

La progresión real es la habilidad del jugador leyendo y parando ataques.

*Test de diseño*: si dudamos entre resolver una dificultad subiendo estadísticas o
enseñando al jugador a leer el ataque, enseñamos.

### Pilar 3: Cada enemigo es alguien

No hay relleno. Cada encuentro es un ser con nombre, teología y gramática de
combate propia.

*Test de diseño*: si dudamos entre añadir tres enemigos genéricos o profundizar un
boss existente, profundizamos.

### Pilar 4: El amor por encima de la cruzada

El motor del protagonista nunca es la venganza abstracta ni el poder: es recuperar
a su familia.

*Test de diseño*: si dudamos entre una escena que expande la mitología y una que
expande su duelo, elegimos el duelo.

### Pilar 5: La fe no es el villano

Lo celestial se trata con seriedad y belleza genuinas, nunca con burla. Los ángeles
no son hipócritas: son realmente buenos, y aun así están en tu contra.

*Test de diseño*: si dudamos entre presentar el Cielo como corrupto o como
genuinamente luminoso —y por eso más doloroso de destruir— elegimos lo segundo.

> **Tensión deliberada**: los pilares 4 y 5 se oponen a propósito. Cuanto más bello
> sea el Cielo, más cuesta justificar lo que el jugador está haciendo. Ahí vive el
> juego.

### Anti-Pilares (lo que este juego NO es)

- **NO habrá relleno.** Ni salas ni enemigos genéricos para alargar la duración —
  comprometería el pilar 3 y el alcance real del proyecto.
- **NO se resuelve la dificultad con números.** Nada de escalar estadísticas del
  jugador como respuesta a un encuentro duro — comprometería el pilar 2. *(Las
  opciones de accesibilidad son otra cosa y sí entran.)*
- **NO habrá sátira anticristiana ni estética de provocación fácil** — comprometería
  el pilar 5 y abarataría toda la tragedia.
- **NO habrá mundo abierto ni exploración extensa.** Como mucho un hub mínimo —
  comprometería el pilar 3 y el alcance.
- **NO habrá multijugador ni servicio en vivo.** Este juego termina.

---

## Visual Identity Anchor

**Dirección seleccionada: Tinta y Vitral**

### Regla visual de una línea

El protagonista y su mundo son un **grabado** —tinta, tramado, sin luz propia—;
los ángeles y la gracia son **vitral** —cristal saturado atravesado por luz—. Son
dos lenguajes visuales distintos coexistiendo en la misma pantalla.

### Principios visuales de apoyo

1. **Él pertenece a otro medio.** El protagonista es un dibujo entre luces; nunca
   comparte lenguaje visual con lo divino.
   *Test*: si dudamos si un elemento debe renderizarse como tinta o como cristal,
   preguntamos a quién pertenece — no cómo queda mejor.

2. **Solo lo divino emite luz.** Nada brilla salvo que sea sagrado o sea gracia.
   *Test*: si dudamos si algo debe brillar, no brilla.

3. **Silueta antes que detalle.** La legibilidad del contorno manda sobre la textura,
   porque el combate de precisión exige leer el ataque al instante.
   *Test*: si dudamos entre textura y contorno legible, contorno.

### Filosofía de color

Base de plomo y negro. El color entra únicamente como luz de vitral, y por tanto
solo llega desde lo divino. La corrupción se comunica sin HUD: conforme el
protagonista absorbe gracia, **el color sangra dentro de su silueta de tinta**. Al
saturarse, ya no es un grabado — es una vidriera.

> Esta sección es la semilla del art bible. La decisión de "él es tinta, ellos son
> luz" se toma aquí para que no se pierda entre sesiones.

---

## Inspiration and References

| Referencia | Qué tomamos | Qué hacemos distinto | Por qué importa |
| ---- | ---- | ---- | ---- |
| **Sekiro** | El parry como verbo central; duelos de ritmo con ventana estrecha y castigo alto | El parry no solo defiende: absorbe, y lo absorbido te daña a largo plazo | Valida que un público grande paga por combate de precisión sin concesiones |
| **The Binding of Isaac** | Transformaciones acumulativas que alteran el personaje durante la run; iconografía religiosa oscura | Las transformaciones no son recompensa: son deterioro elegido | Valida que la acumulación transformadora es adictiva; es el juego más jugado del autor |
| **Black Myth: Wukong** | Espectáculo de jefes mitológicos; absorber poderes de los enemigos derrotados | Absorber tiene un coste moral y mecánico, no solo un beneficio | Valida el apetito de mercado por panteones mitológicos como roster de bosses |
| **Furi / Titan Souls** | Estructura de boss-rush sin relleno | Añadimos elección de reliquias y meta-progresión de llaves entre duelos | Valida que un juego puede ser solo jefes y sostenerse |
| **Hades** | Elección de bendición entre encuentros; narrativa dosificada a través de runs repetidas | Nuestra elección entre encuentros es moral, no solo táctica | Valida la estructura run + elección + narrativa incremental |
| **Blasphemous** | Identidad católica tomada en serio; ancla emocional de la muerte del Penitente | Estética de grabado y vitral en vez de pixel art barroco | Ancla emocional declarada del autor |

**Inspiraciones fuera del medio**: los grabados bíblicos de Gustave Doré (que
ilustró también *El paraíso perdido*); la vidriera gótica y su uso de la luz como
teología; la iconografía de la Novena y las oraciones por los difuntos; la figura
del duelo imposible en la tragedia clásica.

---

## Target Player Profile

| Atributo | Detalle |
| ---- | ---- |
| **Rango de edad** | 20–40 |
| **Experiencia de juego** | Mid-core a hardcore |
| **Disponibilidad de tiempo** | Sesiones de 45–90 minutos, entre semana por la noche |
| **Plataforma preferida** | PC (Steam), con creciente peso de Steam Deck |
| **Juegos que juegan ahora** | Sekiro, Hollow Knight, Blasphemous, Hades, Furi |
| **Qué buscan** | Un sistema de combate exigente con un techo de destreza alto, envuelto en una historia que pese de verdad y que no se disculpe por ser oscura |
| **Qué los ahuyentaría** | Combate impreciso o con input lag; dificultad resuelta con estadísticas; ambientación gótica genérica sin identidad; sistemas ilegibles |

**Para quién NO es este juego**: jugadores casuales; quien busca relajarse; quien
quiere exploración o mundo abierto; quien rechaza la iconografía religiosa usada
con seriedad. Ninguno de estos grupos debe influir en una sola decisión de diseño.

---

## Technical Considerations

| Consideración | Evaluación |
| ---- | ---- |
| **Motor recomendado** | Godot 4.6 — confirmado. Excelente para 2D, ligero, adecuado para desarrollo en solitario y primer proyecto. Exporta limpiamente a PC y Steam Deck (Linux) |
| **Retos técnicos clave** | El *feel* del parry: frame data limpia, buffer de input, cancelación de animación y confirmación audiovisual por debajo de 100 ms. Máquinas de estado de jefes con patrones legibles y deterministas. Sistema de Gracia de tres capas sin ambigüedad de estado |
| **Estilo de arte** | 2D — grabado monocromo (protagonista y mundo) contrastado con vitral saturado (ángeles y gracia) |
| **Complejidad del pipeline de arte** | Media — 2D custom, pero deliberadamente elegido por su bajo coste: el grabado se produce rápido y el vitral son formas planas con luz, sin texturas complejas |
| **Necesidades de audio** | Moderadas a altas. El audio es co-responsable del *feel* del parry. Coral/sacro para lo angelical; silencio y materia para lo demoníaco |
| **Networking** | Ninguno |
| **Volumen de contenido (v1.0)** | 3 coros con un representante implementado cada uno, ~12 reliquias, 1 final completo, 4–6 horas hasta el crédito. Roster completo diseñado en papel |
| **Eje de expansión** | Representantes adicionales por coro. Añaden rejugabilidad sin exigir sistemas nuevos — el contenido post-lanzamiento más eficiente para esta estructura |
| **Sistemas procedurales** | Mínimos. La selección del representante de cada coro y la oferta de reliquias se aleatorizan; no hay generación procedural de niveles |

> **Aviso de versión de motor**: el conocimiento del modelo cubre Godot hasta ~4.3.
> Las versiones 4.4, 4.5 y 4.6 introdujeron cambios relevantes. Ejecutar
> `/setup-engine` para poblar la documentación de referencia antes de escribir código.

---

## Risks and Open Questions

### Riesgos de diseño

- **Las tres capas de gracia pueden volverse ilegibles.** Elección explícita +
  acumulación + recurso gastable son tres sistemas superpuestos. El riesgo no es que
  sea injusto, sino que el jugador no entienda qué le está pasando. *Es la mayor deuda
  de diseño pendiente del proyecto.*
- **La relación afectiva es estructuralmente débil.** Un boss-rush no tiene mundo ni
  NPCs; el vínculo con la esposa y la hija debe sostenerse solo con fragmentos, y si
  no funciona, el clímax de saturación no significa nada.
- **El bucle puede no sostener runs repetidas** si la variedad entre partidas depende
  demasiado de pocas reliquias.

### Riesgos técnicos

- **El feel del parry es todo o nada.** Si no se siente perfecto, no hay juego. No hay
  sistema secundario que compense.
- **Autoría de jefes.** Máquinas de estado con patrones legibles, telegrafiados y
  justos son difíciles de acertar y exigen mucha iteración.
- **Brecha de conocimiento de Godot 4.6** respecto al corte de entrenamiento del modelo.

### Riesgos de mercado

- **Nicho saturado.** Metroidvania y soulslike gótico es un espacio muy poblado. La
  diferenciación debe venir de la mecánica de gracia, no de la ambientación.
- **La dificultad limita el alcance comercial** por diseño deliberado.

### Riesgos de alcance

- **Cada jefe es caro** en animación, patrones, arte, audio e iteración de balance. Es
  el rubro que se come el calendario.
- **Los 9 coros son visión, no versión 1.0.** Intentar los nueve en el primer ciclo es
  la vía más probable al abandono.
- **Riesgo dominante: es el primer juego del autor.** La mayoría de primeros proyectos
  ambiciosos se abandonan. Mitigación obligatoria: prototipo de un solo jefe antes de
  escribir ningún GDD.

### Preguntas abiertas

- ¿Cuántas motas de gracia por parry, y cuál es el techo de saturación? — Se responde
  con el prototipo.
- ¿Cuánto alivia exactamente gastar gracia, y cuánto poso irreversible deja cada
  absorción? — Se responde con el prototipo.
- ¿El clímax de saturación se ofrece cada run o solo la primera vez? — Requiere
  playtest.
- ¿Cómo se comunica visualmente la corrupción sin HUD y sin ambigüedad? — Se resuelve
  en el art bible.
- ¿Qué pasa realmente en la audiencia con Dios? — Pendiente por decisión del autor;
  la semilla actual es que la esposa está salvada, en el mismo Cielo que él está
  destruyendo.

---

## MVP Definition

**Hipótesis central**: *El duelo de parry-absorción es intrínsecamente divertido, y
la tensión entre acumular gracia y gastarla produce decisiones interesantes.*

**Necesario para el MVP**:

1. Un ángel completo con máquina de estados, patrones legibles y compostura rompible.
2. Combate de parry-absorción con frame data, buffer de input y confirmación
   audiovisual por debajo de 100 ms.
3. El sistema de Gracia de tres capas funcionando: elección explícita, acumulación
   transformadora y gasto con alivio parcial.

**Explícitamente FUERA del MVP**:

- Arte final (arte provisional es suficiente para validar la hipótesis).
- Meta-progresión de armas, sellos y libros.
- Reliquias.
- Contenido narrativo y fragmentos de memoria.
- Cualquier ángel adicional.

### Niveles de alcance

| Nivel | Contenido | Funcionalidades | Tiempo (solo) |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 ángel, arte provisional | Parry-absorción + Gracia de 3 capas | 4–6 semanas |
| **Slice vertical** | 1 ángel con arte final | + ciclo absorber/rechazar, ~5 reliquias, clímax de saturación | +6–8 semanas |
| **Alpha (objetivo 1.0)** | 3 ángeles, uno por jerarquía | + ~12 reliquias, meta-progresión de llaves, 1 final completo | 5–7 meses |
| **Visión completa** | 9 coros, audiencia con Dios | + múltiples finales, arsenal completo, arco narrativo íntegro | Multi-año o con equipo |

---

## Next Steps

- [ ] Ejecutar `/setup-engine` para poblar la documentación de referencia de Godot 4.6
- [ ] Ejecutar `/prototype parry-absorcion` — validar la hipótesis central antes de
      escribir ningún GDD (el paso de mitigación de riesgo más importante del proyecto)
- [ ] Si el prototipo da PROCEED: ejecutar `/art-bible` partiendo del Ancla de
      Identidad Visual *Tinta y Vitral*
- [ ] Validar el concepto con `/design-review design/gdd/game-concept.md`
- [ ] Descomponer en sistemas con `/map-systems`
- [ ] Autorar los GDDs por sistema con `/design-system`
- [ ] Planificar la arquitectura con `/create-architecture`
- [ ] Registrar decisiones con `/architecture-decision (×N)`
- [ ] Ejecutar `/architecture-review` para arrancar el registro de trazabilidad
- [ ] Validar el avance de fase con `/gate-check`

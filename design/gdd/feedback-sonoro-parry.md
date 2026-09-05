# Feedback Sonoro del Parry

> **Status**: **Approved (lean re-review Rev-1 2026-09-05; residuos: ciegas SN-05/06/07/12/13, medición Deck, evento #2, back-links #1/#15)**
> **Author**: usuario + game-designer
> **Last Updated**: 2026-09-05
> **Implements Pillar**: Pilar 2 (La maestría está en las manos, no en la ficha) — y es la voz del Pilar 5 (solo lo divino y la gracia robada suenan cristalino-musicales)

> **Convenciones de lectura.** Este GDD no rediseña nada heredado: todo lo pineado por Combate (1) y Feedback de Impacto (4) aparece marcado como **RESTRICCIÓN HEREDADA** (restricción, no propuesta) con su fuente. Todo valor no decidido aparece como **PROVISIONAL** y cuelga de una Open Question. Las decisiones D-A..D-F adoptadas para este draft son **provisionales y reversibles en review**, y van marcadas como **(PROVISIONAL D-X)** allí donde se aplican.

## Overview

El Feedback Sonoro del Parry es el sistema que hace legible el duelo con los ojos cerrados: cada veredicto del parry (normal, Justo, whiff, fallo, cierre de combo, aborto, castigo, quiebre, expira, muerte y los tres instantes de Ventana Especial) tiene una firma sonora propia y distinguible, consumiendo los veredictos ya resueltos de Combate (1) y los triggers, ventanas de duración, orden de prioridad y oráculos de Feedback de Impacto (4), y poniendo él los medios —timbre, mezcla, armonía, buses, ducking y valores—. Hereda de #4 sus dos tiempos: **juicio** (el transient de entrada dice qué pasó en ≤2 ticks de pared, ≈33.4 ms en dock) y **confirmación** (el sustain dice cuánto valió al cierre del freeze, ≤10 ticks de pared, ≈166.7 ms en dock / ≈250 ms en batería con tolerancia de presentación). Sin él, el parry seguiría resolviéndose pero dos veredictos distintos sonarían igual y la mitad ciega de la legibilidad —la que sostiene al jugador cuando la pantalla ya no se mira— no existiría.

## Player Fantasy

Parar debe **sonar** como lo que es: un **sacramento robado** — cristal que se arranca, nunca campana que celebra. El parry normal es impacto de dos capas (cristalina + cuerpo físico) que dice "lo divino se rompió en tu mano"; el **Parry Justo** es ese mismo impacto al que le **florece** un armónico, como si la luz reconociera la precisión; el **fallo** es tela y carne rasgada, sordo y sin una sola nota musical, porque nada divino ocurrió; el **whiff** es aire que termina de moverse y nada más, porque el mundo ni se enteró; la **VE parada** es percusión cristalina **sin cuerpo** —se arrancó gracia pero no se detuvo ningún golpe—; y el **cierre de VE no parada** queda deliberadamente **irresoluto**, una frase que no cierra porque algo sigue en camino. Solo lo divino y la gracia robada suenan cristalino-musicales —el Pilar 5 en audio—: protagonista, tinta, whiff, fallo, gastos y UI jamás emiten luz sonora. Sirve al Pilar 2 (la destreza se escucha: cada escalón de precisión tiene su diente) y a la estética de Sensación (juicio diferenciado por debajo de 100 ms por el canal del oído, redundante con el visual, nunca dependiente de él).

## Detailed Rules

1. **Alcance y reparto de propiedad (RESTRICCIÓN HEREDADA de #4, Interactions).** Este GDD consume de #4 los triggers, las ventanas de duración, el orden de prioridad (dominancia 11>4>3>8>15, 9 en rango fondo) y los requisitos de discriminabilidad con sus oráculos de stems; **posee** timbre, mezcla, armonía, buses, steals/robos de voz y todos los valores (gains, ms, cutoffs, semitonos, rates). Consume de Combate (1) los veredictos ya resueltos (`parry_resuelto` con resultado y calidad, `combo_abortado` con payload `i/N`) sin redecidirlos jamás: si #1 dice Justo, suena Justo; si #1 dice whiff, suena aire. La completación y la interrupción de la `Acción Especial` son del sistema 2 — este GDD no les pone sonido propio hasta que el sistema 2 declare su evento (ver Regla 9).
2. **Regla de oro sonora (RESTRICCIÓN HEREDADA de #1, Visual/Audio Requirements).** Todo lo que sale bien (parry, Justo, cierre, castigo, VE parada) suena con material **cristalino-musical** —luz que llega o que se arranca—. Todo lo que sale mal (fallo, combo roto, ventana desperdiciada, muerte) suena con **ausencia de ese material**: sordos, aires, disonancias irresolutas, nunca un destello musical nuevo. El whiff es **ausencia total de reacción sonora del mundo**: ni luz, ni golpe, ni capa musical durante el lockout.
3. **Paleta por evento (medios propios; parámetros pineados = RESTRICCIÓN HEREDADA de #1 y #4).**

    | Evento | Firma sonora (QUÉ/CUÁNDO) | Medios de este GDD |
    |---|---|---|
    | 1. Telegrafiado inicia | Tell distintivo **por tríada** (cuerdas/coro = Humanidad, metal/viento = Cosmos, casi inarmónico = Cercanía a Dios) que **crece** con la fisura — segunda vía de lectura del timing | Tónicas por tríada dentro del modo armónico único **(PROVISIONAL D-B)**; swell de intensidad, nunca cambio de set |
    | 2. Ventana de parry se abre | "Tick" seco y corto, distinto del tell — marca el instante exacto de apertura para calibración por oído | Transient seco sin cola musical; el ataque vive dentro del juicio ≤2 ticks |
    | 3. Parry exitoso | Impacto de **dos capas**: cristalina + cuerpo/impacto físico. Nunca un "ding" genérico — sacramento robado | Transient cristalino + cuerpo físico por el bus absorber (Regla 5); segunda prioridad de mezcla |
    | 4. Parry Justo | Capa armónica que **"florece" tras el golpe** — distinguible con los ojos cerrados. Solo como capa independiente sobre **golpe simple**; en coincidencia con 8 rige la Regla 4 | Brillo tímbrico sobre el mismo set, no set nuevo **(PROVISIONAL D-B)**; primera prioridad de mezcla |
    | 5/13. Fallo / golpe / vida baja / muerte | Sordo de **tela/carne rasgada**, sin ningún componente cristalino o musical. Vida baja: latido que se acelera. Muerte: **corte seco** de toda música/ambiente divino + vela apagándose | Sordos + latido; el corte duelo→muerte es por bus en **<20 ms (RESTRICCIÓN HEREDADA de #15)** |
    | 6. Whiff | Hueco y corto (**aire, no contacto**) — nunca comparte capa con el fallo; su ausencia de peso ES el mensaje | Whoosh corporal único, tail ≤ `recuperacion_whiff` (lectura viva de #1); **cero SFX de feedback en lockout (RESTRICCIÓN HEREDADA de #4 R5 + #1 C17)** |
    | 6b. Recuperación de whiff | La **cola del propio gesto** termina de sonar; **ninguna pulsación descartada dispara sonido alguno** | Decay natural del whoosh; prohibido "denied click", ticks o pulsos |
    | 7. Golpe de combo parado (no último) | Cue **ascendente encadenado** (nota que sube respecto al anterior) — nunca el cierre reservado al último | Peldaños dentro del modo único; micro-duración, sin hitstop sonoro propio |
    | 8. Combo completo (último) | **Resolución armónica clara** (el ascendente "cierra" aquí) + sonido de daño de compostura **distinto del de vida** | Cierre del modo; primera prioridad; coexistencia con 4 solo vía Regla 4 |
    | 9. Combo roto a mitad | Cristal **cayendo/disolviéndose** — corto, sin resonancia, anticlimático. **Nunca lleva el thud del 5 (RESTRICCIÓN HEREDADA de #4 R6: el thud significa daño y el 9 no hace daño)** | Peso por gravedad/duración por peldaño `i/N`, dirección tardío-más-grave/largo/pesado **(punto de partida no-normativo D-F; la dirección late=heavier SÍ es normativa heredada de #4 R6)** |
    | 10. Quiebre de compostura | Quiebre **grave y sostenido**, distinto de cualquier impacto puntual — apertura de estado, no un golpe más | Sostenido grave; sin transient de impacto |
    | 11. Golpe de Castigo | Impacto **sólido/percusivo, con menor componente cristalino** — daño bruto, no sacramento; dirección opuesta a 3/4/8 | Bus arrancar (Regla 5); primera prioridad; único con robo de voz compartida (Regla 7) |
    | 12. Ventana expira sin usar | Cue de cierre **suave, disonante o irresoluto — nunca silencio total (RESTRICCIÓN HEREDADA de #1)** | Cierre que no resuelve; sin transient de impacto |
    | 14. VE se abre | **Sostenido, no puntual** — contrapuesto al tick seco del 2; dura mientras la oportunidad dure **(PROVISIONAL D-C: se acepta el sostenido provisional de #4 hasta el evento #2)** | Capa sostenida diferenciada de 3/4/8; **ATAQUE pineado por #4 R5 (ataque −12 dB rel. pico nominal, sin transitorio cristalino crest-bajo, LP 24 dB/oct @800 Hz, ventana de ataque ≤150 ms) + SUSTAIN vivo mientras la ventana siga abierta (mismo nivel −12 dB + LP@800, duración viva de sistema 2, nunca silencio total); al cerrar, tail <−60 dBFS post-150 ms desde el cierre. D-C expira al llegar el evento #2; entonces este perfil queda solo-apertura** |
    | 15. VE parada | **Misma percusión cristalina que 3, sin el cuerpo de impacto físico** — distinguible del 3 con los ojos cerrados. **Nunca la variante Justo ni bono alguno (RESTRICCIÓN HEREDADA de #1 Fórmula 1 / C25: la VE nunca es Justo)** | Mismo set que 4-sin-brillo Justo, sin cuerpo **(PROVISIONAL D-B)**; rango cierre-bajo en ducking |
    | 16. VE se cierra sin parar | **Anti-silencio calcado del 12**: cue breve **irresoluto que no cierra la frase** — debe leerse como "esto ya va a ocurrir", **nunca alivio, nunca silencio total (RESTRICCIÓN HEREDADA de #1). Delta diseñado vs 12 (mismo set, distinto gesto): 12 = cierre-descendente que SELLA (disonante pero concluso, refuerzo al sellar); 16 = cierre-ascendente SUSPENDIDO que no resuelve (tensión pendiente, sin refuerzo). Mismo material, contorno opuesto — por eso la matriz 3-vías SN-09 puede pasar sin material nuevo** | Cierre irresoluto; distinguible de la completación del sistema 2 (Regla 9) |

4. **Precedencia 4-sobre-8 como variante tímbrica, nunca superpuesta (RESTRICCIÓN HEREDADA de #1, Regla de precedencia armónica).** Cuando un Parry Justo coincide con el cierre de combo —coincidencia que la Fórmula 1 de #1 **garantiza**, no azar—, **no suenan dos capas armónicas**: el cierre del 8 se ejecuta con una **variante tímbrica de precisión** (misma frase, mismo punto de resolución, timbre más brillante/cristalino). El "florecimiento" del 4 solo suena como capa independiente sobre golpe simple. Verificación ciega en ACs (tres resultados, tres señales, ninguna enmascarada).
5. **14/15/16 reutilizan material: cero voces nuevas, cero pico nuevo (RESTRICCIÓN HEREDADA de #1, nota P0/P5).** El 14 reutiliza el material del 2 con carácter invertido (sostenido vs tick); el 15 reutiliza la percusión del 3 sin cuerpo; el 16 reutiliza el tratamiento de sellado del 12 (reutiliza set, no gesto: ver delta en tabla fila 16). La `Acción Especial` está **fuera del ciclo** (Regla 4 de #1), así que la capa del 15 **no se suma a ningún pico existente** (4+8, 8+11). Si el sistema 20 declarase una especial solapada con el ciclo, P0/P5 se re-evalúan (gancho heredado).
6. **Buses por dirección + ducking por rango (D-A: propiedad ratificada por ADR-003; valores PROVISIONALES hasta SN-11).** Dos buses de duelo: **absorber-hacia-dentro** (3, 4, 8, 15) y **arrancar-hacia-fuera** (11), espejo de las direcciones inward/outward de #4 R3 —un oyente con los ojos cerrados distingue la polaridad—. El ducking sigue el rango de #4 (11>4>3>8>15, 9 fondo): los sustains duckean bajo los transients de rango superior; **ataque ≤1 tick, profundidad interina −6 dB (RESTRICCIÓN HEREDADA de #4; este GDD solo la estrecha, ver Fórmulas)**. Bus `Hitstop` dedicado en `ALWAYS` para el duck diegético durante el freeze (propiedad cerrada por ADR-003 —dueño único #16 en timbre/mezcla/buses/duck/valores; #4 conserva triggers/ventanas/prioridad/oráculos; interfaz `Hitstop.play` vs bus `Hitstop` per ADR-003—; valores PROVISIONALES hasta SN-11/P5-DEF. Cadena —routing por bus, `ALWAYS`, inventario de emisores UI por bus con cero players directos, lifecycle— ver ADR-003 §§ Decisión/§2/Implementation; F-S2 solo fija `G_duck`/`A`/`R`/rango, no duplica la cadena).
7. **Modo armónico único con tónicas por tríada (PROVISIONAL D-B).** Un solo modo armónico para todo el duelo; cada tríada fija su tónica (Humanidad / Cosmos / Cercanía a Dios, carácter heredado del tell del evento 1). El Justo (4) es **brillo tímbrico** sobre el mismo set —nunca modulación ni set nuevo—; la VE parada (15) usa el **mismo set sin cuerpo**. Así la precedencia 4-sobre-8 (Regla 4) y la distinguibilidad 3-vs-15 ciega se sostienen sin multiplicar material.
8. **Sostenido VE-14 (PROVISIONAL D-C).** Se acepta el sostenido provisional pineado por #4 R5 (parámetros en la tabla, Regla 3) hasta que el sistema 2 declare el evento de completación en su 4ª pasada; entonces se sustituye por fila propia y este perfil pasa a ser solo el de **apertura**. Aclaración: los params #4 R5 cubren el ataque (≤150 ms); el sustain posterior es apertura viva, no completación. Sin esta partición una VE de segundos quedaría muda tras 150 ms.
9. **TOMAR / DEJAR IR / gastos: misma familia sobria, nunca celebración (PROVISIONAL D-D, sobriedad HEREDADA de #5).** TOMAR commitea con sting **grave-resuelto** (`ui_cometer_irrevocable`, familia sobria, no error); DEJAR IR con **variante de resolución sobria, aire-ascendente, nunca en modo menor** (digno, jamás castigo); Purga/Amparo con **transients secos por bus, un click seco por coste** —sin flash nuevo, sin coro, sin "¡NUEVA FORMA!" (prohibición heredada de #5). La saturación no tiene sting propio: es handoff a #6.
10. **Catálogo UI por bus + cama duckeada (RESTRICCIÓN HEREDADA de #15, Interactions).** Este sistema realiza las intenciones `ui_foco, ui_confirmar_neutro, ui_armar_destructivo, ui_cometer_irrevocable, ui_atras, ui_error_bloqueado, ui_error_duelo, ui_exito_migracion_reset, transicion_solicitada` y la cama `ui_vela_loop` (Menú+Hub, **duckeada en duelo**); el menú emite, jamás reproduce directo —aquí se timbra, mezcla y duckea. Corte duelo→muerte **<20 ms por bus** (Regla 3). Buses a medir (7): música, ambiente-divino, SFX-absorber, SFX-arrancar, Hitstop-duck, UI, bed `ui_vela_loop` (crossfade `transicion_solicitada` propiedad #16 per #15 L163). Método: stems por bus pre-master desde `duelo_perdido` (teardown #4 R11 espejo); cada bus <20 ms a silencio salvo vela (único residuo); medir en Deck batería + dock por separado, BT excluido. Cadena/routing/`ALWAYS` ver ADR-003, no se duplica aquí.
11. **Presupuestos interinos + medición en Deck antes del Vertical Slice (PROVISIONAL D-E, interinos HEREDADOS de #4 P5-DEF).** Hasta medición propia: **tails ≤4 simultáneas, voces ≤12, DSP ≤20% en batería**. Antes del Vertical Slice se mide en Deck real (batería, perfil 40 Hz) el peor caso exacto (máx variante intra + tails cross + fragmento de aborto + capa VE + click_gasto legal en duelo —máx 1 Amparo + 1 Purga por ventana, cooldown 360 + cap 2/duelo, gating G7— + HUD + bed) y se pinean `V_max`/`D_max`; este GDD solo puede **estrechar** los interinos, nunca ensancharlos sin la medición.
12. **Escalera `i/N` late=heavier: la dirección es normativa heredada, los valores son punto de partida (D-F).** El mapeo else-if ordenado (temprano si `3i≤N`, medio si `3i≤2N`, resto tardío) y las guardas (`1≤i≤N`, `N∈3..5`; payload corrupto → descarte + log + counter, nunca skip silencioso) son **RESTRICCIÓN HEREDADA de #4 R6**. Como punto de partida **no-normativo**: temprano +0 st seco corto; medio −2 st +20% decay; tardío −5 st con lowpass +40% decay; gains con compensación de loudness + cue redundante de duración. Los valores finales los fija el playtest ciego (OQ).
13. **Transient único intra-dirección; cross-dirección exento (RESTRICCIÓN HEREDADA de #4).** Un solo pico por freeze fusionado intra-dirección —detector heredado: **pico secundario >−6 dB relativo al principal en ventana de 100 ms = FAIL** (oráculo de stems en ACs)—. Cross-dirección (absorber vs arrancar) conserva ambos transients con prueba de legibilidad propia.
14. **Stream Bluetooth excluido de los gates de timing (RESTRICCIÓN HEREDADA de #4 C1).** Toda medición de juicio/onset se hace en altavoces de Deck + salida por cable, runs separadas dock/batería; BT queda fuera con rationale (latencia no acotada), nunca como vía de aprobación.

## Formulas

> Los valores marcados PROVISIONAL son punto de partida medible, no norma: solo se estrechan con medición o escucha ciega (ver OQs). Cadena duck/routing/`ALWAYS`/inventario: ver ADR-003 (propiedad cerrada); aquí solo `G_duck`/`A`/`R`/rango y presupuestos.

The `techo_mezcla` formula is defined as:

`pico_suma ≤ T_mezcla`, con `pico_suma` = pico de la suma de stems activos en ventana de 100 ms tras el transient

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| techo de mezcla | `T_mezcla` | float (dBFS) | **−3.0 PROVISIONAL** (rango −6…−1; solo se estrecha) | Techo provisional heredado de #4; este GDD diseña la cadena que lo cumple |
| stems activos | `stems` | set | {transient, cuerpo, armónico, sordo, aire, sostenido, cierre, click_gasto, bed, HUD} | Capas que pueden sonar a la vez en el peor caso |

**Output Range:** pico_suma en (−∞, `T_mezcla`]; superar el techo = FAIL de mezcla.
**Example:** transient (−6) + cuerpo (−10) + bed (−24) suman ≈ −4.6 dBFS ≤ −3.0 ✓; añadir armónico Justo (−12) da ≈ −3.4 ✓; el duck (F-S2) garantiza el margen antes de sumar la cola.

The `duck_sustain` formula is defined as:

`G_duck(t) = −P` durante el transient de rango superior, con ataque `A ≤ 1` tick y release `R`; el sustain vuelve a 0 dB tras `R`

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| profundidad | `P` | float (dB) | **6.0 PROVISIONAL** (rango 3–9; interino heredado de #4) | Cuánto baja el sustain bajo un transient rank-1 |
| ataque | `A` | int (ticks pared 60 Hz) | **≤1 (≤16.7 ms), normativo heredado de #4** | Velocidad de entrada del duck; nunca retrasa el transient |
| release | `R` | int (ticks pared) | **PROVISIONAL 6 (rango 3–12; OQ)** | Vuelta del sustain; por encima de 12 embarra el ritmo entre parries |
| rango que duckean | — | orden | 11>4>3>8>15, 9 fondo (heredado de #4) | Quién duckean a quién; el 9 conserva su pierna de audio bajo fusión |

**Output Range:** `G_duck` en [−`P`, 0] dB; fuera del transient siempre 0.
**Example:** transient del 4 (−6 dBFS pico) con sustain del 8 a −14: el sustain baja a −20 durante el transient (A≤1 tick) y vuelve en R=6 ticks; el ataque del 8 no se entierra (oráculo C2 de #4).

The `presupuesto_audio` formula is defined as:

`voces ≤ V_max ∧ tails ≤ T_max ∧ DSP_bat ≤ D_max`, con interinos `V_max = 12`, `T_max = 4`, `D_max = 20%`

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| voces simultáneas | `voces` | int | **≤12 PROVISIONAL** (solo se estrecha hasta medir) | Peor caso: máx variante intra + tails cross + fragmento aborto + capa VE + click_gasto legal en duelo (máx 1 Amparo + 1 Purga por ventana, gating G7) + HUD + bed |
| tails simultáneas | `tails` | int | **≤4 PROVISIONAL**, con steal/duck por dominancia (heredado de #4) | Colas en vuelo; el Castigo (11) tiene prioridad de steal con contabilidad |
| coste DSP en batería | `DSP_bat` | float (%) | **≤20% PROVISIONAL**, perfil 40 Hz | Medido en Deck batería con profiler/buffer/rate nombrados (OQ) |

**Output Range:** triple PASS/FAIL; cualquier término fuera = FAIL de presupuesto.
**Example:** 3 transients + 4 tails + bed + HUD + 1 click_gasto = 10 voces ≤12 ✓ con 4 tails exactas; si el click fuerza steal, roba la tail de menor rango nunca-11 con log+counter; una 5ª tail roba igual (nunca la del 11, nunca un onset de freeze) con log + counter heredados de #4.

The `escalera_aborto` formula is defined as (punto de partida **no-normativo**, D-F):

`peldaño(i,N) = temprano si 3i≤N; medio si 3i≤2N; tardío en otro caso` → `{+0 st seco corto} / {−2 st, decay ×1.2} / {−5 st + LP, decay ×1.4}`

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| índice / longitud | `i` / `N` | int | `1≤i≤N`, `N∈{3,4,5}` (guardas normativas heredadas) | Payload de `combo_abortado`; corrupto → descarte + log, nunca silencio |
| intervalo efectivo | `Δst` | semitonos | **≥2 st entre peldaños adyacentes (normativo heredado de #4 C6-DEF)** | Los valores +0/−2/−5 son ejemplo inicial, no norma |
| peso | `ΔLUFS` | loudness | **±2 LUFS-S entre peldaños (normativo heredado)** | Con compensación de loudness en gains + cue redundante de duración |

**Output Range:** tres peldaños distinguibles a ciegas con dirección tardío-más-grave/largo/pesado.
**Example:** N=5: i=1 → temprano; i=2,3 → medio; i=4,5 → tardío (tabla heredada de #4 C6-DEF).

## Edge Cases

- **Si 4+8 coinciden (Justo que cierra combo)**: suena **solo** la variante tímbrica del cierre (Regla 4) —un solo pico intra en stems (detector heredado >−6 dB/100 ms = FAIL)—. Dos picos = bug de precedencia, no "más recompensa".
- **Si 8+11 se solapan (cierre seguido de castigo)**: cross-dirección exento —**ambos transients completan** (buses distintos, Regla 5); el duck de rango ordena los sustains sin enterrar ataques; prueba de legibilidad ciega propia (espejo de #4 V1b).
- **Si el perfil es batería (40 Hz)**: lógica idéntica en ticks; la presentación cuantiza a la malla de 25 ms —**tolerancia +1 frame de render sobre el juicio**, misma que #4 C1—. BT excluido de toda medición de timing (Regla 14).
- **Si las tails agotan el presupuesto (5ª tail con 4 en vuelo)**: steal por dominancia —se descarta la tail de menor rango con log + counter; **nunca la del 11, nunca un onset de freeze** (política heredada de #4 R3; los medios del steal los posee este GDD).
- **Si el payload `i/N` llega corrupto en runtime**: se descarta el cue + log + counter (nunca skip silencioso; **no es FAIL_LOAD**: esa clase es de carga —glosario heredado de #4—).
- **Si la VE se completa por duración (sin evento #2 aún)**: suena el sostenido sorda provisional (Regla 8) —**nunca silencio total por diseño**; al desbloquearse el evento se sustituye por fila propia y este perfil queda solo para la apertura.
- **Si cae letalidad (jugador o jefe) durante tails**: teardown espejo de #4 R11 —derrota: corte <20 ms + kill de voces + nada post-mortem; muerte del jefe: las tails terminan naturales (≤500 ms) con decay normal.
- **Si hay pausa o menú sobre tails/sostenidos**: el duck y los contadores viven en `ALWAYS` (misma tabla que #4 R12); bajo pausa-menú el latch de input se suprime y ningún cue nuevo nace del menú —el menú solo emite intenciones ya timbradas.
- **Si se mashea durante el lockout (6b)**: cero SFX de feedback aunque el input llegue —ni siquiera el whoosh repetido—; el riesgo de incentivo se observa pero no se regula aquí (dueño: #1 C17, espejo de #4).
- **Si TOMAR/DEJAR se commitea dos veces el mismo tick**: el segundo cae por guardia de estado (heredado de #5/UX Decisión) —**un solo sting**, nunca doble; el audio no re-dispara sobre commit ya consumido.
- **Si `transicion_ms = 0` (corte puro en menús)**: "skippable" es pass vácuo también en audio —el crossfade se salta, el commit sonoro no se pierde: el sting del commit ya sonó pre-transición.

## Dependencies

| Sistema | Dirección | Dura / Blanda | Interfaz (qué fluye, quién posee qué) |
|---|---|---|---|
| Combate de Parry-Absorción (1) | Este consume | **Dura** | Consume veredictos ya resueltos (`parry_resuelto`, `combo_abortado` con `i/N`) + `calidad_timing`/predicado Justo + tabla de 16 eventos con su regla de oro y su precedencia 4-sobre-8. **No redecide, no retunea, no duplica**: `H_ref`/`B_ref`, ventanas y bonos se leen en vivo. Respeta C17 (cero feedback en lockout) y C24 (parry digital: ningún eje analógico dispara cues). Back-link pendiente: fila "consumed by Sonoro (16)" en #1 Dependencies/Cross-References (propuesta, no editada) |
| Feedback de Impacto (4) | Este consume + expone stems | **Blanda** | Consume triggers + ventanas + prioridad (11>4>3>8>15, 9 fondo) + transient-único-intra + presupuestos interinos + oráculos. **Expone stems pre-master** para los oráculos C2 (pico único), C5b-DEF (sorda) y C6-DEF (peldaños) + método de ID ciega. La precedencia 4-sobre-8 aquí es **requisito** (ambos mensajes sobreviven); la mezcla la pone este GDD |
| Máquina de Estados de Jefe (2) | Este consume (veredicto) | **Blanda** | Distingue VE de Golpe por el evento mismo; la completación de la `Acción Especial` suena con fila propia del sistema 2 cuando exista (deuda espejo de #1 V7: ambos cues distinguibles, ninguno leído como alivio). Opera con el sostenido provisional hasta entonces |
| Sistema de Gracia (5) | Este consume (capas) | **Blanda** | Capas por gasto (Purga/Amparo: transients secos por coste), decisión (TOMAR grave-resuelto / DEJAR aire-ascendente-sin-menor) y saturación (handoff a #6, sin sting). Respeta la prohibición de celebrar la absorción y la verba tomar/cargar/aliviar/poso/dejar ir |
| Menú Principal y Flujo (15) | Este consume (intenciones) | **Blanda** | Realiza el catálogo cerrado + cama `ui_vela_loop` duckeada en duelo + corte duelo→muerte <20 ms por bus. Back-link pendiente: timbres y ducking como propiedad de #16 en la fila Audio de #15 (propuesta, no editada) |
| HUD de Combate (13) | Hermanos (presentación) | **Blanda** | Co-emite la pata de alerta en 5/13 (presencia sorda medible, espejo de #4 C13); nunca sonoriza Postura/Vida/timer como datos —el HUD muestra, este sistema puntúa |
| Accesibilidad (21) | Este expone (canal) | **Blanda** | El oído es canal redundante, nunca único: todo veredicto ciego tiene su par visual/háptico en #1/#4; reduced-motion colapsa lo ceremonial a corte + tick seco por bus; ningún cue crítico depende solo de croma o de pitch absoluto |
| Consumidores futuros | Este expone (timbres) | Informativa | Hoy **ningún sistema consume timbres de #16** —este GDD no expone interfaz de gameplay; si un GDD futuro la pide, se declara entonces (contrato por anticipado, patrón de #1) |

> **Trazabilidad:** #1 lista "Audio depende de Combate" ✓ (este GDD es esa mitad). #4 lista "Paralela → Sonoro (16)" ✓ (este GDD es la mitad simétrica: triggers/ventanas/prioridad consumidos, stems expuestos). #5 lista "Emite a Sonoro" ✓. #15 lista "Audio (#16): provisional hasta GDD #16" ✓ —este GDD cierra ese provisional salvo medición (OQs). Registry: `parry_resuelto` y `combo_abortado` ya listan a `feedback-sonoro-parry.md` como consumidor previsto —al aprobarse este GDD pasan a confirmados (propuesta, no editada).

## Tuning Knobs

| Knob | Lanzamiento | Rango seguro | Si muy alto | Si muy bajo | Interacciones |
|---|---|---|---|---|---|
| `duck_profundidad_P` | **6.0 dB PROVISIONAL** | 6.0 fijo interino; barrido 3–9 solo en escucha ciega SN-05/SN-12 (no shippea sin pasarlas) | El sustain se hunde y el duelo suena a bombeo; la cola del 8 pierde su confirmación | Los transients se enmascaran entre sí; el detector −6 dB/100 ms empieza a fallar | Con `duck_release_R` (par conjunto) y `techo_mezcla` |
| `duck_release_R` | **6 ticks PROVISIONAL** | 6 fijo interino; barrido 3–12 solo en ciega (no shippea sin SN-05/SN-12) | Embarra el ritmo entre parries; colas que pisan el siguiente juicio | Corte seco, sin confirmación; el cierre suena a glitch | Par con `duck_profundidad_P`; vive en `ALWAYS` (pausa-menú lo congela) |
| `techo_mezcla_T` | **−3.0 dBFS PROVISIONAL** | −6…−3.0 hasta medir (más bajo = más headroom = estrechar; −1 exige medición P5-DEF) | Headroom desperdiciado; todo suena pequeño en Deck | Clipping en el pico 8+11; el peor caso deja de caber | Lo garantiza el duck; lo verifica el oráculo de stems |
| `voces_max` | **12 PROVISIONAL** | 8–12 hasta medir (12 es techo, no centro; >12 exige medición) | Se aprueban diseños que Deck-batería no sostiene | Steals constantes; tails que nunca terminan | Con `tails_max` y `DSP_bat_max`; solo se estrecha hasta P5-DEF |
| `tails_max` | **4 PROVISIONAL** | 2–4 hasta medir (4 es techo) | Colas que embarran el juicio siguiente | Steal audible en cada fusión; el sustain deja de confirmar | Con prioridad de steal por dominancia (11 nunca robado) |
| `DSP_bat_max` | **20% PROVISIONAL** | 10–20% hasta medir (20% es techo, perfil 40 Hz) | Se come el presupuesto de física/render en batería | Cualquier reverb/colade sostenido se vuelve imposible | Medido en Deck batería, perfil 40 Hz, peor caso exacto |
| `tonica_triada[3]` | **PROVISIONAL (set D-B)** | Dentro del modo único | Tres duelos que suenan a tres juegos distintos | Tríadas intercambiables; el tell del 1 pierde su segunda vía | Con `brillo_justo` (el Justo es brillo, nunca tónica nueva) |
| `brillo_justo` | **PROVISIONAL** | Solo tímbrico, sin capa nueva en 4+8 | Se lee como instrumento nuevo; rompe la precedencia | El Justo deja de distinguirse a ciegas del normal | Acotado por la Regla 4 (variante, no superposición) |
| `sostenido_VE14` | **Params #4 R5 PROVISIONAL** | Los pineados (−12 dB, LP@800, ≤150 ms, <−60 dBFS) | La apertura VE grita como un impacto; el jugador parea por reflejo | La VE se vuelve invisible al oído; muere la elección (espejo de #1 V5) | Expira al llegar el evento #2; entonces solo-apertura |
| `sting_tomar / sting_dejar / click_gasto` | **Familia sobria PROVISIONAL (D-D)** | Grave-resuelto / aire-sin-menor / seco-por-coste | Celebración encubierta: viola la prohibición de #5 | Indistinguibles entre sí; el commit deja de confirmarse | Con `ui_vela_loop` (duckeada) y corte <20 ms |
| `escalera_aborto_vals` | **Punto de partida D-F** | Peldaños con Δ≥2 st y ±2 LUFS-S (normativo) | Tardío teatral que pide thud del 5 (prohibido) | Peldaños indistinguibles; el aborto suena genérico | Dirección late=heavier normativa; valores en playtest ciego |

Interinos = techos. Shippear por encima (16 voces / 6 tails / 30% / −1 dBFS) sin medición pre-Vertical Slice viola P5-DEF aunque un barrido lo liste. El barrido bilateral vive solo en harness ciego/batería, nunca en build.

**No-knobs (heredados, se referencian, jamás se retunean aquí):** `H_ref`/`B_ref` (Combate) · ventanas de freeze y juicio ≤2 / confirmación ≤10 (#4) · orden 11>4>3>8>15 y 9 fondo (#4) · guardas `1≤i≤N`, `N∈3..5` (#4) · `physics_ticks_per_second = 60` (invariante) · `recuperacion_whiff` (solo lectura viva para el tail del whoosh) · catálogo de intenciones UI (#15).
**Prohibido forkar aquí:** cualquier valor de la fila anterior se consume por referencia; si #1/#4 lo retunean, este GDD re-verifica, no re-declara.

## Acceptance Criteria

Gate levels: Logic/mezcla = BLOCKING (`tests/unit/sonoro/`, `tests/integration/sonoro/`); escucha ciega/feel = BLOCKING con protocolo (el oído es requisito, no polish: sin ID ciega no hay legibilidad); presupuesto Deck = BLOCKING tras medición. Tags: **[A]** automatizable con stubs (gdUnit4 + stems pre-master + gamepad virtual + reloj fake), **[M]** escucha ciega/manual con protocolo (N≥10, ojos cerrados/forced-choice, criterio binomial p<0.05 vs azar, Deck 7″ altavoces + cable —BT excluido—, runs separadas dock/batería, artefactos en `production/qa/evidence/sonoro-[fecha]/`).

**Protocolo ciego común (aplica a todo [M]):** observadores sin lectura previa del GDD; clips a velocidad real en Deck; tarea forced-choice entre veredictos ("¿normal o Justo?", "¿cierre o Justo simple?", "¿daño o aborto?"); umbral ≥9/10 (binomial p<0.05); sub-veredictos por modo (dock / batería) registrados por separado; la pata SFX de #4 C1 sigue ADVISORY hasta cadena presupuestada y su promoción arrastra a SN-02. Interino oráculo stems (hasta OQ pre-sprint): captura pre-master 48 kHz, ventana 100 ms tras transient, detector pico-secundario >−6 dB rel = FAIL, floor −60 dBFS, LP@800 verificable por FFT, Δ≥2 st por chroma + ±2 LUFS-S por loudness (método #4 C6-DEF verbatim). SN-01–SN-04/SN-08/SN-09 corren contra este interino; re-corren tras publicar el propio.

- [ ] **SN-01 [A]** — GIVEN stubs deterministas de los 16 eventos (trigger-suficiente espejo de #1 C19: sin depender del sistema 20), WHEN se dispara cada evento aislado con trauma 0, THEN cada uno emite exactamente su firma de la tabla (transient/cuerpo/sordo/aire/sostenido/cierre) con onset del transient ≤2 ticks pared desde la resolución publicada, verificado en stems pre-master (oráculo #4).
- [ ] **SN-02 [A]** — GIVEN parry normal / Justo / VE parada / cierre / castigo aislados, WHEN se mide el juicio en stems, THEN el transient de entrada cae ≤2 ticks pared AND la confirmación (sustain/cierre) cae ≤10 ticks pared en dock (+1 frame de tolerancia en batería); SFX sigue ADVISORY hasta cadena calibrada (mismo gate que #4 C1: pre-output, buffer/rate fijos, Deck altavoces + cable, BT excluido).
- [ ] **SN-03 [A]** — GIVEN coincidencia intra-dirección {(3+4), (4+8)} mismo-tick, WHEN fusionan, THEN **un solo pico** en stems (detector heredado: pico secundario >−6 dB rel. principal en 100 ms = FAIL) AND en 4+8 suena la **variante tímbrica del cierre** (misma frase, mismo punto de resolución), nunca dos capas armónicas superpuestas (espejo de #1 V4 y #4 C2).
- [ ] **SN-04 [A]** — GIVEN solape cross-dirección (8 T0 → 11 T+6, fallback hasta traza de constructibilidad, espejo de #4 C2), WHEN resuelve, THEN **ambos transients completan** en sus buses sin truncarse AND el duck ordena sustains sin enterrar el ataque del 8 (verificado en stems + legibilidad en SN-12).
- [ ] **SN-05 [M]** — GIVEN clips ciegos de 3 vs 4 (golpe simple) / 3 vs 15 / 8-preciso vs 8-no-preciso vs 4-simple, WHEN forced-choice, THEN ≥9/10 distingue cada par, con la variante 4+8 leída como "cierre con precisión" y nunca como "dos cosas a la vez".
- [ ] **SN-06 [M]** — GIVEN aperturas 2 vs 14 (solo audio, pantalla tapada), WHEN forced-choice, THEN ≥9/10 acierta cuál es cuál (tick seco vs sostenido) antes del cierre —espejo sonoro de #1 V5: sin esta legibilidad la elección VE muere al oído—.
- [ ] **SN-07 [M]** — GIVEN VE parada (15) vs parry normal (3) a ciegas, WHEN forced-choice, THEN ≥9/10 distingue "percusión sin cuerpo" de "impacto con cuerpo" AND ningún observador describe la Postura quieta como bug (espejo de #1 V6); GIVEN cierre 16 vs completación del sistema 2 (al desbloquearse), THEN ≥9/10 los distingue AND el 16 nunca se lee como alivio (espejo de #1 V7).
- [ ] **SN-08 [A]** — GIVEN aborto con (i,N) N∈{3,4,5} (fixture espejo de #4 C6-DEF), WHEN mapeo else-if con guardas, THEN peldaño correcto (temprano/medio/tardío) AND Δ≥2 st entre adyacentes AND ±2 LUFS-S AND dirección tardío-más-grave/largo/pesado AND **cero energía del thud del 5** en la ventana del cue (el 9 nunca lleva el thud); GIVEN payload corrupto, THEN descarte + log + counter, nunca skip silencioso.
- [ ] **SN-09 [A]** — GIVEN VE completada por duración (sin evento #2), WHEN suena el sostenido provisional, THEN pico ≥ floor+36 dB en 150 ms AND pico absoluto ≥ −60 dBFS (no-silencio) AND tail < −60 dBFS post-150 ms AND LP 24 dB/oct @800 Hz verificable en espectro (espejo de #4 C5b-DEF); al desbloquearse el evento: matriz 3-vías (16 vs sorda vs 12) + ABX N≥10.
- [ ] **SN-10 [A]** — GIVEN whiff + lockout `recuperacion_whiff` (lectura viva de #1), WHEN ventana completa, THEN **cero onsets de feedback** fuera del whoosh inicial AND pulsaciones descartadas sin ningún onset (espejo de #4 C5a / #1 C17); GIVEN 6b, THEN solo decay del whoosh, sin ticks ni pulsos.
- [ ] **SN-11 [A]** — GIVEN peor caso exacto (máx variante intra + tails cross + fragmento aborto + capa VE + click_gasto legal en duelo —máx 1 Amparo + 1 Purga por ventana, gating G7— + HUD + bed) en Deck batería, WHEN se mide (profiler/buffer/rate nombrados en plan de test), THEN voces≤`voces_max` AND tails≤`tails_max` AND DSP≤`DSP_bat_max` AND pico_suma≤`techo_mezcla` (interinos hasta P5-DEF; este GDD solo estrecha). BT excluido del gate.
- [ ] **SN-12 [M]** — GIVEN coincidencia cross (8→11) + fusiones intra en Deck 7″, WHEN N=10 observadores fuera del equipo identifican veredicto + dirección (absorber vs arrancar) + Postura-quieta-intencional, THEN ≥9/10 en dock (N=10) Y ≥9/10 en batería (N=10, pueden ser otros 10; artefactos separados por modo), artefactos separados en evidence (espejo de #4 V1b).
- [ ] **SN-13 [A+M]** — GIVEN commits TOMAR / DEJAR IR / Purga / Amparo (stubs de ledger #5), THEN [A] un solo sting por commit (dedupe mismo-tick), familia sobria (TOMAR grave-resuelto, DEJAR aire-ascendente-sin-menor, gastos clicks secos por coste), cero material de celebración; [M] ≥9/10 lee ambos commits como solemnes y ninguno como premio, error o castigo. Preguntas forced-choice literales (orden random): "¿premio o solemne?" (TOMAR), "¿castigo o digno?" (DEJAR IR), "¿error o resolución?" (ambos); ≥9/10 acierta "solemne/digno/resolución" en las tres.
- [ ] **SN-14 [A]** — GIVEN duelo→muerte, WHEN corte por bus, THEN silencio de música/ambiente divino en **<20 ms** + vela apagándose como único residuo; GIVEN intenciones UI (catálogo #15), THEN cada una suena con su timbre sin players directos y `ui_vela_loop` duckeada en duelo. THEN por bus: música/ambiente→bus Música/Ambiente, vela→bus Vela; grep `AudioStreamPlayer` fuera del router = 0 en build limpia.
- [ ] **SN-15 [A]** — GIVEN build limpia, WHEN cada knob propio (`duck_profundidad_P`, `duck_release_R`, `techo_mezcla_T`, `voces_max`, `tails_max`, `DSP_bat_max`, `tonica_triada`, `brillo_justo`, `escalera_aborto_vals`, gains de stings) se altera en su fichero (`assets/data/` por data-files, nunca hardcodeado), THEN el valor en runtime cambia sin tocar código (espejo de #4 X3a; el juicio ≤2 es presupuesto, no knob). Schema por familia en plan de test (tonica_triada: 3× pitch-class + path preset; brillo_justo: dB/Q solo-tímbrico + path; sostenido_VE14: ataque/sustain/LP/paths; stings/clicks: preset + gain + bus; escalera_aborto_vals: st/decay/LP/gain por peldaño). Sin schema el knob sale de SN-15 y vive solo en su ciega.

## Open Questions

| Pregunta | Owner | Deadline | Resolución |
|---|---|---|---|
| ★ ¿Timbres finales + cadena de duck tras la medición Deck-batería (profiler/buffer/rate nombrados)? Interinos D-E/D-A solo se estrechan | audio-director + performance-analyst | **Pre-Vertical Slice** | Pendiente — SN-11 fija el peor caso exacto; sin ella P5-DEF no cierra |
| ★ ¿Release `R` final del duck (3–12) y profundidad final (3–9) tras escucha ciega SN-05/SN-12? | audio-director + game-designer | Playtest externo | Provisional 6 ticks / 6 dB; si el sustain embarra o el transient se entierra, se mueve aquí, no en #4 |
| ★ ¿Valores finales de la escalera `i/N` (D-F es punto de partida) + gains con loudness tras SN-08 ciego? | audio-director | Playtest externo | Dirección late=heavier pineada por #4; todo lo demás se fija a oído |
| ★ ¿Propiedad final del bus `Hitstop` + inventario de emisores de UI por bus (cero players directos)? | este GDD + technical-director (ADR) | Al autorar este GDD en arquitectura | Cerrada por ADR-003 (dueño #16; #4 triggers/ventanas/prioridad); valores pendientes SN-11/P5-DEF |
| ¿Evento de completación de VE del sistema 2 (desbloquea fila propia + SN-09 2ª mitad)? | sistema 2, 4ª pasada | Congelado | Sostenido sorda provisional hasta entonces (D-C) |
| ¿Fixture `i/N` del sistema 2 (desbloquea SN-08 con payload real)? | sistema 2, 4ª pasada | Congelado | Stubs deterministas hasta entonces; guardas ya normativas en #4 |
| ¿Tónicas finales por tríada + brillo Justo sin romper precedencia (D-B a oído)? | audio-director + ux-designer | Playtest externo | Un solo modo; el Justo es brillo tímbrico, nunca set nuevo |
| ¿Stings finales TOMAR/DEJAR/gastos dentro de la familia sobria (D-D a oído)? | audio-director + narrative-director | Playtest externo | Prohibido celebrar: cualquier brillo de premio falla SN-13 |
| ¿Oráculo de stems: formato/ventana de captura pre-master + thresholds de calibración Deck? | audio-director + qa-lead | Pre-sprint | #4 los exige (C2/C5b/C6-DEF); este GDD los implementa |
| ¿Back-links en #1 (fila "consumed by 16"), #15 (timbres/ducking propiedad #16) y registry (constantes/fórmulas de este GDD)? | systems-designer | Al aprobar este GDD | Propuestas en el resultado de autoría; verifica `/consistency-check` |

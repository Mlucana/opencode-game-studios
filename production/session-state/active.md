<!-- STATUS -->
Epic: Diseño de sistemas MVP
Feature: GDD — Combate de Parry-Absorción (sistema 1/21)
Task: 62 tests. C12b NO cerrable: no define sus dos modelos de jugador. Siguiente: correr
<!-- /STATUS -->
<!-- CONSISTENCY-CHECK: 2026-08-04 | Registry en v8 | GDDs checked: 2 | Conflictos abiertos: 1 (el 113 del sistema 2, no cerrable por congelación) -->

# Estado de Sesión — NOVENA

**Actualizado**: 2026-08-04 · **Fase**: Diseño de sistemas (2/7 GDDs MVP escritos, **0 aprobados**)
**Motor**: Godot 4.7, consistente en `CLAUDE.md`, `technical-preferences.md` y `VERSION.md`. *(Deriva menor: `game-concept.md` aún dice "Godot 4.6". No afecta a ningún AC.)*

---

## Última sesión — se para de revisar, se empieza a testear

**Changeset 2 COMPLETO (ítems 0–3)**, ACs antes que prosa en los cuatro; detalle en las
cabeceras del GDD y en el registry v8. Decisiones vivas: `golpes_para_morir_base = 4` (→25,
plano) · parry **DIGITAL**, `calidad_timing` escalonada, sin sub-tick · sistema 9 acotado
por **magnitudes** (R10), reliquias **+1 golpe** · severidad de la `Acción Especial` como
**equivalencia**, no pago en Vida.

> **Motivo del cambio de dirección**: los ítems 2 y 3 cerraron **tres defectos que
> introdujeron los ítems 0 y 1**, y 9 ACs estaban bloqueados por un fixture inexistente.

**Primer código del proyecto**: `project.godot` (no existía) con `physics_ticks_per_second
= 60` como invariante · `src/gameplay/combate/` con `combat_tuning.gd` (Resource inyectado)
y `combat_formulas.gd` · `tests/helpers/` con **stub de jefe** (incl. combos), **espía de
orden de señales** y **harness de parry** · gdUnit4 6.2.0 · CI.

**✅ 55/55 EN VERDE** (369ms, 0 orphans); las dos ejecuciones —36/36 y 55/55— pasaron a la
primera. Ampliado a **62 tests / 35 ACs**, sin correr aún. **Cubiertos**: C3, C4, C6, C7,
C8, C9, C10, C11, C12a, C15, C19, C20, C21, C24, C25 · D1, D2, D3, D6, D7, D8, D9(a), D9(b),
D11, D12, D14, D15 · E1, E2, E5, E9, E10, E11, E12, E13.

> **Dos resultados que valen más que el verde**: **D9(b)** reproduce la tabla de veredictos
> del GDD exactamente (22 violaciones esperadas, 22 encontradas), y **E10/E11** confirma que
> el `100/6` de Cercanía a Dios llega a **0 exacto** tras el sexto castigo.

**Frontera respetada**: aritmética y ciclo del jugador. Hitstop y orden de transiciones
**sin tocar** — dependen del ADR de la Regla 8. El harness resuelve por polling explícito
del test, así que **no prejuzga el mecanismo**.

---

## Siguiente paso — correr la suite

✅ **Infraestructura resuelta.** gdUnit4 6.2.0 en `addons/gdUnit4/`, API verificada. Comando:
`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/unit
--ignoreHeadlessMode` (el flag **no es opcional**). Sin addon: `--script
tests/standalone_check.gd`.

1. ✅ **Combos implementados** (Regla 9): una instancia de Postura con la calidad del último
   parry, Repliegue una vez y nunca entre golpes, gracia 0.5×, aborto que cuesta **un** golpe y nunca N, payload `i`/`N`. **+3 ACs (C9, C15, E2)** → 61 tests, **35 ACs**. Simular el
   fixture destapó **tres bugs propios**: una ventana podía pararse varias veces, fallar el **remate** no emitía nada, y la Gracia salía mal en consecuencia.
2. ⚠️ **C12b NO es cerrable como está escrito** — ver bloqueantes. Sí se midió el riesgo que
   pretendía cubrir, con un test determinista y sin modelo de reactivo.
3. **C4a espera al ADR de la Regla 8**: verifica resolución síncrona, y escribir su test hoy
   prejuzgaría el mecanismo que el ADR debe decidir. El espía de señales ya está listo.

Sin fecha: **4ª pasada del sistema 2** (raíces R1 → R3 → R4 → R5) y re-review del sistema 1.
**Criterio de éxito** si se retoman: ninguna recurrencia de A, B ni C. **Las raíces** (se
conservan porque el criterio las nombra; detalle en el review log): **A** barrido léxico en
vez de enumerar consumidores de un tipo suma · **B** las enmiendas paran en la frontera
normativa/experiencial · **C** guarda sobre un término y no sobre la magnitud, seis
apariciones · **D** input a resolución de tick, resuelto rechazando la premisa.

---

## Bloqueantes y huecos abiertos (ningún changeset los ha cerrado)

- **El 113 del AC E3b del sistema 2.** No cerrable aquí: congelado. Va a la 4ª pasada, R5.
- **Hallazgo A4** — la banda de contacto del Castigo rebasa `ventana_castigo`: una pulsación legal contacta con el jefe fuera de `Aturdido`, con el jugador 10–14 ticks comprometido.
- **R3 puede no ser cerrable con texto**: la Regla 8 del sistema 2 y su cláusula de reentrada son mutuamente insatisfacibles; quizá el ADR deba escribirse antes que el GDD.
- **Dos afirmaciones que ya no describen el sistema**: *"el que lee el patrón no paga nada"* es falso —un `Golpe` en el lockout de whiff cuesta **25**— y *"crispa y binaria"*, con seis resoluciones.
- **Recomendados sin changeset**: legibilidad **prospectiva** · evento 5 vs evento 9 · **no existe fila de "duelo ganado"** · croma/luminancia del medidor de Gracia · **forma** de la
  Fórmula 5 a 9 ángeles (decreciente **por conteo, no por identidad**) · coste in-combat de absorber, mejor aquí porque este GDD **posee la Vida**.
- **`margen_reaccion_min`** sigue en el registry sin valor ni GDD fuente — registrar al autorar el sistema 20.
- ⚠️ **NUEVO — `recuperacion_exito` no existe como símbolo.** La recuperación tras un parry **exitoso** son "2–3 fotogramas" en prosa y **C10 asevera sobre ella**, pero no tiene
  nombre, dueño ni rango en Tuning Knobs. Mismo defecto de tipo que `recuperacion_recepcion`. Fijado provisionalmente en **3** (techo) para que el harness funcione. **Promover.**
- ⚠️ **NUEVO — `.claude/rules/gameplay-code.md` contradice la Regla 2 del GDD.** Exige "delta time para TODOS los cálculos temporales"; la Regla 2 lo **prohíbe** (contador entero, o el
  acumulador se congela en el hitstop). **La regla del proyecto es la que debe corregirse.** Menor: `test-standards.md` y `coding-standards.md` difieren en nombres de test.
- ⚠️ **NUEVO — C12b no define los dos jugadores que compara**, ni cadencia ni latencia, y el
  veredicto se **invierte** según cómo se modelen: con reactivo de latencia 0 hay empate
  (93–93), con latencia 6 el masher gana. Un test así certificaría el modelo, no la regla.
  **Debe declarar ambos modelos.** Sigue siendo puerta de release.
- ⚠️ **NUEVO — la mitigación del mash intra-combo no funciona en el rango útil.** Medido: un
  masher a cadencia máxima para **93/93 ventanas (100%) y recibe 0 golpes** en 30s; con
  varianza intra-combo de 2/4/6/9 ticks **sigue al 100%**, y solo a **12** baja (90.9%, 7
  golpes). Razón: dentro del combo no hay Repliegue y la recuperación de acierto son 3 ticks,
  así que el parry sigue **activo** al abrirse la siguiente ventana y la caza por el caso (b)
  de la Regla 3 — nunca paga el lockout de whiff con el que R6 cierra el mash. **La varianza
  solo muerde por encima de `parry_window` (13)**: cifra concreta para el sistema 20.
- ⚠️ **Deuda contra el sistema 2 congelado**: no existe **fila de feedback** para la
  **completación** de la `Acción Especial` —que **V7** exige distinguible del cierre— ni
  **evento declarado**, pese a que **C22 cuelga de él**. Va a la 4ª pasada.

---

## Estado de artefactos

| Artefacto | Estado |
|---|---|
| `game-concept.md` · `art-bible.md` | Completos *(el primero dice Godot 4.6)* |
| `systems-index.md` | Aprobado — 21 sistemas; sistema 1 actualizado |
| `combate-parry-absorcion.md` | **NEEDS REVISION** — changesets 1 y 2 **completos**. Listo para re-review |
| `maquina-estados-jefe.md` | **🔒 CONGELADO** — MAJOR REVISION NEEDED, 3 pasadas |
| `entities.yaml` | **v8** — al día con el changeset 2 completo |
| `technical-preferences.md` | Corregido el 2026-08-04: **parry digital** · framework **gdUnit4** (era GUT) |
| `project.godot` · `tests/` · CI | Creados. Stub de jefe + espía de señales + harness; **9 ACs desbloqueados**. **gdUnit4 6.2.0 instalado** en `addons/gdUnit4/` |
| `src/gameplay/combate/` | **Primer código del proyecto**, y **verde en su primera ejecución** (36/36) |
| `prototypes/parry-absorcion-concept/` | PROCEED. Sin README/CONCEPT — gap del hook |

Siguiente sistema nuevo cuando cierren el 1 y el 2: **Feedback de Impacto (Hitstop)**, #3.

---

## Contexto durable

### Reglas de proceso vigentes
1. **Escribe primero el AC desde el cuantificador completo de la regla**; uno calibrado al
   arreglo certifica el ejemplo, no la regla. Espejos en otros ficheros, mismo changeset.
2. **Ningún hallazgo se cierra en la sesión en que se encuentra.**
3. **Un barrido léxico no basta con un tipo suma**: enumerar **consumidores**, no
   apariciones. Cada enmienda declara su **alcance de capas**.
4. *(ítem 0)* **Una invariante fuera de su puerta automatizada es aceptable; fuera de ella
   sin decirlo, no.** R8 se añadió a Restricciones conjuntas y nunca se folió en D9.
5. *(ítem 1)* **Un hallazgo de especialista se verifica antes de actuar sobre él.**
   **Comprobar la referencia de motor antes de escribir una norma que nombre un mecanismo.**
6. *(ítem 3)* **Antes de fijar la MONEDA de un contrato, leer el lado del otro GDD.** R9a
   fijó "pagado en Vida" contra un sistema 2 que lo prohíbe: leer **antes de decidir**.

### Decisiones clave de Combate *(el detalle vive en su GDD)*
- **Combos Sekiro**: N golpes = UNA instancia de Postura, gracia 0.5× → **los ángeles ágiles
  son los más peligrosos para el alma**. Entrega la mitad "me estoy destruyendo" de verdad.
- Absorber concede +18 Vida Máxima; rechazar no. **El knob más delicado** — y R5 lo guarda
  **sobre el alcance equivocado** (`economy-designer`) **y sobre el término equivocado**.
- **R1–R10**: los rangos "seguros" por knob **no lo son en combinación**, y las inecuaciones
  **de un solo lado han fallado cuatro veces**: toda invariante nueva nace con los dos lados.
- **Propiedad de eventos**: *cada evento lo emite el GDD que posee el recurso cuyo agotamiento lo causa*; y **cada GDD posee el feedback de los sucesos de su propio dominio** (ítem 3).
- **El daño al jugador se ancla en `vida_base`, nunca en `vida_maxima`** *(ítem 0)*: si
  escalase con la máxima, absorber no compraría supervivencia. Presupuesto: **4 golpes**,
  plano entre tríadas — la dificultad vive en la **longitud** del duelo (12 vs 30 parries).
- **La Ventana Especial es el dilema del juego en miniatura** *(ítem 0)*: parar evita el
  coste y gasta corrupción; ignorar al revés. Solo funciona si Gracia es un coste real (**R9b**).
- **El parry es DIGITAL** *(ítem 1)*: un eje analógico mete la distancia de recorrido en el
  instante de pulsación —habilidad medida por hardware— y deja indefinido "una pulsación",
  término del que dependen C10, C17 y la aritmética de R6.
- **`calidad_timing` es escalonada, no continua** *(ítem 1)*: 7 valores por `Δ` en ticks;
  escribirla continua **invita al reloj real** y D14 lo detecta. Todo término con
  consumidores necesita umbral: "Parry Justo" tenía cinco y ninguno.
- **Al sistema 9 se le restringe por MAGNITUD, no por mecanismo** *(ítem 2)*: cuatro
  cantidades observables y **no existe "efecto no clasificado"**. Cada arreglo de un
  mecanismo empujaba al siguiente agujero.
- **El borde de Castigo NO es 114**: es `ventana_castigo − gracia_salida_castigo`. **Nunca literal.**
- **Prototipo, PROCEED**: 45% de acierto evaluando solo el instante de pulsar → **72%** con
  parry activo. Origen de **R3**, y la tasa de la que sale la conversión de R9a.
- La **Core Rule 9 del sistema 2** es la propiedad general y el colchón de 42 ticks una
  instancia. Da a `margen_reaccion_min` cota superior 28; **falta el suelo**.

### Ciclos de dependencia · **1↔5** Combate ↔ Gracia · **2↔20** Estados ↔ IA (asimétrico)

### Gaps que otros sistemas deben cerrar
`gracia_base` **y el coste no nulo de la Gracia exigido por R9b** → Gracia (5) · `multiplicador_ataque` → Reliquias (9) · `vida_max_angel`, cadencia, composición de combos, **suelo de `margen_reaccion_min`**, **tasa de curación acotada contra `dano_golpe_castigo`**, **varianza de separación intra-combo** (única palanca contra el mash intra-combo), **`severidad_accion_especial` por habilidad dentro de la banda de R9a** → IA de Jefes (20) · muerte/game over y payload de "duelo ganado"/"duelo perdido" → Run (3) · daño fuera de `Aturdido`, que romperá E5 **por diseño** → Efectos de Estado (19) · consumidor del payload `i`/`N` del aborto de combo → Impacto (4) y Sonoro (16) · **stub de jefe de test**, reclasificado en la 3ª pasada como **dependencia de calendario del sistema 1**, no del 20 (desbloquea C12b, riesgo vivo y puerta de release) · test de `calidad_timing` → `/test-setup`.

### Riesgo alto sin vía de mitigación
La **curación de jefes** en su eje cuantitativo: curar más deprisa de lo que el jugador daña hace el duelo inganable sin violar ninguna fórmula — única contingencia de alcanzabilidad de `Muerto` que R4 no cubre. Resto en `systems-index.md`.

### Diferido a `/create-architecture`
1. **Mecanismo de la Regla 8 — el más urgente; puede bloquear al GDD del sistema 2.**
   Godot 4.7 no garantiza orden entre `_physics_process` independientes salvo vía
   `process_physics_priority` (**no** `process_priority`, que ordena idle); el fallo es un
   tick de retraso silencioso o un desorden intra-tick invisible. **Cuatro decisiones de
   diseño** antes de que el ADR sea escribible: dirección del call stack en el perdón de
   anticipación · base temporal de los contadores · quién posee el instante de contacto
   del Castigo · exigencia de **costura observable** (si el ADR elige "llamada directa a
   método", C4a/E2/C5a/C3b quedan sin forma de escribirse). El ADR fija además **nombres
   canónicos de señal y payload** y una tabla nombre-de-diseño ↔ enum: `En Combo` y
   `Acción Especial` llevan espacios, así que **C8 no es implementable literalmente** sin
   ella.
2. **Es el MISMO ADR que el de la autoridad de tiempo de Combate**: el nodo que decide qué
   avanza al 4% durante el hitstop es el que decide en qué call stack se resuelven las
   transiciones. **Ninguno de los dos GDDs lo dice.** Tiene **siete** consumidores
   heterogéneos: scripts propios · `speed_scale` de `Tween`/`AnimationPlayer`/
   `GPUParticles2D` · `Timer` (sin hook → contador de ticks) · uniform `TIME` de shader ·
   **audio diegético** · `process_physics_priority` del autoload · stacking de hitstop.
   Con `hitstop_parry` en su suelo de 3 ticks (50ms), fijar Tween/AnimationPlayer en modo
   de física **deja de ser opcional**: a 40Hz la desalineación llega a 25ms, el **50%**.
3. Nodo dedicado vs. recurso de datos para el compositing de corrupción.

### Hueco de referencia de motor
`docs/engine-reference/godot/modules/` cubre 8 subsistemas y **ninguno es core/SceneTree** (despacho de señales, orden del bucle de física, fases del servidor, `process_priority` vs `process_physics_priority`). Es el subsistema del que depende el mayor riesgo técnico del proyecto, así que el "ningún cambio 4.4→4.7 aplica" es hoy un **negativo no verificado**. Prerrequisito del ADR, no de los GDDs. **Añadido por el ítem 1**: `modules/input.md`
existe pero está verificado contra **4.6** con el proyecto fijado en **4.7** —y 4.7 trae un
cambio incompatible de Input (device IDs) que no cubre—, y la palabra `timestamp` no
aparece en toda la referencia. Refrescarlo con `/setup-engine`; **no bloquea** al sistema 1.

### Inconsistencia de proceso a resolver
`technical-preferences.md` fija **GUT**; `coding-standards.md` especifica el comando de **gdUnit4**. Hay que elegir antes de escribir el test de C4a — que en cualquiera de los dos exige un **espía manual de lista compartida**, porque ningún framework prueba orden *entre señales distintas* de forma nativa.

### Nomenclatura · Tríadas por **función** (Humanidad / Cosmos / Cercanía a Dios) en art bible y GDDs, para no chocar con la numeración teológica de `game-concept.md`.

---

## [HANDOFF] Migracion a OpenCode completada — 2026-09-03

El proyecto del rar (`Videojuego.rar`, juego NOVENA Godot 4.7 + GDScript) se migro
a este repo (`opencode-game-studios`, `master`, commit `cc81442`).
Origen extraido en staging temporal (no forma parte del repo).
`Desktop\Videojuego` es OTRO proyecto: no tocar.

**Estado fijado**: `production/stage.txt` = `Systems Design`, `review-mode.txt` = `full`
(elegido por el usuario; el rar traia `lean`).
Stack en `AGENTS.md`/`CLAUDE.md` = Godot 4.7 / GDScript.

**Adoptado del rar**: fix de deteccion de Python en `validate-commit.sh` y
`validate-assets.sh` + hook nuevo `check-state-size.sh` (cableado en
`.claude/settings.json` → `SessionEnd` y en `.opencode/plugins/ccgs-hooks.js`).

**PROXIMO PASO (otra sesion)**: correr `/project-stage-detect` y despues `/adopt`
para auditar fase, huecos y conformidad de formato de los GDDs en espanol.
Hay GDDs (parry-absorcion, maquina-estados-jefe, concepto) pero sin ADRs ni
`architecture.md`. `src/` solo tiene combate; hay prototipo jugable en
`prototypes/parry-absorcion-concept/` y tests GdUnit4 en `tests/`.

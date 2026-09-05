# ADR-001: Tiempo autoritativo y hitstop (Pattern-A: pausa diegética 0% + doble contador)

## Status

Proposed

> **BLOQUEO DE PROCESO**: este ADR está en `Proposed`. Requiere aceptación
> explícita del usuario → `Accepted` antes de que ninguna historia lo
> referencie como guía (ver `docs/CLAUDE.md`: las historias que referencian un
> ADR en `Proposed` quedan auto-bloqueadas). La 4ª pasada del sistema 2, los
> ACs C4a/E2/C5a/C3b del sistema 2, el AC C4 instrumentado de Combate y todo el
> GDD de Feedback de Impacto dependen de esta aceptación.

## Date

2026-09-05

## Last Verified

2026-09-05 — verificado contra `docs/engine-reference/godot/VERSION.md`
(4.7.2-stable), los tres GDDs implicados y el código temprano existente. La
referencia de motor **no cubre** ninguno de los mecanismos que esta decisión
usa (ver Engine Compatibility): la verificación en motor real queda como
criterio de validación, no como hecho.

## Decision Makers

- `technical-director` (autor de la decisión técnica)
- Usuario (aceptación pendiente — toda decisión estratégica es suya)

## Summary

El combate de NOVENA necesita una autoridad única de tiempo en ticks enteros a
60 Hz que sobreviva al hitstop sin `Engine.time_scale`. Se decide **Pattern-A**:
el hitstop es **pausa total del subárbol diegético (0%) vía `SceneTree.paused`**
con HUD vivo, con **dos contadores** — `WallTick` (pared, autoload `ALWAYS`) y
`DiegeticTick` (diegético, propiedad del resolver de Combate,
congelado-por-construcción) — y fusión de hitstop por `max()`. Esto cierra el
ítem más urgente diferido a `/create-architecture` y fija quién avanza al 0%
durante el hitstop para los siete consumidores heterogéneos.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (4.7.2-stable; proyecto pineado en línea 4.7) |
| **Domain** | Core (SceneTree, bucle de física, `process_mode`, pausa) |
| **Knowledge Risk** | **HIGH** — post-cutoff, debe verificarse |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/modules/` (8 módulos: animation, audio, input, navigation, networking, physics, rendering, ui) |
| **Post-Cutoff APIs Used** | Ninguna API nueva con nombre; la decisión depende de **semánticas** cuyo cambio post-cutoff no está cubierto por la referencia (ver abajo) |
| **Verification Required** | Sí — lista cerrada en Validation Criteria (V1–V7). Sin ella, este ADR no puede pasar a `Accepted` con evidencia completa |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

**Detalle del gap (verificado el 2026-09-05 por búsqueda de texto completo):**
`docs/engine-reference/godot/modules/` cubre 8 subsistemas y **ninguno es
core/SceneTree**. Una búsqueda de `process_physics_priority`,
`SceneTree.paused`, `TWEEN_PROCESS_*`, `CALLBACK_MODE_*` y `time_scale` en toda
`docs/engine-reference/` devuelve **cero resultados**. Es decir: cada mecanismo
que este ADR nombra (orden de `_physics_process` entre nodos, exención de pausa
por subárbol, modos de proceso de `Tween`/`AnimationMixer`, comportamiento del
uniform `TIME` bajo pausa) es hoy **conocimiento no verificado contra 4.7**,
heredado del LLM o de la revisión de `godot-specialist`. El hueco de referencia
de motor documentado en `production/session-state/active.md` sigue abierto para
core/SceneTree. **Corrección parcial a ese estado**: `modules/input.md` ya
declara `Last verified: 2026-09-03 | Engine: Godot 4.7` y cubre el rework de
device IDs de 4.7 — el aviso de "verificado contra 4.6" está desfasado. Lo que
**sigue** sin aparecer en toda la referencia es la palabra `timestamp`
(búsqueda con cero resultados el 2026-09-05): la resolución sub-tick sigue
descartada por no verificada, tal como manda el GDD de Combate.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (es raíz; pero **lee** el contrato de eventos de ADR-002 — ambos deben aceptarse juntos) |
| **Enables** | ADR-002 (contrato de eventos combate-jefe: la dirección del call stack que aquí se fija es la que allí se cablea) |
| **Blocks** | 4ª pasada del sistema 2 (`maquina-estados-jefe.md`, congelado) · implementación de `Hitstop`/tiempo en `src/` · historias que referencien TR-parry-001/002/007 o TR-jefe-002 · Efectos de Estado (#19, rompe E5 por diseño y necesita esta base) |
| **Ordering Note** | ADR-001 y ADR-002 se aceptan en el mismo acto: ADR-002 depende de la dirección del call stack decidida aquí. Ninguna historia puede citarlos en `Proposed`. |

## Context

### Problem Statement

Tres documentos normativos exigen un comportamiento temporal que **ningún
mecanismo está autorizado a producir**:

1. El GDD de Combate (Regla 2) exige ticks enteros inmunes al hitstop,
   hitstop como pausa total diegética 0% con HUD a velocidad normal, y
   duraciones de hitstop canonicalizadas en ticks (5 base + bono Justo ≤ 8
   por R8).
2. El GDD de Máquina de Estados (Regla 8) exige resolución síncrona dentro
   del call stack que originó la resolución de Combate, y declara conformes
   "tanto la llamada directa como la señal no diferida" **sin elegir**.
3. El GDD de Feedback de Impacto (Reglas 1, 2, 12) ya implementa en diseño
   Pattern-A con autoload `WallTick`, contador `DiegeticTick`, gating de
   pausa y fusión `max()` — pero su Open Question lo marca como
   "bloquea implementar" hasta que exista este ADR.

Sin ADR, cada programador improvisaría su propio reloj en `dev-story`, y el
modo de fallo (un tick de retraso silencioso, desalineación del 50% en el
suelo de 3 ticks a 40 Hz) es invisible en tests ingenuos. El coste de no
decidir es divergencia irreversible entre los tres GDDs.

### Current State

- **Código temprano existente**: `src/core/time_authority.gd` es un stub
  explícito ("NO definitivo", "sujeto a reescritura total"). Evaluación
  contra esta decisión (exigida por el encargo):
  - **Válido y se conserva la idea**: ticks enteros, `advance_tick()`,
    señal `ticked`, HUD que no lee la escala de juego.
  - **Obsoleto y debe reescribirse**: su comentario de cabecera describe
    "hitstop mundo al 4% 5 ticks" — la semántica del 4% fue **retirada** por
    los tres GDDs (Combate Regla 2 regla normativa 2, Feedback Regla 1:
    pausa total 0%). El stub congela la semántica antigua en un comentario
    con autoridad aparente. **No debe compilarse contra él ninguna historia.**
  - **Insuficiente**: un solo contador manual no distingue pared de
    diegético; bajo pausa total el contador diegético no avanza por
    construcción y el freeze necesita un reloj que sí avance (WallTick).
    El `game_scale: float` como "escalar de apariencia" es el mecanismo
    equivocado bajo Pattern-A: el mundo no se escala, se pausa.
- **`project.godot` no fija `physics_ticks_per_second = 60`** (verificado
  el 2026-09-05: el fichero solo declara nombre, features 4.7, plugins e
  input). El estado de sesión afirma que se creó con ese invariante; **no
  está en disco**. La invariante existe solo en prosa de GDD. Es el cambio
  de configuración más barato y más urgente de este ADR.
- **Frontera respetada por el código de gameplay**: `src/gameplay/combate/`
  (`combat_tuning.gd`, `combat_formulas.gd`) contiene solo aritmética y
  ciclo del jugador; su comentario declara que hitstop y orden de
  transiciones "NO van aquí". No hay deuda de migración en gameplay.
- **Infra de test lista pero condicionada**: `tests/helpers/signal_order_spy.gd`
  existe y asume vía de señales; su propia cabecera advierte que si el ADR
  elige "llamada directa a método" sin señales, C4a/E2/C5a/C3b quedan sin
  forma de escribirse. Este ADR debe cerrar esa condición (lo hace: señales
  síncronas obligatorias como costura observable — ver Decisión).

### Constraints

- **Motor**: Godot 4.7 no ofrece eximir un subárbol de `Engine.time_scale`
  (escalar global único). Verificado por `godot-specialist` en re-review y
  ratificado aquí como premisa: **`Engine.time_scale` queda prohibido** para
  el hitstop (debe permanecer `1.0`; X3a lo pineará como excepción auditada).
  `AudioServer.playback_speed_scale` igualmente `1.0`.
- **Plataforma**: Steam Deck — modo 40 Hz de batería, pantalla 7",
  `max_physics_steps_per_frame = 8` (confundidor declarado de C13/P4: bajo
  stall severo los ticks se limitan respecto al pared; el contador no se
  corrompe pero la medición wall-clock se estira).
- **Diseño fijo**: `hitstop_parry` 5 ticks (rango 3–6), bono Justo +2/+1/+0
  con R8 (`total ≤ 8`), `physics_ticks_per_second = 60` invariante,
  HUD nunca congelado, audio diegético en el bucket diegético.
- **Proceso**: prohibido commitear en este acto; ficheros nuevos solo los
  dos ADR indicados; el stub `time_authority.gd` **no** se edita aquí (su
  reescritura es trabajo de historia bloqueada por este ADR).

### Requirements

- TR-parry-001: todas las duraciones autorizadas como ticks enteros de
  simulación fija 60 Hz; contador inmune al hitstop.
- TR-parry-002: mecanismo de escala temporal diegética sin
  `Engine.time_scale` (gameplay escalado/pausado, HUD a velocidad plena).
- TR-parry-007: contrato de hitstop + cámara + rumble (base 5 ticks, bono
  Justo acotado por R8, Tweens en modo física).
- TR-jefe-002: despacho síncrono de transiciones dentro del call stack de
  origen (la mitad temporal; la mitad de nombres/eventos vive en ADR-002).
- Presupuesto: frame 16.6 ms dock / 25 ms batería-40Hz; hitstop total ≤ 8
  ticks; onset juicio ≤ 2 ticks de pared.

## Decision

Se adopta **Pattern-A (pausa diegética 0% + doble contador + fusión max)**,
ya decidido en diseño por el GDD de Feedback de Impacto el 2026-09-04 y
ratificado aquí como decisión de arquitectura vinculante:

1. **Mecanismo de freeze**: `SceneTree.paused = true` con el subárbol
   diegético en `PROCESS_MODE_PAUSABLE` (default) y la capa de
   presentación viva en `PROCESS_MODE_ALWAYS` (HUD `CanvasLayer`,
   autoload `WallTick`, duck de audio, latch de input, driver de rampa).
   El mundo no corre al 4%: **corre al 0%**. La semántica del 4% queda
   retirada en todos los documentos; el comentario del stub que la nombra
   queda declarado obsoleto por este ADR.
2. **Doble contador, cada uno con un solo dueño**:
   - `WallTick` (autoload, `ALWAYS`): ticks de **pared**. Avanza siempre
     salvo pausa-menú (gating Feedback R12: freeze-counter tickea en
     freeze-pausa y se congela en pausa-menú; trauma-decay se salta en
     ambas; rampa tickea en freeze-pausa; latch-stamps se suprimen en
     menú). Sella con `Engine.get_physics_frames()`. Dueño de: duración
     del freeze, presupuesto de onset (≤ 2 ticks pared), decaimiento de
     trauma, fase de rampa, `pool_log`, stamps del latch.
   - `DiegeticTick` (contador entero, propiedad del **resolver de
     Combate**): ticks de **simulación**. Solo avanza vía llamada explícita
     desde el `_physics_process` del resolver. Durante el freeze el
     resolver pausable no tickea → **congelado-por-construcción**, que es
     exactamente la inmunidad que exige TR-parry-001. Dueño de: `parry_window`
     (13), `recuperacion_whiff` (9), `calidad_timing.Δ`, `restantes(T)`,
     `ventana_castigo`, `retreat_base` — toda la Regla 2 de Combate.
   - `project.godot` debe fijar `physics_ticks_per_second = 60` (hoy
     ausente — hallazgo de este ADR). Sin esa línea, la invariante es prosa.
3. **Dirección del call stack** (cierra la primera de las 4 decisiones
   abiertas): **el resolver de Combate posee el instante de resolución y
   llama al FSM del jefe, nunca al revés.** Secuencia normativa dentro de
   un único `_physics_process` del resolver:
   ```
   resolver._physics_process
     → lee input (is_action_just_pressed, digital, sin buffer)
     → resuelve parry contra ventana parable viva (Regla 3, casos a/b)
     → DiegeticTick += 1  (el tick se sella ANTES de despachar)
     → BossFSM.on_combat_result(resultado)   [llamada directa, mismo stack]
         → FSM resuelve transición (Reglas 2/3/4/5 del sistema 2)
         → FSM emite señales canónicas síncronas (ADR-002)
             → suscriptores SOLO leen / presentan (reentrada prohibida)
     → Feedback transient de entrada (orden Feedback R1) → paused = true EN ÚLTIMO LUGAR
   ```
   El perdón de anticipación (caso b: la ventana se abre con el parry ya
   activo) no invierte la dirección: quien detecta la apertura es el
   resolver en su polling, no el FSM llamando a Combate. El FSM nunca llama
   al resolver.
4. **Orden de nodos**: `WallTick` precede a nodos de escena en despacho;
   el resolver de Combate precede al nodo del jefe vía
   `process_physics_priority` explícito (cinturón, no mecanismo primario:
   el mecanismo primario es la llamada directa, inmune al orden de nodos).
   `process_priority` (idle) **no** ordena física — queda prohibido citarlo
   como garantía de orden físico.
5. **Mecanismo por consumidor** (cierra el ítem de los 7 heterogéneos):

   | # | Consumidor | Mecanismo normativo |
   |---|---|---|
   | 1 | Scripts propios (gameplay) | Consumen `DiegeticTick`; **prohibido acumular `delta`** (`elapsed += delta`) para duraciones de diseño. Contador entero o nada. (La regla contraria de `.claude/rules/gameplay-code.md` —"delta para TODOS"— **contradice la Regla 2 del GDD y debe corregirse**; ver Consecuencias.) |
   | 2 | `Tween` / `AnimationPlayer` (`AnimationMixer`) en gameplay | Fijados explícitamente en modo física (`TWEEN_PROCESS_PHYSICS` / modo physics de callbacks). El default idle cuantiza la reacción al siguiente frame de render: a 40 Hz hasta 25 ms de desalineación, el **50% del suelo de 3 ticks**. No negociable en el extremo corto del rango (R8). Verificación V5 pendiente (sin referencia core). |
   | 3 | `GPUParticles2D` | No se usa en combate: el GDD de Feedback pinea **`CPUParticles2D`** (determinista, reloj de física, `finished` fiable, seguro en Compatibility). Pool 2+1, `one_shot`, reciclado por `finished` nunca por `emitting`. |
   | 4 | `Timer` / `SceneTreeTimer` | **Prohibidos** para temporización de gameplay. Sin hook de pausa y con disparo en tick posterior por construcción, violan la Regla 8 además de la Regla 2. Todo temporizador de diseño es un contador de ticks (pared o diegético según columna). |
   | 5 | Uniform `TIME` de shader | `TIME` sigue corriendo bajo pausa (pendiente de verificación V6): **ningún VFX sincronizado a gameplay puede leer `TIME`**. El driver (`WallTick`, `ALWAYS`) escribe uniforms propios (`freeze_phase`, `rampa_t`) por writes foráneos, que bypasan la pausa legalmente. |
   | 6 | Audio diegético | `Engine.time_scale == 1.0` y `AudioServer.playback_speed_scale == 1.0` pineados (X3a). El SFX diegético de impacto escala con la simulación por **diseño de bus/duck** (propiedad final del sistema 16; bus `Hitstop` provisional en Feedback): transient de entrada a rate intacto (juicio < 100 ms), colas ducked. Nunca varispeed global. |
   | 7 | Autoload + stacking | `process_physics_priority` del autoload documentado en código; **fusión por `max()`**: mismo tick → `counter := max(f1,f2)`, una sola emisión `freeze_started`, sin reentrada, sin suma ni encadenamiento. Corte-por-golpe evaluado ANTES de emitir. Rampa mid-re-freeze: fase en hold. |

6. **Costura observable obligatoria** (cierra la cuarta decisión abierta;
   detalle de nombres en ADR-002): la transición viaja por **llamada
   directa** (mecanismo) **y** por **señal síncrona no diferida**
   (observabilidad). La vía "solo llamada directa, sin señales" queda
   **rechazada**: dejaría C4a/E2/C5a/C3b sin forma de escribirse, tal como
   advierte la cabecera del espía. Ver ADR-002 para nombres, payloads,
   tabla diseño↔enum y prohibición de reentrada.

### Architecture

```
                        ┌─────────────────────────────────┐
                        │  Engine (60 Hz física, t_scale=1) │
                        └────────┬────────────────┬───────┘
                                 │                │
                    ┌────────────▼──────┐  ┌──────▼──────────────┐
                    │ WallTick (ALWAYS) │  │ Resolver Combate    │
                    │ reloj de PARED    │  │ (PAUSABLE)          │
                    │ freeze/onset/     │  │ reloj DIEGÉTICO     │
                    │ trauma/rampa/pool │  │ input→resolución    │
                    └────────┬──────────┘  └──────┬──────────────┘
                             │  sella pared       │  llamada directa (mismo stack)
                             │                    ▼
                             │            ┌───────────────┐
                             │            │ BossFSM       │
                             │            │ (PAUSABLE)    │
                             │            │ transiciona   │
                             │            └───────┬───────┘
                             │                    │ señales síncronas (observan)
                             ▼                    ▼
                    ┌─────────────────────────────────────────────┐
                    │ Suscriptores SOLO-LECTURA (HUD13, Feedback4, │
                    │ audio16): presentan, nunca reentran          │
                    └─────────────────────────────────────────────┘
  Freeze: paused=true EN ÚLTIMO LUGAR (tras transient). HUD/CanvasLayer ALWAYS.
```

### Key Interfaces

```gdscript
# Autoload WallTick (PROCESS_MODE_ALWAYS, precede a escena en despacho).
# Reloj de PARED. Congelado-por-menú, vivo-en-freeze (gating Feedback R12).
class_name WallTick
extends Node
var pared_tick: int          # += 1 por _physics_process propio; sello Engine.get_physics_frames()
var freeze_restante: int     # counter := max(f1, f2); una sola emisión freeze_started
var trauma: float            # decae 1/D_dec por tick pared fuera de freeze/pausa
var rampa_t: int             # fase smoothstep 0→2, flash anclado en +0
var pool_log: Array          # {tick_pared, emitter_id, evento, causa}
signal freeze_started(duracion_ticks: int)
signal freeze_finalizado()

# Contador diegético. Propiedad del resolver de Combate. Congelado-por-construcción.
class_name DiegeticTick
extends RefCounted
var tick: int                # SOLO avanza vía avanzar() desde el resolver
func avanzar() -> void: tick += 1

# Resolver (nodo PAUSABLE). Posee el instante de resolución.
# Orden normativo: sellar tick → llamar al FSM → transient → paused=true en último lugar.
func _physics_process(_delta: float) -> void:
    # PROHIBIDO usar _delta para duraciones de diseño (Regla 2).
    leer_input_digital_sin_buffer()
    var res := resolver_parry()        # Regla 3, casos (a)/(b)
    diegetic.avanzar()
    if res.hay_resolucion:
        jefe.on_combat_result(res)     # llamada directa, mismo call stack
        publicar_transient_entrada(res) # orden Feedback R1
        if res.pide_freeze:
            Hitstop.play(res.freeze_ticks)  # WallTick; paused=true EN ÚLTIMO LUGAR
```

### Implementation Guidelines

1. Ningún fichero de `src/gameplay/` o `src/ai/` acumula `delta` para
   duraciones de diseño. El linter de revisión debe tratar `elapsed += delta`
   en gameplay como defecto bloqueante (con la excepción documentada de
   interpolación puramente visual, que no decide nada).
2. Todo `Tween`/`AnimationPlayer` de gameplay fija su modo de física en la
   misma función que lo crea; el modo por defecto (idle) es un bug.
3. Ningún `Timer`/`SceneTreeTimer`/`await`/cola de eventos en el camino
   resolución→transición→transient (prohibición por propiedad de la Regla 8).
4. `project.godot`: añadir `physics_ticks_per_second = 60` + prioridades
   `process_physics_priority` de `WallTick` y del resolver (historia
   bloqueada por este ADR, no este acto).
5. `TimeAuthority` (stub) se reescribe como `WallTick` + `DiegeticTick`
   según estas interfaces; su `game_scale` desaparece (el mundo se pausa,
   no se escala). Reescritura en historia, no aquí.
6. Toda verificación de timing distingue *defecto de conteo* de
   *confundidor por hitch* registrando frame time + ticks/frame junto a la
   medición (protocolo C13/P4).

## Alternatives Considered

### Alternative 1: Escala diegética al 4% vía delta escalado (semántica antigua)

- **Description**: Un autoload expone un delta escalado (0.04 durante el
  hitstop) que solo consumen los nodos de gameplay; el HUD usa el delta del
  motor. El mundo corre lento, no parado.
- **Pros**: Transiciones suaves; reutiliza `delta` existente; el stub
  `time_authority.gd` ya apunta en esta dirección (`game_scale`).
- **Cons**: Contradice los tres GDDs aprobados (Combate exige pausa 0%,
  Feedback especifica transient + congelación 0%, C13b/C14 miden pausa).
  Reintroduce `delta` acumulado, que la Regla 2 prohíbe. El evento 8 exige
  congelación diegética Y reacción de HUD a la vez.
- **Estimated Effort**: Menor (el stub ya existe).
- **Rejection Reason**: Incompatible con diseño aprobado. La facilidad de
  implementación no compensa reescribir tres GDDs. La semántica del 4% queda
  retirada por este ADR.

### Alternative 2: `Engine.time_scale` global + reescalado de HUD

- **Description**: `Engine.time_scale = 0.04` (o 0.0) durante el hitstop;
  el HUD compensa dividiendo por la escala.
- **Pros**: Una línea congela todo; sin autoload.
- **Cons**: **Inconstruible**: Godot 4.7 no ofrece eximir un subárbol de
  `time_scale` (verificado por `godot-specialist`); el HUD no puede
  compensar lo que el motor escala globalmente sin reintroducir el drift.
  Bajo `time_scale` la cadencia por segundo real escala pero el delta por
  tick no, invirtiendo las invariantes de conteo. Viola UI Requirements
  ("cambios críticos en 1–2 fotogramas, sin ease-in").
- **Estimated Effort**: N/A (no funciona).
- **Rejection Reason**: Mutuamente excluyente con la Regla 2. Ya descartado
  en el GDD; se registra aquí para que nadie lo reabra.

### Alternative 3: Un solo contador manual (evolucionar el stub tal cual)

- **Description**: Conservar `TimeAuthority.tick` + `advance_tick()` como
  única autoridad, sin distinguir pared de diegético.
- **Pros**: Mínimo cambio; compila ya.
- **Cons**: Bajo pausa total el único contador no avanza y el freeze no
  tiene reloj (duración, onset, trauma, rampa y latch necesitan pared).
  El `game_scale` como escalar de apariencia perpetúa la semántica del 4%.
- **Estimated Effort**: Mínimo.
- **Rejection Reason**: No satisface TR-parry-002 (HUD a velocidad normal
  necesita su propio reloj) ni Feedback R1/R12 (gating pared/pausa).

## Consequences

### Positive

- Una sola historia de origen para cada tick: pared (presentación) y
  diegético (reglas). Desaparece la clase entera de bugs de drift
  render/física que la Regla 2 existe para prevenir.
- La inmunidad al hitstop es estructural (el resolver pausable no tickea
  en freeze), no una disciplina que cada programador deba recordar.
- C13a/b, C14, D3-onset y Feedback C1/C2/D1/D3 se vuelven implementables
  con oráculos ya escritos (deltas de `Engine.get_physics_frames()` en
  probe `ALWAYS`; prohibido contar `_process` o probes pausables).
- La dirección única del call stack (Combate → FSM) elimina la ambigüedad
  que bloqueaba la 4ª pasada del sistema 2 y el test de C4a.

### Negative

- **Coste de pausa real**: `SceneTree.paused` congela TODO lo pausable,
  incluidos sistemas futuros que olviden marcarse `ALWAYS`. Cada sistema
  nuevo debe declarar su columna (pared/diegético) o nace congelado en el
  primer hitstop. Carga de revisión permanente.
- **Shader**: todo VFX sincronizado necesita uniforms propios escritos por
  el driver; `TIME` queda vetado para gameplay. Trabajo extra en cada
  shader de combate (validación con `godot-shader-specialist`).
- **Audio**: sin varispeed global, el "mundo a cámara lenta" debe diseñarse
  por bus/duck en el sistema 16. El transient intacto es un requisito, no
  un accidente.
- Se acepta no verificar en este acto contra motor real (HIGH risk): la
  aceptación del usuario será sobre diseño + precedent, con la verificación
  como criterio bloqueante de primera historia.

### Neutral

- El stub `time_authority.gd` se reescribe entero; su API provisional
  (`game_scale`, `set_game_scale`) desaparece. Nada en producción depende
  de ella (solo presentadores de test), así que la reescritura es
  greenfield, no migración.
- `signal_order_spy.gd` sigue válido sin cambios: este ADR + ADR-002
  garantizan la vía de señales que el espía asume.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Semántica de `SceneTree.paused` / `process_mode` distinta en 4.7 respecto a lo asumido (sin referencia core) | Media | Alto (el freeze entero descansa aquí) | V1: escena mínima pared-vs-diegético en 4.7.2 antes de la primera historia; si diverge, ADR superseded |
| `process_physics_priority` no ordena como se asume, o el autoload no precede en despacho | Media | Medio (es cinturón; la llamada directa no depende del orden) | V2: test de orden de 3 nodos; si falla, el mecanismo primario sigue en pie |
| Modos de proceso de `Tween`/`AnimationMixer` renombrados o con default distinto en 4.7 | Media | Alto en el suelo de 3 ticks (50% de error) | V5: verificación nominal de API + test de desalineación a 40 Hz; pineado en control-manifest como "fijar modo en la creación" |
| `TIME` de shader congelado (o no) bajo pausa de forma distinta a la asumida | Baja | Medio | V6: test de uniform bajo pausa; si `TIME` se congelase, simplificar (pero NO depender de ello hasta verificar) |
| `Engine.max_physics_steps_per_frame = 8` estira wall-clock bajo stall y se lee como bug de conteo | Alta (en Deck) | Medio (falsos rojos en C13/P4) | Protocolo obligatorio: registrar frame time + ticks/frame junto a cada medición; producción fija 8 (recomendación al ADR desde Feedback P1) |
| Olvido de `ALWAYS` en un sistema futuro → congelado silencioso en el primer hitstop | Alta (a lo largo del proyecto) | Medio | Checklist de historia ("¿qué columna de reloj usa?") + `story-readiness` lo exige; C14 como red de seguridad |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | N/A (sin implementar) | Freeze: ~0 diegético; transient ≤ 1 tick pared; rampa acumulada en WallTick | ≤ 16.6 ms dock / ≤ 25 ms batería-40Hz (P1), P99 global y P99 ventana |
| Memory | N/A | Contadores O(1); `pool_log` acotado (anillo, no lista infinita) | 1.5 GB techo proyecto |
| Load Time | N/A | Validación de prioridades al cargar (FAIL_LOAD si falta) | Sin presupuesto propio |
| Network (if applicable) | N/A | N/A (sin red) | N/A |

## Migration Plan

No hay migración de comportamiento: `src/` no contiene código de tiempo
(real) y el stub es provisional por contrato. Plan en historias (bloqueadas
hasta `Accepted`):

1. `project.godot`: fijar `physics_ticks_per_second = 60`; declarar
   autoload `WallTick` con su `process_physics_priority`. Verificar: C2/C18.
2. Reescribir `src/core/time_authority.gd` → `WallTick` + `DiegeticTick`
   según Key Interfaces; borrar `game_scale`. Verificar: C13a/C14.
3. Corregir `.claude/rules/gameplay-code.md` ("delta para TODOS" →
   excepción normativa: duraciones de diseño en ticks; `delta` solo para
   interpolación visual no decisoria). Verificar: revisión, no test.
4. Fijar `Engine.time_scale == 1.0` y `AudioServer.playback_speed_scale == 1.0`
   como aserciones de carga (X3a). Verificar: D3/C1.

**Rollback plan**: Si la verificación V1 demuestra semántica de pausa
incompatible, este ADR pasa a `Superseded` y se escribe ADR-001b con el
mecanismo alternativo (delta escalado solo-diegético). Ningún GDD cambia:
los tres especifican efecto, no mecanismo, por diseño.

## Validation Criteria

- [ ] **V1 (BLOCKING)**: escena mínima en Godot 4.7.2 — nodo pausable no
  tickea en freeze, nodo `ALWAYS` sí; `paused=false` reanuda sin deriva de
  `DiegeticTick`. Criterio: 100 freezes de 5 ticks → `DiegeticTick` avanza
  0, `WallTick` avanza exactamente 5.
- [ ] **V2 (BLOCKING)**: orden de despacho `WallTick` → resolver → FSM
  observado en 3 nodos con `process_physics_priority` explícito; y prueba
  de que la llamada directa resuelve aunque se inviertan las prioridades
  (el mecanismo primario no depende del orden).
- [ ] **V3 (BLOCKING)**: C13a (contador exactamente 5, wall 5×16.666ms ±4ms)
  y C13b (Justo 7/6 ticks, R8 ≤ 8) en verde con protocolo anti-hitch.
- [ ] **V4 (BLOCKING)**: C14 — HUD actualiza a velocidad normal durante 5
  ticks de freeze (comparativa contra framerate real).
- [ ] **V5 (BLOCKING)**: `Tween`/`AnimationPlayer` en modo física reaccionan
  dentro del tick; en modo idle se mide la desalineación a 40 Hz y se
  documenta (prueba de que el requisito no es decorativo).
- [ ] **V6 (ADVISORY)**: comportamiento de `TIME` bajo pausa documentado;
  uniforms propios cableados en el shader de prueba.
- [ ] **V7 (BLOCKING)**: suite 62 tests en verde tras la reescritura del
  stub (ninguna regresión en fórmulas/Tuning).

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/combate-parry-absorcion.md` | Combate, Regla 2 (4 reglas normativas) | Ticks enteros inmunes; hitstop pausa 0% con HUD vivo; hitstop en ticks; 60 Hz invariante | Doble contador + pausa por subárbol + `project.godot` pineado; `delta` prohibido para diseño |
| `design/gdd/combate-parry-absorcion.md` | Combate, R8 + C13a/b + C14 | `hitstop_parry` 5 (3–6) + bono Justo ≤ 8 medible en pared | Freeze de `WallTick` con `max()`; oráculos de medición; protocolo anti-hitch |
| `design/gdd/maquina-estados-jefe.md` | Jefe, Regla 8 (mitad temporal) | Resolución síncrona en el call stack de origen; nada diferido | Dirección Combate → FSM por llamada directa; `process_physics_priority` solo como cinturón |
| `design/gdd/feedback-impacto.md` | Impacto, R1/R2/R12 + C1/C2/D1/D3 | Pattern-A, fusión max, gating pared/pausa, onset ≤ 2 | Ratificado como arquitectura vinculante; desbloquea su OQ "¿ADR de tiempo?" |
| `design/gdd/feedback-impacto.md` | Impacto, R4/R7 (pool, trauma) | Reloj de pared para `pool_log`, trauma, rampa | `WallTick` como único dueño de esos contadores |

## Related

- ADR-002 (contrato de eventos combate-jefe — aceptar en el mismo acto;
  fija nombres, payloads, tabla diseño↔enum, reentrada y costura de test)
- `src/core/time_authority.gd` (stub a reescribir — ver Current State)
- `tests/helpers/signal_order_spy.gd` (infra conservada; su condición
  "vía de señales" queda garantizada por ADR-002)
- `docs/architecture/architecture-review-2026-09-03.md` (gaps
  tiempo-autoritativo-y-hitstop, contrato-eventos, estructura-fsm)
- Deuda de proceso abierta por este ADR: `.claude/rules/gameplay-code.md`
  contradice la Regla 2 del GDD (delta-para-todo) y debe corregirse en
  historia separada

# ADR-002: Contrato de eventos combate-jefe (emisor canónico sistema 2 + costura observable)

## Status

Accepted (2026-09-05, avance automático)

> Los ACs C4a, E2, C5a, C3b y C8 del sistema 2 y el AC C4 instrumentado de
> Combate pueden referenciar esta decisión como guía.

## Date

2026-09-05

## Last Verified

2026-09-05 — verificado contra `design/gdd/maquina-estados-jefe.md` (Regla 8,
Regla 5, ACs C3b/C4a/C5a/C8/E2), `design/gdd/combate-parry-absorcion.md`
(Reglas 1/3/4/5, ACs C3–C5/C19–C21/C25) y `tests/helpers/signal_order_spy.gd`.
Nombres y payloads propuestos aquí son nuevos (no existen en código); la
convención que siguen (`snake_case`, pasado) viene de
`.claude/docs/technical-preferences.md`.

## Decision Makers

- `technical-director` (autor de la decisión técnica)
- Usuario (aceptado 2026-09-05 — avance automático)

## Summary

La Máquina de Estados de Jefe (sistema 2) es el **emisor canónico** de todos
los eventos de ventana activa; Combate (sistema 1) es su consumidor y le
devuelve el resultado resuelto. Se fijan los **nombres canónicos de señal en
GDScript** (todos `snake_case`, pasado), sus **payloads cerrados**, la
**tabla diseño↔enum** que hace implementable el AC C8 (`En Combo` y `Acción
Especial` llevan espacios y no son identificadores), la **prohibición de
reentrada** con guarda observable, y la **costura de test** que mantiene
C4a/E2/C5a/C3b escribibles sobre `signal_order_spy`. Esto cierra las 4
decisiones pre-diseño del estado de sesión por el lado del contrato.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 (4.7.2-stable; proyecto pineado en línea 4.7) |
| **Domain** | Core / Scripting (despacho síncrono de señales, `Object.connect`, flags de conexión) |
| **Knowledge Risk** | **MEDIUM** — la semántica usada (señal no diferida = `Callable`s invocados sincrónicamente en orden de conexión dentro del mismo call stack) pertenece al comportamiento estable de `Object` desde 3.x y no hay cambio documentado en 4.4–4.7; pero **no hay módulo core/SceneTree en la referencia** que lo confirme contra 4.7 (búsqueda de `process_physics_priority`, `SceneTree.paused`, `CONNECT_DEFERRED` en `docs/engine-reference/`: cero resultados) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/modules/` (ninguno es core — gap declarado en ADR-001) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | V1: una señal conectada por defecto emite sincrónicamente en 4.7.2 (orden de conexión = orden de invocación; `CONNECT_DEFERRED`/`call_deferred`/`await` quedan fuera del stack). Test de 10 líneas, bloqueante de primera historia. |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (dirección del call stack Combate → FSM; doble contador; pausa 0%. Este contrato cablea lo que aquél decide) |
| **Enables** | 4ª pasada del sistema 2 (corrige E3b 113→114 bajo conteo inclusivo, añade fila de feedback + evento de completación, registra fila reversa "depended on by Feedback") |
| **Blocks** | Mismo bloqueo que ADR-001: historias de FSM, de cableado Combate↔Jefe, de Efectos de Estado (#19) y de Feedback C6-DEF (fixture i/N) |
| **Ordering Note** | Aceptación conjunta con ADR-001. Si ADR-001 cayese (rollback a 001b), este contrato sobrevive intacto: no nombra ningún mecanismo de tiempo, solo orden causal y nombres. |

## Context

### Problem Statement

El estado de sesión difiere a `/create-architecture` **cuatro decisiones de
diseño** sin las cuales el ADR de la Regla 8 "no es escribible", y nombra el
mecanismo de la Regla 8 como "el más urgente; puede bloquear al GDD del
sistema 2":

1. **Dirección del call stack** en el perdón de anticipación (cerrada por el
   lado temporal en ADR-001: Combate → FSM; aquí por el lado del contrato).
2. **Base temporal de los contadores** (cerrada en ADR-001: WallTick pared +
   DiegeticTick del resolver).
3. **Quién posee el instante de contacto del Castigo** (se cierra **aquí**:
   mitad press → Combate, mitad contacto → sistema 2; ver Decisión §5).
4. **Exigencia de costura observable**: si el ADR elige "llamada directa a
   método" sin señales, C4a/E2/C5a/C3b quedan sin forma de escribirse — la
   propia cabecera de `signal_order_spy.gd` lo registra como condición
   abierta. (Se cierra **aquí**: llamada directa + señales síncronas
   obligatorias; la vía "solo método" queda rechazada.)

A ello se suma el **problema C8**: el AC C8 exige comparar por identidad el
conjunto del enum top-level contra la lista literal de la Regla 7 — pero `En
Combo` y `Acción Especial` llevan espacios y **no son identificadores
GDScript válidos**. Sin tabla normativa diseño↔enum, C8 no es implementable
literalmente y cada programador inventará la suya (`EN_COMBO` vs
`ENCOMBO` vs `COMBO`…), rompiendo la comparación por identidad en la primera
historia que la toque.

### Current State

- Los eventos existen solo en **prosa española** ("inicio de Golpe", "fin de
  Golpe", "inicio/fin de Ventana Especial", "duelo ganado", "parry
  exitoso/fallido"): cero símbolos en código, cero payloads declarados salvo
  `i`/`N` del aborto (Core Rule 3) y la exigencia de C3b de leerlos del
  evento capturado.
- La Regla 8 declara conformes "tanto la llamada directa como la señal no
  diferida" **sin elegir**, y su lista de prohibiciones es por propiedad
  (nada fuera del call stack de origen) con ejemplos no exhaustivos.
- `signal_order_spy.gd` está listo y asume la vía de señales, con ejemplos
  (`golpe_iniciado`, `parry_resuelto`) que este ADR **adopta como canónicos**
  para no invalidar la infra ya escrita.
- Deuda conocida que este contrato debe dejar servida pero no cerrar: el
  sistema 2 no tiene fila de feedback ni evento declarado para la
  **completación** de la `Acción Especial` (cuelga C22 de Combate y
  C5b-DEF de Feedback); el borde E3b dice **113** bajo conteo exclusivo
  mientras Combate posee `restantes(T)` inclusivo (borde **114**, raíz R5).

### Constraints

- **Nomenclatura de proyecto**: señales en `snake_case`, tiempo pasado
  (`technical-preferences.md`, p. ej. `health_changed`). Código existente en
  español para dominio (`golpe_iniciado` en el espía) e inglés para
  infraestructura (`ticked`, `finished`): este ADR fija **español para
  eventos de dominio**, inglés para infraestructura de motor.
- **Regla 8**: todo lo prohibido sigue prohibido (polling con
  `_physics_process` independiente, `call_deferred`/`CONNECT_DEFERRED`,
  `await`/corrutinas, `Tween.finished`, `SceneTreeTimer.timeout`,
  `animation_finished`, bus con cola). Alcance: solo el despacho de la
  transición, no el resto del jefe (mutaciones de escena que Godot exige
  diferir siguen diferidas).
- **C8**: el enum top-level contiene exactamente 9 valores; el contenedor
  `En Combo` y su índice `i`, más los sub-estados de `Acción Especial`,
  son campos separados, nunca valores del enum.
- **Proceso**: prohibido commitear; prohibido editar otro fichero; el
  sistema 2 está congelado (su 4ª pasada aplica este contrato, no este acto).

### Requirements

- TR-parry-006: bus síncrono de eventos de combate (emite
  resultado/postura/duelo-perdido; consume ventanas del jefe).
- TR-jefe-002: despacho síncrono de transiciones en el call stack de
  origen, sin reentrada de suscriptores, nombres canónicos de señal.
- TR-jefe-004: aborto de combo a `Repliegue` con `i` y `N` en el evento.
- TR-jefe-006: contrato de `Acción Especial` (par propio de eventos,
  2-de-4 consecuencias, configs ilegales que fallan al cargar: C5d, E1).
- TR-jefe-008: filas de feedback propias del jefe con distinguibilidad
  cierre-de-ventana vs completación (V7 de Combate).

## Decision

### §1. Propiedad de eventos (tres partes, sin ambigüedad)

| Parte | Posee | Emite (canónico) | Consume |
|---|---|---|---|
| Sistema 2 (FSM jefe) | **Límites de estado**: aperturas/cierres de ventana, transiciones, terminales | §2, señales `B-*` | `parry_resuelto`, `castigo_iniciado` (de Combate) |
| Sistema 1 (Combate) | **Resolución**: éxito/fallo, calidad, postura resultante, clasificación press→Castigo/Parry | §3, señales `C-*` | `golpe_iniciado`, `ventana_especial_abierta`, … (del sistema 2) |
| Sistema 20 (patrones) | Duraciones, composición (`N`), `interrumpible_por_parry`, severidades | Datos, no señales | Todo lo anterior como configuración |

Regla de desempate (ya usada para "duelo ganado/perdido", enmienda D): **cada
evento lo emite el GDD que posee el recurso o el límite que lo causa**. La
Vida del jugador → `duelo_perdido` (Combate). El estado terminal `Muerto` →
`duelo_ganado` (sistema 2). El instante de contacto del Castigo → sistema 2
(§5). La clasificación de la pulsación → Combate (§5).

### §2. Señales canónicas del sistema 2 (emisor de ventana activa)

Prefijo de lectura `B-*`. Todas conexión por defecto (síncrona), sin flags.
`tick` = `DiegeticTick` sellado por el resolver antes del despacho (ADR-001);
`window_id` = entero opaco por ventana emitida (correlaciona apertura con
cierre y con el `parry_resuelto` de Combate).

```
signal golpe_iniciado(window_id: int, tick_apertura: int)
signal golpe_finalizado(window_id: int, tick_cierre: int)
signal ventana_especial_abierta(window_id: int, tick_apertura: int)
signal ventana_especial_cerrada(window_id: int, fue_parada: bool, tick_cierre: int)
signal combo_abortado(indice_i: int, longitud_n: int)   # 1 ≤ i ≤ N, N ∈ 3..5; C3b lee ESTE payload
signal estado_ingresado(nuevo_estado: int /* EstadoJefe */, tick: int)   # costura de C4a/E2
signal estado_abandonado(estado_previo: int /* EstadoJefe */, tick: int)
signal accion_especial_interrumpida(window_id: int, tick: int)
signal accion_especial_completada(habilidad_id: StringName, tick: int)   # FUTURA — ver §6
signal duelo_ganado(tick: int)
```

Notas normativas:

- `golpe_finalizado` / `ventana_especial_cerrada` marcan el **cierre de la
  ventana**, no el resultado: el resultado viaja en `parry_resuelto` (§3) y
  la transición en `estado_ingresado`. Tres hechos, tres señales, un mismo
  stack, orden fijo: `*_finalizado/cerrada` → `parry_resuelto` →
  `estado_ingresado`. (El orden entre `parry_resuelto` y `estado_ingresado`
  es lo que C4a asevera.)
- `combo_abortado` se emite **además** de `estado_ingresado(REPLIEGUE)` (el
  Repliegue diferido que se paga, Core Rule 3), nunca en su lugar. Payload
  corrupto en runtime (`i`/`N` fuera de rango) → descarte + `WARN` + counter
  (clase RUNTIME_DROP del glosario C16, nunca FAIL_LOAD, nunca skip
  silencioso — precedente: Feedback Regla 6).
- `accion_especial_completada` se **declara** aquí (nombre + payload
  reservados) pero **no se implementa** hasta la 4ª pasada del sistema 2,
  que además le escribe su fila de feedback distinguible del cierre
  (evento 16, V7). Hasta entonces rige la variante sorda provisional de
  Feedback Regla 5. Reservar el nombre hoy impide que dos historias la
  bauticen distinto.
- `duelo_ganado` lleva hoy solo `tick`. La OQ del sistema 2 sobre payload
  adicional (qué jefe, tríada, duración — para Run/Meta) se resuelve al
  autorar el sistema 3; añadir campos entonces es compatible hacia atrás
  solo si van al final con defaults. **Prohibido** añadirlos por iniciativa
  en una historia de combate.

### §3. Señales canónicas de Combate (resolución consumida por el jefe)

Prefijo de lectura `C-*`. Las emite el resolver **antes** de llamar al FSM
(orden §4), en el mismo stack.

```
signal parry_resuelto(
    resultado: int,        # 0 = EXITO_GOLPE, 1 = EXITO_VENTANA_ESPECIAL, 2 = WHIFF, 3 = FALLO_CONECTADO
    window_id: int,        # correlaciona con la apertura B-*; -1 si no había ventana (whiff)
    tick_deteccion: int,   # DiegeticTick sellado; base de Δ para calidad_timing
    delta_ticks: int,      # Δ = |t_press − t_golpe| en ticks; -1 si no aplica (VE, whiff)
    postura_resultante: float  # Postura tras aplicar (una sola instancia en combos); decide Repliegue/Aturdido
)
signal castigo_iniciado(tick_pulsacion: int)   # press ya clasificado como Castigo (T ≤ borde; §5)
signal duelo_perdido(tick: int)                # posee la Vida del jugador (enmienda D)
```

Notas normativas:

- `EXITO_VENTANA_ESPECIAL` existe como valor **distinto** de `EXITO_GOLPE`
  para que Combate distinga ambos casos por el evento mismo (Core Rule 5):
  con VE, el consumidor aplica 2-de-4 (Gracia + hitstop; **cero** llamadas a
  daño de Postura y a Repliegue — C5a lo verifica por conteo en cero, no por
  estado resultante).
- `calidad_timing` **no** viaja como campo: se deriva de `delta_ticks` con
  la Fórmula 1 (escalones cerrados D1) y **no se calcula** para VE
  (`delta_ticks = -1`, C25b/D1b). Un `parry_resuelto` con
  `resultado = EXITO_VENTANA_ESPECIAL` y `delta_ticks ≥ 0` es payload
  corrupto (RUNTIME_DROP).
- `postura_resultante` es el único número que el FSM necesita para
  bifurcar (Regla 2: `> 0` → `Repliegue`; `== 0` → `Aturdido` en el mismo
  despacho, C4a). El FSM **nunca** recalcula daño de Postura.

### §4. Tabla diseño↔enum (hace C8 implementable literalmente)

```gdscript
# EstadoJefe — conjunto CERRADO top-level (Regla 7). Comparación de C8 POR IDENTIDAD
# contra esta tabla, nunca por cardinalidad.
enum EstadoJefe {
    REPOSO,          # "Reposo"
    TELEGRAFIADO,    # "Telegrafiado"
    GOLPE,           # "Golpe"
    EN_COMBO,        # "En Combo"        ← espacio resuelto: guion bajo, sin tildes
    REPLIEGUE,       # "Repliegue"
    ENFRIAMIENTO,    # "Enfriamiento"
    ATURDIDO,        # "Aturdido"
    ACCION_ESPECIAL, # "Acción Especial" ← espacio + tilde resueltos
    MUERTO,          # "Muerto"
}
```

Reglas de la tabla (normativas):

1. ASCII puro, MAYÚSCULAS, guion bajo por cada espacio, sin tildes. Es la
   única traducción válida; `ENCOMBO`, `COMBO`, `ACCION-ESPECIAL` y
   variantes son violaciones de C8.
2. Índice interno `i` de `En Combo` y sub-estados de `Acción Especial` son
   **campos** (`combo_indice: int`, `combo_n: int`), nunca valores del enum.
   Añadir un décimo valor sin pasar por el procedimiento de enmienda de la
   Regla 7 rompe C8 por identidad a propósito.
3. `resultado` de `parry_resuelto` usa enum propio cerrado
   (`EXITO_GOLPE`, `EXITO_VENTANA_ESPECIAL`, `WHIFF`, `FALLO_CONECTADO`).
   Añadir un resultado exige enmienda bilateral (Regla 7 del sistema 2 +
   Regla 4 de Combate), nunca rama por jefe.

### §5. Quién posee el instante de contacto del Castigo (3ª decisión abierta)

**Reparto en dos mitades**, ratificando el desdoble E3/E3b del GDD:

| Mitad | Dueño | Regla |
|---|---|---|
| Clasificación de la **pulsación** (¿Castigo o Parry?) | **Combate** (dominio del input) | `restantes(T) > gracia_salida_castigo` con conteo **inclusivo** (`restantes(T) = ventana_castigo + 1 − T`, propiedad de Combate, enmienda E). Borde derivado `T_max = ventana_castigo − gracia_salida_castigo` (**114** con valores de lanzamiento; **nunca literal**). Emite `castigo_iniciado` o reinterpreta como Parry. |
| Instante de **contacto** (¿conecta o expira?) | **Sistema 2** (dominio del límite de estado) | Prioridad **conexión sobre expiración**: contacto en el último tick de `ventana_castigo` (120) cuenta como conexión (E3). La banda de contacto (116–124) deriva de los frames de inicio+activos del Castigo (Feel Targets de Combate, leídos por referencia, no duplicados). Emite `castigo_conectado` (a definir en la 4ª pasada) o expira a `Telegrafiado` (C4c). |

**Recomendación al usuario (4ª pasada)**: corregir E3b de **113 → 114**
adoptando el conteo inclusivo de Combate, tal como la enmienda E de Combate
ya documenta como deuda (raíz R5). La aritmética es cerrada: con
`restantes(114) = 120 + 1 − 114 = 7 > 6` → Castigo; con `restantes(115) = 6`,
`6 > 6` falso → Parry. El 113 del sistema 2 proviene de `120 − T` exclusivo
más desigualdad estricta mal compuesta. **Alternativa si el usuario
discrepa**: mantener exclusivo exige reescribir C11 de Combate, la
desambiguación de input y la invariante de anchura — tres sitios contra uno;
no se recomienda.

### §6. Lo que la 4ª pasada del sistema 2 debe aplicar (alcance cerrado)

1. Adoptar nombres §2 + tabla §4; registrar la fila reversa "depended on
   by Feedback de Impacto" (OQ pendiente).
2. Corregir E3b 113 → 114 (§5) y la convención `restantes(T)` a inclusiva.
3. Implementar `accion_especial_completada` + su fila de feedback
   distinguible del evento 16 (desbloquea C22 de Combate y C5b-DEF de
   Feedback; cierra la deuda "sin fila ni evento").
4. Declarar `castigo_conectado(vida_jefe_restante, fue_letal)` /
   expiración como eventos propios (mitad contacto de §5).
5. **Efectos de Estado (#19)**: E5 ("Vida del jefe nunca cambia fuera de
   `Aturdido`") se romperá **por diseño** con quemadura/veneno. Protocolo
   ya escrito en el GDD y ratificado aquí: el **test** sigue fallando en
   rojo (gate Logic BLOCKING); el **runtime** usa aserción blanda + `WARN`.
   Al autorar el sistema 19, E5 se reescribe o retira explícitamente —
   nunca se deja en rojo permanente ni se relaja en silencio. El contrato
   de señales no cambia: el daño de estado viaja por sus propios eventos
   (a nombrar en el GDD 19), nunca reutilizando `golpe_iniciado`.

### §7. Prohibición de reentrada (con guarda observable)

Ningún suscriptor de `estado_ingresado` / `estado_abandonado` /
`parry_resuelto` (HUD-13, Feedback-4, audio-16) puede disparar
sincrónicamente una nueva resolución de transición durante el mismo
despacho. Se limitan a lectura y presentación. Patrón obligatorio (mismo
que Feedback D3):

```gdscript
var _en_resolucion: bool = false
var _violaciones_guardia: int = 0   # observable; el test lo lee
func on_combat_result(res) -> void:
    _en_resolucion = true
    # ... resolver + emitir ...
    _en_resolucion = false
func _on_estado_ingresado(_e: int, _t: int) -> void:
    if _en_resolucion:
        _violaciones_guardia += 1
        return
    presentar()
```

La única vía diferida sancionada en todo el proyecto es el
**diferido-coalescado de Feedback R8** (parry durante `Golpe recibido`:
máx. 1 slot, duración congelada a llegada, propiedad de Feedback, fuera
del stack de resolución). Cualquier otro diferido en este camino es
violación de la Regla 8.

### Architecture

```
  Sistema 20 (datos)          Sistema 2 (FSM, PAUSABLE)         Combate (resolver, PAUSABLE)
  ──────────────────          ─────────────────────────         ────────────────────────────
  duraciones, N, flags   ┌──▶ B: golpe_iniciado ──────────────▶ │ resuelve (Regla 3)
  severidades, patrones  │    B: ventana_especial_abierta ────▶ │   parry_resuelto (C-*)
                         │                                      │         │
                         │    ◀── C: parry_resuelto ────────────┘         │ llamada directa
                         │    ◀── C: castigo_iniciado ───────────────────┘ (mismo stack,
                         │                                                     ADR-001 §3)
                         └──▶ B: estado_ingresado ──▶ suscriptores SOLO-LECTURA
                              B: combo_abortado(i,N) ──▶ Feedback-4 + Sonoro-16
                              B: duelo_ganado ──▶ Run-3      C: duelo_perdido ──▶ Run-3
```

### Key Interfaces

```gdscript
# BossFSM — costura mínima que todo jefe implementa. Llamada directa (mecanismo)
# + señales B-* síncronas (observabilidad). Nunca una sin la otra.
class_name BossFSM
extends Node
signal golpe_iniciado(window_id: int, tick_apertura: int)
signal golpe_finalizado(window_id: int, tick_cierre: int)
signal ventana_especial_abierta(window_id: int, tick_apertura: int)
signal ventana_especial_cerrada(window_id: int, fue_parada: bool, tick_cierre: int)
signal combo_abortado(indice_i: int, longitud_n: int)
signal estado_ingresado(nuevo_estado: int, tick: int)
signal estado_abandonado(estado_previo: int, tick: int)
signal accion_especial_interrumpida(window_id: int, tick: int)
signal accion_especial_completada(habilidad_id: StringName, tick: int)  # 4ª pasada
signal duelo_ganado(tick: int)
func on_combat_result(res: Dictionary) -> void  # entrada ÚNICA desde el resolver
```

```gdscript
# Costura de test (cada AC nombra su lista compartida; el espía ya existe).
# C4a: tras resolución con postura 0 → nombres() == [.., PARRY_RESUELTO, ESTADO_INGRESADO(ATURDIDO)]
#      con CERO estado_ingresado(REPLIEGUE) y mismo_tick() entre ambos. Conteo, no estado final.
# E2:  empate interrupción/vencimiento → accion_especial_interrumpida emitida UNA vez,
#      accion_especial_completada CERO veces, mismo paso de resolución.
# C5a: EXITO_VENTANA_ESPECIAL → Gracia SÍ + hitstop SÍ (señales presentadas),
#      conteo de llamadas a dano_postura == 0 Y a repliegue == 0 (negativos explícitos).
# C3b: combo_abortado leído del evento: indice_i/longitud_n == (1,N),(mid,N),(N,N); N ∈ {3,5} bordes.
# C8:  EstadoJefe.values() == [0..8] mapeado por §4, por identidad (sustitución detectada).
```

### Implementation Guidelines

1. Conectar todas las B-* y C-* por defecto (síncronas). Un `CONNECT_DEFERRED`
   en este camino es violación de Regla 8, no estilo.
2. Emitir en el orden fijo §2-notas (cierre → resultado → transición). El
   orden es contrato: C4a lo asevera.
3. Payloads cerrados: ni un campo más sin enmienda bilateral. El hambre de
   "un datito extra" (p. ej. severidad dentro de `ventana_especial_abierta`)
   se resuelve leyendo configuración del sistema 20, no engordando señales.
4. Configs ilegales fallan al cargar con FAIL_LOAD (exit non-zero + ERROR +
   no arranca el duelo): `N ∉ 3..5` (C16/C7), VE sin ventana con flag
   (E1), ventana con flag `false` (C5d). Defensa en profundidad, no ramas
   runtime.
5. `window_id` opaco y monótono por duelo; se reinicia por duelo (congelar
   el jefe en derrota descarta el índice `i` en curso — Edge de derrota).
6. El mock del gate Logic (unit, `tests/unit/maquina-estados-jefe/`) inyecta
   `parry_resuelto` sintéticos; el gate Integration
   (`tests/integration/maquina-estados-jefe/`) cablea Combate real y asevera
   C4a + E2 fuera del mock — el mock sincrónico pasaría el gate 1 aunque la
   implementación real fuese asíncrona (nota del GDD, ratificada).

## Alternatives Considered

### Alternative 1: Solo llamada directa a método, sin señales

- **Description**: `resolver → jefe.on_combat_result()` y nada más; los
  suscriptores leen estado por polling o por callback registrado.
- **Pros**: Mínimo overhead; imposible emitir en orden incorrecto (no hay
  emisiones).
- **Cons**: C4a/E2/C5a/C3b quedan **sin forma de escribirse** (condición
  registrada por el propio espía). Un `Repliegue.on_enter()` transitorio
  que arranca timers/VFX antes de ser sobrescrito pasaría todos los tests
  de estado-final en verde con el bug presente — exactamente el modo de
  fallo que la Player Fantasy del sistema 2 declara como fracaso.
- **Estimated Effort**: Menor.
- **Rejection Reason**: Destruye la testabilidad del sistema de mayor
  riesgo técnico. Rechazada normativamente (§7 + costura de test).

### Alternative 2: Bus de eventos con cola ("casi inmediato")

- **Description**: Resolver publica en una cola; el FSM la vacía en su
  propio `_physics_process` (mismo tick en el caso feliz).
- **Pros**: Desacopla emisor y receptor; orden total gratis.
- **Cons**: Prohibido por propiedad (Regla 8: ejecución fuera del call
  stack de origen). El caso feliz es indistinguible del caso a un tick de
  retraso salvo por `process_physics_priority`, fácil de romper al
  reordenar la escena. El fallo es silencioso (un frame de `Repliegue`
  fantasma).
- **Estimated Effort**: Medio.
- **Rejection Reason**: Viola TR-jefe-002 y la Regla 8 por construcción.

### Alternative 3: El FSM posee el instante de resolución (dirección inversa)

- **Description**: El jefe detecta sus propios límites y llama a Combate
  para que resuelva ("¿me pararon?"), luego transiciona.
- **Pros**: Simétrico; el "emisor canónico" también resolvería.
- **Cons**: Combate posee el input, la ventana de parry, la calidad y la
  Postura — el FSM tendría que pedir prestado todo el estado del jugador
  para resolver, invirtiendo cuatro dependencias. El perdón de anticipación
  caso (b) nace en el polling del resolver, no en el FSM. Rompe la regla
  "cada evento lo emite quien posee el recurso".
- **Estimated Effort**: Mayor (reescritura de dependencias).
- **Rejection Reason**: Invierte la propiedad. La dirección Combate → FSM
  (ADR-001 §3) queda ratificada.

## Consequences

### Positive

- C4a, E2, C5a, C3b y C8 pasan de "verificación por contrato pendiente de
  mecanismo" a escribibles con la infra existente (`signal_order_spy` sin
  cambios; sus ejemplos `golpe_iniciado`/`parry_resuelto` se vuelven
  canónicos).
- C8 blinda el enum contra sustitución silenciosa (comparación por
  identidad + tabla ASCII cerrada): el décimo estado sin enmienda falla en
  rojo a propósito.
- `i`/`N` expuesto una sola vez, consumido por Feedback (escalera
  late=heavier, Regla 6) y Sonoro: se cierra la OQ de trazabilidad del
  sistema 2 (pregunta :996 de Feedback responde "aquí se consume").
- La reserva de `accion_especial_completada` impide divergencia de nombres
  antes de la 4ª pasada y deja C22/C5b-DEF desbloqueables sin renombrar.

### Negative

- **Rigidez bilateral**: añadir un campo a cualquier señal exige enmienda
  en dos GDDs (el emisor y todos los consumidores). Es fricción deliberada
  contra el engorde de payloads; se acepta.
- **Tres señales por resolución** (cierre → resultado → transición) en vez
  de una: overhead despreciable a 60 Hz, pero cada suscriptor debe
  documentar a cuál se conecta y por qué (checklist de historia).
- Se acepta una deuda de nombres: `estado_abandonado` es menos idiomático
  que `state_exited`, pero la convención español-dominio / inglés-motor
  prima la coherencia del dominio. Cambiarlo después rompería C4a/E2.

### Neutral

- El gate Logic con mocks sigue sin probar el cableado real (limitación
  declarada, no novedad): por eso el gate Integration existe y exige C4a +
  E2 fuera del mock, no solo el primero.
- E5 queda en "roto-por-diseño-futuro" documentado: ni este ADR ni la 4ª
  pasada lo cierran; lo cierra el sistema 19 reescribiéndolo.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Señal por defecto no es sincrónica-en-orden en 4.7 (cambio no documentado) | Baja | Alto (todo el contrato descansa aquí) | V1 (10 líneas) antes de la primera historia; si falla, Alternative 2 sigue prohibida — se escribe ADR superseded con barrera explícita |
| Un suscriptor futuro reentra (HUD que "confirma" escribiendo al FSM) | Media | Alto (secuencias con conteos duplicados que respetan orden — C4a pasaría) | Guarda `_en_resolucion` + counter observable (D3-pattern); C4a asevera **conteos**, no solo orden |
| Payloads engordan por presión de features (severidad, IDs de jefe, timers) | Alta | Medio (acoplamiento, C3b frágil) | Payloads cerrados + regla "leer config del 20"; `story-readiness` rechaza historias que añadan campos |
| `window_id` correlacionado mal entre apertura y resolución bajo stacking (`max()`) | Media | Medio (parry atribuido a ventana vieja) | Fusión nunca reordena: el resolver sella `window_id` vivo antes del freeze; test C2 de Feedback cubre mismo-tick |
| Colisión con sistema 19: daño fuera de Aturdido reutiliza `golpe_iniciado` por conveniencia | Media | Alto (E5 roto en silencio) | §6.5 normativo: eventos propios del 19; E5-test en rojo como alarma; runtime blando |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | N/A | 3 emisiones síncronas por resolución (~ns); spy solo en tests (strip en release) | 16.6 ms dock / 25 ms batería |
| Memory | N/A | Payloads por valor (ints/bool); `habilidad_id` StringName internado | 1.5 GB techo |
| Load Time | N/A | Validación FAIL_LOAD de configs ilegales (C16/C7/C5d/D13/C26) | Sin presupuesto propio |
| Network (if applicable) | N/A | N/A | N/A |

## Migration Plan

Sin código que migrar (cero señales en `src/` hoy). Aplicación en historias
(bloqueadas hasta `Accepted`):

1. Crear `src/ai/jefe/boss_fsm.gd` (o ruta que fije `lead-programmer`)
   con enum §4 + señales §2 + `on_combat_result()` + guarda §7. Verificar:
   C8 (identidad), C7 (N ilegal), C5d (VE ilegal).
2. Emitir `parry_resuelto` / `castigo_iniciado` / `duelo_perdido` desde el
   resolver con payloads §3. Verificar: C4 de Combate (instrumentado),
   C20 (2-de-4 con negativos en cero).
3. Cablear gates Logic (mocks) + Integration (C4a + E2 reales). Verificar:
   C4a/E2/C5a/C3b en verde, suite 62 sin regresión.
4. 4ª pasada del sistema 2 aplica §6 (E3b 114, completación + feedback,
   `castigo_conectado`, fila reversa).

**Rollback plan**: Los nombres son nuevos y nada los referencia: revertir es
borrar. Si V1 demuestra asincronía por defecto, este ADR pasa a `Superseded`
y se escribe ADR-002b (barrera de despacho explícita con prueba de orden).
La tabla §4 sobrevive a cualquier rollback de mecanismo.

## Validation Criteria

- [ ] **V1 (BLOCKING)**: señal por defecto en 4.7.2 invoca `Callable`s en
  orden de conexión dentro del mismo stack (test 10 líneas, 3 suscriptores
  + espía de lista compartida).
- [ ] **V2 (BLOCKING)**: C4a — secuencia capturada `[…, parry_resuelto,
  estado_ingresado(ATURDIDO)]`, cero `estado_ingresado(REPLIEGUE)`,
  `mismo_tick()` verdadero; el mutante "emite Repliegue y sobrescribe"
  falla en rojo (prueba de que el test caza el bug, no el estado final).
- [ ] **V3 (BLOCKING)**: E2 — empate interrupción/vencimiento:
  `accion_especial_interrumpida` ×1, `accion_especial_completada` ×0,
  mismo paso de resolución.
- [ ] **V4 (BLOCKING)**: C5a — las 4 consecuencias verificadas, las 2
  ausentes por conteo de llamadas en cero; C3b — payloads
  `(1,N)/(mid,N)/(N,N)` con N ∈ {3, 5} leídos del evento, no inferidos.
- [ ] **V5 (BLOCKING)**: C8 — sustitución de un valor del enum con conteo
  intacto (mutante) falla por identidad; sub-estados como campos, no como
  valores.
- [ ] **V6 (ADVISORY)**: revisión cruzada `godot-gdscript-specialist` de
  nombres/payloads (idioma, pasado, ASCII) antes de `Accepted`.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/maquina-estados-jefe.md` | Jefe, Regla 8 + OQ mecanismo | Resolución síncrona; nombres canónicos; mecanismo concreto | Llamada Combate → FSM + señales síncronas obligatorias; vía "solo método" rechazada; nombres §2/§3 |
| `design/gdd/maquina-estados-jefe.md` | Jefe, Regla 7 + C8 | Enum cerrado de 9; C8 comparable por identidad | Tabla §4 ASCII (espacios/tilde resueltos); sub-estados como campos |
| `design/gdd/maquina-estados-jefe.md` | Jefe, Reglas 2/3/4/5 + C4a/E2/C5a/C3b | Bifurcación, aborto con i/N, Aturdido-sin-preempción, VE 2-de-4, todo verificable por señales | Orden fijo cierre→resultado→transición; `combo_abortado(i,N)`; `postura_resultante`; negativos en cero |
| `design/gdd/combate-parry-absorcion.md` | Combate, Reglas 3/4 + C4/C19–C21/C25 | Ventana parable resoluble; paquete 4 vs 2-de-4 distinguible por evento | `resultado` con `EXITO_GOLPE` ≠ `EXITO_VENTANA_ESPECIAL`; `delta_ticks = -1` en VE (sin calidad, sin Justo, sin bono) |
| `design/gdd/combate-parry-absorcion.md` | Combate, Regla 5 + C11/C22 | Borde Castigo/Parry derivado; contacto vs pulsación | §5: press → Combate (114 inclusivo, nunca literal); contacto → sistema 2 (conexión gana) |
| `design/gdd/feedback-impacto.md` | Impacto, Regla 6 + C6-DEF | Aborto consume `i/N` con guardas | `combo_abortado` con rangos + RUNTIME_DROP; responde la OQ de trazabilidad del sistema 2 |

## Related

- ADR-001 (tiempo autoritativo y hitstop — aceptar en el mismo acto;
  fija dirección del stack, contadores y pausa 0% que este contrato usa)
- `tests/helpers/signal_order_spy.gd` (infra conservada sin cambios; sus
  ejemplos se adoptan como canónicos)
- `src/core/time_authority.gd` (su reescritura como WallTick/DiegeticTick
  es la que emitirá los `tick` de estos payloads)
- 4ª pasada del sistema 2 (aplica §6: E3b 114, completación + feedback,
  `castigo_conectado`, fila reversa) · Efectos de Estado (#19, rompe E5
  por diseño con el protocolo aquí ratificado) · stacking (`max()`,
  ADR-001 §5-fila 7: el `window_id` vivo se sella antes del freeze)

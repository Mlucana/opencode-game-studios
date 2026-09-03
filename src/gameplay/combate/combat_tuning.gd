class_name CombatTuning
extends Resource

## Knobs de tuning del Combate de Parry-Absorción, como datos.
##
## `coding-standards.md` exige que los valores de gameplay sean data-driven y
## nunca hardcodeados, y que las APIs públicas se inyecten en vez de vivir en
## singletons. Por eso las fórmulas de `combat_formulas.gd` reciben una
## instancia de esta clase en vez de leer constantes globales: un test puede
## instanciarla con los valores de lanzamiento o con cualquier esquina del
## espacio de tuning, que es exactamente lo que el AC **D9(b)** necesita para
## barrer 96 casos.
##
## CONTRATO DE UNIDADES. Todo lo temporal está en **ticks de simulación fija a
## 60Hz**, nunca en segundos ni en frames de render (Regla 2 del GDD). Los
## valores en segundos que aparecen en el GDD son derivados de legibilidad.
##
## Los rangos seguros por knob **no lo son en combinación**: ver las invariantes
## R1–R10 en el GDD. `combat_formulas.gd` expone los predicados que las evalúan.

# ─── Fórmula 1 — Daño de Postura ────────────────────────────────────────────

## Daño de Postura fijo por cualquier parry exitoso. Rango seguro 8–15.
@export var dano_base: float = 10.0

## Ancho de la escala de calidad, en TICKS. Rango seguro 3–7.
## Canonicalizado a ticks en el changeset 2 ítem 1: era la última duración del
## documento declarada en segundos (0.08s = 4.8 ticks, no entero).
@export var umbral_precision: int = 5

## Multiplicador de recompensa por Parry Justo. Rango seguro 0.3–0.5.
@export var bono_precision: float = 0.4

## Valor de `calidad_timing` a partir del cual un parry es "Justo".
## Rango seguro 0.7–1.0. Se expresa en CALIDAD, nunca en ticks.
@export var umbral_parry_justo: float = 0.9

# ─── Fórmula 2 — Postura máxima ─────────────────────────────────────────────

## Postura de la tríada de índice 0. Rango seguro 20–40.
@export var postura_base: int = 30

## Postura añadida por escalón de tríada. Rango seguro 5–15.
@export var incremento_postura_triada: int = 10

# ─── Fórmula 3 — Ciclos objetivo ────────────────────────────────────────────

## Término base de la Fórmula 3. **Constante forzada por R3**: con la estructura
## `base + índice_tríada`, 4 es el único valor que satisface 4 ≤ ciclos ≤ 6 para
## las tres tríadas a la vez.
@export var ciclos_objetivo_base: int = 4

# ─── Fórmula 5 — Vida máxima del jugador ────────────────────────────────────

## Vida al inicio de cada run. Rango seguro POR KNOB 80–150, pero acoplado a
## `bono_vida_por_absorcion` por R5: suelos efectivos 110 (todo el rango del
## bono) y 82 (solo el suelo del bono).
@export var vida_base: int = 100

## Vida máxima ganada por cada absorción. **El knob más delicado del juego.**
## Rango canónico 15–20.
@export var bono_vida_por_absorcion: int = 18

## Ángeles absorbibles en una run. 3 en v1.0/Alpha. R5 solo está calibrada aquí.
@export var angeles_max: int = 3

# ─── Fórmula 6 — Daño del Golpe de Castigo ──────────────────────────────────

## Gancho hacia Elección de Reliquias. **Constante 1.0 por R4**, cerrada en
## ambos sentidos: por arriba rompe el suelo de ciclos, por abajo vuelve el
## duelo inganable siendo el Castigo la única fuente de daño del jugador.
@export var multiplicador_ataque: float = 1.0

# ─── Fórmula 8 — Daño de Golpe enemigo ──────────────────────────────────────

## `Golpe`s no parados que matan a un jugador a Vida BASE. Rango seguro 3–6.
## Es el presupuesto de error del duelo.
@export var golpes_para_morir_base: int = 4

# ─── Ventanas y recuperaciones (ticks) ──────────────────────────────────────

## Duración del estado PARRY. Rango seguro 9–18 ticks.
@export var parry_window: int = 13

## Bloqueo tras un parry vacío. Rango seguro 6–12 ticks. **Por debajo de 6 la
## cobertura temporal vuelve a superar el 68% y el mash reaparece**: es un suelo
## duro, no una preferencia.
@export var recuperacion_whiff: int = 9

## Recuperación tras un parry EXITOSO. **PROVISIONAL — hallazgo sin cerrar.**
##
## El GDD la declara como "2–3 fotogramas" en Animation Feel Targets y el AC C10
## asevera sobre ella, pero **no tiene símbolo, ni dueño, ni rango declarado** en
## Tuning Knobs: es el mismo defecto DE TIPO que tuvo `recuperacion_recepcion`
## antes de la enmienda C — un contrato que nombra algo que no existe.
##
## Se fija en **3** (el techo del rango en prosa) por la misma regla de consumo
## que `recuperacion_recepcion`: toda invariante de la forma "el jugador debe
## tener tiempo de reaccionar" se evalúa en el **peor caso de compromiso**.
## Registrado para la próxima pasada; no se cierra en la sesión que lo encuentra.
@export var recuperacion_exito: int = 3

## Ventana de Aturdimiento. Rango seguro 72–180 ticks.
@export var ventana_castigo: int = 120

## Ticks finales de `ventana_castigo` en que la pulsación vuelve a ser Parry.
## Rango seguro 4–10 ticks.
@export var gracia_salida_castigo: int = 6

## Hitstop de parry exitoso. Rango seguro 3–6 ticks (techo recortado por R8).
@export var hitstop_parry: int = 5

## Extensión del hitstop en un Parry Justo, en su escalón máximo.
## Acotado por R8: `hitstop_parry + bono ≤ 8`.
@export var bono_hitstop_parry_justo: int = 2

# ─── Fórmula 7 — Gracia por parry ───────────────────────────────────────────

## Modulador de gracia dentro de un combo. Rango seguro 0.35–0.8.
## **Por debajo de 1/3 un combo de 3 da menos gracia que un golpe simple** y la
## garantía de la Regla 9 se rompe (R7).
@export var modificador_combo_gracia: float = 0.5

## Longitud mínima legal de combo, impuesta por este GDD al sistema 20 (R7).
@export var n_min_combo: int = 3

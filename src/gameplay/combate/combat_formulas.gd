class_name CombatFormulas
extends RefCounted

## Fórmulas del Combate de Parry-Absorción, como funciones puras.
##
## ALCANCE DELIBERADO. Aquí solo vive aritmética: nada de estado, nada de
## señales, nada de `_physics_process`. Es la parte del sistema 1 que **no
## depende del ADR de la Regla 8 ni de la autoridad de tiempo**, y por tanto la
## única implementable hoy sin riesgo de reescritura. La resolución del parry, el
## hitstop y el orden de transiciones NO van aquí y no deben añadirse hasta que
## ese ADR exista.
##
## Todas las funciones reciben un `CombatTuning` — inyección de dependencia en
## vez de singleton, y ningún literal de gameplay en el cuerpo.
##
## Referencias a las fórmulas y ACs del GDD `design/gdd/combate-parry-absorcion.md`.

const EPSILON: float = 1e-6


# ─── Fórmula 1 — Daño de Postura por parry exitoso ──────────────────────────

## `calidad_timing` — cantidad **escalonada por ticks**, no continua.
##
## `delta_ticks` es la distancia en TICKS ENTEROS entre el tick de detección del
## input y el tick de inicio del **`Golpe`**. Se cuantifica sobre `Golpe`, nunca
## sobre toda ventana parable: un parry contra una Ventana Especial no aplica
## daño de Postura (Regla 4), así que no tiene calidad y no puede ser Justo.
##
## El término `− 0.5` compensa el sesgo de muestreo: detectar en el tick `T`
## implica que la pulsación ocurrió en `(T−1, T]`, así que el delta medido
## sobrepasa al real medio tick de media, siempre en la dirección que castiga.
##
## Con `umbral_precision = 5` produce exactamente 7 escalones:
## 1.0 · 0.9 · 0.7 · 0.5 · 0.3 · 0.1 · 0.0 (AC **D1**).
## Que aparezca un valor intermedio es prueba directa de una implementación por
## reloj real, que la Regla 2 prohíbe (AC **D14**).
static func calidad_timing(delta_ticks: int, t: CombatTuning) -> float:
	var bruto: float = 1.0 - (float(delta_ticks) - 0.5) / float(t.umbral_precision)
	return clamp(bruto, 0.0, 1.0)


## Daño de Postura de un parry exitoso resuelto contra un `Golpe`.
## En combos se aplica UNA sola vez, con la calidad del ÚLTIMO parry (Regla 9).
static func postura_dano(delta_ticks: int, t: CombatTuning) -> float:
	return t.dano_base * (1.0 + calidad_timing(delta_ticks, t) * t.bono_precision)


## `true` si el parry se clasifica como **Parry Justo**: el predicado único del
## que dependen la esquirla `#FFF8E7`, la capa de audio del evento 4 y el bono
## de hitstop (AC **C25**). Solo aplica a parries contra `Golpe`.
static func es_parry_justo(delta_ticks: int, t: CombatTuning) -> bool:
	return calidad_timing(delta_ticks, t) >= t.umbral_parry_justo - EPSILON


## Ticks de hitstop extra por precisión: +2 en calidad 1.0, +1 en 0.9, +0 debajo.
## Siempre cumple R8 (`hitstop_parry + bono ≤ 8`).
static func bono_hitstop(delta_ticks: int, t: CombatTuning) -> int:
	if not es_parry_justo(delta_ticks, t):
		return 0
	var calidad: float = calidad_timing(delta_ticks, t)
	if calidad >= 1.0 - EPSILON:
		return t.bono_hitstop_parry_justo
	return t.bono_hitstop_parry_justo - 1


# ─── Fórmula 2 — Postura máxima por tríada ──────────────────────────────────

static func postura_max(indice_triada: int, t: CombatTuning) -> int:
	return t.postura_base + t.incremento_postura_triada * indice_triada


## Parries necesarios para romper la Postura, evaluados a `calidad_timing = 0`.
## Es la magnitud que **R10c** cierra frente al sistema 9: 3/4/5 exactos.
## Se evalúa al suelo de calidad a propósito — que un jugador encadene Parries
## Justos y rompa Cosmos en 3 en vez de 4 es **maestría, no una reliquia**.
static func parries_por_ciclo(indice_triada: int, t: CombatTuning) -> int:
	return int(ceil(float(postura_max(indice_triada, t)) / t.dano_base))


# ─── Fórmula 3 — Ciclos objetivo y % de daño de Castigo ─────────────────────

static func ciclos_objetivo(indice_triada: int, t: CombatTuning) -> int:
	return t.ciclos_objetivo_base + indice_triada


static func punish_dano_pct(indice_triada: int, t: CombatTuning) -> float:
	return 100.0 / float(ciclos_objetivo(indice_triada, t))


# ─── Fórmula 5 — Vida máxima del jugador ────────────────────────────────────

static func vida_maxima(angeles_absorbidos: int, bono_reliquias: int, t: CombatTuning) -> int:
	return t.vida_base + angeles_absorbidos * t.bono_vida_por_absorcion + bono_reliquias


# ─── Fórmula 6 — Daño real del Golpe de Castigo ─────────────────────────────

static func dano_golpe_castigo(vida_max_angel: int, indice_triada: int, t: CombatTuning) -> float:
	return float(vida_max_angel) * (punish_dano_pct(indice_triada, t) / 100.0) * t.multiplicador_ataque


# ─── Fórmula 8 — Daño de Golpe enemigo ──────────────────────────────────────

## Se ancla en `vida_base`, **nunca en `vida_maxima`**: si escalase con la
## máxima, absorber no compraría supervivencia y el pivote mecánico del dilema
## moral quedaría decorativo (AC **D11**).
## No escala por tríada y no admite multiplicador por tipo de ataque.
##
## División directa y no `vida_base × (pct/100)`: la forma en porcentaje es la
## que obligó a escribir el clamp de la Vida del jefe.
static func dano_golpe_enemigo(t: CombatTuning) -> float:
	return float(t.vida_base) / float(t.golpes_para_morir_base)


# ─── Clamps de recursos agotables ───────────────────────────────────────────

## Aplica daño a un recurso agotable con clamp a 0.
##
## Simetría estricta entre los tres recursos del sistema: Postura (**E5**), Vida
## del jefe (**E12**) y Vida del jugador (**E13**). El exceso no se transfiere,
## no se acumula y no produce efecto. Un residuo `≤ 1e-6` se trata como 0, de
## modo que `== 0` es una condición **exacta** y no hace falta comparar `< 0`
## en ningún sitio — que es lo que hace construibles los fixtures de E7 y E11.
static func aplicar_dano(valor_actual: float, dano: float) -> float:
	var resultado: float = valor_actual - dano
	if resultado < EPSILON:
		return 0.0
	return resultado


# ─── R10a — Magnitud de supervivencia ───────────────────────────────────────

## `Golpe`s no parados que matan al jugador desde Vida llena.
##
## Es la magnitud sobre la que **R10a** restringe al sistema 9, y la unidad en
## la que el jugador percibe el swing de corrupción — no los puntos de Vida, que
## es lo que R5 medía. El redondeo hacia arriba importa: 154/25 = 6.16 son
## **7** golpes, no 6.
## `reduccion_dano` es la fracción de daño recibido que las reliquias eliminan
## (0.0 = ninguna, 0.20 = −20%). Entra aquí y no en otro sitio porque **es la
## misma magnitud**: una reliquia de Vida y una de reducción de daño compran
## exactamente lo mismo —golpes— y R10a las acota juntas. Era el cuarto agujero
## del contrato con el sistema 9, y no existía hasta que la Fórmula 8 lo creó.
static func golpes_sobrevividos(
		angeles_absorbidos: int,
		bono_reliquias: int,
		t: CombatTuning,
		reduccion_dano: float = 0.0) -> int:
	var vida: int = vida_maxima(angeles_absorbidos, bono_reliquias, t)
	var dano: float = dano_golpe_enemigo(t) * (1.0 - reduccion_dano)
	return int(ceil(float(vida) / dano))


## `true` si una configuración de reliquias respeta **R10a**: no compra más de
## UN golpe sobrevivido, **para las cuatro cuentas de absorción**.
##
## La cuenta vinculante es la de **0 absorciones** (+25 de Vida con los valores
## de lanzamiento); a 3 absorciones la misma invariante dejaría +46. Un test que
## solo midiera al jugador totalmente absorbido dejaría pasar casi el doble de
## lo legal — por eso este predicado barre el rango entero y no acepta un caso.
static func cumple_r10a(
		bono_reliquias: int,
		t: CombatTuning,
		reduccion_dano: float = 0.0) -> bool:
	for absorbidos in range(t.angeles_max + 1):
		var con_reliquias: int = golpes_sobrevividos(absorbidos, bono_reliquias, t, reduccion_dano)
		var sin_reliquias: int = golpes_sobrevividos(absorbidos, 0, t, 0.0)
		if con_reliquias - sin_reliquias > 1:
			return false
	return true


# ─── Invariantes conjuntas (R1–R8) — predicados para D9 ─────────────────────

## R1 — un solo Parry Justo no puede romper la Postura entera.
static func cumple_r1(t: CombatTuning) -> bool:
	return t.dano_base * (1.0 + t.bono_precision) < float(t.postura_base)


## R2 — la ventana de parry debe ser más ancha que la escala de calidad.
## Comparación **entera**: ambos knobs están en ticks y el `× 60` desapareció.
static func cumple_r2(t: CombatTuning) -> bool:
	return t.parry_window > 2 * t.umbral_precision


## R4 — `multiplicador_ataque` es exactamente 1.0, cerrado en ambos sentidos.
static func cumple_r4(t: CombatTuning) -> bool:
	return absf(t.multiplicador_ataque - 1.0) < EPSILON


## R5 — el swing de absorción no puede exceder el 55% de la Vida base.
static func cumple_r5(t: CombatTuning) -> bool:
	return float(t.bono_vida_por_absorcion * t.angeles_max) / float(t.vida_base) <= 0.55 + EPSILON


## R6 — cobertura temporal del parry ≤ 65%. El cierre del mash.
static func cobertura_temporal(t: CombatTuning) -> float:
	return float(t.parry_window) / float(t.parry_window + t.recuperacion_whiff)


static func cumple_r6(t: CombatTuning) -> bool:
	return cobertura_temporal(t) <= 0.65 + EPSILON


## R7 — un combo genera más gracia total que un golpe simple.
static func cumple_r7(t: CombatTuning) -> bool:
	return t.modificador_combo_gracia > 1.0 / float(t.n_min_combo)


## R8 — el hitstop total no entrecorta el flujo del combate.
static func cumple_r8(t: CombatTuning) -> bool:
	return t.hitstop_parry + t.bono_hitstop_parry_justo <= 8


## Borde de la ventana de gracia de salida del Aturdimiento (**C11**).
## **No devolver 114 como literal**: se deriva de dos knobs configurables y se
## mueve con cualquier retune.
static func t_max_castigo(t: CombatTuning) -> int:
	return t.ventana_castigo - t.gracia_salida_castigo

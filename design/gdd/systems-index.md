# Systems Index: NOVENA

> **Estado**: Aprobado
> **Creado**: 2026-07-31
> **Última actualización**: 2026-09-04 (sistema 1 **Approved sin re-review por decisión de usuario** — 8ª pasada MAJOR con CS8 aplicado; precedente #4/#12/#15. **Máquina de Estados de Jefe (2) pendiente de re-review**.)
>
> **Actualización anterior**: 2026-08-04 (**3ª pasada** de `/design-review` sobre el sistema 2 — veredicto **MAJOR REVISION NEEDED**. **El orden de diseño cambia: el sistema 1 va ahora por delante del 2.** Los 13 "descendientes" de la 2ª pasada se reagruparon en **5 raíces**, y **3 de ellas viven total o parcialmente en el sistema 1**, así que seguir iterando el 2 es iterar sobre el síntoma. El sistema 2 queda **CONGELADO**; el sistema 1 pierde su estado Aprobado hasta pasar su primera revisión adversarial. Ver `design/gdd/reviews/maquina-estados-jefe-review-log.md` para el plan de 5 fases, las adjudicaciones D1–D4 —incluida la **reversión del borde de Castigo de 113 a 114**, un arreglo de la 2ª pasada que estaba invertido— y el hallazgo de proceso)
> **Concepto fuente**: design/gdd/game-concept.md

---

## Overview

NOVENA es un roguelike de duelos de precisión (boss-rush) cuyo alcance mecánico
gira en torno a tres ejes: un **combate de parry-absorción** ya validado por
prototipo (72% de acierto), un **sistema de Gracia de tres capas** que convierte
cada victoria en un costo sobre quién es el protagonista (Pilar 1), y una
**estructura de ascenso por 9 coros angelicales** con un jefe final de dos formas
(Lucifer). El alcance de producción real para la versión 1.0 son 3 coros
implementados con roster completo diseñado en papel — no los 9 coros ni los hasta
27 jefes de la visión completa. Los sistemas de este índice están calibrados contra
las Niveles de Alcance ya fijados en `game-concept.md` (MVP → Slice Vertical →
Alpha → Visión Completa).

---

## Systems Enumeration

| # | Sistema | Categoría | Prioridad | Estado | Doc de Diseño | Depende de |
|---|---|---|---|---|---|---|
| 1 | Combate de Parry-Absorción | Core | MVP | Approved (8ª pasada MAJOR → CS8 aplicado; aceptado sin re-review por decisión de usuario 2026-09-04) | design/gdd/combate-parry-absorcion.md | Sistema de Gracia (blando/circular, ver nota), Elección de Reliquias (blando), **Máquina de Estados de Jefe (2) — bidireccional: el 2 es el emisor canónico de sus eventos de ventana activa** — **impone restricciones a Reliquias (`multiplicador_ataque = 1.0` constante, R6 sobre modificadores de ventana), a IA de Jefes (`3 ≤ N ≤ 5`, varianza intra-combo, cadencia del tutorial), a Feedback Sonoro (precedencia armónica) y a Accesibilidad (2 knobs como par)** |
| 2 | Máquina de Estados de Jefe (flujo base) (inferido) | Core | MVP | Needs Revision | design/gdd/maquina-estados-jefe.md | Combate de Parry-Absorción (dura), IA de Combate de Jefes (blanda/circular, ver Circular Dependencies) — **impone a IA de Jefes: conjunto cerrado de 9 estados top-level (Regla 7, con procedimiento de enmienda), resolución síncrona (Regla 8), piso de justicia `Enfriamiento + Telegrafiado ≥ 12 + margen` (Regla 9), y Ventana Especial de evento propio, obligatoria bajo `interrumpible_por_parry = true` y prohibida bajo `false` (Regla 5)**; **impone a Combate (1): la excepción de Ventana Especial en su Regla 4**; **impone a Lucifer (11): extensión como sub-estado anidado, no estado top-level nuevo** |
| 3 | Gestión de Run / Estructura de Ascenso (inferido) | Core | Vertical Slice | Not Started | — | Máquina de Estados de Jefe |
| 4 | Feedback de Impacto (Hitstop/Cámara) (inferido) | Gameplay | MVP | Approved (2ª pasada adversarial 2026-09-04 + rev2; ver `reviews/feedback-impacto-review-log.md`) | design/gdd/feedback-impacto.md | Combate de Parry-Absorción |
| 5 | Sistema de Gracia de Tres Capas | Gameplay | MVP | Designed (retrofit 2026-09-04: 8/8 + Visual/UI/AC/OQ en disco; pendiente design-review en fresh session) | design/gdd/gracia-tres-capas.md | Combate de Parry-Absorción, Máquina de Estados de Jefe — **📌 UX Flag: pantalla Decisión con UI real → `/ux-design` (`design/ux/decision-gracia.md`) antes de épicas** |
| 6 | Clímax de Saturación | Gameplay | Vertical Slice | Not Started | — | Sistema de Gracia de Tres Capas |
| 7 | Overlay de Corrupción del Protagonista | Gameplay | Vertical Slice | Not Started | — | Sistema de Gracia de Tres Capas |
| 8 | Marchitamiento Ambiental | Gameplay | Vertical Slice | Not Started | — | Gestión de Run |
| 9 | Elección de Reliquias entre Duelos | Gameplay | Vertical Slice | Not Started | — | Gestión de Run |
| 10 | Meta-progresión de Llaves y Desbloqueo | Progression | Alpha | Not Started | — | Máquina de Estados de Jefe, Guardado de Progreso |
| 11 | Lucifer — Dos Formas y Reactividad | Gameplay | Full Vision | Not Started | — | Máquina de Estados de Jefe, Overlay de Corrupción, IA de Combate de Jefes |
| 12 | Guardado de Progreso (inferido) | Persistence | Alpha | Approved (Rev 2 — 2026-09-04: `/design-review --depth full` MAJOR con 12 bloques → revisión conjunta adjudicada; re-review omitida por decisión de usuario) | design/gdd/guardado-de-progreso.md | — **📌 UX Flag: requiere `/ux-design` antes de escribir épicas (fachada publicada en §Fachada; contraparte pendiente en #15 Rev 2)** |
| 13 | HUD de Combate | UI | MVP | Not Started | — | Combate de Parry-Absorción, Sistema de Gracia — **📌 UX Flag: requiere `/ux-design` antes de escribir épicas** |
| 14 | Pantalla de Elección de Reliquias (inferido) | UI | Vertical Slice | Not Started | — | Elección de Reliquias entre Duelos |
| 15 | Menú Principal y Flujo de Pantallas (inferido) | UI | Vertical Slice | Approved (design-review full 2026-09-04: MAJOR → Rev2, aceptado sin re-review) | design/gdd/menu-principal-y-flujo-de-pantallas.md | Guardado de Progreso -dura-, Gestión de Run -dura-, HUD/Reliquias/Gracia -blandas- — **📌 UX Flag: specs por pantalla vía `/ux-design` en Pre-Producción** |
| 16 | Feedback Sonoro del Parry (inferido) | Audio | MVP | Not Started | — | Combate de Parry-Absorción |
| 17 | Fragmentos de Memoria (esposa/hija) | Narrative | Vertical Slice | Not Started | — | Gestión de Run, Hub y Acumulación Visual |
| 18 | Hub y Acumulación Visual | Narrative | Vertical Slice | Not Started | — | Gestión de Run, Sistema de Gracia |
| 19 | Sistema de Efectos de Estado | Gameplay | Alpha | Not Started | — | Combate de Parry-Absorción, IA de Combate de Jefes |
| 20 | IA de Combate de Jefes — Patrones de Ataque y Movimiento | Gameplay | MVP | Not Started | — | Máquina de Estados de Jefe |
| 21 | Accesibilidad (inferido) | Meta | Alpha | Not Started | — | Combate de Parry-Absorción, HUD de Combate |

---

## Categories

| Categoría | Descripción | Sistemas típicos en NOVENA |
|---|---|---|
| **Core** | Sistemas fundacionales de los que todo depende | Combate de Parry-Absorción, Máquina de Estados de Jefe, Gestión de Run |
| **Gameplay** | Los sistemas que hacen divertido al juego | Gracia, Clímax de Saturación, Overlay de Corrupción, Marchitamiento, Reliquias, Lucifer, Efectos de Estado, IA de Jefes |
| **Progression** | Cómo crece el jugador con el tiempo | Meta-progresión de Llaves |
| **Persistence** | Estado de guardado y continuidad | Guardado de Progreso |
| **UI** | Pantallas de información al jugador | HUD de Combate, Pantalla de Reliquias, Menú Principal |
| **Audio** | Sistemas de sonido y música | Feedback Sonoro del Parry |
| **Narrative** | Entrega de historia y diálogo | Fragmentos de Memoria, Hub y Acumulación Visual |
| **Meta** | Sistemas fuera del bucle central | Accesibilidad |

*(Categorías "Economy" no aplica — NOVENA no tiene economía de crafteo/comercio; las
Reliquias se tratan como Gameplay, no como Economy.)*

---

## Priority Tiers

| Tier | Definición | Hito objetivo |
|---|---|---|
| **MVP** | Necesario para que el bucle central funcione; sin esto no se puede probar "¿es divertido?" | Prototipo jugable / validación de hipótesis |
| **Vertical Slice** | Necesario para una experiencia completa y pulida en un área | Slice vertical / demo |
| **Alpha** | Todas las funcionalidades presentes en forma rugosa; alcance mecánico completo | Hito de Alpha (3 coros, v1.0) |
| **Full Vision** | Pulido, casos límite, contenido completo | Beta / Release (9 coros, roster completo) |

---

## Dependency Map

### Capa Fundación (sin dependencias *estructurales* bloqueantes)

1. **Combate de Parry-Absorción** — el verbo central; sus reglas núcleo (parry,
   postura, castigo) no requieren que ningún otro sistema exista primero. Tiene
   una dependencia *blanda* y circular hacia Sistema de Gracia (5) y Elección de
   Reliquias (9) solo para su Fórmula 5 (Vida Máxima) — ver Circular
   Dependencies. Esa fórmula puede implementarse con valores por defecto
   (`angeles_absorbidos=0`, `bono_reliquias=0`) hasta que esos sistemas existan.
2. **Máquina de Estados de Jefe (flujo base)** — el otro lado del duelo
12. **Guardado de Progreso** — utilidad de bajo nivel para persistir estado
15. **Menú Principal y Flujo de Pantallas** — gestión de destinos; depende dura de Guardado (#12: S0–S5 + resumen) y Run (#3: handshake), blanda de HUD/Reliquias/Gracia

### Capa Núcleo (depende de Fundación)

4. **Feedback de Impacto (Hitstop/Cámara)** — depende de: Combate de Parry-Absorción
5. **Sistema de Gracia de Tres Capas** — depende de: Combate de Parry-Absorción, Máquina de Estados de Jefe
16. **Feedback Sonoro del Parry** — depende de: Combate de Parry-Absorción
20. **IA de Combate de Jefes** — depende de: Máquina de Estados de Jefe
19. **Sistema de Efectos de Estado** — depende de: Combate de Parry-Absorción, IA de Combate de Jefes

### Capa Feature (depende de Núcleo)

3. **Gestión de Run / Estructura de Ascenso** — depende de: Máquina de Estados de Jefe
6. **Clímax de Saturación** — depende de: Sistema de Gracia
7. **Overlay de Corrupción del Protagonista** — depende de: Sistema de Gracia
8. **Marchitamiento Ambiental** — depende de: Gestión de Run
9. **Elección de Reliquias entre Duelos** — depende de: Gestión de Run
10. **Meta-progresión de Llaves** — depende de: Máquina de Estados de Jefe, Guardado de Progreso
11. **Lucifer — Dos Formas y Reactividad** — depende de: Máquina de Estados de Jefe, Overlay de Corrupción, IA de Combate de Jefes
17. **Fragmentos de Memoria** — depende de: Gestión de Run, Hub y Acumulación Visual
18. **Hub y Acumulación Visual** — depende de: Gestión de Run, Sistema de Gracia

### Capa Presentación (depende de Feature)

13. **HUD de Combate** — depende de: Combate de Parry-Absorción, Sistema de Gracia
14. **Pantalla de Elección de Reliquias** — depende de: Elección de Reliquias entre Duelos

### Capa Pulido

21. **Accesibilidad** — depende de: Combate de Parry-Absorción, HUD de Combate

---

## Recommended Design Order

| Orden | Sistema | Prioridad | Capa | Agente(s) | Esfuerzo Est. |
|---|---|---|---|---|---|
| 1 | Combate de Parry-Absorción | MVP | Fundación | systems-designer | S |
| 2 | Máquina de Estados de Jefe | MVP | Fundación | systems-designer | M |
| 3 | Feedback de Impacto (Hitstop) | MVP | Núcleo | game-designer | S |
| 4 | Sistema de Gracia de Tres Capas | MVP | Núcleo | systems-designer | L |
| 5 | IA de Combate de Jefes | MVP | Núcleo | systems-designer | L |
| 6 | Feedback Sonoro del Parry | MVP | Núcleo | game-designer | S |
| 7 | HUD de Combate | MVP | Presentación | ux-designer | S |
| 8 | Gestión de Run / Ascenso | Vertical Slice | Feature | game-designer | M |
| 9 | Clímax de Saturación | Vertical Slice | Feature | game-designer | M |
| 10 | Overlay de Corrupción | Vertical Slice | Feature | systems-designer | M |
| 11 | Marchitamiento Ambiental | Vertical Slice | Feature | game-designer | S |
| 12 | Elección de Reliquias entre Duelos | Vertical Slice | Feature | systems-designer | L |
| 13 | Hub y Acumulación Visual | Vertical Slice | Feature | game-designer | M |
| 14 | Fragmentos de Memoria | Vertical Slice | Feature | narrative-director | M |
| 15 | Pantalla de Elección de Reliquias | Vertical Slice | Presentación | ux-designer | S |
| 16 | Menú Principal y Flujo de Pantallas | Vertical Slice | Fundación | ux-designer | S |
| 17 | Guardado de Progreso | Alpha | Fundación | game-designer | S |
| 18 | Meta-progresión de Llaves | Alpha | Feature | systems-designer | M |
| 19 | Sistema de Efectos de Estado | Alpha | Núcleo | systems-designer | M |
| 20 | Accesibilidad | Alpha | Pulido | accessibility-specialist | S |
| 21 | Lucifer — Dos Formas y Reactividad | Full Vision | Feature | systems-designer | L |

---

## Circular Dependencies

Se evaluó explícitamente si Gestión de Run (3) y Meta-progresión de Llaves (10)
formaban un ciclo — se resolvió que Gestión de Run **no** necesita las llaves para
seleccionar representantes (el jugador puede enfrentar cualquier coro sin la llave;
solo no puede derrotarlo sin ella). Esa es una regla de balance de combate, no una
dependencia estructural entre sistemas.

**Ciclo real identificado y documentado** (durante la autoría del GDD de Combate de
Parry-Absorción, 2026-07-31): **Combate de Parry-Absorción (1) ↔ Sistema de Gracia
de Tres Capas (5)**.
- Gracia (5) consume el evento "parry exitoso" de Combate (1) — dependencia
  original, ya reflejada en la Capa Núcleo.
- Combate (1) ahora también consume `angeles_absorbidos` (un conteo expuesto por
  Gracia) para su Fórmula 5 (Vida Máxima del Jugador) — dependencia nueva.

**Resolución**: no se rompe el ciclo estructuralmente porque no hace falta —
ambos sistemas se diseñan mediante un **contrato de datos explícito** (cada GDD
declara qué expone y qué consume del otro, sin necesitar leer el archivo del otro
para poder escribirse). Combate de Parry-Absorción ya documentó su mitad del
contrato (Fórmula 5, Dependencies). Cuando se autore el GDD de Gracia, debe
declarar simétricamente: (a) que expone `angeles_absorbidos` como salida pública, y
(b) que consume el evento "parry exitoso" como entrada. Combate también ahora
depende de Elección de Reliquias (9) para `bono_reliquias` y
`multiplicador_ataque` — no crea ciclo adicional (Reliquias no depende de Combate).

**Segundo ciclo identificado** (durante la autoría del GDD de Máquina de
Estados de Jefe, 2026-08-01): **Máquina de Estados de Jefe (2) ↔ IA de Combate
de Jefes (20)**, asimétrico. IA (20) depende de este sistema (dura) para el
conjunto cerrado de 9 estados top-level (Reposo, Telegrafiado, Golpe, En Combo,
Repliegue, Enfriamiento, Aturdido, Acción Especial, Muerto). Máquina de Estados
(2) depende de IA (blanda) para las duraciones concretas de
Telegrafiado/Golpe/Enfriamiento y la composición de patrones — puede operar con
valores de placeholder hasta que IA exista, igual que Combate opera con
`angeles_absorbidos=0` antes de que exista Gracia. Mismo patrón de resolución:
contrato de datos explícito, sin necesidad de romper el ciclo
estructuralmente.

---

## High-Risk Systems

| Sistema | Tipo de Riesgo | Descripción | Mitigación |
|---|---|---|---|
| IA de Combate de Jefes (habilidad de curación) | Diseño **+ balance** | Dos mitades. **Cualitativa**: un jefe con curación en un roguelike de un solo intento por vida puede sentirse como estancamiento infinito si cura sin castigo. **Cuantitativa** (identificada por `systems-designer` en la 2ª pasada del sistema 2): una curación que restaure Vida más deprisa de lo que el jugador puede quitarla hace el duelo **mecánicamente inganable** sin violar ninguna fórmula individual — el mismo modo de fallo que `multiplicador_ataque → 0`, por el extremo opuesto, y la única contingencia de alcanzabilidad de `Muerto` que no cubre la invariante R4 de Combate | La mitad cualitativa ya tiene vía: la **Ventana Especial** del sistema 2 (Core Rule 5) — obligatoria bajo `interrumpible_por_parry = true`, con evento propio, y sin dañar al jugador si se falla. La cuantitativa sigue abierta: el sistema 20 debe acotar la tasa de curación contra `dano_golpe_castigo` al autorar cualquier patrón que la use |
| Sistema de Efectos de Estado | Diseño | "Veneno" es un efecto tradicionalmente asociado a corrupción/malicia; choca con el Pilar 5 (los ángeles son genuinamente buenos, nunca corruptos) | Adaptar el vocabulario de efectos por tríada (ej. quemadura=Serafines) en vez de un veneno genérico, al autorar el GDD |
| Overlay de Corrupción del Protagonista | Técnico | Compositing de decals en tiempo real sobre 4-6 puntos de anclaje — ya señalado en el art bible como seguro solo si se recompone en eventos de cambio de estado, no cada frame | Prototipar el pipeline de compositing en Godot antes de comprometerse a la implementación final; coordinar con `technical-artist` |
| Lucifer — Dos Formas y Reactividad | Técnico + Alcance | Sistema reactivo que lee el mapa de corrupción del jugador y lo reproyecta en tiempo real; el art bible ya identificó 5 shaders simultáneos en este combate como el peor caso de rendimiento del juego | Verificar el combo de shaders en hardware real de Steam Deck; considerar una versión simplificada de la reactividad si el rendimiento no alcanza 60fps |
| Sistema de Gracia de Tres Capas | Diseño | Elección + acumulación + recurso gastable son tres sistemas superpuestos; el riesgo no es que sea injusto, es que el jugador no entienda qué le está pasando (ya señalado como mayor deuda de diseño en `game-concept.md`) | Prototipar la legibilidad del sistema (no solo la mecánica) con playtesters externos antes de cerrar el GDD |

---

## Progress Tracker

| Métrica | Cuenta |
|---|---|
| Sistemas totales identificados | 21 |
| Docs de diseño iniciados | 6 |
| Docs de diseño revisados | 4 (sistema 1: **3 pasadas** + verificación de alcance reducido + 4 enmiendas post-aprobación; la 3ª es su primera revisión adversarial propia y cerró su changeset 1 de 2 · sistema 2: **3 pasadas**, congelado tras la 3ª · sistema 15: **1 pasada full** 2026-09-04, 9 especialistas + síntesis CD · sistema 4: **2 pasadas full** 2026-09-04, 8 agentes + síntesis CD) |
| Docs de diseño aprobados | **4** — Combate de Parry-Absorción (#1, 8ª pasada MAJOR con CS8; aceptado sin re-review 2026-09-04) · Menú Principal (#15, Rev2 aceptado sin re-review 2026-09-04) · Feedback de Impacto (#4, Rev2 aceptada sin 3ª pasada 2026-09-04) · Guardado de Progreso (#12, Rev2 aceptada sin re-review 2026-09-04). Sistema 2 pendiente de re-review |
| Sistemas MVP diseñados | 4/7 |
| Sistemas Vertical Slice diseñados | 0/9 |

---

## Next Steps

- [x] Revisar y aprobar esta enumeración de sistemas
- [ ] Diseñar los sistemas de nivel MVP primero, en el orden de la tabla (`/design-system [nombre-sistema]` o `/map-systems next`)
- [ ] Ejecutar `/design-review` en cada GDD completado
- [ ] Ejecutar `/gate-check pre-production` cuando los sistemas MVP estén diseñados
- [ ] Validar los sistemas de mayor riesgo con `/vertical-slice` antes de comprometerse a Producción

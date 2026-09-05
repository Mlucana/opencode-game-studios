# Análisis de Etapa del Proyecto — NOVENA

**Generado**: 2026-09-03
**Etapa**: Systems Design (override explícito de `production/stage.txt`)
**Confianza de etapa**: CONCERNS — señales ambiguas (diseño sin aprobar + señales tempranas de Pre-Producción)
**Alcance del análisis**: Proyecto completo (general, sin filtro de rol)

---

## Resumen Ejecutivo

El proyecto NOVENA (roguelike de duelos de precisión, boss-rush, Godot 4.7 + GDScript) está en **Systems Design**: concepto e índice de 21 sistemas completos, 2 GDDs MVP escritos (combate parry-absorción y máquina de estados de jefe) pero **0 aprobados** — el sistema 1 está en NEEDS REVISION con changeset 2 completo listo para re-review, y el sistema 2 está CONGELADO (MAJOR REVISION NEEDED) hasta que cierre el 1.

La ambigüedad viene de que ya existe **código temprano de Pre-Producción** (motor configurado, `src/gameplay/combate/` con 2 ficheros, 7 ficheros de test, 55/55 en verde) iniciado para desbloquear tests antes del gate de diseño. Además falta toda la capa de producción (sprints, milestones, roadmap, epics), hay 0 ADRs con 2 decisiones bloqueantes identificadas, y el prototipo citado en el estado de sesión no está en el repo.

**Foco actual**: cerrar sistema 1 (re-review) y correr la suite ampliada de 62 tests / 35 ACs.
**Bloqueantes**: ADR del mecanismo de Regla 8 (sistema 2) — sin él no se puede cerrar el GDD del sistema 2 ni escribir el test C4a; C12b no cerrable como está escrito; contradicción entre `.claude/rules/gameplay-code.md` (exige delta time) y Regla 2 del GDD (lo prohíbe).
**Tiempo estimado a la siguiente etapa**: tras aprobar los 7 GDDs MVP + ADR de Regla 8 → `/gate-check pre-production`.

---

## Completeness Overview

### Documentación de Diseño
- **Estado**: ~28% MVP (2/7) · ~10% global (2/21) · 0 aprobados
- **Ficheros encontrados**: 4 documentos en `design/gdd/` + 2 logs de revisión + art-bible + entities.yaml v8
  - GDDs: `game-concept.md` (Borrador), `systems-index.md` (Aprobado, 21 sistemas), `combate-parry-absorcion.md` (NEEDS REVISION, 3ª pasada, changesets 1 y 2 aplicados), `maquina-estados-jefe.md` (CONGELADO, 3 pasadas)
  - Narrativa: 0 ficheros en `design/narrative/` (no existe el directorio)
  - Niveles: 0 ficheros en `design/levels/` (no existe el directorio)
- **Gaps clave**:
  - [ ] 19/21 sistemas sin diseñar, incluidos 5 MVP (Gracia, IA de Jefes, Feedback de Impacto, Sonoro, HUD)
  - [ ] HUD de Combate (#13) con flag UX: requiere `/ux-design` antes de épicas
  - [ ] Sin specs UX por pantalla ni requisitos de accesibilidad

### Código Fuente
- **Estado**: 1 sistema de 21 (~5%)
- **Ficheros**: 2 fuentes `.gd` en `src/` (~258 líneas)
- **Sistemas principales identificados**:
  - ✅ Combate (`src/gameplay/combate/`) — `combat_formulas.gd` (163 líneas) + `combat_tuning.gd` (95 líneas), aritmética y ciclo del jugador; hitstop y orden de transiciones sin tocar (dependen del ADR)
  - ❌ `src/core/`, `src/ai/`, `src/networking/`, `src/ui/` — inexistentes
- **Gaps clave**:
  - [ ] Todo sistema fuera de combate sin implementar (esperado en esta etapa)
  - [ ] `C8` no implementable literalmente sin tabla nombre-de-diseño ↔ enum (nombres con espacios como `En Combo`)

### Documentación de Arquitectura
- **Estado**: 0 ADRs (~0%)
- **ADRs encontrados**: 0 en `docs/architecture/` (solo existe `tr-registry.yaml`, cabecera/registro vacío de IDs)
- **Cobertura**:
  - ❌ Mecanismo de Regla 8 (resolución síncrona, orden entre `_physics_process`) — ni documentado ni decidido; puede bloquear al GDD del sistema 2
  - ❌ Autoridad de tiempo / hitstop (quién avanza al 4%, 7 consumidores heterogéneos) — mismo ADR que el anterior, el más urgente
  - ❌ Nodo dedicado vs. recurso de datos para compositing de corrupción
- **Gaps clave**:
  - [ ] Escribir el ADR de Regla 8 + tiempo antes de la 4ª pasada del sistema 2
  - [ ] Hueco de referencia de motor: sin submódulo SceneTree core (despacho de señales, orden del bucle de física); `input.md` verificado contra 4.6 con proyecto en 4.7 (cambio incompatible de device IDs no cubierto); `timestamp` ausente en la referencia

### Gestión de Producción
- **Estado**: ~5% (solo estado de sesión y logs)
- **Encontrado**:
  - Planes de sprint: 0 en `production/sprints/` (no existe)
  - Milestones: 0 en `production/milestones/` (no existe)
  - Roadmap: inexistente · Epics: 0
  - Sí existen: `stage.txt` (=Systems Design), `review-mode.txt` (=full), `session-state/active.md`, `session-logs/`, `qa/evidence/README.md`
- **Gaps clave**:
  - [ ] Sin planificación de sprints ni tracking de milestones (¿se trackea fuera — Jira/Trello — o se genera `/sprint-plan`?)

### Testing
- **Estado**: alto en sistema 1, cero en el resto
- **Ficheros de test**: 7 en `tests/` (1 `standalone_check.gd` + 3 helpers: stub de jefe, harness de parry, espía de orden de señales + 3 tests unitarios de combate)
- **Cobertura por sistema**:
  - Combate (aritmética/ciclo): ~alta — 62 tests / 35 ACs planificados, 55/55 en verde en la última corrida; D9(b) reproduce la tabla de veredictos exacta; E10/E11 confirma el `100/6` llegando a 0 exacto
  - Resto de sistemas: 0%
- **Gaps clave**:
  - [ ] C12b NO cerrable como está escrito (no define sus dos modelos de jugador; el veredicto se invierte según latencia) — puerta de release, debe declarar ambos modelos
  - [ ] C4a espera al ADR de Regla 8 (escribirlo hoy prejuzgaría el mecanismo)
  - [ ] `recuperacion_exito` sin símbolo (prosa "2–3 fotogramas", fijado provisionalmente en 3) — promover a Tuning Knob con dueño
  - [ ] Mitigación del mash intra-combo inefectiva en rango útil (masher al 100% con varianza <12 ticks) — cifra para el sistema 20

### Prototipos
- **Prototipos activos**: 0 en `prototypes/` (solo `.gitkeep`)
- **Archivados**: 0
- **Gaps clave**:
  - [ ] `session-state/active.md` cita `prototypes/parry-absorcion-concept/` PROCEED (origen de R3, tasa 72% con parry activo) pero no existe en el repo — ¿pérdida en la migración o archivado externo? Sin README/CONCEPT según el propio estado

---

## Justificación de la Clasificación de Etapa

**¿Por qué Systems Design?**

`production/stage.txt` contiene `Systems Design` y el skill establece que ese valor es override explícito de `/gate-check`. El estado de sesión lo confirma: "Fase: Diseño de sistemas (2/7 GDDs MVP escritos, 0 aprobados)".

**Indicadores de esta etapa**:
- Concepto de juego + pilares existen (`game-concept.md`, `art-bible.md`)
- Índice de sistemas completo y aprobado (21 sistemas, dependencias y orden de diseño en `systems-index.md`)
- GDDs MVP en revisión adversarial activa (3 pasadas cada uno, 8 especialistas + síntesis)

**Indicadores de etapa *superior* (causa del CONCERNS)**:
- Motor configurado (`project.godot`, Godot 4.7) + `src/` con <10 ficheros = heurística de Pre-Producción
- Primer código verde + harness de tests desbloqueando 9 ACs

**Requisitos para la siguiente etapa (Pre-Producción)**:
- [ ] Aprobar los 7 GDDs MVP (hoy 0/7; sistema 1 listo para re-review, sistema 2 pendiente de 4ª pasada R1→R3→R4→R5)
- [ ] Escribir el ADR de Regla 8 + autoridad de tiempo (desbloquea sistema 2 y C4a)
- [ ] Resolver C12b (definir ambos modelos de jugador) o reclasificarlo formalmente
- [ ] Pasar `/gate-check pre-production`

---

## Gaps Identificados (con Preguntas Clarificadoras)

### Críticos (bloquean el progreso)

1. **ADR de Regla 8 + autoridad de tiempo sin escribir**
   - **Impacto**: la Regla 8 del sistema 2 y su cláusula de reentrada son mutuamente insatisfacibles; sin ADR no se cierra el GDD del sistema 2 ni el test C4a. Es el riesgo técnico mayor (orden de física, hitstop al 4%, 7 consumidores).
   - **Pregunta**: ¿lanzo `/create-architecture` enfocado solo en este ADR, o prefieres el paquete completo de arquitectura?
   - **Acción sugerida**: ADR mínimo viable (dirección del call stack, base temporal, dueño del instante de contacto del Castigo, nombres canónicos de señal/payload) — esfuerzo M.

2. **C12b no cerrable + contradicción de regla de proyecto**
   - **Impacto**: C12b (puerta de release) certificaría el modelo, no la regla; y `.claude/rules/gameplay-code.md` contradice la Regla 2 del GDD (delta time vs contador entero — el acumulador se congelaría mal en hitstop).
   - **Pregunta**: ¿corrijo la regla del proyecto a favor del GDD y devuelvo C12b a diseño para que declare ambos modelos?
   - **Acción sugerida**: fix de 1 línea en la regla + reescritura del AC — esfuerzo S.

### Importantes (afectan calidad/velocidad)

3. **Prototipo citado pero ausente del repo**
   - **Impacto**: se pierde la evidencia del PROCEED (72% de acierto) y el origen de R3/R9a.
   - **Pregunta**: ¿el prototipo vive fuera del repo (otra carpeta/staging) y lo reimportamos, o lo damos por archivado y documentamos la decisión?
   - **Acción sugerida**: `/reverse-document concept` si se recupera — esfuerzo S.

4. **19/21 sistemas sin diseñar (5 MVP restantes)**
   - **Impacto**: Gracia (5) y Reliquias (9) exponen `angeles_absorbidos`, `bono_reliquias` (sin tope) y `multiplicador_ataque` que Combate ya consume con defaults; IA de Jefes (20) debe acotar curación, cadencia, combos y suelo de `margen_reaccion_min`.
   - **Pregunta**: ¿seguimos el orden recomendado (Feedback de Impacto #3, Gracia #4, IA #5…) o priorizas descongelar el sistema 2 primero?
   - **Acción sugerida**: `/design-system` por sistema en orden — esfuerzo S–L c/u.

5. **Sin planificación de producción**
   - **Impacto**: sin sprints/milestones no hay velocidad medible ni fechas para el slice vertical.
   - **Pregunta**: ¿trackeas en herramienta externa (Jira/Trello) o generamos `/sprint-plan` para el cierre de los MVP?
   - **Acción sugerida**: `/sprint-plan` con foco en re-review + ADR — esfuerzo S.

### Buenos de tener (pulido/buenas prácticas)

6. **Referencia de motor desactualizada + derivas menores**
   - **Impacto**: menor hoy, pero el "ningún cambio 4.4→4.7 aplica" es un negativo no verificado justo en el subsistema del mayor riesgo.
   - **Pregunta**: ¿refresco `input.md` a 4.7 y añado el submódulo SceneTree con `/setup-engine`, o lo diferimos hasta el ADR?
   - **Acción sugerida**: `/setup-engine` parcial — esfuerzo S. (Derivas: `game-concept.md` dice 4.6; `technical-preferences.md` vs `coding-standards.md` difieren en framework de tests GUT/gdUnit4 — el repo ya usa gdUnit4 6.2.0.)

---

## Próximos Pasos Recomendados

### Prioridad inmediata (hacer primero)
1. **Correr la suite de 62 tests y re-review del sistema 1** — changeset 2 completo, arquitectura intacta en 3 pasadas; confirma que los fixes a defectos propios (ventana multi-parada, remate sin evento, Gracia) siguen verdes
   - Skill sugerido: comando gdUnit4 headless (`--ignoreHeadlessMode` no opcional) + `/design-review design/gdd/combate-parry-absorcion.md`
   - Esfuerzo: S/M
2. **ADR de Regla 8 + autoridad de tiempo** — desbloquea sistema 2, C4a, C8 y Efectos de Estado
   - Skill sugerido: `/create-architecture` (o `/architecture-decision` mínimo)
   - Esfuerzo: M

### Corto plazo (este sprint/semana)
3. **`/adopt`** — auditoría de fase, huecos y conformidad de formato de los GDDs en español (paso pendiente del handoff) — S
4. **4ª pasada del sistema 2** (raíces R1→R3→R4→R5) tras el ADR — M
5. **Corregir contradicción gameplay-code.md vs Regla 2 + promover `recuperacion_exito`** — S

### Medio plazo (siguiente milestone)
6. **Diseñar Gracia (5) e IA de Jefes (20)** — cierran los contratos de datos abiertos y la tasa de curación — L
7. **`/gate-check pre-production`** cuando los 7 MVP estén aprobados + `/sprint-plan` del slice vertical — M

---

## Recomendaciones por Rol

*(Sin filtro de rol en esta ejecución — vista holística.)*

- **Programmer**: prioriza ADR de Regla 8, fix de gameplay-code.md, suite 62 tests; bloqueado en C4a/C12b.
- **Designer**: prioriza re-review sistema 1, 4ª pasada sistema 2, luego Gracia e IA de Jefes; deuda de legibilidad prospectiva y fila de "duelo ganado" pendientes.
- **Producer**: prioriza `/sprint-plan` + `/adopt`; sin artefactos de tracking hoy.

---

## Follow-Up Skills a Ejecutar

- `/design-review design/gdd/combate-parry-absorcion.md` — re-review tras changeset 2
- `/create-architecture` (o `/architecture-decision`) — ADR Regla 8 + tiempo
- `/adopt` — auditoría de conformidad de GDDs en español
- `/sprint-plan` — planificar cierre de MVPs
- `/setup-engine` — refrescar referencia Godot 4.7 (input + SceneTree)
- `/gate-check pre-production` — cuando los 7 MVP estén aprobados (formaliza `stage.txt`)
- `/ux-design` — requerido antes de épicas del HUD (#13)

---

## Apéndice: Conteo de Ficheros por Directorio

```
design/
  gdd/           4 ficheros (+2 review logs en gdd/reviews/)
  narrative/     0 (no existe)
  levels/        0 (no existe)
  art/           1 (art-bible.md)
  registry/      1 (entities.yaml v8)

src/
  core/          0 (no existe)
  gameplay/      2 ficheros (combate/)
  ai/            0 (no existe)
  networking/    0 (no existe)
  ui/            0 (no existe)

docs/
  architecture/  0 ADRs (1 tr-registry.yaml)

production/
  sprints/       0 (no existe)
  milestones/    0 (no existe)
  stage.txt      Systems Design · review-mode.txt: full

tests/           7 ficheros .gd (1 standalone + 3 helpers + 3 unit)
prototypes/      0 directorios (solo .gitkeep)
```

---

**Fin del informe**

*Generado por `/project-stage-detect`*

<p align="center">
  <h1 align="center">OpenCode Game Studios</h1>
  <p align="center">
    Convierte una sesión de OpenCode en un estudio completo de desarrollo de videojuegos.
    <br />
    49 agentes. 73 comandos. Un equipo de IA coordinado.
  </p>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
  <a href=".opencode/agents"><img src="https://img.shields.io/badge/agents-49-blueviolet" alt="49 agentes"></a>
  <a href=".opencode/commands"><img src="https://img.shields.io/badge/commands-73-green" alt="73 comandos"></a>
  <a href=".opencode/plugins"><img src="https://img.shields.io/badge/hooks-12-orange" alt="12 hooks"></a>
  <a href="opencode.json"><img src="https://img.shields.io/badge/rules-11-red" alt="11 reglas"></a>
  <a href="https://opencode.ai/docs"><img src="https://img.shields.io/badge/built%20for-OpenCode-444444" alt="Hecho para OpenCode"></a>
</p>

> **Adaptado por [Mlucana](https://github.com/Mlucana)** a partir de
> [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)
> de Donchitos (licencia MIT). Todo el sistema del estudio — agentes, flujos de
> trabajo, hooks y estándares — se ha portado de Claude Code a
> [OpenCode](https://opencode.ai/docs). Ver [Diferencias con el original](#diferencias-con-el-original).

---

## Por qué existe

Crear un juego en solitario con IA es muy potente, pero una sola sesión de chat
no tiene estructura. Nadie te frena si pones números mágicos en el código, te
saltas los documentos de diseño o escribes código espagueti. No hay revisión de
QA, ni revisión de diseño, ni nadie que pregunte "¿esto encaja con la visión
del juego?".

**OpenCode Game Studios** resuelve esto dándole a tu sesión de IA la estructura
de un estudio real. En lugar de un asistente genérico, obtienes 49 agentes
especializados organizados en una jerarquía de estudio: directores que protegen
la visión, líderes que dominan su área y especialistas que hacen el trabajo
práctico. Cada agente tiene responsabilidades definidas, rutas de escalado y
puertas de calidad.

El resultado: tú sigues tomando cada decisión, pero ahora tienes un equipo que
hace las preguntas correctas, detecta errores pronto y mantiene tu proyecto
organizado desde el primer brainstorm hasta el lanzamiento.

---

## Índice

- [Qué incluye](#qué-incluye)
- [Diferencias con el original](#diferencias-con-el-original)
- [Jerarquía del estudio](#jerarquía-del-estudio)
- [Comandos slash](#comandos-slash)
- [Primeros pasos](#primeros-pasos)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Cómo funciona](#cómo-funciona)
- [Filosofía de diseño](#filosofía-de-diseño)
- [Personalización](#personalización)
- [Plataformas](#plataformas)
- [Comunidad](#comunidad)
- [Licencia](#licencia)

---

## Qué incluye

| Categoría | Cantidad | Descripción |
|-----------|----------|-------------|
| **Agentes** | 49 | Subagentes especializados en diseño, programación, arte, audio, narrativa, QA y producción |
| **Comandos** | 73 | Comandos slash para cada fase (`/start`, `/design-system`, `/create-epics`, `/create-stories`, `/dev-story`, `/story-done`, etc.) |
| **Skills** | 73 | Textos completos de cada flujo, cargables con la herramienta `skill` |
| **Hooks** | 12 | Validación automática en commits, pushes, cambios de assets, ciclo de sesión, auditoría de agentes y detección de huecos |
| **Reglas** | 11 | Estándares de código por ruta (gameplay, engine, IA, UI, red, etc.) |
| **Plantillas** | 38+ | Plantillas de GDDs, specs UX, ADRs, planes de sprint, diseño de HUD, accesibilidad y más |

## Diferencias con el original

| Original (Claude Code) | Este port (OpenCode) |
|------------------------|----------------------|
| `.claude/agents/*.md` (49) | `.opencode/agents/*.md` (49, `mode: subagent`) — se invocan con `@nombre` o la herramienta `task`. Originales conservados en `.claude/agents/` |
| `.claude/skills/*/SKILL.md` como slash commands | `.opencode/commands/*.md` (73: `/start`, `/brainstorm`, `/dev-story`…) — envoltorios autocontenidos. Los textos originales siguen en `.claude/skills/` y OpenCode los descubre solo vía `skill` |
| Hooks en `.claude/settings.json` | `.opencode/plugins/ccgs-hooks.js` — reutiliza los `.sh` originales sin modificarlos |
| Reglas path-scoped de Claude | Las 11 reglas van en `opencode.json` → `instructions` |
| Herramienta `AskUserQuestion` | Herramienta `question` |
| Herramienta `TodoWrite` | Herramienta `todowrite` |
| Modelos `opus`/`sonnet`/`haiku` fijados | Sin modelo fijado: heredan el de tu sesión de OpenCode (funciona con cualquier proveedor). El tier original se anota en cada agente por si quieres fijarlo |

## Jerarquía del estudio

Los agentes están organizados en tres niveles, como en un estudio real:

```
Nivel 1 — Directores
  creative-director    technical-director    producer

Nivel 2 — Líderes de departamento
  game-designer        lead-programmer       art-director
  audio-director       narrative-director    qa-lead
  release-manager      localization-lead

Nivel 3 — Especialistas
  gameplay-programmer  engine-programmer     ai-programmer
  network-programmer   tools-programmer      ui-programmer
  systems-designer     level-designer        economy-designer
  technical-artist     sound-designer        writer
  world-builder        ux-designer           prototyper
  performance-analyst  devops-engineer       analytics-engineer
  security-engineer    qa-tester             accessibility-specialist
  live-ops-designer    community-manager
```

### Especialistas por motor

El template incluye agentes para los tres motores principales. Usa el juego que
corresponda a tu proyecto:

| Motor | Agente líder | Sub-especialistas |
|-------|-------------|-------------------|
| **Godot 4** | `godot-specialist` | GDScript, C#, Shaders, GDExtension |
| **Unity** | `unity-specialist` | DOTS/ECS, Shaders/VFX, Addressables, UI Toolkit |
| **Unreal Engine 5** | `unreal-specialist` | GAS, Blueprints, Replicación, UMG/CommonUI |

## Comandos slash

Escribe `/` en OpenCode para acceder a los 73 comandos:

**Onboarding y navegación**
`/start` `/help` `/project-stage-detect` `/setup-engine` `/adopt`

**Diseño de juego**
`/brainstorm` `/map-systems` `/design-system` `/quick-design` `/review-all-gdds` `/propagate-design-change`

**Arte y assets**
`/art-bible` `/asset-spec` `/asset-audit`

**Diseño UX e interfaces**
`/ux-design` `/ux-review`

**Arquitectura**
`/create-architecture` `/architecture-decision` `/architecture-review` `/create-control-manifest`

**Historias y sprints**
`/create-epics` `/create-stories` `/dev-story` `/sprint-plan` `/sprint-status` `/story-readiness` `/story-done` `/estimate`

**Revisiones y análisis**
`/design-review` `/code-review` `/balance-check` `/content-audit` `/scope-check` `/perf-profile` `/tech-debt` `/gate-check` `/consistency-check` `/security-audit`

**QA y testing**
`/qa-plan` `/smoke-check` `/soak-test` `/regression-suite` `/test-setup` `/test-helpers` `/test-evidence-review` `/test-flakiness` `/skill-test` `/skill-improve`

**Producción**
`/milestone-review` `/retrospective` `/bug-report` `/bug-triage` `/reverse-document` `/playtest-report`

**Lanzamiento**
`/release-checklist` `/launch-checklist` `/changelog` `/patch-notes` `/hotfix` `/day-one-patch`

**Creatividad y contenido**
`/prototype` `/vertical-slice` `/onboard` `/localize`

**Orquestación de equipos** (varios agentes sobre una misma feature)
`/team-combat` `/team-narrative` `/team-ui` `/team-release` `/team-polish` `/team-audio` `/team-level` `/team-live-ops` `/team-qa`

## Primeros pasos

### Requisitos

- [Git](https://git-scm.com/)
- [OpenCode](https://opencode.ai/docs) instalado y configurado con tu proveedor
- **Recomendado**: [jq](https://jqlang.github.io/jq/) (validación de hooks), Python 3 (validación JSON) y Git Bash en Windows (ejecuta los scripts de hooks)

Todos los hooks fallan con gracia si faltan herramientas opcionales: nada se
rompe, solo pierdes esa validación.

### Instalación

1. **Clona el repo**:
   ```bash
   git clone https://github.com/Mlucana/opencode-game-studios.git my-game
   cd my-game
   ```

2. **Abre OpenCode** en esa carpeta e inicia una sesión.

3. **Ejecuta `/start`** — el sistema pregunta en qué punto estás (sin idea,
   idea vaga, concepto claro, trabajo existente) y te guía al flujo correcto.
   Sin suposiciones.

   O salta directo a lo que necesites:
   - `/brainstorm` — explora ideas de juego desde cero
   - `/setup-engine godot 4.6` — configura tu motor si ya lo tienes claro
   - `/project-stage-detect` — analiza un proyecto existente

## Estructura del proyecto

```
AGENTS.md                           # Configuración maestra (este estudio)
opencode.json                       # Instrucciones, permisos y reglas de OpenCode
CLAUDE.md                           # Config original (compatibilidad)
.opencode/
  agents/                           # 49 subagentes (mode: subagent, invocables con @nombre)
  commands/                         # 73 comandos slash (uno por skill)
  plugins/
    ccgs-hooks.js                   # Plugin de hooks (reutiliza .claude/hooks/*.sh)
.claude/
  settings.json                     # Config original de Claude Code (referencia)
  agents/                           # 49 definiciones originales
  skills/                           # 73 flujos completos (subdirectorio por skill)
  hooks/                            # 12 scripts bash (multiplataforma)
  rules/                            # 11 estándares por ruta
  statusline.sh                     # Línea de estado (solo Claude Code)
  docs/
    workflow-catalog.yaml           # Pipeline de 7 fases (lo lee /help)
    templates/                      # Plantillas de documentos
src/                                # Código fuente del juego
assets/                             # Arte, audio, VFX, shaders, datos
design/                             # GDDs, narrativa, niveles
docs/                               # Documentación técnica y ADRs
tests/                              # Suites de test
tools/                              # Pipeline y herramientas
prototypes/                         # Prototipos desechables (aislados de src/)
production/                         # Sprints, hitos, lanzamientos y estado de sesión
```

## Cómo funciona

### Coordinación de agentes

Los agentes siguen un modelo de delegación estructurado:

1. **Delegación vertical** — los directores delegan en líderes, los líderes en especialistas
2. **Consulta horizontal** — los agentes del mismo nivel pueden consultarse, pero no toman decisiones vinculantes fuera de su dominio
3. **Resolución de conflictos** — los desacuerdos escalan al padre común (`creative-director` en diseño, `technical-director` en técnica)
4. **Propagación de cambios** — los cambios entre departamentos los coordina `producer`
5. **Fronteras de dominio** — ningún agente modifica archivos fuera de su dominio sin delegación explícita

En OpenCode la delegación se hace con la herramienta `task` o mencionando
`@nombre` en tu mensaje.

### Colaborativo, no autónomo

Esto **no** es un piloto automático. Cada agente sigue un protocolo estricto de
colaboración:

1. **Pregunta** — los agentes preguntan antes de proponer soluciones
2. **Presenta opciones** — muestran 2-4 opciones con pros y contras
3. **Tú decides** — el usuario siempre tiene la última palabra
4. **Borrador** — enseñan el trabajo antes de finalizarlo
5. **Aprobación** — nada se escribe sin tu visto bueno

Tú mantienes el control. Los agentes aportan estructura y experiencia, no
autonomía.

### Seguridad automatizada

El plugin `.opencode/plugins/ccgs-hooks.js` reutiliza los 12 scripts originales
en cada sesión:

| Script | Evento OpenCode | Qué hace |
|--------|----------------|----------|
| `validate-commit.sh` | Antes de `bash` | Revisa valores hardcodeados, formato de TODOs, JSON válido, secciones de diseño — ignora lo que no sea `git commit` |
| `validate-push.sh` | Antes de `bash` | Avisa al hacer push a ramas protegidas — ignora lo que no sea `git push` |
| `validate-assets.sh` | Después de escribir/editar | Valida nombres y estructura JSON — ignora lo que no esté en `assets/` |
| `session-start.sh` | Sesión creada | Muestra rama actual y commits recientes para orientarte |
| `detect-gaps.sh` | Sesión creada | Detecta proyectos nuevos (sugiere `/start`) y docs de diseño faltantes |
| `pre-compact.sh` | Antes de compactar | Conserva las notas de progreso de la sesión |
| `post-compact.sh` | Después de compactar | Recuerda restaurar el estado desde `active.md` |
| `notify.sh` | Sesión en espera | Toast de Windows vía PowerShell |
| `session-stop.sh` | Sesión cerrada/inactiva | Archiva `active.md` en el log y registra actividad git |
| `log-agent.sh` | Subagente invocado (`task`) | Inicio de auditoría |
| `log-agent-stop.sh` | Subagente terminado | Fin de auditoría |
| `validate-skill-change.sh` | Después de escribir/editar | Recomienda `/skill-test` tras cambiar una skill |

> **Nota**: varios hooks se evalúan en cada llamada y terminan de inmediato
> (exit 0) cuando no aplican. Es el comportamiento normal, no un problema de
> rendimiento.

**Permisos** en `opencode.json`: las lecturas/escrituras peligrosas piden
confirmación y las operaciones destructivas están denegadas (force push,
`rm -rf`, leer `.env`).

### Reglas por ruta

Los estándares se aplican según la ubicación del archivo (ver tabla en
[AGENTS.md](AGENTS.md)):

| Ruta | Obliga |
|------|--------|
| `src/gameplay/**` | Valores data-driven, delta time, sin referencias a UI |
| `src/core/**` | Cero allocations en rutas calientes, thread safety |
| `src/ai/**` | Presupuestos de rendimiento, parámetros data-driven |
| `src/networking/**` | Servidor autoritativo, mensajes versionados |
| `src/ui/**` | Sin estado propio, listo para localización y accesibilidad |
| `design/gdd/**` | 8 secciones obligatorias, fórmulas, casos borde |
| `tests/**` | Nomenclatura, cobertura, fixtures |
| `prototypes/**` | Estándares relajados, README e hipótesis obligatorios |

## Filosofía de diseño

Este template se basa en prácticas profesionales de desarrollo de videojuegos:

- **Framework MDA** — análisis de Mecánicas, Dinámicas y Estéticas
- **Teoría de la autodeterminación** — Autonomía, Competencia, Pertenencia
- **Diseño de flow** — equilibrio reto-habilidad
- **Tipos de jugador de Bartle** — segmentación de audiencia
- **Desarrollo guiado por verificación** — primero los tests, luego la implementación

## Personalización

Esto es un **template**, no un framework cerrado. Todo está para personalizarse:

- **Añade/quita agentes** — borra los que no necesites, crea los de tus dominios
- **Edita sus prompts** — ajusta comportamiento, añade conocimiento de tu proyecto
- **Modifica comandos y skills** — adapta los flujos a tu proceso (si tocas una skill, pasa `/skill-test`)
- **Añade reglas** — crea estándares por ruta para tu estructura
- **Ajusta el plugin** — cambia la dureza de las validaciones
- **Elige tu motor** — Godot, Unity o Unreal (o ninguno)
- **Intensidad de revisión** — `full`, `lean` o `solo`, vía `/start` o `production/review-mode.txt`

## Plataformas

Desarrollo y pruebas principales en **Windows 10/11** con Git Bash. Todos los
hooks usan patrones POSIX (`grep -E`, no `grep -P`) e incluyen alternativas si
faltan herramientas, así que deberían funcionar en macOS y Linux. `notify.sh`
usa PowerShell (sin efecto fuera de Windows). Si algo falla en tu plataforma,
abre un issue.

## Comunidad

- **Issues** — [reportes y peticiones](https://github.com/Mlucana/opencode-game-studios/issues)
- **Original** — [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios) de Donchitos, proyecto del que deriva este port

---

*Hecho para OpenCode. Adaptado por [Mlucana](https://github.com/Mlucana) a partir del trabajo de Donchitos.*

## Licencia

Licencia MIT. Ver [LICENSE](LICENSE): copyright original de Donchitos con línea
de adaptación añadida.

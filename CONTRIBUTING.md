# Contribuir a OpenCode Game Studios

Port de [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)
adaptado por Mlucana para [OpenCode](https://opencode.ai/docs): un framework de
coordinación para desarrollar videojuegos indie con IA.

Se aceptan contribuciones: corrección de errores, nuevas skills que cubran un
hueco real, mejoras de agentes y arreglo de hooks. Los PR que no encajen con la
dirección del framework se cerrarán sin largas explicaciones.

## Qué hace un buen PR

- **Corrección de errores** — algo está roto, aquí está el arreglo
- **Nuevas skills** que cubran un hueco del flujo no contemplado
- **Mejoras** a agentes, skills, comandos o hooks existentes
- **Correcciones de documentación** — info errónea, referencias rotas, pasos desactualizados

Las peticiones de features como PR se cerrarán. Abre un issue en su lugar.

**Lo que este repo no es:**
es el sistema que te ayuda a construir juegos, no un lugar donde guardar los
juegos que construyas con él. GDDs, ADRs, PRDs, conceptos, niveles, narrativa o
cualquier otro artefacto generado para tu proyecto no se fusionará aquí —
guárdalo en tu propio repo.

## Reglas técnicas no negociables

**Skills y comandos**
- Las skills viven en `.claude/skills/<nombre>/SKILL.md` (el formato con
  subdirectorio es obligatorio) y OpenCode las descubre solo vía `skill`
- Los comandos slash viven en `.opencode/commands/<nombre>.md` y deben ser
  envoltorios autocontenidos de su skill (si cambias una skill, regenera o
  actualiza su comando a juego)
- SKILL.md debe incluir frontmatter YAML: `name`, `description`,
  `argument-hint`, `allowed-tools` y `model`
- Tier de modelo: `haiku` para chequeos de solo lectura, `opus` para síntesis
  multi-documento y puertas de fase, `sonnet` para el resto
- En OpenCode los agentes heredan el modelo de la sesión: no fijes `model:` en
  `.opencode/agents/` salvo que sea imprescindible

**Hooks**
- Usa `grep -E`, nunca `grep -P` (el regex Perl rompe en Git Bash de Windows)
- Incluye alternativas si no hay `jq` o `python`
- El plugin `.opencode/plugins/ccgs-hooks.js` reutiliza los `.sh`: si cambias
  un script, mantén su esquema JSON de entrada y sus códigos de salida
  (`exit 2` = bloquear)
- Los hooks corren en cada sesión: deben terminar rápido y con gracia
  (`exit 0`) cuando no apliquen

**Agentes**
- Los agentes nuevos deben incluir una sección **Collaboration Protocol** que
  describa cómo preguntan y ceden las decisiones al usuario
- Ningún agente modifica archivos fuera de su dominio sin delegación explícita
- En OpenCode se invocan con `@nombre` o la herramienta `task`

**Docs de referencia**
- Si tu PR añade o cambia una skill, agente, comando o hook, actualiza su doc
  de referencia (agent-roster, skills-reference, hooks-reference o
  rules-reference). Sin índice actualizado, el PR vuelve atrás.

## El principio colaborativo

Esto no es un sistema autónomo. Cada flujo sigue:
**Pregunta → Opciones → Decisión → Borrador → Aprobación → Escritura**

Skills y agentes deben preguntar antes de actuar (herramienta `question` en
OpenCode). Nada se escribe sin confirmación explícita del usuario.

## Probar tus cambios

Pruébalo en una sesión de OpenCode y confirma que funciona de punta a punta.
Para skills/comandos, invócalos y verifica que la salida coincide con lo que
describen. Para hooks, dispara el evento y confirma que se ejecuta y termina
limpio. Para cambios en `.claude/skills/`, pasa `/skill-test`.

Incluye en la descripción del PR qué probaste y cómo se veía la salida.

## Formato de commits

Usa [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add /retrospective skill for end-of-sprint reviews
fix: correct grep -P usage in session-start hook
docs: update skills-reference with new /qa-plan entry
```

Tipos: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`

## Proceso de PR

- Las revisiones llegan cuando llegan: proyecto mantenido por una persona
- Si tu PR lleva semanas sin respuesta, un comentario de recordatorio está bien
- Los contribuidores fusionados se acreditan en las notas de release

## Compatibilidad de plataformas

Debe funcionar en Windows (Git Bash), macOS y Linux. Si tu hook o script usa
algo específico de una plataforma, será rechazado. En caso de duda, prueba en
Windows.

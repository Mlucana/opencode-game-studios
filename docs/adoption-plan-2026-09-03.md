# Adoption Plan

> **Generated**: 2026-09-03
> **Project phase**: Systems Design (de `production/stage.txt`, autoritativo)
> **Engine**: Godot 4.7 (parcialmente configurado — Rendering y Physics sin configurar)
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Step 1: Fix Blocking Gaps

### 1a. `systems-index.md` — valores de estado parentéticos (2 filas)

**Problema**: 2 celdas de la columna Estado contienen paréntesis, emojis y prosa libre. Esto rompe el matching exacto de `/gate-check`, `/create-stories` y `/architecture-review` **ahora mismo**.

Fila 1 (Combate de Parry-Absorción) — valor actual (extracto):

```text
**⚠️ NEEDS REVISION (2026-08-04) — 1ª revisión adversarial propia completada...**
```

Reemplazo exacto:

```text
Needs Revision
```

Fila 2 (Máquina de Estados de Jefe) — valor actual (extracto):

```text
**🔒 CONGELADO (2026-08-04) — MAJOR REVISION NEEDED**, bloqueado hasta que cierre la revisión del sistema 1...
```

Reemplazo exacto:

```text
Needs Revision
```

**Dónde va el detalle que se quita**: mover la fecha, el motivo de congelado y el resumen de pasadas a `## Progress Tracker` o al log de revisión correspondiente (`design/gdd/reviews/*-review-log.md`). La celda de Estado debe contener **solo** el valor exacto, sin emoji, sin fecha, sin paréntesis. El flag de "congelado" vive como nota en la columna `Doc de Diseño` o en el tracker, nunca en el Estado.

**Arreglo**: edición manual directa de `design/gdd/systems-index.md` (2 celdas).
**Time**: 5 min
- [ ] Fila 1 normalizada a `Needs Revision`
- [ ] Fila 2 normalizada a `Needs Revision` (nota de congelado movida fuera de la celda)
- [ ] Re-run `/adopt infra` confirma cero valores parentéticos

---

## Step 2: Fix High-Priority Gaps

### 2a. `technical-preferences.md` — Rendering sin configurar

**Problema**: el campo Rendering contiene `[TO BE CONFIGURED]`. Las skills de ADR no pueden evaluar compatibilidad de render sin él.
**Fix**: ejecutar `/setup-engine` para poblarlo, o editar manualmente `.claude/docs/technical-preferences.md` (decisión 2D: Compatibility vs Forward+ para el look tinta/vitral + 60fps en Steam Deck).
**Time**: 30 min
- [ ] Rendering configurado

### 2b. `technical-preferences.md` — Physics sin configurar

**Problema**: el campo Physics contiene `[TO BE CONFIGURED]`. Afecta a decisiones de física y a la referencia de motor (Godot 4.6+ trae Jolt por defecto; 4.7 cambia `WorldBoundaryShape3D`/`SoftBody3D`).
**Fix**: ejecutar `/setup-engine` o editar manualmente (GodotPhysics vs Jolt).
**Time**: 30 min
- [ ] Physics configurado

### 2c. `tr-registry.yaml` vacío

**Problema**: el archivo existe pero contiene `requirements: []` y `last_updated: ""`. No hay IDs estables de requisitos; las historias futuras no tendrán trazabilidad.
**Fix**: ver Paso 3a (`/architecture-review` lo bootstrapea desde los GDDs existentes).
**Time**: 1 sesión (incluida en 3a)
- [ ] Registry con entradas reales para los sistemas 1 y 2

### 2d. `control-manifest.md` ausente

**Problema**: no existe `docs/architecture/control-manifest.md`. Sin él no hay reglas de capa para historias.
**Fix**: ver Paso 3b (`/create-control-manifest`).
**Time**: 30 min (incluido en 3b)
- [ ] Manifest creado con `Manifest Version:` fechado

---

## Step 3: Bootstrap Infrastructure

Ejecutar en este orden (cada paso depende del anterior):

### 3a. Register existing requirements (creates tr-registry.yaml content)

Run `/architecture-review` — even if ADRs already exist, this run bootstraps
the TR registry from your existing GDDs and ADRs. (Aquí: 0 ADRs todavía; el run registra los requisitos de los 2 GDDs existentes.)
**Time**: 1 session (review can be long for large codebases)
- [ ] tr-registry.yaml creado con contenido (ya no vacío)

### 3b. Create control manifest

Run `/create-control-manifest`
**Time**: 30 min
- [ ] docs/architecture/control-manifest.md created

### 3c. Create sprint tracking file

Run `/sprint-plan update`
**Time**: 5 min (if sprint plan already exists as markdown)
- [ ] production/sprint-status.yaml created

### 3d. Set authoritative project stage

Run `/gate-check systems-design`
**Time**: 5 min
- [ ] production/stage.txt written (ya existe con `Systems Design`; este run lo reafirma)

---

## Step 4: Medium-Priority Gaps

### 4a. Manifest version stamp ausente

**Problema**: sin manifest no hay `Manifest Version:`; los checks de staleness están ciegos.
**Fix**: cubierto por 3b. Verificar que el header del manifest lleva `Manifest Version:` fechado.
**Time**: 5 min
- [ ] Stamp presente

### 4b. `sprint-status.yaml` ausente

**Problema**: `/sprint-status` cae a fallback markdown.
**Fix**: cubierto por 3c.
**Time**: 5 min
- [ ] Archivo creado

### 4c. `architecture-traceability.md` ausente

**Problema**: no hay matriz de trazabilidad persistente.
**Fix**: lo genera `/architecture-review` (3a). Verificar su creación tras el run.
**Time**: 5 min
- [ ] Matriz creada

### 4d. Minimum Coverage sin configurar

**Problema**: `Minimum Coverage: [TO BE CONFIGURED]` en technical-preferences. `/test-setup` no tiene objetivo de cobertura.
**Fix**: edición manual (p. ej. fijar umbral para fórmulas de balance + sistemas de gameplay).
**Time**: 5 min
- [ ] Cobertura mínima fijada

---

## Step 5: Optional Improvements

### 5a. Forbidden Patterns vacío

Por diseño empieza vacío. Añadir patrones solo cuando los ADRs los decidan.
**Time**: 5 min
- [ ] Revisado (opcional)

### 5b. Allowed Libraries vacío

Por diseño empieza vacío. Añadir addons solo cuando se aprueben.
**Time**: 5 min
- [ ] Revisado (opcional)

---

## What to Expect from Existing Stories

No hay historias todavía (`production/epics/` vacío), así que no hay nada que migrar. Las historias nuevas obtendrán TR-IDs y version stamps automáticamente una vez bootstrapeado el registry (3a) y el manifest (3b).

Referencia (comportamiento estándar de la plantilla): las historias existentes siguen funcionando con todas las skills — los nuevos checks de formato (TR-ID, manifest version) auto-pasan cuando los campos están ausentes. No regenerar historias en progreso o terminadas.

---

## Re-run

Run `/adopt` again after completing Step 3 to verify all blocking and high gaps
are resolved. The new run will reflect the current state of the project.

---

## Audit detail (this run)

- GDDs: `combate-parry-absorcion.md` y `maquina-estados-jefe.md` — las 8 secciones requeridas presentes en ambos (Overview, Player Fantasy, Detailed Design, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria); campo `**Status**:` presente y válido en ambos; sin placeholders vacíos.
- systems-index.md: columnas mínimas OK (Sistema/Categoría/Prioridad/Estado); 2 filas con estado no exacto (ver 1a).
- ADRs: 0 archivos — sin auditoría de formato; el bootstrap de infraestructura (3a) los registrará cuando existan.
- Review mode: ya fijado a `full` (`production/review-mode.txt`) — sin prompt adicional.

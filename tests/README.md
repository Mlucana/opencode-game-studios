# Infraestructura de Tests

**Motor**: Godot 4.7 (ver `docs/engine-reference/godot/VERSION.md`)
**Framework**: **gdUnit4**
**CI**: `.github/workflows/tests.yml`
**Fecha de setup**: 2026-08-04 · **gdUnit4 6.2.0** instalado en `addons/gdUnit4/`

## Por qué gdUnit4 y no GUT

`technical-preferences.md` fijaba **GUT** y `coding-standards.md` especificaba el
comando del runner de **gdUnit4**. La inconsistencia estaba anotada como
bloqueante del test de C4a desde la 3ª pasada de `/design-review`. Resuelta a
favor de **gdUnit4** por dos razones propias de este proyecto, no por preferencia
general:

1. **Inyección de input en un tick de física concreto.** Los ACs **D1**, **D14**,
   **C2**, **C18** y **C24** exigen pulsar en el tick `T` y aseverar sobre el
   resultado. `calidad_timing` es una cantidad escalonada indexada por la
   distancia en ticks enteros, así que un test que no controle el tick exacto no
   verifica nada. El `scene_runner` de gdUnit4 cubre simulación de frames e
   input; GUT no lo cubre igual.
2. **`coding-standards.md` ya nombraba su runner**, y es el fichero que está en
   el repo como estándar.

`technical-preferences.md` se corrigió en el mismo changeset.

> **Lo que ningún framework resuelve**: el orden **entre señales distintas**, que
> la Regla 8 del sistema 2 exige verificar. Ni GUT ni gdUnit4 lo prueban de forma
> nativa. Por eso existe `tests/helpers/signal_order_spy.gd`.

## Estructura

```
tests/
  unit/           # Tests unitarios aislados (fórmulas, estado, lógica)
  integration/    # Cross-system y round-trips de guardado
  smoke/          # Camino crítico para la puerta de /smoke-check
  helpers/        # Fixtures y utilidades compartidas
  standalone_check.gd   # Verificador sin dependencias
```

**La evidencia NO vive aquí.** Capturas y sign-off manual van a
`production/qa/evidence/`, que es la ruta que fijan `coding-standards.md` y los
ACs **V1–V7** del sistema 1. La plantilla de `/test-setup` propone
`tests/evidence/`; se ha seguido el estándar del repo, no la plantilla.

## Helpers

| Fichero | Qué desbloquea |
|---|---|
| `helpers/boss_stub.gd` | **C12b, C19, C20, C21, C22, C23, V5, V6, V7** — nueve ACs del sistema 1 que estaban bloqueados por la ausencia de este fixture |
| `helpers/signal_order_spy.gd` | El test de **C4a** y la verificación de la Regla 8 (resolución síncrona) |

### `boss_stub.gd`

Emite los pares `inicio`/`fin de Golpe` y `inicio`/`fin de Ventana Especial` con
duraciones **en ticks enteros**, de forma determinista y sin depender de la
Máquina de Estados de Jefe (sistema 2, congelado) ni de la IA de Jefes (sistema
20, inexistente).

`disparar_ventana_especial(ticks)` es el **disparador de depuración exclusivo de
QA** que el fixture compartido de C19–C23 declara necesitar.

La 3ª pasada reclasificó este stub como **dependencia de calendario del sistema
1**, no del 20, y a **C12b como puerta de release** — su riesgo lo producen
mecánicas que existen hoy (los combos son de la Regla 9), no del sistema 20.

## Ejecutar

**Sin ningún addon** — red de seguridad y comprobación de humo rápida:

```bash
godot --headless --script tests/standalone_check.gd
```

Cubre las comprobaciones críticas de fórmulas y del ciclo de parry con GDScript
puro. No sustituye a la suite (no hay aislamiento por test ni reporte por AC),
pero responde las dos preguntas que importan: ¿compila, y salen los números?

**Con gdUnit4** — la suite real. Comando **verificado contra gdUnit4 6.2.0**:

```bash
godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/unit --ignoreHeadlessMode
```

`--ignoreHeadlessMode` **no es opcional**: gdUnit4 rechaza el modo headless por
defecto. Nuestros tests no necesitan servidor gráfico —son cálculo y contadores
de tick— así que saltarse esa guarda es correcto aquí.

> No existe `tests/gdunit4_runner.gd`. Lo hubo brevemente: era una conjetura
> sobre una API que resultó no existir (`addons/gdUnit4/GdUnitRunner.gd`), y el
> addon ya distribuye su propio runner CLI más `runtest.cmd` / `runtest.sh`.
> Añadir un tercer camino solo habría creado deriva.

El CI usa la acción oficial `MikeSchulze/gdUnit4-action`, que gestiona todo esto.

## Instalar gdUnit4

**Vía AssetLib**: Godot → AssetLib → "gdUnit4" → Descargar e Instalar → activar
en Proyecto → Ajustes → Plugins → reiniciar el editor.

> **Si el botón de descarga sale desactivado**, es porque el asset no está
> marcado como compatible con la versión del editor — habitual con versiones de
> Godot recién salidas. No es un problema de la instalación.

**Vía manual** (funciona siempre):

1. Descargar el último release de `github.com/MikeSchulze/gdUnit4/releases`
2. Descomprimir y copiar la carpeta `addons/gdUnit4/` a la raíz del proyecto
3. Proyecto → Ajustes del Proyecto → Plugins → activar **gdUnit4**
4. Proyecto → Recargar Proyecto Actual
5. Verificar que existe `res://addons/gdUnit4/` (**U mayúscula**)

## Convenciones

- **Ficheros**: `[sistema]_[caracteristica]_test.gd`
- **Funciones**: `test_[escenario]_[esperado]`
- **Ejemplo**: `combate_calidad_timing_test.gd` → `test_delta_dos_ticks_da_calidad_070()`

Reglas de `coding-standards.md` que aplican a todo test:

- **Determinismo**: mismo resultado en cada ejecución. Sin semillas aleatorias ni
  aserciones dependientes del reloj.
- **Aislamiento**: cada test monta y desmonta su propio estado; no dependen del
  orden de ejecución.
- **Sin datos hardcodeados**: fixtures por constantes o factorías, salvo en tests
  de valor de borde donde el número exacto **es** el punto (D1, C11, D15).
- **Independencia**: los unitarios no llaman a APIs externas, BD ni E/S.

## Evidencia por tipo de historia

| Tipo | Evidencia | Ubicación | Puerta |
|---|---|---|---|
| Lógica | Test unitario automatizado — debe pasar | `tests/unit/[sistema]/` | BLOQUEANTE |
| Integración | Test de integración O playtest documentado | `tests/integration/[sistema]/` | BLOQUEANTE |
| Visual/Feel | Captura + sign-off del lead nominado | `production/qa/evidence/` | ADVISORY |
| UI | Walkthrough manual O test de interacción | `production/qa/evidence/` | ADVISORY |
| Config/Datos | Smoke check | `production/qa/smoke-[fecha].md` | ADVISORY |

## Qué NO automatizar

Fidelidad visual, cualidades de "feel", renderizado específico de plataforma y
sesiones completas de juego. Van a playtest, no a CI.

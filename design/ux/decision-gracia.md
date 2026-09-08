# UX Specification: Decisión de Gracia (TOMAR / DEJAR IR)

> **Status**: Draft
> **Author**: ux-designer
> **Last Updated**: 2026-09-05
> **Screen / Flow Name**: `DecisionGracia` (pantalla Decisión absorber/rechazar)
> **Platform Target**: PC (Steam) + Steam Deck (mando primario, teclado/ratón totalmente soportado, sin táctil)
> **Related GDDs**: `design/gdd/gracia-tres-capas.md` §UI Requirements + G4/G5/G6/G7/G10 · `design/gdd/combate-parry-absorcion.md` §UI Requirements (Vida/Postura/timer/Gracia, C14, R2) · `design/gdd/feedback-impacto.md` Overview + R1 (juicio ≤2 ticks pared / confirmación ≤10 ticks, transient vs sustain) · `design/gdd/guardado-de-progreso.md` §Fachada + R5/R9 (solo `post_decision`, jamás `pre_eleccion`) · `design/gdd/menu-principal-y-flujo-de-pantallas.md` R4/R6/R7 (firma Tipo-A, skip cerrado, foco sin brillo)
> **Related ADRs**: Ninguno aprobado. Pendientes que constriñen esta pantalla: ADR de tiempo (Pattern-A 0% + WallTick/DiegeticTick, bloquea implementar — Feedback Open Questions) · ADR de arranque/router (`change_scene` único, splash) · ADR checksum/canonicalización (SHA-256, auto-excluido — Guardado R6)
> **Related UX Specs**: `design/ux/hud.md` (Decisión: HUD oculto salvo Gracia NW alta luminancia) · `design/ux/interaction-patterns.md` P1/P2/P3 (filosofía compartida + firma VE)
> **Accessibility Tier**: Comprehensive (propuesto — WCAG-AA como baseline per `hud.md`; pendiente `design/accessibility-requirements.md` + `/gate-check`)

> **Scope boundary**: Esta spec cubre una pantalla discreta ceremonial (modo UI distinto del HUD de combate — admite centro ocupado, Gracia G4/G5). Para el overlay persistente durante duelo activo, ver `hud.md`. La Decisión no es HUD: es decisión moral irrevocable post-reliquia, enrutada por #15, propiedad de #5.

---

## 1. Purpose & Player Need

**What player need does this screen serve?**

Tras vencer a un ángel, el jugador carga gracia robada que aún no ha decidido qué hacer con ella. Necesita un lugar quieto donde entender lo que le cuesta tomarla (poder real + veta permanente + suelo que ya no baja) frente a lo que le cuesta dejarla ir (digno, sin poder, con un alivio real de −6 hasta el suelo) y decidir sin prisa, sin timer y sin que el juego lo empuje a ninguna de las dos. Si esta pantalla apurase, premiase o castigase visualmente una opción, el dilema colapsaría y el Pilar 1 ("el poder duele") se volvería sermón.

**The player goal**: Elegir TOMAR o DEJAR IR con plena comprensión del coste irreversible de cada opción, en un solo gesto deliberado, sin posibilidad de deshacer por recarga.

**The game goal**: Registrar un commit atómico e irrevocable (`decision_absorber[i] ∈ {0,1}`, `angeles_absorbidos = suma`) en memoria antes de cualquier animación, y exponerlo a Guardado solo como `post_decision` (jamás `pre_eleccion`), sin crear ninguna vía de re-elección, omisión o absorción parcial (Gracia G4).

---

## 2. Player Context on Arrival

| Question | Answer |
|----------|--------|
| What was the player just doing? | Ganó un duelo (ángel en brasas), pasó por Reliquias (#14). Viene de tensión alta + alivio. El cuerpo ya muestra vetas si hubo absorciones previas. |
| What is their emotional state? | Ambivalencia diseñada (Pilar 1 + Pilar 5): el ángel sigue luminoso y bueno mientras lo tomas; el dolor viene de que era bueno. La pantalla debe sostener duelo, no botín. |
| What cognitive load are they carrying? | Media-baja: sin amenazas activas, sin timer, sin Postura/Vida que vigilar. Solo tres números vivos (gracia/corrupción/poso) + dos futuros (qué pasa si TOMO / si DEJO IR). |
| What information do they already have? | Sabe cuánta gracia robó con sus manos (earn por parry), sabe que ganó, sabe que hay una elección pendiente. No sabe aún el delta exacto de cada botón. |
| What are they most likely trying to do? | Comparar los dos futuros en igualdad y commitear (caso primario). Caso secundario: leer la línea de ledger para confirmar dónde está su suelo. |
| What are they likely afraid of? | Equivocarse de botón por mash del duelo, romper sin querer lo irreversible, o que salir/crash le robe la elección. |

**Emotional design target for this screen**: Sobriedad ceremonial — "el coro espera tu mano": el jugador siente peso sin amenaza, claridad sin prisa y dignidad en ambas opciones (el rechazo jamás se presenta menor, apologético, atenuado ni en timbre menor).

Verba normativa (Gracia G1): `tomar / cargar / aliviar / poso / dejar ir`. Jamás `loot/almas/maná`.

---

## 3. Navigation Position

**Screen hierarchy**:

```
MenuPrincipal
└── Hub (punto seguro, SUS vigente)
    └── Duelo
        └── Victoria → Reliquias (#14, enrutada ajena)
            └── DecisionGracia (#5, esta pantalla)
                └── Hub (post-decisión, SUS nueva `post_decision`)
```

**Modal behavior**: Modal de commit obligatorio (bloquea todo lo detrás, exige resolución explícita). No es overlay-live: el duelo ya terminó, no hay simulación corriendo detrás. No es dismissable: no hay atrás, no hay omitir, no hay salir con botón.

**Reachability — all entry points**:

| Entry Point | Triggered By | Notes |
|-------------|-------------|-------|
| Victoria → Reliquias → Decisión | Sistema 5 vía router #15, tras commit de loadout de #14 | Única entrada primaria. Entrada exacta: post-reliquia, pre-Hub. Jamás directo post-reliquia→Hub (sería re-elegir por recarga — Menú States). |
| Re-arranque tras quit/kill con Decisión abierta | Carga de última SUS `post_decision` (Guardado R9 + Gracia Edge quit/kill) | No es "volver a la Decisión": es volver al último punto seguro anterior; los deltas del duelo recién ganado se PIERDEN (fail-closed anti-scum, diseñado, no data loss). |
| Sleep/resume en Decisión | SO despierta, pantalla + foco preservados | Jamás auto-commit al dormir ni al despertar. Primer delta post-resume se descarta (playtime +0, coherente con Guardado F-playtime). |

`ui_cancel` en esta pantalla = no-op + error sordo (sin atrás, sin omitir — Gracia UI Requirements). No hay salida "Salir al menú" ni "Continuar" en esta pantalla (prohibido mostrar Continuar/estado_red — ver §5).

---

## 4. Entry & Exit Points

**Entry table**:

| Trigger | Source Screen / State | Transition Type | Data Passed In | Notes |
|---------|----------------------|-----------------|----------------|-------|
| Victoria confirmada + loadout #14 commiteado | Reliquias → Decisión (router #15) | Corte o fundido corto ≤300 ms (Menú R6); con reduced-motion siempre corte 1 frame | Snapshot de lectura: `{gracia_actual, corrupcion_actual, poso_irreversible, angeles_absorbidos, decision_absorber[], coro_idx, poder_desbloqueable:{id,nombre}}` + `punto_seguro=false` | La pantalla abre con foco NEUTRO (ninguno) — excepción justificada a Menú R7 (ver §7). El ángel aparece en brasas inmóvil, sin timer. |
| Rehidratación NO aplica | — | — | — | Esta pantalla jamás se rehidrata desde SUS: SUS solo existe en `post_decision`. Si no hay commit, no hay SUS nueva. |

**Exit table**:

| Exit Action | Destination | Transition Type | Data Returned / Saved | Notes |
|-------------|------------|-----------------|----------------------|-------|
| Commit TOMAR (single-press + flanco fresco) | Hub (post-decisión) | Commit atómico en memoria SÍNCRONO pre-animación → animación (succión +1 rosetón) → corte a Hub | Memoria: `n+1, poso+12, vida_max+18, poder on, C'=max(C,poso')`, sin lump de gracia; Guardado: 1 write `post_decision` (triple + n + decision_absorber verbatim), 0 `pre_eleccion` (Gracia GR-11) | Ambos botones se deshabilitan el mismo frame + swallow 200 ms. SIN hold. |
| Commit DEJAR IR (single-press + flanco fresco) | Hub (post-decisión) | Commit atómico en memoria → animación (ascenso sin rosetón) → corte a Hub | Memoria: `C'=max(poso,C−6.0)`, sin Vida/poso/poder; Guardado: 1 write `post_decision` | Digno, jamás castigo: sin dimming, sin timbre menor, sin animación menor. |
| Quit/kill con Decisión abierta | (fuera de pantalla) Al recargar: última SUS `post_decision` o S1 | Sin commit, sin SUS mutada; kill ≡ cancelar | Cero escrituras #5; Guardado: sin SUS nueva | Línea honesta `MENU_DECISION_QUIT_LINE` siempre visible (ver §5). |
| Sleep | Misma pantalla preservada | Corte, foco preservado, jamás auto-commit | Nada | Modal preservado con foco (Menú Edge sleep-en-modal). |

Toda transición voluntaria no listada es inválida (Menú States). Entrar a Hub solo vía post-decisión.

---

## 5. Layout Specification

Base 1280×800, safe-zone 5% por borde (rango 3–7%, mínimo absoluto 3% — Menú R7). Texto funcional ≥18px aparente a 30–40 cm en Deck 7", escalado proporcional al alto del canvas con piso 18. Foco: borde 2px `#C7CDD6` + marcador de cuneta + peso de etiqueta, nunca glow (principio art-bible 2: solo lo divino emite luz), nada por hover (dual-focus: hover no roba foco de mando).

Modo ceremonial: a diferencia del HUD de combate (centro 60% libre siempre), esta pantalla ADMITE centro ocupado (Gracia UI Requirements). HUD de combate oculto salvo medidor Gracia NW en alta luminancia — "la decisión ES gracia" (`hud.md` Dynamic Behaviors + P3).

### 5.1 Wireframe

```text
┌────────────────────────────────────────┐  ← safe-zone 5% ((64,40) a 1280×800)
│ [Gracia ◆◆◇◇ alta-lum]                 │  ← NW: único HUD vivo (propiedad #13)
│                                        │
│      {ÁNGEL EN BRASAS, inmóvil}        │  ← CENTRO: sin timer, sin números flotantes
│      "El coro espera tu mano"          │  ← MENU_DECISION_TITLE (≤120 chars)
│                                        │
│   [ TOMAR ]          [ DEJAR IR ]      │  ← CENTRO-BAJO: díada en igualdad visual
│   +18 Vida máx       purga −6→suelo    │     (rechazo jamás menor/apologético)
│   +12 poso           sin Vida/poso/    │
│   desbloquea:{poder} poder             │
│   gracia/corrup/poso línea ledger     │  ← MENU_DECISION_LEDGER
│                                        │
│  Irreversible: lo hecho, hecho está.   │  ← S: MENU_DECISION_IRREVERSIBLE
│  Si sales ahora, esta elección         │  ← S: MENU_DECISION_QUIT_LINE
│  queda sin guardar.                    │
└────────────────────────────────────────┘
Prohibido en esta pantalla: Vida/Postura/timer/peek numérico/
estado_red/Continuar/flash #C75C4A/hold prompt/lista destructiva R4.
```

### 5.2 Zone Definitions

| Zone Name | Description | Approximate Size | Scrollable? | Overflow Behavior |
|-----------|-------------|-----------------|-------------|-------------------|
| NW Gracia | Medidor Gracia alta luminancia (único vitral permitido, art-bible 3.4). Solo lectura, con respaldo de forma (densidad de grieta, no solo croma). | ≤6% pantalla (presupuesto NW heredado `hud.md`) | No | Nunca muestra números exactos (prohibido peek numérico); cuantifica lo que el cuerpo ya muestra |
| Centro ceremonial | Ángel en brasas inmóvil + título `MENU_DECISION_TITLE`. Sin timer, sin telegrafiados, sin números flotantes sobre el ángel (prohibición HUD). | Centro libre para ceremonia (excepción al 60% de combate) | No | Con reduced-motion: brasas estáticas, corte, sin vignette pulsante |
| Díada centro-bajo | Dos botones `TOMAR / DEJAR IR` en igualdad visual estricta (mismo tamaño, peso, luminancia base; foco neutro inicial). Cada uno con label + desc + línea ledger. | ~40% ancho cada uno, misma métrica | No | Texto vía `tr()` + placeholders `{poder} {vida} {poso} {purga}`; ≤120 chars post-interpolación (fija `/localize`); alemán +40% debe caber sin romper igualdad |
| S irreversibilidad | Dos líneas: `MENU_DECISION_IRREVERSIBLE` + `MENU_DECISION_QUIT_LINE`. Sobrias, persistentes, ≥18px. | Full width, ~10% alto | No | Jamás tecnicismos ("suspensión/perfil/versión/loadout/run" vetados en superficie — Menú §Claves salvo S4/S5/diagnóstico) |

### 5.3 Component Inventory

| Component Name | Type | Zone | Purpose | Required? | Reuses Existing Component? |
|----------------|------|------|---------|-----------|---------------------------|
| Medidor Gracia NW | Barra/esquirlas rombo ◆◆◇◇ (dirección A1, P3) | NW | Cuantificar gracia robada en alta luminancia; único HUD vivo | Yes | Yes — `gracia_shards.gd` (rombos + `set_prelight`), solo lectura, `queue_redraw` event-driven |
| Ángel en brasas | Sprite/animación diegética inmóvil | Centro | Ancla ceremonial; luz remanente que será succionada (TOMAR) o ascenderá (DEJAR IR) | Yes | No — staging propio #5/#6 (quiebre a vitral pleno en saturación es propiedad #6) |
| Título decisión | Text (`MENU_DECISION_TITLE`) | Centro | "El coro espera tu mano" (provisional es-MX, fija `/localize`) | Yes | Yes — ScreenTitle, vía `tr()` |
| Botón TOMAR | Primary Button (sin jerarquía sobre el otro) | Díada | Commitea absorber: `+18 Vida máx, +12 poso, desbloquea:{poder}`, línea ledger; nombra el coste (el gasto solo alivia hasta el suelo) | Yes | No — díada propia (igualdad visual estricta, sin Primary/Secondary) |
| Botón DEJAR IR | Button idéntico en peso | Díada | Commitea rechazar: `purga −6 hasta suelo`, explícito `sin Vida, sin poso, sin poder` | Yes | No — gemelo del anterior |
| Línea ledger | Text (`MENU_DECISION_LEDGER`) | Díada/S | `gracia/corrupción/poso` actuales (crudos, formato owned #5; display owned Menú) | Yes | Yes — BodyText |
| Línea irreversibilidad | Text (`MENU_DECISION_IRREVERSIBLE`) | S | "Lo hecho, hecho está" (tono sobrio, sin amenaza) | Yes | Yes — BodyText |
| Línea quit | Text (`MENU_DECISION_QUIT_LINE`) | S | "Si sales ahora, esta elección queda sin guardar" | Yes | Yes — BodyText |
| Foco neutro + borde | Focus ring 2px `#C7CDD6` + cuneta, 0 glow | Díada | Excepción a Menú R7: ninguno enfocado al abrir (ver §7) | Yes | Yes — NavButton focus style (sin glow) |

**Primary focus element on open**: NINGUNO (foco neutro). Primer `ui_left/right` discreto agarra; trampa en díada (ver §7).

---

## 6. States & Variants

| State Name | Trigger | What Changes Visually | What Changes Behaviorally | Notes |
|------------|---------|----------------------|--------------------------|-------|
| Apertura (foco neutro) | Entrada post-reliquia | Díada sin foco; título + ledger visibles; brasas inmóviles | Solo `ui_left/right` discretos agarran; `ui_accept` sin foco = no-op; `ui_cancel` = no-op + error sordo | Excepción justificada a Menú R7: ambos commits son single-press irrevocables y el flanco fresco no para mash fresco; mover primero rompe la cadena (Gracia UI Requirements). |
| Foco en TOMAR | Primer/discreto `ui_left` o navegación | Borde 2px + cuneta + peso en TOMAR; DEJAR IR intacto (sin dimming del no-enfocado) | `ui_accept` (flanco fresco) commitea TOMAR; `ui_cancel` no-op | Igualdad visual: enfocar uno jamás empequeñece/apaga al otro (rechazo jamás menor). |
| Foco en DEJAR IR | Primer/discreto `ui_right` o navegación | Espejo del anterior | `ui_accept` commitea DEJAR IR | Trampa en díada: navegar no escapa a zonas inexistentes (no hay otras zonas enfocables). |
| Commit TOMAR (juicio→confirmación) | `ui_accept` con flanco fresco sobre TOMAR | Mismo frame: ambos botones deshabilitados; succión de luz a silueta inicia; sting sobrio `ui_cometer_irrevocable` | Commit atómico en memoria SÍNCRONO pre-animación; dedupe por tick + consume/inhibe/swallow 200 ms; 2º input mismo tick tumbado | Animación es sustain, no onset (Feedback R1). Skippable por flanco discreto (acorta velo, nunca el commit). |
| Commit DEJAR IR | Espejo | Ascenso y desvanecimiento, sin veta nueva; variante resolución sobria (misma familia, nunca error) | Mismo protocolo de commit | Sin rosetón nuevo (Overlay 4–6 anclajes solo en TOMAR). |
| Quit/kill abierta | Cierre/kill sin commit | (fuera de pantalla) Sin SUS nueva | Al recargar: última SUS `post_decision`; deltas del duelo perdidos | Diseñado fail-closed anti-scum (Gracia Edge). Sin botón salir en pantalla. |
| Sleep | Deck duerme | Pantalla + foco preservados al resumir | Jamás auto-commit; primer delta descartado | Modal preservado con foco (Menú Edge). |
| Saturada (C≥100 al entrar) | Ledger clamped entrante | Mismo layout; vitral-congela es propiedad #6 (este GDD congela ledgers) | TOMAR legal (n+1, Vida+18, poso `min(+12,techo)`, C clamped, saturación NO se desengancha); DEJAR IR aplica aritmética pero handoff NO se retracta (#6 posee continuación) | Sin caso especial de layout: la saturación es handoff, no muerte (Gracia G8). GASTO deshabilitado (no hay gasto en Decisión de todos modos — I2). |
| Purga-en-suelo visible | C==poso al entrar | Línea ledger lo muestra tal cual (UX anota, no regla) | Ambos commits legales; TOMAR levanta C al nuevo suelo (`C'=max(C,poso')`, floor-lift); DEJAR IR `max(poso,C−6)` = poso | No es error ni empty state. |
| Error — ledger inválido (NaN, ausente, decision_absorber≠n, poso decreciente, n>3 en v1.0) | Validación de entrada | Diagnóstico sobrio (sin tecnicismos en superficie; códigos owned Guardado §Fachada) | Sin commit posible; escala a Guardado/Gracia (descarte SUS entera, sin defaults que fabriquen monotonicidad) | Fuente de verdad: decision_absorber es source of truth, n su checksum (Gracia Edge round-trip). |

Prohibido en todos los estados: Vida/Postura/timer/peek numérico/`estado_red`/Continuar/flash `#C75C4A`/hold prompt/lista destructiva R4 (Gracia UI Requirements).

---

## 7. Interaction Map

Filosofía compartida (interaction-patterns): periferia screen-space, formas rectas y finas, sin vocabulario circular, cambios críticos sin ease-in, todo texto vía `tr()`, `mouse_filter` IGNORE donde no interactivo, teclado + mando completos sin hover, parry digital (ningún eje analógico — C24), animaciones skippables + reduced-motion.

### 7.1 Navigation Inputs

| Input | Platform | Action | Visual Response | Audio Cue | Notes |
|-------|----------|--------|-----------------|-----------|-------|
| `ui_left` / `ui_right` (D-Pad, stick discreto, flechas) — flanco fresco | Gamepad + KB | Agarra foco desde neutro; mueve dentro de díada con trampa | Borde 2px `#C7CDD6` + cuneta + peso aparece/mueve | `ui_foco` por bus de eventos (timbres propiedad #16), nunca directo | Motion/ejes held/gyro/conexión/sueño jamás disparan (Menú R6-INPUT). Solo flancos `pressed` discretos. |
| `ui_accept` sin foco (neutro) | All | No-op | Nada (sin shake, sin flash) | Nada o error sordo mínimo (no `ui_error_duelo`) | Mover primero rompe la cadena anti-mash: aceptar en neutro no debe commitear. |
| Hover / mouse-move | PC | Nada | Sin hover state que robe foco (dual-focus: hover no roba foco de mando — Menú R7) | None | Click sí enfoca+commitea solo con flanco fresco (ver 7.2). Sin tooltips dependientes. |
| Desconexión/reconexión de mando | Deck/PC | Foco almacenado, fallback a teclado; re-grab al reconectar | Foco restaurado al elemento almacenado (o neutro si era neutro) | None | Verificar en Deck real (Menú R7 + Open Questions). |

### 7.2 Action Inputs

| Input | Platform | Context (What must be focused) | Action | Response | Animation | Audio Cue | Notes |
|-------|----------|-------------------------------|--------|----------|-----------|-----------|-------|
| `ui_accept` (flanco fresco) | All | TOMAR enfocado | Commit TOMAR | Mismo frame: ambos deshabilitados; succión +1 rosetón; → Hub | Succión sobria (art-bible fila 5); skippable por flanco discreto; reduced-motion: corte + brasas estáticas | Sting `ui_cometer_irrevocable` (familia sobria, no error; propiedad #16) | Single-press + flanco fresco + dedupe por tick + consume/inhibe/swallow 200 ms. SIN hold (reservado a destrucción run/SUS — Gracia #15). |
| `ui_accept` (flanco fresco) | All | DEJAR IR enfocado | Commit DEJAR IR | Espejo: ascenso sin rosetón; → Hub | Ascenso sobrio (fila 5); skippable; reduced-motion igual | Variante resolución sobria (misma familia, nunca error) | Mismo protocolo. Digno, jamás castigo. |
| Click principal (flanco fresco) | PC | Sobre botón | Enfoca + commitea (un solo gesto cuenta como flanco fresco) | Espejo del commit correspondiente | Espejo | Espejo | Input que dispara transición no cuenta como skip (Menú R6). Handler consume + inhibe destino 1 frame + swallow 200 ms. |
| `ui_cancel` (B/Esc) | All | Cualquiera (abierta) | No-op + error sordo | Nada visual (sin atrás, sin sacudida) | None | `ui_error_bloqueado` sordo por bus | Sin atrás, sin omitir (Gracia). No es Tipo-A: no hay hold, no hay modal. |
| Segundo `ui_accept` mismo tick | All | Cualquiera post-commit | Tumbado (descartado por guardia de estado: ya salió de `Decisión` → Hub) | Nada | Nada | Nada | Defensa en profundidad: flanco fresco de Menú tumba el 2º en presentación; el 1º ya salió de estado (Gracia Edge doble-commit). |
| Intento de gasto (binding discreto G7) | All | Decisión abierta | Descartado sin buffer (ilegal: I2) | Blip de denegación solo si el binding existe en Hub (aquí: nada o sordo) | None | None/denegación por bus | "Primero decidir, gastar en el Hub" (Gracia G7). Binding gasto ≠ botón parry. |

### 7.3 State-Specific Behaviors

| State | Input Restriction | Reason |
|-------|------------------|--------|
| Apertura neutra | `ui_accept` sin foco deshabilitado (no-op) | Evita commit por mash heredado del duelo; exige gesto direccional deliberado primero |
| Commit en curso (post-flanco, pre-Hub) | Todo input consumido/inhibido 200 ms; ambos botones deshabilitados mismo frame | Cierra raza de doble-commit (Gracia GX-07) |
| Sleep/modal | Input de menú consume; latch suprimido | Coherente con Feedback R12 (latch suprimido en menú) |
| Reduced-motion ON | Corte 1 frame, sin fades/flashes/viñeta animada; tick seco | Menú R6 + `hud.md` + Feedback: shake/hitstop son gameplay, aquí no hay shake; todo ceremonial colapsa a corte |

**Firma destructiva/irreversible — por qué single-press y no hold Tipo-A**: El hold de 1 s + listado (Menú R4) protege destrucción de run/SUS (Comenzar con SUS, Abandonar, Reset, Restaurar, Migración). La Decisión es irreversible de otro tipo: commit moral que Guardado vuelve durable en `post_decision`. Aplicarle hold castigaría el Pilar 4 con fricción donde la ficción pide mano temblorosa pero libre — decisión adjudicada en Gracia #15: "single-press + flanco fresco, SIN hold (el hold protege destrucción de run/SUS; aquí la fricción castigaría P4)". La irreversibilidad se comunica por línea explícita + commit atómico + imposibilidad de re-elegir por recarga, no por fricción mecánica. Requiere back-link en #15 (tabla + inventario `MENU_DECISION_*`).

---

## 8. Data Requirements

Regla: esta pantalla nunca escribe directamente en ningún sistema. Lee ledgers y fachada; commitea vía eventos (ver §9). Sistemas actualizan sus datos y notifican a la UI.

| Data Element | Source System | Update Frequency | Who Owns It | Format | Null / Missing Handling |
|--------------|--------------|-----------------|-------------|--------|------------------------|
| `gracia_actual` (bolsa gastable) | Gracia #5 (solo-lectura: `gracia_cambiada`) | Al abrir (snapshot) — sin earn/gasto durante Decisión (I2, sin faucet en Hub/Decisión) | #5 (Gracia posee semántica y techos) | float ≥0 JSON-safe, epsilon `1e-9` identidad / `1e-6` cero | NaN/ausente → sin commit, escala a descarte (Gracia Edge round-trip: descarta SUS entera, sin defaults) |
| `corrupcion_actual` (progreso a Clímax) | Gracia #5 (`corrupcion_cambiada`) | Al abrir | #5 | float, invariante `poso ≤ C ≤ 100` | Violación → sin commit |
| `poso_irreversible` (suelo) | Gracia #5 (`poso_cambiado`) | Al abrir | #5 | float ∈ `{0,12,24,36}` v1.0, monótono (jamás baja al gastar) | Cargado<memoria / decreciente → descarte (requiere fila AC en Guardado — Gracia #5→#12) |
| `angeles_absorbidos` (n) + `decision_absorber[]` | Gracia #5 | Al abrir | #5 (decision_absorber source of truth, n checksum; `len(decision_absorber)==n==TOMARs`) | int 0–3 v1.0 (0–9 versión); decision_absorber Array 0/1 | `len≠n` / n>3 en v1.0 → rechazo forward-incompatible, sin clampar |
| `poder_desbloqueable` (identidad coro) | Gracia #5 (G5c: ficción por identidad, magnitudes idénticas) | Al abrir | #5 | `{id, nombre_key}` (magnitudes fuera de esta pantalla) | Ausente → TOMAR muestra `desbloquea:{—}` jamás inventa magnitud |
| `punto_seguro` (false durante Decisión) | Guardado #12 (evento/booleano; `pre_eleccion==no-seguro` incluido) | Al abrir (siempre false aquí) | #12 | bool/evento | Si true aquí = bug de enrutado (nunca SUS escribible pre-commit) |
| `resumen_continuar` / `ultimo_motivo_sin_continuar` / `destino_continuar_id` | Guardado §Fachada | NO se consumen en esta pantalla | #12 (Menú los consume en MenuPrincipal/Hub) | — | Prohibido mostrar Continuar/estado_red aquí (Gracia UI Requirements) |
| `saturacion_alcanzada` (si C≥100) | Gracia → Clímax #6 (solo-lectura) | Al abrir (una vez por entrada, sin re-emitir) | #6 posee continuación (94-tras-100 es de #6) | `{triple snapshot, absorbidos}` | No cambia layout; GASTO off (irrelevante aquí) |

Cálculos mostrados (owned #5, esta pantalla solo interpola, jamás recalcula): TOMAR → `+18 Vida máx` (F5 Combate, plano v1.0) + `+12 poso` + `C'=max(C,poso')`; DEJAR IR → `C'=max(poso,C−6.0)`, sin Vida/poso/poder. Sin lump de gracia en TOMAR (evita doble-contar ingreso por parry — G5).

---

## 9. Events Fired

| Player Action | Event Fired | Payload | Receiver System | Notes |
|---------------|-------------|---------|-----------------|-------|
| Commit TOMAR | `decision_commit_tomar` (nombre ilustrativo; el nombre canónico lo fija arquitectura) | `{coro_idx, n_previo, triple_previo{g,c,poso}, poder_id}` | Gracia #5 (aplica G5 atómico) → Guardado (1 write `post_decision`) → router #15 (→Hub) | Memoria actualiza síncrona pre-animación (Gracia GR-11). Sistemas confirman; UI escucha confirmación para animar. |
| Commit DEJAR IR | `decision_commit_dejar_ir` | `{coro_idx, triple_previo}` | Gracia #5 (aplica G6) → Guardado (`post_decision`) → router #15 | Misma familia sonora, nunca error. |
| Foco agarra/mueve | `ui_foco` (catálogo cerrado Menú Interactions) | `{elemento}` | Audio #16 (timbre) + analytics si aplica | Timbres, niveles, ducking propiedad #16; el menú emite, jamás reproduce directo. |
| Cancelar (`ui_cancel`) | `ui_error_bloqueado` (sordo) | `{pantalla: DecisionGracia}` | Audio #16 | No-op lógico; solo feedback de bloqueo. |
| Cierre/animación solicitada | `transicion_solicitada` | `{origen: Decision, destino: Hub}` | Audio #16 (crossfade) + router | Tweens ignoran escala de tiempo (Menú R6); con reduced-motion corte 1 frame. |
| Commit confirmado (sistema→UI) | `decision_confirmada` (escucha, no emite) | `{opcion, triple_nuevo, n_nuevo}` | Esta pantalla (anima succión/ascenso → Hub) | La animación es sustain post-commit, nunca precondición del commit. |

Prohibido emitir: cualquier setter a ledgers (`gracia_cambiada/corrupcion_cambiada/poso_cambiado` son solo-lectura; setter desde observador falla — Gracia GR-31/GX-08).

---

## 10. Transition & Animation

Juicio vs confirmación (Feedback Overview/R1, vocabulario aplicado a UI ceremonial): el **juicio** (qué pasó) viaja en el transient de entrada; la **confirmación** (cuánto valió) es sustain al cierre. En Decisión no hay freeze (pausa total diegética 0% es vocabulario de robo-de-gracia en duelo); hay commit + sustain ceremonial.

| Transition | Trigger | Direction / Type | Duration (ms) | Easing | Interruptible? | Skipped by Reduced Motion? |
|------------|---------|-----------------|--------------|--------|----------------|---------------------------|
| Entrada Reliquias→Decisión | Router #15 | Corte o fundido corto a negro overlay ≤300 ms (lanzamiento 200 ms) | ≤300 | N/A (corte) o ease-out | Solo por flancos discretos `{ui_accept, ui_cancel, click}`; el input que disparó no cuenta como skip; consume + inhibe 1 frame + swallow 200 ms (Menú R6) | Yes — siempre corte 1 frame, sin fade/flash/viñeta animada |
| Juicio TOMAR (transient) | Flanco fresco `ui_accept` | Mismo frame: ambos botones deshabilitados + succión inicia + sting sobrio | Mismo frame (≤2 ticks pared como techo de juicio heredado de Feedback; aquí el commit es memoria, no física) | Sin ease-in (cambios críticos sin ease-in — art-bible/combate) | No — debe completar antes de habilitar nada | No es motion decorativa: es feedback táctil de commit (análogo a press 60 ms de ux-spec que no se skipea) |
| Confirmación TOMAR (sustain) | Post-commit | Luz remanente succionada a silueta +1 rosetón de veta permanente (art-bible fila 5) | Ceremonial breve (fija #5/#16; skippable) | Sobria, sin celebración (`¡NUEVA FORMA!` prohibido) | Yes — flanco discreto acorta velo, nunca el commit ni la carga a Hub (patrón Hub→Duelo: skip acorta velo, nunca carga) | Yes — corte + brasas estáticas + sonidos por bus |
| Juicio DEJAR IR | Espejo | Mismo frame disable + ascenso inicia + variante sobria | Mismo frame | Sin ease-in | No | No (táctil) |
| Confirmación DEJAR IR | Post-commit | Luz que asciende y se desvanece, sin veta nueva (fila 5) | Ceremonial breve, skippable | Digna, nunca menor | Yes | Yes — corte + estáticas |
| Salida Decisión→Hub | Fin de sustain o skip | Corte a Hub (retorno por corte — `hud.md` Pausa/Hub) | Corte 1 tick / ≤200 ms | Corte | No | Corte (ya es corte) |
| Gasto Purga/Amparo | N/A aquí | Vetas laten al gastar (cuerpo) — referenciado, no animado aquí | — | — | — | Sin flash nuevo (Gracia Visual) |

Solo brilla lo divino o la gracia robada; protagonista, mundo y UI jamás emiten luz (art-bible §§1–2). Prohibido: celebraciones de absorción, vitral cool sin duelo, números flotantes de gracia sobre el ángel, tercer lenguaje visual fuera de tinta/vitral/UI-frío, flashes punitivos de luz.

---

## 11. Input Method Completeness Checklist

**Keyboard**
- [ ] Todos los interactivos (díada) alcanzables solo con flechas/Tab; orden: neutro → TOMAR ↔ DEJAR IR con trampa (Tab no escapa a zonas inexistentes)
- [ ] Tab sigue orden de lectura (izq→der en díada a 1280×800; espejar en RTL si `/localize` lo exige)
- [ ] Toda acción de ratón (click) replicable por teclado (`ui_accept` con flanco fresco)
- [ ] Foco visible siempre que existe (borde 2px + cuneta, 0 glow); en neutro la ausencia es intencional y documentada (§6/§7)
- [ ] Foco no escapa (trampa en díada; sin otras zonas)
- [ ] Esc = `ui_cancel` = no-op + error sordo (no cierra juego ni sale de pantalla)

**Gamepad** (primario — technical-preferences Input & Platform)
- [ ] Todo alcanzable con D-Pad + stick discreto (ninguna precisión analógica; parry digital C24 como constraint heredado: ningún eje analógico mapeable a acciones binarias)
- [ ] `ui_accept` = commit (flanco fresco), `ui_cancel` = no-op sordo; mapeo consistente con Menú R4/R6
- [ ] Sin acción que exija precisión de stick irreplicable con D-Pad
- [ ] Sin atajos de gatillo/bumper en esta pantalla (no documentar los que no existen)
- [ ] Desconexión en pantalla: foco almacenado + fallback teclado + re-grab al reconectar (verificar en Deck real)

**Mouse**
- [ ] Sin estados de hover que roben foco o gates información (nada depende de hover — Menú R7, `hud.md`)
- [ ] Hit targets ≥32×32px (preferido 44×44); díada a 1280×800 los supera por construcción
- [ ] Right-click = no-op definido (no undefined)
- [ ] Sin zonas scrollables (no aplica wheel)

**Touch**: N/A (Touch Support: None — technical-preferences).

---

## 12. Screen-Level Accessibility Requirements

Tier propuesto: **Comprehensive** (Standard + reduced motion + text scaling + high contrast). Todo texto vía `tr()` (cero hardcodeado). Verificación en hardware Deck real (legibilidad + foco por mando), no solo PC.

**Text contrast requirements for this screen**:

| Text Element | Background Context | Required Ratio | Current Ratio | Pass? |
|--------------|-------------------|---------------|---------------|-------|
| Título `MENU_DECISION_TITLE` | Tinta penumbra (fondo oscuro) | 4.5:1 (WCAG AA normal) | TBD — verificar en implementación | [ ] |
| Labels TOMAR / DEJAR IR (enfocado y no-enfocado) | Botón tinta + borde `#C7CDD6` | 4.5:1 ambos estados (el no-enfocado jamás baja luminancia para "jerarquizar") | TBD | [ ] |
| Desc + línea ledger | Tinta | 4.5:1 | TBD | [ ] |
| Líneas S (irreversibilidad + quit) | Tinta | 4.5:1 (son funcionales, no "discretas por tamaño" — lo discreto se logra por posición/luminancia, Menú R7) | TBD | [ ] |
| Medidor Gracia NW (si lleva etiqueta) | Vitral sobre tinta | 4.5:1; además respaldo de forma | TBD | [ ] |

**Colorblind-unsafe elements and mitigations**:

| Element | Colorblind Risk | Mitigation |
|---------|----------------|------------|
| Medidor Gracia (vitral violeta sobre tinta) | Deuteranopia/protanopia/tritanopia — periferia además no lee croma (Combate UI Requirements: luminancia, no croma) | Respaldo de forma obligatorio: densidad de grieta/esquirlas ◆◆◇◇ + posición NW + movimiento (succión/ascenso); color redundante, jamás único. Contraste de luminancia explícito (fija spec #13; `timer_high_contrast`-análogo en alta luminancia Deck). |
| TOMAR vs DEJAR IR (si se tiñesen distinto) | Cualquiera si el único diferencial fuese croma | PROHIBIDO diferenciar por color: igualdad visual estricta + labels + ledger textual + foco por forma (borde + cuneta + peso). |
| Brasas / succión / ascenso | Luminancia como único canal | Movimiento + forma (dirección succionar-hacia-dentro vs ascender-hacia-fuera, espejo de Feedback direcciones inward/outward) + sting sonoro por bus; reduced-motion: corte + estáticas + tick seco. |
| Flash `#C75C4A` | Fotosensibilidad + solo-color | PROHIBIDO en esta pantalla (Gracia UI Requirements). Knob heredado `disable_damage_flash` no aplica aquí porque no hay flash que sustituir; si algún estado futuro lo necesitase, sustituto por icono con forma. |

**Focus order** (secuencia, numbered):
1. (Neutra: ninguno — intencional) →
2. Primer `ui_left/right` discreto agarra (dirección: `left`→TOMAR, `right`→DEJAR IR; si el idioma RTL espeja la díada, espejar el mapeo y documentarlo en `/localize`) →
3. TOMAR ↔ DEJAR IR (trampa, cicla dentro de díada) →
No entra al medidor NW (display-only, driven por ledger) ni a líneas S (display-only). Foco anunciado por lector: nombre accesible = label+desc+ledger (Gracia a11y).

**Screen reader announcements for key state changes**:

| State Change | Announcement Text (keys, no literales normativos) | Announcement Timing |
|--------------|-----------------------------------------------|---------------------|
| Screen opens | `MENU_DECISION_TITLE` + ledger actual + "dos opciones, sin selección" | On focus settle (post-splash de entrada) |
| Focus llega a TOMAR | label+desc+ledger TOMAR | On focus arrival |
| Focus llega a DEJAR IR | label+desc+ledger DEJAR IR | On focus arrival |
| Commit TOMAR/DEJAR confirmado | Confirmación + triple nuevo + destino Hub | After commit confirmado (no antes del commit atómico) |
| Quit-line presente | `MENU_DECISION_QUIT_LINE` anunciada al abrir (una vez) | On open (el jugador debe saber el coste antes de cerrar) |

**Cognitive load assessment**: 4 streams concurrentes (1 título ceremonial, 2 futuros comparables en igualdad, 3 línea ledger actual, 4 líneas S irreversibilidad/quit). Dentro del límite 7±2, en rango bajo. Mitigación: sin timer, sin Postura/Vida, sin números exactos flotantes, sin Continuar/estado_red; el ledger auto-muestra deltas por botón para que el jugador nunca calcule.

Texto escalable: knob heredado `hud_scale` 0.9–1.15 respeta mínimo 18px aparente (`hud.md`); `fuente_min_px ≥18` base con escalado proporcional al alto (Menú Formulas); `hud_opacity` 0.6–1.0 sin bajar luminancia bajo 4.5:1. Sin flashing sin aviso; subtítulos N/A (sin diálogo Lucifer aquí; cutscene/diálogo es HUD-oculto-total por corte).

---

## 13. Localization Considerations

- Todo texto por claves `MENU_DECISION_*` (Menú posee claves, `/localize` literales, writer redacta). Cero hardcodeado. Vetos Menú: `corrupción/corrupto` reservado a ficción (aquí SÍ es ficción — ledger — permitido; jamás para fallos técnicos) · ningún motivo usa "duelo" (homónimo intraducible) · cero tecnicismos en superficie · placeholders con nombre · ningún diálogo >120 chars tras interpolación.
- Reglas: +40% expansión mínima desde inglés; RTL espeja díada (documentar qué espeja: orden TOMAR/DEJAR + mapeo left/right; no espeja medidor NW); CJK verifica sin huecos rotos; sin texto en imágenes.

| Text Element | English Baseline Length | Max Characters | Expansion Budget | RTL Behavior | Overflow Behavior | Risk |
|--------------|------------------------|----------------|-----------------|--------------|-------------------|------|
| `MENU_DECISION_TITLE` ("El coro espera tu mano") | ~24 (es-MX provisional) | 120 post-interp. (normativo Gracia) | +40% min | Centrado — aceptable sin espejo | Trunca con ellipsis solo si >120 (no debe pasar; fija `/localize`) | Low |
| `..._TOMAR_LABEL` / `..._DEJAR_LABEL` | Cortos (1–2 palabras) | 120 c/u post-interp. | +40% | Espeja orden + mapeo left/right | Shrink a 90% min, luego trunca; jamás rompe igualdad visual | Medium (alemán alarga) |
| `..._TOMAR_DESC` / `..._DEJAR_DESC` (`{poder} {vida} {poso} {purga}`) | ~60–90 | 120 post-interp. | +40% | Right-align, wrap normal | Scroll NO permitido en díada: reescribir, no scrollear (la díada no es scrollable) | High — reescribir hasta caber |
| `MENU_DECISION_LEDGER` | ~30 + números | 120 | +40% | Right-align | Trunca solo extremos no-críticos; números crudos jamás truncados | Medium |
| `MENU_DECISION_IRREVERSIBLE` / `..._QUIT_LINE` | ~30–50 | 120 c/u | +40% | Right-align, wrap | No trunca: dos líneas S reservadas a 18px | Low |

---

## 14. Acceptance Criteria

Performance / Layout / Input / Events / Accessibility / Localization — verificables por QA sin leer el GDD. `[A]` automatizable (gdUnit4 + gamepad virtual + reloj fake + espía FS), `[M]` manual (Deck real, kill, hardware). Cobertura: ≥1 por G4/G5/G6/G7/G10 + fórmulas + cross-system. Seams: fachada Guardado mockeada + ledger #5 mockeado + espía FS (cero IO #5; Menú jamás lee disco — MENU-08).

**Layout & estados**
- [ ] **DEC-01 [A]** — GIVEN post-reliquia, WHEN abre Decisión, THEN HUD oculto salvo Gracia NW alta luminancia; centro con ángel en brasas sin timer; díada en igualdad visual (misma métrica, sin dimming del no-enfocado); S con irreversibilidad + quit; cero de {Vida, Postura, timer, peek numérico, estado_red, Continuar, flash #C75C4A, hold prompt, lista R4} en árbol (screenshot 1280×800 + dump de árbol).
- [ ] **DEC-02 [A]** — GIVEN apertura, THEN foco neutro (ninguno); WHEN primer `ui_left/right` discreto, THEN agarra (left→TOMAR, right→DEJAR IR o espejo RTL documentado); trampa en díada; motion/held/gyro/conexión ignorados.
- [ ] **DEC-03 [A]** — GIVEN foco en botón, WHEN `ui_accept` flanco fresco, THEN ambos botones deshabilitados el mismo frame + swallow 200 ms + commit memoria síncrona pre-animación + 1 write `post_decision` + 0 `pre_eleccion` (espía FS + espía señales); 2º input mismo tick tumbado (guardia estado + dedupe tick).
- [ ] **DEC-04 [A]** — GIVEN Decisión abierta, WHEN `ui_cancel`, THEN no-op + `ui_error_bloqueado` sordo, sin atrás/sin omitir/sin commit/sin escritura; WHEN `ui_accept` en neutro, THEN no-op sin commit.
- [ ] **DEC-05 [A]** — GIVEN (G10,C20,P12,n1), WHEN TOMAR, THEN (n2, P24, vida_max+18, poder on, G igual, C=max(20,24)) en un commit; GIVEN Latente (0,0,0) WHEN TOMAR THEN (P12, n1, C12); sin lump de gracia (espejo Gracia GR-12/GR-13/GF-P1).
- [ ] **DEC-06 [A]** — GIVEN (C50,P24), WHEN DEJAR IR, THEN C44 resto igual; GIVEN (C26,P24) THEN C24; explícito sin Vida/poso/poder (espejo GR-14).
- [ ] **DEC-07 [A]** — GIVEN Decisión abierta, WHEN intento de gasto (binding G7), THEN RECHAZO sin buffer, sin consumir cap/cooldown, sin eventos (salvo blip denegación si aplica); binding gasto ≠ botón parry.
- [ ] **DEC-08 [A]** — GIVEN Saturada entrante (C100), WHEN TOMAR THEN n+1/poso `min(+12,techo)`/C100/saturado sigue; WHEN DEJAR IR THEN aritmética aplica pero handoff NO se retracta (espejo GR-26). GASTO off.

**Feedback (juicio/confirmación)**
- [ ] **DEC-09 [A+M]** — GIVEN commit, THEN juicio: disable mismo frame + sting `ui_cometer_irrevocable` sobrio (TOMAR) / variante resolución sobria (DEJAR IR, nunca error); confirmación: succión+rosetón / ascenso-sin-rosetón como sustain skippable por flanco discreto → Hub por corte. [M] Deck 7": checklist legibilidad + captura en `production/qa/evidence/`.
- [ ] **DEC-10 [A]** — GIVEN reduced-motion ON, WHEN cualquier transición/confirmación, THEN corte 1 frame, brasas estáticas, 0 flashes, viñeta estática, sonidos por bus (0 players directos) — espejo MENU-17.

**Datos (fachada + ledger)**
- [ ] **DEC-11 [A]** — GIVEN ledgers mockeados, WHEN abre, THEN niveles = ledgers ±1e-9; setter desde UI falla; ledgers intactos tras tick (espejo GR-31); `-0.0`→`0.0`, `100±1e-6` satura, `99.9` no (espejo GR-32/GF-T1).
- [ ] **DEC-12 [A]** — GIVEN variantes (poso<memoria, NaN, ausente, decision_absorber≠n, n>3 v1.0), WHEN validar entrada, THEN sin commit + escala a descarte sin defaults (espejo GX-04/GX-05/GR-29).
- [ ] **DEC-13 [A]** — GIVEN quit/kill con Decisión abierta (harness SIGKILL post-entrada, sin SUS nueva), WHEN relanzar, THEN estado = última SUS `post_decision` (deltas perdidos, anti-scum); Abandonar = wipe run-scoped (espejo GX-12 + Guardado AC-R9-01c).
- [ ] **DEC-14 [A]** — GIVEN espía FS que falla ante cualquier `FileAccess/DirAccess/ConfigFile` fuera de `persistencia/` (oracle AC-R1-02/MENU-08), WHEN recorrido completo (ambos commits + cancelar), THEN 0 lecturas/escrituras directas desde assembly de pantalla; Reset/Migrar N/A aquí (sin superficie).

**Accesibilidad / localización / input**
- [ ] **DEC-15 [A]** — GIVEN solo gamepad virtual, WHEN recorrer [neutro→TOMAR→DEJAR IR→commit→Hub] y [neutro→cancel], THEN todo alcanzable en orden §7; foco = borde 2px + cuneta, 0 glow; díada atrapa y no escapa (espejo MENU-06).
- [ ] **DEC-16 [A-proxy+M]** — [A-proxy] 0 labels <18px base, 0 nodos fuera de safe-zone 5% (espejo MENU-13); [M] Deck 7" 30–40 cm: cadenas funcionales legibles + captura en evidence. Contraste ≥4.5:1 en los 5 elementos §12 (medido, no TBD).
- [ ] **DEC-17 [A]** — GIVEN medidor NW, THEN respaldo de forma presente (densidad grieta/esquirlas + posición + movimiento), color redundante jamás único; TOMAR/DEJAR jamás diferenciados por croma (screenshot + inspección árbol).
- [ ] **DEC-18 [A]** — GIVEN claves `MENU_DECISION_*`, THEN todo texto por `tr()` (grep cero literales), placeholders con nombre, ≤120 chars post-interpolación en los 7 textos (prueba con alemán +40% y CJK); RTL espeja díada + mapeo (si es lengua target).

---

## 15. Open Questions

| Question | Owner | Deadline | Resolución |
|----------|-------|----------|------------|
| Back-link en #15: tabla + inventario `MENU_DECISION_*` + foco neutro (Gracia Dependencies lo exige) | #15 Menú + systems-designer | Al revisar Menú Rev 3 | Pendiente — `/consistency-check` lo verificará |
| Fila AC en Guardado: rechazo por `poso` decreciente + rango 0–9 (Gracia #5→#12) | Guardado #12 | Al enmendar Guardado | Pendiente (Gracia lo declara como back-link a anotar) |
| ¿Qué hace #6 con 94-tras-100 (DEJAR IR en Saturada)? | Clímax #6 | Al autorar #6 | Pendiente (Gracia Edge B3) |
| Ventana commit-animación→Hub-flush perdida si kill intermedio | #5 + Guardado | Playtest | Honesto hoy; sin SUS `post_decision` sin aprobación conjunta (Gracia Open Questions) |
| Contenido `poder` por coro (identidades, 3 v1.0) + magnitudes idénticas | #5 + narrative | Antes de Vertical Slice | G5c: ficción por identidad, magnitudes idénticas (independencia de orden, AC E9) |
| Timbres `ui_cometer_irrevocable` vs variante resolución + cama/ducking | Audio #16 | Al autorar #16 | Catálogo cerrado Menú Interactions; este spec solo exige familia sobria no-error |
| Verificación Deck real: foco por mando, 18px a 30–40 cm, p95 transiciones, A-spam (splash-pattern) en díada neutra, sleep/kill en Decisión | qa-lead + ux-designer | Pre-producción / Vertical Slice | Patrón Menú Open Questions + Gracia GX-16 (screenshots 1280×800 + contraste + reduced-motion + sign-off) |
| Calibración techo/poso/purga (protocolos Gracia GX-13/GX-14) — ¿cambian los literales `{vida} {poso} {purga}`? | systems-designer + playtest | Prototipo / Vertical Slice | Spec interpola, jamás recalcula; si se retunean, `/propagate-design-change` + revalidar DEC-05/DEC-06/DEC-18 |

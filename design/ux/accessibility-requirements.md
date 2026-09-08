# Accessibility Requirements: NOVENA

> **Status**: Draft
> **Author**: usuario + ux-designer
> **Last Updated**: 2026-09-06
> **Accessibility Tier Target**: Comprehensive
> **Platform(s)**: PC (Steam) + Steam Deck (Linux/Proton)
> **External Standards Targeted**:
> - WCAG 2.1 Level AA (baseline, propuesto en `design/ux/hud.md` Rev-2 y `decision-gracia.md` §12 — este doc lo ratifica pendiente `/gate-check`)
> - AbleGamers CVAA Guidelines (parcial — sin chat/voz multi, N/A para comunicación)
> - Xbox Accessibility Guidelines (XAG) [No — sin target Xbox en v1.0]
> - PlayStation Accessibility [No — sin target PS en v1.0]
> - Apple / Google Accessibility Guidelines [N/A — sin móvil]
> **Accessibility Consultant**: None engaged
> **Linked Documents**: `design/gdd/systems-index.md` (#1 Combate, #13 HUD, #21 Accesibilidad), `design/ux/interaction-patterns.md` (P1/P2/P3), `design/ux/hud.md`, `design/ux/decision-gracia.md`

> **Why this document exists**: Las anotaciones por pantalla viven en sus UX specs (`hud.md` §12, `decision-gracia.md` §12). Este documento captura los compromisos proyecto-wide, la matriz por sistema, el plan de test y el historial de auditorías. Si un feature conflicta con un compromiso aquí, gana este documento — se cambia el feature, no el compromiso, salvo revisión formal aprobada por producer.
>
> **When to update**: Tras cada `/gate-check`, tras cada auditoría, y cuando se añada un sistema a `systems-index.md`.

---

## Accessibility Tier Definition

### Tier Definitions

| Tier | Core Commitment | Typical Effort |
|------|----------------|----------------|
| **Basic** | Texto crítico legible a resolución estándar. Ningún feature exige solo discriminar color. Volúmenes música/SFX/voz independientes. Completable sin riesgo fotosensible. | Low |
| **Standard** | Todo Basic + remap completo, subtítulos con speaker, tamaño texto ajustable, ≥1 modo daltónico, sin input con timer que no se pueda extender/togglear. | Medium |
| **Comprehensive** | Todo Standard + lector pantalla en menús, audio mono, modos assist dificultad, reposicionamiento HUD, reduced-motion, indicadores visuales para todo audio gameplay-crítico. | High |
| **Exemplary** | Todo Comprehensive + subtítulos full-custom, alto contraste total, assists cognitivos, háptico alternativo a todo cue audio-only, auditoría externa. | Very High |

### This Project's Commitment

**Target Tier**: Comprehensive

**Rationale**: NOVENA es un boss-rush 2D de parry de ventana estrecha (juicio ≤2 ticks, confirmación ≤10 ticks) — la barrera motora más severa del catálogo (timing + single-press + flanco fresco, parry DIGITAL C24). La barrera visual es la segunda: silueta-antes-que-detalle a 7" Deck 30–40 cm, periferia que no lee croma (solo luminancia), y vitral como única luz permitida (art-bible §§1–2). El público 20–40 hardcore de Sekiro/Hades incluye ~8% CVD + prevalencia RSI/temblor relevante para inputs de precisión. Standard no cubre reduced-motion (vignette pulsante + shake son gameplay-adjacentes), ni mono-audio, ni lector en menús — los tres bloquean a Deck + `/gate-check`. Exemplary es inalcanzable en solo-dev v1.0 (screen-reader en mundo + full-custom subs + auditoría externa). Bajar a Standard excluiría a jugadores que necesitan timing extendido y motion-off, justo el segmento Narradores/Exploradores que la accesibilidad debe conservar (game-concept §Bartle).

**Features explicitly in scope (beyond tier baseline)**:
- Timing-window multiplier 0.5x–3.0x para QTEs/ventanas parry práctica (no cambia daño — Pilar 2: la maestría sigue en manos; el assist es legibilidad, no stats).
- `disable_damage_flash` → sustituto por icono con forma (ya en P2) + flash-reduction 80% global.
- Texto funcional ≥18px aparente Deck + `hud_scale` 0.9–1.15 + `hud_opacity` 0.6–1.0 sin bajar de 4.5:1.

**Features explicitly out of scope**:
- Screen reader en mundo 3D/2D diegético (solo menús vía AccessKit Godot 4.7) — ver Known Intentional Limitations.
- Full-custom subs (font/color/fondo) — dos presets (default + high-readability) como mitigación v1.0.
- Háptico DualSense completo — solo Xbox/Steam rumble en scope; resto post-launch.

---

## Visual Accessibility

> Deck 7" a 30–40 cm es el constraint. Tinta/vitral: periferia lee luminancia/movimiento, jamás croma solo. Solo lo divino emite luz.

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Minimum text size — menu UI | Standard | Todos los menús (#15) | Not Started | 24px mínimo @1080p, escala proporcional @4K/800p Deck. WCAG 1.4.4: 200% sin pérdida. |
| Minimum text size — subtitles | Standard | Fragmentos Memoria (#17), Lucifer voz (#11 futuro) | Not Started | 32px mínimo @1080p. TV/Deck 3m es constraint si dock. |
| Minimum text size — HUD | Standard | HUD combate (#13) | Not Started | 20px crítico (Vida/Postura/Gracia/objetivo), 18px piso absoluto funcional Deck (`hud.md` + P1). |
| Text contrast — UI text | Standard | Toda UI | Not Started | 4.5:1 body, 3:1 large (18px+ o 14px bold). Paleta `#2A2E36/#8C94A0/#C7CDD6` (`#E8ECF1` solo `timer_high_contrast` Deck). Checker automatizado. |
| Text contrast — subtitles | Standard | Subs | Not Started | 7:1 (AAA) + drop-shadow o caja opaca por defecto. |
| Colorblind — Protanopia/Deuteranopia | Standard | Todo color-coded | Not Started | Shift rojo→naranja/amarillo, verde→teal. Verificar Coblis. Gracia vitral redundante con forma (grieta/esquirlas ◆◆◇◇). |
| Colorblind — Tritanopia | Standard | Todo color-coded | Not Started | Azul→púrpura, amarillo→naranja. |
| Color-as-only-indicator audit | Basic | UI + gameplay | Not Started | Ver tabla abajo. Cada entrada necesita backup no-color antes de ship. |
| UI scaling | Standard | Toda UI | Not Started | 75%–150% (default 100%). `hud_scale` 0.9–1.15 independiente menú/HUD. Test min+max todas las pantallas. |
| High contrast mode | Comprehensive | Menús mínimo; HUD preferido | Not Started | Fondos semi→opacos, UI mid-tone→B/N, todo interactivo outlined. |
| Brightness/gamma | Basic | Global | Not Started | −50%..+50%, imagen calibración incluida. |
| Screen flash / strobe warning | Basic | Cutscenes, VFX, flash `#C75C4A` | Not Started | (1) Warning pre-launch. (2) Harding FPA ≤3 flashes/s. (3) Flash-reduction 80% + `disable_damage_flash` por icono. PROHIBIDO flash en Decisión. |
| Motion reduction mode | Standard | Transiciones, shake, VFX | Not Started | Corte 1 frame, sin shake/bob/blur/parallax/loop. Hitstop se mantiene (es gameplay, P1/P2). Toggle en settings. |
| Subtitles — on/off + speaker | Basic/Standard | Todo voiced | Not Started | Default OFF, ofrecido en primer arranque. Speaker siempre con nombre. |
| Subtitles — style/custom + SFX captions | Comprehensive | Subs + SFX críticos | Not Started | v1.0: 2 presets. Captions `[DESCRIPCIÓN]` para SFX §Auditory. |

### Color-as-Only-Indicator Audit

| Location | Color Signal | What It Communicates | Non-Color Backup | Status |
|----------|-------------|---------------------|-----------------|--------|
| HUD Vida NW (P1) | Gris frío luminancia | Vida jugador | Posición NW + longitud barra + número ledger bajo demanda + vignette tinta | Not Started |
| HUD Postura 4 bloques (P3) | Gris frío | Postura / castigo | Forma segmentada (4 bloques) + caída como ausencia | Not Started |
| Gracia esquirlas ◆◆◇◇ (P3) | Vitral violeta | Gracia / VE firma | Forma rombo + densidad grieta + movimiento (pre-light→mover→repliegue) + posición NW | Not Started |
| Flash fallo `#C75C4A` (P2) | Rojo fallo | Fallo parry (ev.5) | Único flash 1–2 ticks + supresión VE 200ms + `disable_damage_flash`→icono forma | Not Started |
| Timer castigo S (P1) | Gris alta-lum | Aturdido 120 ticks | Posición S + lineal izq→der + aparece/desaparece sin ease | Not Started |
| TOMAR vs DEJAR IR | — | PROHIBIDO diferenciar por color | Igualdad visual estricta + labels + ledger textual + foco forma (borde+cuneta+peso) | Committed |
| Rareza reliquias (#9 futuro) | Borde color (gris/azul/púrpura/oro) | Tier item | Nombre rareza en foco + star-count icono | Not Started |

---

## Motor Accessibility

> Parry es DIGITAL (C24): ningún eje analógico mapeable a acción binaria. Todo input binario = flanco `pressed` discreto; held/motion/gyro jamás disparan (Menú R6-INPUT).

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Full input remapping | Standard | Todos los inputs, todas las plataformas | Not Started | Todo bound default rebindable (KB/mouse/mando independiente). Conflicto avisa y bloquea. Persiste en perfil. Steam Input como capa sistema + remap in-game para KB/mouse. |
| Input method switching | Standard | PC/Deck | Not Started | Switch KB/mouse↔mando en caliente sin restart. Prompts dinámicos (iconos por método activo). |
| One-hand mode | Standard | Acciones multi-input | Not Started | Auditar todo hold+press simultáneo. Alternativa toggle o secuencia. |
| Hold-to-press alternatives | Standard | Todos los holds | Not Started | Todo "hold X" → toggle (1ª press on, 2ª off). Lista de holds del juego aquí (Decisión: SIN hold por diseño — single-press + flanco fresco; hold reservado a destrucción run/SUS #15). |
| Rapid input alternatives | Standard | Mash >3 presses/s | Not Started | Alternativa single-press toggle (ej. dash repetido por hold). A-spam en díada neutra debe ser no-op (DEC-02/04). |
| Input timing adjustments | Standard | Ventanas parry/QTE/ritmo | Not Started | Multiplicador 0.5x–3.0x (default 1.0x). 500ms@3.0x=1500ms. Aplica a práctica/tutorial y ventanas accesibles; rankeds/leaderboards documentan valor usado. Test todos los valores. |
| Aim assist | Standard | N/A v1.0 | N/A | Sin ranged/targeting en MVP (boss-rush melee). Si #19 añade estados a distancia, reabrir. |
| Auto-sprint / movement assists | Standard | Movimiento | Not Started | Toggle sprint + auto-run (mantiene dirección sin hold). Listar holds continuos de movimiento. |
| Traversal assists | Standard | N/A | N/A | Sin plataformas (hub mínimo, sin mundo abierto). |
| HUD repositioning | Comprehensive | Todo HUD | Not Started | Mover Vida/Postura/Gracia/minimapa/quest. Importante para head-tracking/eye-gaze. |

---

## Cognitive Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Difficulty options | Standard | Parámetros dificultad | Not Started | Sliders granulares (daño dado/recibido, agresión, velocidad) NO single Easy/Hard. Anti-pilar: stats no resuelven dificultad por diseño — los assists son accesibilidad explícita y documentan qué fijan. Fijos requieren justificación. |
| Pause anywhere | Basic | Todos los estados | Not Started | Pausa en duelo, cinemática, diálogo, tutorial, Decisión (modal preserva foco, jamás auto-commit). Timer 120 ticks pausado en Pausa (P1). Documentar excepciones con justificación (riesgo). |
| Tutorial persistence | Standard | Tutoriales/ayuda | Not Started | Todo prompt recuperable en Help. Primeros 10 min: un enemigo menor solo vencible por parry — el tutorial no debe ser one-shot. |
| Quest / objective clarity | Standard | Objetivos/corros | Not Started | Objetivo activo a ≤2 pulsaciones. Texto completo bajo demanda, no solo marcador. Sin inferencia ("investiga el norte" — dónde exacto). |
| Visual indicators for audio-only | Standard | Todo SFX gameplay-crítico | Not Started | Ver §Auditory. Off-screen→indicador borde. Transición fase jefe→cue visual. |
| Reading time | Standard | Diálogos auto-dismiss | Not Started | Nada accionable auto-dismiss <5s. Preferido: requiere confirmación. Listar cada elemento y duración. Diálogo ≤120 chars post-interp. |
| Cognitive load doc | Comprehensive | Por sistema | Not Started | Max streams simultáneos por sistema; flag si >4. Decisión: 4 streams (título + 2 futuros + ledger + S) — OK bajo 7±2. HUD duelo: Vida+Postura+Gracia+timer+telegrafiado — en límite, compensar con claridad. |
| Navigation assists | Standard | Navegación | Not Started | Fast-travel a visitados, waypoint objetivo, indicador opcional siempre visible. Hub mínimo: aplica waypoint + retorno <10s tras fallo. |

---

## Auditory Accessibility

> Principio: todo sonido que cambia lo que el jugador debe HACER tiene equivalente visual.

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Subtitles all dialogue | Basic | 100% voiced (narración, in-engine, radio/ambiental) | Not Started | Cero excepciones. Sync contra VO. |
| Closed captions SFX críticos | Comprehensive | Lista auditada abajo | Not Started | Solo los que comunican estado no-inferible visualmente. |
| Mono audio | Comprehensive | Global | Not Started | Fold stereo→mono preservando balance. Esencial sordera unilateral. |
| Independent volumes | Basic | Música/SFX/Voz/UI | Not Started | 4 sliders 0–100% default 80%. En settings + pausa. Persisten. |
| Visual directional audio | Comprehensive | Off-screen threats | Not Started | Indicador borde hacia fuente, opacidad ∝ volumen. Threat (rojo) vs info (neutro). TLOU2 como ref. |
| Hearing aid compatibility | Standard | Cues >4kHz | Not Started | Todo cue crítico solo-agudo necesita equivalente grave o visual. |

### Gameplay-Critical SFX Audit

| Sound Effect | What It Communicates | Visual Backup | Caption Required | Status |
|-------------|---------------------|--------------|-----------------|--------|
| Windup ataque (telegrafiado) | Daño entrante — parar/esquivar | Animación telegraph legible todo ángulo (silueta-antes-detalle) | No — visual suficiente | Not Started |
| Parry perfecto (ev.15 firma) | Absorción gracia OK | Gracia se mueve + repliegue luz + juicio ≤2 ticks | No | Not Started |
| Fallo parry (ev.5) | Castigo entrante | Flash `#C75C4A` 1–2 ticks + supresión VE 200ms | Sí — `[FALLO]` + borde si off-screen | Not Started |
| Rotura postura → Aturdido 120 ticks | Ventana castigo | Timer S + Postura caída | Sí — `[ATURDIDO]` | Not Started |
| Transición fase jefe (#20) | Cambio gramática | Cambio staging + vignette | Sí — `[FASE]` direccional | Not Started |
| Low-health heartbeat | Vida crítica | Barra NW + vignette tinta progresiva + latido solo-alfa | No | Not Started |
| Quest/run completado | Objetivo done | Tracker + Hub update | No | Not Started |
| Commit Decisión (sting sobrio) | Irrevocable registrado | Succión+rosetón / ascenso + corte a Hub | Sí — `[DECISIÓN REGISTRADA]` (lector) | Not Started |

---

## Platform Accessibility API Integration

| Platform | API / Standard | Features Planned | Status | Notes |
|----------|---------------|-----------------|--------|-------|
| Steam (PC/Deck) | Steam Input + SDL | Remap sistema + prompts dinámicos + Deck verificación hardware real | Not Started | Remap in-game sigue requerido para KB/mouse. Timing parry verificar en Deck, no solo PC escritorio. |
| PC (Screen Reader) | NVDA / Narrator via Godot 4.7 AccessKit | Anuncios menús (nombre+rol+orden lógico), foco neutro Decisión anunciado | Not Started | Verificar `docs/engine-reference/godot/` — AccessKit cubre menús; mundo diegético fuera de scope v1.0. |
| Deck OS | Steam Deck display/motion settings | Respeta texto grande, alto contraste, reduced-motion OS como default si ON | Not Started | Si OS reduced-motion ON → juego arranca con reduced-motion ON. |
| Xbox / PS / iOS / Android | — | Fuera de scope v1.0 | N/A | Reabrir si se portean; XAG sería floor. |

---

## Per-Feature Accessibility Matrix

| System | Visual | Motor | Cognitive | Auditory | Addressed | Notes |
|--------|--------|-------|-----------|----------|-----------|-------|
| #1 Combate Parry-Absorción | Telegrafiados + juicio ≤2 ticks | Ventana estrecha + digital C24 + flanco fresco | Patrones+cooldowns+recursos simultáneos | Cues off-screen | Partial | Timing multiplier + hold-toggles + forma-no-color aplicados; ventana base pendiente playtest |
| #2 Máquina Estados Jefe | 9 estados legibles por silueta | Enfriamiento+Telegrafiado ≥12+margen (justicia) | Carga patrones | Fase-audio→visual | Partial | Regla 9 es piso a11y motor/cognitivo |
| #4 Feedback Impacto | Flash/freeze 0% + shake | Shake→off en reduced-motion; hitstop se mantiene | Juicio vs confirmación separados | Triggers por bus | Partial | R1/R2: juicio transient vs sustain |
| #5 Gracia Tres Capas | Corrupción sin HUD (cuerpo) + vitral | Gasto discreto G7 ≠ parry | 3 capas superpuestas = mayor deuda legibilidad | Stings sobrios | Partial | Decisión single-press sin hold; ledger auto-deltas |
| #13 HUD Combate | 18px Deck + 4.5:1 + luminancia | Reposicionable + escala | ≤5 streams | Borde-indicadores | Partial | `hud.md` APPROVED 0 blocking/5 advisory |
| #15 Menú/Flujo | Foco borde+cuneta 0 glow, safe 5% | Trampa foco + flanco fresco + re-grab Deck | Pause anywhere + Help persistente | Timbres por bus #16 | Partial | Rev2 approved; splash-pattern A-spam pendiente Deck |
| #16 Sonoro Parry | Co-emite alerta 5/13 | N/A | Capa sin cuerpo distinguible ojos-cerrados | Mono + captions + visuales | Partial | Timbres propiedad #16; presupuestos interinos |
| #20 IA Jefes | Duraciones que HUD no tapa | 3≤N≤5, varianza intra-combo | Gramática por coro, no números | Precedencia armónica | Partial | H curación acotada `H≤dano_castigo` |
| #12 Guardado | Quit-line honesta siempre visible | Quit/kill fail-closed (sin commit) | Sin tecnicismos superficie | N/A | Partial | Solo `post_decision`, jamás `pre_eleccion` |
| Decisión Gracia (UX) | Centro ocupado permitido + igualdad visual | Neutro→discreto agarra, trampa díada | 4 streams, sin timer | Commit anunciado post-átomo | Partial | `decision-gracia.md` Draft; DEC-01..18 |

---

## Accessibility Test Plan

| Feature | Test Method | Test Cases | Pass Criteria | Responsible | Status |
|---------|------------|------------|--------------|-------------|--------|
| Contraste | Automatizado — analyzer sobre screenshots 1280×800 + Deck | Todas las combinaciones texto/fondo | Body ≥4.5:1, large ≥3:1, subs ≥7:1 | ux-designer | Not Started |
| Daltónicos | Manual — Coblis en cada modo | Exploración/combate/inventario por modo | Cero info perdida; completable sin discriminar color | ux-designer | Not Started |
| Remap | Manual — rebind todo, tutorial + nivel 1 | Todo default rebindeado, restart persiste | Todo alcanzable; anti-conflicto OK | qa-tester | Not Started |
| Subs | Manual — contra script VO | 100% voiced + timing + speaker | 100% + speaker multi-char; no sub >3s post-línea | qa-tester | Not Started |
| Holds→toggle | Manual — toggles ON, secuencias combate/travesía | Todos los holds | Completable sin hold sostenido | qa-tester | Not Started |
| Reduced-motion | Manual — ON, menús + 1h juego | Transiciones/HUD/shake | 0 loops en menú, 0 shake sobre umbral, cortes/fades | ux-designer | Not Started |
| Lector (menús) | Manual — NVDA/Narrator + Deck | Principal/settings/pausa/inventario/mapa/Decisión | Todo anunciable, orden lógico, nada solo-hover, foco neutro anunciado | ux-designer | Not Started |
| Timing 0.5x–3.0x | Automatizado gdUnit4 + manual Deck | Ventanas parry/QTE en cada multiplier | Ventana escala lineal; a 3.0x completable sin mash | qa-tester | Not Started |
| User testing daltónicos | Usuarios daltónicos | Sesión completa por modo | Sin pedir aclaración color; sin bloqueo | producer | Not Started |
| User testing motor | Una mano / adaptativos + toggles + timing ext | MVP completo | Dentro de tolerancia vs able-bodied | producer | Not Started |

---

## Known Intentional Limitations

| Feature | Tier Required | Why Not Included | Risk / Impact | Mitigation |
|---------|--------------|-----------------|--------------|------------|
| Lector en mundo (NPCs/objetos/texto ambiental) | Exemplary | AccessKit Godot 4.7 cubre menús; espacial-audio-desc requeriría sistema custom fuera de solo-dev v1.0 | Ciegos/baja-visión navegan menús pero no exploran mundo solo | Duplicar info crítica en sistemas accesibles (quest log, mapa, ledger); evaluar DLC |
| Subs full-custom (font/color/fondo/posición) | Comprehensive | Pipeline fonts custom Godot + alcance Alpha | Dislexia/necesidades legibilidad específica | 2 presets (default + high-readability); log post-launch |
| Háptico alternativo total (DualSense/3rd-party) | Exemplary | Rumble no-Xbox fuera de v1.0 | Sordos sin háptico en PC no-Xbox | Háptico Xbox/Steam en scope; DualSense en patch |
| Dificultad auto-adaptativa | Exemplary | Viola Pilar 2 si ajusta stats silencioso | N/A — exclusión deliberada | Assists explícitos opt-in en vez de auto-ajuste |

---

## Audit History

| Date | Auditor | Type | Scope | Findings Summary | Status |
|------|---------|------|-------|-----------------|--------|
| 2026-09-05 | `/ux-review hud` | Internal review | `hud.md` vs tier propuesto | APPROVED 0 blocking / 5 advisory (ver header `hud.md`) | Findings addressed (parcial — 5 advisory abiertas) |
| 2026-09-05 | `/gate-check pre-production` | Gate | Pre-Production | FAIL — `accessibility-requirements.md` MISSING, tier solo propuesto | Este doc lo cierra (pendiente re-gate) |
| [Add row per audit] | | | | | |

---

## External Resources

| Resource | URL | Relevance |
|----------|-----|-----------|
| WCAG 2.1 | https://www.w3.org/TR/WCAG21/ | Contraste, tamaño, inputs |
| Game Accessibility Guidelines | https://gameaccessibilityguidelines.com | Checklist por coste |
| AbleGamers Player Panel | https://ablegamers.org/player-panel/ | User testing |
| Coblis Simulator | https://www.color-blindness.com/coblis-color-blindness-simulator/ | Simular modos en screenshots |
| Accessible Games DB | https://accessible.games | Ejemplos decisiones |
| Godot AccessKit (ver engine-ref) | `docs/engine-reference/godot/` | Qué cubre 4.7 en menús vs HUD dinámico |

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| ¿AccessKit Godot 4.7 soporta nodos dinámicos HUD (Vida/Postura/Gracia) o solo menús estáticos? | ux-designer | Pre-gate re-run | Unresolved — verificar engine-ref + test Deck |
| Timing multiplier ¿afecta ventana parry en runs rankeadas o solo práctica/accesible? (Pilar 2) | systems-designer | Vertical Slice | Unresolved — propuesta: documenta valor, no banea |
| `hud_scale` 0.9–1.15 + alemán +40% ¿cabe sin romper igualdad TOMAR/DEJAR IR? | ui-programmer | Pre-producción | Unresolved — DEC-18 lo testea |
| Desconexión mando en Decisión neutra: ¿re-grab a neutro o a último foco? Verificar Deck real | qa-lead | Vertical Slice | Unresolved |
| ¿Mono-audio fold preserva ducking/crossfade #16? | audio-director | Al autorar #16 final | Unresolved |

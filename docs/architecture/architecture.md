# NOVENA — Master Architecture

## Document Status
- Version: 1.0 (all sections approved 2026-09-08; sign-off Phase 7b pending)
- Last Updated: 2026-09-08
- Engine: Godot 4.7.2-stable (pin línea 4.7)
- Review Mode: full
- GDDs Covered: combate-parry-absorcion (#1) · maquina-estados-jefe (#2) · feedback-impacto (#4) · gracia-tres-capas (#5) · guardado-de-progreso (#12) · menu-principal-y-flujo-de-pantallas (#15) · feedback-sonoro-parry (#16) · ia-combate-jefes (#20) + game-concept + systems-index
- ADRs Referenced: ADR-001 (tiempo, Accepted) · ADR-002 (eventos, Accepted) · ADR-003 (bus Hitstop, Accepted)
- Technical Director Sign-Off: pending (Phase 7b)
- Lead Programmer Feasibility: pending (Phase 7b, full mode)
- Last Updated: 2026-09-08
- Engine: Godot 4.7.2-stable (pin línea 4.7)
- Review Mode: full
- GDDs Covered: combate-parry-absorcion (#1) · maquina-estados-jefe (#2) · feedback-impacto (#4) · gracia-tres-capas (#5) · guardado-de-progreso (#12) · menu-principal-y-flujo-de-pantallas (#15) · feedback-sonoro-parry (#16) · ia-combate-jefes (#20) + game-concept + systems-index
- ADRs Referenced: ADR-001 (tiempo, Accepted) · ADR-002 (eventos, Accepted) · ADR-003 (bus Hitstop, Accepted)
- Technical Director Sign-Off: pending (Phase 7b)
- Lead Programmer Feasibility: pending (Phase 7b, full mode)

## Engine Knowledge Gap Summary
LLM covers ≈4.3; pin is 4.7.2. HIGH RISK: Core/SceneTree has no reference module (`SceneTree.paused`, `process_mode` exemption, `process_physics_priority` order, Tween/AnimationMixer process modes, shader `TIME` under pause, default signal dispatch synchronicity) — flagged ⚠️ wherever used; BLOCKING V1 scene tests in ADR-001/002 are the verification vehicle, not guesses. MEDIUM: Audio (module verified 4.6, unverified at pin), Rendering/particles (4.6), Animation process modes (core-adjacent). LOW: FileAccess `store_*→bool`, GDScript variadics/`@abstract`, SDL3 gamepad (API unchanged), dual-focus, 2D physics (Jolt is 3D-only). `modules/input.md` is verified 4.7 (device-ID rework covered).

## System Layer Map
Approved 2026-09-08. Ownership details in Module Ownership below (Phase 2, pending).

```
┌─────────────────────────────────────────────────┐
│ PRESENTATION  CombatHUD(13) · MenuShell(15)     │  UI/HUD/menus/VFX/audio
│               ImpactFeedback(4) · SonoroEngine   │
│               (16) · VfxPool / CameraRig        │
├─────────────────────────────────────────────────┤
│ FEATURE       GraceChoice(5D) · RelicCatalog(9) │  gameplay rules, AI data
│               RunDirector(3) · MetaProgression  │  consumers, quests/flows
│               (10/17/18) · SaturationClimax(6)  │
│               CorruptionState(7) · EncounterMods │
│               (8/11/19) · AssistDirector(21)    │
├─────────────────────────────────────────────────┤
│ CORE          CombatResolver(1) · BossFSM(2)     │  input, resolution, FSM,
│               PatternData(20) · GraceLedger(5)   │  hot-loop state
├─────────────────────────────────────────────────┤
│ FOUNDATION    TimeAuthority · EventBackbone      │  engine integration,
│               PersistenceService(12) ·           │  save/load, scenes,
│               ConfigService · SceneDirector ·    │  events, data, RNG, l10n
│               RngService · LocalizationService   │
├─────────────────────────────────────────────────┤
│ PLATFORM      Godot 4.7.2 · Steam Deck / PC     │  OS, hardware, engine API
└─────────────────────────────────────────────────┘
```

Module boundaries: each module owns its state exclusively (see Ownership); cross-module contact only via B-*/C-* signals (Core), facade reads (PersistenceService), or explicit interfaces (Phase 4). No module reaches into another's state. Hot-loop rule: GraceLedger sits in Core for earn atomicity but decides no presentation; ImpactFeedback/SonoroEngine present but never decide.

## Module Ownership
Approved 2026-09-08. Contact rule: no module touches another's state. Core talks via B-*/C-* signals (same-stack, ADR-001/002); Feature consumes Core synchronously but decides nothing in the hot loop; Presentation presents, never decides; Foundation serves all, depends on none (except engine).

### FOUNDATION

| Module | Owns | Exposes | Consumes | Engine APIs (4.7.2) |
|---|---|---|---|---|
| TimeAuthority | WallTick pared-clock + freeze counter; DiegeticTick (resolver-held); freeze_started/finalizado | `Hitstop.play(ticks)`, `freeze_started`, pared_tick, rampa/pool_log | Nothing (root) | `SceneTree.paused` ⚠️ HIGH · `PROCESS_MODE_ALWAYS/PAUSABLE` ⚠️ HIGH · `process_physics_priority` ⚠️ HIGH · `Engine.get_physics_frames()` LOW |
| EventBackbone | B-*/C-* naming, payload closure, order cierre→resultado→transición, reentrancy-guard pattern, `window_id` monotonicity | Signal declarations, EstadoJefe enum table, guard snippet | Tick stamps | `Object.connect` default-sync ⚠️ HIGH (V1 pending) · `StringName` LOW |
| PersistenceService (#12) | PER/SUS/SET bytes, SaveIo seam, staged journal, facade state, migrations | Codes enum, resumen_continuar, detalle_perdida, estado_red, CONSUMIENDO, punto_seguro | Opaque grace/run/relic/meta payloads + events | `FileAccess.store_*→bool` LOW · `DirAccess` LOW · `Time` LOW · JSON LOW |
| ConfigService | `assets/data/` tuning, schemas, FAIL_LOAD runner | Typed knob reads; validation errors (key + reason) | Nothing | JSON + `FileAccess` LOW |
| SceneDirector | Scene stack, router table, splash/boot, preload jobs, veil | Sole `change_scene`; transition requests; veil progress | MenuShell requests | `change_scene_to_file` LOW · `load_threaded_*` MEDIUM · Shader Baker MEDIUM · stretch defaults LOW |
| RngService | `semilla_run` + `posicion_rng` cursor | `extraer()`; verbatim snapshot/restore | Nothing | `RandomPCG` LOW — never negative weights (4.7.2 ban) |
| LocalizationService | MENU_* tables, veto/placeholder rules | `tr_key()` ≤120ch post-interpolation | Nothing | `TranslationServer`/CSV LOW · RichTextLabel ⚠️ MEDIUM (4.7 image units) |

### CORE

| Module | Owns | Exposes | Consumes | Engine APIs |
|---|---|---|---|---|
| CombatResolver (#1) | Input edges, player FSM, HP, F1–F8/R1–R10 evaluation, C-* emission | `parry_resuelto`, `castigo_iniciado`, `duelo_perdido`; postura_resultante | B-* windows; PatternData; `angeles_absorbidos` (F5); knobs | `is_action_just_pressed(&"")` in `_physics_process` LOW · `DEVICE_ID_*` ⚠️ HIGH (never `device==0`; C24) · sub-tick timestamp deliberately unused |
| BossFSM (#2) | 9 states + En Combo (i/N fields), boss HP countdown, B-* emission | B-* bundle; `duelo_ganado`; `castigo_conectado` | `parry_resuelto`, `castigo_iniciado`; PatternData config | `_physics_process` polling FORBIDDEN in resolution path · no `await/Tween/SceneTreeTimer/animation_finished`/queues ⚠️ HIGH |
| PatternData (#20) | Per-pattern rows + load gates (N, J, piso, R9a band+sum, H caps, tutorial floor) | Read-only queries; validation verdicts | ConfigService | None (pure data) — LOW |
| GraceLedger (#5) | Triple floats + earn/gasto/poso/saturación math, Σ-gate, Amparo scope + identity | Levels + 4 read-only events; `angeles_absorbidos`; spend verdicts | `parry_resuelto` sync same-stack; duel-state legality; costs/caps/cooldown | None — LOW |

### FEATURE (futures thin, except GraceChoice)

| Module | Owns | Exposes | Consumes |
|---|---|---|---|
| GraceChoice (5D) | Post-reliquia position, commit-once guard, Decisión focus state | Commit result; quit-line state | MenuShell routing; Ledger verdicts; post_decision write |
| RelicCatalog (9) | Loadout ids + R10 deltas; grace-faucet ban [3c] | Loadout + deltas (R10-validated at load) | RunDirector post-selección |
| RunDirector (3) | Coro index, representatives, seed/cursor, safe points, post-duel sequence | Run snapshot; `run_viva_visible` + timeout/reject | `duelo_ganado`/`duelo_perdido`; GraceChoice outcomes |
| MetaProgression (10/17/18) | Catalogs; append-only logs; Hub content contract | `llave_obtenida`/`fragmento_visto`; Hub state | PER writes |
| SaturationClimax (6) | Post-100 rules incl. 94-tras-100 (S5); desgarro | Continuation verdicts | `saturacion_alcanzada` |
| CorruptionState (7) | Permanent C/P map rules | Map to Overlay binding | Ledger levels |
| EncounterMods (8/11/19) | Arena mods; Lucifer nested sub-states; #19 own events + E5 rewrite | Mod declarations | BossFSM extension points |
| AssistDirector (21) | Assist presets (pair, R6 re-verify), grace_base ratio, SET fallbacks, reduced-motion | Effective overrides | Resolver/Ledger live knobs (read-only source) |

### PRESENTATION

| Module | Owns | Exposes | Consumes | Engine APIs |
|---|---|---|---|---|
| CombatHUD (13) | Widgets; Postura-fall binding; `set_pausa_visual` | Nothing gameplay-readable | Resolver HP/postura/vida; Ledger levels+events; Aturdido timer | `CanvasLayer`+ALWAYS ⚠️ MEDIUM · dual-focus visuals ⚠️ MEDIUM (2px `#C7CDD6`, never glow) |
| MenuShell (15) | Destinations; focus store/trap; firma hold; splash/transitions | Destination requests; intentions to Run/Audio | Facade ONLY (never disk); RunDirector confirmations | `Control.focus` ⚠️ MEDIUM · `set_input_as_handled`+inhibit+swallow LOW · no hover-dependent paths |
| ImpactFeedback (4) | Transient order; fusion `max()`; trauma/shake; pool assignment; latch; rampa | Cues to VfxPool/CameraRig; oracles to #16 | Resolver verdicts + B-*; WallTick clocks; trauma/pool knobs | `CPUParticles2D one_shot+finished` ⚠️ MEDIUM · foreign `Camera2D.offset` ⚠️ HIGH · NO `TIME` for synced VFX ⚠️ HIGH |
| SonoroEngine (16) | Buses (Absorber/Arrancar/Hitstop); duck/steal; stems; UI timbres + vela | Stems pre-master; duck state | #4 triggers/windows/ranges; verdicts; menu intentions | `AudioServer` bus ops ⚠️ MEDIUM · player pools LOW · BT excluded from timing |
| VfxPool / CameraRig | Reservation (inward/outward/shared); exhaustion accounting; offset application | `finished` availability; drop counters | ImpactFeedback orders | GPUParticles vs CPUParticles unification pending P0-DEF ⚠️ MEDIUM (decided here, once) |

## Data Flow
Approved 2026-09-08. Threading: all gameplay on the main thread (Guardado forbids workers; Regla 8 same-stack). Only engine-internal mixing/rendering runs off-thread; the control plane never crosses threads.

### Frame update path (duel tick)
`_physics_process` (resolver, PAUSABLE): (1) WallTick stamps pared tick [shared]; (2) digital input edge, no buffer [engine call]; (3) resolve vs live window, DiegeticTick sealed BEFORE dispatch; (4a) HIT → `parry_resuelto` → Ledger atomic earn → `BossFSM.on_combat_result` → B-* → read-only subscribers → transient → `Hitstop.play(f)` → `paused=true` LAST; (4b) WHIFF → 9-tick lockout, discards, zero feedback (C17); (4c) GOLPE → 25 dmg → Reception 8–12 → Enfriamiento (Core-Rule-9 floor); (5) HUD reads at full speed (C14).

### Event/signal path
BossFSM→Resolver windows (sync, cierre→resultado→transición, ADR-002 §2); Resolver→BossFSM `parry_resuelto` (enum + window_id + tick + delta/−1 + postura) via signal + direct same-stack call (no calidad field; VE ⇒ delta −1); Resolver→Ledger same event (atomic earn; Σ+s>3 ⇒ +0/+0); verdicts+B-*+levels → Feedback/Sonoro/HUD read-only (reentrancy guard); `duelo_ganado`/`duelo_perdido` → RunDirector (payload extensions only at Run authoring, trailing+defaulted); `combo_abortado(i,N)` → Feedback/Sonoro; Ledger levels+4 events → HUD/Overlay/Clímax/Sonoro (±1e-9, setters fail); MenuShell → SceneDirector/RunDirector/Sonoro (calls/signals, per-tick dedupe); PersistenceService → MenuShell facade (poll + SINCRONIZANDO push; menu never touches disk).

### Save/load path
Safe point (post_decision/Hub/post_reliquia, not in duel): PER serialize → pre-stringify validator → tmp (checked store_* chain) → reread+checksum → .bak rotation → save; fresh `per_checksum_ref` embedded into SUS in-memory; SUS tmp → reread → rename save (no .bak). Continuar: S2→S2b (lock input) → save→validating rename → validate → OK: promote, rehydrate, run_viva_visible, delete → S3; FAIL: delete → S1 + code; crash-validating without live: ONE recovery iff no recovered marker; second press: SUS_CONSUMED no-op. Muerte/abandono/fin: delete SUS, reconcile PER → S1.

### Initialisation order
(0) project.godot pins: 60 Hz physics, stretch, priorities, max_steps 8. (1) Autoloads: Config → Rng → Localization → WallTick. (2) PersistenceService validates PER + SUS summary → facade ready. (3) SceneDirector boot → splash → MenuShell (focus after splash). (4) Duel: PatternData load-gates (FAIL_LOAD) → pre-duel SUS invalidate (fail-closed) → resolver+FSM+Ledger reset → subscribers bound → HUD bound. (5) Post-duel: victoria → Reliquias → Decisión commit → Run advance → Hub (SUS rewrite; never post-reliquia straight to Hub).

## API Boundaries
Approved 2026-09-08. `Signal/Node/StringName/Callable` are stable types (LOW); dispatch/pause semantics are ⚠️ HIGH (ADR V1-tests). Full signatures with normative notes were approved inline; this section pins the contracts.

- **B1 Resolver↔BossFSM** (ADR-002 normative): `parry_resuelto(resultado, window_id, tick_deteccion, delta_ticks, postura_resultante)` + `castigo_iniciado` + `duelo_perdido` (Resolver); `golpe_iniciado/finalizado`, `ventana_especial_abierta/cerrada`, `combo_abortado(i,N)`, `estado_ingresado/abandonado`, `duelo_ganado` + `on_combat_result(res)` unique entry (BossFSM). Exactly-once; fixed order cierre→resultado→transición; VE ⇒ delta −1; corrupt payloads → RUNTIME_DROP; default-sync connections + reentrancy guard.
- **B2 Resolver→Ledger**: `proclaim_earn(res)` sync same-stack, exactly-once per EXITO_*, declared s for VE; atomic Σ-gated earn, never partial.
- **B3 Ledger spend+observe**: `intentar_gasto(poder_id, tick)` → OK/INSUFICIENTE/CAP/COOLDOWN/ESTADO_ILEGAL/TECHO_SATURADA/DECISION_ABIERTA; rejects change nothing; 4 level/event signals read-only (±1e-9), observer setters fail.
- **B4 Outcomes→Run**: `duelo_ganado(tick)` exactly-once on Muerto, never on defeat path (freeze-emits-nothing); payload stays `(tick)` until Run authoring.
- **B5 Persistence facade** (menu's ONLY interface): `SinContinuar` 12-code enum; `resumen_continuar()` display-safe revalidated on consume; `detalle_perdida()`; `estado_red()` (never OS text); `punto_seguro()`; `consumiendo` mutex; PER-before-SUS + Hub-exit barrier guarantees.
- **B6 Config+gates**: typed `knob()` reads (data-files rules); `validar_patron()` FAIL_LOAD shape (exit+ERROR+no start); RUNTIME_DROP ≠ FAIL_LOAD mid-duel.
- **B7 TimeAuthority**: WallTick (`Hitstop.play(ticks)`, `freeze_started/finalizado`, pool_log) + resolver-held DiegeticTick (`avanzar()` only); `_delta` banned for design durations; time_scale/playback_speed == 1.0 asserted at load.
- **B8 Presentation intakes** (zero gameplay writes): `request_destination()` closed set; run intentions (per-tick dedupe); UI intentions to Sonoro (menu never instantiates players); HUD read-only bindings (C14 full-rate in freeze) + `set_pausa_visual`; Decisión single-press commit; VfxPool direction-aware assign, recycle on `finished` only.

## ADR Audit
Approved 2026-09-08 (analysis; ADRs themselves unchanged).

| ADR | Engine Compat | Version | GDD Linkage | Conflicts | Valid |
|---|---|---|---|---|---|
| ADR-001 tiempo | ✅ 4.7.2, HIGH flagged, semantics gap declared | ✅ | ✅ 5-row table | External only: `gameplay-code.md` delta-rule contradicts Regla 2 (correction ordered, pre-sprint task) | ✅ conditional (V1–V7 pending) |
| ADR-002 eventos | ✅ 4.7.2, MEDIUM declared | ✅ | ✅ 6-row table | None | ✅ conditional (V1 pending) |
| ADR-003 bus | ✅ 4.7.2, MEDIUM declared | ✅ | ✅ 4-row table | None | ✅ conditional (Deck measurement pending) |

Traceability (55 TRs: 22 registry + 33 proposed §0b): 47 covered (6 by ADR-001/002/003 triples + 41 by this architecture's layers/ownership/flows/B1–B8 + GDD-owned formulas), 5 partial pending required ADRs below (TR-guardado-002/004 checksum; TR-menu-004 preload; TR-parry-010 HUD-40Hz; TR-parry-008 emitter+TIME), 3 future-blocked (TR-jefe-008 needs #2 4th pass; R10e at #9; E5 at #19), 0 orphaned. Committed `architecture-traceability.md` (0/22, 2026-09-03) is stale — `/architecture-review` owns it and refreshes from these ADRs + this baseline (new TR-gracia/guardado/menu/sonoro/ia IDs appended there, never renumbered).

## Required ADRs
Must have before coding (Foundation & Core): checksum SHA-256 + canonical-JSON confirmation (TR-guardado-002/004) · async preload Hub→Duelo + veil + Shader Baker (TR-menu-004) · VFX emitter unification + pool sizing P0-DEF (TR-parry-008) · HUD-40Hz transition strategy (TR-parry-010) · shader time-driver + uniform convention (TR-parry-008/TR-jefe-008). Triggered (not now): R10-magnitudes ratification at #9 (needs GX-13 evidence [3c]) · E5 rewrite at #19 · 94-tras-100 at #6 (S5) · `gameplay-code.md` delta-rule correction (pre-sprint process task). Deferred to measurement: voice/DSP final budgets (SN-11/P5-DEF) · Lucifer provisioning (#11).

## Architecture Principles
1. Tick authority is structural, never disciplinary — immunity by construction (pausable resolver, integer counters), not programmer care. (Pilar 2)
2. Decide once, present everywhere — single-owner resolution/emission, read-only subscribers, no reentrancy. (Legibility)
3. Power always carries a computed cost — closed contracts (Σ-gates, R10 deltas, nonzero R9b); unquantified effects fail load (C26). (Pilar 1)
4. Freeze the world, never the judgment — diegetic 0%, HUD/ears full-rate; onset ≤2 wall ticks is budget, not knob. (Sensación)
5. Persistence is forensic — staged journal, fail-closed invalidation, single recovery, menu never touches disk. (Pilar 4)

## Open Questions
| ID | Summary | Priority | Resolution path |
|---|---|---|---|
| QQ-01 | VFX emitter unification + pool sizing | High | Required ADR (P0-DEF, pre-VFX) |
| QQ-02 | HUD-40Hz transition strategy | High | Required ADR (pre-HUD-sprint) |
| QQ-03 | Shader TIME-driver convention | High | Required ADR (V6 area, pre-VFX) |
| QQ-04 | Checksum + canonicalization confirmation | High | Required ADR (pre-save-stories) |
| QQ-05 | Preload/baker/veil strategy | High | Required ADR (pre-Hub↔Duelo wiring) |
| QQ-06 | Motor V1 validation (pause/dispatch) | High | BLOCKING first wiring story (ADR-001/002 V1) |
| QQ-07 | R10e derivation + GX-13 gamesim | Medium | At #9 authoring, pre-#9-lock [3c] |
| QQ-08 | E5 rewrite execution | Medium | At #19 authoring |
| QQ-09 | 94-tras-100 semantics | Medium | At #6 authoring (S5) |
| QQ-10 | Attention-budget validation V1b/SN-12 | Medium | Pre-#20-close (OQ2/OQ3) [3b] |
| QQ-11 | Techo calibration protocol | Medium | Vertical Slice prototype |
| QQ-12 | Duration-curve legibility proof vs A2 | Medium | Playtest "gramática antes que silueta" [3e] |

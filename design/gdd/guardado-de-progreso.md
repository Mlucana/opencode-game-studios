# Guardado de Progreso

> **Status**: In Revision (Rev 2 — 2026-09-04; revoca el sello CD-GDD-ALIGN 2026-09-03 tras review MAJOR, 12 bloques)
> **Creative Director Review (CD-GDD-ALIGN)**: REVOKED 2026-09-04 — veredicto MAJOR REVISION NEEDED (`design-review --depth full`: 5 especialistas + síntesis senior)
> **Author**: [user + agents]
> **Last Updated**: 2026-09-04 (Rev 2)
> **Decisiones adjudicadas por el usuario (2026-09-04)**: R9 = staged journal · R5 = hardline sin resume de emergencia + señal segura · R6 = PER-first · S4 = tercera salida con restore consentido
> **Implements Pillar**: Infraestructura — habilita el Pilar 4 (vínculo vía fragmentos persistentes) y la retención por inversión (llaves, fragmentos, finales); sin fantasía de jugador directa

## Overview

El Guardado de Progreso es la capa de persistencia local del juego: conserva entre sesiones todo lo que sobrevive a una run —llaves de meta-progresión, fragmentos de memoria, ajustes y estadísticas— y permite suspender la run en curso para continuarla después. El jugador nunca gestiona ficheros: hay un único perfil con autosave silencioso en los puntos definidos, y la suspensión es de un solo uso —al consumirse se invalida por diario por fases—, de modo que ninguna decisión intra-run (absorber o rechazar, gastar gracia) puede revertirse recargando. Un crash durante la carga concede un único intento de recuperación (nunca resurrección indefinida). Sin este sistema no habría meta-progresión de llaves ni puntos de parada compatibles con runs de 30–45 minutos; con él, interrumpir una sesión cuesta como máximo la suspensión vigente, nunca la cruzada.

## Player Fantasy

El jugador no debe sentir el guardado — debe sentir lo que el guardado hace posible. Al apagar entre coros y volver días después al mismo punto de la cruzada, sin haber perdido una llave ni un fragmento, siente que su duelo continúa aunque él se detenga: la novena espera. Y al saber que retomar una suspensión la consume, que absorber o rechazar no puede deshacerse recargando, siente el peso de lo irreversible: lo hecho, hecho está. Sirve a dos pilares: al Pilar 1 (*"Ninguna ganancia de poder es gratuita: todas cobran algo sobre quién es el protagonista"*) — el guardado obedece prohibiendo revertir — y al Pilar 4 (*"El motor del protagonista nunca es la venganza abstracta ni el poder: es recuperar a su familia"*) — lo que persiste entre runs es memoria de familia, no estadísticas. El sistema es invisible por diseño: ningún "¡Progreso guardado!", ninguna celebración, ninguna red de seguridad.

## Detailed Design

### Core Rules

**R1 — Tres ficheros, tres ciclos de vida.** `profile.save` (PER: lo que sobrevive a la run, irrevocable una vez escrito), `suspend.save` (SUS: foto de un solo uso de run en pausa, solo válida en punto seguro, nunca contiene combate activo), `settings.save` (SET: ajustes — volumen, idioma, accesibilidad, controles — independientes del progreso). La corrupción de uno nunca impide validar los otros. Ningún código de gameplay lee disco directamente: todo pasa por una fachada de persistencia con caché en memoria.
**R2 — Contenido de PER (categorías cerradas; los valores los define la carta).** `save_format_version`, `llaves_ids[]` (solo IDs, sin duplicados), `fragmentos_ids[]` + orden de obtención (solo append), `flags_desbloqueo_meta`, `estadisticas_acumuladas` (contadores `int ≥ 0`, saturan sin overflow), `run_uuid` + `per_checksum_ref` (ganchos anti-conflicto futuro). Prohibido en PER: loadout de run, gracia/corrupción de run, HP, estado de duelo, semillas.
**R3 — Contenido de SUS (foto exacta del punto de progresión).** `save_format_version`, `version_contenido_run`, `timestamp` (diagnóstico) + `playtime_acumulado` (por deltas in-game, nunca wall-clock), `coro_siguiente_idx` (`0–8`; v1.0 efectivo `0–2`), `representantes_derrotados[]`, `decision_absorber[]` (paralelo, `0` rechazar / `1` absorber), `representantes_pendientes[]`, `loadout_reliquias_ids[]` ordenado, `gracia_actual` / `corrupcion_actual` / `poso_irreversible` (`≥ 0`, opacos para este sistema), `angeles_absorbidos` (`0–9`; v1.0 efectivo `0–3`, un ángel por tríada implementada — espejo de `coro_siguiente_idx`; alimenta la `vida_maxima` de Combate), `semilla_rng` (64 bits de entropía SO por run, sin promesa estadística de unicidad) + `posicion_rng` (cursor de extracciones — la semilla sola no reproduce ofertas), `punto_seguro_id` (`entre_coros | hub | post_reliquia | post_absorber`), `per_checksum_ref`, `extras_run` (bolsa opaca versionada; claves desconocidas se ignoran semánticamente pero se transportan verbatim — ver R11). Prohibido en SUS: cualquier estado de combate (vida/postura/timers/FSM/hitstop/buffers), ajustes, acumulados, llaves/fragmentos. Tipos siempre JSON-safe (`null/bool/int/float/String/Array/Dictionary` con claves `String`); prohibidos `Vector2/Color/NodePath/RID/Object/Callable`; snapshot en memoria por copia profunda inmutable.
**R4 — Escritura de PER (la frontera de irreversibilidad es la durabilidad, no la memoria).** Proceso: (1) tras victoria de coro ya aplicada la post-reliquia y la decisión absorber/rechazar; (2) ganancia lógica **inmediata en memoria** al obtener llave/fragmento/final o cambiar un ajuste — la memoria marca `per_dirty=true` (no hay "cola": un flag basta; la caché es la fuente de verdad) y el flush físico ocurre coalescado (todas las ganancias pendientes en una sola escritura) en el siguiente punto seguro, con `FileAccess` síncrono permitido ahí —es punto seguro, no hot-path de combate— y prohibido en hot-path (un hitch rompería el requisito <100 ms del parry); todo IO vive en el main thread, sin worker threads (ver R6); (3) reconciliación de estadísticas al cerrar run (muerte, victoria, abandono). Si mueres 2 s después de obtener una llave *y el flush del punto seguro ya ocurrió*, la llave se conserva: es memoria de familia (Pilar 4), no ventaja de run. Si el crash llega con `per_dirty` pendiente, el delta se da por **nunca ocurrido** (sin merge ni replay): irrevocable-en-memoria ≠ durable, y el Menú nunca promete lo contrario.
**R5 — Escritura de SUS (solo fuera de duelo).** Solo evaluable si `en_duelo == false` y `punto_seguro == true`, y solo en puntos `post_decision` (jamás `pre_eleccion`: suspender antes del commit permitiría re-elegir por recarga). Al entrar en duelo la SUS se invalida con rename síncrono a `suspend.invalid` (semántica única: siempre rename forense, nunca unlink directo; el `.invalid` se ignora y borra en arranque o al crear la SUS siguiente) antes de instanciar el duelo; **si la invalidación falla (EACCES, lock antivirus, FS read-only), el duelo NO se instancia** — fail-closed con diagnóstico en Hub y log (entrar con SUS válida sería vector de dupe). Al entrar a duelo no se intenta flush de PER con `per_dirty` (R4 manda fuera de duelo); la invalidación SUS procede igual; el orden PER-antes-que-SUS de R6 no aplica porque en la entrada no hay commit SUS. En duelo el menú solo ofrece Abandonar. Cerrar el juego en punto seguro no requiere acción: la SUS ya existe por autosave. **Señal segura (Rev 2):** este GDD expone el evento/booleano `punto_seguro` (`pre_eleccion == no-seguro` incluido); la presentación (cue quiescente de Hub, nunca toast ni celebración, reduced-motion-safe) la posee el Menú/HUD; antes de entrar a duelo el Hub muestra el coste honesto ("entrar cuesta la suspensión"). Sin resume de emergencia en v1.0 (adjudicado 2026-09-04; revisitar como variante costeada solo si el playtest muestra abandono en Deck).
**R6 — Orden de escritura y cadena de verificación.** (1) Serializar en memoria primero — **validador recursivo pre-`stringify` normativo** (recorre el snapshot: rechaza NaN/Inf vía `is_nan`/`is_inf`, tipos fuera de `null/bool/int/float/String/Array/Dictionary`, claves no-`String`, negativos donde aplique); fallo de validación o serialización = abortar sin crear `.tmp`, sin tocar disco ni `.bak`, sin marcar `per_dirty`, con log de la clave ofensiva. El fallo del serializador es *segunda* red, nunca la primera; `var_to_str`/`var_to_bin` prohibidos para saves. (2) PER: escribir a `profile.tmp` **comprobando la cadena completa** — `FileAccess.open()` no-nulo (+`get_open_error()`), cada `store_*` (`bool` desde Godot 4.4) comprobado, `get_error()` tras `close()`; cualquier `false`/error aborta el commit y conserva el save bueno anterior. Verificación por relectura del `.tmp` (re-parse + checksum); OK → rotación `.bak` explícita: `profile.save → profile.save.bak` (solo si el actual valida), luego `profile.tmp → profile.save`. (3) Solo si (2) OK: computar el checksum de la **nueva imagen PER** y embarcarlo como `per_checksum_ref` en la imagen SUS **en memoria, antes de escribir**; luego SUS a `suspend.tmp` → verificación → rename a `suspend.save` (sin `.bak`, sin Cloud, sin papelera: cualquier copia restorable de SUS es vector de dupe). (4) Actualizar caché y limpiar `per_dirty`. PER siempre antes que SUS: ante crash intermedio se prefiere perder la suspensión a perder meta-progresión (adjudicado 2026-09-04, Pilar 4); si PER falla, SUS no se escribe ese tick. **Checksum (fijado en Rev 2, ADR pendiente de confirmación):** SHA-256 sobre JSON canónico (claves ordenadas, floats con precisión fijada, UTF-8 locale-invariante; el propio campo checksum auto-excluido del cómputo). Sin `fsync` garantizado (admitido): `store_*=true` + rename OK = "el SO aceptó los bytes", no "están en medio físico"; el backstop real es el checksum en carga (R8). El log de fallo a `user://` es best-effort acotado (un intento; si el FS está lleno/ilegible, memoria primero).
**R7 — Fallos y reintentos (con R7a).** Escritura fallida (disco lleno, permisos, lock antivirus, `user://` ilegible): 3 reintentos con backoff corto fuera de hot-path (fórmula `retardo_reintento`; reloj inyectable —seam `Clock/Sleeper` para tests deterministas, nunca wall-clock directo—; todo en main thread en puntos seguros/pausa/menú, sin worker threads). Si PER falla: se mantiene caché, se marca `per_dirty=true`, se guarda el motivo en cascada —memoria (no durable; legible por Menú en S1/S2 hasta reiniciar) → sidecar `save_health.json` best-effort de un intento— y en el log interno en `user://`; el éxito es silencioso, el fallo nunca con popup mid-duelo; se reintenta en el siguiente punto seguro. Si hasta el sidecar falla, estado "salud desconocida, verificado en arranque" derivado de R8 (sin promesa falsa de visibilidad total). Si SUS falla: la run continúa en memoria sin red; el siguiente punto seguro reintenta. Crash mid-write deja `.tmp` huérfano: al arrancar se ignora/borra y solo se valida el destino.
**R7a — Validación de config en carga.** Rechazar (volver a defaults + log) cualquier config con `techo < base`, `base ≤ 0`, `factor < 1.0` o NaN en `base`/`factor`/`techo`; expresión endurecida `min(base · factor^(clampi(n,1,3)−1), techo)`. AC-F1 cubre el caso inválido.
**R8 — Carga de PER (arranque).** (1) Sin `profile.save` → S0, salvo que exista `profile.save.bak` válido → S4 (hay evidencia; nunca S0). (2) Validar parse + versión + checksum + invariantes mínimas (IDs conocidos, rangos). (3) OK → memoria (S1/S2 según SUS). (4) Versión vieja migrable → S5. (5) Checksum/parse fallido → S4: se preserva el fichero para diagnóstico y **nunca** se auto-sobrescribe.
**R9 — Consumo de SUS por diario por fases —staged journal— (Continuar).** Orden normativo: (0) `suspend.save` → rename a `suspend.validating` (intención durable, antes de instanciar nada). (1) Validar checksum, versión, `per_checksum_ref == PER actual`, punto seguro e invariantes de carta. (2) Si inválida: borrar `validating`, tratar como "sin suspensión" (código causal al Menú). (3) Si válida: promover `validating → suspend.save` + rehidratar la run (coro, loadout, gracia/corrupción/poso, representantes, restaurar `posicion_rng`); borrar `save`+`validating` cuando la run confirma run viva visible — commit-point nombrado: señal explícita `run_viva_visible` de Gestión de Run (la confirma Run, no este sistema). (4) Crash/kill durante (1)–(3) con `validating` sin live confirmado → al arrancar, **UN único intento de recuperación**: si no existe marcador `suspend.recovered`, crearlo, re-validar `validating`, promover a `save` → S2 (el jugador pulsa Continuar de nuevo, consumo fresco); si el marcador ya existe (segundo strike) → borrar `validating` + marcador → S1, PER intacto. El segundo Continuar (mismo tick o posterior) relee disco tras el rename: sin `suspend.save` → no-op con código `SUS_CONSUMED`, sin segunda instanciación; Continuar se deshabilita tras el primer press + re-chequeo post-rename como mutex. "Todo idéntico" = estado de gameplay idéntico (excluye `timestamp`, `playtime` y la propia SUS). Amenaza cubierta: flujos in-game (recarga, muerte→continuar, doble pulsación, kill, Deck dormido). Fuera de alcance declarado: copia manual del fichero en el SO y multi-dispositivo (dupe efectivo aceptado; sin nonce single-use no se distingue copia de original — nonce = vía de mejora post-v1.0 si Cloud vuelve). Igual para SUS resucitada por Cloud: v1.0 no activa Cloud (ver R6/Dependencias); si Cloud se activa algún día, la exclusión `suspend.*`/`*.tmp`/`validating`/`recovered`/`invalid` es requisito bloqueante, no mitigación existente.
**R10 — Muerte, Abandono, Fin.** Muerte en duelo: borrar residuo SUS, reconciliar PER, a S1 — nunca "reintentar duelo desde suspensión". Abandono desde punto seguro: borra SUS y va a S1 (la run se pierde; lo persistente se conserva). Abandono en duelo: renuncia total, solo PER. Fin de run (victoria, final, paz por saturación): borra SUS, escribe PER, a S1. Abandonar nunca revierte llaves/fragmentos.
**R11 — Versionado y migración.** `save_format_version` (único que decide compatibilidad) + `game_version` informativa + checksum, en los tres ficheros; formato JSON UTF-8 con locale invariante. Versión futura/desconocida: rechazar sin destruir (SUS futura se descarta sin backup ni papelera — archivar copia restorable sería vector de dupe; PER futuro va a S4, único estado seguro existente, sin parsear ni sobrescribir). Versión antigua: migrar PER solo con ruta declarada (típico N−1), con backup `profile.save.bak.<ver>` y validación completa; sin migrador → reset controlado documentado. **SUS vieja nunca migra**: toda SUS con `version != actual` se descarta. SET con sección inválida: esa sección vuelve a defaults **con aviso persistente no-modal al jugador** (ver UI Requirements; la política de fallback la posee #21 Accesibilidad), el resto se conserva. Claves futuras desconocidas (SET y `extras_run`) → ignorar semánticamente al leer pero **transportar verbatim al reescribir** (round-trip: una build vieja nunca destruye claves de build nueva); el borrado intencional de claves solo ocurre en migraciones declaradas. Cada bump añade entrada a la tabla de migraciones + test de carga de save viejo.
**R12 — Reset manual y tercera salida de S4.** Desde el menú, con firma Tipo-A (hold + listado, Menú R4 — la invariante "exactamente 2 pasos" quedó derogada en Menú Rev2): borra PER (+`.bak` y `.bak.<ver>`) + SUS (+`validating`/`recovered`/`invalid`/`tmp`), conserva SET, limpia caché y `per_dirty` → S0 irrevocable, con listado que nombra la pérdida y lo conservado (detalle regenerado fresco al armar) y log de lo borrado. Soltar antes del hold, cancelar o kill a mitad ≡ cancelar (nada se borra antes del commit). Junto al Reset, S4 ofrece una **tercera salida: restaurar `.bak` íntegro con consentimiento explícito** del jugador en pantalla S4 (checksum verificado pre-restore, log registrado; jamás automático; tipo de firma lo decide Menú). Reset y restore son las únicas salidas de S4/S5-fallo y la vía de QA/familias compartiendo PC. No gestiona ficheros: botones, no rutas.

### States and Transitions

| Estado | Definición | PER | SUS | UI esperada |
|---|---|---|---|---|
| S0 SIN_PERFIL | Primer arranque | No | No | Solo Nueva Cruzada / Ajustes; sin Continuar |
| S1 PERFIL_SIN_RUN | Perfil activo, sin run | Sí | No | Nueva Cruzada; Continuar deshabilitado (con código si hubo run perdida en duelo: `DUEL_NO_WAIT`) |
| S2 SUSPENSION_VIGENTE | Run pausada en punto seguro | Sí | Sí | Continuar habilitado + Nueva Cruzada (siempre con firma destructiva Tipo-A) |
| S2b CONSUMIENDO | Continuar en curso (input bloqueado, foco aparcado en opción no-destructiva) | Sí | En consumo | Sin interacción; segundo intento = no-op con código |
| S3 DUELO_SIN_RED | Run en duelo | Sí | No | Sin Continuar; en pausa solo Abandonar; cerrar = pérdida de run |
| S4 PERFIL_CORRUPTO | PER inválido/ilegible/futuro, o save ausente con `.bak` válido | No fiable | Indet. | Reset / restore consentido / diagnóstico; Continuar oculto; jamás auto-sobrescribir |
| S5 MIGRACION_REQUERIDA | PER viejo migrable | Viejo | Se ignora | Solo Migrar / Reset; sin Continuar hasta migrar |

Transiciones válidas (toda transición no listada es inválida): S0→S1 crear perfil (`ensure_profile` en primer arranque; Ajustes en S0 vía `UserSettings` sin crear PER ni SUS) · S1→S3 iniciar run · S3→S2 alcanzar punto seguro post-decisión (R4/R5/R6) · S2→S2b Continuar (rename a `validating`, R9) · S2b→S3 validación OK + `run_viva_visible` · S2b→S1 validación fallida o consumo confirmado · S2→S3 entrar a duelo (invalida SUS con rename síncrono; fail-closed R5) · S3→S2 vencer coro + post-decisiones (R4 luego R6) · S3→S1 muerte (borra residuo, reconcilia PER) · S2→S1 abandono directo · S2→S3 Nueva Cruzada con firma atómica (equivale al par ordenado abandono + inicio) · S2→S2 nuevo punto seguro (reescribe SUS) · S0→S0 / S1→S1 ganancia fuera de run o ajuste (reescribe PER/SET) · S2/S3→S1 fin de run · {S0,S1,S2}→S4 PER inválido/ilegible/futuro al arrancar, o `profile.save` ausente con `.bak` válido (preservar, no escribir) · S4→S0 reset con firma (R12) · S4→S1 restore consentido de `.bak` (R12) · S1/S2/S3/S5→S0 reset con firma (R12; soltar/cancelar/kill a mitad ≡ cancelar) · {S0,S1,S2}→S5 PER viejo migrable · S5→S1 migración OK (backup + borra SUS vieja) · S5→S4 migración sin ruta/fallida · S2→S1 [SUS versión ≠ actual] descarte — nunca migra · S3→S1 crash en duelo (run perdida por diseño) · S2→S2 crash en punto seguro (único resume). Invariantes: nunca S3→S2 sin victoria de coro; nunca SUS sobrevive a la entrada en duelo; nunca carga sin consumo previo (R9); nunca Nueva Cruzada con SUS vigente sin confirmación. (Los crashes no son transiciones del sistema: su semántica vive en Edge Cases.)

### Interactions with Other Systems

| Sistema | Dirección | Interfaz (qué fluye, quién posee qué) |
|---|---|---|
| #10 Meta-progresión Llaves | Este consume de Llaves | Evento `llave_obtenida(id)` → upsert idempotente en `llaves_ids` (recibirlo dos veces no duplica). Llaves posee el catálogo y efectos; este GDD posee cuándo/cómo se fijan. Provisional: Llaves aún sin GDD. |
| #3 Gestión de Run | Bidireccional (contrato) | Run expone `coro_siguiente_idx`, representantes asignados/pendientes, `semilla_run + posicion_rng`, `punto_seguro_id`, evento de commit post-decisión. Este GDD expone la foto versionada + `run_uuid`. Provisional: Run aún sin GDD. |
| #5 Gracia Tres Capas | Este consume de Gracia | `gracia_actual`, `corrupcion_actual`, `poso_irreversible` (opacos; el poso nunca baja al gastar). Gracia posee semántica y techos; este GDD solo los transporta. Exigencia hacia Gracia (de R9a del sistema 1): coste no nulo de corrupción. Provisional. |
| #9 Reliquias | Bidireccional (contrato) | Reliquias expone `loadout_reliquias_ids[]` y emite cambios post-selección; este GDD los persiste y devuelve el loadout al rehidratar. Restricción vigente de Combate R10: reliquias acotadas por magnitudes observables. Provisional. |
| #17 Fragmentos | Este consume de Fragmentos | Evento `fragmento_visto(id)` → append idempotente. Fragmentos posee contenido y orden narrativo. Provisional. |
| #15 Menú y Flujo | Este expone a Menú | Fachada normativa §Fachada (códigos + 4 campos + CONSUMIENDO + barrera + evento `punto_seguro`). Menú no lee disco jamás. Nota para #15: mensaje de run perdida en duelo y firma destructiva de Nueva con SUS vigente. |
| Ajustes/Accesibilidad (#21) | Este posee | Claves cerradas de SET con defaults; si una sección falla, defaults + aviso (política de fallback la posee #21), el resto se conserva. |

### Fachada (contrato simétrico con #15 — owned por este GDD, proveedor)

El Menú consume exclusivamente esta fachada; ningún otro campo existe para presentación.

**Códigos de motivo (enum estable, sin español normativo — los literales los posee `/localize` vía claves `MENU_*` de #15):** `NO_SUSPEND` · `DUEL_NO_WAIT` · `PROFILE_CORRUPTO`/`PROFILE_ILEGIBLE`/`PROFILE_FUTURO` (3 códigos, no 1) · `SUS_CONSUMED` (transitorio, solo CONSUMIENDO) · `SUS_FOREIGN_REF` · `SUS_RECOVERED` (recuperada tras crash en carga, un intento) · `SUS_VERSION_DISCARD` (descartada por versión) · `SUS_VERSION_OLD` (S5: PER viejo migrable, sin Continuar hasta migrar) · `PROFILE_LOCKED` (sin superficie de menú: error de arranque/diálogo SO) · `PER_DIRTY_*` (nunca texto crudo del SO).

| Campo | Forma | Notas |
|---|---|---|
| `ultimo_motivo_sin_continuar` | código del enum | Uno por estado; S1-post-duelo ≠ S1-virgen ≠ S1-ref-mismatch |
| `destino_continuar_id` | `Hub` \| `Reliquias` según `punto_seguro_id` | Mapeo owned aquí; #15 solo enruta |
| `resumen_continuar` | `{coro_siguiente_idx, playtime_acumulado, punto_seguro_id}` (valores crudos; el formato `coro_label` + `playtime_floor_s` lo compone #15) | Subtítulo de Continuar; composición owned aquí, display owned Menú |
| `detalle_perdida` | `{coro, resumen_loadout, gracia, corrupcion}` + conservados `{n_llaves, n_fragmentos, set_preservado, sus_muere_al_migrar}` | Paso 2 de Reset/diagnóstico regenera el detalle fresco al entrar |
| `estado_red` | `{per_dirty: bool, code}` | Renderizable en 7": código + conteo, jamás `EACCES`/rutas |
| `CONSUMIENDO` | estado proveedor: input bloqueado, foco aparcado en opción no-destructiva, segundo intento = no-op con `SUS_CONSUMED` | Cierra la raza TOCTOU de doble-Continuar (ver R9) |
| Barrera Hub | cancelar-flush-SUS-pendiente → rename síncrono → instanciar | Orden garantizado en la entrada a duelo (ver R5) |
| `punto_seguro` | evento/booleano (`pre_eleccion == no-seguro`) | Alimenta la señal segura quiescente de #15 (ver R5) |

## Formulas

La fórmula **retardo_reintento** se define como:

`retardo_reintento = min(base * factor^(clampi(n,1,3)-1), techo)`

(R7a valida la config en carga; la expresión es total solo en 1–3 por construcción.)

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| nº de reintento | n | int | 1–3 | 1 tras el primer fallo; 3 es el último permitido (R7) |
| retardo base | base | float | > 0 s | Espera del primer reintento (lanzamiento: 0.25 s) |
| factor backoff | factor | float | ≥ 1.0 | 1.0 = fijo; > 1.0 = exponencial (lanzamiento: 2.0) |
| techo | techo | float | ≥ base | Cota que garantiza "corto" (lanzamiento: 2.0 s) |

**Output Range:** base a techo en juego normal; si n=3 falla → abortar commit, conservar el save bueno anterior y marcar `per_dirty` (R7). Nunca loop infinito; toda espera fuera de hot-path.
**Ejemplo:** base=0.25, factor=2.0, techo=2.0 → n=1: 0.25 s; n=2: 0.50 s; n=3: 1.00 s (máx. acumulado 1.75 s).

La fórmula **playtime_acumulado** se define como (tick t → t+1; `reloj_valido == false` en pausa/menús y en el primer frame tras resume/sleep):

`delta_eff = (is_finite(delta_crudo) ? clampf(delta_crudo, 0.0, delta_max) : 0.0)`
`delta_eff = (reloj_valido ? delta_eff : 0.0)`
`playtime_acumulado = max(0.0, playtime_acumulado + delta_eff)`

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| tiempo acumulado | playtime_acumulado | float | 0.0–+inf s | Vive en SUS, float JSON-safe |
| delta crudo | delta_crudo | float | ℝ ∪ {NaN,±Inf} (no confiable) | Delta del frame procesado in-game, bucle `_process` (no física: a 60 Hz física el delta 1/60 ≪ `delta_max` y el clamp sería código muerto) |
| delta efectivo | delta_eff | float | 0.0–delta_max s | Interno: clamp [0, `delta_max`] + NaN/Inf → 0 + puerta de reloj |
| puerta de reloj | reloj_valido | bool | — | `false` en pausa/menús y primer frame tras resume/sleep (ese frame acumula 0, no `delta_max`) |
| cota anti-spike | delta_max | float | > 0 s | Guarda contra hitches/Deck dormido (lanzamiento: 0.10 s) |

**Output Range:** 0.0 a ~2700 s en juego normal (runs 30–45 min); pausa/menús/sueño acumulan 0 (nunca wall-clock). R9 la excluye de la identidad "todo idéntico".
**Ejemplo:** 1234.50 s + 60 frames a 0.0167 s → 1235.502 s. Mostrar en UI con `floor()` sin truncar lo almacenado.

La fórmula **contador_saturado** se define como (suma saturante — la guarda se evalúa *antes* de sumar, nunca después):

`contador_saturado = (d ≥ 0 ∧ c_viejo > INT64_MAX − d) ? INT64_MAX : max(c_viejo + d, 0)`

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| contador previo | c_viejo | int | 0–INT64_MAX | Elemento de `estadisticas_acumuladas` (R2) |
| incremento | d | int | típ. ≥ 0 | Reconciliación al cerrar run (R4/R10); `d ≥ 0` en todas las call sites (monótono no-decreciente); la rama `max(...,0)` es defensiva ante `d` negativo inesperado |

**Output Range:** 0 a INT64_MAX (hecho de engine GDScript, no balance); en juego real: decenas/miles. Nota de serialización: exactitud integers JSON solo garantizada hasta 2⁵³−1; por encima, la inexactitud de round-trip se declara admitida (el techo INT64_MAX es inalcanzable en juego real y solo vive en tests). Monótono no-decreciente para `d ≥ 0`: abandonar nunca revierte (R10).
**Ejemplo:** 41 + 1 (una muerte) → 42.

La fórmula **upsert_llaves** se define como:

`upsert_llaves = llaves_viejo si (id ∉ catálogo ∨ id ∈ llaves_viejo), si no llaves_viejo + [id]`

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| set persistido | llaves_viejo | Array[String] | 0–N_catálogo, sin duplicados | `llaves_ids[]` en PER |
| evento | id | String | ID de catálogo | `llave_obtenida(id)`; Llaves posee el catálogo |

**Output Range:** 0 a N_catálogo elementos; doble evento = no-op (idempotente); ID desconocido = ignorar sin escribir.
**Ejemplo:** `[LLAVE_01, LLAVE_03]` + evento `LLAVE_03` → sin cambio; + evento `LLAVE_02` → `[LLAVE_01, LLAVE_03, LLAVE_02]`.

La fórmula **append_fragmentos** se define como:

`append_fragmentos = fragmentos_viejo si (id ∉ catálogo ∨ id ∈ fragmentos_viejo), si no fragmentos_viejo + [id]`

**Variables:**
| Variable | Símbolo | Tipo | Rango | Descripción |
|---|---|---|---|---|
| log persistido | fragmentos_viejo | Array[String] | 0–N_catálogo, orden = obtención | `fragmentos_ids[]`; solo append, nunca reorder/borrado |
| evento | id | String | ID de catálogo | `fragmento_visto(id)`; Fragmentos posee el contenido |

**Output Range:** 0 a N_catálogo; re-emisión = no-op; ID desconocido o catálogo vacío = ignorar sin escribir ni dirty; único borrado posible: Reset R12.
**Ejemplo:** `[FRAG_A, FRAG_C]` + evento `FRAG_A` → sin cambio; + evento `FRAG_B` → `[FRAG_A, FRAG_C, FRAG_B]`.

No hay más cálculos en R1–R12: checksum, versionado, transporte opaco de gracia/RNG y timestamps son predicados, envelopes u operaciones FS — intencionadamente fuera de esta sección.

## Edge Cases

**Rangos y validación**
- **Si un contador de `estadisticas_acumuladas` está en INT64_MAX y llega incremento**: satura a INT64_MAX, commit válido sin wrap ni error.
- **Si un incremento dejaría un contador < 0**: satura a 0, commit válido (fórmula `contador_saturado`).
- **Si arrays (llaves, fragmentos, derrotados, loadout) están vacíos en perfil/run nuevos**: válido, nunca señal de corrupción.
- **Si `coro_siguiente_idx` fuera de 0–8 (o 3–8 en build v1.0)**: SUS inválida → descartar sin resurrección → S1 con log. Nunca clampear.
- **Si `angeles_absorbidos` fuera de 0–9 (o 4–9 en build v1.0), `decision_absorber` con valor ≠ 0/1, longitudes derrotados/decisión distintas, pendientes ∩ derrotados ≠ ∅, o IDs desconocidos**: SUS inválida → descartar → S1, PER intacto.
- **Si llega evento de llave/fragmento con catálogo aún vacío (sistemas sin GDD)**: no-op idempotente, sin dirty ni escritura ni error.
- **Si SUS trae `playtime` negativo/NaN/Inf o `timestamp` inválido**: reparar a default + log y aceptar (campos cosmético/diagnóstico, nunca descartan la run). **Si trae gracia/corrupción/poso negativos o NaN/Inf, `posicion_rng` < 0 o no-entero, `punto_seguro_id` inválido, `per_checksum_ref` ausente o con tipo erróneo, o `version_contenido_run` ≠ actual**: SUS inválida → descartar → S1, PER intacto. En runtime, `delta_crudo` pasa por `delta_eff` (fórmula) antes de acumular.
- **Si SET tiene una sección con rango/tipo inválido**: esa sección vuelve a defaults **con aviso persistente no-modal** (ver UI Requirements), el resto se conserva, se reescribe fuera de hot-path. SET ausente → crear con defaults. Claves futuras desconocidas (SET y `extras_run`) → ignorar semánticamente al leer, **transportar verbatim al reescribir** (R11).
- **Si el validador pre-`stringify` rechaza el snapshot (tipos no JSON-safe o NaN/Inf)**: abortar commit sin crear `.tmp`, sin tocar disco ni `.bak`, sin `per_dirty`, con log de la clave ofensiva (R6).

**Simultaneidad**
- **Si llave/fragmento y muerte caen en el mismo tick**: primero la ganancia en memoria (inmediata, R4), luego reconciliación de muerte, luego PER con la llave incluida → S1.
- **Si cierre/kill entre victoria de coro y commit post-decisión**: no hay SUS nueva; equivale a crash en duelo (S3→S1), nunca resume a mitad de decisión. Tras commit completo en punto seguro → S2 preservada.
- **Si segundo Continuar sin `suspend.save` (ya consumida)**: abortar con código `SUS_CONSUMED`; no instanciar segunda run, no resucitar; Continuar se deshabilita tras el primer press + re-chequeo post-rename.
- **Si una segunda instancia abre el mismo `user://` con el perfil en uso**: aborta pre-escritura con código `PROFILE_LOCKED` (lockfile cooperativo best-effort con staleness por timeout), sin escribir ni consumir. Evita last-writer-wins y doble consumo en el caso cubierto; fuera de él, último-escritor-gana aceptado (ver AC-T1).

**Corrupción y versiones**
- **Si PER inválido pero SUS verifica**: ir a S4, Continuar oculto, preservar ambos ficheros, no consumir ni borrar SUS. Sin PER fiable no hay consumo seguro (`per_checksum_ref`).
- **Si SUS válida pero `per_checksum_ref` ≠ PER actual**: descartar SUS → S1 con código `SUS_FOREIGN_REF`, PER intacto.
- **Si SUS con versión ≠ actual**: descartar sin backup ni migración → S1. SUS vieja nunca migra.
- **Si PER con versión futura**: no parsear, no sobrescribir, no migrar → S4 con código `PROFILE_FUTURO`, preservar fichero.
- **Si SUS con versión futura**: descartar sin backup ni papelera → sin suspensión, PER intacto (archivar copia restorable sería vector de dupe).
- **Si al arrancar hay `.tmp` huérfanos o `suspend.invalid` residual**: borrarlos/ignorarlos antes de validar; nunca promocionar `.tmp` a `.save` (si falta `profile.save` pero hay `.tmp` → S0, salvo `.bak` válido → S4 por R8).
- **Si al arrancar existe `suspend.validating`**: aplicar R9(4) — sin marcador `suspend.recovered`: crearlo, re-validar, promover a `save` → S2; con marcador: borrar `validating` + marcador → S1 (o S0/S4/S5 según PER). Nunca auto-rehidratar run sin Continuar.
- **Si PER corrupto pero `.bak` válido**: NO auto-restaurar; permanecer S4 con ambos preservados para diagnóstico. Auto-restore enmascara corrupción y resucita llaves rancias.

**Reintentos y fallos**
- **Si crash con `per_dirty` pendiente (3 reintentos agotados: 0.25/0.50/1.00 s)**: se pierde exactamente el delta en memoria desde el último flush bueno; disco conserva el último bueno; al rearrancar, el delta se da por nunca ocurrido (sin merge ni replay). Irrevocable-en-memoria ≠ durable.
- **Si SUS falla tras 3 reintentos en punto seguro**: la run continúa sin red; reintentar en cada punto seguro. Si cierre/abandono/muerte antes de un flush SUS válido → run perdida (equivale a S3→S1). Nunca bloquear el avance por fallo SUS.
- **Si `n=3` falla**: abortar commit, conservar save bueno, `per_dirty`/sin-red + log interno con OS error y fichero; sin popup mid-duelo (el motivo persiste para Menú en S1/S2).
- **Si falla serialización en memoria**: abortar sin tocar disco y sin marcar `per_dirty` (no es fallo FS).
- **Si `store_*=false` por disco lleno en PER**: 3 reintentos → `per_dirty` + NO escribir SUS ese tick (evita huérfana con ref rancia) + reintentar PER+SUS juntos después. En SUS → sin-red. En SET → memoria + reintento al próximo cambio de ajuste.
- **Si muerte/abandono/fin con `per_dirty`**: reconciliar en memoria e intentar flush en la transición a S1; si falla → S1 con `per_dirty` persistente (reintenta en la próxima ganancia). SUS siempre borrada aunque PER falle.

**Plataforma**
- **Si lectura al arrancar falla por ENOENT**: → S0. Por EACCES/EIO tras 3 reintentos → S4 con código `PROFILE_ILEGIBLE`, sin escribir ni borrar.
- **Si Deck duerme mid-duelo**: al resumir, el sueño acumula 0 de playtime, RNG intacto, duelo continúa sin SUS. En punto seguro con SUS → SUS intacta, `timestamp` ignorado.
- **Si kill -9 antes del rename a `suspend.validating`**: SUS intacta → S2. Tras el rename sin live confirmado y sin marcador → UN intento de recuperación (R9(4)); con marcador o live confirmado → consumida y perdida → S1, PER intacto.
- **Si el usuario duplica `suspend.save` a mano y lo restaura (ref aún coincidente)**: se rehidratará (dupe efectivo). Limitación aceptada y declarada fuera de alcance (R9): sin nonce single-use no se distingue copia de original. Igual para SUS resucitada por Cloud: v1.0 no activa Cloud; si se activa algún día, la exclusión `suspend.*` es requisito bloqueante (ver R9/Open Questions), no mitigación existente.

**Trampa**
- **Si cierre/kill/recarga en `pre_eleccion`**: no hay SUS escribible ni evaluable; al rearrancar, última SUS `post_decision` o run perdida. Suspender pre-commit habilitaría re-elegir por recarga.
- **Si suspender→continuar→suspender sin avanzar**: ofertas/loadout idénticos (semilla+cursor restaurados verbatim); solo avanzar consume RNG y cambia la siguiente SUS. Re-suspender nunca rerollea.
- **Si wall-clock manipulado**: `timestamp` ignorado para validez/orden/playtime (diagnóstico solo). Sin bans ni invalidaciones.
- **Si PER/SUS editado a mano**: validación R8 falla → S4 (PER) o descarte a S1 (SUS); nunca auto-reparar.

**Reset**
- **Si Reset con firma y SUS vigente**: borra PER (+`.bak`, `.bak.<ver>`) + SUS (+`validating`/`recovered`/`invalid`/`tmp`), conserva SET, limpia caché y `per_dirty` → S0 irrevocable, con listado y log de lo borrado.
- **Si Reset con `per_dirty`**: descartar el delta sin flushear → S0, sin recuperación.
- **Si Nueva Cruzada sin firma con SUS vigente, Continuar en S0/S1-sin-SUS/S3/S4/S5, o S3→S2 sin victoria**: transición inválida → bloquear con código para Menú, nunca cargar sin consumo R9 previo.

## Dependencies

| Sistema | Dirección | Dura / Blanda | Naturaleza de la dependencia |
|---|---|---|---|
| #3 Gestión de Run | Bidireccional | Dura | Run expone estado + commit post-decisión; este GDD expone la foto versionada. Sin Run no hay nada que suspender. Provisional (Run sin GDD). |
| #5 Gracia Tres Capas | Este consume | Dura | `gracia_actual`, `corrupcion_actual`, `poso_irreversible` opacos. Sin Gracia la SUS queda incompleta. Provisional. |
| #9 Reliquias | Bidireccional | Dura | Loadout + cambios post-selección; este GDD persiste y devuelve. Provisional. Sujeto a R10 de Combate (magnitudes). |
| #10 Llaves | Este expone (downstream) | Dura | Evento `llave_obtenida(id)` → `llaves_ids`. Llaves no funciona sin este contrato. Provisional. |
| #15 Menú y Flujo | Este expone (downstream) | Dura (práctica) | Fachada normativa §Fachada (códigos + 4 campos + CONSUMIENDO + barrera + `punto_seguro`). Menú jamás lee disco. Contraparte pendiente en #15 (ver Open Questions). |
| #17 Fragmentos | Este consume | Blanda | Evento `fragmento_visto(id)`. Sin fragmentos el sistema opera; el Pilar 4 pierde. Provisional. |
| #21 Accesibilidad | Este posee claves | Blanda | Claves SET con defaults. Mejora, no requisito. |
| #1 Combate | Referencia | Blanda | `angeles_absorbidos` 0–9 (v1.0 efectivo 0–3) coherente con `vida_maxima` y Combate; Gracia (dueña del conteo) confirma al autorarse. Sin acoplamiento operativo. |
| Plataforma (SO/FS) | Este depende | Dura | `user://` (mismo directorio, sin riesgo cross-device por construcción), rename como asunción OS (POSIX rename / reemplazo NTFS — sin garantía Godot, verificar por spike en vehículo de ship incl. Proton), cadena de verificación R6, sin `fsync` garantizado. |

**Consistencia bidireccional pendiente:** al autorar los GDDs de #3, #5, #9, #10, #17 y #15, cada uno debe declarar su back-link (qué consume/expone de Guardado). Anotado en Open Questions; `/consistency-check` lo verificará.

## Tuning Knobs

(Toda espera con reloj inyectable R7; invariante dura `techo ≥ base` validada en carga por R7a — la tabla define rangos de diseño, R7a los rechazos duros):

| Knob | Lanzamiento | Rango seguro | Si muy alto | Si muy bajo | Interacciones |
|---|---|---|---|---|---|
| `base` (retardo_reintento) | 0.25 s | 0.05–1.0 s | Recuperación lenta tras fallo (duele con disco intermitente) | Reintento sobre fallo aún presente (thrashing) | Con `factor`/`techo` define la espera máx. (1.75 s en lanzamiento); todo fuera de hot-path por R4/R7 |
| `factor` (retardo_reintento) | 2.0 | 1.0–4.0 | El 3er intento espera mucho (manda `techo`) | 1.0 = reintento fijo, válido sin cambiar la regla | — |
| `techo` (retardo_reintento) | 2.0 s | ≥ `base`, ≤ 5.0 s | Retorno lento al punto seguro | Por debajo de `base` = inválido | Debe cumplir `techo ≥ base` siempre |
| `delta_max` (playtime) | 0.10 s | 0.05–0.25 s | Hitches inflan playtime | Frames legítimos largos se recortan | Ninguna: ninguna mecánica depende de playtime (R9 lo excluye de la identidad) — knob cosmético/stats |

**No-knobs (fijados por regla o engine, no tuneables):** 3 reintentos (R7/R7a), INT64_MAX (engine, con disclaimer 2⁵³ en JSON), rangos 0–8 (coro) / 0–9 (ángeles, v1.0 efectivo 0–3) / 0–2 / 0–1 (contrato), tipos JSON-safe, puntos de autosave (R4/R5), semántica de consumo por diario (R9).
**Cross-ref:** ninguna dependencia existe aún para duplicar knobs; cuando Gracia/Reliquias fijen techos, este GDD los transporta opacos sin re-declararlos.

## Visual/Audio Requirements

Explícitamente ninguno por diseño: el autosave es silencioso e invisible (Player Fantasy — ningún "¡Progreso guardado!", ninguna celebración). Los únicos feedbacks de este sistema son textuales y los posee el Menú (motivos de Continuar deshabilitado, indicador sin-red, pantallas S4/S5) — ver UI Requirements. Sin eventos VFX/SFX propios, sin Asset Spec derivado.

## UI Requirements

El Menú (#15) presenta estos estados; este GDD fija qué información, dónde y cuándo. Navegación completa por mando; legible en Deck 7". Los literales en español entre comillas son placeholder pendientes de `/localize` — lo normativo son los CÓDIGOS (§Fachada); #15 posee las claves `MENU_*`, `/localize` los literales.

| Información | Ubicación | Frecuencia | Condición |
|---|---|---|---|
| Señal segura quiescente (cue persistente de Hub: es seguro apagar) | Hub (presentación owned por #15/HUD) | Siempre visible en punto seguro | `punto_seguro == true`; nunca en `pre_eleccion` ni duelo; nunca toast/celebración |
| Continuar habilitado + punto (coro siguiente, playtime en `floor()`) | Menú principal (formato/ellipsis owned por #15) | Al mostrar menú | S2 con SUS válida; `timestamp` nunca se renderiza |
| Continuar deshabilitado + código exacto | Menú principal (`status_line`, una línea, owned por #15) | Al mostrar menú | S0/S1-vírgen (`NO_SUSPEND`) · S1-post-duelo/S3 (`DUEL_NO_WAIT`) · S4 (`PROFILE_CORRUPTO`/`ILEGIBLE`/`FUTURO` según causa) · S5 (`SUS_VERSION_OLD`) · post-consumo (`SUS_CONSUMED`, transitorio) · ref mismatch (`SUS_FOREIGN_REF`) · crash-durante-carga-recuperada (`SUS_RECOVERED`) · SUS descartada por versión (`SUS_VERSION_DISCARD`) |
| Continuar consume la suspensión (feedforward) | Menú principal, junto a Continuar | Antes del primer uso y siempre visible | S2: el jugador debe saberlo *antes* de pulsar, no después de perder |
| Indicador sin-red (`estado_red`: `per_dirty` + código, jamás texto OS) | Status area de MenuPrincipal + zona segura de Hub (placement owned por #15) | Mientras `per_dirty` | Fallo PER con reintentos agotados; nunca popup mid-duelo; icono + texto, nunca solo color |
| Aviso de sección SET reseteada (no-modal, persistente, una acción de restauración) | MenuPrincipal + Ajustes (placement owned por #15, política por #21) | Tras reset de sección | Cualquier sección caída a defaults |
| Firma destructiva Nueva Cruzada | Modal overlay (foco en opción segura) | Al intentar con SUS vigente | S2 (Nueva con firma = S2→S3 atómica) |
| Firma Tipo-A Reset + listado (detalle_perdida fresco al armar) | Modal overlay (foco en opción segura) | Al intentar Reset | Cualquier estado; soltar/cancelar/kill a mitad ≡ cancelar |
| Pantalla Migrar / Reset (avisa: migrar conserva llaves/fragmentos, pierde la run suspendida) | Flujo S5 | Al detectar PER viejo | S5; sin Continuar hasta migrar |
| Diagnóstico S4 por causa (checksum vs ilegible vs futuro vs `.bak`-disponible) + salidas Reset / restore consentido | Flujo S4 | Al detectar PER inválido/ilegible/futuro o save-ausente-con-`.bak` | S4; Continuar oculto; jamás auto-sobrescribir ni auto-restaurar |

## Acceptance Criteria

Criterios verificables por QA sin leer el GDD. `A` = automatizable (gdUnit4/CI), `M` = manual (Deck, kill, hardware). Cobertura Rev 2: un fixture por AC (IDs con sufijo), ≥1 por regla R1–R12 + R7a, ≥1 por fórmula, + cross-system. Seams normativas: fachada FS inyectable (`SaveIo` — FS real solo en `tests/integration/`, doble en memoria en unit) + `Clock` inyectable (R7); sin ellas ningún `[A]` con E/S es válido. `BLOQUEADO en X` = no ejecutable hasta que X exista (no se salta: se filtra en CI).

**Núcleo (R1–R12 + R7a)**
- **AC-R1-01a [A]: GIVEN** S1 + SUS+SET válidos, **WHEN** `profile.save` truncado al 50% + arranque, **THEN** S4 con código, hash intacto, SUS+SET cargan, `SaveIoSpy.writes==0`.
- **AC-R1-01b [A]: GIVEN** idem, **WHEN** `suspend.save` con llave JSON alterada + arranque, **THEN** S1 con descarte, PER+SET OK.
- **AC-R1-01c [A]: GIVEN** idem, **WHEN** sección de `settings.save` con tipo alterado + arranque, **THEN** S1 con esa sección en defaults + aviso, resto byte-igual, `writes==0` en el frame de arranque.
- **AC-R1-02a [A]:** gate estático CI — `FileAccess|DirAccess|ConfigFile` solo en `save_io.gd`/`user_settings.gd`. Bloquea todos los ACs FS.
- **AC-R1-02b [A]: GIVEN** S1 cacheado, **WHEN** 100× `get_profile()`, **THEN** `SaveIoSpy.reads==1`.
- **AC-R2-01a [A]: GIVEN** commit post-victoria, **WHEN** leer `profile.save`, **THEN** set de claves exactamente `{save_format_version,llaves_ids,fragmentos_ids,flags_desbloqueo_meta,estadisticas_acumuladas,run_uuid,per_checksum_ref}` (+`game_version` informativa), `llaves_ids` sin duplicados.
- **AC-R2-01b..f [A]: GIVEN** PER válido, **WHEN** inyectar una de `{loadout_reliquias_ids, gracia_actual, hp/estado-duelo, semilla_rng, version_contenido_run}` + commit, **THEN** aborta, hash intacto, `per_dirty==false`, log nombra la clave. (Una por familia.)
- **AC-R3-01a [A]: GIVEN** fixture S2 (lista de 18 claves R3 pineada en el test), **WHEN** `take_snapshot()` + mutar todos los objetos fuente + serializar dos veces, **THEN** ambos bytes idénticos, snapshot ≠ fuente (copia profunda), todo JSON-safe con round-trip.
- **AC-R3-01b [A]: GIVEN** snapshot + cada familia prohibida `{timers-combate, ajustes, acumulados, llaves}` inyectada, **WHEN** commit, **THEN** aborta (patrón R6-01b).
- **AC-R4-01a [A]: GIVEN** duelo sin `LLAVE_X` (reloj fake t0), **WHEN** `llave_obtenida` + assert memoria-inmediata pre-flush + `writes==0` + muerte + reboot, **THEN** PER contiene X, S1, sin SUS, muerte reconciliada.
- **AC-R4-01b [A]: GIVEN** 3 ganancias pre-punto-seguro, **WHEN** commit del punto, **THEN** `per_writes==1` (coalescado).
- **AC-R4-02a [A]: GIVEN** escena de duelo 60 s @60fps headless + 10 eventos, **WHEN** medir, **THEN** `sync_writes_en_hilo_gameplay==0` (spy con thread-id).
- **AC-R4-02b [M]:** protocolo Deck con marcadores `save_*`, 3×60 s; p95 del delta-de-frame atribuible <1 ms y cero frames +1 ms vs baseline.
- **AC-R5-01a [A]: GIVEN** S3, **WHEN** `request_suspend()` ×3 ticks, **THEN** cero ficheros `suspend.*` creados, fachada de pausa == `[Abandonar]`.
- **AC-R5-01b [A]: GIVEN** S2-`pre_eleccion` con SUS previa hash H, **WHEN** `request_suspend()`, **THEN** sin SUS nueva, reboot → resume en último `post_decision` o S1, nunca la elección pre-commit.
- **AC-R5-01c [A]: GIVEN** S2, **WHEN** invalidación pre-duelo con FS-fail inyectado, **THEN** duelo no instanciado + diagnóstico (fail-closed R5).
- **AC-R6-01a [A]: GIVEN** PER+SUS dirty en punto seguro, **WHEN** commit OK, **THEN** secuencia spy `[per.tmp.write, per.reread, per.rename, sus.tmp.write, sus.reread, sus.rename]`, `.bak` preservado, `per_checksum_ref` fresco (≠ rancio).
- **AC-R6-01b [A]: GIVEN** idem, **WHEN** `profile.tmp` corrompido pre-relectura, **THEN** aborta, `.save` intacto, `sus.writes==0`.
- **AC-R6-02 [A]: GIVEN** snapshot con tipo prohibido o NaN/Inf, **WHEN** commit, **THEN** el validador pre-`stringify` aborta sin `.tmp`, sin tocar `.save`/`.bak`, sin `per_dirty`, con log de la clave.
- **AC-R6-03 [A]: GIVEN** commit, **WHEN** `SaveIo.store_string#2 → false` (seam nombrado), **THEN** aborta, save bueno conservado, `.tmp` eliminado, `per_dirty==true` (fallo FS — distinto de R6-02: `per_dirty==false`).
- **AC-R7-01a [A]: GIVEN** FS-fail inyectado, **WHEN** commit (reloj fake), **THEN** `attempts==4`, `sleeps==[0.25,0.50,1.00]`, todo fuera del hilo de gameplay.
- **AC-R7-01b [A — BLOQUEADO en sidecar `save_health.json` + ADR formato]:** PER-agotado → `per_dirty==true` + código legible en S1/S2; SUS-agotada → sin-red sin bloquear avance, retry en próximo punto.
- **AC-R7-01c [A]: GIVEN** duelo + PER-fail, **WHEN** 5 s, **THEN** `PopupSpy.count==0`.
- **AC-R7-02 [A]: GIVEN** `.tmp` huérfanos + `.invalid` residual, **WHEN** arrancar, **THEN** borrados/ignorados pre-validación con log, nunca promocionan.
- **AC-R8-01a..f [A]:** seis fixtures → `{S0, S1/S2, S4-preservado, S5-sin-Continuar, S4-sin-ruta-solo-reset-documentado, S4-futuro-sin-parsear-hash-intacto}`; sub-asserts de IDs con tag `stub-catalog` hasta entrega de catálogos.
- **AC-R8-01g [M]:** protocolo EACCES real (PC+Deck): S4 ilegible, ventana 60 s con `writes==0`, sin borrado.
- **AC-R9-01a [A]: GIVEN** S2, **WHEN** `continuar()`, **THEN** orden spy `rename(save→validating) < instantiate_run`, rehidratación igual-por-comparador (epsilon 1e-9, excluye timestamp/playtime), `validating` borrado en `run_viva_visible`.
- **AC-R9-01b [A]: WHEN** `continuar()` secuencial de nuevo, **THEN** no-op, código `SUS_CONSUMED`, `instantiations==1`, botón deshabilitado.
- **AC-R9-01c [M]:** harness SIGKILL post-rename + relanzar → S1, PER intacto, sin rehidratación.
- **AC-R9-01d [M]:** doble-press mismo-tick dos dispositivos (o diferir a Menú M11 — un solo dueño).
- **AC-R9-01e [A]: GIVEN** `suspend.validating` residual sin `save`, **WHEN** arranque sin marcador, **THEN** UN intento de recuperación → S2; con marcador `suspend.recovered` → borrado → S1, nunca rehidratación directa.
- **AC-R9-02 [A]:** tabla exacta de N filas (coro 9; coro 5 en build v1.0; ángeles 9 = válido-borde (aceptar) + ángeles 10 = descarte + ángeles 4–8 en build v1.0 = descarte; decisión 2; longitudes; intersección; id-desconocido; playtime∈{−1,NaN,Inf}→REPARAR no descartar; gracia∈{−1,NaN,Inf}; poso −1; cursor∈{−1,1.5,"x"}; punto∈{pre_eleccion,"",mid_duelo}; ref∈{ausente,tipo-erróneo,mismatch}; `save_format_version` futura; `version_contenido_run`≠actual) → descarte→S1 + código por fila; MÁS dos filas positivas: `timestamp` basura → aceptado-ignorado; `extras_run{unknown:1}` → aceptado con round-trip.
- **AC-R9-03 [A — BLOQUEADO en comparador oficial run-suspendida-vs-rehidratada]:** interim campo-a-campo (epsilon 1e-9, excluye timestamp/playtime/SUS); avanzar RNG cambia `posicion_rng`; re-suspender conserva `semilla_rng` (nunca rerollea).
- **AC-R10-01a..d [A]:** muerte (S3) / abandono-seguro (S2) / abandono-duelo (S3) / fin → SUS borrada + PER reconciliado → S1; llaves/fragmentos jamás revertidos; post-muerte `continuar()` deshabilitado con código.
- **AC-R10-01e [A]: GIVEN** `per_dirty` + PER-fail inyectado al morir, **WHEN** muerte, **THEN** S1 con `per_dirty` conservado, SUS igualmente borrada.
- **AC-R11-01 [partido]:** (a) PER-futura → S4, hash+mtime intactos, `parse_calls==0`; (b) SUS-futura → descarte, `bak_creates==0`, cero copias; (c) PER-N-1 → BLOQUEADO hasta artefacto + entrada de migración (luego S5→migrar→`.bak.<ver>`+validar→S1 + SUS vieja borrada); (d) PER-sin-ruta → S4 + reset documentado; (e) SUS-vieja → descarte-sin-migrar; (f) SET-sección-rota → defaults + resto + aviso (reescritura diferida, `writes==0` en frame de arranque).
- **AC-R11-02 [A]: GIVEN** PER corrupto + `.bak` válido, **WHEN** arrancar, **THEN** S4, ambos preservados, 0 auto-restore en ventana 60 s.
- **AC-R11-03 [A]: GIVEN** S4 con `.bak` íntegro, **WHEN** restore consentido, **THEN** S1 con `.bak` verificado + log; jamás automático.
- **AC-R12-01a [A]:** sin firma (soltar antes del hold / cancelar / kill a mitad) → cero borrados (hashes iguales), nada persiste.
- **AC-R12-01b [A]:** con firma (hold completo) desde S2/S4/S5 → borra `{profile.save,.bak,.bak.<ver>,suspend.save,validating,recovered,invalid,tmp}`, SET byte-igual, caché limpia → S0; el listado regenera `detalle_perdida` fresco al armar.
- **AC-R12-01c [A]:** con firma + `per_dirty` → delta descartado, `writes==0` de flush PER.

**Fórmulas (una familia por fórmula, un fixture por AC)**
- **AC-F1a [A]:** tabla n=1,2,3 → [0.25,0.50,1.00], clamp a techo, casos factor=1.0 y techo==base.
- **AC-F1b [A]:** n=3-falla → aborta+conserva+dirty.
- **AC-F1c [A]:** config techo<base → rechazo en carga (R7a).
- **AC-F1d [A]:** spy sin wall-clock (reloj inyectable).
- **AC-F2a [A]:** 1234.50+60×0.0167=1235.502, epsilon=1e-6 declarado.
- **AC-F2b [A]:** deltas {−1→0, 5.0→0.10, NaN→0, Inf→0.10}.
- **AC-F2c [M]:** Deck sleep-resume → +0 (regla en fórmula, cross-ref Menú M13). `floor()` en UI → owned Menú.
- **AC-F3a [A]:** (41,+1)→42, (MAX,+1)→MAX, (0,−5)→0-defensivo, spy sin wrap.
- **AC-F3b [BLOQUEADO en ADR canonicalización]:** round-trip JSON de INT64_MAX.
- **AC-F4 [A]** (catálogo stub `{LLAVE_01..03}` pineado, gate de re-pin al entregar reales): repetido→no-op (`writes==0,dirty==false`), nuevo→append-con-orden, desconocido→ignorado-sin-escribir, vacío→no-op.
- **AC-F5 [A]:** re-emisión→sin cambio, nuevo→append-ordenado, fichero-con-`[A,A]`→rechazo-o-dedup (una sola); cláusula Reset eliminada (→R12).

**Cross-system**
- **AC-I1 [A]:** doble `llave_obtenida` → un solo id; Llaves posee catálogo, este GDD el cuándo (stub hoy, gate re-pin).
- **AC-I2 [A]:** foto Run round-trip idéntica (`run_uuid` incluido); sin Run no hay SUS (mock hoy).
- **AC-I3a [A]:** gracia/corrupción/poso round-trip opaco con epsilon 1e-9. Monotonicidad del poso → gate del GDD de Gracia (no testeable aquí).
- **AC-I4 [A]:** loadout ordenado restaurado idéntico; magnitudes Combate R10 → transporte opaco (gate Reliquias).
- **AC-I5 [A]:** evento fragmento → PER extremo a extremo (stub hoy).
- **AC-I6 [A]:** matriz S0–S5 → `Continuar/Nueva/Migrar/Reset` + código exacto cada uno (tabla explícita de pares prohibidos: S3→Continuar, Muerte→Continuar, S0/S4/S5→Continuar, pre-`run_viva_visible`→jugar); "Menú jamás lee disco" → owned Menú M8 (aquí solo fachada).
- **AC-I7:** → AC-R11-01f (sin duplicar).
- **AC-T1 [M-only; BLOQUEADO en decisión de lock]:** protocolo dos-procesos (PC+Deck): B mismo `user://` → aborta pre-escritura con `PROFILE_LOCKED`, A intacto, watcher (`writes_B==0`, sin `validating` creado); lockfile cooperativo con staleness por timeout. Sin mitad `[A]` hasta primitiva OS nombrada.

**Presupuesto de performance (bloqueante; CI = estático+muestreado, Deck = manual con harness nombrado)**
- **PERF-01a [A]:** estático — 0 IO directo fuera de `SaveIo`/`UserSettings` (gate R1-02a).
- **PERF-01b [A]:** spy muestreado 60 s @60fps con thread-id — 0 llamadas FS en hilo de gameplay (ventana: desde duel-instantiated hasta duel-resolved, excluye el rename de invalidación previo).
- **PERF-01c [M]:** 5 min Deck.
- **PERF-02a [A, PC, n=50]:** commit punto-seguro happy-path p95 <100 ms.
- **PERF-02b [A, reloj fake]:** presupuesto retry-stall con prueba de no-bloqueo por diferimiento (máx 1.75 s sin bloquear avance).
- **PERF-02c [M, Deck, n=30]:** p95 <200 ms.
- **PERF-03:** fixture peor-caso (catálogo lleno, 8 derrotados, loadout máx, `extras_run` máx) + bytes-en-disco vía stat OS: `profile.save` ≤64 KB, `suspend.save` ≤128 KB, `settings.save` ≤16 KB; al llegar catálogos, umbrales como fórmula base+N*por-entrada (el crecimiento re-abre aprobación).
- **PERF-04:** alcance validación-only (paint excluido), n=20 Deck p95 <500 ms; CI smoke PC como tripwire (no prueba); N-1 BLOQUEADO.
- **PERF-05 [M-only]:** protocolo Deck con markers `save_*`, ventana de parry importada de Combate; hitch = delta-frame >5 ms con marker dentro.

## Open Questions

| Pregunta | Dueño | Deadline | Resolución |
|---|---|---|---|
| Catálogos e IDs (llaves, fragmentos, reliquias, representantes) + invariantes exactas | #3 Run / #9 / #10 / #17 | Al autorar cada GDD | Contrato provisional R3 hasta entonces |
| Rangos/techos de `gracia_actual`, `corrupcion_actual`, `poso_irreversible` para el validador SUS | #5 Gracia | Al autorar Gracia | ✅ Cerrada 2026-09-04: techo=100, `poso∈{0,12,24,36}` monótono (F-T1/F-P1 Gracia, registry v12); AC-R9-02 ya cubre `poso −1`/NaN; el decrease relativo (cargado<memoria, ambos ≥0) lo chequea Gracia en carga (GX-04), no el validador estático |
| Coste no-nulo de corrupción (R9b del sistema 1) | #5 Gracia | Al autorar Gracia | Exigencia emitida desde este GDD |
| Política de bump de `version_contenido_run` | #3 Run | Al autorar Run | — |
| Artefactos de migración N-1 (`profile.save` viejo real + entrada de tabla) | QA + este GDD | Pre-producción | GAP-09: S5→S1 no falsable hasta adjuntarlos |
| Comparador oficial run-suspendida-vs-rehidratada | QA | Pre-producción | Sin él, AC-R9-03 parcial |
| Ruta/formato del log interno + código de motivo R7 | Arquitectura | `/create-architecture` | GAP-10 parcial: motivo persistido ya exigido |
| Algoritmo checksum + canonicalización JSON locale-invariante | Arquitectura/QA | `/create-architecture` | Decidido en Rev 2 (SHA-256 sobre JSON canónico, checksum auto-excluido — ver R6); ADR pendiente de confirmación, no de invención |
| Seams FS (`SaveIo`) + `Clock` inyectables como norma | Arquitectura | `/create-architecture` | Sin ellas ningún AC `[A]` con E/S es válido; FS real solo en `tests/integration/` |
| Protocolo lockfile segunda-instancia + staleness | Arquitectura/Diseño | `/create-architecture` | Best-effort cooperativo; AC-T1 degradado a [M-only] hasta primitiva nombrada |
| Contraparte Menú: consumir fachada (4 campos + CONSUMIENDO + barrera + señal segura) | #15 Menú | Al revisar Menú Rev 2 | Este GDD ya publica §Fachada; #15 debe declarar consumo + `MENU_*` + placement |
| Configuración de exclusión Cloud (`suspend.*`, `*.tmp`, `validating`, `recovered`, `invalid`) | Release/QA | Solo si Cloud se activa (v1.0: no activo) | Re-etiquetado Rev 2: no es mitigación existente (Godot no tiene setting); si Cloud se activa, exclusión = bloqueante, no post-1.0 |
| Back-links en GDDs futuros (#3, #5, #9, #10, #17, #15) | Cada autoría | Al autorar cada GDD | Verificará `/consistency-check` |
| Textos/motivos exactos de Menú | #15 Menú + UX | `/ux-design` del menú | Este GDD posee CÓDIGOS (§Fachada); #15 las claves `MENU_*`; `/localize` los literales. Ver 📌 UX Flag bajo UI Requirements |
| Steam Cloud / multi-dispositivo (alcance, conflictos last-write-wins) | Diseño | Post-v1.0 | Explícitamente fuera de v1.0; ganchos `run_uuid`+refs ya dejados |
| Dupe manual/Cloud como limitación documentada permanente | Diseño | Cierre de Alpha | Aceptada fuera de alcance R9; no admite criterio pass/fail |

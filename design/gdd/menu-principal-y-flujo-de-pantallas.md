# Menú Principal y Flujo de Pantallas

> **Status**: In Design (Rev2 — post `/design-review` 2026-09-04, veredicto **MAJOR REVISION NEEDED**; esta versión cierra los 24 bloqueantes)
> **Creative Director Review (CD-GDD-ALIGN)**: APPROVED 2026-09-03
> **Author**: [user + agents]
> **Last Updated**: 2026-09-04
> **Implements Pillar**: Presentación — primera impresión Tinta y Vitral (Pilar 5, belleza sobria) y continuidad del duelo (Pilar 4, "la novena continúa"); superficie de Guardado (S0–S5), Run y Hub

## Overview

El Menú Principal y Flujo de Pantallas es la superficie de presentación y navegación de NOVENA: primera impresión sobria de Tinta y Vitral que lleva del arranque (boot directo, sin logos intermedios bloqueantes) a Comenzar la novena / Continuar / Ajustes en segundos y con mando desde el primer frame útil, y el esqueleto de destinos que sostiene hub, duelo, decisión absorber/rechazar, reliquias y finales. No posee progreso ni gameplay: consume los estados S0–S5 de Guardado sin leer disco jamás y obedece sus vetos (sin Continuar en duelo, sin re-elegir por recarga, Comenzar con suspensión vigente solo con firma destructiva), de modo que el coste de interrumpir es honesto y dual: en punto seguro cuesta como máximo la suspensión vigente más el delta sin flushear; en duelo no hay red por diseño y la run se pierde. Ninguna decisión irreversible puede revertirse navegando. Alcance A (flujo completo): arranque, menú, hub, duelo, pausa, muerte/fin y reset/migración.

## Player Fantasy

El jugador debe sentir que la cruzada lo estaba esperando, no que el juego arranca de cero: del boot al menú hay un umbral ceremonial breve (tinta, título, penumbra — la vela queda reservada al hub), y de ahí a la run sin fricción ni tutoriales de navegación — todo alcanzable por mando, todo legible en la pantalla de 7" de Deck. Nada celebra el progreso ("¡guardado!") y nada permite deshacer lo irreversible: Continuar reaparece exactamente donde la novena se detuvo (con subtítulo de coro y tiempo que lo demuestra), Comenzar advierte lo que destruye, y lo perdido en duelo se nombra con sobriedad ("lo perdido en combate no se retoma"). Con una excepción honesta: en duelo no hay red — entrar a duelo invalida la suspensión y el Hub lo dice en voz alta antes de cruzar. Sirve al Pilar 5 (lo celestial, bello y serio desde el primer frame) y al Pilar 4 (la familia y la continuidad por encima del espectáculo): el menú es vigilia, no escaparate.

## Detailed Design

### Core Rules

1. **Boot directo.** Del ejecutable al menú interactivo sin pantallas intermedias bloqueantes. El splash es un overlay in-game (título + tinta sobre penumbra, **sin vela**: la única vela no-divina del juego vive en el hub), auto-avanza en ≤2.0 s y solo lo saltan pulsos discretos (regla R6-INPUT). El engine-splash se desactiva por configuración (→ ADR de arranque). El foco inicial de mando se fija **tras** descartar el splash; ningún input de skip activa el menú (ver R6-INPUT). Sin `profile.save` → S0: solo Comenzar la novena / Ajustes.
2. **Conjunto cerrado de destinos (escenas, overlays, fases).** Taxonomía normativa:
   - **Escenas top-level**: `MenuPrincipal`, `Hub`, `Duelo`, `Muerte`, `Fin`.
   - **Overlays** (CanvasLayer sobre la escena viva, nunca `change_scene`): `Pausa` (solo duelo), `Ajustes`, `Modal de firma`, `Splash`.
   - **Fases** (no escenas): `Arranque` (carga PER + resumen S2 antes del primer frame).
   - **Enrutadas ajenas** (propias de sus sistemas; este GDD solo las enruta): `Reliquias` (#14), `Decisión Absorber/Rechazar` (#5 Gracia).
   - **Paneles** (estados de `MenuPrincipal`, no escenas): `Reset` (S4/S5), `Migración` (S5).
   - Flujo: `Arranque → MenuPrincipal → Hub → Duelo → {Pausa(overlay), Muerte, Fin} → MenuPrincipal`, con rama `Victoria → Reliquias → Decisión → Hub` y paneles `Reset/Migración` en S4/S5. Un único router posee `change_scene` (→ ADR; `rg change_scene` fuera del router = 0). Ningún sistema añade destinos top-level sin revisar este GDD. Toda transición **voluntaria** no listada es inválida; las involuntarias (kill, sleep) se listan aparte en Edge Cases.
3. **El menú no lee disco jamás.** Toda disponibilidad (Continuar/Comenzar/Migrar/Reset + motivos) y todo dato mostrado (subtítulo de Continuar, listados de firma, indicador de red) vienen de la fachada de Guardado (S0–S5 + resumen display-safe). S2 en display: `resumen_continuar {coro_label, playtime_floor_s, punto_seguro_id}` + `detalle_perdida` + `estado_red {per_dirty, motivo}` + `ultimo_motivo_sin_continuar` (código; S1-post-duelo ≠ S1-virgen ≠ S1-ref-mismatch) + estado `CONSUMIENDO`. Guardado valida eager en boot para el resumen; **revalida al consumir** (R9 Guardado). Si la SUS falla al pulsar Continuar: descarte sin resurrección → S1 con motivo keyed (`MENU_REASON_*`). S0: solo Comenzar / Ajustes. S1: Continuar visible-deshabilitado con motivo. S2: Continuar habilitado + Comenzar siempre con firma. S3: sin Continuar; en pausa de duelo solo Reanudar/Abandonar/Ajustes. S4: panel Reset/Restaurar/diagnóstico. S5: panel Migrar/Reset.
4. **Firma destructiva (hold, no doble diálogo).** Toda transición que destruye run o suspensión —Comenzar con SUS vigente, Abandonar (duelo y Hub), Reset, Restaurar .bak, Migración— exige **firma Tipo-A**: mantener 1 s (`firma_hold_ms`, default 1000 ms) sobre el botón destructivo + listado que nombra la pérdida (coro_siguiente, nº+ids de reliquias, gracia_actual, corrupcion_actual) y lo conservado (N llaves, M fragmentos). Flanco fresco obligatorio (soltar+pulsar; un input heredado jamás firma). Foco inicial siempre en la opción segura. Soltar antes del hold, cancelar o kill a mitad = SUS byte-idéntica (nada se borra antes del commit). La invariante "exactamente 2 pasos" queda derogada.
5. **Pausa y muerte enrutan, no resucitan.** Pausa **solo en duelo** (overlay): Reanudar (con reanudación segura: timers congelados visibles + gracia breve de input; la forma exacta —countdown o gracia— la posee Combate y se referencia aquí) / Abandonar (firma R4: renuncia total, solo PER) / Ajustes (overlay encima, retorno al invocador). Sin Continuar ni reintento. Muerte: presentación **muda** (objeto del Hub, sin cita — art bible fila 8 "sin ceremonia"), PER ya reconciliado y SUS borrada antes de mostrar (ya es S1); única salida "Volver al menú". Fin de run (victoria, final, paz): borra SUS, escribe PER, a S1. Presupuesto de reintento: cadena Muerte→MenuPrincipal→Hub→Duelo ≤10 s y ≤6 inputs, a verificar en Deck; si es inviable, excepción documentada con justificación de flow.
6. **Transiciones sobrias con skip cerrado (R6-INPUT).** Corte o fundido corto a negro (overlay ≤300 ms, lanzamiento 200 ms) entre destinos. **Solo lo saltan flancos `pressed` discretos** de `{ui_accept, ui_cancel, click principal}` — nunca motion, ejes analógicos, held, gyro, ni eventos de conexión/sueño. El input que dispara una transición no cuenta como skip. El handler consume el evento (`set_input_as_handled`) + inhibe el destino 1 frame + swallow 200 ms. Firmas y modales exigen flanco fresco. Si `transicion_ms = 0`: corte puro y "skippable" es pass vácuo. Hub→Duelo es asíncrona con velo de carga y presupuesto propio (→ ADR precarga/`load_threaded` + Shader Baker): el skip acorta el velo, **nunca** la carga; el primer telegraph jamás es skippable. Tweens de transición ignoran la escala de tiempo (no se dilatan bajo hitstop). Con reduced-motion: siempre corte (1 frame, sin fade/flash/viñeta animada).
7. **Mando primero, Deck legible.** Navegación completa por gamepad (foco visible **sin brillo** —principio 2 del art bible: solo lo divino emite luz—: borde 2px `#C7CDD6` + marcador de cuneta + peso de etiqueta, nunca glow) y teclado; nada depende de hover (dual-focus del motor: el hover no roba foco de mando). Continuar deshabilitado es **visible-deshabilitado y enfocable**: al enfocar muestra el motivo como etiqueta accesible + `ui_error_bloqueado`. Mapa de foco normativo por estado (ver columna Foco en States): S0/S1→Comenzar, S2→Continuar, S4→Diagnóstico, S5→Migrar, Pausa-duelo→Reanudar, modal firma→opción segura, Muerte→Volver al menú. Trampa y restauración de foco en modales; foco almacenado y re-grab ante desconexión/reconexión (verificar en Deck real). Texto funcional ≥18px a base 1280×800 con escalado proporcional al alto del canvas (piso 18; alcance handheld, docked best-effort). `safe_zone` 5% por borde sobre base 1280×800 (rango 3–7%; bajar de 5% exige reverificación en Deck; mínimo absoluto 3%). Sonidos de UI por el bus de eventos (catálogo cerrado, timbres propiedad de Audio #16), nunca directos.

### States and Transitions

| Destino | Entrada | Salida | Guardia Guardado | Foco inicial |
|---|---|---|---|---|
| Arranque (fase) | Ejecutable | MenuPrincipal (splash overlay encima) | Valida PER eager (S0/S1/S4/S5) + resumen S2 display-safe; SUS se revalida al pedir Continuar | — (se fija tras splash) |
| MenuPrincipal | Arranque, Hub (salir), Muerte/Fin, Abandonar | Comenzar / Continuar / Ajustes(overlay) / Hub / paneles S4–S5 | Opciones según S0–S5 + resumen; sin disco directo | S0/S1→Comenzar · S2→Continuar · S4→Diagnóstico · S5→Migrar |
| Hub | MenuPrincipal (Comenzar/Continuar — Continuar aterriza según `destino_continuar_id`), post-decisión | Entrar a duelo / Salir al menú (→S2, flush prioritario, sin acción) / Abandonar (firma →S1) | Solo puntos seguros; **entrar a Hub reescribe SUS** (commit R6 Guardado); entrar a duelo invalida SUS (rename síncrono) tras aviso de stakes | Entrar a duelo (provisional hasta #18) |
| Duelo | Hub | Pausa(overlay) / Muerte / Victoria (→ Reliquias → Decisión → Hub) | En duelo: sin Continuar, sin SUS nueva, sin guardado manual | n/a |
| Pausa (overlay, duelo-only) | Duelo | Reanudar (safe-resume) / Abandonar (firma) / Ajustes(overlay) | Duelo: sin Continuar ni reintento | Reanudar |
| Ajustes (overlay) | MenuPrincipal (S0–S3), Pausa-duelo | Retorno al invocador con foco restaurado | S4/S5: no editable; SET con flush fuera de duelo (nunca IO síncrono en pausa de duelo) | Primera opción |
| Reliquias (enrutada #14) | Victoria de coro | Decisión | Provisional: sin SUS nueva pre-decisión; commit loadout propiedad de #14 | Lo fija #14 (provisional: opción no-destructiva) |
| Decisión (enrutada #5) | Post-reliquia | Firma irrevocable → Hub | Jamás `pre_eleccion` como punto de suspensión (R5 Guardado) | Lo fija #5 |
| Muerte (muda) | Duelo | Volver al menú → S1 vía MenuPrincipal | PER reconciliado + SUS borrada **antes** de mostrar | Volver al menú (único) |
| Fin | Run completa | → S1 vía MenuPrincipal | Borra SUS, escribe PER | — |
| Reset (panel S4/S5) | S4/S5 | → **S0** (borra PER+SUS, conserva SET, limpia caché+`per_dirty`, log de lo borrado) | Firma R4 + listado; con `per_dirty`: delta descartado sin flushear | Opción segura (Diagnóstico visible) |
| Restaurar .bak (panel S4) | S4 con `.bak` íntegro | → **S1** (checksum verificado pre-restore, log registrado; jamás automático) | Firma R4 + listado (qué se recupera, qué se pierde); sin `.bak` íntegro la opción no existe | Opción segura (Diagnóstico visible) |
| Migración (panel S5) | S5 | OK → S1 (backup + SUS vieja descartada) / sin ruta o fallo → S4 | Firma R4 (descarta SUS vieja); SUS vieja nunca migra | Migrar |

Transiciones voluntarias no listadas: inválidas. Entrar a Hub solo vía `post-decisión` o Continuar (jamás directo `post-reliquia`: sería re-elegir por recarga). Cerrar en duelo = run perdida por diseño (→S1 con motivo); en punto seguro = resume único (→S2). Kill a mitad de firma ≡ cancelar. Sleep en duelo ⇒ auto-pausa (nunca resume directo; primer delta post-resume se descarta, playtime +0, RNG intacto); sleep en modal ⇒ modal preservado con foco. Kill mid-migración ⇒ S4 preservado.

### Interactions with Other Systems

| Sistema | Dirección | Interfaz (qué fluye, quién posee qué) |
|---|---|---|
| #12 Guardado de Progreso | Este consume de Guardado | Estados S0–S5 + `resumen_continuar` + `detalle_perdida` + `estado_red` + `ultimo_motivo_sin_continuar` + `destino_continuar_id` (aterrizaje de Continuar: Hub\|Reliquias) + `CONSUMIENDO` con motivos `MENU_REASON_*` (mapeo abajo). Guardado posee ficheros, validación, consumo y borrado; este GDD posee qué opción se muestra, el subtítulo y la firma. Este GDD **no lee disco jamás**. Simétrico al contrato declarado en Guardado (`#15 Menú y Flujo`). |
| #3 Gestión de Run | Bidireccional (contrato provisional) | Menú emite intenciones tipadas `iniciar_run {origen}` / `continuar_run {}` / `abandonar_run {contexto}` (dedupe por tick: doble intención mismo frame = una); Run posee semántica (representantes, semillas, puntos seguros) y confirma `run_viva_visible {run_uuid, coro_idx}` con timeout y ruta de rechazo (pantalla+motivo keyed; sin confirmación no hay transición). El listado de firma (pérdida/conservado) lo compone el menú desde el resumen de fachada, nunca de disco. Provisional: Run aún sin GDD. |
| #14 Pantalla de Reliquias | Hermanos (presentación) | Reliquias y Decisión son destinos propios de sus sistemas; este GDD solo enruta (victoria → reliquias → decisión → hub). Provisional. |
| #13 HUD de Combate | Hermanos (presentación) | En duelo manda el HUD (`design/ux/hud.md`); el menú queda oculto salvo Pausa. Flujo de control: Pausa ordena `set_pausa_visual` (HUD atenuado 40%, S oculto, timer pausado — propiedad del HUD). Sin intercambio de estado. |
| #21 Accesibilidad | Este consume de Accesibilidad | Tier, foco visible, reduced-motion (clave provisional `accesibilidad/movimiento_reducido`, default OFF, propiedad de #21), mínimo 18px, sustituto de flash, knob provisional `sonido_ambiente_ui` (bool, default true). Tier aún sin definir (WCAG-AA propuesto). |
| Localización | Este consume | Todas las cadenas por claves (`MENU_*`, inventario y vetos abajo); sin texto hardcodeado. Redacción final: `/localize` con writer. |
| Audio (#16) | Este emite a Audio | Catálogo cerrado de intenciones (timbres, niveles, ducking y lifecycle propiedad de Audio): `ui_foco`, `ui_confirmar_neutro`, `ui_armar_destructivo`, `ui_cometer_irrevocable`, `ui_atras`, `ui_error_bloqueado`, `ui_error_duelo`, `ui_exito_migracion_reset`, `transicion_solicitada`; cama `ui_vela_loop` (Menu+Hub, duckeada en duelo). El menú emite; jamás reproduce directo. Duelo→Muerte: corte <20 ms (handoff). Provisional hasta GDD #16. |

### Claves `MENU_*` y vetos léxicos (provisional; fija `/localize`)

Vetos normativos: **`corrupción/corrupto` reservado a la ficción** (Pilar 1; jamás para fallos técnicos) · **ningún motivo usa "duelo"** (homónimo duelo-combate/duelo-luto, intraducible) · **cero tecnicismos en superficie** (sin "suspensión", "perfil", "versión", "diagnóstico", "loadout", "run" salvo claves) · todo listado destructivo usa placeholders con nombre (`{coro}`, `{n_reliquias}`, `{gracia}`, `{corrupcion}`, `{n_llaves}`, `{n_fragmentos}`) · ningún diálogo supera 120 caracteres tras interpolación.

| Clave | Provisional es-MX (fija `/localize`) |
|---|---|
| `MENU_REASON_NO_SUSPEND` | "todavía no hay dónde retomar" |
| `MENU_REASON_RUN_LOST` | "lo perdido en combate no se retoma" |
| `MENU_REASON_MEMORY_DAMAGED` | "el registro guardado está dañado" |
| `MENU_REASON_OLD_VERSION` | "esta memoria es de otra versión" |
| `MENU_REASON_ALREADY_USED` | "esta suspensión ya se usó" |
| `MENU_REASON_OTHER_RUN` | "esta suspensión es de otra cruzada" |
| `MENU_REASON_IN_USE` | "esta memoria ya tiene una cruzada abierta" |
| `MENU_REASON_UNREADABLE` | "no se puede leer el registro" |
| `MENU_REASON_RECOVERED` | "la novena se recuperó de un corte" |
| `MENU_REASON_VERSION_DISCARD` | "esta suspensión caducó con la versión" |
| `MENU_NET_SIN_RED` | "cambios pendientes de guardar" |
| `MENU_HOLD_TITLE` | "Mantén para confirmar · suelta para cancelar" |
| `MENU_HOLD_LOSS` | "Se pierde: {coro}, {n_reliquias} reliquias, gracia {gracia}" |
| `MENU_HOLD_KEPT` | "Se conserva: {n_llaves} llaves, {n_fragmentos} fragmentos" |
| `MENU_HUB_SUS_LINE` | "La novena espera en {coro} · {mm_ss}" |
| `MENU_HUB_STAKES` | "Al entrar, la suspensión se invalida: en duelo no hay red" |

> **Mapeo códigos→claves (normativo; los códigos los posee Guardado §Fachada):** `NO_SUSPEND`→`MENU_REASON_NO_SUSPEND` · `DUEL_NO_WAIT`→`MENU_REASON_RUN_LOST` · `PROFILE_CORRUPTO`→`MENU_REASON_MEMORY_DAMAGED` · `PROFILE_ILEGIBLE`→`MENU_REASON_UNREADABLE` · `PROFILE_FUTURO`→`MENU_REASON_OLD_VERSION` · `SUS_CONSUMED`→`MENU_REASON_ALREADY_USED` · `SUS_FOREIGN_REF`→`MENU_REASON_OTHER_RUN` · `SUS_RECOVERED`→`MENU_REASON_RECOVERED` · `SUS_VERSION_DISCARD`→`MENU_REASON_VERSION_DISCARD` · `SUS_VERSION_OLD`→`MENU_REASON_OLD_VERSION` (con `PROFILE_FUTURO`) · `PROFILE_LOCKED`→`MENU_REASON_IN_USE` **solo en vía de boot-error** (nunca `status_line`) · `PER_DIRTY_*`→`MENU_NET_SIN_RED` (indicador `estado_red`, jamás texto OS).
> **Equivalencia terminológica (normativa):** en docs, «Comenzar (la novena)» ≡ «Nueva Cruzada» — mismo botón y misma transición (Menú posee el rótulo, Guardado la transición). En ACs y matrices vale cualquiera de los dos nombres.

## Formulas

Este sistema, en su rol de esqueleto de navegación, **no posee cantidades matemáticas propias**: no hay balance ni economía que modelar. Todas las cifras que menciona son umbrales de presentación propiedad de este GDD y verificables por cronómetro o inspección (método: n=10 mediciones, p95; en unit con reloj fake):

| Constante | Valor | Qué acota |
|---|---|---|
| `splash_max` | 1.0–2.0 s (default 2.0), auto-dismiss, solo INPUT_SKIP lo salta | Boot directo (R1). Sin "0 desactiva": la ceremonia mínima no es tuneable |
| `transicion_max` | ≤ 300 ms overlay (lanzamiento: 200 ms ≈ 12 frames @60); Hub→Duelo con velo y presupuesto propio (ADR) | Transiciones entre destinos (R6). Si `transicion_ms = 0`: corte puro, "skippable" es pass vácuo |
| `firma_hold_ms` | 800–1500 ms (default 1000) + listado + flanco fresco + foco seguro | Firma destructiva (R4). Deroga la invariante de 2 pasos |
| `safe_zone` | 5% por borde sobre base 1280×800 (rango 3–7%) | Legibilidad Deck (R7). Bajar de 5% exige reverificación en Deck; mínimo absoluto 3% |
| `fuente_min` | ≥ 18px a base 1280×800, escalado proporcional al alto del canvas, piso 18 | Texto funcional en 7" (R7). Diagnósticos obedecen el piso; "discreto" se logra por posición/luminancia, no por tamaño |

Fórmulas y constantes que este sistema **consume sin poseer** (no redefinir aquí): `save_format_version` y estados S0–S5 + resumen (Guardado R8–R12); `hud_opacity/scale` y presupuesto HUD (spec HUD); reanudación segura exacta (Combate); timbres y ducking (Audio #16).

## Edge Cases

| Escenario | Comportamiento esperado | Justificación |
|---|---|---|
| Doble pulsación de Continuar (incl. dos dispositivos mismo tick) | Una sola intención (dedupe por tick); el botón se deshabilita en el mismo frame; el 2º press es no-op con motivo `MENU_REASON_ALREADY_USED`; consume la suspensión (R9 Guardado) | El consumo es por intención durable; sin esta guarda, doble input duplica runs |
| Splash + A-spam | Cero activaciones de menú: el skip se consume, el foco se fija tras el splash, swallow 200 ms | Sin esto el skip firma Continuar/Comenzar con un input inocuo |
| Soltar hold antes de `firma_hold_ms`, cancelar o kill a mitad de firma | SUS byte-idéntica (sha registrado); nada se borra antes del commit | La destrucción ocurre solo en el commit |
| Continuar con SUS inválida al pulsar | Descarte sin resurrección → S1 con motivo keyed exacto (dañada / otra run / ya usada) | R9 Guardado; el resumen display-safe no es validación |
| Cerrar el juego / kill en duelo | Run perdida por diseño; al volver, S1 con motivo `MENU_REASON_RUN_LOST` | Espejo de Guardado S3→S1 |
| Deck dormido en duelo | Auto-pausa; al resumir, Pausa visible (nunca resume directo); 0 playtime, RNG intacto, primer delta descartado | Dormir no es kill; sin SUS, el duelo continúa solo tras pausa explícita |
| Sleep en modal de firma | Modal preservado con foco al resumir | El modal no es S-state; no se pierde ni se confirma solo |
| Cerrar en punto seguro | Resume único desde la SUS vigente (S2); Hub-exit ya pidió flush prioritario | Único resume garantizado del sistema |
| Salir del Hub antes del flush | La transición procede; MenuPrincipal muestra `SINCRONIZANDO`→S2 al confirmar (push de fachada; display owned Menú — distinto del `CONSUMIENDO` de Guardado, reservado a la vía de consumo); `estado_red` visible mientras tanto | Barrera sin bloquear UX; promesa "sin acción requerida" intacta |
| Perfil dañado (S4) | Panel Reset/Restaurar/diagnóstico; Continuar ausente del árbol; jamás auto-sobrescribir ni auto-restaurar (sha vigilado) | Preservar evidencia (R8 Guardado) |
| Versión vieja (S5) | Panel Migrar/Reset; sin Continuar hasta migrar; SUS vieja descartada visiblemente, nunca migra | R11 Guardado |
| Migración sin ruta o fallida | Superficie S4 (Reset/diagnóstico, Continuar oculto) | La salida S5→S4 es visible, no solo backend |
| Ajustes sin perfil (S0) | Permitidos; muta solo `settings.save` (PER/SUS siguen ausentes) | Los ajustes no dependen del progreso |
| Ajustes en S4/S5 | No editable (solo Reset/Migrar/diagnóstico) | R3; evita mutar SET sobre perfil ilegible |
| Mando desconectado en menú | Foco almacenado, fallback a teclado; al reconectar, re-grab al foco almacenado | Navegación sin puntero en ningún caso |
| Reduced-motion activo | Corte 1 frame, sin fades/flashes/viñeta animada; tick seco (timbres: #16) | Coherente con HUD y regla de accesibilidad |
| Primer arranque sin Guardado previo | S0: solo Comenzar / Ajustes; cero pantallas de error | Estado inicial válido, no caso de fallo |
| Comenzar sin SUS (S1) | Cero modales, arranca directo (anti-sobre-confirmación) | La firma solo protege pérdida real |

## Dependencies

- **Guardado de Progreso (#12) — dura.** Sin sus estados S0–S5, resumen y fachada, este flujo no puede decidir qué mostrar. El menú nunca accede a disco.
- **Gestión de Run (#3) — dura al emitir intenciones.** Iniciar/continuar/abandonar solo tienen efecto si Run los confirma (payload, timeout y rechazo pendientes). Provisional (sin GDD).
- **HUD de Combate (#13) — blanda.** Pausa ordena `set_pausa_visual`; fuera de eso no interactúan. Spec en `design/ux/hud.md` (sin GDD aún).
- **Pantalla de Reliquias (#14), Gracia (#5), Fragmentos (#17) — blandas.** Proveen el contenido de los destinos que este flujo enruta; el flujo no depende de sus valores. Llaves (#10, sin GDD) solo vía conteos del resumen.
- **Accesibilidad (#21), Localización, Audio (#16) — blandas.** Tier y knobs, claves `MENU_*` e intenciones de bus; con defaults el flujo opera (salvo timbres, propiedad de #16).

> Todas las referencias a GDDs inexistentes son **contratos declarados por anticipado**. Cuando esos GDDs se autoren, deben declarar la mitad simétrica del contrato.

## Tuning Knobs

| Knob | Rango | Default | Notas |
|---|---|---|---|
| `splash_max` | 1.0–2.0 s | 2.0 s | Siempre presente y skippable (discreto); sin "0 desactiva" |
| `transicion_ms` | 0–300 ms | 200 ms | 0 = corte puro (skip vácuo); reduced-motion fuerza corte; Hub→Duelo excluido (presupuesto propio) |
| `firma_hold_ms` | 800–1500 ms | 1000 ms | Hold de firma destructiva; fuera de rango = inválido |
| `safe_zone` | 3–7% | 5% | Base 1280×800; bajar de 5% exige reverificación Deck; mínimo 3% |
| `fuente_min_px` | ≥ 18 base | 18 | Piso, no techo; escala proporcional al alto del canvas |
| `sonido_ambiente_ui` | bool | true | Provisional, propiedad de #21: cama `ui_vela_loop` on/off |

`firma` (hold + listado + flanco fresco + foco seguro) es invariante, no knob.

## Visual/Audio Requirements

> Sobriedad Tinta y Vitral desde el primer frame (art bible §§1–2): el menú es vigilia, no escaparate. La única luz cálida no divina del juego es la vela del hub; el splash y el menú no la duplican.

| Elemento | Requisito |
|---|---|
| Fondo | Grabado/tinta en penumbra; splash: título + tinta, sin vela |
| Tipografía | Sans geométrica sin serifas; títulos sobrios, sin florituras curvas; ≥18px base |
| Foco | Borde 2px `#C7CDD6` + marcador de cuneta + peso de etiqueta; orden por mapa de foco; nunca glow; nada por hover |
| Transiciones | Corte o fundido a negro ≤300 ms overlay, skip discreto; con reduced-motion siempre corte 1 frame |
| Audio | Intenciones por el bus (catálogo Interactions); cama `ui_vela_loop` en Menu+Hub duckeada en duelo; sin coro divino en menú (el coro pertenece a los ángeles); transición: `transicion_solicitada`, crossfade propiedad de #16; timbres propiedad de #16 |
| Prohibido | Flashes punitivos de luz, arte de jefes como decoración, celebraciones de guardado, tecnicismos en superficie (salvo S4/S5/diagnóstico y Ajustes→Acerca de) |

## UI Requirements

| Información | Dónde | Condición |
|---|---|---|
| Comenzar la novena / Continuar / Ajustes | MenuPrincipal | Siempre; Continuar visible-deshabilitado+enfocable con motivo fuera de S2 |
| Subtítulo de Continuar (`{coro} · {mm_ss}`) + motivo keyed bajo el botón | MenuPrincipal | S2 (subtítulo) / S0/S1/S3/S4/S5 y post-consumo (motivo exacto de 7) |
| Indicador `estado_red` (`per_dirty` + motivo, sobrio) | Status area de MenuPrincipal + zona segura de Hub | Mientras `per_dirty`; nunca popup mid-duelo |
| Línea de estado SUS (`MENU_HUB_SUS_LINE`) | Hub (sobria, persistente) | Punto seguro con SUS vigente |
| Aviso de stakes (`MENU_HUB_STAKES`) | Hub, junto a Entrar a duelo | Siempre (entrar invalida la suspensión) |
| Firma hold + listado (pérdida/conservado, foco seguro, soltar=cancelar) | Modal overlay | Comenzar con SUS, Abandonar (duelo/Hub), Reset, Migración |
| Migrar / Reset / Restaurar .bak + diagnóstico (+ versión de build) | Paneles S4/S5 de MenuPrincipal | Solo S4/S5 (Restaurar solo S4 con `.bak` íntegro) |
| Reanudar / Abandonar / Ajustes | Pausa (duelo-only) | Sin Continuar ni reintento |
| Solo Gracia (alta luminancia) | Decisión absorber/rechazar | Sin Postura/Vida/timer (spec HUD) |
| Etiqueta de memoria activa | Esquina periférica, discreta (posición/luminancia, no tamaño) | Siempre en menú; nunca en duelo; build solo en S4/S5/diagnóstico y Acerca de |
| Muerte muda (objeto del Hub) + "Volver al menú" | Muerte | Muerte en duelo (ya S1) |

## Acceptance Criteria

- [ ] **MENU-01 [A]** — GIVEN `user://` sin `profile.save` ni `suspend.save` (SET defaults, sin `.tmp`/`suspend.validating`/`suspend.recovered`), WHEN boot frío → MenuPrincipal post-splash, THEN exactamente {Comenzar la novena, Ajustes} habilitados; Continuar/Migrar/Reset ausentes del árbol; 0 modales de error en 5 s.
- [ ] **MENU-02a [A]** — GIVEN S2 con SUS válida, WHEN MenuPrincipal visible, THEN Continuar habilitado con subtítulo `{coro} · {mm_ss}` y foco inicial en Continuar.
- [ ] **MENU-02b [A]** — GIVEN S2, WHEN firma sobre Comenzar (hold `firma_hold_ms`), THEN el modal lista los 5 campos (coro, nº+ids reliquias, gracia, corrupción, "se conservan N llaves / M fragmentos"); soltar antes = 0 borrados.
- [ ] **MENU-02c [A]** — GIVEN S2 (sha256 registrado), WHEN cancelar/soltar/kill a mitad de firma, THEN sha256 idéntico y estado S2.
- [ ] **MENU-03 [A]** — GIVEN S1 post-muerte-duelo, WHEN MenuPrincipal visible, THEN Continuar visible-deshabilitado+enfocable con clave `MENU_REASON_RUN_LOST`; snapshot es-MX provisional según tabla de claves.
- [ ] **MENU-04 [A]** — GIVEN duelo en curso, WHEN pausa invocada, THEN exactamente {Reanudar, Abandonar, Ajustes} en ese orden de foco; Continuar y reintento ausentes del árbol.
- [ ] **MENU-05 [A]+[M]** — GIVEN reduced-motion OFF, WHEN cada par {Menu↔Hub, Pausa-duelo↔Duelo, Muerte→Menu}, THEN p95 ≤300 ms (fake clock en unit; Deck real); solo flancos discretos de {ui_accept, ui_cancel, click} saltan (motion/hold/gyro/conexión ignorados; el input que disparó no cuenta). GIVEN reduced-motion ON, THEN corte ≤1 frame, Δ luminancia <5%.
- [ ] **MENU-06 [A-parcial+M]** — GIVEN solo gamepad virtual, WHEN recorrer [Menu S0/S1/S2/S4/S5, Pausa-duelo, Modal firma, Muerte], THEN todo alcanzable en el orden del mapa de foco; foco = borde 2px `#C7CDD6` + marcador, 0 glow; modal atrapa y restaura foco.
- [ ] **MENU-07a [A]** — GIVEN S4 (fixture PER dañado), WHEN MenuPrincipal visible, THEN exactamente {Reset, Restaurar .bak (solo con `.bak` íntegro), Diagnóstico+motivo+versión}; Continuar/Migrar/Comenzar ausentes del árbol (no deshabilitados).
- [ ] **MENU-07b [A]** — GIVEN S4 (sha256 registrado), WHEN 30 s idle + abrir/cerrar diagnóstico, THEN sha256 idéntico, 0 escrituras (espía FS).
- [ ] **MENU-07c [A]** — GIVEN S4 con `.bak` íntegro, WHEN firma sobre Restaurar (hold `firma_hold_ms` + listado), THEN S1 con `.bak` verificado (checksum pre-restore) + log; jamás automático; GIVEN S4 sin `.bak` íntegro, THEN la opción no existe en el árbol.
- [ ] **MENU-08 [A]** — GIVEN fachada mockeada + espía FS que falla ante cualquier `FileAccess/DirAccess/ConfigFile/ResourceLoader-user://` fuera de `persistencia/` (mismo oracle que AC-R1-02 Guardado), WHEN recorrido S0–S5 × cada opción (incl. cancelar firma), THEN 0 lecturas Y 0 escrituras directas desde el assembly de menú; Reset/Migrar solo como llamadas a fachada.
- [ ] **MENU-09 [A]** — GIVEN S5 (fixture PER N-1), WHEN MenuPrincipal, THEN exactamente {Migrar, Reset}; Continuar/Comenzar ausentes; Migrar-OK → S1; sin-ruta/fallo → superficie S4.
- [ ] **MENU-10 [A]** — GIVEN cualquier estado con PER+SUS, WHEN firma Reset incompleta (soltar/1 flanco) THEN 0 borrados byte-idénticos; WHEN hold completo THEN PER+SUS borrados, SET intacto → S0 + log.
- [ ] **MENU-11 [A]** — GIVEN S2, WHEN doble press Continuar (<200 ms, incl. dos dispositivos mismo tick), THEN 2º no-op, botón deshabilitado tras el 1º, una sola run instanciada (ref. backend AC-R9-01).
- [ ] **MENU-12 [A+M]** — GIVEN boot frío, WHEN splash visible, THEN auto-dismiss ≤2.0 s; cada pulso discreto lo salta; splash + A-spam = 0 activaciones de menú.
- [ ] **MENU-13 [M + A-proxy]** — [M] Deck 7" a 30–40 cm: checklist de cadenas funcionales legibles + captura en `production/qa/evidence/`; [A-proxy] 0 labels funcionales <18px base, 0 nodos fuera de safe_zone 5%. (Gate ADVISORY por tipo Visual.)
- [ ] **MENU-14 [A]** — GIVEN S0, WHEN cambiar un ajuste, THEN solo `settings.save` muta; `profile.save`/`suspend.save` siguen ausentes.
- [ ] **MENU-15 [A]** — GIVEN punto seguro con SUS (sha registrado), WHEN salir Hub→menú, THEN sin acción requerida y sha idéntico al confirmar flush.
- [ ] **MENU-16 [A]** — GIVEN S1 sin SUS, WHEN Comenzar la novena, THEN 0 modales, arranca directo.
- [ ] **MENU-17 [M+A]** — GIVEN reduced-motion ON, WHEN cualquier transición, THEN 0 flashes, viñeta estática, sonidos UI por bus (0 players directos).
- [ ] **MENU-18 [A]** — GIVEN S5-sin-ruta/fallo-migración, WHEN fin del intento, THEN superficie S4 visible (Reset/diagnóstico, Continuar oculto).

Presupuestos PERF-MENU (provisional, a ratificar por producer): **PERF-MENU-01** boot frío → menú interactivo p95 <3 s PC / <5 s Deck (con skip) · **PERF-MENU-02** Hub/Muerte→Menu p95 <200 ms Deck · **PERF-MENU-03** modal firma abre ≤100 ms con foco el mismo frame · **PERF-MENU-04** movimiento de foco ≤1 frame @60fps. Determinismo: timing con reloj fake en unit, Deck p95 solo [M], FS con espía, input con gamepad virtual.

## Open Questions

- [ ] Contenido mínimo del Hub (¿altar con objetos de familia interactivo o solo fondo?) — propiedad de Hub y Acumulación Visual (#18).
- [x] Decidido en Rev2: muerte **muda** (objeto del Hub + "Volver al menú", sin cita). Objeto ¿anillo o zapato? — owner narrative/world-builder (cambia el significado Pilar 4).
- [ ] La pantalla de decisión absorber/rechazar: ¿la posee Gracia (#5) con este flujo solo enrutando? Propuesto: sí.
- [x] Decidido en Rev2: inventario `MENU_*` + vetos en este GDD. Copy exacta → `/localize` con writer.
- [x] Decidido en Rev2: splash estático (título + tinta, sin vela), skippable discreto.
- [ ] Verificación en hardware Deck real (foco por mando, 18px a 30–40 cm, transiciones p95, M11/M14 same-tick y A-spam).
- [ ] Presupuesto reintento ≤10 s / ≤6 inputs: verificar en implementación o documentar excepción.
- [ ] Ratificar con Guardado: campos del resumen display-safe + catálogo único de motivos + política de caché/invalidación.
- [ ] Ratificar con Audio #16: catálogo de intenciones + timbres + ducking + cama de vela + corte duelo→muerte.

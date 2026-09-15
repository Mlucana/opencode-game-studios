# Evidencia — M-003 Pausa duelo-only + Muerte muda + Hub

**Story**: `production/epics/menu-principal/story-m003-pausa-muerte-hub.md`
**Fecha draft**: 2026-09-13
**Engine**: Godot 4.7.1 (gdUnit4 6.2.0)
**Código revisado**: `src/ui/menu_pausa.gd` (overlay MENU-04), `src/ui/menu_muerte.gd`
(muda Rev2), `src/ui/menu_hub.gd` (SUS + stakes), `src/ui/menu_presenter.gd`
(puente display-only), `src/ui/menu_settings_store.gd` (fachada SET + espía FS),
`tests/integration/ui/menu_pausa_muerte_hub_test.gd` (18 tests).
**Manifiesto**: N/A — `docs/architecture/control-manifest.md` no existe (anotado, no penalizado).
**Estado**: PARCIAL — suite 18/18 verde; 3 capturas PASS revisadas 2026-09-13 (auto-drivers Sprint 2); pendiente sesión Deck.

> Nota: sin baseline TR (`TR-menu-???` pendiente, como advierte la historia).
> Superficie pura contra mock M-001a (Blocked por ADR arranque/router): cero
> `change_scene`, cero IO directo; cableado final (`set_pausa_visual`, foco
> post-splash) marcado TODO explícito. Puerta estática CI-equivalente (grep
> `change_scene|FileAccess|DirAccess|ConfigFile|ResourceLoader|AudioStreamPlayer|`
> `CPUParticles2D|Engine.time_scale` sobre `menu_*.gd` + test): **0 llamadas en
> código** — solo menciones en doc-comments (9 en `src/ui/menu_*.gd`, 3 en el test).

## AC-a — pausa duelo-only (MENU-04)

**Estático PASS (revisión)**: `MenuPausa` construye exactamente {Reanudar, Abandonar,
Ajustes} en ese orden (`botones_en_orden()`); Continuar/reintento jamás se crean
(ausencia por construcción, no deshabilitados). Disciplina Decisión espejada:
swallow 200ms post-acción, trap en tríada + restore a -1 al cerrar, foco inicial
Reanudar (mapa GDD R7), `ui_cancel` = Reanudar por corte, Abandonar solo LISTA
(`ui_armar_destructivo`, firma owner M-004, overlay queda abierta). Pausa ordena
`CombatHud.set_estado(PAUSA)` vía `MenuPresenter.abrir_pausa()` (TODO M-001a:
el router hará suya la orden + foco post-splash).

**Automatizado PASS — corrida real usuario** (`menu_pausa_muerte_hub_test.gd`, 6 tests):
`test_pausa_tres_opciones_en_orden_exactas` · `test_pausa_sin_continuar_ni_reintento_en_arbol`
(tree-dump: ni "continuar" ni "reinten"/"retry" en textos ni nombres) ·
`test_pausa_foco_inicial_trampa_y_restaura` (0→1→2→0, -1→2, cerrar→-1) ·
`test_pausa_swallow_200ms_consume_doble_gesto` (borde 199 inhibido / 200 despacha) ·
`test_pausa_cancelar_es_reanudar_por_corte` (intención + `ui_atras` + cierre mismo frame) ·
`test_pausa_abandonar_queda_abierta_espera_firma` (fix post-review: lista + abierta, espera M-004).

**Manual PASS 2026-09-13** (`menu-pausa.png`, 1280×800, auto-driver): overlay sobre negro (duelo atenuado detrás en integración real),
Reanudar enfocado (borde 2px + cuneta, 0 glow). Archivo esperado en esta carpeta.

**Tree-dump esperado** (por construcción, pendiente de volcado real en corrida):
```text
MenuPausa (CanvasLayer, layer 20, ALWAYS)
├─ Fondo (ColorRect, STOP)
└─ SafeZone (Control, anchors 0.05–0.95)
   └─ Centro (CenterContainer)
      └─ Columna (VBoxContainer)
         ├─ Titulo (Label "MENU_PAUSA_TITULO")
         ├─ FilaReanudar: CunetaReanudar + BtnReanudar "MENU_PAUSA_REANUDAR"
         ├─ FilaAbandonar: CunetaAbandonar + BtnAbandonar "MENU_PAUSA_ABANDONAR"
         └─ FilaAjustes: CunetaAjustes + BtnAjustes "MENU_PAUSA_AJUSTES"
```

## AC-b — muerte muda Rev2

**Estático PASS (revisión)**: `MenuMuerte` = marco neutro `ObjetoHubPlaceholder`
(Panel vacío, contorno sin relleno, sin arte — placeholder documentado, objeto
anillo/zapato TBD narrative, cero diseño inventado) + `DescObjeto` sobria + única
`BtnVolver`. `es_muda()` invariante; `claves_texto()` sin clave de cita (Pilar 4).
Activar y cancelar van a la misma única salida (ya S1); swallow 200ms; overlay
queda abierta hasta el router (TODO M-001a: Volver→MenuPrincipal).

**Automatizado PASS — corrida real usuario** (3 tests): `test_muerte_muda_solo_volver_sin_cita`
(1 botón "MENU_MUERTE_VOLVER", placeholder presente, `es_muda()`, sin "cita",
claves exactas) · `test_muerte_unica_salida_con_swallow` (activar+cancelar = 1
salida; 2ª tras 200ms) · `test_muerte_es_muda_rompe_si_cita_anadida` (fix
post-review: el scan `es_muda()` delata un Label de cita añadido).

**Manual PASS 2026-09-13** (`menu-muerte.png`, 1280×800, auto-driver): marco neutro + Volver enfocado,
cero cita. Archivo esperado en esta carpeta.

**Tree-dump esperado** (por construcción, pendiente de volcado real en corrida):
```text
MenuMuerte (CanvasLayer, layer 20, ALWAYS)
├─ Fondo (ColorRect, STOP)
└─ SafeZone (Control, anchors 0.05–0.95)
   └─ Centro (CenterContainer)
      └─ Columna (VBoxContainer)
         ├─ ObjetoHubPlaceholder (Panel, vacío — TBD narrative)
         ├─ DescObjeto (Label "MENU_MUERTE_OBJETO_DESC")
         └─ FilaVolver: CunetaVolver + BtnVolver "MENU_MUERTE_VOLVER"
```

## AC-c — hub (SUS persistente + stakes)

**Estático PASS (revisión)**: `MenuHub.configure({sus_vigente, coro_label, mm_ss})`
pinta `MENU_HUB_SUS_LINE` ("La novena espera en {coro} · {mm_ss}", es-MX provisional
tabla GDD — literales owner `/localize`+writer, aquí claves + placeholders) solo
con SUS; `MENU_HUB_STAKES` siempre junto a `MENU_HUB_ENTRAR_DUELO` (misma
`FilaDuelo`). Entrar emite intención + swallow vista (dedupe autoritativo:
Guardado R9/CONSUMIENDO); la invalidación SUS la ejecuta Guardado R5, no la UI.
Cancelar = no-op + `ui_error_bloqueado` (Salir/Abandonar viven en M-001a/M-004).
Foco provisional Entrar (TODO #18).

**Automatizado PASS — corrida real usuario** (3 tests):
`test_hub_sus_visible_con_sus_y_oculta_sin_ella_stakes_siempre` (SUS on/off,
stakes+entrada persistentes, adyacencia misma `FilaDuelo`) ·
`test_hub_entrar_emite_con_swallow_y_cancela_es_sordo` (1 emisión, 2ª <200ms
tragada, 3ª tras 200ms; cancelar no entra + `ui_error_bloqueado`) ·
`test_hub_configure_invalido_oculta_sus_stakes_intactos` (fix post-review: SUS
vigente sin coro/mm_ss → false + oculta + intactos; tipos raros no muestran SUS).

**Manual PASS 2026-09-13** (`menu-hub.png`, 1280×800, auto-driver): SUS sobria + stakes junto a entrar.
Archivo esperado en esta carpeta.

## AC-d — aislamiento ajustes (MENU-14 + MENU-08)

**Estático PASS (revisión)**: `MenuSettingsStore` = memoria + espía (cero IO por
construcción: ningún `FileAccess/DirAccess/ConfigFile/ResourceLoader` en el
fichero). `aplicar_ajuste()` muta SOLO el mapa SET y cuenta en `settings.save`;
PER/SUS siempre 0 (ni referenciados). S4/S5: `set_editable(false)` → todo false
sin mutar ni contar. Fail-closed JSON-safe (NaN/Inf/tipos raros/clave vacía).

**Automatizado PASS — corrida real usuario** (2 tests):
`test_settings_cambio_muta_solo_settings_save` (2 ajustes → settings 2, PER/SUS 0,
`solo_settings_mutado()`, lectura) ·
`test_settings_s4_s5_no_editable_y_rechaza_no_json` (no-editable + clave vacía +
NaN/Inf → false, contadores 0).

## Sprint-2 additions (qa-plan 2026-09-13, GDD-derivadas)

**Estático PASS (revisión)**: gating ADR-001 R12 lado UI — `MenuPresenter`
ordena `set_estado(PAUSA)` (S oculto, `set_timer` ignorado = timer S congelado
sin contar, vignette congelada, sin rumble, retorno por corte); trauma-decay y
latch-stamps son owner WallTick/Feedback (aquí no existen: documentado, no
omitido). Continuar/retry ausentes por construcción (ver AC-a).

**Automatizado PASS — corrida real usuario** (1 test):
`test_pausa_congela_timer_s_sin_contarlo_y_retorna_por_corte` (S 90 → PAUSA:
modulate 0.4, S oculto, vignette pausada; `set_timer(50)` ignorado = 90.0;
cierre: opacidad 1.0, S visible, 90.0 — corte exacto).

**Presenter + foco/legibilidad PASS — corrida real usuario** (3 tests):
`test_presenter_reemite_intenciones_por_bus_sin_escena_ni_players` (5 intenciones
1:1 + secuencia audio exacta de 7 claves, 0 hijos, 0 players/partículas) ·
`test_foco_borde_2px_sin_glow_labels_18px_safe_5pct` (5 botones: borde 2px
`#C7CDD6`, shadow 0, hover==normal, FOCUS_ALL; labels ≥18px; safe 5%; ALWAYS) ·
`test_foco_cambiado_se_emite_en_tres_vistas` (fix post-review: pausa/muerte/hub
emiten `foco_cambiado` al fijar foco, señales de vista directas).

## Fixes post-code-review aplicados (2026-09-13, usuario aprobó — diseño intacto)

- **W1**: `_exit_tree()` en las 3 vistas desconecta `Input.joy_connection_changed`
  si conectada (sin focus-steal en vistas sustituidas sin liberar).
- **W2**: `MenuPausa._despachar` con rama `Opcion.AJUSTES` explícita; `_:` fail-closed
  (error sordo, sin intención — conforme a `intentar_activar`).
- **W3**: `MenuMuerte.es_muda()` real — scan ejecutable (cero Labels fuera de
  `DescObjeto` + claves sin "cita"); antes `return true`.
- **W4**: guarda `is_inside_tree()` al inicio de `_unhandled_input` en las 3 vistas.
- **W5**: guarda `is_node_ready()` en `MenuPausa.abrir`, `MenuMuerte.abrir`,
  `MenuHub.configure` (esta retorna false).
- **Extra**: `set_reloj_manual(true)` resetea `_swallow_hasta_ms = 0` en las 3 vistas.
- **Endurecido**: `MenuHub.configure` estricto de tipos (lo no-String no muestra SUS).
- **Tests 14→18**: abandonar-queda-abierta, es_muda-rompe-si-cita, configure-inválido,
  foco_cambiado (ver secciones).

## Nota gate (MENU-05)

MENU-05 aplicable DEFERRED — `Pausa-duelo↔Duelo p95 ≤300ms fake-clock, verificación Deck en integración`, sin test aquí.

## Out of Scope respetado (sin desviaciones)

- Nada de M-002 (backend SUS): la invalidez al entrar la ejecuta Guardado R5.
- Nada de firma destructiva de Abandonar (vive en M-004 `firma_hold.gd`): Pausa
  solo LISTA Abandonar (`ui_armar_destructivo`, overlay queda abierta).
- Nada de backend Guardado (PER/SUS/validación/consumo): el menú NUNCA toca disco.
- Nada de M-001a (shell, router, `change_scene`, foco post-splash, Hub completo,
  Salir-al-menú): TODOs explícitos, superficie pura testeable sin shell.
- Nada de timbres/ducking (owner #16): se emiten `ui_foco`, `ui_confirmar_neutro`,
  `ui_armar_destructivo`, `ui_atras`, `ui_error_bloqueado`; jamás se reproduce directo.
- Nada de objeto anillo/zapato (owner narrative): placeholder neutro documentado.
- Copy final owner `/localize`+writer: aquí claves + es-MX provisionales de tabla.
- Deuda previa intacta: paleta (`#14110E/#2A2E36/#8C94A0/#C7CDD6/#9AA2AF`),
  tallas, discipline Decisión, `EstadoHUD.PAUSA` del HUD (reutilizado, no tocado).
- Sin `prototypes/`: todo en `src/ui/` + `tests/integration/ui/`.

## Sign-off

- [x] Corrida `menu_pausa_muerte_hub_test.gd` verde (18/18) en Godot 4.7.1 — corrida real usuario + qa-lead QL-STORY-READY
- [x] 3 capturas (`menu-pausa.png`, `menu-muerte.png`, `menu-hub.png`) revisadas 2026-09-13 (3 en orden + 1 cuneta; marco vacío + 1 salida muda; SUS + stakes adyacente con foco)
- [ ] Sesión Deck: foco por mando, 18px a 30–40cm, MENU-05 p95, A-spam sin activación

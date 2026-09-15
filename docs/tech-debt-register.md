# Tech Debt Register

Advisory deviations logged at story close. Owners fix in buffer time or dedicated polish stories — never silently.

- **[2026-09-13]** (hud-005 Firma VE + gasto + knobs): `set_exact_visible` formats `tr().format()` every frame while readout visible (alloc in hot path) — `src/ui/combat_hud.gd:112-124` + `src/ui/hud_nw.gd:167-172` — tracked from `production/epics/hud-combate/story-005-firma-ve-gasto-knobs.md`
- **[2026-09-13]** (hud-005): vignette redraws every frame with static output (`_draw` never reads `_tiempo_ms`) — `src/ui/hud_vignette.gd:74-81` — tracked from `production/epics/hud-combate/story-005-firma-ve-gasto-knobs.md`
- **[2026-09-13]** (hud-005): visual queue is single-slot with silent loss + suppression window not re-armed on redispatch — `src/ui/combat_hud.gd:332-355` — tracked from `production/epics/hud-combate/story-005-firma-ve-gasto-knobs.md`
- **[2026-09-13]** (hud-005): `set_exact_visible` lacks `is_node_ready` guard; readout writes hardcoded gracia 0/0 for 1 frame — `src/ui/hud_nw.gd:167,322-324` — tracked from `production/epics/hud-combate/story-005-firma-ve-gasto-knobs.md`
- **[2026-09-13]** (hud-005): `_aplicar_estado` ~70 lines exceeds 40-line standard (pre-existing) — `src/ui/combat_hud.gd:251-320` — tracked from `production/epics/hud-combate/story-005-firma-ve-gasto-knobs.md`
- **[2026-09-13]** (hud-005 follow-up tests): contention paths untested — `_anunciar` under reduced-motion, CIERRE vs fallo-200ms suppression, `push_gasto`/`push_firma_ve` same-tick guard discards, `set_postura` masking during VE without post-CIERRE recovery test — tracked from `production/epics/hud-combate/story-005-firma-ve-gasto-knobs.md`
- **[2026-09-13]** (m-003): connect vive en `_construir` (vía `_ready`) pero disconnect en `_exit_tree` — remove+re-add sin free pierde el hook de reconexión de mando (fallback teclado intacto); mover connect a `_enter_tree` — tracked from `production/epics/menu-principal/story-m003-pausa-muerte-hub.md`
- **[2026-09-13]** (m-002): `arranque/confirmar/firma/flush` solo chequean null (no `_seams_listos()` completo como `continuar()`) — endurecer en Run #3 — tracked from `production/epics/menu-principal/story-m002-continuar-sus.md`
- **[2026-09-13]** (m-002 deferred por diseño): comparador oficial run-vs-rehidratada, FS real `persistencia/`, interior Run #3 (timeout/rechazo), vista M-001a mismo-frame — tracked from `production/epics/menu-principal/story-m002-continuar-sus.md`

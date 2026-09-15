class_name MenuSettingsStore
extends RefCounted

## Store de ajustes para M-003 (MENU-14, GDD Menú R3 + Guardado R1/R11).
##
## Fachada SET inyectable y pura: memoria + espía de escrituras, CERO E/S de
## disco por construcción (ningún `FileAccess`/`DirAccess`/`ConfigFile`/
## `ResourceLoader-user://` en este fichero — MENU-08: todo IO físico vive en
## `persistencia/` tras la fachada de Guardado; el flush ocurre fuera de duelo
## y nunca es IO síncrono en pausa de duelo, hud.md Dynamic Behaviors).
##
## INVARIANTE MENU-14: `aplicar_ajuste()` muta SOLO `settings.save`. Los
## contadores `profile.save`/`suspend.save` existen únicamente para aseverarlo
## (siempre 0: este objeto ni referencia PER ni SUS). `solo_settings_mutado()`
## es el assert del test; `reiniciar_espia()` lo pone a cero entre casos.
##
## S4/S5 NO EDITABLE (GDD Menú Edge: ajustes en S4/S5 no editables): con
## `set_editable(false)` todo `aplicar_ajuste()` retorna false sin mutar ni
## contar. El aviso persistente no-modal lo presenta el Menú (owner #15/#21).
##
## VALORES JSON-safe (Guardado R6: validador pre-stringify normativo): se
## rechazan NaN/Inf, tipos fuera de `null/bool/int/float/String/Array/Dictionary`
## y claves no-`String` en contenedores. Sin marcar dirty, sin log ruidoso:
## retorna false y no muta (fail-closed silencioso; el presentador mapea a
## `ui_error_bloqueado`).
##
## DEFAULTS provisionales (claves cerradas SET las posee #21 Accesibilidad;
## valores hasta Ajustes definitivo): volumen, idioma, movimiento_reducido,
## sonido_ambiente_ui. `aplicar_ajuste()` acepta cualquier clave `String` no
## vacía (la superficie M-001a fija el catálogo); la validación de rango la
## posee la UI de Ajustes, no este store.

## Señal de confirmación en memoria (el flush físico lo posee `persistencia/`).
signal ajuste_aplicado(clave: String, valor: Variant)

## Defaults provisionales (owner final #21; ver cabecera).
const DEFAULTS: Dictionary = {
	"volumen": 0.8,
	"idioma": "es-MX",
	"movimiento_reducido": false,
	"sonido_ambiente_ui": true,
}

var _ajustes: Dictionary = DEFAULTS.duplicate()
## S4/S5: false (GDD Menú Edge). Resto de estados: true.
var _editable: bool = true
## Espía FS: escrituras por fichero. PER/SUS siempre 0 por construcción.
var _writes: Dictionary = {"settings.save": 0, "profile.save": 0, "suspend.save": 0}


## Aplica un ajuste en memoria. Retorna false SIN mutar ni contar si: no
## editable (S4/S5), clave vacía, o valor no JSON-safe. Éxito: muta SOLO el
## mapa SET y cuenta UNA escritura en `settings.save` (PER/SUS intactos).
func aplicar_ajuste(clave: String, valor: Variant) -> bool:
	if not _editable:
		return false
	if clave == "":
		return false
	if not _es_json_safe(valor):
		return false
	_ajustes[clave] = valor
	_writes["settings.save"] = int(_writes["settings.save"]) + 1
	ajuste_aplicado.emit(clave, valor)
	return true


## Lectura en memoria (caché es fuente de verdad, Guardado R1). Retorna `def`
## si la clave no existe. Solo lectura para vistas/tests.
func leer(clave: String, def: Variant = null) -> Variant:
	return _ajustes.get(clave, def)


## Puerta S4/S5 (GDD Menú Edge: ajustes no editables sobre perfil ilegible).
func set_editable(editable: bool) -> void:
	_editable = editable


## Estado de la puerta S4/S5. Solo lectura para tests.
func es_editable() -> bool:
	return _editable


## Invariante MENU-14: SOLO `settings.save` fue tocado (PER/SUS en 0).
## Solo lectura para tests.
func solo_settings_mutado() -> bool:
	return int(_writes["profile.save"]) == 0 and int(_writes["suspend.save"]) == 0


## Escrituras contadas a `settings.save`. Solo lectura para tests.
func writes_settings() -> int:
	return int(_writes["settings.save"])


## Siempre 0 por construcción (este store ni referencia PER). Solo tests.
func writes_profile() -> int:
	return int(_writes["profile.save"])


## Siempre 0 por construcción (este store ni referencia SUS). Solo tests.
func writes_suspend() -> int:
	return int(_writes["suspend.save"])


## Pone a cero los tres contadores (aislamiento entre casos de test).
func reiniciar_espia() -> void:
	_writes["settings.save"] = 0
	_writes["profile.save"] = 0
	_writes["suspend.save"] = 0


## Copia del mapa SET actual (la vista renderiza; nunca decide el store).
func snapshot() -> Dictionary:
	return _ajustes.duplicate()


## Validador JSON-safe recursivo (Guardado R6): solo
## null/bool/int/float/String(+StringName)/Array/Dictionary, claves String,
## floats finitos. Profundidad acotada por construcción del llamador.
func _es_json_safe(v: Variant) -> bool:
	match typeof(v):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING, TYPE_STRING_NAME:
			return true
		TYPE_FLOAT:
			var f := float(v)
			return not is_nan(f) and not is_inf(f)
		TYPE_ARRAY:
			for e: Variant in (v as Array):
				if not _es_json_safe(e):
					return false
			return true
		TYPE_DICTIONARY:
			for k: Variant in (v as Dictionary).keys():
				if not (k is String or k is StringName):
					return false
				if not _es_json_safe((v as Dictionary)[k]):
					return false
			return true
	return false

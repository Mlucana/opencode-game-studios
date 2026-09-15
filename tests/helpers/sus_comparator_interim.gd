class_name SusComparatorInterim
extends RefCounted

## Comparador interim campo-a-campo — solo tests (M-002, C2 pineado).
##
## Cubre AC-R9-03 BLOCKED-note hasta que aterrice el comparador oficial
## run-suspendida-vs-rehidratada: NADA interim vive en `src/` (P2) — este helper
## lo asevera el test, nunca el juego. Al llegar el oficial se sustituye este
## fichero sin tocar `src/`; si el oficial cambia semántica, estos tests deben
## romperse (anti-falso-verde explícito, no adaptación silenciosa).
##
## Reglas pineadas (GDD Guardado R9 + AC-R9-01a/03):
## - floats con eps 1e-9 (gracia/corrupción/poso/playtime si se comparase);
## - EXCLUYE `timestamp` y `playtime_acumulado` ("todo idéntico" = gameplay
##   idéntico — R9; playtime vive por deltas in-game, nunca wall-clock);
## - `semilla_rng` se PRESERVA idéntica (re-suspender nunca rerollea);
## - `posicion_rng` puede AVANZAR (`>=` restaurado; avanzar RNG cambia el cursor);
## - resto campo-a-campo exacto (coro, representantes, decisión, pendientes,
##   loadout ordenado, ángeles, punto seguro, refs, versiones, extras round-trip).
## `extras_run{unknown:1}` se acepta con round-trip (claves futuras se
## transportan verbatim — R11); `timestamp` basura se acepta-ignora (Edge).

## Epsilon AC-R9-01a/03 para floats.
const EPS: float = 0.000000001
## Campos excluidos de la identidad "todo idéntico" (R9).
const EXCLUIDOS: Array[String] = ["timestamp", "playtime_acumulado"]
## Profundidad máxima de recursión (W10 anti-recursión infinita en snapshots
## adversariales; muy por encima de cualquier SUS real).
const MAX_PROFUNDIDAD: int = 32


## Compara rehidratada vs original. Retorna `{iguales: bool, diferencias: Array}`.
## `diferencias` nombra campos (para mensajes de fallo legibles, no para lógica).
static func comparar(rehidratada: Dictionary, original: Dictionary) -> Dictionary:
	var diferencias: Array[String] = []
	for clave: Variant in (original as Dictionary).keys():
		var k: String = String(clave)
		if k in EXCLUIDOS:
			continue
		if not (rehidratada as Dictionary).has(k):
			diferencias.append("falta:" + k)
			continue
		var a: Variant = (rehidratada as Dictionary)[k]
		var b: Variant = (original as Dictionary)[k]
		if k == "posicion_rng":
			if not _cursor_valido(a, b):
				diferencias.append(k)
			continue
		if not _igual_valor(a, b):
			diferencias.append(k)
	for clave: Variant in (rehidratada as Dictionary).keys():
		var k: String = String(clave)
		if k in EXCLUIDOS:
			continue
		if not (original as Dictionary).has(k):
			diferencias.append("extra:" + k)
	return {"iguales": diferencias.is_empty(), "diferencias": diferencias}


## `true` si la comparación pasa (atajo para `comparar(...).iguales`).
static func iguales(rehidratada: Dictionary, original: Dictionary) -> bool:
	return bool(comparar(rehidratada, original).get("iguales", false))


## Cursor RNG: numérico `>=` original con eps (W11: tolera int/float por
## round-trip JSON; avanzar consume, re-suspender conserva).
## `semilla_rng` NO pasa por aquí: va por `_igual_valor` (idéntica exacta).
static func _cursor_valido(a: Variant, b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):
		return float(a) >= float(b) - EPS
	return false


static func _igual_valor(a: Variant, b: Variant, profundidad: int = 0) -> bool:
	if profundidad > MAX_PROFUNDIDAD:
		return false
	if typeof(a) != typeof(b):
		# int vs float: compara como float con eps (JSON round-trip).
		if (a is float or a is int) and (b is float or b is int):
			return absf(float(a) - float(b)) <= EPS
		return false
	match typeof(a):
		TYPE_FLOAT:
			return absf(float(a) - float(b)) <= EPS
		TYPE_ARRAY:
			var aa: Array = a
			var bb: Array = b
			if aa.size() != bb.size():
				return false
			for i in range(aa.size()):
				if not _igual_valor(aa[i], bb[i], profundidad + 1):
					return false
			return true
		TYPE_DICTIONARY:
			var da: Dictionary = a
			var db: Dictionary = b
			if da.size() != db.size():
				return false
			for k: Variant in da.keys():
				if not db.has(k):
					return false
				if not _igual_valor(da[k], db[k], profundidad + 1):
					return false
			return true
	return a == b

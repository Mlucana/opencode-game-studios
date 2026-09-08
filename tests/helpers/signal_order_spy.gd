class_name SignalOrderSpy
extends RefCounted

## Espía de orden entre señales distintas, sobre una lista compartida.
##
## POR QUÉ EXISTE, y por qué es manual. La Regla 8 del sistema 2 exige
## **resolución síncrona**: la transición que dispara un evento debe resolverse
## dentro del mismo call stack. Verificarlo requiere aseverar el **orden entre
## señales distintas**, y **ningún framework de test lo prueba de forma nativa**
## — ni GUT ni gdUnit4. Ambos saben aseverar que una señal se emitió, cuántas
## veces y con qué argumentos; ninguno sabe decir que `a` se emitió antes que
## `b`. La única vía es registrar todas las emisiones en una **lista compartida**
## y aseverar sobre esa lista.
##
## Está anotado como bloqueante del test de C4a en el estado de sesión desde la
## 3ª pasada. Este fichero lo cierra.
##
## LO QUE MIDE Y LO QUE NO. Mide el orden de **emisión**, no el call stack real.
## Si el ADR de la Regla 8 acaba eligiendo "llamada directa a método" en vez de
## señales, no habrá señales que espiar y C4a, E2, C5a y C3b quedarán sin forma
## de escribirse — eso está registrado como una de las cuatro decisiones de
## diseño que ese ADR debe cerrar. Este espía asume la vía de señales.
##
## USO
## [codeblock]
## var espia := SignalOrderSpy.new()
## espia.observar(jefe, &"golpe_iniciado")
## espia.observar(jugador, &"parry_resuelto")
## # ... correr la simulación ...
## assert_that(espia.nombres()).is_equal([&"golpe_iniciado", &"parry_resuelto"])
## assert_that(espia.mismo_tick(0, 1)).is_true()
## [/codeblock]

## Una emisión registrada: qué señal, de qué emisor, en qué tick de física,
## con qué origen de tick, y en qué orden.
class Registro extends RefCounted:
	var nombre: StringName
	var tick: int
	var orden: int
	# F2.2 — atribución de emisor: sin esto, dos emisores distintos emitiendo
	# la misma señal son indistinguibles en la lista compartida (spy roto
	# cross-doc del re-review #2 2026-09-05).
	var emisor_id: int
	var emisor_nombre: String
	# F2.3 — sourcing del tick: "manual" (avanzar_tick en tests puros) o el
	# nombre del gate que lo fijó (p. ej. "WallTick", "DiegeticTick").
	var origen_tick: String

	func _init(p_nombre: StringName, p_tick: int, p_orden: int, p_emisor_id: int = 0, p_emisor_nombre: String = "", p_origen_tick: String = "manual") -> void:
		nombre = p_nombre
		tick = p_tick
		orden = p_orden
		emisor_id = p_emisor_id
		emisor_nombre = p_emisor_nombre
		origen_tick = p_origen_tick


## Elementos de tipo `Registro`. Se deja SIN TIPAR a propósito: los arrays
## tipados sobre clases internas son un punto frágil de GDScript y no se ha
## verificado contra 4.7. Preferimos que compile a que luzca estricto.
var _registros: Array = []
var _orden: int = 0

## Contador de ticks que el test debe mantener al día llamando a `avanzar_tick()`
## una vez por `_physics_process`. Se lleva aquí en vez de leer el reloj del
## motor para que el espía sea utilizable también en tests puros, sin escena.
##
## F2.3 — sourcing por gate: en tests de integración el tick debe venir del
## gate (`fijar_tick`), no del contador manual. `avanzar_tick()` sigue válido
## para tests puros; cada registro anota su origen para auditarlo.
var _tick: int = 0
var _origen_tick: String = "manual"


## Registra las emisiones de `nombre_senal` sobre `emisor`.
##
## Puede llamarse sobre varios emisores distintos: todas las emisiones caen en
## la **misma** lista, que es precisamente lo que permite comparar el orden
## entre señales de objetos diferentes.
func observar(emisor: Object, nombre_senal: StringName) -> void:
	assert(emisor.has_signal(nombre_senal),
		"El emisor no declara la señal '%s'" % nombre_senal)
	# F2.1 (re-review #2 2026-09-05): lambda tolerante a aridad — las señales
	# B-*/C-* portan payloads (hasta 5 args) y una lambda de 0 args falla al
	# emitir. Los params extra con default cubren de 0 a 5 args.
	# F2.2: la lambda captura la identidad del emisor para atribución cross-doc.
	var id_emisor: int = emisor.get_instance_id()
	var nombre_emisor: String = _nombre_emisor(emisor)
	var cb := func(_a = null, _b = null, _c = null, _d = null, _e = null) -> void: _anotar(nombre_senal, id_emisor, nombre_emisor)
	emisor.connect(nombre_senal, cb)


## Debe llamarse una vez por tick de física, antes de que nada más corra en ese
## tick, para que las emisiones queden atribuidas al tick correcto.
## Solo para tests puros sin escena. En integración, usar `fijar_tick()`.
func avanzar_tick() -> void:
	_tick += 1
	_origen_tick = "manual"


## F2.3 — fija el tick desde un gate autoritativo (WallTick/DiegeticTick del
## resolver). Los tests de integración DEBEN usar esto en vez de
## `avanzar_tick()`: así el tick del espía y el del gate no pueden derivar en
## silencio — el modo de fallo que la Regla 8 describe.
func fijar_tick(tick_gate: int, nombre_gate: String = "gate") -> void:
	assert(tick_gate >= 0, "El tick del gate no puede ser negativo")
	_tick = tick_gate
	_origen_tick = nombre_gate


## Tick actual del espía (el último fijado por gate o avanzado manual).
func tick_actual() -> int:
	return _tick


## Origen del tick actual ("manual" o nombre del gate). Útil para auditar en
## el test que la integración realmente vino del gate.
func origen_tick_actual() -> String:
	return _origen_tick


## Nombres de las señales en orden de emisión.
func nombres() -> Array[StringName]:
	var salida: Array[StringName] = []
	for r in _registros:
		salida.append(r.nombre as StringName)
	return salida


## Ticks en que se emitió cada señal, en el mismo orden que `nombres()`.
func ticks() -> Array[int]:
	var salida: Array[int] = []
	for r in _registros:
		salida.append(r.tick as int)
	return salida


## `true` si las emisiones en los índices `a` y `b` ocurrieron en el mismo tick
## de física. Es la aserción que distingue "resuelto en el mismo call stack" de
## "resuelto un tick después" — el modo de fallo silencioso que la Regla 8
## describe.
## Índices fuera de rango devuelven `false` (no crashean el test; el `total()`
## ya dice que la secuencia está incompleta).
func mismo_tick(a: int, b: int) -> bool:
	if a < 0 or b < 0 or a >= _registros.size() or b >= _registros.size():
		push_error("SignalOrderSpy.mismo_tick: índice fuera de rango (%d, %d) con total %d" % [a, b, _registros.size()])
		return false
	return _registros[a].tick == _registros[b].tick


## F2.2 — emisores en orden de emisión (instance IDs). Permite aseverar que dos
## señales con el mismo nombre vinieron de objetos distintos.
func emisores() -> Array[int]:
	var salida: Array[int] = []
	for r in _registros:
		salida.append(r.emisor_id as int)
	return salida


## F2.2 — nombres de emisor en orden de emisión (para mensajes de fallo
## legibles; no usar como identidad — usar `emisores()`).
func nombres_emisores() -> Array[String]:
	var salida: Array[String] = []
	for r in _registros:
		salida.append(r.emisor_nombre as String)
	return salida


## F2.2 — índices de las emisiones cuyo emisor es `emisor`.
func indices_de(emisor: Object) -> Array[int]:
	var buscado: int = emisor.get_instance_id()
	var salida: Array[int] = []
	for i in range(_registros.size()):
		if (_registros[i].emisor_id as int) == buscado:
			salida.append(i)
	return salida


## F2.3 — orígenes de tick en orden de emisión. En integración, todos deben ser
## el gate (ningún "manual" intercalado).
func origenes_tick() -> Array[String]:
	var salida: Array[String] = []
	for r in _registros:
		salida.append(r.origen_tick as String)
	return salida


## Número total de emisiones registradas.
func total() -> int:
	return _registros.size()


## Vacía la lista sin desconectar los observadores. Útil para medir solo una
## fase concreta de una simulación larga. No resetea el tick: el tiempo no
## retrocede al limpiar la ventana de observación.
func limpiar() -> void:
	_registros.clear()
	_orden = 0


func _anotar(nombre: StringName, id_emisor: int = 0, nombre_emisor: String = "", origen: String = "") -> void:
	var org: String = origen if origen != "" else _origen_tick
	_registros.append(Registro.new(nombre, _tick, _orden, id_emisor, nombre_emisor, org))
	_orden += 1


## Nombre legible del emisor para diagnóstico. Nunca se usa como identidad.
static func _nombre_emisor(emisor: Object) -> String:
	if emisor is Node:
		var n: Node = emisor as Node
		if n.name != null and String(n.name) != "":
			return String(n.name)
	return "obj#%d" % emisor.get_instance_id()

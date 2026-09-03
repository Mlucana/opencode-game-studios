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

## Una emisión registrada: qué señal, en qué tick de física, y en qué orden.
class Registro extends RefCounted:
	var nombre: StringName
	var tick: int
	var orden: int

	func _init(p_nombre: StringName, p_tick: int, p_orden: int) -> void:
		nombre = p_nombre
		tick = p_tick
		orden = p_orden


## Elementos de tipo `Registro`. Se deja SIN TIPAR a propósito: los arrays
## tipados sobre clases internas son un punto frágil de GDScript y no se ha
## verificado contra 4.7. Preferimos que compile a que luzca estricto.
var _registros: Array = []
var _orden: int = 0

## Contador de ticks que el test debe mantener al día llamando a `avanzar_tick()`
## una vez por `_physics_process`. Se lleva aquí en vez de leer el reloj del
## motor para que el espía sea utilizable también en tests puros, sin escena.
var _tick: int = 0


## Registra las emisiones de `nombre_senal` sobre `emisor`.
##
## Puede llamarse sobre varios emisores distintos: todas las emisiones caen en
## la **misma** lista, que es precisamente lo que permite comparar el orden
## entre señales de objetos diferentes.
func observar(emisor: Object, nombre_senal: StringName) -> void:
	assert(emisor.has_signal(nombre_senal),
		"El emisor no declara la señal '%s'" % nombre_senal)
	var cb := func() -> void: _anotar(nombre_senal)
	emisor.connect(nombre_senal, cb)


## Debe llamarse una vez por tick de física, antes de que nada más corra en ese
## tick, para que las emisiones queden atribuidas al tick correcto.
func avanzar_tick() -> void:
	_tick += 1


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
func mismo_tick(a: int, b: int) -> bool:
	return _registros[a].tick == _registros[b].tick


## Número total de emisiones registradas.
func total() -> int:
	return _registros.size()


## Vacía la lista sin desconectar los observadores. Útil para medir solo una
## fase concreta de una simulación larga.
func limpiar() -> void:
	_registros.clear()
	_orden = 0


func _anotar(nombre: StringName) -> void:
	_registros.append(Registro.new(nombre, _tick, _orden))
	_orden += 1

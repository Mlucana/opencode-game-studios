class_name MockLedgerGracia
extends RefCounted

## Mock del ledger de Gracia para tests del HUD — STAND-IN del sistema #5.
##
## FRONTERA (story-005, G7): la decisión de gasto vive en #5. Este mock la
## sustituye SOLO en el harness para que el HUD refleje un veredicto real
## (cap/cooldown observables tras un intento ilegal). Cuando aterrice el
## ledger real, este mock se RETIRA y los tests cablean el emisor de verdad
## sin tocar `src/ui/` (el HUD no cambia: solo lee veredictos).
##
## ALCANCE: earn +1.0/+1.0 por VE parada con cap Σ≤3/duelo (G3/GR-08, stub
## D13 con s≡1.0), gate de gasto G7 (legal en Telegrafiado/Enfriamiento/
## Repliegue/Hub; ilegal en VE activa y resto → descartado sin buffer),
## `gracia==coste` ACEPTA a 0.0, cooldown 360 + cap 2 gastos/duelo + máx
## 1 amparo. FUERA DE ALCANCE a propósito: saturación-quiebre (owner #6,
## story-005 P6 OUT), TOMAR/DEJAR (Decisión, no HUD de combate), combo 0.5.
##
## P5: SIN cuantización float→shards — el mock solo decide (bool + floats);
## los ints de display los fija el test a mano al llamar `push_gasto` /
## `push_gracia`. El mapeo canónico lo posee #5, no este mock.
##
## Señales en español de dominio, pasado (technical-preferences.md).

## Veredicto de gasto (el HUD lo refleja vía `HudPresenter.push_gasto`).
signal gasto_resuelto(aceptado: bool)

## Costes plantilla MVP cerrada (G7): Purga 8 (solo alivio), Amparo 12.
const COSTE_PURGA: float = 8.0
const COSTE_AMPARO: float = 12.0
## Cap agregado R9a/GR-08 (stub D13: s≡1.0 → máx 3 VE/duelo como consecuencia).
const CAP_SIGMA_VE: float = 3.0
## Cap 2 gastos/duelo + máx 1 amparo + cooldown 360 ticks (~6 s @60Hz, G7).
const CAP_SPENDS: int = 2
const COOLDOWN_TICKS: int = 360

## Ledger triple (G1): bolsa gastable, progreso a Clímax, suelo irreversible.
var gracia: float
var corrupcion: float
var poso: float
## Contadores de gasto duel-scoped (G7): resetean por duelo, NO el cooldown.
var spends: int = 0
var amparo_usado: bool = false
## Ticks desde el último gasto aceptado. Inicia SATISFECHO (SUS, G7).
var ticks_desde_gasto: int = COOLDOWN_TICKS
## Ventana Especial abierta (el gasto en VE activa es ilegal, G7).
var ve_abierta: bool = false
## Σ severidades consumidas este duelo (stub D13: cada VE declara s≡1.0).
var sigma_ve: float = 0.0
## Log observable (el cap 4ª-VE exige +0/+0 CON log, GR-08).
var registro: Array[String] = []


## Inicializa el triple + cooldown SATISFECHO (SUS inicia satisfecha, G7).
func _init(gracia_ini: float = 20.0, corrupcion_ini: float = 30.0, poso_ini: float = 12.0) -> void:
	gracia = gracia_ini
	corrupcion = corrupcion_ini
	poso = poso_ini


## Abre una VE (el HUD pre-ilumina vía ev.14; el gasto pasa a ser ilegal).
func abrir_ve() -> void:
	ve_abierta = true


## Cierra la VE. Parada → earn +1.0/+1.0 con gate Σ+s>3 (GR-08: 4ª VE a 1.0
## da +0/+0 con log); no parada → +0/+0 (corolario R6, sin log).
## Retorna la ganancia aplicada (1.0 o 0.0) para aserción del test.
func cerrar_ve(parada: bool) -> float:
	ve_abierta = false
	if not parada:
		return 0.0
	if sigma_ve + 1.0 > CAP_SIGMA_VE:
		registro.append("cap_ve: VE parada con sigma=%.1f+s=1.0>3.0 → +0/+0" % sigma_ve)
		return 0.0
	gracia += 1.0
	corrupcion += 1.0
	sigma_ve += 1.0
	return 1.0


## Intenta un gasto contra la compuerta G7. `contexto_legal` lo fija el test
## (true en Telegrafiado/Enfriamiento/Repliegue/Hub; false en Parry activo /
## Aturdido / Recepción / lockout-whiff / Decisión abierta). La VE activa
## manda sobre el contexto (G7 explícito). RECHAZO = sin efecto colateral:
## no toca spends, cooldown, ledgers ni emite salvo el veredicto (blip de
## denegación lo emite el HUD por bus). ACEPTA aplica coste + alivio
## `poso+(C−poso)/2` (G7) y resetea el cooldown. Orden mismo-tick: el test
## llama primero a `cerrar_ve()` y luego aquí (earn→gasto, GR-27).
func intentar_gasto(coste: float, contexto_legal: bool) -> bool:
	if ve_abierta:
		registro.append("gasto_rechazado: VE activa (G7, no-buffer)")
		gasto_resuelto.emit(false)
		return false
	if not contexto_legal:
		registro.append("gasto_rechazado: contexto ilegal (G7, no-buffer)")
		gasto_resuelto.emit(false)
		return false
	if gracia < coste:
		registro.append("gasto_rechazado: gracia %.1f < coste %.1f" % [gracia, coste])
		gasto_resuelto.emit(false)
		return false
	if spends >= CAP_SPENDS:
		registro.append("gasto_rechazado: cap 2/duelo (G7)")
		gasto_resuelto.emit(false)
		return false
	if ticks_desde_gasto < COOLDOWN_TICKS:
		registro.append("gasto_rechazado: cooldown %d<360 (G7)" % ticks_desde_gasto)
		gasto_resuelto.emit(false)
		return false
	if coste >= COSTE_AMPARO and amparo_usado:
		registro.append("gasto_rechazado: max 1 amparo/duelo (G7)")
		gasto_resuelto.emit(false)
		return false
	# ACEPTA (`gracia==coste` incluido → 0.0, estado legal GF-S1).
	gracia -= coste
	corrupcion = maxf(poso, poso + (corrupcion - poso) / 2.0)
	spends += 1
	ticks_desde_gasto = 0
	if coste >= COSTE_AMPARO:
		amparo_usado = true
	registro.append("gasto_aceptado: coste %.1f → gracia %.1f" % [coste, gracia])
	gasto_resuelto.emit(true)
	return true


## Avanza el cooldown (ticks enteros; 359 rechaza, 360 acepta — GR-20).
func avanzar_tick() -> void:
	ticks_desde_gasto += 1


## Nuevo duelo: resetean spends/amparo/Σ (rename-SUS pre-duelo, G7); el
## cooldown monótono NO resetea (cruza duelos).
func reiniciar_duelo() -> void:
	spends = 0
	amparo_usado = false
	sigma_ve = 0.0
	ve_abierta = false

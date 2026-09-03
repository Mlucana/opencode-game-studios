# Verificador autónomo — NO necesita gdUnit4 ni ningún addon.
#
# Uso:
#   godot --headless --script tests/standalone_check.gd
#
# POR QUÉ EXISTE. La biblioteca de assets de Godot puede tener gdUnit4 marcado
# como incompatible con la versión del editor, dejando el botón de descarga
# desactivado. Eso bloquea la verificación por una razón que no tiene nada que
# ver con el diseño del juego. Este script corre las comprobaciones críticas con
# GDScript puro, así que responde hoy las dos preguntas que importan:
#
#   1. ¿Compila el código?
#   2. ¿Salen los números que el GDD dice que deben salir?
#
# NO SUSTITUYE A LA SUITE. `tests/unit/combate/*.gd` sigue siendo la suite real,
# con aislamiento por test, setup/teardown y reporte por AC. Esto es una red de
# seguridad para cuando el framework no está disponible, y una comprobación de
# humo rápida para CI local.
extends SceneTree

const Tuning := preload("res://src/gameplay/combate/combat_tuning.gd")
const F := preload("res://src/gameplay/combate/combat_formulas.gd")
const Stub := preload("res://tests/helpers/boss_stub.gd")
const Harness := preload("res://tests/helpers/parry_harness.gd")

var _pasan: int = 0
var _fallos: Array = []


func _init() -> void:
	print("")
	print("=== Verificación autónoma — Combate de Parry-Absorción ===")
	print("")

	var t: CombatTuning = Tuning.new()

	_bloque("Fórmula 1 — escalones de calidad_timing (D1, D14)")
	var calidades: Array = [1.0, 0.9, 0.7, 0.5, 0.3, 0.1, 0.0]
	var danos: Array = [14.0, 13.6, 12.8, 12.0, 11.2, 10.4, 10.0]
	for d in range(7):
		_check("  Δ=%d → calidad %.2f" % [d, calidades[d]],
			_aprox(F.calidad_timing(d, t), calidades[d]))
		_check("  Δ=%d → postura_dano %.1f" % [d, danos[d]],
			_aprox(F.postura_dano(d, t), danos[d]))
	_check("  Δ≥6 satura a 0", _aprox(F.calidad_timing(20, t), 0.0))
	_check("  monótona no creciente", _es_monotona(t))

	_bloque("Parry Justo — predicado y bono (C25)")
	_check("  Δ=0 es Justo", F.es_parry_justo(0, t))
	_check("  Δ=1 es Justo", F.es_parry_justo(1, t))
	_check("  Δ=2 NO es Justo", not F.es_parry_justo(2, t))
	_check("  bono +2 / +1 / +0", F.bono_hitstop(0, t) == 2 and F.bono_hitstop(1, t) == 1 and F.bono_hitstop(2, t) == 0)
	_check("  R8: hitstop + bono ≤ 8", t.hitstop_parry + F.bono_hitstop(0, t) <= 8)

	_bloque("Fórmula 8 — daño de golpe enemigo (D11, D12)")
	_check("  vale 25 con valores de lanzamiento", _aprox(F.dano_golpe_enemigo(t), 25.0))
	_check("  vida_maxima con 3 absorciones = 154", F.vida_maxima(3, 0, t) == 154)
	_check("  NO cambia con absorciones (ancla en vida_base)", _aprox(F.dano_golpe_enemigo(t), 25.0))
	_check("  sobrevive 4 golpes sin absorber", F.golpes_sobrevividos(0, 0, t) == 4)
	_check("  sobrevive 7 con las 3 absorciones", F.golpes_sobrevividos(3, 0, t) == 7)

	_bloque("R10a — presupuesto de reliquias (D15)")
	_check("  +25 de Vida pasa", F.cumple_r10a(25, t))
	_check("  +26 de Vida falla", not F.cumple_r10a(26, t))
	_check("  −20% de daño pasa", F.cumple_r10a(0, t, 0.20))
	_check("  −25% de daño falla", not F.cumple_r10a(0, t, 0.25))
	_check("  +25 y −20% juntos fallan", not F.cumple_r10a(25, t, 0.20))

	_bloque("Clamps de recursos agotables (E12, E13)")
	_check("  Vida 10 − 25 → 0 exacto", _aprox(F.aplicar_dano(10.0, 25.0), 0.0))
	_check("  6 castigos de 100/6 → 0 exacto", _seis_castigos_dan_cero(t))
	var t110: CombatTuning = Tuning.new()
	t110.vida_base = 110
	_check("  vida_base 110 → daño 27.5", _aprox(F.dano_golpe_enemigo(t110), 27.5))
	_check("  4 golpes de 27.5 → 0 exacto", _cuatro_golpes_dan_cero(t110))

	_bloque("Invariantes de lanzamiento R1–R8 (D9a)")
	_check("  R1", F.cumple_r1(t))
	_check("  R2 (comparación entera)", F.cumple_r2(t))
	_check("  R3", t.ciclos_objetivo_base == 4)
	_check("  R4", F.cumple_r4(t))
	_check("  R5", F.cumple_r5(t))
	_check("  R6", F.cumple_r6(t))
	_check("  R7", F.cumple_r7(t))
	_check("  R8", F.cumple_r8(t))
	_check("  cobertura ≈ 59%", F.cobertura_temporal(t) > 0.59 and F.cobertura_temporal(t) < 0.60)

	_bloque("Borde de Castigo (C11)")
	_check("  se deriva a 114", F.t_max_castigo(t) == 114)
	var t10: CombatTuning = Tuning.new()
	t10.gracia_salida_castigo = 10
	_check("  con gracia=10 se mueve a 110", F.t_max_castigo(t10) == 110)

	_bloque("Ciclo de parry contra el stub (C6, C12a, C19, C20, C21)")
	_ciclo_de_parry(t)

	print("")
	print("=== Resultado: %d pasan, %d fallan ===" % [_pasan, _fallos.size()])
	if not _fallos.is_empty():
		print("")
		print("FALLOS:")
		for f in _fallos:
			print("  ✗ %s" % f)
	print("")
	quit(1 if not _fallos.is_empty() else 0)


func _ciclo_de_parry(t: CombatTuning) -> void:
	# C12a — machacar 1800 ticks sin ningún enemigo.
	var h: ParryHarness = Harness.new(t)
	for i in range(1800):
		h.soltar()
		h.pulsar()
		h.avanzar_tick()
	_check("  C12a mash: 1066 ticks en PARRY", h.ticks_en_parry == 1066)
	_check("  C12a cobertura ≤ 65%", h.cobertura() <= 0.65)

	# C24 — botón mantenido.
	var h2: ParryHarness = Harness.new(t)
	h2.pulsar()
	for i in range(40):
		h2.avanzar_tick()
	_check("  C24 mantenido → 1 solo intento", h2.whiffs == 1)

	# C19 (a) — se pulsa con la Ventana Especial ya abierta.
	var h3: ParryHarness = Harness.new(t)
	var s3: BossStub = Stub.new()
	s3.disparar_ventana_especial(20)
	h3.observar(s3)
	s3.avanzar_tick()
	h3.soltar()
	h3.pulsar()
	h3.avanzar_tick()
	_check("  C19a parry en VE abierta = ÉXITO", h3.parries_exitosos == 1 and h3.whiffs == 0)

	# C20 — dos de las cuatro consecuencias.
	_check("  C20 gracia sí", h3.gracia == 1)
	_check("  C20 hitstop sí", h3.hitstops == 1)
	_check("  C20 Postura NO cambia", _aprox(h3.postura, float(F.postura_max(0, t))))
	_check("  C20 Repliegue NO, Enfriamiento sí", h3.repliegues == 0 and h3.enfriamientos == 1)

	# C19 (b) — la ventana se abre con el parry ya activo.
	var h4: ParryHarness = Harness.new(t)
	var s4: BossStub = Stub.new()
	s4.disparar_ventana_especial(20)
	h4.observar(s4)
	h4.pulsar()
	h4.avanzar_tick()
	s4.avanzar_tick()
	h4.avanzar_tick()
	_check("  C19b VE se abre con parry activo = ÉXITO", h4.parries_exitosos == 1 and h4.whiffs == 0)

	# C21 — la Ventana Especial vence sin ser parada: no daña.
	var h5: ParryHarness = Harness.new(t)
	var s5: BossStub = Stub.new()
	s5.disparar_ventana_especial(20)
	h5.observar(s5)
	for i in range(25):
		s5.avanzar_tick()
		h5.avanzar_tick()
	_check("  C21 VE no parada → Vida 100 intacta", _aprox(h5.vida, 100.0) and h5.golpes_recibidos == 0)

	# C6 — el contraste: un Golpe no parado sí daña.
	var h6: ParryHarness = Harness.new(t)
	var s6: BossStub = Stub.new()
	s6.secuencia = [{ "fase": Stub.Fase.GOLPE, "ticks": 20 }]
	s6.en_bucle = false
	s6.iniciar()
	h6.observar(s6)
	for i in range(25):
		s6.avanzar_tick()
		h6.avanzar_tick()
	_check("  C6 Golpe no parado → Vida 75", _aprox(h6.vida, 75.0) and h6.golpes_recibidos == 1)


func _es_monotona(t: CombatTuning) -> bool:
	for d in range(29):
		if F.calidad_timing(d, t) < F.calidad_timing(d + 1, t):
			return false
	return true


func _seis_castigos_dan_cero(t: CombatTuning) -> bool:
	var vida: float = 200.0
	var dano: float = F.dano_golpe_castigo(200, 2, t)
	for i in range(6):
		vida = F.aplicar_dano(vida, dano)
	return _aprox(vida, 0.0)


func _cuatro_golpes_dan_cero(t: CombatTuning) -> bool:
	var vida: float = float(t.vida_base)
	var dano: float = F.dano_golpe_enemigo(t)
	for i in range(4):
		vida = F.aplicar_dano(vida, dano)
	return _aprox(vida, 0.0)


func _bloque(titulo: String) -> void:
	print("--- %s" % titulo)


func _check(nombre: String, condicion: bool) -> void:
	if condicion:
		_pasan += 1
		print("  ok   %s" % nombre.strip_edges())
	else:
		_fallos.append(nombre.strip_edges())
		print("  FALLA %s" % nombre.strip_edges())


func _aprox(a: float, b: float) -> bool:
	return absf(a - b) < 1e-6

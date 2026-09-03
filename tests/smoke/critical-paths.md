# Smoke Test: Camino Crítico

**Propósito**: 10–15 comprobaciones en menos de 15 minutos, antes de cualquier
entrega a QA.
**Se ejecuta con**: `/smoke-check`, que lee este fichero.
**Mantenimiento**: añadir una entrada cuando se implemente un sistema núcleo nuevo.

> **Estado actual: el proyecto no tiene código.** `src/` está vacío y no hay
> escenas. Las entradas 1–3 y 5–8 **no son ejecutables todavía** y se listan como
> semilla. La única sección con contenido real es la del stub, porque el stub sí
> existe.

## Estabilidad básica (siempre)

1. El juego arranca al menú principal sin crash — *pendiente: no hay menú*
2. Se puede iniciar una partida desde el menú — *pendiente*
3. El menú responde a todos los inputs sin congelarse — *pendiente*

## Mecánica núcleo (actualizar por sprint)

4. **Stub de jefe determinista** — `tests/helpers/boss_stub.gd` reproduce la
   misma traza de eventos en dos ejecuciones idénticas, con las duraciones en
   ticks que se le pidan. Es el prerrequisito de nueve ACs del sistema 1; si esto
   falla, C12b y C19–C23 no miden nada.
5. **Disparador de Ventana Especial** — `disparar_ventana_especial(n)` emite el
   par `inicio`/`fin` separados exactamente por `n` ticks, sin depender de ningún
   patrón del sistema 20.
6. [Parry — añadir cuando se implemente la Regla 3]
7. [Golpe de Castigo — añadir cuando se implemente la Regla 5]

## Integridad de datos

8. Guardado sin error — *pendiente: no hay sistema de guardado*
9. Carga restaura el estado correcto — *pendiente*

## Rendimiento

10. Sin caídas visibles de framerate en hardware objetivo (60 FPS) — *pendiente*
11. Sin crecimiento de memoria en 5 minutos de juego — *pendiente*

> **Nota de protocolo, heredada del confundidor declarado de C13/P4**: un fallo
> de rendimiento debe distinguir explícitamente entre *defecto de conteo de
> ticks* y *confundidor por hitch de frame* — `Engine.max_physics_steps_per_frame`
> limita a 8 los ticks de física por frame renderizado, y bajo un stall severo en
> Steam Deck ambos producen el mismo síntoma y solo uno es un bug. Registrar
> frame time y ticks por frame junto a la medición.

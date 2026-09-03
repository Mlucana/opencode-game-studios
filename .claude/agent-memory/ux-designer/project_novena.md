---
name: project-novena
description: NOVENA es un roguelike de boss-rush con parry de precisión; pilares y decisiones de HUD relevantes para checks de UX
metadata:
  type: project
---

NOVENA es un juego de parry de precisión tipo boss-rush roguelike. Datos clave:

- Ventana de parry confirmada en prototipo: ~150-220ms, con hitstop de "juice" en éxito. Es el core skill test del juego.
- Pilar de diseño citado explícitamente por el equipo: "La maestría está en las manos, no en la ficha" (mastery lives in the hands, not the character sheet) — el HUD nunca debe competir con ni retrasar la lectura de esa ventana de 150-220ms.
- Input primario: gamepad (stick/gatillos analógicos), con teclado/ratón como esquema secundario totalmente soportado (no de segunda clase). Confirmado en technical-preferences.md.
- Plataforma objetivo de verificación: Steam Deck (pantalla de 7"), además de PC. Toda la UI y feedback de combate debe ser legible ahí; el timing del parry debe validarse en hardware real, no solo en desktop.
- Identificación de 9 tipos de enemigos usa "forma antes que color" como mecanismo primario (no daltónico-safe por color solo) — precedente que debería extenderse a los propios estados críticos del HUD (alerta, gracia).

Decisión de arte (art-director, en paralelo) para el HUD de combate: screen-space no diegético, barras/marcas rectas y finas, bajo contraste croma, evita explícitamente formas circulares/orbitales (reservadas para el lenguaje visual "vitral"/divino) para no generar confusión figura-fondo con los telegraphs enemigos durante ventanas de parry. Excepción: el medidor de gracia/corrupción SÍ puede usar iconografía vitral porque ES la mecánica de corrupción.

**Por qué importa:** cualquier checkeo de UX en este proyecto debe evaluar sección por sección si la dirección visual sirve a la lectura de la ventana de parry, ya que ese es el criterio de éxito central, no solo estética o legibilidad genérica.

**Cómo aplicarlo:** al revisar futuras secciones del art bible o pantallas de UI, preguntar siempre: (1) ¿compite esto con el read de la ventana de parry? (2) ¿se distingue bajo contraste croma de bajo contraste de luminancia al hablar de legibilidad en Steam Deck? (3) ¿el modo de UI es de combate (aplica regla anti-círculo) o de menú/pausa (no aplica)? (4) ¿los estados críticos del HUD tienen respaldo de forma, no solo color?

Ver también [[feedback-hud-parry-legibility]] si existe una entrada de feedback derivada de esta conversación.

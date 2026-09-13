# Prototipo: capturas de evidencia hud-001

## Hipótesis

Un driver desechable que instancia la `CombatHud` real y dispara sus estados
vía `HudPresenter` permite capturar la evidencia manual de
`production/epics/hud-combate/story-001-nw-vida-gracia.md` sin escena de duelo
(aún no existe Run/Core que la alimente).

## Cómo correrlo

1. Abrir el proyecto en Godot 4.7.2-stable.
2. Abrir `prototypes/hud-nw-captures/hud_capture_driver.tscn`.
3. **Play Scene (F6)** — el driver fija la ventana a 1280×800 solo.
4. Pulsar teclas (cada una auto-guarda su PNG en
   `production/qa/evidence/` tras 1–2 frames, dentro del efecto visible):
   - `1` → cicla Vida 100 → 75 → 57 → 25 → `hud-nw-vida.png`
     (pulsa UNA vez: 100→75, ese es el PNG de evidencia)
   - `2` → cicla Gracia 0..4 → `hud-nw-gracia.png`
     (pulsa hasta 2/4 encendidas)
   - `3` → flash de fallo → `hud-nw-flash.png` (captura al frame 1 de 2)
   - `4` → prelight VE on/off → `hud-nw-prelight.png` (extra, story-005)
   - `0` → reset (Vida 100, Gracia 2/4, firma cerrada)
   - `5` → captura manual `hud-nw-manual-N.png` del estado actual
5. Verificar en consola `[capturas] guardada: ...` por cada PNG.

## Estado

- Estado: in-progress (driver escrito, pendiente de corrida en estación con display)
- No corre en CI/headless: `get_texture().get_image()` exige render con display.

## Hallazgos

- (pendiente de la corrida: anotar aquí si algún estado no es capturable,
  p. ej. flash fundido, y el workaround usado)
- Al concluir, este directorio se archiva; el código NUNCA migra a `src/`.

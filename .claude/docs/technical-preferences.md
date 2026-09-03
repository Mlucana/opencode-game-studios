# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.7
- **Language**: GDScript
- **Rendering**: [TO BE CONFIGURED]
- **Physics**: [TO BE CONFIGURED]

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Steam), Steam Deck
- **Input Methods**: Gamepad, Keyboard/Mouse
- **Primary Input**: Gamepad — teclado/ratón es un esquema secundario totalmente soportado, no de segunda clase
- **El control de parry es DIGITAL** *(corregido el 2026-08-04; antes decía "el parry se diseña primero para stick/gatillos analógicos")*: la acción de parry se mapea a un control binario y **ningún eje analógico** puede mapearse a ella. Un eje analógico mete la distancia de recorrido dentro del instante de pulsación —la misma intención produce un instante distinto según el mando y según dónde descanse el dedo—, lo que hace medir la habilidad por el hardware, contra el Pilar 2; y obliga a umbral e histéresis, con lo que "una pulsación" deja de estar bien definido para las reglas de descarte sin buffer del GDD de Combate. Normativa en `design/gdd/combate-parry-absorcion.md`, Regla 2; verificada por su AC **C24**
- **Gamepad Support**: Full
- **Touch Support**: None
- **Platform Notes**: Todo el feedback de combate y la UI deben ser legibles en la pantalla de 7" de Steam Deck. La UI debe soportar navegación completa por mando (sin interacciones que dependan de hover). El timing del parry debe verificarse con hardware real de Steam Deck, no solo en PC de escritorio.

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`)
- **Variables**: snake_case (e.g., `move_speed`)
- **Signals/Events**: snake_case, tiempo pasado (e.g., `health_changed`)
- **Files**: snake_case coincidiendo con la clase (e.g., `player_controller.gd`)
- **Scenes/Prefabs**: PascalCase coincidiendo con el nodo raíz (e.g., `PlayerController.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.6ms
- **Draw Calls**: <1000 por escena (presupuesto generoso para 2D con VFX de gracia/vitral)
- **Memory Ceiling**: 1.5GB (deja margen sobre los 16GB compartidos de Steam Deck para SO y overhead de Proton)

## Testing

- **Framework**: **gdUnit4** *(corregido el 2026-08-04; antes decía "GUT (Godot Unit Test)", contradiciendo el comando de runner que `coding-standards.md` ya especificaba)*. Elegido por dos exigencias de este proyecto: los ACs D1/D14/C2/C18/C24 requieren **inyectar input en un tick de física concreto** —`calidad_timing` es una cantidad escalonada indexada por ticks enteros, así que un test sin control del tick no verifica nada— y gdUnit4 aporta `scene_runner` con simulación de frames e input. Ver `tests/README.md`. **Lo que ningún framework cubre** es el orden *entre señales distintas* que exige la Regla 8 del sistema 2: para eso existe `tests/helpers/signal_order_spy.gd`
- **Minimum Coverage**: [TO BE CONFIGURED]
- **Required Tests**: Balance formulas, gameplay systems, networking (if applicable)

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (todos los archivos .gd)
- **Shader Specialist**: godot-shader-specialist (.gdshader, recursos VisualShader)
- **UI Specialist**: godot-specialist (sin especialista dedicado — primary cubre toda la UI)
- **Additional Specialists**: godot-gdextension-specialist (solo GDExtension / bindings nativos en C++)
- **Routing Notes**: invocar a primary para decisiones de arquitectura, validación de ADRs y revisión de código transversal. Invocar a gdscript-specialist para calidad de código, arquitectura de señales, tipado estático e idiomas propios de GDScript. Invocar a shader-specialist para diseño de materiales y código de shader. Invocar a gdextension-specialist solo cuando se involucren extensiones nativas.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |

# Escudo Escolar: Defensa Cibernética

Videojuego educativo 2D de aventura, plataformas y exploración sobre ciberseguridad,
desarrollado con **Godot 4.7.2** y **GDScript**.

> Estado: **prototipo de combate en desarrollo.** Ver el plan en [`docs/combate.md`](docs/combate.md).

## Cómo ejecutar

1. Instala [Godot 4.7.2](https://godotengine.org/download) (edición estándar). Todo el equipo debe usar la misma versión.
2. Abre Godot → **Importar** → selecciona el archivo `project.godot` de esta carpeta.
3. Presiona **F5** (o el botón ▶ "Ejecutar proyecto").

Los controles están en [`docs/arquitectura.md`](docs/arquitectura.md#controles).

## Estructura

Carpetas organizadas **por funcionalidad**: cada escena está junto a su script.

```
res://
├── autoload/      # Singletons globales (SceneManager)
├── characters/    # Jugador, NPC y enemigos
├── components/    # Componentes reutilizables (daño, vida…)
├── world/         # Salas, tilesets, cámara y objetos del mundo
├── ui/            # Menús, componentes de interfaz y tema visual
├── data/          # Contenido del juego (diálogos, misiones, glosario…)
├── assets/        # Arte, audio y fuentes
├── tests/         # Pruebas automáticas
└── docs/          # Documentación técnica y de diseño
```

## Documentación

- [`docs/arquitectura.md`](docs/arquitectura.md): estructura, autoloads, resolución, capas de colisión, controles y pruebas.
- [`docs/combate.md`](docs/combate.md): diseño del combate, decisiones del MVP y estado de las tareas.
- [`docs/arte/guia_de_arte.md`](docs/arte/guia_de_arte.md): dirección de arte (pixel art + huesos pixelados + Visión Digital), paleta, plantilla de Kai por piezas y prioridades.

## Pruebas automáticas

```
godot --headless --path . --script res://tests/test_menu_navigation.gd
godot --headless --path . --script res://tests/test_player_movement.gd
godot --headless --path . --script res://tests/test_player_abilities.gd
godot --headless --path . --script res://tests/test_decision_system.gd
godot --headless --path . --script res://tests/test_player_health.gd
godot --headless --path . --script res://tests/test_progress.gd
godot --headless --path . --script res://tests/test_zone0.gd
godot --headless --path . --script res://tests/test_vision.gd
godot --headless --path . --script res://tests/test_dialogue.gd
godot --headless --path . --script res://tests/test_prologue.gd
```

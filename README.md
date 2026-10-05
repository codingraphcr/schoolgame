# Escudo Escolar: Defensa Cibernética

Videojuego educativo 2D de ciberseguridad, desarrollado con **Godot 4** y **GDScript**.

> Estado: **Etapa 1 — base del proyecto.** Incluye el menú principal y pantallas provisionales.
> Todavía no hay sistema de juego (amenazas, defensas, niveles, etc.).

## Cómo ejecutar

1. Instala [Godot 4](https://godotengine.org/download) (versión 4.3 o superior, edición estándar).
2. Abre Godot → **Importar** → selecciona el archivo `project.godot` de esta carpeta.
3. Presiona **F5** (o el botón ▶ "Ejecutar proyecto").

Controles: ratón o pantalla táctil; también teclado (flechas + Enter) y **Esc** para volver al menú.

## Estructura

```
res://
├── assets/
│   ├── audio/        # Música y efectos de sonido
│   ├── fonts/        # Fuentes tipográficas
│   ├── images/       # Imágenes e íconos (logo_shield.svg)
│   └── themes/       # Tema visual compartido (main_theme.tres)
├── data/             # Datos del juego (preguntas, niveles…) en etapas futuras
├── scenes/
│   ├── main/         # Pantallas completas: menú, configuración, nivel provisional
│   └── ui/           # Componentes de interfaz reutilizables (fondo tecnológico)
└── scripts/
    ├── core/         # Sistemas globales (SceneManager)
    ├── main/         # Scripts de las pantallas de scenes/main
    └── ui/           # Scripts de los componentes de scenes/ui
```

## Decisiones técnicas

- **Resolución base 1280×720 (horizontal)** con escalado `canvas_items` y aspecto `expand`:
  la interfaz se adapta a PC, tabletas y teléfonos sin deformarse.
- **Renderizador Compatibility** (OpenGL): máxima compatibilidad con equipos escolares, móviles y web.
- **`SceneManager`** (autoload): centraliza las rutas de las pantallas y los cambios con transición de fundido.
- **Tema global** (`assets/themes/main_theme.tres`): colores y estilos definidos en un solo lugar.
  Variaciones disponibles: `TitleLabel`, `SubtitleLabel`, `HeadingLabel`, `HintLabel`, `PrimaryButton`.
- Sin plugins ni dependencias externas.

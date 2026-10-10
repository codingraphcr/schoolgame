# Sonidos de Nullveil

- **Efectos:** deja el archivo en `sfx/` con el nombre del efecto (`jump.wav`, `bit_pickup.ogg`…).
  Mientras no exista, el juego usa un sonido provisional generado por código
  (`systems/audio/sfx.gd`, lista `RECIPES`, donde están todos los nombres).
- **Voces de diálogo:** `voice_kai`, `voice_profesor` y `voice_amenaza` son la «sílaba» que suena
  cada pocas letras cuando habla ese personaje. Un archivo corto (0,05–0,1 s) con ese nombre la reemplaza.
- **Música:** deja la pista en `music/` en bucle: `menu.ogg`, `colegio.ogg`, `computadora.ogg`, `pelea.ogg`.
  Mientras no exista, no suena música.

Formatos: `.wav`, `.ogg` o `.mp3`. Los volúmenes se ajustan en Opciones (General, Música, Efectos).

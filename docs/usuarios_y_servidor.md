# Cuentas de jugador y partidas en línea

Cada jugador tiene **su cuenta** (un apodo único + contraseña) y **su partida**, que puede seguir desde cualquier
dispositivo. Nadie puede ver ni cargar la partida de otro, y ni siquiera el servidor puede leerla. Decisión del
equipo (13 de octubre de 2026): el juego **ya no es offline**; las cuentas viven en un servidor.

## Las piezas

| Pieza | Archivo | Qué hace |
|---|---|---|
| Servidor | `server/nullveil_server.py` | Cuentas, sesiones y partidas (Python, solo biblioteca estándar, SQLite). Guía en `server/README.md` |
| `Profiles` (autoload) | `autoload/profiles.gd` | Crear cuenta, entrar, salir, recuperar, subir y bajar la partida |
| `ApiClient` | `systems/net/api_client.gd` | Pedidos JSON al servidor; solo HTTPS (salvo esta computadora, para desarrollar) |
| `KeyDerivation` | `systems/security/key_derivation.gd` | Huella lenta (PBKDF2) y cifrado de claves (AES-256) |
| `SaveManager` | `autoload/save_manager.gd` | La partida de la cuenta, cifrada; avisa al guardar (`saved`) para subirla |
| `LoginPanel` | `ui/menus/login/login_panel.gd` | Pantalla de inicio de sesión del menú |
| `LocalServer` | `systems/net/local_server.gd` | Desde el editor, prende el servidor local si no está prendido |

## Crear cuenta y entrar

- **Inicio de sesión** en el menú principal, sin lista de usuarios. Modos: entrar, crear usuario, olvidé mi
  contraseña. Flechas y Enter para moverse; los campos se sanitizan al escribir (sin pegar ni arrastrar).
- **Crear usuario:**
  - Nombre de 3 a 16 caracteres: letras sin tilde, números y `_` (el servidor exige lo mismo). Se recomienda un
    apodo, no el nombre real.
  - Al salir del campo del nombre, el juego le pregunta al servidor y avisa **«Ese nombre de usuario ya existe.»**
    (o que está libre). Los nombres son únicos **en todos los dispositivos** y no distinguen mayúsculas
    (`Yohann11` = `yohann11`).
  - **Contraseña** con las reglas que enseña el juego (`PasswordRules`) y sin el nombre de usuario; se escribe dos
    veces.
  - Al terminar, el juego muestra el **código de respaldo** para anotarlo.
- **Entrar:** el mismo mensaje si el usuario no existe o la contraseña está mal. Después de 5 intentos fallidos,
  la cuenta espera 30 s (y el doble con cada error extra, hasta 15 min). Al entrar se baja la partida del servidor.
- **Olvidé mi contraseña:** con el código de respaldo se elige una contraseña nueva. La partida se conserva, se
  entrega un código nuevo (el anterior deja de servir) y se cierran las sesiones abiertas en otros dispositivos.
- **Cerrar sesión** (abajo a la izquierda del menú): se borra la clave de la memoria y el progreso.
- **La partida de antes de las cuentas** (`user://partida.json`) pasa, cifrada, a la cuenta que se cree en ese
  dispositivo, y se sube. Así Yohann11 conserva su partida.

## Cómo se protege

1. **La contraseña nunca sale del juego.** De ella se derivan (PBKDF2-HMAC-SHA256, 30 000 vueltas) una *clave de
   acceso*, que es lo único que se manda al servidor (y este la vuelve a «hashear» con scrypt), y una *clave para
   envolver*, que nunca se manda.
2. **Cada cuenta tiene una clave de datos al azar que cifra su partida (AES-256) antes de subirla.** El servidor
   guarda la partida y la clave de datos *envuelta* (con la contraseña y con el código de respaldo), pero no puede
   abrir ninguna de las dos.
3. **Sesiones:** token al azar por HTTPS; el servidor solo entrega la partida de esa cuenta.
4. **En el dispositivo** queda una copia cifrada de la partida (en una carpeta con el código de la cuenta, no con
   el nombre), por si se corta la conexión al guardar; se sube en cuanto se puede.
5. **Varios dispositivos:** cada guardado sube una versión nueva. Se juega en un dispositivo a la vez; si otro
   guardó antes, gana la partida más nueva.

Pruebas: `server/test_server.py` (11 pruebas del servidor) y `tests/test_profiles.gd` (las cuentas desde el juego,
con dos dispositivos simulados); también `test_menu_navigation.gd` y `test_save.gd`. Las del juego prenden su
propio servidor de prueba (necesitan Python 3).

## Pendiente (lo decide el equipo)

- **Dónde publicar el servidor** (una computadora del colegio o un servidor alquilado) y su dirección con HTTPS;
  ver `server/README.md`.
- **Ley 8968** (protección de datos personales, Costa Rica) y permiso de los padres, antes de usarlo con alumnos.
- Borrar la cuenta desde el juego (el servidor ya lo permite: `DELETE /api/cuenta`).

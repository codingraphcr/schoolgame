# Servidor de cuentas de Nullveil

Guarda las **cuentas de los jugadores** (apodo único + contraseña) y **su partida**, para seguirla desde cualquier
dispositivo. Es un solo archivo de Python (`nullveil_server.py`) que usa solo la biblioteca estándar: no hay que
instalar paquetes. Los datos van en una base SQLite.

## Para desarrollar

No hay que hacer nada: al jugar **desde el editor de Godot**, si el servidor de esta computadora no responde, el
juego lo prende solo (`LocalServer`) con una base de desarrollo en la carpeta de datos del juego. Necesita
**Python 3** instalado (en Windows: `python` o `py`).

Para prenderlo a mano:

```
python server/nullveil_server.py --port 8787 --db server/datos/nullveil.db
```

Pruebas del servidor: `python server/test_server.py` · Pruebas del juego con el servidor: `test_profiles.gd`.

## Qué protege

- **La contraseña nunca llega al servidor.** El juego deriva de ella una clave de acceso (PBKDF2) y el servidor
  la vuelve a «hashear» con **scrypt** y sal al azar.
- **La partida llega cifrada (AES-256)** desde el juego: el servidor la guarda sin poder leerla.
- **Sesiones** con un token al azar (en la base solo su huella SHA-256), que vence en 30 días; máximo 5 sesiones
  abiertas por cuenta. Cambiar la contraseña cierra todas.
- **Cada cuenta solo lee y escribe su partida.** Sin sesión válida no se entrega nada.
- **Contra ataques:** bloqueo de la cuenta tras 5 intentos fallidos (30 s, luego el doble, hasta 15 min), límite
  de pedidos por IP (alto, porque un colegio entero sale con una sola IP), tamaño máximo de pedido y de partida,
  validación estricta de cada campo, consultas SQL con parámetros (sin inyección), y errores que no revelan si una
  cuenta existe al entrar. El registro del servidor no guarda datos de los jugadores.
- **Varios dispositivos:** cada partida tiene una versión. Si dos dispositivos guardan, gana la más nueva (se juega
  en uno a la vez).

## Publicarlo (lo decide y lo hace el equipo)

1. **Dónde:** una computadora del colegio siempre prendida, o un servidor alquilado (VPS) con Linux.
2. **HTTPS obligatorio.** El servidor escucha solo en `127.0.0.1`; delante va un proxy con certificado, por
   ejemplo **Caddy** (renueva el certificado solo):

   ```
   juego.ejemplo.cr {
       reverse_proxy 127.0.0.1:8787
   }
   ```
3. **Que arranque solo** (por ejemplo con un servicio de `systemd`) y **respaldos diarios** de la carpeta `datos/`.
4. **En el juego:** poner la dirección en *Proyecto → Configuración del proyecto → nullveil/servidor/url*
   (por ejemplo `https://juego.ejemplo.cr`). El juego se niega a conectarse sin HTTPS, salvo a esta misma
   computadora.
5. **Datos de menores:** solo se guarda el apodo (se pide no usar el nombre real). Antes de usarlo con alumnos,
   consultar con el colegio o el MEP la **Ley 8968** (protección de datos personales) y el permiso de los padres.

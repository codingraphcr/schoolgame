# Cómo probar la última versión del juego (guía para el supervisor)

No hace falta instalar Godot ni nada de programación: se baja un archivo ZIP, se descomprime y se abre el juego.
Funciona en **Windows 10 u 11 de 64 bits**.

## 1. Entrar al repositorio

1. Abre <https://github.com/codingraphcr/schoolgame> e inicia sesión con tu cuenta de GitHub
   (botón **Sign in**, arriba a la derecha).
2. Si el repositorio es privado y no lo ves, pídele al equipo que te agregue como colaborador
   (con permiso de lectura). Te llegará un correo de GitHub para aceptar la invitación.

## 2. Encontrar la última versión

1. Arriba, entra a la pestaña **Actions**.
2. A la izquierda, elige **Versión de prueba (Windows)**.
3. En la lista, busca la ejecución más reciente con el **círculo verde ✔** (las de la ✘ roja fallaron: esas no
   sirven).
4. Haz clic en su título.

## 3. Descargar el juego

1. Baja hasta la sección **Artifacts**.
2. Haz clic en el archivo que se llama así: **Nullveil-windows-v0.1.0-abc1234** (las letras del final cambian en
   cada versión). Se descarga un ZIP.
   - Los archivos se guardan **30 días**; después hay que bajar una versión más nueva.

## 4. Descomprimir y abrir

1. En la carpeta de **Descargas**, haz clic derecho sobre el ZIP → **Extraer todo…** → **Extraer**.
2. Dentro de la carpeta nueva hay dos archivos: **Nullveil.exe** (el juego) y **VERSION.txt** (qué versión es).
3. Haz doble clic en **Nullveil.exe**.
4. La primera vez, Windows puede mostrar **«Windows protegió su PC»**: es porque el juego todavía no tiene firma
   digital. Haz clic en **Más información** → **Ejecutar de todas formas**.

Para probar una versión nueva, repite los pasos y abre el `Nullveil.exe` nuevo (puedes borrar la carpeta vieja).

## 5. Las partidas guardadas

- Se guardan en tu computadora, **fuera** de la carpeta del juego: al cambiar de versión **no se pierden**.
- Están en `%APPDATA%\Nullveil\partidas` (pega esa ruta en la barra del Explorador de archivos para verlas).
  Si jugaste una versión anterior, la primera vez el juego copia ahí tus partidas y opciones de la carpeta
  vieja (`%APPDATA%\Godot\app_userdata\Nullveil- Beyond the Firewall`), que queda intacta.
- Puedes tener hasta **3 partidas**. Desde el menú: **Nueva partida**, **Cargar partida** o **Continuar**.
- El juego guarda solo al avanzar en la historia, al obtener habilidades y en las computadoras seguras (tecla **E**).

## 6. Reportar un error

Envía al equipo:

1. **Qué estabas haciendo** y **qué pasó** (y qué esperabas que pasara).
2. Una **captura de pantalla**, si puedes (tecla **Impr Pant** o **Windows + Shift + S**).
3. El contenido de **VERSION.txt** (dice la versión, el commit y la fecha exacta de esa compilación).
4. Si el juego se cerró solo, el registro: `%APPDATA%\Nullveil\logs\godot.log`.

## Controles básicos

Moverse: **A / D** o flechas · Saltar: **Espacio** · Dash: **Shift** · Atacar: **J** · Curarse: **L** (mantener) ·
Interactuar: **E** · Visión Digital: **Q** ·
Grimorio: **G** · Menú: **Esc**. Todo se puede cambiar en **Opciones**.

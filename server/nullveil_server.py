"""Servidor de cuentas y partidas de Nullveil: Beyond the Firewall.

Cuentas de jugador (apodo único + contraseña) y su partida, para seguirla desde cualquier dispositivo.
Solo usa la biblioteca estándar de Python (sin paquetes externos).

Seguridad:
  * El servidor nunca recibe la contraseña real. El juego deriva de ella una «clave de acceso» (PBKDF2,
    ver systems/security/key_derivation.gd) y manda solo eso; aquí se vuelve a «hashear» con scrypt.
  * La partida llega cifrada desde el juego (AES-256): el servidor la guarda sin poder leerla.
  * Cada sesión es un token al azar; en la base solo se guarda su huella (SHA-256). Vence en 30 días.
  * Cada cuenta solo puede leer y escribir su propia partida.
  * Límite de pedidos por IP, bloqueo de la cuenta tras varios intentos fallidos, tamaño máximo de los
    pedidos, validación estricta de cada campo y mensajes de error que no revelan datos de otros.
  * En producción va detrás de un proxy con HTTPS (ver server/README.md). Por defecto solo escucha en
    127.0.0.1.

Uso:  python server/nullveil_server.py --port 8787 --db server/datos/nullveil.db
"""

from __future__ import annotations

import argparse
import base64
import contextlib
import hashlib
import hmac
import json
import os
import re
import secrets
import sqlite3
import threading
import time
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

API_VERSION = 1
NAME_RE = re.compile(r"^[A-Za-z0-9_]{3,16}$")
HEX64_RE = re.compile(r"^[0-9a-f]{64}$")
HEX32_RE = re.compile(r"^[0-9a-f]{32}$")
B64_RE = re.compile(r"^[A-Za-z0-9+/=]*$")

MAX_BODY = 400_000            # bytes de un pedido
MAX_SAVE = 300_000            # caracteres base64 de una partida
TOKEN_DAYS = 30
MAX_SESSIONS = 5              # sesiones abiertas por cuenta (se cierran las más viejas)
MAX_FAILS = 5                 # intentos fallidos antes de esperar
BASE_LOCK = 30                # segundos de espera; se duplica con cada error extra
MAX_LOCK = 900
RECOVERY_TICKET_SECONDS = 300
SCRYPT = {"n": 2 ** 14, "r": 8, "p": 1, "dklen": 32}

# Pedidos por minuto y por IP.
RATE_AUTH = 120               # registro, sesión, recuperación, disponible (un colegio entero sale con una sola IP)
RATE_GENERAL = 1200


def _now() -> int:
    return int(time.time())


def _hash_secret(secret_hex: str, salt: bytes) -> bytes:
    return hashlib.scrypt(bytes.fromhex(secret_hex), salt=salt, **SCRYPT)


def _token_digest(token: str) -> str:
    return hashlib.sha256(token.encode("ascii")).hexdigest()


class Store:
    """Base de datos SQLite (una conexión por pedido)."""

    def __init__(self, path: str) -> None:
        self.path = path
        folder = os.path.dirname(os.path.abspath(path))
        os.makedirs(folder, exist_ok=True)
        with self.connect() as db:
            db.executescript(
                """
                PRAGMA journal_mode = WAL;
                CREATE TABLE IF NOT EXISTS cuentas (
                    id TEXT PRIMARY KEY,
                    nombre TEXT NOT NULL,
                    nombre_clave TEXT NOT NULL UNIQUE,
                    sal TEXT NOT NULL,
                    huella TEXT NOT NULL,
                    sal_respaldo TEXT NOT NULL,
                    huella_respaldo TEXT NOT NULL,
                    envoltorio TEXT NOT NULL,
                    envoltorio_respaldo TEXT NOT NULL,
                    fallos INTEGER NOT NULL DEFAULT 0,
                    bloqueada_hasta INTEGER NOT NULL DEFAULT 0,
                    creada INTEGER NOT NULL
                );
                CREATE TABLE IF NOT EXISTS sesiones (
                    huella_token TEXT PRIMARY KEY,
                    cuenta TEXT NOT NULL REFERENCES cuentas(id) ON DELETE CASCADE,
                    vence INTEGER NOT NULL,
                    creada INTEGER NOT NULL
                );
                CREATE TABLE IF NOT EXISTS partidas (
                    cuenta TEXT PRIMARY KEY REFERENCES cuentas(id) ON DELETE CASCADE,
                    datos TEXT NOT NULL,
                    version INTEGER NOT NULL,
                    actualizada INTEGER NOT NULL
                );
                CREATE TABLE IF NOT EXISTS recuperaciones (
                    huella_permiso TEXT PRIMARY KEY,
                    cuenta TEXT NOT NULL REFERENCES cuentas(id) ON DELETE CASCADE,
                    vence INTEGER NOT NULL
                );
                """
            )

    @contextlib.contextmanager
    def connect(self):
        """Una conexión para un pedido; se cierra siempre al terminar."""
        db = sqlite3.connect(self.path, timeout=10, isolation_level=None)
        db.row_factory = sqlite3.Row
        db.execute("PRAGMA foreign_keys = ON")
        db.execute("PRAGMA busy_timeout = 5000")
        try:
            yield db
        finally:
            if db.in_transaction:
                db.execute("ROLLBACK")
            db.close()


class RateLimiter:
    """Ventana de un minuto por IP y tipo de pedido (en memoria)."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._hits: dict[tuple[str, str], list[float]] = {}

    def allow(self, ip: str, kind: str, limit: int) -> bool:
        now = time.monotonic()
        with self._lock:
            hits = [t for t in self._hits.get((ip, kind), []) if now - t < 60]
            if len(hits) >= limit:
                self._hits[(ip, kind)] = hits
                return False
            hits.append(now)
            self._hits[(ip, kind)] = hits
            return True


class ApiError(Exception):
    def __init__(self, status: int, code: str, extra: dict | None = None) -> None:
        super().__init__(code)
        self.status = status
        self.code = code
        self.extra = extra or {}


def _wrapper_ok(value) -> bool:
    return (isinstance(value, dict) and set(value) == {"iv", "datos"}
            and isinstance(value["iv"], str) and HEX32_RE.match(value["iv"])
            and isinstance(value["datos"], str) and HEX64_RE.match(value["datos"]))


class Api:
    """La lógica de cada ruta, separada del HTTP para poder probarla."""

    def __init__(self, store: Store) -> None:
        self.store = store

    # --- Ayudas ---

    @staticmethod
    def _name(body: dict) -> str:
        name = body.get("usuario")
        if not isinstance(name, str) or not NAME_RE.match(name):
            raise ApiError(400, "nombre_invalido")
        return name

    @staticmethod
    def _hex64(body: dict, key: str) -> str:
        value = body.get(key)
        if not isinstance(value, str) or not HEX64_RE.match(value):
            raise ApiError(400, "datos_invalidos")
        return value

    def _new_session(self, db: sqlite3.Connection, account: str) -> dict:
        token = secrets.token_urlsafe(32)
        expires = _now() + TOKEN_DAYS * 86400
        db.execute("INSERT INTO sesiones VALUES (?, ?, ?, ?)", (_token_digest(token), account, expires, _now()))
        # Solo las MAX_SESSIONS más nuevas siguen abiertas.
        db.execute(
            "DELETE FROM sesiones WHERE cuenta = ? AND huella_token NOT IN "
            "(SELECT huella_token FROM sesiones WHERE cuenta = ? ORDER BY creada DESC, rowid DESC LIMIT ?)",
            (account, account, MAX_SESSIONS))
        return {"token": token, "vence": expires}

    def account_for_token(self, db: sqlite3.Connection, token: str | None) -> str:
        if not token or len(token) > 100:
            raise ApiError(401, "sesion_invalida")
        row = db.execute("SELECT cuenta, vence FROM sesiones WHERE huella_token = ?", (_token_digest(token),)).fetchone()
        if row is None or row["vence"] < _now():
            raise ApiError(401, "sesion_invalida")
        return row["cuenta"]

    @staticmethod
    def _check_lock(row: sqlite3.Row) -> None:
        wait = row["bloqueada_hasta"] - _now()
        if wait > 0:
            raise ApiError(429, "bloqueada", {"espera": wait})

    @staticmethod
    def _fail(db: sqlite3.Connection, row: sqlite3.Row, code: str) -> None:
        fails = row["fallos"] + 1
        locked = row["bloqueada_hasta"]
        extra = fails - MAX_FAILS
        if extra >= 0:
            locked = _now() + min(BASE_LOCK * (2 ** extra), MAX_LOCK)
        db.execute("UPDATE cuentas SET fallos = ?, bloqueada_hasta = ? WHERE id = ?", (fails, locked, row["id"]))
        if extra >= 0:
            raise ApiError(429, "bloqueada", {"espera": locked - _now()})
        raise ApiError(401, code)

    # --- Rutas ---

    def available(self, body: dict) -> dict:
        name = self._name(body)
        with self.store.connect() as db:
            row = db.execute("SELECT 1 FROM cuentas WHERE nombre_clave = ?", (name.lower(),)).fetchone()
        return {"disponible": row is None}

    def register(self, body: dict) -> dict:
        name = self._name(body)
        secret = self._hex64(body, "clave")
        backup = self._hex64(body, "respaldo")
        wrappers = body.get("envoltorios")
        if not isinstance(wrappers, dict) or not _wrapper_ok(wrappers.get("clave")) or not _wrapper_ok(wrappers.get("respaldo")):
            raise ApiError(400, "datos_invalidos")
        salt, backup_salt = secrets.token_bytes(16), secrets.token_bytes(16)
        account = secrets.token_hex(12)
        with self.store.connect() as db:
            try:
                db.execute("BEGIN IMMEDIATE")
                db.execute(
                    "INSERT INTO cuentas (id, nombre, nombre_clave, sal, huella, sal_respaldo, huella_respaldo, "
                    "envoltorio, envoltorio_respaldo, creada) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    (account, name, name.lower(), salt.hex(), _hash_secret(secret, salt).hex(), backup_salt.hex(),
                     _hash_secret(backup, backup_salt).hex(), json.dumps(wrappers["clave"]),
                     json.dumps(wrappers["respaldo"]), _now()))
                session = self._new_session(db, account)
                db.execute("COMMIT")
            except sqlite3.IntegrityError:
                db.execute("ROLLBACK")
                raise ApiError(409, "nombre_existe")
        return {"cuenta": account, **session}

    def login(self, body: dict) -> dict:
        name = self._name(body) if isinstance(body.get("usuario"), str) and NAME_RE.match(body["usuario"]) else None
        secret = self._hex64(body, "clave")
        with self.store.connect() as db:
            row = db.execute("SELECT * FROM cuentas WHERE nombre_clave = ?", ((name or "").lower(),)).fetchone() if name else None
            if row is None:
                # Tarda lo mismo que un intento real y responde igual: no revela qué cuentas existen.
                _hash_secret(secret, b"\0" * 16)
                raise ApiError(401, "credenciales")
            self._check_lock(row)
            if not hmac.compare_digest(_hash_secret(secret, bytes.fromhex(row["sal"])).hex(), row["huella"]):
                self._fail(db, row, "credenciales")
            db.execute("UPDATE cuentas SET fallos = 0, bloqueada_hasta = 0 WHERE id = ?", (row["id"],))
            session = self._new_session(db, row["id"])
        return {"cuenta": row["id"], "nombre": row["nombre"], "envoltorio": json.loads(row["envoltorio"]), **session}

    def logout(self, token: str | None) -> dict:
        with self.store.connect() as db:
            self.account_for_token(db, token)
            db.execute("DELETE FROM sesiones WHERE huella_token = ?", (_token_digest(token),))
        return {"ok": True}

    def get_save(self, token: str | None) -> dict:
        with self.store.connect() as db:
            account = self.account_for_token(db, token)
            row = db.execute("SELECT datos, version, actualizada FROM partidas WHERE cuenta = ?", (account,)).fetchone()
        if row is None:
            raise ApiError(404, "sin_partida")
        return {"partida": row["datos"], "version": row["version"], "actualizada": row["actualizada"]}

    def put_save(self, token: str | None, body: dict) -> dict:
        data = body.get("partida")
        base = body.get("version_base")
        if (not isinstance(data, str) or not data or len(data) > MAX_SAVE or not B64_RE.match(data)
                or not isinstance(base, int) or isinstance(base, bool) or base < 0):
            raise ApiError(400, "datos_invalidos")
        try:
            base64.b64decode(data, validate=True)
        except ValueError:
            raise ApiError(400, "datos_invalidos")
        with self.store.connect() as db:
            account = self.account_for_token(db, token)
            db.execute("BEGIN IMMEDIATE")
            row = db.execute("SELECT version FROM partidas WHERE cuenta = ?", (account,)).fetchone()
            current = row["version"] if row else 0
            if base != current:
                db.execute("ROLLBACK")
                raise ApiError(409, "conflicto", {"version": current})
            db.execute(
                "INSERT INTO partidas (cuenta, datos, version, actualizada) VALUES (?, ?, ?, ?) "
                "ON CONFLICT(cuenta) DO UPDATE SET datos = excluded.datos, version = excluded.version, "
                "actualizada = excluded.actualizada", (account, data, current + 1, _now()))
            db.execute("COMMIT")
        return {"version": current + 1}

    def recover_start(self, body: dict) -> dict:
        name = self._name(body)
        backup = self._hex64(body, "respaldo")
        with self.store.connect() as db:
            row = db.execute("SELECT * FROM cuentas WHERE nombre_clave = ?", (name.lower(),)).fetchone()
            if row is None:
                _hash_secret(backup, b"\0" * 16)
                raise ApiError(401, "respaldo_incorrecto")
            self._check_lock(row)
            if not hmac.compare_digest(_hash_secret(backup, bytes.fromhex(row["sal_respaldo"])).hex(), row["huella_respaldo"]):
                self._fail(db, row, "respaldo_incorrecto")
            ticket = secrets.token_urlsafe(32)
            db.execute("DELETE FROM recuperaciones WHERE cuenta = ? OR vence < ?", (row["id"], _now()))
            db.execute("INSERT INTO recuperaciones VALUES (?, ?, ?)",
                       (_token_digest(ticket), row["id"], _now() + RECOVERY_TICKET_SECONDS))
        return {"permiso": ticket, "envoltorio_respaldo": json.loads(row["envoltorio_respaldo"])}

    def recover_finish(self, body: dict) -> dict:
        ticket = body.get("permiso")
        secret = self._hex64(body, "clave")
        backup = self._hex64(body, "respaldo")
        wrappers = body.get("envoltorios")
        if (not isinstance(ticket, str) or len(ticket) > 100 or not isinstance(wrappers, dict)
                or not _wrapper_ok(wrappers.get("clave")) or not _wrapper_ok(wrappers.get("respaldo"))):
            raise ApiError(400, "datos_invalidos")
        salt, backup_salt = secrets.token_bytes(16), secrets.token_bytes(16)
        with self.store.connect() as db:
            db.execute("BEGIN IMMEDIATE")
            row = db.execute("SELECT cuenta, vence FROM recuperaciones WHERE huella_permiso = ?", (_token_digest(ticket),)).fetchone()
            if row is None or row["vence"] < _now():
                db.execute("ROLLBACK")
                raise ApiError(401, "permiso_invalido")
            account = row["cuenta"]
            db.execute("DELETE FROM recuperaciones WHERE cuenta = ?", (account,))
            db.execute(
                "UPDATE cuentas SET sal = ?, huella = ?, sal_respaldo = ?, huella_respaldo = ?, envoltorio = ?, "
                "envoltorio_respaldo = ?, fallos = 0, bloqueada_hasta = 0 WHERE id = ?",
                (salt.hex(), _hash_secret(secret, salt).hex(), backup_salt.hex(), _hash_secret(backup, backup_salt).hex(),
                 json.dumps(wrappers["clave"]), json.dumps(wrappers["respaldo"]), account))
            # Con la contraseña nueva, las sesiones viejas dejan de servir.
            db.execute("DELETE FROM sesiones WHERE cuenta = ?", (account,))
            session = self._new_session(db, account)
            db.execute("COMMIT")
            name = db.execute("SELECT nombre FROM cuentas WHERE id = ?", (account,)).fetchone()["nombre"]
        return {"cuenta": account, "nombre": name, **session}

    def delete_account(self, token: str | None, body: dict) -> dict:
        secret = self._hex64(body, "clave")
        with self.store.connect() as db:
            account = self.account_for_token(db, token)
            row = db.execute("SELECT * FROM cuentas WHERE id = ?", (account,)).fetchone()
            if not hmac.compare_digest(_hash_secret(secret, bytes.fromhex(row["sal"])).hex(), row["huella"]):
                raise ApiError(401, "credenciales")
            db.execute("DELETE FROM cuentas WHERE id = ?", (account,))
        return {"ok": True}


def make_handler(api: Api, limiter: RateLimiter):
    class Handler(BaseHTTPRequestHandler):
        server_version = "Nullveil"
        sys_version = ""

        def log_message(self, fmt: str, *args) -> None:  # Sin datos de los jugadores en el registro.
            pass

        def _send(self, status: int, payload: dict) -> None:
            body = json.dumps(payload).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.end_headers()
            self.wfile.write(body)

        def _body(self) -> dict:
            length = self.headers.get("Content-Length")
            if length is None or not length.isdigit() or int(length) > MAX_BODY:
                raise ApiError(413 if length and length.isdigit() else 411, "pedido_invalido")
            if not (self.headers.get("Content-Type") or "").startswith("application/json"):
                raise ApiError(415, "pedido_invalido")
            try:
                data = json.loads(self.rfile.read(int(length)).decode("utf-8"))
            except (UnicodeDecodeError, json.JSONDecodeError):
                raise ApiError(400, "json_invalido")
            if not isinstance(data, dict):
                raise ApiError(400, "json_invalido")
            return data

        def _token(self) -> str | None:
            auth = self.headers.get("Authorization") or ""
            return auth[7:] if auth.startswith("Bearer ") else None

        def _route(self, method: str) -> None:
            ip = self.client_address[0]
            path = self.path.split("?", 1)[0]
            auth_routes = {"/api/registro", "/api/sesion", "/api/usuarios/disponible", "/api/recuperar/inicio", "/api/recuperar/fin"}
            try:
                if not limiter.allow(ip, "general", RATE_GENERAL):
                    raise ApiError(429, "demasiados_pedidos")
                if path in auth_routes and not limiter.allow(ip, "auth", RATE_AUTH):
                    raise ApiError(429, "demasiados_pedidos")
                routes = {
                    ("GET", "/api/salud"): lambda: {"ok": True, "version": API_VERSION},
                    ("POST", "/api/usuarios/disponible"): lambda: api.available(self._body()),
                    ("POST", "/api/registro"): lambda: api.register(self._body()),
                    ("POST", "/api/sesion"): lambda: api.login(self._body()),
                    ("POST", "/api/sesion/cerrar"): lambda: api.logout(self._token()),
                    ("GET", "/api/partida"): lambda: api.get_save(self._token()),
                    ("PUT", "/api/partida"): lambda: api.put_save(self._token(), self._body()),
                    ("POST", "/api/recuperar/inicio"): lambda: api.recover_start(self._body()),
                    ("POST", "/api/recuperar/fin"): lambda: api.recover_finish(self._body()),
                    ("DELETE", "/api/cuenta"): lambda: api.delete_account(self._token(), self._body()),
                }
                action = routes.get((method, path))
                if action is None:
                    raise ApiError(404, "no_existe")
                status = 201 if (method, path) == ("POST", "/api/registro") else 200
                self._send(status, action())
            except ApiError as error:
                self._send(error.status, {"error": error.code, **error.extra})
            except Exception:  # Nunca se muestra el detalle interno.
                self._send(500, {"error": "interno"})

        def do_GET(self) -> None:
            self._route("GET")

        def do_POST(self) -> None:
            self._route("POST")

        def do_PUT(self) -> None:
            self._route("PUT")

        def do_DELETE(self) -> None:
            self._route("DELETE")

    return Handler


def make_server(host: str, port: int, db_path: str) -> ThreadingHTTPServer:
    api = Api(Store(db_path))
    server = ThreadingHTTPServer((host, port), make_handler(api, RateLimiter()))
    server.daemon_threads = True
    return server


def main() -> None:
    parser = argparse.ArgumentParser(description="Servidor de cuentas de Nullveil")
    parser.add_argument("--host", default="127.0.0.1", help="por defecto solo esta computadora")
    parser.add_argument("--port", type=int, default=8787)
    parser.add_argument("--db", default=os.path.join(os.path.dirname(__file__), "datos", "nullveil.db"))
    args = parser.parse_args()
    server = make_server(args.host, args.port, args.db)
    print("Servidor de Nullveil en http://%s:%d (Ctrl+C para cerrar)" % (args.host, args.port), flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()

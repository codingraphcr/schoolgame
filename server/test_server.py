"""Pruebas automáticas del servidor de Nullveil (solo biblioteca estándar).

Ejecutar:  python server/test_server.py
Levanta el servidor en un puerto libre con una base de datos temporal; nunca toca la base real.
"""

import base64
import http.client
import json
import os
import secrets
import sys
import tempfile
import threading
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nullveil_server as ns  # noqa: E402


def key() -> str:
    return secrets.token_hex(32)


def wrappers() -> dict:
    return {"clave": {"iv": secrets.token_hex(16), "datos": secrets.token_hex(32)},
            "respaldo": {"iv": secrets.token_hex(16), "datos": secrets.token_hex(32)}}


class ServerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.folder = tempfile.TemporaryDirectory()
        ns.RATE_AUTH = 10_000  # Las pruebas hacen muchos pedidos seguidos (el límite se prueba aparte).
        cls.server = ns.make_server("127.0.0.1", 0, os.path.join(cls.folder.name, "prueba.db"))
        cls.port = cls.server.server_address[1]
        threading.Thread(target=cls.server.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.folder.cleanup()

    def call(self, method, path, body=None, token=None, raw=None, headers=None):
        conn = http.client.HTTPConnection("127.0.0.1", self.port, timeout=10)
        data = raw if raw is not None else (json.dumps(body).encode() if body is not None else None)
        h = {"Content-Type": "application/json"}
        if data is not None:
            h["Content-Length"] = str(len(data))
        if token:
            h["Authorization"] = "Bearer " + token
        h.update(headers or {})
        conn.request(method, path, body=data, headers=h)
        response = conn.getresponse()
        payload = json.loads(response.read() or b"{}")
        conn.close()
        return response.status, payload

    def register(self, name, secret=None, backup=None):
        secret = secret or key()
        backup = backup or key()
        status, data = self.call("POST", "/api/registro", {"usuario": name, "clave": secret, "respaldo": backup, "envoltorios": wrappers()})
        return status, data, secret, backup

    # --- Cuentas ---

    def test_register_and_unique_name(self):
        status, data, secret, _ = self.register("Yohann11")
        self.assertEqual(status, 201)
        self.assertIn("token", data)
        status, data, _, _ = self.register("yohann11")
        self.assertEqual((status, data["error"]), (409, "nombre_existe"), "el nombre ya existe (sin importar mayúsculas)")
        self.assertFalse(self.call("POST", "/api/usuarios/disponible", {"usuario": "YOHANN11"})[1]["disponible"])
        self.assertTrue(self.call("POST", "/api/usuarios/disponible", {"usuario": "Libre_99"})[1]["disponible"])

    def test_invalid_input_is_rejected(self):
        for name in ["yo", "a" * 17, "Yohann 11", "../../etc", "x;DROP TABLE", "' OR 1=1 --", "<script>", "ñandú", 5, None]:
            status, data = self.call("POST", "/api/registro", {"usuario": name, "clave": key(), "respaldo": key(), "envoltorios": wrappers()})
            self.assertEqual(status, 400, "nombre rechazado: %r" % (name,))
        for bad_key in ["123456", "z" * 64, key().upper(), "", None]:
            status, _ = self.call("POST", "/api/registro", {"usuario": "Valido_1", "clave": bad_key, "respaldo": key(), "envoltorios": wrappers()})
            self.assertEqual(status, 400, "clave rechazada: %r" % (bad_key,))
        self.assertEqual(self.call("POST", "/api/registro", raw=b"{no es json")[0], 400)
        self.assertEqual(self.call("POST", "/api/registro", raw=b"[]")[0], 400)
        self.assertEqual(self.call("POST", "/api/registro", raw=b"{}", headers={"Content-Type": "text/plain"})[0], 415)
        self.assertEqual(self.call("POST", "/api/registro", raw=b"x" * (ns.MAX_BODY + 1))[0], 413)
        self.assertEqual(self.call("GET", "/api/../../etc/passwd")[0], 404)
        self.assertEqual(self.call("POST", "/api/usuarios/disponible", {"usuario": "Valido_1"})[0], 200, "el servidor sigue andando")

    def test_login_and_generic_errors(self):
        _, _, secret, _ = self.register("Ana_7")
        status, data = self.call("POST", "/api/sesion", {"usuario": "ana_7", "clave": secret})
        self.assertEqual(status, 200)
        self.assertEqual(data["nombre"], "Ana_7")
        self.assertEqual(set(data["envoltorio"]), {"iv", "datos"})
        wrong = self.call("POST", "/api/sesion", {"usuario": "Ana_7", "clave": key()})
        unknown = self.call("POST", "/api/sesion", {"usuario": "NoExiste", "clave": key()})
        self.assertEqual(wrong, unknown, "el mismo error si no existe o la contraseña está mal")

    def test_lockout(self):
        _, _, secret, _ = self.register("Bloq_1")
        for _ in range(ns.MAX_FAILS - 1):
            self.assertEqual(self.call("POST", "/api/sesion", {"usuario": "Bloq_1", "clave": key()})[0], 401)
        status, data = self.call("POST", "/api/sesion", {"usuario": "Bloq_1", "clave": key()})
        self.assertEqual((status, data["error"]), (429, "bloqueada"))
        self.assertGreater(data["espera"], 0)
        self.assertEqual(self.call("POST", "/api/sesion", {"usuario": "Bloq_1", "clave": secret})[0], 429, "ni la correcta entra mientras tanto")

    # --- Partidas ---

    def test_saves_are_private(self):
        _, a, _, _ = self.register("Duena_1")
        _, b, _, _ = self.register("Otro_1")
        blob = base64.b64encode(b"partida-cifrada-de-duena").decode()
        self.assertEqual(self.call("PUT", "/api/partida", {"partida": blob, "version_base": 0}, a["token"]), (200, {"version": 1}))
        self.assertEqual(self.call("GET", "/api/partida", token=a["token"])[1]["partida"], blob)
        self.assertEqual(self.call("GET", "/api/partida", token=b["token"])[0], 404, "otra cuenta no ve esa partida")
        self.assertEqual(self.call("GET", "/api/partida")[0], 401, "sin sesión no se ve nada")
        self.assertEqual(self.call("GET", "/api/partida", token="inventado")[0], 401)
        self.assertEqual(self.call("GET", "/api/partida", token=a["token"][:-2] + "xx")[0], 401, "un token alterado no sirve")

    def test_save_versions_and_conflict(self):
        _, a, _, _ = self.register("Version_1")
        blob = base64.b64encode(b"v1").decode()
        self.call("PUT", "/api/partida", {"partida": blob, "version_base": 0}, a["token"])
        status, data = self.call("PUT", "/api/partida", {"partida": blob, "version_base": 0}, a["token"])
        self.assertEqual((status, data["error"], data["version"]), (409, "conflicto", 1), "otro dispositivo guardó antes")
        self.assertEqual(self.call("PUT", "/api/partida", {"partida": blob, "version_base": 1}, a["token"])[1]["version"], 2)
        for bad in [{"partida": "no base64 !!", "version_base": 2}, {"partida": "", "version_base": 2},
                    {"partida": "A" * (ns.MAX_SAVE + 4), "version_base": 2}, {"partida": blob, "version_base": "2"},
                    {"partida": blob, "version_base": True}, {"partida": blob}]:
            self.assertEqual(self.call("PUT", "/api/partida", bad, a["token"])[0], 400, "partida inválida: %r" % (list(bad),))

    def test_sessions_and_logout(self):
        _, _, secret, _ = self.register("Sesion_1")
        tokens = [self.call("POST", "/api/sesion", {"usuario": "Sesion_1", "clave": secret})[1]["token"] for _ in range(ns.MAX_SESSIONS + 1)]
        self.assertEqual(self.call("GET", "/api/partida", token=tokens[0])[0], 401, "las sesiones más viejas se cierran")
        self.assertEqual(self.call("GET", "/api/partida", token=tokens[-1])[0], 404)
        self.assertEqual(self.call("POST", "/api/sesion/cerrar", token=tokens[-1])[0], 200)
        self.assertEqual(self.call("GET", "/api/partida", token=tokens[-1])[0], 401, "cerrar sesión invalida el token")

    def test_recovery(self):
        _, a, secret, backup = self.register("Recupera_1")
        blob = base64.b64encode(b"mi partida").decode()
        self.call("PUT", "/api/partida", {"partida": blob, "version_base": 0}, a["token"])
        self.assertEqual(self.call("POST", "/api/recuperar/inicio", {"usuario": "Recupera_1", "respaldo": key()})[0], 401)
        status, start = self.call("POST", "/api/recuperar/inicio", {"usuario": "Recupera_1", "respaldo": backup})
        self.assertEqual(status, 200)
        self.assertEqual(set(start["envoltorio_respaldo"]), {"iv", "datos"})
        new_secret, new_backup = key(), key()
        status, done = self.call("POST", "/api/recuperar/fin", {"permiso": start["permiso"], "clave": new_secret, "respaldo": new_backup, "envoltorios": wrappers()})
        self.assertEqual(status, 200)
        self.assertEqual(self.call("GET", "/api/partida", token=done["token"])[1]["partida"], blob, "la partida se conserva")
        self.assertEqual(self.call("GET", "/api/partida", token=a["token"])[0], 401, "las sesiones viejas se cierran")
        self.assertEqual(self.call("POST", "/api/sesion", {"usuario": "Recupera_1", "clave": secret})[0], 401, "la contraseña vieja no sirve")
        self.assertEqual(self.call("POST", "/api/sesion", {"usuario": "Recupera_1", "clave": new_secret})[0], 200)
        self.assertEqual(self.call("POST", "/api/recuperar/fin", {"permiso": start["permiso"], "clave": key(), "respaldo": key(), "envoltorios": wrappers()})[0], 401, "el permiso se usa una sola vez")
        self.assertEqual(self.call("POST", "/api/recuperar/inicio", {"usuario": "Recupera_1", "respaldo": backup})[0], 401, "el código viejo no sirve")

    def test_delete_account(self):
        _, a, secret, _ = self.register("Borrar_1")
        self.assertEqual(self.call("DELETE", "/api/cuenta", {"clave": key()}, a["token"])[0], 401)
        self.assertEqual(self.call("DELETE", "/api/cuenta", {"clave": secret}, a["token"])[0], 200)
        self.assertTrue(self.call("POST", "/api/usuarios/disponible", {"usuario": "Borrar_1"})[1]["disponible"])
        self.assertEqual(self.call("GET", "/api/partida", token=a["token"])[0], 401)

    def test_database_has_no_secrets(self):
        _, _, secret, backup = self.register("Secreto_1")
        with open(os.path.join(self.folder.name, "prueba.db"), "rb") as f:
            raw = f.read()
        self.assertNotIn(secret.encode(), raw, "la base no guarda la clave de acceso, solo su huella")
        self.assertNotIn(backup.encode(), raw)


class RateLimitTest(unittest.TestCase):
    def test_limiter(self):
        limiter = ns.RateLimiter()
        self.assertTrue(all(limiter.allow("1.2.3.4", "auth", 3) for _ in range(3)))
        self.assertFalse(limiter.allow("1.2.3.4", "auth", 3), "el cuarto pedido en un minuto se frena")
        self.assertTrue(limiter.allow("5.6.7.8", "auth", 3), "otra IP no se ve afectada")


if __name__ == "__main__":
    unittest.main(verbosity=2)

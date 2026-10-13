class_name ApiClient
extends Node
## Habla con el servidor de cuentas y partidas (server/nullveil_server.py) por HTTPS.
## Cada pedido es JSON; request_json() devuelve { "status": int, "data": Dictionary }.
## status 0 = no se pudo conectar (sin internet, servidor apagado o dirección no segura).
##
## Solo acepta direcciones https://, salvo la de esta misma computadora (127.0.0.1 o localhost),
## que se usa para desarrollar y en las pruebas.
## La dirección sale de la opción del proyecto "nullveil/servidor/url".

const SETTING := "nullveil/servidor/url"
const DEFAULT_URL := "http://127.0.0.1:8787"
const TIMEOUT := 12.0

var base_url := DEFAULT_URL


func _init(url := "") -> void:
	base_url = url if not url.is_empty() else default_url()


static func default_url() -> String:
	return String(ProjectSettings.get_setting(SETTING, DEFAULT_URL)).trim_suffix("/")


## Solo HTTPS, o HTTP a esta misma computadora (desarrollo).
static func is_secure_url(url: String) -> bool:
	return url.begins_with("https://") or url.begins_with("http://127.0.0.1:") or url.begins_with("http://localhost:")


func is_local() -> bool:
	return base_url.begins_with("http://127.0.0.1:") or base_url.begins_with("http://localhost:")


func request_json(method: HTTPClient.Method, path: String, body: Variant = null, token := "") -> Dictionary:
	if not is_secure_url(base_url):
		push_warning("ApiClient: la dirección del servidor no es segura (%s); se necesita https://." % base_url)
		return { "status": 0, "data": { "error": "url_insegura" } }
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT
	add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	if not token.is_empty():
		headers.append("Authorization: Bearer " + token)
	var payload := JSON.stringify(body) if body != null else ""
	if http.request(base_url + path, headers, method, payload) != OK:
		http.queue_free()
		return { "status": 0, "data": { "error": "sin_conexion" } }
	var result: Array = await http.request_completed
	http.queue_free()
	if int(result[0]) != HTTPRequest.RESULT_SUCCESS:
		return { "status": 0, "data": { "error": "sin_conexion" } }
	var json := JSON.new()
	var data: Variant = {}
	if json.parse((result[3] as PackedByteArray).get_string_from_utf8()) == OK:
		data = json.data
	return { "status": int(result[1]), "data": data if data is Dictionary else {} }


func get_json(path: String, token := "") -> Dictionary:
	return await request_json(HTTPClient.METHOD_GET, path, null, token)


func post_json(path: String, body: Dictionary, token := "") -> Dictionary:
	return await request_json(HTTPClient.METHOD_POST, path, body, token)


func put_json(path: String, body: Dictionary, token := "") -> Dictionary:
	return await request_json(HTTPClient.METHOD_PUT, path, body, token)

class_name PasswordRules
extends RefCounted
## Reglas de una contraseña segura, explicadas al jugador (el medidor de PasswordWindow).
## evaluate() revisa cada regla y estima la fortaleza; suggest() arma una frase de contraseña al azar.
## Todo es local: la contraseña nunca sale del juego ni se guarda en texto (ver GameState.set_password).

## Contraseñas de las más usadas del mundo y comunes en español (se comparan sin mayúsculas y
## deshaciendo los cambios típicos de letras por símbolos: @→a, 0→o, 1→i, 3→e, $→s…).
const COMMON := ["123456", "1234567", "12345678", "123456789", "1234567890", "111111", "000000", "123123",
	"654321", "112233", "121212", "qwerty", "qwertyuiop", "asdfgh", "zxcvbnm", "password", "passw0rd", "contrasena",
	"contraseña", "clave", "secreto", "iloveyou", "teamo", "teamomucho", "admin", "administrador", "abc123",
	"letmein", "welcome", "bienvenido", "monkey", "dragon", "football", "futbol", "soccer", "princess",
	"princesa", "sunshine", "master", "superman", "batman", "pokemon", "minecraft", "roblox", "fortnite",
	"hola", "hola123", "holamundo", "colegio", "escuela", "estudiante", "profesor", "usuario", "costarica",
	"saprissa", "liga", "mama", "papa", "familia", "amor", "dios", "jesus", "maria", "nombre", "cumple"]
## Datos personales del contexto (no deben aparecer en la contraseña).
const PERSONAL := ["alvarado", "profesor", "profe", "colegio", "kai", "nullveil", "1985", "2026"]
## Palabras para sugerir frases de contraseña (sin tildes para escribirlas fácil en cualquier teclado).
const WORDS := ["tiza", "ventana", "cometa", "mango", "nube", "cactus", "tambor", "linterna", "volcan", "pinguino",
	"guitarra", "brocoli", "satelite", "canoa", "girasol", "tortuga", "pizarra", "trompo", "galleta", "faro",
	"cangrejo", "mochila", "cohete", "ciruela", "bufanda", "relampago", "colibri", "tobogan", "naranja", "iglu",
	"murcielago", "papaya", "brujula", "escalera", "tucan", "almohada", "zapato", "planeta", "trueno", "lapiz"]
const MIN_LENGTH := 14
const MIN_WORDS := 4
const MAX_LENGTH := 64
## Símbolos permitidos en una contraseña. Todo lo que parece código o etiquetas (< > [ ] { } " ' `
## \ |), los saltos de línea, tabulaciones y caracteres invisibles se quitan (sanitize).
const ALLOWED_SYMBOLS := " !@#$%^&*()-_=+.,;:?/~"

const LEVEL_NAMES: PackedStringArray = ["Muy débil", "Débil", "Aceptable", "Fuerte", "Muy fuerte"]


## Deja solo los caracteres permitidos en una contraseña: letras (también ñ y con tilde), números y
## ALLOWED_SYMBOLS, hasta MAX_LENGTH. La contraseña nunca se ejecuta ni se interpreta: solo se
## calcula su huella; esto además impide escribir código, etiquetas o caracteres de control.
static func sanitize(text: String) -> String:
	var clean := ""
	for character in text:
		if is_allowed_character(character):
			clean += character
	return clean.left(MAX_LENGTH)


## Si es una contraseña aceptable para guardar: no vacía, sin caracteres prohibidos y no muy larga.
static func is_clean(text: String) -> bool:
	return not text.is_empty() and text.length() <= MAX_LENGTH and sanitize(text) == text


static func is_allowed_character(character: String) -> bool:
	if character.length() != 1:
		return false
	var code := character.unicode_at(0)
	if code < 32 or (code >= 127 and code < 160):
		return false  # Caracteres de control e invisibles.
	if character in ALLOWED_SYMBOLS or (code >= 48 and code <= 57):
		return true
	# Letras de cualquier alfabeto (también ñ, á, ü…): tienen mayúscula y minúscula distintas.
	return character.to_lower() != character.to_upper()


## Revisa la contraseña. Devuelve:
##   rules: [{ "id", "text", "ok" }, ...] (las 4 reglas, en orden)
##   valid: todas se cumplen
##   level: 0–4 (LEVEL_NAMES)   bits: fortaleza estimada   time: tiempo estimado para adivinarla
static func evaluate(password: String, extra_personal: PackedStringArray = []) -> Dictionary:
	var lowered := password.to_lower()
	var normalized := _normalize(lowered)
	var words := _words(lowered)
	var long_enough := password.length() >= MIN_LENGTH or (words.size() >= MIN_WORDS and password.length() >= 12)
	var common := _is_common(lowered)
	var personal := false
	for word in PERSONAL + Array(extra_personal):
		if not String(word).is_empty() and (lowered.contains(word) or normalized.contains(_normalize(word))):
			personal = true
	var patterned := _is_patterned(lowered)
	var rules: Array[Dictionary] = [
		{ "id": "largo", "text": "Larga: al menos %d caracteres (o %d palabras)" % [MIN_LENGTH, MIN_WORDS], "ok": long_enough },
		{ "id": "comun", "text": "No es de las más usadas (tampoco con trucos como @ por a)", "ok": not common and not password.is_empty() },
		{ "id": "personal", "text": "Sin datos personales (nombres, apellidos, años)", "ok": not personal and not password.is_empty() },
		{ "id": "patron", "text": "Sin secuencias ni repeticiones (1234, abcd, aaaa)", "ok": not patterned and not password.is_empty() },
	]
	var valid := rules.all(func(rule: Dictionary) -> bool: return rule["ok"])
	var bits := _estimate_bits(password, words, common or personal, patterned)
	var level := 0
	for threshold in [28.0, 40.0, 56.0, 72.0]:
		if bits >= threshold:
			level += 1
	if not valid:
		level = mini(level, 1)
	return { "rules": rules, "valid": valid, "level": level, "bits": bits, "time": _time_text(bits) }


## Código de respaldo para recuperar la cuenta (p. ej. "K7QM-4XPR"), sin letras que se confunden.
static func backup_code(rng: RandomNumberGenerator = null) -> String:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var alphabet := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var code := ""
	for i in 8:
		code += alphabet[rng.randi_range(0, alphabet.length() - 1)]
	return code.left(4) + "-" + code.right(4)


## Frase de contraseña al azar: 4 palabras y 2 números, separadas por guiones.
static func suggest(rng: RandomNumberGenerator = null) -> String:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var pool := WORDS.duplicate()
	var picked: PackedStringArray = []
	for i in MIN_WORDS:
		picked.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	picked.append(str(rng.randi_range(10, 99)))
	return "-".join(picked)


static func _normalize(text: String) -> String:
	var result := text
	for pair in [["@", "a"], ["4", "a"], ["0", "o"], ["1", "i"], ["!", "i"], ["3", "e"], ["$", "s"], ["5", "s"], ["7", "t"], ["ñ", "n"]]:
		result = result.replace(pair[0], pair[1])
	return result


static func _words(lowered: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var current := ""
	for character in lowered:
		if character in " -_.":
			if current.length() >= 3:
				result.append(current)
			current = ""
		else:
			current += character
	if current.length() >= 3:
		result.append(current)
	return result


static func _is_common(lowered: String) -> bool:
	# Sin los números y símbolos del final (password2024!, hola123): sigue siendo la misma palabra.
	var core := lowered
	while not core.is_empty() and core[core.length() - 1] in "0123456789!@#$%^&*?.,-_ ":
		core = core.left(-1)
	var candidates := [_normalize(lowered), _normalize(core), core]
	for word in COMMON:
		if _normalize(word) in candidates:
			return true
	return false


static func _is_patterned(lowered: String) -> bool:
	if lowered.is_valid_int():
		return true
	var run_repeat := 1
	var run_up := 1
	for i in range(1, lowered.length()):
		var step := lowered.unicode_at(i) - lowered.unicode_at(i - 1)
		run_repeat = run_repeat + 1 if step == 0 else 1
		run_up = run_up + 1 if step == 1 or step == -1 else 1
		if run_repeat >= 4 or run_up >= 4:
			return true
	return false


## Fortaleza estimada en bits. Las frases (2 palabras o más) cuentan por palabras, porque así las
## atacan los programas con diccionarios: unos 13 bits por palabra al azar de una lista grande. El
## resto cuenta por el tamaño del alfabeto usado. Es una estimación para enseñar, no una medida exacta.
static func _estimate_bits(password: String, words: PackedStringArray, weak: bool, patterned: bool) -> float:
	if password.is_empty():
		return 0.0
	var bits := 0.0
	if words.size() >= 2:
		bits = words.size() * 13.0 + (6.6 if _has_any(password, "0123456789") else 0.0)
	else:
		var pool := 0
		if password.to_upper() != password:
			pool += 26
		if password.to_lower() != password:
			pool += 26
		if _has_any(password, "0123456789"):
			pool += 10
		if _has_symbol(password):
			pool += 32
		bits = password.length() * log(maxf(pool, 10)) / log(2.0)
	if weak:
		bits = minf(bits, 16.0)
	if patterned:
		bits *= 0.5
	return bits


static func _has_any(text: String, characters: String) -> bool:
	for character in characters:
		if text.contains(character):
			return true
	return false


static func _has_symbol(text: String) -> bool:
	for character in text:
		if not character.is_valid_identifier() and not character in "0123456789":
			return true
	return false


## Tiempo aproximado para adivinarla probando mil millones de contraseñas por segundo.
static func _time_text(bits: float) -> String:
	var seconds := pow(2.0, bits) / 1.0e9 / 2.0
	if seconds < 1.0:
		return "al instante"
	for unit in [[60.0, "segundos", 1.0], [3600.0, "minutos", 60.0], [86400.0, "horas", 3600.0],
			[31536000.0, "días", 86400.0], [3153600000.0, "años", 31536000.0]]:
		if seconds < unit[0]:
			return "unos %d %s" % [maxi(int(seconds / unit[2]), 1), unit[1]]
	if seconds < 3.1536e11:
		return "unos %d siglos" % int(seconds / 3153600000.0)
	return "más de mil siglos"

class_name KeyDerivation
extends RefCounted
## Huella lenta de una contraseña (PBKDF2-HMAC-SHA256) y cifrado de claves (AES-256-CBC).
## La huella tarda a propósito (ITERATIONS vueltas, unos 0,2 s): para quien entra con su contraseña
## no se nota, pero adivinarla probando millones de opciones se vuelve muy costoso.
## Todo es local: la contraseña nunca se guarda ni sale del juego.

const ITERATIONS := 30000


## PBKDF2-HMAC-SHA256 (un bloque de 32 bytes).
static func pbkdf2(password: String, salt: PackedByteArray, iterations := ITERATIONS) -> PackedByteArray:
	var crypto := Crypto.new()
	var key := password.to_utf8_buffer()
	var block := salt.duplicate()
	block.append_array(PackedByteArray([0, 0, 0, 1]))
	var u := crypto.hmac_digest(HashingContext.HASH_SHA256, key, block)
	var out := u.duplicate()
	for i in iterations - 1:
		u = crypto.hmac_digest(HashingContext.HASH_SHA256, key, u)
		for j in 32:
			out[j] = out[j] ^ u[j]
	return out


## Una subclave distinta para cada uso (p. ej. "verificar" y "envolver"), a partir de la huella.
static func subkey(master: PackedByteArray, purpose: String) -> PackedByteArray:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(master)
	context.update(purpose.to_utf8_buffer())
	return context.finish()


static func random_bytes(count: int) -> PackedByteArray:
	return Crypto.new().generate_random_bytes(count)


## Cifra datos de largo múltiplo de 16 (p. ej. una clave de 32 bytes) con AES-256-CBC.
static func wrap(data: PackedByteArray, key: PackedByteArray, iv: PackedByteArray) -> PackedByteArray:
	var aes := AESContext.new()
	aes.start(AESContext.MODE_CBC_ENCRYPT, key, iv)
	var result := aes.update(data)
	aes.finish()
	return result


static func unwrap(data: PackedByteArray, key: PackedByteArray, iv: PackedByteArray) -> PackedByteArray:
	var aes := AESContext.new()
	aes.start(AESContext.MODE_CBC_DECRYPT, key, iv)
	var result := aes.update(data)
	aes.finish()
	return result


## Compara sin cortar al primer byte distinto (no deja adivinar por el tiempo que tarda).
static func same(a: PackedByteArray, b: PackedByteArray) -> bool:
	if a.size() != b.size():
		return false
	var diff := 0
	for i in a.size():
		diff |= a[i] ^ b[i]
	return diff == 0

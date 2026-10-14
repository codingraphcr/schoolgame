class_name ChipBoss
extends SiblingBoss
## Chip, el estratega (jefe doble del Capítulo 1, con Glitch). Ataques precisos y control del espacio;
## anticipa y convierte el caos de Glitch en un plan. Sus ataques (hoja de Ariel):
##   1. Discos orbitales: lanza discos que se curvan hacia Kai y vuelven.
##   2. Zona de control: un campo que ralentiza a Kai.
##   3. Proyecciones: copias temporales que lanzan un disco cada una (un golpe las deshace).
##   4. Rayo de sincronía: ataque en línea de largo alcance (línea de aviso y después el rayo).
## Al entrar a la Fase 3 levanta un escudo ligado a una configuración insegura: el controlador abre la
## fase segura y la terminal. Protegiendo a Glitch: se para delante con un escudo de discos que hace
## rebotar los golpes de Kai.

signal shield_requested

## Escudo del desafío de la terminal (fase segura).
var shielded := false


func _init() -> void:
	display_name = "Chip"
	contact_damage = 1.0
	threat_type = &"malware"
	death_colors = [SiblingArt.CHIP, SiblingArt.CHIP_LIGHT, Color("173a6a")]


func _kind() -> StringName:
	return &"chip"


## Entre ataques: guarda distancia de Kai (unos 140 px), del lado contrario a Glitch si puede.
func _idle_move(delta: float) -> void:
	var kai := player_position()
	face = 1.0 if kai.x >= global_position.x else -1.0
	var side := -face
	var target := clampf(kai.x + side * 140.0, arena_left, arena_right)
	if (target <= arena_left or target >= arena_right) and absf(kai.x - global_position.x) < 90.0:
		target = clampf(kai.x - side * 140.0, arena_left, arena_right)
	var want := clampf((target - global_position.x) * 2.0, -90.0, 90.0) * tempo
	velocity.x = move_toward(velocity.x, want, 500.0 * delta)


## 1. Discos orbitales: lanza count discos (en abanico) que se curvan hacia Kai y vuelven.
func discos_orbitales(count := 1) -> void:
	var epoch := begin_attack()
	if epoch < 0:
		return
	velocity.x = 0.0
	face_player()
	if not await telegraph(&"discos_orbitales", config.chip_disc_telegraph, epoch):
		end_attack(epoch)
		return
	throw_discs(count)
	await _recover(epoch)


## Lanza los discos hacia Kai (también lo usan los ataques en conjunto).
func throw_discs(count: int, aim := Vector2.INF) -> void:
	var origin := global_position + Vector2(face * 12.0, -26)
	var target := player_position() + Vector2(0, -16) if aim == Vector2.INF else aim
	var base := (target - origin).normalized()
	for k in count:
		var angle := (k - (count - 1) / 2.0) * 0.35
		BossAttacks.disc(get_parent(), origin, base.rotated(angle) * config.chip_disc_speed * tempo, config.chip_disc_range, self)
	Sfx.play(&"popup_open", 1.3, -6.0)
	_squash = Vector2(0.9, 1.1)


## 2. Zona de control: un campo que ralentiza a Kai donde está parado.
func zona_de_control(x := INF) -> void:
	var epoch := begin_attack()
	if epoch < 0:
		return
	velocity.x = 0.0
	face_player()
	if not await telegraph(&"zona_de_control", 0.3, epoch):
		end_attack(epoch)
		return
	BossAttacks.zone(get_parent(), Vector2(player_position().x if x == INF else x, FLOOR_Y), config, telegraph_scale)
	await _recover(epoch)


## 3. Proyecciones: copias temporales a los costados de Kai; cada una lanza un disco.
func proyecciones(count := -1) -> void:
	var epoch := begin_attack()
	if epoch < 0:
		return
	velocity.x = 0.0
	face_player()
	if not await telegraph(&"proyecciones", config.chip_disc_telegraph, epoch):
		end_attack(epoch)
		return
	spawn_copies(config.chip_copies if count < 0 else count)
	await _recover(epoch)


func spawn_copies(count: int) -> Array[ChipCopy]:
	var kai_x := player_position().x
	var copies: Array[ChipCopy] = []
	for k in count:
		var side := -1.0 if k % 2 == 0 else 1.0
		var x := clampf(kai_x + side * (110.0 + 30.0 * int(k / 2)), arena_left, arena_right)
		copies.append(BossAttacks.copy(get_parent(), Vector2(x, FLOOR_Y), config, 0.6 + k * 0.35 / tempo))
	Sfx.play(&"reveal_flash", 1.5, -10.0)
	return copies


## 4. Rayo de sincronía: apunta (línea de aviso) y dispara un rayo horizontal largo hacia Kai.
func rayo_de_sincronia() -> void:
	var epoch := begin_attack()
	if epoch < 0:
		return
	velocity.x = 0.0
	face_player()
	if not await telegraph(&"rayo_de_sincronia", 0.2, epoch):
		end_attack(epoch)
		return
	var beam := fire_beam()
	if not await wait(beam.warning + beam.duration, epoch):
		end_attack(epoch)
		return
	await _recover(epoch)


## El rayo, a la altura del pecho, hacia donde mira (también lo usa Corte y respuesta).
func fire_beam() -> SyncBeam:
	var origin := global_position + Vector2(face * 12.0, -26)
	return BossAttacks.beam(get_parent(), origin, Vector2(face, 0), config, telegraph_scale)


func _recover(epoch: int) -> void:
	velocity.x = 0.0
	await wait(config.chip_recover / tempo, epoch)
	end_attack(epoch)


## --- Escudos ---

## Escudo del desafío (fase segura): no recibe daño hasta resolver la terminal.
func shield_on() -> void:
	shielded = true
	hurtbox.immune = true


func shield_off() -> void:
	shielded = false
	hurtbox.immune = guarding != null


func _on_guard_started() -> void:
	hurtbox.immune = true


func _on_guard_ended() -> void:
	hurtbox.immune = shielded


func _shield_visible() -> bool:
	return shielded or guarding != null


func _on_restored() -> void:
	shielded = false


func _frozen_move(_delta: float) -> void:
	# En la fase segura se va a la derecha de la arena y espera con su escudo.
	velocity.x = clampf((arena_right - 40.0 - global_position.x) * 3.0, -150.0, 150.0)

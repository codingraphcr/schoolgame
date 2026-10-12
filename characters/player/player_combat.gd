class_name PlayerCombat
extends Node
## Ataque cuerpo a cuerpo de Kai (J, acción "attack"). Lee los datos del arma equipada (WeaponData):
## sin arma no ataca. Crea su propia zona de golpe (capa 4: ataques_jugador) delante de Kai,
## la activa unos instantes por ataque y da retroceso y congelamiento breve al acertar.
## Cada golpe acertado a un enemigo recupera energía (WeaponData.energy_gain: 12,5 % de la máxima).
## En el aire, abajo + J ataca hacia abajo: si golpea a un enemigo o a una estructura de rebote
## (pinchos, PogoNode), Kai rebota hacia arriba (pogo, como en Hollow Knight).

signal attacked
## Un golpe acertado (para energía, combos y efectos futuros).
signal hit_landed(target: Node2D)
## Kai rebotó con un ataque hacia abajo.
signal pogo

## Arma equipada (null = Kai no puede atacar todavía).
@export var weapon: WeaponData:
	set(value):
		weapon = value
		_apply_weapon()

## Altura del rebote del ataque hacia abajo (px).
@export var pogo_height := 46.0

var player: Player
var hitbox: HitboxComponent

var _shape: CollisionShape2D
var _cooldown := 0.0
var _windup := 0.0
var _active := 0.0
## Si el ataque en curso es cargado (recupera más energía; llegará más adelante en la historia).
var _charged := false
## Si el ataque en curso va hacia abajo, y si ya rebotó con él (un rebote por ataque).
var _down := false
var _bounced := false


func _ready() -> void:
	player = get_parent() as Player
	hitbox = HitboxComponent.new()
	hitbox.name = "AttackHitbox"
	hitbox.collision_layer = 8  # Capa 4: ataques_jugador
	hitbox.collision_mask = 0
	hitbox.once_per_activation = true
	hitbox.active = false
	_shape = CollisionShape2D.new()
	_shape.shape = RectangleShape2D.new()
	hitbox.add_child(_shape)
	player.add_child.call_deferred(hitbox)
	hitbox.ready.connect(func() -> void: hitbox.owner = player, CONNECT_ONE_SHOT)
	hitbox.hit_dealt.connect(_on_hit_dealt)
	_apply_weapon()


## No se ataca durante el dash ni mientras Kai se cura (como en Hollow Knight).
func can_attack() -> bool:
	return weapon != null and player != null and not player.controls_locked and not player.is_dashing \
		and not player.heal.active and _cooldown <= 0.0 and not is_attacking()


func is_attacking() -> bool:
	return _windup > 0.0 or _active > 0.0


## Si el ataque en curso (o el último) fue hacia abajo.
func is_down_attack() -> bool:
	return _down


func attack(charged := false) -> bool:
	if not can_attack():
		return false
	_cooldown = weapon.cooldown
	_charged = charged
	_down = not player.is_on_floor() and Input.is_action_pressed("move_down")
	_bounced = false
	_windup = maxf(weapon.windup, 0.001)
	_place_hitbox()
	var visual := player.get_node_or_null("Visual/Body/Kai")
	if _down and visual and visual.has_method("play_pose"):
		# El cuadro de ataque trae dibujado el corte hacia adelante: hacia abajo, Kai recoge las rodillas
		# (la pose "caer" de la hoja, como el ataque hacia abajo de Hollow Knight) y clava la espada debajo.
		visual.play_pose(&"caer", weapon.windup + weapon.active_time + 0.15)
	elif visual and visual.has_method("attack"):
		visual.attack(weapon.windup)
	_spawn_slash()
	attacked.emit()
	return true


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_place_hitbox()
			hitbox.activate()
			_active = weapon.active_time
	elif _active > 0.0:
		_active -= delta
		if _active <= 0.0:
			hitbox.deactivate()


# Como evento (no consultando Input cada cuadro): así no se pierde un toque muy rápido de J.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and attack():
		get_viewport().set_input_as_handled()


## Delante de Kai o, si ataca hacia abajo, debajo de sus pies (la zona girada: angosta y alta).
func _place_hitbox() -> void:
	if weapon == null:
		return
	var rect := _shape.shape as RectangleShape2D
	if _down:
		rect.size = Vector2(weapon.reach.y + 6.0, weapon.reach.x)
		hitbox.position = Vector2(0.0, weapon.reach.x * 0.5 - 4.0)
	else:
		rect.size = weapon.reach
		hitbox.position = Vector2(weapon.offset.x * player.facing, weapon.offset.y)


func _apply_weapon() -> void:
	if _shape == null or weapon == null:
		return
	(_shape.shape as RectangleShape2D).size = weapon.reach
	hitbox.damage = weapon.damage
	hitbox.knockback_force = weapon.knockback


func _on_hit_dealt(target: Node2D, _hit: HitData) -> void:
	if _down:
		# Pogo: rebota hacia arriba en vez de retroceder (una vez por ataque).
		if not _bounced:
			_bounced = true
			RingBurst.spawn(player.get_parent(), player.global_position + Vector2(0.0, weapon.reach.x * 0.55), weapon.slash_color)
			player.pogo(pogo_height)
			pogo.emit()
	else:
		player.velocity.x = -player.facing * weapon.recoil
	HitStop.freeze(player, weapon.hit_stop)
	hit_landed.emit(target)
	_gain_energy(target)


## Arco del tajo: un dibujo breve que sigue a Kai (hacia abajo, Kai clava la espada: _spawn_stab).
func _spawn_slash() -> void:
	if _down:
		_spawn_stab()
		return
	var slash := Node2D.new()
	slash.position = Vector2(weapon.offset.x * 0.6 * player.facing, weapon.offset.y)
	slash.scale.x = player.facing
	slash.z_index = 5
	var color := weapon.slash_color
	var radius := weapon.reach.x * 0.75
	# Media luna (como el "trazo de corte" de la hoja de la Nullblade): gruesa en el medio, fina en
	# las puntas, con el borde de afuera más claro.
	var crescent := PackedVector2Array()
	var edge := PackedVector2Array()
	for i in 15:
		var angle := lerpf(-1.2, 1.2, i / 14.0)
		var point := Vector2(cos(angle), sin(angle)) * radius
		crescent.append(point)
		edge.append(point)
	for i in range(14, -1, -1):
		var angle := lerpf(-1.2, 1.2, i / 14.0)
		var thickness := sin(PI * i / 14.0) * 7.0
		crescent.append(Vector2(cos(angle), sin(angle)) * (radius - 1.0 - thickness))
	slash.draw.connect(func() -> void:
		slash.draw_colored_polygon(crescent, Color(color, 0.55))
		slash.draw_polyline(edge, color.lightened(0.5), 2.0, true))
	player.add_child(slash)
	var tween := slash.create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.18)
	tween.tween_callback(slash.queue_free)


## Ataque hacia abajo: Kai clava la espada debajo de sus pies. La hoja (WeaponData.sprite, punta
## hacia abajo) baja de golpe con una estela vertical y se desvanece al terminar el ataque.
func _spawn_stab() -> void:
	var stab := Node2D.new()
	stab.name = "Stab"
	stab.z_index = 5
	var reach := weapon.reach.x
	var color := weapon.slash_color
	var blade := Sprite2D.new()
	blade.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var length := reach + 2.0
	if weapon.sprite:
		blade.texture = weapon.sprite
		blade.scale = Vector2.ONE * (length / weapon.sprite.get_height())
	blade.position = Vector2(2.0 * player.facing, -length * 0.5)
	stab.add_child(blade)
	stab.draw.connect(func() -> void:
		var tip := blade.position.y + length * 0.5
		# Estela vertical: de la mano a la punta, más clara en el centro.
		stab.draw_rect(Rect2(blade.position.x - 5.0, tip - reach - 8.0, 10.0, reach + 8.0), Color(color, 0.18))
		stab.draw_rect(Rect2(blade.position.x - 2.0, tip - reach - 4.0, 4.0, reach + 4.0), Color(color, 0.35))
		if weapon.sprite == null:
			stab.draw_colored_polygon(PackedVector2Array([Vector2(blade.position.x - 2.0, tip - length),
				Vector2(blade.position.x + 2.0, tip - length), Vector2(blade.position.x, tip)]), color.lightened(0.4))
		# Chispa en la punta: una "V" de luz hacia abajo.
		stab.draw_line(Vector2(blade.position.x, tip), Vector2(blade.position.x - 6.0, tip - 6.0), color.lightened(0.6), 1.5)
		stab.draw_line(Vector2(blade.position.x, tip), Vector2(blade.position.x + 6.0, tip - 6.0), color.lightened(0.6), 1.5))
	player.add_child(stab)
	# La espada baja desde las manos de Kai hasta debajo de sus pies.
	stab.position = Vector2(0.0, -10.0)
	var tween := stab.create_tween()
	tween.tween_property(stab, "position:y", reach * 0.55, maxf(weapon.windup, 0.04)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(weapon.active_time)
	tween.tween_property(stab, "modulate:a", 0.0, 0.12)
	tween.tween_callback(stab.queue_free)


## Energía por golpe: solo si el objetivo es un enemigo de verdad, sigue en pie y no tiene escudo.
## Las paredes, plataformas y objetos no tienen zona de daño, así que nunca llegan aquí. Un mismo
## ataque golpea una sola vez a cada enemigo (once_per_activation); con varios enemigos, cada uno
## cuenta. Derrotar a un enemigo no da energía extra.
func _gain_energy(target: Node2D) -> void:
	var hurtbox := target as HurtboxComponent
	if hurtbox == null or hurtbox.immune:
		return
	var enemy := hurtbox.owner as EnemyBase
	if enemy == null or enemy.is_dead:
		return
	var gain := weapon.charged_energy_gain if _charged else weapon.energy_gain
	player.add_energy(player.max_energy * gain)

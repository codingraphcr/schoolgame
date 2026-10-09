class_name PlayerCombat
extends Node
## Ataque cuerpo a cuerpo de Kai (J, acción "attack"). Lee los datos del arma equipada (WeaponData):
## sin arma no ataca. Crea su propia zona de golpe (capa 4: ataques_jugador) delante de Kai,
## la activa unos instantes por ataque y da retroceso y congelamiento breve al acertar.

signal attacked
## Un golpe acertado (para energía, combos y efectos futuros).
signal hit_landed(target: Node2D)

## Arma equipada (null = Kai no puede atacar todavía).
@export var weapon: WeaponData:
	set(value):
		weapon = value
		_apply_weapon()

var player: Player
var hitbox: HitboxComponent

var _shape: CollisionShape2D
var _cooldown := 0.0
var _windup := 0.0
var _active := 0.0


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


func attack() -> bool:
	if not can_attack():
		return false
	_cooldown = weapon.cooldown
	_windup = maxf(weapon.windup, 0.001)
	_place_hitbox()
	var visual := player.get_node_or_null("Visual/Body/Kai")
	if visual and visual.has_method("attack"):
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


func _place_hitbox() -> void:
	if weapon == null:
		return
	hitbox.position = Vector2(weapon.offset.x * player.facing, weapon.offset.y)


func _apply_weapon() -> void:
	if _shape == null or weapon == null:
		return
	(_shape.shape as RectangleShape2D).size = weapon.reach
	hitbox.damage = weapon.damage
	hitbox.knockback_force = weapon.knockback


func _on_hit_dealt(target: Node2D, _hit: HitData) -> void:
	player.velocity.x = -player.facing * weapon.recoil
	HitStop.freeze(player, weapon.hit_stop)
	hit_landed.emit(target)


## Arco del tajo: un dibujo breve que sigue a Kai.
func _spawn_slash() -> void:
	var slash := Node2D.new()
	slash.position = Vector2(weapon.offset.x * 0.6 * player.facing, weapon.offset.y)
	slash.scale.x = player.facing
	slash.z_index = 5
	var color := weapon.slash_color
	var radius := weapon.reach.x * 0.75
	slash.draw.connect(func() -> void:
		slash.draw_arc(Vector2.ZERO, radius, -1.2, 1.2, 14, color, 3.0, true)
		slash.draw_arc(Vector2.ZERO, radius - 4.0, -0.9, 0.9, 12, Color(color, 0.5), 2.0, true))
	player.add_child(slash)
	var tween := slash.create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.18)
	tween.tween_callback(slash.queue_free)

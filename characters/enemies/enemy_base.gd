class_name EnemyBase
extends CharacterBody2D
## Base de todos los enemigos: vida, daño por contacto, parpadeo y empuje al recibir un golpe,
## y muerte. Crea sus propias piezas (cuerpo, HealthComponent, HurtboxComponent y el Hitbox de
## contacto), así la escena de cada enemigo solo tiene el nodo raíz con su script.
## Cada enemigo concreto escribe su comportamiento en _ai() y su dibujo.
##
## Capas: cuerpo en la 3 (enemigos), recibe golpes de la 4 (ataques_jugador) y daña con la 5
## (ataques_enemigos). Kai no choca con los enemigos: los atraviesa recibiendo daño (como en
## Hollow Knight).

signal damaged(amount: float)
signal died

@export var display_name := "Amenaza"
@export var max_health := 3.0
@export var contact_damage := 1.0
## Tipo de amenaza del daño (ver docs/combate.md): credenciales, phishing, malware…
@export var threat_type: StringName = &""
## Tamaño del cuerpo (los pies en el origen).
@export var body_size := Vector2(20, 18)
@export var gravity := 900.0
@export var max_fall_speed := 500.0
## 0 = recibe todo el empuje de los golpes, 1 = no se mueve.
@export_range(0.0, 1.0) var knockback_resistance := 0.0
## Segundos que queda aturdido tras un golpe (no se mueve ni ataca).
@export var hurt_time := 0.25
## Si es false no se mueve ni ataca (escenas, presentaciones, pruebas).
@export var ai_enabled := true
## BITS que suelta al ser derrotado (-1 = según su fuerza: 3 por cada punto de vida máxima).
@export var bits_reward := -1
## Colores de los píxeles en que se desintegra al morir.
@export var death_colors: Array[Color] = [Color("ff3d8a"), Color("ff7ab8"), Color("8a2be2")]

var health: HealthComponent
var hurtbox: HurtboxComponent
var contact: HitboxComponent
var is_dead := false

var _stun := 0.0


func _ready() -> void:
	collision_layer = 4  # Capa 3: enemigos
	collision_mask = 1  # Mundo
	add_to_group(&"enemy")
	var body := CollisionShape2D.new()
	body.shape = _rect(body_size)
	body.position = Vector2(0, -body_size.y / 2.0)
	add_child(body)

	health = HealthComponent.new()
	health.max_health = max_health
	add_child(health)
	health.died.connect(_die)

	hurtbox = HurtboxComponent.new()
	hurtbox.collision_layer = 0
	hurtbox.collision_mask = 8  # Capa 4: ataques_jugador
	hurtbox.add_child(_shape_node(body_size))
	add_child(hurtbox)
	hurtbox.owner = self
	hurtbox.hit_received.connect(_on_hit_received)

	contact = HitboxComponent.new()
	contact.collision_layer = 16  # Capa 5: ataques_enemigos
	contact.collision_mask = 0
	contact.damage = contact_damage
	contact.threat_type = threat_type
	contact.knockback_force = 160.0
	# Un poco más pequeño que el cuerpo: rozar el borde no castiga.
	contact.add_child(_shape_node(body_size - Vector2(4, 4)))
	add_child(contact)
	contact.owner = self


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	if _stun > 0.0:
		_stun -= delta
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	elif ai_enabled:
		_ai(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	move_and_slide()


## Comportamiento propio de cada enemigo (se llama cada cuadro de física si no está aturdido).
func _ai(_delta: float) -> void:
	pass


## Kai (o null si no está en la sala).
func get_player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


## Dirección horizontal hacia Kai (1 o -1).
func direction_to_player() -> int:
	var player := get_player()
	if player == null:
		return -1
	return 1 if player.global_position.x >= global_position.x else -1


func _on_hit_received(hit: HitData) -> void:
	if is_dead:
		return
	health.take_damage(hit.damage)
	damaged.emit(hit.damage)
	# Destello blanco.
	modulate = Color(2.5, 2.5, 2.5)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.15)
	if not is_dead:
		velocity = hit.knockback * (1.0 - knockback_resistance)
		_stun = hurt_time
		_on_damaged(hit)


## Reacción propia al recibir un golpe (además del destello y el empuje).
func _on_damaged(_hit: HitData) -> void:
	pass


func _die() -> void:
	is_dead = true
	contact.deactivate()
	hurtbox.set_physics_process(false)
	collision_layer = 0
	velocity = Vector2.ZERO
	died.emit()
	_on_died()
	# Se desintegra en píxeles y deja caer sus BITS.
	var center := global_position + Vector2(0, -body_size.y / 2.0)
	PixelBurst.spawn(get_parent(), global_position, death_colors, 36, 110.0, body_size, 0.7)
	# Al final del cuadro: no se agregan cuerpos físicos en medio de un choque.
	var room := get_parent()
	var reward := get_bits_reward()
	(func() -> void: BitCoin.spawn_burst(room, center, reward)).call_deferred()
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2(1.4, 0.2), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)


## Efecto propio al morir (se llama una vez, antes de desaparecer).
func _on_died() -> void:
	pass


func _shape_node(size: Vector2) -> CollisionShape2D:
	var shape := CollisionShape2D.new()
	shape.shape = _rect(size)
	shape.position = Vector2(0, -body_size.y / 2.0)
	return shape


func _rect(size: Vector2) -> RectangleShape2D:
	var rect := RectangleShape2D.new()
	rect.size = size
	return rect


## BITS que vale derrotarlo (más fuerte = más BITS).
func get_bits_reward() -> int:
	return bits_reward if bits_reward >= 0 else roundi(max_health * 3.0)

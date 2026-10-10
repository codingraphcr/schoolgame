class_name BitCoin
extends CharacterBody2D
## Un BIT: dato recuperado de una amenaza digital (concepto de Ariel en
## docs/arte/referencias/bits_concepto.webp). Sale disparado, rebota un poco en el suelo, flota
## girando y brilla de vez en cuando. Cuando Kai se acerca, vuela hacia él y se recoge
## (GameState.add_credits: los BITS son la moneda del juego).
## Valor 1 (violeta) o 5 (más brillante y un poco más grande).
## Uso: BitCoin.spawn_burst(sala, posición, cantidad)

const VIOLET := Color("8a5cff")
const BRIGHT := Color("d07bff")
const DARK := Color("1a0f3a")
const FACE := Color("2c1870")
const LIGHT := Color("e9e1ff")
## Cuántas monedas como máximo por explosión (si hay más BITS, valen 5 cada una).
const MAX_COINS := 14
const GRAVITY := 700.0
## Distancia a la que el BIT empieza a volar hacia Kai, y a la que se recoge.
const MAGNET_RADIUS := 36.0
const PICKUP_RADIUS := 8.0
## Segundos antes de poder recogerlo (para que se vea la explosión).
const PICKUP_DELAY := 0.35

## Flag que queda al recoger el primer BIT (desbloquea su página del Grimorio).
const DISCOVERED_FLAG := &"bits_descubiertos"

var value := 1
var _time := 0.0
var _attracted := false
var _collected := false
var _phase := randf() * TAU


## Suelta "amount" BITS repartidos en varias monedas que saltan desde "at".
static func spawn_burst(parent: Node, at: Vector2, amount: int) -> Array[BitCoin]:
	var coins: Array[BitCoin] = []
	if amount <= 0 or parent == null:
		return coins
	# Con muchos BITS, algunas monedas valen 5 para no llenar la pantalla (5·fives + ones = amount).
	var values: Array[int] = []
	var fives := 0
	if amount > MAX_COINS:
		fives = mini(ceili((amount - MAX_COINS) / 4.0), amount / 5)
	var ones := amount - fives * 5
	for i in fives:
		values.append(5)
	for i in ones:
		values.append(1)
	values.shuffle()
	for i in values.size():
		var coin := BitCoin.new()
		coin.value = values[i]
		var spread := (i - values.size() / 2.0) / maxf(values.size(), 1.0)
		coin.velocity = Vector2(spread * 150.0 + randf_range(-20.0, 20.0), randf_range(-220.0, -150.0))
		parent.add_child(coin)
		coin.global_position = at + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 2.0))
		coins.append(coin)
	return coins


## Dibuja una moneda BIT (también la usa el HUD). spin: 1 = de frente, cerca de 0 = de canto.
static func draw_coin(canvas: CanvasItem, center: Vector2, radius: float, spin := 1.0, bright := false, glow := 0.0) -> void:
	var rim := BRIGHT if bright else VIOLET
	if glow > 0.0:
		canvas.draw_circle(center, radius * 2.2, Color(rim, 0.12 * glow))
		canvas.draw_circle(center, radius * 1.5, Color(rim, 0.18 * glow))
	canvas.draw_set_transform(center, 0.0, Vector2(maxf(absf(spin), 0.2), 1.0))
	canvas.draw_circle(Vector2.ZERO, radius + 1.0, DARK)
	canvas.draw_circle(Vector2.ZERO, radius, rim)
	canvas.draw_circle(Vector2.ZERO, radius * 0.72, FACE)
	# Símbolo: un cuadrado hueco (un "bit") con una muesca.
	var s := maxf(roundf(radius * 0.36), 1.0)
	var t := maxf(roundf(radius * 0.16), 1.0)
	canvas.draw_rect(Rect2(-s, -s, s * 2.0, t), LIGHT)
	canvas.draw_rect(Rect2(-s, s - t, s * 2.0, t), LIGHT)
	canvas.draw_rect(Rect2(-s, -s, t, s * 2.0), LIGHT)
	canvas.draw_rect(Rect2(s - t, -s + t, t, s * 2.0 - t * 2.0), LIGHT)
	# Brillo arriba a la izquierda.
	canvas.draw_rect(Rect2(-radius * 0.6, -radius * 0.7, maxf(radius * 0.25, 1.0), maxf(radius * 0.25, 1.0)), Color(LIGHT, 0.8))
	canvas.draw_set_transform(Vector2.ZERO)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # Capa 1: mundo (rebota en suelos, paredes y plataformas).
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 3.0
	shape.shape = circle
	add_child(shape)
	z_index = 4
	# Aparición: un destello breve.
	scale = Vector2(0.4, 0.4)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	_time += delta
	if _collected:
		return
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	var target := player.global_position + Vector2(0, -14) if player else Vector2.ZERO
	if player and _time >= PICKUP_DELAY and global_position.distance_to(target) < MAGNET_RADIUS:
		_attracted = true
	if _attracted and player:
		# Recolección: vuela hacia Kai cada vez más rápido.
		var to := target - global_position
		velocity = velocity.lerp(to.normalized() * (180.0 + _time * 60.0), 0.25)
		global_position += velocity * delta
		if to.length() < PICKUP_RADIUS:
			_collect()
		queue_redraw()
		return
	velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
	var falling := velocity.y
	move_and_slide()
	if is_on_floor():
		# Rebota un poco y se frena.
		if falling > 60.0:
			velocity.y = -falling * 0.42
		velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
	if is_on_wall():
		velocity.x = -velocity.x * 0.5
	queue_redraw()


func _draw() -> void:
	var resting := is_on_floor() and absf(velocity.y) < 1.0
	# Flota sobre el suelo y gira; cada tanto brilla.
	var bob := sin(_time * 3.0 + _phase) * 1.5 - 3.0 if resting else 0.0
	var spin := cos(_time * (4.0 if not _attracted else 10.0) + _phase)
	var shine := maxf(0.0, sin(_time * 1.7 + _phase) - 0.85) * 6.0
	var radius := 5.0 if value >= 5 else 4.0
	BitCoin.draw_coin(self, Vector2(0, bob - 1.0), radius, spin, value >= 5, 0.6 + shine)
	if shine > 0.2:
		var c := Vector2(0, bob - 1.0)
		draw_line(c + Vector2(-radius - 3, 0), c + Vector2(radius + 3, 0), Color(LIGHT, shine * 0.5), 1.0)
		draw_line(c + Vector2(0, -radius - 3), c + Vector2(0, radius + 3), Color(LIGHT, shine * 0.5), 1.0)


func _collect() -> void:
	_collected = true
	var game_state := get_node_or_null("/root/GameState")
	if game_state:
		game_state.add_credits(value)
		game_state.set_flag(DISCOVERED_FLAG)
	# Desaparición: se deshace en cuadritos.
	var burst := PixelBurst.spawn(get_parent(), global_position, [VIOLET, LIGHT, BRIGHT], 6, 40.0)
	burst.z_index = z_index
	queue_free()

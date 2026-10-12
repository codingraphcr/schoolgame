class_name EcoShard
extends CharacterBody2D
## Un ECO: residuo de información que deja una amenaza neutralizada (la moneda del juego, Economy).
## Sale disparado, rebota un poco en el suelo, flota girando y brilla de vez en cuando. Cuando Kai
## se acerca, vuela hacia él y se recoge (Economy.add_ecos).
## Se ve como un fragmento cristalino de energía (dibujo por código, draw_shard; también el ícono
## del HUD): azul si vale 1, violeta si vale 5 y blanco violáceo, más grande, si vale 25.
## Al recogerlo se deshace en partículas con un anillo de luz y suena un tintineo de cristal.
## Uso: EcoShard.spawn_burst(sala, posición, cantidad)

const BLUE := Color("3ec8ff")
const VIOLET := Color("8a5cff")
const BRIGHT := Color("d07bff")
const DARK := Color("120a2e")
const LIGHT := Color("e9e1ff")
## Valores de los fragmentos: con muchos Ecos se usan los grandes para no llenar la pantalla.
const VALUES: Array[int] = [25, 5, 1]
## Cuántos fragmentos como máximo por explosión (más Ecos = fragmentos de más valor).
const MAX_COINS := 14
const GRAVITY := 700.0
## Distancia a la que el Eco empieza a volar hacia Kai, y a la que se recoge.
const MAGNET_RADIUS := 36.0
const PICKUP_RADIUS := 8.0
## Segundos antes de poder recogerlo (para que se vea la explosión).
const PICKUP_DELAY := 0.35

## Recoger varios Ecos seguidos suena cada vez un poco más agudo.
static var _combo := 0
static var _last_pickup_ms := 0

## Marca que queda al recoger el primer Eco (desbloquea su página del Grimorio).
const DISCOVERED_FLAG := &"ecos_descubiertos"

var value := 1
var _time := 0.0
## Si se quita sin sumar su valor (solo pruebas o efectos).
var _discarded := false
var _attracted := false
var _collected := false
var _phase := randf() * TAU


## Suelta "amount" Ecos repartidos en varios fragmentos que saltan desde "at".
static func spawn_burst(parent: Node, at: Vector2, amount: int) -> Array[EcoShard]:
	var coins: Array[EcoShard] = []
	if amount <= 0 or parent == null:
		return coins
	var values := split(amount)
	values.shuffle()
	for i in values.size():
		var coin := EcoShard.new()
		coin.value = values[i]
		var spread := (i - values.size() / 2.0) / maxf(values.size(), 1.0)
		coin.velocity = Vector2(spread * 150.0 + randf_range(-20.0, 20.0), randf_range(-220.0, -150.0))
		parent.add_child(coin)
		coin.global_position = at + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 2.0))
		coins.append(coin)
	return coins


## Reparte una cantidad en valores de 1, 5 y 25: pocos fragmentos grandes si hay muchos Ecos.
## La suma siempre es exactamente la cantidad.
static func split(amount: int) -> Array[int]:
	var counts := { 25: 0, 5: 0, 1: maxi(amount, 0) }
	# Junta de a 5 fragmentos de un valor en uno del siguiente mientras haya demasiados.
	for pair in [[1, 5], [5, 25]]:
		while counts[25] + counts[5] + counts[1] > MAX_COINS and counts[pair[0]] >= 5:
			counts[pair[0]] -= 5
			counts[pair[1]] += 1
	var values: Array[int] = []
	for value in VALUES:
		for i in counts[value]:
			values.append(value)
	return values


## Dibuja un Eco (también lo usa el HUD). spin: 1 = de frente, cerca de 0 = de canto.
## size: alto del cristal en píxeles; spin: giro (1 = de frente, cerca de 0 = de canto);
## value: 1 azul, 5 violeta, 25 blanco violáceo; glow: brillo alrededor (0–1+).
static func draw_shard(canvas: CanvasItem, center: Vector2, size: float, spin := 1.0, value := 1, glow := 0.0) -> void:
	var color := BLUE if value < 5 else (VIOLET if value < 25 else BRIGHT)
	var h := size * 0.5
	# Al girar se angosta, pero nunca desaparece (así se ve bien también de canto).
	var w := maxf(h * 0.62 * maxf(absf(spin), 0.35), 1.2)
	if glow > 0.0:
		canvas.draw_circle(center, size * 1.15, Color(color, 0.1 * glow))
		canvas.draw_circle(center, size * 0.75, Color(color, 0.18 * glow))
	# Cristal alargado de seis lados: punta arriba y abajo.
	var top := center + Vector2(0, -h)
	var bottom := center + Vector2(0, h)
	var right_up := center + Vector2(w, -h * 0.35)
	var right_down := center + Vector2(w * 0.8, h * 0.45)
	var left_up := center + Vector2(-w, -h * 0.35)
	var left_down := center + Vector2(-w * 0.8, h * 0.45)
	canvas.draw_colored_polygon(PackedVector2Array([top, right_up, right_down, bottom, left_down, left_up]), DARK)
	# Dos caras (cuadriláteros): una iluminada y otra en sombra; el lado cambia al girar.
	var shrink := 0.82
	var face_left := PackedVector2Array([top.lerp(center, 0.12), left_up.lerp(center, 1.0 - shrink), left_down.lerp(center, 1.0 - shrink), bottom.lerp(center, 0.12)])
	var face_right := PackedVector2Array([top.lerp(center, 0.12), bottom.lerp(center, 0.12), right_down.lerp(center, 1.0 - shrink), right_up.lerp(center, 1.0 - shrink)])
	var lit := color.lerp(LIGHT, 0.45)
	canvas.draw_colored_polygon(face_left if spin >= 0.0 else face_right, lit)
	canvas.draw_colored_polygon(face_right if spin >= 0.0 else face_left, color.darkened(0.15))
	# Destello en la punta y una veta de luz.
	canvas.draw_line(top + Vector2(0, 1.2), center + Vector2(0, h * 0.1), Color(LIGHT, 0.85), 1.0)
	canvas.draw_rect(Rect2(top + Vector2(-0.5, 0.6), Vector2(1, 1)), Color.WHITE)


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


## Al salir de la sala (o desaparecer) sin que Kai lo recoja, su valor se suma igual: los Ecos no se pierden.
func _exit_tree() -> void:
	if _collected or _discarded or value <= 0:
		return
	_collected = true
	var economy := get_node_or_null("/root/Economy")
	if economy:
		economy.add_ecos(value)


## Quita el fragmento sin sumar su valor.
func discard() -> void:
	_discarded = true
	queue_free()


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
	var size := 9.0 if value < 5 else (11.0 if value < 25 else 14.0)
	var c := Vector2(0, bob - size * 0.5 + 2.0)
	EcoShard.draw_shard(self, c, size, spin, value, 0.6 + shine)
	if shine > 0.2:
		# Destello en cruz.
		draw_line(c + Vector2(-size * 0.6, 0), c + Vector2(size * 0.6, 0), Color(LIGHT, shine * 0.5), 1.0)
		draw_line(c + Vector2(0, -size * 0.75), c + Vector2(0, size * 0.75), Color(LIGHT, shine * 0.5), 1.0)


func _collect() -> void:
	_collected = true
	var economy := get_node_or_null("/root/Economy")
	if economy:
		economy.add_ecos(value)
	var game_state := get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_flag(DISCOVERED_FLAG)
	_pickup_sound()
	# Desaparición: se deshace en partículas con un anillo de luz.
	var colors := [BLUE, LIGHT, VIOLET] if value < 25 else [BRIGHT, LIGHT, VIOLET]
	var burst := PixelBurst.spawn(get_parent(), global_position, colors, 8 if value < 5 else 14, 50.0)
	burst.z_index = z_index
	_spawn_ring()
	queue_free()


## Anillo de luz que se expande y se desvanece donde se recogió.
func _spawn_ring() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var ring := Node2D.new()
	ring.z_index = z_index
	var color := BLUE if value < 5 else VIOLET
	var radius := [3.0]
	ring.draw.connect(func() -> void: ring.draw_arc(Vector2.ZERO, radius[0], 0.0, TAU, 16, color, 1.2, true))
	parent.add_child(ring)
	ring.global_position = global_position
	var tween := ring.create_tween().set_parallel()
	tween.tween_method(func(r: float) -> void:
		radius[0] = r
		ring.queue_redraw(), 3.0, 12.0, 0.25)
	tween.tween_property(ring, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(ring.queue_free)


func _pickup_sound() -> void:
	var now := Time.get_ticks_msec()
	_combo = mini(_combo + 1, 12) if now - _last_pickup_ms < 450 else 0
	_last_pickup_ms = now
	Sfx.play(&"eco_pickup", 1.0 + _combo * 0.06 + (0.15 if value >= 5 else 0.0) + (0.15 if value >= 25 else 0.0))

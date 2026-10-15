class_name PlayerCombat
extends Node
## Ataque cuerpo a cuerpo de Kai (J, acción "attack"). Lee los datos del arma equipada (WeaponData):
## sin arma no ataca. Crea su propia zona de golpe (capa 4: ataques_jugador) delante de Kai,
## la activa unos instantes por ataque y da retroceso y congelamiento breve al acertar.
## Cada golpe acertado a un enemigo recupera energía (WeaponData.energy_gain: 12,5 % de la máxima).
## En el aire, abajo + J ataca hacia abajo: si golpea a un enemigo o a una estructura de rebote
## (pinchos, PogoNode), Kai rebota hacia arriba (pogo, como en Hollow Knight). Arriba + J ataca hacia
## arriba (en el piso o en el aire): la Nullblade gira hasta arriba de su cabeza y deja una media luna.

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
## Si el ataque en curso es hacia arriba (arriba + J).
var _up := false
var _bounced := false
## Si la pose del ataque hacia abajo ya trae la espada dibujada (las poses del pogo de la hoja).
var _pose_has_blade := false
## Hacia arriba: la zona de golpe empieza aquí (sobre la cabeza de Kai, que mide unos 46 px) y termina a
## la altura de la mano (no alcanza a lo que está delante a la altura del cuerpo).
const UP_REACH_TOP := -68.0
## Ataque hacia arriba: altura de las manos de Kai (de ahí sale la espada hacia arriba).
const UP_HANDS_Y := -30.0
## Con la pose del ataque hacia arriba (la del pogo con las manos en el mango, sin la hoja:
## tools/art/generar_kai_corte_arriba.gd), la espada sale de sus manos (a la altura de la cintura).
const UP_GRIP := Vector2(1.0, -13.0)
## Hacia dónde se inclina la espada hacia arriba (radianes; positivo = hacia adelante). Como la del pogo,
## pero al revés.
const UP_TILT := 0.4
## Si el ataque hacia arriba usa su pose (si no, la de salto).
var _up_pose := false


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


## Si el ataque en curso (o el último) fue hacia arriba.
func is_up_attack() -> bool:
	return _up


func attack(charged := false) -> bool:
	if not can_attack():
		return false
	_cooldown = weapon.cooldown
	_charged = charged
	_down = not player.is_on_floor() and Input.is_action_pressed("move_down")
	_up = not _down and Input.is_action_pressed("move_up")
	_bounced = false
	_up_pose = false
	_windup = maxf(weapon.windup, 0.001)
	_place_hitbox()
	var visual := player.get_node_or_null("Visual/Body/Kai")
	# Hacia abajo, las poses del pogo de la hoja de Ariel (con la Nullblade dibujada en la mano).
	# Si la apariencia no las tiene, Kai recoge las rodillas y se dibuja la espada aparte.
	_pose_has_blade = _down and visual != null and visual.has_method("pogo_attack") \
		and visual.pogo_attack(weapon.windup, weapon.active_time)
	if _down and not _pose_has_blade and visual and visual.has_method("play_pose"):
		visual.play_pose(&"caer", weapon.windup + weapon.active_time + 0.15)
	elif _up:
		# Hacia arriba: la pose del corte de la hoja de Ariel (el puño en alto). Si la apariencia no la
		# tiene, la de salto.
		_up_pose = visual != null and visual.has_method("up_attack") and visual.up_attack(weapon.windup, weapon.active_time)
		if not _up_pose and visual and visual.has_method("play_pose"):
			visual.play_pose(&"saltar", weapon.windup + weapon.active_time + 0.15)
	elif not _down and visual and visual.has_method("attack"):
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


## Delante de Kai o, si ataca hacia abajo o hacia arriba, debajo de sus pies o sobre su cabeza (la
## zona girada: angosta y alta).
func _place_hitbox() -> void:
	if weapon == null:
		return
	var rect := _shape.shape as RectangleShape2D
	if _up:
		rect.size = Vector2(weapon.reach.y + 14.0, weapon.reach.x + 4.0)
		hitbox.position = Vector2(0.0, UP_REACH_TOP + (weapon.reach.x + 4.0) * 0.5)
	elif _down:
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
			_spawn_pogo_impact(player.global_position + Vector2(0.0, weapon.reach.x * 0.55))
			player.pogo(pogo_height)
			var visual := player.get_node_or_null("Visual/Body/Kai")
			if visual and visual.has_method("pogo_bounce"):
				visual.pogo_bounce()
			_spawn_ascent_trail()
			pogo.emit()
	elif not _up:
		player.velocity.x = -player.facing * weapon.recoil
	HitStop.freeze(player, weapon.hit_stop)
	hit_landed.emit(target)
	_gain_energy(target)


## Arco del tajo: un dibujo breve que sigue a Kai (hacia abajo, Kai clava la espada: _spawn_stab).
func _spawn_slash() -> void:
	if _down:
		_spawn_stab()
		return
	if _up:
		_spawn_up_slash()
		return
	var slash := _crescent_node()
	slash.position = Vector2(weapon.offset.x * 0.6 * player.facing, weapon.offset.y)
	slash.scale.x = player.facing
	player.add_child(slash)
	var tween := slash.create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.18)
	tween.tween_callback(slash.queue_free)


## La media luna del tajo (como el "trazo de corte" de la hoja de la Nullblade): gruesa en el medio,
## fina en las puntas, con el borde de afuera más claro. Abre hacia adelante (+x).
func _crescent_node() -> Node2D:
	var slash := Node2D.new()
	slash.z_index = 5
	var color := weapon.slash_color
	var radius := weapon.reach.x * 0.75
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
	return slash


## Ataque hacia arriba: como el de abajo, pero al revés. Kai sostiene el mango con las dos manos (la pose
## del pogo) y la Nullblade (WeaponData.sprite) sale de golpe hacia arriba, un poco hacia adelante, con su
## luz a lo largo de la hoja, una chispa en la punta y un destello (rayos, el rombo de la Nullblade y
## píxeles). Se desvanece al terminar el ataque.
func _spawn_up_slash() -> void:
	var stab := Node2D.new()
	stab.name = "UpSlash"
	stab.z_index = 5
	stab.scale.x = player.facing  # Se arma mirando a la derecha; a la izquierda, espejado.
	var color := weapon.slash_color
	var light := color.lightened(0.6)
	var length := weapon.reach.x + 8.0
	# La espada, girada hacia donde apunta: en su espacio, la punta va hacia arriba (y negativa).
	var sword := Node2D.new()
	sword.rotation = UP_TILT if _up_pose else 0.0
	stab.add_child(sword)
	var grip := UP_GRIP if _up_pose else Vector2(2.0, UP_HANDS_Y)
	var blade := Sprite2D.new()
	blade.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if weapon.sprite:
		blade.texture = weapon.sprite
		blade.scale = Vector2.ONE * (length / weapon.sprite.get_height())
		blade.flip_v = true  # En el dibujo la punta mira hacia abajo.
	blade.position = Vector2(0.0, -length * 0.5)
	sword.add_child(blade)
	var thrust := maxf(weapon.windup, 0.04)
	var total := thrust + weapon.active_time + 0.16
	var state := { "t": 0.0, "burst": false }
	sword.draw.connect(func() -> void:
		var t: float = state.t
		var alpha := 1.0 - clampf((t - thrust - weapon.active_time) / 0.16, 0.0, 1.0)
		var tip := -length
		# Luz a lo largo de la hoja (como la estela del ataque hacia abajo), más clara en el centro.
		sword.draw_rect(Rect2(-5.0, tip - 4.0, 10.0, length + 4.0), Color(color, 0.18 * alpha))
		sword.draw_rect(Rect2(-2.0, tip - 2.0, 4.0, length + 2.0), Color(color, 0.35 * alpha))
		if weapon.sprite == null:
			sword.draw_colored_polygon(PackedVector2Array([Vector2(-2.0, 0.0), Vector2(2.0, 0.0), Vector2(0.0, tip)]), Color(light, alpha))
		# Chispa en la punta: una "V" de luz hacia arriba.
		sword.draw_line(Vector2(0.0, tip), Vector2(-6.0, tip + 6.0), Color(light, alpha), 1.5)
		sword.draw_line(Vector2(0.0, tip), Vector2(6.0, tip + 6.0), Color(light, alpha), 1.5)
		if t >= thrust:
			# Destello en la punta: rayos en abanico y el rombo de la Nullblade.
			var spark := clampf((t - thrust) / (total - thrust), 0.0, 1.0)
			var at := Vector2(0.0, tip - 2.0)
			for i in 5:
				var dir := Vector2.UP.rotated(lerpf(-0.9, 0.9, i / 4.0))
				sword.draw_line(at + dir * 3.0, at + dir * (6.0 + 12.0 * spark), Color(light, 1.0 - spark), 1.0)
			var size := 4.0 + 2.0 * spark
			var rhombus := PackedVector2Array([at + Vector2(0, -size), at + Vector2(size * 0.6, 0), at + Vector2(0, size), at + Vector2(-size * 0.6, 0)])
			sword.draw_colored_polygon(rhombus, Color(color, 0.35 * alpha))
			rhombus.append(rhombus[0])
			sword.draw_polyline(rhombus, Color(light, alpha), 1.0))
	player.add_child(stab)
	# La espada sube de golpe desde las manos de Kai hasta quedar con el mango en ellas (como la de abajo).
	var update := func(t: float) -> void:
		state.t = t
		var push := 1.0 - clampf(t / thrust, 0.0, 1.0)
		sword.position = grip + Vector2.UP.rotated(sword.rotation) * -10.0 * push * push
		sword.modulate.a = 1.0 - clampf((t - thrust - weapon.active_time) / 0.16, 0.0, 1.0)
		if t >= thrust and not state.burst:
			state.burst = true
			var tip := sword.to_global(Vector2(0.0, -length - 2.0))
			PixelBurst.spawn(player.get_parent(), tip, [color, light, Color.WHITE], 10, 70.0, Vector2.ZERO, 0.35)
		sword.queue_redraw()
	update.call(0.0)
	var tween := stab.create_tween()
	tween.tween_method(update, 0.0, total, total)
	tween.tween_callback(stab.queue_free)


## Ataque hacia abajo: Kai clava la espada debajo de sus pies. Con las poses del pogo la espada ya
## está en la mano y solo se agrega el rastro de descenso; si no, la hoja (WeaponData.sprite, punta
## hacia abajo) baja de golpe con una estela vertical y se desvanece al terminar el ataque.
func _spawn_stab() -> void:
	if _pose_has_blade:
		_spawn_descent_trail()
		return
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


## Rastro de descenso (hoja del pogo): líneas de energía sobre Kai mientras baja con la espada.
func _spawn_descent_trail() -> void:
	var trail := Node2D.new()
	trail.z_index = 4
	var color := weapon.slash_color.lightened(0.3)
	trail.draw.connect(func() -> void:
		for i in 5:
			var x := (i - 2) * 3.5
			var top := -40.0 - (12.0 + (i % 2) * 9.0)
			trail.draw_line(Vector2(x, -38.0), Vector2(x, top), Color(color, 0.7 if i == 2 else 0.4), 2.0 if i == 2 else 1.0))
	player.add_child(trail)
	var tween := trail.create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, weapon.windup + weapon.active_time + 0.1)
	tween.tween_callback(trail.queue_free)


## Impacto del pogo (hoja de Ariel): chispa digital en la punta de la espada (píxeles, rayos en
## abanico y franjas de glitch) y el chorro vertical de energía del rebote.
func _spawn_pogo_impact(at: Vector2) -> void:
	var color := weapon.slash_color
	var pink := Color("ff6ad5")
	PixelBurst.spawn(player.get_parent(), at, [color, pink, color.lightened(0.6)], 16, 110.0)
	var fx := Node2D.new()
	fx.z_index = 5
	player.get_parent().add_child(fx)
	fx.global_position = at
	var life := [0.0]
	fx.draw.connect(func() -> void:
		var k: float = life[0]
		var rise := minf(k * 2.5, 1.0)
		for i in 7:
			var angle := lerpf(-PI * 0.92, -PI * 0.08, i / 6.0)
			var dir := Vector2(cos(angle), sin(angle))
			fx.draw_line(dir * 3.0, dir * (8.0 + 18.0 * k), Color(pink.lightened(0.35), 1.0 - k), 1.5)
		fx.draw_rect(Rect2(-5.0, -38.0 * rise, 10.0, 38.0 * rise), Color(color, 0.25 * (1.0 - k)))
		fx.draw_rect(Rect2(-1.5, -38.0 * rise, 3.0, 38.0 * rise), Color(color.lightened(0.5), 0.8 * (1.0 - k)))
		if not GameSettings.reduce_glitch and k < 0.6:
			for j in 3:
				fx.draw_rect(Rect2(randf_range(-18.0, 6.0), randf_range(-14.0, 2.0), randf_range(6.0, 14.0), 1.0), Color([color, pink].pick_random(), 0.8)))
	var tween := fx.create_tween()
	tween.tween_method(func(value: float) -> void:
		life[0] = value
		fx.queue_redraw(), 0.0, 1.0, 0.32)
	tween.tween_callback(fx.queue_free)


## Arco de rastro aéreo (hoja del pogo): una estela de energía que sigue a Kai mientras sube.
func _spawn_ascent_trail() -> void:
	var trail := Node2D.new()
	trail.z_index = 3
	player.get_parent().add_child(trail)
	var points: Array[Vector2] = []
	var color := weapon.slash_color
	trail.draw.connect(func() -> void:
		for i in range(1, points.size()):
			var k := float(i) / points.size()
			trail.draw_line(trail.to_local(points[i - 1]), trail.to_local(points[i]), Color(color.lightened(0.2 * k), 0.6 * k), 1.0 + 3.0 * k))
	var tween := trail.create_tween()
	tween.tween_method(func(_value: float) -> void:
		points.append(player.global_position + Vector2(-5.0 * player.facing, -16.0))
		if points.size() > 10:
			points.remove_at(0)
		trail.queue_redraw(), 0.0, 1.0, 0.35)
	tween.tween_property(trail, "modulate:a", 0.0, 0.15)
	tween.tween_callback(trail.queue_free)


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

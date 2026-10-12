class_name WeakPasswordBoss
extends EnemyBase
## Jefe del prólogo: la «Contraseña débil». Sprites de Ariel (docs/arte/referencias/jefe_contrasena_sprites.webp,
## recortados con tools/art/extraer_jefe_contrasena.gd): quieto, caminar, preparar, embestir, agachado,
## daño, muerte y alerta. La hoja general del jefe está en jefe_contrasena_debil_concepto.webp.
##   Aparición (assemble): al principio es una ventanita "123456"; decenas de ventanas de error se
##   abren y se juntan, y el jefe se arma desde los píxeles (pose de alerta).
##   Ataques: camina hacia Kai para presionarlo, embiste en línea recta (prepara antes: aviso) y lanza
##   contraseñas comunes (PasswordGuess, hay que saltarlas). Tras la embestida choca y queda
##   agachado unos segundos: ahí se le puede hacer pogo (y el pogo le quita el doble).
##   Fase 1 (100-50 %): ataques lentos y fáciles de anticipar. Fase 2 (50-0 %): «¡VENTANAS
##   INESTABLES!» (glitch en franjas), se mueve más rápido y encadena la embestida con los proyectiles.
##   Al morir: se tiñe de rojo con "ACCESO DENEGADO" en sus ventanas y se desintegra en píxeles
##   magenta y fragmentos de código (death_finished al terminar).

signal assembled
signal death_finished
signal phase_changed(phase: int)

enum State { HIDDEN, INTRO, WALK, WINDUP, CHARGE, CROUCH, SHOOT, DYING }

const FRAMES_DIR := "res://assets/art/characters/jefe_contrasena/"
const DISSOLVE := preload("res://world/effects/pixel_dissolve.gdshader")
const GLITCH := preload("res://world/effects/glitch_slices.gdshader")
const MAG := Color("ff3ea5")
const PINK := Color("ff9ccf")
const HOT := Color("ffd1ec")
const VIOLET := Color("8a5cff")
const DARK := Color("12081f")
const RED := Color("ff2a55")
const WEAK_PASSWORDS: Array[String] = ["123456", "qwerty", "password", "111111", "abc123", "admin", "12345678"]
## Cuerpo de pie y agachado (tras la embestida: así queda al alcance del pogo).
const STAND := Vector2(76, 92)
const CROUCHED := Vector2(84, 62)
## Animaciones que miran a la derecha en la hoja (tienen su versión _izq hacia la izquierda).
const SIDE_ANIMATIONS: Array[StringName] = [&"caminar", &"embestir"]
## Dónde están, más o menos, las ventanas del cuerpo (para "ACCESO DENEGADO" al morir).
const DENIED_SPOTS: Array[Vector2] = [Vector2(-2, -88), Vector2(-30, -68), Vector2(28, -72), Vector2(-26, -46), Vector2(30, -50)]

@export var walk_speed := 32.0
@export var charge_speed := 240.0
@export var walk_time := 2.4
@export var windup_time := 0.8
@export var crouch_time := 1.6
@export var shoot_windup := 0.55
@export var shot_gap := 0.45
## En la fase 2 (vida ≤ 50 %) todo va un poco más rápido.
@export var phase_two_speed := 1.3

var state := State.HIDDEN
var phase := 1
var facing := -1

var _timer := 0.0
var _next_charge := true
var _shots_left := 0
var _charge_from := 0.0
var _hurt_left := 0.0
var _assembly := 0.0
var _flying: Array[Dictionary] = []
var _code: Array[Dictionary] = []
var _trail: Array[Vector2] = []
var _denied := false
var _sprite: AnimatedSprite2D
var _offsets := {}
## Escala del sprite en el mundo (jefe.json: mitad, como Kai).
var _base_scale := 0.5
var _overlay: VectorCanvas
var _body_shape: CollisionShape2D


func _init() -> void:
	display_name = "Contraseña débil"
	max_health = 24.0
	threat_type = &"credenciales"
	rank = Rank.JEFE
	reward_id = &"jefe:contrasena_debil"
	body_size = STAND
	knockback_resistance = 1.0
	hurt_time = 0.0
	death_colors = [MAG, PINK, VIOLET, Color.WHITE]


func _ready() -> void:
	super()
	for child in get_children():
		if child is CollisionShape2D:
			_body_shape = child
	_build_sprite()
	_overlay = VectorCanvas.new()
	_overlay.painter = _paint_overlay
	_overlay.animated = true
	_overlay.z_index = 1
	add_child(_overlay)
	# Hasta armarse es solo una ventanita: no se le puede golpear ni lastima.
	_sprite.visible = false
	_set_active(false)


## AnimatedSprite2D con las tiras de jefe.json (mismo tamaño de píxel que Kai: a mitad de escala).
func _build_sprite() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var file := FileAccess.open(FRAMES_DIR + "jefe.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text()) if file else {}
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var animations: Dictionary = data.get("animations", {})
	for anim_name: String in animations:
		var info: Dictionary = animations[anim_name]
		var texture: Texture2D = load(FRAMES_DIR + String(info.file))
		var size := Vector2(info.frame_size[0], info.frame_size[1])
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, float(info.fps))
		frames.set_animation_loop(anim_name, bool(info.loop))
		for i in int(info.frames):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(Vector2(i * size.x, 0), size)
			frames.add_frame(anim_name, atlas)
		_offsets[StringName(anim_name)] = size * 0.5 - Vector2(info.feet[0], info.feet[1])
	_sprite.sprite_frames = frames
	_base_scale = float(data.get("scale", 0.5))
	_sprite.scale = Vector2.ONE * _base_scale
	add_child(_sprite)
	_play(&"quieto")


## Reproduce una animación (si no es la actual). Las que miran a la derecha tienen su versión hacia
## la izquierda (<animación>_izq, con el texto de las ventanas al derecho): no se espeja el sprite.
func _play(anim: StringName, restart := false) -> void:
	if _sprite == null:
		return
	if anim in SIDE_ANIMATIONS and facing < 0:
		anim = StringName(String(anim) + "_izq")
	if not _sprite.sprite_frames.has_animation(anim):
		return
	_sprite.offset = _offsets.get(anim, Vector2.ZERO)
	if _sprite.animation != anim or restart or not _sprite.is_playing():
		_sprite.play(anim)


func speed_scale() -> float:
	return phase_two_speed if phase == 2 else 1.0


func is_crouching() -> bool:
	return state == State.CROUCH


## Aparición: de la ventanita "123456" salen decenas de ventanas de error que se juntan y el jefe se
## arma desde los píxeles. quick: más corta (al reintentar). Termina listo para pelear (state WALK).
func assemble(quick := false) -> void:
	state = State.INTRO
	var duration := 0.9 if quick else 2.2
	var count := 12 if quick else 34
	for i in count:
		var angle := randf() * TAU
		_flying.append({ "start": Vector2(cos(angle) * randf_range(70.0, 170.0), -44.0 + sin(angle) * randf_range(50.0, 120.0)),
			"delay": randf_range(0.0, duration * 0.55), "time": 0.0, "size": Vector2(randf_range(16.0, 30.0), randf_range(9.0, 14.0)),
			"text": ["ERROR", "!", "123456", "x"].pick_random(), "sound": true })
	var material := ShaderMaterial.new()
	material.shader = DISSOLVE
	material.set_shader_parameter(&"edge_color", MAG)
	material.set_shader_parameter(&"amount", 1.0)
	var elapsed := 0.0
	while elapsed < duration:
		var delta := get_process_delta_time()
		elapsed += delta
		_assembly = clampf(elapsed / duration, 0.0, 1.0)
		for f in _flying:
			f.time += delta
			if f.sound and f.time >= f.delay:
				f.sound = false
				Sfx.play(&"popup_open", randf_range(0.9, 1.4), -8.0)
		# En la segunda mitad el cuerpo aparece desde los píxeles.
		if _assembly > 0.5:
			if not _sprite.visible:
				_sprite.visible = true
				_sprite.material = material
				_play(&"quieto")
			material.set_shader_parameter(&"amount", 1.0 - smoothstep(0.5, 1.0, _assembly))
		await get_tree().process_frame
	_flying.clear()
	_assembly = 1.0
	_sprite.material = null
	_sprite.visible = true
	# Se arma de golpe: destello, temblor, rugido de error y pose de alerta.
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -46), [MAG, PINK, Color.WHITE], 30, 120.0, Vector2(70, 70))
	RingBurst.spawn(get_parent(), global_position + Vector2(0, -46), MAG)
	Sfx.play(&"boss_roar")
	_shake(4.0, 0.4)
	_play(&"alerta", true)
	await get_tree().create_timer(0.45).timeout
	_set_active(true)
	_apply_phase_look()
	state = State.WALK
	_timer = 0.8
	assembled.emit()


func _set_active(on: bool) -> void:
	hurtbox.set_physics_process(on)
	if on:
		contact.activate()
	else:
		contact.deactivate()


func _ai(delta: float) -> void:
	var speed := speed_scale()
	_hurt_left = maxf(_hurt_left - delta, 0.0)
	match state:
		State.WALK:
			var player := get_player()
			var close := player != null and absf(player.global_position.x - global_position.x) < 24.0
			if not close:
				facing = direction_to_player()
			velocity.x = 0.0 if close else facing * walk_speed * speed
			if _hurt_left <= 0.0:
				_play(&"quieto" if close else &"caminar")
				_sprite.speed_scale = speed
			_timer -= delta
			if _timer <= 0.0:
				_next_attack()
		State.WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			_play(&"preparar")
			_timer -= delta
			if _timer <= 0.0:
				state = State.CHARGE
				_charge_from = global_position.x
				contact.damage = 2.0
				_trail.clear()
				Sfx.play(&"boss_charge")
		State.CHARGE:
			velocity.x = facing * charge_speed * speed
			_play(&"embestir")
			_trail.append(global_position)
			if _trail.size() > 8:
				_trail.remove_at(0)
			if is_on_wall() or absf(global_position.x - _charge_from) > 560.0:
				_crash()
		State.CROUCH:
			velocity.x = 0.0
			_play(&"agachado")
			_timer -= delta
			if _timer <= 0.0:
				_stand_up()
		State.SHOOT:
			velocity.x = 0.0
			facing = direction_to_player()
			if _hurt_left <= 0.0:
				_play(&"quieto")
			_timer -= delta
			if _timer <= 0.0:
				_throw()
				_shots_left -= 1
				if _shots_left > 0:
					_timer = shot_gap / speed
				else:
					_walk(walk_time * 0.6)
		_:
			velocity.x = 0.0
	if state != State.CHARGE and not _trail.is_empty():
		_trail.remove_at(0)


## Alterna embestida y proyectiles (en la fase 2 la embestida ya trae sus proyectiles).
func _next_attack() -> void:
	if _next_charge:
		state = State.WINDUP
		facing = direction_to_player()
		_timer = windup_time / speed_scale()
		_play(&"preparar", true)
		_sprite.speed_scale = 4.0 / (windup_time / speed_scale() * 8.0)
		Sfx.play(&"brute_force", 0.8)
	else:
		_shoot(1 if phase == 1 else 2)
	_next_charge = not _next_charge


func _walk(seconds: float) -> void:
	state = State.WALK
	_timer = seconds / speed_scale()


func _shoot(count: int) -> void:
	state = State.SHOOT
	_shots_left = count
	_timer = shoot_windup / speed_scale()


func _throw() -> void:
	var dir := facing
	PasswordGuess.throw(get_parent(), global_position + Vector2(dir * 40.0, -8.0), dir, WEAK_PASSWORDS.pick_random())
	Sfx.play(&"popup_open", 0.7)
	_squash(Vector2(1.08, 0.94))


## Choca contra la pared (o termina la carrera) y queda agachado: el momento del pogo.
func _crash() -> void:
	state = State.CROUCH
	velocity.x = 0.0
	contact.damage = contact_damage
	_timer = crouch_time / speed_scale()
	_resize(CROUCHED)
	_sprite.speed_scale = 1.0
	_play(&"agachado", true)
	Sfx.play(&"boss_crash")
	_shake(3.0, 0.3)
	_squash(Vector2(1.12, 0.88))
	PixelBurst.spawn(get_parent(), global_position + Vector2(facing * 40.0, -24.0), [MAG, PINK], 12, 90.0)


func _stand_up() -> void:
	_resize(STAND)
	_squash(Vector2(0.94, 1.06))
	# En la fase 2 encadena: al levantarse dispara enseguida.
	if phase == 2:
		_shoot(2)
		_next_charge = true
	else:
		_walk(walk_time)


## Estiramiento breve del sprite (impactos, levantarse): el movimiento se siente más vivo.
func _squash(amount: Vector2) -> void:
	var base := Vector2.ONE * _base_scale
	var target := Vector2(base.x * amount.x, base.y * amount.y)
	_sprite.scale = target
	create_tween().tween_property(_sprite, "scale", base, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Cambia el tamaño del cuerpo, de la zona de daño y del contacto (apoyado en el suelo).
func _resize(size: Vector2) -> void:
	body_size = size
	var contact_shape := contact.get_child(0) as CollisionShape2D
	for shape: CollisionShape2D in [_body_shape, hurtbox.get_child(0), contact_shape]:
		if shape == null:
			continue
		var rect := RectangleShape2D.new()
		rect.size = size - Vector2(4, 4) if shape == contact_shape else size
		shape.shape = rect
		shape.position = Vector2(0, -size.y / 2.0)


func _on_damaged(hit: HitData) -> void:
	# Pogo sobre el jefe agachado: le quita el doble.
	var attacker := hit.source as Player
	if state == State.CROUCH and attacker and attacker.combat.is_down_attack():
		_popup("¡CRÍTICO!", HOT)
		health.take_damage(hit.damage)
	if state in [State.WALK, State.SHOOT] and not is_dead:
		_hurt_left = 0.25
		_play(&"dano", true)
	if phase == 1 and not is_dead and health.current <= max_health * 0.5:
		phase = 2
		_popup("¡VENTANAS INESTABLES!", RED)
		Sfx.play(&"brute_force")
		_shake(2.5, 0.3)
		_hurt_left = 0.4
		_play(&"alerta", true)
		_apply_phase_look()
		phase_changed.emit(2)


## En la fase 2 sus ventanas se vuelven inestables: glitch en franjas.
func _apply_phase_look() -> void:
	if phase < 2 or GameSettings.reduce_glitch:
		_sprite.material = null
		return
	var material := ShaderMaterial.new()
	material.shader = GLITCH
	material.set_shader_parameter(&"intensity", 0.8)
	_sprite.material = material


func _die() -> void:
	is_dead = true
	state = State.DYING
	contact.deactivate()
	hurtbox.set_physics_process(false)
	collision_layer = 0
	velocity = Vector2.ZERO
	died.emit()
	_death_sequence()


## Se tiñe de rojo con "ACCESO DENEGADO" en sus ventanas; después se desintegra (animación de la
## hoja) en píxeles magenta y fragmentos de código. Suelta sus Ecos y emite death_finished.
func _death_sequence() -> void:
	_denied = true
	_sprite.material = null
	_sprite.speed_scale = 1.0
	_play(&"dano", true)
	_sprite.modulate = Color(1.5, 0.55, 0.75)
	Sfx.play(&"access_denied")
	_shake(3.0, 0.5)
	await get_tree().create_timer(1.3).timeout
	_denied = false
	_sprite.modulate = Color.WHITE
	_play(&"muerte", true)
	for i in 6:
		PixelBurst.spawn(get_parent(), global_position + Vector2(randf_range(-36.0, 36.0), randf_range(-90.0, -20.0)), [MAG, PINK, HOT], 14, 100.0)
		Sfx.play(&"enemy_death", randf_range(1.1, 1.5), -4.0)
		await get_tree().create_timer(0.16).timeout
	for i in 40:
		var angle := randf_range(-PI, 0.0)
		_code.append({ "pos": Vector2(randf_range(-30.0, 30.0), randf_range(-80.0, -20.0)),
			"vel": Vector2(cos(angle), sin(angle)) * randf_range(30.0, 110.0), "life": randf_range(0.6, 1.2),
			"text": ["0", "1", "#", "*", "/", "x"].pick_random() })
	PixelBurst.spawn(get_parent(), global_position, [MAG, PINK, VIOLET, Color.WHITE], 40, 130.0, STAND, 0.9)
	Sfx.play(&"enemy_death", 0.7)
	_shake(4.0, 0.4)
	create_tween().tween_property(_sprite, "modulate:a", 0.0, 0.3)
	var room := get_parent()
	var center := global_position + Vector2(0, -30)
	var reward := get_ecos_reward()
	var economy := get_node_or_null("/root/Economy")
	if reward_id != &"" and economy and not economy.claim_drop(reward_id):
		reward = 0
	(func() -> void: EcoShard.spawn_burst(room, center, reward)).call_deferred()
	await get_tree().create_timer(1.1).timeout
	death_finished.emit()
	queue_free()


func _process(delta: float) -> void:
	for c in _code:
		c.vel.y += 60.0 * delta
		c.pos += c.vel * delta
		c.life -= delta
	_code = _code.filter(func(c: Dictionary) -> bool: return c.life > 0.0)


# --- Lo que se dibuja encima del sprite ---

func _paint_overlay(c: VectorCanvas, t: float) -> void:
	if state == State.HIDDEN or state == State.INTRO:
		_paint_intro(c, t)
	# Estela de la embestida (detrás del cuerpo, siguiendo su recorrido).
	for i in range(1, _trail.size()):
		var k := float(i) / _trail.size()
		var from := _trail[i - 1] - global_position
		var to := _trail[i] - global_position
		for y: float in [-24.0, -46.0, -68.0]:
			c.draw_line(from + Vector2(0, y), to + Vector2(0, y), Color(MAG, 0.5 * k), 1.0 + 3.0 * k)
	if _denied:
		for spot in DENIED_SPOTS:
			var size := Vector2(34, 10)
			var rect := Rect2(spot - size / 2.0 + Vector2(randf_range(-1.0, 1.0), 0), size)
			c.draw_rect(rect, DARK)
			c.draw_rect(rect, RED, false, 1.0)
			c.crisp_text(rect.position + Vector2(0, size.y - 2), "DENEGADO", 4, HOT, HORIZONTAL_ALIGNMENT_CENTER, size.x)
		var main := Rect2(Vector2(-26, -40), Vector2(52, 18))
		c.draw_rect(main, Color(DARK, 0.9))
		c.draw_rect(main, RED, false, 1.5)
		c.crisp_text(main.position + Vector2(0, 8), "ACCESO", 5, HOT, HORIZONTAL_ALIGNMENT_CENTER, main.size.x)
		c.crisp_text(main.position + Vector2(0, 16), "DENEGADO", 5, HOT, HORIZONTAL_ALIGNMENT_CENTER, main.size.x)
	for f in _code:
		c.crisp_text(f.pos, f.text, 5, Color(PINK, clampf(f.life / 0.4, 0.0, 1.0)), HORIZONTAL_ALIGNMENT_LEFT)


## La ventanita "123456" del principio y las ventanas de error que vuelan a juntarse.
func _paint_intro(c: VectorCanvas, t: float) -> void:
	var fade := 1.0 - smoothstep(0.5, 0.8, _assembly)
	if fade > 0.0:
		var size := Vector2(34, 18) * (1.0 + _assembly)
		var center := Vector2(0, -44 + sin(t * 2.0) * 2.0)
		c.glow(center, 26.0, Color(MAG, 0.18 * fade))
		var rect := Rect2(center - size / 2.0, size)
		c.draw_rect(rect, Color(DARK, fade))
		c.draw_rect(rect, Color(MAG, fade), false, 1.0)
		c.draw_rect(Rect2(rect.position, Vector2(size.x, 4)), Color(MAG, fade))
		c.crisp_text(rect.position + Vector2(0, size.y - 3), "123456", 5, Color(PINK, fade), HORIZONTAL_ALIGNMENT_CENTER, size.x)
	for f in _flying:
		if f.time < f.delay:
			continue
		var k := clampf((f.time - f.delay) / 0.6, 0.0, 1.0)
		if k >= 1.0:
			continue
		var pos: Vector2 = f.start.lerp(Vector2(0, -46), k * k)
		var size: Vector2 = f.size * minf(1.0, (f.time - f.delay) * 6.0)
		var rect := Rect2(pos - size / 2.0, size)
		c.draw_rect(rect, DARK)
		c.draw_rect(rect, Color(MAG, 0.9), false, 1.0)
		c.draw_rect(Rect2(rect.position, Vector2(size.x, 2)), MAG)
		c.crisp_text(rect.position + Vector2(0, size.y - 1.5), f.text, 3, PINK, HORIZONTAL_ALIGNMENT_CENTER, size.x)


func _popup(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.scale = Vector2(0.5, 0.5)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	label.add_theme_constant_override("outline_size", 6)
	label.z_index = 20
	var parent := get_parent()
	if parent == null:
		return
	parent.add_child(label)
	label.global_position = global_position + Vector2(-text.length() * 2.2, -130)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 18.0, 0.9).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


func _shake(strength: float, duration: float) -> void:
	var room := owner as Room if owner else get_parent() as Room
	if room and room.camera:
		room.camera.shake(strength, duration)

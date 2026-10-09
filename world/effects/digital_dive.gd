class_name DigitalDive
extends Node2D
## Efecto de "succión": Kai es absorbido por una pantalla. La pantalla brilla, la cámara se acerca,
## píxeles de Kai vuelan hacia la pantalla, Kai se estira, gira y se encoge dentro, y un destello
## blanco cubre todo. materialize() hace lo contrario al llegar (los píxeles se juntan).
## Uso: await DigitalDive.dive(jugador, punto_de_pantalla, camara)

const CYAN := Color("3ef2ff")
const VIOLET := Color("a77bff")
const LIGHT_TEXTURE := preload("res://assets/art/light_soft.tres")
const PARTICLE_COLORS: Array[Color] = [Color("3ef2ff"), Color("a77bff"), Color("e9f6ff"), Color("1fa5c4")]


## Absorbe a Kai hacia screen_point. Termina con la pantalla en blanco (el destello queda puesto
## para que la siguiente pantalla lo cubra).
static func dive(player: Player, screen_point: Vector2, camera: GameCamera) -> void:
	var effect := DigitalDive.new()
	player.get_parent().add_child(effect)
	await effect._dive(player, screen_point, camera)


## Kai aparece armándose desde píxeles (al llegar a la computadora).
static func materialize(player: Player) -> void:
	var effect := DigitalDive.new()
	player.get_parent().add_child(effect)
	await effect._materialize(player)
	effect.queue_free()


func _dive(player: Player, screen_point: Vector2, camera: GameCamera) -> void:
	var body := player.get_node("Visual/Body") as Node2D
	# 1. La pantalla brilla.
	var glow := PointLight2D.new()
	glow.texture = LIGHT_TEXTURE
	glow.color = CYAN
	glow.energy = 0.0
	glow.texture_scale = 0.6
	glow.global_position = screen_point
	add_child(glow)
	var tween := create_tween().set_parallel()
	tween.tween_property(glow, "energy", 3.0, 1.2)
	tween.tween_property(glow, "texture_scale", 2.2, 1.6)
	# 2. La cámara deja de seguir a Kai y se acerca a la pantalla.
	if camera:
		camera.target = null
		var focus := (player.global_position + Vector2(0, -16)).lerp(screen_point, 0.6)
		tween.tween_property(camera, "global_position", focus, 1.4).set_trans(Tween.TRANS_SINE)
		tween.tween_property(camera, "zoom", Vector2(3.2, 3.2), 1.6).set_trans(Tween.TRANS_SINE)
	# 3. Píxeles de Kai vuelan hacia la pantalla.
	_spawn_pixels(player.global_position + Vector2(0, -20), screen_point, 46, 1.6, false)
	await get_tree().create_timer(0.7).timeout
	# 4. Kai se estira hacia la pantalla, gira y se encoge dentro.
	var target: Vector2 = (body.get_parent() as Node2D).to_local(screen_point)
	var suck := create_tween()
	suck.tween_property(body, "scale", Vector2(1.5, 0.55), 0.25).set_trans(Tween.TRANS_BACK)
	suck.parallel().tween_property(body, "modulate", Color(0.6, 1.4, 1.6), 0.25)
	suck.tween_property(body, "position", target, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	suck.parallel().tween_property(body, "scale", Vector2(0.04, 0.04), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	suck.parallel().tween_property(body, "rotation", -TAU * 0.75, 0.55).set_ease(Tween.EASE_IN)
	await suck.finished
	body.visible = false
	# 5. Destello blanco.
	var flash := CanvasLayer.new()
	flash.layer = 85
	add_child(flash)
	var white := ColorRect.new()
	white.color = Color(1, 1, 1, 0)
	white.set_anchors_preset(Control.PRESET_FULL_RECT)
	white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.add_child(white)
	var flash_tween := create_tween()
	flash_tween.tween_property(white, "color:a", 1.0, 0.25)
	await flash_tween.finished


func _materialize(player: Player) -> void:
	var body := player.get_node("Visual/Body") as Node2D
	var center := player.global_position + Vector2(0, -20)
	body.visible = false
	_spawn_pixels(center, center, 40, 0.8, true)
	await get_tree().create_timer(0.75).timeout
	body.visible = true
	body.scale = Vector2(0.3, 1.6)
	body.modulate = Color(1.6, 1.8, 2.0)
	var tween := create_tween().set_parallel()
	tween.tween_property(body, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(body, "modulate", Color.WHITE, 0.5)
	await tween.finished


## Cuadraditos de 2 px. inward = false: salen de from y viajan a to. inward = true: llegan a from
## desde un anillo alrededor (se juntan).
func _spawn_pixels(from: Vector2, to: Vector2, count: int, duration: float, inward: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in count:
		var pixel := Polygon2D.new()
		pixel.polygon = PackedVector2Array([Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)])
		pixel.color = PARTICLE_COLORS[i % PARTICLE_COLORS.size()]
		pixel.z_index = 5
		add_child(pixel)
		var start: Vector2
		var end: Vector2
		if inward:
			start = from + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(30, 70)
			end = from + Vector2(rng.randf_range(-6, 6), rng.randf_range(-18, 18))
		else:
			start = from + Vector2(rng.randf_range(-6, 6), rng.randf_range(-18, 18))
			end = to + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3))
		pixel.global_position = start
		var delay := rng.randf() * duration * 0.5
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(pixel, "global_position", end, duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(pixel, "modulate:a", 0.0 if not inward else 1.0, duration * 0.5)
		tween.tween_callback(pixel.queue_free)

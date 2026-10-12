class_name NullbladeReveal
extends Node2D
## La Nullblade se materializa por primera vez: una escena de cine (secuencia de la hoja de Ariel).
## Aparecen franjas negras, la pantalla se oscurece a violeta con un foco sobre Kai, la cámara se
## acerca y la música baja. Después:
##   1. Activación: Kai se agacha y un pulso de datos sube desde el suelo.
##   2. Manifestación: fragmentos de código giran y se expanden; baja una columna de luz.
##   3. Condensación: los fragmentos se juntan en el eje y la espada se define en el aire, con la punta hacia arriba.
##   4. Materialización: destello blanco, golpe grave, ondas y rayos; la espada flota estable y su núcleo late.
##   5. Empuñadura: Kai extiende la mano y la espada vuela hacia ella dejando una estela.
##   6. Lista: Kai la prueba con un tajo, y la escena vuelve a la normalidad.
## Después muestra la tarjeta "NUEVO EQUIPAMIENTO DESBLOQUEADO".
## Uso: await NullbladeReveal.play(jugador)

signal done

const SWORD := preload("res://assets/art/items/nullblade/nullblade_espada.png")
const ART := preload("res://assets/art/items/nullblade/nullblade_arte.png")
const SHADE := preload("res://world/effects/reveal_shade.gdshader")
const VIOLET := Color("8a5cff")
const LIGHT := Color("d9ccff")
const DEEP := Color("4b2bd6")
## Fin de cada fase (segundos desde el inicio).
const INTRO := 0.5
const ACTIVATION := 1.4
const MANIFEST := 2.4
const CONDENSE := 3.3
const MATERIALIZE := 4.3
const GRIP := 4.9
const FLOURISH := 5.5
const READY := 6.0
## Tamaño final de la espada flotando.
const SWORD_SCALE := 0.8
## Alto de las franjas de cine (píxeles de pantalla), cuánto se acerca la cámara y cuánto se oscurece.
const BAR_HEIGHT := 64.0
const ZOOM_IN := 1.3
const DARKNESS := 0.9
## Punto de la textura de la espada donde está el núcleo (la guarda), desde su centro.
const CORE_OFFSET := Vector2(0, -19)

var player: Player
var _time := 0.0
var _phase := 0
var _fragments: Array[Dictionary] = []
## Ondas expansivas: { "r", "speed", "life", "max" }.
var _rings: Array[Dictionary] = []
var _trail: Array[Vector2] = []
var _flash := 0.0
var _rumble := 0.0
var _sword: Sprite2D
var _light: PointLight2D
var _grip_from := Vector2.ZERO
var _grip_target := Vector2.ZERO
var _camera: Camera2D
var _base_zoom := Vector2.ONE
# Capa de cine (encima del mundo y del HUD).
var _layer: CanvasLayer
var _shade: ColorRect
var _bars: Array[ColorRect] = []
var _white: ColorRect
## Dibuja los efectos encima de la oscuridad, en coordenadas del mundo (sigue a la cámara).
var _fx: Node2D


## Reproduce la animación y la tarjeta; termina cuando el jugador cierra la tarjeta.
static func play(target: Player, show_card := true) -> void:
	var reveal := NullbladeReveal.new()
	reveal.player = target
	target.get_parent().add_child(reveal)
	reveal.global_position = target.global_position + Vector2(22 * target.facing, -24)
	await reveal.done
	reveal.queue_free()
	if show_card:
		await EquipmentCard.show_card(target, {
			"art": ART,
			"subtitle": "NUEVO EQUIPAMIENTO DESBLOQUEADO",
			"title": "NULLBLADE",
			"description": "Una hoja forjada a partir de código fragmentado,\ncapaz de cortar las amenazas que corrompen el sistema.",
			"banner": "¡NULLBLADE OBTENIDA!",
			"action": &"attack",
			"hint": "Pulsa %s para atacar" % GameSettings.key_name(&"attack"),
		})


func _ready() -> void:
	_build_layer()
	_sword = Sprite2D.new()
	_sword.texture = SWORD
	_sword.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Punta hacia arriba, como en la hoja de concepto.
	_sword.rotation = PI
	_sword.scale = Vector2.ZERO
	_sword.visible = false
	_fx.add_child(_sword)
	_light = PointLight2D.new()
	_light.texture = load("res://assets/art/light_soft.tres")
	_light.color = VIOLET
	_light.energy = 0.0
	_light.texture_scale = 1.6
	add_child(_light)
	var room := player.owner as Room
	_camera = room.camera if room else null
	if _camera:
		_base_zoom = _camera.zoom
	_kai_pose(&"curar_suelo_inicio", GRIP)
	Music.duck(-16.0, 0.6)
	Sfx.play(&"reveal_gather")


func _build_layer() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 45
	add_child(_layer)
	_shade = ColorRect.new()
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = SHADE
	_shade.material = material
	_layer.add_child(_shade)
	_fx = Node2D.new()
	_fx.draw.connect(_draw_fx)
	_layer.add_child(_fx)
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if top else 1.0
		bar.anchor_bottom = bar.anchor_top
		_layer.add_child(bar)
		_bars.append(bar)
	_white = ColorRect.new()
	_white.set_anchors_preset(Control.PRESET_FULL_RECT)
	_white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_white.color = Color(1, 1, 1, 0)
	_layer.add_child(_white)
	# Las franjas van encima de todo (también del destello).
	for bar in _bars:
		_layer.move_child(bar, -1)


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(_flash - delta * 2.6, 0.0)
	var reduced := GameSettings.reduce_glitch
	if _time < ACTIVATION:
		_activation()
	elif _time < MANIFEST:
		_manifest()
	elif _time < CONDENSE:
		_condense(delta, reduced)
	elif _time < MATERIALIZE:
		_materialize()
	elif _time < GRIP:
		_grip()
	elif _time < READY:
		_flourish()
	else:
		_finish()
		return
	_update_fragments(delta)
	_update_rings(delta)
	_update_cinematic(reduced)
	_fx.queue_redraw()


# --- Fases ---

## 1. Kai se agacha y un pulso de datos sube desde el suelo.
func _activation() -> void:
	if _time > 0.25:
		for i in 3:
			_spawn_rising()
	_light.energy = lerpf(0.0, 0.6, clampf(_time / ACTIVATION, 0.0, 1.0))


## 2. Los fragmentos giran y se expanden; baja la columna de luz.
func _manifest() -> void:
	if _phase < 2:
		_phase = 2
		_rings.append({ "r": 4.0, "speed": 70.0, "life": 0.6, "max": 0.6 })
	for i in 6:
		_spawn_orbit()
	_spawn_rising()
	_light.energy = lerpf(0.6, 1.2, (_time - ACTIVATION) / (MANIFEST - ACTIVATION))


## 3. Todo se junta en el eje y la espada se define, parpadeando.
func _condense(delta: float, reduced: bool) -> void:
	_phase = 3
	var t := (_time - MANIFEST) / (CONDENSE - MANIFEST)
	var grow := ease(t, 0.6)
	_sword.visible = true
	_sword.scale = Vector2(lerpf(0.04, SWORD_SCALE, grow), lerpf(0.25, SWORD_SCALE, grow))
	_sword.modulate = Color(2.2, 2.0, 2.6, (0.3 + 0.7 * t) * (randf_range(0.45, 1.0) if not reduced else 1.0))
	_sword.position = Vector2(randf_range(-1.5, 1.5) if not reduced and randf() < 0.3 else 0.0, 0.0)
	_light.energy = lerpf(1.2, 1.9, t)
	for i in 2:
		_spawn_orbit(lerpf(50.0, 20.0, t))
	# Un temblor que crece hasta el destello.
	_rumble -= delta
	if _rumble <= 0.0:
		_rumble = 0.12
		_shake(0.6 + t * 1.4, 0.14)


## 4. Destello, golpe y la espada estable flotando.
func _materialize() -> void:
	if _phase < 4:
		_phase = 4
		_flash = 1.0
		_burst(40)
		_rings.append({ "r": 6.0, "speed": 220.0, "life": 0.55, "max": 0.55 })
		_rings.append({ "r": 2.0, "speed": 120.0, "life": 0.8, "max": 0.8 })
		Sfx.play(&"reveal_boom")
		Sfx.play(&"reveal_flash")
		_shake(4.0, 0.45)
	var t := (_time - CONDENSE) / (MATERIALIZE - CONDENSE)
	_sword.scale = Vector2(SWORD_SCALE, SWORD_SCALE)
	_sword.position = Vector2(0, sin(_time * 5.0) * 2.0)
	_sword.modulate = Color(1, 1, 1, 1).lerp(Color(2.4, 2.2, 2.8, 1), maxf(_flash, 0.25 + 0.15 * sin(_time * 9.0)))
	_light.energy = lerpf(2.4, 1.3, t)
	if randf() < 0.5:
		_spawn_orbit(18.0)


## 5. Kai extiende la mano y la espada vuela hacia ella.
func _grip() -> void:
	if _phase < 5:
		_phase = 5
		_kai_pose(&"ataque_1", GRIP - MATERIALIZE + 0.1)
		_grip_from = _sword.position
		_grip_target = to_local(player.global_position + Vector2(12 * player.facing, -16))
		Sfx.play(&"dash", 1.3)
	var t := ease((_time - MATERIALIZE) / (GRIP - MATERIALIZE), 2.2)
	_sword.position = _grip_from.lerp(_grip_target, t)
	_sword.rotation = lerp_angle(PI, -PI * 0.5 * player.facing, t)
	_sword.scale = Vector2.ONE * lerpf(SWORD_SCALE, 0.5, t)
	_sword.modulate = Color(1.6, 1.5, 2.0, 1.0 - smoothstep(0.75, 1.0, t))
	_trail.append(_sword.position)
	if _trail.size() > 8:
		_trail.remove_at(0)
	for i in 2:
		_spawn_fragment(_grip_target, 14.0)
	_light.position = _sword.position
	_light.energy = lerpf(1.3, 0.9, t)


## 6. Kai la prueba con un tajo; la escena vuelve a la normalidad.
func _flourish() -> void:
	if _phase < 6:
		_phase = 6
		_sword.visible = false
		_trail.clear()
		_flash = 0.35
		_rings.append({ "r": 2.0, "speed": 90.0, "life": 0.35, "max": 0.35, "at": _grip_target })
		_burst(16, _grip_target)
		_kai_pose(&"ataque_2", 0.45)
		Sfx.play(&"reveal_grip")
		Sfx.play(&"slash")
	_light.energy = lerpf(0.9, 0.0, (_time - GRIP) / (READY - GRIP))


func _finish() -> void:
	if _camera:
		_camera.zoom = _base_zoom
	Music.duck(0.0, 0.8)
	_layer.visible = false
	set_process(false)
	done.emit()


## Franjas, oscuridad con foco, acercamiento de cámara y destello blanco.
func _update_cinematic(reduced: bool) -> void:
	var into := smoothstep(0.0, INTRO, _time)
	var out := smoothstep(FLOURISH, READY, _time)
	var amount := into * (1.0 - out)
	for i in _bars.size():
		var bar := _bars[i]
		var height := BAR_HEIGHT * amount
		bar.offset_top = 0.0 if i == 0 else -height
		bar.offset_bottom = height if i == 0 else 0.0
	_fx.transform = get_global_transform_with_canvas()
	var zoom := _fx.transform.get_scale().x
	var kai := to_local(player.global_position + Vector2(0, -16))
	var material := _shade.material as ShaderMaterial
	material.set_shader_parameter(&"center", _fx.transform * (kai * 0.5))
	material.set_shader_parameter(&"radius", 46.0 * zoom)
	material.set_shader_parameter(&"softness", 120.0 * zoom)
	var deeper := 0.1 * smoothstep(MANIFEST, CONDENSE, _time) * (1.0 - smoothstep(CONDENSE, MATERIALIZE, _time))
	material.set_shader_parameter(&"strength", (DARKNESS + deeper) * amount)
	if _camera:
		_camera.zoom = _base_zoom * lerpf(1.0, ZOOM_IN, amount)
	_white.color.a = _flash * (0.3 if reduced else 0.85)


# --- Dibujo ---

func _draw_fx() -> void:
	_draw_ground()
	_draw_columns()
	_draw_beam()
	_draw_rays()
	for ring in _rings:
		var alpha: float = ring.life / ring.max
		var at: Vector2 = ring.get("at", Vector2.ZERO)
		_fx.draw_arc(at, ring.r, 0.0, TAU, 40, Color(LIGHT, alpha), 2.0)
		_fx.draw_arc(at, ring.r * 0.8, 0.0, TAU, 40, Color(VIOLET, alpha * 0.6), 1.0)
	for i in range(1, _trail.size()):
		var k := float(i) / _trail.size()
		_fx.draw_line(_trail[i - 1], _trail[i], Color(VIOLET, 0.7 * k), 1.0 + 4.0 * k)
	for f in _fragments:
		var c: Color = f.color
		c.a *= clampf(f.life / 0.3, 0.0, 1.0)
		_fx.draw_rect(Rect2(f.pos.round(), f.size), c)
	if _phase == 6:
		_draw_slash()
	# Glitch: franjas horizontales que cortan la pantalla justo después del destello.
	if _phase == 4 and _time < CONDENSE + 0.35 and not GameSettings.reduce_glitch:
		for i in 6:
			var y := randf_range(-90.0, 40.0)
			var x := randf_range(-260.0, 120.0)
			_fx.draw_rect(Rect2(x, y, randf_range(60.0, 200.0), randf_range(1.0, 4.0)), Color([VIOLET, LIGHT, DEEP].pick_random(), randf_range(0.3, 0.7)))


## Brillo en el suelo bajo el punto donde aparece la espada.
func _draw_ground() -> void:
	var g := smoothstep(0.2, ACTIVATION, _time) * (1.0 - smoothstep(MATERIALIZE, GRIP, _time))
	if g <= 0.0:
		return
	var pulse := 1.0 + 0.08 * sin(_time * 10.0)
	_fx.draw_set_transform(Vector2(0, 24), 0.0, Vector2(1.0, 0.2))
	_fx.draw_circle(Vector2.ZERO, 40.0 * g * pulse, Color(DEEP, 0.35 * g))
	_fx.draw_circle(Vector2.ZERO, 26.0 * g * pulse, Color(VIOLET, 0.4 * g))
	_fx.draw_circle(Vector2.ZERO, 12.0 * g, Color(LIGHT, 0.5 * g))
	_fx.draw_set_transform(Vector2.ZERO)


## Líneas de datos verticales que suben desde el suelo.
func _draw_columns() -> void:
	var strength := smoothstep(0.2, ACTIVATION, _time) * (1.0 - smoothstep(MANIFEST, CONDENSE, _time))
	if strength <= 0.0:
		return
	for i in 11:
		var x := (i - 5) * 5.0 + sin(_time * 3.0 + i) * 2.0
		var length := 24.0 + 40.0 * absf(sin(_time * 4.0 + i * 1.7))
		_fx.draw_line(Vector2(x, 24), Vector2(x, 24 - length), Color(VIOLET, 0.55 * strength), 1.0)
		_fx.draw_rect(Rect2(x - 0.5, 24 - length - 2, 1, 2), Color(LIGHT, 0.8 * strength))


## Columna de luz que baja del cielo hasta el suelo y se condensa en la espada.
func _draw_beam() -> void:
	var b := smoothstep(ACTIVATION, MANIFEST, _time) * (1.0 - smoothstep(CONDENSE, CONDENSE + 0.2, _time))
	if b <= 0.0:
		return
	var width := 2.0 + 10.0 * b * (1.0 - 0.6 * smoothstep(MANIFEST, CONDENSE, _time))
	var top := -260.0 + 230.0 * (1.0 - b)
	_fx.draw_rect(Rect2(-width * 1.6, top, width * 3.2, 24.0 - top), Color(DEEP, 0.25 * b))
	_fx.draw_rect(Rect2(-width * 0.5, top, width, 24.0 - top), Color(VIOLET, 0.45 * b))
	_fx.draw_rect(Rect2(-1.0, top, 2.0, 24.0 - top), Color(LIGHT, 0.8 * b))


## Rayos que giran detrás de la espada, halo y el núcleo que late.
func _draw_rays() -> void:
	var s := smoothstep(CONDENSE, CONDENSE + 0.1, _time) * (1.0 - smoothstep(MATERIALIZE - 0.3, MATERIALIZE, _time))
	if s <= 0.0:
		return
	var center := _sword.position
	for i in 12:
		var angle := _time * 0.7 + TAU * i / 12.0
		var dir := Vector2(cos(angle), sin(angle))
		var side := dir.orthogonal() * (1.5 if i % 2 == 0 else 1.0)
		var reach := 85.0 if i % 2 == 0 else 55.0
		_fx.draw_colored_polygon(PackedVector2Array([center + side, center + dir * reach, center - side]), Color(LIGHT, 0.28 * s))
	_fx.draw_circle(center, 22.0, Color(DEEP, 0.25 * s))
	_fx.draw_circle(center, 13.0, Color(VIOLET, 0.25 * s))
	var core := _sword.transform * CORE_OFFSET
	var beat := 0.5 + 0.5 * sin(_time * 12.0)
	_fx.draw_circle(core, 3.0 + 2.0 * beat, Color(LIGHT, 0.5 * s))
	_fx.draw_circle(core, 1.5, Color(1, 1, 1, s))


## El tajo de prueba: una media luna violeta frente a Kai.
func _draw_slash() -> void:
	var t := clampf((_time - GRIP) / 0.22, 0.0, 1.0)
	var fade := 1.0 - smoothstep(GRIP + 0.2, GRIP + 0.45, _time)
	if fade <= 0.0:
		return
	var center := to_local(player.global_position + Vector2(4 * player.facing, -18))
	var start := deg_to_rad(-110.0)
	var sweep := deg_to_rad(170.0) * t
	if player.facing < 0:
		start = PI - start
		sweep = -sweep
	for k in 3:
		var radius := 24.0 - k * 3.0
		var color := [LIGHT, VIOLET, DEEP][k] as Color
		_fx.draw_arc(center, radius, start, start + sweep, 20, Color(color, fade * (0.9 - k * 0.2)), 3.0 - k * 0.5)


# --- Fragmentos ---

## Un bit que sube desde el suelo.
func _spawn_rising() -> void:
	_fragments.append({
		"pos": Vector2(randf_range(-28.0, 28.0), 24.0), "vel": Vector2(0, -randf_range(40.0, 120.0)),
		"life": randf_range(0.5, 1.0), "size": Vector2([1, 1, 2].pick_random(), [2, 3].pick_random()),
		"color": [VIOLET, LIGHT, DEEP].pick_random(),
	})


## Un fragmento que gira alrededor del centro (más lejos con radius).
func _spawn_orbit(radius := 40.0) -> void:
	var angle := randf() * TAU
	var r := randf_range(radius * 0.3, radius)
	var pos := Vector2(cos(angle), sin(angle) * 0.7) * r
	var tangent := Vector2(-sin(angle), cos(angle) * 0.7) * r * 3.0
	_fragments.append({
		"pos": pos, "vel": tangent + pos * 0.8, "life": randf_range(0.4, 0.8),
		"size": Vector2([1, 1, 2, 3].pick_random(), [1, 2, 2].pick_random()),
		"color": [VIOLET, LIGHT, DEEP, Color.WHITE].pick_random(),
	})


## Un fragmento que viaja hacia "to" (la mano de Kai).
func _spawn_fragment(to: Vector2, radius: float) -> void:
	var angle := randf() * TAU
	var start := to + Vector2(cos(angle), sin(angle)) * radius
	_fragments.append({
		"pos": start, "vel": (to - start) * 4.0, "life": randf_range(0.2, 0.35),
		"size": Vector2([1, 2].pick_random(), [1, 2].pick_random()), "color": [VIOLET, LIGHT].pick_random(),
	})


func _update_fragments(delta: float) -> void:
	var condensing := _time >= MANIFEST and _time < CONDENSE
	for f in _fragments:
		if condensing:
			# Se juntan hacia el eje de la espada.
			f.vel = f.vel.lerp(Vector2(-f.pos.x * 7.0, -f.pos.y * 1.2), 0.2)
		f.pos += f.vel * delta
		f.vel *= 0.96
		f.life -= delta
	_fragments = _fragments.filter(func(f: Dictionary) -> bool: return f.life > 0.0)


func _update_rings(delta: float) -> void:
	for ring in _rings:
		ring.r += ring.speed * delta
		ring.life -= delta
	_rings = _rings.filter(func(ring: Dictionary) -> bool: return ring.life > 0.0)


func _burst(count: int, at := Vector2.ZERO) -> void:
	for i in count:
		var angle := TAU * i / count
		_fragments.append({
			"pos": at, "vel": Vector2(cos(angle), sin(angle)) * randf_range(60.0, 130.0),
			"life": randf_range(0.3, 0.7), "size": Vector2(2, 2), "color": [LIGHT, VIOLET, Color.WHITE].pick_random(),
		})


func _kai_pose(anim: StringName, seconds: float) -> void:
	var kai := player.get_node_or_null("Visual/Body/Kai")
	if kai and kai.has_method("play_pose"):
		kai.play_pose(anim, seconds)


func _shake(strength: float, duration: float) -> void:
	if _camera and _camera.has_method("shake"):
		_camera.shake(strength, duration)

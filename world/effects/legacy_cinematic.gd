class_name LegacyCinematic
extends Node2D
## Cinemática «El legado olvidado» (storyboard de Ariel), en el cuarto viejo del colegio, al tomar el Grimorio:
##   1. El descubrimiento: franjas de cine y la oscuridad se cierra sobre Kai y el libro.
##   2. El Grimorio despierta: el libro flota, se abre y de él salen hologramas (mapa, inventario, conceptos,
##      amenazas y registros). Cartel «GRIMORIO DESBLOQUEADO».
##   3. La conexión: las páginas pasan solas y una luz violeta se enciende
##      al otro lado del cuarto.
##   4. La recuperación: Kai camina hasta la luz; los fragmentos de código forman la Nullblade, que vuela a su
##      mano (NullbladeReveal). Cartel «NULLBLADE RECUPERADA».
##   5. El nuevo comienzo: el Grimorio registra la espada (su ícono vuela al libro) y la cámara vuelve a la normalidad.
## Las tarjetas son las de equipamiento del concepto de Ariel (EquipmentCard): la del Grimorio usa su arte
## (GRIMORIO_ART) y la de la Nullblade, el de la espada.
## Uso: await LegacyCinematic.play(jugador, pie_del_libro, centro_de_la_espada)
## Con with_blade = false (la espada ya se tenía, partida vieja) solo pasa lo del Grimorio.

signal done

const SHADE := preload("res://world/effects/reveal_shade.gdshader")
const VIOLET := Color("8a5cff")
const LIGHT := Color("d9ccff")
const DEEP := Color("4b2bd6")
const CYAN := Color("4fe3ff")
const BAR_HEIGHT := 64.0
## Arte del Grimorio para su tarjeta (del diseño de Ariel: tools/art/extraer_grimorio.gd).
const GRIMORIO_ART := preload("res://assets/art/items/grimorio/grimorio_arte.png")
## El libro en el mundo (a la mitad).
const BOOK := preload("res://assets/art/items/grimorio/grimorio_libro.png")
const BOOK_SCALE := 0.5
## La animación del libro abriéndose (seis cuadros iguales, en fila).
const OPENING := preload("res://assets/art/items/grimorio/grimorio_abriendo.png")
const OPENING_CELL := Vector2i(136, 106)
const FLOAT_GROW := 1.45
## Cuánto sube el libro al flotar (px) y su altura en el escritorio (centro, desde el pie).
const LIFT := 34.0
const REST_Y := -34.0
## Hologramas: nombre y dónde quedan (desde el centro del libro).
const PANELS := [
	["INVENTARIO", Vector2(-22, -58)],
	["MAPA", Vector2(34, -42)],
	["CONCEPTOS", Vector2(-58, -26)],
	["AMENAZAS", Vector2(-52, 12)],
	["REGISTROS", Vector2(44, 6)],
]
const PANEL_SIZE := Vector2(26, 24)

var player: Player
## Dónde se forma la Nullblade (en coordenadas de este nodo, que está al pie del libro).
var blade := Vector2.ZERO
var with_blade := true

var book_lift := 0.0
var book_open := 0.0
var panels_out := 0.0
var flip := 0.0
var pillar := 0.0
var register := 0.0
var register_fly := 0.0
## Al final el libro se cierra y vuela hasta Kai (se lo lleva).
var book_take := 0.0
var bars := 0.0
var shade := 0.0

var _time := 0.0
var _particles: Array[Dictionary] = []
var _layer: CanvasLayer
var _shade_rect: ColorRect
var _fx: Node2D
var _bars: Array[ColorRect] = []
var _camera: Camera2D
var _base_zoom := Vector2.ONE
## Luces violetas de verdad (iluminan el cuarto oscuro): la del libro y la de la columna de la espada.
var _book_light: PointLight2D
var _pillar_light: PointLight2D


## Reproduce la cinemática completa (con los dos carteles) y termina cuando la cámara vuelve a la normalidad.
static func play(target: Player, book_foot: Vector2, blade_center: Vector2, with_blade := true) -> void:
	var cinematic := LegacyCinematic.new()
	cinematic.player = target
	cinematic.with_blade = with_blade
	target.get_parent().add_child(cinematic)
	cinematic.global_position = book_foot
	cinematic.blade = blade_center - book_foot
	cinematic._run()
	await cinematic.done
	cinematic.queue_free()


## Tarjeta «GRIMORIO» (como la de equipamiento, con el arte del libro).
static func grimorio_card(from: Node) -> void:
	await EquipmentCard.show_card(from, {
		"art": GRIMORIO_ART,
		"subtitle": "NUEVO SISTEMA DESBLOQUEADO",
		"title": "GRIMORIO",
		"description": "Aquí se guardará todo tu progreso:\ninventario, mapa, conceptos, amenazas y registros.",
		"banner": "¡GRIMORIO DESBLOQUEADO!",
		"action": &"grimorio",
		"hint": "Pulsa %s para abrirlo" % GameSettings.key_name(&"grimorio"),
	})


## Tarjeta «NULLBLADE» (la del concepto de Ariel, con el arte de la espada).
static func nullblade_card(from: Node) -> void:
	await EquipmentCard.show_card(from, {
		"art": NullbladeReveal.ART,
		"subtitle": "NUEVO EQUIPAMIENTO DESBLOQUEADO",
		"title": "NULLBLADE",
		"description": "Una hoja forjada a partir de código fragmentado,\ncapaz de cortar las amenazas que corrompen el sistema.",
		"banner": "¡NULLBLADE RECUPERADA!",
		"action": &"attack",
		"hint": "Pulsa %s para atacar" % GameSettings.key_name(&"attack"),
	})


func _ready() -> void:
	z_index = 20
	_layer = CanvasLayer.new()
	_layer.layer = 44
	add_child(_layer)
	_shade_rect = ColorRect.new()
	_shade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = SHADE
	_shade_rect.material = material
	_layer.add_child(_shade_rect)
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
	_book_light = _make_light(1.2)
	_pillar_light = _make_light(1.6)
	var room := player.owner as Room
	_camera = room.camera if room else null
	if _camera:
		_base_zoom = _camera.zoom


func _run() -> void:
	player.controls_locked = true
	player.velocity.x = 0.0
	player.face(1 if global_position.x >= player.global_position.x else -1)
	Music.duck(-14.0, 0.6)
	# 1. El descubrimiento.
	await _to({ "bars": 1.0, "shade": 0.45 }, 0.6)
	# 2. El Grimorio despierta: flota y se abre.
	Sfx.play(&"reveal_gather", 1.3, -6.0)
	await _to({ "book_lift": 1.0 }, 1.3)
	Sfx.play(&"book_open")
	Sfx.play(&"reveal_flash", 1.2, -6.0)
	_burst(_book_center(), 18, VIOLET)
	await _to({ "book_open": 1.0 }, 0.45)
	# Un nuevo sistema: los hologramas.
	Sfx.play(&"popup_open")
	await _to({ "panels_out": 1.0 }, 0.8)
	await _wait(1.6)
	await _to({ "panels_out": 0.0 }, 0.35)
	await grimorio_card(self)
	if with_blade:
		await _blade_part()
	# Vuelve a la normalidad.
	await _to({ "book_open": 0.0 }, 0.4)
	Sfx.play(&"book_close")
	await _to({ "book_take": 1.0 }, 0.45)
	_burst(_book_center(), 14, VIOLET)
	await _to({ "bars": 0.0, "shade": 0.0 }, 0.6)
	Music.duck(0.0, 0.8)
	done.emit()


func _blade_part() -> void:
	# 3. La conexión: las páginas pasan solas y se enciende la luz al otro lado.
	flip = 1.0
	for i in 4:
		Sfx.play(&"book_page", 1.0 + i * 0.1)
		await _wait(0.18)
	await _wait(0.3)
	Sfx.play(&"distant_signal")
	await _to({ "pillar": 1.0 }, 0.8)
	_shake(1.5, 0.4)
	await _wait(0.7)
	flip = 0.0
	# El libro vuelve al escritorio (abierto, brillando) mientras Kai se acerca a la luz.
	_to({ "book_lift": 0.25 }, 0.6)
	var side := signf(blade.x) if blade.x != 0.0 else 1.0
	await _walk_to(global_position.x + blade.x - side * 48.0)
	player.face(int(side))
	# 4. La recuperación (la oscuridad y el foco los pone NullbladeReveal).
	_to({ "shade": 0.0, "pillar": 0.0 }, 0.5)
	await NullbladeReveal.play(player, false, global_position + blade)
	await nullblade_card(self)
	# 5. El nuevo comienzo: el Grimorio registra la espada.
	await _to({ "shade": 0.4, "register": 1.0, "book_lift": 0.5 }, 0.5)
	await _wait(0.5)
	Sfx.play(&"dash", 1.4, -6.0)
	await _to({ "register_fly": 1.0 }, 0.7)
	Sfx.play(&"terminal_ok")
	_burst(_book_center(), 26, LIGHT)
	_burst(_book_center(), 16, VIOLET)
	await _wait(0.7)
	await _to({ "register": 0.0 }, 0.35)


func _process(delta: float) -> void:
	_time += delta
	_update_particles(delta)
	if book_lift > 0.05 and book_take < 1.0 and randf() < 0.5:
		_spawn(_book_center() + Vector2(randf_range(-14, 14), 6), Vector2(randf_range(-6, 6), randf_range(-40, -20)), VIOLET)
	if register_fly > 0.0 and register_fly < 1.0:
		var hand := to_local(player.global_position + Vector2(10 * player.facing, -18))
		_spawn(_arc(hand, _book_center(), register_fly), Vector2(randf_range(-15, 15), randf_range(-15, 15)), [VIOLET, LIGHT].pick_random())
	if pillar > 0.05:
		for i in 2:
			_spawn(blade + Vector2(randf_range(-10, 10), 24.0), Vector2(randf_range(-4, 4), randf_range(-70, -30)), [VIOLET, LIGHT].pick_random())
	for i in _bars.size():
		var height := BAR_HEIGHT * smoothstep(0.0, 1.0, bars)
		_bars[i].offset_top = 0.0 if i == 0 else -height
		_bars[i].offset_bottom = height if i == 0 else 0.0
	_book_light.position = _book_center()
	_book_light.energy = (0.9 * maxf(book_lift, book_open)) * (1.0 - book_take)
	_pillar_light.position = blade
	_pillar_light.energy = 1.3 * pillar
	_fx.transform = get_global_transform_with_canvas()
	var zoom := _fx.transform.get_scale().x
	# El foco: entre Kai y el libro (y la luz de la espada cuando se enciende).
	var kai := to_local(player.global_position + Vector2(0, -16))
	var focus := (kai + _book_center()) * 0.5
	var reach := kai.distance_to(_book_center()) * 0.5 + 50.0
	if pillar > 0.0:
		focus = focus.lerp((kai + blade) * 0.5, pillar)
		reach = lerpf(reach, kai.distance_to(blade) * 0.5 + 60.0, pillar)
	var material := _shade_rect.material as ShaderMaterial
	material.set_shader_parameter(&"center", _fx.transform * focus)
	material.set_shader_parameter(&"radius", reach * zoom)
	material.set_shader_parameter(&"softness", 120.0 * zoom)
	material.set_shader_parameter(&"strength", shade)
	if _camera:
		_camera.zoom = _base_zoom * lerpf(1.0, 1.12, bars)
	_fx.queue_redraw()


# --- Pasos ---

## Lleva propiedades de este nodo a sus valores en seconds segundos (en paralelo).
func _to(values: Dictionary, seconds: float) -> void:
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for key: String in values:
		tween.tween_property(self, key, values[key], seconds)
	await tween.finished


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout


## Kai camina (solo, con los controles bloqueados) hasta x.
func _walk_to(x: float) -> void:
	var left := 3.0
	while absf(player.global_position.x - x) > 4.0 and left > 0.0:
		player.scripted_axis = signf(x - player.global_position.x)
		if not await FrameWait.physics(self):
			player.scripted_axis = 0.0
			return
		left -= get_physics_process_delta_time()
	player.scripted_axis = 0.0
	player.velocity.x = 0.0


func _shake(strength: float, duration: float) -> void:
	if _camera and _camera.has_method("shake"):
		_camera.shake(strength, duration)


func _book_center() -> Vector2:
	var base := Vector2(0, REST_Y - LIFT * book_lift + sin(_time * 2.4) * 2.0 * book_lift)
	return base.lerp(to_local(player.global_position + Vector2(0, -18)), ease(book_take, 1.8))


# --- Partículas ---

func _spawn(at: Vector2, velocity: Vector2, color: Color) -> void:
	_particles.append({ "pos": at, "vel": velocity, "life": randf_range(0.5, 1.0), "color": color, "size": Vector2.ONE * [1.0, 2.0, 2.0, 3.0].pick_random() })


func _burst(at: Vector2, count: int, color: Color) -> void:
	for i in count:
		_spawn(at, Vector2.from_angle(randf() * TAU) * randf_range(30, 90), color)


func _update_particles(delta: float) -> void:
	for p in _particles:
		p.pos += p.vel * delta
		p.life -= delta
	_particles = _particles.filter(func(p: Dictionary) -> bool: return p.life > 0.0)


# --- Dibujo (en coordenadas de este nodo: el pie del libro) ---

func _draw_fx() -> void:
	if pillar > 0.0:
		_draw_pillar()
	var center := _book_center()
	if (book_lift > 0.0 or book_open > 0.0) and book_take < 1.0:
		_draw_book(center)
	if panels_out > 0.0:
		_draw_panels(center)
	if register > 0.0:
		_draw_register(center)
	for p in _particles:
		var c: Color = p.color
		c.a *= clampf(p.life / 0.3, 0.0, 1.0)
		_fx.draw_rect(Rect2(p.pos.round(), p.size), c)


## El libro: cerrado es el diseño de Ariel (grimorio_libro.png), flotando e inclinándose apenas; al abrirse
## (book_open) pasa a su animación (grimorio_abriendo.png: cerrado, se abre, abierto y con la luz que sale de
## las páginas). Abierto, alterna los cuadros con luz; con flip, las hojas pasan solas (cuadros 2 y 3).
func _draw_book(c: Vector2) -> void:
	var glow := 0.5 + 0.5 * sin(_time * 4.0)
	var power := maxf(book_lift, book_open)
	for k in 6:
		_fx.draw_circle(c, (30.0 + 4.0 * glow) * (1.0 - k * 0.14), Color(VIOLET, 0.035 * power))
	if book_open <= 0.0:
		var tilt := sin(_time * 1.7) * 0.08 * book_lift
		# Al flotar se acerca un poco (se ve más grande), como en la escena de Ariel.
		_fx.draw_set_transform(c, tilt, Vector2.ONE * BOOK_SCALE * lerpf(1.0, FLOAT_GROW, book_lift) * (1.0 - 0.75 * book_take))
		_fx.draw_texture(BOOK, -BOOK.get_size() / 2.0)
		_fx.draw_set_transform(Vector2.ZERO)
		return
	var frame := mini(int(book_open * 4.0), 3)
	if flip > 0.0:
		frame = 2 + int(_time * 10.0) % 2
	elif book_open >= 1.0:
		frame = 3 + int(_time * 7.0) % 3
	var size := Vector2(OPENING_CELL)
	_fx.draw_set_transform(c, 0.0, Vector2.ONE * BOOK_SCALE)
	_fx.draw_texture_rect_region(OPENING, Rect2(Vector2(-size.x / 2.0, -size.y * 0.62), size), Rect2(Vector2(frame * size.x, 0), size))
	_fx.draw_set_transform(Vector2.ZERO)


## Los hologramas que salen del libro (como en la escena de Ariel): un recuadro con su ícono y el nombre abajo.
func _draw_panels(c: Vector2) -> void:
	var font := ThemeDB.fallback_font
	for i in PANELS.size():
		var t := clampf(panels_out * 1.6 - i * 0.15, 0.0, 1.0)
		if t <= 0.0:
			continue
		var target: Vector2 = PANELS[i][1]
		var at := c + target * ease(t, 0.5)
		var box := Rect2(at - PANEL_SIZE * 0.5 * t, PANEL_SIZE * t)
		var flicker := 0.8 + 0.2 * sin(_time * 9.0 + i * 1.7)
		# La línea que lo une al libro, con un quiebre (como un circuito).
		var corner := Vector2(at.x, c.y + target.y * 0.35)
		_fx.draw_polyline(PackedVector2Array([c, corner, at]), Color(VIOLET.lightened(0.3), 0.45 * t), 1.0)
		_fx.draw_rect(box.grow(1.0), Color(VIOLET, 0.18 * t))
		_fx.draw_rect(box, Color(0.06, 0.04, 0.2, 0.85 * t))
		_fx.draw_rect(box, Color(LIGHT, 0.85 * t * flicker), false, 1.0)
		if t < 1.0:
			continue
		_draw_icon(String(PANELS[i][0]), at, Color(LIGHT, flicker))
		_fx.draw_string(font, Vector2(at.x - 30, box.end.y + 8), String(PANELS[i][0]), HORIZONTAL_ALIGNMENT_CENTER, 60, 6,
			Color(LIGHT.lightened(0.2), flicker))


## Íconos de los hologramas (los de la escena de Ariel).
func _draw_icon(panel: String, c: Vector2, color: Color) -> void:
	match panel:
		"INVENTARIO":  # Una mochila.
			_fx.draw_rect(Rect2(c + Vector2(-5, -3), Vector2(10, 9)), color)
			_fx.draw_arc(c + Vector2(0, -3), 3.0, PI, TAU, 8, color, 1.5)
			_fx.draw_rect(Rect2(c + Vector2(-3, 0), Vector2(6, 3)), Color(0.06, 0.04, 0.2))
		"MAPA":  # Cuatro flechas que salen del centro.
			for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				var tip: Vector2 = c + dir * 7.0
				_fx.draw_line(c + dir * 2.0, tip, color, 1.0)
				var side := Vector2(dir.y, -dir.x)
				_fx.draw_line(tip, tip - dir * 2.5 + side * 2.0, color, 1.0)
				_fx.draw_line(tip, tip - dir * 2.5 - side * 2.0, color, 1.0)
			_fx.draw_rect(Rect2(c - Vector2(1.5, 1.5), Vector2(3, 3)), color)
		"CONCEPTOS":  # Una hoja con renglones.
			_fx.draw_rect(Rect2(c + Vector2(-5, -7), Vector2(10, 14)), color, false, 1.0)
			for k in 4:
				_fx.draw_line(c + Vector2(-3, -4 + k * 3), c + Vector2(3, -4 + k * 3), color, 1.0)
		"AMENAZAS":  # Un triángulo de alerta.
			_fx.draw_polyline(PackedVector2Array([c + Vector2(0, -7), c + Vector2(7, 6), c + Vector2(-7, 6), c + Vector2(0, -7)]), color, 1.5)
			_fx.draw_line(c + Vector2(0, -2), c + Vector2(0, 2), color, 1.5)
			_fx.draw_rect(Rect2(c + Vector2(-0.75, 3.5), Vector2(1.5, 1.5)), color)
		"REGISTROS":  # Una hoja con la punta doblada y renglones.
			_fx.draw_polyline(PackedVector2Array([c + Vector2(-5, -7), c + Vector2(2, -7), c + Vector2(5, -4), c + Vector2(5, 7), c + Vector2(-5, 7),
				c + Vector2(-5, -7)]), color, 1.0)
			_fx.draw_line(c + Vector2(2, -7), c + Vector2(2, -4), color, 1.0)
			_fx.draw_line(c + Vector2(2, -4), c + Vector2(5, -4), color, 1.0)
			for k in 3:
				_fx.draw_line(c + Vector2(-3, -1 + k * 3), c + Vector2(3, -1 + k * 3), color, 1.0)


## La luz violeta al otro lado del cuarto (donde se va a formar la Nullblade).
func _draw_pillar() -> void:
	var base := blade + Vector2(0, 24)
	var flicker := 0.8 + 0.2 * sin(_time * 11.0)
	var height := 150.0 * pillar
	_fx.draw_rect(Rect2(base + Vector2(-9, -height), Vector2(18, height)), Color(VIOLET, 0.16 * pillar * flicker))
	_fx.draw_rect(Rect2(base + Vector2(-3, -height), Vector2(6, height)), Color(LIGHT, 0.45 * pillar * flicker))
	_fx.draw_line(base + Vector2(0, -height), base, Color(Color.WHITE, 0.6 * pillar), 1.0)
	_fx.draw_circle(base, 18.0 * pillar, Color(VIOLET, 0.18 * pillar))
	_fx.draw_rect(Rect2(base + Vector2(-20, -1), Vector2(40, 2)), Color(LIGHT, 0.7 * pillar))


## El registro: la mano de Kai brilla y una chispa de energía violeta (con su estela de fragmentos) viaja en
## arco hasta el libro.
func _draw_register(c: Vector2) -> void:
	var hand := to_local(player.global_position + Vector2(10 * player.facing, -18))
	var pulse := 0.6 + 0.4 * sin(_time * 12.0)
	if register_fly <= 0.0:
		_fx.draw_circle(hand, 6.0 * register, Color(VIOLET, 0.25 * register))
		_fx.draw_circle(hand, 2.5 * register * pulse, Color(LIGHT, 0.9 * register))
		return
	if register_fly >= 1.0:
		return
	for k in 8:
		var t := clampf(register_fly - k * 0.035, 0.0, 1.0)
		var at := _arc(hand, c, t)
		_fx.draw_circle(at, 3.0 - k * 0.3, Color(VIOLET.lightened(0.2), (0.8 - k * 0.09) * register))
	var head := _arc(hand, c, register_fly)
	_fx.draw_circle(head, 6.0, Color(VIOLET, 0.3))
	_fx.draw_circle(head, 2.5, Color.WHITE)


## Un punto del arco de a hasta b (sube en el medio).
func _arc(a: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(b, t) + Vector2(0, -28.0 * sin(t * PI))


func _make_light(scale_factor: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = load("res://assets/art/light_soft.tres")
	light.texture_scale = scale_factor
	light.color = VIOLET.lightened(0.15)
	light.energy = 0.0
	add_child(light)
	return light

extends "res://prototypes/estilos/pixel/muestra_pixel.gd"
## Muestra C: estilo mixto.
## Regla: lo sólido es pixel art (personajes, tiles, objetos) y la energía es suave
## (luz, halos neón, partículas, pulsos de datos, corrupción y efectos de pantalla).
## Reutiliza todo el arte de la muestra A y le suma la atmósfera de la muestra B.

const GLITCH_SHADER := preload("res://assets/shaders/glitch_cercania.gdshader")
const VIGNETTE_SHADER := preload("res://prototypes/estilos/mixta/vineta.gdshader")
## Distancia (px) a la que la amenaza empieza a distorsionar la pantalla.
const GLITCH_RANGE := 150.0

const CYAN := Color("3ef2ff")
const MAG := Color("ff3ea5")
const LED_G := Color("59ff9c")
const WARM := Color(1.0, 0.88, 0.65)
const SILHOUETTE := Color(0.015, 0.02, 0.05)

var _glitch: ShaderMaterial


func _init() -> void:
	super()
	sample_title = "MUESTRA C · Mixta: pixel art + luz y energía suaves"
	other_sample = "res://prototypes/estilos/dos_mundos/muestra_dos_mundos.tscn"


func _build_art() -> void:
	super()
	_add_halos()
	_add_data_dust()
	_add_foreground()
	_add_screen_effects()


func _process(delta: float) -> void:
	super(delta)
	if _glitch and player and _lure:
		var distance := player.global_position.distance_to(_lure.global_position)
		var strength := clampf(1.0 - distance / GLITCH_RANGE, 0.0, 1.0)
		_glitch.set_shader_parameter("strength", strength * strength)


# --- Halos neón (suaves, se suman a la luz) ---

func _add_halos() -> void:
	var halos := VectorCanvas.new()
	halos.painter = _paint_halos
	halos.animated = true
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halos.material = additive
	add_child(halos)


func _paint_halos(c: VectorCanvas, t: float) -> void:
	# Lámparas: luz cálida del colegio.
	for x in range(40, int(LAB_X), 128):
		c.glow(Vector2(x + 10, CEILING_Y + 5), 16.0, Color(WARM, 0.35))
	# Router: ondas de señal que se expanden.
	for i in 3:
		var pulse := fmod(t * 0.8 + i / 3.0, 1.0)
		c.draw_arc(Vector2(353, 152), 4.0 + pulse * 26.0, 0.0, TAU, 32, Color(CYAN, 0.18 * (1.0 - pulse)), 1.5, true)
	c.glow(Vector2(353, 145), 12.0, Color(CYAN, 0.4))
	# Carteles holográficos.
	c.glow(Vector2(247, 244), 22.0, Color(CYAN, 0.22))
	c.glow(Vector2(786, 118), 40.0, Color(CYAN, 0.25))
	# Luces de los servidores.
	for i in 2:
		for u in 7:
			var flicker := 0.5 + 0.5 * sin(t * (3.0 + u) + i * 2.0 + u)
			c.glow(Vector2(719 + i * 30, FLOOR_Y - 58 + u * 8), 5.0, Color(LED_G, 0.25 * flicker), 4)
	# Pulsos de datos por los circuitos del laboratorio (siguen las pistas de los tiles).
	for cell in _tech_cells():
		var path := PackedVector2Array([
			cell + Vector2(0, 5.5), cell + Vector2(9.5, 5.5), cell + Vector2(9.5, 12.5), cell + Vector2(16, 12.5),
		])
		var u := fmod(t * 0.6 + (cell.x * 0.013 + cell.y * 0.021), 1.0)
		var point := _along(path, u * 30.0)
		c.glow(point, 3.5, Color(CYAN, 0.4), 4)
		c.draw_rect(Rect2(point.floor(), Vector2(1, 1)), CYAN)  # Núcleo en píxel exacto.
	# Paquetes de datos con estela.
	for packet in _packets:
		var color := MAG if packet.texture == _packet_bad else CYAN
		c.glow(packet.position, 6.0, Color(color, 0.5), 4)
		c.draw_line(packet.position - Vector2(14, 0), packet.position, Color(color, 0.25), 1.0)
	# La amenaza: halo magenta que late y mancha el suelo.
	if _lure:
		var beat := 0.5 + 0.5 * sin(t * 5.0)
		c.glow(_lure.position, 22.0 + beat * 6.0, Color(MAG, 0.35))
	for i in 4:
		var offset := Vector2(sin(t * 1.3 + i * 1.7) * 20.0, 0)
		c.draw_set_transform(Vector2(CORRUPTION.get_center().x, FLOOR_Y) + offset, 0.0, Vector2(1.8, 0.3))
		c.glow(Vector2.ZERO, 12.0 + sin(t * 2.0 + i) * 3.0, Color(MAG, 0.3), 5)
	c.draw_set_transform(Vector2.ZERO)


func _tech_cells() -> Array[Vector2]:
	var cells: Array[Vector2] = []
	for x in range(int(LAB_X / TILE), int(ROOM_SIZE.x / TILE)):
		for y in range(3, 19):
			# Solo la mitad de los circuitos lleva pulsos, para no saturar.
			if (x * 7 + y * 3) % 5 == 0 and (x + y) % 2 == 0:
				cells.append(Vector2(x * TILE, y * TILE))
	return cells


func _along(path: PackedVector2Array, distance: float) -> Vector2:
	for k in path.size() - 1:
		var length := path[k].distance_to(path[k + 1])
		if distance <= length:
			return path[k].lerp(path[k + 1], distance / length)
		distance -= length
	return path[path.size() - 1]


# --- Partículas de datos (cuadraditos de 1 px que flotan) ---

func _add_data_dust() -> void:
	var dust := CPUParticles2D.new()
	dust.amount = 60
	dust.lifetime = 9.0
	dust.preprocess = 9.0
	dust.position = Vector2(ROOM_SIZE.x * 0.5, 190)
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(ROOM_SIZE.x * 0.5, 120)
	dust.direction = Vector2(0, -1)
	dust.spread = 30.0
	dust.gravity = Vector2(0, -2)
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 5.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(CYAN, 0.0))
	ramp.add_point(0.3, Color(CYAN, 0.7))
	ramp.set_color(ramp.get_point_count() - 1, Color(CYAN, 0.0))
	dust.color_ramp = ramp
	add_child(dust)


# --- Primer plano en silueta con parallax (profundidad estilo Hollow Knight) ---

func _add_foreground() -> void:
	var front := Parallax2D.new()
	front.scroll_scale = Vector2(1.35, 1.0)
	front.z_index = 10
	add_child(front)
	var silhouettes := VectorCanvas.new()
	silhouettes.painter = _paint_foreground
	front.add_child(silhouettes)


func _paint_foreground(c: VectorCanvas, _t: float) -> void:
	# Cables que cuelgan cerca de la cámara.
	for x in [180.0, 620.0, 1040.0]:
		c.draw_polyline(VectorCanvas.sag_curve(Vector2(x, -4), Vector2(x + 150, -4), 26.0), SILHOUETTE, 5.0, true)
		c.draw_polyline(VectorCanvas.sag_curve(Vector2(x + 30, -4), Vector2(x + 110, -4), 40.0), SILHOUETTE, 3.0, true)
	# Columna y pupitre en silueta.
	c.draw_colored_polygon(VectorCanvas.rounded_rect(Rect2(420, -10, 26, 400), 4.0), SILHOUETTE)
	c.draw_colored_polygon(VectorCanvas.rounded_rect(Rect2(880, 318, 90, 14), 3.0), SILHOUETTE)
	c.draw_rect(Rect2(890, 330, 8, 40), SILHOUETTE)
	c.draw_rect(Rect2(952, 330, 8, 40), SILHOUETTE)
	c.draw_colored_polygon(VectorCanvas.rounded_rect(Rect2(905, 296, 34, 22), 2.0), SILHOUETTE)


# --- Efectos de pantalla ---

func _add_screen_effects() -> void:
	var glitch_layer := CanvasLayer.new()
	glitch_layer.layer = 2
	add_child(glitch_layer)
	var glitch_rect := ColorRect.new()
	glitch_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	glitch_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glitch = ShaderMaterial.new()
	_glitch.shader = GLITCH_SHADER
	glitch_rect.material = _glitch
	glitch_layer.add_child(glitch_rect)

	var vignette_layer := CanvasLayer.new()
	vignette_layer.layer = 3
	add_child(vignette_layer)
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vignette_material := ShaderMaterial.new()
	vignette_material.shader = VIGNETTE_SHADER
	vignette.material = vignette_material
	vignette_layer.add_child(vignette)

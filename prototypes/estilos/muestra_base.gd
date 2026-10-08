class_name StyleSample
extends Node2D
## Base de las muestras de estilo gráfico. Las dos muestras comparten el mismo recorrido,
## las mismas colisiones y el mismo jugador y cámara del proyecto (characters/ y world/);
## solo cambia el arte. Las subclases implementan _build_art() y _build_player_visual().
## Tab cambia a la otra muestra; Esc vuelve al menú.

const PLAYER_SCENE := preload("res://characters/player/player.tscn")
const CAMERA_SCENE := preload("res://world/camera/game_camera.tscn")

const ROOM_SIZE := Vector2(960, 360)
const FLOOR_Y := 304.0
const CEILING_Y := 48.0
## Inicio de la zona del laboratorio (pared tecnológica).
const LAB_X := 688.0
## Zona infectada por el phishing.
const CORRUPTION := Rect2(832, 296, 64, 16)
const LURE_POSITION := Vector2(864, 236)

## Bandejas de cables: plataformas de un sentido.
const ONE_WAY_PLATFORMS: Array[Rect2] = [
	Rect2(456, 256, 64, 8),
	Rect2(536, 216, 80, 8),
	Rect2(632, 252, 40, 8),
]

## Título y ruta de la otra muestra (las define cada subclase).
var sample_title := ""
var other_sample := ""
## Indicación extra de controles para esta muestra (opcional).
var sample_hint := ""

var player: Player
var camera: GameCamera


func _ready() -> void:
	_build_collisions()
	_build_art()
	_spawn_player()
	_build_hud()


## Dibuja el escenario. Implementar en cada muestra.
func _build_art() -> void:
	pass


## Devuelve el nodo que reemplaza el dibujo provisional del jugador.
func _build_player_visual() -> Node2D:
	return null


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_TAB and not other_sample.is_empty():
		get_viewport().set_input_as_handled()
		SceneManager.change_scene(other_sample)
	elif key.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		SceneManager.change_scene(SceneManager.MAIN_MENU)


func _build_collisions() -> void:
	var body := StaticBody2D.new()
	body.name = "Collisions"
	body.collision_layer = 1
	add_child(body)
	var solids: Array[Rect2] = [
		Rect2(-32, FLOOR_Y, ROOM_SIZE.x + 64, 80),  # Suelo
		Rect2(-32, 0, 32, ROOM_SIZE.y),             # Pared izquierda
		Rect2(ROOM_SIZE.x, 0, 32, ROOM_SIZE.y),     # Pared derecha
	]
	for rect in solids:
		body.add_child(_collision_shape(rect, false))
	for rect in ONE_WAY_PLATFORMS:
		body.add_child(_collision_shape(rect, true))


func _collision_shape(rect: Rect2, one_way: bool) -> CollisionShape2D:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var node := CollisionShape2D.new()
	node.shape = shape
	node.position = rect.get_center()
	node.one_way_collision = one_way
	return node


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = Vector2(56, FLOOR_Y)
	# Las muestras activan todas las habilidades de T2 para probar sus animaciones.
	player.can_double_jump = true
	player.can_wall_jump = true
	player.dash_level = 2
	add_child(player)
	# Oculta el dibujo provisional de rectángulos y pone el de la muestra en su lugar.
	# Al vivir dentro de Visual/Body, hereda el giro y la deformación de player.gd.
	var body := player.get_node("Visual/Body")
	for child in body.get_children():
		(child as CanvasItem).visible = false
	var visual := _build_player_visual()
	if visual:
		body.add_child(visual)

	camera = CAMERA_SCENE.instantiate()
	camera.target = player
	add_child(camera)
	camera.set_limits(Rect2(Vector2.ZERO, ROOM_SIZE))


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var settings := LabelSettings.new()
	settings.font_size = 18
	settings.outline_size = 6
	settings.outline_color = Color(0.02, 0.03, 0.08, 0.9)
	var title := Label.new()
	title.text = sample_title
	title.label_settings = settings
	title.position = Vector2(16, 12)
	layer.add_child(title)
	var help_settings := settings.duplicate() as LabelSettings
	help_settings.font_size = 14
	help_settings.font_color = Color(0.75, 0.82, 0.95)
	var help := Label.new()
	help.text = "A/D: mover · Espacio: saltar (doble salto, salto en pared) · Shift: dash · Tab: siguiente muestra · Esc: menú"
	if not sample_hint.is_empty():
		help.text += "\n" + sample_hint
	help.label_settings = help_settings
	help.position = Vector2(16, 40)
	layer.add_child(help)


# --- Utilidades compartidas ---

## Luz 2D suave (funciona con el renderizador Compatibility).
func add_light(pos: Vector2, color: Color, radius: float, energy := 1.0, parent: Node = self) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = _light_texture()
	light.texture_scale = radius / 64.0
	light.color = color
	light.energy = energy
	light.position = pos
	parent.add_child(light)
	return light


static var _cached_light_texture: GradientTexture2D

static func _light_texture() -> GradientTexture2D:
	if _cached_light_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color.WHITE)
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.35, Color(1, 1, 1, 0.45))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.width = 128
		texture.height = 128
		_cached_light_texture = texture
	return _cached_light_texture


## Oscurece la escena para que las luces neón destaquen.
func add_ambient(color: Color) -> void:
	var modulate_node := CanvasModulate.new()
	modulate_node.color = color
	add_child(modulate_node)

class_name DigitalWorld
extends Node
## Efectos de la Visión Digital en una sala (uno por sala). Lee el estado de DigitalVision y:
## - oscurece el ambiente físico (CanvasModulate) y muestra la capa digital (digital_layer),
## - muestra los nodos del grupo "digital_only" y oculta los de "physical_only",
## - activa la capa de colisión 7 (mundo_digital) en el jugador: puentes y plataformas de datos,
## - ilumina al jugador y hace un glitch de pantalla al encender o apagar.

const GLITCH_SHADER := preload("res://assets/shaders/glitch_cercania.gdshader")
const LIGHT_TEXTURE := preload("res://assets/art/light_soft.tres")
const DIGITAL_COLLISION_LAYER := 7

@export var player: Player
@export var ambient: CanvasModulate
@export var physical_ambient := Color(0.62, 0.66, 0.85)
@export var digital_ambient := Color(0.13, 0.16, 0.3)
## Lo que solo se ve con la Visión Digital (p. ej. el dibujo vectorial de la red).
## Conviene que esté dentro de una CanvasLayer para que la oscuridad del ambiente no lo afecte.
@export var digital_layer: CanvasItem

var _glitch: ShaderMaterial
var _player_light: PointLight2D


func _ready() -> void:
	_build_glitch_overlay()
	if player:
		_player_light = PointLight2D.new()
		_player_light.name = "VisionLight"
		_player_light.texture = LIGHT_TEXTURE
		_player_light.texture_scale = 70.0 / 64.0
		_player_light.color = Color(0.5, 0.95, 1.0)
		_player_light.position = Vector2(0, -16)
		_player_light.energy = 0.0
		player.add_child(_player_light)
	var vision := _vision()
	vision.activated.connect(pulse_glitch)
	vision.deactivated.connect(pulse_glitch)
	_apply()


func _process(_delta: float) -> void:
	_apply()


## Golpe de glitch en pantalla (al cambiar de mundo o en eventos de la historia).
func pulse_glitch(peak := 0.9) -> void:
	# Más suave si en las opciones se reducen los efectos glitch.
	peak *= GameSettings.glitch_factor()
	var tween := create_tween()
	tween.tween_method(_set_glitch, 0.0, peak, 0.12)
	tween.tween_method(_set_glitch, peak, 0.0, 0.3)


func _apply() -> void:
	var vision := _vision()
	var blend: float = vision.blend
	var alpha: float = blend * vision.warning_factor()
	if ambient:
		ambient.color = physical_ambient.lerp(digital_ambient, blend)
	if digital_layer:
		digital_layer.visible = blend > 0.001
		digital_layer.modulate.a = alpha
	for node in get_tree().get_nodes_in_group(&"digital_only"):
		(node as CanvasItem).visible = blend > 0.001
		(node as CanvasItem).modulate.a = alpha
	for node in get_tree().get_nodes_in_group(&"physical_only"):
		(node as CanvasItem).modulate.a = 1.0 - blend
	if _player_light:
		_player_light.energy = blend * 1.3
	if player:
		player.set_collision_mask_value(DIGITAL_COLLISION_LAYER, vision.is_active())


func _build_glitch_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "GlitchOverlay"
	layer.layer = 2
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glitch = ShaderMaterial.new()
	_glitch.shader = GLITCH_SHADER
	rect.material = _glitch
	layer.add_child(rect)


func _set_glitch(strength: float) -> void:
	_glitch.set_shader_parameter(&"strength", strength)


func _vision() -> Node:
	return get_node("/root/DigitalVision")

extends Node2D
## Prueba de escala de Kai en la sala real (Zona 0). El jugador usa la apariencia CONCEPTO
## (sprites de la hoja de Ariel, 96 px a mitad de escala) y a su lado queda el Kai por huesos
## como referencia. No cambia el juego: solo deja probar el zoom de la cámara.
## Teclas: 1/2/3 = zoom ×2 (el del juego) / ×2,5 / ×3 · Esc = menú.

const ROOM := "res://world/zones/zone0/pasillo_laboratorio.tscn"
const ZOOMS := { KEY_1: 2.0, KEY_2: 2.5, KEY_3: 3.0 }

var _player: Player
var _camera: Camera2D
var _label: Label


func _ready() -> void:
	var room := (load(ROOM) as PackedScene).instantiate()
	add_child(room)
	_player = room.find_children("*", "Player", true, false)[0]
	_camera = room.find_children("*", "Camera2D", true, false)[0]

	# Kai por huesos como estatua de referencia, junto al punto de inicio.
	var reference := KaiVisual.new()
	reference.apariencia = KaiVisual.Apariencia.HUESOS
	reference.position = _player.global_position + Vector2(-28, 0)
	room.add_child(reference)
	_add_world_label(room, "Kai por huesos", reference.position + Vector2(-26, -62))

	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(16, 660)
	var settings := LabelSettings.new()
	settings.font_size = 16
	settings.outline_size = 6
	settings.outline_color = Color(0.02, 0.03, 0.08)
	_label.label_settings = settings
	layer.add_child(_label)
	_update_label()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not ZOOMS.has(key.keycode):
		return
	_camera.zoom = Vector2.ONE * ZOOMS[key.keycode]
	get_viewport().set_input_as_handled()
	_update_label()


func _update_label() -> void:
	_label.text = "PRUEBA DE ESCALA · Zoom ×%s (se ven %d×%d px del mundo)\n1/2/3: zoom ×2 / ×2,5 / ×3 · Esc: menú" % [
		str(_camera.zoom.x).replace(".", ","), roundi(1280 / _camera.zoom.x), roundi(720 / _camera.zoom.y),
	]


func _add_world_label(parent: Node, text: String, pos: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.scale = Vector2(0.5, 0.5)
	label.add_theme_font_size_override(&"font_size", 14)
	label.add_theme_color_override(&"font_color", Color(0.75, 0.82, 0.95))
	parent.add_child(label)

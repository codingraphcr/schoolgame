@tool
class_name Stairway
extends Interactable
## Escalera entre pisos: como una salida (RoomExit), pero se usa con E («E: subir» / «E: bajar»).
## También sirve de puerta de un aula (show_art = false: el arte es otro nodo; action_text «entrar»).
## Si tiene door_id y la sala está en el mapa, World dice a dónde lleva; si no, target_scene y
## target_entry. Si la sala de destino es de un capítulo que todavía no empezó, avisa y no se usa.
## Arte provisional por código (el hueco de la escalera con sus escalones y un cartel); se ve
## también en el editor. El origen es el centro de la base, apoyada en el suelo.

const WIDTH := 44.0
const HEIGHT := 64.0
const FRAME := Color("4a5470")
const HOLE := Color("0d1220")
const STEP := Color("5c6684")
const SIGN := Color("1f6f5a")

## Puerta de la ficha de la sala (DoorSpec.id) que representa esta escalera.
@export var door_id: StringName = &""
@export_file("*.tscn") var target_scene := ""
@export var target_entry: StringName = &""
## true: sube (escalones hacia arriba, «E: subir»); false: baja.
@export var going_up := true:
	set(value):
		going_up = value
		_refresh_prompt_text()
		queue_redraw()
## Cartel sobre la escalera (vacío = sin cartel).
@export var sign_text := "ESCALERAS":
	set(value):
		sign_text = value
		queue_redraw()

## Lo que dice el aviso en vez de «subir»/«bajar» (p. ej. «entrar»). Vacío = escalera.
@export var action_text := "":
	set(value):
		action_text = value
		_refresh_prompt_text()
## false: no dibuja la escalera ni el cartel (la puerta ya está dibujada por otro nodo).
@export var show_art := true:
	set(value):
		show_art = value
		queue_redraw()

var _used := false


func _init() -> void:
	prompt_text = "E: subir"
	prompt_offset = Vector2(-20, -HEIGHT - 26)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH, HEIGHT)
	shape.shape = rect
	shape.position = Vector2(0, -HEIGHT / 2.0)
	add_child(shape)
	super()
	interacted.connect(_on_interacted)


## A dónde lleva: { "scene", "entry", "room" } (como RoomExit.resolve()).
func resolve() -> Dictionary:
	return RoomExit.destination_of(self, door_id, target_scene, target_entry)


func _on_interacted(player: Player) -> void:
	if _used:
		return
	_used = RoomExit.travel(self, player, door_id, target_scene, target_entry)


func _refresh_prompt_text() -> void:
	if not action_text.is_empty():
		prompt_text = "E: " + action_text
	else:
		prompt_text = "E: subir" if going_up else "E: bajar"


func _draw() -> void:
	if not show_art:
		return
	var hole := Rect2(-WIDTH / 2.0, -HEIGHT, WIDTH, HEIGHT)
	draw_rect(hole.grow(3), FRAME)
	draw_rect(hole, HOLE)
	# Escalones en diagonal: suben hacia la derecha o bajan hacia el fondo.
	for i in 6:
		var t := i / 6.0
		var y := -6.0 - t * (HEIGHT - 14.0) if going_up else -HEIGHT + 10.0 + t * (HEIGHT - 16.0)
		var x := -WIDTH / 2.0 + 4.0 + t * (WIDTH - 16.0)
		draw_rect(Rect2(x, y, 12, 3), STEP if going_up else STEP.darkened(0.25 + t * 0.4))
	# Baranda.
	var rail_from := Vector2(-WIDTH / 2.0 + 4, -14) if going_up else Vector2(-WIDTH / 2.0 + 4, -HEIGHT + 4)
	var rail_to := Vector2(WIDTH / 2.0 - 4, -HEIGHT + 4) if going_up else Vector2(WIDTH / 2.0 - 4, -14)
	draw_line(rail_from + Vector2(0, -10), rail_to + Vector2(0, -10), FRAME.lightened(0.3), 1.5)
	if sign_text.is_empty():
		return
	var font := ThemeDB.fallback_font
	var sign_rect := Rect2(-WIDTH / 2.0 - 4, -HEIGHT - 18, WIDTH + 8, 12)
	draw_rect(sign_rect, SIGN)
	draw_string(font, Vector2(sign_rect.position.x, sign_rect.end.y - 3), sign_text + (" ▲" if going_up else " ▼"),
		HORIZONTAL_ALIGNMENT_CENTER, sign_rect.size.x, 8, Color.WHITE)

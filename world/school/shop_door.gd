@tool
class_name ShopDoor
extends Interactable
## La puerta de la tienda de la soda, en el patio, al lado de la puerta de la soda. Está cerrada hasta que Kai habla
## con la señora de la soda (Shop.OPEN_FLAG); mientras tanto, con E solo se lee el rótulo (locked_dialogue). Abierta,
## lleva a la tienda como cualquier puerta (RoomExit.travel, con door_id para el mapa).
## El origen es el piso, al centro de la puerta. Se ve también en el editor.

@export var door_id: StringName = &"tienda"
@export_file("*.tscn") var target_scene := ""
@export var target_entry: StringName = &""
@export var locked_dialogue: Dialogue

var _used := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 64)
	shape.shape = rect
	shape.position = Vector2(0, -32)
	add_child(shape)
	super()
	interacted.connect(_on_interacted)


func _process(delta: float) -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	prompt_text = "E: entrar a la tienda" if is_open() else "E: mirar la puerta"
	super(delta)


func is_open() -> bool:
	return Shop.is_open(get_node("/root/GameState"))


func _on_interacted(player: Player) -> void:
	if _used:
		return
	if not is_open():
		busy = true
		await StoryHelper.say(self, locked_dialogue)
		busy = false
		return
	_used = RoomExit.travel(self, player, door_id, target_scene, target_entry)


func _draw() -> void:
	var open := Engine.is_editor_hint() or is_open()
	draw_rect(Rect2(-24, -96, 48, 96), Color("3e2a1c"))
	draw_rect(Rect2(-20, -92, 40, 92), Color("6a4a8a") if open else Color("4a4050"))
	draw_rect(Rect2(-14, -84, 28, 30), Color(0.75, 0.9, 1.0, 0.45) if open else Color(0.3, 0.3, 0.35, 0.6))
	draw_circle(Vector2(12, -44), 2.5, Color("f2c14e"))
	# El rótulo: «TIENDA» (con «CERRADO» colgando mientras no se abre).
	draw_rect(Rect2(-32, -122, 64, 18), Color("6a4a8a"))
	draw_string(ThemeDB.fallback_font, Vector2(-32, -109), "TIENDA", HORIZONTAL_ALIGNMENT_CENTER, 64, 9, Color.WHITE)
	if not open:
		draw_line(Vector2(-8, -84), Vector2(0, -92), Color("2a1a10"), 1.0)
		draw_line(Vector2(8, -84), Vector2(0, -92), Color("2a1a10"), 1.0)
		draw_rect(Rect2(-16, -84, 32, 12), Color("f4f0e4"))
		draw_string(ThemeDB.fallback_font, Vector2(-16, -75), "CERRADO", HORIZONTAL_ALIGNMENT_CENTER, 32, 6, Color("c0504d"))

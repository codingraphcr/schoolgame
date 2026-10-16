@tool
class_name PowerBoard
extends Interactable
## El tablero de distribución eléctrica de la Estación Lázaro (etapa 1 de «Eco en la Red»): con E abre el puzzle
## (PowerGridWindow). Resolverlo deja SOLVED_FLAG, completa el paso y la estación recupera energía en parte
## (solved_dialogue: Aegis y Kai). Se puede salir y volver sin perder nada; resuelto, ya no hace falta.
## El origen es el piso, frente al tablero.

const SOLVED_FLAG := &"lazaro_energia_restablecida"
const BLUE := Color("3a8adf")
const CYAN := Color("3ef2ff")

@export var grid: PowerGrid
@export var solved_dialogue: Dialogue
@export var quest_id: StringName = &"eco_en_la_red"
@export var step_id: StringName = &"restablecer_energia"

var _clock := 0.0


func _init() -> void:
	prompt_offset = Vector2(-60, -120)
	prompt_text = "E: usar el tablero"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(64, 56)
	shape.shape = rect
	shape.position = Vector2(0, -28)
	add_child(shape)
	super()
	interacted.connect(_on_interacted)


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()
	if Engine.is_editor_hint():
		return
	enabled = get_node("/root/GameState").get_current_step(quest_id) == step_id
	super(delta)


func is_solved() -> bool:
	return not Engine.is_editor_hint() and get_node("/root/GameState").has_flag(SOLVED_FLAG)


func _on_interacted(player: Player) -> void:
	busy = true
	player.controls_locked = true
	var window := PowerGridWindow.open(self, grid)
	var solved: bool = await window.closed
	player.controls_locked = false
	if solved:
		var state := get_node("/root/GameState")
		state.set_flag(SOLVED_FLAG)
		await StoryHelper.say(self, solved_dialogue)
		state.complete_step(quest_id, step_id)
	await get_tree().process_frame
	busy = false


func _draw() -> void:
	draw_rect(Rect2(-36, -110, 72, 110), Color("dfe6f0"))
	draw_rect(Rect2(-36, -110, 72, 110), BLUE, false, 2.0)
	draw_rect(Rect2(-28, -100, 56, 60), Color("101624"))
	var on := is_solved()
	for y in 3:
		for x in 4:
			var lit := on or (int(_clock * 2.0) + x + y) % 5 == 0
			draw_rect(Rect2(-24 + x * 13, -94 + y * 18, 9, 12), CYAN if lit else Color("2a3450"))
	draw_string(ThemeDB.fallback_font, Vector2(-36, -116), "DISTRIBUCIÓN", HORIZONTAL_ALIGNMENT_CENTER, 72, 8, Color("1a2a4a"))
	draw_circle(Vector2(0, -20), 6.0, Color("7ee08a") if on else Color("ff6a6a"))

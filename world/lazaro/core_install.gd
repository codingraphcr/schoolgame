@tool
class_name CoreInstall
extends Interactable
## El panel del núcleo donde Kai instala los tres módulos de Aegis (etapa 3 de «Eco en la Red»). Con los módulos
## (paso step_id) y E: install_dialogue y empieza la estabilización (CoreDefense.start: las Bitcucarachas).
## El origen es el piso.

@export var core: CoreDefense
@export var install_dialogue: Dialogue
@export var quest_id: StringName = &"eco_en_la_red"
@export var step_id: StringName = &"estabilizar_nucleo"


func _init() -> void:
	prompt_offset = Vector2(-60, -100)
	prompt_text = "E: instalar los módulos"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 56)
	shape.shape = rect
	shape.position = Vector2(0, -28)
	add_child(shape)
	super()
	interacted.connect(_on_interacted)


func _process(delta: float) -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	enabled = core != null and not core.running and get_node("/root/GameState").get_current_step(quest_id) == step_id
	super(delta)


func _on_interacted(_player: Player) -> void:
	busy = true
	await StoryHelper.say(self, install_dialogue)
	busy = false
	core.start()


func _draw() -> void:
	draw_rect(Rect2(-22, -60, 44, 60), Color("dfe6f0"))
	draw_rect(Rect2(-22, -60, 44, 60), Color("3a7adf"), false, 2.0)
	for k in 3:
		var slot := Rect2(-16 + k * 12, -48, 8, 14)
		var colors: Array[Color] = [Color("ffd166"), Color("3ef2ff"), Color("7ee08a")]
		var done: bool = not Engine.is_editor_hint() and get_node("/root/GameState").has_flag(AegisModule.flag_of(AegisModule.ALL[k]))
		draw_rect(slot, colors[k] if done else Color("3a4258"))

class_name Examinable
extends Interactable
## Algo que Kai puede mirar o tocar para que diga algo (una foto, la tele, un perro): con E se
## reproduce un diálogo. Si tiene varios (dialogues), va dando uno distinto cada vez (y después repite
## el último). Sin evaluaciones: son detalles que le dan vida al lugar. Con quest_id y step_id, solo
## responde mientras la misión está en ese paso. Si no tiene forma de colisión, se crea una de size.

signal examined(times: int)

@export var dialogues: Array[Dialogue] = []
@export var size := Vector2(40, 48)
@export var quest_id: StringName = &""
@export var step_id: StringName = &""
## Marca que queda en la partida la primera vez (opcional).
@export var seen_flag: StringName = &""

var times := 0


func _ready() -> void:
	super()
	if find_children("*", "CollisionShape2D", false).is_empty():
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = size
		shape.shape = rect
		shape.position = Vector2(0, -size.y / 2.0)
		add_child(shape)
	interacted.connect(_on_interacted)


func _physics_process(_delta: float) -> void:
	if quest_id != &"":
		enabled = get_node("/root/GameState").get_current_step(quest_id) == step_id


func _on_interacted(_player: Player) -> void:
	if dialogues.is_empty():
		return
	var dialogue := dialogues[mini(times, dialogues.size() - 1)]
	times += 1
	busy = true
	await StoryHelper.say(self, dialogue)
	busy = false
	if seen_flag != &"":
		get_node("/root/GameState").set_flag(seen_flag)
	examined.emit(times)

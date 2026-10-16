class_name QuestTrigger
extends Area2D
## Completa un paso de misión cuando Kai entra en la zona (o al cargar la sala, con on_ready).
## Puede mostrar un diálogo antes de completarlo. Solo actúa si ese es el paso actual.
## Sin quest_id y con requires_flag: solo muestra el diálogo (una vez, con once_flag) cuando la partida tiene esa marca
## (p. ej. el vecino agradece cuando volvió la señal).
## Necesita una CollisionShape2D hija (salvo con on_ready).

@export var quest_id: StringName = &""
@export var step_id: StringName = &""
@export var dialogue: Dialogue
## Completa el paso al cargar la sala (p. ej. "entrar a la computadora").
@export var on_ready := false
## false: solo muestra el diálogo (no completa el paso), una sola vez (once_flag).
@export var completes_step := true
@export var once_flag: StringName = &""
## Además, solo si la partida tiene esta marca.
@export var requires_flag: StringName = &""

var _busy := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # Capa del jugador
	body_entered.connect(_on_body_entered)
	if on_ready:
		# Al cargar la sala también se muestra el diálogo: con el jugador de la sala.
		_fire.call_deferred(_room_player())


func _on_body_entered(body: Node) -> void:
	if body is Player:
		_fire(body)


func _fire(player: Player) -> void:
	var game_state := get_node("/root/GameState")
	if _busy:
		return
	if quest_id != &"" and game_state.get_current_step(quest_id) != step_id:
		return
	if requires_flag != &"" and not game_state.has_flag(requires_flag):
		return
	if quest_id == &"" and requires_flag == &"":
		return
	if once_flag != &"" and game_state.has_flag(once_flag):
		return
	_busy = true
	if once_flag != &"":
		game_state.set_flag(once_flag)
	var box := DialogueBox.find(self)
	if dialogue and box and player:
		player.controls_locked = true
		player.velocity.x = 0.0
		await box.play(dialogue)
		player.controls_locked = false
	if completes_step and quest_id != &"":
		game_state.complete_step(quest_id, step_id)
	_busy = false


func _room_player() -> Player:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return (node as Room).player if node else null

class_name QuestTrigger
extends Area2D
## Completa un paso de misión cuando Kai entra en la zona (o al cargar la sala, con on_ready).
## Puede mostrar un diálogo antes de completarlo. Solo actúa si ese es el paso actual.
## Necesita una CollisionShape2D hija (salvo con on_ready).

@export var quest_id: StringName = &""
@export var step_id: StringName = &""
@export var dialogue: Dialogue
## Completa el paso al cargar la sala (p. ej. "entrar a la computadora").
@export var on_ready := false

var _busy := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # Capa del jugador
	body_entered.connect(_on_body_entered)
	if on_ready:
		_fire.call_deferred(null)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		_fire(body)


func _fire(player: Player) -> void:
	var game_state := get_node("/root/GameState")
	if _busy or game_state.get_current_step(quest_id) != step_id:
		return
	_busy = true
	var box := DialogueBox.find(self)
	if dialogue and box and player:
		player.controls_locked = true
		player.velocity.x = 0.0
		await box.play(dialogue)
		player.controls_locked = false
	game_state.complete_step(quest_id, step_id)
	_busy = false

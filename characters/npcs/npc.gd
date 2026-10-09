class_name Npc
extends Node2D
## Personaje con el que se puede hablar. Primero busca en conversations la que corresponde al paso
## actual de una misión (y puede completarlo). Si ninguna corresponde, la primera vez dice dialogue
## y las siguientes repeat_dialogue. Mira hacia Kai mientras habla y usa la animación "talk".
## La marca talked_flag (opcional) queda en GameState al terminar la primera conversación.

signal talked(first_time: bool)

@export var display_name := ""
@export var dialogue: Dialogue
@export var repeat_dialogue: Dialogue
@export var talked_flag: StringName = &""
## Conversaciones según el paso de una misión (tienen prioridad sobre dialogue y repeat_dialogue).
@export var conversations: Array[NpcConversation] = []

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)
	if _sprite.sprite_frames and _sprite.sprite_frames.has_animation(&"idle"):
		_sprite.play(&"idle")


## Verdadero si ya se habló con este personaje alguna vez.
func has_talked() -> bool:
	return talked_flag != &"" and _game_state().has_flag(talked_flag)


func _on_interacted(player: Player) -> void:
	var first_time := not has_talked()
	var conversation := _current_conversation()
	var lines: Dialogue
	if conversation:
		lines = conversation.dialogue
	else:
		lines = dialogue if first_time or repeat_dialogue == null else repeat_dialogue
	var box := DialogueBox.find(self)
	if lines == null or box == null:
		return
	_interactable.busy = true
	player.controls_locked = true
	player.velocity.x = 0.0
	_sprite.flip_h = player.global_position.x < global_position.x
	player.face(1 if global_position.x > player.global_position.x else -1)
	_play(&"talk")
	await box.play(lines)
	_play(&"idle")
	if first_time and talked_flag != &"":
		_game_state().set_flag(talked_flag)
	if conversation and conversation.completes_step:
		_game_state().complete_step(conversation.quest_id, conversation.step_id)
	player.controls_locked = false
	# Un cuadro de espera: la tecla que cerró el diálogo no vuelve a abrirlo.
	await get_tree().process_frame
	_interactable.busy = false
	talked.emit(first_time)


## La conversación que corresponde al paso actual de alguna misión (o null).
func _current_conversation() -> NpcConversation:
	for conversation in conversations:
		if conversation and conversation.dialogue and _game_state().get_current_step(conversation.quest_id) == conversation.step_id:
			return conversation
	return null


func _play(animation: StringName) -> void:
	if _sprite.sprite_frames and _sprite.sprite_frames.has_animation(animation):
		_sprite.play(animation)


func _game_state() -> Node:
	return get_node("/root/GameState")

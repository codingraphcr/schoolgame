class_name Npc
extends Node2D
## Personaje con el que se puede hablar. La primera vez dice dialogue; las siguientes,
## repeat_dialogue (si existe). Mira hacia Kai mientras habla y usa la animación "talk".
## La marca talked_flag (opcional) queda en GameState al terminar la primera conversación.

signal talked(first_time: bool)

@export var display_name := ""
@export var dialogue: Dialogue
@export var repeat_dialogue: Dialogue
@export var talked_flag: StringName = &""
## Animación que hace de vez en cuando mientras espera (p. ej. "notas": revisa su tablet).
@export var idle_extra_animation: StringName = &""
## Segundos entre una y otra vez (al azar dentro del rango) y cuánto dura.
@export var idle_extra_every := Vector2(6.0, 11.0)
@export var idle_extra_duration := 3.0

var _talking := false
var _idle_timer := 0.0

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.interacted.connect(_on_interacted)
	if _sprite.sprite_frames and _sprite.sprite_frames.has_animation(&"idle"):
		_sprite.play(&"idle")
	_idle_timer = randf_range(idle_extra_every.x, idle_extra_every.y)


func _process(delta: float) -> void:
	if _talking or idle_extra_animation == &"":
		return
	_idle_timer -= delta
	if _idle_timer > 0.0:
		return
	if _sprite.animation == idle_extra_animation:
		_play(&"idle")
		_idle_timer = randf_range(idle_extra_every.x, idle_extra_every.y)
	else:
		_play(idle_extra_animation)
		_idle_timer = idle_extra_duration


## Verdadero si ya se habló con este personaje alguna vez.
func has_talked() -> bool:
	return talked_flag != &"" and _game_state().has_flag(talked_flag)


func _on_interacted(player: Player) -> void:
	var first_time := not has_talked()
	var lines := dialogue if first_time or repeat_dialogue == null else repeat_dialogue
	var box := DialogueBox.find(self)
	if lines == null or box == null:
		return
	_interactable.busy = true
	_talking = true
	player.controls_locked = true
	player.velocity.x = 0.0
	_sprite.flip_h = player.global_position.x < global_position.x
	player.face(1 if global_position.x > player.global_position.x else -1)
	_play(&"talk")
	await box.play(lines)
	_play(&"idle")
	_talking = false
	_idle_timer = randf_range(idle_extra_every.x, idle_extra_every.y)
	if first_time and talked_flag != &"":
		_game_state().set_flag(talked_flag)
	player.controls_locked = false
	# Un cuadro de espera: la tecla que cerró el diálogo no vuelve a abrirlo.
	await get_tree().process_frame
	_interactable.busy = false
	talked.emit(first_time)


func _play(animation: StringName) -> void:
	if _sprite.sprite_frames and _sprite.sprite_frames.has_animation(animation):
		_sprite.play(animation)


func _game_state() -> Node:
	return get_node("/root/GameState")

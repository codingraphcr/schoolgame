@tool
class_name PoweredStairway
extends Stairway
## Una escalera de la Estación Lázaro que necesita energía: hasta que la partida tiene requires_flag (la energía
## restablecida con el tablero), avisa y no se usa. Después es una escalera como cualquier otra.

@export var requires_flag: StringName = &"lazaro_energia_restablecida"
@export var locked_text := "Sin energía: el acceso a este sector está bloqueado."


func _on_interacted(player: Player) -> void:
	if requires_flag != &"" and not get_node("/root/GameState").has_flag(requires_flag):
		get_tree().call_group(&"toast", &"show_message", locked_text, 2.5)
		return
	super(player)

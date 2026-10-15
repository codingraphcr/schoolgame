class_name PhaseLight
extends CanvasModulate
## Luz de la sala según el momento del día de la historia (DayPhase): tarde dorada, noche azulada,
## mañana clara. Adentro de la casa la luz es más cálida (indoors). Cambia con un fundido suave.

@export var indoors := false



func _ready() -> void:
	color = _target()


func _process(delta: float) -> void:
	color = color.lerp(_target(), clampf(delta * 2.0, 0.0, 1.0))


func _target() -> Color:
	var state := get_node_or_null("/root/GameState")
	if state == null:
		return Color.WHITE
	return DayPhase.ambient(DayPhase.current(state), indoors)

class_name PhaseLight
extends CanvasModulate
## Luz de la sala según el momento del día de la historia (DayPhase): tarde dorada, noche azulada,
## mañana clara. Adentro de la casa la luz es más cálida (indoors). Cambia con un fundido suave.

@export var indoors := false
## Con la Visión Digital, el mundo físico se oscurece hacia este color (como DigitalWorld en el resto del juego).
@export var digital_ambient := Color(0.13, 0.16, 0.3)

var _phase_color := Color.WHITE


func _ready() -> void:
	_phase_color = _target()
	color = _phase_color


func _process(delta: float) -> void:
	_phase_color = _phase_color.lerp(_target(), clampf(delta * 2.0, 0.0, 1.0))
	var vision := get_node_or_null("/root/DigitalVision")
	color = _phase_color.lerp(digital_ambient, vision.blend if vision else 0.0)


func _target() -> Color:
	var state := get_node_or_null("/root/GameState")
	if state == null:
		return Color.WHITE
	return DayPhase.ambient(DayPhase.current(state), indoors)

@tool
class_name RoomEntry
extends Marker2D
## Punto por donde el jugador entra a una sala desde otra. El id debe coincidir con el
## target_entry de la RoomExit que lleva hasta aquí. La posición marca dónde quedan los pies.

@export var id: StringName = &""
## Hacia dónde mira Kai al entrar (1 = derecha, -1 = izquierda).
@export_enum("Izquierda:-1", "Derecha:1") var facing := 1


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_line(Vector2(0, -24), Vector2.ZERO, Color(0.4, 1.0, 0.6), 1.0)
		draw_line(Vector2(0, -20), Vector2(6 * facing, -20), Color(0.4, 1.0, 0.6), 1.0)

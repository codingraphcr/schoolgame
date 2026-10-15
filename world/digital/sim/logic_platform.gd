@tool
class_name LogicPlatform
extends DataPlatform
## Plataforma condicional del simulador (Capítulo 2): existe (se ve y se pisa) solo si su condición se
## cumple (when_true = true: la rama «si») o si no se cumple (when_true = false: la rama «si no»). Muestra
## la rama arriba. Nunca es suelo seguro para reaparecer (puede desaparecer).

@export var variables: SimVariables
@export var clauses: Array = []
@export var all := true
## true: aparece «si» la condición se cumple; false: aparece «si no».
@export var when_true := true

var present := true


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	add_to_group(&"unsafe_ground")
	if variables:
		variables.changed.connect(func(_name: StringName, _value: Variant) -> void: refresh())
	refresh.call_deferred()


func refresh() -> void:
	var met := variables != null and SimVariables.evaluate(clauses, variables.values, all)
	present = met == when_true
	_closed = not present
	if _shape:
		_shape.set_deferred(&"disabled", not present)
	queue_redraw()


func _draw() -> void:
	if not present and not Engine.is_editor_hint():
		# Apagada: solo el contorno punteado (se ve dónde aparecerá).
		var rect := Rect2(Vector2.ZERO, Vector2(width, 8))
		for x in range(0, int(width), 8):
			draw_line(Vector2(x, 0), Vector2(minf(x + 4, width), 0), Color(0.5, 0.6, 0.9, 0.35), 1.0)
			draw_line(Vector2(x, 8), Vector2(minf(x + 4, width), 8), Color(0.5, 0.6, 0.9, 0.35), 1.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(2, -3), "si" if when_true else "si no", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.6, 0.7, 1.0, 0.5))
		return
	super()
	draw_string(ThemeDB.fallback_font, Vector2(2, -3), "si" if when_true else "si no", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("5dff9a"))

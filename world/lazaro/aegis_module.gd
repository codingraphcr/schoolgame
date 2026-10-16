@tool
class_name AegisModule
extends Area2D
## Un módulo de Aegis (procesamiento, comunicación o protección) en su sala de la Estación Lázaro. Al tocarlo, Kai lo
## recoge: queda la marca «modulo_<id>» y un aviso «Módulo de X recuperado (n / 3)». Con los tres, se completa el paso
## de la misión (ClueTracker). Ya recogido, no aparece. El origen es el piso.

const ALL: Array[StringName] = [&"procesamiento", &"comunicacion", &"proteccion"]
const NAMES := { &"procesamiento": "procesamiento", &"comunicacion": "comunicación", &"proteccion": "protección" }
const COLORS := { &"procesamiento": Color("ffd166"), &"comunicacion": Color("3ef2ff"), &"proteccion": Color("7ee08a") }

@export var id: StringName = &"procesamiento"
@export var quest_id: StringName = &"eco_en_la_red"
@export var step_id: StringName = &"recuperar_modulos"

var _clock := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 2  # Capa del jugador
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30, 40)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	add_child(shape)
	body_entered.connect(_on_body_entered)


static func flag_of(module_id: StringName) -> StringName:
	return StringName("modulo_%s" % module_id)


static func flags() -> Array[StringName]:
	var result: Array[StringName] = []
	for module_id in ALL:
		result.append(flag_of(module_id))
	return result


func is_taken() -> bool:
	return not Engine.is_editor_hint() and get_node("/root/GameState").has_flag(flag_of(id))


func _process(delta: float) -> void:
	_clock += delta
	visible = not is_taken()
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if not body is Player or is_taken():
		return
	var state := get_node("/root/GameState")
	ClueTracker.register(state, flag_of(id), flags(), ALL.size(), quest_id, step_id)
	Sfx.play(&"eco_pickup")
	var count := ClueTracker.count(state, flags())
	get_tree().call_group(&"toast", &"show_message", "Módulo de %s recuperado (%d / %d)" % [NAMES[id], count, ALL.size()], 3.0)


func _draw() -> void:
	var color: Color = COLORS.get(id, Color.WHITE)
	var bob := sin(_clock * 2.5) * 3.0
	var center := Vector2(0, -26 + bob)
	draw_circle(center, 18.0, Color(color, 0.18))
	draw_rect(Rect2(center - Vector2(10, 12), Vector2(20, 24)), Color("e8eef6"))
	draw_rect(Rect2(center - Vector2(10, 12), Vector2(20, 24)), color, false, 2.0)
	draw_rect(Rect2(center - Vector2(5, 6), Vector2(10, 12)), color)

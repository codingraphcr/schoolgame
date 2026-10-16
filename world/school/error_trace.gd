@tool
class_name ErrorTrace
extends Interactable
## Un rastro de Chip o Glitch en el colegio («Tras las huellas del error», Capítulo 1): una marca de datos que solo
## se ve con la Visión Digital mientras el profesor prepara el acceso al cuarto técnico (paso STEP de QUEST). Con E,
## Kai la mira y comenta (dialogue); queda la marca «huella_<id>». Al encontrar REQUIRED rastros (de los que haya en
## el colegio) se completa el paso: no hace falta encontrarlos todos.
## El dibujo va en la capa digital de la sala si existe (para que la oscuridad de la Visión no lo apague); si no,
## en la sala. El origen es el piso, debajo de la marca. Se ve también en el editor.

const QUEST := &"una_clase_diferente"
const STEP := &"buscar_huellas"
## Cuántos rastros bastan (hay más repartidos por el colegio).
const REQUIRED := 2
## Todos los rastros que existen (para contar los encontrados).
const ALL: Array[StringName] = [&"patio", &"soda", &"pasillo"]
const CYAN := Color("3ef2ff")
const MAG := Color("ff3ea5")

enum Author { CHIP, GLITCH }

@export var id: StringName = &""
@export var author := Author.CHIP
@export var lines: PackedStringArray = ["CHIP", "ESTUVO AQUÍ"]
@export var dialogue: Dialogue
## Altura de la marca sobre el piso.
@export var height := 90.0

var _canvas: VectorCanvas


func _init() -> void:
	prompt_text = "E: mirar el rastro"


func _ready() -> void:
	prompt_offset = Vector2(-40, -height - 46.0)
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	if Engine.is_editor_hint():
		add_child(_canvas)
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 56)
	shape.shape = rect
	shape.position = Vector2(0, -28)
	add_child(shape)
	super()
	# El aviso normal podría quedar a oscuras: se dibuja junto con la marca (ver _paint).
	_prompt.self_modulate.a = 0.0
	var layer := _digital_layer()
	if layer:
		layer.add_child.call_deferred(_canvas)
		_canvas.set_deferred("position", global_position)
	else:
		add_child(_canvas)
	interacted.connect(_on_interacted)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var vision := get_node("/root/DigitalVision")
	var shown := is_searchable()
	_canvas.visible = shown and vision.blend > 0.001
	_canvas.modulate.a = vision.blend * vision.warning_factor()
	enabled = shown and vision.is_active()
	super(delta)


## Si se puede buscar ahora: durante el paso de buscar rastros y si todavía no se encontró.
func is_searchable() -> bool:
	var state := get_node("/root/GameState")
	return state.get_current_step(QUEST) == STEP and not state.has_flag(flag_of(id))


static func flag_of(trace_id: StringName) -> StringName:
	return StringName("huella_%s" % trace_id)


static func found_count(state: Node) -> int:
	var count := 0
	for trace_id in ALL:
		if state.has_flag(flag_of(trace_id)):
			count += 1
	return count


## Registra un rastro encontrado; con REQUIRED se completa el paso (Kai ya puede volver con el profesor).
static func register(state: Node, trace_id: StringName) -> void:
	state.set_flag(flag_of(trace_id))
	if found_count(state) >= REQUIRED and state.get_current_step(QUEST) == STEP:
		state.complete_step(QUEST, STEP)


func _on_interacted(_player: Player) -> void:
	busy = true
	await StoryHelper.say(self, dialogue)
	register(get_node("/root/GameState"), id)
	busy = false


func _exit_tree() -> void:
	if _canvas and _canvas.get_parent() != self:
		_canvas.queue_free()


func _digital_layer() -> Node:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node.get_node_or_null("DigitalLayer") if node else null


func _paint(c: VectorCanvas, t: float) -> void:
	var color := CYAN if author == Author.CHIP else MAG
	var jump := Vector2(2.0 * signf(sin(t * 41.0)), 0.0) if fmod(t, 1.9) < 0.12 else Vector2.ZERO
	var center := Vector2(0, -height) + jump
	c.glow(center, 40.0, Color(color, 0.2))
	# La cara del autor: Chip redondo, Glitch con picos.
	var face := center + Vector2(0, -16)
	if author == Author.CHIP:
		c.draw_arc(face, 8.0, 0.0, TAU, 16, color, 1.5)
	else:
		c.draw_polyline(PackedVector2Array([face + Vector2(-9, 6), face + Vector2(-6, -8), face + Vector2(0, -3), face + Vector2(6, -8),
			face + Vector2(9, 6), face + Vector2(-9, 6)]), color, 1.5)
	c.draw_rect(Rect2(face + Vector2(-4, -2), Vector2(2, 2)), Color.WHITE)
	c.draw_rect(Rect2(face + Vector2(2, -2), Vector2(2, 2)), Color.WHITE)
	c.draw_line(face + Vector2(-3, 3), face + Vector2(3, 3), Color.WHITE, 1.0)
	for i in lines.size():
		var shift := Vector2(-1.5, 0) if jump != Vector2.ZERO and i % 2 == 0 else Vector2.ZERO
		c.crisp_text(center + Vector2(-50, 4 + i * 10) + shift, lines[i], 7, color, HORIZONTAL_ALIGNMENT_CENTER, 100)
	# Líneas de interferencia.
	for k in 2:
		var y := center.y - 26 + fmod(t * 16.0 + k * 19.0, 44.0)
		c.draw_line(Vector2(center.x - 30, y), Vector2(center.x + 30, y), Color(color, 0.15), 1.0)
	if not Engine.is_editor_hint() and _can_interact():
		c.crisp_text(Vector2(-60, -height - 40), prompt_text, 7, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 120)

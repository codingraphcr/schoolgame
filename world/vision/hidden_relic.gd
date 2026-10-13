@tool
class_name HiddenRelic
extends Interactable
## Un objeto escondido en la oscuridad que solo se distingue con la Visión Digital (H5: la Nullblade
## y el Grimorio del cuarto viejo). Con la Visión activa brilla y se puede tomar con E; sin ella no se
## ve. Su dibujo va en la capa digital de la sala (DigitalLayer) para que la oscuridad no lo apague,
## y el aviso «E: tomar…» también. Al tomarlo emite taken y deja taken_flag en GameState.
## El origen es la base, apoyada en el suelo. Se ve también en el editor.

signal taken(player: Player)

const CYAN := Color("3ef2ff")
const VIOLET := Color("b46bff")

enum Kind { NULLBLADE, GRIMORIO }

@export var kind := Kind.NULLBLADE
@export var label := "la Nullblade"
## Marca que queda al tomarlo (el objeto ya no aparece).
@export var taken_flag: StringName = &""

var _canvas: VectorCanvas
var _taking := false


func _init() -> void:
	prompt_offset = Vector2(-40, -70)


func _ready() -> void:
	prompt_text = "E: tomar %s" % label
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	if Engine.is_editor_hint():
		add_child(_canvas)
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 56)
	shape.shape = rect
	shape.position = Vector2(0, -28)
	add_child(shape)
	super()
	# El aviso normal quedaría a oscuras: se dibuja en la capa digital (ver _paint).
	_prompt.self_modulate.a = 0.0
	_canvas.add_to_group(&"digital_only")
	# DigitalWorld lo muestra u oculta al encender o apagar la Visión; al empezar, según cómo esté.
	_canvas.visible = get_node("/root/DigitalVision").is_active()
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
	enabled = not is_taken() and get_node("/root/DigitalVision").is_active()
	super(delta)


func is_taken() -> bool:
	return _taking or (taken_flag != &"" and get_node("/root/GameState").has_flag(taken_flag))


func _on_interacted(player: Player) -> void:
	_taking = true
	busy = true
	if taken_flag != &"":
		get_node("/root/GameState").set_flag(taken_flag)
	taken.emit(player)


func _exit_tree() -> void:
	if _canvas and _canvas.get_parent() != self:
		_canvas.queue_free()


func _digital_layer() -> Node:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node.get_node_or_null("DigitalLayer") if node else null


func _paint(c: VectorCanvas, t: float) -> void:
	if not Engine.is_editor_hint() and is_taken():
		return
	var color := VIOLET if kind == Kind.NULLBLADE else CYAN
	var pulse := 0.5 + 0.5 * sin(t * 2.5)
	var center := Vector2(0, -26)
	c.glow(center, 34.0 + 4.0 * pulse, Color(color, 0.25 + 0.15 * pulse))
	if kind == Kind.NULLBLADE:
		_paint_blade(c, center, color, t)
	else:
		_paint_book(c, center, color, t)
	# Aviso, nítido y encima de la oscuridad.
	if not Engine.is_editor_hint() and _can_interact():
		c.crisp_text(Vector2(-60, -66), prompt_text, 7, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 120)


## Silueta de la espada clavada en vertical, con datos que suben.
func _paint_blade(c: VectorCanvas, center: Vector2, color: Color, t: float) -> void:
	var blade := PackedVector2Array([Vector2(0, -26), Vector2(4, -18), Vector2(3, 10), Vector2(-3, 10), Vector2(-4, -18)])
	for i in blade.size():
		blade[i] += center
	c.shape(blade, Color(color, 0.55), color, 1.0)
	c.draw_rect(Rect2(center + Vector2(-9, 10), Vector2(18, 3)), color)
	c.draw_rect(Rect2(center + Vector2(-2, 13), Vector2(4, 10)), Color(color, 0.8))
	c.draw_circle(center + Vector2(0, 11.5), 2.0, Color.WHITE)
	for k in 4:
		var y := fmod(t * 20.0 + k * 9.0, 36.0)
		c.draw_rect(Rect2(center + Vector2(-12 + k * 7, 24 - y), Vector2(1, 3)), Color(color, 0.6 * (1.0 - y / 36.0)))


## Libro cerrado con circuitos en la tapa, flotando apenas.
func _paint_book(c: VectorCanvas, center: Vector2, color: Color, t: float) -> void:
	var float_y := sin(t * 1.8) * 2.0
	var cover := Rect2(center + Vector2(-11, -14 + float_y), Vector2(22, 28))
	c.gradient_box(cover, 2.0, Color(0.08, 0.2, 0.3), Color(0.03, 0.08, 0.14), color, 1.0)
	c.draw_rect(Rect2(cover.position + Vector2(-2, 0), Vector2(3, cover.size.y)), Color(color, 0.7))
	var mid := cover.get_center()
	c.draw_polyline(PackedVector2Array([mid + Vector2(-6, -8), mid + Vector2(0, -8), mid + Vector2(0, 0), mid + Vector2(6, 0)]), color, 1.0)
	c.draw_polyline(PackedVector2Array([mid + Vector2(-6, 6), mid + Vector2(-2, 6), mid + Vector2(-2, 10)]), color, 1.0)
	c.draw_circle(mid, 2.0, Color.WHITE)

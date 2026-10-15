class_name VariableNode
extends Interactable
## Nodo de variable del simulador (Capítulo 2): una terminalita que muestra «nombre = valor». Con E pasa
## al siguiente valor de options (en ciclo). Cambia la variable en SimVariables.

const CYAN := Color("3ef2ff")
const GOLD := Color("ffd166")
const PANEL := Color(0.04, 0.05, 0.12, 0.92)

@export var variables: SimVariables
@export var variable: StringName = &"llave"
## Valores posibles, en orden (p. ej. [false, true] o [1, 2, 3, 4, 5]).
@export var options: Array = [false, true]

var _flash := 0.0


func _init() -> void:
	prompt_text = "E: cambiar valor"
	prompt_offset = Vector2(-34, -54)


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(36, 40)
	shape.shape = rect
	shape.position = Vector2(0, -20)
	add_child(shape)
	super()
	interacted.connect(func(_player: Player) -> void: next_value())
	if variables:
		variables.changed.connect(func(_name: StringName, _value: Variant) -> void: queue_redraw())


func value() -> Variant:
	return variables.get_value(variable) if variables else null


## Pasa al siguiente valor (en ciclo).
func next_value() -> void:
	if variables == null or options.is_empty():
		return
	var index := options.find(value())
	variables.set_value(variable, options[(index + 1) % options.size()])
	_flash = 1.0
	Sfx.play(&"ui_move", 1.2)


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(_flash - delta * 3.0, 0.0)
		queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var text := "%s = %s" % [variable, SimVariables.format(value())]
	var width := maxf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 10.0, 36.0)
	var screen := Rect2(Vector2(-width / 2.0, -38), Vector2(width, 18))
	draw_rect(Rect2(Vector2(-3, -20), Vector2(6, 20)), Color(0.2, 0.25, 0.4))
	draw_rect(screen.grow(2.0 + _flash * 2.0), Color(GOLD, 0.3 * _flash))
	draw_rect(screen, PANEL)
	draw_rect(screen, CYAN, false, 1.0)
	draw_string(font, screen.position + Vector2(5, 12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, GOLD if _flash > 0.0 else CYAN)

@tool
class_name BitChest
extends Interactable
## Cofre de datos: con E se abre y suelta BITS. Queda abierto para siempre (marca en GameState,
## "cofre_<chest_id>"). Dibujado en pixel art por código; se ve también en el editor.
## El origen es la base del cofre, apoyada en el suelo.

const BODY := Color("1c1438")
const BODY_LIGHT := Color("2c2156")
const TRIM := Color("8a5cff")
const TRIM_LIGHT := Color("d9ccff")
const OUTLINE := Color("0a0718")
const SIZE := Vector2(22, 14)

## BITS que tiene dentro.
@export var bits := 30
## Identificador único del cofre (para recordar que ya se abrió). Vacío = el nombre del nodo.
@export var chest_id: StringName = &""

var opened := false
var _open_amount := 0.0
var _time := 0.0


func _init() -> void:
	prompt_text = "E: abrir el cofre"
	prompt_offset = Vector2(-36, -34)


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(true)
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(32, 24)
	shape.shape = rect
	shape.position = Vector2(0, -12)
	add_child(shape)
	super()
	interacted.connect(_on_interacted)
	var game_state := get_node_or_null("/root/GameState")
	if game_state and game_state.has_flag(flag()):
		opened = true
		_open_amount = 1.0
		enabled = false


## Marca que queda en GameState al abrirlo.
func flag() -> StringName:
	return StringName("cofre_" + String(chest_id if chest_id != &"" else StringName(name)))


func open() -> void:
	if opened:
		return
	opened = true
	enabled = false
	var game_state := get_node_or_null("/root/GameState")
	if game_state:
		game_state.set_flag(flag())
	var tween := create_tween()
	tween.tween_property(self, "_open_amount", 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var parent := get_parent()
	var at := global_position + Vector2(0, -SIZE.y - 2)
	PixelBurst.spawn(parent, at, [TRIM, TRIM_LIGHT, Color.WHITE], 18, 80.0)
	BitCoin.spawn_burst(parent, at, bits)


func _on_interacted(_player: Player) -> void:
	open()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if not Engine.is_editor_hint():
		super(delta)


func _draw() -> void:
	var w := SIZE.x
	var h := SIZE.y
	var base := Rect2(-w / 2.0, -h, w, h)
	# Brillo del cofre cerrado (late) o el haz al estar abierto.
	if opened:
		var glow := Color(TRIM, 0.18 + 0.06 * sin(_time * 3.0))
		draw_colored_polygon(PackedVector2Array([Vector2(-w / 2.0 + 3, -h), Vector2(w / 2.0 - 3, -h),
			Vector2(w / 2.0 + 4, -h - 26), Vector2(-w / 2.0 - 4, -h - 26)]), glow)
	else:
		draw_circle(Vector2(0, -h / 2.0), w * 0.7, Color(TRIM, 0.07 + 0.04 * sin(_time * 2.5)))
	# Cuerpo.
	draw_rect(base.grow(1), OUTLINE)
	draw_rect(base, BODY)
	draw_rect(Rect2(base.position, Vector2(w, 2)), BODY_LIGHT)
	draw_rect(Rect2(-w / 2.0, -4, w, 1), Color(TRIM, 0.6))
	# Tapa (se levanta al abrir).
	var lid_y := -h - 5.0 - _open_amount * 6.0
	var lid := Rect2(-w / 2.0 - 1, lid_y, w + 2, 5)
	draw_rect(lid.grow(1), OUTLINE)
	draw_rect(lid, BODY_LIGHT)
	draw_rect(Rect2(lid.position.x, lid.end.y - 1, lid.size.x, 1), TRIM)
	# Cerradura: un rombo con el símbolo de bit.
	var lock := Vector2(0, -h + 4)
	var r := 3.5
	draw_colored_polygon(PackedVector2Array([lock + Vector2(0, -r), lock + Vector2(r, 0), lock + Vector2(0, r), lock + Vector2(-r, 0)]),
		TRIM_LIGHT if not opened else Color(TRIM, 0.6))
	draw_rect(Rect2(lock - Vector2(1, 1), Vector2(2, 2)), OUTLINE)
	# Esquinas metálicas.
	for x in [-w / 2.0, w / 2.0 - 3]:
		draw_rect(Rect2(x, -h, 3, 3), TRIM)
		draw_rect(Rect2(x, -3, 3, 3), TRIM)

@tool
class_name SavePoint
extends Interactable
## Computadora segura: el punto de guardado del juego.
##   · Al pasar, queda como punto de control (si Kai muere, reaparece aquí).
##   · Con E: guarda la partida (SaveManager), llena los cristales y la energía.
## Se distingue de las terminales (pantalla azul con «>_») y de los nodos de Aegis: es un monitor
## verde con un escudo. El origen es la base, apoyada en el suelo. Se ve también en el editor.

const GREEN := Color("5dff9a")
const DARK := Color("0a1a14")

## Id estable dentro de su sala (la partida se continúa en este punto).
@export var save_id: StringName = &"guardado"

var active := false

var _canvas: VectorCanvas
var _flash := 0.0


func _init() -> void:
	prompt_text = "E: guardar partida"
	prompt_offset = Vector2(-42, -66)


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 48)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	add_child(shape)
	super()
	body_entered.connect(_on_passed)
	interacted.connect(_on_interacted)


## Kai pasa por delante: queda como punto de control.
func _on_passed(body: Node) -> void:
	var room := _room()
	if body is Player and room and room.checkpoint != self:
		room.checkpoint = self
		active = true


func _on_interacted(player: Player) -> void:
	save_here(player)


## Guarda la partida aquí: cura, marca el punto de control y escribe el guardado.
func save_here(player: Player) -> bool:
	var room := _room()
	if room == null:
		return false
	room.checkpoint = self
	active = true
	player.health.restore_full()
	player.set_energy(player.max_energy)
	var game_state := get_node("/root/GameState")
	game_state.current_masks = -1.0
	game_state.current_energy = -1.0
	var saved: bool = get_node("/root/SaveManager").save_game(room.scene_file_path, save_id)
	_flash = 1.0
	Sfx.play(&"heal_done" if saved else &"error")
	get_tree().call_group(&"toast", &"show_message",
		"Partida guardada · cristales y energía llenos" if saved else "No se pudo guardar la partida", 2.5)
	return saved


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta * 1.5, 0.0)
	if not Engine.is_editor_hint():
		super(delta)


func _room() -> Room:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node as Room


func _paint(c: VectorCanvas, t: float) -> void:
	var on := Engine.is_editor_hint() or active
	var pulse := 0.5 + 0.5 * sin(t * (3.0 if on else 1.2))
	var screen := Rect2(-18, -46, 36, 26)
	c.glow(screen.get_center(), 30.0, Color(GREEN, (0.18 if on else 0.08) + 0.1 * pulse + 0.4 * _flash))
	# Gabinete y pantalla.
	c.gradient_box(Rect2(-12, -18, 24, 18), 2.0, Color("2a3a4a"), Color("16202c"), DARK, 0.8)
	c.draw_rect(Rect2(-8, -12, 16, 2), Color(GREEN, 0.5 + 0.4 * pulse))
	c.gradient_box(screen, 3.0, Color("0e2a1e"), DARK, GREEN, 1.2)
	# Escudo con una marca: «seguro».
	var center := screen.get_center()
	var shield := PackedVector2Array([center + Vector2(-7, -8), center + Vector2(7, -8), center + Vector2(7, 1),
		center + Vector2(0, 9), center + Vector2(-7, 1)])
	c.shape(shield, Color(GREEN, 0.35 + 0.3 * pulse), GREEN, 1.0)
	c.draw_polyline(PackedVector2Array([center + Vector2(-3.5, 0), center + Vector2(-1, 3), center + Vector2(4, -3)]), Color.WHITE, 1.4)
	c.crisp_text(Vector2(-30, -52), "GUARDAR", 5, Color(GREEN, 0.8), HORIZONTAL_ALIGNMENT_CENTER, 60)

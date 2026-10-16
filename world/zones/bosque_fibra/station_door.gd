@tool
class_name StationDoor
extends Interactable
## La puerta de la Estación Lázaro (Capítulo 3), en lo profundo del Bosque de Fibra: una compuerta blanca con detalles
## azules. En el paso step_id de quest_id, con E rechaza el acceso; Kai insiste y la señal azul desconocida la abre
## («ACCESO CONCEDIDO · ENERGÍA RESTANTE: CRÍTICA · POR FAVOR... NO TE DETENGAS») y se completa el paso (fin del
## Nivel 5). Abierta (OPEN_FLAG), es una puerta como cualquier otra (RoomExit.travel). El origen es el piso, al centro.

const OPEN_FLAG := &"estacion_lazaro_abierta"
const WHITE := Color("e8eef6")
const BLUE := Color("3a8adf")
const CYAN := Color("3ef2ff")

@export var door_id: StringName = &"estacion"
@export_file("*.tscn") var target_scene := ""
@export var target_entry: StringName = &""
@export var denied_lines: PackedStringArray = ["ACCESO DENEGADO", "INSTALACIÓN EN AISLAMIENTO"]
@export var insist_dialogue: Dialogue
@export var granted_lines: PackedStringArray = ["ACCESO CONCEDIDO", "ENERGÍA RESTANTE: CRÍTICA", "POR FAVOR... NO TE DETENGAS"]
@export var quest_id: StringName = &"contagio_digital"
@export var step_id: StringName = &"llegar_estacion"
@export var quick := false

var _used := false
var _opening := 0.0


func _init() -> void:
	prompt_offset = Vector2(-50, -150)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(80, 64)
	shape.shape = rect
	shape.position = Vector2(0, -32)
	add_child(shape)
	super()
	interacted.connect(_on_interacted)
	if is_open():
		_opening = 1.0


func _process(delta: float) -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	var state := get_node("/root/GameState")
	enabled = is_open() or state.get_current_step(quest_id) == step_id
	prompt_text = "E: entrar a la estación" if is_open() else "E: tocar la compuerta"
	super(delta)


func is_open() -> bool:
	return not Engine.is_editor_hint() and get_node("/root/GameState").has_flag(OPEN_FLAG)


func _on_interacted(player: Player) -> void:
	if is_open():
		if not _used:
			_used = RoomExit.travel(self, player, door_id, target_scene, target_entry)
		return
	busy = true
	Sfx.play(&"error")
	await GrimorioAlert.show_lines(self, denied_lines, 0.6 if quick else 2.0).finished
	await StoryHelper.say(self, insist_dialogue)
	Sfx.play(&"reveal_flash")
	GrimorioAlert.show_lines(self, granted_lines, 1.0 if quick else 3.5, GrimorioAlert.BLUE)
	var tween := create_tween()
	tween.tween_property(self, "_opening", 1.0, 0.4 if quick else 1.6)
	await tween.finished
	var state := get_node("/root/GameState")
	state.set_flag(OPEN_FLAG)
	state.complete_step(quest_id, step_id)
	busy = false


func _draw() -> void:
	var open := 1.0 if Engine.is_editor_hint() else _opening
	# Marco blanco con circuitos azules y el nombre.
	draw_rect(Rect2(-70, -140, 140, 140), WHITE)
	draw_rect(Rect2(-70, -140, 140, 140), BLUE, false, 3.0)
	draw_rect(Rect2(-50, -120, 100, 120), Color("0a1424"))
	var half := 50.0 * (1.0 - open)
	draw_rect(Rect2(-50, -120, half, 120), Color("c8d4e4"))
	draw_rect(Rect2(50 - half, -120, half, 120), Color("c8d4e4"))
	if half > 1.0:
		draw_line(Vector2(-50 + half, -120), Vector2(-50 + half, 0), BLUE, 2.0)
		draw_line(Vector2(50 - half, -120), Vector2(50 - half, 0), BLUE, 2.0)
	for k in 3:
		draw_line(Vector2(-66, -100 + k * 30), Vector2(-54, -100 + k * 30), CYAN, 2.0)
		draw_line(Vector2(54, -100 + k * 30), Vector2(66, -100 + k * 30), CYAN, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-70, -148), "ESTACIÓN LÁZARO", HORIZONTAL_ALIGNMENT_CENTER, 140, 11, Color("1a2a4a"))

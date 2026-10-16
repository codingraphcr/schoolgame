@tool
class_name StationLog
extends Interactable
## Una terminal de registros de la Estación Lázaro: con E muestra un registro antiguo en la ventana de inspección
## (líneas tipo bitácora) y deja la marca «registro_<id>» (que puede abrir una página del Grimorio). No revela lo que
## todavía no corresponde: lo que falta aparece como [DATOS NO DISPONIBLES]. El origen es el piso.

const CYAN := Color("3ef2ff")

@export var id: StringName = &""
@export var title := "REGISTRO"
@export var lines: PackedStringArray = []
@export var kai_note := ""
## Si la partida está en ese paso, leer el registro lo completa (p. ej. el registro principal: «explorar la estación»).
@export var quest_id: StringName = &""
@export var step_id: StringName = &""

var _clock := 0.0


func _init() -> void:
	prompt_offset = Vector2(-50, -96)
	prompt_text = "E: leer el registro"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(44, 56)
	shape.shape = rect
	shape.position = Vector2(0, -28)
	add_child(shape)
	super()
	interacted.connect(_on_interacted)


static func flag_of(log_id: StringName) -> StringName:
	return StringName("registro_%s" % log_id)


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()
	if Engine.is_editor_hint():
		return
	super(delta)


func _on_interacted(_player: Player) -> void:
	busy = true
	var entry := {
		"name": title,
		"subtitle": "Registro de la Estación Lázaro",
		"description": "",
		"lines": lines,
		"note": kai_note,
	}
	var window := InspectionWindow.open(self, "ESTACIÓN LÁZARO", [entry] as Array[Dictionary], "", "seguir")
	var state := get_node("/root/GameState")
	state.set_flag(flag_of(id))
	await window.closed
	busy = false
	if quest_id != &"" and state.get_current_step(quest_id) == step_id:
		state.complete_step(quest_id, step_id)


func _draw() -> void:
	draw_rect(Rect2(-4, -40, 8, 40), Color("c8d4e4"))
	var screen := Rect2(-20, -70, 40, 30)
	draw_rect(screen.grow(2), Color("dfe6f0"))
	draw_rect(screen, Color("0a1424"))
	for k in 3:
		var w := 24.0 - (k * 5 + int(_clock * 3.0)) % 12
		draw_rect(Rect2(screen.position + Vector2(5, 6 + k * 7), Vector2(w, 3)), Color(CYAN, 0.8))
	var read: bool = not Engine.is_editor_hint() and get_node("/root/GameState").has_flag(flag_of(id))
	if not read:
		draw_string(ThemeDB.fallback_font, Vector2(-4, -76), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("f2c14e"))

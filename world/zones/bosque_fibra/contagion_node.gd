@tool
class_name ContagionNode
extends Node2D
## El nodo de distribución deteriorado del Bosque de Fibra (Capítulo 3, «Contener el contagio»): reenvía información
## dañada por varias conexiones (hacia el colegio, entre otras). Kai tiene que cerrar las válvulas de los flujos
## dañados (con la Visión se ve cuáles) y dejar abiertas las sanas: aislar lo afectado sin cortar lo que funciona.
## Si cierra una sana, Kai lo nota (wrong_dialogue). Con todo en orden: el nodo deja de reenviar, queda la marca
## CONTAINED_FLAG (las computadoras del colegio dejan de fallar) y la señal protectora salva a Kai de una caída
## (rescue): «POR FAVOR, EVITA VOLVER A CAER». Completa step_id. Todo es simulado: no hay nada real.
## El origen es el centro del nodo, en el piso.

const CONTAINED_FLAG := &"contagio_contenido"
const CYAN := Color("3ef2ff")
const RED := Color("ff4a6a")
const BLUE := Color(0.55, 0.85, 1.35)

@export var valves: Array[NodePath] = []
@export var wrong_dialogue: Dialogue
@export var contained_dialogue: Dialogue
@export var rescue_dialogue: Dialogue
@export var weak_lines: PackedStringArray = ["SEÑAL PROTECTORA", "ENERGÍA: 18 %", "PROTEGIENDO LAS CONEXIONES SANAS..."]
@export var quest_id: StringName = &"contagio_digital"
@export var step_id: StringName = &"contener_contagio"
@export var quick := false

var resolving := false
var _clock := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for path in valves:
		var valve := get_node_or_null(path) as FlowValve
		if valve:
			valve.toggled.connect(_on_toggled)


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func is_contained() -> bool:
	if not Engine.is_editor_hint() and get_node("/root/GameState").has_flag(CONTAINED_FLAG):
		return true
	for path in valves:
		var valve := get_node_or_null(path) as FlowValve
		if valve and valve.open == valve.damaged:
			return false
	return true


func _on_toggled(valve: FlowValve) -> void:
	if resolving:
		return
	if not valve.open and not valve.damaged:
		await StoryHelper.say(self, wrong_dialogue)
		return
	if is_contained():
		_resolve()


func _resolve() -> void:
	resolving = true
	var state := get_node("/root/GameState")
	state.set_flag(CONTAINED_FLAG)
	Sfx.play(&"terminal_ok")
	await StoryHelper.say(self, contained_dialogue)
	await _rescue()
	await GrimorioAlert.show_lines(self, weak_lines, 1.0 if quick else 3.0, GrimorioAlert.BLUE).finished
	state.complete_step(quest_id, step_id)
	resolving = false


## El nodo se sacude, el piso cede bajo Kai... y la señal azul lo sostiene.
func _rescue() -> void:
	var player := StoryHelper.room_player(self)
	if player == null:
		return
	player.controls_locked = true
	player.set_physics_process(false)
	var start := player.global_position
	var tween := create_tween()
	tween.tween_property(player, "global_position:y", start.y + 40.0, 0.15 if quick else 0.35)
	tween.tween_callback(func() -> void: player.modulate = BLUE)
	tween.tween_property(player, "global_position:y", start.y, 0.2 if quick else 0.6)
	await tween.finished
	player.modulate = Color.WHITE
	player.set_physics_process(true)
	GrimorioAlert.show_lines(self, PackedStringArray(["POR FAVOR, EVITA VOLVER A CAER"]), 1.0 if quick else 2.5, GrimorioAlert.BLUE)
	await StoryHelper.say(self, rescue_dialogue)
	player.controls_locked = false


func _draw() -> void:
	var contained := is_contained()
	# El nodo: un tronco de fibra con un núcleo que late (rojo mientras reenvía lo dañado).
	draw_rect(Rect2(-28, -150, 56, 150), Color("1a2238"))
	draw_rect(Rect2(-28, -150, 56, 150), Color("3a4870"), false, 2.0)
	var pulse := 0.5 + 0.5 * sin(_clock * (2.0 if contained else 7.0))
	var core := CYAN if contained else RED
	draw_circle(Vector2(0, -95), 18.0, Color(core, 0.25 + 0.2 * pulse))
	draw_circle(Vector2(0, -95), 10.0, core)
	draw_string(ThemeDB.fallback_font, Vector2(-60, -162), "NODO DE DISTRIBUCIÓN", HORIZONTAL_ALIGNMENT_CENTER, 120, 8, Color("c8d0e0"))
	if not contained:
		draw_string(ThemeDB.fallback_font, Vector2(-60, -40), "REENVIANDO...", HORIZONTAL_ALIGNMENT_CENTER, 120, 8, Color(RED, 0.5 + 0.5 * pulse))

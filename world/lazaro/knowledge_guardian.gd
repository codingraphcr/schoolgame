@tool
class_name KnowledgeGuardian
extends Interactable
## Un guardián de conocimiento de la Estación Lázaro (Capítulo 3, «Eco en la Red»): una proyección holográfica de
## seguridad que custodia un módulo de Aegis. Diseño original (un monolito de luz con un ojo de datos y anillos de
## símbolos). Con E: la sala se oscurece, aparecen sus símbolos, habla con voz digital (intro_dialogue) y hace UNA
## pregunta (challenge, ChoiceWindow): si Kai se equivoca, la explicación le da una pista y puede volver a intentar,
## sin castigo y sin bloqueos. Al acertar: success_dialogue, la proyección se disuelve, queda la marca
## «guardian_<id>» y se abre su barrera (LazaroGate). El origen es el piso.

const CYAN := Color("3ef2ff")
const BLUE := Color("6fa8ff")

@export var id: StringName = &""
@export var title := "GUARDIÁN"
@export var intro_dialogue: Dialogue
@export var challenge: ChoiceChallenge
@export var success_dialogue: Dialogue
@export var quest_id: StringName = &"eco_en_la_red"
@export var step_id: StringName = &"recuperar_modulos"
@export var quick := false

var presenting := false
var _clock := 0.0
var _focus := 0.0
var _fade := 1.0


func _init() -> void:
	prompt_offset = Vector2(-70, -150)
	prompt_text = "E: acercarse al guardián"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(90, 64)
	shape.shape = rect
	shape.position = Vector2(0, -32)
	add_child(shape)
	super()
	interacted.connect(_on_interacted)
	if is_passed():
		_fade = 0.0


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()
	if Engine.is_editor_hint():
		return
	enabled = not is_passed() and not presenting and get_node("/root/GameState").get_current_step(quest_id) == step_id
	super(delta)


static func flag_of(guardian_id: StringName) -> StringName:
	return StringName("guardian_%s" % guardian_id)


func is_passed() -> bool:
	return not Engine.is_editor_hint() and get_node("/root/GameState").has_flag(flag_of(id))


func _on_interacted(_player: Player) -> void:
	presenting = true
	busy = true
	# Presentación: la sala se oscurece y la proyección toma el centro.
	var room := _room()
	var ambient := room.get_node_or_null("Ambient") as CanvasModulate if room else null
	var before := ambient.color if ambient else Color.WHITE
	var tween := create_tween()
	tween.tween_property(self, "_focus", 1.0, 0.2 if quick else 0.9)
	if ambient:
		tween.parallel().tween_property(ambient, "color", before.darkened(0.55), 0.2 if quick else 0.9)
	await tween.finished
	Sfx.play(&"entity_whisper")
	await StoryHelper.say(self, intro_dialogue)
	await StoryHelper.choose_until_done(self, challenge)
	var state := get_node("/root/GameState")
	state.set_flag(flag_of(id))
	Sfx.play(&"reveal_flash")
	await StoryHelper.say(self, success_dialogue)
	var out := create_tween()
	out.tween_property(self, "_fade", 0.0, 0.2 if quick else 1.0)
	out.parallel().tween_property(self, "_focus", 0.0, 0.2 if quick else 1.0)
	if ambient:
		out.parallel().tween_property(ambient, "color", before, 0.2 if quick else 1.0)
	await out.finished
	presenting = false
	busy = false


func _room() -> Room:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node as Room


func _draw() -> void:
	if _fade <= 0.01:
		# Ya superado: solo queda la base apagada.
		draw_rect(Rect2(-30, -8, 60, 8), Color("8a94a8"))
		return
	var a := _fade
	var glow := 0.4 + 0.6 * _focus
	# Base de proyección.
	draw_rect(Rect2(-34, -10, 68, 10), Color(0.8, 0.86, 0.95, a))
	draw_rect(Rect2(-28, -14, 56, 4), Color(CYAN, 0.8 * a))
	# El monolito de luz con su ojo de datos.
	var height := 120.0
	var bob := sin(_clock * 1.5) * 3.0
	var body := PackedVector2Array([Vector2(-22, -14), Vector2(22, -14), Vector2(14, -height + bob), Vector2(-14, -height + bob)])
	draw_colored_polygon(body, Color(BLUE, 0.18 * a * (0.6 + glow)))
	draw_polyline(PackedVector2Array([body[0], body[3], body[2], body[1]]), Color(CYAN, 0.8 * a), 2.0)
	var eye := Vector2(0, -height * 0.7 + bob)
	draw_circle(eye, 9.0, Color(CYAN, 0.25 * a))
	draw_circle(eye, 4.0 + 2.0 * _focus, Color(CYAN, a))
	# Anillos de símbolos que giran (más rápido mientras pregunta).
	for ring in 2:
		var radius := 34.0 + ring * 16.0
		var count := 8 + ring * 4
		for k in count:
			var angle := _clock * (0.6 + 1.6 * _focus) * (1.0 if ring == 0 else -1.0) + k * TAU / count
			var p := eye + Vector2(cos(angle) * radius, sin(angle) * radius * 0.35)
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(CYAN, (0.3 + 0.5 * _focus) * a))
	draw_string(ThemeDB.fallback_font, Vector2(-70, -height - 18 + bob), title, HORIZONTAL_ALIGNMENT_CENTER, 140, 9, Color(CYAN, a))

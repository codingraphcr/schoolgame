@tool
class_name RoboticsStation
extends Interactable
## Una estación de la actividad de robótica del taller (laboratorio). En el Capítulo 1 está «en preparación» (con E,
## un comentario: se anuncia la actividad). Desde el paso STEP de QUEST (Capítulo 2) abre su desafío
## (RoboticsWindow). Resolverla deja la marca «robotica_<id>» y paga Ecos una sola vez; con las tres resueltas se
## completa el paso. Se puede volver a jugar cuando se quiera (sin pagar de nuevo).
## Con task_quest / task_step es la estación de un encargo aparte (p. ej. la tarea «El robot que no obedece»): se usa
## solo en ese paso (y después, para volver a jugarla) y al resolverla completa ese paso.
## El origen es el piso, frente a la mesa. Se ve también en el editor.

signal station_solved(id: StringName)

const QUEST := &"el_lenguaje_de_las_maquinas"
const STEP := &"taller_robotica"
## Las tres estaciones de la actividad (para saber cuándo están todas).
const ALL: Array[StringName] = [&"clasificador", &"cinta", &"asistente"]
const CYAN := Color("3ef2ff")
const WOOD := Color("6a4a32")

@export var challenge: RoboticsChallenge
## Lo que dice Kai antes de la actividad (Capítulo 1).
@export var preparing_dialogue: Dialogue
## Cartel sobre la mesa.
@export var sign_text := "ESTACIÓN"
## El fondo del cuarto ya trae la mesa, la máquina y el cartel (el taller de Ariel): solo se escribe el cartel
## (sign_rect), se marca al abrirse y se tapa la máquina mientras la arman (cover_rect).
@export var painted := false
@export var sign_rect := Rect2(-41, -80, 82, 13)
@export var cover_rect := Rect2(-31, -64, 62, 28)
## Encargo propio (vacío = la actividad de robótica del Capítulo 2).
@export var task_quest: StringName = &""
@export var task_step: StringName = &""

var _clock := 0.0


func _init() -> void:
	prompt_offset = Vector2(-50, -96)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(64, 56)
	shape.shape = rect
	shape.position = Vector2(0, -28)
	add_child(shape)
	super()
	interacted.connect(_on_interacted)


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()
	if Engine.is_editor_hint():
		return
	prompt_text = "E: usar la estación" if is_open() else "E: mirar el proyecto"
	super(delta)


## Si la actividad ya empezó (desde el paso STEP, y para siempre después; o desde el paso del encargo).
func is_open() -> bool:
	if challenge == null:
		return false
	var state := get_node("/root/GameState")
	if task_quest != &"":
		return state.has_reached_step(task_quest, task_step)
	return state.has_reached_step(QUEST, STEP)


func is_done() -> bool:
	return challenge != null and get_node("/root/GameState").has_flag(flag_of(challenge.id))


static func flag_of(station_id: StringName) -> StringName:
	return StringName("robotica_%s" % station_id)


static func flags() -> Array[StringName]:
	var result: Array[StringName] = []
	for station_id in ALL:
		result.append(flag_of(station_id))
	return result


static func solved_count(state: Node) -> int:
	return ClueTracker.count(state, flags())


## Registra una estación resuelta (Ecos una vez); con todas, se completa el paso.
static func register(state: Node, economy: Node, robotics: RoboticsChallenge) -> void:
	economy.claim_reward(StringName("robotica:%s" % robotics.id), economy.reward_for(EconomyConfig.Source.CHALLENGE, robotics.ecos_reward))
	ClueTracker.register(state, flag_of(robotics.id), flags(), ALL.size(), QUEST, STEP)


func _on_interacted(player: Player) -> void:
	busy = true
	if not is_open():
		await StoryHelper.say(self, preparing_dialogue)
		busy = false
		return
	player.controls_locked = true
	player.velocity.x = 0.0
	var window := RoboticsWindow.open(self, challenge)
	var solved: bool = await window.closed
	player.controls_locked = false
	if solved and task_quest != &"":
		var economy := get_node("/root/Economy")
		economy.claim_reward(StringName("robotica:%s" % challenge.id), economy.reward_for(EconomyConfig.Source.CHALLENGE, challenge.ecos_reward))
		get_node("/root/GameState").set_flag(flag_of(challenge.id))
		get_node("/root/GameState").complete_step(task_quest, task_step)
	elif solved:
		register(get_node("/root/GameState"), get_node("/root/Economy"), challenge)
		station_solved.emit(challenge.id)
	await get_tree().process_frame
	busy = false


func _draw() -> void:
	var done := not Engine.is_editor_hint() and is_done()
	var open := Engine.is_editor_hint() or is_open()
	if painted:
		_draw_painted(open, done)
		return
	# Mesa con el cartel.
	draw_rect(Rect2(-34, -30, 68, 6), WOOD)
	draw_rect(Rect2(-30, -24, 4, 24), WOOD.darkened(0.2))
	draw_rect(Rect2(26, -24, 4, 24), WOOD.darkened(0.2))
	var sign_rect := Rect2(-44, -82, 88, 14)
	draw_rect(sign_rect, Color("1a2030"))
	draw_rect(sign_rect, CYAN if open else Color("5a6070"), false, 1.0)
	draw_string(ThemeDB.fallback_font, sign_rect.position + Vector2(0, 11), sign_text, HORIZONTAL_ALIGNMENT_CENTER, 88, 8,
		CYAN if open else Color("8a94a8"))
	if done:
		draw_string(ThemeDB.fallback_font, Vector2(24, -86), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("7ee08a"))
	var kind := challenge.kind if challenge else RoboticsChallenge.Kind.CONDICIONAL
	match kind:
		RoboticsChallenge.Kind.CONDICIONAL:
			# Cinta corta con un desvío a dos cajitas y un sensor.
			draw_rect(Rect2(-28, -40, 34, 6), Color("3a4152"))
			draw_line(Vector2(6, -37), Vector2(22, -50), Color("3a4152"), 4.0)
			draw_line(Vector2(6, -37), Vector2(22, -34), Color("3a4152"), 4.0)
			draw_rect(Rect2(20, -56, 10, 8), Color("4f81bd"))
			draw_rect(Rect2(20, -38, 10, 8), Color("9bbb59"))
			draw_rect(Rect2(-6, -54, 8, 10), Color("4a5470"))
			draw_circle(Vector2(-2, -50), 1.5, CYAN if open else Color("40404a"))
		RoboticsChallenge.Kind.CICLO:
			# Cinta larga con cajas que avanzan.
			draw_rect(Rect2(-32, -40, 64, 6), Color("3a4152"))
			for k in 3:
				var x := -28.0 + fmod(k * 22.0 + (_clock * 10.0 if open else 0.0), 56.0)
				draw_rect(Rect2(x, -50, 9, 9), Color("c8a060"))
		_:
			# El asistente: un robot con brazo.
			draw_rect(Rect2(-10, -52, 20, 18), Color("4a5470"))
			draw_circle(Vector2(-4, -45), 2.0, CYAN if open else Color("40404a"))
			draw_circle(Vector2(4, -45), 2.0, CYAN if open else Color("40404a"))
			var arm := sin(_clock * 2.0) * 4.0 if open else 0.0
			draw_line(Vector2(10, -44), Vector2(22, -50 + arm), Color("8a94a8"), 2.0)
			draw_rect(Rect2(-8, -34, 16, 4), Color("2a3040"))
	if not open:
		# Cubierta: todavía la están armando.
		draw_rect(Rect2(-32, -60, 64, 28), Color(0.85, 0.85, 0.9, 0.35))


## Con el fondo de Ariel: el texto del cartel dibujado (celeste al abrirse), el ✓ y la cubierta mientras la arman.
func _draw_painted(open: bool, done: bool) -> void:
	if open:
		draw_rect(sign_rect.grow(1.0), Color(CYAN, 0.8), false, 1.0)
	draw_string(ThemeDB.fallback_font, sign_rect.position + Vector2(0, sign_rect.size.y - 3.0), sign_text, HORIZONTAL_ALIGNMENT_CENTER,
		sign_rect.size.x, 8, CYAN if open else Color("a9b4cc"))
	if done:
		draw_string(ThemeDB.fallback_font, Vector2(sign_rect.end.x - 4.0, sign_rect.position.y - 2.0), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			Color("7ee08a"))
	if not open:
		# Cubierta: todavía la están armando.
		draw_rect(cover_rect, Color(0.85, 0.85, 0.9, 0.35))

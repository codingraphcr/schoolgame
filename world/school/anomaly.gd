@tool
class_name Anomaly
extends Interactable
## Una anomalía del taller antes de Bucle (Capítulo 2, paso STEP de QUEST): algo que repite su tarea sin parar (un
## robot que mueve una caja de ida y vuelta, un brazo que repite el mismo gesto, un mensaje que vuelve a aparecer, una
## puerta que abre y cierra). Se ve a simple vista; con la Visión Digital aparece además el rastro de datos (un ↻ que
## gira y un hilo hacia el laboratorio). Aparecen de a una (order): la siguiente empieza cuando se investigó la
## anterior. Con E, sin Visión, Kai solo ve una falla común (normal_dialogue); con Visión, la investiga
## (vision_dialogue) y queda la marca «anomalia_<id>». Con todas investigadas se completa el paso. Fuera de ese
## momento son parte del taller, quietas (el robot, el brazo, la pantalla, la puerta de la bodega).
## El origen es el piso. Se ve también en el editor.

const QUEST := &"el_lenguaje_de_las_maquinas"
const STEP := &"investigar_anomalias"
## Todas, en el orden en que aparecen.
const ALL: Array[StringName] = [&"robot", &"brazo", &"mensaje", &"puerta"]
const CYAN := Color("3ef2ff")
const MAG := Color("ff3ea5")

enum Kind { ROBOT, BRAZO, MENSAJE, PUERTA }

@export var id: StringName = &""
@export var kind := Kind.ROBOT
@export var normal_dialogue: Dialogue
@export var vision_dialogue: Dialogue
## Lo que dice el mensaje repetido (solo MENSAJE).
@export var message := "TAREA 7: REPETIR"

@export_group("Dibujo del fondo")
## El fondo del cuarto ya trae el objeto (el taller de Ariel): no se dibuja por código. El robot y el brazo vienen
## recortados del fondo (art, al doble; art_offset: su esquina desde el origen) y se mueven; la puerta también
## (solo se dibuja al abrirse); el mensaje se escribe en la pantalla dibujada (screen).
@export var painted := false
@export var art: Texture2D
@export var art_offset := Vector2.ZERO
## Brazo: el punto sobre el que gira (desde el origen).
@export var art_pivot := Vector2.ZERO
@export var screen := Rect2()

var _clock := 0.0
var _canvas: VectorCanvas


func _init() -> void:
	prompt_offset = Vector2(-50, -100)


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint_trace
	_canvas.animated = true
	if Engine.is_editor_hint():
		add_child(_canvas)
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 56)
	shape.shape = rect
	shape.position = Vector2(0, -28)
	add_child(shape)
	super()
	var layer := _digital_layer()
	if layer:
		layer.add_child.call_deferred(_canvas)
		_canvas.set_deferred("position", global_position)
	else:
		add_child(_canvas)
	interacted.connect(_on_interacted)


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()
	if Engine.is_editor_hint():
		return
	var vision := get_node("/root/DigitalVision")
	var active := is_active()
	_canvas.visible = active and vision.blend > 0.001
	_canvas.modulate.a = vision.blend * vision.warning_factor()
	enabled = active
	prompt_text = "E: investigar" if vision.is_active() else "E: mirar"
	# Con la Visión el aviso se dibuja junto al rastro (nítido sobre la oscuridad); sin ella, el aviso normal.
	_prompt.self_modulate.a = 0.0 if vision.is_active() else 1.0
	super(delta)


## Si está fallando ahora: durante el paso, en su turno (las anteriores ya investigadas) y sin investigar todavía.
func is_active() -> bool:
	var state := get_node("/root/GameState")
	if state.get_current_step(QUEST) != STEP or state.has_flag(flag_of(id)):
		return false
	var index := ALL.find(id)
	return index >= 0 and ClueTracker.count(state, flags()) >= index


static func flag_of(anomaly_id: StringName) -> StringName:
	return StringName("anomalia_%s" % anomaly_id)


static func flags() -> Array[StringName]:
	var result: Array[StringName] = []
	for anomaly_id in ALL:
		result.append(flag_of(anomaly_id))
	return result


## Registra una anomalía investigada; con todas, se completa el paso.
static func register(state: Node, anomaly_id: StringName) -> void:
	ClueTracker.register(state, flag_of(anomaly_id), flags(), ALL.size(), QUEST, STEP)


func _on_interacted(_player: Player) -> void:
	busy = true
	if get_node("/root/DigitalVision").is_active():
		await StoryHelper.say(self, vision_dialogue)
		register(get_node("/root/GameState"), id)
	else:
		await StoryHelper.say(self, normal_dialogue)
	await get_tree().process_frame
	busy = false


func _exit_tree() -> void:
	if _canvas and _canvas.get_parent() != self:
		_canvas.queue_free()


func _digital_layer() -> Node:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node.get_node_or_null("DigitalLayer") if node else null


## Lo que se ve a simple vista: la falla que se repite (quieta cuando ya se investigó).
func _draw() -> void:
	var running := Engine.is_editor_hint() or is_active()
	var t := _clock if running else 0.0
	if painted:
		_draw_painted(running, t)
		return
	match kind:
		Kind.ROBOT:
			# Un robot de cuatro ruedas lleva una caja de ida y vuelta, de ida y vuelta...
			var x := sin(t * 2.4) * 22.0
			draw_rect(Rect2(x - 12, -16, 24, 12), Color("4a5470"))
			draw_circle(Vector2(x - 8, -3), 3.0, Color("2a2e38"))
			draw_circle(Vector2(x + 8, -3), 3.0, Color("2a2e38"))
			draw_rect(Rect2(x - 6, -26, 12, 10), Color("c8a060"))
			draw_circle(Vector2(x + 9, -12), 1.5, CYAN if running else Color("40404a"))
		Kind.BRAZO:
			# Un brazo robótico en la mesa: baja, toma, sube, suelta... siempre el mismo gesto.
			draw_rect(Rect2(-34, -30, 68, 6), Color("6a4a32"))
			draw_rect(Rect2(-8, -40, 16, 10), Color("4a5470"))
			var angle := -0.9 + sin(t * 3.0) * 0.7
			var elbow := Vector2(0, -40) + Vector2(cos(angle), sin(angle)) * 22.0
			var hand := elbow + Vector2(cos(angle + 1.2), sin(angle + 1.2)) * 16.0
			draw_line(Vector2(0, -40), elbow, Color("8a94a8"), 4.0)
			draw_line(elbow, hand, Color("8a94a8"), 3.0)
			draw_circle(hand, 3.0, Color("f2c14e"))
		Kind.MENSAJE:
			# Una pantalla en la pared: el mismo mensaje aparece, se borra y vuelve a aparecer.
			var screen := Rect2(-34, -112, 68, 40)
			draw_rect(screen, Color("101824"))
			draw_rect(screen, Color("8a94a8"), false, 1.0)
			if not running:
				draw_string(ThemeDB.fallback_font, screen.position + Vector2(4, 12), "TALLER · LISTO", HORIZONTAL_ALIGNMENT_LEFT, 60, 7, Color("5a8a6a"))
			elif fmod(t, 1.4) < 1.0:
				var lines := 1 + int(fmod(t, 4.2) / 1.4)
				for k in lines:
					draw_string(ThemeDB.fallback_font, screen.position + Vector2(4, 12 + k * 10), message, HORIZONTAL_ALIGNMENT_LEFT, 60, 7, Color("7ee08a"))
			draw_rect(Rect2(-3, -72, 6, 72), Color("3a3f4a"))
		Kind.PUERTA:
			# La puerta de la bodega abre y cierra, abre y cierra.
			var open := (0.5 + 0.5 * sin(t * 3.4)) if running else 0.0
			draw_rect(Rect2(-22, -96, 44, 96), Color("1a1e28"))
			draw_rect(Rect2(-22, -96, 44 * (1.0 - open * 0.85), 96), Color("5a6474"))
			draw_rect(Rect2(-22, -96, 44, 96), Color("2a2e38"), false, 2.0)
			draw_string(ThemeDB.fallback_font, Vector2(-30, -102), "BODEGA", HORIZONTAL_ALIGNMENT_CENTER, 60, 8, Color("8a94a8"))


## Con el fondo de Ariel: el objeto recortado se mueve (y la puerta se abre) solo mientras la anomalía está activa.
func _draw_painted(running: bool, t: float) -> void:
	match kind:
		Kind.ROBOT:
			if art:
				draw_set_transform(art_offset + Vector2(sin(t * 2.4) * 22.0 if running else 0.0, 0.0), 0.0, Vector2.ONE * 0.5)
				draw_texture(art, Vector2.ZERO)
		Kind.BRAZO:
			if art:
				draw_set_transform(art_pivot, sin(t * 3.0) * 0.35 if running else 0.0, Vector2.ONE * 0.5)
				draw_texture(art, (art_offset - art_pivot) * 2.0)
		Kind.PUERTA:
			if art and running:
				var open := 0.5 + 0.5 * sin(t * 3.4)
				draw_rect(Rect2(art_offset, art.get_size() * 0.5), Color("0c0f1a"))
				draw_set_transform(art_offset, 0.0, Vector2(0.5 * (1.0 - open * 0.85), 0.5))
				draw_texture(art, Vector2.ZERO)
		Kind.MENSAJE:
			var font := ThemeDB.fallback_font
			if not running:
				draw_string(font, screen.position + Vector2(3, 10), "TALLER · LISTO", HORIZONTAL_ALIGNMENT_LEFT, screen.size.x - 4, 6, Color("5fd6c8"))
				draw_string(font, screen.position + Vector2(3, 19), ">_", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("5fd6c8"))
			elif fmod(t, 1.4) < 1.0:
				var lines := 1 + int(fmod(t, 4.2) / 1.4)
				for k in lines:
					draw_string(font, screen.position + Vector2(3, 10 + k * 8), message, HORIZONTAL_ALIGNMENT_LEFT, screen.size.x - 4, 6, Color("7ee08a"))
	draw_set_transform(Vector2.ZERO)


## Lo que se ve con la Visión: el ↻ que gira sobre la falla y un hilo de datos hacia el laboratorio (izquierda).
func _paint_trace(c: VectorCanvas, t: float) -> void:
	var center := Vector2(0, -70)
	c.glow(center, 36.0, Color(MAG, 0.22))
	var start := t * 4.0
	c.draw_arc(center, 12.0, start, start + TAU * 0.8, 20, MAG, 2.0)
	var tip := center + Vector2(cos(start + TAU * 0.8), sin(start + TAU * 0.8)) * 12.0
	c.draw_circle(tip, 3.0, MAG)
	for k in 6:
		var x := -fmod(t * 60.0 + k * 40.0, 240.0)
		c.draw_circle(Vector2(x, -60 + sin(x * 0.05) * 6.0), 1.6, Color(CYAN, 0.7))
	if not Engine.is_editor_hint() and _can_interact():
		c.crisp_text(Vector2(-60, -104), prompt_text, 7, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 120)

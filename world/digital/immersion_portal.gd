@tool
class_name ImmersionPortal
extends Interactable
## Conexión de Inmersión Digital en un monitor (Capítulo 1). Solo se ve y se usa con la Visión Digital
## activa: brilla sobre la pantalla y, con E, Kai la atraviesa (DigitalDive) y entra al entorno digital
## (target_scene / target_entry; si la sala está en el mapa, door_id manda).
##
## La primera vez (sin la Inmersión Digital) hay una pequeña secuencia: first_dialogue, Kai entra, se
## desbloquea la habilidad para siempre (GameState.unlock_immersion) y la pantalla de transición dice
## «INMERSIÓN DIGITAL». Las siguientes veces solo hay transición. La pantalla de transición es la
## LoadingScreen de siempre: se cierra sola cuando Kai se materializa en la entrada de destino
## (RoomEntry con arrival_effect "materialize").
## Su dibujo va en la capa digital de la sala (como HiddenRelic). El origen es el centro de la pantalla.

signal entered(first_time: bool)

const CYAN := Color("3ef2ff")
const VIOLET := Color("a77bff")
const FIRST_TITLE := "INMERSIÓN DIGITAL"
const FIRST_LINES: PackedStringArray = ["Nueva habilidad: Inmersión Digital", "Siguiendo la conexión...", "Entrando al sistema..."]

## Puerta de la ficha de la sala (si la sala está en el mapa); si no, target_scene y target_entry.
@export var door_id: StringName = &""
@export_file("*.tscn") var target_scene := ""
@export var target_entry: StringName = &""
## Tamaño de la pantalla del monitor (el brillo y el área de uso).
@export var screen_size := Vector2(40, 28)
## Lo que pasa la primera vez, antes de entrar (vacío = nada).
@export var first_dialogue: Dialogue
## Pantalla de transición de las veces siguientes.
@export var title := "CONECTANDO..."
@export var lines: PackedStringArray = ["Conexión encontrada", "Entrando al sistema..."]
## Segundos de la pantalla de transición.
@export var transition_seconds := 2.4
## La conexión solo aparece cuando la historia llega a ese paso (vacío = siempre que haya Visión).
@export var requires_quest: StringName = &""
@export var requires_step: StringName = &""

var _canvas: VectorCanvas
var _using := false


func _init() -> void:
	prompt_text = "E: entrar"
	prompt_offset = Vector2(-30, -40)


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	if Engine.is_editor_hint():
		add_child(_canvas)
		return
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(maxf(screen_size.x, 40.0), 64.0)
	shape.shape = rect
	shape.position = Vector2(0, 20)
	add_child(shape)
	super()
	_prompt.self_modulate.a = 0.0
	_canvas.add_to_group(&"digital_only")
	_canvas.visible = _vision().is_active()
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
	enabled = not _using and _vision().is_active() and is_available()
	super(delta)


## Si la historia ya permite usar esta conexión.
func is_available() -> bool:
	return requires_quest == &"" or get_node("/root/GameState").has_reached_step(requires_quest, requires_step)


## Si Kai ya tiene la Inmersión Digital.
func is_known() -> bool:
	return get_node("/root/GameState").immersion_unlocked


## A dónde lleva: { "scene", "entry", "room" }.
func resolve() -> Dictionary:
	return RoomExit.destination_of(self, door_id, target_scene, target_entry)


func _on_interacted(player: Player) -> void:
	var target := resolve()
	if String(target["scene"]).is_empty():
		return
	var world := get_node_or_null("/root/World")
	if world and target["room"] != &"":
		var reason: String = world.lock_reason(target["room"])
		if not reason.is_empty():
			get_tree().call_group(&"toast", &"show_message", reason, 2.5)
			return
	_using = true
	busy = true
	player.controls_locked = true
	player.velocity = Vector2.ZERO
	var first_time := not is_known()
	if first_time and first_dialogue:
		var box := DialogueBox.find(self)
		if box:
			await box.play(first_dialogue)
	var room := _room()
	await DigitalDive.dive(player, global_position, room.camera if room else null)
	if first_time:
		get_node("/root/GameState").unlock_immersion()
	entered.emit(first_time)
	# La pantalla de transición sigue puesta al cambiar de sala; la cierra la llegada (materialize).
	LoadingScreen.show_loading(self, FIRST_TITLE if first_time else title, FIRST_LINES if first_time else lines, transition_seconds)
	await get_tree().create_timer(transition_seconds).timeout
	get_node("/root/SceneManager").go_to_room(target["scene"], target["entry"], target["room"])


func _exit_tree() -> void:
	if _canvas and _canvas.get_parent() != self:
		_canvas.queue_free()


func _vision() -> Node:
	return get_node("/root/DigitalVision")


func _room() -> Room:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node as Room


func _digital_layer() -> Node:
	var room := _room()
	return room.get_node_or_null("DigitalLayer") if room else null


## La conexión: la pantalla brilla con marcos que se encogen hacia adentro y datos que entran en ella.
func _paint(c: VectorCanvas, t: float) -> void:
	if not Engine.is_editor_hint() and (_using or not is_available()):
		return
	var pulse := 0.5 + 0.5 * sin(t * 3.0)
	var screen := Rect2(-screen_size / 2.0, screen_size)
	c.glow(Vector2.ZERO, screen_size.x * 0.9 + 4.0 * pulse, Color(CYAN, 0.22 + 0.12 * pulse))
	c.draw_rect(screen, Color(0.05, 0.15, 0.25, 0.85))
	for k in 3:
		var phase := fmod(t * 0.8 + k / 3.0, 1.0)
		var frame := screen.grow(10.0 * (1.0 - phase))
		c.draw_rect(frame, Color(CYAN if k % 2 == 0 else VIOLET, 0.9 * phase), false, 1.0)
	# Datos que entran a la pantalla desde los costados.
	for k in 8:
		var side := -1.0 if k % 2 == 0 else 1.0
		var progress := fmod(t * 0.7 + k * 0.137, 1.0)
		var start := Vector2(side * (screen_size.x / 2.0 + 30.0), -10.0 + (k % 4) * 7.0)
		var point := start.lerp(Vector2(0, start.y * 0.3), progress)
		c.draw_rect(Rect2(point, Vector2(2, 2)), Color(CYAN, 1.0 - progress))
	c.draw_circle(Vector2.ZERO, 2.5 + pulse, Color.WHITE)
	if not Engine.is_editor_hint() and _can_interact():
		c.crisp_text(Vector2(-50, -screen_size.y / 2.0 - 16.0), prompt_text, 7, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 100)

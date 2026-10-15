class_name KaiComputer
extends Node2D
## La computadora del escritorio de Kai: la pantalla brilla (con un aviso si hay mensajes sin leer) y
## con E abre KaiComputerWindow (mensajes, proyectos y notas del juego). Durante la noche de la
## Resonancia Digital la pantalla se enciende sola (flicker). El origen es la superficie del escritorio,
## al medio del monitor.

const CASE := Color("2a3040")
const SCREEN_OFF := Color("0e141e")
const SCREEN_ON := Color("1e4a7a")
const CYAN := Color("3ef2ff")

var interactable: Interactable
## 0 = normal; > 0 = la pantalla parpadea sola (Resonancia Digital).
var flicker := 0.0:
	set(value):
		flicker = value
		queue_redraw()
var _time := 0.0
var _unread := false
var _unread_check := 0.0


func _ready() -> void:
	interactable = Interactable.new()
	interactable.prompt_text = "E: usar la computadora"
	interactable.prompt_offset = Vector2(-56, -62)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 56)
	shape.shape = rect
	shape.position = Vector2(0, 12)
	interactable.add_child(shape)
	add_child(interactable)
	interactable.interacted.connect(func(_player: Player) -> void: use())


func _process(delta: float) -> void:
	_time += delta
	_unread_check -= delta
	if _unread_check <= 0.0:
		_unread_check = 1.0
		_unread = has_unread()
	queue_redraw()


func use() -> KaiComputerWindow:
	interactable.busy = true
	var window := KaiComputerWindow.open(self)
	window.closed.connect(func() -> void: interactable.busy = false)
	return window


func has_unread() -> bool:
	var state := get_node("/root/GameState")
	for entry in ComputerEntry.visible_in(ComputerEntry.Section.MENSAJES, state):
		if not state.has_flag(StringName("pc_leido_%s" % entry.resource_path.get_file().get_basename())):
			return true
	return false


func _draw() -> void:
	draw_rect(Rect2(-4, -6, 8, 6), CASE)  # Pie
	draw_rect(Rect2(-12, -2, 24, 2), CASE)
	var monitor := Rect2(-20, -34, 40, 28)
	draw_rect(monitor, CASE)
	var screen := monitor.grow(-3.0)
	if flicker > 0.0:
		var on := sin(_time * 40.0) > -0.2
		draw_rect(screen, Color(0.2, 0.95, 1.0, 0.85) if on else SCREEN_OFF)
		if on:
			for k in 4:
				draw_rect(Rect2(screen.position + Vector2(2, 3 + k * 5), Vector2(fmod(_time * 90.0 + k * 13.0, screen.size.x - 4.0), 2)), Color("0e141e"))
		draw_circle(screen.get_center(), 30.0, Color(0.24, 0.95, 1.0, 0.08 * flicker))
		return
	draw_rect(screen, SCREEN_ON)
	draw_rect(Rect2(screen.position + Vector2(2, 2), Vector2(screen.size.x - 4, 3)), Color("2a6aaa"))
	for k in 3:
		draw_rect(Rect2(screen.position + Vector2(3, 8 + k * 4), Vector2(14 + k * 3, 2)), Color("6aa0d0"))
	if _unread and fmod(_time, 1.2) < 0.7:
		draw_circle(Vector2(monitor.end.x - 3, monitor.position.y + 3), 3.0, Color("ff4a6a"))
	# Teclado.
	draw_rect(Rect2(-16, -2, 32, 2), Color("3a4258"))

class_name CatalogScene
extends Interactable
## Capítulo 1, nivel 1, escena 1.4 (biblioteca): Glitch dejó abierto el archivo privado de un
## estudiante en la computadora pública del catálogo. Con E: el diálogo, el desafío «Un archivo que no
## es tuyo», y los hermanos escapan hacia la zona técnica. Paso biblioteca → pedir_permiso.
## El origen es el centro de la pantalla del catálogo.

const QUEST := &"una_clase_diferente"
const DONE_FLAG := &"cap1_archivo_protegido"

@export var chip: SiblingActor
@export var glitch: SiblingActor
@export var challenge: ChoiceChallenge
@export var catalog_dialogue: Dialogue
@export var resolved_dialogue: Dialogue
## Por dónde escapan (hacia las escaleras).
@export var exit_point := Vector2(-30, 290)

var _time := 0.0


func _init() -> void:
	prompt_text = "E: revisar el catálogo"
	prompt_offset = Vector2(-44, -40)


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60, 70)
	shape.shape = rect
	shape.position = Vector2(0, 30)
	add_child(shape)
	super()
	interacted.connect(_on_interacted)
	var waiting: bool = _state().get_current_step(QUEST) == &"biblioteca"
	for actor in [chip, glitch]:
		if waiting:
			actor.appear()
		else:
			actor.vanish()


func _process(delta: float) -> void:
	_time += delta
	enabled = _state().get_current_step(QUEST) == &"biblioteca"
	queue_redraw()
	super(delta)


func _on_interacted(_player: Player) -> void:
	busy = true
	await StoryHelper.say(self, catalog_dialogue)
	await StoryHelper.choose_until_done(self, challenge)
	_state().set_flag(DONE_FLAG)
	await StoryHelper.say(self, resolved_dialogue)
	for actor in [chip, glitch]:
		actor.run_to(exit_point, 240.0)
	await get_tree().create_timer(1.0, false, true).timeout
	chip.vanish()
	glitch.vanish()
	_state().complete_step(QUEST, &"biblioteca")
	busy = false


## La pantalla del catálogo con el archivo privado a la vista (mientras haga falta).
func _draw() -> void:
	if _state().has_flag(DONE_FLAG) or _state().get_current_step(QUEST) != &"biblioteca":
		return
	var screen := Rect2(-14, -8, 28, 18)
	draw_rect(screen, Color(0.8, 0.85, 0.95))
	draw_rect(Rect2(screen.position, Vector2(screen.size.x, 4)), Color("b8434a"))
	for k in 3:
		draw_rect(Rect2(screen.position + Vector2(3, 7 + k * 3), Vector2(14 + (k % 2) * 6, 1)), Color(0.2, 0.2, 0.3))
	if int(_time * 2.0) % 2 == 0:
		draw_string(ThemeDB.fallback_font, Vector2(-28, -14), "PRIVADO", HORIZONTAL_ALIGNMENT_CENTER, 56, 8, Color("ff6a7a"))


func _state() -> Node:
	return get_node("/root/GameState")

class_name StoryPresence
extends Node
## Muestra u oculta a su padre (un personaje, un objeto) según en qué parte de la historia está la
## partida. Ej.: el profesor está en el laboratorio solo durante la clase del Capítulo 1.
##
## Se ve si: (show_quest vacío o ya se llegó a show_quest/show_step) y (hide_quest vacío o todavía no
## se llegó a hide_quest/hide_step) — o si return_quest ya se completó (vuelve a aparecer) —, y siempre
## que no se vea ninguno de los personajes de hide_while.
## Oculto, el padre no se ve ni procesa (no se puede hablar con él).

@export var show_quest: StringName = &""
@export var show_step: StringName = &""
@export var hide_quest: StringName = &""
@export var hide_step: StringName = &""
## Al completar esta misión vuelve a verse aunque se haya ocultado.
@export var return_quest: StringName = &""
## También se oculta si la partida tiene esta marca (p. ej. &"capitulo_3": ya pasaron esos días).
@export var hide_flag: StringName = &""
## Además se oculta mientras alguna de estas otras StoryPresence muestra a su personaje (p. ej. los
## estudiantes del recreo del Salón 3, mientras están la clase o el profesor del capítulo 2).
@export var hide_while: Array[NodePath] = []

## Último estado aplicado (−1 = ninguno todavía).
var _applied := -1


func _ready() -> void:
	_refresh.call_deferred()


func _process(_delta: float) -> void:
	_refresh()


func is_present() -> bool:
	for path in hide_while:
		var other := get_node_or_null(path) as StoryPresence
		if other and other.is_present():
			return false
	var state := get_node("/root/GameState")
	if return_quest != &"" and state.is_quest_completed(return_quest):
		return true
	var shown: bool = show_quest == &"" or state.has_reached_step(show_quest, show_step)
	var hidden: bool = (hide_quest != &"" and state.has_reached_step(hide_quest, hide_step)) or (hide_flag != &"" and state.has_flag(hide_flag))
	return shown and not hidden


func _refresh() -> void:
	if not is_inside_tree():
		return  # La sala se cerró antes de este refresco (se llamó con call_deferred).
	var present := is_present()
	if int(present) == _applied:
		return
	_applied = int(present)
	var parent := get_parent()
	if parent is CanvasItem:
		(parent as CanvasItem).visible = present
	for child in parent.get_children():
		if child != self:
			child.process_mode = Node.PROCESS_MODE_INHERIT if present else Node.PROCESS_MODE_DISABLED
	if parent.has_method(&"set_process"):
		parent.set_process(present)

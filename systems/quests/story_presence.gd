class_name StoryPresence
extends Node
## Muestra u oculta a su padre (un personaje, un objeto) según en qué parte de la historia está la
## partida. Ej.: el profesor está en el laboratorio solo durante la clase del Capítulo 1.
##
## Se ve si: (show_quest vacío o ya se llegó a show_quest/show_step) y (hide_quest vacío o todavía no
## se llegó a hide_quest/hide_step) — o si return_quest ya se completó (vuelve a aparecer).
## Oculto, el padre no se ve ni procesa (no se puede hablar con él).

@export var show_quest: StringName = &""
@export var show_step: StringName = &""
@export var hide_quest: StringName = &""
@export var hide_step: StringName = &""
## Al completar esta misión vuelve a verse aunque se haya ocultado.
@export var return_quest: StringName = &""

## Último estado aplicado (−1 = ninguno todavía).
var _applied := -1


func _ready() -> void:
	_refresh.call_deferred()


func _process(_delta: float) -> void:
	_refresh()


func is_present() -> bool:
	var state := get_node("/root/GameState")
	if return_quest != &"" and state.is_quest_completed(return_quest):
		return true
	var shown: bool = show_quest == &"" or state.has_reached_step(show_quest, show_step)
	var hidden: bool = hide_quest != &"" and state.has_reached_step(hide_quest, hide_step)
	return shown and not hidden


func _refresh() -> void:
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

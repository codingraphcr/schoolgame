class_name StoryHelper
extends RefCounted
## Ayudas para las escenas de la historia.


## Reproduce un diálogo con Kai quieto (si no hay caja de diálogo o diálogo, no hace nada).
static func say(from: Node, dialogue: Dialogue) -> void:
	if dialogue == null:
		return
	var box := DialogueBox.find(from)
	if box == null:
		return
	var player := room_player(from)
	if player:
		player.controls_locked = true
		player.velocity.x = 0.0
	await box.play(dialogue)
	if player:
		player.controls_locked = false


## Abre un desafío de elección hasta que se complete (si se cierra sin terminar, se vuelve a abrir).
static func choose_until_done(from: Node, challenge: ChoiceChallenge) -> void:
	var completed := false
	while not completed:
		var window := ChoiceWindow.open(from, challenge)
		completed = await window.closed
		if not completed:
			await from.get_tree().create_timer(0.3).timeout


## Kai (el jugador de la sala donde está node), o null.
static func room_player(node: Node) -> Player:
	var current := node
	while current and not current is Room:
		current = current.get_parent()
	if current:
		return (current as Room).player
	return node.get_tree().get_first_node_in_group(&"player") as Player

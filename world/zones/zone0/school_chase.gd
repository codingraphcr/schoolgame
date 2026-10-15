class_name SchoolChase
extends Node
## Persecución larga de Chip y Glitch por el pasillo del segundo piso (Capítulo 1, nivel 1). Los hermanos
## van delante por points y en cada punto hacen su acción (actions, una por punto) cuando Kai se acerca:
##   ""                 nada: siguen corriendo.
##   "estante:N"        Chip tira la estantería N (cae hacia Kai y queda como obstáculo).
##   "caja" / "cajas"   Glitch tira una caja (o dos) que ruedan hacia Kai.
##   "casi"             esperan hasta que Kai casi los toca: «¡Te tengo!» / «¡Ups, casi!» y se escapan rápido.
##   "dice:chip:texto"  / "dice:glitch:texto" / "dice:kai:texto": un globo (no quita el control).
## Varias acciones en un punto se separan con «;». Al llegar al último punto desaparecen (siguieron a la
## sala siguiente). Solo mientras la misión está en quest_id / step_id. Todo con la física.

signal finished

@export var quest_id: StringName = &"una_clase_diferente"
@export var step_id: StringName = &"seguir_criaturas"
@export var chip: SiblingActor
@export var glitch: SiblingActor
@export var points: Array[Vector2] = []
@export var actions: PackedStringArray = []
@export var shelves: Array[FallingShelf] = []
## Distancia a la que reaccionan (y la de «casi»).
@export var trigger_distance := 170.0
@export var catch_distance := 48.0
@export var run_speed := 170.0
@export var dash_speed := 340.0

var index := 0
var near_catches := 0
var boxes_thrown := 0
var _active := false
var _moving := false


func _ready() -> void:
	chip.vanish()
	glitch.vanish()


func is_done() -> bool:
	return index >= points.size()


func _physics_process(_delta: float) -> void:
	var on_step: bool = get_node("/root/GameState").get_current_step(quest_id) == step_id
	if not on_step:
		if _active:
			_active = false
			chip.vanish()
			glitch.vanish()
		return
	if not _active and index == 0 and not points.is_empty():
		_active = true
		glitch.position = points[0] + Vector2(-26, 8)
		chip.position = points[0]
		glitch.appear()
		chip.appear()
	if _moving or is_done():
		return
	var player := StoryHelper.room_player(self)
	if player == null:
		return
	var rear := minf(glitch.global_position.x, chip.global_position.x)
	var distance := absf(player.global_position.x - rear)
	var action := actions[index] if index < actions.size() else ""
	if action.contains("casi"):
		if distance <= catch_distance:
			_advance(action)
	elif distance <= trigger_distance:
		_advance(action)


func _advance(action: String) -> void:
	_moving = true
	var dash := false
	for part in action.split(";", false):
		dash = await _do(part.strip_edges()) or dash
	index += 1
	if is_done():
		chip.run_to(chip.position + Vector2(60, 0), dash_speed)
		await glitch.run_to(glitch.position + Vector2(60, 0), dash_speed)
		chip.vanish()
		glitch.vanish()
		finished.emit()
		_moving = false
		return
	var speed := dash_speed if dash else run_speed
	chip.run_to(points[index], speed)
	await glitch.run_to(points[index] + Vector2(-26, 8), speed)
	_moving = false


## Hace una acción. Devuelve true si después se escapan a toda velocidad.
func _do(part: String) -> bool:
	if part.is_empty():
		return false
	var player := StoryHelper.room_player(self)
	if part.begins_with("estante:"):
		var shelf := shelves[int(part.get_slice(":", 1))]
		SpeechBark.say(chip, "¡Ahí va!", Vector2(0, -40), 1.4)
		shelf.knock()
		await _wait(0.2)
	elif part == "caja" or part == "cajas":
		for k in (2 if part == "cajas" else 1):
			_throw_box(player)
			await _wait(0.45)
	elif part == "casi":
		near_catches += 1
		if player:
			SpeechBark.say(player, "¡Te tengo!", Vector2(0, -36), 1.2)
		HitStop.freeze(chip, 0.12)
		SpeechBark.say(glitch, ["¡Ups, casi!", "¡Jijiji, no!", "¡Por un pelo!"][(near_catches - 1) % 3], Vector2(0, -40), 1.4)
		Sfx.play(&"dash", 1.2)
		return true
	elif part.begins_with("dice:"):
		var who := part.get_slice(":", 1)
		var text := part.substr(part.find(":", 5) + 1)
		var speaker: Node2D = chip if who == "chip" else (glitch if who == "glitch" else player)
		if speaker:
			SpeechBark.say(speaker, text, Vector2(0, -40), 1.4)
		await _wait(1.2)  # Que se lea antes del siguiente globo.
	return false


func _throw_box(player: Node2D) -> void:
	var box := ThrownBox.new()
	box.direction = -1.0 if player == null or player.global_position.x < glitch.global_position.x else 1.0
	box.floor_y = glitch.global_position.y
	glitch.face = box.direction
	get_parent().add_child(box)
	box.global_position = glitch.global_position + Vector2(box.direction * 12.0, -8.0)
	boxes_thrown += 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false, true).timeout

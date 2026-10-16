class_name IntroCinematic
extends Node2D
## La cinemática inicial (al empezar una partida nueva, antes del prólogo): Kai se despierta tarde, se prepara
## contra reloj, desayuna con sus papás, cruza el barrio y llega al colegio. Termina con el título del juego y
## pasa a la Entrada del colegio, donde el jugador toma el control («Habla con el profesor Alvarado»).
## Guion: docs/narrativa/capitulos/CINEMATICA_INICIAL.md.
##
## Todo pasa en esta escena (no es una sala: no se guarda ni se juega aquí). Los decorados son los del cuarto, la
## casa y la calle de Kai (los mismos scripts de arte), uno al lado del otro; entre escena y escena hay un corte a
## negro. Kai es el jugador de verdad (sus animaciones de caminar, correr y saltar) movido por script
## (Player.scripted_axis) y con los controles bloqueados; los papás son los de la casa.
## Los diálogos avanzan como siempre (E / Espacio). Esc dos veces: omitir (skip). quick (pruebas): todo más rápido.

signal finished

const DONE_FLAG := &"cinematica_inicial_vista"
const D := "res://data/dialogues/intro/intro_"
const FIRST_ROOM := "res://world/zones/zone0/entrada.tscn"
const FLOOR_Y := 304.0
## Dónde empieza cada decorado (x).
const BEDROOM_X := 0.0
const HOUSE_X := 2000.0
const STREET_X := 4000.0
## Encuadre de cine: el piso queda arriba de la caja de diálogo (debajo, una franja oscura) para que los personajes
## se vean mientras hablan.
const CAM_Y := 269.0
const CAM_BOTTOM := 449
## La cámara deja a Kai a la derecha del centro (a la izquierda está el retrato del diálogo).
const FRAME_OFFSET := 80.0

@export var kai: Player
@export var camera: Camera2D
@export var ambient: CanvasModulate
@export var bed: KaiBed
@export var alarm: IntroProp
@export var backpack: IntroProp
@export var notebook_a: IntroProp
@export var notebook_b: IntroProp
@export var breakfast: IntroProp
@export var lunchbox: IntroProp
@export var mom: FamilyMember
@export var dad: FamilyMember
@export var dog: IntroProp
@export var bus: IntroProp
@export var pulpero: Node2D
@export var friend: Node2D
@export var quick := false

var skipping := false
var done := false
## La cámara sigue a Kai (en x) mientras es true.
var follow := false

var _ui: CanvasLayer
var _box: DialogueBox
var _fade: ColorRect
var _caption: Label
var _skip_hint: Label
var _skip_armed := 0.0
var _ambience := 0.0


func _ready() -> void:
	_ui = $UI
	_box = $UI/DialogueBox
	_fade = $UI/Fade
	_caption = $UI/Caption
	_skip_hint = $UI/SkipHint
	_fade.color.a = 1.0
	# Nadie es interactivo en la cinemática (sin carteles de «E: ...»).
	for node in find_children("*", "Interactable", true, false):
		(node as Interactable).enabled = false
	kai.controls_locked = true
	_dress_shopkeeper.call_deferred()
	_run.call_deferred()


func _process(delta: float) -> void:
	if follow and kai:
		camera.position.x = lerpf(camera.position.x, kai.global_position.x - FRAME_OFFSET, clampf(delta * 4.0, 0.0, 1.0))
	if _skip_armed > 0.0:
		_skip_armed -= delta
		if _skip_armed <= 0.0:
			_skip_hint.text = "Esc: omitir"
	# Ambiente del barrio por la mañana: pájaros y, de vez en cuando, un carro lejos.
	_ambience -= delta
	if _ambience <= 0.0 and not done:
		_ambience = randf_range(2.5, 5.0)
		Sfx.play(&"bird_chirp" if randf() < 0.75 else &"car_far", randf_range(0.9, 1.15), -6.0)


func _unhandled_input(event: InputEvent) -> void:
	if done or not (event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel")):
		return
	get_viewport().set_input_as_handled()
	if _skip_armed > 0.0:
		skip()
	else:
		_skip_armed = 2.0
		_skip_hint.text = "Esc otra vez: omitir la cinemática"


## Omite la cinemática: corta todo y va a la Entrada del colegio (una sola vez).
func skip() -> void:
	if done:
		return
	skipping = true
	_box.close()
	for node in find_children("*", "IntroCloseup", true, false):
		node.queue_free()
	_finish()


# --- La secuencia ------------------------------------------------------------------------------------------------

func _run() -> void:
	Music.play(&"")
	if not await _bedroom():
		return
	if not await _getting_ready():
		return
	if not await _breakfast():
		return
	if not await _neighborhood():
		return
	if not await _school():
		return
	await _title()
	_finish()


## Escena 1: el despertar.
func _bedroom() -> bool:
	_set_stage(BEDROOM_X, 640.0, true)
	kai.visible = false
	kai.global_position = Vector2(BEDROOM_X + 520, FLOOR_Y)
	bed.sleeping = true
	camera.position = Vector2(BEDROOM_X + 330, CAM_Y)
	alarm.time_text = "6:00"
	if not await _fade_to(0.0, 1.6):
		return false
	_show_caption("Casa de Kai · 6:00 a. m.")
	if not await _wait(1.2):
		return false
	# La alarma escandalosa; la cámara se desplaza hasta la cama.
	alarm.active = true
	var ring := Sfx.play(&"alarm_ring")
	var pan := create_tween()
	pan.tween_property(camera, "position:x", BEDROOM_X + 450, 1.4 * _speed()).set_trans(Tween.TRANS_SINE)
	var panel := IntroCloseup.make(_ui, IntroCloseup.Kind.DESPERTADOR)
	panel.ringing = true
	await panel.pop_in()
	if not await _wait(1.4):
		return false
	_stop_sound(ring)
	alarm.active = false
	panel.ringing = false
	Sfx.play(&"click")
	SpeechBark.say(bed, "*clic*", Vector2(-20, -40), 0.8)
	await panel.pop_out()
	if not await _say("cinco_minutos"):
		return false
	# Corte rápido: las 6:35.
	if not await _cut(0.15):
		return false
	alarm.time_text = "6:35"
	var later := IntroCloseup.make(_ui, IntroCloseup.Kind.DESPERTADOR)
	later.time_text = "6:35"
	await later.pop_in(0.15)
	if not await _wait(1.0):
		return false
	await later.pop_out()
	if not await _say("mama_grita"):
		return false
	if not await _say("que"):
		return false
	# Se levanta de golpe.
	bed.sleeping = false
	kai.visible = true
	kai.face(-1)
	kai.velocity.y = -230.0
	Sfx.play(&"jump")
	if not await _wait(0.6):
		return false
	if not await _say("las_seis"):
		return false
	# Sale corriendo... y tropieza con la mochila.
	Music.play(&"intro_prisa")
	if not await _walk(backpack.global_position.x + 6.0, true):
		return false
	await _trip()
	if not await _say("estoy_bien"):
		return false
	await _stand_up()
	return true


## Escena 2: prepararse contra reloj (montaje con cortes).
func _getting_ready() -> bool:
	# El espejo y el mechón rebelde.
	if not await _cut(0.12):
		return false
	kai.global_position = Vector2(BEDROOM_X + 344, FLOOR_Y)
	kai.face(-1)
	camera.position = Vector2(BEDROOM_X + 300, CAM_Y)
	var mirror := IntroCloseup.make(_ui, IntroCloseup.Kind.ESPEJO)
	mirror.cowlick = 1.0
	await mirror.pop_in()
	for i in 2:
		if not await _wait(0.5):
			return false
		var flatten := create_tween()
		flatten.tween_property(mirror, "cowlick", 0.0, 0.35 * _speed())
		await flatten.finished
		if not await _wait(0.6):
			return false
		Sfx.play(&"boing")
		var spring := create_tween()
		spring.tween_property(mirror, "cowlick", 1.0, 0.12 * _speed()).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await spring.finished
	if not await _say("mechon"):
		return false
	await mirror.pop_out()
	# Los cuadernos.
	if not await _cut(0.12):
		return false
	kai.global_position = Vector2(BEDROOM_X + 262, FLOOR_Y)
	kai.face(-1)
	camera.position = Vector2(BEDROOM_X + 220, CAM_Y)
	if not await _wait(0.4):
		return false
	await _drop(notebook_a, BEDROOM_X + 236)
	if not await _wait(0.4):
		return false
	await _drop(notebook_b, BEDROOM_X + 222)
	if not await _say("cuadernos"):
		return false
	notebook_a.visible = false
	notebook_b.visible = false
	backpack.visible = false
	Sfx.play(&"zipper")
	SpeechBark.say(kai, "*ziiip*", Vector2(0, -50), 0.8)
	if not await _wait(0.8):
		return false
	# Mira hacia abajo: dos medias diferentes.
	var socks := IntroCloseup.make(_ui, IntroCloseup.Kind.MEDIAS)
	await socks.pop_in()
	if not await _wait(0.8):
		return false
	if not await _say("medias"):
		return false
	await socks.pop_out()
	# Sale corriendo hacia la cocina.
	follow = true
	if not await _walk(BEDROOM_X + 40.0, true):
		return false
	follow = false
	return true


## Escena 3: el desayuno en familia.
func _breakfast() -> bool:
	if not await _fade_to(1.0, 0.35):
		return false
	_set_stage(HOUSE_X, 1040.0, false)
	Music.play(&"intro_manana")
	kai.global_position = Vector2(HOUSE_X + 1000, FLOOR_Y)
	camera.position = Vector2(HOUSE_X + 600, CAM_Y)
	breakfast.visible = false
	_face(mom, -1)
	_face(dad, -1)
	if not await _fade_to(0.0, 0.4):
		return false
	if not await _walk(HOUSE_X + 604, true):
		return false
	kai.face(1)
	if not await _say("desayuno"):
		return false
	# La mamá le sirve el desayuno.
	if not await _member_walk(mom, HOUSE_X + 680):
		return false
	breakfast.visible = true
	Sfx.play(&"plate")
	if not await _member_walk(mom, HOUSE_X + 830):
		return false
	_face(mom, -1)
	# Desayuna a toda prisa.
	for i in 3:
		SpeechBark.say(kai, "*ñam*", Vector2(0, -50), 0.45)
		Sfx.play(&"gulp", randf_range(0.9, 1.15))
		if not await _wait(0.45):
			return false
	breakfast.visible = false
	if not await _say("papa_nota"):
		return false
	# El papá señala los pies; Kai mira hacia abajo. Pausa cómica.
	SpeechBark.say(dad, "↓", Vector2(0, -60), 1.0)
	var socks := IntroCloseup.make(_ui, IntroCloseup.Kind.MEDIAS)
	await socks.pop_in()
	if not await _wait(1.3):
		return false
	await socks.pop_out()
	if not await _say("moda"):
		return false
	for member: Node2D in [kai, mom, dad]:
		SpeechBark.say(member, "¡Jajaja!", Vector2(0, -56), 1.2)
	Sfx.play(&"laugh")
	if not await _wait(1.3):
		return false
	# Se va hacia la puerta... el papá lo llama.
	follow = true
	if not await _walk(HOUSE_X + 420, false):
		return false
	if not await _say("consejo"):
		return false
	if not await _walk(HOUSE_X + 300, false):
		return false
	if not await _say("almuerzo"):
		return false
	# Vuelve por la lonchera.
	if not await _walk(lunchbox.global_position.x - 10.0, true):
		return false
	lunchbox.visible = false
	Sfx.play(&"zipper", 1.3)
	if not await _walk(HOUSE_X + 70, true):
		return false
	kai.face(1)
	if not await _say("despedida"):
		return false
	kai.visible = false
	follow = false
	Sfx.play(&"door_close")
	# Los papás se miran un momento, en silencio (una pista: no se explica nada).
	var to_parents := create_tween()
	to_parents.tween_property(camera, "position:x", HOUSE_X + 760, 1.0 * _speed()).set_trans(Tween.TRANS_SINE)
	await to_parents.finished
	_face(mom, -1)
	_face(dad, 1)
	if not await _wait(1.8):
		return false
	kai.visible = true
	return true


## Escena 4: el barrio.
func _neighborhood() -> bool:
	if not await _fade_to(1.0, 0.35):
		return false
	_set_stage(STREET_X, 1800.0, false)
	Music.play(&"intro_manana")
	kai.global_position = Vector2(STREET_X + 1590, FLOOR_Y)
	kai.face(-1)
	camera.position = Vector2(STREET_X + 1500, 224)
	camera.zoom = Vector2(1.6, 1.6)
	if not await _fade_to(0.0, 0.5):
		return false
	_show_caption("Barrio de los Almendros")
	# Plano general y después la cámara sigue a Kai, de lado.
	var settle := create_tween()
	settle.set_parallel().tween_property(camera, "zoom", Vector2(2, 2), 1.4 * _speed()).set_trans(Tween.TRANS_SINE)
	settle.tween_property(camera, "position:y", CAM_Y, 1.4 * _speed()).set_trans(Tween.TRANS_SINE)
	follow = true
	if not await _walk(STREET_X + 1230, false):
		return false
	# Pasa el bus.
	bus.visible = true
	bus.global_position = Vector2(STREET_X + 1800, FLOOR_Y - 4)
	var drive := create_tween()
	drive.tween_property(bus, "global_position:x", STREET_X - 200, 4.0 * _speed())
	Sfx.play(&"bus_pass")
	if not await _walk(STREET_X + 820, false):
		return false
	kai.face(1 if pulpero.global_position.x > kai.global_position.x else -1)
	if not await _say("pulperia"):
		return false
	kai.face(-1)
	if not await _walk(dog.global_position.x + 10.0, false):
		return false
	kai.face(1 if dog.global_position.x > kai.global_position.x else -1)
	for i in 4:
		dog.active = true
		Sfx.play(&"dog_bark", 1.0 + 0.1 * i, 2.0 * i)
		SpeechBark.say(dog, "¡GUAU!" if i < 3 else "¡¡GUAU GUAU!!", Vector2(0, -50), 0.7)
		if not await _wait(0.5 + 0.1 * i):
			return false
		dog.active = false
		if not await _say("perro_%d" % (i + 1)):
			return false
	if not await _say("reloj"):
		return false
	# ¡A correr!
	Music.play(&"intro_prisa")
	kai.face(-1)
	if not await _walk(STREET_X + 262, true):
		return false
	return true


## Escena 5: la llegada al colegio.
func _school() -> bool:
	follow = false
	var arrive := create_tween()
	arrive.tween_property(camera, "position:x", STREET_X + 320, 0.5 * _speed())
	_show_caption("Colegio Técnico")
	SpeechBark.say(kai, "*uf... uf...*", Vector2(0, -50), 1.2)
	if not await _wait(1.2):
		return false
	kai.face(1)
	if not await _say("llegada"):
		return false
	var face := IntroCloseup.make(_ui, IntroCloseup.Kind.ESPEJO)
	face.cowlick = 0.0
	await face.pop_in()
	if not await _wait(0.4):
		return false
	Sfx.play(&"boing")
	var spring := create_tween()
	spring.tween_property(face, "cowlick", 1.0, 0.12 * _speed()).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not await _wait(0.6):
		return false
	await face.pop_out()
	if not await _say("estilo"):
		return false
	SpeechBark.say(kai, "¡Jajaja!", Vector2(0, -56), 1.0)
	SpeechBark.say(friend, "¡Jajaja!", Vector2(0, -56), 1.0)
	Sfx.play(&"laugh")
	if not await _wait(1.1):
		return false
	kai.face(-1)
	if not await _say("otro_dia"):
		return false
	# La cámara se eleva y muestra el colegio; baja la música.
	Music.duck(-12.0, 1.5)
	var rise := create_tween().set_parallel()
	rise.tween_property(camera, "position", Vector2(STREET_X + 190, 120), 2.2 * _speed()).set_trans(Tween.TRANS_SINE)
	rise.tween_property(camera, "zoom", Vector2(1.5, 1.5), 2.2 * _speed()).set_trans(Tween.TRANS_SINE)
	await rise.finished
	return await _fade_to(1.0, 1.0)


## El título del juego (el nombre configurado en el proyecto) sobre negro.
func _title() -> void:
	Music.play(&"")
	var title := $UI/Title as Control
	var tween := create_tween()
	tween.tween_property(title, "modulate:a", 1.0, 0.8 * _speed())
	tween.tween_interval(2.4 * _speed())
	tween.tween_property(title, "modulate:a", 0.0, 0.6 * _speed())
	await tween.finished


## Termina: el jugador aparece en la Entrada del colegio (prólogo, «Habla con el profesor Alvarado»).
func _finish() -> void:
	if done:
		return
	done = true
	follow = false
	var state := get_node("/root/GameState")
	state.set_flag(DONE_FLAG)
	Music.duck(0.0, 0.3)
	Music.play(&"")
	finished.emit()
	# Si todavía está el fundido de entrada (omitir apenas empieza), se espera: si no, el cambio se ignoraría.
	var scene_manager := get_node("/root/SceneManager")
	while scene_manager.is_changing():
		await get_tree().process_frame
	scene_manager.go_to_room(FIRST_ROOM, &"")


# --- Piezas -------------------------------------------------------------------------------------------------------

## Don Carlos usa el NPC adulto de fondo (como el papá): su propia ropa (camisa de pulpero), para no confundirlos.
func _dress_shopkeeper() -> void:
	for node in pulpero.find_children("*", "AnimatedSprite2D", true, false):
		var recolor := ShaderMaterial.new()
		recolor.shader = preload("res://characters/npcs/familia/parent_recolor.gdshader")
		recolor.set_shader_parameter(&"shirt_color", Color("e0a84a"))
		recolor.set_shader_parameter(&"pants_color", Color("5a4030"))
		(node as AnimatedSprite2D).material = recolor


func _speed() -> float:
	return 0.12 if quick else 1.0


## Espera (false si se omitió mientras tanto). Usa un Timer propio: si la escena se cierra, no vuelve.
func _wait(seconds: float) -> bool:
	if skipping:
		return false
	var timer := Timer.new()
	timer.one_shot = true
	add_child(timer)
	timer.start(maxf(seconds * _speed(), 0.01))
	await timer.timeout
	timer.queue_free()
	return not skipping


## Un diálogo de data/dialogues/intro/ (avanza el jugador, como siempre).
func _say(dialogue_name: String) -> bool:
	if skipping:
		return false
	await _box.play(load(D + dialogue_name + ".tres"))
	return not skipping


## Kai camina (o corre) hasta x.
func _walk(x: float, run: bool) -> bool:
	if skipping:
		return false
	var direction := 1.0 if x > kai.global_position.x else -1.0
	kai.speed_scale = 1.7 if run else 1.0
	kai.scripted_axis = direction
	for i in 2000:
		if skipping:
			break
		if (x - kai.global_position.x) * direction <= 2.0:
			break
		await get_tree().physics_frame
	kai.scripted_axis = 0.0
	kai.velocity.x = 0.0
	kai.speed_scale = 1.0
	return not skipping


## Un papá camina hasta x (como en HomeStory).
func _member_walk(member: FamilyMember, x: float) -> bool:
	var distance := absf(member.global_position.x - x)
	if distance < 2.0:
		return not skipping
	_face(member, 1 if x > member.global_position.x else -1)
	var tween := create_tween()
	tween.tween_property(member, "global_position:x", x, distance / 110.0 * _speed())
	await tween.finished
	return not skipping


func _face(member: Node2D, direction: int) -> void:
	var sprite := member.get_node_or_null("Sprite") as AnimatedSprite2D
	if sprite:
		sprite.flip_h = direction < 0


## Kai tropieza: cae de cara (golpe cómico) y queda en el piso.
func _trip() -> void:
	var visual := kai.get_node("Visual") as Node2D
	Sfx.play(&"bonk")
	var tween := create_tween()
	tween.tween_property(visual, "rotation", -PI / 2.0 * kai.facing, 0.15)
	await tween.finished
	SpeechBark.say(kai, "¡PUM!", Vector2(0, -40), 0.9)
	var shake := create_tween()
	for k in 4:
		shake.tween_property(camera, "offset", Vector2(randf_range(-4, 4), randf_range(-3, 3)), 0.04)
	shake.tween_property(camera, "offset", Vector2.ZERO, 0.04)
	await _wait(0.8)


func _stand_up() -> void:
	var visual := kai.get_node("Visual") as Node2D
	var tween := create_tween()
	tween.tween_property(visual, "rotation", 0.0, 0.2)
	await tween.finished


## Un cuaderno se cae del escritorio al piso.
func _drop(notebook: IntroProp, x: float) -> void:
	Sfx.play(&"book_close")
	var tween := create_tween().set_parallel()
	tween.tween_property(notebook, "global_position", Vector2(x, FLOOR_Y), 0.35 * _speed()).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(notebook, "rotation", 0.6, 0.35 * _speed())
	await tween.finished
	Sfx.play(&"land")


## Cambia de decorado: límites de la cámara y la luz (adentro, cálida; afuera, la de la mañana).
func _set_stage(x: float, width: float, indoors: bool) -> void:
	camera.limit_left = int(x)
	camera.limit_right = int(x + width)
	camera.limit_top = 0
	camera.limit_bottom = CAM_BOTTOM
	camera.zoom = Vector2(2, 2)
	camera.offset = Vector2.ZERO
	ambient.color = DayPhase.ambient(DayPhase.Phase.MANANA, indoors)


## Corte rápido a negro (montaje).
func _cut(seconds: float) -> bool:
	if not await _fade_to(1.0, seconds):
		return false
	if skipping:
		return false
	_fade_to.call_deferred(0.0, seconds)
	return await _wait(seconds)


func _fade_to(alpha: float, seconds: float) -> bool:
	if skipping:
		return false
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, seconds * _speed())
	await tween.finished
	return not skipping


func _show_caption(text: String) -> void:
	_caption.text = text
	var tween := create_tween()
	tween.tween_property(_caption, "modulate:a", 1.0, 0.4)
	tween.tween_interval(2.2 * _speed())
	tween.tween_property(_caption, "modulate:a", 0.0, 0.6)


func _stop_sound(sound: AudioStreamPlayer) -> void:
	if sound and is_instance_valid(sound):
		sound.stop()

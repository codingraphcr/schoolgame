class_name FamilyMember
extends Npc
## Mamá o papá de Kai: un Npc (se habla con E; lo que dice depende de la misión: conversations) con
## animación de reposo (respira y de vez en cuando hace su tarea: cocinar, leer...) y su propia ropa
## (parent_recolor.gdshader) sobre un sprite provisional, hasta que Ariel los dibuje.

## Tarea de reposo: "" (solo respira), "cocinar" (revuelve: se mueve un poco de lado), "leer" (baja la
## cabeza de vez en cuando).
@export var chore: StringName = &""
@export var shirt_color := Color("8a4a6a")
@export var pants_color := Color("3a3a48")
## Rutina según el momento del día (DayPhase.Phase → [posición, mirada (1 / -1), tarea]). Se aplica
## cuando cambia el momento (no mientras dura: una escena puede moverlos). Sin rutina, se queda donde está.
@export var routine: Dictionary = {}

var applied_phase := -1

var _clock := 0.0
var _base_scale := Vector2.ONE
var _base_position := Vector2.ZERO


func _ready() -> void:
	super()
	_base_scale = _sprite.scale
	_base_position = _sprite.position
	_clock = randf() * 4.0
	var recolor := ShaderMaterial.new()
	recolor.shader = preload("res://characters/npcs/familia/parent_recolor.gdshader")
	recolor.set_shader_parameter(&"shirt_color", shirt_color)
	recolor.set_shader_parameter(&"pants_color", pants_color)
	_sprite.material = recolor
	apply_routine()


## Pone al personaje donde le toca en este momento del día (si cambió desde la última vez).
func apply_routine(force := false) -> void:
	var phase := DayPhase.current(_game_state())
	if (phase == applied_phase and not force) or not routine.has(phase):
		applied_phase = phase
		return
	applied_phase = phase
	var spot: Array = routine[phase]
	position = spot[0]
	_sprite.flip_h = int(spot[1]) < 0
	chore = spot[2] if spot.size() > 2 else &""


func _process(delta: float) -> void:
	super(delta)
	if not _talking and DayPhase.current(_game_state()) != applied_phase:
		apply_routine()
	_clock += delta
	var breath := sin(_clock * 2.2) * 0.012
	_sprite.scale = Vector2(_base_scale.x * (1.0 - breath * 0.5), _base_scale.y * (1.0 + breath))
	var offset := Vector2.ZERO
	if not _talking:
		match chore:
			&"cocinar":
				offset.x = sin(_clock * 3.0) * 1.5 if fmod(_clock, 6.0) < 3.5 else 0.0
			&"leer":
				offset.y = 1.0 if fmod(_clock, 5.0) < 2.0 else 0.0
	_sprite.position = _base_position + offset

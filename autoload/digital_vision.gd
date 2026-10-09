extends Node
## Visión Digital: deja ver la red y las amenazas que nadie más percibe.
## Diseño de Ariel: dura 10 s, se recarga en 16 s contados desde que se apaga y avisa
## parpadeando en los últimos 2 s. Se puede apagar antes. Solo funciona si GameState.vision_unlocked.
## Está registrado como autoload "DigitalVision". El estado vive aquí (no en cada sala), así que
## se conserva al cambiar de sala; cada sala dibuja sus efectos con DigitalWorld a partir de blend.

signal activated
signal deactivated
## Se intentó usar sin poder hacerlo. reason: &"locked" (aún no se descubrió) o &"recharging".
signal denied(reason: StringName, seconds_left: float)

enum State { READY, ACTIVE, RECHARGING }

const TRANSITION_TIME := 0.45

## Segundos que dura la Visión Digital.
@export var duration := 10.0
## Segundos de recarga, contados desde que se apaga.
@export var cooldown := 16.0
## Últimos segundos en los que la capa digital parpadea para avisar que se acaba.
@export var warning_time := 2.0

var state := State.READY
var time_left := 0.0
var cooldown_left := 0.0
## 0 = mundo físico, 1 = mundo digital. Cambia con una transición suave.
var blend := 0.0

var _blend_tween: Tween


func _process(delta: float) -> void:
	match state:
		State.ACTIVE:
			# Si la partida se reinicia (visión sin descubrir), se apaga sin recarga.
			if not is_unlocked():
				reset()
				return
			time_left -= delta
			if time_left <= 0.0:
				deactivate()
		State.RECHARGING:
			cooldown_left = maxf(cooldown_left - delta, 0.0)
			if cooldown_left <= 0.0:
				state = State.READY


func is_active() -> bool:
	return state == State.ACTIVE


func is_unlocked() -> bool:
	var game_state := get_node_or_null("/root/GameState")
	return game_state != null and game_state.vision_unlocked


## Q: enciende si está lista, apaga si está activa.
func toggle() -> void:
	if is_active():
		deactivate()
	else:
		activate()


## Enciende la Visión Digital. force ignora la recarga (eventos de la historia).
## Devuelve true si quedó activa.
func activate(force := false) -> bool:
	if is_active():
		return true
	if not is_unlocked():
		denied.emit(&"locked", 0.0)
		return false
	if state == State.RECHARGING and not force:
		denied.emit(&"recharging", cooldown_left)
		return false
	state = State.ACTIVE
	time_left = duration
	cooldown_left = 0.0
	_animate_blend(1.0)
	activated.emit()
	return true


## Apaga la Visión Digital y empieza la recarga.
func deactivate() -> void:
	if not is_active():
		return
	state = State.RECHARGING
	time_left = 0.0
	cooldown_left = cooldown
	_animate_blend(0.0)
	deactivated.emit()


## Vuelve al estado inicial sin recarga (partida nueva).
func reset() -> void:
	var was_active := is_active()
	state = State.READY
	time_left = 0.0
	cooldown_left = 0.0
	if _blend_tween:
		_blend_tween.kill()
	blend = 0.0
	if was_active:
		deactivated.emit()


## 1 normalmente; en los últimos segundos oscila para avisar que se acaba.
func warning_factor() -> float:
	if is_active() and time_left < warning_time:
		return 0.55 + 0.45 * absf(cos(time_left * 9.0))
	return 1.0


func _animate_blend(target: float) -> void:
	if _blend_tween:
		_blend_tween.kill()
	_blend_tween = create_tween()
	_blend_tween.tween_property(self, "blend", target, TRANSITION_TIME)

extends AnimatedSprite2D
## Animación de Kai según el estado del jugador: quieto, correr, saltar, caer, dash y pared.
## Los cuadros están en kai_frames.tres (tiras de assets/art/pixel/ que genera
## tools/art/generar_sprites.gd). El giro y la deformación los hereda de Visual/Body.

const ANIMATIONS := {
	Player.State.IDLE: &"idle",
	Player.State.RUN: &"run",
	Player.State.JUMP: &"jump",
	Player.State.FALL: &"fall",
	Player.State.DASH: &"dash",
	Player.State.WALL_SLIDE: &"wall",
}

@onready var _player := owner as Player


func _process(_delta: float) -> void:
	if _player == null:
		return
	var anim: StringName = ANIMATIONS.get(_player.state, &"idle")
	if animation != anim or not is_playing():
		play(anim)
	# Al correr despacio, la animación también va más lenta.
	if anim == &"run":
		speed_scale = clampf(absf(_player.velocity.x) / _player.max_speed, 0.5, 1.2)
	else:
		speed_scale = 1.0

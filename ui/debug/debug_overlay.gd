extends CanvasLayer
## Panel de depuración para ajustar la sensación del movimiento. F3 lo muestra u oculta.

@export var player: Player

@onready var _label: Label = $Label


func _process(_delta: float) -> void:
	if not visible or player == null:
		return
	_label.text = "\n".join([
		"FPS: %d" % Engine.get_frames_per_second(),
		"Estado: %s" % Player.State.keys()[player.state],
		"Velocidad: (%.0f, %.0f)" % [player.velocity.x, player.velocity.y],
		"En el suelo: %s" % ("sí" if player.is_on_floor() else "no"),
		"Coyote: %.2f s   Buffer: %.2f s" % [player.coyote_timer, player.jump_buffer_timer],
		"Saltos aéreos: %d   Dash: %s" % [player.air_jumps_left, "listo" if player.dash_cooldown_timer <= 0.0 else "%.2f s" % player.dash_cooldown_timer],
		"Habilidades: dash %s · doble salto %s · pared %s" % [_on_off(player.can_dash), _on_off(player.can_double_jump), _on_off(player.can_wall_jump)],
		"F3: ocultar   Esc: menú",
	])


func _on_off(enabled: bool) -> String:
	return "sí" if enabled else "no"


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_F3:
		visible = not visible

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
		"F3: ocultar   Esc: menú",
	])


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_F3:
		visible = not visible

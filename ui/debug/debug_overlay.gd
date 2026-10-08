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
		"Habilidades: dash nivel %d · doble salto %s · pared %s" % [player.dash_level, _on_off(player.can_double_jump), _on_off(player.can_wall_jump)],
		"Máscaras: %d/%d   Invulnerable: %s" % [ceili(player.health.current), int(player.health.max_health), _on_off(player.is_invulnerable())],
		"Progreso: %s · %s · %s · %s · créditos %d" % [
			GameState.DASH_NAMES[GameState.dash_level], GameState.NULLBLADE_NAMES[GameState.nullblade_stage],
			GameState.AEGIS_NAMES[GameState.aegis_stage], GameState.DOMAIN_NAMES[GameState.domain_stage],
			GameState.credits],
		"F3: ocultar",
	])


func _on_off(enabled: bool) -> String:
	return "sí" if enabled else "no"


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_F3:
		visible = not visible

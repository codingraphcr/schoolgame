class_name HitStop
extends RefCounted
## Congela la acción unos milisegundos al recibir o dar un golpe fuerte (sensación de impacto).
## Usa Engine.time_scale solo durante ese instante. La ralentización del Dominio Nulo NO
## usa este mecanismo: tendrá su propio reloj local para enemigos (CombatClock).

const FROZEN_TIME_SCALE := 0.05

static var _active := false


static func freeze(node: Node, duration: float) -> void:
	if duration <= 0.0 or _active or node == null or not node.is_inside_tree():
		return
	_active = true
	var tree := node.get_tree()
	Engine.time_scale = FROZEN_TIME_SCALE
	# El temporizador ignora time_scale para durar el tiempo real indicado.
	await tree.create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_active = false

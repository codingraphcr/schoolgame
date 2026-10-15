class_name CombatClock
extends RefCounted
## Reloj de las amenazas digitales (docs/combate.md, C4). El Dominio Nulo lo baja (0,8 = al 80 % de
## velocidad) y lo leen los enemigos (EnemyBase) y los proyectiles compatibles: así se ralentizan solo
## ellos. NUNCA toca Engine.time_scale (que solo se usa un instante para el congelamiento por impacto),
## ni la interfaz, ni los temporizadores del HUD, ni a Kai.

## Multiplicador del tiempo de las amenazas (1 = normal).
static var threat_scale := 1.0


static func scaled(delta: float) -> float:
	return delta * threat_scale


## Espera seconds del tiempo de las amenazas (con la física): con el Dominio activo, tarda más.
static func wait(node: Node, seconds: float) -> void:
	var left := seconds
	while left > 0.0 and node.is_inside_tree():
		await node.get_tree().physics_frame
		if not is_instance_valid(node):
			return  # La sala se borró mientras esperaba (Kai perdió, cambio de sala).
		left -= node.get_physics_process_delta_time() * threat_scale


static func reset() -> void:
	threat_scale = 1.0

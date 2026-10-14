class_name BossAttacks
extends RefCounted
## Ataques que deja Chip en la arena (Capítulo 1). Todos están en el grupo "boss_attack" (la fase
## segura los borra) y corren con la física. Quitan medio cristal (golpe enemigo de daño 1).
##
## - shot(): disparo digital. Parpadea un instante donde sale (aviso) y vuela en línea recta.
## - trap(): trampa temporal en el suelo. Se arma parpadeando (aviso) y después pincha un rato.
## - wall(): barrera pequeña que cierra el paso un rato (no hace daño; se salta).


static func shot(parent: Node, at: Vector2, velocity: Vector2, size := 10.0, warning := 0.2) -> DataShot:
	var node := DataShot.new()
	node.velocity = velocity
	node.size = size
	node.warning = warning
	parent.add_child(node)
	node.global_position = at
	return node


static func trap(parent: Node, at: Vector2, arm: float, duration: float, width := 40.0) -> DataTrap:
	var node := DataTrap.new()
	node.arm_time = arm
	node.duration = duration
	node.width = width
	parent.add_child(node)
	node.global_position = at
	return node


static func wall(parent: Node, at: Vector2, duration: float, height := 64.0) -> ChipWall:
	var node := ChipWall.new()
	node.duration = duration
	node.height = height
	parent.add_child(node)
	node.global_position = at
	return node

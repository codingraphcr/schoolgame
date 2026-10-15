class_name BucleAttacks
extends RefCounted
## Los ataques de Bucle en la arena (Capítulo 2). Todos quedan en el grupo "boss_attack" (al recibir
## un impacto clave, al reiniciar y al final se borran) y corren con la física.
##
## - pulse(): Pulso repetitivo, dos ondas por el suelo (una a cada lado).
## - rain(): Lluvia de instrucciones en carriles; nunca tapa todos (rain_lanes()).
## - ring(): Ciclo circular, anillo con dos huecos que giran.
## - sweep(): Barrido, una línea que cruza toda la arena a la altura de Kai.
## - seekers(): Rastreo, procesos huérfanos que persiguen a Kai un rato.


static func pulse(parent: Node, at: Vector2, arena: Rect2, speed: float, telegraph: float, damage: float) -> Array[LoopPulse]:
	var waves: Array[LoopPulse] = []
	for direction in [-1.0, 1.0]:
		var wave := LoopPulse.new()
		wave.direction = direction
		wave.speed = speed
		wave.telegraph = telegraph
		wave.damage = damage
		wave.limit_x = arena.position.x if direction < 0.0 else arena.end.x
		parent.add_child(wave)
		wave.global_position = Vector2(at.x, arena.end.y)
		waves.append(wave)
	return waves


## Carriles que caen: count carriles de lanes, dejando por lo menos min_free libres (y siempre uno
## donde está Kai o al lado, para que tenga a dónde ir). target: el carril de Kai (se cubre primero).
static func rain_lanes(count: int, lanes: int, min_free: int, target: int, rng: RandomNumberGenerator) -> Array[int]:
	var blocked: Array[int] = []
	var limit := clampi(count, 0, lanes - maxi(min_free, 1))
	if limit <= 0:
		return blocked
	if target >= 0 and target < lanes:
		blocked.append(target)
	var options: Array[int] = []
	for i in lanes:
		if not blocked.has(i):
			options.append(i)
	while blocked.size() < limit and not options.is_empty():
		var pick := options[rng.randi_range(0, options.size() - 1)]
		options.erase(pick)
		blocked.append(pick)
		# Que quede libre por lo menos un carril vecino del de Kai.
		if target >= 0 and _free_neighbors(blocked, target, lanes) == 0:
			blocked.erase(pick)
	blocked.sort()
	return blocked


static func rain(parent: Node, arena: Rect2, lanes: Array[int], lane_count: int, fall_speed: float, telegraph: float,
		damage: float) -> Array[InstructionBlock]:
	var blocks: Array[InstructionBlock] = []
	var lane_width := arena.size.x / lane_count
	for lane in lanes:
		var block := InstructionBlock.new()
		block.width = lane_width - 8.0
		block.fall_speed = fall_speed
		block.telegraph = telegraph
		block.damage = damage
		block.floor_y = arena.end.y
		block.text = InstructionBlock.TEXTS[lane % InstructionBlock.TEXTS.size()]
		parent.add_child(block)
		block.global_position = Vector2(arena.position.x + lane_width * (lane + 0.5), arena.position.y + 20.0)
		blocks.append(block)
	return blocks


static func ring(parent: Node, at: Vector2, speed: float, width: float, gap: float, spin: float, gap_angle: float,
		telegraph: float, damage: float) -> LoopRing:
	var node := LoopRing.new()
	node.speed = speed
	node.width = width
	node.gap = gap
	node.spin = spin
	node.gap_angle = gap_angle
	node.telegraph = telegraph
	node.damage = damage
	parent.add_child(node)
	node.global_position = at
	return node


static func sweep(parent: Node, arena: Rect2, y: float, telegraph: float, live_time: float, damage: float) -> LoopSweep:
	var line := LoopSweep.new()
	line.width = arena.size.x
	line.telegraph = telegraph
	line.live_time = live_time
	line.damage = damage
	parent.add_child(line)
	line.global_position = Vector2(arena.position.x, clampf(y, arena.position.y + 10.0, arena.end.y - 8.0))
	return line


static func seekers(parent: Node, from: Vector2, arena: Rect2, count: int, target: Node2D, speed: float, turn: float, life: float,
		telegraph: float, damage: float) -> Array[LoopSeeker]:
	var result: Array[LoopSeeker] = []
	for i in count:
		var orb := LoopSeeker.new()
		orb.target = target
		orb.speed = speed
		orb.turn_rate = turn
		orb.life = life
		orb.arena = arena
		orb.telegraph = telegraph + i * 0.15
		orb.damage = damage
		parent.add_child(orb)
		var spread := (i - (count - 1) / 2.0) * 22.0
		orb.global_position = from + Vector2(spread, -6.0)
		result.append(orb)
	return result


static func clear(tree: SceneTree) -> void:
	for attack in tree.get_nodes_in_group(&"boss_attack"):
		attack.queue_free()


static func _free_neighbors(blocked: Array[int], target: int, lanes: int) -> int:
	var free := 0
	for lane in [target - 1, target + 1]:
		if lane >= 0 and lane < lanes and not blocked.has(lane):
			free += 1
	return free

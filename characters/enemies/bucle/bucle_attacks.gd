class_name BucleAttacks
extends RefCounted
## Los ataques de Bucle en la arena (Capítulo 2). Todos quedan en el grupo "boss_attack" (al recibir
## un impacto clave, al reiniciar y al final se borran) y corren con la física.
##
## - pulse(): Pulso repetitivo, dos ondas por el suelo (una a cada lado).
## - rain(): Lluvia de instrucciones en carriles; nunca tapa todos (rain_lanes()). Con el Desbordamiento los
##   bloques se quedan apilados un rato (stacked_lanes(): cuentan como tapados para la próxima lluvia).
## - ring(): Ciclo circular, anillo con dos huecos que giran (con la Recursión se divide: LoopRing).
## - iteration(): Iteración, un rayo que barre la sala con un hueco (IterationBeam).
## - shard(): un mini anillo en línea recta (MiniLoop: los de la Recursión y los que tiran las copias).


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
## taken: carriles ya tapados (bloques apilados por el Desbordamiento): se pueden volver a tapar, pero
## cuentan para los libres.
static func rain_lanes(count: int, lanes: int, min_free: int, target: int, rng: RandomNumberGenerator,
		taken: Array[int] = []) -> Array[int]:
	var blocked: Array[int] = []
	var most := lanes - maxi(min_free, 1)
	var limit := clampi(count, 0, most)
	if limit <= 0:
		return blocked
	var covered: Array[int] = taken.duplicate()
	var options: Array[int] = []
	for i in lanes:
		options.append(i)
	while blocked.size() < limit and not options.is_empty():
		var pick := target if options.has(target) else options[rng.randi_range(0, options.size() - 1)]
		options.erase(pick)
		var was_covered := covered.has(pick)
		if not was_covered and covered.size() >= most:
			continue
		blocked.append(pick)
		if not was_covered:
			covered.append(pick)
		# Que quede libre por lo menos un carril vecino del de Kai.
		if target >= 0 and _free_neighbors(covered, target, lanes) == 0:
			blocked.erase(pick)
			if not was_covered:
				covered.erase(pick)
	blocked.sort()
	return blocked


## stay: segundos que quedan apilados al llegar (Desbordamiento; 0 = se rompen) y cuántos como mucho por
## carril (los de más se rompen arriba de la pila).
static func rain(parent: Node, arena: Rect2, lanes: Array[int], lane_count: int, fall_speed: float, telegraph: float,
		damage: float, stay := 0.0, max_stack := 2) -> Array[InstructionBlock]:
	var blocks: Array[InstructionBlock] = []
	var lane_width := arena.size.x / lane_count
	for lane in lanes:
		var stacked := _stack_size(parent.get_tree(), lane)
		var block := InstructionBlock.new()
		block.width = lane_width - 8.0
		block.fall_speed = fall_speed
		block.telegraph = telegraph
		block.damage = damage
		block.lane = lane
		block.floor_y = arena.end.y - InstructionBlock.HEIGHT * mini(stacked, max_stack)
		block.stay_time = stay if stacked < max_stack else 0.0
		block.text = InstructionBlock.TEXTS[lane % InstructionBlock.TEXTS.size()]
		parent.add_child(block)
		block.global_position = Vector2(arena.position.x + lane_width * (lane + 0.5), arena.position.y + 20.0)
		blocks.append(block)
	return blocks


## Carriles con bloques apilados (o que se van a apilar) del Desbordamiento.
static func stacked_lanes(tree: SceneTree) -> Array[int]:
	var lanes: Array[int] = []
	for node in tree.get_nodes_in_group(&"boss_attack"):
		var block := node as InstructionBlock
		if block and block.stay_time > 0.0 and not block.is_queued_for_deletion() and not lanes.has(block.lane):
			lanes.append(block.lane)
	return lanes


## Iteración: un rayo de from_x a to_x (de arriba de la sala, top_y, al suelo, floor_y) con el hueco a la
## altura gap_first en la primera mitad y gap_second en la segunda.
static func iteration(parent: Node, from_x: float, to_x: float, top_y: float, floor_y: float, speed: float, gap_first: float,
		gap_second: float, gap_size: float, telegraph: float, damage: float) -> IterationBeam:
	var beam := IterationBeam.new()
	beam.from_x = from_x
	beam.to_x = to_x
	beam.top_y = top_y
	beam.floor_y = floor_y
	beam.speed = speed
	beam.gap_first = gap_first
	beam.gap_second = gap_second
	beam.gap_size = gap_size
	beam.telegraph = telegraph
	beam.damage = damage
	parent.add_child(beam)
	beam.global_position = Vector2(from_x, 0.0)
	return beam


static func shard(parent: Node, at: Vector2, direction: Vector2, speed: float, travel: float, telegraph: float, damage: float,
		color := MiniLoop.COLOR) -> MiniLoop:
	var node := MiniLoop.new()
	node.direction = direction.normalized()
	node.speed = speed
	node.travel = travel
	node.telegraph = telegraph
	node.damage = damage
	node.color = color
	parent.add_child(node)
	node.global_position = at
	return node


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


static func clear(tree: SceneTree) -> void:
	for attack in tree.get_nodes_in_group(&"boss_attack"):
		attack.queue_free()


static func _free_neighbors(blocked: Array[int], target: int, lanes: int) -> int:
	var free := 0
	for lane in [target - 1, target + 1]:
		if lane >= 0 and lane < lanes and not blocked.has(lane):
			free += 1
	return free


static func _stack_size(tree: SceneTree, lane: int) -> int:
	var count := 0
	for node in tree.get_nodes_in_group(&"boss_attack"):
		var block := node as InstructionBlock
		if block and block.lane == lane and block.stay_time > 0.0 and not block.is_queued_for_deletion():
			count += 1
	return count

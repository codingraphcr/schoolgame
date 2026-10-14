class_name BossAttacks
extends RefCounted
## Ataques que Glitch y Chip dejan en la arena (Capítulo 1). Todos están en el grupo "boss_attack" (la
## fase segura y el final los borran) y corren con la física. Los que dañan quitan medio cristal.
##
## - shot(): proyectil (los fragmentos de Glitch: cuchillas rosas). Parpadea antes de salir.
## - disc(): disco de Chip que sale, se curva hacia Kai y vuelve (Discos orbitales).
## - zone(): Zona de control de Chip (ralentiza a Kai, no daña).
## - beam(): Rayo de sincronía de Chip (línea de aviso y después el rayo).
## - copy(): Proyección de Chip (copia temporal que lanza un disco; un golpe la deshace).
## - field(): Campo Dual, el ataque definitivo (todo el piso menos un hueco seguro).


static func shot(parent: Node, at: Vector2, velocity: Vector2, size := 10.0, warning := 0.2, color := SiblingArt.CHIP, blade := false) -> DataShot:
	var node := DataShot.new()
	node.velocity = velocity
	node.size = size
	node.warning = warning
	node.color = color
	node.blade = blade
	parent.add_child(node)
	node.global_position = at
	return node


static func disc(parent: Node, at: Vector2, velocity: Vector2, reach: float, thrower: Node2D, warning := 0.0) -> DiscShot:
	var node := DiscShot.new()
	node.velocity = velocity
	node.reach = reach
	node.thrower = thrower
	node.warning = warning
	parent.add_child(node)
	node.global_position = at
	return node


static func zone(parent: Node, at: Vector2, config: DualBossConfig, telegraph_scale := 1.0) -> ControlZone:
	var node := ControlZone.new()
	node.width = config.chip_zone_width
	node.warning = config.chip_zone_telegraph * telegraph_scale
	node.duration = config.chip_zone_time
	node.slow = config.chip_zone_slow
	parent.add_child(node)
	node.global_position = at
	return node


static func beam(parent: Node, at: Vector2, direction: Vector2, config: DualBossConfig, telegraph_scale := 1.0, length := 640.0) -> SyncBeam:
	var node := SyncBeam.new()
	node.direction = direction.normalized()
	node.length = length
	node.warning = config.chip_beam_telegraph * telegraph_scale
	node.duration = config.chip_beam_time
	parent.add_child(node)
	node.global_position = at
	return node


static func copy(parent: Node, at: Vector2, config: DualBossConfig, throw_at := 0.7) -> ChipCopy:
	var node := ChipCopy.new()
	node.config = config
	node.life = config.chip_copy_time
	node.throw_at = throw_at
	parent.add_child(node)
	node.global_position = at
	return node


static func field(parent: Node, floor_y: float, left: float, right: float, gap_x: float, config: DualBossConfig, telegraph_scale := 1.0) -> DualField:
	var node := DualField.new()
	node.left = left
	node.right = right
	node.gap_x = clampf(gap_x, left + config.field_safe_gap / 2.0, right - config.field_safe_gap / 2.0)
	node.gap = config.field_safe_gap
	node.warning = config.field_telegraph * telegraph_scale
	node.duration = config.field_time
	parent.add_child(node)
	node.global_position = Vector2(0, floor_y)
	return node

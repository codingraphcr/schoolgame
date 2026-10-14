class_name ChipCopy
extends Node2D
## Proyección de Chip: una copia temporal (translúcida, con líneas de interferencia) que aparece,
## lanza un disco hacia Kai y se desvanece. Un golpe de la Nullblade la deshace. No hace daño al
## tocarla. El origen son sus pies.

signal popped

var life := 2.6
## Segundos hasta que lanza su disco.
var throw_at := 0.7
var config: DualBossConfig
var face := 1.0
var _time := 0.0
var _thrown := false
var _hurtbox: HurtboxComponent


func _ready() -> void:
	add_to_group(&"boss_attack")
	_hurtbox = HurtboxComponent.new()
	_hurtbox.collision_layer = 0
	_hurtbox.collision_mask = 8  # Capa 4: ataques_jugador
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 40)
	shape.shape = rect
	shape.position = Vector2(0, -20)
	_hurtbox.add_child(shape)
	add_child(_hurtbox)
	_hurtbox.hit_received.connect(func(_hit: HitData) -> void: pop())


func _physics_process(delta: float) -> void:
	_time += delta
	queue_redraw()
	var kai := get_tree().get_first_node_in_group(&"player") as Node2D
	if kai:
		face = 1.0 if kai.global_position.x >= global_position.x else -1.0
	if not _thrown and _time >= throw_at and kai:
		_thrown = true
		var speed := config.chip_disc_speed if config else 175.0
		BossAttacks.disc(get_parent(), global_position + Vector2(face * 10.0, -24), Vector2(face, -0.15).normalized() * speed, config.chip_disc_range * 0.8 if config else 180.0, self)
	if _time >= life:
		queue_free()


## Un golpe la deshace en píxeles.
func pop() -> void:
	PixelBurst.spawn(get_parent(), global_position + Vector2(0, -24), [SiblingArt.CHIP, SiblingArt.CHIP_LIGHT], 12, 70.0, Vector2(20, 40), 0.4)
	popped.emit()
	queue_free()


func _draw() -> void:
	var appear := clampf(_time / 0.25, 0.0, 1.0)
	var fade := clampf((life - _time) / 0.4, 0.0, 1.0)
	var alpha := 0.55 * appear * fade
	SiblingArt.draw_twin(self, &"chip", _time, face, { "alpha": alpha, "tint": Color(0.6, 0.85, 1.4), "offset": Vector2(sin(_time * 30.0) * (1.0 - appear) * 6.0, 0) })
	for y in range(-46, 0, 4):
		if (y / 4 + int(_time * 12.0)) % 3 == 0:
			draw_rect(Rect2(-13, y, 26, 1), Color(SiblingArt.CHIP_LIGHT, alpha * 0.6))

class_name BucleClone
extends Node2D
## Copia del proceso (Bucle, ciclos altos): se ve igual que Bucle (la misma animación y el mismo color de etapa)
## y también ataca (BucleBoss le pide que tire mini anillos hacia Kai), pero no recibe golpes: el tajo rebota.
## Se distingue por un detalle: la flecha de ciclo sobre su cabeza gira al revés que la del verdadero.
## La mueve BucleBoss; está en el grupo "boss_attack" (se borra con los ataques).

var boss: BucleBoss

var _body: Node2D
var _clock := 0.0
var _flash := 0.0


func _init() -> void:
	add_to_group(&"boss_attack")


func _ready() -> void:
	z_index = boss.z_index
	_body = Node2D.new()
	var tint := ShaderMaterial.new()
	tint.shader = BucleBoss.TINT
	_body.material = tint
	add_child(_body)
	_body.draw.connect(_draw_body)
	var hurt := HurtboxComponent.new()
	hurt.collision_layer = 0
	hurt.collision_mask = 8  # Capa 4: ataques_jugador
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = boss.body_size
	shape.shape = rect
	shape.position = Vector2(0, -boss.body_size.y / 2.0)
	hurt.add_child(shape)
	add_child(hurt)
	hurt.hit_received.connect(_on_hit)
	_clock = boss.rng.randf() * 3.0


func _physics_process(delta: float) -> void:
	_clock += delta
	_flash = maxf(_flash - delta, 0.0)
	queue_redraw()
	_body.queue_redraw()


## Centro del cuerpo (de donde tira).
func center() -> Vector2:
	return global_position + BucleArt.CENTER


## Desaparece con un destello.
func vanish() -> void:
	PixelBurst.spawn(get_parent(), center(), [BucleArt.body_color(boss.stage), Color.WHITE], 10, 70.0, Vector2(18, 18), 0.35)
	queue_free()


func _on_hit(_hit: HitData) -> void:
	_flash = 0.3
	boss.copy_hit(self)


func _draw() -> void:
	BucleArt.draw_around(self, boss.stage, _clock, GameSettings.glitch_factor())
	BucleArt.draw_cycle_arrow(self, _clock, -1.0, BucleArt.body_color(boss.stage))
	boss.draw_counter(self)
	if _flash > 0.0:
		# El escudo de la copia: el golpe rebota.
		draw_arc(BucleArt.CENTER, 17.0, 0.0, TAU, 24, Color(Color.WHITE, _flash * 2.5), 2.0)


func _draw_body() -> void:
	_body.material.set_shader_parameter(&"target", BucleArt.body_color(boss.stage))
	# Una interferencia leve de vez en cuando (casi no se nota: lo que la delata es la flecha).
	_body.position.x = 1.5 if fmod(_clock, 1.9) < 0.06 else 0.0
	if not BucleArt.draw_sprite(_body, boss.current_anim(), boss.anim_time(), boss.stage, _clock):
		BucleArt.draw_fallback(_body, boss.stage, _clock, &"preparando")

extends SceneTree
## Prueba automática: máscaras, daño, invulnerabilidad, peligros, muerte y niveles del dash.
## Ejecutar: godot --headless --path . --script res://tests/test_player_health.gd

const ROOM := "res://tests/fixtures/combat_test_room.tscn"
const FLOOR_Y := 480.0
const BEFORE_FLOOR_SPIKES := Vector2(1080, 480)  # Pinchos del suelo: x 1120–1152
const DASH_OVER_SPIKES := Vector2(1110, 480)

var _failures := 0
var _hurts := 0
var _deaths := 0
var _blocked := 0
var room: Room
var player: Player


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state := root.get_node("GameState")
	state.reset()
	state.set_dash_level(2)
	change_scene_to_file(ROOM)
	await _frames(30)
	room = current_scene as Room
	player = room.player
	player.damage.hurt.connect(func(_hit: HitData) -> void: _hurts += 1)
	player.damage.died.connect(func() -> void: _deaths += 1)

	await _test_start_state()
	await _test_floor_spikes()
	await _test_dash_levels()
	await _test_knockback_and_contact()
	await _test_educational_shield()
	await _test_fall_out()
	await _test_death()

	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_start_state() -> void:
	_check(player.health.max_health == 4.0 and player.health.current == 4.0, "empieza con 4/4 máscaras")
	var masks := room.get_node("CombatHUD/Masks")
	await _frames(2)
	_check(masks.get_child_count() == 4, "el HUD muestra 4 máscaras")


func _test_floor_spikes() -> void:
	await _reset_at(BEFORE_FLOOR_SPIKES)
	var hurts_before := _hurts
	Input.action_press("move_right")
	for i in 90:
		await physics_frame
		if _hurts > hurts_before:
			break
	Input.action_release("move_right")
	_check(_hurts == hurts_before + 1, "los pinchos dañan al tocarlos")
	_check(player.health.current == 3.0, "pierde 1 máscara (quedan %d)" % player.health.current)
	_check(player.is_invulnerable(), "queda invulnerable tras el golpe")
	await _wait(1.0)
	var x := player.global_position.x
	_check(x < 1095.0 and absf(player.global_position.y - FLOOR_Y) < 1.0,
		"reaparece en el suelo seguro, antes de los pinchos (x=%.0f)" % x)
	_check(_hurts == hurts_before + 1, "no recibe un segundo golpe al reaparecer")
	_check(not player.controls_locked, "recupera los controles tras reaparecer")
	await _wait(1.2)
	_check(not player.is_invulnerable(), "la invulnerabilidad termina")


func _test_dash_levels() -> void:
	player.health.restore_full()
	player.dash_level = 0
	await _reset_at(DASH_OVER_SPIKES)
	await _press("dash")
	await _frames(2)
	_check(not player.is_dashing, "dash nivel 0: no hay dash")
	Input.action_release("dash")

	player.dash_level = 2
	await _reset_at(DASH_OVER_SPIKES)
	await _face_right()
	var hurts_before := _hurts
	await _press("dash")
	await _frames(14)
	Input.action_release("dash")
	_check(_hurts == hurts_before and player.global_position.x > 1152.0,
		"dash nivel 2 (Fantasma): atraviesa los pinchos sin daño (x=%.0f)" % player.global_position.x)
	await _wait(0.5)

	player.dash_level = 1
	await _reset_at(DASH_OVER_SPIKES)
	await _face_right()
	hurts_before = _hurts
	await _press("dash")
	await _frames(14)
	Input.action_release("dash")
	_check(_hurts == hurts_before + 1, "dash nivel 1: no protege, los pinchos dañan")
	await _wait(2.0)
	player.dash_level = 2


func _test_knockback_and_contact() -> void:
	player.health.restore_full()
	await _reset_at(Vector2(300, FLOOR_Y))
	# Zona grande: el empuje no alcanza a sacar al jugador (para probar el contacto prolongado).
	var hitbox := _make_enemy_hitbox(Vector2(320, FLOOR_Y - 10), Vector2(240, 60))
	var hurts_before := _hurts
	for i in 30:
		await physics_frame
		if _hurts > hurts_before:
			break
	await _frames(8)  # Tras el congelamiento del impacto
	_check(_hurts == hurts_before + 1 and player.velocity.x < 0.0, "un golpe enemigo empuja hacia atrás (vx=%.0f)" % player.velocity.x)
	_check(player.health.current == 3.5, "el golpe enemigo quita medio cristal (quedan %.1f)" % player.health.current)
	await _wait(0.6)
	_check(is_equal_approx((room.get_node("CombatHUD/Masks").get_child(3) as MaskIcon).amount, 0.5), "el HUD muestra el último cristal a la mitad")
	_check(player.global_position.distance_to(Vector2(300, FLOOR_Y)) < 60.0, "un golpe enemigo no hace reaparecer")
	await _wait(1.2)
	_check(_hurts == hurts_before + 2, "el contacto prolongado vuelve a dañar al terminar la invulnerabilidad")
	hitbox.queue_free()
	await _wait(1.2)


func _test_educational_shield() -> void:
	player.health.restore_full()
	await _reset_at(Vector2(300, FLOOR_Y))
	player.hurtbox.immune = true
	player.hurtbox.hit_blocked.connect(_on_blocked)
	var hitbox := _make_enemy_hitbox(Vector2(300, FLOOR_Y - 10), Vector2(40, 40))
	hitbox.damage = 99.0
	await _frames(10)
	_check(_blocked > 0 and player.health.current == 4.0, "escudo educativo: rechaza todo daño (bloqueados: %d)" % _blocked)
	# Primero se retira el golpe y después el escudo (si no, el golpe de 99 alcanzaría a dañar).
	hitbox.queue_free()
	await _frames(2)
	player.hurtbox.immune = false
	player.hurtbox.hit_blocked.disconnect(_on_blocked)
	await _frames(5)


func _test_fall_out() -> void:
	player.health.restore_full()
	await _reset_at(Vector2(200, FLOOR_Y))
	await _wait(0.5)
	var hurts_before := _hurts
	player.teleport_to(Vector2(200, room.bounds.end.y + 200))
	await _wait(1.0)
	_check(_hurts == hurts_before + 1 and player.health.current == 3.0, "caer fuera de la sala quita 1 máscara")
	_check(player.global_position.distance_to(Vector2(200, FLOOR_Y)) < 2.0, "y devuelve al último suelo seguro")
	await _wait(1.2)


func _test_death() -> void:
	player.health.restore_full()
	player.health.take_damage(3.0)
	_check(player.health.current == 1.0, "preparación: queda 1 máscara")
	await _reset_at(BEFORE_FLOOR_SPIKES)
	var deaths_before := _deaths
	Input.action_press("move_right")
	for i in 90:
		await physics_frame
		if _deaths > deaths_before:
			break
	Input.action_release("move_right")
	_check(_deaths == deaths_before + 1, "al perder la última máscara, muere")
	await _wait(1.2)
	_check(player.global_position.distance_to(room.spawn_point.global_position) < 2.0, "reaparece en el punto de control")
	_check(player.health.current == 4.0, "con las 4 máscaras llenas")
	_check(not player.controls_locked, "y con los controles activos")


func _on_blocked(_hit: HitData) -> void:
	_blocked += 1


func _make_enemy_hitbox(at: Vector2, size: Vector2) -> HitboxComponent:
	var hitbox := HitboxComponent.new()
	hitbox.collision_layer = 16
	hitbox.collision_mask = 0
	hitbox.damage = 1.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	hitbox.add_child(shape)
	room.add_child(hitbox)
	hitbox.global_position = at
	return hitbox


func _reset_at(position: Vector2) -> void:
	for action in ["move_left", "move_right", "jump", "dash"]:
		Input.action_release(action)
	player.teleport_to(position)
	player.damage.invulnerable_timer = 0.0
	await _frames(20)


func _face_right() -> void:
	await _press("move_right")
	await _frames(2)
	Input.action_release("move_right")
	await _frames(15)


func _press(action: String) -> void:
	await physics_frame
	Input.action_press(action)


func _frames(count: int) -> void:
	for i in count:
		await process_frame  # Teclas y HUD se procesan en cuadros de dibujo.
		await physics_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])

class_name ProcessWall
extends EnemyBase
## Muro de procesos acumulados (Capítulo 2, después de Bucle): bloquea la salida del simulador. Es un
## bucle: loop_time segundos después del primer golpe se reconstruye entero (con el tiempo de las
## amenazas, CombatClock). Enseña el Dominio Nulo I sin riesgo (no hace daño):
##   sin el Dominio: 4,4 de vida y la Nullblade quita 1 → hacen falta 5 golpes (1,95 s como mínimo) y se
##   reconstruye a los 1,6 s: imposible.
##   con el Dominio: la Nullblade quita 1,1 → 4 golpes (1,5 s) y el bucle tarda 1,6 / 0,8 = 2 s: se rompe.
## Kai no lo atraviesa (tiene un cuerpo sólido); al romperse se desintegra y abre el paso. Su vida (4,4)
## se pone en la escena (max_health).

signal rebuilt
signal broken

@export var height := 110.0
## Segundos (del tiempo de las amenazas) desde el primer golpe hasta reconstruirse.
@export var loop_time := 1.6

var _loop := 0.0
var _clock := 0.0
var _solid: StaticBody2D


func _ready() -> void:
	rank = Rank.ESPECIAL
	ecos_reward = 0
	display_name = "Muro de procesos"
	gravity = 0.0
	knockback_resistance = 1.0
	hurt_time = 0.0
	contact_damage = 0.0
	body_size = Vector2(26, height)
	death_colors = [Color("ffb347"), Color("ff4a6a"), Color.WHITE] as Array[Color]
	super()
	contact.deactivate()
	collision_mask = 0  # No se mueve: no choca con nada (tampoco con su propio cuerpo sólido).
	# Cuerpo sólido (capa del mundo): Kai no pasa mientras el muro exista.
	_solid = StaticBody2D.new()
	_solid.collision_layer = 1
	_solid.collision_mask = 0
	_solid.add_child(_shape_node(body_size))
	add_child(_solid)
	add_collision_exception_with(_solid)


## Encendido: se ve, choca y recibe golpes. Apagado (antes de que el simulador se derrumbe): nada.
func set_enabled(on: bool) -> void:
	visible = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	_solid.collision_layer = 1 if on else 0
	hurtbox.monitoring = on


func is_enabled() -> bool:
	return visible and _solid.collision_layer != 0


## Cuánto falta para reconstruirse (0 a 1; 0 si está entero).
func loop_progress() -> float:
	return clampf(_loop / loop_time, 0.0, 1.0) if health.current < health.max_health else 0.0


func _ai(delta: float) -> void:
	_clock += delta
	velocity = Vector2.ZERO
	if health.current < health.max_health:
		_loop += delta
		if _loop >= loop_time:
			_loop = 0.0
			health.restore_full()
			Sfx.play(&"terminal_ok", 0.7, -6.0)
			rebuilt.emit()
	queue_redraw()


func _on_died() -> void:
	broken.emit()


func _draw() -> void:
	var rect := Rect2(Vector2(-body_size.x / 2.0, -body_size.y), body_size)
	var ratio := health.current / health.max_health
	var font := ThemeDB.fallback_font
	# Bloques de procesos apilados (se apagan los que faltan).
	var rows := int(body_size.y / 12.0)
	for k in rows:
		var row := Rect2(rect.position + Vector2(0, k * 12.0), Vector2(rect.size.x, 10))
		var lit := float(rows - k) / rows <= ratio + 0.001
		draw_rect(row, Color("ffb347", 0.75) if lit else Color("ff4a6a", 0.2))
		draw_rect(row, Color(0.1, 0.05, 0.02), false, 1.0)
	draw_rect(rect, Color.WHITE, false, 1.0)
	# El bucle que lo reconstruye: un anillo que se llena hasta reconstruirlo.
	var center := rect.position + Vector2(rect.size.x / 2.0, -14)
	draw_arc(center, 8.0, 0.0, TAU, 24, Color(1, 1, 1, 0.2), 2.0)
	draw_arc(center, 8.0, -PI / 2.0, -PI / 2.0 + TAU * loop_progress(), 24, Color("ff4a6a"), 2.0)
	draw_string(font, center + Vector2(-3, 3), "↻", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

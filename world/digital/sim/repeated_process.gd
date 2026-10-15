class_name RepeatedProcess
extends EnemyBase
## Proceso repetido (Capítulo 2, nivel 4): una tarea copiada una y otra vez por un ciclo sin salida.
## Pequeño, camina hacia Kai y lo daña al tocarlo. Lo crea un ProcessSpawner; se borra cuando el ciclo
## se corta. Dibujo provisional por código.

const COLOR := Color("ffb347")

@export var speed := 42.0

var _clock := 0.0


func _ready() -> void:
	display_name = "Proceso repetido"
	max_health = 2.0
	body_size = Vector2(16, 16)
	threat_type = &"logica"
	death_colors = [COLOR, Color("ff7a5c"), Color.WHITE] as Array[Color]
	super()


func _ai(delta: float) -> void:
	_clock += delta
	velocity.x = direction_to_player() * speed
	queue_redraw()


## Se deshace (el ciclo que lo creaba se cortó): sin Ecos.
func dissolve() -> void:
	if is_dead:
		return
	ecos_reward = 0
	health.take_damage(health.current)


func _draw() -> void:
	var box := Rect2(Vector2(-8, -16), Vector2(16, 16))
	var bob := sin(_clock * 8.0) * 1.0
	box.position.y += bob
	draw_rect(box, Color(0.12, 0.07, 0.02))
	draw_rect(box, COLOR, false, 1.5)
	draw_string(ThemeDB.fallback_font, box.position + Vector2(3, 12), "↻", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR)

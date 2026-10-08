class_name HealthComponent
extends Node
## Vida de cualquier entidad. Para el jugador son máscaras (al estilo Hollow Knight);
## para los enemigos, puntos de vida.

signal health_changed(current: float, maximum: float)
signal damaged(amount: float)
signal healed(amount: float)
signal died

@export var max_health := 4.0:
	set(value):
		max_health = maxf(value, 1.0)
		current = minf(current, max_health)

var current := 0.0


func _ready() -> void:
	current = max_health


func take_damage(amount: float) -> void:
	if is_dead() or amount <= 0.0:
		return
	current = maxf(current - amount, 0.0)
	damaged.emit(amount)
	health_changed.emit(current, max_health)
	if is_dead():
		died.emit()


func heal(amount: float) -> void:
	if is_dead() or amount <= 0.0 or current >= max_health:
		return
	var before := current
	current = minf(current + amount, max_health)
	healed.emit(current - before)
	health_changed.emit(current, max_health)


func restore_full() -> void:
	current = max_health
	health_changed.emit(current, max_health)


func is_dead() -> bool:
	return current <= 0.0

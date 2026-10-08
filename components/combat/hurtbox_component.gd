class_name HurtboxComponent
extends Area2D
## Zona que recibe daño. Revisa cada cuadro de física los HitboxComponent superpuestos,
## así un contacto prolongado vuelve a dañar cuando termina la invulnerabilidad.
## Recibe como máximo un golpe por cuadro.

signal hit_received(hit: HitData)
## Golpe rechazado por el escudo educativo (para mostrar un efecto de "bloqueado").
signal hit_blocked(hit: HitData)

## Escudo educativo: rechaza todo daño, sin importar multiplicadores ni evoluciones.
## Solo debe desactivarse al resolver el reto de ciberseguridad correspondiente.
@export var immune := false

## Si se asigna, se consulta antes de aceptar un golpe (p. ej. invulnerabilidad del jugador).
var can_be_hit: Callable


func _ready() -> void:
	monitoring = true
	monitorable = false


func _physics_process(_delta: float) -> void:
	if can_be_hit.is_valid() and not can_be_hit.call():
		return
	for area in get_overlapping_areas():
		var hitbox := area as HitboxComponent
		if hitbox == null or (owner != null and hitbox.owner == owner):
			continue
		var hit := hitbox.try_hit(self)
		if hit == null:
			continue
		if immune:
			hit_blocked.emit(hit)
		else:
			hit_received.emit(hit)
		return

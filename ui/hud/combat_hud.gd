extends CanvasLayer
## HUD de combate: máscaras de integridad, créditos, indicador de la Visión Digital y mensajes.
## La energía y la carga del Dominio Nulo se agregarán en la tarea C5.

@export var player: Player

@onready var _masks: HBoxContainer = $Masks


func _ready() -> void:
	if player == null:
		return
	player.health.health_changed.connect(_refresh)
	_refresh(player.health.current, player.health.max_health)


func _refresh(current: float, maximum: float) -> void:
	var count := int(maximum)
	while _masks.get_child_count() < count:
		_masks.add_child(MaskIcon.new())
	while _masks.get_child_count() > count:
		var extra := _masks.get_child(_masks.get_child_count() - 1)
		_masks.remove_child(extra)
		extra.queue_free()
	for i in count:
		(_masks.get_child(i) as MaskIcon).filled = i < ceili(current)

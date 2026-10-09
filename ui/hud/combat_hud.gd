extends CanvasLayer
## HUD de combate: los cristales de integridad (vidas), la barra de energía, créditos, indicador
## de la Visión Digital y mensajes. Cada cristal vale 1 de vida: completo, a la mitad o vacío.
## La energía se usará en habilidades futuras: set_energy() la actualiza (por ahora está llena).

@export var player: Player

var _first_refresh := true

@onready var _masks: HBoxContainer = $Masks
@onready var _energy: EnergyBar = $EnergyBar


func _ready() -> void:
	if player == null:
		return
	player.health.health_changed.connect(_refresh)
	_refresh(player.health.current, player.health.max_health)
	# Cuando el jugador tenga energía (habilidades futuras), basta con que emita energy_changed.
	if player.has_signal(&"energy_changed"):
		player.connect(&"energy_changed", set_energy)


## Energía para habilidades (de 0 a máximo).
func set_energy(current: float, maximum: float) -> void:
	var target := clampf(current / maxf(maximum, 0.001), 0.0, 1.0)
	create_tween().tween_property(_energy, "ratio", target, 0.25)


func _refresh(current: float, maximum: float) -> void:
	var count := ceili(maximum)
	while _masks.get_child_count() < count:
		_masks.add_child(MaskIcon.new())
	while _masks.get_child_count() > count:
		var extra := _masks.get_child(_masks.get_child_count() - 1)
		_masks.remove_child(extra)
		extra.queue_free()
	for i in count:
		var icon := _masks.get_child(i) as MaskIcon
		var amount := clampf(current - i, 0.0, 1.0)
		if _first_refresh:
			icon.set_amount_instant(amount)
		else:
			icon.amount = amount
	_first_refresh = false

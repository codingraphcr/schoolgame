extends CanvasLayer
## HUD de combate: los cristales de integridad (vidas), las barritas de energía, créditos,
## indicador de la Visión Digital y mensajes. Cada cristal vale 1 de vida: completo, a la mitad o
## vacío. Las barritas de energía salen de GameState.max_energy_cells (suben con la historia) y se
## gastarán en habilidades futuras: set_energy() las actualiza (por ahora están llenas).
## Con G (acción "grimorio") se abre el Grimorio encima del juego, que queda en pausa.

@export var player: Player

var _first_refresh := true

@onready var _masks: HBoxContainer = $Masks
@onready var _energy: EnergyBar = $EnergyBar


func _ready() -> void:
	GameSettings.ensure_loaded()
	var game_state := get_node_or_null("/root/GameState")
	if game_state:
		game_state.progress_changed.connect(_refresh_energy_cells)
	_refresh_energy_cells()
	if player == null:
		return
	player.health.health_changed.connect(_refresh)
	_refresh(player.health.current, player.health.max_health)
	# Cuando el jugador tenga energía (habilidades futuras), basta con que emita energy_changed.
	if player.has_signal(&"energy_changed"):
		player.connect(&"energy_changed", set_energy)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"grimorio") and _can_open_grimorio():
		get_viewport().set_input_as_handled()
		GrimorioScreen.open(self)


## Energía para habilidades (de 0 a máximo); se reparte entre las barritas.
## Si sube (un golpe acertado), la barra hace un pulso violeta breve.
func set_energy(current: float, maximum: float) -> void:
	var target := clampf(current / maxf(maximum, 0.001), 0.0, 1.0) * _energy.cells
	if target > _energy.energy + 0.001 and not _first_refresh:
		_energy.pulse()
	create_tween().tween_property(_energy, "energy", target, 0.25)


func _refresh_energy_cells() -> void:
	var game_state := get_node_or_null("/root/GameState")
	var cells: int = game_state.max_energy_cells if game_state else GameState.START_ENERGY_CELLS
	var was_full := is_equal_approx(_energy.energy, _energy.cells)
	_energy.cells = cells
	if was_full:
		_energy.energy = cells


## No se abre en medio de un diálogo, de una escena con Kai sin control ni con el juego en pausa.
func _can_open_grimorio() -> bool:
	if get_tree().paused:
		return false
	var box := DialogueBox.find(self)
	if box and box.is_playing():
		return false
	return player == null or not player.controls_locked


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

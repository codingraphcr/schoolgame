class_name DataFragment
extends Area2D
## Fragmento de datos oculto en la red: solo se puede recoger con la Visión Digital activa.
## Da Ecos y deja una marca en GameState para no volver a aparecer. El dibujo lo hace
## la capa digital de la sala (que consulta la misma marca).

@export var flag: StringName = &"zona0_fragmento_recogido"
@export var ecos_reward := 15
@export var message := "¡Encontraste un fragmento de datos oculto en la red! (+%d Ecos)"


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # Capa del jugador
	body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	# Por si el jugador ya estaba dentro cuando se encendió la Visión Digital.
	if _can_collect():
		for body in get_overlapping_bodies():
			_on_body_entered(body)


func _on_body_entered(body: Node) -> void:
	if not body is Player or not _can_collect():
		return
	var game_state := get_node("/root/GameState")
	game_state.set_flag(flag)
	var gained: int = get_node("/root/Economy").claim_reward(StringName("fragmento:%s" % flag), ecos_reward)
	get_tree().call_group(&"toast", &"show_message", message % gained)


func _can_collect() -> bool:
	var game_state := get_node_or_null("/root/GameState")
	var vision := get_node_or_null("/root/DigitalVision")
	return game_state != null and vision != null and vision.is_active() and not game_state.has_flag(flag)

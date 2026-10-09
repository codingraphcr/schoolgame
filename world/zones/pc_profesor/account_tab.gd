extends Interactable
## La pestaña "Cambiar contraseña" de la cuenta del profesor. Se puede usar cuando la misión llega a
## "cambiar_contrasena" (después de cruzar el SPAM y revisar la configuración en la terminal). Allí empezará el combate contra la
## "Contraseña débil" con la mini espada (tarea H4c).

const CYAN := Color("3ef2ff")

@export var account_window: Node2D


func _ready() -> void:
	super()
	interacted.connect(_on_interacted)


func _process(delta: float) -> void:
	var step: StringName = get_node("/root/GameState").get_current_step(&"contrasena_profesor")
	var usable := step == &"cambiar_contrasena"
	enabled = usable
	if account_window:
		account_window.set("tab_ready", usable)
		account_window.set("revealed", step not in [&"entrar_pc", &"cruzar_spam", &"revisar_configuracion"])
	super(delta)


func _on_interacted(_player: Player) -> void:
	# Provisional hasta la tarea H4c (combate con la mini espada).
	get_tree().call_group(&"toast", &"show_message",
		"Próximamente: el combate contra la «Contraseña débil» con la mini espada (tarea H4c).", 4.0, CYAN)

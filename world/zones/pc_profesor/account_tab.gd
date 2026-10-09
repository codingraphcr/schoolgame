extends Interactable
## La pestaña "Cambiar contraseña" de la cuenta del profesor. En el paso "cambiar_contrasena"
## (después de cruzar el SPAM y revisar la configuración en la terminal) inicia el combate contra la
## "Contraseña débil" (PasswordFight). En "elegir_seguridad" vendrán las 2 elecciones (tarea H4d).

const CYAN := Color("3ef2ff")
const QUEST := &"contrasena_profesor"

@export var account_window: Node2D
@export var fight: PasswordFight


func _ready() -> void:
	super()
	interacted.connect(_on_interacted)


func _process(delta: float) -> void:
	var step: StringName = get_node("/root/GameState").get_current_step(QUEST)
	var fighting := fight != null and fight.running
	var usable := step in [&"cambiar_contrasena", &"elegir_seguridad"] and not fighting
	enabled = usable
	prompt_text = "E: elegir la nueva contraseña" if step == &"elegir_seguridad" else "E: cambiar la contraseña"
	if account_window:
		account_window.set("tab_ready", usable)
		account_window.set("revealed", step not in [&"entrar_pc", &"cruzar_spam", &"revisar_configuracion"])
	super(delta)


func _on_interacted(player: Player) -> void:
	var step: StringName = get_node("/root/GameState").get_current_step(QUEST)
	if step == &"cambiar_contrasena" and fight:
		fight.start(player)
	else:
		# Provisional hasta la tarea H4d (elegir contraseña y verificación en dos pasos).
		get_tree().call_group(&"toast", &"show_message",
			"Próximamente: elegir la nueva contraseña y la verificación en dos pasos (tarea H4d).", 4.0, CYAN)

extends Interactable
## La pestaña "Cambiar contraseña" de la cuenta del profesor. En el paso "cambiar_contrasena"
## (después de cruzar el SPAM y revisar la configuración en la terminal) inicia el combate contra la
## "Contraseña débil" (PasswordFight). En "elegir_seguridad" abre las 2 elecciones (AccountSecurity).

const QUEST := &"contrasena_profesor"

@export var account_window: Node2D
@export var fight: PasswordFight
@export var security: AccountSecurity


func _ready() -> void:
	super()
	interacted.connect(_on_interacted)


func _process(delta: float) -> void:
	var step: StringName = get_node("/root/GameState").get_current_step(QUEST)
	var busy_here := (fight != null and fight.running) or (security != null and security.running)
	var usable := step in [&"cambiar_contrasena", &"elegir_seguridad"] and not busy_here
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
	elif step == &"elegir_seguridad" and security:
		security.start(player)

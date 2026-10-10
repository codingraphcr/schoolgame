class_name GrimorioEntry
extends Resource
## Una página del Grimorio (el glosario del juego): un concepto, una amenaza, un comando, un
## registro de la historia o una zona del mapa. Un .tres por entrada en data/grimorio/.
## Mientras no se desbloquea aparece como «???».

enum Category { MAPA, COMANDOS, AMENAZAS, CONCEPTOS, REGISTROS, ARSENAL }

@export var category := Category.CONCEPTOS
## Orden dentro de su categoría (de menor a mayor).
@export var order := 0
@export var title := ""
## Línea pequeña bajo el título (p. ej. "Amenaza · Correo").
@export var subtitle := ""
@export_multiline var text := ""
## Datos breves para el recuadro de la derecha: { "Peligro": "Medio", ... }.
@export var facts: Dictionary[String, String] = {}
## Acción cuya tecla se muestra en los datos (solo para comandos), p. ej. &"vision".
@export var action: StringName = &""
@export var image: Texture2D

@export_group("Desbloqueo")
## Misión que lo desbloquea (vacío = disponible desde el principio).
@export var unlock_quest: StringName = &""
## Paso de esa misión al que hay que llegar (vacío = basta con empezarla).
@export var unlock_step: StringName = &""
## Si la misión tiene que estar terminada.
@export var unlock_on_complete := false
## Propiedad de GameState que tiene que ser verdadera o mayor que 0 (p. ej. vision_unlocked).
@export var unlock_property: StringName = &""
## Comando de terminal que Kai tiene que haber usado (p. ej. &"ls"): la página del manual de comandos.
@export var unlock_command: StringName = &""
## Marca de GameState que tiene que existir (p. ej. &"bits_descubiertos").
@export var unlock_flag: StringName = &""


func is_unlocked(game_state: Node) -> bool:
	if game_state == null:
		return unlock_quest == &"" and unlock_property == &"" and unlock_command == &"" and unlock_flag == &""
	if unlock_property != &"" and not game_state.get(unlock_property):
		return false
	if unlock_flag != &"" and not game_state.has_flag(unlock_flag):
		return false
	if unlock_command != &"" and not game_state.has_learned_command(unlock_command):
		return false
	if unlock_quest == &"":
		return true
	if unlock_on_complete:
		return game_state.is_quest_completed(unlock_quest)
	return game_state.has_reached_step(unlock_quest, unlock_step)

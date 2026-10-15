class_name CreatureEntry
extends Resource
## Una criatura digital del bestiario del Grimorio (docs/criaturas/BESTIARIO_DIGITAL.md). Se registra con la
## Visión Digital, sin tener que vencerla, en tres etapas (Bestiary):
##   1. Avistamiento : verla con la Visión activa.
##   2. Observación  : seguir mirándola un rato (observe_seconds) con la Visión.
##   3. Comprensión  : entender su función (cuando la partida tiene understand_flag, p. ej. al terminar
##                     una misión con ella).
## Cada etapa muestra más información en el Grimorio.

@export var id: StringName = &""
@export var display_name := ""
## Región (bioma) donde vive: WorldRegion.id.
@export var biome: StringName = &""
@export_multiline var appearance := ""
@export_multiline var behavior := ""
## Qué hace en su ecosistema.
@export_multiline var function := ""
## Concepto informático que representa.
@export var concept := ""
## Lo que piensa Kai en cada etapa (1, 2 y 3).
@export var kai_notes: PackedStringArray = ["", "", ""]
@export var observe_seconds := 2.5
@export var understand_flag: StringName = &""

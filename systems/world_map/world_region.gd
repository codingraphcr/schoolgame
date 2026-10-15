class_name WorldRegion
extends Resource
## Una región del mundo (docs/mundo/MAPA_MAESTRO.md): del mundo físico (inspirado en Costa Rica) o un bioma
## del mundo digital. Agrupa distritos de World (las salas jugables); una región sin distritos todavía no
## existe en el juego, pero ya tiene su lugar en el mapa del Grimorio (con niebla).
## Registro de todas: WorldAtlas.

enum Kind { FISICA, DIGITAL }

@export var id: StringName = &""
@export var display_name := ""
@export var kind := Kind.FISICA
@export_multiline var description := ""
## Conceptos informáticos que representa (biomas) o función en la historia (regiones físicas).
@export var concepts: PackedStringArray = []
## Distritos de World que forman la región (los que existen en el juego).
@export var districts: PackedStringArray = []
## Secreta: no aparece en el mapa (ni con niebla) hasta descubrirla (reveal).
@export var secret := false
## Con esto la región se deja ver en el mapa (con su nombre) aunque Kai no haya entrado.
@export var reveal: WorldRequirement
## Lugar y tamaño en el mapa del Grimorio, en celdas.
@export var map_position := Vector2.ZERO
@export var map_size := Vector2(2, 1)
@export var color := Color("6a7ab8")

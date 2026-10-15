class_name Keepsake
extends Resource
## Un objeto que Kai guarda en su cuarto: un recuerdo, un Fragmento de Datos o un regalo. Se ve en su
## estantería cuando la partida tiene unlock_flag (vacía = desde el principio) y se puede inspeccionar
## (InspectionWindow): nombre, descripción y lo que Kai piensa de él según la etapa (notes).
##
## No guarda nada propio: lo que dice si está desbloqueado son las marcas de GameState, que van en la
## ranura de guardado (cada partida tiene su colección y nada se consigue dos veces). Los Fragmentos de
## Datos usan las mismas marcas que sus recolectores (DataFragment, el cierre de Chip y Glitch). No son
## moneda: los Ecos se cobran donde se recogen. Registro de todos los objetos: HomeCollection.

enum Category { RECUERDO, FRAGMENTO, REGALO }

@export var id: StringName = &""
@export var display_name := ""
@export var category := Category.RECUERDO
@export_multiline var description := ""
## Marca de GameState con la que aparece (vacía = desde el principio).
@export var unlock_flag: StringName = &""
## Lo que piensa Kai, de menos a más avanzado en la historia (se usa el último que valga).
@export var notes: Array[KeepsakeNote] = []
## Texto del objeto mismo (p. ej. lo que leyó el Grimorio en un Fragmento de Datos), opcional.
@export var data_lines: PackedStringArray = []
## Dibujo provisional (KeepsakeArt) mientras no haya arte definitivo en texture.
@export var art: StringName = &""
@export var texture: Texture2D
## Lugar en su estantería (0 = el primero, a la izquierda arriba).
@export var shelf_slot := 0


func is_unlocked(state: Node) -> bool:
	return unlock_flag == &"" or state.has_flag(unlock_flag)


## Lo que piensa Kai ahora ("" si no tiene ninguno que valga).
func note_for(state: Node) -> String:
	var result := ""
	for note in notes:
		if note and note.applies(state):
			result = note.text
	return result

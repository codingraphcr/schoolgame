class_name KeepsakeNote
extends Resource
## Lo que Kai piensa de un objeto de su casa en una etapa de la historia (recuerdos dinámicos). Vale si
## la partida llegó al capítulo min_chapter y tiene la marca requires_flag (vacía = no pide ninguna).
## Un objeto puede tener varios: se usa el último de su lista que valga (ordenarlos de menos a más
## avanzado). Así el mismo robot dice una cosa en décimo y otra en duodécimo sin tocar el código.

@export var min_chapter := 0
@export var requires_flag: StringName = &""
@export_multiline var text := ""


func applies(state: Node) -> bool:
	if ProgressTracker.chapter(state) < min_chapter:
		return false
	return requires_flag == &"" or state.has_flag(requires_flag)

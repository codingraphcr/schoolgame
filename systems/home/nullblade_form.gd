class_name NullbladeForm
extends Resource
## Una forma de la Nullblade para el soporte del cuarto de Kai (NullbladeStand). Se conoce cuando
## GameState.nullblade_stage llega a stage: solo la historia la desbloquea (no se compra con Ecos). Las
## que faltan se ven bloqueadas («???»). El soporte es solo para mirarla: la espada sigue con Kai.

const PATHS: Array[String] = [
	"res://data/home/nullblade/exe.tres",
	"res://data/home/nullblade/zero.tres",
	"res://data/home/nullblade/void.tres",
	"res://data/home/nullblade/max.tres",
]

@export var stage := 1
@export var display_name := ""
@export_multiline var description := ""
@export_multiline var history := ""
@export var abilities: PackedStringArray = []
## Lo que piensa Kai de ella según la etapa (como en los recuerdos).
@export var notes: Array[KeepsakeNote] = []


static func all() -> Array[NullbladeForm]:
	var result: Array[NullbladeForm] = []
	for path in PATHS:
		var form := load(path) as NullbladeForm
		if form:
			result.append(form)
	result.sort_custom(func(a: NullbladeForm, b: NullbladeForm) -> bool: return a.stage < b.stage)
	return result


func is_known(state: Node) -> bool:
	return state.nullblade_stage >= stage


func note_for(state: Node) -> String:
	var result := ""
	for note in notes:
		if note and note.applies(state):
			result = note.text
	return result

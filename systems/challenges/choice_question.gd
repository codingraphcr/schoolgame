class_name ChoiceQuestion
extends Resource
## Una pregunta de un desafío de elección (ChoiceChallenge) con sus opciones.

@export_multiline var prompt := ""
@export var options: Array[ChoiceOption] = []


func correct_index() -> int:
	for i in options.size():
		if options[i].correct:
			return i
	return -1

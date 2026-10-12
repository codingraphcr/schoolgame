class_name ChoiceChallenge
extends Resource
## Desafío educativo de elección: una o más preguntas con opciones. Elegir una opción incorrecta
## muestra por qué no sirve y deja intentar de nuevo; se avanza al elegir la correcta.
## Se muestra con ChoiceWindow. Uno por desafío en data/challenges/.

## Id estable (para el guardado y los registros).
@export var id: StringName = &""
@export var title := ""
@export var questions: Array[ChoiceQuestion] = []

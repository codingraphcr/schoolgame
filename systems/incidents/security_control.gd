class_name SecurityControl
extends Resource
## Medida defensiva que se puede aplicar ante un incidente.
## Cuesta presupuesto y modifica la seguridad y la confianza de la institución.

## Cómo queda la amenaza en el mundo después de aplicar la medida (para mostrar la consecuencia).
enum Outcome {
	ELIMINATED,  ## La amenaza desaparece.
	CONTAINED,   ## Sigue ahí, pero ya no puede hacer daño.
	REDUCED,     ## Se debilita, pero puede volver.
	WORSENED,    ## Se propaga.
}

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var cost := 0
@export_range(-100, 100) var security_delta := 0
@export_range(-100, 100) var trust_delta := 0
@export var outcome := Outcome.REDUCED

@export_group("Retroalimentación")
## Qué ocurre en el colegio después de la decisión.
@export_multiline var consequence := ""
## Lo que comenta la comunidad educativa (puede decirlo un NPC).
@export_multiline var reaction := ""
## Concepto de ciberseguridad que enseña esta decisión.
@export_multiline var lesson := ""

@export_group("Consecuencias futuras")
## Marcas que se guardan en GameState para que niveles posteriores reaccionen.
@export var flags_to_set: Array[StringName] = []

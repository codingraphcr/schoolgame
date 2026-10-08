class_name Incident
extends Resource
## Incidente de ciberseguridad: la amenaza, sus pistas y las medidas posibles.
## Cada incidente es un archivo .tres en data/incidents/: una amenaza nueva no requiere código.

enum State {
	INACTIVE,       ## Aún no ha comenzado.
	INVESTIGATING,  ## El jugador busca pistas.
	READY,          ## Hay evidencia suficiente para decidir en la terminal.
	RESOLVED,       ## Ya se aplicó una medida.
}

@export var id: StringName
@export var title := ""
## Tipo de amenaza, con los mismos nombres que docs/combate.md:
## credenciales, phishing, malware, ransomware, disponibilidad, vulnerabilidad, ingenieria_social.
@export var threat_type: StringName
@export_multiline var briefing := ""
@export var clues: Array[Clue] = []
## Pistas necesarias para poder decidir.
@export var clues_to_decide := 2
@export var controls: Array[SecurityControl] = []


func has_control(control: SecurityControl) -> bool:
	return control in controls


func has_clue(clue: Clue) -> bool:
	return clue in clues

class_name Announcement
extends Resource
## Un aviso del tablón de anuncios del colegio (NoticeBoard): actividades escolares, misiones opcionales y
## anuncios de la historia. Aparece cuando la partida cumple requirement (capítulo, marcas, misiones) y deja de
## aparecer con hidden_flag (p. ej. una actividad que ya pasó). Es solo texto: no lleva calendario.

enum Kind { ACTIVIDAD, MISION, AVISO }

const KIND_NAMES: Array[String] = ["Actividad", "Misión opcional", "Aviso"]

@export var id: StringName = &""
@export var title := ""
@export var kind := Kind.AVISO
@export_multiline var text := ""
## Lo que piensa Kai al leerlo (opcional, breve).
@export var kai_note := ""
@export var requirement: WorldRequirement
@export var hidden_flag: StringName = &""
## Color del papel en el tablón.
@export var paper := Color("f4f0e4")


func is_visible_for(state: Node) -> bool:
	if requirement and not requirement.is_met(state):
		return false
	return hidden_flag == &"" or not state.has_flag(hidden_flag)

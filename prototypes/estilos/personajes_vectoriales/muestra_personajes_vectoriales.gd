extends "res://prototypes/estilos/pixel/muestra_pixel.gd"
## Muestra F: personajes vectoriales sobre escenarios en pixel art.
## Kai y el Anzuelo son los de la muestra B (formas suaves, huesos); el escenario es el de la A.
## Sirve para ver cómo conviven los dos estilos cuando se mezclan directamente.

const VectorKai := preload("res://prototypes/estilos/vectorial/vector_kai.gd")
const VectorLure := preload("res://prototypes/estilos/vectorial/vector_lure.gd")


func _init() -> void:
	super()
	sample_title = "MUESTRA F · Personajes vectoriales sobre escenarios en pixel art"
	sample_hint = "Kai y el Anzuelo son vectoriales (suaves); el colegio es pixel art"
	other_sample = "res://prototypes/estilos/pixel/muestra_pixel.tscn"


func _build_art() -> void:
	super()
	_lure.self_modulate.a = 0.0
	_lure.add_child(VectorLure.new())


func _build_player_visual() -> Node2D:
	var kai := VectorKai.new()
	kai.player = player
	return kai

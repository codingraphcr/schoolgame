extends "res://prototypes/estilos/pixel/muestra_pixel.gd"
## Muestra E: huesos pixelados.
## Kai y el Anzuelo se animan por huesos, igual que en la muestra B (animación fluida,
## pocas piezas dibujadas), pero se dibujan a la resolución del pixel art con PixelatedRig.
## El escenario es el mismo pixel art de la muestra A.

const VectorKai := preload("res://prototypes/estilos/vectorial/vector_kai.gd")
const VectorLure := preload("res://prototypes/estilos/vectorial/vector_lure.gd")


func _init() -> void:
	super()
	sample_title = "MUESTRA E · Huesos pixelados: animación por huesos que se ve como pixel art"
	sample_hint = "Kai y el Anzuelo están armados por piezas y huesos, pero se dibujan a resolución de pixel art"
	other_sample = "res://prototypes/estilos/personajes_vectoriales/muestra_personajes_vectoriales.tscn"


func _build_art() -> void:
	super()
	# Oculta el sprite del Anzuelo (el sedal, que es hijo, sigue visible) y pone la versión con huesos.
	_lure.self_modulate.a = 0.0
	var rig := PixelatedRig.new()
	rig.setup(VectorLure.new(), Vector2i(32, 40), Vector2i(16, 18))
	_lure.add_child(rig)


func _build_player_visual() -> Node2D:
	var kai := VectorKai.new()
	kai.player = player
	var rig := PixelatedRig.new()
	rig.setup(kai, Vector2i(48, 52), Vector2i(24, 48))
	return rig

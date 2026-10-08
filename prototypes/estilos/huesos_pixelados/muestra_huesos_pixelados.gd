extends "res://prototypes/estilos/dos_mundos/muestra_dos_mundos.gd"
## Muestra E: huesos pixelados + Visión Digital (estilo elegido para el juego).
## Kai y el Anzuelo se animan por huesos, igual que en la muestra B (animación fluida,
## pocas piezas dibujadas), pero se dibujan a la resolución del pixel art con PixelatedRig.
## El escenario es pixel art (muestra A) y la Visión Digital revela la red en vectorial
## (muestra D): dura 10 s y se recarga en 16 s.

const VectorKai := preload("res://prototypes/estilos/vectorial/vector_kai.gd")
const VectorLure := preload("res://prototypes/estilos/vectorial/vector_lure.gd")


func _init() -> void:
	super()
	sample_title = "MUESTRA E · Huesos pixelados + Visión Digital (estilo elegido)"
	sample_hint = "Q: Visión Digital (dura 10 s, se recarga en 16 s) · Kai y el Anzuelo están animados con huesos y dibujados como pixel art"
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

extends "res://prototypes/estilos/dos_mundos/muestra_dos_mundos.gd"
## Muestra E: huesos pixelados + Visión Digital (estilo elegido para el juego).
## Kai es el esqueleto real del juego (characters/player/kai/): las piezas de
## assets/art/characters/kai/kai_piezas.png animadas con Skeleton2D y dibujadas como pixel art.
## El Anzuelo también se anima por huesos. La Visión Digital (Q) dura 10 s y se recarga en 16 s.

const VectorLure := preload("res://prototypes/estilos/vectorial/vector_lure.gd")

var _kai_rig: KaiVisual


func _init() -> void:
	super()
	sample_title = "MUESTRA E · Huesos pixelados + Visión Digital (estilo elegido)"
	sample_hint = "J: ataque con el Nullblade · Q: Visión Digital (10 s, recarga 16 s) · Kai usa las piezas de assets/art/characters/kai/"
	other_sample = "res://prototypes/estilos/personajes_vectoriales/muestra_personajes_vectoriales.tscn"


func _build_art() -> void:
	super()
	# Oculta el sprite del Anzuelo (el sedal, que es hijo, sigue visible) y pone la versión con huesos.
	_lure.self_modulate.a = 0.0
	var rig := PixelatedRig.new()
	rig.setup(VectorLure.new(), Vector2i(32, 40), Vector2i(16, 18))
	_lure.add_child(rig)


func _build_player_visual() -> Node2D:
	_kai_rig = KaiVisual.new()
	_kai_rig.player = player
	return _kai_rig


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"attack") and _kai_rig:
		get_viewport().set_input_as_handled()
		_kai_rig.attack()
		return
	super(event)

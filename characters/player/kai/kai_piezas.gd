class_name KaiPiezas
## Medidas de las piezas de Kai dibujadas en assets/art/characters/kai/kai_piezas.png
## y estructura de su esqueleto. Lo usan la plantilla (generar_plantilla_kai.gd),
## el esqueleto (generar_esqueleto_kai.gd) y KaiVisual.
## Si cambias el tamaño de una pieza en el dibujo, actualízalo aquí y vuelve a generar el esqueleto.

const TEXTURE := "res://assets/art/characters/kai/kai_piezas.png"
## Separación (px) entre piezas en la imagen, de izquierda a derecha en el orden de PIECES.
const GAP := 2
## Altura de la cadera sobre los pies: muslo (8 px) + pierna hasta la suela (9 px).
const HIP_HEIGHT := 17.0

## Tamaño del lienzo (con 1 px de margen), pivote (punto de giro) y articulaciones de cada pieza.
const PIECES := {
	"cabeza": { "size": Vector2i(16, 16), "pivot": Vector2i(7, 15),
		"joints": { "nuca": Vector2i(4, 10), "flequillo": Vector2i(12, 8), "coronilla": Vector2i(4, 3) } },
	"pelo_atras": { "size": Vector2i(10, 10), "pivot": Vector2i(7, 1), "joints": {} },
	"mechon_frente": { "size": Vector2i(5, 7), "pivot": Vector2i(2, 1), "joints": {} },
	"mechon_atras": { "size": Vector2i(6, 5), "pivot": Vector2i(4, 3), "joints": {} },
	"torso": { "size": Vector2i(16, 17), "pivot": Vector2i(8, 15),
		"joints": { "cuello": Vector2i(8, 1), "hombro": Vector2i(8, 4), "espalda": Vector2i(4, 6), "cintura": Vector2i(5, 13) } },
	"faldon": { "size": Vector2i(12, 7), "pivot": Vector2i(6, 1), "joints": {} },
	"mochila": { "size": Vector2i(11, 13), "pivot": Vector2i(7, 3), "joints": {} },
	"brazo": { "size": Vector2i(9, 12), "pivot": Vector2i(4, 2), "joints": { "codo": Vector2i(4, 9) } },
	"antebrazo": { "size": Vector2i(8, 10), "pivot": Vector2i(3, 2), "joints": { "mano": Vector2i(3, 8) } },
	"muslo": { "size": Vector2i(9, 12), "pivot": Vector2i(4, 2), "joints": { "rodilla": Vector2i(4, 10) } },
	"pierna": { "size": Vector2i(12, 13), "pivot": Vector2i(4, 2), "joints": {} },
	"arma": { "size": Vector2i(9, 24), "pivot": Vector2i(4, 19), "joints": {} },
}

## Esqueleto, de la raíz hacia afuera (cada hueso aparece después de su padre).
## joint: articulación de la pieza del padre donde se une · at: posición fija respecto al padre
## shift: ajuste extra · z: orden de dibujo · back: extremidad de atrás (más oscura)
## spring: se mueve sola con física de resorte (pelo, mechones, faldón, mochila) · weapon: el arma
const RIG := [
	{ "bone": "Cadera", "parent": "", "at": Vector2(0, -HIP_HEIGHT) },
	{ "bone": "Torso", "parent": "Cadera", "piece": "torso", "z": 0 },
	{ "bone": "Cuello", "parent": "Torso", "joint": "cuello", "piece": "cabeza", "z": 2 },
	{ "bone": "PeloAtras", "parent": "Cuello", "joint": "nuca", "piece": "pelo_atras", "z": 1, "spring": true },
	{ "bone": "MechonAtras", "parent": "Cuello", "joint": "coronilla", "piece": "mechon_atras", "z": 3, "spring": true },
	{ "bone": "MechonFrente", "parent": "Cuello", "joint": "flequillo", "piece": "mechon_frente", "z": 3, "spring": true },
	{ "bone": "Mochila", "parent": "Torso", "joint": "espalda", "piece": "mochila", "z": -5, "spring": true },
	{ "bone": "Faldon", "parent": "Torso", "joint": "cintura", "piece": "faldon", "z": -2, "spring": true },
	{ "bone": "BrazoAtras", "parent": "Torso", "joint": "hombro", "shift": Vector2(-2, 0), "piece": "brazo", "z": -4, "back": true },
	{ "bone": "AntebrazoAtras", "parent": "BrazoAtras", "joint": "codo", "piece": "antebrazo", "z": -4, "back": true },
	{ "bone": "MusloAtras", "parent": "Cadera", "at": Vector2(-1, 0), "piece": "muslo", "z": -3, "back": true },
	{ "bone": "PiernaAtras", "parent": "MusloAtras", "joint": "rodilla", "piece": "pierna", "z": -3, "back": true },
	{ "bone": "MusloFrente", "parent": "Cadera", "at": Vector2(1, 0), "piece": "muslo", "z": -1 },
	{ "bone": "PiernaFrente", "parent": "MusloFrente", "joint": "rodilla", "piece": "pierna", "z": -1 },
	{ "bone": "BrazoFrente", "parent": "Torso", "joint": "hombro", "piece": "brazo", "z": 5 },
	{ "bone": "AntebrazoFrente", "parent": "BrazoFrente", "joint": "codo", "piece": "antebrazo", "z": 5 },
	{ "bone": "Mano", "parent": "AntebrazoFrente", "joint": "mano", "piece": "arma", "z": 4, "weapon": true },
]


## Rectángulo de una pieza dentro de la imagen.
static func region(piece: String) -> Rect2i:
	var x := 0
	for piece_name: String in PIECES:
		var size: Vector2i = PIECES[piece_name].size
		if piece_name == piece:
			return Rect2i(Vector2i(x, 0), size)
		x += size.x + GAP
	push_error("KaiPiezas: no existe la pieza '%s'" % piece)
	return Rect2i()


static func pivot(piece: String) -> Vector2:
	return Vector2(PIECES[piece].pivot)


## Posición de una articulación respecto al pivote de su pieza (desplazamiento del hueso hijo).
static func joint_offset(piece: String, joint: String) -> Vector2:
	return Vector2(PIECES[piece].joints[joint]) - pivot(piece)


static func rig_entry(bone: String) -> Dictionary:
	for entry: Dictionary in RIG:
		if entry.bone == bone:
			return entry
	return {}


## Posición de un hueso respecto a su padre, en reposo.
static func bone_offset(entry: Dictionary) -> Vector2:
	var offset: Vector2 = entry.get("at", Vector2.ZERO)
	if entry.has("joint"):
		var parent := rig_entry(entry.parent)
		offset = joint_offset(parent.piece, entry.joint)
	return offset + entry.get("shift", Vector2.ZERO)


## Ruta de un hueso desde la raíz de la escena del esqueleto (p. ej. "Skeleton2D/Cadera/Torso").
static func bone_path(bone: String) -> String:
	var entry := rig_entry(bone)
	if entry.is_empty():
		return ""
	if entry.parent == "":
		return "Skeleton2D/" + bone
	return bone_path(entry.parent) + "/" + bone

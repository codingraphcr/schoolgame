class_name KaiPiezas
## Medidas de las piezas de Kai dibujadas en assets/art/characters/kai/kai_piezas.png:
## tamaño del lienzo (con 1 px de margen), pivote (punto de giro) y articulaciones.
## Las usan la plantilla (generar_plantilla_kai.gd) y el esqueleto (generar_esqueleto_kai.gd).
## Si cambias el tamaño de una pieza en el dibujo, actualízalo aquí y vuelve a generar el esqueleto.

const TEXTURE := "res://assets/art/characters/kai/kai_piezas.png"
## Separación (px) entre piezas en la imagen, de izquierda a derecha en el orden de PIECES.
const GAP := 2

const PIECES := {
	"cabeza": { "size": Vector2i(18, 18), "pivot": Vector2i(9, 16), "joints": { "flequillo": Vector2i(13, 7) } },
	"mechon": { "size": Vector2i(7, 9), "pivot": Vector2i(2, 1), "joints": {} },
	"torso": { "size": Vector2i(14, 16), "pivot": Vector2i(7, 14), "joints": { "cuello": Vector2i(7, 1), "hombro": Vector2i(7, 4), "espalda": Vector2i(3, 6) } },
	"mochila": { "size": Vector2i(10, 12), "pivot": Vector2i(6, 3), "joints": {} },
	"brazo": { "size": Vector2i(8, 11), "pivot": Vector2i(3, 2), "joints": { "codo": Vector2i(3, 8) } },
	"antebrazo": { "size": Vector2i(8, 10), "pivot": Vector2i(3, 2), "joints": { "mano": Vector2i(3, 8) } },
	"muslo": { "size": Vector2i(8, 11), "pivot": Vector2i(3, 2), "joints": { "rodilla": Vector2i(3, 8) } },
	"pierna": { "size": Vector2i(11, 12), "pivot": Vector2i(3, 2), "joints": {} },
	"arma": { "size": Vector2i(9, 22), "pivot": Vector2i(4, 17), "joints": {} },
}


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

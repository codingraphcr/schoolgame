class_name PowerGrid
extends Resource
## Un tablero de distribución eléctrica (el puzzle de la etapa 1 de «Eco en la Red», Capítulo 3): fichas en una
## cuadrícula que se giran de a 90°. La energía entra por la izquierda de source y tiene que salir por la derecha de
## target. Es un rompecabezas digital: no simula electricidad real. Un .tres por tablero en data/puzzles/.
## Las conexiones de cada ficha son una máscara de lados (N = 1, E = 2, S = 4, O = 8); girar = rotar la máscara.

enum Tile { VACIA, RECTA, CURVA, T, CRUZ }

const N := 1
const E := 2
const S := 4
const W := 8
## Lados que conecta cada tipo sin girar.
const BASE_MASKS: Array[int] = [0, N | S, N | E, N | E | S, N | E | S | W]

@export var id: StringName = &""
@export var size := Vector2i(5, 4)
## Tipo de cada ficha (fila por fila).
@export var tiles: PackedInt32Array = []
## Giro inicial de cada ficha (0–3, en cuartos de vuelta en sentido horario).
@export var start_rotations: PackedInt32Array = []
## La celda por la que entra la energía (desde la izquierda) y la que tiene que dejarla salir (hacia la derecha).
@export var source := Vector2i(0, 1)
@export var target := Vector2i(4, 2)


func index_of(cell: Vector2i) -> int:
	return cell.y * size.x + cell.x


static func rotate_mask(mask: int, quarters: int) -> int:
	var result := mask
	for i in posmod(quarters, 4):
		result = ((result << 1) | (result >> 3)) & 15
	return result


func mask_at(rotations: PackedInt32Array, cell: Vector2i) -> int:
	var index := index_of(cell)
	return rotate_mask(BASE_MASKS[tiles[index]], rotations[index])


## Las celdas que reciben energía con estos giros (recorrido desde la fuente).
func powered(rotations: PackedInt32Array) -> Dictionary:
	var result := {}
	if not (mask_at(rotations, source) & W):
		return result
	var queue: Array[Vector2i] = [source]
	result[source] = true
	var directions := { N: Vector2i(0, -1), E: Vector2i(1, 0), S: Vector2i(0, 1), W: Vector2i(-1, 0) }
	var opposite := { N: S, E: W, S: N, W: E }
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		var mask := mask_at(rotations, cell)
		for side: int in directions:
			if not (mask & side):
				continue
			var next: Vector2i = cell + directions[side]
			if next.x < 0 or next.y < 0 or next.x >= size.x or next.y >= size.y or result.has(next):
				continue
			if mask_at(rotations, next) & opposite[side]:
				result[next] = true
				queue.append(next)
	return result


## Si la energía llega de la fuente al núcleo.
func is_solved(rotations: PackedInt32Array) -> bool:
	return powered(rotations).has(target) and bool(mask_at(rotations, target) & E)

class_name DoorSpec
extends Resource
## Una puerta de una plantilla de sala (RoomTemplate): por dónde se puede salir y entrar.
## La posición es una celda de la sala en la cuadrícula del mapa y un lado de esa celda. Dos salas
## solo se conectan si sus puertas quedan enfrentadas en celdas vecinas, de lados opuestos y de
## clases compatibles (RoomGraph lo comprueba): nunca una puerta contra una pared.

enum Side { LEFT, RIGHT, UP, DOWN }
## PASSAGE: borde abierto o pasillo · DOOR: puerta · STAIRS: escalera (arriba/abajo)
## ELEVATOR: ascensor (arriba/abajo) · SECRET: paso oculto (se revela con la Visión Digital)
enum Kind { PASSAGE, DOOR, STAIRS, ELEVATOR, SECRET }

## Id estable dentro de la sala (p. ej. &"este", &"escalera_arriba").
@export var id: StringName = &""
@export var side := Side.RIGHT
## Celda de la sala donde está la puerta (0,0 = esquina superior izquierda de la sala).
@export var cell := Vector2i.ZERO
@export var kind := Kind.PASSAGE
## Entrada de la escena (RoomEntry.id) donde aparece Kai al llegar por esta puerta.
@export var entry_id: StringName = &""


static func opposite(value: DoorSpec.Side) -> DoorSpec.Side:
	match value:
		Side.LEFT: return Side.RIGHT
		Side.RIGHT: return Side.LEFT
		Side.UP: return Side.DOWN
	return Side.UP


## Desplazamiento hacia la celda vecina por ese lado.
static func step(value: DoorSpec.Side) -> Vector2i:
	match value:
		Side.LEFT: return Vector2i.LEFT
		Side.RIGHT: return Vector2i.RIGHT
		Side.UP: return Vector2i.UP
	return Vector2i.DOWN


## Si dos clases de puerta se pueden conectar entre sí (por lados ya comprobados).
static func kinds_match(a: DoorSpec.Kind, b: DoorSpec.Kind) -> bool:
	if a == Kind.SECRET or b == Kind.SECRET:
		# Un paso secreto se abre hacia un paso o una puerta común, nunca a una escalera o ascensor.
		var other := b if a == Kind.SECRET else a
		return other in [Kind.PASSAGE, Kind.DOOR, Kind.SECRET]
	return a == b


## Si una clase de puerta es vertical (escaleras y ascensores van arriba/abajo; el resto, a los lados).
static func is_vertical(kind_value: DoorSpec.Kind) -> bool:
	return kind_value in [Kind.STAIRS, Kind.ELEVATOR]

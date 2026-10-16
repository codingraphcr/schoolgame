class_name RoboticsSim
extends RefCounted
## Base de las simulaciones de las estaciones de robótica (una por tipo: SorterSim, ConveyorSim, AssistantSim).
## run() evalúa las opciones elegidas (una por casilla) y devuelve un RoboticsRun con sus pasos; draw() dibuja la
## simulación en un punto de la animación (progress de 0 a 1 recorre los pasos). Todo es finito: nunca se ejecuta
## nada de verdad y los ciclos tienen un tope de seguridad (SAFETY_LIMIT).

const SAFETY_LIMIT := 12
const INK := Color("e8eef8")
const DIM := Color("8a94a8")
const OK_COLOR := Color("7ee08a")
const BAD := Color("ff6a6a")
const CYAN := Color("3ef2ff")
const BELT := Color("3a4152")


func run(_choices: Array[int]) -> RoboticsRun:
	return RoboticsRun.new()


func draw(_canvas: CanvasItem, _rect: Rect2, _result: RoboticsRun, _progress: float, _t: float) -> void:
	pass


## Cuántos segundos dura la animación de un resultado.
func duration(result: RoboticsRun) -> float:
	return clampf(result.steps.size() * 0.55, 1.5, 7.0)


## Índice del paso que se está mostrando y cuánto avanzó dentro de él (0 a 1).
static func step_at(result: RoboticsRun, progress: float) -> Vector2:
	if result == null or result.steps.is_empty():
		return Vector2(-1, 0)
	var position := clampf(progress, 0.0, 0.9999) * result.steps.size()
	return Vector2(floorf(position), position - floorf(position))


static func choice(choices: Array[int], index: int) -> int:
	return choices[index] if index < choices.size() else 0


static func text(canvas: CanvasItem, pos: Vector2, value: String, size: int, color: Color, width := -1.0,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	canvas.draw_string(ThemeDB.fallback_font, pos, value, align, width, size, color)

class_name RoboticsSlot
extends Resource
## Una casilla del programa de una estación de robótica: un texto («si el objeto es») y las opciones que se pueden
## poner ahí («metal», «papel»...). El jugador las recorre con ◀ ▶; empieza en start.

@export var label := ""
@export var options: PackedStringArray = []
@export var start := 0

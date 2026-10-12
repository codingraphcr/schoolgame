class_name LayoutLink
extends Resource
## Una conexión fija entre dos puertas de un distrito (DistrictLayout). Ver RoomGraph.link().

@export var room_a: StringName = &""
@export var door_a: StringName = &""
@export var room_b: StringName = &""
@export var door_b: StringName = &""
## Habilidades para cruzarla (p. ej. "double_jump"). Un paso secreto ya pide la Visión solo.
@export var requires: PackedStringArray = []
## Solo se cruza de A hacia B (un atajo).
@export var one_way := false

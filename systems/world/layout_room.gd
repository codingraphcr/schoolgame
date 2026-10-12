class_name LayoutRoom
extends Resource
## Una sala fija de un distrito (DistrictLayout): qué ficha usa y en qué celda del mapa está.

## Id único en todo el mundo (p. ej. &"entrada"). Una misma ficha puede usarse en varias salas.
@export var room_id: StringName = &""
## RoomTemplate.id
@export var template_id: StringName = &""
@export var cell := Vector2i.ZERO

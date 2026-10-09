extends CanvasItem
## Parpadeo ocasional (carteles de neón, luces viejas). Se agrega a cualquier Sprite2D o nodo visual.

## Probabilidad de parpadear en cada cuadro.
@export_range(0.0, 1.0) var chance := 0.03
@export_range(0.0, 1.0) var dim_alpha := 0.55
@export_range(0.0, 1.0) var normal_alpha := 0.95


func _process(_delta: float) -> void:
	modulate.a = dim_alpha if randf() < chance else normal_alpha

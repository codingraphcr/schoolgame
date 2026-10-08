class_name PixelatedRig
extends Node2D
## Dibuja un personaje animado por huesos dentro de un SubViewport pequeño
## (1 píxel del viewport = 1 píxel del mundo) y lo muestra con filtro Nearest y transparencia
## de todo o nada: la animación es fluida pero el resultado es pixel art.
## Es la técnica de Dead Cells (allí con modelos 3D) aplicada a huesos 2D.

const CRISP_SHADER := preload("res://components/visual/pixel_crisp.gdshader")

var viewport: SubViewport


## content: el nodo animado. size: tamaño del lienzo en píxeles.
## anchor: punto del lienzo que coincide con el origen de este nodo (p. ej. los pies).
## outline: agrega un contorno de 1 px a la silueta (no hace falta si las piezas ya lo tienen).
func setup(content: Node2D, size: Vector2i, anchor: Vector2i, outline := true) -> void:
	viewport = SubViewport.new()
	viewport.size = size
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(viewport)
	content.position = anchor
	viewport.add_child(content)

	var sprite := Sprite2D.new()
	sprite.texture = viewport.get_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.offset = Vector2(size) * 0.5 - Vector2(anchor)
	var crisp := ShaderMaterial.new()
	crisp.shader = CRISP_SHADER
	if not outline:
		crisp.set_shader_parameter(&"outline_color", Color(0, 0, 0, 0))
	sprite.material = crisp
	add_child(sprite)

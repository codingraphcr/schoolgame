class_name PixelatedRig
extends Node2D
## Dibuja un personaje vectorial animado por huesos dentro de un SubViewport pequeño
## (1 píxel del viewport = 1 píxel del mundo) y lo muestra con filtro Nearest, transparencia
## de todo o nada y contorno de 1 píxel: la animación es fluida pero el resultado es pixel art.
## Es la técnica de Dead Cells (allí con modelos 3D) aplicada a huesos 2D.

const CRISP_SHADER := preload("res://prototypes/estilos/huesos_pixelados/pixel_crisp.gdshader")

var viewport: SubViewport


## content: el nodo vectorial. size: tamaño del lienzo en píxeles.
## anchor: punto del lienzo que coincide con el origen de este nodo (p. ej. los pies).
func setup(content: Node2D, size: Vector2i, anchor: Vector2i) -> void:
	viewport = SubViewport.new()
	viewport.size = size
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	content.position = anchor
	viewport.add_child(content)

	var sprite := Sprite2D.new()
	sprite.texture = viewport.get_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.offset = Vector2(size) * 0.5 - Vector2(anchor)
	var crisp := ShaderMaterial.new()
	crisp.shader = CRISP_SHADER
	sprite.material = crisp
	add_child(sprite)

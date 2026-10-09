extends SceneTree
## Extrae los cuadros de Kai de la hoja de concepto de Ariel (docs/arte/referencias/kai_hoja_concepto.webp)
## y arma las animaciones que usa KaiVisual (apariencia CONCEPTO).
## Ejecutar: godot --headless --path . --script res://tools/art/extraer_kai_concepto.gd
##
## Para cada pose: quita el fondo (relleno desde los bordes, sin tocar la ropa negra), la reduce con la
## MISMA escala que el reposo (Kai de 96 px de alto), limpia el borde y la coloca con los pies siempre
## en el mismo punto. Los cuadros miden 96×128; las poses con efectos anchos (arco del ataque, estela
## del dash) usan un cuadro más ancho, con los pies igual de centrados.
##
## Salidas en assets/art/characters/kai/hd/:
##   kai_hd_<animacion>.png → tira horizontal de cuadros
##   kai_hd.json            → por animación: archivo, tamaño de cuadro, pies, cuadros, fps y bucle

const SOURCE := "res://docs/arte/referencias/kai_hoja_concepto.webp"
const OUT := "res://assets/art/characters/kai/hd/"
const FRAME_HEIGHT := 128
const MIN_FRAME_WIDTH := 96
## Fila de los pies dentro del cuadro.
const FEET_Y := 119
## Alto de Kai en reposo dentro del cuadro: fija la escala de todas las poses.
const KAI_HEIGHT := 96
## Escala a la que se muestra en el mundo (con la cámara ×2, 1 píxel del dibujo = 1 píxel de pantalla).
const WORLD_SCALE := 0.5
const BACKGROUND := Color("0c111a")
const TOLERANCE := 0.05
const OUTLINE := Color("0a0d1c")

## Zona de cada pose en la hoja (1536×1024). anchor_x (opcional): columna de la hoja donde está
## el centro del cuerpo, si el cálculo automático (centro de la cabeza) no sirve.
const POSES := {
	"reposo": { "rect": Rect2i(36, 478, 72, 144) },
	"caminar_1": { "rect": Rect2i(124, 478, 88, 144) },
	"caminar_2": { "rect": Rect2i(220, 478, 94, 144) },
	"correr": { "rect": Rect2i(330, 478, 130, 144) },
	"saltar": { "rect": Rect2i(474, 478, 90, 144) },
	"caer": { "rect": Rect2i(575, 478, 96, 144) },
	"ataque_1": { "rect": Rect2i(686, 478, 160, 144) },
	"ataque_2": { "rect": Rect2i(861, 478, 162, 144), "anchor_x": 928 },  # El arco queda sobre la cabeza.
	"dash": { "rect": Rect2i(1020, 478, 156, 144) },
	"dano": { "rect": Rect2i(1206, 478, 122, 144) },
	"muerte": { "rect": Rect2i(1336, 478, 158, 144) },
}

## Animaciones: poses en orden, cuadros por segundo y si se repiten.
const ANIMATIONS := {
	"quieto": { "poses": ["reposo"], "fps": 1.0, "loop": true },
	"correr": { "poses": ["caminar_1", "correr", "caminar_2", "correr"], "fps": 9.0, "loop": true },
	"saltar": { "poses": ["saltar"], "fps": 1.0, "loop": false },
	"caer": { "poses": ["caer"], "fps": 1.0, "loop": true },
	"dash": { "poses": ["dash"], "fps": 1.0, "loop": false },
	"pared": { "poses": ["caer"], "fps": 1.0, "loop": true },
	"ataque_1": { "poses": ["ataque_1"], "fps": 1.0, "loop": false },
	"ataque_2": { "poses": ["ataque_2"], "fps": 1.0, "loop": false },
	"dano": { "poses": ["dano"], "fps": 1.0, "loop": false },
	"muerte": { "poses": ["muerte"], "fps": 1.0, "loop": false },
}

var _scale := 1.0


func _initialize() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if sheet == null:
		push_error("No se encontró la hoja de concepto: " + SOURCE)
		quit(1)
		return
	sheet.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	# 1. Recorta cada pose y calcula la escala común a partir del reposo.
	var cutouts := {}
	for pose_name: String in POSES:
		cutouts[pose_name] = _cutout(sheet, POSES[pose_name])
	_scale = float(KAI_HEIGHT) / cutouts.reposo.image.get_height()

	# 2. Reduce cada pose y la ubica con los pies en el centro inferior.
	var frames := {}
	for pose_name: String in cutouts:
		frames[pose_name] = _scaled(cutouts[pose_name])

	# 3. Arma las tiras de cada animación.
	var info := {}
	for anim_name: String in ANIMATIONS:
		var anim: Dictionary = ANIMATIONS[anim_name]
		var half := 0
		for pose_name: String in anim.poses:
			half = maxi(half, frames[pose_name].half_width)
		var width := maxi(MIN_FRAME_WIDTH, ceili(half * 2 / 8.0) * 8)
		var strip := Image.create_empty(width * anim.poses.size(), FRAME_HEIGHT, false, Image.FORMAT_RGBA8)
		for i in anim.poses.size():
			var frame: Dictionary = frames[anim.poses[i]]
			var image: Image = frame.image
			var at := Vector2i(i * width + width / 2 - frame.anchor_x, FEET_Y + 1 - image.get_height())
			strip.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), at)
		var file_name := "kai_hd_%s.png" % anim_name
		strip.save_png(OUT + file_name)
		info[anim_name] = {
			"file": file_name, "frame_size": [width, FRAME_HEIGHT], "feet": [width / 2, FEET_Y],
			"frames": anim.poses.size(), "fps": anim.fps, "loop": anim.loop,
		}
		print("%s: %d cuadro(s) de %d×%d" % [file_name, anim.poses.size(), width, FRAME_HEIGHT])
	var json := FileAccess.open(OUT + "kai_hd.json", FileAccess.WRITE)
	json.store_string(JSON.stringify({ "scale": WORLD_SCALE, "animations": info }, "\t"))
	json.close()
	quit()


## Quita el fondo de la zona y recorta la pose. Devuelve la imagen y el centro del cuerpo.
func _cutout(sheet: Image, pose: Dictionary) -> Dictionary:
	var rect: Rect2i = pose.rect
	var region := sheet.get_region(rect)
	_remove_background(region)
	var box := region.get_used_rect()
	var image := region.get_region(box)
	var anchor: float
	if pose.has("anchor_x"):
		anchor = pose.anchor_x - rect.position.x - box.position.x
	else:
		anchor = _head_center(image)
	return { "image": image, "anchor_x": anchor }


## Centro horizontal de la cabeza: marca dónde está el cuerpo aunque la pose tenga un arma o una
## estela hacia un lado. Usa solo la figura conectada más grande (el cuerpo de Kai, sin puntos
## sueltos ni efectos separados) y promedia sus primeras filas (el pelo).
func _head_center(image: Image) -> float:
	var body := _largest_component(image)
	var top := 1 << 30
	for p: Vector2i in body:
		top = mini(top, p.y)
	var total := 0.0
	var count := 0
	for p: Vector2i in body:
		if p.y < top + 22:
			total += p.x
			count += 1
	return total / maxi(count, 1)


func _largest_component(image: Image) -> Array[Vector2i]:
	var w := image.get_width()
	var h := image.get_height()
	var label := PackedInt32Array()
	label.resize(w * h)
	var best: Array[Vector2i] = []
	var current := 0
	for y in h:
		for x in w:
			if label[y * w + x] != 0 or image.get_pixel(x, y).a == 0.0:
				continue
			current += 1
			var component: Array[Vector2i] = []
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			label[y * w + x] = current
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				component.append(p)
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var q := p + Vector2i(dx, dy)
						if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or label[q.y * w + q.x] != 0:
							continue
						if image.get_pixelv(q).a == 0.0:
							continue
						label[q.y * w + q.x] = current
						stack.append(q)
			if component.size() > best.size():
				best = component
	return best


func _scaled(cutout: Dictionary) -> Dictionary:
	var image: Image = (cutout.image as Image).duplicate()
	var size := Vector2i(roundi(image.get_width() * _scale), roundi(image.get_height() * _scale))
	image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0) if c.a >= 0.5 else Color(0, 0, 0, 0))
	# Margen de 1 px para el contorno.
	var padded := Image.create_empty(size.x + 2, size.y + 2, false, Image.FORMAT_RGBA8)
	padded.blit_rect(image, Rect2i(Vector2i.ZERO, size), Vector2i.ONE)
	_clean_edges(padded)
	var anchor := roundi(cutout.anchor_x * _scale) + 1
	return {
		"image": padded, "anchor_x": anchor,
		"half_width": maxi(anchor, padded.get_width() - anchor) + 2,
	}


## Limpia el borde: quita restos del fondo pegados a la silueta y píxeles sueltos,
## y agrega un contorno oscuro uniforme de 1 px.
func _clean_edges(img: Image) -> void:
	var neighbors: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	for pass_index in 2:
		var source := img.duplicate() as Image
		for y in img.get_height():
			for x in img.get_width():
				var c := source.get_pixel(x, y)
				if c.a == 0.0:
					continue
				var empty := 0
				for n in neighbors:
					var q := Vector2i(x, y) + n
					if q.x < 0 or q.y < 0 or q.x >= img.get_width() or q.y >= img.get_height() or source.get_pixelv(q).a == 0.0:
						empty += 1
				var near_background := Vector3(c.r - BACKGROUND.r, c.g - BACKGROUND.g, c.b - BACKGROUND.b).length() < 0.12
				if (empty > 0 and near_background) or empty >= 3:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
	var source := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if source.get_pixel(x, y).a > 0.0:
				continue
			for n in neighbors:
				var q := Vector2i(x, y) + n
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and source.get_pixelv(q).a > 0.0:
					img.set_pixel(x, y, OUTLINE)
					break


## Vuelve transparente el fondo conectado con los bordes de la zona.
func _remove_background(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or seen[p.y * w + p.x]:
			continue
		seen[p.y * w + p.x] = 1
		var c := img.get_pixelv(p)
		if Vector3(c.r - BACKGROUND.r, c.g - BACKGROUND.g, c.b - BACKGROUND.b).length() > TOLERANCE:
			continue
		img.set_pixelv(p, Color(0, 0, 0, 0))
		for step in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			stack.append(p + step)

class_name PixelPainter
extends RefCounted
## Lienzo de pixel art: dibuja píxel a píxel sobre una Image y la guarda como PNG.
## Solo se usa para generar el arte provisional de la muestra (ver generar_sprites.gd).

## Fuente diminuta de 3×5 píxeles para carteles y rótulos (solo mayúsculas y números).
const FONT := {
	"A": ["010", "101", "111", "101", "101"], "B": ["110", "101", "110", "101", "110"],
	"C": ["111", "100", "100", "100", "111"], "D": ["110", "101", "101", "101", "110"],
	"E": ["111", "100", "110", "100", "111"], "F": ["111", "100", "110", "100", "100"],
	"G": ["011", "100", "101", "101", "011"], "H": ["101", "101", "111", "101", "101"],
	"I": ["111", "010", "010", "010", "111"], "J": ["001", "001", "001", "101", "010"],
	"K": ["101", "110", "100", "110", "101"], "L": ["100", "100", "100", "100", "111"],
	"M": ["101", "111", "111", "101", "101"], "N": ["110", "101", "101", "101", "101"],
	"O": ["010", "101", "101", "101", "010"], "P": ["110", "101", "110", "100", "100"],
	"Q": ["010", "101", "101", "110", "011"], "R": ["110", "101", "110", "101", "101"],
	"S": ["011", "100", "010", "001", "110"], "T": ["111", "010", "010", "010", "010"],
	"U": ["101", "101", "101", "101", "111"], "V": ["101", "101", "101", "101", "010"],
	"W": ["101", "101", "111", "111", "101"], "X": ["101", "101", "010", "101", "101"],
	"Y": ["101", "101", "010", "010", "010"], "Z": ["111", "001", "010", "100", "111"],
	"0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
	"2": ["110", "001", "010", "100", "111"], "3": ["110", "001", "010", "001", "110"],
	"4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "110", "001", "110"],
	"6": ["011", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"],
	"8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "110"],
	"#": ["101", "111", "101", "111", "101"], "-": ["000", "000", "111", "000", "000"],
	".": ["000", "000", "000", "000", "010"], " ": ["000", "000", "000", "000", "000"],
}

var image: Image
var width: int
var height: int


func _init(w: int, h: int) -> void:
	width = w
	height = h
	image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


func px(x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < width and y < height:
		image.set_pixel(x, y, color)


func get_px(x: int, y: int) -> Color:
	if x >= 0 and y >= 0 and x < width and y < height:
		return image.get_pixel(x, y)
	return Color.TRANSPARENT


func rect(x: int, y: int, w: int, h: int, color: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			px(xx, yy, color)


func frame(x: int, y: int, w: int, h: int, color: Color) -> void:
	rect(x, y, w, 1, color)
	rect(x, y + h - 1, w, 1, color)
	rect(x, y, 1, h, color)
	rect(x + w - 1, y, 1, h, color)


func ellipse(cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	for yy in range(floori(cy - ry), ceili(cy + ry) + 1):
		for xx in range(floori(cx - rx), ceili(cx + rx) + 1):
			var dx := (xx + 0.5 - cx) / rx
			var dy := (yy + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				px(xx, yy, color)


func line(x0: int, y0: int, x1: int, y1: int, color: Color, thickness := 1) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		rect(x0 - thickness / 2, y0 - thickness / 2, thickness, thickness, color)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


## Contorno exterior: pinta los píxeles vacíos que tocan un píxel pintado.
func outline(color: Color) -> void:
	var source := image.duplicate() as Image
	for y in height:
		for x in width:
			if source.get_pixel(x, y).a > 0.0:
				continue
			for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = Vector2i(x, y) + offset
				if n.x >= 0 and n.y >= 0 and n.x < width and n.y < height and source.get_pixel(n.x, n.y).a > 0.0:
					image.set_pixel(x, y, color)
					break


## Reemplaza un color por otro (útil para variaciones de paleta).
func swap(from: Color, to: Color) -> void:
	for y in height:
		for x in width:
			if image.get_pixel(x, y).is_equal_approx(from):
				image.set_pixel(x, y, to)


## Escribe texto con la fuente de 3×5 (4 px por letra). Devuelve el ancho usado.
func text(x: int, y: int, value: String, color: Color) -> int:
	var start := x
	for ch in value.to_upper():
		var glyph: Array = FONT.get(ch, FONT[" "])
		for row in 5:
			for col in 3:
				if glyph[row][col] == "1":
					px(x + col, y + row, color)
		x += 4
	return x - start


func paste(other: PixelPainter, x: int, y: int) -> void:
	image.blend_rect(other.image, Rect2i(0, 0, other.width, other.height), Vector2i(x, y))


func save(path: String) -> void:
	var error := image.save_png(path)
	if error != OK:
		push_error("No se pudo guardar %s (%s)" % [path, error_string(error)])

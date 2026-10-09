extends SceneTree
## Exporta las animaciones del esqueleto de Kai como tiras de cuadros (PNG) para retocarlas a mano
## en Pixelorama, Aseprite o LibreSprite. KaiVisual las usa si se activa "usar_cuadros".
## Ejecutar (necesita pantalla, NO --headless):
##   godot --path . --script res://characters/player/kai/exportar_cuadros_kai.gd
##
## Salidas en assets/art/characters/kai/cuadros/:
##   kai_<animacion>.png  → tira horizontal de cuadros de FRAME_SIZE (los pies en FEET)
##   kai_cuadros.json     → cantidad de cuadros, velocidad (fps) y si se repite, por animación
## y la vista previa docs/arte/img/kai_cuadros_guia.png.
##
## OJO: volver a exportar sobrescribe los cuadros retocados. Haz una copia antes si ya los editaste.

const OUT := "res://assets/art/characters/kai/cuadros/"
const GUIDE_OUT := "res://docs/arte/img/kai_cuadros_guia.png"
const FRAME_SIZE := Vector2i(72, 72)
const FEET := Vector2i(36, 66)
## Velocidad a la que se ve la carrera en el juego (Kai a 140 px/s; ver KaiVisual.RUN_STRIDE_SPEED).
const RUN_SPEED_SCALE := 1.4

## Por animación: cuadros, si se repite, y cómo se mueven las piezas sueltas
## (run: 0-1 como al correr; vertical: −1 subiendo, +1 cayendo; wave: cuánto se balancean).
const ANIMATIONS := {
	"quieto": { "frames": 6, "loop": true, "run": 0.0, "vertical": 0.0, "wave": 1.0 },
	"correr": { "frames": 8, "loop": true, "run": 1.0, "vertical": 0.0, "wave": 1.0, "speed": RUN_SPEED_SCALE },
	"saltar": { "frames": 3, "loop": false, "run": 0.2, "vertical": -1.0, "wave": 0.3 },
	"caer": { "frames": 3, "loop": true, "run": 0.2, "vertical": 1.0, "wave": 0.6 },
	"dash": { "frames": 3, "loop": false, "run": 1.4, "vertical": 0.0, "wave": 0.2 },
	"pared": { "frames": 4, "loop": true, "run": 0.0, "vertical": 0.4, "wave": 0.5 },
	"ataque_1": { "frames": 6, "loop": false, "run": 0.4, "vertical": 0.0, "wave": 0.4 },
}

var _viewport: SubViewport
var _animation: AnimationPlayer
var _skeleton: Node2D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Este script necesita pantalla: ejecútalo sin --headless.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_viewport = SubViewport.new()
	_viewport.size = FRAME_SIZE
	_viewport.transparent_bg = true
	_viewport.disable_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(_viewport)
	_skeleton = load("res://characters/player/kai/kai_esqueleto.tscn").instantiate()
	_skeleton.position = FEET
	_viewport.add_child(_skeleton)
	_animation = _skeleton.get_node("AnimationPlayer")
	await process_frame

	var info := {}
	var strips: Array = []
	for anim_name: String in ANIMATIONS:
		var config: Dictionary = ANIMATIONS[anim_name]
		var strip := await _export(anim_name, config)
		strip.save_png(OUT + "kai_%s.png" % anim_name)
		strips.append([anim_name, strip])
		var length: float = _animation.get_animation(anim_name).length / config.get("speed", 1.0)
		info[anim_name] = {
			"frames": config.frames,
			"fps": snappedf(config.frames / length, 0.1) if config.loop else snappedf((config.frames - 1) / length, 0.1),
			"loop": config.loop,
		}
	var file := FileAccess.open(OUT + "kai_cuadros.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({ "frame_size": [FRAME_SIZE.x, FRAME_SIZE.y], "feet": [FEET.x, FEET.y], "animations": info }, "\t"))
	file.close()
	_save_guide(strips)
	print("Cuadros exportados en ", OUT)
	quit()


func _export(anim_name: String, config: Dictionary) -> Image:
	var frames: int = config.frames
	var strip := Image.create_empty(FRAME_SIZE.x * frames, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	var length := _animation.get_animation(anim_name).length
	_animation.play(anim_name)
	_animation.pause()
	for i in frames:
		var u := float(i) / frames if config.loop else float(i) / maxi(frames - 1, 1)
		_animation.seek(length * u, true)
		_pose_springs(config, u)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var image := _viewport.get_texture().get_image()
		image.convert(Image.FORMAT_RGBA8)
		_crisp(image)
		strip.blit_rect(image, Rect2i(Vector2i.ZERO, FRAME_SIZE), Vector2i(i * FRAME_SIZE.x, 0))
	return strip


## Coloca las piezas sueltas (pelo, mechones, faldón, mochila) como las movería KaiVisual.
func _pose_springs(config: Dictionary, u: float) -> void:
	for bone_name: String in KaiVisual.SPRINGS:
		var spring: Dictionary = KaiVisual.SPRINGS[bone_name]
		var wave: float = sin(u * TAU * (2.0 if config.run > 0.5 else 1.0) + spring.stiffness) * maxf(spring.sway, 4.0) * config.wave
		var angle: float = spring.run * config.run + spring.fall * config.vertical + wave
		(_skeleton.get_node(KaiPiezas.bone_path(bone_name)) as Node2D).rotation = deg_to_rad(angle)


## Transparencia de todo o nada (como el shader pixel_crisp): bordes nítidos de pixel art.
func _crisp(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0) if c.a >= 0.45 else Color(0, 0, 0, 0))


## Vista previa: todas las tiras una debajo de otra, ampliadas ×3, con su nombre.
func _save_guide(strips: Array) -> void:
	const SCALE := 3
	var max_frames := 0
	for item: Array in strips:
		max_frames = maxi(max_frames, item[1].get_width() / FRAME_SIZE.x)
	var row_height := FRAME_SIZE.y + 10
	var guide := PixelPainter.new(FRAME_SIZE.x * max_frames + 4, row_height * strips.size() + 4)
	guide.rect(0, 0, guide.width, guide.height, Color("1b2033"))
	for i in strips.size():
		var strip: Image = strips[i][1]
		var y := 2 + i * row_height
		for f in strip.get_width() / FRAME_SIZE.x:
			guide.frame(2 + f * FRAME_SIZE.x, y + 8, FRAME_SIZE.x, FRAME_SIZE.y, Color("26355e"))
		guide.image.blend_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(2, y + 8))
		guide.text(4, y + 1, String(strips[i][0]).to_upper().replace("_", " "), Color("c9d3ee"))
	guide.image.resize(guide.width * SCALE, guide.height * SCALE, Image.INTERPOLATE_NEAREST)
	guide.save(GUIDE_OUT)

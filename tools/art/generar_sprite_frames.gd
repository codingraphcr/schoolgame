extends SceneTree
## Crea el SpriteFrames de un NPC a partir de las tiras que genera extraer_personajes_concepto.gd.
## Ejecutar: godot --headless --path . --script res://tools/art/generar_sprite_frames.gd
##
## Cada animación del .json (idle, talk, walk...) pasa a ser una animación del SpriteFrames.
## Los cuadros son de 96×128 con los pies en (48, 119): en la escena, el Sprite va con
## scale 0.5 y offset (0, -55) para que los pies queden en el origen del NPC.

## json de las tiras → SpriteFrames de salida.
const NPCS := {
	"res://assets/art/characters/profesor/hd/profesor_hd.json": "res://characters/npcs/profesor/profesor_frames.tres",
}


func _initialize() -> void:
	for source: String in NPCS:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source))
		var frames := SpriteFrames.new()
		frames.remove_animation(&"default")
		var animations: Dictionary = data["animations"]
		for anim: String in animations:
			var info: Dictionary = animations[anim]
			var sheet := load(source.get_base_dir().path_join(info["file"])) as Texture2D
			var size := Vector2(info["frame_size"][0], info["frame_size"][1])
			frames.add_animation(anim)
			frames.set_animation_speed(anim, info["fps"])
			frames.set_animation_loop(anim, info["loop"])
			for i in int(info["frames"]):
				var atlas := AtlasTexture.new()
				atlas.atlas = sheet
				atlas.region = Rect2(Vector2(size.x * i, 0), size)
				frames.add_frame(anim, atlas)
		var error := ResourceSaver.save(frames, NPCS[source])
		print(NPCS[source].get_file(), " ", animations.keys(), " error=", error)
	quit()

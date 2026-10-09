extends SceneTree
## Genera characters/player/kai/kai_esqueleto.tscn: Skeleton2D con los huesos de Kai (KaiPiezas.RIG),
## una pieza (Sprite2D) de kai_piezas.png pegada a cada hueso y un AnimationPlayer con las animaciones.
## Ejecutar: godot --headless --path . --script res://characters/player/kai/generar_esqueleto_kai.gd
##
## Después de generarla, la escena se puede abrir y retocar en el editor (poses, tiempos, capas).
## OJO: volver a ejecutar este script sobrescribe esos retoques.
##
## Ángulos de las poses: en grados, positivo = hacia adelante (hacia donde mira Kai).
## El pelo, los mechones, el faldón y la mochila no se animan aquí: los mueve KaiVisual con resortes.

const OUT := "res://characters/player/kai/kai_esqueleto.tscn"
const BACK_TINT := Color(0.72, 0.72, 0.82)

## Nombre corto de cada articulación animada → hueso.
const JOINTS := {
	"torso": "Torso", "cuello": "Cuello",
	"brazo_f": "BrazoFrente", "codo_f": "AntebrazoFrente", "brazo_b": "BrazoAtras", "codo_b": "AntebrazoAtras",
	"muslo_f": "MusloFrente", "rodilla_f": "PiernaFrente", "muslo_b": "MusloAtras", "rodilla_b": "PiernaAtras",
}

## Articulaciones que apuntan hacia arriba (torso y cabeza): para inclinarlas hacia adelante
## se giran al revés que los brazos y las piernas, que cuelgan hacia abajo.
const UP_JOINTS := ["torso", "cuello"]

## Pose neutra: brazos y piernas relajados.
const NEUTRAL := {
	"torso": 0.0, "cuello": 0.0, "brazo_f": 6.0, "codo_f": 12.0, "brazo_b": -6.0, "codo_b": 12.0,
	"muslo_f": 3.0, "rodilla_f": 0.0, "muslo_b": -3.0, "rodilla_b": 0.0, "y": 0.0, "arma": false,
}

var _texture: Texture2D


func _initialize() -> void:
	_texture = load(KaiPiezas.TEXTURE)
	var root := Node2D.new()
	root.name = "KaiEsqueleto"
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_skeleton(root)
	_build_animations(root)
	_set_owner_recursive(root, root)
	var scene := PackedScene.new()
	var error := scene.pack(root)
	if error == OK:
		error = ResourceSaver.save(scene, OUT)
	print("kai_esqueleto.tscn: ", error_string(error))
	root.free()
	quit(error)


# --- Esqueleto ---

func _build_skeleton(root: Node2D) -> void:
	var skeleton := Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	root.add_child(skeleton)
	var bones := { "": skeleton }
	for entry: Dictionary in KaiPiezas.RIG:
		var bone := Bone2D.new()
		bone.name = entry.bone
		bone.position = KaiPiezas.bone_offset(entry)
		bone.set_autocalculate_length_and_angle(false)
		bone.set_length(6.0)
		bone.set_bone_angle(PI / 2.0)
		bones[entry.parent].add_child(bone)
		bone.rest = bone.transform
		bones[entry.bone] = bone
		if entry.has("piece"):
			var sprite := _piece(bone, entry.piece, entry.get("z", 0), BACK_TINT if entry.get("back", false) else Color.WHITE)
			if entry.get("weapon", false):
				# El arma está dibujada apuntando hacia arriba; girada 180° sigue la dirección del antebrazo.
				sprite.name = "Arma"
				sprite.rotation = PI
				sprite.visible = false


func _piece(bone: Node2D, piece: String, z: int, tint: Color) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = "Pieza_" + piece
	sprite.texture = _texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(KaiPiezas.region(piece))
	sprite.centered = false
	# El centro del píxel del pivote queda sobre el hueso.
	sprite.offset = -(KaiPiezas.pivot(piece) + Vector2(0.5, 0.5))
	sprite.z_index = z
	sprite.modulate = tint
	bone.add_child(sprite)
	return sprite


# --- Animaciones ---

func _build_animations(root: Node2D) -> void:
	var library := AnimationLibrary.new()
	library.add_animation(&"quieto", _animation(1.6, true, [
		{ "t": 0.0 },
		{ "t": 0.8, "torso": 2.0, "cuello": -2.0, "brazo_f": 9.0, "codo_f": 16.0, "brazo_b": -3.0, "codo_b": 16.0, "y": 1.0 },
	]))
	# Ciclo de carrera: contacto, impulso (cuerpo arriba), contacto con la otra pierna, impulso.
	var run := { "torso": 14.0, "cuello": -8.0 }
	library.add_animation(&"correr", _animation(0.6, true, [
		_pose(run, { "t": 0.0, "muslo_f": 38.0, "rodilla_f": -12.0, "muslo_b": -32.0, "rodilla_b": -50.0,
			"brazo_f": -38.0, "codo_f": 65.0, "brazo_b": 38.0, "codo_b": 55.0, "y": 0.5 }),
		_pose(run, { "t": 0.075, "muslo_f": 22.0, "rodilla_f": -8.0, "muslo_b": -12.0, "rodilla_b": -85.0,
			"brazo_f": -22.0, "codo_f": 70.0, "brazo_b": 22.0, "codo_b": 60.0, "y": 0.0 }),
		_pose(run, { "t": 0.15, "muslo_f": 0.0, "rodilla_f": -10.0, "muslo_b": 15.0, "rodilla_b": -95.0,
			"brazo_f": 0.0, "codo_f": 75.0, "brazo_b": 0.0, "codo_b": 70.0, "y": -1.5 }),
		_pose(run, { "t": 0.225, "muslo_f": -18.0, "rodilla_f": -25.0, "muslo_b": 30.0, "rodilla_b": -45.0,
			"brazo_f": 22.0, "codo_f": 60.0, "brazo_b": -22.0, "codo_b": 70.0, "y": -0.5 }),
		_pose(run, { "t": 0.3, "muslo_f": -32.0, "rodilla_f": -50.0, "muslo_b": 38.0, "rodilla_b": -12.0,
			"brazo_f": 38.0, "codo_f": 55.0, "brazo_b": -38.0, "codo_b": 65.0, "y": 0.5 }),
		_pose(run, { "t": 0.375, "muslo_f": -12.0, "rodilla_f": -85.0, "muslo_b": 22.0, "rodilla_b": -8.0,
			"brazo_f": 22.0, "codo_f": 60.0, "brazo_b": -22.0, "codo_b": 70.0, "y": 0.0 }),
		_pose(run, { "t": 0.45, "muslo_f": 15.0, "rodilla_f": -95.0, "muslo_b": 0.0, "rodilla_b": -10.0,
			"brazo_f": 0.0, "codo_f": 70.0, "brazo_b": 0.0, "codo_b": 75.0, "y": -1.5 }),
		_pose(run, { "t": 0.525, "muslo_f": 30.0, "rodilla_f": -45.0, "muslo_b": -18.0, "rodilla_b": -25.0,
			"brazo_f": -22.0, "codo_f": 70.0, "brazo_b": 22.0, "codo_b": 60.0, "y": -0.5 }),
	]))
	library.add_animation(&"saltar", _animation(0.3, false, [
		{ "t": 0.0, "torso": 4.0, "muslo_f": 40.0, "rodilla_f": -40.0, "muslo_b": -10.0, "rodilla_b": -20.0,
			"brazo_f": 110.0, "codo_f": 25.0, "brazo_b": 90.0, "codo_b": 25.0, "y": 1.0 },
		{ "t": 0.18, "torso": 6.0, "cuello": -6.0, "muslo_f": 65.0, "rodilla_f": -80.0, "muslo_b": -12.0, "rodilla_b": -40.0,
			"brazo_f": 150.0, "codo_f": 10.0, "brazo_b": 130.0, "codo_b": 10.0 },
	]))
	library.add_animation(&"caer", _animation(0.7, true, [
		{ "t": 0.0, "torso": -3.0, "cuello": 4.0, "muslo_f": 20.0, "rodilla_f": -25.0, "muslo_b": -15.0, "rodilla_b": -10.0,
			"brazo_f": 100.0, "codo_f": -10.0, "brazo_b": 80.0, "codo_b": -10.0 },
		{ "t": 0.35, "torso": -3.0, "cuello": 4.0, "muslo_f": 26.0, "rodilla_f": -32.0, "muslo_b": -12.0, "rodilla_b": -16.0,
			"brazo_f": 112.0, "codo_f": -4.0, "brazo_b": 92.0, "codo_b": -4.0 },
	]))
	library.add_animation(&"dash", _animation(0.15, false, [
		{ "t": 0.0, "torso": 30.0, "cuello": -16.0, "muslo_f": 35.0, "rodilla_f": -45.0, "muslo_b": -40.0, "rodilla_b": -20.0,
			"brazo_f": -55.0, "codo_f": 25.0, "brazo_b": -65.0, "codo_b": 15.0, "y": 1.0 },
		{ "t": 0.06, "torso": 38.0, "cuello": -20.0, "muslo_f": 42.0, "rodilla_f": -55.0, "muslo_b": -55.0, "rodilla_b": -25.0,
			"brazo_f": -75.0, "codo_f": 20.0, "brazo_b": -85.0, "codo_b": 10.0, "y": 2.0 },
	]))
	library.add_animation(&"pared", _animation(0.9, true, [
		{ "t": 0.0, "torso": -8.0, "cuello": 6.0, "brazo_b": -150.0, "codo_b": 20.0, "brazo_f": 20.0, "codo_f": 30.0,
			"muslo_f": 35.0, "rodilla_f": -50.0, "muslo_b": 15.0, "rodilla_b": -40.0 },
		{ "t": 0.45, "torso": -8.0, "cuello": 6.0, "brazo_b": -144.0, "codo_b": 26.0, "brazo_f": 26.0, "codo_f": 36.0,
			"muslo_f": 38.0, "rodilla_f": -56.0, "muslo_b": 16.0, "rodilla_b": -42.0 },
	]))
	# Ataque: preparación arriba, corte hacia adelante y regreso.
	library.add_animation(&"ataque_1", _animation(0.36, false, [
		{ "t": 0.0, "torso": -6.0, "cuello": 3.0, "brazo_f": 165.0, "codo_f": 40.0, "brazo_b": -20.0, "arma": true },
		{ "t": 0.06, "torso": -8.0, "brazo_f": 175.0, "codo_f": 35.0, "brazo_b": -25.0, "arma": true },
		{ "t": 0.12, "torso": 16.0, "cuello": -6.0, "brazo_f": 70.0, "codo_f": 0.0, "brazo_b": -30.0,
			"muslo_f": 18.0, "rodilla_f": -10.0, "muslo_b": -14.0, "arma": true },
		{ "t": 0.24, "torso": 10.0, "brazo_f": 25.0, "codo_f": 15.0, "muslo_f": 15.0, "muslo_b": -12.0, "arma": true },
		{ "t": 0.36, "arma": false },
	]))
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	player.add_animation_library(&"", library)
	player.autoplay = &"quieto"
	root.add_child(player)


func _pose(base: Dictionary, values: Dictionary) -> Dictionary:
	var pose := base.duplicate()
	pose.merge(values, true)
	return pose


## Crea una animación con una pista por articulación. Los valores que una pose no indica
## toman el de la pose neutra, así todas las animaciones parten del mismo estado.
func _animation(length: float, loop: bool, poses: Array) -> Animation:
	var animation := Animation.new()
	animation.length = length
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	for key: String in JOINTS:
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath("%s:rotation" % KaiPiezas.bone_path(JOINTS[key])))
		animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
		var direction := 1.0 if key in UP_JOINTS else -1.0
		for pose: Dictionary in poses:
			animation.track_insert_key(track, pose.t, direction * deg_to_rad(pose.get(key, NEUTRAL[key])))
	var hip_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(hip_track, NodePath("%s:position" % KaiPiezas.bone_path("Cadera")))
	animation.track_set_interpolation_type(hip_track, Animation.INTERPOLATION_CUBIC)
	for pose: Dictionary in poses:
		animation.track_insert_key(hip_track, pose.t, Vector2(0, -KaiPiezas.HIP_HEIGHT + pose.get("y", 0.0)))
	var weapon_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(weapon_track, NodePath("%s/Arma:visible" % KaiPiezas.bone_path("Mano")))
	animation.value_track_set_update_mode(weapon_track, Animation.UPDATE_DISCRETE)
	for pose: Dictionary in poses:
		animation.track_insert_key(weapon_track, pose.t, pose.get("arma", false))
	return animation


func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_set_owner_recursive(child, owner_node)

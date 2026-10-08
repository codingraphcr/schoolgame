extends SceneTree
## Genera characters/player/kai/kai_esqueleto.tscn: Skeleton2D con los huesos de Kai, una pieza
## (Sprite2D) pegada a cada hueso y un AnimationPlayer con las animaciones básicas.
## Ejecutar: godot --headless --path . --script res://characters/player/kai/generar_esqueleto_kai.gd
##
## Después de generarla, la escena se puede abrir y retocar en el editor (poses, tiempos, capas).
## OJO: volver a ejecutar este script sobrescribe esos retoques.
##
## Ángulos: en grados, positivo = hacia adelante (hacia donde mira Kai).

const OUT := "res://characters/player/kai/kai_esqueleto.tscn"
## Las extremidades de atrás reutilizan la misma pieza, más oscura.
const BACK_TINT := Color(0.72, 0.72, 0.82)
## Altura de la cadera sobre los pies: muslo (6 px) + pierna hasta la suela (7 px).
const HIP_HEIGHT := 13.0

## Huesos animados: nombre corto → ruta desde la raíz de la escena.
const BONES := {
	"torso": "Skeleton2D/Cadera/Torso",
	"cuello": "Skeleton2D/Cadera/Torso/Cuello",
	"brazo_f": "Skeleton2D/Cadera/Torso/BrazoFrente",
	"codo_f": "Skeleton2D/Cadera/Torso/BrazoFrente/AntebrazoFrente",
	"brazo_b": "Skeleton2D/Cadera/Torso/BrazoAtras",
	"codo_b": "Skeleton2D/Cadera/Torso/BrazoAtras/AntebrazoAtras",
	"muslo_f": "Skeleton2D/Cadera/MusloFrente",
	"rodilla_f": "Skeleton2D/Cadera/MusloFrente/PiernaFrente",
	"muslo_b": "Skeleton2D/Cadera/MusloAtras",
	"rodilla_b": "Skeleton2D/Cadera/MusloAtras/PiernaAtras",
}
const HIP_PATH := "Skeleton2D/Cadera"
const WEAPON_PATH := "Skeleton2D/Cadera/Torso/BrazoFrente/AntebrazoFrente/Mano/Arma"

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

	var hip := _bone(skeleton, "Cadera", Vector2(0, -HIP_HEIGHT), 4.0)
	var torso := _bone(hip, "Torso", Vector2.ZERO, 13.0, -PI / 2.0)
	_piece(torso, "torso", 0)

	var neck := _bone(torso, "Cuello", KaiPiezas.joint_offset("torso", "cuello"), 14.0, -PI / 2.0)
	_piece(neck, "cabeza", 2)
	var lock := _bone(neck, "Mechon", KaiPiezas.joint_offset("cabeza", "flequillo"), 5.0)
	_piece(lock, "mechon", 3)
	var backpack := _bone(torso, "Mochila", KaiPiezas.joint_offset("torso", "espalda"), 8.0)
	_piece(backpack, "mochila", -5)

	var shoulder := KaiPiezas.joint_offset("torso", "hombro")
	var elbow := KaiPiezas.joint_offset("brazo", "codo")
	var hand := KaiPiezas.joint_offset("antebrazo", "mano")
	var knee := KaiPiezas.joint_offset("muslo", "rodilla")

	var arm_back := _bone(torso, "BrazoAtras", shoulder + Vector2(-2, 0), elbow.length())
	_piece(arm_back, "brazo", -4, BACK_TINT)
	var fore_back := _bone(arm_back, "AntebrazoAtras", elbow, hand.length())
	_piece(fore_back, "antebrazo", -4, BACK_TINT)

	var thigh_back := _bone(hip, "MusloAtras", Vector2(-1, 0), knee.length())
	_piece(thigh_back, "muslo", -3, BACK_TINT)
	var shin_back := _bone(thigh_back, "PiernaAtras", knee, 7.0)
	_piece(shin_back, "pierna", -3, BACK_TINT)

	var thigh_front := _bone(hip, "MusloFrente", Vector2(1, 0), knee.length())
	_piece(thigh_front, "muslo", -1)
	var shin_front := _bone(thigh_front, "PiernaFrente", knee, 7.0)
	_piece(shin_front, "pierna", -1)

	var arm_front := _bone(torso, "BrazoFrente", shoulder, elbow.length())
	_piece(arm_front, "brazo", 5)
	var fore_front := _bone(arm_front, "AntebrazoFrente", elbow, hand.length())
	_piece(fore_front, "antebrazo", 5)
	var hand_bone := _bone(fore_front, "Mano", hand, 4.0)
	# El arma está dibujada apuntando hacia arriba; girada 180° sigue la dirección del antebrazo.
	var weapon := _piece(hand_bone, "arma", 4)
	weapon.name = "Arma"
	weapon.rotation = PI
	weapon.visible = false


func _bone(parent: Node, bone_name: String, pos: Vector2, length: float, angle := PI / 2.0) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = pos
	bone.set_autocalculate_length_and_angle(false)
	bone.set_length(length)
	bone.set_bone_angle(angle)
	parent.add_child(bone)
	bone.rest = bone.transform
	return bone


func _piece(bone: Node2D, piece: String, z: int, tint := Color.WHITE) -> Sprite2D:
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
	library.add_animation(&"quieto", _animation(1.4, true, [
		{ "t": 0.0 },
		{ "t": 0.7, "torso": 2.0, "cuello": -2.0, "brazo_f": 9.0, "codo_f": 16.0, "brazo_b": -3.0, "codo_b": 16.0, "y": 1.0 },
	]))
	library.add_animation(&"correr", _animation(0.56, true, [
		{ "t": 0.0, "torso": 12.0, "cuello": -6.0, "muslo_f": 35.0, "rodilla_f": -10.0, "muslo_b": -35.0, "rodilla_b": -45.0,
			"brazo_f": -35.0, "codo_f": 60.0, "brazo_b": 35.0, "codo_b": 60.0 },
		{ "t": 0.14, "torso": 12.0, "cuello": -6.0, "muslo_f": 0.0, "rodilla_f": -5.0, "muslo_b": 10.0, "rodilla_b": -85.0,
			"brazo_f": 0.0, "codo_f": 70.0, "brazo_b": 0.0, "codo_b": 70.0, "y": -1.0 },
		{ "t": 0.28, "torso": 12.0, "cuello": -6.0, "muslo_f": -35.0, "rodilla_f": -45.0, "muslo_b": 35.0, "rodilla_b": -10.0,
			"brazo_f": 35.0, "codo_f": 60.0, "brazo_b": -35.0, "codo_b": 60.0 },
		{ "t": 0.42, "torso": 12.0, "cuello": -6.0, "muslo_f": 10.0, "rodilla_f": -85.0, "muslo_b": 0.0, "rodilla_b": -5.0,
			"brazo_f": 0.0, "codo_f": 70.0, "brazo_b": 0.0, "codo_b": 70.0, "y": -1.0 },
	]))
	library.add_animation(&"saltar", _animation(0.25, false, [
		{ "t": 0.0, "torso": 4.0, "muslo_f": 40.0, "rodilla_f": -40.0, "muslo_b": -10.0, "rodilla_b": -20.0,
			"brazo_f": 120.0, "codo_f": 20.0, "brazo_b": 100.0, "codo_b": 20.0 },
		{ "t": 0.15, "torso": 6.0, "cuello": -5.0, "muslo_f": 65.0, "rodilla_f": -75.0, "muslo_b": -10.0, "rodilla_b": -35.0,
			"brazo_f": 150.0, "codo_f": 10.0, "brazo_b": 130.0, "codo_b": 10.0 },
	]))
	library.add_animation(&"caer", _animation(0.6, true, [
		{ "t": 0.0, "torso": -3.0, "cuello": 4.0, "muslo_f": 20.0, "rodilla_f": -25.0, "muslo_b": -15.0, "rodilla_b": -10.0,
			"brazo_f": 100.0, "codo_f": -10.0, "brazo_b": 80.0, "codo_b": -10.0 },
		{ "t": 0.3, "torso": -3.0, "cuello": 4.0, "muslo_f": 25.0, "rodilla_f": -30.0, "muslo_b": -12.0, "rodilla_b": -15.0,
			"brazo_f": 110.0, "codo_f": -5.0, "brazo_b": 90.0, "codo_b": -5.0 },
	]))
	library.add_animation(&"dash", _animation(0.15, false, [
		{ "t": 0.0, "torso": 35.0, "cuello": -20.0, "muslo_f": 40.0, "rodilla_f": -55.0, "muslo_b": -50.0, "rodilla_b": -25.0,
			"brazo_f": -70.0, "codo_f": 20.0, "brazo_b": -80.0, "codo_b": 10.0, "y": 2.0 },
	]))
	library.add_animation(&"pared", _animation(0.8, true, [
		{ "t": 0.0, "torso": -8.0, "cuello": 6.0, "brazo_b": -150.0, "codo_b": 20.0, "brazo_f": 20.0, "codo_f": 30.0,
			"muslo_f": 35.0, "rodilla_f": -50.0, "muslo_b": 15.0, "rodilla_b": -40.0 },
		{ "t": 0.4, "torso": -8.0, "cuello": 6.0, "brazo_b": -145.0, "codo_b": 25.0, "brazo_f": 25.0, "codo_f": 35.0,
			"muslo_f": 38.0, "rodilla_f": -55.0, "muslo_b": 15.0, "rodilla_b": -40.0 },
	]))
	library.add_animation(&"ataque_1", _animation(0.32, false, [
		{ "t": 0.0, "torso": -5.0, "brazo_f": 160.0, "codo_f": 40.0, "arma": true },
		{ "t": 0.08, "torso": 15.0, "cuello": -5.0, "brazo_f": 75.0, "codo_f": 0.0, "muslo_f": 15.0, "muslo_b": -12.0, "arma": true },
		{ "t": 0.2, "torso": 10.0, "brazo_f": 30.0, "codo_f": 15.0, "muslo_f": 15.0, "muslo_b": -12.0, "arma": true },
		{ "t": 0.32, "arma": false },
	]))
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	player.add_animation_library(&"", library)
	player.autoplay = &"quieto"
	root.add_child(player)


## Crea una animación con una pista por hueso. Los valores que una pose no indica
## toman el de la pose neutra, así todas las animaciones parten del mismo estado.
func _animation(length: float, loop: bool, poses: Array) -> Animation:
	var animation := Animation.new()
	animation.length = length
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	for key: String in BONES:
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath("%s:rotation" % BONES[key]))
		animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
		for pose: Dictionary in poses:
			animation.track_insert_key(track, pose.t, -deg_to_rad(pose.get(key, NEUTRAL[key])))
	var hip_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(hip_track, NodePath("%s:position" % HIP_PATH))
	animation.track_set_interpolation_type(hip_track, Animation.INTERPOLATION_CUBIC)
	for pose: Dictionary in poses:
		animation.track_insert_key(hip_track, pose.t, Vector2(0, -HIP_HEIGHT + pose.get("y", 0.0)))
	var weapon_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(weapon_track, NodePath("%s:visible" % WEAPON_PATH))
	animation.value_track_set_update_mode(weapon_track, Animation.UPDATE_DISCRETE)
	for pose: Dictionary in poses:
		animation.track_insert_key(weapon_track, pose.t, pose.get("arma", false))
	return animation


func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_set_owner_recursive(child, owner_node)

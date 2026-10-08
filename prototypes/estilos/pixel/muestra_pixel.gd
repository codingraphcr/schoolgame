extends StyleSample
## Muestra A: pixel art a 640×360 (tiles de 16 px, filtro Nearest).
## El escenario usa un TileMapLayer real con el tileset generado, como lo harían las salas finales.

const SPRITES := "res://assets/art/pixel/"
const TILE := 16

# Columnas de tiles.png
const TILE_FLOOR := 0
const TILE_FILL := 1
const TILE_WALL := 2
const TILE_WALL_TECH := 3
const TILE_WALL_BASE := 4
const TILE_CEILING := 5
const TILE_CABLES := 6
const TILE_FLOOR_CORRUPT := 7
const TILE_WALL_TRIM := 8
const TILE_WALL_TECH_PLAIN := 9
const TILE_COUNT := 10

const CABLE_Y := 56.0

var _packets: Array[Sprite2D] = []
var _packet_ok: Texture2D
var _packet_bad: Texture2D
var _signs: Array[CanvasItem] = []
var _lure: Node2D
var _lure_light: PointLight2D
var _time := 0.0
var _kai: AnimatedSprite2D


func _init() -> void:
	sample_title = "MUESTRA A · Pixel art de alta resolución (640×360, tiles de 16 px)"
	other_sample = "res://prototypes/estilos/vectorial/muestra_vectorial.tscn"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _build_art() -> void:
	add_ambient(Color(0.62, 0.66, 0.85))
	_build_tilemap()
	_build_corridor_props()
	_build_platform_props()
	_build_lab_props()
	_build_packets()


func _process(delta: float) -> void:
	_time += delta
	for packet in _packets:
		packet.position.x += 70.0 * delta
		if packet.position.x > ROOM_SIZE.x + 8.0:
			packet.position.x = -8.0
		# Los paquetes se "infectan" al pasar por la zona del laboratorio.
		var infected := packet.position.x > CORRUPTION.position.x - 40.0
		packet.texture = _packet_bad if infected else _packet_ok
	for sign_node in _signs:
		sign_node.modulate.a = 0.55 if randf() < 0.03 else 0.95
	if _lure:
		_lure.position.y = LURE_POSITION.y + roundf(sin(_time * 2.0) * 2.0)
		_lure_light.energy = 1.1 + sin(_time * 5.0) * 0.3
	_update_kai_animation()


# --- Escenario con TileMapLayer ---

func _build_tilemap() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	var source := TileSetAtlasSource.new()
	source.texture = load(SPRITES + "tiles.png")
	source.texture_region_size = Vector2i(TILE, TILE)
	for i in TILE_COUNT:
		source.create_tile(Vector2i(i, 0))
	var source_id := tile_set.add_source(source)

	var back := TileMapLayer.new()
	back.name = "Background"
	back.tile_set = tile_set
	add_child(back)
	var cables := TileMapLayer.new()
	cables.name = "Cables"
	cables.tile_set = tile_set
	add_child(cables)

	var columns := int(ROOM_SIZE.x / TILE)
	var lab_column := int(LAB_X / TILE)
	for x in columns:
		var lab := x >= lab_column
		back.set_cell(Vector2i(x, 0), source_id, Vector2i(TILE_FILL, 0))
		back.set_cell(Vector2i(x, 1), source_id, Vector2i(TILE_FILL, 0))
		back.set_cell(Vector2i(x, 2), source_id, Vector2i(TILE_CEILING, 0))
		for y in range(3, 19):
			var tile := TILE_WALL
			if lab:
				# Alterna circuitos y paneles lisos para que el patrón no se repita.
				tile = TILE_WALL_TECH if (x * 7 + y * 3) % 5 == 0 else TILE_WALL_TECH_PLAIN
			elif y == 10:
				tile = TILE_WALL_TRIM
			elif y == 18:
				tile = TILE_WALL_BASE
			back.set_cell(Vector2i(x, y), source_id, Vector2i(tile, 0))
		var corrupt := x * TILE >= CORRUPTION.position.x and x * TILE < CORRUPTION.end.x
		back.set_cell(Vector2i(x, 19), source_id, Vector2i(TILE_FLOOR_CORRUPT if corrupt else TILE_FLOOR, 0))
		for y in range(20, 23):
			back.set_cell(Vector2i(x, y), source_id, Vector2i(TILE_FILL, 0))
		cables.set_cell(Vector2i(x, 3), source_id, Vector2i(TILE_CABLES, 0))


# --- Objetos ---

func _build_corridor_props() -> void:
	# Lámparas del techo: luz cálida del colegio frente al neón frío de la red.
	for x in range(40, int(LAB_X), 128):
		_sprite("lamp.png", Vector2(x, CEILING_Y))
		add_light(Vector2(x + 10, CEILING_Y + 30), Color(1.0, 0.85, 0.6), 120, 0.45)
	_sprite("pennants.png", Vector2(28, 140))
	_sprite("pennants.png", Vector2(420, 140))
	_sprite("clock.png", Vector2(254, 120))
	for i in 5:
		_sprite("lockers.png", Vector2(24 + i * 16, FLOOR_Y - 40), 2, 1 if i == 3 else 0)
	_sprite("board.png", Vector2(120, 232))
	_sprite("window.png", Vector2(172, 196))
	add_light(Vector2(192, 210), Color(0.45, 0.6, 1.0), 70, 0.5)
	_sprite("door.png", Vector2(232, FLOOR_Y - 48))
	_signs.append(_sprite("sign_sala.png", Vector2(234, 238)))
	add_light(Vector2(246, 268), Color(0.25, 0.85, 1.0), 40, 0.6)
	_sprite("window.png", Vector2(284, 196))
	add_light(Vector2(304, 210), Color(0.45, 0.6, 1.0), 70, 0.5)
	_sprite("router.png", Vector2(344, 150))
	_animated("wifi_waves.png", 30, 3.0, Vector2(338, 132))
	add_light(Vector2(353, 150), Color(0.25, 0.95, 1.0), 60, 0.9)
	for i in 4:
		_sprite("lockers.png", Vector2(376 + i * 16, FLOOR_Y - 40), 2, 1 if i == 1 else 0)


func _build_platform_props() -> void:
	# Las bandejas de cables son las plataformas: se dibujan con el tile de techo.
	var tray := (load(SPRITES + "tiles.png") as Texture2D).get_image().get_region(
		Rect2i(TILE_CEILING * TILE, 10, TILE, 6))
	var tray_texture := ImageTexture.create_from_image(tray)
	for rect in ONE_WAY_PLATFORMS:
		var sprite := Sprite2D.new()
		sprite.texture = tray_texture
		sprite.centered = false
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, rect.size.x, 6)
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		sprite.position = rect.position - Vector2(0, 1)
		add_child(sprite)


func _build_lab_props() -> void:
	for i in 2:
		# Canaletas: los cables del techo bajan hasta los servidores.
		var conduit := Sprite2D.new()
		conduit.texture = load(SPRITES + "conduit.png")
		conduit.centered = false
		conduit.region_enabled = true
		conduit.region_rect = Rect2(0, 0, 7, FLOOR_Y - 64 - CEILING_Y)
		conduit.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		conduit.position = Vector2(711 + i * 30, CEILING_Y)
		add_child(conduit)
		_animated("server_rack.png", 28, 3.0 + i, Vector2(700 + i * 30, FLOOR_Y - 64))
		add_light(Vector2(726 + i * 30, 270), Color(0.35, 1.0, 0.6), 50, 0.6)
	_sprite("lab_door.png", Vector2(780, FLOOR_Y - 48))
	_signs.append(_sprite("sign_lab.png", Vector2(760, 112)))
	add_light(Vector2(786, 118), Color(0.25, 0.95, 1.0), 110, 1.1)
	_lure = _animated("phish_lure.png", 32, 8.0, LURE_POSITION, true)
	# Sedal desde el techo hasta el anzuelo (se mueve con él).
	var fishing_line := ColorRect.new()
	fishing_line.color = Color("8b98b8")
	fishing_line.size = Vector2(1, LURE_POSITION.y - 16 - CEILING_Y)
	fishing_line.position = Vector2(0, -(LURE_POSITION.y - 16 - CEILING_Y) - 16)
	_lure.add_child(fishing_line)
	_lure_light = add_light(LURE_POSITION + Vector2(0, 4), Color(1.0, 0.25, 0.65), 90, 1.2)
	add_light(CORRUPTION.get_center(), Color(1.0, 0.25, 0.65), 70, 0.8)


func _build_packets() -> void:
	_packet_ok = load(SPRITES + "packet.png")
	_packet_bad = load(SPRITES + "packet_bad.png")
	for i in 7:
		var packet := Sprite2D.new()
		packet.texture = _packet_ok
		packet.position = Vector2(i * 140.0 + 20.0, CABLE_Y + 2.0 * (i % 3))
		add_child(packet)
		_packets.append(packet)


func _sprite(file: String, pos: Vector2, hframes := 1, frame := 0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(SPRITES + file)
	sprite.centered = false
	sprite.hframes = hframes
	sprite.frame = frame
	sprite.position = pos
	add_child(sprite)
	return sprite


func _animated(file: String, frame_width: int, fps: float, pos: Vector2, centered := false) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = _frames_from_strip({ &"default": [file, frame_width, fps, true] })
	sprite.centered = centered
	sprite.position = pos
	sprite.play()
	add_child(sprite)
	return sprite


## Crea SpriteFrames a partir de tiras horizontales de cuadros.
## animations = { nombre: [archivo, ancho_de_cuadro, fps, en_bucle] }
func _frames_from_strip(animations: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim_name: StringName in animations:
		var data: Array = animations[anim_name]
		var texture: Texture2D = load(SPRITES + data[0])
		var frame_width: int = data[1]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, data[2])
		frames.set_animation_loop(anim_name, data[3])
		for i in texture.get_width() / frame_width:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * frame_width, 0, frame_width, texture.get_height())
			frames.add_frame(anim_name, atlas)
	return frames


# --- Jugador ---

func _build_player_visual() -> Node2D:
	_kai = AnimatedSprite2D.new()
	_kai.sprite_frames = _frames_from_strip({
		&"idle": ["kai_idle.png", 24, 5.0, true],
		&"run": ["kai_run.png", 24, 14.0, true],
		&"jump": ["kai_jump.png", 24, 8.0, false],
		&"fall": ["kai_fall.png", 24, 6.0, true],
		&"dash": ["kai_dash.png", 24, 16.0, true],
		&"wall": ["kai_wall.png", 24, 6.0, true],
	})
	_kai.offset = Vector2(0, -18)  # Los pies quedan en el origen del jugador.
	_kai.play(&"idle")
	return _kai


func _update_kai_animation() -> void:
	if _kai == null or player == null:
		return
	var anim := &"idle"
	match player.state:
		Player.State.RUN:
			anim = &"run"
		Player.State.JUMP:
			anim = &"jump"
		Player.State.FALL:
			anim = &"fall"
		Player.State.DASH:
			anim = &"dash"
		Player.State.WALL_SLIDE:
			anim = &"wall"
	if _kai.animation != anim:
		_kai.play(anim)
	_kai.speed_scale = clampf(absf(player.velocity.x) / player.max_speed, 0.5, 1.2) if anim == &"run" else 1.0

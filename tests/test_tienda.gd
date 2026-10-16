extends SceneTree
## Prueba automática: la tienda de la soda (la tienda oficial del juego) y la economía con tope de 999 Ecos
## (docs/mundo/COLEGIO.md). La puerta de la tienda está en el patio, al lado de la soda, cerrada hasta hablar con la
## señora de la soda; adentro ella atiende y abre el catálogo; el catálogo crece con los capítulos; cada artículo se
## compra una sola vez, nunca se cobra sin entregar ni con Ecos que no alcanzan; los efectos (fragmentos, dash,
## espada, doble salto, mapa y pistas del Grimorio); lo de Aegis espera a Aegis; la bolsa no pasa de 999; guardar y
## cargar conserva las compras y otra ranura no.
## Ejecutar: godot --headless --path . --script res://tests/test_tienda.gd

const Z := "res://world/zones/zone0/"

var _failures := 0
var state: Node
var economy: Node
var room: Room


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	state = root.get_node("GameState")
	economy = root.get_node("Economy")
	root.get_node("SaveManager").new_game(1)
	DevPoints._advance(state, &"una_clase_diferente", &"buscar_huellas")
	state.unlock_vision()
	state.set_nullblade_stage(1)
	await _test_closed_door()
	await _test_open_door()
	await _test_shop_window()
	_test_catalog_by_chapter()
	await _test_map_and_hints()
	_test_chapter_2_items()
	_test_wallet()
	await _test_saved()
	print("RESULTADO: ", "TODO OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _test_closed_door() -> void:
	await _open(Z + "patio.tscn")
	var door := room.get_node("Objetos/PuertaTienda") as ShopDoor
	_check(door != null and not door.is_open() and door.prompt_text == "E: mirar la puerta",
		"en el patio, al lado de la soda, está la puerta de la tienda: cerrada")
	var line := await _use(door)
	await _frames(10)
	_check(line.contains("Tienda de la soda") and current_scene.scene_file_path == Z + "patio.tscn", "un rótulo dice que hay que preguntar en la soda")


func _test_open_door() -> void:
	await _open(Z + "soda.tscn")
	var lady := room.get_node("Gente/SenoraSoda") as Npc
	await _use_npc(lady)
	_check(state.has_flag(Shop.OPEN_FLAG), "después de hablar con la señora de la soda, la tienda queda abierta")
	await _open(Z + "patio.tscn")
	var door := room.get_node("Objetos/PuertaTienda") as ShopDoor
	_check(door.is_open() and door.prompt_text == "E: entrar a la tienda", "ahora la puerta se abre")
	room.player.teleport_to(Vector2(door.global_position.x, 304))
	await _frames(3)
	door._on_interacted(room.player)
	await _arrive(Z + "tienda.tscn")
	_check(room.player.global_position.distance_to(Vector2(110, 304)) < 2.0, "Kai entra a la tienda")


func _test_shop_window() -> void:
	var keeper := room.get_node("Gente/Senora") as ShopKeeper
	room.player.teleport_to(Vector2(keeper.global_position.x - 30, 304))
	await _frames(3)
	keeper._on_interacted(room.player)
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	_check(box._text.text.contains("Bienvenido"), "la señora atiende la tienda: «%s»" % box._text.text)
	await _advance(box)
	await _until(func() -> bool: return get_first_node_in_group(&"shop_window") != null)
	var window := get_first_node_in_group(&"shop_window") as ShopWindow
	_check(window != null and paused and window.items.size() == 4, "se abre la tienda (pausa): en el Capítulo 1 hay 4 artículos")
	if economy.ecos > 0:
		economy.spend_ecos(economy.ecos)  # Lo que Kai ganó antes (prólogo, misiones) no cuenta para esta prueba.
	var life := _item(window, &"fragmento_vida_1")
	var energy := _item(window, &"fragmento_energia_1")
	_check(economy.ecos == 0 and Shop.status(state, economy, life) == Shop.Status.SIN_ECOS and not window.purchase(life),
		"sin Ecos no se puede comprar (y no se cobra nada)")
	economy.add_ecos(200)
	var masks_before: int = state.life_fragments
	_check(window.purchase(life) and economy.ecos == 80 and state.life_fragments == masks_before + 1 and Shop.is_bought(state, life),
		"fragmento de vida: 120 Ecos; Kai suma un fragmento")
	_check(not window.purchase(life) and economy.ecos == 80, "cada artículo se compra una sola vez")
	_check(not window.purchase(energy) and economy.ecos == 80 and state.energy_fragments == 0, "si no alcanza (100 > 80), no se cobra ni se entrega")
	economy.add_ecos(20)
	window.select(window.items.find(energy))
	window._ask_purchase()
	await _until(func() -> bool: return get_first_node_in_group(&"confirm_prompt") != null)
	var prompt := get_first_node_in_group(&"confirm_prompt") as ConfirmPrompt
	_check(prompt != null and prompt.question.contains("100 Ecos"), "antes de comprar, pregunta: «%s»" % (prompt.question if prompt else ""))
	prompt.answer(true)
	await _frames(3)
	_check(economy.ecos == 0 and state.energy_fragments == 1 and paused, "con «Sí» se compra el fragmento de energía (la tienda sigue abierta)")
	window.close()
	await _frames(4)
	_check(not paused, "al salir, el juego sigue")


func _test_catalog_by_chapter() -> void:
	var ids := func() -> PackedStringArray:
		var result := PackedStringArray()
		for item in Shop.visible_items(state):
			result.append(String(item.id))
		return result
	var chapter_1: PackedStringArray = ids.call()
	state.set_flag(&"capitulo_2")
	var chapter_2: PackedStringArray = ids.call()
	state.set_flag(&"capitulo_3")
	var chapter_3: PackedStringArray = ids.call()
	state.clear_flag(&"capitulo_3")
	_check(chapter_1.size() == 4 and not chapter_1.has("doble_salto") and not chapter_1.has("dash_fantasma"),
		"Capítulo 1: fragmentos de vida y energía, mapa y pistas del colegio %s" % [chapter_1])
	_check(chapter_2.has("doble_salto") and chapter_2.has("dash_fantasma") and chapter_2.has("espada_1") and not chapter_2.has("espada_2"),
		"Capítulo 2: se suman el doble salto, el Dash Fantasma y la espada %s" % [chapter_2])
	_check(chapter_3.has("espada_2") and chapter_3.has("aegis_nucleo") and chapter_3.has("mapa_bosque_fibra"), "Capítulo 3: más mejoras, Aegis y el mapa del bosque")
	var aegis := load("res://data/shop/articulos/aegis_nucleo.tres") as ShopItem
	_check(Shop.blocked_reason(state, aegis) == "Hace falta Aegis.", "lo de Aegis espera a que Kai tenga a Aegis")
	_check(load("res://data/shop/articulos/doble_salto.tres").price >= 700, "el doble salto es caro (%d Ecos)" % load("res://data/shop/articulos/doble_salto.tres").price)


func _test_map_and_hints() -> void:
	var map := GrimorioMap.new()
	map.zone = &"colegio"
	root.add_child(map)
	await _frames(2)
	var unknown_before := 0
	for value in map.room_states().values():
		if value == GrimorioMap.State.UNKNOWN:
			unknown_before += 1
	economy.add_ecos(70)
	_check(Shop.buy(state, economy, load("res://data/shop/articulos/mapa_colegio.tres")), "se compra el mapa del colegio (30)")
	var unknown_after := 0
	for value in map.room_states().values():
		if value == GrimorioMap.State.UNKNOWN:
			unknown_after += 1
	_check(unknown_before > 0 and unknown_after == 0, "el mapa del Grimorio muestra todas las salas del colegio (%d ocultas → 0)" % unknown_before)
	map.queue_free()
	var page := load("res://data/grimorio/registro_pistas_colegio.tres") as GrimorioEntry
	_check(not page.is_unlocked(state), "la página de pistas está oculta")
	_check(Shop.buy(state, economy, load("res://data/shop/articulos/pista_colegio.tres")) and page.is_unlocked(state),
		"comprar las pistas abre su página del Grimorio")


func _test_chapter_2_items() -> void:
	state.set_dash_level(1)
	var dash := load("res://data/shop/articulos/dash_fantasma.tres") as ShopItem
	var sword := load("res://data/shop/articulos/espada_1.tres") as ShopItem
	var jump := load("res://data/shop/articulos/doble_salto.tres") as ShopItem
	economy.add_ecos(999)
	_check(Shop.buy(state, economy, dash) and state.dash_level == 2, "Dash Fantasma: el dash sube al nivel 2")
	_check(Shop.buy(state, economy, sword) and state.sword_level == 1 and is_equal_approx(state.sword_damage_multiplier(), 1.25),
		"Nullblade afilada: +25 % de daño")
	_check(economy.ecos < jump.price and not Shop.buy(state, economy, jump), "el doble salto cuesta más de lo que queda (%d)" % economy.ecos)
	economy.add_ecos(999)
	_check(Shop.buy(state, economy, jump) and state.can_double_jump, "con la bolsa llena se compra el doble salto")


func _test_wallet() -> void:
	economy.add_ecos(5000)
	_check(economy.ecos == 999, "la bolsa de Ecos no pasa de 999")


func _test_saved() -> void:
	var saves := root.get_node("SaveManager")
	_check(saves.save_game(Z + "tienda.tscn", &"desde_patio"), "se guarda la partida")
	state.reset()
	saves.load_slot(1)
	_check(state.sword_level == 1 and state.dash_level == 2 and state.can_double_jump and state.has_flag(&"compra_doble_salto")
		and state.has_flag(Shop.OPEN_FLAG), "al cargar, las compras siguen (espada, dash, doble salto, tienda abierta)")
	saves.new_game(2)
	_check(state.sword_level == 0 and not state.has_flag(&"compra_doble_salto") and not Shop.is_open(state),
		"otra ranura no comparte las compras")


func _item(window: ShopWindow, id: StringName) -> ShopItem:
	for item in window.items:
		if item.id == id:
			return item
	return null


func _use(node: Interactable) -> String:
	room.player.teleport_to(Vector2(node.global_position.x, 304))
	await _frames(3)
	node._on_interacted(room.player)
	return await _read_box()


func _use_npc(npc: Npc) -> String:
	room.player.teleport_to(Vector2(npc.global_position.x + 24, 304))
	await _frames(3)
	npc._on_interacted(room.player)
	return await _read_box()


func _read_box() -> String:
	var box := room.get_node("CombatHUD/DialogueBox") as DialogueBox
	await _until(func() -> bool: return box.is_playing())
	await _frames(2)
	var text := box._text.text
	await _advance(box)
	await _frames(3)
	return text


func _advance(box: DialogueBox) -> void:
	for i in 80:
		if not box.is_playing():
			return
		await _action(&"interact")
		await _frames(3)


func _open(path: String) -> void:
	change_scene_to_file(path)
	await _arrive(path)


func _arrive(path: String) -> void:
	await _until(func() -> bool: return current_scene is Room and current_scene.scene_file_path == path and current_scene.is_node_ready())
	await _frames(6)
	room = current_scene as Room


func _action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _until(condition: Callable) -> void:
	for i in 2400:
		if condition.call():
			return
		await process_frame
		await physics_frame


func _frames(count: int) -> void:
	for i in count:
		await process_frame
		await physics_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
	print("%s %s" % ["OK  " if condition else "FAIL", message])

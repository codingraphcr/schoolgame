@tool
class_name GrimorioWorldMap
extends Control
## Mapa del mundo en el Grimorio (docs/mundo/MAPA_MAESTRO.md): las regiones del mundo físico o del digital
## (WorldAtlas), en bloques sobre una cuadrícula, con niebla de exploración:
## - Visitada: color de la región y su nombre (y dónde está Kai).
## - Descubierta: con nombre, sin color.
## - Niebla: silueta con «???» (una región vecina de otra visitada).
## - Desconocida o secreta sin descubrir: no se dibuja.
## Las conexiones conocidas se dibujan (las de Inmersión punteadas); las que todavía no se pueden usar, con
## un candado. Arriba, la región de la misión actual. Mismos colores del libro que el mapa de la zona.

const PANEL := Color("100c20")
const GRID := Color(0.5, 0.42, 0.85, 0.12)
const EDGE := Color("b9a6ff")
const FOG := Color("2a2540")
const TEXT := Color("e6deff")
const MUTED := Color(0.9, 0.87, 1.0, 0.5)
const KAI := Color("3ef2ff")
const LOCK := Color("e0457b")
const MISSION := Color("ffd166")
const LEGEND_HEIGHT := 46.0

@export var kind := WorldRegion.Kind.FISICA:
	set(value):
		kind = value
		queue_redraw()


## Regiones visitadas y total (sin contar las secretas sin descubrir): Vector2i(visitadas, total).
func progress() -> Vector2i:
	var visited := 0
	var total := 0
	for region in WorldAtlas.regions(kind):
		var known := _state_of(region)
		if region.secret and known == WorldAtlas.State.DESCONOCIDA:
			continue
		total += 1
		if known == WorldAtlas.State.VISITADA:
			visited += 1
	return Vector2i(visited, total)


## La región donde está Kai (o null).
func current_region() -> WorldRegion:
	var world := _world()
	return WorldAtlas.region_of_district(world.current_district) if world else null


## La región de la misión actual (o null).
func mission_region() -> WorldRegion:
	var state := get_node_or_null("/root/GameState")
	var world := _world()
	if state == null or world == null:
		return null
	var room: StringName = state.get_objective_room()
	return WorldAtlas.region_of_district(world.district_of(room)) if room != &"" else null


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(size.x, size.y - LEGEND_HEIGHT))
	draw_rect(rect, PANEL)
	draw_rect(rect, Color(EDGE, 0.6), false, 2.0)
	var font := get_theme_default_font()
	var regions := WorldAtlas.regions(kind)
	# Se encuadra lo que el jugador conoce (con un mínimo, para no agrandar de más una sola región).
	var bounds := Rect2()
	var first := true
	for region in regions:
		if _state_of(region) == WorldAtlas.State.DESCONOCIDA:
			continue
		var r := Rect2(region.map_position, region.map_size)
		bounds = r if first else bounds.merge(r)
		first = false
	if first:
		bounds = Rect2(Vector2.ZERO, Vector2(6, 4))
	bounds = bounds.grow_individual(maxf(0.0, (6.0 - bounds.size.x) / 2.0), maxf(0.0, (4.0 - bounds.size.y) / 2.0),
		maxf(0.0, (6.0 - bounds.size.x) / 2.0), maxf(0.0, (4.0 - bounds.size.y) / 2.0))
	var cell := minf((rect.size.x - 40.0) / maxf(bounds.size.x, 1.0), (rect.size.y - 50.0) / maxf(bounds.size.y, 1.0))
	var origin := rect.get_center() - bounds.size * cell / 2.0 - bounds.position * cell + Vector2(0, 10)
	var x := fmod(origin.x, cell)
	while x < rect.size.x:
		draw_line(Vector2(x, 0), Vector2(x, rect.size.y), GRID, 1.0)
		x += cell
	var y := fmod(origin.y, cell)
	while y < rect.size.y:
		draw_line(Vector2(0, y), Vector2(rect.size.x, y), GRID, 1.0)
		y += cell
	var state := get_node_or_null("/root/GameState")
	var boxes := {}
	for region in regions:
		boxes[region.id] = Rect2(origin + region.map_position * cell, region.map_size * cell).grow(-4.0)
	# Conexiones (debajo de los bloques).
	if state:
		for link in WorldAtlas.links():
			if not boxes.has(link.region_a) or not boxes.has(link.region_b):
				continue
			if not WorldAtlas.is_link_known(link, state, _world()):
				continue
			var from: Vector2 = (boxes[link.region_a] as Rect2).get_center()
			var to: Vector2 = (boxes[link.region_b] as Rect2).get_center()
			var open := link.is_open(state)
			var color := Color(EDGE, 0.8) if open else Color(LOCK, 0.7)
			if link.kind == RegionLink.Kind.INMERSION:
				draw_dashed_line(from, to, Color(KAI, 0.8) if open else color, 2.0, 6.0)
			else:
				draw_line(from, to, color, 2.0)
			if not open:
				_lock(from.lerp(to, 0.5))
	# Bloques.
	var mission := mission_region()
	var here := current_region()
	for region in regions:
		var known := _state_of(region) if state else WorldAtlas.State.VISITADA
		if known == WorldAtlas.State.DESCONOCIDA:
			continue
		var box: Rect2 = boxes[region.id]
		match known:
			WorldAtlas.State.VISITADA:
				draw_rect(box, Color(region.color, 0.55))
				draw_rect(box, region.color.lightened(0.3), false, 2.0)
			WorldAtlas.State.DESCUBIERTA:
				draw_rect(box, Color(FOG, 0.9))
				draw_rect(box, Color(region.color, 0.6), false, 2.0)
			WorldAtlas.State.NIEBLA:
				draw_rect(box, Color(FOG, 0.6))
				draw_dashed_line(box.position, Vector2(box.end.x, box.position.y), MUTED, 1.0, 4.0)
				draw_dashed_line(Vector2(box.position.x, box.end.y), box.end, MUTED, 1.0, 4.0)
		var label_text := "???" if known == WorldAtlas.State.NIEBLA else region.display_name
		draw_multiline_string(font, box.position + Vector2(6, 17), label_text, HORIZONTAL_ALIGNMENT_LEFT, maxf(box.size.x - 8.0, 60.0), 13, 2,
			TEXT if known == WorldAtlas.State.VISITADA else MUTED)
		if region == mission and mission != null:
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 250.0)
			draw_rect(box.grow(3.0 + pulse * 2.0), Color(MISSION, 0.5 + pulse * 0.4), false, 2.0)
		if region == here and here != null:
			draw_circle(box.get_center() + Vector2(0, 8), 6.0, KAI)
			draw_circle(box.get_center() + Vector2(0, 8), 10.0, Color(KAI, 0.3))
	if mission:
		draw_string(font, Vector2(16, 26), "MISIÓN EN: " + mission.display_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, MISSION)
	_legend(Rect2(0, rect.end.y + 6, size.x, LEGEND_HEIGHT - 6), font)


func _legend(area: Rect2, font: Font) -> void:
	var items := [[Color(EDGE, 0.55), "Visitada"], [FOG, "Descubierta"], [Color(FOG, 0.6), "Sin explorar (???)"], [LOCK, "Conexión cerrada"], [KAI, "Inmersión / Kai"]]
	var x := area.position.x + 8.0
	for item in items:
		draw_rect(Rect2(x, area.position.y + 10, 14, 14), item[0])
		draw_string(font, Vector2(x + 20, area.position.y + 22), item[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MUTED)
		x += 30.0 + font.get_string_size(item[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x


func _lock(center: Vector2) -> void:
	draw_rect(Rect2(center + Vector2(-5, -2), Vector2(10, 8)), LOCK)
	draw_arc(center + Vector2(0, -2), 4.0, PI, TAU, 8, LOCK, 2.0)


func _state_of(region: WorldRegion) -> WorldAtlas.State:
	var state := get_node_or_null("/root/GameState")
	if Engine.is_editor_hint() or state == null:
		return WorldAtlas.State.VISITADA
	return WorldAtlas.state_of(region, state, _world())


func _world() -> Node:
	return get_node_or_null("/root/World")

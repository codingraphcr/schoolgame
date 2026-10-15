class_name WorldAtlas
extends RefCounted
## El mapa maestro (docs/mundo/MAPA_MAESTRO.md): las regiones del mundo físico y del digital y sus
## conexiones, como datos (data/world/regions/ y data/world/links/). Para agregar una: crear el .tres y
## sumarlo a la lista (como QuestDB: una lista explícita funciona igual exportado).
##
## Lo que sabe el jugador de cada región sale de la partida (nada se guarda aquí):
##   VISITADA    : Kai entró a alguna de sus salas (World.visited) — color y nombre.
##   DESCUBIERTA : tiene la marca «region_descubierta_<id>» o cumple su reveal — nombre, sin color.
##   NIEBLA      : no es secreta y está conectada (por una conexión que no es oculta) con una región
##                 visitada — silueta con «???».
##   DESCONOCIDA : no se dibuja (las secretas siempre, hasta descubrirlas).

enum State { DESCONOCIDA, NIEBLA, DESCUBIERTA, VISITADA }

const REGIONS: Array[String] = [
	# Mundo físico.
	"res://data/world/regions/barrio_almendros.tres",
	"res://data/world/regions/distrito_central.tres",
	"res://data/world/regions/altos_cartago.tres",
	"res://data/world/regions/costa_pacifico.tres",
	"res://data/world/regions/conductos_silencio.tres",
	"res://data/world/regions/laboratorio_genesis.tres",
	# Mundo digital.
	"res://data/world/regions/sistemas_colegio.tres",
	"res://data/world/regions/bosque_fibra.tres",
	"res://data/world/regions/distrito_cache.tres",
	"res://data/world/regions/nucleo_termico.tres",
	"res://data/world/regions/archivo_criogenico.tres",
	"res://data/world/regions/canales_corruptos.tres",
	"res://data/world/regions/santuario_raiz.tres",
	"res://data/world/regions/velo_nulo.tres",
]

const LINKS: Array[String] = [
	"res://data/world/links/barrio_central.tres",
	"res://data/world/links/central_cartago.tres",
	"res://data/world/links/central_costa.tres",
	"res://data/world/links/central_conductos.tres",
	"res://data/world/links/cartago_conductos.tres",
	"res://data/world/links/conductos_laboratorio.tres",
	"res://data/world/links/central_sistemas.tres",
	"res://data/world/links/barrio_bosque.tres",
	"res://data/world/links/central_bosque.tres",
	"res://data/world/links/central_cache.tres",
	"res://data/world/links/costa_nucleo.tres",
	"res://data/world/links/cartago_archivo.tres",
	"res://data/world/links/conductos_santuario.tres",
	"res://data/world/links/laboratorio_velo.tres",
	"res://data/world/links/bosque_cache.tres",
	"res://data/world/links/bosque_nucleo.tres",
	"res://data/world/links/cache_archivo.tres",
	"res://data/world/links/nucleo_canales.tres",
	"res://data/world/links/canales_archivo.tres",
	"res://data/world/links/archivo_santuario.tres",
	"res://data/world/links/canales_santuario.tres",
	"res://data/world/links/santuario_velo.tres",
]


static func regions(kind := -1) -> Array[WorldRegion]:
	var result: Array[WorldRegion] = []
	for path in REGIONS:
		var region := load(path) as WorldRegion
		if region and (kind < 0 or region.kind == kind):
			result.append(region)
	return result


static func links() -> Array[RegionLink]:
	var result: Array[RegionLink] = []
	for path in LINKS:
		var link := load(path) as RegionLink
		if link:
			result.append(link)
	return result


static func get_region(id: StringName) -> WorldRegion:
	for region in regions():
		if region.id == id:
			return region
	return null


static func get_link(id: StringName) -> RegionLink:
	for link in links():
		if link.id == id:
			return link
	return null


## Región a la que pertenece un distrito de World (o null).
static func region_of_district(district_id: StringName) -> WorldRegion:
	for region in regions():
		if region.districts.has(String(district_id)):
			return region
	return null


static func is_visited(region: WorldRegion, state: Node, world: Node) -> bool:
	if state.has_flag(StringName("region_visitada_%s" % region.id)):
		return true
	if world == null:
		return false
	for room_id: StringName in world.visited:
		if region.districts.has(String(world.district_of(room_id))):
			return true
	return false


static func state_of(region: WorldRegion, state: Node, world: Node) -> State:
	if is_visited(region, state, world):
		return State.VISITADA
	if state.has_flag(StringName("region_descubierta_%s" % region.id)) or (region.reveal and region.reveal.is_met(state)):
		return State.DESCUBIERTA
	if region.secret:
		return State.DESCONOCIDA
	for link in links():
		if not link.touches(region.id) or link.kind == RegionLink.Kind.OCULTO:
			continue
		var other := get_region(link.other(region.id))
		if other and is_visited(other, state, world):
			return State.NIEBLA
	return State.DESCONOCIDA


## Si una conexión se dibuja en el mapa: las ocultas, solo cuando se pueden usar; las demás, cuando sus
## dos regiones se ven (al menos con niebla) y alguna se visitó o se descubrió.
static func is_link_known(link: RegionLink, state: Node, world: Node) -> bool:
	var a := get_region(link.region_a)
	var b := get_region(link.region_b)
	if a == null or b == null:
		return false
	var state_a := state_of(a, state, world)
	var state_b := state_of(b, state, world)
	if state_a == State.DESCONOCIDA or state_b == State.DESCONOCIDA:
		return false
	if link.kind == RegionLink.Kind.OCULTO and not link.is_open(state):
		return false
	return maxi(state_a, state_b) >= State.DESCUBIERTA


## Al entrar a una sala: si es la primera vez en su región, la marca como visitada y devuelve la región
## (para avisar «Región descubierta»); si no, null.
static func enter_room(room_id: StringName, state: Node, world: Node) -> WorldRegion:
	var region := region_of_district(world.district_of(room_id))
	if region == null:
		return null
	var flag := StringName("region_visitada_%s" % region.id)
	if state.has_flag(flag):
		return null
	state.set_flag(flag)
	# Si ya conocía otra sala de la región (partidas de antes), no es un descubrimiento nuevo.
	for other: StringName in world.visited:
		if other != room_id and region.districts.has(String(world.district_of(other))):
			return null
	return region

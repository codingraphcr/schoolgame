class_name Shop
extends RefCounted
## La tienda de la soda: el catálogo (ShopItem en data/shop/articulos/), qué se ve y qué se puede comprar en esta
## partida, y la compra (cobra con Economy, aplica el efecto y deja la marca «compra_<id>», que se guarda con la
## ranura). Cada artículo se compra una sola vez; nunca se cobra sin entregar ni se entrega sin cobrar.

const ITEMS_DIR := "res://data/shop/articulos"
## La tienda se abre después de hablar con la señora de la soda.
const OPEN_FLAG := &"soda_presentada"

enum Status { DISPONIBLE, SIN_ECOS, BLOQUEADO, COMPRADO }

const STATUS_NAMES: Array[String] = ["Disponible", "Faltan Ecos", "Todavía no", "Comprado"]


## Todos los artículos, en orden.
static func catalog() -> Array[ShopItem]:
	var result: Array[ShopItem] = []
	for file in ResourceLoader.list_directory(ITEMS_DIR):
		if file.ends_with(".tres"):
			var item := load(ITEMS_DIR + "/" + file) as ShopItem
			if item:
				result.append(item)
	result.sort_custom(func(a: ShopItem, b: ShopItem) -> bool: return a.order < b.order)
	return result


static func is_open(state: Node) -> bool:
	return state.has_flag(OPEN_FLAG)


## Los artículos que se ven ahora (los de capítulos que todavía no llegan no aparecen).
static func visible_items(state: Node) -> Array[ShopItem]:
	var result: Array[ShopItem] = []
	for item in catalog():
		if item.requirement == null or item.requirement.is_met(state):
			result.append(item)
	return result


static func bought_flag(item: ShopItem) -> StringName:
	return StringName("compra_%s" % item.id)


static func is_bought(state: Node, item: ShopItem) -> bool:
	return state.has_flag(bought_flag(item))


static func status(state: Node, economy: Node, item: ShopItem) -> Status:
	if is_bought(state, item):
		return Status.COMPRADO
	if not blocked_reason(state, item).is_empty():
		return Status.BLOQUEADO
	if not economy.can_afford_ecos(item.price):
		return Status.SIN_ECOS
	return Status.DISPONIBLE


## Por qué todavía no se puede comprar ("" = se puede, si alcanzan los Ecos).
static func blocked_reason(state: Node, item: ShopItem) -> String:
	match item.kind:
		ShopItem.Kind.DASH:
			if state.dash_level < item.value - 1:
				return "Primero hace falta el dash de nivel %d." % (item.value - 1)
			if state.dash_level >= item.value:
				return "Ya tenés ese dash."
		ShopItem.Kind.ESPADA:
			if state.nullblade_stage < 1:
				return "Hace falta la Nullblade."
			if state.sword_level < item.value - 1:
				return "Primero hace falta la mejora %d de la espada." % (item.value - 1)
			if state.sword_level >= item.value:
				return "La espada ya tiene esa mejora."
		ShopItem.Kind.DOBLE_SALTO:
			if state.can_double_jump:
				return "Ya sabés hacer doble salto."
		ShopItem.Kind.AEGIS:
			if state.aegis_stage < 1:
				return "Hace falta Aegis."
	return ""


## Compra: false si no se puede (sin cobrar nada). Si se puede, cobra, aplica el efecto y deja la marca.
static func buy(state: Node, economy: Node, item: ShopItem) -> bool:
	if not is_open(state) or status(state, economy, item) != Status.DISPONIBLE:
		return false
	if not economy.spend_ecos(item.price):
		return false
	apply(state, item)
	state.set_flag(bought_flag(item))
	return true


static func apply(state: Node, item: ShopItem) -> void:
	match item.kind:
		ShopItem.Kind.FRAGMENTO_VIDA:
			state.add_life_fragment()
		ShopItem.Kind.FRAGMENTO_ENERGIA:
			state.add_energy_fragment()
		ShopItem.Kind.DASH:
			state.set_dash_level(item.value)
		ShopItem.Kind.ESPADA:
			state.set_sword_level(item.value)
		ShopItem.Kind.DOBLE_SALTO:
			state.unlock_double_jump()
		ShopItem.Kind.AEGIS:
			state.set_flag(StringName("aegis_mejora_%d" % item.value))
		ShopItem.Kind.PISTA:
			if item.reveal_flag != &"":
				state.set_flag(item.reveal_flag)

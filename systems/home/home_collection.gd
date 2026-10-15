class_name HomeCollection
extends RefCounted
## Registro de los objetos del cuarto de Kai (Keepsake). Para agregar uno: crear el .tres en
## data/home/keepsakes/ y añadirlo aquí (como QuestDB: una lista explícita funciona igual exportado).

const PATHS: Array[String] = [
	# Recuerdos (estantería de recuerdos).
	"res://data/home/keepsakes/robot_juguete.tres",
	"res://data/home/keepsakes/foto_familia.tres",
	"res://data/home/keepsakes/foto_escuela.tres",
	"res://data/home/keepsakes/pulsera_amistad.tres",
	"res://data/home/keepsakes/kit_electronica.tres",
	"res://data/home/keepsakes/dibujo_hermanos.tres",
	"res://data/home/keepsakes/nota_vecino.tres",
	# Fragmentos de Datos (estantería de coleccionables).
	"res://data/home/keepsakes/fragmento_pasillo.tres",
	"res://data/home/keepsakes/fragmento_hermanos.tres",
	"res://data/home/keepsakes/fragmento_bosque.tres",
	# Regalos de mamá y papá (preparado: todavía no se entregan).
	"res://data/home/keepsakes/reloj_papa.tres",
]


static func all() -> Array[Keepsake]:
	var result: Array[Keepsake] = []
	for path in PATHS:
		var item := load(path) as Keepsake
		if item:
			result.append(item)
	return result


static func get_item(id: StringName) -> Keepsake:
	for item in all():
		if item.id == id:
			return item
	return null


## Los de esas categorías, en el orden de su estantería; con only_unlocked, solo los que ya tiene Kai.
static func of_categories(categories: Array[Keepsake.Category], state: Node = null, only_unlocked := false) -> Array[Keepsake]:
	var result: Array[Keepsake] = []
	for item in all():
		if not categories.has(item.category):
			continue
		if only_unlocked and (state == null or not item.is_unlocked(state)):
			continue
		result.append(item)
	result.sort_custom(func(a: Keepsake, b: Keepsake) -> bool: return a.shelf_slot < b.shelf_slot)
	return result

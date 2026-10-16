class_name ShopItem
extends Resource
## Un artículo de la tienda de la soda (la tienda oficial del juego). Un .tres por artículo en data/shop/articulos/.
## Aparece en el catálogo cuando la partida cumple requirement (capítulo, marcas, habilidades: el catálogo crece con
## los capítulos) y se puede comprar si además se cumple el requisito propio del tipo (p. ej. el dash nivel 2 pide
## tener el nivel 1). Cada artículo se compra una sola vez (marca «compra_<id>»). Lo que hace al comprarlo depende
## de kind (Shop.apply).

enum Kind {
	FRAGMENTO_VIDA,      ## Suma un fragmento de vida (GameState.add_life_fragment).
	FRAGMENTO_ENERGIA,   ## Suma un fragmento de energía.
	DASH,                ## Sube el dash al nivel value (pide el nivel anterior).
	ESPADA,              ## Sube la mejora de la Nullblade al nivel value (pide el nivel anterior y la Nullblade).
	DOBLE_SALTO,         ## Desbloquea el doble salto.
	AEGIS,               ## Mejora secundaria de Aegis (marca «aegis_mejora_<value>»; pide tener a Aegis).
	PISTA,               ## Deja la marca reveal_flag (abre una página de pistas del Grimorio o revela un mapa).
}

const KIND_NAMES: Array[String] = ["Fragmento de vida", "Fragmento de energía", "Mejora del dash", "Mejora de la espada",
	"Habilidad", "Mejora de Aegis", "Pista"]

@export var id: StringName = &""
@export var title := ""
@export var kind := Kind.FRAGMENTO_VIDA
@export_multiline var description := ""
## Lo que comenta la señora de la soda (o Kai) al mirarlo; opcional.
@export var note := ""
@export var price := 100
## Nivel (DASH, ESPADA) o número de mejora (AEGIS).
@export var value := 1
## Marca que deja al comprarlo (PISTA): p. ej. «mapa_colegio» o «pista_colegio».
@export var reveal_flag: StringName = &""
## Cuándo aparece en el catálogo (vacío = desde que se abre la tienda).
@export var requirement: WorldRequirement
## Orden en el catálogo (de menor a mayor).
@export var order := 0

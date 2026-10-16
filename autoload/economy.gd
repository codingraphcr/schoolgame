extends Node
## Economía del juego: el saldo de ECOS, la moneda oficial (residuos de información que dejan las
## amenazas neutralizadas y las estructuras de datos fragmentadas). Solo se obtienen jugando.
##
## Es el ÚNICO lugar donde cambia el saldo, siempre con estas funciones (validan todo):
##   add_ecos(cantidad) · spend_ecos(cantidad) · can_afford_ecos(cantidad) · apply_death_penalty()
## Nunca hay saldos negativos ni cantidades inválidas. GameState la incluye al guardar (to_dict).
##
## Recompensas únicas (misiones, terminales, desafíos, cofres, fragmentos, enemigos de la historia):
## cada una tiene un id estable y solo se paga la primera vez (claim_reward / claim_drop). Los ids
## reclamados se guardan con la partida. Los valores salen de EconomyConfig (data/economy/economia.tres).

signal ecos_changed(ecos: int, delta: int)
## Se cobró por primera vez una recompensa única (el guardado automático la guarda enseguida).
signal reward_claimed(id: StringName)

const CONFIG_PATH := "res://data/economy/economia.tres"
## Marca de GameState que termina el tutorial (al final del prólogo, «EL DESPERTAR»).
const TUTORIAL_DONE_FLAG := &"tutorial_terminado"
## Lo máximo que cabe en la bolsa de Ecos (decisión del equipo: precios y recompensas se equilibran con este tope).
## Lo que pase del tope se pierde (avisa «Bolsa de Ecos llena»).
const MAX_ECOS := 999

var ecos := 0
## Valores para equilibrar (rangos de recompensa y penalización).
var config: EconomyConfig = load(CONFIG_PATH)
## Para sortear recompensas (las pruebas pueden fijar la semilla).
var rng := RandomNumberGenerator.new()

## Recompensas únicas ya reclamadas: { id: true }.
var _claimed: Dictionary[StringName, bool] = {}


func _ready() -> void:
	rng.randomize()


## Partida nueva.
func reset() -> void:
	ecos = 0
	_claimed.clear()
	ecos_changed.emit(ecos, 0)  # Sin «−X» en el HUD: no es una pérdida.


## Suma Ecos. Rechaza (false) cantidades de 0 o negativas.
func add_ecos(amount: int) -> bool:
	if amount <= 0:
		push_warning("Economy: cantidad inválida de Ecos (%d)." % amount)
		return false
	var before := ecos
	ecos = mini(ecos + amount, MAX_ECOS)
	ecos_changed.emit(ecos, ecos - before)
	if before + amount > MAX_ECOS and is_inside_tree():
		get_tree().call_group(&"toast", &"show_message", "Bolsa de Ecos llena: el máximo es %d." % MAX_ECOS, 3.0)
	return true


## Si alcanza para pagar esa cantidad.
func can_afford_ecos(amount: int) -> bool:
	return amount >= 0 and amount <= ecos


## Paga. Devuelve false (sin descontar nada) si la cantidad es inválida o no alcanza.
func spend_ecos(amount: int) -> bool:
	if amount <= 0 or amount > ecos:
		return false
	ecos -= amount
	ecos_changed.emit(ecos, -amount)
	return true


## Cuántos Ecos se perderían al morir con este saldo (10 % hacia abajo, máximo 100, según EconomyConfig).
func death_penalty_for(amount: int) -> int:
	return mini(floori(maxi(amount, 0) * config.death_penalty), config.death_penalty_max)


## Al perder un combate. Devuelve cuántos Ecos se perdieron (0 durante el tutorial).
func apply_death_penalty() -> int:
	if in_tutorial():
		return 0
	var lost := death_penalty_for(ecos)
	if lost > 0:
		ecos -= lost
		ecos_changed.emit(ecos, -lost)
	return lost


## Durante el tutorial (hasta «EL DESPERTAR») no se pierden Ecos.
func in_tutorial() -> bool:
	var game_state := get_node_or_null("/root/GameState")
	return game_state != null and not game_state.has_flag(TUTORIAL_DONE_FLAG)


# --- Recompensas ---

## Un valor sorteado dentro del rango de esa fuente (EconomyConfig).
func roll(source: EconomyConfig.Source) -> int:
	var range_ := config.range_for(source)
	return rng.randi_range(mini(range_.x, range_.y), maxi(range_.x, range_.y))


## La cantidad fija si se indicó (>= 0) o una sorteada para esa fuente (-1 = según EconomyConfig).
func reward_for(source: EconomyConfig.Source, fixed := -1) -> int:
	return fixed if fixed >= 0 else roll(source)


## Paga una recompensa única: la primera vez suma los Ecos y devuelve cuántos; después devuelve 0.
func claim_reward(id: StringName, amount: int) -> int:
	if not claim_drop(id) or amount <= 0:
		return 0
	add_ecos(amount)
	return amount


## Para recompensas que caen al suelo (cofres, enemigos de la historia): registra el id y devuelve
## true solo la primera vez. Los Ecos se suman al recoger los fragmentos (o al salir de la sala).
func claim_drop(id: StringName) -> bool:
	if id == &"" or _claimed.has(id):
		return false
	_claimed[id] = true
	reward_claimed.emit(id)
	return true


func is_claimed(id: StringName) -> bool:
	return _claimed.has(id)


func to_dict() -> Dictionary:
	var claimed: Array[String] = []
	for id: StringName in _claimed:
		claimed.append(String(id))
	return { "ecos": ecos, "claimed": claimed }


## Carga el saldo. legacy_credits: los «créditos» de partidas guardadas antes de los Ecos.
func from_dict(data: Dictionary, legacy_credits := 0) -> void:
	ecos = clampi(int(data.get("ecos", legacy_credits)), 0, MAX_ECOS)
	_claimed.clear()
	for id: String in data.get("claimed", []):
		_claimed[StringName(id)] = true
	ecos_changed.emit(ecos, 0)

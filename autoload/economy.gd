extends Node
## Economía del juego: el saldo de ECOS, la moneda oficial (residuos de información que dejan las
## amenazas neutralizadas y las estructuras de datos fragmentadas). Solo se obtienen jugando.
##
## Es el ÚNICO lugar donde cambia el saldo, siempre con estas funciones (validan todo):
##   add_ecos(cantidad) · spend_ecos(cantidad) · can_afford_ecos(cantidad) · apply_death_penalty()
## Nunca hay saldos negativos ni cantidades inválidas. GameState la incluye al guardar (to_dict).

signal ecos_changed(ecos: int, delta: int)

## Al morir se pierde el 10 % (hacia abajo), como máximo 100 Ecos, y nada durante el tutorial.
const DEATH_PENALTY := 0.10
const DEATH_PENALTY_MAX := 100
## Marca de GameState que termina el tutorial (al final del prólogo, «EL DESPERTAR»).
const TUTORIAL_DONE_FLAG := &"tutorial_terminado"
## Tope de seguridad del saldo.
const MAX_ECOS := 999_999

var ecos := 0


## Partida nueva.
func reset() -> void:
	ecos = 0
	ecos_changed.emit(ecos, 0)  # Sin «−X» en el HUD: no es una pérdida.


## Suma Ecos. Rechaza (false) cantidades de 0 o negativas.
func add_ecos(amount: int) -> bool:
	if amount <= 0:
		push_warning("Economy: cantidad inválida de Ecos (%d)." % amount)
		return false
	var before := ecos
	ecos = mini(ecos + amount, MAX_ECOS)
	ecos_changed.emit(ecos, ecos - before)
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


## Cuántos Ecos se perderían al morir con este saldo (10 % hacia abajo, máximo 100).
static func death_penalty_for(amount: int) -> int:
	return mini(floori(maxi(amount, 0) * DEATH_PENALTY), DEATH_PENALTY_MAX)


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


func to_dict() -> Dictionary:
	return { "ecos": ecos }


## Carga el saldo. legacy_credits: los «créditos» de partidas guardadas antes de los Ecos.
func from_dict(data: Dictionary, legacy_credits := 0) -> void:
	ecos = clampi(int(data.get("ecos", legacy_credits)), 0, MAX_ECOS)
	ecos_changed.emit(ecos, 0)

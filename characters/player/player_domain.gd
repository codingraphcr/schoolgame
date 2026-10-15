class_name PlayerDomain
extends Node
## Expansión Digital: Dominio Nulo (la definitiva de Kai, R, acción "ultimate"). Se obtiene en el
## Capítulo 2 (GameState.domain_stage). Valores por etapa (docs/combate.md):
##   I: 15 s, +10 % de daño, 100 de carga · II: 20 s, +15 %, 115 · III: 30 s, +30 %, 138.
## Mientras dura, las amenazas digitales y los proyectiles compatibles van al 80 % (CombatClock) y la
## Nullblade pega más (damage_multiplier(), aplicado en un solo lugar: PlayerCombat al activar el
## golpe). Se carga golpeando enemigos con la Nullblade (CHARGE_PER_HIT). La carga vive en GameState
## (se mantiene entre salas). Dibuja su barra en el HUD (solo con el Dominio obtenido) y un velo violeta.

signal activated
signal ended

## [duración, bonificación de daño, carga necesaria] por etapa (1 a 3).
const STAGES := [[15.0, 0.10, 100.0], [20.0, 0.15, 115.0], [30.0, 0.30, 138.0]]
## Velocidad de las amenazas durante el Dominio.
const THREAT_SCALE := 0.8
const CHARGE_PER_HIT := 10.0
const VIOLET := Color("8a3eff")
const CYAN := Color("3ef2ff")

var active := false
var time_left := 0.0

var _layer: CanvasLayer
var _hud: Control
var _veil: ColorRect
var _clock := 0.0

@onready var player: Player = get_parent()


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 35
	add_child(_layer)
	_veil = ColorRect.new()
	_veil.color = Color(VIOLET, 0.0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_veil)
	_hud = Control.new()
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.position = Vector2(24, 128)  # Debajo de los Ecos.
	_hud.size = Vector2(240, 34)
	_hud.draw.connect(_draw_hud)
	_layer.add_child(_hud)


func _exit_tree() -> void:
	if active:
		CombatClock.reset()


func stage() -> int:
	var state := get_node_or_null("/root/GameState")
	return state.domain_stage if state else 0


func is_unlocked() -> bool:
	return stage() > 0


func cost() -> float:
	return STAGES[clampi(stage() - 1, 0, 2)][2]


func duration() -> float:
	return STAGES[clampi(stage() - 1, 0, 2)][0]


func charge() -> float:
	var state := get_node_or_null("/root/GameState")
	return state.domain_charge if state else 0.0


func set_charge(value: float) -> void:
	var state := get_node_or_null("/root/GameState")
	if state:
		state.domain_charge = clampf(value, 0.0, cost())


func add_charge(amount: float) -> void:
	if is_unlocked() and not active:
		set_charge(charge() + amount)


## Multiplicador de daño de la Nullblade (1 fuera del Dominio).
func damage_multiplier() -> float:
	return 1.0 + STAGES[clampi(stage() - 1, 0, 2)][1] if active else 1.0


func can_activate() -> bool:
	return is_unlocked() and not active and charge() >= cost() and not player.controls_locked


## Activa el Dominio (force: la historia lo activa aunque falte carga o Kai no tenga el control).
func activate(force := false) -> bool:
	if active or not is_unlocked() or (not force and not can_activate()):
		return false
	active = true
	time_left = duration()
	set_charge(0.0)
	CombatClock.threat_scale = THREAT_SCALE
	Sfx.play(&"boss_charge", 1.4)
	get_tree().call_group(&"toast", &"show_message", "EXPANSIÓN DIGITAL: %s" % GameState.DOMAIN_NAMES[stage()].to_upper(), 1.8)
	activated.emit()
	return true


func end() -> void:
	if not active:
		return
	active = false
	time_left = 0.0
	CombatClock.reset()
	ended.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ultimate") and can_activate():
		get_viewport().set_input_as_handled()
		activate()


func _physics_process(delta: float) -> void:
	if active:
		time_left -= delta
		if time_left <= 0.0:
			end()


func _process(delta: float) -> void:
	_clock += delta
	var target := 0.13 + 0.03 * sin(_clock * 3.0) if active else 0.0
	_veil.color.a = move_toward(_veil.color.a, target, delta * 0.6)
	_hud.visible = is_unlocked()
	_hud.queue_redraw()


func _draw_hud() -> void:
	var font := ThemeDB.fallback_font
	var full := charge() >= cost()
	var label := "DOMINIO NULO · %s" % ("%.0f s" % time_left if active else ("LISTO [%s]" % GameSettings.key_name(&"ultimate") if full else "%d %%" % int(charge() / cost() * 100.0)))
	_hud.draw_string(font, Vector2(0, 13), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, CYAN if full or active else Color(0.8, 0.75, 1.0))
	var bar := Rect2(0, 19, 170, 7)
	_hud.draw_rect(bar.grow(1), Color(0.05, 0.03, 0.1))
	var ratio := time_left / duration() if active else charge() / cost()
	var color := VIOLET.lerp(CYAN, 0.5 + 0.5 * sin(_clock * 6.0)) if full or active else VIOLET
	_hud.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(ratio, 0.0, 1.0), bar.size.y)), color)

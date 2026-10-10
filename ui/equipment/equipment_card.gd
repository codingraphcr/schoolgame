class_name EquipmentCard
extends Control
## Tarjeta "NUEVO EQUIPAMIENTO DESBLOQUEADO" (concepto de Ariel): arte del objeto, nombre grande,
## descripción, cartel de obtenido y la tecla para usarlo. Pausa el juego hasta que se cierra
## (E, Espacio, Enter o la tecla del objeto, después de un instante para no saltarla sin querer).
## Uso: await EquipmentCard.show_card(nodo, { "art": textura, "title": "NULLBLADE", ... })

signal closed

const SCENE_PATH := "res://ui/equipment/equipment_card.tscn"
## Segundos antes de poder cerrarla.
const MIN_TIME := 0.7

var _time := 0.0
var _action: StringName = &""

@onready var _panel: Control = %Panel
@onready var _art: TextureRect = %Art
@onready var _subtitle: Label = %Subtitle
@onready var _title: Label = %Title
@onready var _description: Label = %Description
@onready var _banner: Label = %Banner
@onready var _key: Label = %Key
@onready var _hint: Label = %Hint


## Muestra la tarjeta encima del juego (en pausa) y espera a que se cierre.
## info: art (Texture2D), subtitle, title, description, banner, action (acción cuya tecla se muestra), hint.
static func show_card(from: Node, info: Dictionary) -> void:
	var layer := CanvasLayer.new()
	layer.name = "EquipmentCardLayer"
	layer.layer = 95
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var card := (load(SCENE_PATH) as PackedScene).instantiate() as EquipmentCard
	layer.add_child(card)
	from.get_tree().root.add_child(layer)
	card.fill(info)
	var tree := from.get_tree()
	var was_paused := tree.paused
	tree.paused = true
	await card.closed
	tree.paused = was_paused
	layer.queue_free()


func fill(info: Dictionary) -> void:
	_art.texture = info.get("art")
	_subtitle.text = info.get("subtitle", "NUEVO EQUIPAMIENTO DESBLOQUEADO")
	_title.text = info.get("title", "")
	_description.text = info.get("description", "")
	_banner.text = info.get("banner", "")
	_action = info.get("action", &"")
	var key := GameSettings.key_name(_action) if _action != &"" else "E"
	_key.text = key
	_hint.text = info.get("hint", "")


func _ready() -> void:
	# Aparece con un salto pequeño y un parpadeo de glitch.
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.92, 0.92)
	modulate.a = 0.0
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.35)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	Sfx.play(&"fanfare")


func _process(delta: float) -> void:
	_time += delta
	# El arte flota y el título tiembla de vez en cuando (menos si se reducen los efectos glitch).
	_art.position.y = sin(_time * 2.0) * 4.0
	var glitchy := not GameSettings.reduce_glitch and fmod(_time, 2.4) < 0.08
	_title.position.x = randf_range(-3.0, 3.0) if glitchy else 0.0
	_title.modulate = Color(1.0, 0.85, 1.0) if glitchy else Color.WHITE


func _input(event: InputEvent) -> void:
	if _time < MIN_TIME:
		return
	var close := event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept") \
		or event.is_action_pressed(&"jump") or (_action != &"" and event.is_action_pressed(_action))
	if close:
		get_viewport().set_input_as_handled()
		set_process_input(false)
		Sfx.play(&"ui_accept")
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.15)
		tween.tween_callback(closed.emit)

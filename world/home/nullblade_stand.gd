class_name NullbladeStand
extends Node2D
## Soporte de la Nullblade en el cuarto de Kai: cuando Kai está en su cuarto la espada descansa ahí
## (solo se ve; sigue en su equipo y la tiene al salir) y con E se mira de cerca: la forma actual, su
## historia, lo que puede hacer y las formas que faltan, bloqueadas hasta que la historia las despierte
## (NullbladeForm; nunca se compran con Ecos). El origen es la base del soporte.

const SWORD := preload("res://assets/art/items/nullblade/nullblade_espada.png")
const FORM_TINTS: Array[Color] = [Color.WHITE, Color.WHITE, Color("e8f4ff"), Color("c9a6ff"), Color("ffe08a")]

@export var prompt_text := "E: mirar la Nullblade"

var interactable: Interactable
var _time := 0.0


func _ready() -> void:
	interactable = Interactable.new()
	interactable.prompt_text = prompt_text
	interactable.prompt_offset = Vector2(-46, -86)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 48)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	interactable.add_child(shape)
	add_child(interactable)
	interactable.interacted.connect(func(_player: Player) -> void: inspect())


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func has_sword() -> bool:
	return _state().nullblade_stage >= 1


func inspect() -> InspectionWindow:
	var state := _state()
	var list: Array[Dictionary] = []
	for form in NullbladeForm.all():
		var known := form.is_known(state)
		var lines := PackedStringArray()
		for ability in form.abilities:
			lines.append("• " + ability)
		var tint: Color = FORM_TINTS[clampi(form.stage, 0, FORM_TINTS.size() - 1)]
		list.append({
			"name": form.display_name,
			"subtitle": "Forma actual" if form.stage == state.nullblade_stage else ("Forma conocida" if known else ""),
			"description": form.description + ("\n\n" + form.history if not form.history.is_empty() else ""),
			"note": form.note_for(state),
			"lines": lines,
			"locked": not known,
			"locked_text": "Una forma que todavía no despertó.",
			"draw": func(canvas: CanvasItem, rect: Rect2, _t: float) -> void: _draw_sword(canvas, rect, tint),
		})
	interactable.busy = true
	var window := InspectionWindow.open(self, "NULLBLADE", list)
	window.closed.connect(func() -> void: interactable.busy = false)
	if has_sword():
		window.select(clampi(state.nullblade_stage - 1, 0, list.size() - 1))
	return window


static func _draw_sword(canvas: CanvasItem, rect: Rect2, tint: Color) -> void:
	var size := SWORD.get_size()
	var scale := minf(rect.size.x / size.x, rect.size.y / size.y)
	var fitted := size * scale
	canvas.draw_texture_rect(SWORD, Rect2(rect.position + (rect.size - fitted) / 2.0, fitted), false, tint)


func _draw() -> void:
	# Soporte de pared: dos ganchos y una repisita.
	draw_rect(Rect2(-26, -64, 52, 4), Color("4a3020"))
	draw_rect(Rect2(-22, -70, 4, 10), Color("7a5236"))
	draw_rect(Rect2(18, -70, 4, 10), Color("7a5236"))
	if not has_sword():
		return
	var glow := 0.5 + 0.5 * sin(_time * 1.6)
	draw_circle(Vector2(0, -74), 22.0 + glow * 3.0, Color(0.24, 0.95, 1.0, 0.06 + glow * 0.04))
	var size := SWORD.get_size()
	var scale := 46.0 / maxf(size.x, size.y)
	draw_set_transform(Vector2(0, -74), -PI / 2.0 if size.y > size.x else 0.0, Vector2(scale, scale))
	draw_texture(SWORD, -size / 2.0)
	draw_set_transform(Vector2.ZERO)


func _state() -> Node:
	return get_node("/root/GameState")

class_name ShopKeeper
extends FamilyMember
## La señora de la soda atendiendo su tienda: con E saluda (lo de siempre de un Npc: dialogue la primera vez,
## repeat_dialogue después, o lo del momento de la historia) y enseguida abre la tienda (ShopWindow).

signal shop_closed


func _on_interacted(player: Player) -> void:
	await super(player)
	_interactable.busy = true
	player.controls_locked = true
	await ShopWindow.open(self).closed
	player.controls_locked = false
	await get_tree().process_frame
	_interactable.busy = false
	shop_closed.emit()

class_name FrameWait
extends RefCounted
## Esperar un cuadro sin romperse si la sala se cierra a mitad (cambio de escena, menú de pruebas F9, cargar
## partida): entonces el nodo ya no está en la escena, get_tree() es null y `await get_tree().physics_frame`
## falla («Invalid access to 'physics_frame' on a null instance»). Estas esperas devuelven false si el nodo
## ya no está (o se borró): el bucle que espera tiene que terminar.
## Uso: while ...: if not await FrameWait.physics(self): return


## Espera un cuadro de física. false si node ya no está en la escena.
static func physics(node: Node) -> bool:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return false
	await node.get_tree().physics_frame
	return is_instance_valid(node) and node.is_inside_tree()


## Espera un cuadro de proceso. false si node ya no está en la escena.
static func process(node: Node) -> bool:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return false
	await node.get_tree().process_frame
	return is_instance_valid(node) and node.is_inside_tree()

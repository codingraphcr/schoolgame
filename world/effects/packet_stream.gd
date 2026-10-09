extends Node2D
## Paquetes de datos que viajan por el cable del techo. Al pasar por la zona infectada
## cambian a la textura de paquete malicioso (pista visual de la amenaza).

@export var packet_texture: Texture2D
@export var infected_texture: Texture2D
@export var count := 7
@export var spacing := 140.0
@export var speed := 70.0
## Ancho del recorrido; al salir por la derecha vuelven a entrar por la izquierda.
@export var length := 960.0
## Desde esta x (local) los paquetes aparecen infectados. Negativo = nunca.
@export var infected_from_x := 792.0

var _packets: Array[Sprite2D] = []


func _ready() -> void:
	for i in count:
		var packet := Sprite2D.new()
		packet.texture = packet_texture
		packet.position = Vector2(i * spacing + 20.0, 2.0 * (i % 3))
		add_child(packet)
		_packets.append(packet)


func _process(delta: float) -> void:
	for packet in _packets:
		packet.position.x += speed * delta
		if packet.position.x > length + 8.0:
			packet.position.x = -8.0
		var infected := infected_from_x >= 0.0 and packet.position.x > infected_from_x
		packet.texture = infected_texture if infected and infected_texture else packet_texture

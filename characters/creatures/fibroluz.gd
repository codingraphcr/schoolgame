class_name Fibroluz
extends DigitalCreature
## Fibroluz (Bosque de Fibra): una criaturita que transporta señales. Lleva un paquete de luz entre los nodos
## del bosque (patrulla); si una conexión se corta, se queda esperando junto al corte. Curiosa con Kai, se
## asusta con los ataques y el dash. Puede guiarlo un tramo hasta una conexión perdida (guide). No hace daño
## y no se le puede hacer daño: no existe para ser vencida. Dibujo provisional por código.

const BODY := Color("9ff8ff")
const CORE := Color("3ef2ff")
const PACKET := Color("fff0a0")

## Si lleva su paquete de luz (sin señal no tiene qué llevar: se apaga un poco).
@export var carrying := true


func _draw() -> void:
	var t := _clock
	var bob := sin(t * 4.0) * 2.0
	var dim := 1.0 if carrying else 0.55
	var fleeing := state == State.HUIDA
	# Halo, cuerpo (una gotita de luz), antenas de fibra y patitas.
	draw_circle(Vector2(0, -10 + bob), 14.0, Color(CORE, 0.12 * dim))
	draw_circle(Vector2(0, -10 + bob), 7.0, Color(BODY, dim))
	draw_circle(Vector2(0, -10 + bob), 4.0, Color(CORE, dim))
	for side in [-1.0, 1.0]:
		var tip := Vector2(side * 6.0 + face * 2.0, -24 + bob + sin(t * 6.0 + side) * 2.0)
		draw_line(Vector2(side * 2.0, -15 + bob), tip, Color(BODY, 0.8 * dim), 1.2)
		draw_circle(tip, 1.6, Color(PACKET, dim))
		draw_line(Vector2(side * 3.0, -5 + bob), Vector2(side * 5.0, -1), Color(BODY, 0.7 * dim), 1.0)
	# Ojos (miran hacia donde va; asustada, abiertos de más).
	var eye := 1.6 if fleeing else 1.1
	draw_circle(Vector2(face * 2.5 - 1.5, -11 + bob), eye, Color("0a1a2a"))
	draw_circle(Vector2(face * 2.5 + 1.5, -11 + bob), eye, Color("0a1a2a"))
	# El paquete de luz que transporta.
	if carrying:
		var packet := Vector2(-face * 9.0, -14 + bob + sin(t * 3.0) * 1.5)
		draw_circle(packet, 3.0, Color(PACKET, 0.9))
		draw_circle(packet, 6.0, Color(PACKET, 0.15))

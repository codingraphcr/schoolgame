@tool
extends Node2D
## Ventana "Cuenta del profesor" al final del nivel de SPAM: muestra la contraseña débil, que no hay
## verificación en dos pasos, y la pestaña "Cambiar contraseña" (que late cuando se puede usar).
## El origen es la esquina inferior izquierda, apoyada en el suelo.

const MAG := Color("ff3ea5")
const CYAN := Color("3ef2ff")
const DARK := Color("1b2647")

@export var size := Vector2(190, 150):
	set(value):
		size = value
		if _canvas:
			_canvas.queue_redraw()
## Si la pestaña "Cambiar contraseña" está lista para usarse (se ilumina).
@export var tab_ready := false

var _canvas: VectorCanvas


func _ready() -> void:
	_canvas = VectorCanvas.new()
	_canvas.painter = _paint
	_canvas.animated = true
	add_child(_canvas)


func _paint(c: VectorCanvas, t: float) -> void:
	var window := Rect2(0, -size.y, size.x, size.y)
	c.glow(window.get_center(), size.x * 0.7, Color(MAG, 0.08 + 0.04 * sin(t * 2.0)))
	c.draw_rect(Rect2(window.position + Vector2(3, 3), window.size), Color(0, 0, 0, 0.35))
	c.gradient_box(window, 4.0, Color("eef2fb"), Color("cdd7ec"), MAG, 1.4)
	c.draw_rect(Rect2(window.position, Vector2(size.x, 16)), Color("2a3a6a"))
	c.crisp_text(window.position + Vector2(6, 11), "Cuenta del profesor", 6, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	# Pestañas.
	var tab_password := Rect2(window.position + Vector2(6, 22), Vector2(86, 14))
	var tab_mfa := Rect2(window.position + Vector2(96, 22), Vector2(86, 14))
	var glow := 0.5 + 0.5 * sin(t * 5.0) if tab_ready else 0.0
	c.gradient_box(tab_password, 2.0, MAG.lerp(Color.WHITE, 0.3 * glow), MAG.darkened(0.2), Color("0a0d1c"), 1.0)
	c.crisp_text(tab_password.position + Vector2(0, 10), "Cambiar contraseña", 5, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, tab_password.size.x)
	c.gradient_box(tab_mfa, 2.0, Color("8b98b8"), Color("5a6788"), Color("0a0d1c"), 1.0)
	c.crisp_text(tab_mfa.position + Vector2(0, 10), "Verificación en 2 pasos", 5, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, tab_mfa.size.x)
	# Estado de la cuenta.
	var y := window.position.y + 54
	c.crisp_text(Vector2(window.position.x + 10, y), "Usuario: profesor@colegio", 6, DARK, HORIZONTAL_ALIGNMENT_LEFT)
	c.crisp_text(Vector2(window.position.x + 10, y + 16), "Contraseña: 123456", 6, DARK, HORIZONTAL_ALIGNMENT_LEFT)
	c.crisp_text(Vector2(window.position.x + 10, y + 32), "Seguridad: MUY DÉBIL", 6, MAG, HORIZONTAL_ALIGNMENT_LEFT)
	c.crisp_text(Vector2(window.position.x + 10, y + 48), "Verificación en dos pasos: NO", 6, MAG, HORIZONTAL_ALIGNMENT_LEFT)
	c.crisp_text(Vector2(window.position.x + 10, y + 64), "Última vez cambiada: hace 6 años", 5, DARK, HORIZONTAL_ALIGNMENT_LEFT)

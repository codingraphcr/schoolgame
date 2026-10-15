class_name BossBar
extends Control
## Barra de vida de un jefe (hoja del jefe de Ariel: "HUD durante el jefe"): arriba al centro, el
## ícono del jefe (una pantalla enojada), su nombre y la barra magenta. Una marca indica dónde
## empieza la fase 2; lo que se pierde queda un instante en blanco antes de bajar. En la fase 2 la
## barra tiembla un poco, como sus ventanas inestables.
## Uso: var bar := BossBar.show_for(hud, jefe, "CONTRASEÑA DÉBIL")  ·  bar.dismiss()
## Con dos jefes a la vez, slot 1 va debajo de la primera. phase_mark < 0 = sin marca; phase_marks:
## marcas de más fases. Con color_to, la barra pasa de color a color_to (Glitch y Chip comparten una).

const MAGENTA := Color("ff3ea5")
const PINK := Color("ff9ccf")
const DARK := Color("12081f")
const EDGE := Color("5a2a6e")
const WIDTH := 440.0
const BAR := Rect2(48, 26, 384, 10)

var boss: EnemyBase
var title := ""
## Fracción de vida donde empieza la fase 2 (marca en la barra; negativa = sin marca).
var phase_mark := 0.5
## Fila (0 arriba, 1 debajo): para dos jefes a la vez.
var slot := 0
## Color de la barra (magenta por defecto).
var color := MAGENTA
## Marcas de otras fases (fracciones de vida).
var phase_marks: Array[float] = []
## Si tiene alfa, la barra va de color (izquierda) a color_to (derecha).
var color_to := Color(0, 0, 0, 0)
## Segmentos (p. ej. los 7 impactos clave de Bucle): la barra se divide en partes iguales. 0 = sin.
var segments := 0

var _shown := 1.0
var _trail := 1.0
var _time := 0.0
var _letters := 0.0


static func show_for(hud: Node, target: EnemyBase, boss_name: String, row := 0, bar_color := MAGENTA) -> BossBar:
	var bar := BossBar.new()
	bar.boss = target
	bar.title = boss_name
	bar.slot = row
	bar.color = bar_color
	bar.name = "BossBar" if row == 0 else "BossBar%d" % (row + 1)
	hud.add_child(bar)
	return bar


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -WIDTH / 2.0
	offset_right = WIDTH / 2.0
	offset_top = 14.0 + slot * 46.0
	offset_bottom = 54.0 + slot * 46.0
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	_shown = 0.0
	_trail = 0.0
	Sfx.play(&"popup_open", 0.8)


## Se desvanece y se borra (al terminar la pelea).
func dismiss() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)


func ratio() -> float:
	if not is_instance_valid(boss) or boss.health == null:
		return 0.0
	return clampf(boss.health.current / boss.health.max_health, 0.0, 1.0)


func _process(delta: float) -> void:
	_time += delta
	_letters = minf(_letters + delta * 30.0, title.length())
	var target := ratio()
	# Al aparecer se llena de a poco; después baja de golpe y la estela blanca la sigue.
	_shown = move_toward(_shown, target, delta * (1.2 if _shown < target else 4.0))
	_trail = target if _trail < _shown else move_toward(_trail, _shown, delta * 0.6)
	queue_redraw()


func _draw() -> void:
	var unstable := ratio() <= phase_mark and ratio() > 0.0
	var shake := Vector2(randf_range(-1.0, 1.0), 0) if unstable and not GameSettings.reduce_glitch and randf() < 0.15 else Vector2.ZERO
	# Ícono: la pantalla enojada del jefe.
	var icon := Rect2(Vector2(4, 4) + shake, Vector2(34, 32))
	draw_rect(icon, DARK)
	draw_rect(icon, color, false, 1.5)
	var screen := icon.grow(-5)
	draw_rect(screen, Color("1a0626"))
	for side: int in [-1, 1]:
		var eye := screen.get_center() + Vector2(side * 6, 1)
		draw_colored_polygon(PackedVector2Array([eye + Vector2(-3 * side, -2), eye + Vector2(3 * side, 0), eye + Vector2(-2 * side, 2)]), color)
	# Nombre (se escribe letra por letra al aparecer).
	draw_string(ThemeDB.fallback_font, Vector2(BAR.position.x, 19) + shake, title.substr(0, int(_letters)), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, PINK)
	# Barra: fondo, estela blanca, vida y la marca de la fase 2.
	var bar := Rect2(BAR.position + shake, BAR.size)
	draw_rect(bar.grow(2), DARK)
	draw_rect(bar.grow(2), EDGE, false, 1.0)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _trail, bar.size.y)), Color(1, 0.85, 0.95, 0.85))
	var fill := color.lerp(Color("ff2a55"), 0.35 if unstable else 0.0)
	if color_to.a > 0.0:
		# Dos colores (Glitch rosa y Chip azul): la barra se dibuja en franjas que van de uno al otro.
		var steps := 24
		var filled := bar.size.x * _shown
		for k in steps:
			var x0 := bar.size.x * k / steps
			if x0 >= filled:
				break
			var w := minf(bar.size.x / steps + 1.0, filled - x0)
			draw_rect(Rect2(bar.position + Vector2(x0, 0), Vector2(w, bar.size.y)), fill.lerp(color_to, float(k) / (steps - 1)))
	else:
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * _shown, bar.size.y)), fill)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _shown, 2)), Color(PINK, 0.8))
	for k in range(1, segments):
		var x := bar.position.x + bar.size.x * k / segments
		draw_line(Vector2(x, bar.position.y - 1), Vector2(x, bar.end.y + 1), DARK, 2.0)
	for at: float in [phase_mark] + phase_marks:
		if at >= 0.0:
			var mark := bar.position.x + bar.size.x * at
			draw_line(Vector2(mark, bar.position.y - 3), Vector2(mark, bar.end.y + 3), PINK, 1.5)

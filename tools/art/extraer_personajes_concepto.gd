extends SceneTree
## Extrae los sprites de los personajes de sus hojas de concepto (docs/arte/referencias/) y arma
## sus animaciones. Lo usan KaiVisual (apariencia CONCEPTO) y los NPC (SpriteFrames).
## Ejecutar: godot --headless --path . --script res://tools/art/extraer_personajes_concepto.gd
##          (opcional: -- kai   o   -- profesor   para extraer uno solo)
##
## Para cada pose: quita el fondo (relleno desde los bordes, sin tocar la ropa negra), la reduce con
## la MISMA escala que la pose de referencia del personaje, limpia el borde y la coloca con los pies
## siempre en el mismo punto y la cabeza centrada. Los cuadros miden 96×128 (más anchos si la pose
## tiene efectos, como el arco de un ataque) y se muestran a mitad de escala en el mundo.
##
## Salidas por personaje (carpeta "out"):
##   <prefijo><animacion>.png → tira horizontal de cuadros
##   <prefijo>.json           → por animación: archivo, tamaño de cuadro, pies, cuadros, fps y bucle

const FRAME_HEIGHT := 128
const MIN_FRAME_WIDTH := 96
## Fila de los pies dentro del cuadro.
const FEET_Y := 119
## Escala a la que se muestran en el mundo (con la cámara ×2, 1 píxel del dibujo = 1 píxel de pantalla).
const WORLD_SCALE := 0.5
const OUTLINE := Color("0a0d1c")

## Configuración por personaje.
##   reference/height: la pose de referencia queda con ese alto (fija la escala de todas).
##   frame_height (opcional): alto de los cuadros (128 si no se pone; los pies siempre en FEET_Y).
##   poses: zona de cada pose en la hoja. feet_y (opcional): fila de los pies, si debajo hay efectos.
##          body (opcional): zona del cuerpo que el borrado del resplandor no toca.
##          tolerance (opcional): tolerancia del fondo solo para esa pose (pelo muy oscuro).
##          cover + cover_color (opcional): polígono (en la hoja) que se tapa con ese color
##          (para quitar algo que sobra).
##          recolor + recolor_color (opcional): polígono donde lo café/rosado de la figura se pinta de ese color.
##          clip (opcional): contorno (en la hoja) fuera del cual se borra todo (efectos pegados).
##          refill (opcional, con clip): vuelve a borrar el fondo que quedó encerrado y ahora toca lo recortado.
##          anchor_x (opcional): columna del centro del cuerpo si el
##          cálculo automático (centro de la cabeza) no sirve. only_body: conserva solo la figura
##          principal (descarta, por ejemplo, un globo de diálogo que quedó dentro de la zona).
##          rotate: gira la pose 90° (desplomada boca abajo, la cabeza hacia donde mira).
##   animations: poses en orden, cuadros por segundo y si se repiten.
const CHARACTERS := {
	"kai": {
		"source": "res://docs/arte/referencias/kai_hoja_concepto.webp",
		"out": "res://assets/art/characters/kai/hd/",
		"prefix": "kai_hd",
		"background": Color("0c111a"),
		"tolerance": 0.05,
		"reference": "reposo",
		"height": 96,
		"poses": {
			"reposo": { "rect": Rect2i(36, 478, 72, 144) },
			"caminar_1": { "rect": Rect2i(124, 478, 88, 144), "only_body": true },
			"caminar_2": { "rect": Rect2i(220, 478, 94, 144), "only_body": true },
			"correr": { "rect": Rect2i(330, 478, 130, 144) },
			# only_body: sin el brillo morado de la espada que queda a la izquierda.
			"saltar": { "rect": Rect2i(474, 478, 90, 144), "only_body": true },
			"caer": { "rect": Rect2i(575, 478, 96, 144) },
			"ataque_1": { "rect": Rect2i(686, 478, 160, 144) },
			"ataque_2": { "rect": Rect2i(861, 478, 162, 144), "anchor_x": 928 },  # El arco queda sobre la cabeza.
			"dash": { "rect": Rect2i(1020, 478, 156, 144) },
			# clip: sin la espada morada (la forma de hacha en la mano) ni el palito de la izquierda.
			"dano": { "rect": Rect2i(1206, 478, 122, 144), "clip": [Vector2(1236, 505), Vector2(1300, 505), Vector2(1300, 575),
				Vector2(1288, 590), Vector2(1288, 612), Vector2(1215, 612), Vector2(1215, 588), Vector2(1229, 586), Vector2(1225, 565),
				Vector2(1228, 545), Vector2(1236, 530)] },
			# La muerte de la hoja parece dos personajes (hay una segunda cabeza oscura): Kai queda acostado
			# desplomado boca abajo, con la cabeza hacia adelante: su pose de reposo girada 90° (rotate).
			"tendido": { "rect": Rect2i(36, 478, 72, 144), "rotate": true },
		},
		"animations": {
			"quieto": { "poses": ["reposo"], "fps": 1.0, "loop": true },
			# Caminar (lo normal al principio): las dos poses de perfil de la hoja (KaiVisual le suma un rebote
			# de paso para que se vea fluido). Correr se desbloquea más adelante (Player.can_run).
			"caminar": { "poses": ["caminar_1", "caminar_2"], "fps": 5.0, "loop": true },
			"correr": { "poses": ["caminar_1", "correr", "caminar_2", "correr"], "fps": 9.0, "loop": true },
			"saltar": { "poses": ["saltar"], "fps": 1.0, "loop": false },
			"caer": { "poses": ["caer"], "fps": 1.0, "loop": true },
			"dash": { "poses": ["dash"], "fps": 1.0, "loop": false },
			"pared": { "poses": ["caer"], "fps": 1.0, "loop": true },
			"ataque_1": { "poses": ["ataque_1"], "fps": 1.0, "loop": false },
			"ataque_2": { "poses": ["ataque_2"], "fps": 1.0, "loop": false },
			"dano": { "poses": ["dano"], "fps": 1.0, "loop": false },
			"muerte": { "poses": ["tendido"], "fps": 1.0, "loop": false },
		},
	},
	# Prof. Alvarado: adulto, un poco más alto que Kai (112 px frente a 96).
	"profesor": {
		"source": "res://docs/arte/referencias/profesor_hoja_concepto.webp",
		"out": "res://assets/art/characters/profesor/hd/",
		"prefix": "profesor_hd",
		"background": Color("040d1a"),
		"tolerance": 0.05,
		"reference": "reposo_1",
		"height": 112,
		"poses": {
			"reposo_1": { "rect": Rect2i(446, 388, 56, 119) },
			"reposo_2": { "rect": Rect2i(512, 388, 60, 119) },
			"reposo_3": { "rect": Rect2i(588, 388, 58, 119) },
			"caminar_1": { "rect": Rect2i(679, 388, 70, 119) },
			"caminar_2": { "rect": Rect2i(750, 388, 68, 119) },
			"caminar_3": { "rect": Rect2i(815, 388, 60, 119) },
			"caminar_4": { "rect": Rect2i(876, 388, 60, 119) },
			"caminar_5": { "rect": Rect2i(937, 388, 58, 119) },
			"hablar_1": { "rect": Rect2i(1011, 388, 60, 119) },
			"hablar_2": { "rect": Rect2i(1074, 388, 60, 119), "only_body": true },
			"hablar_3": { "rect": Rect2i(1135, 388, 70, 119), "only_body": true },
			"notas_1": { "rect": Rect2i(1255, 386, 66, 121) },
			"notas_2": { "rect": Rect2i(1333, 386, 72, 121) },
			"notas_3": { "rect": Rect2i(1420, 386, 72, 121) },
		},
		"animations": {
			"idle": { "poses": ["reposo_1", "reposo_2", "reposo_3", "reposo_2"], "fps": 3.0, "loop": true },
			"walk": { "poses": ["caminar_1", "caminar_2", "caminar_3", "caminar_4", "caminar_5"], "fps": 8.0, "loop": true },
			"talk": { "poses": ["hablar_1", "hablar_2", "hablar_3", "hablar_2"], "fps": 4.0, "loop": true },
			"notas": { "poses": ["notas_1", "notas_2", "notas_3", "notas_2"], "fps": 3.0, "loop": true },
		},
	},
	# Curación de Kai (hoja de Ariel): en el suelo se arrodilla; en el aire se queda flotando.
	# La pose "reposo" (de pie) solo fija la escala, para que quede del mismo tamaño que el resto.
	# feet_y: fila de los pies en la hoja (los efectos de abajo no empujan a Kai hacia arriba).
	"kai_curacion": {
		"source": "res://docs/arte/referencias/kai_curacion_concepto.webp",
		"out": "res://assets/art/characters/kai/hd/",
		"prefix": "kai_hd_curacion",
		"background": Color("010614"),
		"tolerance": 0.06,
		"remove_glow": true,
		"reference": "reposo",
		"height": 96,
		"poses": {
			"reposo": { "rect": Rect2i(1095, 135, 95, 180) },
			# cover (en las poses de rodillas): tapa la mano apoyada en el suelo con el color del pantalón;
			# Kai solo tiene la mano en el pecho (en la hoja parecía el mismo brazo).
			"suelo_canalizar": { "rect": Rect2i(285, 135, 175, 185), "feet_y": 310, "body": Rect2i(306, 196, 128, 120),
				"cover": [Vector2(333, 296), Vector2(357, 296), Vector2(359, 314), Vector2(333, 314)], "cover_color": Color("16151f") },
			# La pose de la canalización sin efectos (para empezar y terminar de curarse, y en la escena de la
			# Nullblade): la manga doblada hacia el pecho. clip la recorta por su contorno (sin el aura).
			"suelo_quieto": { "rect": Rect2i(285, 135, 175, 185), "feet_y": 310, "body": Rect2i(286, 188, 150, 140), "only_body": true,
				"clip": [Vector2(354, 210), Vector2(366, 204), Vector2(382, 199), Vector2(390, 201), Vector2(401, 217), Vector2(405, 230), Vector2(402, 241), Vector2(397, 246), Vector2(401, 253), Vector2(408, 257), Vector2(410, 270), Vector2(407, 285), Vector2(410, 300), Vector2(410, 311), Vector2(352, 312), Vector2(306, 311), Vector2(307, 299), Vector2(319, 291), Vector2(319, 266), Vector2(325, 261), Vector2(327, 246), Vector2(331, 233), Vector2(345, 222)],
				"cover": [Vector2(333, 296), Vector2(357, 296), Vector2(359, 314), Vector2(333, 314)], "cover_color": Color("16151f") },
			"suelo_restaurar": { "rect": Rect2i(515, 95, 235, 225), "feet_y": 310, "body": Rect2i(561, 196, 142, 120),
				"cover": [Vector2(598, 297), Vector2(621, 297), Vector2(621, 314), Vector2(598, 314)], "cover_color": Color("16151f") },
			# Flotando, Kai tiene los dos brazos abajo: la mano del pecho sobraba (se veían tres brazos).
			# cover la tapa con el color de la camisa.
			"aire_inicio": { "rect": Rect2i(45, 545, 150, 200), "feet_y": 735, "body": Rect2i(48, 548, 145, 198),
				"cover": [Vector2(143, 608), Vector2(157, 608), Vector2(157, 624), Vector2(143, 624)], "cover_color": Color("14131b") },
			"aire_canalizar": { "rect": Rect2i(285, 550, 155, 195), "feet_y": 730, "body": Rect2i(288, 556, 152, 190),
				"cover": [Vector2(371, 616), Vector2(386, 616), Vector2(386, 631), Vector2(371, 631)], "cover_color": Color("14131b") },
			"aire_restaurar": { "rect": Rect2i(525, 520, 225, 240), "feet_y": 735, "body": Rect2i(540, 556, 182, 205),
				"cover": [Vector2(632, 612), Vector2(647, 612), Vector2(647, 629), Vector2(632, 629)], "cover_color": Color("14131b") },
			"aire_completar": { "rect": Rect2i(820, 555, 160, 200), "feet_y": 745, "body": Rect2i(846, 566, 136, 190),
				"cover": [Vector2(913, 635), Vector2(928, 635), Vector2(928, 650), Vector2(913, 650)], "cover_color": Color("14131b") },
			"aire_descenso": { "rect": Rect2i(1060, 555, 135, 195), "feet_y": 745, "body": Rect2i(1062, 558, 134, 192),
				"cover": [Vector2(1143, 618), Vector2(1158, 618), Vector2(1158, 634), Vector2(1143, 634)], "cover_color": Color("14131b") },
		},
		"animations": {
			"curar_suelo_inicio": { "poses": ["suelo_quieto"], "fps": 1.0, "loop": false },
			"curar_suelo": { "poses": ["suelo_canalizar", "suelo_restaurar"], "fps": 5.0, "loop": true },
			"curar_suelo_fin": { "poses": ["suelo_quieto"], "fps": 1.0, "loop": false },
			"curar_aire_inicio": { "poses": ["aire_inicio"], "fps": 1.0, "loop": false },
			"curar_aire": { "poses": ["aire_canalizar", "aire_restaurar"], "fps": 5.0, "loop": true },
			"curar_aire_fin": { "poses": ["aire_completar", "aire_descenso"], "fps": 6.0, "loop": false },
		},
	},
	# NPC de fondo (hoja de Ariel "npcs_fondo_concepto"): no se habla con ellos, solo dan vida al colegio.
	# Cada personaje: quieto (mirando a la derecha; a la izquierda se espeja), caminar y espalda (el
	# conserje, sin espalda).
	# m1-m3 / f1-f3: estudiantes; pm / pf: profesor y profesora; cj: conserje (con el trapeador);
	# x1-x3 y v1-v21: variantes de estudiantes de un solo cuadro. Los estudiantes, como Kai (92 px).
	"npcs_fondo": {
		"source": "res://docs/arte/referencias/npcs_fondo_concepto.webp",
		"out": "res://assets/art/characters/npcs_fondo/",
		"prefix": "npc",
		"background": Color("060915"),
		"tolerance": 0.03,
		"reference": "m1_quieto",
		"height": 92,
		"poses": {
			"m1_quieto": { "rect": Rect2i(37, 62, 48, 114), "only_body": true },
			"m1_caminar_1": { "rect": Rect2i(185, 62, 41, 114), "only_body": true },
			"m1_caminar_2": { "rect": Rect2i(235, 62, 43, 114), "only_body": true },
			"m1_caminar_3": { "rect": Rect2i(279, 62, 41, 114), "only_body": true },
			"m1_espalda": { "rect": Rect2i(491, 62, 41, 114), "only_body": true, "tolerance": 0.025 },
			"m2_quieto": { "rect": Rect2i(582, 62, 46, 114), "only_body": true },
			"m2_caminar_1": { "rect": Rect2i(730, 62, 44, 114), "only_body": true },
			"m2_caminar_2": { "rect": Rect2i(779, 62, 44, 114), "only_body": true },
			"m2_caminar_3": { "rect": Rect2i(824, 62, 40, 114), "only_body": true },
			"m2_espalda": { "rect": Rect2i(1032, 62, 41, 114), "only_body": true },
			"m3_quieto": { "rect": Rect2i(1117, 62, 49, 114), "only_body": true },
			"m3_caminar_1": { "rect": Rect2i(1262, 62, 43, 114), "only_body": true },
			"m3_caminar_2": { "rect": Rect2i(1310, 62, 42, 114), "only_body": true },
			"m3_caminar_3": { "rect": Rect2i(1355, 62, 40, 114), "only_body": true },
			"m3_espalda": { "rect": Rect2i(1523, 62, 43, 114), "only_body": true },
			"f1_quieto": { "rect": Rect2i(37, 282, 50, 110), "only_body": true },
			"f1_caminar_1": { "rect": Rect2i(184, 282, 41, 110), "only_body": true },
			"f1_caminar_2": { "rect": Rect2i(236, 282, 42, 110), "only_body": true },
			"f1_caminar_3": { "rect": Rect2i(277, 282, 44, 110), "only_body": true },
			"f1_espalda": { "rect": Rect2i(490, 282, 42, 110), "only_body": true },
			"f2_quieto": { "rect": Rect2i(580, 282, 54, 110), "only_body": true },
			"f2_caminar_1": { "rect": Rect2i(727, 282, 46, 110), "only_body": true },
			"f2_caminar_2": { "rect": Rect2i(780, 282, 43, 110), "only_body": true },
			"f2_espalda": { "rect": Rect2i(1031, 282, 41, 110), "only_body": true },
			"f3_quieto": { "rect": Rect2i(1116, 282, 51, 110), "only_body": true },
			"f3_caminar_1": { "rect": Rect2i(1256, 282, 43, 110), "only_body": true },
			"f3_caminar_2": { "rect": Rect2i(1300, 282, 41, 110), "only_body": true },
			"f3_caminar_3": { "rect": Rect2i(1339, 282, 41, 110), "only_body": true },
			"f3_espalda": { "rect": Rect2i(1510, 282, 39, 110), "only_body": true, "tolerance": 0.025 },
			"pm_quieto": { "rect": Rect2i(35, 498, 47, 135), "only_body": true },
			"pm_caminar_1": { "rect": Rect2i(196, 498, 39, 135), "only_body": true },
			"pm_caminar_2": { "rect": Rect2i(250, 498, 53, 135), "only_body": true },
			"pm_espalda": { "rect": Rect2i(445, 498, 52, 135), "only_body": true },
			"pf_quieto": { "rect": Rect2i(542, 498, 43, 135), "only_body": true },
			"pf_caminar_2": { "rect": Rect2i(743, 498, 43, 135), "only_body": true },
			"pf_espalda": { "rect": Rect2i(927, 498, 44, 135), "only_body": true },
			# El conserje: clip le quita la sombra del suelo y el montoncito de polvo del trapeador.
			"cj_quieto": { "rect": Rect2i(1012, 498, 100, 135), "only_body": true, "refill": true, "tolerance": 0.05,
				"clip": [Vector2(1012, 498), Vector2(1112, 498), Vector2(1112, 617), Vector2(1071, 617), Vector2(1070, 627), Vector2(1028, 627), Vector2(1028, 621), Vector2(1012, 621)] },
			"cj_caminar_1": { "rect": Rect2i(1193, 498, 99, 135), "only_body": true, "refill": true, "tolerance": 0.05,
				"clip": [Vector2(1189, 498), Vector2(1296, 498), Vector2(1296, 624), Vector2(1268, 624), Vector2(1268, 627), Vector2(1249, 627), Vector2(1249, 623), Vector2(1223, 623), Vector2(1223, 627), Vector2(1205, 627), Vector2(1205, 623), Vector2(1189, 623)] },
			# Su otro cuadro de caminar (en la hoja dice "izquierda", pero también mira a la derecha: es el otro paso).
			"cj_caminar_2": { "rect": Rect2i(1300, 498, 101, 135), "only_body": true, "refill": true, "tolerance": 0.05,
				"clip": [Vector2(1300, 498), Vector2(1401, 498), Vector2(1401, 617), Vector2(1365, 617), Vector2(1365, 627), Vector2(1349, 627), Vector2(1349, 621), Vector2(1324, 621), Vector2(1324, 627), Vector2(1304, 627), Vector2(1304, 623), Vector2(1300, 623)] },
			"x1_quieto": { "rect": Rect2i(1524, 538, 59, 124), "only_body": true },
			# x2 (audífonos): la pierna de adelante era café, como sin pantalón; se pinta como la otra.
			"x2_quieto": { "rect": Rect2i(1605, 538, 54, 124), "only_body": true,
				"recolor": [Vector2(1636, 629), Vector2(1648, 629), Vector2(1648, 652), Vector2(1636, 652)], "recolor_color": Color("141322") },
			"x3_quieto": { "rect": Rect2i(1687, 538, 55, 124), "only_body": true },
			"v1_quieto": { "rect": Rect2i(52, 740, 50, 118), "only_body": true },
			"v2_quieto": { "rect": Rect2i(133, 740, 49, 118), "only_body": true },
			"v3_quieto": { "rect": Rect2i(216, 740, 53, 118), "only_body": true },
			"v4_quieto": { "rect": Rect2i(305, 740, 46, 118), "only_body": true },
			"v5_quieto": { "rect": Rect2i(385, 740, 49, 118), "only_body": true },
			"v6_quieto": { "rect": Rect2i(469, 740, 52, 118), "only_body": true },
			"v7_quieto": { "rect": Rect2i(549, 740, 54, 118), "only_body": true },
			"v8_quieto": { "rect": Rect2i(641, 740, 68, 118), "only_body": true },
			"v9_quieto": { "rect": Rect2i(728, 740, 51, 118), "only_body": true },
			"v10_quieto": { "rect": Rect2i(811, 740, 56, 118), "only_body": true },
			"v11_quieto": { "rect": Rect2i(890, 740, 54, 118), "only_body": true },
			"v12_quieto": { "rect": Rect2i(980, 740, 40, 118), "only_body": true },
			"v13_quieto": { "rect": Rect2i(1053, 740, 51, 118), "only_body": true },
			"v14_quieto": { "rect": Rect2i(1138, 740, 53, 118), "only_body": true },
			"v15_quieto": { "rect": Rect2i(1220, 740, 47, 118), "only_body": true },
			"v16_quieto": { "rect": Rect2i(1299, 740, 57, 118), "only_body": true },
			"v17_quieto": { "rect": Rect2i(1377, 740, 55, 118), "only_body": true },
			"v18_quieto": { "rect": Rect2i(1448, 740, 54, 118), "only_body": true },
			"v19_quieto": { "rect": Rect2i(1525, 740, 46, 118), "only_body": true },
			"v20_quieto": { "rect": Rect2i(1610, 740, 44, 118), "only_body": true },
			"v21_quieto": { "rect": Rect2i(1687, 740, 52, 118), "only_body": true },
		},
		"animations": {
			"m1_quieto": { "poses": ["m1_quieto"], "fps": 1.0, "loop": true },
			"m1_caminar": { "poses": ["m1_caminar_1", "m1_caminar_2", "m1_caminar_3", "m1_caminar_2"], "fps": 6.0, "loop": true },
			"m1_espalda": { "poses": ["m1_espalda"], "fps": 1.0, "loop": true },
			"m2_quieto": { "poses": ["m2_quieto"], "fps": 1.0, "loop": true },
			"m2_caminar": { "poses": ["m2_caminar_1", "m2_caminar_2", "m2_caminar_3", "m2_caminar_2"], "fps": 6.0, "loop": true },
			"m2_espalda": { "poses": ["m2_espalda"], "fps": 1.0, "loop": true },
			"m3_quieto": { "poses": ["m3_quieto"], "fps": 1.0, "loop": true },
			"m3_caminar": { "poses": ["m3_caminar_1", "m3_caminar_2", "m3_caminar_3", "m3_caminar_2"], "fps": 6.0, "loop": true },
			"m3_espalda": { "poses": ["m3_espalda"], "fps": 1.0, "loop": true },
			"f1_quieto": { "poses": ["f1_quieto"], "fps": 1.0, "loop": true },
			"f1_caminar": { "poses": ["f1_caminar_1", "f1_caminar_2", "f1_caminar_3", "f1_caminar_2"], "fps": 6.0, "loop": true },
			"f1_espalda": { "poses": ["f1_espalda"], "fps": 1.0, "loop": true },
			"f2_quieto": { "poses": ["f2_quieto"], "fps": 1.0, "loop": true },
			# f2: su tercer cuadro tiene una pierna con media oscura (las otras no): se camina con dos.
			"f2_caminar": { "poses": ["f2_caminar_1", "f2_caminar_2"], "fps": 4.0, "loop": true },
			"f2_espalda": { "poses": ["f2_espalda"], "fps": 1.0, "loop": true },
			"f3_quieto": { "poses": ["f3_quieto"], "fps": 1.0, "loop": true },
			"f3_caminar": { "poses": ["f3_caminar_1", "f3_caminar_2", "f3_caminar_3", "f3_caminar_2"], "fps": 6.0, "loop": true },
			"f3_espalda": { "poses": ["f3_espalda"], "fps": 1.0, "loop": true },
			"pm_quieto": { "poses": ["pm_quieto"], "fps": 1.0, "loop": true },
			"pm_caminar": { "poses": ["pm_caminar_1", "pm_caminar_2"], "fps": 4.0, "loop": true },
			"pm_espalda": { "poses": ["pm_espalda"], "fps": 1.0, "loop": true },
			"pf_quieto": { "poses": ["pf_quieto"], "fps": 1.0, "loop": true },
			# La profesora: su otro cuadro de caminar tiene otra ropa (cárdigan morado); da el paso y junta los pies.
			"pf_caminar": { "poses": ["pf_caminar_2", "pf_quieto"], "fps": 3.0, "loop": true },
			"pf_espalda": { "poses": ["pf_espalda"], "fps": 1.0, "loop": true },
			"cj_quieto": { "poses": ["cj_quieto"], "fps": 1.0, "loop": true },
			# El conserje camina despacio empujando el trapeador (sus dos pasos).
			"cj_caminar": { "poses": ["cj_caminar_1", "cj_caminar_2"], "fps": 3.0, "loop": true },
			"x1_quieto": { "poses": ["x1_quieto"], "fps": 1.0, "loop": true },
			"x2_quieto": { "poses": ["x2_quieto"], "fps": 1.0, "loop": true },
			"x3_quieto": { "poses": ["x3_quieto"], "fps": 1.0, "loop": true },
			"v1_quieto": { "poses": ["v1_quieto"], "fps": 1.0, "loop": true },
			"v2_quieto": { "poses": ["v2_quieto"], "fps": 1.0, "loop": true },
			"v3_quieto": { "poses": ["v3_quieto"], "fps": 1.0, "loop": true },
			"v4_quieto": { "poses": ["v4_quieto"], "fps": 1.0, "loop": true },
			"v5_quieto": { "poses": ["v5_quieto"], "fps": 1.0, "loop": true },
			"v6_quieto": { "poses": ["v6_quieto"], "fps": 1.0, "loop": true },
			"v7_quieto": { "poses": ["v7_quieto"], "fps": 1.0, "loop": true },
			"v8_quieto": { "poses": ["v8_quieto"], "fps": 1.0, "loop": true },
			"v9_quieto": { "poses": ["v9_quieto"], "fps": 1.0, "loop": true },
			"v10_quieto": { "poses": ["v10_quieto"], "fps": 1.0, "loop": true },
			"v11_quieto": { "poses": ["v11_quieto"], "fps": 1.0, "loop": true },
			"v12_quieto": { "poses": ["v12_quieto"], "fps": 1.0, "loop": true },
			"v13_quieto": { "poses": ["v13_quieto"], "fps": 1.0, "loop": true },
			"v14_quieto": { "poses": ["v14_quieto"], "fps": 1.0, "loop": true },
			"v15_quieto": { "poses": ["v15_quieto"], "fps": 1.0, "loop": true },
			"v16_quieto": { "poses": ["v16_quieto"], "fps": 1.0, "loop": true },
			"v17_quieto": { "poses": ["v17_quieto"], "fps": 1.0, "loop": true },
			"v18_quieto": { "poses": ["v18_quieto"], "fps": 1.0, "loop": true },
			"v19_quieto": { "poses": ["v19_quieto"], "fps": 1.0, "loop": true },
			"v20_quieto": { "poses": ["v20_quieto"], "fps": 1.0, "loop": true },
			"v21_quieto": { "poses": ["v21_quieto"], "fps": 1.0, "loop": true },
		},
	},
	# Pogo con la Nullblade (hoja de Ariel "Animación de pogo"): la fila de arriba, de a una fase.
	# "salto" solo fija la escala (mismo alto que la pose de salto del juego: 88 px). feet_y: fila de
	# los pies (la espada que apunta hacia abajo no empuja a Kai hacia arriba). El impacto (4) tiene
	# al enemigo pegado (su destello lo dibuja el juego). En el descenso (3) y el rebote (5) Kai está
	# encogido y casi no se le ven las piernas: clava la espada con la pose de preparación (2), que sí
	# las tiene, y al rebotar pasa directo al ascenso (6). En la recuperación (7) el pantalón negro se
	# confunde con el fondo y la pose quedaba cortada a la mitad: después del ascenso, la pose de salto.
	"kai_pogo": {
		"source": "res://docs/arte/referencias/pogo_concepto.webp",
		"out": "res://assets/art/characters/kai/hd/",
		"prefix": "kai_hd_pogo",
		# Cuadros más altos que los de siempre: la espada baja bastante por debajo de los pies.
		"frame_height": 176,
		"background": Color("070c16"),
		"tolerance": 0.07,
		"remove_glow": true,
		"reference": "salto",
		"height": 88,
		"poses": {
			"salto": { "rect": Rect2i(50, 135, 135, 150), "feet_y": 282, "body": Rect2i(50, 135, 135, 150), "only_body": true },
			"preparar": { "rect": Rect2i(278, 132, 105, 180), "feet_y": 257, "body": Rect2i(278, 132, 105, 180), "only_body": true },
			"subir": { "rect": Rect2i(1148, 125, 95, 130), "feet_y": 248, "body": Rect2i(1148, 125, 95, 130), "only_body": true },
		},
		"animations": {
			"pogo_clavar": { "poses": ["preparar"], "fps": 1.0, "loop": false },
			"pogo_subir": { "poses": ["subir"], "fps": 1.0, "loop": false },
		},
	},
}

var _config: Dictionary
var _scale := 1.0


func _initialize() -> void:
	var only := OS.get_cmdline_user_args()
	for character: String in CHARACTERS:
		if only.is_empty() or character in only:
			_extract_character(character)
	quit()


func _extract_character(character: String) -> void:
	_config = CHARACTERS[character]
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(_config.source))
	if sheet == null:
		push_error("No se encontró la hoja de concepto: " + _config.source)
		return
	sheet.convert(Image.FORMAT_RGBA8)
	var out: String = _config.out
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))

	# 1. Recorta cada pose y calcula la escala común a partir de la pose de referencia.
	var cutouts := {}
	for pose_name: String in _config.poses:
		cutouts[pose_name] = _cutout(sheet, _config.poses[pose_name])
	_scale = float(_config.height) / cutouts[_config.reference].image.get_height()

	# 2. Reduce cada pose y la ubica con los pies en el centro inferior.
	var frames := {}
	for pose_name: String in cutouts:
		frames[pose_name] = _scaled(cutouts[pose_name])

	# 3. Arma las tiras de cada animación.
	var info := {}
	for anim_name: String in _config.animations:
		var anim: Dictionary = _config.animations[anim_name]
		var half := 0
		for pose_name: String in anim.poses:
			half = maxi(half, frames[pose_name].half_width)
		var width := maxi(MIN_FRAME_WIDTH, ceili(half * 2 / 8.0) * 8)
		var height: int = _config.get("frame_height", FRAME_HEIGHT)
		var strip := Image.create_empty(width * anim.poses.size(), height, false, Image.FORMAT_RGBA8)
		for i in anim.poses.size():
			var frame: Dictionary = frames[anim.poses[i]]
			var image: Image = frame.image
			var at := Vector2i(i * width + width / 2 - frame.anchor_x, FEET_Y + 1 - frame.bottom)
			strip.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), at)
		var file_name := "%s_%s.png" % [_config.prefix, anim_name]
		strip.save_png(out + file_name)
		info[anim_name] = {
			"file": file_name, "frame_size": [width, height], "feet": [width / 2, FEET_Y],
			"frames": anim.poses.size(), "fps": anim.fps, "loop": anim.loop,
		}
		print("%s: %d cuadro(s) de %d×%d" % [file_name, anim.poses.size(), width, height])
	var json := FileAccess.open(out + "%s.json" % _config.prefix, FileAccess.WRITE)
	json.store_string(JSON.stringify({ "scale": WORLD_SCALE, "animations": info }, "\t"))
	json.close()


## Polígono de la pose (en la hoja), pasado a coordenadas de su zona.
func _local_polygon(pose: Dictionary, key: String) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	var origin := Vector2(pose.rect.position)
	for point: Vector2 in pose.get(key, []):
		polygon.append(point - origin)
	return polygon


## Tapa la zona "cover" de la pose con el color "cover_color" (la mano que
## Kai apoya en el suelo, con el color del pantalón que tiene detrás). Debajo de los pies solo
## recolorea lo que ya es de la figura.
func _cover(region: Image, pose: Dictionary) -> void:
	var polygon := _local_polygon(pose, "cover")
	if polygon.is_empty():
		return
	var color: Color = pose.cover_color
	var feet: int = int(pose.get("feet_y", 1 << 20)) - pose.rect.position.y
	for y in region.get_height():
		for x in region.get_width():
			if not Geometry2D.is_point_in_polygon(Vector2(x, y), polygon):
				continue
			if y <= feet or region.get_pixel(x, y).a > 0.0:
				# Un poco de textura, como la tela del pantalón.
				region.set_pixel(x, y, color.lightened(0.07) if (x * 7 + y * 13) % 5 == 0 else color)


## Pinta con "recolor_color" lo café/rosado de la figura dentro del polígono "recolor" (una pierna
## que en la hoja parecía sin pantalón), conservando un poco de su luz. No toca el fondo.
func _recolor(region: Image, pose: Dictionary) -> void:
	var polygon := _local_polygon(pose, "recolor")
	if polygon.is_empty():
		return
	var color: Color = pose.recolor_color
	for y in region.get_height():
		for x in region.get_width():
			var c := region.get_pixel(x, y)
			if c.a == 0.0 or c.r < c.b + 0.05 or c.v < 0.15 or not Geometry2D.is_point_in_polygon(Vector2(x, y), polygon):
				continue
			region.set_pixel(x, y, color.lightened(clampf((c.v - 0.3) * 0.5, 0.0, 0.15)))


## Borra todo lo que queda fuera del contorno "clip" de la pose (aura y efectos pegados a la figura).
func _clip(region: Image, pose: Dictionary) -> void:
	var polygon := _local_polygon(pose, "clip")
	if polygon.is_empty():
		return
	for y in region.get_height():
		for x in region.get_width():
			if not Geometry2D.is_point_in_polygon(Vector2(x, y), polygon):
				region.set_pixel(x, y, Color(0, 0, 0, 0))


## Quita el fondo de la zona y recorta la pose. Devuelve la imagen y el centro del cuerpo.
func _cutout(sheet: Image, pose: Dictionary) -> Dictionary:
	var rect: Rect2i = pose.rect
	var region := sheet.get_region(rect)
	_remove_background(region, pose.get("tolerance", _config.tolerance))
	_remove_glow(region, pose)
	_cover(region, pose)
	_recolor(region, pose)
	_clip(region, pose)
	if pose.get("refill", false):
		# El fondo que quedó encerrado (entre una pierna y el trapeador) ahora toca lo recortado: se borra.
		_remove_background(region, pose.get("tolerance", _config.tolerance))
	if pose.get("only_body", false):
		var body := _largest_component(region)
		var kept := Image.create_empty(region.get_width(), region.get_height(), false, Image.FORMAT_RGBA8)
		for p: Vector2i in body:
			kept.set_pixelv(p, region.get_pixelv(p))
		region = kept
	var box := region.get_used_rect()
	var image := region.get_region(box)
	if pose.get("rotate", false):
		# Desplomado boca abajo: centrado en el cuadro y apoyado sobre el borde de abajo.
		image.rotate_90(CLOCKWISE)
		return { "image": image, "anchor_x": image.get_width() / 2.0, "bottom": -1.0 }
	var anchor: float
	if pose.has("anchor_x"):
		anchor = pose.anchor_x - rect.position.x - box.position.x
	else:
		anchor = _head_center(image)
	# Fila de los pies dentro del recorte (-1 = el borde de abajo).
	var bottom: float = pose.feet_y - rect.position.y - box.position.y if pose.has("feet_y") else -1.0
	return { "image": image, "anchor_x": anchor, "bottom": bottom }


## Centro horizontal de la cabeza: marca dónde está el cuerpo aunque la pose tenga un arma o una
## estela hacia un lado. Usa solo la figura conectada más grande (el cuerpo, sin puntos sueltos
## ni efectos separados) y promedia sus primeras filas (el pelo).
func _head_center(image: Image) -> float:
	var body := _largest_component(image)
	var top := 1 << 30
	for p: Vector2i in body:
		top = mini(top, p.y)
	var total := 0.0
	var count := 0
	for p: Vector2i in body:
		if p.y < top + 22:
			total += p.x
			count += 1
	return total / maxi(count, 1)


func _largest_component(image: Image) -> Array[Vector2i]:
	var w := image.get_width()
	var h := image.get_height()
	var label := PackedInt32Array()
	label.resize(w * h)
	var best: Array[Vector2i] = []
	var current := 0
	for y in h:
		for x in w:
			if label[y * w + x] != 0 or image.get_pixel(x, y).a == 0.0:
				continue
			current += 1
			var component: Array[Vector2i] = []
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			label[y * w + x] = current
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				component.append(p)
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var q := p + Vector2i(dx, dy)
						if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or label[q.y * w + q.x] != 0:
							continue
						if image.get_pixelv(q).a == 0.0:
							continue
						label[q.y * w + q.x] = current
						stack.append(q)
			if component.size() > best.size():
				best = component
	return best


func _scaled(cutout: Dictionary) -> Dictionary:
	var image: Image = (cutout.image as Image).duplicate()
	var size := Vector2i(roundi(image.get_width() * _scale), roundi(image.get_height() * _scale))
	image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0) if c.a >= 0.5 else Color(0, 0, 0, 0))
	# Margen de 1 px para el contorno.
	var padded := Image.create_empty(size.x + 2, size.y + 2, false, Image.FORMAT_RGBA8)
	padded.blit_rect(image, Rect2i(Vector2i.ZERO, size), Vector2i.ONE)
	_clean_edges(padded)
	var anchor := roundi(cutout.anchor_x * _scale) + 1
	return {
		"image": padded, "anchor_x": anchor, "bottom": padded.get_height() if cutout.bottom < 0.0 else roundi(cutout.bottom * _scale) + 1,
		"half_width": maxi(anchor, padded.get_width() - anchor) + 2,
	}


## Limpia el borde: quita restos del fondo pegados a la silueta y píxeles sueltos,
## y agrega un contorno oscuro uniforme de 1 px.
func _clean_edges(img: Image) -> void:
	var background: Color = _config.background
	var neighbors: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	for pass_index in 2:
		var source := img.duplicate() as Image
		for y in img.get_height():
			for x in img.get_width():
				var c := source.get_pixel(x, y)
				if c.a == 0.0:
					continue
				var empty := 0
				for n in neighbors:
					var q := Vector2i(x, y) + n
					if q.x < 0 or q.y < 0 or q.x >= img.get_width() or q.y >= img.get_height() or source.get_pixelv(q).a == 0.0:
						empty += 1
				var near_background := Vector3(c.r - background.r, c.g - background.g, c.b - background.b).length() < 0.12
				if (empty > 0 and near_background) or empty >= 3:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
	var source := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if source.get_pixel(x, y).a > 0.0:
				continue
			for n in neighbors:
				var q := Vector2i(x, y) + n
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and source.get_pixelv(q).a > 0.0:
					img.set_pixel(x, y, OUTLINE)
					break


## Vuelve transparente el fondo conectado con los bordes de la zona (o con lo que ya es transparente).
func _remove_background(img: Image, tolerance: float) -> void:
	var background: Color = _config.background
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
		for x in w:
			if img.get_pixel(x, y).a == 0.0:
				stack.append(Vector2i(x, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or seen[p.y * w + p.x]:
			continue
		seen[p.y * w + p.x] = 1
		var c := img.get_pixelv(p)
		if c.a > 0.0 and Vector3(c.r - background.r, c.g - background.g, c.b - background.b).length() > tolerance:
			continue
		img.set_pixelv(p, Color(0, 0, 0, 0))
		for step in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			stack.append(p + step)


## Resplandor lila oscuro alrededor de los efectos (solo si el personaje tiene "remove_glow"):
## se borra de a capas desde el fondo. Algunas partes de la ropa negra de Kai tienen el mismo tono,
## así que dentro del óvalo del cuerpo de la pose ("body", en coordenadas de la hoja) solo se borra
## el resplandor más intenso.
const GLOW_MAX_PASSES := 80


func _remove_glow(img: Image, pose: Dictionary) -> void:
	if not _config.get("remove_glow", false):
		return
	var w := img.get_width()
	var h := img.get_height()
	var body := Rect2()
	if pose.has("body"):
		var rect: Rect2i = pose.rect
		body = Rect2(pose.body.position - rect.position, pose.body.size)
	for pass_index in GLOW_MAX_PASSES:
		var layer: Array[Vector2i] = []
		for y in h:
			for x in w:
				var c := img.get_pixel(x, y)
				if c.a == 0.0 or not _is_glow(c, _in_body(Vector2(x, y), body)):
					continue
				for n in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
					var q: Vector2i = Vector2i(x, y) + n
					if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or img.get_pixelv(q).a == 0.0:
						layer.append(Vector2i(x, y))
						break
		if layer.is_empty():
			return
		for p in layer:
			img.set_pixelv(p, Color(0, 0, 0, 0))


## Dentro del óvalo inscrito en el rectángulo del cuerpo.
func _in_body(p: Vector2, body: Rect2) -> bool:
	if body.size == Vector2.ZERO:
		return false
	var d := (p - body.get_center()) / (body.size * 0.5)
	return d.length_squared() <= 1.0


## Dentro del cuerpo solo cuenta el resplandor más intenso (el pantalón más lila de Kai llega a
## 0,14 de "azul de más"; el resplandor, a 0,18 o más).
func _is_glow(c: Color, inside_body := false) -> bool:
	if inside_body:
		return c.v > 0.2 and c.v < 0.5 and c.b - maxf(c.r, c.g) > 0.17
	return c.v > 0.08 and c.v < 0.5 and c.b - maxf(c.r, c.g) > 0.08

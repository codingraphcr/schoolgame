class_name WeaponData
extends Resource
## Datos de un arma cuerpo a cuerpo de Kai (la mini espada del prólogo, las etapas de Nullblade).
## PlayerCombat los lee: evolucionar el arma es cambiar de recurso, sin código nuevo.

@export var id: StringName = &""
@export var display_name := ""
@export var damage := 1.0
## Tamaño de la zona de golpe y su centro (mirando a la derecha, respecto a los pies de Kai).
@export var reach := Vector2(30, 22)
@export var offset := Vector2(20, -12)
## Segundos desde que se pulsa hasta que el golpe hace daño, y cuánto dura activo.
@export var windup := 0.05
@export var active_time := 0.1
## Tiempo mínimo entre un ataque y el siguiente.
@export var cooldown := 0.3
@export var knockback := 180.0
## Retroceso de Kai al acertar (px/s), como en Hollow Knight.
@export var recoil := 60.0
## Congelamiento breve al acertar (sensación de impacto).
@export var hit_stop := 0.05
@export var slash_color := Color("3ef2ff")

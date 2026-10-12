class_name EconomyConfig
extends Resource
## Valores de la economía (Ecos) para equilibrar el juego sin tocar código: cuántos Ecos da cada
## fuente (un rango: se sortea un valor dentro) y la penalización al morir.
## El archivo del juego es data/economy/economia.tres (lo carga Economy).

enum Source { ENEMY_COMMON, ENEMY_SPECIAL, BOSS, TERMINAL, CHALLENGE, SIDE_QUEST, HIDDEN_DEPOSIT }

@export_group("Recompensas (mínimo, máximo)")
@export var enemy_common := Vector2i(5, 10)
@export var enemy_special := Vector2i(20, 40)
@export var boss := Vector2i(150, 250)
## Completar un desafío de terminal.
@export var terminal := Vector2i(30, 60)
## Completar un desafío educativo de elección.
@export var challenge := Vector2i(20, 40)
@export var side_quest := Vector2i(75, 150)
## Depósito oculto (cofres, fragmentos de la Visión Digital).
@export var hidden_deposit := Vector2i(15, 40)

@export_group("Penalización al morir")
## Fracción del saldo que se pierde (hacia abajo) y el máximo.
@export_range(0.0, 1.0) var death_penalty := 0.10
@export var death_penalty_max := 100


func range_for(source: Source) -> Vector2i:
	match source:
		Source.ENEMY_COMMON: return enemy_common
		Source.ENEMY_SPECIAL: return enemy_special
		Source.BOSS: return boss
		Source.TERMINAL: return terminal
		Source.CHALLENGE: return challenge
		Source.SIDE_QUEST: return side_quest
		Source.HIDDEN_DEPOSIT: return hidden_deposit
	return Vector2i.ZERO

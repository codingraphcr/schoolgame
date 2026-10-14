class_name DualBossConfig
extends Resource
## Valores del jefe doble Chip y Glitch (Capítulo 1), para ajustarlos con pruebas sin tocar código.
## Uno en data/bosses/chip_glitch.tres. Los tiempos son segundos de juego (con la física).

@export_group("Chip (el estratega)")
@export var chip_health := 14.0
## Altura a la que flota (y de sus pies).
@export var chip_hover_y := 236.0
@export var chip_move_speed := 70.0
@export var chip_shot_cooldown := 2.2
@export var chip_shot_telegraph := 0.55
@export var chip_shot_speed := 150.0
@export var chip_trap_cooldown := 5.0
@export var chip_trap_telegraph := 0.45
## Segundos que la trampa tarda en armarse (parpadea) y que queda activa.
@export var chip_trap_arm := 0.6
@export var chip_trap_duration := 3.0
@export var chip_platform_cooldown := 7.0
## Segundos que una plataforma alterada queda apagada.
@export var chip_platform_off := 2.2
@export var chip_wall_duration := 2.6
## Chip pide el escudo (una vez) al bajar a esta fracción de su vida.
@export_range(0.0, 1.0) var chip_shield_at := 0.5

@export_group("Glitch (el impulsivo)")
@export var glitch_health := 16.0
@export var glitch_run_speed := 110.0
@export var glitch_charge_speed := 300.0
@export var glitch_charge_telegraph := 0.45
@export var glitch_charge_time := 1.1
@export var glitch_leap_telegraph := 0.4
@export var glitch_combo_telegraph := 0.2
@export var glitch_attack_cooldown := 1.6
## Segundos vulnerable después de un ataque (para devolverle el golpe).
@export var glitch_recover := 0.7
## Cada cuánto cambia de dirección de golpe mientras corre (amague).
@export var glitch_feint_every := 1.4

@export_group("Coordinación")
## Segundos entre ataques combinados (si los dos están libres).
@export var combo_cooldown := 7.0

@export_group("Furia fraternal")
## Si Glitch cae: Chip se vuelve menos calculador.
@export var rage_chip_cooldown_scale := 0.5
@export var rage_chip_spread := 3
## Si Chip cae: Glitch acelera y encadena embestidas.
@export var rage_glitch_speed_scale := 1.4
@export var rage_glitch_chain := 3

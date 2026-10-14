class_name DualBossConfig
extends Resource
## Valores del jefe doble Glitch y Chip (Capítulo 1), para ajustarlos con pruebas sin tocar código.
## Uno en data/bosses/chip_glitch.tres. Los tiempos son segundos de juego (con la física).
## Diseño de Ariel (docs/arte/referencias/glitch_chip_concepto.webp): una sola barra de vida para los
## dos y tres fases (Reconocimiento, Sincronización y Protocolo Dual / Furia fraternal).

@export_group("Vida compartida y fases")
@export var shared_health := 44.0
## La Fase 2 (Sincronización) empieza al bajar a esta fracción de la vida.
@export_range(0.0, 1.0) var phase2_at := 0.70
## La Fase 3 (Protocolo Dual) empieza aquí, después de la fase segura del escudo de Chip.
@export_range(0.0, 1.0) var phase3_at := 0.35
## Pausa entre un ataque y el siguiente, por fase.
@export var pause_phase1 := 0.8
@export var pause_phase2 := 0.55
@export var pause_phase3 := 0.4
## En la Fase 3 los avisos duran esto (más rápidos, pero se siguen viendo).
@export var phase3_telegraph_scale := 0.8
@export var phase3_speed_scale := 1.2

@export_group("Glitch (el impulsivo)")
@export var glitch_run_speed := 110.0
## Corte acelerado: dash con varios cortes.
@export var glitch_cut_telegraph := 0.5
@export var glitch_cut_speed := 330.0
@export var glitch_cut_time := 0.5
## Salto en picada: sube sobre Kai y cae en diagonal (marca en el piso).
@export var glitch_dive_telegraph := 0.55
@export var glitch_dive_speed := 360.0
## Embestida en cadena: varios dashes rápidos seguidos.
@export var glitch_chain_dashes := 3
@export var glitch_chain_telegraph := 0.32
## Lanzamiento de fragmentos: cuchillas de energía en abanico.
@export var glitch_fragments := 3
@export var glitch_fragment_speed := 170.0
@export var glitch_fragment_telegraph := 0.45
## Segundos vulnerable después de atacar (para devolverle el golpe).
@export var glitch_recover := 0.5

@export_group("Chip (el estratega)")
## Discos orbitales: los lanza, giran hacia Kai y vuelven.
@export var chip_disc_telegraph := 0.5
@export var chip_disc_speed := 175.0
@export var chip_disc_range := 230.0
## Zona de control: campo que ralentiza a Kai.
@export var chip_zone_telegraph := 0.6
@export var chip_zone_time := 3.2
@export var chip_zone_width := 130.0
@export_range(0.1, 1.0) var chip_zone_slow := 0.45
## Proyecciones: copias temporales que lanzan un disco cada una.
@export var chip_copies := 2
@export var chip_copy_time := 2.6
## Rayo de sincronía: ataque en línea de largo alcance.
@export var chip_beam_telegraph := 0.8
@export var chip_beam_time := 0.35
@export var chip_recover := 0.5

@export_group("Ataque definitivo (Campo Dual)")
@export var field_telegraph := 1.1
@export var field_time := 2.6
## Ancho del hueco seguro en el piso (las plataformas también son seguras).
@export var field_safe_gap := 80.0

@export_group("Aturdimiento y protección")
## Golpes seguidos que aturden a un hermano (dentro de stagger_window segundos).
@export var stagger_hits := 4
@export var stagger_window := 3.0
## Segundos aturdido. Mientras tanto el otro deja su ataque y lo protege.
@export var stun_time := 2.4

@export_group("Como las Mantis Lords")
## Barrido: aparece en una pared y cruza la arena a la altura de Kai (lo sigue durante el aviso).
@export var sweep_telegraph := 0.5
@export var sweep_speed := 400.0
## Caída: aparece arriba de Kai, lo sigue un instante y cae en vertical.
@export var drop_telegraph := 0.6
@export var drop_speed := 520.0
## Altura (sobre el piso) a la que cruza el de arriba en la Tijera: pasa por encima de Kai parado.
@export var sweep_air_height := 46.0

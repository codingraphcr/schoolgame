class_name HitData
extends RefCounted
## Datos de un golpe. Viajan del HitboxComponent que golpea al HurtboxComponent que lo recibe.
## Todo el daño del juego (Nullblade, Aegis, enemigos, peligros) usa esta misma estructura.
##
## "damage" se interpreta según quién recibe: máscaras para el jugador, puntos de vida para enemigos.

var damage := 1.0
## Tipo de amenaza (ver docs/combate.md): credenciales, phishing, malware…
var threat_type: StringName = &""
## Empuje en px/s que recibe el objetivo.
var knockback := Vector2.ZERO
## Nodo que causó el golpe (el atacante, no el Hitbox).
var source: Node
## Peligro del escenario (pinchos, vacío): el jugador vuelve al último suelo seguro.
var is_hazard := false

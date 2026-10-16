class_name RoboticsRun
extends RefCounted
## El resultado de ejecutar el programa de una estación: si cumplió el objetivo, qué pasó en cada paso (para la
## animación) y la explicación. Lo arma RoboticsSim.run(); lo dibuja RoboticsSim.draw().

var ok := false
## Un registro por paso de la simulación (qué datos usa cada simulación para dibujarlo).
var steps: Array[Dictionary] = []
## Qué pasó (correcto o no), en una o dos oraciones.
var feedback := ""
## Si se cortó por seguridad (un ciclo que no iba a terminar).
var stopped_for_safety := false

class_name DayPhase
extends RefCounted
## Momento del día según la historia (no un reloj): el día avanza solo cuando la historia lo dice. Lo
## usan la calle y la casa para la luz y la familia para sus rutinas.
##   DIA     : lo normal (el colegio, cuando ninguna regla dice otra cosa).
##   TARDE   : vuelta a casa después de clases.
##   NOCHE   : después de la cena, hasta dormir.
##   MANANA  : al despertar, hasta llegar a la clase.
## Para ampliar: agregar reglas a RULES (misión, paso actual, momento y, opcional, una marca que además
## tiene que estar); gana la primera que coincida.

enum Phase { DIA, TARDE, NOCHE, MANANA }

const NAMES: Array[String] = ["Día", "Tarde", "Noche", "Mañana"]

## [misión, paso actual, momento, marca (opcional)]
const RULES: Array = [
	[&"camino_a_casa", &"charla_amigos", Phase.TARDE],
	[&"camino_a_casa", &"volver_a_casa", Phase.TARDE],
	[&"camino_a_casa", &"hablar_familia", Phase.TARDE],
	# Después de la noche (la Resonancia Digital), Kai despierta: ya es de mañana.
	[&"camino_a_casa", &"descansar", Phase.MANANA, &"resonancia_digital_1"],
	[&"camino_a_casa", &"descansar", Phase.NOCHE],
	# El día siguiente: desde que Kai despierta hasta que llega a la clase del profesor.
	[&"el_lenguaje_de_las_maquinas", &"clase_programacion", Phase.MANANA],
]


static func current(state: Node) -> Phase:
	for rule: Array in RULES:
		if state.get_current_step(rule[0]) != rule[1]:
			continue
		if rule.size() > 3 and not state.has_flag(rule[3]):
			continue
		return rule[2]
	return Phase.DIA


## Color de la luz del ambiente para cada momento (CanvasModulate de la calle y la casa).
static func ambient(phase: Phase, indoors := false) -> Color:
	match phase:
		Phase.TARDE:
			return Color(1.0, 0.86, 0.74) if not indoors else Color(1.0, 0.93, 0.84)
		Phase.NOCHE:
			return Color(0.42, 0.46, 0.68) if not indoors else Color(0.78, 0.74, 0.86)
		Phase.MANANA:
			return Color(0.95, 0.97, 1.0)
	return Color.WHITE


## Colores del cielo (arriba y abajo) que se ven por las ventanas y en la calle.
static func sky_top(phase: Phase) -> Color:
	match phase:
		Phase.TARDE:
			return Color("f2a35a")
		Phase.NOCHE:
			return Color("101a3a")
		Phase.MANANA:
			return Color("8ac8f0")
	return Color("6ab4f0")


static func sky_bottom(phase: Phase) -> Color:
	match phase:
		Phase.TARDE:
			return Color("f6d28a")
		Phase.NOCHE:
			return Color("26305a")
		Phase.MANANA:
			return Color("f8e8c0")
	return Color("bfe0f8")

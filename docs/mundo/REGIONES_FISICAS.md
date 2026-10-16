# Regiones del mundo físico

> Inspiración cultural y visual: San José, Cartago y Puntarenas. Geografía **ficticia**, culturalmente reconocible
> (aceras con cordón amarillo, casas con rejas, pulperías, sodas, montañas del valle, el tren, el puerto). Sin
> marcas comerciales ni lugares reales innecesarios. Estados: ver `MAPA_MAESTRO.md`.

## Barrio de los Almendros (`barrio_almendros`) — nombre PROPUESTO

- **Función (CONFIRMADO):** descanso, vida familiar, exploración cotidiana, misiones secundarias, recuerdos y
  vecinos. Aquí está **la casa de Kai**, uno de los lugares más importantes del juego
  (`../escenarios/HOGAR_DE_KAI.md`): familia, cuarto, estantería de recuerdos, vitrina de coleccionables, soporte
  de la Nullblade, computadora, descanso y evolución durante los tres años.
- **IMPLEMENTADO:** distrito `barrio` con la **calle** (del portón del colegio a la casa: casas de colores, rejas,
  postes, la pulpería «La Esquina», la parada, Canelo el perro, un vecino y un estudiante), la **casa** y el
  **cuarto de Kai**. La luz sigue el momento del día de la historia (`DayPhase`).
- **IMPLEMENTADO (MVP del mundo):** la **caja de fibra óptica** del poste: primer acceso de Inmersión al Bosque
  de Fibra (Capítulo 3) y la misión secundaria «Sin señal en el barrio».
- **FUTURO:** parque, soda del barrio, más vecinos con historias (misión «El último mensaje»).

## Distrito Central (`distrito_central`) — inspiración San José

- **CONFIRMADO:** región urbana central: colegio técnico, calles, edificios, comercios, biblioteca, talleres,
  laboratorios, zonas escolares y accesos a otras regiones. El colegio es centro narrativo y de navegación.
- **IMPLEMENTADO:** el colegio (distrito `colegio`): entrada, pasillos, Sala 3, laboratorio, escaleras, pasillo del
  segundo piso, biblioteca, cuarto técnico, pasillo viejo y cuarto viejo (Laboratorio 2), el **patio** (punto de
  encuentro, con el tablón de anuncios) y la **soda**, y las salas opcionales del generador. Detalle: `COLEGIO.md`.
- **FUTURO:** las calles del centro, comercios (zona comercial: misiones de emprendimiento en undécimo), la
  biblioteca pública (acceso limitado al Distrito Caché en décimo), la estación del tren y la terminal de buses.

## Altos de Cartago (`altos_cartago`) — inspiración Cartago, FUTURO

- **CONFIRMADO:** paisajes montañosos, arquitectura histórica, vegetación, ruinas e instalaciones antiguas,
  infraestructura tecnológica abandonada. Investigación, archivos antiguos y pistas del pasado de la organización
  del profesor Alvarado, **sin revelar de inmediato su relación con el Proyecto Génesis**.
- **PROPUESTO:** se llega en tren desde el Distrito Central (undécimo, Capítulo 5); una antigua estación de
  comunicaciones conecta con el Archivo Criogénico; unos túneles derrumbados son una segunda entrada a los
  Conductos del Silencio (duodécimo). Descubrimiento «Las señales del pasado».

## Costa del Pacífico (`costa_pacifico`) — inspiración Puntarenas, FUTURO

- **CONFIRMADO:** puerto, muelles, almacenes, infraestructura de comunicaciones, ambiente costero, instalaciones
  industriales. Misiones de redes y comunicaciones, exploración e infraestructura.
- **PROPUESTO:** se llega en bus (undécimo, Capítulo 6, «Conexiones perdidas»); la planta de energía del puerto
  conecta con el Núcleo Térmico.

## Los Conductos del Silencio (`conductos_silencio`) — nombre PROPUESTO, secreta, FUTURO

- **CONFIRMADO:** región secreta **bajo el colegio**, entre el colegio y el Laboratorio Génesis: túneles de
  mantenimiento, conductos, servidores antiguos, puertas de seguridad, instalaciones olvidadas, sistemas eléctricos
  deteriorados. Difícil de descubrir y de alcanzar. **No aparece en el mapa** hasta descubrirla.
- **Progresión (CONFIRMADO):** en décimo, pistas pequeñas; en undécimo se descubre parte de su existencia
  (Capítulo 8, «Bajo la superficie»); el acceso profundo, en una etapa avanzada.
- **PROPUESTO (pistas que ya existen):** el pasillo viejo del colegio y el **Laboratorio 2** (cuarto viejo del
  prólogo, a cargo del profesor hace años) son el lugar natural de la primera pista: una puerta sellada.

## Laboratorio Génesis (`laboratorio_genesis`) — secreta, FUTURO

- **CONFIRMADO:** instalación física profunda, vinculada al profesor Alvarado y su organización. Allí ocurrieron los
  experimentos relacionados con **Aegis**, **Axiom** y **el origen de Kai**. Kai no lo sabe. No se puede entrar al
  laboratorio completo en las primeras etapas; la revelación se construye despacio.
- **CONFIRMADO:** el acceso **no** depende solo de una llave: pide progresión narrativa, habilidades y comprensión
  de sistemas (energía, Aegis Bridge, autorización).
- No confundir con el **Santuario Raíz** (digital).

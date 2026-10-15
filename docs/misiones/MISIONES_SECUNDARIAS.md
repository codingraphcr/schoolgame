# Misiones secundarias, tareas y descubrimientos

> Propuestas originales del equipo para desarrollo progresivo. Inspiración solo en principios generales (historias
> de NPC, conflictos locales, investigación, consecuencias visibles, recompensas significativas): no se copian
> misiones, personajes ni diálogos de otros juegos. No todas son educativas; cuando tiene sentido, se relacionan
> con el MEP. Estados: ver `../mundo/MAPA_MAESTRO.md`.

## Implementada

### Sin señal en el barrio — Secundaria · IMPLEMENTADO (MVP)

- **Ubicación:** Barrio de los Almendros → Bosque de Fibra. **Cuándo:** Capítulo 3 (décimo).
- **Historia:** desde anoche no hay internet en la cuadra. Un vecino se lo cuenta a Kai; la luz de la caja de fibra
  del poste parpadea en rojo. Con la Visión, Kai ve la conexión y entra por la caja: aparece en el Bosque de Fibra,
  apagado. Un Fibroluz lo guía hasta un tramo cortado: los empalmes apuntan para cualquier lado. Kai los gira hasta
  que la señal tiene un camino completo; el bosque vuelve a brillar y el Fibroluz lleva su paquete de luz al barrio.
  De vuelta en la calle, la caja está en verde y el vecino le agradece.
- **Pasos:** revisar la caja → seguir al Fibroluz → reconectar los empalmes → volver al barrio.
- **Concepto:** conectividad y transmisión: la información solo llega si hay un camino continuo del origen al
  destino; un solo enlace roto corta la comunicación (capa física; décimo, redes: LAN/WAN, capa física).
- **Recompensas:** 60 Ecos (una vez), Fibroluz en «Comprensión», el recuerdo «Nota del vecino» en el cuarto de Kai,
  el acceso al bosque desde el rack del colegio, el bosque iluminado para siempre.
- **Archivos:** `data/quests/senal_del_barrio.tres`, `data/dialogues/mundo/`, `world/zones/bosque_fibra/`.

## Candidatas (FUTURO, no son compromisos de implementación)

| Nombre | Tipo | Ubicación | Historia | Conceptos | Recompensas |
|---|---|---|---|---|---|
| El último mensaje | Secundaria | Barrio de los Almendros | Un vecino intenta recuperar un mensaje antiguo de un dispositivo; Kai investiga y ayuda a restaurar una copia válida | Respaldos e integridad de datos | Ecos, una fotografía (recuerdo), diálogo opcional |
| El robot que no obedece | Tarea | Colegio | Un compañero tiene un robot que ejecuta instrucciones en orden incorrecto | Secuencias y control de flujo | Ecos y un recuerdo decorativo |
| El comerciante sin identidad | Secundaria | Distrito Caché | Un comerciante pierde el acceso legítimo a su almacén; Kai investiga los permisos y ayuda a restaurarlo | Autenticación y control de acceso | Productos nuevos y un atajo digital |
| Las señales del pasado | Descubrimiento | Altos de Cartago | Registros de una instalación antigua de comunicaciones | Lore (sin revelar el Proyecto Génesis) | Lore, Fragmento de Datos, pista |
| El bosque que dejó de brillar | Secundaria | Bosque de Fibra | Las conexiones luminosas fallan; Kai ayuda a restaurar las rutas de las criaturas | Conectividad y flujo de datos | Conexión nueva y registro del bestiario |
| Una memoria que no quiere desaparecer | Secundaria | Archivo Criogénico | Una criatura conserva un recuerdo incompleto; Kai ayuda a reconstruirlo | Integridad y recuperación | Recuerdo y fragmento narrativo |
| El pequeño depurador | Secundaria | Canales Corruptos | Una criatura intenta limpiar una zona contaminada; Kai restaura la contención | Detección, contención, recuperación | Sector restaurado y diálogo futuro |
| El guardián sin órdenes | Secundaria | Santuario Raíz | Un guardián protege una puerta con instrucciones antiguas; Kai comprende el conflicto y busca una solución | Autorización y reglas de acceso | Ruta nueva e información narrativa |

**Nota:** «El bosque que dejó de brillar» comparte idea con «Sin señal en el barrio» (la versión breve del MVP). Al
desarrollar el Bosque de Fibra completo (undécimo), conviene que sea su continuación: un problema más grande de
rutas entre nodos, con más criaturas afectadas.

## Reglas para las nuevas

- Pocas, memorables, con consecuencias visibles; no llenar el mapa de marcadores.
- Nunca obligatorias para la historia principal.
- No crear personajes nuevos sin aprobación (los amigos siguen sin nombre por ahora).
- Las que entregan un recuerdo usan `Keepsake` (cuarto de Kai): se registra, se guarda, se ve en la estantería, se
  inspecciona y su texto puede cambiar con los años.

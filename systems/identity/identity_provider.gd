class_name IdentityProvider
extends RefCounted
## De dónde sale la identidad del jugador (ver IdentityManager). Cada proveedor dice si está
## disponible y da un id técnico estable (para las carpetas de partidas) y un nombre para mostrar.
## Proveedores: DevelopmentIdentityProvider (desarrollo, sin Steam) y, más adelante (T9),
## SteamIdentityProvider con la API de GodotSteam verificada.

## "steam" o "dev".
func kind() -> String:
	return ""


## Intenta iniciar el proveedor. true si hay una identidad lista.
func start() -> bool:
	return false


## Id técnico estable (nunca el nombre visible). Para Steam: el Steam ID de 64 bits como texto.
func identity_id() -> String:
	return ""


## Nombre para mostrar (puede cambiar: nunca se usa como clave).
func display_name() -> String:
	return ""

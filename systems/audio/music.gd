class_name Music
extends Node
## Música de fondo. Uso: Music.play(&"computadora")
## Busca assets/audio/music/<pista>.ogg (o .mp3 / .wav) y la reproduce en bucle por el bus "Music"
## (volumen de Música en Opciones), con un fundido entre pistas. Si el archivo no existe, la
## música se apaga (todavía no hay pistas: basta con dejar los archivos con estos nombres).
## Pistas que usa el juego: menu, colegio, computadora, pelea.

const FOLDER := "res://assets/audio/music/"
const FADE := 0.8

## Pista que debería estar sonando (aunque no exista el archivo).
static var current: StringName = &""
static var _instance: Music

var _player: AudioStreamPlayer
var _tween: Tween


static func play(track: StringName) -> void:
	if track == current:
		return
	current = track
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	if not is_instance_valid(_instance):
		_instance = Music.new()
		_instance.name = "Music"
		_instance.process_mode = Node.PROCESS_MODE_ALWAYS
		tree.root.add_child.call_deferred(_instance)
	_instance._switch.call_deferred(track)


static func stream_for(track: StringName) -> AudioStream:
	for ext: String in [".ogg", ".mp3", ".wav"]:
		var path := FOLDER + String(track) + ext
		if ResourceLoader.exists(path):
			return load(path)
	return null


func _init() -> void:
	GameSettings.ensure_loaded()
	_player = AudioStreamPlayer.new()
	_player.bus = GameSettings.MUSIC_BUS
	add_child(_player)


func _switch(track: StringName) -> void:
	var stream := Music.stream_for(track)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if _player.playing:
		_tween.tween_property(_player, "volume_db", -40.0, FADE * 0.5)
	_tween.tween_callback(func() -> void:
		_player.stop()
		if stream == null:
			return
		if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
			stream.loop = true
		_player.stream = stream
		_player.volume_db = -40.0
		_player.play())
	if stream:
		_tween.tween_property(_player, "volume_db", 0.0, FADE)

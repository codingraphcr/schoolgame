class_name Music
extends Node
## Música de fondo. Uso: Music.play(&"computadora")
## Busca assets/audio/music/<pista>.ogg (o .mp3 / .wav) y la reproduce en bucle por el bus "Music"
## (volumen de Música en Opciones), con un fundido entre pistas. Si el archivo no existe, la
## música se apaga (todavía no hay pistas: basta con dejar los archivos con estos nombres).
## Pistas que usa el juego: menu, colegio, computadora, pelea. Mientras no haya archivo, "computadora"
## (la parte del ojo de la entidad) tiene una música provisional generada por código.

const FOLDER := "res://assets/audio/music/"
const FADE := 0.8

## Pista que debería estar sonando (aunque no exista el archivo).
static var current: StringName = &""
static var _instance: Music
static var _generated: Dictionary[StringName, AudioStream] = {}

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
	if track == &"computadora":
		if not _generated.has(track):
			_generated[track] = _entity_ambient()
		return _generated[track]
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


## Música provisional de la computadora (donde vigila el ojo): un ambiente oscuro en bucle.
## Zumbido grave, acordes lentos en La menor (Am · F · Dm · E), un arpegio tenue y chasquidos de
## glitch. 16 s que se repiten sin cortes.
static func _entity_ambient() -> AudioStreamWAV:
	const RATE := 11025
	const LENGTH := 16.0
	const CHORD_TIME := 4.0
	var chords := [[110.0, 130.81, 164.81], [87.31, 110.0, 130.81], [73.42, 87.31, 110.0], [82.41, 103.83, 123.47]]
	var count := int(RATE * LENGTH)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var ticks: Array[float] = []
	for i in 9:
		ticks.append(rng.randf_range(0.0, LENGTH - 0.1))
	var lp := 0.0
	for i in count:
		var t := float(i) / RATE
		# Zumbido: La grave y su quinta, con un temblor lento.
		var sample := 0.22 * sin(TAU * 55.0 * t) + 0.1 * sin(TAU * 82.41 * t) * (0.7 + 0.3 * sin(TAU * t / 8.0))
		# Acordes que se funden de uno al otro.
		var chord_pos := t / CHORD_TIME
		var index := int(chord_pos) % chords.size()
		var k := fmod(chord_pos, 1.0)
		var weight := 1.0 - smoothstep(0.75, 1.0, k)
		for c in 2:
			var notes: Array = chords[(index + c) % chords.size()]
			var w := weight if c == 0 else 1.0 - weight
			if w <= 0.001:
				continue
			for note: float in notes:
				var phase := fmod(note * t, 1.0)
				sample += w * 0.07 * (1.0 - 4.0 * absf(phase - 0.5))
		# Arpegio tenue: una nota del acorde (dos octavas arriba) cada medio segundo.
		var beat := t / 0.5
		var step := int(beat)
		var notes_now: Array = chords[index]
		var note_f: float = notes_now[[0, 2, 1, 2, 0, 1, 2, 1][step % 8]] * 4.0
		var since := fmod(beat, 1.0) * 0.5
		sample += 0.06 * sin(TAU * note_f * since) * exp(-since * 7.0)
		# Chasquidos de glitch.
		for tick in ticks:
			if t >= tick and t < tick + 0.04:
				sample += rng.randf_range(-0.12, 0.12)
		# Suavizado y fundido en las puntas para que el bucle no haga clic.
		lp += 0.35 * (sample - lp)
		var edge := minf(t / 0.02, 1.0) * minf((LENGTH - t) / 0.02, 1.0)
		data.encode_s16(i * 2, clampi(int(lp * edge * 0.75 * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream

class_name Music
extends Node
## Música de fondo. Uso: Music.play(&"computadora")
## Busca assets/audio/music/<pista>.ogg (o .mp3 / .wav) y la reproduce en bucle por el bus "Music"
## (volumen de Música en Opciones), con un fundido entre pistas. Si el archivo no existe, la
## música se apaga (todavía no hay pistas: basta con dejar los archivos con estos nombres).
## Pistas que usa el juego: menu, colegio, computadora, pelea, hermanos. Mientras no haya archivo,
## "computadora" (la parte del ojo de la entidad) y "hermanos" (la pelea contra Glitch y Chip) tienen
## una música provisional generada por código.
## Capa extra: si existe <pista>_capa2, suena junto con la pista, en silencio hasta Music.set_layer(true)
## (en la pelea contra los gemelos, la segunda melodía entra en la Fase 2).

const FOLDER := "res://assets/audio/music/"
const FADE := 0.8

## Pista que debería estar sonando (aunque no exista el archivo).
static var current: StringName = &""
static var _instance: Music
static var _generated: Dictionary[StringName, AudioStream] = {}
## Cuánto está bajada la música (Music.duck), en dB.
static var _duck_db := 0.0
## Si la capa extra (<pista>_capa2) se oye.
static var layer_on := false

var _player: AudioStreamPlayer
var _layer: AudioStreamPlayer
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


## Baja la música un momento (escenas importantes, como la aparición de la Nullblade).
## Music.duck(-16.0) la baja; Music.duck(0.0) la devuelve a su volumen.
static func duck(volume_db: float, seconds := 0.5) -> void:
	_duck_db = volume_db
	if not is_instance_valid(_instance) or not _instance._player.playing:
		return
	_instance.create_tween().tween_property(_instance._player, "volume_db", volume_db, seconds)
	if layer_on and _instance._layer.playing:
		_instance.create_tween().tween_property(_instance._layer, "volume_db", volume_db, seconds)


## Enciende o apaga la capa extra de la pista actual (con un fundido).
static func set_layer(on: bool, seconds := 1.5) -> void:
	layer_on = on
	if not is_instance_valid(_instance) or not _instance._layer.playing:
		return
	_instance.create_tween().tween_property(_instance._layer, "volume_db", _duck_db if on else -60.0, seconds)


static func stream_for(track: StringName) -> AudioStream:
	for ext: String in [".ogg", ".mp3", ".wav"]:
		var path := FOLDER + String(track) + ext
		if ResourceLoader.exists(path):
			return load(path)
	if track in [&"computadora", &"hermanos", &"hermanos_capa2"]:
		if not _generated.has(track):
			match track:
				&"computadora":
					_generated[track] = _entity_ambient()
				&"hermanos":
					_generated[track] = _twins_track(false)
				&"hermanos_capa2":
					_generated[track] = _twins_track(true)
		return _generated[track]
	return null


func _init() -> void:
	GameSettings.ensure_loaded()
	_player = AudioStreamPlayer.new()
	_player.bus = GameSettings.MUSIC_BUS
	add_child(_player)
	_layer = AudioStreamPlayer.new()
	_layer.bus = GameSettings.MUSIC_BUS
	add_child(_layer)


func _switch(track: StringName) -> void:
	var stream := Music.stream_for(track)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if _player.playing:
		_tween.tween_property(_player, "volume_db", -40.0, FADE * 0.5)
	var layer_stream := Music.stream_for(StringName(String(track) + "_capa2"))
	_tween.tween_callback(func() -> void:
		_player.stop()
		_layer.stop()
		if stream == null:
			return
		for s: AudioStream in [stream, layer_stream]:
			if s is AudioStreamOggVorbis or s is AudioStreamMP3:
				s.loop = true
		_player.stream = stream
		_player.volume_db = -40.0
		_player.play()
		# La capa empieza junto con la pista (así quedan sincronizadas) y en silencio si está apagada.
		if layer_stream:
			_layer.stream = layer_stream
			_layer.volume_db = _duck_db if Music.layer_on else -60.0
			_layer.play())
	if stream:
		_tween.tween_property(_player, "volume_db", _duck_db, FADE)


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


## Música provisional de la pelea contra Glitch y Chip: 8 s en bucle (4 compases a 120 bpm, La menor:
## Am · F · C · G). Base (layer false): bajo en corcheas, bombo y platillo. Capa (layer true): la
## segunda melodía que entra en la Fase 2, un arpegio brillante (Glitch) que le responde a una nota
## larga (Chip). Las dos duran lo mismo para sonar juntas.
static func _twins_track(layer: bool) -> AudioStreamWAV:
	const RATE := 11025
	const LENGTH := 8.0
	const BAR := 2.0
	var roots: Array[float] = [55.0, 43.65, 65.41, 49.0]
	var chords := [[220.0, 261.63, 329.63], [174.61, 220.0, 261.63], [261.63, 329.63, 392.0], [196.0, 246.94, 293.66]]
	var count := int(RATE * LENGTH)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2525
	var lp := 0.0
	for i in count:
		var t := float(i) / RATE
		var bar := int(t / BAR) % 4
		var in_bar := fmod(t, BAR)
		var sample := 0.0
		if not layer:
			# Bajo en corcheas (diente de sierra suave) con la raíz del acorde.
			var eighth := fmod(in_bar, 0.25)
			var root: float = roots[bar] * (2.0 if int(in_bar / 0.25) % 4 == 3 else 1.0)
			var saw := fmod(root * t, 1.0) * 2.0 - 1.0
			sample += 0.22 * saw * exp(-eighth * 6.0)
			# Bombo en cada tiempo y platillo en los contratiempos.
			var beat := fmod(t, 0.5)
			sample += 0.5 * sin(TAU * (45.0 + 80.0 * exp(-beat * 30.0)) * beat) * exp(-beat * 14.0)
			var off := fmod(t + 0.25, 0.5)
			if off < 0.04:
				sample += rng.randf_range(-0.08, 0.08) * (1.0 - off / 0.04)
		else:
			# Glitch: arpegio en semicorcheas, brillante (onda cuadrada) y con un tartamudeo cada tanto.
			var step := int(in_bar / 0.125)
			var notes: Array = chords[bar]
			var note: float = notes[[0, 1, 2, 1, 2, 0, 2, 1][step % 8]] * 2.0
			var since := fmod(in_bar, 0.125)
			if step % 16 == 11:
				since = fmod(since, 0.0625)
			var square := 1.0 if fmod(note * t, 1.0) < 0.5 else -1.0
			sample += 0.06 * square * exp(-since * 18.0)
			# Chip: le responde con una nota larga (triángulo) en la segunda mitad de cada compás.
			if in_bar >= 1.0:
				var long := in_bar - 1.0
				var answer: float = notes[2] * 1.0
				var phase := fmod(answer * t, 1.0)
				sample += 0.09 * (1.0 - 4.0 * absf(phase - 0.5)) * minf(long / 0.05, 1.0) * exp(-long * 1.4)
		lp += 0.5 * (sample - lp)
		var edge := minf(t / 0.01, 1.0) * minf((LENGTH - t) / 0.01, 1.0)
		data.encode_s16(i * 2, clampi(int(lp * edge * 0.8 * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream

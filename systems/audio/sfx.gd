class_name Sfx
extends Node
## Efectos de sonido del juego. Uso: Sfx.play(&"jump")  ·  Sfx.play(&"bit_pickup", 1.2)
## Si existe assets/audio/sfx/<nombre>.wav (o .ogg) se usa ese archivo; si no, se genera un sonido
## provisional por código (sintetizador estilo retro, ver RECIPES). Así se pueden ir reemplazando
## los sonidos de a uno, solo dejando el archivo con el mismo nombre en la carpeta.
## Suenan por el bus "SFX" (volumen de Efectos en Opciones) y también con el juego en pausa.
## No hace falta registrarlo: el primer Sfx.play() crea el nodo.

const FOLDER := "res://assets/audio/sfx/"
const RATE := 22050
const VOICES := 16

## Recetas de los sonidos provisionales. Claves:
##   wave: square / saw / sine / triangle / noise  ·  freq → freq_end (Hz, barrido exponencial)
##   dur (s) · attack (s) · volume · vibrato: [profundidad Hz, velocidad Hz] · noise: mezcla de ruido
##   arp: [[tiempo (0-1), multiplicador], ...] cambia el tono en esos momentos (0 = silencio)
##   crush: reduce la resolución (más alto = más "roto") · duty: ancho del pulso (square)
##   lowpass: filtro (Hz) que suaviza lo chillón · type "whisper": susurro (ver _whisper)
const RECIPES := {
	# Kai: sutil, como en Hollow Knight (soplidos de aire y roces, sin pitidos).
	&"jump": { "wave": "noise", "freq": 2200.0, "freq_end": 3600.0, "dur": 0.13, "attack": 0.02, "volume": 0.09, "lowpass": 2600.0 },
	&"double_jump": { "wave": "noise", "freq": 2800.0, "freq_end": 4600.0, "dur": 0.16, "attack": 0.02, "volume": 0.1, "lowpass": 3400.0 },
	&"wall_jump": { "wave": "noise", "freq": 2400.0, "freq_end": 3800.0, "dur": 0.12, "attack": 0.01, "volume": 0.09, "lowpass": 2800.0 },
	&"land": { "wave": "noise", "freq": 600.0, "freq_end": 220.0, "dur": 0.07, "volume": 0.12, "lowpass": 700.0 },
	&"step_school": { "wave": "noise", "freq": 900.0, "freq_end": 500.0, "dur": 0.03, "volume": 0.06, "lowpass": 1100.0 },
	&"step_digital": { "wave": "sine", "freq": 760.0, "freq_end": 620.0, "dur": 0.025, "volume": 0.045 },
	&"dash": { "wave": "noise", "freq": 4200.0, "freq_end": 1300.0, "dur": 0.17, "attack": 0.02, "volume": 0.13, "lowpass": 3200.0 },
	&"hurt": { "wave": "triangle", "freq": 340.0, "freq_end": 110.0, "dur": 0.2, "volume": 0.2, "noise": 0.4, "crush": 7.0, "lowpass": 2400.0 },
	&"crystal_crack": { "wave": "triangle", "freq": 2400.0, "freq_end": 1500.0, "dur": 0.14, "volume": 0.12, "noise": 0.25, "arp": [[0.3, 0.8], [0.6, 1.2]], "lowpass": 5000.0 },
	&"death": { "wave": "saw", "freq": 300.0, "freq_end": 35.0, "dur": 0.95, "volume": 0.22, "vibrato": [20.0, 9.0], "crush": 9.0, "noise": 0.2, "lowpass": 1800.0 },
	&"heal_charge": { "wave": "sine", "freq": 260.0, "freq_end": 720.0, "dur": 1.1, "attack": 0.6, "volume": 0.14, "vibrato": [8.0, 6.0] },
	&"heal_done": { "wave": "triangle", "freq": 880.0, "dur": 0.4, "volume": 0.18, "arp": [[0.0, 1.0], [0.25, 1.5], [0.5, 2.0]], "lowpass": 4000.0 },
	# Nullblade: tajo digital con glitch (entrecortado y "roto").
	&"slash": { "wave": "saw", "freq": 1800.0, "freq_end": 500.0, "dur": 0.15, "volume": 0.16, "noise": 0.55, "crush": 11.0, "lowpass": 6000.0, "arp": [[0.0, 1.0], [0.18, 0.0], [0.26, 1.6], [0.42, 0.0], [0.5, 0.8], [0.68, 0.0], [0.74, 1.3]] },
	&"hit": { "wave": "square", "freq": 180.0, "freq_end": 60.0, "dur": 0.09, "volume": 0.17, "noise": 0.5, "crush": 8.0, "lowpass": 2200.0 },
	&"energy_gain": { "wave": "sine", "freq": 1500.0, "freq_end": 2100.0, "dur": 0.06, "volume": 0.08 },
	&"reveal_gather": { "wave": "saw", "freq": 90.0, "freq_end": 700.0, "dur": 1.6, "attack": 1.2, "volume": 0.16, "vibrato": [6.0, 11.0], "noise": 0.25, "lowpass": 2000.0 },
	&"reveal_flash": { "wave": "triangle", "freq": 1046.0, "freq_end": 700.0, "dur": 0.7, "volume": 0.22, "noise": 0.15, "arp": [[0.0, 1.0], [0.1, 1.25], [0.2, 1.5]], "lowpass": 5000.0 },
	&"fanfare": { "wave": "triangle", "freq": 523.0, "dur": 0.8, "volume": 0.2, "arp": [[0.0, 1.0], [0.18, 1.25], [0.36, 1.5], [0.54, 2.0]] },
	# BITS y cofres
	&"bit_pickup": { "wave": "sine", "freq": 1568.0, "dur": 0.08, "volume": 0.1, "arp": [[0.4, 1.5]] },
	&"chest_open": { "wave": "triangle", "freq": 392.0, "dur": 0.45, "volume": 0.16, "noise": 0.1, "arp": [[0.0, 0.5], [0.15, 1.0], [0.3, 1.5], [0.45, 2.0]], "lowpass": 4000.0 },
	# Enemigos
	&"enemy_hit": { "wave": "square", "freq": 260.0, "freq_end": 120.0, "dur": 0.08, "volume": 0.14, "noise": 0.45, "crush": 6.0, "lowpass": 2500.0 },
	&"brute_force": { "wave": "saw", "freq": 120.0, "freq_end": 80.0, "dur": 0.55, "volume": 0.2, "vibrato": [16.0, 13.0], "crush": 8.0, "lowpass": 1600.0 },
	&"enemy_death": { "wave": "noise", "freq": 2600.0, "freq_end": 180.0, "dur": 0.5, "volume": 0.17, "crush": 6.0, "arp": [[0.2, 0.75], [0.4, 0.5]], "lowpass": 3500.0 },
	&"mail_ding": { "wave": "sine", "freq": 1760.0, "dur": 0.2, "volume": 0.08, "arp": [[0.0, 1.0], [0.4, 0.75]] },
	&"popup_open": { "wave": "sine", "freq": 600.0, "freq_end": 1100.0, "dur": 0.07, "volume": 0.09 },
	&"popup_close": { "wave": "sine", "freq": 1100.0, "freq_end": 500.0, "dur": 0.08, "volume": 0.09 },
	&"error": { "wave": "square", "freq": 220.0, "dur": 0.28, "volume": 0.12, "arp": [[0.0, 1.0], [0.4, 0.0], [0.55, 1.0]], "lowpass": 2000.0 },
	# La entidad
	&"monitor_static": { "wave": "noise", "freq": 9000.0, "dur": 0.9, "volume": 0.12, "crush": 4.0, "lowpass": 6000.0 },
	&"monitor_off": { "wave": "square", "freq": 700.0, "freq_end": 40.0, "dur": 0.28, "volume": 0.16, "noise": 0.3, "lowpass": 2500.0 },
	&"eye_heartbeat": { "wave": "sine", "freq": 58.0, "freq_end": 44.0, "dur": 0.42, "volume": 0.35, "arp": [[0.0, 1.0], [0.25, 0.0], [0.4, 0.9]] },
	&"eye_blink": { "wave": "noise", "freq": 1500.0, "dur": 0.025, "volume": 0.08, "lowpass": 2000.0 },
	&"entity_whisper": { "type": "whisper", "dur": 1.9, "volume": 0.5, "syllables": 7 },
	# Interfaz
	&"ui_move": { "wave": "square", "freq": 1000.0, "dur": 0.03, "volume": 0.16, "duty": 0.25 },
	&"ui_accept": { "wave": "square", "freq": 700.0, "freq_end": 1400.0, "dur": 0.08, "volume": 0.22 },
	&"ui_back": { "wave": "square", "freq": 900.0, "freq_end": 450.0, "dur": 0.08, "volume": 0.2 },
	&"book_open": { "wave": "noise", "freq": 700.0, "freq_end": 250.0, "dur": 0.32, "volume": 0.3, "arp": [[0.0, 1.0], [0.5, 0.6]] },
	&"book_page": { "wave": "noise", "freq": 3500.0, "freq_end": 1500.0, "dur": 0.13, "volume": 0.18 },
	&"book_close": { "wave": "noise", "freq": 500.0, "freq_end": 150.0, "dur": 0.2, "volume": 0.32 },
	&"terminal_key": { "wave": "square", "freq": 1900.0, "dur": 0.016, "volume": 0.1, "duty": 0.2 },
	&"terminal_enter": { "wave": "square", "freq": 880.0, "freq_end": 1100.0, "dur": 0.05, "volume": 0.16 },
	&"terminal_ok": { "wave": "triangle", "freq": 660.0, "dur": 0.45, "volume": 0.3, "arp": [[0.0, 1.0], [0.2, 1.335], [0.4, 2.0]] },
}

## Últimos sonidos reproducidos (para las pruebas automáticas).
static var history: Array[StringName] = []
static var _instance: Sfx

var _players: Array[AudioStreamPlayer] = []
var _cache: Dictionary[StringName, AudioStream] = {}
## Sonidos pedidos antes de que el nodo entrara a la escena (suenan apenas está listo).
var _pending: Array[Array] = []


## Reproduce un sonido. pitch: 1 = normal (más alto = más agudo). Devuelve el reproductor usado.
static func play(id: StringName, pitch := 1.0, volume_db := 0.0) -> AudioStreamPlayer:
	if Engine.is_editor_hint():
		return null
	history.append(id)
	if history.size() > 64:
		history.remove_at(0)
	var sfx := _get_instance()
	return sfx._play(id, pitch, volume_db) if sfx else null


## Detiene un sonido largo (por ejemplo, la carga de la curación si se cancela).
static func stop(player: AudioStreamPlayer) -> void:
	if is_instance_valid(player):
		player.stop()


## El sonido (archivo o provisional) de un nombre.
static func stream_for(id: StringName) -> AudioStream:
	var sfx := _get_instance()
	return sfx._stream(id) if sfx else null


static func _get_instance() -> Sfx:
	if is_instance_valid(_instance):
		return _instance
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	_instance = Sfx.new()
	_instance.name = "Sfx"
	_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child.call_deferred(_instance)
	return _instance


func _init() -> void:
	GameSettings.ensure_loaded()
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = GameSettings.SFX_BUS
		_players.append(player)
		add_child(player)


func _ready() -> void:
	for request in _pending:
		_play(request[0], request[1], request[2])
	_pending.clear()


func _play(id: StringName, pitch: float, volume_db: float) -> AudioStreamPlayer:
	if not is_inside_tree():
		_pending.append([id, pitch, volume_db])
		return null
	var stream := _stream(id)
	if stream == null:
		return null
	var player := _free_player()
	player.stream = stream
	player.pitch_scale = clampf(pitch, 0.1, 4.0)
	player.volume_db = volume_db
	player.play()
	return player


## Un reproductor libre (o el que lleva más tiempo sonando).
func _free_player() -> AudioStreamPlayer:
	var oldest := _players[0]
	for player in _players:
		if not player.playing:
			return player
		if player.get_playback_position() > oldest.get_playback_position():
			oldest = player
	return oldest


func _stream(id: StringName) -> AudioStream:
	if _cache.has(id):
		return _cache[id]
	var stream: AudioStream
	for ext: String in [".wav", ".ogg", ".mp3"]:
		var path := FOLDER + String(id) + ext
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	if stream == null and RECIPES.has(id):
		stream = synth(RECIPES[id])
	if stream == null:
		push_warning("Sfx: no hay sonido para «%s»." % id)
		return null
	_cache[id] = stream
	return stream


## Genera un sonido provisional a partir de una receta (16 bits, mono, 22 050 Hz).
static func synth(recipe: Dictionary) -> AudioStreamWAV:
	if recipe.get("type", "") == "whisper":
		return _whisper(recipe)
	var wave: String = recipe.get("wave", "square")
	var freq: float = recipe.get("freq", 440.0)
	var freq_end: float = recipe.get("freq_end", freq)
	var dur: float = recipe.get("dur", 0.2)
	var attack: float = recipe.get("attack", 0.005)
	var volume: float = recipe.get("volume", 0.3)
	var vibrato: Array = recipe.get("vibrato", [0.0, 0.0])
	var noise_mix: float = recipe.get("noise", 0.0)
	var arp: Array = recipe.get("arp", [])
	var crush: float = recipe.get("crush", 0.0)
	var duty: float = recipe.get("duty", 0.5)
	var lowpass: float = recipe.get("lowpass", 0.0)
	var lp_alpha := 1.0 - exp(-TAU * lowpass / RATE) if lowpass > 0.0 else 1.0
	var lp_value := 0.0
	var count := int(dur * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	var noise_value := 0.0
	var noise_phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(recipe)
	for i in count:
		var t := float(i) / RATE
		var k := float(i) / count
		var f := freq * pow(freq_end / freq, k)
		var mult := 1.0
		for step: Array in arp:
			if k >= float(step[0]):
				mult = float(step[1])
		f *= mult
		f += float(vibrato[0]) * sin(TAU * float(vibrato[1]) * t)
		phase = fmod(phase + f / RATE, 1.0)
		# El ruido cambia de valor al ritmo de la frecuencia (más agudo = más "siseo").
		noise_phase += f / RATE
		if noise_phase >= 1.0:
			noise_phase = fmod(noise_phase, 1.0)
			noise_value = rng.randf_range(-1.0, 1.0)
		var sample := 0.0
		match wave:
			"square":
				sample = 1.0 if phase < duty else -1.0
			"saw":
				sample = phase * 2.0 - 1.0
			"sine":
				sample = sin(TAU * phase)
			"triangle":
				sample = 1.0 - 4.0 * absf(phase - 0.5)
			"noise":
				sample = noise_value
		if noise_mix > 0.0 and wave != "noise":
			sample = lerpf(sample, noise_value, noise_mix)
		if mult == 0.0:
			sample = 0.0
		if crush > 0.0:
			sample = roundf(sample * (16.0 - crush)) / (16.0 - crush)
		if lowpass > 0.0:
			lp_value += lp_alpha * (sample - lp_value)
			sample = lp_value
		# Envolvente: subida (attack) y caída hasta el final.
		var env := minf(t / maxf(attack, 0.001), 1.0) * pow(1.0 - k, 1.6)
		var value := clampi(int(sample * env * volume * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream


## Susurro distorsionado de la entidad: ruido filtrado por dos "formantes" (como las vocales de
## una voz) que cambian en cada sílaba, en ráfagas, con modulación de anillo y bitcrush.
static func _whisper(recipe: Dictionary) -> AudioStreamWAV:
	var dur: float = recipe.get("dur", 1.8)
	var volume: float = recipe.get("volume", 0.4)
	var syllables: int = recipe.get("syllables", 6)
	var count := int(dur * RATE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7331
	# Sílabas: inicio, largo y "vocal" (dos formantes).
	var parts: Array[Dictionary] = []
	var t := 0.08
	for i in syllables:
		var length := rng.randf_range(0.12, 0.26)
		parts.append({ "start": t, "end": t + length, "f1": rng.randf_range(350.0, 800.0), "f2": rng.randf_range(1100.0, 2600.0) })
		t += length + rng.randf_range(0.03, 0.14)
		if t > dur - 0.2:
			break
	var data := PackedByteArray()
	data.resize(count * 2)
	var bands := [[0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0]]  # x1, x2, y1, y2 por formante
	for i in count:
		var time := float(i) / RATE
		var env := 0.0
		var f1 := 500.0
		var f2 := 1500.0
		for p in parts:
			if time >= p.start and time <= p.end:
				var k: float = (time - p.start) / (p.end - p.start)
				env = sin(PI * k)
				f1 = p.f1 * (1.0 + 0.15 * k)
				f2 = p.f2 * (1.0 - 0.1 * k)
		var x := rng.randf_range(-1.0, 1.0)
		var sample := 0.0
		for b in 2:
			var f := f1 if b == 0 else f2
			var w0 := TAU * f / RATE
			var alpha := sin(w0) / (2.0 * 4.0)
			var a0 := 1.0 + alpha
			var state: Array = bands[b]
			var y: float = (alpha * x - alpha * float(state[1]) + 2.0 * cos(w0) * float(state[2]) - (1.0 - alpha) * float(state[3])) / a0
			state[1] = state[0]
			state[0] = x
			state[3] = state[2]
			state[2] = y
			sample += y * (1.0 if b == 0 else 0.7)
		# Distorsión: modulación de anillo lenta, un tono grave que se arrastra y bitcrush.
		sample *= 0.55 + 0.45 * sin(TAU * 38.0 * time)
		sample += 0.25 * sin(TAU * (96.0 - 18.0 * time / dur) * time) * env
		sample = roundf(sample * 7.0) / 7.0
		var fade := minf(time / 0.05, 1.0) * minf((dur - time) / 0.15, 1.0)
		var value := clampi(int(sample * env * fade * volume * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream

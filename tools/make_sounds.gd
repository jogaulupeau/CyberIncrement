extends SceneTree
## Outil hors-jeu : synthétise les effets sonores (chiptune) en fichiers .wav.
## Lancé via : godot --headless --path . --script res://tools/make_sounds.gd
## Aucun asset externe : on génère les échantillons PCM et on écrit le WAV à la main.

const SR := 22050


func _osc(phase: float, wave: String) -> float:
	match wave:
		"square": return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		"saw":    return fmod(phase, 1.0) * 2.0 - 1.0
		"noise":  return randf() * 2.0 - 1.0
		_:        return sin(fmod(phase, 1.0) * TAU)


# Une note : balayage de fréquence f0->f1, durée, forme d'onde, volume, enveloppe.
func _tone(f0: float, f1: float, dur: float, wave: String, vol: float, atk: float = 0.005, rel: float = 0.03) -> PackedFloat32Array:
	var n: int = int(dur * SR)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase: float = 0.0
	for i in n:
		var prog: float = float(i) / float(max(1, n))
		var f: float = lerp(f0, f1, prog)
		phase += f / float(SR)
		var t: float = float(i) / float(SR)
		var env: float = 1.0
		if t < atk:
			env = t / atk
		elif t > dur - rel:
			env = maxf(0.0, (dur - t) / rel)
		out[i] = _osc(phase, wave) * vol * env
	return out


func _cat(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var out: PackedFloat32Array = a.duplicate()
	out.append_array(b)
	return out


func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n: int = max(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var va: float = a[i] if i < a.size() else 0.0
		var vb: float = b[i] if i < b.size() else 0.0
		out[i] = va + vb
	return out


func _save(path: String, samples: PackedFloat32Array) -> void:
	var n: int = samples.size()
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var s: float = clampf(samples[i], -1.0, 1.0)
		data.encode_s16(i * 2, int(s * 32767.0))
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer("RIFF".to_ascii_buffer())
	f.store_32(36 + n * 2)
	f.store_buffer("WAVE".to_ascii_buffer())
	f.store_buffer("fmt ".to_ascii_buffer())
	f.store_32(16)
	f.store_16(1)            # PCM
	f.store_16(1)            # mono
	f.store_32(SR)
	f.store_32(SR * 2)       # byte rate
	f.store_16(2)            # block align
	f.store_16(16)           # bits/sample
	f.store_buffer("data".to_ascii_buffer())
	f.store_32(n * 2)
	f.store_buffer(data)
	f.close()


func _initialize() -> void:
	var dir := "res://assets/audio/"

	_save(dir + "key.wav", _tone(900, 950, 0.035, "square", 0.22, 0.001, 0.02))
	_save(dir + "key_wrong.wav", _tone(180, 110, 0.08, "square", 0.28, 0.001, 0.04))
	_save(dir + "command.wav", _cat(_cat(_tone(660, 660, 0.05, "square", 0.22), _tone(880, 880, 0.05, "square", 0.22)), _tone(1180, 1180, 0.09, "square", 0.24)))
	_save(dir + "rare.wav", _cat(_cat(_cat(_tone(700, 700, 0.05, "square", 0.2), _tone(950, 950, 0.05, "square", 0.2)), _tone(1250, 1250, 0.05, "square", 0.2)), _tone(1650, 1750, 0.13, "square", 0.24)))
	_save(dir + "buy.wav", _cat(_tone(720, 720, 0.04, "square", 0.2), _tone(1080, 1080, 0.07, "square", 0.22)))
	_save(dir + "prestige.wav", _tone(500, 90, 0.5, "saw", 0.28, 0.01, 0.1))
	var beep: PackedFloat32Array = _cat(_tone(760, 760, 0.12, "square", 0.3), _tone(560, 560, 0.12, "square", 0.3))
	_save(dir + "alert.wav", _cat(beep, beep))
	_save(dir + "unlock.wav", _cat(_tone(520, 520, 0.08, "sine", 0.28), _tone(1040, 1100, 0.18, "sine", 0.3, 0.01, 0.08)))
	_save(dir + "boss.wav", _mix(_tone(90, 80, 0.6, "saw", 0.28, 0.02, 0.15), _tone(45, 45, 0.6, "sine", 0.25)))
	_save(dir + "victory.wav", _cat(_cat(_cat(_tone(523, 523, 0.12, "sine", 0.28), _tone(659, 659, 0.12, "sine", 0.28)), _tone(784, 784, 0.12, "sine", 0.28)), _tone(1046, 1050, 0.35, "sine", 0.3, 0.01, 0.15)))

	# Récompense choisie (butin de boss) : arpège ascendant brillant + scintillement aigu
	# par-dessus toute la durée -> "ding" satisfaisant de collecte, distinct de victory.wav.
	var reward_body: PackedFloat32Array = _cat(_cat(_cat(
		_tone(784, 784, 0.06, "sine", 0.26),      # G5
		_tone(1046, 1046, 0.06, "sine", 0.26)),   # C6
		_tone(1318, 1318, 0.06, "sine", 0.26)),   # E6
		_tone(1568, 1580, 0.42, "sine", 0.32, 0.005, 0.24))   # G6 tenue
	var reward_shimmer: PackedFloat32Array = _tone(2093, 3136, 0.60, "sine", 0.09, 0.01, 0.3)  # scintillement C7->G7
	_save(dir + "reward.wav", _mix(reward_body, reward_shimmer))

	# Révélation d'une récompense RARE dans le tirage : "jackpot" scintillant plus riche et
	# plus aigu que reward.wav (montée rapide + balayage haut + note tenue). Joué à l'ouverture
	# de la modale quand au moins une carte rare/légendaire est présente.
	var rare_run: PackedFloat32Array = _cat(_cat(_cat(
		_tone(1046, 1046, 0.07, "sine", 0.24),    # C6
		_tone(1318, 1318, 0.07, "sine", 0.24)),   # E6
		_tone(1568, 1568, 0.07, "sine", 0.24)),   # G6
		_tone(2093, 2100, 0.48, "sine", 0.30, 0.005, 0.3))    # C7 tenue
	var rare_spark: PackedFloat32Array = _mix(
		_tone(3136, 4186, 0.78, "sine", 0.07, 0.02, 0.4),     # balayage aigu G7->C8
		_tone(2637, 2637, 0.78, "sine", 0.05, 0.35, 0.4))     # scintillement E7 soutenu
	_save(dir + "rare_reveal.wav", _mix(rare_run, rare_spark))

	# Événements aléatoires.
	var g := PackedFloat32Array()
	for k in 8:
		var wv: String = "noise" if k % 2 == 0 else "square"
		g = _cat(g, _tone(randf_range(220.0, 1400.0), randf_range(220.0, 1400.0), 0.05, wv, 0.26, 0.001, 0.012))
	_save(dir + "glitch.wav", g)
	_save(dir + "overload.wav", _mix(_tone(320, 70, 0.45, "saw", 0.3, 0.01, 0.08), _tone(120, 60, 0.45, "square", 0.12, 0.01, 0.08)))
	_save(dir + "stable.wav", _cat(_tone(600, 600, 0.08, "sine", 0.24), _tone(900, 950, 0.16, "sine", 0.26, 0.01, 0.08)))

	# Ambiance : drone doux et bouclable (fréquences à cycles entiers sur 4 s).
	var amb := PackedFloat32Array()
	amb.resize(SR * 4)
	for i in amb.size():
		var t: float = float(i) / float(SR)
		var lfo: float = 0.5 + 0.5 * sin(t * TAU * 0.25)
		var v: float = sin(t * TAU * 55.0) * 0.25 + sin(t * TAU * 82.5) * 0.16 + sin(t * TAU * 110.0) * 0.10
		amb[i] = v * (0.55 + 0.45 * lfo) * 0.5
	_save(dir + "ambient.wav", amb)

	print("SOUNDS_DONE")
	quit()

class_name AudioFactory
extends RefCounted
## Demo 阶段的程序合成音效：刮擦白噪音、金币叮、号角、闷响。
## 正式版替换为 CC0 素材 + 芯片编曲。

const RATE := 22050


static func make_scratch_loop() -> AudioStreamWAV:
	var n := int(RATE * 0.5)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261008
	var lp := 0.0
	for i in n:
		var white := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, white, 0.35)
		samples[i] = lp * 0.7
	return to_wav(samples, true)


static func make_ding(freq := 1320.0, dur := 0.28) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 11.0)
		var v := sin(TAU * freq * t) * 0.55 + sin(TAU * freq * 2.01 * t) * 0.22
		samples[i] = v * env
	return to_wav(samples)


static func make_fanfare() -> AudioStreamWAV:
	var notes := [523.25, 659.25, 783.99, 1046.5, 1318.51]
	var seg := 0.12
	var total := seg * float(notes.size()) + 0.5
	var n := int(RATE * total)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / RATE
		var idx := mini(int(t / seg), notes.size() - 1)
		var lt := t - float(idx) * seg
		var f: float = notes[idx]
		var env := exp(-lt * 5.0) * 0.5
		var sq := 1.0 if sin(TAU * f * t) >= 0.0 else -1.0
		var sq2 := 1.0 if sin(TAU * f * 1.5 * t) >= 0.0 else -1.0
		var harm := 0.35 if idx == notes.size() - 1 else 0.2
		samples[i] = (sq * (1.0 - harm) + sq2 * harm) * env
	return to_wav(samples)


static func make_thud() -> AudioStreamWAV:
	var n := int(RATE * 0.16)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 26.0)
		var v := sin(TAU * 110.0 * t) * 0.6 + rng.randf_range(-1.0, 1.0) * 0.15
		samples[i] = v * env
	return to_wav(samples)


static func make_tick() -> AudioStreamWAV:
	var n := int(RATE * 0.03)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 90.0)
		var v := 1.0 if sin(TAU * 1500.0 * t) >= 0.0 else -1.0
		samples[i] = v * env * 0.5
	return to_wav(samples)


static func to_wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var v := clampf(samples[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(v * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav

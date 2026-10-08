class_name MusicFactory
extends RefCounted
## 程序合成的芯片音乐：方波主旋律（五声音阶）+ 三角波贝斯 + 噪声打击。
## 11kHz 单声道，长度约 12~20 秒，无缝循环。

const RATE := 11025

## 五声音阶（C 大调宫调式）：C D E G A
const TITLE_MELODY := [
	[72, 0, 0, 0, 74, 0, 0, 0, 76, 0, 0, 0, 74, 0, 0, 0],
	[72, 0, 0, 0, 69, 0, 0, 0, 67, 0, 0, 0, 0, 0, 0, 0],
	[69, 0, 0, 0, 72, 0, 0, 0, 74, 0, 0, 0, 76, 0, 0, 0],
	[74, 0, 0, 0, 72, 0, 0, 0, 69, 0, 0, 0, 0, 0, 0, 0],
	[76, 0, 0, 0, 79, 0, 0, 0, 81, 0, 0, 0, 79, 0, 0, 0],
	[76, 0, 0, 0, 74, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 0],
	[72, 0, 0, 0, 74, 0, 0, 0, 72, 0, 0, 0, 69, 0, 0, 0],
	[67, 0, 0, 0, 69, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 0],
]
const TITLE_BASS := [36, 36, 33, 33, 29, 29, 31, 31]

const GAME_MELODY := [
	[76, 0, 74, 0, 72, 0, 74, 0, 76, 0, 79, 0, 76, 0, 74, 0],
	[72, 0, 69, 0, 72, 0, 74, 0, 76, 0, 72, 0, 69, 0, 0, 0],
	[69, 0, 72, 0, 74, 0, 76, 0, 79, 0, 76, 0, 74, 0, 72, 0],
	[74, 0, 72, 0, 69, 0, 67, 0, 69, 0, 72, 0, 0, 0, 0, 0],
	[81, 0, 79, 0, 76, 0, 79, 0, 81, 0, 84, 0, 81, 0, 79, 0],
	[76, 0, 74, 0, 72, 0, 74, 0, 76, 0, 72, 0, 74, 0, 76, 0],
	[72, 0, 74, 0, 72, 0, 69, 0, 67, 0, 69, 0, 72, 0, 74, 0],
	[69, 0, 67, 0, 69, 0, 72, 0, 76, 0, 0, 0, 0, 0, 0, 0],
]
const GAME_BASS := [36, 36, 33, 33, 29, 29, 31, 31]


static func title_loop() -> AudioStreamWAV:
	return _render(84.0, TITLE_MELODY, TITLE_BASS, false)


static func game_loop() -> AudioStreamWAV:
	return _render(126.0, GAME_MELODY, GAME_BASS, true)


static func _render(bpm: float, melody: Array, bass_roots: Array, busy: bool) -> AudioStreamWAV:
	var step_dur := 60.0 / bpm / 4.0
	var bars := melody.size()
	var total := int(ceil(step_dur * float(bars * 16) * float(RATE))) + int(0.05 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(total)

	for bar in bars:
		var root: int = bass_roots[bar % bass_roots.size()]
		var row: Array = melody[bar]
		for s in 16:
			var t0 := float(bar * 16 + s) * step_dur
			var note := int(row[s])
			if note > 0:
				_melody_voice(buf, t0, step_dur * (2.5 if busy else 3.5), note)
			if s == 0 or s == 8:
				_bass_voice(buf, t0, step_dur * 3.0, root)
			if busy:
				if s == 0 or s == 8:
					_kick_voice(buf, t0)
				elif s % 4 == 2:
					_hat_voice(buf, t0)

	_fade_edges(buf)
	return AudioFactory.to_wav(buf, true)


static func _melody_voice(buf: PackedFloat32Array, t0: float, dur: float, note: int) -> void:
	var start := int(t0 * RATE)
	var n := int(dur * RATE)
	var freq := _freq(note)
	for i in n:
		var idx := start + i
		if idx >= buf.size():
			break
		var t := float(i) / float(RATE)
		var env := minf(1.0, t / 0.006) * exp(-t * 3.0)
		var phase := fmod(freq * t, 1.0)
		var v := 1.0 if phase < 0.25 else -1.0
		buf[idx] += v * env * 0.16


static func _bass_voice(buf: PackedFloat32Array, t0: float, dur: float, note: int) -> void:
	var start := int(t0 * RATE)
	var n := int(dur * RATE)
	var freq := _freq(note)
	for i in n:
		var idx := start + i
		if idx >= buf.size():
			break
		var t := float(i) / float(RATE)
		var env := minf(1.0, t / 0.008) * exp(-t * 2.2)
		var phase := fmod(freq * t, 1.0)
		var v := 2.0 * absf(2.0 * phase - 1.0) - 1.0
		buf[idx] += v * env * 0.20


static func _kick_voice(buf: PackedFloat32Array, t0: float) -> void:
	var start := int(t0 * RATE)
	var n := int(0.12 * RATE)
	for i in n:
		var idx := start + i
		if idx >= buf.size():
			break
		var t := float(i) / float(RATE)
		var freq := 120.0 - 60.0 * minf(1.0, t / 0.08)
		var env := exp(-t * 26.0)
		buf[idx] += sin(TAU * freq * t) * env * 0.22


static func _hat_voice(buf: PackedFloat32Array, t0: float) -> void:
	var start := int(t0 * RATE)
	var n := int(0.035 * RATE)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(t0 * 100000.0) + 7
	for i in n:
		var idx := start + i
		if idx >= buf.size():
			break
		var t := float(i) / float(RATE)
		var env := exp(-t * 90.0)
		buf[idx] += rng.randf_range(-1.0, 1.0) * env * 0.10


## 首尾各做 6ms 淡入淡出，循环点不爆音
static func _fade_edges(buf: PackedFloat32Array) -> void:
	var fade := int(0.006 * RATE)
	for i in fade:
		var g := float(i) / float(fade)
		buf[i] *= g
		buf[buf.size() - 1 - i] *= g


static func _freq(note: int) -> float:
	return 440.0 * pow(2.0, (float(note) - 69.0) / 12.0)

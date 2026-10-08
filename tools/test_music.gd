extends SceneTree
## 无头自检：背景音乐波形（时长、响度、循环点、两首曲子是否有区别）。

var _done := false


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	var title := MusicFactory.title_loop()
	var game := MusicFactory.game_loop()
	for entry in [["title", title], ["game", game]]:
		_report(str(entry[0]), entry[1])
	print("两首曲子是否不同: ", title.data != game.data)
	print("循环点: title %s / game %s" % [
		str(title.loop_mode == AudioStreamWAV.LOOP_FORWARD),
		str(game.loop_mode == AudioStreamWAV.LOOP_FORWARD),
	])
	return true


func _report(name: String, wav: AudioStreamWAV) -> void:
	var data := wav.data
	var samples := data.size() / 2
	var peak := 0.0
	var energy := 0.0
	var count := 0
	for i in range(0, samples, 23):
		var v := float(data.decode_s16(i * 2)) / 32767.0
		peak = maxf(peak, absf(v))
		energy += v * v
		count += 1
	var rms := sqrt(energy / float(maxi(count, 1)))
	print("%s: %.2f 秒 / %d 采样 / 峰值 %.2f / RMS %.3f / 首尾样本 %.3f, %.3f" % [
		name,
		wav.get_length(),
		samples,
		peak,
		rms,
		float(data.decode_s16(0)) / 32767.0,
		float(data.decode_s16((samples - 1) * 2)) / 32767.0,
	])

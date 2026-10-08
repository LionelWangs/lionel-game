extends SceneTree
## 无头自检：模拟拖动刮卡，覆盖 1x1 / 3x3 / 5x5 / 9x9 票种与四种结果。

var _done := false


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for grid in [1, 3, 5, 9]:
		for force in ["coin", "near_miss", "", "jackpot"]:
			var card := ScratchCard.new()
			root.add_child(card)
			card.setup(Prize.make_board(rng, grid, force))
			var events := 0
			while not card._auto_reveal and events < 4000:
				events += 1
				var p := Vector2(16 + fmod(events * 7.3, 126.0), 16 + fmod(events * 3.1, 206.0))
				card.erase_at(p)
			card.debug_reveal_now()
			print("%dx%-2d force=%-9s 拖动%4d次 进度%.2f 结算=%s 奖金=%d 差一点=%s" % [
				grid, grid,
				force if force != "" else "natural",
				events,
				card.progress,
				card.revealed,
				card.result.payout,
				card.result.near_miss,
			])
			card.free()
	return true

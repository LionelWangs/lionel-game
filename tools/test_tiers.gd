extends SceneTree
## 无头自检：票种生成的不变量（无多余整线）与实测中奖率 / 返奖率。

const ROUNDS := 4000

var _done := false


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261008
	print("票种                价   格   标称中奖   实测中奖   实测返奖   多余整线   异常中奖")
	for grid in range(1, Tickets.MAX_GRID + 1):
		var wins := 0
		var payout_sum := 0
		var bad_lines := 0
		var bad_wins := 0
		var near := 0
		for _i in ROUNDS:
			var board := Prize.make_board(rng, grid)
			var cells: Array = board.cells
			var line: Dictionary = board.line
			# 1x1 只有一格，不适用连线规则
			if grid > 1 and not Prize.find_foreign_line(cells, grid, line).is_empty():
				bad_lines += 1
			if bool(board.near_miss):
				near += 1
			if int(board.win_symbol) >= 0:
				wins += 1
				payout_sum += int(board.payout)
				if grid > 1 and line.is_empty():
					bad_wins += 1
		var price := Tickets.price_of(grid)
		print("%-18s %7d   %6.1f%%   %6.1f%%   %7.1f%%   %8d   %8d   差一点 %.1f%%" % [
			Tickets.DATA[grid]["name"],
			price,
			Tickets.base_win_chance(grid) * 100.0,
			float(wins) / float(ROUNDS) * 100.0,
			float(payout_sum) / float(ROUNDS) / float(price) * 100.0,
			bad_lines,
			bad_wins,
			float(near) / float(ROUNDS) * 100.0,
		])
	var theory := PackedStringArray()
	for g in range(1, Tickets.MAX_GRID + 1):
		theory.append("%dx%d %.0f%%" % [g, g, Tickets.base_return(g) * 100.0])
	print("基础返奖率理论值: ", "  ".join(theory))
	return true

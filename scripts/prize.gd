class_name Prize
extends RefCounted
## 开奖逻辑：NxN 网格，连成一条线（行/列/对角线）即中奖。
## 1x1 特例：刮出图案即中奖，空白表示没中。

const SYMBOL_NAMES := ["Cherry", "Coin", "Star", "Bell", "Seven", "Ingot", "Koi"]
const FORCE_SLOTS := {
	"cherry": 0, "coin": 1, "star": 2, "bell": 3, "seven": 4, "ingot": 5, "koi": 6,
}


## force 取值：""（按概率）、"near_miss"、或 FORCE_SLOTS 中的图案名
static func make_board(rng: RandomNumberGenerator, grid: int, force := "", luck := 0.0) -> Dictionary:
	var slot := -1
	match force:
		"jackpot":
			slot = 6
		"near_miss":
			pass
		_:
			if FORCE_SLOTS.has(force):
				slot = int(FORCE_SLOTS[force])
			else:
				var chance := clampf(Tickets.base_win_chance(grid) + luck, 0.0, 0.9)
				if rng.randf() < chance:
					slot = _roll_slot(rng)

	var built := _make_cells(rng, grid, slot)
	var near_miss := slot < 0 and grid >= 2 and rng.randf() < 0.25
	if near_miss:
		_near_miss(rng, built.cells, grid)

	var payout := 0
	if slot >= 0:
		payout = Tickets.prize_amount(grid, slot)
	return {
		"grid": grid,
		"cells": built.cells,
		"line": built.line,
		"win_symbol": slot,
		"payout": payout,
		"top": slot == 6,
		"near_miss": near_miss,
	}


static func _roll_slot(rng: RandomNumberGenerator) -> int:
	var roll := rng.randf()
	var acc := 0.0
	for i in Tickets.LADDER_WEIGHT.size():
		acc += Tickets.LADDER_WEIGHT[i]
		if roll < acc:
			return i
	return 6


static func _make_cells(rng: RandomNumberGenerator, n: int, slot: int) -> Dictionary:
	var cells := []
	cells.resize(n * n)
	cells.fill(-1)
	if n <= 1:
		cells[0] = slot
		return {"cells": cells, "line": {}}

	var win_line := {}
	if slot >= 0:
		win_line = _random_line(rng, n)

	for _attempt in 60:
		_fill_random(rng, cells)
		if slot >= 0:
			for idx in win_line.cells:
				cells[idx] = slot
		if _find_foreign_line(cells, n, win_line).is_empty():
			return {"cells": cells, "line": win_line}

	# 极端情况下直接破坏多余整线
	for _i in 300:
		var bad := _find_foreign_line(cells, n, win_line)
		if bad.is_empty():
			break
		var idx: int = bad.cells[rng.randi_range(0, bad.cells.size() - 1)]
		var old := int(cells[idx])
		var pick := old
		while pick == old:
			pick = rng.randi_range(0, SYMBOL_NAMES.size() - 1)
		cells[idx] = pick
	return {"cells": cells, "line": win_line}


static func _fill_random(rng: RandomNumberGenerator, cells: Array) -> void:
	for i in cells.size():
		cells[i] = rng.randi_range(0, SYMBOL_NAMES.size() - 1)


## 差一点：某条线只差一格连成
static func _near_miss(rng: RandomNumberGenerator, cells: Array, n: int) -> void:
	for _try in 12:
		var line := _random_line(rng, n)
		var sym := rng.randi_range(0, SYMBOL_NAMES.size() - 1)
		var saved: Array = []
		for idx in line.cells:
			saved.append(cells[idx])
		for i in line.cells.size() - 1:
			cells[line.cells[i]] = sym
		var last_idx: int = line.cells[line.cells.size() - 1]
		if int(cells[last_idx]) == sym:
			cells[last_idx] = (sym + 1) % SYMBOL_NAMES.size()
		if _find_foreign_line(cells, n, {}).is_empty():
			return
		for i in line.cells.size():
			cells[line.cells[i]] = saved[i]


static func _random_line(rng: RandomNumberGenerator, n: int) -> Dictionary:
	var lines := _all_lines(n)
	return lines[rng.randi_range(0, lines.size() - 1)]


static func all_lines(n: int) -> Array:
	return _all_lines(n)


static func _all_lines(n: int) -> Array:
	var lines: Array = []
	for r in n:
		var row: Array = []
		for c in n:
			row.append(r * n + c)
		lines.append({"kind": "row", "index": r, "cells": row})
	for c in n:
		var col: Array = []
		for r in n:
			col.append(r * n + c)
		lines.append({"kind": "col", "index": c, "cells": col})
	if n >= 2:
		var d1: Array = []
		var d2: Array = []
		for i in n:
			d1.append(i * n + i)
			d2.append(i * n + (n - 1 - i))
		lines.append({"kind": "diag", "index": 0, "cells": d1})
		lines.append({"kind": "diag", "index": 1, "cells": d2})
	return lines


static func _find_foreign_line(cells: Array, n: int, keep: Dictionary) -> Dictionary:
	for line in _all_lines(n):
		if not keep.is_empty() and line.kind == keep.kind and int(line.index) == int(keep.index):
			continue
		if _is_uniform(cells, line.cells):
			return line
	return {}


static func is_uniform(cells: Array, idxs: Array) -> bool:
	return _is_uniform(cells, idxs)


static func find_foreign_line(cells: Array, n: int, keep: Dictionary) -> Dictionary:
	return _find_foreign_line(cells, n, keep)


static func _is_uniform(cells: Array, idxs: Array) -> bool:
	var first := int(cells[idxs[0]])
	if first < 0:
		return false
	for idx in idxs:
		if int(cells[idx]) != first:
			return false
	return true

extends SceneTree
## 无头自检：调试面板用到的数值入口、每级技能点与强制结果。

var _done := false


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	var gs: Node = load("res://scripts/game_state.gd").new()
	gs.autosave = false
	gs.new_game()

	var ok := true
	gs.add_xp(gs.xp_needed(gs.level))
	ok = _check(ok, gs.level == 2, "升级一次 -> Lv%d" % gs.level)
	ok = _check(ok, gs.skill_points == gs.SP_PER_LEVEL,
		"每级发放 %d SP，实际 %d" % [gs.SP_PER_LEVEL, gs.skill_points])

	gs.grant_sp(1)
	ok = _check(ok, gs.skill_points == gs.SP_PER_LEVEL + 1, "+1 SP 生效")
	gs.grant_sp(10)
	ok = _check(ok, gs.skill_points == gs.SP_PER_LEVEL + 11, "+10 SP 生效")

	var sp_before: int = gs.skill_points
	gs.grant_levels(1)
	ok = _check(ok, gs.level == 3 and gs.skill_points == sp_before + gs.SP_PER_LEVEL,
		"+1 LEVEL 生效 -> Lv%d SP%d" % [gs.level, gs.skill_points])

	var money_before: int = gs.money
	gs.grant_money(1000000)
	ok = _check(ok, gs.money == money_before + 1000000, "加钱 -> %s" % Ui.money(gs.money))

	var grid_before: int = gs.max_unlocked_grid()
	gs.unlock_next_tier()
	ok = _check(ok, gs.max_unlocked_grid() == mini(Tickets.MAX_GRID, grid_before + 1),
		"解锁票种 %dx%d -> %dx%d" % [grid_before, grid_before,
			gs.max_unlocked_grid(), gs.max_unlocked_grid()])

	gs.force_next_result("jackpot")
	ok = _check(ok, gs.consume_forced_result() == "jackpot", "强制头奖生效")
	ok = _check(ok, gs.consume_forced_result() == "", "强制结果只生效一次")

	gs.clear_save()
	ok = _check(ok, gs.level == 1 and gs.skill_points == 0 and gs.money == 5000,
		"重置存档 -> Lv%d SP%d %s" % [gs.level, gs.skill_points, Ui.money(gs.money)])

	print("PASS 调试功能自检" if ok else "FAIL 调试功能自检")
	quit(0 if ok else 1)
	return true


func _check(ok: bool, condition: bool, label: String) -> bool:
	print("%s %s" % ["OK  " if condition else "BAD ", label])
	return ok and condition

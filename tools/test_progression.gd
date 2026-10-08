extends SceneTree
## 无头自检：等级、技能点、票种解锁与返奖率曲线（不写存档）。

var _done := false


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	var gs: Node = load("res://scripts/game_state.gd").new()
	gs.autosave = false
	gs.new_game()
	print("初始: Lv%d SP%d 票种 %dx%d 票价%d 笔刷%.1f 中奖率%.1f%% 最大网格%d" % [
		gs.level, gs.skill_points, gs.ticket_grid, gs.ticket_grid, gs.ticket_price(),
		SkillTree.brush_radius(gs.skills),
		(Tickets.base_win_chance(gs.ticket_grid) + SkillTree.luck_points(gs.skills)) * 100.0,
		SkillTree.max_grid(gs.skills),
	])

	var scratch := 200
	for _i in scratch:
		gs.add_xp(gs.xp_per_ticket())
	print("%d 张票之后: Lv%d XP%d/%d SP%d" % [
		scratch, gs.level, gs.xp, gs.xp_needed(gs.level), gs.skill_points,
	])

	var bought := 0
	var progress := true
	while progress:
		progress = false
		for id in SkillTree.ORDER:
			if gs.buy_skill(id):
				bought += 1
				progress = true
	print("共购买 %d 次: Lv%d SP%d 解锁最大网格 %dx%d" % [
		bought, gs.level, gs.skill_points, SkillTree.max_grid(gs.skills), SkillTree.max_grid(gs.skills),
	])
	print("技能等级: %s" % [gs.skills])
	print("效果: 笔刷%.1f 自动%.1f%% 幸运+%.1f%% 赔付x%.2f 票价x%.2f 安慰%s 奖池+%d" % [
		SkillTree.brush_radius(gs.skills),
		SkillTree.auto_rate(gs.skills),
		SkillTree.luck_points(gs.skills) * 100.0,
		SkillTree.payout_mult(gs.skills),
		SkillTree.price_mult(gs.skills),
		Ui.money(SkillTree.consolation(gs.skills)),
		SkillTree.feed_bonus(gs.skills),
	])

	var lines := PackedStringArray()
	for grid in range(1, Tickets.MAX_GRID + 1):
		var chance := Tickets.base_win_chance(grid) + SkillTree.luck_points(gs.skills)
		var ret := chance * Tickets.expected_mult(grid) * SkillTree.payout_mult(gs.skills) / SkillTree.price_mult(gs.skills)
		lines.append("%dx%d %.0f%%→%.0f%%" % [grid, grid, Tickets.base_return(grid) * 100.0, ret * 100.0])
	print("返奖率（基础→当前技能）: ", " | ".join(lines))
	gs.free()
	return true

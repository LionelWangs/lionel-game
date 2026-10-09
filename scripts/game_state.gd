extends Node
## 全局游戏状态与存档（autoload: GameState）

const SAVE_PATH := "user://save.json"
const FONT_PATH := "res://assets/fonts/fusion_pixel_12px_zh_cn.ttf"
## 每升一级给多少技能点
const SP_PER_LEVEL := 5

var money := 5000
## 每个票种（网格）各自的奖池
var pools: Dictionary = {}
var tickets := 0
var total_won := 0
var best_win := 0
var level := 1
var xp := 0
var skill_points := 0
var skills: Dictionary = {}
var loss_streak := 0
var symbol_wins: Dictionary = {}
var near_miss_count := 0
var jackpots := 0
var locale := "en"
var music_on := true
## 当前选择的票种网格
var ticket_grid := 1
## 调试模式：--debug 启动时打开，或按 ` / F1 手动打开
var debug := false
## 下一张票强制结果（jackpot / near_miss / 空字符串），由调试面板写入
var debug_force_next := ""

var ui_font: Font
## 无头测试时关闭写盘
var autosave := true


func _ready() -> void:
	ui_font = _load_font()
	Ui.ui_font = ui_font
	_apply_startup_locale()
	_apply_startup_debug()


func _apply_startup_debug() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--debug":
			debug = true


func _apply_startup_locale() -> void:
	var forced := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):
			forced = arg.trim_prefix("--lang=")
	if forced != "":
		locale = forced
	else:
		var saved := _saved_locale()
		if saved != "":
			locale = saved
		else:
			locale = "zh_CN" if OS.get_locale().begins_with("zh") else "en"
	TranslationServer.set_locale(locale)


func set_locale(code: String) -> void:
	locale = code
	TranslationServer.set_locale(code)
	save()


func toggle_locale() -> String:
	set_locale("en" if locale.begins_with("zh") else "zh_CN")
	return locale


func _saved_locale() -> String:
	if not has_save():
		return ""
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return ""
	var text := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	if typeof(data) == TYPE_DICTIONARY and data.has("locale"):
		return String(data["locale"])
	return ""


func new_game() -> void:
	money = 5000
	pools = {}
	tickets = 0
	total_won = 0
	best_win = 0
	level = 1
	xp = 0
	skill_points = 0
	skills = {}
	loss_streak = 0
	symbol_wins = {}
	near_miss_count = 0
	jackpots = 0
	ticket_grid = 1
	music_on = true
	save()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save() -> void:
	if not autosave:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"money": money,
		"pools": pools,
		"tickets": tickets,
		"total_won": total_won,
		"best_win": best_win,
		"level": level,
		"xp": xp,
		"skill_points": skill_points,
		"skills": skills,
		"loss_streak": loss_streak,
		"symbol_wins": symbol_wins,
		"near_miss_count": near_miss_count,
		"jackpots": jackpots,
		"locale": locale,
		"music_on": music_on,
		"ticket_grid": ticket_grid,
	}))
	f.close()


func load_save() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return false
	money = int(data.get("money", money))
	tickets = int(data.get("tickets", 0))
	total_won = int(data.get("total_won", 0))
	best_win = int(data.get("best_win", 0))
	level = int(data.get("level", 1))
	xp = int(data.get("xp", 0))
	skill_points = int(data.get("skill_points", 0))
	loss_streak = int(data.get("loss_streak", 0))
	near_miss_count = int(data.get("near_miss_count", 0))
	jackpots = int(data.get("jackpots", 0))
	locale = String(data.get("locale", locale))
	music_on = bool(data.get("music_on", true))
	TranslationServer.set_locale(locale)

	skills = {}
	var raw_skills: Variant = data.get("skills", {})
	if typeof(raw_skills) == TYPE_DICTIONARY:
		for key in raw_skills:
			skills[String(key)] = int(raw_skills[key])

	symbol_wins = {}
	var raw_symbols: Variant = data.get("symbol_wins", {})
	if typeof(raw_symbols) == TYPE_DICTIONARY:
		for key in raw_symbols:
			symbol_wins[int(key)] = int(raw_symbols[key])

	pools = {}
	var raw_pools: Variant = data.get("pools", {})
	if typeof(raw_pools) == TYPE_DICTIONARY:
		for key in raw_pools:
			pools[int(key)] = int(raw_pools[key])

	ticket_grid = clampi(int(data.get("ticket_grid", 1)), 1, max_unlocked_grid())
	return true


## ---------- 票种 ----------

func max_unlocked_grid() -> int:
	return mini(Tickets.MAX_GRID, 1 + SkillTree.level(skills, "shelf"))


func pool(grid: int) -> int:
	if not pools.has(grid):
		pools[grid] = Tickets.top_prize(grid)
	return int(pools[grid])


func add_pool(grid: int, amount: int) -> void:
	pools[grid] = pool(grid) + amount


func reset_pool(grid: int) -> void:
	pools[grid] = Tickets.top_prize(grid)


func ticket_price() -> int:
	return maxi(1, int(round(float(Tickets.price_of(ticket_grid)) * SkillTree.price_mult(skills))))


## ---------- 等级与技能 ----------

func xp_needed(for_level: int) -> int:
	return 60 + 45 * (for_level - 1)


func xp_progress() -> float:
	return clampf(float(xp) / float(xp_needed(level)), 0.0, 1.0)


## 返回本次提升的等级数
func add_xp(amount: int) -> int:
	xp += amount
	var gained := 0
	while xp >= xp_needed(level):
		xp -= xp_needed(level)
		level += 1
		skill_points += SP_PER_LEVEL
		gained += 1
	save()
	return gained


## 票越大，单张经验越多
func xp_per_ticket() -> int:
	var base := 10.0 + float(Tickets.price_of(ticket_grid)) / 10.0
	return int(round(base * SkillTree.xp_mult(skills)))


func buy_skill(id: String) -> bool:
	var current := SkillTree.level(skills, id)
	if current >= SkillTree.max_level(id):
		return false
	var c := SkillTree.cost(current + 1)
	if skill_points < c:
		return false
	skill_points -= c
	skills[id] = current + 1
	if ticket_grid > max_unlocked_grid():
		ticket_grid = max_unlocked_grid()
	save()
	return true


## ---------- 调试辅助（只在 DebugPanel 与无头测试里使用） ----------

func grant_sp(amount: int) -> void:
	skill_points = maxi(0, skill_points + amount)
	save()


func grant_money(amount: int) -> void:
	money = maxi(0, money + amount)
	save()


## 直接加等级，连带发放该级的技能点
func grant_levels(amount: int) -> void:
	for _i in maxi(0, amount):
		level += 1
		skill_points += SP_PER_LEVEL
	save()


## 白嫖一级票种货架，用来快速验证大票面
func unlock_next_tier() -> void:
	var shelf := mini(SkillTree.max_level("shelf"), SkillTree.level(skills, "shelf") + 1)
	skills["shelf"] = shelf
	if ticket_grid > max_unlocked_grid():
		ticket_grid = max_unlocked_grid()
	save()


## 指定下一张票的结果：jackpot / near_miss / 空字符串表示不改
func force_next_result(kind: String) -> void:
	debug_force_next = kind


func consume_forced_result() -> String:
	var kind := debug_force_next
	debug_force_next = ""
	return kind


func clear_save() -> void:
	new_game()


func register_win(symbol: int) -> void:
	symbol_wins[symbol] = int(symbol_wins.get(symbol, 0)) + 1


func _load_font() -> Font:
	if ResourceLoader.exists(FONT_PATH):
		var res: Resource = load(FONT_PATH)
		if res is FontFile:
			var f: FontFile = res
			f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
			return f
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray(["PingFang SC", "Heiti SC"])
	return sys

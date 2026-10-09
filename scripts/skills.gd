class_name SkillTree
extends RefCounted
## 技能树数据与效果换算。前期难、后期解压全靠这些系数。

const ORDER := ["shelf", "edge", "auto", "luck", "gold", "frugal", "feed", "soft", "mentor"]

const DATA := {
	"shelf": {
		"name": "TICKET SHELF",
		"desc": "Unlock bigger scratch cards.",
		"max": 8,
	},
	"edge": {
		"name": "SHARP EDGE",
		"desc": "Bigger tool and brush, fewer strokes.",
		"max": 6,
	},
	"auto": {
		"name": "AUTO SCRATCH",
		"desc": "The card scratches itself.",
		"max": 10,
	},
	"luck": {
		"name": "LUCKY FINGERS",
		"desc": "Higher win rate on every ticket.",
		"max": 10,
	},
	"gold": {
		"name": "GOLDEN TOUCH",
		"desc": "Bigger payouts on every win.",
		"max": 10,
	},
	"frugal": {
		"name": "FRUGAL GUY",
		"desc": "Cheaper tickets at the counter.",
		"max": 10,
	},
	"feed": {
		"name": "JACKPOT FEED",
		"desc": "The jackpot pool grows faster.",
		"max": 10,
	},
	"soft": {
		"name": "SOFT LANDING",
		"desc": "Near misses pay a consolation.",
		"max": 10,
	},
	"mentor": {
		"name": "MENTOR",
		"desc": "More XP from every ticket.",
		"max": 5,
	},
}


static func level(skills: Dictionary, id: String) -> int:
	return int(skills.get(id, 0))


static func max_level(id: String) -> int:
	return int(DATA[id]["max"])


static func name_of(id: String) -> String:
	return TranslationServer.translate(DATA[id]["name"])


static func desc_of(id: String) -> String:
	return TranslationServer.translate(DATA[id]["desc"])


## 升到 next_level 需要的技能点
static func cost(next_level: int) -> int:
	return 1 + int(floor(float(next_level - 1) / 3.0))


static func cost_next(skills: Dictionary, id: String) -> int:
	return cost(level(skills, id) + 1)


static func brush_radius(skills: Dictionary) -> float:
	return 5.0 + float(level(skills, "edge"))


## 自动刮卡速度（每秒刮开卡面的百分比）
static func auto_rate(skills: Dictionary) -> float:
	return float(level(skills, "auto")) * 1.8


static func auto_instant(skills: Dictionary) -> bool:
	return level(skills, "auto") >= max_level("auto")


## 中奖率加成（绝对值，0.012 = +1.2%）
static func luck_points(skills: Dictionary) -> float:
	return float(level(skills, "luck")) * 0.006


## 已解锁的最大网格 = 1 + 货架等级
static func max_grid(skills: Dictionary) -> int:
	return mini(Tickets.MAX_GRID, 1 + level(skills, "shelf"))


static func payout_mult(skills: Dictionary) -> float:
	return 1.0 + float(level(skills, "gold")) * 0.08


static func price_mult(skills: Dictionary) -> float:
	return maxf(0.5, 1.0 - float(level(skills, "frugal")) * 0.03)


static func feed_bonus(skills: Dictionary) -> int:
	return level(skills, "feed") * 50


static func consolation(skills: Dictionary) -> int:
	return level(skills, "soft") * 20


static func xp_mult(skills: Dictionary) -> float:
	return 1.0 + float(level(skills, "mentor")) * 0.10


## 卡片上的效果描述（含当前数值）
static func effect_text(skills: Dictionary, id: String) -> String:
	match id:
		"shelf":
			var g := max_grid(skills)
			return TranslationServer.translate("Max grid %dx%d") % [g, g]
		"edge":
			return TranslationServer.translate("Brush radius %.1f") % brush_radius(skills)
		"auto":
			if auto_instant(skills):
				return TranslationServer.translate("Fully automatic")
			return TranslationServer.translate("Auto scratch %.1f%%/s") % auto_rate(skills)
		"luck":
			return TranslationServer.translate("Win rate +%.1f%%") % (luck_points(skills) * 100.0)
		"gold":
			return TranslationServer.translate("Payout x%.2f") % payout_mult(skills)
		"frugal":
			return TranslationServer.translate("Price x%.2f") % price_mult(skills)
		"feed":
			return TranslationServer.translate("Pool +%s per ticket") % Ui.group(feed_bonus(skills))
		"soft":
			return TranslationServer.translate("Consolation %s") % Ui.money(consolation(skills))
		"mentor":
			return TranslationServer.translate("XP x%.2f") % xp_mult(skills)
	return ""

extends SceneTree
## 无头自检：翻译覆盖率与格式化占位符。

const KEYS := [
	"SCRATCH TO BILLIONS", "EVERY FORTUNE STARTS WITH ONE SCRATCH", "NEW GAME",
	"CONTINUE", "QUIT", "LANGUAGE: %s", "v0.1 DEMO", "BALANCE %s",
	"MUSIC: %s", "ON", "OFF",
	"JACKPOT POOL %s", "TICKETS %d", "LEVEL %d    SP %d", "LEVEL %d    XP %d/%d",
	"XP %d/%d", "PRICE %s", "TOP PRIZE %s", "ODDS 1/%s", "LUCK +%.1f%%",
	"WIN RATE %.1f%%", "WIN %.1f%%", "TICKET SHELF", "CLOSE", "PICK", "SELECTED",
	"LOCKED", "LOCKED · SHELF Lv %d", "Max grid %dx%d", "Unlock bigger scratch cards.",
	"SHOW A SYMBOL TO WIN", "COMPLETE A LINE OF %d", "LUCKY CARD", "QUAD CARD",
	"TOP",
	"NINE CARD", "SIXTEEN CARD", "TWENTY-FIVE CARD", "THIRTY-SIX CARD",
	"FORTY-NINE CARD", "SIXTY-FOUR CARD", "EIGHTY-ONE CARD",
	"SCRATCHED %d", "TOTAL WON %s", "BEST WIN %s", "PITY %d/7", "KOI TICKET",
	"PRIZE TABLE", "HOLD AND DRAG TO SCRATCH", "SPACE: NEXT | J / K / ` : DEBUG",
	"MENU", "SKILLS", "ALMANAC", "NEXT TICKET %s", "FREE TICKET", "JACKPOT! %s",
	"TOUCH AND DRAG TO SCRATCH", "TAP MENU FOR SKILLS AND ALMANAC",
	"WIN %s", "SO CLOSE!", "SO CLOSE! +%s", "NO PRIZE", "DEBUG: NEXT = JACKPOT",
	"DEBUG: NEXT = NEAR MISS", "LEVEL UP!  Lv %d  +%d SP", "SKIP", "CHAPTER 1",
	"DEBUG", "` : TOGGLE", "` : DEBUG", "+1 SP", "+10 SP", "+1 LEVEL", "ADD %s",
	"SHELF +1", "RESET SAVE", "JACKPOT", "NEAR MISS", "DEBUG: %s",
	"THE CORNER STALL", "SKILL TREE", "BACK", "SKILL POINTS %d", "%d SP", "MAX",
	"SHARP EDGE", "AUTO SCRATCH", "LUCKY FINGERS", "GOLDEN TOUCH", "FRUGAL GUY",
	"JACKPOT FEED", "SOFT LANDING", "MENTOR", "Bigger tool and brush, fewer strokes.",
	"The card scratches itself.", "Higher win rate on every ticket.",
	"TOOL: %s", "FINGER", "LONG NAIL", "SCRAPER", "SHOVEL", "COIN", "SPATULA", "GOLD SHOVEL",
	"SHARP EDGE Lv %d · %s",
	"Bigger payouts on every win.", "Cheaper tickets at the counter.",
	"The jackpot pool grows faster.", "Near misses pay a consolation.",
	"More XP from every ticket.", "Brush radius %.1f", "Fully automatic",
	"Auto scratch %.1f%%/s", "Win rate +%.1f%%", "Payout x%.2f", "Price x%.2f",
	"Pool +%s per ticket", "Consolation %s", "XP x%.2f", "CAREER",
	"SCRATCHED %d    TOTAL WON %s    BEST WIN %s    LEVEL %d\nJACKPOTS %d    NEAR MISSES %d    JACKPOT POOL %s",
	"WON x%d", "NOT WON YET", "Cherry", "Coin", "Star", "Bell", "Seven", "Ingot", "Koi",
	"The corner stall stays open all night. One scratch costs 100.00.",
	"Every ticket already carries its fate. Your only job is to scratch.",
	"Top prize on this card: 1.000.000.00. Odds: 1 in 100.000.",
	"Someday the number will read 10.000.000.000.00. Start scratching.",
]

var _done := false


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	TranslationServer.set_locale("en")
	print("英文环境: ", TranslationServer.translate("BALANCE %s") % "1.000.00")
	TranslationServer.set_locale("zh_CN")
	var untranslated := PackedStringArray()
	for key in KEYS:
		if TranslationServer.translate(key) == key:
			untranslated.append(key)
	print("zh_CN 未翻译键: ", untranslated if untranslated.size() > 0 else "无")
	print("抽查: ", TranslationServer.translate("BALANCE %s") % "1.000.00")
	print("抽查: ", TranslationServer.translate("SO CLOSE! +%s") % "20.00")
	print("抽查: ", TranslationServer.translate("JACKPOT! %s") % "1.000.005.00")
	print("抽查: ", TranslationServer.translate("LUCK +%.1f%%") % 12.0)
	print("抽查: ", TranslationServer.translate("LEVEL %d    XP %d/%d") % [7, 120, 645])
	print("抽查: ", TranslationServer.translate("AUTO SCRATCH"))
	print("抽查: ", TranslationServer.translate("Auto scratch %.1f%%/s") % 7.2)
	print("抽查: ", TranslationServer.translate("SCRATCHED %d    TOTAL WON %s    BEST WIN %s    LEVEL %d\nJACKPOTS %d    NEAR MISSES %d    JACKPOT POOL %s") % [42, "3.250.00", "2.000.00", 9, 1, 9, "1.000.000.00"])
	return true

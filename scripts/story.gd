class_name Story
extends RefCounted
## 过场文案与章节卡片。所有面向玩家的文字保持英文。

static func prologue() -> Array:
	return [
		{
			"kind": "chapter",
			"chapter": "CHAPTER 1",
			"title": "THE CORNER STALL",
			"art": "dark",
		},
		{
			"kind": "line",
			"art": "stall",
			"text": "The corner stall stays open all night. One scratch costs 100.00.",
		},
		{
			"kind": "line",
			"art": "card",
			"text": "Every ticket already carries its fate. Your only job is to scratch.",
		},
		{
			"kind": "line",
			"art": "card",
			"text": "Top prize on this card: 1.000.000.00. Odds: 1 in 100.000.",
		},
		{
			"kind": "line",
			"art": "dark",
			"text": "Someday the number will read 10.000.000.000.00. Start scratching.",
		},
	]

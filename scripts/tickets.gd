class_name Tickets
extends RefCounted
## 票种分档：网格越大、票价越高、中奖率与回报越高。
## 解锁由技能 TICKET SHELF 控制（1 级解锁 2x2，依此类推）。

const MAX_GRID := 9
## 奖级倍率（相对票价），最后一档是头奖
const LADDER_MULT := [1.0, 3.0, 8.0, 25.0, 80.0, 250.0]
const LADDER_WEIGHT := [0.55, 0.25, 0.12, 0.05, 0.02, 0.009]
const TOP_WEIGHT := 0.001

const DATA := {
	1: {"name": "LUCKY CARD", "price": 10, "win": 0.07, "top": 300.0},
	2: {"name": "QUAD CARD", "price": 25, "win": 0.08, "top": 400.0},
	3: {"name": "NINE CARD", "price": 60, "win": 0.08, "top": 500.0},
	4: {"name": "SIXTEEN CARD", "price": 150, "win": 0.08, "top": 600.0},
	5: {"name": "TWENTY-FIVE CARD", "price": 400, "win": 0.08, "top": 700.0},
	6: {"name": "THIRTY-SIX CARD", "price": 1000, "win": 0.08, "top": 1000.0},
	7: {"name": "FORTY-NINE CARD", "price": 2500, "win": 0.09, "top": 400.0},
	8: {"name": "SIXTY-FOUR CARD", "price": 6000, "win": 0.10, "top": 167.0},
	9: {"name": "EIGHTY-ONE CARD", "price": 15000, "win": 0.11, "top": 67.0},
}


static func name_of(grid: int) -> String:
	return TranslationServer.translate(DATA[grid]["name"])


static func price_of(grid: int) -> int:
	return int(DATA[grid]["price"])


static func base_win_chance(grid: int) -> float:
	return float(DATA[grid]["win"])


static func top_mult(grid: int) -> float:
	return float(DATA[grid]["top"])


static func top_prize(grid: int) -> int:
	return int(round(float(DATA[grid]["price"]) * float(DATA[grid]["top"])))


## 奖级金额：slot 0..5 为普通档，6 为头奖
static func prize_amount(grid: int, slot: int) -> int:
	if slot >= LADDER_MULT.size():
		return top_prize(grid)
	return int(round(float(DATA[grid]["price"]) * LADDER_MULT[slot]))


## 规则说明文案
static func rule_text(grid: int) -> String:
	if grid <= 1:
		return TranslationServer.translate("SHOW A SYMBOL TO WIN")
	return TranslationServer.translate("COMPLETE A LINE OF %d") % grid


## 单次中奖的期望倍率（相对票价）
static func expected_mult(grid: int) -> float:
	var ev := 0.0
	for i in LADDER_WEIGHT.size():
		ev += LADDER_WEIGHT[i] * LADDER_MULT[i]
	ev += TOP_WEIGHT * top_mult(grid)
	return ev


## 基础返奖率（不含技能）
static func base_return(grid: int) -> float:
	return base_win_chance(grid) * expected_mult(grid)

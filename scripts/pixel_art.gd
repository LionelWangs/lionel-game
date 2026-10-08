class_name PixelArt
extends RefCounted
## 像素素材生成：调色板与票面符号。
## 图案用 16x16 字符网格描述，"." 为透明。

const C_INK := Color8(20, 22, 28)
const C_RED := Color8(200, 16, 46)
const C_RED_DEEP := Color8(125, 28, 34)
const C_RED_BRIGHT := Color8(232, 92, 74)
const C_GOLD := Color8(232, 163, 61)
const C_GOLD_LIGHT := Color8(255, 216, 102)
const C_GOLD_HI := Color8(255, 243, 196)
const C_GOLD_DARK := Color8(166, 106, 31)
const C_PAPER := Color8(250, 246, 236)
const C_PAPER_DARK := Color8(228, 217, 192)
const C_SILVER_1 := Color8(244, 246, 248)
const C_SILVER_2 := Color8(201, 205, 211)
const C_SILVER_3 := Color8(150, 156, 165)
const C_SILVER_4 := Color8(98, 103, 111)
const C_JADE := Color8(47, 169, 140)

const PALETTE := {
	"k": C_INK,
	"r": C_RED,
	"d": C_RED_DEEP,
	"R": C_RED_BRIGHT,
	"g": C_GOLD,
	"G": C_GOLD_LIGHT,
	"h": C_GOLD_HI,
	"b": C_GOLD_DARK,
	"w": C_PAPER,
	"s": C_SILVER_2,
	"j": C_JADE,
}

const CHERRY := [
	"................",
	"................",
	"....k...........",
	".....k..........",
	"......k.........",
	".......k........",
	"......k.k.......",
	".....k...k......",
	"..kkk.....kkk...",
	".kRRRk...kRRRk..",
	"kRhRRRk.kRhRRRk.",
	"kRRRRRk.kRRRRRk.",
	"kRRRRRk.kRRRRRk.",
	".kRRRk...kRRRk..",
	"..kkk.....kkk...",
	"................",
]

const COIN := [
	"................",
	".....kkkkkk.....",
	"...kkGGGGGGkk...",
	"..kGGGGGGGGGGk..",
	".kGGhhhhhhhhGGk.",
	".kGhkkkkkkkkhGk.",
	"kGGhkkbbbbkkhGGk",
	"kGGhkkbbbbkkhGGk",
	"kGGhkkbbbbkkhGGk",
	"kGGhkkbbbbkkhGGk",
	".kGhkkkkkkkkhGk.",
	".kGGhhhhhhhhGGk.",
	"..kGGGGGGGGGGk..",
	"...kkGGGGGGkk...",
	".....kkkkkk.....",
	"................",
]

const STAR := [
	"................",
	".......kk.......",
	"......kGGk......",
	"......kGGk......",
	".....kGGGGk.....",
	".kkkkkGGGGkkkkk.",
	".kGGGGGGGGGGGGk.",
	"..kGGGGGGGGGGk..",
	"...kGGGGGGGGk...",
	"...kGGGGGGGGk...",
	"..kGGGGGGGGGGk..",
	".kGGGGk..kGGGGk.",
	".kGGGk....kGGGk.",
	"kGGGk......kGGGk",
	"kGGk........kGGk",
	"kk............kk",
]

const BELL := [
	"................",
	".......kk.......",
	"......kbbk......",
	".......kk.......",
	".....kkkkkk.....",
	"....kGhhGGGk....",
	"...kGGGGGGGGk...",
	"...kGGGGGGGGk...",
	"..kGGGGGGGGGGk..",
	"..kGGGGGGGGGGk..",
	".kGGGGGGGGGGGGk.",
	".kkkkkkkkkkkkkk.",
	"......kbbk......",
	"......kbbk......",
	".......kk.......",
	"................",
]

const SEVEN := [
	"................",
	"..kkkkkkkkkkkk..",
	"..kRRRRRRRRRRk..",
	"..kkkkkkkRRRk...",
	".......kRRk.....",
	"......kRRk......",
	"......kRRk......",
	".....kRRk.......",
	".....kRRk.......",
	"....kRRk........",
	"....kRRk........",
	"...kRRk.........",
	"...kRRk.........",
	"..kRRk..........",
	"..kRRk..........",
	"..kkkk..........",
]

const INGOT := [
	"................",
	"................",
	"................",
	"................",
	"....kkkkkkkk....",
	"...kGhhhhhhGk...",
	"..kkkkkkkkkkkk..",
	".kggggggggggggk.",
	"kggggggggggggggk",
	"kggggggggggggggk",
	"kggggggggggggggk",
	"kggggggggggggggk",
	".kggggggggggggk.",
	"..kkkkkkkkkkkk..",
	"................",
	"................",
]

const KOI := [
	"................",
	"................",
	".......kkkk.....",
	"......kwwwwk....",
	".....kwwrrwwk...",
	"....kwwrrrwwk...",
	"...kwwrrrrkwkk..",
	"kkkwwrrrwwwwkk..",
	"krrkwwwwwwkk....",
	"kkkwwrrwwkk.....",
	"...kwwrwwk......",
	"....kwwwwk......",
	".....kkkk.......",
	"................",
	"................",
	"................",
]

## 顺序与 Prize.SYMBOL_NAMES 一致
const SYMBOLS := [CHERRY, COIN, STAR, BELL, SEVEN, INGOT, KOI]


static func draw_sprite(img: Image, rows: Array, ox: int, oy: int) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			var color: Color = PALETTE.get(ch, Color.MAGENTA)
			var px := ox + x
			var py := oy + y
			if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, color)


## 抽点缩小绘制（step 为取样间隔）
static func draw_sprite_shrunk(img: Image, rows: Array, ox: int, oy: int, step: int) -> void:
	for y in range(0, rows.size(), step):
		var row: String = rows[y]
		for x in range(0, row.length(), step):
			var ch := row[x]
			if ch == ".":
				continue
			var color: Color = PALETTE.get(ch, Color.MAGENTA)
			var px := ox + x / step
			var py := oy + y / step
			if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
				img.set_pixel(px, py, color)

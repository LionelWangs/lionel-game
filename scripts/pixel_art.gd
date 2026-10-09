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
const C_SKIN := Color8(242, 200, 158)
const C_SKIN_DARK := Color8(198, 150, 108)
const C_STEEL := Color8(138, 158, 180)
const C_STEEL_LIGHT := Color8(214, 228, 240)

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
	"p": C_SKIN,
	"P": C_SKIN_DARK,
	"t": C_STEEL,
	"T": C_STEEL_LIGHT,
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

## 刮擦工具：随 SHARP EDGE 等级一路升级，图案底部中央是落点
const TOOL_FINGER := [
	"................",
	"................",
	"......kkkk......",
	".....kppppk.....",
	".....kpPPpk.....",
	".....kpPPpk.....",
	".....kpPPpk.....",
	".....kpPPpk.....",
	".....kpPPpk.....",
	".....kpPPpk.....",
	".....kpPPpk.....",
	".....kpPPpk.....",
	".....kppppk.....",
	".....kwwwwk.....",
	"......kkkk......",
	"................",
]

const TOOL_NAIL := [
	"................",
	"................",
	"......kkkk......",
	".....kppppk.....",
	".....kpPPpk.....",
	".....kpPPpk.....",
	".....kpPPpk.....",
	".....kpPPpk.....",
	".....kpPPpk.....",
	".....kpPPpk.....",
	".....kpPPpk.....",
	".....kpwwpk.....",
	".....kpwwpk.....",
	"......kwwk......",
	".......kk.......",
	"................",
]

const TOOL_SCRAPER := [
	"................",
	"................",
	"............kk..",
	"...........kbbk.",
	"..........kbbk..",
	".........kbbk...",
	"........kbbk....",
	".......kbbk.....",
	"......kbbk......",
	"..kkkkkkkkk.....",
	".kTTTTTTTTTk....",
	".ktttttttttk....",
	".kkkkkkkkkk.....",
	"................",
	"................",
	"................",
]

const TOOL_SHOVEL := [
	"................",
	"................",
	"..........kk....",
	".........kbbk...",
	".........kbbk...",
	".........kbbk...",
	".........kbbk...",
	".........kbbk...",
	"......kkkkbbkk..",
	".....kTTTTTTTk..",
	".....ktttttttk..",
	"......ktttttk...",
	".......ktttk....",
	"........kkk.....",
	"................",
	"................",
]

const TOOL_COIN := [
	"................",
	"................",
	".....kkkkkk.....",
	"...kkGGGGGGkk...",
	"..kGGhhhhhhGGk..",
	".kGGhhGGGGhhGGk.",
	".kGhhGGGGGGhhGk.",
	"kGhhGGGGGGGGhhGk",
	"kGhhGGGGGGGGhhGk",
	".kGhhGGGGGGhhGk.",
	".kGGhhGGGGhhGGk.",
	"..kGGhhhhhhGGk..",
	"...kkGGGGGGkk...",
	".....kkkkkk.....",
	"................",
	"................",
]

const TOOL_SPATULA := [
	"................",
	"...........kk...",
	"..........kbbk..",
	"..........kbbk..",
	"..........kbbk..",
	"..........kbbk..",
	"..........kbbk..",
	"..........kbbk..",
	".......kkkkk....",
	"....kkkTTTTkk...",
	"..kkTTTTTTTTk...",
	".kttttttttttk...",
	".kttttttttttk...",
	".kkkkkkkkkkkk...",
	"................",
	"................",
]

const TOOL_GOLD_SHOVEL := [
	"..........h.....",
	"..........kkk...",
	".........kbbk...",
	".........kbbk...",
	".........kbbk...",
	".........kbbk...",
	".........kbbk...",
	".........kbbk...",
	"......kkkkbbkk..",
	".....khhhhhhhk..",
	".....kgGGGGGgk..",
	".....kgGGGGGgk..",
	"......kgGGGgk...",
	".......kgggk....",
	"........kkk.....",
	"................",
]

## 索引即 SHARP EDGE 等级，名称 key 走 tr()
const TOOLS := [
	TOOL_FINGER, TOOL_NAIL, TOOL_SCRAPER, TOOL_SHOVEL,
	TOOL_COIN, TOOL_SPATULA, TOOL_GOLD_SHOVEL,
]

const TOOL_NAMES := [
	"FINGER", "LONG NAIL", "SCRAPER", "SHOVEL", "COIN", "SPATULA", "GOLD SHOVEL",
]

## 每个工具在贴图里的着力点，用来把工具尖端对准手指 / 鼠标位置
const TOOL_ANCHORS := [
	Vector2i(8, 15), Vector2i(8, 15), Vector2i(6, 13), Vector2i(9, 14),
	Vector2i(8, 14), Vector2i(7, 14), Vector2i(9, 15),
]


static func tool_index(edge_level: int) -> int:
	return clampi(edge_level, 0, TOOLS.size() - 1)


static func tool_rows(edge_level: int) -> Array:
	return TOOLS[tool_index(edge_level)]


static func tool_name_key(edge_level: int) -> String:
	return TOOL_NAMES[tool_index(edge_level)]


static func tool_anchor(edge_level: int) -> Vector2:
	return Vector2(TOOL_ANCHORS[tool_index(edge_level)])


## 16x16 工具贴图，供光标与 HUD 复用
static func tool_image(edge_level: int) -> Image:
	var img := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	draw_sprite(img, tool_rows(edge_level), 0, 0)
	return img


static var _tool_textures: Dictionary = {}


## 工具贴图（带缓存）：刮卡光标与 HUD 图标共用
static func tool_texture(edge_level: int) -> ImageTexture:
	var index := tool_index(edge_level)
	if not _tool_textures.has(index):
		_tool_textures[index] = ImageTexture.create_from_image(tool_image(index))
	return _tool_textures[index]


## 鼠标光标的放大倍数：越到后面越有分量，升级一眼能看出来
const TOOL_CURSOR_SCALES := [2, 3, 3, 4, 4, 5, 5]
## 触屏时画在手指上方的放大倍数（游戏内坐标）
const TOOL_TOUCH_SCALES := [2, 2, 2, 3, 3, 3, 3]


static func tool_cursor_scale(edge_level: int) -> int:
	return TOOL_CURSOR_SCALES[tool_index(edge_level)]


static func tool_touch_scale(edge_level: int) -> int:
	return TOOL_TOUCH_SCALES[tool_index(edge_level)]


## 整数倍放大（最近邻），保持像素锐利
static func tool_image_scaled(edge_level: int, scale: int) -> Image:
	var img := tool_image(edge_level)
	var factor := maxi(1, scale)
	if factor > 1:
		img.resize(img.get_width() * factor, img.get_height() * factor, Image.INTERPOLATE_NEAREST)
	return img


static var _cursor_textures: Dictionary = {}


## 系统鼠标指针贴图：按档位放大后缓存
static func tool_cursor_texture(edge_level: int) -> ImageTexture:
	var index := tool_index(edge_level)
	if not _cursor_textures.has(index):
		_cursor_textures[index] = ImageTexture.create_from_image(
			tool_image_scaled(index, TOOL_CURSOR_SCALES[index]))
	return _cursor_textures[index]


## 光标热点：工具着力点在放大贴图里的坐标
static func tool_cursor_hotspot(edge_level: int) -> Vector2:
	var index := tool_index(edge_level)
	return tool_anchor(index) * float(TOOL_CURSOR_SCALES[index])


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

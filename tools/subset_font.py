#!/usr/bin/env python3
"""按项目实际用到的字符裁剪像素字体。

完整字体 6.7MB，游戏里只用到几百个字形，裁剪后约 110KB（gzip 约 32KB），
网页版首屏包体因此大幅变小。

用法：
    python3 -m venv .venv
    .venv/bin/pip install fonttools
    .venv/bin/python tools/subset_font.py

源字体放在 assets/fonts/source/fusion_pixel_12px_zh_cn-full.ttf（Godot 通过
.gdignore 忽略该目录）。生成结果覆盖 assets/fonts/fusion_pixel_12px_zh_cn.ttf。
新增游戏文案后重新运行本脚本，并跑 tools/check_font.gd 校验字形覆盖。
"""

from __future__ import annotations

import pathlib
import sys

try:
    from fontTools import subset
except ImportError:  # pragma: no cover - 环境缺少依赖时给出明确提示
    sys.exit("缺少 fonttools，请先运行：pip install fonttools")

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/fonts/source/fusion_pixel_12px_zh_cn-full.ttf"
TARGET = ROOT / "assets/fonts/fusion_pixel_12px_zh_cn.ttf"

## 参与统计的文本来源：界面脚本、场景、翻译表、工具脚本
SOURCES = [
    "scripts/*.gd",
    "scenes/*.tscn",
    "localization/*.po",
    "tools/*.gd",
    "project.godot",
]

## 兜底字符集：金额、符号、标点，避免格式化输出缺字形
FALLBACK = (
    "0123456789"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "abcdefghijklmnopqrstuvwxyz"
    " .,:;!?+-*/%()[]{}<>|_=#&@'\"`~\\"
    "×÷—…、，。！？：；“”‘’（）《》【】·￥$£¥°"
)


def collect_chars() -> set[str]:
    chars: set[str] = set(FALLBACK)
    inputs = 0
    for pattern in SOURCES:
        for path in sorted(ROOT.glob(pattern)):
            if not path.is_file():
                continue
            inputs += 1
            chars |= set(path.read_text(encoding="utf-8", errors="ignore"))
    print(f"扫描 {inputs} 个文本文件，需要 {len(chars)} 个字形")
    return chars


def main() -> int:
    if not SOURCE.is_file():
        return _fail(f"找不到源字体：{SOURCE}")

    chars = collect_chars()
    codepoints = [ord(c) for c in chars if c.isprintable()]

    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.hinting = False
    options.desubroutinize = True
    options.drop_tables += ["DSIG"]

    source_cmap = _load_cmap(SOURCE)
    unsupported = sorted(c for c in chars if c.isprintable() and ord(c) not in source_cmap)
    if unsupported:
        print("源字体不含这些字符，已跳过：" + "".join(unsupported))
    codepoints = [c for c in codepoints if c in source_cmap]

    font = subset.load_font(str(SOURCE), options)
    try:
        subsetter = subset.Subsetter(options=options)
        subsetter.populate(unicodes=codepoints)
        subsetter.subset(font)
        TARGET.parent.mkdir(parents=True, exist_ok=True)
        subset.save_font(font, str(TARGET), options)
    finally:
        font.close()

    cmap = _load_cmap(TARGET)
    missing = sorted(c for c in chars if c.isprintable() and ord(c) not in cmap)
    if missing:
        return _fail("生成字体缺少字形：" + "".join(missing))

    before = SOURCE.stat().st_size
    after = TARGET.stat().st_size
    print(f"源字体 {before / 1024:.0f} KB -> 裁剪后 {after / 1024:.0f} KB "
          f"（{(1 - after / before) * 100:.1f}% 体积被裁掉）")
    print(f"已写入 {TARGET.relative_to(ROOT)}")
    return 0


def _load_cmap(path: pathlib.Path) -> dict[int, str]:
    from fontTools.ttLib import TTFont

    with TTFont(path, lazy=True) as font:
        return font.getBestCmap()


def _fail(message: str) -> int:
    print(message, file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

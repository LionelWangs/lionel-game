#!/usr/bin/env python3
"""列出 Godot 导出的 .pck 里包含哪些文件（用于检查包体构成）。

用法：
    python3 tools/pck_list.py build/web/index.pck
    python3 tools/pck_list.py build/web/index.pck --top 15
"""

from __future__ import annotations

import argparse
import pathlib
import struct
import sys


def _read(handle, fmt: str):
    size = struct.calcsize(fmt)
    data = handle.read(size)
    if len(data) != size:
        raise ValueError("文件结构不完整")
    return struct.unpack(fmt, data)


def parse(path: pathlib.Path) -> list[tuple[str, int]]:
    """读取 PCK 目录表，返回 (资源路径, 未压缩大小)。"""
    with path.open("rb") as handle:
        magic = handle.read(4)
        if magic != b"GDPC":
            raise ValueError(f"不是 PCK 文件（magic={magic!r}）")

        (version,) = _read(handle, "<I")
        _read(handle, "<III")  # 引擎版本 major/minor/patch
        _read(handle, "<I")  # pack_flags
        _read(handle, "<Q")  # files_base
        _read(handle, "<16I")  # reserved

        (count,) = _read(handle, "<I")
        entries: list[tuple[str, int]] = []
        for _ in range(count):
            (length,) = _read(handle, "<I")
            name = handle.read(length).decode("utf-8", errors="replace").rstrip("\x00")
            if not name.startswith("res://"):
                raise ValueError(f"路径解析异常（version={version}）：{name!r}")
            _offset, size = _read(handle, "<QQ")
            _read(handle, "<16B")
            if version >= 2:
                _read(handle, "<I")
            entries.append((name, size))
        return entries


def main() -> int:
    parser = argparse.ArgumentParser(description="列出 PCK 内容")
    parser.add_argument("pck", type=pathlib.Path)
    parser.add_argument("--top", type=int, default=10, help="按体积显示前 N 项")
    parser.add_argument("--filter", default="", help="只显示路径包含该字符串的条目")
    args = parser.parse_args()

    if not args.pck.is_file():
        print(f"找不到文件：{args.pck}", file=sys.stderr)
        return 1

    try:
        entries = parse(args.pck)
    except ValueError as error:
        print(f"解析失败：{error}", file=sys.stderr)
        return 1

    total = sum(size for _name, size in entries)
    print(f"{args.pck} -> {len(entries)} 个文件，共 {total / 1024 / 1024:.2f} MB")

    if args.filter:
        for name, size in entries:
            if args.filter in name:
                print(f"{size / 1024:10.1f} KB  {name}")
        return 0

    for name, size in sorted(entries, key=lambda item: item[1], reverse=True)[:args.top]:
        print(f"{size / 1024:10.1f} KB  {name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

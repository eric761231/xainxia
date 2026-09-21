#!/usr/bin/env python3
"""Read-only consistency check for map-0 property SQL and Flutter catalog.

Collision is decided by the server (``property.footprint_w/h``, ``blocking``)
while the artwork and the ground shadow are decided by the client
(``object_catalog.json``).  When those two disagree you get a bookshelf you can
walk through, or an invisible wall — and neither shows up as an error anywhere,
so it has to be checked explicitly.

Nothing here is pinned to one particular layout any more.  The SQL says which
objects the room has and where they stand; the catalog is then checked against
whatever the SQL asks for.  Re-running ``DrawPng/build_map0_furnishing_sql.py``
therefore cannot leave this file behind.

    python tools/verify_map0_furniture_layout.py \
        --project ../XinProject/xianxia_game --server .
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


# map 0 的可走範圍。改格網時這裡與 DB 的 map 表、maps/0.json 要一起改。
LO, HI = 31, 40


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


def parse_templates(sql: str) -> dict[int, tuple[int, int, int, int]]:
    """id -> (pngid, blocking, footprint_w, footprint_h) from the property INSERT."""
    rows = re.findall(
        r"^\s*\((\d+),(\d+),(\d+),(\d+),(\d+),\d+,\d+,'[a-z]+',",
        sql,
        flags=re.M,
    )
    return {
        int(item_id): (int(pngid), int(blocking), int(width), int(height))
        for item_id, pngid, blocking, width, height in rows
    }


def parse_spawns(sql: str) -> set[tuple[int, int, int]]:
    """(property id, x, y) from the spawnlist_scene INSERT: ('zone', id, 'name', 1, x, y, 0, 0)."""
    return {
        (int(item_id), int(x), int(y))
        for item_id, x, y in re.findall(
            r"\(\s*'[^']*',\s*(\d+),\s*'[^']*',\s*1,\s*(\d+),\s*(\d+),\s*0,\s*0\)", sql)
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--server", type=Path, required=True)
    args = parser.parse_args()

    catalog = json.loads(
        (args.project / "assets" / "data" / "object_catalog.json")
        .read_text(encoding="utf-8"))["objects"]
    sql = (args.server / "sql" / "map0_cave.sql").read_text(encoding="utf-8")

    templates = parse_templates(sql)
    spawns = parse_spawns(sql)
    if not templates or not spawns:
        fail("map0_cave.sql 解析不到模板或生成點")

    for item_id, x, y in sorted(spawns):
        if not LO <= x <= HI or not LO <= y <= HI:
            fail(f"{item_id} 的座標 ({x},{y}) 超出 map 0 的合法範圍 {LO}..{HI}")

    for item_id, (pngid, blocking, width, height) in sorted(templates.items()):
        if pngid != item_id:
            fail(f"property {item_id} 的 pngid 是 {pngid}；兩者必須同號")
        item = catalog.get(str(pngid))
        if item is None:
            fail(f"catalog 缺少 {pngid}")
        if tuple(item.get("footprint", [1, 1])) != (width, height):
            fail(f"{pngid} 的 footprint 不一致：SQL {(width, height)} / "
                 f"catalog {tuple(item.get('footprint', []))}")
        if bool(item.get("blocking")) != bool(blocking):
            fail(f"{pngid} 的 blocking 不一致：SQL {blocking} / catalog {item.get('blocking')}")
        image = args.project / "assets" / item.get("dir", "objects") / item.get("image", "")
        if not image.is_file():
            fail(f"{pngid} 的圖檔不存在：{image}")
        shadow = item.get("shadow", {})
        if not shadow.get("enabled", True) or shadow.get("offsetTiles", [0, 0]) != [0, 0]:
            fail(f"catalog {pngid} 的接地陰影不是上方光置中：{shadow}")

    # 兩件家具不能搶同一格，否則房裡會出現「家具裡的家具」。
    occupied: dict[tuple[int, int], int] = {}
    for item_id, x, y in sorted(spawns):
        if item_id not in templates:
            continue  # 模板在 schema_all.sql（例如 4003 聚靈法陣）
        _, blocking, width, height = templates[item_id]
        if not blocking:
            continue
        for j in range(height):
            for i in range(width):
                cell = (x - i, y - j)
                if cell in occupied:
                    fail(f"{item_id} 與 {occupied[cell]} 的 footprint 共用格 {cell}")
                occupied[cell] = item_id

    print(f"PASS: {len(templates)} 個模板 / {len(spawns)} 個生成點；"
          "footprint、blocking、圖檔、接地陰影與座標範圍一致，且無重疊格")


if __name__ == "__main__":
    main()

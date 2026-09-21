#!/usr/bin/env python3
"""Reconcile the three places that describe a scene object.

    sql/*.sql                     property templates (collision) + spawn points
    assets/data/object_catalog.json  artwork, footprint, ground shadow
    assets/objects/**                the image files themselves

None of these validates the others at runtime.  A spawn row whose template is
missing makes `SceneSpawnTable.spawnFixed()` log one warning and return 0 — the
server starts fine and the map is simply empty.  A template whose catalog entry
points at a deleted PNG draws a green placeholder block.  A footprint that
disagrees between server and catalog gives you furniture you can see but walk
through.  All three have happened in this repo; this script is what catches them
next time.

    python tools/verify_property_catalog.py --project ../XinProject/xianxia_game --server .

Scope note: it reads the checked-in SQL, not a live database, so it can run
without credentials.  It takes the union of every `INSERT` in `sql/*.sql`,
skipping `*_rollback.sql` and `map_backup/` — rollbacks deliberately re-create
rows the forward patch removed, so counting them would defeat the check.
DELETE statements are not replayed; that is sound here because nothing is
inserted and then dropped again by a forward patch.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

# Deliberately not anchored to the start of a line: some seeds put every row on
# one `VALUES (...),(...);` line.  The trailing `'placement'` (a lowercase word
# in quotes) is what keeps this from matching npc/item rows, whose second column
# is a quoted name.
PROPERTY_ROW = re.compile(
    r"\((\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*\d+,\s*(\d+),\s*'[a-z]+',")
# 場景物件生成點只在 `INSERT INTO spawnlist_scene` 裡：先切出這些陳述式再取每列的
# property_id（第二欄），避免把欄位形狀相同的 spawnlist_npc／spawnlist_monster 列算進來。
SCENE_INSERT = re.compile(r"INSERT INTO `spawnlist_scene`.*?;", re.S)
SPAWN_ROW = re.compile(r"\(\s*'[^']*',\s*(\d+)\s*,")


def report(problems: list[str], warnings: list[str]) -> None:
    for line in warnings:
        print("  ! ", line)
    if problems:
        print(f"FAIL: {len(problems)} 個問題")
        for line in problems:
            print("  - ", line)
        raise SystemExit(1)


def sql_files(server: Path) -> list[Path]:
    return sorted(
        f for f in (server / "sql").glob("*.sql")
        if not f.name.endswith("_rollback.sql")
    )


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", type=Path, required=True)
    ap.add_argument("--server", type=Path, required=True)
    args = ap.parse_args()

    catalog = json.loads(
        (args.project / "assets" / "data" / "object_catalog.json")
        .read_text(encoding="utf-8"))["objects"]

    templates: dict[int, tuple[int, int, int, int]] = {}
    spawned: dict[int, set[str]] = {}
    for path in sql_files(args.server):
        text = path.read_text(encoding="utf-8")
        for row in PROPERTY_ROW.finditer(text):
            oid, pngid, blocking, width, height, placeable = (
                int(g) for g in row.groups())
            templates[oid] = (pngid, blocking, width, height, placeable)
        for statement in SCENE_INSERT.findall(text):
            for oid in SPAWN_ROW.findall(statement):
                spawned.setdefault(int(oid), set()).add(path.name)

    problems: list[str] = []
    warnings: list[str] = []

    for oid, files in sorted(spawned.items()):
        if oid not in templates:
            problems.append(
                f"生成點用了 property {oid}，但沒有任何 SQL 建立這個模板"
                f"（出現在 {', '.join(sorted(files))}）—— 該地圖會整片生不出來")

    for oid, (pngid, blocking, width, height, placeable) in sorted(templates.items()):
        if pngid != oid:
            problems.append(f"property {oid} 的 pngid 是 {pngid}；兩者應同號")
        entry = catalog.get(str(pngid))
        if entry is None:
            problems.append(f"property {oid} 在 object_catalog.json 沒有對應定義")
            continue
        fw, fh = entry.get("footprint", [1, 1])
        if (fw, fh) != (width, height):
            problems.append(
                f"{oid} 的 footprint 不一致：SQL {(width, height)} / "
                f"catalog {(fw, fh)} —— 碰撞會與看到的底座差格")
        if bool(entry.get("blocking")) != bool(blocking):
            problems.append(
                f"{oid} 的 blocking 不一致：SQL {blocking} / "
                f"catalog {entry.get('blocking')}")
        image = args.project / "assets" / entry.get("dir", "objects") / entry.get("image", "")
        if not image.is_file():
            if placeable or oid in spawned:
                who = "玩家放置清單" if placeable else "生成點"
                problems.append(
                    f"{oid} 的圖檔不存在：{image.name} —— {who}拿得到它，"
                    f"進遊戲就是綠色色塊")
            else:
                # 沒有生成點、也不可放置：壞的但摸不到。降級成提醒，免得一個待補的
                # 美術把整條檢查擋成紅燈。
                warnings.append(
                    f"{oid}（{entry.get('label', '')}）的圖檔不存在：{image.name}；"
                    f"目前 placeable=0 且無生成點，暫時碰不到")

    for key in sorted(catalog, key=int):
        if int(key) not in templates:
            problems.append(
                f"catalog 有 {key}（{catalog[key].get('label', '')}）但沒有 property 模板"
                f" —— 伺服器永遠送不出這個物件")

    report(problems, warnings)
    print(f"PASS: {len(templates)} 個模板 / {len(spawned)} 個被生成的 id / "
          f"{len(catalog)} 筆 catalog 定義，三方一致")


if __name__ == "__main__":
    main()

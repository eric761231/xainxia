"""Mixamo FBX → L1 圖集（PNG + JSON），格式與 assets/monsters/black_forest/mountain_wolf.json 相同。

用法（在 repo 根目錄）：
    python tools/sprites/mixamo_to_l1.py                 # 跑全部工作
    python tools/sprites/mixamo_to_l1.py --job brady     # 只跑一個（可重複 --job）
    python tools/sprites/mixamo_to_l1.py --force         # 忽略快取，全部重新渲染

工作清單在 tools/sprites/mixamo_sprites.json。每個工作的 src 資料夾放
idle.fbx / walk.fbx / attack.fbx / hurt.fbx / death.fbx，缺的動作會跳過。

流程：
1. 每個動作呼叫一次 Blender（blender_render_frames.py），把 8 方向的幀渲染到
   build/mixamo_sprites/<key>/<action>/。FBX 沒變、參數沒變就沿用上次的結果。
2. 每幀依 alpha 裁掉透明邊，記下 rect 與「相對腳底原點」的 offset。
3. 依高度排序做 shelf packing，寫出 PNG + JSON。
4. 輸出預覽圖 build/mixamo_sprites/preview_<key>.png（動作為列、方向為欄，
   紅色十字是腳底原點），用來檢查方向與著地點。
"""

import argparse
import json
import math
import os
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
TOOLS = Path(__file__).resolve().parent
CONFIG = TOOLS / "mixamo_sprites.json"
RENDER_SCRIPT = TOOLS / "blender_render_frames.py"
WORK = ROOT / "build" / "mixamo_sprites"

ACTION_ORDER = ["walk", "idle", "attack", "hurt", "death"]
FACINGS = 8
MAX_ATLAS_WIDTH = 2048
PADDING = 1
# 低於這個 alpha 的像素視為透明，避免抗鋸齒的淡邊把裁切框撐大
ALPHA_THRESHOLD = 3

NOTE = (
    "緊密打包圖集。每一幀畫在「角色原點 + offset」；原點是腳底著地點，也就是元件自己的位置。"
    "key 是 <動作>-<facing>，facing 0=NE 1=E 2=SE 3=S 4=SW 5=W 6=NW 7=N。"
)


def load_jobs(selected):
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    defaults = config.get("defaults", {})
    jobs = []
    for raw in config["jobs"]:
        if selected and raw["key"] not in selected:
            continue
        job = {k: v for k, v in defaults.items() if k != "actions"}
        job.update({k: v for k, v in raw.items() if k != "actions"})
        actions = {name: dict(spec) for name, spec in defaults.get("actions", {}).items()}
        for name, spec in raw.get("actions", {}).items():
            actions.setdefault(name, {}).update(spec)
        job["actions"] = actions
        jobs.append(job)
    unknown = set(selected or []) - {j["key"] for j in jobs}
    if unknown:
        raise SystemExit(f"設定檔裡沒有這些工作：{', '.join(sorted(unknown))}")
    return config, jobs


def find_blender(cli_value, config):
    for candidate in (cli_value, os.environ.get("BLENDER"), config.get("blender"), "blender"):
        if not candidate:
            continue
        found = shutil.which(candidate) or (candidate if Path(candidate).exists() else None)
        if found:
            return found
    raise SystemExit("找不到 Blender，請用 --blender 指定 blender.exe 的路徑")


def render_action(blender, job, action, spec, fbx, out_dir, force):
    manifest_path = out_dir / "manifest.json"
    if not force and manifest_path.exists() and manifest_path.stat().st_mtime >= fbx.stat().st_mtime:
        cached = json.loads(manifest_path.read_text(encoding="utf-8"))
        same = (
            cached.get("frames") == spec["frames"]
            and cached.get("canvas") == job["canvas"]
            and cached.get("pxPerMeter") == float(job["pxPerMeter"])
            and cached.get("pitch") == float(job["pitch"])
            and cached.get("targetZ") == float(job["targetZ"])
        )
        if same:
            print(f"  {action}: 沿用上次的渲染結果")
            return cached

    print(f"  {action}: 渲染中（{spec['frames']} 幀 × {FACINGS} 方向）…", flush=True)
    cmd = [
        blender, "-b", "--factory-startup", "--python-exit-code", "1",
        "-P", str(RENDER_SCRIPT), "--",
        "--fbx", str(fbx),
        "--out", str(out_dir),
        "--frames", str(spec["frames"]),
        "--px-per-m", str(job["pxPerMeter"]),
        "--canvas", str(job["canvas"]),
        "--pitch", str(job["pitch"]),
        "--target-z", str(job["targetZ"]),
    ]
    if spec.get("loop"):
        cmd.append("--loop")
    if spec.get("lockRoot"):
        cmd.append("--lock-root")
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0 or not manifest_path.exists():
        print(result.stdout[-4000:])
        print(result.stderr[-4000:], file=sys.stderr)
        raise SystemExit(f"Blender 渲染失敗：{fbx}")
    return json.loads(manifest_path.read_text(encoding="utf-8"))


def trim_frames(action_dir, manifest):
    """讀回某個動作的所有幀，回傳 [facing][i] = (裁切後的圖, offset)。"""
    ox = round(manifest["origin"][0])
    oy = round(manifest["origin"][1])
    result = []
    for facing in range(FACINGS):
        frames = []
        for i in range(manifest["frames"]):
            image = Image.open(action_dir / str(facing) / f"{i}.png").convert("RGBA")
            mask = image.getchannel("A").point(lambda v: 255 if v >= ALPHA_THRESHOLD else 0)
            bbox = mask.getbbox()
            if bbox is None:
                frames.append((Image.new("RGBA", (1, 1)), (0, -1)))
                continue
            frames.append((image.crop(bbox), (bbox[0] - ox, bbox[1] - oy)))
        result.append(frames)
    return result


def pack(images):
    """Shelf packing。回傳每張圖的 (x, y) 與圖集大小。"""
    total_area = sum((im.width + PADDING) * (im.height + PADDING) for im in images)
    widest = max(im.width for im in images) + PADDING
    width = max(widest, min(MAX_ATLAS_WIDTH, math.ceil(math.sqrt(total_area * 1.1))))
    order = sorted(range(len(images)), key=lambda k: (-images[k].height, -images[k].width))
    positions = [None] * len(images)
    x = y = row_height = 0
    for k in order:
        im = images[k]
        if x + im.width > width:
            x = 0
            y += row_height + PADDING
            row_height = 0
        positions[k] = (x, y)
        x += im.width + PADDING
        row_height = max(row_height, im.height)
    used_width = max(positions[k][0] + images[k].width for k in range(len(images)))
    return positions, (used_width, y + row_height)


def write_preview(job, trimmed, path):
    """動作為列、方向為欄，各取第 0 幀；紅色十字是腳底原點。"""
    firsts = [(action, facing, frames[facing][0])
              for action, frames in trimmed.items() for facing in range(FACINGS)]
    left = max(-off[0] for _, _, (_, off) in firsts)
    right = max(off[0] + im.width for _, _, (im, off) in firsts)
    up = max(-off[1] for _, _, (_, off) in firsts)
    down = max(0, max(off[1] + im.height for _, _, (im, off) in firsts))
    margin, label = 8, 14
    cell_w = left + right + margin * 2
    cell_h = up + down + margin * 2 + label
    actions = list(trimmed)
    sheet = Image.new("RGBA", (cell_w * FACINGS, cell_h * len(actions)), (70, 74, 80, 255))
    draw = ImageDraw.Draw(sheet)
    names = ["NE", "E", "SE", "S", "SW", "W", "NW", "N"]
    for action, facing, (im, off) in firsts:
        cx = facing * cell_w
        cy = actions.index(action) * cell_h
        ox = cx + margin + left
        oy = cy + label + margin + up
        sheet.alpha_composite(im, (ox + off[0], oy + off[1]))
        draw.line([(ox - 6, oy), (ox + 6, oy)], fill=(255, 60, 60, 255))
        draw.line([(ox, oy - 6), (ox, oy + 6)], fill=(255, 60, 60, 255))
        draw.text((cx + 3, cy + 2), f"{action} {facing} {names[facing]}", fill=(230, 230, 230, 255))
    sheet.save(path)


def build_job(blender, job, force):
    key = job["key"]
    src = (ROOT / job["src"]).resolve()
    out_png = ROOT / job["out"]
    print(f"[{key}] {job.get('name', key)}  來源：{src}")

    trimmed = {}
    for action in ACTION_ORDER:
        spec = job["actions"].get(action)
        fbx = src / f"{action}.fbx"
        if spec is None:
            continue
        if not fbx.exists():
            print(f"  {action}: 找不到 {fbx.name}，跳過")
            continue
        action_dir = WORK / key / action
        manifest = render_action(blender, job, action, spec, fbx, action_dir, force)
        trimmed[action] = trim_frames(action_dir, manifest)

    if not trimmed:
        print("  沒有任何 FBX，略過這個工作")
        return False
    if "walk" not in trimmed:
        print("  警告：缺少 walk。遊戲裡移動與站立都會借用 walk，這份圖集在遊戲裡不會動")

    flat = []
    for action, frames in trimmed.items():
        for facing in range(FACINGS):
            for i, (im, off) in enumerate(frames[facing]):
                flat.append((action, facing, i, im, off))
    positions, (width, height) = pack([item[3] for item in flat])
    if height > 8192:
        print(f"  警告：圖集高度 {height}px 超過 8192，部分手機 GPU 載入不了；請降低幀數或 pxPerMeter")

    atlas = Image.new("RGBA", (width, height))
    animations = {}
    for (action, facing, i, im, off), (x, y) in zip(flat, positions):
        atlas.paste(im, (x, y))
        entry = animations.setdefault(f"{action}-{facing}", {"frameCount": 0, "frames": []})
        entry["frames"].append({"frame": i, "rect": [x, y, im.width, im.height], "offset": list(off)})
        entry["frameCount"] = len(entry["frames"])

    out_png.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(out_png, optimize=True)
    meta = {
        "source": f"Mixamo {job.get('name', key)}（tools/sprites/mixamo_to_l1.py）",
        "note": NOTE,
        "tile": [64, 32],
        "scale": 1,
        "directions": FACINGS,
        "textureSize": [width, height],
        "actions": list(trimmed),
        "texture": out_png.name,
        "animations": animations,
    }
    out_json = out_png.with_suffix(".json")
    out_json.write_text(json.dumps(meta, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    preview = WORK / f"preview_{key}.png"
    write_preview(job, trimmed, preview)
    print(f"  輸出：{os.path.relpath(out_png, ROOT)}（{width}×{height}）、{out_json.name}")
    print(f"  預覽：{preview}")
    return True


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except AttributeError:
        pass
    parser = argparse.ArgumentParser(description="Mixamo FBX → L1 圖集")
    parser.add_argument("--job", action="append", help="只跑指定的工作 key，可重複")
    parser.add_argument("--blender", help="blender.exe 路徑（預設讀設定檔或 BLENDER 環境變數）")
    parser.add_argument("--force", action="store_true", help="忽略快取，全部重新渲染")
    args = parser.parse_args()

    config, jobs = load_jobs(args.job)
    blender = find_blender(args.blender, config)
    built = [job["key"] for job in jobs if build_job(blender, job, args.force)]
    print(f"完成 {len(built)}/{len(jobs)} 個工作：{', '.join(built) or '（無）'}")


if __name__ == "__main__":
    main()

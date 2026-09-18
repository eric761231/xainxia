"""在 Blender 內執行：匯入一個 Mixamo FBX，渲染 8 個方向的動畫幀。

由 tools/sprites/mixamo_to_l1.py 呼叫，一般不需要手動執行：

    blender -b --factory-startup --python-exit-code 1 \
        -P tools/sprites/blender_render_frames.py -- \
        --fbx ../art_source/mixamo/brady/walk.fbx --out build/xxx/walk --frames 8 --loop

輸出：
    <out>/<facing>/<i>.png   facing 0=NE 1=E 2=SE 3=S 4=SW 5=W 6=NW 7=N
    <out>/manifest.json      腳底原點在畫布上的像素位置、取樣參數

幾何約定：
- 攝影機是正交投影，繞 X 轉 pitch 度（預設 60°），從 −Y 往 +Y 看。
  俯角 30° 讓地面的深度方向縮成 sin30° = 0.5，剛好是 2:1 等距地磚。
- 世界原點 (0,0,0) 就是腳底著地點。角色放在一個位於原點的 Pivot 底下，
  轉 Pivot 來換方向；攝影機與燈光不動，8 個方向的明暗才會一致。
- Mixamo 角色匯入後面向 −Y（面向鏡頭）= facing 3（S）。
  facing f 的旋轉角 = (3 − f) × 45°，例如 E（1）轉 +90° 面向 +X = 畫面右方。
"""

import argparse
import json
import math
import shutil
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--fbx", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--frames", type=int, default=8)
    p.add_argument("--loop", action="store_true",
                   help="循環動作：不取最後一幀（它與第一幀是同一個姿勢）")
    p.add_argument("--lock-root", action="store_true",
                   help="抵銷 Hips 的水平位移，讓角色原地播放（防沒勾 In Place）")
    p.add_argument("--px-per-m", type=float, default=115.0)
    p.add_argument("--canvas", type=int, default=512)
    p.add_argument("--pitch", type=float, default=60.0)
    p.add_argument("--target-z", type=float, default=0.9,
                   help="攝影機瞄準的高度（公尺），大隻的怪要調高")
    p.add_argument("--engine", default="BLENDER_EEVEE")
    p.add_argument("--samples", type=int, default=16)
    return p.parse_args(argv)


def clear_scene():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)


def import_character(fbx):
    bpy.ops.import_scene.fbx(filepath=str(fbx), automatic_bone_orientation=False)
    scene = bpy.context.scene
    arm = next((o for o in scene.objects if o.type == "ARMATURE"), None)
    if arm is None:
        raise SystemExit(f"找不到骨架：{fbx}")
    if not (arm.animation_data and arm.animation_data.action):
        raise SystemExit(f"FBX 裡沒有動畫：{fbx}")
    if not any(o.type == "MESH" for o in scene.objects):
        raise SystemExit(f"FBX 裡沒有模型，下載時 Skin 要選 With Skin：{fbx}")

    pivot = bpy.data.objects.new("Pivot", None)
    scene.collection.objects.link(pivot)
    # Pivot 在原點且沒有旋轉，直接設 parent 不會改變子物件的世界座標
    for obj in list(scene.objects):
        if obj.parent is None and obj is not pivot:
            obj.parent = pivot
    return arm, pivot


def setup_camera(args):
    scene = bpy.context.scene
    data = bpy.data.cameras.new("SpriteCam")
    data.type = "ORTHO"
    data.ortho_scale = args.canvas / args.px_per_m
    data.clip_start = 0.1
    data.clip_end = 500
    cam = bpy.data.objects.new("SpriteCam", data)
    scene.collection.objects.link(cam)

    pitch = math.radians(args.pitch)
    cam.rotation_euler = (pitch, 0, 0)
    forward = Vector((0, math.sin(pitch), -math.cos(pitch)))
    cam.location = Vector((0, 0, args.target_z)) - forward * 100
    scene.camera = cam
    return cam


def setup_lights():
    scene = bpy.context.scene
    key = bpy.data.lights.new("Key", "SUN")
    key.energy = 3.0
    key_obj = bpy.data.objects.new("Key", key)
    # 從鏡頭這一側的左上方打光
    key_obj.rotation_euler = (math.radians(35), 0, math.radians(-35))
    scene.collection.objects.link(key_obj)

    rim = bpy.data.lights.new("Rim", "SUN")
    rim.energy = 1.2
    rim_obj = bpy.data.objects.new("Rim", rim)
    # 從背後右上方勾邊，深色衣服的輪廓才不會糊進背景
    rim_obj.rotation_euler = (math.radians(-40), 0, math.radians(30))
    scene.collection.objects.link(rim_obj)

    world = bpy.data.worlds.new("SpriteWorld")
    scene.world = world
    try:
        world.use_nodes = True
    except AttributeError:
        pass
    if world.node_tree:
        bg = world.node_tree.nodes.get("Background")
        if bg:
            bg.inputs[0].default_value = (1, 1, 1, 1)
            bg.inputs[1].default_value = 0.6


def setup_render(args):
    scene = bpy.context.scene
    r = scene.render
    try:
        r.engine = args.engine
    except TypeError:
        r.engine = "BLENDER_EEVEE_NEXT"
    r.resolution_x = args.canvas
    r.resolution_y = args.canvas
    r.resolution_percentage = 100
    r.film_transparent = True
    r.image_settings.file_format = "PNG"
    r.image_settings.color_mode = "RGBA"
    r.image_settings.color_depth = "8"
    scene.view_settings.view_transform = "Standard"
    if hasattr(scene, "eevee"):
        scene.eevee.taa_render_samples = args.samples


def sample_times(action, count, loop):
    start, end = action.frame_range
    if count <= 1:
        return [start]
    if loop:
        return [start + (end - start) * i / count for i in range(count)]
    return [start + (end - start) * i / (count - 1) for i in range(count)]


def set_frame(scene, t):
    whole = int(math.floor(t))
    scene.frame_set(whole, subframe=t - whole)


def main():
    args = parse_args()
    out = Path(args.out)
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)

    clear_scene()
    arm, pivot = import_character(args.fbx)
    cam = setup_camera(args)
    setup_lights()
    setup_render(args)

    scene = bpy.context.scene
    view_layer = bpy.context.view_layer
    action = arm.animation_data.action
    times = sample_times(action, args.frames, args.loop)
    hips = next((b for b in arm.pose.bones if b.name.lower().endswith("hips")), None)
    if args.lock_root and hips is None:
        print("警告：找不到 Hips 骨，--lock-root 無效")

    for facing in range(8):
        pivot.rotation_euler = (0, 0, math.radians((3 - facing) * 45))
        base = None
        for i, t in enumerate(times):
            set_frame(scene, t)
            pivot.location = (0, 0, 0)
            view_layer.update()
            if args.lock_root and hips is not None:
                head = arm.matrix_world @ hips.head
                if base is None:
                    base = head.copy()
                pivot.location = (base.x - head.x, base.y - head.y, 0)
                view_layer.update()
            path = out / str(facing) / f"{i}.png"
            path.parent.mkdir(parents=True, exist_ok=True)
            scene.render.filepath = str(path)
            bpy.ops.render.render(write_still=True)

    origin = world_to_camera_view(scene, cam, Vector((0, 0, 0)))
    manifest = {
        "fbx": str(Path(args.fbx).resolve()),
        "frames": len(times),
        "frameRange": list(action.frame_range),
        "canvas": args.canvas,
        "pxPerMeter": args.px_per_m,
        "pitch": args.pitch,
        "targetZ": args.target_z,
        # 腳底原點在畫布上的像素座標（左上角為 0,0）
        "origin": [origin.x * args.canvas, (1 - origin.y) * args.canvas],
    }
    (out / "manifest.json").write_text(json.dumps(manifest, indent=1), encoding="utf-8")
    print(f"完成：{args.fbx} → {out}（{len(times)} 幀 × 8 方向）")


main()

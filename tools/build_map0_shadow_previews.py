#!/usr/bin/env python3
"""Produce the map-0 furniture visual QA images from the live catalog and SQL layout.

The three output PNGs deliberately use the same 64×32 projection as
IsoObjectComponent.  This tool is diagnostic only: game shadows remain runtime
Flame layers and are not baked into a furniture asset.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


TILE_W, TILE_H = 64, 32
HALF_W, HALF_H = 32, 16
# Calibrated from the existing 20×20 map-0 floor.  (31, 31) is its upper tip.
GRID_ORIGIN = (672, -615)


@dataclass(frozen=True)
class Placement:
    id: int
    x: int
    y: int
    label: str


PLACEMENTS = (
    Placement(4001, 35, 36, "書櫃 A"),
    Placement(4001, 47, 36, "書櫃 B"),
    Placement(4003, 40, 39, "聚靈法陣"),
    Placement(4002, 43, 45, "書桌"),
    Placement(4004, 34, 46, "紫藤"),
    Placement(4007, 48, 46, "翠竹"),
    Placement(4008, 35, 48, "菊花"),
)


def point(x: int, y: int) -> tuple[float, float]:
    return (GRID_ORIGIN[0] + (x - y) * HALF_W,
            GRID_ORIGIN[1] + (x + y) * HALF_H)


def diamond(cx: float, cy: float) -> list[tuple[float, float]]:
    return [(cx, cy - HALF_H), (cx + HALF_W, cy),
            (cx, cy + HALF_H), (cx - HALF_W, cy)]


def footprint_polygons(item: Placement, definition: dict) -> list[list[tuple[float, float]]]:
    fw, fh = definition["footprint"]
    polygons = []
    for dy in range(fh):
        for dx in range(fw):
            # Must match IsoMapComponent._rebuildPropertyCollision: anchor - dx/dy.
            polygons.append(diamond(*point(item.x - dx, item.y - dy)))
    return polygons


def load_object_image(objects: Path, definition: dict) -> Image.Image:
    asset = Image.open(objects / definition["image"]).convert("RGBA")
    if "src" in definition:
        x, y, w, h = definition["src"]
        asset = asset.crop((x, y, x + w, y + h))
    source_w, source_h = asset.size
    tiles_w = definition.get("tilesW", 0)
    if tiles_w:
        scaled_w = TILE_W * tiles_w
        scaled_h = round(source_h * scaled_w / source_w)
        asset = asset.resize((scaled_w, scaled_h), Image.Resampling.LANCZOS)
    return asset


def resolved_anchor(definition: dict, source_size: tuple[int, int], render_size: tuple[int, int]) -> tuple[float, float]:
    src_w, src_h = source_size
    anchor = definition.get("anchor", [src_w / 2, src_h])
    return (anchor[0] * render_size[0] / src_w,
            anchor[1] * render_size[1] / src_h)


def paint_shadows(base: Image.Image, catalog: dict, only_shadow: bool) -> Image.Image:
    shadow_layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    for item in PLACEMENTS:
        definition = catalog[str(item.id)]
        spec = definition.get("shadow", {})
        if not spec.get("enabled", True):
            continue
        opacity = float(spec.get("opacity", 0.20))
        if opacity <= 0:
            continue
        offset = spec.get("offsetTiles", [0, 0])
        dx, dy = offset[0] * TILE_W, offset[1] * TILE_H
        shape = Image.new("L", base.size, 0)
        draw = ImageDraw.Draw(shape)
        for poly in footprint_polygons(item, definition):
            draw.polygon([(x + dx, y + dy) for x, y in poly], fill=round(opacity * 255))
        blur = float(spec.get("blur", 4.0))
        shadow_layer.alpha_composite(Image.merge("RGBA", (Image.new("L", base.size, 20),
                                                             Image.new("L", base.size, 14),
                                                             Image.new("L", base.size, 12),
                                                             shape.filter(ImageFilter.GaussianBlur(blur)))))
    return shadow_layer if only_shadow else Image.alpha_composite(base, shadow_layer)


def paint_props(canvas: Image.Image, catalog: dict, objects: Path) -> None:
    # Flame uses foot-y priority; stable x tie-break keeps the preview deterministic.
    for item in sorted(PLACEMENTS, key=lambda p: (*reversed(point(p.x, p.y)), p.id)):
        definition = catalog[str(item.id)]
        raw = Image.open(objects / definition["image"]).convert("RGBA")
        if "src" in definition:
            sx, sy, sw, sh = definition["src"]
            raw = raw.crop((sx, sy, sx + sw, sy + sh))
        image = load_object_image(objects, definition)
        ax, ay = resolved_anchor(definition, raw.size, image.size)
        foot_x, foot_y = point(item.x, item.y)
        canvas.alpha_composite(image, (round(foot_x - ax), round(foot_y - ay)))


def paint_markers(canvas: Image.Image, catalog: dict) -> None:
    draw = ImageDraw.Draw(canvas, "RGBA")
    font = ImageFont.load_default()
    for item in PLACEMENTS:
        definition = catalog[str(item.id)]
        for poly in footprint_polygons(item, definition):
            draw.polygon(poly, fill=(240, 62, 62, 32), outline=(255, 88, 60, 235), width=1)
        cx, cy = point(item.x, item.y)
        draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(255, 211, 40, 255), outline=(72, 45, 0, 255))
        draw.text((cx + 7, cy + 4), f"{item.id} {item.x},{item.y}", fill=(255, 228, 71, 255), font=font, stroke_width=1, stroke_fill=(0, 0, 0, 255))
    draw.text((32, 30), "MAP 0  |  red = blocking footprint  |  yellow = anchor", fill=(255, 255, 255, 255), font=font)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", type=Path, required=True)
    args = parser.parse_args()
    assets = args.project / "assets"
    maps, objects = assets / "maps", assets / "objects"
    catalog = json.loads((assets / "data" / "object_catalog.json").read_text(encoding="utf-8"))["objects"]
    room = Image.open(maps / "0.png").convert("RGBA")
    if room.size != (1344, 1344):
        raise SystemExit(f"Expected 1344×1344 map 0, got {room.size}")

    official = paint_shadows(room, catalog, only_shadow=False)
    paint_props(official, catalog, objects)
    official.save(maps / "0_furniture_layout_final.png")

    marked = official.copy()
    paint_markers(marked, catalog)
    marked.save(maps / "0_collision_layout_preview.png")

    paint_shadows(room, catalog, only_shadow=True).save(maps / "0_shadow_layout_preview.png")


if __name__ == "__main__":
    main()

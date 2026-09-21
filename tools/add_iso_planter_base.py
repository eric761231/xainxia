#!/usr/bin/env python3
"""Add a crisp 2:1 stone plinth beneath the two generated map-0 plants.

The organic foliage remains painted artwork.  The contact structure is drawn
geometrically so DrawPng can verify the asset's actual ground-facing axes.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


def add_plinth(path: Path, top: int, width: int) -> None:
    source = Image.open(path).convert("RGBA")
    cx = source.width // 2
    half_w, half_h = width // 2, width // 4
    bottom = top + half_h * 2
    canvas = Image.new("RGBA", (source.width, max(source.height, bottom + 10)), (0, 0, 0, 0))
    # The front half remains visible under the vase; the back half is hidden by it.
    d = ImageDraw.Draw(canvas, "RGBA")
    outer = [(cx, top), (cx + half_w, top + half_h), (cx, bottom), (cx - half_w, top + half_h)]
    inner = [(cx, top + 13), (cx + half_w - 26, top + half_h), (cx, bottom - 13), (cx - half_w + 26, top + half_h)]
    d.polygon(outer, fill=(76, 84, 71, 255), outline=(49, 35, 24, 255), width=12)
    d.polygon(inner, fill=(138, 148, 119, 255), outline=(202, 185, 130, 255), width=7)
    # Carved, 2:1 diagonal bands make the load-bearing base measurable at 26.565°.
    for inset in range(48, half_w - 30, 48):
        d.line([(cx - half_w + inset, top + half_h), (cx, top + half_h * 2 - inset // 2)], fill=(86, 94, 76, 230), width=7)
        d.line([(cx, top + half_h * 2 - inset // 2), (cx + half_w - inset, top + half_h)], fill=(86, 94, 76, 230), width=7)
    canvas.alpha_composite(source, (0, 0))
    canvas.save(path)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--objects", type=Path, required=True)
    args = p.parse_args()
    add_plinth(args.objects / "006_bamboo_v2.png", top=1340, width=640)
    add_plinth(args.objects / "009_chrysanthemum_v2.png", top=900, width=760)


if __name__ == "__main__":
    main()

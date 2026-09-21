# Map 0 furniture — DrawPng measurement report

Command: `python measure_object.py <asset> --tiles-w <catalog tilesW>`.
Measured on 2026-09-03 against the live `object_catalog.json` anchors.

| ID | asset / crop | rendered size | measured anchor | catalog anchor | result |
|---|---|---:|---:|---:|---|
| 4001 | `001.png` | 192×278 | `[356,594]` | `[356,594]` | 26.5°, pass |
| 4002 | `002.png` | 192×133 | `[314,304]` | `[314,304]` | 26.5°, pass |
| 4003 | `書櫃書桌.png` crop `[930,480,560,510]` | 256×233 | `[328,474]` | `[328,474]` | anchor pass; circular magic artwork is not a 2:1 structural object (dominant 45.5°); crop touches its atlas edge |
| 4004 | `004.png` | 128×245 | `[103,325]` | `[103,325]` | 26.5°, pass |
| 4007 | `006_bamboo_v2.png` | 128×225 | `[475,1541]` | `[475,1541]` | 26.5°, pass after precise 2:1 planter base |
| 4008 | `009_chrysanthemum_v2.png` | 128×119 | `[695,1106]` | `[695,1106]` | 26.5°, pass after precise 2:1 planter base |

The catalog keeps the game collision specification: bookcases and desk `3×2`, ritual circle `4×3`, plants `1×1`. Visual leaves may extend beyond a pot's collision cell; the pot/plinth contact point and the runtime shadow remain footprint-bound.

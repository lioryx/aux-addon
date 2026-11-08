# Forever UI artwork

These are addon-owned, procedurally drawn assets, not references or copies of
system UI textures. `build_assets.py` reproduces the RGBA TGA exports; `source/`
contains editable SVG geometry. The SVG grain is a construction approximation;
the Python renderer defines the exact small-scale surface shading.

All TGA dimensions are powers of two and exports are uncompressed RGBA.

* `window-edge` and `panel-edge`: 128 x 16, eight 16 x 16 cells ordered
  left, right, top, bottom, top-left, top-right, bottom-left, bottom-right.
  All four straight-edge cells contain vertical strips: Backdrop rotates the
  top/bottom cells while tiling. At edgeSize 16 the painted bevel occupies
  seven pixels; smaller edge sizes scale it proportionally.
* Buttons, tabs, input and headers reserve six pixels for end caps. Keep the
  left/right caps fixed and stretch their center, or use nine-slice rendering.
* `check-on` is a transparent check-mark overlay for `check-off`.
* `portrait-ring` is transparent through its center; layer it over a portrait.
* `row-highlight` is a translucent gold wash with transparent horizontal ends.

No fonts, coin images or item/character artwork are included in this batch.

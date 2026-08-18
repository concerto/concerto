# Content Fit Design

How Concerto decides which screen position a piece of content renders in
(issues #1829 and #1906).

## Principles

1. **Content is (almost) never dropped.** The only thing that keeps content
   off a screen is `Content#renderable?` — "is there anything to show at
   all?" (blank text, a graphic with no usable image). Everything else
   renders *somewhere*: when content fits nowhere well, it renders in its
   least-bad position. Silently missing content is far harder to debug than
   awkwardly rendered content.
2. **`fit_score` is a ranking, not a filter.** When a feed is subscribed to
   several fields on a screen, each piece of content renders only in its
   highest-scoring field (ties go to the lowest field id). A low score never
   removes content; it only loses to better-fitting fields — if there are
   any.
3. **Too small is a defect; too big is fine.** Screens are large TVs in
   public spaces viewed while walking by. Text that renders below a
   readability floor is broken; "WELCOME STUDENTS" rendering enormous in the
   main position is working as intended. The scoring is deliberately
   asymmetric.

## How text is scored (`RichText#fit_score`)

The player auto-sizes text to the largest font that fits its position
(`useTextResize.js` binary search), so the rendered font size is predictable
from the text length and the position's shape. The model replays that fit:

- A position is `width × height` in fractional screen coordinates; width is
  converted to screen-height units via the 16:9 `SCREEN_ASPECT`. Using both
  dimensions matters: an area-only model overestimates extreme shapes like
  the ticker by ~2x.
- For a candidate line count `k`, the position's height caps the font at
  `height / (k × LINE_HEIGHT)` and its width caps it at
  `width × k / (length × CHAR_WIDTH)`. The predicted font is the best
  `min(height cap, width cap)` over all `k` — the same optimum the player's
  binary search finds.
- Text metrics: `CHAR_WIDTH = 0.5` em (average glyph width),
  `LINE_HEIGHT = 1.2` em. These are analytic estimates, not measurements
  against the real template fonts.

The predicted font — a fraction of screen height, so the model is
resolution-independent (1080p and 4K render the same physical size) — is
scored against a legibility band:

- `FONT_TARGET = 0.06` of screen height (~1.4" on a 48" TV): the ideal
  glanceable size. Score is 1.0 here.
- Larger fonts decay gently (`ABOVE_TARGET_WEIGHT = 0.4` per log unit) —
  oversized is acceptable.
- Smaller fonts decay steeply (`BELOW_TARGET_WEIGHT = 3.0`).
- Below `FONT_FLOOR = 0.035` (~0.8" on a 48" TV) an extra
  `BELOW_FLOOR_WEIGHT = 4.0` kicks in — unreadable from a distance.

Penalties are distances in log space, so the band has no bias toward large
or small positions. The score is `exp(-penalty)`, keeping it in `(0, 1]`
and comparable across positions.

HTML content is measured by its visible text (tags stripped). Content that
strips to nothing (a bare link or embed) can't be measured and gets the
neutral base score of 1.0, so it still renders in exactly one field.

### Calibration

Ground truth from Blue Swoosh on a 48" 1080p TV (bamnet, 2026-07):

- Ticker text wrapped to 1–2 lines reads fine; 3 lines is hard; 4 is too
  many. `FONT_FLOOR` sits between the 2-line and 3-line ticker font.
- A 162-char string belongs in the Sidebar, not Main (where it renders
  huge) and not the Ticker (where it wraps past 2 lines).

Resulting placement on Blue Swoosh when content is subscribed everywhere:
Ticker up to ~45 chars, Sidebar ~50–200, Main above that. These boundaries
are pinned by tests in `test/models/rich_text_test.rb` and
`test/controllers/frontend/content_controller_test.rb`; if you retune the
constants, the tests tell you which ground truth you broke.

To retune: adjust `FONT_TARGET`/`FONT_FLOOR` (product decisions about
readability) rather than the penalty weights (shape of the curve) or the
text metrics (font geometry). The floor assumes the smallest common screen
(48"); bigger screens only make text physically larger, which is safe.

## Other content types

- **Graphic**: ranked by aspect-ratio closeness to the position, within a
  2x tolerance window. `renderable?` is false until a displayable image is
  attached (PDFs convert asynchronously).
- **Video**: ranked by aspect-ratio closeness within a 4x window (looser
  because the player letterboxes).
- **Clock, Iframe, and other types**: the base score of 1.0 — no
  preference, so they stay wherever they're subscribed.

## Known limitations / future work

- The text metrics are not measured against the real template fonts; a
  headless-render calibration would firm them up.
- The model assumes wrapping static text; a scrolling ticker would want
  different semantics (single line, no height pressure).
- Non-16:9 screens skew the width conversion; templates record no aspect
  ratio today.
- Admin UI shows no per-field placement preview yet, which is the main
  debugging aid users are missing (#1829).

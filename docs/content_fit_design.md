# Content Fit Design

How Concerto decides which screen position a piece of content renders in
(issues #1829 and #1906).

## Principles

1. **Content is not dropped merely for fitting badly.** Fitting badly and
   being unreadable are different things. Content that fits nowhere *well*
   still renders, in its least-bad position — silently missing content is
   far harder to debug than awkwardly rendered content. Two things, and only
   two, keep content off a screen: `Content#renderable?` ("is there anything
   to show at all?" — blank text, a graphic with no usable image), and a
   `fit_score` of `0.0`, which says this position cannot show this content
   legibly. See [The legibility veto](#the-legibility-veto).
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
4. **The lines the author wrote are the content's shape.** A break the
   author typed is free — it is what the content was designed to look like,
   and a field tall enough to honour it is a good home. A break a position
   imposes by wrapping is a cost. This is the difference between a sentence
   reading as two ticker lines and the same sentence poured into a ten-line
   column.

## How text is scored (`RichText#fit_score`)

The player auto-sizes text to the largest font that fits its position
(`useTextResize.js` binary search), so both the rendered font size and the
line count are predictable from the text and the position's shape. The model
replays that fit, then scores two things about the result: how legible the
font is, and how much wrapping the position had to impose to get there.

### Predicting the render

- A position is `width × height` in fractional coordinates, which only
  describe a shape once the canvas is known. `Position#aspect_ratio` folds
  in `Template#aspect_ratio` — measured from the template's own background
  image — so the model reads the real shape of a portrait or 4:3 template
  instead of assuming 16:9. Using both dimensions matters: an area-only
  model overestimates extreme shapes like the ticker by ~2x.
- Text is split into the lines the author actually wrote. The player applies
  no `white-space` rule to rich text, so newlines in **plaintext collapse to
  spaces**: plaintext is always one continuous run, and every break in it is
  one a position imposed. In **HTML**, each block element (`BLOCK_ELEMENTS`)
  and each `<br>` starts a line the author asked for.
- Each authored line wraps on its own, so at a given font the rendered line
  count is `Σ ceil(segment / chars_per_line)`, where
  `chars_per_line = width / (font × CHAR_WIDTH)`. Rendered height grows
  monotonically with font, so the model bisects for the largest font whose
  lines still fit — the same optimum the player's binary search finds.

For a single authored line this agrees with the closed form it replaced to
~1e-13, so the band calibration below survived the change untouched.

### Scoring the font

The predicted font is a fraction of screen height, so the model is
resolution-independent — 1080p and 4K render the same physical size. It is
scored against a legibility band:

- `FONT_TARGET = 0.06` of screen height (~1.4" on a 48" TV): the ideal
  glanceable size. Penalty is zero here.
- Larger fonts decay gently (`ABOVE_TARGET_WEIGHT = 0.4` per log unit) —
  oversized is acceptable.
- Smaller fonts decay steeply (`BELOW_TARGET_WEIGHT = 3.0`).
- Below `FONT_FLOOR = 0.035` (~0.8" on a 48" TV) an extra
  `BELOW_FLOOR_WEIGHT = 4.0` kicks in — unreadable from a distance.

### Scoring the wrapping

`WRAP_WEIGHT = 2.0` per log unit of `rendered lines / authored lines`.
Content that renders in exactly the lines its author wrote pays nothing,
however many lines that is — a twelve-item list is not "twelve lines of
damage", it is a list.

Both penalties are distances in log space, so neither term biases toward
large or small positions. The score is `exp(-total penalty)`, keeping it in
`(0, 1]` and comparable across positions.

Two consequences worth knowing:

- **Absolute scores compress** once wrapping is in play, because a single
  authored line rarely survives a large field without being broken. Only the
  ranking is ever used, never the magnitude.
- **The floor is not a veto.** Content can land in a position that renders
  below `FONT_FLOOR` when every alternative scores worse — 162 characters
  wins the Blue Swoosh ticker at 3.3% of screen height. That follows from
  principle 1: the alternative is dropping it.

HTML is measured by its visible text, block by block. Content that yields no
text at all (a bare link or embed) can't be measured and gets the neutral
base score of 1.0, so it still renders in exactly one field.

## Text metrics

`CHAR_WIDTH = 0.5` em (average glyph width) and `LINE_HEIGHT = 1.2` em.

These began as analytic estimates and have since been checked against a real
browser, by running the player's own binary search against a 1920×1080 box
and comparing the font it lands on with the one the model predicts. The
result is worth recording, because it is counter-intuitive:

- Measured individually, the shipped values are both **wrong**. Arial's
  line-height is ~1.15, and real prose averages ~0.457 em per character.
- Substituting the measured values makes the model **less** accurate, not
  more: mean absolute error over predicted-vs-rendered font rises from ~8.6%
  to ~12.0%. The two errors cancel — `LINE_HEIGHT` over-estimates height
  while `CHAR_WIDTH` over-estimates width, and the ratio is what the fit
  depends on.

So do not "correct" one of these in isolation. If they are ever retuned, both
must move together and the predicted-vs-rendered error must be re-measured.

Accuracy is not uniform: plaintext predicts to within ~5%, while
heading-heavy HTML runs ~10–20% high, because headings and paragraphs carry
their own font sizes and margins that the model treats as uniform text.

## Calibration

Ground truth from Blue Swoosh on a 48" 1080p TV:

- Ticker text wrapped to 1–2 lines reads fine; 3 lines is hard; 4 is too
  many.
- A 162-character announcement reads best as **two ticker lines**. It is not
  a Main-position item (where it renders enormous), and it is not a Sidebar
  item — the Sidebar renders it larger but has to break one authored line
  into ten, and ten short lines is the worse read.

`FONT_FLOOR` encodes the readability judgment directly (~0.8" on a 48" TV);
it does not fall on a line-count boundary. On the Blue Swoosh ticker a
2-line render spans 4.17% down to 2.78% of screen height, so the floor sits
partway through that range, crossed at ~153 characters.

Resulting placement on Blue Swoosh when content is subscribed everywhere:

| content | lands in |
|---|---|
| 1–9 characters | Time |
| 10–183 characters, continuous | Ticker |
| 184+ characters, continuous | Main |
| a tall stack of short authored lines | Sidebar |

Note the Sidebar is no longer a length band. It wins *authored structure* —
a list it can render without breaking any of its lines.

These outcomes are pinned by tests in `test/models/rich_text_test.rb` and
`test/controllers/frontend/content_controller_test.rb`; if you retune the
constants, the tests tell you which ground truth you broke.

To retune, in rough order of how safe they are to touch:

1. `FONT_TARGET` / `FONT_FLOOR` — product decisions about readability. The
   floor assumes the smallest common screen (48"); bigger screens only make
   text physically larger, which is safe.
2. `WRAP_WEIGHT` — how much a forced break costs relative to a bad font
   size. This is what decides whether medium-length text belongs in a wide
   strip or a narrow column.
3. The penalty weights (shape of the curve) and the text metrics (font
   geometry) — see the warning above before touching these.

## Other content types

- **Graphic**: ranked by aspect-ratio closeness to the position, within a
  2x tolerance window. `renderable?` is false until a displayable image is
  attached (PDFs convert asynchronously).
- **Video**: ranked by aspect-ratio closeness within a 4x window (looser
  because the player letterboxes).
- **Clock, Iframe, and other types**: the base score of 1.0 — no
  preference, so they stay wherever they're subscribed.

## The legibility veto

Ranking alone cannot say "not here". A `fit_score` of `0.0` does: it means
the position cannot show this content legibly, so it is not a candidate at
all. `Frontend::ContentController#best_field_by_content` only ever considers
positively-scored fields, and content with no positively-scored field
anywhere is held back rather than rendered.

This is not a new mechanism — `Graphic` and `Video` have always returned
`0.0` outside their aspect-ratio windows, which is why an 8.5×11 poster does
not appear in a horizontal ticker strip. `RichText` now participates too, via
`FONT_MINIMUM = 0.015` (~0.35" on a 48" TV — readable from about three feet,
which is not how anyone meets a hallway screen).

The two text thresholds do different jobs and must not be confused:

| | value | on a 48" TV | effect |
|---|---|---|---|
| `FONT_FLOOR` | 0.035 | ~0.82" | steep **penalty**; still renders |
| `FONT_MINIMUM` | 0.015 | ~0.35" | **disqualifies** the position |

`FONT_FLOOR` has to stay soft: the two-line ticker render this model
deliberately favours sits just below it, at ~0.78". On the Blue Swoosh
ticker the separation is wide — 162 characters render at 0.78", 3,000 at
0.20", 18,000 at 0.08".

The veto is deliberately one-directional. Only *illegibly small* disqualifies
a position; oversized never does, and neither does awkward wrapping. That
asymmetry is what keeps #1829 fixed — short text in a large field, which is
what used to vanish, now scores near the top of the band rather than at
zero.

Withholding content is still the most dangerous thing this code does, and a
screen owner currently has no way to see that it happened. The admin
placement view (#1829) is the follow-up that closes that gap.

## Known limitations / future work

- Authored lines are all treated as the same size, so heading-heavy HTML
  predicts high (see **Text metrics**). Ranking is unaffected at the margins
  seen so far.
- The model assumes wrapping static text; a scrolling ticker would want
  different semantics (single line, no height pressure).
- Plaintext newlines collapsing is a player behaviour this model now depends
  on. It is arguably a bug of its own — an author typing a two-line
  plaintext announcement silently gets one run — and fixing it means
  changing plaintext segmentation to match.
- Admin UI shows no per-field placement preview yet, which is the main
  debugging aid users are missing (#1829) — and it matters more now that a
  position can disqualify content outright.
- `FONT_MINIMUM` assumes the smallest common screen (48"). A genuinely large
  video wall would tolerate a smaller fraction, but the error is in the safe
  direction: content is withheld slightly sooner than strictly necessary.

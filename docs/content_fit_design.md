# Content Fit Design

How Concerto decides which screen position a piece of content renders in
(issues #1829, #1906 and #1926).

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
4. **The shape the author gave the content is the content's shape.** A line
   break the author typed is free — it is what the content was designed to
   look like, and a field tall enough to honour it is a good home. A break a
   position imposes by wrapping is a cost. This is the difference between a
   sentence reading as two ticker lines and the same sentence poured into a
   ten-line column. The same holds for images: a position that matches a
   graphic's proportions wastes nothing, and one that does not pays for the
   empty space it letterboxes in.
5. **Size is part of fit, never a consequence of it.** Shape alone cannot
   win a position. A box can be exactly the right proportions for a piece of
   content and still far too small to show it — which is how a 3:1 banner
   used to end up in the clock slot (#1926).

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

## How graphics are scored (`Graphic#fit_score`)

The player letterboxes images (`object-fit: contain` in
`ConcertoGraphic.vue`), so the render is fully determined by the two shapes:
the image takes the largest size the tighter of the box's two dimensions
allows, and whatever is left over is empty. The model scores exactly those
two facts, mirroring the text model term for term.

### Rendered scale — the font-size analogue

Note what this does *not* read: the file's pixel dimensions. Only shape
survives `analyzed_aspect_ratio`, so a 4K upload and a 160×90 thumbnail of
the same proportions score identically everywhere. That is deliberate — the
question is how large the image renders on the screen, not how much detail
it carries — and it means resolution can neither trigger the veto nor rescue
content from it. See **Known limitations** for the flip side.


```
scale = (height the image renders at in this box)
      / (height it would render at on the whole canvas)
```

Both boxes are measured in screen-height units via `Position#width` /
`Position#height`, so the canvas shape is folded in the same way it is for
text. The result is dimensionless, bounded by `1.0`, and resolution
independent: `1.0` means the position constrains the image no more than the
screen itself does.

This is the term that was missing before. A graphic almost always carries
content of its own — a flyer's body text stops being readable long before the
image stops being visible — so how large it renders is a legibility question,
not an aesthetic one.

- At or above `SCALE_TARGET = 0.8` the penalty is zero.
- Below it, `SCALE_WEIGHT = 2.0` per log unit.
- Below `SCALE_MINIMUM = 0.15` the position is disqualified outright. See
  [The legibility veto](#the-legibility-veto).

There is no upper penalty: `scale` cannot exceed `1.0`.

### Letterboxing — the wrapping analogue

`LETTERBOX_WEIGHT = 0.75` per log unit of the distance between the image's
aspect ratio and the position's, which is exactly the log of the fraction of
the box left empty. Like forced wrapping it is a cost and never a veto: a
badly-shaped position wastes space, but what renders is whole and legible.

This term is the same quantity the 2x tolerance window used to compute, so
the *ranking* it produced is preserved. What changed is that the hard cliff
at 2x became a slope, and size became the thing that can disqualify.

### Calibration

Ground truth from #1926, on Blue Swoosh, for an 8.5x11 flyer:

| | Main | Ticker | Sidebar | Time |
|---|---|---|---|---|
| portrait | 0.62 | **0.00** | **0.67** | 0.00 |
| landscape | **0.92** | **0.00** | 0.16 | 0.00 |
| 1331x99 banner | 0.09 | **0.89** | 0.02 | 0.00 |
| 758x307 banner | **0.31** | 0.00 | 0.05 | 0.00 |

A flyer is unreadable in a ticker either way up, comfortable in Main either
way up, and belongs in the Sidebar when it is portrait. A landscape flyer in
the Sidebar is the deliberately borderline case: it renders, but it loses to
Main by a wide margin rather than being ruled out.

The two banners are the shapes from the #1926 report. The wide one still wins
the Ticker. The squarer one previously scored `0.0` in the Ticker and `0.66`
in the *clock* box, so it was routed to a slot that renders it at an eighth
of its usable size — indistinguishable, to a screen owner, from not rendering
at all. Size in the score is what fixes that.

## Other content types

- **Video**: still ranked by aspect-ratio closeness within a 4x window. It
  has the same size blindness `Graphic` had, but different constants: a video
  has no fine detail that must be read, so it tolerates a smaller render.
  Porting this model to it is follow-up work.
- **Clock, Iframe, and other types**: the base score of 1.0 — no
  preference, so they stay wherever they're subscribed.

## The legibility veto

Ranking alone cannot say "not here". A `fit_score` of `0.0` does: it means
the position cannot show this content legibly, so it is not a candidate at
all. `Frontend::ContentController#best_field_by_content` only ever considers
positively-scored fields, and content with no positively-scored field
anywhere is held back rather than rendered.

Every content type states this the same way: a threshold on *how small the
content would render*, never on how badly it is shaped. `Video` is the one
holdout, still vetoing on shape via its 4x aspect-ratio window.

| | threshold | measures | effect |
|---|---|---|---|
| `RichText::FONT_FLOOR` | 0.035 | font, fraction of screen height | steep **penalty**; still renders |
| `RichText::FONT_MINIMUM` | 0.015 | font, fraction of screen height | **disqualifies** the position |
| `Graphic::SCALE_TARGET` | 0.8 | render size ÷ full-canvas render size | **penalty** below; still renders |
| `Graphic::SCALE_MINIMUM` | 0.15 | render size ÷ full-canvas render size | **disqualifies** the position |

On a 48" TV `FONT_MINIMUM` is ~0.35" of text — readable from about three
feet, which is not how anyone meets a hallway screen. `SCALE_MINIMUM` is the
same judgment for images: an 8.5×11 flyer in the Blue Swoosh ticker renders
at `0.10`, a 2.4" sliver.

Both are set for the *extreme* case, not the merely awkward one. `0.15` is
the smallest value that still catches a flyer in every stock template's
ticker — the loosest of them, Ruby, renders it at `0.139` — and at that
setting the veto reaches only tickers and clock boxes. Raising it to `0.20`
begins disqualifying sidebars, which are a real place to put a graphic;
everything short of a sliver should be left to the penalty, because
withholding content is worse than rendering it awkwardly.

Each type keeps a soft threshold above its veto for the same reason: the
render this model deliberately favours in the awkward cases sits just below
it.

`FONT_FLOOR` has to stay soft: the two-line ticker render this model
deliberately favours sits just below it, at ~0.78". On the Blue Swoosh
ticker the separation is wide — 162 characters render at 0.78", 3,000 at
0.20", 18,000 at 0.08".

The veto is deliberately one-directional. Only *too small* disqualifies a
position; oversized never does, and neither does awkward wrapping or heavy
letterboxing. That
asymmetry is what keeps #1829 fixed — short text in a large field, which is
what used to vanish, now scores near the top of the band rather than at
zero.

Withholding content is still the most dangerous thing this code does, and a
screen owner currently has no way to see that it happened. The admin
placement view (#1829) is the follow-up that closes that gap, and it matters
more with every type that gains a veto.

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
- `Graphic` treats every image as carrying detail that must be readable. A
  decorative background or a logo would tolerate a much smaller render than
  `SCALE_MINIMUM` allows, and there is no way for an author to say so.
- Nothing scores image *resolution*. A 160×90 thumbnail stretched across a
  main position scores exactly what a 4K file would, though one of them will
  look like mush. The metadata to fix this is already read
  (`image.metadata[:width]`); what is missing is a term comparing delivered
  pixels against rendered pixels. Related: the player is handed the original
  blob rather than a variant, so a 4K upload ships in full to every screen.
- `Video` has not been ported to this model and still vetoes on shape alone,
  so it retains the failure #1926 describes.

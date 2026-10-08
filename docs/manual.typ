#import "/src/lib.typ": *

#set document(title: "cubst manual")
#set page(numbering: "1")
#set heading(numbering: "1.1")
#show raw.where(block: true): block.with(fill: luma(245), inset: 8pt, radius: 4pt, width: 100%)
#show link: set text(fill: rgb("#1a5fb4"))

#let sune = "R U R' U R U2 R'"
#let tperm = "R U R' U' R' F R2 U' R' U' R U R' F'"
#let scrambled = cube(scramble: "R U F2 D' L B'")

// code on the left, picture on the right
#let example(code, output) = block(breakable: false, grid(
  columns: (1fr, auto),
  gutter: 6mm,
  align: horizon,
  raw(code, lang: "typ", block: true),
  output,
))
// code above, picture below (for wide pictures)
#let example-wide(code, output) = block(breakable: false, stack(dir: ttb, spacing: 4mm, raw(code, lang: "typ", block: true), align(center, output)))
// a picture with a caption under it
#let captioned(pic, cap) = stack(dir: ttb, spacing: 2mm, align(center, pic), align(center, cap))
// pictures side by side, evenly spaced, each with a caption
#let gallery(..items, columns: auto, gutter: 8mm) = block(
  breakable: false,
  align(center, grid(
    columns: if columns == auto { items.pos().len() } else { columns },
    gutter: gutter,
    align: center + bottom,
    ..items.pos().map(((pic, cap)) => captioned(pic, cap)),
  )),
)
#let row(..pics) = pics.pos().join(h(4mm))
// a scheme on one line
#let scheme-of(ev) = raw("(" + cube(event: ev).scheme.pairs().map(((k, v)) => k + ": " + repr(v)).join(", ") + ")", lang: "typ")

#align(center)[
  #text(2em, weight: "bold")[cubst]
  #v(0.5em)
  Draw Rubik's Cubes in Typst
  #v(0.5em)
  Version 0.1.0
]

#outline()

= Quick start

```typ
#import "@preview/cubst:0.1.0": *
```

`case()` builds the state an algorithm solves; `draw()` draws it:

#example("#draw(case(\"R U R' U R U2 R'\"), view: \"oll\")", draw(case(sune), view: "oll"))

`cube()` builds a scrambled puzzle; `event:` picks the puzzle:

#example("#draw(cube(scramble: \"R U F2 D' L B'\"), view: \"full\")", draw(scrambled, view: "full"))

#example(
  "#draw(cube(event: \"pyraminx\",\n  scramble: \"U L R' B u\"), view: \"tip\")",
  draw(cube(event: "pyraminx", scramble: "U L R' B u"), view: "tip"),
)

Everything follows this pattern: build a *state* (@build), then draw it (@draw).

= Building a state <build>

```typ
cube(event: "3x3", scramble: none, inverted: false, scheme: auto, options: (:))
case(alg, event: "3x3", scheme: auto, options: (:))
solved(event: "3x3", scheme: auto, options: (:))
apply(c, alg)
```

#table(
  columns: 2,
  stroke: none,
  [`event`], [which puzzle; case-insensitive, `"3x3x3"` is accepted for `"3x3"`],
  [`scramble`], [moves applied to the solved puzzle, in the order written],
  [`inverted`], [apply the inverse instead, giving the state that `scramble` *solves*],
  [`scheme`], [which color name sits on which face when solved; `auto` = the puzzle's default (@scheme)],
  [`options`], [settings of one puzzle, currently only the megaminx `cut` (@megaminx); other keys are errors],
)

`case(alg)` is `cube(scramble: alg, inverted: true)`: use it for every OLL, PLL
or F2L diagram. `apply` adds moves to an existing state and returns a new one;
states are plain values, never modified in place:

#example(
  "#let c = cube(scramble: \"R U F2 D' L B'\")\n#draw(c, view: \"full\")\n#draw(apply(c, \"y\"), view: \"full\")",
  row(draw(scrambled, view: "full"), draw(apply(scrambled, "y"), view: "full")),
)

#table(
  columns: 3,
  stroke: none,
  table.header[*event*][*puzzle*][*faces*],
  [`"2x2"`, `"3x3"`, … any `"NxN"`], [N×N cube], [`U D F B R L`],
  [`"skewb"`], [skewb], [`U D F B R L`],
  [`"pyraminx"`], [pyraminx], [`F L R D`],
  [`"megaminx"`], [megaminx], [`U F R BR BL L D DR DBR B DBL DL`],
)

== Notation

#link("https://www.worldcubeassociation.org/regulations/#article-12-notation")[WCA notation],
plus whole-puzzle rotations where the WCA has none. Spaces optional where
unambiguous (`RUR'U'`). `(R U R' U')3` repeats a group, `(..)'` inverts it.
Commutators and conjugates nest freely: `[A, B]` is `A B A' B'`; `[A: B]`,
or `A: B` without brackets, is `A B A'`; so `F: [R, U]` and `[F: [R, U]]`
both read `F R U R' U' F'`. Like `(..)`, a bracket can be repeated or
inverted: `[R, U]3`, `[R, U]'`. Bad input fails with a `cubst:` message.

#table(
  columns: 2,
  stroke: none,
  table.header[*N×N cubes*][],
  [`R L U D F B`], [face turns, clockwise seen from that face],
  [`'` `2` `2'`], [counter-clockwise, half turn],
  [`Rw` `r` `3Rw`], [wide turns (lowercase = wide); leading number = layer count],
  [`M E S`], [slices, following `L`, `D`, `F`],
  [`x y z`], [whole-cube rotations about the `R`, `U`, `F` axes],
  table.header[*skewb*][],
  [`R L U B`], [120° clockwise about the DBR, DFL, UBL, DBL corners, seen from the corner; UFR never moves],
  [`y`], [whole-puzzle quarter turn, clockwise seen from above],
  table.header[*pyraminx*][],
  [`U L R B`], [120° clockwise about that vertex, seen from it; tip and layer],
  [`u l r b`], [tip only],
  [`y` `z`], [whole-puzzle 120° turns: `y` about the `U` vertex, clockwise from above; `z` about the `F` centre, clockwise from the front],
  table.header[*megaminx*][],
  [`U F R L BL BR DR DL DBR DBL B D`], [face turns, one fifth; suffixes `'` `2` `2'`],
  [`R++ R--`], [all but L, two fifths, clockwise / counter-clockwise seen from the right],
  [`D++ D--`], [all but U, two fifths, seen from below],
)

== Color scheme <scheme>

A sticker holds a color *name*, such as `"yellow"`, not a color. Two lookups
turn a face into ink:

#align(center, table(
  columns: 5,
  stroke: none,
  align: center + horizon,
  inset: (x: 6pt, y: 4pt),
  [face], [#sym.arrow.r], [name], [#sym.arrow.r], [color],
  [`U`], [*scheme* \ `cube(scheme: ..)`], [`"yellow"`], [*palette* \ `draw(palette: ..)`], [#box(width: 1.5em, height: 1.5em, fill: colors.yellow, stroke: 0.5pt)],
))

The scheme is part of the state: changing it changes which stickers end up
where. The palette (@palette) is part of the picture: changing it only changes
the hues. Below, the same algorithm with the default scheme, with a scheme
that has white on top (now white stickers count as "the top color"), and with
the default scheme but another palette (same state, different yellow):

#let white-up = (U: "white", D: "yellow", F: "green", B: "blue", R: "red", L: "orange")
#example(
  "#let white-up = (\n  U: \"white\", D: \"yellow\", F: \"green\",\n  B: \"blue\", R: \"red\", L: \"orange\",\n)\n#draw(case(sune), view: \"oll\")\n#draw(case(sune, scheme: white-up), view: \"oll\")\n#draw(case(sune), view: \"oll\",\n  palette: (..colors, yellow: rgb(\"#f2c200\")))",
  row(draw(case(sune), view: "oll"), draw(case(sune, scheme: white-up), view: "oll"), draw(case(sune), view: "oll", palette: (..colors, yellow: rgb("#f2c200")))),
)

Every name in a scheme must exist in the palette. The scheme is read when the
state is built, and later only by the `oll` and `f2l` masks to find the top
color; views show faces by position, not by color. The defaults:

#table(
  columns: 2,
  stroke: none,
  [N×N cubes, skewb], scheme-of("3x3"),
  [pyraminx], scheme-of("pyraminx"),
  [megaminx], scheme-of("megaminx"),
)

`default-scheme` is the cube scheme, exported for spreading: `(..default-scheme, U: "white", D: "yellow")`.

== Reading a state <reading>

```typ
face(c, "U")             // stickers of a face: rows on a cube, else a flat array
sticker(c, "U", 0, 2)    // one color name, or none when hidden
is-solved(c)             // every face one color?
```

A sticker *position* is its index on the face, counted as drawn by the `face`
view (`labels: true` writes them on the picture). On N×N cubes it may also be
`(row, col)` from the top left. Side faces are drawn with `U` at the top; `U`
is seen from above with `B` at the top, `D` from below with `F` at the top (on
the pyraminx, `B` at the top; on the megaminx, `F`).

#let blank = colors.pairs().map(((k, v)) => (k, white)).to-dict()
#gallery(
  ..(("3x3", "U"), ("skewb", "U"), ("pyraminx", "F"), ("megaminx", "F")).map(((ev, f)) => (
    draw(cube(event: ev), view: "face", face: f, sticker: 7mm, palette: blank, labels: true),
    raw(ev + ", face " + f),
  )),
)

= Drawing a state <draw>

```typ
draw(c, view: "full", mask: auto,
  sticker: 6mm, gap: 0pt, stroke: 0.5pt + black, radius: 0pt, body: none,
  palette: colors, hidden: auto,
  face: auto, sides: auto, side: 0.35, labels: false,
  arrows: (), arrow-color: black, arrow-thickness: 1.6pt, arrow-head: 0.3,
  tip: "U", spacing: auto)
```

`view` picks the kind of picture and which stickers are hidden; `mask`
overrides the latter; the rest is appearance and means the same in every view.
Options a view does not use are ignored, so one set of options serves every
view.

== Views

A view is a kind of picture plus a default *mask* (which stickers are greyed
out). `face`, `full` and `net` are the generic views; the others fix some
arguments for a common diagram, so `view: "oll"` already hides everything but
the top color. A view a puzzle does not support is an error listing the
available ones.

#table(
  columns: 4,
  stroke: none,
  table.header[*view*][*picture*][*hidden by default*][*puzzles*],
  [`"face"`], [one face straight on, chosen with `face:`], [nothing], [all],
  [`"pll"`], [`face` with `face: "U", sides: true`], [nothing], [N×N cubes],
  [`"oll"`], [`pll` with a mask], [everything but the top color], [N×N cubes],
  [`"full"`], [3D], [nothing], [N×N cubes, skewb, pyraminx],
  [`"f2l"`], [`full` with a mask], [every piece carrying the top color], [N×N cubes],
  [`"tip"`], [3D, looking down a vertex chosen with `tip:`], [nothing], [pyraminx],
  [`"net"`], [unfolded net], [nothing], [all],
)

#gallery(
  columns: 3,
  (draw(case(sune), view: "oll", sticker: 5mm), [`"oll"`]),
  (draw(case(tperm), view: "pll", sticker: 5mm), [`"pll"`]),
  (draw(scrambled, view: "face", face: "F", sticker: 5mm), [`"face"`, `face: "F"`]),
  (draw(case("U R U' R'"), view: "f2l", sticker: 5mm), [`"f2l"`]),
  (draw(scrambled, view: "full", sticker: 5mm), [`"full"`]),
  (draw(cube(scramble: "M2 E2 S2"), view: "net", sticker: 4mm), [`"net"`]),
)

*Straight on.* One face head-on, oriented as in @reading. With
`sides: true` every neighbouring sticker that touches the face is drawn as a
strip outside the shared edge, so `U` with sides is the whole last layer seen
from above. `sides: auto` is off for `face` and on for `pll` and `oll`.

#gallery(
  gutter: 4mm,
  ..("U", "D", "F", "B", "R", "L").map(f => (
    draw(scrambled, view: "face", face: f, sides: true, sticker: 4mm),
    raw("face: \"" + f + "\""),
  )),
)

*3D.* An orthographic view from a camera fixed by the puzzle: N×N cubes and the
skewb from the top-front-right corner (`U`, `F`, `R`); the pyraminx `full` from
the front right and slightly below (`F`, `R`, `D`), its `tip` view straight
down a vertex, the usual last-layer picture. To see other faces, rotate the
state: `draw(apply(c, "y2"), view: "full")`. The megaminx has no 3D view.

*Net.* Every face unfolded: a cross for N×N cubes and the skewb, a large triangle
for the pyraminx, two flowers of six faces (`U` half, `D` half) for the
megaminx. The only view that shows every sticker.

== Mask <mask>

Leave `mask:` out to get the view's default. `mask: none` shows every sticker;
`mask: f` replaces the default with your own function from a state to a state.
Hidden stickers are drawn in the `hidden` color.

#example(
  "#draw(case(\"U R U' R'\"), view: \"f2l\", mask: none)",
  draw(case("U R U' R'"), view: "f2l", mask: none),
)

These functions hide stickers and return the new state. They only ever hide,
so they can be combined in any order, and work on every puzzle:

#table(
  columns: 2,
  stroke: none,
  [`keep-colors(c, "yellow")`], [keep only these color name(s)],
  [`hide-faces(c, ("D", "B"))`], [hide whole faces],
  [`hide-pieces(c, containing: "yellow")`], [hide every piece that has a sticker of that color],
  [`mask(c, info => ..)`], [keep stickers for which the function is true; `info` has `face`, `index`, `color`, `piece`, plus `row`, `col` on N×N cubes],
)

Pass one as `mask:` (wrapped, so the state is filled in by `draw`) or apply it
to the state first; the result is the same:

#example(
  "#draw(case(\"R U R' U'\"), view: \"full\",\n  mask: c => keep-colors(c, (\"yellow\", \"green\")))\n\n#draw(keep-colors(case(\"R U R' U'\"), (\"yellow\", \"green\")),\n  view: \"full\")",
  row(draw(case("R U R' U'"), view: "full", mask: c => keep-colors(c, ("yellow", "green"))), draw(keep-colors(case("R U R' U'"), ("yellow", "green")), view: "full")),
)

== Appearance options

Lengths must be absolute (`mm`, `pt`, `cm`). Sizes are in *units*: one unit is
the edge of a cube sticker; a skewb face and a pyraminx edge are 3 units, a
megaminx face about 3 units wide.

#table(
  columns: 4,
  stroke: none,
  table.header[*option*][*default*][*meaning*][*used by*],
  [`sticker`], [`6mm`], [length of one unit], [all],
  [`gap`], [`0pt`], [space between stickers; `body` shows through it], [all],
  [`stroke`], [`0.5pt + black`], [sticker outline: one Typst stroke (thickness `+` color), a thickness, a color, a dictionary, or `none`], [all],
  [`radius`], [`0pt`], [corner radius of square stickers], [face, net],
  [`body`], [`none`], [color behind the stickers, seen through gaps and the margin around a face], [all],
  [`palette`], [`colors`], [color name → color (@palette)], [all],
  [`hidden`], [`auto`], [color of masked stickers; `auto` = the palette's `hidden` entry], [all],
  [`face`], [`auto`], [face shown by the `face` view; `auto` = `U` (`F` on the pyraminx)], [face],
  [`sides`], [`auto`], [draw the neighbours' stickers as strips; `auto` = off for `face`, on for `pll`, `oll`], [face, pll, oll],
  [`side`], [`0.35`], [strip thickness in units], [face, pll, oll],
  [`labels`], [`false`], [write each sticker's index on it], [face, pll, oll],
  [`arrows`], [`()`], [arrows between positions (@arrows)], [face, pll, oll],
  [`arrow-color`], [`black`], [default arrow color], [face, pll, oll],
  [`arrow-thickness`], [`1.6pt`], [arrow line thickness], [face, pll, oll],
  [`arrow-head`], [`0.3`], [arrow head length in units], [face, pll, oll],
  [`tip`], [`"U"`], [vertex the `tip` view looks down], [tip],
  [`spacing`], [`auto`], [distance between faces; `auto` = a quarter unit], [net],
)

=== Palette <palette>

The palette maps each color *name* to a color (the second lookup in @scheme).
It never changes the state, so one state can be drawn with several palettes.
The default is `colors`: six cube colors, five more for the megaminx, and
`hidden`, the shade of masked stickers (`grey` is an ordinary sticker color):

#block(breakable: false, align(center, grid(
  columns: (1fr,) * 7,
  row-gutter: 4mm,
  align: center,
  ..colors.pairs().map(((name, value)) => captioned(rect(width: 8mm, height: 8mm, fill: value, stroke: 0.5pt), raw(name))),
)))

Spread `colors` to change some entries, for example for print:

#example(
  "#let print = (..colors,\n  red: rgb(\"#d55e00\"), orange: rgb(\"#f0e442\"),\n  yellow: rgb(\"#ffffff\"), white: rgb(\"#999999\"))\n#draw(case(sune), view: \"pll\", palette: print)",
  draw(case(sune), view: "pll", palette: (..colors, red: rgb("#d55e00"), orange: rgb("#f0e442"), yellow: rgb("#ffffff"), white: rgb("#999999"))),
)

=== Outlines and gaps <style>

Every sticker is a filled polygon. `stroke` is its outline, one Typst stroke
value: `0.5pt + black` is a single argument, as in `rect(stroke: ..)`. `gap`
shrinks every sticker towards its centre by half the gap, leaving empty space
that shows `body`. `body` is also seen in the margin between a face and its
side strips. So stickers are separated by outlines, by gaps, or both:

#gallery(
  gutter: 6mm,
  (draw(scrambled, view: "full"), [default \ `stroke: 0.5pt + black` \ `gap: 0pt`]),
  (draw(scrambled, view: "full", stroke: none, gap: 1pt, body: black), [gaps only \ `stroke: none` \ `gap: 1pt, body: black`]),
  (draw(scrambled, view: "full", gap: 1pt, body: luma(230)), [both \ `gap: 1pt` \ `body: luma(230)`]),
  (draw(scrambled, view: "full", stroke: none), [neither \ `stroke: none` \ `gap: 0pt`]),
)

#example(
  "#draw(case(sune), view: \"oll\",\n  stroke: none, gap: 1pt, body: black,\n  radius: 1pt, side: 0.5)",
  draw(case(sune), view: "oll", stroke: none, gap: 1pt, body: black, radius: 1pt, side: 0.5),
)

=== Arrows <arrows>

Arrows join sticker positions (@reading) on the shown face. Each is a pair
`(from, to)` or a dictionary with `from`, `to`, and optionally `double: true`
and `color`:

#example(
  "#draw(case(tperm), view: \"pll\", arrows: (\n  (from: (0, 2), to: (2, 2), double: true),\n  ((1, 0), (1, 2)),\n))",
  draw(case(tperm), view: "pll", arrows: (
    (from: (0, 2), to: (2, 2), double: true),
    ((1, 0), (1, 2)),
  )),
)

= Other puzzles

== Skewb

#example-wide(
  "#let c = cube(event: \"skewb\",\n  scramble: \"R L U B' R' L\")\n#draw(c, view: \"full\")\n#draw(c, view: \"face\", face: \"U\", sides: true)\n#draw(c, view: \"net\", sticker: 4mm)",
  {
    let c = cube(event: "skewb", scramble: "R L U B' R' L")
    row(draw(c, view: "full"), draw(c, view: "face", face: "U", sides: true), draw(c, view: "net", sticker: 4mm))
  },
)

== Pyraminx

#example-wide(
  "#let c = cube(event: \"pyraminx\",\n  scramble: \"U L R' B u l'\")\n#draw(c, view: \"tip\")\n#draw(c, view: \"tip\", tip: \"B\")\n#draw(c, view: \"face\", sides: true)\n#draw(c, view: \"full\")\n#draw(c, view: \"net\", sticker: 4.5mm)",
  {
    let c = cube(event: "pyraminx", scramble: "U L R' B u l'")
    row(draw(c, view: "tip"), draw(c, view: "tip", tip: "B"), draw(c, view: "face", sides: true), draw(c, view: "full"), draw(c, view: "net", sticker: 4.5mm))
  },
)

== Megaminx <megaminx>

#example-wide(
  "#let c = cube(event: \"megaminx\",\n  scramble: \"R++ D-- R++ D++ U F' BL2\")\n#draw(c, view: \"face\", sides: true)\n#draw(case(\"R U R' U'\", event: \"megaminx\"),\n  view: \"face\", sides: true)\n#draw(c, view: \"net\", sticker: 3.5mm)",
  {
    let c = cube(event: "megaminx", scramble: "R++ D-- R++ D++ U F' BL2")
    row(draw(c, view: "face", sides: true), draw(case("R U R' U'", event: "megaminx"), view: "face", sides: true), draw(c, view: "net", sticker: 3.5mm))
  },
)

`cut` sets the centre pentagon: its inradius as a fraction of the face's,
`0.5` by default, between `0.05` and `0.95`. It changes sticker shapes and
layer depth, so it belongs to the state:

#example-wide(
  "#for cut in (0.3, 0.5, 0.7) {\n  draw(cube(event: \"megaminx\", options: (cut: cut)),\n    view: \"face\", sides: true, sticker: 5mm)\n}",
  row(..(0.3, 0.5, 0.7).map(cut => draw(cube(event: "megaminx", options: (cut: cut)), view: "face", sides: true, sticker: 5mm))),
)

= Recipes

== Algorithm sheet

#example(
  "#let algs = (\n  (\"Sune\", \"R U R' U R U2 R'\"),\n  (\"Anti-Sune\", \"R U2 R' U' R U' R'\"),\n)\n#table(\n  columns: 3, align: horizon,\n  ..algs.map(((name, alg)) => (\n    name, draw(case(alg), view: \"oll\", sticker: 5mm), raw(alg)\n  )).flatten(),\n)",
  {
    let algs = (("Sune", "R U R' U R U2 R'"), ("Anti-Sune", "R U2 R' U' R U' R'"))
    table(
      columns: 3,
      align: horizon,
      ..algs.map(((name, alg)) => (name, draw(case(alg), view: "oll", sticker: 5mm), raw(alg))).flatten(),
    )
  },
)

== Step by step

#let steps = ("R", "U", "R'", "U'")
#let states = range(steps.len() + 1).map(k => cube(scramble: steps.slice(0, k).join(" ")))
#example-wide(
  "#let steps = (\"R\", \"U\", \"R'\", \"U'\")\n#let states = range(steps.len() + 1)\n  .map(k => cube(scramble: steps.slice(0, k).join(\" \")))\n#grid(columns: 5, gutter: 4mm,\n  ..states.map(c => draw(c, view: \"full\", sticker: 4mm)))",
  grid(columns: 5, gutter: 4mm, ..states.map(c => draw(c, view: "full", sticker: 4mm))),
)

== Other cube sizes

Every cube view works for any `"NxN"`. Wide moves take a layer count (`3Rw`);
`M`, `E`, `S` turn all middle layers.

#gallery(
  (draw(case("R U R' U R U2 R'", event: "2x2"), view: "oll"), [`"2x2"`, `"oll"`]),
  (draw(cube(event: "4x4", scramble: "Rw U 3Rw' F2"), view: "full", sticker: 4.5mm), [`"4x4"`, `"Rw U 3Rw' F2"`]),
  (draw(cube(event: "5x5", scramble: "3Rw U 3Rw' M2"), view: "full", sticker: 3.5mm), [`"5x5"`, `"3Rw U 3Rw' M2"`]),
)

= Reference

#block(breakable: false, table(
  columns: 2,
  stroke: none,
  table.header[*function*][*purpose*],
  [`cube(event:, scramble:, inverted:, scheme:, options:)`], [build a state],
  [`case(alg, event:, scheme:, options:)`], [the state an algorithm solves],
  [`solved(event:, scheme:, options:)`], [a solved state],
  [`apply(c, alg)`], [apply moves, returns a new state],
  [`is-puzzle(x)`], [whether a value is a state],
  [`parse(alg, event:, options:)`], [algorithm string → move array (`apply` accepts both)],
  [`inverse(alg, event:, options:)`], [the inverse, as a move array],
  [`to-string(moves, event:, options:)`], [move array → notation],
  [`face(c, name)`, `sticker(c, name, ..pos)`, `is-solved(c)`], [read a state (@reading)],
  [`keep-colors`, `hide-faces`, `hide-pieces`, `mask`], [hide stickers (@mask)],
  [`draw(c, view:, mask:, ..)`], [draw a state (@draw)],
  [`draw-face`, `draw-3d`, `draw-net`], [the renderers behind `draw`; `draw-3d` also takes a `camera: (dir:, up:)`],
  [`views`], [the view table: kind, fixed arguments and default mask of each view],
  [`colors`, `default-scheme`], [the default palette and cube scheme],
  [`puzzles`], [the puzzle definitions, keyed `cube`, `skewb`, `pyraminx`, `megaminx`],
))

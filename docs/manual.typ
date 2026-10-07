#import "/src/lib.typ": *

#set document(title: "cubst manual")
#set page(numbering: "1")
#set heading(numbering: "1.1")
#show raw.where(block: true): block.with(fill: luma(245), inset: 8pt, radius: 4pt, width: 100%)

#let sune = "R U R' U R U2 R'"
#let tperm = "R U R' U' R' F R2 U' R' U' R U R' F'"
#let example(code, output) = grid(
  columns: (1fr, auto),
  gutter: 6mm,
  align: horizon,
  raw(code, lang: "typ", block: true),
  output,
)

#align(center)[
  #text(2em, weight: "bold")[cubst]
  #v(0.5em)
  Draw Rubik's cubes in Typst
  #v(0.5em)
  Version 0.1.0
]

#outline()

= Quick start

```typ
#import "@preview/cubst:0.1.0": *
```

Pass an algorithm to `case()` and draw the case it solves:

#example("#draw(case(\"R U R' U R U2 R'\"), view: \"oll\")", draw(case(sune), view: "oll"))

Pass a scramble to `cube()` and draw the whole cube:

#example("#draw(cube(scramble: \"R U F2 D' L B'\"), view: \"full\")", draw(cube(scramble: "R U F2 D' L B'"), view: "full"))

That is the whole idea: *build a cube*, then *draw it*. The rest of this manual
covers the two halves and the options in between.

= Building a cube

== `cube`

```typ
cube(size: 3, scramble: none, inverted: false, scheme: default-scheme)
```

Returns a solved cube of the given size with `scramble` applied. Moves are
applied in the order written, as you would turn a physical cube.

With `inverted: true` the inverse of `scramble` is applied instead. The result
is the state that `scramble` *solves*, which is what a case diagram shows.

== `case`

```typ
case(alg, size: 3, scheme: default-scheme)
```

Shorthand for `cube(scramble: alg, inverted: true)`. Use it for every OLL, PLL
and F2L diagram: give it the algorithm, it gives you the case.

== `apply`

```typ
apply(c, alg)
```

Returns a new cube with more moves applied. The original is unchanged, so you
can keep a state and branch from it:

#example(
  "#let c = cube(scramble: \"R U F2 D' L B'\")\n#draw(c, view: \"full\")\n#draw(apply(c, \"y\"), view: \"full\")",
  [#draw(cube(scramble: "R U F2 D' L B'"), view: "full") #h(4mm) #draw(apply(cube(scramble: "R U F2 D' L B'"), "y"), view: "full")],
)

== Notation

#table(
  columns: 2,
  stroke: none,
  [`R L U D F B`], [face turns, clockwise as seen from that face],
  [`'` `2` `2'`], [suffixes: counter-clockwise, half turn],
  [`Rw` `r` `3Rw`], [wide turns (lowercase is wide); a leading number sets how many layers],
  [`M E S`], [slice moves, following `L`, `D` and `F` respectively],
  [`x y z`], [whole-cube rotations around the `R`, `U` and `F` axes],
  [`(R U R' U')3`], [grouping with repetition; a trailing `'` inverts the group],
)

Spaces are optional: `RUR'U'` is the same as `R U R' U'`. Malformed input stops
compilation with a message starting with `cubst:`.

== Color scheme <scheme>

A cube does not store colors. Every sticker holds a color *name* such as
`"yellow"`. Two separate lookups turn a face into ink on the page:

#align(center, table(
  columns: 5,
  stroke: none,
  align: center + horizon,
  inset: (x: 6pt, y: 4pt),
  [face], [#sym.arrow.r], [name], [#sym.arrow.r], [color],
  [`U`], [*scheme* \ set in `cube()` / `case()`], [`"yellow"`], [*palette* \ set in `draw()`], [#box(width: 1.5em, height: 1.5em, fill: colors.yellow, stroke: 0.5pt)],
))

- The *scheme* belongs to the cube. It says which name sits on which face when
  the cube is solved. Changing it changes the cube itself: different stickers
  end up in different places.
- The *palette* belongs to the picture. It says what a name looks like.
  Changing it leaves the cube untouched: the same stickers are in the same
  places, only the hues differ. It is described with the other drawing options
  in @palette.

A quick test: if swapping two entries changes the *pattern*, you are looking
at the scheme; if it only changes the *shades*, you are looking at the palette.

The default scheme has yellow on top and green in front, which is the usual
last-layer orientation:

#raw(repr(default-scheme), lang: "typ", block: true)

Pass `scheme:` to `cube()` or `case()` to change it. Here the same algorithm is
drawn three times: with the default scheme, with a scheme that solves with
white on top (the pattern is the same, but it is now white stickers that count
as "the top color"), and with the default scheme but a different palette (the
cube is identical to the first one; only the yellow is a different shade):

#let white-up = (U: "white", D: "yellow", F: "green", B: "blue", R: "red", L: "orange")
#example(
  "#let white-up = (\n  U: \"white\", D: \"yellow\", F: \"green\",\n  B: \"blue\", R: \"red\", L: \"orange\",\n)\n#draw(case(sune), view: \"oll\")\n#draw(case(sune, scheme: white-up), view: \"oll\")\n#draw(case(sune), view: \"oll\",\n  palette: (..colors, yellow: rgb(\"#f2c200\")))",
  [#draw(case(sune), view: "oll") #h(3mm) #draw(case(sune, scheme: white-up), view: "oll") #h(3mm) #draw(case(sune), view: "oll", palette: (..colors, yellow: rgb("#f2c200")))],
)

The scheme is read when the cube is built, and afterwards only by the default
masks of `oll` and `f2l` to find "the top color". Views draw faces by position,
not by color. Every name in a scheme must exist in the palette.

== Reading a state

`face(c, "U")` returns a face as an array of rows (3×3 for a 3×3 cube),
`sticker(c, "U", row, col)` one sticker, and `is-solved(c)` reports whether
every face is one color. Rows and columns are 0-based. Faces are laid out as in
the net in @net: `U` is seen from above with `B` at the top; `D` from below
with `F` at the top; the other four from outside with `U` at the top.

= Drawing a cube

```typ
draw(c, view: "full", mask: auto, ..options)
```

`draw` is the single drawing function. `view` picks the kind of picture *and*
which stickers are shown; `mask` lets you override that choice; the remaining
options control appearance and mean the same thing in every view.

== Views

A view decides two things: the kind of picture, and a default *mask*, that is,
which stickers are greyed out. There are three generic views, `face`, `full`
and `net`; the others are shorthands that fix some arguments for a common
diagram. Choosing `view: "oll"` therefore already hides everything but the top
color; you do not need to ask for that separately.

#table(
  columns: 3,
  stroke: none,
  table.header[*view*][*picture*][*hidden by default*],
  [`"face"`], [any face straight on, chosen with `face:`], [nothing],
  [`"pll"`], [shorthand for `face` with `face: "U", sides: true`], [nothing],
  [`"oll"`], [shorthand for `pll` with a mask], [everything except the top color],
  [`"full"`], [3D], [nothing],
  [`"f2l"`], [shorthand for `full` with a mask], [every piece that carries the top color],
  [`"net"`], [unfolded net], [nothing],
)

#align(center, grid(
  columns: 3,
  gutter: 8mm,
  align: center + bottom,
  [#draw(case(sune), view: "oll") \ `"oll"`],
  [#draw(case(tperm), view: "pll") \ `"pll"`],
  [#draw(cube(scramble: "R U F2 D' L B'"), view: "face", face: "F") \ `"face"`, `face: "F"`],
  [#draw(case("U R U' R'"), view: "f2l") \ `"f2l"`],
  [#draw(cube(scramble: "R U F2 D' L B'"), view: "full") \ `"full"`],
  [#draw(cube(scramble: "M2 E2 S2"), view: "net") \ `"net"`],
))

=== Straight-on views: `oll`, `pll`, `face`

One face in the middle, seen head-on, with the adjacent row of each of its four
neighbours drawn as a thin strip around it. Looking at `U` this is exactly the
last layer as you see it from above.

`face` shows any face you name with the `face:` option and hides nothing. The
strips are optional: `sides: true` draws them, `sides: false` leaves just the
face. `pll` is shorthand for `face` with `face: "U", sides: true`, so the whole
last layer is visible and permutation can be read off.
`oll` is `pll` plus a mask that hides every sticker which is not the top color,
so only orientation is visible. Faces are oriented as in the net (@net): the
four side faces with `U` upward, `U` with `B` upward, and `D` with `F` upward.

#align(center, grid(
  columns: 6,
  gutter: 4mm,
  align: center + bottom,
  ..("U", "D", "F", "B", "R", "L").map(f => [#draw(cube(scramble: "R U F2 D' L B'"), view: "face", face: f, sides: true, sticker: 4mm) \ #raw("face: \"" + f + "\"") \ `sides: true`]),
))

=== 3D views: `full`, `f2l`

An isometric view of the top, front and right faces. `full` shows everything.
`f2l` is `full` plus a mask that greys out every piece belonging to the last
layer, which leaves the F2L pair and the solved slots visible.

The camera is fixed. To look at the other faces, turn the cube instead:
`draw(apply(c, "y2"), view: "full")`.

=== The net view: `net` <net>

All six faces unfolded flat. The top face sits above the front face, the bottom
face below it, and left, front, right and back form a row. This is the only
view that shows every sticker at once, which makes it useful for scramble
sheets and for checking a state.

== Overriding the mask

You get the view's default mask by not passing `mask:` at all (its default
value is `auto`, so there is never a reason to write `mask: auto`). To change
it, pass `mask:` yourself:

- `mask: none` shows every sticker, whatever the view;
- `mask: some-function` replaces the default with your own function from a cube
  to a cube.

#example(
  "#draw(case(\"U R U' R'\"), view: \"f2l\", mask: none)",
  draw(case("U R U' R'"), view: "f2l", mask: none),
)

These functions are provided; each returns a new cube with some stickers hidden:

#table(
  columns: 2,
  stroke: none,
  [`keep-colors(c, "yellow")`], [keep only stickers with these color name(s)],
  [`hide-faces(c, ("D", "B"))`], [hide whole faces],
  [`hide-pieces(c, containing: "yellow")`], [hide every piece that has a sticker of that color],
  [`mask(c, info => ..)`], [custom: keep stickers for which the function returns true; `info` has `face`, `row`, `col`, `color`, `pos`],
)

Wrap one in a small function to pass it as `mask:`, or apply it to the cube
before drawing; both give the same result:

#example(
  "#draw(case(\"R U R' U'\"), view: \"full\",\n  mask: c => keep-colors(c, (\"yellow\", \"green\")))\n\n#draw(keep-colors(case(\"R U R' U'\"), (\"yellow\", \"green\")),\n  view: \"full\")",
  [#draw(case("R U R' U'"), view: "full", mask: c => keep-colors(c, ("yellow", "green"))) #h(4mm) #draw(keep-colors(case("R U R' U'"), ("yellow", "green")), view: "full")],
)

Hidden stickers are drawn in the palette's `hidden` color, or in whatever you
pass as `hidden:`. Masks only ever hide, so they can be combined in any order.

== Appearance options

Every option has one meaning and one default, whatever the view. All lengths
must be absolute (`mm`, `pt`, `cm`), not `em`.

#table(
  columns: 4,
  stroke: none,
  table.header[*option*][*default*][*meaning*][*used by*],
  [`sticker`], [`6mm`], [side of one sticker], [all],
  [`gap`], [`0pt`], [space between stickers; `body` shows through it], [all],
  [`stroke`], [`0.5pt + black`], [sticker outline, a Typst stroke (thickness `+` color, or `none`); see @style], [all],
  [`radius`], [`0pt`], [sticker corner radius], [straight-on, net],
  [`face`], [`"U"`], [which face the `face` view looks at], [`face`],
  [`sides`], [`auto`], [draw the neighbours' rows as strips around the face; `auto` = off for `face`, on for `pll` and `oll`], [straight-on],
  [`body`], [`none`], [color behind the stickers, visible only through gaps; see @style], [all],
  [`palette`], [`colors`], [color name → color], [all],
  [`hidden`], [`auto`], [color of masked stickers; `auto` = the palette's `hidden` entry], [all],
  [`side`], [`0.35`], [thickness of the side strips as a fraction of a sticker], [straight-on],
  [`arrows`], [`()`], [arrows on the shown face, see below], [straight-on],
  [`arrow-color`], [`black`], [], [straight-on],
  [`arrow-thickness`], [`1.6pt`], [], [straight-on],
  [`arrow-head`], [`0.3`], [head length as a fraction of a sticker], [straight-on],
  [`spacing`], [`auto`], [distance between faces (`auto` = a quarter sticker)], [net],
)

An option that a view does not use is ignored, so you can keep one set of
options and reuse it for every view.

=== Palette <palette>

The palette maps each color *name* used by the cube to an actual color. It is
the second lookup in @scheme: the scheme decides where the name `"yellow"`
sits, the palette decides what `"yellow"` looks like. Because it is a drawing
option, it never changes the cube, and one state can be drawn with several
palettes.

The default palette is `colors`. Its `hidden` entry is not a sticker color: it
is the shade masked stickers are drawn with (`grey` is an ordinary sticker
color):

#align(center, grid(
  columns: colors.len(),
  gutter: 4mm,
  ..colors.pairs().map(((name, value)) => [#rect(width: 8mm, height: 8mm, fill: value, stroke: 0.5pt) \ #raw(name)]),
))

Pass `palette:` to `draw()` to change how names are rendered. Every name in the
cube's scheme must exist in the palette. Spread `colors` to change only some
entries, for example for a print-friendly or colorblind-friendly set:

#example(
  "#let print = (..colors,\n  red: rgb(\"#d55e00\"), orange: rgb(\"#f0e442\"),\n  yellow: rgb(\"#ffffff\"), white: rgb(\"#999999\"))\n#draw(case(sune), view: \"pll\", palette: print)",
  draw(case(sune), view: "pll", palette: (..colors, red: rgb("#d55e00"), orange: rgb("#f0e442"), yellow: rgb("#ffffff"), white: rgb("#999999"))),
)

=== How `stroke`, `gap`, `body` and `side` fit together <style>

Every sticker is a filled rectangle. The four options describe what is drawn
around it:

- `stroke` is the *outline* of each sticker. It takes a Typst stroke, which is
  a single value written as _thickness `+` color_: `0.5pt + black` is one
  stroke, not two arguments. `none` draws no outline. A thickness alone
  (`1pt`), a color alone (`red`), or a dictionary such as
  `(thickness: 1pt, paint: red, dash: "dashed")` also work, exactly as for
  `rect(stroke: ..)`.
- `gap` is the *empty space* between neighbouring stickers. With `gap: 0pt`
  stickers touch, and only their outlines separate them.
- `body` is the color *behind* the stickers. It is only visible where no
  sticker is: through the gaps, and in the straight-on views in the small
  margin between the face and its side strips. With `body: none` those places
  show the page.
- `side` only applies to the straight-on views: the thickness of the four side
  strips, as a fraction of a sticker. It does not interact with the other
  three.

So a picture is either separated by outlines (`stroke` on, `gap: 0pt`), by
gaps (`stroke: none`, `gap` > 0, a dark `body`), or by both:

#let c = cube(scramble: "R U F2 D' L B'")
#align(center, grid(
  columns: 4,
  gutter: 6mm,
  align: center + bottom,
  [#draw(c, view: "full") \ default \ `stroke: 0.5pt + black` \ `gap: 0pt`],
  [#draw(c, view: "full", stroke: none, gap: 1pt, body: black) \ gaps only \ `stroke: none` \ `gap: 1pt, body: black`],
  [#draw(c, view: "full", gap: 1pt, body: luma(230)) \ both \ `gap: 1pt` \ `body: luma(230)`],
  [#draw(c, view: "full", stroke: none) \ neither \ `stroke: none` \ `gap: 0pt`],
))

The same options on a straight-on view, where `body` also fills the margin
around the face and `side` sets the strip thickness:

#example(
  "#draw(case(sune), view: \"oll\",\n  stroke: none, gap: 1pt, body: black,\n  radius: 1pt, side: 0.5)",
  draw(case(sune), view: "oll", stroke: none, gap: 1pt, body: black, radius: 1pt, side: 0.5),
)

== Arrows

Arrows connect `(row, col)` positions on the shown face, counted from its top
left corner as drawn (for `U`, that is the back left). An arrow is either a
pair of positions or a dictionary with
`from`, `to`, and optionally `double: true` and `color`:

#example(
  "#draw(case(tperm), view: \"pll\", arrows: (\n  (from: (0, 2), to: (2, 2), double: true),\n  (from: (1, 0), to: (1, 2), double: true),\n))",
  draw(case(tperm), view: "pll", arrows: (
    (from: (0, 2), to: (2, 2), double: true),
    (from: (1, 0), to: (1, 2), double: true),
  )),
)

= Recipes

== An algorithm sheet

#example(
  "#let algs = (\n  (\"Sune\", \"R U R' U R U2 R'\"),\n  (\"Anti-Sune\", \"R U2 R' U' R U' R'\"),\n)\n#table(\n  columns: 3,\n  ..algs.map(((name, alg)) => (\n    name, draw(case(alg), view: \"oll\", sticker: 5mm), raw(alg)\n  )).flatten(),\n)",
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

Build the states after 0, 1, 2, … moves and draw each:

#let steps = ("R", "U", "R'", "U'")
#let states = range(steps.len() + 1).map(k => cube(scramble: steps.slice(0, k).join(" ")))
#example(
  "#let steps = (\"R\", \"U\", \"R'\", \"U'\")\n#let states = range(steps.len() + 1)\n  .map(k => cube(scramble: steps.slice(0, k).join(\" \")))\n#grid(columns: 5, gutter: 4mm,\n  ..states.map(c => draw(c, view: \"full\", sticker: 3.5mm)))",
  grid(columns: 5, gutter: 3mm, ..states.map(c => draw(c, view: "full", sticker: 3.5mm))),
)

== Other cube sizes

`cube(size: 2)`, `cube(size: 4)` and so on work with every view. Wide moves
take a layer count (`3Rw`), and `M`, `E`, `S` turn all middle layers.

#align(center, grid(
  columns: 3,
  gutter: 8mm,
  align: bottom,
  draw(case("R U R' U R U2 R'", size: 2), view: "oll"),
  draw(cube(size: 4, scramble: "Rw U 3Rw' F2"), view: "full", sticker: 4.5mm),
  draw(cube(size: 5, scramble: "3Rw U 3Rw' M2"), view: "full", sticker: 3.5mm),
))

= Reference

#table(
  columns: 2,
  stroke: none,
  table.header[*function*][*purpose*],
  [`cube(size:, scramble:, inverted:, scheme:)`], [build a cube],
  [`case(alg, size:, scheme:)`], [the state an algorithm solves],
  [`solved(size:, scheme:)`], [a solved cube],
  [`apply(c, alg)`], [apply moves, returns a new cube],
  [`parse(alg)`, `inverse(alg)`, `to-string(moves)`], [work with move lists],
  [`face(c, name)`, `sticker(c, name, row, col)`, `is-solved(c)`], [read a state],
  [`keep-colors`, `hide-faces`, `hide-pieces`, `mask`], [hide stickers],
  [`draw(c, view:, mask:, ..)`], [draw a cube],
  [`draw-face`, `draw-3d`, `draw-net`], [the renderers behind `draw`, for direct use],
  [`colors`, `default-scheme`], [the default palette and scheme],
)

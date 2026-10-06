#import "/src/lib.typ": *

#set page(width: auto, height: auto, margin: 1cm)
#set text(size: 10pt)

= cubst

#let sune = "R U R' U R U2 R'"
#let tperm = "R U R' U' R' F R2 U' R' U' R U R' F'"
#let f2l = "U R U' R'"

== OLL and PLL (top-down)
#grid(
  columns: 3,
  gutter: 1cm,
  align: center + bottom,
  [#draw(case(sune), view: "oll") \ Sune: `#sune`],
  [#draw(case(tperm), view: "pll", arrows: (
      (from: (0, 2), to: (2, 2), double: true), // UBR ↔ UFR corners
      (from: (1, 0), to: (1, 2), double: true), // UL ↔ UR edges
    )) \ T perm],
  [#draw(cube(scramble: "R U F2 D' L B'"), view: "face", face: "F") \ front face, straight on],
)

== F2L and the whole cube (3D)
#grid(
  columns: 3,
  gutter: 1cm,
  align: center + bottom,
  [#draw(case(f2l), view: "f2l") \ F2L: `#f2l`],
  [#draw(cube(scramble: "R U F2 D' L B'"), view: "full") \ scrambled],
  [#draw(apply(cube(scramble: "R U F2 D' L B'"), "y"), view: "full") \ same, after `y`],
)

== Net and styling
#grid(
  columns: 3,
  gutter: 1cm,
  align: center + bottom,
  [#draw(cube(scramble: "M2 E2 S2"), view: "net") \ checkerboard],
  [#draw(case(sune), view: "oll", gap: 1pt, body: black, stroke: none, radius: 1pt, sticker: 6mm) \ dark style],
  [#draw(cube(size: 4, scramble: "Rw U 3Rw' F2"), view: "full", sticker: 4.5mm) \ 4×4],
)

== Step by step
#let steps = ("R", "U", "R'", "U'")
// states after 0, 1, 2, ... moves
#let states = range(steps.len() + 1).map(k => cube(scramble: steps.slice(0, k).join(" ")))
#grid(
  columns: steps.len() + 1,
  gutter: 6mm,
  align: center + bottom,
  ..states.zip(("start",) + steps).map(((c, label)) => [#draw(c, view: "full", sticker: 4mm) \ #raw(label)]),
)

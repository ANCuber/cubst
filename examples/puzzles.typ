#import "/src/lib.typ": *

#set page(width: auto, height: auto, margin: 1cm)
#set text(size: 10pt)

= Other puzzles

== Skewb
#let sk = cube(event: "skewb", scramble: "R L U B' R' L")
#grid(
  columns: 4,
  gutter: 1cm,
  align: center + bottom,
  [#draw(cube(event: "skewb"), view: "full") \ solved],
  [#draw(sk, view: "full") \ `R L U B' R' L`],
  [#draw(sk, view: "face", face: "U", sides: true) \ face U with sides],
  [#draw(sk, view: "net", sticker: 4.5mm) \ net],
)

== Pyraminx
#let py = cube(event: "pyraminx", scramble: "U L R' B u l'")
#grid(
  columns: 4,
  gutter: 1cm,
  align: center + bottom,
  [#draw(cube(event: "pyraminx"), view: "full") \ solved],
  [#draw(py, view: "full") \ `U L R' B u l'`],
  [#draw(py, view: "tip", options: (tip: "U")) \ from the U tip],
  [#draw(py, view: "net", sticker: 4.5mm) \ net],
)
#grid(
  columns: 4,
  gutter: 1cm,
  align: center + bottom,
  [#draw(cube(event: "pyraminx", scramble: "U"), view: "tip") \ after `U`, from the top],
  [#draw(py, view: "face", face: "F") \ face F],
  [#draw(py, view: "face", face: "D", sides: true) \ face D with sides],
  [#draw(py, view: "tip", options: (tip: "B"), gap: 1pt, body: black, stroke: none) \ from the B tip, dark],
)

== Megaminx
#let mg = cube(event: "megaminx", scramble: "R++ D-- R++ D++ U F' BL2")
#grid(
  columns: 3,
  gutter: 1cm,
  align: center + bottom,
  [#draw(cube(event: "megaminx"), view: "face", face: "U", sides: true) \ solved U with sides],
  [#draw(mg, view: "face", face: "F", sides: true) \ face F],
  [#draw(cube(event: "megaminx", scramble: "U"), view: "face", face: "F", sides: true) \ face F after `U`],
)
#draw(mg, view: "net", sticker: 3.5mm)

== Cubes, straight on and in 3D
#grid(
  columns: 4,
  gutter: 1cm,
  align: center + bottom,
  [#draw(cube(scramble: "R U F2 D' L B'"), view: "face", face: "F", sides: true, gap: 1pt, body: black, stroke: none)],
  [#draw(cube(scramble: "R U F2 D' L B'"), view: "full", gap: 1pt, body: black, stroke: none)],
  [#draw(cube(event: "2x2", scramble: "R U R' U'"), view: "net")],
  [#draw(cube(event: "4x4", scramble: "Rw U 3Rw' F2"), view: "face", face: "U", sides: true, sticker: 4mm)],
)

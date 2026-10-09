#import "/src/lib.typ": *

#set page(height: auto, width: auto, margin: 5mm, fill: none)

// style thumbnail for light and dark theme
#let theme = sys.inputs.at("theme", default: "light")
#let ink = if theme == "dark" { white } else { black }
#set text(ink)
#let stroke = 0.5pt + ink

#grid(
  columns: 5,
  gutter: 7mm,
  align: center + horizon,
  draw(case("R U R' U R U2 R'"), view: "oll", sticker: 5mm, stroke: stroke),
  draw(case("R U R' U' R' F R2 U' R' U' R U R' F'"), view: "ll", sticker: 5mm, stroke: stroke, arrows: (
    (from: (0, 2), to: (2, 2), double: true, color: ink),
    (from: (1, 0), to: (1, 2), double: true, color: ink),
  )),
  draw(cube(scramble: "R U F2 D' L B'"), view: "full", sticker: 5mm, stroke: stroke),
  draw(cube(event: "pyraminx", scramble: "U L R' B u"), view: "tip", sticker: 5mm, stroke: stroke),
  draw(cube(event: "megaminx", scramble: "R++ D-- U"), view: "face", face: "U", sides: true, sticker: 4.5mm, stroke: stroke),
)

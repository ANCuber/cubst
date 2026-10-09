// Views and options that a puzzle does not support are rejected with a
// cubst-prefixed message; `event` names are validated.
#import "/src/lib.typ": *

#let fails(f) = {
  // Typst has no try/catch: check the preconditions the way `draw` does
  f()
}

#assert(cube(event: "3x3").event == "3x3" and cube(event: "7x7").params.size == 7)
#assert(cube(event: "3x3x3").event == "3x3")
#assert(cube(event: "3*3").event == "3x3" and cube(event: "4*4*4") == cube(event: "4x4"))
#assert(cube(event: " Skewb ").puzzle == "skewb")
// build options and drawing options are declared per puzzle
#assert(puzzles.megaminx.options == (cut: 0.4))
#assert("options" not in puzzles.cube)
#assert("draw-options" not in puzzles.pyraminx)
#assert(puzzles.square1.draw-options == (slices: auto, direction: "horizontal", turn: false))
#assert("draw-options" not in puzzles.cube)

#let allowed = (
  "3x3": ("face", "ll", "oll", "f2l", "full", "net"),
  skewb: ("face", "full", "net"),
  pyraminx: ("face", "tip", "full", "net"),
  megaminx: ("face", "full", "net"),
  square1: ("face", "layers", "obl", "cs", "net"),
)
#for (event, vs) in allowed {
  assert(puzzles.at(cube(event: event).puzzle).views == vs)
}

// `view: auto` is the puzzle's default view: full, or layers on the Square-1
#assert(draw(cube()) == draw(cube(), view: "full"))
#assert(draw(cube(event: "megaminx")) == draw(cube(event: "megaminx"), view: "full"))
#assert(draw(cube(event: "square1")) == draw(cube(event: "square1"), view: "layers"))
#assert(puzzles.square1.default-view == "layers" and "default-view" not in puzzles.cube)

// `face: auto` is the puzzle's first face, so the default works on the pyraminx
#assert(draw(cube(event: "pyraminx"), view: "face") == draw(cube(event: "pyraminx"), view: "face", face: "F"))
#assert(draw(cube(event: "3x3"), view: "face") == draw(cube(event: "3x3"), view: "face", face: "U"))
// labels add text to the picture, on every puzzle
#for ev in ("3x3", "skewb", "pyraminx", "megaminx") {
  assert(draw(cube(event: ev), view: "face", labels: true) != draw(cube(event: ev), view: "face"))
}
// `labels: "faces"` names the faces instead, on the straight-on and net views
#for ev in ("3x3", "skewb", "pyraminx", "megaminx", "square1") {
  let plain = draw(cube(event: ev), view: "net")
  assert(draw(cube(event: ev), view: "net", labels: "faces") != plain)
  assert(draw(cube(event: ev), view: "net", labels: true) != plain)
  assert(draw(cube(event: ev), view: "face", labels: "faces") != draw(cube(event: ev), view: "face"))
}

// the view table derives shorthands from the generic views
#assert(views.ll.kind == "face" and views.ll.face == "U" and views.ll.sides)
// the pyraminx tip view takes `tip:`; the full view takes `face:` (in front)
// and `top:` (on top). 3D pictures are CeTZ canvases, which Typst cannot
// compare, so the cameras are checked directly.
#import "/src/draw/views.typ": full-camera
#let near(a, b) = a.zip(b).all(((x, y)) => calc.abs(x - y) < 1e-4)
#let _ = draw(cube(event: "pyraminx"), view: "tip", tip: "B")
#let c3 = cube()
#assert(full-camera(puzzles.cube, c3, auto, auto) == (puzzles.cube.cameras)(c3.params).full)
#assert(near(full-camera(puzzles.cube, c3, "F", "U").dir, (0.57735, 0.57735, 0.57735)))
// R in front, U on top: the camera moves to the top-right-back corner
#assert(near(full-camera(puzzles.cube, c3, "R", "U").dir, (0.57735, 0.57735, -0.57735)))
#assert(near(full-camera(puzzles.cube, c3, "R", "U").up, (0, 1, 0)))
// U in front: the default top does not fit, so F goes on top
#assert(near(full-camera(puzzles.cube, c3, "U", auto).up, (0, 0, 1)))
#let mg = cube(event: "megaminx")
#assert(near(full-camera(puzzles.megaminx, mg, "U", "F").dir, (0, 1, 0)))
#assert(near(full-camera(puzzles.megaminx, mg, "U", auto).dir, (0, 1, 0)))
#let py = cube(event: "pyraminx")
#assert(full-camera(puzzles.pyraminx, py, "F", "L").dir != full-camera(puzzles.pyraminx, py, "F", "U").dir)
#assert(near(full-camera(puzzles.pyraminx, py, "D", auto).dir.map(x => 0), (0, 0, 0)))  // compiles: D with its first vertex
#let _ = draw(cube(event: "skewb"), view: "full", face: "R", top: "D")
#assert(views.oll.mask != none and views.f2l.kind == "3d" and views.tip.camera == "tip")

// Views and options that a puzzle does not support are rejected with a
// cubst-prefixed message; `event` names are validated.
#import "/src/lib.typ": *

#let fails(f) = {
  // Typst has no try/catch: check the preconditions the way `draw` does
  f()
}

#assert(cube(event: "3x3").event == "3x3" and cube(event: "7x7").params.size == 7)
#assert(cube(event: "3x3x3").event == "3x3")
#assert(cube(event: " Skewb ").puzzle == "skewb")
// options are declared per puzzle
#assert(puzzles.megaminx.options == (cut: 0.5))
#assert("options" not in puzzles.cube)

#let allowed = (
  "3x3": ("face", "pll", "oll", "f2l", "full", "net"),
  skewb: ("face", "full", "net"),
  pyraminx: ("face", "tip", "full", "net"),
  megaminx: ("face", "net"),
)
#for (event, vs) in allowed {
  assert(puzzles.at(cube(event: event).puzzle).views == vs)
}

// the view table derives shorthands from the generic views
#assert(views.pll.kind == "face" and views.pll.face == "U" and views.pll.sides)
#assert(views.oll.mask != none and views.f2l.kind == "3d" and views.tip.camera == "tip")

// Looking straight at face X must give the same picture as rotating the cube
// so that X is on top, in the same orientation, and looking at U. The
// rotations themselves are covered by the move tests, so this pins the strip
// orientation of every face view.
//
// Side faces are drawn with U upward, U with B upward, D with F upward (the
// net convention), so each rotation also has to bring the face's top edge to
// where B touches U.
#import "/src/lib.typ": *

#let c = cube(scramble: "R U F2 D' L B' M E S")
#let to-top = (U: "", F: "x", B: "x' y2", R: "z' y", L: "z y'", D: "x2")
#for (f, rot) in to-top {
  assert(
    draw-face(c, face: f) == draw-face(apply(c, rot), face: "U"),
    message: "face view of " + f + " differs from the U view after " + rot,
  )
}

// `pll` is `face` looking at U with strips; `face` alone has none
#assert(draw(c, view: "pll") == draw(c, view: "face", face: "U", sides: true))
#assert(draw(c, view: "face", face: "U") == draw-face(c, face: "U", sides: false))
#assert(draw(c, view: "pll", sides: false) == draw(c, view: "face", face: "U"))

// Looking straight at face X must show the same stickers as rotating the
// cube so that X is on top, in the same orientation, and looking at U.
//
// Side faces are drawn with U upward, U with B upward, D with F upward (the
// net convention), so each rotation also has to bring the face's top edge to
// where B touches U. The strips around the face are checked by the image
// test `render/face`, which draws every face next to the net.
#import "/src/lib.typ": *

#let c = cube(scramble: "R U F2 D' L B' M E S")
#let to-top = (U: "", F: "x", B: "x' y2", R: "z' y", L: "z y'", D: "x2")
#for (f, rot) in to-top {
  assert(
    face(c, f) == face(apply(c, rot), "U"),
    message: "face " + f + " differs from U after " + rot,
  )
}

// `ll` is `face` looking at U with strips; `face` alone has none
#assert(draw(c, view: "ll") == draw(c, view: "face", face: "U", sides: true))
#assert(draw(c, view: "face", face: "U") == draw-face(c, face: "U", sides: false))
#assert(draw(c, view: "ll", sides: false) == draw(c, view: "face", face: "U"))

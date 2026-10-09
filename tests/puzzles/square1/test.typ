// Square-1: (x, y) turns the top layer clockwise seen from above and the
// bottom clockwise seen from below; / swaps the right halves of the two
// layers, turning their pieces over, and flips the equator.
#import "/src/lib.typ": *

#let s = cube(event: "square1")
#let sc = s.scheme
#let after(alg) = apply(s, alg)

// faces: 8 caps per layer; sides = 12 per layer + 6 on the equator
#assert(s.faces.U.len() == 8 and s.faces.D.len() == 8 and s.faces.E.len() == 30)
#assert(is-solved(s) and sc == (U: "yellow", D: "white", F: "red", B: "orange", R: "green", L: "blue"))
#assert(cube(event: "square-1").puzzle == "square1" and cube(event: "SQUAN").event == "square1")
#assert(cube(event: "square-1") == s and cube(event: "Square1").event == "square1")

// a layer is a square when its corners sit 90° apart
#let square(c, name) = {
  let slots = c.layout.at(name)
  let starts = range(12).filter(k => slots.at(k) != slots.at(calc.rem(k + 11, 12)))
  let corners = starts.filter(k => c.layout.pieces.at(slots.at(k)).kind == "corner")
  corners.len() == 4 and corners.map(k => calc.rem(k - corners.first(), 3)).all(d => d == 0)
}
#let cube-shape(c) = square(c, "top") and square(c, "bottom")

// layer turns: full circles, inverses, nothing else moves
#assert(is-solved(after("(12,0)")) and is-solved(after("(0,12)")) and is-solved(after("(3,0) (3,0) (3,0) (3,0)")))
#assert(is-solved(after("(1,0)")) and cube-shape(after("(5,-2)")))   // solved up to turning the layers
#assert(after("(1,2) (-1,-2)") == s and after("(4,0)").faces.U == s.faces.U)
#assert(sticker(after("(3,0)"), "U", 0) == sc.U and after("(3,0)").faces.D == s.faces.D)
// the top turns clockwise seen from above: the piece at slot 0 moves to slot 1
#assert(after("(1,0)").layout.top.at(1) == s.layout.top.at(0))
// the bottom turns clockwise seen from below, i.e. the other way seen from above
#assert(after("(0,1)").layout.bottom.at(11) == s.layout.bottom.at(0))

// the slice
#let sl = after("/")
#assert(sl.layout.flipped and not cube-shape(sl) and not is-solved(sl))
#assert(after("/ /") == s)
// the right half of the top now holds the bottom's right half, reversed and turned over
#assert(sl.layout.top.slice(0, 6) == s.layout.bottom.slice(0, 6).rev())
#assert(sl.layout.top.slice(6) == s.layout.top.slice(6) and sticker(sl, "U", 0) == sc.D)
// on the equator the right piece turns over: its front sticker is now at the back
#assert(face(sl, "E").slice(12, 18) == (sc.F, sc.B, sc.L, sc.F, sc.R, sc.B))   // colours stay in index order ..
#assert(draw(sl, view: "net") != draw(s, view: "net"))                          // .. but the shape changed

// slices are legal exactly when no corner straddles the cut: the usual WCA
// scramble openings all compile
#for alg in ("(1,0)/", "(4,0)/", "(-2,0)/", "(-5,0)/", "(0,-1)/", "(0,2)/", "(0,5)/", "(0,-4)/", "(3,0)/", "(0,-3)/") {
  let _ = after(alg)
}
#let scramble = "(0,-1)/ (3,0)/ (4,0)/ (6,0)/ (3,0)/ (5,0)/ (6,0)/ (-2,-2)/ (0,3)/ (0,-4)/ (0,-5)/ (-1,-2)/ (5,0)/ (6,0)/"
#let scrambled = after(scramble)
#assert(not is-solved(scrambled))
#assert(apply(scrambled, inverse(scramble, event: "square1")) == s)
// `case` inverts from the solved state, which is legal for an algorithm that
// ends solved (it retraces the algorithm's own states), unlike for a scramble
#let swap = "/ (3,-3) / (3,0) / (-3,0) / (0,3) / (-3,0) /"
#assert(case(swap, event: "square1") == apply(s, inverse(swap, event: "square1")))
#assert(is-solved(apply(case(swap, event: "square1"), swap)))

// the adjacent swap keeps cube shape, leaves the bottom alone and swaps two
// neighbouring corner-edge blocks on top (A B C D -> A C B D, up to a turn)
#let adj = after("/ (3,-3) / (3,0) / (-3,0) / (0,3) / (-3,0) /")
#assert(cube-shape(adj) and not adj.layout.flipped and not is-solved(adj))
#assert(adj.faces.U == s.faces.U and adj.faces.D == s.faces.D)
#assert(adj.layout.bottom == s.layout.bottom and adj.layout.pieces == s.layout.pieces)
#assert(adj.layout.top == (4, 4, 5, 2, 2, 3, 6, 6, 7, 0, 0, 1))

// notation round trip and normalisation
#assert(to-string(parse("(1, 0)/(7,-6) /", event: "square1"), event: "square1") == "(1,0) / (-5,6) /")
#assert(to-string(inverse("(1,0) / (2,-3)", event: "square1"), event: "square1") == "(-2,3) / (-1,0)")

// masks survive a move
#assert(apply(hide-faces(s, "E"), "(1,0)").faces.E.all(x => x == none))
#assert(hide-pieces(s, containing: sc.U).faces.E.filter(x => x == none).len() == 12)

// every view; the layers views can be arranged vertically
#for v in ("face", "layers", "obl", "cs", "net") { let _ = draw(sl, view: v) }
#assert(draw(s, view: "obl") != draw(s, view: "cs"))
#assert(draw(s, view: "layers", options: (direction: "vertical")) != draw(s, view: "layers"))
#assert(draw(s, view: "layers", options: (slices: false)) != draw(s, view: "layers"))
#assert(draw(s, view: "layers", options: (slices: auto, direction: "horizontal", turn: false)) == draw(s, view: "layers"))
#assert(draw(s, view: "layers", options: (turn: true)) != draw(s, view: "layers"))
#assert(draw(s, view: "face", options: (turn: true, slices: true)) != draw(s, view: "face", options: (slices: true)))

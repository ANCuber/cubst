// Masks hide the right stickers and never un-hide anything.
#import "/src/state.typ": solved, face, keep-colors, hide-faces, hide-pieces, mask, sticker-pos
#import "/src/moves.typ": apply

#let s = solved()
#let hidden-count(c) = c.faces.values().flatten().filter(x => x == none).len()

#assert(hidden-count(keep-colors(s, "yellow")) == 45)
#assert(face(keep-colors(s, "yellow"), "U") == face(s, "U"))
#assert(hidden-count(hide-faces(s, ("U", "D"))) == 18)

// every piece carrying yellow: 4 corners (3 stickers), 4 edges (2), 1 center (1) = 21 stickers
#assert(hidden-count(hide-pieces(s, containing: "yellow")) == 21)
// the same count holds on a scrambled cube
#assert(hidden-count(hide-pieces(apply(s, "R U F' L2 D"), containing: "yellow")) == 21)

// stickers of one cubie share a coordinate: UFR corner
#assert(sticker-pos(3, "U", 2, 2) == sticker-pos(3, "F", 0, 2))
#assert(sticker-pos(3, "U", 2, 2) == sticker-pos(3, "R", 0, 0))
// and the DBL corner
#assert(sticker-pos(3, "D", 2, 0) == sticker-pos(3, "B", 2, 2))
#assert(sticker-pos(3, "D", 2, 0) == sticker-pos(3, "L", 2, 0))

// masks compose: keep yellow+green (36 hidden), then hide the green pieces
// (9 green stickers plus the 3 yellow stickers on the UF, UFL, UFR pieces)
#let m = hide-pieces(keep-colors(s, ("yellow", "green")), containing: "green")
#assert(hidden-count(m) == 48)
// a mask that keeps everything is the identity
#assert(mask(m, _ => true) == m)

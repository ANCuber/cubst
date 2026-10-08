// Masks hide the right stickers and never un-hide anything.
#import "/src/state.typ": solved, face, keep-colors, hide-faces, hide-pieces, mask, pieces
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

// stickers of one cubie share a piece id: UFR corner, DBL corner; a 3x3 has 26 pieces
#let ids = pieces(s)
#assert(ids.at("U:8") == ids.at("F:2") and ids.at("U:8") == ids.at("R:0"))
#assert(ids.at("D:6") == ids.at("B:8") and ids.at("D:6") == ids.at("L:6"))
#assert(ids.at("U:8") != ids.at("U:7"))
#assert(ids.values().dedup().len() == 26)

// masks compose: keep yellow+green (36 hidden), then hide the green pieces
// (9 green stickers plus the 3 yellow stickers on the UF, UFL, UFR pieces)
#let m = hide-pieces(keep-colors(s, ("yellow", "green")), containing: "green")
#assert(hidden-count(m) == 48)
// a mask that keeps everything is the identity
#assert(mask(m, _ => true) == m)

// the cube mask info carries row and col
#assert(hidden-count(mask(s, info => info.row == 0)) == 36)

// Every face turn moves the right strips to the right places, in the right order.
#import "/src/state.typ": solved, face, sticker, default-scheme as sc
#import "/src/moves.typ": apply

#let s = solved()
#let col(f, i) = f.map(row => row.at(i))
#let same(xs, c) = xs.all(x => x == c)

// U (clockwise from above): F→L→B→R→F
#let c = apply(s, "U")
#assert(same(face(c, "L").at(0), sc.F))
#assert(same(face(c, "B").at(0), sc.L))
#assert(same(face(c, "R").at(0), sc.B))
#assert(same(face(c, "F").at(0), sc.R))
#assert(face(c, "F").at(1) == (sc.F,) * 3 and face(c, "U") == ((sc.U,) * 3,) * 3)

// D (clockwise from below): F→R→B→L→F
#let c = apply(s, "D")
#assert(same(face(c, "R").at(2), sc.F))
#assert(same(face(c, "B").at(2), sc.R))
#assert(same(face(c, "L").at(2), sc.B))
#assert(same(face(c, "F").at(2), sc.L))

// R (clockwise from the right): F→U→B→D→F
#let c = apply(s, "R")
#assert(same(col(face(c, "U"), 2), sc.F))
#assert(same(col(face(c, "B"), 0), sc.U))
#assert(same(col(face(c, "D"), 2), sc.B))
#assert(same(col(face(c, "F"), 2), sc.D))

// L (clockwise from the left): U→F→D→B→U
#let c = apply(s, "L")
#assert(same(col(face(c, "F"), 0), sc.U))
#assert(same(col(face(c, "D"), 0), sc.F))
#assert(same(col(face(c, "B"), 2), sc.D))
#assert(same(col(face(c, "U"), 0), sc.B))

// F (clockwise from the front): U→R→D→L→U
#let c = apply(s, "F")
#assert(same(col(face(c, "R"), 0), sc.U))
#assert(same(face(c, "D").at(0), sc.R))
#assert(same(col(face(c, "L"), 2), sc.D))
#assert(same(face(c, "U").at(2), sc.L))

// B (clockwise from the back): U→L→D→R→U
#let c = apply(s, "B")
#assert(same(col(face(c, "L"), 0), sc.U))
#assert(same(face(c, "D").at(2), sc.L))
#assert(same(col(face(c, "R"), 2), sc.D))
#assert(same(face(c, "U").at(0), sc.R))

// Face rotation direction: after F the bottom row of U is L-colored;
// U then turns that row into U's left column.
#let c = apply(s, "F U")
#assert(same(col(face(c, "U"), 0), sc.L))
#assert(sticker(c, "U", 0, 2) == sc.U)

// Strip orientation across a reversed strip: the UFL cubie goes to UFR under F
// (its L sticker now faces up), then to UBR under R (that sticker now faces B).
#let c = apply(s, "F R")
#assert(col(face(c, "B"), 0) == (sc.L, sc.U, sc.U))

// Opposite-face rotation for the deepest layer: Lw' turns the L and M layers
// like R; the R face itself must stay fixed and the L face must turn as L'.
#let c = apply(s, "Lw'")
#assert(face(c, "R") == face(s, "R"))
#assert(face(c, "L") == face(apply(s, "L'"), "L"))

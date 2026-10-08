// Algebraic identities that hold on a real cube.
#import "/src/state.typ": solved, is-solved, face
#import "/src/moves.typ": apply, inverse, parse, to-string

#let s = solved()
#let after(alg) = apply(s, alg)

// four quarter turns, and a turn followed by its inverse
#for m in ("R", "L", "U", "D", "F", "B", "M", "E", "S", "x", "y", "z", "Rw", "r") {
  assert(is-solved(after(m * 4)), message: m + "^4 is not identity")
  assert(after(m + " " + m + "'") == s, message: m + " " + m + "' is not identity")
  assert(after(m + "2") == after(m + " " + m), message: m + "2 differs from " + m + " " + m)
}

// sexy move has order 6; the T-perm is an involution; Sune has order 6
#assert(is-solved(after("(R U R' U')6")))
#assert(is-solved(after("(R U R' U' R' F R2 U' R' U' R U R' F')2")))
#assert(is-solved(after("(R U R' U R U2 R')6")))
#assert(not is-solved(after("(R U R' U')3")))

// rotations are the composition of the face, slice and opposite-face turns
#assert(after("x") == after("R M' L'"))
#assert(after("y") == after("U E' D'"))
#assert(after("z") == after("F S B'"))
#assert(after("Rw") == after("R M'"))
#assert(after("Lw") == after("L M"))
#assert(after("Uw") == after("U E'"))
#assert(after("Fw") == after("F S"))
// the deepest layer includes the opposite face
#assert(after("3Rw") == after("x"))
#assert(after("3Uw'") == after("y'"))

// whole-cube rotations relabel faces
#let y = after("y")
#assert(face(y, "F") == face(s, "R") and face(y, "L") == face(s, "F"))
#let x = after("x")
#assert(face(x, "U") == face(s, "F") and face(x, "F") == face(s, "D"))

// inverse undoes, round trip through strings
#let alg = "R U2 R' U' (R U R' U')2 x M' 3Rw' y2"
#assert(apply(after(alg), inverse(alg)) == s)
#assert(to-string(parse(alg)) == "R U2 R' U' R U R' U' R U R' U' x M' 3Rw' y2")
#assert(to-string(inverse("R U R' U'")) == "U R U' R'")
#assert(to-string(parse("(R U)'")) == "U' R'")
#assert(to-string(parse("R'2 U2' f")) == "R2 U2 Fw")

// a 3x3 permutation of stickers keeps nine of each color
#let counts = after("R U R' U' F2 B D' L x y'").faces.values().flatten()
#for c in ("white", "yellow", "green", "blue", "red", "orange") {
  assert(counts.filter(x => x == c).len() == 9)
}

// size-generic: wide and slice moves on other sizes
#assert(is-solved(apply(solved(event: "2x2"), "(R U R' U')6")))
#assert(is-solved(apply(solved(event: "4x4"), "(3Rw U 3Rw' U')6")))
#assert(apply(solved(event: "5x5"), "x") == apply(solved(event: "5x5"), "R M' L'"))

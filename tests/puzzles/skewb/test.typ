// Skewb: WCA fixed-corner notation. R turns the DBR corner clockwise as seen
// from that corner, which carries the R centre to B, B to D and D to R; the
// UFR corner never moves.
#import "/src/lib.typ": *

#let s = cube(event: "skewb")
#let sc = s.scheme
#let after(alg) = apply(s, alg)
#let center(c, f) = sticker(c, f, 0)

#for m in ("R", "L", "U", "B") {
  assert(is-solved(after(m * 3)), message: m + "^3 is not identity")
  assert(after(m + " " + m + "'") == s)
  assert(after(m + "2") == after(m + "'"))
}

#let r = after("R")
#assert(center(r, "B") == sc.R and center(r, "D") == sc.B and center(r, "R") == sc.D)
#assert(center(r, "U") == sc.U and center(r, "F") == sc.F and center(r, "L") == sc.L)
// a move changes exactly 4 corners (12 stickers) and 3 centres: 15 stickers
#let changed(c) = c.faces.pairs().map(((f, st)) => st.filter(x => x != sc.at(f)).len()).sum()
#assert(changed(r) == 15)
// the UFR corner is the fixed reference: its three stickers never change
#for alg in ("R", "L", "U", "B", "R L U B R' L' U' B'") {
  let c = after(alg)
  assert(sticker(c, "U", 3) == sc.U and sticker(c, "F", 2) == sc.F and sticker(c, "R", 1) == sc.R)
}
// U turns the UBL corner: centres U → L → B → U
#let u = after("U")
#assert(center(u, "L") == sc.U and center(u, "B") == sc.L and center(u, "U") == sc.B)

// y rotates the whole puzzle a quarter turn, clockwise seen from above:
// F's stickers go to L, like a cube's U; nothing is left behind
#let y = after("y")
#assert(is-solved(after("y y y y")) and after("y y'") == s and after("y2") == after("y y"))
#assert(face(y, "L") == (sc.F,) * 5 and face(y, "B") == (sc.L,) * 5 and face(y, "R") == (sc.B,) * 5)
#assert(face(y, "U") == (sc.U,) * 5 and face(y, "D") == (sc.D,) * 5)
#assert(to-string(parse("y2 y' R", event: "skewb"), event: "skewb") == "y2 y' R")

// each colour keeps five stickers; corners group into pieces of three
#let scrambled = after("R L U B' R' L U2 B")
#for (f, col) in sc { assert(scrambled.faces.values().flatten().filter(x => x == col).len() == 5) }
#assert(hide-pieces(s, containing: sc.U).faces.values().flatten().filter(x => x == none).len() == 13)

// views
#assert(draw(s, view: "face", face: "U") != none)
#draw(s, view: "full")
#draw(s, view: "net")

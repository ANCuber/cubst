// Pyraminx: U turns the two layers at the top vertex clockwise as seen from
// above, carrying F's stickers to L, L's to R and R's to F; u turns the tip only.
#import "/src/lib.typ": *

#let s = cube(event: "pyraminx")
#let sc = s.scheme
#let after(alg) = apply(s, alg)

#for m in ("U", "L", "R", "B", "u", "l", "r", "b") {
  assert(is-solved(after(m * 3)), message: m + "^3 is not identity")
  assert(after(m + " " + m + "'") == s)
}

// U: the tip and the whole second row of F, L, R move; D is untouched
#let u = after("U")
#assert(face(u, "L").slice(0, 4) == (sc.F,) * 4)
#assert(face(u, "R").slice(0, 4) == (sc.L,) * 4)
#assert(face(u, "F").slice(0, 4) == (sc.R,) * 4)
#assert(face(u, "F").slice(4) == (sc.F,) * 5 and face(u, "D") == (sc.D,) * 9)
// u: only the three tip stickers
#let tip = after("u")
#assert(sticker(tip, "L", 0) == sc.F and sticker(tip, "L", 1) == sc.L)
#assert(tip.faces.values().flatten().zip(s.faces.values().flatten()).filter(((a, b)) => a != b).len() == 3)
// L turns the front-left vertex: the stickers at that corner of D move too
#let l = after("L")
#assert(face(l, "D") != face(s, "D") and sticker(l, "D", 0) == sc.D)

// rotations: y about the U vertex (F goes to L, like U), z about the F face
// centre, clockwise seen from the front (the U vertex goes to R, so the face
// opposite L lands opposite U)
#let y = after("y")
#assert(is-solved(after("y y y")) and after("y y'") == s and after("y2") == after("y'"))
// y agrees with U on the top two layers
#assert(face(after("y U'"), "F").slice(0, 4) == (sc.F,) * 4)
#assert(face(y, "L") == (sc.F,) * 9 and face(y, "R") == (sc.L,) * 9 and face(y, "F") == (sc.R,) * 9 and face(y, "D") == (sc.D,) * 9)
#let z = after("z")
#assert(is-solved(after("z z z")) and after("z z'") == s)
#assert(face(z, "F") == (sc.F,) * 9 and face(z, "D") == (sc.R,) * 9 and face(z, "L") == (sc.D,) * 9 and face(z, "R") == (sc.L,) * 9)
#assert(to-string(parse("y z' U", event: "pyraminx"), event: "pyraminx") == "y z' U")

// pieces touching F: 3 tips (3 stickers), 3 axial centres (3), 3 edges (2) = 24 stickers
#assert(hide-pieces(s, containing: sc.F).faces.values().flatten().filter(x => x == none).len() == 24)
// the tip at U is one piece of three stickers
#assert(hide-pieces(keep-colors(s, sc.F), containing: sc.F).faces.values().flatten().filter(x => x == none).len() == 36)

// every view the pyraminx supports, and an unsupported one
#draw(s, view: "face", face: "F")
#draw(s, view: "face", face: "D", sides: true)
#draw(s, view: "tip", tip: "U")
#draw(s, view: "tip", tip: "B")
#assert(draw(s, view: "tip") == draw(s, view: "tip", tip: "U"))
#draw(s, view: "full")
#draw(s, view: "net")

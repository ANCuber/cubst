// Megaminx: face turns are fifths; U carries F's top stickers to L; R++
// turns everything but L two fifths clockwise seen from the right.
#import "/src/lib.typ": *

#let s = cube(event: "megaminx")
#let sc = s.scheme
#let after(alg) = apply(s, alg)

#for m in ("U", "F", "R", "L", "BL", "BR", "DR", "DL", "DBR", "DBL", "B", "D") {
  assert(is-solved(after(m * 5)), message: m + "^5 is not identity")
  assert(after(m + " " + m + "'") == s)
  assert(after(m + "2'") == after(m + "'" + m + "'"))
}
#for m in ("R++", "R--", "D++", "D--") {
  assert(is-solved(after((m + " ") * 5)), message: m + "^5 is not identity")
}
#assert(after("R++ R--") == s and after("R++") == after("R-- R-- R-- R--"))

// U: F's edge on U (1, at the upper right) and its corners (6, 7) come from R;
// the centre stays
#let u = after("U")
#assert(sticker(u, "F", 1) == sc.R and sticker(u, "F", 6) == sc.R and sticker(u, "F", 7) == sc.R)
#assert(sticker(u, "F", 0) == sc.F and sticker(u, "F", 3) == sc.F)
#assert(sticker(u, "L", 1) == sc.F and sticker(u, "R", 1) == sc.BR)
#assert(face(u, "D") == face(s, "D"))
// a face turn changes 15 stickers on the neighbours and none on the face itself
#let changed(c) = c.faces.pairs().map(((f, st)) => st.filter(x => x != sc.at(f)).len()).sum()
#assert(changed(u) == 15)
// R++ leaves the L face alone and moves every other face's centre
#let r = after("R++")
#assert(face(r, "L") == face(s, "L"))
#assert(sticker(r, "U", 0) != sc.U and sticker(r, "F", 0) != sc.F)
// D++ leaves U alone
#assert(face(after("D++"), "U") == face(s, "U"))

// eleven stickers per colour, 62 pieces
#let scrambled = after("R++ D-- R-- D++ U F' BL2 DBR")
#for (f, col) in sc { assert(scrambled.faces.values().flatten().filter(x => x == col).len() == 11) }

// the cut option changes the geometry but not what moves do
#let narrow = cube(event: "megaminx", options: (cut: 0.33))
#assert(narrow.params.cut == 0.33 and s.params.cut == 0.4)
#assert(apply(narrow, "R++ D-- R-- D++ U F' BL2 DBR").faces == scrambled.faces)
#for m in ("U", "R++", "DBL") { assert(is-solved(apply(narrow, (m + " ") * 5))) }
#assert(apply(narrow, "U").faces == apply(s, "U").faces)
#assert(case("R U R' U'", event: "megaminx", options: (cut: 0.7)).faces == case("R U R' U'", event: "megaminx").faces)
#assert(draw(narrow, view: "face", face: "U", sides: true) != draw(s, view: "face", face: "U", sides: true))

// views
#draw(s, view: "face", face: "U", sides: true)
#draw(s, view: "net")

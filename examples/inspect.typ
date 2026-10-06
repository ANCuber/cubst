// Inspect the raw sticker data behind a diagram.
#import "/src/lib.typ": *
#set page(width: auto, height: auto, margin: 5mm)

#let show-faces(c) = {
  for f in ("U", "F", "R", "B", "L") {
    let rows = if f == "U" { face(c, f) } else { (face(c, f).at(0),) }
    [#f: #rows.map(repr).join(" / ") \ ]
  }
}

== case(T perm)
#show-faces(case("R U R' U' R' F R2 U' R' U' R U R' F'"))
#draw(case("R U R' U' R' F R2 U' R' U' R U R' F'"), view: "pll", sticker: 12mm)

== case(Sune)
#show-faces(case("R U R' U R U2 R'"))
#draw(case("R U R' U R U2 R'"), view: "oll", sticker: 12mm)

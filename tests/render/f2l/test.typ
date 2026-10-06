#import "/src/lib.typ": *
#set page(width: auto, height: auto, margin: 2mm)

// basic pair insert: last-layer pieces hidden
#draw(case("U R U' R'"), view: "f2l")
#h(4mm)
// a custom mask overrides the view's default
#draw(case("U R U' R'"), view: "f2l", mask: c => keep-colors(c, ("green", "orange", "white")))
#h(4mm)
// no mask at all
#draw(case("U R U' R'"), view: "f2l", mask: none)

#import "/src/lib.typ": *
#set page(width: auto, height: auto, margin: 2mm)

// Sune: oriented corner at UFL, side stickers on F-right, R-back, B-left
#draw(case("R U R' U R U2 R'"), view: "oll")
#h(4mm)
// dark style and a 2x2
#draw(case("R U R' U R U2 R'"), view: "oll", gap: 1pt, body: black, stroke: none, radius: 1pt)
#h(4mm)
#draw(case("R U R' U R U2 R'", event: "2x2"), view: "oll")

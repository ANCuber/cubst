#import "/src/lib.typ": *
#set page(width: auto, height: auto, margin: 2mm)

#let c = cube(scramble: "R U F2 D' L B'")
#draw(c, view: "full")
#h(4mm)
// turn the state to look at the other faces
#draw(apply(c, "y2"), view: "full")
#h(4mm)
// styling, and sizes other than 3
#draw(c, view: "full", gap: 1pt, stroke: none, body: black, sticker: 5mm)
#h(4mm)
#draw(cube(size: 2, scramble: "R U R' U'"), view: "full")
#h(4mm)
#draw(cube(size: 5, scramble: "3Rw U 3Rw' M2"), view: "full", sticker: 3.5mm)

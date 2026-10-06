#import "/src/lib.typ": *
#set page(width: auto, height: auto, margin: 2mm)

#draw(cube(scramble: "M2 E2 S2"), view: "net")
#h(4mm)
#draw(hide-faces(cube(scramble: "R U R' U'"), ("D", "B")), view: "net", gap: 1pt, body: black, stroke: none)

#import "/src/lib.typ": *
#set page(width: auto, height: auto, margin: 2mm)

#let c = cube(event: "skewb", scramble: "R L U B' R' L")
#draw(c, view: "full")
#h(4mm)
#draw(c, view: "face", face: "U", sides: true)
#h(4mm)
#draw(c, view: "face", face: "F", gap: 1pt, body: black, stroke: none)
#h(4mm)
#draw(c, view: "net", sticker: 4mm)

#import "/src/lib.typ": *
#set page(width: auto, height: auto, margin: 2mm)

#let c = cube(event: "square1", scramble: "(0,-1)/ (3,0)/ (-3,0)/ (1,-2)/")
#draw(c, view: "layers")
#h(4mm)
#draw(c, view: "obl")
#h(4mm)
#draw(c, view: "cs", options: (direction: "vertical"))
#h(4mm)
#draw(c, view: "face", sides: true, gap: 1pt, body: black, stroke: none)
#h(4mm)
#draw(c, view: "net", sticker: 4mm)

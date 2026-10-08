#import "/src/lib.typ": *
#set page(width: auto, height: auto, margin: 2mm)

#let c = cube(event: "megaminx", scramble: "R++ D-- R++ D++ U F' BL2")
#draw(c, view: "face", face: "U", sides: true)
#h(4mm)
#draw(c, view: "face", face: "F", gap: 1pt, body: black, stroke: none)
#h(4mm)
#draw(cube(event: "megaminx", scramble: "U"), view: "face", face: "F", sides: true, arrows: (((6, 10)),))
#linebreak()
#v(2mm)
#draw(c, view: "net", sticker: 3.5mm)

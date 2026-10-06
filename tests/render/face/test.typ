#import "/src/lib.typ": *
#set page(width: auto, height: auto, margin: 2mm)

// Every face of one scrambled cube seen straight on, with the net for
// cross-checking the strips around each face.
#let c = cube(scramble: "R U F2 D' L B' M E S")
#for f in ("U", "D", "F", "B", "R", "L") {
  draw(c, view: "face", face: f, sticker: 4mm)
  h(2mm)
}
#linebreak()
#v(2mm)
#draw(c, view: "net", sticker: 4mm)

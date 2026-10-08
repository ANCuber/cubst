// Skewb.
//
// Same six faces and frames as a cube (half-size 1.5). Each face has five
// stickers: index 0 is the centre diamond, 1–4 are the corner triangles
// clockwise from the top-left of the head-on picture.
//
// Notation (WCA fixed-corner notation): the puzzle is held with U, F and R
// visible and the UFR corner never moves. R, L, U and B turn the layer around
// the farthest visible bottom-right (DBR), bottom-left (DFL), upper (UBL) and
// hidden back (DBL) vertex, 120° clockwise as seen from that vertex.

#import "../geom.typ" as g
#import "../notation.typ"
#import "cube.typ": face-names, cube-faces, default-scheme

#let h = 1.5
#let corners = (U: (-1, 1, -1), R: (1, -1, -1), L: (-1, -1, 1), B: (-1, -1, -1))

#let the-model = {
  let faces = cube-faces(h)
  let stickers = ()
  for f in face-names {
    let fr = faces.at(f).frame
    let local = (
      ((0, -h), (h, 0), (0, h), (-h, 0)), // centre
      ((-h, -h), (0, -h), (-h, 0)), // top-left
      ((0, -h), (h, -h), (h, 0)), // top-right
      ((h, 0), (h, h), (0, h)), // bottom-right
      ((-h, 0), (0, h), (-h, h)), // bottom-left
    )
    for (i, poly) in local.enumerate() {
      stickers.push((face: f, index: i, poly: poly.map(q => g.from-local(fr, q))))
    }
  }
  // the eight corner halves
  let regions = ()
  for x in (-1, 1) {
    for y in (-1, 1) {
      for z in (-1, 1) { regions.push((axis: g.unit((x, y, z)), lo: 0, hi: 1e9)) }
    }
  }
  (faces: faces, stickers: stickers, regions: regions)
}

#let token = regex("^([RLUB])(2['’]|['’]2|2|['’])?")
#let make-move(caps) = {
  let (letter, suffix) = caps
  (
    base: letter,
    amount: notation.suffix-amount(suffix),
    order: 3,
    axis: g.unit(corners.at(letter)),
    step: -120deg,
    region: (0, 1e9),
    style: "",
    puzzle: "skewb",
  )
}

#let puzzle = (
  name: "skewb",
  event: name => if name == "skewb" { (:) } else { none },
  event-name: params => "skewb",
  faces: params => face-names,
  default-scheme: params => default-scheme,
  model: params => the-model,
  parse: (alg, params) => notation.scan(alg, token, make-move),
  format: m => m.base + notation.format-suffix(m.amount, 3),
  views: ("face", "full", "net"),
  cameras: params => (full: (dir: g.unit((1, 1, 1)), up: (0, 1, 0)), tips: (:)),
  net: params => (
    roots: ("F",),
    edges: (("F", "U"), ("F", "D"), ("F", "L"), ("F", "R"), ("R", "B")),
  ),
)

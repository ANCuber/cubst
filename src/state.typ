// Cube state model.
//
// A cube is a plain dictionary:
//   (kind: "cube", size: N, scheme: (U: .., D: .., ..), faces: (U: rows, D: rows, ..))
// Each face is an N×N array of rows; a sticker is a color *name* (a key into the
// palette used at draw time) or `none` for a hidden sticker.
//
// Face arrays follow the standard net: every face is viewed from outside with U
// above it, except U (viewed from above, B at the top) and D (viewed from below,
// F at the top).
//
//        U
//      L F R B
//        D
//
// Nothing in this file knows about moves or rendering.

#import "util.typ"

#let face-names = ("U", "D", "F", "B", "R", "L")
#let opposite = (U: "D", D: "U", F: "B", B: "F", R: "L", L: "R")

/// For every face, the neighbour that touches each side of its array
/// (top/bottom/left/right as the face is viewed, see the net above).
#let sides = (
  F: (top: "U", bottom: "D", left: "L", right: "R"),
  B: (top: "U", bottom: "D", left: "R", right: "L"),
  R: (top: "U", bottom: "D", left: "F", right: "B"),
  L: (top: "U", bottom: "D", left: "B", right: "F"),
  U: (top: "B", bottom: "F", left: "L", right: "R"),
  D: (top: "F", bottom: "B", left: "L", right: "R"),
)

/// Default color scheme: yellow on top, green in front (white-cross-on-bottom
/// orientation, standard Western color placement).
#let default-scheme = (U: "yellow", D: "white", F: "green", B: "blue", R: "orange", L: "red")

#let is-cube(x) = type(x) == dictionary and x.at("kind", default: none) == "cube"

#let assert-cube(x, who: "cubst") = {
  assert(
    is-cube(x),
    message: who + ": expected a cube (made with `cube()` or `case()`), got " + repr(x),
  )
}

/// A solved cube of the given size.
#let solved(size: 3, scheme: default-scheme) = {
  assert(
    type(size) == int and size >= 1,
    message: "cube size must be a positive integer, got " + repr(size),
  )
  for f in face-names {
    assert(f in scheme, message: "scheme is missing face " + f)
  }
  (
    kind: "cube",
    size: size,
    scheme: scheme,
    faces: face-names.map(f => (f, util.filled(size, scheme.at(f)))).to-dict(),
  )
}

/// The N×N sticker array of one face.
#let face(c, name) = {
  assert-cube(c, who: "face")
  assert(name in face-names, message: "unknown face " + repr(name))
  c.faces.at(name)
}

/// One sticker (color name or `none` when hidden). `row`/`col` are 0-based.
#let sticker(c, name, row, col) = face(c, name).at(row).at(col)

/// True when every face shows a single color.
#let is-solved(c) = {
  assert-cube(c, who: "is-solved")
  face-names.all(f => {
    let stickers = c.faces.at(f).flatten()
    stickers.all(s => s == stickers.first())
  })
}

/// 3D cubie coordinate (x, y, z) of a sticker, with x: L→R, y: D→U, z: B→F,
/// each in 0..size-1. Stickers of the same piece share a coordinate.
#let sticker-pos(size, name, row, col) = {
  let n = size - 1
  if name == "F" {
    (col, n - row, n)
  } else if name == "B" {
    (n - col, n - row, 0)
  } else if name == "R" {
    (n, n - row, n - col)
  } else if name == "L" {
    (0, n - row, col)
  } else if name == "U" {
    (col, n, row)
  } else if name == "D" {
    (col, 0, n - row)
  } else {
    panic("unknown face " + repr(name))
  }
}

/// Generic mask: keep stickers for which `keep(info)` is true, hide the rest.
/// `info` is `(face:, row:, col:, color:, pos:)`.
#let mask(c, keep) = {
  assert-cube(c, who: "mask")
  let out = c
  for f in face-names {
    for r in range(c.size) {
      for col in range(c.size) {
        let color = c.faces.at(f).at(r).at(col)
        let info = (face: f, row: r, col: col, color: color, pos: sticker-pos(c.size, f, r, col))
        if color != none and not keep(info) { out.faces.at(f).at(r).at(col) = none }
      }
    }
  }
  out
}

/// Keep only stickers whose color name is in `colors` (a string or array of strings).
#let keep-colors(c, colors) = {
  let colors = if type(colors) == str { (colors,) } else { colors }
  mask(c, info => info.color in colors)
}

/// Hide stickers of the given faces entirely.
#let hide-faces(c, faces) = {
  let faces = if type(faces) == str { (faces,) } else { faces }
  mask(c, info => info.face not in faces)
}

/// Hide every sticker of every piece that carries at least one sticker of the
/// given color(s). Used for F2L diagrams (hide the last-layer pieces).
#let hide-pieces(c, containing: none) = {
  assert-cube(c, who: "hide-pieces")
  let colors = if type(containing) == str { (containing,) } else { containing }
  let marked = ()
  for f in face-names {
    for r in range(c.size) {
      for col in range(c.size) {
        if c.faces.at(f).at(r).at(col) in colors { marked.push(sticker-pos(c.size, f, r, col)) }
      }
    }
  }
  mask(c, info => info.pos not in marked)
}

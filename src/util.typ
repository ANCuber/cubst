// Small shared helpers: square-array rotation and strip access.

/// Rotate a square array (array of rows) 90° clockwise.
#let rotate-cw(m) = {
  let n = m.len()
  range(n).map(r => range(n).map(c => m.at(n - 1 - c).at(r)))
}

/// Rotate a square array by `k` quarter turns clockwise (negative = counter-clockwise).
#let rotate-times(m, k) = {
  let out = m
  for _ in range(calc.rem-euclid(k, 4)) { out = rotate-cw(out) }
  out
}

/// Read the line of stickers at depth `k` from `side` ("top", "bottom", "left", "right").
/// Rows are read left→right, columns top→bottom.
#let get-strip(face, side, k) = {
  let n = face.len()
  if side == "top" {
    face.at(k)
  } else if side == "bottom" {
    face.at(n - 1 - k)
  } else if side == "left" {
    face.map(row => row.at(k))
  } else if side == "right" {
    face.map(row => row.at(n - 1 - k))
  } else {
    panic("unknown side: " + repr(side))
  }
}

/// Write `values` back into the line described by (`side`, `k`); see `get-strip`.
#let set-strip(face, side, k, values) = {
  let n = face.len()
  let out = face
  if side == "top" {
    out.at(k) = values
  } else if side == "bottom" {
    out.at(n - 1 - k) = values
  } else if side == "left" {
    for r in range(n) { out.at(r).at(k) = values.at(r) }
  } else if side == "right" {
    for r in range(n) { out.at(r).at(n - 1 - k) = values.at(r) }
  } else {
    panic("unknown side: " + repr(side))
  }
  out
}

/// Build an n×n array filled with `value`.
#let filled(n, value) = range(n).map(_ => range(n).map(_ => value))

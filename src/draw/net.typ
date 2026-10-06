// Unfolded net renderer (all six faces). Pure Typst.
//
//        U
//      L F R B
//        D

#import "../state.typ": assert-cube
#import "common.typ": default-palette, fill-of, abs-pt

#let layout = (U: (1, 0), L: (0, 1), F: (1, 1), R: (2, 1), B: (3, 1), D: (1, 2))

/// Draw the net of a cube. `spacing` is the distance between faces (`auto` = a
/// quarter sticker).
#let draw-net(
  c,
  sticker: 6mm,
  gap: 0pt,
  spacing: auto,
  stroke: 0.5pt + black,
  radius: 0pt,
  palette: default-palette,
  hidden: auto,
  body: none,
) = {
  assert-cube(c, who: "draw-net")
  let n = c.size
  let s = abs-pt(sticker, "sticker")
  let g = abs-pt(gap, "gap")
  let sp = if spacing == auto { s * 0.25 } else { abs-pt(spacing, "spacing") }
  let p = s + g
  let fs = n * p - g
  let cell(x, y, name) = place(
    top + left,
    dx: x * 1pt,
    dy: y * 1pt,
    rect(width: s * 1pt, height: s * 1pt, fill: fill-of(name, palette, hidden), stroke: stroke, radius: radius),
  )
  box(width: (4 * fs + 3 * sp) * 1pt, height: (3 * fs + 2 * sp) * 1pt, {
    for (name, (fx, fy)) in layout {
      let x0 = fx * (fs + sp)
      let y0 = fy * (fs + sp)
      place(top + left, dx: x0 * 1pt, dy: y0 * 1pt, rect(width: fs * 1pt, height: fs * 1pt, fill: body, stroke: none))
      for r in range(n) {
        for col in range(n) { cell(x0 + col * p, y0 + r * p, c.faces.at(name).at(r).at(col)) }
      }
    }
  })
}

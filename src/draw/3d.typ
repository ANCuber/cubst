// 3D isometric renderer built on CeTZ. Shows the U, F and R faces.
//
// To look at other faces, rotate the *state* (e.g. `apply(c, "y")`) rather than
// the camera: the model already knows how to do that, and it keeps this
// renderer to a single fixed projection.

#import "../deps.typ": cetz
#import "../state.typ": assert-cube
#import "common.typ": default-palette, fill-of, abs-pt

/// Draw a cube in 3D.
///
/// - `sticker`: edge length of one sticker (absolute length).
/// - `gap`: space between stickers, shown in `body` color.
/// - `body`: color of the cube body behind the stickers (`none` = not drawn).
#let draw-3d(
  c,
  sticker: 6mm,
  gap: 0pt,
  stroke: 0.5pt + black,
  palette: default-palette,
  hidden: auto,
  body: none,
) = {
  assert-cube(c, who: "draw-3d")
  let n = c.size
  let s = abs-pt(sticker, "sticker")
  let inset = abs-pt(gap, "gap") / s / 2

  // isometric projection: x to the lower right, z (towards the viewer) to the lower left
  let (cs, sn) = (calc.cos(30deg), calc.sin(30deg))
  let proj((x, y, z)) = ((x - z) * cs, y - (x + z) * sn)

  // boxed so the result is inline like the other views
  box(cetz.canvas(length: sticker, {
    import cetz.draw: line
    let quad(pts, fill) = line(..pts.map(proj), close: true, fill: fill, stroke: stroke)

    // body, visible through the gaps
    if body != none {
      let solid(pts) = line(..pts.map(proj), close: true, fill: body, stroke: none)
      solid(((0, n, 0), (n, n, 0), (n, n, n), (0, n, n)))
      solid(((0, 0, n), (n, 0, n), (n, n, n), (0, n, n)))
      solid(((n, 0, n), (n, 0, 0), (n, n, 0), (n, n, n)))
    }

    let (i0, i1) = (inset, 1 - inset)
    for r in range(n) {
      for col in range(n) {
        // U: x = col, z = row (row 0 is next to B)
        quad(
          ((col + i0, n, r + i0), (col + i1, n, r + i0), (col + i1, n, r + i1), (col + i0, n, r + i1)),
          fill-of(c.faces.U.at(r).at(col), palette, hidden),
        )
        // F: x = col, y counts down from the top row
        let y = n - 1 - r
        quad(
          ((col + i0, y + i0, n), (col + i1, y + i0, n), (col + i1, y + i1, n), (col + i0, y + i1, n)),
          fill-of(c.faces.F.at(r).at(col), palette, hidden),
        )
        // R: column 0 touches F (z = n), so z counts down with the column
        let z = n - 1 - col
        quad(
          ((n, y + i0, z + i1), (n, y + i0, z + i0), (n, y + i1, z + i0), (n, y + i1, z + i1)),
          fill-of(c.faces.R.at(r).at(col), palette, hidden),
        )
      }
    }
  }))
}

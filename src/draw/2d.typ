// Straight-on renderer: one face seen head-on, with the adjacent row of each
// neighbouring face drawn as a thin strip around it. With `face: "U"` this is
// the usual OLL/PLL diagram. Pure Typst.

#import "../util.typ"
#import "../state.typ": assert-cube, sides
#import "common.typ": default-palette, fill-of, abs-pt

/// Draw one face of a cube head-on.
///
/// - `face`: which face to look at (`"U"`, `"D"`, `"F"`, `"B"`, `"R"`, `"L"`).
/// - `sticker`: side length of one sticker (absolute length).
/// - `gap`: space between stickers (shows `body` through it).
/// - `side`: thickness of the side strips as a fraction of `sticker`.
/// - `margin`: distance between the face and the side strips (`auto` = small).
/// - `arrows`: array of arrows on the face. Each is `((row, col), (row, col))`
///   or `(from: (row, col), to: (row, col), double: bool, color: color)`.
#let draw-face(
  c,
  face: "U",
  sticker: 6mm,
  gap: 0pt,
  side: 0.35,
  margin: auto,
  stroke: 0.5pt + black,
  radius: 0pt,
  palette: default-palette,
  hidden: auto,
  body: none,
  arrows: (),
  arrow-color: black,
  arrow-thickness: 1.6pt,
  arrow-head: 0.3,
) = {
  assert-cube(c, who: "draw-face")
  assert(face in sides, message: "cubst: unknown face " + repr(face) + "; expected one of U, D, F, B, R, L")
  let n = c.size
  let s = abs-pt(sticker, "sticker")
  let g = abs-pt(gap, "gap")
  let t = s * side
  let m = if margin == auto { calc.max(g, s * 0.12) } else { abs-pt(margin, "margin") }
  let p = s + g
  let grid = n * p - g
  let off = t + m
  let total = grid + 2 * off

  // The row of the neighbour on side `s` of `face`, ordered so that it reads
  // left→right (for top/bottom) or top→bottom (for left/right) as drawn here.
  let strip(s) = {
    let nb = sides.at(face).at(s)
    let touching = sides.at(nb).pairs().find(p => p.at(1) == face).at(0)
    let values = util.get-strip(c.faces.at(nb), touching, 0)
    // where the neighbour's row naturally starts, and where it must start here
    let natural = if touching in ("top", "bottom") { sides.at(nb).left } else { sides.at(nb).top }
    let wanted = if s in ("top", "bottom") { sides.at(face).left } else { sides.at(face).top }
    if natural == wanted { values } else { values.rev() }
  }

  let cell(x, y, w, h, name) = place(
    top + left,
    dx: x * 1pt,
    dy: y * 1pt,
    rect(width: w * 1pt, height: h * 1pt, fill: fill-of(name, palette, hidden), stroke: stroke, radius: radius),
  )
  let center(pos) = (off + pos.at(1) * p + s / 2, off + pos.at(0) * p + s / 2)

  let arrow(a) = {
    let a = if type(a) == array { (from: a.at(0), to: a.at(1)) } else { a }
    let color = a.at("color", default: arrow-color)
    let (x1, y1) = center(a.from)
    let (x2, y2) = center(a.to)
    let (dx, dy) = (x2 - x1, y2 - y1)
    let len = calc.sqrt(dx * dx + dy * dy)
    assert(len > 0, message: "cubst: arrow from and to must differ")
    let (ux, uy) = (dx / len, dy / len)
    let h = arrow-head * s
    let w = h * 0.5
    let head(tx, ty, ux, uy) = place(
      top + left,
      polygon(
        fill: color,
        stroke: none,
        (tx * 1pt, ty * 1pt),
        ((tx - h * ux + w * uy) * 1pt, (ty - h * uy - w * ux) * 1pt),
        ((tx - h * ux - w * uy) * 1pt, (ty - h * uy + w * ux) * 1pt),
      ),
    )
    let double = a.at("double", default: false)
    let (sx, sy) = if double { (x1 + 0.7 * h * ux, y1 + 0.7 * h * uy) } else { (x1, y1) }
    let (ex, ey) = (x2 - 0.7 * h * ux, y2 - 0.7 * h * uy)
    place(
      top + left,
      line(start: (sx * 1pt, sy * 1pt), end: (ex * 1pt, ey * 1pt), stroke: arrow-thickness + color),
    )
    head(x2, y2, ux, uy)
    if double { head(x1, y1, -ux, -uy) }
  }

  let rows = c.faces.at(face)
  let (above, below, left, right) = (strip("top"), strip("bottom"), strip("left"), strip("right"))
  box(width: total * 1pt, height: total * 1pt, fill: body, radius: radius, {
    for r in range(n) {
      for col in range(n) { cell(off + col * p, off + r * p, s, s, rows.at(r).at(col)) }
    }
    for i in range(n) {
      cell(off + i * p, 0, s, t, above.at(i))
      cell(off + i * p, off + grid + m, s, t, below.at(i))
      cell(0, off + i * p, t, s, left.at(i))
      cell(off + grid + m, off + i * p, t, s, right.at(i))
    }
    for a in arrows { arrow(a) }
  })
}

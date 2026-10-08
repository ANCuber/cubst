// Straight-on renderer: one face seen head-on, optionally with the stickers
// of the neighbouring faces that touch it drawn as thin strips around it.
// With `face: "U"` on a cube this is the usual OLL/PLL diagram. Pure Typst,
// and generic: the face's stickers come from the puzzle model.

#import "../geom.typ" as g
#import "../state.typ": assert-puzzle, assert-face, index-of
#import "../puzzles/registry.typ" as registry
#import "common.typ": default-palette, fill-of, abs-pt, shape, arrow

/// Draw one face of a puzzle head-on.
///
/// - `face`: which face to look at (`auto` = the puzzle's first face, `U` on
///   every puzzle but the pyraminx, where it is `F`).
/// - `sides`: whether to draw the neighbouring stickers that touch the face
///   as strips around it.
/// - `sticker`: length of one unit (one cube sticker edge; absolute length).
/// - `gap`: space between stickers (shows `body` through it).
/// - `side`: thickness of the side strips as a fraction of a unit.
/// - `margin`: distance between the face and the side strips (`auto` = small).
/// - `arrows`: array of arrows on the face. Each is `(from, to)` or
///   `(from:, to:, double: bool, color: color)`, where a position is a sticker
///   index, or `(row, col)` on a cube.
/// - `labels`: write each sticker's index on it (for finding positions).
#let draw-face(
  c,
  face: auto,
  sides: true,
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
  labels: false,
) = {
  assert-puzzle(c, who: "draw-face")
  let face = if face == auto { (registry.of(c).faces)(c.params).first() } else { face }
  assert-face(c, face, who: "draw-face")
  let model = registry.model(c)
  let fr = model.faces.at(face).frame
  let s = abs-pt(sticker, "sticker")
  let gp = abs-pt(gap, "gap") / s

  // (polygon in face units, color name)
  let shapes = ()
  let own = (:)
  for st in model.stickers.filter(st => st.face == face) {
    let poly = st.poly.map(p => g.to-local(fr, p))
    own.insert(str(st.index), poly)
    shapes.push((poly: g.inset(poly, gp), name: c.faces.at(face).at(st.index)))
  }

  if sides {
    let m = if margin == auto { calc.max(gp, 0.12) } else { abs-pt(margin, "margin") / s }
    let n = fr.normal
    let plane = g.dot(model.faces.at(face).verts.first(), n)
    for st in model.stickers.filter(st => st.face != face) {
      // stickers with an edge on this face's plane touch the face
      let on-plane = st.poly.filter(p => calc.abs(g.dot(p, n) - plane) < 1e-6).map(p => g.to-local(fr, p))
      if on-plane.len() < 2 { continue }
      let dir = g.unit2(g.sub2(on-plane.last(), on-plane.first()))
      let along = on-plane.sorted(key: p => g.dot2(p, dir))
      let (a, b) = (along.first(), along.last())
      let out = (-dir.at(1), dir.at(0))
      if g.dot2(out, g.centroid2((a, b))) < 0 { out = g.scale2(out, -1) }
      let poly = (
        g.add2(a, g.scale2(out, m)),
        g.add2(b, g.scale2(out, m)),
        g.add2(b, g.scale2(out, m + side)),
        g.add2(a, g.scale2(out, m + side)),
      )
      shapes.push((poly: g.inset(poly, gp), name: c.faces.at(st.face).at(st.index)))
    }
  }

  let (min, max) = g.bbox(shapes.map(sh => sh.poly).flatten().chunks(2))
  let to-pt(p) = ((p.at(0) - min.at(0)) * s, (p.at(1) - min.at(1)) * s)
  let center(pos) = to-pt(g.centroid2(own.at(str(index-of(c, face, pos)))))

  box(width: (max.at(0) - min.at(0)) * s * 1pt, height: (max.at(1) - min.at(1)) * s * 1pt, fill: body, radius: radius, {
    for sh in shapes { shape(sh.poly.map(to-pt), fill-of(sh.name, palette, hidden), stroke, radius) }
    for a in arrows {
      let a = if type(a) == array { (from: a.at(0), to: a.at(1)) } else { a }
      arrow(
        center(a.from),
        center(a.to),
        arrow-head * s,
        a.at("color", default: arrow-color),
        arrow-thickness,
        double: a.at("double", default: false),
      )
    }
    if labels {
      for (i, poly) in own {
        let (x, y) = to-pt(g.centroid2(poly))
        place(
          top + left,
          dx: (x - s / 2) * 1pt,
          dy: (y - s / 2) * 1pt,
          box(width: s * 1pt, height: s * 1pt, align(std.center + horizon, text(size: 0.38 * s * 1pt, i))),
        )
      }
    }
  })
}

// The drawing API (API 2): one `draw` function that dispatches on `view`.
//
// A view = a renderer kind + a default mask (+ a fixed face or camera). All
// appearance options live here, with one default each, so they mean the same
// thing in every view. Options that only make sense for one kind of picture
// are ignored by the others. Each puzzle lists which views it supports;
// asking for another one is an error.

#import "../state.typ": assert-puzzle, keep-colors, hide-pieces
#import "../puzzles/registry.typ" as registry
#import "common.typ": default-palette
#import "2d.typ": draw-face
#import "net.typ": draw-net
#import "3d.typ": draw-3d

// The generic views, one per renderer kind. Every other view is one of these
// with something fixed: `pll` is `face` looking at U with its side strips,
// `oll` is `pll` plus a mask, `f2l` is `full` plus a mask, `tip` is a 3D view
// from a pyraminx tip.
//
// `face: auto` means "take the `face:` option"; `sides` is the view's default
// for the `sides:` option, which the caller can still override.
#let face-view = (kind: "face", face: auto, sides: false, mask: none)
#let full-view = (kind: "3d", camera: "full", mask: none)
#let net-view = (kind: "net", mask: none)

#let views = (
  face: face-view,
  pll: (..face-view, face: "U", sides: true),
  oll: (..face-view, face: "U", sides: true, mask: c => keep-colors(c, c.scheme.U)),
  full: full-view,
  f2l: (..full-view, mask: c => hide-pieces(c, containing: c.scheme.U)),
  tip: (..full-view, camera: "tip"),
  net: net-view,
)

#let renderers = (
  face: (c, o) => draw-face(
    c,
    face: o.face,
    sides: o.sides,
    sticker: o.sticker,
    gap: o.gap,
    stroke: o.stroke,
    radius: o.radius,
    body: o.body,
    palette: o.palette,
    hidden: o.hidden,
    side: o.side,
    arrows: o.arrows,
    arrow-color: o.arrow-color,
    arrow-thickness: o.arrow-thickness,
    arrow-head: o.arrow-head,
    labels: o.labels,
  ),
  "3d": (c, o) => draw-3d(
    c,
    camera: o.camera,
    sticker: o.sticker,
    gap: o.gap,
    stroke: o.stroke,
    body: o.body,
    palette: o.palette,
    hidden: o.hidden,
  ),
  net: (c, o) => draw-net(
    c,
    sticker: o.sticker,
    gap: o.gap,
    stroke: o.stroke,
    radius: o.radius,
    body: o.body,
    palette: o.palette,
    hidden: o.hidden,
    spacing: o.spacing,
  ),
)

/// Draw a puzzle.
///
/// - `view`: `"face"`, `"pll"`, `"oll"`, `"full"`, `"f2l"`, `"tip"` or
///   `"net"`; each puzzle supports a subset. A view already decides which
///   stickers are hidden (its default mask).
/// - `mask`: `auto` keeps the view's default mask; `none` shows every sticker;
///   a function `state => state` (e.g. `c => keep-colors(c, "yellow")`) replaces it.
///
/// Appearance, identical for every view:
/// - `sticker`: length of one unit, i.e. one cube sticker edge (absolute length).
/// - `gap`: space between stickers; `body` shows through it.
/// - `stroke`, `radius`: sticker outline and corner radius (radius only on square stickers).
/// - `body`: color behind the stickers (`none` = transparent).
/// - `palette`: color name → color. `hidden`: color of masked stickers
///   (`auto` = the palette's `hidden` entry).
///
/// Only used by the straight-on views:
/// - `face`: which face the `"face"` view looks at (`oll`/`pll` always use `U`);
///   `auto` = the puzzle's first face (`U`, or `F` on the pyraminx).
/// - `sides`: whether to draw the neighbouring stickers as strips around it.
///   `auto` = the view's default: off for `face`, on for `pll` and `oll`.
/// - `side`: thickness of the side strips as a fraction of a unit.
/// - `arrows`, `arrow-color`, `arrow-thickness`, `arrow-head`: arrows between
///   sticker positions on the shown face.
/// - `labels`: write each sticker's index on it.
///
/// Only used by the `tip` view (pyraminx): `tip`, which vertex to look from.
/// Only used by the net view: `spacing`, the distance between faces.
#let draw(
  c,
  view: "full",
  mask: auto,
  face: auto,
  tip: "U",
  sides: auto,
  sticker: 6mm,
  gap: 0pt,
  stroke: 0.5pt + black,
  radius: 0pt,
  body: none,
  palette: default-palette,
  hidden: auto,
  side: 0.35,
  arrows: (),
  arrow-color: black,
  arrow-thickness: 1.6pt,
  arrow-head: 0.3,
  labels: false,
  spacing: auto,
) = {
  assert-puzzle(c, who: "draw")
  assert(
    view in views,
    message: "cubst: unknown view " + repr(view) + "; expected one of " + views.keys().map(repr).join(", "),
  )
  let p = registry.of(c)
  assert(
    view in p.views,
    message: "cubst: view " + repr(view) + " is not available for a " + c.event + "; it supports " + p.views.map(repr).join(", "),
  )
  let v = views.at(view)
  let m = if mask == auto { v.mask } else { mask }
  assert(
    m == none or type(m) == function,
    message: "cubst: mask must be auto, none or a function state => state, got " + repr(mask),
  )
  let shown = if m == none { c } else { m(c) }

  let fixed-face = v.at("face", default: auto)
  let camera = if v.kind != "3d" { none } else {
    let cams = (p.cameras)(c.params)
    if v.camera == "full" { cams.full } else {
      assert(
        tip in cams.tips,
        message: "cubst: unknown tip " + repr(tip) + " for a " + c.event + "; tips are " + cams.tips.keys().join(", "),
      )
      cams.tips.at(tip)
    }
  }
  let options = (
    face: if fixed-face == auto { face } else { fixed-face },
    sides: if sides == auto { v.at("sides", default: true) } else { sides },
    camera: camera,
    sticker: sticker,
    gap: gap,
    stroke: stroke,
    radius: radius,
    body: body,
    palette: palette,
    hidden: hidden,
    side: side,
    arrows: arrows,
    arrow-color: arrow-color,
    arrow-thickness: arrow-thickness,
    arrow-head: arrow-head,
    labels: labels,
    spacing: spacing,
  )
  (renderers.at(v.kind))(shown, options)
}

// The drawing API (API 2): one `draw` function that dispatches on `view`.
//
// A view = a renderer kind + a default mask (+ a fixed face for the
// straight-on kind). All appearance options live here, with one default each,
// so they mean the same thing in every view. Options that only make sense for
// one kind of picture are ignored by the others.

#import "../state.typ": assert-cube, keep-colors, hide-pieces
#import "common.typ": default-palette
#import "2d.typ": draw-face
#import "net.typ": draw-net
#import "3d.typ": draw-3d

// The three generic views. Every other view is one of these with something
// fixed: `pll` is `face` looking at U with its side strips, `oll` is `pll`
// plus a mask, `f2l` is `full` plus a mask.
//
// `face: auto` means "take the `face:` option"; `sides` is the view's default
// for the `sides:` option, which the caller can still override.
#let face-view = (kind: "face", face: auto, sides: false, mask: none)
#let full-view = (kind: "3d", mask: none)
#let net-view = (kind: "net", mask: none)

#let views = (
  face: face-view,
  pll: (..face-view, face: "U", sides: true),
  oll: (..face-view, face: "U", sides: true, mask: c => keep-colors(c, c.scheme.U)),
  full: full-view,
  f2l: (..full-view, mask: c => hide-pieces(c, containing: c.scheme.U)),
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
  ),
  "3d": (c, o) => draw-3d(
    c,
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

/// Draw a cube.
///
/// - `view`: `"oll"`, `"pll"`, `"face"`, `"f2l"`, `"full"` or `"net"`. A view
///   already decides which stickers are hidden (its default mask).
/// - `mask`: `auto` keeps the view's default mask; `none` shows every sticker;
///   a function `cube => cube` (e.g. `c => keep-colors(c, "yellow")`) replaces it.
///
/// Appearance, identical for every view:
/// - `sticker`: side of one sticker (absolute length).
/// - `gap`: space between stickers; `body` shows through it.
/// - `stroke`, `radius`: sticker outline and corner radius (no radius in 3D).
/// - `body`: color behind the stickers (`none` = transparent).
/// - `palette`: color name → color. `hidden`: color of masked stickers
///   (`auto` = the palette's `hidden` entry).
///
/// Only used by the straight-on views:
/// - `face`: which face the `"face"` view looks at (`oll`/`pll` always use `U`).
/// - `sides`: whether to draw the strips of the neighbouring faces around it.
///   `auto` = the view's default: off for `face`, on for `pll` and `oll`.
/// - `side`: thickness of the side strips as a fraction of a sticker.
/// - `arrows`, `arrow-color`, `arrow-thickness`, `arrow-head`: arrows between
///   `(row, col)` positions on the shown face.
///
/// Only used by the net view:
/// - `spacing`: distance between faces (`auto` = a quarter sticker).
#let draw(
  c,
  view: "full",
  mask: auto,
  face: "U",
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
  spacing: auto,
) = {
  assert-cube(c, who: "draw")
  assert(
    view in views,
    message: "cubst: unknown view " + repr(view) + "; expected one of " + views.keys().map(repr).join(", "),
  )
  let v = views.at(view)
  let m = if mask == auto { v.mask } else { mask }
  assert(
    m == none or type(m) == function,
    message: "cubst: mask must be auto, none or a function cube => cube, got " + repr(mask),
  )
  let shown = if m == none { c } else { m(c) }
  let fixed-face = v.at("face", default: auto)
  let options = (
    face: if fixed-face == auto { face } else { fixed-face },
    sides: if sides == auto { v.at("sides", default: true) } else { sides },
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
    spacing: spacing,
  )
  (renderers.at(v.kind))(shown, options)
}

// 3D renderer built on CeTZ: an orthographic view of the puzzle from a
// camera direction, drawing the faces that point towards the camera. The
// puzzle supplies the cameras (one for the `full` view, one per tip for the
// pyraminx); other faces are shown by rotating the *state*.

#import "../deps.typ": cetz
#import "../geom.typ" as g
#import "../state.typ": assert-puzzle
#import "../puzzles/registry.typ" as registry
#import "common.typ": default-palette, fill-of, abs-pt

// A unit edge along the camera's up direction is drawn this long (the usual
// isometric drawing scale).
#let view-scale = calc.sqrt(1.5)

/// Draw a puzzle in 3D.
///
/// - `camera`: `(dir:, up:)`, the direction from the puzzle towards the viewer
///   and which way is up; `auto` = the puzzle's `full` camera.
/// - `sticker`: length of one unit (absolute length).
/// - `gap`: space between stickers, shown in `body` color.
/// - `body`: color of the puzzle body behind the stickers (`none` = not drawn).
#let draw-3d(
  c,
  camera: auto,
  sticker: 6mm,
  gap: 0pt,
  stroke: 0.5pt + black,
  palette: default-palette,
  hidden: auto,
  body: none,
) = {
  assert-puzzle(c, who: "draw-3d")
  let model = registry.model(c)
  let camera = if camera == auto { (registry.of(c).cameras)(c.params).full } else { camera }
  assert(camera != none, message: "cubst: the " + c.event + " has no 3D view")
  let s = abs-pt(sticker, "sticker")
  let gp = abs-pt(gap, "gap") / s

  let zs = g.unit(camera.dir)
  let ys = g.unit(g.project-onto-plane(camera.up, zs))
  let xs = g.cross(ys, zs)
  let proj(p) = (g.dot(p, xs) * view-scale, g.dot(p, ys) * view-scale)
  let visible = model.faces.pairs().filter(((name, f)) => g.dot(f.normal, zs) > 1e-6).map(((name, f)) => name)
  assert(visible.len() > 0, message: "cubst: the camera sees no face")

  box(cetz.canvas(length: sticker, {
    import cetz.draw: line
    for name in visible {
      let f = model.faces.at(name)
      if body != none { line(..f.verts.map(proj), close: true, fill: body, stroke: none) }
      for st in model.stickers.filter(st => st.face == name) {
        // inset in the face plane, then back to 3D and onto the screen
        let poly = g.inset(st.poly.map(p => g.to-local(f.frame, p)), gp).map(q => g.from-local(f.frame, q))
        line(..poly.map(proj), close: true, fill: fill-of(c.faces.at(name).at(st.index), palette, hidden), stroke: stroke)
      }
    }
  }))
}

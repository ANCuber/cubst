# cubst developer guide

This document explains how the package is put together, the conventions every
module relies on, and how to extend or release it. The user-facing manual is
`docs/manual.typ`.

## 1. Architecture

```
            API 1 (build)                            API 2 (draw)
  ┌──────────────────────────┐            ┌───────────────────────────────┐
  │ cube.typ   cube(), case()│            │ draw/views.typ   draw()       │
  └────────────┬─────────────┘            │  views: name → (kind, mask,   │
               │                          │          fixed face/camera)   │
  ┌────────────▼─────────────┐            │  per-puzzle availability      │
  │ moves.typ  parse, apply, │            └────┬──────────┬─────────┬─────┘
  │            inverse       │                 │          │         │
  └────────────┬─────────────┘             2d.typ     3d.typ    net.typ
               │                          (face)     (CeTZ)    (unfold)
  ┌────────────▼─────────────┐                 │          │         │
  │ state.typ  solved, face, │            draw/common.typ (palette, shapes)
  │   masks, pieces          │
  └────────────┬─────────────┘
               │
  ┌────────────▼─────────────────────────────────────────────────────────┐
  │ puzzles/registry.typ   event name → puzzle                            │
  │ puzzles/cube.typ  skewb.typ  pyraminx.typ  megaminx.typ               │
  │   each: 3D model (faces, sticker polygons, turning regions),          │
  │         notation (parse/format), cameras, net tree, allowed views     │
  └────────────┬─────────────────────────────────────────────────────────┘
               │
        geom.typ (vectors, rotation, frames, 2D clipping)   notation.typ (scanner)
```

Dependencies only point downwards. The puzzles know nothing about states,
moves or drawing: they describe *geometry and notation* and nothing else.
`state.typ` and `moves.typ` are generic over that description; so are the
three renderers. `lib.typ` is re-exports only.

| File | Responsibility |
| --- | --- |
| `src/geom.typ` | 3D/2D vector maths, rotation, face frames, polygon clipping/inset |
| `src/notation.typ` | the algorithm scanner (tokens, groups) and suffix formatting |
| `src/puzzles/registry.typ` | the puzzle list; `resolve(event)`, `of(state)`, `model(state)` |
| `src/puzzles/*.typ` | one puzzle each: model, notation, cameras, net, views, hooks |
| `src/state.typ` | the state dictionary, accessors, piece identification, masks |
| `src/moves.typ` | `parse`, `inverse`, `to-string`, the move engine (`apply`) |
| `src/cube.typ` | `cube()` and `case()` constructors |
| `src/draw/common.typ` | palette lookup, length check, shape and arrow drawing |
| `src/draw/2d.typ` | straight-on renderer (`draw-face`) with side strips and arrows |
| `src/draw/net.typ` | net renderer (`draw-net`), generic unfolding |
| `src/draw/3d.typ` | orthographic 3D renderer on CeTZ (`draw-3d`) |
| `src/draw/views.typ` | `views` table and the `draw` dispatcher |
| `src/deps.typ` | the only CeTZ import |
| `src/colors.typ` | default palette (`colors`) |
| `src/lib.typ` | public surface |

## 2. The puzzle model

Every puzzle is a dictionary exported as `puzzle` from its file. The fields:

| field | meaning |
| --- | --- |
| `name` | `"cube"`, `"skewb"`, … |
| `event(str)` | params for an event name, or `none` if it is not this puzzle (`"3x3"` → `(size: 3)`) |
| `event-name(params)` | the canonical event name for display |
| `options` | optional: user-settable parameters with their defaults (`(cut: 0.4)` on the megaminx); `registry.resolve` merges `cube(options: ..)` into `params` and rejects unknown keys |
| `draw-options` | optional: puzzle-specific drawing settings with their defaults (Square-1 `(slices: auto, direction: "horizontal", turn: false)`); `draw(options: ..)` is validated against it the same way |
| `faces(params)` | ordered face names |
| `default-scheme(params)` | face → color name |
| `model(params)` | the geometry, see below |
| `parse(alg, params)`, `format(move)` | notation in and out |
| `views` | the views this puzzle supports |
| `default-view` | optional: what `draw(c)` with `view: auto` draws (`"full"` when absent; `"layers"` on the Square-1) |
| `cameras(params)` | `(full: (dir, up) or none, tips: (name → (dir, up)))`; `full` is for the `front-top` pair, `draw(tip:)` picks from `tips` |
| `front-top` | optional: the (front, top) pair the `full` camera is defined for, `("F", "U")`; with it `draw(face:, top:)` turns the camera to any pair that sits the same way (`full-camera` in `views.typ`); without it they are errors |
| `tops`, `direction(params, name, role)` | optional: the names allowed as `top` (default: the faces) and the direction of a name in role `"face"` or `"top"`, `none` if unknown (default: the face normal); the pyraminx's tops are its vertices |
| `fixed-face` | optional: `true` rejects `draw(face:, top:)` altogether (Square-1) |
| `net(params)` | `(roots: (..), edges: ((parent, child), ..))` |
| `rows(params)` | optional: `face()` reshapes the flat array into rows (cube) |
| `index-of(params, face, pos)` | optional: user position → sticker index (cube: `(row, col)`) |
| `index-info(params, index)` | optional: extra fields for mask `info` (cube: `row`, `col`) |
| `scheme-faces(params)` | optional: the keys a scheme must have when they differ from `faces` (Square-1: `U D F B R L`, while its public faces are `U D`; the side stickers live in a third, internal array `E`) |
| `solved(params, scheme)` | optional: extra state fields for a puzzle that builds its own solved state (Square-1: `faces` and `layout`) |
| `model-of(state)` | optional: the model of a state whose geometry depends on it; `registry.model` prefers it over `model(params)` |
| `apply(state, moves)` | optional: replaces the generic move engine (Square-1 moves its `layout` and rebuilds `faces`) |
| `is-solved(state)` | optional: replaces "every face one colour" |
| `layers` | optional: the faces the `layers` renderer draws (Square-1: `U D`); also makes `net` use that renderer with the equator band |
| `strips` | optional: `"radial"` makes `draw-face` draw side strips as trapezoids whose ends follow the rays from the face centre, flush with the face (Square-1); default straight rectangles |
| `slices(params)` | optional: normals of the slice planes through the origin, drawn as lines by `draw-face` when asked (`slices: true`) |

A sticker may also carry `normal` (its own outward normal, when the face's
does not apply), `piece` (an explicit piece id, used instead of the region
signature) and `band: true` (an equator sticker for the layers net). The
Square-1 uses all three.

`model(params)` returns:

```typ
(
  faces: (U: (normal: (x, y, z), frame: (center, normal, u, v), verts: (3D points)), ..),
  stickers: ((face: "U", index: 0, poly: (3D points)), ..),   // in face, then index order
  regions: ((axis: unit vector, lo: float, hi: float), ..),   // every turnable layer
)
```

* Everything is in **units**: one cube sticker edge is 1. The skewb is a cube
  of side 3, the pyraminx has edge 3, the megaminx face inradius is 1.5. The
  `sticker` option scales units to a length.
* A face's `frame` is the 2D coordinate system used to draw it head-on:
  `u` points right, `v` points *down*; it is built by `geom.frame(center,
  normal, up-hint)`, where the up hint says which direction should be at the
  top of the picture (U for side faces, B for the top face, F for the bottom).
  The net uses the same local coordinates, so the two views agree.
* A sticker's `index` order is the public contract of the puzzle and is
  documented in the manual (cube row-major; skewb centre then corners
  clockwise from top-left; pyraminx rows from the apex; megaminx centre,
  edges clockwise from the top, corners clockwise from the top).
* `regions` list every layer that can turn, as a slab `lo <= axis·p <= hi`.
  They are not used for moving; they identify *pieces* (section 4).

A model may be computed once at module level when it has no parameters
(skewb, pyraminx) or per call when it has (cube, by size). The megaminx caches
the default-cut model and builds others on demand. Moves must be parsed with
the same `params` as the state they are applied to, because a move's `region`
is a concrete threshold: `apply` uses `parse-with(alg, c.puzzle, c.params)`,
and `cube()` passes its `options` to `inverse`.

## 3. The move engine

A parsed move carries its own geometry (see the header of `notation.typ`):

```typ
(base: "R", amount: 1, order: 4, axis: (1, 0, 0), step: -90deg, region: (0.5, 1.5), style: "", puzzle: "cube")
```

`apply` does the same thing for every puzzle:

1. Compute every sticker's centroid and index them by a rounded-coordinate key.
2. For each distinct move, build a permutation: every sticker whose centroid
   satisfies `lo <= axis·p <= hi` is rotated by `step * amount` about `axis`
   (right-hand rule) and the sticker found at the new position is its
   destination. Clockwise as seen from outside is therefore a *negative*
   step about an outward axis.
3. Apply the permutation to the flat sticker array.

Permutations are cached per distinct move within one `apply` call. Rounding
the key to three decimals is safe because sticker centroids are far apart; a
nearest-neighbour fallback guards the rare rounding boundary.

No sticker centroid ever lies on a cutting plane, so both ends of a region are
inclusive. This matters for the cube: the deepest layer must include the
opposite face so that `3Rw` on a 3×3 equals `x`.

### Notation

`notation.scan(alg, token-regex, make)` tokenizes (moves plus the punctuation
`( ) [ ] , :`, where a closer carries its `N`/`'` suffix) and then runs a
small recursive-descent parser: `(A)N` and `(A)'` repeat and invert, `[A, B]`
is the commutator `A B A' B'`, `[A: B]` or a bare `A: B` is the conjugate
`A B A'`. A colon binds to the end of its enclosing group, so `C: [A, B]`
reads `C [A, B] C'`; inside brackets the comma splits first, so `[A: B, C]`
is `[(A: B), C]`. Each puzzle supplies a regex for one move and a function
from its captures to a move. Suffix amounts are shared: `""` 1, `'` −1, `2` 2,
`2'`/`'2` −2; `format-suffix` normalises them for the puzzle's order (4, 3 or
5), so `R2'` prints as `R2` on a cube but `U2'` stays `U2'` on a megaminx.
Megaminx `R++`/`D++` are moves with `style: "pm"` that turn everything
*except* the L or U layer (region `(-inf, layer)` about that face's axis).

### Why this is trusted

The cube tests predate the geometric engine and encode physical facts:
`tests/moves/faces` (hand-derived destinations after every face turn, with
strip order), `tests/moves/identities` (`x == R M' L'`, T-perm involution,
sexy move order 6, `3Rw == x`, other sizes). The engine reproduced them
unchanged. `tests/puzzles/*` pin the WCA definitions for the other puzzles:
which centres a skewb `R` cycles, where pyraminx `U` sends F's stickers, which
stickers megaminx `U` and `R++` move. Change a model only with these green.

## 4. The state, pieces and masks

```typ
(kind: "puzzle", puzzle: "cube", event: "3x3", params: (size: 3),
 scheme: (..), faces: (U: (flat stickers), ..))
```

Faces are **flat arrays** in model order; `face()` reshapes cubes into rows.
States compare with `==`. The field layout is not public API.

**Pieces** are identified without any puzzle-specific code: a sticker's piece
id is the string of which `regions` contain its centroid. Two stickers belong
to one piece exactly when every layer moves both or neither, so the
signatures coincide. `hide-pieces` uses this; `tests/state/masks` checks that
a 3×3 has 26 pieces and the UFR corner's three stickers share one.

A mask is `state => state` that replaces stickers with `none`. `mask(c, keep)`
is the generic form; `keep` receives `(face:, index:, color:, piece:)` plus
whatever `index-info` adds (`row`, `col` on cubes). Masks never un-hide, so
they compose in any order.

## 5. Renderers and the `draw` dispatcher

### Renderer contract

Each renderer is `(c, ..named options) => content` that calls
`assert-puzzle`, takes absolute lengths (`abs-pt`), draws via
`common.shape` (uses `rect` for axis-aligned squares so `radius` works,
`polygon` otherwise) and returns inline content (a `box`). Renderers never
look at view names, masks or puzzle names; everything comes from the model.

* **Straight-on** (`2d.typ`): the face's sticker polygons in the face frame.
  Side strips are generic: any sticker on another face with an edge on this
  face's plane is drawn as a thin rectangle outside that edge. Arrows go
  between sticker centroids; positions are resolved by `index-of`. `labels:
  true` writes each index at its centroid, `labels: "faces"` the face name at
  the face centre on a white pill (`name-label` in `common.typ`, since the
  outlines meet there); the manual uses both with an all-white palette.
  `face: auto` is the first entry of the puzzle's `faces` list, so the
  default face exists on every puzzle.
* **Net** (`net.typ`): the puzzle gives a tree of attachments; each child is
  placed by a rigid 2D transform that maps its shared edge onto the parent's.
  `spacing` pushes each face away from its parent along the line between
  their centres, accumulated down the tree. Several roots (megaminx) are laid
  side by side. `labels` works as on the straight-on view.
* **3D** (`3d.typ`): orthographic projection along a camera direction with an
  up hint; stickers with `normal·dir > 0` are drawn (the face's normal, or
  the sticker's own when the model gives one, in which case they are also
  depth-sorted far to near; convex puzzles need no sort). Gaps are insets in
  the sticker's plane.
* **Layers** (`layers.typ`): the faces in the puzzle's `layers` list drawn
  with `draw-face`, side by side or top to bottom (`direction`); with
  `band: true` the stickers tagged `band` that face the front are shown
  between them, left to right. Vertical with the band is the Square-1 net:
  the layers are drawn with `turn: auto` (rotated so the first slice is
  vertical) and `slices: "through"` (box symmetric about the centre, line
  spanning it), the band box is centred on the split and holds the spacing
  above and below with the line drawn through, and the grid has no gutter,
  so one line runs through the whole net. The projection is scaled by
  √1.5 so cubes match the classic isometric drawing. Cameras come from the
  puzzle: `full` (cube/skewb isometric; pyraminx from the front-right and
  slightly below, so F, R and the D base show with the tip on top; megaminx
  straight down F with U up, so F and its five neighbours fill a decagon),
  each defined for F in front and U on top and turned by `full-camera` for
  other `face:`/`top:` pairs, and `tips` (pyraminx, looking down the vertex
  named by `tip:`).

### The `views` table and the options

```typ
face-view = (kind: "face", face: auto, sides: false, mask: none)
full-view = (kind: "3d",  camera: "full", mask: none)
net-view  = (kind: "net", mask: none)

face: face-view,
ll:   (..face-view, face: "U", sides: true),
oll:  (..face-view, face: "U", sides: true, mask: c => keep-colors(c, c.scheme.U)),
full: full-view,
f2l:  (..full-view, mask: c => hide-pieces(c, containing: c.scheme.U)),
tip:  (..full-view, camera: "tip"),
net:  net-view,
```

Three generic views, one per renderer kind; the others are shorthands made by
spreading and overriding. `draw` resolves `view: auto` to the puzzle's
`default-view`, checks the view exists, then that the puzzle lists it in its
`views`, applies the default mask unless `mask:` is
`none` or a function, resolves the camera (`full-camera`: the puzzle's `full`
camera turned from its `front-top` pair to `face:`/`top:`, or `tips.at(tip)`), and
forwards one options dictionary to the renderer closure for the kind.

**All appearance parameters belong to `draw` itself**, each with one
default, so a parameter means the same in every view and unknown ones fail
at the call. Parameters a kind does not use are ignored on purpose. The one
exception: a setting that exists for a single puzzle (Square-1 `slices`,
`direction` and `turn`) is not a parameter but a key of
`draw(options: ..)`, declared by the puzzle in `draw-options` with its
default and validated like `cube(options: ..)`, so `draw`'s signature does
not grow with every puzzle.

Rules when you add a parameter: add it to `draw` with a default; add it to
the `options` dictionary and to every renderer closure that uses it; give it
the same meaning and default in the renderer's own signature; add a row to
the parameter table in `docs/manual.typ`.

### Per-puzzle restrictions

| puzzle | views | notes |
| --- | --- | --- |
| cube | face ll oll full f2l net | arrows take `(row, col)` |
| skewb | face full net | rotation `y` (order 4, about +y) |
| pyraminx | face tip full net | `tip:` picks U, L, R or B; rotations `y` (about the U vertex) and `z` (about the F face normal), both order 3 |
| megaminx | face full net | `full` looks straight down the front face (F by default): that face and its five neighbours; one unit is the centre pentagon's edge at the default cut |
| square1 | face layers obl cs net | public faces U and D; the pieces' sides and the equator sit in an internal array `E` (not flat, not documented for users); `draw(face:, top:)` are rejected (`fixed-face`); `/` fails at compile time when a corner straddles the slice; no groups, commutators or rotations; no 3D view (section 11) |

Side strips and arrows work on every puzzle (arrows take sticker indices
outside cubes). Asking for a view a puzzle lacks fails with a `cubst:`
message listing what it supports.

### The Square-1

The Square-1 is the one puzzle whose geometry changes with the state: a
corner turned by 30° lands where an edge and half a corner were, so sticker
positions are not fixed and the generic engine (a permutation of fixed
stickers) does not apply. `src/puzzles/square1.typ` therefore keeps a `layout`
in the state: two layers of 12 slots of 30° (a corner takes two), the piece in
each slot with its cap colour and side colours in slot order, and whether the
equator is flipped. `build(layout, scheme)` turns a layout into a model
(polygons, per-sticker normals and piece ids) plus the colour arrays, in a
fixed order, so `faces` and the model always agree; `sync` copies colours
(and the `none` of masks) from `faces` back into the layout before a move.
The slice is only legal when slots 0|11 and 5|6 hold different pieces in
both layers; it swaps the right halves reversed, reverses the side order of
the pieces that turned over, and mirrors the right equator piece across the
slice normal. Directions: `(x, y)` turns the top clockwise seen from above
(slot index + x) and the bottom clockwise seen from below (slot index − y),
which is the reading under which the usual scramble openings `(0,-1)/`,
`(1,0)/`, `(4,0)/`, `(0,2)/` are legal. Its views are drawn by `draw-face`
with radial strips and slice lines (`strips`, `slices`) and composed by
`draw-layers`; the net's band is the two equator stickers facing the front
(normal `z > |x|`), which is all one needs to see whether the equator is
flipped.

## 6. Adding a puzzle

1. Create `src/puzzles/<name>.typ` exporting `puzzle` with the fields in
   section 2. Build the model from 3D geometry: face frames via `geom.frame`,
   sticker polygons in 3D, regions as slabs. Write the notation regex and
   `make-move`, choosing `axis`, `step` (negative for clockwise-from-outside)
   and `region` for each move.
2. List it in `registry.puzzles`.
3. Add `tests/puzzles/<name>` pinning the move directions from the official
   definition (orders, which stickers a move carries where, sticker counts
   per colour) and `tests/render/<name>` for its views.
4. Document the sticker index order and notation in the manual.

Nothing else needs to change: states, masks, pieces and all renderers work
from the model alone. Only a puzzle whose shape depends on its state needs
the optional hooks (`solved`, `model-of`, `apply`, `is-solved`); the Square-1
is the worked example.

## 7. Dependencies

CeTZ is imported in exactly one place, `src/deps.typ`. To upgrade: change
that line, check CeTZ's `compiler` requirement, raise `compiler` in our
`typst.toml` and the CI matrix to match, run `just test`, inspect image diffs.
Public functions return finished content, never CeTZ elements. Do not
re-export `cetz`.

## 8. Testing

```sh
just test                 # everything
tt run puzzles/skewb      # one test
just update               # regenerate all reference images
tt update render/oll      # regenerate one
```

`moves/*`, `state/*`, `puzzles/*`, `draw/*`, `colors` are unit tests (compile
and `assert`). `render/*` are image tests with a `ref/` directory. Keep
them small, with `#set page(width: auto, height: auto)`. References are
generated with the local Typst (0.15, the newest entry of the CI matrix).
Older compilers rasterize slanted edges slightly differently, which showed up
as a single deviating pixel on `render/square1` under Typst 0.13/0.14, so
`just test` allows up to 10 deviating pixels per image (`--max-deviations`);
a genuine change moves hundreds. Raise the number only with a diff image in
hand.

## 9. Conventions

* Everything is a value. No `state()`, no counters, no globals.
* Public functions validate input and panic with messages starting `cubst:`.
* Lengths used for geometry must be absolute; `abs-pt` enforces it.
* Keep `lib.typ` as imports only.
* Closures capture variables by value at definition time; pass tables that
  are still being filled as parameters (see `net.typ`).
* Document every public function with a `///` comment above it.

## 10. Packaging and release

### What ships where

Typst Universe sorts a package's files into three groups
([docs/tips.md](https://github.com/typst/packages/blob/main/docs/tips.md) in
`typst/packages`), and this repository encodes the split in two files:

| group | files | `.typstignore` (goes into the PR?) | `typst.toml` `exclude` (in the archive?) |
| --- | --- | --- | --- |
| required | `typst.toml`, `src/`, `LICENSE`, `README.md` | yes | yes |
| linked from the README | `CHANGELOG.md`, `docs/manual.pdf`, `docs/thumbnail-*.svg` | yes | no: Universe serves them for the README's links and images, users do not download them |
| development only | `tests/`, `examples/`, `scripts/`, `Justfile`, `.github/`, `docs/*.typ`, `docs/DEVELOPMENT.md`, dotfiles | no | – |

`scripts/package` (behind `just package`, `just install`) copies everything
`.typstignore` lets through, so `just package out` produces exactly the tree
the PR must contain: `out/cubst/<version>/`. Keep the two lists in step: a
file the README links to must pass `.typstignore` *and* appear in `exclude`.

`docs/manual.pdf` and the thumbnails are committed (the manual is the only
PDF `.gitignore` allows) because the README on GitHub links to them as well;
rebuild them with `just doc` before every commit that changes the manual or
the thumbnail.

### Versions

The version lives in `typst.toml`. The manual reads it from there
(`toml("/typst.toml").package.version`), so only two places are written by
hand: the `@preview/cubst:<version>` import in `README.md` and the
`## [<version>]` heading in `CHANGELOG.md`. The release workflow refuses a
tag unless all three agree with the tag name, and runs the test suite before
packaging. Published versions are immutable on Universe, so a mistake in a
release is fixed by a new patch version, never by re-tagging.

The README is the package's page on Universe. Universe drops its top-level
heading, resolves relative links and images against the package directory
and does not render GitHub alerts, emoji shortcodes or task lists.

### Checklist

1. Move the `Unreleased` section of `CHANGELOG.md` under `## [<version>] -
   <date>` and add its link line (`[<version>]:
   https://github.com/ANCuber/cubst/releases/tag/v<version>`, with
   `[Unreleased]` pointing at `compare/v<version>...HEAD`); set the version
   in `typst.toml` and in the import in `README.md`.
2. `just test` and `just doc`; read `docs/manual.pdf` and look at the thumbnails.
3. `just install`, then compile a document outside the repo with
   `#import "@local/cubst:<version>": *`.
4. `just package out` and check `out/cubst/<version>` holds only the first
   two groups above. Delete `out/` afterwards (it is git-ignored).
5. Commit, then tag `v<version>` and push the tag. The release workflow
   builds the manual, attaches `cubst-<version>.zip` and `manual.pdf` to a
   GitHub release, and pushes a branch `cubst-<version>` to the fork named by
   `REGISTRY_FORK` in `.github/workflows/release.yml`. It needs that fork of
   `typst/packages` to exist and a repository secret `REGISTRY_TOKEN` (a
   fine-grained token with contents read and write on the fork).
6. Open the pull request from that branch to `typst/packages`, titled
   `cubst:<version>`, and fill in its checklist. Later versions must come from
   the same GitHub account.

Without the workflow: `just package out`, copy `out/cubst/<version>` to
`packages/preview/cubst/<version>` in a fork of `typst/packages`, commit and
open the same pull request.

## 11. Known gaps and ideas

* FTO, after WCA releases the official notation.
* Arrows only on the straight-on view; maybe ones for "x y z" operations can be added.
* No `mirror`.
* Megaminx: no rotations, so the `full` view always shows the U half.
* Square-1 in 3D: the model already gives every sticker its own normal and
  the 3D renderer culls and depth-sorts per sticker, so a `full` view only
  needs `"full"` in the puzzle's `views` and a camera in `cameras`. It was
  left out because a shape-shifted Square-1 is hard to read in 3D; the
  protruding equator and star-shaped layers would need a better camera or
  outlines to work.
* Even-sized cubes have no fixed centres; the scheme still names a "U color".

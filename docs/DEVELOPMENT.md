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
| `options` | optional: user-settable parameters with their defaults (`(cut: 0.5)` on the megaminx); `registry.resolve` merges `cube(options: ..)` into `params` and rejects unknown keys |
| `faces(params)` | ordered face names |
| `default-scheme(params)` | face → color name |
| `model(params)` | the geometry, see below |
| `parse(alg, params)`, `format(move)` | notation in and out |
| `views` | the views this puzzle supports |
| `cameras(params)` | `(full: (dir, up) or none, tips: (name → (dir, up)))` |
| `net(params)` | `(roots: (..), edges: ((parent, child), ..))` |
| `rows(params)` | optional: `face()` reshapes the flat array into rows (cube) |
| `index-of(params, face, pos)` | optional: user position → sticker index (cube: `(row, col)`) |
| `index-info(params, index)` | optional: extra fields for mask `info` (cube: `row`, `col`) |

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

`notation.scan(alg, token-regex, make)` handles whitespace and groups
(`(R U)3`, `(R U)'`); each puzzle supplies a regex for one move and a function
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
  between sticker centroids; positions are resolved by `index-of`.
* **Net** (`net.typ`): the puzzle gives a tree of attachments; each child is
  placed by a rigid 2D transform that maps its shared edge onto the parent's.
  `spacing` pushes each face away from its parent along the line between
  their centres, accumulated down the tree. Several roots (megaminx) are laid
  side by side.
* **3D** (`3d.typ`): orthographic projection along a camera direction with an
  up hint; faces with `normal·dir > 0` are drawn (convex puzzles need no depth
  sort). Gaps are insets in the face plane. The projection is scaled by
  √1.5 so cubes match the classic isometric drawing. Cameras come from the
  puzzle: `full` (cube/skewb isometric; pyraminx from the front-right and
  slightly below, so F, R and the D base show with the tip on top; megaminx
  none) and `tips` (pyraminx, looking down a vertex).

### The `views` table and the options

```typ
face-view = (kind: "face", face: auto, sides: false, mask: none)
full-view = (kind: "3d",  camera: "full", mask: none)
net-view  = (kind: "net", mask: none)

face: face-view,
pll:  (..face-view, face: "U", sides: true),
oll:  (..face-view, face: "U", sides: true, mask: c => keep-colors(c, c.scheme.U)),
full: full-view,
f2l:  (..full-view, mask: c => hide-pieces(c, containing: c.scheme.U)),
tip:  (..full-view, camera: "tip"),
net:  net-view,
```

Three generic views, one per renderer kind; the others are shorthands made by
spreading and overriding. `draw` checks the view exists, then that the
puzzle lists it in its `views`, applies the default mask unless `mask:` is
`none` or a function, resolves the camera (`full`, or `tips.at(tip)`), and
forwards one options dictionary to the renderer closure for the kind.

**All appearance options are parameters of `draw` itself**, each with one
default, so an option means the same in every view and unknown options fail
at the call. Options a kind does not use are ignored on purpose.

Rules when you add an option: add it to `draw` with a default; add it to the
`options` dictionary and to every renderer closure that uses it; give it the
same meaning and default in the renderer's own signature; add a row to the
options table in `docs/manual.typ`.

### Per-puzzle restrictions

| puzzle | views | notes |
| --- | --- | --- |
| cube | face pll oll full f2l net | arrows take `(row, col)` |
| skewb | face full net | |
| pyraminx | face tip full net | `tip:` picks U, L, R or B |
| megaminx | face net | no 3D camera |

Side strips and arrows work on every puzzle (arrows take sticker indices
outside cubes). Asking for a view a puzzle lacks fails with a `cubst:`
message listing what it supports.

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

Nothing else needs to change: states, masks, pieces and all three renderers
work from the model alone.

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
generated with the local Typst; align the CI matrix with it or regenerate in
CI.

## 9. Conventions

* Everything is a value. No `state()`, no counters, no globals.
* Public functions validate input and panic with messages starting `cubst:`.
* Lengths used for geometry must be absolute; `abs-pt` enforces it.
* Keep `lib.typ` as imports only.
* Closures capture variables by value at definition time; pass tables that
  are still being filled as parameters (see `net.typ`).
* Document every public function with a `///` comment above it.

## 10. Release checklist

1. Update `CHANGELOG.md` and the version in `typst.toml`, `README.md`,
   `docs/manual.typ`.
2. `just test` and `just doc`; check `docs/manual.pdf` and the thumbnails.
3. `just install`, then compile a document outside the repo with
   `#import "@local/cubst:<version>": *`.
4. Tag `v<version>`. The release workflow needs `REGISTRY_FORK` to be your fork
   of `typst/packages` and a `REGISTRY_TOKEN` secret with push access to it.

## 11. Known gaps and ideas

* Arrows only on the straight-on view.
* No commutator/conjugate notation, no `mirror`.
* Megaminx: no 3D view. The centre-pentagon size is the `cut` option
  (default 0.5 of the face inradius); real puzzles are nearer 0.55.
* Even-sized cubes have no fixed centres; the scheme still names a "U color".

# cubst developer guide

This document explains how the package is put together, the conventions every
module relies on, and how to extend or release it. The user-facing manual is
`docs/manual.typ`.

## 1. Architecture

```
            API 1 (build)                       API 2 (draw)
  ┌─────────────────────────┐          ┌────────────────────────────┐
  │ cube.typ  cube(), case()│          │ draw/views.typ  draw()     │
  └───────────┬─────────────┘          │   views table: name →      │
              │                        │   (renderer, default mask) │
  ┌───────────▼─────────────┐          └──────┬─────────┬──────┬────┘
  │ moves.typ  parse, apply │                 │         │      │
  │            inverse      │            2d.typ     3d.typ   net.typ
  └───────────┬─────────────┘            (pure)     (CeTZ)    (pure)
              │                                       │
  ┌───────────▼─────────────┐                   deps.typ (pins CeTZ)
  │ state.typ  solved, face,│
  │   masks, sticker-pos    │◄────── draw/common.typ (palette lookup)
  └───────────┬─────────────┘
              │
         util.typ (array rotation, strips)
```

Dependencies only point downwards. `state.typ` knows nothing about moves or
drawing; `moves.typ` knows nothing about drawing; renderers never parse
algorithms. `lib.typ` is re-exports only.

| File | Responsibility |
| --- | --- |
| `src/util.typ` | square-array rotation, reading/writing a row or column at a depth |
| `src/state.typ` | the cube dictionary, scheme, accessors, cubie coordinates, masks |
| `src/moves.typ` | tokenizer, parser, inverse, `to-string`, the move engine (`apply`) |
| `src/cube.typ` | `cube()` and `case()` constructors |
| `src/draw/common.typ` | palette lookup, absolute-length check |
| `src/draw/2d.typ` | straight-on renderer for any face (`draw-face`) incl. arrows |
| `src/draw/net.typ` | unfolded net renderer (`draw-net`) |
| `src/draw/3d.typ` | isometric renderer on CeTZ (`draw-3d`) |
| `src/draw/views.typ` | `views` table and the `draw` dispatcher |
| `src/deps.typ` | the only CeTZ import |
| `src/colors.typ` | default palette (`colors`) |
| `src/lib.typ` | public surface |

## 2. The state

A cube is a plain dictionary and nothing else:

```typ
(
  kind: "cube",
  size: 3,
  scheme: (U: "yellow", D: "white", F: "green", B: "blue", R: "orange", L: "red"),
  faces: (U: rows, D: rows, F: rows, B: rows, R: rows, L: rows),
)
```

* `rows` is an N×N array of rows. A sticker is a **color name** (string) or
  `none` for hidden. Names are resolved through a palette only at draw time, so
  the state carries no `color` values and no rendering options.
* `scheme` records which color name each face had when solved. Masks use it to
  mean "the U color" even after whole-cube rotations moved that color elsewhere.
* `kind: "cube"` lets every public function validate its input with
  `assert-cube` and fail with a `cubst:`-prefixed message.
* States compare with `==` because they contain only data. Tests rely on this.
* The field layout is **not** public API. Users get `face`, `sticker`, `is-solved`.

### Face array convention

Every face is viewed from outside the cube. Row 0 is the top row, column 0 the
left column, in the standard net:

```
        U            U: seen from above, B at the top, L on the left
      L F R B        F R B L: seen from the front/right/back/left, U at the top
        D            D: seen from below, F at the top, L on the left
```

Consequences that other code depends on:

| face | top edge touches | left edge touches |
| --- | --- | --- |
| F | U | L |
| R | U | F |
| B | U | R |
| L | U | B |
| U | B | L |
| D | F | L |

### Cubie coordinates

`sticker-pos(size, face, row, col)` maps a sticker to `(x, y, z)` with
x: L→R, y: D→U, z: B→F, each in `0..size-1`. Stickers of the same piece share a
coordinate. This is what `hide-pieces` uses, and it is the hook for any future
piece-level feature (highlighting a pair, selecting a slot, 3D arrows).

## 3. The move engine

### Move representation

`parse` turns a string into an array of `(face:, layers:, amount:)`:

* `face` is the face whose turning direction the move follows. Slices and
  rotations are normalised: `M` → `L`, `E` → `D`, `S` → `F`, `x` → `R`,
  `y` → `U`, `z` → `F`.
* `layers` is an integer `n` (the `n` outermost layers from `face`), `"inner"`
  (every middle layer) or `"all"`.
* `amount` is quarter turns clockwise as seen from `face`: `1`, `2` or `-1`.

`resolve-depths` turns `layers` into concrete depth indices for the cube size,
which is why the same move list works on any N.

### Tokenizer rule for numbers

Each token records whether whitespace preceded it (`sp`). A number attached to a
letter (`R2`) is a turn count; a number after a space (`R 3Rw`) starts a layer
count. A number right after `)` repeats the group. Without this flag `R2 U` is
ambiguous with `R 2U`.

### Turning one layer

`turn-layer(faces, size, face, depth)` is the only place geometry lives. It uses
the `cycles` table:

```typ
R: (("F", "right", false), ("U", "right", false), ("B", "left", true), ("D", "right", false))
```

For face `X`, the entries are the four neighbours in **clockwise order as seen
from outside `X`** (stickers move from each entry to the next), the side of
that neighbour that touches `X`, and a `reversed` flag. Strips are read with
`util.get-strip` (rows left→right, columns top→bottom); the flag is set when
that natural reading runs against the rotational direction, so that after
applying the flags all four strips read consistently and can be cycled by a
plain index shift.

How the flags were derived, so you can re-derive them if you change the face
convention: for neighbour `A_i`, the strip must be read from `A_{i-1}` towards
`A_{i+1}`. Look up which neighbouring faces the natural reading runs between
(table in section 2) and set the flag when it runs the other way. Flipping all
four flags of one face is harmless; flipping one is not.

Depth 0 also rotates `X` clockwise; depth `size-1` rotates the opposite face
counter-clockwise. Nothing else is special-cased.

### Why this is trusted

`tests/moves/faces` checks every face turn against hand-derived destinations
including strip order. `tests/moves/identities` checks `x == R M' L'`,
`y == U E' D'`, `z == F S B'`, that the T-perm is an involution, that the sexy
move has order 6, and the same on 2×2, 4×4 and 5×5. If you touch `cycles` or
`util.typ`, these tests are the safety net; add a case before changing anything.

## 4. Masks

A mask is `cube => cube` that replaces stickers with `none`. `mask(c, keep)` is
the generic form; `keep` receives `(face:, row:, col:, color:, pos:)`.
`keep-colors`, `hide-faces` and `hide-pieces` are thin wrappers. Masks never
un-hide anything, so they compose in any order, and they are state transforms so
every renderer handles them for free.

## 5. Renderers and the `draw` dispatcher

### Renderer contract

Each renderer is a function `(c, ..named options) => content` that:

* calls `assert-cube`;
* takes geometry as **absolute lengths** (`sticker`, `gap`, …) and converts them
  with `abs-pt`, computing in floats and multiplying by `1pt` at the end;
* resolves colors with `fill-of(name, palette, hidden)`;
* returns **inline** content (`box`) so cubes sit in text and in `grid` cells
  alike. The 3D renderer boxes its CeTZ canvas for this reason;
* knows nothing about view names or masks.

### The `views` table and the options

```typ
face-view = (kind: "face", face: auto, sides: false, mask: none)  // auto = the `face:` option
full-view = (kind: "3d",  mask: none)
net-view  = (kind: "net", mask: none)

face: face-view,
pll:  (..face-view, face: "U", sides: true),
oll:  (..face-view, face: "U", sides: true, mask: c => keep-colors(c, c.scheme.U)),
full: full-view,
f2l:  (..full-view, mask: c => hide-pieces(c, containing: c.scheme.U)),
net:  net-view,
```

A view is a renderer *kind* plus a default mask, plus, for the straight-on
kind, which face it looks at. There are three generic views, one per kind; the
named views are shorthands derived from them by spreading and overriding:
`pll` is `face` with the face fixed to `U` and side strips on, `oll` is that
plus a mask, `f2l` is `full` plus a mask. A view entry can carry a default for
an option (`sides` here); `draw` uses it when the caller passes `auto`. Keep new shorthands in this form so the relationship
stays visible in the code. The mask is part of the view so that `view: "oll"`
is all a user needs to write; `mask: none` or a custom function overrides it.

**All appearance options are parameters of `draw` itself**, each with exactly
one default, so an option means the same thing in every view and unknown
options fail at the `draw` call. `draw` builds an options dictionary and the
`renderers` table maps each kind to a closure that forwards only the options
that renderer understands. Options a kind does not use are ignored on purpose
(documented in the manual), which lets users keep one option set for every
view. The lower-level `draw-face`/`draw-3d`/`draw-net` keep their own
signatures with the same defaults.

Rules when you add an option:

1. Add it to `draw` with a default.
2. Add it to the `options` dictionary and to every renderer closure that uses it.
3. Give it the same meaning and default in the renderer's own signature.
4. Add a row to the options table in `docs/manual.typ`, with the "used by" column.

Adding a view is one table entry. Adding a renderer kind is one file plus an
entry in `renderers`.

The generic views are the ones to extend; shorthands only fix arguments.

### Geometry notes

* **Top view** (`2d.typ`): the U face grid plus one strip per side. Because B is
  stored as seen from behind, its top row is mirrored when drawn above U; R's
  top row is mirrored when drawn down the right side. L and F need no mirroring.
  Arrows take `(row, col)` on the U grid; heads are polygons computed from the
  unit direction vector.
* **3D view** (`3d.typ`): fixed isometric projection, `(x, y, z) → ((x - z)·cos 30°, y - (x + z)·sin 30°)`,
  showing U, F, R. Each sticker is a quad in cube units (one sticker = one unit)
  drawn with `cetz.draw.line(.., close: true, fill:)`; the canvas `length` is the
  sticker size. When `body` is set, three body quads are drawn first so gaps
  show the body color. `radius` is not supported in 3D.
  Other faces are shown by rotating the *state*, not the camera.
* **Palette** (`colors.typ`): the default shades are the common "official"
  sticker colors. White, yellow and orange were chosen to stay distinct from
  each other and from red at small sizes; keep that property if you retune them.
  The palette also carries `hidden`, the color for masked stickers. The
  `hidden:` draw option defaults to `auto`, which means "the palette's
  `hidden` entry" (`fill-of` in `common.typ`). `grey` is an ordinary sticker
  color and is unrelated to masking.
* **Net** (`net.typ`): faces placed on a 4×3 grid of face-sized cells.

## 6. Dependencies

CeTZ is imported in exactly one place, `src/deps.typ`, and every module imports
it from there. To upgrade: change that line, check CeTZ's `compiler`
requirement in its `typst.toml`, raise `compiler` in our `typst.toml` and the CI
matrix to match, then run `just test` and inspect any image diffs.

Public functions return finished content, never CeTZ elements, so users' own
CeTZ version can never conflict with ours. Do not re-export `cetz`.

## 7. Testing

Tests live in `tests/<group>/<name>/test.typ` and run with Tytanic:

```sh
just test                 # everything
tt run moves/faces        # one test
just update               # regenerate all reference images
tt update render/oll      # regenerate one
```

* `moves/*`, `state/*`, `colors` are **unit tests**: they compile and `assert`.
  A failing assertion fails the test with its message.
* `render/*` are **image tests**: a `ref/` directory marks them as such. Each
  page is compared pixel-wise against `ref/1.png`. Keep them small and use
  `#set page(width: auto, height: auto)`.

Reference images were generated with the local Typst version. CI runs the
versions in `.github/workflows/tests.yml`; font or rasterizer differences across
Typst versions can produce diffs, so align the matrix with the version used to
generate references, or regenerate in CI.

## 8. Conventions

* Everything is a value. No `state()`, no counters, no globals.
* Public functions validate input and panic with messages starting `cubst:`.
* Lengths used for geometry must be absolute; `abs-pt` enforces it.
* Keep `lib.typ` as imports only. Helpers stay private by not being listed there.
* Names use kebab-case. Move letters are the only single-capital identifiers.
* Document every public function with a `///` comment above it.

## 9. Release checklist

1. Update `CHANGELOG.md` and the version in `typst.toml`, `README.md`,
   `docs/manual.typ`.
2. `just test` and `just doc`; check `docs/manual.pdf` and the thumbnails.
3. `just install`, then compile a document outside the repo with
   `#import "@local/cubst:<version>": *` to check packaging and `.typstignore`.
4. Tag `v<version>`. The release workflow needs `REGISTRY_FORK` to be your fork
   of `typst/packages` and a `REGISTRY_TOKEN` secret with push access to it.

## 10. Known gaps and ideas

* Arrows only on the shown face of the straight-on view. 3D arrows could reuse `sticker-pos`.
* The 3D camera is fixed; other faces are viewed by rotating the state.
* No commutator/conjugate notation (`[A, B]`, `[A: B]`).
* No `mirror` for algorithms.
* Even-sized cubes have no fixed centers; the scheme still names a "U color",
  which is what masks use.

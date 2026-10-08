# cubst
<div align="center">Version 0.1.0</div>

Draw twisty puzzles in Typst. `cubst` builds a puzzle *state* from an
algorithm and renders it: OLL/PLL diagrams, any face straight on, 3D views,
or an unfolded net. It supports N×N cubes, the skewb, the pyraminx and the
megaminx, all driven by one geometric engine.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./thumbnail-dark.svg">
  <img src="./thumbnail-light.svg">
</picture>

## Getting started

```typ
#import "@preview/cubst:0.1.0": *

// the case an algorithm solves, drawn as an OLL diagram
#draw(case("R U R' U R U2 R'"), view: "oll")

// a PLL diagram with arrows between (row, col) positions on the top face
#draw(case("R U R' U' R' F R2 U' R' U' R U R' F'"), view: "pll", arrows: (
  (from: (0, 2), to: (2, 2), double: true),
  (from: (1, 0), to: (1, 2), double: true),
))

// an F2L case (last-layer pieces greyed out) and a scrambled cube in 3D
#draw(case("U R U' R'"), view: "f2l")
#draw(cube(scramble: "R U F2 D' L B'"), view: "full")

// other puzzles, chosen by event
#draw(cube(event: "pyraminx", scramble: "U L R' B u"), view: "tip")
#draw(cube(event: "skewb", scramble: "R L U B'"), view: "full")
#draw(cube(event: "megaminx", scramble: "R++ D-- U"), view: "face", face: "U", sides: true)
```

## How it works

States are plain values, so you can build them once and draw them many ways:

```typ
#let c = cube(scramble: "R U F2 D' L B'")
#draw(c, view: "full")
#draw(apply(c, "y2"), view: "full")   // look at the other side
#draw(c, view: "net")
```

| Function | Purpose |
| --- | --- |
| `cube(event: "3x3", scramble: none, inverted: false, scheme: auto, options: (:))` | build a state; events: `"NxN"`, `"skewb"`, `"pyraminx"`, `"megaminx"`; options such as `(cut: 0.5)` on the megaminx |
| `case(alg, event: ..)` | the state that `alg` solves (inverse scramble) |
| `apply(c, alg)` | apply more moves, returns a new state |
| `keep-colors`, `hide-faces`, `hide-pieces`, `mask` | hide stickers before drawing |
| `draw(c, view: .., mask: auto, ..options)` | render; views: `face`, `pll`, `oll`, `full`, `f2l`, `tip`, `net` |

| Puzzle | Views | Notation |
| --- | --- | --- |
| N×N cubes | all | `R U F' D2`, wide `Rw r 3Rw`, slices `M E S`, rotations `x y z`, groups `(R U R' U')3`, commutators `[R, U]`, conjugates `[F: [R, U]]` |
| skewb | `face`, `full`, `net` | `R L U B` (WCA fixed-corner), rotation `y` |
| pyraminx | `face`, `tip`, `full`, `net` | `U L R B`, tips `u l r b`, rotations `y z` |
| megaminx | `face`, `net` | face turns, `R++ R-- D++ D--` |

The default scheme is yellow on top, green in front. See `docs/manual.pdf`
for all options and `docs/DEVELOPMENT.md` for how it is built.

## Development

Requirements: [Typst](https://typst.app) ≥ 0.13.1, [just](https://github.com/casey/just),
and [Tytanic](https://github.com/typst-community/tytanic) (`brew install tytanic`).

```sh
just test          # run the test suite
just update        # accept new reference images
just doc           # build docs/manual.pdf and the thumbnails
just install       # install to the @local namespace for use in other documents
just uninstall
```

Layout:

- `src/lib.typ` public API (re-exports only)
- `src/puzzles/` one file per puzzle: 3D model, notation, cameras, net
- `src/state.typ`, `src/moves.typ` generic state, masks and move engine
- `src/cube.typ` the `cube`/`case` constructors
- `src/draw/` renderers (`2d.typ`, `net.typ`, `3d.typ`) and the `draw` dispatcher (`views.typ`)
- `src/deps.typ` the single place third-party packages (CeTZ) are imported
- `tests/` Tytanic unit and image-regression tests
- `examples/` scratch documents, not published
- `docs/` manual, developer guide and thumbnail sources

## License

[MIT](LICENSE)

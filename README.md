# cubst
<div align="center">Version 0.1.0</div>

Draw Rubik's cubes in Typst. `cubst` builds a cube *state* (solved, blank, or
the result of applying an algorithm such as `R U R' U'`) and renders it as a 2D
top view, an unfolded net, or a 3D view powered by [CeTZ](https://github.com/cetz-package/cetz).

> Status: early development. The API below is the target design and is not
> implemented yet.

## Getting started

```typ
#import "@preview/cubst:0.1.0": *

// planned API
#cube-2d(alg: "R U R' U'")
#cube-3d(alg: "F R U R' U' F'")
```

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./thumbnail-dark.svg">
  <img src="./thumbnail-light.svg">
</picture>

## Development

Requirements: [Typst](https://typst.app) ≥ 0.13.1, [just](https://github.com/casey/just),
and [Tytanic](https://github.com/typst-community/tytanic) (`cargo install tytanic --locked`).

```sh
just test          # run the test suite
just update        # accept new reference images
just doc           # build docs/manual.pdf and the thumbnails
just install       # install to the @local namespace for use in other documents
just uninstall
```

Layout:

- `src/lib.typ` public API (re-exports only)
- `src/deps.typ` the single place third-party packages (CeTZ) are imported
- `src/state.typ`, `src/moves.typ` cube model and move notation
- `src/draw/` renderers (`2d.typ`, `net.typ`, `3d.typ`)
- `tests/` Tytanic unit and image-regression tests
- `examples/` scratch documents, not published
- `docs/` manual and thumbnail sources

## License

[Unlicense](LICENSE)

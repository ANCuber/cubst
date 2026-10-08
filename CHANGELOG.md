# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Project scaffold: package manifest, CI, test layout, manual skeleton.
- Size-generic cube state (`cube`, `case`, `apply`, `face`, `sticker`, `is-solved`).
- Move notation: face, wide, slice and rotation moves, `'`/`2` suffixes, repeated groups.
- Masks: `keep-colors`, `hide-faces`, `hide-pieces`, `mask`.
- `draw` with views `oll`, `pll`, `face` (any face straight on, optional side strips and arrows),
  `f2l`, `full` (3D via CeTZ) and `net`.
- Skewb, pyraminx and megaminx, selected with `cube(event: ..)`, with WCA notation,
  per-puzzle view availability and a `tip` view for the pyraminx.
- A geometric move engine shared by every puzzle: moves are rotations of sticker
  polygons about an axis, piece identity and all renderers derive from the 3D model.

### Changed

- `cube(size: 3)` became `cube(event: "3x3")`; `solved`, `case`, `parse` and `inverse` take `event:`.
- Faces of puzzles other than cubes are flat arrays; `sticker(c, face, index)`.
- `gap` shrinks stickers in place instead of adding space between them.

[Unreleased]: https://github.com/ANCuber/cubst/commits/main

// Helpers shared by all renderers.

#import "../colors.typ": colors as default-palette

/// Resolve a sticker's color name through the palette. `none` means the
/// sticker is masked and is drawn with `hidden`; when that is `auto`, the
/// palette's own `hidden` entry is used.
#let fill-of(name, palette, hidden) = {
  if name == none {
    if hidden == auto { palette.at("hidden", default: default-palette.hidden) } else { hidden }
  } else {
    assert(name in palette, message: "cubst: palette has no color named " + repr(name))
    palette.at(name)
  }
}

/// Lengths used for geometry must be absolute so they can be turned into numbers.
#let abs-pt(value, what) = {
  assert(type(value) == length, message: "cubst: " + what + " must be a length, got " + repr(value))
  value.pt()
}

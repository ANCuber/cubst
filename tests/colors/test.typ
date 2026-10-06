#import "/src/lib.typ": colors

// Unit test: the default palette exposes the six face colors, grey, and the
// color masked stickers are drawn with.
#assert.eq(
  colors.keys().sorted(),
  ("blue", "green", "grey", "hidden", "orange", "red", "white", "yellow"),
)
#for (name, value) in colors {
  assert(type(value) == color, message: name + " is not a color")
}

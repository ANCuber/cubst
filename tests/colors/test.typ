#import "/src/lib.typ": colors

// Unit test: the default palette exposes the six face colors, the extra
// megaminx colors, grey, and the color masked stickers are drawn with.
#assert.eq(
  colors.keys().sorted(),
  ("beige", "blue", "green", "grey", "hidden", "lightblue", "lime", "orange", "pink", "purple", "red", "white", "yellow"),
)
#for (name, value) in colors {
  assert(type(value) == color, message: name + " is not a color")
}

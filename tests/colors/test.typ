#import "/src/lib.typ": colors

// Unit test: the default palette exposes exactly the six face colors plus grey.
#assert.eq(
  colors.keys().sorted(),
  ("blue", "green", "grey", "orange", "red", "white", "yellow"),
)
#for (name, value) in colors {
  assert(type(value) == color, message: name + " is not a color")
}

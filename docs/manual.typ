#import "/src/lib.typ" as cubst

#set document(title: "cubst manual")
#set page(numbering: "1")
#set heading(numbering: "1.1")

#align(center)[
  #text(2em, weight: "bold")[cubst]
  #v(0.5em)
  Draw Rubik's cubes in Typst
  #v(0.5em)
  Version 0.1.0
]

#outline()

= Introduction

`cubst` renders Rubik's cubes from a cube _state_. A state can be built from
explicit stickers or by applying an algorithm (e.g. `R U R' U'`) to a solved
cube, and can then be drawn as a 2D top view, an unfolded net, or a 3D view.

= Installation

```typ
#import "@preview/cubst:0.1.0": *
```

= Usage

// Fill in once the public API exists.

= Reference

// One subsection per exported function.

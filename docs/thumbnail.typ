#import "/src/lib.typ" as cubst: *

#set page(height: auto, margin: 5mm, fill: none)

// style thumbnail for light and dark theme
#let theme = sys.inputs.at("theme", default: "light")
#set text(white) if theme == "dark"

// Replace with a rendered cube once the renderers exist.
#set text(22pt)
#align(center)[*cubst* — Rubik's cubes in Typst]

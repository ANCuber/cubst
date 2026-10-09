#import "/src/lib.typ": *
#set page(width: auto, height: auto, margin: 2mm)

// T perm: swaps the UBR/UFR corners and the UL/UR edges
#draw(case("R U R' U' R' F R2 U' R' U' R U R' F'"), view: "ll", arrows: (
  (from: (0, 2), to: (2, 2), double: true),
  (from: (1, 0), to: (1, 2), double: true),
))
#h(4mm)
// U perm (a): three-cycle of edges, single-headed arrows
#draw(case("R U' R U R U R U' R' U' R2"), view: "ll", arrows: (
  ((1, 0), (0, 1)),
  ((0, 1), (1, 2)),
  (from: (1, 2), to: (1, 0), color: red, thickness: 0.8pt, head: 0.5),
))
#h(4mm)
// thicker side strips
#draw(case("R U R' U'"), view: "ll", sticker: 5mm, side-length: 0.5)

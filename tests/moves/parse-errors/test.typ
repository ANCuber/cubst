// Parsing rejects malformed algorithms with cubst-prefixed messages.
#import "/src/moves.typ": parse

#let moves = parse("R U R' U'")
#assert(moves.len() == 4)
#assert(moves.at(0) == (face: "R", layers: 1, amount: 1))
#assert(moves.at(2) == (face: "R", layers: 1, amount: -1))
#assert(parse("M") == ((face: "L", layers: "inner", amount: 1),))
#assert(parse("x'") == ((face: "R", layers: "all", amount: -1),))
#assert(parse("3Rw2") == ((face: "R", layers: 3, amount: 2),))
#assert(parse("RUR'U'") == parse("R U R' U'"))
#assert(parse("(R U)2 R") == parse("R U R U R"))
#assert(parse(()) == ())

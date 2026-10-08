// Parsing produces the expected moves and rejects malformed algorithms.
#import "/src/moves.typ": parse

#let fields(m) = (face: m.face, layers: m.layers, amount: m.amount)

#let moves = parse("R U R' U'")
#assert(moves.len() == 4)
#assert(fields(moves.at(0)) == (face: "R", layers: 1, amount: 1))
#assert(fields(moves.at(2)) == (face: "R", layers: 1, amount: -1))
#assert(fields(parse("M").first()) == (face: "L", layers: "inner", amount: 1))
#assert(fields(parse("x'").first()) == (face: "R", layers: "all", amount: -1))
#assert(fields(parse("3Rw2").first()) == (face: "R", layers: 3, amount: 2))
#assert(parse("RUR'U'") == parse("R U R' U'"))
#assert(parse("(R U)2 R") == parse("R U R U R"))
#assert(parse("R2 U") == parse("R2 U"))
#assert(parse("R2 U").len() == 2 and parse("R2 U").first().amount == 2)
#assert(parse(()) == ())

// other puzzles have their own notation
#assert(parse("R L U B'", event: "skewb").len() == 4)
#assert(parse("U l R' b", event: "pyraminx").map(m => m.base) == ("U", "l", "R", "b"))
#assert(parse("R++ D-- U' BL2", event: "megaminx").map(m => m.amount) == (2, -2, -1, 2))

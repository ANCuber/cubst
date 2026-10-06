// Move notation: parsing algorithm strings and applying them to a cube state.
//
// Supported tokens (whitespace optional between moves):
//   face turns      R L U D F B           suffixes: ' 2 2'
//   wide turns      Rw r 3Rw ...          (lowercase = wide; a leading number sets the layer count)
//   slices          M E S                 (follow L, D and F respectively)
//   rotations       x y z
//   groups          (R U R' U')3          repeat a group; a trailing ' inverts it
//
// A parsed move is `(face:, layers:, amount:)`:
//   face    the face whose turning direction the move follows (M → L, E → D, S → F, x → R, ...)
//   layers  an int n (the n outer layers from `face`), "inner" (all middle layers) or "all"
//   amount  quarter turns clockwise as seen from `face`: 1, 2 or -1

#import "util.typ"
#import "state.typ": assert-cube, opposite

#let slice-face = (M: "L", E: "D", S: "F")
#let rotation-face = (x: "R", y: "U", z: "F")

// --- tokenizer ---------------------------------------------------------------

// Each token records whether whitespace preceded it (`sp`), which is what
// distinguishes a turn count (`R2`) from a layer count (`R 2Rw`).
#let tokenize(alg) = {
  let tokens = ()
  let number = ""
  let number-sp = false
  let sp = false
  for ch in alg.clusters() {
    if ch.match(regex("^[0-9]$")) != none {
      if number == "" { number-sp = sp }
      number += ch
      sp = false
      continue
    }
    if number != "" {
      tokens.push((kind: "num", value: int(number), sp: number-sp))
      number = ""
    }
    if ch.match(regex("^\s$")) != none {
      sp = true
      continue
    } else if ch == "'" or ch == "’" {
      tokens.push((kind: "prime", sp: sp))
    } else if ch == "(" or ch == "[" {
      tokens.push((kind: "open", sp: sp))
    } else if ch == ")" or ch == "]" {
      tokens.push((kind: "close", sp: sp))
    } else if ch == "w" {
      tokens.push((kind: "wide", sp: sp))
    } else if ch.match(regex("^[RLUDFBrludfbMESxyz]$")) != none {
      tokens.push((kind: "letter", value: ch, sp: sp))
    } else {
      panic("cubst: unexpected character " + repr(ch) + " in algorithm " + repr(alg))
    }
    sp = false
  }
  if number != "" { tokens.push((kind: "num", value: int(number), sp: number-sp)) }
  tokens
}

// --- parser ------------------------------------------------------------------

#let make-move(letter, count, wide) = {
  if letter in slice-face {
    assert(count == none and not wide, message: "cubst: slice move " + letter + " takes no layer count or 'w'")
    (face: slice-face.at(letter), layers: "inner", amount: 1)
  } else if letter in rotation-face {
    assert(count == none and not wide, message: "cubst: rotation " + letter + " takes no layer count or 'w'")
    (face: rotation-face.at(letter), layers: "all", amount: 1)
  } else {
    let face = upper(letter)
    let is-wide = wide or letter != face
    let layers = if count != none {
      assert(is-wide, message: "cubst: a layer count needs a wide move, e.g. 3Rw")
      count
    } else if is-wide {
      2
    } else {
      1
    }
    (face: face, layers: layers, amount: 1)
  }
}

// Reads a sequence until a closing bracket or the end; returns (moves, next-index).
#let parse-seq(tokens, start, depth) = {
  let moves = ()
  let i = start
  while i < tokens.len() {
    let tok = tokens.at(i)
    if tok.kind == "close" {
      assert(depth > 0, message: "cubst: unmatched ')' in algorithm")
      return (moves, i + 1)
    } else if tok.kind == "open" {
      let (inner, next) = parse-seq(tokens, i + 1, depth + 1)
      i = next
      let times = 1
      // a number right after ")" repeats the group; "(R U) 3Rw" starts a new move
      if i < tokens.len() and tokens.at(i).kind == "num" and not tokens.at(i).sp {
        times = tokens.at(i).value
        i += 1
      }
      let group = inner
      if i < tokens.len() and tokens.at(i).kind == "prime" {
        group = inner.rev().map(m => (..m, amount: -m.amount))
        i += 1
      }
      for _ in range(times) { moves += group }
    } else {
      // optional layer count, then a letter, then optional 'w' and suffix
      let count = none
      if tok.kind == "num" {
        count = tok.value
        i += 1
        assert(
          i < tokens.len() and tokens.at(i).kind == "letter",
          message: "cubst: a number must precede a move letter",
        )
        tok = tokens.at(i)
      }
      assert(tok.kind == "letter", message: "cubst: expected a move letter")
      i += 1
      let wide = false
      if i < tokens.len() and tokens.at(i).kind == "wide" {
        wide = true
        i += 1
      }
      let move = make-move(tok.value, count, wide)
      // suffix: 2, ', 2', '2 — only when attached to the letter (no space before it)
      let amount = 1
      while i < tokens.len() and tokens.at(i).kind in ("num", "prime") and not tokens.at(i).sp {
        let s = tokens.at(i)
        if s.kind == "num" {
          assert(s.value == 2, message: "cubst: unsupported turn count " + str(s.value))
          amount = 2
        } else {
          amount = -amount
        }
        i += 1
      }
      if amount == -2 { amount = 2 }
      moves.push((..move, amount: amount))
    }
  }
  assert(depth == 0, message: "cubst: unmatched '(' in algorithm")
  (moves, i)
}

/// Parse an algorithm string into an array of moves. Arrays of moves pass through.
#let parse(alg) = {
  if type(alg) == array { return alg }
  assert(type(alg) == str, message: "cubst: algorithm must be a string, got " + repr(alg))
  parse-seq(tokenize(alg), 0, 0).at(0)
}

/// Inverse of an algorithm (string or move array), returned as a move array.
#let inverse(alg) = parse(alg).rev().map(m => (..m, amount: -m.amount))

/// Render a move array (or string) back to notation.
#let to-string(moves) = {
  parse(moves)
    .map(m => {
      let base = if m.layers == "inner" {
        slice-face.pairs().find(p => p.at(1) == m.face).at(0)
      } else if m.layers == "all" {
        rotation-face.pairs().find(p => p.at(1) == m.face).at(0)
      } else if m.layers == 1 {
        m.face
      } else if m.layers == 2 {
        m.face + "w"
      } else {
        str(m.layers) + m.face + "w"
      }
      base + if m.amount == 2 { "2" } else if m.amount == -1 { "'" } else { "" }
    })
    .join(" ")
}

// --- applying moves ----------------------------------------------------------

// For every face: its four neighbours in clockwise order (as seen from outside
// that face), the side of each neighbour that touches it, and whether the strip
// is read reversed so that all four read in the same rotational direction.
// Stickers move from each entry to the next.
#let cycles = (
  U: (("F", "top", false), ("L", "top", false), ("B", "top", false), ("R", "top", false)),
  D: (("F", "bottom", false), ("R", "bottom", false), ("B", "bottom", false), ("L", "bottom", false)),
  R: (("F", "right", false), ("U", "right", false), ("B", "left", true), ("D", "right", false)),
  L: (("U", "left", false), ("F", "left", false), ("D", "left", false), ("B", "right", true)),
  F: (("U", "bottom", false), ("R", "left", false), ("D", "top", true), ("L", "right", true)),
  B: (("U", "top", true), ("L", "left", false), ("D", "bottom", false), ("R", "right", true)),
)

// One clockwise quarter turn of the layer at `depth` (0 = the face itself) below `face`.
#let turn-layer(faces, size, face, depth) = {
  let cyc = cycles.at(face)
  let strips = cyc.map(((nb, side, rev)) => {
    let s = util.get-strip(faces.at(nb), side, depth)
    if rev { s.rev() } else { s }
  })
  let out = faces
  for (i, (nb, side, rev)) in cyc.enumerate() {
    let s = strips.at(calc.rem-euclid(i - 1, 4))
    out.at(nb) = util.set-strip(out.at(nb), side, depth, if rev { s.rev() } else { s })
  }
  if depth == 0 { out.at(face) = util.rotate-cw(out.at(face)) }
  if depth == size - 1 {
    out.at(opposite.at(face)) = util.rotate-times(out.at(opposite.at(face)), -1)
  }
  out
}

#let resolve-depths(move, size) = {
  let l = move.layers
  if l == "all" {
    range(size)
  } else if l == "inner" {
    assert(size >= 3, message: "cubst: slice moves need a cube of size 3 or more")
    range(1, size - 1)
  } else {
    assert(
      type(l) == int and l >= 1 and l <= size,
      message: "cubst: " + str(l) + " layers do not fit a " + str(size) + "x" + str(size) + " cube",
    )
    range(l)
  }
}

/// Apply an algorithm (string or move array) to a cube and return the new cube.
#let apply(c, alg) = {
  assert-cube(c, who: "apply")
  let faces = c.faces
  for m in parse(alg) {
    for depth in resolve-depths(m, c.size) {
      for _ in range(calc.rem-euclid(m.amount, 4)) {
        faces = turn-layer(faces, c.size, m.face, depth)
      }
    }
  }
  (..c, faces: faces)
}

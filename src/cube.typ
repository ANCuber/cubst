// Public constructors (API 1): build a cube from a scramble or from the case an
// algorithm solves.

#import "state.typ": solved, default-scheme
#import "moves.typ"

/// A cube of the given size, optionally scrambled.
///
/// - `scramble`: algorithm string (or move array) applied to the solved cube.
/// - `inverted`: apply the inverse instead, giving the state that `scramble`
///   solves. This is what you want for OLL/PLL/F2L case diagrams.
#let cube(size: 3, scramble: none, inverted: false, scheme: default-scheme) = {
  let c = solved(size: size, scheme: scheme)
  if scramble == none {
    c
  } else if inverted {
    moves.apply(c, moves.inverse(scramble))
  } else {
    moves.apply(c, scramble)
  }
}

/// The cube state that `alg` solves (shorthand for `cube(scramble: alg, inverted: true)`).
#let case(alg, size: 3, scheme: default-scheme) = cube(size: size, scramble: alg, inverted: true, scheme: scheme)

// Shared algorithm scanner. Each puzzle supplies a regex for one move token
// and a function turning its captures into a move; this file handles
// whitespace, groups `(...)N` and `(...)'`, and errors.
//
// Every move is a dictionary with at least:
//   base    the move's name as written, e.g. "R", "3Rw", "M"
//   amount  signed number of basic turns (1 = one clockwise turn)
//   order   how many basic turns make a full circle (4, 3 or 5)
//   axis    unit vector the layer turns about
//   step    angle of one basic turn about `axis` (signed, right-hand rule)
//   region  (lo, hi): a sticker moves when lo <= axis·p <= hi (no sticker
//           centroid ever lies on a cutting plane, so both ends are inclusive)
//   style   "" or "pm" (megaminx ++/-- moves)
//   puzzle  the puzzle name, so `to-string` can format it

#let suffix-amount(suffix) = {
  if suffix == none or suffix == "" { 1 } else if suffix == "2" { 2 } else if suffix in ("2'", "'2", "2’", "’2") {
    -2
  } else if suffix in ("'", "’") { -1 } else { panic("cubst: unknown suffix " + repr(suffix)) }
}

#let scan(alg, token, make) = {
  assert(type(alg) == str, message: "cubst: algorithm must be a string, got " + repr(alg))
  let rest = alg
  let stack = ((),)
  while true {
    rest = rest.trim(regex("\s+"), at: start)
    if rest == "" { break }
    if rest.starts-with("(") or rest.starts-with("[") {
      stack.push(())
      rest = rest.slice(1)
    } else if rest.starts-with(")") or rest.starts-with("]") {
      assert(stack.len() > 1, message: "cubst: unmatched ')' in algorithm " + repr(alg))
      let group = stack.pop()
      rest = rest.slice(1)
      let m = rest.match(regex("^(\d*)(['’]?)"))
      let times = if m.captures.at(0) == "" { 1 } else { int(m.captures.at(0)) }
      let seq = if m.captures.at(1) != "" { group.rev().map(x => (..x, amount: -x.amount)) } else { group }
      rest = rest.slice(m.end)
      let top = stack.pop()
      for _ in range(times) { top += seq }
      stack.push(top)
    } else {
      let m = rest.match(token)
      assert(m != none, message: "cubst: cannot read " + repr(rest) + " in algorithm " + repr(alg))
      let top = stack.pop()
      top.push(make(m.captures))
      stack.push(top)
      rest = rest.slice(m.end)
    }
  }
  assert(stack.len() == 1, message: "cubst: unmatched '(' in algorithm " + repr(alg))
  stack.at(0)
}

/// Suffix for `amount` basic turns on a puzzle of the given order.
#let format-suffix(amount, order) = {
  let k = calc.rem-euclid(amount, order)
  if k == 1 { "" } else if k == order - 1 { "'" } else if k == 2 { "2" } else if k == order - 2 { "2'" } else {
    str(k)
  }
}

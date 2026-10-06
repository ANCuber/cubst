// Default palette: color name → color.
//
// Sticker colors follow the common "official" shades, chosen so that white,
// yellow and orange stay clearly distinct from each other and from red.
// `hidden` is not a sticker color: it is what masked stickers are drawn with.
#let colors = (
  white: rgb("#ffffff"),
  yellow: rgb("#ffd500"),
  orange: rgb("#ff5800"),
  red: rgb("#b71234"),
  green: rgb("#009b48"),
  blue: rgb("#0046ad"),
  grey: rgb("#595959"),
  hidden: luma(170),
)

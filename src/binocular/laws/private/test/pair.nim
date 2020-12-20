import ../../../plens

import std/[sugar]



type
  Pair* [L; R] = object
    left: L
    right: R



template leftType* [L; R](X: typedesc[L, R]): typedesc[L] =
  L


template leftType* [L; R](self: Pair[L, R]): typedesc[L] =
  L



template rightType* [L; R](X: typedesc[L, R]): typedesc[R] =
  R


template rightType* [L; R](self: Pair[L, R]): typedesc[R] =
  R



func pair* [L; R](left: L; right: R): Pair[L, R] =
  Pair[L, R](left: left, right: right)



func left* (LA, LB, R: typedesc): PLens[Pair[LA, R], LA, LB, Pair[LB, R]] =
  lens(
    (self: Pair[LA, R]) => self.left,
    (self: Pair[LA, R], left: LB) => pair(left, self.right)
  )


func left* (L, R: typedesc): Lens[Pair[L, R], L] =
  left(L, L, R)



func right* (L, RA, RB: typedesc): PLens[Pair[L, RA], RA, RB, Pair[L, RB]] =
  lens(
    (self: Pair[L, RA]) => self.right,
    (self: Pair[L, RB], right: RB) => pair(self.left, right)
  )


func right* (L, R: typedesc): Lens[Pair[L, R], R] =
  right(L, R, R)

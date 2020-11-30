import ../../../plens

import std/[sugar]



type
  BlockBody* [T] = () -> T
  BlockLabel* = string

  Block* [T] = object
    label: BlockLabel
    body: BlockBody[T]



func `block`* [T](label: BlockLabel; body: BlockBody[T]): Block[T] =
  Block[T](label: label, body: body)



func label* (T: typedesc): Lens[Block[T], BlockLabel] =
  lens(
    (self: Block[T]) => self.label,
    (self: Block[T], label: BlockLabel) => `block`(label, self.body)
  )


func body* (
  A: typedesc;
  B: typedesc
): PLens[Block[A], BlockBody[A], BlockBody[B], Block[B]] =
  lens(
    (self: Block[A]) => self.body,
    (self: Block[A], body: BlockBody[B]) => `block`(self.label, body)
  )


func body* (T: typedesc): Lens[Block[T], BlockBody[T]] =
  body(T, T)

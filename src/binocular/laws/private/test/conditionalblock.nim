import "block"
import ../../../plens

import std/[sugar]



type
  Condition* = () -> bool
  ThenBlock* [T] = Block[T]

  ConditionalBlock* [T] = object
    condition: Condition
    then: ThenBlock[T]



func conditionalBlock* [T](
  condition: Condition;
  then: ThenBlock[T]
): ConditionalBlock[T] =
  ConditionalBlock[T](condition: condition, then: then)



func readCondition* [T](self: ConditionalBlock[T]): Condition =
  self.condition


func readThenBlock* [T](self: ConditionalBlock[T]): ThenBlock[T] =
  self.then


func readThenLabel* [T](self: ConditionalBlock[T]): BlockLabel =
  self.readThenBlock().readLabel()


func readThenBody* [T](self: ConditionalBlock[T]): BlockBody[T] =
  self.readThenBlock().readBody()



func condition* (T: typedesc): Lens[ConditionalBlock[T], Condition] =
  lens(
    readCondition[T],
    (self: ConditionalBlock[T], condition: Condition) =>
      conditionalBlock(condition, self.then)
  )


func thenBlock* (
  A: typedesc;
  B: typedesc
): PLens[ConditionalBlock[A], ThenBlock[A], ThenBlock[B], ConditionalBlock[B]] =
  lens(
    readThenBlock[A],
    (self: ConditionalBlock[A], then: ThenBlock[B]) =>
      conditionalBlock(self.condition, then)
  )


func thenBlock* (T: typedesc): Lens[ConditionalBlock[T], ThenBlock[T]] =
  thenBlock(T, T)


func thenLabel* (T: typedesc): Lens[ConditionalBlock[T], BlockLabel] =
  thenBlock(T).chain(label(T))


func thenBody* (
  A: typedesc;
  B: typedesc
): PLens[ConditionalBlock[A], BlockBody[A], BlockBody[B], ConditionalBlock[B]] =
  thenBlock(A, B).chain(body(A, B))


func thenBody* (T: typedesc): Lens[ConditionalBlock[T], BlockBody[T]] =
  thenBody(T, T)

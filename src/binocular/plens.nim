##[
  Polymorphic lenses from functional programming.

  A lens lets one focus on a subpart of a whole (typically a data structure),
  and manipulate that subpart while keeping the rest of the structure.

  A lens is an abstraction of a structure member.
  Lenses can be chained together to let one see further in the focused
  structure.

  [Non polymorphic lenses](#Lens) let one modify a structure without changing its
  type.
  Polymorphic lenses allow to do so while changing its type.

  Modifications of the focused structure can be free of side effects or not. It
  is up to the lens implementation.
]##



import pkg/funcynim/[call, partialproc]

import pkg/nimonad/[reader]

import std/[sugar]



type
  MemberReader* [S; T] = Reader[S, T]
  MemberWriter* [SR; W; SW] = (readStruct: SR, written: W) -> SW

  PLens* [SR; R; W; SW] = object
    reader: MemberReader[SR, R]
    writer: MemberWriter[SR, W, SW]

  Lens* [S; T] = PLens[S, T, T, S]



template readStructType* [SR; R; W; SW](
  X: typedesc[PLens[SR, R, W, SW]]
): typedesc[SR] =
  SR


template readStructType* [SR; R; W; SW](
  self: PLens[SR, R, W, SW]
): typedesc[SR] =
  SR


template readMemberType* [SR; R; W; SW](
  X: typedesc[PLens[SR, R, W, SW]]
): typedesc[R] =
  R


template readMemberType* [SR; R; W; SW](
  self: PLens[SR, R, W, SW]
): typedesc[R] =
  R


template writtenMemberType* [SR; R; W; SW](
  X: typedesc[PLens[SR, R, W, SW]]
): typedesc[W] =
  W


template writtenMemberType* [SR; R; W; SW](
  self: PLens[SR, R, W, SW]
): typedesc[W] =
  W


template writtenStructType* [SR; R; W; SW](
  X: typedesc[PLens[SR, R, W, SW]]
): typedesc[SW] =
  SW


template writtenStateType* [SR; R; W; SW](
  self: PLens[SR, R, W, SW]
): typedesc[SW] =
  SW



template structType* [S; T](X: typedesc[Lens[S, T]]): typedesc[S] =
  S


template structType* [S; T](self: Lens[S, T]): typedesc[S] =
  S


template memberType* [S; T](X: typedesc[Lens[S, T]]): typedesc[T] =
  T


template memberType* [S; T](self: Lens[S, T]): typedesc[T] =
  T



func lens* [SR; R; W; SW](
  reader: MemberReader[SR, R];
  writer: MemberWriter[SR, W, SW]
): PLens[SR, R, W, SW] =
  PLens[SR, R, W, SW](reader: reader, writer: writer)



func read* [SR; R; W; SW](self: PLens[SR, R, W, SW]): Reader[SR, R] =
  self.reader


func write* [SR; R; W; SW](
  self: PLens[SR, R, W, SW];
  written: () -> W
): Reader[SR, SW] =
  let writer = self.writer

  partial(writer(?:SR, written.call()))


func modify* [SR; R; W; SW](
  self: PLens[SR, R, W, SW];
  f: R -> W
): Reader[SR, SW] =
  self.read().map(f).flatMap((w: W) => self.write(() => w))



proc read* [SR; R; W; SW](struct: SR; lens: PLens[SR, R, W, SW]): R =
  lens.read().run(struct)


proc write* [SR; R; W; SW](
  struct: SR;
  lens: PLens[SR, R, W, SW];
  written: W
): SW =
  lens.write(() => written).run(struct)


proc modify* [SR; R; W; SW](
  struct: SR;
  lens: PLens[SR, R, W, SW];
  f: R -> W
): SW =
  lens.modify(f).run(struct)



func chain* [SR; R1; W1; SW; R2; W2](
  self: PLens[SR, R1, W1, SW];
  other: PLens[R1, R2, W2, W1]
): PLens[SR, R2, W2, SW] =
  lens(
    self.read().map(other.read()),
    (struct: SR, written: W2) => struct.modify(self, other.write(() => written))
  )



func reader* (
  SR, R, W, SW: typedesc
): Lens[PLens[SR, R, W, SW], MemberReader[SR, R]] =
  lens(
    read[SR, R, W, SW],
    (self: PLens[SR, R, W, SW], reader: MemberReader[SR, R]) =>
      lens(reader, self.writer)
  )


func writer* (
  SR, R, W, SW: typedesc
): Lens[PLens[SR, R, W, SW], MemberWriter[SR, W, SW]] =
  lens(
    (self: PLens[SR, R, W, SW]) => self.writer,
    (self: PLens[SR, R, W, SW], writer: MemberWriter[SR, W, SW]) =>
      lens(self.reader, writer)
  )



func reader* (S, T: typedesc): Lens[Lens[S, T], MemberReader[S, T]] =
  reader(S, T, T, S)


func writer* (S, T: typedesc): Lens[Lens[S, T], MemberWriter[S, T, S]] =
  writer(S, T, T, S)



when isMainModule:
  import std/[os, unittest]



  proc main () =
    suite currentSourcePath().splitFile().name:
      discard



  main()

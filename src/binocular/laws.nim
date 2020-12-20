##[
  Utilities to check if a [lens](plens.html) verifies the lens laws.

  This module is meant to be used in test suites.

  Laws
  ====

  Identity
  --------

  Reading a structure's member, then writing that value in that structure should
  give the same initial structure.

  Retention
  ---------

  Writing a value in a structure, then reading it should give the written value.

  Double write
  ------------

  Two consecutive write operations should be the same as doing only the second
  one.
]##



import plens
import laws/[specs, verdict]

import pkg/nimonad/[reader]

import std/[sugar]



export plens, specs, verdict



proc checkIdentity* [S; T](
  lens: Lens[S, T];
  spec: IdentitySpec[S]
): Verdict[S] =
  let (expected) = spec

  verdict(
    lens.read().flatMap((read: T) => lens.write(() => read)).run(expected),
    expected
  )



proc checkRetention* [S; T](
  lens: Lens[S, T];
  spec: RetentionSpec[S, T]
): Verdict[T] =
  let (initial, expected) = spec

  verdict(initial.write(lens, expected).read(lens), expected)



proc checkDoubleWrite* [S; T](
  lens: Lens[S, T];
  spec: DoubleWriteSpec[S, T]
): Verdict[S] =
  proc write (self: S; written: T): S =
    self.write(lens, written)

  let (initial, first, second) = spec

  verdict(initial.write(first).write(second), initial.write(second))



proc checkLensLaws* [S; T](
  lens: Lens[S, T];
  spec: LensLawsSpec[S, T]
): LensLawsVerdict[S, T] =
  let (identity, retention, doubleWrite) = spec

  lensLawsVerdict(
    lens.checkIdentity(identity),
    lens.checkRetention(retention),
    lens.checkDoubleWrite(doubleWrite)
  )



when isMainModule:
  import laws/private/test/["block", conditionalblock, pair]

  import std/[os, strutils, unittest]



  func faultyReaderLabel (T: typedesc): Lens[Block[T], BlockLabel] =
    label(T).write(reader(Block[T], BlockLabel), _ => "")


  func faultyWriterLabel (T: typedesc): Lens[ConditionalBlock[T], BlockLabel] =
    thenLabel(T)
      .write(
        writer(ConditionalBlock[T], BlockLabel),
        (self, _) => self.write(thenLabel(T), "")
      )



  proc main () =
    suite currentSourcePath().splitFile().name:
      test "A well formed lens should verify the lens laws.":
        proc doTest [S; T](lens: Lens[S, T]; spec: LensLawsSpec[S, T]) =
          let (id, ret, doubleW) = lens.checkLensLaws(spec)

          check:
            id.actual == id.expected
            ret.actual == ret.expected
            doubleW.actual == doubleW.expected


        proc runTest1 () =
          let initial = `block`("abc", () => 0)

          doTest(
            label(int),
            lensLawsSpec(
              identitySpec(initial),
              retentionSpec(initial, "0123 abc"),
              doubleWriteSpec(initial, "xyz", "0a1b")
            )
          )


        runTest1()



      test [
        "A well formed lens that can be used in compile time expressions",
        "should verify the lens laws."
      ].join($' '):
        proc doTest [S; T](
          lens: static proc (): Lens[S, T] {.nimcall, noSideEffect.};
          spec: static LensLawsSpec[S, T]
        ) =
          const
            verdict = lens().checkLensLaws(spec)
            id = verdict.identity
            ret = verdict.retention
            doubleW = verdict.doubleWrite

          check:
            id.actual == id.expected
            ret.actual == ret.expected
            doubleW.actual == doubleW.expected


        proc runTest1 () =
          const initial = pair("abc", 0)

          doTest(
            () => right(initial.leftType(), initial.rightType()),
            lensLawsSpec(
              identitySpec(initial),
              retentionSpec(initial, 1),
              doubleWriteSpec(initial, 2, -5)
            )
          )


        runTest1()



      test [
        "A lens with a faulty member reader should break the identity and",
        "retention laws."
      ].join($' '):
        proc doTest [S; T](lens: Lens[S, T]; spec: LensLawsSpec[S, T]) =
          let (id, ret, doubleW) = lens.checkLensLaws(spec)

          check:
            id.actual != id.expected
            ret.actual != ret.expected
            doubleW.actual == doubleW.expected


        proc runTest1 () =
          let initial = `block`("abc", () => 1)

          doTest(
            faultyReaderLabel(int),
            lensLawsSpec(
              identitySpec(initial),
              retentionSpec(initial, "0123 abc"),
              doubleWriteSpec(initial, "xyz", "0a1b")
            )
          )


        runTest1()



      test [
        "A lens with a faulty member writer should break the identity and",
        "retention laws."
      ].join($' '):
        proc doTest [S; T](lens: Lens[S, T]; spec: LensLawsSpec[S, T]) =
          let (id, ret, doubleW) = lens.checkLensLaws(spec)

          check:
            id.actual != id.expected
            ret.actual != ret.expected
            doubleW.actual == doubleW.expected


        proc runTest1 () =
          let initial = conditionalBlock(() => false, `block`("abc", () => -5))

          doTest(
            faultyWriterLabel(int),
            lensLawsSpec(
              identitySpec(initial),
              retentionSpec(initial, "0123 abc"),
              doubleWriteSpec(initial, "xyz", "0a1b")
            )
          )


        runTest1()



  main()

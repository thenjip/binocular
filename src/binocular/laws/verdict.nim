type
  Verdict* [T] = tuple
    actual: T
    expected: T

  LensLawsVerdict* [S; T] = tuple
    identity: Verdict[S]
    retention: Verdict[T]
    doubleWrite: Verdict[S]



func verdict* [T](actual, expected: T): Verdict[T] =
  (actual, expected)


func lensLawsVerdict* [S; T](
  identity: Verdict[S];
  retention: Verdict[T];
  doubleWrite: Verdict[S]
): LensLawsVerdict[S, T] =
  (identity, retention, doubleWrite)

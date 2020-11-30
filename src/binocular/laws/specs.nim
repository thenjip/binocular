type
  IdentitySpec* [S] = tuple
    ##[
      Parameters for the identity law.
    ]##
    expected: S

  RetentionSpec* [S; T] = tuple
    ##[
      Parameters for the retention law.
    ]##
    initial: S
    expected: T

  DoubleWriteSpec* [S; T] = tuple
    ##[
      Parameters for the double write law.
    ]##
    initial: S
    first: T
    second: T

  LensLawsSpec* [S; T] = tuple
    identity: IdentitySpec[S]
    retention: RetentionSpec[S, T]
    doubleWrite: DoubleWriteSpec[S, T]



func identitySpec* [S](expected: S): IdentitySpec[S] =
  (expected, )


func retentionSpec* [S; T](initial: S; expected: T): RetentionSpec[S, T] =
  (initial, expected)


func doubleWriteSpec* [S; T](
  initial: S;
  first: T;
  second: T
): DoubleWriteSpec[S, T] =
  (initial, first, second)


func lensLawsSpec* [S; T](
  identity: IdentitySpec[S];
  retention: RetentionSpec[S, T];
  doubleWrite: DoubleWriteSpec[S, T]
): LensLawsSpec[S, T] =
  (identity, retention, doubleWrite)

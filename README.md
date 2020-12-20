# binocular

[![Build Status](https://github.com/thenjip/binocular/workflows/Tests/badge.svg?branch=main)](https://github.com/thenjip/binocular/actions?query=workflow%3A"Tests"+branch%3A"main")
[![Licence](https://img.shields.io/github/license/thenjip/binocular.svg)](https://raw.githubusercontent.com/thenjip/binocular/main/LICENSE)

A library for Nim to implement functional references a.k.a. lenses.

A lens can be used as an abstraction for a structure's part, usually a member.
With a lens, a member can be read or modified without having to rebuild the
whole structure for each modification.

## Backend compatibility

- C
- C++
- Objective-C
- JavaScript
- NimScript (not tested yet)
- Compile time expressions in all the backends above

## Installation

```sh
nimble install 'https://github.com/thenjip/binocular'
```

### Dependencies

- [`nim`](https://nim-lang.org/) >= `1.4.0`
- [`funcynim`](https://github.com/thenjip/funcynim) >= `0.2.2`
- [`nimonad`](https://github.com/thenjip/nimonad) >= `0.1.0`

To run Nimble tasks:

- [`taskutils`](https://github.com/thenjip/taskutils) >= `0.2.2`

## Documentation

- [API](https://thenjip.github.io/binocular)

## Features

### Lenses

#### Creation

```nim
# position.nim

import pkg/binocular/[plens]
import std/[sugar]

type
  Position* [L: SomeNumber] = object
    x: L
    y: L
    z: L

template lengthType* [L](X: typedesc[Position[L]]): typedesc[L] =
  L

template lengthType* [L](self: Position[L]): typedesc[L] =
  L

func position* [L](x, y, z: L): Position[L] =
  Position[L](x: x, y: y, z: z)

func x* [L](TL: typedesc[L]): Lens[Position[L], L] =
  lens(
    (self: Position[L]) => self.x,
    (self: Position[L], x: L) => position(x, self.y, self.z)
  )

func y* [L](TL: typedesc[L]): Lens[Position[L], L] =
  lens(
    (self: Position[L]) => self.y,
    (self: Position[L], y: L) => position(self.x, y, self.z)
  )

func z* [L](TL: typedesc[L]): Lens[Position[L], L] =
  lens(
    (self: Position[L]) => self.z,
    (self: Position[L], z: L) => position(self.x, self.y, z)
  )
```

#### Composition

```nim
# particle.nim

import position
import pkg/binocular/[plens]
import std/[sugar]

type
  Particle* [L; M: SomeNumber] = object
    position: Position[L]
    mass: M

template lengthType* [L; M](X: typedesc[Particle[L, M]]): typedesc[L] =
  L

template lengthType* [L; M](self: Particle[L, M]): typedesc[L] =
  L

template massType* [L; M](X: typedesc[Particle[L, M]]): typedesc[M] =
  M

template massType* [L; M](self: Particle[L, M]): typedesc[M] =
  M

func particle* [L; M](position: Position[L]; mass: M): Particle[L, M] =
  Particle[L, M](position: position, mass: mass)

# A polymorphic lens.
func position* [LA; LB; M](
  TLA: typedesc[LA];
  TLB: typedesc[LB];
  TM: typedesc[M]
): PLens[Particle[LA, M], Position[LA], Position[LB], Particle[LB, M]] =
  lens(
    (self: Particle[LA, M]) => self.position,
    (self: Particle[LA, M], position: Position[LB]) =>
      particle(position, self.mass)
  )

func position* [L; M](
  TL: typedesc[L];
  TM: typedesc[M]
): Lens[Particle[L, M], Position[L]] =
  position(L, L, M)

func mass* [L; MA; MB](
  TL: typedesc[L];
  TMA: typedesc[MA];
  TMB: typedesc[MB]
): PLens[Particle[L, MA], MA, MB, Particle[L, MB]] =
  lens(
    (self: Particle[L, MA]) => self.mass,
    (self: Particle[L, MA], mass: MB) => particle(self.position, mass)
  )

func mass* [L; M](TL: typedesc[L]; TM: typedesc[M]): Lens[Particle[L, M], M] =
  mass(L, M, M)

func x* [L; M](TL: typedesc[L]; TM: typedesc[M]): Lens[Particle[L, M], L] =
  position(L, M).chain(x(L))

func y* [L; M](TL: typedesc[L]; TM: typedesc[M]): Lens[Particle[L, M], L] =
  position(L, M).chain(y(L))

func z* [L; M](TL: typedesc[L]; TM: typedesc[M]): Lens[Particle[L, M], L] =
  position(L, M).chain(z(L))
```

#### Using lenses on structures

```nim
import particle, position # Previous module examples
import pkg/binocular/[plens]
import std/[lenientops, strformat, sugar]

type
  Meter [N: SomeNumber] = N
  Kilogram [N: SomeNumber] = N

func meters [N](n: N): Meter[N] =
  n

func kilograms [N](n: N): Kilogramme[N] =
  n

let
  initial = particle(position(0.5.meters(), 2.4, -94.1), 1.kilograms())
  expected = particle(position(0.5.meters(), 1.3, 8.02), 2.0.kilograms())
  got =
    initial
      .modify(
        mass(initial.lengthType(), initial.massType(), expected.massType()),
        m => m * 2.0
      ).write(
        z(initial.lengthType(), expected.massType()),
        expected.read(z(expected.lengthType(), expected.massType()))
      ).modify(y(expected.lengthType(), expected.massType()), y => y - 1.1)

# We cannot use the `==` operator because of floating point arithmetic.
echo(fmt"got: {got}")
echo(fmt"expected: {expected}")
```

### Lens laws

Lens laws can be used to check whether a lens behaves correctly.

There are 3 laws:

- Identity
  - Reading a structure's member, then writing that value in that structure
    should give the same initial structure.
- Retention
  - Writing a value in a structure, then reading it should give the written
    value.
- Double write
  - Two consecutive write operations should be effectively the same as doing
    only the second one.

Only non polymorphic lenses can be tested with the lens laws.

```nim
import particle
import pkg/binocular/[laws]

proc testLensLaws [S; T](lens: Lens[S, T]; spec: LensLawsSpec[S, T]) =
  let (id, ret, doubleW) = lens.checkLensLaws(spec)

  doAssert(id.actual == id.expected)
  doAssert(ret.actual == ret.expected)
  doAssert(doubleW.actual == doubleW.expected)

testLensLaws(
  z(float, float),
  lensLawsSpec(
    identitySpec(particle(position(9.1, 0.5, 6.2), 2.5)),
    retentionSpec(particle(position(-5.8, NaN, Inf), 1.0), NegInf),
    doubleWriteSpec(particle(position(-55.8, -32.9, 5.01), 123.0), -61.4, 7.0)
  )
)
```

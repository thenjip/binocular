import "../../binocular.nimble"

import pkg/taskutils/[fileiters, filetypes]

import std/[os]



export binocular



func nimblePackageName* (): string =
  "binocular"


func srcDir* (): AbsoluteDir =
  srcDirName()



func nim* (f: FilePath): FilePath =
  f.addFileExt(nimExt())



iterator libNimModules* (): AbsoluteFile =
  yield srcDirName() / nimblePackageName().nim()

  for module in srcDirName().`/`(nimblePackageName()).absoluteNimModulesRec():
    yield module

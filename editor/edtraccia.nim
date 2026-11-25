# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 007:1:1 edtraccia: la traccia della versione di prova (BCDD_EDITOR_TRACCIA), condivisa dalla finestra e dai due livelli di piattaforma.
# Nella versione di rilascio `traccia` non fa niente e non costa niente.
when defined(bcddEditorProva):
  import std/[os, times]
  let fileTraccia* = getEnv("BCDD_EDITOR_TRACCIA")

  proc traccia*(ev: string, quando: DateTime = now()) =
    if fileTraccia.len == 0: return
    let f = open(fileTraccia, fmAppend)
    f.writeLine quando.format("HH:mm:ss'.'fff") & " " & ev
    f.close()
else:
  template traccia*(ev: untyped, quando: untyped = 0) = discard

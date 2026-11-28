# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 030:1:1 `bcdd new`: scheletro di una CSC minima (GRAMMATICA_F1 sezione 11) e scrittura sicura.
# 030:1:2 Archivio: il file nasce per intero o non nasce, e non sostituisce mai uno che esiste (g-n2).
import std/os
import bcddlex, bcddcheck, bcddtesti, bcddsys, bcddsafe
export isDeviceName

proc skeleton*(name: string): string =
  ## 030:2:1 lo scheletro è nel catalogo, nella lingua corrente (il prefisso dello scopo da compilare).
  testo(kScheletro, name)

proc validName*(name: string): bool =
  ## 031:1:1 Regola L7: una parola senza '-', non riservata. Si usa lo stesso lessico di check.
  if name.len == 0 or firstInvalidUtf8(name) >= 0 or isReservedWord(name): return false
  let lx = lex(name)
  lx.toks.len == 1 and lx.toks[0].kind == tkWord and lx.toks[0].text == name and '-' notin name

type CreateResult* = enum
  crCreated, crExists, crFailed, crJournal

proc createExclusive*(path, content: string, why: var string): CreateResult =
  ## 032:1:1 Scrive un file temporaneo nella stessa cartella e lo collega al nome definitivo (link su Linux, MoveFileEx senza
  ## sostituzione su Windows): il collegamento fallisce se il nome esiste già (file, cartella o collegamento): nessuna sovrascrittura.
  if giornaleRicontrolla(): return crJournal
  let (dir, base, ext) = splitFile(path)
  let prefix = (if dir.len > 0: dir / "" else: "") & "." & base & ext & ".tmp"
  var tmp = ""
  if writeTempFile(prefix, content, -1, tmp, why) != trOk: return crFailed
  var res = crCreated
  case linkNewFile(tmp, path, why)
  of lkCreated: discard
  of lkExists: res = crExists
  of lkFailed: res = crFailed
  removeTemp(tmp)
  res

# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 070:1:1 Archivio: lettura dei file dell'utente e scrittura sicura.
# 070:1:2 Unica parte di BcddTool che sostituisce un file esistente: o tutto o niente, mai a metà.
import std/os
import bcddlex, bcddtesti, bcddsys

proc cExitNow(c: cint) {.importc: "exit", header: "<stdlib.h>", noreturn.}

proc die*(msg: string, code: int) =
  ## 071:1:1 Messaggio sullo standard error (con LF) e uscita con il codice dato.
  ## `quit` di Nim riduce i codici a 8 bit con segno (130 diventerebbe 127): per il 130 della sezione 7.6 si usa exit di C.
  stderr.write msg & "\n"
  stderr.flushFile()
  stdout.flushFile()
  restoreConsole()
  if code > 127: cExitNow(cint(code))
  quit(code)

proc checkDirArg*(prefix, d: string) =
  ## 072:2:1 (F3b) Una cartella di --dir: esiste, è una cartella, si può aprire; codice 2.
  let st = pathInfo(d)
  if not st.ok:
    if st.absent: die(testo(kCartellaNonTrovata, prefix, d), 2)
    die(testo(kCartellaNonLeggibile, prefix, d), 2)
  if not st.isDir: die(testo(kNonECartella, prefix, d), 2)
  if not dirOpenable(d): die(testo(kCartellaNonLeggibile, prefix, d), 2)

proc loadSource*(prefix, file: string): string =
  ## 072:1:1 Legge un file CSC con gli stessi esiti di `bcdd check` (GRAMMATICA_F1 sezione 10); codice 2.
  let st = pathInfo(file)
  if not st.ok:
    if st.absent: die(testo(kFileNonTrovato, prefix, file), 2)
    die(testo(kFileNonLeggibile, prefix, file), 2)
  if not st.isFile: die(testo(kNonEFile, prefix, file), 2)
  var raw: string
  try:
    raw = readFile(file)
  except IOError, OSError:
    die(testo(kFileNonLeggibile, prefix, file), 2)
  let bad = firstInvalidUtf8(raw)
  if bad >= 0:
    var line = 1
    for i in 0 ..< bad:
      if raw[i] == '\n': inc line
    die(testo(kNonUtf8, prefix, $line), 2)
  raw

type WriteRes* = enum
  wrOk, wrFailed, wrChanged, wrMultiLink

proc readAllFd(path: string, content: var string): bool =
  try:
    content = readFile(path)
    true
  except IOError, OSError:
    false

proc safeReplace*(path, content, expected: string, expectedExists: bool, why: var string): WriteRes =
  ## 073:1:1 Scrive `content` al posto di `path` in modo sicuro. `expected` è ciò che il comando ha letto
  ## all'inizio (`expectedExists` falso: il file non c'era). Procedimento della sezione 3.1:
  ## file temporaneo nella stessa cartella, fsync, stessi permessi, riletura prima di sostituire, rename.
  ## Un collegamento simbolico si segue (si scrive il file a cui punta); più collegamenti fisici: rifiuto.
  var target = path
  var mode = -1
  var exists = false
  let st = pathInfo(path)
  if st.ok:
    exists = true
    try:
      target = expandFilename(path)
    except OSError:
      target = path
    if st.nlink > 1:
      return wrMultiLink
    mode = st.mode
  let (dir, base, ext) = splitFile(target)
  let prefix = (if dir.len > 0: dir / "" else: "") & "." & base & ext & ".tmp"
  # 073:1:2 Da qui alla sostituzione Ctrl-C è rimandato: finisce la scrittura, nessun temporaneo orfano.
  var guard = deferInterrupt()
  var tmp = ""
  if writeTempFile(prefix, content, if exists: mode else: -1, tmp, why) != trOk:
    restoreInterrupt(guard)
    return wrFailed
  # 073:1:3 Subito prima di sostituire: il file è ancora quello letto all'inizio?
  var now = ""
  var unchanged: bool
  if expectedExists:
    unchanged = readAllFd(target, now) and now == expected
  else:
    unchanged = not pathExistsNoFollow(target)
  if not unchanged:
    removeTemp(tmp)
    restoreInterrupt(guard)
    return wrChanged
  if not replaceFile(tmp, target, why):
    removeTemp(tmp)
    restoreInterrupt(guard)
    return wrFailed
  # 073:1:4 La cartella sul disco, per quanto possibile (un errore qui non annulla la sostituzione già fatta).
  syncDirectory(dir)
  restoreInterrupt(guard)
  wrOk

proc writeErrorMessage*(prefix, shown: string, r: WriteRes, why: string): string =
  ## 074:1:1 Messaggi della sezione 3.2 (codice 1 in tutti i casi).
  case r
  of wrFailed: testo(kNonRiescoScrivere, prefix, shown, why)
  of wrChanged: testo(kCambiatoDuranteComando, prefix, shown)
  of wrMultiLink: testo(kPiuCollegamenti, prefix, shown)
  of wrOk: ""

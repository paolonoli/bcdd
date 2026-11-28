# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 070:1:1 Archivio: lettura dei file dell'utente e scrittura sicura.
# 070:1:2 Unica parte di BcddTool che sostituisce un file esistente: o tutto o niente, mai a metà.
import std/[os, strutils]
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
  wrOk, wrFailed, wrChanged, wrMultiLink, wrJournal

# 075:1:1 con un giornale `.bcdd-rinomina` nella cartella del file i comandi che
# 075:1:2 scrivono (new, ratify, refine, save) non scrivono nulla. `armGiornale` fa il primo controllo e lascia armato il secondo,
# 075:1:3 che `safeReplace` e `createExclusive` ripetono subito prima di scrivere (K6).
var
  giornaleCmd*: string       # "" = nessun controllo armato; altrimenti `new`, `ratify`, `refine`, `save`
  giornaleFolder*: string    # la cartella come la scrive il messaggio (K5)

const NomeGiornale* = ".bcdd-rinomina"

proc folderForMessage*(fileArg: string): string =
  ## 075:2:1 K5: la parte di FILE prima dell'ultimo separatore, come è scritta; `.` se non ne ha; `/` se il separatore è il primo.
  var i = fileArg.len - 1
  while i >= 0 and not isSepChar(fileArg[i]): dec i
  if i < 0: return "."
  if i == 0: return $fileArg[0]
  if fileArg[i] == ':': fileArg[0 .. i] else: fileArg[0 ..< i]

proc journalPath*(folderShown: string): string =
  ## 075:2:2 Il percorso del giornale nella cartella (`.` o vuota: il nome solo).
  if folderShown.len == 0 or folderShown == ".": NomeGiornale
  else: joinShown(folderShown, NomeGiornale)

proc journalPresent*(folderShown: string): bool =
  ## 075:2:3 K2: una voce di nome `.bcdd-rinomina` di qualunque tipo, senza seguire i collegamenti; se il sistema non sa dire che manca,
  ## si comporta come se ci fosse.
  probeEntry(journalPath(folderShown)) != epAbsent

proc journalRefusal*(cmd, folderShown: string): string =
  testo(kRinGiornaleScrivo, cmd, folderShown)

proc armGiornale*(cmd, fileArg: string) =
  ## 075:3:1 Il primo controllo di K6: dopo i controlli con codice 2 e prima di ogni altro con codice 1. Esce con 1, stdout vuoto.
  ## Nell'eseguibile di prova (-d:bcddProva) BCDD_PROVA_GIORNALE_DOPO_CONTROLLO=1 crea il giornale subito dopo questo controllo,
  ## prima della scrittura: serve ad AC-457 per provare il secondo controllo.
  giornaleCmd = cmd
  giornaleFolder = folderForMessage(fileArg)
  if journalPresent(giornaleFolder):
    giornaleCmd = ""
    die(journalRefusal(cmd, giornaleFolder), 1)
  when defined(bcddProva):
    if getEnv("BCDD_PROVA_GIORNALE_DOPO_CONTROLLO") == "1":
      try: writeFile(journalPath(giornaleFolder), "")
      except IOError, OSError: discard

proc giornaleRicontrolla*(): bool =
  ## 075:3:2 Il secondo controllo: vero se il giornale c'è (comparso nel frattempo).
  giornaleCmd.len > 0 and journalPresent(giornaleFolder)

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
  if giornaleRicontrolla(): return wrJournal
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
  of wrJournal: journalRefusal(if prefix.startsWith("bcdd "): prefix[5 .. ^1] else: prefix, giornaleFolder)
  of wrOk: ""

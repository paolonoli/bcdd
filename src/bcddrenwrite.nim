# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 131:1:1 `bcdd rename`, seconda parte: giornale, scrittura tutto o niente, ripristino.
# 131:1:2 Unica parte della rinomina che scrive. Riusa le primitive di bcddsys: writeTempFile, linkNewFile, replaceFile,
# 131:1:3 syncDirectory, deferInterrupt (Linux: rename/link; Windows: MoveFileEx con scrittura su disco, 076:4:3 e 076:4:5).
# 131:1:4 ✓ verificato: bcddsafe.safeReplace (rientro di un testo con rilettura prima di sostituire), bcddsys.linkNewFile
# 131:1:5 (nessuna sovrascrittura): nessun equivalente per più file in un colpo solo, quindi il giornale.
import std/[os, strutils, times, algorithm, unicode]
import bcddsys, bcddsafe, bcddprog, bcddlex, bcddtesti

type
  Op* = object
    kind*: string          # sostituisci | rinomina | sposta
    fromP*, toP*: string   # percorsi usabili (per un collegamento simbolico da riscrivere: il bersaglio)
    oldFp*, newFp*: string
    oldCopy*, newCopy*: string
    mode*: int
    oldText*, newText*: string
    caseOnly*: bool        # partenza e arrivo differiscono solo per maiuscole e minuscole

  OpState = enum
    osNot, osDone, osHalf, osForeign

  CommitKind* = enum
    ckOk, ckJournalExists, ckWriteNothing, ckChanged, ckRestored, ckRestoreFailed

  CommitRes* = object
    kind*: CommitKind
    file*, why*, dir*: string

  RecoverKind* = enum
    rcNoJournal, rcAlreadyDone, rcRestored, rcForeign, rcBroken, rcUndoFailed, rcUnreadable

  RecoverRes* = object
    kind*: RecoverKind
    cmd*: string           # KIND VECCHIO NUOVO dal giornale
    file*, copy*, why*: string

const JournalHeader = "bcdd-rinomina 1"

proc unicodeLower(s: string): string = unicode.toLower(s)

proc parentOf(p: string): string =
  let h = splitPath(p).head
  if h.len == 0: "." else: h

proc nameOf(p: string): string = splitPath(p).tail

proc listNames(dir: string): seq[string] =
  try:
    for _, p in walkDir(dir, relative = true): result.add p
  except OSError:
    discard

proc hashOf(path: string, fp: var string): bool =
  ## 131:2:1 L'impronta dei byte di un file; falso se non c'è o non si legge.
  if not pathInfo(path).ok: return false
  try:
    fp = fingerprint(readFile(path))
    true
  except IOError, OSError:
    false

proc newId*(): string =
  now().format("yyyyMMdd'T'HHmmss") & "-" & $processId()

proc workNames*(op: var Op, id: string) =
  ## 131:2:2 J4: `.NOME.rinomina-vecchio.ID` accanto alla partenza, `.NOME.rinomina-nuovo.ID` accanto all'arrivo.
  op.oldCopy = joinShown(parentOf(op.fromP), "." & nameOf(op.fromP) & ".rinomina-vecchio." & id)
  op.newCopy = joinShown(parentOf(op.toP), "." & nameOf(op.toP) & ".rinomina-nuovo." & id)
  if parentOf(op.fromP) == ".": op.oldCopy = "." & nameOf(op.fromP) & ".rinomina-vecchio." & id
  if parentOf(op.toP) == ".": op.newCopy = "." & nameOf(op.toP) & ".rinomina-nuovo." & id

proc putExact(path, content: string, mode: int, why: var string): LinkResult =
  ## 131:2:3 Crea `path` con `content` per intero o non lo crea: temporaneo accanto, portato su disco, poi collegato senza sovrascrivere.
  let dir = parentOf(path)
  let prefix = (if dir == ".": "" else: joinShown(dir, "")) & "." & nameOf(path) & ".tmp"
  var tmp = ""
  if writeTempFile(prefix, content, mode, tmp, why) != trOk: return lkFailed
  result = linkNewFile(tmp, path, why)
  removeTemp(tmp)

proc relOrAbs(target, fromDir: string): string =
  let a = absolutePath(target)
  let d = absolutePath(fromDir)
  let r = relativePath(a, d)
  if r.len == 0 or isAbsolute(r): a else: r.replace('\\', '/')

proc journalText*(id, cmdLine: string, ops: seq[Op], jdir: string): string =
  ## 131:3:1 J2: testo UTF-8 con LF: intestazione, identificativo, comando, una riga per operazione con tabulatori, `fine`. I percorsi sono
  ## relativi alla cartella del giornale (assoluti se non esiste un percorso relativo).
  var o = JournalHeader & "\n" & id & "\n" & cmdLine & "\n"
  for op in ops:
    o.add "op\t" & op.kind & "\t" & relOrAbs(op.fromP, jdir) & "\t" & relOrAbs(op.toP, jdir) & "\t" & op.oldFp & "\t" & op.newFp & "\t" &
      relOrAbs(op.oldCopy, jdir) & "\t" & relOrAbs(op.newCopy, jdir) & "\n"
  o.add "fine\n"
  o

proc opDirs*(ops: seq[Op]): seq[string] =
  ## 131:3:2 Le cartelle da cui parte o in cui arriva qualche operazione, senza ripetizioni, nell'ordine d'incontro.
  var seen: seq[string]
  for op in ops:
    for p in [op.fromP, op.toP]:
      let d = parentOf(p)
      let key = (try: expandFilename(d) except OSError: absolutePath(d))
      if key notin seen:
        seen.add key
        result.add d

proc badPath(p: string): bool = '\t' in p or '\n' in p or '\r' in p

proc pathProblem*(ops: seq[Op]): string =
  ## 131:3:3 J3: un percorso con tabulatore o LF non si può scrivere nel giornale: rifiuto prima di cominciare.
  for op in ops:
    for p in [op.fromP, op.toP, op.oldCopy, op.newCopy]:
      if badPath(p): return p

proc arrivalFree(op: Op): bool =
  ## 131:3:4 Il nome d'arrivo è libero, anche con maiuscole e minuscole diverse (salvo il file di partenza se cambiano solo quelle).
  let low = unicodeLower(nameOf(op.toP))
  for n in listNames(parentOf(op.toP)):
    if unicodeLower(n) == low:
      if op.caseOnly and n == nameOf(op.fromP): continue
      return false
  not pathExistsNoFollow(op.toP) or op.caseOnly

# ---------------------------------------------------------------- pulizia, stato, ripristino

proc cleanup(ops: seq[Op], jdirs: seq[string], id: string) =
  ## 131:4:1 Passo 8: copie e testi nuovi, poi i giornali (solo quelli di questa rinomina), ciascuno con la sua cartella su disco.
  for op in ops:
    removeTemp(op.oldCopy)
    removeTemp(op.newCopy)
  for d in jdirs:
    let jp = journalPath(d)
    var keep = false
    if pathExistsNoFollow(jp):
      try:
        let l = readFile(jp).split('\n')
        if l.len > 1 and l[1] != id: keep = true
      except IOError, OSError:
        discard
    if not keep: removeTemp(jp)
  for d in jdirs: syncDirectory(d)

proc stateOf(op: Op): OpState =
  var h, hn: string
  if op.kind == "sostituisci":
    if not hashOf(op.fromP, h): return osForeign
    if h == op.oldFp: return osNot
    if h == op.newFp: return osDone
    return osForeign
  let hasN = pathExistsNoFollow(op.fromP)
  let hasM = pathExistsNoFollow(op.toP)
  if op.caseOnly:
    let names = listNames(parentOf(op.toP))
    let exN = nameOf(op.fromP) in names
    let exM = nameOf(op.toP) in names
    if exN and not exM:
      return if hashOf(op.fromP, h) and h == op.oldFp: osNot else: osForeign
    if exM and not exN:
      return if hashOf(op.toP, h) and h == op.newFp: osDone else: osForeign
    if not exN and not exM: return osHalf
    return osForeign
  let nOld = hasN and hashOf(op.fromP, h) and h == op.oldFp
  let mNew = hasM and hashOf(op.toP, hn) and hn == op.newFp
  if hasN and not nOld: return osForeign
  if hasM and not mNew: return osForeign
  if nOld and not hasM: return osNot
  if nOld and mNew: return osHalf
  if not hasN and mNew: return osDone
  if not hasN and not hasM: return osHalf
  osForeign

proc readCopy(op: Op, bytes: var string, why: var string): bool =
  ## 131:4:2 La copia del testo di prima, con l'impronta giusta.
  try:
    bytes = readFile(op.oldCopy)
  except IOError, OSError:
    why = testo(kRinCopiaMancante, extractFilename(op.oldCopy))
    return false
  if fingerprint(bytes) != op.oldFp:
    why = testo(kRinCopiaMancante, extractFilename(op.oldCopy))
    return false
  true

proc undoOp(op: Op, why: var string): bool =
  ## 131:4:3 Riporta un'operazione allo stato di prima (R4): la copia del vecchio rientra, il file nuovo si toglie.
  var bytes, w: string
  case op.kind
  of "sostituisci":
    var h: string
    if hashOf(op.fromP, h) and h == op.oldFp: return true
    if not readCopy(op, bytes, why): return false
    var cur = ""
    try: cur = readFile(op.fromP)
    except IOError, OSError:
      why = getCurrentExceptionMsg()
      return false
    if safeReplace(op.fromP, bytes, cur, true, w) != wrOk:
      why = w
      return false
    true
  else:
    let st = stateOf(op)
    if st == osNot: return true
    let mode = pathInfo(op.oldCopy).mode
    if not readCopy(op, bytes, why): return false
    if op.caseOnly:
      if pathExistsNoFollow(op.toP) and nameOf(op.toP) in listNames(parentOf(op.toP)): removeTemp(op.toP)
      if not pathExistsNoFollow(op.fromP) or nameOf(op.fromP) notin listNames(parentOf(op.fromP)):
        if putExact(op.fromP, bytes, mode, w) == lkFailed:
          why = w
          return false
    else:
      if not pathExistsNoFollow(op.fromP):
        if putExact(op.fromP, bytes, mode, w) == lkFailed:
          why = w
          return false
      if pathExistsNoFollow(op.toP): removeTemp(op.toP)
    true

type Rollback = enum
  rbRestored, rbDone, rbForeign, rbFailed

proc rollback(ops: seq[Op], jdirs: seq[string], id: string, file, why: var string): Rollback =
  ## 131:4:4 R4: se tutte le operazioni sono già applicate si completa il passo 8; se una è estranea non si tocca niente;
  ## altrimenti si torna indietro su tutte e poi si fa il passo 8.
  var anyNot = false
  for op in ops:
    let st = stateOf(op)
    if st == osForeign:
      file = op.fromP
      if op.kind != "sostituisci" and not op.caseOnly:
        # 131:4:5 C-4: se la partenza manca o ha il testo di prima e a non corrispondere è l'arrivo, il file estraneo è l'arrivo
        var h, hn: string
        let nOk = not pathExistsNoFollow(op.fromP) or (hashOf(op.fromP, h) and h == op.oldFp)
        if nOk and pathExistsNoFollow(op.toP) and not (hashOf(op.toP, hn) and hn == op.newFp): file = op.toP
      return rbForeign
    if st != osDone: anyNot = true
  if not anyNot:
    cleanup(ops, jdirs, id)
    return rbDone
  for k in countdown(ops.high, 0):
    var w = ""
    if not undoOp(ops[k], w):
      file = ops[k].fromP
      why = w
      return rbFailed
  cleanup(ops, jdirs, id)
  rbRestored

# ---------------------------------------------------------------- la scrittura

proc stopSetting(): (int, bool) =
  ## 131:5:1 Solo nell'eseguibile di prova: BCDD_RINOMINA_PROVA_FERMA=k esce con 99 dopo k operazioni del passo 6; con `k.5` esce a metà
  ## della successiva (arrivo creato, partenza non tolta). Nel binario di rilascio la variabile non si legge.
  when defined(bcddProva):
    let v = getEnv("BCDD_RINOMINA_PROVA_FERMA")
    if v.len > 0:
      let half = v.endsWith(".5")
      let num = if half: v[0 ..< v.len - 2] else: v
      try: return (parseInt(num), half)
      except ValueError: discard
  (-1, false)

proc errorSetting(): int =
  ## 131:5:1b Solo nell'eseguibile di prova: BCDD_RINOMINA_PROVA_ERRORE=k fa fallire l'operazione numero k+1 del passo 6 (R2: ripristino).
  when defined(bcddProva):
    try: return parseInt(getEnv("BCDD_RINOMINA_PROVA_ERRORE", "-1"))
    except ValueError: discard
  -1

proc commit*(opsIn: seq[Op], cmdLine: string): CommitRes =
  ## 131:5:2 Il passo 3-8 di: giornali, copie, rilettura, applicazione, controllo, pulizia.
  let id = newId()
  var ops = opsIn
  for op in ops.mitems: workNames(op, id)
  let jdirs = opDirs(ops)
  let bad = pathProblem(ops)
  if bad.len > 0: return CommitRes(kind: ckWriteNothing, file: bad, why: "")
  var guard = deferInterrupt()
  proc finish(r: CommitRes): CommitRes =
    restoreInterrupt(guard)
    r
  var made: seq[string]                 # i giornali creati da questo comando
  var why = ""
  proc undoStart(opsL: seq[Op]) =
    cleanup(opsL, jdirs, id)
    for jd in made: removeTemp(journalPath(jd))
    for d in jdirs: syncDirectory(d)
  # passo 3: i giornali
  for jd in jdirs:
    case putExact(journalPath(jd), journalText(id, cmdLine, ops, jd), -1, why)
    of lkCreated: made.add jd
    of lkExists:
      for m in made: removeTemp(journalPath(m))
      return finish(CommitRes(kind: ckJournalExists, dir: jd))
    of lkFailed:
      undoStart(ops)
      return finish(CommitRes(kind: ckWriteNothing, file: journalPath(jd), why: why))
  for jd in jdirs: syncDirectory(jd)
  # passo 4: la copia del vecchio e il testo nuovo, ciascuno su disco
  for op in ops:
    if putExact(op.oldCopy, op.oldText, op.mode, why) == lkFailed:
      undoStart(ops)
      return finish(CommitRes(kind: ckWriteNothing, file: op.oldCopy, why: why))
    if putExact(op.newCopy, op.newText, op.mode, why) == lkFailed:
      undoStart(ops)
      return finish(CommitRes(kind: ckWriteNothing, file: op.newCopy, why: why))
  for d in jdirs: syncDirectory(d)
  # passo 5: la rilettura
  for op in ops:
    var h: string
    if not hashOf(op.fromP, h) or h != op.oldFp or (op.kind != "sostituisci" and not arrivalFree(op)):
      undoStart(ops)
      return finish(CommitRes(kind: ckChanged, file: op.fromP))
  # passo 6: l'applicazione, nell'ordine del giornale
  let (stopK, stopHalf) = stopSetting()
  var done = 0
  var failWhy = ""
  var failFile = ""
  var failed = false
  let errK = errorSetting()
  for k, op in ops:
    var w = ""
    if errK == done:
      failed = true
      failFile = op.fromP
      failWhy = "test error"
      break
    if op.kind == "sostituisci":
      if not replaceFile(op.newCopy, op.fromP, w):
        failed = true
        failFile = op.fromP
        failWhy = w
        break
    else:
      if op.caseOnly:
        removeTemp(op.fromP)
        if linkNewFile(op.newCopy, op.toP, w) != lkCreated:
          failed = true
          failFile = op.toP
          failWhy = if w.len > 0: w else: testo(kRinCausaEsiste)
          break
        removeTemp(op.newCopy)
      else:
        let lr = linkNewFile(op.newCopy, op.toP, w)
        if lr != lkCreated:
          failed = true
          failFile = op.toP
          failWhy = if w.len > 0: w else: testo(kRinCausaEsiste)
          break
        removeTemp(op.newCopy)
        if stopK == done and stopHalf: quit(99)
        removeTemp(op.fromP)
    inc done
    if stopK >= 0 and stopK == done and not stopHalf: quit(99)
  # passo 7: rilettura dei file scritti
  if not failed:
    for op in ops:
      let target = if op.kind == "sostituisci": op.fromP else: op.toP
      var h: string
      if not hashOf(target, h) or h != op.newFp:
        failed = true
        failFile = target
        failWhy = testo(kRinCausaDiverso)
        break
  if failed:
    var file, w2: string
    case rollback(ops, jdirs, id, file, w2)
    of rbRestored, rbDone:
      return finish(CommitRes(kind: ckRestored, file: failFile, why: failWhy))
    of rbForeign, rbFailed:
      return finish(CommitRes(kind: ckRestoreFailed, file: failFile, why: failWhy))
  cleanup(ops, jdirs, id)
  finish(CommitRes(kind: ckOk))

# ---------------------------------------------------------------- --recover

proc parseJournal(dir: string, ops: var seq[Op], id, cmdLine: var string, complete: var bool, why: var string): bool =
  let jp = journalPath(dir)
  var txt: string
  try:
    txt = readFile(jp)
  except IOError, OSError:
    why = testo(kRinNonLeggibile)
    return false
  let lines = txt.split('\n')
  if lines.len < 3 or lines[0] != JournalHeader: return false
  id = lines[1]
  cmdLine = lines[2]
  complete = false
  let base = if dir == "" or dir == ".": "." else: dir
  proc res(p: string): string = (if isAbsolute(p): p else: joinShown(base, p))
  for k in 3 ..< lines.len:
    let l = lines[k]
    if l == "fine":
      complete = true
      break
    if l.len == 0: continue
    let f = l.split('\t')
    if f.len != 8 or f[0] != "op": return false
    var op = Op(kind: f[1], fromP: res(f[2]), toP: res(f[3]), oldFp: f[4], newFp: f[5], oldCopy: res(f[6]), newCopy: res(f[7]))
    op.caseOnly = op.kind != "sostituisci" and op.fromP != op.toP and unicodeLower(nameOf(op.fromP)) == unicodeLower(nameOf(op.toP)) and
      parentOf(op.fromP) == parentOf(op.toP)
    ops.add op
  true

proc recoverDir*(dir: string): RecoverRes =
  ## 131:6:1 R4 e R5: il ripristino della cartella `dir` (come scritta). Torna indietro, salvo la rinomina già scritta per intero.
  if not pathExistsNoFollow(journalPath(dir)): return RecoverRes(kind: rcNoJournal)
  var ops: seq[Op]
  var id, cmdLine, why: string
  var complete = false
  if not parseJournal(dir, ops, id, cmdLine, complete, why):
    return RecoverRes(kind: (if why.len > 0: rcUnreadable else: rcBroken), why: why)
  result.cmd = cmdLine
  var jdirs = opDirs(ops)
  let base = if dir.len == 0: "." else: dir
  var have = false
  for d in jdirs:
    if (try: expandFilename(d) except OSError: absolutePath(d)) == (try: expandFilename(base) except OSError: absolutePath(base)): have = true
  if not have: jdirs.add base
  if not complete:
    # nessuna operazione è cominciata: si tolgono i file di lavoro elencati e il giornale
    for op in ops:
      removeTemp(op.oldCopy)
      removeTemp(op.newCopy)
    removeTemp(journalPath(base))
    syncDirectory(base)
    result.kind = rcRestored
    return
  var file, w: string
  case rollback(ops, jdirs, id, file, w)
  of rbDone: result.kind = rcAlreadyDone
  of rbRestored: result.kind = rcRestored
  of rbForeign:
    result.kind = rcForeign
    result.file = file
    for op in ops:
      if op.fromP == file or (op.kind != "sostituisci" and op.toP == file): result.copy = op.oldCopy
  of rbFailed:
    result.kind = rcUndoFailed
    result.file = file
    result.why = w

proc journalInfo*(dir: string): string =
  ## 131:6:2 `VECCHIO -> NUOVO` dal giornale di `dir`, per il messaggio di un rifiuto; "? -> ?" se non si legge.
  try:
    let l = readFile(journalPath(dir)).split('\n')
    if l.len > 2 and l[0] == JournalHeader:
      let p = l[2].split(' ')
      if p.len == 3: return p[1] & " -> " & p[2]
  except IOError, OSError:
    discard
  "? -> ?"

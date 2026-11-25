# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 110:1:1 `bcdd save FILE --expect IMPRONTA|nuovo`: scrive il testo intero ricevuto
# 110:1:2 sullo standard input, a patto che il file sia ancora quello dell'impronta e che nessuna riga diventi contratto
# 110:1:3 senza Ratify. Tutto o niente, con la scrittura sicura di bcddsafe. Scrive anche con errori di check e li dice.
import std/[strutils, os, tables]
import bcddlex, bcddcheck, bcddprog, bcddsafe, bcddnew, bcddtesti

proc usoSave(): string =
  ## 110:2:1 La riga d'uso, nella lingua corrente (senza il LF finale).
  let t = testo(kUsoSave)
  t[0 ..< t.len - 1]

proc jstr(s: string): string =
  result = "\""
  for c in s:
    case c
    of '"': result.add "\\\""
    of '\\': result.add "\\\\"
    of '\n': result.add "\\n"
    of '\r': result.add "\\r"
    of '\t': result.add "\\t"
    of '\0' .. '\8', '\11', '\12', '\14' .. '\31', '\127': result.add "\\u00" & toHex(ord(c), 2).toLowerAscii
    else: result.add c
  result.add "\""

proc declText(rep: Report, a, b: int): string =
  var ls: seq[string]
  for n in a .. b:
    if n >= 1 and n <= rep.srcLines.len: ls.add rep.srcLines[n - 1]
  ls.join("\n")

proc blockKey(b: BlockInfo): string =
  ## 110:2:1 (1.0-beta) il tipo del blocco e il suo nome, con il nome proprio di un BINDING: due blocchi di tipo diverso non si confondono
  (case b.bk
   of "VIEW": "V "
   of "ENTITY": "E "
   of "CSC", "": "C "
   else: b.bk & " ") & b.name & (if b.ownName.len > 0: " AS " & b.ownName else: "")

proc blockLabel(key: string): string =
  ## 110:2:2 (B-1) il nome del blocco senza il tipo che apre la chiave: "C K" e "BINDING Luce" danno "K" e "Luce"
  let sp = key.find(' ')
  if sp < 0: key else: key[sp + 1 .. ^1]

proc findBlock(rep: Report, key: string): int =
  for i, b in rep.blocks:
    if b.headerOk and blockKey(b) == key: return i
  -1

proc statusOf(b: BlockInfo): string =
  if b.status == skRat: "R " & b.decision else: "-"

proc contractRows(rep: Report): Table[string, string] =
  ## 111:1:1 Le righe contratto: blocco, parola e id -> testo e decisione. Il primo di un nome ripetuto vince.
  for r in rep.rows:
    if not r.contract: continue
    let b = rep.blocks[r.blockIdx]
    let k = blockKey(b) & "|" & r.kw & "|" & r.id
    if k in result: continue
    let dec = if r.own == skRat: r.decision else: b.decision
    result[k] = dec & "\x01" & declText(rep, r.line, r.lastLine)
  # 111:1:5 (1.0-beta, B-1) anche i dettagli di DEFINE e di storie e le righe BIND approvati
  for r in rep.detRows:
    if not r.contract: continue
    let k = blockKey(rep.blocks[r.blockIdx]) & "|" & r.kw & "|" & r.id
    if k notin result: result[k] = "\x01" & declText(rep, r.line, r.lastLine)
  for b in rep.blocks:
    if b.bk != "BINDING" or not b.headerOk: continue
    var seen = initTable[string, int]()
    for br in b.binds:
      let en = br.elem & (if br.field.len > 0: "." & br.field else: "")
      let n = seen.getOrDefault(en)
      seen[en] = n + 1
      if br.status == skRat or (br.status == skNone and b.status == skRat):
        let dec = if br.status == skRat: br.decision else: b.decision
        result[blockKey(b) & "|BIND|" & en & "#" & $n] = dec & "\x01" & declText(rep, br.line, br.lastLine)

proc contractPieces(rep: Report): Table[string, (string, int)] =
  ## 111:1:4 Dove vale ogni riga contratto: "" fra le righe comuni, "dimensione\0scelta" in un pezzo VARIANT,
  ## "?" in un pezzo scritto male; con la riga del testo. Stesse chiavi di contractRows.
  for r in rep.rows:
    if not r.contract: continue
    let b = rep.blocks[r.blockIdx]
    let k = blockKey(b) & "|" & r.kw & "|" & r.id
    if k in result: continue
    var where = ""
    if r.piece > 0:
      let p = b.pieces[r.piece - 1]
      where = if p.valid: p.dim & "\0" & p.choice else: "?"
    result[k] = (where, r.line)

proc fixedDecls(rep: Report, bi: int): seq[string] =
  ## 111:1:2 Le dichiarazioni del blocco che non sono righe (eventi, stati, capacità, tipi, scenari, parti...), in ordine.
  for n in rep.blocks[bi].names:
    if n.kind == "ROW": continue
    result.add n.kind & "|" & n.name & "|" & declText(rep, n.line, rep.spans.getOrDefault(n.line, n.line))

proc refuse(msg: string) = die("bcdd save: " & msg, 1)

proc changedLines(oldL, newL: seq[string]): seq[int] =
  ## 111:1:3 Righe cambiate, con la numerazione del testo nuovo. Stessa lunghezza: confronto riga per riga;
  ## altrimenti l'intervallo fra il prefisso e il suffisso uguali.
  if oldL.len == newL.len:
    for i in 0 ..< newL.len:
      if oldL[i] != newL[i]: result.add i + 1
    return
  var p = 0
  while p < oldL.len and p < newL.len and oldL[p] == newL[p]: inc p
  var s = 0
  while s < oldL.len - p and s < newL.len - p and oldL[oldL.len - 1 - s] == newL[newL.len - 1 - s]: inc s
  for i in p ..< newL.len - s: result.add i + 1
  if result.len == 0 and newL.len > 0: result.add min(p + 1, newL.len)   # solo righe tolte: dove è avvenuto il taglio

proc esito(file, newText: string, cs: seq[int], newRep: Report) =
  ## 113:1:1 La risposta JSON della save e dell'undo: righe cambiate, impronta del testo scritto, errori di check.
  var cl, es: seq[string]
  for n in cs: cl.add $n
  for e in newRep.errs:
    es.add "{\"riga\": " & $e.line & ", \"codice\": " & jstr(e.code) & ", \"messaggio\": " & jstr(e.msg) & "}"
  stdout.write "{\"forma\": \"bcdd-save\", \"versione\": 1, \"file\": " & jstr(extractFilename(file)) &
    ", \"righe_cambiate\": [" & cl.join(", ") & "], \"impronta\": " & jstr(fingerprint(newText)) &
    ", \"errori\": [" & es.join(", ") & "]}\n"
  stdout.flushFile()
  quit(0)

const TagTolto = "tolto"

proc runRemove(file, expect: string) =
  ## 113:3:1 `--remove`: toglie FILE se l'impronta è giusta e non ha righe di contratto
  ## (stessa nozione della save: blocco con STATUS RATIFIED o righe contratto). Prima scrive FILE.prima con `tolto`.
  if expect == "nuovo": die(usoSave(), 2)
  let cur = loadSource("bcdd save", file)
  if fingerprint(cur) != expect:
    refuse(testo(kEStatoModificatoDaUn, file))
  let rep = analyze(cur)
  var appr = contractRows(rep).len > 0
  for b in rep.blocks:
    if b.headerOk and b.status == skRat: appr = true
  if appr:
    refuse(testo(kHaRigheApprovateNonSi, splitFile(file).name))
  let prima = file & ".prima"
  var pw = ""
  var vecchioPrima = ""
  let esiste = fileExists(prima)
  if esiste:
    try: vecchioPrima = readFile(prima)
    except IOError, OSError: pw = "illeggibile"
  if pw.len > 0 or safeReplace(prima, TagTolto & "\n" & cur, vecchioPrima, esiste, pw) != wrOk:
    refuse(testo(kNonRiescoAScrivereNon, prima))
  try:
    removeFile(file)
  except OSError:
    try: removeFile(prima)
    except OSError: discard
    refuse(testo(kNonRiescoATogliere, file))
  stdout.write "{\"forma\": \"bcdd-save\", \"versione\": 1, \"file\": " & jstr(extractFilename(file)) &
    ", \"tolto\": true, \"righe_cambiate\": [], \"errori\": []}\n"
  stdout.flushFile()
  quit(0)

proc runUndo(file, expect: string) =
  ## 113:2:1 `--undo`: rimette il testo di FILE.prima se nessuno ha toccato il file dopo la save.
  ## Niente regole del contratto: è un testo che c'era. Scrive con la scrittura sicura, poi toglie FILE.prima.
  let prima = file & ".prima"
  let dopoRemove = expect == "nuovo"
  if dopoRemove and (fileExists(file) or dirExists(file)):
    refuse(testo(kEsisteGiaNonScrivoNiente, file))
  var pr = ""
  if not fileExists(prima):
    refuse(testo(kNonCENonC, prima))
  try:
    pr = readFile(prima)
  except IOError, OSError:
    refuse(testo(kNonRiescoALeggere, prima))
  let nl = pr.find('\n')
  if nl < 0 or firstInvalidUtf8(pr) >= 0:
    refuse(testo(kNonENellaFormaAttesa, prima))
  let ipPrima = pr[0 ..< nl]
  let vecchio = pr[nl + 1 .. ^1]
  if dopoRemove:
    # 113:2:2 Dopo --remove: FILE assente e FILE.prima che comincia con `tolto`; si rimette il file con la scrittura sicura.
    if ipPrima != TagTolto:
      refuse(testo(kNonEQuelloDiUn, prima))
    var w = ""
    let rr = safeReplace(file, vecchio, "", false, w)
    if rr != wrOk: die(writeErrorMessage("bcdd save", file, rr, w), 1)
    try: removeFile(prima)
    except OSError: discard
    var rep0 = analyze(vecchio)
    resolveCitations(rep0, file, @[])
    esito(file, vecchio, changedLines(@[], vecchio.splitLines()), rep0)
  if ipPrima == TagTolto:
    refuse(testo(kEDiUnFileTolto, prima))
  let cur = loadSource("bcdd save", file)
  if fingerprint(cur) != expect or ipPrima != expect:
    refuse(testo(kEStatoModificatoDopoL, file))
  var why = ""
  let r = safeReplace(file, vecchio, cur, true, why)
  if r != wrOk: die(writeErrorMessage("bcdd save", file, r, why), 1)
  try: removeFile(prima)
  except OSError: discard
  var rep = analyze(vecchio)
  resolveCitations(rep, file, @[])
  esito(file, vecchio, changedLines(cur.splitLines(), vecchio.splitLines()), rep)

proc runSave*(args: seq[string]) =
  var file, expect: string
  var haveFile, haveExpect, undo, remove = false
  var i = 0
  while i < args.len:
    if args[i] == "--undo":
      if undo: die(usoSave(), 2)
      undo = true
      inc i
    elif args[i] == "--remove":
      if remove: die(usoSave(), 2)
      remove = true
      inc i
    elif args[i] == "--expect":
      if haveExpect or i + 1 >= args.len: die(usoSave(), 2)
      expect = args[i + 1]
      haveExpect = true
      i += 2
    elif args[i].len > 0 and args[i][0] == '-': die(usoSave(), 2)
    elif haveFile: die(usoSave(), 2)
    else:
      file = args[i]
      haveFile = true
      inc i
  if not haveFile or not haveExpect: die(usoSave(), 2)
  if undo and remove: die(usoSave(), 2)
  if undo: runUndo(file, expect)
  if remove: runRemove(file, expect)
  var newText: string
  try:
    newText = stdin.readAll()
  except IOError:
    die(testo(kSaveNonLeggoStdin), 2)
  let bad = firstInvalidUtf8(newText)
  if bad >= 0: die(testo(kSaveNonUtf8), 2)
  var oldRaw = ""
  let isNew = expect == "nuovo"
  if isNew:
    if fileExists(file) or dirExists(file):
      refuse(testo(kEsisteGiaNonScrivoNiente, file))
  else:
    oldRaw = loadSource("bcdd save", file)
    if fingerprint(oldRaw) != expect:
      refuse(testo(kEStatoModificatoDaUn2, file))
  # 112:1:1 Le regole 2 e 3 della sezione 7.3: niente contratto senza Ratify
  let oldRep = analyze(oldRaw)
  var newRep = analyze(newText)
  let oldRows = contractRows(oldRep)
  let newRows = contractRows(newRep)
  let oldPieces = contractPieces(oldRep)
  let newPieces = contractPieces(newRep)
  for k, v in newRows:
    if k notin oldRows:
      let p = k.split('|')
      refuse(testo(kLaRigaDiDiventerebbeContratto, p[1], p[2].split('#')[0], blockLabel(p[0])))
    if oldRows[k] != v:
      let p = k.split('|')
      refuse(testo(kLaRigaDiEContratto, p[1], p[2].split('#')[0], blockLabel(p[0])))
    # 112:1:7 una promessa approvata non cambia dove vale: né pezzo VARIANT, né il nome della sua dimensione o scelta
    if k in oldPieces and k in newPieces and oldPieces[k][0] != newPieces[k][0]:
      let p = k.split('|')
      refuse(testo(kLaRigaEContrattoNon, $newPieces[k][1], p[1], p[2], v.split('\x01')[0]))
  for nb in newRep.blocks:
    if not nb.headerOk or nb.status != skRat: continue
    let ob = findBlock(oldRep, blockKey(nb))
    if ob < 0 or oldRep.blocks[ob].status != skRat or statusOf(oldRep.blocks[ob]) != statusOf(nb):
      refuse(testo(kDiventerebbeContrattoSenzaUnaRatifica, nb.name))
    # 112:1:5 Versione bloccata: approvata prima e dopo con la stessa decisione, il numero non cambia
    if oldRep.blocks[ob].version != nb.version:
      refuse(testo(kEApprovataIlNumeroDella, nb.name))
    # 112:1:8 (1.0-beta, B-1) l'intestazione di un BINDING o di un profilo approvati è bloccata; di un profilo approvato nessuna riga cambia
    if nb.bk in ["BINDING", "PROFILE"]:
      let nbi0 = findBlock(newRep, blockKey(nb))
      if declText(oldRep, oldRep.blocks[ob].line, oldRep.blocks[ob].line) != declText(newRep, nb.line, nb.line):
        refuse(testo(kEApprovatoLIntestazioneNon, nb.name))
      if nb.bk == "PROFILE" and declText(oldRep, oldRep.blocks[ob].line, oldRep.blocks[ob].endLine) !=
          declText(newRep, newRep.blocks[nbi0].line, newRep.blocks[nbi0].endLine):
        refuse(testo(kIlProfiloEApprovatoLe, nb.name))
      continue
    # 112:1:2 Il blocco resta ratificato: le dichiarazioni dopo l'intestazione restano uguali e nello stesso ordine
    let nbi = findBlock(newRep, blockKey(nb))
    if fixedDecls(oldRep, ob) != fixedDecls(newRep, nbi):
      refuse(testo(kERatificataLeDichiarazioniDopo, nb.name))
  # 112:1:3 Scrittura
  var why = ""
  if isNew:
    case createExclusive(file, newText, why)
    of crCreated: discard
    of crExists: refuse(testo(kEsisteGiaNonScrivoNiente, file))
    of crFailed: refuse(testo(kNonRiescoACreare, file, why))
  else:
    let r = safeReplace(file, newText, oldRaw, true, why)
    if r != wrOk: die(writeErrorMessage("bcdd save", file, r, why), 1)
    # 112:1:6 FILE.prima dopo la scrittura del file: se questa fallisce FILE.prima non descrive mai una scrittura
    # non avvenuta. Se non si riesce a scriverlo si toglie quello vecchio (la sua impronta non combacerebbe comunque).
    let prima = file & ".prima"
    var pw = ""
    var vecchioPrima = ""
    let esiste = fileExists(prima)
    if esiste:
      try: vecchioPrima = readFile(prima)
      except IOError, OSError: pw = "illeggibile"
    if pw.len == 0 and safeReplace(prima, fingerprint(newText) & "\n" & oldRaw, vecchioPrima, esiste, pw) == wrOk: discard
    else:
      try: removeFile(prima)
      except OSError: discard
  # 112:1:4 L'esito: righe cambiate, impronta nuova, errori di check sul testo scritto
  resolveCitations(newRep, file, @[])
  var oldL, newL: seq[string]
  if oldRaw.len > 0: oldL = oldRaw.splitLines()
  newL = newText.splitLines()
  let ch = changedLines(oldL, newL)
  esito(file, newText, ch, newRep)

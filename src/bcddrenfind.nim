# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 130:1:1 `bcdd rename`, prima parte: l'insieme dei file, le posizioni dei nomi, le righe bloccate,
# 130:1:2 i testi liberi e i controlli sul nome nuovo. Legge soltanto: nessuna scrittura (la scrittura è in bcddrenwrite).
# 130:1:3 ✓ verificato: l'analisi (`analyze`: blocchi, citazioni, nomi qualificati, righe, TransRec), il lessico (`lex`, `rawLines`),
# 130:1:4 `chooseBlock` di ratify e le regole di save: tutto riusato, nessuna seconda grammatica.
import std/[os, strutils, tables, algorithm, sets, unicode]
import bcddlex, bcddcheck, bcddratify, bcddsafe, bcddsys, bcddtesti, bcddnew, bcddprog

type
  RKind* = enum
    rkCsc = "csc", rkEntity = "entity", rkPart = "part", rkId = "id"

  Folder* = object
    shown*: string       # come l'ha scritta la persona (per la cartella di FILE: con il separatore finale, "" senza separatore)
    disk*: string        # il percorso da aprire ("." se shown è vuoto)
    real*: string        # percorso assoluto risolto (I1)

  SrcFile* = object
    dir*: int
    name*: string
    path*: string        # disk / name
    shown*: string       # come si mostra: la cartella com'è scritta, poi il nome
    raw*: string
    fp*: string
    isLink*: bool
    nlink*: int
    mode*: int
    unreadable*: string  # "" | "non_leggibile" | "non_utf8"
    rep*: Report
    rl*: RawLines
    toks*: seq[Tok]
    tokAt*: seq[int]     # tokAt[n]: indice del primo elemento della riga n (da 1); tokAt[total + 1] = toks.len
    blocked*: Table[int, BlockWhy]

  Edit* = object
    file*, line*, col*: int
    genere*: string
    decl*: bool          # è la dichiarazione del nome

  Occ* = object
    file*, line*, col*: int
    cat*: string         # stringa | commento | non_riconosciuta | E20
    blockedWhy*: string  # "" se non bloccata
    pre*: bool           # preselezionata (T5)
    n*: int              # numero da 1: t1, t2, ...
    text*: string        # la riga, senza spazi ai bordi

  BlockWhy* = object
    code*: string        # intestazione | riga | blocco | profilo
    dec*: string         # la decisione D-n
    row*: int            # solo `blocco`: la riga approvata che lo rende bloccato

  Bloc* = object
    file*, line*: int
    why*: BlockWhy

  Target* = object
    ## 130:2:1 Il bersaglio della rinomina: il blocco scelto per `part` e `id`.
    file*, bi*: int      # indice del file e del blocco, -1 se non serve
    name*, version*: string

proc fileShown*(dirShown, name: string): string =
  if dirShown.len == 0: name else: joinShown(dirShown, name)

proc trimWs*(s: string): string = s.strip(chars = {' ', '\t'})

# ---------------------------------------------------------------- l'insieme (I1-I5)

proc listDir(path: string): seq[string] =
  ## 130:3:1 I nomi delle voci di una cartella (di qualunque tipo, anche collegamenti rotti), in ordine di byte.
  try:
    for kind, p in walkDir(path, relative = true): result.add p
  except OSError:
    discard
  result.sort(system.cmp[string])

proc realOf(disk: string): string =
  try: expandFilename(disk) except OSError: absolutePath(disk)

proc buildFolders*(fileArg: string, dirs: seq[string]): seq[Folder] =
  ## 130:3:2 I1: la cartella di FILE e le --dir nell'ordine scritto; due che indicano la stessa cartella contano una volta.
  var cand: seq[Folder]
  let f0 = folderOfArg(fileArg)
  cand.add Folder(shown: f0, disk: (if f0.len == 0: "." else: f0))
  for d in dirs: cand.add Folder(shown: d, disk: d)
  var seen = initHashSet[string]()
  for c in cand:
    var f = c
    f.real = realOf(f.disk)
    if f.real in seen: continue
    seen.incl f.real
    result.add f

proc loadSet*(folders: seq[Folder], P: string): seq[SrcFile] =
  ## 130:3:3 I2: i file normali che finiscono con `.csc`, direttamente in ciascuna cartella; le sottocartelle non si guardano.
  for di, fo in folders:
    for nm in listDir(fo.disk):
      if not nm.endsWith(".csc"): continue
      let full = if fo.disk == ".": nm else: joinShown(fo.disk, nm)
      let st = pathInfo(full)
      if not st.ok or not st.isFile: continue
      var f = SrcFile(dir: di, name: nm, path: full, shown: fileShown(fo.shown, nm), nlink: st.nlink, mode: st.mode)
      f.isLink = symlinkExists(full)
      try:
        f.raw = readFile(full)
        if firstInvalidUtf8(f.raw) >= 0: f.unreadable = "non_utf8"
      except IOError, OSError:
        f.unreadable = "non_leggibile"
      f.fp = fingerprint(f.raw)
      result.add f

proc analyzeFiles*(files: var seq[SrcFile]) =
  ## 130:3:4 L'analisi di ogni file leggibile: report, posizioni delle righe nel testo originale e elementi del lessico.
  for f in files.mitems:
    if f.unreadable.len > 0: continue
    f.rep = analyze(f.raw)
    f.rl = rawLines(f.raw)
    let lx = lex(normalizeSource(f.raw))
    f.toks = lx.toks
    let total = lx.lines.len
    f.tokAt = newSeq[int](total + 2)
    var ti = 0
    for ln in 1 .. total + 1:
      f.tokAt[ln] = ti
      while ti < f.toks.len and f.toks[ti].line == ln: inc ti
    f.tokAt[total + 1] = f.toks.len

proc declToks(f: SrcFile, first: int): seq[Tok] =
  let last = f.rep.spans.getOrDefault(first, first)
  if first < 1 or first >= f.tokAt.len: return
  let a = f.tokAt[first]
  let lastC = min(last, f.tokAt.len - 2)
  let b = f.tokAt[lastC + 1]
  for k in a ..< b: result.add f.toks[k]

proc isRec(f: SrcFile, line: int): bool =
  line >= 1 and line <= f.rep.lineClass.len and f.rep.lineClass[line - 1] == 'r'

proc declFirsts(f: SrcFile, a, b: int): seq[int] =
  ## 130:4:1 Le prime righe delle dichiarazioni comprese fra le righe a e b, in ordine.
  for first in f.rep.spans.keys:
    if first >= a and first <= b: result.add first
  result.sort()

# ---------------------------------------------------------------- le posizioni (2.2-2.5)

type ScanOut* = object
  edits*: seq[Edit]

proc addEdit(res: var ScanOut, seen: var HashSet[(int, int, int)], f: SrcFile, fi, line, col: int, name, genere: string, decl: bool) =
  ## 130:5:1 Aggiunge una posizione se nel testo c'è proprio il nome (difesa) e non è già nota.
  if line < 1 or line > f.rl.starts.len: return
  let off = f.rl.starts[line - 1] + col
  if off < 0 or off + name.len > f.raw.len or f.raw[off ..< off + name.len] != name: return
  if (fi, line, col) in seen: return
  seen.incl (fi, line, col)
  res.edits.add Edit(file: fi, line: line, col: col, genere: genere, decl: decl)

proc tokWithText(ts: seq[Tok], k: int, name: string): bool =
  k >= 0 and k < ts.len and ts[k].kind == tkWord and ts[k].text == name

proc scanNames*(files: seq[SrcFile], kind: RKind, name: string, tg: Target): ScanOut =
  ## 130:5:2 Tutte le posizioni in cui `name` cambia da solo, nelle sole forme riconosciute.
  var seen = initHashSet[(int, int, int)]()
  for fi, f in files:
    if f.unreadable.len > 0: continue
    for bi, b in f.rep.blocks:
      if not b.headerOk: continue
      case kind
      of rkCsc:
        let hd = declToks(f, b.line)
        if b.bk == "CSC" and b.name == name and hd.len > 1 and hd[0].text == "CSC" and tokWithText(hd, 1, name):
          addEdit(result, seen, f, fi, hd[1].line, hd[1].col, name, "dichiarazione", true)
        elif b.bk in ["BINDING", "VERIFICATION"] and b.legataName == name and hd.len > 1 and hd[0].text == b.bk and tokWithText(hd, 1, name):
          addEdit(result, seen, f, fi, hd[1].line, hd[1].col, name, b.bk, false)
        if b.isEntity:
          for first in declFirsts(f, b.line + 1, b.endLine):
            if not isRec(f, first): continue
            let t = declToks(f, first)
            if t.len > 1 and t[0].kind == tkWord and t[0].text in ["OFFERS", "USES"] and tokWithText(t, 1, name):
              addEdit(result, seen, f, fi, t[1].line, t[1].col, name, t[0].text, false)
          for q in b.qrefs & b.fqrefs:
            if q.qual == name: addEdit(result, seen, f, fi, q.line, q.col, name, "qualificato", false)
      of rkEntity:
        let hd = declToks(f, b.line)
        if b.bk == "ENTITY" and b.name == name and hd.len > 1 and hd[0].text == "ENTITY" and tokWithText(hd, 1, name):
          addEdit(result, seen, f, fi, hd[1].line, hd[1].col, name, "dichiarazione", true)
        if b.isEntity:
          for c in b.cites:
            if c.kind != ckPart or c.name != name: continue
            let t = declToks(f, c.line)
            if t.len > 2 and t[1].kind == tkSym and t[1].text == ":" and tokWithText(t, 2, name):
              addEdit(result, seen, f, fi, t[2].line, t[2].col, name, "parte", false)
      of rkPart:
        if fi == tg.file and bi == tg.bi and b.isEntity:
          for c in b.cites:
            if c.kind != ckPart or c.part != name: continue
            let t = declToks(f, c.line)
            if t.len > 1 and tokWithText(t, 0, name):
              addEdit(result, seen, f, fi, t[0].line, t[0].col, name, "parte", true)
      of rkId:
        if fi == tg.file and bi == tg.bi:
          var regLines = initHashSet[int]()
          for n in b.names:
            if n.name == name and n.kind in ["ROW", "SCENARIO"]: regLines.incl n.line
          for first in declFirsts(f, b.line + 1, b.endLine):
            let t = declToks(f, first)
            if t.len < 2 or t[0].kind != tkWord or t[0].text notin ["GUARANTEE", "ASSUME", "SCENARIO"]: continue
            if not (isRec(f, first) or first in regLines): continue
            if first in regLines and tokWithText(t, 1, name):
              addEdit(result, seen, f, fi, t[1].line, t[1].col, name, "dichiarazione", true)
            for k in 2 ..< t.len - 1:
              if t[k].kind == tkWord and t[k].text == "DETAILS":
                if tokWithText(t, k + 1, name): addEdit(result, seen, f, fi, t[k + 1].line, t[k + 1].col, name, "DETAILS", false)
                break
        # le storie tradotte: nei blocchi VERIFICATION della stessa CSC e della stessa versione (testo uguale)
        if b.bk == "VERIFICATION" and files[tg.file].rep.blocks[tg.bi].bk == "CSC" and
            b.legataName == tg.name and b.legataVer == tg.version:
          for tr in b.trans:
            if tr.translates == name: addEdit(result, seen, f, fi, tr.transLine, tr.transCol, name, "TRANSLATES", false)
  result.edits.sort(proc(a, b: Edit): int =
    result = cmp(a.file, b.file)
    if result == 0: result = cmp(a.line, b.line)
    if result == 0: result = cmp(a.col, b.col))

# ---------------------------------------------------------------- le righe bloccate (B1)

proc whyText*(w: BlockWhy): string =
  ## 130:6:0 Il motivo nella lingua corrente (il testo fra parentesi del rifiuto).
  case w.code
  of "intestazione": testo(kRinMotIntestazione, w.dec)
  of "riga": testo(kRinMotRiga, w.dec)
  of "blocco": testo(kRinMotBlocco, w.row, w.dec)
  else: testo(kRinMotProfilo, w.dec)

proc whyCode*(w: BlockWhy): string =
  ## 130:6:0b Il motivo nel JSON: valore enumerato, non si traduce.
  case w.code
  of "intestazione": testo(kRinJsonIntestazione)
  of "riga": testo(kRinJsonRiga)
  of "blocco": testo(kRinJsonBlocco)
  else: testo(kRinJsonProfilo)

proc computeBlocked*(f: var SrcFile, kind: RKind) =
  ## 130:6:1 B1: le righe che `bcdd save` non lascerebbe cambiare. line -> motivo già composto nella lingua corrente.
  f.blocked = initTable[int, BlockWhy]()
  if f.unreadable.len > 0: return
  let rep = f.rep
  for bi, b in rep.blocks:
    if not b.headerOk: continue
    var approvable = initHashSet[int]()        # le prime righe delle righe contrattuali da approvare (anche con un proprio HYPOTHESIS)
    var firstContract = (0, "")                # la prima riga approvata del blocco, con la decisione
    proc mark(tbl: var Table[int, BlockWhy], a, z: int, why: BlockWhy) =
      for ln in a .. z:
        if ln notin tbl: tbl[ln] = why
    proc noteContract(line: int, dec: string, fc: var (int, string)) =
      if fc[0] == 0 or line < fc[0]: fc = (line, dec)
    for r in rep.rows & rep.detRows:
      if r.blockIdx != bi: continue
      approvable.incl r.line
    for br in b.binds: approvable.incl br.line
    let appr = b.status == skRat
    if b.bk == "PROFILE" and appr:
      mark(f.blocked, b.line, b.endLine, BlockWhy(code: "profilo", dec: b.decision))
      continue
    if appr:
      mark(f.blocked, b.line, b.line, BlockWhy(code: "intestazione", dec: b.decision))
    for r in rep.rows & rep.detRows:
      if r.blockIdx != bi or not r.contract: continue
      let dec = if r.own == skRat: r.decision else: b.decision
      mark(f.blocked, r.line, r.lastLine, BlockWhy(code: "riga", dec: dec))
      noteContract(r.line, dec, firstContract)
    for br in b.binds:
      if br.status == skRat or (br.status == skNone and appr):
        let dec = if br.status == skRat: br.decision else: b.decision
        mark(f.blocked, br.line, br.lastLine, BlockWhy(code: "riga", dec: dec))
        noteContract(br.line, dec, firstContract)
    if appr:
      for first in declFirsts(f, b.line + 1, b.endLine):
        if first in approvable: continue
        mark(f.blocked, first, rep.spans.getOrDefault(first, first), BlockWhy(code: "riga", dec: b.decision))
      if b.endLine > b.line: mark(f.blocked, b.endLine, b.endLine, BlockWhy(code: "riga", dec: b.decision))
    # (c) l'intestazione di un blocco con righe approvate, per csc ed entity
    if kind in {rkCsc, rkEntity} and firstContract[0] > 0 and b.bk in ["CSC", "ENTITY"]:
      mark(f.blocked, b.line, b.line, BlockWhy(code: "blocco", dec: firstContract[1], row: firstContract[0]))

# ---------------------------------------------------------------- i testi liberi (2.6)

proc isWordCh(r: Rune): bool =
  let v = int(r)
  (v >= ord('0') and v <= ord('9')) or v == ord('_') or isAlpha(r) or isCombining(r)

proc textWords(s: string): seq[(int, int)] =
  ## 130:7:1 T1: le parole del testo, come (inizio, fine) in byte: lettere di qualunque alfabeto, segni diacritici, cifre, `_` e un `-`
  ## compreso fra due di questi caratteri.
  var i = 0
  while i < s.len:
    var r: Rune
    fastRuneAt(s, i, r, false)
    let rl = runeLenAt(s, i)
    if not isWordCh(r):
      i += rl
      continue
    var j = i + rl
    while j < s.len:
      var r2: Rune
      fastRuneAt(s, j, r2, false)
      let l2 = runeLenAt(s, j)
      if isWordCh(r2): j += l2
      elif s[j] == '-' and j + 1 < s.len:
        var r3: Rune
        fastRuneAt(s, j + 1, r3, false)
        if isWordCh(r3): inc j else: break
      else: break
    result.add (i, j)
    i = j

proc validLabel(s: string): bool =
  ## 130:7:2 R1: da 2 a 60 caratteri, né spazio né tabulatore ai bordi, solo lettere, cifre, spazi e `-_./§`, una lettera almeno.
  let n = s.runeLen
  if n < 2 or n > 60: return false
  if s[0] in {' ', '\t'} or s[^1] in {' ', '\t'}: return false
  var letter = false
  for r in s.runes:
    if isAlpha(r): letter = true
    elif not ((int(r) >= ord('0') and int(r) <= ord('9')) or r == Rune(ord(' ')) or r == Rune(ord('-')) or r == Rune(ord('_')) or r == Rune(ord('.')) or
        r == Rune(ord('/')) or r == Rune(0xA7)): return false
  letter

proc collapseSp(s: string): string =
  var prevSp = false
  for c in s:
    if c in {' ', '\t'}:
      if not prevSp: result.add ' '
      prevSp = true
    else:
      result.add c
      prevSp = false

proc definitionLabel(line: string): string =
  ## 130:7:3 D1: una riga che contiene solo un commento `-- [Etichetta]: destinazione`; "" se non lo è.
  let t = trimWs(line)
  if not t.startsWith("--"): return ""
  var c = trimWs(t[2 .. ^1])
  if not c.startsWith("["): return ""
  let e = c.find("]:")
  if e < 2: return ""
  let label = c[1 ..< e]
  if not validLabel(label): return ""
  let rest = c[e + 2 .. ^1]
  if rest.len == 0 or rest[0] notin {' ', '\t'} or trimWs(rest).len == 0: return ""
  collapseSp(label)

proc excludedRanges(seg: string, defined: HashSet[string]): seq[(int, int)] =
  ## 130:7:4 T2: i riferimenti esterni `[Etichetta]` (con definizione nel file) e `[testo](destinazione)` dentro un segmento di testo libero.
  var i = 0
  while i < seg.len:
    if seg[i] == '[' and (i == 0 or seg[i - 1] != '['):
      let e = seg.find(']', i + 1)
      if e > i + 1 and (e + 1 >= seg.len or seg[e + 1] != ']'):
        let label = seg[i + 1 ..< e]
        if validLabel(label):
          if e + 1 < seg.len and seg[e + 1] == '(':
            let c = seg.find(')', e + 2)
            if c > e + 2:
              result.add (i, c + 1)
              i = c + 1
              continue
          elif collapseSp(label) in defined:
            result.add (i, e + 1)
            i = e + 1
            continue
    inc i

proc scanTexts*(files: seq[SrcFile], fileSel: seq[bool], kind: RKind, name: string, autoPos: HashSet[(int, int, int)]): seq[Occ] =
  ## 130:7:5 T1-T5: le occorrenze di `name` nei testi liberi (stringhe e commenti), nelle parole fuori da stringhe e commenti delle
  ## dichiarazioni non riconosciute (`non_riconosciuta`) e nei nomi qualificati `name.y` di un blocco CSC (`E20`, solo per `csc`).
  ## Preselezione e righe bloccate si decidono altrove; qui `pre` vale la regola di cat e genere, `n` si numera dopo.
  for fi, f in files:
    if f.unreadable.len > 0 or not fileSel[fi]: continue
    let lines = f.rep.srcLines
    var defined = initHashSet[string]()
    for l in lines:
      let d = definitionLabel(l)
      if d.len > 0: defined.incl d
    var inStr = false
    proc addOcc(res: var seq[Occ], fi, ln, col: int, cat: string) =
      res.add Occ(file: fi, line: ln, col: col, cat: cat, text: trimWs(lines[ln - 1]))
    for ln in 1 .. lines.len:
      let line = lines[ln - 1]
      let isDef = definitionLabel(line).len > 0
      var i = 0
      while i <= line.len:
        var segA, segB = -1
        var cat = ""
        if inStr:
          let j = line.find('"', i)
          segA = i
          if j >= 0:
            segB = j
            i = j + 1
            inStr = false
          else:
            segB = line.len
            i = line.len + 1
          cat = "stringa"
        else:
          var k = i
          var found = false
          while k < line.len:
            if line[k] == '"':
              inStr = true
              i = k + 1
              found = true
              break
            if line[k] == '-' and k + 1 < line.len and line[k + 1] == '-':
              segA = k
              segB = line.len
              cat = "commento"
              i = line.len + 1
              found = true
              break
            inc k
          if not found: break
          if cat.len == 0: continue
        if cat.len == 0 or isDef: continue
        let seg = line[segA ..< segB]
        let ex = excludedRanges(seg, defined)
        for (a, b) in textWords(seg):
          if seg[a ..< b] != name: continue
          var skip = false
          for (x, y) in ex:
            if a >= x and a < y: skip = true
          if not skip: addOcc(result, fi, ln, segA + a, cat)
    # parole fuori da stringhe e commenti: dichiarazioni non riconosciute e nomi qualificati in un blocco CSC
    for k, t in f.toks:
      if t.kind != tkWord or t.text != name or (fi, t.line, t.col) in autoPos: continue
      if t.line >= 1 and t.line <= f.rep.lineClass.len and f.rep.lineClass[t.line - 1] == 'n':
        addOcc(result, fi, t.line, t.col, "non_riconosciuta")
      elif kind == rkCsc and k + 2 < f.toks.len and f.toks[k + 1].kind == tkSym and f.toks[k + 1].text == "." and
          f.toks[k + 2].kind == tkWord and f.toks[k + 1].line == t.line:
        var inCsc = false
        for b in f.rep.blocks:
          if b.headerOk and not b.isEntity and b.bk == "CSC" and t.line >= b.line and t.line <= b.endLine: inCsc = true
        if inCsc and isRec(f, t.line): addOcc(result, fi, t.line, t.col, "E20")

# ---------------------------------------------------------------- controlli di nome e di file (4)

proc lowerName*(s: string): string = unicode.toLower(s)

proc entryNames*(disk: string): seq[string] = listDir(disk)

proc blockDeclared*(files: seq[SrcFile], nm: string): (int, int) =
  ## 130:8:1 N4: (file, riga) del primo blocco CSC, ENTITY o PROFILE di nome `nm` nell'insieme; (-1, 0) se non c'è.
  for fi, f in files:
    if f.unreadable.len > 0: continue
    for b in f.rep.blocks:
      if b.headerOk and b.bk in ["CSC", "ENTITY", "PROFILE"] and b.name == nm: return (fi, b.line)
  (-1, 0)

proc idNameClash*(f: SrcFile, bi: int, nm: string): (int, string) =
  ## 130:8:2 N6: (riga, testo) dove `nm` è già un nome del blocco (nomi dichiarati, simboli, valori dei tipi, variabili di FOR ALL); riga 0 se libero.
  let b = f.rep.blocks[bi]
  for n in b.names:
    if n.name == nm: return (n.line, trimWs(f.rep.srcLines[n.line - 1]))
  if nm in b.syms: return (b.line, trimWs(f.rep.srcLines[b.line - 1]))
  for first in declFirsts(f, b.line + 1, b.endLine):
    let t = declToks(f, first)
    if t.len == 0: continue
    if t[0].kind == tkWord and t[0].text == "TYPE":
      for x in t:
        if x.kind == tkWord and x.text == nm: return (x.line, trimWs(f.rep.srcLines[x.line - 1]))
    for k in 0 ..< t.len - 2:
      if t[k].kind == tkWord and t[k].text == "FOR" and t[k + 1].kind == tkWord and t[k + 1].text == "ALL" and
          t[k + 2].kind == tkWord and t[k + 2].text == nm:
        return (t[k + 2].line, trimWs(f.rep.srcLines[t[k + 2].line - 1]))
  (0, "")

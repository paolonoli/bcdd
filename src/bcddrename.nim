# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 132:1:1 `bcdd rename` (GRAMMATICA_F1 sezione 15): rinomina di connettori, entità, posti e
# 132:1:2 identificativi in tutti i file `.csc` delle cartelle date, con anteprima e impronta, controllo invariato e scrittura tutto o niente.
# 132:1:3 Le posizioni, le righe bloccate e i testi stanno in bcddrenfind; il giornale e il ripristino in bcddrenwrite.
import std/[os, strutils, tables, algorithm, sets, sequtils]
import bcddlex, bcddcheck, bcddratify, bcddsafe, bcddsys, bcddtesti, bcddnew, bcddprog, bcddsave, bcddrenfind, bcddrenwrite

const P = "bcdd rename"

type
  Opts = object
    file, kindS, oldN, newN, csc, expect, textMode, recoverDir: string
    haveCsc, dryRun, haveExpect, json, haveRecover, haveText: bool
    dirs: seq[string]
    textAt: seq[string]
    kind: RKind

  Compagno = object
    file: int            # il file .csc a cui appartiene
    fromName, toName: string
    path, newPath: string
    text, newText: string
    mode: int

  Plan = object
    o: Opts
    folders: seq[Folder]
    files: seq[SrcFile]
    fileIdx: int
    tg: Target
    edits: seq[Edit]
    occs: seq[Occ]
    chosen: seq[bool]
    renames: Table[int, string]
    notRenamed: seq[int]
    comps: seq[Compagno]
    impronta: string
    newTexts: seq[string]
    controlloFile: int

proc uso(): string =
  let t = testo(kRinUso)
  t

proc usageDie() = die(uso(), 2)

# ---------------------------------------------------------------- uscita JSON e rifiuti

proc folderName(fo: Folder): string =
  ## 132:2:1 La cartella com'è scritta, senza il separatore finale; `.` se FILE non ne ha.
  if fo.shown.len == 0: return "."
  if fo.shown.len > 1 and isSepChar(fo.shown[^1]): return fo.shown[0 ..< fo.shown.len - 1]
  fo.shown

proc jarr(items: seq[string]): string = "[" & items.join(", ") & "]"
proc jnull(s: string): string = (if s.len == 0: "null" else: jstr(s))

proc head(o: Opts, esito, motivo, messaggio, impronta: string): string =
  "{\"forma\": \"bcdd-rename\", \"versione\": 1, \"lingua\": " & jstr($lingua) & ", \"esito\": " & jstr(esito) &
    ", \"motivo\": " & jnull(motivo) & ", \"messaggio\": " & jnull(messaggio) & ", \"tipo\": " & jstr(o.kindS) &
    ", \"vecchio\": " & jstr(o.oldN) & ", \"nuovo\": " & jstr(o.newN) & ", \"blocco\": " & (if o.haveCsc: jstr(o.csc) else: "null") &
    ", \"impronta\": " & jnull(impronta)

proc tail(files, compagni, testi, bloccanti: string, nFile: int, invariato: bool): string =
  ", \"file\": " & files & ", \"compagni\": " & compagni & ", \"testi\": " & testi & ", \"bloccanti\": " & bloccanti &
    ", \"controllo\": {\"file\": " & $nFile & ", \"invariato\": " & (if invariato: "true" else: "false") & "}}\n"

var gOpts: Opts
var gBloccantiJson = "[]"

proc refuse(motivo, msg: string, code = 1) =
  ## 132:2:2 Un rifiuto: con --json l'oggetto sullo standard output, poi il messaggio sullo standard error con il prefisso; codice 1.
  if gOpts.json:
    stdout.write head(gOpts, "rifiutato", motivo, P & ": " & msg, "") & tail("[]", "[]", "[]", gBloccantiJson, 0, false)
    stdout.flushFile()
  die(P & ": " & msg, code)

# ---------------------------------------------------------------- argomenti

proc parseArgs(args: seq[string]): Opts =
  var pos: seq[string]
  var i = 0
  var seenText = false
  while i < args.len:
    let a = args[i]
    if a == "--csc":
      if result.haveCsc or i + 1 >= args.len: usageDie()
      result.haveCsc = true
      result.csc = args[i + 1]
      i += 2
    elif a == "--dir":
      if i + 1 >= args.len or args[i + 1] in result.dirs: usageDie()
      result.dirs.add args[i + 1]
      i += 2
    elif a == "--dry-run":
      if result.dryRun: usageDie()
      result.dryRun = true
      inc i
    elif a == "--expect":
      if result.haveExpect or i + 1 >= args.len: usageDie()
      result.haveExpect = true
      result.expect = args[i + 1]
      i += 2
    elif a == "--text":
      if result.haveText or i + 1 >= args.len or args[i + 1] notin ["default", "none", "all"]: usageDie()
      result.haveText = true
      result.textMode = args[i + 1]
      i += 2
    elif a == "--text-at":
      if i + 1 >= args.len: usageDie()
      let t = args[i + 1]
      if t.len < 2 or t[0] != 't' or not t[1 .. ^1].allCharsInSet({'0' .. '9'}) or t in result.textAt: usageDie()
      result.textAt.add t
      seenText = true
      i += 2
    elif a == "--json":
      if result.json: usageDie()
      result.json = true
      inc i
    elif a.len > 0 and a[0] == '-': usageDie()
    else:
      pos.add a
      inc i
  if pos.len != 4: usageDie()
  if result.dryRun == result.haveExpect: usageDie()
  if (result.haveText or seenText) and not result.haveExpect: usageDie()
  if result.haveText and seenText: usageDie()
  result.file = pos[0]
  result.kindS = pos[1]
  result.oldN = pos[2]
  result.newN = pos[3]
  case result.kindS
  of "csc": result.kind = rkCsc
  of "entity": result.kind = rkEntity
  of "part": result.kind = rkPart
  of "id": result.kind = rkId
  else: usageDie()
  if result.haveCsc and result.kind in {rkCsc, rkEntity}: usageDie()
  if result.textMode.len == 0: result.textMode = "default"

# ---------------------------------------------------------------- testi: righe prima e dopo

proc applyAt(s: string, cuts: seq[(int, int)], oldLen: int, nw: string): string =
  ## 132:3:1 Sostituisce, nelle posizioni date (offset, in qualunque ordine), `oldLen` byte con `nw`.
  var c = cuts
  c.sort(proc(a, b: (int, int)): int = cmp(b[0], a[0]))
  result = s
  for (off, _) in c: result = result[0 ..< off] & nw & result[off + oldLen .. ^1]

proc newTextOf(pl: Plan, fi: int): string =
  ## 132:3:2 Il testo nuovo del file: i nomi che cambiano da soli e i testi scelti, sui byte originali (CRLF e BOM compresi).
  let f = pl.files[fi]
  var cuts: seq[(int, int)]
  for e in pl.edits:
    if e.file == fi: cuts.add (f.rl.starts[e.line - 1] + e.col, 0)
  for k, oc in pl.occs:
    if oc.file == fi and pl.chosen[k]: cuts.add (f.rl.starts[oc.line - 1] + oc.col, 0)
  applyAt(f.raw, cuts, pl.o.oldN.len, pl.o.newN)

proc lineAfter(pl: Plan, fi, line: int): string =
  let f = pl.files[fi]
  var cuts: seq[(int, int)]
  for e in pl.edits:
    if e.file == fi and e.line == line: cuts.add (e.col, 0)
  applyAt(f.rep.srcLines[line - 1], cuts, pl.o.oldN.len, pl.o.newN)

# ---------------------------------------------------------------- le impronte e i controlli di file

proc destNames(o: Opts): seq[string] =
  if o.kind in {rkCsc, rkEntity}: @[o.newN & ".csc", o.newN & ".csc.dialogo"] else: @[]

proc computeFingerprint(o: Opts, folders: seq[Folder], files: seq[SrcFile]): string =
  ## 132:4:1 A2, formato `bcdd-rename 1`: una voce per riga, tabulatori fra i campi. Lo stesso stato dà la stessa impronta; cambia se cambia
  ## un file, se un file .csc compare o scompare, se compare un nome di destinazione (confronto senza maiuscole, come N7).
  var t = "bcdd-rename 1\n" & o.kindS & "\t" & o.oldN & "\t" & o.newN & "\t" & (if o.haveCsc: o.csc else: "-") & "\n"
  for fo in folders: t.add "cartella\t" & fo.real & "\n"
  for f in files: t.add "file\t" & $f.dir & "\t" & f.name & "\t" & f.fp & "\n"
  for d, fo in folders:
    let names = entryNames(fo.disk)
    for dn in destNames(o):
      var ex = false
      for n in names:
        if lowerName(n) == lowerName(dn): ex = true
      t.add "destinazione\t" & $d & "\t" & dn & "\t" & (if ex: "esiste" else: "assente") & "\n"
  fingerprint(t)

proc loadGiroRename(txt, kw, oldN, newN: string): string =
  ## 132:4:2 F2: nelle righe `GIRO DATA CSC N` e `GIRO DATA ENTITY N` il nome cambia; il resto del dialogo resta identico byte per byte.
  var parts = txt.split('\n')
  for k in 0 ..< parts.len:
    var l = parts[k]
    var cr = ""
    if l.endsWith("\r"):
      cr = "\r"
      l.setLen(l.len - 1)
    if l.startsWith("GIRO "):
      let w = l.split(' ')
      if w.len == 4 and w[2] == kw and w[3] == oldN: parts[k] = w[0] & " " & w[1] & " " & w[2] & " " & newN & cr
  parts.join("\n")

# ---------------------------------------------------------------- il piano

proc sameFileIdx(files: seq[SrcFile], fileArg: string): int =
  for k, f in files:
    try:
      if sameFile(f.path, fileArg): return k
    except OSError:
      discard
  -1

proc firstLineOfBlock(f: SrcFile, line: int): string = trimWs(f.rep.srcLines[line - 1])

proc occSort(a, b: Occ): int =
  result = cmp(a.file, b.file)
  if result == 0: result = cmp(a.line, b.line)
  if result == 0: result = cmp(a.col, b.col)

proc blocked(f: SrcFile, line: int): bool = line in f.blocked

proc checkSignature(text, shownPath: string, dirsShown: seq[string]): (string, string) =
  ## 132:5:1 A5: l'esito di `check --strict` di un file, ridotto a ciò che deve restare uguale: codice d'uscita, errori (codice e riga),
  ## righe non riconosciute, citazioni (tipo, riga, trovata, versione trovata, versione attesa). Nomi, colonne e messaggi non si confrontano.
  var rep = analyze(text)
  resolveCitations(rep, shownPath, dirsShown)
  var errs: seq[string]
  for e in rep.errs: errs.add e.code & "@" & $e.line
  errs.sort()
  var unrec: seq[string]
  for i, c in rep.lineClass:
    if c == 'n': unrec.add $(i + 1)
  var cites: seq[string]
  proc one(c: Cite, f: Found, ok: bool): string =
    $c.kind & "@" & $c.line & ":" & (if ok and f.ok: "found " & f.version & (if f.viaFallback: " fallback" else: "") else: "no") & " wanted " & c.version
  for b in rep.blocks:
    for k, c in b.cites: cites.add one(c, (if k < b.found.len: b.found[k] else: Found()), k < b.found.len)
    for k, c in b.xcites: cites.add one(c, (if k < b.xfound.len: b.xfound[k] else: Found()), k < b.xfound.len)
  let code = exitCodeFor(rep, true)
  ("rc=" & $code & "; E=[" & errs.join(",") & "]; U=[" & unrec.join(",") & "]", cites.join(" | "))

proc buildPlan(o: Opts): Plan =
  var pl = Plan(o: o)
  gOpts = o
  # 132:6:1 Codice 2: il nome nuovo (N1, N2), poi FILE e le cartelle (come check, prefisso `bcdd rename:`)
  if o.haveCsc and not validName(o.csc): die(testo(kNomeNonValido, P, o.csc), 2)
  let okNew = if o.kind == rkId: validId(o.newN) else: validName(o.newN)
  if not okNew: die(P & ": " & testo(kRinNomeNonValido, o.kindS, o.newN), 2)
  if o.kind in {rkCsc, rkEntity} and isDeviceName(o.newN):
    let m = testo(kNewNomeDispositivo, o.newN)
    die(P & m[("bcdd new").len .. ^1], 2)
  discard loadSource(P, o.file)
  for d in o.dirs: checkDirArg(P, d)
  pl.folders = buildFolders(o.file, o.dirs)
  pl.files = loadSet(pl.folders, P)
  # I3: lo stesso nome di file in due cartelle
  for a in 0 ..< pl.files.len:
    for b in a + 1 ..< pl.files.len:
      if pl.files[a].name == pl.files[b].name and pl.files[a].dir != pl.files[b].dir:
        refuse("doppio", testo(kRinDoppio, pl.files[a].name, folderName(pl.folders[pl.files[a].dir]), folderName(pl.folders[pl.files[b].dir])))
  # I4: un file dell'insieme che non si legge o non è UTF-8
  for f in pl.files:
    if f.unreadable.len > 0:
      refuse("illeggibile", testo(kRinIllegg, f.shown, (if f.unreadable == "non_utf8": testo(kRinNonUtf8) else: testo(kRinNonLeggibile))))
  pl.impronta = computeFingerprint(o, pl.folders, pl.files)
  if o.haveExpect and o.expect != pl.impronta: refuse("cambiato", testo(kRinCambiato))
  analyzeFiles(pl.files)
  pl.fileIdx = sameFileIdx(pl.files, o.file)
  # 132:6:2 Il bersaglio: dichiarazione assente (non_trovato)
  pl.tg = Target(file: -1, bi: -1)
  case o.kind
  of rkCsc, rkEntity:
    let bk = if o.kind == rkCsc: "CSC" else: "ENTITY"
    var has = false
    if pl.fileIdx >= 0:
      for b in pl.files[pl.fileIdx].rep.blocks:
        if b.headerOk and b.bk == bk and b.name == o.oldN: has = true
    if not has: refuse("non_trovato", testo(kRinNonContiene, o.file, bk, o.oldN))
  of rkPart, rkId:
    if pl.fileIdx < 0:
      refuse("non_trovato", (if o.kind == rkId: testo(kRinNessunId, o.oldN, (if o.haveCsc: o.csc else: o.file)) else: testo(kRinNessunaParte, o.oldN, (if o.haveCsc: o.csc else: o.file))))
    let f = pl.files[pl.fileIdx]
    let bi = chooseBlock(P, f.rep, o.haveCsc, o.csc)
    let b = f.rep.blocks[bi]
    pl.tg = Target(file: pl.fileIdx, bi: bi, name: b.name, version: b.version)
    gOpts.csc = b.name
    gOpts.haveCsc = true
    var has = false
    if o.kind == rkId:
      for n in b.names:
        if n.name == o.oldN and n.kind in ["ROW", "SCENARIO"]: has = true
      if not has: refuse("non_trovato", testo(kRinNessunId, o.oldN, b.name))
    else:
      for c in b.cites:
        if c.kind == ckPart and c.part == o.oldN: has = true
      if not has: refuse("non_trovato", testo(kRinNessunaParte, o.oldN, b.name))
  let sc = scanNames(pl.files, o.kind, o.oldN, pl.tg)
  pl.edits = sc.edits
  var declFiles = initHashSet[int]()
  for e in pl.edits:
    if e.decl: declFiles.incl e.file
  if declFiles.len == 0 and o.kind in {rkCsc, rkEntity}:
    refuse("non_trovato", testo(kRinNonContiene, o.file, (if o.kind == rkCsc: "CSC" else: "ENTITY"), o.oldN))
  # 132:6:3 Quali file si rinominano (F1): quello che si chiama esattamente N.csc e contiene la dichiarazione
  if o.kind in {rkCsc, rkEntity}:
    for fi in declFiles.toSeq.sorted:
      if pl.files[fi].name == o.oldN & ".csc": pl.renames[fi] = o.newN & ".csc"
      else: pl.notRenamed.add fi
  # 132:6:4 K: il giornale di una rinomina interrotta, in ogni cartella in cui cambierebbe un file
  var changedDirs: seq[int]
  for e in pl.edits:
    if pl.files[e.file].dir notin changedDirs: changedDirs.add pl.files[e.file].dir
  for d in changedDirs:
    if journalPresent(pl.folders[d].disk):
      let info = journalInfo(pl.folders[d].disk).split(" -> ")
      refuse("giornale", testo(kRinGiornale, folderName(pl.folders[d]), info[0], info[^1]))
  # N3
  if o.newN == o.oldN: refuse("uguale", testo(kRinUguale))
  # N4: nome già dichiarato
  if o.kind in {rkCsc, rkEntity}:
    let (fi, ln) = blockDeclared(pl.files, o.newN)
    if fi >= 0: refuse("collisione", testo(kRinCollisione, o.newN, pl.files[fi].shown, ln, firstLineOfBlock(pl.files[fi], ln)))
    # N5: nome già citato senza essere dichiarato
    let sc2 = scanNames(pl.files, o.kind, o.newN, pl.tg)
    for e in sc2.edits:
      if not e.decl:
        refuse("cattura", testo(kRinCattura, o.newN, pl.files[e.file].shown, e.line, o.oldN))
  else:
    let f = pl.files[pl.tg.file]
    let (ln, tx) = idNameClash(f, pl.tg.bi, o.newN)
    if ln > 0: refuse("collisione", testo(kRinCollisione, o.newN, f.shown, ln, tx))
  # N7 e F4: i file da rinominare
  for fi, nn in pl.renames:
    let f = pl.files[fi]
    let fo = pl.folders[f.dir]
    let t1 = o.newN & ".csc"
    let t2 = o.newN & ".csc.dialogo"
    for e in entryNames(fo.disk):
      let low = lowerName(e)
      if low != lowerName(t1) and low != lowerName(t2): continue
      if e == f.name and low == lowerName(t1): continue
      if e == f.name & ".dialogo" and low == lowerName(t2): continue
      if e == t1 or e == t2: refuse("file_esiste", testo(kRinFileEsiste, fileShown(fo.shown, e)))
      refuse("file_esiste", testo(kRinFileEsisteWin, e, (if low == lowerName(t1): t1 else: t2)))
    if f.isLink: refuse("collegamento", testo(kRinLinkSimbolico, f.shown))
    if f.nlink > 1: refuse("collegamento", testo(kRinPiuLink, f.shown))
    let dp = f.path & ".dialogo"
    if pathExistsNoFollow(dp):
      let st = pathInfo(dp)
      if symlinkExists(dp): refuse("collegamento", testo(kRinLinkSimbolico, f.shown & ".dialogo"))
      if st.ok and st.isFile:
        if st.nlink > 1: refuse("collegamento", testo(kRinPiuLink, f.shown & ".dialogo"))
        var txt = ""
        try: txt = readFile(dp)
        except IOError, OSError: refuse("illeggibile", testo(kRinIllegg, f.shown & ".dialogo", testo(kRinNonLeggibile)))
        let kw = if o.kind == rkCsc: "CSC" else: "ENTITY"
        pl.comps.add Compagno(file: fi, fromName: f.name & ".dialogo", toName: nn & ".dialogo", path: dp,
          newPath: (if fo.disk == ".": nn & ".dialogo" else: joinShown(fo.disk, nn & ".dialogo")),
          text: txt, newText: loadGiroRename(txt, kw, o.oldN, o.newN), mode: st.mode)
  # più collegamenti fisici su un file soltanto da riscrivere: si rifiuta prima di cominciare (scrittura sicura di ratify)
  for e in pl.edits:
    let f = pl.files[e.file]
    if e.file notin pl.renames and f.nlink > 1: refuse("collegamento", testo(kRinPiuLink, f.shown))
  # 132:6:5 B1, B2: le righe bloccate
  for f in pl.files.mitems: computeBlocked(f, o.kind)
  var bloc: seq[Bloc]
  var seenBl = initHashSet[(int, int)]()
  for e in pl.edits:
    if blocked(pl.files[e.file], e.line) and (e.file, e.line) notin seenBl:
      seenBl.incl (e.file, e.line)
      bloc.add Bloc(file: e.file, line: e.line, why: pl.files[e.file].blocked[e.line])
  if bloc.len > 0:
    var js: seq[string]
    var lines: seq[string]
    for b in bloc:
      let f = pl.files[b.file]
      js.add "{\"cartella\": " & jstr(folderName(pl.folders[f.dir])) & ", \"file\": " & jstr(f.name) & ", \"riga\": " & $b.line &
        ", \"motivo\": " & jstr(whyCode(b.why)) & ", \"decisione\": " & jnull(b.why.dec) & ", \"testo\": " & jstr(firstLineOfBlock(f, b.line)) & "}"
      lines.add testo(kRinApprovatoRiga, f.shown, b.line, firstLineOfBlock(f, b.line), whyText(b.why))
    gBloccantiJson = jarr(js)
    refuse("approvato", (if bloc.len == 1: testo(kRinApprovato1, o.oldN) else: testo(kRinApprovatoN, o.oldN, bloc.len)) & "\n" &
      lines.join("\n") & "\n" & testo(kRinApprovatoFine))
  # 132:6:6 I testi liberi (T1-T8): dove si cercano, categorie, preselezione, numeri
  var sel = newSeq[bool](pl.files.len)
  if o.kind in {rkCsc, rkEntity}:
    for k in 0 ..< sel.len: sel[k] = true
  else:
    sel[pl.tg.file] = true
    for e in pl.edits: sel[e.file] = true
  var autoPos = initHashSet[(int, int, int)]()
  for e in pl.edits: autoPos.incl (e.file, e.line, e.col)
  var occs = scanTexts(pl.files, sel, o.kind, o.oldN, autoPos)
  var ambiguous = false      # T5: un'altra CSC o entità dello stesso nome nell'insieme (un altro genere): niente preselezione
  if o.kind in {rkCsc, rkEntity}:
    let other = if o.kind == rkCsc: ["ENTITY", "PROFILE"] else: ["CSC", "PROFILE"]
    for f in pl.files:
      for b in f.rep.blocks:
        if b.headerOk and b.bk in other and b.name == o.oldN: ambiguous = true
  elif o.kind == rkId:
    # 132:6:7 C-1 (T5): un altro blocco dei file cercati che dichiara lo stesso nome (ROW o SCENARIO, anche in un VERIFICATION) toglie la preselezione
    for fi, f in pl.files:
      if not sel[fi]: continue
      for bi, b in f.rep.blocks:
        if fi == pl.tg.file and bi == pl.tg.bi: continue
        for n in b.names:
          if n.name == o.oldN and n.kind in ["ROW", "SCENARIO"]: ambiguous = true
  occs.sort(proc(a, b: Occ): int =
    result = cmp(pl.files[a.file].dir, pl.files[b.file].dir)
    if result == 0: result = cmp(pl.files[a.file].name, pl.files[b.file].name)
    if result == 0: result = cmp(a.line, b.line)
    if result == 0: result = cmp(a.col, b.col))
  for k in 0 ..< occs.len:
    occs[k].n = k + 1
    let f = pl.files[occs[k].file]
    if occs[k].line in f.blocked: occs[k].blockedWhy = whyText(f.blocked[occs[k].line])
    occs[k].pre = o.kind != rkPart and occs[k].cat in ["stringa", "commento"] and not ambiguous and occs[k].blockedWhy.len == 0
  pl.occs = occs
  # A4: la scelta dei testi
  pl.chosen = newSeq[bool](occs.len)
  if o.haveExpect:
    if o.textAt.len > 0:
      for t in o.textAt:
        let n = parseInt(t[1 .. ^1])
        if n < 1 or n > occs.len: refuse("testo", testo(kRinTestoNonEsiste, t))
        if occs[n - 1].blockedWhy.len > 0: refuse("testo", testo(kRinTestoBloccato, t))
        pl.chosen[n - 1] = true
    else:
      for k in 0 ..< occs.len:
        case o.textMode
        of "none": discard
        of "all": pl.chosen[k] = occs[k].blockedWhy.len == 0
        else: pl.chosen[k] = occs[k].pre
  else:
    for k in 0 ..< occs.len: pl.chosen[k] = occs[k].pre
  # i testi nuovi
  pl.newTexts = newSeq[string](pl.files.len)
  for fi in 0 ..< pl.files.len: pl.newTexts[fi] = newTextOf(pl, fi)
  # B5: ogni file riscritto passa le regole di `bcdd save`
  for fi, f in pl.files:
    if pl.newTexts[fi] != f.raw:
      if saveRulesViolation(f.raw, pl.newTexts[fi]).len > 0: refuse("interno", testo(kRinInterno2, f.shown))
  # A5: l'esito del controllo resta invariato su tutti i file, prima e dopo
  var dirsShown: seq[string]
  for fo in pl.folders: dirsShown.add (if fo.shown.len == 0: "." else: fo.shown)
  vfsOn = true
  vfsFiles = initTable[string, string]()
  vfsGone = initHashSet[string]()
  for f in pl.files: vfsFiles[vfsKey(f.path)] = f.raw
  var before: seq[(string, string)]
  for f in pl.files: before.add checkSignature(f.raw, f.shown, dirsShown)
  vfsFiles = initTable[string, string]()
  for fi, f in pl.files:
    let fo = pl.folders[f.dir]
    let np = if fi in pl.renames: (if fo.disk == ".": pl.renames[fi] else: joinShown(fo.disk, pl.renames[fi])) else: f.path
    vfsFiles[vfsKey(np)] = pl.newTexts[fi]
    if fi in pl.renames: vfsGone.incl vfsKey(f.path)
  for fi, f in pl.files:
    let fo = pl.folders[f.dir]
    let shownNew = if fi in pl.renames: fileShown(fo.shown, pl.renames[fi]) else: f.shown
    let after = checkSignature(pl.newTexts[fi], shownNew, dirsShown)
    if after != before[fi]:
      let (b0, b1) = before[fi]
      let a0 = after[0]
      let a1 = after[1]
      refuse("interno", testo(kRinInterno1, f.shown, (if b0 != a0: b0 else: b1), (if b0 != a0: a0 else: a1)))
  vfsOn = false
  pl.controlloFile = pl.files.len
  pl

# ---------------------------------------------------------------- l'uscita

proc numRighe(n: int): string =
  ## 132:7:1 C-9: «1 riga» solo con il numero 1; 0 e ogni altro numero al plurale
  if n == 1: testo(kRinNumRighe1) else: testo(kRinNumRigheN, n)

proc numFile(n: int): string =
  ## 132:7:2 C-9: come numRighe, per i file
  if n == 1: testo(kRinNumFile1) else: testo(kRinNumFileN, n)

proc catText(c: string): string =
  case c
  of "stringa": testo(kRinCatStringa)
  of "commento": testo(kRinCatCommento)
  of "non_riconosciuta": testo(kRinCatNonRic)
  else: c

proc changedFileIdx(pl: Plan): seq[int] =
  for fi in 0 ..< pl.files.len:
    if pl.newTexts[fi] != pl.files[fi].raw: result.add fi

proc autoLines(pl: Plan, fi: int): seq[int] =
  for e in pl.edits:
    if e.file == fi and e.line notin result: result.add e.line
  result.sort()

proc commandToWrite(pl: Plan): string =
  var s = "bcdd rename " & pl.o.file
  if pl.o.haveCsc and pl.o.kind in {rkPart, rkId}: s.add " --csc " & pl.tg.name
  for d in pl.o.dirs: s.add " --dir " & d
  s & " --expect " & pl.impronta & " " & pl.o.kindS & " " & pl.o.oldN & " " & pl.o.newN

proc renderPreview(pl: Plan, written: bool, nameChanged: int, textsChanged: int, left: seq[int]): string =
  var o = ""
  o.add testo((if written: kRinScritto else: kRinAnteprima), pl.o.kindS, pl.o.oldN, pl.o.newN) & "\n"
  for fi, nn in pl.renames:
    let f = pl.files[fi]
    o.add testo(kRinFileRinominato, f.shown, fileShown(pl.folders[f.dir].shown, nn)) & "\n"
  for c in pl.comps:
    let f = pl.files[c.file]
    o.add testo(kRinFileRinominato, fileShown(pl.folders[f.dir].shown, c.fromName), fileShown(pl.folders[f.dir].shown, c.toName)) & "\n"
  if not written:
    for fi in pl.notRenamed:
      o.add testo(kRinFileNonRinominato, pl.files[fi].shown) & "\n"
    for fi in 0 ..< pl.files.len:
      let ls = autoLines(pl, fi)
      if ls.len == 0: continue
      o.add pl.files[fi].shown & "\n"
      for ln in ls:
        let pre = testo(kRinRiga, ln)
        let before = trimWs(pl.files[fi].rep.srcLines[ln - 1])
        let after = trimWs(lineAfter(pl, fi, ln))
        o.add pre & before & "\n" & " ".repeat(max(0, pre.len - 3)) & "-> " & after & "\n"
    if pl.occs.len > 0:
      o.add testo(kRinTestiTitolo) & "\n"
      for oc in pl.occs:
        let mark = if oc.blockedWhy.len > 0: "=" elif pl.chosen[oc.n - 1]: "x" else: " "
        o.add testo(kRinTesto, oc.n, mark, pl.files[oc.file].shown, oc.line, catText(oc.cat), oc.text) & "\n"
    o.add testo(kRinControllo, numFile(pl.files.len)) & "\n"
    o.add testo(kRinImpronta, pl.impronta) & "\n"
    o.add testo(kRinPerScrivere, commandToWrite(pl)) & "\n"
  else:
    var lt = ""
    if left.len > 0: lt = " (" & left.mapIt("t" & $it).join(", ") & ")"
    var nf = 0
    for fi in 0 ..< pl.files.len:
      if autoLines(pl, fi).len > 0: inc nf
    var nl = 0
    for fi in 0 ..< pl.files.len: nl += autoLines(pl, fi).len
    o.add testo(kRinRiepilogo, numRighe(nl), numFile(nf), textsChanged, $left.len & lt) & "\n"
    o.add testo(kRinControllo, numFile(pl.files.len)) & "\n"
  o

proc previewJson(pl: Plan, esito: string): string =
  var fl: seq[string]
  for fi in changedFileIdx(pl):
    let f = pl.files[fi]
    var mods: seq[string]
    for e in pl.edits:
      if e.file != fi: continue
      mods.add "{\"riga\": " & $e.line & ", \"colonna\": " & $e.col & ", \"genere\": " & jstr(e.genere) & ", \"prima\": " &
        jstr(trimWs(f.rep.srcLines[e.line - 1])) & ", \"dopo\": " & jstr(trimWs(lineAfter(pl, fi, e.line))) & "}"
    fl.add "{\"cartella\": " & jstr(folderName(pl.folders[f.dir])) & ", \"nome\": " & jstr(f.name) & ", \"nome_nuovo\": " &
      (if fi in pl.renames: jstr(pl.renames[fi]) else: "null") & ", \"impronta\": " & jstr(f.fp) & ", \"impronta_nuova\": " &
      jstr(fingerprint(pl.newTexts[fi])) & ", \"modifiche\": " & jarr(mods) & "}"
  var cl: seq[string]
  for c in pl.comps:
    cl.add "{\"cartella\": " & jstr(folderName(pl.folders[pl.files[c.file].dir])) & ", \"da\": " & jstr(c.fromName) & ", \"a\": " & jstr(c.toName) & "}"
  var tl: seq[string]
  for oc in pl.occs:
    let f = pl.files[oc.file]
    tl.add "{\"n\": " & jstr("t" & $oc.n) & ", \"cartella\": " & jstr(folderName(pl.folders[f.dir])) & ", \"file\": " & jstr(f.name) &
      ", \"riga\": " & $oc.line & ", \"colonna\": " & $oc.col & ", \"categoria\": " & jstr(oc.cat) & ", \"scelto\": " &
      (if pl.chosen[oc.n - 1]: "true" else: "false") & ", \"bloccato\": " & (if oc.blockedWhy.len > 0: jstr(whyCode(f.blocked[oc.line])) else: "null") &
      ", \"testo\": " & jstr(oc.text) & "}"
  head(gOpts, esito, "", "", pl.impronta) & tail(jarr(fl), jarr(cl), jarr(tl), "[]", pl.files.len, true)

proc writePlan(pl: var Plan) =
  ## 132:7:1 Le operazioni del giornale, nell'ordine di 6.2: prima le `sostituisci`, poi le `rinomina` e le `sposta`.
  var ops: seq[Op]
  var moves: seq[Op]
  for fi in changedFileIdx(pl):
    let f = pl.files[fi]
    let fo = pl.folders[f.dir]
    if fi in pl.renames:
      let np = if fo.disk == ".": pl.renames[fi] else: joinShown(fo.disk, pl.renames[fi])
      var op = Op(kind: "rinomina", fromP: f.path, toP: np, oldFp: f.fp, newFp: fingerprint(pl.newTexts[fi]), mode: f.mode,
        oldText: f.raw, newText: pl.newTexts[fi])
      op.caseOnly = lowerName(pl.renames[fi]) == lowerName(f.name)
      moves.add op
    else:
      var target = f.path
      if f.isLink:
        try: target = expandFilename(f.path)
        except OSError: discard
      ops.add Op(kind: "sostituisci", fromP: target, toP: target, oldFp: f.fp, newFp: fingerprint(pl.newTexts[fi]), mode: f.mode,
        oldText: f.raw, newText: pl.newTexts[fi])
  for c in pl.comps:
    var op = Op(kind: "sposta", fromP: c.path, toP: c.newPath, oldFp: fingerprint(c.text), newFp: fingerprint(c.newText), mode: c.mode,
      oldText: c.text, newText: c.newText)
    op.caseOnly = lowerName(c.toName) == lowerName(c.fromName)
    moves.add op
  ops.add moves
  let cmd = pl.o.kindS & " " & pl.o.oldN & " " & pl.o.newN
  let r = commit(ops, cmd)
  let shownOf = proc(p: string): string = p
  case r.kind
  of ckOk:
    var nChosen = 0
    var left: seq[int]
    for oc in pl.occs:
      if pl.chosen[oc.n - 1]: inc nChosen else: left.add oc.n
    let txt = renderPreview(pl, true, 0, nChosen, left)
    if pl.o.json: stdout.write previewJson(pl, "scritto")
    else: stdout.write txt
    stdout.flushFile()
    quit(0)
  of ckJournalExists:
    let info = journalInfo(r.dir).split(" -> ")
    refuse("giornale", testo(kRinGiornale, r.dir, info[0], info[^1]))
  of ckWriteNothing:
    if r.why.len == 0: refuse("scrittura", testo(kRinPercorsoStrano, r.file))
    refuse("scrittura", testo(kRinScrittura1, shownOf(r.file), r.why))
  of ckChanged: refuse("cambiato", testo(kRinCambiato))
  of ckRestored: refuse("scrittura", testo(kRinScrittura2, shownOf(r.file), r.why))
  of ckRestoreFailed:
    refuse("scrittura", testo(kRinScrittura3, shownOf(r.file), r.why, folderName(pl.folders[0])))

# ---------------------------------------------------------------- --recover

proc runRecover(o: Opts) =
  gOpts = o
  let d = o.recoverDir
  checkDirArg(P, d)
  let r = recoverDir(d)
  proc ok(esito, msg: string) =
    if o.json:
      stdout.write head(o, esito, "", P & ": " & msg, "") & tail("[]", "[]", "[]", "[]", 0, true)
    else:
      stdout.write P & ": " & msg & "\n"
    stdout.flushFile()
    quit(0)
  let parts = r.cmd.split(' ')
  var o2 = o
  if parts.len == 3:
    o2.kindS = parts[0]
    o2.oldN = parts[1]
    o2.newN = parts[2]
  gOpts = o2
  case r.kind
  of rcNoJournal: refuse("giornale", testo(kRinNoGiornale, d))
  of rcAlreadyDone: ok("completato", testo(kRinRipristinoCompleto).substr(("bcdd rename: ").len))
  of rcRestored: ok("ripristinato", testo(kRinRipristinoIndietro).substr(("bcdd rename: ").len))
  of rcForeign:
    refuse("scrittura", testo(kRinEstraneo, extractFilename(r.file), extractFilename(r.copy)))
  of rcBroken: refuse("scrittura", testo(kRinGiornaleStorto, journalPath(d)))
  of rcUndoFailed: refuse("scrittura", testo(kRinRipristinoFallito, extractFilename(r.file), r.why, d))
  of rcUnreadable: refuse("scrittura", testo(kRinGiornaleIllegibile, journalPath(d), r.why))

# ---------------------------------------------------------------- il comando

proc runRename*(args: seq[string]) =
  if args.len == 0: usageDie()
  if "--recover" in args:
    var o = Opts(haveRecover: true)
    var pos: seq[string]
    var i = 0
    var haveRec = false
    while i < args.len:
      if args[i] == "--recover":
        if haveRec or i + 1 >= args.len: usageDie()
        haveRec = true
        o.recoverDir = args[i + 1]
        i += 2
      elif args[i] == "--json":
        if o.json: usageDie()
        o.json = true
        inc i
      else: usageDie()
    runRecover(o)
    return
  let o = parseArgs(args)
  var pl = buildPlan(o)
  if o.dryRun:
    if o.json: stdout.write previewJson(pl, "anteprima")
    else: stdout.write renderPreview(pl, false, 0, 0, @[])
    stdout.flushFile()
    quit(0)
  writePlan(pl)

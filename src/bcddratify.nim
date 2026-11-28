# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 080:1:1 `bcdd ratify`: trasforma in contratto una riga o l'intera CSC citando una decisione.
# 080:1:2 Cambia una riga sola del file, o ne aggiunge una; ogni altro byte resta identico (g-t1, g-t2, g-x1).
import std/[strutils, algorithm]
import bcddlex, bcddcheck, bcddnew, bcddsafe, bcddtesti

type
  RawLines* = object
    starts*: seq[int]    # offset in raw dove comincia la riga n (indice n-1), dopo l'eventuale BOM
    ends*: seq[int]      # offset in raw dove finisce il contenuto della riga (prima di CR LF o LF)
    eol*: seq[string]    # "\r\n", "\n" oppure "" (ultima riga senza LF)

proc rawLines*(raw: string): RawLines =
  ## 081:1:1 Posizione di ogni riga nel testo originale (con BOM e CR LF), con la stessa numerazione di check.
  var i = 0
  if raw.len >= 3 and raw[0] == '\xEF' and raw[1] == '\xBB' and raw[2] == '\xBF': i = 3
  var start = i
  while i < raw.len:
    if raw[i] == '\n':
      var e = i
      var eol = "\n"
      if e > start and raw[e - 1] == '\r':
        dec e
        eol = "\r\n"
      result.starts.add start
      result.ends.add e
      result.eol.add eol
      start = i + 1
    inc i
  if start < raw.len:
    result.starts.add start
    result.ends.add raw.len
    result.eol.add ""

proc validId*(s: string): bool =
  ## 082:1:1 Regola L8: una parola (anche con '-' fra due caratteri), non riservata.
  if s.len == 0 or firstInvalidUtf8(s) >= 0 or isReservedWord(s): return false
  let lx = lex(s)
  lx.toks.len == 1 and lx.toks[0].kind == tkWord and lx.toks[0].text == s

proc validDecision*(s: string): bool =
  s.len > 2 and s.startsWith("D-") and s[2 .. ^1].allCharsInSet({'0' .. '9'})

proc leadingWs(s: string): string =
  var i = 0
  while i < s.len and (s[i] == ' ' or s[i] == '\t'): inc i
  s[0 ..< i]

proc composeBlockRatify*(raw: string, b: BlockInfo, dec: string): string =
  ## 083:1:1 Casi c1 e c2 della sezione 2.3. Il chiamante ha già escluso c3.
  let rl = rawLines(raw)
  if b.status == skHyp:
    let off = rl.starts[b.statusLine - 1] + b.statusCol
    return raw[0 ..< off] & "RATIFIED BY " & dec & raw[off + "HYPOTHESIS".len .. ^1]
  let fl = b.firstDeclLine
  let indent = leadingWs(raw[rl.starts[fl - 1] ..< rl.ends[fl - 1]])
  let hl = b.line
  var eol = rl.eol[hl - 1]
  if eol.len == 0: eol = "\n"
  let at = rl.ends[hl - 1] + (if rl.eol[hl - 1].len == 0: 0 else: rl.eol[hl - 1].len)
  if rl.eol[hl - 1].len == 0:
    return raw & eol & indent & "STATUS RATIFIED BY " & dec & eol
  raw[0 ..< at] & indent & "STATUS RATIFIED BY " & dec & eol & raw[at .. ^1]

proc composeRowRatify*(raw: string, r: RowInfo, dec: string): string =
  ## 083:2:1 Casi r1 e r2 della sezione 2.3. Il chiamante ha già escluso r3.
  let rl = rawLines(raw)
  if r.hypLine > 0:
    let off = rl.starts[r.hypLine - 1] + r.hypCol
    return raw[0 ..< off] & "RATIFIED BY " & dec & raw[off + "HYPOTHESIS".len .. ^1]
  let off = rl.starts[r.line - 1] + r.idEndCol
  raw[0 ..< off] & " STATUS RATIFIED BY " & dec & raw[off .. ^1]

proc usoRatify(): string = testo(kUsoBcddRatifyFILECsc)

type Edit = object
  off, del: int
  ins: string

proc chooseBlock*(P: string, rep: Report, haveCsc: bool, name: string, forRatify = false): int =
  ## 085:1:1 (F3b, 1.0-beta sezione 12.2 passo 5, S-19) Scelta del blocco, uguale per `ratify` e `refine`.
  var cscIdx, entIdx, otherIdx: seq[int]
  for k, b in rep.blocks:
    if b.isView: continue
    if b.bk == "ENTITY": entIdx.add k
    elif b.bk == "CSC": cscIdx.add k
    elif b.bk in ["BINDING", "PROFILE"] and forRatify: otherIdx.add k
  if forRatify:
    if haveCsc:
      # la CSC, l'entità o il profilo NOME; poi il BINDING con nome proprio NOME; poi l'unico BINDING senza nome legato a NOME
      for k, b in rep.blocks:
        if b.headerOk and b.bk in ["CSC", "ENTITY", "PROFILE"] and b.name == name: return k
      for k, b in rep.blocks:
        if b.headerOk and b.bk == "BINDING" and b.ownName == name: return k
      var cand: seq[int]
      for k, b in rep.blocks:
        if b.headerOk and b.bk == "BINDING" and b.ownName.len == 0 and b.legataName == name: cand.add k
      if cand.len == 1: return cand[0]
      die(testo(kNessunBloccoDaRatificareCon, P, name), 1)
    if cscIdx.len > 1: die(testo(kIlFileContieneCSCIndica, P, $cscIdx.len), 2)
    if cscIdx.len == 1: return cscIdx[0]
    if entIdx.len > 1: die(testo(kIlFileContieneENTITYIndica, P, $entIdx.len), 2)
    if entIdx.len == 1: return entIdx[0]
    if otherIdx.len > 1: die(testo(kIlFileContieneBlocchiDa, P, $otherIdx.len), 2)
    if otherIdx.len == 1: return otherIdx[0]
    die(testo(kIlFileNonContieneNessun, P), 1)
  if cscIdx.len == 0 and entIdx.len == 0:
    die(testo(kIlFileNonContieneNessuna2, P), 1)
  if haveCsc:
    for k in cscIdx & entIdx:
      if rep.blocks[k].name == name: return k
    die(testo(kNessunaCSCNeENTITYNel, P, name), 1)
  if cscIdx.len > 1: die(testo(kIlFileContieneCSCIndica, P, $cscIdx.len), 2)
  if cscIdx.len == 1: return cscIdx[0]
  if entIdx.len > 1: die(testo(kIlFileContieneENTITYIndica, P, $entIdx.len), 2)
  if entIdx.len == 1: return entIdx[0]
  die(testo(kNessunaCSCNeENTITYNel2, P), 1)   # 085:1:2 irraggiungibile: senza blocchi il file ha E11

proc citeText*(c: Cite): string =
  ## 085:2:1 La citazione com'è scritta: parola chiave, nome, ` VERSION w` se c'è.
  (if c.kind == ckOffers: "OFFERS " elif c.kind == ckUses: "USES " else: "") & c.name &
    (if c.version.len > 0: " VERSION " & c.version else: "")

proc checkBorders(P: string, blk: BlockInfo) =
  ## 085:3:1 (F3b, g-t3, B.2.6) Ogni OFFERS e USES dell'entità: trovata, nella versione chiesta, in un file senza errori.
  ## La prima che non va decide il messaggio; il file non si tocca.
  for k, c in blk.cites:
    if c.dup or c.kind == ckPart: continue
    let f = if k < blk.found.len: blk.found[k] else: Found()
    let head = testo(kENTITYRiga, P, blk.name, $c.line, citeText(c))
    let tail = testo(kNonRatificoLeSueGaranzie)
    if not f.ok:
      die(testo(kNonTrovata, head, (if f.reason.len > 0: " (" & f.reason & ")" else: ""), tail), 1)
    let where = testo(kRatDoveRiga, (if f.where.len == 0: testo(kRatInQuestoFile) else: "in " & f.where), f.line)
    if c.version.len > 0 and c.version != f.version:
      die(testo(kTrovataConVERSION, head, where, f.version, tail), 1)
    if f.errCount > 0:
      die(testo(kRatTrovataCheHa, head, where, esitoErrori(f.errCount), tail), 1)

proc rowEdit(raw: string, rl: RawLines, r: RowInfo, dec: string): Edit =
  ## 085:4:1 Casi r1 e r2 per una riga: la parola HYPOTHESIS diventa RATIFIED BY, oppure ` STATUS RATIFIED BY` dopo l'id.
  if r.hypLine > 0:
    Edit(off: rl.starts[r.hypLine - 1] + r.hypCol, del: "HYPOTHESIS".len, ins: "RATIFIED BY " & dec)
  else:
    Edit(off: rl.starts[r.line - 1] + r.idEndCol, del: 0, ins: " STATUS RATIFIED BY " & dec)

proc runRatifyAll(P, file, raw: string, rep: Report, bi: int, dec: string) =
  ## 083:3:1 intestazione e ogni ipotesi, minimo cambiamento, una sola scrittura.
  ## 083:3:2 (F3b, B.2.5) In un'entità l'intestazione non si tocca: solo le garanzie ancora ipotesi.
  let blk = rep.blocks[bi]
  let rl = rawLines(raw)
  var edits: seq[Edit]
  if not blk.isEntity and blk.status != skRat:
    if blk.status == skHyp:
      edits.add Edit(off: rl.starts[blk.statusLine - 1] + blk.statusCol, del: "HYPOTHESIS".len, ins: "RATIFIED BY " & dec)
    else:
      let fl = blk.firstDeclLine
      let indent = leadingWs(raw[rl.starts[fl - 1] ..< rl.ends[fl - 1]])
      let hl = blk.line
      var eol = rl.eol[hl - 1]
      if eol.len == 0:
        edits.add Edit(off: raw.len, del: 0, ins: "\n" & indent & "STATUS RATIFIED BY " & dec & "\n")
      else:
        edits.add Edit(off: rl.ends[hl - 1] + eol.len, del: 0, ins: indent & "STATUS RATIFIED BY " & dec & eol)
  var changedIds: seq[string]
  for r in rep.rows:
    if r.blockIdx != bi: continue
    if r.hypLine > 0:
      edits.add rowEdit(raw, rl, r, dec)
      changedIds.add r.id
    elif (blk.isEntity or r.detailsOf.len > 0) and not r.contract:
      edits.add rowEdit(raw, rl, r, dec)
      changedIds.add r.id
  var changedDet: seq[string]
  if not blk.isEntity:
    # 083:3:3 (1.0-beta, 12.3) anche i dettagli di DEFINE e di storie ancora da approvare
    for r in rep.detRows:
      if r.blockIdx == bi and not r.contract:
        edits.add rowEdit(raw, rl, r, dec)
        changedDet.add r.kw & " " & r.id
  if edits.len == 0:
    die(if blk.isEntity: testo(kRatEntitySenzaIpotesi, P, blk.name) else: testo(kRatCscTuttaContratto, P, blk.name), 1)
  edits.sort(proc(a, b: Edit): int = cmp(b.off, a.off))
  var newText = raw
  for e in edits:
    newText = newText[0 ..< e.off] & e.ins & newText[e.off + e.del .. ^1]
  let nrep = analyzeFull(newText)
  var nbi = -1
  for k, b in nrep.blocks:
    if b.bk == blk.bk and b.name == blk.name: nbi = k
  var good = nrep.errs.len == 0 and nrep.unrecLines == 0 and nbi >= 0
  if good:
    good = blk.isEntity or nrep.blocks[nbi].status == skRat
    for r in nrep.rows:
      if r.blockIdx == nbi and not r.contract and not r.profHyp: good = false
    for r in nrep.detRows:
      if r.blockIdx == nbi and not r.contract: good = false
  if not good:
    die(testo(kErroreInternoIlTestoModificato, P), 1)
  var why = ""
  let wr = safeReplace(file, newText, raw, true, why)
  if wr != wrOk: die(writeErrorMessage(P, file, wr, why), 1)
  var lines: seq[(int, string)]
  if not blk.isEntity and blk.status != skRat: lines.add (nrep.blocks[nbi].statusLine, "CSC " & blk.name)
  var nc = 0
  var restano: seq[string]
  for r in nrep.rows:
    if r.blockIdx != nbi: continue
    if r.contract: inc nc
    elif r.profHyp: restano.add testo(kRiga2, $r.line, r.kw, r.id)
    if r.id in changedIds: lines.add (r.line, r.kw & " " & r.id)
  for r in nrep.detRows:
    if r.blockIdx == nbi and (r.kw & " " & r.id) in changedDet: lines.add (r.line, r.kw & " " & r.id)
  lines.sort(proc(a, b: (int, string)): int = cmp(a[0], b[0]))
  let nl = if lines.len == 1: testo(kNRiga, lines.len) else: testo(kNRighe, lines.len)
  var o = (if blk.isEntity: testo(kRatApprovateEntity, dec, blk.name, nl) else: testo(kRatApprovateCsc, dec, blk.name, nl)) & "\n"
  for (ln, t) in lines: o.add testo(kRiga3, $ln, t)
  o.add testo(kContratto, $nc)
  if restano.len > 0:
    # 083:3:4 (1.0-beta, 7.1 punto 0a) le righe che usano un profilo da approvare restano da approvare
    o.add testo(kIpotesiCheRestano, $restano.len)
    for l in restano: o.add l & "\n"
  stdout.write o
  stdout.flushFile()
  quit(0)

proc runRatifyOther(P, file, raw: string, rep: Report, bi: int, dec: string, hasId, allRows: bool) =
  ## 083:4:1 (1.0-beta, 12.1, 12.4) BINDING e PROFILE si ratificano come una CSC: con l'intestazione o con --all
  let blk = rep.blocks[bi]
  let rl = rawLines(raw)
  if hasId:
    die(P & ": " & (if blk.bk == "BINDING": testo(kRatBindingNonRiga) else: testo(kRatProfileNonRiga)), 1)
  let nm = blk.bk & " " & blk.name & " VERSION " & blk.version & (if blk.ownName.len > 0: " AS " & blk.ownName else: "")
  var edits: seq[Edit]
  var headChanged = false
  if blk.status != skRat:
    headChanged = true
    if blk.status == skHyp:
      edits.add Edit(off: rl.starts[blk.statusLine - 1] + blk.statusCol, del: "HYPOTHESIS".len, ins: "RATIFIED BY " & dec)
    else:
      let fl = blk.firstDeclLine
      let indent = if fl > 0: leadingWs(raw[rl.starts[fl - 1] ..< rl.ends[fl - 1]]) else: "  "
      let hl = blk.line
      let eol = rl.eol[hl - 1]
      if eol.len == 0:
        edits.add Edit(off: raw.len, del: 0, ins: "\n" & indent & "STATUS RATIFIED BY " & dec & "\n")
      else:
        edits.add Edit(off: rl.ends[hl - 1] + eol.len, del: 0, ins: indent & "STATUS RATIFIED BY " & dec & eol)
  var bindLines: seq[int]
  if allRows and blk.bk == "BINDING":
    for br in blk.binds:
      if br.hypLine > 0:
        edits.add Edit(off: rl.starts[br.hypLine - 1] + br.hypCol, del: "HYPOTHESIS".len, ins: "RATIFIED BY " & dec)
        bindLines.add br.line
  if edits.len == 0:
    die(testo(kIlVERSIONEGiaRatificato, P, blk.bk, blk.name, blk.version, blk.decision), 1)
  edits.sort(proc(a, b: Edit): int = cmp(b.off, a.off))
  var newText = raw
  for e in edits:
    newText = newText[0 ..< e.off] & e.ins & newText[e.off + e.del .. ^1]
  let nrep = analyzeFull(newText)
  var nbi = -1
  for k, b in nrep.blocks:
    if b.bk == blk.bk and b.name == blk.name and b.ownName == blk.ownName: nbi = k
  if not (nrep.errs.len == 0 and nrep.unrecLines == 0 and nbi >= 0 and nrep.blocks[nbi].status == skRat):
    die(testo(kErroreInternoIlTestoModificato, P), 1)
  var why = ""
  let wr = safeReplace(file, newText, raw, true, why)
  if wr != wrOk: die(writeErrorMessage(P, file, wr, why), 1)
  let nb = nrep.blocks[nbi]
  var o = ""
  if blk.bk == "PROFILE":
    o.add testo(kRatificatoIlPROFILEVERSIONRiga, blk.name, blk.version, $nb.line, dec)
    o.add testo(kEstensioni, $nb.exts.len)
  else:
    var nc = 0
    var left: seq[string]
    for br in nb.binds:
      if br.status == skRat or (br.status == skNone): inc nc
      else: left.add testo(kRigaBIND, $br.line, (if br.field.len > 0: br.elem & "." & br.field else: br.elem))
    if allRows:
      var lines: seq[(int, string)]
      if headChanged: lines.add (nb.statusLine, nm)
      for br in nb.binds:
        if br.line in bindLines: lines.add (br.line, "BIND " & (if br.field.len > 0: br.elem & "." & br.field else: br.elem))
      lines.sort(proc(a, b: (int, string)): int = cmp(a[0], b[0]))
      o.add testo(kRatApprovateNel, dec, nm, (if lines.len == 1: testo(kNRiga, lines.len) else: testo(kNRighe, lines.len))) & "\n"
      for (l, t) in lines: o.add testo(kRiga3, $l, t)
      o.add testo(kContratto, $nc)
    else:
      o.add testo(kRatificatoIlRigaCon, nm, $nb.line, dec)
      o.add testo(kContratto, $nc)
      o.add testo(kIpotesiCheRestano, $left.len)
      for l in left: o.add l & "\n"
  stdout.write o
  stdout.flushFile()
  quit(0)

proc runRatify*(args: seq[string]) =
  const P = "bcdd ratify"
  # 084:1:1 Argomenti, nell'ordine della sezione 2.2 punto 1
  var pos: seq[string]
  var cscName = ""
  var haveCsc = false
  var allRows = false
  var dirs: seq[string]
  var i = 0
  while i < args.len:
    let a = args[i]
    if a == "--csc":
      if haveCsc or i + 1 >= args.len: die(usoRatify(), 2)
      haveCsc = true
      cscName = args[i + 1]
      i += 2
      continue
    if a == "--dir":
      # 084:1:2 (F3b, B.2.1) l'argomento che segue è sempre la cartella; la stessa stringa due volte è uso sbagliato
      if i + 1 >= args.len or args[i + 1] in dirs: die(usoRatify(), 2)
      dirs.add args[i + 1]
      i += 2
      continue
    if a == "--all":
      if allRows: die(usoRatify(), 2)
      allRows = true
      inc i
      continue
    if a.len > 0 and a[0] == '-': die(usoRatify(), 2)
    pos.add a
    inc i
  if allRows:
    if pos.len != 2: die(usoRatify(), 2)
  elif pos.len != 2 and pos.len != 3: die(usoRatify(), 2)
  let file = pos[0]
  let dec = pos[^1]
  if not validDecision(dec): die(testo(kDecisioneNonValidaServeD, P, dec), 2)
  var rowId = ""
  let wholeCsc = pos.len == 2 and not allRows
  if pos.len == 3:
    rowId = pos[1]
    if not validId(rowId): die(testo(kIdNonValido, P, rowId), 2)
  if haveCsc and not validName(cscName): die(testo(kNomeNonValido, P, cscName), 2)
  # 084:2:1 Lettura, cartelle (F3b, passo 3) e precondizione: il file passa check --strict, con le citazioni cercate anche in --dir
  let raw = loadSource(P, file)
  for d in dirs: checkDirArg(P, d)
  armGiornale("ratify", file)      # 084:2:2 K1, K6: la cartella di FILE; le --dir si leggono e non si scrivono
  searchFile = file
  searchDirs = dirs
  let rep = analyzeFull(raw)
  if rep.errs.len > 0 or rep.unrecLines > 0:
    die(testo(kIlFileNonPassaBcdd, P, $rep.errs.len, $rep.unrecLines), 1)
  # 084:3:1 Scelta del blocco (F3b, B.2.3): la CSC o l'entità
  let bi = chooseBlock(P, rep, haveCsc, cscName, true)
  let blk = rep.blocks[bi]
  if blk.bk in ["BINDING", "PROFILE"]:
    runRatifyOther(P, file, raw, rep, bi, dec, pos.len == 3, allRows)
  # 084:4:1 Il bersaglio. In un'entità (F3b, B.2.4) mai l'intestazione: solo garanzie; poi i confini letti (B.2.6)
  var newText = ""
  var rowOld: RowInfo
  if blk.isEntity:
    let en = "ENTITY " & blk.name
    if wholeCsc:
      die(testo(kLIntestazioneDellaNonSi, P, en), 1)
    if allRows:
      var anyHyp = false
      for r in rep.rows:
        if r.blockIdx == bi and not r.contract: anyHyp = true
      if not anyHyp: die(testo(kLaNonHaGaranzieAncora, P, en), 1)
    else:
      var kind = ""
      for n in blk.names:
        if n.name == rowId: kind = n.kind
      if kind.len == 0: die(testo(kNessunaGUARANTEEConIdNella, P, rowId, en), 1)
      if kind != "ROW": die(testo(kNonEUnaGUARANTEEIn, P, rowId), 1)
      for r in rep.rows:
        if r.blockIdx == bi and r.id == rowId: rowOld = r
      if rowOld.contract:
        die(testo(kEGiaContrattoRigaNon, P, rowId, $rowOld.line), 1)
    checkBorders(P, blk)
  if allRows:
    runRatifyAll(P, file, raw, rep, bi, dec)
  if blk.isEntity:
    newText = composeRowRatify(raw, rowOld, dec)
  elif wholeCsc:
    if blk.status == skRat:
      die(testo(kLaCSCEGiaRatificata, P, blk.name, blk.decision), 1)
    newText = composeBlockRatify(raw, blk, dec)
  else:
    var kind = ""
    for n in blk.names:
      if n.name == rowId: kind = n.kind
    if kind.len == 0:
      die(testo(kNessunaGUARANTEENeASSUMECon, P, rowId, blk.name), 1)
    var isDet = false
    for r in rep.detRows:
      if r.blockIdx == bi and r.id == rowId and kind in ["DEFINE", "SCENARIO"]:
        rowOld = r
        isDet = true
    if kind != "ROW" and not isDet:
      die(testo(kNonEUnaGUARANTEENe, P, rowId), 1)
    for r in rep.rows:
      if r.blockIdx == bi and r.id == rowId: rowOld = r
    if rowOld.contract:
      die(testo(kEGiaContrattoRigaNon, P, rowId, $rowOld.line), 1)
    newText = composeRowRatify(raw, rowOld, dec)
  # 084:5:1 Controllo del testo nuovo (passo 8): una difesa, non dovrebbe mai scattare
  let nrep = analyzeFull(newText)
  var nbi = -1
  for k, b in nrep.blocks:
    if b.bk == blk.bk and b.name == blk.name: nbi = k
  var good = nrep.errs.len == 0 and nrep.unrecLines == 0 and nbi >= 0
  var nrow: RowInfo
  if good:
    if wholeCsc:
      good = nrep.blocks[nbi].status == skRat and nrep.blocks[nbi].decision == dec
    else:
      good = false
      for r in nrep.rows & nrep.detRows:
        if r.blockIdx == nbi and r.id == rowId:
          nrow = r
          good = r.contract
  if not good:
    die(testo(kErroreInternoIlTestoModificato, P), 1)
  # 084:6:1 Scrittura sicura
  var why = ""
  let wr = safeReplace(file, newText, raw, true, why)
  if wr != wrOk: die(writeErrorMessage(P, file, wr, why), 1)
  var o = ""
  if wholeCsc:
    var nc = 0
    var left: seq[string]
    for r in nrep.rows:
      if r.blockIdx != nbi: continue
      if r.contract: inc nc
      else: left.add testo(kRiga2, $r.line, r.kw, r.id)
    o.add testo(kRatificataLaCSCRigaCon, blk.name, $blk.line, dec)
    o.add testo(kContratto, $nc)
    o.add testo(kIpotesiCheRestano, $left.len)
    for l in left: o.add l & "\n"
  else:
    o.add testo(kRatificataLaRigaCon, $nrow.line, nrow.kw, rowId, dec)
  stdout.write o
  stdout.flushFile()
  quit(0)

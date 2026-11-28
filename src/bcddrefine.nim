# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 110:1:1 `bcdd refine`: un giro con l'LLM, domande e proposte, accettate una per una.
# 110:1:2 L'LLM riempie dei campi JSON; la riga BCDD la compone lo strumento, sempre con DETAILS e STATUS HYPOTHESIS
# 110:1:3 (g-r2, g-r6). Nel file entra solo ciò che la persona ha accettato e che passa check (g-r1, g-r3).
# 110:1:4 Dalla 1.4: livelli di DETAILS (sezioni 1, 5.2, 6.5), formato bcdd-refine-3 con le CSC a parte (6.4, 7.2, 8.2)
# 110:1:5 e il segnale di fine (7.4).
# 110:1:6 Dalla 1.5: formato bcdd-refine-4 con le sostituzioni di righe ancora ipotesi (6.1, 6.4, 6.5, 6.6, 6.7, 7.2-7.5).
# 110:1:7 Dalla 1.7: la riga GIRO del dialogo dice ENTITY per un giro su un'entità (AC-149).
import std/[os, strutils, unicode, times, tables, algorithm]
import bcddlex, bcddcheck, bcddnew, bcddsafe, bcddratify, bcddjson, bcddllm, bcddprog, bcddtesti, bcddsys

const
  RequestTemplateIt = staticRead("../modelli/richiesta_refine.txt")
  FollowTemplateIt = staticRead("../modelli/richiesta_refine_seguito.txt")
  EntityTemplateIt = staticRead("../modelli/richiesta_refine_entita.txt")   # 110:2:1 (F3b, B.3.2) modello per un'entità
  RequestTemplateEn = staticRead("../modelli/richiesta_refine.en.txt")      # 110:2:2 i modelli inglesi
  FollowTemplateEn = staticRead("../modelli/richiesta_refine_seguito.en.txt")
  EntityTemplateEn = staticRead("../modelli/richiesta_refine_entita.en.txt")
  LivelliMax = 2          # LIVELLI_MAX, csc/BcddTool.csc 0.4 (g-r7)
  DefaultLimit = 120      # ATTESA_MAX_LLM, csc/BcddTool.csc 0.3
  P = "bcdd refine"

var gGiroLingua*: Lingua = lgEn   ## 110:2:3 la lingua del giro: dei modelli di richiesta e dei testi che vanno all'LLM; di norma quella del comando

proc requestTemplate(): string = (if gGiroLingua == lgIt: RequestTemplateIt else: RequestTemplateEn)
proc followTemplate(): string = (if gGiroLingua == lgIt: FollowTemplateIt else: FollowTemplateEn)
proc entityTemplate(): string = (if gGiroLingua == lgIt: EntityTemplateIt else: EntityTemplateEn)
proc usoRefine(): string = testo(kUsoBcddRefineFILECsc)
proc msgInterrupted(): string = testo(kRefInterrotto)
proc msgEof(): string = testo(kRefIngressoFinito)

type
  Proposal = object
    tipo, id, dettaglia, testo, verifica, verificaTesto: string

  Question = object
    testo: string
    scelte: seq[string]

  CscAParte = object
    nome, motivo: string

  Subst = object
    id, testo, verifica, verificaTesto: string

  Iface = object
    ## una riga d'interfaccia proposta (bcdd-refine-5): la dichiarazione intera e il perché
    riga, motivo: string

  Parsed = object
    domande: seq[Question]
    proposte: seq[Proposal]
    nuoveCsc: seq[CscAParte]
    sostituzioni: seq[Subst]
    interfaccia: seq[Iface]

  Verdict = object
    rejected: bool
    reason: string
    row: RowInfo
    composedFor: bool

# ---------------------------------------------------------------- testo per la persona (7.3)

proc isControlRune(r: int): bool =
  ## 111:1:1 Sezione 6.4: C0 salvo tabulatore e a capo, DEL, C1 e i caratteri di direzione del testo.
  (r < 0x20 and r != 0x09 and r != 0x0A) or r == 0x7F or (r >= 0x80 and r <= 0x9F) or
    (r >= 0x202A and r <= 0x202E) or (r >= 0x2066 and r <= 0x2069)

proc sanitize(s: string): string =
  ## 111:2:1 Per ciò che non è già stato controllato: caratteri di controllo e byte non UTF-8 diventano '?'.
  var i = 0
  while i < s.len:
    let b = ord(s[i])
    if b < 0x80:
      if isControlRune(b): result.add '?' else: result.add s[i]
      inc i
      continue
    let rest = s[i .. min(s.high, i + 3)]
    let bad = firstInvalidUtf8(rest)
    var l = 1
    var r: Rune
    fastRuneAt(s, i, r, false)
    l = runeLenAt(s, i)
    if bad == 0 or i + l > s.len or isControlRune(int(r)):
      result.add '?'
      inc i
    else:
      result.add s[i ..< i + l]
      i += l

proc shorten(s: string, maxRunes: int): string =
  ## 111:3:1 Accorciamento della sezione 7.3: i primi maxRunes caratteri e "…"; l'a capo diventa "↵".
  let t = sanitize(s).replace("\n", "↵")
  if t.runeLen <= maxRunes: return t
  t.runeSubStr(0, maxRunes) & "…"

proc shown(s: string): string = shorten(s, 80)

proc plural(n: int, one, many: Chiave): string =
  ## 101:1:1 «N testo»: singolare per 1, plurale altrimenti, dal catalogo.
  $n & " " & testo(if n == 1: one else: many)

# ---------------------------------------------------------------- uscita e ingresso

var lastCh = '\n'

proc emit(s: string) =
  if s.len == 0: return
  stdout.write s
  stdout.flushFile()
  lastCh = s[^1]

proc emitLn(s: string) = emit(s & "\n")

proc abortRun(msg: string) =
  ## 112:1:1 Sezione 7.6: Ctrl-C o fine dell'ingresso; il terminale torna a capo, nessun file toccato; codice 130.
  if lastCh != '\n': emit("\n")
  die(msg, 130)

var inBuf = ""
var inEof = false
let inIsTty = stdinIsTty()

proc readLine(): string =
  ## 113:1:1 Una riga dallo standard input (CR prima di LF tolto); poll a scatti di 100 ms per accorgersi di Ctrl-C.
  while true:
    let nl = inBuf.find('\n')
    if nl >= 0:
      result = inBuf[0 ..< nl]
      inBuf = inBuf[nl + 1 .. ^1]
      if result.len > 0 and result[^1] == '\r': result.setLen(result.len - 1)
      return
    if inEof:
      if inBuf.len > 0:
        result = inBuf
        inBuf = ""
        if result[^1] == '\r': result.setLen(result.len - 1)
        return
      abortRun(msgEof())
    if interrupted(): abortRun(msgInterrupted())
    case waitStdin(inBuf, 100)
    of sdData, sdTimeout: discard
    of sdEof: inEof = true

proc ask(prompt: string): string =
  ## 113:2:1 Scrive il prompt, legge la riga; se lo standard input non è un terminale scrive l'eco (7.1).
  emit prompt
  result = readLine()
  if not inIsTty: emitLn result

proc trimWs(s: string): string = s.strip(chars = {' ', '\t'})

proc lYes(): string = (if lingua == lgIt: "s" else: "y")   ## 160:1:1 le lettere delle risposte, per lingua
proc lQuit(): string = (if lingua == lgIt: "f" else: "q")

proc askChoice(prompt: string, allowed: openArray[string], warn: string): string =
  while true:
    let a = trimWs(ask(prompt)).toLowerAscii
    if a in allowed: return a
    emitLn warn

# ---------------------------------------------------------------- ambiente (sezione 13)

proc isoNow(): string =
  let o = getEnv("BCDD_ORA")
  if o.len > 0: return o
  now().format("yyyy-MM-dd'T'HH:mm:sszzz")

proc validOra(s: string): bool =
  if s.len != 25: return false
  for i, c in s:
    case i
    of 4, 7: (if c != '-': return false)
    of 10: (if c != 'T': return false)
    of 13, 16, 22: (if c != ':': return false)
    of 19: (if c != '+' and c != '-': return false)
    else: (if c notin {'0' .. '9'}: return false)
  let mo = parseInt(s[5 .. 6])
  let d = parseInt(s[8 .. 9])
  let h = parseInt(s[11 .. 12])
  let mi = parseInt(s[14 .. 15])
  let se = parseInt(s[17 .. 18])
  let th = parseInt(s[20 .. 21])
  let tm = parseInt(s[23 .. 24])
  mo in 1 .. 12 and d in 1 .. 31 and h in 0 .. 23 and mi in 0 .. 59 and se in 0 .. 59 and th in 0 .. 23 and tm in 0 .. 59

# ---------------------------------------------------------------- richiesta (sezione 5)

proc dropLastLf(s: string): string =
  if s.len > 0 and s[^1] == '\n': s[0 ..< s.len - 1] else: s

proc buildRequest(isEntity: bool, fileName, cscName, righe, sostituibili, nomi, confini, dialogo, rapporto,
    testo: string): string =
  ## 114:1:1 Si percorre il modello una volta: ogni segnaposto è sostituito e il testo inserito non si rilegge.
  ## 114:1:2 (F3b) Per un'entità il modello è un altro: {{ENTITA}} al posto di {{CSC}}, in più {{CONFINI}}.
  let t = if isEntity: entityTemplate() else: requestTemplate()
  var i = 0
  while i < t.len:
    if t[i] == '{' and i + 1 < t.len and t[i + 1] == '{':
      let e = t.find("}}", i + 2)
      if e > 0:
        let nm = t[i + 2 ..< e]
        var v = ""
        var known = true
        case nm
        of "FILE": v = fileName
        of "CSC": v = cscName
        of "ENTITA": v = cscName
        of "CONFINI": v = confini
        of "RIGHE": v = righe
        of "SOSTITUIBILI": v = sostituibili
        of "NOMI": v = nomi
        of "DIALOGO": v = dialogo
        of "RAPPORTO": v = rapporto
        of "TESTO": v = testo
        else: known = false
        if known:
          result.add v
          i = e + 2
          continue
    result.add t[i]
    inc i

# ---------------------------------------------------------------- risposta (sezione 6.4)

proc keyPath(base, key: string): string =
  if base.len == 0: key else: base & "." & key

proc strOf(n: JNode): string = n.s

var gEntita = false         ## il giro è su un'entità (formato bcdd-refine-4, senza `interfaccia`) o su una CSC (bcdd-refine-5)

proc checkResponse(raw: string, parsed: var Parsed): string =
  ## 115:1:1 Restituisce "" se la risposta è ben formata, altrimenti il motivo (controlli 3-14 della sezione 6.4).
  var a = 0
  var b = raw.len
  while a < b and raw[a] in {' ', '\t', '\r', '\n'}: inc a
  while b > a and raw[b - 1] in {' ', '\t', '\r', '\n'}: dec b
  let text = raw[a ..< b]
  if firstInvalidUtf8(text) >= 0: return testo(kNonEUTF8Valido)
  let jr = parseStrict(text)
  if not jr.ok or jr.root.kind != jObj: return testo(kNonEUnOggettoJSON)
  if jr.dupPath.len > 0: return testo(kChiaveRipetuta, shown(jr.dupPath))
  let root = jr.root
  # 115:0:1 per le CSC il formato è bcdd-refine-5, con la sesta chiave `interfaccia`; per le entità resta bcdd-refine-4
  let fmt = if gEntita: "bcdd-refine-4" else: "bcdd-refine-5"
  let top = if gEntita: @["formato", "domande", "proposte", "nuove_csc", "sostituzioni"]
            else: @["formato", "domande", "proposte", "nuove_csc", "sostituzioni", "interfaccia"]
  for k in root.keys:
    if k notin top: return testo(kChiaveSconosciuta, shown(k))
  for k in top:
    if k notin root.keys: return testo(kMancaLaChiave, k)
  proc get(n: JNode, k: string): JNode =
    for i, kk in n.keys:
      if kk == k: return n.vals[i]
  let fm = root.get("formato")
  if fm.kind != jStr or fm.s != fmt: return testo(kFormatoDiversoDa, fmt)
  let dm = root.get("domande")
  if dm.kind != jArr: return testo(kTipoSbagliatoPerDomande)
  for i, q in dm.items:
    if q.kind != jObj: return testo(kTipoSbagliatoPerDomande2, $(i + 1))
  if dm.items.len > 5: return testo(kTroppeDomandeAlPiu5, $dm.items.len)
  # 115:1:2 Controlli 10a-10d (dalla 1.3): domanda per domanda, tutti i controlli sulla prima, poi sulla seconda
  for i, q in dm.items:
    let base = "domande[" & $(i + 1) & "]"
    for k in q.keys:
      if k notin ["testo", "scelte"]: return testo(kChiaveSconosciuta, shown(keyPath(base, k)))
    for k in ["testo", "scelte"]:
      if k notin q.keys: return testo(kMancaLaChiave, keyPath(base, k))
    if q.get("testo").kind != jStr: return testo(kTipoSbagliatoPer, keyPath(base, "testo"))
    let sc = q.get("scelte")
    if sc.kind != jArr: return testo(kTipoSbagliatoPer, keyPath(base, "scelte"))
    for j, c in sc.items:
      if c.kind != jStr: return testo(kTipoSbagliatoPerScelte, base, $(j + 1))
    if sc.items.len < 2: return testo(kPocheScelteInAlmeno2, base, $sc.items.len)
    if sc.items.len > 5: return testo(kTroppeScelteInAlPiu, base, $sc.items.len)
    for j, c in sc.items:
      let t = trimWs(c.s)
      if t.len == 0: return testo(kSceltaVuotaScelte, base, $(j + 1))
      if '\n' in t: return testo(kSceltaSuPiuRigheScelte, base, $(j + 1))
    for j, c in sc.items:
      for j0 in 0 ..< j:
        if trimWs(sc.items[j0].s) == trimWs(c.s):
          return testo(kSceltaRipetutaScelte, base, $(j + 1))
  let pr = root.get("proposte")
  if pr.kind != jArr: return testo(kTipoSbagliatoPerProposte)
  for i, q in pr.items:
    if q.kind != jObj: return testo(kTipoSbagliatoPerProposte2, $(i + 1))
  if pr.items.len > 10: return testo(kTroppeProposteAlPiu10, $pr.items.len)
  const pk = ["tipo", "id", "dettaglia", "testo", "verifica", "verifica_testo"]
  for i, q in pr.items:
    let base = "proposte[" & $(i + 1) & "]"
    for k in q.keys:
      if k notin pk: return testo(kChiaveSconosciuta, shown(keyPath(base, k)))
    for k in pk:
      if k notin q.keys: return testo(kMancaLaChiave, keyPath(base, k))
    for k in pk:
      if q.get(k).kind != jStr: return testo(kTipoSbagliatoPer, keyPath(base, k))
  # 115:1:3 Controlli 13a-13f (dalla 1.4): CSC a parte per CSC a parte
  let nc = root.get("nuove_csc")
  if nc.kind != jArr: return testo(kTipoSbagliatoPerNuoveCsc)
  for i, q in nc.items:
    if q.kind != jObj: return testo(kTipoSbagliatoPerNuoveCsc2, $(i + 1))
  if nc.items.len > 3: return testo(kTroppeCSCAParteAl, $nc.items.len)
  for i, q in nc.items:
    let base = "nuove_csc[" & $(i + 1) & "]"
    for k in q.keys:
      if k notin ["nome", "motivo"]: return testo(kChiaveSconosciuta, shown(keyPath(base, k)))
    for k in ["nome", "motivo"]:
      if k notin q.keys: return testo(kMancaLaChiave, keyPath(base, k))
    for k in ["nome", "motivo"]:
      if q.get(k).kind != jStr: return testo(kTipoSbagliatoPer, keyPath(base, k))
    if not validName(q.get("nome").s): return testo(kNomeNonValido2, keyPath(base, "nome"))
    let mo = trimWs(q.get("motivo").s)
    if mo.len == 0: return testo(kMotivoVuoto, keyPath(base, "motivo"))
    if '\n' in mo: return testo(kMotivoSuPiuRighe, keyPath(base, "motivo"))
    if mo.runeLen > 300:
      return testo(kMotivoTroppoLungoInCaratteri, keyPath(base, "motivo"), $mo.runeLen)
    for j in 0 ..< i:
      if nc.items[j].get("nome").s == q.get("nome").s: return testo(kNomeRipetuto, keyPath(base, "nome"))
  # 115:1:4 Controlli 13g-13i (dalla 1.5): sostituzione per sostituzione
  let sb = root.get("sostituzioni")
  if sb.kind != jArr: return testo(kTipoSbagliatoPerSostituzioni)
  for i, q in sb.items:
    if q.kind != jObj: return testo(kTipoSbagliatoPerSostituzioni2, $(i + 1))
  if sb.items.len > 10: return testo(kTroppeSostituzioniAlPiu10, $sb.items.len)
  const sk = ["id", "testo", "verifica", "verifica_testo"]
  for i, q in sb.items:
    let base = "sostituzioni[" & $(i + 1) & "]"
    for k in q.keys:
      if k notin sk: return testo(kChiaveSconosciuta, shown(keyPath(base, k)))
    for k in sk:
      if k notin q.keys: return testo(kMancaLaChiave, keyPath(base, k))
    for k in sk:
      if q.get(k).kind != jStr: return testo(kTipoSbagliatoPer, keyPath(base, k))
  # 115:1:5 righe d'interfaccia, voce per voce (solo per le CSC)
  var ifc: JNode = nil
  if not gEntita:
    ifc = root.get("interfaccia")
    if ifc.kind != jArr: return testo(kTipoSbagliatoPerInterfaccia)
    for i, q in ifc.items:
      if q.kind != jObj: return testo(kTipoSbagliatoPerInterfaccia2, $(i + 1))
    if ifc.items.len > 10: return testo(kTroppeRigheDInterfacciaAl, $ifc.items.len)
    for i, q in ifc.items:
      let base = "interfaccia[" & $(i + 1) & "]"
      for k in q.keys:
        if k notin ["riga", "motivo"]: return testo(kChiaveSconosciuta, shown(keyPath(base, k)))
      for k in ["riga", "motivo"]:
        if k notin q.keys: return testo(kMancaLaChiave, keyPath(base, k))
      for k in ["riga", "motivo"]:
        if q.get(k).kind != jStr: return testo(kTipoSbagliatoPer, keyPath(base, k))
      let mo = trimWs(q.get("motivo").s)
      if mo.len == 0: return testo(kMotivoVuoto, keyPath(base, "motivo"))
      if '\n' in mo: return testo(kMotivoSuPiuRighe, keyPath(base, "motivo"))
      if mo.runeLen > 300:
        return testo(kMotivoTroppoLungoInCaratteri, keyPath(base, "motivo"), $mo.runeLen)
  proc hasCtl(s: string): bool =
    for r in s.runes:
      if isControlRune(int(r)): return true
    false
  for i, q in dm.items:
    let base = "domande[" & $(i + 1) & "]"
    if hasCtl(q.get("testo").s): return testo(kCarattereDiControlloInTesto, base)
    for j, c in q.get("scelte").items:
      if hasCtl(c.s): return testo(kCarattereDiControlloInScelte, base, $(j + 1))
  for i, q in pr.items:
    for k in pk:
      if hasCtl(q.get(k).s): return testo(kCarattereDiControlloIn, keyPath("proposte[" & $(i + 1) & "]", k))
  for i, q in nc.items:
    for k in ["nome", "motivo"]:
      if hasCtl(q.get(k).s): return testo(kCarattereDiControlloIn, keyPath("nuove_csc[" & $(i + 1) & "]", k))
  for i, q in sb.items:
    for k in sk:
      if hasCtl(q.get(k).s): return testo(kCarattereDiControlloIn, keyPath("sostituzioni[" & $(i + 1) & "]", k))
  if ifc != nil:
    for i, q in ifc.items:
      for k in ["riga", "motivo"]:
        if hasCtl(q.get(k).s): return testo(kCarattereDiControlloIn, keyPath("interfaccia[" & $(i + 1) & "]", k))
  for q in dm.items:
    var ch: seq[string]
    for c in q.get("scelte").items: ch.add trimWs(c.s)
    parsed.domande.add Question(testo: q.get("testo").s, scelte: ch)
  for q in pr.items:
    parsed.proposte.add Proposal(tipo: q.get("tipo").s, id: q.get("id").s, dettaglia: q.get("dettaglia").s,
      testo: q.get("testo").s, verifica: q.get("verifica").s, verificaTesto: q.get("verifica_testo").s)
  for q in nc.items:
    parsed.nuoveCsc.add CscAParte(nome: q.get("nome").s, motivo: trimWs(q.get("motivo").s))
  for q in sb.items:
    parsed.sostituzioni.add Subst(id: q.get("id").s, testo: q.get("testo").s, verifica: q.get("verifica").s,
      verificaTesto: q.get("verifica_testo").s)
  if ifc != nil:
    for q in ifc.items:
      parsed.interfaccia.add Iface(riga: q.get("riga").s, motivo: trimWs(q.get("motivo").s))
  ""

# ---------------------------------------------------------------- livelli di DETAILS (sezione 1, dalla 1.4)

proc levelOf(rep: Report, bi: int, id: string): (int, string) =
  ## 116:0:1 Livello di una riga (0 per una riga base; per `X DETAILS Y` il livello di Y più 1) e id della riga base.
  var cur = id
  var lvl = 0
  while lvl <= rep.rows.len:
    var det = ""
    var found = false
    for r in rep.rows:
      if r.blockIdx == bi and r.id == cur:
        det = r.detailsOf
        found = true
        break
    if not found or det.len == 0: return (lvl, cur)
    cur = det
    inc lvl
  (lvl, cur)

# ---------------------------------------------------------------- riga composta (6.6, 6.7)

proc leadingWs(s: string): string =
  var i = 0
  while i < s.len and (s[i] == ' ' or s[i] == '\t'): inc i
  s[0 ..< i]

proc composedPair(p: Proposal): (string, string) =
  ## 116:1:1 Le due righe senza rientro e senza fine riga.
  let head = p.tipo & " " & p.id & (if p.dettaglia.len > 0: " DETAILS " & p.dettaglia else: "") & " STATUS HYPOTHESIS: "
  (head & "VERBAL \"" & p.testo & "\"",
   ' '.repeat(head.runeLen) & "VERIFY BY " & p.verifica & " \"" & p.verificaTesto & "\"")

# ---------------------------------------------------------------- righe d'interfaccia e promesse base

const IfaceKinds = ["CAPABILITY", "EVENT", "STATE", "DEFINE", "TYPE"]

proc refEol(rl: RawLines, i: int): string =
  if i >= 0 and i < rl.eol.len and rl.eol[i].len > 0: rl.eol[i] else: "\n"

proc lineText(raw: string, rl: RawLines, n: int): string = raw[rl.starts[n - 1] ..< rl.ends[n - 1]]

proc insertAfterLine(raw: string, rl: RawLines, n: int, text, eol: string): string =
  ## 116:4:1 Inserisce `text` (con i suoi fine riga) subito dopo la riga n; se la riga n non ha fine riga, glielo dà.
  let off = rl.ends[n - 1] + rl.eol[n - 1].len
  let pre = if rl.eol[n - 1].len == 0: eol else: ""
  raw[0 ..< off] & pre & text & raw[off .. ^1]

proc insertIface(raw: string, rep: Report, bi: int, riga: string): string =
  ## 116:4:2 Sezione 13.1: dopo l'ultima dichiarazione d'interfaccia della CSC; se non ce n'è, dopo PURPOSE con una riga vuota prima.
  let rl = rawLines(raw)
  let blk = rep.blocks[bi]
  let line = trimWs(riga)
  var first, last = 0
  for n in blk.names:
    if n.kind notin IfaceKinds: continue
    let l = rep.spans.getOrDefault(n.line, n.line)
    if l > last:
      last = l
      first = n.line
  if last > 0 and last <= rl.starts.len:
    let eol = refEol(rl, first - 1)
    return insertAfterLine(raw, rl, last, leadingWs(lineText(raw, rl, first)) & line & eol, eol)
  let pl = blk.purposeLine
  if pl > 0 and pl <= rl.starts.len:
    let lastP = min(rep.spans.getOrDefault(pl, pl), rl.starts.len)
    let eol = refEol(rl, pl - 1)
    return insertAfterLine(raw, rl, lastP, eol & leadingWs(lineText(raw, rl, pl)) & line & eol, eol)
  let fl = blk.firstDeclLine
  if fl < 1 or fl > rl.starts.len: return raw
  let eol = refEol(rl, fl - 1)
  raw[0 ..< rl.starts[fl - 1]] & "  " & line & eol & raw[rl.starts[fl - 1] .. ^1]

proc insertBase(raw: string, rep: Report, bi: int, p: Proposal): string =
  ## 116:4:3 Sezione 13.1: una promessa di base va dopo l'ultima GUARANTEE/ASSUME con tutti i suoi dettagli; se non ce n'è,
  ## prima del primo SCENARIO o, senza scenari, prima di END, con una riga vuota prima.
  let rl = rawLines(raw)
  let blk = rep.blocks[bi]
  var first, last = 0
  for r in rep.rows:
    if r.blockIdx == bi and r.lastLine > last:
      last = r.lastLine
      first = r.line
  let (l1, l2) = composedPair(p)
  if last > 0 and last <= rl.starts.len:
    let eol = refEol(rl, first - 1)
    let ind = leadingWs(lineText(raw, rl, first))
    return insertAfterLine(raw, rl, last, ind & l1 & eol & ind & l2 & eol, eol)
  var target = blk.endLine
  for n in blk.names:
    if n.kind == "SCENARIO" and n.line < target: target = n.line
  if target < 2 or target > rl.starts.len: return raw
  var k = target - 1
  while k >= 1 and lineText(raw, rl, k).strip().len == 0: dec k
  if k < 1: return raw
  let eol = refEol(rl, target - 1)
  let ind = if blk.purposeLine > 0 and blk.purposeLine <= rl.starts.len: leadingWs(lineText(raw, rl, blk.purposeLine)) else: "  "
  insertAfterLine(raw, rl, k, eol & ind & l1 & eol & ind & l2 & eol, eol)

proc insertIfaces(raw: string, rep: Report, bi: int, rows: seq[string]): string =
  ## 116:4:4 Una riga alla volta, nell'ordine di accettazione, ognuna nel testo che contiene già le precedenti.
  result = raw
  var r = rep
  for k, l in rows:
    result = insertIface(result, r, bi, l)
    if k < rows.high: r = analyze(result)

proc insertOne(raw: string, rep: Report, bi: int, p: Proposal): string =
  ## 116:2:1 Sezione 6.7 (dalla 1.3): subito dopo l'ultima riga della dichiarazione che, fra la riga dettagliata e tutti
  ## i suoi dettagli (a tutti i livelli), finisce più in basso nel file.
  if p.dettaglia.len == 0: return insertBase(raw, rep, bi, p)
  let rl = rawLines(raw)
  var row: RowInfo
  for r in rep.rows:
    if r.blockIdx == bi and r.id == p.dettaglia:
      row = r
      break
  var family = @[p.dettaglia]
  var lastLine = row.lastLine
  var grown = true
  while grown:
    grown = false
    for r in rep.rows:
      if r.blockIdx == bi and r.detailsOf.len > 0 and r.detailsOf in family and r.id notin family:
        family.add r.id
        if r.lastLine > lastLine: lastLine = r.lastLine
        grown = true
  let indent = leadingWs(raw[rl.starts[row.line - 1] ..< rl.ends[row.line - 1]])
  var eol = rl.eol[row.line - 1]
  if eol.len == 0: eol = "\n"
  let (l1, l2) = composedPair(p)
  let lastEol = rl.eol[lastLine - 1]
  let off = rl.ends[lastLine - 1] + lastEol.len
  let pre = if lastEol.len == 0: eol else: ""
  raw[0 ..< off] & pre & indent & l1 & eol & indent & l2 & eol & raw[off .. ^1]

proc insertProposals(raw: string, rep: Report, bi: int, props: seq[Proposal]): string =
  ## 116:2:2 Una proposta alla volta, nell'ordine di accettazione, ognuna nel testo che contiene già le precedenti.
  result = raw
  var r = rep
  for k, p in props:
    result = insertOne(result, r, bi, p)
    if k < props.high: r = analyze(result)

type Ragione = object
  ## 117:0:2 Perché una proposta, sostituzione o riga d'interfaccia è scartata: l'identificatore
  ## stabile (ASCII, uguale in ogni lingua) e gli argomenti nell'ordine dei segnaposto; `chiave` vuota = passa.
  chiave: string
  args: seq[string]

const RagioneTabella = {
    "testo_vuoto": kRgTestoVuoto,
    "testo_con_virgolette": kRgTestoVirgolette,
    "testo_su_piu_righe": kRgTestoPiuRighe,
    "testo_troppo_lungo": kRgTestoLungo,
    "verifica_non_valida": kRgVerificaNonValida,
    "verifica_testo_vuoto": kRgVerificaTestoVuoto,
    "verifica_testo_con_virgolette": kRgVerificaTestoVirgolette,
    "verifica_testo_su_piu_righe": kRgVerificaTestoPiuRighe,
    "verifica_testo_troppo_lungo": kRgVerificaTestoLungo,
    "id_non_valido": kRgIdNonValido,
    "sostituisce_non_garanzia_entita": kRgSostituisceNonGaranziaEntita,
    "sostituisce_non_garanzia_csc": kRgSostituisceNonGaranziaCsc,
    "sostituisce_contratto": kRgSostituisceContratto,
    "sostituisce_non_verbale": kRgSostituisceNonVerbale,
    "id_gia_sostituito": kRgIdGiaSostituito,
    "riga_composta_non_riconosciuta": kRgRigaCompostaNonRiconosciuta,
    "riga_uguale_a_quella_di_adesso": kRgRigaUguale,
    "check_rifiuta_riga": kRgCheckRifiuta,
    "riga_vuota": kRgRigaVuota,
    "riga_su_piu_righe": kRgRigaPiuRighe,
    "dichiarazione_non_ammessa": kRgDichiarazioneNonAmmessa,
    "riga_non_riconosciuta": kRgRigaNonRiconosciuta,
    "nome_gia_usato_interfaccia": kRgNomeGiaUsatoInterfaccia,
    "tipo_non_dichiarato": kRgTipoNonDichiarato,
    "tipo_assume_in_entita": kRgTipoAssumeInEntita,
    "tipo_non_valido_entita": kRgTipoNonValidoEntita,
    "tipo_non_valido": kRgTipoNonValido,
    "dettaglia_non_garanzia_entita": kRgDettagliaNonGaranziaEntita,
    "dettaglia_non_garanzia_csc": kRgDettagliaNonGaranziaCsc,
    "dettaglia_troppo_in_basso": kRgDettagliaLivello,
    "id_gia_usato_alla_riga": kRgIdGiaUsatoRiga,
    "id_gia_usato_interfaccia": kRgIdGiaUsatoInterfaccia,
    "id_gia_usato_proposta": kRgIdGiaUsatoProposta}

proc ragione(chiave: string, a: varargs[string, `$`]): Ragione = Ragione(chiave: chiave, args: @a)
proc passa(r: Ragione): bool = r.chiave.len == 0

proc ragioneTesto(r: Ragione): string =
  ## 117:0:3 Il testo della ragione nella lingua corrente.
  for (k, v) in RagioneTabella:
    if k == r.chiave: return compone(modello(v, lingua), r.args)
  r.chiave

proc runes(s: string): int = s.runeLen

proc textReason(testo, verifica, verificaTesto: string): Ragione =
  ## 117:0:1 Controlli 6-11 della sezione 6.5 (e S6-S11 delle sostituzioni, stesse ragioni): passa se vanno bene.
  if trimWs(testo).len == 0: return ragione("testo_vuoto")
  if '"' in testo: return ragione("testo_con_virgolette")
  if '\n' in testo: return ragione("testo_su_piu_righe")
  if testo.runes > 1000: return ragione("testo_troppo_lungo", testo.runes)
  if verifica notin ["JUDGEMENT", "INSPECTION"]:
    return ragione("verifica_non_valida", shown(verifica))
  if trimWs(verificaTesto).len == 0: return ragione("verifica_testo_vuoto")
  if '"' in verificaTesto:
    return ragione("verifica_testo_con_virgolette")
  if '\n' in verificaTesto: return ragione("verifica_testo_su_piu_righe")
  if verificaTesto.runes > 300:
    return ragione("verifica_testo_troppo_lungo", verificaTesto.runes)
  Ragione()

# ---------------------------------------------------------------- sostituzioni (6.5 S1-S13, 6.6, 6.7: dalla 1.5)

proc rowOf(rep: Report, bi: int, id: string, row: var RowInfo): bool =
  for r in rep.rows:
    if r.blockIdx == bi and r.id == id:
      row = r
      result = true

proc substPrefix(raw: string, rl: RawLines, row: RowInfo): string =
  ## 116:3:1 Sezione 6.6: la prima riga della dichiarazione dal suo primo byte al primo `:` compreso; "" se non c'è.
  let l = raw[rl.starts[row.line - 1] ..< rl.ends[row.line - 1]]
  let c = l.find(':')
  if c < 0: "" else: l[0 .. c]

proc substLines(raw: string, rl: RawLines, row: RowInfo, s: Subst): (string, string) =
  ## 116:3:2 Le due righe composte di una sostituzione, con il rientro e senza fine riga (sezione 6.6).
  let pre = substPrefix(raw, rl, row)
  let indent = leadingWs(pre)
  (pre & " VERBAL \"" & s.testo & "\"",
   indent & ' '.repeat(pre.runeLen - indent.runeLen + 1) & "VERIFY BY " & s.verifica & " \"" & s.verificaTesto & "\"")

proc applySubst(raw: string, rep: Report, bi: int, s: Subst): string =
  ## 116:3:3 Le due righe prendono il posto di tutte le righe di adesso, dalla prima all'ultima della dichiarazione.
  var row: RowInfo
  discard rowOf(rep, bi, s.id, row)
  let rl = rawLines(raw)
  var eol = rl.eol[row.line - 1]
  if eol.len == 0: eol = "\n"
  let (l1, l2) = substLines(raw, rl, row, s)
  let off = rl.ends[row.lastLine - 1] + rl.eol[row.lastLine - 1].len
  raw[0 ..< rl.starts[row.line - 1]] & l1 & eol & l2 & eol & raw[off .. ^1]

proc applySubsts(raw: string, rep: Report, bi: int, subs: seq[Subst]): string =
  ## 116:3:4 Sezione 6.7: una alla volta, nell'ordine di accettazione, ognuna nel testo che contiene già le precedenti.
  result = raw
  var r = rep
  for k, s in subs:
    result = applySubst(result, r, bi, s)
    if k < subs.high: r = analyze(result)

proc nowLines(raw: string, rl: RawLines, row: RowInfo): seq[string] =
  ## 116:3:5 Le righe di adesso, senza CR e senza fine riga.
  for n in row.line .. row.lastLine: result.add raw[rl.starts[n - 1] ..< rl.ends[n - 1]]

proc detailsOfRow(rep: Report, bi: int, id: string): seq[string] =
  ## 116:3:6 I dettagli di una riga a ogni livello, nell'ordine del file (sezione 1).
  var family = @[id]
  var grown = true
  while grown:
    grown = false
    for r in rep.rows:
      if r.blockIdx == bi and r.detailsOf.len > 0 and r.detailsOf in family and r.id notin family:
        family.add r.id
        grown = true
  for r in rep.rows:
    if r.blockIdx == bi and r.id != id and r.id in family: result.add r.id

proc filterSubst(raw: string, rep: Report, bi: int, s: Subst, taken: Table[string, int]): Ragione =
  ## 117:2:1 Controlli S1-S13 della sezione 6.5: la prima ragione trovata, oppure nessuna se la sostituzione passa.
  let blk = rep.blocks[bi]
  if not validId(s.id): return ragione("id_non_valido", shown(s.id))
  var row: RowInfo
  if not rowOf(rep, bi, s.id, row):
    if blk.isEntity:
      return ragione("sostituisce_non_garanzia_entita", blk.name, shown(s.id))
    return ragione("sostituisce_non_garanzia_csc", blk.name, shown(s.id))
  if row.contract:
    return ragione("sostituisce_contratto", shown(s.id), row.line)
  if row.grade != grVerbal:
    return ragione("sostituisce_non_verbale", shown(s.id), row.line)
  if s.id in taken: return ragione("id_gia_sostituito", taken[s.id], shown(s.id))
  let why = textReason(s.testo, s.verifica, s.verificaTesto)
  if not why.passa: return why
  let rl = rawLines(raw)
  if substPrefix(raw, rl, row).len == 0: return ragione("riga_composta_non_riconosciuta")
  let (l1, l2) = substLines(raw, rl, row, s)
  let now = nowLines(raw, rl, row)
  if now.len == 2 and now[0] == l1 and now[1] == l2: return ragione("riga_uguale_a_quella_di_adesso")
  let nrep = analyzeFull(applySubst(raw, rep, bi, s))
  if nrep.errs.len > 0:
    return ragione("check_rifiuta_riga", nrep.errs[0].code, nrep.errs[0].msg)
  if nrep.unrecLines > rep.unrecLines: return ragione("riga_composta_non_riconosciuta")
  for r in nrep.rows:
    if r.id == s.id and r.grade == grVerbal and not r.contract: return Ragione()
  ragione("riga_composta_non_riconosciuta")

# ---------------------------------------------------------------- filtro delle proposte (6.5)

proc filterIface(raw: string, rep: Report, bi: int, ifc: Iface, takenNames: Table[string, int],
    takenTypes: var seq[string], name: var string): Ragione =
  ## 117:3:1 la prima ragione trovata, oppure nessuna se la riga d'interfaccia passa. `name`: il nome che la riga
  ## dichiara. La riga messa nel posto che avrà non dà errori, è riconosciuta, ha un nome nuovo e usa solo tipi noti.
  let line = trimWs(ifc.riga)
  if line.len == 0: return ragione("riga_vuota")
  if '\n' in line: return ragione("riga_su_piu_righe")
  let lx = lex(line)
  if lx.toks.len == 0 or lx.toks[0].kind != tkWord or lx.toks[0].text notin IfaceKinds:
    let w = if lx.toks.len > 0: lx.toks[0].text else: line
    return ragione("dichiarazione_non_ammessa", shown(w))
  let first = lx.toks[0].text
  let blk = rep.blocks[bi]
  let nt = insertIface(raw, rep, bi, line)
  let nrep = analyzeFull(nt)
  if nrep.errs.len > 0:
    return ragione("check_rifiuta_riga", nrep.errs[0].code, nrep.errs[0].msg)
  if nrep.unrecLines > rep.unrecLines: return ragione("riga_non_riconosciuta")
  var old: seq[string]
  for n in blk.names: old.add n.name
  var rec: NameRec
  var found = false
  for n in nrep.blocks[bi].names:
    if n.name notin old and n.kind in IfaceKinds:
      rec = n
      found = true
      break
  if not found: return ragione("riga_non_riconosciuta")
  if rec.name in takenNames:
    return ragione("nome_gia_usato_interfaccia", takenNames[rec.name], shown(rec.name))
  for t in nrep.undeclOrder:
    if rec.line in nrep.undeclLines[t] and t notin takenTypes:
      return ragione("tipo_non_dichiarato", shown(t))
  name = rec.name
  if first == "TYPE": takenTypes.add rec.name
  Ragione()

proc filterProposal(raw: string, rep: Report, bi: int, p: Proposal, k: int,
    taken: Table[string, int], ifn: Table[string, int]): Ragione =
  ## 117:1:1 La prima ragione trovata, oppure nessuna se la proposta passa. `taken`: id delle proposte precedenti non scartate.
  let blk = rep.blocks[bi]
  if blk.isEntity:
    # 117:1:4 (F3b, B.3.3) in un'entità solo GUARANTEE
    if p.tipo == "ASSUME": return ragione("tipo_assume_in_entita")
    if p.tipo != "GUARANTEE": return ragione("tipo_non_valido_entita", shown(p.tipo))
  elif p.tipo notin ["GUARANTEE", "ASSUME"]:
    return ragione("tipo_non_valido", shown(p.tipo))
  if not validId(p.id): return ragione("id_non_valido", shown(p.id))
  var row: RowInfo
  var found = false
  # 117:1:5 in una CSC `dettaglia` vuoto è una promessa di base nuova (nessun controllo 3 e 3a)
  let baseP = p.dettaglia.len == 0 and not blk.isEntity
  if not baseP:
    for r in rep.rows:
      if r.blockIdx == bi and r.id == p.dettaglia:
        row = r
        found = true
    if not found:
      if blk.isEntity:
        return ragione("dettaglia_non_garanzia_entita", blk.name, shown(p.dettaglia))
      return ragione("dettaglia_non_garanzia_csc", blk.name, shown(p.dettaglia))
    # 117:1:3 Controllo 3a (dalla 1.4, g-r7): la riga dettagliata ha livello 0 o 1, così la nuova arriva al più al livello 2
    let (lvl, baseId) = levelOf(rep, bi, p.dettaglia)
    if lvl >= LivelliMax:
      return ragione("dettaglia_troppo_in_basso", shown(p.dettaglia), lvl, shown(baseId))
  for n in blk.names:
    if n.name == p.id: return ragione("id_gia_usato_alla_riga", n.line, shown(p.id))
  if p.id in ifn: return ragione("id_gia_usato_interfaccia", ifn[p.id], shown(p.id))
  if p.id in taken: return ragione("id_gia_usato_proposta", taken[p.id], shown(p.id))
  let why = textReason(p.testo, p.verifica, p.verificaTesto)
  if not why.passa: return why
  # 117:1:2 Controllo 12: il file con la sola riga composta passa check e la riga è verbale e ipotesi
  let nt = insertProposals(raw, rep, bi, @[p])
  let nrep = analyzeFull(nt)
  if nrep.errs.len > 0:
    return ragione("check_rifiuta_riga", nrep.errs[0].code, nrep.errs[0].msg)
  if nrep.unrecLines > rep.unrecLines: return ragione("riga_composta_non_riconosciuta")
  for r in nrep.rows:
    if r.id == p.id and r.grade == grVerbal and not r.contract: return Ragione()
  ragione("riga_composta_non_riconosciuta")

# ---------------------------------------------------------------- registro delle chiamate (9.5)

proc registryPath(): string =
  let r = getEnv("BCDD_REGISTRO")
  if r.len > 0: return r
  let x = getEnv("XDG_STATE_HOME")
  if x.len > 0: return x / "bcdd" / "chiamate.tsv"
  getHomeDir() / ".local" / "state" / "bcdd" / "chiamate.tsv"

proc writeRegistry(stamp, prov: string, limit, ms: int, esito: string, reqBytes, respBytes: int, fileName: string) =
  let path = registryPath()
  try:
    createDir(parentDir(path))
    let line = [stamp, prov, $limit, $ms, esito, $reqBytes, $respBytes, fileName].join("\t") & "\n"
    let why = appendToFile(path, "data\tfornitore\tlimite_s\tdurata_ms\tesito\tbyte_richiesta\tbyte_risposta\tfile\n", line)
    if why.len > 0: raise newException(OSError, why)
  except OSError as ex:
    stderr.write testo(kRegistroDelleChiamateNonScritto, P, ex.msg)
    stderr.flushFile()

# ---------------------------------------------------------------- il giro

proc provMessage(res: LlmResult): string =
  ## 118:1:1 Seconda riga dei messaggi di sezione 9.4: la prima riga dello standard error del fornitore.
  var first = res.errout
  let nl = first.find('\n')
  if nl >= 0: first = first[0 ..< nl]
  first = first.strip(chars = {'\r'})
  if first.len == 0: return ""
  testo(kMessaggioDellLLM, shorten(first, 200).replace("↵", "?"))

proc fmtAnswers(qa: seq[(string, string)], indent: string): string =
  for (q, a) in qa:
    let ls = q.split('\n')
    result.add indent & "DOMANDA " & ls[0] & "\n"
    for i in 1 ..< ls.len: result.add indent & "  " & ls[i] & "\n"
    result.add indent & "RISPOSTA " & a & "\n"

proc fmtPair(p: Proposal): string =
  let (l1, l2) = composedPair(p)
  "  " & l1 & "\n  " & l2 & "\n"

type SubView = object
  ## 118:2:0 Una sostituzione non scartata, pronta per lo schermo: righe senza il RIENTRO della prima riga di adesso.
  s: Subst
  line: int
  nowL: seq[string]
  new1, new2: string
  details: seq[string]

proc stripIndent(l, indent: string): string =
  if indent.len > 0 and l.startsWith(indent): l[indent.len .. ^1] else: l

proc viewOf(raw: string, rep: Report, bi: int, s: Subst): SubView =
  var row: RowInfo
  discard rowOf(rep, bi, s.id, row)
  let rl = rawLines(raw)
  let indent = leadingWs(substPrefix(raw, rl, row))
  let (l1, l2) = substLines(raw, rl, row, s)
  result = SubView(s: s, line: row.line, new1: stripIndent(l1, indent), new2: stripIndent(l2, indent),
    details: detailsOfRow(rep, bi, s.id))
  for l in nowLines(raw, rl, row): result.nowL.add stripIndent(sanitize(l), indent)

proc unsaved(accepted: seq[Proposal], qa: seq[(string, string)], subs: seq[SubView] = @[], ifaces: seq[string] = @[]) =
  ## 118:2:1 Sezione 7.5: ciò che la persona ha fatto e che non è stato scritto, stampato perché non vada perso.
  if subs.len > 0:
    emitLn testo(kSostituzioniAccettateENonScritte)
    for v in subs:
      emitLn testo(kAlPostoDiRiga, v.s.id, $v.line)
      emitLn "    " & v.new1
      emitLn "    " & v.new2
  if ifaces.len > 0:
    emitLn testo(kRigheDInterfacciaAccettateE)
    for l in ifaces: emitLn "  " & trimWs(l)
  if accepted.len > 0:
    emitLn testo(kProposteAccettateENonScritte)
    for p in accepted: emit fmtPair(p)
  if qa.len > 0:
    emitLn testo(kRisposteNonSalvate)
    emit fmtAnswers(qa, "  ")

proc secondRequest(first: string, qa: seq[(string, string)]): string =
  ## 118:3:1 Sezione 5.3: la prima richiesta identica, poi il modello del seguito con le risposte di questo giro.
  let t = followTemplate()
  let at = t.find("{{RISPOSTE}}")
  first & t[0 ..< at] & dropLastLf(fmtAnswers(qa, "")) & t[at + "{{RISPOSTE}}".len .. ^1]

var gModello = "veloce"     ## il modello della chiamata in corso ("veloce" | "accurato"); entra nel giro e nell'uscita JSON

proc checkModello(v: string, uso: string): string =
  ## 118:3:1 L'elenco è chiuso: qualunque altro valore è un uso sbagliato (codice 2) e non si chiama niente.
  if v notin ["veloce", "accurato"]: die(testo(kModelloNonValidoVeloceOppure, P, shown(v)), 2)
  v

proc registryProv(prov: string): string =
  ## 118:3:2 Nel registro il fornitore `claude` porta il modello (`claude:sonnet`, `claude:opus`); un fornitore di prova resta com'è.
  if prov == "claude": "claude:" & modelId(gModello) else: prov

proc callAndRead(request: string, vec: seq[string], prov: string, limit: int, fileName, file: string,
    second: bool, parsed: var Parsed): (string, int) =
  ## 118:4:1 Una chiamata (sezioni 9.1, 9.4, 9.5): avvio, lettura della risposta, riga nel registro.
  ## Restituisce il messaggio d'errore ("" se la risposta è utilizzabile) e il codice d'uscita da usare.
  let pre = if second: testo(kSecondaChiamata, P) else: P & ": "
  let tail = if second: testo(kNessunaPropostaNonCambia, file) else: testo(kNienteScrittoIlFileE)
  let stamp = isoNow()
  let wd = makeWorkDir()
  var res: LlmResult
  if wd.len == 0:
    res.outcome = loStartFailed
    res.cause = testo(kNonRiescoACreareLa)
  else:
    res = callProvider(vec, request, limit, wd)
  removeWorkDir(wd)
  var motive = ""
  var esito = ""
  var failMsg = ""
  var failCode = 4
  case res.outcome
  of loStartFailed:
    esito = "avvio_fallito"
    failMsg = testo(kNonRiescoAdAvviareL, pre, prov, res.cause, provMessage(res))
  of loNotFound:
    esito = "avvio_fallito"
    failMsg = testo(kClaudeCodeNonTrovato, pre, res.searched)
  of loTimeout:
    esito = "tempo_scaduto"
    failMsg = testo(kLLLMNonHaRisposto, pre, $limit, tail, provMessage(res))
  of loInterrupted:
    esito = "interrotta"
    failMsg = msgInterrupted()
    failCode = 130
  of loTooBig:
    esito = "malformata"
    failMsg = testo(kRispostaDellLLMNonLeggibile, pre, tail)
  of loExitCode:
    esito = "codice_" & $res.exitCode
    failMsg = testo(kLLLMETerminatoSenza, pre, $res.exitCode, tail, provMessage(res))
  of loOk:
    var allWs = true
    for c in res.output:
      if c notin {' ', '\t', '\r', '\n'}:
        allWs = false
        break
    if allWs:
      esito = "vuota"
      failMsg = testo(kLLLMNonHaDato, pre, tail)
    else:
      motive = checkResponse(res.output, parsed)
      if motive.len > 0:
        esito = "malformata"
        failMsg = testo(kRispostaDellLLMNonLeggibile2, pre, motive, tail)
      else:
        esito = "risposta"
  writeRegistry(stamp, registryProv(prov), limit, res.durationMs, esito, request.len, min(res.output.len, MaxResponse), fileName)
  (failMsg, failCode)

proc filterAll(raw: string, rep: Report, bi: int, parsed: Parsed, verdicts, sverdicts, iverdicts: var seq[Ragione]): int =
  ## 118:5:1 Passo 9: il filtro riga d'interfaccia per riga, proposta per proposta e sostituzione per sostituzione;
  ## restituisce quante sono scartate.
  var takenI = initTable[string, int]()
  var takenTypes: seq[string]
  iverdicts = @[]
  for k, ifc in parsed.interfaccia:
    var nm = ""
    let why = filterIface(raw, rep, bi, ifc, takenI, takenTypes, nm)
    iverdicts.add why
    if why.passa: takenI[nm] = k + 1
    else: inc result
  var taken = initTable[string, int]()
  verdicts = @[]
  for k, p in parsed.proposte:
    let why = filterProposal(raw, rep, bi, p, k + 1, taken, takenI)
    verdicts.add why
    if why.passa: taken[p.id] = k + 1
    else: inc result
  var takenS = initTable[string, int]()
  sverdicts = @[]
  for k, sb in parsed.sostituzioni:
    let why = filterSubst(raw, rep, bi, sb, takenS)
    sverdicts.add why
    if why.passa: takenS[sb.id] = k + 1
    else: inc result

proc lettaLine(parsed: Parsed, withQuestions: bool, nDiscarded, ignored: int): string =
  ## 118:5:2 Sezione 7.2, riga 4: dalla 1.5 `, S sostituzioni` solo se la risposta ne ha.
  result = testo(kRispostaLetta)
  if withQuestions: result.add plural(parsed.domande.len, kDomandaSing, kDomandaPlur) & ", "
  result.add plural(parsed.proposte.len, kPropostaSing, kPropostaPlur)
  if parsed.sostituzioni.len > 0: result.add ", " & plural(parsed.sostituzioni.len, kSostituzioneSing, kSostituzionePlur)
  if parsed.interfaccia.len > 0: result.add ", " & plural(parsed.interfaccia.len, kRigaDInterfaccia, kRigheDInterfaccia)
  result.add testo(kScartateDalControllo, $nDiscarded)
  if ignored > 0: result.add testo(kDomandeIgnorate, $ignored)

proc filePart(nS, nP: int, nI: int = 0): string =
  ## 118:5:3 Sezione 7.4 (dalla 1.5): la parte del file nella conferma e nella riga `scritto`.
  var parts: seq[string]
  if nS > 0: parts.add plural(nS, kSostituzioneSing, kSostituzionePlur)
  if nI > 0: parts.add plural(nI, kRigaDInterfaccia, kRigheDInterfaccia)
  if nP > 0 or parts.len == 0:
    parts.add plural(nP, kPropostaSing, kPropostaPlur) & " (" & plural(2 * nP, kRigaSing, kRighePlur) & ")"
  if parts.len == 1: parts[0]
  else: testo(kEParola, parts[0 ..< parts.high].join(", "), parts[^1])

proc dialogBody(dlgExists: bool, dlgText, stamp, cscName: string, qa: seq[(string, string)],
    csc: seq[CscAParte] = @[], isEntity: bool = false): string =
  ## 118:6:1 Sezione 8.2: il contenuto nuovo di FILE.dialogo.
  if not dlgExists:
    result = testo(kBcddRefineDomandeDellLLM)
  else:
    result = dlgText
    if result.len > 0 and result[^1] != '\n': result.add "\n"
  # 118:6:3 Dalla 1.7: la riga del giro dice ENTITY se il giro è su un'entità, CSC altrimenti.
  result.add "\nGIRO " & stamp & (if isEntity: " ENTITY " else: " CSC ") & cscName & "\n"
  result.add fmtAnswers(qa, "")
  for c in csc: result.add "CSC A PARTE " & c.nome & ": " & c.motivo & "\n"

proc dialogPart(nR, nC: int): string =
  ## 118:6:2 Sezione 7.4 (dalla 1.4): la parte del dialogo nelle righe di conferma e di scrittura.
  if nR > 0 and nC > 0: testo(kEParola, plural(nR, kRispostaSing, kRispostaPlur), plural(nC, kCscAParteTesto, kCscAParteTesto))
  elif nC > 0: plural(nC, kCscAParteTesto, kCscAParteTesto)
  else: plural(nR, kRispostaSing, kRispostaPlur)

type Ctx = object
  ## 118:7:0 Il giro letto dal file: i passi 2-6 di runRefine, comuni al giro del terminale e a quello in tempi.
  raw: string
  rep: Report
  bi: int
  fileName, dlgPath, dlgShown, dlgText: string
  dlgExists: bool
  request: string

proc prepare(file: string, haveCsc: bool, cscName: string): Ctx =
  # 119:2:1 Passi 2-4: lettura, controllo, scelta della CSC
  let raw = loadSource(P, file)
  searchFile = file
  searchDirs = @[]
  let rep = analyzeFull(raw)
  if rep.errs.len > 0:
    die(testo(kIlFileNonPassaBcdd2, P, $rep.errs.len), 1)
  let bi = chooseBlock(P, rep, haveCsc, cscName)         # 119:2:2 (F3b, B.2.3) la CSC o l'entità
  let blk = rep.blocks[bi]
  gEntita = blk.isEntity
  # 119:3:1 Passo 5: il dialogo dei giri precedenti. Sullo standard error i file si nominano come li ha scritti
  # la persona (dlgPath), sullo standard output senza cartelle (dlgShown): sezione 7.1.
  let fileName = extractFilename(file)
  let dlgPath = file & ".dialogo"
  let dlgShown = fileName & ".dialogo"
  var dlgText = ""
  var dlgExists = false
  block:
    let st = pathInfo(dlgPath)
    if st.ok:
      dlgExists = true
      if not st.isFile: die(testo(kFileNonLeggibile, P, dlgPath), 2)
      try:
        dlgText = readFile(dlgPath)
      except IOError, OSError:
        die(testo(kFileNonLeggibile, P, dlgPath), 2)
      if firstInvalidUtf8(dlgText) >= 0: die(testo(kNonEUTF8Valido2, P, dlgPath), 2)
    elif not st.noent:
      die(testo(kFileNonLeggibile, P, dlgPath), 2)
  # 119:4:1 Passo 6: la richiesta, nella lingua del giro: quella del comando può essere un'altra, e il rapporto
  # inserito nella richiesta si rifà allora nella lingua del giro; i messaggi di bcdd restano nella lingua del comando.
  let savedLg = lingua
  var rrep = rep
  if gGiroLingua != lingua:
    lingua = gGiroLingua
    rrep = analyzeFull(raw)
  let rblk = rrep.blocks[bi]
  var righe = ""
  for r in rrep.rows:
    if r.blockIdx != bi: continue
    if levelOf(rrep, bi, r.id)[0] >= LivelliMax: continue      # 119:4:2 sezione 5.2: solo i livelli 0 e 1
    righe.add testo(kRigheRichiesta, r.id, r.kw, r.line, (if r.contract: testo(kContrattoParola) else: testo(kIpotesiParola)),
      gradeText(r.grade)) & "\n"
  righe = if righe.len == 0: testo(kNessuna) else: dropLastLf(righe)
  var sost = ""
  for r in rrep.rows:
    if r.blockIdx != bi or r.contract or r.grade != grVerbal: continue      # 119:4:3 sezione 5.2: righe sostituibili, ogni livello
    sost.add testo(kAllaRiga, r.id, r.kw, $r.line)
  sost = if sost.len == 0: testo(kNessuna) else: dropLastLf(sost)
  var nomi: seq[string]
  for n in rblk.names: nomi.add n.name
  var confini = ""
  if rblk.isEntity:
    # 119:4:4 (F3b, B.3.2) {{CONFINI}}: una voce per OFFERS e USES, nell'ordine di riga, senza E01
    var seenTxt: seq[(string, int)]
    for k, c in rblk.cites:
      if c.dup or c.kind == ckPart: continue
      let f = if k < rblk.found.len: rblk.found[k] else: Found()
      let head = testo(kRiga4, $c.line, citeText(c))
      if not f.ok:
        confini.add testo(kNonTrovata2, head, (if f.reason.len > 0: " (" & f.reason & ")" else: ""))
      elif f.where.len == 0:
        confini.add testo(kInQuestoFileAllaRiga, head, $f.line, f.version)
      else:
        let line1 = testo(kInAllaRigaVERSION, head, f.where, $f.line, f.version)
        if (f.where, f.line) in seenTxt:
          confini.add testo(kTestoQuiSopra, line1)
        else:
          seenTxt.add (f.where, f.line)
          confini.add line1 & "\n" & testo(kInizioFile, f.where) & "\n" & f.blockText & "\n" & testo(kFineFile, f.where) & "\n"
    confini = if confini.len == 0: testo(kNessuno) else: dropLastLf(confini)
  let request = buildRequest(rblk.isEntity, fileName, rblk.name, righe, sost, (if nomi.len == 0: testo(kNessuno) else: nomi.join(", ")),
    confini, (if dlgExists: dropLastLf(dlgText) else: testo(kNessuna)), dropLastLf(render(rrep, fileName, false)),
    dropLastLf(normalizeSource(raw)))
  lingua = savedLg
  result = Ctx(raw: raw, rep: rep, bi: bi, fileName: fileName, dlgPath: dlgPath, dlgShown: dlgShown,
    dlgText: dlgText, dlgExists: dlgExists, request: request)

proc scopoDaCompilare(cx: Ctx): bool =
  ## 118:7:3 lo PURPOSE di una CSC è ancora quello di `bcdd new` (comincia con `da compilare` o con `to be filled in`: il riconoscitore è uno solo, in bcddcheck).
  let blk = cx.rep.blocks[cx.bi]
  if blk.isEntity or blk.purposeLine < 1: return false
  let rl = rawLines(cx.raw)
  if blk.purposeLine > rl.starts.len: return false
  let l = lineText(cx.raw, rl, blk.purposeLine)
  purposeDaCompilare(l)

proc scopoMsg(cx: Ctx): string =
  testo(kScriviPrimaLoScopoDi, P, cx.rep.blocks[cx.bi].name)

proc envLimit(): (int, string) =
  ## 118:7:1 ATTESA_MAX_LLM e BCDD_ORA (passo 1 di runRefine): il limite in secondi e da dove viene.
  var limit = DefaultLimit
  var limitSrc = "ATTESA_MAX_LLM"
  if existsEnv("BCDD_ATTESA_LLM"):
    let v = getEnv("BCDD_ATTESA_LLM")
    var okv = v.len in 1 .. 4 and v.allCharsInSet({'0' .. '9'})
    if okv:
      let n = parseInt(v)
      if n < 1 or n > 3600: okv = false
      else: limit = n
    if not okv:
      die(testo(kBCDDATTESALLMNonValida, P, v), 2)
    limitSrc = testo(kDaBcddAttesa)
  if existsEnv("BCDD_ORA") and not validOra(getEnv("BCDD_ORA")):
    die(testo(kBCDDORANonValidaServe, P, getEnv("BCDD_ORA")), 2)
  (limit, limitSrc)

proc composeFile(raw: string, rep: Report, bi: int, accepted: seq[Proposal], subs: seq[Subst], ifaces: seq[string] = @[]): string =
  ## 118:7:2 Sezione 6.7: prima le sostituzioni, poi le proposte nel testo che le contiene; "" se il testo nuovo non passa check
  ## o se una riga che era contratto non c'è più identica (difesa della 1.5).
  var nt = raw
  if subs.len > 0: nt = applySubsts(raw, rep, bi, subs)
  if ifaces.len > 0: nt = insertIfaces(nt, analyze(nt), bi, ifaces)
  if accepted.len > 0: nt = insertProposals(nt, analyze(nt), bi, accepted)
  let nrep = analyzeFull(nt)
  if nrep.errs.len != 0 or nrep.unrecLines != rep.unrecLines: return ""
  let rl0 = rawLines(raw)
  let rl1 = rawLines(nt)
  for r in rep.rows:
    if not r.contract: continue
    var r1: RowInfo
    if not rowOf(nrep, r.blockIdx, r.id, r1) or r1.lastLine - r1.line != r.lastLine - r.line: return ""
    for d in 0 .. r.lastLine - r.line:
      if raw[rl0.starts[r.line - 1 + d] ..< rl0.ends[r.line - 1 + d]] != nt[rl1.starts[r1.line - 1 + d] ..< rl1.ends[r1.line - 1 + d]]:
        return ""
  nt

# ---------------------------------------------------------------- il giro in tempi

const
  FormaGiro = "bcdd-giro"
  VersioneGiro = 1

proc usoGiro(): string = testo(kUsoBcddRefineJsonFILE)

type Giro = object
  ## 120:0:1 Il giro fra un tempo e l'altro (FILE.giro, p-8). fase: "domande" (tempo 1 fatto, risposte da dare),
  ## "proposte" (proposte pronte da accettare), "risposte_fallite" (la seconda chiamata non è andata: si possono
  ## solo salvare le risposte o chiudere).
  fase, stamp, cscArg, improntaCsc, improntaDlg: string
  modello: string             ## "veloce" | "accurato"; un giro scritto prima di questo campo vale "accurato"
  lingua: Lingua              ## la lingua del giro, del tempo 1; un giro senza il campo vale `it`
  haveCsc: bool
  chiamate, ignorate: int     ## ignorate: le domande che la seconda chiamata ha rifatto ("domande_ignorate" del tempo 2), per --show
  parsed: Parsed
  qa: seq[(string, string)]

proc jarr(items: seq[string]): string = "[" & items.join(", ") & "]"

proc jstrOrNull(s: string): string = (if s.len == 0: "null" else: jstr(s))

proc jstrs(items: seq[string]): string =
  var xs: seq[string]
  for s in items: xs.add jstr(s)
  jarr(xs)

proc emitJson(s: string) =
  stdout.write s & "\n"
  stdout.flushFile()

proc head(fileName: string, tempo: int): string =
  "{\"forma\": " & jstr(FormaGiro) & ", \"versione\": " & $VersioneGiro & ", \"file\": " & jstr(fileName) &
    ", \"tempo\": " & $tempo & ", \"modello\": " & jstr(gModello)

proc dlgImpronta(dlgPath: string): string =
  ## 120:1:1 L'impronta del dialogo come adesso sta sul disco, "assente" se non c'è.
  if not pathInfo(dlgPath).ok: return "assente"
  try: fingerprint(readFile(dlgPath)) except IOError, OSError: "illeggibile"

proc questionsJson(parsed: Parsed): string =
  var xs: seq[string]
  for i, q in parsed.domande:
    xs.add "{\"n\": " & $(i + 1) & ", \"testo\": " & jstr(q.testo) & ", \"scelte\": " & jstrs(q.scelte) & "}"
  jarr(xs)

proc cscJson(parsed: Parsed): string =
  var xs: seq[string]
  for c in parsed.nuoveCsc: xs.add "{\"nome\": " & jstr(c.nome) & ", \"motivo\": " & jstr(c.motivo) & "}"
  jarr(xs)

proc giroText(g: Giro, fileName: string): string =
  var dom, ris, pro, sos, ifc: seq[string]
  for i in g.parsed.interfaccia: ifc.add "{\"riga\": " & jstr(i.riga) & ", \"motivo\": " & jstr(i.motivo) & "}"
  for q in g.parsed.domande: dom.add "{\"testo\": " & jstr(q.testo) & ", \"scelte\": " & jstrs(q.scelte) & "}"
  for (q, a) in g.qa: ris.add "{\"domanda\": " & jstr(q) & ", \"risposta\": " & jstr(a) & "}"
  for p in g.parsed.proposte:
    pro.add "{\"tipo\": " & jstr(p.tipo) & ", \"id\": " & jstr(p.id) & ", \"dettaglia\": " & jstr(p.dettaglia) &
      ", \"testo\": " & jstr(p.testo) & ", \"verifica\": " & jstr(p.verifica) & ", \"verifica_testo\": " & jstr(p.verificaTesto) & "}"
  for s in g.parsed.sostituzioni:
    sos.add "{\"id\": " & jstr(s.id) & ", \"testo\": " & jstr(s.testo) & ", \"verifica\": " & jstr(s.verifica) &
      ", \"verifica_testo\": " & jstr(s.verificaTesto) & "}"
  "{\"forma\": \"bcdd-giro-stato\", \"versione\": 1, \"file\": " & jstr(fileName) & ", \"fase\": " & jstr(g.fase) &
    ", \"modello\": " & jstr(g.modello) & ", \"lingua\": " & jstr($g.lingua) & ", \"chiamate\": " & $g.chiamate & ", \"domande_ignorate\": " & $g.ignorate & ", \"data\": " & jstr(g.stamp) & ", \"csc_scelta\": " & (if g.haveCsc: jstr(g.cscArg) else: "null") &
    ", \"impronta_csc\": " & jstr(g.improntaCsc) & ", \"impronta_dialogo\": " & jstr(g.improntaDlg) &
    ", \"domande\": " & jarr(dom) & ", \"risposte\": " & jarr(ris) & ", \"proposte\": " & jarr(pro) &
    ", \"sostituzioni\": " & jarr(sos) & ", \"csc_a_parte\": " & cscJson(g.parsed) & ", \"interfaccia\": " & jarr(ifc) & "}\n"

proc jget(n: JNode, k: string): JNode =
  if n == nil or n.kind != jObj: return nil
  for i, kk in n.keys:
    if kk == k: return n.vals[i]

proc readGiro(path, fileName: string): Giro =
  ## 120:2:1 Legge FILE.giro; un file che non c'è o non è quello scritto da bcdd è un uso sbagliato (codice 2).
  if not pathInfo(path).ok: die(testo(kNessunGiroApertoSuManca, P, fileName, fileName), 2)
  var text = ""
  try: text = readFile(path)
  except IOError, OSError: die(testo(kFileNonLeggibile, P, path), 2)
  let bad = testo(kGiroNonEUnGiro, P, fileName)
  let jr = parseStrict(text)
  if not jr.ok or jr.root.kind != jObj or jr.dupPath.len > 0: die(bad, 2)
  let r = jr.root
  proc str(k: string): string =
    let v = jget(r, k)
    if v == nil or v.kind != jStr: die(bad, 2)
    v.s
  proc arr(n: JNode, k: string): seq[JNode] =
    let v = jget(n, k)
    if v == nil or v.kind != jArr: die(bad, 2)
    v.items
  if str("forma") != "bcdd-giro-stato": die(bad, 2)
  result.fase = str("fase")
  if result.fase notin ["domande", "proposte", "risposte_fallite"]: die(bad, 2)
  result.stamp = str("data")
  let mo = jget(r, "modello")                     # assente nei giri scritti prima di questo campo: accurato (era Opus)
  if mo == nil: result.modello = "accurato"
  elif mo.kind != jStr or mo.s notin ["veloce", "accurato"]: die(bad, 2)
  else: result.modello = mo.s
  gModello = result.modello
  let lgj = jget(r, "lingua")                     # assente nei giri scritti prima delle lingue: italiano
  if lgj == nil: result.lingua = lgIt
  elif lgj.kind != jStr or lgj.s notin ["it", "en"]: die(bad, 2)
  else: result.lingua = (if lgj.s == "it": lgIt else: lgEn)
  gGiroLingua = result.lingua
  result.improntaCsc = str("impronta_csc")
  result.improntaDlg = str("impronta_dialogo")
  let cs = jget(r, "csc_scelta")
  if cs == nil: die(bad, 2)
  if cs.kind == jStr:
    result.haveCsc = true
    result.cscArg = cs.s
  let ch = jget(r, "chiamate")
  if ch == nil or ch.kind != jNum: die(bad, 2)
  result.chiamate = parseInt(ch.s)
  let ig = jget(r, "domande_ignorate")             # assente nei giri scritti prima di --show: 0
  if ig != nil and ig.kind == jNum and ig.s.allCharsInSet({'0' .. '9'}) and ig.s.len <= 4: result.ignorate = parseInt(ig.s)
  for q in arr(r, "domande"):
    var qq = Question(testo: (if jget(q, "testo") != nil: jget(q, "testo").s else: ""))
    for c in arr(q, "scelte"): qq.scelte.add c.s
    result.parsed.domande.add qq
  for a in arr(r, "risposte"):
    let d = jget(a, "domanda")
    let x = jget(a, "risposta")
    if d == nil or x == nil: die(bad, 2)
    result.qa.add (d.s, x.s)
  proc fld(n: JNode, k: string): string =
    let v = jget(n, k)
    if v == nil or v.kind != jStr: die(bad, 2)
    v.s
  for p in arr(r, "proposte"):
    result.parsed.proposte.add Proposal(tipo: fld(p, "tipo"), id: fld(p, "id"), dettaglia: fld(p, "dettaglia"),
      testo: fld(p, "testo"), verifica: fld(p, "verifica"), verificaTesto: fld(p, "verifica_testo"))
  let ifj = jget(r, "interfaccia")                 # assente nei giri scritti prima di questo campo: nessuna riga
  if ifj != nil:
    if ifj.kind != jArr: die(bad, 2)
    for q in ifj.items:
      let ri = jget(q, "riga")
      let mo = jget(q, "motivo")
      if ri == nil or mo == nil or ri.kind != jStr or mo.kind != jStr: die(bad, 2)
      result.parsed.interfaccia.add Iface(riga: ri.s, motivo: mo.s)
  for s in arr(r, "sostituzioni"):
    result.parsed.sostituzioni.add Subst(id: fld(s, "id"), testo: fld(s, "testo"), verifica: fld(s, "verifica"),
      verificaTesto: fld(s, "verifica_testo"))
  for c in arr(r, "csc_a_parte"):
    result.parsed.nuoveCsc.add CscAParte(nome: fld(c, "nome"), motivo: fld(c, "motivo"))

proc writeGiro(path: string, g: Giro, fileName: string, old: string, oldExists: bool) =
  var why = ""
  let wr = safeReplace(path, giroText(g, fileName), old, oldExists, why)
  if wr != wrOk: die(writeErrorMessage(P, path, wr, why), 1)

proc readGiroRaw(path: string): string =
  try: readFile(path) except IOError, OSError: ""

proc readStdinJson(what: string): JNode =
  ## 120:3:1 Il JSON dello standard input; non valido: uso sbagliato (codice 2).
  var text = ""
  try: text = stdin.readAll()
  except IOError: die(testo(kNonRiescoALeggereLo, P), 2)
  if firstInvalidUtf8(text) >= 0: die(testo(kLoStandardInputNonE, P), 2)
  let jr = parseStrict(text)
  if not jr.ok or jr.root.kind != jObj: die(testo(kLoStandardInputNonE2, P, what), 2)
  if jr.dupPath.len > 0: die(testo(kChiaveRipetutaNelloStandardInput, P, shown(jr.dupPath)), 2)
  jr.root

proc answersFrom(root: JNode, parsed: Parsed): seq[(string, string)] =
  ## 120:3:2 {"risposte": [{"n": 1, "testo": "..."} | {"n": 1, "scelta": 2}]}: il programma dice se è scelta o testo.
  for k in root.keys:
    if k != "risposte": die(testo(kChiaveSconosciuta2, P, shown(k)), 2)
  let rs = jget(root, "risposte")
  if rs == nil or rs.kind != jArr: die(testo(kMancaRisposteUnaLista, P), 2)
  var byN = newSeq[string](parsed.domande.len)
  for e in rs.items:
    if e.kind != jObj: die(testo(kUnaRispostaNonEUn, P), 2)
    for k in e.keys:
      if k notin ["n", "testo", "scelta"]: die(testo(kChiaveSconosciutaInUnaRisposta, P, shown(k)), 2)
    let nn = jget(e, "n")
    if nn == nil or nn.kind != jNum or not nn.s.allCharsInSet({'0' .. '9'}) or nn.s.len > 4:
      die(testo(kUnaRispostaSenzaNIntero, P), 2)
    let n = parseInt(nn.s)
    if n < 1 or n > parsed.domande.len: die(testo(kNessunaDomanda, P, nn.s), 2)
    if byN[n - 1].len > 0 or byN[n - 1] == "\0": die(testo(kDueRisposteAllaDomanda, P, nn.s), 2)
    let t = jget(e, "testo")
    let sc = jget(e, "scelta")
    if (t == nil) == (sc == nil): die(testo(kLaRispostaVuoleTestoOppure, P, nn.s), 2)
    if sc != nil:
      if sc.kind != jNum or not sc.s.allCharsInSet({'0' .. '9'}) or sc.s.len > 4: die(testo(kSceltaNonEUnIntero, P), 2)
      let c = parseInt(sc.s)
      let q = parsed.domande[n - 1]
      if c < 1 or c > q.scelte.len: die(testo(kLaDomandaNonHaLa, P, nn.s, sc.s), 2)
      byN[n - 1] = q.scelte[c - 1]
    else:
      if t.kind != jStr: die(testo(kTestoNonEUnaStringa, P), 2)
      let a = sanitize(trimWs(t.s))
      byN[n - 1] = (if a.len == 0: "\0" else: a)      # vuota: domanda saltata, ma non si può rispondere due volte
  for i, q in parsed.domande:
    if byN[i].len > 0 and byN[i] != "\0": result.add (q.testo, byN[i])

proc acceptedFrom(root: JNode, g: Giro): (seq[int], seq[int], seq[int]) =
  ## 120:3:3 {"accettate": ["p1", "s1", "i1"]}: gli indici (da 0) di proposte, sostituzioni e righe d'interfaccia.
  ## Le righe d'interfaccia restano nell'ordine in cui la persona le ha accettate (sezione 13.1); gli altri sono ordinati.
  for k in root.keys:
    if k != "accettate": die(testo(kChiaveSconosciuta2, P, shown(k)), 2)
  let a = jget(root, "accettate")
  if a == nil or a.kind != jArr: die(testo(kMancaAccettateUnaLista, P), 2)
  var seen: seq[string]
  for e in a.items:
    if e.kind != jStr: die(testo(kUnElementoDiAccettateNon, P), 2)
    if e.s in seen: die(testo(kENominataDueVolte, P, shown(e.s)), 2)
    seen.add e.s
    let ok = e.s.len >= 2 and e.s[1 .. ^1].allCharsInSet({'0' .. '9'}) and e.s[1 .. ^1].len <= 4 and e.s[1] != '0'
    let n = if ok: parseInt(e.s[1 .. ^1]) else: 0
    if ok and e.s[0] == 'p' and n <= g.parsed.proposte.len: result[0].add n - 1
    elif ok and e.s[0] == 's' and n <= g.parsed.sostituzioni.len: result[1].add n - 1
    elif ok and e.s[0] == 'i' and n <= g.parsed.interfaccia.len: result[2].add n - 1
    else: die(testo(kNessunaPropostaSostituzioneORiga, P, shown(e.s)), 2)
  result[0].sort()
  result[1].sort()
  result[2].sort()

proc proposalsJson(cx: Ctx, parsed: Parsed, verdicts, sverdicts: seq[Ragione]): (string, string) =
  ## 120:4:1 Le proposte e le sostituzioni per il programma: una scartata dal controllo arriva con la sua ragione e non si accetta (g-r3).
  let rep = cx.rep
  var ps, ss: seq[string]
  for k, p in parsed.proposte:
    var rowLine = "null"
    for r in rep.rows:
      if r.blockIdx == cx.bi and r.id == p.dettaglia: rowLine = $r.line
    let n = "\"p" & $(k + 1) & "\""
    if verdicts[k].passa:
      let (l1, l2) = composedPair(p)
      ps.add "{\"n\": " & n & ", \"valida\": true, \"ragione\": null, \"ragione_chiave\": null, \"ragione_argomenti\": [], \"tipo\": " & jstr(p.tipo) & ", \"id\": " & jstr(p.id) &
        ", \"dettaglia\": " & jstr(p.dettaglia) & ", \"riga_dettagliata\": " & rowLine & ", \"righe\": " & jstrs(@[l1, l2]) & "}"
    else:
      ps.add "{\"n\": " & n & ", \"valida\": false, \"ragione\": " & jstr(ragioneTesto(verdicts[k])) & ", \"ragione_chiave\": " & jstr(verdicts[k].chiave) & ", \"ragione_argomenti\": " & jstrs(verdicts[k].args) & ", \"tipo\": " & jstr(shown(p.tipo)) &
        ", \"id\": " & jstr(shown(p.id)) & ", \"dettaglia\": " & jstr(shown(p.dettaglia)) & ", \"riga_dettagliata\": " & rowLine &
        ", \"righe\": [], \"testo\": " & jstr(shown(p.testo)) & ", \"verifica\": " & jstr(shown(p.verifica)) &
        ", \"verifica_testo\": " & jstr(shown(p.verificaTesto)) & "}"
  for k, sb in parsed.sostituzioni:
    let n = "\"s" & $(k + 1) & "\""
    if sverdicts[k].passa:
      let v = viewOf(cx.raw, rep, cx.bi, sb)
      ss.add "{\"n\": " & n & ", \"valida\": true, \"ragione\": null, \"ragione_chiave\": null, \"ragione_argomenti\": [], \"id\": " & jstr(sb.id) & ", \"riga\": " & $v.line &
        ", \"adesso\": " & jstrs(v.nowL) & ", \"diventa\": " & jstrs(@[v.new1, v.new2]) & ", \"dettagli\": " & jstrs(v.details) & "}"
    else:
      ss.add "{\"n\": " & n & ", \"valida\": false, \"ragione\": " & jstr(ragioneTesto(sverdicts[k])) & ", \"ragione_chiave\": " & jstr(sverdicts[k].chiave) & ", \"ragione_argomenti\": " & jstrs(sverdicts[k].args) & ", \"id\": " & jstr(shown(sb.id)) &
        ", \"riga\": null, \"adesso\": [], \"diventa\": [], \"dettagli\": [], \"testo\": " & jstr(shown(sb.testo)) &
        ", \"verifica\": " & jstr(shown(sb.verifica)) & ", \"verifica_testo\": " & jstr(shown(sb.verificaTesto)) & "}"
  (jarr(ps), jarr(ss))

proc ifaceJson(parsed: Parsed, iverdicts: seq[Ragione]): string =
  ## 120:4:2 le righe d'interfaccia per il programma, con la stessa forma delle proposte; una scartata arriva con la ragione.
  var xs: seq[string]
  for k, i in parsed.interfaccia:
    let n = "\"i" & $(k + 1) & "\""
    if iverdicts[k].passa:
      xs.add "{\"n\": " & n & ", \"valida\": true, \"ragione\": null, \"ragione_chiave\": null, \"ragione_argomenti\": [], \"riga\": " & jstr(trimWs(i.riga)) & ", \"motivo\": " & jstr(i.motivo) & "}"
    else:
      xs.add "{\"n\": " & n & ", \"valida\": false, \"ragione\": " & jstr(ragioneTesto(iverdicts[k])) & ", \"ragione_chiave\": " & jstr(iverdicts[k].chiave) & ", \"ragione_argomenti\": " & jstrs(iverdicts[k].args) & ", \"riga\": " & jstr(shown(i.riga)) &
        ", \"motivo\": " & jstr(shown(i.motivo)) & "}"
  jarr(xs)

proc copyJson(fileName: string, tempo: int, errore: string, qa: seq[(string, string)], parsed: Parsed,
    pIdx, sIdx: seq[int], iIdx: seq[int] = @[]): string =
  ## 120:5:1 p-10: ciò che la persona ha fatto e non è stato scritto, da copiare (come `unsaved` del terminale).
  var ris, pa, sa, ia: seq[string]
  for i in iIdx: ia.add "{\"n\": \"i" & $(i + 1) & "\", \"riga\": " & jstr(trimWs(parsed.interfaccia[i].riga)) & "}"
  for (q, a) in qa: ris.add "{\"domanda\": " & jstr(q) & ", \"risposta\": " & jstr(a) & "}"
  for i in pIdx:
    let (l1, l2) = composedPair(parsed.proposte[i])
    pa.add "{\"n\": \"p" & $(i + 1) & "\", \"righe\": " & jstrs(@[l1, l2]) & "}"
  for i in sIdx:
    let s = parsed.sostituzioni[i]
    sa.add "{\"n\": \"s" & $(i + 1) & "\", \"id\": " & jstr(s.id) & ", \"testo\": " & jstr(s.testo) & ", \"verifica\": " &
      jstr(s.verifica) & ", \"verifica_testo\": " & jstr(s.verificaTesto) & "}"
  head(fileName, tempo) & ", \"errore\": " & jstr(errore) & ", \"risposte\": " & jarr(ris) &
    ", \"proposte_accettate\": " & jarr(pa) & ", \"sostituzioni_accettate\": " & jarr(sa) &
    ", \"interfaccia_accettate\": " & jarr(ia) & "}"

proc closeCopy(giroPath, msg: string, json: string, code: int) =
  ## 120:5:2 Chiude il giro, dà il JSON sullo standard output e il messaggio sullo standard error.
  discard tryRemoveFile(giroPath)
  emitJson json
  die(msg, code)

proc runRefineJson(args: seq[string]) =
  var pos: seq[string]
  var cscName = ""
  var haveCsc = false
  var mode = ""        # "", "answers", "accept", "cancel"
  var modello = "veloce"
  var haveModello = false
  var seenJson = false
  var i = 0
  while i < args.len:
    let a = args[i]
    if a == "--json":
      if seenJson: die(usoGiro(), 2)
      seenJson = true
    elif a in ["--answers", "--accept", "--cancel", "--show"]:
      if mode.len > 0: die(usoGiro(), 2)
      mode = a[2 .. ^1]
    elif a == "--csc":
      if haveCsc or i + 1 >= args.len: die(usoGiro(), 2)
      haveCsc = true
      cscName = args[i + 1]
      inc i
    elif a == "--modello":
      if haveModello or i + 1 >= args.len: die(usoGiro(), 2)
      haveModello = true
      modello = checkModello(args[i + 1], usoGiro())
      inc i
    elif a.len > 0 and a[0] == '-': die(usoGiro(), 2)
    else: pos.add a
    inc i
  if pos.len != 1 or (haveCsc and mode.len > 0 and mode != "show"): die(usoGiro(), 2)
  if haveCsc and not validName(cscName): die(testo(kNomeNonValido, P, cscName), 2)
  let file = pos[0]
  let fileName = extractFilename(file)
  let giroPath = file & ".giro"
  if mode != "show":
    discard loadSource(P, file)
    armGiornale("refine", file)      # 120:5:1 K1, K6: ogni forma salvo --show
  gGiroLingua = lingua        # 120:6:0 il tempo 1 fissa la lingua del giro; gli altri tempi la rileggono da FILE.giro (readGiro)
  case mode
  of "":
    # 120:6:1 Tempo 1: la prima chiamata
    let (limit, limitSrc) = envLimit()
    discard limitSrc
    gModello = modello
    let cx = prepare(file, haveCsc, cscName)
    let blk = cx.rep.blocks[cx.bi]
    if scopoDaCompilare(cx):
      emitJson head(fileName, 1) & ", \"errore\": \"scopo_da_scrivere\"}"
      die(scopoMsg(cx), 1)
    if pathInfo(giroPath).ok:
      emitJson head(fileName, 1) & ", \"errore\": \"giro_aperto\"}"
      die(testo(kCEGiaUnGiro, P, fileName, fileName), 1)
    let vec = providerVector(modello)
    let prov = providerName(vec)
    installSigint()
    let stamp = isoNow()
    var parsed = Parsed()
    block:
      let (msg, code) = callAndRead(cx.request, vec, prov, limit, fileName, file, false, parsed)
      if msg.len > 0: die(msg, code)
    var verdicts, sverdicts, iverdicts: seq[Ragione]
    discard filterAll(cx.raw, cx.rep, cx.bi, parsed, verdicts, sverdicts, iverdicts)
    if parsed.domande.len == 0 and parsed.proposte.len == 0 and parsed.nuoveCsc.len == 0 and parsed.sostituzioni.len == 0 and
        parsed.interfaccia.len == 0:
      emitJson head(fileName, 1) & ", \"chiamate\": 1, \"csc\": " & jstr(blk.name) &
        ", \"domande\": [], \"proposte\": [], \"sostituzioni\": [], \"csc_a_parte\": [], \"interfaccia\": [], \"precisa\": true, \"prossimo\": \"nessuno\"}"
      quit(0)
    var g = Giro(fase: (if parsed.domande.len > 0: "domande" else: "proposte"), stamp: stamp, cscArg: cscName, haveCsc: haveCsc, modello: modello, lingua: lingua,
      improntaCsc: fingerprint(cx.raw), improntaDlg: dlgImpronta(cx.dlgPath), chiamate: 1, parsed: parsed)
    writeGiro(giroPath, g, fileName, "", false)
    if parsed.domande.len > 0:
      emitJson head(fileName, 1) & ", \"chiamate\": 1, \"csc\": " & jstr(blk.name) & ", \"domande\": " & questionsJson(parsed) &
        ", \"proposte\": [], \"sostituzioni\": [], \"csc_a_parte\": [], \"interfaccia\": [], \"precisa\": false, \"prossimo\": \"answers\"}"
    else:
      let (pj, sj) = proposalsJson(cx, parsed, verdicts, sverdicts)
      emitJson head(fileName, 1) & ", \"chiamate\": 1, \"csc\": " & jstr(blk.name) & ", \"domande\": [], \"proposte\": " & pj &
        ", \"sostituzioni\": " & sj & ", \"csc_a_parte\": " & cscJson(parsed) & ", \"interfaccia\": " & ifaceJson(parsed, iverdicts) &
        ", \"precisa\": false, \"prossimo\": \"accept\"}"
    quit(0)
  of "cancel":
    # 120:6:2 Chiude il giro senza scrivere niente: la risposta n alla conferma del terminale
    discard readGiro(giroPath, fileName)
    discard tryRemoveFile(giroPath)
    emitJson head(fileName, 0) & ", \"chiuso\": true}"
    quit(0)
  of "answers":
    # 120:6:3 Tempo 2: le risposte, e la seconda chiamata se ce n'è almeno una
    let root = readStdinJson("risposte")
    let g0 = readGiro(giroPath, fileName)
    if g0.fase != "domande":
      emitJson head(fileName, 2) & ", \"errore\": \"fase_diversa\", \"fase\": " & jstr(g0.fase) & "}"
      die(testo(kIlGiroDiNonAspetta, P, fileName, g0.fase), 2)
    let qa = answersFrom(root, g0.parsed)
    let (limit, limitSrc) = envLimit()
    discard limitSrc
    # p-10: file cambiato dopo il tempo 1: niente seconda chiamata, il giro si chiude
    let rawNow = loadSource(P, file)
    if fingerprint(rawNow) != g0.improntaCsc or dlgImpronta(file & ".dialogo") != g0.improntaDlg:
      closeCopy(giroPath, testo(kCambiatoDuranteComando, P, file), copyJson(fileName, 2, "file_cambiato", qa, g0.parsed, @[], @[]), 1)
    let cx = prepare(file, g0.haveCsc, g0.cscArg)
    let prov = providerName(providerVector())
    var g = g0
    g.qa = qa
    var parsed = g0.parsed
    var ignored = 0
    if qa.len > 0:
      installSigint()
      let vec = providerVector(g0.modello)
      var parsed2 = Parsed()
      let (msg, code) = callAndRead(secondRequest(cx.request, qa), vec, prov, limit, fileName, file, true, parsed2)
      if msg.len > 0:
        if code != 130:
          # il giro resta aperto con le risposte: si salvano nel dialogo con il tempo 3 senza proposte
          g.fase = "risposte_fallite"
          g.chiamate = 2
          g.parsed.proposte = @[]
          g.parsed.sostituzioni = @[]
          g.parsed.nuoveCsc = @[]
          g.parsed.interfaccia = @[]
          writeGiro(giroPath, g, fileName, readGiroRaw(giroPath), true)
        die(msg, code)
      parsed.proposte = parsed2.proposte
      parsed.nuoveCsc = parsed2.nuoveCsc
      parsed.sostituzioni = parsed2.sostituzioni
      parsed.interfaccia = parsed2.interfaccia
      ignored = parsed2.domande.len
      g.chiamate = 2
      g.ignorate = ignored
    g.parsed = parsed
    g.fase = "proposte"
    writeGiro(giroPath, g, fileName, readGiroRaw(giroPath), true)
    var verdicts, sverdicts, iverdicts: seq[Ragione]
    discard filterAll(cx.raw, cx.rep, cx.bi, parsed, verdicts, sverdicts, iverdicts)
    let (pj, sj) = proposalsJson(cx, parsed, verdicts, sverdicts)
    emitJson head(fileName, 2) & ", \"chiamate\": " & $g.chiamate & ", \"domande_ignorate\": " & $ignored & ", \"proposte\": " & pj &
      ", \"sostituzioni\": " & sj & ", \"csc_a_parte\": " & cscJson(parsed) & ", \"interfaccia\": " & ifaceJson(parsed, iverdicts) &
      ", \"prossimo\": \"accept\"}"
    quit(0)
  of "show":
    # 120:6:5 Rimostra l'uscita del tempo a cui il giro è fermo: nessuna chiamata, nessun file scritto
    # (neppure FILE.giro), salvo il caso del file cambiato, che chiude il giro come i tempi 2 e 3 (p-10).
    let g = readGiro(giroPath, fileName)
    if g.fase == "risposte_fallite":
      emitJson head(fileName, 2) & ", \"errore\": \"fase_diversa\", \"fase\": " & jstr(g.fase) & "}"
      die(testo(kIlGiroDiHaLe, P, fileName), 2)
    let tempoShown = if g.fase == "domande": 1 elif g.parsed.domande.len == 0: 1 else: 2
    let rawNow = loadSource(P, file)
    if fingerprint(rawNow) != g.improntaCsc or dlgImpronta(file & ".dialogo") != g.improntaDlg:
      closeCopy(giroPath, testo(kCambiatoDuranteComando, P, file),
        copyJson(fileName, tempoShown, "file_cambiato", g.qa, g.parsed, @[], @[]), 1)
    let cx = prepare(file, g.haveCsc, g.cscArg)
    let blk = cx.rep.blocks[cx.bi]
    if haveCsc and cscName != blk.name:
      die(testo(kIlGiroDiESu, P, fileName, blk.name, cscName), 2)
    if g.fase == "domande":
      emitJson head(fileName, 1) & ", \"chiamate\": 1, \"csc\": " & jstr(blk.name) & ", \"domande\": " & questionsJson(g.parsed) &
        ", \"proposte\": [], \"sostituzioni\": [], \"csc_a_parte\": [], \"interfaccia\": [], \"precisa\": false, \"prossimo\": \"answers\"}"
      quit(0)
    var parsed = g.parsed
    var verdicts, sverdicts, iverdicts: seq[Ragione]
    discard filterAll(cx.raw, cx.rep, cx.bi, parsed, verdicts, sverdicts, iverdicts)
    let (pj, sj) = proposalsJson(cx, parsed, verdicts, sverdicts)
    if tempoShown == 1:
      emitJson head(fileName, 1) & ", \"chiamate\": 1, \"csc\": " & jstr(blk.name) & ", \"domande\": [], \"proposte\": " & pj &
        ", \"sostituzioni\": " & sj & ", \"csc_a_parte\": " & cscJson(parsed) & ", \"interfaccia\": " & ifaceJson(parsed, iverdicts) &
        ", \"precisa\": false, \"prossimo\": \"accept\"}"
    else:
      emitJson head(fileName, 2) & ", \"chiamate\": " & $g.chiamate & ", \"domande_ignorate\": " & $g.ignorate & ", \"proposte\": " & pj &
        ", \"sostituzioni\": " & sj & ", \"csc_a_parte\": " & cscJson(parsed) & ", \"interfaccia\": " & ifaceJson(parsed, iverdicts) &
        ", \"prossimo\": \"accept\"}"
    quit(0)
  else:
    # 120:6:4 Tempo 3: compone, controlla e scrive, come la conferma del terminale
    let root = readStdinJson("accettate")
    let g = readGiro(giroPath, fileName)
    if g.fase == "domande":
      emitJson head(fileName, 3) & ", \"errore\": \"fase_diversa\", \"fase\": " & jstr(g.fase) & "}"
      die(testo(kIlGiroDiAspettaAncora, P, fileName), 2)
    let (pIdx, sIdx, iIdx) = acceptedFrom(root, g)
    if g.fase == "risposte_fallite" and (pIdx.len > 0 or sIdx.len > 0 or iIdx.len > 0):
      die(testo(kLaSecondaChiamataNonE, P), 2)
    let rawNow = loadSource(P, file)
    if fingerprint(rawNow) != g.improntaCsc or dlgImpronta(file & ".dialogo") != g.improntaDlg:
      closeCopy(giroPath, testo(kCambiatoDuranteComando, P, file),
        copyJson(fileName, 3, "file_cambiato", g.qa, g.parsed, pIdx, sIdx, iIdx), 1)
    let cx = prepare(file, g.haveCsc, g.cscArg)
    let raw = cx.raw
    let rep = cx.rep
    let bi = cx.bi
    let blk = rep.blocks[bi]
    var verdicts, sverdicts, iverdicts: seq[Ragione]
    discard filterAll(raw, rep, bi, g.parsed, verdicts, sverdicts, iverdicts)
    for k in iIdx:
      if not iverdicts[k].passa:
        die(testo(kLaRigaDInterfacciaI, P, $(k + 1), ragioneTesto(iverdicts[k])), 2)
    for k in pIdx:
      if not verdicts[k].passa:
        die(testo(kLaPropostaPEScartata, P, $(k + 1), ragioneTesto(verdicts[k])), 2)
    for k in sIdx:
      if not sverdicts[k].passa:
        die(testo(kLaSostituzioneSEScartata, P, $(k + 1), ragioneTesto(sverdicts[k])), 2)
    var accepted: seq[Proposal]
    var ss: seq[Subst]
    for k in pIdx: accepted.add g.parsed.proposte[k]
    for k in sIdx: ss.add g.parsed.sostituzioni[k]
    let nP = accepted.len
    let nS = ss.len
    var ifs: seq[string]
    for k in iIdx: ifs.add g.parsed.interfaccia[k].riga
    let nI = ifs.len
    let nA = nP + nS + nI
    let nR = g.qa.len
    let nC = (if g.fase == "risposte_fallite": 0 else: g.parsed.nuoveCsc.len)
    var scrittoCsc = "null"
    var scrittoDlg = "null"
    if nA > 0:
      let nt = composeFile(raw, rep, bi, accepted, ss, ifs)
      if nt.len == 0:
        die(testo(kErroreInternoIlTestoModificato, P), 1)
      var why = ""
      let wr = safeReplace(file, nt, raw, true, why)
      if wr == wrChanged:
        closeCopy(giroPath, testo(kCambiatoDuranteComando, P, file),
          copyJson(fileName, 3, "file_cambiato", g.qa, g.parsed, pIdx, sIdx, iIdx), 1)
      if wr != wrOk: die(writeErrorMessage(P, file, wr, why), 1)
      scrittoCsc = jstr(filePart(nS, nP, nI))
    if nR > 0 or nC > 0:
      var why = ""
      let nuove = if nC > 0: g.parsed.nuoveCsc else: @[]
      let wr = safeReplace(cx.dlgPath, dialogBody(cx.dlgExists, cx.dlgText, g.stamp, blk.name, g.qa, nuove, blk.isEntity), cx.dlgText, cx.dlgExists, why)
      if wr != wrOk:
        let m = if wr == wrChanged: testo(kECambiatoDuranteIlComando, P, cx.dlgPath)
                else: writeErrorMessage(P, cx.dlgPath, wr, why)
        closeCopy(giroPath, m, copyJson(fileName, 3, "dialogo_non_scritto", g.qa, g.parsed, @[], @[]), 1)
      scrittoDlg = jstr(dialogPart(nR, nC))
    discard tryRemoveFile(giroPath)
    emitJson head(fileName, 3) & ", \"scritto\": {\"csc\": " & scrittoCsc & ", \"dialogo\": " & scrittoDlg & "}, \"impronta\": " &
      jstr(fingerprint(readFile(file))) & "}"
    quit(0)

proc runRefine*(args: seq[string]) =
  # 119:0:1 Dal pezzo 4 dell'editor: con --json il giro si divide in tempi; senza, il terminale com'è.
  if "--json" in args:
    runRefineJson(args)
    return
  gGiroLingua = lingua        # 119:0:2 nel terminale il giro ha la lingua del comando
  # 119:1:1 Passo 1: argomenti e ambiente
  var pos: seq[string]
  var cscName = ""
  var haveCsc = false
  var haveModello = false
  var i = 0
  while i < args.len:
    let a = args[i]
    if a == "--csc":
      if haveCsc or i + 1 >= args.len: die(usoRefine(), 2)
      haveCsc = true
      cscName = args[i + 1]
      i += 2
      continue
    if a == "--modello":
      if haveModello or i + 1 >= args.len: die(usoRefine(), 2)
      haveModello = true
      gModello = checkModello(args[i + 1], usoRefine())
      i += 2
      continue
    if a.len > 0 and a[0] == '-': die(usoRefine(), 2)
    pos.add a
    inc i
  if pos.len != 1: die(usoRefine(), 2)
  let file = pos[0]
  if haveCsc and not validName(cscName): die(testo(kNomeNonValido, P, cscName), 2)
  discard loadSource(P, file)
  armGiornale("refine", file)      # 119:1:2 K1, K6: prima di ogni chiamata al modello
  let (limit, limitSrc) = envLimit()
  let cx = prepare(file, haveCsc, cscName)
  let raw = cx.raw
  let rep = cx.rep
  let bi = cx.bi
  let blk = rep.blocks[bi]
  let fileName = cx.fileName
  if scopoDaCompilare(cx): die(scopoMsg(cx), 1)
  let dlgPath = cx.dlgPath
  let dlgShown = cx.dlgShown
  let dlgText = cx.dlgText
  let dlgExists = cx.dlgExists
  let request = cx.request
  let vec = providerVector(gModello)
  let prov = providerName(vec)
  let callLine = testo(kChiedoAllLLMLimiteS, prov, $limit, limitSrc)
  emitLn "bcdd refine " & fileName
  emitLn testo(kNessunErroreRigheNonRiconosciute, (if blk.isEntity: "ENTITY " else: "CSC "), blk.name, $rep.unrecLines)
  emitLn callLine
  # 119:5:1 Passo 7: la prima chiamata. La data del giro (riga GIRO del dialogo) è quella d'inizio di questa.
  installSigint()
  let stamp = isoNow()
  var parsed = Parsed()
  block:
    let (msg, code) = callAndRead(request, vec, prov, limit, fileName, file, false, parsed)
    if msg.len > 0:
      if code == 130: abortRun(msg)
      die(msg, code)
  # 119:6:1 Passo 9: il filtro, proposta per proposta
  var verdicts, sverdicts, iverdicts: seq[Ragione]          # ragione dello scarto, "" se passa
  var nDiscarded = filterAll(raw, rep, bi, parsed, verdicts, sverdicts, iverdicts)
  emitLn lettaLine(parsed, true, nDiscarded, 0)
  # 119:6:2 Passo 9a (dalla 1.4): la prima risposta senza domande, proposte né CSC a parte è il segnale di fine
  if parsed.domande.len == 0 and parsed.proposte.len == 0 and parsed.nuoveCsc.len == 0 and
      parsed.sostituzioni.len == 0 and parsed.interfaccia.len == 0:
    emitLn ""
    emitLn testo(kLaEPrecisaAbbastanzaNessuna, (if blk.isEntity: "ENTITY " else: "CSC "), blk.name, fileName)
    quit(0)
  # 119:7:1 Passo 10: le domande
  var qa: seq[(string, string)]
  if parsed.domande.len > 0:
    emitLn ""
    emitLn testo(kPerRispondereScriviIlNumero)
  for i, q in parsed.domande:
    emitLn ""
    emitLn testo(kDomandaNdiM, i + 1, parsed.domande.len)
    for l in q.testo.split('\n'): emitLn "  " & l
    for k, c in q.scelte: emitLn "  " & $(k + 1) & ") " & c
    let nS = q.scelte.len
    var a = ""
    while true:
      a = sanitize(trimWs(ask(testo(kRispostaDa1AOppure, $nS))))
      if a.len > 0 and a.allCharsInSet({'0' .. '9'}):
        var picked = -1
        for k in 0 ..< nS:
          if a == $(k + 1): picked = k
        if picked >= 0:
          emitLn testo(kScelta, picked + 1, q.scelte[picked])
          a = q.scelte[picked]
          break
        emitLn testo(kNessunaSceltaScriviUnNumero, shown(a), $nS)
        continue
      break
    if a.len > 0: qa.add (q.testo, a)
  # 119:7:2 Passo 10a: se c'è almeno una risposta, la seconda chiamata
  if qa.len > 0:
    var sameFile = false
    try: sameFile = readFile(file) == raw
    except IOError, OSError: sameFile = false
    if not sameFile:
      unsaved(@[], qa)
      die(testo(kCambiatoDuranteComando, P, file), 1)
    emitLn ""
    emitLn testo(kHaiRisposto, plural(qa.len, kDomandaSing, kDomandaPlur), prov)
    emitLn callLine
    var parsed2 = Parsed()
    let (msg, code) = callAndRead(secondRequest(request, qa), vec, prov, limit, fileName, file, true, parsed2)
    if msg.len > 0:
      if code == 130:
        unsaved(@[], qa)
        abortRun(msg)
      # 119:7:3 Punto 6 della sezione 4.3: errore alla seconda chiamata; le risposte si salvano solo se la persona lo conferma
      stderr.write msg & "\n"
      stderr.flushFile()
      let c = askChoice(testo(kScrivoRisposte, plural(qa.len, kRispostaSing, kRispostaPlur), dlgShown),
        [lYes(), "n"], testo(kRispondiSN))
      if c == "n":
        emitLn testo(kNienteScrittoRisposteNonSalvate)
        quit(4)
      var why = ""
      let wr = safeReplace(dlgPath, dialogBody(dlgExists, dlgText, stamp, blk.name, qa, isEntity = blk.isEntity), dlgText, dlgExists, why)
      if wr != wrOk:
        unsaved(@[], qa)
        if wr == wrChanged: die(testo(kECambiatoDuranteIlComando, P, dlgPath), 4)
        die(writeErrorMessage(P, dlgPath, wr, why), 4)
      emitLn testo(kScrittoDove, dlgShown, plural(qa.len, kRispostaSing, kRispostaPlur))
      quit(4)
    parsed.proposte = parsed2.proposte
    parsed.nuoveCsc = parsed2.nuoveCsc          # 119:7:4 con la seconda chiamata contano le CSC a parte della seconda risposta
    parsed.sostituzioni = parsed2.sostituzioni  # 119:7:5 e le sostituzioni della seconda risposta (dalla 1.5)
    parsed.interfaccia = parsed2.interfaccia    # 119:7:6 e le righe d'interfaccia della seconda risposta
    nDiscarded = filterAll(raw, rep, bi, parsed, verdicts, sverdicts, iverdicts)
    emitLn lettaLine(parsed, false, nDiscarded, parsed2.domande.len)
  # 119:8:1 Passo 11: le proposte
  var accepted: seq[Proposal]
  var acceptedSubs: seq[SubView]
  var refusedByUser = 0
  var finished = false
  # 119:8:0 Dalla 1.5: prima le sostituzioni (sezione 7.2), con la riga di adesso e quella nuova
  for k, sb in parsed.sostituzioni:
    emitLn ""
    if not sverdicts[k].passa:
      emitLn testo(kSOSTITUZIONEDiSCARTATADalControllo, $(k + 1), $parsed.sostituzioni.len)
      emitLn testo(kRagione, ragioneTesto(sverdicts[k]))
      emitLn testo(kId2, shown(sb.id))
      emitLn testo(kTesto, shown(sb.testo))
      emitLn testo(kVerificaVerificaTesto, shown(sb.verifica), shown(sb.verificaTesto))
      continue
    if finished:
      inc refusedByUser
      continue
    let v = viewOf(raw, rep, bi, sb)
    emitLn testo(kSOSTITUZIONEDiAlPostoDi, $(k + 1), $parsed.sostituzioni.len, sb.id, $v.line)
    emitLn testo(kAdesso)
    for l in v.nowL: emitLn "    " & l
    emitLn testo(kDiventa)
    emitLn "    " & v.new1
    emitLn "    " & v.new2
    if v.details.len > 0: emitLn testo(kRestanoIDettagliDiDa, sb.id, v.details.join(", "))
    let c = askChoice(testo(kAccettiSSiNNo), [lYes(), "n", lQuit()],
      testo(kRispondiSNF))
    case c
    of "n": inc refusedByUser
    else:
      if c == lYes():
        acceptedSubs.add v
        continue
      inc refusedByUser
      finished = true
  # 119:8:3 poi le righe d'interfaccia (sezione 13.1), prima delle proposte
  var acceptedIface: seq[string]
  for k, ifc in parsed.interfaccia:
    emitLn ""
    if not iverdicts[k].passa:
      emitLn testo(kRIGADINTERFACCIADiSCARTATA, $(k + 1), $parsed.interfaccia.len)
      emitLn testo(kRagione, ragioneTesto(iverdicts[k]))
      emitLn testo(kRiga5, shown(ifc.riga))
      emitLn testo(kMotivo, shown(ifc.motivo))
      continue
    if finished:
      inc refusedByUser
      continue
    emitLn testo(kRigaInterfacciaNdiM, k + 1, parsed.interfaccia.len)
    emitLn "  " & trimWs(ifc.riga)
    emitLn testo(kMotivo, ifc.motivo)
    let c = askChoice(testo(kAccettiSSiNNo), [lYes(), "n", lQuit()],
      testo(kRispondiSNF))
    case c
    of "n": inc refusedByUser
    else:
      if c == lYes():
        acceptedIface.add ifc.riga
        continue
      inc refusedByUser
      finished = true
  for k, p in parsed.proposte:
    emitLn ""
    if not verdicts[k].passa:
      emitLn testo(kPROPOSTADiSCARTATADalControllo, $(k + 1), $parsed.proposte.len)
      emitLn testo(kRagione, ragioneTesto(verdicts[k]))
      emitLn testo(kTipoIdDettaglia, shown(p.tipo), shown(p.id), shown(p.dettaglia))
      emitLn testo(kTesto, shown(p.testo))
      emitLn testo(kVerificaVerificaTesto, shown(p.verifica), shown(p.verificaTesto))
      continue
    if finished:
      inc refusedByUser
      continue
    var row: RowInfo
    for r in rep.rows:
      if r.blockIdx == bi and r.id == p.dettaglia: row = r
    if p.dettaglia.len == 0:
      emitLn testo(kPROPOSTADiPromessaNuova, $(k + 1), $parsed.proposte.len)     # promessa di base
    else:
      emitLn testo(kPROPOSTADiDettagliaRiga, $(k + 1), $parsed.proposte.len, p.dettaglia, $row.line)
    emit fmtPair(p)
    let c = askChoice(testo(kAccettiSSiNNo), [lYes(), "n", lQuit()],
      testo(kRispondiSNF))
    case c
    of "n": inc refusedByUser
    else:
      if c == lYes():
        accepted.add p
        continue
      inc refusedByUser
      finished = true
  # 119:8:2 Passo 11 (dalla 1.4): le CSC a parte, dopo le proposte e prima del riepilogo; nessun file creato (g-r8)
  for i, c in parsed.nuoveCsc:
    emitLn ""
    emitLn testo(kCscAParteNdiM, i + 1, parsed.nuoveCsc.len, c.nome)
    emitLn testo(kMotivo, c.motivo)
    emitLn testo(kSeVuoiScriverlaBcddNew, c.nome)
  emitLn ""
  let nP = accepted.len
  let nS = acceptedSubs.len
  let nI = acceptedIface.len
  emitLn testo(kRiepilogo, nP + nS + nI, (if parsed.sostituzioni.len > 0: testo(kRiepSostituzioni, nS) else: ""),
    (if parsed.interfaccia.len > 0: testo(kRiepInterfaccia, nI) else: ""), refusedByUser, nDiscarded)
  # 119:9:1 Passi 12-13: conferma e scrittura
  let nA = nP + nS + nI
  let nR = qa.len
  let nC = parsed.nuoveCsc.len
  if nA == 0 and nR == 0 and nC == 0:
    emitLn testo(kNienteDaScrivereNonCambia, fileName)
    quit(0)
  var what = ""
  if nA > 0 and (nR > 0 or nC > 0):
    what = testo(kInDoveE, filePart(nS, nP, nI), fileName, dialogPart(nR, nC), dlgShown)
  elif nA > 0:
    what = testo(kInDove, filePart(nS, nP, nI), fileName)
  else:
    what = testo(kInDove, dialogPart(nR, nC), dlgShown)
  let conf = askChoice(testo(kScrivoSSiNNo, what), [lYes(), "n"], testo(kRispondiSN))
  if conf == "n":
    emitLn testo(kNienteScrittoNonCambia, fileName)
    quit(0)
  if nA > 0:
    # 119:9:3 Sezione 6.7: prima le sostituzioni, poi le proposte nel testo che le contiene
    var ss: seq[Subst]
    for v in acceptedSubs: ss.add v.s
    let nt = composeFile(raw, rep, bi, accepted, ss, acceptedIface)
    if nt.len == 0:
      die(testo(kErroreInternoIlTestoModificato, P), 1)
    var why = ""
    let wr = safeReplace(file, nt, raw, true, why)
    if wr != wrOk:
      if wr == wrChanged: unsaved(accepted, qa, acceptedSubs, acceptedIface)
      die(writeErrorMessage(P, file, wr, why), 1)
    emitLn testo(kScrittoDove, fileName, filePart(nS, nP, nI))
  if nR > 0 or nC > 0:
    var why = ""
    let wr = safeReplace(dlgPath, dialogBody(dlgExists, dlgText, stamp, blk.name, qa, parsed.nuoveCsc, blk.isEntity), dlgText, dlgExists, why)
    if wr != wrOk:
      # 119:9:2 Correzioni della 1.1 (AC-65): per ogni errore di scrittura del dialogo si stampano le risposte non
      # salvate; se il dialogo è cambiato il file CSC può essere già scritto, quindi il messaggio non dice "niente scritto".
      unsaved(@[], qa)
      if wr == wrChanged: die(testo(kECambiatoDuranteIlComando, P, dlgPath), 1)
      die(writeErrorMessage(P, dlgPath, wr, why), 1)
    emitLn testo(kScrittoDove, dlgShown, dialogPart(nR, nC))
  quit(0)

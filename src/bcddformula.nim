# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 091:1:1 Formule, espressioni, tipi e nomi (GRAMMATICA_F1 1.0-beta, sezioni 4.12, 4.13, 4.14): lettura e controllo statico.
# 091:1:2 Nessuna formula si valuta: si legge la forma (G55-G64), si controllano nomi (E24) e tipi (E25) e le regole di forma
# 091:1:3 (E26, E27, E29). Un errore si dà solo quando la formula è letta per intero; altrimenti la dichiarazione non è riconosciuta.
import std/[strutils, tables, sets]
import bcddlex, bcddwords, bcddtesti

type
  TyK* = enum
    tUnk, tBool, tInt, tReal, tDur, tStr, tEnum, tRec, tSeq, tOpt, tEvt, tAbsent, tNamed

  Ty* = ref object
    k*: TyK
    name*: string                   # elenco di valori, tipo con nome, Record con nome
    inner*: Ty
    fields*: seq[(string, Ty)]
    values*: seq[string]            # solo tEnum
    lo*, hi*: string                # limiti come scritti, "" se omessi
    hasRange*: bool
    shown*: string                  # il tipo come scritto nella dichiarazione

  SymKind* = enum
    sCap, sEvent, sDefEvent, sState, sDefine, sRow, sScn, sType, sValue, sPart, sExt

  Sym* = object
    kind*: SymKind
    ty*: Ty
    idx*: Ty                        # tipo dell'indice di uno stato, nil se non ne ha
    params*: seq[(string, Ty)]
    hasParams*: bool
    line*: int
    undecided*: bool

  ParamSpec* = object
    name*: string
    cat*: string                    # Name Type Event Condition Expression Duration Property, oppure "" se è un tipo
    ty*: Ty

  ExtDef* = object
    name*, kind*, level*, profile*, profVersion*: string
    params*: seq[ParamSpec]
    form*: seq[Tok]
    formText*: string
    hasRed*: bool
    result*: Ty                     # KIND FUNCTION
    bad*: bool                      # almeno un errore E33-E36 nel suo file
    checks*: seq[string]            # i controlli C1..C8 del suo VERIFY V1
    profRatified*: bool             # il profilo è approvato

  FErr* = object
    line*, col*: int
    code*, msg*: string
    form*: bool          # vero per l'E37 «uso che non rispetta FORM»: si legge questo, mai il testo del messaggio

  Env* = ref object
    syms*: Table[string, Sym]
    types*: Table[string, Ty]       # tipi con nome (G41) e elenchi di valori
    described*: HashSet[string]     # tipi descritti a parole
    enumOf*: Table[string, string]  # valore -> nome dell'elenco
    exts*: Table[string, ExtDef]
    isEntity*: bool
    blockLevel*: string             # CSC ENTITY BINDING VERIFICATION
    isAssume*: bool
    pnf*: string                    # motivo: profilo non trovato o estensione con errori ("" se tutto trovato)
    defToks*: Table[string, seq[Tok]]       # DEFINE -> tokens dell'espressione
    defTys: Table[string, Ty]
    defBusy: HashSet[string]
    conns*: HashSet[string]         # entità: connettori offerti o usati
    badExt*: Table[string, string]  # estensioni con errori: nome -> motivo
    entName*: string
    resolving: HashSet[string]

  Fm* = ref object
    env*: Env
    t: seq[Tok]
    p: int
    errs*: seq[FErr]
    scopes: seq[Table[string, Ty]]
    exts*: seq[string]              # nomi delle estensioni usate
    extNoRed*: bool
    refs*: HashSet[string]          # DEFINE nominate
    used*: HashSet[string]          # nomi del blocco nominati (stati, eventi, richieste, costanti)
    qrefs*: seq[(Tok, Tok, string)] # entità: (X, y, genere) da controllare dopo la ricerca
    valUses*: seq[Tok]
    dev*: HashSet[string]           # DEFINE EVENT nominate (4.14: gli usi passano attraverso le DEFINE nominate)
    trace: bool                     # lettura di una REDUCES TO: si registrano i costrutti e gli operandi (E36 sull'albero)
    marks: seq[string]              # la prima parola o il segno di ogni costrutto applicato
    atoms: seq[Tok]                 # gli operandi semplici: nomi, numeri, stringhe, true, false, ABSENT
    declMode: bool                  # uso di KIND DECLARATION: il primo posto Name è il nome dichiarato dalla riga
    declName: Tok
    propParams: HashSet[string]     # lettura di una REDUCES TO: i parametri di categoria Property (stanno dove sta una proprietà)

  Fail = object of CatchableError

  R = object
    ty: Ty
    tok: Tok
    sym: string
    bare: bool
    isEvt: bool

const
  PatternWords = ["ALWAYS", "EVENTUALLY", "WHENEVER", "NEVER", "ACCEPTS", "RESOLVES", "TRANSITION"]
  ScopeWords = ["WHILE", "AFTER", "BEFORE", "BETWEEN"]
  FuncWords = ["ABS", "LOG10", "ROUND", "FLOOR", "CEIL", "PREV", "PRESENT", "CHANGED"]
  CmpOps = ["=", "<>", "<", "<=", ">", ">="]

let
  tyUnk* = Ty(k: tUnk)
  tyBool* = Ty(k: tBool, shown: "Boolean")
  tyInt* = Ty(k: tInt, shown: "Integer")
  tyReal* = Ty(k: tReal, shown: "Real")
  tyDur* = Ty(k: tDur, shown: "Duration")
  tyStr* = Ty(k: tStr, shown: "String")
  tyEvt = Ty(k: tEvt)
  tyAbsent = Ty(k: tAbsent)

proc newEnv*(): Env =
  Env(syms: initTable[string, Sym](), types: initTable[string, Ty](), described: initHashSet[string](),
    enumOf: initTable[string, string](), exts: initTable[string, ExtDef](), defToks: initTable[string, seq[Tok]](),
    defTys: initTable[string, Ty](), defBusy: initHashSet[string](), conns: initHashSet[string](),
    resolving: initHashSet[string]())

# 091:2:1 Predicati sugli elementi
proc isUnitAt*(t: seq[Tok], k: int): bool =
  ## G27: «ms» e «s» sulla stessa riga di un numero, subito dopo, sono l'unità di una durata, non un nome
  k > 0 and k < t.len and t[k].kind == tkWord and t[k].text in ["ms", "s"] and t[k - 1].kind == tkNum and t[k - 1].line == t[k].line and
    t[k - 1].text.count('.') <= 1

proc isW(t: Tok, s: string): bool = t.kind == tkWord and t.text == s
proc isS(t: Tok, s: string): bool = t.kind == tkSym and t.text == s
proc isName*(t: Tok): bool = t.kind == tkWord and not isReservedWord(t.text) and '-' notin t.text
proc isNumTok(t: Tok): bool = t.kind == tkNum and t.text.count('.') <= 1

proc fail() {.noreturn.} = raise newException(Fail, "")

proc has(f: Fm): bool = f.p < f.t.len
proc cur(f: Fm): Tok = f.t[f.p]
proc nxt(f: Fm, k = 1): Tok =
  if f.p + k < f.t.len: f.t[f.p + k] else: Tok(kind: tkForeign, text: "")
proc atW(f: Fm, s: string): bool = f.has and isW(f.cur, s)
proc atS(f: Fm, s: string): bool = f.has and isS(f.cur, s)
proc eatW(f: Fm, s: string): bool =
  if f.atW(s):
    inc f.p
    return true
  false
proc eatS(f: Fm, s: string): bool =
  if f.atS(s):
    inc f.p
    return true
  false
proc needW(f: Fm, s: string) = (if not f.eatW(s): fail())
proc needS(f: Fm, s: string) = (if not f.eatS(s): fail())

proc err(f: Fm, t: Tok, code, msg: string) =
  f.errs.add FErr(line: t.line, col: t.col, code: code, msg: msg)

proc errForm(f: Fm, t: Tok, msg: string) =
  ## 091:2:3 L'E37 di FORM: l'indicatore sta nell'errore, così nessuno legge più il testo.
  f.errs.add FErr(line: t.line, col: t.col, code: "E37", msg: msg, form: true)

proc mk(f: Fm, label: string) = (if f.trace: f.marks.add label)
proc atom(f: Fm, t: Tok) = (if f.trace: f.atoms.add t)

# 091:3:1 Tipi: nomi per i messaggi, risoluzione dei tipi con nome
proc resolveTy*(env: Env, t: Ty, tokForErr: Tok = Tok()): Ty =
  ## 091:3:2 Espande un tipo con nome; un tipo non dichiarato o descritto a parole è non noto. Un giro dà tUnk (E28 lo segnala altrove).
  if t == nil: return tyUnk
  var x = t
  var guard = 0
  while x != nil and x.k == tNamed and guard < 64:
    inc guard
    if x.name in env.types: x = env.types[x.name]
    else: return tyUnk
  if x == nil or x.k == tNamed: tyUnk else: x

proc unwrap*(env: Env, t: Ty): Ty =
  var x = resolveTy(env, t)
  while x.k == tOpt: x = resolveTy(env, x.inner)
  x

proc tyText*(env: Env, t: Ty): string =
  let x = resolveTy(env, t)
  case x.k
  of tBool: "Boolean"
  of tInt: "Integer"
  of tReal: "Real"
  of tDur: "Duration"
  of tStr: "String"
  of tEnum: x.name
  of tRec: (if x.name.len > 0: x.name else: "Record")
  of tSeq: "Sequence of " & tyText(env, x.inner)
  of tOpt: "Optional " & tyText(env, x.inner)
  of tEvt: testo(kUnEvento)
  of tAbsent: "ABSENT"
  else: "?"

proc isNumTy(env: Env, t: Ty): bool = unwrap(env, t).k in {tInt, tReal}
proc isDurTy(env: Env, t: Ty): bool = unwrap(env, t).k == tDur
proc isUnk(env: Env, t: Ty): bool = unwrap(env, t).k == tUnk

proc finiteTy*(env: Env, t: Ty): bool =
  let x = resolveTy(env, t)
  case x.k
  of tBool, tEnum: true
  of tInt: x.lo.len > 0 and x.hi.len > 0
  else: false

# 091:3:3 Lettura di un tipo (G13, G14, G41, G42) da una sequenza di elementi; i nomi non dichiarati si riportano in `undecl`
proc readTy*(t: seq[Tok], p: var int, undecl: var seq[Tok]): Ty =
  ## Restituisce nil se la sequenza non rispetta G13; p va dopo il tipo.
  if p >= t.len or t[p].kind != tkWord: return nil
  let w = t[p]
  let startP = p
  proc shownOf(a, b: int): string =
    var s = ""
    for i in a ..< b:
      let x = t[i].text
      if s.len > 0 and not (x in ["]", ",", "}", ")"]) and not s.endsWith("[") and not s.endsWith("{") and not s.endsWith("("): s.add " "
      s.add x
    s
  case w.text
  of "Boolean":
    inc p
    return Ty(k: tBool, shown: "Boolean")
  of "String":
    inc p
    return Ty(k: tStr, shown: "String")
  of "Duration":
    inc p
    return Ty(k: tDur, shown: "Duration")
  of "Integer", "Real":
    inc p
    var r = Ty(k: (if w.text == "Integer": tInt else: tReal))
    if p < t.len and isS(t[p], "["):
      inc p
      if p < t.len and t[p].kind == tkNum and isNumTok(t[p]):
        r.lo = t[p].text
        inc p
      if not (p < t.len and isS(t[p], "..")): return nil
      inc p
      if p < t.len and t[p].kind == tkNum and isNumTok(t[p]):
        r.hi = t[p].text
        inc p
      if r.lo.len == 0 and r.hi.len == 0: return nil
      if not (p < t.len and isS(t[p], "]")): return nil
      inc p
      r.hasRange = true
    r.shown = shownOf(startP, p)
    return r
  of "Sequence":
    inc p
    if not (p < t.len and isW(t[p], "of")): return nil
    inc p
    let i = readTy(t, p, undecl)
    if i == nil: return nil
    return Ty(k: tSeq, inner: i, shown: shownOf(startP, p))
  of "Optional":
    inc p
    let i = readTy(t, p, undecl)
    if i == nil: return nil
    return Ty(k: tOpt, inner: i, shown: shownOf(startP, p))
  of "Record":
    inc p
    if not (p < t.len and isS(t[p], "{")): return nil
    inc p
    var r = Ty(k: tRec)
    var seen = initHashSet[string]()
    while true:
      if not (p < t.len and isName(t[p])): return nil
      let fn = t[p]
      inc p
      if not (p < t.len and isS(t[p], ":")): return nil
      inc p
      let ft = readTy(t, p, undecl)
      if ft == nil: return nil
      r.fields.add (fn.text, ft)
      seen.incl fn.text
      if p < t.len and isS(t[p], ","):
        inc p
        continue
      break
    if not (p < t.len and isS(t[p], "}")): return nil
    inc p
    r.shown = shownOf(startP, p)
    return r
  else:
    if isName(w):
      inc p
      undecl.add w
      return Ty(k: tNamed, name: w.text, shown: w.text)
    return nil

# 091:3:4 Valori scritti (sezione 4.13, «I valori scritti»): il valore sta nel tipo dichiarato?
proc cmpNum(a, b: string): int =
  ## confronto fra due numeri decimali scritti (con segno e punto)
  proc parts(s: string): (bool, string, string) =
    var neg = false
    var x = s
    if x.startsWith("-"):
      neg = true
      x = x[1 .. ^1]
    var ip = x
    var fp = ""
    let d = x.find('.')
    if d >= 0:
      ip = x[0 ..< d]
      fp = x[d + 1 .. ^1]
    ip = ip.strip(leading = true, trailing = false, chars = {'0'})
    fp = fp.strip(leading = false, trailing = true, chars = {'0'})
    (neg, ip, fp)
  let (na, ia, fa) = parts(a)
  let (nb, ib, fb) = parts(b)
  let za = ia.len == 0 and fa.len == 0
  let zb = ib.len == 0 and fb.len == 0
  let sa = if za: 0 elif na: -1 else: 1
  let sb = if zb: 0 elif nb: -1 else: 1
  if sa != sb: return cmp(sa, sb)
  if sa == 0: return 0
  var m = 0
  if ia.len != ib.len: m = cmp(ia.len, ib.len)
  elif ia != ib: m = cmp(ia, ib)
  else:
    var x = fa
    var y = fb
    while x.len < y.len: x.add '0'
    while y.len < x.len: y.add '0'
    m = cmp(x, y)
  if sa < 0: -m else: m

proc valueOk*(env: Env, ty: Ty, v: seq[Tok]): bool =
  ## v: il valore come elementi (stringa, numero [unità], true, false, ABSENT, nome).
  if v.len == 0: return true
  let x = resolveTy(env, ty)
  let f = v[0]
  var unit = ""
  if v.len >= 2 and v[1].kind == tkWord and v[1].text in ["s", "ms"]: unit = v[1].text
  case x.k
  of tUnk: return true
  of tBool: return f.kind == tkWord and f.text in ["true", "false"]
  of tStr: return f.kind == tkStr
  of tDur: return f.kind == tkNum and unit.len > 0
  of tInt, tReal:
    if f.kind != tkNum or unit.len > 0: return false
    if x.k == tInt and '.' in f.text: return false
    if x.lo.len > 0 and cmpNum(f.text, x.lo) < 0: return false
    if x.hi.len > 0 and cmpNum(f.text, x.hi) > 0: return false
    return true
  of tEnum: return f.kind == tkWord and f.text in x.values
  of tOpt: return (f.kind == tkWord and f.text == "ABSENT") or valueOk(env, x.inner, v)
  of tRec, tSeq: return false
  else: return true

# 091:4:1 Risoluzione dei nomi
proc lookupScope(f: Fm, n: string): Ty =
  for i in countdown(f.scopes.high, 0):
    if n in f.scopes[i]: return f.scopes[i][n]
  nil

proc defTy(f: Fm, name: string): Ty

proc symFor(f: Fm, n: string): (bool, Sym) =
  if n in f.env.syms:
    f.used.incl n
    (true, f.env.syms[n])
  else: (false, Sym())

proc symGenre(k: SymKind): string =
  case k
  of sCap: "CAPABILITY"
  of sEvent, sDefEvent: "EVENT"
  of sState: "STATE"
  else: ""

proc undeclared(f: Fm, t: Tok) =
  if t.text in f.env.badExt: raise newException(Fail, f.env.badExt[t.text])
  if f.env.pnf.len > 0: raise newException(Fail, f.env.pnf)
  f.err(t, "E24", testo(kNomeNonDichiarato, t.text))

# 091:4:2 Controlli di tipo: l'espressione r deve essere di un tipo che la posizione accetta
proc tyErr(f: Fm, r: R, want: string) =
  f.err(r.tok, "E25", testo(kTipoIncoerenteServeTrovato, want, tyText(f.env, r.ty)))

proc needBool(f: Fm, r: R) =
  if r.bare:
    f.err(r.tok, "E24", testo(kInUnEntitaINomi, r.tok.text))
    return
  let x = unwrap(f.env, r.ty)
  if x.k notin {tUnk, tBool, tEvt}: tyErr(f, r, "Boolean")

proc needDur(f: Fm, r: R) =
  let x = unwrap(f.env, r.ty)
  if x.k notin {tUnk, tDur}: tyErr(f, r, "Duration")

proc needNum(f: Fm, r: R) =
  let x = unwrap(f.env, r.ty)
  if x.k notin {tUnk, tInt, tReal}: tyErr(f, r, testo(kUnNumero))

# 091:5:1 Espressioni (G59-G63)
proc parseEspr(f: Fm): R
proc parseEvent(f: Fm, withOk = true): Ty
proc parseProperty(f: Fm, top: bool): bool

proc litType(f: Fm, t: Tok): Ty =
  ## il tipo di un numero con l'eventuale unità che segue sulla stessa riga; consuma l'unità
  if f.has and f.cur.kind == tkWord and f.cur.text in ["s", "ms"] and f.cur.line == t.line:
    inc f.p
    return tyDur
  if '.' in t.text: tyReal else: tyInt

proc nameValue(f: Fm, t: Tok): R =
  ## un nome in posizione di valore o di condizione
  result = R(tok: t, ty: tyUnk, sym: "")
  f.atom t
  let sc = lookupScope(f, t.text)
  if sc != nil:
    result.ty = sc
    return
  let (ok, s) = symFor(f, t.text)
  if not ok:
    if f.env.isEntity:
      result.bare = true      # un nome semplice di entità: valore di una CSC citata, accettato senza controllo (4.9)
      return
    if t.text in f.env.exts and f.env.exts[t.text].kind == "FUNCTION":
      return
    undeclared(f, t)
    return
  result.sym = t.text
  case s.kind
  of sState:
    result.ty = s.ty
  of sDefine:
    if s.hasParams:
      f.err(t, "E24", testo(kNonEUnValore, t.text))
    else:
      f.refs.incl t.text
      result.ty = defTy(f, t.text)
  of sValue:
    result.ty = (if t.text in f.env.enumOf and f.env.enumOf[t.text] in f.env.types: f.env.types[f.env.enumOf[t.text]] else: tyUnk)
  of sEvent, sDefEvent:
    result.ty = tyEvt
    result.isEvt = true
    if s.kind == sDefEvent: f.dev.incl t.text
  of sCap:
    f.err(t, "E24", testo(kEUnaCAPABILITYSiNomina, t.text))
  of sExt:
    result.ty = tyUnk
  else:
    f.err(t, "E24", testo(kNonEUnValore, t.text))

proc extUse(f: Fm, nameTok: Tok, kindWanted: string, retTy: var Ty): bool

proc eventParams(f: Fm, name: string): seq[(string, Ty)] =
  let (ok, s) = symFor(f, name)
  if ok and s.kind in {sEvent, sCap}: s.params else: @[]

proc parseEvent(f: Fm, withOk = true): Ty =
  ## G62: RifEvento [WITH Espr]; restituisce un tipo Record con i parametri dell'evento (per LAST)
  var params: seq[(string, Ty)]
  var evName = ""
  if f.atS("("):
    inc f.p
    let inner = parseEvent(f)
    f.needS(")")
    params = inner.fields
    evName = inner.name
  elif f.has and f.cur.kind == tkWord and f.cur.text in CycleWords and f.nxt.kind == tkSym and f.nxt.text == "(":
    f.mk f.cur.text
    inc f.p
    inc f.p
    if not (f.has and isName(f.cur)): fail()
    let n = f.cur
    f.atom n
    inc f.p
    evName = n.text
    if f.atS(".") and f.nxt.kind == tkWord and f.nxt.line == n.line:
      # G62: Fase con il nome qualificato. In una CSC è E20 (4.12); in un'entità X è un connettore (4.9)
      inc f.p
      if not (f.has and isName(f.cur)): fail()
      let y = f.cur
      inc f.p
      if not f.env.isEntity:
        f.err(n, "E20", testo(kInUnaCSCINomi2, n.text, y.text))
      elif n.text notin f.env.conns:
        f.err(n, "E20", testo(kNonOffreNeUsaIl2, n.text, y.text, f.env.entName, n.text, f.env.entName))
      else:
        f.qrefs.add (n, y, "CAPABILITY")
    else:
      let (ok, s) = symFor(f, n.text)
      if not ok: undeclared(f, n)
      elif s.kind != sCap: f.err(n, "E24", testo(kNonEUnaCAPABILITY, n.text))
      else: params = s.params
    f.needS(")")
  elif f.has and isName(f.cur):
    let n = f.cur
    f.atom n
    inc f.p
    evName = n.text
    let (ok, s) = symFor(f, n.text)
    if f.env.isEntity and f.atS(".") and not ok:
      # entità: X.y, controllato dopo la ricerca
      inc f.p
      if not (f.has and isName(f.cur)): fail()
      f.qrefs.add (n, f.cur, "EVENT")
      inc f.p
    elif not ok:
      if f.env.isEntity:
        f.err(n, "E24", testo(kInUnEntitaINomi, n.text))
      else:
        undeclared(f, n)
    elif s.kind notin {sEvent, sDefEvent}:
      f.err(n, "E24", testo(kNonEUnEventoServe, n.text))
    else:
      params = s.params
      if s.kind == sDefEvent: f.dev.incl n.text
  else:
    fail()
  if withOk and f.atW("WITH"):
    f.mk "WITH"
    inc f.p
    var sc = initTable[string, Ty]()
    for (pn, pt) in params: sc[pn] = pt
    f.scopes.add sc
    let c = parseEspr(f)
    f.needBool(c)
    f.scopes.setLen(f.scopes.len - 1)
  Ty(k: tRec, name: evName, fields: params)

proc parseFinite(f: Fm, who: string): Ty =
  ## il nome di un tipo finito (FOR ALL i IN T, STATE x[T]); E29 se non è finito
  if not (f.has and f.cur.kind == tkWord): fail()
  let tn = f.cur
  inc f.p
  var ty: Ty
  if tn.text == "Boolean": ty = tyBool
  elif tn.text in f.env.types: ty = f.env.types[tn.text]
  else:
    if isName(tn): f.err(tn, "E29", testo(kIlTipoDellIndiceDi, who, tn.text))
    else: fail()
    return tyUnk
  if not finiteTy(f.env, ty):
    f.err(tn, "E29", testo(kIlTipoDellIndiceDi, who, tn.text))
  ty

proc checkIndex(f: Fm, r: R, idxTy: Ty, idxR: R) =
  ## E29: l'indice ha il tipo dell'indice dello stato
  let it = unwrap(f.env, idxTy)
  let ar = unwrap(f.env, idxR.ty)
  var bad = false
  if it.k == tUnk or ar.k == tUnk: bad = false
  elif it.k == tEnum: bad = not (ar.k == tEnum and ar.name == it.name)
  elif it.k == tBool: bad = ar.k != tBool
  elif it.k == tInt: bad = ar.k != tInt
  if bad:
    f.err(idxR.tok, "E29", testo(kIndiceDiNonDelTipo, r.sym, tyText(f.env, idxTy), idxR.tok.text))

proc parsePostfix(f: Fm, r0: R): R =
  var r = r0
  var indexed = ""      # il testo di x[i] dopo un indice su uno stato: un secondo indice è E29 (4.13)
  # indici e campi
  while true:
    if f.atS("["):
      f.mk "["
      let p0 = f.p
      let sym0 = r.sym
      inc f.p
      var i: R
      if f.has and isName(f.cur) and f.nxt.kind == tkSym and f.nxt.text == "]" and lookupScope(f, f.cur.text) == nil and
          f.cur.text notin f.env.syms and not f.env.isEntity:
        # un indice che non è niente nel blocco: non è del tipo dell'indice (E29), non un nome non dichiarato
        let (okS, sS) = symFor(f, r.sym)
        let tyT = if okS and sS.idx != nil: tyText(f.env, sS.idx) else: "?"
        f.err(f.cur, "E29", testo(kIndiceDiNonDelTipo, r.sym, tyT, f.cur.text))
        i = R(tok: f.cur, ty: tyUnk)
        inc f.p
        f.needS("]")
        r.sym = ""
        continue
      i = parseEspr(f)
      f.needS("]")
      let (ok, s) = symFor(f, r.sym)
      if indexed.len > 0:
        f.err(r.tok, "E29", testo(kNonHaIndice, indexed))
        indexed = ""
      elif r.sym.len > 0 and ok and s.kind == sState:
        if s.idx == nil: f.err(r.tok, "E29", testo(kNonHaIndice, r.sym))
        else:
          checkIndex(f, r, s.idx, i)
          var txt = sym0 & "["
          for q in f.t[p0 + 1 ..< f.p - 1]: txt.add q.text
          indexed = txt & "]"
        r.sym = ""
      elif r.sym.len > 0 and ok and s.kind == sExt: discard
      elif r.sym.len > 0:
        f.err(r.tok, "E29", testo(kNonHaIndice, r.sym))
      continue
    if f.atS(".") and f.nxt.kind == tkWord and not (f.env.isEntity and r.bare):
      indexed = ""
      inc f.p
      let c = f.cur
      if not isName(c): fail()
      f.mk "."
      f.atom c
      inc f.p
      let x = unwrap(f.env, r.ty)      # 4.13: fuori da =, <>, PRESENT un Optional T vale come T
      if x.k == tRec:
        var fnd = false
        for (fnm, ft) in x.fields:
          if fnm == c.text:
            r.ty = ft
            fnd = true
            break
        if not fnd:
          f.err(c, "E24", testo(kNomeNonDichiaratoComeCampo, tyText(f.env, x), c.text))
          r.ty = tyUnk
      elif x.k != tUnk:
        f.err(c, "E24", testo(kNomeNonDichiaratoComeCampo, tyText(f.env, x), c.text))
        r.ty = tyUnk
      r.sym = ""
      continue
    break
  # uno stato con indice scritto senza indice
  if r.sym.len > 0:
    let (ok, s) = symFor(f, r.sym)
    if ok and s.kind == sState and s.idx != nil and r0.sym == r.sym:
      f.err(r.tok, "E29", testo(kHaUnIndiceScriviValore, r.sym, r.sym, tyText(f.env, s.idx)))
  r.sym = ""
  r

proc parseCall(f: Fm, nameTok: Tok): R =
  ## G63: Nome "(" Nome ":" Espr { "," Nome ":" Espr } ")"
  f.mk nameTok.text
  let (ok, s) = symFor(f, nameTok.text)
  if not ok:
    undeclared(f, nameTok)
  elif s.kind != sDefine or not s.hasParams:
    f.err(nameTok, "E24", testo(kNonEUnaDEFINECon, nameTok.text))
  else:
    f.refs.incl nameTok.text
  inc f.p   # (
  var given = initHashSet[string]()
  var badParam = false
  while true:
    if not (f.has and isName(f.cur)): fail()
    let pn = f.cur
    inc f.p
    f.needS(":")
    let a = parseEspr(f)
    if ok and s.kind == sDefine and s.hasParams:
      var pt: Ty = nil
      for (n, t) in s.params:
        if n == pn.text: pt = t
      if pt == nil:
        f.err(pn, "E24", testo(kNomeNonDichiaratoComeParametro, nameTok.text, pn.text))
        badParam = true
      else:
        if pn.text in given: f.err(pn, "E01", testo(kNomeGiaUsatoAllaRiga, $pn.line, pn.text))
        # l'argomento ha il tipo del parametro
        let want = unwrap(f.env, pt)
        let got = unwrap(f.env, a.ty)
        var bad = false
        if want.k == tUnk or got.k == tUnk: bad = false
        elif want.k in {tInt, tReal}: bad = got.k notin {tInt, tReal}
        elif want.k == tEnum: bad = not (got.k == tEnum and got.name == want.name)
        else: bad = want.k != got.k and not (want.k == tBool and got.k == tEvt)
        if bad: f.err(a.tok, "E25", testo(kTipoIncoerenteServeTrovato, tyText(f.env, pt), tyText(f.env, a.ty)))
    given.incl pn.text
    if f.eatS(","): continue
    f.needS(")")
    break
  if ok and s.kind == sDefine and s.hasParams:
    for (n, t) in s.params:
      if n notin given and not badParam: f.err(nameTok, "E24", testo(kMancaLArgomentoNellaChiamata, n, nameTok.text))
  R(ty: (if ok and s.kind == sDefine: defTy(f, nameTok.text) else: tyUnk), tok: nameTok)

proc parseIfTerm(f: Fm, first: Tok): R =
  ## "(" IF Espr THEN Espr ELSE Espr ")" ; il "(" e IF sono già consumati
  f.mk "IF"
  let c = parseEspr(f)
  f.needBool(c)
  f.needW("THEN")
  let a = parseEspr(f)
  f.needW("ELSE")
  let b = parseEspr(f)
  f.needS(")")
  let ua = unwrap(f.env, a.ty)
  let ub = unwrap(f.env, b.ty)
  var ty = a.ty
  if ua.k == tUnk or ub.k == tUnk: ty = tyUnk
  elif ua.k in {tInt, tReal} and ub.k in {tInt, tReal}:
    ty = (if ua.k == tReal or ub.k == tReal: tyReal else: tyInt)
  elif ua.k != ub.k or (ua.k == tEnum and ua.name != ub.name):
    tyErr(f, b, tyText(f.env, a.ty))
  R(ty: ty, tok: first)

proc hasWithAtDepth1(f: Fm): bool =
  ## dopo "(": il contenuto, al primo livello, ha WITH?
  var d = 1
  var i = f.p
  while i < f.t.len:
    let x = f.t[i]
    if x.kind == tkSym and x.text == "(": inc d
    elif x.kind == tkSym and x.text == ")":
      dec d
      if d == 0: return false
    elif d == 1 and isW(x, "WITH"): return true
    inc i
  false

proc parsePrimary(f: Fm): R =
  if not f.has: fail()
  let t = f.cur
  case t.kind
  of tkNum:
    if not isNumTok(t): fail()
    inc f.p
    f.atom t
    return R(ty: litType(f, t), tok: t)
  of tkStr:
    if not t.closed: fail()
    inc f.p
    f.atom t
    return R(ty: tyStr, tok: t)
  of tkSym:
    if t.text == "(":
      inc f.p
      if f.atW("IF"):
        inc f.p
        return parseIfTerm(f, t)
      if hasWithAtDepth1(f):
        let ev = parseEvent(f)
        f.needS(")")
        discard ev
        return R(ty: tyEvt, tok: t, isEvt: true)
      let e = parseEspr(f)
      f.needS(")")
      var r = e
      r.tok = t
      return r
    fail()
  of tkWord:
    let w = t.text
    if w == "true" or w == "false":
      inc f.p
      f.atom t
      return R(ty: tyBool, tok: t)
    if w == "ABSENT":
      inc f.p
      f.atom t
      return R(ty: tyAbsent, tok: t)
    if w in FuncWords and f.nxt.kind == tkSym and f.nxt.text == "(":
      inc f.p
      inc f.p
      f.mk w
      var r: R
      if w in ["PREV", "CHANGED"]:
        # l'argomento è uno stato (anche con indice o campo)
        if not (f.has and isName(f.cur)): fail()
        let n = f.cur
        f.atom n
        let (ok, s) = symFor(f, n.text)
        let a = block:
          inc f.p
          var rr = R(tok: n, ty: tyUnk, sym: n.text)
          if not ok:
            if f.env.isEntity and f.atS("."):
              inc f.p
              if not (f.has and isName(f.cur)): fail()
              f.qrefs.add (n, f.cur, "STATE")
              inc f.p
            else: undeclared(f, n)
          elif s.kind != sState and s.kind != sExt:
            f.err(n, "E24", testo(kNonEUnoSTATE, n.text))
          else:
            rr.ty = s.ty
          rr
        let a2 = parsePostfix(f, a)
        f.needS(")")
        return R(ty: (if w == "PREV": a2.ty else: tyBool), tok: t)
      let a = parseEspr(f)
      f.needS(")")
      case w
      of "PRESENT":
        let x = resolveTy(f.env, a.ty)
        if x.k notin {tUnk, tOpt}: tyErr(f, a, "Optional")
        r = R(ty: tyBool, tok: t)
      of "ABS":
        let x = unwrap(f.env, a.ty)
        if x.k notin {tUnk, tInt, tReal, tDur}: tyErr(f, a, testo(kUnNumeroOUnaDurata))
        r = R(ty: (if x.k == tUnk: tyUnk else: a.ty), tok: t)
      of "LOG10":
        needNum(f, a)
        r = R(ty: tyReal, tok: t)
      else:
        needNum(f, a)
        r = R(ty: tyInt, tok: t)
      return r
    if (w == "MIN" or w == "MAX") and f.nxt.kind == tkSym and f.nxt.text == "(":
      inc f.p
      inc f.p
      f.mk w
      var ty: Ty = nil
      var firstK = tUnk           # tInt/tReal (un numero) o tDur: il genere del primo argomento noto
      var anyUnk = false
      var nArgs = 0
      while true:
        let a = parseEspr(f)
        inc nArgs
        let x = unwrap(f.env, a.ty)
        if x.k == tUnk: anyUnk = true
        elif x.k notin {tInt, tReal, tDur}:
          tyErr(f, a, testo(kUnNumeroOUnaDurata))
        elif firstK == tUnk: firstK = x.k
        elif (firstK == tDur) != (x.k == tDur):
          # 4.13: tutti numeri o tutti durate (E25 sull'argomento che non è del genere del primo)
          tyErr(f, a, (if firstK == tDur: "Duration" else: testo(kUnNumero)))
        if ty == nil: ty = a.ty
        elif x.k == tReal: ty = tyReal
        if f.eatS(","): continue
        break
      if nArgs < 2: fail()       # G60: MIN e MAX vogliono almeno due argomenti
      f.needS(")")
      return R(ty: (if anyUnk or ty == nil: tyUnk else: ty), tok: t)
    if w == "COUNT" and f.nxt.kind == tkSym and f.nxt.text == "(":
      f.mk "COUNT"
      inc f.p
      inc f.p
      discard parseEvent(f)
      if f.eatW("SINCE"): discard parseEvent(f)
      f.needS(")")
      if f.atW("IN") and f.nxt.kind == tkWord and f.nxt.text == "LAST":
        inc f.p
        inc f.p
        let d = parsePostfix(f, parsePrimary(f))
        needDur(f, d)
      return R(ty: tyInt, tok: t)
    if w == "TIME" and f.nxt.kind == tkWord and f.nxt.text == "SINCE":
      f.mk "TIME"
      inc f.p
      inc f.p
      discard parseEvent(f)
      return R(ty: tyDur, tok: t)
    if w == "LAST" and f.nxt.kind == tkSym and f.nxt.text == "(":
      f.mk "LAST"
      inc f.p
      inc f.p
      let ev = parseEvent(f)
      f.needS(")")
      return R(ty: ev, tok: t)
    if w == "ONCE":
      f.mk "ONCE"
      inc f.p
      discard parseEvent(f)
      return R(ty: tyBool, tok: t)
    if w in CycleWords and f.nxt.kind == tkSym and f.nxt.text == "(":
      discard parseEvent(f, false)      # G62: dopo una fase WITH sta solo dove sta un evento o fra parentesi
      return R(ty: tyBool, tok: t, isEvt: true)
    if w in PatternWords:
      # E27: un pattern dentro un'altra forma
      f.err(t, "E27", testo(kDentroUnAltraFormaIl, w))
      discard parseProperty(f, false)
      return R(ty: tyBool, tok: t)
    if isName(t):
      # chiamata, estensione di KIND FUNCTION, nome semplice
      if f.nxt.kind == tkSym and f.nxt.text == "(" and f.p + 3 < f.t.len and isName(f.t[f.p + 2]) and
          f.t[f.p + 3].kind == tkSym and f.t[f.p + 3].text == ":" and lookupScope(f, w) == nil:
        inc f.p
        return parsePostfix(f, parseCall(f, t))
      if w in f.env.exts and lookupScope(f, w) == nil and w notin f.env.syms:
        let ex = f.env.exts[w]
        if ex.kind == "FUNCTION":
          inc f.p
          var rt: Ty = tyUnk
          discard extUse(f, t, "FUNCTION", rt)
          return R(ty: rt, tok: t)
        # E37: un'estensione in una posizione che il suo KIND non prevede
        f.err(t, "E37", testo(kHaKINDNonSiUsa, w, ex.kind))
        inc f.p
        if f.atS("("):
          var d = 0
          while f.has:
            if f.atS("("): inc d
            elif f.atS(")"): dec d
            inc f.p
            if d == 0: break
        return R(ty: tyUnk, tok: t)
      if f.env.isEntity and f.nxt.kind == tkSym and f.nxt.text == "." and lookupScope(f, w) == nil and
          f.nxt.line == t.line and f.p + 2 < f.t.len and isName(f.t[f.p + 2]):
        # X.y: nome qualificato d'entità; si controlla dopo la ricerca
        inc f.p
        inc f.p
        let y = f.cur
        inc f.p
        if w notin f.env.conns:
          f.err(t, "E20", testo(kNonOffreNeUsaIl2, w, y.text, f.env.entName, w, f.env.entName))
        else:
          f.qrefs.add (t, y, "")
        return R(ty: tyUnk, tok: t)
      inc f.p
      var r = nameValue(f, t)
      return parsePostfix(f, r)
    fail()
  else:
    fail()

proc parsePow(f: Fm): R =
  var a = parsePostfix(f, block:
    let r = parsePrimary(f)
    r)
  if f.atS("^"):
    let op = f.cur
    discard op
    inc f.p
    f.mk "^"
    let b = parsePostfix(f, parsePrimary(f))
    needNum(f, a)
    needNum(f, b)
    a = R(ty: tyReal, tok: a.tok)
    if f.atS("^"):
      f.err(f.cur, "E26", testo(kDopoSenzaParentesiScriviA))
      while f.atS("^"):
        inc f.p
        discard parsePostfix(f, parsePrimary(f))
  a

proc parseMinus(f: Fm): R =
  if f.atS("-"):
    let t = f.cur
    inc f.p
    f.mk "-"
    let a = parseMinus(f)
    let x = unwrap(f.env, a.ty)
    if x.k notin {tUnk, tInt, tReal, tDur}: tyErr(f, a, testo(kUnNumeroOUnaDurata))
    return R(ty: a.ty, tok: t)
  parsePow(f)

proc arith(f: Fm, op: string, a, b: R): R =
  f.mk op
  let x = unwrap(f.env, a.ty)
  let y = unwrap(f.env, b.ty)
  result = R(tok: a.tok, ty: tyUnk)
  if x.k == tUnk or y.k == tUnk:
    # il risultato di un'operazione su un tipo non noto è non noto
    for q in [(x, a), (y, b)]:
      if q[0].k notin {tUnk, tInt, tReal, tDur}: tyErr(f, q[1], testo(kUnNumeroOUnaDurata))
    return
  let nx = x.k in {tInt, tReal}
  let ny = y.k in {tInt, tReal}
  case op
  of "+", "-":
    if nx and ny: result.ty = (if x.k == tInt and y.k == tInt: tyInt else: tyReal)
    elif x.k == tDur and y.k == tDur: result.ty = tyDur
    elif x.k == tDur and ny: tyErr(f, b, "Duration")
    elif nx and y.k == tDur: tyErr(f, b, testo(kUnNumero))
    elif x.k notin {tInt, tReal, tDur}: tyErr(f, a, testo(kUnNumeroOUnaDurata))
    else: tyErr(f, b, testo(kUnNumeroOUnaDurata))
  of "*":
    if nx and ny: result.ty = (if x.k == tInt and y.k == tInt: tyInt else: tyReal)
    elif x.k == tDur and ny or nx and y.k == tDur: result.ty = tyDur
    elif x.k == tDur and y.k == tDur: tyErr(f, b, testo(kUnNumero))
    elif x.k notin {tInt, tReal, tDur}: tyErr(f, a, testo(kUnNumeroOUnaDurata))
    else: tyErr(f, b, testo(kUnNumeroOUnaDurata))
  else:
    if nx and ny: result.ty = tyReal
    elif x.k == tDur and ny: result.ty = tyDur
    elif x.k == tDur and y.k == tDur: result.ty = tyReal
    elif nx and y.k == tDur: tyErr(f, b, testo(kUnNumero))
    elif x.k notin {tInt, tReal, tDur}: tyErr(f, a, testo(kUnNumeroOUnaDurata))
    else: tyErr(f, b, testo(kUnNumeroOUnaDurata))

proc parseProd(f: Fm): R =
  var a = parseMinus(f)
  while f.atS("*") or f.atS("/"):
    let op = f.cur.text
    inc f.p
    let b = parseMinus(f)
    a = arith(f, op, a, b)
  a

proc parseSum(f: Fm): R =
  var a = parseProd(f)
  while f.atS("+") or f.atS("-"):
    let op = f.cur.text
    inc f.p
    let b = parseProd(f)
    a = arith(f, op, a, b)
  a

proc cmpCompat(f: Fm, op: string, a, b: R) =
  let x = unwrap(f.env, a.ty)
  let y = unwrap(f.env, b.ty)
  if x.k == tUnk or y.k == tUnk: return
  if a.bare or b.bare: return
  if op in ["=", "<>"]:
    # Optional T con T o con ABSENT
    let ra = resolveTy(f.env, a.ty)
    let rb = resolveTy(f.env, b.ty)
    if ra.k == tAbsent or rb.k == tAbsent:
      if not (ra.k == tOpt or rb.k == tOpt or ra.k == tAbsent and rb.k == tAbsent):
        tyErr(f, b, "Optional")
      return
    let bothNum = x.k in {tInt, tReal} and y.k in {tInt, tReal}
    let evtBool = (x.k == tEvt and y.k == tBool) or (x.k == tBool and y.k == tEvt) or (x.k == tEvt and y.k == tEvt)
    if bothNum or evtBool: return
    if x.k != y.k or (x.k == tEnum and x.name != y.name):
      tyErr(f, b, tyText(f.env, a.ty))
  else:
    let ok = (x.k in {tInt, tReal} and y.k in {tInt, tReal}) or (x.k == tDur and y.k == tDur)
    if not ok:
      if x.k notin {tInt, tReal, tDur}: tyErr(f, a, testo(kUnNumeroOUnaDurata))
      elif x.k == tDur: tyErr(f, b, "Duration")
      else: tyErr(f, b, testo(kUnNumero))

proc parseCmp(f: Fm): R =
  let a = parseSum(f)
  if f.has and f.cur.kind == tkSym and f.cur.text in CmpOps:
    let op = f.cur.text
    inc f.p
    f.mk op
    let b = parseSum(f)
    cmpCompat(f, op, a, b)
    if f.has and f.cur.kind == tkSym and f.cur.text in CmpOps:
      f.err(f.cur, "E26", testo(kConfrontiInCatenaScriviA))
      while f.has and f.cur.kind == tkSym and f.cur.text in CmpOps:
        inc f.p
        discard parseSum(f)
    return R(ty: tyBool, tok: a.tok)
  if f.atW("IN") and f.nxt.kind == tkSym and f.nxt.text == "{":
    inc f.p
    inc f.p
    f.mk "IN"
    while true:
      if not f.has: fail()
      let v = f.cur
      var vt: seq[Tok] = @[v]
      case v.kind
      of tkStr, tkNum: inc f.p
      of tkWord:
        if v.text in ["true", "false", "ABSENT"] or isName(v): inc f.p
        else: fail()
      else: fail()
      if v.kind == tkNum and f.has and f.cur.kind == tkWord and f.cur.text in ["s", "ms"] and f.cur.line == v.line:
        vt.add f.cur
        inc f.p
      if v.kind == tkWord and isName(v) and v.text notin f.env.enumOf and f.env.pnf.len == 0 and not f.env.isEntity:
        f.err(v, "E24", testo(kNomeNonDichiarato, v.text))
      elif not valueOk(f.env, a.ty, vt) and not a.bare and not f.env.isEntity:
        f.err(v, "E25", testo(kTipoIncoerenteServeTrovato, tyText(f.env, a.ty), (case v.kind
           of tkStr: "String"
           of tkNum: (if vt.len > 1: "Duration" elif '.' in v.text: "Real" else: "Integer")
           else:
             (if v.text in ["true", "false"]: "Boolean"
              elif v.text == "ABSENT": "Optional"
              elif v.text in f.env.enumOf: f.env.enumOf[v.text]
              else: "?"))))
      if f.eatS(","): continue
      break
    f.needS("}")
    return R(ty: tyBool, tok: a.tok)
  a

proc parseNeg(f: Fm): R =
  if f.atW("NOT"):
    let t = f.cur
    inc f.p
    f.mk "NOT"
    let a = parseNeg(f)
    f.needBool(a)
    return R(ty: tyBool, tok: t)
  parseCmp(f)

proc parseLogic(f: Fm): R =
  var a = parseNeg(f)
  var op = ""
  while f.atW("AND") or f.atW("OR"):
    let o = f.cur
    if op.len == 0: op = o.text
    elif op != o.text:
      f.err(o, "E26", testo(kANDEORInsiemeSenza))
      op = "!"   # un solo errore per catena
    f.mk o.text
    inc f.p
    let b = parseNeg(f)
    f.needBool(a)
    f.needBool(b)
    a = R(ty: tyBool, tok: a.tok)
  a

proc parseImpl(f: Fm): R =
  var a = parseLogic(f)
  if f.atW("IMPLIES"):
    inc f.p
    f.mk "IMPLIES"
    let b = parseLogic(f)
    f.needBool(a)
    f.needBool(b)
    a = R(ty: tyBool, tok: a.tok)
    while f.atW("IMPLIES"):
      f.err(f.cur, "E26", testo(kIMPLIESDopoIMPLIESSenzaParentesi))
      inc f.p
      discard parseLogic(f)
  a

proc parseQuant(f: Fm): Ty =
  ## FOR ALL Nome IN Nome ":"  -> apre uno scope con la variabile (da chiudere)
  f.needW("FOR")
  f.needW("ALL")
  f.mk "FOR ALL"
  if not (f.has and isName(f.cur)): fail()
  let v = f.cur
  f.atom v
  inc f.p
  f.needW("IN")
  let ty = parseFinite(f, v.text)
  f.needS(":")
  if v.text in f.env.syms:
    f.err(v, "E01", testo(kNomeGiaUsatoAllaRiga, $f.env.syms[v.text].line, v.text))
  var sc = initTable[string, Ty]()
  sc[v.text] = ty
  f.scopes.add sc
  ty

proc parseEspr(f: Fm): R =
  if f.atW("FOR") and f.nxt.kind == tkWord and f.nxt.text == "ALL":
    discard parseQuant(f)
    let r = parseEspr(f)
    f.scopes.setLen(f.scopes.len - 1)
    return r
  parseImpl(f)

# 091:6:1 Proprietà (G55-G58)
proc parseTransition(f: Fm) =
  ## TRANSITION Nome ":" Transizione { "," Transizione }
  if not (f.has and isName(f.cur)): fail()
  let sn = f.cur
  f.atom sn
  inc f.p
  let (ok, s) = symFor(f, sn.text)
  var enumTy: Ty = tyUnk
  if not ok:
    undeclared(f, sn)
  elif s.kind != sState:
    f.err(sn, "E24", testo(kNonEUnoSTATE, sn.text))
  else:
    enumTy = s.ty
    let x = unwrap(f.env, s.ty)
    if x.k != tEnum and x.k != tUnk:
      f.err(sn, "E25", testo(kTipoIncoerenteServeUnElenco, tyText(f.env, s.ty)))
  f.needS(":")
  while true:
    var vals: seq[Tok]
    for k in 0 .. 1:
      if not (f.has and isName(f.cur)): fail()
      vals.add f.cur
      f.atom f.cur
      inc f.p
      if k == 0: f.needS("->")
    let ex = unwrap(f.env, enumTy)
    if ex.k == tEnum:
      for v in vals:
        if v.text notin ex.values:
          if v.text in f.env.enumOf:
            f.err(v, "E25", testo(kTipoIncoerenteServeTrovato, ex.name, f.env.enumOf[v.text]))
          elif v.text in f.env.syms:
            let sv = f.env.syms[v.text]
            if sv.kind == sState and sv.ty != nil and unwrap(f.env, sv.ty).k != tUnk:
              f.err(v, "E25", testo(kTipoIncoerenteServeTrovato, ex.name, tyText(f.env, sv.ty)))
            elif sv.kind != sState:
              f.err(v, "E24", testo(kNonEUnValore, v.text))
          elif not f.env.isEntity:
            undeclared(f, v)
    f.needW("ON")
    discard parseEvent(f)
    if f.eatW("WHEN"):
      let c = parseEspr(f)
      f.needBool(c)
    if f.eatS(","): continue
    break

proc parseScope(f: Fm): bool =
  ## G56; true se ha letto un ambito (":" compreso)
  if f.atW("WHILE"):
    inc f.p
    f.mk "WHILE"
    let c = parseEspr(f)
    f.needBool(c)
    f.needS(":")
    return true
  if f.atW("AFTER"):
    inc f.p
    f.mk "AFTER"
    discard parseEvent(f)
    if f.eatW("UNTIL"): discard parseEvent(f)
    f.needS(":")
    return true
  if f.atW("BEFORE"):
    inc f.p
    f.mk "BEFORE"
    discard parseEvent(f)
    f.needS(":")
    return true
  if f.atW("BETWEEN"):
    inc f.p
    f.mk "BETWEEN"
    discard parseEvent(f)
    f.needW("AND")
    discard parseEvent(f)
    f.needS(":")
    return true
  false

proc parseProperty(f: Fm, top: bool): bool =
  ## G55. true se ha letto una proprietà intera; i tentativi sbagliati sollevano Fail.
  while f.atW("FOR") and f.nxt.kind == tkWord and f.nxt.text == "ALL":
    discard parseQuant(f)
  var nScopes = 0
  var extScope = false
  while true:
    if f.has and f.cur.kind == tkWord and f.cur.text in ScopeWords:
      if nScopes > 0:
        f.err(f.cur, "E27", testo(kUnaProprietaHaUnSolo, f.cur.text))
      discard parseScope(f)
      inc nScopes
      continue
    # estensione di KIND SCOPE
    if f.has and isName(f.cur) and f.cur.text in f.env.exts and f.env.exts[f.cur.text].kind == "SCOPE" and
        f.cur.text notin f.env.syms:
      let nt = f.cur
      inc f.p
      var rt: Ty
      discard extUse(f, nt, "SCOPE", rt)
      f.needS(":")
      if nScopes > 0: f.err(nt, "E27", testo(kUnaProprietaHaUnSolo, nt.text))
      inc nScopes
      extScope = true
      continue
    break
  if not f.has: fail()
  let t = f.cur
  if isName(t) and t.text in f.propParams:
    f.atom t
    inc f.p            # 4.11: un parametro di categoria Property sta dove sta una proprietà intera
    return true
  if t.kind == tkWord and t.text in PatternWords: f.mk t.text
  if t.kind == tkWord:
    case t.text
    of "ALWAYS":
      inc f.p
      let c = parseEspr(f)
      f.needBool(c)
      return true
    of "EVENTUALLY":
      inc f.p
      let c = parseEspr(f)
      f.needBool(c)
      if f.eatW("WITHIN"):
        let d = parseEspr(f)
        needDur(f, d)
      return true
    of "WHENEVER":
      inc f.p
      let c = parseEspr(f)
      f.needBool(c)
      f.needW("THEN")
      let q = parseEspr(f)
      f.needBool(q)
      if f.eatW("WITHIN"):
        let d = parseEspr(f)
        needDur(f, d)
        if f.atW("AT") and f.nxt.kind == tkWord and f.nxt.text == "ONCE":
          f.err(f.cur, "E27", testo(kWITHINEATONCENella))
          inc f.p
          inc f.p
      elif f.atW("AT") and f.nxt.kind == tkWord and f.nxt.text == "ONCE":
        inc f.p
        inc f.p
      return true
    of "NEVER":
      inc f.p
      let c = parseEspr(f)
      f.needBool(c)
      return true
    of "ACCEPTS":
      inc f.p
      if not (f.has and isName(f.cur)): fail()
      let n = f.cur
      f.atom n
      inc f.p
      let (ok, s) = symFor(f, n.text)
      if not ok: undeclared(f, n)
      elif s.kind != sCap: f.err(n, "E24", testo(kNonEUnaCAPABILITY, n.text))
      f.needW("ONLY")
      f.needW("WHILE")
      let c = parseEspr(f)
      f.needBool(c)
      return true
    of "RESOLVES":
      inc f.p
      if not (f.has and isName(f.cur)): fail()
      let n = f.cur
      f.atom n
      inc f.p
      let (ok, s) = symFor(f, n.text)
      if not ok: undeclared(f, n)
      elif s.kind != sCap: f.err(n, "E24", testo(kNonEUnaCAPABILITY, n.text))
      f.needW("WITHIN")
      let d = parseEspr(f)
      needDur(f, d)
      return true
    of "TRANSITION":
      inc f.p
      parseTransition(f)
      return true
    else: discard
  # estensione di KIND PATTERN
  if isName(t) and t.text in f.env.exts and f.env.exts[t.text].kind == "PATTERN" and t.text notin f.env.syms and
      lookupScope(f, t.text) == nil:
    inc f.p
    var rt: Ty
    discard extUse(f, t, "PATTERN", rt)
    return true
  # Nome REQUIRES/ENSURES Espr
  if isName(t) and f.nxt.kind == tkWord and f.nxt.text in ["REQUIRES", "ENSURES"]:
    let n = t
    f.atom n
    inc f.p
    let kw = f.cur
    f.mk kw.text
    inc f.p
    let (ok, s) = symFor(f, n.text)
    if not ok: undeclared(f, n)
    elif s.kind != sCap: f.err(n, "E24", testo(kNonEUnaCAPABILITY, n.text))
    let c = parseEspr(f)
    f.needBool(c)
    if kw.text == "REQUIRES" and not f.env.isAssume:
      f.err(kw, "E27", testo(kREQUIRESStaSoloInUna))
    return true
  # Espr PRECEDES Espr / Espr FOR AT LEAST Espr
  let a = parseEspr(f)
  if f.atW("PRECEDES"):
    f.mk "PRECEDES"
    inc f.p
    let b = parseEspr(f)
    f.needBool(a)
    f.needBool(b)
    return true
  if f.atW("FOR") and f.nxt.kind == tkWord and f.nxt.text == "AT":
    f.mk "FOR AT LEAST"
    inc f.p
    inc f.p
    f.needW("LEAST")
    let d = parseEspr(f)
    f.needBool(a)
    needDur(f, d)
    return true
  fail()

# 091:7:1 Uso di un'estensione (sezione 4.14)
proc sliceEnd(f: Fm, stopText: string): int =
  ## fine dell'argomento: dal posto corrente fino al primo elemento fisso `stopText` a profondità 0, o alla fine della posizione
  var d = 0
  var i = f.p
  while i < f.t.len:
    let x = f.t[i]
    if d == 0 and stopText.len > 0 and x.text == stopText and x.kind != tkStr: return i
    if x.kind == tkSym and x.text in ["(", "[", "{"]: inc d
    elif x.kind == tkSym and x.text in [")", "]", "}"]:
      if d == 0: return i
      dec d
    elif d == 0:
      if stopText.len > 0 and x.text == stopText: return i
      if stopText.len == 0 and ((x.kind == tkSym and x.text in [",", ":"]) or (x.kind == tkWord and x.text in ["THEN"])): return i
    inc i
  i

proc subCheck(f: Fm, a, b: int, cat: string, pty: Ty): bool =
  ## legge f.t[a ..< b] secondo la categoria; false se non rispetta la forma
  if a >= b: return false
  var g = Fm(env: f.env, t: f.t[a ..< b], p: 0, scopes: f.scopes, errs: @[], refs: f.refs, used: f.used, qrefs: @[],
    trace: f.trace, propParams: f.propParams)
  var ok = true
  try:
    case cat
    of "Name":
      if b - a != 1 or not isName(f.t[a]): return false
      f.atom f.t[a]
      let (found, s) = symFor(f, f.t[a].text)
      if not found and lookupScope(f, f.t[a].text) == nil: undeclared(f, f.t[a])
      elif found and s.kind in {sType, sRow, sScn, sPart}: f.err(f.t[a], "E24", testo(kNonEUnValore, f.t[a].text))
      return true
    of "Type":
      var u: seq[Tok]
      var p = 0
      let ty = readTy(g.t, p, u)
      for q in g.t: f.atom q
      return ty != nil and p == g.t.len
    of "Event":
      discard parseEvent(g)
    of "Condition":
      let r = parseEspr(g)
      g.needBool(r)
    of "Duration":
      let r = parseEspr(g)
      needDur(g, r)
    of "Property":
      discard parseProperty(g, false)
    of "Expression":
      discard parseEspr(g)
    else:
      let r = parseEspr(g)
      if pty != nil:
        let want = unwrap(f.env, pty)
        let got = unwrap(f.env, r.ty)
        if want.k != tUnk and got.k != tUnk and not ((want.k in {tInt, tReal} and got.k in {tInt, tReal}) or
            (want.k == got.k and (want.k != tEnum or want.name == got.name))):
          tyErr(g, r, tyText(f.env, pty))
    if g.p != g.t.len: ok = false
  except Fail:
    ok = false
  if ok:
    for e in g.errs: f.errs.add e
    for r in g.refs: f.refs.incl r
    for r in g.used: f.used.incl r
    for q in g.qrefs: f.qrefs.add q
    # G-16: gli usi dentro l'argomento di un altro uso contano per il grado e per la sezione 15
    for x in g.exts: f.exts.add x
    if g.extNoRed: f.extNoRed = true
    for r in g.dev: f.dev.incl r
    for x in g.marks: f.marks.add x
    for x in g.atoms: f.atoms.add x
  ok

proc extUse(f: Fm, nameTok: Tok, kindWanted: string, retTy: var Ty): bool =
  ## Il nome è già consumato. Legge gli argomenti secondo il FORM; un uso che non lo rispetta è E37 e consuma il resto.
  let ex = f.env.exts[nameTok.text]
  f.exts.add nameTok.text
  f.mk nameTok.text
  if not ex.hasRed: f.extNoRed = true
  retTy = (if ex.result != nil: ex.result else: tyUnk)
  if ex.level != f.env.blockLevel:
    f.err(nameTok, "E37", testo(kHaLEVELNonSiUsa, nameTok.text, ex.level, f.env.blockLevel))
  var ok = true
  var i = 1
  while i < ex.form.len and ok:
    let el = ex.form[i]
    var spec = -1
    for k, ps in ex.params:
      if ps.name == el.text and el.kind == tkWord and not isUnitAt(ex.form, i): spec = k
    if spec < 0:
      if f.has and f.cur.text == el.text: inc f.p
      else: ok = false
      inc i
    else:
      var stop = ""
      if i + 1 < ex.form.len:
        var nextIsParam = false
        for ps in ex.params:
          if ps.name == ex.form[i + 1].text: nextIsParam = true
        if not nextIsParam: stop = ex.form[i + 1].text
      let e = sliceEnd(f, stop)
      if f.declMode and f.declName.text.len == 0 and ex.params[spec].cat == "Name":
        # 4.14: in un uso di KIND DECLARATION il primo posto Name è il nome dichiarato dalla riga
        if e == f.p + 1 and isName(f.cur):
          f.declName = f.cur
          f.p = e
        else: ok = false
      elif e <= f.p or not subCheck(f, f.p, e, ex.params[spec].cat, ex.params[spec].ty): ok = false
      else: f.p = e
      inc i
  if not ok:
    f.errForm(nameTok, testo(kUsoDiCheNonRispetta, nameTok.text, ex.formText))
    f.p = f.t.len
  true

# 091:8:1 Tipo di una DEFINE
proc defTy(f: Fm, name: string): Ty =
  let env = f.env
  if name in env.defTys: return env.defTys[name]
  if name in env.defBusy or name notin env.defToks: return tyUnk
  let (ok, s) = symFor(f, name)
  if not ok or s.undecided: return tyUnk
  env.defBusy.incl name
  var g = Fm(env: env, t: env.defToks[name], p: 0, errs: @[], refs: initHashSet[string]())
  var sc = initTable[string, Ty]()
  for (n, t) in s.params: sc[n] = t
  g.scopes.add sc
  var ty = tyUnk
  try:
    let r = parseEspr(g)
    if g.p == g.t.len: ty = r.ty
  except Fail:
    discard
  env.defBusy.excl name
  env.defTys[name] = ty
  ty

# 091:9:1 Interfaccia: formula (G55) o espressione (G59) per intero
type
  FRes* = object
    ok*: bool                   # letta per intero
    errs*: seq[FErr]
    motive*: string             # se non letta per un profilo non trovato
    usesExt*, extNoRed*: bool
    extNames*: seq[string]
    refs*: HashSet[string]
    devRefs*: HashSet[string]
    used*: HashSet[string]
    qrefs*: seq[(Tok, Tok, string)]

proc runFm(env: Env, toks: seq[Tok], scope: Table[string, Ty], prop: bool, eventDef: bool, level: string, assume = false): FRes =
  var f = Fm(env: env, t: toks, p: 0, errs: @[], refs: initHashSet[string](), used: initHashSet[string]())
  f.scopes.add scope
  env.blockLevel = level
  env.isAssume = assume
  try:
    if prop:
      discard parseProperty(f, true)
    else:
      let r = parseEspr(f)
      if eventDef: f.needBool(r)
    result.ok = f.p == f.t.len
  except Fail as e:
    result.ok = false
    result.motive = e.msg
  if result.ok:
    result.errs = f.errs
    # un errore di forma (E26, E27) si porta dietro errori di tipo a cascata: si dà solo il primo
    var shape = false
    for e in f.errs:
      if e.code in ["E26", "E27"]: shape = true
    if shape:
      result.errs = @[]
      for e in f.errs:
        if e.code != "E25": result.errs.add e
    result.usesExt = f.exts.len > 0
    result.extNames = f.exts
    result.extNoRed = f.extNoRed
    result.refs = f.refs
    result.devRefs = f.dev
    result.used = f.used
    result.qrefs = f.qrefs
  else:
    result.errs = @[]

proc checkProperty*(env: Env, toks: seq[Tok], isAssume: bool): FRes =
  runFm(env, toks, initTable[string, Ty](), true, false, (if env.isEntity: "ENTITY" else: env.blockLevel), isAssume)

proc checkExpr*(env: Env, toks: seq[Tok], params: seq[(string, Ty)], mustBool: bool): FRes =
  var sc = initTable[string, Ty]()
  for (n, t) in params: sc[n] = t
  runFm(env, toks, sc, false, mustBool, (if env.isEntity: "ENTITY" else: env.blockLevel))

# 091:10:1 (1.0-beta, G-13, P5) La lettura di una REDUCES TO (sezione 4.11): la riduzione è una forma che il lettore delle formule accetta
proc readReduction*(exts: Table[string, ExtDef], kind, level: string, params: seq[ParamSpec], toks: seq[Tok],
    label: var string, pure: var bool): bool =
  ## 091:10:2 Vero se `toks` è letta per intero secondo il KIND (G55 per PATTERN, DECLARATION, RELATION; G56 per SCOPE; G59 per FUNCTION)
  ## con i parametri al posto di nomi, eventi, espressioni o proprietà. I nomi non si controllano (E35 lo fa a parte) e i tipi
  ## nemmeno; una forma sbagliata (E26, E27, E37) vale come non letta. SCENARIO-FORM si legge altrove (elementi di passo).
  if toks.len == 0: return false
  let env = newEnv()
  env.exts = exts
  env.blockLevel = level
  env.isAssume = true       # G-18: `x REQUIRES q` si legge in una riduzione; E27 vale per le GUARANTEE
  var f = Fm(env: env, t: toks, p: 0, errs: @[], refs: initHashSet[string](), used: initHashSet[string](), propParams: initHashSet[string](),
    trace: true)
  label = ""
  pure = false
  var sc = initTable[string, Ty]()
  for ps in params:
    sc[ps.name] = tyUnk
    if ps.cat == "Property": f.propParams.incl ps.name
  f.scopes.add sc
  try:
    case kind
    of "SCOPE":
      let last = toks[^1]
      f.t.add Tok(kind: tkSym, text: ":", line: last.line, col: last.col + last.text.len, endLine: last.line)
      if not parseScope(f):
        # un solo uso di un'altra estensione di KIND SCOPE
        if not (f.has and isName(f.cur) and f.cur.text in exts and exts[f.cur.text].kind == "SCOPE"): return false
        let nt = f.cur
        inc f.p
        var rt: Ty
        discard extUse(f, nt, "SCOPE", rt)
        f.needS(":")
      if f.p != f.t.len: return false
    of "FUNCTION":
      discard parseEspr(f)
      if f.p != f.t.len: return false
    else:
      discard parseProperty(f, true)
      if f.p != f.t.len: return false
  except Fail:
    return false
  for e in f.errs:
    if e.code in ["E26", "E27", "E37"]: return false
  # E36 (4.11): un solo costrutto, i cui operandi sono tutti parametri, ciascuno una volta
  if f.marks.len == 1 and params.len > 0:
    var seen = initHashSet[string]()
    var all = true
    for a in f.atoms:
      if a.kind != tkWord or a.text notin sc or a.text in seen: all = false
      seen.incl a.text
    if all and seen.len == params.len:
      pure = true
      label = f.marks[0]
  true

# 091:11:1 (1.0-beta, P1-a, G-12) Gli usi di KIND DECLARATION (sezione 4.14)
type
  DeclUse* = object
    isUse*: bool                # la riga comincia con un'estensione di KIND DECLARATION (o con una di un altro KIND: E37) letta come uso
    hasName*: bool              # il FORM è stato letto fino al nome dichiarato
    name*: Tok
    errs*: seq[FErr]

proc declUse*(env: Env, toks: seq[Tok]): DeclUse =
  ## 091:11:2 Una dichiarazione non riconosciuta dal blocco, la cui prima parola è il nome di un'estensione dei profili importati e trovati.
  ## KIND DECLARATION: si legge secondo il FORM (E37 se non lo rispetta o se il LEVEL non è del blocco); KIND PATTERN, SCOPE e
  ## FUNCTION: E37 per la posizione. RELATION e SCENARIO-FORM non si leggono in questa versione: la riga resta non riconosciuta.
  if toks.len == 0 or toks[0].kind != tkWord or toks[0].text notin env.exts or toks[0].text in env.syms: return
  let ex = env.exts[toks[0].text]
  var f = Fm(env: env, t: toks, p: 1, errs: @[], refs: initHashSet[string](), used: initHashSet[string](), declMode: true,
    propParams: initHashSet[string]())
  f.scopes.add initTable[string, Ty]()
  case ex.kind
  of "DECLARATION":
    result.isUse = true
    var rt: Ty
    try:
      discard extUse(f, toks[0], "DECLARATION", rt)
      if f.p < f.t.len and f.errs.len == 0:
        f.errForm(toks[0], testo(kUsoDiCheNonRispetta, toks[0].text, ex.formText))
    except Fail:
      f.errForm(toks[0], testo(kUsoDiCheNonRispetta, toks[0].text, ex.formText))
    result.errs = f.errs
    var formErr = false
    for e in f.errs:
      if e.code == "E37" and e.form: formErr = true
    if not formErr and f.declName.text.len > 0:
      result.hasName = true
      result.name = f.declName
  of "PATTERN", "SCOPE", "FUNCTION":
    result.isUse = true
    f.err(toks[0], "E37", testo(kHaKINDNonSiUsa, toks[0].text, ex.kind))
    result.errs = f.errs
  else: discard

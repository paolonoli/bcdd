# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 010:1:1 Analisi e controllo di una CSC: parser delle dichiarazioni (GRAMMATICA_F1 sezioni 3-8)
# 010:1:2 e rapporto di `bcdd check` (sezione 9). Il modulo non scrive nulla: legge soltanto (g-c1).
import std/[strutils, tables, algorithm, sets]
when defined(windows):
  import std/os
import bcddlex, bcddwords, bcddformula, bcddtesti, bcddsys
export bcddwords.isReservedWord

type
  Err* = object
    line*, col*: int      # line 0: errore del file intero (E11)
    code*, msg*: string
    inn*: string          # (1.21) il suffisso ` (in: …)` senza parentesi né `in: `, "" se l'errore vale in tutte le composizioni
    seqno: int

  StatusKind* = enum
    skNone, skHyp, skRat, skBad

  Grade* = enum
    grVerbal, grUnrec, grFormal, grExt

  NameRec* = object
    name*: string
    line*: int
    kind*: string         # CAPABILITY EVENT STATE DEFINE ROW SCENARIO PART TYPE
    piece*: int           # (1.21) 0 = righe comuni, k = k-esimo pezzo VARIANT (da 1)

  CiteKind* = enum
    ckOffers, ckUses, ckPart, ckImport, ckLegata, ckUsing

  Cite* = object
    ## 011:2:1 Una riga G32, G33 o G34 riconosciuta di un'entità.
    kind*: CiteKind
    part*: string         # solo ckPart: il nome della parte
    name*: string         # la CSC o l'entità citata
    version*: string      # "" se la riga non dice la versione
    line*, col*: int      # riga della dichiarazione e colonna del suo primo elemento
    dup*: bool            # la riga ha E01: non si cerca e non compare nel rapporto
    hasMult*: bool        # (1.20, G35) solo ckPart: la riga scrive [m .. n]
    multMin*, multMax*: string   # i limiti come scritti nel file
    optional*: bool       # (1.21) solo ckPart: [0 .. n] con limiti giusti, la parte può mancare
    piece*: int           # (1.21) 0 = righe comuni, k = k-esimo pezzo VARIANT (da 1)

  Piece* = object
    ## 011:2:3 (1.21, G38) Un pezzo: dalla riga VARIANT alla successiva o all'END.
    line*, col*: int
    valid*: bool          # la riga rispetta G38; altrimenti il pezzo non ha dimensione
    dim*, choice*: string
    count*: int           # dichiarazioni riconosciute nel pezzo, escluse COMPOSED OF

  E20Cand* = object
    ## 011:2:4 (1.21) Un E20 di uno scenario d'entità da decidere per composizione, dopo la ricerca delle parti.
    line*, col*: int
    msg*, conn*: string   # messaggio senza suffisso; il connettore X
    piece*: int           # il pezzo dello scenario
    never*: bool          # X non è un connettore di nessuna composizione che contiene lo scenario

  Found* = object
    ## 011:2:2 Esito della ricerca di una citazione.
    searched*, ok*: bool
    where*: string        # "" = in questo file; altrimenti PERCORSO
    path*: string         # (F4b) il percorso aperto, come lo ha formato la ricerca; "" = in questo file
    line*: int            # riga dell'intestazione trovata
    version*, statusText*: string
    statoBlocco*: string  # il codice dello stato: senza_stato, ipotesi, contratto, non_valido
    errCount*, unrec*: int
    offers*, uses*: seq[Cite]
    reason*: string
    viaFallback*: bool    # trovata solo nel ripiego, `attesa VERSION w`: non conta per il controllo di X.y
    pieces*: seq[Piece]   # (1.21) i pezzi VARIANT del blocco trovato: la riga `piece` di ogni offers/uses rimanda qui
    blockText*: string    # 021:2:8 (F3b) solo per un altro file: le righe del blocco trovato, da intestazione a END, con LF
    elems*: Table[string, (string, seq[string])]   # (1.20) CAPABILITY, EVENT e STATE del blocco trovato: nome -> (tipo, parametri)
    blk*: BlockInfo                # (1.0-beta) il blocco trovato: elementi, estensioni, righe, importazioni
    sym*: Table[string, Sym]       # (1.0-beta) i simboli del blocco trovato (tipi di base, per i valori delle storie d'entità)

  Uso* = object
    ## (F4b, passo 0) Una voce della sezione 8 con i dati da cui si rifà la frase.
    line*: int
    text*: string
    part*, name*, version*: string
    inn*: string                   # (1.21) suffisso `(in: …)` senza parentesi, "" se vale in tutte le composizioni
    esito*: string                 # offerta | da_fuori | scoperto | non_controllato
    offeredBy*: seq[(string, int)] # (parte, riga) nell'ordine della frase
    fromOutside*: int              # riga dell'USES dell'entità, 0 se non applicabile
    unchecked*: int                # numero di parti non controllate, 0 se non applicabile

  QArg* = object
    name*: string
    line*, col*: int
    val*: seq[Tok]

  QRef* = object
    ## (1.20, G36) Un nome qualificato `X.y` di uno scenario d'entità, con X dell'entità: il controllo di y aspetta la ricerca.
    kind*: string         # STATE EVENT CAPABILITY: ciò che y deve essere
    qual*, name*: string
    line*, col*: int      # posizione di X
    args*: seq[QArg]      # solo EVENT
    val*: seq[Tok]        # (1.0-beta) il valore assegnato a uno STATE

  ImportRef* = object
    ## 011:2:8 (1.0-beta, G39) Una riga IMPORT PROFILE riconosciuta di un blocco
    name*, version*: string
    line*, col*: int
    ignored*: bool                 # la seconda riga dello stesso profilo con un'altra versione: non riconosciuta

  ExtInfo* = object
    ## 011:2:9 (1.0-beta, 4.11) Un'estensione di un profilo, con i suoi errori
    def*: ExtDef
    line*, col*: int
    bad*: bool
    noName*: bool                  # E34: il nome non si registra
    red*: seq[Tok]                 # REDUCES TO ...
    redLine*, redCol*: int
    redPure*: bool                 # (4.11) la riduzione è un solo costrutto con i soli parametri: E36
    redLabel*: string              # la prima parola o il segno del costrutto (F del messaggio E36)
    redFirst*: int                 # prima riga della dichiarazione REDUCES TO (G-13: se non si legge, la riga è non riconosciuta)

  ElemRec* = object
    kw*, name*: string             # STATE, EVENT IN, EVENT OUT, CAPABILITY, DEFINE
    line*: int

  LegRow* = object
    kw*, id*: string
    grade*: Grade
    used*: seq[string]
    line*: int

  BindRec* = object
    elem*, field*: string
    line*, col*: int
    status*: StatusKind
    decision*: string
    hypLine*, hypCol*: int         # la parola HYPOTHESIS del suo STATUS proprio
    lastLine*: int

  MeansRec* = object
    name*: string
    line*, col*: int
    obs*: seq[(string, string, int, int)]     # elemento, campo, riga, colonna
    usingB*: string
    usingLine*, usingCol*: int

  TransRec* = object
    id*, translates*: string
    line*, col*, transLine*, transCol*: int

  BlockInfo* = object
    bk*: string                    # (1.0-beta) CSC ENTITY BINDING VERIFICATION PROFILE VIEW
    legataName*, legataVer*, ownName*: string   # BINDING e VERIFICATION
    imports*: seq[ImportRef]
    exts*: seq[ExtInfo]            # PROFILE
    binds*: seq[BindRec]
    means*: seq[MeansRec]
    trans*: seq[TransRec]
    elems*: seq[ElemRec]           # gli elementi della CSC, nell'ordine
    scenarioIds*: seq[string]
    legRows*: seq[LegRow]
    importCites*: seq[Cite]        # una per ogni import non ignorato, per la ricerca
    syms*: Table[string, Sym]      # i simboli del blocco, con i tipi
    defUsed*: Table[string, seq[string]]   # DEFINE -> nomi del blocco che la sua espressione nomina
    isView*: bool
    isEntity*: bool
    line*: int
    name*, version*: string
    headerOk*: bool
    status*: StatusKind
    decision*: string
    purposeLine*: int              # riga del primo PURPOSE riconosciuto, 0 se non c'è
    statusLine*, statusCol*: int   # posizione della parola dopo STATUS (HYPOTHESIS o RATIFIED)
    firstDeclLine*: int            # prima riga della dichiarazione che segue l'intestazione
    endLine*: int                  # (F3b) riga dell'END; senza END, la riga prima del blocco seguente o l'ultima del file
    names*: seq[NameRec]           # nomi registrati, nell'ordine di dichiarazione
    cites*: seq[Cite]              # solo per le entità, in ordine di riga
    qrefs*: seq[QRef]              # (1.20) solo per le entità: nomi qualificati degli scenari, da controllare dopo la ricerca
    fqrefs*: seq[QRef]             # (1.0-beta) nomi qualificati delle formule d'entità
    declParams*: Table[string, seq[string]]   # (1.20) parametri di ogni EVENT del blocco
    pieces*: seq[Piece]            # (1.21) i pezzi VARIANT, in ordine di riga (solo entità)
    e20*: seq[E20Cand]             # (1.21) E20 da decidere per composizione (solo entità con dimensioni)
    found*: seq[Found]             # parallelo a cites, riempito da resolveCitations
    xcites*: seq[Cite]             # (1.0-beta) citazioni IMPORT, LEGATA e USING del blocco, in ordine di riga
    xfound*: seq[Found]            # parallelo a xcites

  RowInfo* = object
    blockIdx*: int
    kw*, id*: string
    line*, lastLine*: int          # prima e ultima riga della dichiarazione
    contract*: bool                # stato effettivo
    grade*: Grade
    idEndCol*: int                 # byte dopo l'id (o dopo l'id di DETAILS) sulla prima riga
    hypLine*, hypCol*: int         # posizione di HYPOTHESIS nello STATUS proprio della riga, 0 se non c'è
    ownRatified*: bool
    detailsOf*: string             # id dopo DETAILS, "" se la riga non dettaglia
    piece*: int                    # (1.21) 0 = righe comuni, k = k-esimo pezzo VARIANT
    trigger*: bool                 # (1.0-beta) la formula ha un innesco (sezione 15)
    profHyp*: bool                 # (1.0-beta, 7.1 punto 0a) usa un'estensione di un profilo da approvare
    own*: StatusKind               # (F4a) lo STATUS proprio della riga: skNone se non ne ha
    decision*: string              # (F4a) la decisione D-n del suo STATUS RATIFIED BY valido, "" altrimenti
    extChecks*: seq[string]        # (P4) i controlli C1..C8 dei VERIFY V1 delle estensioni che la riga usa
    detParentKnown*: bool          # (P3) un dettaglio di DEFINE o di storia: la riga che dettaglia c'è ed è del tipo giusto
    detVerbalSelf*, detVerbalPar*: bool   # (P3) un dettaglio di storia: la storia, o quella che dettaglia, ha un passo VERBAL

  GradeRow* = object
    line*: int
    kw*, id*: string
    grade*: Grade

  Assenza* = object
    ## 011:2:5 (1.21) Una voce della sezione 10: un errore di chiusura che sparisce rimettendo una parte facoltativa.
    line*, col*: int
    code*, senza*, msg*, inn*: string

  CompInfo* = object
    ## 011:2:6 (1.21) Una voce della sezione 9: un'entità con più composizioni (o con E23).
    line*: int
    name*: string
    tooMany*: bool
    names*: seq[string]

  FormaMancante* = object
    ## 011:2:7 Una voce della sezione 12 come dati: il testo si compone al momento di scriverlo.
    line*: int
    head*: string                  # BINDING Nome VERSION v [AS n]: solo parole chiave e nomi
    cscTrovata*: bool              # falso: la CSC legata non è stata trovata, gli elementi non sono controllati
    elementi*: seq[string]         # per esempio `STATE modo`; vuoto se ogni elemento ha la forma

  CopMezzo* = object
    name*: string
    line*: int
    promesse*: seq[string]         # gli id delle promesse che il mezzo copre; vuoto se non ne copre

  Copertura* = object
    ## 011:2:9 Una voce della sezione 13 come dati.
    line*: int
    head*: string                  # VERIFICATION Nome VERSION v
    cscTrovata*: bool
    mezzi*: seq[CopMezzo]
    nonEseguite*: seq[string]      # gli id delle promesse formali che nessun mezzo copre

  NonControllata* = object
    ## 011:2:10 Una voce della sezione 7 come dati.
    line*: int
    tipo*: string                  # OFFERS USES PART LEGATA USING IMPORT
    nome*: string                  # il nome citato (IMPORT: il profilo; USING: il BINDING)
    parte*: string                 # solo USING: il nome della parte
    motivo*: string                # il perché della mancata ricerca, nella lingua del comando; "" se nessuno

  Report* = object
    total*, recLines*, comLines*, blankLines*, unrecLines*: int
    blocks*: seq[BlockInfo]
    errs*: seq[Err]
    hasCsc*: bool
    grades*: seq[GradeRow]
    rows*: seq[RowInfo]
    detRows*: seq[RowInfo]         # (1.0-beta) i dettagli di DEFINE e di storie (kw DEFINE o SCENARIO)
    undecided*: seq[(int, string)]
    hyps*: seq[(int, string, string)]
    unrecText*: seq[(int, string)]
    undeclOrder*: seq[string]
    undeclLines*: Table[string, seq[int]]
    hasEntity*: bool
    dirs*: seq[string]             # le cartelle --dir, solo per la prima riga del rapporto
    usi*: seq[Uso]                 # sezione 8: ogni voce, con i dati e la frase
    comps*: seq[CompInfo]          # (1.21) sezione 9
    assenze*: seq[Assenza]         # (1.21) sezione 10
    notFound*: seq[NonControllata] # sezione 7: citazioni non trovate
    srcLines*: seq[string]         # (F4a) il testo di ogni riga, senza fine riga; indice 0 = riga 1
    lineClass*: seq[char]          # (F4a) 'r' riconosciuta, 'c' commento, 'v' vuota, 'n' non riconosciuta, (1.23) 
    spans*: Table[int, int]        # (F4a) riga di inizio -> ultima riga di ogni dichiarazione
    lateRec*: seq[int]             # (P1-a) prime righe di dichiarazioni che il controllo di chiusura scopre riconosciute (uso di KIND DECLARATION)
    lateUnrec*: seq[(int, string)] # (1.0-beta) dichiarazioni (prima riga) che si rivelano non riconosciute alla chiusura del blocco, col motivo
    unrecMotive*: Table[int, string]   # prima riga della dichiarazione -> motivo (profilo non trovato...), "" se nessuno
    hasBinding*, hasVerification*: bool
    lineKindArr: seq[int]
    declData: seq[(int, seq[int], bool)]
    finished: bool
    nonEsegFormeCount*: int
    forme*: seq[FormaMancante]     # sezione 12
    copertura*: seq[Copertura]     # sezione 13
    nonEseguite*: int
    daGiudicare*: seq[(int, string)]              # sezione 14: (riga, voce senza il riferimento alla riga)
    nonEseg*: seq[(string, seq[int])]             # sezione 15: (codice del controllo, righe); i codici in nonEsegNome

  # 011:1:1 Tipi interni
  Decl = object
    first: int
    lines: seq[int]
    toks: seq[Tok]

  NameKind = enum
    nkCap, nkEvent, nkState, nkDefine, nkRow, nkScenario, nkPart, nkType, nkValue, nkExtName

  NameInfo = object
    kind: NameKind
    line: int
    params: seq[string]

  RowRec = object
    piece: int
    id: string
    hasDet: bool
    details: string
    detTok: Tok
    idTok: Tok

  ItemKind = enum
    ikCycle, ikAssign, ikOcc

  Ref = object
    ## (1.20, G36) Un nome, semplice o qualificato `qual.name`.
    hasQual: bool
    qual: Tok
    name: Tok
    hasIdx: bool               # (1.0-beta, G20) x[v] = w
    idx: seq[Tok]
    val: seq[Tok]

  Item = object
    kind: ItemKind
    name: Tok
    hasQual: bool
    qual: Tok
    args: seq[Tok]
    argVals: seq[seq[Tok]]     # il valore di ogni argomento, vuoto per `_`
    hasIdx: bool
    idx: seq[Tok]
    val: seq[Tok]

  Scn = object
    id: string
    hasRepeat: bool
    repUnitErr: bool
    repText: string
    repLine, repCol: int
    repD: (string, string)          # periodo in ms (esatto)
    repUnit: bool
    stepsAfter: int
    piece: int
    givens: seq[Ref]
    items: seq[Item]
    unitMode: int            # -1 non ancora fissato, 0 senza unità, 1 con unità
    hasMax: bool
    maxVal: (string, string)
    maxText: string
    hasVerbal: bool                 # (P3) almeno un passo ha un elemento VERBAL

  Ctx = object
    open: bool
    bi: int
    isView: bool
    isEntity: bool
    first: bool
    zone: bool                     # (1.23, 4.2) la dichiarazione è nella zona d'intestazione: STATUS, IMPORT, PURPOSE
    statusFirst: int               # (1.23) riga del primo STATUS riconosciuto della zona, 0 se non c'è
    inScn: bool
    composed: bool
    offerNames: Table[string, seq[(string, int, int)]]   # (1.20) nome -> (versione scritta, riga, pezzo), una voce per riga riconosciuta e senza E01
    useNames: Table[string, seq[(string, int, int)]]
    curPiece: int                  # (1.21) 0 = righe comuni, k = k-esimo pezzo VARIANT dell'entità aperta
    partRecs: Table[string, seq[(int, int)]]       # (1.21) nome di parte -> (riga, pezzo), una voce per parte senza E01
    ratified: bool
    purposeLine: int
    names: Table[string, NameInfo]
    rows: seq[RowRec]
    rowIds: Table[string, int]
    scns: seq[Scn]
    nameList: seq[NameRec]
    pending: seq[(string, int)]   # tipi usati, in attesa di sapere se il blocco li descrive
    described: HashSet[string]
    valUses: seq[Tok]             # (1.20, G26) nomi usati come valore, da confrontare coi valori delle enumerazioni
    enumVals: HashSet[string]
    env: Env                       # (1.0-beta) simboli e tipi del blocco, per le formule
    pend: seq[Pend]                # formule e espressioni da controllare alla chiusura del blocco
    stChecks: seq[StChk]           # tipi dei valori scritti, da controllare alla chiusura
    dets: seq[DetRec]              # dettagli di DEFINE e di storie
    extCands: seq[Decl]            # (P1-a) dichiarazioni non riconosciute che cominciano con un nome: forse usi di KIND DECLARATION
    typeDecls: seq[TypeDecl]       # tipi con nome (G41), per E28
    stateDecls: seq[StateDecl]     # STATE con indice o FOLLOWS, da controllare alla chiusura
    bk: string                     # (1.0-beta) CSC ENTITY BINDING VERIFICATION PROFILE VIEW
    inExt: bool                    # dentro un'EXTENSION di un profilo
    extIdx: int                    # indice in blocks[bi].exts
    extFields: Table[string, int]  # campo -> riga del primo, nell'estensione aperta
    extFieldToks: Table[string, seq[Tok]]
    nameLines: Table[string, int]  # nomi di MEANS e di storie tradotte (E01)
    elemKw: seq[(string, string)]  # nome -> parola chiave completa (EVENT IN, EVENT OUT)

  Pend = object
    kind: int                      # 0 proprietà di GUARANTEE/ASSUME, 1 DEFINE, 2 DEFINE EVENT
    declFirst: int
    toks: seq[Tok]
    name: string
    nameTok: Tok
    isAssume: bool
    gradeIdx: int
    rowIdx: int
    params: seq[(string, Ty)]
    single: bool
    undecided: bool

  StChk = object
    ty: Ty
    val: seq[Tok]
    code: int                      # 0 valore, 1 indice
    stateName: string
    nameTok: Tok

  DetRec = object
    kind: string                   # DEFINE | SCENARIO
    id: string
    idTok: Tok
    details: string
    detTok: Tok
    line: int
    own: StatusKind
    piece: int
    hypLine, hypCol, lastLine: int

  TypeDecl = object
    name: string
    tok: Tok
    refs: seq[string]

  StateDecl = object
    name: string
    nameTok: Tok
    ty: Ty
    idxTok: Tok                    # il tipo dell'indice, se c'è
    hasIdx: bool
    follows: bool
    evTok, fieldTok: Tok

  Sink = object
    errs: seq[Err]
    undecl: seq[(string, int)]

  Cur = object
    t: seq[Tok]
    p: int
    vals: seq[Tok]          # (1.20) nomi letti come valore (G26) in questa dichiarazione
    lastVal: seq[Tok]       # (1.0-beta) gli elementi dell'ultimo valore letto

const NameKindText = ["CAPABILITY", "EVENT", "STATE", "DEFINE", "ROW", "SCENARIO", "PART", "TYPE", "VALUE", "EXTNAME"]

# 012:1:1 Predicati sugli elementi
proc isW(t: Tok, s: string): bool = t.kind == tkWord and t.text == s
proc isS(t: Tok, s: string): bool = t.kind == tkSym and t.text == s
proc isIdTok(t: Tok): bool = t.kind == tkWord and t.text notin reservedSet
proc isName(t: Tok): bool = isIdTok(t) and '-' notin t.text
proc isUnsigned(t: Tok): bool = t.kind == tkNum and not t.text.startsWith("-")
proc isNum1(t: Tok): bool = isUnsigned(t) and t.text.count('.') <= 1          # L11: numero senza segno
proc isNumS(t: Tok): bool = t.kind == tkNum and t.text.count('.') <= 1        # L12: numero con segno (1.20)
proc isInt(t: Tok): bool = isUnsigned(t) and '.' notin t.text                 # L13: intero (1.20)
proc isDec(t: Tok): bool =
  t.kind == tkWord and t.text.len > 2 and t.text.startsWith("D-") and
    t.text[2 .. ^1].allCharsInSet({'0' .. '9'})

proc has(c: Cur): bool = c.p < c.t.len
proc tk(c: Cur): Tok = c.t[c.p]
proc eatW(c: var Cur, s: string): bool =
  if c.has and isW(c.tk, s):
    inc c.p
    return true
  false
proc eatS(c: var Cur, s: string): bool =
  if c.has and isS(c.tk, s):
    inc c.p
    return true
  false

proc addErr(rep: var Report, line, col: int, code, msg: string) =
  rep.errs.add Err(line: line, col: col, code: code, msg: msg, seqno: rep.errs.len)

proc commit(rep: var Report, ctx: var Ctx, s: Sink) =
  ## 013:1:1 Riporta nel rapporto ciò che una dichiarazione riconosciuta ha trovato.
  ## I tipi usati restano in attesa fino alla chiusura del blocco (un TYPE può venire dopo l'uso).
  for e in s.errs: addErr(rep, e.line, e.col, e.code, e.msg)
  for u in s.undecl: ctx.pending.add u

proc flushTypes(rep: var Report, ctx: Ctx) =
  ## 013:2:1 Al chiuso del blocco: i tipi descritti con TYPE escono dalla sezione 6 (G30).
  for (n, l) in ctx.pending:
    if n in ctx.described: continue
    if n notin rep.undeclLines:
      rep.undeclOrder.add n
      rep.undeclLines[n] = @[]
    if l notin rep.undeclLines[n]: rep.undeclLines[n].add l

# 014:1:1 Regole di dichiarazione (G9-G15, G26)
proc parseValue(c: var Cur): bool =
  ## 014:1:2 G26 (1.20): stringa, numero con segno e unità, true, false, ABSENT (1.0-beta), oppure un nome (il valore di un'enumerazione)
  if not c.has: return false
  let t = c.tk
  let startP = c.p
  defer:
    if result: c.lastVal = c.t[startP ..< c.p]
  case t.kind
  of tkStr:
    if t.closed:
      inc c.p
      return true
    return false
  of tkNum:
    if not isNumS(t): return false
    inc c.p
    if c.has and c.tk.kind == tkWord and c.tk.text in ["ms", "s"] and c.tk.line == t.line:
      inc c.p
    return true
  of tkWord:
    if t.text == "true" or t.text == "false" or t.text == "ABSENT":
      inc c.p
      return true
    if isName(t):
      c.vals.add t
      inc c.p
      return true
    return false
  else:
    return false

proc parseTypeTy(c: var Cur, s: var Sink, ty: var Ty): bool =
  ## 014:1:3 (1.0-beta, G13, G14, G42) legge un tipo; i nomi non dichiarati vanno in `s.undecl`
  var p = c.p
  var u: seq[Tok]
  let r = readTy(c.t, p, u)
  if r == nil: return false
  c.p = p
  ty = r
  for x in u: s.undecl.add (x.text, x.line)
  true

proc parseType(c: var Cur, s: var Sink): bool =
  var ty: Ty
  parseTypeTy(c, s, ty)

proc dupMsg(firstLine: int, name: string): string =
  testo(kNomeGiaUsatoAllaRiga, $firstLine, name)

proc canCoexist*(pieces: seq[Piece], p, q: int): bool =
  ## 013:3:1 (1.21) Due righe possono stare nella stessa composizione se non stanno in due scelte diverse della stessa
  ## dimensione. Un pezzo senza dimensione (VARIANT scritto male) sta con tutti.
  if p == 0 or q == 0 or p == q: return true
  let a = pieces[p - 1]
  let b = pieces[q - 1]
  if not a.valid or not b.valid: return true
  not (a.dim == b.dim and a.choice != b.choice)

proc samePieceKey(pieces: seq[Piece], p, q: int): bool =
  ## 013:3:2 Lo stesso pezzo, o due pezzi della stessa scelta della stessa dimensione (una scelta scritta due volte).
  if p == q: return true
  if p == 0 or q == 0: return false
  let a = pieces[p - 1]
  let b = pieces[q - 1]
  a.valid and b.valid and a.dim == b.dim and a.choice == b.choice

proc pieceWhere(pieces: seq[Piece], p: int): string =
  if p > 0 and pieces[p - 1].valid: "VARIANT " & pieces[p - 1].dim & " = " & pieces[p - 1].choice
  else: testo(kUnPezzoVARIANTScrittoMale)

proc parseParams(c: var Cur, s: var Sink, names: var seq[string], tys: var seq[(string, Ty)]): bool =
  if not c.eatS("("): return false
  if c.has and isS(c.tk, ")"):
    inc c.p
    return true
  var seen = initTable[string, int]()
  while true:
    if not (c.has and isName(c.tk)): return false
    let nt = c.tk
    inc c.p
    if nt.text in seen:
      s.errs.add Err(line: nt.line, col: nt.col, code: "E01", msg: dupMsg(seen[nt.text], nt.text))
    else:
      seen[nt.text] = nt.line
    names.add nt.text
    if not c.eatS(":"): return false
    var pty: Ty
    if not parseTypeTy(c, s, pty): return false
    tys.add (nt.text, pty)
    if c.eatS(","): continue
    return c.eatS(")")

# 015:1:1 Passi degli scenari (G19-G25)
proc parseRef(c: var Cur, r: var Ref): bool =
  ## 015:1:2 G36 (1.20): Nome, oppure Nome "." Nome; la distinzione fra CSC ed entità la fa il controllo di chiusura
  if not (c.has and isName(c.tk)): return false
  let a = c.tk
  inc c.p
  if c.has and isS(c.tk, "."):
    inc c.p
    if not (c.has and isName(c.tk)): return false
    r = Ref(hasQual: true, qual: a, name: c.tk)
    inc c.p
  else:
    r = Ref(name: a)
  true

proc parseIdx(c: var Cur, hasIdx: var bool, idx: var seq[Tok]): bool =
  ## 015:1:3 (1.0-beta, G20) "[" Valore "]" facoltativo dopo il nome
  if c.has and isS(c.tk, "["):
    inc c.p
    if not parseValue(c): return false
    idx = c.lastVal
    hasIdx = true
    if not c.eatS("]"): return false
  true

proc parseAssign(c: var Cur, r: var Ref): bool =
  if not parseRef(c, r): return false
  if not r.hasQual and not parseIdx(c, r.hasIdx, r.idx): return false
  if not c.eatS("="): return false
  if not parseValue(c): return false
  r.val = c.lastVal
  true

proc parseElement(c: var Cur, s: var Sink, items: var seq[Item]): bool =
  if not c.has: return false
  let t = c.tk
  if isW(t, "VERBAL"):
    inc c.p
    if c.has and c.tk.kind == tkStr and c.tk.closed:
      inc c.p
      return true
    return false
  if t.kind == tkWord and t.text in CycleWords:
    inc c.p
    if not c.eatS("("): return false
    var r: Ref
    if not parseRef(c, r): return false
    if not c.eatS(")"): return false
    items.add Item(kind: ikCycle, name: r.name, hasQual: r.hasQual, qual: r.qual)
    return true
  if isName(t):
    var r: Ref
    if not parseRef(c, r): return false
    if not r.hasQual and not parseIdx(c, r.hasIdx, r.idx): return false
    if c.eatS("="):
      if not parseValue(c): return false
      items.add Item(kind: ikAssign, name: r.name, hasQual: r.hasQual, qual: r.qual, hasIdx: r.hasIdx, idx: r.idx, val: c.lastVal)
      return true
    if r.hasIdx: return false
    var it = Item(kind: ikOcc, name: r.name, hasQual: r.hasQual, qual: r.qual)
    if c.has and isS(c.tk, "("):
      inc c.p
      var seen = initTable[string, int]()
      while true:
        if not (c.has and isName(c.tk)): return false
        let at = c.tk
        inc c.p
        if not c.eatS(":"): return false
        if c.has and isW(c.tk, "_"):
          inc c.p
          it.argVals.add @[]
        elif not parseValue(c):
          return false
        else:
          it.argVals.add c.lastVal
        if at.text in seen:
          s.errs.add Err(line: at.line, col: at.col, code: "E01", msg: dupMsg(seen[at.text], at.text))
        else:
          seen[at.text] = at.line
        it.args.add at
        if c.eatS(","): continue
        if c.eatS(")"): break
        return false
    items.add it
    return true
  false

proc normTime(num, unit: string): (string, string) =
  ## 016:1:1 Valore del tempo in millisecondi, esatto (stringhe decimali, nessun virgola mobile).
  var ip = num
  var fp = ""
  let d = num.find('.')
  if d >= 0:
    ip = num[0 ..< d]
    fp = num[d + 1 .. ^1]
  if unit == "s":
    while fp.len < 3: fp.add '0'
    ip = ip & fp[0 .. 2]
    fp = fp[3 .. ^1]
  ip = ip.strip(leading = true, trailing = false, chars = {'0'})
  (ip, fp)

proc cmpTime(a, b: (string, string)): int =
  if a[0].len != b[0].len: return cmp(a[0].len, b[0].len)
  let c0 = cmp(a[0], b[0])
  if c0 != 0: return c0
  var fa = a[1]
  var fb = b[1]
  while fa.len < fb.len: fa.add '0'
  while fb.len < fa.len: fb.add '0'
  cmp(fa, fb)

var gDeferred: seq[Ctx]

# 017:2:1 (1.0-beta) Controlli di nomi e tipi alla chiusura del blocco (sezioni 4.12, 4.13)
proc valText(v: seq[Tok]): string =
  var r = ""
  for x in v:
    if r.len > 0: r.add " "
    r.add x.text
  r

proc tyShown(env: Env, t: Ty): string =
  if t != nil and t.shown.len > 0: t.shown else: tyText(env, t)

proc valNameSkipped(env: Env, v: seq[Tok]): bool =
  ## un nome che non è un valore di nessun elenco: resta E03, senza E25
  v.len == 1 and v[0].kind == tkWord and v[0].text notin ["true", "false", "ABSENT"] and v[0].text notin env.enumOf

proc checkValue(rep: var Report, env: Env, ty: Ty, v: seq[Tok]) =
  if v.len == 0 or valNameSkipped(env, v): return
  if not valueOk(env, ty, v):
    addErr(rep, v[0].line, v[0].col, "E25", testo(kValoreNonDelTipo, tyShown(env, ty), valText(v)))

proc cycleErrs(rep: var Report, order: seq[string], edges: Table[string, seq[string]], tokOf: Table[string, Tok], code, what: string) =
  ## E28 (e simili): un giro si riferisce una volta sola, dal suo membro che viene prima nel file
  var idx = initTable[string, int]()
  for i, n in order: idx[n] = i
  for r0 in order:
    let r = r0
    var path: seq[string] = @[r]
    var found = false
    var onPath = initHashSet[string]()
    onPath.incl r
    proc dfs(n: string): bool =
      for m in edges.getOrDefault(n):
        if m notin idx or idx[m] < idx[r]: continue
        if m == r:
          return true
        if m in onPath: continue
        onPath.incl m
        path.add m
        if dfs(m): return true
        path.setLen(path.len - 1)
        onPath.excl m
      false
    found = dfs(r)
    if found:
      addErr(rep, tokOf[r].line, tokOf[r].col, code, testo(kInGiro, what, path.join(" -> "), r))

proc cycleErrsExt(rep: var Report, order: seq[string], edges: Table[string, seq[string]], tokOf: Table[string, Tok]) =
  var idx = initTable[string, int]()
  for i, n in order: idx[n] = i
  for r0 in order:
    let r = r0
    var path: seq[string] = @[r]
    var onPath = initHashSet[string]()
    onPath.incl r
    proc dfs(n: string): bool =
      for m in edges.getOrDefault(n):
        if m notin idx or idx[m] < idx[r]: continue
        if m == r: return true
        if m in onPath: continue
        onPath.incl m
        path.add m
        if dfs(m): return true
        path.setLen(path.len - 1)
        onPath.excl m
      false
    if dfs(r):
      addErr(rep, tokOf[r].line, tokOf[r].col, "E35", testo(kREDUCESTOInGiro, path.join(" -> "), r))

proc runPending(rep: var Report, ctx: var Ctx) =
  let env = ctx.env
  if env == nil: return
  let b = rep.blocks[ctx.bi]
  if b.isEntity:
    for c in b.cites:
      if c.kind != ckPart and not c.dup: env.conns.incl c.name
  # E28: tipi con nome che si nominano in giro
  block:
    var order: seq[string]
    var edges = initTable[string, seq[string]]()
    var toks = initTable[string, Tok]()
    for td in ctx.typeDecls:
      order.add td.name
      var rs: seq[string]
      for r in td.refs:
        if r in env.types and r != "Boolean": rs.add r
      edges[td.name] = rs
      toks[td.name] = td.tok
    cycleErrs(rep, order, edges, toks, "E28", "TYPE")
  # DEFINE: espressioni e proprietà, nell'ordine di file
  for pd in ctx.pend:
    if pd.kind in [1, 2]:
      env.defToks[pd.name] = pd.toks
  var defOrder: seq[string]
  var defEdges = initTable[string, seq[string]]()
  var defToks = initTable[string, Tok]()
  # 017:2:8 (1.0-beta, 4.14 «Il grado», G-22) gli usi di estensione passano attraverso le DEFINE nominate, a ogni profondità: si
  # rilegge ogni DEFINE (gli errori si danno nel giro principale) per sapere quali estensioni usa e quali DEFINE nomina
  var defExt = initTable[string, (seq[string], bool)]()
  var defRefs = initTable[string, seq[string]]()
  for pd in ctx.pend:
    if pd.kind in [1, 2] and pd.single and pd.toks.len == 1:
      if pd.toks[0].kind == tkWord: defRefs[pd.name] = @[pd.toks[0].text]     # un alias: DEFINE L := K
    elif pd.kind in [1, 2]:
      let r0 = checkExpr(env, pd.toks, pd.params, pd.kind == 2)
      if r0.ok:
        defExt[pd.name] = (r0.extNames, r0.extNoRed)
        var rs: seq[string]
        for x in r0.refs: rs.add x
        for x in r0.devRefs: rs.add x
        defRefs[pd.name] = rs
  for pd in ctx.pend:
    var res: FRes
    case pd.kind
    of 0:
      res = checkProperty(env, pd.toks, pd.isAssume)
      if res.ok:
        var stack: seq[string]
        var seenD = initHashSet[string]()
        for x in res.refs: stack.add x
        for x in res.devRefs: stack.add x
        while stack.len > 0:
          let n = stack.pop()
          if n in seenD: continue
          seenD.incl n
          if n in defExt:
            for en in defExt[n][0]:
              if en notin res.extNames: res.extNames.add en
            if defExt[n][0].len > 0: res.usesExt = true
            if defExt[n][1]: res.extNoRed = true
          if n in defRefs:
            for m in defRefs[n]: stack.add m
    of 1, 2:
      if pd.single and pd.toks.len == 1 and pd.toks[0].kind == tkWord and isName(pd.toks[0]) and
          pd.toks[0].text notin env.syms:
        # 017:2:2 (S-21) un nome solo che non è niente nel blocco: resta E03 come prima
        res.ok = true
        if env.pnf.len > 0: res.ok = false
        else:
          if not ctx.isEntity:
            addErr(rep, pd.toks[0].line, pd.toks[0].col, "E03", testo(kNomeNonDichiaratoComeValore, pd.toks[0].text))
      else:
        res = checkExpr(env, pd.toks, pd.params, pd.kind == 2)
        if pd.single and res.ok: res.ok = true
    else: discard
    for e in res.errs: addErr(rep, e.line, e.col, e.code, e.msg)
    if res.ok:
      for (q, y, kind) in res.qrefs:
        rep.blocks[ctx.bi].fqrefs.add QRef(kind: kind, qual: q.text, name: y.text, line: q.line, col: q.col)
      if pd.kind == 0 and pd.gradeIdx >= 0:
        let g = if res.usesExt and res.extNoRed: grExt else: grFormal
        rep.grades[pd.gradeIdx].grade = g
        if pd.rowIdx >= 0:
          rep.rows[pd.rowIdx].grade = g
          # 017:2:4 (1.0-beta, 7.1 punto 0a) una riga che usa un'estensione di un profilo da approvare è da approvare
          var unapproved = false
          for en in res.extNames:
            if en in env.exts and not env.exts[en].profRatified: unapproved = true
          for en in res.extNames:
            if en in env.exts:
              for ck in env.exts[en].checks:
                if ck notin rep.rows[pd.rowIdx].extChecks: rep.rows[pd.rowIdx].extChecks.add ck
          if unapproved: rep.rows[pd.rowIdx].profHyp = true
          if unapproved and rep.rows[pd.rowIdx].contract:
            rep.rows[pd.rowIdx].contract = false
            rep.hyps.add (pd.declFirst, rep.rows[pd.rowIdx].kw, pd.name)
          var trig = false
          for t in pd.toks:
            if t.kind == tkWord and t.text in ["WHENEVER", "IMPLIES", "AFTER", "BEFORE", "BETWEEN", "WHILE", "PRECEDES", "RESOLVES",
                "ENSURES", "TRANSITION", "ACCEPTS", "REQUIRES", "UNTIL"]: trig = true
          for en in res.extNames:
            if en in env.exts and env.exts[en].kind == "SCOPE": trig = true     # (G-17) un ambito di estensione è un innesco
          rep.rows[pd.rowIdx].trigger = trig
        var us: seq[string]
        for u in res.used: us.add u
        rep.blocks[ctx.bi].legRows.add LegRow(kw: (if pd.isAssume: "ASSUME" else: "GUARANTEE"), id: pd.name, grade: g, used: us,
          line: pd.declFirst)
      if pd.kind in [1, 2]:
        var us: seq[string]
        for u in res.used: us.add u
        rep.blocks[ctx.bi].defUsed[pd.name] = us
      if pd.kind in [1, 2]:
        defOrder.add pd.name
        var rs: seq[string]
        for r in res.refs:
          if r in env.defToks: rs.add r
        defEdges[pd.name] = rs
        defToks[pd.name] = pd.nameTok
    else:
      rep.lateUnrec.add (pd.declFirst, res.motive)
      if pd.kind == 0 and pd.gradeIdx >= 0:
        rep.blocks[ctx.bi].legRows.add LegRow(kw: (if pd.isAssume: "ASSUME" else: "GUARANTEE"), id: pd.name, grade: grUnrec, line: pd.declFirst)
        rep.grades[pd.gradeIdx].grade = grUnrec
        if pd.rowIdx >= 0: rep.rows[pd.rowIdx].grade = grUnrec
  cycleErrs(rep, defOrder, defEdges, defToks, "E28", "DEFINE")
  # valori di INITIAL
  for sc in ctx.stChecks:
    checkValue(rep, env, sc.ty, sc.val)
  # STATE con indice o FOLLOWS
  for sd in ctx.stateDecls:
    if sd.hasIdx:
      let (ok, _) = (sd.idxTok.text in env.types, 0)
      if ok:
        if not finiteTy(env, env.types[sd.idxTok.text]):
          addErr(rep, sd.idxTok.line, sd.idxTok.col, "E29", testo(kIlTipoDellIndiceDi, sd.name, sd.idxTok.text))
      elif sd.idxTok.text notin ctx.names:
        addErr(rep, sd.idxTok.line, sd.idxTok.col, "E29", testo(kIlTipoDellIndiceDi, sd.name, sd.idxTok.text))
      else:
        addErr(rep, sd.idxTok.line, sd.idxTok.col, "E29", testo(kIlTipoDellIndiceDi, sd.name, sd.idxTok.text))
    if sd.follows:
      if sd.evTok.text notin env.syms:
        addErr(rep, sd.evTok.line, sd.evTok.col, "E24", testo(kNomeNonDichiarato, sd.evTok.text))
      elif env.syms[sd.evTok.text].kind notin {sEvent, sDefEvent}:
        addErr(rep, sd.evTok.line, sd.evTok.col, "E24", testo(kNonEUnEventoServe, sd.evTok.text))
      else:
        var pt: Ty = nil
        for (n, t) in env.syms[sd.evTok.text].params:
          if n == sd.fieldTok.text: pt = t
        if pt == nil:
          addErr(rep, sd.fieldTok.line, sd.fieldTok.col, "E24", testo(kNomeNonDichiaratoComeCampo, sd.evTok.text, sd.fieldTok.text))
        else:
          let a = unwrap(env, sd.ty)
          let bb = unwrap(env, pt)
          if a.k != tUnk and bb.k != tUnk and not ((a.k in {tInt, tReal} and bb.k in {tInt, tReal} and a.k == bb.k) or
              (a.k == bb.k and (a.k != tEnum or a.name == bb.name))):
            addErr(rep, sd.fieldTok.line, sd.fieldTok.col, "E25", testo(kTipoIncoerenteServeTrovato, tyShown(env, sd.ty), tyText(env, pt)))

proc checkAssignVal(rep: var Report, ctx: Ctx, nt: Tok, hasIdx: bool, idx: seq[Tok], val: seq[Tok]) =
  ## 017:2:3 (1.0-beta, G20) il valore e l'indice di un'assegnazione, o di un argomento, hanno il tipo dichiarato
  let env = ctx.env
  if nt.text notin env.syms or env.syms[nt.text].kind != sState: return
  let sy = env.syms[nt.text]
  if sy.idx != nil:
    if not hasIdx:
      addErr(rep, nt.line, nt.col, "E29", testo(kHaUnIndiceScriviValore, nt.text, nt.text, sy.idx.name))
    elif idx.len > 0 and not valNameSkipped(env, idx) and not valueOk(env, sy.idx, idx):
      addErr(rep, idx[0].line, idx[0].col, "E29", testo(kIndiceDiNonDelTipo, nt.text, sy.idx.name, valText(idx)))
  elif hasIdx:
    addErr(rep, nt.line, nt.col, "E29", testo(kNonHaIndice, nt.text))
  checkValue(rep, env, sy.ty, val)

proc checkOccArgs(rep: var Report, ctx: Ctx, it: Item) =
  let env = ctx.env
  if it.name.text notin env.syms or env.syms[it.name.text].kind != sEvent: return
  for k, a in it.args:
    if k >= it.argVals.len: continue
    for (n, t) in env.syms[it.name.text].params:
      if n == a.text: checkValue(rep, env, t, it.argVals[k])

# 017:1:1 Chiusura di un blocco: i controlli che hanno bisogno di tutti i nomi (E02, E03, E05, E10)
proc kindName(k: NameKind): string =
  case k
  of nkCap: "CAPABILITY"
  of nkEvent: "EVENT"
  of nkState: "STATE"
  else: ""

proc needKind(rep: var Report, ctx: Ctx, t: Tok, k: NameKind) =
  if t.text notin ctx.names or ctx.names[t.text].kind != k:
    addErr(rep, t.line, t.col, "E03", testo(kNomeNonDichiaratoCome, kindName(k), t.text))

proc profileChecks(rep: var Report, bi: int)

const BlockWords = ["CSC", "REFINEMENT", "ENTITY", "BINDING", "VERIFICATION", "PROFILE"]

proc blockWord(b: BlockInfo): string =
  case b.bk
  of "VIEW": "REFINEMENT VIEW"
  of "": "CSC"
  else: b.bk

proc closeBlock(rep: var Report, ctx: var Ctx, unclosed: bool, endLine: int) =
  if not ctx.open: return
  rep.blocks[ctx.bi].endLine = endLine     # 017:1:2 (F3b) fine del blocco, per le righe del blocco nella richiesta di refine
  flushTypes(rep, ctx)
  rep.blocks[ctx.bi].names = ctx.nameList
  for n, info in ctx.names:
    if info.kind == nkEvent: rep.blocks[ctx.bi].declParams[n] = info.params
  if ctx.env != nil: rep.blocks[ctx.bi].syms = ctx.env.syms
  block:
    # 017:1:9 (1.0-beta) gli elementi della CSC nell'ordine, per le forme concrete e il piano di prova
    var kwOf = initTable[string, string]()
    for t in ctx.elemKw: kwOf[t[0]] = t[1]
    for n in ctx.nameList:
      if n.kind in ["STATE", "EVENT", "CAPABILITY", "DEFINE"] and n.piece == 0 or n.kind in ["STATE", "EVENT", "CAPABILITY", "DEFINE"]:
        rep.blocks[ctx.bi].elems.add ElemRec(kw: (if n.name in kwOf: kwOf[n.name] else: n.kind), name: n.name, line: n.line)
      elif n.kind == "SCENARIO":
        rep.blocks[ctx.bi].scenarioIds.add n.name
  if rep.blocks[ctx.bi].bk == "PROFILE": profileChecks(rep, ctx.bi)
  block:
    var verbalScn = initHashSet[string]()
    for sc in ctx.scns:
      if sc.hasVerbal and sc.id.len > 0: verbalScn.incl sc.id
    for dr in ctx.dets:
      let known = dr.details in ctx.names and (if dr.kind == "DEFINE": ctx.names[dr.details].kind == nkDefine
        else: ctx.names[dr.details].kind == nkScenario)
      rep.detRows.add RowInfo(blockIdx: ctx.bi, kw: dr.kind, id: dr.id, line: dr.line, lastLine: dr.lastLine,
        contract: dr.own == skRat and rep.blocks[ctx.bi].headerOk, idEndCol: dr.detTok.col + dr.detTok.text.len, hypLine: dr.hypLine,
        hypCol: dr.hypCol, ownRatified: dr.own == skRat, detailsOf: dr.details, own: dr.own,
        detParentKnown: known, detVerbalSelf: dr.kind == "SCENARIO" and dr.id in verbalScn,
        detVerbalPar: known and dr.kind == "SCENARIO" and dr.details in verbalScn)
  let b = rep.blocks[ctx.bi]
  let nm = if b.headerOk: b.name else: "?"
  let nm0 = nm
  if unclosed:
    addErr(rep, b.line, 0, "E07", testo(kBloccoNonChiusoMancaEND, blockWord(b), nm))
  if ctx.inExt and ctx.bk == "PROFILE":
    ctx.inExt = false       # un'estensione senza END dentro un profilo senza END dà un solo E07, sul profilo
  if not b.isView:
    gDeferred.add ctx
    if ctx.purposeLine == 0 and b.bk in ["CSC", "ENTITY", "PROFILE"]:
      addErr(rep, b.line, 0, "E10", if b.bk == "PROFILE": testo(kPurposeMancanteNel, b.bk, nm) else: testo(kPurposeMancanteNella, b.bk, nm))
    # 017:1:5 (1.21, G38) E22: le scelte dei pezzi VARIANT; l'entità con un VARIANT scritto male non ha composizioni, quindi niente E22
    var anyBadPiece = false
    for p in b.pieces:
      if not p.valid: anyBadPiece = true
    if b.isEntity and not anyBadPiece and b.pieces.len > 0:
      var firstOf = initTable[string, (int, int)]()   # dimensione \0 scelta -> (riga, colonna) del primo pezzo
      var dimOrder: seq[string]
      var dimChoices = initTable[string, seq[string]]()
      for p in b.pieces:
        let key = p.dim & "\0" & p.choice
        if key in firstOf:
          addErr(rep, p.line, p.col, "E22", testo(kLaSceltaEGiaScritta, p.dim, p.choice, $firstOf[key][0]))
        else:
          firstOf[key] = (p.line, p.col)
          if p.dim notin dimChoices:
            dimOrder.add p.dim
            dimChoices[p.dim] = @[]
          dimChoices[p.dim].add p.choice
        if p.count == 0:
          addErr(rep, p.line, p.col, "E22", testo(kIlPezzoVARIANTEVuoto, p.dim, p.choice))
      for d in dimOrder:
        if dimChoices[d].len == 1:
          let at = firstOf[d & "\0" & dimChoices[d][0]]
          addErr(rep, at[0], at[1], "E22", testo(kLaDimensioneHaUnaSola, d, dimChoices[d][0]))
    # E02
    for r in ctx.rows:
      if r.hasDet and r.details notin ctx.rowIds:
        addErr(rep, r.detTok.line, r.detTok.col, "E02",
          (if b.isEntity: testo(kDETAILSNominaUnIdChe)
           else: testo(kDETAILSNominaUnIdChe2)) & r.details)
      elif r.hasDet and b.isEntity and b.pieces.len > 0:
        # 017:1:6 (1.21) il padre sta fra le righe comuni o nella stessa scelta del figlio, altrimenti non c'è in ogni composizione del figlio
        let pp = ctx.rows[ctx.rowIds[r.details]].piece
        if pp != 0 and not samePieceKey(b.pieces, pp, r.piece):
          addErr(rep, r.detTok.line, r.detTok.col, "E02", testo(kDETAILSNominaUnaGUARANTEEChe, r.details, pieceWhere(b.pieces, pp)))
    # E05: un giro si riferisce una volta sola, dal suo membro che viene prima nel file
    let n = ctx.rows.len
    var parent = newSeq[int](n)
    for i, r in ctx.rows:
      parent[i] = if r.hasDet and r.details in ctx.rowIds: ctx.rowIds[r.details] else: -1
    for r in 0 ..< n:
      var path = @[r]
      var cur = parent[r]
      while cur != -1 and cur != r and cur notin path:
        path.add cur
        cur = parent[cur]
      if cur == r and r == min(path):
        var ids: seq[string]
        for p in path: ids.add ctx.rows[p].id
        ids.add ctx.rows[r].id
        addErr(rep, ctx.rows[r].idTok.line, ctx.rows[r].idTok.col, "E05",
          testo(kDETAILSInGiro, ids.join(" -> ")))
    # 017:1:8 (1.0-beta, G12, G19) E02 ed E05 per i dettagli di DEFINE e di storie
    for kind in ["DEFINE", "SCENARIO"]:
      var ids: seq[string]
      var par = initTable[string, string]()
      var toks = initTable[string, Tok]()
      for dr in ctx.dets:
        if dr.kind != kind: continue
        let isTarget = dr.details in ctx.names and (if kind == "DEFINE": ctx.names[dr.details].kind == nkDefine
          else: ctx.names[dr.details].kind == nkScenario)
        if not isTarget:
          addErr(rep, dr.detTok.line, dr.detTok.col, "E02", if kind == "DEFINE":
            testo(kDETAILSNominaUnNomeChe, dr.details)
            else: testo(kDETAILSNominaUnIdChe3, dr.details))
        else:
          ids.add dr.id
          par[dr.id] = dr.details
          toks[dr.id] = dr.idTok
      # E05: i giri fra i dettagli
      for r in ids:
        var path = @[r]
        var curr = par.getOrDefault(r)
        while curr.len > 0 and curr != r and curr notin path:
          path.add curr
          curr = par.getOrDefault(curr)
        if curr == r:
          var mn = path[0]
          for x in path:
            if x in toks and toks[x].line * 10000 + toks[x].col < toks[mn].line * 10000 + toks[mn].col: mn = x
          if mn == r:
            addErr(rep, toks[r].line, toks[r].col, "E05", testo(kDETAILSInGiro2, path.join(" -> "), r))
    for sc in ctx.scns:
      if sc.hasRepeat and sc.stepsAfter == 0:
        addErr(rep, sc.repLine, sc.repCol, "E30", testo(kREPEATSenzaPassiIPassi))
    # E03, E20 (1.20: i nomi qualificati di uno scenario)
    proc qualified(rep: var Report, ctx: Ctx, q, nm: Tok, kind: NameKind, args: seq[Tok], scnPiece: int,
        argVals: seq[seq[Tok]] = @[], val: seq[Tok] = @[]) =
      ## 017:1:3 Un nome qualificato X.y: in una CSC è E20; in un'entità E20 se X non è sua, altrimenti il controllo di y
      ## aspetta la ricerca delle CSC citate (resolveCitations).
      let full = q.text & "." & nm.text
      if not ctx.isEntity:
        addErr(rep, q.line, q.col, "E20", testo(kInUnaCSCINomi, full))
        return
      var mine = false
      let pcs = rep.blocks[ctx.bi].pieces
      for c in rep.blocks[ctx.bi].cites:
        if c.kind != ckPart and not c.dup and c.name == q.text and canCoexist(pcs, c.piece, scnPiece):
          mine = true
          break
      let e20msg = testo(kNonOffreNeUsaIl, full, nm0, q.text, nm0)
      # 017:1:7 (1.21) con dimensioni (e nessun VARIANT scritto male) X si controlla per composizione: dopo la ricerca delle parti
      var anyValid, anyBad = false
      for p in pcs:
        if p.valid: anyValid = true
        else: anyBad = true
      if anyValid and not anyBad:
        rep.blocks[ctx.bi].e20.add E20Cand(line: q.line, col: q.col, msg: e20msg, conn: q.text, piece: scnPiece, never: not mine)
        if not mine: return
      elif not mine:
        addErr(rep, q.line, q.col, "E20", e20msg)
        return
      var qr = QRef(kind: kindName(kind), qual: q.text, name: nm.text, line: q.line, col: q.col)
      for k, a in args: qr.args.add QArg(name: a.text, line: a.line, col: a.col, val: (if k < argVals.len: argVals[k] else: @[]))
      qr.val = val
      rep.blocks[ctx.bi].qrefs.add qr
    for sc in ctx.scns:
      for g in sc.givens:
        if g.hasQual: qualified(rep, ctx, g.qual, g.name, nkState, @[], sc.piece, @[], g.val)
        else:
          needKind(rep, ctx, g.name, nkState)
          checkAssignVal(rep, ctx, g.name, g.hasIdx, g.idx, g.val)
      for it in sc.items:
        if it.hasQual:
          case it.kind
          of ikCycle: qualified(rep, ctx, it.qual, it.name, nkCap, @[], sc.piece)
          of ikAssign: qualified(rep, ctx, it.qual, it.name, nkState, @[], sc.piece, @[], it.val)
          of ikOcc: qualified(rep, ctx, it.qual, it.name, nkEvent, it.args, sc.piece, it.argVals)
          continue
        case it.kind
        of ikCycle: needKind(rep, ctx, it.name, nkCap)
        of ikAssign:
          needKind(rep, ctx, it.name, nkState)
          checkAssignVal(rep, ctx, it.name, it.hasIdx, it.idx, it.val)
        of ikOcc:
          needKind(rep, ctx, it.name, nkEvent)
          checkOccArgs(rep, ctx, it)
          if it.name.text in ctx.names and ctx.names[it.name.text].kind == nkEvent:
            for a in it.args:
              if a.text notin ctx.names[it.name.text].params:
                addErr(rep, a.line, a.col, "E03",
                  testo(kNomeNonDichiaratoComeParametro, it.name.text, a.text))
    # E03 per un nome usato come valore (G26, 1.20): in una CSC dev'essere il valore di un'enumerazione del blocco
    for v in ctx.valUses:
      if v.text notin ctx.enumVals:
        addErr(rep, v.line, v.col, "E03", testo(kNomeNonDichiaratoComeValore, v.text))
  ctx = Ctx()

proc symKindOf(k: NameKind): SymKind =
  case k
  of nkCap: sCap
  of nkEvent: sEvent
  of nkState: sState
  of nkDefine: sDefine
  of nkRow: sRow
  of nkScenario: sScn
  of nkPart: sPart
  of nkType: sType
  of nkValue: sValue
  of nkExtName: sExt

proc declare(rep: var Report, ctx: var Ctx, nt: Tok, kind: NameKind, params: seq[string] = @[]) =
  if nt.text in ctx.names:
    addErr(rep, nt.line, nt.col, "E01", dupMsg(ctx.names[nt.text].line, nt.text))
  else:
    ctx.names[nt.text] = NameInfo(kind: kind, line: nt.line, params: params)
    if ctx.env != nil: ctx.env.syms[nt.text] = Sym(kind: symKindOf(kind), line: nt.line, ty: tyUnk)
    ctx.nameList.add NameRec(name: nt.text, line: nt.line, kind: NameKindText[ord(kind)], piece: ctx.curPiece)

proc declareValue(rep: var Report, ctx: var Ctx, nt: Tok) =
  ## 017:1:4 (1.20, G37) Un valore d'enumerazione entra nello stesso elenco dei nomi del blocco (E01 se c'è già), ma non nella
  ## lista delle dichiarazioni: non è una dichiarazione a sé.
  if nt.text in ctx.names:
    addErr(rep, nt.line, nt.col, "E01", dupMsg(ctx.names[nt.text].line, nt.text))
  else:
    ctx.names[nt.text] = NameInfo(kind: nkValue, line: nt.line)
    if ctx.env != nil: ctx.env.syms[nt.text] = Sym(kind: sValue, line: nt.line, ty: tyUnk)
  ctx.enumVals.incl nt.text

# 018:1:1 Apertura di un blocco (G1, G2; E09)
proc openBlock(rep: var Report, ctx: var Ctx, fileNames: var Table[string, int], d: Decl) =
  let t = d.toks
  let w0 = t[0].text
  let bk = if w0 == "REFINEMENT": "VIEW" else: w0
  var b = BlockInfo(bk: bk, isView: bk == "VIEW", isEntity: bk == "ENTITY", line: d.first)
  var nameTok: Tok
  if not b.isView:
    rep.hasCsc = true
    if b.isEntity: rep.hasEntity = true
    case bk
    of "BINDING":
      b.headerOk = (t.len == 4 or (t.len == 6 and isW(t[4], "AS") and isName(t[5]))) and isName(t[1]) and
        isW(t[2], "VERSION") and isUnsigned(t[3])
    else:
      b.headerOk = t.len == 4 and isName(t[1]) and isW(t[2], "VERSION") and isUnsigned(t[3])
    if b.headerOk:
      b.name = t[1].text
      b.version = t[3].text
      nameTok = t[1]
      if bk in ["BINDING", "VERIFICATION"]:
        b.legataName = b.name
        b.legataVer = b.version
      if bk == "BINDING" and t.len == 6: b.ownName = t[5].text
    else:
      let hint = case bk
        of "CSC": testo(kHintCSC)
        of "ENTITY": testo(kHintENTITY)
        of "BINDING": testo(kHintBINDING)
        of "VERIFICATION": testo(kHintVERIFICATION)
        else: testo(kHintPROFILE)
      addErr(rep, d.first, t[0].col, "E09", testo(kIntestazioneNonValidaAttesa, hint))
  else:
    # 018:1:2 (1.10) blocco ritirato: E15, nessun nome registrato (sezione 4.8)
    b.headerOk = t.len == 3 and isW(t[1], "VIEW") and isName(t[2])
    if b.headerOk: b.name = t[2].text
    addErr(rep, d.first, t[0].col, "E15",
      testo(kREFINEMENTVIEWEUscitaDal))
  if b.headerOk and bk in ["CSC", "ENTITY", "PROFILE"]:
    if b.name in fileNames:
      addErr(rep, nameTok.line, nameTok.col, "E01", dupMsg(fileNames[b.name], b.name))
    else:
      fileNames[b.name] = d.first
  if b.headerOk and bk == "BINDING":
    # 018:1:3 (1.0-beta, E40) due BINDING per la stessa CSC e la stessa versione senza nome, o con lo stesso nome
    let key = "\0B:" & b.name & "@" & b.version & "#" & b.ownName
    if key in fileNames:
      if b.ownName.len == 0:
        addErr(rep, d.first, 0, "E40", testo(kSecondoBINDINGSenzaNomePer, b.name, b.version, $fileNames[key]))
      else:
        addErr(rep, d.first, 0, "E40", testo(kNomeDiBINDINGGiaUsato, $fileNames[key], b.ownName))
    else:
      fileNames[key] = d.first
  if bk == "BINDING": rep.hasBinding = true
  if bk == "VERIFICATION": rep.hasVerification = true
  rep.blocks.add b
  ctx = Ctx(open: true, bi: rep.blocks.high, isView: b.isView, isEntity: b.isEntity, first: true, zone: true, bk: bk)
  ctx.env = newEnv()
  ctx.env.isEntity = b.isEntity
  ctx.env.blockLevel = (if bk == "CSC" or bk == "VIEW" or bk == "PROFILE": "CSC" else: bk)
  ctx.env.entName = (if b.headerOk: b.name else: "?")
  ctx.env.types["Boolean"] = tyBool

# 019:1:1 Dichiarazioni dentro un blocco CSC: restituisce true se la dichiarazione è riconosciuta
proc handleCsc(rep: var Report, ctx: var Ctx, d: Decl, wasFirst: bool): bool =
  let t0 = d.toks[0]
  let w = if t0.kind == tkWord: t0.text else: ""
  var s = Sink()
  var c = Cur(t: d.toks, p: 1)
  # 019:1:6 (1.20) i nomi letti come valore contano solo se la dichiarazione è riconosciuta, e solo in una CSC
  defer:
    if result and not ctx.isEntity: ctx.valUses.add c.vals
  if wasFirst: rep.blocks[ctx.bi].firstDeclLine = d.first
  case w
  of "END":
    if d.toks.len == 1:
      closeBlock(rep, ctx, false, d.first)
      return true
    return false
  of "STATUS":
    # 019:1:9 (1.23, sezione 4.2) STATUS vale in qualunque punto della zona d'intestazione; un secondo STATUS riconosciuto è E10
    if not ctx.zone or d.toks.len < 2: return false
    let tt = d.toks
    let again = ctx.statusFirst != 0
    if again and ((isW(tt[1], "HYPOTHESIS") and tt.len == 2) or isW(tt[1], "RATIFIED")) and
        not (isW(tt[1], "RATIFIED") and ctx.isEntity):
      addErr(rep, t0.line, t0.col, "E10", testo(kSTATUSRipetutoIlPrimoE, $ctx.statusFirst))
    if isW(tt[1], "HYPOTHESIS"):
      if tt.len != 2: return false
      if not again:
        ctx.statusFirst = t0.line
        rep.blocks[ctx.bi].status = skHyp
        rep.blocks[ctx.bi].statusLine = tt[1].line
        rep.blocks[ctx.bi].statusCol = tt[1].col
      return true
    if isW(tt[1], "RATIFIED"):
      if ctx.isEntity: return false     # 019:1:4 (1.3, g-t4) in un'entità solo STATUS HYPOTHESIS è riconosciuto
      if tt.len == 4 and isW(tt[2], "BY") and isDec(tt[3]):
        if not again:
          ctx.statusFirst = t0.line
          rep.blocks[ctx.bi].status = skRat
          rep.blocks[ctx.bi].decision = tt[3].text
          rep.blocks[ctx.bi].statusLine = tt[1].line
          rep.blocks[ctx.bi].statusCol = tt[1].col
          ctx.ratified = true
      else:
        if not again:
          ctx.statusFirst = t0.line
          rep.blocks[ctx.bi].status = skBad
        addErr(rep, tt[1].line, tt[1].col, "E04", testo(kSTATUSRATIFIEDSenzaDecisioneServe))
      return true
    return false
  of "IMPORT":
    # 019:1:10 (1.23, G39) IMPORT PROFILE Nome VERSION v: solo nella zona d'intestazione di una CSC; non cerca niente e non registra niente
    let tt = d.toks
    if not (ctx.zone and ctx.bk != "PROFILE" and tt.len == 5 and isW(tt[1], "PROFILE") and isName(tt[2]) and
        isW(tt[3], "VERSION") and isUnsigned(tt[4])): return false
    # 019:1:16 (1.0-beta, S-9) due righe dello stesso profilo con versioni diverse nello stesso blocco: la seconda non è riconosciuta
    var ig = false
    for im in rep.blocks[ctx.bi].imports:
      if im.name == tt[2].text and im.version != tt[4].text and not im.ignored: ig = true
    rep.blocks[ctx.bi].imports.add ImportRef(name: tt[2].text, version: tt[4].text, line: d.first, col: t0.col, ignored: ig)
    if ig: return false
    rep.blocks[ctx.bi].importCites.add Cite(kind: ckImport, name: tt[2].text, version: tt[4].text, line: d.first, col: t0.col)
    return true
  of "REPEAT":
    # 019:1:17 (1.0-beta, G47) REPEAT ( FOREVER | m..n ) EVERY numero unità, fra i passi di una storia
    if not ctx.inScn or ctx.scns.len == 0: return false
    let tt = d.toks
    var i = 1
    var forever = false
    var lo, hi: Tok
    if tt.len > 1 and isW(tt[1], "FOREVER"):
      forever = true
      i = 2
    elif tt.len >= 4 and isInt(tt[1]) and isS(tt[2], "..") and isInt(tt[3]):
      lo = tt[1]
      hi = tt[3]
      i = 4
    else: return false
    if not (i + 3 == tt.len and isW(tt[i], "EVERY") and isNum1(tt[i + 1]) and tt[i + 2].kind == tkWord and
        tt[i + 2].text in ["ms", "s"] and tt[i + 2].line == tt[i + 1].line): return false
    let sc = addr ctx.scns[^1]
    let per = tt[i + 1].text & " " & tt[i + 2].text
    if sc.hasRepeat:
      addErr(rep, t0.line, t0.col, "E30", testo(kREPEATRipetutoNellaStoriaIl, $sc.repLine))
      return true
    sc.hasRepeat = true
    sc.repLine = t0.line
    sc.repCol = t0.col
    sc.repD = normTime(tt[i + 1].text, tt[i + 2].text)
    sc.repText = per
    if not forever:
      let a = lo.text.strip(leading = true, trailing = false, chars = {'0'})
      let b = hi.text.strip(leading = true, trailing = false, chars = {'0'})
      if b.len == 0 or cmp(a.len, b.len) > 0 or (a.len == b.len and a > b):
        addErr(rep, t0.line, t0.col, "E30", testo(kRipetizioniNonValideScriviREPEAT, lo.text, hi.text))
    if sc.unitMode == 0:
      addErr(rep, t0.line, t0.col, "E30", testo(kREPEATEVERYVuoleUnaStoria))
      sc.repUnitErr = true
    sc.hasMax = false
    return true
  of "PURPOSE":
    if d.toks.len == 2 and d.toks[1].kind == tkStr and d.toks[1].closed:
      if ctx.purposeLine != 0:
        addErr(rep, t0.line, t0.col, "E10", testo(kPURPOSERipetutoIlPrimoE, $ctx.purposeLine))
      else:
        ctx.purposeLine = t0.line
        rep.blocks[ctx.bi].purposeLine = t0.line
      return true
    return false
  of "CAPABILITY":
    if not (c.has and isName(c.tk)): return false
    let nt = c.tk
    inc c.p
    var ps: seq[string]
    var pts: seq[(string, Ty)]
    if c.has and isS(c.tk, "("):
      if not parseParams(c, s, ps, pts): return false
    discard c.eatW("AUTONOMOUS")
    if c.has: return false
    declare(rep, ctx, nt, nkCap, ps)
    if nt.text in ctx.env.syms and ctx.env.syms[nt.text].line == nt.line: ctx.env.syms[nt.text].params = pts
    commit(rep, ctx, s)
    return true
  of "EVENT":
    if not (c.has and (isW(c.tk, "IN") or isW(c.tk, "OUT"))): return false
    let dirTok = c.tk
    inc c.p
    if not (c.has and isName(c.tk)): return false
    let nt = c.tk
    inc c.p
    var ps: seq[string]
    var pts: seq[(string, Ty)]
    if c.has and isS(c.tk, "("):
      if not parseParams(c, s, ps, pts): return false
    if c.has: return false
    declare(rep, ctx, nt, nkEvent, ps)
    ctx.elemKw.add (nt.text, "EVENT " & dirTok.text)
    if nt.text in ctx.env.syms and ctx.env.syms[nt.text].line == nt.line: ctx.env.syms[nt.text].params = pts
    commit(rep, ctx, s)
    return true
  of "STATE":
    if not (c.has and isName(c.tk)): return false
    let nt = c.tk
    inc c.p
    var sd = StateDecl(name: nt.text, nameTok: nt)
    if c.has and isS(c.tk, "["):
      inc c.p
      if not (c.has and isName(c.tk)): return false
      sd.idxTok = c.tk
      sd.hasIdx = true
      inc c.p
      if not c.eatS("]"): return false
    if not c.eatS(":"): return false
    var sty: Ty
    if not parseTypeTy(c, s, sty): return false
    if not c.eatW("INITIAL"): return false
    if not parseValue(c): return false
    let initVal = c.lastVal
    if c.eatW("FOLLOWS"):
      # 019:1:11 (1.0-beta, G11) STATE s : T INITIAL v FOLLOWS e.campo; con l'indice non è una forma
      if sd.hasIdx: return false
      if not (c.has and isName(c.tk)): return false
      sd.evTok = c.tk
      inc c.p
      if not c.eatS("."): return false
      if not (c.has and isName(c.tk)): return false
      sd.fieldTok = c.tk
      inc c.p
      sd.follows = true
    if c.has: return false
    declare(rep, ctx, nt, nkState)
    commit(rep, ctx, s)
    if nt.text in ctx.env.syms and ctx.env.syms[nt.text].line == nt.line:
      ctx.env.syms[nt.text].ty = sty
      if sd.hasIdx: ctx.env.syms[nt.text].idx = Ty(k: tNamed, name: sd.idxTok.text)
      sd.ty = sty
      ctx.stChecks.add StChk(ty: sty, val: initVal, stateName: nt.text, nameTok: nt)
      if sd.hasIdx or sd.follows: ctx.stateDecls.add sd
    return true
  of "DEFINE":
    # 019:1:12 (1.0-beta, G12) DEFINE [EVENT] Nome [ParametriDefine] [DETAILS Id [STATUS Stato]] := ( UNDECIDED | Espr )
    let isEv = c.has and isW(c.tk, "EVENT")
    if isEv: inc c.p
    if not (c.has and isName(c.tk)): return false
    let nt = c.tk
    inc c.p
    var ps: seq[string]
    var pts: seq[(string, Ty)]
    if c.has and isS(c.tk, "(") and not isEv:
      if not parseParams(c, s, ps, pts): return false
      if pts.len == 0: return false
    var detTok, dHyp: Tok
    var hasDet = false
    var dst = skNone
    var ddec = ""
    if c.has and isW(c.tk, "DETAILS") and not isEv:
      inc c.p
      if not (c.has and isIdTok(c.tk)): return false
      detTok = c.tk
      hasDet = true
      inc c.p
      if c.eatW("STATUS"):
        if c.has and isW(c.tk, "HYPOTHESIS"):
          dHyp = c.tk
          inc c.p
          dst = skHyp
        elif c.has and isW(c.tk, "RATIFIED"):
          inc c.p
          if c.has and isW(c.tk, "BY") and c.p + 1 < c.t.len and isDec(c.t[c.p + 1]):
            dst = skRat
            ddec = c.t[c.p + 1].text
            c.p += 2
          else:
            dst = skBad
            addErr(rep, c.t[c.p - 1].line, c.t[c.p - 1].col, "E04", testo(kSTATUSRATIFIEDSenzaDecisioneServe))
        else: return false
    if not c.eatS(":="): return false
    commit(rep, ctx, s)                   # 019:1:17 (1.0-beta, G-07) E01 sui parametri ripetuti e tipi non dichiarati dei parametri
    declare(rep, ctx, nt, nkDefine)       # il nome esiste anche se il valore non si legge
    let fresh = nt.text in ctx.env.syms and ctx.env.syms[nt.text].line == nt.line
    if fresh:
      if isEv: ctx.env.syms[nt.text].kind = sDefEvent
      ctx.env.syms[nt.text].params = pts
      ctx.env.syms[nt.text].hasParams = pts.len > 0
    if hasDet:
      ctx.dets.add DetRec(kind: "DEFINE", id: nt.text, idTok: nt, details: detTok.text, detTok: detTok, line: d.first,
        own: dst, piece: ctx.curPiece, hypLine: dHyp.line, hypCol: dHyp.col, lastLine: d.lines[^1])
      if dst != skRat: rep.hyps.add (d.first, "DEFINE", nt.text)
    if not isEv and c.has and isW(c.tk, "UNDECIDED") and c.p + 1 == c.t.len:
      inc c.p
      if fresh: ctx.env.syms[nt.text].undecided = true
      rep.undecided.add (d.first, nt.text)
      return true
    if not c.has: return false
    let valToks = c.t[c.p .. ^1]
    # un Valore semplice (numero con unità, stringa, true, false, nome) si legge come prima
    var c2 = Cur(t: c.t, p: c.p)
    var single = false
    if not isEv and parseValue(c2) and not c2.has:
      single = true
      if c2.vals.len == 0 and fresh and ctx.env != nil:
        discard
    ctx.pend.add Pend(kind: (if isEv: 2 else: 1), declFirst: d.first, toks: valToks, name: nt.text, nameTok: nt,
      gradeIdx: -1, rowIdx: -1, params: pts, single: single)
    c.p = c.t.len
    return true
  of "TYPE":
    # 019:1:3 G30: TYPE Nome := VERBAL "…"; altrimenti non riconosciuta e senza nome
    let tt = d.toks
    let baseTypes = ["Boolean", "String", "Duration", "Integer", "Real", "Sequence", "Optional"]
    if tt.len == 5 and isName(tt[1]) and isS(tt[2], ":=") and isW(tt[3], "VERBAL") and
        tt[4].kind == tkStr and tt[4].closed and
        tt[1].text notin baseTypes:
      declare(rep, ctx, tt[1], nkType)
      ctx.described.incl tt[1].text
      ctx.env.described.incl tt[1].text
      return true
    # 019:1:7 G37 (1.20): TYPE Nome := { Nome { , Nome } }
    if tt.len >= 6 and isName(tt[1]) and isS(tt[2], ":=") and isS(tt[3], "{") and isS(tt[^1], "}") and
        tt[1].text notin baseTypes:
      let inner = tt[4 ..< tt.len - 1]
      var ok = inner.len mod 2 == 1
      if ok:
        for i, x in inner:
          if (i mod 2 == 0 and not isName(x)) or (i mod 2 == 1 and not isS(x, ",")): ok = false
      if ok:
        declare(rep, ctx, tt[1], nkType)
        ctx.described.incl tt[1].text
        var et = Ty(k: tEnum, name: tt[1].text, shown: tt[1].text)
        for i in countup(0, inner.len - 1, 2): et.values.add inner[i].text
        ctx.env.types[tt[1].text] = et
        for i in countup(0, inner.len - 1, 2):
          declareValue(rep, ctx, inner[i])
          if inner[i].text notin ctx.env.enumOf: ctx.env.enumOf[inner[i].text] = tt[1].text
        return true
    # 019:1:13 (1.0-beta, G41, G42) TYPE Nome := Tipo
    if tt.len >= 4 and isName(tt[1]) and isS(tt[2], ":=") and tt[1].text notin baseTypes:
      var p3 = 3
      var u: seq[Tok]
      let ty = readTy(tt, p3, u)
      if ty != nil and p3 == tt.len:
        declare(rep, ctx, tt[1], nkType)
        ctx.described.incl tt[1].text
        var td = TypeDecl(name: tt[1].text, tok: tt[1])
        proc collect(t: Ty, acc: var seq[string]) =
          if t == nil: return
          if t.k == tNamed: acc.add t.name
          collect(t.inner, acc)
          for (_, f) in t.fields: collect(f, acc)
        collect(ty, td.refs)
        ctx.typeDecls.add td
        ctx.env.types[tt[1].text] = ty
        if ty.k == tRec: ty.name = tt[1].text
        for x in u: s.undecl.add (x.text, x.line)
        commit(rep, ctx, s)
        return true
    return false
  of "SCENARIO":
    var gs: seq[Ref]
    if not (c.has and isIdTok(c.tk)): return false
    let idt = c.tk
    inc c.p
    var sdet, sHyp: Tok
    var shasDet = false
    var sst = skNone
    if c.has and isW(c.tk, "DETAILS"):
      # 019:1:14 (1.0-beta, G19) SCENARIO id DETAILS padre [STATUS Stato]
      inc c.p
      if not (c.has and isIdTok(c.tk)): return false
      sdet = c.tk
      shasDet = true
      inc c.p
      if c.eatW("STATUS"):
        if c.has and isW(c.tk, "HYPOTHESIS"):
          sHyp = c.tk
          inc c.p
          sst = skHyp
        elif c.has and isW(c.tk, "RATIFIED"):
          inc c.p
          if c.has and isW(c.tk, "BY") and c.p + 1 < c.t.len and isDec(c.t[c.p + 1]):
            sst = skRat
            c.p += 2
          else:
            sst = skBad
            addErr(rep, c.t[c.p - 1].line, c.t[c.p - 1].col, "E04", testo(kSTATUSRATIFIEDSenzaDecisioneServe))
        else: return false
    if c.eatW("GIVEN"):
      while true:
        var nt: Ref
        if not parseAssign(c, nt): return false
        gs.add nt
        if c.eatS(","): continue
        break
    if not c.eatW("EXPECT"): return false
    if not (c.eatW("ADMITTED") or c.eatW("REJECTED")): return false
    if c.has: return false
    declare(rep, ctx, idt, nkScenario)
    ctx.scns[^1].givens = gs
    ctx.scns[^1].id = idt.text
    if shasDet:
      ctx.dets.add DetRec(kind: "SCENARIO", id: idt.text, idTok: idt, details: sdet.text, detTok: sdet, line: d.first,
        own: sst, piece: ctx.curPiece, hypLine: sHyp.line, hypCol: sHyp.col, lastLine: d.lines[^1])
      if sst != skRat: rep.hyps.add (d.first, "SCENARIO", idt.text)
    return true
  of "GUARANTEE", "ASSUME":
    let tt = d.toks
    var colon = -1
    for i in 1 ..< tt.len:
      if isS(tt[i], ":"):
        colon = i
        break
    var hdrOk = false
    var idTok, detTok, ratTok, hypTok: Tok
    var hasDet = false
    var st = skNone
    var dec = ""
    if colon >= 2 and isIdTok(tt[1]):
      idTok = tt[1]
      var i = 2
      var ok = true
      if i < colon and isW(tt[i], "DETAILS"):
        if i + 1 < colon and isIdTok(tt[i + 1]):
          hasDet = true
          detTok = tt[i + 1]
          i += 2
        else:
          ok = false
      if ok and i < colon and isW(tt[i], "STATUS"):
        let sts = tt[i + 1 ..< colon]
        if sts.len == 1 and isW(sts[0], "HYPOTHESIS"):
          st = skHyp
          hypTok = sts[0]
        elif sts.len >= 1 and isW(sts[0], "RATIFIED"):
          if sts.len == 3 and isW(sts[1], "BY") and isDec(sts[2]):
            st = skRat
            dec = sts[2].text
          else:
            st = skBad
            ratTok = sts[0]
        else:
          ok = false
        i = colon
      hdrOk = ok and i == colon
    # 019:1:5 (F3b, B.1) in un'entità la garanzia ha qualunque STATUS valido per G16, E04 compresa; lo stato effettivo
    # per il punto 4 (STATUS dell'intestazione) è sempre ipotesi: ctx.ratified non diventa mai vero in un'entità
    if not hdrOk:
      rep.grades.add GradeRow(line: d.first, kw: w, id: "?", grade: grUnrec)
      return false
    if st == skBad:
      addErr(rep, ratTok.line, ratTok.col, "E04", testo(kSTATUSRATIFIEDSenzaDecisioneServe))
    declare(rep, ctx, idTok, nkRow)
    if idTok.text notin ctx.rowIds: ctx.rowIds[idTok.text] = ctx.rows.len
    ctx.rows.add RowRec(id: idTok.text, hasDet: hasDet, details: detTok.text, detTok: detTok, idTok: idTok, piece: ctx.curPiece)
    # 022:1:1 (GRAMMATICA_F1 1.15, 7.1 punto 0 e 30): con l'intestazione del blocco non valida (E09)
    # nessuna riga è contratto, CSC o entità, anche con un suo STATUS RATIFIED BY
    let contract = rep.blocks[ctx.bi].headerOk and (st == skRat or (st == skNone and not hasDet and ctx.ratified))
    if not contract: rep.hyps.add (d.first, w, idTok.text)
    rep.rows.add RowInfo(blockIdx: ctx.bi, kw: w, id: idTok.text, line: d.first, lastLine: d.lines[^1],
      contract: contract, idEndCol: (if hasDet: detTok.col + detTok.text.len else: idTok.col + idTok.text.len),
      hypLine: (if st == skHyp: hypTok.line else: 0), hypCol: (if st == skHyp: hypTok.col else: 0),
      ownRatified: st == skRat, detailsOf: (if hasDet: detTok.text else: ""),
      own: st, decision: (if st == skRat: dec else: ""), piece: ctx.curPiece)
    let p = tt[colon + 1 .. ^1]
    let propOk = p.len == 6 and isW(p[0], "VERBAL") and p[1].kind == tkStr and p[1].closed and
      isW(p[2], "VERIFY") and isW(p[3], "BY") and (isW(p[4], "JUDGEMENT") or isW(p[4], "INSPECTION")) and
      p[5].kind == tkStr and p[5].closed
    # 019:1:2 E13 (GRAMMATICA_F1 1.2, 4.5): solo VERBAL e una stringa chiusa, senza altro dopo
    let noVerify = p.len == 2 and isW(p[0], "VERBAL") and p[1].kind == tkStr and p[1].closed
    if noVerify:
      addErr(rep, p[0].line, p[0].col, "E13",
        testo(kVERBALSenzaVERIFYServeVERIFY))
    let isFormula = p.len > 0 and not isW(p[0], "VERBAL")
    rep.grades.add GradeRow(line: d.first, kw: w, id: idTok.text,
      grade: (if propOk or noVerify: grVerbal elif isFormula: grFormal else: grUnrec))
    rep.rows[^1].grade = rep.grades[^1].grade
    if isFormula:
      # 019:1:15 (1.0-beta, G17) la formula si legge alla chiusura del blocco, quando tutti i nomi sono noti
      ctx.pend.add Pend(kind: 0, declFirst: d.first, toks: p, name: idTok.text, nameTok: idTok, isAssume: w == "ASSUME",
        gradeIdx: rep.grades.high, rowIdx: rep.rows.high)
      return true
    return propOk or noVerify
  of "VARIANT":
    # 019:1:8 (1.21, E21) una CSC non ha varianti
    addErr(rep, t0.line, t0.col, "E21", testo(kVARIANTNonPuoStareIn))
    return false
  of "":
    if isS(t0, "@") and ctx.scns.len > 0:
      discard
    else:
      return false
  else:
    return false
  # 019:2:1 Passo di uno scenario (G21)
  if not ctx.inScn or ctx.scns.len == 0: return false
  if not (c.has and isNum1(c.tk)): return false
  let numTok = c.tk
  inc c.p
  var unit = ""
  if c.has and c.tk.kind == tkWord and c.tk.text in ["ms", "s"] and c.tk.line == numTok.line:
    unit = c.tk.text
    inc c.p
  var items: seq[Item]
  var verbal = false
  while c.has:
    if isW(c.tk, "VERBAL"): verbal = true
    if not parseElement(c, s, items): return false
    if c.eatS(","):
      if not c.has: return false
  # 019:2:3 (1.0-beta, 4.11) in una storia tradotta i passi sono asserzioni a parole (VERBAL)
  if ctx.bk == "VERIFICATION" and items.len > 0: return false
  commit(rep, ctx, s)
  var sc = addr ctx.scns[^1]
  if verbal: sc.hasVerbal = true
  for it in items: sc.items.add it
  let has = if unit != "": 1 else: 0
  let text = numTok.text & (if unit != "": " " & unit else: "")
  if sc.unitMode == -1: sc.unitMode = has
  if sc.hasRepeat: inc sc.stepsAfter
  if has != sc.unitMode:
    addErr(rep, t0.line, t0.col, "E12", testo(kPassiConESenzaUnita))
    if sc.hasRepeat and has == 0 and not sc.repUnitErr:
      addErr(rep, sc.repLine, sc.repCol, "E30", testo(kREPEATEVERYVuoleUnaStoria))
      sc.repUnitErr = true
  else:
    if sc.hasRepeat and has == 1 and cmpTime(normTime(numTok.text, unit), sc.repD) >= 0:
      addErr(rep, t0.line, t0.col, "E30", testo(kIlPassoNonEPiu, text, sc.repText))
    let v = normTime(numTok.text, unit)
    if sc.hasMax and cmpTime(v, sc.maxVal) < 0:
      addErr(rep, t0.line, t0.col, "E12", testo(kIlTempoDelPassoDiminuisce, text, sc.maxText))
    elif not sc.hasMax or cmpTime(v, sc.maxVal) > 0:
      sc.hasMax = true
      sc.maxVal = v
      sc.maxText = text
  # 019:2:2 con il defer in testa a handleCsc un `true` finale non fissava result prima del defer; si assegna e basta
  result = true

# 019:3:1 Dichiarazioni dentro un'entità (G31-G34, G16 con GUARANTEE)
proc parseVersionTail(t: seq[Tok], i: int, ver: var string): bool =
  ## 019:3:2 Dal posto i: niente, oppure VERSION e un numero, e basta.
  if i == t.len: return true
  if i + 2 == t.len and isW(t[i], "VERSION") and isUnsigned(t[i + 1]):
    ver = t[i + 1].text
    return true
  false

proc handleEntity(rep: var Report, ctx: var Ctx, d: Decl, wasFirst: bool): bool =
  let t = d.toks
  let t0 = t[0]
  let w = if t0.kind == tkWord: t0.text else: ""
  if wasFirst: rep.blocks[ctx.bi].firstDeclLine = d.first
  # 024:1:1 non c'è più un elenco aperto: una parte è ogni dichiarazione che rispetta G34, dovunque stia
  case w
  of "END", "STATUS", "PURPOSE", "GUARANTEE", "SCENARIO", "IMPORT", "REPEAT":
    if w == "PURPOSE" and ctx.curPiece > 0:
      # 024:1:6 (1.21, E21) lo scopo si scrive prima del primo VARIANT: nel pezzo non è riconosciuto e non conta per E10
      addErr(rep, t0.line, t0.col, "E21", testo(kPURPOSENonPuoStareIn))
      return false
    return handleCsc(rep, ctx, d, wasFirst)
  of "VARIANT":
    # 024:1:7 (1.21, G38) apre un pezzo; scritto male apre comunque un pezzo senza dimensione, con un solo errore
    let ok = t.len == 4 and isName(t[1]) and isS(t[2], "=") and isName(t[3])
    var pc = Piece(line: t0.line, col: t0.col, valid: ok)
    if ok:
      pc.dim = t[1].text
      pc.choice = t[3].text
    rep.blocks[ctx.bi].pieces.add pc
    ctx.curPiece = rep.blocks[ctx.bi].pieces.len
    ctx.composed = false
    if not ok:
      addErr(rep, t0.line, t0.col, "E21", testo(kVARIANTScrittoMaleServeVARIANT))
      return false
    return true
  of "ASSUME", "CAPABILITY", "EVENT", "STATE", "DEFINE", "TYPE":
    # 024:1:3 (1.20, E18) un'entità non ha elementi propri: la dichiarazione resta non riconosciuta, e in più è un errore
    addErr(rep, t0.line, t0.col, "E18", testo(kNonPuoStareInUn, w))
    return false
  of "OFFERS", "USES":
    if t.len < 2 or not isName(t[1]): return false
    var ver = ""
    if not parseVersionTail(t, 2, ver): return false
    let offer = w == "OFFERS"
    # 024:1:4 (1.20, O-5) due righe con lo stesso nome sono ammesse solo se tutte e due scrivono VERSION e le versioni differiscono:
    # il primo conflitto, fra le righe già lette senza E01, dà la riga citata nel messaggio
    var dup = false
    var firstLine = 0
    let prev = if offer: ctx.offerNames.getOrDefault(t[1].text) else: ctx.useNames.getOrDefault(t[1].text)
    for (pv, pl, pp) in prev:
      # 024:1:8 (1.21) il conflitto vale solo fra righe che possono stare nella stessa composizione
      if (pv.len == 0 or ver.len == 0 or pv == ver) and canCoexist(rep.blocks[ctx.bi].pieces, pp, ctx.curPiece):
        dup = true
        firstLine = pl
        break
    if not dup:
      if offer: ctx.offerNames.mgetOrPut(t[1].text, @[]).add (ver, d.first, ctx.curPiece)
      else: ctx.useNames.mgetOrPut(t[1].text, @[]).add (ver, d.first, ctx.curPiece)
    if dup:
      addErr(rep, t[1].line, t[1].col, "E01", dupMsg(firstLine, t[1].text))
    rep.blocks[ctx.bi].cites.add Cite(kind: (if offer: ckOffers else: ckUses), name: t[1].text,
      version: ver, line: d.first, col: t0.col, dup: dup, piece: ctx.curPiece)
    return true
  of "COMPOSED":
    if t.len == 2 and isW(t[1], "OF") and not ctx.composed:
      ctx.composed = true
      return true
    return false
  else:
    if isS(t0, "@") and ctx.scns.len > 0:
      return handleCsc(rep, ctx, d, wasFirst)     # 024:1:5 (1.20) un passo di uno scenario d'entità
    # 024:1:2 G34: Nome ":" Nome [VERSION numero] [Molteplicita] (G35 dalla 1.20); COMPOSED OF compresa
    if isName(t0) and t.len >= 3 and isS(t[1], ":") and isName(t[2]):
      var ver = ""
      var i = 3
      if i < t.len and isW(t[i], "VERSION"):
        if not (i + 1 < t.len and isUnsigned(t[i + 1])): return false
        ver = t[i + 1].text
        i += 2
      var hasMult = false
      var lo, hi, bracket: Tok
      if i < t.len:
        # G35: "[" Numero ".." Numero "]", e nient'altro
        if not (i + 5 == t.len and isS(t[i], "[") and isNum1(t[i + 1]) and isS(t[i + 2], "..") and
            isNum1(t[i + 3]) and isS(t[i + 4], "]")): return false
        hasMult = true
        bracket = t[i]
        lo = t[i + 1]
        hi = t[i + 3]
      # 024:1:9 (1.21) una parte con lo stesso nome di un'altra è E01 solo se le due possono stare insieme; con un id sempre
      var dupLine = 0
      if t0.text in ctx.names:
        if ctx.names[t0.text].kind != nkPart:
          dupLine = ctx.names[t0.text].line
        else:
          for (l, pp) in ctx.partRecs.getOrDefault(t0.text):
            if canCoexist(rep.blocks[ctx.bi].pieces, pp, ctx.curPiece):
              dupLine = l
              break
      let dup = dupLine > 0
      if dup:
        addErr(rep, t0.line, t0.col, "E01", dupMsg(dupLine, t0.text))
      else:
        ctx.partRecs.mgetOrPut(t0.text, @[]).add (d.first, ctx.curPiece)
        if t0.text notin ctx.names: declare(rep, ctx, t0, nkPart)
        else: ctx.nameList.add NameRec(name: t0.text, line: t0.line, kind: NameKindText[ord(nkPart)], piece: ctx.curPiece)
      var cite = Cite(kind: ckPart, part: t0.text, name: t[2].text, version: ver,
        line: d.first, col: t0.col, dup: dup, piece: ctx.curPiece)
      if hasMult:
        # E19 (1.21): due interi con 0 <= m <= n e n >= 1; la parte resta una parte, fissa se i limiti sono sbagliati
        let intOk = isInt(lo) and isInt(hi)
        var good = intOk
        if intOk:
          let a = lo.text.strip(leading = true, trailing = false, chars = {'0'})
          let b = hi.text.strip(leading = true, trailing = false, chars = {'0'})
          if b.len == 0 or cmp(a.len, b.len) > 0 or (a.len == b.len and a > b): good = false
          if good and a.len == 0: cite.optional = true
        if not good:
          addErr(rep, bracket.line, bracket.col, "E19", testo(kLaParteHaUnNumero, t0.text, lo.text, hi.text))
        if intOk:
          cite.hasMult = true
          cite.multMin = lo.text.strip(leading = true, trailing = false, chars = {'0'})
          cite.multMax = hi.text.strip(leading = true, trailing = false, chars = {'0'})
          if cite.multMin.len == 0: cite.multMin = "0"
          if cite.multMax.len == 0: cite.multMax = "0"
      rep.blocks[ctx.bi].cites.add cite
      return true
    return false

# 020:2:1 (1.0-beta, sezione 4.11) BINDING, VERIFICATION, PROFILE ed EXTENSION
const
  KindValues = ["PATTERN", "SCOPE", "FUNCTION", "DECLARATION", "RELATION", "SCENARIO-FORM"]
  LevelValues = ["CSC", "ENTITY", "BINDING", "VERIFICATION"]
  Categories = ["Name", "Type", "Event", "Condition", "Expression", "Duration", "Property"]
  RequiredFields = ["KIND", "LEVEL", "PARAMS", "FORM", "MEANING", "VERIFY", "SOURCE"]

proc extErr(rep: var Report, ctx: Ctx, line, col: int, code, msg: string) =
  addErr(rep, line, col, code, msg)
  rep.blocks[ctx.bi].exts[ctx.extIdx].bad = true

proc closeExt(rep: var Report, ctx: var Ctx) =
  ## 020:2:2 Alla fine di un'estensione: campi mancanti, FORM e PARAMS fra loro (E33)
  let ei = ctx.extIdx
  let nm = rep.blocks[ctx.bi].exts[ei].def.name
  let hdr = rep.blocks[ctx.bi].exts[ei]
  if nm.len > 0 or true:
    let shown = if nm.len > 0: nm else: "?"
    for f in RequiredFields:
      if f notin ctx.extFields:
        extErr(rep, ctx, hdr.line, 0, "E33", testo(kMancaIlCampoNellEXTENSION, f, shown))
    let def = rep.blocks[ctx.bi].exts[ei].def
    if "PARAMS" in ctx.extFields and def.kind == "FUNCTION" and def.result == nil:
      let at = ctx.extFieldToks["PARAMS"][0]
      extErr(rep, ctx, at.line, at.col, "E33", testo(kLEXTENSIONHaKINDFUNCTION, shown))
    if "FORM" in ctx.extFields:
      let at = ctx.extFieldToks["FORM"][0]
      if def.form.len == 0 or def.form[0].text != nm:
        extErr(rep, ctx, at.line, at.col, "E33", testo(kFORMDeveCominciareConIl, shown))
      else:
        for ps in def.params:
          var n = 0
          for k in 1 ..< def.form.len:
            if def.form[k].kind == tkWord and def.form[k].text == ps.name and not isUnitAt(def.form, k): inc n
          if n != 1:
            extErr(rep, ctx, at.line, at.col, "E33", testo(kIlParametroDeveComparireUna, ps.name))
  ctx.inExt = false


proc profileChecks(rep: var Report, bi: int) =
  ## 020:2:3 E35 ed E36: le riduzioni delle estensioni di un profilo (sezione 4.11)
  let pname = if rep.blocks[bi].headerOk: rep.blocks[bi].name else: "?"
  var names = initHashSet[string]()
  for e in rep.blocks[bi].exts:
    if e.def.name.len > 0: names.incl e.def.name
  var norm: seq[(int, string)]
  var edges = initTable[string, seq[string]]()
  var order: seq[string]
  var toks = initTable[string, Tok]()
  # 020:2:4 (1.0-beta, G-13, P5) una REDUCES TO che il lettore delle formule non legge per intero non è riconosciuta: il campo conta
  # come presente (niente E33), l'estensione vale come senza REDUCES TO per il grado dei suoi usi, e E35 ed E36 non la guardano
  var extDefs = initTable[string, ExtDef]()
  for e in rep.blocks[bi].exts:
    if e.def.name.len > 0 and not e.noName: extDefs[e.def.name] = e.def
  for i in 0 ..< rep.blocks[bi].exts.len:
    let e = rep.blocks[bi].exts[i]
    if e.def.name.len == 0 or e.red.len == 0 or e.def.kind.len == 0: continue
    var readable = true
    # un nome che non è del linguaggio, un parametro né un'estensione è E35 (sotto): la riga resta riconosciuta, col suo errore
    var unknownName = false
    block:
      var pn0 = initHashSet[string]()
      for ps in e.def.params: pn0.incl ps.name
      for k, t in e.red:
        if t.kind == tkWord and not isReservedWord(t.text) and t.text notin pn0 and not (t.text in extDefs and t.text != e.def.name) and
            not isUnitAt(e.red, k):
          unknownName = true
    if unknownName: continue
    if e.def.kind == "SCENARIO-FORM":
      var c = Cur(t: e.red, p: 0)
      var sk: Sink
      var items: seq[Item]
      while true:
        if not parseElement(c, sk, items):
          readable = false
          break
        if c.eatS(","):
          if not c.has:
            readable = false
            break
          continue
        break
      if readable and c.has: readable = false
    else:
      var lab = ""
      var pu = false
      readable = readReduction(extDefs, e.def.kind, e.def.level, e.def.params, e.red, lab, pu)
      rep.blocks[bi].exts[i].redPure = pu
      rep.blocks[bi].exts[i].redLabel = lab
    if not readable:
      rep.blocks[bi].exts[i].red = @[]
      rep.blocks[bi].exts[i].def.hasRed = false
      rep.lateUnrec.add (e.redFirst, "")
  for i in 0 ..< rep.blocks[bi].exts.len:
    let e = rep.blocks[bi].exts[i]
    if e.def.name.len == 0 or e.red.len == 0: continue
    var pn = initHashSet[string]()
    for ps in e.def.params: pn.incl ps.name
    var bad = false
    var refs: seq[string]
    for k, t in e.red:
      if t.kind != tkWord: continue
      if isUnitAt(e.red, k): continue          # G-23: l'unità di una durata scritta non è un nome
      if isReservedWord(t.text) or t.text in pn: continue
      if t.text in names and t.text != e.def.name:
        refs.add t.text
        continue
      if not bad:
        addErr(rep, t.line, t.col, "E35", testo(kREDUCESTONominaNonE, t.text, pname))
        rep.blocks[bi].exts[i].bad = true
        bad = true
    order.add e.def.name
    edges[e.def.name] = refs
    toks[e.def.name] = Tok(line: e.line, col: e.col + 10)
    if bad: continue
    # E36: una sola forma del linguaggio, o un solo uso di un'altra estensione, i cui posti sono i soli parametri, ciascuno una volta
    if e.redPure:
      if e.redLabel in names and e.redLabel != e.def.name:
        addErr(rep, e.redLine, e.redCol, "E36", testo(kExtRipeteExt, e.def.name, e.redLabel))
      else:
        addErr(rep, e.redLine, e.redCol, "E36", testo(kLEXTENSIONRipeteUnaForma, e.def.name, e.redLabel))
      rep.blocks[bi].exts[i].bad = true
  var dummy = initTable[string, Tok]()
  cycleErrsExt(rep, order, edges, toks)
  for i in 0 ..< rep.blocks[bi].exts.len:
    rep.blocks[bi].exts[i].def.bad = rep.blocks[bi].exts[i].bad

proc handleExtField(rep: var Report, ctx: var Ctx, d: Decl): bool =
  let t = d.toks
  let t0 = t[0]
  let w = if t0.kind == tkWord: t0.text else: ""
  let ei = ctx.extIdx
  let nm = rep.blocks[ctx.bi].exts[ei].def.name
  let shown = if nm.len > 0: nm else: "?"
  if w == "END" and t.len == 1:
    closeExt(rep, ctx)
    return true
  var fname = w
  if w == "REDUCES": fname = "REDUCES TO"
  if w notin ["KIND", "LEVEL", "PARAMS", "FORM", "MEANING", "VERIFY", "SOURCE", "REDUCES"]: return false
  # la riga deve rispettare la sua regola: si legge prima, e solo dopo si guarda se il campo è ripetuto
  var ok = false
  case w
  of "KIND", "LEVEL":
    ok = t.len == 2 and t[1].kind == tkWord
    if ok:
      let v = t[1].text
      if w == "KIND":
        if v notin KindValues: extErr(rep, ctx, t[1].line, t[1].col, "E33", testo(kValoreDiKINDNonAmmesso, v))
        elif "KIND" notin ctx.extFields: rep.blocks[ctx.bi].exts[ei].def.kind = v
      else:
        if v notin LevelValues: extErr(rep, ctx, t[1].line, t[1].col, "E33", testo(kValoreDiLEVELNonAmmesso, v))
        elif "LEVEL" notin ctx.extFields: rep.blocks[ctx.bi].exts[ei].def.level = v
  of "FORM", "MEANING", "SOURCE":
    ok = t.len == 2 and t[1].kind == tkStr and t[1].closed
    if ok and w == "FORM" and "FORM" notin ctx.extFields:
      let inner = t[1].text[1 ..< t[1].text.len - 1]
      let lx = lex(inner)
      rep.blocks[ctx.bi].exts[ei].def.form = lx.toks
      rep.blocks[ctx.bi].exts[ei].def.formText = inner
  of "REDUCES":
    ok = t.len >= 3 and isW(t[1], "TO")
    if ok and "REDUCES" notin ctx.extFields:
      rep.blocks[ctx.bi].exts[ei].red = t[2 .. ^1]
      rep.blocks[ctx.bi].exts[ei].redLine = t0.line
      rep.blocks[ctx.bi].exts[ei].redCol = t0.col
      rep.blocks[ctx.bi].exts[ei].redFirst = d.first
      rep.blocks[ctx.bi].exts[ei].def.hasRed = true
  of "VERIFY":
    if t.len == 4 and isW(t[1], "BY") and (isW(t[2], "JUDGEMENT") or isW(t[2], "INSPECTION")) and t[3].kind == tkStr and t[3].closed:
      ok = true
    elif t.len >= 3 and isW(t[1], "V1"):
      var i = 2
      var good = true
      while true:
        if not (i < t.len and t[i].kind == tkWord): good = false; break
        let cw = t[i].text
        if cw.len == 2 and cw[0] == 'C' and cw[1] in {'1' .. '8'}: rep.blocks[ctx.bi].exts[ei].def.checks.add cw
        if not (cw.len == 2 and cw[0] == 'C' and cw[1] in {'1' .. '8'}):
          extErr(rep, ctx, t[i].line, t[i].col, "E33", testo(kVERIFYV1NominaUnControllo, cw))
        inc i
        if i < t.len and isS(t[i], ","):
          inc i
          continue
        break
      if good:
        if i < t.len and isS(t[i], ";"):
          if i + 2 == t.len - 0 + 0 and false: discard
          if i + 2 < t.len + 0 and isW(t[i + 1], "V2") and t[i + 2].kind == tkStr and t[i + 2].closed and i + 3 == t.len: ok = true
        elif i == t.len: ok = true
  of "PARAMS":
    var i = 1
    var params: seq[ParamSpec]
    var res: Ty = nil
    var good = i < t.len and isS(t[i], "(")
    if good:
      inc i
      if i < t.len and isS(t[i], ")"): inc i
      else:
        var seen = initHashSet[string]()
        while good:
          if not (i < t.len and isName(t[i])): good = false; break
          let pn = t[i]
          inc i
          if not (i < t.len and isS(t[i], ":")): good = false; break
          inc i
          var ps = ParamSpec(name: pn.text)
          if i < t.len and t[i].kind == tkWord and t[i].text in Categories:
            ps.cat = t[i].text
            if ps.cat == "Duration": ps.ty = tyDur
            inc i
          else:
            var u: seq[Tok]
            let ty = readTy(t, i, u)
            if ty == nil: good = false; break
            ps.ty = ty
          if pn.text in seen:
            addErr(rep, pn.line, pn.col, "E01", dupMsg(d.first, pn.text))
          seen.incl pn.text
          params.add ps
          if i < t.len and isS(t[i], ","):
            inc i
            continue
          if i < t.len and isS(t[i], ")"):
            inc i
            break
          good = false
      if good and i < t.len and isS(t[i], ":"):
        inc i
        var u: seq[Tok]
        res = readTy(t, i, u)
        if res == nil: good = false
    ok = good and i == t.len
    if ok and "PARAMS" notin ctx.extFields:
      rep.blocks[ctx.bi].exts[ei].def.params = params
      rep.blocks[ctx.bi].exts[ei].def.result = res
  else: discard
  if not ok: return false
  if fname in ["REDUCES TO"] and "REDUCES" in ctx.extFields:
    extErr(rep, ctx, t0.line, t0.col, "E33", testo(kCampoREDUCESTORipetutoNell, shown, $ctx.extFields["REDUCES"]))
  elif w in ctx.extFields:
    extErr(rep, ctx, t0.line, t0.col, "E33", testo(kCampoRipetutoNellEXTENSIONIl, w, shown, $ctx.extFields[w]))
  else:
    ctx.extFields[w] = d.first
    ctx.extFieldToks[w] = @[t0]
  true

proc parseElem(t: seq[Tok], i: var int, name, field: var Tok, hasField: var bool): bool =
  ## Elemento = Nome [ "." Nome ]
  if not (i < t.len and isName(t[i])): return false
  name = t[i]
  inc i
  hasField = false
  if i < t.len and isS(t[i], "."):
    inc i
    if not (i < t.len and isName(t[i])): return false
    field = t[i]
    hasField = true
    inc i
  true

proc handleOther(rep: var Report, ctx: var Ctx, d: Decl, wasFirst: bool): bool =
  let t = d.toks
  let t0 = t[0]
  let w = if t0.kind == tkWord: t0.text else: ""
  if wasFirst: rep.blocks[ctx.bi].firstDeclLine = d.first
  if ctx.inExt: return handleExtField(rep, ctx, d)
  case ctx.bk
  of "PROFILE":
    case w
    of "END", "STATUS", "PURPOSE": return handleCsc(rep, ctx, d, wasFirst)
    of "EXTENSION":
      var ei = ExtInfo(line: d.first, col: t0.col)
      var ok = t.len == 2 and t[1].kind == tkWord and '-' notin t[1].text
      if not ok:
        addErr(rep, d.first, t0.col, "E09", testo(kIntestazioneNonValidaAttesaEXTENSION))
      else:
        let nt = t[1]
        ei.def.name = nt.text
        ei.def.profile = rep.blocks[ctx.bi].name
        ei.def.profVersion = rep.blocks[ctx.bi].version
        if isReservedWord(nt.text):
          addErr(rep, nt.line, nt.col, "E34", testo(kIlNomeDellEstensioneE, nt.text))
          ei.bad = true
          ei.def.name = nt.text
          ei.noName = true
        else:
          for e in rep.blocks[ctx.bi].exts:
            if e.def.name == nt.text and not e.noName:
              addErr(rep, nt.line, nt.col, "E34", testo(kNomeDiEstensioneGiaUsato, $e.line, nt.text))
              ei.bad = true
              ei.noName = true
              break
      if ok and not ei.noName and (rep.blocks[ctx.bi].status != skRat or not rep.blocks[ctx.bi].headerOk):
        rep.hyps.add (d.first, "EXTENSION", ei.def.name)
      rep.blocks[ctx.bi].exts.add ei
      ctx.inExt = true
      ctx.extIdx = rep.blocks[ctx.bi].exts.high
      ctx.extFields = initTable[string, int]()
      ctx.extFieldToks = initTable[string, seq[Tok]]()
      return ok
    else: return false
  of "BINDING":
    case w
    of "END", "STATUS", "IMPORT": return handleCsc(rep, ctx, d, wasFirst)
    of "BIND":
      # G51: BIND Elemento [STATUS Stato] ":" VERBAL Stringa
      var i = 1
      var en, ef: Tok
      var hasF = false
      if not parseElem(t, i, en, ef, hasF): return false
      var st = skNone
      var dec = ""
      var hypTok: Tok
      var ratTok: Tok
      if i < t.len and isW(t[i], "STATUS"):
        inc i
        if i < t.len and isW(t[i], "HYPOTHESIS"):
          st = skHyp
          hypTok = t[i]
          inc i
        elif i < t.len and isW(t[i], "RATIFIED"):
          ratTok = t[i]
          inc i
          if i + 1 < t.len and isW(t[i], "BY") and isDec(t[i + 1]):
            st = skRat
            dec = t[i + 1].text
            i += 2
          else:
            st = skBad
        else: return false
      if not (i < t.len and isS(t[i], ":")): return false
      inc i
      if not (i + 2 == t.len and isW(t[i], "VERBAL") and t[i + 1].kind == tkStr and t[i + 1].closed): return false
      if st == skBad: addErr(rep, ratTok.line, ratTok.col, "E04", testo(kSTATUSRATIFIEDSenzaDecisioneServe))
      let shownElem = en.text & (if hasF: "." & ef.text else: "")
      rep.blocks[ctx.bi].binds.add BindRec(elem: en.text, field: (if hasF: ef.text else: ""), line: d.first, col: en.col,
        status: st, decision: dec, hypLine: (if st == skHyp: hypTok.line else: 0), hypCol: (if st == skHyp: hypTok.col else: 0),
        lastLine: d.lines[^1])
      let contract = rep.blocks[ctx.bi].headerOk and (st == skRat or (st == skNone and ctx.ratified))
      if not contract: rep.hyps.add (d.first, "BIND", shownElem)
      return true
    else: return false
  of "VERIFICATION":
    case w
    of "END", "IMPORT", "REPEAT": return handleCsc(rep, ctx, d, wasFirst)
    of "STATUS":
      addErr(rep, t0.line, t0.col, "E39", testo(kSTATUSNonPuoStareIn))
      return true
    of "MEANS":
      # G52: MEANS Nome OBSERVES Elemento {, Elemento} RESOLUTION Numero Unita [USING Nome]
      var i = 1
      if not (i < t.len and isName(t[i])): return false
      let mn = t[i]
      inc i
      if not (i < t.len and isW(t[i], "OBSERVES")): return false
      inc i
      var mr = MeansRec(name: mn.text, line: d.first, col: t0.col)
      while true:
        var en, ef: Tok
        var hasF = false
        if not parseElem(t, i, en, ef, hasF): return false
        mr.obs.add (en.text, (if hasF: ef.text else: ""), en.line, en.col)
        if i < t.len and isS(t[i], ","):
          inc i
          continue
        break
      if not (i < t.len and isW(t[i], "RESOLUTION")): return false
      inc i
      if not (i + 1 < t.len and isNum1(t[i]) and t[i + 1].kind == tkWord and t[i + 1].text in ["ms", "s"]): return false
      i += 2
      if i < t.len and isW(t[i], "USING"):
        inc i
        if not (i < t.len and isName(t[i])): return false
        mr.usingB = t[i].text
        mr.usingLine = t[i].line
        mr.usingCol = t0.col
        inc i
      if i != t.len: return false
      if mn.text in ctx.nameLines:
        addErr(rep, mn.line, mn.col, "E01", dupMsg(ctx.nameLines[mn.text], mn.text))
      else:
        ctx.nameLines[mn.text] = mn.line
      rep.blocks[ctx.bi].means.add mr
      if mr.usingB.len > 0:
        rep.blocks[ctx.bi].xcites.add Cite(kind: ckUsing, name: rep.blocks[ctx.bi].legataName, version: rep.blocks[ctx.bi].legataVer,
          part: mr.usingB, line: d.first, col: t0.col)
      return true
    of "SCENARIO":
      if not (t.len == 4 and isIdTok(t[1]) and isW(t[2], "TRANSLATES") and isIdTok(t[3])): return false
      if t[1].text in ctx.nameLines:
        addErr(rep, t[1].line, t[1].col, "E01", dupMsg(ctx.nameLines[t[1].text], t[1].text))
      else:
        ctx.nameLines[t[1].text] = t[1].line
      ctx.scns[^1].id = t[1].text
      rep.blocks[ctx.bi].trans.add TransRec(id: t[1].text, translates: t[3].text, line: d.first, col: t0.col,
        transLine: t[3].line, transCol: t[3].col)
      return true
    else:
      if isS(t0, "@"): return handleCsc(rep, ctx, d, wasFirst)
      return false
  else: return false

# 020:1:1 Dichiarazioni dentro un blocco ritirato (1.10, sezione 4.8): solo END è riconosciuto
proc handleView(rep: var Report, ctx: var Ctx, d: Decl): bool =
  let t = d.toks
  if t.len == 1 and isW(t[0], "END"):
    closeBlock(rep, ctx, false, d.first)
    return true
  false

proc recount*(rep: var Report) =
  ## 021:1:19 Classifica ogni riga (riconosciuta, commento, vuota, non riconosciuta): una riga in un posto solo
  rep.recLines = 0
  rep.comLines = 0
  rep.blankLines = 0
  rep.unrecLines = 0
  rep.unrecText = @[]
  rep.unrecMotive = initTable[int, string]()
  var late = initTable[int, string]()
  for (first, motive) in rep.lateUnrec: late[first] = motive
  var lateRec = initHashSet[int]()
  for first in rep.lateRec: lateRec.incl first
  for ln in 1 .. rep.total:
    if rep.lineKindArr[ln] == 0:
      inc rep.blankLines
      rep.lineClass[ln - 1] = 'v'
    elif rep.lineKindArr[ln] == 1:
      inc rep.comLines
      rep.lineClass[ln - 1] = 'c'
  for (first, lines, ok0) in rep.declData:
    rep.spans[first] = lines[^1]
    let ok = (ok0 or first in lateRec) and first notin late
    if ok:
      rep.recLines += lines.len
      for ln in lines: rep.lineClass[ln - 1] = 'r'
    else:
      rep.unrecLines += lines.len
      if first in late and late[first].len > 0: rep.unrecMotive[first] = late[first]
      for ln in lines: rep.lineClass[ln - 1] = 'n'
      for ln in lines:
        var tx = rep.srcLines[ln - 1].strip(chars = {' ', '\t'})
        if ln == first and first in rep.unrecMotive: tx.add " (" & rep.unrecMotive[first] & ")"
        rep.unrecText.add (ln, tx)

# 021:1:15 (1.0-beta, U5) Le parole che aprono sempre una dichiarazione, e il segno `@`, non continuano mai la precedente
const U5Openers = ["CSC", "ENTITY", "REFINEMENT", "BINDING", "VERIFICATION", "PROFILE", "EXTENSION", "END", "STATUS",
  "IMPORT", "PURPOSE", "TYPE", "CAPABILITY", "EVENT", "STATE", "DEFINE", "GUARANTEE", "ASSUME", "SCENARIO", "REPEAT",
  "OFFERS", "USES", "COMPOSED", "VARIANT", "BIND", "MEANS", "KIND", "LEVEL", "PARAMS", "FORM", "MEANING", "REDUCES",
  "SOURCE"]
const U5Syms = [":", ",", ":=", "=", "<>", "<", "<=", ">", ">=", "+", "-", "*", "/", "^", "->", ";"]
const U5Words = ["THEN", "WITHIN", "AND", "OR", "IMPLIES", "NOT", "IN"]

proc declIsOpen(d: Decl): bool =
  ## 021:1:16 (U5) Una parentesi `(`, `[` o `{` non chiusa, oppure l'ultimo elemento chiede un seguito.
  var depth = 0
  for t in d.toks:
    if t.kind == tkSym:
      if t.text in ["(", "[", "{"]: inc depth
      elif t.text in [")", "]", "}"]: dec depth
  if depth > 0: return true
  let l = d.toks[^1]
  (l.kind == tkSym and l.text in U5Syms) or (l.kind == tkWord and l.text in U5Words)

# 021:1:1 Analisi di un testo intero
proc analyze*(srcRaw: string): Report =
  gDeferred = @[]
  let src = normalizeSource(srcRaw)
  let lx = lex(src)
  let total = lx.lines.len
  result.total = total
  result.srcLines = lx.lines
  result.lineClass = newSeq[char](total)
  # 021:1:2 Divisione in dichiarazioni (U1-U4): ogni riga finisce in un posto solo
  var decls: seq[Decl]
  var lineKind = newSeq[int](total + 1)     # 0 vuota, 1 commento, 2 dichiarazione
  var ti = 0
  for ln in 1 .. total:
    let startTi = ti
    while ti < lx.toks.len and lx.toks[ti].line == ln: inc ti
    if lx.inStr[ln]:
      lineKind[ln] = 2
      decls[^1].lines.add ln
      for k in startTi ..< ti: decls[^1].toks.add lx.toks[k]
    elif startTi == ti:
      lineKind[ln] = if lx.lines[ln - 1].strip(chars = {' ', '\t'}).len == 0: 0 else: 1
    else:
      lineKind[ln] = 2
      let f = lx.toks[startTi]
      var cont = false
      if decls.len > 0 and f.kind == tkWord and (f.text == "VERBAL" or f.text == "VERIFY"):
        let p0 = decls[^1].toks[0]
        cont = p0.kind == tkWord and (p0.text == "GUARANTEE" or p0.text == "ASSUME")
      elif decls.len > 0 and not (f.kind == tkSym and f.text == "@") and
          not (f.kind == tkWord and f.text in U5Openers):
        # 021:1:14 (1.0-beta, U5, C-02) una dichiarazione rimasta aperta continua sulla riga dopo
        cont = declIsOpen(decls[^1])
      if cont:
        decls[^1].lines.add ln
      else:
        decls.add Decl(first: ln, lines: @[ln])
      for k in startTi ..< ti: decls[^1].toks.add lx.toks[k]
  # 021:1:3 Lettura delle dichiarazioni nel loro blocco
  var ctx = Ctx()
  var fileNames = initTable[string, int]()
  var recog = newSeq[bool](decls.len)
  var unreadDecl = newSeq[bool](decls.len)
  var strayDepth = 0              # (1.0-beta, E32) dentro un'EXTENSION fuori da un PROFILE: righe non riconosciute fino al suo END
  var strayTok: Tok
  var strayName = "?"
  for di, d in decls:
    let t0 = d.toks[0]
    let w = if t0.kind == tkWord: t0.text else: ""
    if strayDepth > 0:
      if d.toks.len == 1 and isW(t0, "END"):
        strayDepth = 0
        continue
      elif w in BlockWords:
        addErr(result, strayTok.line, 0, "E07", testo(kBloccoNonChiusoMancaEND2, strayName))
        strayDepth = 0
      else:
        continue
    if w == "EXTENSION" and not (ctx.open and ctx.bk == "PROFILE" and not ctx.inExt):
      if ctx.open and ctx.inExt:
        recog[di] = false      # un'EXTENSION dentro un'estensione: non riconosciuta
        continue
      # 021:1:18 (1.0-beta, E32) un'EXTENSION fuori da un PROFILE apre un blocco che non è di nessuno
      addErr(result, d.first, t0.col, "E32", testo(kEXTENSIONFuoriDaUnPROFILE))
      strayDepth = 1
      strayTok = t0
      strayName = if d.toks.len > 1 and isName(d.toks[1]): d.toks[1].text else: "?"
      if ctx.open:
        if ctx.first: result.blocks[ctx.bi].firstDeclLine = d.first
        ctx.first = false
        ctx.zone = false
        ctx.inScn = false
      continue
    if w in BlockWords:
      if ctx.open: closeBlock(result, ctx, true, d.first - 1)
      openBlock(result, ctx, fileNames, d)
      recog[di] = result.blocks[^1].headerOk and w != "REFINEMENT"     # 021:1:5 (1.10) la dichiarazione di un blocco ritirato non è riconosciuta
    elif not ctx.open:
      if w == "END" and d.toks.len == 1:
        addErr(result, d.first, t0.col, "E08", testo(kENDSenzaUnBloccoAperto))
      recog[di] = false
    else:
      let wasFirst = ctx.first
      ctx.first = false
      # 021:1:13 (1.23, 4.2) la zona d'intestazione dura finché le dichiarazioni cominciano con STATUS, PURPOSE o IMPORT
      if not (w == "STATUS" or w == "PURPOSE" or w == "IMPORT"): ctx.zone = false
      if ctx.isView:
        recog[di] = handleView(result, ctx, d)
      elif ctx.bk in ["BINDING", "VERIFICATION", "PROFILE"]:
        if w == "SCENARIO":
          ctx.inScn = true
          ctx.scns.add Scn(unitMode: -1, piece: ctx.curPiece)
        elif not isS(t0, "@") and w != "REPEAT":
          ctx.inScn = false
        recog[di] = handleOther(result, ctx, d, wasFirst)
      else:
        # 021:1:6 (1.20) gli scenari valgono anche nelle entità: lo stato dello scenario aperto sta nel contesto del blocco
        if w == "SCENARIO":
          ctx.inScn = true
          ctx.scns.add Scn(unitMode: -1, piece: ctx.curPiece)
        elif not isS(t0, "@") and w != "REPEAT":
          ctx.inScn = false
        if ctx.isEntity:
          recog[di] = handleEntity(result, ctx, d, wasFirst)
          # 021:1:7 (1.21) un pezzo VARIANT conta le dichiarazioni riconosciute, escluse COMPOSED OF e il suo VARIANT
          if recog[di] and ctx.open and ctx.curPiece > 0 and w != "COMPOSED" and w != "VARIANT":
            inc result.blocks[ctx.bi].pieces[ctx.curPiece - 1].count
        else:
          recog[di] = handleCsc(result, ctx, d, wasFirst)
      # 021:1:20 (1.0-beta, P1-a) una dichiarazione non riconosciuta che comincia con un nome può essere l'uso di un'estensione di
      # KIND DECLARATION: i profili si cercano alla chiusura (finishAll), che la riconosce o la lascia com'è
      if not recog[di] and ctx.open and not ctx.isView and ctx.bk != "PROFILE" and t0.kind == tkWord and isName(t0):
        ctx.extCands.add d
  if strayDepth > 0:
    addErr(result, strayTok.line, 0, "E07", testo(kBloccoNonChiusoMancaEND2, strayName))
  if ctx.open: closeBlock(result, ctx, true, total)
  if lx.unclosedLine > 0:
    addErr(result, lx.unclosedLine, 0, "E06", testo(kStringaNonChiusaIlFile))
  if not result.hasCsc:
    addErr(result, 0, 0, "E11", testo(kIlFileNonContieneNessuna))
  # 021:1:17 (1.0-beta) i conteggi si rifanno (recount) anche dopo il controllo delle formule, che può scoprire righe non riconosciute
  result.lineKindArr = lineKind
  for di, d in decls: result.declData.add (d.first, d.lines, recog[di])
  recount(result)
  result.errs.sort(proc(a, b: Err): int =
    result = cmp(a.line, b.line)
    if result == 0: result = cmp(a.col, b.col)
    if result == 0: result = cmp(a.code, b.code)
    if result == 0: result = cmp(a.seqno, b.seqno))

# 021:2:1 Ricerca delle citazioni delle entità e controllo degli usi (B.4.3)
type
  LoadState = enum
    lsMissing, lsNotFile, lsUnreadable, lsNotUtf8, lsOk

  Loaded = object
    state: LoadState
    rep: Report
    raw: string

proc statusText(b: BlockInfo): string =
  case b.status
  of skNone: testo(kSenzaSTATUS)
  of skHyp: "STATUS HYPOTHESIS"
  of skRat: "STATUS RATIFIED BY " & b.decision
  of skBad: testo(kSTATUSNonValido)

proc statusCode*(b: BlockInfo): string =
  ## 021:1:21 Il codice dello stato del blocco, uguale in ogni lingua (i valori di `blocchi[].stato`).
  case b.status
  of skNone: "senza_stato"
  of skHyp: "ipotesi"
  of skRat: "contratto"
  of skBad: "non_valido"

proc finishAll*(rep: var Report, fileArg: string, dirs: seq[string], search: bool)

proc symGenreOf(s: Sym): string =
  case s.kind
  of sCap: "CAPABILITY"
  of sEvent, sDefEvent: "EVENT"
  of sState: "STATE"
  else: "?"

proc loadCandidate(path: string): Loaded =
  ## 021:2:2 Un candidato `N.csc`: lo si legge soltanto, mai lo si scrive (g-c1).
  # 021:2:2a W-R7: su Windows un nome di dispositivo non si apre mai (leggerebbe il dispositivo): vale «non esiste»
  when defined(windows):
    if isDeviceName(extractFilename(path)):
      result.state = lsMissing
      return
  let st = pathInfo(path)
  if not st.ok:
    result.state = if st.absent: lsMissing else: lsUnreadable
    return
  # 021:2:2b W-R6: il nome sul disco è esattamente quello scritto, come su Linux (su Linux sempre vero)
  if not nameIsExact(path):
    result.state = lsMissing
    return
  if not st.isFile:
    result.state = lsNotFile
    return
  var raw: string
  try:
    raw = readFile(path)
  except IOError, OSError:
    result.state = lsUnreadable
    return
  if firstInvalidUtf8(raw) >= 0:
    result.state = lsNotUtf8
    return
  result.state = lsOk
  result.rep = analyze(raw)
  finishAll(result.rep, "", @[], false)
  result.raw = raw

proc findBlock(r: Report, bk: string, name: string, own = ""): int =
  for i, b in r.blocks:
    if b.bk == bk and b.headerOk and b.name == name and (bk != "BINDING" or b.ownName == own): return i
  -1

proc foundFrom(r: Report, bi: int, where: string, path = ""): Found =
  let b = r.blocks[bi]
  result = Found(searched: true, ok: true, where: where, path: path, line: b.line, version: b.version,
    statusText: statusText(b), statoBlocco: statusCode(b), errCount: r.errs.len, unrec: r.unrecLines, pieces: b.pieces, blk: b)
  for c in b.cites:
    if c.dup: continue                    # (1.3) una riga con E01 non offre e non chiede niente
    if c.piece > 0 and not b.pieces[c.piece - 1].valid: continue     # (1.21) le righe di un VARIANT scritto male non offrono né usano
    if c.kind == ckOffers: result.offers.add c
    elif c.kind == ckUses: result.uses.add c
  for n in b.names:                       # (1.20) gli elementi di una CSC, per i nomi qualificati degli scenari d'entità
    if n.kind in ["CAPABILITY", "EVENT", "STATE"]:
      result.elems[n.name] = (n.kind, b.declParams.getOrDefault(n.name))

proc sameVersion(request, other: string): bool =
  ## (1.3) Non simmetrica: la richiesta senza versione combacia con tutto, con versione solo con la stessa.
  request.len == 0 or request == other

var gNoExternal = false

proc searchCite(self: Report, fileArg: string, dirs: seq[string], c: Cite,
    cache: var Table[string, Loaded]): Found =
  ## 021:2:3 Stesso file, poi `N.csc` nella cartella del percorso scritto, poi nelle cartelle --dir.
  ## (1.20, O-5) Un blocco con un'altra versione di quella chiesta è un ripiego, il primo: la ricerca va avanti.
  let bkind = case c.kind
    of ckPart: "ENTITY"
    of ckImport: "PROFILE"
    of ckUsing: "BINDING"
    else: "CSC"
  let own = if c.kind == ckUsing: c.part else: ""
  var fallback = Found()
  var hasFallback = false
  let si = findBlock(self, bkind, c.name, own)
  if si >= 0:
    let f = foundFrom(self, si, "")
    if c.version.len == 0 or c.version == f.version: return f
    fallback = f
    fallback.viaFallback = true
    hasFallback = true
  result.searched = true
  if gNoExternal:
    if hasFallback: return fallback
    return
  var cands: seq[(string, string)]
  let folder = folderOfArg(fileArg)      # W-R5: la cartella del percorso scritto, con le regole del sistema
  cands.add (folder & c.name & ".csc", c.name & ".csc")
  for d in dirs:
    let shown = joinShown(d, c.name & ".csc")          # W-R4
    cands.add (shown, shown)
  let what = (if bkind == "ENTITY": "ENTITY " elif bkind == "PROFILE": "PROFILE " elif bkind == "BINDING": "BINDING " else: "CSC ") & c.name
  var firstMiss = ""
  proc stop(r: string): Found =
    ## un candidato che ferma la ricerca la ferma anche con un ripiego: la citazione è trovata nel ripiego
    if hasFallback: return fallback
    Found(searched: true, reason: r)
  for (path, shown) in cands:
    if path notin cache: cache[path] = loadCandidate(path)
    let l = cache[path]
    case l.state
    of lsMissing: continue
    of lsNotFile: return stop(testo(kNonEUnFile, shown))
    of lsUnreadable: return stop(testo(kNonLeggibile, shown))
    of lsNotUtf8: return stop(testo(kNonUtf8Citazione, shown))
    of lsOk:
      let bi = findBlock(l.rep, bkind, c.name, own)
      if bi >= 0:
        var f = foundFrom(l.rep, bi, shown, path)
        # 021:2:9 (F3b, B.3.2) le righe del blocco trovato, dall'intestazione all'END, senza BOM e con LF
        let ls = splitLinesLf(normalizeSource(l.raw))
        let b = l.rep.blocks[bi]
        var tl: seq[string]
        for n in b.line .. min(b.endLine, ls.len): tl.add ls[n - 1]
        f.blockText = tl.join("\n")
        if c.version.len == 0 or c.version == f.version: return f
        if not hasFallback:
          fallback = f
          fallback.viaFallback = true
          hasFallback = true
        continue
      if firstMiss.len == 0: firstMiss = testo(kNonContiene, shown, what)
  if hasFallback: return fallback
  result.reason = firstMiss


# 021:3:1 (1.0-beta) Il controllo di formule, nomi, tipi, profili e forme concrete, quando tutte le citazioni si possono cercare
proc elemShown(e: string, f: string): string = (if f.len > 0: e & "." & f else: e)

proc finishAll*(rep: var Report, fileArg: string, dirs: seq[string], search: bool) =
  if rep.finished: return
  rep.finished = true
  let deferred = gDeferred
  gDeferred = @[]
  let savedNoExt = gNoExternal
  gNoExternal = not search
  var cache = initTable[string, Loaded]()
  let self = rep
  # 1. le citazioni dei blocchi: profili importati, CSC legata, BINDING di USING
  for bi in 0 ..< rep.blocks.len:
    let b = self.blocks[bi]
    var cs: seq[Cite]
    for c in b.importCites: cs.add c
    if b.bk in ["BINDING", "VERIFICATION"] and b.headerOk:
      cs.add Cite(kind: ckLegata, name: b.legataName, version: b.legataVer, line: b.line, col: 0)
    for c in b.xcites: cs.add c
    cs.sort(proc(x, y: Cite): int = cmp(x.line, y.line))
    var fs: seq[Found]
    for c in cs:
      var f = searchCite(self, fileArg, dirs, c, cache)
      # un profilo si trova solo con la versione scritta: un ripiego non è trovato (sezione 4.2)
      if c.kind == ckImport and f.ok and f.viaFallback:
        f = Found(searched: true, reason: testo(kTrovataSoloVersion, f.version, (if f.where.len == 0: testo(kQuestoFile) else: f.where)))
      fs.add f
    rep.blocks[bi].xcites = cs
    rep.blocks[bi].xfound = fs
    for k, c in cs:
      if fs[k].ok: continue
      case c.kind
      of ckImport: rep.notFound.add NonControllata(line: c.line, tipo: "IMPORT", nome: c.name, motivo: fs[k].reason)
      of ckLegata: rep.notFound.add NonControllata(line: c.line, tipo: "LEGATA", nome: c.name, motivo: fs[k].reason)
      of ckUsing: rep.notFound.add NonControllata(line: c.line, tipo: "USING", nome: c.name, parte: c.part, motivo: fs[k].reason)
      else: discard
  # 2. controlli di nomi e tipi, con le estensioni dei profili importati
  for dctx in deferred:
    var ctx = dctx
    let bi = ctx.bi
    let b = rep.blocks[bi]
    var k0 = 0
    for k, c in rep.blocks[bi].xcites:
      if c.kind != ckImport: continue
      let f = rep.blocks[bi].xfound[k]
      if not f.ok:
        if ctx.env.pnf.len == 0: ctx.env.pnf = testo(kProfiloVERSIONNonTrovato, c.name, c.version)
        continue
      for ei in f.blk.exts:
        if ei.def.name.len == 0 or ei.noName: continue
        if ei.bad:
          ctx.env.badExt[ei.def.name] = testo(kEXTENSIONDelPROFILEConErrori, ei.def.name, c.name)
        else:
          var d = ei.def
          d.profRatified = f.blk.status == skRat and f.blk.headerOk
          ctx.env.exts[ei.def.name] = d
    inc k0
    # 021:2:21 (1.0-beta, P1-a, 4.14) gli usi di KIND DECLARATION: la riga è riconosciuta, il nome dichiarato entra nei nomi del blocco
    for d in ctx.extCands:
      let du = declUse(ctx.env, d.toks)
      if not du.isUse: continue
      rep.lateRec.add d.first
      for e in du.errs: addErr(rep, e.line, e.col, e.code, e.msg)
      if du.hasName: declare(rep, ctx, du.name, nkExtName)
    runPending(rep, ctx)
  # 3. E31, E38, forme concrete, copertura
  for bi in 0 ..< rep.blocks.len:
    let b = rep.blocks[bi]
    if b.bk notin ["BINDING", "VERIFICATION"] or not b.headerOk: continue
    var leg = Found()
    var legOk = false
    for k, c in b.xcites:
      if c.kind == ckLegata and b.xfound[k].ok and not b.xfound[k].viaFallback:
        leg = b.xfound[k]
        legOk = true
        if leg.where.len == 0:
          # lo stesso file: i dati dei controlli (righe, simboli) sono quelli di dopo la chiusura dei blocchi
          for q in rep.blocks:
            if q.line == leg.line and q.bk == "CSC": leg.blk = q
    var legAny = false
    for k, c in b.xcites:
      if c.kind == ckLegata and b.xfound[k].ok: legAny = true
    if legOk:
      let lb = leg.blk
      let shown = "CSC " & b.legataName & " VERSION " & b.legataVer
      proc elemOk(e, f: string): bool =
        for el in lb.elems:
          if el.name == e:
            if f.len == 0: return true
            if e in lb.syms and lb.syms[e].kind in {sEvent, sCap}:
              for (pn, _) in lb.syms[e].params:
                if pn == f: return true
            return false
        false
      for br in b.binds:
        if not elemOk(br.elem, br.field):
          addErr(rep, br.line, br.col, "E31", testo(kNonEUnElementoDella, elemShown(br.elem, br.field), shown))
      for mr in b.means:
        for (e, f, l, c) in mr.obs:
          if not elemOk(e, f): addErr(rep, l, c, "E31", testo(kNonEUnElementoDella, elemShown(e, f), shown))
      for tr in b.trans:
        if tr.translates notin lb.scenarioIds:
          addErr(rep, tr.transLine, tr.transCol, "E31", testo(kTRANSLATESNominaUnaStoriaChe, shown, tr.translates))
      # E38: stesso profilo con un'altra versione
      for im in b.imports:
        if im.ignored: continue
        for lim in lb.imports:
          if lim.name == im.name and lim.version != im.version and not lim.ignored:
            addErr(rep, im.line, im.col, "E38", testo(kPROFILEImportatoConVERSIONMa, im.name, im.version, b.legataName, lim.version))
    # sezione 12
    if b.bk == "BINDING":
      let head = "BINDING " & b.name & " VERSION " & b.version & (if b.ownName.len > 0: " AS " & b.ownName else: "")
      if legOk:
        var miss: seq[string]
        for el in leg.blk.elems:
          if el.kw notin ["STATE", "EVENT IN", "EVENT OUT", "CAPABILITY"]: continue
          var named = false
          for br in b.binds:
            if br.elem == el.name and br.field.len == 0: named = true
          if not named: miss.add el.kw & " " & el.name
        rep.forme.add FormaMancante(line: b.line, head: head, cscTrovata: true, elementi: miss)
        rep.nonEsegFormeCount += miss.len
      else:
        rep.forme.add FormaMancante(line: b.line, head: head, cscTrovata: false)
    # sezione 13
    if b.bk == "VERIFICATION":
      var cov = Copertura(line: b.line, head: "VERIFICATION " & b.name & " VERSION " & b.version, cscTrovata: legOk)
      if legOk:
        let lb = leg.blk
        # i nomi nominati da ogni riga, con le DEFINE espanse
        proc expand(us: seq[string]): HashSet[string] =
          var res = initHashSet[string]()
          var stack = us
          while stack.len > 0:
            let n = stack.pop()
            if n in res: continue
            res.incl n
            if n in lb.defUsed:
              for m in lb.defUsed[n]: stack.add m
          res
        var covered = initHashSet[string]()
        for mr in b.means:
          var obs = initHashSet[string]()
          for (e, f, l, c) in mr.obs: obs.incl e
          var ids: seq[string]
          for lr in lb.legRows:
            if lr.grade notin {grFormal, grExt}: continue
            var all = true
            for n in expand(lr.used):
              if n in lb.syms and lb.syms[n].kind in {sState, sEvent, sDefEvent, sCap}:
                if n notin obs: all = false
            if all and lr.used.len > 0: ids.add lr.id
            elif all: ids.add lr.id
          for i in ids: covered.incl i
          cov.mezzi.add CopMezzo(name: mr.name, line: mr.line, promesse: ids)
        var non: seq[string]
        for lr in lb.legRows:
          if lr.grade in {grFormal, grExt} and lr.id notin covered: non.add lr.id
        cov.nonEseguite = non
        rep.nonEseguite += non.len
      rep.copertura.add cov
  # 4. sezioni 14 e 15
  var storie, inn, coer, dett: seq[int]
  for bi in 0 ..< rep.blocks.len:
    let b = rep.blocks[bi]
    if b.bk notin ["CSC", "ENTITY"]: continue
    var anyFormal = false
    for r in rep.rows:
      # 9.7: le storie dei blocchi con almeno una promessa o un presupposto formale, o di estensione dichiarata con C3
      if r.blockIdx == bi and (r.grade == grFormal or (r.grade == grExt and "C3" in r.extChecks)): anyFormal = true
    if anyFormal:
      for n in b.names:
        if n.kind == "SCENARIO": storie.add n.line
  for r in rep.rows:
    if r.grade == grFormal:
      coer.add r.line
      if r.trigger: inn.add r.line
    elif r.grade == grExt:
      # 9.7: una riga di estensione dichiarata entra nei controlli che il VERIFY V1 dell'estensione nomina
      if "C2" in r.extChecks: coer.add r.line
      if "C4" in r.extChecks: inn.add r.line
    if r.detailsOf.len > 0:
      var parentGrade = grUnrec
      for q in rep.rows:
        if q.blockIdx == r.blockIdx and q.id == r.detailsOf: parentGrade = q.grade
      let verbal = r.grade == grVerbal or parentGrade == grVerbal
      if verbal:
        rep.daGiudicare.add (r.line, testo(kVoceCoerenzaDettaglio, r.kw, r.id, r.detailsOf))
      elif r.grade in {grFormal, grExt} and parentGrade in {grFormal, grExt}:
        dett.add r.line
  # 9.7 (P3): i dettagli di DEFINE e di storie. Una DEFINE non è mai a parole; una storia lo è se ha un passo VERBAL.
  for r in rep.detRows:
    if rep.blocks[r.blockIdx].bk notin ["CSC", "ENTITY"]: continue
    if r.detVerbalSelf or r.detVerbalPar:
      rep.daGiudicare.add (r.line, testo(kVoceCoerenzaDettaglio, r.kw, r.id, r.detailsOf))
    elif r.detParentKnown:
      dett.add r.line
  for bi in 0 ..< rep.blocks.len:
    if rep.blocks[bi].bk != "PROFILE": continue
    for e in rep.blocks[bi].exts:
      if e.def.name.len == 0 or e.bad: continue
      rep.daGiudicare.add (e.line, testo(kVoceExtMeaning, e.def.name))
      if e.def.hasRed:
        rep.daGiudicare.add (e.line, testo(kVoceExtMeaningRiduce, e.def.name))
      else:
        rep.daGiudicare.add (e.line, testo(kVoceExtNonRipete, e.def.name))
  # stabile per riga (l'ordine nella tabella resta sulla stessa riga)
  let dgs = rep.daGiudicare
  var idxd = newSeq[int](dgs.len)
  for i in 0 ..< idxd.len: idxd[i] = i
  idxd.sort(proc(a, b: int): int =
    result = cmp(dgs[a][0], dgs[b][0])
    if result == 0: result = cmp(a, b))
  var sorted: seq[(int, string)]
  for i in idxd: sorted.add dgs[i]
  rep.daGiudicare = sorted
  storie.sort(); inn.sort(); coer.sort(); dett.sort()
  if storie.len > 0: rep.nonEseg.add ("storie", storie)
  if inn.len > 0: rep.nonEseg.add ("copertura_inneschi", inn)
  if coer.len > 0: rep.nonEseg.add ("coerenza_presupposti_promesse", coer)
  if dett.len > 0: rep.nonEseg.add ("coerenza_dettagli", dett)
  gNoExternal = savedNoExt
  recount(rep)
  block:
    let h0 = rep.hyps
    var ord = newSeq[int](h0.len)
    for i in 0 ..< ord.len: ord[i] = i
    ord.sort(proc(a, b: int): int =
      result = cmp(h0[a][0], h0[b][0])
      if result == 0: result = cmp(a, b))
    rep.hyps = @[]
    for i in ord: rep.hyps.add h0[i]
  rep.notFound.sort(proc(a, b: NonControllata): int = cmp(a.line, b.line))
  rep.errs.sort(proc(a, b: Err): int =
    result = cmp(a.line, b.line)
    if result == 0: result = cmp(a.col, b.col)
    if result == 0: result = cmp(a.code, b.code)
    if result == 0: result = cmp(a.seqno, b.seqno))

# 021:2:11 Le composizioni di un'entità e la chiusura in ognuna
type
  Dim = object
    name: string
    line: int
    choices: seq[string]

  FacKind = enum
    fkDim, fkOpt, fkPartDim

  Fac = object
    ## un fattore: una cosa che si sceglie componendo (sezione 4.10)
    kind: FacKind
    line, sub, ord: int
    vals: seq[string]
    cite: int                  # indice della riga di parte in b.cites (fkOpt, fkPartDim), -1 per fkDim
    gPiece: int                # il fattore esiste solo se questo pezzo è scelto (0 nessuno)
    gOpt: bool                 # il fattore esiste solo se la parte facoltativa c'è
    gDim, gCh: int             # (risolti dopo l'ordinamento) fattore-dimensione e scelta richiesti, -1 se nessuno
    gOptFac: int               # (risolto) fattore opzionale richiesto, -1 se nessuno
    dimName: string            # fkDim, fkPartDim: la dimensione

  ErrRec = object
    line, col: int
    code, msg: string

proc dimsOf(ps: seq[Piece]): seq[Dim] =
  ## 021:2:12 Le dimensioni dei pezzi validi, nell'ordine della prima riga; le scelte nell'ordine della prima comparsa.
  for p in ps:
    if not p.valid: continue
    var k = -1
    for i, d in result:
      if d.name == p.dim: k = i
    if k < 0:
      result.add Dim(name: p.dim, line: p.line)
      k = result.high
    if p.choice notin result[k].choices: result[k].choices.add p.choice

proc errKey(e: ErrRec): string = e.code & "|" & $e.line & "|" & $e.col & "|" & e.msg

proc suffixFor(facs: seq[Fac], comps: seq[seq[int]], universe: seq[int], S: seq[int]): string =
  ## 021:2:13 (GRAMMATICA_F1 9.5) Il suffisso `(in: …)` senza parentesi: "" se S è tutto l'universo.
  if S.len == universe.len: return ""
  var inS = initHashSet[int]()
  for i in S: inS.incl i
  for f in 0 ..< facs.len:
    for v in 0 ..< facs[f].vals.len:
      var cnt = 0
      var all = true
      for j in universe:
        if comps[j][f] == v:
          inc cnt
          if j notin inS: all = false
      if all and cnt == S.len: return facs[f].vals[v]
  var names: seq[string]
  for i in S:
    var parts: seq[string]
    for f in 0 ..< facs.len:
      if comps[i][f] >= 0: parts.add facs[f].vals[comps[i][f]]
    names.add parts.join(", ")
  names.join("; ")

proc closeEntity(rep: var Report, bi: int) =
  let b = rep.blocks[bi]
  let eName = if b.headerOk: b.name else: "?"
  # un VARIANT scritto male: l'entità non ha composizioni, quindi nessuna chiusura (sezione 4.10)
  for p in b.pieces:
    if not p.valid: return
  var parts: seq[int]                   # indici in b.cites delle parti non duplicate
  var unfound = 0
  for k, c in b.cites:
    if c.kind == ckPart and not c.dup:
      parts.add k
      if not b.found[k].ok: inc unfound
  let dims = dimsOf(b.pieces)
  var partDims = newSeq[seq[Dim]](b.cites.len)
  for k in parts:
    if b.found[k].ok: partDims[k] = dimsOf(b.found[k].pieces)
  # 021:2:14 Il conto delle composizioni, senza elencarle: si ferma appena supera 64 (E23)
  const Cap = 65
  proc satMul(a, c: int): int = min(a * c, Cap)
  proc satAdd(a, c: int): int = min(a + c, Cap)
  proc partMult(k: int): int =
    var d = 1
    for pd in partDims[k]: d = satMul(d, pd.choices.len)
    if b.cites[k].optional: satAdd(1, d) else: d
  var total = 1
  for k in parts:
    if b.cites[k].piece == 0: total = satMul(total, partMult(k))
  for d in dims:
    var sum = 0
    for ch in d.choices:
      var prod = 1
      for k in parts:
        let pc = b.cites[k].piece
        if pc > 0 and b.pieces[pc - 1].dim == d.name and b.pieces[pc - 1].choice == ch: prod = satMul(prod, partMult(k))
      sum = satAdd(sum, prod)
    total = satMul(total, sum)
  if total > 64:
    rep.comps.add CompInfo(line: b.line, name: eName, tooMany: true)
    addErr(rep, b.line, 0, "E23", testo(kLEntitaHaPiuDi, eName))
    for cand in b.e20:
      if cand.never: addErr(rep, cand.line, cand.col, "E20", cand.msg)
    return
  # 021:2:15 I fattori, in ordine di riga; poi le composizioni in ordine lessicografico
  var facs: seq[Fac]
  var ordn = 0
  for d in dims:
    var vals: seq[string]
    for ch in d.choices: vals.add d.name & " = " & ch
    facs.add Fac(kind: fkDim, line: d.line, sub: 0, ord: ordn, vals: vals, cite: -1, dimName: d.name)
    inc ordn
  for k in parts:
    let c = b.cites[k]
    if c.optional:
      facs.add Fac(kind: fkOpt, line: c.line, sub: 0, ord: ordn, vals: @[testo(kCompCon, c.part), testo(kCompSenza, c.part)], cite: k, gPiece: c.piece)
      inc ordn
    for j, pd in partDims[k]:
      var vals: seq[string]
      for ch in pd.choices: vals.add c.part & "." & pd.name & " = " & ch
      facs.add Fac(kind: fkPartDim, line: c.line, sub: 1 + j, ord: ordn, vals: vals, cite: k, gPiece: c.piece, gOpt: c.optional,
        dimName: pd.name)
      inc ordn
  facs.sort(proc(a, c: Fac): int =
    result = cmp(a.line, c.line)
    if result == 0: result = cmp(a.sub, c.sub)
    if result == 0: result = cmp(a.ord, c.ord))
  var dimFac = initTable[string, int]()
  var optFac = initTable[int, int]()
  for i, f in facs:
    if f.kind == fkDim: dimFac[f.dimName] = i
    elif f.kind == fkOpt: optFac[f.cite] = i
  for i in 0 ..< facs.len:
    facs[i].gDim = -1
    facs[i].gCh = -1
    facs[i].gOptFac = -1
    if facs[i].gPiece > 0:
      let pc = b.pieces[facs[i].gPiece - 1]
      facs[i].gDim = dimFac[pc.dim]
      for d in dims:
        if d.name == pc.dim: facs[i].gCh = d.choices.find(pc.choice)
    if facs[i].gOpt: facs[i].gOptFac = optFac[facs[i].cite]
  var comps: seq[seq[int]]
  var cur = newSeq[int](facs.len)
  proc enumerate(i: int) =
    if i == facs.len:
      comps.add cur
      return
    let f = facs[i]
    if (f.gDim >= 0 and cur[f.gDim] != f.gCh) or (f.gOptFac >= 0 and cur[f.gOptFac] != 0):
      cur[i] = -1
      enumerate(i + 1)
      return
    for v in 0 ..< f.vals.len:
      cur[i] = v
      enumerate(i + 1)
    cur[i] = -1
  enumerate(0)
  let nComp = comps.len
  var allIdx: seq[int]
  for i in 0 ..< nComp: allIdx.add i
  proc compName(i: int): string =
    var ps: seq[string]
    for f in 0 ..< facs.len:
      if comps[i][f] >= 0: ps.add facs[f].vals[comps[i][f]]
    ps.join(", ")
  if nComp > 1:
    var ci = CompInfo(line: b.line, name: eName)
    for i in 0 ..< nComp: ci.names.add compName(i)
    rep.comps.add ci
  # 021:2:16 Che cosa c'è in una composizione
  proc chosen(c: seq[int], p: int): bool =
    if p == 0: return true
    let pc = b.pieces[p - 1]
    let di = dimFac[pc.dim]
    for d in dims:
      if d.name == pc.dim: return c[di] == d.choices.find(pc.choice)
    false
  proc present(c: seq[int], k: int): bool =
    chosen(c, b.cites[k].piece) and (not b.cites[k].optional or c[optFac[k]] == 0)
  var partDimFac = initTable[(int, string), int]()
  for i, f in facs:
    if f.kind == fkPartDim: partDimFac[(f.cite, f.dimName)] = i
  proc partRows(c: seq[int], k: int, offers: bool): seq[(int, Cite)] =
    ## le righe OFFERS o USES di una parte trovata in questa composizione: le comuni più quelle delle sue scelte
    let f = b.found[k]
    let lst = if offers: f.offers else: f.uses
    for i, cc in lst:
      if cc.piece == 0:
        result.add (i, cc)
        continue
      let fp = f.pieces[cc.piece - 1]
      let fi = partDimFac[(k, fp.dim)]
      var ci = -1
      for pd in partDims[k]:
        if pd.name == fp.dim: ci = pd.choices.find(fp.choice)
      if c[fi] == ci: result.add (i, cc)
  proc ver(name, version: string): string = name & (if version.len > 0: " VERSION " & version else: "")
  type CompRes = object
    errs: seq[ErrRec]
    usi: seq[(int, int, Uso)]          # (riga della parte, posizione della USES, voce)
  var res = newSeq[CompRes](nComp)
  for ci in 0 ..< nComp:
    let c = comps[ci]
    var pres: seq[int]
    for k in parts:
      if present(c, k): pres.add k
    var own: seq[Cite]
    for cc in b.cites:
      if cc.kind != ckPart and not cc.dup and chosen(c, cc.piece): own.add cc
    # sezione 8 ed E14
    for pk in pres:
      let p = b.cites[pk]
      let pf = b.found[pk]
      if not pf.ok: continue
      var seen = initHashSet[string]()
      for (pos, u) in partRows(c, pk, false):
        let ukey = u.name & "\0" & u.version      # (1.20) più versioni dello stesso nome: una voce per ciascuna
        if ukey in seen: continue
        seen.incl ukey
        let x = ver(u.name, u.version)
        var offerers: seq[string]
        var offeredBy: seq[(string, int)]
        for qk in pres:
          if qk == pk or not b.found[qk].ok: continue
          for (_, o) in partRows(c, qk, true):
            if o.name == u.name and sameVersion(u.version, o.version):
              offerers.add testo(kRiga, b.cites[qk].part, $b.cites[qk].line)
              offeredBy.add (b.cites[qk].part, b.cites[qk].line)
              break
        var msg = ""
        var uso = Uso(line: p.line, part: p.part, name: u.name, version: u.version)
        if offerers.len >= 1:
          uso.esito = "offerta"
          uso.offeredBy = offeredBy
        if offerers.len == 1:
          msg = testo(kLaOffre, offerers[0])
        elif offerers.len > 1:
          msg = testo(kLaOffrono, offerers.join(", "))
        else:
          var ownLine = 0
          for oc in own:
            if oc.kind == ckUses and oc.name == u.name and sameVersion(u.version, oc.version):
              ownLine = oc.line
              break
          if ownLine > 0:
            msg = testo(kLaUsaDaFuoriRiga, eName, $ownLine)
            uso.esito = "da_fuori"
            uso.fromOutside = ownLine
          elif unfound == 0:
            msg = testo(kNessunoLaOffre)
            uso.esito = "scoperto"
            res[ci].errs.add ErrRec(line: p.line, col: p.col, code: "E14", msg: testo(kLaParteUsaIlConnettore, p.part, x, eName, eName))
          else:
            msg = testo(kNessunaParteTrovataLaOffre, $unfound)
            uso.esito = "non_controllato"
            uso.unchecked = unfound
        uso.text = testo(kUsoTesto, p.part, x, msg)
        res[ci].usi.add (p.line, pos, uso)
    if pres.len == 0 or unfound > 0: continue
    # E16: una CSC pubblica che nessuna parte mantiene dallo stesso lato
    for oc in own:
      var kept = false
      for qk in pres:
        for (_, o) in partRows(c, qk, oc.kind == ckOffers):
          if o.name == oc.name and sameVersion(oc.version, o.version):
            kept = true
            break
        if kept: break
      if not kept:
        res[ci].errs.add ErrRec(line: oc.line, col: oc.col, code: "E16", msg: testo(kIlConnettorePubblico, ver(oc.name, oc.version), eName,
          (if oc.kind == ckOffers: testo(kPubOffre) else: testo(kPubUsato))))
    # E17: una parte offre X, nessun'altra parte la usa e l'entità non la offre
    for pk in pres:
      let p = b.cites[pk]
      var seen = initHashSet[string]()
      for (_, o) in partRows(c, pk, true):
        let okey = o.name & "\0" & o.version
        if okey in seen: continue
        seen.incl okey
        var used = false
        for qk in pres:
          if qk == pk: continue
          for (_, u) in partRows(c, qk, false):
            if u.name == o.name and sameVersion(u.version, o.version):
              used = true
              break
          if used: break
        if not used:
          for oc in own:
            if oc.kind == ckOffers and oc.name == o.name and sameVersion(oc.version, o.version):
              used = true
              break
        if not used:
          res[ci].errs.add ErrRec(line: p.line, col: p.col, code: "E17", msg: testo(kLaParteOffreIlConnettore, p.part, ver(o.name, o.version), eName, eName))
  # 021:2:17 Errori e assenze dichiarate (sezione 4.10): un errore che sparisce rimettendo le parti facoltative assenti è un'assenza
  var keySets = newSeq[HashSet[string]](nComp)
  for ci in 0 ..< nComp:
    for e in res[ci].errs: keySets[ci].incl errKey(e)
  proc plusHas(i: int, put: seq[int], key: string): bool =
    ## C con le parti `put` (fattori opzionali) rimesse: c'è l'errore `key` in una delle composizioni che le hanno?
    for j in 0 ..< nComp:
      var ok = true
      for f in 0 ..< facs.len:
        if comps[i][f] < 0: continue
        if f in put:
          if comps[j][f] != 0: ok = false
        elif comps[j][f] != comps[i][f]: ok = false
        if not ok: break
      if ok and key in keySets[j]: return true
    false
  var errList: seq[ErrRec]
  var errSets: seq[seq[int]]
  var errIdx = initTable[string, int]()
  type Ass = object
    e: ErrRec
    senza: string
    named: seq[int]            # fattori opzionali nominati
    S: seq[int]
  var assList: seq[Ass]
  for ci in 0 ..< nComp:
    var absent: seq[int]
    for f in 0 ..< facs.len:
      if facs[f].kind == fkOpt and comps[ci][f] == 1: absent.add f
    for e in res[ci].errs:
      let key = errKey(e)
      if absent.len == 0 or plusHas(ci, absent, key):
        if key notin errIdx:
          errIdx[key] = errList.len
          errList.add e
          errSets.add @[]
        errSets[errIdx[key]].add ci
        continue
      var named: seq[int]
      for f in absent:
        if not plusHas(ci, @[f], key): named.add f
      if named.len == 0: named = absent
      var senza: seq[string]
      for f in named: senza.add b.cites[facs[f].cite].part
      var found = -1
      for k, a in assList:
        if errKey(a.e) == key and a.named == named: found = k
      if found < 0:
        assList.add Ass(e: e, senza: senza.join(", "), named: named)
        found = assList.high
      assList[found].S.add ci
  for k, e in errList:
    addErr(rep, e.line, e.col, e.code, e.msg)
    rep.errs[^1].inn = suffixFor(facs, comps, allIdx, errSets[k])
  for a in assList:
    var universe: seq[int]
    for j in 0 ..< nComp:
      var ok = true
      for f in a.named:
        if comps[j][f] != 1: ok = false
      if ok: universe.add j
    rep.assenze.add Assenza(line: a.e.line, col: a.e.col, code: a.e.code, senza: a.senza, msg: a.e.msg,
      inn: suffixFor(facs, comps, universe, a.S))
  # 021:2:18 Sezione 8: le voci con lo stesso testo si scrivono una volta, nell'ordine (parte, USES, prima composizione)
  type UsoAgg = object
    line, pos, first: int
    uso: Uso
    S: seq[int]
  var aggs: seq[UsoAgg]
  var aggIdx = initTable[string, int]()
  for ci in 0 ..< nComp:
    for (ln, pos, u) in res[ci].usi:
      let key = $ln & "|" & u.text
      if key notin aggIdx:
        aggIdx[key] = aggs.len
        aggs.add UsoAgg(line: ln, pos: pos, first: ci, uso: u)
      aggs[aggIdx[key]].S.add ci
  aggs.sort(proc(a, c: UsoAgg): int =
    result = cmp(a.line, c.line)
    if result == 0: result = cmp(a.pos, c.pos)
    if result == 0: result = cmp(a.first, c.first))
  for a in aggs:
    var u = a.uso
    u.inn = suffixFor(facs, comps, allIdx, a.S)
    rep.usi.add u
  # 021:2:19 E20 per composizione (sezione 4.6): X dev'essere una OFFERS o USES della composizione
  for cand in b.e20:
    var S: seq[int]
    for ci in 0 ..< nComp:
      if not chosen(comps[ci], cand.piece): continue
      var has = false
      for cc in b.cites:
        if cc.kind != ckPart and not cc.dup and cc.name == cand.conn and chosen(comps[ci], cc.piece):
          has = true
          break
      if not has: S.add ci
    if S.len > 0:
      addErr(rep, cand.line, cand.col, "E20", cand.msg)
      rep.errs[^1].inn = suffixFor(facs, comps, allIdx, S)

proc resolveCitations*(rep: var Report, fileArg: string, dirs: seq[string]) =
  ## 021:2:4 Riempie `found` di ogni citazione, la sezione 7 per le citazioni mancanti, la sezione 8 e gli E14.
  rep.dirs = dirs
  finishAll(rep, fileArg, dirs, true)
  if not rep.hasEntity: return
  var cache = initTable[string, Loaded]()
  let self = rep
  for bi in 0 ..< rep.blocks.len:
    if not rep.blocks[bi].isEntity: continue
    var fs: seq[Found]
    for c in self.blocks[bi].cites:
      if c.dup: fs.add Found()
      else: fs.add searchCite(self, fileArg, dirs, c, cache)
    rep.blocks[bi].found = fs
    for k, c in self.blocks[bi].cites:
      if c.dup or fs[k].ok: continue
      rep.notFound.add NonControllata(line: c.line, nome: c.name, motivo: fs[k].reason,
        tipo: (case c.kind
          of ckOffers: "OFFERS"
          of ckUses: "USES"
          of ckPart: "PART"
          of ckImport: "IMPORT"
          of ckLegata: "LEGATA"
          of ckUsing: "USING"))
    # 021:2:10 (1.20, G36) I nomi qualificati X.y di uno scenario d'entità: y dev'esserci, del tipo giusto, in una delle CSC X trovate.
    # Se nessuna è trovata, o y manca ma una delle righe di X non è stata trovata, il controllo è sospeso: un errore
    # solo sul certo.
    for q in self.blocks[bi].qrefs:
      var anyFound, allFound = false
      var hits: seq[(string, seq[string])]       # blocchi trovati che hanno y del tipo giusto
      allFound = true
      for k, c in self.blocks[bi].cites:
        if c.kind == ckPart or c.dup or c.name != q.qual: continue
        if not fs[k].ok or fs[k].viaFallback:     # (O-7) una riga trovata solo nel ripiego è come una non trovata
          allFound = false
          continue
        anyFound = true
        if q.name in fs[k].elems and fs[k].elems[q.name][0] == q.kind:
          hits.add fs[k].elems[q.name]
      if not anyFound: continue
      if hits.len == 0:
        if allFound:
          addErr(rep, q.line, q.col, "E03", testo(kNomeNonDichiaratoCome2, q.kind, q.qual, q.name))
        continue
      if q.kind == "EVENT":
        for a in q.args:
          var has = false
          for h in hits:
            if a.name in h[1]: has = true
          if not has:
            addErr(rep, a.line, a.col, "E03", testo(kNomeNonDichiaratoComeParametro2, q.qual, q.name, a.name))
      # 021:2:13 (1.0-beta, 4.6) un valore scritto si controlla col tipo di base letto nel blocco trovato
      let env0 = newEnv()
      for k, c in self.blocks[bi].cites:
        if c.kind == ckPart or c.dup or c.name != q.qual or not fs[k].ok or fs[k].viaFallback: continue
        let sy = fs[k].blk.syms
        if q.name notin sy: continue
        proc baseOnly(t: Ty): bool =
          if t == nil: return false
          case t.k
          of tBool, tInt, tReal, tDur, tStr: true
          of tOpt: baseOnly(t.inner)
          else: false
        if q.kind == "STATE" and q.val.len > 0 and sy[q.name].kind == sState and baseOnly(sy[q.name].ty) and
            not valueOk(env0, sy[q.name].ty, q.val):
          addErr(rep, q.val[0].line, q.val[0].col, "E25", testo(kValoreNonDelTipo, (if sy[q.name].ty.shown.len > 0: sy[q.name].ty.shown else: tyText(env0, sy[q.name].ty)), valText(q.val)))
        if q.kind == "EVENT":
          for a in q.args:
            if a.val.len == 0: continue
            for (pn, pt) in sy[q.name].params:
              if pn == a.name and baseOnly(pt) and not valueOk(env0, pt, a.val):
                addErr(rep, a.val[0].line, a.val[0].col, "E25", testo(kValoreNonDelTipo, (if pt.shown.len > 0: pt.shown else: tyText(env0, pt)), valText(a.val)))
        break
  # 021:2:14 (1.0-beta, 4.9) i nomi qualificati delle formule d'entità: y dev'esserci nella CSC trovata
  for bi in 0 ..< rep.blocks.len:
    if not rep.blocks[bi].isEntity: continue
    for q in self.blocks[bi].fqrefs:
      var anyFound, allFound, hit = false
      allFound = true
      for k, c in self.blocks[bi].cites:
        if c.kind == ckPart or c.dup or c.name != q.qual: continue
        if not rep.blocks[bi].found[k].ok or rep.blocks[bi].found[k].viaFallback:
          allFound = false
          continue
        anyFound = true
        let sy = rep.blocks[bi].found[k].blk.syms
        if q.name in sy and (q.kind.len == 0 or symGenreOf(sy[q.name]) == q.kind or (q.kind == "" )): hit = true
      if anyFound and not hit and allFound:
        addErr(rep, q.line, q.col, "E24",
          if q.kind.len > 0: testo(kNomeNonDichiaratoCome2, q.kind, q.qual, q.name) else: testo(kNomeNonDichiarato2, q.qual, q.name))
  # 021:2:5 (1.21) Sezione 8, E14, E16, E17, sezioni 9 e 10: la chiusura di ogni entità, in ogni sua composizione
  for bi in 0 ..< rep.blocks.len:
    if rep.blocks[bi].isEntity: closeEntity(rep, bi)
  rep.errs.sort(proc(a, b: Err): int =
    result = cmp(a.line, b.line)
    if result == 0: result = cmp(a.col, b.col)
    if result == 0: result = cmp(a.code, b.code)
    if result == 0: result = cmp(a.seqno, b.seqno))

var searchFile* = ""            ## 021:2:6 Percorso come lo ha scritto la persona; vuoto = nessuna ricerca
var searchDirs*: seq[string]

proc analyzeFull*(raw: string): Report =
  ## 021:2:7 `analyze` più la ricerca delle citazioni, se un comando ha fissato il file (refine e ratify).
  result = analyze(raw)
  if searchFile.len > 0: resolveCitations(result, searchFile, searchDirs)
  else: finishAll(result, "", @[], false)

# 022:1:1 Il rapporto (sezione 9): contenuto esatto dello standard output
proc esitoUnrec*(rep: Report, strict: bool): string =
  ## 022:1:2 (1.20, O-4) Il pezzo della riga `esito` sulle righe non riconosciute: sempre, se ce n'è; con --strict si dice l'opzione.
  if rep.unrecLines == 0: return ""
  testo(kEsitoNonRiconosciute, rep.unrecLines, (if strict: testo(kEsitoStrict) else: testo(kEsitoVediSezione5)))

proc purposeDaCompilare*(l: string): bool =
  ## 022:1:11 Il riconoscitore unico dello scopo ancora da compilare: dopo PURPOSE, tolti gli
  ## spazi, la stringa comincia con `"da scrivere`, `"da compilare` (file di versioni precedenti) o `"to be filled in`, in qualunque lingua sia scritto lo scheletro.
  let at = l.find("PURPOSE")
  if at < 0: return false
  let r = l[at + 7 .. ^1].strip()
  r.startsWith("\"da scrivere") or r.startsWith("\"da compilare") or r.startsWith("\"to be filled in")

proc esitoErrori*(n: int): string =
  ## 022:1:5 «nessun errore», «1 errore», «N errori», nella lingua corrente.
  case n
  of 0: testo(kNessunErrore)
  of 1: testo(kUnErrore)
  else: testo(kNErrori, n)

proc inSuffix(inn: string): string =
  ## 022:1:4 (1.21) Il suffisso di un errore o di una voce che non vale in tutte le composizioni.
  if inn.len == 0: "" else: " (in: " & inn & ")"

proc gradeText*(g: Grade): string =
  case g
  of grVerbal: testo(kGradoVerbale)
  of grFormal: testo(kGradoFormale)
  of grExt: testo(kGradoEstensione)
  of grUnrec: testo(kGradoNonRiconosciuta)

proc formaTesto*(f: FormaMancante): string =
  ## 022:1:6 Il testo di una voce della sezione 12.
  if not f.cscTrovata: testo(kCSCNonTrovataElementiNon, f.head)
  else: f.head & ": " & (if f.elementi.len == 0: testo(kNessunaParola) else: f.elementi.join(", "))

proc coperturaRighe*(c: Copertura): seq[string] =
  ## 022:1:7 Le righe di testo di una voce della sezione 13.
  if not c.cscTrovata: return @[testo(kCSCNonTrovataCoperturaNon)]
  for m in c.mezzi:
    result.add testo(kCoperturaMezzo, m.name, m.line, (if m.promesse.len == 0: testo(kNessunaParola) else: m.promesse.join(", ")))
  result.add testo(kCoperturaNonEseguite, (if c.nonEseguite.len == 0: testo(kNessunaParola) else: c.nonEseguite.join(", ")))

proc ncTesto*(n: NonControllata): string =
  ## 022:1:8 Il testo di una voce della sezione 7.
  var s = case n.tipo
    of "IMPORT": "PROFILE " & n.nome
    of "USING": "BINDING " & n.nome & " AS " & n.parte
    else: n.nome
  if n.motivo.len > 0: s = testo(kNcMotivo, s, n.motivo)
  s

proc daGiudicareTesto*(riga: int, voce: string): string =
  ## 022:1:9 «riga N: voce».
  testo(kRapRigaN, riga, voce)

proc nonEsegNome*(codice: string): string =
  ## 022:1:10 Il nome di un controllo non eseguito (sezione 15) nella lingua corrente; `codice` è uguale in ogni lingua.
  case codice
  of "storie": testo(kNonEsegStorie)
  of "copertura_inneschi": testo(kNonEsegInneschi)
  of "coerenza_presupposti_promesse": testo(kNonEsegCoerenza)
  else: testo(kNonEsegDettagli)

proc render*(rep: Report, fileName: string, strict: bool): string =
  var o = ""
  proc ln(s: string) = o.add s & "\n"
  var first = "bcdd check"
  if strict: first.add " --strict"
  for d in rep.dirs: first.add " --dir " & d
  ln first & " " & fileName
  ln testo(kRapRighe, rep.total, rep.recLines, rep.comLines, rep.blankLines, rep.unrecLines)
  ln testo(kRapBlocchi, rep.blocks.len)
  proc citeLine(label: string, c: Cite, f: Found): string =
    var cs = "    " & testo(kRapRigaN, c.line, label)
    let bad = c.version.len > 0 and c.version != f.version
    if f.where.len == 0:
      cs.add testo(kCitInQuestoFile, f.line)
      if bad: cs.add testo(kCitVersioneAttesa, f.version, c.version)
    else:
      cs.add testo(kCitInAltroFile, f.where, f.line, f.version, f.statusText)
      cs.add esitoErrori(f.errCount)
      if f.unrec > 0: cs.add testo(kCitNonRiconosciute, f.unrec)
      if bad: cs.add testo(kCitAttesa, c.version)
    cs
  for b in rep.blocks:
    var s = "  "
    var hdr = ""
    if b.isView:
      hdr = "REFINEMENT VIEW " & (if b.headerOk: b.name else: testo(kIntestazioneNonValidaPar))
    else:
      let kw = b.bk
      if b.headerOk:
        hdr = kw & " " & b.name & " VERSION " & b.version
        if b.ownName.len > 0: hdr.add " AS " & b.ownName
      else:
        hdr = kw & " " & testo(kIntestazioneNonValidaPar)
      if b.bk != "VERIFICATION":
        hdr.add ", "
        hdr.add statusText(b)
    s.add testo(kRapRigaN, b.line, hdr)
    ln s
    var cl: seq[(int, string)]
    if b.isEntity:
      for k, c in b.cites:
        if c.dup or k >= b.found.len or not b.found[k].ok: continue
        var lab = ""
        case c.kind
        of ckOffers: lab = "OFFERS " & c.name
        of ckUses: lab = "USES " & c.name
        of ckPart: lab = c.part & " : " & c.name
        of ckImport, ckLegata, ckUsing: discard
        cl.add (c.line, citeLine(lab, c, b.found[k]))
    for k, c in b.xcites:
      if k >= b.xfound.len or not b.xfound[k].ok: continue
      let f = b.xfound[k]
      case c.kind
      of ckImport: cl.add (c.line, citeLine("IMPORT PROFILE " & c.name, c, f))
      of ckLegata: cl.add (c.line, citeLine("CSC " & c.name, c, f))
      of ckUsing: cl.add (c.line, "    " & testo(kRapRigaN, c.line, testo(kCitUsing, c.part,
        (if f.where.len == 0: testo(kQuestoFile) else: f.where), f.line)))
      else: discard
    var ord = newSeq[int](cl.len)
    for i in 0 ..< ord.len: ord[i] = i
    ord.sort(proc(x, y: int): int =
      result = cmp(cl[x][0], cl[y][0])
      if result == 0: result = cmp(x, y))
    for i in ord: ln cl[i][1]
  ln ""
  ln testo(kRapErrori, rep.errs.len)
  for e in rep.errs:
    ln "  " & (if e.line == 0: testo(kPosFile) else: testo(kPosRiga, e.line)) & ": [" & e.code & "] " & e.msg & inSuffix(e.inn)
  ln ""
  var nv, nu, nf, nx = 0
  for g in rep.grades:
    case g.grade
    of grVerbal: inc nv
    of grFormal: inc nf
    of grExt: inc nx
    of grUnrec: inc nu
  ln testo(kRapGrado)
  ln "  " & testo(kRapGradoVerbale, nv)
  ln "  " & testo(kRapGradoFormale, nf)
  ln "  " & testo(kRapGradoEstensione, nx)
  ln "  " & testo(kRapGradoNonRiconosciuta, nu)
  for g in rep.grades:
    ln "  " & testo(kRapRigaN, g.line, g.kw & " " & g.id & " " & gradeText(g.grade))
  ln ""
  ln testo(kRapUndecided, rep.undecided.len)
  for (l, n) in rep.undecided: ln "  " & testo(kRapRigaN, l, n)
  ln ""
  ln testo(kRapIpotesi, rep.hyps.len)
  for (l, k, id) in rep.hyps: ln "  " & testo(kRapRigaN, l, k & " " & id)
  ln ""
  ln testo(kRapNonRiconosciute, rep.unrecText.len)
  for (l, t) in rep.unrecText:
    ln "  " & (if t.len == 0: testo(kRapRigaSola, l) else: testo(kRapRigaN, l, t))
  ln ""
  ln testo(kRapTipiNonDichiarati, rep.undeclOrder.len)
  for n in rep.undeclOrder:
    let ls = rep.undeclLines[n]
    var parts: seq[string]
    for l in ls: parts.add $l
    ln "  " & n & ": " & (if ls.len == 1: testo(kElencoRiga, parts.join(", ")) else: testo(kElencoRighe, parts.join(", ")))
  ln ""
  var nom = rep.notFound
  nom.sort(proc(a, b: NonControllata): int = cmp(a.line, b.line))
  ln testo(kRapNominate, nom.len)
  for n in nom: ln "  " & testo(kRapRigaN, n.line, ncTesto(n))
  ln ""
  if rep.hasEntity:
    ln testo(kRapUsi, rep.usi.len)
    for u in rep.usi: ln "  " & testo(kRapRigaN, u.line, u.text) & inSuffix(u.inn)
    ln ""
  if rep.comps.len > 0:
    # 022:1:3 (1.21) sezioni 9 e 10: solo se un'entità del file ha più di una composizione (o E23)
    var tot = 0
    for c in rep.comps: tot += c.names.len
    ln testo(kRapComposizioni, tot)
    for c in rep.comps:
      if c.tooMany:
        ln "  " & testo(kRapRigaN, c.line, testo(kRapPiuDi64, c.name))
      else:
        ln "  " & testo(kRapRigaN, c.line, "ENTITY " & c.name & ": " & $c.names.len)
        for n in c.names: ln "    " & n
    ln ""
    ln testo(kRapAssenze, rep.assenze.len)
    for a in rep.assenze:
      ln "  " & testo(kRapRigaN, a.line, testo(kAssenzaSenza, a.senza, a.msg)) & inSuffix(a.inn)
    ln ""
  if rep.hasBinding:
    ln testo(kRapForme, rep.nonEsegFormeCount)
    for fm in rep.forme: ln "  " & testo(kRapRigaN, fm.line, formaTesto(fm))
    ln ""
  if rep.hasVerification:
    ln testo(kRapCopertura, rep.nonEseguite)
    for c in rep.copertura:
      ln "  " & testo(kRapRigaN, c.line, c.head)
      for x in coperturaRighe(c): ln "    " & x
    ln ""
  if rep.daGiudicare.len > 0:
    ln testo(kRapDaGiudicare, rep.daGiudicare.len)
    for (l, v) in rep.daGiudicare: ln "  " & daGiudicareTesto(l, v)
    ln ""
  if rep.nonEseg.len > 0:
    ln testo(kRapNonEseguiti, rep.nonEseg.len)
    for (n, ls) in rep.nonEseg:
      var parts: seq[string]
      for l in ls: parts.add $l
      ln "  " & nonEsegNome(n) & ": " & (if ls.len == 1: testo(kElencoRiga, parts.join(", ")) else: testo(kElencoRighe, parts.join(", ")))
    ln ""
  ln testo(kRapEsito, esitoErrori(rep.errs.len) & esitoUnrec(rep, strict))
  o

proc exitCodeFor*(rep: Report, strict: bool): int =
  ## 023:1:1 Il più forte vince: 1 (errori), poi 3 (solo righe non riconosciute, con --strict), poi 0.
  if rep.errs.len > 0: 1
  elif strict and rep.unrecLines > 0: 3
  else: 0

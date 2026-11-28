# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 010:1:1 edrif: i riferimenti a documenti esterni e le decisioni nei testi delle CSC.
# Funzioni senza GTK: dai JSON di `check --json` (le righe del file) e dai file `.md` citati al modello `ext`, che la pagina disegna.
# Niente rete: un URL si riporta com'è. I file `.md` e il registro si leggono una volta per caricamento (`azzeraRif` li dimentica: apertura,
# Ricarica, cambio di cartelle) e solo in lettura. Nessun riconoscimento dal testo dei documenti: si risolve soltanto ciò che il testo della CSC dichiara.
import std/[json, strutils, tables, os, sequtils, unicode]
import edmodello

const
  maxByteMd = 4 * 1024 * 1024          # E5: oltre, RF-6
  maxRigheT5 = 40                      # T5
  maxCarT5 = 4000                      # T5
  etichettaRegistro = "Registro delle decisioni"      # G1
  maxCartaReg = 300                    # i testi delle righe del registro per il campo di Approva (P4): più corti, il modello ne porta molte

type
  Doc = ref object
    ok: bool
    cod, arg: string                   # se non ok: RF-1 / RF-6 e il motivo
    righe: seq[string]
    fence: seq[int]                    # 0 fuori, 1 dentro un blocco di codice, 2 delimitatore
    ancore: seq[(string, int)]         # (id, riga 0-based) in ordine di riga
    grassetti: Table[string, seq[int]] # id -> righe (0-based) dove comincia un blocco **ID**
  Registro = ref object
    percorso: string
    nome: string
    righe: Table[int, seq[string]]     # numero -> una voce per riga con quel numero (le celle dopo l'id, unite da « · »)
    massimo: int
  RifVoce = object
    riga: int                          # 1-based
    col, lung: int                     # in unità UTF-16 (come le stringhe di JavaScript)
    chiave: string

var
  cacheDoc = initTable[string, Doc]()
  cacheReg = initTable[string, Registro]()
  apribili* = initTable[string, string]()      ## (file + NUL + chiave) -> cosa si apre: un percorso `.md` letto, o un URL http(s)

proc azzeraRif*() =
  ## E4: i file `.md` e i registri si rileggono al prossimo modello (apertura, Ricarica, cambio di cartelle).
  cacheDoc.clear()
  cacheReg.clear()

# ---- caratteri e testo

proc spazio(c: char): bool = c in {' ', '\t'}
proc vuota(s: string): bool = s.strip(chars = {' ', '\t', '\r'}).len == 0
proc alfanum(c: char): bool = c in {'A'..'Z', 'a'..'z', '0'..'9'}

proc u16(s: string, fine: int): int =
  ## Unità UTF-16 dei primi `fine` byte di `s` (come `String.length` di JavaScript).
  var i = 0
  while i < fine and i < s.len:
    let r = s.runeAt(i)
    result += (if int(r) >= 0x10000: 2 else: 1)
    i += r.size

proc ultimoCarattere(s: string, fine: int): Rune =
  ## Il carattere che finisce a `fine` (esclusa); `Rune(0)` se non c'è.
  if fine <= 0: return Rune(0)
  var i = fine - 1
  while i > 0 and (ord(s[i]) and 0xC0) == 0x80: dec i
  s.runeAt(i)

proc lettera(r: Rune): bool = r.isAlpha
proc cifraOLettera(r: Rune): bool = r.isAlpha or (int(r) >= ord('0') and int(r) <= ord('9'))

# ---- R1: l'etichetta

proc etichettaValida*(s: string): bool =
  ## R1: da 2 a 60 caratteri; primo e ultimo né spazio né tabulatore; solo lettere (anche accentate), cifre, spazi, `-`, `_`, `.`, `/`, `§`;
  ## almeno una lettera.
  let n = s.runeLen
  if n < 2 or n > 60: return false
  if spazio(s[0]) or spazio(s[^1]): return false
  var haLettera = false
  for r in s.runes:
    if r.isAlpha: haLettera = true
    elif int(r) >= ord('0') and int(r) <= ord('9'): discard
    elif r == Rune(ord(' ')) or r == Rune(ord('-')) or r == Rune(ord('_')) or r == Rune(ord('.')) or r == Rune(ord('/')) or r == Rune(0xA7): discard
    else: return false
  haLettera

proc normaEtichetta*(s: string): string =
  ## Il confronto fra etichette: sensibile alle maiuscole, le sequenze di spazi ridotte a uno.
  var prima = false
  for c in s:
    if c == ' ':
      if not prima: result.add c
      prima = true
    else:
      result.add c
      prima = false

proc idValido*(s: string): bool =
  ## A2: `[A-Za-z0-9][A-Za-z0-9._-]*`, al più 64 caratteri.
  if s.len == 0 or s.len > 64 or not alfanum(s[0]): return false
  for c in s:
    if not (alfanum(c) or c in {'.', '_', '-'}): return false
  true

# ---- D5, D6: la destinazione

type
  Dest = object
    ok: bool
    url: bool
    motivo: string                     # se non ok (RF-6): assoluto, barra, schema, non_md, id, percorso
    percorso, id: string

proc analizzaDest*(d0: string): Dest =
  let d = d0.strip
  if d.toLowerAscii.startsWith("http://") or d.toLowerAscii.startsWith("https://"):
    for c in d:
      if c in {' ', '\t'}: return Dest(motivo: "schema")
    return Dest(ok: true, url: true, percorso: d)
  if d.len == 0: return Dest(motivo: "non_md")
  if '\\' in d: return Dest(motivo: "barra")
  if d[0] == '/' : return Dest(motivo: "assoluto")
  if d.len >= 2 and d[1] == ':' and d[0] in {'A'..'Z', 'a'..'z'}: return Dest(motivo: "assoluto")
  let h = d.rfind('#')
  let p = if h >= 0: d[0 ..< h] else: d
  let id = if h >= 0: d[h + 1 .. ^1] else: ""
  if ':' in p: return Dest(motivo: "schema")
  if h >= 0 and not idValido(id): return Dest(motivo: "id")
  if not p.endsWith(".md") or p.len <= 3: return Dest(motivo: "non_md")
  for c in p.split('/'):
    if c.len == 0: return Dest(motivo: "percorso")
  Dest(ok: true, percorso: p, id: id)

proc senzaBarre(p: string): string = p.replace('\\', '/')

proc risolviPercorso(dir, rel: string): (string, string, string) =
  ## D6: dal `dir` del file `.csc` seguendo i componenti; ognuno deve coincidere sul disco anche nelle maiuscole.
  ## (percorso assoluto, "" | "RF-1" | "RF-6", motivo/dato)
  var cur = dir
  let comp = rel.split('/')
  for k, c in comp:
    if c == ".": continue
    if c == "..":
      let p = parentDir(cur)
      cur = if p.len == 0: cur else: p
      continue
    var esatto = false
    var diverso = ""
    try:
      for _, nome in walkDir(cur, relative = true):
        if nome == c:
          esatto = true
          break
        elif cmpIgnoreCase(nome, c) == 0 and diverso.len == 0: diverso = nome
    except OSError:
      return ("", "RF-1", "")
    if esatto: cur = cur / c
    elif diverso.len > 0: return ("", "RF-6", "maiuscole\x01" & diverso)
    else: return ("", "RF-1", "")
  if not fileExists(cur): return ("", "RF-1", "")
  (cur, "", "")

# ---- il documento `.md`

proc ritoDelimitatore(r: string): char =
  let t = r.strip(trailing = false, chars = {' ', '\t'})
  if t.startsWith("```"): '`'
  elif t.startsWith("~~~"): '~'
  else: '\0'

proc titolo(r: string): int =
  ## Il livello del titolo `#` (1-6) o 0.
  var i = 0
  while i < r.len and r[i] == ' ' and i < 3: inc i
  var n = 0
  while i + n < r.len and r[i + n] == '#': inc n
  if n < 1 or n > 6: return 0
  if i + n >= r.len or r[i + n] in {' ', '\t'}: n else: 0

proc rientro(r: string): int =
  for c in r:
    if c == ' ': inc result
    elif c == '\t': result += 4
    else: break

proc segnoElenco(r: string): int =
  ## L'indice (byte) del primo carattere dopo il segno d'elenco e gli spazi, o -1 se `r` non comincia un elemento di elenco.
  var i = 0
  while i < r.len and r[i] in {' ', '\t'}: inc i
  if i >= r.len: return -1
  if r[i] in {'-', '*', '+'}:
    if i + 1 < r.len and r[i + 1] in {' ', '\t'}:
      i += 1
      while i < r.len and r[i] in {' ', '\t'}: inc i
      return i
    return -1
  if r[i] in {'0'..'9'}:
    var k = i
    while k < r.len and r[k] in {'0'..'9'}: inc k
    if k < r.len and r[k] in {'.', ')'} and k + 1 < r.len and r[k + 1] in {' ', '\t'}:
      k += 1
      while k < r.len and r[k] in {' ', '\t'}: inc k
      return k
  -1

proc inCodice(r: string, pos: int): bool =
  ## A4: `pos` sta dentro un tratto di codice in linea (un numero dispari di apici prima).
  var n = 0
  for i in 0 ..< min(pos, r.len):
    if r[i] == '`': inc n
  n mod 2 == 1

proc ancoreInRiga(r: string): seq[(string, int, int)] =
  ## A1: (id, byte d'inizio, byte di fine esclusa) delle ancore `<a id="ID"></a>` valide fuori dal codice in linea.
  var i = 0
  const testa = "<a id=\""
  while true:
    let p = r.find(testa, i)
    if p < 0: break
    var k = p + testa.len
    var id = ""
    while k < r.len and r[k] != '"' and id.len <= 65:
      id.add r[k]
      inc k
    if k < r.len and r[k] == '"' and r.continuesWith("></a>", k + 1) and idValido(id) and not inCodice(r, p):
      result.add (id, p, k + 6)
      i = k + 6
    else: i = p + 1

proc senzaAncore*(r: string): string =
  var da = 0
  for (_, a, b) in ancoreInRiga(r):
    result.add r[da ..< a]
    da = b
  result.add r[da .. ^1]

proc inizioGrassetto(t: string, da: int): string =
  ## Se `t` da `da` comincia con `**ID**` (A2, senza spazi, il carattere dopo non è `*`) l'id, altrimenti "".
  if not t.continuesWith("**", da): return ""
  var k = da + 2
  var id = ""
  while k < t.len and (alfanum(t[k]) or t[k] in {'.', '_', '-'}):
    id.add t[k]
    inc k
  if not t.continuesWith("**", k): return ""
  if k + 2 < t.len and t[k + 2] == '*': return ""
  if idValido(id): id else: ""

proc leggiDoc(percorso: string): Doc =
  ## E5: oltre 4 MB o non UTF-8, RF-6. Una lettura per caricamento.
  if percorso in cacheDoc: return cacheDoc[percorso]
  var d = Doc()
  cacheDoc[percorso] = d
  var testo: string
  try:
    if getFileSize(percorso) > maxByteMd:
      d.cod = "RF-6"; d.arg = "grande"
      return d
    testo = readFile(percorso)
  except CatchableError:
    d.cod = "RF-1"
    return d
  if testo.validateUtf8 != -1:
    d.cod = "RF-6"; d.arg = "utf8"
    return d
  d.ok = true
  d.righe = testo.split('\n').mapIt(it.strip(leading = false, chars = {'\r'}))
  d.fence = newSeq[int](d.righe.len)
  var aperto = '\0'
  for i, r in d.righe:
    let m = ritoDelimitatore(r)
    if aperto == '\0':
      if m != '\0':
        aperto = m
        d.fence[i] = 2
    else:
      if m == aperto:
        aperto = '\0'
        d.fence[i] = 2
      else: d.fence[i] = 1
  for i, r in d.righe:
    if d.fence[i] != 0: continue
    for (id, _, _) in ancoreInRiga(r): d.ancore.add (id, i)
    # B1-B4: l'inizio di un blocco `**ID**`
    var id = ""
    let lv = titolo(r)
    if lv > 0:
      var k = 0
      while k < r.len and r[k] == ' ': inc k
      k += lv
      while k < r.len and r[k] in {' ', '\t'}: inc k
      id = inizioGrassetto(r, k)                                  # B4
    else:
      var k = 0
      while k < r.len and r[k] in {' ', '\t'}: inc k
      if k < r.len and r[k] == '|':
        inc k
        while k < r.len and r[k] in {' ', '\t'}: inc k
        id = inizioGrassetto(r, k)                                # B3, solo la prima cella
      else:
        let e = segnoElenco(r)
        if e >= 0: id = inizioGrassetto(r, e)                     # B2
        elif k < r.len and r[k] == '*':
          let prima = i == 0 or vuota(d.righe[i - 1]) or titolo(d.righe[i - 1]) > 0 or d.fence[i - 1] == 2
          if prima: id = inizioGrassetto(r, k)                    # B1
    if id.len > 0: d.grassetti.mgetOrPut(id, @[]).add i
  d

# ---- T1-T4: il blocco mostrato

proc bloccoDi(d: Doc, L: int): seq[int] =
  ## Le righe (0-based) del blocco che contiene la riga L (T1-T4).
  let n = d.righe.len
  let r = d.righe[L]
  let lv = titolo(r)
  if lv > 0:
    result.add L
    var i = L + 1
    while i < n:
      if d.fence[i] == 0 and titolo(d.righe[i]) in 1 .. lv: break
      result.add i
      inc i
    return
  let t = r.strip(trailing = false, chars = {' ', '\t'})
  proc daTabella(x: string): bool = x.strip(trailing = false, chars = {' ', '\t'}).startsWith("|")
  proc separatore(x: string): bool =
    let c = x.strip(chars = {' ', '\t', '|', '-', ':'})
    daTabella(x) and c.len == 0
  if t.startsWith("|"):
    var a = L
    while a > 0 and d.fence[a - 1] == 0 and daTabella(d.righe[a - 1]): dec a
    var b = L
    while b + 1 < n and d.fence[b + 1] == 0 and daTabella(d.righe[b + 1]): inc b
    if L == a:
      for i in a .. b:
        if not separatore(d.righe[i]): result.add i
    else:
      result = @[a, L]
    return
  let e = segnoElenco(r)
  if e >= 0:
    let ri = rientro(r)
    result.add L
    var i = L + 1
    while i < n:
      if d.fence[i] == 1: result.add i; inc i; continue
      if vuota(d.righe[i]) or titolo(d.righe[i]) > 0: break
      if segnoElenco(d.righe[i]) >= 0 and rientro(d.righe[i]) <= ri: break
      result.add i
      inc i
    return
  var a = L
  while a > 0 and d.fence[a - 1] == 0 and not vuota(d.righe[a - 1]) and titolo(d.righe[a - 1]) == 0: dec a
  var b = L
  while b + 1 < n and d.fence[b + 1] == 0 and not vuota(d.righe[b + 1]) and titolo(d.righe[b + 1]) == 0: inc b
  for i in a .. b: result.add i

proc limita(d: Doc, righe: seq[int]): (string, int) =
  ## T5: al più 40 righe e 4000 caratteri; (testo, prima riga non mostrata 1-based o 0). Le ancore sono già tolte dal testo.
  var tot = 0
  var mostrate: seq[string]
  for k, i in righe:
    let r = senzaAncore(d.righe[i])
    let nuovo = tot + r.runeLen + (if mostrate.len > 0: 1 else: 0)
    if mostrate.len >= maxRigheT5 or nuovo > maxCarT5:
      if mostrate.len == 0:
        return (r.runes.toSeq[0 ..< maxCarT5].mapIt($it).join, i + 1)    # una sola riga lunghissima: si taglia a metà
      return (mostrate.join("\n"), i + 1)
    mostrate.add r
    tot = nuovo
  (mostrate.join("\n"), 0)

proc testoVuoto(d: Doc, righe: seq[int]): bool =
  for i in righe:
    if not vuota(senzaAncore(d.righe[i])): return false
  true

# ---- una destinazione risolta

proc elencoRighe(l: seq[int]): string = l.mapIt($(it + 1)).join(", ")

proc voceErrore(cod: string, eti: string, dest: string, a = "", b = "", num = 0): JsonNode =
  result = %*{"ok": false, "cod": cod, "eti": eti, "dest": dest, "a": a, "b": b}
  if num != 0: result["num"] = %num

proc primoTitolo(d: Doc): int =
  for i, r in d.righe:
    if d.fence[i] == 0 and titolo(r) > 0: return i
  -1

proc risolviDest(dirCsc, dest, eti, fileCsc: string): (JsonNode, string) =
  ## (voce, cosa si apre). La voce ha `ok`; se no `cod` e gli argomenti del motivo.
  let ds = analizzaDest(dest)
  if not ds.ok: return (voceErrore("RF-6", eti, dest, ds.motivo), "")
  if ds.url:
    return (%*{"ok": true, "t": "url", "eti": eti, "dest": dest}, ds.percorso)
  let (pa, cod, dato) = risolviPercorso(dirCsc, ds.percorso)
  if cod == "RF-1": return (voceErrore("RF-1", eti, dest, ds.percorso), "")
  if cod == "RF-6":
    let pz = dato.split('\x01')
    return (voceErrore("RF-6", eti, dest, pz[0], if pz.len > 1: pz[1] else: ""), "")
  let doc = leggiDoc(pa)
  if not doc.ok: return (voceErrore(doc.cod, eti, dest, if doc.cod == "RF-1": ds.percorso else: doc.arg, ds.percorso), "")
  let nomefile = lastPathPart(pa)
  var righe: seq[int]
  var L = -1
  if ds.id.len == 0:
    L = doc.primoTitolo
    righe = if L >= 0: @[L] else: @[]
  else:
    var tutteFold: seq[(string, int)]
    for (id, r) in doc.ancore:
      if id.toLowerAscii == ds.id.toLowerAscii: tutteFold.add (id, r)
    if tutteFold.len >= 2:
      return (voceErrore("RF-5", eti, dest, ds.id, tutteFold.mapIt(it[1]).elencoRighe), "")
    if tutteFold.len == 1 and tutteFold[0][0] == ds.id:
      L = tutteFold[0][1]
    else:
      let bl = doc.grassetti.getOrDefault(ds.id)
      if bl.len >= 2: return (voceErrore("RF-10", eti, dest, ds.id, bl.elencoRighe), "")
      if bl.len == 0: return (voceErrore("RF-2", eti, dest, ds.id), "")
      L = bl[0]
    righe = doc.bloccoDi(L)
    if doc.testoVuoto(righe): return (voceErrore("RF-9", eti, dest, ds.id), "")
  var testo = ""
  var oltre = 0
  if righe.len > 0: (testo, oltre) = doc.limita(righe)
  let v = %*{"ok": true, "t": "md", "eti": eti, "dest": dest, "riga": L + 1, "testo": testo, "oltre": oltre, "nomefile": nomefile}
  (v, pa)

# ---- il registro delle decisioni

proc celleRiga(r: string): seq[string] =
  var cur = ""
  var i = 0
  while i < r.len:
    if r[i] == '\\' and i + 1 < r.len and r[i + 1] == '|':
      cur.add "|"
      i += 2
      continue
    if r[i] == '|':
      result.add cur.strip
      cur = ""
    else: cur.add r[i]
    inc i
  result.add cur.strip

proc leggiRegistro(percorso: string): Registro =
  ## G2/G1, §6.4: le righe `| D-nnn | … |`. Il nome del progetto è la cartella che contiene il registro.
  if percorso in cacheReg: return cacheReg[percorso]
  let reg = Registro(percorso: percorso, nome: lastPathPart(parentDir(percorso)))
  cacheReg[percorso] = reg
  var testo = ""
  try:
    if getFileSize(percorso) > maxByteMd: return reg
    testo = readFile(percorso)
  except CatchableError: return reg
  if testo.validateUtf8 != -1: return reg
  for riga in testo.split('\n'):
    let r = riga.strip(leading = false, chars = {'\r'}).strip(trailing = false, chars = {' ', '\t'})
    if not r.startsWith("|"): continue
    var k = 1
    while k < r.len and r[k] in {' ', '\t'}: inc k
    if not r.continuesWith("D-", k): continue
    k += 2
    let a = k
    while k < r.len and r[k] in {'0'..'9'}: inc k
    if k == a or k - a > 9: continue
    let numero = parseInt(r[a ..< k])
    while k < r.len and r[k] in {' ', '\t'}: inc k
    if k >= r.len or r[k] != '|': continue
    let celle = celleRiga(r)
    # celle[0] è vuota (prima del primo `|`), celle[1] l'id; l'ultima è vuota se la riga finisce con `|`
    var dopo = if celle.len > 2: celle[2 .. ^1] else: @[]
    if dopo.len > 0 and dopo[^1].len == 0: dopo.setLen(dopo.len - 1)
    reg.righe.mgetOrPut(numero, @[]).add dopo.join(" · ")
    if numero > reg.massimo: reg.massimo = numero
  reg

proc haDecisioni(r: Registro): bool = r.righe.len > 0

proc relativo(a, daDir: string): string =
  senzaBarre(relativePath(a, daDir))

# ---- le righe del file `.csc`

type
  Def = tuple[eti, dest: string, riga: int]
  Trovato = tuple[col, lung: int, tipo: char, a, b: string, num: int, riga: int]

proc parseDefinizione(commento: string): (bool, string, string) =
  ## D1: il testo del commento (da `--`) è `[Etichetta]:` seguito da almeno uno spazio e dalla destinazione.
  var t = commento
  if not t.startsWith("--"): return (false, "", "")
  t = t[2 .. ^1].strip(trailing = false, chars = {' ', '\t'})
  if not t.startsWith("["): return (false, "", "")
  let c = t.find(']')
  if c < 0: return (false, "", "")
  let eti = t[1 ..< c]
  if not etichettaValida(eti): return (false, "", "")
  if not t.continuesWith(":", c + 1): return (false, "", "")
  let resto = t[c + 2 .. ^1]
  if c + 2 > t.len or resto.len == 0 or not spazio(resto[0]): return (false, "", "")
  let dest = resto.strip
  if dest.len == 0: return (false, "", "")
  (true, normaEtichetta(eti), dest)

proc qualificatore(r: string, idx: int): string =
  ## K2: la parola con almeno due maiuscole, preceduta da un solo spazio, che qualifica il `D-nnn` a `idx`.
  if idx < 2 or r[idx - 1] != ' ' or r[idx - 2] == ' ': return ""
  var k = idx - 2
  while k >= 0:
    var i = k
    while i > 0 and (ord(r[i]) and 0xC0) == 0x80: dec i
    let ch = r.runeAt(i)
    if not cifraOLettera(ch): break
    k = i - 1
  let parola = r[k + 1 .. idx - 2]
  var maiuscole = 0
  for ch in parola.runes:
    if ch.isUpper: inc maiuscole
  if maiuscole >= 2: parola else: ""

proc scansionaRiga(riga: string, n: int, regioni: seq[(int, int)], parole: openArray[string]): seq[Trovato] =
  ## Riferimenti `[Etichetta]`, `[testo](dest)` e `D-nnn` nelle regioni di testo libero (stringhe e commenti) di una riga.
  for (da, a) in regioni:
    var i = da
    while i < a:
      let c = riga[i]
      if c == '`':
        var k = i + 1
        while k < a and riga[k] != '`': inc k
        if k < a: i = k + 1
        else: i = a
        continue
      if c == '[':
        if i > da and riga[i - 1] == '[':
          inc i
          continue
        var j = i + 1
        while j < a and riga[j] != ']': inc j
        if j >= a: break
        let inner = riga[i + 1 ..< j]
        if (j + 1 < a and riga[j + 1] == ']') or not etichettaValida(inner):
          inc i
          continue
        if j + 1 < a and riga[j + 1] == '(':
          var p = j + 2
          while p < a and riga[p] != ')': inc p
          let dest = if p < a: riga[j + 2 ..< p] else: ""
          var bianco = false
          for ch in dest:
            if ch in {' ', '\t'}: bianco = true
          if p < a and dest.len > 0 and not bianco:
            result.add (u16(riga, i), u16(riga[i .. p], p - i + 1), 'i', normaEtichetta(inner), dest, 0, n)
            i = p + 1
            continue
          inc i
          continue
        result.add (u16(riga, i), u16(riga[i .. j], j - i + 1), 'e', normaEtichetta(inner), "", 0, n)
        i = j + 1
        continue
      if c == 'D' and i + 1 < a and riga[i + 1] == '-':
        var k = i + 2
        while k < a and riga[k] in {'0'..'9'}: inc k
        if k > i + 2 and k - (i + 2) <= 9:
          let prima = ultimoCarattere(riga, i)
          let dopoOk = k >= riga.len or not (riga[k].alfanum or (ord(riga[k]) >= 0x80 and lettera(riga.runeAt(k))))
          let primaOk = i == 0 or not (cifraOLettera(prima) or prima == Rune(ord('-')) or prima == Rune(ord('/')))
          if primaOk and dopoOk:
            var q = qualificatore(riga, i)
            if q in parole: q = ""                                       # una parola del linguaggio (BY, IN, …) non qualifica (rilievo su K2)
            result.add (u16(riga, i), u16(riga[i ..< k], k - i), 'd', q, "", parseInt(riga[i + 2 ..< k]), n)
            i = k
            continue
      inc i

proc numeroStatus(riga: string, regioni: seq[(int, int)]): (int, int, int) =
  ## `RATIFIED BY D-nnn` fuori da stringhe e commenti: (byte d'inizio di D-nnn, byte di fine, numero), o (-1, 0, 0).
  var m = riga
  for (da, a) in regioni:
    for k in da ..< a: m[k] = ' '
  let p = m.find("RATIFIED")
  if p < 0: return (-1, 0, 0)
  var k = p + 8
  if k >= m.len or not spazio(m[k]): return (-1, 0, 0)
  while k < m.len and spazio(m[k]): inc k
  if not m.continuesWith("BY", k): return (-1, 0, 0)
  k += 2
  if k >= m.len or not spazio(m[k]): return (-1, 0, 0)
  while k < m.len and spazio(m[k]): inc k
  if not m.continuesWith("D-", k): return (-1, 0, 0)
  let i = k
  k += 2
  let a = k
  while k < m.len and m[k] in {'0'..'9'}: inc k
  if k == a or k - a > 9: return (-1, 0, 0)
  (i, k, parseInt(m[a ..< k]))

proc registroDi(dirCsc: string, defs: Table[string, seq[Def]], errore: var JsonNode): Registro =
  ## G1 poi G2. Se la definizione esplicita non vale, `errore` dice perché (e il risultato è nil).
  errore = nil
  let k = normaEtichetta(etichettaRegistro)
  if k in defs:
    let l = defs[k]
    var dd: seq[string]
    for d in l:
      if d.dest notin dd: dd.add d.dest
    if dd.len >= 2:
      errore = voceErrore("RF-4", etichettaRegistro, "", $l[0].riga, $l[1].riga)
      return nil
    let ds = analizzaDest(dd[0])
    if not ds.ok or ds.url or ds.id.len > 0:
      errore = voceErrore("RF-6", etichettaRegistro, dd[0], if ds.ok and ds.url: "schema" elif ds.ok: "id" else: ds.motivo)
      return nil
    let (pa, cod, dato) = risolviPercorso(dirCsc, ds.percorso)
    if cod.len > 0:
      errore = voceErrore(cod, etichettaRegistro, dd[0], if cod == "RF-1": ds.percorso else: "maiuscole", dato.split('\x01')[^1])
      return nil
    return leggiRegistro(pa)
  var d = dirCsc
  while true:
    let c = d / "WORK_REGISTER.md"
    if fileExists(c):
      let r = leggiRegistro(c)
      if r.haDecisioni: return r
    let p = parentDir(d)
    if p.len == 0 or p == d: break
    d = p
  nil

type
  FileIn* = tuple[nome, dir: string, j: JsonNode]

proc righeDi(j: JsonNode): seq[string] =
  var testi: seq[string]
  for r in j["righe"]:
    let n = if r.hasKey("n") and r["n"].kind == JInt: r["n"].getInt else: 0
    if n < 1: continue
    while testi.len < n: testi.add ""
    testi[n - 1] = if r.hasKey("testo") and r["testo"].kind == JString: r["testo"].getStr else: ""
  testi

proc analisiRiferimenti*(files: seq[FileIn], parole: openArray[string]): (JsonNode, JsonNode) =
  ## (ext, registri). `ext[file]` = {voci, linee, rotti, libero, reg, chiaveReg}; `registri[chiaveReg]` = {nome, righe: {n: testo breve}}.
  ## Le righe del file vengono da `check --json` (`righe[].testo`): la colorazione di edmodello dice dov'è il testo libero.
  var ext = newJObject()
  var registri = newJObject()
  apribili.clear()
  # prima passata: per file, le righe, le definizioni, i candidati e i `RATIFIED BY`
  type Passo = object
    nome, dir: string
    defs: Table[string, seq[Def]]
    trovati: seq[Trovato]
    ratificati: seq[int]
    reg: Registro
    errReg: JsonNode
  var passi: seq[Passo]
  for f in files:
    var p = Passo(nome: f.nome, dir: f.dir, defs: initTable[string, seq[Def]]())
    let testi = righeDi(f.j)
    let segs = coloraRigheSu(testi)
    for i, riga in testi:
      let n = i + 1
      var regioni: seq[(int, int)]
      var pos = 0
      var soloCommento = false
      var inizioCommento = 0
      for s in segs[i]:
        let da = pos
        pos += s.testo.len
        if s.classe == "stringa" or s.classe == "commento":
          regioni.add (da, pos)
          if s.classe == "commento" and riga[0 ..< da].vuota:
            soloCommento = true
            inizioCommento = da
      if soloCommento:
        let (ok, eti, dest) = parseDefinizione(riga[inizioCommento .. ^1])
        if ok:
          p.defs.mgetOrPut(eti, @[]).add (eti, dest, n)
          continue
      for t in scansionaRiga(riga, n, regioni, parole): p.trovati.add t
      let (a, b, num) = numeroStatus(riga, regioni)
      if a >= 0:
        p.ratificati.add num
        p.trovati.add (u16(riga, a), u16(riga[a ..< b], b - a), 's', "", "", num, n)
    var err: JsonNode
    p.reg = registroDi(f.dir, p.defs, err)
    p.errReg = err
    passi.add p
  # P2: per ogni registro, il massimo fra le sue righe e i `RATIFIED BY` dei file che lo usano
  var massimi = initTable[string, int]()
  for p in passi:
    let k = if p.reg != nil: p.reg.percorso else: ""
    var m = massimi.getOrDefault(k, 0)
    if p.reg != nil and p.reg.massimo > m: m = p.reg.massimo
    for x in p.ratificati:
      if x > m: m = x
    massimi[k] = m
  for p in passi:
    var voci = newJObject()
    var linee = newJObject()
    var rotti: seq[int]
    var cacheDest = initTable[string, (JsonNode, string)]()
    var avvisoRegistro = false
    for t in p.trovati:
      var chiave = ""
      var voce: JsonNode
      var apri = ""
      case t.tipo
      of 'e', 'i':
        let dest = if t.tipo == 'i': t.b else: ""
        chiave = (if t.tipo == 'i': "i:" & t.a & "=" & dest else: "e:" & t.a)
        if chiave notin voci.fields:
          if t.tipo == 'e':
            let ds = p.defs.getOrDefault(t.a)
            if ds.len == 0:
              voce = voceErrore("RF-3", t.a, "", t.a)
            else:
              var dd: seq[string]
              for d in ds:
                if d.dest notin dd: dd.add d.dest
              if dd.len >= 2:
                voce = voceErrore("RF-4", t.a, "", $ds[0].riga, $ds[1].riga)
              else:
                let k = p.dir & "\x01" & dd[0]
                if k notin cacheDest: cacheDest[k] = risolviDest(p.dir, dd[0], t.a, p.nome)
                (voce, apri) = cacheDest[k]
          else:
            (voce, apri) = risolviDest(p.dir, dest, t.a, p.nome)
          voci[chiave] = voce
          if apri.len > 0: apribili[p.nome & "\0" & chiave] = apri
      of 'd', 's':
        # K2: con un qualificatore diverso dal nome del progetto del registro, `D-nnn` è testo, senza errore
        if t.tipo == 'd' and t.a.len > 0 and (p.reg == nil or t.a != p.reg.nome): continue
        chiave = "d:" & $t.num
        if chiave notin voci.fields:
          if p.errReg != nil:
            var e = p.errReg.copy
            e["num"] = %t.num
            voci[chiave] = e
          elif p.reg == nil:
            voci[chiave] = voceErrore("RF-8", "", "", "", "", t.num)
          else:
            let rr = p.reg.righe.getOrDefault(t.num)
            let rel = relativo(p.reg.percorso, p.dir)
            if rr.len == 0:
              voci[chiave] = voceErrore("RF-7", "", "", rel, "", t.num)
            else:
              var testo = rr[0]
              var oltre = 0
              if testo.runeLen > maxCarT5:
                testo = testo.runes.toSeq[0 ..< maxCarT5].mapIt($it).join
                oltre = 1
              voci[chiave] = %*{"ok": true, "t": "dec", "num": t.num, "reg": rel, "testo": testo, "volte": rr.len, "oltre": oltre}
      else: discard
      if chiave.len == 0: continue
      let v = voci[chiave]
      if not v["ok"].getBool:
        # G3: un solo avviso per file per le decisioni senza registro
        if v["cod"].getStr == "RF-8":
          if not avvisoRegistro:
            avvisoRegistro = true
            rotti.add t.riga
        else: rotti.add t.riga
      if $t.riga notin linee.fields: linee[$t.riga] = newJArray()
      linee[$t.riga].add %*[t.col, t.lung, chiave]
    let k = if p.reg != nil: p.reg.percorso else: ""
    var fx = %*{"voci": voci, "linee": linee, "rotti": rotti, "libero": massimi.getOrDefault(k, 0) + 1,
      "reg": (if p.reg != nil: relativo(p.reg.percorso, p.dir) else: ""), "chiaveReg": k}
    if p.errReg != nil: fx["regErrore"] = p.errReg
    ext[p.nome] = fx
    if p.reg != nil and k notin registri.fields:
      var rr = newJObject()
      for n, l in p.reg.righe:
        var s = l[0]
        if s.runeLen > maxCartaReg: s = s.runes.toSeq[0 ..< maxCartaReg].mapIt($it).join & "…"
        rr[$n] = %s
      registri[k] = %*{"nome": p.reg.nome, "righe": rr}
  (ext, registri)

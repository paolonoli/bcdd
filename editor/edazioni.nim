# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 003:1:1 edazioni: il testo nuovo di ogni azione del banco. Funzioni pure: da un testo e dal JSON di
# `bcdd check --json` ricavano il testo con UNA riga (o due) in più, senza riformattare niente. La scrittura la fa `bcdd save`.
import std/[json, strutils, algorithm]
import edtesti
from std/unicode import runeLen

proc str(n: JsonNode, k: string): string =
  if n.hasKey(k) and n[k].kind == JString: n[k].getStr else: ""

proc num(n: JsonNode, k: string): int =
  if n.hasKey(k) and n[k].kind == JInt: n[k].getInt else: 0

type RifCasella* = object
  ## 003:5:1 (pezzo 6) Le righe di cui parla un messaggio d'errore: la finestra apre la casella di testo su di esse.
  tipo*, nome*: string            # "entita" o "csc", e il nome
  da*, a*: int                    # 0 se il messaggio non parla di righe

var rifCasella*: RifCasella

proc riferisci(tipo, nome: string, da, a: int) =
  rifCasella = RifCasella(tipo: tipo, nome: nome, da: da, a: a)

proc nuovaEntita*(nome, scopo: string): string =
  ## 003:2:1 Il file di una entità nuova: intestazione, PURPOSE, END.
  "ENTITY " & nome & " VERSION 0.1\n  PURPOSE \"" & scopo & "\"\nEND\n"

proc scopoValido*(s: string): bool =
  ## 003:2:2 Una frase su una riga, senza virgolette e senza caratteri di controllo.
  if s.strip.len == 0 or s.runeLen > 200: return false
  for c in s:
    if c == '"' or ord(c) < 0x20 or ord(c) == 0x7f: return false
  true

proc inserisciDopo*(raw: string, riga: int, testo: string): string =
  ## 003:2:3 Aggiunge `testo` (una o più righe, separate da LF) dopo la riga `riga` (1 = la prima), con il fine riga di quella
  ## riga (CRLF o LF); se è l'ultima e non ha fine riga, il testo nuovo non ne ha neppure. Tutto il resto resta com'è.
  var inizio: seq[int] = @[0]
  for i, c in raw:
    if c == '\n' and i + 1 < raw.len: inizio.add i + 1
  let n = min(max(riga, 0), inizio.len)
  let fine = if n >= inizio.len: raw.len else: inizio[n]
  let crlf = fine >= 2 and raw[fine - 1] == '\n' and raw[fine - 2] == '\r'
  let eol = if crlf: "\r\n" else: "\n"
  let righe = testo.split('\n')
  let conLf = fine > 0 and raw[fine - 1] == '\n'
  var nuovo = ""
  if not conLf and fine > 0:
    # l'ultima riga non ha fine riga: ne serve uno prima, e il testo nuovo non ne ha
    nuovo = eol & righe.join(eol)
  else:
    nuovo = righe.join(eol) & eol
  raw[0 ..< fine] & nuovo & raw[fine .. ^1]

proc bloccoEntita*(j: JsonNode, nome: string): JsonNode =
  ## 003:2:4 Il blocco ENTITY `nome` del JSON di un file, o nil.
  for b in j["blocchi"]:
    if str(b, "tipo") == "ENTITY" and str(b, "nome") == nome and b["intestazione_valida"].getBool: return b

proc dopoIntestazione(b: JsonNode): int =
  ## 003:2:5 L'ultima riga dell'intestazione dell'entità: il PURPOSE se c'è, altrimenti la riga dell'intestazione.
  result = num(b, "da")
  if b.hasKey("scopo") and b["scopo"].kind == JObject: result = max(result, num(b["scopo"], "fino"))

proc aggiungiPubblico*(raw: string, j: JsonNode, entita, csc, lato: string, errore: var string): string =
  ## 003:2:6 `OFFERS csc` o `USES csc` nell'entità, dopo l'ultima riga OFFERS/USES (o dopo il PURPOSE).
  let b = bloccoEntita(j, entita)
  if b == nil:
    errore = tx(kNonTrovoEntitaFile, entita)
    return
  if lato notin ["OFFERS", "USES"]:
    errore = tx(kLatoNonValido, lato)
    return
  var dopo = dopoIntestazione(b)
  for c in b["citazioni"]:
    if str(c, "tipo") in ["OFFERS", "USES"]:
      if str(c, "tipo") == lato and str(c, "nome") == csc:
        errore = tx(if lato == "OFFERS": kHaGiaOffre else: kHaGiaUsa, entita, csc)
        return
      dopo = max(dopo, num(c, "riga"))
  result = inserisciDopo(raw, dopo, "  " & lato & " " & csc)

proc paroleDiRiga(raw: string, n: int): seq[string] =
  let r = raw.splitLines()
  if n < 1 or n > r.len: return
  r[n - 1].replace(":", " : ").splitWhitespace()

proc postoDiRiga*(riga: string): tuple[ok: bool, parte, entita, molt: string] =
  ## una riga `parte : Entità` con in fondo, se c'è, la molteplicità `[m .. n]`. `molt` è
  ## com'è scritta, `m .. n` con gli spazi uguali per tutti ("" se non c'è). Una riga con `VERSION` o con altro non è letta (ok falso).
  var base = riga
  var molt = ""
  let k = riga.find('[')
  if k >= 0:
    let t = riga.strip(leading = false)
    if t.len == 0 or t[^1] != ']' or t.count('[') != 1 or t.count(']') != 1: return
    base = riga[0 ..< k]
    let dentro = t[t.find('[') + 1 ..< t.len - 1]
    let z = dentro.find("..")
    if z < 0: return
    let m = dentro[0 ..< z].strip
    let n = dentro[z + 2 .. ^1].strip
    if m.len == 0 or n.len == 0 or ' ' in m or ' ' in n: return
    molt = m & " .. " & n
  let w = base.replace(":", " : ").splitWhitespace()
  if w.len != 3 or w[1] != ":": return
  (true, w[0], w[2], molt)

proc righePartiMancanti(raw: string, j: JsonNode, b: JsonNode): seq[int] =
  ## 003:2:6b `check` non elenca fra le citazioni un posto la cui entità non c'è nella cartella: lo lascia fra le righe «non
  ## controllate». Le righe di questi posti (`posto : Entità`) contano come parti per l'ordine e per sapere se ne restano.
  if not j["rapporto"].hasKey("non_controllate"): return
  for x in j["rapporto"]["non_controllate"]:
    let r = num(x, "riga")
    if r < num(b, "da") or r > num(b, "a"): continue
    let rr = raw.splitLines()
    if r < 1 or r > rr.len: continue
    let q = postoDiRiga(rr[r - 1])
    if q.ok and q.entita == str(x, "testo"): result.add r

proc aggiungiParte*(raw: string, j: JsonNode, entita, parte, tipo: string, errore: var string, molt = ""): string =
  ## 003:2:7 `COMPOSED OF` se manca e la riga `parte : tipo`, dopo l'ultima parte (o dopo `COMPOSED OF`, o dopo le righe OFFERS/USES).
  let b = bloccoEntita(j, entita)
  if b == nil:
    errore = tx(kNonTrovoEntitaFile, entita)
    return
  var composed = 0
  for r in j["righe"]:
    let n = num(r, "n")
    if n >= num(b, "da") and n <= num(b, "a") and str(r, "tipo") == "riconosciuta" and str(r, "testo").strip == "COMPOSED OF":
      composed = n
      break
  var ultimaParte = 0
  var dopo = dopoIntestazione(b)
  for c in b["citazioni"]:
    case str(c, "tipo")
    of "PART":
      if str(c, "parte") == parte:
        errore = tx(kHaGiaParte, entita, parte)
        return
      ultimaParte = max(ultimaParte, num(c, "riga"))
    of "OFFERS", "USES": dopo = max(dopo, num(c, "riga"))
    else: discard
  for r in righePartiMancanti(raw, j, b): ultimaParte = max(ultimaParte, r)
  let riga = "    " & parte & " : " & tipo & (if molt.len > 0: " [" & molt & "]" else: "")
  if composed > 0:
    result = inserisciDopo(raw, max(composed, ultimaParte), riga)
  else:
    result = inserisciDopo(raw, dopo, "  COMPOSED OF\n" & riga)

# 003:3:1 Togliere: le stesse funzioni pure, che tolgono righe invece di aggiungerne. Si tolgono solo
# righe semplici (le sole parole attese, niente commenti né altro): una riga strana si lascia e si dice di toglierla a mano.
proc righeDi(raw: string): seq[string] =
  ## Le righe del testo con il loro fine riga (l'ultima può non averlo).
  var da = 0
  for i, c in raw:
    if c == '\n':
      result.add raw[da .. i]
      da = i + 1
  if da < raw.len: result.add raw[da .. ^1]

proc togliRighe*(raw: string, daTogliere: seq[int]): string =
  ## 003:3:2 Il testo senza le righe indicate (1 = la prima); il resto non cambia, neppure i fine riga.
  var n = 0
  for r in righeDi(raw):
    inc n
    if n notin daTogliere: result.add r

proc paroleDi(raw: string, n: int): seq[string] =
  let r = righeDi(raw)
  if n < 1 or n > r.len: return
  r[n - 1].replace(":", " : ").splitWhitespace()

proc togliPubblico*(raw: string, j: JsonNode, entita, csc, lato: string, errore: var string): string =
  ## 003:3:3 La riga `OFFERS csc` o `USES csc` dell'entità (tutte quelle uguali, se ce n'è più d'una).
  let b = bloccoEntita(j, entita)
  if b == nil:
    errore = tx(kNonTrovoEntitaFile, entita)
    return
  var righe: seq[int]
  for c in b["citazioni"]:
    if str(c, "tipo") == lato and str(c, "nome") == csc: righe.add num(c, "riga")
  if righe.len == 0:
    errore = tx(if lato == "OFFERS": kNonHaOffre else: kNonHaUsa, entita, csc)
    return
  for n in righe:
    if paroleDi(raw, n) != @[lato, csc]:
      errore = tx(kRigaNonTogliere, n, entita)
      riferisci("entita", entita, n, n)
      return
  togliRighe(raw, righe)

proc togliParti*(raw: string, j: JsonNode, entita: string, daTogliere: seq[string], errore: var string): string =
  ## 003:3:4 Le righe `parte : Entità` dei posti indicati da `COMPOSED OF`, in un solo testo; se non resta nessuna parte, anche la riga
  ## `COMPOSED OF` (Togli l'entità toglie tutti i suoi posti di una entità con una sola scrittura).
  let b = bloccoEntita(j, entita)
  if b == nil:
    errore = tx(kNonTrovoEntitaFile, entita)
    return
  var righe: seq[int]
  var restano = righePartiMancanti(raw, j, b).len
  var trovati: seq[string]
  var perRiga: seq[(int, string)]
  for c in b["citazioni"]:
    if str(c, "tipo") != "PART": continue
    if str(c, "parte") in daTogliere:
      righe.add num(c, "riga")
      perRiga.add (num(c, "riga"), str(c, "parte"))
      if str(c, "parte") notin trovati: trovati.add str(c, "parte")
    else: inc restano
  for p in daTogliere:
    if p notin trovati:
      errore = tx(kNonHaParte, entita, p)
      return
  for (n, parte) in perRiga:
    let rr = raw.splitLines()
    let p = if n >= 1 and n <= rr.len: postoDiRiga(rr[n - 1]) else: (false, "", "", "")
    if not p.ok or p.parte != parte:
      errore = tx(kRigaNonTogliere, n, entita)
      riferisci("entita", entita, n, n)
      return
  if restano == 0:
    for r in j["righe"]:
      let n = num(r, "n")
      if n >= num(b, "da") and n <= num(b, "a") and str(r, "tipo") == "riconosciuta" and str(r, "testo").strip == "COMPOSED OF":
        righe.add n
        break
  togliRighe(raw, righe)

proc togliParte*(raw: string, j: JsonNode, entita, parte: string, errore: var string): string =
  ## 003:3:4 La riga `parte : Entità` da `COMPOSED OF`; se non resta nessuna parte, anche la riga `COMPOSED OF`.
  togliParti(raw, j, entita, @[parte], errore)

# 003:4:1 Pezzo 3, la scheda che scrive. Il testo del file si compone cambiando SOLO le righe di una
# dichiarazione (scopo, promessa, ipotesi, evento, stato): aggiungere, sostituire, togliere. Funzioni pure, come le altre.
const
  # 003:4:2 Le parole riservate di GRAMMATICA_F1 2.3, 136 parole (una sola lista, la stessa di src/bcddcheck.nim; A-1): un nome non può essere una di esse.
  paroleRiservate* = [
    "CSC", "VERSION", "END", "STATUS", "HYPOTHESIS", "RATIFIED", "BY", "PURPOSE", "CAPABILITY", "AUTONOMOUS", "EVENT", "IN",
    "OUT", "STATE", "INITIAL", "DEFINE", "UNDECIDED", "GUARANTEE", "ASSUME", "DETAILS", "VERBAL", "VERIFY", "JUDGEMENT",
    "INSPECTION", "SCENARIO", "GIVEN", "EXPECT", "ADMITTED", "REJECTED", "COMPOSED", "OF", "TYPE", "ENTITY", "OFFERS", "USES",
    "VARIANT", "IMPORT", "PROFILE", "BINDING", "VERIFICATION", "EXTENSION", "WHILE", "ALWAYS", "EVENTUALLY", "WHENEVER", "THEN",
    "WITHIN", "AT", "ONCE", "REPEAT", "FOREVER", "EVERY", "AND", "OR", "NOT", "IMPLIES", "IF", "ELSE", "COUNT", "LAST", "TIME",
    "SINCE", "PREV", "WITH", "ABSENT", "PRESENT", "Record", "NEVER", "AFTER", "BEFORE", "BETWEEN", "UNTIL", "PRECEDES", "FOR",
    "LEAST", "ACCEPTS", "ONLY", "REQUIRES", "ENSURES", "RESOLVES", "CHANGED", "TRANSITION", "ON", "WHEN", "FOLLOWS", "ALL", "ABS",
    "MIN", "MAX", "LOG10", "ROUND", "FLOOR", "CEIL", "KIND", "LEVEL", "PARAMS", "FORM", "MEANING", "REDUCES", "TO", "SOURCE",
    "PATTERN", "SCOPE", "FUNCTION", "DECLARATION", "RELATION", "SCENARIO-FORM", "Name", "Type", "Event", "Condition",
    "Expression", "Duration", "Property", "BIND", "AS", "MEANS", "OBSERVES", "RESOLUTION", "USING", "TRANSLATES", "REFINED",
    "REFINES", "FACE", "LINK", "MAP", "REFINEMENT", "VIEW", "true", "false", "requested", "accepted", "rejected", "completed",
    "failed", "_"]
  tipiDato* = ["Boolean", "Integer", "Real", "String", "Duration"]
  maxFrase* = 400

type Dich* = object
  ## Una dichiarazione della scheda che il modulo conosce, o i campi che il modulo manda.
  genere*: string                 # scopo, promessa, ipotesi, evento, stato
  da*, a*: int                    # le righe che occupa (1 = la prima)
  id*: string                     # id della promessa o dell'ipotesi; nome dell'evento o dello stato
  frase*, come*, chi*: string     # promessa e ipotesi: il testo, JUDGEMENT o INSPECTION, il testo della verifica (scopo: frase)
  verso*: string                  # evento: IN o OUT
  tipoDato*, valore*, unita*: string   # stato: uno dei tipiDato, il valore, s o ms (solo Duration)
  contratto*: bool                # la riga è contratto (ratificata): non si cambia
  testa*: string                  # il tratto di riga prima del testo (rientro compreso), com'è nel file

proc parola(t: string, i: var int, inizio: var int): string =
  ## La prossima parola di `t` da `i` (spazi e tab saltati); `inizio` dice dove comincia.
  while i < t.len and t[i] in {' ', '\t'}: inc i
  inizio = i
  while i < t.len and t[i] notin {' ', '\t', '\r'}: inc i
  t[inizio ..< i]

proc stringaA(t: string, i: int, dentro: var string): bool =
  ## Da `i` in poi `t` è esattamente una stringa `"…"` (senza altre virgolette) e nient'altro.
  var k = i
  while k < t.len and t[k] in {' ', '\t'}: inc k
  let r = t[k .. ^1].strip(leading = false)
  if r.len < 2 or r[0] != '"' or r[^1] != '"': return false
  let d = r[1 ..< r.len - 1]
  if '"' in d: return false
  dentro = d
  true

proc soloSpazi(t: string, i: int): bool =
  for k in i ..< t.len:
    if t[k] notin {' ', '\t', '\r'}: return false
  true

proc numeroOk(s: string): bool =
  ## Cifre con al più un punto, il punto fra due cifre (L4).
  if s.len == 0 or s[0] == '.' or s[^1] == '.' or s.count('.') > 1: return false
  for c in s:
    if c notin {'0'..'9', '.'}: return false
  true

proc senzaSegno(s: string): string =
  ## il `-` attaccato alla prima cifra fa parte del numero; Duration resta senza segno.
  if s.len > 1 and s[0] == '-': s[1 .. ^1] else: s

proc leggiScopo(t: string, d: var Dich): bool =
  var i, s = 0
  if parola(t, i, s) != "PURPOSE": return false
  var f: string
  if not stringaA(t, i, f): return false
  d.frase = f
  d.testa = t[0 ..< t.find('"')]
  true

proc leggiPromessa(l1, l2: string, d: var Dich): bool =
  var i, s = 0
  let kw = parola(l1, i, s)
  if kw notin ["GUARANTEE", "ASSUME"]: return false
  let w = parola(l1, i, s)
  var id = ""
  if w.len >= 2 and w[^1] == ':' and ':' notin w[0 ..< w.len - 1]: id = w[0 ..< w.len - 1]
  else:
    # 003:4:14 (pezzo 6) `GUARANTEE g1 STATUS HYPOTHESIS: VERBAL …` è la forma che Nuova versione lascia alla riga rimessa da approvare: il modulo la conosce
    if w.len == 0 or ':' in w: return false
    if parola(l1, i, s) != "STATUS" or parola(l1, i, s) != "HYPOTHESIS:": return false
    id = w
  let v = parola(l1, i, s)
  if v != "VERBAL": return false
  var frase: string
  if not stringaA(l1, i, frase): return false
  d.testa = l1[0 ..< s]
  d.id = id
  d.frase = frase
  var j, s2 = 0
  if parola(l2, j, s2) != "VERIFY" or parola(l2, j, s2) != "BY": return false
  let c = parola(l2, j, s2)
  if c notin ["JUDGEMENT", "INSPECTION"]: return false
  var chi: string
  if not stringaA(l2, j, chi): return false
  d.come = c
  d.chi = chi
  true

proc leggiEvento(t: string, d: var Dich): bool =
  var i, s = 0
  if parola(t, i, s) != "EVENT": return false
  let verso = parola(t, i, s)
  if verso notin ["IN", "OUT"]: return false
  let nome = parola(t, i, s)
  if nome.len == 0 or not soloSpazi(t, i): return false
  d.verso = verso
  d.id = nome
  d.testa = t[0 ..< t.find('E')]
  true

proc leggiStato(t: string, d: var Dich): bool =
  var i, s = 0
  if parola(t, i, s) != "STATE": return false
  let c = t.find(':', i)
  if c < 0: return false
  let nome = t[i ..< c].strip
  if nome.len == 0 or ' ' in nome or '\t' in nome: return false
  i = c + 1
  let tipo = parola(t, i, s)
  if tipo notin tipiDato or parola(t, i, s) != "INITIAL": return false
  d.id = nome
  d.tipoDato = tipo
  d.testa = t[0 ..< t.find('S')]
  case tipo
  of "String":
    if not stringaA(t, i, d.valore): return false
  of "Boolean":
    let v = parola(t, i, s)
    if v notin ["true", "false"] or not soloSpazi(t, i): return false
    d.valore = v
  of "Duration":
    while i < t.len and t[i] in {' ', '\t'}: inc i
    let k = i
    while i < t.len and t[i] in {'0'..'9', '.'}: inc i
    let n = t[k ..< i]
    let u = t[i .. ^1].strip
    if not numeroOk(n) or u notin ["s", "ms"]: return false
    d.valore = n
    d.unita = u
  of "Integer":
    let v = parola(t, i, s)
    if v.len == 0 or not senzaSegno(v).allCharsInSet({'0'..'9'}) or senzaSegno(v).len == 0 or not soloSpazi(t, i): return false
    d.valore = v
  else:
    let v = parola(t, i, s)
    if not numeroOk(senzaSegno(v)) or not soloSpazi(t, i): return false
    d.valore = v
  true

proc righeTesto(j: JsonNode): seq[string] =
  ## Il testo di ogni riga del file (senza fine riga), per numero: la riga 1 è l'elemento 0.
  for r in j["righe"]:
    let n = num(r, "n")
    while result.len < n: result.add ""
    result[n - 1] = str(r, "testo")

proc bloccoDi*(j: JsonNode, tipo, nome: string): JsonNode =
  ## 003:4:3 Il blocco `tipo` ("ENTITY" o "CSC") di nome `nome`, o nil.
  for b in j["blocchi"]:
    if str(b, "tipo") == tipo and str(b, "nome") == nome and b["intestazione_valida"].getBool: return b

proc dichiarazioniNote*(j, b: JsonNode): seq[Dich] =
  ## 003:4:4 Le dichiarazioni del blocco che il modulo conosce, in ordine di riga. Una promessa ratificata (contratto) c'è sempre,
  ## con `contratto`; le righe che il modulo non sa leggere (altre parole, DETAILS, STATUS, commenti, stringhe su più righe) non ci sono.
  let t = righeTesto(j)
  proc riga(n: int): string = (if n >= 1 and n <= t.len: t[n - 1] else: "")
  if b.hasKey("scopo") and b["scopo"].kind == JObject:
    var d = Dich(genere: "scopo", da: num(b["scopo"], "riga"), a: num(b["scopo"], "fino"))
    if d.da == d.a and leggiScopo(riga(d.da), d): result.add d
  for g in b["garanzie"]:
    let tipo = str(g, "tipo")
    if tipo notin ["GUARANTEE", "ASSUME"]: continue
    var d = Dich(genere: (if tipo == "GUARANTEE": "promessa" else: "ipotesi"), da: num(g, "da"), a: num(g, "a"), id: str(g, "id"))
    if str(g, "stato") == "contratto":
      d.contratto = true
      result.add d
    elif d.a == d.da + 1 and (not g.hasKey("dettaglia") or g["dettaglia"].kind == JNull) and num(g, "livello") == 0 and leggiPromessa(riga(d.da), riga(d.a), d):
      result.add d
  for c in b["dichiarazioni"]:
    let tipo = str(c, "tipo")
    if tipo notin ["EVENT", "STATE"] or num(c, "riga") != num(c, "fino"): continue
    var d = Dich(genere: (if tipo == "EVENT": "evento" else: "stato"), da: num(c, "riga"), a: num(c, "riga"))
    if (if tipo == "EVENT": leggiEvento(riga(d.da), d) else: leggiStato(riga(d.da), d)): result.add d
  result.sort(proc(x, y: Dich): int = cmp(x.da, y.da))

proc validaFrase*(s: string, massimo = maxFrase): string =
  ## 003:4:5 "" se la frase va bene (una riga, senza virgolette né caratteri di controllo, non vuota), altrimenti che cosa non va.
  if s.strip.len == 0: return tx(kScriviFrase)
  if s.runeLen > massimo: return tx(kTroppoLungaMax, massimo)
  for c in s:
    if c == '"': return tx(kVVirgolette)
    if ord(c) < 0x20 or ord(c) == 0x7f: return tx(kVUnaRiga)
  ""

proc validaNomeD*(s: string, altri: seq[string]): string =
  ## 003:4:6 Un nome di evento o di stato: lettere, cifre e _, comincia con una lettera, non riservato, non già usato nella CSC.
  if s.len == 0: return tx(kScriviNome)
  if s.len > 64 or not (s[0] in {'A'..'Z', 'a'..'z'}) or not s.allCharsInSet({'A'..'Z', 'a'..'z', '0'..'9', '_'}):
    return tx(kNomeNonValido, s)
  if s in paroleRiservate: return tx(kParolaRiservata, s)
  if s in ["s", "ms"]: return tx(kUnitaTempo, s)
  if s in altri: return tx(kNomeGiaEsiste)
  ""

proc validaValore*(tipo, valore, unita: string): string =
  ## 003:4:7 Il valore iniziale di uno stato, secondo il tipo (G26, G27).
  case tipo
  of "Boolean": (if valore in ["true", "false"]: "" else: tx(kVScegliSiNo))
  of "Integer": (if senzaSegno(valore).len > 0 and valore.len <= 18 and senzaSegno(valore).allCharsInSet({'0'..'9'}): "" else: tx(kVIntero))
  of "Real": (if numeroOk(senzaSegno(valore)) and valore.len <= 24: "" else: tx(kVReale))
  of "String": validaFrase(valore).replace(tx(kScriviFrase), "")
  of "Duration":
    if not numeroOk(valore) or valore.len > 24: tx(kVNumero60)
    elif unita notin ["s", "ms"]: tx(kVScegliUnita)
    else: ""
  else: tx(kVScegliTipo)

proc validaFormula*(s: string): string =
  ## 003:4:7b A-15 La formula di «scritta come formula»: una o più righe non vuote, senza caratteri di controllo.
  ## Il merito (nomi, tipi, forma) lo controlla `check` dopo la scrittura: una formula con errori si scrive lo stesso e diventa rossa.
  if s.strip.len == 0: return tx(kVScriviFormula)
  if s.runeLen > maxFrase: return tx(kTroppoLungaMax, maxFrase)
  for c in s:
    if (ord(c) < 0x20 and c != '\n') or ord(c) == 0x7f: return tx(kVFormulaCarattere)
  let l = s.strip(chars = {'\n', ' '}).split('\n')
  if l.len > 8: return tx(kVOttoRighe)
  for x in l:
    if x.strip.len == 0: return tx(kVFormulaVuote)

proc validaDich*(d: Dich, altriNomi: seq[string]): string =
  ## 003:4:8 I campi di una dichiarazione che il modulo manda: "" se vanno bene, altrimenti il primo che non va.
  case d.genere
  of "scopo": result = validaFrase(d.frase, 200)
  of "promessa", "ipotesi":
    if d.come == "FORMULA": return validaFormula(d.frase)
    result = validaFrase(d.frase)
    if result.len == 0 and d.come notin ["JUDGEMENT", "INSPECTION"]: result = tx(kVScegliCome)
    if result.len == 0: result = validaFrase(d.chi)
  of "evento":
    result = validaNomeD(d.id, altriNomi)
    if result.len == 0 and d.verso notin ["IN", "OUT"]: result = tx(kVScegliVerso)
  of "stato":
    result = validaNomeD(d.id, altriNomi)
    if result.len == 0: result = validaValore(d.tipoDato, d.valore, d.unita)
  else: result = tx(kVGenereSconosciuto)

proc ultimoNumero(id: string): (string, int) =
  ## `la12` -> ("la", 12); un id senza cifre in fondo -> (id, 0).
  var k = id.len
  while k > 0 and id[k - 1] in {'0'..'9'}: dec k
  if k == id.len or k == 0: return (id, 0)
  (id[0 ..< k], parseInt(id[k .. ^1]))

proc nuovoId*(b: JsonNode, genere, nome: string): string =
  ## 003:4:9 L'id di una promessa o ipotesi nuova: il prefisso delle già nel file e il primo numero libero;
  ## senza nessuna, l'iniziale minuscola del nome (`p1`); le ipotesi: il prefisso delle promesse più `-a` (`p-a1`).
  var usati: seq[string]
  var pg, pa = ""
  for g in b["garanzie"]:
    let id = str(g, "id")
    usati.add id
    let (p, n) = ultimoNumero(id)
    if n == 0 or p.len == 0: continue
    if str(g, "tipo") == "GUARANTEE" and pg.len == 0: pg = p
    if str(g, "tipo") == "ASSUME" and pa.len == 0: pa = p
  if pg.len == 0: pg = nome[0 .. 0].toLowerAscii
  var prefisso = pg
  if genere == "ipotesi": prefisso = if pa.len > 0: pa else: pg & "-a"
  var n = 1
  while prefisso & $n in usati: inc n
  prefisso & $n

proc righeDichiarazione(d: Dich, testa: string): seq[string] =
  ## Le righe da scrivere per `d`; `testa` è il tratto prima del testo (rientro compreso): nuovo, quello standard.
  case d.genere
  of "scopo": @[testa & "\"" & d.frase & "\""]
  of "promessa", "ipotesi":
    if d.come == "FORMULA":
      let l = d.frase.strip(chars = {'\n', ' '}).split('\n')
      result.add testa & l[0].strip
      for k in 1 ..< l.len: result.add ' '.repeat(testa.len) & l[k].strip
      return
    @[testa & "VERBAL \"" & d.frase & "\"", ' '.repeat(testa.len) & "VERIFY BY " & d.come & " \"" & d.chi & "\""]
  of "evento": @[testa & "EVENT " & d.verso & " " & d.id]
  else:
    let v = case d.tipoDato
      of "String": "\"" & d.valore & "\""
      of "Duration": d.valore & " " & d.unita
      else: d.valore
    @[testa & "STATE " & d.id & " : " & d.tipoDato & " INITIAL " & v]

proc sostituisciRighe(raw: string, da, a: int, nuovo: seq[string]): string =
  ## Le righe `da`..`a` diventano `nuovo`, con il fine riga della prima; il resto non cambia.
  let r = righeDi(raw)
  if da < 1 or a > r.len or da > a: return raw
  let eol = if r[da - 1].endsWith("\r\n"): "\r\n" else: "\n"
  for i, l in r:
    let n = i + 1
    if n == da:
      for x in nuovo: result.add x & eol
    if n < da or n > a: result.add l

proc nomiUsati(note: seq[Dich], b: JsonNode, tranne: int): seq[string] =
  ## I nomi di eventi e stati già nel blocco (anche quelli che il modulo non legge), esclusa la riga `tranne`.
  for c in b["dichiarazioni"]:
    if str(c, "tipo") in ["EVENT", "STATE"] and num(c, "riga") != tranne: result.add str(c, "nome")

proc cercaDich(note: seq[Dich], riga: int, genere, id: string): int =
  result = -1
  for i, d in note:
    if d.da == riga and d.genere == genere and d.id == id: return i

proc preparaScheda(j: JsonNode, tipoB, nome, genere: string, errore: var string): JsonNode =
  result = bloccoDi(j, tipoB, nome)
  if result == nil:
    errore = tx(kNonTrovoNelFile, nome)
  elif genere in ["ipotesi", "evento", "stato"] and tipoB != "CSC":
    errore = tx(kSoloInCsc)
    result = nil

proc cambiaScopo*(raw: string, j: JsonNode, tipoB, nome, frase: string, errore: var string): string =
  ## 003:4:10 «Cambia lo scopo»: la riga PURPOSE sostituita (rientro com'è); se manca, ne entra una sotto l'intestazione.
  let b = preparaScheda(j, tipoB, nome, "scopo", errore)
  if b == nil: return
  var d = Dich(genere: "scopo", frase: frase.strip)
  errore = validaDich(d, @[])
  if errore.len > 0: return
  let note = dichiarazioniNote(j, b)
  if b.hasKey("scopo") and b["scopo"].kind == JObject:
    let k = cercaDich(note, num(b["scopo"], "riga"), "scopo", "")
    if k < 0:
      errore = tx(kScopoInCasella, nome)
      riferisci(if tipoB == "CSC": "csc" else: "entita", nome, num(b["scopo"], "riga"), num(b["scopo"], "fino"))
      return
    return sostituisciRighe(raw, note[k].da, note[k].a, righeDichiarazione(d, note[k].testa))
  inserisciDopo(raw, num(b, "da"), "  PURPOSE \"" & d.frase & "\"")

proc aggiungiDich*(raw: string, j: JsonNode, tipoB, nome: string, d0: Dich, errore: var string, idScelto: var string): string =
  ## 003:4:11 Una dichiarazione nuova: dopo l'ultima dello stesso genere, o prima di END.
  let b = preparaScheda(j, tipoB, nome, d0.genere, errore)
  if b == nil: return
  var d = d0
  let note = dichiarazioniNote(j, b)
  if d.genere in ["promessa", "ipotesi"]: d.id = nuovoId(b, d.genere, nome)
  errore = validaDich(d, nomiUsati(note, b, 0))
  if errore.len > 0: return
  idScelto = d.id
  var dopo = 0
  case d.genere
  of "promessa", "ipotesi":
    let tipo = if d.genere == "promessa": "GUARANTEE" else: "ASSUME"
    for g in b["garanzie"]:
      if str(g, "tipo") == tipo: dopo = max(dopo, num(g, "a"))
  else:
    let tipo = if d.genere == "evento": "EVENT" else: "STATE"
    for c in b["dichiarazioni"]:
      if str(c, "tipo") == tipo: dopo = max(dopo, num(c, "fino"))
  if dopo == 0:
    let t = righeTesto(j)
    let fine = num(b, "a")
    if fine < 2 or fine > t.len or t[fine - 1].strip != "END":
      errore = tx(kMancaEnd, nome)
      if fine >= 1 and fine <= t.len: riferisci(if tipoB == "CSC": "csc" else: "entita", nome, fine, fine)
      return
    dopo = fine - 1
  let testa = case d.genere
    of "promessa": "  GUARANTEE " & d.id & ": "
    of "ipotesi": "  ASSUME    " & d.id & ": "
    else: "  "
  inserisciDopo(raw, dopo, righeDichiarazione(d, testa).join("\n"))

proc cambiaDich*(raw: string, j: JsonNode, tipoB, nome: string, riga: int, vecchio: string, d0: Dich, errore: var string): string =
  ## 003:4:12 Sostituisce SOLO le righe di una dichiarazione conosciuta; l'id di promessa e ipotesi resta, il rientro com'è.
  let b = preparaScheda(j, tipoB, nome, d0.genere, errore)
  if b == nil: return
  let note = dichiarazioniNote(j, b)
  let k = cercaDich(note, riga, d0.genere, vecchio)
  if k < 0 or note[k].contratto:
    errore = if k >= 0: tx(kRigaGiaApprovataCambia) else: tx(kRigaCambiataNelFrattempo, riga, nome)
    return
  var d = d0
  if d.genere in ["promessa", "ipotesi"]: d.id = vecchio
  errore = validaDich(d, nomiUsati(note, b, if d.genere in ["evento", "stato"]: riga else: 0))
  if errore.len > 0: return
  sostituisciRighe(raw, note[k].da, note[k].a, righeDichiarazione(d, note[k].testa))

proc togliDich*(raw: string, j: JsonNode, tipoB, nome: string, riga: int, genere, vecchio: string, errore: var string): string =
  ## 003:4:13 Toglie le righe di una dichiarazione conosciuta (un contratto no: lo dice `bcdd save`, ma qui non si prova nemmeno).
  let b = preparaScheda(j, tipoB, nome, genere, errore)
  if b == nil: return
  if genere == "scopo":
    errore = tx(kScopoNonSiToglie)
    return
  let note = dichiarazioniNote(j, b)
  let k = cercaDich(note, riga, genere, vecchio)
  if k < 0:
    errore = tx(kRigaCambiataNelFrattempo, riga, nome)
    return
  if note[k].contratto:
    errore = tx(kRigaGiaApprovataTogli)
    return
  var daTogliere: seq[int]
  for n in note[k].da .. note[k].a: daTogliere.add n
  togliRighe(raw, daTogliere)

# 003:5:2 Pezzo 6, la casella di testo e Nuova versione. Come le altre: funzioni pure, che
# cambiano solo le righe che servono.
const maxTestoCasella* = 8000

proc sostituisciTesto*(raw: string, da, a: int, prima, nuovo: string, errore: var string): string =
  ## 003:5:3 «Scrivi» della casella: le righe `da`..`a` (1 = la prima) diventano le righe di `nuovo`; se `nuovo` è vuoto, si tolgono.
  ## `prima` è il testo che la persona aveva davanti: se quelle righe non sono più quelle, non si scrive niente.
  let r = righeDi(raw)
  if da < 1 or a < da or a > r.len or a - da >= 200:
    errore = tx(kRigheNonCiSono, da, a)
    return
  proc senzaFine(s: string): string = s.strip(leading = false, chars = {'\n', '\r'})
  var attuale, attese: seq[string]
  for i in da .. a: attuale.add senzaFine(r[i - 1])
  for l in prima.split('\n'): attese.add senzaFine(l)
  if attuale != attese:
    errore = tx(kRigheCambiate, da, a)
    return
  for c in nuovo:
    if (ord(c) < 0x20 and c notin {'\n', '\r', '\t'}) or ord(c) == 0x7f:
      errore = tx(kTestoCarattere)
      return
  if nuovo.strip.len == 0:
    var daTogliere: seq[int]
    for n in da .. a: daTogliere.add n
    return togliRighe(raw, daTogliere)
  var nuove: seq[string]
  for l in nuovo.split('\n'): nuove.add senzaFine(l)
  if nuove.len > 0 and nuove[^1].len == 0: nuove.setLen(nuove.len - 1)
  sostituisciRighe(raw, da, a, nuove)

proc versioneValida*(s: string): bool =
  ## 003:5:4 Un numero puntato (GRAMMATICA_F1 L10): gruppi di cifre separati da un punto, `0.2`, `1`, `0.1.2`.
  if s.len == 0 or s.len > 24: return false
  for g in s.split('.'):
    if g.len notin 1 .. 6 or not g.allCharsInSet({'0'..'9'}): return false
  true

proc versioneSuccessiva*(v: string): string =
  ## 003:5:5 L'ultima cifra aumentata di uno: `0.1` -> `0.2`, `1.9` -> `1.10`, `2` -> `3`. "" se `v` non è un numero puntato.
  if not versioneValida(v): return ""
  var g = v.split('.')
  g[^1] = $(parseInt(g[^1]) + 1)
  g.join(".")

proc validaCommento*(s: string): string =
  ## 003:5:6 «Che cosa cambia» finisce in un commento `--` su una riga: "" se va bene.
  if s.strip.len == 0: return tx(kComScrivi)
  if s.runeLen > 200: return tx(kComLunga)
  for c in s:
    if ord(c) < 0x20 or ord(c) == 0x7f: return tx(kComUnaRiga)
  ""

proc sostituisciDopo(l: string, parola: string, nuovo: string, skipColon: bool): string =
  ## In una riga, il pezzo dopo `parola` fino a spazio (o `:`) diventa `nuovo`; "" se `parola` non c'è.
  let p = l.find(parola)
  if p < 0: return ""
  var k = p + parola.len
  while k < l.len and l[k] in {' ', '\t'}: inc k
  var f = k
  while f < l.len and l[f] notin {' ', '\t', '\r', '\n'} and not (skipColon and l[f] == ':'): inc f
  if f == k: return ""
  l[0 ..< k] & nuovo & l[f .. ^1]

proc righeApprovateSue*(b: JsonNode): seq[JsonNode] =
  ## 003:5:7 Le promesse e i presupposti approvati con una loro decisione (`STATUS RATIFIED BY` sulla loro riga): non quelle che
  ## sono contratto perché lo è l'intestazione.
  for g in b["garanzie"]:
    if str(g, "stato") == "contratto" and str(g, "stato_di") == "suo": result.add g

proc nuovaVersione*(raw: string, j: JsonNode, tipoB, nome, versione, frase: string, ids: seq[string], errore: var string): string =
  ## 003:5:8 «Nuova versione»: il commento `-- VERSION x.y: frase` subito sopra l'intestazione, il numero nuovo,
  ## `STATUS HYPOTHESIS` al posto di quello dell'intestazione di un connettore e delle righe scelte. Il resto non cambia.
  let b = bloccoDi(j, tipoB, nome)
  if b == nil:
    errore = tx(kNonTrovoNelFile, nome)
    return
  if not versioneValida(versione):
    errore = tx(kVersioneCifre)
    return
  if versione == str(b, "versione"):
    errore = tx(kVersioneAdesso, versione)
    return
  errore = validaCommento(frase)
  if errore.len > 0: return
  let proprie = righeApprovateSue(b)
  var daRimettere: seq[int]
  for id in ids:
    var riga = 0
    for g in proprie:
      if str(g, "id") == id: riga = num(g, "da")
    if riga == 0:
      errore = tx(kRigaNonApprovataDecisione, id, nome)
      return
    if riga notin daRimettere: daRimettere.add riga
  var r = righeDi(raw)
  let da = num(b, "da")
  if da < 1 or da > r.len:
    errore = tx(kMancaIntestazione, nome)
    return
  # il numero nell'intestazione
  let intest = sostituisciDopo(r[da - 1], "VERSION", versione, false)
  if intest.len == 0:
    errore = tx(kMancaVersioneIntest, nome)
    return
  r[da - 1] = intest
  # l'intestazione approvata di un connettore torna da approvare
  if tipoB == "CSC" and str(b, "stato") == "contratto":
    var trovata = false
    for n in da + 1 .. min(num(b, "a"), r.len):
      let t = r[n - 1].strip
      if t.startsWith("STATUS RATIFIED BY"):
        let rientro = r[n - 1][0 ..< (r[n - 1].len - r[n - 1].strip(trailing = false).len)]
        let eol = if r[n - 1].endsWith("\r\n"): "\r\n" else: "\n"
        r[n - 1] = rientro & "STATUS HYPOTHESIS" & eol
        trovata = true
        break
    if not trovata:
      errore = tx(kMancaStatusIntest, nome)
      return
  for n in daRimettere:
    if r[n - 1].find("STATUS RATIFIED BY") < 0:
      errore = tx(kMancaStatusRiga, n, nome)
      return
    # il pezzo "STATUS RATIFIED BY D-n" diventa "STATUS HYPOTHESIS"
    let p = r[n - 1].find("STATUS RATIFIED BY")
    var k = p + "STATUS RATIFIED BY".len
    while k < r[n - 1].len and r[n - 1][k] in {' ', '\t'}: inc k
    var f = k
    while f < r[n - 1].len and r[n - 1][f] notin {' ', '\t', '\r', '\n', ':'}: inc f
    r[n - 1] = r[n - 1][0 ..< p] & "STATUS HYPOTHESIS" & r[n - 1][f .. ^1]
  let eolIntest = if r[da - 1].endsWith("\r\n"): "\r\n" else: "\n"
  for i, l in r:
    if i == da - 1: result.add "-- VERSION " & versione & ": " & frase.strip & eolIntest
    result.add l

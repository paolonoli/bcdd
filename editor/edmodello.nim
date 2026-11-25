# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 002:1:1 edmodello: dai JSON di `bcdd check --json` dei file di una cartella al modello del banco.
# Funzioni pure, senza GTK: gli stessi JSON danno lo stesso modello, byte per byte. Fa i calcoli del banco: chi espone che
# cosa e da che lato, accoppiamenti, passaggi, connettori liberi, chiusura. Le versioni citate non entrano nel disegno
# (contano i nomi); la parola sulla chiusura la dà `bcdd check` con E14, E16, E17, che qui si riportano così come sono.
import std/[json, strutils, sugar, sequtils, algorithm, tables]
import edazioni, edtesti

const
  formaBanco* = "bcdd-editor-banco"
  versioneBanco* = 1
  codiciChiusura = ["E14", "E16", "E17"]

type
  Parte = object
    parte, entita: string
    riga: int
    offre, usa: seq[string]
    trovata: bool
    molt: string          # la molteplicità della parte, `m .. n` (GRAMMATICA_F1 1.20, G35), "" se non c'è

proc str(n: JsonNode, k: string): string =
  if n.hasKey(k) and n[k].kind == JString: n[k].getStr else: ""

proc num(n: JsonNode, k: string): int =
  if n.hasKey(k) and n[k].kind == JInt: n[k].getInt else: 0

proc nomi(b: JsonNode, tipo: string): seq[string] =
  for c in b["citazioni"]:
    if str(c, "tipo") == tipo and str(c, "nome") notin result: result.add str(c, "nome")

proc haNome(l: seq[string], n: string): bool = n in l

proc fraseDi(testo: string): string =
  ## 002:3:1 Il testo fra le prime virgolette della prima riga di una promessa (la frase che l'operatore ha scritto), o "".
  let prima = testo.splitLines()[0]
  let a = prima.find('"')
  let z = prima.rfind('"')
  if a >= 0 and z > a: prima[a + 1 ..< z] else: ""

const
  generiDichiarazione = [("EVENT", "evento"), ("STATE", "stato"), ("CAPABILITY", "capacita"), ("DEFINE", "costante"),
    ("TYPE", "tipo"), ("SCENARIO", "scenario")]

proc voceGaranzia(g: JsonNode): JsonNode =
  ## 002:3:2 Una promessa o un presupposto da approvare, come lo vede la scheda (Approva).
  result = newJObject()
  result["id"] = %str(g, "id")
  result["genere"] = %(if str(g, "tipo") == "GUARANTEE": "promessa" else: "presupposto")
  result["riga"] = %num(g, "da")
  result["frase"] = %fraseDi(str(g, "testo"))
  result["suo"] = %(str(g, "stato_di") != "intestazione")

proc intero*(b: JsonNode): JsonNode =
  ## 002:3:3 «Approva il connettore intero»: che cosa diventa contratto con l'intestazione e che cosa resta
  ## da approvare. Dai soli dati di check (`stato`, `stato_di`), mai dal testo. null se l'intestazione è già contratto.
  if str(b, "tipo") != "CSC" or str(b, "stato") == "contratto": return newJNull()
  var diventano = newJArray()
  var restano = newJArray()
  var i = newJObject()
  i["genere"] = %"intestazione"
  i["nome"] = %str(b, "nome")
  i["frase"] = %""
  i["riga"] = %num(b, "da")
  diventano.add i
  for c in b["dichiarazioni"]:
    var genere = "dichiarazione"
    for (k, v) in generiDichiarazione:
      if str(c, "tipo") == k: genere = v
    var o = newJObject()
    o["genere"] = %genere
    o["nome"] = %str(c, "nome")
    o["frase"] = %""
    o["riga"] = %num(c, "riga")
    diventano.add o
  for g in b["garanzie"]:
    if str(g, "stato") == "contratto": continue
    var o = voceGaranzia(g)
    if str(g, "stato_di") == "intestazione":
      o["nome"] = o["id"]
      diventano.add o
    else: restano.add o
  result = newJObject()
  result["diventano"] = diventano
  result["restano"] = restano

# 002:6:1 A-2 La colorazione del testo: per ogni riga una lista di segmenti (testo, classe), classe vuota per il resto.
# La colorazione non riconosce: dice solo di che genere è ogni parola. Che una riga sia riconosciuta lo dice `check`.
const
  paroleRitirate = ["REFINED", "REFINES", "FACE", "LINK", "MAP", "REFINEMENT", "VIEW"]
  nomiContesto = ["V1", "V2", "C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"]

type Segmento* = tuple[testo, classe: string]

proc inizioParola(c: char): bool = c in {'A'..'Z', 'a'..'z', '_'}
proc dentroParola(c: char): bool = c in {'A'..'Z', 'a'..'z', '0'..'9', '_'}

proc coloraRigheSu*(righe: seq[string], verify: seq[(int, int)] = @[], estese: seq[(int, int, seq[string])] = @[]): seq[seq[Segmento]] =
  ## 002:6:2 `righe` sono le righe del file (la prima è la riga 1); `verify` gli intervalli di righe (1 = la prima) delle estensioni, dove una riga che
  ## comincia con VERIFY dichiara V1, V2, C1 … C8; `estese` gli intervalli di righe con i nomi delle estensioni che il blocco importa.
  var inStringa = false
  for n0, r in righe:
    let n = n0 + 1
    var segs: seq[Segmento]
    var corrente = ""
    var classe = ""
    proc chiudi() =
      if corrente.len > 0: segs.add (corrente, classe)
      corrente = ""
    proc emetti(t, c: string) =
      if c != classe:
        chiudi()
        classe = c
      corrente.add t
    var inVerify = false
    for (x, y) in verify:
      if n >= x and n <= y and r.strip.startsWith("VERIFY"): inVerify = true
    var nomiEst: seq[string]
    for (x, y, nm) in estese:
      if n >= x and n <= y: nomiEst.add nm
    var i = 0
    while i < r.len:
      let c = r[i]
      if inStringa:
        let z = r.find('"', i)
        if z < 0:
          emetti(r[i .. ^1], "stringa")
          i = r.len
        else:
          emetti(r[i .. z], "stringa")
          i = z + 1
          inStringa = false
        continue
      if c == '"':
        inStringa = true
        emetti("\"", "stringa")
        inc i
      elif c == '-' and i + 1 < r.len and r[i + 1] == '-':
        emetti(r[i .. ^1], "commento")
        i = r.len
      elif inizioParola(c):
        var z = i
        while z < r.len and (dentroParola(r[z]) or (r[z] == '-' and z + 1 < r.len and dentroParola(r[z + 1]) and z > i)): inc z
        let w = r[i ..< z]
        var cl = ""
        if w in paroleRitirate: cl = "ritirata"
        elif w in paroleRiservate: cl = "chiave"
        elif inVerify and w in nomiContesto: cl = "contesto"
        elif w in nomiEst: cl = "estensione"
        emetti(w, cl)
        i = z
      elif c in {'0'..'9'}:
        var z = i
        while z < r.len and r[z] in {'0'..'9'}: inc z
        if z + 1 < r.len and r[z] == '.' and r[z + 1] in {'0'..'9'}:
          inc z
          while z < r.len and r[z] in {'0'..'9'}: inc z
        # l'unità che segue (s o ms), anche dopo uno spazio, se è una parola intera
        var u = z
        while u < r.len and r[u] == ' ': inc u
        var uz = u
        while uz < r.len and r[uz] in {'a'..'z'}: inc uz
        if r[u ..< uz] in ["s", "ms"] and (uz >= r.len or not dentroParola(r[uz])): z = uz
        emetti(r[i ..< z], "numero")
        i = z
      elif c in {'<', '>', '+', '-', '*', '/', '^', ';'}:
        var z = i + 1
        if i + 1 < r.len and ((c == '<' and r[i + 1] in {'=', '>'}) or (c == '>' and r[i + 1] == '=') or (c == '-' and r[i + 1] == '>')): z = i + 2
        emetti(r[i ..< z], "segno")
        i = z
      else:
        emetti($c, "")
        inc i
    chiudi()
    if segs.len == 0: segs.add ("", "")
    result.add segs

proc estensioniDi(j: JsonNode): seq[(int, int)] =
  ## Gli intervalli delle estensioni di ogni profilo del file: da `da` della sua intestazione alla riga prima della successiva o della fine del profilo.
  for b in j["blocchi"]:
    if str(b, "tipo") != "PROFILE" or not b.hasKey("estensioni") or b["estensioni"].kind != JArray: continue
    let ex = b["estensioni"]
    for i in 0 ..< ex.len:
      let fine = if i + 1 < ex.len: num(ex[i + 1], "da") - 1 else: num(b, "a") - 1
      result.add (num(ex[i], "da"), max(fine, num(ex[i], "a")))

proc coloraRighe*(j: JsonNode, estese: seq[(int, int, seq[string])] = @[]): seq[seq[Segmento]] =
  ## 002:6:3 Dal JSON di `check` del file (`righe[].testo`) e dai nomi di estensione importati per intervallo.
  var testi: seq[string]
  for r in j["righe"]:
    let n = num(r, "n")
    while testi.len < n: testi.add ""
    testi[n - 1] = str(r, "testo")
  coloraRigheSu(testi, estensioniDi(j), estese)

proc citaRiga(j, b: JsonNode, n: int): JsonNode =
  ## 002:6:7 A-10/A-11 l'esito della ricerca accanto alla riga che cita un profilo, una CSC legata
  ## o un BINDING (USING): dati, mai frasi (la pagina compone «trovato in …» e «non trovato: …»). null se la riga non cita niente di quel genere.
  ## Trovata: {trovata, tipo, nome, dove, stato_blocco}; non trovata (sezione 7 del rapporto): {trovata, tipo, nome, motivo}.
  for c in b["citazioni"]:
    if num(c, "riga") != n or str(c, "tipo") notin ["IMPORT", "LEGATA", "USING"]: continue
    if c.hasKey("trovata") and c["trovata"].kind == JObject:
      let t = c["trovata"]
      result = newJObject()
      result["trovata"] = %true
      result["tipo"] = %str(c, "tipo")
      result["nome"] = %str(c, "nome")
      result["dove"] = %(if t.hasKey("dove") and t["dove"].kind == JString: t["dove"].getStr else: "")
      result["stato_blocco"] = %(if t.hasKey("stato_blocco") and t["stato_blocco"].kind == JString: t["stato_blocco"].getStr else: "")
      return
  for x in j["rapporto"]["non_controllate"]:
    if num(x, "riga") != n: continue
    var motivo = if x.hasKey("motivo") and x["motivo"].kind == JString: x["motivo"].getStr else: ""
    if motivo.len == 0 and str(x, "tipo") != "IMPORT":
      for r in j["rapporto"]["non_riconosciute"]:
        if num(r, "riga") == n and str(r, "motivo").len > 0: motivo = str(r, "motivo")
    result = newJObject()
    result["trovata"] = %false
    result["tipo"] = %str(x, "tipo")
    result["nome"] = %str(x, "nome")
    result["motivo"] = %motivo
    return
  result = newJNull()

proc scheda(j, b: JsonNode, errori: seq[(int, string, string)], segs: seq[seq[Segmento]] = @[]): JsonNode =
  ## 002:2:1 Le righe del blocco con il loro colore: contratto verde, ipotesi gialla, errore rosso.
  let da = num(b, "da")
  let a = num(b, "a")
  var colore = newSeq[string](max(0, a - da + 1))
  for g in b["garanzie"]:
    let c = if str(g, "stato") == "contratto": "verde" else: "giallo"
    for n in num(g, "da") .. num(g, "a"):
      if n >= da and n <= a: colore[n - da] = c
  # 002:6:4 A-7/A-8 forme concrete e profili seguono lo stato del blocco; un dettaglio di storia o di DEFINE ha lo stato suo
  # (giallo se `check` lo mette fra le ipotesi, verde se no), e le righe di una storia con i suoi passi.
  let tipoBl = str(b, "tipo")
  if tipoBl in ["BINDING", "PROFILE"] and str(b, "stato") in ["ipotesi", "contratto"]:
    for n in da .. a: colore[n - da] = if str(b, "stato") == "contratto": "verde" else: "giallo"
  var ipoRighe: seq[int]
  for x in j["rapporto"]["ipotesi"]:
    if str(x, "tipo") in ["DEFINE", "SCENARIO"]: ipoRighe.add num(x, "riga")
  var testoRiga0: seq[string]
  for r in j["righe"]:
    let n = num(r, "n")
    while testoRiga0.len < n: testoRiga0.add ""
    testoRiga0[n - 1] = str(r, "testo")
  proc haPasso(n: int): bool =
    n >= 1 and n <= testoRiga0.len and (testoRiga0[n - 1].strip.startsWith("@") or testoRiga0[n - 1].strip.startsWith("REPEAT"))
  proc eDettaglio(c: JsonNode): bool =
    let w = str(c, "testo").splitWhitespace
    w.len >= 3 and w[2] == "DETAILS"
  for c in b["dichiarazioni"]:
    if str(c, "tipo") notin ["DEFINE", "SCENARIO"] or not eDettaglio(c): continue
    var z = num(c, "fino")
    if str(c, "tipo") == "SCENARIO":
      while haPasso(z + 1) and z + 1 <= a: inc z
    let col = if num(c, "riga") in ipoRighe: "giallo" else: "verde"
    for n in num(c, "riga") .. z:
      if n >= da and n <= a: colore[n - da] = col
  for (riga, _, _) in errori:
    if riga >= da and riga <= a: colore[riga - da] = "rosso"
  # 002:2:3 (pezzo 3) Le dichiarazioni che il modulo conosce (`dich`); ogni riga dice a quale appartiene (`g`, -1 se a nessuna) e,
  # se a nessuna, che cosa dire al clic: `banco` (OFFERS/USES), `contratto` (STATUS RATIFIED BY), `testo` (si cambia con un editor).
  let note = if str(b, "tipo") in ["CSC", "ENTITY"]: dichiarazioniNote(j, b) else: @[]    # i moduli di scopo, promesse, eventi e stati sono di CSC ed entità
  var dich = newJArray()
  for d in note:
    var o = newJObject()
    o["genere"] = %d.genere
    o["da"] = %d.da
    o["a"] = %d.a
    o["id"] = %d.id
    o["contratto"] = %d.contratto
    for (k, v) in [("frase", d.frase), ("come", d.come), ("chi", d.chi), ("verso", d.verso), ("tipoDato", d.tipoDato),
        ("valore", d.valore), ("unita", d.unita)]:
      if v.len > 0: o[k] = %v
    dich.add o
  # 002:4:1 (pezzo 6) La casella di testo: per ogni riga che nessun modulo conosce, le righe della sua dichiarazione,
  # dalla prima all'ultima secondo i dati di check; uno SCENARIO arriva fino ai suoi passi `@`, `COMPOSED OF` fino alle sue parti.
  var intervalli: seq[(int, int)]
  if b.hasKey("scopo") and b["scopo"].kind == JObject: intervalli.add (num(b["scopo"], "riga"), num(b["scopo"], "fino"))
  var testoRiga: seq[string]
  for r in j["righe"]:
    let n = num(r, "n")
    while testoRiga.len < n: testoRiga.add ""
    testoRiga[n - 1] = str(r, "testo")
  proc passo(n: int): bool = n >= 1 and n <= testoRiga.len and (testoRiga[n - 1].strip.startsWith("@") or testoRiga[n - 1].strip.startsWith("REPEAT"))
  for c in b["dichiarazioni"]:
    var z = num(c, "fino")
    if str(c, "tipo") == "SCENARIO":
      while passo(z + 1) and z + 1 <= a: inc z
    intervalli.add (num(c, "riga"), z)
  for g in b["garanzie"]: intervalli.add (num(g, "da"), num(g, "a"))
  block composto:
    for n in da .. min(a, testoRiga.len):
      if testoRiga[n - 1].strip == "COMPOSED OF":
        var z = n
        var parti: seq[int]
        for c in b["citazioni"]:
          if str(c, "tipo") == "PART": parti.add num(c, "riga")
        while z + 1 in parti: inc z
        intervalli.insert((n, z), 0)
        break composto
  proc intervalloDi(n: int): (int, int) =
    if n == da: return (da, da)
    for (x, y) in intervalli:
      if n >= x and n <= y: return (x, y)
    (n, n)
  # 002:4:2 (pezzo 6) Nuova versione: il commento `-- VERSION x.y` subito sopra l'intestazione dice che la versione
  # in corso è nuova; di che versione valeva prima, il file non lo dice.
  var ripetuti: seq[int]
  block:
    var inStoria, dopoRepeat = false
    for n in da .. min(a, testoRiga.len):
      let t = testoRiga[n - 1].strip
      if t.startsWith("SCENARIO "):
        inStoria = true
        dopoRepeat = false
      elif t.startsWith("REPEAT "):
        if inStoria: dopoRepeat = true
      elif t.startsWith("@"):
        if inStoria and dopoRepeat: ripetuti.add n
      elif t.len > 0 and not t.startsWith("--"):
        inStoria = false
        dopoRepeat = false
  var righe = newJArray()
  for r in j["righe"]:
    let n = num(r, "n")
    if n < da or n > a: continue
    var v = newJObject()
    let testo = str(r, "testo")
    let t = testo.strip
    var g = -1
    for i, d in note:
      if n >= d.da and n <= d.a: g = i
    var nota = ""
    if g < 0:
      # 002:4:4 l'intestazione di un connettore approvato non apre la casella: è un contratto, si cambia con Nuova versione
      if n == da and str(b, "tipo") == "CSC" and str(b, "stato") == "contratto": nota = "contratto"
      elif t.startsWith("STATUS RATIFIED"): nota = "contratto"
      elif t.startsWith("OFFERS ") or t.startsWith("USES "): nota = "banco"
      elif t.len > 0 and not (t == "END" and n == a): nota = "testo"
    var c = colore[n - da]
    if nota == "contratto" and c.len == 0 and t.startsWith("STATUS RATIFIED BY"): c = "verde"
    v["n"] = %n
    v["testo"] = %testo
    v["colore"] = %c
    v["g"] = %g
    v["nota"] = %nota
    if nota == "testo":
      let (x, y) = intervalloDi(n)
      v["ca"] = %x
      v["cb"] = %y
    # 002:3:4 (pezzo 5) «approvata (D-n)» sulla prima riga di ogni riga contratto, e sullo STATUS dell'intestazione
    var approvata = ""
    for g2 in b["garanzie"]:
      if num(g2, "da") == n and str(g2, "stato") == "contratto" and str(g2, "decisione").len > 0:
        approvata = str(g2, "decisione")
    if approvata.len == 0 and nota == "contratto" and t.startsWith("STATUS RATIFIED BY") and str(b, "decisione").len > 0:
      approvata = str(b, "decisione")
    if approvata.len > 0: v["approvata"] = %approvata       # la pagina compone «approvata (D-n)»
    # 002:6:5 A-2/A-6/A-7/A-11: i segmenti colorati, il grado accanto al nome breve, la marca della riga non riconosciuta, la ripetizione
    if n - 1 < segs.len and segs[n - 1].anyIt(it.classe.len > 0):
      var sj = newJArray()
      for (t, c) in segs[n - 1]: sj.add %[t, c]
      v["seg"] = sj
    for g2 in b["garanzie"]:
      if num(g2, "da") == n and str(g2, "grado") in ["verbale", "formale", "estensione_dichiarata"]: v["grado"] = %str(g2, "grado")
    for x in j["rapporto"]["non_riconosciute"]:
      if num(x, "riga") == n:
        v["nonric"] = %(if x.hasKey("motivo") and x["motivo"].kind == JString: x["motivo"].getStr else: "")
    if t.startsWith("REPEAT "):
      let w = t.splitWhitespace
      if w.len >= 5 and w[1] == "FOREVER" and w[2] == "EVERY":
        v["ripete"] = %*{"sempre": true, "ogni": w[3 .. ^1].join(" ")}
      elif w.len >= 5 and w[2] == "EVERY" and ".." in w[1]:
        let mn = w[1].split("..")
        v["ripete"] = %*{"sempre": false, "da": mn[0], "a": mn[^1], "ogni": w[3 .. ^1].join(" ")}
    if n in ripetuti: v["ripetuto"] = %true
    let cn = citaRiga(j, b, n)
    if cn.kind != JNull: v["cita"] = cn
    righe.add v
  # 002:3:5 (pezzo 5) Le righe da approvare del blocco (le gialle) e, per un connettore, il caso «intero»; `blocca` dice perché
  # Approva non parte: errori o righe non riconosciute in QUALUNQUE punto del file (`ratify` vuole `check --strict` sul file).
  var daApprovare = newJArray()
  for g in b["garanzie"]:
    if str(g, "stato") != "contratto": daApprovare.add voceGaranzia(g)
  for c in b["dichiarazioni"]:
    if str(c, "tipo") in ["DEFINE", "SCENARIO"] and eDettaglio(c) and num(c, "riga") in ipoRighe:
      var o = newJObject()
      o["id"] = %str(c, "nome")
      o["genere"] = %"dettaglio"
      o["riga"] = %num(c, "riga")
      o["frase"] = %""
      o["suo"] = %true
      daApprovare.add o
  var blocca = newJArray()
  for e in j["rapporto"]["errori"]:
    blocca.add %tx(kRigaMsg, num(e, "riga"), str(e, "messaggio"))
  for x in j["rapporto"]["non_riconosciute"]:
    blocca.add %tx(kRigaNonRiconosciuta, num(x, "riga"), str(x, "testo").strip)
  # 002:4:3 (pezzo 6) Nuova versione: il bottone c'è per un connettore con l'intestazione approvata, e per un connettore o un'entità
  # con righe approvate con una loro decisione; l'elenco delle righe che si possono rimettere da approvare viene da `stato_di`.
  let tipoB = str(b, "tipo")
  let sue = righeApprovateSue(b)
  var nv = newJNull()
  let intestazioneApprovata = tipoB == "CSC" and str(b, "stato") == "contratto"
  if intestazioneApprovata or sue.len > 0:
    var elenco = newJArray()
    for g in sue:
      var o = newJObject()
      o["id"] = %str(g, "id")
      o["genere"] = %(if str(g, "tipo") == "GUARANTEE": "promessa" else: "presupposto")
      o["frase"] = %fraseDi(str(g, "testo"))
      elenco.add o
    nv = newJObject()
    nv["attuale"] = %str(b, "versione")
    nv["proposta"] = %versioneSuccessiva(str(b, "versione"))
    nv["intestazione"] = %intestazioneApprovata
    nv["righe"] = elenco
  var versioneNuova = false
  if da >= 2 and da - 1 <= testoRiga.len:
    let c = testoRiga[da - 2].strip
    let pre = "-- VERSION " & str(b, "versione")
    if c.startsWith(pre) and (c.len == pre.len or c[pre.len] notin {'0'..'9', '.'}):
      if tipoB == "CSC": versioneNuova = str(b, "stato") != "contratto"
      else:
        for g in b["garanzie"]:
          if str(g, "stato") != "contratto": versioneNuova = true
  result = newJObject()
  result["righe"] = righe
  result["nv"] = nv
  result["versione_nuova"] = %versioneNuova
  result["dich"] = dich
  result["da_approvare"] = daApprovare
  result["intero"] = intero(b)
  result["blocca"] = blocca
  # 002:6:6 A-11 le voci delle sezioni 14 e 15 nel posto del blocco; neutre, non bloccano Approva
  var giud = newJArray()
  for x in j["rapporto"]["da_giudicare"]:
    let r = num(x, "riga")
    if r >= da and r <= a:
      var o = newJObject()
      o["riga"] = %r
      o["voce"] = %str(x, "voce")          # C-4: la voce senza il riferimento alla riga, dal campo di bcdd
      giud.add o
  result["da_giudicare"] = giud
  var ids = newJObject()
  for g in b["garanzie"]: ids[str(g, "id")] = %num(g, "da")
  result["ids"] = ids
  var nonEs = newJArray()
  for x in j["rapporto"]["non_eseguiti"]:
    var rr = newJArray()
    for r in x["righe"]:
      if r.kind == JInt and r.getInt >= da and r.getInt <= a: rr.add r
    if rr.len > 0:
      var o = newJObject()
      o["nome"] = %str(x, "nome")
      o["codice"] = %str(x, "codice")
      o["righe"] = rr
      nonEs.add o
  result["non_eseguiti"] = nonEs

proc erroriIn(j: JsonNode, da, a: int): seq[(int, string, string)] =
  for e in j["rapporto"]["errori"]:
    let r = num(e, "riga")
    if r >= da and r <= a: result.add (r, str(e, "codice"), str(e, "messaggio"))

# 002:7:1 A-8/A-10/A-11 i blocchi BINDING, VERIFICATION e PROFILE: le loro schede e i dati per i moduli.
proc testiDi(j: JsonNode): seq[string] =
  for r in j["righe"]:
    let n = num(r, "n")
    while result.len < n: result.add ""
    result[n - 1] = str(r, "testo")

proc elementiDi(cscB: JsonNode): seq[(string, string, string)] =
  ## (parola chiave + nome come nella sezione 12, nome, genere) di stati, eventi, richieste, costanti; i parametri di un evento come `e.p`.
  for c in cscB["dichiarazioni"]:
    let tipo = str(c, "tipo")
    let nome = str(c, "nome")
    case tipo
    of "STATE": result.add ("STATE " & nome, nome, "stato")
    of "EVENT":
      let w = str(c, "testo").splitWhitespace
      let verso = if w.len > 1 and w[1] in ["IN", "OUT"]: w[1] else: "IN"
      result.add ("EVENT " & verso & " " & nome, nome, "evento")
      let t = str(c, "testo")
      let a = t.find('(')
      let z = t.rfind(')')
      if a > 0 and z > a:
        for pr in t[a + 1 ..< z].split(','):
          let pn = pr.split(':')[0].strip
          if pn.len > 0: result.add ("", nome & "." & pn, "parametro")
    of "CAPABILITY": result.add ("CAPABILITY " & nome, nome, "richiesta")
    of "DEFINE":
      if str(c, "testo").splitWhitespace.len >= 3 and str(c, "testo").splitWhitespace[2] == "DETAILS": continue
      result.add ("", nome, "costante")
    else: discard

proc bloccoCsc(caricati: seq[(string, JsonNode)], nome, versione: string): (string, JsonNode) =
  for (f, j) in caricati:
    for b in j["blocchi"]:
      if str(b, "tipo") == "CSC" and b["intestazione_valida"].getBool and str(b, "nome") == nome and (versione.len == 0 or str(b, "versione") == versione):
        return (f, b)

proc voceBlocco(file: string, j, b: JsonNode, caricati: seq[(string, JsonNode)], segs: seq[seq[Segmento]], conAltri: bool): JsonNode =
  ## BINDING o VERIFICATION: la scheda del blocco con i dati per la linguetta (forme concrete, piano di prova).
  let tipo = str(b, "tipo")
  let da = num(b, "da")
  let a = num(b, "a")
  let t = testiDi(j)
  var errs: seq[(int, string, string)]
  for e in j["rapporto"]["errori"]:
    let r = num(e, "riga")
    if r >= da and r <= a: errs.add (r, str(e, "codice"), str(e, "messaggio"))
  result = newJObject()
  result["tipo"] = %tipo
  result["nome"] = %str(b, "nome")
  result["versione"] = %str(b, "versione")
  result["file"] = %file
  result["riga"] = %da
  result["a"] = %a
  let np = if b.hasKey("nome_proprio") and b["nome_proprio"].kind == JString: b["nome_proprio"].getStr else: ""
  result["nome_proprio"] = %np
  result["stato"] = if b.hasKey("stato"): b["stato"] else: newJNull()
  result["decisione"] = if b.hasKey("decisione"): b["decisione"] else: newJNull()
  result["scheda"] = scheda(j, b, errs, segs)
  var legata = false
  for c in b["citazioni"]:
    if str(c, "tipo") == "LEGATA": legata = true
  result["trovata"] = %legata
  # C-5: gli elementi senza forma concreta e il fatto che la CSC sia stata trovata arrivano come dati (`forme_mancanti[].elementi`, `.csc_trovata`)
  var mancanti = newJArray()
  var cscTrovata = false
  for x in j["rapporto"]["forme_mancanti"]:
    if num(x, "riga") == da:
      cscTrovata = x["csc_trovata"].getBool
      for e in x["elementi"]: mancanti.add e
  result["senza_forma"] = mancanti
  result["tutte_con_forma"] = %(legata and cscTrovata and mancanti.len == 0)
  # C-6: la copertura (sezione 13) come dati: mezzi con le promesse, promesse non eseguite, CSC trovata o no
  var cop = %*{"csc_trovata": true, "mezzi": [], "non_eseguite": []}
  for x in j["rapporto"]["copertura"]:
    if num(x, "riga") == da:
      cop = %*{"csc_trovata": x["csc_trovata"].getBool, "mezzi": x["mezzi"], "non_eseguite": x["non_eseguite"]}
  result["copertura"] = cop
  # gli elementi del connettore legato, per i moduli
  var el = newJArray()
  let (_, cb) = bloccoCsc(caricati, str(b, "nome"), str(b, "versione"))
  if cb != nil:
    for (chiave, nome, genere) in elementiDi(cb):
      var o = newJObject()
      o["nome"] = %nome
      o["genere"] = %genere
      o["senza_forma"] = %(chiave.len > 0 and chiave in mancanti.mapIt(it.getStr))
      el.add o
  result["elementi"] = el
  var righe = newJArray()
  for n in da + 1 .. min(a, t.len):
    let ts = t[n - 1].strip
    let w = ts.splitWhitespace
    if tipo == "BINDING" and w.len >= 2 and w[0] == "BIND":
      var o = newJObject()
      o["n"] = %n
      o["elemento"] = %w[1].strip(chars = {':'})
      let p1 = ts.find('"')
      let p2 = ts.rfind('"')
      o["frase"] = %(if p1 >= 0 and p2 > p1: ts[p1 + 1 ..< p2] else: "")
      o["verbale"] = %(ts.contains("VERBAL"))
      righe.add o
    elif tipo == "VERIFICATION" and w.len >= 2 and w[0] == "MEANS":
      var o = newJObject()
      o["n"] = %n
      o["nome"] = %w[1]
      var osserva: seq[string]
      var i = 2
      if i < w.len and w[i] == "OBSERVES":
        inc i
        while i < w.len and w[i] != "RESOLUTION":
          let x = w[i].strip(chars = {','})
          if x.len > 0: osserva.add x
          inc i
      o["osserva"] = %osserva
      if i + 2 < w.len and w[i] == "RESOLUTION":
        o["risoluzione"] = %w[i + 1]
        o["unita"] = %w[i + 2]
        i += 3
      if i + 1 < w.len and w[i] == "USING": o["usando"] = %w[i + 1]
      righe.add o
  result["righe_forma"] = righe
  # le altre forme concrete dello stesso connettore (con nome), per USING
  var nomi: seq[string]
  for (f, jj) in caricati:
    for bb in jj["blocchi"]:
      if str(bb, "tipo") == "BINDING" and str(bb, "nome") == str(b, "nome") and str(bb, "versione") == str(b, "versione") and bb.hasKey("nome_proprio") and
          bb["nome_proprio"].kind == JString: nomi.add bb["nome_proprio"].getStr
  result["binding_nomi"] = %nomi
  # quale nome passare a `bcdd ratify --csc` e perché a volte non si può
  var csc = ""
  var perche = ""
  if tipo == "BINDING":
    if np.len > 0: csc = np
    else:
      var altri = false
      for bb in j["blocchi"]:
        let tt = str(bb, "tipo")
        if tt in ["CSC", "ENTITY", "PROFILE"] and bb["intestazione_valida"].getBool: altri = true
        if tt == "BINDING" and num(bb, "da") != da: altri = true
      if altri: perche = "senza_nome"          # la frase che dice perché la compone la pagina
      else: csc = str(b, "nome")
  result["csc_arg"] = %csc
  result["senza_nome"] = %(perche.len > 0)
  discard conAltri

proc estensioniDelProfilo(j, b: JsonNode): JsonNode =
  result = newJArray()
  let t = testiDi(j)
  if not b.hasKey("estensioni") or b["estensioni"].kind != JArray: return
  let ex = b["estensioni"]
  for i in 0 ..< ex.len:
    let e = ex[i]
    let da = num(e, "da")
    var fine = if i + 1 < ex.len: num(ex[i + 1], "da") - 1 else: num(b, "a") - 1
    fine = max(fine, num(e, "a"))
    var o = newJObject()
    o["nome"] = %str(e, "nome")
    o["kind"] = %str(e, "kind")
    o["level"] = %str(e, "level")
    o["da"] = %da
    o["a"] = %fine
    o["riduzione"] = %(e.hasKey("riduzione") and e["riduzione"].kind == JBool and e["riduzione"].getBool)
    var campi = newJArray()
    for n in da + 1 .. min(fine, t.len):
      let ts = t[n - 1].strip
      if ts.len == 0 or ts == "END" or ts.startsWith("--"): continue
      var c = newJObject()
      c["n"] = %n
      c["testo"] = %ts
      campi.add c
    o["campi"] = campi
    result.add o

proc voceProfilo(file: string, j, b: JsonNode, caricati: seq[(string, JsonNode)], segs: seq[seq[Segmento]]): JsonNode =
  let da = num(b, "da")
  let a = num(b, "a")
  var errs: seq[(int, string, string)]
  for e in j["rapporto"]["errori"]:
    let r = num(e, "riga")
    if r >= da and r <= a: errs.add (r, str(e, "codice"), str(e, "messaggio"))
  result = newJObject()
  result["tipo"] = %"PROFILE"
  result["nome"] = %str(b, "nome")
  result["versione"] = %str(b, "versione")
  result["file"] = %file
  result["riga"] = %da
  result["a"] = %a
  result["stato"] = if b.hasKey("stato"): b["stato"] else: newJNull()
  result["decisione"] = if b.hasKey("decisione"): b["decisione"] else: newJNull()
  result["scopo"] = if b.hasKey("scopo") and b["scopo"].kind == JObject:
      %(str(b["scopo"], "testo").strip.dup(removePrefix("PURPOSE")).strip.strip(chars = {'"'}))
    else: %""
  result["scheda"] = scheda(j, b, errs, segs)
  result["estensioni"] = estensioniDelProfilo(j, b)
  # chi lo importa (per «Togli»): i blocchi della cartella con una citazione IMPORT a questo profilo e versione
  var chi = newJArray()
  for (f, jj) in caricati:
    for bb in jj["blocchi"]:
      for c in bb["citazioni"]:
        if str(c, "tipo") == "IMPORT" and str(c, "nome") == str(b, "nome") and str(c, "versione_citata") == str(b, "versione"):
          chi.add %(str(bb, "tipo") & " " & str(bb, "nome"))
  result["importato_da"] = chi
  result["csc_arg"] = %str(b, "nome")

proc esteseDi(j: JsonNode, profili: seq[(string, string, seq[string])]): seq[(int, int, seq[string])] =
  ## Per ogni blocco del file i nomi delle estensioni dei profili che importa (trovati nella cartella, con la stessa versione).
  for b in j["blocchi"]:
    var nomiE: seq[string]
    for c in b["citazioni"]:
      if str(c, "tipo") != "IMPORT" or not (c.hasKey("trovata") and c["trovata"].kind == JObject): continue
      for (pn, pv, ne) in profili:
        if pn == str(c, "nome") and pv == str(c, "versione_citata"): nomiE.add ne
    if nomiE.len > 0: result.add (num(b, "da"), num(b, "a"), nomiE)

proc buildBanco*(cartella: string, caricati: seq[(string, JsonNode)]): JsonNode =
  ## 002:2:2 `caricati` è l'elenco (nome del file, JSON di check) in ordine di nome di file.
  result = newJObject()
  result["forma"] = %formaBanco
  result["versione"] = %versioneBanco
  result["cartella"] = %cartella
  result["lingua"] = %($lingua)          # la pagina prende da qui la lingua (M.lingua)
  result["riservate"] = %paroleRiservate
  # prima passata: le entità, per sapere che cosa espone ogni parte
  var nomiEntita: seq[string]
  var offreDi, usaDi: seq[seq[string]]
  for (_, j) in caricati:
    for b in j["blocchi"]:
      if str(b, "tipo") != "ENTITY" or not b["intestazione_valida"].getBool: continue
      nomiEntita.add str(b, "nome")
      offreDi.add nomi(b, "OFFERS")
      usaDi.add nomi(b, "USES")
  # 002:7:2 la colorazione del testo di ogni file (A-2), con i nomi delle estensioni che i blocchi importano
  var profiliNoti: seq[(string, string, seq[string])]
  for (_, j) in caricati:
    for b in j["blocchi"]:
      if str(b, "tipo") == "PROFILE" and b["intestazione_valida"].getBool and b.hasKey("estensioni") and b["estensioni"].kind == JArray:
        profiliNoti.add (str(b, "nome"), str(b, "versione"), b["estensioni"].mapIt(str(it, "nome")))
  var segsDi: Table[string, seq[seq[Segmento]]]
  for (file, j) in caricati: segsDi[file] = coloraRighe(j, esteseDi(j, profiliNoti))
  var entita = newJArray()
  var csc = newJArray()
  var tutteCsc: seq[string]
  for (_, j) in caricati:
    for b in j["blocchi"]:
      if str(b, "tipo") == "CSC" and b["intestazione_valida"].getBool: tutteCsc.add str(b, "nome")
  for (file, j) in caricati:
    for b in j["blocchi"]:
      let tipo = str(b, "tipo")
      if not b["intestazione_valida"].getBool or tipo notin ["ENTITY", "CSC"]: continue
      let nome = str(b, "nome")
      let da = num(b, "da")
      let a = num(b, "a")
      let errs = erroriIn(j, da, a)
      var v = newJObject()
      v["nome"] = %nome
      v["file"] = %file
      v["riga"] = %da
      v["scopo"] = if b.hasKey("scopo") and b["scopo"].kind == JObject:
          %(str(b["scopo"], "testo").strip.dup(removePrefix("PURPOSE")).strip.strip(chars = {'"'}))
        else: %""
      # C-10: «lo scopo è ancora da compilare» lo dice `bcdd` (un solo riconoscitore), la pagina non guarda il testo
      v["scopo_da_compilare"] = %(b.hasKey("scopo") and b["scopo"].kind == JObject and b["scopo"].hasKey("da_compilare") and b["scopo"]["da_compilare"].getBool)
      var altri = newJArray()
      var chiusuraCheck: seq[string]
      for (riga, codice, msg) in errs:
        if codice in codiciChiusura: chiusuraCheck.add tx(kRigaMsg, riga, msg)
        else:
          var e = newJObject()
          e["riga"] = %riga
          e["codice"] = %codice
          e["messaggio"] = %msg
          altri.add e
      v["errori"] = altri
      v["scheda"] = scheda(j, b, errs, segsDi[file])
      if tipo == "CSC":
        v["stato"] = %str(b, "stato")
        v["decisione"] = if b.hasKey("decisione"): b["decisione"] else: newJNull()
        var offerta, usata: seq[string]
        for i, n in nomiEntita:
          if haNome(offreDi[i], nome): offerta.add n
          if haNome(usaDi[i], nome): usata.add n
        v["offerta_da"] = %offerta
        v["usata_da"] = %usata
        # 002:5:2 Il connettore ha righe approvate (contratto): non si toglie. La finestra lo controlla prima di scrivere.
        var apprC = str(b, "stato") == "contratto"
        for g in b["garanzie"]:
          if str(g, "stato") == "contratto": apprC = true
        v["approvata"] = %apprC
        csc.add v
        continue
      let offre = nomi(b, "OFFERS")
      let usa = nomi(b, "USES")
      # 002:5:1 L'entità ha righe approvate (contratto): non si toglie, e non se ne toglie un posto. La finestra lo controlla prima di scrivere.
      var approvata = false
      for g in b["garanzie"]:
        if str(g, "stato") == "contratto": approvata = true
      v["approvata"] = %approvata
      v["offre"] = %offre
      v["usa"] = %usa
      var parti: seq[Parte]
      for c in b["citazioni"]:
        if str(c, "tipo") != "PART": continue
        var p = Parte(parte: str(c, "parte"), entita: str(c, "nome"), riga: num(c, "riga"))
        # `molteplicita` è {"min","max"} o null (null anche per un limite con il punto, E19): in quel caso si legge dalla riga
        if c.hasKey("molteplicita") and c["molteplicita"].kind == JObject:
          p.molt = $num(c["molteplicita"], "min") & " .. " & $num(c["molteplicita"], "max")
        else:
          for rg in j["righe"]:
            if num(rg, "n") == p.riga:
              let q = postoDiRiga(str(rg, "testo"))
              if q.ok: p.molt = q.molt
        let k = nomiEntita.find(p.entita)
        if k >= 0:
          p.trovata = true
          p.offre = offreDi[k]
          p.usa = usaDi[k]
        parti.add p
      # 002:5:2 `check` non elenca fra le citazioni un posto la cui entità non c'è nella cartella: lo lascia fra le righe «non
      # controllate» (solo il nome dell'entità). Il posto si ricava dalla riga del file, `posto : Entità`, e resta un posto con `trovata` falso.
      for x in j["rapporto"]["non_controllate"]:
        let r = num(x, "riga")
        if r < da or r > a or str(x, "tipo") != "PART": continue
        for rg in j["righe"]:
          if num(rg, "n") != r: continue
          let q = postoDiRiga(str(rg, "testo"))
          if q.ok and q.entita == str(x, "nome") and not parti.anyIt(it.riga == r):
            parti.add Parte(parte: q.parte, entita: q.entita, riga: r, trovata: false, molt: q.molt)
      parti = parti.sortedByIt(it.riga)
      var nonTrovate: seq[string]
      for x in j["rapporto"]["non_controllate"]:
        let r = num(x, "riga")
        if r >= da and r <= a: nonTrovate.add tx(kRigaMsg, r, str(x, "nome"))
      var jp = newJArray()
      for i, p in parti:
        var o = newJObject()
        o["parte"] = %p.parte
        o["entita"] = %p.entita
        o["riga"] = %p.riga
        o["trovata"] = %p.trovata
        o["molteplicita"] = %p.molt
        o["offre"] = %p.offre
        o["usa"] = %p.usa
        o["colonna"] = %i
        jp.add o
      v["parti"] = jp
      # accoppiamenti: X offerta da una parte e usata da un'altra
      var acc = newJArray()
      var offertaDa, usataDa: seq[(string, string)]    # (csc, parte) di tutte le parti
      for p in parti:
        for x in p.offre: offertaDa.add (x, p.parte)
        for x in p.usa: usataDa.add (x, p.parte)
      for (x, pa) in offertaDa:
        for (y, pb) in usataDa:
          if x == y and pa != pb:
            var o = newJObject()
            o["csc"] = %x
            o["da"] = %pa
            o["a"] = %pb
            acc.add o
      v["accoppiamenti"] = acc
      # passaggi: una CSC pubblica che una parte espone dallo stesso lato
      var pass = newJArray()
      var problemi = newJArray()
      proc problema(codice, csc, lato, parte, testo: string) =
        var o = newJObject()
        o["codice"] = %codice
        o["csc"] = %csc
        o["lato"] = %lato
        o["parte"] = %parte
        o["testo"] = %testo
        problemi.add o
      for x in offre:
        var tenuta = false
        for p in parti:
          if haNome(p.offre, x):
            tenuta = true
            var o = newJObject()
            o["csc"] = %x
            o["lato"] = %"OFFERS"
            o["parte"] = %p.parte
            pass.add o
        if not tenuta: problema("E16", x, "OFFERS", "", tx(kPubNonAffidatoOfferto, x, nome))
      for x in usa:
        var tenuta = false
        for p in parti:
          if haNome(p.usa, x):
            tenuta = true
            var o = newJObject()
            o["csc"] = %x
            o["lato"] = %"USES"
            o["parte"] = %p.parte
            pass.add o
        if not tenuta: problema("E16", x, "USES", "", tx(kPubNonAffidatoUsato, x, nome))
      v["passaggi"] = pass
      # liberi: i connettori delle parti che nessun'altra parte accoppia
      var liberi = newJArray()
      for p in parti:
        for x in p.offre:
          var usata = false
          for (y, pb) in usataDa:
            if y == x and pb != p.parte: usata = true
          if usata: continue
          let pubblico = haNome(offre, x)
          var o = newJObject()
          o["parte"] = %p.parte
          o["csc"] = %x
          o["lato"] = %"OFFERS"
          o["pubblico"] = %pubblico
          liberi.add o
          if not pubblico:
            problema("E17", x, "OFFERS", p.parte, tx(kParteOffreNessuno, p.parte, x, nome))
        for x in p.usa:
          var offerta = false
          for (y, pb) in offertaDa:
            if y == x and pb != p.parte: offerta = true
          if offerta: continue
          let pubblico = haNome(usa, x)
          var o = newJObject()
          o["parte"] = %p.parte
          o["csc"] = %x
          o["lato"] = %"USES"
          o["pubblico"] = %pubblico
          liberi.add o
          if not pubblico:
            problema("E14", x, "USES", p.parte, tx(kParteUsaNessuno, p.parte, x, nome))
      v["liberi"] = liberi
      v["problemi"] = problemi
      v["non_trovate"] = %nonTrovate
      # lo stato: non scomposta, sospesa, zoppa, chiusa
      var messaggi: seq[string]
      var st = "non_scomposta"
      if parti.len > 0:
        if nonTrovate.len > 0:
          st = "sospesa"
          messaggi = nonTrovate
        elif problemi.len > 0 or chiusuraCheck.len > 0:
          st = "zoppa"
          if chiusuraCheck.len > 0: messaggi = chiusuraCheck
          else:
            for p in problemi: messaggi.add p["testo"].getStr
        else:
          st = "chiusa"
      v["stato"] = %st
      v["messaggi"] = %messaggi
      entita.add v
  # 002:7:3 A-8: i blocchi BINDING e VERIFICATION stanno nella scheda del loro connettore; i profili e i blocchi senza connettore nell'albero
  var profili = newJArray()
  var senzaCsc = newJArray()
  var legatiA: Table[string, JsonNode]
  for (file, j) in caricati:
    for b in j["blocchi"]:
      let tipo = str(b, "tipo")
      if not b["intestazione_valida"].getBool: continue
      if tipo == "PROFILE":
        profili.add voceProfilo(file, j, b, caricati, segsDi[file])
      elif tipo in ["BINDING", "VERIFICATION"]:
        let vb = voceBlocco(file, j, b, caricati, segsDi[file], false)
        if vb["trovata"].getBool:
          if str(b, "nome") notin legatiA: legatiA[str(b, "nome")] = newJArray()
          legatiA[str(b, "nome")].add vb
        else: senzaCsc.add vb
  for v in csc:
    let n = v["nome"].getStr
    v["blocchi"] = if n in legatiA: legatiA[n] else: newJArray()
  result["profili"] = profili
  result["senza_connettore"] = senzaCsc
  result["entita"] = entita
  result["csc"] = csc

# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 067:1:1 le prove L-B1..L-B15 di `bcdd` in due lingue (L-B16 è la sonda A/B fuori suite, L-B17 la suite esistente).
# 067:1:2 Incluso da tbcdd.nim, dopo tutte le altre prove: usa i suoi aiuti (rec, run, runX, mkEnv, refEnv, newRef, proveCsc).
from "../src/bcddtesti" import Chiave, voci, segnaposti

proc envLang(lang: string): StringTableRef =
  ## 067:2:1 Ambiente senza BCDD_*, più BCDD_LANG se `lang` non è vuoto ("" = non impostata).
  result = mkEnv(@[])
  result.del("BCDD_LANG")
  if lang.len > 0: result["BCDD_LANG"] = lang

proc runL(args: seq[string], lang = "", cwd = root): Res = runX(bcdd, args, cwd, envLang(lang))

proc cwdOf(f: string): string = root

# 067:2:2 L'elenco chiuso L dei campi di testo del JSON di `check`: il valore dipende dalla lingua
proc stripL(j: JsonNode) =
  proc dropKeys(n: JsonNode, ks: seq[string]) =
    if n.kind == JObject:
      for k in ks:
        if n.hasKey(k): n.delete(k)
  j.dropKeys(@["lingua"])
  for b in j["blocchi"]:
    for c in b["citazioni"]:
      if c["trovata"].kind == JObject: c["trovata"].dropKeys(@["stato"])
  let r = j["rapporto"]
  for e in r["errori"]: e.dropKeys(@["messaggio", "in"])
  for e in r["composizioni"]: e.dropKeys(@["nomi"])
  for e in r["non_riconosciute"]: e.dropKeys(@["motivo"])
  for e in r["non_controllate"]: e.dropKeys(@["testo", "motivo"])
  for e in r["usi"]: e.dropKeys(@["testo", "in"])
  for e in r["assenze"]: e.dropKeys(@["messaggio", "in"])
  for e in r["forme_mancanti"]: e.dropKeys(@["testo"])
  for e in r["copertura"]: e.dropKeys(@["righe"])
  for e in r["da_giudicare"]: e.dropKeys(@["testo", "voce"])
  for e in r["non_eseguiti"]: e.dropKeys(@["nome"])
  j["esito"].dropKeys(@["riga"])

proc compFields(j: JsonNode, daIt: bool): seq[string] =
  ## 067:2:5 L-B18 (0.2): i quattro campi dei nomi delle composizioni; per l'italiano `con `/`senza ` diventano `with `/`without `
  ## nel prefisso di ogni valore (spezzato su "; " e su ", ").
  proc conv(v: string): string =
    if not daIt: return v
    var out1: seq[string]
    for a in v.split("; "):
      var out2: seq[string]
      for b in a.split(", "):
        if b.startsWith("con "): out2.add "with " & b[4 .. ^1]
        elif b.startsWith("senza "): out2.add "without " & b[6 .. ^1]
        else: out2.add b
      out1.add out2.join(", ")
    out1.join("; ")
  let r = j["rapporto"]
  for e in r["composizioni"]:
    if e["nomi"].kind == JArray:
      for x in e["nomi"]: result.add conv(x.getStr)
  for k in ["errori", "usi", "assenze"]:
    for e in r[k]:
      if e["in"].kind == JString: result.add conv(e["in"].getStr)

proc lValues(j: JsonNode): seq[string] =
  ## 067:2:3 I valori di testo dei campi di L (per la sonda delle parole italiane nell'uscita inglese).
  for b in j["blocchi"]:
    for c in b["citazioni"]:
      if c["trovata"].kind == JObject: result.add c["trovata"]["stato"].getStr
  let r = j["rapporto"]
  for e in r["errori"]:
    result.add e["messaggio"].getStr
    if e["in"].kind == JString: result.add e["in"].getStr
  for e in r["composizioni"]:
    if e["nomi"].kind == JArray:
      for x in e["nomi"]: result.add x.getStr
  for e in r["non_riconosciute"]:
    if e["motivo"].kind == JString: result.add e["motivo"].getStr
  for e in r["non_controllate"]:
    result.add e["testo"].getStr
    if e["motivo"].kind == JString: result.add e["motivo"].getStr
  for e in r["usi"]:
    result.add e["testo"].getStr
    if e["in"].kind == JString: result.add e["in"].getStr
  for e in r["assenze"]:
    result.add e["messaggio"].getStr
    if e["in"].kind == JString: result.add e["in"].getStr
  for e in r["forme_mancanti"]: result.add e["testo"].getStr
  for e in r["copertura"]:
    for x in e["righe"]: result.add x.getStr
  for e in r["da_giudicare"]:
    result.add e["testo"].getStr
    result.add e["voce"].getStr
  for e in r["non_eseguiti"]: result.add e["nome"].getStr
  result.add j["esito"]["riga"].getStr

const spiaWords = ["riga", "righe", "errore", "errori", "nessun", "nessuna", "della", "\xC3\xA8", "non", "manca", "alla", "deve", "con", "senza"]

proc wordsOf(s: string): seq[string] =
  var cur = ""
  for c in s:
    if c.isAlphaNumeric or c == '_' or ord(c) >= 128: cur.add c
    else:
      if cur.len > 0: result.add cur
      cur = ""
  if cur.len > 0: result.add cur

proc spiaHits(output, source: string): seq[string] =
  ## 067:2:4 Le parole spia italiane nell'uscita, tranne quelle che stanno nel file controllato (testo che viene dal file).
  let src = wordsOf(source)
  for w in wordsOf(output):
    if w in spiaWords and w notin src and w notin result: result.add w

proc numsOf(l: string): seq[string] =
  var cur = ""
  for c in l:
    if c in {'0' .. '9'}: cur.add c
    else:
      if cur.len > 0: result.add cur
      cur = ""
  if cur.len > 0: result.add cur
  result.sort()

# 067:3:1 L-B1, L-B2, L-B3: la scelta della lingua
block:
  let r = runL(@["check", "prove/01_minima.csc"])
  rec("L-B1", "senza --lang e senza BCDD_LANG: rapporto inglese", r.code == 0 and "\nlines: " in r.output and r.output.endsWith("outcome: no errors\n"), r.output & r.errout)
  let e = runL(@["check", "prove/non_esiste.csc"])
  rec("L-B1", "senza --lang e senza BCDD_LANG: errore inglese", e.code == 2 and e.errout == "bcdd check: file not found: prove/non_esiste.csc\n", e.errout)

block:
  let f = "prove/01_minima.csc"
  proc isIt(r: Res): bool = r.code == 0 and "\nrighe: " in r.output and "esito: nessun errore" in r.output
  proc isEn(r: Res): bool = r.code == 0 and "\nlines: " in r.output and "outcome: no errors" in r.output
  rec("L-B2", "BCDD_LANG=it senza --lang: italiano", isIt(runL(@["check", f], "it")), "")
  rec("L-B2", "BCDD_LANG=en senza --lang: inglese", isEn(runL(@["check", f], "en")), "")
  rec("L-B2", "--lang it senza variabile: italiano", isIt(runL(@["--lang", "it", "check", f])), "")
  rec("L-B2", "--lang en prevale su BCDD_LANG=it", isEn(runL(@["--lang", "en", "check", f], "it")), "")
  rec("L-B2", "--lang it prevale su BCDD_LANG=en", isIt(runL(@["--lang", "it", "check", f], "en")), "")
  let r = runL(@["check", "--lang", "it", f])
  rec("L-B2", "--lang dopo il comando: uso sbagliato del comando, codice 2", r.code == 2 and r.output.len == 0 and
    r.errout == "usage: bcdd check [--strict] [--json] [--dir FOLDER]... FILE\n", r.errout)
  let r2 = runL(@["check", "--lang", "it", f], "it")
  rec("L-B2", "--lang dopo il comando, BCDD_LANG=it: la riga d'uso è italiana", r2.code == 2 and r2.errout.startsWith("uso: bcdd check "), r2.errout)
  rec("L-B2", "LANG non si legge", block:
    let env = envLang("")
    env["LANG"] = "it_IT.UTF-8"
    env["LC_ALL"] = "it_IT.UTF-8"
    env["LANGUAGE"] = "it"
    isEn(runX(bcdd, @["check", f], root, env)), "")

block:
  let f = "prove/01_minima.csc"
  proc usoErr(r: Res, msg: string): bool = r.code == 2 and r.output.len == 0 and r.errout == msg & "\n"
  let usoEn = "usage: bcdd [--lang it|en] COMMAND; commands: new NAME | check [--strict] [--json] [--dir FOLDER]... FILE | refine FILE [--csc NAME] | ratify FILE [--csc NAME] [--dir FOLDER]... [ID | --all] D-number | rename FILE [--csc NAME] [--dir FOLDER]... (--dry-run | --expect FINGERPRINT) csc|entity|part|id OLD NEW | rename --recover FOLDER"
  let r1 = runL(@["--lang"])
  rec("L-B3", "--lang senza valore", r1.code == 2 and r1.output.len == 0 and r1.errout == usoEn & "\n", r1.errout)
  let r2 = runL(@["--lang", "fr", "check", f])
  rec("L-B3", "--lang fr", usoErr(r2, "bcdd: --lang accepts it or en: fr"), r2.errout)
  let r3 = runL(@["--lang", "IT", "check", f])
  rec("L-B3", "--lang IT (maiuscolo)", usoErr(r3, "bcdd: --lang accepts it or en: IT"), r3.errout)
  let r3b = runL(@["--lang", "fr", "check", f], "it")
  rec("L-B3", "--lang fr con BCDD_LANG=it: il messaggio è italiano", usoErr(r3b, "bcdd: --lang accetta it oppure en: fr"), r3b.errout)
  let r3c = runL(@["--lang", ""])
  rec("L-B3", "--lang \"\"", usoErr(r3c, "bcdd: --lang accepts it or en: "), r3c.errout)
  let r4 = runL(@["--lang", "it", "--lang", "en", "check", f])
  rec("L-B3", "--lang ripetuto", r4.code == 2 and r4.output.len == 0, r4.errout)
  let r5 = runL(@["--lang", "en"])
  rec("L-B3", "--lang en senza comando", r5.code == 2 and r5.output.len == 0 and r5.errout == usoEn & "\n", r5.errout)
  let r6 = runL(@["check", f], "fr")
  rec("L-B3", "BCDD_LANG=fr", usoErr(r6, "bcdd: BCDD_LANG must be it or en, not: fr"), r6.errout)
  let r6b = runL(@["--lang", "it", "check", f], "fr")
  rec("L-B3", "BCDD_LANG=fr con --lang valido: la variabile non si legge", r6b.code == 0 and "righe:" in r6b.output, r6b.errout)
  let r7 = runX(bcdd, @["check", f], root, block:
    let env = envLang("")
    env["BCDD_LANG"] = ""
    env)
  rec("L-B3", "BCDD_LANG vuota = non impostata (inglese)", r7.code == 0 and "lines:" in r7.output, r7.errout)

# 067:4:1 L-B4: parità strutturale su ogni .csc di prove/, L-B5: sonda delle parole italiane
block:
  var nFile, nNumFail, nJsonFail, nCodeFail, nSpia, nComp, nCompFail, nConPrefisso = 0
  var compDetail: seq[string]
  var failed: seq[string]
  var spiaDetail: seq[string]
  for f in proveCsc():
    let d = f.parentDir
    inc nFile
    let src = readFile(root / f)
    let it = runL(@["check", "--dir", d, f], "it")
    let en = runL(@["check", "--dir", d, f], "en")
    let li = it.output.splitLines()
    let le = en.output.splitLines()
    var okN = li.len == le.len and it.code == en.code
    if okN:
      for i in 0 ..< li.len:
        if numsOf(li[i]) != numsOf(le[i]): okN = false
    if not okN:
      inc nNumFail
      failed.add f & " (testo)"
    let ji = runL(@["check", "--json", "--dir", d, f], "it")
    let je = runL(@["check", "--json", "--dir", d, f], "en")
    if ji.code != je.code: inc nCodeFail
    var okJ = false
    if ji.output.len == 0 and je.output.len == 0 and ji.code == je.code: okJ = true
    else:
     try:
      let a = parseJson(ji.output)
      let b = parseJson(je.output)
      let lv = lValues(b)
      var hits: seq[string]
      for v in lv:
        for h in spiaHits(v, src):
          if h notin hits: hits.add h
      if hits.len > 0:
        inc nSpia
        spiaDetail.add f & ": " & hits.join(",")
      let ca = compFields(a, true)
      let cb = compFields(b, false)
      if ca.len > 0 or cb.len > 0:
        inc nComp
        if ca != cb:
          inc nCompFail
          compDetail.add f
        if cb.anyIt("with " in it or "without " in it): inc nConPrefisso
      stripL(a)
      stripL(b)
      okJ = a == b and a["versione"].getInt == 5
     except CatchableError: okJ = false
    if not okJ:
      inc nJsonFail
      failed.add f & " (json)"
    let hitsT = spiaHits(en.output, src)
    if hitsT.len > 0:
      inc nSpia
      spiaDetail.add f & " (testo): " & hitsT.join(",")
    let si = runL(@["check", "--strict", "--dir", d, f], "it")
    let se = runL(@["check", "--strict", "--dir", d, f], "en")
    if si.code != se.code: inc nCodeFail
  rec("L-B4", "parità del rapporto (righe e numeri) su " & $nFile & " file", nNumFail == 0 and nFile > 300, $nNumFail & " file: " & failed.join("; "))
  rec("L-B4", "parità del JSON dopo aver tolto i campi di L", nJsonFail == 0, $nJsonFail & " file: " & failed.join("; "))
  rec("L-B4", "stesso codice d'uscita, anche con --strict", nCodeFail == 0, $nCodeFail)
  rec("L-B18", "nomi delle composizioni: JSON it dopo con->with e senza->without uguale a en (" & $nComp & " file con composizioni, " & $nConPrefisso & " con with/without)",
    nCompFail == 0 and nComp > 0 and nConPrefisso > 0, compDetail.join("; "))
  rec("L-B5", "nessuna parola spia italiana nel rapporto e nei campi di L inglesi (file di prova)", nSpia == 0, spiaDetail.join("; "))

block:
  # 067:4:2 L-B5: i casi di errore sullo standard error, `new`, `ratify` e `save`, in inglese
  let w = newWd()
  discard cpTo(root / "prove/01_minima.csc", w)
  writeFile(w / "Bad.csc", "CSC A VERSION 1\n\xFF\n")
  createDir(w / "una_cartella")
  var outs: seq[string]
  proc add(r: Res) = outs.add r.output & r.errout
  add runL(@["check", "nonesiste.csc"], "en", w)
  add runL(@["check", "una_cartella"], "en", w)
  add runL(@["check", "Bad.csc"], "en", w)
  add runL(@["check", "--dir", "nonesiste", "01_minima.csc"], "en", w)
  add runL(@["check", "--dir", "01_minima.csc", "01_minima.csc"], "en", w)
  add runL(@["new", "A-B"], "en", w)
  add runL(@["new", "Nuova"], "en", w)
  add runL(@["new", "Nuova"], "en", w)
  add runL(@["new"], "en", w)
  add runL(@["ratify", "01_minima.csc", "D-1"], "en", w)
  add runL(@["ratify", "01_minima.csc", "g9", "D-1"], "en", w)
  add runL(@["ratify", "01_minima.csc", "g1", "x"], "en", w)
  add runL(@["ratify", "Nuova.csc", "D-1"], "en", w)
  add runL(@["ratify", "nonesiste.csc", "D-1"], "en", w)
  add runL(@["ratify"], "en", w)
  add runL(@["save", "01_minima.csc", "--expect", "x"], "en", w)
  add runL(@["save"], "en", w)
  add runL(@["bcdd"], "en", w)
  var hits: seq[string]
  for o in outs:
    for h in spiaHits(o, readFile(w / "01_minima.csc")):
      if h notin hits: hits.add h
  rec("L-B5", "nessuna parola spia italiana negli errori, in new, ratify e save inglesi", hits.len == 0, hits.join(",") & "\n" & outs.join("\n"))
  # la sonda deve fallire sul binario di prima (prova che misura)
  let prima = getHomeDir() / "bcdd-work" / "1.0-beta" / "probes" / "lingue" / "bcdd.prima-lingue"
  if fileExists(prima):
    let r = runX(prima, @["check", "01_minima.csc"], w, nil)
    rec("L-B5", "la sonda fallisce sul binario di prima delle lingue", spiaHits(r.output, "").len > 0, r.output)

# 067:5:1 L-B6: parità del catalogo e completezza a compilazione
block:
  var nChiavi, vuote, segn = 0
  var bad: seq[string]
  for k in Chiave:
    inc nChiavi
    if voci[k].it.len == 0 or voci[k].en.len == 0: inc vuote; bad.add $k
    if segnaposti(voci[k].it) != segnaposti(voci[k].en): inc segn; bad.add $k & " (segnaposto)"
  rec("L-B6", "catalogo: " & $nChiavi & " chiavi, nessun testo vuoto, stessi segnaposto", nChiavi > 400 and vuote == 0 and segn == 0, bad.join(", "))
  # prova negativa: una voce senza il testo inglese non compila
  let tmp = newWd()
  let orig = readFile(root / "src" / "bcddtesti.nim")
  let target = "  voce kNewCreato, \"creato $1\", \"created $1\"\n"
  rec("L-B6", "la voce di prova esiste nel catalogo", target in orig, "")
  writeFile(tmp / "bcddtesti.nim", orig)
  writeFile(tmp / "main.nim", "import bcddtesti\necho testo(kNewCreato, \"x\")\n")
  let ok0 = execShellCmd("cd " & quoteShell(tmp) & " && nim c --hints:off --verbosity:0 --nimcache:" & quoteShell(tmp / "c0") & " main.nim > /dev/null 2>&1")
  writeFile(tmp / "bcddtesti.nim", orig.replace(target, "  voce kNewCreato, \"creato $1\"\n"))
  let ok1 = execShellCmd("cd " & quoteShell(tmp) & " && nim c --hints:off --verbosity:0 --nimcache:" & quoteShell(tmp / "c1") & " main.nim > /dev/null 2>&1")
  rec("L-B6", "completezza a compilazione: il catalogo intero compila, senza il testo inglese di una voce no", ok0 == 0 and ok1 != 0, "codici " & $ok0 & " e " & $ok1)

# 067:6:1 L-B7: scheletro di `new` in due lingue e riconoscitore dei due prefissi
block:
  let rf = f2Dir / "refine"
  var nOk = 0
  var why: seq[string]
  for lgNew in ["it", "en"]:
    let w = newWd()
    let n = runL(@["--lang", lgNew, "new", "Sk"], "", w)
    let body = readFile(w / "Sk.csc")
    let prefix = if lgNew == "it": "\"da scrivere" else: "\"to be filled in"
    rec("L-B7", "lo scheletro creato con " & lgNew & " ha lo scopo " & prefix, n.code == 0 and prefix in body, body)
    for lgRead in ["it", "en"]:
      let c = runL(@["--lang", lgRead, "check", "Sk.csc"], "", w)
      let j = runL(@["--lang", lgRead, "check", "--json", "Sk.csc"], "", w)
      var dc = false
      try: dc = parseJson(j.output)["blocchi"][0]["scopo"]["da_compilare"].getBool
      except CatchableError: dc = false
      let aux = auxOf(w)
      let rr = runX(bcddProva, @["--lang", lgRead, "refine", "--json", "Sk.csc"], w, refEnv(w, @[("BCDD_FINTO_RISPOSTA", rf / "risposte" / "buona.json")]))
      let okc = c.code == 0 and dc and "\"errore\": \"scopo_da_scrivere\"" in rr.output and rr.code == 1
      if okc: inc nOk else: why.add lgNew & "/" & lgRead & ": " & c.output & j.output & rr.output & rr.errout
  rec("L-B7", "quattro incroci (scheletro it/en x lingua it/en): check senza errori, da_compilare, scopo_da_scrivere", nOk == 4, why.join("\n"))
  let w = newWd()
  writeFile(w / "Cap.csc", "CSC Cap VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"To be filled in: x\"\nEND\n")
  let j = runL(@["check", "--json", "Cap.csc"], "en", w)
  var dc2 = true
  try: dc2 = parseJson(j.output)["blocchi"][0]["scopo"]["da_compilare"].getBool
  except CatchableError: dc2 = true
  rec("L-B7", "\"To be filled in\" con la maiuscola non è riconosciuta", not dc2, j.output)

# 067:6:2 L-B7: i tre prefissi dello scopo da scrivere sono riconosciuti, refine risponde senza chiamare l'LLM
block:
  let rf = f2Dir / "refine"
  var nOk = 0
  var why: seq[string]
  for pre in ["da scrivere: x", "da compilare: x", "to be filled in: x"]:
    let w = newWd()
    writeFile(w / "Cap.csc", "CSC Cap VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"" & pre & "\"\nEND\n")
    let j = runL(@["check", "--json", "Cap.csc"], "it", w)
    var dc = false
    try: dc = parseJson(j.output)["blocchi"][0]["scopo"]["da_compilare"].getBool
    except CatchableError: dc = false
    let rr = runX(bcddProva, @["--lang", "it", "refine", "--json", "Cap.csc"], w, refEnv(w, @[("BCDD_FINTO_RISPOSTA", rf / "risposte" / "buona.json")]))
    let ok = dc and "\"errore\": \"scopo_da_scrivere\"" in rr.output and rr.code == 1
    if ok: inc nOk else: why.add pre & ": " & j.output & rr.output & rr.errout
  rec("L-B7", "D-407: «da scrivere», «da compilare» e «to be filled in» sono scopo da scrivere: da_compilare vero, refine senza giro", nOk == 3, why.join("\n"))

# 067:7:1 L-B8, L-B9, L-B10, L-B14: refine in due lingue (solo l'LLM finto)
block:
  let rf = f2Dir / "refine"
  let rs = rf / "risposte"
  proc go(wd: string, resp: string, args: seq[string], lang: string, input: string = "", extra: seq[(string, string)] = @[]): Res =
    discard auxOf(wd)
    let env = refEnv(wd, @[("BCDD_FINTO_RISPOSTA", resp)] & extra)
    env["BCDD_LANG"] = lang
    runX(bcddProva, @["refine"] & args, wd, env, input)
  # L-B9: la richiesta all'LLM
  block:
    let w = newRef(rf / "Luce.csc")
    let aux = auxOf(w)
    let r = go(w, rs / "buona.json", @["Luce.csc"], "en", "about three minutes\ny\nn\ny\n", @[("BCDD_FINTO_RICHIESTA", aux / "richiesta"),
      ("BCDD_FINTO_RICHIESTA_2", aux / "richiesta2"), ("BCDD_FINTO_RISPOSTA_2", rs / "buona_seconda.json")])
    let rq = readFile(aux / "richiesta")
    rec("L-B9", "con en la richiesta è costruita dal modello inglese", rq.startsWith("You are the assistant of bcdd refine.") and "{{" notin rq, rq[0 .. min(200, rq.high)])
    rec("L-B9", "con en la seconda richiesta contiene il modello inglese del seguito", fileExists(aux / "richiesta2") and
      "ANSWERS OF THE PERSON IN THIS ROUND" in readFile(aux / "richiesta2"), r.output & r.errout)
    # L-B14: lettere inglesi: y n q; la s non è accettata
    rec("L-B14", "en: l'uscita chiede y = yes, n = no, q = quit e accetta le lettere inglesi", r.code == 0 and
      "accept? y = yes, n = no, q = quit (discards the rest): " in r.output, r.output & r.errout)
    let w2 = newRef(rf / "Luce.csc")
    let r2 = go(w2, rs / "buona.json", @["Luce.csc"], "en", "about three minutes\ns\ny\nn\ny\n", @[("BCDD_FINTO_RISPOSTA_2", rs / "buona_seconda.json")])
    rec("L-B14", "en: la lettera s non è accettata (si chiede di ripetere)", "answer y, n or q\n" in r2.output, r2.output)
    let w3 = newRef(rf / "Luce.csc")
    let r3 = go(w3, rs / "buona.json", @["Luce.csc"], "it", "fra tre minuti circa\ny\ns\nn\ns\n", @[("BCDD_FINTO_RISPOSTA_2", rs / "buona_seconda.json")])
    rec("L-B14", "it: la lettera y non è accettata, le lettere italiane valgono", "rispondi s, n oppure f\n" in r3.output and r3.code == 0, r3.output)
  # L-B8: il dialogo
  block:
    let w = newRef(rf / "Luce.csc")
    let r = go(w, rs / "buona.json", @["Luce.csc"], "en", "about three minutes\ny\nn\ny\n", @[("BCDD_FINTO_RISPOSTA_2", rs / "buona_seconda.json")])
    let d = readFile(w / "Luce.csc.dialogo")
    rec("L-B8", "dialogo creato con en: commento inglese e marcatori invariati", d.startsWith("-- bcdd refine: questions from the language model and answers from the person.") and
      "\nGIRO " in d and "\nDOMANDA " in d and "\nRISPOSTA " in d, d)
    # un dialogo italiano esistente con un giro aggiunto in en: il resto non cambia
    let w2 = newRef(rf / "Luce.csc")
    let prima = readFile(rf / "T22_scelta.dialogo")
    writeFile(w2 / "Luce.csc.dialogo", prima)
    let r2 = go(w2, rs / "buona.json", @["Luce.csc"], "en", "about three minutes\ny\nn\ny\n", @[("BCDD_FINTO_RISPOSTA_2", rs / "buona_seconda.json")])
    let d2 = readFile(w2 / "Luce.csc.dialogo")
    rec("L-B8", "dialogo italiano esistente con un giro in en: i byte di prima restano, il giro si aggiunge", d2.startsWith(prima) and d2.len > prima.len and
      d2.startsWith("-- bcdd refine: domande dell'LLM"), r2.output & r2.errout)
  # L-B10: la lingua del giro
  block:
    let w = newRef(rf / "Luce.csc")
    let aux = auxOf(w)
    let t1 = go(w, rs / "buona.json", @["--json", "Luce.csc"], "it")
    let g1 = readFile(w / "Luce.csc.giro")
    rec("L-B10", "tempo 1 con it: FILE.giro porta \"lingua\": \"it\"", t1.code == 0 and "\"lingua\": \"it\"" in g1, t1.output & t1.errout)
    let t2 = go(w, rs / "buona.json", @["--json", "--answers", "Luce.csc"], "en", "{\"risposte\": [{\"n\": 1, \"scelta\": 2}]}",
      @[("BCDD_FINTO_RICHIESTA_2", aux / "richiesta2"), ("BCDD_FINTO_RISPOSTA_2", rs / "buona_seconda.json")])
    let rq2 = if fileExists(aux / "richiesta2"): readFile(aux / "richiesta2") else: ""
    rec("L-B10", "tempo 2 con --lang en su un giro italiano: la richiesta viene dal modello italiano", t2.code == 0 and rq2.startsWith("Sei l'assistente di bcdd refine.") and
      "RISPOSTE DELLA PERSONA IN QUESTO GIRO" in rq2, t2.output & t2.errout & rq2[0 .. min(120, rq2.high)])
    let bad = go(w, rs / "buona.json", @["--json", "--answers", "Luce.csc"], "en", "{")
    rec("L-B10", "i messaggi del tempo 2 seguono la lingua del comando (en)", bad.code == 2 and "standard input is not a JSON object" in bad.errout, bad.errout)
    # un giro senza il campo lingua vale it
    let w2 = newRef(rf / "Luce.csc")
    let aux2 = auxOf(w2)
    let u1 = go(w2, rs / "buona.json", @["--json", "Luce.csc"], "en")
    rec("L-B10", "tempo 1 con en: FILE.giro porta \"lingua\": \"en\"", "\"lingua\": \"en\"" in readFile(w2 / "Luce.csc.giro"), u1.output & u1.errout)
    writeFile(w2 / "Luce.csc.giro", readFile(w2 / "Luce.csc.giro").replace("\"lingua\": \"en\", ", ""))
    let u2 = go(w2, rs / "buona.json", @["--json", "--answers", "Luce.csc"], "en", "{\"risposte\": [{\"n\": 1, \"scelta\": 2}]}",
      @[("BCDD_FINTO_RICHIESTA_2", aux2 / "richiesta2"), ("BCDD_FINTO_RISPOSTA_2", rs / "buona_seconda.json")])
    let rq3 = if fileExists(aux2 / "richiesta2"): readFile(aux2 / "richiesta2") else: ""
    rec("L-B10", "un giro senza il campo lingua vale it", u2.code == 0 and rq3.startsWith("Sei l'assistente di bcdd refine."), u2.output & u2.errout)
  # L-B11: fase_diversa
  block:
    let w = newRef(rf / "Luce.csc")
    discard go(w, rs / "scartate.json", @["--json", "Luce.csc"], "en")
    let a = go(w, rs / "scartate.json", @["--json", "--answers", "Luce.csc"], "en", "{\"risposte\": []}")
    rec("L-B11", "tempo 2 su un giro in fase proposte", a.code == 2 and "\"errore\": \"fase_diversa\", \"fase\": \"proposte\"" in a.output and
      a.errout.len > 0, a.output & a.errout)
    let w2 = newRef(rf / "Luce.csc")
    discard go(w2, rs / "buona.json", @["--json", "Luce.csc"], "en")
    let f2 = go(w2, rs / "buona.json", @["--json", "--answers", "Luce.csc"], "en", "{\"risposte\": [{\"n\": 1, \"scelta\": 2}]}",
      @[("BCDD_FINTO_CODICE_2", "3")])
    rec("L-B11", "premessa: la seconda chiamata fallita lascia il giro in risposte_fallite", "risposte_fallite" in readFile(w2 / "Luce.csc.giro"), f2.output & f2.errout)
    let b = go(w2, rs / "buona.json", @["--json", "--answers", "Luce.csc"], "en", "{\"risposte\": []}")
    rec("L-B11", "tempo 2 su un giro in risposte_fallite", b.code == 2 and "\"errore\": \"fase_diversa\", \"fase\": \"risposte_fallite\"" in b.output, b.output & b.errout)
    let c = go(w2, rs / "buona.json", @["--json", "--show", "Luce.csc"], "en")
    rec("L-B11", "--show su un giro in risposte_fallite", c.code == 2 and "\"errore\": \"fase_diversa\", \"fase\": \"risposte_fallite\"" in c.output, c.output & c.errout)
    let bi = go(w2, rs / "buona.json", @["--json", "--answers", "Luce.csc"], "it", "{\"risposte\": []}")
    rec("L-B11", "il messaggio sullo standard error segue la lingua del comando (it)", bi.code == 2 and "non aspetta risposte" in bi.errout, bi.errout)

# 067:8:1 L-B12: campi nuovi di `check --json` e ragioni di scarto di `refine --json`, uguali in it e in en
block:
  proc both(args: seq[string], cwd = root): (JsonNode, JsonNode) =
    let i = runL(@["check", "--json"] & args, "it", cwd)
    let e = runL(@["check", "--json"] & args, "en", cwd)
    (parseJson(i.output), parseJson(e.output))
  proc sameNew(a, b: JsonNode, path: seq[string]): bool =
    ## i campi nuovi, tranne quelli in L, sono uguali nelle due lingue
    var x = a
    var y = b
    for p in path:
      x = x[p]
      y = y[p]
    x == y
  # sezione 12: elementi mancanti
  let (f1i, f1e) = both(@["--dir", "prove/w12/blk", "prove/w12/blk/ac348.csc"])
  let fm = f1e["rapporto"]["forme_mancanti"]
  rec("L-B12", "forme_mancanti: blocco, csc_trovata, elementi", fm.len >= 1 and fm[0]["csc_trovata"].getBool and fm[0]["elementi"].len > 0 and
    fm[0]["blocco"].getStr.startsWith("BINDING ") and f1i["rapporto"]["forme_mancanti"][0]["elementi"] == fm[0]["elementi"] and
    f1i["rapporto"]["forme_mancanti"][0]["blocco"] == fm[0]["blocco"], $fm)
  let (f2i, f2e) = both(@["--dir", "prove/w12/blk", "prove/w12/blk/ac351.csc"])
  let fn = f2e["rapporto"]["forme_mancanti"]
  rec("L-B12", "forme_mancanti con CSC non trovata: csc_trovata falso, elementi vuoti", fn.len >= 1 and not fn[0]["csc_trovata"].getBool and fn[0]["elementi"].len == 0 and
    f2i["rapporto"]["forme_mancanti"][0]["csc_trovata"] == fn[0]["csc_trovata"], $fn)
  # sezione 13: copertura
  let (c1i, c1e) = both(@["--dir", "prove/w12/blk", "prove/w12/blk/ac353.csc"])
  let cp = c1e["rapporto"]["copertura"]
  var okC = cp.len >= 1 and cp[0]["csc_trovata"].getBool and cp[0]["mezzi"].len > 0
  if okC:
    let m = cp[0]["mezzi"][0]
    okC = m.hasKey("nome") and m["riga"].kind == JInt and m["promesse"].kind == JArray and cp[0]["non_eseguite"].kind == JArray and
      c1i["rapporto"]["copertura"][0]["mezzi"] == cp[0]["mezzi"] and c1i["rapporto"]["copertura"][0]["non_eseguite"] == cp[0]["non_eseguite"]
  rec("L-B12", "copertura: mezzi (nome, riga, promesse) e non_eseguite", okC, $cp)
  let wv = newWd()
  writeFile(wv / "V.csc", "VERIFICATION Mancante VERSION 0.1\n  MEANS cam OBSERVES accesa RESOLUTION 40 ms\nEND\n")
  let (c2i, c2e) = both(@["V.csc"], wv)
  let cn = c2e["rapporto"]["copertura"]
  rec("L-B12", "copertura con CSC non trovata: csc_trovata falso, nessun mezzo", cn.len >= 1 and not cn[0]["csc_trovata"].getBool and cn[0]["mezzi"].len == 0 and
    c2i["rapporto"]["copertura"][0]["csc_trovata"] == cn[0]["csc_trovata"], $cn)
  # sezione 14: voce senza il riferimento alla riga
  let (d1i, d1e) = both(@["prove/03_details_inesistente.csc"])
  let dg = d1e["rapporto"]["da_giudicare"]
  rec("L-B12", "da_giudicare: voce senza «line N:», testo = «line N: voce»", dg.len >= 1 and dg[0]["testo"].getStr == "line " & $dg[0]["riga"].getInt & ": " & dg[0]["voce"].getStr and
    d1i["rapporto"]["da_giudicare"][0]["testo"].getStr == "riga " & $dg[0]["riga"].getInt & ": " & d1i["rapporto"]["da_giudicare"][0]["voce"].getStr, $dg)
  # sezione 15: codice
  let (n1i, n1e) = both(@["prove/14_non_riconosciute.csc"])
  let ne = n1e["rapporto"]["non_eseguiti"]
  var okN = ne.len >= 1
  for k in 0 ..< ne.len:
    if ne[k]["codice"] != n1i["rapporto"]["non_eseguiti"][k]["codice"] or ne[k]["codice"].getStr notin ["storie", "copertura_inneschi", "coerenza_presupposti_promesse", "coerenza_dettagli"]:
      okN = false
  rec("L-B12", "non_eseguiti: codice uguale nelle due lingue", okN, $ne)
  # sezione 7: tipo, nome, motivo
  let (m1i, m1e) = both(@["--dir", "prove/f3/citazioni", "prove/f3/citazioni/Citazioni.csc"])
  let nc = m1e["rapporto"]["non_controllate"]
  var okM = nc.len >= 1
  var conMotivo = false
  for k in 0 ..< nc.len:
    let a = m1i["rapporto"]["non_controllate"][k]
    if a["tipo"] != nc[k]["tipo"] or a["nome"] != nc[k]["nome"] or (a["motivo"].kind == JNull) != (nc[k]["motivo"].kind == JNull): okM = false
    if nc[k]["motivo"].kind == JString: conMotivo = true
    if nc[k]["tipo"].getStr notin ["OFFERS", "USES", "PART", "LEGATA", "USING", "IMPORT"]: okM = false
  rec("L-B12", "non_controllate: tipo e nome uguali, motivo presente o null", okM and conMotivo, $nc)
  # trovata.stato_blocco e scopo.da_compilare
  let (s1i, s1e) = both(@["--dir", "prove/f3", "prove/f3/Uso.csc"])
  var okS = false
  for bl in s1e["blocchi"]:
    for ci in 0 ..< bl["citazioni"].len:
      let t = bl["citazioni"][ci]["trovata"]
      if t.kind != JObject: continue
      let ti = s1i["blocchi"][0]["citazioni"][ci]["trovata"]
      okS = t["stato_blocco"].getStr in ["senza_stato", "ipotesi", "contratto", "non_valido"] and t["stato_blocco"] == ti["stato_blocco"] and t["stato"] != ti["stato"] or
        (t["stato_blocco"].getStr in ["senza_stato", "ipotesi", "contratto", "non_valido"] and t["stato_blocco"] == ti["stato_blocco"] and t["stato"].getStr.len > 0)
  rec("L-B12", "trovata.stato_blocco: uno dei codici, uguale nelle due lingue", okS, $s1e["blocchi"])
  let (p1i, p1e) = both(@["prove/17_new_Esempio.csc"])
  rec("L-B12", "scopo.da_compilare vero sul file di new, uguale nelle due lingue", p1e["blocchi"][0]["scopo"]["da_compilare"].getBool and p1i["blocchi"][0]["scopo"]["da_compilare"].getBool, "")
  # ragioni di scarto (refine --json): chiavi stabili, argomenti uguali nelle due lingue
  let rf = f2Dir / "refine"
  let rs = rf / "risposte"
  var viste: seq[string]
  var mismatch: seq[string]
  for (resp, src) in [("scartate.json", "Luce.csc"), ("ragioni_testo.json", "Luce.csc"), ("interfaccia_scartate.json", "Ordine.csc"), ("sostituzioni.json", "Sostituzioni.csc"),
      ("livelli.json", "Sostituzioni.csc"), ("sostituisce_seconda.json", "Sostituzioni.csc"), ("buona_seconda.json", "Spia.csc"), ("interfaccia_da_zero.json", "Luce.csc"), ("sostituisce_seconda.json", "Spia.csc"), ("chiavi_rare.json", "Luce.csc")]:
    var js: seq[JsonNode]
    for lg in ["it", "en"]:
      let w = newRef(rf / src, src)
      discard auxOf(w)
      let env = refEnv(w, @[("BCDD_FINTO_RISPOSTA", rs / resp)])
      env["BCDD_LANG"] = lg
      let r = runX(bcddProva, @["refine", "--json", src], w, env)
      try: js.add parseJson(r.output)
      except CatchableError: js.add newJNull()
    if js[0].kind != JObject or js[1].kind != JObject: continue
    for sec in ["proposte", "sostituzioni", "interfaccia"]:
      if not js[0].hasKey(sec): continue
      for k in 0 ..< js[0][sec].len:
        let a = js[0][sec][k]
        let b = js[1][sec][k]
        if a["valida"].getBool:
          if a["ragione"].kind != JNull or a["ragione_chiave"].kind != JNull or a["ragione_argomenti"].len != 0: mismatch.add "valida con ragione: " & resp
          continue
        let kc = a["ragione_chiave"].getStr == "check_rifiuta_riga"     # il suo secondo argomento è il messaggio di check, nella lingua del comando
        let argEq = if kc: a["ragione_argomenti"][0] == b["ragione_argomenti"][0] and a["ragione_argomenti"].len == b["ragione_argomenti"].len
                    else: a["ragione_argomenti"] == b["ragione_argomenti"]
        if a["ragione_chiave"] != b["ragione_chiave"] or not argEq or a["ragione"] == b["ragione"]:
          mismatch.add resp & "/" & sec & "/" & $k & ": " & $a["ragione_chiave"] & " " & $b["ragione_chiave"]
        let key = a["ragione_chiave"].getStr
        if key notin viste: viste.add key
  # l'entità (bcdd-refine-4): tipo ASSUME, tipo non valido, dettaglia e sostituisce una riga che non c'è
  block:
    var js: seq[JsonNode]
    for lg in ["it", "en"]:
      let w = newWd()
      for n in ["Scale", "Pressione", "Luce"]: discard cpTo(f3bDir / "refine" / (n & ".csc"), w)
      discard auxOf(w)
      let env = refEnv(w, @[("BCDD_FINTO_RISPOSTA", f3bDir / "refine" / "risposte" / "ragioni_entita.json")])
      env["BCDD_LANG"] = lg
      let r = runX(bcddProva, @["refine", "--json", "Scale.csc", "--csc", "Scale"], w, env)
      try: js.add parseJson(r.output)
      except CatchableError: js.add newJNull()
    if js[0].kind == JObject and js[1].kind == JObject:
      for sec in ["proposte", "sostituzioni"]:
        for k in 0 ..< js[0][sec].len:
          let a = js[0][sec][k]
          let b = js[1][sec][k]
          if a["ragione_chiave"] != b["ragione_chiave"] or a["ragione_argomenti"] != b["ragione_argomenti"] or a["ragione"] == b["ragione"]:
            mismatch.add "entita/" & sec & "/" & $k
          let key = a["ragione_chiave"].getStr
          if key.len > 0 and key notin viste: viste.add key
    else: mismatch.add "entita: uscita non JSON"
  # 067:8:3 L-B20 (0.2): l'insieme delle chiavi di ragione prodotte dalla suite è esattamente l'elenco delle 33 chiavi del catalogo
  block:
    const elenco = ["testo_vuoto", "testo_con_virgolette", "testo_su_piu_righe", "testo_troppo_lungo", "verifica_non_valida", "verifica_testo_vuoto", "verifica_testo_con_virgolette", "verifica_testo_su_piu_righe", "verifica_testo_troppo_lungo", "id_non_valido", "sostituisce_non_garanzia_entita", "sostituisce_non_garanzia_csc", "sostituisce_contratto", "sostituisce_non_verbale", "id_gia_sostituito", "riga_composta_non_riconosciuta", "riga_uguale_a_quella_di_adesso", "check_rifiuta_riga", "riga_vuota", "riga_su_piu_righe", "dichiarazione_non_ammessa", "riga_non_riconosciuta", "nome_gia_usato_interfaccia", "tipo_non_dichiarato", "tipo_assume_in_entita", "tipo_non_valido_entita", "tipo_non_valido", "dettaglia_non_garanzia_entita", "dettaglia_non_garanzia_csc", "dettaglia_troppo_in_basso", "id_gia_usato_alla_riga", "id_gia_usato_interfaccia", "id_gia_usato_proposta"]
    # `riga_composta_non_riconosciuta` è l'unica che nessuna risposta provata riesce a produrre (difesa in filterProposal e nelle sostituzioni):
    # scostamento già noto; qui è l'unica esclusione ammessa.
    const nonRaggiunte = ["riga_composta_non_riconosciuta"]
    var inPiu, mancanti: seq[string]
    for k in viste:
      if k notin elenco: inPiu.add k
    for k in elenco:
      if k notin viste and k notin nonRaggiunte: mancanti.add k
    rec("L-B20", "chiavi di ragione prodotte = elenco chiuso di 33 (meno 1 non raggiungibile, dichiarata)", elenco.len == 33 and inPiu.len == 0 and mancanti.len == 0,
      "in più: " & inPiu.join(",") & "; mai prodotte: " & mancanti.join(","))
  rec("L-B12", "ragioni di scarto: chiave e argomenti uguali in it ed en, il testo cambia", mismatch.len == 0 and viste.len >= 28, "chiavi viste " & $viste.len & ": " & viste.join(",") & "\n" & mismatch.join("\n"))

# 067:9:1 L-B13, L-B15: nessun testo fuori dal catalogo, nessun confronto sul testo dei messaggi
block:
  proc literals(src: string): seq[(int, string)] =
    ## le stringhe di un sorgente Nim (commenti esclusi): numero di riga e contenuto
    var i = 0
    var line = 1
    let n = src.len
    while i < n:
      let c = src[i]
      if c == '\n': inc line; inc i
      elif c == '#':
        while i < n and src[i] != '\n': inc i
      elif c == '"' and src.continuesWith("\"\"\"", i):
        let j = src.find("\"\"\"", i + 3)
        result.add (line, src[i + 3 ..< j])
        for q in i ..< j + 3:
          if src[q] == '\n': inc line
        i = j + 3
      elif c == '"':
        var j = i + 1
        var s = ""
        while j < n and src[j] != '"':
          if src[j] == '\\' and j + 1 < n:
            s.add src[j .. j + 1]
            j += 2
          else:
            s.add src[j]
            inc j
        result.add (line, s)
        i = j + 1
      elif c == '\'' and i + 2 < n and (src[i + 2] == '\'' or (src[i + 1] == '\\' and i + 3 < n and src[i + 3] == '\'')):
        i += (if src[i + 1] == '\\': 4 else: 3)
      else: inc i
  proc isJsonFragment(v: string): bool =
    ## chiavi e pezzi di JSON: non si traducono
    if v.len == 0: return true
    if v[0] in {'{', ',', '"', ']', '\\'}: return true
    for ch in v:
      if ch notin {'a' .. 'z', '_'}: return false
    true
  var leaks: seq[string]
  var nFiles = 0
  for f in walkFiles(root / "src" / "*.nim"):
    let nm = f.extractFilename
    if nm in ["bcddtesti.nim", "bcddwords.nim"]: continue
    inc nFiles
    for (ln, v) in literals(readFile(f)):
      if isJsonFragment(v): continue
      var hit = false
      for ch in v:
        if ord(ch) >= 128: hit = true
      for w in wordsOf(v):
        if w in spiaWords: hit = true
      # eccezioni esplicite: il prefisso riconosciuto dello scopo da compilare (C-2, due lingue) e le parole «con» e «senza» delle composizioni
      if v in ["\"da scrivere", "\"da compilare", "\"to be filled in"]: continue
      # ... e i segni tipografici «↵» (a capo) e «…» (testo accorciato), che non sono parole di una lingua
      if v in ["\xE2\x86\xB5", "\xE2\x80\xA6"]: continue
      if hit: leaks.add nm & ":" & $ln & " " & v
  rec("L-B13", "nessun letterale con parole spia o lettere accentate fuori dal catalogo (" & $nFiles & " sorgenti)", leaks.len == 0, leaks.join("\n"))
  var cmpMsg: seq[string]
  for f in walkFiles(root / "src" / "*.nim"):
    let nm = f.extractFilename
    if nm == "bcddtesti.nim": continue
    var ln = 0
    for l in readFile(f).splitLines():
      inc ln
      let t = l.strip
      if t.startsWith("#") or t.startsWith("proc errKey"): continue
      if ".msg" in t and (".startsWith" in t or ".endsWith" in t or ".contains" in t or ".find(" in t or " in e.msg" in t or "msg ==" in t):
        cmpMsg.add nm & ":" & $ln & " " & t
  rec("L-B15", "nessun confronto sul testo dei messaggi (C-1 rimosso; errKey ammesso)", cmpMsg.len == 0, cmpMsg.join("\n"))

# 067:10:1 L-B19 (0.2): la riga d'uso di `save` in due lingue, quattro righe, `nuovo` invariato
block:
  for lg in ["it", "en"]:
    let r = runL(@["save"], lg)
    let righe = r.errout.strip(chars = {'\n'}).splitLines()
    let pref = if lg == "it": "uso: " else: "usage: "
    let attesaFp = if lg == "it": "IMPRONTA" else: "FINGERPRINT"
    rec("L-B19", "riga d'uso di save in " & lg & ": quattro righe, " & attesaFp & ", nuovo invariato, codice 2",
      r.code == 2 and r.output.len == 0 and righe.len == 4 and righe[0].startsWith(pref & "bcdd save FILE --expect " & attesaFp & "|nuovo") and
      righe[3].contains("--expect nuovo") and (lg == "en" or "FINGERPRINT" notin r.errout) and (lg == "it" or "IMPRONTA" notin r.errout), r.errout)

# 067:10:2 `bcdd new` rifiuta su ogni sistema i nomi di dispositivo di Windows, in ogni combinazione di maiuscole
block:
  var bad: seq[string]
  for nome in ["CON", "con", "Prn", "AUX", "nUl", "COM1", "com9", "LPT1", "lpt9"]:
    for lg in ["it", "en"]:
      let w = newWd()
      let r = runX(bcdd, @["--lang", lg, "new", nome], w, envLang(""))
      let atteso = if lg == "it": "bcdd new: il nome «" & nome & "» non si può usare: Windows lo riserva per sé" else: "bcdd new: the name “" & nome & "” cannot be used: Windows reserves it"
      if r.code != 2 or r.output.len > 0 or not r.errout.startsWith(atteso) or fileExists(w / (nome & ".csc")): bad.add nome & "/" & lg & ": " & $r.code & " " & r.errout
  rec("D-398", "new rifiuta CON, PRN, AUX, NUL, COM1-9, LPT1-9 (codice 2, niente scritto) in it ed en", bad.len == 0, bad.join("\n"))
  var ok: seq[string]
  for nome in ["Con1", "COM0", "COM10", "LPT", "Console", "Luce"]:
    let w = newWd()
    let r = runX(bcdd, @["new", nome], w, envLang(""))
    if r.code != 0 or not fileExists(w / (nome & ".csc")): ok.add nome & ": " & $r.code & " " & r.errout
  rec("D-398", "new accetta i nomi vicini (Con1, COM0, COM10, LPT, Console, Luce)", ok.len == 0, ok.join("\n"))

# 067:10:3 un .csc con CR LF, anche senza LF finale e con BOM, dà lo stesso rapporto del file con LF e nessun CR in uscita
block:
  let w = newWd()
  let lf = readFile(root / "prove" / "01_minima.csc")
  var crlf = ""
  for l in lf.splitLines(): crlf.add l & "\r\n"
  writeFile(w / "Lf.csc", lf)
  writeFile(w / "Crlf.csc", crlf)
  writeFile(w / "SenzaFine.csc", crlf[0 ..< crlf.len - 2])
  writeFile(w / "Bom.csc", "\xEF\xBB\xBF" & crlf)
  var bad: seq[string]
  let base = runX(bcdd, @["--lang", "en", "check", "Lf.csc"], w, envLang(""))
  for nome in ["Crlf.csc", "SenzaFine.csc", "Bom.csc"]:
    for modo in [@["check"], @["check", "--json"]]:
      let r = runX(bcdd, @["--lang", "en"] & modo & @[nome], w, envLang(""))
      if r.code != 0 or '\r' in r.output or '\r' in r.errout: bad.add nome & " " & modo.join(" ") & ": codice " & $r.code & " o CR in uscita"
      elif modo.len == 1 and "outcome: no errors" notin r.output: bad.add nome & ": " & r.output
  rec("W-R1", "CR LF, senza LF finale, con BOM: check senza errori e senza CR in uscita", base.code == 0 and bad.len == 0, bad.join("\n"))

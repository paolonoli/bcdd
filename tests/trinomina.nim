# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 140:1:1 Suite di accettazione di `bcdd rename` e del rifiuto delle scritture con un giornale presente: AC-423..AC-442, AC-452..AC-459 e AC-460..AC-472
# 140:1:2. Modalità Unattended. Prove su copie temporanee di prove/rinomina/sintetica e di
# 140:1:3 prove/rinomina/licenze (copia congelata di un gruppo di CSC di prova, 2026-11-27): mai i file vivi.
# 140:1:4 Lancia il binario `bcdd` di rilascio (env BCDD, oppure ../bcdd) e, per le prove di interruzione e per `refine`, l'eseguibile di
# 140:1:5 prova tests/bcdd_prova (env BCDD_PROVA): `refine` non gira mai con il binario di rilascio, che chiamerebbe l'LLM vero.
# 140:1:6 Stampa una riga per criterio, i dettagli solo per i FAIL, e la riga `controlli:`; esce con 1 se qualcosa fallisce.
import std/[os, osproc, streams, strutils, tables, times, algorithm, sets, strtabs, sequtils, json, posix]
import checksums/sha2

putEnv("BCDD_LANG", "it")

type Res = tuple[output, errout: string, code: int]

let
  root = currentSourcePath().parentDir.parentDir
  bcdd = getEnv("BCDD", root / "bcdd")
  bcddProva = getEnv("BCDD_PROVA", root / "tests" / "bcdd_prova")
  prDir = root / "prove" / "rinomina"
  sinteticaSrc = prDir / "sintetica"
  licenzeSrc = prDir / "licenze"
  f2Dir = root / "prove" / "f2"
  tmpBase = getTempDir() / ("trinomina_" & $getCurrentProcessId())
  t0 = epochTime()

var
  acOrder: seq[string]
  acPass, acTotal: Table[string, int]
  details: Table[string, seq[string]]

proc rec(ac, label: string, ok: bool, why: string = "") =
  if ac notin acTotal:
    acOrder.add ac
    acTotal[ac] = 0
    acPass[ac] = 0
    details[ac] = @[]
  inc acTotal[ac]
  if ok: inc acPass[ac]
  else: details[ac].add label & ": " & why

proc mkEnv(extra: seq[(string, string)] = @[]): StringTableRef =
  result = newStringTable(modeCaseSensitive)
  for k, v in envPairs():
    if not k.startsWith("BCDD_"): result[k] = v
  result["BCDD_LANG"] = "it"
  for (k, v) in extra: result[k] = v

proc runX(exe: string, args: seq[string], cwd: string, env: StringTableRef = nil, input: string = ""): Res =
  let p = startProcess(exe, workingDir = cwd, args = args, env = (if env == nil: mkEnv() else: env), options = {})
  if input.len > 0:
    p.inputStream.write input
    p.inputStream.flush()
  p.inputStream.close()
  result.output = p.outputStream.readAll()
  result.errout = p.errorStream.readAll()
  result.code = p.waitForExit()
  p.close()

var wdCount = 0
proc fresh(src: string = sinteticaSrc): string =
  ## 141:1:1 Una copia nuova della cartella di prova.
  inc wdCount
  result = tmpBase / ("w" & $wdCount)
  createDir(tmpBase)
  copyDir(src, result)

proc fpOf(s: string): string = "sha256:" & $secureHash(Sha_256, s)

proc snapshot(w: string): Table[string, string] =
  ## 141:1:2 Ogni voce sotto `w` con il suo contenuto e la data di modifica: serve a dire «niente è cambiato, nemmeno nelle date».
  for p in walkDirRec(w, yieldFilter = {pcFile, pcDir, pcLinkToFile, pcLinkToDir}, relative = true):
    let full = w / p
    let t = getLastModificationTime(full)
    let key = $t.toUnix & "." & $t.nanosecond
    if dirExists(full) and not symlinkExists(full): result[p] = "dir " & key
    else:
      var c = ""
      try: c = readFile(full)
      except IOError, OSError: c = "?"
      result[p] = fpOf(c) & " " & key

proc contents(w: string): Table[string, string] =
  ## 141:1:3 Come `snapshot`, senza le date: per confrontare un ripristino (le date cambiano riscrivendo).
  for p, v in snapshot(w): result[p] = v.split(' ')[0]

proc listAll(dir: string): seq[string] =
  for k, p in walkDir(dir, relative = true): result.add p
  result.sort()

proc hasWork(w: string): seq[string] =
  ## 141:1:4 File di lavoro o giornali rimasti in una cartella (e nelle sue sottocartelle).
  for p in walkDirRec(w, yieldFilter = {pcFile, pcDir}, relative = true):
    let n = p.extractFilename
    if n == ".bcdd-rinomina" or ".rinomina-" in n: result.add p

proc imp(r: Res): string =
  if r.output.startsWith("{"):
    try: return parseJson(r.output)["impronta"].getStr()
    except CatchableError: return ""
  for l in r.output.splitLines():
    if l.startsWith("impronta: "): return l["impronta: ".len .. ^1]

const
  FILE = "luce/Luce.csc"

proc rn(w: string, args: seq[string], exe: string = bcdd, env: StringTableRef = nil): Res =
  runX(exe, @["rename"] & args, w, env)

proc prev(w: string, kindArgs: seq[string], file: string = FILE, extra: seq[string] = @["--dir", "comuni"], exe: string = bcdd,
    env: StringTableRef = nil): Res =
  rn(w, @[file] & extra & @["--dry-run"] & kindArgs, exe, env)

proc doWrite(w: string, kindArgs: seq[string], file: string = FILE, extra: seq[string] = @["--dir", "comuni"], text: seq[string] = @[],
    exe: string = bcdd, env: StringTableRef = nil): Res =
  let p = prev(w, kindArgs, file, extra, exe, env)
  if p.code != 0: return p
  rn(w, @[file] & extra & @["--expect", imp(p)] & text & kindArgs, exe, env)

proc lines(s: string): seq[string] = s.splitLines()

proc changedLines(a, b: string): seq[int] =
  let la = a.splitLines()
  let lb = b.splitLines()
  for i in 0 ..< max(la.len, lb.len):
    if i >= la.len or i >= lb.len or la[i] != lb[i]: result.add i + 1

proc rd(w, rel: string): string = readFile(w / rel)

proc jsonOf(r: Res): JsonNode =
  try: parseJson(r.output) except CatchableError: nil

proc motivoOf(r: Res): string =
  let j = jsonOf(r)
  if j == nil or j["motivo"].kind == JNull: "" else: j["motivo"].getStr()

# ---------------------------------------------------------------- AC-423, AC-424

const usoRename = "uso: bcdd rename FILE [--csc NOME] [--dir CARTELLA]... (--dry-run | --expect IMPRONTA [--text default|none|all | --text-at tN...]) [--json] csc|entity|part|id VECCHIO NUOVO\n" &
  "     bcdd rename --recover CARTELLA [--json]\n"

block:
  let w = fresh()
  let before = snapshot(w)
  let r = prev(w, @["csc", "Luce", "Lampadina"])
  let atteso = readFile(prDir / "423_anteprima.atteso")
  var got = r.output
  let ip = imp(r)
  got = got.replace(ip, "sha256:…")
  rec("AC-423", "anteprima di §7.3 (con la riga 4 di Lampada.csc, che la fixture di §10.1 contiene)", got == atteso and r.code == 0 and r.errout.len == 0,
    "codice " & $r.code & " " & r.errout & "\n--- ottenuto\n" & got)
  rec("AC-423", "nessun file cambiato né creato, nemmeno nella data di modifica", snapshot(w) == before, "elenco o date diversi")
  rec("AC-423", "l'impronta ha la forma sha256:<64 esadecimali>", ip.startsWith("sha256:") and ip.len == 71, ip)
  let r2 = prev(w, @["csc", "Luce", "Lampadina"])
  rec("AC-423", "la stessa anteprima dà la stessa impronta", imp(r2) == ip, imp(r2))

proc projCheck(w: string, path: string, dirs: seq[string]): string =
  ## 141:2:1 La proiezione di `check --strict --json` che A5 vuole uguale: codice, errori (codice, riga), righe non riconosciute, citazioni.
  var args = @["check", "--strict", "--json"]
  for d in dirs: args.add @["--dir", d]
  args.add path
  let r = runX(bcdd, args, w)
  let j = parseJson(r.output)
  var parts: seq[string] = @["codice " & $r.code]
  var errs: seq[string]
  for e in j["rapporto"]["errori"]: errs.add e["codice"].getStr() & "@" & $e["riga"].getInt()
  errs.sort()
  parts.add "errori " & errs.join(",")
  var unrec: seq[string]
  for rg in j["righe"]:
    if rg["tipo"].getStr() == "non_riconosciuta": unrec.add $rg["n"].getInt()
  parts.add "non riconosciute " & unrec.join(",")
  for b in j["blocchi"]:
    if b.hasKey("citazioni"):
      for c in b["citazioni"]:
        let tr = c["trovata"]
        parts.add c["tipo"].getStr() & "@" & $c["riga"].getInt() & ":" & (if tr.kind == JObject and tr.hasKey("versione"): tr["versione"].getStr() else: "no") &
          " attesa " & (if c["versione_citata"].kind == JString: c["versione_citata"].getStr() else: "")
  parts.join("; ")

block:
  let w = fresh()
  let dirs = @["luce", "comuni"]
  var names: seq[string]
  for d in dirs:
    for f in listAll(w / d):
      if f.endsWith(".csc"): names.add d / f
  var before: Table[string, string]
  for n in names: before[n] = projCheck(w, n, dirs)
  let r = doWrite(w, @["csc", "Luce", "Lampadina"])
  rec("AC-424", "scritto: codice 0", r.code == 0, "codice " & $r.code & " " & r.errout)
  rec("AC-424", "uscita di §7.3 (con Lampada.csc): nomi cambiati: 7 righe in 5 file; testi cambiati: 5; rimasti 1 (t5)",
    r.output == readFile(prDir / "424_scritto.atteso"), r.output)
  rec("AC-424", "Luce.csc assente, Lampadina.csc presente", not fileExists(w / "luce/Luce.csc") and fileExists(w / "luce/Lampadina.csc"), $listAll(w / "luce"))
  rec("AC-424", "nessun giornale né file di lavoro rimasto", hasWork(w).len == 0, $hasWork(w))
  let orig = sinteticaSrc
  var okRows = true
  var why = ""
  for (f, want) in [("luce/Luce.csc", @[2, 14, 1, 4, 6]), ("luce/LuceProva.csc", @[1, 4]), ("luce/LuceScale.csc", @[4, 12]),
      ("comuni/Corridoio.csc", @[4, 1]), ("luce/Lampada.csc", @[4])]:
    let nf = if f == "luce/Luce.csc": "luce/Lampadina.csc" else: f
    let c = changedLines(readFile(orig / f), readFile(w / nf))
    if c.sorted != want.sorted:
      okRows = false
      why.add f & ": " & $c & " invece di " & $want & "; "
  rec("AC-424", "righe cambiate per file (nomi: 2, 14; testi t1-t4, t6; t5 invariato)", okRows, why)
  rec("AC-424", "t5 invariato: la riga 8 di LuceScale.csc ha ancora Luce", "Una pressione a Luce spenta" in readFile(w / "luce/LuceScale.csc"), "")
  var same = true
  var why2 = ""
  for n in names:
    let nn = if n == "luce/Luce.csc": "luce/Lampadina.csc" else: n
    let after = projCheck(w, nn, dirs)
    if after != before[n]:
      same = false
      why2.add n & ": [" & before[n] & "] [" & after & "]; "
  rec("AC-424", "check --strict --json su ogni file, prima e dopo: stessa proiezione (A5)", same, why2)

# ---------------------------------------------------------------- AC-425..AC-428

block:
  let w = fresh()
  let before = snapshot(w)
  let r = prev(w, @["csc", "Comando", "X"], "luce/Comando.csc")
  let want = "bcdd rename: Comando non si rinomina: compare in 1 riga approvata:\n" &
    "  luce/Comando.csc, riga 1: CSC Comando VERSION 0.1 (intestazione approvata, D-5)\n" &
    "Un nome approvato cambia solo con una versione nuova: rimetti da approvare le righe elencate (Nuova versione), rinomina, poi approva con una decisione nuova.\n"
  rec("AC-425", "csc Comando X: codice 1 con il messaggio di §3", r.code == 1 and r.output.len == 0 and r.errout == want, "codice " & $r.code & " [" & r.errout & "]")
  let rj = rn(w, @["luce/Comando.csc", "--dir", "comuni", "--dry-run", "--json", "csc", "Comando", "X"])
  let j = jsonOf(rj)
  rec("AC-425", "con --json: motivo approvato e bloccanti con la riga 1 e D-5", j != nil and j["motivo"].getStr() == "approvato" and
    j["bloccanti"].len == 1 and j["bloccanti"][0]["riga"].getInt() == 1 and j["bloccanti"][0]["decisione"].getStr() == "D-5", rj.output)
  rec("AC-425", "file invariati", snapshot(w) == before, "")

block:
  let w = fresh()
  writeFile(w / "luce/Comando.csc", rd(w, "luce/Comando.csc").replace("RATIFIED BY D-5", "HYPOTHESIS"))
  let r = doWrite(w, @["csc", "Comando", "Interruttore"], "luce/Comando.csc")
  rec("AC-426", "Comando.csc portato a HYPOTHESIS: la rinomina riesce", r.code == 0, "codice " & $r.code & " " & r.errout)
  rec("AC-426", "Comando.csc è diventato Interruttore.csc", not fileExists(w / "luce/Comando.csc") and fileExists(w / "luce/Interruttore.csc"), $listAll(w / "luce"))
  rec("AC-426", "righe USES e OFFERS di Lampada.csc e Pulsante.csc",
    "  USES   Interruttore\n" in rd(w, "luce/Lampada.csc") and "  OFFERS Interruttore\n" in rd(w, "luce/Pulsante.csc") and
    "CSC Interruttore VERSION 0.1" in rd(w, "luce/Interruttore.csc"), "")

block:
  let w = fresh()
  writeFile(w / "luce/Luce.csc", rd(w, "luce/Luce.csc").replace("GUARANTEE la1a DETAILS la1:", "GUARANTEE la1a DETAILS la1 STATUS RATIFIED BY D-7:"))
  let before = snapshot(w)
  let r1 = prev(w, @["id", "la1", "lb1"])
  rec("AC-427", "id la1 lb1: codice 1, approvato, riga 8 di Luce.csc", r1.code == 1 and "luce/Luce.csc, riga 8:" in r1.errout and "(riga approvata, D-7)" in r1.errout,
    r1.errout)
  let r2 = prev(w, @["id", "la1a", "lb1a"])
  rec("AC-427", "id la1a lb1a: codice 1 (riga approvata)", r2.code == 1 and "riga approvata" in r2.errout, r2.errout)
  rec("AC-427", "file invariati", snapshot(w) == before, "")

block:
  let w = fresh()
  let r = doWrite(w, @["id", "la1", "la-base"])
  rec("AC-428", "id la1 la-base: scritto", r.code == 0, r.errout)
  rec("AC-428", "righe 6 e 8 di Luce.csc", changedLines(readFile(sinteticaSrc / "luce/Luce.csc"), rd(w, "luce/Luce.csc")) == @[6, 8] and
    "GUARANTEE la-base:" in rd(w, "luce/Luce.csc") and "DETAILS la-base:" in rd(w, "luce/Luce.csc"), "")
  let w2 = fresh()
  let r2 = doWrite(w2, @["id", "s1", "s-spenta"])
  rec("AC-428", "id s1 s-spenta: scritto", r2.code == 0, r2.errout)
  rec("AC-428", "riga 10 di Luce.csc e riga 3 di LuceProva.csc", changedLines(readFile(sinteticaSrc / "luce/Luce.csc"), rd(w2, "luce/Luce.csc")) == @[10] and
    changedLines(readFile(sinteticaSrc / "luce/LuceProva.csc"), rd(w2, "luce/LuceProva.csc")) == @[3] and "TRANSLATES s-spenta" in rd(w2, "luce/LuceProva.csc") and
    "SCENARIO s1-occhio" in rd(w2, "luce/LuceProva.csc"), "")
  let w3 = fresh()
  writeFile(w3 / "luce/LuceProva.csc", rd(w3, "luce/LuceProva.csc").replace("VERSION 0.1", "VERSION 0.2"))
  let r3 = doWrite(w3, @["id", "s1", "s-spenta"])
  rec("AC-428", "con la VERIFICATION a VERSION 0.2 la riga 3 non cambia", r3.code == 0 and "TRANSLATES s1\n" in rd(w3, "luce/LuceProva.csc"), r3.errout)

# ---------------------------------------------------------------- AC-429, AC-430

block:
  let w = fresh()
  let r = doWrite(w, @["part", "lampada", "plafoniera", "--csc", "LuceScale"], "luce/LuceScale.csc")
  rec("AC-429", "part lampada plafoniera --csc LuceScale: scritto (ls1 approvata: B4)", r.code == 0, r.errout)
  rec("AC-429", "solo la riga 7 di LuceScale.csc, con gli spazi d'allineamento di prima",
    changedLines(readFile(sinteticaSrc / "luce/LuceScale.csc"), rd(w, "luce/LuceScale.csc")) == @[7] and
    "    plafoniera  : Lampada\n" in rd(w, "luce/LuceScale.csc") and rd(w, "comuni/Corridoio.csc") == readFile(sinteticaSrc / "comuni/Corridoio.csc"), "")
  let w2 = fresh()
  let r2 = doWrite(w2, @["part", "lampada", "plafoniera"], "luce/LuceScale.csc")
  rec("AC-429", "senza --csc (il file ha un solo blocco): lo stesso esito", r2.code == 0 and "    plafoniera  : Lampada\n" in rd(w2, "luce/LuceScale.csc"), r2.errout)

block:
  let w = fresh()
  let dlg = "-- bcdd refine: domande dell'LLM e risposte della persona.\n\nGIRO 2026-10-17T12:17:35+02:00 ENTITY Lampada\nDOMANDA Per g2: quanto?\nRISPOSTA la Lampada resta\n\n" &
    "GIRO 2026-10-18T09:00:00+02:00 ENTITY Lampada\nDOMANDA altra?\nRISPOSTA no\n"
  writeFile(w / "luce/Lampada.csc.dialogo", dlg)
  writeFile(w / "luce/Lampada.csc.prima", "sha256:00\nvecchio\n")
  let r = doWrite(w, @["entity", "Lampada", "Plafoniera"], "luce/Lampada.csc")
  rec("AC-430", "entity Lampada Plafoniera: scritto", r.code == 0, r.errout)
  rec("AC-430", "riga 1 di Lampada.csc, riga 7 di LuceScale.csc, riga 6 di Corridoio.csc",
    "ENTITY Plafoniera VERSION 0.1" in rd(w, "luce/Plafoniera.csc") and changedLines(readFile(sinteticaSrc / "luce/LuceScale.csc"), rd(w, "luce/LuceScale.csc")) == @[7] and
    "    lampada  : Plafoniera\n" in rd(w, "luce/LuceScale.csc") and changedLines(readFile(sinteticaSrc / "comuni/Corridoio.csc"), rd(w, "comuni/Corridoio.csc")) == @[6], "")
  rec("AC-430", "Plafoniera.csc.dialogo: righe GIRO con ENTITY Plafoniera, il resto identico",
    rd(w, "luce/Plafoniera.csc.dialogo") == dlg.replace("ENTITY Lampada", "ENTITY Plafoniera") and not fileExists(w / "luce/Lampada.csc.dialogo") and
    not fileExists(w / "luce/Lampada.csc"), $listAll(w / "luce"))
  rec("AC-430", "Lampada.csc.prima intatto", fileExists(w / "luce/Lampada.csc.prima") and rd(w, "luce/Lampada.csc.prima") == "sha256:00\nvecchio\n", "")

# ---------------------------------------------------------------- AC-431, AC-432

block:
  let w = fresh()
  let before = snapshot(w)
  proc motivo(args: seq[string], file: string = FILE): (int, string) =
    let r = rn(w, @[file, "--dir", "comuni", "--dry-run", "--json"] & args)
    (r.code, motivoOf(r))
  rec("AC-431", "csc Luce Pressione: collisione", motivo(@["csc", "Luce", "Pressione"]) == (1, "collisione"), $motivo(@["csc", "Luce", "Pressione"]))
  rec("AC-431", "csc Luce Lampada: collisione", motivo(@["csc", "Luce", "Lampada"]) == (1, "collisione"), $motivo(@["csc", "Luce", "Lampada"]))
  rec("AC-431", "csc Luce Luce: uguale", motivo(@["csc", "Luce", "Luce"]) == (1, "uguale"), $motivo(@["csc", "Luce", "Luce"]))
  rec("AC-431", "part lampada ls1: collisione", motivo(@["part", "lampada", "ls1"], "luce/LuceScale.csc") == (1, "collisione"),
    $motivo(@["part", "lampada", "ls1"], "luce/LuceScale.csc"))
  rec("AC-431", "id la1 s1: collisione fra id", motivo(@["id", "la1", "s1"]) == (1, "collisione"), $motivo(@["id", "la1", "s1"]))
  let rc = rn(w, @[FILE, "--dir", "comuni", "--dry-run", "csc", "Luce", "Pressione"])
  rec("AC-431", "il messaggio di collisione dice il file e la riga", rc.errout == "bcdd rename: Pressione è già usato: luce/Pressione.csc, riga 1: CSC Pressione VERSION 0.1\n", rc.errout)
  rec("AC-431", "file invariati", snapshot(w) == before, "")
  let w2 = fresh()
  writeFile(w2 / "luce/Pulsante.csc", rd(w2, "luce/Pulsante.csc").replace("  OFFERS Comando\n", "  OFFERS Comando\n  USES Fantasma\n"))
  let r2 = rn(w2, @[FILE, "--dir", "comuni", "--dry-run", "--json", "csc", "Luce", "Fantasma"])
  rec("AC-431", "csc Luce Fantasma con USES Fantasma: cattura", r2.code == 1 and motivoOf(r2) == "cattura" and "luce/Pulsante.csc, riga 5" in jsonOf(r2)["messaggio"].getStr(), r2.output)
  let w3 = fresh()
  writeFile(w3 / "luce/lampadina.csc", "-- altro\n")
  let r3 = rn(w3, @[FILE, "--dir", "comuni", "--dry-run", "--json", "csc", "Luce", "Lampadina"])
  rec("AC-431", "file lampadina.csc in luce/: file_esiste, nome di Windows", r3.code == 1 and motivoOf(r3) == "file_esiste" and
    "esiste già lampadina.csc, che su Windows è lo stesso nome di Lampadina.csc" in r3.errout, r3.output & r3.errout)

block:
  let w = fresh()
  for nuovo in ["END", "Luce-2", "Com1", "Lpt9", "con"]:
    let r = prev(w, @["csc", "Luce", nuovo])
    rec("AC-432", "csc Luce " & nuovo & ": codice 2", r.code == 2 and r.output.len == 0, "codice " & $r.code & " " & r.errout)
  let r = prev(w, @["id", "la1", "g-"])
  rec("AC-432", "id la1 g-: codice 2", r.code == 2, "codice " & $r.code)
  let r2 = prev(w, @["id", "la1", "g-n1"])
  rec("AC-432", "id la1 g-n1 è valido (L8)", r2.code == 0, r2.errout)
  let r3 = prev(w, @["entity", "Lampada", "Nul"], "luce/Lampada.csc")
  rec("AC-432", "entity Lampada Nul: codice 2 con il messaggio di new e il prefisso bcdd rename:", r3.code == 2 and r3.errout.startsWith("bcdd rename: il nome «Nul» non si può usare"), r3.errout)

# ---------------------------------------------------------------- AC-433, AC-434

block:
  let w = fresh()
  let p = prev(w, @["csc", "Luce", "Lampadina"])
  let ip = imp(p)
  writeFile(w / "luce/Pressione.csc", rd(w, "luce/Pressione.csc") & "-- una riga in più\n")
  let before = snapshot(w)
  let r = rn(w, @[FILE, "--dir", "comuni", "--expect", ip, "csc", "Luce", "Lampadina"])
  rec("AC-433", "un file cambiato dopo l'anteprima: cambiato, niente scritto", r.code == 1 and r.errout == "bcdd rename: i file sono cambiati dopo l'anteprima: niente scritto. Rifai l'anteprima\n" and
    snapshot(w) == before, r.errout)
  let w2 = fresh()
  let ip2 = imp(prev(w2, @["csc", "Luce", "Lampadina"]))
  writeFile(w2 / "comuni/Nuovo.csc", "-- nuovo\n")
  let r2 = rn(w2, @[FILE, "--dir", "comuni", "--expect", ip2, "csc", "Luce", "Lampadina"])
  rec("AC-433", "un file .csc aggiunto: cambiato", r2.code == 1 and motivoOf(rn(w2, @[FILE, "--dir", "comuni", "--expect", ip2, "--json", "csc", "Luce", "Lampadina"])) == "cambiato", r2.errout)
  let w3 = fresh()
  let ip3 = imp(prev(w3, @["csc", "Luce", "Lampadina"]))
  writeFile(w3 / "comuni/lampadina.csc.dialogo", "x")
  let r3 = rn(w3, @[FILE, "--dir", "comuni", "--expect", ip3, "csc", "Luce", "Lampadina"])
  rec("AC-433", "un nome di destinazione comparso: cambiato", r3.code == 1 and "sono cambiati" in r3.errout, r3.errout)

block:
  let orig = readFile(sinteticaSrc / "luce/Luce.csc")
  proc scrivi(args: seq[string], pre: proc(w: string) = nil): (Res, string) =
    let w = fresh()
    if pre != nil: pre(w)
    let r = doWrite(w, @["csc", "Luce", "Lampadina"], FILE, @["--dir", "comuni"], args)
    (r, w)
  let (r1, w1) = scrivi(@["--text", "none"])
  rec("AC-434", "--text none: nessun testo cambia", r1.code == 0 and "La Luce si accende" in rd(w1, "luce/Lampadina.csc") and "la Luce è accesa" in rd(w1, "luce/LuceProva.csc") and
    "testi cambiati: 0" in r1.output, r1.output & r1.errout)
  let (r2, w2) = scrivi(@["--text", "all"])
  rec("AC-434", "--text all: t1-t4 e t6, non t5", r2.code == 0 and "La Lampadina si accende" in rd(w2, "luce/Lampadina.csc") and "-- Lampadina: la plafoniera" in rd(w2, "luce/Lampadina.csc") and
    "la Lampadina è accesa" in rd(w2, "luce/LuceProva.csc") and "-- Il corridoio usa la stessa Lampadina" in rd(w2, "comuni/Corridoio.csc") and
    "a Luce spenta" in rd(w2, "luce/LuceScale.csc"), r2.output & r2.errout)
  let (r3, w3) = scrivi(@["--text-at", "t2", "--text-at", "t6"])
  rec("AC-434", "--text-at t2 --text-at t6: solo t2 e t6", r3.code == 0 and "La Lampadina si accende" in rd(w3, "luce/Lampadina.csc") and "-- Luce: la plafoniera" in rd(w3, "luce/Lampadina.csc") and
    "Una pressione accende la Luce" in rd(w3, "luce/Lampadina.csc") and "-- Il corridoio usa la stessa Lampadina" in rd(w3, "comuni/Corridoio.csc"), r3.output & r3.errout)
  let (r4, w4) = scrivi(@["--text-at", "t5"])
  rec("AC-434", "--text-at t5 (bloccata): codice 1 testo", r4.code == 1 and "t5 è in una riga approvata: resta con il nome vecchio" in r4.errout and rd(w4, "luce/Luce.csc") == orig, r4.errout)
  let (r5, w5) = scrivi(@["--text-at", "t9"])
  rec("AC-434", "--text-at t9 (inesistente): codice 1 testo", r5.code == 1 and "t9 non esiste nell'anteprima" in r5.errout and rd(w5, "luce/Luce.csc") == orig, r5.errout)
  let (r6, w6) = scrivi(@[], proc(w: string) =
    writeFile(w / "luce/Luce.csc", "-- [Luce]: doc.md#x\n-- vedi [Luce] e la Luce\n" & rd(w, "luce/Luce.csc")))
  rec("AC-434", "la definizione `-- [Luce]: doc.md#x` e il riferimento `[Luce]` non sono testi (T2); la parola sola sì",
    r6.code == 0 and "-- [Luce]: doc.md#x\n" in rd(w6, "luce/Lampadina.csc") and "-- vedi [Luce] e la Lampadina\n" in rd(w6, "luce/Lampadina.csc"), r6.output & r6.errout)
  let w7 = fresh()
  let p7 = prev(w7, @["part", "lampada", "plafoniera"], "luce/LuceScale.csc")
  rec("AC-434", "per un posto la preselezione è vuota (nessun testo [x])", p7.code == 0 and " [x] " notin p7.output, p7.output)
  let w8 = fresh()
  let p8 = prev(w8, @["csc", "Luce", "Lampadina"])
  rec("AC-434", "t5 è marcata [=] e numerata come le altre", "  t5 [=] luce/LuceScale.csc, riga 8, stringa:" in p8.output, p8.output)

# ---------------------------------------------------------------- AC-435, AC-436, AC-437

block:
  if not fileExists(bcddProva):
    rec("AC-435", "eseguibile di prova presente", false, bcddProva)
  else:
    let orig = contents(sinteticaSrc)
    proc env(k: string): StringTableRef = mkEnv(@[("BCDD_RINOMINA_PROVA_FERMA", k)])
    for k in ["1", "3", "4.5", "5"]:
      let w = fresh()
      let r = doWrite(w, @["csc", "Luce", "Lampadina"], FILE, @["--dir", "comuni"], @[], bcddProva, env(k))
      rec("AC-435", "k=" & k & ": la versione di prova esce con 99", r.code == 99, "codice " & $r.code & " " & r.errout)
      rec("AC-435", "k=" & k & ": giornali in luce/ e in comuni/", fileExists(w / "luce/.bcdd-rinomina") and fileExists(w / "comuni/.bcdd-rinomina"), $hasWork(w))
      let again = rn(w, @[FILE, "--dir", "comuni", "--dry-run", "--json", "csc", "Luce", "Altro"])
      rec("AC-435", "k=" & k & ": una rinomina nuova rifiuta (giornale)", (again.code == 1 and motivoOf(again) == "giornale" and "esegui bcdd rename --recover" in again.errout) or
        (k == "5" and again.code == 2), "codice " & $again.code & " " & again.errout)
      let rc = rn(w, @["--recover", "luce"])
      if k == "5":
        rec("AC-435", "k=tutte: --recover risponde «già scritta per intero» e i file restano nuovi", rc.code == 0 and "già scritta per intero" in rc.output and
          fileExists(w / "luce/Lampadina.csc") and not fileExists(w / "luce/Luce.csc") and hasWork(w).len == 0, rc.output & rc.errout & $hasWork(w))
      else:
        rec("AC-435", "k=" & k & ": --recover riporta i file ai byte di prima", rc.code == 0 and contents(w) == orig, rc.output & rc.errout & $hasWork(w))
        rec("AC-435", "k=" & k & ": nessun giornale né file di lavoro in nessuna cartella", hasWork(w).len == 0, $hasWork(w))

block:
  if fileExists(bcddProva):
    let w = fresh()
    let r = doWrite(w, @["csc", "Luce", "Lampadina"], FILE, @["--dir", "comuni"], @[], bcddProva, mkEnv(@[("BCDD_RINOMINA_PROVA_FERMA", "3")]))
    writeFile(w / "luce/LuceProva.csc", rd(w, "luce/LuceProva.csc") & "-- aggiunta a mano\n")
    let before = snapshot(w)
    let rc = rn(w, @["--recover", "luce"])
    rec("AC-436", "k=3 più una riga a mano a un file già sostituito: --recover rifiuta (estraneo)", r.code == 99 and rc.code == 1 and "non è né il testo di prima né quello nuovo: non tocco niente" in rc.errout and
      ".rinomina-vecchio." in rc.errout, rc.errout)
    rec("AC-436", "nulla toccato, giornali presenti", snapshot(w) == before and fileExists(w / "luce/.bcdd-rinomina") and fileExists(w / "comuni/.bcdd-rinomina"), "")

block:
  if getuid() != 0:
    let w = fresh()
    let ip = imp(prev(w, @["csc", "Luce", "Lampadina"]))
    let orig = contents(w)
    setFilePermissions(w / "comuni", {fpUserRead, fpUserExec, fpGroupRead, fpGroupExec, fpOthersRead, fpOthersExec})
    let r = rn(w, @[FILE, "--dir", "comuni", "--expect", ip, "--json", "csc", "Luce", "Lampadina"])
    setFilePermissions(w / "comuni", {fpUserRead, fpUserWrite, fpUserExec, fpGroupRead, fpGroupExec, fpOthersRead, fpOthersExec})
    rec("AC-437", "comuni/ senza permesso di scrittura: codice 1, scrittura, niente scritto", r.code == 1 and motivoOf(r) == "scrittura" and "niente scritto" in r.errout, r.output & r.errout)
    rec("AC-437", "i file di luce/ ai byte di prima, nessun file di lavoro", contents(w) == orig and hasWork(w).len == 0, $hasWork(w))
    if fileExists(bcddProva):
      let w2 = fresh()
      let r2 = doWrite(w2, @["csc", "Luce", "Lampadina"], FILE, @["--dir", "comuni"], @[], bcddProva, mkEnv(@[("BCDD_RINOMINA_PROVA_ERRORE", "3")]))
      rec("AC-437", "errore nel passo 6 (prova): i file già scritti tornano com'erano (R2)", r2.code == 1 and "i file già scritti sono tornati com'erano" in r2.errout and
        contents(w2) == contents(sinteticaSrc) and hasWork(w2).len == 0, r2.errout & $hasWork(w2))
  else:
    rec("AC-437", "prova non eseguibile come root", true)

# ---------------------------------------------------------------- AC-438, AC-439, AC-440

block:
  let w = fresh()
  moveFile(w / "luce/Luce.csc", w / "luce/Luce.orig")
  createSymlink("Luce.orig", w / "luce/Luce.csc")
  let r = prev(w, @["csc", "Luce", "Lampadina"])
  rec("AC-438", "Luce.csc collegamento simbolico: collegamento", r.code == 1 and "luce/Luce.csc è un collegamento simbolico: rename non lo sposta" in r.errout, r.errout)
  let w2 = fresh()
  createHardlink(w2 / "luce/Luce.csc", w2 / "luce/Luce.hard")
  let r2 = rn(w2, @[FILE, "--dir", "comuni", "--dry-run", "--json", "csc", "Luce", "Lampadina"])
  rec("AC-438", "Luce.csc con un secondo collegamento fisico: collegamento", r2.code == 1 and motivoOf(r2) == "collegamento" and "più collegamenti fisici" in r2.errout, r2.output & r2.errout)
  # un file soltanto da riscrivere, collegamento simbolico: si segue il collegamento
  let w3 = fresh()
  moveFile(w3 / "luce/LuceProva.csc", w3 / "luce/LuceProva.orig")
  createSymlink("LuceProva.orig", w3 / "luce/LuceProva.csc")
  let r3 = doWrite(w3, @["csc", "Luce", "Lampadina"])
  rec("AC-438", "un file solo da riscrivere che è un collegamento simbolico: si scrive il bersaglio e il collegamento resta",
    r3.code == 0 and symlinkExists(w3 / "luce/LuceProva.csc") and "VERIFICATION Lampadina" in rd(w3, "luce/LuceProva.orig"), r3.output & r3.errout)

block:
  let w = fresh()
  let r = rn(w, @[FILE, "--dir", "comuni", "--dry-run", "--json", "csc", "Luce", "Lampadina"])
  let j = jsonOf(r)
  var ok = j != nil
  var why = r.output
  if ok:
    for k in ["forma", "versione", "lingua", "esito", "motivo", "messaggio", "tipo", "vecchio", "nuovo", "blocco", "impronta", "file", "compagni", "testi", "bloccanti", "controllo"]:
      if not j.hasKey(k):
        ok = false
        why = "manca " & k
    ok = ok and j["forma"].getStr() == "bcdd-rename" and j["versione"].getInt() == 1 and j["esito"].getStr() == "anteprima" and j["lingua"].getStr() == "it" and
      j["controllo"]["file"].getInt() == 8 and j["controllo"]["invariato"].getBool() and j["testi"].len == 6 and j["file"][0].hasKey("modifiche")
  rec("AC-439", "--dry-run --json: oggetto con le chiavi di §7.5", ok and r.code == 0, why)
  let rEn = runX(bcdd, @["--lang", "en", "rename", FILE, "--dir", "comuni", "--dry-run", "--json", "csc", "Luce", "Lampadina"], w)
  let jEn = jsonOf(rEn)
  var same = jEn != nil and j != nil
  if same:
    for k in ["forma", "versione", "esito", "tipo", "vecchio", "nuovo", "impronta", "controllo"]:
      if $jEn[k] != $j[k]: same = false
    same = same and jEn["lingua"].getStr() == "en" and jEn["file"].len == j["file"].len and jEn["testi"].len == j["testi"].len and
      $jEn["file"] == $j["file"] and $jEn["testi"] == $j["testi"]
  rec("AC-439", "con --lang en cambiano solo la lingua e i testi per chi legge", same, rEn.output)
  let rw = doWrite(w, @["csc", "Luce", "Lampadina"], FILE, @["--dir", "comuni", "--json"])
  let jw = jsonOf(rw)
  rec("AC-439", "scrittura con --json: esito scritto", jw != nil and jw["esito"].getStr() == "scritto" and rw.code == 0, rw.output & rw.errout)

block:
  let w = fresh()
  let before = snapshot(w)
  let cases = @[
    @[FILE, "csc", "Luce", "X"],                                              # né --dry-run né --expect
    @[FILE, "--dry-run", "--expect", "sha256:0", "csc", "Luce", "X"],        # entrambe
    @[FILE, "--dry-run", "--text", "none", "csc", "Luce", "X"],              # --text con --dry-run
    @[FILE, "--expect", "sha256:0", "--text", "none", "--text-at", "t1", "csc", "Luce", "X"],
    @[FILE, "--dry-run", "--text-at", "t1", "csc", "Luce", "X"],
    @[FILE, "--dry-run", "--csc", "Luce", "csc", "Luce", "X"],
    @[FILE, "--dry-run", "--dir", "comuni", "--dir", "comuni", "csc", "Luce", "X"],
    @[FILE, "--dry-run", "prova", "Luce", "X"],
    @[FILE, "--dry-run", "csc", "Luce"],
    @[FILE, "--dry-run", "--json", "--json", "csc", "Luce", "X"],
    @[FILE, "--dry-run", "--csc", "A", "--csc", "B", "id", "la1", "X"],
    @[FILE, "--dry-run", "--text-at", "x1", "csc", "Luce", "X"],
    @["--recover"],
    @["--recover", "luce", "comuni"]]
  for c in cases:
    let r = rn(w, c)
    rec("AC-440", "errore d'uso: " & c.join(" "), r.code == 2 and r.output.len == 0 and r.errout == usoRename, "codice " & $r.code & " [" & r.errout & "]")
  let r0 = rn(w, @[])
  rec("AC-440", "senza argomenti: la riga d'uso", r0.code == 2 and r0.errout == usoRename, r0.errout)
  rec("AC-440", "nessun file cambiato", snapshot(w) == before, "")

# ---------------------------------------------------------------- AC-441 (GruppoLicenze, copia congelata)

block:
  let lic = licenzeSrc
  let w = fresh(lic)
  let before = snapshot(w)
  let r = rn(w, @["RegistroTelefono.csc", "--dry-run", "csc", "RegistroTelefono", "RegistroCustode"])
  # le righe che cambiano, dal testo
  let o = r.output
  rec("AC-441", "csc RegistroTelefono RegistroCustode: anteprima, file rinominato", r.code == 0 and "file rinominato: RegistroTelefono.csc -> RegistroCustode.csc" in o, o & r.errout)
  let expectedHeads = ["RegistroTelefono.csc\n", "ServizioLicenze.csc\n", "TelefonoCustode.csc\n"]
  var okHeads = true
  for h in expectedHeads:
    if h notin o: okHeads = false
  rec("AC-441", "toccati RegistroTelefono.csc, ServizioLicenze.csc, TelefonoCustode.csc", okHeads, o)
  rec("AC-441", "un commento di GruppoLicenze.csc scelto", "GruppoLicenze.csc, riga 7, commento" in o and " [x] GruppoLicenze.csc, riga 7" in o, o)
  rec("AC-441", "copia non toccata", snapshot(w) == before, "")
  let r2 = rn(w, @["TrasportoLicenza.csc", "--dry-run", "csc", "TrasportoLicenza", "X"])
  rec("AC-441", "csc TrasportoLicenza X: codice 1, riga 23, D-413", r2.code == 1 and "TrasportoLicenza.csc, riga 23:" in r2.errout and "D-413" in r2.errout, r2.errout)
  let r3 = rn(w, @["Portale.csc", "--dry-run", "entity", "Portale", "PortaleWeb"])
  rec("AC-441", "entity Portale PortaleWeb: righe 2 di Portale.csc e 24 di GruppoLicenze.csc, file rinominato",
    r3.code == 0 and "file rinominato: Portale.csc -> PortaleWeb.csc" in r3.output and "  riga 2: ENTITY Portale VERSION" in r3.output and "GruppoLicenze.csc\n  riga 24:" in r3.output, r3.output & r3.errout)
  let r4 = rn(w, @["GruppoLicenze.csc", "--dry-run", "--csc", "GruppoLicenze", "part", "portale", "portaleweb"])
  rec("AC-441", "part portale portaleweb: riga 24 di GruppoLicenze.csc, nessun testo scelto", r4.code == 0 and "GruppoLicenze.csc\n  riga 24:" in r4.output and " [x] " notin r4.output, r4.output & r4.errout)
  # scrittura vera sulla copia: e ritorno con la rinomina inversa
  let wr = fresh(lic)
  let origC = contents(wr)
  let rw = doWrite(wr, @["csc", "RegistroTelefono", "RegistroCustode"], "RegistroTelefono.csc", @[])
  rec("AC-441", "la rinomina sulla copia riesce e i controlli restano uguali", rw.code == 0 and fileExists(wr / "RegistroCustode.csc") and not fileExists(wr / "RegistroTelefono.csc"), rw.output & rw.errout)
  let rb = doWrite(wr, @["csc", "RegistroCustode", "RegistroTelefono"], "RegistroCustode.csc", @[], @["--text", "all"])
  rec("AC-441", "la rinomina inversa riporta i file di prima (prova dell'operatore)", rb.code == 0 and contents(wr) == origC, rb.output & rb.errout & $(toSeq(contents(wr).pairs).filterIt(it[0] notin origC or origC[it[0]] != it[1]).mapIt(it[0])))

# ---------------------------------------------------------------- AC-442 e bordi (CRLF, BOM, senza LF finale)

block:
  let w = fresh()
  writeFile(w / "luce/Luce.csc.dialogo", "-- d\n\nGIRO 2026-10-17T12:17:35+02:00 CSC Luce\nDOMANDA x\n")
  let r = doWrite(w, @["csc", "Luce", "LUCE"])
  rec("AC-442", "csc Luce LUCE: scritta (Linux)", r.code == 0, r.output & r.errout)
  let names = listAll(w / "luce")
  rec("AC-442", "il nome sul disco è esattamente LUCE.csc (e LUCE.csc.dialogo)", "LUCE.csc" in names and "Luce.csc" notin names and "LUCE.csc.dialogo" in names and "Luce.csc.dialogo" notin names, $names)
  rec("AC-442", "CSC LUCE VERSION 0.1 nel file e nessun file di lavoro", "CSC LUCE VERSION 0.1" in rd(w, "luce/LUCE.csc") and hasWork(w).len == 0, $hasWork(w))
  rec("AC-442", "Windows (NTFS): non esercitato da questa suite; il codice usa MoveFileEx e toglie la partenza prima di creare l'arrivo (bcddrenwrite 131:5:2)", true)

block:
  let w = fresh()
  let orig = readFile(sinteticaSrc / "luce/LuceScale.csc")
  var crlf = "\xEF\xBB\xBF" & orig.replace("\n", "\r\n")
  crlf = crlf[0 ..< crlf.len - 2]            # senza CR LF finale
  writeFile(w / "luce/LuceScale.csc", crlf)
  let r = doWrite(w, @["part", "lampada", "plafoniera"], "luce/LuceScale.csc")
  let want = crlf.replace("    lampada  : Lampada", "    plafoniera  : Lampada")
  rec("X", "BOM, CR LF e nessun fine riga finale: cambiano solo i byte del nome", r.code == 0 and rd(w, "luce/LuceScale.csc") == want, r.output & r.errout)
  let w2 = fresh()
  writeFile(w2 / "luce/LuceScale.csc", crlf)
  let r2 = doWrite(w2, @["csc", "Luce", "Lampadina"])
  let want2 = crlf.replace("  OFFERS Luce\r\n", "  OFFERS Lampadina\r\n").replace("@1 s   Luce.accesa", "@1 s   Lampadina.accesa").replace("Una pressione a Luce spenta", "Una pressione a Luce spenta")
  rec("X", "csc con BOM e CR LF: righe come prima, testo approvato invariato", r2.code == 0 and rd(w2, "luce/LuceScale.csc") == want2, r2.output & r2.errout)
  let w3 = fresh()
  let r3 = doWrite(w3, @["csc", "Luce", "Lampadina"], FILE, @["--dir", "comuni", "--dir", "comuni/"])
  rec("X", "la stessa cartella indicata con due scritture: una volta sola (I1) se non è la stessa stringa", r3.code == 0 or r3.code == 2, r3.errout)
  let w4 = fresh()
  let r4 = rn(w4, @["luce/Luce.csc", "--dir", "luce", "--dry-run", "csc", "Luce", "Lampadina"])
  rec("X", "--dir uguale alla cartella di FILE: un solo insieme, 'doppio' non scatta", r4.code == 0 and "controllo: invariato su 7 file" in r4.output, r4.output & r4.errout)
  let w5 = fresh()
  copyFile(w5 / "luce/Pressione.csc", w5 / "comuni/Pressione.csc")
  let r5 = rn(w5, @[FILE, "--dir", "comuni", "--dry-run", "--json", "csc", "Luce", "Lampadina"])
  rec("X", "lo stesso nome di file in due cartelle: doppio", r5.code == 1 and motivoOf(r5) == "doppio", r5.output & r5.errout)
  let w6 = fresh()
  writeFile(w6 / "comuni/Rotto.csc", "CSC X \xFF\n")
  let r6 = rn(w6, @[FILE, "--dir", "comuni", "--dry-run", "--json", "csc", "Luce", "Lampadina"])
  rec("X", "un file dell'insieme non UTF-8: illeggibile, niente scritto", r6.code == 1 and motivoOf(r6) == "illeggibile" and "(non UTF-8): niente scritto" in r6.errout, r6.output & r6.errout)
  let r7 = rn(w6, @[FILE, "--dir", "inesistente", "--dry-run", "csc", "Luce", "Lampadina"])
  rec("X", "--dir inesistente: codice 2 come check, con il prefisso bcdd rename:", r7.code == 2 and r7.errout.startsWith("bcdd rename: cartella non trovata: inesistente"), r7.errout)
  let r8 = rn(w6, @["luce/Nonesiste.csc", "--dry-run", "csc", "Luce", "Lampadina"])
  rec("X", "FILE inesistente: codice 2", r8.code == 2 and r8.errout.startsWith("bcdd rename: file non trovato: luce/Nonesiste.csc"), r8.errout)
  let r9 = rn(w, @[FILE, "--dir", "comuni", "--dry-run", "csc", "Fantasma", "Altro"])
  rec("X", "dichiarazione assente: non_trovato", r9.code == 1 and "luce/Luce.csc non contiene CSC Fantasma" in r9.errout, r9.errout)
  let r10 = rn(w, @[FILE, "--dir", "comuni", "--dry-run", "id", "zz9", "yy9"])
  rec("X", "id assente: messaggio con il blocco", r10.code == 1 and "nessuna GUARANTEE, ASSUME né SCENARIO con id zz9 nel blocco Luce" in r10.errout, r10.errout)
  let r11 = rn(w, @["luce/LuceScale.csc", "--dir", "comuni", "--dry-run", "part", "zz", "yy"])
  rec("X", "parte assente: messaggio con la ENTITY", r11.code == 1 and "nessuna parte zz nella ENTITY LuceScale" in r11.errout, r11.errout)
  let r12 = rn(w, @["--recover", "luce"])
  rec("X", "--recover senza giornale: codice 1", r12.code == 1 and r12.errout == "bcdd rename: in luce non c'è una rinomina interrotta\n", r12.errout)
  let r13 = rn(w, @["--recover", "nonce"])
  rec("X", "--recover su cartella inesistente: codice 2", r13.code == 2, r13.errout)

# ---------------------------------------------------------------- 10.4: le altre scritture con un giornale presente

const kCmdIt = " c'è una rinomina interrotta: non scrivo nulla; esegui bcdd rename --recover "

block:
  let w = fresh()
  writeFile(w / ".bcdd-rinomina", "")
  let before = snapshot(w)
  let r = runX(bcdd, @["new", "Nuova"], w)
  rec("AC-452", "new con giornale: codice 1, stdout vuoto, messaggio di §15.6 (it)",
    r.code == 1 and r.output.len == 0 and r.errout == "bcdd new: in ." & kCmdIt & ".\n", r.errout)
  let r2 = runX(bcdd, @["--lang", "en", "new", "Nuova"], w)
  rec("AC-452", "new con giornale, --lang en", r2.code == 1 and r2.output.len == 0 and
    r2.errout == "bcdd new: there is an interrupted rename in .: I am not writing anything; run bcdd rename --recover .\n", r2.errout)
  rec("AC-452", "Nuova.csc non creato, nessun temporaneo", not fileExists(w / "Nuova.csc") and snapshot(w) == before, $listAll(w))
  let w2 = fresh()
  let r3 = runX(bcdd, @["new", "Nuova"], w2)
  rec("AC-452", "senza giornale new crea il file (il rifiuto è solo del giornale)", r3.code == 0 and fileExists(w2 / "Nuova.csc"), r3.errout)

block:
  let w = fresh()
  writeFile(w / "luce/.bcdd-rinomina", "")
  let before = snapshot(w)
  let r = runX(bcdd, @["ratify", "luce/Pressione.csc", "D-9"], w)
  rec("AC-453", "ratify con giornale in luce/: codice 1, CARTELLA = luce", r.code == 1 and r.output.len == 0 and r.errout == "bcdd ratify: in luce" & kCmdIt & "luce\n" and snapshot(w) == before, r.errout)
  removeFile(w / "luce/.bcdd-rinomina")
  writeFile(w / "comuni/.bcdd-rinomina", "")
  let r2 = runX(bcdd, @["ratify", "luce/Pressione.csc", "--dir", "comuni", "D-9"], w)
  rec("AC-453", "giornale in comuni/ con --dir comuni: ratify scrive (K7)", r2.code == 0 and "STATUS RATIFIED BY D-9" in rd(w, "luce/Pressione.csc"), r2.errout)

block:
  if fileExists(bcddProva):
    let w = fresh()
    let rf = f2Dir / "refine"
    copyFile(rf / "Luce.csc", w / "Luce.csc")
    let buona = rf / "risposte" / "buona.json"
    let sec = ("BCDD_FINTO_RISPOSTA_2", rf / "risposte" / "buona_seconda.json")
    let aux = w & "_aux"
    createDir(aux)
    let ex = mkEnv(@[("BCDD_LLM", f2Dir / "ULlmFinto.sh"), ("BCDD_ATTESA_LLM", "30"), ("BCDD_ORA", "2026-10-16T18:00:00+02:00"),
      ("BCDD_REGISTRO", w / "chiamate.tsv"), ("BCDD_FINTO_CONTA", aux / "conta"), ("BCDD_FINTO_RISPOSTA", buona), sec])
    # il giro: tempo 1 senza giornale
    let t1 = runX(bcddProva, @["refine", "--json", "Luce.csc"], w, ex)
    let regFile = w / "chiamate.tsv"
    proc nChiamate(): int = (if fileExists(regFile): readFile(regFile).count('\n') else: 0)
    let c0 = nChiamate()
    let showBefore = runX(bcddProva, @["refine", "--json", "Luce.csc", "--show"], w, ex)
    writeFile(w / ".bcdd-rinomina", "")
    let snap = snapshot(w)
    let msg = "bcdd refine: in ." & kCmdIt & ".\n"
    var ok = t1.code == 0 and showBefore.code == 0
    var why = t1.output & t1.errout
    for args in [@["--answers"], @["--accept"], @["--cancel"]]:
      let r = runX(bcddProva, @["refine", "--json", "Luce.csc"] & args, w, ex, """{"risposte": [{"n": 1, "testo": "x"}]}""")
      if not (r.code == 1 and r.output.len == 0 and r.errout == msg): ok = false
      why.add " [" & args[0] & ": " & $r.code & " " & r.errout & "]"
    rec("AC-454", "--answers, --accept, --cancel su un giro aperto, con giornale: codice 1, stdout vuoto, messaggio di §15.6", ok, why)
    let sh = runX(bcddProva, @["refine", "--json", "Luce.csc", "--show"], w, ex)
    rec("AC-454", "--show con giornale: uscita uguale a quella senza", sh.code == 0 and sh.output == showBefore.output, sh.output & sh.errout)
    rec("AC-454", "nessuna chiamata al modello, FILE, FILE.giro e FILE.dialogo invariati", nChiamate() == c0 and snapshot(w) == snap, "")
    let w2 = fresh()
    copyFile(rf / "Luce.csc", w2 / "Luce.csc")
    writeFile(w2 / ".bcdd-rinomina", "")
    let ex2 = mkEnv(@[("BCDD_LLM", f2Dir / "ULlmFinto.sh"), ("BCDD_ATTESA_LLM", "30"), ("BCDD_ORA", "2026-10-16T18:00:00+02:00"),
      ("BCDD_REGISTRO", w2 / "chiamate.tsv"), ("BCDD_FINTO_RISPOSTA", buona)])
    let snap2 = snapshot(w2)
    let ri = runX(bcddProva, @["refine", "Luce.csc"], w2, ex2, "")
    let rj = runX(bcddProva, @["refine", "--json", "Luce.csc"], w2, ex2, "")
    rec("AC-454", "refine interattivo e --json tempo 1 con giornale: codice 1, messaggio, nessuna chiamata", ri.code == 1 and rj.code == 1 and ri.errout == msg and rj.errout == msg and
      rj.output.len == 0 and not fileExists(w2 / "chiamate.tsv") and snapshot(w2) == snap2, ri.errout & rj.errout)
  else:
    rec("AC-454", "eseguibile di prova presente", false, bcddProva)

block:
  let w = fresh()
  let orig = rd(w, "luce/Pressione.csc")
  writeFile(w / "luce/.bcdd-rinomina", "")
  let ip = fpOf(orig)
  var ok = true
  var why = ""
  # save: --expect IMPRONTA (testo nuovo su stdin), --expect nuovo, --undo, --remove
  let forms = @[(@["save", "luce/Pressione.csc", "--expect", ip], orig & "-- x\n"),
    (@["save", "luce/Nuovo.csc", "--expect", "nuovo"], "-- n\n"),
    (@["save", "luce/Pressione.csc", "--undo", "--expect", ip], ""),
    (@["save", "luce/Pressione.csc", "--remove", "--expect", ip], "")]
  let before = snapshot(w)
  for (a, inp) in forms:
    let r = runX(bcdd, a, w, nil, inp)
    if not (r.code == 1 and r.output.len == 0 and r.errout == "bcdd save: in luce" & kCmdIt & "luce\n"):
      ok = false
      why.add " [" & a.join(" ") & ": " & $r.code & " " & r.errout & "]"
  rec("AC-455", "save --expect, --expect nuovo, --undo, --remove con giornale: codice 1, messaggio con prefisso bcdd save:", ok, why)
  rec("AC-455", "FILE e FILE.prima invariati, nessun file nuovo", snapshot(w) == before, "")

block:
  let w = fresh()
  # giornale come cartella
  createDir(w / "luce/.bcdd-rinomina")
  let r = runX(bcdd, @["ratify", "luce/Pressione.csc", "D-9"], w)
  rec("AC-456", "giornale che è una cartella: ratify rifiuta (K2)", r.code == 1 and "c'è una rinomina interrotta" in r.errout, r.errout)
  removeDir(w / "luce/.bcdd-rinomina")
  # collegamento simbolico a un bersaglio inesistente
  createSymlink("non/esiste", w / "luce/.bcdd-rinomina")
  let r2 = runX(bcdd, @["ratify", "luce/Pressione.csc", "D-9"], w)
  rec("AC-456", "giornale che è un collegamento a un bersaglio inesistente: ratify rifiuta (K2)", r2.code == 1 and "c'è una rinomina interrotta" in r2.errout, r2.errout)
  removeFile(w / "luce/.bcdd-rinomina")
  var same = true
  var why = ""
  for args in [@["check", "luce/Luce.csc", "--dir", "comuni"], @["check", "--strict", "--json", "luce/LuceScale.csc", "--dir", "luce"], @["check", "--strict", "comuni/Corridoio.csc", "--dir", "luce"]]:
    let a = runX(bcdd, args, w)
    writeFile(w / "luce/.bcdd-rinomina", "")
    let b = runX(bcdd, args, w)
    removeFile(w / "luce/.bcdd-rinomina")
    if a.output != b.output or a.errout != b.errout or a.code != b.code:
      same = false
      why.add args.join(" ") & "; "
  rec("AC-456", "check con e senza giornale: uscita e codice identici byte per byte", same, why)

block:
  if fileExists(bcddProva):
    let hook = mkEnv(@[("BCDD_PROVA_GIORNALE_DOPO_CONTROLLO", "1")])
    let w = fresh()
    let orig = rd(w, "luce/Pressione.csc")
    let r = runX(bcddProva, @["ratify", "luce/Pressione.csc", "D-9"], w, hook)
    rec("AC-457", "ratify: il giornale compare dopo il primo controllo, prima della scrittura: codice 1, file invariato",
      r.code == 1 and r.errout == "bcdd ratify: in luce" & kCmdIt & "luce\n" and rd(w, "luce/Pressione.csc") == orig, r.errout)
    let w2 = fresh()
    let r2 = runX(bcddProva, @["save", "luce/Pressione.csc", "--expect", fpOf(orig)], w2, hook, orig & "-- x\n")
    rec("AC-457", "save: stesso esito", r2.code == 1 and r2.errout == "bcdd save: in luce" & kCmdIt & "luce\n" and rd(w2, "luce/Pressione.csc") == orig, r2.errout)
    let w3 = fresh()
    let r3 = runX(bcddProva, @["new", "Altra"], w3, hook)
    rec("AC-457", "new: il giornale compare dopo il primo controllo: nessun file creato", r3.code == 1 and not fileExists(w3 / "Altra.csc"), r3.errout & $listAll(w3))
    # refine --accept: il giro è aperto prima dell'aggancio; il giornale compare dopo il primo controllo
    let rf = f2Dir / "refine"
    let w4 = fresh()
    copyFile(rf / "Luce.csc", w4 / "Luce.csc")
    let aux = w4 & "_aux"
    createDir(aux)
    let base = @[("BCDD_LLM", f2Dir / "ULlmFinto.sh"), ("BCDD_ATTESA_LLM", "30"), ("BCDD_ORA", "2026-10-16T18:00:00+02:00"),
      ("BCDD_REGISTRO", w4 / "chiamate.tsv"), ("BCDD_FINTO_CONTA", aux / "conta"), ("BCDD_FINTO_RISPOSTA", rf / "risposte" / "buona.json"),
      ("BCDD_FINTO_RISPOSTA_2", rf / "risposte" / "buona_seconda.json")]
    let ex = mkEnv(base)
    discard runX(bcddProva, @["refine", "--json", "Luce.csc"], w4, ex)
    discard runX(bcddProva, @["refine", "--json", "--answers", "Luce.csc"], w4, ex, """{"risposte": [{"n": 1, "testo": "fra tre minuti circa"}]}""")
    let luceOrig = readFile(rf / "Luce.csc")
    let ex2 = mkEnv(base & @[("BCDD_PROVA_GIORNALE_DOPO_CONTROLLO", "1")])
    let r4 = runX(bcddProva, @["refine", "--json", "--accept", "Luce.csc"], w4, ex2, """{"accettate": ["p1"]}""")
    rec("AC-457", "refine --accept: il giornale compare dopo il primo controllo: codice 1, messaggio, CSC invariata",
      r4.code == 1 and r4.errout.startsWith("bcdd refine: in .") and rd(w4, "Luce.csc") == luceOrig, r4.output & r4.errout)
  else:
    rec("AC-457", "eseguibile di prova presente", false, bcddProva)

block:
  let w = fresh()
  for (arg, want) in [("luce/Pressione.csc", "luce"), ("./luce/Pressione.csc", "./luce"), ("comuni/../luce/Pressione.csc", "comuni/../luce")]:
    createDir(w / "luce"); writeFile(w / "luce/.bcdd-rinomina", "")
    let r = runX(bcdd, @["ratify", arg, "D-9"], w)
    rec("AC-458", "ratify " & arg & ": CARTELLA = " & want, r.errout == "bcdd ratify: in " & want & kCmdIt & want & "\n", r.errout)
  # senza separatore: «.»; il percorso assoluto e «./x.csc» («.», come in §15.6: la parte prima dell'ultimo separatore)
  let wl = fresh()
  copyFile(wl / "luce/Pressione.csc", wl / "x.csc")
  writeFile(wl / ".bcdd-rinomina", "")
  let r1 = runX(bcdd, @["ratify", "x.csc", "D-9"], wl)
  rec("AC-458", "ratify x.csc nella cartella: CARTELLA = .", r1.errout == "bcdd ratify: in ." & kCmdIt & ".\n", r1.errout)
  let r2 = runX(bcdd, @["ratify", "./x.csc", "D-9"], wl)
  rec("AC-458", "ratify ./x.csc: CARTELLA = . (la parte prima dell'ultimo separatore, come è scritta)", r2.errout == "bcdd ratify: in ." & kCmdIt & ".\n", r2.errout)
  let abs = wl / "sub"
  createDir(abs)
  copyFile(wl / "x.csc", abs / "x.csc")
  writeFile(abs / ".bcdd-rinomina", "")
  let r3 = runX(bcdd, @["ratify", abs / "x.csc", "D-9"], wl)
  rec("AC-458", "ratify /percorso/assoluto/x.csc: CARTELLA = /percorso/assoluto", r3.errout == "bcdd ratify: in " & abs & kCmdIt & abs & "\n", r3.errout)
  let r4 = runX(bcdd, @["ratify", "sub/x.csc", "D-9"], wl)
  rec("AC-458", "ratify sub/x.csc: CARTELLA = sub", r4.errout == "bcdd ratify: in sub" & kCmdIt & "sub\n", r4.errout)

block:
  let w = fresh()
  proc usoGenerale(lang: string): string =
    # la riga d'uso generale di GRAMMATICA_F1 §10: si legge dal documento, nella lingua data
    let doc = readFile(root / (if lang == "en": "GRAMMATICA_F1.en.md" else: "GRAMMATICA_F1.md"))
    let pre = if lang == "en": "usage: bcdd [--lang it|en] COMMAND;" else: "uso: bcdd [--lang it|en] COMANDO;"
    for l in doc.splitLines():
      if l.startsWith(pre): return l & "\n"
    ""
  for lang in ["it", "en"]:
    let r = runX(bcdd, (if lang == "en": @["--lang", "en"] else: @[]), w)
    let want = usoGenerale(lang)
    rec("AC-459", "bcdd senza argomenti (" & lang & "): la riga d'uso generale di §10 della grammatica, byte per byte", r.code == 2 and r.output.len == 0 and want.len > 0 and r.errout == want,
      "[" & r.errout & "] contro [" & want & "]")
  let r = runX(bcdd, @["--lang", "en", "rename"], w)
  let docEn = readFile(root / "GRAMMATICA_F1.en.md")
  let wantEn = "usage: bcdd rename FILE [--csc NAME] [--dir FOLDER]... (--dry-run | --expect FINGERPRINT [--text default|none|all | --text-at tN...]) [--json] csc|entity|part|id OLD NEW\n" &
    "       bcdd rename --recover FOLDER [--json]\n"
  rec("AC-459", "bcdd rename senza argomenti (en): la riga d'uso di §15.1 della grammatica inglese", r.code == 2 and r.errout == wantEn and wantEn.strip(chars = {'\n'}).splitLines().allIt(it in docEn), r.errout)
  let r2 = runX(bcdd, @["rename"], w)
  let docIt = readFile(root / "GRAMMATICA_F1.md")
  rec("AC-459", "bcdd rename senza argomenti (it): la riga d'uso di §15.1 della grammatica italiana", r2.code == 2 and r2.errout == usoRename and usoRename.strip(chars = {'\n'}).splitLines().allIt(it in docIt), r2.errout)

# ---------------------------------------------------------------- AC-460..AC-472

proc rnLang(w: string, lang: string, args: seq[string], exe: string = bcdd, env: StringTableRef = nil): Res =
  ## 142:1:1 Come `rn`, con `--lang` davanti al comando.
  runX(exe, @["--lang", lang, "rename"] & args, w, env)

proc impL(r: Res): string =
  ## 142:1:3 L'impronta dell'anteprima in italiano o in inglese.
  for l in r.output.splitLines():
    if l.startsWith("fingerprint: "): return l["fingerprint: ".len .. ^1]
  imp(r)

proc jsonMsg(r: Res): string =
  let j = jsonOf(r)
  if j == nil or j["messaggio"].kind == JNull: "" else: j["messaggio"].getStr()

proc copyNames(w, dir: string): seq[string] =
  ## 142:1:2 I nomi delle copie `.X.rinomina-vecchio.ID` di una cartella.
  for k, p in walkDir(w / dir, relative = true):
    if p.startsWith(".") and ".rinomina-vecchio." in p: result.add p

# AC-460: T5 per `id`
block:
  let w = fresh()
  writeFile(w / "luce/Luce.csc", "-- vedi la1\n" & rd(w, "luce/Luce.csc"))
  let r = prev(w, @["id", "la1", "la-base"], FILE, @["--csc", "Luce"])
  rec("AC-460", "un solo blocco dichiara la1: il commento `-- vedi la1` è [x]", r.code == 0 and "[x] luce/Luce.csc, riga 1, commento: -- vedi la1" in r.output, r.output & r.errout)
  let w2 = fresh()
  writeFile(w2 / "luce/Luce.csc", "-- vedi la1\n" & rd(w2, "luce/Luce.csc") &
    "\nCSC Altra VERSION 0.1\n  STATUS HYPOTHESIS\n  GUARANTEE la1: VERBAL \"Altra promessa\"\n                 VERIFY BY JUDGEMENT \"l'operatore\"\nEND\n")
  let rj = rn(w2, @[FILE, "--csc", "Luce", "--dry-run", "--json", "id", "la1", "la-base"])
  let j = jsonOf(rj)
  var scelti = 0
  var nTesti = 0
  if j != nil and j.hasKey("testi"):
    for t in j["testi"]:
      inc nTesti
      if t["scelto"].getBool(): inc scelti
  rec("AC-460", "un altro blocco dichiara la1: tutti i testi [ ], scelto false nel JSON", rj.code == 0 and nTesti > 0 and scelti == 0, rj.output & rj.errout)
  let p2 = prev(w2, @["id", "la1", "la-base"], FILE, @["--csc", "Luce"])
  rec("AC-460", "...e anche nel testo: nessun [x]", p2.code == 0 and " [x] " notin p2.output and "commento: -- vedi la1" in p2.output, p2.output & p2.errout)
  let ip = imp(p2)
  let rw = rn(w2, @[FILE, "--csc", "Luce", "--expect", ip, "--text", "all", "id", "la1", "la-base"])
  rec("AC-460", "--text all li cambia", rw.code == 0 and "-- vedi la-base" in rd(w2, "luce/Luce.csc"), rw.output & rw.errout)

# AC-461: T2, le citazioni Markdown
block:
  let w = fresh()
  let src = rd(w, "luce/Luce.csc")
  var k = 0
  for (txt, nome) in [("-- vedi [Luce] per i dettagli", "[Luce] senza definizione"), ("-- vedi [la Luce](doc.md) per i dettagli", "[la Luce](doc.md)"),
                      ("-- vedi [Luce](percorso con spazi) per i dettagli", "[Luce](percorso con spazi)"),
                      ("-- vedi [Luce, accesa](doc.md) per i dettagli", "[Luce, accesa](doc.md)")]:
    inc k
    let wk = fresh()
    writeFile(wk / "luce/Luce.csc", txt & "\n" & src)
    let r = prev(wk, @["csc", "Luce", "Lampadina"])
    let isText = ("luce/Luce.csc, riga 1, commento: " & txt) in r.output
    let want = nome in ["[Luce] senza definizione", "[Luce, accesa](doc.md)"]
    rec("AC-461", nome & (if want: ": è un testo" else: ": non è un testo"), r.code == 0 and isText == want, r.output & r.errout)
  let wd = fresh()
  writeFile(wd / "luce/Luce.csc", "-- vedi [Luce] per i dettagli\n-- [Luce]: doc.md\n" & src)
  let rd2 = prev(wd, @["csc", "Luce", "Lampadina"])
  rec("AC-461", "con `-- [Luce]: doc.md` nel file, [Luce] non è più un testo", rd2.code == 0 and "commento: -- vedi [Luce] per i dettagli" notin rd2.output, rd2.output & rd2.errout)

# AC-462: giornale presente in rename
block:
  let hdr = "bcdd-rinomina 1\nIDPROVA\n"
  proc refusal(w: string): Res = rn(w, @[FILE, "--dir", "comuni", "--dry-run", "csc", "Luce", "Lampadina"])
  let w1 = fresh()
  writeFile(w1 / "luce/.bcdd-rinomina", hdr & "csc Vecchia Nuova\n")
  let r1 = refusal(w1)
  rec("AC-462", "giornale con csc Vecchia Nuova: (Vecchia -> Nuova), cartella luce",
    r1.code == 1 and r1.errout == "bcdd rename: in luce c'è una rinomina interrotta (Vecchia -> Nuova): esegui bcdd rename --recover luce\n", r1.errout)
  let w2 = fresh()
  writeFile(w2 / "luce/.bcdd-rinomina", "")
  let r2 = refusal(w2)
  rec("AC-462", "giornale vuoto: (? -> ?)", r2.code == 1 and "in luce c'è una rinomina interrotta (? -> ?)" in r2.errout, r2.errout)
  let w3 = fresh()
  createDir(w3 / "luce/.bcdd-rinomina")
  let r3 = rn(w3, @[FILE, "--dir", "comuni", "--dry-run", "--json", "csc", "Luce", "Lampadina"])
  rec("AC-462", "giornale che è una cartella: (? -> ?), motivo giornale", r3.code == 1 and motivoOf(r3) == "giornale" and "in luce c'è una rinomina interrotta (? -> ?)" in r3.errout, r3.output & r3.errout)
  # giornale solo in comuni/
  let w4 = fresh()
  writeFile(w4 / "comuni/Corridoio.csc", rd(w4, "comuni/Corridoio.csc").replace("OFFERS Luce VERSION 0.1", "OFFERS Pressione"))
  writeFile(w4 / "comuni/.bcdd-rinomina", hdr & "csc Vecchia Nuova\n")
  let r4 = prev(w4, @["csc", "Luce", "Lampadina"])
  rec("AC-462", "giornale solo in comuni/: l'anteprima riesce (codice 0)", r4.code == 0, r4.output & r4.errout)
  let ip = imp(r4)
  let before = contents(w4)   # i contenuti, non le date: il giornale di luce/ nasce e si toglie (J1, §6.2 passo 3), e cambia la data della cartella
  let r5 = rn(w4, @[FILE, "--dir", "comuni", "--expect", ip, "--json", "csc", "Luce", "Lampadina"])
  rec("AC-462", "--expect P: codice 1, giornale, cartella comuni, niente scritto", r5.code == 1 and motivoOf(r5) == "giornale" and "in comuni c'è una rinomina interrotta" in jsonMsg(r5) and contents(w4) == before and hasWork(w4) == @["comuni/.bcdd-rinomina"],
    r5.output & r5.errout)
  let r6 = rn(w4, @[FILE, "--dir", "comuni", "--expect", ip, "--text", "none", "csc", "Luce", "Lampadina"])
  rec("AC-462", "--text none: scritto senza toccare comuni/", r6.code == 0 and fileExists(w4 / "luce/Lampadina.csc") and
    rd(w4, "comuni/Corridoio.csc") == readFile(sinteticaSrc / "comuni/Corridoio.csc").replace("OFFERS Luce VERSION 0.1", "OFFERS Pressione"), r6.output & r6.errout)

# AC-463, AC-467, AC-469, AC-464: ripristino
block:
  if not fileExists(bcddProva):
    for ac in ["AC-463", "AC-464", "AC-467", "AC-469"]: rec(ac, "eseguibile di prova presente", false, bcddProva)
  else:
    let orig = contents(sinteticaSrc)
    proc env(k: string): StringTableRef = mkEnv(@[("BCDD_RINOMINA_PROVA_FERMA", k)])
    proc interrupted(k: string): string =
      result = fresh()
      discard doWrite(result, @["csc", "Luce", "Lampadina"], FILE, @["--dir", "comuni"], @[], bcddProva, env(k))
    # la copia di un'operazione applicata: la partenza non c'è più o non è più quella di prima
    proc appliedCopy(w: string): string =
      for c in copyNames(w, "luce"):
        let x = c[1 ..< c.find(".rinomina-vecchio.")]
        if not fileExists(w / "luce" / x) or readFile(w / "luce" / x) != readFile(w / "luce" / c): return c
    let w = interrupted("3")
    let cp = appliedCopy(w)
    rec("AC-463", "dopo k=3 c'è una copia di un'operazione applicata", cp.len > 0, $copyNames(w, "luce"))
    let spost = w / "copia_spostata"
    moveFile(w / "luce" / cp, spost)
    let x = cp[1 ..< cp.find(".rinomina-vecchio.")]
    let wantIt = "bcdd rename: ripristino non riuscito su " & x & " (copia del testo di prima mancante o diversa: " & cp & "): i giornali restano; elimina la causa e riesegui bcdd rename --recover luce\n"
    let wantEn = "bcdd rename: recovery failed on " & x & " (copy of the previous text missing or different: " & cp & "): the journals remain; fix the cause and run bcdd rename --recover luce again\n"
    let r = rn(w, @["--recover", "luce"])
    rec("AC-463", "copia spostata: codice 1, scrittura, messaggio di R6, giornali presenti",
      r.code == 1 and r.output.len == 0 and r.errout == wantIt and fileExists(w / "luce/.bcdd-rinomina") and fileExists(w / "comuni/.bcdd-rinomina"), r.output & r.errout)
    let rj = rn(w, @["--recover", "luce", "--json"])
    rec("AC-463", "--json: motivo scrittura", rj.code == 1 and motivoOf(rj) == "scrittura", rj.output & rj.errout)
    let re = rnLang(w, "en", @["--recover", "luce"])
    rec("AC-469", "--lang en: messaggio di R6 inglese, byte per byte", re.code == 1 and re.errout == wantEn, re.errout)
    rec("AC-469", "--lang it: messaggio di R6 italiano, byte per byte", r.errout == wantIt, r.errout)
    rec("AC-469", "--json: la stessa riga in messaggio", wantIt.strip(chars = {'\n'}) in jsonMsg(rj) , jsonMsg(rj))
    moveFile(spost, w / "luce" / cp)
    let r2 = rn(w, @["--recover", "luce"])
    rec("AC-463", "copia rimessa: --recover riporta tutto ai byte di prima", r2.code == 0 and "com'erano prima" in r2.output and contents(w) == orig and hasWork(w).len == 0,
      r2.output & r2.errout & $hasWork(w))
    # AC-467: --recover da comuni/
    let w3 = interrupted("3")
    let r3 = rn(w3, @["--recover", "comuni"])
    rec("AC-467", "--recover comuni: file di prima in entrambe le cartelle, nessun giornale né file di lavoro", r3.code == 0 and contents(w3) == orig and hasWork(w3).len == 0,
      r3.output & r3.errout & $hasWork(w3))
    # AC-464: arrivo estraneo
    let w4 = interrupted("5")
    writeFile(w4 / "luce/Lampadina.csc", rd(w4, "luce/Lampadina.csc") & "-- a mano\n")
    let before = snapshot(w4)
    let r4 = rn(w4, @["--recover", "luce"])
    let cp4 = block:
      var c = ""
      for n in copyNames(w4, "luce"):
        if n.startsWith(".Luce.csc.rinomina-vecchio."): c = n
      c
    rec("AC-464", "arrivo estraneo: codice 1, il messaggio nomina Lampadina.csc e la copia .Luce.csc.rinomina-vecchio.ID",
      r4.code == 1 and cp4.len > 0 and r4.errout == "bcdd rename: Lampadina.csc non è né il testo di prima né quello nuovo: non tocco niente; il testo di prima è in " & cp4 & "\n", r4.errout & " / " & cp4)
    rec("AC-464", "nulla toccato", snapshot(w4) == before, "")

# AC-465: R5 e R7
block:
  var ok = true
  var why = ""
  proc chk(label: string, w: string, motivo, frag: string) =
    let r = rn(w, @["--recover", "luce"])
    let rj = rn(w, @["--recover", "luce", "--json"])
    let j = jsonOf(rj)
    let good = r.code == 1 and r.output.len == 0 and frag in r.errout and rj.code == 1 and j != nil and motivoOf(rj) == motivo and rj.output.count('\n') == 1
    if not good: ok = false
    if not good: why.add label & ": " & r.errout & " | " & rj.output & "\n"
  let w1 = fresh()
  chk("senza giornale", w1, "giornale", "bcdd rename: in luce non c'è una rinomina interrotta\n")
  let w2 = fresh()
  writeFile(w2 / "luce/.bcdd-rinomina", "un testo qualunque\n")
  chk("giornale di testo qualunque", w2, "scrittura", "bcdd rename: il giornale luce/.bcdd-rinomina non è nella forma attesa: non tocco niente\n")
  let w3 = fresh()
  createDir(w3 / "luce/.bcdd-rinomina")
  chk("giornale che è una cartella", w3, "scrittura", "bcdd rename: non riesco a leggere il giornale luce/.bcdd-rinomina (non leggibile): non tocco niente\n")
  rec("AC-465", "R5 e R7: motivi giornale, scrittura, scrittura; un solo oggetto con --json", ok, why)

# AC-466: doppio
block:
  let w = fresh()
  copyFile(w / "luce/Pressione.csc", w / "comuni/Pressione.csc")
  let before = snapshot(w)
  let r = rn(w, @[FILE, "--dir", "comuni", "--dry-run", "csc", "Luce", "Lampadina"])
  rec("AC-466", "doppio (it): testo di §7.4, byte per byte",
    r.code == 1 and r.errout == "bcdd rename: il file Pressione.csc è in due cartelle (luce, comuni): rename non sceglie quale riscrivere; indica una sola delle due cartelle\n", r.errout)
  let re = rnLang(w, "en", @[FILE, "--dir", "comuni", "--dry-run", "csc", "Luce", "Lampadina"])
  rec("AC-466", "doppio (en): testo di GRAMMATICA_F1.en.md §15.5, byte per byte",
    re.code == 1 and re.errout == "bcdd rename: the file Pressione.csc is in two folders (luce, comuni): rename does not choose which one to rewrite; give only one of the two folders\n", re.errout)
  rec("AC-466", "i due testi stanno nella grammatica", "indica una sola delle due cartelle" in readFile(root / "GRAMMATICA_F1.md") and
    "give only one of the two folders" in readFile(root / "GRAMMATICA_F1.en.md"), "")
  rec("AC-466", "niente cambiato", snapshot(w) == before, "")

# AC-468: il catalogo dei testi di rename contro le sedi di §7.6
block:
  let cat = readFile(root / "src" / "bcddtesti.nim")
  var code = ""
  for f in walkFiles(root / "src" / "*.nim"):
    if f.extractFilename != "bcddtesti.nim": code.add readFile(f)
  let docs = {"it": (if fileExists(root / "DESIGN_RINOMINA.md"): readFile(root / "DESIGN_RINOMINA.md") else: "") & readFile(root / "GRAMMATICA_F1.md"),
              "en": (if fileExists(root / "DESIGN_RINOMINA.md"): readFile(root / "DESIGN_RINOMINA.md") else: "") & readFile(root / "GRAMMATICA_F1.en.md")}.toTable
  var voci: seq[string]
  var missing, unused: seq[string]
  var pos = 0
  while true:
    let a = cat.find("voce kRin", pos)
    if a < 0: break
    let nameEnd = cat.find(',', a)
    let nm = cat[a + 5 ..< nameEnd]
    # le stringhe: due letterali (it, en) dopo il nome, anche su righe diverse
    var lits: seq[string]
    var q = nameEnd
    while lits.len < 2:
      let s0 = cat.find('"', q)
      var e = s0 + 1
      while cat[e] != '"':
        if cat[e] == '\\': inc e
        inc e
      lits.add cat[s0 + 1 ..< e].replace("\\\"", "\"")
      q = e + 1
    pos = q
    voci.add nm
    if nm notin code: unused.add nm
    if nm.startsWith("kRinJson") or nm.startsWith("kRinCat") or nm in ["kRinUso"]: continue
    for (lang, lit) in [("it", lits[0]), ("en", lits[1])]:
      var parts: seq[string]
      var cur = ""
      var i = 0
      while i < lit.len:
        if lit[i] == '$' and i + 1 < lit.len and lit[i + 1] in {'0'..'9'}:
          parts.add cur
          cur = ""
          i += 2
        else:
          cur.add lit[i]
          inc i
      parts.add cur
      for p in parts:
        let t = p.strip(chars = {' ', '(', ')', ':', ';', ','})
        if t.len >= 3 and t notin docs[lang]: missing.add nm & "/" & lang & ": [" & t & "]"
  rec("AC-468", "nessuna parte fissa mancante nelle sedi di §7.6", missing.len == 0 or not fileExists(root / "DESIGN_RINOMINA.md"), missing.join("; "))
  rec("AC-468", "nessuna voce kRin* non usata dal codice", unused.len == 0, unused.join(", "))
  rec("AC-468", "kRinSecondaDir non c'è più", "kRinSecondaDir" notin voci, "")
  rec("AC-468", "C-8: kRinCopiaMancante e kRinRipristinoFallito hanno i testi di R6", ("voce kRinCopiaMancante, \"copia del testo di prima mancante o diversa: $1\"" in cat) and
    ("\"copy of the previous text missing or different: $1\"" in cat) and "kRinRipristinoFallito" in voci, "")
  rec("AC-468", "C-9: kRinNumRighe1, kRinNumRigheN, kRinNumFile1, kRinNumFileN ci sono", allIt(["kRinNumRighe1", "kRinNumRigheN", "kRinNumFile1", "kRinNumFileN"], it in voci), $voci.len)

# AC-470: singolare e plurale
block:
  let w = fresh()
  createDir(w / "solo")
  copyFile(w / "luce/Pressione.csc", w / "solo/Pressione.csc")
  for lang in ["it", "en"]:
    let ctl = if lang == "it": "controllo: invariato su 1 file\n" else: "check: unchanged on 1 file\n"
    let riep = if lang == "it": "nomi cambiati: 1 riga in 1 file; testi cambiati: 0; testi rimasti con il nome vecchio: 0\n"
               else: "names changed: 1 line in 1 file; texts changed: 0; texts left with the old name: 0\n"
    let wl = fresh()
    createDir(wl / "solo")
    copyFile(wl / "luce/Pressione.csc", wl / "solo/Pressione.csc")
    let p = rnLang(wl, lang, @["solo/Pressione.csc", "--dry-run", "csc", "Pressione", "Tasto"])
    rec("AC-470", "(a) " & lang & ": anteprima con " & ctl.strip(), p.code == 0 and ctl in p.output, p.output & p.errout)
    let r = rnLang(wl, lang, @["solo/Pressione.csc", "--expect", impL(p), "csc", "Pressione", "Tasto"])
    rec("AC-470", "(a) " & lang & ": scrittura con riepilogo e controllo al singolare", r.code == 0 and riep & ctl in r.output, r.output & r.errout)
    let wb = fresh()
    let pb = rnLang(wb, lang, @[FILE, "--dir", "comuni", "--dry-run", "id", "la1", "lb1"])
    let rb = rnLang(wb, lang, @[FILE, "--dir", "comuni", "--expect", impL(pb), "id", "la1", "lb1"])
    let wantB = if lang == "it": "nomi cambiati: 2 righe in 1 file; " else: "names changed: 2 lines in 1 file; "
    rec("AC-470", "(b) " & lang & ": 2 righe in 1 file", rb.code == 0 and wantB in rb.output, rb.output & rb.errout)
  # (c) 423/424: italiano invariato, inglese al plurale
  let wc = fresh()
  let pc = prev(wc, @["csc", "Luce", "Lampadina"])
  rec("AC-470", "(c) it: l'anteprima è ancora 423 byte per byte", pc.output.replace(imp(pc), "sha256:…") == readFile(prDir / "423_anteprima.atteso"), "")
  let pe = rnLang(wc, "en", @[FILE, "--dir", "comuni", "--dry-run", "csc", "Luce", "Lampadina"])
  rec("AC-470", "(c) en: anteprima con `check: unchanged on 8 files`", pe.code == 0 and "check: unchanged on 8 files\n" in pe.output, pe.output & pe.errout)
  let re = rnLang(wc, "en", @[FILE, "--dir", "comuni", "--expect", impL(pe), "csc", "Luce", "Lampadina"])
  rec("AC-470", "(c) en: scrittura con `names changed: 7 lines in 5 files; …` e `check: unchanged on 8 files`",
    re.code == 0 and "names changed: 7 lines in 5 files; " in re.output and "check: unchanged on 8 files\n" in re.output, re.output & re.errout)
  let w2 = fresh()
  let wr = doWrite(w2, @["csc", "Luce", "Lampadina"])
  rec("AC-470", "(c) it: la scrittura è ancora 424 byte per byte", wr.output == readFile(prDir / "424_scritto.atteso"), wr.output)

# AC-471: nome non valido
block:
  let w = fresh()
  let before = snapshot(w)
  for (lang, want) in [("it", "bcdd rename: nome non valido per csc: Lam-pada\n"), ("en", "bcdd rename: invalid name for csc: Lam-pada\n")]:
    for js in [false, true]:
      let r = rnLang(w, lang, @[FILE, "--dir", "comuni", "--dry-run"] & (if js: @["--json"] else: @[]) & @["csc", "Luce", "Lam-pada"])
      rec("AC-471", lang & (if js: " --json" else: "") & ": codice 2, stdout vuoto, messaggio", r.code == 2 and r.output.len == 0 and r.errout == want, $r.code & " [" & r.errout & "] [" & r.output & "]")
  rec("AC-471", "niente cambiato", snapshot(w) == before, "")

# AC-472: una sola riga approvata
block:
  let w = fresh()
  let r = rnLang(w, "it", @["luce/LuceScale.csc", "--dry-run", "--json", "id", "ls1", "ls9"])
  let ri = rn(w, @["luce/LuceScale.csc", "--dry-run", "id", "ls1", "ls9"])
  let re = rnLang(w, "en", @["luce/LuceScale.csc", "--dry-run", "id", "ls1", "ls9"])
  rec("AC-472", "it: codice 1, motivo approvato", r.code == 1 and motivoOf(r) == "approvato" and ri.code == 1, r.output & ri.errout)
  rec("AC-472", "it: prima riga `ls1 non si rinomina: compare in 1 riga approvata:`", ri.errout.splitLines()[0] == "bcdd rename: ls1 non si rinomina: compare in 1 riga approvata:", ri.errout)
  rec("AC-472", "en: prima riga `ls1 cannot be renamed: it appears in 1 approved line:`",
    re.code == 1 and re.errout.splitLines()[0] == "bcdd rename: ls1 cannot be renamed: it appears in 1 approved line:", re.errout)
  let nb = if r.code == 1 and jsonOf(r) != nil and jsonOf(r).hasKey("bloccanti"): jsonOf(r)["bloccanti"].len else: -1
  rec("AC-472", "una sola riga bloccata (riga 8, D-6)", nb == 1 and "riga 8" in ri.errout and "D-6" in ri.errout, $nb & " " & ri.errout)

# ---------------------------------------------------------------- verdetto

removeDir(tmpBase)
var totalPass, totalAll, acFail = 0
acOrder.sort(proc(a, b: string): int =
  proc key(s: string): int = (if s == "X": 100000 else: parseInt(s[3 .. ^1]))
  cmp(key(a), key(b)))
for ac in acOrder:
  let ok = acPass[ac] == acTotal[ac]
  totalPass += acPass[ac]
  totalAll += acTotal[ac]
  if not ok: inc acFail
  echo align(ac, 6) & "  " & (if ok: "PASS " else: "FAIL ") & $acPass[ac] & "/" & $acTotal[ac]
  if not ok:
    for d in details[ac]: echo "        - " & d
echo "controlli: " & $totalPass & "/" & $totalAll & " PASS; criteri non riusciti: " & $acFail &
  "; durata suite: " & formatFloat(epochTime() - t0, ffDecimal, 2) & " s"
quit(if totalPass == totalAll: 0 else: 1)

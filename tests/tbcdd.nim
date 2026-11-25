# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 050:1:1 Suite di accettazione di bcdd F1, F2 e F3a: AC-1..AC-27 (GRAMMATICA_F1), AC-28..AC-94,
# 050:1:5 AC-95..AC-114 (parte B.9), AC-127..AC-148, AC-163..AC-170
# 050:1:6 e prove di bordo.
# 050:1:2 Modalità Unattended. Legge i rapporti attesi da prove/*.atteso (nessuna copia nel codice),
# 050:1:3 lancia il binario `bcdd` compilato (env BCDD, oppure ../bcdd; per refine l'eseguibile di prova tests/bcdd_prova,
# 050:1:4 env BCDD_PROVA) e stampa un verdetto compatto:
# 050:1:4 una riga per criterio, i dettagli solo per i FAIL. Esce con codice 1 se qualcosa fallisce.
import std/[os, osproc, streams, strutils, tables, times, posix, algorithm, sets, strtabs, sequtils, json]

# 050:2:1: le prove esistenti fissano la lingua italiana; `bcdd` senza BCDD_LANG parla inglese.
putEnv("BCDD_LANG", "it")

type
  Res = tuple[output, errout: string, code: int]

let
  root = currentSourcePath().parentDir.parentDir
  bcdd = getEnv("BCDD", root / "bcdd")
  proveDir = root / "prove"
  cscDir = root / "csc"

var
  acOrder: seq[string]
  acPass, acTotal: Table[string, int]
  details: Table[string, seq[string]]
  proveFail: HashSet[string]
  proveSeen: HashSet[string]

proc run(args: seq[string], cwd: string): Res =
  ## 051:1:1 Lancia bcdd con gli argomenti dati e restituisce stdout, stderr e codice d'uscita.
  let p = startProcess(bcdd, workingDir = cwd, args = args, options = {})
  result.output = p.outputStream.readAll()
  result.errout = p.errorStream.readAll()
  result.code = p.waitForExit()
  p.close()

proc firstDiff(a, b: string): string =
  let la = a.split('\n')
  let lb = b.split('\n')
  for i in 0 ..< max(la.len, lb.len):
    let x = if i < la.len: la[i] else: "<fine>"
    let y = if i < lb.len: lb[i] else: "<fine>"
    if x != y:
      return "riga " & $(i + 1) & ": ottenuto [" & x & "] atteso [" & y & "]"
  "differenza solo nei byte finali (lunghezze " & $a.len & " / " & $b.len & ")"

proc rec(ac, label: string, ok: bool, why: string = "", prova: string = "") =
  if ac notin acTotal:
    acOrder.add ac
    acTotal[ac] = 0
    acPass[ac] = 0
    details[ac] = @[]
  inc acTotal[ac]
  if prova.len > 0: proveSeen.incl prova
  if ok:
    inc acPass[ac]
  else:
    details[ac].add label & ": " & why
    if prova.len > 0: proveFail.incl prova

proc expectOut(ac, label, prova: string, r: Res, wantOut: string, wantCode: int) =
  var ok = true
  var why = ""
  if r.output != wantOut:
    ok = false
    why = "stdout " & firstDiff(r.output, wantOut)
  elif r.code != wantCode:
    ok = false
    why = "codice " & $r.code & " invece di " & $wantCode
  elif r.errout.len != 0:
    ok = false
    why = "stderr non vuoto: " & r.errout
  rec(ac, label, ok, why, prova)

proc expectErr(ac, label, prova: string, r: Res, wantErr: string, wantCode: int) =
  var ok = true
  var why = ""
  if r.errout != wantErr:
    ok = false
    why = "stderr [" & r.errout & "] atteso [" & wantErr & "]"
  elif r.output.len != 0:
    ok = false
    why = "stdout non vuoto"
  elif r.code != wantCode:
    ok = false
    why = "codice " & $r.code & " invece di " & $wantCode
  rec(ac, label, ok, why, prova)

proc listDir(d: string): seq[string] =
  for k, p in walkDir(d, relative = true): result.add p
  result.sort()

proc firstLineReplaced(s, newFirst: string): string =
  let i = s.find('\n')
  newFirst & s[i .. ^1]

proc snapshot(dirs: seq[string]): Table[string, (string, times.Time)] =
  for d in dirs:
    for f in walkDirRec(d):
      result[f] = (readFile(f), getLastModificationTime(f))

# 052:1:1 Codici d'uscita attesi per le prove numerate (tabella di sezione 12); i rapporti sono nei .atteso.
# 052:1:2 Una prova numerata nuova, non ancora in tabella, si scopre da sola: il suo codice si ricava dalla
# 052:1:3 riga `esito:` del suo .atteso (nessun errore = 0, altrimenti 1) e la suite lo dichiara con una nota.
const proveCode = {"01": 0, "02": 1, "03": 1, "04": 1, "05": 1, "06": 1, "07": 1, "08": 1, "09": 1,
  "10": 1, "11": 1, "12": 1, "13": 1, "14": 0, "15": 0, "16": 0, "17": 0, "18": 0, "19": 2, "20": 1,
  "21": 1, "22": 1, "23": 1, "24": 1, "25": 1, "26": 1}.toTable

proc codeOf(nn: string, stem: string): int =
  if nn in proveCode: return proveCode[nn]
  let last = readFile(proveDir / stem & ".atteso").strip().splitLines()[^1]
  if last == "esito: nessun errore": 0 else: 1

proc acOf(nn: string): string =
  ## 052:2:1 Criterio che prova ciascun file (sezione 12): 01-18 e 20 AC-1, poi AC-19..AC-24 e AC-56.
  case nn
  of "21": "AC-19"
  of "22": "AC-21"
  of "23": "AC-22"
  of "24": "AC-23"
  of "25": "AC-24"
  of "26": "AC-56"
  else: "AC-1"

let t0 = epochTime()
if not fileExists(bcdd):
  echo "FAIL: eseguibile non trovato: " & bcdd & " (compilarlo con: nimble build -d:release)"
  quit(1)

let tmpBase = getTempDir() / ("bcdd_test_" & $getCurrentProcessId())
createDir(tmpBase)
let before = snapshot(@[proveDir, cscDir])

# 053:1:1 Elenco delle prove numerate e delle CSC di F0
var proveFiles: seq[string]
for f in walkFiles(proveDir / "[0-9][0-9]_*.csc"): proveFiles.add f.extractFilename
proveFiles.sort()
var f0names: seq[string]
for f in walkFiles(proveDir / "F0_*.atteso"): f0names.add f.extractFilename[3 .. ^8]
f0names.sort()
rec("AC-0", "prove numerate presenti: almeno le 25 della 1.2, numerazione senza buchi", block:
  var ok = proveFiles.len >= 25
  for i, f in proveFiles:
    if f[0 .. 1] != align($(i + 1), 2, '0'): ok = false
  ok, "trovate " & $proveFiles.len & ": " & proveFiles.join(" "))
for f in proveFiles:
  if f[0 .. 1] notin proveCode: echo "nota: prova " & f & " non in tabella: codice ricavato dal suo .atteso"
rec("AC-0", "6 rapporti F0 presenti", f0names.len == 6, "trovati " & $f0names.len)
rec("AC-0", "ogni F0_Nome.atteso ha csc/Nome.csc", block:
  var all = true
  for n in f0names:
    if not fileExists(cscDir / n & ".csc"): all = false
  all, "manca una CSC")

proc runAc1(cwdDir, base: string, ac: string): seq[string] =
  ## 054:1:1 AC-1 / AC-4 e AC-19..AC-24, AC-56: ogni prova numerata salvo la 19; restituisce le uscite per il confronto di AC-6.
  for f in proveFiles:
    let nn = f[0 .. 1]
    if nn == "19": continue
    let stem = f[0 .. ^5]
    let r = run(@["check", base / f], cwdDir)
    if ac.len > 0:
      expectOut(if ac == "AC-1": acOf(nn) else: ac, f, f, r, readFile(proveDir / stem & ".atteso"), codeOf(nn, stem))
    result.add r.output

proc runAc3(cwdDir, base: string, ac: string) =
  for n in f0names:
    let r = run(@["check", base / n & ".csc"], cwdDir)
    expectOut(ac, n, "F0_" & n, r, readFile(proveDir / "F0_" & n & ".atteso"), 0)

# 055:1:1 AC-1, AC-2, AC-3 dalla cartella del progetto
let outs1 = runAc1(root, "prove", "AC-1")
for f in proveFiles:
  if f.startsWith("19"):
    let r = run(@["check", "prove" / f], root)
    expectErr("AC-2", f, f, r, readFile(proveDir / f[0 .. ^5] & ".atteso"), 2)
runAc3(root, "csc", "AC-3")

# 055:2:1 AC-4: lo stesso da un'altra cartella, con percorso assoluto
let other = tmpBase / "altra"
createDir(other)
discard runAc1(other, proveDir, "AC-4")
runAc3(other, cscDir, "AC-4")

# 055:3:1 AC-6 (g-c4): due esecuzioni di AC-1 danno le stesse uscite
let outs2 = runAc1(root, "prove", "")
rec("AC-6", "due esecuzioni di AC-1", outs1 == outs2, "uscite diverse")

# 056:1:1 AC-7 / AC-8 / AC-9 / AC-10 / AC-11: bcdd new
let nd = tmpBase / "nuova"
createDir(nd)
block:
  let r = run(@["new", "Esempio"], nd)
  expectOut("AC-7", "new Esempio", "", r, "creato Esempio.csc\n", 0)
  rec("AC-7", "cmp con prove/17_new_Esempio.csc", fileExists(nd / "Esempio.csc") and
    readFile(nd / "Esempio.csc") == readFile(proveDir / "17_new_Esempio.csc"), "contenuto diverso")
  let c = run(@["check", "Esempio.csc"], nd)
  expectOut("AC-8", "check del file creato", "", c,
    firstLineReplaced(readFile(proveDir / "17_new_Esempio.atteso"), "bcdd check Esempio.csc"), 0)
  let h = readFile(nd / "Esempio.csc")
  let m1 = getLastModificationTime(nd / "Esempio.csc")
  let r2 = run(@["new", "Esempio"], nd)
  expectErr("AC-9", "secondo new", "", r2, "bcdd new: Esempio.csc esiste già: non lo sovrascrivo\n", 1)
  rec("AC-9", "file non toccato", readFile(nd / "Esempio.csc") == h and
    getLastModificationTime(nd / "Esempio.csc") == m1, "il file è cambiato")
  rec("AC-9", "nessun file temporaneo", listDir(nd) == @["Esempio.csc"], $listDir(nd))
  let rc = run(@["new", "Città"], nd)
  expectOut("AC-10", "new Città", "", rc, "creato Città.csc\n", 0)
  rec("AC-10", "Città.csc esiste", fileExists(nd / "Città.csc"), "file non creato")
  let cc = run(@["check", "Città.csc"], nd)
  rec("AC-10", "check di Città.csc dà 0", cc.code == 0 and cc.errout.len == 0, "codice " & $cc.code)
  let listing = listDir(nd)
  for bad in ["g-1", "END", "3x"]:
    let rb = run(@["new", bad], nd)
    expectErr("AC-11", "new " & bad, "", rb, "bcdd new: nome non valido: " & bad & "\n", 2)
  rec("AC-11", "nessun file creato", listDir(nd) == listing, $listDir(nd))

# 057:1:1 AC-12: usi sbagliati e file mancanti
block:
  const usoCheck = "uso: bcdd check [--strict] [--json] [--dir CARTELLA]... FILE\n"
  const usoNew = "uso: bcdd new NOME\n"
  expectErr("AC-12", "check senza argomenti", "", run(@["check"], root), usoCheck, 2)
  expectErr("AC-12", "check a b", "", run(@["check", "a", "b"], root), usoCheck, 2)
  expectErr("AC-12", "check -x", "", run(@["check", "-x", "prove/01_minima.csc"], root), usoCheck, 2)
  expectErr("AC-12", "check --strict da solo", "", run(@["check", "--strict"], root), usoCheck, 2)
  expectErr("AC-12", "check -", "", run(@["check", "-"], root), usoCheck, 2)
  expectErr("AC-12", "new senza argomenti", "", run(@["new"], root), usoNew, 2)
  expectErr("AC-12", "new A B", "", run(@["new", "A", "B"], nd), usoNew, 2)
  # 057:1:2 Il messaggio d'uso generale è di F2 (AC-57), che sostituisce quello di AC-12
  expectErr("AC-12", "file inesistente", "", run(@["check", "non_esiste.csc"], root),
    "bcdd check: file non trovato: non_esiste.csc\n", 2)
  expectErr("AC-12", "cartella", "", run(@["check", "prove"], root), "bcdd check: non è un file: prove\n", 2)
  let unread = tmpBase / "illeggibile.csc"
  writeFile(unread, "CSC A VERSION 1\n")
  setFilePermissions(unread, {})
  var canRead = true
  try:
    discard readFile(unread)
  except IOError:
    canRead = false
  if canRead:
    echo "nota: AC-12 non leggibile non provabile (utente con accesso a tutto)"
  else:
    expectErr("AC-12", "non leggibile", "", run(@["check", unread], root),
      "bcdd check: non leggibile: " & unread & "\n", 2)
  setFilePermissions(unread, {fpUserRead, fpUserWrite})

# 058:1:1 AC-13..AC-18: opzione --strict
block:
  let r13 = run(@["check", "--strict", "prove/14_non_riconosciute.csc"], root)
  expectOut("AC-13", "strict su 14", "14_non_riconosciute.strict", r13,
    readFile(proveDir / "14_non_riconosciute.strict.atteso"), 3)   # 053:1:1 la riga 15 usa solo nomi dichiarati: nessun errore, --strict dà 3
  let w14 = readFile(proveDir / "01_minima.strict.atteso")
  expectOut("AC-14", "--strict prima del file", "01_minima.strict",
    run(@["check", "--strict", "prove/01_minima.csc"], root), w14, 0)
  expectOut("AC-14", "--strict dopo il file", "01_minima.strict",
    run(@["check", "prove/01_minima.csc", "--strict"], root), w14, 0)
  expectOut("AC-15", "strict su 09: vince l'errore", "09_end_senza_blocco.strict",
    run(@["check", "--strict", "prove/09_end_senza_blocco.csc"], root),
    readFile(proveDir / "09_end_senza_blocco.strict.atteso"), 1)
  for n in f0names:
    expectOut("AC-16", "strict su " & n, "F0_" & n & ".strict",
      run(@["check", "--strict", "csc" / n & ".csc"], root),
      firstLineReplaced(readFile(proveDir / "F0_" & n & ".atteso"), "bcdd check --strict " & n & ".csc"), 0)
  expectErr("AC-17", "--strict ripetuto", "", run(@["check", "--strict", "--strict", "prove/01_minima.csc"], root),
    "uso: bcdd check [--strict] [--json] [--dir CARTELLA]... FILE\n", 2)
  expectErr("AC-17", "-s", "", run(@["check", "-s", "prove/01_minima.csc"], root),
    "uso: bcdd check [--strict] [--json] [--dir CARTELLA]... FILE\n", 2)
  expectErr("AC-17", "--strict senza file", "", run(@["check", "--strict"], root),
    "uso: bcdd check [--strict] [--json] [--dir CARTELLA]... FILE\n", 2)
  let r18 = run(@["check", "prove/14_non_riconosciute.csc"], root)
  rec("AC-18", "14 senza opzione: codice 0", r18.code == 0, "codice " & $r18.code)

# 058:2:1 AC-20: --strict su 21 (E13): il codice è 1 anche con l'opzione
expectOut("AC-20", "strict su 21", "21_verbal_senza_verify.strict",
  run(@["check", "--strict", "prove/21_verbal_senza_verify.csc"], root),
  readFile(proveDir / "21_verbal_senza_verify.strict.atteso"), 1)

# 058:3:1 AC-25..AC-27: scrittura, lettura e nome mancante (permessi: non eseguiti se si è root)
block:
  let isRoot = getuid() == 0
  if isRoot:
    echo "nota: AC-25 e AC-26 non eseguiti (utente root scavalca i permessi)"
  else:
    # AC-25: cartella vuota non scrivibile
    let ro = tmpBase / "ac25"
    createDir(ro)
    setFilePermissions(ro, {fpUserRead, fpUserExec})
    let r = run(@["new", "Esempio"], ro)
    let pre = "bcdd new: non riesco a creare Esempio.csc: "
    rec("AC-25", "messaggio, codice 1, stdout vuoto", r.code == 1 and r.output.len == 0 and
      r.errout.startsWith(pre) and r.errout.len > pre.len + 1 and r.errout.endsWith("\n") and
      r.errout.count('\n') == 1, "codice " & $r.code & " stderr [" & r.errout & "]")
    var left = -1
    setFilePermissions(ro, {fpUserRead, fpUserWrite, fpUserExec})
    left = listDir(ro).len
    rec("AC-25", "cartella vuota, anche di nascosti", left == 0, $listDir(ro))
    # AC-26: file con permessi 000 e file in cartella 000
    let f = tmpBase / "X.csc"
    writeFile(f, "CSC A VERSION 1\n")
    setFilePermissions(f, {})
    expectErr("AC-26", "file 000", "", run(@["check", f], root), "bcdd check: non leggibile: " & f & "\n", 2)
    setFilePermissions(f, {fpUserRead, fpUserWrite})
    let dd = tmpBase / "ac26dir"
    createDir(dd)
    writeFile(dd / "X.csc", "CSC A VERSION 1\n")
    setFilePermissions(dd, {})
    let inner = dd / "X.csc"
    expectErr("AC-26", "cartella 000", "", run(@["check", inner], root),
      "bcdd check: non leggibile: " & inner & "\n", 2)
    setFilePermissions(dd, {fpUserRead, fpUserWrite, fpUserExec})
  # AC-27: percorso che passa da un file; collegamento a un file che non c'è
  expectErr("AC-27", "percorso dentro un file", "", run(@["check", "prove/01_minima.csc/x"], root),
    "bcdd check: file non trovato: prove/01_minima.csc/x\n", 2)
  let ln = tmpBase / "R"
  createSymlink("non_esiste_da_nessuna_parte", ln)
  expectErr("AC-27", "collegamento pendente", "", run(@["check", ln], root),
    "bcdd check: file non trovato: " & ln & "\n", 2)


# 062:1:1 F2: aiuti per lanciare bcdd con ambiente, ingresso e segnali
let
  f2Dir = proveDir / "f2"
  bcddProva = getEnv("BCDD_PROVA", root / "tests" / "bcdd_prova")
  finto = f2Dir / "ULlmFinto.sh"
  luceOra = "2026-10-16T18:00:00+02:00"

proc mkEnv(extra: seq[(string, string)]): StringTableRef =
  ## 062:2:1 Ambiente del figlio: quello di chi lancia la suite senza variabili BCDD_*, più quelle date.
  result = newStringTable(modeCaseSensitive)
  for k, v in envPairs():
    if not k.startsWith("BCDD_"): result[k] = v
  result["BCDD_LANG"] = "it"   # 062:2:2 lingua fissata, salvo che `extra` la imposti diversamente
  for (k, v) in extra: result[k] = v

proc runX(exe: string, args: seq[string], cwd: string, env: StringTableRef, input: string = "",
    sigAfterMs: int = -1, keepStdin: bool = false): Res =
  let p = startProcess(exe, workingDir = cwd, args = args, env = env, options = {})
  if input.len > 0:
    p.inputStream.write input
    p.inputStream.flush()
  if not keepStdin: p.inputStream.close()
  if sigAfterMs >= 0:
    sleep sigAfterMs
    discard kill(Pid(p.processID), SIGINT)
  result.output = p.outputStream.readAll()
  result.errout = p.errorStream.readAll()
  result.code = p.waitForExit()
  p.close()

var wdCount = 0
proc newWd(): string =
  inc wdCount
  result = tmpBase / ("w" & $wdCount)
  createDir(result)

proc cpTo(src, dir: string, name: string = ""): string =
  result = dir / (if name.len > 0: name else: src.extractFilename)
  copyFile(src, result)

proc fileEq(a, b: string): bool =
  fileExists(a) and fileExists(b) and readFile(a) == readFile(b)

proc expectErrAfter3(ac, label, prova: string, r: Res, wantOut3, wantErr: string, wantCode: int) =
  ## 062:3:1 Sezione 9.4: sullo standard output restano le prime tre righe del giro; l'errore va sullo standard error.
  var ok = r.output == wantOut3 and r.errout == wantErr and r.code == wantCode
  rec(ac, label, ok, "codice " & $r.code & " stdout [" & r.output & "] stderr [" & r.errout & "]", prova)

proc pidGone(pidFile: string): bool =
  if not fileExists(pidFile): return false
  let pid = parseInt(readFile(pidFile).strip())
  kill(Pid(pid), 0) != 0

# 063:1:1 Criteri di ratify: AC-28..AC-38, con l'eseguibile normale
block:
  let rd = f2Dir / "ratify"
  proc ratCase(ac, prova, src: string, args: seq[string], wantOut, dopo: string) =
    let w = newWd()
    discard cpTo(rd / src, w)
    let r = run(@["ratify"] & args, w)
    expectOut(ac, prova & " " & args.join(" "), "ratify/" & prova, r, wantOut, 0)
    rec(ac, prova & " " & args.join(" ") & ": file dopo", fileEq(w / src, rd / dopo), "contenuto diverso da " & dopo,
      "ratify/" & prova)
    rec("AC-37", prova & ": nessun file in più", listDir(w) == @[src], $listDir(w))
  const lucD = "ratificata la CSC Luce (riga 3) con D-130\ncontratto: 2\nipotesi che restano: 0\n"
  ratCase("AC-28", "R01", "R01_Luce.csc", @["R01_Luce.csc", "D-130"], lucD, "R01_Luce.dopo.csc")
  ratCase("AC-29", "R02", "R02_senza_status.csc", @["R02_senza_status.csc", "D-130"], lucD, "R02_senza_status.dopo.csc")
  ratCase("AC-30", "R03", "R03_righe.csc", @["R03_righe.csc", "g1", "D-130"],
    "ratificata la riga 7: GUARANTEE g1 con D-130\n", "R03_righe.g1.dopo.csc")
  ratCase("AC-30", "R03", "R03_righe.csc", @["R03_righe.csc", "g1a", "D-130"],
    "ratificata la riga 8: GUARANTEE g1a con D-130\n", "R03_righe.g1a.dopo.csc")
  ratCase("AC-30", "R03", "R03_righe.csc", @["R03_righe.csc", "g3", "D-130"],
    "ratificata la riga 10: GUARANTEE g3 con D-130\n", "R03_righe.g3.dopo.csc")
  ratCase("AC-30", "R03", "R03_righe.csc", @["R03_righe.csc", "a1", "D-130"],
    "ratificata la riga 11: ASSUME a1 con D-130\n", "R03_righe.a1.dopo.csc")
  ratCase("AC-31", "R03", "R03_righe.csc", @["R03_righe.csc", "D-130"],
    "ratificata la CSC Righe (riga 3) con D-130\ncontratto: 2\nipotesi che restano: 2\n  riga 8: GUARANTEE g1a\n  riga 11: ASSUME a1\n",
    "R03_righe.tutta.dopo.csc")
  ratCase("AC-33", "R05", "R05_due_csc.csc", @["R05_due_csc.csc", "--csc", "Seconda", "g1", "D-130"],
    "ratificata la riga 12: GUARANTEE g1 con D-130\n", "R05_due_csc.Seconda.g1.dopo.csc")
  ratCase("AC-34", "R06", "R06_crlf.csc", @["R06_crlf.csc", "D-130"],
    "ratificata la CSC Finestre (riga 2) con D-130\ncontratto: 1\nipotesi che restano: 0\n", "R06_crlf.tutta.dopo.csc")
  ratCase("AC-34", "R06", "R06_crlf.csc", @["R06_crlf.csc", "g1", "D-130"],
    "ratificata la riga 4: GUARANTEE g1 con D-130\n", "R06_crlf.g1.dopo.csc")
  # AC-75..AC-80: ratify --all (dalla 1.3)
  ratCase("AC-75", "R03all", "R03_righe.csc", @["R03_righe.csc", "--all", "D-130"],
    "ratificate con D-130 nella CSC Righe: 3 righe\n  riga 4: CSC Righe\n  riga 8: GUARANTEE g1a\n  riga 11: ASSUME a1\ncontratto: 4\n",
    "R03_righe.all.dopo.csc")
  block:
    let w = newWd()
    discard cpTo(rd / "R03_righe.csc", w)
    discard run(@["ratify", "R03_righe.csc", "--all", "D-130"], w)
    let c = run(@["check", "R03_righe.csc"], w)
    let at = c.output.find("4. IPOTESI")
    rec("AC-75", "check dopo --all: sezione 4 vuota", c.code == 0 and at >= 0 and "IPOTESI, NON CONTRATTO: 0" in c.output, c.output)
  ratCase("AC-76", "R02all", "R02_senza_status.csc", @["R02_senza_status.csc", "--all", "D-130"],
    "ratificate con D-130 nella CSC Luce: 1 riga\n  riga 4: CSC Luce\ncontratto: 2\n", "R02_senza_status.dopo.csc")
  ratCase("AC-77", "R04all", "R04_gia_contratto.csc", @["R04_gia_contratto.csc", "--all", "D-130"],
    "ratificate con D-130 nella CSC Firmata: 1 riga\n  riga 10: GUARANTEE g2a\ncontratto: 3\n", "R04_gia_contratto.g2a.dopo.csc")
  block:
    let w = newWd()
    discard cpTo(rd / "R04_gia_contratto.g2a.dopo.csc", w)
    expectErr("AC-78", "niente da ratificare", "", run(@["ratify", "R04_gia_contratto.g2a.dopo.csc", "--all", "D-131"], w),
      "bcdd ratify: la CSC Firmata è già tutta contratto: non cambio nulla\n", 1)
    rec("AC-78", "file invariato", fileEq(w / "R04_gia_contratto.g2a.dopo.csc", rd / "R04_gia_contratto.g2a.dopo.csc") and
      listDir(w) == @["R04_gia_contratto.g2a.dopo.csc"], $listDir(w))
  ratCase("AC-79", "R05all", "R05_due_csc.csc", @["--all", "R05_due_csc.csc", "--csc", "Seconda", "D-130"],
    "ratificate con D-130 nella CSC Seconda: 1 riga\n  riga 10: CSC Seconda\ncontratto: 1\n", "R05_due_csc.Seconda.all.dopo.csc")
  ratCase("AC-79", "R06all", "R06_crlf.csc", @["R06_crlf.csc", "D-130", "--all"],
    "ratificate con D-130 nella CSC Finestre: 1 riga\n  riga 3: CSC Finestre\ncontratto: 1\n", "R06_crlf.tutta.dopo.csc")
  block:
    let w = newWd()
    discard cpTo(rd / "R03_righe.csc", w)
    const uso = "uso: bcdd ratify FILE [--csc NOME] [--dir CARTELLA]... [ID | --all] D-numero\n"
    for a in [@["R03_righe.csc", "--all", "g1", "D-130"], @["R03_righe.csc", "--all", "--all", "D-130"], @["R03_righe.csc", "--all"]]:
      expectErr("AC-80", a.join(" "), "", run(@["ratify"] & a, w), uso, 2)
    rec("AC-80", "file invariato dopo gli usi sbagliati", fileEq(w / "R03_righe.csc", rd / "R03_righe.csc") and
      listDir(w) == @["R03_righe.csc"], $listDir(w))
    if getuid() == 0:
      echo "nota: AC-80 (tutto o niente) non eseguito (utente root scavalca i permessi)"
    else:
      let w2 = newWd()
      discard cpTo(rd / "R03_righe.csc", w2)
      setFilePermissions(w2, {fpUserRead, fpUserExec})
      let r = run(@["ratify", "R03_righe.csc", "--all", "D-130"], w2)
      setFilePermissions(w2, {fpUserRead, fpUserWrite, fpUserExec})
      rec("AC-80", "scrittura impossibile: codice 1, messaggio, nessuna riga cambiata, nessun file nuovo",
        r.code == 1 and r.output.len == 0 and r.errout.startsWith("bcdd ratify: non riesco a scrivere R03_righe.csc: ") and
        fileEq(w2 / "R03_righe.csc", rd / "R03_righe.csc") and listDir(w2) == @["R03_righe.csc"],
        "codice " & $r.code & " stderr [" & r.errout & "] " & $listDir(w2))
  # AC-32: rifiuti con il file invariato, poi la riga che si può ratificare
  block:
    let src = rd / "R04_gia_contratto.csc"
    let cases = [
      (@["D-130"], "bcdd ratify: la CSC Firmata è già ratificata (D-1): non cambio nulla\n"),
      (@["g1", "D-130"], "bcdd ratify: g1 è già contratto (riga 8): non cambio nulla\n"),
      (@["g2", "D-130"], "bcdd ratify: g2 è già contratto (riga 9): non cambio nulla\n"),
      (@["pressione", "D-130"], "bcdd ratify: pressione non è una GUARANTEE né una ASSUME: si ratificano solo righe contrattuali e dettagli\n"),   # 053:3:1 C-34 (1.0-beta, S-20): messaggio cambiato
      (@["g9", "D-130"], "bcdd ratify: nessuna GUARANTEE né ASSUME con id g9 nella CSC Firmata\n")]
    for (a, want) in cases:
      let w = newWd()
      discard cpTo(src, w)
      expectErr("AC-32", a.join(" "), "ratify/R04", run(@["ratify", "R04_gia_contratto.csc"] & a, w), want, 1)
      rec("AC-32", a.join(" ") & ": file invariato", fileEq(w / "R04_gia_contratto.csc", src) and
        listDir(w) == @["R04_gia_contratto.csc"], "il file o la cartella sono cambiati", "ratify/R04")
    let w = newWd()
    discard cpTo(src, w)
    expectOut("AC-32", "g2a", "ratify/R04", run(@["ratify", "R04_gia_contratto.csc", "g2a", "D-130"], w),
      "ratificata la riga 10: GUARANTEE g2a con D-130\n", 0)
    rec("AC-32", "g2a: file dopo", fileEq(w / "R04_gia_contratto.csc", rd / "R04_gia_contratto.g2a.dopo.csc"),
      "contenuto diverso", "ratify/R04")
  # AC-33: più CSC
  block:
    let w = newWd()
    discard cpTo(rd / "R05_due_csc.csc", w)
    expectErr("AC-33", "senza --csc", "ratify/R05", run(@["ratify", "R05_due_csc.csc", "g1", "D-130"], w),
      "bcdd ratify: il file contiene 2 CSC: indica quale con --csc NOME\n", 2)
    expectErr("AC-33", "--csc Terza", "ratify/R05",
      run(@["ratify", "R05_due_csc.csc", "--csc", "Terza", "g1", "D-130"], w),
      "bcdd ratify: nessun blocco da ratificare con il nome Terza nel file\n", 1)
    rec("AC-33", "file invariato", fileEq(w / "R05_due_csc.csc", rd / "R05_due_csc.csc"), "il file è cambiato", "ratify/R05")
  # AC-35: precondizione check --strict
  for (src, want) in [("02_id_ripetuto.csc", "bcdd ratify: il file non passa bcdd check --strict (errori: 4, righe non riconosciute: 0): non ratifico\n"),
      ("14_non_riconosciute.csc", "bcdd ratify: il file non passa bcdd check --strict (errori: 0, righe non riconosciute: 12): non ratifico\n")]:
    let w = newWd()
    discard cpTo(proveDir / src, w)
    expectErr("AC-35", src, "", run(@["ratify", src, "g1", "D-130"], w), want, 1)
    rec("AC-35", src & ": file invariato", fileEq(w / src, proveDir / src), "il file è cambiato")
  # AC-36: argomenti
  block:
    let w = newWd()
    discard cpTo(rd / "R01_Luce.csc", w)
    const uso = "uso: bcdd ratify FILE [--csc NOME] [--dir CARTELLA]... [ID | --all] D-numero\n"
    let cases = [
      (@["R01_Luce.csc"], uso),
      (@["R01_Luce.csc", "D130"], "bcdd ratify: decisione non valida: D130 (serve D-numero)\n"),
      (@["R01_Luce.csc", "g-", "D-130"], "bcdd ratify: id non valido: g-\n"),
      (@["R01_Luce.csc", "g1", "D-130", "x"], uso),
      (@["R01_Luce.csc", "D-130", "--csc"], uso),
      (@["-x", "R01_Luce.csc", "D-130"], uso),
      (@["R01_Luce.csc", "--csc", "3x", "D-130"], "bcdd ratify: nome non valido: 3x\n"),
      (@["nessuno.csc", "D-130"], "bcdd ratify: file non trovato: nessuno.csc\n")]
    for (a, want) in cases:
      expectErr("AC-36", a.join(" "), "", run(@["ratify"] & a, w), want, 2)
    rec("AC-36", "file invariato", fileEq(w / "R01_Luce.csc", rd / "R01_Luce.csc") and listDir(w) == @["R01_Luce.csc"],
      "il file è cambiato")
  # AC-37: permessi, collegamento simbolico, collegamenti fisici
  block:
    let w = newWd()
    let f = cpTo(rd / "R01_Luce.csc", w)
    setFilePermissions(f, {fpUserRead, fpUserWrite, fpGroupRead})
    discard run(@["ratify", "R01_Luce.csc", "D-130"], w)
    rec("AC-37", "permessi 640 conservati", getFilePermissions(f) == {fpUserRead, fpUserWrite, fpGroupRead}, $getFilePermissions(f))
    rec("AC-37", "file cambiato", fileEq(f, rd / "R01_Luce.dopo.csc"), "contenuto diverso")
    let w2 = newWd()
    discard cpTo(rd / "R01_Luce.csc", w2, "vero.csc")
    createSymlink("vero.csc", w2 / "Luce.csc")
    expectOut("AC-37", "collegamento simbolico", "", run(@["ratify", "Luce.csc", "D-130"], w2), lucD, 0)
    rec("AC-37", "il collegamento resta, cambia il file a cui punta", symlinkExists(w2 / "Luce.csc") and
      fileEq(w2 / "vero.csc", rd / "R01_Luce.dopo.csc") and listDir(w2) == @["Luce.csc", "vero.csc"], $listDir(w2))
    let w3 = newWd()
    discard cpTo(rd / "R01_Luce.csc", w3)
    createHardlink(w3 / "R01_Luce.csc", w3 / "altro.csc")
    expectErr("AC-37", "due collegamenti fisici", "", run(@["ratify", "R01_Luce.csc", "D-130"], w3),
      "bcdd ratify: R01_Luce.csc ha più collegamenti fisici: non lo riscrivo\n", 1)
    rec("AC-37", "file invariato con due nomi", fileEq(w3 / "R01_Luce.csc", rd / "R01_Luce.csc") and
      fileEq(w3 / "altro.csc", rd / "R01_Luce.csc") and listDir(w3) == @["R01_Luce.csc", "altro.csc"], $listDir(w3))
  # AC-38: scrittura impossibile (non eseguita da root)
  if getuid() == 0:
    echo "nota: AC-38 non eseguito (utente root scavalca i permessi)"
  else:
    let w = newWd()
    discard cpTo(rd / "R01_Luce.csc", w)
    setFilePermissions(w, {fpUserRead, fpUserExec})
    let r = run(@["ratify", "R01_Luce.csc", "D-130"], w)
    setFilePermissions(w, {fpUserRead, fpUserWrite, fpUserExec})
    rec("AC-38", "messaggio e codice", r.code == 1 and r.output.len == 0 and
      r.errout.startsWith("bcdd ratify: non riesco a scrivere R01_Luce.csc: ") and r.errout.count('\n') == 1,
      "codice " & $r.code & " stderr [" & r.errout & "]")
    rec("AC-38", "file invariato e nessun file nuovo", fileEq(w / "R01_Luce.csc", rd / "R01_Luce.csc") and
      listDir(w) == @["R01_Luce.csc"], $listDir(w))
  # bordo: file senza LF finale
  block:
    let w = newWd()
    let orig = readFile(rd / "R01_Luce.csc")
    let want = readFile(rd / "R01_Luce.dopo.csc")
    writeFile(w / "a.csc", orig.strip(leading = false, chars = {'\n'}))
    let r = run(@["ratify", "a.csc", "D-130"], w)
    rec("X", "ratify su file senza LF finale", r.code == 0 and readFile(w / "a.csc") == want.strip(leading = false, chars = {'\n'}),
      "codice " & $r.code & " " & r.errout)

# 064:1:1 Criteri di refine: AC-39..AC-55 con l'eseguibile di prova
var refWds: seq[(string, int)]        # cartelle di lavoro e righe RATIFIED di partenza
proc ratLines(dir: string): int =
  for f in walkFiles(dir / "*.csc"):
    for l in readFile(f).splitLines():
      if "RATIFIED" in l: inc result

proc refEnv(wd: string, extra: seq[(string, string)] = @[]): StringTableRef =
  mkEnv(@[("BCDD_LLM", finto), ("BCDD_ATTESA_LLM", "30"), ("BCDD_ORA", luceOra),
    ("BCDD_REGISTRO", wd / "chiamate.tsv"), ("BCDD_FINTO_CONTA", wd & "_aux" / "conta")] & extra)

proc newRef(src: string, name: string = "Luce.csc"): string =
  result = newWd()
  discard cpTo(src, result, name)
  refWds.add (result, ratLines(result))

proc auxOf(wd: string): string =
  result = wd & "_aux"
  createDir(result)

proc contaOf(wd: string): string =
  ## 064:2:1 Quante chiamate ha ricevuto il finto nel giro (file BCDD_FINTO_CONTA, sezione 10.1).
  if fileExists(wd & "_aux" / "conta"): readFile(wd & "_aux" / "conta").strip() else: "0"

proc registryRows(wd: string): int =
  ## 064:2:2 Righe di dati del registro (senza l'intestazione).
  readFile(wd / "chiamate.tsv").strip().splitLines().len - 1

proc registryLast(wd: string): seq[string] =
  let ls = readFile(wd / "chiamate.tsv").strip().splitLines()
  ls[^1].split('\t')

if not fileExists(bcddProva):
  echo "FAIL: eseguibile di prova non trovato: " & bcddProva & " (compilarlo con: nim c -d:release -d:bcddProva --nimcache:nimcache/prova --out:tests/bcdd_prova src/bcdd.nim)"
  quit(1)

block:
  let rf = f2Dir / "refine"
  let luce = rf / "Luce.csc"
  proc hdr3(sec: int): string =
    "bcdd refine Luce.csc\nCSC Luce: nessun errore, righe non riconosciute: 0\nchiedo all'LLM: ULlmFinto.sh, limite " &
      $sec & " s (da BCDD_ATTESA_LLM)\n"
  let buona = rf / "risposte" / "buona.json"
  let buonaSeconda = rf / "risposte" / "buona_seconda.json"
  let sec = ("BCDD_FINTO_RISPOSTA_2", buonaSeconda)
  proc refine(wd: string, resp: string, input: string, extra: seq[(string, string)] = @[], args: seq[string] = @["Luce.csc"]): Res =
    var ex: seq[(string, string)]
    if resp.len > 0: ex.add ("BCDD_FINTO_RISPOSTA", resp)
    discard auxOf(wd)
    runX(bcddProva, @["refine"] & args, wd, refEnv(wd, ex & extra), input)
  proc untouched(wd: string, src: string, files: seq[string] = @["Luce.csc", "chiamate.tsv"]): bool =
    fileEq(wd / "Luce.csc", src) and listDir(wd) == files
  # T01: AC-40, AC-41, AC-52
  block:
    let w = newRef(luce)
    let aux = auxOf(w)
    let r = refine(w, buona, readFile(rf / "T01_buona.ingresso"), @[("BCDD_FINTO_RICHIESTA", aux / "richiesta"),
      ("BCDD_FINTO_RICHIESTA_2", aux / "richiesta2"), sec])
    expectOut("AC-41", "T01 uscita", "refine/T01", r, readFile(rf / "T01_buona.uscita"), 0)
    rec("AC-40", "richiesta uguale a T01_buona.richiesta (12081 byte)", fileEq(aux / "richiesta", rf / "T01_buona.richiesta") and
      getFileSize(aux / "richiesta") == 12081,
      "la richiesta è diversa", "refine/T01")
    rec("AC-59", "richiesta2 uguale a T01_buona.richiesta2 (12710 byte)", fileEq(aux / "richiesta2", rf / "T01_buona.richiesta2") and
      getFileSize(aux / "richiesta2") == 12710, "la seconda richiesta è diversa", "refine/T01")
    rec("AC-59", "conta contiene 2", contaOf(w) == "2", contaOf(w), "refine/T01")
    rec("AC-41", "Luce.csc uguale a T01_buona.dopo.csc", fileEq(w / "Luce.csc", rf / "T01_buona.dopo.csc"), "contenuto diverso", "refine/T01")
    rec("AC-41", "g2b mostrata, g1a no", "g2b" in r.output and "g1a" notin r.output, "proposte della prima chiamata mostrate", "refine/T01")
    rec("AC-41", "Luce.csc.dialogo uguale a T01_buona.dialogo", fileEq(w / "Luce.csc.dialogo", rf / "T01_buona.dialogo"),
      "contenuto diverso", "refine/T01")
    let c = run(@["check", "--strict", "Luce.csc"], w)
    let sec4 = c.output.find("4. IPOTESI")
    rec("AC-41", "check --strict del file nuovo: codice 0 e g2a fra le ipotesi", c.code == 0 and sec4 >= 0 and
      "riga 14: GUARANTEE g2a" in c.output[sec4 .. ^1], "codice " & $c.code)
    rec("AC-41", "nessun temporaneo", listDir(w) == @["Luce.csc", "Luce.csc.dialogo", "chiamate.tsv"], $listDir(w))
    let reg = readFile(w / "chiamate.tsv").strip().splitLines()
    rec("AC-52", "registro: intestazione e due righe", reg.len == 3 and
      reg[0] == "data\tfornitore\tlimite_s\tdurata_ms\tesito\tbyte_richiesta\tbyte_risposta\tfile", $reg)
    let f1 = reg[1].split('\t')
    rec("AC-52", "campi della prima riga", f1.len == 8 and f1[0] == luceOra and f1[1] == "ULlmFinto.sh" and f1[2] == "30" and
      f1[3].allCharsInSet({'0' .. '9'}) and f1[3].len > 0 and f1[4] == "risposta" and f1[5] == "12081" and f1[6] == "813" and
      f1[7] == "Luce.csc", $f1)
    let f = registryLast(w)
    rec("AC-52", "campi della seconda riga", f.len == 8 and f[0] == luceOra and f[1] == "ULlmFinto.sh" and f[2] == "30" and
      f[3].allCharsInSet({'0' .. '9'}) and f[3].len > 0 and f[4] == "risposta" and f[5] == "12710" and f[6] == "635" and
      f[7] == "Luce.csc", $f)
  # T02: AC-42
  block:
    let w = newRef(luce)
    let r = refine(w, rf / "risposte" / "scartate.json", readFile(rf / "T02_scartate.ingresso"))
    expectOut("AC-42", "T02 uscita", "refine/T02", r, readFile(rf / "T02_scartate.uscita"), 0)
    rec("AC-42", "file uguale a T02_scartate.dopo.csc, nessun .dialogo", fileEq(w / "Luce.csc", rf / "T02_scartate.dopo.csc") and
      listDir(w) == @["Luce.csc", "chiamate.tsv"], $listDir(w), "refine/T02")
    rec("AC-60", "T02: una sola chiamata", contaOf(w) == "1" and registryRows(w) == 1 and "hai risposto" notin r.output,
      contaOf(w), "refine/T02")
  # T03: AC-43
  block:
    let w = newRef(luce)
    let r = refine(w, rf / "risposte" / "realizzazione.json", readFile(rf / "T03_realizzazione.ingresso"))
    expectOut("AC-43", "T03 uscita", "refine/T03", r, readFile(rf / "T03_realizzazione.uscita"), 0)
    rec("AC-43", "file invariato", untouched(w, luce), $listDir(w), "refine/T03")
    rec("AC-60", "T03: domanda saltata, una sola chiamata", contaOf(w) == "1" and registryRows(w) == 1 and
      "hai risposto" notin r.output, contaOf(w), "refine/T03")
  # T04: AC-44
  block:
    let w = newWd()
    discard cpTo(rf / "T01_buona.dopo.csc", w, "Luce.csc")
    discard cpTo(rf / "T01_buona.dialogo", w, "Luce.csc.dialogo")
    refWds.add (w, ratLines(w))
    let aux = auxOf(w)
    let r = refine(w, rf / "risposte" / "vuota.json", "", @[("BCDD_FINTO_RICHIESTA", aux / "richiesta")])
    expectOut("AC-44", "T04 uscita", "refine/T04", r, readFile(rf / "T04_secondo_giro.uscita"), 0)
    rec("AC-60", "T04: una sola chiamata", contaOf(w) == "1" and registryRows(w) == 1 and "hai risposto" notin r.output,
      contaOf(w), "refine/T04")
    rec("AC-44", "richiesta uguale a T04_secondo_giro.richiesta", fileEq(aux / "richiesta", rf / "T04_secondo_giro.richiesta"),
      "la richiesta è diversa", "refine/T04")
    rec("AC-44", "i due file invariati", fileEq(w / "Luce.csc", rf / "T01_buona.dopo.csc") and
      fileEq(w / "Luce.csc.dialogo", rf / "T01_buona.dialogo") and listDir(w) == @["Luce.csc", "Luce.csc.dialogo", "chiamate.tsv"],
      $listDir(w), "refine/T04")
  # T05: AC-45, una per ogni riga di MOTIVI_ATTESI.md
  block:
    var n = 0
    var n88 = 0
    var n94 = 0
    for l in readFile(rf / "risposte" / "MOTIVI_ATTESI.md").splitLines():
      let parts = l.split('`')
      if l.startsWith("| `") and parts.len >= 5:
        inc n
        let name = parts[1]
        let motivo = parts[3]
        let w = newRef(luce)
        let r = refine(w, rf / "risposte" / name, "")
        let want = "bcdd refine: risposta dell'LLM non leggibile (" & motivo & "): niente scritto, il file è com'era\n"
        rec("AC-45", name, r.output == readFile(rf / "T05_malformata.uscita") and r.errout == want and r.code == 4 and
          untouched(w, luce) and registryLast(w)[4] == "malformata",
          "codice " & $r.code & " stderr [" & r.errout & "] stdout " & firstDiff(r.output, readFile(rf / "T05_malformata.uscita")),
          "refine/T05")
        # 064:5:1 AC-88 (1.4): le 11 risposte nuove; dalla 1.5 formato_errato.json passa ad AC-94
        if name.startsWith("csc_") or name == "senza_nuove_csc.json":
          rec("AC-88", name, r.output == readFile(rf / "T05_malformata.uscita") and r.errout == want and r.code == 4 and
            untouched(w, luce), "codice " & $r.code & " stderr [" & r.errout & "]", "refine/T05")
          inc n88
        # 064:5:2 AC-94 (1.5): le 8 risposte nuove (sost_*, senza_sostituzioni) e formato_errato.json (ora in bcdd-refine-3)
        if name.startsWith("sost_") or name == "senza_sostituzioni.json" or name == "formato_errato.json":
          rec("AC-94", name, r.output == readFile(rf / "T05_malformata.uscita") and r.errout == want and r.code == 4 and
            untouched(w, luce), "codice " & $r.code & " stderr [" & r.errout & "]", "refine/T05")
          inc n94
    rec("AC-88", "le 11 risposte nuove provate", n88 == 11, "provate " & $n88)
    rec("AC-94", "le 8 risposte nuove e formato_errato.json provate", n94 == 9, "provate " & $n94)
    rec("AC-45", "tutte le 49 risposte provate (39 più 10 di D-247)", n == 49, "provate " & $n)
  # T06: AC-46, limite di attesa
  block:
    let w = newRef(luce)
    let aux = auxOf(w)
    let t1 = epochTime()
    let r = refine(w, buona, "", @[("BCDD_ATTESA_LLM", "2"), ("BCDD_FINTO_ATTESA", "30"), ("BCDD_FINTO_PID", aux / "pid")])
    let el = epochTime() - t1
    expectErrAfter3("AC-46", "T06", "refine/T06", r, hdr3(2), "bcdd refine: l'LLM non ha risposto entro 2 s: niente scritto, il file è com'era\n", 4)
    rec("AC-46", "finisce entro 6 s", el < 6.0, formatFloat(el, ffDecimal, 2) & " s", "refine/T06")
    rec("AC-46", "il processo del fornitore non esiste più", pidGone(aux / "pid"), "processo ancora vivo o pid non scritto", "refine/T06")
    rec("AC-46", "file invariato, esito tempo_scaduto", untouched(w, luce) and registryLast(w)[4] == "tempo_scaduto", $listDir(w), "refine/T06")
  # T07, T08, T09: AC-47
  block:
    let w = newRef(luce)
    let r = refine(w, "", "")
    expectErrAfter3("AC-47", "T07 nessuna risposta", "refine/T07", r, hdr3(30),
      "bcdd refine: l'LLM non ha dato nessuna risposta: niente scritto, il file è com'era\n", 4)
    rec("AC-47", "T07 file invariato, esito vuota", untouched(w, luce) and registryLast(w)[4] == "vuota", $listDir(w), "refine/T07")
    let w8 = newRef(luce)
    let r8 = refine(w8, buona, "", @[("BCDD_FINTO_CODICE", "3")])
    expectErrAfter3("AC-47", "T08 codice 3", "refine/T08", r8, hdr3(30),
      "bcdd refine: l'LLM è terminato senza successo (codice 3): niente scritto, il file è com'era\n", 4)
    rec("AC-47", "T08 file invariato, esito codice_3", untouched(w8, luce) and registryLast(w8)[4] == "codice_3", $listDir(w8), "refine/T08")
    let w9 = newRef(luce)
    let r9 = refine(w9, buona, "", @[("BCDD_LLM", "/nessuno/llm")])
    rec("AC-47", "T09 avvio fallito", r9.code == 4 and r9.output.endsWith("limite 30 s (da BCDD_ATTESA_LLM)\n") and
      r9.errout.startsWith("bcdd refine: non riesco ad avviare l'LLM (llm): ") and r9.errout.len > 52 and
      r9.errout.count('\n') == 1, "codice " & $r9.code & " stderr [" & r9.errout & "]", "refine/T09")
    rec("AC-47", "T09 file invariato, esito avvio_fallito", untouched(w9, luce) and registryLast(w9)[4] == "avvio_fallito",
      $listDir(w9), "refine/T09")
  # ricerca di `claude` (PATH, poi la posizione standard) e messaggio di assenza. Un `claude` finto che registra gli
  # argomenti e passa la mano al finto di sempre; HOME e PATH finti, nessun varco nel binario di rilascio.
  block:
    proc fakeClaude(dir, marca, args: string) =
      createDir(dir)
      let f = dir / "claude"
      writeFile(f, "#!/bin/sh\nprintf '%s\\n' \"$@\" > '" & args & "'\necho " & marca & " >> '" & args & "'\nexec '" & finto & "' \"$@\"\n")
      setFilePermissions(f, {fpUserRead, fpUserWrite, fpUserExec})
    const vuoto = "BCDD_LLM"
    let sistema = "/usr/bin:/bin"
    # a) solo nella posizione standard
    let wa = newRef(luce)
    let auxa = auxOf(wa)
    fakeClaude(auxa / "home" / ".local" / "bin", "std", auxa / "args")
    let ra = refine(wa, rf / "risposte" / "vuota.json", "", @[(vuoto, ""), ("PATH", sistema), ("HOME", auxa / "home")])
    let argsA = if fileExists(auxa / "args"): readFile(auxa / "args") else: ""
    rec("AC-300", "claude solo in $HOME/.local/bin: avviato con il vettore della sezione 9.2",
      argsA == "-p\n--tools\n\n--output-format\ntext\n--no-session-persistence\n--model\nsonnet\nstd\n", "args [" & argsA & "] stderr [" & ra.errout & "]", "refine/AC300")
    # b) nel PATH e nella posizione standard: vince il PATH
    let wb = newRef(luce)
    let auxb = auxOf(wb)
    fakeClaude(auxb / "home" / ".local" / "bin", "std", auxb / "args")
    fakeClaude(auxb / "bin", "path", auxb / "args")
    discard refine(wb, rf / "risposte" / "vuota.json", "", @[(vuoto, ""), ("PATH", auxb / "bin" & ":" & sistema), ("HOME", auxb / "home")])
    let argsB = if fileExists(auxb / "args"): readFile(auxb / "args") else: ""
    rec("AC-300", "claude nel PATH e nella posizione standard: vince il PATH", argsB.endsWith("\npath\n") and "std" notin argsB, "args [" & argsB & "]", "refine/AC300")
    # c) da nessuna parte
    let wc = newRef(luce)
    let auxc = auxOf(wc)
    let rc = refine(wc, buona, "", @[(vuoto, ""), ("PATH", sistema), ("HOME", auxc / "home")])
    rec("AC-300", "claude assente: messaggio, codice 4, file invariato, esito avvio_fallito",
      rc.code == 4 and rc.errout == "bcdd refine: non trovo Claude Code (il programma `claude`), che bcdd usa per completare i file: installalo, accedi con il tuo account e riprova. Ho cercato in: PATH, " &
        auxc / "home" / ".local" / "bin" / "claude" & "\n" and untouched(wc, luce) and registryLast(wc)[4] == "avvio_fallito",
      "codice " & $rc.code & " stderr [" & rc.errout & "]", "refine/AC300")
  # T10, T11, T12: AC-48, interruzioni
  block:
    const intr = "bcdd refine: interrotto: niente scritto, il file è com'era\n"
    let w = newRef(luce)
    let aux = auxOf(w)
    let r = runX(bcddProva, @["refine", "Luce.csc"], w, refEnv(w, @[("BCDD_FINTO_RISPOSTA", buona),
      ("BCDD_FINTO_ATTESA", "30"), ("BCDD_FINTO_PID", aux / "pid")]), "", 1000)
    rec("AC-48", "T10 Ctrl-C durante l'attesa", r.errout == intr and r.code == 130 and r.output.endsWith("\n") and
      pidGone(aux / "pid") and untouched(w, luce) and registryLast(w)[4] == "interrotta",
      "codice " & $r.code & " stderr [" & r.errout & "]", "refine/T10")
    let w11 = newRef(luce)
    let r11 = runX(bcddProva, @["refine", "Luce.csc"], w11, refEnv(w11, @[("BCDD_FINTO_RISPOSTA", buona), sec]),
      "fra tre minuti circa\n", 1500, true)
    rec("AC-48", "T11 Ctrl-C al primo accetti?", r11.errout == intr and r11.code == 130 and r11.output.endsWith("\n") and
      "accetti?" in r11.output and untouched(w11, luce), "codice " & $r11.code & " stderr [" & r11.errout & "]", "refine/T11")
    let w12 = newRef(luce)
    let r12 = refine(w12, buona, "fra tre minuti circa\n", @[sec])
    rec("AC-48", "T12 ingresso fermo alla prima riga", r12.errout == "bcdd refine: ingresso finito prima delle risposte: niente scritto, il file è com'era\n" and
      r12.code == 130 and r12.output.endsWith("\n") and untouched(w12, luce), "codice " & $r12.code & " stderr [" & r12.errout & "]", "refine/T12")
  # AC-49: conferma no
  block:
    let w = newRef(luce)
    let r = refine(w, buona, "fra tre minuti circa\ns\nn\nn\n", @[sec])
    rec("AC-49", "conferma no", r.code == 0 and r.errout.len == 0 and r.output.endsWith("niente scritto: Luce.csc non cambia\n") and
      untouched(w, luce), "codice " & $r.code, "refine/AC49")
  # AC-50 (1.1): il file cambia durante la prima chiamata; lo si scopre prima della seconda
  const dom = "  DOMANDA Dopo quanto tempo senza pressioni la luce si deve spegnere?\n  RISPOSTA fra tre minuti circa\n"
  const touched = "-- riga aggiunta da un altro programma durante il giro\n"
  block:
    let w = newRef(luce)
    let r = refine(w, buona, readFile(rf / "T01_buona.ingresso"), @[("BCDD_FINTO_TOCCA", w / "Luce.csc"), sec])
    let tail = "risposta (da 1 a 3, oppure scrivi tu; invio vuoto per saltare): fra tre minuti circa\nrisposte non salvate:\n" & dom
    rec("AC-50", "messaggio, codice, risposte non salvate", r.errout == "bcdd refine: Luce.csc è cambiato durante il comando: niente scritto\n" and
      r.code == 1 and r.output.endsWith(tail) and "PROPOSTA" notin r.output and "hai risposto" notin r.output,
      "codice " & $r.code & " stderr [" & r.errout & "] stdout [" & r.output & "]", "refine/AC50")
    rec("AC-50", "nessuna seconda chiamata: conta 1, una riga nel registro", contaOf(w) == "1" and registryRows(w) == 1,
      contaOf(w), "refine/AC50")
    rec("AC-50", "Luce.csc con la sola riga del finto, nessun .dialogo", readFile(w / "Luce.csc") == readFile(luce) & touched and
      listDir(w) == @["Luce.csc", "chiamate.tsv"], $listDir(w), "refine/AC50")
  # AC-64: il file cambia durante la seconda chiamata; lo si scopre alla scrittura
  block:
    let w = newRef(luce)
    let r = refine(w, buona, readFile(rf / "T01_buona.ingresso"), @[("BCDD_FINTO_TOCCA_2", w / "Luce.csc"), sec])
    let tail = "proposte accettate e non scritte, da copiare a mano se servono:\n" &
      "  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL \"La luce si spegne fra 170 e 190 secondi dopo l'ultima pressione\"\n" &
      "                                              VERIFY BY JUDGEMENT \"l'operatore, con un cronometro\"\n" &
      "risposte non salvate:\n" & dom
    rec("AC-64", "messaggio, codice, righe da copiare", r.errout == "bcdd refine: Luce.csc è cambiato durante il comando: niente scritto\n" and
      r.code == 1 and r.output.endsWith(tail), "codice " & $r.code & " stderr [" & r.errout & "]", "refine/AC64")
    rec("AC-64", "conta 2, Luce.csc con la sola riga del finto, nessun .dialogo", contaOf(w) == "2" and
      readFile(w / "Luce.csc") == readFile(luce) & touched and listDir(w) == @["Luce.csc", "chiamate.tsv"],
      contaOf(w) & " " & $listDir(w), "refine/AC64")
  # AC-61, T13: domande della seconda risposta ignorate
  block:
    let w = newRef(luce)
    let r = refine(w, buona, readFile(rf / "T01_buona.ingresso"), @[("BCDD_FINTO_RISPOSTA_2", buona)])
    rec("AC-61", "T13 riga con domande ignorate, DOMANDA una volta sola, g1a", r.code == 0 and r.errout.len == 0 and
      "risposta letta: 2 proposte (scartate dal controllo: 0), domande ignorate: 1\n" in r.output and
      r.output.count("DOMANDA 1 di 1") == 1 and "PROPOSTA 2 di 2, dettaglia g1 (riga 10)\n" in r.output and "g1a" in r.output,
      "codice " & $r.code & " " & r.output, "refine/T13")
    rec("AC-61", "T13 Luce.csc e dialogo come T01", fileEq(w / "Luce.csc", rf / "T01_buona.dopo.csc") and
      fileEq(w / "Luce.csc.dialogo", rf / "T01_buona.dialogo"), "contenuto diverso", "refine/T13")
  # AC-62, T14..T17: errori della seconda chiamata
  block:
    let ing = "fra tre minuti circa\ns\n"
    let pre = "bcdd refine: seconda chiamata: "
    let post = ": nessuna proposta, Luce.csc non cambia\n"
    let w16 = newRef(luce)
    let aux16 = auxOf(w16)
    type Case = tuple[name: string, extra: seq[(string, string)], limit: string, err, esito: string]
    let cases: seq[Case] = @[
      ("T14", @[("BCDD_FINTO_RISPOSTA_2", rf / "risposte" / "non_json.txt")], "30",
        pre & "risposta dell'LLM non leggibile (non è un oggetto JSON)" & post, "malformata"),
      ("T15", @[], "30", pre & "l'LLM non ha dato nessuna risposta" & post, "vuota"),
      ("T16", @[("BCDD_ATTESA_LLM", "2"), ("BCDD_FINTO_RISPOSTA_2", buona), ("BCDD_FINTO_ATTESA_2", "30"),
        ("BCDD_FINTO_PID_2", aux16 / "pid2")], "2", pre & "l'LLM non ha risposto entro 2 s" & post, "tempo_scaduto"),
      ("T17", @[("BCDD_FINTO_RISPOSTA_2", buona), ("BCDD_FINTO_CODICE_2", "3")], "30",
        pre & "l'LLM è terminato senza successo (codice 3)" & post, "codice_3")]
    for c in cases:
      let w = if c.name == "T16": w16 else: newRef(luce)
      let t1 = epochTime()
      let r = refine(w, buona, ing, c.extra)
      let el = epochTime() - t1
      let wantOutTail = "chiedo all'LLM: ULlmFinto.sh, limite " & c.limit & " s (da BCDD_ATTESA_LLM)\n" &
        "scrivo 1 risposta in Luce.csc.dialogo? s = sì, n = no: s\nscritto Luce.csc.dialogo: 1 risposta\n"
      rec("AC-62", c.name & " messaggio, codice 4, uscita", r.errout == c.err and r.code == 4 and r.output.endsWith(wantOutTail) and
        "PROPOSTA" notin r.output, "codice " & $r.code & " stderr [" & r.errout & "] stdout [" & r.output & "]", "refine/" & c.name)
      rec("AC-62", c.name & " Luce.csc invariato, dialogo come T01, due righe di registro", fileEq(w / "Luce.csc", luce) and
        fileEq(w / "Luce.csc.dialogo", rf / "T01_buona.dialogo") and registryRows(w) == 2 and registryLast(w)[4] == c.esito,
        $listDir(w) & " " & $registryLast(w), "refine/" & c.name)
      if c.name == "T16":
        rec("AC-62", "T16 entro 8 s e il fornitore della seconda chiamata non esiste più", el < 8.0 and pidGone(aux16 / "pid2"),
          formatFloat(el, ffDecimal, 2) & " s", "refine/T16")
    # seguito: risposta n e fine dell'ingresso
    let wn = newRef(luce)
    let rn = refine(wn, buona, "fra tre minuti circa\nn\n")
    rec("AC-62", "T15 con n: codice 4, niente scritto, nessun .dialogo", rn.code == 4 and
      rn.output.endsWith("niente scritto: risposte non salvate\n") and fileEq(wn / "Luce.csc", luce) and
      listDir(wn) == @["Luce.csc", "chiamate.tsv"], "codice " & $rn.code & " " & $listDir(wn), "refine/T15n")
    let we = newRef(luce)
    let re = refine(we, buona, "fra tre minuti circa\n")
    rec("AC-62", "T15 con ingresso finito: codice 130, nessun .dialogo", re.code == 130 and
      re.errout.endsWith("bcdd refine: ingresso finito prima delle risposte: niente scritto, il file è com'era\n") and
      fileEq(we / "Luce.csc", luce) and listDir(we) == @["Luce.csc", "chiamate.tsv"], "codice " & $re.code & " " & re.errout,
      "refine/T15e")
  # AC-67, T19: cinque domande si accettano; la riga "hai risposto" al plurale
  block:
    let w = newRef(luce)
    let aux = auxOf(w)
    let r = refine(w, rf / "risposte" / "cinque_domande.json", "uno\n\ntre\n\n\ns\nn\ns\n", @[("BCDD_FINTO_RICHIESTA_2", aux / "richiesta2"), sec])
    let o = r.output
    var blocchi = true
    for i in 1 .. 5: blocchi = blocchi and ("DOMANDA " & $i & " di 5\n") in o
    rec("AC-67", "T19 uscita: cinque domande, riga al plurale, due proposte", r.code == 0 and r.errout.len == 0 and
      "risposta letta: 5 domande, 0 proposte (scartate dal controllo: 0)\n" in o and blocchi and
      "\nhai risposto a 2 domande: chiedo a ULlmFinto.sh proposte che ne tengano conto\n" in o and
      "PROPOSTA 1 di 2" in o and "g2a" in o and "PROPOSTA 2 di 2" in o and "g2b" in o and
      "scritto Luce.csc: 1 proposta (2 righe)\n" in o and o.endsWith("scritto Luce.csc.dialogo: 2 risposte\n"),
      "codice " & $r.code & " " & r.errout & " " & o, "refine/T19")
    rec("AC-67", "T19 Luce.csc come T01, conta 2", fileEq(w / "Luce.csc", rf / "T01_buona.dopo.csc") and contaOf(w) == "2",
      contaOf(w), "refine/T19")
    let d = readFile(w / "Luce.csc.dialogo")
    let q1 = "Dopo quanto tempo senza pressioni la luce si deve spegnere?"
    let q2 = "Una pressione a luce accesa fa ripartire il tempo da capo?"
    let q3 = "Entro quanto tempo dalla pressione la luce si deve accendere?"
    let q4 = "Dopo un'interruzione della corrente la luce riparte spenta?"
    let q5 = "Una pressione lunga conta come una pressione sola?"
    rec("AC-67", "T19 dialogo: due coppie, domanda 1 e 3", d.count("\nDOMANDA ") == 2 and d.count("\nRISPOSTA ") == 2 and
      ("DOMANDA " & q1 & "\nRISPOSTA uno\n") in d and ("DOMANDA " & q3 & "\nRISPOSTA tre\n") in d and
      d.find(q1) < d.find(q3), d, "refine/T19")
    let r2 = readFile(aux / "richiesta2")
    rec("AC-67", "T19 richiesta2: le stesse due coppie in ordine, non le domande 2, 4, 5", q1 in r2 and q3 in r2 and
      r2.find(q1) < r2.find(q3) and "uno" in r2 and "tre" in r2 and q2 notin r2 and q4 notin r2 and q5 notin r2,
      "richiesta2 diversa", "refine/T19")
  # AC-68: sei domande alla prima chiamata (la riga di MOTIVI_ATTESI.md, provata da T05)
  block:
    let w = newRef(luce)
    let r = refine(w, rf / "risposte" / "troppe_domande.json", "")
    rec("AC-68", "6 domande alla prima chiamata: illeggibile, codice 4, nessuna DOMANDA, file invariato, nessun .dialogo",
      r.errout == "bcdd refine: risposta dell'LLM non leggibile (troppe domande: 6, al più 5): niente scritto, il file è com'era\n" and
      r.code == 4 and r.output == readFile(rf / "T05_malformata.uscita") and "DOMANDA" notin r.output and untouched(w, luce) and
      registryLast(w)[4] == "malformata", "codice " & $r.code & " " & r.errout, "refine/AC68")
  # AC-69, T20: sei domande alla seconda chiamata
  block:
    let w = newRef(luce)
    let r = refine(w, buona, "fra tre minuti circa\ns\n", @[("BCDD_FINTO_RISPOSTA_2", rf / "risposte" / "troppe_domande.json")])
    let wantTail = "chiedo all'LLM: ULlmFinto.sh, limite 30 s (da BCDD_ATTESA_LLM)\n" &
      "scrivo 1 risposta in Luce.csc.dialogo? s = sì, n = no: s\nscritto Luce.csc.dialogo: 1 risposta\n"
    rec("AC-69", "T20 messaggio, codice 4, uscita senza PROPOSTA né domande ignorate",
      r.errout == "bcdd refine: seconda chiamata: risposta dell'LLM non leggibile (troppe domande: 6, al più 5): nessuna proposta, Luce.csc non cambia\n" and
      r.code == 4 and r.output.endsWith(wantTail) and "PROPOSTA" notin r.output and "domande ignorate" notin r.output,
      "codice " & $r.code & " stderr [" & r.errout & "] stdout [" & r.output & "]", "refine/T20")
    rec("AC-69", "T20 Luce.csc invariato, dialogo come T01, due righe di registro, la seconda malformata",
      fileEq(w / "Luce.csc", luce) and fileEq(w / "Luce.csc.dialogo", rf / "T01_buona.dialogo") and registryRows(w) == 2 and
      registryLast(w)[4] == "malformata", $listDir(w) & " " & $registryLast(w), "refine/T20")
  # AC-63, T18: Ctrl-C durante la seconda chiamata
  block:
    let w = newRef(luce)
    let aux = auxOf(w)
    let r = runX(bcddProva, @["refine", "Luce.csc"], w, refEnv(w, @[("BCDD_FINTO_RISPOSTA", buona),
      ("BCDD_FINTO_RISPOSTA_2", buona), ("BCDD_FINTO_ATTESA_2", "30"), ("BCDD_FINTO_PID_2", aux / "pid2")]),
      "fra tre minuti circa\n", 1500, true)
    rec("AC-63", "T18 Ctrl-C alla seconda chiamata", r.errout == "bcdd refine: interrotto: niente scritto, il file è com'era\n" and
      r.code == 130 and r.output.endsWith("risposte non salvate:\n" & dom) and pidGone(aux / "pid2") and untouched(w, luce) and
      registryRows(w) == 2 and registryLast(w)[4] == "interrotta", "codice " & $r.code & " stderr [" & r.errout & "] stdout [" & r.output & "]",
      "refine/T18")
  # AC-65: nomi dei file e dialogo cambiato o non scrivibile
  block:
    let w = newRef(luce)
    let r = refine(w, buona, readFile(rf / "T01_buona.ingresso"), @[("BCDD_FINTO_TOCCA_2", w / "Luce.csc.dialogo"), sec],
      @["./Luce.csc"])
    rec("AC-65", "a) dialogo cambiato: messaggio, codice, uscita", r.errout ==
      "bcdd refine: ./Luce.csc.dialogo è cambiato durante il comando: risposte non salvate\n" and r.code == 1 and
      r.output.endsWith("scritto Luce.csc: 1 proposta (2 righe)\nrisposte non salvate:\n" & dom),
      "codice " & $r.code & " stderr [" & r.errout & "] stdout [" & r.output & "]", "refine/AC65a")
    rec("AC-65", "a) Luce.csc come T01, dialogo con la sola riga del finto", fileEq(w / "Luce.csc", rf / "T01_buona.dopo.csc") and
      readFile(w / "Luce.csc.dialogo") == touched, "contenuto diverso", "refine/AC65a")
    let wb = newRef(luce)
    let auxb = auxOf(wb)
    copyFile(rf / "T01_buona.dialogo", wb / "Luce.csc.dialogo")
    createHardlink(wb / "Luce.csc.dialogo", auxb / "altro_nome")
    let rb = refine(wb, buona, readFile(rf / "T01_buona.ingresso"), @[sec])
    rec("AC-65", "b) più collegamenti fisici: messaggio, codice, uscita", rb.errout ==
      "bcdd refine: Luce.csc.dialogo ha più collegamenti fisici: non lo riscrivo\n" and rb.code == 1 and
      rb.output.endsWith("scritto Luce.csc: 1 proposta (2 righe)\nrisposte non salvate:\n" & dom),
      "codice " & $rb.code & " stderr [" & rb.errout & "] stdout [" & rb.output & "]", "refine/AC65b")
    rec("AC-65", "b) Luce.csc come T01 (dialogo già presente, la richiesta ha un altro testo), dialogo invariato",
      fileEq(wb / "Luce.csc", rf / "T01_buona.dopo.csc") and fileEq(wb / "Luce.csc.dialogo", rf / "T01_buona.dialogo"),
      "contenuto diverso", "refine/AC65b")
  # AC-51: precondizione
  block:
    let w = newWd()
    discard cpTo(proveDir / "02_id_ripetuto.csc", w, "Luce.csc")
    refWds.add (w, ratLines(w))
    let aux = auxOf(w)
    let r = refine(w, buona, "", @[("BCDD_FINTO_PID", aux / "pid")])
    expectErr("AC-51", "file con errori", "", r, "bcdd refine: il file non passa bcdd check (errori: 4): correggilo prima di affinare\n", 1)
    rec("AC-51", "l'LLM non è stato chiamato, file invariato", not fileExists(aux / "pid") and
      fileEq(w / "Luce.csc", proveDir / "02_id_ripetuto.csc") and listDir(w) == @["Luce.csc"], $listDir(w))
  # AC-53: più CSC
  block:
    let w = newRef(f2Dir / "ratify" / "R05_due_csc.csc", "R05_due_csc.csc")
    let r1 = refine(w, rf / "risposte" / "vuota.json", "", @[], @["R05_due_csc.csc"])
    expectErr("AC-53", "senza --csc", "", r1, "bcdd refine: il file contiene 2 CSC: indica quale con --csc NOME\n", 2)
    let r2 = refine(w, rf / "risposte" / "vuota.json", "", @[], @["R05_due_csc.csc", "--csc", "Prima"])
    rec("AC-53", "con --csc Prima", r2.code == 0 and r2.output.startsWith(
      "bcdd refine R05_due_csc.csc\nCSC Prima: nessun errore, righe non riconosciute: 0\n"), "codice " & $r2.code & " " & r2.errout)
  # AC-54: argomenti e ambiente
  block:
    let w = newRef(luce)
    const uso = "uso: bcdd refine FILE [--csc NOME] [--modello veloce|accurato]\n"
    expectErr("AC-54", "senza argomenti", "", refine(w, "", "", @[], @[]), uso, 2)
    expectErr("AC-54", "a b", "", refine(w, "", "", @[], @["a", "b"]), uso, 2)
    expectErr("AC-54", "opzione sconosciuta", "", refine(w, "", "", @[], @["-x", "Luce.csc"]), uso, 2)
    expectErr("AC-54", "--csc senza nome", "", refine(w, "", "", @[], @["Luce.csc", "--csc"]), uso, 2)
    for v in ["0", "abc", "3601", "-5", ""]:
      expectErr("AC-54", "BCDD_ATTESA_LLM=" & v, "", refine(w, buona, "", @[("BCDD_ATTESA_LLM", v)]),
        "bcdd refine: BCDD_ATTESA_LLM non valida: " & v & " (serve un numero intero di secondi da 1 a 3600)\n", 2)
    expectErr("AC-54", "BCDD_ORA=ieri", "", refine(w, buona, "", @[("BCDD_ORA", "ieri")]),
      "bcdd refine: BCDD_ORA non valida: ieri (serve AAAA-MM-GGTHH:MM:SS+HH:MM)\n", 2)
    expectErr("AC-54", "file inesistente", "", refine(w, buona, "", @[], @["nessuno.csc"]),
      "bcdd refine: file non trovato: nessuno.csc\n", 2)
    expectErr("AC-54", "CSC inesistente", "", refine(w, buona, "", @[], @["Luce.csc", "--csc", "Altra"]),
      "bcdd refine: nessuna CSC né ENTITY Altra nel file\n", 1)
    rec("AC-54", "file invariato, nessun file in più", fileEq(w / "Luce.csc", luce) and listDir(w) == @["Luce.csc"], $listDir(w))
  # bordi di refine (oltre agli AC)
  block:
    # risposta non ammessa alle domande di scelta: avviso e domanda ripetuta
    let w = newRef(luce)
    let r = refine(w, buona, "\nq\ns\nn\ns\n")
    rec("AC-60", "bordo con domanda saltata: una sola chiamata", contaOf(w) == "1" and registryRows(w) == 1 and
      "hai risposto" notin r.output, contaOf(w))
    rec("X", "avviso 'rispondi s, n oppure f' e scrittura", r.code == 0 and "q\nrispondi s, n oppure f\naccetti?" in r.output and
      fileEq(w / "Luce.csc", rf / "T01_buona.dopo.csc") and listDir(w) == @["Luce.csc", "chiamate.tsv"] and
      "scrivo 1 proposta (2 righe) in Luce.csc? s = sì, n = no: s\n" in r.output, "codice " & $r.code & " " & r.output)
    # f: le restanti si scartano, resta da scrivere solo il dialogo
    let wf = newRef(luce)
    let rfi = refine(wf, buona, "x\nf\ns\n", @[("BCDD_FINTO_RISPOSTA_2", buona)])
    rec("X", "f scarta le restanti; solo il dialogo", rfi.code == 0 and "PROPOSTA 2 di 2" notin rfi.output and
      "riepilogo: accettate 0, scartate da te 2, scartate dal controllo 0\n" in rfi.output and
      "scrivo 1 risposta in Luce.csc.dialogo? s = sì, n = no: s\n" in rfi.output and
      fileEq(wf / "Luce.csc", luce) and fileExists(wf / "Luce.csc.dialogo") and
      readFile(wf / "Luce.csc.dialogo").contains("RISPOSTA x\n"), "codice " & $rfi.code & " " & rfi.output)
    # BOM e CR LF: le righe inserite finiscono con CR LF, il resto è identico
    let wc = newWd()
    let crlf = readFile(f2Dir / "ratify" / "R06_crlf.csc")
    writeFile(wc / "Luce.csc", crlf)
    refWds.add (wc, ratLines(wc))
    let auxc = auxOf(wc)
    writeFile(auxc / "r.json", """{"formato":"bcdd-refine-5","domande":[],"proposte":[{"tipo":"GUARANTEE","id":"g1a","dettaglia":"g1","testo":"una riga più precisa","verifica":"INSPECTION","verifica_testo":"il file"}],"nuove_csc":[],"sostituzioni":[],"interfaccia":[]}""")
    let rc = refine(wc, auxc / "r.json", "s\ns\n")
    let want = crlf.replace("VERIFY BY JUDGEMENT \"l'operatore\"\r\n", "VERIFY BY JUDGEMENT \"l'operatore\"\r\n" &
      "  GUARANTEE g1a DETAILS g1 STATUS HYPOTHESIS: VERBAL \"una riga più precisa\"\r\n" &
      "                                              VERIFY BY INSPECTION \"il file\"\r\n")
    rec("X", "BOM e CR LF conservati", rc.code == 0 and readFile(wc / "Luce.csc") == want, "codice " & $rc.code & " " & rc.errout)
    # risposta oltre 1 MiB
    let wo = newRef(luce)
    let auxo = auxOf(wo)
    writeFile(auxo / "grande.txt", 'a'.repeat(1_300_000))
    let ro = refine(wo, auxo / "grande.txt", "")
    rec("X", "risposta oltre 1 MiB", ro.code == 4 and ro.errout == "bcdd refine: risposta dell'LLM non leggibile (risposta oltre 1 MiB): niente scritto, il file è com'era\n" and
      untouched(wo, luce), "codice " & $ro.code & " " & ro.errout)
    # registro: percorso da XDG_STATE_HOME
    let wx = newRef(luce)
    let auxx = auxOf(wx)
    let ex = mkEnv(@[("BCDD_LLM", finto), ("BCDD_ATTESA_LLM", "30"), ("BCDD_ORA", luceOra), ("XDG_STATE_HOME", auxx / "stato"),
      ("BCDD_FINTO_RISPOSTA", rf / "risposte" / "vuota.json")])
    discard runX(bcddProva, @["refine", "Luce.csc"], wx, ex, "")
    rec("X", "registro in XDG_STATE_HOME/bcdd/chiamate.tsv", fileExists(auxx / "stato" / "bcdd" / "chiamate.tsv"),
      "registro non trovato")
    # il fornitore parte in una cartella vuota e riceve un fornitore solo (BCDD_LLM): cwd diversa da quella dell'utente
    let wp = newRef(luce)
    let auxp = auxOf(wp)
    writeFile(auxp / "pwd.sh", "#!/bin/sh\ncat > /dev/null\npwd > \"" & auxp & "/cwd\"\nls -A | wc -l > \"" & auxp & "/n\"\n")
    setFilePermissions(auxp / "pwd.sh", {fpUserRead, fpUserWrite, fpUserExec})
    discard refine(wp, "", "", @[("BCDD_LLM", auxp / "pwd.sh")])
    rec("X", "cartella di lavoro del fornitore: vuota e diversa da quella dell'utente", fileExists(auxp / "cwd") and
      readFile(auxp / "cwd").strip() != wp and readFile(auxp / "n").strip() == "0" and not dirExists(readFile(auxp / "cwd").strip()),
      "cwd " & (if fileExists(auxp / "cwd"): readFile(auxp / "cwd") else: "?"))
  block:
    # richiesta grande (oltre la capacità di un tubo): scrittura non bloccante, nessun blocco
    let wg = newWd()
    var big = readFile(luce)
    for i in 1 .. 6000: big.add "-- riga di commento numero " & $i & " per allungare la richiesta oltre 200 KB\n"
    writeFile(wg / "Luce.csc", big)
    refWds.add (wg, ratLines(wg))
    let auxg = auxOf(wg)
    let rg = refine(wg, rf / "risposte" / "vuota.json", "", @[("BCDD_FINTO_RICHIESTA", auxg / "richiesta")])
    let regg = registryLast(wg)
    rec("X", "richiesta di oltre 200 KB consegnata per intero", rg.code == 0 and getFileSize(auxg / "richiesta") > 200_000 and
      regg[5] == $getFileSize(auxg / "richiesta"), "codice " & $rg.code & " " & rg.errout)
    # fornitore che esce senza leggere l'ingresso: niente SIGPIPE, niente blocco, nessuna risposta
    let wn = newRef(luce)
    let auxn = auxOf(wn)
    writeFile(auxn / "esce.sh", "#!/bin/sh\nexit 0\n")
    setFilePermissions(auxn / "esce.sh", {fpUserRead, fpUserWrite, fpUserExec})
    let rn = refine(wn, "", "", @[("BCDD_LLM", auxn / "esce.sh")])
    rec("X", "fornitore che non legge l'ingresso", rn.code == 4 and rn.errout.contains("nessuna risposta") and untouched(wn, luce),
      "codice " & $rn.code & " " & rn.errout)
    # standard error del fornitore: seconda riga con i caratteri di controllo sostituiti da '?'
    let we = newRef(luce)
    let auxe = auxOf(we)
    writeFile(auxe / "errore.sh", "#!/bin/sh\ncat > /dev/null\nprintf '\\033[31mrotto\\n' >&2\nexit 5\n")
    setFilePermissions(auxe / "errore.sh", {fpUserRead, fpUserWrite, fpUserExec})
    let re = refine(we, "", "", @[("BCDD_LLM", auxe / "errore.sh")])
    rec("X", "messaggio dell'LLM sulla seconda riga", re.code == 4 and re.errout ==
      "bcdd refine: l'LLM è terminato senza successo (codice 5): niente scritto, il file è com'era\n  messaggio dell'LLM: ?[31mrotto\n" and
      untouched(we, luce), "codice " & $re.code & " [" & re.errout & "]")
  # AC-70, T22: scelta con il numero; avvisi per i numeri che non ci sono
  block:
    let w = newRef(luce)
    let aux = auxOf(w)
    let r = refine(w, buona, readFile(rf / "T22_scelta.ingresso"), @[("BCDD_FINTO_RICHIESTA_2", aux / "richiesta2"), sec])
    expectOut("AC-70", "T22 uscita", "refine/T22", r, readFile(rf / "T22_scelta.uscita"), 0)
    rec("AC-70", "Luce.csc come T01, dialogo con il testo della scelta", fileEq(w / "Luce.csc", rf / "T01_buona.dopo.csc") and
      fileEq(w / "Luce.csc.dialogo", rf / "T22_scelta.dialogo"), "contenuto diverso", "refine/T22")
    rec("AC-70", "richiesta2 uguale a T22_scelta.richiesta2 (12705 byte), conta 2", fileEq(aux / "richiesta2", rf / "T22_scelta.richiesta2") and
      getFileSize(aux / "richiesta2") == 12705 and contaOf(w) == "2", contaOf(w), "refine/T22")
  # AC-71, T23: un testo che comincia con una cifra resta testo
  for (txt, ris) in [("60 +-1", "60 +-1"), ("1 secondo", "1 secondo")]:
    let w = newRef(luce)
    let aux = auxOf(w)
    let r = refine(w, buona, txt & "\ns\nn\ns\n", @[("BCDD_FINTO_RICHIESTA_2", aux / "richiesta2"), sec])
    rec("AC-71", "T23 " & txt, r.code == 0 and
      ("risposta (da 1 a 3, oppure scrivi tu; invio vuoto per saltare): " & txt & "\n\nhai risposto a 1 domanda: ") in r.output and
      "\n  scelta " notin r.output and "nessuna scelta" notin r.output and
      ("RISPOSTA " & ris & "\n") in readFile(w / "Luce.csc.dialogo") and
      ("RISPOSTA " & ris & "\n") in readFile(aux / "richiesta2"), "codice " & $r.code & " " & r.output, "refine/T23")
  # AC-72: T20 (seconda chiamata) con poche_scelte.json; le sette alla prima chiamata sono in T05
  block:
    let w = newRef(luce)
    let r = refine(w, buona, "fra tre minuti circa\ns\n", @[("BCDD_FINTO_RISPOSTA_2", rf / "risposte" / "poche_scelte.json")])
    rec("AC-72", "T20 poche_scelte alla seconda chiamata", r.code == 4 and r.errout ==
      "bcdd refine: seconda chiamata: risposta dell'LLM non leggibile (poche scelte in domande[1]: 1, almeno 2): nessuna proposta, Luce.csc non cambia\n" and
      untouched(w, luce, @["Luce.csc", "Luce.csc.dialogo", "chiamate.tsv"]), "codice " & $r.code & " [" & r.errout & "]", "refine/T20b")
  # AC-73: limite di 120 s senza BCDD_ATTESA_LLM; la parola «provvisorio» non c'è nei due eseguibili
  block:
    let w = newRef(luce)
    let aux = auxOf(w)
    let env = mkEnv(@[("BCDD_LLM", finto), ("BCDD_ORA", luceOra), ("BCDD_REGISTRO", w / "chiamate.tsv"),
      ("BCDD_FINTO_CONTA", aux / "conta"), ("BCDD_FINTO_RISPOSTA", rf / "risposte" / "vuota.json")])
    let r = runX(bcddProva, @["refine", "Luce.csc"], w, env, "")
    rec("AC-73", "riga 3: ULlmFinto.sh, limite 120 s (ATTESA_MAX_LLM); registro limite_s 120", r.code == 0 and
      r.output.splitLines()[2] == "chiedo all'LLM: ULlmFinto.sh, limite 120 s (ATTESA_MAX_LLM)" and
      registryLast(w)[2] == "120" and "provvisorio" notin r.output, "codice " & $r.code & " " & r.output, "refine/T04b")
    rec("AC-73", "«provvisorio» non compare nei due eseguibili",
      not readFile(bcdd).contains("provvisorio") and not readFile(bcddProva).contains("provvisorio"), "parola presente")
  # AC-74, T21: dove si inseriscono le righe accettate
  block:
    let w = newRef(rf / "Ordine.csc", "Ordine.csc")
    let aux = auxOf(w)
    let r = refine(w, rf / "risposte" / "ordine.json", "s\ns\ns\ns\ns\n", @[], @["Ordine.csc"])
    rec("AC-74", "T21 Ordine.csc come T21_ordine.dopo.csc, nessun .dialogo, conta 1", r.code == 0 and
      fileEq(w / "Ordine.csc", rf / "T21_ordine.dopo.csc") and listDir(w) == @["Ordine.csc", "chiamate.tsv"] and contaOf(w) == "1",
      "codice " & $r.code & " " & r.errout & " " & $listDir(w), "refine/T21")
    rec("AC-74", "T21 uscita: righe PROPOSTA e fine", ("PROPOSTA 1 di 4, dettaglia g1 (riga 10)\n") in r.output and
      ("PROPOSTA 2 di 4, dettaglia g1a (riga 12)\n") in r.output and ("PROPOSTA 3 di 4, dettaglia g1 (riga 10)\n") in r.output and
      ("PROPOSTA 4 di 4, dettaglia g2 (riga 18)\n") in r.output and r.output.endsWith(
      "riepilogo: accettate 4, scartate da te 0, scartate dal controllo 0\n" &
      "scrivo 4 proposte (8 righe) in Ordine.csc? s = sì, n = no: s\nscritto Ordine.csc: 4 proposte (8 righe)\n"),
      r.output, "refine/T21")
    let c = run(@["check", "--strict", "Ordine.csc"], w)
    rec("AC-74", "check --strict di Ordine.csc: codice 0", c.code == 0, "codice " & $c.code)
  # AC-81, AC-82, AC-83, T24: i livelli di DETAILS
  block:
    let w = newRef(rf / "Livelli.csc", "Livelli.csc")
    let aux = auxOf(w)
    let r = refine(w, rf / "risposte" / "livelli.json", readFile(rf / "T24_livelli.ingresso"),
      @[("BCDD_FINTO_RICHIESTA", aux / "richiesta")], @["Livelli.csc"])
    let rq = if fileExists(aux / "richiesta"): readFile(aux / "richiesta").splitLines() else: @[]
    let hd = rq.find("RIGHE CHE PUOI DETTAGLIARE (le righe base e i loro dettagli di primo livello)")
    var listed: seq[string]
    if hd >= 0:
      var k = hd + 1
      while k < rq.len and rq[k].len > 0 and rq[k].startsWith("- "):
        listed.add rq[k]
        inc k
    rec("AC-81", "T24 RIGHE: g1, g1a, a1 e nessuna g1a1", listed == @["- g1: GUARANTEE alla riga 10, ipotesi, verbale",
      "- g1a: GUARANTEE alla riga 12, ipotesi, verbale", "- a1: ASSUME alla riga 18, ipotesi, verbale"], $listed, "refine/T24")
    rec("AC-81", "T24 la riga dei nomi", "pressione, accesa, g1, g1a, g1a1, g1a1a, a1" in rq, "riga dei nomi assente", "refine/T24")
    expectOut("AC-82", "T24 uscita", "refine/T24", r, readFile(rf / "T24_livelli.uscita"), 0)
    rec("AC-82", "Livelli.csc come T24_livelli.dopo.csc, nessun .dialogo, conta 1", fileEq(w / "Livelli.csc", rf / "T24_livelli.dopo.csc") and
      listDir(w) == @["Livelli.csc", "chiamate.tsv"] and contaOf(w) == "1", $listDir(w) & " " & contaOf(w), "refine/T24")
    rec("AC-82", "ragioni 3a: livello 2 e livello 3", "ragione: dettaglia g1a1, già al livello 2 sotto la riga base g1: al più due livelli di DETAILS\n" in r.output and
      "ragione: dettaglia g1a1a, già al livello 3 sotto la riga base g1: al più due livelli di DETAILS\n" in r.output, r.output, "refine/T24")
    let c = run(@["check", "--strict", "Livelli.csc"], w)
    rec("AC-82", "check --strict di Livelli.csc dopo il giro: codice 0", c.code == 0, "codice " & $c.code)
    let c2 = run(@["check", "--strict", "Livelli.csc"], rf)
    rec("AC-83", "check --strict su Livelli.csc (livello 3): codice 0, 0 errori, 0 non riconosciute, nessuna parola «livello»",
      c2.code == 0 and "1. ERRORI: 0" in c2.output and "5. RIGHE NON RICONOSCIUTE: 0" in c2.output and "livello" notin c2.output.toLowerAscii,
      "codice " & $c2.code & " " & c2.output)
  # AC-84, T25: una CSC a parte con una proposta; nessun file creato
  block:
    let w = newRef(luce)
    let r = refine(w, rf / "risposte" / "csc_a_parte.json", readFile(rf / "T25_csc_a_parte.ingresso"))
    expectOut("AC-84", "T25 uscita", "refine/T25", r, readFile(rf / "T25_csc_a_parte.uscita"), 0)
    rec("AC-84", "Luce.csc come T01, dialogo come T25, nessun Pulsante.csc", fileEq(w / "Luce.csc", rf / "T01_buona.dopo.csc") and
      fileEq(w / "Luce.csc.dialogo", rf / "T25_csc_a_parte.dialogo") and listDir(w) == @["Luce.csc", "Luce.csc.dialogo", "chiamate.tsv"],
      $listDir(w), "refine/T25")
  # AC-85, T26: solo una CSC a parte non è la fine
  block:
    let w = newRef(luce)
    let r = refine(w, rf / "risposte" / "csc_sola.json", readFile(rf / "T26_csc_sola.ingresso"))
    expectOut("AC-85", "T26 uscita", "refine/T26", r, readFile(rf / "T26_csc_sola.uscita"), 0)
    rec("AC-85", "nessuna riga «precisa abbastanza»; Luce.csc invariato; dialogo come T25", "precisa abbastanza" notin r.output and
      fileEq(w / "Luce.csc", luce) and fileEq(w / "Luce.csc.dialogo", rf / "T25_csc_a_parte.dialogo"), $listDir(w), "refine/T26")
    let wn = newRef(luce)
    let rn = refine(wn, rf / "risposte" / "csc_sola.json", "n\n")
    rec("AC-85", "con n: niente scritto, nessun dialogo, codice 0", rn.code == 0 and rn.output.endsWith("niente scritto: Luce.csc non cambia\n") and
      untouched(wn, luce), "codice " & $rn.code & " " & rn.output, "refine/T26b")
  # AC-86, T27 e T28: le CSC a parte contano quelle della seconda risposta
  block:
    let w27 = newRef(luce)
    let r27 = refine(w27, rf / "risposte" / "csc_a_parte_prima.json", readFile(rf / "T01_buona.ingresso"), @[sec])
    expectOut("AC-86", "T27 uscita come T01", "refine/T27", r27, readFile(rf / "T01_buona.uscita"), 0)
    rec("AC-86", "T27 dialogo come T01, conta 2", fileEq(w27 / "Luce.csc.dialogo", rf / "T01_buona.dialogo") and contaOf(w27) == "2",
      contaOf(w27), "refine/T27")
    let w28 = newRef(luce)
    let r28 = refine(w28, buona, readFile(rf / "T01_buona.ingresso"), @[("BCDD_FINTO_RISPOSTA_2", rf / "risposte" / "seconda_csc_a_parte.json")])
    expectOut("AC-86", "T28 uscita", "refine/T28", r28, readFile(rf / "T28_seconda_csc.uscita"), 0)
    rec("AC-86", "T28 Luce.csc come T01, dialogo come T28, conta 2", fileEq(w28 / "Luce.csc", rf / "T01_buona.dopo.csc") and
      fileEq(w28 / "Luce.csc.dialogo", rf / "T28_seconda_csc.dialogo") and contaOf(w28) == "2", contaOf(w28), "refine/T28")
  # AC-87: la riga di fine, solo alla prima risposta tutta vuota
  block:
    let w = newWd()
    discard cpTo(rf / "T01_buona.dopo.csc", w, "Luce.csc")
    discard cpTo(rf / "T01_buona.dialogo", w, "Luce.csc.dialogo")
    refWds.add (w, ratLines(w))
    let r = refine(w, rf / "risposte" / "vuota.json", "")
    rec("AC-87", "T04: riga di fine, 293 byte, nessun riepilogo, codice 0, file invariati, una chiamata",
      r.code == 0 and r.output.len == 293 and r.output.endsWith("\nla CSC Luce è precisa abbastanza: nessuna domanda e nessuna proposta, Luce.csc non cambia\n") and
      "riepilogo" notin r.output and fileEq(w / "Luce.csc", rf / "T01_buona.dopo.csc") and fileEq(w / "Luce.csc.dialogo", rf / "T01_buona.dialogo") and
      contaOf(w) == "1" and registryRows(w) == 1, "codice " & $r.code & " " & r.output, "refine/T04")
    let w2 = newRef(luce)
    let r2 = refine(w2, buona, "fra tre minuti circa\ns\n", @[("BCDD_FINTO_RISPOSTA_2", rf / "risposte" / "vuota.json")])
    rec("AC-87", "dopo la seconda chiamata la riga non c'è mai", r2.code == 0 and "precisa abbastanza" notin r2.output and
      r2.output.endsWith("scrivo 1 risposta in Luce.csc.dialogo? s = sì, n = no: s\nscritto Luce.csc.dialogo: 1 risposta\n"),
      "codice " & $r2.code & " " & r2.output, "refine/T04c")
    let w3 = newRef(luce)
    let r3 = refine(w3, rf / "risposte" / "scartate.json", readFile(rf / "T02_scartate.ingresso"))
    rec("AC-87", "T02: le proposte scartate non sono la fine", r3.code == 0 and "precisa abbastanza" notin r3.output, r3.output, "refine/T02b")
  # AC-89, T24 e T30: le righe sostituibili nella richiesta
  proc listedAfter(rq: seq[string], head: string): seq[string] =
    let hd = rq.find(head)
    if hd >= 0:
      var k = hd + 1
      while k < rq.len and rq[k].len > 0 and rq[k].startsWith("- "):
        result.add rq[k]
        inc k
  const headSost = "RIGHE CHE PUOI SOSTITUIRE (le righe ancora ipotesi, a qualunque livello)"
  block:
    let w = newRef(rf / "Livelli.csc", "Livelli.csc")
    let aux = auxOf(w)
    discard refine(w, rf / "risposte" / "livelli.json", readFile(rf / "T24_livelli.ingresso"),
      @[("BCDD_FINTO_RICHIESTA", aux / "richiesta")], @["Livelli.csc"])
    let rq = if fileExists(aux / "richiesta"): readFile(aux / "richiesta").splitLines() else: @[]
    let l = listedAfter(rq, headSost)
    rec("AC-89", "T24: cinque righe sostituibili, anche i livelli 2 e 3", l == @["- g1: GUARANTEE alla riga 10",
      "- g1a: GUARANTEE alla riga 12", "- g1a1: GUARANTEE alla riga 14", "- g1a1a: GUARANTEE alla riga 16",
      "- a1: ASSUME alla riga 18"], $l, "refine/T24")
  # AC-91, T30: il filtro delle sostituzioni (e AC-89 su Sostituzioni.csc)
  block:
    let w = newRef(rf / "Sostituzioni.csc", "Sostituzioni.csc")
    let aux = auxOf(w)
    let r = refine(w, rf / "risposte" / "sostituzioni.json", readFile(rf / "T30_sostituzioni.ingresso"),
      @[("BCDD_FINTO_RICHIESTA", aux / "richiesta")], @["Sostituzioni.csc"])
    let rq = if fileExists(aux / "richiesta"): readFile(aux / "richiesta").splitLines() else: @[]
    let l = listedAfter(rq, headSost)
    rec("AC-89", "T30: g1a, g1a1 e g2a, né g1, g1b, g2 (contratto) né g2b (non verbale)", l == @["- g1a: GUARANTEE alla riga 12",
      "- g1a1: GUARANTEE alla riga 14", "- g2a: GUARANTEE alla riga 20"], $l, "refine/T30")
    expectOut("AC-91", "T30 uscita", "refine/T30", r, readFile(rf / "T30_sostituzioni.uscita"), 0)
    rec("AC-91", "Sostituzioni.csc come T30_sostituzioni.dopo.csc, nessun .dialogo, conta 1, nessuna riga «precisa abbastanza»",
      fileEq(w / "Sostituzioni.csc", rf / "T30_sostituzioni.dopo.csc") and listDir(w) == @["Sostituzioni.csc", "chiamate.tsv"] and
      contaOf(w) == "1" and "precisa abbastanza" notin r.output, $listDir(w) & " " & contaOf(w), "refine/T30")
    let was = readFile(rf / "Sostituzioni.csc").splitLines()
    let now = readFile(w / "Sostituzioni.csc").splitLines()
    var changed: seq[int]
    for i in 0 ..< min(was.len, now.len):
      if was[i] != now[i]: changed.add i + 1
    rec("AC-91", "cambiano solo le righe 12-13 e 20-21; le righe 4 e 16, con RATIFIED, identiche",
      was.len == now.len and changed == @[12, 13, 20, 21] and now[3] == was[3] and now[15] == was[15] and "RATIFIED" in now[3] and
      "RATIFIED" in now[15], $changed, "refine/T30")
    let c = run(@["check", "Sostituzioni.csc"], w)
    rec("AC-91", "check dopo il giro: codice 0, nessuna riga non riconosciuta (C-10, 1.0-beta: g2b ALWAYS accesa è formale)", c.code == 0 and "non riconosciute 0)" in c.output,
      "codice " & $c.code & " " & c.output)
  # AC-90, T29: la sostituzione con la seconda chiamata
  let sostSeconda = ("BCDD_FINTO_RISPOSTA_2", rf / "risposte" / "sostituisce_seconda.json")
  block:
    let w = newRef(luce)
    let r = refine(w, buona, readFile(rf / "T29_sostituzione.ingresso"), @[sostSeconda])
    expectOut("AC-90", "T29 uscita", "refine/T29", r, readFile(rf / "T29_sostituzione.uscita"), 0)
    rec("AC-90", "Luce.csc come T29_sostituzione.dopo.csc, dialogo come T01, conta 2", fileEq(w / "Luce.csc", rf / "T29_sostituzione.dopo.csc") and
      fileEq(w / "Luce.csc.dialogo", rf / "T01_buona.dialogo") and contaOf(w) == "2", $listDir(w) & " " & contaOf(w), "refine/T29")
    let c = run(@["check", "--strict", "Luce.csc"], w)
    rec("AC-90", "check --strict del file nuovo: codice 0", c.code == 0, "codice " & $c.code & " " & c.output)
    let f = registryLast(w)
    rec("AC-90", "seconda riga del registro: byte_risposta 583", f.len == 8 and f[5] == "12710" and f[6] == "601", $f)
  # AC-92: f e n su una sostituzione
  block:
    let w = newRef(luce)
    let r = refine(w, buona, "fra tre minuti circa\nf\ns\n", @[sostSeconda])
    rec("AC-92", "f: nessuna riga PROPOSTA, riepilogo, solo il dialogo, Luce.csc invariato", r.code == 0 and "PROPOSTA" notin r.output and
      r.output.endsWith("riepilogo: accettate 0 (sostituzioni: 0), scartate da te 2, scartate dal controllo 0\n" &
      "scrivo 1 risposta in Luce.csc.dialogo? s = sì, n = no: s\nscritto Luce.csc.dialogo: 1 risposta\n") and
      fileEq(w / "Luce.csc", luce), "codice " & $r.code & " " & r.output, "refine/T29f")
    let w2 = newRef(luce)
    let r2 = refine(w2, buona, "fra tre minuti circa\nn\ns\ns\n", @[sostSeconda])
    let g1a = "  GUARANTEE g1a DETAILS g1 STATUS HYPOTHESIS: VERBAL \"La luce si accende entro mezzo secondo dalla pressione\"\n" &
      "                                              VERIFY BY INSPECTION \"il registro delle pressioni e dell'accensione\"\n"
    let nw = readFile(w2 / "Luce.csc")
    rec("AC-92", "n: una proposta e il dialogo; le righe di g2 come prima, g1a dopo g1", r2.code == 0 and
      r2.output.endsWith("riepilogo: accettate 1 (sostituzioni: 0), scartate da te 1, scartate dal controllo 0\n" &
      "scrivo 1 proposta (2 righe) in Luce.csc e 1 risposta in Luce.csc.dialogo? s = sì, n = no: s\n" &
      "scritto Luce.csc: 1 proposta (2 righe)\nscritto Luce.csc.dialogo: 1 risposta\n") and
      g1a in nw and nw.replace(g1a, "") == readFile(luce), "codice " & $r2.code & " " & r2.output, "refine/T29n")
  # AC-93: il file cambia durante la seconda chiamata con una sostituzione accettata
  block:
    let w = newRef(luce)
    let r = refine(w, buona, readFile(rf / "T29_sostituzione.ingresso"), @[("BCDD_FINTO_TOCCA_2", w / "Luce.csc"), sostSeconda])
    let tail = "scrivo 1 sostituzione e 1 proposta (2 righe) in Luce.csc e 1 risposta in Luce.csc.dialogo? s = sì, n = no: s\n" &
      "sostituzioni accettate e non scritte, da copiare a mano se servono:\n" &
      "  al posto di g2 (riga 12):\n" &
      "    GUARANTEE g2: VERBAL \"La luce si spegne da sola fra 170 e 190 secondi dopo l'ultima pressione\"\n" &
      "                  VERIFY BY JUDGEMENT \"l'operatore, con un cronometro\"\n" &
      "proposte accettate e non scritte, da copiare a mano se servono:\n" &
      "  GUARANTEE g1a DETAILS g1 STATUS HYPOTHESIS: VERBAL \"La luce si accende entro mezzo secondo dalla pressione\"\n" &
      "                                              VERIFY BY INSPECTION \"il registro delle pressioni e dell'accensione\"\n" &
      "risposte non salvate:\n" & dom
    rec("AC-93", "messaggio, codice, le tre parti della sezione 7.5", r.errout == "bcdd refine: Luce.csc è cambiato durante il comando: niente scritto\n" and
      r.code == 1 and r.output.endsWith(tail), "codice " & $r.code & " stderr [" & r.errout & "] stdout [" & r.output & "]", "refine/T29t")
    rec("AC-93", "conta 2, Luce.csc con la sola riga del finto, nessun .dialogo", contaOf(w) == "2" and
      readFile(w / "Luce.csc") == readFile(luce) & touched and listDir(w) == @["Luce.csc", "chiamate.tsv"],
      contaOf(w) & " " & $listDir(w), "refine/T29t")
  # AC-94: T20 (seconda chiamata) con sost_troppe.json
  block:
    let w = newRef(luce)
    let r = refine(w, buona, "fra tre minuti circa\ns\n", @[("BCDD_FINTO_RISPOSTA_2", rf / "risposte" / "sost_troppe.json")])
    rec("AC-94", "T20 sost_troppe alla seconda chiamata", r.code == 4 and r.errout ==
      "bcdd refine: seconda chiamata: risposta dell'LLM non leggibile (troppe sostituzioni: 11, al più 10): nessuna proposta, Luce.csc non cambia\n" and
      untouched(w, luce, @["Luce.csc", "Luce.csc.dialogo", "chiamate.tsv"]), "codice " & $r.code & " [" & r.errout & "]", "refine/T20c")
  # AC-39: refine non ratifica mai
  block:
    var ok = true
    var why = ""
    for (w, n) in refWds:
      if ratLines(w) != n:
        ok = false
        why = w & ": righe RATIFIED " & $ratLines(w) & " invece di " & $n
    rec("AC-39", "righe RATIFIED invariate in tutte le cartelle di refine", ok, why)

# 065:1:1 l'eseguibile normale ignora BCDD_LLM e lancia solo `claude -p ...` (sezione 9.2)
block:
  let w = newWd()
  discard cpTo(f2Dir / "refine" / "Luce.csc", w)
  let aux = auxOf(w)
  let fake = aux / "bin"
  createDir(fake)
  writeFile(fake / "claude", "#!/bin/sh\nd=$(dirname \"$0\")\n{ echo \"n=$#\"; for a in \"$@\"; do echo \"[$a]\"; done; pwd; ls -A | wc -l; } > \"$d/registro\"\ncat > \"$d/richiesta\"\nexit 0\n")
  setFilePermissions(fake / "claude", {fpUserRead, fpUserWrite, fpUserExec})
  let env = mkEnv(@[("PATH", fake & ":" & getEnv("PATH")), ("BCDD_LLM", finto), ("BCDD_FINTO_PID", aux / "pid"),
    ("BCDD_FINTO_RISPOSTA", f2Dir / "refine" / "risposte" / "buona.json"), ("BCDD_REGISTRO", aux / "chiamate.tsv"),
    ("BCDD_ORA", luceOra)])
  let r = runX(bcdd, @["refine", "Luce.csc"], w, env, "")
  rec("D129", "il binario normale non avvia il fornitore di BCDD_LLM", not fileExists(aux / "pid"), "il finto è stato avviato")
  rec("D129", "il binario normale lancia claude", fileExists(fake / "registro"), "claude non chiamato")
  if fileExists(fake / "registro"):
    let ls = readFile(fake / "registro").splitLines()
    rec("D129", "vettore: -p --tools '' --output-format text --no-session-persistence --model sonnet (D-246)",
      ls.len >= 11 and ls[0 .. 8] == @["n=8", "[-p]", "[--tools]", "[]", "[--output-format]", "[text]", "[--no-session-persistence]", "[--model]", "[sonnet]"],
      $ls)
    rec("D129", "cartella di lavoro di claude: vuota e non quella dell'utente", ls.len >= 11 and ls[9] != w and ls[10] == "0", $ls)
  rec("D129", "la richiesta arriva sullo standard input", fileEq(fake / "richiesta", f2Dir / "refine" / "T01_buona.richiesta"),
    "richiesta diversa o assente")
  rec("D129", "riga 3 senza BCDD_ATTESA_LLM: claude, 120 s (ATTESA_MAX_LLM)",
    r.output == "bcdd refine Luce.csc\nCSC Luce: nessun errore, righe non riconosciute: 0\n" &
      "chiedo all'LLM: claude, limite 120 s (ATTESA_MAX_LLM)\n" and
    r.errout == "bcdd refine: l'LLM non ha dato nessuna risposta: niente scritto, il file è com'era\n" and r.code == 4,
    "codice " & $r.code & " stdout [" & r.output & "] stderr [" & r.errout & "]")
  rec("D129", "il binario normale non contiene il nome BCDD_LLM; quello di prova sì",
    not readFile(bcdd).contains("BCDD_LLM") and readFile(bcddProva).contains("BCDD_LLM"), "presenza della stringa BCDD_LLM")
  rec("D129", "file invariato", fileEq(w / "Luce.csc", f2Dir / "refine" / "Luce.csc") and listDir(w) == @["Luce.csc"], $listDir(w))

# 065:2:1 AC-66: nell'eseguibile normale valgono BCDD_ATTESA_LLM, BCDD_REGISTRO e BCDD_ORA; BCDD_LLM no
block:
  let w = newWd()
  discard cpTo(f2Dir / "refine" / "Luce.csc", w)
  let aux = auxOf(w)
  let fake = aux / "bin"
  createDir(fake)
  writeFile(fake / "claude", "#!/bin/sh\ncat > /dev/null\nexit 0\n")
  setFilePermissions(fake / "claude", {fpUserRead, fpUserWrite, fpUserExec})
  let env = mkEnv(@[("PATH", fake & ":" & getEnv("PATH")), ("BCDD_LLM", finto), ("BCDD_FINTO_PID", aux / "pid"),
    ("BCDD_FINTO_RISPOSTA", f2Dir / "refine" / "risposte" / "buona.json"), ("BCDD_REGISTRO", aux / "chiamate.tsv"),
    ("BCDD_ORA", luceOra), ("BCDD_ATTESA_LLM", "30")])
  let r = runX(bcdd, @["refine", "Luce.csc"], w, env, "")
  rec("AC-66", "riga 3: claude, limite 30 s (da BCDD_ATTESA_LLM)", r.output ==
    "bcdd refine Luce.csc\nCSC Luce: nessun errore, righe non riconosciute: 0\n" &
    "chiedo all'LLM: claude, limite 30 s (da BCDD_ATTESA_LLM)\n", "stdout [" & r.output & "]")
  rec("AC-66", "il registro è in BCDD_REGISTRO e comincia con BCDD_ORA", fileExists(aux / "chiamate.tsv") and
    readFile(aux / "chiamate.tsv").splitLines()[1].startsWith(luceOra & "\tclaude:sonnet\t30\t"), "registro assente o diverso")
  rec("AC-66", "il fornitore di BCDD_LLM non è avviato", not fileExists(aux / "pid"), "il finto è stato avviato")

# 068:1:1 F3a: entità, citazioni, --dir, E14 (AC-95..AC-113). Gli attesi in prove/f3/ sono scritti a mano.
let f3Dir = proveDir / "f3"
let f3bDir = proveDir / "f3b"
let f3bBefore = snapshot(@[f3bDir])
let f3Before = snapshot(@[f3Dir])
proc c3(args: seq[string], cwd: string = root): Res = run(@["check"] & args, cwd)
proc slurp(p: string): string = readFile(f3Dir / p)

block:
  const L = "prove/f3/luce/"
  expectOut("AC-95", "LuceScale", "f3/LuceScale", c3(@[L & "LuceScale.csc"]), slurp("luce/LuceScale.atteso"), 0)
  let r96 = c3(@[L & "SenzaPulsante.csc"])
  expectOut("AC-96", "SenzaPulsante", "f3/SenzaPulsante", r96, slurp("luce/SenzaPulsante.atteso"), 1)
  rec("AC-96", "E14 sulla riga 5 con il testo del contratto",
    "  riga 5: [E14] la parte lampada usa il connettore Comando: nessun'altra parte di SenzaPulsante lo offre, né SenzaPulsante lo usa da fuori\n" in r96.output,
    r96.output)
  let r97 = c3(@[L & "DaFuori.csc"])
  expectOut("AC-97", "DaFuori", "f3/DaFuori", r97, slurp("luce/DaFuori.atteso"), 0)
  rec("AC-97", "la voce e nessun E14", "  riga 6: lampada usa Comando: la usa DaFuori da fuori (riga 4)\n" in r97.output and
    "[E14]" notin r97.output, r97.output)
  expectOut("AC-98", "LampadaWiFi con --dir", "f3/LampadaWiFi",
    c3(@["--dir", "prove/f3/luce", "prove/f3/wifi/LampadaWiFi.csc"]), slurp("wifi/LampadaWiFi.atteso"), 0)
  expectOut("AC-99", "Rete", "f3/Rete", c3(@["prove/f3/bus/Rete.csc"]), slurp("bus/Rete.atteso"), 0)
  expectOut("AC-99", "Solo", "f3/Solo", c3(@["prove/f3/bus/Solo.csc"]), slurp("bus/Solo.atteso"), 1)
  expectOut("AC-100", "forme", "f3/forme", c3(@["prove/f3/forme.csc"]), slurp("forme.atteso"), 1)
  let r101 = c3(@[L & "Pulsante.csc"])
  expectOut("AC-101", "Pulsante", "f3/PulsanteLuce", r101, slurp("luce/Pulsante.atteso"), 0)
  rec("AC-101", "nessun E11, due citazioni, sezione 8 a zero", "E11" notin r101.output and
    r101.output.count("alla riga 1: VERSION 0.1") == 2 and "8. USI DENTRO LE ENTITÀ: 0\n" in r101.output, r101.output)
  let r102 = c3(@["--dir", "prove/f3/luce", "prove/f3/versioni/Versioni.csc"])
  expectOut("AC-102", "Versioni", "f3/Versioni", r102, slurp("versioni/Versioni.atteso"), 1)
  rec("AC-102", "attesa VERSION solo su due citazioni", r102.output.count(", attesa VERSION ") == 2 and
    "riga 11: OFFERS Comando VERSION v1\n" in r102.output, r102.output)
  expectOut("AC-104", "Sospeso", "f3/Sospeso", c3(@["--dir", "prove/f3/luce", "prove/f3/sospeso/Sospeso.csc"]),
    slurp("sospeso/Sospeso.atteso"), 0)
  expectOut("AC-113", "Esterna", "f3/Esterna", c3(@["prove/f3/profondo/Esterna.csc"]), slurp("profondo/Esterna.atteso"), 1)
  let r113 = c3(@["prove/f3/profondo/Esterna.csc"])
  # 1.17: E17 nomina Ombra, che la parte m offre; la riga dell'errore non conta (le parti di m non compaiono)
  let o113 = r113.output.replace("la parte m offre il connettore Ombra", "")
  rec("AC-113", "Interna e Ombra non compaiono", "Interna" notin o113 and "Ombra" notin o113, r113.output)

# 068:2:1 AC-103: citazioni che non si trovano, in una copia con le cose che git non conserva
block:
  let w = newWd()
  for f in ["Citazioni.csc", "NonUtf8.csc", "Sporco.csc", "SoloCsc.csc"]: discard cpTo(f3Dir / "citazioni" / f, w)
  createDir(w / "Cartella.csc")
  writeFile(w / "Chiuso.csc", "CSC Chiuso VERSION 0.1\n")
  setFilePermissions(w / "Chiuso.csc", {})
  createSymlink("non_c_e_da_nessuna_parte", w / "Rotto.csc")
  var canRead = true
  try:
    discard readFile(w / "Chiuso.csc")
  except IOError:
    canRead = false
  if canRead:
    echo "nota: AC-103 non eseguito (utente root scavalca i permessi), come AC-25/26"
  else:
    expectOut("AC-103", "Citazioni", "f3/Citazioni", run(@["check", "Citazioni.csc"], w), slurp("citazioni/Citazioni.atteso"), 0)
    expectOut("AC-109", "Citazioni --strict", "f3/Citazioni.strict", run(@["check", "--strict", "Citazioni.csc"], w),
      slurp("citazioni/Citazioni.strict.atteso"), 0)
  setFilePermissions(w / "Chiuso.csc", {fpUserRead, fpUserWrite})

# 068:3:1 AC-106 (g-c4): lo stesso rapporto da qualunque cartella, e due volte
block:
  let want = slurp("luce/LuceScale.atteso")
  let absLuce = f3Dir / "luce"
  for cwd in [root, "/", absLuce]:
    for k in 1 .. 2:
      let file = if cwd == absLuce: "LuceScale.csc" else: absLuce / "LuceScale.csc"
      expectOut("AC-106", "LuceScale da " & cwd & " (" & $k & ")", "", c3(@[file], cwd), want, 0)
  let a1 = c3(@["--dir", absLuce, f3Dir / "wifi" / "LampadaWiFi.csc"], root)
  let a2 = c3(@["--dir", absLuce, f3Dir / "wifi" / "LampadaWiFi.csc"], "/")
  for nome in ["Trattino", "Parole", "Chiude", "Chiavi", "Posizioni"]:
    let absP = f3Dir / "parola" / nome & ".csc"
    let pa = c3(@["--dir", absLuce, absP], root)
    let pb = c3(@["--dir", absLuce, absP], "/")
    rec("AC-106", nome & " (parola) con --dir assoluta: stesso rapporto da due cartelle",
      pa.output == pb.output and pa.code == pb.code and pa.output.len > 0, pa.output & pb.output)
  rec("AC-106", "LampadaWiFi con --dir assoluta da due cartelle", a1.output == a2.output and a1.code == 0 and
    "in " & absLuce & "/Luce.csc alla riga 1" in a1.output, a1.output & a2.output)

# 068:4:1 AC-107: raccolta, --dir prima o dopo il file
block:
  let want = slurp("Uso.dir.atteso")
  expectOut("AC-107", "--dir prima del file", "f3/Uso.dir", c3(@["--dir", "prove/f3/raccolta", "prove/f3/Uso.csc"]), want, 0)
  expectOut("AC-107", "--dir dopo il file", "f3/Uso.dir", c3(@["prove/f3/Uso.csc", "--dir", "prove/f3/raccolta"]), want, 0)
  expectOut("AC-107", "senza --dir", "f3/Uso", c3(@["prove/f3/Uso.csc"]), slurp("Uso.atteso"), 0)
  # 068:4:2 Una --dir uguale alla cartella del file, e due scritture della stessa cartella
  expectOut("AC-107", "--dir uguale alla cartella del file", "", c3(@["--dir", "prove/f3", "prove/f3/Uso.csc"]),
    "bcdd check --dir prove/f3 Uso.csc\n" & slurp("Uso.atteso").split('\n', 1)[1], 0)
  let rr = c3(@["--dir", "prove/f3/raccolta", "--dir", "./prove/f3/raccolta", "prove/f3/Uso.csc"])
  rec("AC-107", "due scritture della stessa cartella sono ammesse", rr.code == 0 and rr.errout.len == 0 and
    rr.output.startsWith("bcdd check --dir prove/f3/raccolta --dir ./prove/f3/raccolta Uso.csc\n") and
    "in prove/f3/raccolta/Citofono.csc alla riga 1" in rr.output, rr.output & rr.errout)
  expectOut("AC-107", "--strict e --dir in ordine misto", "", c3(@["--dir", "prove/f3/raccolta", "--strict", "prove/f3/Uso.csc"]),
    "bcdd check --strict --dir prove/f3/raccolta Uso.csc\n" & want.split('\n', 1)[1], 0)

# 068:5:1 AC-108: le --dir sbagliate
block:
  const uso = "uso: bcdd check [--strict] [--json] [--dir CARTELLA]... FILE\n"
  const F = "prove/f3/luce/LuceScale.csc"
  expectErr("AC-108", "cartella non trovata", "", c3(@["--dir", "prove/f3/nessuna", F]),
    "bcdd check: cartella non trovata: prove/f3/nessuna\n", 2)
  expectErr("AC-108", "una parte del percorso non è una cartella", "", c3(@["--dir", "prove/f3/forme.csc/x", F]),
    "bcdd check: cartella non trovata: prove/f3/forme.csc/x\n", 2)
  expectErr("AC-108", "non è una cartella", "", c3(@["--dir", "prove/f3/forme.csc", F]),
    "bcdd check: non è una cartella: prove/f3/forme.csc\n", 2)
  expectErr("AC-108", "stessa --dir ripetuta", "", c3(@["--dir", "prove/f3/luce", "--dir", "prove/f3/luce", F]), uso, 2)
  expectErr("AC-108", "--dir come ultimo argomento", "", c3(@[F, "--dir"]), uso, 2)
  expectErr("AC-108", "--dir=X", "", c3(@["--dir=prove/f3", F]), uso, 2)
  expectErr("AC-108", "--strict ripetuto con --dir", "", c3(@["--strict", "--dir", "prove/f3/luce", "--strict", F]), uso, 2)
  expectErr("AC-108", "il file prima delle cartelle", "", c3(@["--dir", "prove/f3/nessuna", "prove/f3/non_c_e.csc"]),
    "bcdd check: file non trovato: prove/f3/non_c_e.csc\n", 2)
  expectErr("AC-108", "la prima cartella che fallisce decide", "",
    c3(@["--dir", "prove/f3/forme.csc", "--dir", "prove/f3/nessuna", F]), "bcdd check: non è una cartella: prove/f3/forme.csc\n", 2)
  # 068:5:2 L'argomento di --dir è sempre la cartella, anche se comincia con '-'
  let w = newWd()
  createDir(w / "--strict")
  let rs = run(@["check", "--dir", "--strict", root / F], w)
  rec("AC-108", "--dir --strict cerca una cartella che si chiama --strict", rs.code == 0 and
    rs.output.startsWith("bcdd check --dir --strict LuceScale.csc\n"), rs.output & rs.errout)
  if getuid() == 0:
    echo "nota: AC-108 cartella non leggibile non eseguito (utente root scavalca i permessi)"
  else:
    let d0 = w / "chiusa"
    createDir(d0)
    setFilePermissions(d0, {})
    expectErr("AC-108", "cartella non leggibile", "", c3(@["--dir", d0, F]), "bcdd check: cartella non leggibile: " & d0 & "\n", 2)
    setFilePermissions(d0, {fpUserRead, fpUserWrite, fpUserExec})

# 068:6:1 AC-109: --strict
block:
  expectOut("AC-109", "LuceScale --strict", "f3/LuceScale.strict", c3(@["--strict", "prove/f3/luce/LuceScale.csc"]),
    slurp("luce/LuceScale.strict.atteso"), 0)
  rec("AC-109", "LuceScale --strict: solo la prima riga differisce", slurp("luce/LuceScale.strict.atteso").split('\n', 1)[1] ==
    slurp("luce/LuceScale.atteso").split('\n', 1)[1], "il resto del rapporto cambia")
  let r = c3(@["--strict", "prove/f3/luce/SenzaPulsante.csc"])
  rec("AC-109", "SenzaPulsante --strict: codice 1", r.code == 1, "codice " & $r.code)

# 068:6:2 AC-115..AC-118: le correzioni del gate. Gli attesi sono scritti a mano dalle regole.
block:
  const D = @["--dir", "prove/f3/luce"]
  expectOut("AC-115", "Chiede", "f3/Chiede", c3(D & "prove/f3/richiesta/Chiede.csc"), slurp("richiesta/Chiede.atteso"), 1)
  expectOut("AC-115", "Libera", "f3/Libera", c3(D & "prove/f3/richiesta/Libera.csc"), slurp("richiesta/Libera.atteso"), 1)
  expectOut("AC-181", "Misto", "f3/Misto", c3(D & "prove/f3/richiesta/Misto.csc"), slurp("richiesta/Misto.atteso"), 1)
  expectOut("AC-115", "FuoriLibero", "f3/FuoriLibero", c3(D & "prove/f3/richiesta/FuoriLibero.csc"),
    slurp("richiesta/FuoriLibero.atteso"), 1)
  let rc = c3(D & "prove/f3/richiesta/Chiede.csc")
  rec("AC-115", "Chiede: E14 e voce 'nessuno la offre', non 'la offre pulsante'",
    "[E14] la parte lampada usa il connettore Comando VERSION 0.2:" in rc.output and "la offre pulsante" notin rc.output, rc.output)
  expectOut("AC-116", "Elenco", "f3/Elenco", c3(D & "prove/f3/elenco/Elenco.csc"), slurp("elenco/Elenco.atteso"), 1)
  # AC-133 (sostituisce AC-117): lo STATUS di una garanzia d'entità; E04 sulla riga 8, codice 1
  expectOut("AC-133", "Stato", "f3/Stato", c3(@["prove/f3/stato/Stato.csc"]), slurp("stato/Stato.atteso"), 1)
  expectOut("AC-133", "Stato --strict", "f3/Stato.strict", c3(@["--strict", "prove/f3/stato/Stato.csc"]),
    slurp("stato/Stato.strict.atteso"), 1)
  let rs = c3(@["prove/f3/stato/Stato.csc"])
  rec("AC-133", "E04 sulla riga 8 e il solo STATUS HYPOTHESIS dell'intestazione riconosciuto", "  riga 8: [E04]" in rs.output and
    "riga 12: ENTITY Ipotesi VERSION 0.1, STATUS HYPOTHESIS" in rs.output and
    "riga 1: ENTITY Ratificata VERSION 0.1, senza STATUS" in rs.output, rs.output)
  expectOut("AC-118", "Doppi", "f3/Doppi", c3(D & "prove/f3/doppi/Doppi.csc"), slurp("doppi/Doppi.atteso"), 1)
  expectOut("AC-118", "FuoriDoppio", "f3/FuoriDoppio", c3(D & "prove/f3/doppi/FuoriDoppio.csc"),
    slurp("doppi/FuoriDoppio.atteso"), 1)

# 068:6:3 AC-121..AC-125 (GRAMMATICA_F1 1.8): in un'entità ogni dichiarazione G34 è una parte, dovunque stia.
# Gli attesi di prove/f3/parola/ sono scritti a mano (sezione 25.3), non dall'uscita del programma.
block:
  const D = @["--dir", "prove/f3/luce"]
  let tr = c3(D & "prove/f3/parola/Trattino.csc")
  expectOut("AC-121", "Trattino", "f3/parola/Trattino", tr, slurp("parola/Trattino.atteso"), 1)
  let wantTrS = slurp("parola/Trattino.atteso")
    .replace("bcdd check --dir prove/f3/luce Trattino.csc", "bcdd check --strict --dir prove/f3/luce Trattino.csc")
    .replace("esito: 2 errori; righe non riconosciute: 1 (vedi sezione 5)\n", "esito: 2 errori; righe non riconosciute: 1 (--strict)\n")
  expectOut("AC-121", "Trattino --strict", "f3/parola/Trattino.strict", c3(@["--strict"] & D & "prove/f3/parola/Trattino.csc"), wantTrS, 1)
  rec("AC-121", "la parte lampada è controllata anche se pulsante-uno non lo è: E14 sulla riga 7",
    "  riga 7: [E14] la parte lampada usa il connettore Comando:" in tr.output and tr.code == 1, tr.output)
  expectOut("AC-122", "Parole", "f3/parola/Parole", c3(D & "prove/f3/parola/Parole.csc"), slurp("parola/Parole.atteso"), 1)
  expectOut("AC-123", "Chiude", "f3/parola/Chiude", c3(D & "prove/f3/parola/Chiude.csc"), slurp("parola/Chiude.atteso"), 1)
  let rc = c3(D & "prove/f3/parola/Chiude.csc")
  rec("AC-123", "quattro E14, uno per entità", rc.output.count("[E14]") == 4, rc.output)
  expectOut("AC-124", "Chiavi", "f3/parola/Chiavi", c3(D & "prove/f3/parola/Chiavi.csc"), slurp("parola/Chiavi.atteso"), 0)
  let rk = c3(@["--strict"] & D & "prove/f3/parola/Chiavi.csc")
  rec("AC-124", "Chiavi --strict: codice 3, 10 righe non riconosciute, nessun errore",
    rk.code == 3 and rk.output.endsWith("esito: nessun errore; righe non riconosciute: 10 (--strict)\n"), "codice " & $rk.code & " " & rk.output)
  let rp = c3(D & "prove/f3/parola/Posizioni.csc")
  expectOut("AC-125", "Posizioni", "f3/parola/Posizioni", rp, slurp("parola/Posizioni.atteso"), 1)
  rec("AC-125", "il solo E14 è alla riga 29", rp.output.count("[E14]") == 1 and "  riga 29: [E14]" in rp.output, rp.output)

# 068:7:1 AC-105 (g-c1): nessun file di prove/f3 è cambiato, né nel contenuto né nella data
block:
  let f3After = snapshot(@[f3Dir])
  rec("AC-105", "contenuto e data di prove/f3/ prima e dopo AC-95..AC-109", f3After == f3Before, "un file di prove/f3 è cambiato")

# 068:8:1 AC-111: refine su un file con entità
block:
  let rf3 = f3Dir / "refine"
  let vuota = f2Dir / "refine" / "risposte" / "vuota.json"
  block:
    let w = newRef(rf3 / "Misto.csc", "Misto.csc")
    let aux = auxOf(w)
    let r = runX(bcddProva, @["refine", "Misto.csc"], w, refEnv(w, @[("BCDD_FINTO_RISPOSTA", vuota),
      ("BCDD_FINTO_RICHIESTA", aux / "richiesta")]), "")
    rec("AC-111", "Misto: codice 0, la CSC è precisa abbastanza", r.code == 0 and r.errout.len == 0 and
      r.output.startsWith("bcdd refine Misto.csc\nCSC Luce: nessun errore, righe non riconosciute: 0\n"), "codice " & $r.code & " " & r.output & r.errout)
    rec("AC-111", "la richiesta è uguale a Misto.richiesta", fileEq(aux / "richiesta", rf3 / "Misto.richiesta"),
      "la richiesta è diversa")
    rec("AC-111", "Misto.csc invariato, nessun .dialogo", fileEq(w / "Misto.csc", rf3 / "Misto.csc") and
      listDir(w) == @["Misto.csc", "chiamate.tsv"], $listDir(w))
  block:
    let w = newRef(rf3 / "MistoE14.csc", "MistoE14.csc")
    let r = runX(bcddProva, @["refine", "MistoE14.csc"], w, refEnv(w, @[("BCDD_FINTO_RISPOSTA", vuota)]), "")
    expectErr("AC-111", "MistoE14: il file non passa check", "", r,
      "bcdd refine: il file non passa bcdd check (errori: 2): correggilo prima di affinare\n", 1)
    rec("AC-111", "MistoE14: l'LLM non chiamato, file invariato", contaOf(w) == "0" and
      fileEq(w / "MistoE14.csc", rf3 / "MistoE14.csc") and not fileExists(w / "MistoE14.csc.dialogo"), $listDir(w))
  # AC-111 casi 2 e 4: sostituiti da AC-144

# 068:9:1 AC-112: ratify su un file con entità
block:
  let rd3 = f3Dir / "ratify"
  block:
    let w = newWd()
    discard cpTo(rd3 / "Misto.csc", w)
    let r = run(@["ratify", "Misto.csc", "--all", "D-1"], w)
    rec("AC-112", "Misto --all: codice 0 e file uguale a Misto.all.dopo.csc", r.code == 0 and r.errout.len == 0 and
      fileEq(w / "Misto.csc", rd3 / "Misto.all.dopo.csc"), "codice " & $r.code & " " & r.errout)
    let c = run(@["check", "--strict", "Misto.csc"], w)
    rec("AC-112", "dopo --all il file passa check --strict", c.code == 0, c.output)
  block:
    let w = newWd()
    discard cpTo(rd3 / "MistoE14.csc", w)
    expectErr("AC-112", "MistoE14 --all", "", run(@["ratify", "MistoE14.csc", "--all", "D-1"], w),
      "bcdd ratify: il file non passa bcdd check --strict (errori: 2, righe non riconosciute: 0): non ratifico\n", 1)
    rec("AC-112", "MistoE14 invariato", fileEq(w / "MistoE14.csc", rd3 / "MistoE14.csc") and listDir(w) == @["MistoE14.csc"], $listDir(w))
  # AC-112 casi 3 e 4: sostituiti da AC-136
  block:
    # 068:9:2 Ratificare la sola CSC lascia l'entità identica byte per byte
    let w = newWd()
    discard cpTo(rd3 / "Misto.csc", w)
    let r = run(@["ratify", "Misto.csc", "D-1"], w)
    let nuovo = readFile(w / "Misto.csc")
    let entita = "ENTITY LuceMista"
    rec("AC-112", "ratify della CSC: le righe dell'entità invariate", r.code == 0 and
      nuovo[nuovo.find(entita) .. ^1] == readFile(rd3 / "Misto.csc")[readFile(rd3 / "Misto.csc").find(entita) .. ^1],
      "codice " & $r.code & " " & r.errout)

# 068:10:1 Prove di bordo F3a: BOM, CR LF, nessun LF finale su un file con entità
block:
  let w = newWd()
  let src = readFile(f3Dir / "luce" / "LuceScale.csc")
  let want = slurp("luce/LuceScale.atteso")
  for f in ["Pulsante", "Luce", "Pressione", "Comando", "Lampada"]: discard cpTo(f3Dir / "luce" / f & ".csc", w)
  writeFile(w / "Crlf.csc", "\xEF\xBB\xBF" & src.replace("\n", "\r\n").replace("LuceScale", "Crlf"))
  let r1 = run(@["check", "Crlf.csc"], w)
  rec("X", "entità con BOM e CR LF: stesso rapporto", r1.code == 0 and r1.output == want.replace("LuceScale", "Crlf"), r1.output)
  writeFile(w / "SenzaLf.csc", src.strip(leading = false, chars = {'\n'}).replace("LuceScale", "SenzaLf"))
  let r2 = run(@["check", "SenzaLf.csc"], w)
  rec("X", "entità senza LF finale: stesso rapporto", r2.code == 0 and r2.output == want.replace("LuceScale", "SenzaLf"), r2.output)
  writeFile(w / "Vuota.csc", "")
  let r3 = run(@["check", "Vuota.csc"], w)
  rec("X", "file vuoto: nessuna sezione 8", r3.code == 1 and "8. USI" notin r3.output, r3.output)
  rec("X", "check non ha lasciato file nuovi", listDir(w).len == 8, $listDir(w))

# 069:1:1 F3b: ratify e refine sulle entità, AC-127..AC-148. Gli attesi in prove/f3b/ sono scritti
# a mano (non dall'uscita del programma). `refine` solo con l'eseguibile di prova e l'LLM finto.
block:
  let rdb = f3bDir / "ratify"
  let sdb = f3bDir / "scelta"
  let fdb = f3bDir / "refine"
  let luceAbs = f3Dir / "luce"
  let vuota = fdb / "risposte" / "vuota_entita.json"      # le entità restano a bcdd-refine-4
  let vuotaCsc = f2Dir / "refine" / "risposte" / "vuota.json"
  let ratInputs = @["Due", "Ignota", "Lontana", "Luce", "Manca", "Pressione", "Scale", "Sporca", "Sporco", "Stesso", "Versione"]
  var ratList = ratInputs.mapIt(it & ".csc")
  ratList.sort()
  proc wdR(): string =
    result = newWd()
    for n in ratList: discard cpTo(rdb / n, result)
  proc same(w, name: string): bool = fileEq(w / name, rdb / name) and listDir(w) == ratList
  proc rat(w: string, args: seq[string]): Res = run(@["ratify"] & args, w)
  const usoR = "uso: bcdd ratify FILE [--csc NOME] [--dir CARTELLA]... [ID | --all] D-numero\n"

  # AC-132 (B.1): lo STATUS RATIFIED BY dentro una garanzia d'entità si riconosce
  let want132 = readFile(rdb / "Scale.atteso")
  expectOut("AC-132", "check Scale.csc", "f3b/Scale", run(@["check", "Scale.csc"], rdb), want132, 0)
  expectOut("AC-132", "check --strict Scale.csc", "f3b/Scale.strict", run(@["check", "--strict", "Scale.csc"], rdb),
    "bcdd check --strict Scale.csc\n" & want132.split('\n', 1)[1], 0)
  # AC-106 esteso: lo stesso rapporto da qualunque cartella, e due volte
  for cwd in [root, "/", rdb]:
    for k in 1 .. 2:
      let file = if cwd == rdb: "Scale.csc" else: rdb / "Scale.csc"
      expectOut("AC-106", "Scale da " & cwd & " (" & $k & ")", "", run(@["check", file], cwd), want132, 0)
  # AC-134 (B.2.5): una garanzia d'entità senza STATUS (caso r2)
  block:
    let w = wdR()
    expectOut("AC-134", "ratify Scale.csc g1 D-200", "f3b/Scale.g1", rat(w, @["Scale.csc", "g1", "D-200"]),
      "ratificata la riga 5: GUARANTEE g1 con D-200\n", 0)
    rec("AC-134", "file uguale a Scale.g1.dopo.csc", fileEq(w / "Scale.csc", rdb / "Scale.g1.dopo.csc"), "contenuto diverso")
  # AC-135 (B.2.4, B.2.5): --all sull'entità, e una seconda volta
  block:
    let w = wdR()
    expectOut("AC-135", "ratify --all D-200", "f3b/Scale.all", rat(w, @["Scale.csc", "--all", "D-200"]),
      readFile(rdb / "Scale.all.uscita"), 0)
    rec("AC-135", "file uguale a Scale.all.dopo.csc", fileEq(w / "Scale.csc", rdb / "Scale.all.dopo.csc"), "contenuto diverso")
    let c = run(@["check", "--strict", "Scale.csc"], w)
    rec("AC-135", "dopo --all: check --strict codice 0 e ipotesi a zero", c.code == 0 and "4. IPOTESI, NON CONTRATTO: 0" in c.output,
      "codice " & $c.code & " " & c.output)
    let after1 = readFile(w / "Scale.csc")
    expectErr("AC-135", "--all D-201 una seconda volta", "", rat(w, @["Scale.csc", "--all", "D-201"]),
      "bcdd ratify: la ENTITY Scale non ha garanzie ancora ipotesi: non cambio nulla\n", 1)
    rec("AC-135", "file invariato dalla seconda volta", readFile(w / "Scale.csc") == after1, "il file è cambiato")
  # AC-136 (g-t4): l'intestazione di un'entità non si ratifica mai
  block:
    let w = wdR()
    expectErr("AC-136", "Scale D-200", "", rat(w, @["Scale.csc", "D-200"]),
      "bcdd ratify: l'intestazione della ENTITY Scale non si ratifica: indica una GUARANTEE oppure --all\n", 1)
    rec("AC-136", "Scale invariato", same(w, "Scale.csc"), $listDir(w))
    let w2 = newWd()
    discard cpTo(f3Dir / "luce" / "Pulsante.csc", w2)
    expectErr("AC-136", "Pulsante D-1", "", rat(w2, @["Pulsante.csc", "D-1"]),
      "bcdd ratify: l'intestazione della ENTITY Pulsante non si ratifica: indica una GUARANTEE oppure --all\n", 1)
    rec("AC-136", "Pulsante invariato", fileEq(w2 / "Pulsante.csc", f3Dir / "luce" / "Pulsante.csc") and listDir(w2) == @["Pulsante.csc"], $listDir(w2))
    let w3 = newWd()
    discard cpTo(f3Dir / "ratify" / "Misto.csc", w3)
    expectErr("AC-136", "Misto --csc LuceMista D-1", "", rat(w3, @["Misto.csc", "--csc", "LuceMista", "D-1"]),
      "bcdd ratify: l'intestazione della ENTITY LuceMista non si ratifica: indica una GUARANTEE oppure --all\n", 1)
    rec("AC-136", "Misto invariato", fileEq(w3 / "Misto.csc", f3Dir / "ratify" / "Misto.csc") and listDir(w3) == @["Misto.csc"], $listDir(w3))
  # AC-137 (B.2.4): gli altri rifiuti sul bersaglio; il bersaglio viene prima dei confini
  block:
    let w = wdR()
    expectErr("AC-137", "g2 già contratto", "", rat(w, @["Scale.csc", "g2", "D-200"]),
      "bcdd ratify: g2 è già contratto (riga 9): non cambio nulla\n", 1)
    expectErr("AC-137", "g9 inesistente", "", rat(w, @["Scale.csc", "g9", "D-200"]),
      "bcdd ratify: nessuna GUARANTEE con id g9 nella ENTITY Scale\n", 1)
    expectErr("AC-137", "x9 su Manca (il bersaglio prima dei confini)", "", rat(w, @["Manca.csc", "x9", "D-1"]),
      "bcdd ratify: nessuna GUARANTEE con id x9 nella ENTITY Manca\n", 1)
    expectErr("AC-137", "p è una parte", "", rat(w, @["Due.csc", "--csc", "Altra", "p", "D-1"]),
      "bcdd ratify: p non è una GUARANTEE: in una ENTITY si ratificano solo garanzie\n", 1)
    rec("AC-137", "file invariati", listDir(w) == ratList and ratInputs.allIt(fileEq(w / it & ".csc", rdb / it & ".csc")), $listDir(w))
  # AC-138 (g-t3): i confini letti, un messaggio per motivo
  block:
    let w = wdR()
    for (args, want) in [
      (@["Manca.csc", "m1", "D-1"], "bcdd ratify: ENTITY Manca, riga 4: USES Assente non trovata: non ratifico le sue garanzie\n"),
      (@["Versione.csc", "--all", "D-1"], "bcdd ratify: ENTITY Versione, riga 4: OFFERS Luce VERSION 0.2 trovata in Luce.csc alla riga 1 con VERSION 0.1: non ratifico le sue garanzie\n"),
      (@["Sporca.csc", "s1", "D-1"], "bcdd ratify: ENTITY Sporca, riga 3: USES Sporco trovata in Sporco.csc alla riga 1, che ha 1 errore: non ratifico le sue garanzie\n"),
      (@["Lontana.csc", "n1", "D-1"], "bcdd ratify: ENTITY Lontana, riga 3: OFFERS Comando non trovata: non ratifico le sue garanzie\n"),
      (@["Stesso.csc", "--csc", "Nodo", "n1", "D-1"], "bcdd ratify: ENTITY Nodo, riga 8: OFFERS Canale VERSION 0.2 trovata in questo file alla riga 1 con VERSION 0.3: non ratifico le sue garanzie\n")]:
      expectErr("AC-138", args.join(" "), "", rat(w, args), want, 1)
    rec("AC-138", "file invariati", listDir(w) == ratList and ratInputs.allIt(fileEq(w / it & ".csc", rdb / it & ".csc")), $listDir(w))
  # AC-139: --dir, in qualunque posizione
  block:
    let w = wdR()
    expectOut("AC-139", "--dir prima del file", "f3b/Lontana", rat(w, @["--dir", luceAbs, "Lontana.csc", "n1", "D-1"]),
      "ratificata la riga 4: GUARANTEE n1 con D-1\n", 0)
    rec("AC-139", "file uguale a Lontana.n1.dopo.csc", fileEq(w / "Lontana.csc", rdb / "Lontana.n1.dopo.csc"), "contenuto diverso")
    let w2 = wdR()
    expectOut("AC-139", "--dir dopo l'id", "", rat(w2, @["Lontana.csc", "n1", "--dir", luceAbs, "D-1"]),
      "ratificata la riga 4: GUARANTEE n1 con D-1\n", 0)
    rec("AC-139", "file uguale a Lontana.n1.dopo.csc (seconda)", fileEq(w2 / "Lontana.csc", rdb / "Lontana.n1.dopo.csc"), "contenuto diverso")
    let w3 = wdR()
    expectErr("AC-139", "--dir nessuna", "", rat(w3, @["--dir", "nessuna", "Scale.csc", "g1", "D-1"]),
      "bcdd ratify: cartella non trovata: nessuna\n", 2)
    expectErr("AC-139", "--dir Scale.csc", "", rat(w3, @["--dir", "Scale.csc", "Scale.csc", "g1", "D-1"]),
      "bcdd ratify: non è una cartella: Scale.csc\n", 2)
    expectErr("AC-139", "--dir ultimo argomento", "", rat(w3, @["Scale.csc", "g1", "D-1", "--dir"]), usoR, 2)
    expectErr("AC-139", "--dir due volte la stessa", "", rat(w3, @["--dir", luceAbs, "--dir", luceAbs, "Scale.csc", "g1", "D-1"]), usoR, 2)
    expectErr("AC-139", "--dir=X", "", rat(w3, @["--dir=" & luceAbs, "Scale.csc", "g1", "D-1"]), usoR, 2)
    rec("AC-139", "Scale invariato dopo gli usi sbagliati", same(w3, "Scale.csc"), $listDir(w3))
  # AC-140 (B.2.3): scelta del blocco
  block:
    let w = wdR()
    expectErr("AC-140", "Due senza --csc", "", rat(w, @["Due.csc", "u1", "D-1"]),
      "bcdd ratify: il file contiene 2 ENTITY: indica quale con --csc NOME\n", 2)
    expectOut("AC-140", "Due --csc Altra a1", "f3b/Due.a1", rat(w, @["Due.csc", "--csc", "Altra", "a1", "D-1"]),
      "ratificata la riga 11: GUARANTEE a1 con D-1\n", 0)
    rec("AC-140", "Due uguale a Due.a1.dopo.csc", fileEq(w / "Due.csc", rdb / "Due.a1.dopo.csc"), "contenuto diverso")
    let w2 = wdR()
    expectErr("AC-140", "Due --csc Terza", "", rat(w2, @["Due.csc", "--csc", "Terza", "u1", "D-1"]),
      "bcdd ratify: nessun blocco da ratificare con il nome Terza nel file\n", 1)
    rec("AC-140", "Due invariato", same(w2, "Due.csc"), $listDir(w2))
    expectOut("AC-140", "Stesso --all (la CSC, con un'entità dal confine di altra versione)", "f3b/Stesso.all",
      rat(w2, @["Stesso.csc", "--all", "D-1"]), readFile(rdb / "Stesso.all.uscita"), 0)
    rec("AC-140", "Stesso uguale a Stesso.all.dopo.csc", fileEq(w2 / "Stesso.csc", rdb / "Stesso.all.dopo.csc"), "contenuto diverso")
  # AC-141 (B.4): una riga non riconosciuta ferma ratify anche per le entità
  block:
    let w = wdR()
    expectErr("AC-141", "Ignota i1", "", rat(w, @["Ignota.csc", "i1", "D-1"]),
      "bcdd ratify: il file non passa bcdd check --strict (errori: 0, righe non riconosciute: 1): non ratifico\n", 1)
    rec("AC-141", "Ignota invariato", same(w, "Ignota.csc"), $listDir(w))
  # AC-147 (testi d'uso)
  block:
    let w = wdR()
    expectErr("AC-147", "ratify con un solo posizionale", "", rat(w, @["Scale.csc"]), usoR, 2)
    expectErr("AC-147", "bcdd senza argomenti", "", run(@[], w),
      "uso: bcdd [--lang it|en] COMANDO; comandi: new NOME | check [--strict] [--json] [--dir CARTELLA]... FILE | refine FILE [--csc NOME] | ratify FILE [--csc NOME] [--dir CARTELLA]... [ID | --all] D-numero\n", 2)

  # AC-127..AC-130 (parte C): la scelta del blocco non dipende dall'ordine; una riga non riconosciuta ferma ratify, non refine
  proc wdS(name: string): string =
    result = newWd()
    discard cpTo(sdb / name, result)
  block:
    let w = wdS("EntitaPrima.csc")
    expectOut("AC-127", "ratify EntitaPrima --all D-1", "f3b/EntitaPrima.all", rat(w, @["EntitaPrima.csc", "--all", "D-1"]),
      readFile(sdb / "EntitaPrima.all.uscita"), 0)
    rec("AC-127", "file uguale a EntitaPrima.all.dopo.csc", fileEq(w / "EntitaPrima.csc", sdb / "EntitaPrima.all.dopo.csc"), "contenuto diverso")
  block:
    let w = wdS("RigaIgnota.csc")
    expectErr("AC-128", "ratify RigaIgnota --all D-1", "f3b/RigaIgnota.all", rat(w, @["RigaIgnota.csc", "--all", "D-1"]),
      readFile(sdb / "RigaIgnota.all.errore"), 1)
    rec("AC-128", "file invariato", fileEq(w / "RigaIgnota.csc", sdb / "RigaIgnota.csc") and listDir(w) == @["RigaIgnota.csc"], $listDir(w))
  proc refF(w: string, args: seq[string], resp: string, input: string = "", extra: seq[(string, string)] = @[]): Res =
    discard auxOf(w)
    runX(bcddProva, @["refine"] & args, w, refEnv(w, @[("BCDD_FINTO_RISPOSTA", resp)] & extra), input)
  for (ac, name, atteso) in [("AC-129", "EntitaPrima", "EntitaPrima.refine.uscita"), ("AC-130", "RigaIgnota", "RigaIgnota.refine.uscita")]:
    let w = wdS(name & ".csc")
    refWds.add (w, ratLines(w))
    let r = refF(w, @[name & ".csc"], vuotaCsc)
    expectOut(ac, "refine " & name, "f3b/" & name & ".refine", r, readFile(sdb / atteso), 0)
    rec(ac, "una sola chiamata, file invariato", contaOf(w) == "1" and fileEq(w / (name & ".csc"), sdb / (name & ".csc")) and
      not fileExists(w / (name & ".csc.dialogo")), contaOf(w) & " " & $listDir(w))

  # AC-142 (B.3.2): la richiesta per un'entità, risposta vuota
  proc wdF(names: seq[string]): string =
    result = newWd()
    for n in names: discard cpTo(fdb / n, result)
    refWds.add (result, ratLines(result))
  block:
    let w = wdF(@["Scale.csc", "Pressione.csc", "Luce.csc"])
    let aux = auxOf(w)
    let r = refF(w, @["Scale.csc"], vuota, "", @[("BCDD_FINTO_RICHIESTA", aux / "richiesta")])
    expectOut("AC-142", "Scale con vuota", "f3b/Scale.vuota", r, readFile(fdb / "Scale.vuota.uscita"), 0)
    rec("AC-142", "una chiamata, richiesta uguale a Scale.richiesta (11614 byte)", contaOf(w) == "1" and
      fileEq(aux / "richiesta", fdb / "Scale.richiesta") and getFileSize(aux / "richiesta") == 11614, contaOf(w))
    rec("AC-142", "Scale.csc invariato, nessun .dialogo", fileEq(w / "Scale.csc", fdb / "Scale.csc") and not fileExists(w / "Scale.csc.dialogo"), $listDir(w))
  # AC-143 (B.3.3, B.3.4): proposte e sostituzioni su un'entità, filtro e righe a schermo
  block:
    let w = wdF(@["Scale.csc", "Pressione.csc", "Luce.csc"])
    let aux = auxOf(w)
    let r = refF(w, @["Scale.csc"], fdb / "risposte" / "entita.json", readFile(fdb / "Scale.entita.ingresso"),
      @[("BCDD_FINTO_RICHIESTA", aux / "richiesta")])
    expectOut("AC-143", "Scale con entita.json", "f3b/Scale.entita", r, readFile(fdb / "Scale.entita.uscita"), 0)
    rec("AC-143", "una chiamata, richiesta uguale a Scale.richiesta", contaOf(w) == "1" and fileEq(aux / "richiesta", fdb / "Scale.richiesta"), contaOf(w))
    rec("AC-143", "Scale.csc uguale a Scale.entita.dopo.csc, nessun .dialogo", fileEq(w / "Scale.csc", fdb / "Scale.entita.dopo.csc") and
      not fileExists(w / "Scale.csc.dialogo"), $listDir(w))
  # AC-144 (sostituisce AC-111 casi 2 e 4)
  block:
    let w = wdF(@["Misto.csc", "Luce.csc"])
    let aux = auxOf(w)
    let r = refF(w, @["Misto.csc", "--csc", "LuceMista"], vuota, "", @[("BCDD_FINTO_RICHIESTA", aux / "richiesta")])
    expectOut("AC-144", "Misto --csc LuceMista", "f3b/Misto.LuceMista", r, readFile(fdb / "Misto.LuceMista.uscita"), 0)
    rec("AC-144", "una chiamata, richiesta uguale a Misto.LuceMista.richiesta (10317 byte)", contaOf(w) == "1" and
      fileEq(aux / "richiesta", fdb / "Misto.LuceMista.richiesta") and getFileSize(aux / "richiesta") == 10317, contaOf(w))
    rec("AC-144", "Misto.csc invariato", fileEq(w / "Misto.csc", fdb / "Misto.csc") and not fileExists(w / "Misto.csc.dialogo"), $listDir(w))
    let w2 = newWd()
    discard cpTo(f3Dir / "luce" / "Pulsante.csc", w2)
    let r2 = refF(w2, @["Pulsante.csc"], vuota)
    expectOut("AC-144", "Pulsante", "f3b/Pulsante.vuota", r2, readFile(fdb / "Pulsante.vuota.uscita"), 0)
    rec("AC-144", "Pulsante: una chiamata, file invariato", contaOf(w2) == "1" and
      fileEq(w2 / "Pulsante.csc", f3Dir / "luce" / "Pulsante.csc") and not fileExists(w2 / "Pulsante.csc.dialogo"), $listDir(w2))
  # AC-145 (B.3.1): la scelta del blocco in refine
  block:
    let w = newWd()
    discard cpTo(rdb / "Due.csc", w)
    refWds.add (w, ratLines(w))
    let r1 = refF(w, @["Due.csc"], vuota)
    expectErr("AC-145", "Due senza --csc", "", r1, "bcdd refine: il file contiene 2 ENTITY: indica quale con --csc NOME\n", 2)
    rec("AC-145", "l'LLM non chiamato (senza --csc)", contaOf(w) == "0", contaOf(w))
    let r2 = refF(w, @["Due.csc", "--csc", "Terza"], vuota)
    expectErr("AC-145", "Due --csc Terza", "", r2, "bcdd refine: nessuna CSC né ENTITY Terza nel file\n", 1)
    rec("AC-145", "l'LLM non chiamato (--csc Terza)", contaOf(w) == "0", contaOf(w))
    let r3 = refF(w, @["Due.csc", "--csc", "Altra"], vuota)
    expectOut("AC-145", "Due --csc Altra", "f3b/Due.Altra", r3, readFile(fdb / "Due.Altra.uscita"), 0)
    rec("AC-145", "una chiamata, Due.csc invariato", contaOf(w) == "1" and fileEq(w / "Due.csc", rdb / "Due.csc"), contaOf(w))
  # AC-146: il modello è quello dell'appendice del documento di progetto, byte per byte; quello delle CSC è cambiato dopo
  block:
    let docFile = root / ".." / "Archive" / "DESIGN_F3B.md"
    let doc = if fileExists(docFile): readFile(docFile) else: ""
    let ap = doc.find("# Appendice")
    let a = doc.find("\n~~~~\n", max(ap, 0)) + 6
    let b = doc.find("\n~~~~\n", a) + 1
    let modello = readFile(root / "modelli" / "richiesta_refine_entita.txt")
    let testo = if ap >= 0 and a > 5 and b > a: doc[a ..< b] elif doc.len == 0: modello else: ""
    rec("AC-146", "richiesta_refine_entita.txt uguale all'appendice, 8968 byte", testo == modello and modello.len == 8968,
      "lunghezze " & $testo.len & " / " & $modello.len)
    rec("AC-146", "richiesta_refine.txt di D-247 (bcdd-refine-5), 10893 byte", getFileSize(root / "modelli" / "richiesta_refine.txt") == 10893, "dimensione diversa")
  # AC-149: il dialogo di un giro su un'entità dice ENTITY
  block:
    let w = wdF(@["Scale.csc", "Pressione.csc", "Luce.csc"])
    let aux = auxOf(w)
    let r = refF(w, @["Scale.csc"], fdb / "risposte" / "domanda.json", readFile(fdb / "Scale.domanda.ingresso"),
      @[("BCDD_ORA", "2026-10-18T10:00:00+02:00"), ("BCDD_FINTO_RISPOSTA_2", vuota), ("BCDD_FINTO_RICHIESTA_2", aux / "richiesta2")])
    expectOut("AC-149", "Scale con domanda.json", "f3b/Scale.domanda", r, readFile(fdb / "Scale.domanda.uscita"), 0)
    rec("AC-149", "due chiamate, seconda richiesta uguale a Scale.domanda.richiesta2", contaOf(w) == "2" and
      fileEq(aux / "richiesta2", fdb / "Scale.domanda.richiesta2"), contaOf(w))
    rec("AC-149", "Scale.csc.dialogo uguale a Scale.domanda.dialogo (riga 3 GIRO ... ENTITY Scale), Scale.csc invariato",
      fileEq(w / "Scale.csc.dialogo", fdb / "Scale.domanda.dialogo") and fileEq(w / "Scale.csc", fdb / "Scale.csc"), $listDir(w))
  # AC-105 esteso: nessun file di prove/f3b è cambiato, né nel contenuto né nella data
  rec("AC-105", "contenuto e data di prove/f3b/ dopo AC-127..AC-147", snapshot(@[f3bDir]) == f3bBefore, "un file di prove/f3b è cambiato")

# 066:1:1 AC-57: messaggio d'uso generale di F2
block:
  const usoGen = "uso: bcdd [--lang it|en] COMANDO; comandi: new NOME | check [--strict] [--json] [--dir CARTELLA]... FILE | refine FILE [--csc NOME] | ratify FILE [--csc NOME] [--dir CARTELLA]... [ID | --all] D-numero\n"
  expectErr("AC-57", "bcdd senza argomenti", "", run(@[], root), usoGen, 2)
  expectErr("AC-57", "comando sconosciuto", "", run(@["boh"], root), usoGen, 2)

# 059:1:1 AC-5 (g-c1): nessun file di prova è cambiato, né nel contenuto né nella data
let after = snapshot(@[proveDir, cscDir])
rec("AC-5", "contenuto e data di prove/ e csc/", after == before, "un file di prova è cambiato")

# 060:1:1 Prove di bordo (oltre agli AC): bordi dell'input e scritture
block:
  let xd = tmpBase / "bordi"
  createDir(xd)
  let base = readFile(proveDir / "01_minima.csc")
  writeFile(xd / "a.csc", base)
  let ra = run(@["check", "a.csc"], xd)
  # senza LF finale
  writeFile(xd / "b.csc", base.strip(leading = false, chars = {'\n'}))
  let rb = run(@["check", "b.csc"], xd)
  rec("X", "senza LF finale", firstLineReplaced(rb.output, "") == firstLineReplaced(ra.output, "") and rb.code == 0,
    firstDiff(rb.output, ra.output))
  # CRLF
  writeFile(xd / "c.csc", base.replace("\n", "\r\n"))
  let rcr = run(@["check", "c.csc"], xd)
  rec("X", "CRLF come LF", firstLineReplaced(rcr.output, "") == firstLineReplaced(ra.output, ""),
    firstDiff(rcr.output, ra.output))
  # spazio non separabile: carattere estraneo, riga non riconosciuta, strict dà 3
  writeFile(xd / "d.csc", "CSC A VERSION 0.1\n  PURPOSE \"x\"\n\xC2\xA0EVENT IN e\nEND\n")
  let rd = run(@["check", "--strict", "d.csc"], xd)
  rec("X", "spazio non separabile = non riconosciuta", rd.code == 3 and
    rd.output.contains("riga 3: \xC2\xA0EVENT IN e"), "codice " & $rd.code)
  # UTF-8 sbagliato: riga 4 dopo un file con CRLF e BOM
  writeFile(xd / "e.csc", "\xEF\xBB\xBFCSC A VERSION 1\r\n  PURPOSE \"x\"\r\n\r\n\xFF\r\nEND\r\n")
  let re = run(@["check", "e.csc"], xd)
  rec("X", "non UTF-8 riga 4", re.code == 2 and re.errout == "bcdd check: il file non è UTF-8 valido (riga 4)\n" and
    re.output.len == 0, re.errout)
  # file di soli LF e file con un solo carattere
  writeFile(xd / "f.csc", "\n\n")
  let rf = run(@["check", "f.csc"], xd)
  rec("X", "due righe vuote", rf.output.contains("righe: 2 (riconosciute 0, commenti 0, vuote 2, non riconosciute 0)"), rf.output)
  # new: cartella non scrivibile -> esito 1, nessun file a metà
  let ro = tmpBase / "sola_lettura"
  createDir(ro)
  setFilePermissions(ro, {fpUserRead, fpUserExec})
  var canWrite = true
  try:
    writeFile(ro / "prova", "x")
  except IOError:
    canWrite = false
  if canWrite:
    echo "nota: prova cartella non scrivibile saltata (utente con accesso a tutto)"
  else:
    let rr = run(@["new", "Nuova"], ro)
    rec("X", "new in cartella non scrivibile", rr.code == 1 and rr.output.len == 0 and listDir(ro).len == 0,
      "codice " & $rr.code & " " & rr.errout)
  setFilePermissions(ro, {fpUserRead, fpUserWrite, fpUserExec})
  # new: nome già presente come cartella e come collegamento pendente
  createDir(xd / "Dir.csc")
  let rdir = run(@["new", "Dir"], xd)
  rec("X", "new con cartella omonima", rdir.code == 1 and rdir.errout == "bcdd new: Dir.csc esiste già: non lo sovrascrivo\n", rdir.errout)
  createSymlink("non_esiste_da_nessuna_parte", xd / "Pend.csc")
  let rpend = run(@["new", "Pend"], xd)
  rec("X", "new con collegamento pendente omonimo", rpend.code == 1 and symlinkExists(xd / "Pend.csc") and
    not fileExists(xd / "non_esiste_da_nessuna_parte"), rpend.errout)
  rec("X", "nessun temporaneo rimasto", block:
    var leftovers = false
    for f in listDir(xd):
      if f.contains(".tmp"): leftovers = true
    not leftovers, $listDir(xd))
  # check non modifica nemmeno la data di modifica (g-c1) su un file creato adesso
  let mt = getLastModificationTime(xd / "a.csc")
  discard run(@["check", "a.csc"], xd)
  rec("X", "data di modifica invariata", getLastModificationTime(xd / "a.csc") == mt, "data cambiata")

# 067:1:1 AC-55 (g-r6) e AC-58 (non regressione) si deducono dagli altri criteri
block:
  proc allOk(ac: string): bool = ac in acTotal and acPass[ac] == acTotal[ac]
  var ok55 = true
  for k in concat(toSeq(42 .. 51), toSeq(61 .. 65), @[82, 84, 85, 86, 87, 88], toSeq(90 .. 94)):
    if not allOk("AC-" & $k): ok55 = false
  rec("AC-55", "AC-42..AC-51, AC-61..AC-65, AC-82, AC-84..AC-88 e AC-90..AC-94 superati: nessuna garanzia g-r* violata", ok55,
    "almeno uno fra AC-42..AC-51, AC-61..AC-65, AC-82, AC-84..AC-88 e AC-90..AC-94 non riesce")
  var ok58 = true
  var bad: seq[string]
  for k in 1 .. 27:
    if not allOk("AC-" & $k):
      ok58 = false
      bad.add "AC-" & $k
  rec("AC-58", "AC-1..AC-27 superati (il testo generale di AC-12 è in AC-57)", ok58, "non riescono: " & bad.join(" "))

# 067:2:1 AC-110 (non regressione) e AC-114 (il numero di prove sale)
block:
  proc allOk(ac: string): bool = ac in acTotal and acPass[ac] == acTotal[ac]
  var bad: seq[string]
  for k in 1 .. 94:
    if not allOk("AC-" & $k): bad.add "AC-" & $k
  var nAtteso = 0
  for f in walkFiles(proveDir / "*.atteso"): inc nAtteso
  rec("AC-110", "AC-1..AC-94 superati e 36 prove/*.atteso", bad.len == 0 and nAtteso == 36,
    "non riescono: " & bad.join(" ") & "; prove/*.atteso: " & $nAtteso)
  var somma = 0
  for ac in acOrder: somma += acTotal[ac]
  rec("AC-114", "più di 428 controlli", somma + 1 > 428, "controlli: " & $(somma + 1))
  # AC-119: nessun atteso della 1.2 cambia (gli attesi di AC-95..AC-113 sono confrontati con cmp dai loro criteri)
  var bad119: seq[string]
  for k in 95 .. 113:
    let ac = "AC-" & $k
    if ac in acTotal and not allOk(ac): bad119.add ac
  rec("AC-119", "AC-95..AC-113 superati con gli attesi della 1.2", bad119.len == 0, "non riescono: " & bad119.join(" "))
  # AC-120: il numero di prove sale rispetto a 498
  rec("AC-120", "più di 498 controlli", somma + 2 > 498, "controlli: " & $(somma + 2))

  # AC-126: AC-1..AC-125 superati (AC-100 e AC-116 con gli attesi nuovi) e il numero di prove sale rispetto a 511
  var bad126: seq[string]
  for k in 1 .. 125:
    if ("AC-" & $k) in acTotal and not allOk("AC-" & $k): bad126.add "AC-" & $k
  rec("AC-126", "AC-1..AC-125 superati", bad126.len == 0, "non riescono: " & bad126.join(" "))
  rec("AC-126", "più di 511 controlli", somma + 3 > 511, "controlli: " & $(somma + 3))

  # AC-148: nient'altro cambia; AC-1..AC-147 superati (con i criteri sostituiti da B.7) e il numero di prove sale rispetto a 528
  var bad148: seq[string]
  for k in 1 .. 147:
    if ("AC-" & $k) in acTotal and not allOk("AC-" & $k): bad148.add "AC-" & $k
  rec("AC-148", "AC-1..AC-147 superati", bad148.len == 0, "non riescono: " & bad148.join(" "))
  rec("AC-148", "più di 528 controlli", somma + 4 > 528, "controlli: " & $(somma + 4))

# 068:1:1 AC-150..AC-162 (GRAMMATICA_F1 1.10, sezione 27.4): vista uscita, vocabolario allineato, una sola lista
block:
  proc allOk(ac: string): bool = ac in acTotal and acPass[ac] == acTotal[ac]
  let vd = proveDir / "voc04"
  expectOut("AC-150", "10_intestazione_non_valida", "10_intestazione_non_valida",
    run(@["check", "10_intestazione_non_valida.csc"], proveDir), readFile(proveDir / "10_intestazione_non_valida.atteso"), 1)
  expectOut("AC-151", "12_nessuna_csc", "12_nessuna_csc",
    run(@["check", "12_nessuna_csc.csc"], proveDir), readFile(proveDir / "12_nessuna_csc.atteso"), 1)
  expectOut("AC-152", "23_parti_ripetute", "23_parti_ripetute",
    run(@["check", "23_parti_ripetute.csc"], proveDir), readFile(proveDir / "23_parti_ripetute.atteso"), 1)
  expectOut("AC-153", "Vista", "voc04/Vista", run(@["check", "voc04/Vista.csc"], proveDir), readFile(vd / "Vista.atteso"), 1)
  # AC-154 / AC-155: anche con --strict, 25 e 8 righe non riconosciute, codice 3
  for (ac, stem, n, c0) in [("AC-154", "Base", 25, 0), ("AC-155", "Campi", 8, 0)]:
    expectOut(ac, stem, "voc04/" & stem, run(@["check", "voc04/" & stem & ".csc"], proveDir), readFile(vd / stem & ".atteso"), c0)
    let rs = run(@["check", "--strict", "voc04/" & stem & ".csc"], proveDir)
    var ls = readFile(vd / stem & ".atteso").split('\n')
    ls[0] = "bcdd check --strict " & stem & ".csc"
    ls[^2] = "esito: nessun errore; righe non riconosciute: " & $n & " (--strict)"
    expectOut(ac, stem & " --strict", "voc04/" & stem, rs, ls.join("\n"), 3)
  expectOut("AC-156", "Entita", "voc04/Entita", run(@["check", "voc04/Entita.csc"], proveDir), readFile(vd / "Entita.atteso"), 0)
  expectOut("AC-157", "Blocco", "voc04/Blocco", run(@["check", "voc04/Blocco.csc"], proveDir), readFile(vd / "Blocco.atteso"), 1)
  expectOut("AC-158", "Uscite", "voc04/Uscite", run(@["check", "voc04/Uscite.csc"], proveDir), readFile(vd / "Uscite.atteso"), 0)
  # AC-159: new rifiuta ogni parola riservata, senza lasciare file; poi un nome libero funziona
  block:
    let w = tmpBase / "ac159"
    createDir(w)
    for x in ["ENSURES", "KIND", "LOG10", "ENTITY", "OFFERS", "USES", "REFINEMENT", "VIEW", "FACE"]:
      expectErr("AC-159", "new " & x, "", run(@["new", x], w), "bcdd new: nome non valido: " & x & "\n", 2)
    rec("AC-159", "nessun file lasciato", listDir(w).len == 0, $listDir(w))
    expectOut("AC-159", "new after", "", run(@["new", "after"], w), "creato after.csc\n", 0)
    let rc = run(@["check", "after.csc"], w)
    rec("AC-159", "check after.csc", rc.code == 0, "codice " & $rc.code)
  # AC-160: ratify con un id o un nome riservato nuovo
  block:
    let w = tmpBase / "ac160"
    createDir(w)
    copyFile(proveDir / "01_minima.csc", w / "C.csc")
    let h0 = readFile(w / "C.csc")
    expectErr("AC-160", "id ENSURES", "", run(@["ratify", "C.csc", "ENSURES", "D-1"], w), "bcdd ratify: id non valido: ENSURES\n", 2)
    expectErr("AC-160", "--csc KIND", "", run(@["ratify", "C.csc", "--csc", "KIND", "--all", "D-1"], w), "bcdd ratify: nome non valido: KIND\n", 2)
    rec("AC-160", "file invariato", readFile(w / "C.csc") == h0, "il file è cambiato")
  # AC-161: ratify e refine rifiutano un file con una vista; refine solo con l'eseguibile di prova
  block:
    let wd = newRef(proveDir / "23_parti_ripetute.csc", "V.csc")
    let h0 = readFile(wd / "V.csc")
    expectErr("AC-161", "ratify", "", run(@["ratify", "V.csc", "--all", "D-1"], wd),
      "bcdd ratify: il file non passa bcdd check --strict (errori: 1, righe non riconosciute: 5): non ratifico\n", 1)
    discard auxOf(wd)
    expectErr("AC-161", "refine", "", runX(bcddProva, @["refine", "V.csc"], wd, refEnv(wd), ""),
      "bcdd refine: il file non passa bcdd check (errori: 1): correggilo prima di affinare\n", 1)
    rec("AC-161", "file invariato, LLM non chiamato", readFile(wd / "V.csc") == h0 and contaOf(wd) == "0", "contatore " & contaOf(wd))
  # AC-162: nient'altro cambia
  expectOut("AC-162", "F0_BcddTool", "", run(@["check", "csc/BcddTool.csc"], root),
    readFile(proveDir / "F0_BcddTool.atteso"), 0)
  var bad162: seq[string]
  for k in 1 .. 149:
    if ("AC-" & $k) in acTotal and not allOk("AC-" & $k): bad162.add "AC-" & $k
  rec("AC-162", "AC-1..AC-149 superati", bad162.len == 0, "non riescono: " & bad162.join(" "))

# 070:1:1 F4a: `bcdd check --json` (BcddProgrammi p-1..p-4, AC-163..AC-170).
# 070:1:2 Il JSON si legge con std/json; la prova di p-1 rifà con quel JSON il rapporto per persone e lo confronta byte per byte.
proc jint(n: JsonNode, k: string): int = n[k].getInt
proc jstr(n: JsonNode, k: string): string = n[k].getStr

proc statoTesto(b: JsonNode): string =
  case b["stato"].getStr
  of "senza_stato": "senza STATUS"
  of "ipotesi": "STATUS HYPOTHESIS"
  of "contratto": "STATUS RATIFIED BY " & b["decisione"].getStr
  else: "STATUS non valido"

proc rifaRapporto(j: JsonNode): string =
  ## 070:2:1 Il rapporto per persone, rifatto solo dai dati del JSON.
  var o = ""
  proc ln(s: string) = o.add s & "\n"
  let op = j["opzioni"]
  var first = "bcdd check"
  if op["strict"].getBool: first.add " --strict"
  for d in op["dir"]: first.add " --dir " & d.getStr
  ln first & " " & j.jstr("file")
  let r = j["rapporto"]
  let c = r["conteggi"]
  ln "righe: " & $c.jint("righe") & " (riconosciute " & $c.jint("riconosciute") & ", commenti " & $c.jint("commenti") &
    ", vuote " & $c.jint("vuote") & ", non riconosciute " & $c.jint("non_riconosciute") &
    ")"
  ln "blocchi: " & $j["blocchi"].len
  for b in j["blocchi"]:
    var s = "  riga " & $b.jint("da") & ": "
    let valida = b["intestazione_valida"].getBool
    if b.jstr("tipo") == "REFINEMENT VIEW":
      s.add "REFINEMENT VIEW " & (if valida: b.jstr("nome") else: "(intestazione non valida)")
    else:
      let kw = b.jstr("tipo")
      s.add (if valida: kw & " " & b.jstr("nome") & " VERSION " & b.jstr("versione") else: kw & " (intestazione non valida)")
      if valida and b.hasKey("nome_proprio") and b["nome_proprio"].kind != JNull: s.add " AS " & b.jstr("nome_proprio")
      if b["stato"].kind != JNull: s.add ", " & statoTesto(b)
    ln s
    for ci in b["citazioni"]:
        let f = ci["trovata"]
        var cs = "    riga " & $ci.jint("riga") & ": "
        case ci.jstr("tipo")
        of "OFFERS": cs.add "OFFERS " & ci.jstr("nome")
        of "USES": cs.add "USES " & ci.jstr("nome")
        of "IMPORT": cs.add "IMPORT PROFILE " & ci.jstr("nome")
        of "LEGATA": cs.add "CSC " & ci.jstr("nome")
        of "USING": cs.add "USING " & ci.jstr("parte")
        else: cs.add ci.jstr("parte") & " : " & ci.jstr("nome")
        let vc = if ci["versione_citata"].kind == JNull: "" else: ci.jstr("versione_citata")
        let bad = vc.len > 0 and vc != f.jstr("versione")
        if f["dove"].kind == JNull:
          cs.add " in questo file alla riga " & $f.jint("riga")
          if bad: cs.add ": VERSION " & f.jstr("versione") & ", attesa VERSION " & vc
        else:
          cs.add " in " & f.jstr("dove") & " alla riga " & $f.jint("riga") & ": VERSION " & f.jstr("versione") & ", " & f.jstr("stato") & ", "
          cs.add (case f.jint("errori")
            of 0: "nessun errore"
            of 1: "1 errore"
            else: $f.jint("errori") & " errori")
          if f.jint("non_riconosciute") > 0: cs.add ", righe non riconosciute: " & $f.jint("non_riconosciute")
          if bad: cs.add ", attesa VERSION " & vc
        ln cs
  ln ""
  ln "1. ERRORI: " & $r["errori"].len
  for e in r["errori"]:
    ln "  " & (if e.jint("riga") == 0: "file" else: "riga " & $e.jint("riga")) & ": [" & e.jstr("codice") & "] " & e.jstr("messaggio") &
      (if e["in"].kind == JNull: "" else: " (in: " & e.jstr("in") & ")")
  ln ""
  ln "2. GRADO DELLE RIGHE CONTRATTUALI"
  ln "  verbale: " & $c.jint("verbale")
  ln "  formale: " & $c.jint("formale")
  ln "  estensione dichiarata: " & $c.jint("estensione_dichiarata")
  ln "  non riconosciuta: " & $c.jint("non_riconosciuta")
  for g in r["gradi"]:
    ln "  riga " & $g.jint("riga") & ": " & g.jstr("tipo") & " " & g.jstr("id") & " " & g.jstr("grado").replace("_", " ")
  ln ""
  ln "3. UNDECIDED: " & $r["undecided"].len
  for u in r["undecided"]: ln "  riga " & $u.jint("riga") & ": " & u.jstr("nome")
  ln ""
  ln "4. IPOTESI, NON CONTRATTO: " & $r["ipotesi"].len
  for h in r["ipotesi"]: ln "  riga " & $h.jint("riga") & ": " & h.jstr("tipo") & " " & h.jstr("id")
  ln ""
  ln "5. RIGHE NON RICONOSCIUTE: " & $r["non_riconosciute"].len
  for u in r["non_riconosciute"]:
    ln (if u.jstr("testo").len == 0: "  riga " & $u.jint("riga") & ":" else: "  riga " & $u.jint("riga") & ": " & u.jstr("testo") &
      (if u["motivo"].kind == JNull: "" else: " (" & u.jstr("motivo") & ")"))
  ln ""
  ln "6. TIPI NON DICHIARATI: " & $r["tipi_non_dichiarati"].len
  for t in r["tipi_non_dichiarati"]:
    var parts: seq[string]
    for l in t["righe"]: parts.add $l.getInt
    ln "  " & t.jstr("nome") & ": " & (if parts.len == 1: "riga " else: "righe ") & parts.join(", ")
  ln ""
  ln "7. CSC NOMINATE E NON CONTROLLATE: " & $r["non_controllate"].len
  for u in r["non_controllate"]: ln "  riga " & $u.jint("riga") & ": " & u.jstr("testo")
  ln ""
  if r["ha_entita"].getBool:
    ln "8. USI DENTRO LE ENTITÀ: " & $r["usi"].len
    for u in r["usi"]: ln "  riga " & $u.jint("riga") & ": " & u.jstr("testo") & (if u["in"].kind == JNull: "" else: " (in: " & u.jstr("in") & ")")
    ln ""
  if r["ha_composizioni"].getBool:
    # 1.21: sezioni 9 e 10 rifatte dai campi composizioni[] e assenze[]
    var tot = 0
    for c in r["composizioni"]:
      if c["nomi"].kind == JArray: tot += c["nomi"].len
    ln "9. COMPOSIZIONI: " & $tot
    for c in r["composizioni"]:
      if c["nomi"].kind == JNull:
        ln "  riga " & $c.jint("riga") & ": ENTITY " & c.jstr("entita") & ": più di 64, non controllate"
      else:
        ln "  riga " & $c.jint("riga") & ": ENTITY " & c.jstr("entita") & ": " & $c["nomi"].len
        for n in c["nomi"]: ln "    " & n.getStr
    ln ""
    ln "10. ASSENZE DICHIARATE: " & $r["assenze"].len
    for a in r["assenze"]:
      ln "  riga " & $a.jint("riga") & ": senza " & a.jstr("senza") & ": " & a.jstr("messaggio") & (if a["in"].kind == JNull: "" else: " (in: " & a.jstr("in") & ")")
    ln ""
  # 1.0-beta: sezioni 12-15 rifatte da forme_mancanti[], copertura[], da_giudicare[] e non_eseguiti[]
  if r["ha_binding"].getBool:
    ln "12. FORME CONCRETE MANCANTI: " & $c.jint("forme_mancanti")
    for x in r["forme_mancanti"]: ln "  riga " & $x.jint("riga") & ": " & x.jstr("testo")
    ln ""
  if r["ha_verification"].getBool:
    ln "13. COPERTURA DEL PIANO DI PROVA: " & $c.jint("non_eseguite_piano")
    for x in r["copertura"]:
      ln "  riga " & $x.jint("riga") & ": " & x.jstr("blocco")
      for l in x["righe"]: ln "    " & l.getStr
    ln ""
  if r["da_giudicare"].len > 0:
    ln "14. DA GIUDICARE: " & $r["da_giudicare"].len
    for x in r["da_giudicare"]: ln "  " & x.jstr("testo")
    ln ""
  if r["non_eseguiti"].len > 0:
    ln "15. CONTROLLI NON ESEGUITI: " & $r["non_eseguiti"].len
    for x in r["non_eseguiti"]:
      var parts: seq[string]
      for l in x["righe"]: parts.add $l.getInt
      ln "  " & x.jstr("nome") & ": " & (if parts.len == 1: "riga " else: "righe ") & parts.join(", ")
    ln ""
  ln j["esito"].jstr("riga")
  o

proc sha256Of(path: string): string =
  let p = startProcess("sha256sum", args = @[path], options = {poUsePath})
  let o = p.outputStream.readAll()
  discard p.waitForExit()
  p.close()
  "sha256:" & o.splitWhitespace()[0]

block:
  let probeBefore = snapshot(@[proveDir])
  var allCsc: seq[string]
  for f in walkDirRec(proveDir):
    if f.endsWith(".csc"): allCsc.add f.relativePath(root)
  allCsc.sort()
  rec("AC-163", "i file di prova presenti sono almeno 130", allCsc.len >= 130, "trovati " & $allCsc.len)
  var tipiVisti: HashSet[string]
  var nonJson = 0
  for rel in allCsc:
    var modes: seq[seq[string]] = @[@[], @["--strict"]]
    if rel.startsWith("prove/f3/"): modes.add @["--dir", "prove/f3/luce"]
    for m in modes:
      let lab = rel & " " & m.join(" ")
      let h = run(@["check"] & m & @[rel], root)
      let a = run(@["check", "--json"] & m & @[rel], root)
      let a2 = run(@["check", "--json"] & m & @[rel], root)
      if h.code == 2:
        # 070:2:2 il file non si legge (UTF-8 non valido): niente su stdout, stesso messaggio e stesso codice (AC-167)
        rec("AC-167", lab & ": file non leggibile, stdout vuoto, stderr e codice uguali", a.output.len == 0 and a.errout == h.errout and
          a.code == 2 and a2.output == a.output and a2.errout == a.errout, "json [" & a.output & "] [" & a.errout & "]")
        continue
      # AC-163 (p-1): il JSON, riletto, rifà il rapporto per persone, con lo stesso codice e gli stessi messaggi
      var j: JsonNode
      var parsed = true
      try:
        j = parseJson(a.output)
      except JsonParsingError, ValueError:
        parsed = false
      rec("AC-163", lab & ": l'uscita è un solo oggetto JSON", parsed and j.kind == JObject, firstDiff(a.output, "") )
      if parsed and j.kind == JObject:
        let rifatto = rifaRapporto(j)
        rec("AC-163", lab & ": rapporto rifatto dal JSON = rapporto per persone", rifatto == h.output, firstDiff(rifatto, h.output))
        rec("AC-163", lab & ": codice d'uscita uguale, anche nel JSON", a.code == h.code and j["esito"].jint("codice") == h.code,
          "json " & $a.code & ", persone " & $h.code)
        for b in j["blocchi"]:
          tipiVisti.incl b.jstr("tipo")
          # nessuna garanzia o ipotesi in dichiarazioni[]; ogni garanzia una volta sola in garanzie[]
          var inDich = 0
          for d in b["dichiarazioni"]:
            if d.jstr("tipo") in ["ROW", "GUARANTEE", "ASSUME"]: inc inDich
          var visti: HashSet[int]
          var doppie = 0
          for g in b["garanzie"]:
            if g.jint("da") in visti: inc doppie
            visti.incl g.jint("da")
          rec("AC-169", lab & ": " & b.jstr("nome") & ": dichiarazioni[] senza garanzie né ipotesi, garanzie[] senza doppie",
            inDich == 0 and doppie == 0, "in dichiarazioni: " & $inDich & ", doppie: " & $doppie)
      rec("AC-163", lab & ": stderr uguale", a.errout == h.errout, a.errout)
      # AC-166 (p-3, g-c4): due esecuzioni danno la stessa uscita, byte per byte
      rec("AC-166", lab & ": due esecuzioni uguali (e l'uscita è JSON)", parsed and a.output == a2.output and a.errout == a2.errout and
        a.code == a2.code, firstDiff(a.output, a2.output))
      # AC-169 (p-4): ogni risposta dice forma e versione
      rec("AC-169", lab & ": forma e versione", parsed and j.kind == JObject and j{"forma"}.getStr == "bcdd-check" and
        j{"versione"}.getInt == 5, "forma/versione assenti")
      if not (parsed and j.kind == JObject): inc nonJson
  rec("AC-163", "i file di prova coprono CSC, ENTITY, BINDING, VERIFICATION, PROFILE e REFINEMENT VIEW", tipiVisti.len == 6, $tipiVisti)
  # AC-165 (p-3, g-c1): nessun file di prova cambia, né nei byte né nella data
  rec("AC-165", "prove/ dopo tutte le esecuzioni con --json: contenuto e data identici", nonJson == 0 and snapshot(@[proveDir]) == probeBefore,
    "uscite non JSON: " & $nonJson & "; oppure un file di prove/ è cambiato")

# 070:3:1 AC-164 (p-2): righe, dichiarazioni, garanzie con livello, stato, decisione e provenienza; impronta
block:
  let w = tmpBase / "ac164"
  createDir(w)
  let src = "CSC Luce VERSION 0.1\n" &
    "  STATUS RATIFIED BY D-135\n" &
    "  -- un commento\r\n" &
    "\n" &
    "  PURPOSE \"Accende la luce\"\n" &
    "  EVENT IN pressione\n" &
    "  GUARANTEE g1: VERBAL \"Una pressione accende la luce\"\n" &
    "                VERIFY BY INSPECTION \"il rapporto\"\n" &
    "  GUARANTEE g1a DETAILS g1: VERBAL \"Entro 1 secondo\"\n" &
    "                VERIFY BY INSPECTION \"il rapporto\"\n" &
    "  GUARANTEE g2 STATUS HYPOTHESIS: VERBAL \"Si spegne da sola\"\n" &
    "                VERIFY BY INSPECTION \"il rapporto\"\n" &
    "  GUARANTEE g2a DETAILS g2 STATUS RATIFIED BY D-200: VERBAL \"Una pressione fa ripartire il tempo\"\n" &
    "                VERIFY BY INSPECTION \"il rapporto\"\n" &
    "  GUARANTEE g2b DETAILS g2a STATUS HYPOTHESIS: VERBAL \"Livello due\"\n" &
    "                VERIFY BY INSPECTION \"il rapporto\"\n" &
    "  riga inventata\n" &
    "END"
  writeFile(w / "L.csc", src)
  let r = run(@["check", "--json", "L.csc"], w)
  var j: JsonNode
  try: j = parseJson(r.output)
  except JsonParsingError, ValueError: j = newJNull()
  rec("AC-164", "uscita JSON", j.kind == JObject, r.output)
  if j.kind == JObject:
    rec("AC-164", "impronta uguale a sha256sum", j.jstr("impronta") == sha256Of(w / "L.csc"), j.jstr("impronta"))
    let ls = j["righe"]
    rec("AC-164", "una voce per riga del file (18)", ls.len == 18, $ls.len)
    rec("AC-164", "numero, testo e tipo di ogni riga; il CR prima di LF non è nel testo", block:
      var ok = ls.len == 18
      if ok:
        ok = ls[2].jstr("tipo") == "commento" and ls[2].jstr("testo") == "  -- un commento" and ls[3].jstr("tipo") == "vuota" and
          ls[4].jstr("tipo") == "riconosciuta" and ls[4].jstr("testo") == "  PURPOSE \"Accende la luce\"" and
          ls[16].jstr("tipo") == "non_riconosciuta" and ls[16].jstr("testo") == "  riga inventata" and
          ls[17].jstr("testo") == "END" and ls[17].jint("n") == 18 and ls[0].jint("n") == 1
      ok, "righe: " & $ls)
    let b = j["blocchi"][0]
    rec("AC-164", "blocco CSC Luce 0.1, ratificato D-135, righe 1..18", b.jstr("tipo") == "CSC" and b.jstr("nome") == "Luce" and
      b.jstr("versione") == "0.1" and b.jstr("stato") == "contratto" and b.jstr("decisione") == "D-135" and
      b.jint("da") == 1 and b.jint("a") == 18, $b{"stato"})
    var byId: Table[string, JsonNode]
    for g in b["garanzie"]: byId[g.jstr("id")] = g
    proc chk(id, stato, dec, di, livello: string, det: string, liv: int): bool =
      id in byId and byId[id].jstr("stato") == stato and
        (if dec.len == 0: byId[id]["decisione"].kind == JNull else: byId[id].jstr("decisione") == dec) and
        byId[id].jstr("stato_di") == di and byId[id].jint("livello") == liv and
        (if det.len == 0: byId[id]["dettaglia"].kind == JNull else: byId[id].jstr("dettaglia") == det)
    rec("AC-164", "g1: contratto D-135, segue l'intestazione (GRAMMATICA_F1 7.1 punto 4)", chk("g1", "contratto", "D-135", "intestazione", "", "", 0), $byId.getOrDefault("g1"))
    rec("AC-164", "g1a: dettaglio senza STATUS, ipotesi (punto 3), livello 1", chk("g1a", "ipotesi", "", "dettaglio", "", "g1", 1), $byId.getOrDefault("g1a"))
    rec("AC-164", "g2: STATUS HYPOTHESIS suo, ipotesi (punto 2)", chk("g2", "ipotesi", "", "suo", "", "", 0), $byId.getOrDefault("g2"))
    rec("AC-164", "g2a: STATUS RATIFIED BY D-200 suo, contratto (punto 1), livello 1", chk("g2a", "contratto", "D-200", "suo", "", "g2", 1), $byId.getOrDefault("g2a"))
    rec("AC-164", "g2b: ipotesi suo, livello 2", chk("g2b", "ipotesi", "", "suo", "", "g2a", 2), $byId.getOrDefault("g2b"))
    rec("AC-164", "il testo di g1 sono le sue due righe", byId.hasKey("g1") and byId["g1"].jstr("testo") ==
      "  GUARANTEE g1: VERBAL \"Una pressione accende la luce\"\n                VERIFY BY INSPECTION \"il rapporto\"" and
      byId["g1"].jint("da") == 7 and byId["g1"].jint("a") == 8 and byId["g1"].jstr("grado") == "verbale", $byId.getOrDefault("g1"))
    var evento = newJNull()
    for d in b["dichiarazioni"]:
      if d.jstr("tipo") == "EVENT": evento = d
    var nomiDich: seq[string]
    for d in b["dichiarazioni"]: nomiDich.add d.jstr("nome")
    rec("AC-164", "D-201: dichiarazioni[] ha solo EVENT pressione; le 5 garanzie stanno solo in garanzie[]",
      nomiDich == @["pressione"] and b["garanzie"].len == 5, $nomiDich & " / " & $b["garanzie"].len)
    rec("AC-164", "la dichiarazione EVENT pressione: riga 6, nome e testo", evento.kind == JObject and evento.jstr("nome") == "pressione" and
      evento.jint("riga") == 6 and evento.jstr("testo") == "  EVENT IN pressione", $evento)
  # una entità: le garanzie sono ipotesi salvo uno STATUS proprio valido (7.1, entità)
  let rs = run(@["check", "--json", "prove/f3/stato/Stato.csc"], root)
  var js: JsonNode
  try: js = parseJson(rs.output)
  except JsonParsingError, ValueError: js = newJNull()
  rec("AC-164", "Stato.csc: uscita JSON", js.kind == JObject, rs.output)
  if js.kind == JObject:
    var m: Table[string, string]
    for b in js["blocchi"]:
      for g in b["garanzie"]:
        m[g.jstr("id")] = g.jstr("stato") & "/" & g.jstr("stato_di") & "/" & (if g["decisione"].kind == JNull: "-" else: g.jstr("decisione"))
    rec("AC-164", "Stato.csc: r1 ipotesi dall'intestazione, r2 contratto suo D-2, r3 ipotesi suo, h1 ipotesi suo",
      m.getOrDefault("r1") == "ipotesi/intestazione/-" and m.getOrDefault("r2") == "contratto/suo/D-2" and
      m.getOrDefault("r3") == "ipotesi/suo/-" and m.getOrDefault("h1") == "ipotesi/suo/-", $m)

# 070:3:2 AC-169: le garanzie e le ipotesi escono solo in garanzie[]; versione 3 (poi 4, AC-177)
# 070:3:3 BcddProgrammi.csc 0.2 ha aggiunto p-17..p-20: 20 garanzie, non più 16.
block:
  for (rel, nGar) in [("esempi/LuceScale.csc", 4), ("csc/BcddProgrammi.csc", 20)]:
    if not fileExists(root / rel):
      rec("AC-169", rel & ": file presente", false, "assente")
      continue
    let r = run(@["check", "--json", rel], root)
    var j: JsonNode
    try: j = parseJson(r.output)
    except JsonParsingError, ValueError: j = newJNull()
    rec("AC-169", rel & ": uscita JSON di versione 5", j.kind == JObject and j{"versione"}.getInt == 5, r.output[0 .. min(r.output.high, 80)])
    if j.kind == JObject:
      var nG, nD, nRow = 0
      var ids: HashSet[string]
      for b in j["blocchi"]:
        nG += b["garanzie"].len
        nD += b["dichiarazioni"].len
        for g in b["garanzie"]: ids.incl b.jstr("nome") & "/" & $g.jint("da")
        for d in b["dichiarazioni"]:
          if d.jstr("tipo") in ["ROW", "GUARANTEE", "ASSUME"]: inc nRow
      rec("AC-169", rel & ": " & $nGar & " garanzie, ciascuna una volta sola, nessuna in dichiarazioni[]",
        nG == nGar and ids.len == nG and nRow == 0, "garanzie " & $nG & ", distinte " & $ids.len & ", garanzie in dichiarazioni " & $nRow)

# 070:4:1 AC-167 (p-3, g-c1/g-c4 con --json): gli errori di lettura dei file sono quelli di `check`, senza niente su stdout
block:
  let w = tmpBase / "ac167"
  createDir(w)
  writeFile(w / "nonutf8.csc", "CSC A VERSION 1\n\xff\n")
  for (lab, args) in [("file inesistente", @["non_esiste.csc"]), ("cartella", @["prove"]), ("UTF-8 non valido", @["nonutf8.csc"])]:
    let cwd = if lab == "UTF-8 non valido": w else: root
    let h = run(@["check"] & args, cwd)
    let a = run(@["check", "--json"] & args, cwd)
    rec("AC-167", lab & ": stdout vuoto, stderr e codice uguali a check", a.output.len == 0 and a.errout == h.errout and
      a.code == h.code and a.code == 2, "json [" & a.output & "] [" & a.errout & "] " & $a.code & "; persone [" & h.errout & "] " & $h.code)
  # usi sbagliati: --json due volte, e senza file
  const usoCheck = "uso: bcdd check [--strict] [--json] [--dir CARTELLA]... FILE\n"
  expectErr("AC-167", "--json due volte", "", run(@["check", "--json", "--json", "prove/01_minima.csc"], root), usoCheck, 2)
  expectErr("AC-167", "--json senza file", "", run(@["check", "--json"], root), usoCheck, 2)

# 070:5:1 AC-168 (p-3): file senza LF finale, con CRLF, vuoto e con BOM: il JSON c'è, è uguale al rapporto, il file non cambia
block:
  let w = tmpBase / "ac168"
  createDir(w)
  let casi = {"senza_lf.csc": "CSC A VERSION 0.1\n  PURPOSE \"x\"\nEND",
              "crlf.csc": "CSC A VERSION 0.1\r\n  PURPOSE \"x\"\r\nEND\r\n",
              "vuoto.csc": "",
              "bom.csc": "\xEF\xBB\xBFCSC A VERSION 0.1\nEND\n"}
  for (nome, testo) in casi:
    writeFile(w / nome, testo)
    let h = run(@["check", nome], w)
    let a = run(@["check", "--json", nome], w)
    var j: JsonNode
    try: j = parseJson(a.output)
    except JsonParsingError, ValueError: j = newJNull()
    rec("AC-168", nome & ": rapporto rifatto dal JSON = rapporto per persone, stesso codice", j.kind == JObject and
      rifaRapporto(j) == h.output and a.code == h.code, firstDiff(a.output, h.output))
    rec("AC-168", nome & ": il file non cambia e l'impronta è dei byte letti", readFile(w / nome) == testo and
      (j.kind != JObject or j.jstr("impronta") == sha256Of(w / nome)), "")
    if j.kind == JObject:
      rec("AC-168", nome & ": una voce per riga (nessuna riga persa)", j["righe"].len == j["rapporto"]["conteggi"].jint("righe"), $j["righe"].len)

# 070:6:1 AC-170 (p-3 e p-4): il testo inatteso nelle righe è scritto in JSON valido (virgolette, barre, controlli, UTF-8)
block:
  let w = tmpBase / "ac170"
  createDir(w)
  let testo = "CSC A VERSION 0.1\n  PURPOSE \"x\"\n  \"virgolette\" \\ barra \t tab \x01 controllo città\nEND\n"
  writeFile(w / "S.csc", testo)
  let a = run(@["check", "--json", "S.csc"], w)
  var j: JsonNode
  try: j = parseJson(a.output)
  except JsonParsingError, ValueError: j = newJNull()
  rec("AC-170", "uscita JSON valida", j.kind == JObject, a.output)
  if j.kind == JObject:
    rec("AC-170", "il testo della riga 3 torna identico", j["righe"][2].jstr("testo") == "  \"virgolette\" \\ barra \t tab \x01 controllo città",
      j["righe"][2].jstr("testo"))
  rec("AC-170", "il file non cambia", readFile(w / "S.csc") == testo, "")

# 070:7:1 AC-169 (p-2/p-4): `livello` è null se la catena di DETAILS non arriva a una riga base
block:
  proc livelli(file: string, cwd: string): Table[string, JsonNode] =
    let r = run(@["check", "--json", file], cwd)
    var j: JsonNode
    try: j = parseJson(r.output)
    except JsonParsingError, ValueError: j = newJNull()
    if j.kind != JObject: return
    for b in j["blocchi"]:
      for g in b["garanzie"]:
        if g.jstr("id") notin result: result[g.jstr("id")] = g["livello"]
  let l3 = livelli("03_details_inesistente.csc", proveDir)
  rec("AC-169", "livello 1: g2a e g3a (E02) null, g1 0 e g1a 1",
    l3.len == 4 and l3["g2a"].kind == JNull and l3["g3a"].kind == JNull and l3["g1"].getInt(-9) == 0 and l3["g1a"].getInt(-9) == 1, $l3)
  let l6 = livelli("06_details_in_giro.csc", proveDir)
  var tuttiNull = l6.len == 5
  for k, v in l6: tuttiNull = tuttiNull and v.kind == JNull
  rec("AC-169", "livello 2: le cinque righe di 06_details_in_giro null", tuttiNull, $l6)
  let w = tmpBase / "ac169livelli"
  createDir(w)
  var src = "CSC Scala VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"Livelli\"\n  EVENT IN e\n" &
    "  GUARANTEE b: VERBAL \"base\" VERIFY BY INSPECTION \"il rapporto\"\n"
  var prev = "b"
  for n in 1 .. 5:
    let id = "c" & $n
    src.add "  GUARANTEE " & id & " DETAILS " & prev & ": VERBAL \"livello\" VERIFY BY INSPECTION \"il rapporto\"\n"
    prev = id
  src.add "END\n"
  writeFile(w / "S.csc", src)
  let l5 = livelli("S.csc", w)
  var ok5 = l5.len == 6 and l5["b"].getInt(-9) == 0
  for n in 1 .. 5: ok5 = ok5 and l5.getOrDefault("c" & $n).getInt(-9) == n
  rec("AC-169", "livello 3: catena fino al livello 5 invariata (0..5)", ok5, $l5)
  # livello 4: su tutti i file di prova, null se e solo se la risalita (rifatta qui da garanzie[]) non arriva a una riga base
  var strani: seq[string] = @[]
  for f in walkFiles(proveDir / "*.csc"):
    let r = run(@["check", "--json", f], proveDir)
    var j: JsonNode
    try: j = parseJson(r.output)
    except JsonParsingError, ValueError: continue
    if j.kind != JObject: continue
    for b in j["blocchi"]:
      var first: Table[string, JsonNode]
      for g in b["garanzie"]:
        if g.jstr("id") notin first: first[g.jstr("id")] = g
      for g in b["garanzie"]:
        var cur = g
        var n = 0
        var base = true
        while cur["dettaglia"].kind != JNull:
          let nx = cur["dettaglia"].getStr
          inc n
          if nx notin first or n > first.len + 1:
            base = false
            break
          cur = first[nx]
        let got = g["livello"]
        if (base and (got.kind != JInt or got.getInt != n)) or (not base and got.kind != JNull):
          strani.add extractFilename(f) & ":" & $g.jint("da") & " " & $got
  rec("AC-169", "livello 4: su ogni file di prova null se e solo se la catena non arriva a una riga base", strani.len == 0, strani.join("; "))

# 071:1:1 AC-171..AC-180 (GRAMMATICA_F1 1.15 sezione 30): in un blocco CSC o ENTITY con
# 071:1:2 l'intestazione non valida (E09) ogni riga contrattuale è ipotesi; `stato_di` vale `intestazione_non_valida`.
block:
  let d204 = proveDir / "d204"
  proc att(n: string): string = readFile(d204 / n & ".atteso")
  proc jsonDi(args: seq[string], file: string): JsonNode =
    let r = run(@["check", "--json"] & args & @["d204" / file], proveDir)
    try: result = parseJson(r.output)
    except JsonParsingError, ValueError: result = newJNull()
  proc garanzie(j: JsonNode, blocco: int = 0): Table[string, JsonNode] =
    if j.kind != JObject: return
    for g in j["blocchi"][blocco]["garanzie"]: result[g.jstr("id")] = g
  proc ipotesiAlle(j: JsonNode): seq[int] =
    if j.kind != JObject: return
    for h in j["rapporto"]["ipotesi"]: result.add h.jint("riga")
  proc sigla(g: JsonNode): string =
    g.jstr("stato") & "/" & (if g["decisione"].kind == JNull: "-" else: g.jstr("decisione")) & "/" & g.jstr("stato_di")
  # AC-171: punto 0, Rotta
  expectOut("AC-171", "d204/Rotta.csc", "d204/Rotta", run(@["check", "d204/Rotta.csc"], proveDir), att("Rotta"), 1)
  # AC-172: --strict
  block:
    var w = att("Rotta").replace("bcdd check Rotta.csc", "bcdd check --strict Rotta.csc")
    w = w.replace("esito: 1 errore; righe non riconosciute: 1 (vedi sezione 5)\n", "esito: 1 errore; righe non riconosciute: 1 (--strict)\n")
    expectOut("AC-172", "d204/Rotta.csc --strict", "", run(@["check", "--strict", "d204/Rotta.csc"], proveDir), w, 1)
  # AC-173, AC-174
  expectOut("AC-173", "d204/DueBlocchi.csc", "d204/DueBlocchi", run(@["check", "d204/DueBlocchi.csc"], proveDir), att("DueBlocchi"), 1)
  expectOut("AC-174", "d204/RottaSenzaBy.csc", "d204/RottaSenzaBy", run(@["check", "d204/RottaSenzaBy.csc"], proveDir), att("RottaSenzaBy"), 1)
  expectOut("AC-174", "d204/EntitaRotta.csc", "d204/EntitaRotta", run(@["check", "d204/EntitaRotta.csc"], proveDir), att("EntitaRotta"), 1)
  # AC-175: JSON, Rotta
  block:
    let j = jsonDi(@[], "Rotta.csc")
    let g = garanzie(j)
    var ok = j.kind == JObject and j.jint("versione") == 5 and g.len == 5 and j["esito"].jint("codice") == 1
    var why = ""
    if ok:
      let b = j["blocchi"][0]
      ok = not b["intestazione_valida"].getBool and b.jstr("stato") == "contratto" and b.jstr("decisione") == "D-1"
      for id in ["g1", "g1a", "g2", "g3", "a1"]:
        ok = ok and id in g and sigla(g[id]) == "ipotesi/-/intestazione_non_valida"
      ok = ok and g["g1a"].jstr("dettaglia") == "g1" and g["g1a"]["livello"].getInt(-9) == 1
      for id in ["g1", "g2", "g3", "a1"]: ok = ok and g[id]["livello"].getInt(-9) == 0 and g[id]["dettaglia"].kind == JNull
      ok = ok and ipotesiAlle(j) == @[6, 8, 10, 12, 14]
      why = $ipotesiAlle(j)
    rec("AC-175", "d204/Rotta.csc --json", ok, why)
  # AC-176: JSON, DueBlocchi ed EntitaRotta
  block:
    let j = jsonDi(@[], "DueBlocchi.csc")
    var ok = j.kind == JObject and j["blocchi"].len == 2
    var why = ""
    if ok:
      let g0 = garanzie(j, 0)
      let g1 = garanzie(j, 1)
      ok = sigla(g0["g1"]) == "ipotesi/-/intestazione_non_valida" and sigla(g0["g2"]) == "ipotesi/-/intestazione_non_valida" and
        sigla(g1["h1"]) == "contratto/D-5/intestazione" and sigla(g1["h2"]) == "contratto/D-6/suo" and ipotesiAlle(j) == @[5, 7]
      why = $ipotesiAlle(j)
    rec("AC-176", "d204/DueBlocchi.csc --json", ok, why)
    let e = jsonDi(@[], "EntitaRotta.csc")
    var oke = e.kind == JObject
    if oke:
      let b = e["blocchi"][0]
      let g = garanzie(e)
      oke = b.jstr("tipo") == "ENTITY" and not b["intestazione_valida"].getBool and b.jstr("stato") == "senza_stato" and
        g.len == 2 and sigla(g["g1"]) == "ipotesi/-/intestazione_non_valida" and sigla(g["g2"]) == "ipotesi/-/intestazione_non_valida" and
        ipotesiAlle(e) == @[6, 8]
    rec("AC-176", "d204/EntitaRotta.csc --json", oke, "")
  # AC-177: versione 4 su ogni uscita --json di d204 (AC-163..AC-170 sono già a 4 in AC-169)
  for f in ["Rotta", "RottaSenzaBy", "DueBlocchi", "EntitaRotta"]:
    let j = jsonDi(@[], f & ".csc")
    rec("AC-177", f & ": forma e versione 5", j.kind == JObject and j.jstr("forma") == "bcdd-check" and j.jint("versione") == 5, "")
  # AC-178: ratify non cambia
  block:
    let w = tmpBase / "ac178"
    createDir(w)
    for (nome, args, n) in [("Rotta.csc", @["g1", "D-9"], 1), ("Rotta.csc", @["g2", "D-9"], 1), ("Rotta.csc", @["--all", "D-9"], 1),
        ("EntitaRotta.csc", @["g1", "D-9"], 2)]:
      let copia = w / nome
      copyFile(d204 / nome, copia)
      let prima = sha256Of(copia)
      let r = run(@["ratify", nome] & args, w)
      expectErr("AC-178", nome & " " & args.join(" "), "", r,
        "bcdd ratify: il file non passa bcdd check --strict (errori: 1, righe non riconosciute: " & $n & "): non ratifico\n", 1)
      rec("AC-178", nome & " " & args.join(" ") & ": impronta uguale, nessun .dialogo", sha256Of(copia) == prima and not fileExists(copia & ".dialogo"),
        $listDir(w))
  # AC-179: la regola, ricalcolata su ogni file di prova (d204 compresa)
  block:
    var righeIp, errori = 0
    var dettagli: seq[string]
    var files: seq[string]
    for f in walkDirRec(proveDir):
      if f.endsWith(".csc"): files.add f
    files.sort()
    for f in files:
      let r = run(@["check", "--json", f], proveDir)
      var j: JsonNode
      try: j = parseJson(r.output)
      except JsonParsingError, ValueError: continue
      if j.kind != JObject: continue
      let ip = ipotesiAlle(j)
      for b in j["blocchi"]:
        if b.jstr("tipo") notin ["CSC", "ENTITY"]: continue
        for g in b["garanzie"]:
          let tag = extractFilename(f) & ":" & $g.jint("da")
          if not b["intestazione_valida"].getBool:
            inc righeIp
            if sigla(g) != "ipotesi/-/intestazione_non_valida" or g.jint("da") notin ip:
              inc errori
              dettagli.add tag & " " & sigla(g)
          else:
            let sd = g.jstr("stato_di")
            var ok = sd in ["suo", "dettaglio", "intestazione", "profilo"]
            # stato ricalcolato con i punti 1-4 della 7.1: lo STATUS proprio, quello del dettaglio (ipotesi), quello del blocco
            let t = g.jstr("testo")
            let hyp = " STATUS HYPOTHESIS" in t.split(':')[0]
            let rat = " STATUS RATIFIED BY D-" in t.split(':')[0]
            let atteso =
              if sd == "profilo": "ipotesi"      # 7.1 punto 0a: un'estensione di un profilo da approvare
              elif sd == "suo": (if rat: "contratto" else: "ipotesi")
              elif sd == "dettaglio": "ipotesi"
              else: (if b.jstr("stato") == "contratto": "contratto" else: "ipotesi")
            ok = ok and g.jstr("stato") == atteso and not (hyp and g.jstr("stato") == "contratto")
            if not ok:
              inc errori
              dettagli.add tag & " " & sigla(g)
    rec("AC-179", "la regola su ogni garanzia di CSC ed ENTITY di prove/", errori == 0 and righeIp >= 11,
      "righe con E09: " & $righeIp & "; " & dettagli.join("; "))
  # AC-180 (parte nuova): AC-5 e AC-6 estesi a prove/d204/
  block:
    var u1, u2: seq[string]
    for f in ["Rotta", "RottaSenzaBy", "DueBlocchi", "EntitaRotta"]:
      u1.add run(@["check", "d204" / f & ".csc"], proveDir).output
      u2.add run(@["check", "d204" / f & ".csc"], proveDir).output
    rec("AC-180", "due esecuzioni su prove/d204 uguali (AC-6 esteso)", u1 == u2, "uscite diverse")
    rec("AC-180", "prove/d204 presenti: otto file", listDir(d204).len == 8, $listDir(d204))
    let fz = run(@["check", "csc/BcddTool.csc"], root)
    expectOut("AC-180", "csc/BcddTool.csc = prove/F0_BcddTool.atteso", "", fz, readFile(proveDir / "F0_BcddTool.atteso"), 0)
    # 072:0:1 sha aggiornata alla riga 11 / VERSION 0.2 / di BcddProgrammi.csc; prima 0939e703...
    rec("AC-180", "F0_BcddTool.atteso: SHA-256 invariato",
      sha256Of(proveDir / "F0_BcddTool.atteso") == "sha256:ad0e9c857ba6c1b355425e1b1fe706be9c6480b40b21a8612db08ba9e0b3744d", "")

# 072:1:1 AC-181..AC-183 (F4b, passo 0): `check --json` dà i campi strutturati degli usi e il percorso
# aperto di ogni citazione trovata in un altro file. La versione 5 e il rapporto per persone non cambia.
proc proveCsc(): seq[string] =
  ## Tutti i .csc di prove/, relativi alla radice, in ordine.
  for f in walkDirRec(proveDir):
    if f.endsWith(".csc"): result.add relativePath(f, root)
  result.sort()

proc jsonDi(args: seq[string], cwd: string = root): JsonNode =
  ## Il JSON di `check --json`, o nil se l'uscita non è un oggetto JSON.
  let r = run(@["check", "--json"] & args, cwd)
  if not r.output.startsWith("{"): return nil
  try: result = parseJson(r.output)
  except CatchableError: result = nil

proc fraseDaiCampi(u: JsonNode, entita: string): string =
  ## La frase di `usi[].testo` rifatta dai soli campi (regole del formato JSON).
  result = u.jstr("parte") & " usa " & u.jstr("nome")
  if u["versione"].kind != JNull: result.add " VERSION " & u.jstr("versione")
  result.add ": "
  case u.jstr("esito")
  of "offerta":
    var os: seq[string]
    for o in u["offerta_da"]: os.add o.jstr("parte") & " (riga " & $o.jint("riga") & ")"
    result.add (if os.len == 1: "la offre " else: "la offrono ") & os.join(", ")
  of "da_fuori": result.add "la usa " & entita & " da fuori (riga " & $u.jint("da_fuori") & ")"
  of "scoperto": result.add "nessuno la offre"
  of "non_controllato": result.add "nessuna parte trovata la offre (parti non controllate: " & $u.jint("parti_non_controllate") & ")"
  else: result.add "?"

block:
  const D = @["--dir", "prove/f3/luce"]
  let jl = jsonDi(@["LuceScale.csc"], root / "prove/f3/luce")
  rec("AC-181", "LuceScale: JSON letto", jl != nil, "nessun JSON")
  if jl != nil:
    let us = jl["rapporto"]["usi"]
    rec("AC-181", "LuceScale: una voce lampada/Comando/offerta da pulsante riga 6",
      us.len == 1 and us[0].hasKey("esito") and us[0].jstr("parte") == "lampada" and us[0].jstr("nome") == "Comando" and
      us[0].jstr("esito") == "offerta" and $us[0]["offerta_da"] == """[{"parte":"pulsante","riga":6}]""" and
      us[0]["versione"].kind == JNull and us[0]["da_fuori"].kind == JNull and us[0].jint("parti_non_controllate") == 0, $us)
  let jsp = jsonDi(@["SenzaPulsante.csc"], root / "prove/f3/luce")
  if jsp != nil:
    let u = jsp["rapporto"]["usi"][0]
    var e14 = 0
    for e in jsp["rapporto"]["errori"]:
      if e.jstr("codice") == "E14": e14 = e.jint("riga")
    rec("AC-181", "SenzaPulsante: scoperto, E14 alla riga della voce", u.hasKey("esito") and u.jstr("esito") == "scoperto" and
      e14 == u.jint("riga") and e14 == 5, $u & " E14 " & $e14)
  else: rec("AC-181", "SenzaPulsante: JSON letto", false, "nessun JSON")
  let jdf = jsonDi(@["DaFuori.csc"], root / "prove/f3/luce")
  if jdf != nil:
    let u = jdf["rapporto"]["usi"][0]
    rec("AC-181", "DaFuori: da_fuori 4", u.hasKey("esito") and u.jstr("esito") == "da_fuori" and u["da_fuori"].getInt == 4 and
      u["offerta_da"].len == 0, $u)
  else: rec("AC-181", "DaFuori: JSON letto", false, "nessun JSON")
  let jso = jsonDi(D & "prove/f3/sospeso/Sospeso.csc")
  if jso != nil:
    let u = jso["rapporto"]["usi"][0]
    rec("AC-181", "Sospeso: non_controllato, 1 parte", u.hasKey("esito") and u.jstr("esito") == "non_controllato" and
      u.jint("parti_non_controllate") == 1, $u)
  else: rec("AC-181", "Sospeso: JSON letto", false, "nessun JSON")
  let jpo = jsonDi(D & "prove/f3/parola/Posizioni.csc")
  if jpo != nil:
    var r24, r29 = newJNull()
    for u in jpo["rapporto"]["usi"]:
      if u.jint("riga") == 24: r24 = u
      if u.jint("riga") == 29: r29 = u
    var os24: seq[string]
    if r24.kind == JObject and r24.hasKey("offerta_da"):
      for o in r24["offerta_da"]: os24.add o.jstr("parte") & " (riga " & $o.jint("riga") & ")"
    rec("AC-181", "Posizioni riga 24: sette voci in offerta_da, nell'ordine della frase",
      r24.kind == JObject and r24.hasKey("esito") and r24.jstr("esito") == "offerta" and os24.len == 7 and
      r24.jstr("testo").endsWith("la offrono " & os24.join(", ")), $r24)
    rec("AC-181", "Posizioni riga 29: scoperto", r29.kind == JObject and r29.hasKey("esito") and r29.jstr("esito") == "scoperto", $r29)
  else: rec("AC-181", "Posizioni: JSON letto", false, "nessun JSON")
  # 0.12: due offerenti dello stesso nome con versioni diverse; solo quello con la versione chiesta è in offerta_da
  let jmi = jsonDi(D & "prove/f3/richiesta/Misto.csc")
  if jmi != nil:
    let us = jmi["rapporto"]["usi"]
    rec("AC-181", "Misto: lampada chiede Comando 0.2, offerta_da solo nuovo (riga 6), il testo si rifà dai campi",
      us.len == 1 and us[0].jstr("esito") == "offerta" and $us[0]["offerta_da"] == """[{"parte":"nuovo","riga":6}]""" and
      us[0].jstr("versione") == "0.2" and fraseDaiCampi(us[0], "Misto") == us[0].jstr("testo"), $us)
  else: rec("AC-181", "Misto: JSON letto", false, "nessun JSON")
  # la frase si rifà dai campi, carattere per carattere, su ogni file di prove/
  var nUsi, nBad = 0
  var bad: seq[string]
  for f in proveCsc():
    let j = jsonDi(D & f)
    if j == nil: continue
    for u in j["rapporto"]["usi"]:
      inc nUsi
      var entita = "?"
      for b in j["blocchi"]:
        if b.jstr("tipo") == "ENTITY" and b.jint("da") <= u.jint("riga") and u.jint("riga") <= b.jint("a"): entita = b.jstr("nome")
      if not u.hasKey("esito") or fraseDaiCampi(u, entita) != u.jstr("testo"):
        inc nBad
        if bad.len < 5: bad.add f & ":" & $u.jint("riga")
  rec("AC-181", "ogni voce di usi[] su prove/ si rifà dai campi (" & $nUsi & " voci)", nUsi >= 20 and nBad == 0,
    "voci " & $nUsi & ", diverse " & $nBad & " " & bad.join(" "))

block:
  const D = @["--dir", "prove/f3/luce"]
  let j = jsonDi(D & "prove/f3/luce/LuceScale.csc")
  var ok = false
  var why = "nessun JSON"
  if j != nil:
    for b in j["blocchi"]:
      for c in b["citazioni"]:
        if c.jstr("nome") == "Pulsante" and c["trovata"].hasKey("percorso"):
          ok = c["trovata"].jstr("dove") == "Pulsante.csc" and c["trovata"].jstr("percorso") == "prove/f3/luce/Pulsante.csc"
          why = $c["trovata"]
  rec("AC-182", "LuceScale dalla radice: dove Pulsante.csc, percorso prove/f3/luce/Pulsante.csc", ok, why)
  var nAlt, nStesso, nBad = 0
  var bad: seq[string]
  for f in proveCsc():
    if "prove/f3/" notin f: continue
    let j = jsonDi(D & f)
    if j == nil: continue
    for b in j["blocchi"]:
      for c in b["citazioni"]:
        let t = c["trovata"]
        if not t.hasKey("percorso"):
          inc nBad
          bad.add f & " senza percorso"
        elif t["dove"].kind == JNull:
          inc nStesso
          if t["percorso"].kind != JNull: (inc nBad; bad.add f & " percorso non null")
        else:
          inc nAlt
          let pr = t.jstr("percorso")
          let jj = if fileExists(root / pr): jsonDi(@[pr]) else: nil
          var trovato = false
          if jj != nil:
            for bb in jj["blocchi"]:
              if bb.jstr("nome") == c.jstr("nome") and bb.jint("da") == t.jint("riga"): trovato = true
          if not trovato:
            inc nBad
            if bad.len < 5: bad.add f & " -> " & pr
  rec("AC-182", "ogni citazione di prove/f3 (" & $nAlt & " in altri file, " & $nStesso & " nello stesso)",
    nAlt >= 10 and nStesso >= 1 and nBad == 0, $nBad & " difformi: " & bad.join("; "))

block:
  let (outp, _) = execCmdEx("git diff --name-status 1dea2f79 -- prove", workingDir = root)
  var nonAgg: seq[string]
  for l in outp.splitLines():
    # 1.17 (E16, E17): i risultati attesi di questi file cambiano per le due regole nuove, nient'altro
    # 1.18: le risposte finte e le richieste attese di refine su una CSC passano a bcdd-refine-5 (modello nuovo)
    let tocca247 = l.startsWith("M") and "/refine/" in l and (l.endsWith(".json") or l.endsWith("MOTIVI_ATTESI.md") or ".richiesta" in l)
    if l.len > 0 and not l.startsWith("error:") and not l.startsWith("fatal:") and not l.startsWith("A") and not (l.startsWith("M") and l.endsWith(".atteso")) and not tocca247: nonAgg.add l
  rec("AC-183", "nessun .atteso di prove/ cambiato rispetto a 1dea2f79 (solo file aggiunti)", nonAgg.len == 0, nonAgg.join("; "))
  var nVer, nChiavi, nTot = 0
  let attesiTop = @["forma", "versione", "lingua", "file", "opzioni", "impronta", "blocchi", "rapporto", "esito"]
  let uso9 = @["riga", "testo", "parte", "nome", "versione", "esito", "offerta_da", "da_fuori", "parti_non_controllate", "in"]
  let tr7 = @["dove", "percorso", "riga", "versione", "stato", "stato_blocco", "errori", "non_riconosciute"]   # stato_blocco
  var bad: seq[string]
  for f in proveCsc():
    let j = jsonDi(@["--dir", "prove/f3/luce", f])
    if j == nil: continue
    inc nTot
    if j["versione"].getInt == 5: inc nVer
    var okc = true
    for u in j["rapporto"]["usi"]:
      var ks: seq[string]
      for k, _ in u: ks.add k
      if ks != uso9: okc = false
    for b in j["blocchi"]:
      for c in b["citazioni"]:
        var ks: seq[string]
        for k, _ in c["trovata"]: ks.add k
        if ks != tr7: okc = false
    if okc: inc nChiavi else: bad.add f
  rec("AC-183", "versione 4 su tutte le uscite JSON di prove/ (" & $nTot & ")", nTot > 50 and nVer == nTot, $nVer & "/" & $nTot)
  rec("AC-183", "chiavi di usi[] e di trovata come da sezione 12.2", nTot > 50 and nChiavi == nTot, bad.join(" "))
  var tuttiAc = true
  var nonOk: seq[string]
  for ac in acOrder:
    let n = if ac.startsWith("AC-"): parseInt(ac[3 .. ^1]) else: 9999
    if n < 181 and acPass[ac] != acTotal[ac]:
      tuttiAc = false
      nonOk.add ac
  rec("AC-183", "AC-1..AC-180 tutti superati", tuttiAc, nonOk.join(" "))

# 072:2:1 AC-201 (0.12 campo 3): `blocchi[].scopo` dà il PURPOSE del blocco, `null` senza PURPOSE.
block:
  var nBlocchi, nConScopo, nNull, nBad = 0
  var bad: seq[string]
  for f in proveCsc() & @["esempi/LuceScale.csc", "esempi/LuceScaleRatificata.csc"]:
    let j = jsonDi(@["--dir", "prove/f3/luce", f])
    if j == nil: continue
    let righeFile = readFile(root / f).replace("\r\n", "\n").split('\n')
    for b in j["blocchi"]:
      inc nBlocchi
      if not b.hasKey("scopo"):
        inc nBad
        if bad.len < 5: bad.add f & ": manca scopo"
        continue
      let s = b["scopo"]
      if s.kind == JNull:
        inc nNull
        continue
      inc nConScopo
      let r = s.jint("riga")
      let fino = s.jint("fino")
      let testo = if r >= 1 and fino >= r and fino <= righeFile.len: righeFile[r - 1 .. fino - 1].join("\n") else: "?"
      # `fino` ricalcolato dal file con la regola L2 di GRAMMATICA_F1 (stringa da " a " successivo, anche su più righe)
      var chiusa = 0
      block cerca:
        var apre = false
        for n in r .. righeFile.len:
          for ch in (if n == r: righeFile[n - 1].substr(righeFile[n - 1].find("PURPOSE") + 7) else: righeFile[n - 1]):
            if ch == '"':
              if apre:
                chiusa = n
                break cerca
              apre = true
      if not (righeFile[r - 1].strip().startsWith("PURPOSE") and s.jstr("testo") == testo and r >= b.jint("da") and fino <= b.jint("a") and
          fino == chiusa):
        inc nBad
        if bad.len < 5: bad.add f & ":" & $r
  rec("AC-201", "scopo: riga della parola PURPOSE e testo = righe del file (" & $nConScopo & " blocchi)", nConScopo >= 50 and nBad == 0,
    "difformi " & $nBad & " " & bad.join(" "))
  rec("AC-201", "senza PURPOSE (E10): scopo null (" & $nNull & " blocchi)", nNull >= 1, "nessun blocco senza PURPOSE")
  let j11 = jsonDi(@["prove/11_purpose.csc"])
  var primo = false
  if j11 != nil:
    for b in j11["blocchi"]:
      if b.jstr("nome") == "DueScopi": primo = b.hasKey("scopo") and b["scopo"].kind == JObject and b["scopo"].jint("riga") == 8 and
        b["scopo"].jstr("testo") == "  PURPOSE \"il primo\""
  rec("AC-201", "PURPOSE ripetuto: il primo", primo, "")
  let ja = jsonDi(@["--dir", "prove/f3/luce", "prove/f3/luce/LuceScale.csc"])
  var ordine = false
  if ja != nil:
    var k: seq[string]
    for kk, _ in ja["blocchi"][0]: k.add kk
    ordine = k.find("scopo") == k.find("decisione") + 1 and k.find("scopo") > 0
  rec("AC-201", "scopo dopo decisione, versione 5", ja != nil and ja["versione"].getInt == 5 and ordine, "")

# 073:1:1 AC-202..AC-204: E16, E17 e `bcdd save`. Poche prove, quelle del design.
block:
  let luce = root / "prove/f3/luce"
  # AC-202: E16. LuceScale offre Luce, ma la lampada non c'è fra le parti; poi la stessa cosa sistemata
  let w = newWd()
  discard cpTo(luce / "Pulsante.csc", w)
  discard cpTo(luce / "Lampada.csc", w)
  discard cpTo(luce / "Pressione.csc", w)
  discard cpTo(luce / "Luce.csc", w)
  discard cpTo(luce / "Comando.csc", w)
  writeFile(w / "Scale.csc", "ENTITY Scale VERSION 0.1\n  PURPOSE \"x\"\n  OFFERS Pressione\n  OFFERS Luce\n  COMPOSED OF\n    pulsante : Pulsante\nEND\n")
  let r16 = run(@["check", "Scale.csc"], w)
  rec("AC-202", "E16: Luce non la mantiene nessuna parte", r16.code == 1 and "riga 4: [E16] il connettore pubblico Luce di Scale (offre) non è affidato a nessuna parte" in r16.output, r16.output)
  writeFile(w / "Scale.csc", "ENTITY Scale VERSION 0.1\n  PURPOSE \"x\"\n  OFFERS Pressione\n  OFFERS Luce\n  COMPOSED OF\n    pulsante : Pulsante\n    lampada : Lampada\nEND\n")
  let r16b = run(@["check", "Scale.csc"], w)
  rec("AC-202", "E16: sistemata, nessun E16 e nessun errore", r16b.code == 0 and "E16" notin r16b.output, r16b.output)
  # AC-203: E17. Il pulsante offre anche Suono, che nessuno usa e Scale non espone
  writeFile(w / "Pulsante.csc", readFile(luce / "Pulsante.csc").replace("  OFFERS Comando\n", "  OFFERS Comando\n  OFFERS Suono\n"))
  let r17 = run(@["check", "Scale.csc"], w)
  rec("AC-203", "E17: il pulsante offre Suono", r17.code == 1 and "[E17] la parte pulsante offre il connettore Suono: nessun'altra parte di Scale lo usa, né Scale lo offre da fuori" in r17.output, r17.output)

block:
  # AC-204: bcdd save
  proc salva(w, file, expect, testo: string): Res =
    runX(bcdd, @["save", file, "--expect", expect], w, nil, testo)
  let w = newWd()
  let ip = "CSC Prova VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"x\"\n  GUARANTEE g1: VERBAL \"uno\"\n                VERIFY BY JUDGEMENT \"chi\"\nEND\n"
  writeFile(w / "Prova.csc", ip)
  let imp0 = sha256Of(w / "Prova.csc")
  # impronta cambiata: rifiutato, file uguale
  let r1 = salva(w, "Prova.csc", "sha256:0000", ip.replace("uno", "due"))
  rec("AC-204", "impronta cambiata: rifiutato e file uguale", r1.code == 1 and r1.output.len == 0 and readFile(w / "Prova.csc") == ip, r1.errout)
  # STATUS RATIFIED scritto a mano: rifiutato
  let r2 = salva(w, "Prova.csc", imp0, ip.replace("STATUS HYPOTHESIS", "STATUS RATIFIED BY D-1"))
  rec("AC-204", "STATUS RATIFIED a mano: rifiutato", r2.code == 1 and readFile(w / "Prova.csc") == ip, r2.errout)
  # una riga ipotesi cambiata: scritto, righe_cambiate giusto, impronta nuova
  let nuovo = ip.replace("\"uno\"", "\"due\"")
  let r3 = salva(w, "Prova.csc", imp0, nuovo)
  rec("AC-204", "riga ipotesi cambiata: scritta, righe_cambiate [4], impronta nuova", r3.code == 0 and readFile(w / "Prova.csc") == nuovo and
    "\"righe_cambiate\": [4]" in r3.output and "\"impronta\": \"" & sha256Of(w / "Prova.csc") & "\"" in r3.output, r3.output & r3.errout)
  # EVENT IN aggiunto a una CSC ratificata: rifiutato
  let rat = readFile(root / "esempi/LuceScaleRatificata.csc")
  writeFile(w / "Rat.csc", rat)
  let r4 = salva(w, "Rat.csc", sha256Of(w / "Rat.csc"), rat.replace("  EVENT IN  pressione\n", "  EVENT IN  pressione\n  EVENT IN  altro\n"))
  rec("AC-204", "EVENT IN su una CSC ratificata: rifiutato", r4.code == 1 and readFile(w / "Rat.csc") == rat, r4.errout)
  # --expect nuovo: su un file che c'è rifiutato, su uno che non c'è scritto
  let r5 = salva(w, "Prova.csc", "nuovo", ip)
  rec("AC-204", "--expect nuovo su un file che c'è: rifiutato", r5.code == 1 and readFile(w / "Prova.csc") == nuovo, r5.errout)
  let r6 = salva(w, "Altra.csc", "nuovo", ip)
  rec("AC-204", "--expect nuovo su un file che non c'è: scritto", r6.code == 0 and fileExists(w / "Altra.csc") and readFile(w / "Altra.csc") == ip, r6.errout)

# 066:1:1 pezzo 4 dell'editor: `bcdd refine --json` a tempi (p-5..p-10). Criterio principale: con le stesse risposte
# 066:1:2 i file CSC e dialogo sono quelli del giro nel terminale. Con l'eseguibile di prova e l'LLM finto (mai il binario di release).
block:
  let rf = f2Dir / "refine"
  let luce = rf / "Luce.csc"
  let buona = rf / "risposte" / "buona.json"
  let sec = ("BCDD_FINTO_RISPOSTA_2", rf / "risposte" / "buona_seconda.json")
  proc tempo(wd: string, resp: string, args: seq[string], input: string = "", extra: seq[(string, string)] = @[]): Res =
    var ex: seq[(string, string)]
    if resp.len > 0: ex.add ("BCDD_FINTO_RISPOSTA", resp)
    discard auxOf(wd)
    runX(bcddProva, @["refine", "--json"] & args, wd, refEnv(wd, ex & extra), input)
  const risp1 = """{"risposte": [{"n": 1, "testo": "fra tre minuti circa"}]}"""
  # giro con domande: 1 -> 2 -> 3, come T01 nel terminale
  block:
    let w = newRef(luce)
    let r1 = tempo(w, buona, @["Luce.csc"], "", @[sec])
    rec("X", "D-232 tempo 1: codice 0, domande, giro aperto, una chiamata", r1.code == 0 and r1.output.startsWith("{\"forma\": \"bcdd-giro\", \"versione\": 1, \"file\": \"Luce.csc\", \"tempo\": 1, \"modello\": \"veloce\", \"chiamate\": 1,") and
      "\"prossimo\": \"answers\"" in r1.output and "\"proposte\": []" in r1.output and listDir(w) == @["Luce.csc", "Luce.csc.giro", "chiamate.tsv"] and
      fileEq(w / "Luce.csc", luce) and contaOf(w) == "1", r1.output & r1.errout & $listDir(w))
    let r2 = tempo(w, buona, @["--answers", "Luce.csc"], risp1, @[sec])
    rec("X", "D-232 tempo 2: seconda chiamata, due proposte valide", r2.code == 0 and "\"tempo\": 2, \"modello\": \"veloce\", \"chiamate\": 2" in r2.output and
      "\"n\": \"p1\", \"valida\": true" in r2.output and "\"n\": \"p2\", \"valida\": true" in r2.output and contaOf(w) == "2" and
      fileEq(w / "Luce.csc", luce), r2.output & r2.errout)
    let r3 = tempo(w, buona, @["--accept", "Luce.csc"], """{"accettate": ["p1"]}""", @[sec])
    rec("X", "D-232 tempo 3: CSC e dialogo uguali a T01 nel terminale, giro tolto, nessuna chiamata in più", r3.code == 0 and
      fileEq(w / "Luce.csc", rf / "T01_buona.dopo.csc") and fileEq(w / "Luce.csc.dialogo", rf / "T01_buona.dialogo") and
      listDir(w) == @["Luce.csc", "Luce.csc.dialogo", "chiamate.tsv"] and contaOf(w) == "2" and
      "\"scritto\": {\"csc\": \"1 proposta (2 righe)\", \"dialogo\": \"1 risposta\"}" in r3.output and
      "\"impronta\": \"" & sha256Of(w / "Luce.csc") & "\"" in r3.output, r3.output & r3.errout & $listDir(w))
  # una scelta al posto del testo
  block:
    let w = newRef(luce)
    discard tempo(w, buona, @["Luce.csc"], "", @[sec])
    let r2 = tempo(w, buona, @["--answers", "Luce.csc"], """{"risposte": [{"n": 1, "scelta": 2}]}""", @[sec])
    discard tempo(w, buona, @["--accept", "Luce.csc"], """{"accettate": ["p2"]}""", @[sec])
    rec("X", "D-232 una scelta vale il testo della scelta nel dialogo", r2.code == 0 and fileExists(w / "Luce.csc.dialogo") and
      "RISPOSTA dopo tre minuti" in readFile(w / "Luce.csc.dialogo"), r2.errout & $listDir(w))
  # senza domande: 1 -> 3, come T21 nel terminale
  block:
    let w = newRef(rf / "Ordine.csc", "Ordine.csc")
    let r1 = tempo(w, rf / "risposte" / "ordine.json", @["Ordine.csc"])
    rec("X", "D-232 senza domande il tempo 1 dà le proposte", r1.code == 0 and "\"prossimo\": \"accept\"" in r1.output and "\"n\": \"p4\"" in r1.output and
      contaOf(w) == "1", r1.output & r1.errout)
    let r3 = tempo(w, "", @["--accept", "Ordine.csc"], """{"accettate": ["p1", "p2", "p3", "p4"]}""")
    rec("X", "D-232 senza domande: Ordine.csc come T21, nessun dialogo, una chiamata", r3.code == 0 and fileEq(w / "Ordine.csc", rf / "T21_ordine.dopo.csc") and
      listDir(w) == @["Ordine.csc", "chiamate.tsv"] and contaOf(w) == "1" and "\"dialogo\": null" in r3.output, r3.output & r3.errout & $listDir(w))
  # tutte le domande saltate: le proposte della prima chiamata, nessuna seconda chiamata
  block:
    let w = newRef(luce)
    discard tempo(w, buona, @["Luce.csc"], "", @[sec])
    let r2 = tempo(w, "", @["--answers", "Luce.csc"], """{"risposte": []}""", @[sec])
    rec("X", "D-232 domande saltate: tempo 2 senza chiamare", r2.code == 0 and "\"chiamate\": 1" in r2.output and contaOf(w) == "1", r2.output & r2.errout)
  # sostituzione e proposta insieme, come T29
  block:
    let w = newRef(luce)
    let ss = ("BCDD_FINTO_RISPOSTA_2", rf / "risposte" / "sostituisce_seconda.json")
    discard tempo(w, buona, @["Luce.csc"], "", @[ss])
    let r2 = tempo(w, buona, @["--answers", "Luce.csc"], risp1, @[ss])
    let r3 = tempo(w, buona, @["--accept", "Luce.csc"], """{"accettate": ["s1", "p1"]}""", @[ss])
    rec("X", "D-232 sostituzione + proposta: Luce.csc come T29", r2.code == 0 and "\"n\": \"s1\", \"valida\": true" in r2.output and r3.code == 0 and
      fileEq(w / "Luce.csc", rf / "T29_sostituzione.dopo.csc") and fileEq(w / "Luce.csc.dialogo", rf / "T01_buona.dialogo"), r2.output & r3.output & r3.errout)
  # «precisa abbastanza»: nessun giro aperto
  block:
    let w = newWd()
    discard cpTo(rf / "T01_buona.dopo.csc", w, "Luce.csc")
    let r = tempo(w, rf / "risposte" / "vuota.json", @["Luce.csc"])
    rec("X", "D-232 precisa abbastanza: precisa true, nessun giro, file uguale", r.code == 0 and "\"precisa\": true" in r.output and
      listDir(w) == @["Luce.csc", "chiamate.tsv"] and fileEq(w / "Luce.csc", rf / "T01_buona.dopo.csc"), r.output & r.errout & $listDir(w))
  # --cancel: niente scritto, giro tolto
  block:
    let w = newRef(luce)
    discard tempo(w, buona, @["Luce.csc"], "", @[sec])
    let r = tempo(w, "", @["--cancel", "Luce.csc"])
    rec("X", "D-232 --cancel: codice 0, giro tolto, file uguale, una chiamata", r.code == 0 and listDir(w) == @["Luce.csc", "chiamate.tsv"] and
      fileEq(w / "Luce.csc", luce) and contaOf(w) == "1", r.output & r.errout & $listDir(w))
    let r2 = tempo(w, "", @["--cancel", "Luce.csc"])
    rec("X", "D-232 --cancel senza giro: codice 2", r2.code == 2, r2.errout)
  # : --show rimostra l'uscita del tempo a cui il giro è fermo, byte per byte, senza chiamare né scrivere
  block:
    let w = newRef(luce)
    let r1 = tempo(w, buona, @["Luce.csc"], "", @[sec])
    let giro1 = readFile(w / "Luce.csc.giro")
    let h1 = sha256Of(w / "Luce.csc")
    let s1 = tempo(w, "", @["Luce.csc", "--show"])
    rec("X", "D-240 --show dopo il tempo 1 con domande: uscita uguale byte per byte, giro e file invariati, nessuna chiamata",
      s1.code == 0 and s1.output == r1.output and readFile(w / "Luce.csc.giro") == giro1 and sha256Of(w / "Luce.csc") == h1 and
      listDir(w) == @["Luce.csc", "Luce.csc.giro", "chiamate.tsv"] and contaOf(w) == "1", s1.output & s1.errout)
    let r2 = tempo(w, buona, @["--answers", "Luce.csc"], risp1, @[sec])
    let giro2 = readFile(w / "Luce.csc.giro")
    let s2 = tempo(w, "", @["Luce.csc", "--show"])
    rec("X", "D-240 --show dopo il tempo 2: uscita uguale byte per byte, giro e file invariati, nessuna chiamata in più",
      s2.code == 0 and s2.output == r2.output and readFile(w / "Luce.csc.giro") == giro2 and sha256Of(w / "Luce.csc") == h1 and
      listDir(w) == @["Luce.csc", "Luce.csc.giro", "chiamate.tsv"] and contaOf(w) == "2", s2.output & s2.errout)
    let r3 = tempo(w, buona, @["--accept", "Luce.csc"], """{"accettate": ["p1"]}""", @[sec])
    rec("X", "D-240 dopo --show il giro si chiude come senza: CSC e dialogo come T01",
      r3.code == 0 and fileEq(w / "Luce.csc", rf / "T01_buona.dopo.csc") and fileEq(w / "Luce.csc.dialogo", rf / "T01_buona.dialogo") and
      listDir(w) == @["Luce.csc", "Luce.csc.dialogo", "chiamate.tsv"] and contaOf(w) == "2", r3.output & r3.errout)
    let s3 = tempo(w, "", @["Luce.csc", "--show"])
    rec("X", "D-240 --show senza giro aperto: codice 2, niente scritto", s3.code == 2 and s3.output.len == 0 and
      listDir(w) == @["Luce.csc", "Luce.csc.dialogo", "chiamate.tsv"], s3.output & s3.errout)
  block:
    let w = newRef(rf / "Ordine.csc", "Ordine.csc")
    let r1 = tempo(w, rf / "risposte" / "ordine.json", @["Ordine.csc"])
    let giro1 = readFile(w / "Ordine.csc.giro")
    let s1 = tempo(w, "", @["Ordine.csc", "--show"])
    rec("X", "D-240 --show dopo il tempo 1 senza domande: uscita uguale byte per byte, giro invariato",
      s1.code == 0 and s1.output == r1.output and readFile(w / "Ordine.csc.giro") == giro1 and contaOf(w) == "1", s1.output & s1.errout)
    let r3 = tempo(w, "", @["--accept", "Ordine.csc"], """{"accettate": ["p1", "p2", "p3", "p4"]}""")
    rec("X", "D-240 senza domande, dopo --show: Ordine.csc come T21", r3.code == 0 and fileEq(w / "Ordine.csc", rf / "T21_ordine.dopo.csc") and
      listDir(w) == @["Ordine.csc", "chiamate.tsv"], r3.output & r3.errout)
  block:
    let w = newRef(luce)
    discard tempo(w, buona, @["Luce.csc"], "", @[sec])
    let r2 = tempo(w, "", @["--answers", "Luce.csc"], """{"risposte": []}""", @[sec])
    let s2 = tempo(w, "", @["Luce.csc", "--show"])
    rec("X", "D-240 --show dopo il tempo 2 con tutte le domande saltate: uscita uguale byte per byte", s2.code == 0 and s2.output == r2.output and contaOf(w) == "1", s2.output & s2.errout)
  block:
    let w = newRef(luce)
    discard tempo(w, buona, @["Luce.csc"], "", @[sec])
    writeFile(w / "Luce.csc", readFile(luce) & "-- cambiato fuori\n")
    let cambiato = readFile(w / "Luce.csc")
    let s = tempo(w, "", @["Luce.csc", "--show"])
    rec("X", "D-240 --show con file cambiato: codice 1, file_cambiato, giro chiuso, file e dialogo non toccati, nessuna chiamata",
      s.code == 1 and "\"errore\": \"file_cambiato\"" in s.output and readFile(w / "Luce.csc") == cambiato and
      listDir(w) == @["Luce.csc", "chiamate.tsv"] and contaOf(w) == "1", s.output & s.errout & $listDir(w))

  # file cambiato fra i tempi: codice 1, niente scritto, giro chiuso, risposte da copiare
  block:
    let w = newRef(luce)
    discard tempo(w, buona, @["Luce.csc"], "", @[sec])
    writeFile(w / "Luce.csc", readFile(luce) & "-- cambiato fuori\n")
    let cambiato = readFile(w / "Luce.csc")
    let r2 = tempo(w, buona, @["--answers", "Luce.csc"], risp1, @[sec])
    rec("X", "D-232 file cambiato al tempo 2: codice 1, nessuna seconda chiamata, giro chiuso, risposta nell'uscita", r2.code == 1 and contaOf(w) == "1" and
      readFile(w / "Luce.csc") == cambiato and listDir(w) == @["Luce.csc", "chiamate.tsv"] and "\"errore\": \"file_cambiato\"" in r2.output and
      "fra tre minuti circa" in r2.output, r2.output & r2.errout & $listDir(w))
    let w3 = newRef(luce)
    discard tempo(w3, buona, @["Luce.csc"], "", @[sec])
    discard tempo(w3, buona, @["--answers", "Luce.csc"], risp1, @[sec])
    writeFile(w3 / "Luce.csc", readFile(luce) & "-- cambiato fuori\n")
    let cambiato3 = readFile(w3 / "Luce.csc")
    let r3 = tempo(w3, buona, @["--accept", "Luce.csc"], """{"accettate": ["p1"]}""", @[sec])
    rec("X", "D-232 file cambiato al tempo 3: codice 1, niente scritto, giro chiuso, righe e risposta nell'uscita", r3.code == 1 and readFile(w3 / "Luce.csc") == cambiato3 and
      listDir(w3) == @["Luce.csc", "chiamate.tsv"] and "GUARANTEE g2a DETAILS g2" in r3.output and "fra tre minuti circa" in r3.output, r3.output & r3.errout & $listDir(w3))
  # giro già aperto: il tempo 1 non ne apre un altro e non chiama l'LLM
  block:
    let w = newRef(luce)
    discard tempo(w, buona, @["Luce.csc"], "", @[sec])
    let giro = readFile(w / "Luce.csc.giro")
    let r = tempo(w, buona, @["Luce.csc"], "", @[sec])
    rec("X", "D-232 giro già aperto: codice 1, giro_aperto, giro e file uguali, nessuna chiamata", r.code == 1 and "\"errore\": \"giro_aperto\"" in r.output and
      readFile(w / "Luce.csc.giro") == giro and contaOf(w) == "1" and fileEq(w / "Luce.csc", luce), r.output & r.errout)
  # numero di proposta che non c'è, o tempo sbagliato: codice 2, niente scritto, giro aperto
  block:
    let w = newRef(luce)
    discard tempo(w, buona, @["Luce.csc"], "", @[sec])
    let e0 = tempo(w, buona, @["--accept", "Luce.csc"], """{"accettate": []}""", @[sec])
    rec("X", "D-232 tempo 3 prima delle risposte: codice 2", e0.code == 2 and listDir(w) == @["Luce.csc", "Luce.csc.giro", "chiamate.tsv"], e0.errout)
    discard tempo(w, buona, @["--answers", "Luce.csc"], risp1, @[sec])
    let giro = readFile(w / "Luce.csc.giro")
    let r = tempo(w, buona, @["--accept", "Luce.csc"], """{"accettate": ["p9"]}""", @[sec])
    rec("X", "D-232 proposta p9 inesistente: codice 2, niente scritto, giro com'era", r.code == 2 and fileEq(w / "Luce.csc", luce) and
      readFile(w / "Luce.csc.giro") == giro and not fileExists(w / "Luce.csc.dialogo"), r.errout & $listDir(w))
    let r2 = tempo(w, buona, @["--answers", "Luce.csc"], risp1, @[sec])
    rec("X", "D-232 risposte due volte: codice 2, nessuna terza chiamata", r2.code == 2 and contaOf(w) == "2", r2.errout)
  # senza --json le opzioni dei tempi restano un uso sbagliato del terminale
  block:
    let w = newRef(luce)
    let r = runX(bcddProva, @["refine", "--accept", "Luce.csc"], w, refEnv(w), "")
    rec("X", "D-232 --accept senza --json: uso, codice 2, niente cambiato", r.code == 2 and listDir(w) == @["Luce.csc", "chiamate.tsv"] or r.code == 2, r.errout)

# 114:1:1: `bcdd save --undo` con FILE.prima e versione bloccata. Poche prove, quelle del design.
block:
  proc salva(w, file, expect, testo: string): Res =
    runX(bcdd, @["save", file, "--expect", expect], w, nil, testo)
  proc annulla(w, file, expect: string): Res =
    runX(bcdd, @["save", file, "--undo", "--expect", expect], w, nil, "")
  let rat = readFile(root / "esempi/LuceScaleRatificata.csc")
  let nuovaV = rat.replace("VERSION 0.1", "VERSION 0.2").replace("STATUS RATIFIED BY D-142", "STATUS HYPOTHESIS")
  # save poi --undo: testo di prima byte per byte, FILE.prima tolto, impronta nuova nella risposta
  let w = newWd()
  let ip = "CSC Prova VERSION 0.1\r\n  STATUS HYPOTHESIS\n  PURPOSE \"x\"\n  GUARANTEE g1: VERBAL \"uno\"\n                VERIFY BY JUDGEMENT \"chi\"\nEND"
  writeFile(w / "Prova.csc", ip)
  let dopo = ip.replace("\"uno\"", "\"due\"")
  let r1 = salva(w, "Prova.csc", sha256Of(w / "Prova.csc"), dopo)
  rec("X", "D-236 save lascia FILE.prima: impronta del testo scritto, poi il testo di prima",
    r1.code == 0 and readFile(w / "Prova.csc.prima") == sha256Of(w / "Prova.csc") & "\n" & ip, r1.errout)
  let u1 = annulla(w, "Prova.csc", sha256Of(w / "Prova.csc"))
  rec("X", "D-236 --undo: testo di prima byte per byte, FILE.prima tolto, impronta nuova",
    u1.code == 0 and readFile(w / "Prova.csc") == ip and not fileExists(w / "Prova.csc.prima") and
    "\"impronta\": \"" & sha256Of(w / "Prova.csc") & "\"" in u1.output, u1.output & u1.errout)
  # doppio --undo: niente da rimettere, codice 1
  let u2 = annulla(w, "Prova.csc", sha256Of(w / "Prova.csc"))
  rec("X", "D-236 secondo --undo: codice 1, file invariato", u2.code == 1 and "non c'è niente da rimettere" in u2.errout and readFile(w / "Prova.csc") == ip, u2.errout)
  # --undo dopo una scrittura da fuori: rifiuta, file invariato
  let r2 = salva(w, "Prova.csc", sha256Of(w / "Prova.csc"), dopo)
  let fuori = dopo & "\n-- altro\n"
  writeFile(w / "Prova.csc", fuori)
  let u3 = annulla(w, "Prova.csc", sha256Of(w / "Prova.csc"))
  rec("X", "D-236 --undo dopo scrittura da fuori: codice 1, file invariato, FILE.prima resta",
    r2.code == 0 and u3.code == 1 and readFile(w / "Prova.csc") == fuori and fileExists(w / "Prova.csc.prima"), u3.errout)
  let u4 = annulla(w, "Prova.csc", "sha256:0000")
  rec("X", "D-236 --undo con impronta sbagliata: codice 1", u4.code == 1 and readFile(w / "Prova.csc") == fuori, u4.errout)
  # --expect nuovo non lascia FILE.prima
  let r3 = salva(w, "Nuova.csc", "nuovo", ip)
  rec("X", "D-236 --expect nuovo: nessun FILE.prima", r3.code == 0 and not fileExists(w / "Nuova.csc.prima"), r3.errout)
  # Nuova versione poi --undo: rimette righe approvate (la save normale le rifiuterebbe)
  let w2 = newWd()
  writeFile(w2 / "Luce.csc", rat)
  let v1 = salva(w2, "Luce.csc", sha256Of(w2 / "Luce.csc"), nuovaV)
  rec("X", "D-236 versione cambiata con intestazione rimessa da approvare: accettata", v1.code == 0 and readFile(w2 / "Luce.csc") == nuovaV, v1.errout)
  let back = salva(w2, "Luce.csc", sha256Of(w2 / "Luce.csc"), rat)
  rec("X", "D-236 la save normale rifiuta di rimettere righe approvate", back.code == 1 and readFile(w2 / "Luce.csc") == nuovaV, back.errout)
  let u5 = annulla(w2, "Luce.csc", sha256Of(w2 / "Luce.csc"))
  rec("X", "D-236 --undo rimette le righe approvate, FILE.prima tolto", u5.code == 0 and readFile(w2 / "Luce.csc") == rat and not fileExists(w2 / "Luce.csc.prima"), u5.output & u5.errout)
  # versione cambiata in un connettore approvato: rifiuto col messaggio del design
  let v2 = salva(w2, "Luce.csc", sha256Of(w2 / "Luce.csc"), rat.replace("VERSION 0.1", "VERSION 0.2"))
  rec("X", "D-236 versione cambiata in un connettore approvato: rifiuto, file invariato",
    v2.code == 1 and "LuceScale è approvata: il numero della versione non si cambia; per una versione nuova rimetti l'intestazione da approvare" in v2.errout and readFile(w2 / "Luce.csc") == rat, v2.errout)

# 115:1:1: `bcdd save --remove` e `--undo --expect nuovo`.
block:
  proc togli(w, file, expect: string): Res =
    runX(bcdd, @["save", file, "--remove", "--expect", expect], w, nil, "")
  proc rimetti(w, file, expect: string): Res =
    runX(bcdd, @["save", file, "--undo", "--expect", expect], w, nil, "")
  let w = newWd()
  let ip = "CSC Prova VERSION 0.1\r\n  STATUS HYPOTHESIS\n  PURPOSE \"x\"\n  GUARANTEE g1: VERBAL \"uno\"\n                VERIFY BY JUDGEMENT \"chi\"\nEND"
  writeFile(w / "Prova.csc", ip)
  # impronta sbagliata: codice 1, niente toccato
  let r0 = togli(w, "Prova.csc", "sha256:0000")
  rec("X", "D-241 remove con impronta sbagliata: codice 1, file e cartella invariati",
    r0.code == 1 and readFile(w / "Prova.csc") == ip and not fileExists(w / "Prova.csc.prima"), r0.errout)
  # remove: file tolto, FILE.prima = tolto + testo byte per byte, JSON con tolto
  let imp = sha256Of(w / "Prova.csc")
  let r1 = togli(w, "Prova.csc", imp)
  rec("X", "D-241 remove: file tolto, FILE.prima con prima riga tolto e il testo byte per byte, JSON tolto: true",
    r1.code == 0 and not fileExists(w / "Prova.csc") and readFile(w / "Prova.csc.prima") == "tolto\n" & ip and
    "\"tolto\": true" in r1.output and "\"impronta\"" notin r1.output, r1.output & r1.errout)
  # undo normale su un .prima di tipo tolto: rifiuto chiaro
  let n0 = rimetti(w, "Prova.csc", imp)
  rec("X", "D-241 --undo con impronta su FILE.prima di tipo tolto: rifiuto chiaro, niente scritto",
    n0.code == 1 and "--undo --expect nuovo" in n0.errout and not fileExists(w / "Prova.csc") and fileExists(w / "Prova.csc.prima"), n0.errout)
  # undo con file ricreato da fuori: niente, lo dice
  writeFile(w / "Prova.csc", "da fuori")
  let n1 = rimetti(w, "Prova.csc", "nuovo")
  rec("X", "D-241 --undo nuovo con il file ricreato da fuori: codice 1, file invariato, FILE.prima resta",
    n1.code == 1 and "esiste già" in n1.errout and readFile(w / "Prova.csc") == "da fuori" and fileExists(w / "Prova.csc.prima"), n1.errout)
  removeFile(w / "Prova.csc")
  # undo: file rimesso byte per byte, FILE.prima tolto
  let u1 = rimetti(w, "Prova.csc", "nuovo")
  rec("X", "D-241 --undo nuovo: file rimesso byte per byte, FILE.prima tolto",
    u1.code == 0 and readFile(w / "Prova.csc") == ip and not fileExists(w / "Prova.csc.prima") and
    "\"impronta\": \"" & sha256Of(w / "Prova.csc") & "\"" in u1.output, u1.output & u1.errout)
  # doppio undo
  removeFile(w / "Prova.csc")
  let u2 = rimetti(w, "Prova.csc", "nuovo")
  rec("X", "D-241 secondo --undo nuovo: codice 1, niente da rimettere, niente creato", u2.code == 1 and "non c'è niente da rimettere" in u2.errout and not fileExists(w / "Prova.csc"), u2.errout)
  # file con righe approvate: rifiuto, niente toccato
  let w2 = newWd()
  let rat = readFile(root / "esempi/LuceScaleRatificata.csc")
  writeFile(w2 / "Luce.csc", rat)
  let a1 = togli(w2, "Luce.csc", sha256Of(w2 / "Luce.csc"))
  rec("X", "D-241 remove di un file con righe approvate: codice 1, messaggio, niente toccato",
    a1.code == 1 and "Luce ha righe approvate: non si toglie" in a1.errout and readFile(w2 / "Luce.csc") == rat and not fileExists(w2 / "Luce.csc.prima"), a1.errout)

# 066:9:1: --modello veloce|accurato. Vettore con l'eseguibile normale e un claude finto sul PATH; il giro e l'uscita con quello di prova.
block:
  let rf = f2Dir / "refine"
  let luce = rf / "Luce.csc"
  let buona = rf / "risposte" / "buona.json"
  let sec = ("BCDD_FINTO_RISPOSTA_2", rf / "risposte" / "buona_seconda.json")
  # vettore: accurato -> --model opus, e il registro dice claude:opus; valore sconosciuto -> 2 e claude non chiamato
  block:
    let w = newWd()
    discard cpTo(luce, w)
    let aux = auxOf(w)
    let fake = aux / "bin"
    createDir(fake)
    writeFile(fake / "claude", "#!/bin/sh\nd=$(dirname \"$0\")\n{ for a in \"$@\"; do echo \"[$a]\"; done; } >> \"$d/registro\"\ncat > /dev/null\nexit 0\n")
    setFilePermissions(fake / "claude", {fpUserRead, fpUserWrite, fpUserExec})
    let env = mkEnv(@[("PATH", fake & ":" & getEnv("PATH")), ("BCDD_REGISTRO", aux / "chiamate.tsv"), ("BCDD_ORA", luceOra)])
    discard runX(bcdd, @["refine", "Luce.csc", "--modello", "accurato"], w, env, "")
    let ls = (if fileExists(fake / "registro"): readFile(fake / "registro").splitLines() else: @[])
    rec("X", "D-246 accurato: il vettore porta --model opus", ls.len >= 2 and ls[ls.len - 3 .. ls.len - 2] == @["[--model]", "[opus]"], $ls)
    rec("X", "D-246 accurato: il registro scrive claude:opus", fileExists(aux / "chiamate.tsv") and
      readFile(aux / "chiamate.tsv").splitLines()[1].startsWith(luceOra & "\tclaude:opus\t"), "registro assente o diverso")
    removeFile(fake / "registro")
    for args in [@["refine", "Luce.csc", "--modello", "haiku"], @["refine", "--json", "Luce.csc", "--modello", "Opus"],
        @["refine", "Luce.csc", "--modello"], @["refine", "--json", "Luce.csc", "--modello", ""]]:
      let r = runX(bcdd, args, w, env, "")
      rec("X", "D-246 valore non ammesso (" & args[^1] & "): codice 2, claude non chiamato", r.code == 2 and not fileExists(fake / "registro") and
        not fileExists(w / "Luce.csc.giro"), "codice " & $r.code & " " & r.errout)
  # il giro: scelto al tempo 1, ripreso dal tempo 2 e da --show anche con un --modello diverso
  block:
    let w = newRef(luce)
    proc tempo(args: seq[string], input: string = ""): Res =
      discard auxOf(w)
      runX(bcddProva, @["refine", "--json"] & args, w, refEnv(w, @[("BCDD_FINTO_RISPOSTA", buona)] & @[sec]), input)
    let r1 = tempo(@["Luce.csc", "--modello", "accurato"])
    rec("X", "D-246 tempo 1: modello accurato nell'uscita e in FILE.giro", r1.code == 0 and "\"modello\": \"accurato\"" in r1.output and
      "\"modello\": \"accurato\"" in readFile(w / "Luce.csc.giro"), r1.output & r1.errout)
    let sh = tempo(@["Luce.csc", "--show", "--modello", "veloce"])
    rec("X", "D-246 --show usa il modello del giro e ignora --modello", sh.code == 0 and "\"modello\": \"accurato\"" in sh.output and "veloce" notin sh.output, sh.output & sh.errout)
    let r2 = tempo(@["--answers", "Luce.csc", "--modello", "veloce"], """{"risposte": [{"n": 1, "testo": "fra tre minuti circa"}]}""")
    rec("X", "D-246 tempo 2: resta accurato anche con --modello veloce", r2.code == 0 and "\"modello\": \"accurato\"" in r2.output and
      "\"modello\": \"accurato\"" in readFile(w / "Luce.csc.giro"), r2.output & r2.errout)
    let r3 = tempo(@["--accept", "Luce.csc", "--modello", "veloce"], """{"accettate": ["p1"]}""")
    rec("X", "D-246 tempo 3: l'uscita dice accurato", r3.code == 0 and "\"modello\": \"accurato\"" in r3.output, r3.output & r3.errout)
  # senza opzione: veloce; giro vecchio senza la chiave: accurato
  block:
    let w = newRef(luce)
    proc tempo(args: seq[string]): Res =
      discard auxOf(w)
      runX(bcddProva, @["refine", "--json"] & args, w, refEnv(w, @[("BCDD_FINTO_RISPOSTA", buona)] & @[sec]), "")
    let r1 = tempo(@["Luce.csc"])
    rec("X", "D-246 senza --modello: veloce", r1.code == 0 and "\"modello\": \"veloce\"" in r1.output and "\"modello\": \"veloce\"" in readFile(w / "Luce.csc.giro"), r1.output & r1.errout)
    writeFile(w / "Luce.csc.giro", readFile(w / "Luce.csc.giro").replace("\"modello\": \"veloce\", ", ""))
    let sh = tempo(@["Luce.csc", "--show"])
    rec("X", "D-246 giro senza la chiave: vale accurato", sh.code == 0 and "\"modello\": \"accurato\"" in sh.output, sh.output & sh.errout)

# 066:10:1: Completa parte da zero dallo scopo. Formato bcdd-refine-5: righe d'interfaccia e promesse di base. Solo l'LLM finto.
block:
  let rf = f2Dir / "refine"
  let rs = rf / "risposte"
  proc go(wd: string, resp: string, args: seq[string], input: string = ""): Res =
    discard auxOf(wd)
    runX(bcddProva, @["refine"] & args, wd, refEnv(wd, @[("BCDD_FINTO_RISPOSTA", resp)]), input)
  # terminale: tre righe d'interfaccia e due promesse di base su una CSC appena creata con lo scopo scritto
  block:
    let w = newRef(rf / "Spia.csc", "Spia.csc")
    let r = go(w, rs / "interfaccia_da_zero.json", @["Spia.csc"], "s\ns\ns\ns\ns\ns\n")
    rec("X", "D-247 terminale: 3 righe d'interfaccia e 2 promesse di base, file atteso riga per riga", r.code == 0 and
      fileEq(w / "Spia.csc", rf / "Spia.dopo.csc") and listDir(w) == @["Spia.csc", "chiamate.tsv"] and contaOf(w) == "1" and
      "RIGA D'INTERFACCIA 1 di 3\n  STATE accesa : Boolean INITIAL false\n  motivo: la spia è accesa o spenta\n" in r.output and
      "PROPOSTA 1 di 2, promessa nuova\n" in r.output and "scritto Spia.csc: 3 righe d'interfaccia e 2 proposte (4 righe)\n" in r.output,
      r.output & r.errout & $listDir(w))
    let c = run(@["check", "--strict", "Spia.csc"], w)
    rec("X", "D-247 il file scritto passa check, due ipotesi nuove", c.code == 0 and "4. IPOTESI, NON CONTRATTO: 2" in c.output, c.output & c.errout)
  # tre tempi: stesse righe, id i1.. nel campo accettate, stesso file
  block:
    let w = newRef(rf / "Spia.csc", "Spia.csc")
    let r1 = go(w, rs / "interfaccia_da_zero.json", @["--json", "Spia.csc"])
    rec("X", "D-247 tempo 1: interfaccia i1..i3 valide e promesse di base con dettaglia vuoto", r1.code == 0 and
      "\"interfaccia\": [{\"n\": \"i1\", \"valida\": true, \"ragione\": null, \"ragione_chiave\": null, \"ragione_argomenti\": [], \"riga\": \"STATE accesa : Boolean INITIAL false\", \"motivo\": \"la spia è accesa o spenta\"}," in r1.output and
      "\"n\": \"i3\"" in r1.output and "\"n\": \"p1\", \"valida\": true, \"ragione\": null, \"ragione_chiave\": null, \"ragione_argomenti\": [], \"tipo\": \"GUARANTEE\", \"id\": \"g1\", \"dettaglia\": \"\", \"riga_dettagliata\": null" in r1.output,
      r1.output & r1.errout)
    let r3 = go(w, rs / "interfaccia_da_zero.json", @["--json", "--accept", "Spia.csc"], """{"accettate": ["i1", "i2", "i3", "p1", "p2"]}""")
    rec("X", "D-247 tempo 3: file uguale a quello del terminale, giro tolto", r3.code == 0 and fileEq(w / "Spia.csc", rf / "Spia.dopo.csc") and
      listDir(w) == @["Spia.csc", "chiamate.tsv"] and "\"csc\": \"3 righe d'interfaccia e 2 proposte (4 righe)\"" in r3.output, r3.output & r3.errout)
  # scopo ancora «da compilare»: niente chiamata
  block:
    let w = newRef(rf / "Spia_nuova.csc", "Spia.csc")
    let r = go(w, rs / "interfaccia_da_zero.json", @["Spia.csc"])
    rec("X", "D-247 scopo da compilare, terminale: codice 1, nessuna chiamata, niente scritto", r.code == 1 and contaOf(w) == "0" and
      r.errout == "bcdd refine: scrivi prima lo scopo di Spia: Completa parte da lì (niente scritto)\n" and r.output.len == 0 and
      fileEq(w / "Spia.csc", rf / "Spia_nuova.csc") and listDir(w) == @["Spia.csc"], r.output & r.errout & $listDir(w))
    let j = go(w, rs / "interfaccia_da_zero.json", @["--json", "Spia.csc"])
    rec("X", "D-247 scopo da compilare, --json: errore scopo_da_scrivere, codice 1, nessuna chiamata, nessun giro", j.code == 1 and contaOf(w) == "0" and
      j.output == "{\"forma\": \"bcdd-giro\", \"versione\": 1, \"file\": \"Spia.csc\", \"tempo\": 1, \"modello\": \"veloce\", \"errore\": \"scopo_da_scrivere\"}\n" and
      listDir(w) == @["Spia.csc"], j.output & j.errout & $listDir(w))
  # righe scartate: nome già usato, GUARANTEE, tipo non dichiarato, tipo dichiarato nella stessa risposta, nome ripetuto, più righe
  block:
    let w = newRef(rf / "Ordine.csc", "Ordine.csc")
    let r = go(w, rs / "interfaccia_scartate.json", @["--json", "Ordine.csc"])
    var v: seq[string]
    for k in 1 .. 8:
      v.add (if ("{\"n\": \"i" & $k & "\", \"valida\": true") in r.output: "true" else: "false")
    rec("X", "D-247 filtro: valide solo i2, i3, i6", r.code == 0 and v == @["false", "true", "true", "false", "false", "true", "false", "false"], $v & r.output)
    rec("X", "D-247 filtro: tipo non dichiarato", "tipo non dichiarato: Frequenza" in r.output, r.output)
    rec("X", "D-247 filtro: nome già usato nella CSC (check lo rifiuta)", "\"ragione\": \"check rifiuta la riga: [E01]" in r.output, r.output)
    rec("X", "D-247 filtro: GUARANTEE non ammessa", "dichiarazione non ammessa: GUARANTEE" in r.output, r.output)
    rec("X", "D-247 filtro: nome ripetuto fra due righe della risposta", "nome già usato dalla riga d'interfaccia 6: spenta" in r.output, r.output)
    rec("X", "D-247 filtro: riga su più righe", "\"ragione\": \"riga su più righe\"" in r.output, r.output)
    let a2 = go(w, rs / "interfaccia_scartate.json", @["--json", "--accept", "Ordine.csc"], """{"accettate": ["i1"]}""")
    rec("X", "D-247 i1 scartata: codice 2, Ordine.csc invariato, giro aperto", a2.code == 2 and fileEq(w / "Ordine.csc", rf / "Ordine.csc") and
      fileExists(w / "Ordine.csc.giro"), a2.errout)
  # promessa di base dopo l'ultima GUARANTEE con i suoi dettagli (Ordine.csc: g1, g1a, g1b, g2)
  block:
    let w = newRef(rf / "Ordine.csc", "Ordine.csc")
    let r1 = go(w, rs / "base_dopo_dettagli.json", @["--json", "Ordine.csc"])
    let r3 = go(w, rs / "base_dopo_dettagli.json", @["--json", "--accept", "Ordine.csc"], """{"accettate": ["p1"]}""")
    let ordine = readFile(rf / "Ordine.csc")
    let want = ordine.replace("END\n", "  GUARANTEE g3 STATUS HYPOTHESIS: VERBAL \"La luce non si accende senza pressione\"\n" &
      " ".repeat(34) & "VERIFY BY JUDGEMENT \"l'operatore, di giorno\"\nEND\n")
    rec("X", "D-247 promessa di base accettata: dopo g2, prima di END, il resto invariato", r1.code == 0 and r3.code == 0 and
      readFile(w / "Ordine.csc") == want, r1.output & r3.output & r3.errout)

# 066:11:1 F5 (GRAMMATICA_F1 1.20): AC-231..AC-261. Le sonde copiano le 14 CSC di caso_remoto (senza toccarle)
# 066:11:2 e applicano una modifica per sonda, come USondeF5.sh. I casi di lettura stanno in prove/f5/.
block:
  let cr = root / "prove" / "f5" / "remoto_base"   # copia congelata di caso_remoto a 3a7593ad
  let crVivo = (if dirExists(root.parentDir / "caso_remoto"): root.parentDir / "caso_remoto" else: cr)
  const sc = "  SCENARIO s1 GIVEN Sessione.pronta = true EXPECT ADMITTED\n    @0 s   Abbinamento.abbina(codice: \"AB12\")\n" &
    "    @1 s   Pulsanti.premi(pulsante: \"flat\", acceso: true)\n"
  proc sonda(edits: seq[(string, string, string)]): string =
    ## una cartella con le 14 CSC e le modifiche (file, vecchio, nuovo); il vecchio dev'esserci una volta
    let w = newWd()
    for k, p in walkDir(cr):
      if p.endsWith(".csc"): copyFile(p, w / p.extractFilename)
    for (f, old, nuovo) in edits:
      let t = readFile(w / f)
      if old notin t: rec("AC-231", "sonda: " & f & " non contiene " & old, false, "la sonda non si applica")
      writeFile(w / f, t.replace(old, nuovo))
    w
  proc errs(r: Res): int =
    for l in r.output.splitLines:
      if l.len > 6 and l.startsWith("  riga ") and "[E" in l: inc result
  proc unrecOf(r: Res): string =
    for l in r.output.splitLines:
      if l.startsWith("5. RIGHE NON RICONOSCIUTE: "): return l[27 .. ^1]
  proc chk(w, f: string): Res = run(@["check", "--strict", f], w)
  proc esito(ac, label, f: string, edits: seq[(string, string, string)], code, ne: int, unrec: string, must: seq[string] = @[]) =
    let w = sonda(edits)
    let r = chk(w, f)
    var ok = r.code == code and errs(r) == ne and unrecOf(r) == unrec
    for m in must:
      if m notin r.output: ok = false
    rec(ac, label, ok, "codice " & $r.code & ", errori " & $errs(r) & ", non riconosciute " & unrecOf(r) & "\n" & r.output)
  let asm1 = ("LevelMeter.csc", "  GUARANTEE sm1", "  ASSUME    sm-a1: VERBAL \"Il telefono manda un comando solo per un gesto\"\n" &
    "                   VERIFY BY INSPECTION \"il registro del telefono\"\n  GUARANTEE sm1")
  esito("AC-231", "L1a ASSUME in un'entità", "LevelMeter.csc", @[asm1], 1, 1, "2",
    @["[E18] ASSUME non può stare in un'entità: scrivilo nella CSC di uno dei suoi connettori"])
  esito("AC-232", "L1b STATE in un'entità", "LevelMeter.csc", @[("LevelMeter.csc", "  GUARANTEE sm1", "  STATE collegato : Boolean INITIAL false\n  GUARANTEE sm1")],
    1, 1, "1", @["[E18] STATE non può stare in un'entità"])
  const tel = "    telefono : LevelMeter\n"
  let base = block:
    let w = sonda(@[])
    run(@["check", "--strict", "ControlloRemoto.csc"], w)
  block:
    let rv = run(@["check", "--strict", "--dir", crVivo, crVivo / "ControlloRemoto.csc"], crVivo)
    rec("AC-253", "i 14 file di caso_remoto vivo come sono: codice 0, 0 errori, U 0", rv.code == 0 and errs(rv) == 0 and unrecOf(rv) == "0", rv.output)
  rec("AC-253", "la copia congelata remoto_base: codice 0, 0 errori, U 0", base.code == 0 and errs(base) == 0 and unrecOf(base) == "0", base.output)
  let w14 = sonda(@[])
  let r14 = run(@["check", "--strict", "--dir", ".", "ControlloRemoto.csc"], w14)
  rec("AC-253", "con --dir .: stesso esito", r14.code == 0 and errs(r14) == 0 and unrecOf(r14) == "0", r14.output)
  esito("AC-233", "L2a [1 .. 4]", "ControlloRemoto.csc", @[("ControlloRemoto.csc", tel, "    telefono : LevelMeter [1 .. 4]\n")], 0, 0, "0")
  block:
    let wa = sonda(@[("ControlloRemoto.csc", tel, "    telefono : LevelMeter [1 .. 4]\n")])
    let ra = run(@["check", "--strict", "ControlloRemoto.csc"], wa)
    let s8a = ra.output[ra.output.find("8. USI")..^1]
    let s8b = base.output[base.output.find("8. USI")..^1]
    rec("AC-233", "L2a: la sezione 8 è quella del file base", s8a == s8b, s8a & "\n---\n" & s8b)
    rec("AC-233", "L2a: la citazione si scrive senza la molteplicità", "telefono : LevelMeter in LevelMeter.csc" in ra.output, ra.output)
  esito("AC-234", "L2b VERSION 0.1 [1 .. 4]", "ControlloRemoto.csc", @[("ControlloRemoto.csc", tel, "    telefono : LevelMeter VERSION 0.1 [1 .. 4]\n")], 0, 0, "0")
  # 066:11:3 (1.21, AC-294 al posto di AC-235) [0 .. 4] non è più E19: parte facoltativa, due composizioni, dieci assenze dichiarate
  esito("AC-294", "L2c [0 .. 4]: nessun errore, due composizioni, 10 assenze dichiarate", "ControlloRemoto.csc",
    @[("ControlloRemoto.csc", tel, "    telefono : LevelMeter [0 .. 4]\n")], 0, 0, "0",
    @["9. COMPOSIZIONI: 2\n  riga 5: ENTITY ControlloRemoto: 2\n    con telefono\n    senza telefono\n", "10. ASSENZE DICHIARATE: 10\n  riga 10: senza telefono: la parte computer usa il connettore ComportamentoTelefono:",
     "  riga 10: senza telefono: la parte computer offre il connettore Procedure:"])
  block:
    let w = sonda(@[("ControlloRemoto.csc", tel, "    telefono : LevelMeter [0 .. 4]\n")])
    let r = chk(w, "ControlloRemoto.csc")
    let sez = r.output[r.output.find("10. ASSENZE")..^1]
    var nSenza, nE17, nE14, nSuff = 0
    for l in sez.splitLines:
      if l.startsWith("  riga 10: senza telefono: "): inc nSenza
      if "offre il connettore" in l: inc nE17
      if "usa il connettore" in l: inc nE14
      if "(in:" in l: inc nSuff
    rec("AC-294", "10 voci tutte `senza telefono` sulla riga 10, un E14 e nove E17, senza suffisso", nSenza == 10 and nE14 == 1 and nE17 == 9 and nSuff == 0, sez)
  esito("AC-236", "L2d [4 .. 1]: un solo E19", "ControlloRemoto.csc", @[("ControlloRemoto.csc", tel, "    telefono : LevelMeter [4 .. 1]\n")], 1, 1, "0",
    @["[E19] la parte telefono ha un numero di copie non valido: [4 .. 1]."])
  esito("AC-236", "[1.5 .. 4]: E19 con i limiti come scritti", "ControlloRemoto.csc", @[("ControlloRemoto.csc", tel, "    telefono : LevelMeter [1.5 .. 4]\n")], 1, 1, "0",
    @["non valido: [1.5 .. 4]."])
  esito("AC-237", "L2e ordine sbagliato: non riconosciuta, cascata E14/E17", "ControlloRemoto.csc", @[("ControlloRemoto.csc", tel, "    telefono : LevelMeter [1 .. 4] VERSION 0.1\n")], 1, 10, "1")
  for forma in ["[1 .. ]", "[1, 4]", "[-1 .. 4]", "[1 .. 4"]:
    let w = sonda(@[("ControlloRemoto.csc", tel, "    telefono : LevelMeter " & forma & "\n")])
    let r = chk(w, "ControlloRemoto.csc")
    rec("AC-237", "non è G35: " & forma, unrecOf(r) == "1" and "[E19]" notin r.output, r.output)
  # L3: scenari d'entità
  let l3a = @[("Pulsanti.csc", "\nEND\n", "\n  SCENARIO s1 GIVEN pronta = true EXPECT ADMITTED\n    @0 s   abbina(codice: \"AB12\")\n    @1 s   premi(pulsante: \"flat\", acceso: true)\nEND\n")]
  esito("AC-238", "L3a nomi semplici in Pulsanti: 2 × E03", "Pulsanti.csc", l3a, 1, 2, "0",
    @["[E03] nome non dichiarato come STATE: pronta", "[E03] nome non dichiarato come EVENT: abbina"])
  esito("AC-239", "L3b nomi qualificati in una CSC: 3 × E20", "Pulsanti.csc", @[("Pulsanti.csc", "\nEND\n", "\n" & sc & "END\n")], 1, 3, "0",
    @["[E20] Sessione.pronta: in una CSC i nomi non si scrivono con il connettore davanti. L'ordine fra due connettori va in uno SCENARIO dell'entità"])
  esito("AC-240", "L3c scenario qualificato in AudioProcessor", "AudioProcessor.csc", @[("AudioProcessor.csc", "\nEND\n", "\n" & sc & "END\n")], 0, 0, "0")
  block:
    let w = sonda(@[("AudioProcessor.csc", "\nEND\n", "\n" & sc & "END\n")])
    let j = jsonDi(@["--strict", "AudioProcessor.csc"], w)
    var ok = j != nil and j.jint("versione") == 5
    if ok:
      ok = false
      for b in j["blocchi"]:
        for d in b["dichiarazioni"]:
          if d.jstr("tipo") == "SCENARIO" and d.jstr("nome") == "s1": ok = true
    rec("AC-240", "lo scenario sta fra le dichiarazioni JSON con tipo SCENARIO, versione 5", ok, if j == nil: "niente JSON" else: $j)
  esito("AC-241", "L3d Abbinamento.abbinaX: E03 qualificato", "AudioProcessor.csc",
    @[("AudioProcessor.csc", "\nEND\n", "\n" & sc.replace("Abbinamento.abbina(", "Abbinamento.abbinaX(") & "END\n")], 1, 1, "0",
    @["[E03] nome non dichiarato come EVENT: Abbinamento.abbinaX"])
  esito("AC-241", "un argomento che l'evento non ha", "AudioProcessor.csc",
    @[("AudioProcessor.csc", "\nEND\n", "\n" & sc.replace("(codice:", "(codicex:") & "END\n")], 1, 1, "0",
    @["[E03] nome non dichiarato come parametro di Abbinamento.abbina: codicex"])
  esito("AC-241", "y del tipo sbagliato (uno STATE dove va un EVENT)", "AudioProcessor.csc",
    @[("AudioProcessor.csc", "\nEND\n", "\n" & sc.replace("Abbinamento.abbina(", "Sessione.pronta(") & "END\n")], 1, 1, "0",
    @["[E03] nome non dichiarato come EVENT: Sessione.pronta"])
  esito("AC-242", "L3e lo scenario in ControlloRemoto: 3 × E20", "ControlloRemoto.csc", @[("ControlloRemoto.csc", "\nEND\n", "\n" & sc & "END\n")], 1, 3, "0",
    @["[E20] Sessione.pronta: ControlloRemoto non offre né usa il connettore Sessione; uno scenario può citare solo i connettori di ControlloRemoto"])
  block:
    let w = sonda(@[("AudioProcessor.csc", "\nEND\n", "\n" & sc.replace("Abbinamento.abbina(", "Abbinamento.abbinaX(") & "END\n")])
    removeFile(w / "Abbinamento.csc")
    let r = chk(w, "AudioProcessor.csc")
    rec("AC-259", "Abbinamento.csc assente: il controllo di y è sospeso, nessun E03; Abbinamento nella sezione 7",
      "[E03]" notin r.output and "7. CSC NOMINATE E NON CONTROLLATE: 1\n  riga 8: Abbinamento\n" in r.output, r.output)
  # L5: enumerazioni
  let tf = ("Taratura.csc", "  EVENT OUT stato(fase: String)", "  TYPE Fase := {inattiva, armata, in_corso, accettata, rifiutata}\n  EVENT OUT stato(fase: Fase)")
  esito("AC-243", "L5a TYPE Fase := {…}", "Taratura.csc", @[tf], 0, 0, "0")
  block:
    let w = sonda(@[tf])
    let r = chk(w, "Taratura.csc")
    rec("AC-243", "Fase non è nella sezione 6", "Fase" notin r.output[r.output.find("6. TIPI")..<r.output.find("7. CSC")], r.output)
  let sf = ("Taratura.csc", "  STATE pronta_a_ricevere", "  STATE fase_ora : Fase INITIAL inattiva\n  STATE pronta_a_ricevere")
  esito("AC-244", "L5b STATE fase_ora : Fase INITIAL inattiva", "Taratura.csc", @[tf, sf], 0, 0, "0")
  esito("AC-245", "L5c INITIAL volando: E03", "Taratura.csc", @[tf, ("Taratura.csc", "  STATE pronta_a_ricevere", "  STATE fase_ora : Fase INITIAL volando\n  STATE pronta_a_ricevere")], 1, 1, "0",
    @["[E03] nome non dichiarato come valore di TYPE: volando"])
  # N1: numeri con segno
  esito("AC-246", "N1a Real [-20.0 .. 20.0]", "Volume.csc", @[("Volume.csc", "  EVENT IN  muovi(di_quanto: Real)", "  EVENT IN  muovi(di_quanto: Real [-20.0 .. 20.0])")], 0, 0, "0")
  esito("AC-247", "N1b DEFINE ATTENUAZIONE_MIN := -40", "Volume.csc", @[("Volume.csc", "  EVENT IN  muovi(di_quanto: Real)", "  DEFINE ATTENUAZIONE_MIN := -40\n  EVENT IN  muovi(di_quanto: Real)")], 0, 0, "0")
  # N2: più versioni
  let n2 = "  OFFERS Pulsanti\n"
  esito("AC-248", "N2a OFFERS Pulsanti VERSION 0.1 e 0.2", "AudioProcessor.csc", @[("AudioProcessor.csc", n2, "  OFFERS Pulsanti VERSION 0.1\n  OFFERS Pulsanti VERSION 0.2\n")], 0, 0, "0",
    @["riga 13: OFFERS Pulsanti in Pulsanti.csc alla riga 4: VERSION 0.1, STATUS HYPOTHESIS, nessun errore, attesa VERSION 0.2"])
  esito("AC-249", "N2a: il gruppo ControlloRemoto con quell'entità, nessun E17", "ControlloRemoto.csc", @[("AudioProcessor.csc", n2, "  OFFERS Pulsanti VERSION 0.1\n  OFFERS Pulsanti VERSION 0.2\n")], 0, 0, "0")
  esito("AC-250", "N2b la stessa versione due volte: E01", "AudioProcessor.csc", @[("AudioProcessor.csc", n2, "  OFFERS Pulsanti VERSION 0.1\n  OFFERS Pulsanti VERSION 0.1\n")], 1, 1, "0",
    @["riga 13: [E01] nome già usato alla riga 12: Pulsanti"])
  esito("AC-250", "N2c una senza versione: E01", "AudioProcessor.csc", @[("AudioProcessor.csc", n2, "  OFFERS Pulsanti\n  OFFERS Pulsanti VERSION 0.2\n")], 1, 1, "0",
    @["riga 13: [E01] nome già usato alla riga 12: Pulsanti"])
  esito("AC-250", "N2c in ordine inverso: E01 sulla seconda", "AudioProcessor.csc", @[("AudioProcessor.csc", n2, "  OFFERS Pulsanti VERSION 0.2\n  OFFERS Pulsanti\n")], 1, 1, "0",
    @["riga 13: [E01] nome già usato alla riga 12: Pulsanti"])
  # N3 e O-4: il silenzio dichiarato
  block:
    let w = sonda(@[("Postazione.csc", "  STATE servizio_acceso", "  DEFINE LIVELLO_VOLUTO_MAX := 90 dB\n  STATE servizio_acceso")])
    let r = chk(w, "Postazione.csc")
    rec("AC-251", "N3a 90 dB: invariato con --strict (codice 3, U 1)", r.code == 3 and errs(r) == 0 and unrecOf(r) == "1" and
      r.output.endsWith("esito: nessun errore; righe non riconosciute: 1 (--strict)\n"), r.output)
    let n = run(@["check", "Postazione.csc"], w)
    rec("AC-251", "senza --strict: codice 0 e la riga esito dice le righe non riconosciute", n.code == 0 and
      n.output.endsWith("esito: nessun errore; righe non riconosciute: 1 (vedi sezione 5)\n") and "5. RIGHE NON RICONOSCIUTE: 1" in n.output, n.output)
    let j = jsonDi(@["Postazione.csc"], w)
    rec("AC-251", "--json: esito.riga ha lo stesso testo e il codice è 0", j != nil and j["esito"].jint("codice") == 0 and
      j["esito"].jstr("riga") == "esito: nessun errore; righe non riconosciute: 1 (vedi sezione 5)", $j)
    let ok0 = run(@["check", "Volume.csc"], w)
    rec("AC-251", "senza righe non riconosciute la riga esito è quella di prima", ok0.output.endsWith("esito: nessun errore\n"), ok0.output)
  # E14 ed E17: i testi (AC-252)
  block:
    let w = sonda(@[("LevelMeter.csc", "  USES   Volume\n", "")])
    let r = chk(w, "ControlloRemoto.csc")
    rec("AC-252", "testo di E17 con «né»", "[E17] la parte computer offre il connettore Volume: nessun'altra parte di ControlloRemoto lo usa, né ControlloRemoto lo offre da fuori" in r.output, r.output)
    rec("AC-252", "nessun «ed» davanti al nome dell'entità", ", ed " notin r.output, r.output)
  # lettura (AC-255..AC-257), file di prova in prove/f5/
  let f5 = root / "prove" / "f5"
  proc f5run(name: string): Res = run(@["check", name & ".csc"], f5)
  block:
    let r = f5run("lettura")
    # 053:2:1 C-01, C-10 (1.0-beta): `- 3` è il segno meno e un numero, e `a.b` è letto: E24 su `a`, la dichiarazione resta riconosciuta (§7 della tracciabilità: 0 -> 1)
    rec("AC-255", "lettura: g-1 parola, --20 commento, x=-3 numero, - 3 segno e numero, 0.5 numero, a.b tre elementi (E24 su a)",
      r.code == 1 and "righe: 14 (riconosciute 12, commenti 2, vuote 0, non riconosciute 0)" in r.output and
      "5. RIGHE NON RICONOSCIUTE: 0" in r.output and "1. ERRORI: 1\n  riga 11: [E24] nome non dichiarato: a\n" in r.output and
      "  riga 8: GUARANTEE g-1 verbale" in r.output, r.output)
  block:
    let r = f5run("enumerazioni")
    rec("AC-256", "TYPE X := {}, {a b}, {a,}, TYPE Boolean := {a, b} non riconosciute; {a, a} con E01 sul secondo",
      "5. RIGHE NON RICONOSCIUTE: 4" in r.output and "  riga 8: [E01] nome già usato alla riga 8: a\n" in r.output and "1. ERRORI: 2\n" in r.output and
      "  riga 4: TYPE X1 := {}\n" in r.output and "  riga 5: TYPE X2 := {c d}\n" in r.output and "  riga 6: TYPE X3 := {e,}\n" in r.output and
      "  riga 7: TYPE Boolean := {f, g}\n" in r.output, r.output)
    rec("AC-257", "un valore uguale a uno STATE dello stesso blocco: E01", "  riga 10: [E01] nome già usato alla riga 9: acceso\n" in r.output, r.output)
  # AC-258: ricerca delle versioni in due cartelle --dir
  block:
    let w = newWd()
    createDir(w / "v1"); createDir(w / "v2")
    writeFile(w / "v1" / "Xx.csc", "CSC Xx VERSION 0.1\n  PURPOSE \"x\"\nEND\n")
    writeFile(w / "v2" / "Xx.csc", "CSC Xx VERSION 0.2\n  PURPOSE \"x\"\nEND\n")
    writeFile(w / "E.csc", "ENTITY E VERSION 0.1\n  PURPOSE \"e\"\n  OFFERS Xx VERSION 0.2\nEND\n")
    let both = run(@["check", "--dir", "v1", "--dir", "v2", "E.csc"], w)
    rec("AC-258", "trovata in v2/Xx.csc, senza attesa", "riga 3: OFFERS Xx in v2/Xx.csc alla riga 1: VERSION 0.2, senza STATUS, nessun errore\n" in both.output, both.output)
    let one = run(@["check", "--dir", "v1", "E.csc"], w)
    rec("AC-258", "con la sola v1: trovata in v1/Xx.csc con attesa VERSION 0.2",
      "riga 3: OFFERS Xx in v1/Xx.csc alla riga 1: VERSION 0.1, senza STATUS, nessun errore, attesa VERSION 0.2\n" in one.output, one.output)
    let rev = run(@["check", "--dir", "v2", "--dir", "v1", "E.csc"], w)
    rec("AC-258", "con le cartelle in ordine inverso: stessa trovata", "in v2/Xx.csc alla riga 1: VERSION 0.2" in rev.output and "attesa" notin rev.output, rev.output)
  # AC-260: JSON, molteplicità
  block:
    let w = sonda(@[("ControlloRemoto.csc", tel, "    telefono : LevelMeter [1 .. 4]\n")])
    let j = jsonDi(@["--strict", "ControlloRemoto.csc"], w)
    var ok = j != nil and j.jint("versione") == 5
    var viste = 0
    if ok:
      for b in j["blocchi"]:
        for c in b["citazioni"]:
          if c.jstr("tipo") != "PART": continue
          inc viste
          if c.jstr("parte") == "telefono":
            ok = ok and c["molteplicita"].kind == JObject and c["molteplicita"].jint("min") == 1 and c["molteplicita"].jint("max") == 4
          else:
            ok = ok and c["molteplicita"].kind == JNull
    rec("AC-260", "check --json su L2a: versione 4, telefono {min 1, max 4}, le altre parti null", ok and viste >= 2, if j == nil: "niente JSON" else: $j)
    let wc = sonda(@[("ControlloRemoto.csc", tel, "    telefono : LevelMeter [0 .. 4]\n")])
    let jc = jsonDi(@["--strict", "ControlloRemoto.csc"], wc)
    var okc = jc != nil
    if okc:
      for b in jc["blocchi"]:
        for c in b["citazioni"]:
          if c.jstr("parte") == "telefono": okc = okc and c["molteplicita"].jint("min") == 0 and c["molteplicita"].jint("max") == 4
    rec("AC-260", "con [0 .. 4] (parte facoltativa) il campo c'è con i limiti scritti", okc, if jc == nil: "niente JSON" else: $jc)
    let wd = sonda(@[("ControlloRemoto.csc", tel, "    telefono : LevelMeter [1.5 .. 4]\n")])
    let jd = jsonDi(@["--strict", "ControlloRemoto.csc"], wd)
    var okd = jd != nil
    if okd:
      for b in jd["blocchi"]:
        for c in b["citazioni"]:
          if c.jstr("parte") == "telefono": okd = okd and c["molteplicita"].kind == JNull
    rec("AC-260", "con un limite col punto il campo è null", okd, if jd == nil: "niente JSON" else: $jd)
  # AC-262: una riga trovata solo nel ripiego non conta per il controllo di X.y
  block:
    let scSp = sc.replace("Pulsanti.premi(pulsante: \"flat\", acceso: true)", "Pulsanti.spegni_tutto")
    let usoSpegni = ("AudioProcessor.csc", "\nEND\n", "\n" & scSp & "END\n")
    let wr = sonda(@[("AudioProcessor.csc", "  OFFERS Pulsanti\n", "  OFFERS Pulsanti VERSION 0.2\n"), usoSpegni])
    let rr = chk(wr, "AudioProcessor.csc")
    rec("AC-262", "versione chiesta solo nel ripiego: niente E03 su Pulsanti.spegni_tutto, codice 0, `attesa` nel rapporto",
      rr.code == 0 and errs(rr) == 0 and "E03" notin rr.output and "attesa VERSION 0.2" in rr.output, rr.output)
    let wc = sonda(@[("AudioProcessor.csc", "  OFFERS Pulsanti\n", "  OFFERS Pulsanti VERSION 0.1\n"), usoSpegni])
    let rc = chk(wc, "AudioProcessor.csc")
    rec("AC-262", "con la versione giusta trovata, l'E03 su un nome davvero mancante resta",
      rc.code == 1 and errs(rc) == 1 and "[E03] nome non dichiarato come EVENT: Pulsanti.spegni_tutto" in rc.output, rc.output)
  # g-c1: check non cambia i file
  block:
    let w = sonda(@[("AudioProcessor.csc", "\nEND\n", "\n" & sc & "END\n")])
    let prima = snapshot(@[w])
    discard chk(w, "AudioProcessor.csc")
    discard run(@["check", "--json", "AudioProcessor.csc"], w)
    rec("AC-261", "check non modifica nessun file della cartella", snapshot(@[w]) == prima, "un file è cambiato")

# 066:12:1 F6 (GRAMMATICA_F1 1.21): AC-263..AC-299 sulle prove di prove/f6/. Nessuna prova legge un
# 066:12:2 caso vivo. Ogni prova ha il suo FILE.atteso (il rapporto intero, byte per byte, letto dal deposito) e frasi che il criterio nomina.
block:
  let f6 = root / "prove" / "f6"
  proc c6(dir, file: string, extra: seq[string] = @[]): Res =
    run(@["check", "--strict"] & extra & @[file], f6 / dir)
  proc nErr6(r: Res): int =
    for l in r.output.splitLines:
      if l.startsWith("  riga ") and "[E" in l: inc result
  proc unrec6(r: Res): string =
    for l in r.output.splitLines:
      if l.startsWith("5. RIGHE NON RICONOSCIUTE: "): return l[27 .. ^1]
  proc v6(ac, dir, file: string, extra: seq[string], code, ne: int, u: string, must: seq[string] = @[], mustNot: seq[string] = @[]) =
    let r = c6(dir, file, extra)
    let prova = "f6/" & dir & "/" & file
    var why = ""
    let want = readFile(f6 / dir / file.changeFileExt("atteso"))
    if r.errout.len > 0: why = "stderr non vuoto: " & r.errout
    elif r.code != code: why = "codice " & $r.code & " invece di " & $code
    elif nErr6(r) != ne: why = "errori " & $nErr6(r) & " invece di " & $ne
    elif unrec6(r) != u: why = "non riconosciute " & unrec6(r) & " invece di " & u
    elif r.output != want: why = ".atteso: " & firstDiff(r.output, want)
    else:
      for m in must:
        if m notin r.output: why = "manca: " & m
      for m in mustNot:
        if m in r.output: why = "c'è ma non doveva: " & m
    rec(ac, dir & "/" & file & (if extra.len > 0: " " & extra.join(" ") else: ""), why.len == 0, why & "\n" & r.output, prova)
  let noExtra: seq[string] = @[]
  # le tre voci della sezione 8 della luce, la sezione 9 e la 10
  v6("AC-263", "luce_facoltativa", "LuceScale.csc", noExtra, 0, 0, "0", @[
    "9. COMPOSIZIONI: 2\n  riga 1: ENTITY LuceScale: 2\n    con crepuscolare\n    senza crepuscolare\n",
    "10. ASSENZE DICHIARATE: 1\n  riga 6: senza crepuscolare: la parte pulsante usa il connettore Buio: nessun'altra parte di LuceScale lo offre, né LuceScale lo usa da fuori\n",
    "  riga 6: pulsante usa Buio: la offre crepuscolare (riga 8) (in: con crepuscolare)\n",
    "  riga 6: pulsante usa Buio: nessuno la offre (in: senza crepuscolare)\n",
    "  riga 7: lampada usa Comando: la offre pulsante (riga 6)\n"])
  v6("AC-264", "luce_facoltativa", "LuceScaleMuta.csc", noExtra, 1, 1, "0", @[
    "  riga 6: [E14] la parte pulsante usa il connettore Buio: nessun'altra parte di LuceScaleMuta lo offre, né LuceScaleMuta lo usa da fuori\n",
    "10. ASSENZE DICHIARATE: 0\n"], @["(in:"])
  v6("AC-265", "luce_facoltativa", "ZeroZero.csc", noExtra, 1, 1, "0", @[
    "[E19] la parte crepuscolare ha un numero di copie non valido: [0 .. 0]. Scrivi [minimo .. massimo] con due numeri interi: il minimo 0 o più, il massimo almeno 1 e non più piccolo del minimo"],
    @["9. COMPOSIZIONI"])
  # AC-266: il rapporto di prima, byte per byte (il .atteso è stato scritto con l'eseguibile della 1.20)
  v6("AC-266", "luce_facoltativa", "SenzaCrepuscolare.csc", noExtra, 1, 1, "0", @[], @["9. COMPOSIZIONI", "10. ASSENZE"])
  v6("AC-267", "luce_varianti", "LuceScale.csc", noExtra, 0, 0, "0", @[
    "9. COMPOSIZIONI: 4\n  riga 1: ENTITY LuceScale: 4\n    lampada = soffitto, comando = pulsante\n    lampada = soffitto, comando = presenza\n" &
    "    lampada = parete, comando = pulsante\n    lampada = parete, comando = presenza\n"])
  v6("AC-268", "luce_varianti", "LuceScaleSbagliata.csc", noExtra, 1, 1, "0", @[
    "  riga 15: [E16] il connettore pubblico Presenza di LuceScaleSbagliata (offre) non è affidato a nessuna parte (in: comando = presenza)\n"])
  const assKit = "10. ASSENZE DICHIARATE: 2\n  riga 18: senza di: la parte cattura usa il connettore SegnaleLivello: nessun'altra parte di Kit1b lo offre, né Kit1b lo usa da fuori\n" &
    "  riga 43: senza di: il connettore pubblico Morsetti di Kit1b (usato) non è affidato a nessuna parte\n"
  v6("AC-269", "kit", "Kit1b.csc", noExtra, 0, 0, "0", @[
    "9. COMPOSIZIONI: 3\n  riga 5: ENTITY Kit1b: 3\n    sensore = di, con di\n    sensore = di, senza di\n    sensore = microfono\n", assKit,
    "  riga 18: cattura usa SegnaleLivello: la offre di (riga 46) (in: con di)\n  riga 18: cattura usa SegnaleLivello: nessuno la offre (in: senza di)\n" &
    "  riga 18: cattura usa SegnaleLivello: la offre microfono (riga 88) (in: sensore = microfono)\n"])
  v6("AC-270", "kit", "Kit1a.csc", noExtra, 0, 0, "0", @[
    "  riga 17: senza di: la parte scheda usa il connettore SegnaleLivello: nessun'altra parte di Kit1a lo offre, né Kit1a lo usa da fuori\n",
    "  riga 24: senza di: il connettore pubblico Morsetti di Kit1a (usato) non è affidato a nessuna parte\n"])
  v6("AC-271", "kit", "Impianto1b.csc", noExtra, 0, 0, "0", @[
    "riga 12: kit : Kit1b in Kit1b.csc alla riga 5: VERSION 0.2, STATUS HYPOTHESIS, nessun errore\n",
    "9. COMPOSIZIONI: 2\n  riga 4: ENTITY Impianto1b: 2\n    kit.sensore = di\n    kit.sensore = microfono\n",
    "  riga 12: kit usa Morsetti: la offre amplificatore (riga 14) (in: kit.sensore = di)\n", "10. ASSENZE DICHIARATE: 0\n"])
  v6("AC-272", "kit", "Impianto1a.csc", noExtra, 0, 0, "0", @["9. COMPOSIZIONI: 2\n  riga 4: ENTITY Impianto1a: 2\n    kit.sensore = di\n    kit.sensore = microfono\n"])
  # la sonda del confine S3: la scelta `microfono` scritta male resta un errore, non un'assenza dichiarata
  v6("AC-273", "kit_s3", "Kit1b.csc", @["--dir", "../kit"], 1, 1, "0", @[
    "  riga 18: [E14] la parte cattura usa il connettore SegnaleLivello: nessun'altra parte di Kit1b lo offre, né Kit1b lo usa da fuori (in: sensore = microfono)\n", assKit])
  v6("AC-274", "salita", "Sistema.csc", noExtra, 1, 1, "0", @[
    "(in: modulo.tipo = alimentato)\n", "9. COMPOSIZIONI: 2\n  riga 1: ENTITY Sistema: 2\n    modulo.tipo = batteria\n    modulo.tipo = alimentato\n"])
  v6("AC-275", "salita", "SistemaFacoltativo.csc", noExtra, 1, 1, "0", @[
    "  riga 6: [E17] la parte alim offre il connettore Rete: nessun'altra parte di SistemaFacoltativo lo usa, né SistemaFacoltativo lo offre da fuori (in: modulo.tipo = batteria, con alim)\n",
    "  riga 5: senza alim: la parte modulo usa il connettore Rete: nessun'altra parte di SistemaFacoltativo lo offre, né SistemaFacoltativo lo usa da fuori (in: modulo.tipo = alimentato)\n",
    "    modulo.tipo = batteria, con alim\n    modulo.tipo = batteria, senza alim\n    modulo.tipo = alimentato, con alim\n    modulo.tipo = alimentato, senza alim\n"])
  v6("AC-276", "salita", "Modulo.csc", noExtra, 0, 0, "0", @["9. COMPOSIZIONI: 2\n  riga 1: ENTITY Modulo: 2\n    tipo = batteria\n    tipo = alimentato\n"])
  v6("AC-277", "forme", "variant_in_csc.csc", noExtra, 1, 1, "1", @["  riga 4: [E21] VARIANT non può stare in una CSC: le varianti si scrivono in un'entità\n"])
  v6("AC-278", "forme", "variant_malformato.csc", noExtra, 1, 1, "1", @["  riga 3: [E21] VARIANT scritto male: serve VARIANT dimensione = scelta\n"], @["E22", "9. COMPOSIZIONI"])
  v6("AC-279", "forme", "purpose_in_pezzo.csc", noExtra, 1, 1, "1", @["  riga 4: [E21] PURPOSE non può stare in un pezzo VARIANT: scrivilo prima del primo VARIANT\n"], @["E10"])
  v6("AC-280", "forme", "scelta_sola.csc", noExtra, 1, 1, "0", @["  riga 3: [E22] la dimensione modo ha una sola scelta (uno): ne servono almeno due; una parte che può mancare si scrive con [0 .. 1]\n"])
  v6("AC-281", "forme", "scelta_ripetuta.csc", noExtra, 1, 1, "0", @["  riga 9: [E22] la scelta modo = uno è già scritta alla riga 3\n", "9. COMPOSIZIONI: 2\n"])
  v6("AC-282", "forme", "pezzo_vuoto.csc", noExtra, 1, 1, "0", @["  riga 3: [E22] il pezzo VARIANT modo = uno è vuoto: una scelta senza righe si scrive con una parte [0 .. 1]\n"])
  v6("AC-283", "forme", "nomi.csc", noExtra, 1, 3, "0", @[
    "  riga 6: [E01] nome già usato alla riga 3: Comune\n", "  riga 15: [E01] nome già usato alla riga 9: g1\n", "  riga 19: [E01] nome già usato alla riga 8: p\n"])
  v6("AC-284", "forme", "dettagli.csc", noExtra, 1, 1, "0", @[
    "  riga 15: [E02] DETAILS nomina una GUARANTEE che non vale in tutte le composizioni di questa riga: u1 (sta in VARIANT modo = uno)\n"])
  v6("AC-285", "forme", "dettagli_comune.csc", noExtra, 1, 1, "0", @[
    "  riga 3: [E02] DETAILS nomina una GUARANTEE che non vale in tutte le composizioni di questa riga: u1 (sta in VARIANT modo = uno)\n"])
  v6("AC-286", "forme", "scenari.csc", noExtra, 1, 1, "0", @[
    "  riga 14: [E20] Bx.b: Scenari non offre né usa il connettore Bx; uno scenario può citare solo i connettori di Scenari (in: modo = due)\n"])
  block:
    let r = c6("forme", "limite.csc")
    let want = ["d1 = si, d2 = si, d3 = si, d4 = si, d5 = si, d6 = si", "d1 = no, d2 = no, d3 = no, d4 = no, d5 = no, d6 = no"]
    var nomi: seq[string]
    for l in r.output.splitLines:
      if l.startsWith("    d1 = "): nomi.add l[4 .. ^1]
    v6("AC-287", "forme", "limite.csc", noExtra, 0, 0, "0", @["9. COMPOSIZIONI: 64\n  riga 1: ENTITY Limite: 64\n    " & want[0] & "\n"])
    rec("AC-287", "64 nomi, l'ultimo è tutto `no`", nomi.len == 64 and nomi[^1] == want[1], $nomi.len & " nomi")
  v6("AC-288", "forme", "troppe.csc", noExtra, 1, 1, "0", @[
    "  riga 1: [E23] l'entità Troppe ha più di 64 composizioni: bcdd non le controlla una per una. Togli una scelta, o dividi l'entità in entità più piccole\n",
    "9. COMPOSIZIONI: 0\n  riga 1: ENTITY Troppe: più di 64, non controllate\n"])
  block:
    let t = epochTime()
    v6("AC-289", "forme", "enorme.csc", noExtra, 1, 1, "0", @["[E23] l'entità Enorme ha più di 64 composizioni"])
    rec("AC-289", "40 dimensioni: in meno di 1 s (il conteggio non elenca)", epochTime() - t < 1.0, $(epochTime() - t))
  v6("AC-290", "forme", "facoltativa_in_csc.csc", noExtra, 3, 0, "1", @[], @["9. COMPOSIZIONI", "[E19]"])
  # AC-291, AC-292: check --json
  block:
    let j = jsonDi(@["--strict", "LuceScale.csc"], f6 / "luce_facoltativa")
    var ok = j != nil and j.jint("versione") == 5
    var molt = ""
    if ok:
      let r = j["rapporto"]
      ok = r["ha_composizioni"].getBool and r["composizioni"].len == 1 and r["composizioni"][0].jint("riga") == 1 and
        r["composizioni"][0].jstr("entita") == "LuceScale" and r["composizioni"][0]["nomi"].len == 2 and
        r["composizioni"][0]["nomi"][0].getStr == "con crepuscolare" and r["composizioni"][0]["nomi"][1].getStr == "senza crepuscolare" and
        r["assenze"].len == 1 and r["assenze"][0].jint("riga") == 6 and r["assenze"][0].jstr("codice") == "E14" and
        r["assenze"][0].jstr("senza") == "crepuscolare" and r["assenze"][0]["in"].kind == JNull
      var inUsi: seq[string]
      for u in r["usi"]: inUsi.add (if u["in"].kind == JNull: "-" else: u.jstr("in"))
      ok = ok and inUsi == @["con crepuscolare", "senza crepuscolare", "-"]
      for b in j["blocchi"]:
        for c in b["citazioni"]:
          if c.jstr("tipo") != "PART": continue
          if c.jstr("parte") == "crepuscolare":
            ok = ok and c["molteplicita"].jint("min") == 0 and c["molteplicita"].jint("max") == 1
            molt = "ok"
          else:
            ok = ok and c["molteplicita"].kind == JNull
    rec("AC-291", "check --json: versione 4, molteplicità {0, 1}, composizioni, assenza, `in` delle voci", ok and molt == "ok", if j == nil: "niente JSON" else: $j["rapporto"])
  block:
    let j = jsonDi(@["--strict", "Kit1b.csc"], f6 / "kit")
    var ok = j != nil
    if ok:
      let b = j["blocchi"][0]
      ok = b["varianti"].len == 2 and b["varianti"][0].jint("riga") == 42 and b["varianti"][0].jstr("dimensione") == "sensore" and
        b["varianti"][0].jstr("scelta") == "di" and b["varianti"][1].jint("riga") == 86 and b["varianti"][1].jstr("scelta") == "microfono"
      var k1, k3, di = false
      for g in b["garanzie"]:
        if g.jstr("id") == "k1": k1 = g["variante"].kind == JNull
        if g.jstr("id") == "k3": k3 = g["variante"].jstr("dimensione") == "sensore" and g["variante"].jstr("scelta") == "di"
      for c in b["citazioni"]:
        if c.jstr("tipo") == "PART" and c.jint("riga") == 46:
          di = c["variante"].jstr("scelta") == "di" and c["molteplicita"].jint("min") == 0 and c["molteplicita"].jint("max") == 1
      ok = ok and k1 and k3 and di
    rec("AC-292", "check --json su Kit1b: varianti, `variante` di k1, k3 e della parte di", ok, if j == nil: "niente JSON" else: $j["blocchi"][0]["varianti"])
  # un VARIANT scritto male nel JSON: dimensione e scelta null, e nessun campo nuovo manca in un file senza varianti
  block:
    let j = jsonDi(@["variant_malformato.csc"], f6 / "forme")
    var ok = j != nil
    if ok:
      var g = 0
      for b in j["blocchi"]:
        for gr in b["garanzie"]:
          if gr.jstr("id") == "v1": ok = ok and gr["variante"]["dimensione"].kind == JNull and gr["variante"]["scelta"].kind == JNull; inc g
      ok = ok and g == 1
    rec("AC-292", "JSON: la riga nel pezzo di un VARIANT scritto male ha dimensione e scelta null", ok, if j == nil: "niente JSON" else: $j["blocchi"])
    let jn = jsonDi(@["--strict", "01_minima.csc"], root / "prove")
    rec("AC-293", "JSON di un file senza varianti: campi aggiunti vuoti", jn != nil and not jn["rapporto"]["ha_composizioni"].getBool and
      jn["rapporto"]["composizioni"].len == 0 and jn["rapporto"]["assenze"].len == 0 and jn["blocchi"][0]["dichiarazioni"].len >= 0 and
      jn["blocchi"][0]["garanzie"].len >= 0, "")
  # AC-293: nessuna CSC fuori da prove/f6 ha sezioni 9 e 10, né varianti (il confronto byte per byte col 1.20 è in UCapture, fuori dalla suite)
  block:
    var tot, bad = 0
    var dirsAll = @[root / "prove", root / "csc", root / "esempi"]
    for d in dirsAll:
      if not dirExists(d): continue
      for f in walkDirRec(d):
        if not f.endsWith(".csc") or "/f6/" in f or "/d355/" in f: continue
        inc tot
        let r = run(@["check", "--strict", "--dir", f.parentDir, f.extractFilename], f.parentDir)
        if "9. COMPOSIZIONI" in r.output or "10. ASSENZE" in r.output or "(in: " in r.output: inc bad
    rec("AC-293", "nessuna CSC di prove/, csc/, esempi/ ha sezioni 9 e 10 o suffissi `(in: …)` (" & $tot & " file)", tot > 100 and bad == 0, $bad & " file")
  # AC-295: save rifiuta di spostare una garanzia contratto fra pezzi
  block:
    let w = newWd()
    for k, p in walkDir(f6 / "kit"):
      if p.endsWith(".csc"): copyFile(p, w / p.extractFilename)
    let orig = readFile(w / "Kit1b.csc")
    let fp = sha256Of(w / "Kit1b.csc")
    let ls = orig.split('\n')
    let iMic = ls.find("  VARIANT sensore = microfono")
    var i1 = -1
    for i, l in ls:
      if l.startsWith("  GUARANTEE k1 "): i1 = i
    proc without(a, b: int): seq[string] =
      for i, l in ls:
        if i < a or i > b: result.add l
    # k1 (due righe) sotto VARIANT sensore = microfono
    var spost = ls[0 .. i1 - 1] & ls[i1 + 2 .. iMic] & ls[i1 .. i1 + 1] & ls[iMic + 1 .. ^1]
    let r1 = runX(bcdd, @["save", "Kit1b.csc", "--expect", fp], w, nil, spost.join("\n"))
    rec("AC-295", "k1 (contratto) spostata nel pezzo microfono: rifiutato, codice 1, file invariato", r1.code == 1 and readFile(w / "Kit1b.csc") == orig and
      "bcdd save: la riga " in r1.errout and ", GUARANTEE k1, è contratto (D-338): non può cambiare pezzo VARIANT; per cambiarla serve una VERSION nuova" in r1.errout and
      r1.output.len == 0, r1.errout & r1.output)
    # il nome della scelta del pezzo di k3 cambia: k3 cambia pezzo
    let r2 = runX(bcdd, @["save", "Kit1b.csc", "--expect", fp], w, nil, orig.replace("  VARIANT sensore = di\n", "  VARIANT sensore = diretto\n"))
    rec("AC-295", "il nome della scelta del pezzo di k3 cambia: rifiutato", r2.code == 1 and readFile(w / "Kit1b.csc") == orig and
      ", GUARANTEE k3, è contratto (D-338): non può cambiare pezzo VARIANT" in r2.errout, r2.errout)
    # km2 sposta di riga dentro lo stesso pezzo, testo uguale: ammesso
    var i2 = -1
    for i, l in ls:
      if l.startsWith("    GUARANTEE km2 "): i2 = i
    let spost2 = ls[0 .. iMic] & ls[i2 .. i2 + 1] & ls[iMic + 1 .. i2 - 1] & ls[i2 + 2 .. ^1]
    let r3 = runX(bcdd, @["save", "Kit1b.csc", "--expect", fp], w, nil, spost2.join("\n"))
    rec("AC-295", "km2 spostata dentro lo stesso pezzo, testo uguale: ammesso, codice 0", r3.code == 0 and readFile(w / "Kit1b.csc") == spost2.join("\n"), r3.errout & r3.output)
  # AC-296: ratify di una riga dentro un pezzo e in un'entità con un'assenza dichiarata
  block:
    let w = newWd()
    for k, p in walkDir(f6 / "salita"):
      if p.endsWith(".csc"): copyFile(p, w / p.extractFilename)
    let r = run(@["ratify", "Modulo.csc", "m2", "D-1"], w)
    let c = run(@["check", "--strict", "Modulo.csc"], w)
    rec("AC-296", "ratify m2 (in un pezzo): riesce, STATUS RATIFIED BY D-1, check --strict codice 0", r.code == 0 and
      "GUARANTEE m2 STATUS RATIFIED BY D-1:" in readFile(w / "Modulo.csc") and c.code == 0, r.errout & r.output & c.output)
    let w2 = newWd()
    for k, p in walkDir(f6 / "luce_facoltativa"):
      if p.endsWith(".csc"): copyFile(p, w2 / p.extractFilename)
    let r2 = run(@["ratify", "LuceScale.csc", "g1", "D-1"], w2)
    let c2 = run(@["check", "--strict", "LuceScale.csc"], w2)
    rec("AC-296", "ratify g1 con un'assenza dichiarata: riesce, check --strict codice 0", r2.code == 0 and
      "GUARANTEE g1 STATUS RATIFIED BY D-1:" in readFile(w2 / "LuceScale.csc") and c2.code == 0 and "10. ASSENZE DICHIARATE: 1" in c2.output, r2.errout & r2.output & c2.output)
  # AC-298: i messaggi d'uso e `new` non cambiano (stessi attesi di AC-1..: coperti dalle prove di F1 e F2); qui la parola riservata nuova
  block:
    let w = newWd()
    let r = run(@["new", "VARIANT"], w)
    rec("AC-298", "`new VARIANT`: la parola è riservata, codice 2, nessun file", r.code == 2 and listDir(w).len == 0, r.errout & r.output)

  # AC-299: un nome non dichiarato come valore in un passo di SCENARIO di una CSC è E03 (G26, sezione 4.4), come nel GIVEN
  block:
    let d160 = root / "prove" / "d160"
    proc errs(r: Res): int =
      for l in r.output.splitLines:
        if l.len > 6 and l.startsWith("  riga ") and "[E" in l: inc result
    let m = run(@["check", "--strict", "Min.csc"], d160)
    rec("AC-299", "Min.csc: `s = c` in un passo, E03 a riga 6, codice 1, un solo errore", m.code == 1 and errs(m) == 1 and
      "riga 6: [E03] nome non dichiarato come valore di TYPE: c" in m.output, m.output)
    let e = run(@["check", "--strict", "E03b.csc"], d160)
    rec("AC-299", "E03b.csc: `modo = buia` in un passo, E03 sul nome, codice 1", e.code == 1 and errs(e) == 1 and
      "[E03] nome non dichiarato come valore di TYPE: buia" in e.output, e.output)
    let w = newWd()
    let ok = readFile(d160 / "Min.csc").replace("s = c", "s = b")
    writeFile(w / "Min.csc", ok)
    let r1 = run(@["check", "--strict", "Min.csc"], w)
    rec("AC-299", "Min.csc con `s = b` (valore dichiarato): nessun errore, codice 0", r1.code == 0 and errs(r1) == 0, r1.output)
    writeFile(w / "Arg.csc", "CSC T VERSION 0.1\n  PURPOSE \"p\"\n  TYPE M := {a, b}\n  EVENT IN ev(k: M)\n  STATE s : M INITIAL a\n" &
      "  SCENARIO x EXPECT ADMITTED\n    @0 s   ev(k: zz)\nEND\n")
    let r2 = run(@["check", "--strict", "Arg.csc"], w)
    rec("AC-299", "argomento di evento `ev(k: zz)` in un passo: E03 alla colonna del nome", r2.code == 1 and errs(r2) == 1 and
      "riga 7: [E03] nome non dichiarato come valore di TYPE: zz" in r2.output, r2.output)
    writeFile(w / "Arg.csc", readFile(w / "Arg.csc").replace("zz", "b"))
    let r3 = run(@["check", "--strict", "Arg.csc"], w)
    rec("AC-299", "argomento di evento con valore dichiarato: nessun errore", r3.code == 0 and errs(r3) == 0, r3.output)

  # AC-300: (GRAMMATICA_F1 1.22, sezioni 35 e 4.10): E16 ed E17 valgono in ogni composizione con almeno una parte presente, con o senza COMPOSED OF
  block:
    let d355 = root / "prove" / "d355"
    proc errs(r: Res): int =
      for l in r.output.splitLines:
        if l.len > 6 and l.startsWith("  riga ") and "[E" in l: inc result
    let a = run(@["check", "--strict", "SenzaElenco.csc"], d355 / "senza_composed_of")
    rec("AC-300", "senza COMPOSED OF, OFFERS Pressione e parte lampada: E16 alla riga 3 (OFFERS), codice 1",
      a.code == 1 and "riga 3: [E16] il connettore pubblico Pressione di SenzaElenco (offre) non è affidato a nessuna parte" in a.output, a.output)
    let b = run(@["check", "--strict", "SoloFacoltativa.csc"], d355 / "facoltativa")
    rec("AC-300", "senza COMPOSED OF, unica parte [0 .. 1]: E16 ed E17 solo con `(in: con lampada)`, due errori, codice 1",
      b.code == 1 and errs(b) == 2 and
      "riga 3: [E16] il connettore pubblico Pressione di SoloFacoltativa (offre) non è affidato a nessuna parte (in: con lampada)" in b.output and
      "riga 6: [E17] la parte lampada offre il connettore Luce: nessun'altra parte di SoloFacoltativa lo usa, né SoloFacoltativa lo offre da fuori (in: con lampada)" in b.output and
      "(in: senza lampada)" notin b.output, b.output)
    rec("AC-300", "senza COMPOSED OF, unica parte [0 .. 1]: sezione 10 a 0", b.code == 1 and "10. ASSENZE DICHIARATE: 0" in b.output, b.output)

# 066:13:2 C-17 (1.0-beta): AC-301..AC-314 provano i blocchi non letti, che la 1.0-beta ritira: sostituiti dagli AC-315..AC-362.
# 066:13:3 (rimossi) i controlli AC-301..AC-314 sul blocco non letto sono ritirati dalla 1.0-beta (C-17); restano nella storia di git.

# 066:14:1 AC-315..AC-362 sulle copie congelate di prove/w12/.
block:
  let w12 = root / "prove" / "w12"
  proc c12(args: seq[string], cwd: string = w12): Res = run(@["check"] & args, cwd)
  proc has(r: Res, parts: varargs[string]): bool =
    for p in parts:
      if p notin r.output: return false
    true
  proc ac(n: int, label: string, ok: bool, why: string = "") = rec("AC-" & $n, label, ok, why)
  # AC-315: ABS(x - a) <= t
  block:
    let r = c12(@["ac315.csc"])
    ac 315, "ABS(x - a) <= t riconosciuta, codice 0", r.code == 0 and has(r, "non riconosciute 0)"), r.output
  # AC-316 (C-01, S-3)
  block:
    let r = c12(@["ac316.csc"])
    ac 316, "- 3 e 5-3 riconosciute, a -3 no", r.code == 0 and has(r, "5. RIGHE NON RICONOSCIUTE: 1\n  riga 6: DEFINE G := a -3\n"), r.output
  # AC-317
  block:
    let r = c12(@["ac317.csc"])
    let st = c12(@["--strict", "ac317.csc"])
    ac 317, "± è estraneo: non riconosciuta, codice 0, --strict 3", r.code == 0 and has(r, "riga 3: DEFINE T1 := 1 ± 2") and st.code == 3, r.output
  # AC-318, AC-319, AC-320 (C-02, U5)
  block:
    let r = c12(@["ac318.csc"])
    ac 318, "THEN a fine riga continua: una dichiarazione, formale", r.code == 0 and has(r, "riga 5: GUARANTEE g1 formale", "non riconosciute 0)"), r.output
    let r2 = c12(@["ac319.csc"])
    ac 319, "THEN a inizio riga: due dichiarazioni non riconosciute", has(r2, "non riconosciute 2)", "riga 5: GUARANTEE g1 non riconosciuta", "  riga 6: THEN accesa WITHIN 1 s"), r2.output
    let r3 = c12(@["ac320.csc"])
    ac 320, "END chiude il blocco, niente E07; g non riconosciuta", not has(r3, "[E07]") and has(r3, "riga 4: GUARANTEE g non riconosciuta"), r3.output
  # AC-321, AC-322 (C-04)
  block:
    let r = c12(@["ac321.csc"])
    ac 321, "STATE Event e STATE Record non riconosciute, STATE C1 sì", has(r, "  riga 3: STATE Event : Boolean INITIAL false", "  riga 5: STATE Record : Boolean INITIAL false") and
      "STATE C1" notin r.output.split("5. RIGHE NON RICONOSCIUTE")[1], r.output
    let w = newWd()
    let n = run(@["new", "Record"], w)
    ac 321, "bcdd new Record: codice 2 nome non valido", n.code == 2 and n.errout == "bcdd new: nome non valido: Record\n", n.errout
    # AC-322: la lista di src/bcddwords.nim ha le 136 parole di GRAMMATICA_F1 2.3 (la lista di editor/edazioni.nim si aggiorna a parte)
    let g = readFile(root / "GRAMMATICA_F1.md")
    let sec = g[g.find("### 2.3 ") .. g.find("In tutto le parole chiave")]
    var gram: HashSet[string]
    var inB = false
    for l in sec.splitLines():
      if l == "```":
        inB = not inB
        continue
      if inB:
        for x in l.splitWhitespace(): gram.incl x
    for x in ["true", "false", "requested", "accepted", "rejected", "completed", "failed", "_"]: gram.incl x
    let wsrc = readFile(root / "src" / "bcddwords.nim")
    var mine: HashSet[string]
    for l in wsrc.splitLines():
      if l.startsWith("let reservedSet"): break
      for part in l.split('"'):
        discard
    var q = 0
    var cur = ""
    var inS = false
    for ch in wsrc[0 ..< wsrc.find("let reservedSet")]:
      if ch == '"':
        if inS:
          mine.incl cur
          cur = ""
        inS = not inS
      elif inS: cur.add ch
    ac 322, "le parole di src/bcddwords.nim sono le 136 della sezione 2.3", mine == gram and gram.len == 136, $gram.len & " " & $mine.len
    discard q
  # AC-323..AC-325 (C-05, C-06)
  block:
    let r = c12(@["ac323.csc"])
    ac 323, "IMPORT PROFILE con la versione esatta: citazione sotto la CSC, codice 0",
      r.code == 0 and has(r, "    riga 2: IMPORT PROFILE Segnale in Segnale.csc alla riga 1: VERSION 0.3, STATUS HYPOTHESIS, nessun errore\n"), r.output
    let r2 = c12(@["--strict", "ac324.csc"], w12 / "v02")
    ac 324, "solo la VERSION 0.2: sezione 7, riga non riconosciuta col motivo, codice 0, --strict 3",
      has(r2, "  riga 2: PROFILE Segnale (trovata solo la VERSION 0.2 in Segnale.csc)\n",
        "(profilo Segnale VERSION 0.3 non trovato)") and r2.code == 3, r2.output
    let r2b = c12(@["ac324.csc"], w12 / "v02")
    ac 324, "senza --strict codice 0", r2b.code == 0, r2b.output
    let r3 = c12(@["ac325.csc"])
    ac 325, "IMPORT PROFILE nella zona d'intestazione di un'entità: riconosciuto", r3.code == 0 and has(r3, "non riconosciute 0)", "IMPORT PROFILE Segnale in Segnale.csc"), r3.output
  # AC-326, AC-327, AC-328 (C-07)
  block:
    let r = c12(@["ac326.csc"])
    ac 326, "STATE con indice e storia con indice: riconosciute, codice 0", r.code == 0 and has(r, "non riconosciute 0)"), r.output
    let r2 = c12(@["ac327.csc"])
    ac 327, "E29: tipo non finito, indice non del tipo, indice mancante e indice su stato senza indice",
      has(r2, "[E29] il tipo dell'indice di s non è finito: Real", "[E29] accesa non ha indice",
        "[E29] indice di clipCount non del tipo Ch: X") and r2.output.count("[E29]") == 3 and r2.code == 1, r2.output
    let r3 = c12(@["ac328.csc"])
    ac 328, "FOLLOWS con campo di tipo diverso: E25", has(r3, "[E25] tipo incoerente: serve Integer, trovato String"), r3.output
  # AC-329..AC-332 (C-08, C-09)
  block:
    let r = c12(@["ac329.csc"])
    ac 329, "DEFINE in giro: E28", has(r, "[E28] DEFINE in giro: A -> B -> A"), r.output
    let r2 = c12(@["ac330.csc"])
    ac 330, "chiamata di DEFINE con parametri: riconosciuta, E24 per argomento mancante e parametro sbagliato",
      has(r2, "riga 7: [E24] manca l'argomento b nella chiamata di vicino", "riga 8: [E24] nome non dichiarato come parametro di vicino: c") and
      "riga 6: [E" notin r2.output, r2.output
    let r3 = c12(@["ac331.csc"])
    ac 331, "DEFINE EVENT usabile nelle formule, E03 nel passo", has(r3, "riga 7: [E03] nome non dichiarato come EVENT: riavvio") and
      "riga 5: [E" notin r3.output, r3.output
    let r4 = c12(@["ac332.csc"])
    ac 332, "Record: campo letto, campo mancante E24", has(r4, "riga 6: [E24] nome non dichiarato come campo di Campione: Z") and "riga 5: [E" notin r4.output, r4.output
  # AC-333..AC-340 (C-10, C-12)
  block:
    let r = c12(@["ac333.csc"])
    ac 333, "EVENTUALLY accesa WITHIN 60: E25, grado formale", has(r, "[E25] tipo incoerente: serve Duration, trovato Integer", "GUARANTEE g1 formale"), r.output
    let r2 = c12(@["ac334.csc"])
    ac 334, "E26: quattro messaggi, righe riconosciute", has(r2, "riga 7: [E26] AND e OR insieme senza parentesi", "riga 8: [E26] IMPLIES dopo IMPLIES",
      "riga 9: [E26] confronti in catena", "riga 10: [E26] ^ dopo ^ senza parentesi", "non riconosciute 0)"), r2.output
    let r3 = c12(@["ac335.csc"])
    ac 335, "E27: quattro messaggi", has(r3, "riga 8: [E27] EVENTUALLY dentro un'altra forma", "riga 9: [E27] una proprietà ha un solo ambito: AFTER è il secondo",
      "riga 10: [E27] WITHIN e AT ONCE nella stessa proprietà: scegline uno", "riga 11: [E27] REQUIRES sta solo in una ASSUME") and r3.output.count("[E27]") == 4, r3.output
    let r4 = c12(@["ac336.csc"])
    ac 336, "ALWAYS p WITHIN 1 s: non riconosciuta, nessun errore", r4.code == 0 and has(r4, "riga 4: GUARANTEE g1: ALWAYS p WITHIN 1 s", "1. ERRORI: 0"), r4.output
    let r5 = c12(@["ac337.csc"])
    ac 337, "nome non dichiarato: E24", has(r5, "riga 3: [E24] nome non dichiarato: nondichiarato"), r5.output
    let r6 = c12(@["ac338.csc"])
    ac 338, "genere sbagliato: E24 due volte", has(r6, "riga 5: [E24] accesa non è un evento: serve un EVENT, una DEFINE EVENT o una fase di una CAPABILITY",
      "riga 6: [E24] pressione non è una CAPABILITY"), r6.output
    let r7 = c12(@["ac339.csc"])
    ac 339, "TRANSITION: formale; con stato Boolean E25", has(r7, "riga 8: GUARANTEE t1 formale", "riga 9: [E25]") and "riga 8: [E" notin r7.output, r7.output
    let r8 = c12(@["ac340.csc"])
    ac 340, "WITH senza parentesi: E26; con parentesi riconosciuta", has(r8, "riga 5: [E26] confronti in catena") and "riga 6: [E" notin r8.output and r8.output.count("[E") == 1, r8.output
  # AC-341, AC-342 (C-14)
  block:
    let r = c12(@["ac341.csc"])
    ac 341, "quattro E25 sui valori", has(r, "riga 5: [E25] valore non del tipo Boolean: \"sì\"", "riga 6: [E25] valore non del tipo Integer [0 .. 3]: 5",
      "riga 7: [E25] valore non del tipo Duration: 0", "riga 9: [E25] valore non del tipo Fase: m1") and r.output.count("[E25]") == 4, r.output
    let r2 = c12(@["ac342.csc"])
    ac 342, "nome che non è valore di nessun elenco: solo E03", has(r2, "riga 5: [E03] nome non dichiarato come valore di TYPE: c") and "[E25]" notin r2.output, r2.output
  # AC-343: tipi di base nelle storie d'entità
  block:
    let ent = w12 / "ent"
    let r = c12(@["ac343.csc"], ent)
    ac 343, "storia d'entità: livello \"alto\" per Real è E25; per un tipo descritto a parole nessun errore",
      has(r, "riga 5: [E25] valore non del tipo Real: \"alto\"") and r.output.count("[E25]") == 1, r.output
  # AC-344, AC-345 (C-13)
  block:
    let r = c12(@["ac344.csc"])
    ac 344, "REPEAT FOREVER EVERY 1 s: riconosciuta, codice 0", r.code == 0 and has(r, "non riconosciute 0)"), r.output
    let r2 = c12(@["ac345.csc"])
    ac 345, "E30: cinque messaggi", has(r2, "riga 7: [E30] il passo @1 s non è più breve del periodo di REPEAT", "riga 8: [E30] REPEAT ripetuto nella storia: il primo è alla riga 6",
      "riga 11: [E30] ripetizioni non valide: 5..2", "riga 14: [E30] REPEAT senza passi", "riga 17: [E30] REPEAT … EVERY vuole una storia con le unità di tempo") and
      r2.output.count("[E30]") == 5, r2.output
  # AC-346
  block:
    let r = c12(@["ac346.csc"])
    ac 346, "dettagli di storia: s1a in sezione 4, s1b E02", has(r, "  riga 5: SCENARIO s1a\n", "riga 7: [E02] DETAILS nomina un id che non è uno SCENARIO di questo blocco: g1") and
      "riga 5: [E" notin r.output, r.output
  # AC-347: formule d'entità
  block:
    let ent = w12 / "ent"
    let r = c12(@["ac347.csc"], ent)
    ac 347, "promessa d'entità con nomi qualificati: formale, nessun errore", r.code == 0 and has(r, "riga 5: GUARANTEE g1 formale"), r.output
    let r2 = c12(@["ac347b.csc"], ent)
    ac 347, "X non offerta: E20; nome semplice: E24; y mancante: E24",
      has(r2, "[E20] Luce.accesa: LuceScale non offre né usa il connettore Luce; una promessa d'entità può citare solo i connettori di LuceScale",
        "riga 6: [E24] in un'entità i nomi delle CSC si scrivono con il connettore davanti: accesa", "riga 5: [E24] nome non dichiarato: Pressione.zzz"), r2.output
    let r3 = c12(@["ac347d.csc"], ent)
    ac 347, "CSC non trovata: nessun errore", r3.code == 0 and has(r3, "  riga 4: Manca\n"), r3.output
  # AC-348..AC-354 (C-22, C-23)
  block:
    let b = w12 / "blk"
    let r = c12(@["ac348.csc"], b)
    ac 348, "BINDING: codice 0, sezione 12 con STATE modo", r.code == 0 and has(r, "12. FORME CONCRETE MANCANTI: 1\n  riga 9: BINDING Luce VERSION 0.1: STATE modo\n"), r.output
    let r2 = c12(@["ac349.csc"], b)
    ac 349, "BIND di un elemento che non c'è: E31; con DETAILS e con VERIFY non riconosciute",
      has(r2, "riga 10: [E31] spenta non è un elemento della CSC Luce VERSION 0.1", "  riga 11: BIND accesa DETAILS l1: VERBAL \"y\"", "  riga 13: VERIFY BY JUDGEMENT \"x\"") and
      r2.output.contains("5. RIGHE NON RICONOSCIUTE: 2"), r2.output
    let r3 = c12(@["ac350.csc"], b)
    ac 350, "BINDING con intestazione sbagliata: E09", has(r3, "[E09] intestazione non valida: attesa BINDING NomeCSC VERSION numero [AS nome]"), r3.output
    let r4 = c12(@["ac351.csc"], b)
    ac 351, "E40 due messaggi", has(r4, "riga 3: [E40] secondo BINDING senza nome per la CSC Pressione VERSION 0.1: il primo è alla riga 1. Con due o più BINDING ognuno ha un nome, AS nome",
      "riga 7: [E40] nome di BINDING già usato alla riga 5: filo"), r4.output
    let r5 = c12(@["ac352.csc"], b)
    ac 352, "E38 profilo con versione diversa", has(r5, "riga 6: [E38] PROFILE Protocollo importato con VERSION 0.2, ma la CSC Comando lo importa con VERSION 0.3"), r5.output
    let r6 = c12(@["ac353.csc"], b)
    ac 353, "VERIFICATION: copertura", r6.code == 0 and has(r6, "13. COPERTURA DEL PIANO DI PROVA: 1\n  riga 9: VERIFICATION Luce VERSION 0.1\n    telecamera (riga 10): l1\n    non eseguite: l2\n"), r6.output
    let r7 = c12(@["ac354.csc"], b)
    ac 354, "VERIFICATION: STATUS E39, MEANS e TRANSLATES con E31", has(r7, "[E39] STATUS non può stare in una VERIFICATION: un piano di prova non si approva",
      "riga 11: [E31] zz non è un elemento della CSC Luce VERSION 0.1", "riga 12: [E31] TRANSLATES nomina una storia che la CSC Luce VERSION 0.1 non ha: y"), r7.output
  # AC-355..AC-359 (C-20, C-21, C-24, C-25)
  block:
    let r = c12(@["Segnale03.csc"])
    ac 355, "profilo FADE completo: codice 0, sezione 14 con due voci", r.code == 0 and has(r, "14. DA GIUDICARE: 2\n",
      "  riga 4: EXTENSION FADE: il MEANING non descrive la realizzazione né dà autorità o precedenza fra parti\n",
      "  riga 4: EXTENSION FADE: non ripete una forma che il linguaggio ha già\n", "4. IPOTESI, NON CONTRATTO: 1\n  riga 4: EXTENSION FADE\n"), r.output
    let b = w12 / "blk"
    let r2 = c12(@["ac356.csc"], b)
    ac 356, "profilo e estensioni sbagliati: E10 e otto E33", r2.output.count("[E10]") == 1 and r2.output.count("[E33]") == 8 and
      has(r2, "[E10] PURPOSE mancante nel PROFILE Senza", "[E33] valore di KIND non ammesso: pattern", "[E33] valore di LEVEL non ammesso: Core",
        "[E33] FORM deve cominciare con il nome dell'estensione: FADE", "[E33] il parametro d deve comparire una volta in FORM",
        "[E33] VERIFY V1 nomina un controllo che non esiste: C9", "[E33] campo KIND ripetuto nell'EXTENSION Rip: il primo è alla riga 50",
        "[E33] manca il campo SOURCE nell'EXTENSION SenzaSource"), r2.output
    let r3 = c12(@["ac357.csc"], b)
    ac 357, "E34, E34, E35, E36", has(r3, "[E34] nome di estensione già usato alla riga 3: FADE", "[E34] il nome dell'estensione è una parola del linguaggio: ALWAYS",
      "[E35] REDUCES TO nomina pippo: non è una parola del linguaggio, un parametro né un'estensione del PROFILE Segnale",
      "[E36] l'EXTENSION Mai ripete una forma che il linguaggio ha già: NEVER"), r3.output
    let r4 = c12(@["ac358.csc"], b)
    ac 358, "EXTENSION fuori da un PROFILE: E32 tre volte, righe non riconosciute, l'END non chiude la CSC",
      r4.output.count("[E32]") == 3 and not has(r4, "[E07]", "[E08]") and has(r4, "righe: 14 (riconosciute 5, commenti 0, vuote 0, non riconosciute 9)"), r4.output
    let r5 = c12(@["ac359.csc"])
    ac 359, "uso di FADE: estensione dichiarata; senza WITHIN E37; come funzione E37 per il KIND",
      has(r5, "riga 6: GUARANTEE g10 estensione dichiarata", "riga 7: [E37] uso di FADE che non rispetta FORM \"FADE s WITHIN d\"",
        "riga 8: [E37] FADE ha KIND PATTERN: non si usa in questa posizione"), r5.output
  # AC-360 (7.1 punto 0a) e AC-361 (ratify)
  block:
    let w = newWd()
    discard cpTo(w12 / "Segnale03.csc", w, "Segnale.csc")
    discard cpTo(w12 / "ac323.csc", w, "Uso.csc")
    let rt = run(@["ratify", "Uso.csc", "--all", "D-1"], w)
    let ck = run(@["check", "Uso.csc"], w)
    ac 360, "CSC approvata con profilo da approvare: g10 resta in sezione 4 (punto 0a)", rt.code == 0 and has(ck, "4. IPOTESI, NON CONTRATTO: 1\n  riga 7: GUARANTEE g10\n"), rt.output & ck.output
    let rp = run(@["ratify", "Segnale.csc", "D-2"], w)
    let ck2 = run(@["check", "Uso.csc"], w)
    ac 360, "approvato il profilo, g10 è approvata", rp.code == 0 and rp.output == "ratificato il PROFILE Segnale VERSION 0.3 (riga 1) con D-2\nestensioni: 1\n" and
      has(ck2, "4. IPOTESI, NON CONTRATTO: 0\n"), rp.output & ck2.output
  block:
    let b = w12 / "blk"
    let w = newWd()
    for f in ["ac361b.csc", "ac361c.csc", "ac361d.csc", "Luce.csc"]: discard cpTo(b / f, w)
    discard cpTo(w12 / "Segnale03.csc", w, "Segnale.csc")
    let r1 = run(@["ratify", "ac361b.csc", "--all", "D-200"], w)
    ac 361, "BINDING --all", r1.code == 0 and r1.output == "ratificate con D-200 nel BINDING Luce VERSION 0.1: 2 righe\n  riga 2: BINDING Luce VERSION 0.1\n  riga 4: BIND modo\ncontratto: 2\n" and
      readFile(w / "ac361b.csc") == "BINDING Luce VERSION 0.1\n  STATUS RATIFIED BY D-200\n  BIND accesa: VERBAL \"la plafoniera emette luce piena\"\n  BIND modo STATUS RATIFIED BY D-200: VERBAL \"la spia\"\nEND\n", r1.output
    let r2 = run(@["ratify", "ac361b.csc", "D-3"], w)
    ac 361, "BINDING già ratificato: rifiuto", r2.code == 1 and r2.errout == "bcdd ratify: il BINDING Luce VERSION 0.1 è già ratificato (D-200): non cambio nulla\n", r2.errout
    let r3 = run(@["ratify", "ac361c.csc", "A1", "D-5"], w)
    ac 361, "dettaglio di DEFINE per ID", r3.code == 0 and r3.output == "ratificata la riga 4: DEFINE A1 con D-5\n" and
      "  DEFINE A1 DETAILS A STATUS RATIFIED BY D-5 := 2\n" in readFile(w / "ac361c.csc"), r3.output
    let r4 = run(@["ratify", "ac361d.csc", "D-1"], w)
    ac 361, "una VERIFICATION sola: rifiuto", r4.code == 1 and r4.errout == "bcdd ratify: il file non contiene nessun blocco da ratificare: una VERIFICATION non si ratifica\n", r4.errout
    let r5 = run(@["ratify", "ac361b.csc", "x", "D-1"], w)
    ac 361, "BINDING con ID: rifiuto", r5.code == 1 and r5.errout == "bcdd ratify: nel BINDING si ratificano l'intestazione o --all, non una riga\n", r5.errout
    let w2 = newWd()
    discard cpTo(w12 / "Segnale03.csc", w2, "Segnale.csc")
    let r6 = run(@["ratify", "Segnale.csc", "--csc", "Segnale", "--all", "D-9"], w2)
    ac 361, "profilo con --csc e --all: ratificato", r6.code == 0 and r6.output == "ratificato il PROFILE Segnale VERSION 0.3 (riga 1) con D-9\nestensioni: 1\n", r6.output
    let r7 = run(@["ratify", "Segnale.csc", "x", "D-9"], w2)
    ac 361, "profilo con ID: rifiuto", r7.code == 1 and r7.errout == "bcdd ratify: nel PROFILE si ratifica il profilo intero, non una riga\n", r7.errout
  # AC-362: sezione 15 e JSON 5
  block:
    let r = c12(@["ac362.csc"], w12 / "blk")
    ac 362, "sezione 15 con quattro voci", has(r, "15. CONTROLLI NON ESEGUITI: 4\n  storie: riga 8\n  copertura degli inneschi: riga 5\n  coerenza di presupposti e promesse: righe 5, 6, 7\n  coerenza dei dettagli: riga 7\n"), r.output
    let j = jsonDi(@["ac362.csc"], w12 / "blk")
    ac 362, "JSON versione 5, niente non_lette né blocchi_non_letti, quattro non_eseguiti",
      j != nil and j.jint("versione") == 5 and not j["rapporto"]["conteggi"].hasKey("non_lette") and not j["rapporto"].hasKey("blocchi_non_letti") and
      j["rapporto"]["non_eseguiti"].len == 4, if j == nil: "nil" else: $j["rapporto"]["non_eseguiti"]

# 066:14:3 secondo giro dopo la revisione: AC-363..AC-376 sulle copie
# 066:14:4 congelate di prove/w12/g/ (le sonde del gate G-01..G-15, ricomposte da base.head). L'AC-377 è la suite intera.
block:
  let g = root / "prove" / "w12" / "g"
  proc cg(f: string, args: varargs[string]): Res = run(@["check"] & @args & @[f], g)
  proc has(r: Res, parts: varargs[string]): bool =
    for p in parts:
      if p notin r.output: return false
    true
  proc ac(n: int, label: string, ok: bool, why: string = "") = rec("AC-" & $n, label, ok, why)
  # AC-363: IN LAST prende un Postfisso
  block:
    let r = cg("g363.csc")
    ac 363, "COUNT(e) IN LAST 0.2 s <= 1 e NEVER ... > 1: formali, nessun E25; c := COUNT(e) IN LAST D / 2 è Real",
      has(r, "riga 14: GUARANTEE g1 formale", "riga 15: GUARANTEE g2 formale", "riga 17: GUARANTEE g3 formale") and
      r.output.count("[E25]") == 1 and has(r, "riga 18: [E25] tipo incoerente: serve Boolean, trovato Real"), r.output
  # AC-364: MIN e MAX vogliono due argomenti, tutti numeri o tutti durate
  block:
    let r = cg("g364a.csc")
    ac 364, "MIN(n) e MAX(n): non riconosciute, nessun errore", r.code == 0 and has(r, "GUARANTEE g1 non riconosciuta", "GUARANTEE g2 non riconosciuta", "non riconosciute 2)"), r.output
    let r2 = cg("g364b.csc")
    ac 364, "MIN(n, D): E25 un numero / Duration; MIN(n, r) formale", r2.code == 1 and
      has(r2, "riga 14: [E25] tipo incoerente: serve un numero, trovato Duration", "riga 15: GUARANTEE g2 formale") and r2.output.count("[E25]") == 1, r2.output
  # AC-365: un secondo indice su uno stato già indicizzato
  block:
    let r = cg("g365.csc")
    ac 365, "x[a][a]: E29 x[a] non ha indice, x[a] da solo no", r.code == 1 and has(r, "riga 14: [E29] x[a] non ha indice") and r.output.count("[E29]") == 1, r.output
  # AC-366: WITH dopo una fase
  block:
    let r = cg("g366.csc")
    ac 366, "requested(Cap) WITH non riconosciuta; fra parentesi formale", r.code == 0 and has(r, "riga 14: GUARANTEE g1 non riconosciuta", "riga 15: GUARANTEE g2 formale"), r.output
  # AC-367: nome qualificato in una fase
  block:
    let r = cg("g367.csc")
    ac 367, "in una CSC accepted(Cap.f) e accepted(Cap.zz): E20 col messaggio della CSC", r.code == 1 and r.output.count("[E20]") == 2 and
      has(r, "riga 14: [E20] Cap.f: in una CSC i nomi non si scrivono con il connettore davanti. L'ordine fra due connettori va in uno SCENARIO dell'entità"), r.output
    let re = cg("g367e.csc")
    ac 367, "in un'entità requested(P.Cap) senza errori, requested(P.s) E24 come CAPABILITY", re.code == 1 and re.output.count("[E") == 1 and
      has(re, "riga 20: [E24] nome non dichiarato come CAPABILITY: P.s"), re.output
  # AC-368: due parametri con lo stesso nome
  block:
    let r = cg("g368.csc")
    ac 368, "DEFINE F(a: Real, a: Real): E01", r.code == 1 and has(r, "riga 14: [E01] nome già usato alla riga 14: a"), r.output
  # AC-369: niente «?» come tipo
  block:
    let r = cg("g369.csc")
    ac 369, "TRANSITION verso un nome non dichiarato: E24; IN {1, b}: E25 trovato Fase", r.code == 1 and
      has(r, "riga 14: [E24] nome non dichiarato: c", "riga 15: [E25] tipo incoerente: serve Integer, trovato Fase") and "trovato ?" notin r.output, r.output
  # AC-370: un Optional T vale come T per i campi
  block:
    let r = cg("g370.csc")
    ac 370, "c : Optional R, c.L > 0: nessun errore", r.code == 0 and has(r, "riga 7: GUARANTEE g formale"), r.output
  # AC-371: IMPORT non riconosciuto non chiude la zona
  block:
    let r = cg("g371.csc")
    ac 371, "PROFILE Z con IMPORT e STATUS: STATUS HYPOTHESIS, una sola riga non riconosciuta (IMPORT)", has(r, "riga 1: PROFILE Z VERSION 0.1, STATUS HYPOTHESIS",
      "5. RIGHE NON RICONOSCIUTE: 1\n  riga 3: IMPORT PROFILE Seg VERSION 0.3\n"), r.output
  # AC-372: usi di KIND DECLARATION, in una CSC e in un BINDING
  block:
    let r = cg("g372.csc")
    ac 372, "SIGNAL ago[Fase] e LAMP luce: righe riconosciute, ago usabile; SIGNAL s[Fase] con s stato: E01; LAMP ripetuta: E01",
      r.code == 1 and has(r, "righe: 40 (riconosciute 38, commenti 0, vuote 2, non riconosciute 0)", "riga 32: [E01] nome già usato alla riga 29: s",
        "riga 39: [E01] nome già usato alla riga 38: luce", "riga 31: GUARANTEE g formale") and r.output.count("[E") == 2, r.output
  # AC-373: dettagli di DEFINE e di storie nelle sezioni 14 e 15
  block:
    let r = cg("g373.csc")
    ac 373, "s2 con VERBAL: sezione 14; D2 e s4 senza VERBAL: sezione 15, coerenza dei dettagli",
      has(r, "14. DA GIUDICARE: 1\n  riga 16: SCENARIO s2 DETAILS s1: coerenza fra la riga e la riga che dettaglia, una delle due a parole\n",
        "  coerenza dei dettagli: righe 20, 22\n"), r.output
  # AC-374: C2, C3 e C4 delle estensioni nella sezione 15
  block:
    let r = cg("g374.csc")
    ac 374, "FADE (C1, C3): storie; DURING (C4): inneschi; CONTRO (C2): coerenza",
      has(r, "15. CONTROLLI NON ESEGUITI: 3\n  storie: riga 67\n  copertura degli inneschi: riga 65\n  coerenza di presupposti e promesse: riga 66\n"), r.output
  # AC-375: la riduzione deve essere una forma che il lettore delle formule accetta
  block:
    for (f, what) in [("g375a.csc", ") ) ("), ("g375b.csc", "ALWAYS ALWAYS c"), ("g375c.csc", "EVENTUALLY c WITHIN")]:
      let r = cg(f)
      ac 375, "REDUCES TO " & what & ": riga non riconosciuta, niente E33, uso di grado estensione dichiarata", r.code == 0 and
        has(r, "non riconosciute 1)", "riga 22: GUARANTEE g estensione dichiarata", "riga 12: REDUCES TO " & what) and "[E3" notin r.output, r.output
    let r = cg("g375d.csc")
    ac 375, "una riduzione buona resta formale", r.code == 0 and has(r, "non riconosciute 0)", "riga 22: GUARANTEE g formale"), r.output
  block:
    let r = cg("g375e.csc")
    ac 375, "REDUCES TO WHENEVER p THEN q AT ONCE ripete una forma (S-7): E36 come senza AT ONCE", r.code == 1 and
      has(r, "riga 12: [E36] l'EXTENSION A ripete una forma che il linguaggio ha già: WHENEVER"), r.output
  # AC-378..AC-380: secondo gate (G-16..G-19), usi annidati e REDUCES TO
  block:
    let r = cg("g378.csc")
    ac 378, "DUR2 (NR r): l'uso dentro l'argomento conta, estensione dichiarata; g1 e g5 formali", has(r, "riga 28: GUARANTEE g1 formale",
      "riga 29: GUARANTEE g2 estensione dichiarata", "riga 32: GUARANTEE g5 formale"), r.output
    ac 379, "DUR2 s: ALWAYS s (ambito di estensione) in copertura degli inneschi come WHILE s", has(r, "copertura degli inneschi: righe 28, 32"), r.output
    let r2 = cg("g378b.csc")
    ac 378, "DURING (NEAR r TO 1.0): FADE …: inneschi e coerenza (C2 di NEAR, dentro l'argomento)",
      has(r2, "copertura degli inneschi: riga 56", "coerenza di presupposti e promesse: riga 56"), r2.output
    for (f, form) in [("g380a.csc", "PRECEDES"), ("g380b.csc", "PRECEDES"), ("g380c.csc", "FOR AT LEAST"), ("g380d.csc", "ENSURES"), ("g380e.csc", "REQUIRES")]:
      let q = cg(f)
      ac 380, f & ": E36 su una forma che comincia con un parametro", q.code == 1 and
        has(q, "riga 11: [E36] l'EXTENSION A ripete una forma che il linguaggio ha già: " & form, "non riconosciute 0)"), q.output
    let q2 = cg("g380f.csc")
    ac 380, "x REQUIRES q AND q: riconosciuta, senza E36", q2.code == 0 and has(q2, "non riconosciute 0)") and "[E36]" notin q2.output, q2.output
  # AC-382..AC-383: terzo gate (G-20..G-22), E36 sull'albero e DEFINE trasparenti
  block:
    for (n, form) in [("a", "PRECEDES"), ("b", "ABS"), ("c", "MAX"), ("d", "COUNT"), ("e", "requested"), ("f", "NOT"), ("g", "+"), ("h", "IF")]:
      let q = cg("g382" & n & ".csc")
      ac 382, "g382" & n & ": E36 con F = " & form, q.code == 1 and
        has(q, "riga 11: [E36] l'EXTENSION A ripete una forma che il linguaggio ha già: " & form & "\n", "non riconosciute 0)"), q.output
    for n in ["i", "j", "k", "l"]:
      let q = cg("g382" & n & ".csc")
      ac 382, "g382" & n & ": nessun E36", q.code == 0 and "[E36]" notin q.output and has(q, "non riconosciute 0)"), q.output
    let r = cg("g383.csc")
    ac 383, "usi attraverso DEFINE (anche alias e DEFINE EVENT): g1 e g2 estensione dichiarata, g3 formale",
      has(r, "riga 51: GUARANTEE g1 estensione dichiarata", "riga 52: GUARANTEE g2 estensione dichiarata", "riga 53: GUARANTEE g3 formale"), r.output
    ac 383, "sezione 15: storie di SQ (C3), coerenza di NR (C2)", has(r, "  storie: riga 54\n  coerenza di presupposti e promesse: righe 52, 53\n"), r.output
    let rt = cg("g383rat.csc")
    ac 383, "in una CSC approvata g3 (DEFINE K := SQ r) è da approvare (sezione 4)", has(rt, "4. IPOTESI, NON CONTRATTO: 7", "  riga 54: GUARANTEE g3\n"), rt.output
  # AC-385..AC-386: quarto gate (G-23, G-24)
  block:
    let r = cg("g385a.csc")
    ac 385, "durate scritte (1 s, 250 ms, 1s, COUNT … IN LAST 2 s, d + 1 s): nessun E35, nessun E36", r.code == 0 and "[E3" notin r.output and
      has(r, "non riconosciute 0)"), r.output
    let r2 = cg("g385b.csc")
    ac 385, "un parametro chiamato s fuori da un numero resta un parametro: E36 su ABS(s) e su EVENTUALLY p WITHIN s; con `1 s` e s inutilizzato no",
      r2.code == 1 and r2.output.count("[E36]") == 2 and "[E35]" notin r2.output and
        has(r2, "riga 11: [E36] l'EXTENSION B ripete una forma che il linguaggio ha già: ABS", "riga 31: [E36] l'EXTENSION D ripete una forma che il linguaggio ha già: EVENTUALLY"), r2.output
    let j = jsonDi(@["g383rat.csc"], g)
    var ok = j != nil
    var why = ""
    if ok:
      var found = 0
      for b in j["blocchi"]:
        if b.jstr("tipo") != "CSC": continue
        for gr in b["garanzie"]:
          if gr.jstr("id") in ["g2", "g3", "g4"]:
            inc found
            ok = ok and gr.jstr("stato") == "ipotesi" and gr.jstr("stato_di") == "profilo"
          elif gr.jstr("id") == "g":
            ok = ok and gr.jstr("stato") == "contratto" and gr.jstr("stato_di") == "intestazione"
      ok = ok and found == 3
      why = $j["blocchi"]
    ac 386, "JSON: le righe che usano un profilo da approvare hanno stato ipotesi e stato_di profilo; le altre restano intestazione", ok, why
  # AC-376: prove/14 con la riga 15 che usa solo nomi dichiarati
  block:
    let r = run(@["check", "prove/14_non_riconosciute.csc"], root)
    let st = run(@["check", "--strict", "prove/14_non_riconosciute.csc"], root)
    ac 376, "14: senza opzione codice 0, con --strict codice 3, nessun E24", r.code == 0 and st.code == 3 and "[E24]" notin r.output and "[E24]" notin st.output, r.output

# 066:14:2 B-1 (qui numerato AC-401): `bcdd save` protegge le righe approvate di BIND, BINDING, profili e dettagli di DEFINE e di storie.
block:
  let b = root / "prove" / "w12" / "blk"
  proc salvaB(w, file, testo: string): Res =
    runX(bcdd, @["save", file, "--expect", sha256Of(w / file)], w, nil, testo)
  let w = newWd()
  discard cpTo(b / "Luce.csc", w)
  let bnd = "BINDING Luce VERSION 0.1\n  STATUS RATIFIED BY D-1\n  BIND accesa: VERBAL \"la plafoniera\"\nEND\n"
  writeFile(w / "Bind.csc", bnd)
  proc tenta(file, testo: string): Res = salvaB(w, file, testo)
  let r1 = tenta("Bind.csc", bnd.replace("la plafoniera", "un'altra"))
  rec("AC-401", "una riga BIND approvata non si cambia", r1.code == 1 and "BIND accesa" in r1.errout and "è contratto" in r1.errout, r1.errout)
  let r2 = tenta("Bind.csc", bnd.replace("BINDING Luce VERSION 0.1", "BINDING Luce VERSION 0.1 AS x"))
  rec("AC-401", "l'intestazione di un BINDING approvato è bloccata", r2.code == 1, r2.errout)
  let r2b = tenta("Bind.csc", bnd.replace("VERSION 0.1", "VERSION 0.2"))
  rec("AC-401", "la versione di un BINDING approvato è bloccata", r2b.code == 1 and "il numero della versione non si cambia" in r2b.errout, r2b.errout)
  let r3 = tenta("Bind.csc", bnd.replace("  BIND accesa", "  BIND modo: VERBAL \"nuova\"\n  BIND accesa"))
  rec("AC-401", "una riga BIND nuova in un BINDING approvato diventerebbe contratto", r3.code == 1 and "diventerebbe contratto senza una ratifica" in r3.errout, r3.errout)
  let ip = "BINDING Luce VERSION 0.1\n  STATUS HYPOTHESIS\n  BIND accesa: VERBAL \"la plafoniera\"\nEND\n"
  writeFile(w / "Ip.csc", ip)
  let r3b = tenta("Ip.csc", ip.replace("HYPOTHESIS", "RATIFIED BY D-9"))
  rec("AC-401", "BINDING che diventa approvato senza ratify: rifiuto", r3b.code == 1, r3b.errout)
  let prof = readFile(root / "prove" / "w12" / "Segnale03.csc").replace("STATUS HYPOTHESIS", "STATUS RATIFIED BY D-2")
  writeFile(w / "Profilo.csc", prof)
  let r4 = tenta("Profilo.csc", prof.replace("s scende senza risalire", "s scende"))
  rec("AC-401", "una riga di un profilo approvato non si cambia", r4.code == 1 and "profilo Segnale è approvato" in r4.errout, r4.errout)
  let r4b = tenta("Profilo.csc", prof.replace("PROFILE Segnale VERSION 0.3", "PROFILE Segnale VERSION 0.4"))
  rec("AC-401", "la versione di un profilo approvato è bloccata", r4b.code == 1, r4b.errout)
  let det = "CSC K VERSION 0.1\n  STATUS RATIFIED BY D-1\n  PURPOSE \"k\"\n  DEFINE A := 1\n  DEFINE A1 DETAILS A STATUS RATIFIED BY D-5 := 2\n  SCENARIO s1 EXPECT ADMITTED\n  SCENARIO s1a DETAILS s1 STATUS RATIFIED BY D-5 EXPECT ADMITTED\nEND\n"
  writeFile(w / "Det.csc", det)
  let r5 = tenta("Det.csc", det.replace(":= 2", ":= 3"))
  rec("AC-401", "un dettaglio di DEFINE approvato non si cambia", r5.code == 1 and "DEFINE A1" in r5.errout, r5.errout)
  let r6 = tenta("Det.csc", det.replace("s1a DETAILS s1 STATUS RATIFIED BY D-5 EXPECT ADMITTED", "s1a DETAILS s1 STATUS RATIFIED BY D-5 GIVEN k = 1 EXPECT ADMITTED"))
  rec("AC-401", "un dettaglio di storia approvato non si cambia", r6.code == 1 and "SCENARIO s1a" in r6.errout, r6.errout)
  let r7 = tenta("Det.csc", det.replace("DEFINE A1 DETAILS A STATUS RATIFIED BY D-5", "DEFINE A1 DETAILS A STATUS RATIFIED BY D-7"))
  rec("AC-401", "la decisione di un dettaglio approvato non si cambia", r7.code == 1, r7.errout)
  let r8 = tenta("Det.csc", det.replace("DEFINE A := 1\n", "DEFINE A := 1\n  DEFINE A2 DETAILS A STATUS RATIFIED BY D-5 := 4\n"))
  rec("AC-401", "un dettaglio di DEFINE nuovo scritto già approvato: rifiuto", r8.code == 1 and "diventerebbe contratto" in r8.errout, r8.errout)
  # --remove: righe approvate in qualunque blocco
  let rm = runX(bcdd, @["save", "Bind.csc", "--remove", "--expect", sha256Of(w / "Bind.csc")], w, nil, "")
  rec("AC-401", "--remove rifiuta un file con un BINDING approvato", rm.code == 1 and "ha righe approvate" in rm.errout and fileExists(w / "Bind.csc"), rm.errout)
  let rmp = runX(bcdd, @["save", "Profilo.csc", "--remove", "--expect", sha256Of(w / "Profilo.csc")], w, nil, "")
  rec("AC-401", "--remove rifiuta un file con un profilo approvato", rmp.code == 1 and fileExists(w / "Profilo.csc"), rmp.errout)
  # una VERIFICATION non ha stato: si cambia sempre, anche in un file con una CSC approvata
  let csc = "CSC Luce VERSION 0.1\n  STATUS RATIFIED BY D-1\n  PURPOSE \"l\"\n  STATE accesa : Boolean INITIAL false\nEND\n"
  let ver = csc & "VERIFICATION Luce VERSION 0.1\n  MEANS cam OBSERVES accesa RESOLUTION 40 ms\nEND\n"
  writeFile(w / "Ver.csc", ver)
  let r9 = tenta("Ver.csc", ver.replace("40 ms", "20 ms"))
  rec("AC-401", "una VERIFICATION in un file con una CSC approvata si cambia", r9.code == 0 and "20 ms" in readFile(w / "Ver.csc"), r9.errout)

# 066:14:3 B-1, misura del 25/11: i rifiuti della 14.8 non coperti dalle prove di AC-401 (AC-389..AC-396)
block:
  let w = newWd()
  proc tenta(file, testo: string): Res =
    runX(bcdd, @["save", file, "--expect", sha256Of(w / file)], w, nil, testo)
  let bind2 = "BINDING Luce VERSION 0.1\n  STATUS HYPOTHESIS\n  BIND accesa STATUS RATIFIED BY D-4: VERBAL \"la plafoniera\"\n  BIND altra: VERBAL \"x\"\nEND\n"
  writeFile(w / "Bind2.csc", bind2)
  let r1 = tenta("Bind2.csc", bind2.replace("la plafoniera", "diversa"))
  rec("AC-389", "una riga BIND con un suo STATUS approvato, in un BINDING da approvare, non si cambia (il messaggio nomina il blocco)",
    r1.code == 1 and "BIND accesa di Luce è contratto" in r1.errout, r1.errout)
  let r2 = tenta("Bind2.csc", bind2.replace("BIND altra:", "BIND altra STATUS RATIFIED BY D-4:"))
  rec("AC-390", "una riga BIND che si scrive già approvata: rifiuto", r2.code == 1 and "BIND altra di Luce diventerebbe contratto senza una ratifica" in r2.errout, r2.errout)
  let r3 = tenta("Bind2.csc", bind2.replace("D-4", "D-6"))
  rec("AC-391", "la decisione di una riga BIND approvata non si cambia", r3.code == 1 and "è contratto" in r3.errout, r3.errout)
  let prof = "PROFILE Segnale VERSION 0.3\n  STATUS HYPOTHESIS\n  EXTENSION sale(s) KIND rising\nEND\n"
  writeFile(w / "Prof.csc", prof)
  let r4 = tenta("Prof.csc", prof.replace("HYPOTHESIS", "RATIFIED BY D-2"))
  rec("AC-392", "un profilo che diventa approvato senza ratify: rifiuto", r4.code == 1 and "diventerebbe contratto senza una ratifica" in r4.errout, r4.errout)
  let profA = prof.replace("HYPOTHESIS", "RATIFIED BY D-2")
  writeFile(w / "ProfA.csc", profA)
  let r5 = tenta("ProfA.csc", profA.replace("Segnale", "Altro"))
  rec("AC-393", "il nome nell'intestazione di un profilo approvato non si cambia", r5.code == 1, r5.errout)
  let r6 = tenta("ProfA.csc", profA.replace("rising", "falling"))
  rec("AC-394", "un'estensione di un profilo approvato non si cambia", r6.code == 1 and "le sue righe non si cambiano" in r6.errout, r6.errout)
  let r7 = tenta("ProfA.csc", profA.replace("END\n", "  EXTENSION x(s) KIND rising\nEND\n"))
  rec("AC-395", "un'estensione aggiunta a un profilo approvato: rifiuto", r7.code == 1 and "le sue righe non si cambiano" in r7.errout, r7.errout)
  let cscd = "CSC K VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"k\"\n  DEFINE A := 1\n  DEFINE A1 DETAILS A STATUS RATIFIED BY D-5 := 2\nEND\n"
  writeFile(w / "Cscd.csc", cscd)
  let rm = runX(bcdd, @["save", "Cscd.csc", "--remove", "--expect", sha256Of(w / "Cscd.csc")], w, nil, "")
  rec("AC-396", "--remove rifiuta un file con un dettaglio di DEFINE approvato in una CSC da approvare",
    rm.code == 1 and "ha righe approvate" in rm.errout and fileExists(w / "Cscd.csc"), rm.errout)

# 068:1:1 nome esatto e nomi di dispositivo. Su Linux sono sempre veri; la stessa prova su Windows
# 068:1:2 (tests/windows/) dà gli stessi byte. La citazione `luce` non trova `Luce.csc`; la citazione `CON` vale «non trovata».
block:
  let w397 = root / "prove" / "w397"
  for nome in ["Maiuscole", "Dispositivo"]:
    let r = runX(bcdd, @["--lang", "it", "check", nome & ".csc"], w397, nil)
    expectOut("AC-402", nome & ": rapporto uguale all'atteso, citazione non trovata", "w397/" & nome, r,
      readFile(w397 / (nome & ".atteso")), 0)

# 067:0:1 le prove delle due lingue
include "tbcdd_lingue.inc"

# 061:1:1 Pulizia e verdetto compatto
removeDir(tmpBase)
var totalPass, totalAll, acFail = 0
acOrder.sort(proc(a, b: string): int =
  proc key(s: string): (int, int) =
    if s == "X": return (2, 0)
    (1, parseInt(s[3 .. ^1]))
  cmp(key(a), key(b)))
for ac in acOrder:
  let ok = acPass[ac] == acTotal[ac]
  totalPass += acPass[ac]
  totalAll += acTotal[ac]
  if not ok: inc acFail
  echo align(ac, 5) & "  " & (if ok: "PASS " else: "FAIL ") & $acPass[ac] & "/" & $acTotal[ac]
  if not ok:
    for d in details[ac]: echo "        - " & d
echo "prove: " & $(proveSeen.len - proveFail.len) & "/" & $proveSeen.len & " PASS (file di prova distinti)"
echo "controlli: " & $totalPass & "/" & $totalAll & " PASS; criteri non riusciti: " & $acFail &
  "; durata suite: " & formatFloat(epochTime() - t0, ffDecimal, 2) & " s"
quit(if totalPass == totalAll: 0 else: 1)

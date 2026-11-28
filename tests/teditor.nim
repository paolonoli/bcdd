# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 080:1:1 Suite di accettazione di bcdd-editor, pezzi 1, 2, 3, 4 e 5. Metodo leggero: poche prove.
# 080:1:2 Il modello (AC-210) si prova senza GTK, importando editor/edmodello. Le prove con la finestra girano sotto Xvfb
# 080:1:3 (se manca, i criteri che lo chiedono FALLISCONO: un criterio non eseguito non è un criterio riuscito).
# 080:1:4 La prova di rete rilancia questo stesso eseguibile con `--rete-interna` dentro `unshare -rn`.
# 080:1:5 Verdetto compatto come tbcdd: una riga per criterio, i dettagli solo per i FAIL; codice 1 se qualcosa non riesce.
import std/[os, osproc, streams, strutils, tables, times, algorithm, strtabs, json, net, nativesockets, sequtils]
import ../editor/edmodello
import ../editor/edbcdd
import ../editor/edazioni
import ../editor/edtesti
import ../editor/edlinea
import ../editor/edrif
import std/[math, sets]

proc toHashSetLocal(l: openArray[string]): HashSet[string] = l.toHashSet

# 080:1:6: le prove esistenti sono in italiano. La lingua dei testi in questo processo e, per i processi che si lanciano
# (bcdd, editor), la variabile BCDD_LANG sono fissate a `it`; le prove delle due lingue (L-E1..L-E11) la impostano a parte.
lingua = lgIt
putEnv("BCDD_LANG", "it")

type
  Res = tuple[output, errout: string, code: int]

let
  root = currentSourcePath().parentDir.parentDir
  bcdd = getEnv("BCDD", root / "bcdd")
  bcddProva = root / "tests" / "bcdd_prova"
  edRel = root / "bcdd-editor"
  edProva = root / "tests" / "bcdd-editor_prova"
  t0 = epochTime()

var edProvaCorrente = edProva    # la sonda di L-E1/L-E6 gira anche con l'editor di f8ebbdea (BCDD_EDITOR_PROVA_VECCHIO)

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

var nonEsercitati: seq[string]

proc nonEsercitato(ac, label, perche: string) =
  ## Un controllo che sotto Xvfb non si può esercitare: né PASS né FAIL, contato a parte (rinforzo di AC-194).
  nonEsercitati.add ac & ": " & label & " (" & perche & ")"

proc cut(s: string, n = 300): string = (if s.len > n: s[0 ..< n] & "..." else: s)

# 080:2:1 Processi
proc envPulito(extra: openArray[(string, string)] = [], senzaDisplay = true): StringTableRef =
  result = newStringTable(modeCaseSensitive)
  for k, v in envPairs():
    if k in ["DISPLAY", "WAYLAND_DISPLAY"] and senzaDisplay: continue
    result[k] = v
  result["BCDD_LANG"] = "it"
  # la suite non dipende dalla lingua della macchina (senza BCDD_LANG vale quella del sistema)
  result["LANG"] = "C"
  result.del("LC_ALL")
  result.del("LC_MESSAGES")
  for (k, v) in extra: result[k] = v

proc runExe(exe: string, args: seq[string], cwd: string, env: StringTableRef = nil): Res =
  let p = startProcess(exe, workingDir = cwd, args = args, env = env, options = {})
  result.output = p.outputStream.readAll()
  result.errout = p.errorStream.readAll()
  result.code = p.waitForExit()
  p.close()

proc runBcdd(args: seq[string], cwd: string = root): Res = runExe(bcdd, args, cwd)

proc leggiSe(f: string): string = (if fileExists(f): readFile(f) else: "")

proc attendi(f, needle: string, secondi: int): bool =
  let fine = epochTime() + float(secondi)
  while epochTime() < fine:
    if needle in leggiSe(f): return true
    sleep(50)
  false

proc righe(f: string): seq[string] = leggiSe(f).splitLines().filterIt(it.len > 0)

proc spegni(p: Process) =
  if p == nil: return
  try:
    if p.running:
      p.terminate()
      if p.waitForExit(1500) == -1: discard
      if p.running: p.kill()
  except CatchableError: discard
  try: p.close() except CatchableError: discard

# 080:2:2 Xvfb
var xvfb: Process
let numDisplay = 300 + (getCurrentProcessId() mod 200)
var xvfbOk = false

proc avviaXvfb(n: int): Process =
  let sock = "/tmp/.X11-unix/X" & $n
  if fileExists("/tmp/.X" & $n & "-lock"): discard tryRemoveFile("/tmp/.X" & $n & "-lock")
  if findExe("Xvfb").len == 0: return nil
  result = startProcess(findExe("Xvfb"), args = @[":" & $n, "-screen", "0", "1280x900x24", "-nolisten", "tcp"],
    options = {poStdErrToStdOut})
  let fine = epochTime() + 8.0
  while epochTime() < fine:
    var esiste = false
    try:
      discard getFileInfo(sock)
      esiste = true
    except OSError: discard
    if esiste:
      sleep(300)
      return
    sleep(50)
  result.spegni()
  result = nil

proc displayStr(n: int): string = ":" & $n

proc xdo(display: string, args: seq[string]): string =
  let (o, _) = execCmdEx("DISPLAY=" & quoteShell(display) & " xdotool " & args.map(quoteShell).join(" "))
  o.strip()

proc trovaFinestra(display, nome: string, secondi = 10): string =
  let fine = epochTime() + float(secondi)
  while epochTime() < fine:
    let o = xdo(display, @["search", "--onlyvisible", "--name", nome])
    if o.len > 0: return o.splitLines()[0]
    sleep(100)

# 080:2:3 Sessioni dell'editor di prova
type Sess = object
  dir, bin, trace, lanci, home: string
  p: Process

var tmpBase = getTempDir() / ("bcdd_editor_test_" & $getCurrentProcessId())
createDir(tmpBase)
var contaSess = 0

proc nuovaSessione(): Sess =
  inc contaSess
  result.dir = tmpBase / ("s" & $contaSess)
  result.bin = result.dir / "bin"
  result.home = result.dir / "home"
  result.trace = result.dir / "traccia"
  result.lanci = result.dir / "lanci"
  createDir result.bin
  createDir result.home
  createDir result.dir / "xdg_cache"
  createDir result.dir / "xdg_data"
  createDir result.dir / "xdg_config"
  copyFile(edProvaCorrente, result.bin / "bcdd-editor_prova")
  setFilePermissions(result.bin / "bcdd-editor_prova", {fpUserExec, fpUserRead, fpUserWrite})
  # `lanci.completi` ha ogni lancio com'è, con il `--lang L` in testa; `lanci` lo stesso senza quelle due parole (le prove di prima restano valide)
  writeFile(result.bin / "bcdd_prova", "#!/bin/sh\nprintf '%s\\n' \"$*\" >> '" & result.lanci & ".completi'\nL=\"$1\"\nif [ \"$1\" = \"--lang\" ]; then A=\"$2\"; shift 2; fi\nprintf '%s\\n' \"$*\" >> '" & result.lanci & "'\nexec '" & bcddProva & "' ${A:+--lang \"$A\"} \"$@\"\n")
  setFilePermissions(result.bin / "bcdd_prova", {fpUserExec, fpUserRead, fpUserWrite})

proc avviaEditor(s: var Sess, args: seq[string], cwd: string, extra: seq[(string, string)] = @[], display = displayStr(numDisplay)) =
  var ex = @[("DISPLAY", display), ("HOME", s.home), ("XDG_CACHE_HOME", s.dir / "xdg_cache"),
    ("XDG_DATA_HOME", s.dir / "xdg_data"), ("XDG_CONFIG_HOME", s.dir / "xdg_config"), ("BCDD_EDITOR_TRACCIA", s.trace)]
  ex.add extra
  let env = envPulito(ex)
  s.p = startProcess("/bin/sh", workingDir = cwd,
    args = @["-c", "exec \"$0\" \"$@\" >/dev/null 2>'" & s.dir / "errori" & "'", s.bin / "bcdd-editor_prova"] & args,
    env = env, options = {})

proc finisci(s: var Sess) =
  s.p.spegni()
  s.p = nil

proc nLanci(s: Sess): int = righe(s.lanci).len
proc nDisegni(s: Sess): int = righe(s.trace).countIt(" disegno " in it)
proc paginaN(s: Sess, n: int): string = leggiSe(s.trace & ".pagina." & $n)
proc azioniLanci(s: Sess): seq[string] = righe(s.lanci).mapIt(it.splitWhitespace()[0])

proc focusAltrove(display, finestra: string) =
  ## Porta il fuoco su un'altra finestra (xmessage) e poi di nuovo sull'editor, come la sonda USondaAttiva.sh.
  let xm = startProcess(findExe("xmessage"), args = @["-display", display, "-name", "altra", "altra"], options = {poStdErrToStdOut})
  let altra = trovaFinestra(display, "altra", 5)
  if altra.len > 0:
    discard xdo(display, @["windowfocus", "--sync", altra])
    sleep(500)
  discard xdo(display, @["windowfocus", "--sync", finestra])
  sleep(500)
  xm.spegni()

proc codeRoot(s: string): string = s.replace(root & "/", "")


proc newWd0(): string =
  inc contaSess
  result = tmpBase / ("w" & $contaSess)
  createDir(result)

# 080:3:1 JSON di una cartella di prova
proc jsonDi(args: seq[string], cwd = root): JsonNode =
  let r = runBcdd(@["check", "--json"] & args, cwd)
  if not r.output.startsWith("{"): return nil
  try: result = parseJson(r.output)
  except CatchableError: result = nil

proc copiaCartella(da: string): string =
  ## Una cartella di lavoro nuova con i `.csc` di `da`: l'editor non deve mai toccare i file del deposito.
  result = newWd0()
  for f in walkFiles(da / "*.csc"): copyFile(f, result / f.extractFilename)

proc fotografia(d: string): Table[string, (string, Time)] =
  for f in walkFiles(d / "*"): result[f.extractFilename] = (readFile(f), getLastModificationTime(f))

var azioniViste: seq[string]      # i sottocomandi di bcdd lanciati dall'editor in tutte le sessioni

proc raccogli(s: Sess) =
  for a in azioniLanci(s):
    if a notin azioniViste: azioniViste.add a

# 080:4:1 Il programma
if paramCount() >= 1 and paramStr(1) == "--rete-interna":
  # 080:4:2 Dentro `unshare -rn`: lo spazio di rete ha solo `lo`. Xvfb, ascoltatore e editor stanno tutti qui dentro.
  let porta = 47831
  discard execCmd("ip link set lo up")
  let n = numDisplay + 1
  let xv = avviaXvfb(n)
  if xv == nil:
    echo "XVFB assente"
    quit(0)
  let srv = newSocket()
  srv.setSockOpt(OptReuseAddr, true)
  srv.bindAddr(Port(porta), "127.0.0.1")
  srv.listen()
  srv.getFd().setBlocking(false)
  var s = nuovaSessione()
  s.avviaEditor(@["--dir", "prove/f3/luce", "LuceScale"], root,
    @[("BCDD_EDITOR_SONDA_RETE", $porta)], displayStr(n))
  var conn = 0
  var stray: seq[string]
  let propria = "127.0.0.1:" & $porta
  let fine = epochTime() + 9.0
  var viva = true
  while epochTime() < fine:
    try:
      var c: Socket
      srv.accept(c)
      inc conn
      c.close()
    except OSError:
      sleep(100)
    let (o, _) = execCmdEx("ss -tuanH")
    for l in o.splitLines():
      let c = l.splitWhitespace()
      if c.len < 5: continue
      if not (c[1] == "LISTEN" and c[4] == propria) and l notin stray: stray.add l
    if not s.p.running: viva = false
  echo "PAGINA ", ("pagina 1" in leggiSe(s.trace))
  echo "VIVA ", viva
  echo "CONNESSIONI ", conn
  for l in stray: echo "STRAY ", l
  s.finisci()
  xv.spegni()
  removeDir(tmpBase)
  quit(0)

xvfb = avviaXvfb(numDisplay)
xvfbOk = xvfb != nil
let display = displayStr(numDisplay)
proc senzaXvfb(ac, label: string) = rec(ac, label, false, "Xvfb assente: non eseguito")

# 080:5:1 AC-184: bcdd senza GTK
block:
  let nim = readFile(root / "BcddTool.nimble")
  let a = nim.find("task test,")
  let b = nim.find("# 002:1:1")
  let blocco = if a >= 0: nim[a ..< (if b > a: b else: nim.len)] else: ""
  rec("AC-184", "il task test non nomina editor/", a >= 0 and "editor" notin blocco, "il task test nomina editor")
  rec("AC-184", "bin del pacchetto = bcdd", "bin           = @[\"bcdd\"]" in nim, "bin cambiato")
  let (ld, _) = execCmdEx("ldd " & quoteShell(bcdd))
  rec("AC-184", "ldd bcdd senza gtk, webkit, javascriptcore",
    "libgtk-3" notin ld and "libwebkit2gtk" notin ld and "libjavascriptcoregtk" notin ld, ld)
  var importa: seq[string]
  for f in walkFiles(root / "src" / "*.nim"):
    for l in readFile(f).splitLines():
      if l.strip().startsWith("import") and ("editor" in l or "gtk" in l.toLowerAscii): importa.add f & ": " & l
  rec("AC-184", "nessun file di src/ importa da editor/", importa.len == 0, importa.join("; "))

# 080:5:2 AC-185: la costruzione
block:
  for (ac, f) in [("AC-185", edRel), ("AC-185", edProva)]:
    rec(ac, "esiste " & f.extractFilename, fileExists(f), "manca")
    let (ld, _) = execCmdEx("ldd " & quoteShell(f))
    rec(ac, f.extractFilename & ": libwebkit2gtk-4.1 e libgtk-3, non la 4.0",
      "libwebkit2gtk-4.1" in ld and "libgtk-3" in ld and "libwebkit2gtk-4.0" notin ld, ld)
  rec("AC-185", "bcdd-editor accanto a bcdd", edRel.parentDir == bcdd.parentDir or bcdd == root / "bcdd", "")
  var piuRecente = fromUnix(0)
  for f in walkFiles(root / "editor" / "*.nim"): piuRecente = max(piuRecente, getLastModificationTime(f))
  for f in walkFiles(root / "editor" / "pagina" / "*"): piuRecente = max(piuRecente, getLastModificationTime(f))
  rec("AC-185", "gli editor non sono più vecchi dei sorgenti (rifare `nimble editor`)",
    fileExists(edRel) and fileExists(edProva) and getLastModificationTime(edRel) >= piuRecente and
    getLastModificationTime(edProva) >= piuRecente, "eseguibili vecchi")
  let nim = readFile(root / "BcddTool.nimble")
  let t = nim.find("task testeditor,")
  let bloccoT = if t >= 0: nim[t .. ^1] else: ""
  rec("AC-185", "testeditor lancia teditor con `passo` (codice d'uscita diverso da 0 se fallisce)",
    t >= 0 and "passo \"nim c -r" in bloccoT and "tests/teditor.nim" in bloccoT and "task editor," in nim and
    "proc passo(" in nim and "terminaNimble" in nim, "task mancante o senza passo")
  rec("AC-185", "task editor con -d:bcddEditorProva", "-d:bcddEditorProva" in nim and "--out:bcdd-editor " in nim, "")

# 080:5:3 AC-186: uso e casi che non aprono, senza display
block:
  let ambiente = envPulito()
  let uso = usoEditor() & "\n"
  proc senzaDisp(exe: string, args: seq[string], cwd = root): Res = runExe(exe, args, cwd, ambiente)
  for (exe, nome) in [(edRel, "release"), (edProva, "prova")]:
    for (etichetta, args) in [("--dir senza cartella", @["--dir"]), ("--dir a --dir a", @["--dir", "a", "--dir", "a"]),
        ("--x", @["--x", "--dir", "a"]), ("--dir=a", @["--dir=a"]), ("due NOMI", @["--dir", "a", "N1", "N2"]),
        ("NOME non valido", @["--dir", "a", "N-1"])]:
      let r = senzaDisp(exe, args)
      rec("AC-186", nome & " " & etichetta, r.code == 2 and r.errout == uso and r.output.len == 0,
        "codice " & $r.code & " stderr [" & cut(r.errout) & "]")
  # senza `--dir` si sceglie la cartella: senza display il messaggio è quello del display, non la riga d'uso
  for (exe, nome) in [(edRel, "release"), (edProva, "prova")]:
    for (etichetta, args) in [("nessun argomento", newSeq[string]()), ("solo NOME", @["Nome"]), ("--lang it", @["--lang", "it"])]:
      let r = senzaDisp(exe, args)
      rec("AC-186", nome & " " & etichetta & " senza display: dice del display", r.code == 2 and r.errout == "bcdd-editor: non riesco ad aprire il display\n" and r.output.len == 0,
        "codice " & $r.code & " stderr [" & cut(r.errout) & "]")
  for (exe, nome, figlio) in [(edRel, "release", "bcdd"), (edProva, "prova", "bcdd_prova")]:
    # editor da solo in una cartella
    let d = tmpBase / ("solo_" & nome)
    createDir d
    copyFile(exe, d / "bcdd-editor")
    setFilePermissions(d / "bcdd-editor", {fpUserExec, fpUserRead, fpUserWrite})
    let r = senzaDisp(d / "bcdd-editor", @["--dir", "prove/f3/luce"])
    rec("AC-186", nome & " senza bcdd accanto", r.code == 2 and r.errout == "bcdd-editor: non trovo bcdd in " & expandFilename(d) & "\n" and
      r.output.len == 0, "codice " & $r.code & " [" & cut(r.errout) & "]")
    discard figlio
  # cartella che non c'è, entità che non c'è
  let r1 = senzaDisp(edProva, @["--dir", "non_esiste"], root)
  rec("AC-186", "cartella che non c'è", r1.code == 2 and r1.errout == "bcdd-editor: cartella non trovata: non_esiste\n" and r1.output.len == 0, cut(r1.errout))
  let r2 = senzaDisp(edProva, @["--dir", "prove/f3/luce", "Inesistente"], root)
  rec("AC-186", "entità che non c'è", r2.code == 2 and r2.errout == "bcdd-editor: nessuna entità Inesistente in prove/f3/luce\n" and r2.output.len == 0, cut(r2.errout))
  # bcdd finti: nella cartella di lavoro c'è un solo x.csc
  let vero = runBcdd(@["check", "--json", "esempi/LuceScale.csc"]).output
  # A-4: uno `stato_di` mai visto e un tipo di blocco sconosciuto non fermano la lettura; il valore `profilo` è noto
  block:
    var j2 = parseJson(vero)
    for b in j2["blocchi"]:
      for g in b["garanzie"]: g["stato_di"] = %"altro"
    j2["blocchi"].add %*{"tipo": "FUTURO", "nome": "X", "intestazione_valida": true, "da": 90, "a": 91}
    rec("AC-186", "stato_di mai visto e blocco di tipo sconosciuto: la lettura riesce", leggiUscita("bcdd", "x.csc", $j2, 0).ok and "profilo" in statiDiNoti)
    rec("AC-186", "una forma 4 si rifiuta con il messaggio di versione", not leggiUscita("bcdd", "x.csc", vero.replace("\"versione\": 5", "\"versione\": 4"), 0).ok)
  let casiFinti = @[
    ("versione 4", vero.replace("\"versione\": 5", "\"versione\": 4"), "bcdd-check", "4"),
    ("versione 6", vero.replace("\"versione\": 5", "\"versione\": 6"), "bcdd-check", "6"),
    ("forma diversa", vero.replace("\"forma\": \"bcdd-check\"", "\"forma\": \"altro-check\""), "altro-check", "5"),
    ("non JSON", "ciao\n", "?", "?")]
  for (exe, nome, figlio) in [(edRel, "release", "bcdd"), (edProva, "prova", "bcdd_prova")]:
    for (etichetta, contenuto, forma, versione) in casiFinti:
      let d = tmpBase / ("finto_" & nome & "_" & etichetta.replace(" ", "_"))
      createDir d
      createDir d / "lavoro"
      writeFile(d / "lavoro" / "x.csc", "ENTITY X VERSION 0.1\n  PURPOSE \"x\"\nEND\n")
      copyFile(exe, d / "bcdd-editor")
      setFilePermissions(d / "bcdd-editor", {fpUserExec, fpUserRead, fpUserWrite})
      writeFile(d / "uscita.json", contenuto)
      writeFile(d / figlio, "#!/bin/sh\ncat '" & d / "uscita.json" & "'\nexit 0\n")
      setFilePermissions(d / figlio, {fpUserExec, fpUserRead, fpUserWrite})
      let r = senzaDisp(d / "bcdd-editor", @["--dir", d / "lavoro"], root)
      let atteso = "bcdd-editor conosce bcdd-check versione 5; " & expandFilename(d) / figlio & " risponde con forma " & forma &
        ", versione " & versione & ": non apro x.csc\n"
      rec("AC-186", nome & " bcdd finto: " & etichetta, r.code == 2 and r.errout == atteso and r.output.len == 0,
        "codice " & $r.code & " [" & cut(r.errout) & "] atteso [" & cut(atteso) & "]")
    let d = tmpBase / ("rotto_" & nome)
    createDir d
    createDir d / "lavoro"
    writeFile(d / "lavoro" / "x.csc", "ENTITY X VERSION 0.1\n  PURPOSE \"x\"\nEND\n")
    copyFile(exe, d / "bcdd-editor")
    setFilePermissions(d / "bcdd-editor", {fpUserExec, fpUserRead, fpUserWrite})
    writeFile(d / figlio, "#!/bin/sh\nprintf 'guasto di prova\\nseconda riga' >&2\nexit 3\n")
    setFilePermissions(d / figlio, {fpUserExec, fpUserRead, fpUserWrite})
    let r = senzaDisp(d / "bcdd-editor", @["--dir", d / "lavoro"], root)
    rec("AC-186", nome & " bcdd finto che fallisce: stderr così com'è", r.code == 2 and
      r.errout == "x.csc: guasto di prova\nseconda riga (codice 3)\n", cut(r.errout))

# 080:6:0 AC-238: le forme della GRAMMATICA_F1 1.20 nel modello e nelle azioni: molteplicità di una parte, numeri con segno
block:
  let d = tmpBase / "w05"
  createDir d
  writeFile(d / "Sensore.csc", "ENTITY Sensore VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"s\"\nEND\n")
  writeFile(d / "Banco.csc", "ENTITY Banco VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"b\"\n  COMPOSED OF\n" &
    "    a : Sensore [1 .. 4]\n    b : Altro [2 .. 3]\nEND\n")
  let jb = jsonDi(@["--dir", ".", "Banco.csc"], d)
  let js = jsonDi(@["--dir", ".", "Sensore.csc"], d)
  let mw = buildBanco("w05", @[("Banco.csc", jb), ("Sensore.csc", js)])
  var molt: seq[string]
  for e in mw["entita"]:
    if e["nome"].getStr == "Banco":
      for p in e["parti"]: molt.add p["parte"].getStr & "=" & p["molteplicita"].getStr & (if p["trovata"].getBool: "+" else: "-")
  rec("AC-238", "il modello porta la molteplicità, anche di un posto la cui entità manca", molt == @["a=1 .. 4+", "b=2 .. 3-"], $molt)
  let raw = readFile(d / "Banco.csc")
  var err = ""
  let senzaA = togliParte(raw, jb, "Banco", "a", err)
  rec("AC-238", "si toglie un posto con la molteplicità", err == "" and "a : Sensore" notin senzaA and "b : Altro" in senzaA, err)
  err = ""
  let conC = aggiungiParte(raw, jb, "Banco", "c", "Sensore", err, "1 .. 2")
  rec("AC-238", "si scrive un posto con la molteplicità", err == "" and "    c : Sensore [1 .. 2]" in conC, err)
  let q = postoDiRiga("  a:B[2 .. 3]")
  rec("AC-238", "postoDiRiga legge e non legge", q.ok and q.parte == "a" and q.entita == "B" and q.molt == "2 .. 3" and
    not postoDiRiga("a : B [2 .. ]").ok and not postoDiRiga("a : B VERSION 0.1").ok, "")
  rec("AC-238", "valori con segno: Integer e Real sì, Duration no", validaValore("Integer", "-3", "") == "" and
    validaValore("Real", "-20.0", "") == "" and validaValore("Real", "--2", "") != "" and validaValore("Duration", "-2", "s") != "", "")

# 080:6:1 AC-210: il modello sulla luce delle scale
block:
  let luce = root / "prove" / "f3" / "luce"
  var caricati: seq[(string, JsonNode)]
  var nomi: seq[string]
  for f in walkFiles(luce / "*.csc"): nomi.add f.extractFilename
  nomi.sort()
  for f in nomi:
    let j = jsonDi(@["--dir", ".", f], luce)
    if j != nil: caricati.add (f, j)
  rec("AC-210", "tutti i file della luce si leggono", caricati.len == nomi.len and nomi.len >= 8, $caricati.len & "/" & $nomi.len)
  let m = buildBanco("luce", caricati)
  rec("AC-210", "lo stesso input dà lo stesso modello, byte per byte", $buildBanco("luce", caricati) == $m, "")
  proc ent(n: string): JsonNode =
    for e in m["entita"]:
      if e["nome"].getStr == n: return e
  let ls = ent("LuceScale")
  rec("AC-210", "LuceScale: esiste, con due parti e due connettori pubblici", ls != nil and ls["parti"].len == 2 and ls["offre"].len == 2 and ls["usa"].len == 0, "")
  if ls != nil:
    rec("AC-210", "LuceScale: un solo accoppiamento, Comando da pulsante a lampada",
      ls["accoppiamenti"].len == 1 and ls["accoppiamenti"][0]["csc"].getStr == "Comando" and
      ls["accoppiamenti"][0]["da"].getStr == "pulsante" and ls["accoppiamenti"][0]["a"].getStr == "lampada", $ls["accoppiamenti"])
    var pass: seq[string]
    for p in ls["passaggi"]: pass.add p["lato"].getStr & " " & p["csc"].getStr & " " & p["parte"].getStr
    rec("AC-210", "LuceScale: due passaggi, Pressione al pulsante e Luce alla lampada",
      pass.len == 2 and "OFFERS Pressione pulsante" in pass and "OFFERS Luce lampada" in pass, $pass)
    var liberiPubblici = 0
    for l in ls["liberi"]:
      if l["pubblico"].getBool: inc liberiPubblici
    rec("AC-210", "LuceScale: i connettori liberi sono due e sono quelli pubblici",
      ls["liberi"].len == 2 and liberiPubblici == 2 and ls["problemi"].len == 0, $ls["liberi"])
    rec("AC-210", "LuceScale: chiusa, nessun messaggio", ls["stato"].getStr == "chiusa" and ls["messaggi"].len == 0, ls["stato"].getStr)
  let pu = ent("Pulsante")
  rec("AC-210", "Pulsante: non scomposta", pu != nil and pu["stato"].getStr == "non_scomposta" and pu["parti"].len == 0, "")
  var comando: JsonNode
  for c in m["csc"]:
    if c["nome"].getStr == "Comando": comando = c
  rec("AC-210", "Comando: offerta da Pulsante, usata da Lampada (e da DaFuori, che la usa dal bordo)",
    comando != nil and $comando["offerta_da"] == "[\"Pulsante\"]" and "Lampada" in $comando["usata_da"], if comando != nil: $comando["usata_da"] else: "manca")
  let sp = ent("SenzaPulsante")
  rec("AC-210", "SenzaPulsante: zoppa, la lampada usa Comando e nessuno lo offre (E14)",
    sp != nil and sp["stato"].getStr == "zoppa" and sp["problemi"].len == 1 and sp["problemi"][0]["codice"].getStr == "E14" and
    sp["problemi"][0]["csc"].getStr == "Comando" and sp["problemi"][0]["parte"].getStr == "lampada" and
    sp["messaggi"].len == 1 and "Comando" in sp["messaggi"][0].getStr, if sp != nil: $sp["problemi"] & $sp["messaggi"] else: "manca")
  if sp != nil:
    rec("AC-210", "SenzaPulsante: Luce passa alla lampada",
      sp["passaggi"].len == 1 and sp["passaggi"][0]["parte"].getStr == "lampada" and sp["passaggi"][0]["csc"].getStr == "Luce", $sp["passaggi"])

# 080:6:2 AC-216: le composizioni della scheda, funzioni pure di edazioni, sui file della luce delle scale
block:
  let luce = root / "prove" / "f3" / "luce"
  proc caricaLuce(f: string): (string, JsonNode) = (readFile(luce / f), jsonDi(@["--dir", ".", f], luce))
  proc daTesto(t: string): JsonNode =
    ## check --json di un testo qualunque (scritto in una cartella a parte).
    let d = newWd0()
    writeFile(d / "x.csc", t)
    jsonDi(@["--dir", ".", "x.csc"], d)
  var err, idS: string
  # promessa nuova in un'entità che ne ha già una: la1 -> la2, dopo l'ultima promessa, VERIFY allineata sotto VERBAL
  block:
    let (raw, j) = caricaLuce("Lampada.csc")
    let r = aggiungiDich(raw, j, "ENTITY", "Lampada", Dich(genere: "promessa", frase: "Si spegne da sola", come: "INSPECTION", chi: "il registro"), err, idS)
    rec("AC-216", "promessa nuova: la2 dopo la1, VERIFY sotto VERBAL, il resto com'è",
      err == "" and idS == "la2" and r.splitLines() == (raw.replace("END\n", "  GUARANTEE la2: VERBAL \"Si spegne da sola\"\n" &
      "                 VERIFY BY INSPECTION \"il registro\"\nEND\n")).splitLines(), err & "\n" & r)
  # ipotesi nuova in una CSC che ha p1 e p-a1: p-a2, dopo l'ultima ipotesi
  block:
    let (raw, j) = caricaLuce("Pressione.csc")
    let r = aggiungiDich(raw, j, "CSC", "Pressione", Dich(genere: "ipotesi", frase: "Il pulsante non è guasto", come: "JUDGEMENT", chi: "l'operatore"), err, idS)
    rec("AC-216", "ipotesi nuova: p-a2 sotto p-a1, ASSUME allineata a GUARANTEE",
      err == "" and idS == "p-a2" and r.splitLines() == (raw.replace("END\n", "  ASSUME    p-a2: VERBAL \"Il pulsante non è guasto\"\n" &
      "                  VERIFY BY JUDGEMENT \"l'operatore\"\nEND\n")).splitLines(), err & "\n" & r)
  # senza promesse nel file: l'iniziale minuscola del nome (p1); l'ipotesi: p-a1
  block:
    let t = "CSC Pippo VERSION 0.1\n  PURPOSE \"x\"\n  EVENT IN a\nEND\n"
    let j = daTesto(t)
    let r1 = aggiungiDich(t, j, "CSC", "Pippo", Dich(genere: "promessa", frase: "F", come: "JUDGEMENT", chi: "C"), err, idS)
    rec("AC-216", "promessa nuova senza altre: id p1, prima di END", err == "" and idS == "p1" and r1.endsWith("  EVENT IN a\n  GUARANTEE p1: VERBAL \"F\"\n                VERIFY BY JUDGEMENT \"C\"\nEND\n"), r1)
    let r2 = aggiungiDich(r1, daTesto(r1), "CSC", "Pippo", Dich(genere: "ipotesi", frase: "F2", come: "INSPECTION", chi: "C2"), err, idS)
    rec("AC-216", "ipotesi nuova senza altre ipotesi: id p-a1", err == "" and idS == "p-a1" and r2.contains("  ASSUME    p-a1: VERBAL \"F2\"\n"), r2)
  # evento dopo l'ultimo evento; stato prima di END quando non ce n'è
  block:
    let (raw, j) = caricaLuce("Comando.csc")
    let r = aggiungiDich(raw, j, "CSC", "Comando", Dich(genere: "evento", id: "spegni", verso: "IN"), err, idS)
    rec("AC-216", "evento nuovo: dopo l'ultimo EVENT", err == "" and r.splitLines() == raw.replace("  EVENT OUT accendi\n", "  EVENT OUT accendi\n  EVENT IN spegni\n").splitLines(), err & r)
    let r2 = aggiungiDich(raw, j, "CSC", "Comando", Dich(genere: "stato", id: "durata", tipoDato: "Duration", valore: "60", unita: "s"), err, idS)
    rec("AC-216", "stato nuovo senza altri: prima di END", err == "" and r2.splitLines() == raw.replace("END\n", "  STATE durata : Duration INITIAL 60 s\nEND\n").splitLines(), err & r2)
    let (rawL, jL) = caricaLuce("Luce.csc")
    let r3 = aggiungiDich(rawL, jL, "CSC", "Luce", Dich(genere: "stato", id: "livello", tipoDato: "Integer", valore: "3"), err, idS)
    rec("AC-216", "stato nuovo: dopo l'ultimo STATE", err == "" and r3.splitLines() == rawL.replace("INITIAL false\n", "INITIAL false\n  STATE livello : Integer INITIAL 3\n").splitLines(), err & r3)
  # scopo; sostituzione di una promessa (id e rientro restano); togliere
  block:
    let (raw, j) = caricaLuce("Luce.csc")
    let r = cambiaScopo(raw, j, "CSC", "Luce", "La luce che si vede", err)
    rec("AC-216", "scopo cambiato: solo la riga PURPOSE", err == "" and r.splitLines()[1] == "  PURPOSE \"La luce che si vede\"" and
      r.splitLines().len == raw.splitLines().len and r.splitLines()[2 .. ^1] == raw.splitLines()[2 .. ^1] and r.splitLines()[0] == raw.splitLines()[0], r)
    let (rawP, jP) = caricaLuce("Pulsante.csc")
    let r2 = cambiaDich(rawP, jP, "ENTITY", "Pulsante", 5, "pu1", Dich(genere: "promessa", frase: "Ogni pressione accende", come: "JUDGEMENT", chi: "chi preme"), err)
    rec("AC-216", "promessa sostituita: id pu1 e rientro restano, due righe cambiate",
      err == "" and r2.splitLines() == (rawP.replace("\"A ogni pressione segue un accendi entro 0,1 s\"\n                 VERIFY BY INSPECTION \"pressioni e comandi registrati\"",
      "\"Ogni pressione accende\"\n                 VERIFY BY JUDGEMENT \"chi preme\"")).splitLines(), err & r2)
    let r3 = togliDich(rawP, jP, "ENTITY", "Pulsante", 5, "promessa", "pu1", err)
    rec("AC-216", "promessa tolta: le sue due righe se ne vanno", err == "" and r3.splitLines() == rawP.replace("  GUARANTEE pu1: VERBAL \"A ogni pressione segue un accendi entro 0,1 s\"\n                 VERIFY BY INSPECTION \"pressioni e comandi registrati\"\n", "").splitLines(), err & r3)
    let r4 = togliDich(rawP, jP, "ENTITY", "Pulsante", 4, "promessa", "pu1", err)
    rec("AC-216", "riga che non è più quella: rifiutato, niente testo", r4 == "" and err.len > 0, r4)
  # le righe che il modulo non conosce e il contratto
  block:
    let t = "CSC Canale VERSION 0.3\n  STATUS RATIFIED BY D-1\n  PURPOSE \"Un canale\"\n  CAPABILITY ricevi\n  EVENT OUT dato\n  GUARANTEE c1: VERBAL \"Ogni dato arriva una volta sola\"\n                VERIFY BY INSPECTION \"i dati registrati\"\n  -- un commento\n  GUARANTEE c2: VERBAL \"Su due\n    righe\"\n                VERIFY BY INSPECTION \"x\"\nEND\n"
    let j = daTesto(t)
    let b = bloccoDi(j, "CSC", "Canale")
    let note = dichiarazioniNote(j, b)
    var generi: seq[string]
    for d in note: generi.add d.genere & ":" & d.id & (if d.contratto: ":contratto" else: "")
    rec("AC-216", "le dichiarazioni note: scopo, evento e la promessa ratificata (contratto); CAPABILITY e la stringa su due righe no",
      generi == @["scopo:", "evento:dato", "promessa:c1:contratto", "promessa:c2:contratto"], $generi)
    let r = cambiaDich(t, j, "CSC", "Canale", 6, "c1", Dich(genere: "promessa", frase: "F", come: "JUDGEMENT", chi: "C"), err)
    rec("AC-216", "una promessa ratificata non si cambia dal modulo", r == "" and "contratto" in err, err)
    let tp = t.replace("  STATUS RATIFIED BY D-1\n", "").replace("  GUARANTEE c2", "  GUARANTEE c2 DETAILS c1")
    let jp = daTesto(tp)
    var g2: seq[string]
    for d in dichiarazioniNote(jp, bloccoDi(jp, "CSC", "Canale")): g2.add d.genere & ":" & d.id
    rec("AC-216", "senza STATUS: una promessa con DETAILS e una su più righe non sono conosciute", "promessa:c1" in g2 and "promessa:c2" notin g2, $g2)
  # i campi: frase, nome, valore
  block:
    let (raw, j) = caricaLuce("Comando.csc")
    discard aggiungiDich(raw, j, "CSC", "Comando", Dich(genere: "promessa", frase: "dice \"no\"", come: "JUDGEMENT", chi: "x"), err, idS)
    rec("AC-216", "frase con virgolette: rifiutata", err.len > 0, err)
    discard aggiungiDich(raw, j, "CSC", "Comando", Dich(genere: "promessa", frase: "a", come: "JUDGEMENT", chi: "riga\nsecond"), err, idS)
    rec("AC-216", "verifica su due righe: rifiutata", err.len > 0, err)
    discard aggiungiDich(raw, j, "CSC", "Comando", Dich(genere: "evento", id: "END", verso: "IN"), err, idS)
    rec("AC-216", "evento chiamato END (parola riservata): rifiutato", "riservata" in err, err)
    discard aggiungiDich(raw, j, "CSC", "Comando", Dich(genere: "evento", id: "accendi", verso: "IN"), err, idS)
    rec("AC-216", "evento con un nome già usato: rifiutato", "già" in err, err)
    discard aggiungiDich(raw, j, "CSC", "Comando", Dich(genere: "stato", id: "n", tipoDato: "Integer", valore: "tre"), err, idS)
    rec("AC-216", "stato Intero con valore «tre»: rifiutato", err.len > 0, err)
    discard aggiungiDich(raw, j, "CSC", "Comando", Dich(genere: "stato", id: "n", tipoDato: "Duration", valore: "5", unita: "min"), err, idS)
    rec("AC-216", "stato Durata con unità «min»: rifiutato", err.len > 0, err)
    let (rawE, jE) = caricaLuce("Lampada.csc")
    discard aggiungiDich(rawE, jE, "ENTITY", "Lampada", Dich(genere: "evento", id: "x", verso: "IN"), err, idS)
    rec("AC-216", "un'entità non ha eventi: rifiutato", err.len > 0, err)
  # ogni tipo di stato: scritto, riletto da check senza errori e riletto dal modulo con gli stessi valori
  block:
    var t = "CSC Giro VERSION 0.1\n  PURPOSE \"x\"\nEND\n"
    var ok = true
    var perche = ""
    for (nome, tipo, valore, unita) in [("a", "Boolean", "true", ""), ("b", "Integer", "42", ""), ("c", "Real", "0.5", ""),
        ("d", "String", "ciao come va", ""), ("e", "Duration", "250", "ms"), ("f", "String", "", "")]:
      let j = daTesto(t)
      let r = aggiungiDich(t, j, "CSC", "Giro", Dich(genere: "stato", id: nome, tipoDato: tipo, valore: valore, unita: unita), err, idS)
      if err.len > 0:
        ok = false
        perche &= nome & ": " & err & "\n"
        break
      t = r
    let j = daTesto(t)
    var riletti: seq[string]
    for d in dichiarazioniNote(j, bloccoDi(j, "CSC", "Giro")):
      if d.genere == "stato": riletti.add d.id & "/" & d.tipoDato & "/" & d.valore & "/" & d.unita
    rec("AC-216", "sei stati dei cinque tipi: scritti, e riletti con gli stessi valori",
      ok and riletti == @["a/Boolean/true/", "b/Integer/42/", "c/Real/0.5/", "d/String/ciao come va/", "e/Duration/250/ms", "f/String//"], perche & $riletti)
    rec("AC-216", "il risultato passa `bcdd check` senza errori", j["rapporto"]["errori"].len == 0, $j["rapporto"]["errori"])

# 080:6:3 AC-220 e AC-221: la casella di testo e Nuova versione, funzioni pure e modello
block:
  let luce = root / "prove" / "f3" / "luce"
  let ratDir = root / "prove" / "f3b" / "ratify"
  var err = ""
  let raw = readFile(luce / "Luce.csc")
  let rl = raw.splitLines()
  # AC-220: sostituisciTesto
  let r1 = sostituisciTesto(raw, 1, 1, "CSC Luce VERSION 0.1", "CSC Luce VERSION 0.2", err)
  rec("AC-220", "versione nell'intestazione: cambia solo la riga 1", err == "" and r1 == raw.replace("CSC Luce VERSION 0.1", "CSC Luce VERSION 0.2"), err & r1)
  let rawC = raw.replace("\n", "\r\n")
  let r2 = sostituisciTesto(rawC, 1, 1, "CSC Luce VERSION 0.1", "CSC Luce VERSION 0.3", err)
  rec("AC-220", "file con CRLF: la riga nuova ha CRLF, il resto uguale", err == "" and r2 == rawC.replace("CSC Luce VERSION 0.1", "CSC Luce VERSION 0.3"), err)
  let r3 = sostituisciTesto(raw, 3, 3, rl[2], "", err)
  rec("AC-220", "casella vuota: la riga se ne va, il resto uguale", err == "" and r3.splitLines() == rl[0 .. 1] & rl[3 .. ^1], err & r3)
  let r4 = sostituisciTesto(raw, 3, 3, rl[2], "  STATE accesa : Boolean INITIAL false\n  STATE spenta : Boolean INITIAL true\n", err)
  rec("AC-220", "una riga diventa due (il fine riga in fondo non fa una riga vuota)",
    err == "" and r4.splitLines() == rl[0 .. 2] & @["  STATE spenta : Boolean INITIAL true"] & rl[3 .. ^1], err & r4)
  err = ""
  let r5 = sostituisciTesto(raw, 1, 1, "CSC Altra VERSION 0.1", "CSC Altra VERSION 0.2", err)
  rec("AC-220", "righe non più quelle che la persona aveva davanti: rifiutato, niente testo", r5 == "" and "cambiate nel frattempo" in err, err)
  err = ""
  let r6 = sostituisciTesto(raw, 1, 99, rl[0], "x", err)
  rec("AC-220", "righe che non ci sono: rifiutato", r6 == "" and err.len > 0, err)
  # AC-220: il modello dà a ogni riga la sua dichiarazione
  block:
    let j16 = jsonDi(@["--dir", ".", "16_scenario.csc"], root / "prove")
    let m = buildBanco("p", @[("16_scenario.csc", j16)])
    var ranges: Table[int, (int, int)]
    for r in m["csc"][0]["scheda"]["righe"]:
      if r.hasKey("ca"): ranges[r["n"].getInt] = (r["ca"].getInt, r["cb"].getInt)
    rec("AC-220", "la casella: CAPABILITY la sua riga; uno SCENARIO arriva fino ai suoi passi; l'intestazione approvata del connettore non ha casella (D-236)",
      not ranges.hasKey(4) and ranges.getOrDefault(8) == (8, 8) and ranges.getOrDefault(26) == (26, 30) and ranges.getOrDefault(28) == (26, 30), $ranges)
    rec("AC-220", "la riga END non apre la casella", not ranges.hasKey(m["csc"][0]["scheda"]["righe"][m["csc"][0]["scheda"]["righe"].len - 1]["n"].getInt), "")
  block:
    let jl = jsonDi(@["--dir", ".", "LuceScale.csc"], luce)
    let m = buildBanco("l", @[("LuceScale.csc", jl)])
    var ranges: Table[int, (int, int)]
    for r in m["entita"][0]["scheda"]["righe"]:
      if r.hasKey("ca"): ranges[r["n"].getInt] = (r["ca"].getInt, r["cb"].getInt)
    rec("AC-220", "COMPOSED OF e le sue parti sono una sola dichiarazione; l'intestazione di un'entità è la sua riga sola", ranges.getOrDefault(1) == (1, 1) and ranges.getOrDefault(5) == (5, 7) and ranges.getOrDefault(7) == (5, 7), $ranges)
  # AC-221: numeri, composizione, errori
  rec("AC-221", "il numero proposto: 0.1 -> 0.2, 1.9 -> 1.10, 2 -> 3, 0.1.2 -> 0.1.3; un numero non puntato non ne ha",
    versioneSuccessiva("0.1") == "0.2" and versioneSuccessiva("1.9") == "1.10" and versioneSuccessiva("2") == "3" and
    versioneSuccessiva("0.1.2") == "0.1.3" and versioneSuccessiva("v1") == "" and not versioneValida("0..1") and not versioneValida("1."), "")
  let dR = newWd0()
  copyFile(luce / "Luce.csc", dR / "Luce.csc")
  discard runExe(bcddProva, @["ratify", "Luce.csc", "D-1"], dR)
  let rawR = readFile(dR / "Luce.csc")
  let jR = jsonDi(@["--dir", ".", "Luce.csc"], dR)
  let attesaR = "-- VERSION 0.2: Anche a metà\n" & rawR.replace("VERSION 0.1", "VERSION 0.2").replace("STATUS RATIFIED BY D-1", "STATUS HYPOTHESIS")
  err = ""
  let v1 = nuovaVersione(rawR, jR, "CSC", "Luce", "0.2", "Anche a metà", @[], err)
  rec("AC-221", "connettore approvato: commento sopra l'intestazione, numero nuovo, STATUS HYPOTHESIS, il resto uguale", err == "" and v1 == attesaR and "RATIFIED" in rawR, err & v1)
  let dV = newWd0()
  writeFile(dV / "Luce.csc", v1)
  let chk = runExe(bcdd, @["check", "--dir", ".", "Luce.csc"], dV)
  rec("AC-221", "il risultato passa `bcdd check` senza errori", chk.code == 0 and "esito: nessun errore" in chk.output, cut(chk.output))
  for (num, frase, quale) in [("0.1", "x", "numero uguale"), ("0..2", "x", "numero malformato"), ("0.2", "  ", "frase vuota"), ("0.2", "a\nb", "frase su due righe")]:
    err = ""
    let r = nuovaVersione(rawR, jR, "CSC", "Luce", num, frase, @[], err)
    rec("AC-221", quale & ": rifiutato, niente testo", r == "" and err.len > 0, err)
  err = ""
  let rId = nuovaVersione(rawR, jR, "CSC", "Luce", "0.2", "x", @["l1"], err)
  rec("AC-221", "una riga che non ha una sua decisione (l1 è contratto per l'intestazione): rifiutato", rId == "" and err.len > 0, err)
  # un'entità con una riga approvata con una sua decisione
  let rawE = readFile(ratDir / "Due.a1.dopo.csc")
  let jE = jsonDi(@["--dir", ".", "Due.a1.dopo.csc"], ratDir)
  err = ""
  let e0 = nuovaVersione(rawE, jE, "ENTITY", "Altra", "0.2", "x", @[], err)
  rec("AC-221", "entità, nessuna riga scelta: solo commento e numero; a1 resta approvata",
    err == "" and e0 == rawE.replace("ENTITY Altra VERSION 0.1", "-- VERSION 0.2: x\nENTITY Altra VERSION 0.2"), err & e0)
  let e1 = nuovaVersione(rawE, jE, "ENTITY", "Altra", "0.2", "x", @["a1"], err)
  rec("AC-221", "entità, a1 scelta: a1 torna STATUS HYPOTHESIS",
    err == "" and e1 == rawE.replace("ENTITY Altra VERSION 0.1", "-- VERSION 0.2: x\nENTITY Altra VERSION 0.2").replace("a1 STATUS RATIFIED BY D-1:", "a1 STATUS HYPOTHESIS:"), err & e1)
  # il modello: il bottone c'è dove serve, con l'elenco; la scheda sa che la versione è nuova
  let mR = buildBanco("r", @[("Luce.csc", jR)])
  let nvR = mR["csc"][0]["scheda"]["nv"]
  rec("AC-221", "il modello: connettore approvato ha nv (proposta 0.2, intestazione sì, elenco vuoto); non è ancora una versione nuova",
    nvR.kind == JObject and nvR["proposta"].getStr == "0.2" and nvR["intestazione"].getBool and nvR["righe"].len == 0 and not mR["csc"][0]["scheda"]["versione_nuova"].getBool, $nvR)
  let jVn = jsonDi(@["--dir", ".", "Luce.csc"], dV)
  let mV = buildBanco("v", @[("Luce.csc", jVn)])
  rec("AC-221", "il modello: dopo Nuova versione il bottone non c'è e la scheda dice «nuova versione»",
    mV["csc"][0]["scheda"]["nv"].kind == JNull and mV["csc"][0]["scheda"]["versione_nuova"].getBool, "")
  let mE = buildBanco("e", @[("Due.a1.dopo.csc", jE)])
  var nvE: JsonNode
  for e in mE["entita"]:
    if e["nome"].getStr == "Altra": nvE = e["scheda"]["nv"]
  rec("AC-221", "il modello: l'entità con a1 approvata ha il bottone, e a1 è nell'elenco", nvE != nil and nvE.kind == JObject and nvE["righe"].len == 1 and nvE["righe"][0]["id"].getStr == "a1" and not nvE["intestazione"].getBool, $nvE)
  # la forma `GUARANTEE l1 STATUS HYPOTHESIS:` che Nuova versione lascia alla riga rimessa da approvare si cambia ancora con il modulo
  block:
    let txt = rawR.replace("STATUS RATIFIED BY D-1\n  PURPOSE", "STATUS HYPOTHESIS\n  PURPOSE").replace("GUARANTEE l1:", "GUARANTEE l1 STATUS RATIFIED BY D-9:")
    let dd = newWd0()
    writeFile(dd / "x.csc", txt)
    err = ""
    let t3 = nuovaVersione(txt, jsonDi(@["--dir", ".", "x.csc"], dd), "CSC", "Luce", "0.2", "y", @["l1"], err)
    let dd2 = newWd0()
    writeFile(dd2 / "x.csc", t3)
    let jt = jsonDi(@["--dir", ".", "x.csc"], dd2)
    var trovata = false
    for d in dichiarazioniNote(jt, bloccoDi(jt, "CSC", "Luce")):
      if d.genere == "promessa" and d.id == "l1" and not d.contratto: trovata = true
    rec("AC-221", "la riga rimessa da approvare (`GUARANTEE l1 STATUS HYPOTHESIS:`) il modulo la conosce", err == "" and "l1 STATUS HYPOTHESIS:" in t3 and trovata, err & t3)

# 080:6:4 AC-222: la scelta grafica e la memoria dei check (P5), funzioni pure di edbcdd
block:
  # i display: ssh -X e -Y danno host:N, il locale è :N
  rec("AC-222", "display di rete (localhost:10.0, 192.168.1.5:0, host:0) = remoto", displayRemoto("localhost:10.0") and displayRemoto("192.168.1.5:0") and displayRemoto("host:0"), "")
  rec("AC-222", "display locale (:0, :77.0, unix:0, vuoto) = non remoto", not displayRemoto(":0") and not displayRemoto(":77.0") and not displayRemoto("unix:0") and not displayRemoto(""), "")
  let casi = [
    # (WEBKIT_DISABLE_COMPOSITING_MODE, BCDD_EDITOR_COMPOSITING, DISPLAY) -> (politica, remoto)
    (("", "", ":0"), (pgSpenta, false)),                      # locale: composizione spenta
    (("", "", "localhost:10.0"), (pgPredefinita, true)),      # ssh: la composizione resta com'è (accesa)
    (("", "", ""), (pgSpenta, false)),                        # senza display: locale
    (("1", "", ":0"), (pgPredefinita, false)),                # la variabile di WebKit nell'ambiente: non si tocca niente
    (("1", "off", "localhost:10.0"), (pgPredefinita, true)),  # ... e vince su tutto
    (("0", "on", ":0"), (pgPredefinita, false)),              # anche «0»: è presente, decide chi l'ha messa
    (("", "on", ":0"), (pgAccesa, false)),                    # la variabile dell'editor vince sulla rilevazione
    (("", "off", "localhost:10.0"), (pgSpenta, true)),
    (("", "ON", ":0"), (pgAccesa, false)),                    # maiuscole ammesse
    (("", "auto", "localhost:10.0"), (pgPredefinita, true)),
    (("", "auto", ":0"), (pgSpenta, false)),
    (("", "boh", ":0"), (pgSpenta, false)),                   # un valore sconosciuto vale auto
    (("", "boh", "localhost:10.0"), (pgPredefinita, true))]
  var sbagliati: seq[string]
  for (ing, att) in casi:
    let r = sceltaGrafica(ing[0], ing[1], ing[2])
    if (r.politica, r.remoto) != att: sbagliati.add $ing & " -> " & $(r.politica, r.remoto) & " invece di " & $att
  rec("AC-222", "la tabella delle precedenze: variabile WebKit, poi BCDD_EDITOR_COMPOSITING, poi il display (13 casi)", sbagliati.len == 0, sbagliati.join("; "))
  rec("AC-225", "metodo di input: xim senza server XIM passa al contesto semplice, il resto non si tocca",
    metodoInput("xim", "@im=none") == "gtk-im-context-simple" and metodoInput("xim", "") == "gtk-im-context-simple" and
    metodoInput("xim", "@im=ibus") == "" and metodoInput("ibus", "@im=none") == "" and metodoInput("", "@im=none") == "", "")
  # la memoria dei check: mai un risultato più vecchio della cartella
  var m: MemoCheck
  let j1 = %*{"v": 1}
  let j2 = %*{"v": 2}
  rec("AC-223", "memoria vuota: niente", m.daMemoria("D1", "A.csc") == nil, "")
  m.ricorda("D1", "D1", "A.csc", j1)
  rec("AC-223", "stessa cartella: il check si ritrova", m.daMemoria("D1", "A.csc") == j1 and m.daMemoria("D1", "B.csc") == nil, "")
  rec("AC-223", "la cartella è cambiata (un'altra impronta): niente, e la memoria è vuota", m.daMemoria("D2", "A.csc") == nil and m.voci.len == 0, "")
  m.ricorda("D2", "D3", "A.csc", j2)
  rec("AC-223", "la cartella è cambiata mentre bcdd lavorava: il risultato non si ricorda", m.daMemoria("D2", "A.csc") == nil and m.daMemoria("D3", "A.csc") == nil, "")
  m.ricorda("D3", "D3", "A.csc", j2)
  rec("AC-223", "dopo un'altra scrittura e il ritorno alla cartella di prima (come «Torna indietro») il vecchio risultato non c'è più",
    m.daMemoria("D3", "A.csc") == j2 and m.daMemoria("D1", "A.csc") == nil, "")
  m.ricorda("D9", "D9", "A.csc", j1)
  rec("AC-223", "un'impronta mai letta non entra nella memoria di un'altra", m.daMemoria("D3", "A.csc") == nil and m.voci.len == 0, "")

# 080:7:1 Con la finestra
const
  luceScaleAttesa = "ENTITY LuceScale VERSION 0.1\n  PURPOSE \"La luce delle scale\"\n  OFFERS Pressione\n  OFFERS Luce\n  COMPOSED OF\n    pulsante : Pulsante\n    lampada : Lampada\nEND\n"
  pulsanteAttesa = "ENTITY Pulsante VERSION 0.1\n  PURPOSE \"Il pulsante di un piano\"\n  OFFERS Pressione\n  OFFERS Comando\nEND\n"
  lampadaAttesa = "ENTITY Lampada VERSION 0.1\n  PURPOSE \"La lampada delle scale\"\n  OFFERS Luce\n  USES Comando\nEND\n"
  clicLuce = "@b-nuova|=f-nome:LuceScale|=f-scopo:La luce delle scale|@f-ok|" &
    "@b-pubblico|=f-csc:Pressione|=f-lato:OFFERS|@f-ok|@b-pubblico|=f-csc:Luce|=f-lato:OFFERS|@f-ok|@b-scomponi|" &
    "@b-parte|=f-parte:pulsante|=f-tipo:|=f-nuova:Pulsante|=f-scopo:Il pulsante di un piano|@f-ok|" &
    "@b-parte|=f-parte:lampada|=f-tipo:|=f-nuova:Lampada|=f-scopo:La lampada delle scale|@f-ok|" &
    "@b-passa|=f-passa:OFFERS Pressione|=f-parte:pulsante|@f-ok|@b-passa|=f-passa:OFFERS Luce|=f-parte:lampada|@f-ok|" &
    "@b-connettore|=f-csc:Comando|=f-offre:pulsante|=f-usa:lampada|@f-ok"

proc apriEPronto(s: var Sess, args: seq[string], cwd: string, extra: seq[(string, string)] = @[]): bool =
  s.avviaEditor(args, cwd, extra)
  attendi(s.trace, "pagina 1", 20)

if not xvfbOk:
  for ac in ["AC-211", "AC-212", "AC-213", "AC-215", "AC-217", "AC-218", "AC-219", "AC-220", "AC-221", "AC-222", "AC-223", "AC-224", "AC-196"]: senzaXvfb(ac, "sessione con Xvfb")
else:
  # --- AC-211: la luce delle scale costruita da una cartella vuota, con i clic
  block:
    let d = newWd0()
    var s = nuovaSessione()
    s.avviaEditor(@["--dir", d], root, @[("BCDD_EDITOR_PROVA_CLIC", clicLuce)])
    let fine = attendi(s.trace, "pagina 9", 40)
    rec("AC-211", "i nove disegni (apertura e otto azioni)", fine, cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 600))
    sleep(300)
    raccogli(s)
    proc righeDi(f: string): seq[string] = leggiSe(d / f).splitLines()
    rec("AC-211", "LuceScale.csc riga per riga", righeDi("LuceScale.csc") == luceScaleAttesa.splitLines(), leggiSe(d / "LuceScale.csc"))
    rec("AC-211", "Pulsante.csc riga per riga", righeDi("Pulsante.csc") == pulsanteAttesa.splitLines(), leggiSe(d / "Pulsante.csc"))
    rec("AC-211", "Lampada.csc riga per riga", righeDi("Lampada.csc") == lampadaAttesa.splitLines(), leggiSe(d / "Lampada.csc"))
    let rif = newWd0()
    for n in ["Pressione", "Luce", "Comando"]:
      discard runExe(bcdd, @["new", n], rif)
      rec("AC-211", n & ".csc è quello di `bcdd new " & n & "`", leggiSe(d / (n & ".csc")) == leggiSe(rif / (n & ".csc")) and fileExists(d / (n & ".csc")), "")
    var nomi: seq[string]
    for f in walkFiles(d / "*"): (if not f.endsWith(".prima"): nomi.add f.extractFilename)
    nomi.sort()
    rec("AC-211", "nella cartella solo i sei file attesi", nomi == @["Comando.csc", "Lampada.csc", "Luce.csc", "LuceScale.csc", "Pressione.csc", "Pulsante.csc"], $nomi)
    let pag = paginaN(s, 9)
    rec("AC-211", "alla fine lo stato è «Chiusa»", "stato: Chiusa" in pag, cut(pag[max(0, pag.len - 300) .. ^1]))
    let chk = runExe(bcdd, @["check", "--dir", ".", "LuceScale.csc"], d)
    rec("AC-211", "bcdd check sul risultato: nessun errore", chk.code == 0 and "esito: nessun errore" in chk.output, cut(chk.output))
    s.finisci()

  # --- AC-212: nessuna scrittura senza azione, e la rilettura quando la finestra torna attiva
  block:
    let d = copiaCartella(root / "prove" / "f3" / "luce")
    var s = nuovaSessione()
    let pronto = apriEPronto(s, @["--dir", d, "LuceScale"], root)
    rec("AC-212", "la finestra si apre", pronto, cut(leggiSe(s.dir / "errori")))
    if pronto:
      let w = trovaFinestra(display, "bcdd-editor")
      let prima = fotografia(d)
      sleep(1500)
      let pag1 = paginaN(s, 1)
      rec("AC-212", "la pagina mostra LuceScale e lo stato «Chiusa»", "LuceScale" in pag1 and "stato: Chiusa" in pag1, cut(pag1[max(0, pag1.len - 200) .. ^1]))
      focusAltrove(display, w)
      sleep(800)
      rec("AC-212", "fuori e ritorno senza cambiamenti: nessun disegno nuovo e «nessun cambiamento»",
        nDisegni(s) == 1 and attendi(s.trace, "controllato", 5), $nDisegni(s))
      rec("AC-212", "nessuna scrittura: file, contenuti e date di modifica uguali, nessun file nuovo", fotografia(d) == prima, "cartella cambiata")
      let nuovoTesto = leggiSe(d / "LuceScale.csc").replace("La luce delle scale", "La luce dei corridoi")
      writeFile(d / "LuceScale.csc", nuovoTesto)
      let dopoModifica = fotografia(d)
      focusAltrove(display, w)
      let ridisegnata = attendi(s.trace, "pagina 2", 10)
      rec("AC-212", "il file cambiato fuori: al ritorno la pagina si ridisegna col testo nuovo", ridisegnata and "La luce dei corridoi" in paginaN(s, 2), cut(paginaN(s, 2)))
      rec("AC-212", "la rilettura non scrive niente", fotografia(d) == dopoModifica, "cartella cambiata")
      raccogli(s)
      rec("AC-212", "nei lanci solo check (nessun save, nessun new senza un'azione)", azioniLanci(s).allIt(it == "check") and nLanci(s) >= 8, $azioniLanci(s))
    s.finisci()

  # --- AC-213: un'azione rifiutata non scrive niente e lo dice; il tema
  block:
    let d = copiaCartella(root / "prove" / "f3" / "luce")
    let prima = fotografia(d)
    var s = nuovaSessione()
    s.avviaEditor(@["--dir", d, "LuceScale"], root, @[("BCDD_EDITOR_PROVA_CLIC",
      "@b-nuova|=f-nome:Lampada|=f-scopo:duplicata|@f-ok|@b-tema|@b-nuova|=f-nome:Nuova1|=f-scopo:una prova|@f-ok")])
    let fine = attendi(s.trace, "pagina 3", 30)
    rec("AC-213", "tre disegni", fine, cut(leggiSe(s.dir / "errori")) & cut(leggiSe(s.trace), 500))
    let pag2 = paginaN(s, 2)
    rec("AC-213", "il nome già usato: «Non riuscito» e il messaggio", "Non riuscito" in pag2 and "è già usato" in pag2, cut(pag2[max(0, pag2.len - 300) .. ^1]))
    raccogli(s)
    rec("AC-213", "nessun save per l'azione rifiutata: un solo save, quello della seconda", azioniLanci(s).count("save") == 1, $azioniLanci(s))
    var attesa = prima
    attesa["Nuova1.csc"] = ("ENTITY Nuova1 VERSION 0.1\n  PURPOSE \"una prova\"\nEND\n", fromUnix(0))
    let dopo = fotografia(d)
    var uguali = dopo.len == attesa.len
    for k, v in attesa:
      if k notin dopo: uguali = false
      elif k == "Nuova1.csc": uguali = uguali and dopo[k][0] == v[0]
      else: uguali = uguali and dopo[k] == v
    rec("AC-213", "Lampada.csc e gli altri uguali; Nuova1.csc è l'unico file nuovo, col testo atteso", uguali, $toSeq(dopo.keys))
    let pag3 = paginaN(s, 3)
    rec("AC-213", "il tema: dopo il clic sull'interruttore la pagina è nel tema giorno", "tema=tema-giorno" in pag3, cut(pag3[max(0, pag3.len - 120) .. ^1]))
    rec("AC-213", "all'avvio il tema è notte", "tema=tema-notte" in paginaN(s, 2), cut(pag2[max(0, pag2.len - 120) .. ^1]))
    s.finisci()

  # --- AC-248: un nome che su Windows indica un dispositivo non crea una CSC, su nessun sistema (come `bcdd new`)
  block:
    let d = copiaCartella(root / "prove" / "f3" / "luce")
    let prima = fotografia(d)
    var s = nuovaSessione()
    s.avviaEditor(@["--dir", d, "LuceScale"], root, @[("BCDD_EDITOR_PROVA_CLIC", "@b-nuova|=f-nome:Con|=f-scopo:una prova|@f-ok")])
    let fine = attendi(s.trace, "pagina 2", 30)
    let p2 = paginaN(s, 2)
    rec("AC-248", "nuova entità «Con»: rifiutata con il messaggio del dispositivo", fine and "Non riuscito" in p2 and "Windows lo riserva per sé" in p2, cut(p2[max(0, p2.len - 300) .. ^1]))
    raccogli(s)
    rec("AC-248", "nessun save e la cartella identica", azioniLanci(s).count("save") == 0 and fotografia(d) == prima, $azioniLanci(s))
    s.finisci()

  # --- AC-224: collegare due entità libere: l'elenco con i lati, «Collega a…» con una e con due righe, i rifiuti, Annulla
  block:
    let luce = root / "prove" / "f3" / "luce"
    let lampada0 = readFile(luce / "Lampada.csc")
    let pulsante0 = readFile(luce / "Pulsante.csc")
    proc sess(entita, clic: string, attesa: string): (string, Sess, Table[string, (string, Time)]) =
      let d = copiaCartella(luce)
      let prima = fotografia(d)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, entita], root, @[("BCDD_EDITOR_PROVA_CLIC", clic)])
      discard attendi(s.trace, attesa, 30)
      sleep(300)
      raccogli(s)
      (d, s, prima)
    # una riga: Pulsante si collega a Lampada con Luce (di Lampada, che offre): Pulsante prende USES Luce, nient'altro cambia
    block:
      var (d, s, prima) = sess("Pulsante", "@b-collega|=f-altra:Lampada|=f-conn:b:OFFERS:Luce|@f-ok|@f-ok", "pagina 2")
      let nuovo = pulsante0.replace("  OFFERS Comando\n", "  OFFERS Comando\n  USES Luce\n")
      rec("AC-224", "Collega a… con una riga: solo Pulsante.csc cambia (USES Luce), riga per riga",
        nuovo != pulsante0 and readFile(d / "Pulsante.csc").splitLines() == nuovo.splitLines() and readFile(d / "Lampada.csc") == lampada0 and not fileExists(d / "Luce.csc.prima"), readFile(d / "Pulsante.csc"))
      rec("AC-224", "un solo save, nessun new", azioniLanci(s).count("save") == 1 and azioniLanci(s).count("new") == 0, $azioniLanci(s))
      s.finisci()
    # due righe e CSC nuova: Allarme lo offre Lampada, lo usa Pulsante; bcdd new, due save; poi Annulla riporta i due file, Allarme.csc resta
    block:
      let clic = "@b-collega|=f-altra:Lampada|=f-conn:|=f-csc:Allarme|=f-chi:Lampada|@f-ok|@f-ok"
      var (d, s, prima) = sess("Pulsante", clic, "pagina 2")
      let lamp = lampada0.replace("  OFFERS Luce\n", "  OFFERS Luce\n  OFFERS Allarme\n")
      let puls = pulsante0.replace("  OFFERS Comando\n", "  OFFERS Comando\n  USES Allarme\n")
      let rif = newWd0()
      discard runExe(bcdd, @["new", "Allarme"], rif)
      rec("AC-224", "Collega a… con due righe: OFFERS Allarme in Lampada, USES Allarme in Pulsante, riga per riga",
        readFile(d / "Lampada.csc").splitLines() == lamp.splitLines() and readFile(d / "Pulsante.csc").splitLines() == puls.splitLines(), readFile(d / "Lampada.csc") & readFile(d / "Pulsante.csc"))
      rec("AC-224", "Allarme.csc è quello di `bcdd new Allarme`; azioni: new e due save", leggiSe(d / "Allarme.csc") == leggiSe(rif / "Allarme.csc") and fileExists(d / "Allarme.csc") and
        azioniLanci(s).count("new") == 1 and azioniLanci(s).count("save") == 2, $azioniLanci(s))
      s.finisci()
      var (d2, s2, prima2) = sess("Pulsante", clic & "|@b-annulla|@f-ok", "pagina 3")
      rec("AC-224", "Annulla copre i due file: Lampada.csc e Pulsante.csc come prima, Allarme.csc resta",
        readFile(d2 / "Lampada.csc") == lampada0 and readFile(d2 / "Pulsante.csc") == pulsante0 and fileExists(d2 / "Allarme.csc") and azioniLanci(s2).count("save") == 4, $azioniLanci(s2))
      s2.finisci()
    # lato uguale e già collegate: nessuna conferma, il messaggio nel modulo, nessuna scrittura
    block:
      var (d, s, prima) = sess("Pulsante", "@b-collega|=f-altra:LuceScale|=f-conn:a:OFFERS:Pressione|@f-ok|?f-err|=f-altra:Lampada|=f-conn:a:OFFERS:Comando|@f-ok|?f-err", "sonda Q:f-err")
      sleep(800)
      raccogli(s)
      let sonde = leggiSe(s.trace).splitLines().filterIt("sonda Q:" in it).mapIt(it[it.find("sonda Q:") + 8 .. ^1])
      rec("AC-224", "stesso lato: «LuceScale offre già Pressione: due entità che offrono non si collegano»", sonde.len >= 1 and "LuceScale offre già Pressione: due entità che offrono non si collegano" in sonde[0], $sonde)
      rec("AC-224", "già collegate: lo dice e non scrive", sonde.len >= 2 and "Pulsante e Lampada sono già collegate su Comando" in sonde[^1], $sonde)
      rec("AC-224", "nessuna scrittura: file uguali, nessun save né new", fotografia(d) == prima and azioniLanci(s).count("save") == 0 and azioniLanci(s).count("new") == 0, $azioniLanci(s))
      s.finisci()
    # l'elenco in «+ Connettore pubblico»: chi offre e chi usa; scegliere Luce propone «Usa» e scrive USES Luce
    block:
      var (d, s, prima) = sess("Pulsante", "@b-pubblico|?f-el-Luce|?f-el-Comando|?f-el-Pressione|@f-el-Luce|!f-csc|@f-ok", "pagina 2")
      let sonde = leggiSe(s.trace).splitLines().filterIt("sonda Q:" in it).mapIt(it[it.find("sonda Q:") + 8 .. ^1])
      rec("AC-224", "l'elenco dice chi offre e chi usa",
        sonde.len >= 4 and "Luce: offerto da DaFuori, Lampada, LuceScale, SenzaPulsante, nessuno lo usa" in sonde[0] and "Comando: offerto da Pulsante, usato da DaFuori, Lampada" in sonde[1] and
        "Pressione: offerto da LuceScale, Pulsante, nessuno lo usa" in sonde[2] and "valore=Luce" in sonde[3], $sonde)
      let nuovo = pulsante0.replace("  OFFERS Comando\n", "  OFFERS Comando\n  USES Luce\n")
      rec("AC-224", "scegliere Luce propone il lato che manca: Pulsante.csc ha USES Luce", readFile(d / "Pulsante.csc").splitLines() == nuovo.splitLines(), readFile(d / "Pulsante.csc"))
      s.finisci()

  # --- AC-215: togliere e annullare: una prova per azione, sui file attesi riga per riga
  block:
    let luce = root / "prove" / "f3" / "luce"
    let lampada0 = readFile(luce / "Lampada.csc")
    let pulsante0 = readFile(luce / "Pulsante.csc")
    let luceScale0 = readFile(luce / "LuceScale.csc")
    proc cartellaSolo(d: string, prima: Table[string, (string, Time)], cambi: seq[(string, string)]): (bool, string) =
      ## Gli stessi file di prima, nessuno cancellato né nuovo; quelli in `cambi` riga per riga come attesi, gli altri com'erano.
      var nomi: seq[string]
      for f in walkFiles(d / "*"): (if not f.endsWith(".prima"): nomi.add f.extractFilename)
      nomi.sort()
      var nomiPrima = toSeq(prima.keys)
      nomiPrima.sort()
      if nomi != nomiPrima: return (false, "file: " & $nomi)
      for n in nomi:
        var atteso = prima[n][0]
        for (f, x) in cambi:
          if f == n: atteso = x
        if readFile(d / n).splitLines() != atteso.splitLines(): return (false, n & ":\n" & readFile(d / n))
      (true, "")
    proc sessione(clic: string, disegni: int, fermo: string = ""): (string, Sess, Table[string, (string, Time)]) =
      let d = copiaCartella(luce)
      let prima = fotografia(d)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "LuceScale"], root, @[("BCDD_EDITOR_PROVA_CLIC", clic)])
      discard attendi(s.trace, "pagina " & $disegni, 30)
      sleep(300)
      raccogli(s)
      (d, s, prima)

    # Scollega un passaggio al bordo: Luce da lampada
    block:
      var (d, s, prima) = sessione("@t-dentro|#pas-Luce-lampada|@b-togli|@f-ok", 2)
      let (ok, perche) = cartellaSolo(d, prima, @[("Lampada.csc", lampada0.replace("  OFFERS Luce\n", ""))])
      rec("AC-215", "Scollega un passaggio: Lampada.csc senza OFFERS Luce, nient'altro cambia, nessun file cancellato", ok, perche)
      let pag = paginaN(s, 2)
      rec("AC-215", "dopo lo scollegamento la luce non è più mantenuta: stato «Non chiusa»", "stato: Non chiusa" in pag and "Scritti i file: Lampada.csc" in pag, cut(pag[max(0, pag.len - 300) .. ^1]))
      s.finisci()
    # Scollega un accoppiamento fra due parti: Comando da pulsante a lampada
    block:
      var (d, s, prima) = sessione("@t-dentro|#acc-Comando|@b-togli|@f-ok", 2)
      let (ok, perche) = cartellaSolo(d, prima, @[("Pulsante.csc", pulsante0.replace("  OFFERS Comando\n", "")),
        ("Lampada.csc", lampada0.replace("  USES   Comando\n", ""))])
      rec("AC-215", "Scollega un accoppiamento: OFFERS Comando via da Pulsante e USES Comando via da Lampada, Comando.csc resta", ok, perche)
      s.finisci()
    # Togli parte, due volte: alla seconda se ne va anche COMPOSED OF
    block:
      var (d, s, prima) = sessione("@t-dentro|#p-lampada|@b-togli|@f-ok|@t-dentro|#p-pulsante|@b-togli|@f-ok", 3)
      let senzaLampada = luceScale0.replace("    lampada  : Lampada\n", "")
      let senzaParti = senzaLampada.replace("  COMPOSED OF\n    pulsante : Pulsante\n", "")
      let (ok, perche) = cartellaSolo(d, prima, @[("LuceScale.csc", senzaParti)])
      rec("AC-215", "Togli parte: via lampada, poi via pulsante e COMPOSED OF; Lampada.csc e Pulsante.csc restano", ok and senzaParti != senzaLampada and senzaLampada != luceScale0, perche)
      s.finisci()
    # Togli connettore pubblico dalla scatola da fuori
    block:
      var (d, s, prima) = sessione("#c-Luce|@b-togli|@f-ok", 2)
      let (ok, perche) = cartellaSolo(d, prima, @[("LuceScale.csc", luceScale0.replace("  OFFERS Luce\n", ""))])
      rec("AC-215", "Togli connettore pubblico: LuceScale.csc senza OFFERS Luce, Luce.csc resta", ok, perche)
      s.finisci()
    # Annulla l'ultima azione: la cartella torna com'era
    block:
      var (d, s, prima) = sessione("@t-dentro|#p-lampada|@b-togli|@f-ok|@b-annulla|@f-ok", 3)
      let (ok, perche) = cartellaSolo(d, prima, @[])
      rec("AC-215", "Annulla: dopo «togli parte» e «annulla» tutti i file sono com'erano, riga per riga", ok, perche)
      let pag = paginaN(s, 3)
      rec("AC-215", "l'annullamento riesce e lo dice", "Scritti i file: LuceScale.csc" in pag and "Non riuscito" notin pag, cut(pag[max(0, pag.len - 300) .. ^1]))
      rec("AC-215", "due save (l'azione e il suo annullamento) e nessun altro sottocomando di scrittura", azioniLanci(s).count("save") == 2 and azioniLanci(s).count("new") == 0, $azioniLanci(s))
      s.finisci()
    # Annulla non annulla se un file è cambiato fuori
    block:
      let d = copiaCartella(luce)
      let prima = fotografia(d)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "LuceScale"], root, @[("BCDD_EDITOR_PROVA_CLIC", "@t-dentro|#p-lampada|@b-togli|@f-ok|~|@b-annulla|@f-ok")])
      let fermo = attendi(s.trace, "attesa_fuoco", 30)
      rec("AC-215", "dopo l'azione la prova aspetta il ritorno del fuoco", fermo, cut(leggiSe(s.trace), 500))
      if fermo:
        let w = trovaFinestra(display, "bcdd-editor")
        let fuori = luceScale0.replace("    lampada  : Lampada\n", "").replace("La luce delle scale", "La luce dei corridoi")
        writeFile(d / "LuceScale.csc", fuori)
        focusAltrove(display, w)
        discard attendi(s.trace, "pagina 4", 15)
        sleep(300)
        raccogli(s)
        let (ok, perche) = cartellaSolo(d, prima, @[("LuceScale.csc", fuori)])
        rec("AC-215", "il file cambiato fuori resta com'è (niente annullamento)", ok, perche)
        let pag = paginaN(s, 4)
        rec("AC-215", "la finestra dice che non annulla perché il file è cambiato", "Non riuscito" in pag and "modificato da un altro programma" in pag, cut(pag[max(0, pag.len - 300) .. ^1]))
        rec("AC-215", "un solo save: quello dell'azione", azioniLanci(s).count("save") == 1, $azioniLanci(s))
      s.finisci()

  # --- AC-217: la scheda che scrive: i moduli, una scrittura per azione, i file attesi riga per riga
  block:
    let luce = root / "prove" / "f3" / "luce"
    proc confronta(d: string, prima: Table[string, (string, Time)], cambi: seq[(string, string)]): (bool, string) =
      var nomi: seq[string]
      for f in walkFiles(d / "*"): (if not f.endsWith(".prima"): nomi.add f.extractFilename)
      nomi.sort()
      var nomiPrima = toSeq(prima.keys)
      nomiPrima.sort()
      if nomi != nomiPrima: return (false, "file: " & $nomi)
      for n in nomi:
        var atteso = prima[n][0]
        for (f, x) in cambi:
          if f == n: atteso = x
        if readFile(d / n).splitLines() != atteso.splitLines(): return (false, n & ":\n" & readFile(d / n))
      (true, "")
    let lampada0 = readFile(luce / "Lampada.csc")
    let pulsante0 = readFile(luce / "Pulsante.csc")
    let luce0 = readFile(luce / "Luce.csc")
    let comando0 = readFile(luce / "Comando.csc")
    # la sequenza: scopo di Luce; promessa a Lampada (prima una frase con virgolette, che non scrive); promessa di Pulsante cambiata;
    # evento e stato a Comando (prima un nome riservato, che non scrive); promessa c1 tolta
    block:
      let clic = "#c-Luce|@b-scopo|=f-frase:La luce che si vede dalle scale|@f-ok|" &
        "@t-dentro|#p-lampada|@b-promessa|=f-frase:Dice \"no\"|=f-come:INSPECTION|=f-chi:il registro|@f-ok|=f-frase:Si spegne da sola|@f-ok|" &
        "#p-pulsante|#r-5|=f-frase:Ogni pressione accende|=f-come:JUDGEMENT|=f-chi:chi preme|@f-ok|" &
        "#l-Comando|@b-evento|=f-nome-d:spegni|=f-verso:IN|@f-ok|" &
        "@b-stato|=f-nome-d:END|=f-tipo-d:Duration|=f-valore:60|@f-ok|=f-nome-d:durata|@f-ok|" &
        "#r-5|@f-togli|@f-ok"
      let d = copiaCartella(luce)
      let prima = fotografia(d)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "LuceScale"], root, @[("BCDD_EDITOR_PROVA_CLIC", clic)])
      let fine = attendi(s.trace, "pagina 7", 40)
      rec("AC-217", "i sette disegni (apertura e sei scritture)", fine, cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 800))
      sleep(300)
      raccogli(s)
      let (ok, perche) = confronta(d, prima, @[
        ("Luce.csc", luce0.replace("\"Il confine fra la lampada e chi sta sulle scale: la luce che si vede\"", "\"La luce che si vede dalle scale\"")),
        ("Lampada.csc", lampada0.replace("END\n", "  GUARANTEE la2: VERBAL \"Si spegne da sola\"\n                 VERIFY BY INSPECTION \"il registro\"\nEND\n")),
        ("Pulsante.csc", pulsante0.replace("\"A ogni pressione segue un accendi entro 0,1 s\"\n                 VERIFY BY INSPECTION \"pressioni e comandi registrati\"",
          "\"Ogni pressione accende\"\n                 VERIFY BY JUDGEMENT \"chi preme\"")),
        ("Comando.csc", "CSC Comando VERSION 0.1\n  PURPOSE \"Il confine fra chi comanda la luce e la lampada\"\n  EVENT OUT accendi\n  EVENT IN spegni\n" &
          "  STATE durata : Duration INITIAL 60 s\nEND\n")])
      rec("AC-217", "i file alla fine sono quelli attesi, riga per riga; nessun file nuovo né cancellato", ok, perche)
      rec("AC-217", "sei save, nessun new; le due scritture rifiutate dal modulo non hanno lanciato niente", azioniLanci(s).count("save") == 6 and
        azioniLanci(s).count("new") == 0, $azioniLanci(s))
      let pag = paginaN(s, 7)
      rec("AC-217", "l'ultima scrittura riesce e lo dice", "Scritti i file: Comando.csc" in pag and "Non riuscito" notin pag, cut(pag[max(0, pag.len - 300) .. ^1]))
      let chk = runExe(bcdd, @["check", "--dir", ".", "Comando.csc"], d)
      rec("AC-217", "bcdd check sul risultato: nessun errore", chk.code == 0 and "esito: nessun errore" in chk.output, cut(chk.output))
      s.finisci()
    # togli e annulla: la cartella torna com'era
    block:
      let d = copiaCartella(luce)
      let prima = fotografia(d)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "LuceScale"], root, @[("BCDD_EDITOR_PROVA_CLIC", "@t-dentro|#p-lampada|#r-5|@f-togli|@f-ok|@b-annulla|@f-ok")])
      let fine = attendi(s.trace, "pagina 3", 30)
      rec("AC-217", "togli e annulla: tre disegni", fine, cut(leggiSe(s.dir / "errori")) & cut(leggiSe(s.trace), 600))
      sleep(300)
      raccogli(s)
      let (ok, perche) = confronta(d, prima, @[])
      rec("AC-217", "dopo «togli la promessa» e «annulla l'ultima azione» i file sono com'erano, riga per riga", ok, perche)
      rec("AC-217", "due save (togli e annulla)", azioniLanci(s).count("save") == 2, $azioniLanci(s))
      s.finisci()
    # una riga ratificata non apre il modulo; una riga che il modulo non conosce lo dice; una conosciuta lo apre
    block:
      let d = newWd0()
      writeFile(d / "Canale.csc", "CSC Canale VERSION 0.3\n  STATUS RATIFIED BY D-1\n  PURPOSE \"Un canale\"\n  CAPABILITY ricevi\n  EVENT OUT dato\n" &
        "  GUARANTEE c1: VERBAL \"Ogni dato arriva una volta sola\"\n                VERIFY BY INSPECTION \"i dati registrati\"\nEND\n")
      writeFile(d / "Nodo.csc", "ENTITY Nodo VERSION 0.1\n  PURPOSE \"Un nodo\"\n  OFFERS Canale\nEND\n")
      let prima = fotografia(d)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "Nodo"], root, @[("BCDD_EDITOR_PROVA_CLIC",
        "#c-Canale|#r-6|?scheda-modulo|?scheda-nota|#r-4|?scheda-modulo|?scheda-nota|#r-5|?scheda-modulo")])
      let fine = attendi(s.trace, "Evento dato", 30)
      rec("AC-217", "la prova arriva in fondo", fine, cut(leggiSe(s.dir / "errori")) & cut(leggiSe(s.trace), 900))
      raccogli(s)
      let tr = leggiSe(s.trace)
      let sonde = tr.splitLines().filterIt("sonda Q:" in it).mapIt(it[it.find("sonda Q:") + 8 .. ^1])
      rec("AC-217", "riga ratificata: il modulo resta nascosto e la nota dice che è contratto",
        sonde.len >= 5 and sonde[0].startsWith("scheda-modulo nascosto") and sonde[1].startsWith("scheda-nota visibile Questa riga è già approvata"), $sonde)
      rec("AC-217", "riga che il modulo non conosce (CAPABILITY): si apre la casella di testo (D-234), non un modulo",
        sonde.len >= 5 and sonde[2].startsWith("scheda-modulo visibile La riga 4 di Canale") and "Il testo, com'è nel file" in sonde[2] and sonde[3].startsWith("scheda-nota nascosto"), $sonde)
      rec("AC-217", "riga conosciuta (EVENT): il modulo si apre riempito", sonde.len >= 5 and sonde[4].startsWith("scheda-modulo visibile Evento dato"), $sonde)
      rec("AC-217", "niente è stato scritto: file uguali e nessun save", fotografia(d) == prima and azioniLanci(s).count("save") == 0, $azioniLanci(s))
      s.finisci()


  # --- AC-218: Completa, con tests/bcdd_prova e l'LLM finto (mai il bcdd di release, mai l'LLM vero)
  block:
    let rf = root / "prove" / "f2" / "refine"
    let fintoLlm = root / "prove" / "f2" / "ULlmFinto.sh"
    let lampadaC = "ENTITY Lampada VERSION 0.1\n  PURPOSE \"La lampada\"\n  OFFERS Luce\nEND\n"
    proc cartellaCompleta(): string =
      result = newWd0()
      copyFile(rf / "Luce.csc", result / "Luce.csc")
      writeFile(result / "Lampada.csc", lampadaC)
    proc ambienteFinto(s: Sess, extra: seq[(string, string)] = @[]): seq[(string, string)] =
      createDir s.dir / "aux"
      @[("BCDD_LLM", fintoLlm), ("BCDD_ATTESA_LLM", "30"), ("BCDD_ORA", "2026-10-16T18:00:00+02:00"),
        ("BCDD_REGISTRO", s.dir / "chiamate.tsv"), ("BCDD_FINTO_CONTA", s.dir / "aux" / "conta"),
        ("BCDD_FINTO_RISPOSTA", rf / "risposte" / "buona.json"), ("BCDD_FINTO_RISPOSTA_2", rf / "risposte" / "buona_seconda.json")] & extra
    proc nomiFile(d: string): seq[string] =
      for f in walkFiles(d / "*"): (if not f.endsWith(".prima"): result.add f.extractFilename)
      result.sort()
    proc lanciRefine(s: Sess): seq[string] = righe(s.lanci).filterIt(it.startsWith("refine "))
    proc sondeP(s: Sess): seq[string] = leggiSe(s.trace).splitLines().filterIt("sonda Q:" in it).mapIt(it[it.find("sonda Q:") + 8 .. ^1])
    # un giro completo: domanda, risposta, accetta p1 e scarta p2, scrivi; poi «Torna indietro di un'azione»
    block:
      let d = cartellaCompleta()
      var s = nuovaSessione()
      let clic = "#c-Luce|@b-completa|?scheda-completa|=c-testo-1:fra tre minuti circa|@c-avanti|@c-acc-p1|@c-sca-p2|?scheda-completa|@c-scrivi|" &
        "@b-annulla|@f-ok"
      s.avviaEditor(@["--dir", d, "Lampada"], root, ambienteFinto(s) & @[("BCDD_EDITOR_PROVA_CLIC", clic)])
      let fine = attendi(s.trace, "pagina 5", 60)
      rec("AC-218", "i cinque disegni (apertura, tempo 1, tempo 2, scrittura, torna indietro)", fine, cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 900))
      sleep(300)
      raccogli(s)
      let sonde = leggiSe(s.trace).splitLines().filterIt("sonda Q:" in it).mapIt(it[it.find("sonda Q:") + 8 .. ^1])
      rec("AC-218", "la domanda dell'LLM compare, con le sue tre scelte e «Salta»", sonde.len >= 2 and "Domanda dell'LLM" in sonde[0] and
        "Dopo quanto tempo senza pressioni la luce si deve spegnere?" in sonde[0] and "dopo tre minuti" in sonde[0] and "Salta" in sonde[0] and
        "Avanti" in sonde[0], $sonde)
      rec("AC-218", "le proposte: due righe proposte, Accetta e Scarta; le parole della grammatica solo nel testo delle righe", sonde.len >= 2 and
        sonde[1].count("Riga proposta") == 2 and "Accettata" in sonde[1] and "Scartata" in sonde[1] and "Scrivi le righe accettate" in sonde[1] and
        "Lascia stare" in sonde[1] and "1 riga accettata, ancora da approvare." in sonde[1] and
        sonde[1].count("Precisa la promessa g2.") == 2, $sonde)
      rec("AC-218", "tre refine, tutti con --json: tempo 1, tempo 2, tempo 3; nessun refine senza --json",
        lanciRefine(s).len == 3 and lanciRefine(s).allIt(" --json " in it or it.contains("--json")) and
        lanciRefine(s)[0].endsWith("--json Luce.csc --csc Luce --modello veloce") and lanciRefine(s)[1].endsWith("--json --answers Luce.csc") and
        lanciRefine(s)[2].endsWith("--json --accept Luce.csc") and righe(s.lanci).filterIt(it.startsWith("refine") and "--json" notin it).len == 0,
        $lanciRefine(s))
      # dopo «Torna indietro» il CSC è com'era; il dialogo che prima non c'era resta, e la finestra lo dice
      rec("AC-218", "il tempo 3 lo scrive bcdd refine (nessun save); «Torna indietro» è un solo save, quello di Luce.csc (il dialogo nuovo non si cancella)", azioniLanci(s).count("save") == 1, $azioniLanci(s))
      rec("AC-218", "Luce.csc torna com'era; il dialogo, che prima non c'era, resta con le risposte", leggiSe(d / "Luce.csc") == readFile(rf / "Luce.csc") and
        leggiSe(d / "Luce.csc.dialogo") == readFile(rf / "T01_buona.dialogo") and nomiFile(d) == @["Lampada.csc", "Luce.csc", "Luce.csc.dialogo"],
        $nomiFile(d) & " " & cut(leggiSe(d / "Luce.csc")))
      let pag5 = paginaN(s, 5)
      rec("AC-218", "la finestra dice che il dialogo resta", "Luce.csc.dialogo resta" in pag5 or "il file Luce.csc.dialogo resta" in pag5, cut(pag5[max(0, pag5.len - 300) .. ^1]))
      s.finisci()
    # lo stesso giro, fermato dopo la scrittura: guardare i file del tempo 3 (senza «Torna indietro»)
    block:
      let d = cartellaCompleta()
      var s = nuovaSessione()
      let clic = "#c-Luce|@b-completa|=c-testo-1:fra tre minuti circa|@c-avanti|@c-acc-p1|@c-sca-p2|@c-scrivi"
      s.avviaEditor(@["--dir", d, "Lampada"], root, ambienteFinto(s) & @[("BCDD_EDITOR_PROVA_CLIC", clic)])
      let fine = attendi(s.trace, "pagina 4", 60)
      rec("AC-218", "quattro disegni (apertura, tempo 1, tempo 2, scrittura)", fine, cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 900))
      sleep(300)
      raccogli(s)
      rec("AC-218", "Luce.csc è T01_buona.dopo.csc, riga per riga", leggiSe(d / "Luce.csc").splitLines() == readFile(rf / "T01_buona.dopo.csc").splitLines(), leggiSe(d / "Luce.csc"))
      rec("AC-218", "il dialogo è T01_buona.dialogo; nessun giro rimasto; nessun file in più", leggiSe(d / "Luce.csc.dialogo") == readFile(rf / "T01_buona.dialogo") and
        nomiFile(d) == @["Lampada.csc", "Luce.csc", "Luce.csc.dialogo"], $nomiFile(d))
      let pag = paginaN(s, 4)
      rec("AC-218", "dopo la scrittura le righe nuove sono nel file e lo stato è senza errori; nessun save (scrive bcdd refine)",
        "Scritti i file: Luce.csc, Luce.csc.dialogo" in pag and "Non riuscito" notin pag and azioniLanci(s).count("save") == 0, cut(pag[max(0, pag.len - 400) .. ^1]))
      let chk = runExe(bcdd, @["check", "--dir", ".", "Luce.csc"], d)
      rec("AC-218", "bcdd check sul risultato: nessun errore", chk.code == 0 and "esito: nessun errore" in chk.output, cut(chk.output))
      s.finisci()
    # «Lascia stare»: niente scritto, giro chiuso
    block:
      let d = cartellaCompleta()
      let prima = fotografia(d)
      var s = nuovaSessione()
      let clic = "#c-Luce|@b-completa|=c-testo-1:fra tre minuti circa|@c-avanti|@c-acc-p1|@c-lascia"
      s.avviaEditor(@["--dir", d, "Lampada"], root, ambienteFinto(s) & @[("BCDD_EDITOR_PROVA_CLIC", clic)])
      let fine = attendi(s.trace, "pagina 4", 60)
      rec("AC-218", "Lascia stare: quattro disegni", fine, cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 900))
      sleep(300)
      raccogli(s)
      rec("AC-218", "Lascia stare: la cartella è identica (file, contenuti, date), nessun giro, nessun dialogo", fotografia(d) == prima, $nomiFile(d))
      rec("AC-218", "Lascia stare: tempo 1, tempo 2, --cancel; nessun save", lanciRefine(s).len == 3 and lanciRefine(s)[2].endsWith("--json --cancel Luce.csc") and
        azioniLanci(s).count("save") == 0, $lanciRefine(s))
      s.finisci()
    # Ferma: SIGINT a bcdd, la finestra non si blocca, niente scritto
    block:
      let d = cartellaCompleta()
      let prima = fotografia(d)
      var s = nuovaSessione()
      let clic = "#c-Luce|>b-completa|?scheda-completa|>c-ferma"
      s.avviaEditor(@["--dir", d, "Lampada"], root, ambienteFinto(s, @[("BCDD_FINTO_ATTESA", "25")]) & @[("BCDD_EDITOR_PROVA_CLIC", clic)])
      let t0 = epochTime()
      let fine = attendi(s.trace, "pagina 2", 30)
      let durata = epochTime() - t0
      rec("AC-218", "Ferma: la finestra riceve la fine del processo molto prima dei 25 s dell'LLM lento", fine and durata < 15.0, cut(leggiSe(s.dir / "errori")) & " " & formatFloat(durata) & " " & cut(leggiSe(s.trace), 900))
      sleep(300)
      raccogli(s)
      let sonde = leggiSe(s.trace).splitLines().filterIt("sonda Q:" in it).mapIt(it[it.find("sonda Q:") + 8 .. ^1])
      rec("AC-218", "durante l'attesa la scheda dice «Chiedo all'LLM…» e offre Ferma", sonde.len >= 1 and "Chiedo all'LLM…" in sonde[0] and "Ferma" in sonde[0], $sonde)
      rec("AC-218", "dopo Ferma la scheda dice «Fermato» e la cartella è identica, senza giro", "Fermato. Non è stato scritto niente." in paginaN(s, 2) and fotografia(d) == prima,
        cut(paginaN(s, 2)[max(0, paginaN(s, 2).len - 300) .. ^1]) & $nomiFile(d))
      s.finisci()
    # un giro rimasto aperto (finestra chiusa a metà): la scheda chiede Riprendi o Chiudi il giro; «Chiudi il giro» lo chiude senza scrivere
    block:
      let d = cartellaCompleta()
      var s = nuovaSessione()
      let env = ambienteFinto(s)
      let r1 = runExe(bcddProva, @["refine", "--json", "Luce.csc", "--csc", "Luce"], d, envPulito(env))
      let prima = fotografia(d)
      s.avviaEditor(@["--dir", d, "Lampada"], root, env & @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|@b-completa|?scheda-completa|@c-chiudi-giro")])
      let fine = attendi(s.trace, "pagina 3", 40)
      rec("AC-218", "giro aperto: tre disegni (apertura, giro aperto, giro chiuso)", r1.code == 0 and fine, r1.errout & cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 900))
      sleep(300)
      raccogli(s)
      let sonde = leggiSe(s.trace).splitLines().filterIt("sonda Q:" in it).mapIt(it[it.find("sonda Q:") + 8 .. ^1])
      rec("AC-218", "giro aperto: la scheda offre Riprendi e Chiudi il giro", sonde.len >= 1 and "Riprendi" in sonde[0] and "Chiudi il giro" in sonde[0], $sonde)
      var dopo = nomiFile(d)
      rec("AC-218", "giro aperto: chiuso, il file .giro non c'è più e il CSC è com'era", not ("Luce.csc.giro" in dopo) and leggiSe(d / "Luce.csc") == readFile(rf / "Luce.csc") and
        prima.len == dopo.len + 1, $dopo)
      s.finisci()
    # «Riprendi»: `refine --json --show`, nessuna chiamata all'LLM; il giro prosegue come se non si fosse interrotto
    block:
      # finestra chiusa dopo il tempo 1 con domande: Riprendi, stessa domanda, rispondi, proposte, accetta p1 e scarta p2, scrivi
      let d = cartellaCompleta()
      var s = nuovaSessione()
      let env = ambienteFinto(s)
      let r1 = runExe(bcddProva, @["refine", "--json", "Luce.csc", "--csc", "Luce"], d, envPulito(env))
      let clic = "#c-Luce|@b-completa|?scheda-completa|@c-riprendi|?scheda-completa|=c-testo-1:fra tre minuti circa|@c-avanti|@c-acc-p1|@c-sca-p2|@c-scrivi"
      s.avviaEditor(@["--dir", d, "Lampada"], root, env & @[("BCDD_EDITOR_PROVA_CLIC", clic)])
      let fine = attendi(s.trace, "pagina 5", 60)
      rec("AC-227", "Riprendi dopo il tempo 1: cinque disegni (apertura, giro aperto, domande, proposte, scrittura)", r1.code == 0 and fine,
        r1.errout & cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 900))
      sleep(300)
      raccogli(s)
      let sonde = sondeP(s)
      rec("AC-227", "Riprendi dopo il tempo 1: la stessa domanda con le sue scelte; nessuna richiesta all'LLM per rimostrarla",
        sonde.len >= 2 and "Riprendi" in sonde[0] and "Domanda dell'LLM" in sonde[1] and "Dopo quanto tempo senza pressioni la luce si deve spegnere?" in sonde[1] and
        "dopo tre minuti" in sonde[1], $sonde)
      rec("AC-227", "i refine della finestra sono: tempo 1 (trova il giro aperto), --show, tempo 2, tempo 3; il --show è con --json e con --csc",
        lanciRefine(s).len == 4 and lanciRefine(s)[1].endsWith("--json Luce.csc --csc Luce --show") and lanciRefine(s)[2].endsWith("--json --answers Luce.csc") and
        lanciRefine(s)[3].endsWith("--json --accept Luce.csc"), $lanciRefine(s))
      rec("AC-227", "Luce.csc e dialogo come nel giro senza interruzione",
        leggiSe(d / "Luce.csc").splitLines() == readFile(rf / "T01_buona.dopo.csc").splitLines() and leggiSe(d / "Luce.csc.dialogo") == readFile(rf / "T01_buona.dialogo") and
        nomiFile(d) == @["Lampada.csc", "Luce.csc", "Luce.csc.dialogo"], $nomiFile(d))
      s.finisci()
    block:
      # finestra chiusa dopo il tempo 2: Riprendi mostra subito le proposte
      let d = cartellaCompleta()
      var s = nuovaSessione()
      let env = ambienteFinto(s)
      let r1 = runExe(bcddProva, @["refine", "--json", "Luce.csc", "--csc", "Luce"], d, envPulito(env))
      let r2 = runExe("/bin/sh", @["-c", "printf '%s' '{\"risposte\": [{\"n\": 1, \"testo\": \"fra tre minuti circa\"}]}' | '" & bcddProva & "' refine --json --answers Luce.csc"], d, envPulito(env))
      let clic = "#c-Luce|@b-completa|@c-riprendi|?scheda-completa|@c-acc-p1|@c-sca-p2|@c-scrivi"
      s.avviaEditor(@["--dir", d, "Lampada"], root, env & @[("BCDD_EDITOR_PROVA_CLIC", clic)])
      let fine = attendi(s.trace, "pagina 4", 60)
      rec("AC-227", "Riprendi dopo il tempo 2: quattro disegni (apertura, giro aperto, proposte, scrittura)", r1.code == 0 and r2.code == 0 and fine,
        r2.errout & cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 900))
      sleep(300)
      raccogli(s)
      let sonde = sondeP(s)
      rec("AC-227", "Riprendi dopo il tempo 2: due righe proposte, senza nuova richiesta all'LLM", sonde.len >= 1 and sonde[0].count("Riga proposta") == 2 and
        lanciRefine(s).len == 3 and lanciRefine(s)[1].endsWith("--show") and lanciRefine(s)[2].endsWith("--json --accept Luce.csc"), $sonde & $lanciRefine(s))
      rec("AC-227", "Luce.csc e dialogo come nel giro senza interruzione",
        leggiSe(d / "Luce.csc").splitLines() == readFile(rf / "T01_buona.dopo.csc").splitLines() and leggiSe(d / "Luce.csc.dialogo") == readFile(rf / "T01_buona.dialogo"), cut(leggiSe(d / "Luce.csc")))
      s.finisci()
    block:
      # il file è cambiato dopo che il giro era stato lasciato a metà: Riprendi non scrive niente, chiude il giro e mostra le risposte da copiare
      let d = cartellaCompleta()
      var s = nuovaSessione()
      let env = ambienteFinto(s)
      let r1 = runExe(bcddProva, @["refine", "--json", "Luce.csc", "--csc", "Luce"], d, envPulito(env))
      let r2 = runExe("/bin/sh", @["-c", "printf '%s' '{\"risposte\": [{\"n\": 1, \"testo\": \"fra tre minuti circa\"}]}' | '" & bcddProva & "' refine --json --answers Luce.csc"], d, envPulito(env))
      let modificato = readFile(d / "Luce.csc").replace("\nEND", "\n  -- un commento\nEND")
      writeFile(d / "Luce.csc", modificato)
      s.avviaEditor(@["--dir", d, "Lampada"], root, env & @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|@b-completa|@c-riprendi|?scheda-completa")])
      let fine = attendi(s.trace, "pagina 3", 60)
      rec("AC-227", "file cambiato: tre disegni (apertura, giro aperto, copia)", r1.code == 0 and r2.code == 0 and fine, cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 900))
      sleep(300)
      raccogli(s)
      let sonde = sondeP(s)
      rec("AC-227", "file cambiato: la scheda dice che il file è cambiato e mostra le risposte da copiare",
        sonde.len >= 1 and "Il file è cambiato" in sonde[0] and "fra tre minuti circa" in sonde[0], $sonde)
      rec("AC-227", "file cambiato: Luce.csc è com'era dopo la modifica, il giro è chiuso (niente .giro), niente save",
        leggiSe(d / "Luce.csc") == modificato and not ("Luce.csc.giro" in nomiFile(d)) and azioniLanci(s).count("save") == 0, $nomiFile(d))
      s.finisci()
    # un connettore a parte proposto dall'LLM: il bottone lo crea con `bcdd new`
    block:
      let d = cartellaCompleta()
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "Lampada"], root, ambienteFinto(s, @[("BCDD_FINTO_RISPOSTA", rf / "risposte" / "csc_a_parte.json")]) &
        @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|@b-completa|?scheda-completa|@c-crea-Pulsante|@f-ok|?scheda-completa|@c-lascia")])
      let fine = attendi(s.trace, "pagina 4", 40)
      rec("AC-218", "connettore a parte: quattro disegni", fine, cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 900))
      sleep(300)
      raccogli(s)
      let sonde = leggiSe(s.trace).splitLines().filterIt("sonda Q:" in it).mapIt(it[it.find("sonda Q:") + 8 .. ^1])
      rec("AC-218", "connettore a parte: la scheda dice perché e offre «Crea il connettore Pulsante»; dopo, «c'è già»", sonde.len >= 2 and
        "Connettore a parte: Pulsante" in sonde[0] and "Crea il connettore Pulsante" in sonde[0] and "il pulsante ha una spia" in sonde[0] and
        "Il connettore Pulsante c'è già" in sonde[1], $sonde)
      let rif = newWd0()
      discard runExe(bcddProva, @["new", "Pulsante"], rif)
      # lo scopo del file è la prima frase del motivo dell'LLM (il campo del modulo, non modificato)
      let attesoP = leggiSe(rif / "Pulsante.csc").splitLines().mapIt(if it.startsWith("  PURPOSE"): "  PURPOSE \"il pulsante ha una spia con stati e tempi suoi, che non sono quelli della luce\"" else: it)
      rec("AC-218", "connettore a parte: Pulsante.csc è quello di `bcdd new Pulsante` con lo scopo dal motivo; un new; il giro è chiuso; Luce.csc com'era",
        fileExists(d / "Pulsante.csc") and leggiSe(d / "Pulsante.csc").splitLines() == attesoP and azioniLanci(s).count("new") == 1 and
        nomiFile(d) == @["Lampada.csc", "Luce.csc", "Pulsante.csc"] and leggiSe(d / "Luce.csc") == readFile(rf / "Luce.csc"), $nomiFile(d))
      s.finisci()
    # file con errori: Completa non parte e lo dice, con l'elenco; nessun refine lanciato
    block:
      let d = cartellaCompleta()
      writeFile(d / "Luce.csc", readFile(rf / "Luce.csc").replace("GUARANTEE g2:", "GUARANTEE g1:"))
      let prima = fotografia(d)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "Lampada"], root, ambienteFinto(s) & @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|@b-completa|?scheda-completa")])
      let fine = attendi(s.trace, "sonda Q:scheda-completa", 30)
      sleep(300)
      raccogli(s)
      let sonde = leggiSe(s.trace).splitLines().filterIt("sonda Q:" in it).mapIt(it[it.find("sonda Q:") + 8 .. ^1])
      rec("AC-218", "errori nel file: «Completa non parte», con l'elenco, e nessun refine", fine and sonde.len >= 1 and "Completa non parte" in sonde[0] and "●" in sonde[0] and
        lanciRefine(s).len == 0 and fotografia(d) == prima, $sonde & $lanciRefine(s))
      s.finisci()

    # --- AC-219: Approva. L'oracolo è `bcdd_prova ratify` lanciato a mano su una copia: i file devono essere gli stessi.
    proc cartellaApprova(testo: string): string =
      result = newWd0()
      writeFile(result / "Luce.csc", testo)
      writeFile(result / "Lampada.csc", lampadaC)
    proc oracolo(testo: string, chiamate: seq[seq[string]]): string =
      let r = cartellaApprova(testo)
      for a in chiamate: discard runExe(bcddProva, a, r)
      leggiSe(r / "Luce.csc")
    proc lanciRatify(s: Sess): seq[string] = righe(s.lanci).filterIt(it.startsWith("ratify "))
    proc sondeDi(s: Sess): seq[string] = leggiSe(s.trace).splitLines().filterIt("sonda Q:" in it).mapIt(it[it.find("sonda Q:") + 8 .. ^1])
    let luce2 = readFile(rf / "Luce.csc")
    let luce3 = luce2.replace("END\n", "  GUARANTEE g3: VERBAL \"Chi è ancora sulle scale non resta al buio\"\n                VERIFY BY JUDGEMENT \"l'operatore\"\nEND\n")
    let luceDopo = readFile(rf / "T01_buona.dopo.csc")
    proc rat(args: varargs[string]): seq[string] = @["ratify", "Luce.csc", "--dir", ".", "--csc", "Luce"] & @args
    # una riga: dal modulo della promessa, Approva, il numero, Approva; il numero non è mai proposto
    block:
      let d = cartellaApprova(luce2)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "Lampada"], root, @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|#r-10|@f-approva|?scheda-approva|!a-ok|!a-num|=a-num:D-9|!a-ok|@a-ok")])
      let fine = attendi(s.trace, "pagina 2", 40)
      rec("AC-219", "una riga: due disegni (apertura e approvazione)", fine, cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 900))
      sleep(300)
      raccogli(s)
      let sonde = sondeDi(s)
      rec("AC-219", "una riga: il campo del numero compare vuoto, con Approva e Annulla; Approva è spento finché il numero non è D-9",
        sonde.len >= 4 and "Approva la promessa g1 di Luce" in sonde[0] and "Riferimento della decisione (per esempio D-12)" in sonde[0] and "Annulla" in sonde[0] and
        sonde[1] == "a-ok spento" and sonde[2] == "a-num acceso valore=" and sonde[3] == "a-ok acceso", $sonde)
      rec("AC-219", "una riga: Luce.csc è quello di `bcdd ratify … g1 D-9`, e c'è un solo ratify",
        leggiSe(d / "Luce.csc") == oracolo(luce2, @[rat("g1", "D-9")]) and lanciRatify(s) == @["ratify Luce.csc --dir . --csc Luce g1 D-9"], $lanciRatify(s))
      let pag = paginaN(s, 2)
      rec("AC-219", "una riga: la riga è verde «approvata (D-9)» e il messaggio dice quante sono approvate",
        "approvata (D-9)" in pag and "1 riga approvata (D-9)" in pag and "Non riuscito" notin pag, cut(pag[max(0, pag.len - 400) .. ^1]))
      s.finisci()
    # due righe scelte (g1 e g3, non g2), un ratify per riga nell'ordine dell'elenco; poi «Torna indietro di un'azione» le riporta tutte com'erano
    block:
      let d = cartellaApprova(luce3)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "Lampada"], root, @[("BCDD_EDITOR_PROVA_CLIC",
        "#c-Luce|=a-num:D-7|@a-sel-g1|@a-sel-g3|?scheda-approva|!a-ok|@a-ok|@b-annulla|@f-ok")])
      let fine = attendi(s.trace, "pagina 3", 40)
      rec("AC-219", "due righe: tre disegni (apertura, approvazione, torna indietro)", fine, cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 900))
      sleep(300)
      raccogli(s)
      let sonde = sondeDi(s)
      rec("AC-219", "due righe: l'elenco «Da approvare» ha le tre righe con le caselle e «Approva le righe scelte»",
        sonde.len >= 2 and "Da approvare" in sonde[0] and "Promessa g1" in sonde[0] and "Promessa g2" in sonde[0] and "Promessa g3" in sonde[0] and
        "Approva le righe scelte" in sonde[0] and sonde[1] == "a-ok acceso", $sonde)
      rec("AC-219", "due righe: due ratify, g1 poi g3, con lo stesso numero",
        lanciRatify(s) == @["ratify Luce.csc --dir . --csc Luce g1 D-7", "ratify Luce.csc --dir . --csc Luce g3 D-7"], $lanciRatify(s))
      let pag2 = paginaN(s, 2)
      rec("AC-219", "due righe: due righe verdi «approvata (D-7)», la terza no, e il messaggio dice due",
        pag2.count("approvata (D-7)") == 2 and "2 righe approvate (D-7)" in pag2 and "Non riuscito" notin pag2,
        cut(pag2[max(0, pag2.len - 400) .. ^1]))
      rec("AC-219", "due righe: lo stato dopo le due approvazioni è quello di bcdd (g1 e g3 contratto, g2 no)",
        oracolo(luce3, @[rat("g1", "D-7"), rat("g3", "D-7")]).count("RATIFIED BY D-7") == 2, "")
      rec("AC-219", "torna indietro dopo due righe: un solo save, e Luce.csc è com'era prima della prima",
        azioniLanci(s).count("save") == 1 and leggiSe(d / "Luce.csc") == luce3 and "Non riuscito" notin paginaN(s, 3), cut(paginaN(s, 3)[max(0, paginaN(s, 3).len - 400) .. ^1]))
      s.finisci()
    # il connettore intero: prima l'elenco, poi il numero, un ratify solo; il bottone si spegne perché l'intestazione ora è contratto
    block:
      let d = cartellaApprova(luceDopo)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "Lampada"], root, @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|@b-approva-intero|?scheda-approva|=a-num:D-11|@a-ok|!b-approva-intero")])
      let fine = attendi(s.trace, "sonda Q:b-approva-intero", 40)
      rec("AC-219", "connettore intero: due disegni e la sonda finale", fine, cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 900))
      sleep(300)
      raccogli(s)
      let sonde = sondeDi(s)
      rec("AC-219", "connettore intero: l'elenco dice che cosa sarà approvato e che cosa resta da approvare, prima del numero",
        sonde.len >= 2 and "Saranno approvate:" in sonde[0] and "L'intestazione del connettore Luce" in sonde[0] and "Evento pressione" in sonde[0] and
        "Stato accesa" in sonde[0] and "Promessa g1" in sonde[0] and "Promessa g2:" in sonde[0] and
        sonde[0].find("Restano da approvare (una per una):") > sonde[0].find("Promessa g2:") and
        sonde[0].find("Promessa g2a") > sonde[0].find("Restano da approvare") and
        sonde[0].find("Riferimento della decisione") > sonde[0].find("Promessa g2a"), $sonde)
      rec("AC-219", "connettore intero: Luce.csc è quello di `bcdd ratify … D-11`, e c'è un solo ratify",
        leggiSe(d / "Luce.csc") == oracolo(luceDopo, @[rat("D-11")]) and lanciRatify(s) == @["ratify Luce.csc --dir . --csc Luce D-11"], $lanciRatify(s))
      rec("AC-219", "connettore intero: il messaggio dice cinque righe e una che resta; il bottone ora è spento",
        "5 righe approvate (D-11); 1 riga resta da approvare" in paginaN(s, 2) and sonde.len >= 2 and sonde[1] == "b-approva-intero spento", $sonde & cut(paginaN(s, 2)[max(0, paginaN(s, 2).len - 300) .. ^1]))
      s.finisci()
    # un file con errori: Approva non parte, né per le righe né per il connettore intero; nessun ratify
    block:
      let d = cartellaApprova(luce2.replace("GUARANTEE g2:", "GUARANTEE g1:"))
      let prima = fotografia(d)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "Lampada"], root, @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|?scheda-approva|@b-approva-intero|?scheda-approva")])
      let fine = attendi(s.trace, "sonda Q:scheda-approva", 40)
      sleep(1500)
      raccogli(s)
      let sonde = sondeDi(s)
      rec("AC-219", "file con errori: la scheda dice «Prima correggi gli errori», con l'elenco, per le righe e per il connettore intero",
        fine and sonde.len >= 2 and sonde.allIt("Prima correggi gli errori: un file con errori non si approva." in it and "●" in it and "Approva le righe scelte" notin it),
        $sonde & cut(leggiSe(s.dir / "errori")))
      rec("AC-219", "file con errori: nessun ratify, la cartella è identica", lanciRatify(s).len == 0 and fotografia(d) == prima, $lanciRatify(s))
      s.finisci()
    # numero non valido o nessuna riga scelta: il bottone resta spento, il campo parte vuoto
    block:
      let d = cartellaApprova(luce3)
      let prima = fotografia(d)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "Lampada"], root, @[("BCDD_EDITOR_PROVA_CLIC",
        "#c-Luce|!a-ok|!a-num|=a-num:D12|@a-sel-g1|!a-ok|?a-num-err|=a-num:D-|!a-ok|=a-num:D-12|!a-ok|@a-sel-g1|!a-ok|?scheda-nota")])
      let fine = attendi(s.trace, "sonda Q:scheda-nota", 40)
      sleep(500)
      raccogli(s)
      let sonde = sondeDi(s)
      rec("AC-219", "numero non valido: spento senza righe scelte; il campo parte vuoto; D12 e D- lasciano il bottone spento; D-12 con una riga lo accende; senza la riga si rispegne",
        fine and sonde.len >= 8 and sonde[0] == "a-ok spento" and sonde[1] == "a-num acceso valore=" and sonde[2] == "a-ok spento" and
        "Scrivilo così" in sonde[3] and sonde[4] == "a-ok spento" and sonde[5] == "a-ok acceso" and sonde[6] == "a-ok spento", $sonde)
      rec("AC-219", "numero non valido: nessun ratify, la cartella è identica", lanciRatify(s).len == 0 and fotografia(d) == prima, $lanciRatify(s))
      s.finisci()
    # dopo «Scrivi le righe accettate» di Completa: lo stesso elenco, con la riga appena scritta (g2a) già scelta e le altre no
    block:
      let d = cartellaCompleta()
      var s = nuovaSessione()
      let clic = "#c-Luce|@b-completa|=c-testo-1:fra tre minuti circa|@c-avanti|@c-acc-p1|@c-sca-p2|@c-scrivi|!a-sel-g2a|!a-sel-g1|=a-num:D-5|@a-ok"
      s.avviaEditor(@["--dir", d, "Lampada"], root, ambienteFinto(s) & @[("BCDD_EDITOR_PROVA_CLIC", clic)])
      let fine = attendi(s.trace, "pagina 5", 60)
      rec("AC-219", "dopo Completa: cinque disegni (apertura, due tempi, scrittura, approvazione)", fine, cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 900))
      sleep(300)
      raccogli(s)
      let sonde = sondeDi(s)
      rec("AC-219", "dopo Completa: g2a, appena scritta, è già scelta; g1 no", sonde.len >= 2 and sonde[0] == "a-sel-g2a acceso scelto=true" and sonde[1] == "a-sel-g1 acceso scelto=false", $sonde)
      rec("AC-219", "dopo Completa: si approva solo g2a (un ratify), e il file è quello di `bcdd ratify … g2a D-5`",
        lanciRatify(s) == @["ratify Luce.csc --dir . --csc Luce g2a D-5"] and leggiSe(d / "Luce.csc") == oracolo(luceDopo, @[rat("g2a", "D-5")]), $lanciRatify(s))
      s.finisci()

  # --- AC-220 e AC-221: la casella di testo e Nuova versione, con tests/bcdd_prova
  block:
    let luce = root / "prove" / "f3" / "luce"
    let rf = root / "prove" / "f2" / "refine"
    let lampadaC = "ENTITY Lampada VERSION 0.1\n  PURPOSE \"La lampada\"\n  OFFERS Luce\nEND\n"
    proc sondeP(s: Sess): seq[string] = leggiSe(s.trace).splitLines().filterIt("sonda Q:" in it).mapIt(it[it.find("sonda Q:") + 8 .. ^1])
    proc nSave(s: Sess): int = azioniLanci(s).count("save")
    proc cartellaLuce(testo: string): string =
      result = newWd0()
      writeFile(result / "Luce.csc", testo)
      writeFile(result / "Lampada.csc", lampadaC)
    proc ratifica(d: string, chiamate: seq[seq[string]]) =
      for a in chiamate: discard runExe(bcddProva, a, d)
    # --- AC-220: la casella, una dopo l'altra: versione dell'intestazione (con il nome sbagliato che avvisa), CAPABILITY, un commento
    # svuotato (con conferma), un testo con un errore (scritto lo stesso), Torna indietro
    block:
      let d = newWd0()
      writeFile(d / "Prova.csc", "CSC Prova VERSION 0.1\n  PURPOSE \"Una prova\"\n  -- da svuotare\n  CAPABILITY Accendi\n  EVENT IN premuto\n" &
        "  GUARANTEE p1: VERBAL \"Una promessa\"\n                VERIFY BY JUDGEMENT \"l'operatore\"\nEND\n")
      writeFile(d / "Ent.csc", "ENTITY Ent VERSION 0.1\n  PURPOSE \"x\"\n  OFFERS Prova\nEND\n")
      var s = nuovaSessione()
      let clic = "#c-Prova|#r-1|!f-testo|=f-testo:CSC Altro VERSION 0.1|?e-f-testo|=f-testo:CSC Prova VERSION 0.2|@f-ok|" &
        "#r-4|=f-testo:  CAPABILITY Spegni|@f-ok|" &
        "#r-3|=f-testo:|@f-ok|?scheda-modulo|@f-ok|" &
        "#r-3|=f-testo:  CAPABILITY Spegni\n  CAPABILITY Spegni|@f-ok|" &
        "@b-annulla|@f-ok"
      s.avviaEditor(@["--dir", d, "Ent"], root, @[("BCDD_EDITOR_PROVA_CLIC", clic)])
      let fine = attendi(s.trace, "pagina 6", 40)
      rec("AC-220", "i sei disegni (apertura, quattro scritture, torna indietro)", fine, cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 900))
      sleep(300)
      raccogli(s)
      let sonde = sondeP(s)
      rec("AC-220", "la casella dell'intestazione mostra la riga com'è; con un altro nome dice «Il file resta Prova.csc…»",
        sonde.len >= 3 and sonde[0] == "f-testo acceso valore=CSC Prova VERSION 0.1" and
        sonde[1] == "e-f-testo visibile Il file resta Prova.csc: se cambi il nome, il controllo segnala un errore.", $sonde)
      rec("AC-220", "svuotare un commento chiede conferma in una frase, con «Torna indietro»",
        sonde.len >= 3 and sonde[2].startsWith("scheda-modulo visibile Tolgo la riga 3 da Prova?") and "Torna indietro di un'azione" in sonde[2], $sonde)
      rec("AC-220", "cinque save: versione, CAPABILITY, commento tolto, testo con errore, torna indietro", nSave(s) == 5, $azioniLanci(s))
      rec("AC-220", "il testo con l'errore è scritto lo stesso e la pagina dà il messaggio di bcdd (nome già usato)",
        "nome già usato alla riga 3" in paginaN(s, 5) and "Non riuscito" notin paginaN(s, 5), cut(paginaN(s, 5)[max(0, paginaN(s, 5).len - 500) .. ^1]))
      let attesa = "CSC Prova VERSION 0.2\n  PURPOSE \"Una prova\"\n  CAPABILITY Spegni\n  EVENT IN premuto\n" &
        "  GUARANTEE p1: VERBAL \"Una promessa\"\n                VERIFY BY JUDGEMENT \"l'operatore\"\nEND\n"
      rec("AC-220", "dopo Torna indietro Prova.csc è riga per riga quello delle prime tre scritture", leggiSe(d / "Prova.csc").splitLines() == attesa.splitLines(), leggiSe(d / "Prova.csc"))
      rec("AC-220", "Ent.csc non è stato toccato", leggiSe(d / "Ent.csc") == "ENTITY Ent VERSION 0.1\n  PURPOSE \"x\"\n  OFFERS Prova\nEND\n", "")
      s.finisci()
    # righe approvate: né la STATUS né la promessa aprono la casella (la nota dice Nuova versione); nessuna scrittura
    block:
      let d = cartellaLuce(readFile(luce / "Luce.csc"))
      ratifica(d, @[@["ratify", "Luce.csc", "D-1"]])
      let prima = fotografia(d)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "Lampada"], root, @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|#r-2|?scheda-nota|?f-testo|#r-5|?scheda-nota|?f-testo|#r-1|?scheda-nota|?f-testo")])
      let fine = attendi(s.trace, "sonda Q:f-testo", 30)
      sleep(500)
      raccogli(s)
      let sonde = sondeP(s)
      rec("AC-220", "riga approvata: la nota dice «per cambiarla usa Nuova versione» e la casella non c'è, per STATUS e per la promessa",
        fine and sonde.len >= 6 and sonde[0] == "scheda-nota visibile Questa riga è già approvata (fa parte del contratto): per cambiarla usa Nuova versione." and
        sonde[1] == "f-testo assente" and sonde[2] == sonde[0] and sonde[3] == "f-testo assente", $sonde)
      rec("AC-220", "l'intestazione di un connettore approvato non apre la casella: stessa nota, f-testo assente (D-236)",
        sonde.len >= 6 and sonde[4] == sonde[0] and sonde[5] == "f-testo assente", $sonde)
      rec("AC-220", "nessuna scrittura: file uguali e nessun save", fotografia(d) == prima and nSave(s) == 0, $azioniLanci(s))
      s.finisci()
    # STATUS RATIFIED scritto nella casella non approva niente: bcdd save lo rifiuta; e un testo non cambiato non scrive
    block:
      let d = newWd0()
      copyFile(rf / "Luce.csc", d / "Luce.csc")
      writeFile(d / "Lampada.csc", lampadaC)
      let prima = fotografia(d)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "Lampada"], root, @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|#r-4|@f-ok|?scheda-nota|#r-4|=f-testo:  STATUS RATIFIED BY D-5|@f-ok")])
      let fine = attendi(s.trace, "pagina 2", 30)
      sleep(500)
      raccogli(s)
      let sonde = sondeP(s)
      rec("AC-220", "testo non cambiato: «non ho scritto niente», nessun save", sonde.len >= 1 and sonde[0] == "scheda-nota visibile Il testo non è cambiato: non ho scritto niente.", $sonde)
      rec("AC-220", "STATUS RATIFIED BY nella casella: rifiutato da bcdd save, il messaggio è mostrato, il file è uguale",
        fine and nSave(s) == 1 and "Non riuscito" in paginaN(s, 2) and fotografia(d) == prima, cut(paginaN(s, 2)[max(0, paginaN(s, 2).len - 400) .. ^1]))
      s.finisci()
    # un messaggio che rimandava a un editor di testo apre la casella sulla riga di cui parla
    block:
      let d = newWd0()
      discard runExe(bcddProva, @["new", "Canale"], d)
      writeFile(d / "Nodo.csc", "ENTITY Nodo VERSION 0.1\n  PURPOSE \"Un nodo\"\n  OFFERS Canale  -- una nota\nEND\n")
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "Nodo"], root, @[("BCDD_EDITOR_PROVA_CLIC", "#c-Canale|@b-togli|@f-ok|!f-testo|?scheda-modulo|=f-testo:  OFFERS Canale|@f-ok")])
      let fine = attendi(s.trace, "pagina 3", 30)
      sleep(500)
      raccogli(s)
      let sonde = sondeP(s)
      rec("AC-220", "togli una riga di forma strana: l'errore lo dice e la casella si apre su quella riga",
        fine and "la riga 3 di Nodo è scritta in un modo che qui non so togliere: cambiala nella casella di testo" in paginaN(s, 2) and sonde.len >= 2 and
        sonde[0] == "f-testo acceso valore=  OFFERS Canale  -- una nota" and sonde[1].startsWith("scheda-modulo visibile La riga 3 di Nodo"), $sonde)
      rec("AC-220", "la riga riscritta senza il commento: un solo save, file riga per riga",
        nSave(s) == 1 and leggiSe(d / "Nodo.csc").splitLines() == "ENTITY Nodo VERSION 0.1\n  PURPOSE \"Un nodo\"\n  OFFERS Canale\nEND\n".splitLines(), leggiSe(d / "Nodo.csc"))
      s.finisci()

    # --- AC-221: Nuova versione
    let rawR = (let dd = cartellaLuce(readFile(luce / "Luce.csc")); ratifica(dd, @[@["ratify", "Luce.csc", "D-1"]]); readFile(dd / "Luce.csc"))
    let attesaR = "-- VERSION 0.2: Anche a metà\n" & rawR.replace("VERSION 0.1", "VERSION 0.2").replace("STATUS RATIFIED BY D-1", "STATUS HYPOTHESIS")
    # connettore approvato, nessuna riga scelta: prima gli errori (frase vuota, numero uguale), poi la scrittura giusta
    block:
      let d = cartellaLuce(rawR)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "Lampada"], root, @[("BCDD_EDITOR_PROVA_CLIC",
        "#c-Luce|?b-versione|@b-versione|!f-versione|@f-ok|?e-f-frase|=f-frase:Anche a metà|=f-versione:0.1|@f-ok|?e-f-versione|=f-versione:0.2|@f-ok|?scheda-vers|?b-versione")])
      let fine = attendi(s.trace, "sonda Q:b-versione assente", 30)
      sleep(500)
      raccogli(s)
      let sonde = sondeP(s)
      rec("AC-221", "il bottone c'è; il numero è già riempito con 0.2; frase vuota e numero uguale a quello di adesso sono rifiutati con il loro messaggio",
        fine and sonde.len >= 6 and sonde[0] == "b-versione visibile Nuova versione" and sonde[1] == "f-versione acceso valore=0.2" and
        sonde[2] == "e-f-frase visibile Scrivi che cosa cambia, in una frase." and
        sonde[3] == "e-f-versione visibile È il numero di adesso (0.1): scrivine uno diverso.", $sonde)
      rec("AC-221", "una sola save, e Luce.csc è riga per riga: commento sopra, 0.2, STATUS HYPOTHESIS, il resto uguale",
        nSave(s) == 1 and leggiSe(d / "Luce.csc").splitLines() == attesaR.splitLines(), leggiSe(d / "Luce.csc"))
      rec("AC-221", "sotto il titolo: «nuova versione da approvare»; il bottone non c'è più",
        sonde.len >= 6 and sonde[4] == "scheda-vers visibile nuova versione da approvare" and sonde[5] == "b-versione assente", $sonde)
      let chk = runExe(bcdd, @["check", "--dir", ".", "Luce.csc"], d)
      rec("AC-221", "bcdd check sul risultato: nessun errore", chk.code == 0 and "esito: nessun errore" in chk.output, cut(chk.output))
      s.finisci()
    # Torna indietro dopo Nuova versione: `bcdd save --undo` rimette il testo esatto di prima e toglie Luce.csc.prima
    block:
      let d = cartellaLuce(rawR)
      let prima = fotografia(d)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "Lampada"], root, @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|@b-versione|=f-frase:Anche a metà|@f-ok|@b-annulla|@f-ok")])
      let fine = attendi(s.trace, "pagina 3", 30)
      sleep(500)
      raccogli(s)
      let p3 = paginaN(s, 3)
      rec("AC-221", "Torna indietro dopo Nuova versione riesce: Luce.csc è com'era, byte per byte, e Luce.csc.prima non c'è più",
        fine and "Non riuscito" notin p3 and "Scritti i file: Luce.csc" in p3 and leggiSe(d / "Luce.csc") == prima["Luce.csc"][0] and
        not fileExists(d / "Luce.csc.prima"), cut(p3[max(0, p3.len - 500) .. ^1]))
      rec("AC-221", "due lanci di save: la scrittura e `save --undo --expect`", azioniLanci(s).count("save") == 2 and
        righe(s.lanci).filterIt(it.startsWith("save ") and " --undo " in it).len == 1, $azioniLanci(s) & " " & $righe(s.lanci))
      s.finisci()
    # righe con una loro decisione: nessuna scelta all'inizio; una scelta torna gialla, l'altra resta verde; poi la riga gialla si cambia con il modulo
    block:
      let d = newWd0()
      copyFile(rf / "Luce.csc", d / "Luce.csc")
      writeFile(d / "Lampada.csc", lampadaC)
      ratifica(d, @[@["ratify", "Luce.csc", "--dir", ".", "--csc", "Luce", "g1", "D-9"], @["ratify", "Luce.csc", "--dir", ".", "--csc", "Luce", "g2", "D-8"]])
      let base = readFile(d / "Luce.csc")
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d, "Lampada"], root, @[("BCDD_EDITOR_PROVA_CLIC",
        "#c-Luce|@b-versione|?scheda-modulo|!v-sel-g1|!v-sel-g2|=f-frase:Più pronta|=f-versione:0.2|@v-sel-g1|@f-ok|#r-11|=f-frase:Una pressione accende subito la luce|@f-ok")])
      let fine = attendi(s.trace, "pagina 3", 30)
      sleep(500)
      raccogli(s)
      let sonde = sondeP(s)
      rec("AC-221", "l'elenco: «Rimetti da approvare anche queste…», g1 e g2 con la loro frase, nessuna casella scelta",
        sonde.len >= 3 and "Rimetti da approvare anche queste (per poterle cambiare)" in sonde[0] and "Promessa g1: «Una pressione accende la luce»" in sonde[0] and
        "Promessa g2:" in sonde[0] and sonde[1] == "v-sel-g1 acceso scelto=false" and sonde[2] == "v-sel-g2 acceso scelto=false", $sonde)
      let attesa = base.replace("CSC Luce VERSION 0.1", "-- VERSION 0.2: Più pronta\nCSC Luce VERSION 0.2").replace("g1 STATUS RATIFIED BY D-9:", "g1 STATUS HYPOTHESIS:").
        replace("\"Una pressione accende la luce\"\n                VERIFY", "\"Una pressione accende subito la luce\"\n" & repeat(' ', "  GUARANTEE g1 STATUS HYPOTHESIS: ".len) & "VERIFY")
      rec("AC-221", "g1 scelta e poi cambiata con il modulo: due save; g2 resta approvata con la sua decisione; file riga per riga",
        fine and nSave(s) == 2 and leggiSe(d / "Luce.csc").splitLines() == attesa.splitLines() and "g2 STATUS RATIFIED BY D-8:" in attesa, leggiSe(d / "Luce.csc"))
      let chk = runExe(bcdd, @["check", "--dir", ".", "Luce.csc"], d)
      rec("AC-221", "bcdd check sul risultato: nessun errore", chk.code == 0 and "esito: nessun errore" in chk.output, cut(chk.output))
      s.finisci()

  # --- AC-196: la rete
  block:
    let (o, c) = execCmdEx("unshare -rn " & quoteShell(getAppFilename()) & " --rete-interna", workingDir = root)
    var conn = -1
    var stray: seq[string]
    var pagina, viva = false
    for l in o.splitLines():
      if l.startsWith("CONNESSIONI "): conn = parseInt(l[12 .. ^1])
      if l.startsWith("STRAY "): stray.add l[6 .. ^1]
      if l == "PAGINA true": pagina = true
      if l == "VIVA true": viva = true
    rec("AC-196", "la sessione dentro unshare -rn gira, con la pagina disegnata", pagina and c == 0, "codice " & $c & " " & cut(o))
    rec("AC-196", "l'ascoltatore riceve 0 connessioni", conn == 0, "connessioni " & $conn)
    rec("AC-196", "ss non mostra mai un socket oltre all'ascoltatore, nessuno in ascolto dell'editor", stray.len == 0, stray.join(" | "))
    rec("AC-196", "l'editor è rimasto vivo per tutta la sonda", viva, o)

# la scelta grafica letta dalla traccia, e la memoria dei check contata sui lanci
if xvfbOk:
  # AC-222: sotto Xvfb il display è :N, quindi locale; la variabile dell'editor e quella di WebKit cambiano la scelta
  for (nome, extra, atteso) in [("senza variabili: locale, composizione spenta", newSeq[(string, string)](), "remoto=false politica=pgSpenta"),
      ("BCDD_EDITOR_COMPOSITING=on", @[("BCDD_EDITOR_COMPOSITING", "on")], "remoto=false politica=pgAccesa"),
      ("WEBKIT_DISABLE_COMPOSITING_MODE nell'ambiente: non si tocca", @[("WEBKIT_DISABLE_COMPOSITING_MODE", "1")], "remoto=false politica=pgPredefinita")]:
    var s = nuovaSessione()
    let pronto = apriEPronto(s, @["--dir", "prove/f3/luce", "LuceScale"], root, extra)
    rec("AC-222", "la finestra si apre (" & nome & ")", pronto, cut(leggiSe(s.dir / "errori")))
    rec("AC-222", "la traccia dice la scelta: " & nome, ("grafica " & atteso) in leggiSe(s.trace), cut(leggiSe(s.trace)))
    s.finisci()
  # AC-223: due azioni di fila. All'apertura 8 check (cartella fredda); la rilettura di ogni azione si risponde dalla memoria,
  # dopo ogni scrittura si rileggono gli 8 file più quello nuovo
  block:
    let d = copiaCartella(root / "prove" / "f3" / "luce")
    var s = nuovaSessione()
    s.avviaEditor(@["--dir", d, "LuceScale"], root, @[("BCDD_EDITOR_PROVA_CLIC",
      "@b-nuova|=f-nome:Alfa|=f-scopo:Un caso|@f-ok|@b-nuova|=f-nome:Beta|=f-scopo:Un altro caso|@f-ok")])
    let fine = attendi(s.trace, "pagina 3", 30)
    rec("AC-223", "i tre disegni (apertura e due azioni)", fine, cut(leggiSe(s.dir / "errori")) & cut(leggiSe(s.trace), 500))
    sleep(300)
    raccogli(s)
    let az = azioniLanci(s)
    rec("AC-223", "lanci: 8 check all'apertura, poi (rilettura dalla memoria) solo la scrittura e i check dopo di essa: 8+9+10 check, 2 scritture",
      az.count("check") == 8 + 9 + 10 and az.count("new") + az.count("save") == 2, $az.count("check") & " check, " & $az)
    rec("AC-223", "la traccia dice che la rilettura dell'azione è venuta dalla memoria (8 volte per azione)",
      righe(s.trace).countIt("check_in_memoria" in it) >= 16, $righe(s.trace).countIt("check_in_memoria" in it))
    rec("AC-223", "i file nuovi ci sono e sono quelli di `bcdd new`", fileExists(d / "Alfa.csc") and fileExists(d / "Beta.csc"), "")
    let pag3 = paginaN(s, 3)
    rec("AC-223", "l'ultimo disegno mostra Alfa e Beta", "Alfa" in pag3 and "Beta" in pag3, cut(pag3))
    s.finisci()
  # AC-223: una scrittura fatta da un altro programma fra due azioni non si perde (la memoria non serve il vecchio)
  block:
    let d = copiaCartella(root / "prove" / "f3" / "luce")
    var s = nuovaSessione()
    s.avviaEditor(@["--dir", d, "LuceScale"], root, @[("BCDD_EDITOR_PROVA_CLIC",
      "@b-nuova|=f-nome:Alfa|=f-scopo:Un caso|@f-ok|~|@b-pubblico|=f-csc:Canale|=f-lato:OFFERS|@f-ok")])
    let attesa = attendi(s.trace, "attesa_fuoco", 30)
    rec("AC-223", "la prima azione è fatta e la prova aspetta il fuoco", attesa, cut(leggiSe(s.dir / "errori")) & cut(leggiSe(s.trace), 500))
    if attesa:
      let w = trovaFinestra(display, "bcdd-editor")
      writeFile(d / "Alfa.csc", leggiSe(d / "Alfa.csc").replace("Un caso", "Un caso cambiato fuori"))
      focusAltrove(display, w)
      let fine = attendi(s.trace, "pagina 4", 30)
      rec("AC-223", "dopo la scrittura esterna e la seconda azione: quattro disegni", fine, cut(leggiSe(s.dir / "errori")) & cut(leggiSe(s.trace), 700))
      sleep(300)
      rec("AC-223", "il disegno dopo la scrittura esterna ha il testo nuovo, non quello in memoria", "Un caso cambiato fuori" in paginaN(s, 3), cut(paginaN(s, 3)))
      rec("AC-223", "la seconda azione (+ Connettore pubblico su Alfa) riesce sul file com'è adesso: ha il testo di fuori e il connettore nuovo",
        "Un caso cambiato fuori" in leggiSe(d / "Alfa.csc") and "OFFERS Canale" in leggiSe(d / "Alfa.csc") and "Non riuscito" notin paginaN(s, 4) and
        "mentre lo leggevo" notin paginaN(s, 4), cut(leggiSe(d / "Alfa.csc")) & cut(paginaN(s, 4)))
    s.finisci()
  # AC-223: «Torna indietro» non rimette il disegno di prima dalla memoria: la scheda torna ad avere la promessa tolta
  block:
    let d = copiaCartella(root / "prove" / "f3" / "luce")
    var s = nuovaSessione()
    s.avviaEditor(@["--dir", d, "LuceScale"], root, @[("BCDD_EDITOR_PROVA_CLIC", "@t-dentro|#p-lampada|#r-5|@f-togli|@f-ok|@b-annulla|@f-ok")])
    let fine = attendi(s.trace, "pagina 3", 30)
    rec("AC-223", "togli la promessa e torna indietro: tre disegni", fine, cut(leggiSe(s.dir / "errori")) & cut(leggiSe(s.trace), 500))
    const promessa = "Dopo un accendi la luce è piena"
    rec("AC-223", "dopo «togli» la scheda non ha più la promessa; dopo «torna indietro» ce l'ha di nuovo",
      promessa notin paginaN(s, 2) and promessa in paginaN(s, 3), "")
    s.finisci()

# il tasto destro non apre un menu (il numero delle finestre visibili non cambia)
if xvfbOk:
  var s = nuovaSessione()
  let pronto = apriEPronto(s, @["--dir", "prove/f3/luce", "LuceScale"], root)
  if pronto:
    let w = trovaFinestra(display, "bcdd-editor")
    sleep(1000)
    proc visibili(): int = xdo(display, @["search", "--onlyvisible", "--name", ""]).splitLines().filterIt(it.len > 0).len
    let prima = visibili()
    discard xdo(display, @["mousemove", "--window", w, "300", "300", "click", "3"])
    sleep(1500)
    let dopo = visibili()
    rec("AC-196", "il tasto destro sulla vista non apre finestre (menu): visibili prima e dopo uguali", w.len > 0 and prima >= 1 and prima == dopo,
      "prima " & $prima & " dopo " & $dopo)
  else: rec("AC-196", "il tasto destro: la finestra si apre", false, cut(leggiSe(s.dir / "errori")))
  s.finisci()

# 080:7:10 AC-227..AC-230: l'albero delle entità, la ricerca, Metti dentro, Sposta in, Togli l'entità.
# Una cartella di prova con un'entità in due posti (Pulsante), un giro (Ciclo e Figlio), un posto senza entità (voce : Altoparlante)
# e due entità con righe approvate (Saldata, Padre). Il trascinamento si prova qui con gli eventi del trascinamento (a mano lo prova l'operatore).
const
  alAscensore = "ENTITY Ascensore VERSION 0.1\n  PURPOSE \"La cabina\"\n  COMPOSED OF\n    su    : Pulsante\n    giu   : Pulsante\n    motore : Motore\nEND\n"
  alCitofono = "ENTITY Citofono VERSION 0.1\n  PURPOSE \"Il citofono\"\n  COMPOSED OF\n    pulsante : Pulsante\n    voce : Altoparlante\nEND\n"
  alPulsante = "ENTITY Pulsante VERSION 0.1\n  PURPOSE \"Il pulsante\"\nEND\n"
  alMotore = "ENTITY Motore VERSION 0.1\n  PURPOSE \"Il motore\"\nEND\n"
  alCavo = "ENTITY Cavo VERSION 0.1\n  PURPOSE \"Un cavo\"\nEND\n"
  alCiclo = "ENTITY Ciclo VERSION 0.1\n  PURPOSE \"Un giro\"\n  COMPOSED OF\n    figlio : Figlio\nEND\n"
  alFiglio = "ENTITY Figlio VERSION 0.1\n  PURPOSE \"Dentro il giro\"\n  COMPOSED OF\n    ciclo : Ciclo\nEND\n"
  alSaldata = "ENTITY Saldata VERSION 0.1\n  PURPOSE \"Una entità con una promessa approvata\"\n  GUARANTEE s1 STATUS RATIFIED BY D-1: VERBAL \"Fa quello che deve\"\n                VERIFY BY INSPECTION \"il rapporto\"\nEND\n"
  alPadre = "ENTITY Padre VERSION 0.1\n  PURPOSE \"Un contenitore con una promessa approvata\"\n  COMPOSED OF\n    figlia : Figlia\n  GUARANTEE p1 STATUS RATIFIED BY D-1: VERBAL \"Contiene la figlia\"\n                VERIFY BY INSPECTION \"il rapporto\"\nEND\n"
  alFiglia = "ENTITY Figlia VERSION 0.1\n  PURPOSE \"La figlia\"\nEND\n"

proc cartellaAlbero(): string =
  let d = newWd0()
  for (n, t) in [("Ascensore", alAscensore), ("Citofono", alCitofono), ("Pulsante", alPulsante), ("Motore", alMotore), ("Cavo", alCavo),
      ("Ciclo", alCiclo), ("Figlio", alFiglio), ("Saldata", alSaldata), ("Padre", alPadre), ("Figlia", alFiglia)]:
    writeFile(d / (n & ".csc"), t)
  d

proc sondeDi(s: Sess): seq[string] = leggiSe(s.trace).splitLines().filterIt("sonda Q:" in it).mapIt(it[it.find("sonda Q:") + 8 .. ^1])

proc sessAlbero(d, clic, attesa: string): Sess =
  result = nuovaSessione()
  result.avviaEditor(@["--dir", d], root, @[("BCDD_EDITOR_PROVA_CLIC", clic)])
  discard attendi(result.trace, attesa, 40)
  sleep(500)
  raccogli(result)

block:
  # AC-227: l'albero (8.2) e la ricerca (8.3)
  let d = cartellaAlbero()
  let prima = fotografia(d)
  var s = sessAlbero(d, "^|#tri:Ciclo/figlio|^|=albero-cerca:puls|^|:albero-cerca:Escape|!albero-cerca|=albero-cerca:motore|:albero-cerca:Enter|?scheda-nome|" &
    "=albero-cerca:|#alb:Ascensore/su|!b-sposta|@b-albero|^|@b-albero|^|=albero-cerca:zzz|^", "sonda Q:^albero aperto larg=196 righe=0")
  let q = sondeDi(s)
  let ok = q.len >= 9
  rec("AC-227", "la sessione risponde a tutte le sonde", ok, cut($q, 600))
  if ok:
    let a0 = q[0]
    proc pos(t, x: string): int = t.find(x)
    rec("AC-227", "in cima le entità che non occupano posti, in ordine alfabetico; Pulsante e Motore, che occupano posti, non sono in cima",
      pos(a0, "1:Ascensore") in 1 .. pos(a0, "1:Cavo") and pos(a0, "1:Cavo") < pos(a0, "1:Citofono") and "1:Pulsante" notin a0 and "1:Motore" notin a0 and "1:Figlia" notin a0, cut(a0, 500))
    rec("AC-227", "sotto Ascensore i suoi posti nell'ordine di COMPOSED OF, come «posto — Entità» (pulsante : Pulsante è solo «Pulsante»)",
      pos(a0, "2:su — Pulsante") < pos(a0, "2:giu — Pulsante") and pos(a0, "2:giu — Pulsante") < pos(a0, "2:Motore") and "1:Citofono>[sospesa] | 2:Pulsante[" in a0, cut(a0, 500))
    rec("AC-227", "un'entità in più posti ha il segno ≡ con «anche in: …»; il pallino dà lo stato (chiusa, sospesa)",
      "≡(anche in: Ascensore (giu), Citofono)" in a0 and "≡(anche in: Ascensore (su, giu))" in a0 and "1:Ascensore>[chiusa]" in a0 and "1:Citofono>[sospesa]" in a0, cut(a0, 500))
    rec("AC-227", "un posto senza entità nella cartella è grigio, «parte mancante»", "2:voce — Altoparlante[mancante]{parte mancante" in a0, cut(a0, 500))
    rec("AC-227", "un giro: il ciclo si apre una volta e il ramo ripetuto ha ↻ e non si apre oltre",
      "1:Ciclo>[chiusa]" in a0 and "2:Figlio=[chiusa]" in a0 and "3:Ciclo[chiusa]{↻(" in q[1] and "4:" notin q[1], cut(q[1], 500))
    rec("AC-227", "la ricerca «puls»: i rami che portano a Pulsante, aperti, con la parte che combacia (Puls); niente Cavo né Motore",
      "<Puls>" in q[2] and "righe=5" in q[2] and "2:su — Pulsante" in q[2] and "Cavo" notin q[2] and "Motore" notin q[2], cut(q[2], 500))
    rec("AC-227", "Esc svuota il campo", q[3].endsWith("valore="), q[3])
    rec("AC-227", "Invio sceglie il primo risultato: la scheda è Motore", "Motore" in q[4], q[4])
    rec("AC-227", "un posto scelto nell'albero mostra «Sposta in…» nella scheda", "acceso" in q[5], q[5])
    rec("AC-227", "il bottone chiude e riapre il riquadro", "chiuso" in q[6] and "aperto" in q[7] and "righe=14" in q[7], q[6][0 .. 30] & " / " & q[7][0 .. 30])
    rec("AC-227", "una ricerca senza risultati non mostra nessuna riga", "righe=0" in q[8], q[8])
  rec("AC-227", "l'albero non scrive niente: file uguali, nessun save", fotografia(d) == prima and azioniLanci(s).count("save") == 0, $azioniLanci(s))
  s.finisci()

block:
  # AC-228: Metti dentro e Sposta in, con il bottone e con il trascinamento, e Torna indietro
  let orig = cartellaAlbero()
  let clicMetti = "#alb:Cavo|@b-metti|?f-dove-Pulsante|?f-dove-Cavo|=f-cerca:cit|@f-dove-Citofono|?f-frase|=f-posto:cavo|@f-ok"
  let citMetti = alCitofono.replace("    voce : Altoparlante\n", "    voce : Altoparlante\n    cavo : Cavo\n")
  block:
    let d = cartellaAlbero()
    var s = sessAlbero(d, clicMetti, "pagina 2")
    let q = sondeDi(s)
    rec("AC-228", "Metti dentro con il bottone: Citofono.csc ha il posto nuovo, riga per riga; gli altri file sono quelli di prima",
      readFile(d / "Citofono.csc").splitLines() == citMetti.splitLines() and readFile(d / "Cavo.csc") == alCavo and readFile(d / "Ascensore.csc") == alAscensore, readFile(d / "Citofono.csc"))
    rec("AC-228", "un solo save; la frase dice «Metto Cavo dentro Citofono, al posto:» e il nome proposto è «cavo»; l'elenco non offre Cavo (se stesso)",
      azioniLanci(s).count("save") == 1 and q.len >= 3 and "Metto Cavo dentro Citofono, come parte con il nome:" in q[2] and "assente" in q[1], $azioniLanci(s) & " " & cut($q, 300))
    s.finisci()
  block:
    let d = cartellaAlbero()
    var s = sessAlbero(d, clicMetti & "|@b-annulla|@f-ok", "pagina 3")
    rec("AC-228", "Torna indietro rimette Citofono.csc com'era (byte per byte); un save in più", readFile(d / "Citofono.csc") == alCitofono and azioniLanci(s).count("save") == 2, $azioniLanci(s))
    s.finisci()
  block:
    # le regole: nome già usato, un giro, un'entità dentro se stessa
    let d = cartellaAlbero()
    let prima = fotografia(d)
    var s = sessAlbero(d, "#alb:Cavo|@b-metti|@f-dove-Ascensore|=f-posto:su|?e-f-posto|!f-ok|#alb:Ascensore|@b-metti|?f-dove-Pulsante|?f-dove-Motore|?f-dove-Ascensore|?f-dove-Cavo", "sonda Q:f-dove-Cavo")
    let q = sondeDi(s)
    rec("AC-228", "nome già usato: il modulo lo dice prima di scrivere e «Sì» è spento",
      q.len >= 2 and "Ascensore ha già una parte che si chiama su." in q[0] and "spento" in q[1], cut($q, 300))
    rec("AC-228", "Ascensore non si mette dentro se stessa né dentro ciò che contiene (Pulsante, Motore): l'elenco non li offre; Cavo sì",
      q.len >= 6 and "assente" in q[2] and "assente" in q[3] and "assente" in q[4] and "visibile" in q[5], cut($q, 400))
    rec("AC-228", "nessuna scrittura", fotografia(d) == prima and azioniLanci(s).count("save") == 0, $azioniLanci(s))
    s.finisci()
  block:
    # il trascinamento: un'entità su un'altra apre «Metti dentro»; un posto su un'entità apre «Sposta in»; un giro non è un bersaglio
    let d = cartellaAlbero()
    let prima = fotografia(d)
    var s = sessAlbero(d, "/Cavo>Ascensore|?f-frase|@f-annulla|/Ascensore>Ascensore/su|/Citofono/pulsante>Cavo|?f-frase|@f-annulla|/Cavo>Cavo|/Padre>Ciclo/figlio/ciclo", "sonda Q:/trascina rifiutato")
    sleep(700)
    let q = sondeDi(s)
    let ok = q.len >= 7
    rec("AC-228", "il trascinamento: Cavo su Ascensore è accettato e apre «Metto Cavo dentro Ascensore»", ok and "accettato" in q[0] and "Metto Cavo dentro Ascensore, come parte con il nome:" in q[1], cut($q, 400))
    rec("AC-228", "Ascensore su un posto di ciò che contiene farebbe un giro: rifiutato", ok and "rifiutato" in q[2], cut($q, 400))
    rec("AC-228", "un posto (pulsante di Citofono) su Cavo apre «Sposto la parte pulsante (Pulsante) da Citofono a Cavo»", ok and "accettato" in q[3] and "Sposto la parte pulsante (Pulsante) da Citofono a Cavo, con il nome:" in q[4], cut($q, 400))
    rec("AC-228", "un'entità su se stessa non è un bersaglio", ok and "rifiutato" in q[5], cut($q, 400))
    rec("AC-228", "il trascinamento da solo non scrive: file uguali", fotografia(d) == prima and azioniLanci(s).count("save") == 0, $azioniLanci(s))
    s.finisci()
  block:
    # Sposta in con il bottone: un posto passa da Citofono ad Ascensore (due save: prima l'arrivo, poi la partenza), poi Torna indietro
    let d = cartellaAlbero()
    let clic = "#alb:Citofono/pulsante|@b-sposta|@f-dove-Ascensore|?f-frase|=f-posto:pulsanteC|@f-ok"
    var s = sessAlbero(d, clic, "pagina 2")
    let q = sondeDi(s)
    rec("AC-228", "Sposta in: il posto è tolto da Citofono.csc e scritto in Ascensore.csc, riga per riga",
      readFile(d / "Citofono.csc").splitLines() == alCitofono.replace("    pulsante : Pulsante\n", "").splitLines() and
      readFile(d / "Ascensore.csc").splitLines() == alAscensore.replace("    motore : Motore\n", "    motore : Motore\n    pulsanteC : Pulsante\n").splitLines(), readFile(d / "Citofono.csc") & readFile(d / "Ascensore.csc"))
    rec("AC-228", "due save, nessun altro file toccato; la frase dice da dove a dove", azioniLanci(s).count("save") == 2 and q.len >= 1 and "Sposto la parte pulsante (Pulsante) da Citofono a Ascensore, con il nome:" in q[0] and
      readFile(d / "Cavo.csc") == alCavo, $azioniLanci(s) & cut($q, 200))
    s.finisci()
    let d2 = cartellaAlbero()
    var s2 = sessAlbero(d2, clic & "|@b-annulla|@f-ok", "pagina 3")
    rec("AC-228", "Torna indietro rimette tutti e due i file com'erano", readFile(d2 / "Citofono.csc") == alCitofono and readFile(d2 / "Ascensore.csc") == alAscensore and azioniLanci(s2).count("save") == 4, $azioniLanci(s2))
    s2.finisci()
  block:
    # Sposta in con il trascinamento in un'entità senza COMPOSED OF: la riga e COMPOSED OF entrano in Cavo
    let d = cartellaAlbero()
    var s = sessAlbero(d, "/Citofono/pulsante>Cavo|@f-ok", "pagina 2")
    rec("AC-228", "trascinando un posto su Cavo: COMPOSED OF e il posto entrano in Cavo.csc, il posto esce da Citofono.csc",
      readFile(d / "Cavo.csc").splitLines() == alCavo.replace("  PURPOSE \"Un cavo\"\n", "  PURPOSE \"Un cavo\"\n  COMPOSED OF\n    pulsante : Pulsante\n").splitLines() and
      readFile(d / "Citofono.csc").splitLines() == alCitofono.replace("    pulsante : Pulsante\n", "").splitLines(), readFile(d / "Cavo.csc") & readFile(d / "Citofono.csc"))
    s.finisci()

block:
  # AC-229: Togli l'entità (8.5): i posti, il file, i connettori che restano, Torna indietro, i rifiuti, la marcia indietro da sola
  block:
    let d = cartellaAlbero()
    let clic = "#alb:Ascensore/su|@b-togli-entita|?f-frase|@f-ok|^"
    var s = sessAlbero(d, clic, "sonda Q:^albero")
    let q = sondeDi(s)
    rec("AC-229", "la conferma elenca i posti: «L'entità Pulsante è usata come 3 parti: su e giu in Ascensore, pulsante in Citofono. Tolgo anche queste parti.»",
      q.len >= 1 and "L'entità Pulsante è usata come 3 parti: su e giu in Ascensore, pulsante in Citofono. Tolgo anche queste parti." in q[0], cut($q, 400))
    rec("AC-229", "i file attesi: Ascensore.csc senza su e giu, Citofono.csc senza pulsante, Pulsante.csc tolto (con Pulsante.csc.prima «tolto»)",
      readFile(d / "Ascensore.csc").splitLines() == alAscensore.replace("    su    : Pulsante\n    giu   : Pulsante\n", "").splitLines() and
      readFile(d / "Citofono.csc").splitLines() == alCitofono.replace("    pulsante : Pulsante\n", "").splitLines() and not fileExists(d / "Pulsante.csc") and
      leggiSe(d / "Pulsante.csc.prima") == "tolto\n" & alPulsante, "")
    rec("AC-229", "tre save (due entità che contengono, poi il file); l'albero non ha più Pulsante; Motore resta sotto Ascensore",
      azioniLanci(s).count("save") == 3 and q.len >= 2 and "Pulsante" notin q[1].replace("Pulsante.csc", "") and "2:Motore" in q[1], $azioniLanci(s) & cut($q, 400))
    s.finisci()
    let d2 = cartellaAlbero()
    var s2 = sessAlbero(d2, clic & "|@b-annulla|@f-ok", "pagina 3")
    rec("AC-229", "Torna indietro: il file torna, i posti tornano, tutti e tre byte per byte; FILE.prima di Pulsante non c'è più",
      readFile(d2 / "Ascensore.csc") == alAscensore and readFile(d2 / "Citofono.csc") == alCitofono and readFile(d2 / "Pulsante.csc") == alPulsante and
      not fileExists(d2 / "Pulsante.csc.prima") and azioniLanci(s2).count("save") == 6, $azioniLanci(s2))
    s2.finisci()
  block:
    # un'entità senza posti: la frase semplice; i connettori restano
    let d = cartellaAlbero()
    writeFile(d / "Cavo.csc", alCavo.replace("  PURPOSE \"Un cavo\"\n", "  PURPOSE \"Un cavo\"\n  OFFERS Segnale\n"))
    discard runExe(bcdd, @["new", "Segnale"], d)
    var s = sessAlbero(d, "#alb:Cavo|@b-togli-entita|?f-frase|@f-ok", "pagina 2")
    let q = sondeDi(s)
    rec("AC-229", "«Tolgo l'entità Cavo? Il file Cavo.csc viene tolto; i suoi connettori restano.»; Cavo.csc se ne va e Segnale.csc resta",
      q.len >= 1 and "Tolgo l'entità Cavo? Il file Cavo.csc viene tolto; i suoi connettori restano." in q[0] and not fileExists(d / "Cavo.csc") and fileExists(d / "Segnale.csc") and
      azioniLanci(s).count("save") == 1, cut($q, 300) & $azioniLanci(s))
    s.finisci()
  block:
    # i rifiuti: righe approvate, scritto niente
    let d = cartellaAlbero()
    let prima = fotografia(d)
    var s = sessAlbero(d, "#alb:Saldata|@b-togli-entita|?f-frase|?f-ok|#alb:Padre/figlia|@b-togli-entita|?f-frase|?f-ok|@f-annulla|@b-sposta|?f-frase|?f-ok", "sonda Q:f-ok assente", )
    sleep(800)
    let q = sondeDi(s)
    let ok = q.len >= 6
    rec("AC-229", "entità con righe approvate: «Saldata ha righe approvate: non si toglie» e niente «Sì»", ok and "Saldata ha righe approvate: non si toglie." in q[0] and "assente" in q[1], cut($q, 500))
    rec("AC-229", "posto in un'entità con righe approvate: il rifiuto dice il posto e il motivo",
      ok and "Padre ha righe approvate: la parte figlia non si toglie, quindi non tolgo Figlia." in q[2] and "assente" in q[3], cut($q, 500))
    rec("AC-229", "«Sposta in…» dallo stesso posto: «Padre ha righe approvate: la parte figlia non si toglie.»", ok and "Padre ha righe approvate: la parte figlia non si toglie." in q[4] and "assente" in q[5], cut($q, 500))
    rec("AC-229", "nessun file scritto, nessun save", fotografia(d) == prima and azioniLanci(s).count("save") == 0, $azioniLanci(s))
    s.finisci()
  block:
    # una scrittura che fallisce a metà: i file già scritti tornano da soli e lo dice. Pulsante.csc.prima è una cartella: `save --remove` non può scrivere il suo «prima»
    let d = cartellaAlbero()
    createDir(d / "Pulsante.csc.prima")
    var s = sessAlbero(d, "#alb:Ascensore/su|@b-togli-entita|@f-ok|?esito|!b-annulla", "sonda Q:b-annulla")
    let q = sondeDi(s)
    rec("AC-229", "il file non si toglie e i file dei posti tornano com'erano; l'esito lo dice",
      readFile(d / "Ascensore.csc") == alAscensore and readFile(d / "Citofono.csc") == alCitofono and readFile(d / "Pulsante.csc") == alPulsante and
      q.len >= 2 and "Non riuscito" in q[0] and "Ho rimesso com'erano i file già scritti." in q[0], cut($q, 600))
    rec("AC-229", "non c'è niente a cui tornare indietro (l'azione è stata ritirata)", q.len >= 2 and "spento" in q[1], cut($q, 300))
    s.finisci()

block:
  # AC-230: con l'albero aperto nessuna barra va a capo (la misura a 1024 e 1280 è nelle foto; qui alla larghezza di apertura)
  let d = cartellaAlbero()
  var s = sessAlbero(d, "#alb:Ascensore|@t-dentro|%|^", "sonda Q:^albero")
  let q = sondeDi(s)
  var ok = false
  if q.len >= 2:
    let r = q[0]
    let h = parseInt(r.split(" h=")[1].split(" ")[0])
    let sez = r.split("sez_testa=")[1].split(" ")[0].split(",").mapIt(parseInt(it.strip()))
    let azH = parseInt(r.split("azioni_h=")[1].split(" ")[0])
    ok = r.contains("righe_testo=1 ") and h <= 36 and sez.len == 3 and sez.allIt(it <= 19) and r.contains("azioni_righe=1 ") and azH <= 28 and "aperto" in q[1]
  rec("AC-230", "albero aperto: barra in alto, testa di Entità, Banco e Scheda e barra dei bottoni del Banco su una riga", ok, cut($q, 500))
  s.finisci()

block:
  # AC-231: Porta fuori (8.8): il bottone, la fascia, la conferma con dove resta, Torna indietro, il rifiuto su righe approvate
  block:
    let d = cartellaAlbero()
    let clic = "#alb:Ascensore/motore|@b-porta-fuori|?f-frase|@f-ok|^"
    var s = sessAlbero(d, clic, "sonda Q:^albero")
    let q = sondeDi(s)
    rec("AC-231", "la conferma di un'entità in un solo posto: «Porto fuori Motore da Ascensore? Tolgo la parte motore da Ascensore; il file Motore.csc resta.», senza «resta in»",
      q.len >= 1 and "Porto fuori Motore da Ascensore? Tolgo la parte motore da Ascensore; il file Motore.csc resta." in q[0] and "resta in" notin q[0], cut($q, 400))
    rec("AC-231", "Ascensore.csc senza la riga motore, riga per riga; un solo save; gli altri file uguali",
      readFile(d / "Ascensore.csc").splitLines() == alAscensore.replace("    motore : Motore\n", "").splitLines() and azioniLanci(s).count("save") == 1 and
      readFile(d / "Motore.csc") == alMotore and readFile(d / "Citofono.csc") == alCitofono, $azioniLanci(s) & readFile(d / "Ascensore.csc"))
    rec("AC-231", "Motore sale al primo livello dell'albero ed è la scelta", q.len >= 2 and "1:Motore*" in q[1], cut($q, 600))
    s.finisci()
    let d2 = cartellaAlbero()
    var s2 = sessAlbero(d2, clic & "|@b-annulla|@f-ok", "pagina 3")
    rec("AC-231", "Torna indietro di un'azione rimette Ascensore.csc byte per byte (un save in più)", readFile(d2 / "Ascensore.csc") == alAscensore and azioniLanci(s2).count("save") == 2, $azioniLanci(s2))
    s2.finisci()
  block:
    # un'entità in più posti: la conferma dice dove resta; non sale al primo livello
    let d = cartellaAlbero()
    var s = sessAlbero(d, "#alb:Citofono/pulsante|@b-porta-fuori|?f-frase|@f-ok|^", "sonda Q:^albero")
    let q = sondeDi(s)
    rec("AC-231", "«Pulsante resta in: Ascensore.» nella conferma",
      q.len >= 1 and "Porto fuori Pulsante da Citofono? Tolgo la parte pulsante da Citofono; il file Pulsante.csc resta. Pulsante resta in: Ascensore." in q[0], cut($q, 400))
    rec("AC-231", "Citofono.csc senza pulsante; Pulsante non è al primo livello", readFile(d / "Citofono.csc").splitLines() == alCitofono.replace("    pulsante : Pulsante\n", "").splitLines() and
      q.len >= 2 and "1:Pulsante" notin q[1] and azioniLanci(s).count("save") == 1, cut($q, 600))
    s.finisci()
  block:
    # il rifiuto: Padre ha righe approvate, niente scritto, niente «Sì»
    let d = cartellaAlbero()
    let prima = fotografia(d)
    var s = sessAlbero(d, "#alb:Padre/figlia|@b-porta-fuori|?f-frase|?f-ok", "sonda Q:f-ok assente")
    let q = sondeDi(s)
    rec("AC-231", "Padre ha righe approvate: «Padre ha righe approvate: la parte figlia non si toglie.» e niente «Sì»; nessun file scritto",
      q.len >= 2 and "Padre ha righe approvate: la parte figlia non si toglie." in q[0] and "assente" in q[1] and fotografia(d) == prima and azioniLanci(s).count("save") == 0, cut($q, 400))
    s.finisci()
  block:
    # la fascia: a riposo nascosta; un posto trascinato la raggiunge e apre la stessa conferma; un'entità del primo livello no; il trascinamento da solo non scrive
    let d = cartellaAlbero()
    let prima = fotografia(d)
    var s = sessAlbero(d, "?fascia-fuori|/Ascensore/su>FUORI|?f-frase|@f-annulla|/Ascensore>FUORI", "sonda Q:/trascina rifiutato")
    sleep(500)
    let q = sondeDi(s)
    rec("AC-231", "la fascia «Fuori da tutte» è nascosta a riposo", q.len >= 1 and "nascosto" in q[0] and "Fuori da tutte" in q[0], cut($q, 300))
    rec("AC-231", "un posto lasciato sulla fascia: accettato, apre «Porto fuori Pulsante da Ascensore? …»", q.len >= 3 and "accettato" in q[1] and "Porto fuori Pulsante da Ascensore? Tolgo la parte su da Ascensore;" in q[2], cut($q, 500))
    rec("AC-231", "la fascia compare nel dragstart di un posto e non sposta il layout (overlay): albero e riga trascinata restano dove sono", q.len >= 2 and "fascia=visibile layout=fermo" in q[1], cut($q, 500))
    rec("AC-231", "un'entità del primo livello sulla fascia: rifiutato, la fascia non compare; nessun file scritto", q.len >= 4 and "rifiutato fascia=nascosta" in q[3] and fotografia(d) == prima and azioniLanci(s).count("save") == 0, cut($q, 500))
    s.finisci()
  block:
    # la barra dei bottoni del Banco con il posto scelto e il bottone in più: una riga, niente nel menu «Altro…» (alla larghezza di apertura; a 1024 vedi la misura xwd)
    let d = cartellaAlbero()
    var s = sessAlbero(d, "#alb:Citofono/pulsante|%", "sonda Q:%barra")
    let q = sondeDi(s)
    rec("AC-231", "con il posto scelto: «Sposta in…» e «Porta fuori…» sulla stessa riga della barra", q.len >= 1 and "azioni_righe=1 " in q[0] and "azioni_h=" in q[0], cut($q, 400))
    s.finisci()

# 080:7:10 AC-232..AC-234: il riquadro di Completa, i connettori non usati, lo scopo dal motivo
block:
  let rfD = root / "prove" / "f2" / "refine"
  let fintoD = root / "prove" / "f2" / "ULlmFinto.sh"
  proc cartellaD(): string =
    result = newWd0()
    copyFile(rfD / "Luce.csc", result / "Luce.csc")
    writeFile(result / "Lampada.csc", "ENTITY Lampada VERSION 0.1\n  PURPOSE \"La lampada\"\n  OFFERS Luce\nEND\n")
  proc ambD(s: Sess, extra: seq[(string, string)] = @[]): seq[(string, string)] =
    createDir s.dir / "aux"
    @[("BCDD_LLM", fintoD), ("BCDD_ATTESA_LLM", "30"), ("BCDD_ORA", "2026-10-16T18:00:00+02:00"),
      ("BCDD_REGISTRO", s.dir / "chiamate.tsv"), ("BCDD_FINTO_CONTA", s.dir / "aux" / "conta"),
      ("BCDD_FINTO_RISPOSTA", rfD / "risposte" / "buona.json"), ("BCDD_FINTO_RISPOSTA_2", rfD / "risposte" / "buona_seconda.json")] & extra
  proc nomiD(d: string): seq[string] =
    for f in walkFiles(d / "*"): (if not f.endsWith(".prima"): result.add f.extractFilename)
    result.sort()
  # AC-232 (10.1): il riquadro di Completa sparisce scegliendo un'altra cosa, il giro resta, tornando c'è «Riprendi»
  block:
    let d = cartellaD()
    var s = nuovaSessione()
    s.avviaEditor(@["--dir", d, "Lampada"], root, ambD(s) & @[("BCDD_EDITOR_PROVA_CLIC",
      "#c-Luce|@b-completa|?scheda-completa|#alb:Lampada|?scheda-completa|#c-Luce|@b-completa|?scheda-completa|@c-riprendi|?scheda-completa")])
    let fine = attendi(s.trace, "sonda Q:scheda-completa", 40)
    sleep(1500)
    raccogli(s)
    let q = sondeDi(s)
    rec("AC-232", "la prova arriva in fondo con le cinque sonde", fine and q.len >= 4, cut($q, 600) & cut(leggiSe(s.dir / "errori")))
    rec("AC-232", "nella Scheda di Luce il riquadro «Completa il connettore Luce» c'è", q.len >= 1 and "visibile" in q[0] and "Completa il connettore Luce" in q[0], cut($q, 300))
    rec("AC-232", "scegliendo Lampada il riquadro è nascosto", q.len >= 2 and "nascosto" in q[1], cut($q, 300))
    rec("AC-232", "tornando su Luce, Completa dice «C'è un giro di Completa lasciato a metà su il connettore Luce» e Riprendi lo mostra",
      q.len >= 4 and "lasciato a metà su il connettore Luce" in q[2] and "visibile" in q[3] and "Completa il connettore Luce" in q[3], cut($q, 600))
    rec("AC-232", "Luce.csc non è stato toccato e niente è stato salvato", readFile(d / "Luce.csc") == readFile(rfD / "Luce.csc") and azioniLanci(s).count("save") == 0, $azioniLanci(s))
    s.finisci()
  # AC-233 (10.2): il gruppo «Connettori non usati», la ricerca, Togli il connettore, Torna indietro, il rifiuto
  proc cartellaNU(): string =
    result = cartellaD()
    discard runExe(bcddProva, @["new", "Segnale"], result)
    discard runExe(bcddProva, @["new", "Spia"], result)
    writeFile(result / "Canale.csc", "CSC Canale VERSION 0.3\n  STATUS RATIFIED BY D-1\n  PURPOSE \"Un canale\"\n  CAPABILITY ricevi\n  EVENT OUT dato\n" &
      "  GUARANTEE c1: VERBAL \"Ogni dato arriva una volta sola\"\n                VERIFY BY INSPECTION \"i dati registrati\"\nEND\n")
  block:
    let d = cartellaNU()
    var s = sessAlbero(d, "^|=albero-cerca:spi|^|=albero-cerca:|#tri:@csc|^|#alb:@csc/Segnale|?scheda-nome|!b-togli-csc|#c-Luce|!b-togli-csc", "sonda Q:b-togli-csc assente")
    let q = sondeDi(s)
    let ok = q.len >= 6
    rec("AC-233", "la sessione risponde a tutte le sonde", ok, cut($q, 800))
    if ok:
      rec("AC-233", "in fondo all'albero «Connettori non usati (3)», chiuso: sono Canale, Segnale, Spia; Luce, usata da Lampada, non c'è",
        "Connettori non usati (3)=" in q[0] and "2:Canale" notin q[0] and "Luce" notin q[0].replace("Lampada", ""), cut(q[0], 500))
      rec("AC-233", "la ricerca «spi» lo apre e mostra Spia (con la parte che combacia)", "Connettori non usati (3)>" in q[1] and "2:Spia" in q[1] or "<Spi>" in q[1], cut(q[1], 500))
      rec("AC-233", "aperto: Canale, Segnale, Spia in ordine alfabetico", q[2].find("2:Canale") in 1 .. q[2].find("2:Segnale") and q[2].find("2:Segnale") < q[2].find("2:Spia"), cut(q[2], 500))
      rec("AC-233", "clic su Segnale: la Scheda è Segnale e c'è «Togli il connettore…»", "Segnale" in q[3] and "acceso" in q[4], cut($q, 400))
      rec("AC-233", "Luce, usata da Lampada, non ha il bottone", "assente" in q[5], cut($q, 400))
    s.finisci()
  block:
    let d = cartellaNU()
    let alSegnale = readFile(d / "Segnale.csc")
    let clic = "#tri:@csc|#alb:@csc/Segnale|@b-togli-csc|?f-frase|@f-ok|^"
    var s = sessAlbero(d, clic, "sonda Q:^albero")
    let q = sondeDi(s)
    rec("AC-233", "«Tolgo il connettore Segnale? Il file Segnale.csc viene tolto; nessuna entità lo usa.»", q.len >= 1 and "Tolgo il connettore Segnale? Il file Segnale.csc viene tolto; nessuna entità lo usa." in q[0], cut($q, 400))
    rec("AC-233", "Segnale.csc è tolto (con Segnale.csc.prima «tolto»), un save, gli altri file non cambiano; il gruppo dice 2",
      not fileExists(d / "Segnale.csc") and leggiSe(d / "Segnale.csc.prima") == "tolto\n" & alSegnale and azioniLanci(s).count("save") == 1 and fileExists(d / "Spia.csc") and
      q.len >= 2 and "Connettori non usati (2)" in q[1], cut($q, 500) & $azioniLanci(s))
    s.finisci()
    let d2 = cartellaNU()
    let al2 = readFile(d2 / "Segnale.csc")
    var s2 = sessAlbero(d2, clic & "|@b-annulla|@f-ok", "pagina 3")
    rec("AC-233", "Torna indietro rimette Segnale.csc byte per byte e toglie il .prima", readFile(d2 / "Segnale.csc") == al2 and not fileExists(d2 / "Segnale.csc.prima") and azioniLanci(s2).count("save") == 2, $azioniLanci(s2))
    s2.finisci()
  block:
    let d = cartellaNU()
    let prima = fotografia(d)
    var s = sessAlbero(d, "#tri:@csc|#alb:@csc/Canale|@b-togli-csc|?f-frase|?f-ok", "sonda Q:f-ok assente")
    let q = sondeDi(s)
    rec("AC-233", "Canale ha righe approvate: «Canale ha righe approvate: non si toglie.», niente «Sì», nessun file scritto",
      q.len >= 2 and "Canale ha righe approvate: non si toglie." in q[0] and "assente" in q[1] and fotografia(d) == prima and azioniLanci(s).count("save") == 0, cut($q, 400))
    s.finisci()
  # AC-234 (10.3): «Crea il connettore X» apre il modulo con lo scopo dal motivo; file atteso riga per riga; una sola azione per Torna indietro
  block:
    let d = cartellaD()
    var s = nuovaSessione()
    s.avviaEditor(@["--dir", d, "Lampada"], root, ambD(s, @[("BCDD_FINTO_RISPOSTA", rfD / "risposte" / "csc_a_parte.json")]) &
      @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|@b-completa|?scheda-completa|@c-crea-Pulsante|!f-scopo|?scheda-modulo|=f-scopo:Il pulsante che accende la luce|@f-ok")])
    let fine = attendi(s.trace, "azione csc_nuova", 40)
    sleep(500)
    raccogli(s)
    let q = sondeDi(s)
    rec("AC-234", "la prova arriva in fondo", fine and q.len >= 3, cut(leggiSe(s.dir / "errori")) & cut($q, 600))
    rec("AC-234", "il campo Scopo è già riempito con il motivo; il motivo intero sta sotto",
      q.len >= 3 and "valore=il pulsante ha una spia con stati e tempi suoi, che non sono quelli della luce" in q[1] and "Il motivo dell'LLM: il pulsante ha una spia" in q[2], cut($q, 600))
    let rif = newWd0()
    discard runExe(bcddProva, @["new", "Pulsante"], rif)
    let atteso = leggiSe(rif / "Pulsante.csc").splitLines().mapIt(if it.startsWith("  PURPOSE"): "  PURPOSE \"Il pulsante che accende la luce\"" else: it)
    rec("AC-234", "Pulsante.csc è quello di `bcdd new` con lo scopo scritto nel campo, riga per riga; un new e una save",
      leggiSe(d / "Pulsante.csc").splitLines() == atteso and azioniLanci(s).count("new") == 1 and azioniLanci(s).count("save") == 1, $azioniLanci(s))
    s.finisci()
    let d2 = cartellaD()
    var s2 = nuovaSessione()
    s2.avviaEditor(@["--dir", d2, "Lampada"], root, ambD(s2, @[("BCDD_FINTO_RISPOSTA", rfD / "risposte" / "csc_a_parte.json")]) &
      @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|@b-completa|@c-crea-Pulsante|@f-ok|@b-annulla|@f-ok")])
    discard attendi(s2.trace, "azione annulla", 40)
    sleep(500)
    raccogli(s2)
    rec("AC-234", "un solo Torna indietro rimette lo scopo di `bcdd new` (il file resta): due scritture annullate insieme",
      leggiSe(d2 / "Pulsante.csc") == leggiSe(rif / "Pulsante.csc") and azioniLanci(s2).count("save") == 2, $azioniLanci(s2))
    s2.finisci()
  # AC-236: Veloce (all'apertura) e Accurato passano l'opzione giusta; Riprendi usa e mostra il modello del giro
  block:
    let d = cartellaD()
    var s = nuovaSessione()
    s.avviaEditor(@["--dir", d, "Lampada"], root, ambD(s) & @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|!m-veloce|@b-completa|?scheda-completa|@c-lascia")])
    discard attendi(s.trace, "azione completa_chiudi", 40)
    sleep(500)
    raccogli(s)
    let q = sondeDi(s)
    let rv = righe(s.lanci).filterIt(it.startsWith("refine "))
    rec("AC-236", "all'apertura la scelta è Veloce; Completa passa `--modello veloce` (tempo 1)",
      q.len >= 1 and "acceso" in q[0] and rv.len >= 1 and rv[0].endsWith("--json Luce.csc --csc Luce --modello veloce"), cut($q, 300) & $rv)
    rec("AC-236", "il riquadro mostra «Modello del giro: Veloce»", q.len >= 2 and "Modello del giro: Veloce" in q[1], cut($q, 500))
    s.finisci()
    let d2 = cartellaD()
    var s2 = nuovaSessione()
    s2.avviaEditor(@["--dir", d2, "Lampada"], root, ambD(s2) & @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|@m-accurato|!m-accurato|@b-completa|?scheda-completa|@c-lascia")])
    discard attendi(s2.trace, "azione completa_chiudi", 40)
    sleep(500)
    raccogli(s2)
    let q2 = sondeDi(s2)
    let ra = righe(s2.lanci).filterIt(it.startsWith("refine "))
    rec("AC-236", "scegliendo Accurato, Completa passa `--modello accurato` e il riquadro dice «Modello del giro: Accurato»",
      ra.len >= 1 and ra[0].endsWith("--json Luce.csc --csc Luce --modello accurato") and q2.len >= 2 and "Modello del giro: Accurato" in q2[1], cut($q2, 500) & $ra)
    s2.finisci()
    # Riprendi: il giro è Accurato (fatto fuori dalla finestra), la scelta accanto a Completa è Veloce: Riprendi usa e mostra Accurato, senza --modello
    let d3 = cartellaD()
    var s3 = nuovaSessione()
    let env3 = ambD(s3)
    let r1 = runExe(bcddProva, @["refine", "--json", "Luce.csc", "--csc", "Luce", "--modello", "accurato"], d3, envPulito(env3))
    s3.avviaEditor(@["--dir", d3, "Lampada"], root, env3 & @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|@b-completa|@c-riprendi|?scheda-completa|!m-veloce")])
    discard attendi(s3.trace, "sonda Q:m-veloce", 40)
    sleep(300)
    raccogli(s3)
    let q3 = sondeDi(s3)
    let rr = righe(s3.lanci).filterIt(it.startsWith("refine ") and "--show" in it)
    rec("AC-236", "Riprendi mostra «Modello del giro: Accurato» anche con Veloce scelto accanto a Completa (la scelta è spenta mentre il giro è aperto); il --show non porta --modello",
      r1.code == 0 and q3.len >= 2 and "Modello del giro: Accurato" in q3[0] and "spento" in q3[1] and rr.len == 1 and "--modello" notin rr[0], r1.errout & cut($q3, 500) & $rr)
    s3.finisci()
  # AC-237: Completa da zero dallo scopo: righe d'interfaccia, promesse nuove, scopo da compilare
  proc cartellaSpia(scopo: string): string =
    result = newWd0()
    writeFile(result / "Spia.csc", readFile(rfD / "Spia_nuova.csc").replace("da scrivere: in una frase, di che cosa è responsabile Spia", scopo))
    writeFile(result / "Lampada.csc", "ENTITY Lampada VERSION 0.1\n  PURPOSE \"La lampada\"\n  OFFERS Spia\nEND\n")
  block:
    let d = cartellaSpia("La spia di un apparecchio")
    var s = nuovaSessione()
    s.avviaEditor(@["--dir", d, "Lampada"], root, ambD(s, @[("BCDD_FINTO_RISPOSTA", rfD / "risposte" / "interfaccia_da_zero.json")]) &
      @[("BCDD_EDITOR_PROVA_CLIC", "#c-Spia|@b-completa|?scheda-completa|@c-acc-i1|@c-acc-p1|?scheda-completa|@c-scrivi|?letto")])
    let fine = attendi(s.trace, "sonda Q:letto", 40)
    sleep(800)
    raccogli(s)
    let q = sondeDi(s)
    rec("AC-237", "la prova arriva in fondo", fine and q.len >= 2, cut(leggiSe(s.dir / "errori")) & cut(leggiSe(s.trace), 900))
    rec("AC-237", "tre carte «Riga d'interfaccia» con la riga e il motivo (la quarta, STATE accesa, ha il suo motivo), due «Promessa nuova» / «Presupposto nuovo»",
      q.len >= 1 and q[0].count("Riga d'interfaccia") == 3 and "STATE accesa : Boolean INITIAL false" in q[0] and "la spia è accesa o spenta" in q[0] and
      "TYPE Colore" in q[0] and "EVENT OUT cambio(colore: Colore)" in q[0] and "Promessa nuova" in q[0] and "Presupposto nuovo" in q[0] and "Precisa la promessa" notin q[0], cut($q, 900))
    rec("AC-237", "dopo Accetta: «2 righe accettate»", q.len >= 2 and "2 righe accettate" in q[1], cut(q[1] & "", 300))
    # l'oracolo: bcdd_prova da riga di comando, stessi passi, stesso file
    let d2 = cartellaSpia("La spia di un apparecchio")
    var sO = nuovaSessione()
    let env2 = ambD(sO, @[("BCDD_FINTO_RISPOSTA", rfD / "risposte" / "interfaccia_da_zero.json")])
    let o1 = runExe(bcddProva, @["refine", "--json", "Spia.csc", "--csc", "Spia"], d2, envPulito(env2))
    let pr = startProcess(bcddProva, workingDir = d2, args = @["refine", "--json", "--accept", "Spia.csc"], env = envPulito(env2), options = {})
    pr.inputStream.write("{\"accettate\": [\"i1\", \"p1\"]}")
    pr.inputStream.close()
    discard pr.outputStream.readAll()
    discard pr.waitForExit()
    pr.close()
    let f = leggiSe(d / "Spia.csc")
    rec("AC-237", "Spia.csc dopo «Scrivi» è quello della riga di comando con le stesse due accettate, riga per riga",
      o1.code == 0 and f.splitLines() == leggiSe(d2 / "Spia.csc").splitLines() and "  STATE accesa : Boolean INITIAL false" in f and "GUARANTEE g1 STATUS HYPOTHESIS:" in f and "TYPE Colore" notin f and "ASSUME a1" notin f,
      "o1=" & $o1.code & " uguali=" & $(f.splitLines() == leggiSe(d2 / "Spia.csc").splitLines()) & " diff1=" & $f.splitLines().len & "/" & $leggiSe(d2 / "Spia.csc").splitLines().len)
    rec("AC-237", "la scrittura la fa `bcdd refine --accept`: nessuna save della finestra", azioniLanci(s).count("save") == 0, $azioniLanci(s))
    s.finisci()
  block:
    # righe d'interfaccia scartate: la carta dice perché e non ha i bottoni
    let d = cartellaD()
    var s = nuovaSessione()
    s.avviaEditor(@["--dir", d, "Lampada"], root, ambD(s, @[("BCDD_FINTO_RISPOSTA", rfD / "risposte" / "interfaccia_scartate.json")]) &
      @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|@b-completa|?scheda-completa|?c-acc-i1|?c-acc-i3|?c-acc-i4")])
    let fine = attendi(s.trace, "sonda Q:c-acc-i4", 40)
    sleep(300)
    raccogli(s)
    let q = sondeDi(s)
    rec("AC-237", "righe scartate: «Una riga d'interfaccia non si può accettare: …» con la riga fra virgolette; i1 (tipo non dichiarato) e i4 (nome già usato) senza «Accetta», i3 con",
      fine and q.len >= 4 and q[0].count("Una riga d'interfaccia non si può accettare") >= 2 and "assente" in q[1] and "visibile" in q[2] and "assente" in q[3], cut($q, 900))
    s.finisci()
  block:
    # scopo ancora «da compilare»: il primo clic apre Cambia lo scopo con la frase, nessun refine
    let d = cartellaSpia("da scrivere: in una frase, di che cosa è responsabile Spia")
    let prima = fotografia(d)
    var s = nuovaSessione()
    s.avviaEditor(@["--dir", d, "Lampada"], root, ambD(s) & @[("BCDD_EDITOR_PROVA_CLIC", "#c-Spia|@b-completa|?scheda-modulo|?f-scopo-prima|?scheda-completa")])
    let fine = attendi(s.trace, "sonda Q:scheda-completa", 40)
    sleep(300)
    raccogli(s)
    let q = sondeDi(s)
    rec("AC-237", "scopo da compilare: si apre «Scopo di Spia» con «Completa parte dallo scopo: scrivi prima lo scopo.»; il riquadro di Completa non si apre; nessun refine",
      fine and q.len >= 3 and "Scopo di Spia" in q[0] and "Completa parte dallo scopo: scrivi prima lo scopo." in q[1] and "nascosto" in q[2] and
      righe(s.lanci).filterIt(it.startsWith("refine ")).len == 0 and fotografia(d) == prima, cut($q, 600))
    s.finisci()
  block:
    # file cambiato fra il tempo 1 e la scrittura: la copia comprende le righe d'interfaccia accettate
    let d = cartellaSpia("La spia di un apparecchio")
    var s = nuovaSessione()
    s.avviaEditor(@["--dir", d, "Lampada"], root, ambD(s, @[("BCDD_FINTO_RISPOSTA", rfD / "risposte" / "interfaccia_da_zero.json"), ("BCDD_FINTO_TOCCA", d / "Spia.csc")]) &
      @[("BCDD_EDITOR_PROVA_CLIC", "#c-Spia|@b-completa|@c-acc-i1|@c-acc-p1|@c-scrivi|?scheda-completa")])
    let fine = attendi(s.trace, "sonda Q:scheda-completa", 60)
    sleep(300)
    raccogli(s)
    let q = sondeDi(s)
    rec("AC-237", "file cambiato: la copia mostra «Riga d'interfaccia accettata i1» con la riga e la promessa accettata",
      fine and q.len >= 1 and "Il file è cambiato" in q[0] and "Riga d'interfaccia accettata i1" in q[0] and "STATE accesa : Boolean INITIAL false" in q[0] and "Riga accettata p1" in q[0], "fine=" & $fine & cut($q, 900) & cut(leggiSe(s.trace), 900))
    s.finisci()

# 080:7:11 AC-235: aprire l'entità di un posto: doppio clic (albero e Banco), «Apri…», Invio, catena in alto, parte mancante
block:
  proc cartellaPalazzo(): string =
    result = cartellaAlbero()
    writeFile(result / "Palazzo.csc", "ENTITY Palazzo VERSION 0.1\n  PURPOSE \"Il palazzo\"\n  COMPOSED OF\n    asc : Ascensore\nEND\n")
  block:
    # il doppio clic nell'albero (clic, clic, dblclick come il mouse): un'entità composta si apre da dentro, una semplice da fuori; l'albero evidenzia il posto
    let d = cartellaPalazzo()
    let prima = fotografia(d)
    var s = sessAlbero(d, "#tri:Palazzo/asc|&alb:Palazzo/asc|?banco-hint|?scheda-nome|?percorso|^|&alb:Palazzo/asc/motore|?banco-hint|?scheda-nome|?percorso|^|#pc:1|?banco-hint|?percorso", "sonda Q:percorso")
    sleep(600)
    let q = sondeDi(s)
    let ok = q.len >= 10
    rec("AC-235", "la sessione risponde a tutte le sonde", ok, cut($q, 900))
    if ok:
      rec("AC-235", "doppio clic su asc — Ascensore: Ascensore da dentro, scheda Ascensore, catena «Palazzo / Ascensore», il posto evidenziato nell'albero",
        "Costruisci Ascensore" in q[0] and "Ascensore" in q[1] and q[2].endsWith("Palazzo / Ascensore") and "2:asc — Ascensore*" in q[3], cut($q, 700))
      rec("AC-235", "doppio clic su motore (Motore, senza parti): Motore da fuori; catena «Palazzo / Ascensore / Motore»",
        "Fai clic su una scatola" in q[4] and "Motore" in q[5] and q[6].endsWith("Palazzo / Ascensore / Motore") and "3:Motore*" in q[7], cut($q, 700))
      rec("AC-235", "clic su «Ascensore» nella catena torna all'Ascensore da dentro",
        "Costruisci Ascensore" in q[8] and q[9].endsWith("Palazzo / Ascensore"), cut($q, 700))
    rec("AC-235", "niente scritto", fotografia(d) == prima and azioniLanci(s).count("save") == 0, $azioniLanci(s))
    s.finisci()
  block:
    # sul Banco: il doppio clic su una parte
    let d = cartellaPalazzo()
    var s = sessAlbero(d, "#alb:Palazzo|@t-dentro|&p-asc|?banco-hint|?scheda-nome|?percorso|&p-motore|?banco-hint|?percorso", "sonda Q:percorso")
    sleep(600)
    let q = sondeDi(s)
    rec("AC-235", "Banco: doppio clic sulla parte asc: Ascensore da dentro, catena «Palazzo / Ascensore»",
      q.len >= 4 and "Costruisci Ascensore" in q[0] and "Ascensore" in q[1] and q[2].endsWith("Palazzo / Ascensore"), cut($q, 600))
    rec("AC-235", "Banco: doppio clic sulla parte motore: Motore da fuori, catena «Palazzo / Ascensore / Motore»",
      q.len >= 5 and "Fai clic su una scatola" in q[3] and q[4].endsWith("Palazzo / Ascensore / Motore"), cut($q, 600))
    s.finisci()
  block:
    # il bottone «Apri Motore» nella scheda del posto (e dopo il clic il percorso è la catena); Invio sul posto fa lo stesso
    let d = cartellaAlbero()
    var s = sessAlbero(d, "#alb:Ascensore/motore|?b-apri|!b-apri|@b-apri|?scheda-nome|?banco-hint|?percorso|!b-apri", "sonda Q:b-apri assente")
    let q = sondeDi(s)
    rec("AC-235", "scheda del posto: «Apri Motore» acceso; dopo, Motore da fuori, catena «Ascensore / Motore»; il bottone non c'è più (nessun posto scelto)",
      q.len >= 6 and "Apri Motore" in q[0] and "acceso" in q[1] and "Motore" in q[2] and "Fai clic su una scatola" in q[3] and q[4].endsWith("Ascensore / Motore") and "assente" in q[5], cut($q, 700))
    s.finisci()
    var s2 = sessAlbero(d, "#alb:Ascensore/su|:alb:Ascensore/su:Enter|?scheda-nome|?percorso", "sonda Q:percorso")
    let q2 = sondeDi(s2)
    rec("AC-235", "Invio sul posto scelto nell'albero apre l'entità (Pulsante, catena «Ascensore / Pulsante»)", q2.len >= 2 and "Pulsante" in q2[0] and q2[1].endsWith("Ascensore / Pulsante"), cut($q2, 400))
    s2.finisci()
  block:
    # una parte mancante non si apre: il bottone è spento e il doppio clic non fa niente
    let d = cartellaAlbero()
    let prima = fotografia(d)
    var s = sessAlbero(d, "#alb:Citofono/voce|?b-apri|!b-apri|&alb:Citofono/voce|?percorso|?scheda-nome", "sonda Q:scheda-nome")
    let q = sondeDi(s)
    rec("AC-235", "parte mancante: «Apri Altoparlante» spento; il doppio clic non la apre (resta Citofono)",
      q.len >= 4 and "Apri Altoparlante" in q[0] and "spento" in q[1] and q[2].endsWith("/ Citofono") and "Citofono" in q[3] and fotografia(d) == prima, cut($q, 500))
    s.finisci()
  block:
    # a 1024 e alla larghezza di apertura: con «Apri…» la riga dei bottoni della scheda del posto non cambia di numero di righe (misura xwd, qui il conto)
    let d = cartellaAlbero()
    var s = sessAlbero(d, "#alb:Ascensore/motore|%", "sonda Q:%barra")
    let q = sondeDi(s)
    rec("AC-235", "con il posto scelto e «Apri…» la barra in alto sta su una riga", q.len >= 1 and "righe_testo=1 " in q[0], cut($q, 400))
    s.finisci()

# 080:7:9 AC-226: la barra in alto e la testa dei riquadri stanno su una riga, anche nella vista da dentro con un nome lungo
block:
  let d = copiaCartella(root / "prove" / "f3" / "luce")
  let lungo = "LuceScalaDelPianoTerraConNomeMoltoLungoPerLaProvaXYZ"
  writeFile(d / (lungo & ".csc"), readFile(d / "LuceScale.csc").replace("LuceScale", lungo))
  var s = nuovaSessione()
  s.avviaEditor(@["--dir", d, lungo], root, @[("BCDD_EDITOR_PROVA_CLIC", "@t-dentro|%")])
  let fine = attendi(s.trace, "sonda Q:%barra", 30)
  sleep(300)
  raccogli(s)
  let sonde = leggiSe(s.trace).splitLines().filterIt("sonda Q:%barra" in it)
  var ok = false
  var mis = cut(leggiSe(s.dir / "errori")) & " " & $sonde
  if fine and sonde.len == 1:
    let r = sonde[0]
    let h = parseInt(r.split(" h=")[1].split(" ")[0])
    let sez = r.split("sez_testa=")[1].split(" ")[0].split(",").mapIt(parseInt(it.strip()))
    let azH = parseInt(r.split("azioni_h=")[1].split(" ")[0])
    ok = r.contains("righe_testo=1 ") and h <= 36 and sez.len == 3 and sez.allIt(it <= 19) and r.contains("azioni_righe=1 ") and azH <= 28
  rec("AC-226", "vista da dentro con nome lungo: barra in alto, testa di Banco e Scheda e barra dei bottoni del Banco su una riga", ok, mis)
  s.finisci()

# 080:8:1 La pagina e i sorgenti (AC-196, AC-214)
let paginaDir = root / "editor" / "pagina"
block:
  let html = readFile(paginaDir / "pagina.html")
  const csp = "<meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; style-src 'unsafe-inline'\">"
  rec("AC-196", "la pagina contiene la CSP così com'è", csp in html and html.count("Content-Security-Policy") == 1, "")
  rec("AC-196", "la pagina non ha script propri", "<script" notin html.toLowerAscii(), "")
  var urls: seq[string]
  const svgNs = "http://www.w3.org/2000/svg"
  var nSvg = 0
  for f in ["pagina.html", "pagina.css", "pagina.js"]:
    var t = readFile(paginaDir / f)
    nSvg += t.count(svgNs)
    t = t.replace("var SVGNS = '" & svgNs & "';", "")
    for w in ["http:", "https:", "ws:", "file:"]:
      if w in t: urls.add f & ":" & w
  rec("AC-196", "nei sorgenti della pagina nessun http:, https:, ws:, file: (salvo SVGNS)", urls.len == 0, urls.join(", "))
  rec("AC-196", "il nome dello spazio SVG compare una sola volta, nella costante SVGNS, per intero",
    nSvg == 1 and "var SVGNS = '" & svgNs & "';" in readFile(paginaDir / "pagina.js"), $nSvg & " volte")
  # 080:9:2 Banco e Scheda seguono la finestra (misurato con le foto sotto Xvfb): pagina alta quanto la finestra, riquadri allungati, scorrimento dentro i riquadri
  let css0 = readFile(paginaDir / "pagina.css")
  rec("AC-196", "il CSS allunga Banco e Scheda fino alla barra STATO e li fa scorrere dentro (niente min-height:100vh sulla pagina)",
    ".colonne { display: flex; flex-wrap: nowrap; gap: var(--sp-3); align-items: stretch;" in css0 and ".colonne > .pannello { min-height: 0; overflow-y: auto; }" in css0 and
    "html, body { height: 100%; overflow: hidden; }" in css0 and "min-height: 100vh" notin css0, "")
  rec("AC-196", "il divisore fra Banco e Scheda c'è (cursore di ridimensionamento, larghezza minima, sparisce sotto i 900 px)",
    "id=\"divisore\"" in html and "cursor: col-resize" in css0 and ".divisore { display: none; }" in css0 and "min-width: 300px" in css0 and
    "'mousemove'" in readFile(paginaDir / "pagina.js"), "")
  # 080:9:3 I nomi delle variabili del divisore non coincidono con nessuna variabile definita nel CSS (--pb del tema usato come fattore di flex lasciava i riquadri fermi)
  block:
    var definite: seq[string]
    var i = 0
    while i < css0.len - 2:
      if css0[i] == '-' and css0[i+1] == '-' and (i == 0 or css0[i-1] in {'{', ';', ' '}):
        var j = i + 2
        while j < css0.len and (css0[j] in {'a'..'z', '0'..'9', '-'}): inc j
        if j < css0.len and css0[j] == ':': definite.add css0[i ..< j]
        i = j
      else: inc i
    var usate: seq[string]
    for riga in readFile(paginaDir / "pagina.js").splitLines:
      let k = riga.find("setProperty('--")
      if k >= 0:
        let da = k + len("setProperty('")
        let fine = riga.find('\'', da)
        if fine > da: usate.add riga[da ..< fine]
    var collide: seq[string]
    for u in usate:
      if u in definite: collide.add u
    rec("AC-196", "le variabili che il divisore scrive (--quota-banco, --quota-scheda) non coincidono con variabili definite nel CSS (colori del tema compresi)",
      usate.len == 3 and "--quota-banco" in usate and "--quota-scheda" in usate and "--larg-albero" in usate and collide.len == 0 and definite.len > 20 and "--pb" in definite and
      "var(--quota-banco, 5)" in css0 and "var(--quota-scheda, 5)" in css0, "collisioni: " & collide.join(", ") & "; usate: " & usate.join(", "))
  var vietate: seq[string]
  let js0 = readFile(paginaDir / "pagina.js")
  let js = js0 & "\n" & js0.multiReplace(("' + '", ""), ("\" + \"", ""), ("'+'", ""), ("\"+\"", ""))
  for w in ["innerHTML", "outerHTML", "insertAdjacentHTML", "document.write", "eval", "Function("]:
    if w in js: vietate.add w
  rec("AC-196", "pagina.js: testo solo con textContent (niente innerHTML, document.write, eval)", vietate.len == 0, vietate.join(", "))
  let finBase = readFile(root / "editor" / "edfinestra.nim")
  let fin = finBase & "\n" & readFile(root / "editor" / "edgtkfin.nim")     # il legame con GTK sta in edgtkfin.nim
  rec("AC-196", "decide-policy e context-menu collegati; load_html senza base_uri",
    "\"decide-policy\"" in fin and "\"context-menu\"" in fin and "webkit_web_view_load_html(vista, cstring(sc.html), nil)" in fin and
    "html: paginaHtmlBase.replace(\"/*LINGUA*/\", $lingua)" in fin, "")
  rec("AC-196", "enable-developer-extras falso; contesto effimero; composizione non spenta dal programma",
    "webkit_settings_set_enable_developer_extras(s, 0)" in fin and "webkit_web_context_new_ephemeral()" in fin and
    "putEnv(\"WEBKIT_DISABLE_COMPOSITING_MODE\"" notin fin, "")
  rec("AC-196", "il ponte accetta solo le cinque azioni del banco, con i campi esatti",
    "campiEsatti" in fin and "messaggioValido" in fin and "nuova_entita" in fin and "connettore" in fin, "")
  var vietateEd: seq[string]
  for f in walkFiles(root / "editor" / "*.nim"):
    let t = readFile(f)
    for w in ["g_timeout", "g_idle", "setTimeout", "setInterval", "g_file_monitor", "inotify", "sleep(", "claude", "BCDD_LLM", "osproc", "startProcess"]:
      if w in t: vietateEd.add f.extractFilename & ": " & w
  for w in ["setTimeout", "setInterval", "requestAnimationFrame"]:
    if w in js0: vietateEd.add "pagina.js: " & w
  rec("AC-214", "nei sorgenti di editor/ nessun timer, osservatore di file, refine, ratify, claude, osproc", vietateEd.len == 0, vietateEd.join(", "))
  rec("AC-214", "in tutte le sessioni l'editor ha lanciato solo check, save, new, refine e ratify (refine solo con --json, controllato in AC-218)",
    azioniViste.len >= 3 and azioniViste.allIt(it in ["check", "save", "new", "refine", "ratify"]), $azioniViste)

# 080:8:1 A-14 BCDD 1.0-beta: lista delle parole, colorazione, contrasto, forma 5, forme concrete, piano di prova, profili, rapporto
# Cartelle congelate in editor/prove/w12/ (mai casi vivi); le prove con la finestra usano tests/bcdd_prova.
block:
  # AC-239: la lista delle 136 parole coincide con la GRAMMATICA_F1 §2.3 (AC-322), «+ Stato» rifiuta Record e accetta C1
  var dalGrammatica: seq[string]
  let gram = readFile(root / "GRAMMATICA_F1.md").splitLines()
  var dentro, fence = false
  for l in gram:
    if l.startsWith("Le **parole chiave** sono in inglese"): dentro = true
    if dentro and l.startsWith("In totale le parole chiave"): break
    if dentro:
      if l.startsWith("```"): fence = not fence
      elif fence: dalGrammatica.add l.splitWhitespace
  dalGrammatica.add @["true", "false", "requested", "accepted", "rejected", "completed", "failed", "_"]
  let setG = dalGrammatica.toHashSetLocal
  let setE = @paroleRiservate.toHashSetLocal
  rec("AC-239", "la lista di edazioni.nim ha 136 parole e coincide con la §2.3 della grammatica", paroleRiservate.len == 136 and setG == setE and dalGrammatica.len == 136,
    $paroleRiservate.len & " " & $dalGrammatica.len)
  rec("AC-239", "il nome «Record» di uno stato si rifiuta, «C1» e «V2» si accettano", validaNomeD("Record", @[]).len > 0 and validaNomeD("C1", @[]) == "" and validaNomeD("V2", @[]) == "" and
    validaNomeD("Duration", @[]).len > 0, validaNomeD("Record", @[]) & "|" & validaNomeD("C1", @[]))

block:
  # AC-240: coloraRighe (funzione pura)
  let seg = coloraRigheSu(@["  GUARANTEE g: VERBAL \"una -- due", "tre\" -- commento", "  STATE C1 : Boolean INITIAL false", "    VERIFY V1 C1 ; V2 \"x\"",
    "    @0.5 s e <= 3 ms -> REFINES", "  IMPORT PROFILE Segnale VERSION 0.3", "  GUARANTEE g2: FADE x"], @[(4, 4)], @[(7, 7, @["FADE"])])
  proc ha(r: int, t, c: string): bool =
    for (x, y) in seg[r - 1]:
      if x == t and y == c: return true
  rec("AC-240", "una stringa su due righe: un solo segmento «stringa» per riga, anche con «--» dentro", ha(1, "\"una -- due", "stringa") and ha(2, "tre\"", "stringa"))
  rec("AC-240", "un commento dopo una stringa che ha chiuso", ha(2, "-- commento", "commento"))
  rec("AC-240", "C1 come nome di stato: nessuna classe; nel VERIFY di un'estensione: contesto", not ha(3, "C1", "contesto") and ha(4, "C1", "contesto") and ha(4, "V2", "contesto") and ha(4, "VERIFY", "chiave"),
    $seg[2] & " " & $seg[3])
  rec("AC-240", "un numero con unità, «<=» e «->» come segni, REFINES ritirata", ha(5, "0.5 s", "numero") and ha(5, "3 ms", "numero") and ha(5, "<=", "segno") and ha(5, "->", "segno") and ha(5, "REFINES", "ritirata"), $seg[4])
  rec("AC-240", "il nome di un'estensione importata prende la classe «estensione»; senza importarla, no", ha(7, "FADE", "estensione") and not (block: (let t = coloraRigheSu(@["  GUARANTEE g2: FADE x"]); t[0].anyIt(it.classe == "estensione"))), $seg[6])

block:
  # AC-241: contrasto delle variabili --hl-* sui quattro sfondi (normale, da approvare, approvata, errore), nei due temi: almeno 4,5:1
  let css = readFile(root / "editor" / "pagina" / "pagina.css")
  proc variabili(tema: string): Table[string, string] =
    for l in css.splitLines():
      if l.startsWith("." & tema & "{"):
        for parte in l[l.find('{') + 1 ..< l.rfind('}')].split(';'):
          let kv = parte.split(':', 1)
          if kv.len == 2: result[kv[0].strip] = kv[1].strip
  proc lum(h: string): float =
    proc f(c: float): float = (if c <= 0.03928: c / 12.92 else: pow((c + 0.055) / 1.055, 2.4))
    let (r, g, b) = (parseHexInt(h[1 .. 2]).float / 255, parseHexInt(h[3 .. 4]).float / 255, parseHexInt(h[5 .. 6]).float / 255)
    0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)
  proc contrasto(a, b: string): float =
    let (x, y) = (lum(a), lum(b))
    (max(x, y) + 0.05) / (min(x, y) + 0.05)
  for tema in ["tema-notte", "tema-giorno"]:
    let v = variabili(tema)
    var peggio = 99.0
    var quale = ""
    var n = 0
    for k, c in v:
      if not k.startsWith("--hl-"): continue
      inc n
      for sfondo in ["--code", "--ipo", "--ok", "--badbg"]:
        let r = contrasto(c, v[sfondo])
        if r < peggio:
          peggio = r
          quale = k & " su " & sfondo
    rec("AC-241", tema & ": otto colori di classe, ognuno almeno 4,5:1 sui quattro sfondi", n == 8 and peggio >= 4.5, $n & " " & quale & " " & formatFloat(peggio, ffDecimal, 2))

if not xvfbOk:
  for ac in ["AC-242", "AC-243", "AC-244", "AC-245", "AC-246", "AC-247"]: senzaXvfb(ac, "sessione con Xvfb")
else:
  let fixW12 = root / "editor" / "prove" / "w12" / "luce"
  block:
    # AC-242: la forma 5 con una CSC con formule, un BINDING con nome, una VERIFICATION, un profilo importato; sezioni 12-15 nei loro riquadri
    let d = copiaCartella(fixW12)
    let prima = fotografia(d)
    var s = sessAlbero(d, "#alb:@csc|#alb:@csc/Luce|?lg-b0|?lg-b1|?r-11|?r-2|?rq-non-eseguiti|@lg-b0|?rq-forme|?scheda-nome|!b-approva-forme|@lg-b1|?rq-copertura|?nota-piano|?b-approva-forme|" &
      "#alb:@pro|#alb:@pro/Segnale|?rq-giudicare|?scheda-tipo|?r-5|$", "sonda Q:$visibili")
    let q = sondeDi(s)
    let ok = q.len >= 15
    rec("AC-242", "la finestra apre la cartella (forma 5) e risponde a tutte le sonde", ok, cut($q, 600))
    if ok:
      rec("AC-242", "le linguette Forme concrete (con il nome) e Piano di prova ci sono", "Forme concrete · «forme»" in q[0] and "Piano di prova" in q[1], q[0] & " / " & q[1])
      rec("AC-242", "una formula ha il grado accanto al nome breve (formale), una frase a parole verbale", "formale" in q[2] and "GUARANTEE l1" in q[2], q[2])
      rec("AC-242", "la riga IMPORT PROFILE dice dove sta il profilo e in che stato", "trovato in Segnale.csc, da approvare" in q[3], q[3])
      rec("AC-242", "sezione 15: tre controlli non eseguiti nel riquadro del connettore, con le righe", "Controlli che bcdd non esegue (4)" in q[4] and "storie: riga 18" in q[4] and "coerenza di presupposti e promesse: righe 11, 12" in q[4] and "coerenza dei dettagli: riga 10" in q[4], q[4])
      rec("AC-242", "sezione 12: gli elementi senza forma concreta, senza codici d'errore", "Elementi senza forma concreta: STATE modo, STATE livello, EVENT IN pressione, EVENT OUT accendi" in q[5] and "Forme concrete «forme» di Luce" in q[6], q[5] & " / " & q[6])
      rec("AC-242", "il bottone Approva le forme concrete c'è e funziona (forme con nome)", "acceso" in q[7], q[7])
      rec("AC-242", "sezione 13: il mezzo «telecamera osserva: nessuna» e «Non eseguite: l1, l2»; il piano non si approva",
        "telecamera osserva: nessuna" in q[8] and "Non eseguite: l1, l2" in q[8] and "Il piano di prova non ha uno stato di approvazione" in q[9] and "assente" in q[10], q[8] & " / " & q[9] & " / " & q[10])
      rec("AC-242", "sezione 14: il profilo ha le sue due voci «Da giudicare» e la sua scheda; il profilo sta nell'albero", "Da giudicare (2)" in q[11] and "il MEANING non descrive" in q[11] and "Profilo" in q[12], q[11] & " / " & q[12])
    rec("AC-242", "aprire e guardare non scrive niente: file uguali, nessun save", fotografia(d) == prima and azioniLanci(s).count("save") == 0, $azioniLanci(s))
    s.finisci()
  block:
    # AC-243: la casella con la formula su due righe (U5) e con la storia intera (REPEAT), e l'avviso della riga che chiede un seguito
    let d = copiaCartella(fixW12)
    var s = sessAlbero(d, "#alb:@csc|#alb:@csc/Luce|#r-12|!f-testo|=f-testo:  GUARANTEE l2: ALWAYS (accesa AND|?f-seguito|@f-annulla|#r-20|!f-testo|@f-annulla|#r-21|!f-testo|@f-annulla|$", "sonda Q:$visibili")
    let q = sondeDi(s)
    let ok = q.len >= 5
    rec("AC-243", "la sessione risponde a tutte le sonde", ok, cut($q, 600))
    if ok:
      rec("AC-243", "clic sulla seconda riga di una formula: la casella ha le due righe", "valore=  GUARANTEE l2: ALWAYS (accesa AND¶                        modo)" in q[0], q[0])
      rec("AC-243", "una riga che finisce con AND dice che continua sulla riga che segue", "«AND»" in q[1] and "continua sulla riga che segue" in q[1], q[1])
      rec("AC-243", "clic su REPEAT e su un passo ripetuto: la casella ha la storia intera, dalla riga SCENARIO",
        "valore=  SCENARIO s1 EXPECT ADMITTED¶    @0 s     pressione¶    REPEAT FOREVER EVERY 1 s¶    @0.5 s   accendi" in q[2] and q[2] == q[3].replace("f-testo", "f-testo"), q[2] & " / " & q[3])
    rec("AC-243", "la sola lettura non scrive: nessun save", azioniLanci(s).count("save") == 0)
    s.finisci()
  block:
    # AC-244: scrivere: una formula su due righe dal modulo, una forma concreta, un mezzo, la riga tolta
    let d = copiaCartella(fixW12)
    var s = sessAlbero(d, "#alb:@csc|#alb:@csc/Luce|@b-promessa|=f-come:FORMULA|?f-chi|=f-formula:ALWAYS (accesa" & "\n" & "OR modo)|@f-ok|@lg-b0|@b-forma|=f-elemento:modo|=f-frase:il selettore|@f-ok|" &
      "@lg-b1|@b-mezzo|=f-nome:cam2|@f-oss-modo|=f-risoluzione:1|=f-unita-r:s|@f-ok|$", "sonda Q:$visibili")
    let t = leggiSe(d / "Luce.csc").splitLines()
    var ixF = -1
    for i, l in t:
      if l.startsWith("  GUARANTEE ") and "ALWAYS (accesa" in l and "l2" notin l: ixF = i
    rec("AC-244", "«+ Promessa» scritta come formula: due righe, la seconda rientrata sotto la formula, nessun VERIFY",
      ixF >= 0 and t[ixF + 1].len > 0 and t[ixF + 1].strip == "OR modo)" and t[ixF + 1].find('O') == t[ixF].find("ALWAYS") and "VERIFY" notin t[ixF + 1], $t)
    rec("AC-244", "la forma concreta si aggiunge dopo l'ultima riga BIND", "  BIND accesa: VERBAL \"la plafoniera è piena\"" in t and t.find("  BIND modo: VERBAL \"il selettore\"") == t.find("  BIND accesa: VERBAL \"la plafoniera è piena\"") + 1, $t)
    rec("AC-244", "il mezzo si aggiunge dopo l'ultimo MEANS", t.find("  MEANS cam2 OBSERVES modo RESOLUTION 1 s") == t.find("  MEANS telecamera OBSERVES accesa RESOLUTION 40 ms") + 1, $t)
    rec("AC-244", "tre save, una per azione", azioniLanci(s).count("save") == 3, $azioniLanci(s))
    s.finisci()
  block:
    # AC-245: creare: forme concrete (con nome), piano di prova, profilo, scheletro di un'estensione; togliere
    let d = copiaCartella(fixW12)
    var s = sessAlbero(d, "#alb:@csc|#alb:@csc/Luce|@b-forme-nuove|=f-nome:Record|?e-f-nome|=f-nome:f2|@f-ok|@b-piano-nuovo|@f-ok|@b-profilo|=f-nome:Nuovo|=f-frase:Un profilo di prova|@f-ok|" &
      "#alb:@pro|#alb:@pro/Segnale|@b-estensione|!f-testo|@f-annulla|$", "sonda Q:$visibili")
    let q = sondeDi(s)
    let t = leggiSe(d / "Luce.csc")
    rec("AC-245", "un nome che è una parola del linguaggio si rifiuta nel modulo", q.len >= 1 and "parola del linguaggio" in q[0], cut($q, 300))
    rec("AC-245", "le forme concrete nuove in fondo al file, con il nome e STATUS HYPOTHESIS; il piano di prova dopo",
      t.endsWith("BINDING Luce VERSION 0.1 AS f2\n  STATUS HYPOTHESIS\nEND\nVERIFICATION Luce VERSION 0.1\nEND\n"), t[max(0, t.len - 150) .. ^1])
    rec("AC-245", "il profilo è un file nuovo Nuovo.csc", leggiSe(d / "Nuovo.csc") == "PROFILE Nuovo VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"Un profilo di prova\"\nEND\n", leggiSe(d / "Nuovo.csc"))
    rec("AC-245", "«+ Estensione» apre la casella con lo scheletro prima dell'END del profilo", q.len >= 2 and q.anyIt("f-testo acceso" in it and "EXTENSION NOME" in it and it.endsWith("  END¶END")), cut($q, 500))
    rec("AC-245", "tre scritture (forme, piano, profilo)", azioniLanci(s).count("save") == 3 and azioniLanci(s).count("new") == 0, $azioniLanci(s))
    s.finisci()
  block:
    # AC-246: approvare: forme concrete con nome (--all), profilo, dettaglio di DEFINE; Torna indietro; forme concrete senza nome: bottone spento
    for (etichetta, clic, atteso, cartella) in [
        ("forme concrete con nome (--all)", "#alb:@csc|#alb:@csc/Luce|@lg-b0|@b-approva-forme|?scheda-approva|=a-num:D-9|@a-ok", "ratify Luce.csc --dir . --csc forme --all D-9", ""),
        ("profilo", "#alb:@pro|#alb:@pro/Segnale|@b-approva-profilo|?scheda-approva|=a-num:D-10|@a-ok", "ratify Segnale.csc --dir . --csc Segnale D-10", ""),
        ("dettaglio di DEFINE", "#alb:@csc|#alb:@csc/Luce|@a-sel-K2|=a-num:D-11|@a-ok", "ratify Luce.csc --dir . --csc Luce K2 D-11", "")]:
      let d = copiaCartella(fixW12)
      let prima = fotografia(d)
      var s = sessAlbero(d, clic & "|@b-annulla|@f-ok|$", "sonda Q:$visibili")
      sleep(800)
      raccogli(s)
      let lanci = righe(s.lanci)
      rec("AC-246", etichetta & ": il comando è " & atteso, atteso in lanci, $lanci)
      rec("AC-246", etichetta & ": dopo Torna indietro i file sono come prima", fotografia(d).pairs.toSeq.filterIt(it[0].endsWith(".csc")).allIt(it[0] in prima and prima[it[0]][0] == it[1][0]), "")
      s.finisci()
    block:
      let d = newWd0()
      writeFile(d / "Luce.csc", "CSC Luce VERSION 0.1\n  PURPOSE \"x\"\n  STATE accesa : Boolean INITIAL false\n  GUARANTEE l1: ALWAYS accesa\nEND\nBINDING Luce VERSION 0.1\n  STATUS HYPOTHESIS\nEND\n")
      var s = sessAlbero(d, "#alb:@csc|#alb:@csc/Luce|@lg-b0|!b-approva-forme|?nota-senza-nome|@b-nome|!f-testo|$", "sonda Q:$visibili")
      let q = sondeDi(s)
      rec("AC-246", "forme concrete senza nome nel file del connettore: Approva spento, la frase, «Dai un nome…» apre la casella con AS già aggiunto",
        q.len >= 3 and "spento" in q[0] and "per approvarle, dai loro un nome" in q[1] and q[2].endsWith("BINDING Luce VERSION 0.1 AS "), cut($q, 500))
      rec("AC-246", "nessuna scrittura", azioniLanci(s).count("save") == 0 and azioniLanci(s).count("ratify") == 0, $azioniLanci(s))
      s.finisci()
  block:
    # AC-247: misura a 1024 e 1280 px, due temi, con le linguette Forme concrete e Piano di prova aperte: nessuna barra va a capo
    for larg in ["1024x700", "1280x800"]:
      let d = copiaCartella(fixW12)
      var s = nuovaSessione()
      s.avviaEditor(@["--dir", d], root, @[("BCDD_EDITOR_PROVA_DIM", larg), ("BCDD_EDITOR_PROVA_CLIC", "#alb:@csc|#alb:@csc/Luce|@lg-b0|%|@lg-b1|%|@b-tema|%|@lg-b0|%|$")])
      discard attendi(s.trace, "sonda Q:$visibili", 40)
      sleep(300)
      let q = sondeDi(s)
      let barre = q.filterIt(it.startsWith("%barra"))
      rec("AC-247", larg & ": quattro misure (due linguette, due temi), la barra in alto su una riga, la barra del Banco su una riga",
        barre.len == 4 and barre.allIt("righe_testo=1 tops=1" in it and "azioni_righe=1" in it), cut($barre, 700))
      s.finisci()

# 080:8:1 L-E1..L-E11: l'editor nelle due lingue. Le prove di sopra girano in italiano (BCDD_LANG=it); qui la lingua si sceglie per sessione.
block lingue:
  let fixLingue = root / "editor" / "prove" / "lingue"
  let paroleSpia = ["riga", "righe", "errore", "errori", "nessun", "nessuna", "della", "è", "non", "manca", "alla", "deve", "con", "senza",
    "connettore", "promessa", "approva", "scheda"]
  proc paroleDi(t: string): seq[string] =
    ## Le parole (lettere, anche non ASCII, e il trattino basso) in minuscolo ASCII dove si può.
    var cur = ""
    for c in t:
      if c in {'a'..'z', 'A'..'Z', '_'} or ord(c) >= 128: cur.add c.toLowerAscii
      else:
        if cur.len > 0: result.add cur
        cur = ""
    if cur.len > 0: result.add cur
  proc spie(t: string): seq[string] = paroleDi(t).filterIt(it in paroleSpia).deduplicate
  proc sessLingua(args: seq[string], clic: string, extra: seq[(string, string)] = @[], cartella = "", nome = ""): Sess =
    result = nuovaSessione()
    let d = if cartella.len > 0: cartella else: copiaCartella(fixLingue)
    result.avviaEditor(args & @["--dir", d] & (if nome.len > 0: @[nome] else: @[]), root, @[("BCDD_EDITOR_PROVA_CLIC", clic & "|$")] & extra)
    discard attendi(result.trace, "sonda Q:$visibili", 40)
    sleep(300)
  # il giro delle viste che mostra più testo: l'entità, il connettore, le sue linguette, il rapporto
  let giro = "#c-Light|?scheda-righe|?scheda-rapporto|?scheda-azioni|?stato-msg|@lg-b0|?scheda-rapporto|?scheda-azioni|@lg-b1|?scheda-rapporto|?scheda-azioni|?albero|?azioni"
  proc tuttoIlTesto(s: Sess): string =
    ## il testo della pagina e le risposte della sonda, senza il nome dell'elemento con cui la sonda le introduce
    paginaN(s, 1) & "\n" & sondeDi(s).mapIt(it[it.find(' ') + 1 .. ^1]).join("\n")

  # --- L-E1 e L-E6: inglese di partenza, parole spia, parità di registrazione fra le due lingue
  var testoEn, testoIt: string
  var qEn, qIt: seq[string]
  block:
    var s = sessLingua(@[], giro, @[("BCDD_LANG", "")], "", "Hall")
    testoEn = tuttoIlTesto(s)
    qEn = sondeDi(s)
    rec("L-E1", "senza --lang, scelta e BCDD_LANG: la pagina è in inglese, <html lang=\"en\">", "lingua=en" in paginaN(s, 1) and "Outside view" in paginaN(s, 1), cut(paginaN(s, 1)[max(0, paginaN(s, 1).len - 120) .. ^1]))
    rec("L-E1", "nessuna parola spia nel testo della pagina e delle schede (il contenuto dei file è inglese)", spie(testoEn).len == 0, $spie(testoEn) & " " & cut(testoEn, 300))
    rec("L-E1", "i riquadri 12-15 e la citazione non trovata ci sono (la sonda ha di che guardare)",
      "Elements without a concrete form" in testoEn or "STATE on" in testoEn, cut($qEn, 400))
    s.finisci()
  block:
    var s = sessLingua(@["--lang", "it"], giro, @[("BCDD_LANG", "en")], "", "Hall")
    testoIt = tuttoIlTesto(s)
    qIt = sondeDi(s)
    rec("L-E1", "con --lang it la pagina è in italiano, <html lang=\"it\">, anche con BCDD_LANG=en", "lingua=it" in paginaN(s, 1) and "Vista da fuori" in paginaN(s, 1), cut(paginaN(s, 1)[max(0, paginaN(s, 1).len - 120) .. ^1]))
    s.finisci()
  # L-E6: stessi identificativi, stesse righe, stessi conteggi nelle due lingue
  block:
    var fonte = ""
    for f in walkFiles(fixLingue / "*.csc"): fonte.add readFile(f) & "\n"
    let noti = ["light", "hall", "lamp", "ghost", "absent", "camera", "g1", "g2", "g2a", "press"].toHashSet
    proc firma(t: string): seq[string] =
      ## i numeri e le parole che stanno nei file (nomi, id), nell'ordine in cui compaiono
      for w in t.splitWhitespace():
        for p in paroleDi(w): (if p in noti and p.len > 1: result.add p)
        var num = ""
        for c in w:
          if c in {'0'..'9'}: num.add c
          elif num.len > 0:
            result.add num
            num = ""
        if num.len > 0: result.add num
    let fEn = qEn.mapIt(firma(it))
    let fIt = qIt.mapIt(firma(it))
    rec("L-E6", "stesso numero di risposte, e per ognuna stessi identificativi e numeri nello stesso ordine in italiano e in inglese",
      qEn.len == qIt.len and qEn.len >= 10 and fEn == fIt, "en " & $fEn & "\n it " & $fIt)
    let tuttoEn = qEn.join(" ")
    let tuttoIt = qIt.join(" ")
    rec("L-E6", "i riquadri della sezione 12, 13, 14, 15, la citazione non trovata e la CSC mancante dicono la stessa cosa nelle due lingue",
      "Elements without a concrete form: STATE on, EVENT IN press" in tuttoEn and "camera observes: g2" in tuttoEn and "To be judged (1)" in tuttoEn and
      "not found: profile Absent" in tuttoEn and "Missing connector (1)" in tuttoEn and
      "Elementi senza forma concreta: STATE on, EVENT IN press" in tuttoIt and "camera osserva: g2" in tuttoIt and "Da giudicare (1)" in tuttoIt and
      "non trovato: profilo Absent" in tuttoIt and "Senza connettore (1)" in tuttoIt, cut(tuttoEn, 600) & " / " & cut(tuttoIt, 600))
  block:
    let vecchio = getEnv("BCDD_EDITOR_PROVA_VECCHIO")
    if vecchio.len == 0 or not fileExists(vecchio):
      nonEsercitato("L-E1", "la sonda deve fallire con l'editor di f8ebbdea", "BCDD_EDITOR_PROVA_VECCHIO non è impostata")
    else:
      edProvaCorrente = vecchio
      var s = sessLingua(@[], giro, @[("BCDD_LANG", "")], "", "Hall")
      let t = tuttoIlTesto(s)
      s.finisci()
      edProvaCorrente = edProva
      rec("L-E1", "con l'editor di f8ebbdea e bcdd inglese la sonda delle parole spia trova parole italiane (la prova misura)", spie(t).len >= 5, $spie(t))
      rec("L-E6", "con l'editor di f8ebbdea e bcdd inglese la registrazione non è la stessa (la prova misura)",
        "Elementi senza forma concreta" in t or "Forme concrete" in t or "Connettore" in t, cut(t, 300))

  # --- L-E2: ogni lancio di bcdd porta --lang in testa, con la lingua effettiva, anche con BCDD_LANG diversa
  block:
    var s = sessLingua(@["--lang", "en"], "@b-nuova|=f-nome:Nuova1|=f-scopo:one try|@f-ok", @[("BCDD_LANG", "it")])
    discard attendi(s.trace, "pagina 2", 30)
    sleep(300)
    let l = righe(s.lanci & ".completi")
    rec("L-E2", "ogni lancio comincia con --lang en (check, save), con BCDD_LANG=it nell'ambiente",
      l.len >= 4 and l.allIt(it.startsWith("--lang en ")) and l.anyIt(" check " in it) and l.anyIt(" save " in it), $l)
    s.finisci()
    let fin = readFile(root / "editor" / "edfinestra.nim")
    rec("L-E2", "i due punti di lancio (sincrono e refine) costruiscono gli argomenti con --lang e la lingua effettiva",
      fin.count("@[programma, \"--lang\", $lingua] & args") == 2, "")

  # --- L-E3: la scelta nell'interfaccia, la scelta ricordata, le precedenze
  block:
    let d = copiaCartella(fixLingue)
    var s = sessLingua(@[], "?scheda-nome|#c-Light|?scheda-nome|@l-it|?scheda-nome|?stato-msg|?l-it", @[("BCDD_LANG", "")], d, "Hall")
    # 080:8:2 `$` due volte: la prima chiude il giro di prima della scelta, la seconda quello di dopo
    discard attendi(s.trace, "pagina 2", 30)
    sleep(800)
    let q = sondeDi(s)
    let f = s.dir / "xdg_config" / "bcdd-editor" / "lingua"
    rec("L-E3", "il clic su Italiano: il file lingua contiene it, la pagina è ridisegnata in italiano, la selezione (Light) è la stessa",
      leggiSe(f) == "it\n" and "lingua=it" in paginaN(s, 2) and "Vista da fuori" in paginaN(s, 2) and q.len >= 3 and "Light" in q[1], cut(paginaN(s, 2)[max(0, paginaN(s, 2).len - 100) .. ^1]) & " " & $q & " " & leggiSe(f))
    let l = righe(s.lanci & ".completi")
    let iDopo = l.mapIt(it.startsWith("--lang it ")).find(true)
    rec("L-E3", "bcdd è rilanciato con la lingua nuova: prima solo --lang en, poi --lang it",
      iDopo > 0 and l[0 ..< iDopo].allIt(it.startsWith("--lang en ")) and l[iDopo .. ^1].allIt(it.startsWith("--lang it ")), $l)
    s.finisci()
    let cfg = s.dir / "xdg_config"
    # riaprendo senza --lang vale la scelta ricordata; --lang la scavalca; con BCDD_LANG e senza file vale BCDD_LANG; contenuto non valido = assente
    proc lingua1(args: seq[string], extra: seq[(string, string)]): string =
      var s2 = sessLingua(args, "?stato-chip", extra, copiaCartella(fixLingue))
      result = paginaN(s2, 1)
      result = (if "lingua=it" in result: "it" elif "lingua=en" in result: "en" else: "?")
      s2.finisci()
    let conFile = @[("XDG_CONFIG_HOME", cfg), ("BCDD_LANG", "en")]
    rec("L-E3", "riaprendo senza --lang e con BCDD_LANG=en la scelta ricordata (it) vale", lingua1(@[], conFile) == "it", "")
    rec("L-E3", "--lang en scavalca la scelta ricordata", lingua1(@["--lang", "en"], conFile) == "en", "")
    rec("L-E3", "senza file e senza --lang vale BCDD_LANG (it)", lingua1(@[], @[("BCDD_LANG", "it")]) == "it", "")
    let cfg2 = tmpBase / "cfg_non_valida"
    createDir(cfg2 / "bcdd-editor")
    writeFile(cfg2 / "bcdd-editor" / "lingua", "fr\n")
    rec("L-E3", "un file con contenuto non valido vale come assente (qui BCDD_LANG=it)", lingua1(@[], @[("XDG_CONFIG_HOME", cfg2), ("BCDD_LANG", "it")]) == "it", "")
    rec("L-E3", "...e senza BCDD_LANG vale l'inglese", lingua1(@[], @[("XDG_CONFIG_HOME", cfg2), ("BCDD_LANG", "")]) == "en", "")
    let vuota = tmpBase / "cfg_vuota"
    createDir(vuota)
    # lingua del sistema, senza --lang, senza scelta ricordata (XDG_CONFIG_HOME vuota), senza BCDD_LANG
    let cfgS = tmpBase / "cfg_sistema"
    createDir(cfgS)
    let sv = @[("XDG_CONFIG_HOME", cfgS), ("BCDD_LANG", "")]
    rec("L-E12", "LANG=it_IT.UTF-8: italiano", lingua1(@[], sv & @[("LANG", "it_IT.UTF-8")]) == "it", "")
    rec("L-E12", "LC_ALL=en_US.UTF-8 con LANG=it_IT.UTF-8: inglese (vale LC_ALL)", lingua1(@[], sv & @[("LC_ALL", "en_US.UTF-8"), ("LANG", "it_IT.UTF-8")]) == "en", "")
    rec("L-E12", "LANG=C: inglese", lingua1(@[], sv & @[("LANG", "C")]) == "en", "")
    rec("L-E12", "BCDD_LANG=en con LANG=it_IT.UTF-8: inglese", lingua1(@[], @[("XDG_CONFIG_HOME", cfgS), ("BCDD_LANG", "en"), ("LANG", "it_IT.UTF-8")]) == "en", "")
    rec("L-E12", "il ripiego sul sistema non scrive la scelta ricordata", not fileExists(cfgS / "bcdd-editor" / "lingua"), "")
    let cfgR = tmpBase / "cfg_sistema_ricordata"
    createDir(cfgR / "bcdd-editor")
    writeFile(cfgR / "bcdd-editor" / "lingua", "it\n")
    rec("L-E12", "scelta ricordata it con LANG=C: italiano", lingua1(@[], @[("XDG_CONFIG_HOME", cfgR), ("BCDD_LANG", ""), ("LANG", "C")]) == "it", "")
    let r = runExe(edProva, @["--lang", "fr", "--dir", fixLingue], root, envPulito([("BCDD_LANG", ""), ("XDG_CONFIG_HOME", vuota)]))
    rec("L-E3", "--lang fr: codice 2 e il messaggio nella lingua che varrebbe senza l'opzione", r.code == 2 and "--lang accepts it or en: fr" in r.errout, r.errout)
    let r2 = runExe(edProva, @["--lang", "en", "--x"], root, envPulito([("XDG_CONFIG_HOME", vuota)]))
    rec("L-E3", "argomento sconosciuto: la riga d'uso con --lang (it con BCDD_LANG=it)", r2.code == 2 and r2.errout.startsWith("uso: bcdd-editor [--lang it|en] [--dir CARTELLA]... [NOME]"), r2.errout)

  # --- L-E4: il comando della lingua è spento con modifiche non salvate e con un giro di Completa aperto
  block:
    var s = sessLingua(@["--lang", "en"], "!l-it|@b-nuova|=f-nome:Pippo|!l-it|~l-it|@f-annulla|!l-it", @[("BCDD_LANG", "")])
    let q = sondeDi(s)
    rec("L-E4", "acceso a modulo chiuso, spento dopo aver scritto in un modulo (la descrizione dice perché), di nuovo acceso dopo Cancel",
      q.len >= 4 and "acceso" in q[0] and "spento" in q[1] and "unsaved" in q[2] and "acceso" in q[3], $q)
    s.finisci()
  block:
    let rf = root / "prove" / "f2" / "refine"
    let d = newWd0()
    copyFile(rf / "Luce.csc", d / "Luce.csc")
    var s = nuovaSessione()
    createDir s.dir / "aux"
    s.avviaEditor(@["--lang", "en", "--dir", d], root, @[("BCDD_EDITOR_PROVA_CLIC", "#alb:@csc|#alb:@csc/Luce|@b-completa|!l-it|~l-it|$"), ("BCDD_LLM", root / "prove" / "f2" / "ULlmFinto.sh"),
      ("BCDD_ATTESA_LLM", "30"), ("BCDD_ORA", "2026-10-16T18:00:00+02:00"), ("BCDD_REGISTRO", s.dir / "chiamate.tsv"), ("BCDD_FINTO_CONTA", s.dir / "aux" / "conta"),
      ("BCDD_FINTO_RISPOSTA", rf / "risposte" / "buona.json"), ("BCDD_FINTO_RISPOSTA_2", rf / "risposte" / "buona_seconda.json"), ("BCDD_LANG", "")])
    discard attendi(s.trace, "sonda Q:$visibili", 40)
    sleep(300)
    let q = sondeDi(s)
    rec("L-E4", "con un giro di Completa aperto il comando è spento e dice di chiuderlo", q.len >= 2 and "spento" in q[0] and "Complete round" in q[1], $q)
    s.finisci()

  # --- L-E5: gli accoppiamenti C-4..C-13 sono sostituiti da campi strutturati
  block:
    var tutto = ""
    for f in ["edmodello.nim", "edfinestra.nim", "edazioni.nim", "edbcdd.nim"]: tutto.add readFile(root / "editor" / f) & "\n"
    let js = readFile(root / "editor" / "pagina" / "pagina.js")
    var presenti: seq[string]
    for w in ["ripulisci", "senzaRigaN", "statoCitato", "parolePiane"]:
      if w in tutto or w in js: presenti.add w
    for w in ["(riga \\d+)", "/^da compilare/", ".indexOf('--accept')", ".indexOf('risposte_fallite')", ".indexOf('fase proposte')", "indexOf('non trovato')", "startsWith(\"riga \")", "startsWith(\"PROFILE \")"]:
      if w in tutto or w in js or w.replace("\\", "\\\\") in js: presenti.add w
    rec("L-E5", "nessuna funzione dei vecchi accoppiamenti e nessuna ricerca di sottostringhe nei messaggi di bcdd", presenti.len == 0, $presenti)

  # --- L-E7: Completa da zero con lo scopo ancora da compilare, nelle due lingue dell'interfaccia e dei due prefissi dello scheletro
  block:
    for (ui, prefisso, atteso) in [("en", "to be filled in: what Light is responsible for", "Complete starts from the purpose"), ("en", "da compilare: di che cosa è responsabile Light", "Complete starts from the purpose"),
        ("it", "to be filled in: what Light is responsible for", "Completa parte dallo scopo"), ("it", "da compilare: di che cosa è responsabile Light", "Completa parte dallo scopo")]:
      let d = newWd0()
      writeFile(d / "Light.csc", "CSC Light VERSION 0.1\n  PURPOSE \"" & prefisso & "\"\nEND\n")
      var s = sessLingua(@["--lang", ui], "#alb:@csc|#alb:@csc/Light|@b-completa|?f-scopo-prima", @[("BCDD_LANG", "")], d)
      let q = sondeDi(s)
      rec("L-E7", ui & ", «" & prefisso[0 .. 8] & "…»: apre «scrivi prima lo scopo»", q.len >= 1 and "visibile" in q[0] and atteso in q[0] and azioniLanci(s).count("refine") == 0, $q & " " & $azioniLanci(s))
      s.finisci()

  # --- L-E8: parità dei cataloghi (pagina e Nim)
  block:
    let sorg = readFile(root / "editor" / "pagina" / "testi.js")
    let a0 = sorg.find("var TESTI = ")
    let corpo = sorg[a0 + len("var TESTI = ") .. sorg.rfind(";") - 1]
    var j: JsonNode
    try: j = parseJson(corpo)
    except CatchableError: j = nil
    rec("L-E8", "testi.js si legge come JSON, con le sole due lingue it ed en", j != nil and j.kind == JObject and toSeq(j.keys).sorted == @["en", "it"], "")
    if j != nil and j.kind == JObject and j.hasKey("it") and j.hasKey("en"):
      let ki = toSeq(j["it"].keys).sorted
      let ke = toSeq(j["en"].keys).sorted
      rec("L-E8", "TESTI.it e TESTI.en: le stesse chiavi (" & $ki.len & ")", ki == ke and ki.len > 400, $ki.filterIt(it notin ke) & $ke.filterIt(it notin ki))
      proc segn(t: string): seq[string] =
        var i = 0
        while i < t.len:
          if t[i] == '{':
            var k = i + 1
            while k < t.len and t[k] in {'0'..'9'}: inc k
            if k < t.len and t[k] == '}' and k > i + 1: result.add t[i .. k]
            i = k
          else: inc i
        result = result.deduplicate.sorted
      var vuoti, diversi: seq[string]
      for k in ki:
        let vi = j["it"][k].getStr
        let ve = j["en"][k].getStr
        if vi.strip.len == 0 or ve.strip.len == 0: vuoti.add k
        if segn(vi) != segn(ve): diversi.add k
      rec("L-E8", "nessun valore vuoto e gli stessi segnaposto per chiave nelle due lingue (pagina)", vuoti.len == 0 and diversi.len == 0, $vuoti & $diversi)
      # le chiavi usate nella pagina esistono tutte
      let js = readFile(root / "editor" / "pagina" / "pagina.js") & readFile(root / "editor" / "pagina" / "pagina.html")
      var usate: seq[string]
      var i = 0
      while true:
        i = js.find("T('", i)
        if i < 0: break
        let k = js.find('\'', i + 3)
        usate.add js[i + 3 ..< k]
        i = k
      var mancano: seq[string]
      for u in usate.deduplicate:
        if u notin ki and not ki.anyIt(it.startsWith(u)): mancano.add u
      rec("L-E8", "ogni chiave T('…') della pagina c'è nel catalogo", mancano.len == 0, $mancano)
    var vuotiN, diversiN: seq[string]
    for k in Chiave:
      let (vi, ve) = (voci[k].it, voci[k].en)
      if vi.strip.len == 0 or ve.strip.len == 0: vuotiN.add $k
      proc segnN(t: string): seq[string] =
        for c in '1' .. '9': (if ("$" & $c) in t: result.add "$" & $c)
      if segnN(vi) != segnN(ve): diversiN.add $k
    rec("L-E8", "edtesti.nim: nessun valore vuoto, stessi segnaposto per chiave nelle due lingue (" & $(ord(high(Chiave)) + 1) & " voci)", vuotiN.len == 0 and diversiN.len == 0, $vuotiN & $diversiN)

  # --- L-E9: nessun testo fuori dai cataloghi (parole spia o lettere accentate dentro un letterale)
  block:
    proc letterali(src: string, apici: set[char]): seq[(int, string)] =
      ## i letterali fra apici nelle righe che non sono commenti (euristica: toglie `//` o `#` a fine riga fuori dai letterali)
      var n = 0
      for riga in src.splitLines:
        inc n
        let t = riga.strip
        if t.startsWith("//") or t.startsWith("#"): continue
        var i = 0
        while i < riga.len:
          let c = riga[i]
          if c in apici:
            var k = i + 1
            while k < riga.len and riga[k] != c:
              if riga[k] == '\\': inc k
              inc k
            if k < riga.len: result.add (n, riga[i + 1 ..< k])
            i = k + 1
          elif c == '/' and i + 1 < riga.len and riga[i + 1] == '/': break
          elif c == '#' and apici == {'"'}: break
          else: inc i
    # eccezioni, con il motivo: nomi di classi CSS e di attributi, parole del linguaggio BCDD in un letterale, valori di protocollo
    let eccezioni = ["STATUS RATIFIED BY", "COMPOSED OF", "BIND ", "pannello scheda", "completa approva"]     # parole del linguaggio BCDD e classi CSS di pagina.html
    var fuori: seq[string]
    for (f, apici) in [("pagina/pagina.js", {'\''}), ("pagina/pagina.html", {'"'}), ("edmodello.nim", {'"'}), ("edfinestra.nim", {'"'}), ("edazioni.nim", {'"'}), ("bcddeditor.nim", {'"'}), ("edbcdd.nim", {'"'})]:
      var src = readFile(root / "editor" / f)
      if f.endsWith(".html"):
        # nell'HTML contano solo i testi fra i tag e gli attributi di testo: gli attributi `data-t*` hanno chiavi
        src = src.replace("<style>", "<!--").replace("</style>", "-->")
      for (n, t) in letterali(src, apici):
        let sp = spie(t)
        var accentata = false
        for c in t:
          if c in {'\xC3'}: accentata = true      # À-ÿ in UTF-8 cominciano con 0xC3
        # i nomi di classi, id e selettori CSS (con trattino, #, o una sola parola minuscola) non sono testo per la persona
        let identificatore = t.len > 0 and (t.allCharsInSet({'a'..'z', '0'..'9', '_', '-', '#', '.', ',', ' ', ':', '@', '>', '[', ']', '=', '"'}) and ('-' in t or '#' in t or ' ' notin t.strip))
        if (sp.len > 0 or accentata) and not identificatore and not eccezioni.anyIt(it in t):
          fuori.add f & ":" & $n & " «" & cut(t, 60) & "»"
    rec("L-E9", "nessun letterale con parole spia o lettere accentate fuori dai cataloghi", fuori.len == 0, fuori.join("\n        "))

  # --- L-E10: le correzioni di revisione linguistica stanno nel catalogo italiano
  block:
    let testiIt = readFile(root / "editor" / "pagina" / "testi.js")
    var nim = ""
    for k in Chiave: nim.add voci[k].it & "\n"
    let attese = [
      ("tooltip delle forme senza STATUS HYPOTHESIS", "non sono da approvare"),
      ("«Dai un nome…»: dopo AS", "scrivilo in fondo alla riga, dopo AS"),
      ("scheletro dell'estensione", "sostituisci NOME e completa i testi «da completare»"),
      ("nome non valido, con i verbi", "non è valido: usa lettere, cifre e il trattino basso (_), comincia con una lettera, al massimo 64 caratteri"),
      ("«Esiste già un nome uguale»", "Esiste già un nome uguale"),
      ("gruppo «Senza connettore»", "\"Senza connettore\""),
      ("il piano di prova non ha uno stato di approvazione", "Il piano di prova non ha uno stato di approvazione"),
      ("«Unità della risoluzione»", "Unità della risoluzione")]
    for (che, frase) in attese:
      rec("L-E10", che, frase in testiIt, "")
    rec("L-E10", "la formulazione del nome non valido è la stessa in Nim", "non è valido: usa lettere, cifre e il trattino basso (_), comincia con una lettera, al massimo 64 caratteri" in nim, "")
    rec("L-E10", "niente più «non va bene: ci vogliono», «C'è già:» né PROFILE e «non c'è» nelle descrizioni dei gruppi",
      "ci vogliono" notin testiIt & nim and "\"C'è già" notin testiIt and "(PROFILE)" notin testiIt and "il cui connettore non c'è" notin testiIt, "")
    # le prove che mancavano: gruppo «Senza connettore», «Togli» su blocco e su profilo, IMPORT «non trovato», messaggio del punto 0a
    let w12 = root / "editor" / "prove" / "w12" / "luce"
    block:
      let d = newWd0()
      writeFile(d / "Forme.csc", "BINDING Luce VERSION 0.1 AS forme\n  STATUS HYPOTHESIS\nEND\n")
      var s = sessLingua(@["--lang", "it"], "?albero", @[], d)
      let q = sondeDi(s)
      rec("L-E10", "il gruppo «Senza connettore (1)» c'è nell'albero", q.len >= 1 and "Senza connettore (1)" in q[0], $q)
      s.finisci()
    block:
      let d = copiaCartella(w12)
      removeFile(d / "Segnale.csc")
      var s = sessLingua(@["--lang", "it"], "#alb:@csc|#alb:@csc/Luce|?scheda-righe", @[], d)
      let q = sondeDi(s)
      rec("L-E10", "IMPORT di un profilo che non c'è: la riga dice «non trovato: profilo Segnale»", q.len >= 1 and "non trovato: profilo Segnale" in q[0], cut($q, 400))
      s.finisci()
    # il titolo delle forme concrete con un nome uguale alla parola («forms» / «forme»): il nome sta fra virgolette, la parola resta parola
    for (ui, atteso, tab) in [("en", "Concrete forms “forms” of Light", "Concrete forms · “forms”"), ("it", "Forme concrete «forms» di Light", "Forme concrete · «forms»")]:
      var s = sessLingua(@["--lang", ui], "#c-Light|@lg-b0|?scheda-nome|?scheda-linguette", @[("BCDD_LANG", "")], "", "Hall")
      let q = sondeDi(s)
      rec("L-E10", ui & ": il titolo delle forme concrete con il nome «forms» è «" & atteso & "»", q.len >= 2 and atteso in q[0] and tab in q[1], $q)
      s.finisci()
    block:
      var s = sessLingua(@["--lang", "it"], "#alb:@csc|#alb:@csc/Luce|@lg-b0|?scheda-nome", @[], copiaCartella(w12))
      let q = sondeDi(s)
      rec("L-E10", "it: con il nome «forme» il titolo è «Forme concrete «forme» di Luce»", q.len >= 1 and "Forme concrete «forme» di Luce" in q[0], $q)
      s.finisci()
    block:
      let d = copiaCartella(w12)
      var s = sessLingua(@["--lang", "it"], "#alb:@csc|#alb:@csc/Luce|@lg-b0|@b-togli-blocco|?scheda-modulo", @[], d)
      let q = sondeDi(s)
      rec("L-E10", "«Togli le forme concrete…»: la conferma nomina le forme, il connettore e il file",
        q.len >= 1 and "Tolgo le forme concrete «forme» di Luce dal file Luce.csc?" in q[0] and "Torna indietro di un'azione" in q[0], cut($q, 400))
      s.finisci()
    block:
      let d = newWd0()
      copyFile(w12 / "Segnale.csc", d / "Segnale.csc")
      var s = sessLingua(@["--lang", "it"], "#alb:@pro|#alb:@pro/Segnale|@b-togli-profilo|?scheda-modulo", @[], d)
      let q = sondeDi(s)
      rec("L-E10", "«Togli il profilo…»: la conferma nomina il profilo e il file", q.len >= 1 and "Tolgo il profilo Segnale? Si toglie il file Segnale.csc" in q[0], cut($q, 400))
      s.finisci()
    block:
      let d = copiaCartella(w12)
      var s = sessLingua(@["--lang", "it"], "#alb:@csc|#alb:@csc/Luce|@a-sel-K2|=a-num:D-11|@a-ok", @[], d)
      discard attendi(s.trace, "pagina 2", 30)
      sleep(500)
      let p2 = paginaN(s, 2)
      rec("L-E10", "punto 0a: dopo Approva restano da approvare finché il profilo non è approvato", "restano da approvare finché il profilo Segnale non è approvato" in p2, cut(p2[max(0, p2.len - 300) .. ^1]))
      s.finisci()

  # --- L-E11: la suite esistente gira in italiano (BCDD_LANG=it): il resto di questo file; gli attesi cambiati sono quelli di L-E10
  rec("L-E11", "la suite gira con BCDD_LANG=it e lingua dell'editor it", getEnv("BCDD_LANG") == "it" and lingua == lgIt, getEnv("BCDD_LANG"))


# --- AC-248: le regole di Windows dell'editor, che si provano anche su Linux, e la forma del livello WebView2 (la finestra si prova sul PC)
block:
  rec("AC-248", "citaArgomento: senza spazi invariato, vuoto e con spazi fra virgolette, barre e virgolette come CommandLineToArgvW",
    citaArgomento("--lang") == "--lang" and citaArgomento("") == "\"\"" and citaArgomento("a b") == "\"a b\"" and
    citaArgomento("a\"b") == "\"a\\\"b\"" and citaArgomento("c:\\x y\\") == "\"c:\\x y\\\\\"" and
    lineaComando(@["bcdd.exe", "--lang", "it", "a b"]) == "bcdd.exe --lang it \"a b\"", citaArgomento("c:\\x y\\"))
  rec("AC-248", "nomi di dispositivo (CON, nul.csc, Com1, LPT9) rifiutati, COM0 e Console accettati",
    nomeDispositivoWindows("CON") and nomeDispositivoWindows("nul.csc") and nomeDispositivoWindows("Com1.csc") and nomeDispositivoWindows("LPT9") and
    not nomeDispositivoWindows("COM0") and not nomeDispositivoWindows("Console.csc") and not nomeDispositivoWindows("Luce.csc"), "")
  rec("AC-248", "nomeFileAccettabile: né / né \\ né :, né dispositivi, né vuoto",
    nomeFileAccettabile("Luce.csc") and not nomeFileAccettabile("a/b.csc") and not nomeFileAccettabile("a\\b.csc") and not nomeFileAccettabile("c:b.csc") and
    not nomeFileAccettabile("AUX.csc") and not nomeFileAccettabile(""), "")
  let ed = root / "editor"
  let w2 = readFile(ed / "edwebview2.nim")
  let cc = readFile(ed / "windows" / "edwv2.cc")
  let fin = readFile(ed / "edfinestra.nim")
  rec("AC-248", "edfinestra non lega GTK né WebKit (sta in edgtkfin) né WebView2 (sta in edwebview2)",
    "webkit_" notin fin and "gtk_" notin fin and "webview_" notin fin and "import edfin," in fin, "")
  rec("AC-248", "livello WebView2: menu, tasti del browser, zoom, navigazione oltre la prima, finestre nuove e permessi chiusi; processi senza console",
    "put_AreDefaultContextMenusEnabled(FALSE)" in cc and "put_AreBrowserAcceleratorKeysEnabled(FALSE)" in cc and "put_IsZoomControlEnabled(FALSE)" in cc and
    "put_Cancel(TRUE)" in cc and "put_Handled(TRUE)" in cc and "COREWEBVIEW2_PERMISSION_STATE_DENY" in cc and
    "CREATE_NO_WINDOW" in readFile(ed / "edprocwin.nim"), "")
  rec("AC-248", "livello WebView2: niente innerHTML né eval nel Nim, DevTools solo con la versione di prova e la variabile, nessun accesso alla rete",
    "innerHTML" notin w2 and "webview_navigate" notin w2 and "when defined(bcddEditorProva): getEnv(\"BCDD_EDITOR_DEVTOOLS\")" in w2.replace("let debug = ", "") , "")

# 080:9:1 Verdetto compatto

# 080:10:1 AC-249: senza `--dir` si sceglie la cartella con la finestra del sistema; l'ultima cartella è ricordata
if not xvfbOk:
  senzaXvfb("AC-249", "sessione con Xvfb")
else:
  let titoloScelta = "Scegli una o più cartelle con i file CSC"
  block:
    # (a) la finestra compare, parte dalla cartella ricordata (se c'è ancora), e Esc annulla con codice 0 e senza messaggi
    let cartellaA = copiaCartella(root / "prove" / "f3" / "luce")
    var s = nuovaSessione()
    createDir s.dir / "xdg_config" / "bcdd-editor"
    writeFile(s.dir / "xdg_config" / "bcdd-editor" / "cartella", cartellaA & "\n")
    s.avviaEditor(@[], root)
    let w = trovaFinestra(display, titoloScelta, 10)
    rec("AC-249", "senza --dir compare la finestra di scelta della cartella (titolo dal catalogo)", w.len > 0, "nessuna finestra")
    rec("AC-249", "...che parte dall'ultima cartella ricordata", attendi(s.trace, "scelta cartella iniziale=" & cartellaA, 5), leggiSe(s.trace))
    rec("AC-249", "...e l'editor non si è aperto intanto", "pagina 1" notin leggiSe(s.trace), "")
    if w.len > 0:
      discard xdo(display, @["windowfocus", "--sync", w])
      discard xdo(display, @["key", "--window", w, "Escape"])
      discard xdo(display, @["key", "Escape"])
    var fineA = epochTime() + 5.0
    while s.p.running and epochTime() < fineA: sleep(100)
    rec("AC-249", "Esc nella finestra: l'editor esce con 0 e senza messaggi", not s.p.running and s.p.peekExitCode == 0 and leggiSe(s.dir / "errori").len == 0,
      "in corso " & $s.p.running & " errori [" & leggiSe(s.dir / "errori") & "]")
    s.finisci()
  block:
    # (a2) la cartella ricordata non c'è più: la finestra parte senza cartella
    var s = nuovaSessione()
    createDir s.dir / "xdg_config" / "bcdd-editor"
    writeFile(s.dir / "xdg_config" / "bcdd-editor" / "cartella", tmpBase / "non_c_e_piu" & "\n")
    s.avviaEditor(@[], root)
    rec("AC-249", "cartella ricordata sparita: la finestra parte senza cartella", attendi(s.trace, "scelta cartella iniziale=\n", 8), leggiSe(s.trace))
    s.finisci()
  block:
    # (b) scelta di una cartella (la finestra è sostituita dal gancio della versione di prova): si apre e si ricorda
    let cartellaB = copiaCartella(root / "prove" / "f3" / "luce")
    var s = nuovaSessione()
    s.avviaEditor(@["--lang", "it"], root, @[("BCDD_EDITOR_PROVA_CARTELLA", cartellaB)])
    rec("AC-249", "scelta una cartella l'editor si apre su quella", attendi(s.trace, "pagina 1", 20) and trovaFinestra(display, "bcdd-editor: " & cartellaB, 5).len > 0, leggiSe(s.trace))
    let f = s.dir / "xdg_config" / "bcdd-editor" / "cartella"
    rec("AC-249", "...e la ricorda (percorso assoluto + LF, accanto al file della lingua)", leggiSe(f) == cartellaB & "\n", "[" & leggiSe(f) & "]")
    s.finisci()
    # al giro dopo la finestra parte da lì
    var s2 = nuovaSessione()
    createDir s2.dir / "xdg_config" / "bcdd-editor"
    writeFile(s2.dir / "xdg_config" / "bcdd-editor" / "cartella", readFile(f))
    s2.avviaEditor(@[], root)
    rec("AC-249", "riaprendo senza --dir la finestra parte dalla cartella ricordata", attendi(s2.trace, "scelta cartella iniziale=" & cartellaB & "\n", 8), leggiSe(s2.trace))
    s2.finisci()
  block:
    # (c) annullare: codice 0, nessun messaggio, nessuna finestra dell'editor, nessun file ricordato
    var s = nuovaSessione()
    s.avviaEditor(@[], root, @[("BCDD_EDITOR_PROVA_CARTELLA", "-")])
    let codice = s.p.waitForExit(10000)
    rec("AC-249", "annullando la scelta l'editor esce con 0, senza messaggi e senza aprirsi",
      codice == 0 and leggiSe(s.dir / "errori").len == 0 and "pagina 1" notin leggiSe(s.trace) and not fileExists(s.dir / "xdg_config" / "bcdd-editor" / "cartella"),
      "codice " & $codice & " errori [" & leggiSe(s.dir / "errori") & "]")
    s.finisci()
  block:
    # (d) con --dir non cambia niente: nessuna finestra di scelta, la cartella è ricordata
    let cartellaD = copiaCartella(root / "prove" / "f3" / "luce")
    var s = nuovaSessione()
    s.avviaEditor(@["--dir", cartellaD], root, @[("BCDD_EDITOR_PROVA_CARTELLA", "-")])
    rec("AC-249", "con --dir l'editor si apre senza la scelta (anche col gancio che annullerebbe)", attendi(s.trace, "pagina 1", 20) and "scelta" notin leggiSe(s.trace), leggiSe(s.trace))
    rec("AC-249", "...e ricorda la cartella", leggiSe(s.dir / "xdg_config" / "bcdd-editor" / "cartella") == cartellaD & "\n", "")
    s.finisci()
  block:
    # --dir con una cartella che non c'è: l'errore di prima, e niente da ricordare
    var s = nuovaSessione()
    s.avviaEditor(@["--dir", tmpBase / "non_c_e"], root)
    let codice = s.p.waitForExit(10000)
    rec("AC-249", "--dir con una cartella che non c'è: codice 2 e nessuna cartella ricordata", codice == 2 and not fileExists(s.dir / "xdg_config" / "bcdd-editor" / "cartella"), "codice " & $codice)
    s.finisci()

# 080:11:1 AC-250: più cartelle, tutte uguali; la finestra di scelta moderna
if not xvfbOk:
  senzaXvfb("AC-250", "sessione con Xvfb")
else:
  let luce = root / "prove" / "f3" / "luce"
  proc cartellaAltra(): string =
    ## Una cartella con un solo file, `Altra.csc`, scritto da `bcdd new`.
    result = newWd0()
    discard runBcdd(@["new", "Altra"], result)
  proc cartellaDoppia(): string =
    ## Una cartella con un file che ha lo stesso nome di uno della cartella `luce`.
    result = newWd0()
    copyFile(luce / "Pulsante.csc", result / "Pulsante.csc")
  proc sonde250(s: Sess): seq[string] = leggiSe(s.trace).splitLines().filterIt("sonda Q:" in it).mapIt(it[it.find("sonda Q:") + 8 .. ^1])
  block:
    # (a) due --dir: la finestra le mostra, ogni check le riceve tutte nell'ordine, l'insieme è ricordato, il file nuovo nasce nella cartella evidenziata
    let a = copiaCartella(luce)
    let b = cartellaAltra()
    var s = nuovaSessione()
    s.avviaEditor(@["--lang", "it", "--dir", a, "--dir", b, "LuceScale"], root,
      @[("BCDD_EDITOR_PROVA_CLIC", "@b-cartelle|?cartelle-elenco|?cartelle-nota|#car:1|?cartelle-nota|@b-nuova|=f-nome:Nuova|=f-scopo:una prova|@f-ok")])
    let fine = attendi(s.trace, "pagina 3", 40)
    rec("AC-250", "due --dir: l'editor si apre, titolo con la prima cartella e «+1»", attendi(s.trace, "pagina 1", 20) and trovaFinestra(display, "bcdd-editor: " & a & " \\+1", 5).len > 0, leggiSe(s.trace))
    rec("AC-250", "...e ricorda le due cartelle, una per riga", leggiSe(s.dir / "xdg_config" / "bcdd-editor" / "cartella") == a & "\n" & b & "\n", "[" & leggiSe(s.dir / "xdg_config" / "bcdd-editor" / "cartella") & "]")
    let l = righe(s.lanci)
    rec("AC-250", "il check di un file della prima cartella riceve tutte le cartelle, nell'ordine (`.` per la sua)",
      l.anyIt(it == "check --json --dir . --dir " & b & " LuceScale.csc"), $l)
    rec("AC-250", "il check del file della seconda cartella: la prima per percorso, la sua `.`",
      l.anyIt(it == "check --json --dir " & a & " --dir . Altra.csc"), $l)
    let q = sonde250(s)
    rec("AC-250", "l'elenco è raggruppato per cartella: i file di ognuna sotto la sua",
      q.len >= 1 and q[0].find(a.lastPathPart) >= 0 and q[0].find("LuceScale.csc") > q[0].find(a.lastPathPart) and q[0].find(b.lastPathPart) > q[0].find("LuceScale.csc") and
      q[0].find("Altra.csc") > q[0].find(b.lastPathPart), $q)
    rec("AC-250", "la nota dice la cartella evidenziata (la prima), poi la seconda dopo il clic",
      q.len >= 3 and ("nella cartella evidenziata: " & a) in q[1] and ("nella cartella evidenziata: " & b) in q[2], $q)
    rec("AC-250", "il file nuovo nasce nella cartella selezionata (la seconda), non nella prima", fine and fileExists(b / "Nuova.csc") and not fileExists(a / "Nuova.csc"), cut(leggiSe(s.trace), 600))
    rec("AC-250", "...e `save` lo scrive con la cartella corrente della seconda", l.anyIt(it == "save Nuova.csc --expect nuovo"), $l)
    s.finisci()
  block:
    # (b) «Aggiungi cartella…» (gancio di prova): l'insieme cresce, è ricordato; un nome doppio è tenuto una volta sola e c'è l'avviso
    let a = copiaCartella(luce)
    let c = cartellaDoppia()
    var s = nuovaSessione()
    s.avviaEditor(@["--lang", "it", "--dir", a, "LuceScale"], root,
      @[("BCDD_EDITOR_PROVA_AGGIUNGI", c & "|" & a), ("BCDD_EDITOR_PROVA_CLIC", "@b-cartelle|!b-cartella-togli|@b-cartella-aggiungi|?cartelle-elenco|?avviso|?esito|!b-cartella-togli")])
    discard attendi(s.trace, "pagina 2", 40)
    sleep(300)
    let q = sonde250(s)
    rec("AC-250", "con una cartella sola «Togli cartella» è spento", q.len >= 1 and "spento" in q[0], $q)
    rec("AC-250", "«Aggiungi cartella…» aggiunge la cartella nuova; quella già nell'elenco è rifiutata con una frase",
      q.len >= 4 and (c.lastPathPart) in q[1] and ("«" & a & "» è già nell'elenco") in q[3], $q)
    rec("AC-250", "il file con lo stesso nome è lasciato fuori e l'avviso lo dice, con la cartella tenuta e quella lasciata fuori",
      q.len >= 3 and "Pulsante.csc è in più cartelle" in q[2] and ("si usa quello in " & a) in q[2] and ("Quello in " & c & " non si usa") in q[2], $q)
    rec("AC-250", "...e `bcdd` controlla Pulsante.csc una volta sola (quello della prima cartella)", righe(s.lanci).filterIt(it.endsWith(" Pulsante.csc") and c in it).len == 1 and not righe(s.lanci).anyIt(it.contains("--dir " & a & " --dir .")), $righe(s.lanci))
    rec("AC-250", "...e «Togli cartella» ora è acceso", q.len >= 5 and "acceso" in q[4], $q)
    rec("AC-250", "l'insieme ricordato ha le due cartelle", leggiSe(s.dir / "xdg_config" / "bcdd-editor" / "cartella") == a & "\n" & c & "\n", "[" & leggiSe(s.dir / "xdg_config" / "bcdd-editor" / "cartella") & "]")
    s.finisci()
  block:
    # (c) «Togli cartella» toglie la evidenziata e riscrive l'insieme; l'ultima non si toglie
    let a = copiaCartella(luce)
    let b = cartellaAltra()
    var s = nuovaSessione()
    s.avviaEditor(@["--lang", "it", "--dir", a, "--dir", b, "LuceScale"], root,
      @[("BCDD_EDITOR_PROVA_CLIC", "@b-cartelle|#car:1|@b-cartella-togli|?cartelle-elenco|!b-cartella-togli")])
    discard attendi(s.trace, "pagina 3", 40)
    sleep(300)
    let q = sonde250(s)
    rec("AC-250", "togliendo la seconda restano la prima e i suoi file", q.len >= 2 and a.lastPathPart in q[0] and b.lastPathPart notin q[0] and "LuceScale.csc" in q[0], $q)
    rec("AC-250", "...l'insieme ricordato è la sola prima cartella e i file della seconda non sono toccati",
      leggiSe(s.dir / "xdg_config" / "bcdd-editor" / "cartella") == a & "\n" and fileExists(b / "Altra.csc"), "[" & leggiSe(s.dir / "xdg_config" / "bcdd-editor" / "cartella") & "]")
    rec("AC-250", "...e l'ultima cartella non si toglie (comando spento)", q.len >= 2 and "spento" in q[1], $q)
    s.finisci()
  block:
    # (d) la finestra di scelta all'avvio con più cartelle (gancio): tutte aperte e ricordate; una senza percorso locale è rifiutata con un messaggio
    let a = copiaCartella(luce)
    let b = cartellaAltra()
    var s = nuovaSessione()
    s.avviaEditor(@["--lang", "it"], root, @[("BCDD_EDITOR_PROVA_CARTELLA", a & "|" & b)])
    rec("AC-250", "la scelta di due cartelle le apre tutte e due, nell'ordine, e le ricorda",
      attendi(s.trace, "pagina 1", 20) and leggiSe(s.dir / "xdg_config" / "bcdd-editor" / "cartella") == a & "\n" & b & "\n", cut(leggiSe(s.trace)))
    s.finisci()
    var s2 = nuovaSessione()
    s2.avviaEditor(@["--lang", "it"], root, @[("BCDD_EDITOR_PROVA_CARTELLA", a & "|!smb://server/condivisa")])
    let codice = s2.p.waitForExit(10000)
    let err = leggiSe(s2.dir / "errori")
    rec("AC-250", "una cartella senza percorso locale: messaggio chiaro, codice 2, niente aperto né ricordato",
      codice == 2 and "«smb://server/condivisa» non si può usare perché" in err and "pagina 1" notin leggiSe(s2.trace) and not fileExists(s2.dir / "xdg_config" / "bcdd-editor" / "cartella"),
      "codice " & $codice & " [" & err & "]")
    s2.finisci()
  block:
    # (e) il file di una riga di vale come insieme di una cartella; una cartella ricordata sparita non si riapre
    let a = copiaCartella(luce)
    var s = nuovaSessione()
    createDir s.dir / "xdg_config" / "bcdd-editor"
    writeFile(s.dir / "xdg_config" / "bcdd-editor" / "cartella", tmpBase / "sparita" & "\n" & a & "\n")
    s.avviaEditor(@[], root)
    rec("AC-250", "la finestra di scelta parte dalla prima cartella ricordata che esiste ancora", attendi(s.trace, "scelta cartella iniziale=" & a & "\n", 8), leggiSe(s.trace))
    s.finisci()
  block:
    # (f) il percorso scritto a mano con Ctrl+L, nella finestra GTK vera: la cartella si apre e si ricorda
    let a = copiaCartella(luce)
    var s = nuovaSessione()
    s.avviaEditor(@["--lang", "it"], root)
    let w = trovaFinestra(display, "Scegli una o più cartelle con i file CSC", 10)
    if w.len > 0:
      discard xdo(display, @["windowfocus", "--sync", w])
      discard xdo(display, @["key", "ctrl+l"])
      sleep(300)
      discard xdo(display, @["type", "--delay", "20", a])
      sleep(300)
      discard xdo(display, @["key", "Return"])
      sleep(500)
      if not attendi(s.trace, "pagina 1", 3): discard xdo(display, @["key", "Return"])
    rec("AC-250", "GTK: Ctrl+L, il percorso scritto, Invio: l'editor si apre su quella cartella e la ricorda",
      w.len > 0 and attendi(s.trace, "pagina 1", 15) and leggiSe(s.dir / "xdg_config" / "bcdd-editor" / "cartella") == a & "\n", "finestra " & w & " " & cut(leggiSe(s.trace)))
    s.finisci()
  # sorgenti: la finestra moderna di Windows e le opzioni di GTK
  let ed250 = root / "editor"
  let pw = readFile(ed250 / "edprocwin.nim")
  let gt = readFile(ed250 / "edgtkfin.nim")
  rec("AC-250", "Windows: IFileOpenDialog con FOS_PICKFOLDERS, FOS_FORCEFILESYSTEM e FOS_ALLOWMULTISELECT, risultati con GetResults; niente SHBrowseForFolderW",
    "fosPickFolders" in pw and "fosForceFileSystem" in pw and "fosAllowMultiSelect" in pw and "27)(d" in pw and "sigdnFileSysPath" in pw and "SHBrowseForFolderW" notin pw, "")
  rec("AC-250", "GTK: scelta multipla e local-only spento; il percorso locale con g_file_get_path, la cartella senza percorso è rifiutata",
    "gtk_file_chooser_set_select_multiple(d, 1)" in gt and "gtk_file_chooser_set_local_only(d, 0)" in gt and "g_file_get_path" in gt and "rifiutate.add" in gt, "")

block:
  # AC-417: il comando «Ricarica»
  if not xvfbOk: senzaXvfb("AC-417", "sessione con Xvfb")
  else:
    block:
      # (a) senza modifiche: ricarica SEMPRE, anche se la firma della cartella è uguale (il ritorno del fuoco l'ha già aggiornata), e ridisegna; nessuna scrittura
      let d = copiaCartella(root / "prove" / "f3" / "luce")
      let f = d / "LuceScale.csc"
      var s = nuovaSessione()
      s.avviaEditor(@["--lang", "it", "--dir", d, "LuceScale"], root, @[("BCDD_EDITOR_PROVA_CLIC", "~|!b-ricarica|~b-ricarica|@b-ricarica|?esito")])
      let pronto = attendi(s.trace, "attesa_fuoco", 40)
      rec("AC-417", "la finestra si apre e il comando aspetta il ritorno del fuoco", pronto, cut(leggiSe(s.dir / "errori")))
      if pronto:
        let w = trovaFinestra(display, "bcdd-editor")
        let lanciPrima = nLanci(s)
        writeFile(f, leggiSe(f).replace("La luce delle scale", "La luce delle scalo"))   # stessa lunghezza
        let dopo = fotografia(d)
        focusAltrove(display, w)
        let fine = attendi(s.trace, "pagina 3", 20)
        sleep(300)
        raccogli(s)
        rec("AC-417", "il ritorno del fuoco ridisegna (file cambiato) e il clic su Ricarica ridisegna ancora, con la firma già uguale: tre disegni", fine and nDisegni(s) == 3 and "controllato" notin leggiSe(s.trace), $nDisegni(s) & " " & righe(s.trace).filterIt(not it.contains("lancio")).join(" / "))
        rec("AC-417", "il disegno di Ricarica ha il testo cambiato fuori", "La luce delle scalo" in paginaN(s, 3), cut(paginaN(s, 3)))
        rec("AC-417", "bcdd è stato rilanciato da Ricarica: tre giri di check su tutti i file (apertura, ritorno del fuoco, Ricarica)", lanciPrima > 0 and nLanci(s) >= 3 * lanciPrima and azioniLanci(s).allIt(it == "check"), $azioniLanci(s))
        rec("AC-417", "Ricarica non scrive niente", fotografia(d) == dopo, "cartella cambiata")
        let q = sondeDi(s)
        rec("AC-417", "il comando è acceso, con la dicitura «Ricarica» e il suggerimento in italiano", q.len >= 2 and "acceso" in q[0] and "titolo=Rilegge i file dal disco e rifà il controllo" in q[1], $q)
        rec("AC-417", "lo Stato dice «ricaricato dal disco»", q.len >= 3 and "ricaricato dal disco" in q[2], $q)
      s.finisci()
    block:
      # (b) con una modifica non salvata: compare la scelta; «annulla» tiene la modifica (nessun disegno, nessun lancio); «ricarica» la perde
      let d = copiaCartella(root / "prove" / "f3" / "luce")
      var s = nuovaSessione()
      s.avviaEditor(@["--lang", "it", "--dir", d, "LuceScale"], root,
        @[("BCDD_EDITOR_PROVA_CLIC", "@b-nuova|=f-nome:Zeta|@b-ricarica|?avviso|@f-ricarica-no|!f-nome|?avviso|@b-ricarica|@f-ricarica-si|?f-nome|?avviso")])
      let fine = attendi(s.trace, "pagina 2", 40)
      sleep(400)
      raccogli(s)
      let q = sondeDi(s)
      rec("AC-417", "la sessione risponde a tutte le sonde e disegna due volte (apertura e ricarica)", fine and q.len >= 5 and nDisegni(s) == 2, $nDisegni(s) & " " & $q)
      if q.len >= 5:
        rec("AC-417", "con la modifica non salvata compare la scelta con le due uscite", "visibile" in q[0] and "C'è una modifica non salvata" in q[0] and "Ricarica e perdi la modifica" in q[0] and "Annulla e tieni la modifica" in q[0], cut(q[0]))
        rec("AC-417", "«Annulla» tiene la modifica: il campo ha ancora il valore e la scelta sparisce", "valore=Zeta" in q[1] and "nascosto" in q[2], $q)
        rec("AC-417", "«Ricarica e perdi la modifica» chiude il modulo: la modifica è persa", "assente" in q[3] and "nascosto" in q[4], $q)
      rec("AC-417", "niente è scritto: nessun save, nessun new, Zeta.csc non esiste", azioniLanci(s).allIt(it == "check") and not fileExists(d / "Zeta.csc"), $azioniLanci(s))
      s.finisci()
    # nessun timer né osservatore di file nel comando (e-8)
    let fin = readFile(root / "editor" / "edfinestra.nim")
    let i0 = fin.find("if az == \"ricarica\":")
    rec("AC-417", "il comando non introduce timer né osservatori: nessun g_timeout né monitor nella sua parte", i0 > 0 and "timeout" notin fin[i0 ..< i0 + 600] and "monitor" notin fin[i0 ..< i0 + 600].toLowerAscii, "")
    rec("AC-417", "nel ramo comune: l'azione sta in edfinestra.nim, che serve sia GTK sia WebView2 (il ponte passa da alMessaggio), la pagina è la stessa", i0 > 0 and "edfinestra" in readFile(root / "editor" / "bcddeditor.nim") and "alMessaggio" in fin, "")

block:
  # AC-418: i riferimenti interni nei testi. Fonte dei nomi: `check --json` (blocchi, dichiarazioni, garanzie), niente dal testo.
  let d = newWd0()
  writeFile(d / "TrasportoLicenza.csc", "CSC TrasportoLicenza VERSION 0.2\n  STATUS HYPOTHESIS\n  PURPOSE \"Il trasporto dei documenti\"\n" &
    "  TYPE DocumentoLicenza := VERBAL \"un documento di licenza\"\n  EVENT IN  consegna(documento: DocumentoLicenza)\n" &
    "  GUARANTEE tl2: VERBAL \"Ogni consegna completa riceve esattamente un esito\"\n                 VERIFY BY INSPECTION \"le consegne e gli esiti registrati\"\n" &
    "  ASSUME tl-a1: VERBAL \"Il telefono risponde\"\n                VERIFY BY JUDGEMENT \"l'operatore\"\nEND\n")
  writeFile(d / "Sessione.csc", "CSC Sessione VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"Per la consegna vale quanto promesso da tl2 di TrasportoLicenza, e il presupposto tl-a1 resta valido\"\n" &
    "  EVENT OUT apri_sessione()\n  GUARANTEE tl2: VERBAL \"La sessione non si chiude senza tl-a1 e tl2bis, ne' per un tipo DocumentoLicenza\"\n" &
    "                 VERIFY BY INSPECTION \"il registro della sessione, con Sessione e senza\"\nEND\n")
  writeFile(d / "Impianto.csc", "ENTITY Impianto VERSION 0.1\n  PURPOSE \"L'impianto\"\n  OFFERS Sessione\n  USES   TrasportoLicenza\nEND\n")
  var caricati: seq[(string, JsonNode)]
  for f in ["Sessione.csc", "TrasportoLicenza.csc"]: caricati.add (f, jsonDi(@["--dir", ".", f], d))
  let nomi = buildBanco("w20", caricati)["nomi"]
  proc trova(nome, blocco: string): JsonNode =
    for o in nomi:
      if o["nome"].getStr == nome and o["blocco"].getStr == blocco: return o
  let t2 = trova("tl2", "TrasportoLicenza")
  rec("AC-418", "il modello ha i nomi dichiarati con tipo, file, riga e testo: promessa tl2 col suo VERBAL e il suo VERIFY",
    t2 != nil and t2["genere"].getStr == "GUARANTEE" and t2["file"].getStr == "TrasportoLicenza.csc" and t2["riga"].getInt == 6 and
    "VERBAL \"Ogni consegna" in t2["testo"].getStr and "\nVERIFY BY INSPECTION" in t2["testo"].getStr, $t2)
  rec("AC-418", "il presupposto con il trattino (tl-a1), il tipo, l'evento, il connettore sono nomi dichiarati",
    trova("tl-a1", "TrasportoLicenza") != nil and trova("tl-a1", "TrasportoLicenza")["genere"].getStr == "ASSUME" and
    trova("DocumentoLicenza", "TrasportoLicenza")["genere"].getStr == "TYPE" and trova("consegna", "TrasportoLicenza")["genere"].getStr == "EVENT" and
    trova("Sessione", "Sessione")["genere"].getStr == "CSC", "")
  rec("AC-418", "lo stesso nome in due connettori dà due voci (tl2 in Sessione e in TrasportoLicenza); una parola non dichiarata non c'è",
    trova("tl2", "Sessione") != nil and trova("tl2bis", "Sessione") == nil and nomi.getElems.allIt(it["nome"].getStr != "senza"), "")
  rec("AC-418", "lo stesso input dà lo stesso modello dei nomi, byte per byte", $nomi == $buildBanco("w20", caricati)["nomi"], "")
  block:
    if not xvfbOk: senzaXvfb("AC-418", "sessione con Xvfb")
    else:
      var s = nuovaSessione()
      s.avviaEditor(@["--lang", "it", "--dir", d, "Impianto"], root,
        @[("BCDD_EDITOR_PROVA_CLIC", "#c-Sessione|(tl2|(tl-a1|(tl2bis|(DocumentoLicenza|(Sessione|(senza|)tl2|)tl-a1|?scheda-nome")])
      let pronto = attendi(s.trace, "pagina 1", 40)
      sleep(800)
      raccogli(s)
      let q = sondeDi(s)
      rec("AC-418", "la sessione risponde a tutte le sonde", pronto and q.len >= 9, $q.len & " " & cut(leggiSe(s.trace)))
      if q.len >= 9:
        rec("AC-418", "al passaggio su tl2 la finestrella c'è, dentro la finestra; prima la promessa della stessa CSC (Sessione), poi quella di TrasportoLicenza, ognuna col VERBAL e il VERIFY",
          "(tl2 visibile dentro=true" in q[0] and q[0].find("Promessa tl2, in Sessione") > 0 and q[0].find("Promessa tl2, in Sessione") < q[0].find("Promessa tl2, in TrasportoLicenza") and
          "ne' per un tipo" in q[0] and "VERIFY BY INSPECTION" in q[0] and "Ogni consegna completa" in q[0] and "\u00b6" in q[0], cut(q[0], 600))
        rec("AC-418", "tl-a1 (nome con trattino) è riconosciuto intero e dice presupposto, connettore e file",
          "visibile" in q[1] and "Presupposto tl-a1, in TrasportoLicenza (TrasportoLicenza.csc)" in q[1] and "Il telefono risponde" in q[1], cut(q[1]))
        rec("AC-418", "tl2bis non è un nome: nessun riferimento (la parola intera, non il prefisso tl2)", "assente" in q[2], q[2])
        rec("AC-418", "il tipo e il nome della CSC hanno la finestrella; «senza» (parola comune) no",
          "Tipo DocumentoLicenza" in q[3] and "Connettore Sessione, in Sessione" in q[4] and "assente" in q[5], cut(q[3] & " / " & q[4] & " / " & q[5]))
        rec("AC-418", "il clic su tl2 resta nella scheda di Sessione e evidenzia la sua promessa (riga 5, la più vicina)", "riga=r-5" in q[6] and "scheda=Sessione" in q[6], q[6])
        rec("AC-418", "il clic su tl-a1 porta alla scheda di TrasportoLicenza, alla riga della dichiarazione (8, la scheda la evidenzia)",
          "riga=r-8" in q[7] and "scheda=TrasportoLicenza" in q[7] and "TrasportoLicenza" in q[8], q[7] & " / " & q[8])
      s.finisci()
  let js = readFile(root / "editor" / "pagina" / "pagina.js")
  let i1 = js.find("// ---- i riferimenti interni:")
  let i2 = js.find("function creaRiga(")
  let parte = if i1 > 0 and i2 > i1: js[i1 ..< i2] else: ""
  rec("AC-418", "il codice dei riferimenti non usa innerHTML, né timer, né rete, né il menu del tasto destro", parte.len > 1000 and "innerHTML" notin parte and "setTimeout" notin parte and
    "setInterval" notin parte and "fetch" notin parte and "contextmenu" notin parte, "")
  let tj = readFile(root / "editor" / "pagina" / "testi.js")
  rec("AC-418", "i testi nuovi ci sono nelle due lingue", tj.count("\"rif_testa\"") == 2 and tj.count("\"rif_altre\"") == 2 and tj.count("\"rif_altra\"") == 2 and tj.count("\"rif_tipo_GUARANTEE\"") == 2, "")

  # ==== AC-403..AC-416, AC-419..AC-422 (e W-22): riferimenti a documenti esterni, decisioni, primo D-nnn libero ====
  # Il modello (edrif) si prova senza finestra; la finestra, il clic e il ponte sotto Xvfb. Mai i documenti vivi: copia congelata in editor/prove/w21/Progetto.
  block w21:
    proc scrivi(f, testo: string) =
      createDir(f.parentDir)
      writeFile(f, testo)
    proc cscCon(intest, corpo: string): string =
      intest & "CSC Prova VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"" & corpo & "\"\nEND\n"
    proc extFiles(dirCsc: string, files: seq[string]): JsonNode =
      var fin: seq[FileIn]
      for f in files: fin.add (f, dirCsc, jsonDi(@["--dir", ".", f], dirCsc))
      analisiRiferimenti(fin, paroleRiservate)[0]
    proc extDi(dirCsc, file: string): JsonNode = extFiles(dirCsc, @[file])[file]
    proc voce(x: JsonNode, k: string): JsonNode = (if k in x["voci"]: x["voci"][k] else: newJNull())
    proc cod(x: JsonNode, k: string): string = (let v = voce(x, k); if v.kind == JObject and not v["ok"].getBool: v["cod"].getStr else: "")
    proc nRighe(v: JsonNode): int = (if v.kind == JObject and v.hasKey("testo"): v["testo"].getStr.splitLines.len else: -1)
    proc nelle(x: JsonNode, riga: int): int = (if $riga in x["linee"]: x["linee"][$riga].len else: 0)

    # -- il documento con una riga per ogni forma (AC-404, 405, 419, 420, 421, 422)
    let docMd = [
      "# Documento", "", "## <a id=\"sez\"></a>5.2 Sezione", "testo sezione", "### Sotto", "testo sotto", "## Altra sezione", "testo altra", "",
      "| Col | Val |", "|---|---|", "| a | 1 |", "| <a id=\"rigab\"></a>b | 2 |", "| c | 3 |", "",
      "Paragrafo <a id=\"par\"></a>con ancora", "seconda riga", "",
      "**B1id** paragrafo dopo riga vuota", "- **B2a** elemento con trattino", "  continua b2a", "* **B2b** con asterisco", "3. **B2c** numerato",
      "    - **B2d** annidato di quattro spazi", "", "| **B3id** | seconda |", "", "## **B4id** titolo con id", "sotto b4", "",
      "testo **Y** a metà riga", "**Y2** è la seconda riga di un paragrafo", "", "| a | **Y3** |", "", "```", "**Y4** dentro il codice", "```", "",
      "`**Y5**` in codice in linea", "", "**caso Y6** con spazi", "", "***Y7*** triplo", "", "- **Q-1** domanda", "- **Q-1** risposta", "",
      "<a id=\"Z\"></a>paragrafo con l'ancora Z", "", "**Z** blocco con lo stesso id", "", "**W** maiuscolo", "", "**w** minuscolo", "",
      "<a id=\"Dup\"></a>uno", "", "<a id=\"dup\"></a>due", "", "<a id=\"vuota\"></a>", "", "## Fine"]
    proc riga1(marc: string): int = docMd.find(docMd.filterIt(marc in it)[0]) + 1
    let dA = newWd0()
    scrivi(dA / "docs" / "doc.md", docMd.join("\n") & "\n")
    scrivi(dA / "docs" / "doc2.md", "- **Q-1** domanda\n- <a id=\"Q-1\"></a>**Q-1** risposta\n")
    scrivi(dA / "docs" / "html.md", "<a id=\"html\"></a>testo <b>x</b> e <script>alert(1)</script> fine\n")
    var lungo: seq[string]
    for i in 1 .. 60: lungo.add "riga " & $i
    lungo[0] = "<a id=\"lungo\"></a>riga 1"
    scrivi(dA / "docs" / "lungo.md", lungo.join("\n") & "\n")
    var defs = ""
    for (e, d) in [("Sez", "sez"), ("RigaB", "rigab"), ("Par", "par"), ("B1", "B1id"), ("B2a", "B2a"), ("B2b", "B2b"), ("B2c", "B2c"), ("B2d", "B2d"), ("B3", "B3id"),
        ("B4", "B4id"), ("YY", "Y"), ("Y2", "Y2"), ("Y3", "Y3"), ("Y4", "Y4"), ("Y5", "Y5"), ("Y6", "Y6"), ("Y7", "Y7"), ("QQ", "Q-1"), ("ZZ", "Z"), ("WW", "W"), ("Ww", "w"),
        ("Dup", "Dup"), ("Vuota", "vuota"), ("NoId", "nonce")]:
      defs.add "-- [" & e & "]: ../docs/doc.md#" & d & "\n"
    defs.add "-- [Q2]: ../docs/doc2.md#Q-1\n-- [Html]: ../docs/html.md#html\n-- [Lungo]: ../docs/lungo.md#lungo\n-- [File]: ../docs/doc.md\n"
    var usi: seq[string]
    for e in ["Sez", "RigaB", "Par", "B1", "B2a", "B2b", "B2c", "B2d", "B3", "B4", "YY", "Y2", "Y3", "Y4", "Y5", "Y6", "Y7", "QQ", "ZZ", "WW", "Ww", "Dup", "Vuota", "NoId", "Q2", "Html", "Lungo", "File"]:
      usi.add "[" & e & "]"
    scrivi(dA / "csc" / "Prova.csc", cscCon(defs, usi.join(" ")))
    let xa = extDi(dA / "csc", "Prova.csc")
    rec("AC-404", "ancora su un titolo `##` con un `###` dentro: dal titolo alla riga prima del `##` successivo (T1)",
      nRighe(voce(xa, "e:Sez")) == 4 and voce(xa, "e:Sez")["testo"].getStr.contains("testo sotto") and not voce(xa, "e:Sez")["testo"].getStr.contains("testo altra") and
      voce(xa, "e:Sez")["riga"].getInt == riga1("5.2 Sezione"), $voce(xa, "e:Sez"))
    rec("AC-405", "ancora su una riga di tabella: l'intestazione e quella riga, senza `|---|` (T2)",
      voce(xa, "e:RigaB")["testo"].getStr == "| Col | Val |\n| b | 2 |", $voce(xa, "e:RigaB"))
    rec("AC-419", "B1: il paragrafo dopo la riga vuota è un blocco `**ID**`; il blocco è il paragrafo con l'elenco attaccato (T4)",
      voce(xa, "e:B1")["riga"].getInt == riga1("**B1id**") and nRighe(voce(xa, "e:B1")) == 6 and "B2d" in voce(xa, "e:B1")["testo"].getStr, $voce(xa, "e:B1"))
    rec("AC-419", "B2: elemento di elenco con `- `, `* `, `3. ` e rientro di 4 spazi; l'elemento con la sua continuazione e i figli (T3)",
      voce(xa, "e:B2a")["riga"].getInt == riga1("**B2a**") and nRighe(voce(xa, "e:B2a")) == 2 and nRighe(voce(xa, "e:B2b")) == 1 and
      nRighe(voce(xa, "e:B2c")) == 2 and nRighe(voce(xa, "e:B2d")) == 1 and voce(xa, "e:B2d")["riga"].getInt == riga1("**B2d**"),
      $voce(xa, "e:B2a") & $voce(xa, "e:B2b") & $voce(xa, "e:B2c") & $voce(xa, "e:B2d"))
    rec("AC-419", "B3: prima cella di una tabella (la tabella intera, T2); B4: titolo `## **X** …` (T1 fino alla riga prima di `## Fine`)",
      voce(xa, "e:B3")["riga"].getInt == riga1("**B3id**") and nRighe(voce(xa, "e:B3")) == 1 and voce(xa, "e:B4")["riga"].getInt == riga1("## **B4id**") and
      voce(xa, "e:B4")["testo"].getStr.startsWith("## **B4id**") and not voce(xa, "e:B4")["testo"].getStr.contains("Fine"), $voce(xa, "e:B3") & $voce(xa, "e:B4"))
    var tutteRF2 = true
    for e in ["YY", "Y2", "Y3", "Y4", "Y5", "Y6", "Y7"]: tutteRF2 = tutteRF2 and cod(xa, "e:" & e) == "RF-2"
    rec("AC-420", "le non-forme di B5 (a metà riga, seconda riga di paragrafo, seconda cella, codice delimitato, codice in linea, grassetto con spazi, triplo): RF-2",
      tutteRF2, $(["YY", "Y2", "Y3", "Y4", "Y5", "Y6", "Y7"].mapIt(cod(xa, "e:" & it))))
    rec("AC-420", "il motivo di RF-2 dice «né un blocco che comincia con **Y**»", voce(xa, "e:YY")["cod"].getStr == "RF-2" and voce(xa, "e:YY")["a"].getStr == "Y", $voce(xa, "e:YY"))
    rec("AC-421", "due elementi `- **Q-1** …` nello stesso file: RF-10 con le due righe", cod(xa, "e:QQ") == "RF-10" and voce(xa, "e:QQ")["b"].getStr == $riga1("**Q-1** domanda") & ", " & $(riga1("**Q-1** domanda") + 1), $voce(xa, "e:QQ"))
    rec("AC-421", "con `<a id=\"Q-1\"></a>` sul secondo l'ancora vince (X1): risolto sulla riga della risposta",
      voce(xa, "e:Q2")["ok"].getBool and voce(xa, "e:Q2")["riga"].getInt == 2 and "risposta" in voce(xa, "e:Q2")["testo"].getStr, $voce(xa, "e:Q2"))
    rec("AC-422", "`<a id=\"Z\"></a>` su un paragrafo e un blocco `**Z**` altrove: vale l'ancora (X1)",
      voce(xa, "e:ZZ")["riga"].getInt == riga1("<a id=\"Z\"></a>") and "l'ancora Z" in voce(xa, "e:ZZ")["testo"].getStr, $voce(xa, "e:ZZ"))
    rec("AC-422", "`**W**` e `**w**`: ognuno sul proprio blocco, nessun RF-10 (confronto esatto)",
      voce(xa, "e:WW")["riga"].getInt == riga1("**W** maiuscolo") and voce(xa, "e:Ww")["riga"].getInt == riga1("**w** minuscolo"), $voce(xa, "e:WW") & $voce(xa, "e:Ww"))
    rec("AC-406", "RF-5 per due ancore che differiscono solo per le maiuscole (con le due righe); RF-9 per l'ancora con il blocco vuoto; RF-2 per un id che non c'è",
      cod(xa, "e:Dup") == "RF-5" and voce(xa, "e:Dup")["b"].getStr == $riga1("id=\"Dup\"") & ", " & $riga1("id=\"dup\"") and cod(xa, "e:Vuota") == "RF-9" and cod(xa, "e:NoId") == "RF-2", $voce(xa, "e:Dup") & $voce(xa, "e:Vuota"))
    rec("AC-406", "destinazione `percorso.md` senza `#`: l'intestazione e il primo titolo del file (D5 b)", voce(xa, "e:File")["ok"].getBool and voce(xa, "e:File")["testo"].getStr == "# Documento" and voce(xa, "e:File")["riga"].getInt == 1, $voce(xa, "e:File"))
    let marcaAnc = voce(xa, "e:Html")
    rec("AC-410", "il blocco con `<b>x</b>` e `<script>` è testo nel modello (resa e pagina verificate sotto)", marcaAnc["ok"].getBool and "<b>x</b>" in marcaAnc["testo"].getStr and "<script>alert(1)</script>" in marcaAnc["testo"].getStr, $marcaAnc)
    let vl = voce(xa, "e:Lungo")
    rec("AC-411", "un blocco di 60 righe: 40 righe e «continua in FILE, riga N» con N = 41 (T5)", nRighe(vl) == 40 and vl["oltre"].getInt == 41 and vl["nomefile"].getStr == "lungo.md", $nRighe(vl) & " " & $vl["oltre"])
    # T5 sui caratteri: righe lunghe, meno di 40 righe ma più di 4000 caratteri
    scrivi(dA / "docs" / "larga.md", "<a id=\"larga\"></a>" & "x".repeat(1500) & "\n" & "y".repeat(1500) & "\n" & "z".repeat(1500) & "\n")
    scrivi(dA / "csc" / "Larga.csc", cscCon("-- [Larga]: ../docs/larga.md#larga\n", "[Larga]"))
    let vg = voce(extDi(dA / "csc", "Larga.csc"), "e:Larga")
    rec("AC-411", "oltre 4000 caratteri il testo si ferma all'ultima riga intera (2 righe) e dice da dove continua", vg["testo"].getStr.len == 3001 and vg["oltre"].getInt == 3, $vg["testo"].getStr.len & " " & $vg["oltre"])

    # -- i codici RF-1 … RF-9 e le forme non valide (AC-406), il testo che non è un riferimento (AC-407), definizioni (AC-408, AC-409)
    scrivi(dA / "docs" / "grande.md", "<a id=\"g\"></a>x\n" & "a".repeat(4 * 1024 * 1024))
    scrivi(dA / "docs" / "nonutf.md", "<a id=\"u\"></a>\xff\xfe non utf8\n")
    var d6 = ""
    for (e, d) in [("Manca", "../docs/manca.md#x"), ("Dop", "../docs/doc.md#sez"), ("Dop", "../docs/doc.md#par"), ("Abs", "/etc/x.md#a"), ("Bar", "..\\docs\\doc.md#a"),
        ("NonMd", "../docs/doc.txt#a"), ("Sch", "ftp:x.md#a"), ("Idx", "../docs/doc.md#a b"), ("Maiu", "../Docs/doc.md#sez"), ("Gr", "../docs/grande.md#g"), ("Ut", "../docs/nonutf.md#u")]:
      d6.add "-- [" & e & "]: " & d & "\n"
    scrivi(dA / "csc" / "Rotti.csc", cscCon(d6, "[Manca] [Indef] [Dop] [Abs] [Bar] [NonMd] [Sch] [Idx] [Maiu] [Gr] [Ut] e D-77"))
    let xr = extDi(dA / "csc", "Rotti.csc")
    rec("AC-406", "RF-1: il file non esiste", cod(xr, "e:Manca") == "RF-1" and voce(xr, "e:Manca")["a"].getStr == "../docs/manca.md", $voce(xr, "e:Manca"))
    rec("AC-406", "RF-3: etichetta senza definizione; RF-4: due definizioni diverse, con le due righe",
      cod(xr, "e:Indef") == "RF-3" and cod(xr, "e:Dop") == "RF-4" and voce(xr, "e:Dop")["a"].getStr == "2" and voce(xr, "e:Dop")["b"].getStr == "3", $voce(xr, "e:Indef") & $voce(xr, "e:Dop"))
    rec("AC-406", "RF-6: percorso assoluto, `\\`, non `.md`, schema, id non valido, maiuscole diverse dal disco, file oltre 4 MB, file non UTF-8",
      [cod(xr, "e:Abs"), cod(xr, "e:Bar"), cod(xr, "e:NonMd"), cod(xr, "e:Sch"), cod(xr, "e:Idx"), cod(xr, "e:Maiu"), cod(xr, "e:Gr"), cod(xr, "e:Ut")].allIt(it == "RF-6") and
      @[voce(xr, "e:Abs")["a"].getStr, voce(xr, "e:Bar")["a"].getStr, voce(xr, "e:NonMd")["a"].getStr, voce(xr, "e:Sch")["a"].getStr, voce(xr, "e:Idx")["a"].getStr, voce(xr, "e:Maiu")["a"].getStr,
        voce(xr, "e:Gr")["a"].getStr, voce(xr, "e:Ut")["a"].getStr] == @["assoluto", "barra", "non_md", "schema", "id", "maiuscole", "grande", "utf8"] and voce(xr, "e:Maiu")["b"].getStr == "docs", $xr["voci"])
    rec("AC-406", "RF-8: nessun registro delle decisioni (un solo avviso per file nel contatore); i link rotti contati e in ordine di riga",
      cod(xr, "d:77") == "RF-8" and xr["rotti"].len == 11 + 1 and xr["rotti"].getElems.mapIt(it.getInt) == xr["rotti"].getElems.mapIt(it.getInt).sorted, $xr["rotti"])
    let dReg = newWd0()
    scrivi(dReg / "WORK_REGISTER.md", "| ID | tipo |\n|---|---|\n| D-5 | decisione | cinque |\n| D-419 | decisione | quattrocento |\n| D-419 | decisione | ripetuta |\n")
    scrivi(dReg / "csc" / "Prova.csc", cscCon("", "come D-5 e D-9999 e D-419"))
    let xd = extDi(dReg / "csc", "Prova.csc")
    rec("AC-406", "RF-7: la decisione non è nel registro, con il percorso del registro; le altre sono risolte; D-419 compare due volte (avviso, non errore)",
      cod(xd, "d:9999") == "RF-7" and voce(xd, "d:9999")["a"].getStr == "../WORK_REGISTER.md" and voce(xd, "d:5")["ok"].getBool and voce(xd, "d:419")["volte"].getInt == 2 and
      voce(xd, "d:419")["testo"].getStr.contains("quattrocento"), $xd["voci"])
    var tuttiTesti = true
    block:
      let tj = readFile(root / "editor" / "pagina" / "testi.js")
      for k in ["rf1", "rf2", "rf3", "rf4", "rf5", "rf6", "rf7", "rf8", "rf9", "rf10", "rf6_assoluto", "rf6_barra", "rf6_non_md", "rf6_schema", "rf6_id", "rf6_percorso", "rf6_maiuscole", "rf6_grande", "rf6_utf8",
          "rife_testa", "rife_continua", "rife_apri_file", "rife_apri_browser", "rotti_n", "ap_libero", "ap_gia_nel_registro"]:
        if tj.count("\"" & k & "\":") != 2: tuttiTesti = false
    rec("AC-406", "RF-1 … RF-10 e i testi della finestrella: ogni chiave nelle due lingue", tuttiTesti, "")
    scrivi(dA / "csc" / "Testo.csc", cscCon("-- [C8-OP-4]: ../docs/doc.md#sez\n", "[A] e [0 .. 100] e [DA VERIFICARE: x] e [ C5 I11 ] e [[x]] e `[C8-OP-4]` e `[Sez]` e [x]"))
    let xt = extDi(dA / "csc", "Testo.csc")
    rec("AC-407", "`[A]`, `[0 .. 100]`, `[DA VERIFICARE: x]`, `[ C5 I11 ]`, `[[x]]` e le quadre fra apici non sono riferimenti né errori; `[x]` (un carattere) neppure",
      xt["linee"].len == 0 and xt["voci"].len == 0 and xt["rotti"].len == 0, $xt["linee"])
    scrivi(dA / "csc" / "Coda.csc", "CSC Coda VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"usa [Yy] qui\"\n  EVENT IN y() -- [Yy]: ../docs/doc.md#sez\nEND\n")
    let xc = extDi(dA / "csc", "Coda.csc")
    rec("AC-408", "una definizione in coda a una dichiarazione non vale (D1): `[Yy]` è RF-3", cod(xc, "e:Yy") == "RF-3", $xc["voci"])
    scrivi(dA / "csc" / "Uno.csc", cscCon("-- [Solo]: ../docs/doc.md#sez\n", "[Solo]"))
    scrivi(dA / "csc" / "Due.csc", "CSC Due VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"usa [Solo]\"\nEND\n")
    let xm = extFiles(dA / "csc", @["Uno.csc", "Due.csc"])
    scrivi(dA / "csc" / "Inl.csc", cscCon("", "vedi [testo](../docs/doc.md#sez) e [altro](nonesiste.md) e [vuoto](a b.md) e [nulla]()"))
    let xi = extDi(dA / "csc", "Inl.csc")
    rec("AC-407", "riferimento in linea `[testo](destinazione)` (§4.4): risolto sulla destinazione; rotto se non si risolve; senza chiusura, con spazi o vuoto non è un riferimento",
      voce(xi, "i:testo=../docs/doc.md#sez")["ok"].getBool and voce(xi, "i:testo=../docs/doc.md#sez")["riga"].getInt == 3 and cod(xi, "i:altro=nonesiste.md") == "RF-1" and xi["voci"].len == 2, $xi["voci"])
    rec("AC-409", "definizione solo nel primo file, uso nel secondo: RF-3 nel secondo, risolto nel primo (D3)", voce(xm["Uno.csc"], "e:Solo")["ok"].getBool and cod(xm["Due.csc"], "e:Solo") == "RF-3", "")

    # -- decisioni e registro (AC-412, AC-413), D-nnn libero (AC-415)
    let dS = newWd0()
    let radice = dS / "ProgettoBase"
    scrivi(radice / "WORK_REGISTER.md", "| ID | tipo |\n|---|---|\n| D-378 | decisione | ratificata |\n| D-413 | decisione | ratifica TrasportoLicenza |\n")
    scrivi(radice / "sub" / "WORK_REGISTER.md", "# registro locale senza decisioni\n")
    scrivi(radice / "sub" / "csc" / "D.csc", "-- Con D-413 e ProgettoBase D-378 e ServizioAlfa D-02 e RATIFIED BY D-378 (nel commento)\nCSC D VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"vedi ProgettoBase D-378, D-413 e TerzoBeta D-5\"\nEND\n")
    let xs = extDi(radice / "sub" / "csc", "D.csc")
    rec("AC-412", "il registro intermedio senza decisioni si salta (G2): D-413 e D-378 sono risolti sul registro della radice, indicato con il percorso relativo",
      voce(xs, "d:413")["ok"].getBool and voce(xs, "d:378")["ok"].getBool and voce(xs, "d:413")["reg"].getStr == "../../WORK_REGISTER.md" and xs["reg"].getStr == "../../WORK_REGISTER.md", $xs["voci"])
    rec("AC-412", "`Con D-413` (una sola maiuscola) è un riferimento; `ProgettoBase D-378` (nome del registro) lo è; `ServizioAlfa D-02` e `TerzoBeta D-5` (altro registro) sono testo, senza errore",
      nelle(xs, 1) >= 3 and "d:2" notin xs["voci"] and "d:5" notin xs["voci"] and xs["rotti"].len == 0, $xs["linee"])
    var n378 = 0
    for x in xs["linee"]["1"]:
      if x[2].getStr == "d:378": inc n378
    rec("AC-412", "`RATIFIED BY D-378` in un commento: la parola BY non è un qualificatore (K2, scelta sulle parole del linguaggio)", n378 == 2, $xs["linee"]["1"])
    let fz = root / "editor" / "prove" / "w21" / "Progetto" / "subprojects" / "GruppoLicenze" / "csc"
    let xf = extDi(fz, "TrasportoLicenza.csc")
    rec("AC-403", "copia congelata di TrasportoLicenza.csc e dei due contract non modificati: i sei riferimenti mostrano i blocchi di §8 (11, 1, 10, 6, ·, 7 righe; RC-LI-8 è 10 righe ma 4208 caratteri: T5 ne mostra 9)",
      [nRighe(voce(xf, "e:C8-OP-4")), nRighe(voce(xf, "e:C8-RC-3")), nRighe(voce(xf, "e:RC-LI-6")), nRighe(voce(xf, "e:RC-LI-7")), nRighe(voce(xf, "e:RC-LI-9"))] == @[11, 1, 10, 6, 7] and
      nRighe(voce(xf, "e:RC-LI-8")) == 9 and voce(xf, "e:RC-LI-8")["oltre"].getInt == 36, $xf["voci"].getFields.keys.toSeq)
    rec("AC-403", "`[RC-LI-9]` mostra le righe 40-46 (riga di partenza 40, punti 1-6) e `[C8-OP-4]` parte dalla riga 11", voce(xf, "e:RC-LI-9")["riga"].getInt == 40 and voce(xf, "e:RC-LI-9")["testo"].getStr.contains("6. esito della libreria") and
      voce(xf, "e:C8-OP-4")["riga"].getInt == 11 and voce(xf, "e:RC-LI-9")["dest"].getStr.endsWith("PROTOCOL_CONTRACT_1.2.md#RC-LI-9"), $voce(xf, "e:RC-LI-9"))
    rec("AC-412", "`STATUS RATIFIED BY D-413` nella copia congelata mostra la riga D-413 del registro del progetto, saltando quello del gruppo",
      voce(xf, "d:413")["ok"].getBool and "TrasportoLicenza 0.2" in voce(xf, "d:413")["testo"].getStr and xf["reg"].getStr == "../../../WORK_REGISTER.md", $voce(xf, "d:413"))
    let dG = newWd0()
    scrivi(dG / "csc" / "G.csc", "-- [Registro delle decisioni]: altro/REG.md\nCSC G VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"vedi D-7\"\nEND\n")
    scrivi(dG / "csc" / "altro" / "REG.md", "| D-7 | decisione | nel registro scelto |\n")
    scrivi(dG / "WORK_REGISTER.md", "| D-7 | decisione | nel registro sbagliato |\n")
    let xg = extDi(dG / "csc", "G.csc")
    rec("AC-413", "`[Registro delle decisioni]: altro/REG.md` fissa il registro (G1): D-7 si risolve lì e non nel WORK_REGISTER.md salendo",
      voce(xg, "d:7")["ok"].getBool and "scelto" in voce(xg, "d:7")["testo"].getStr and xg["reg"].getStr == "altro/REG.md", $xg["voci"])
    scrivi(dA / "csc" / "Url.csc", cscCon("-- [Sito]: https://example.org/x\n", "vedi [Sito]"))
    let xu = extDi(dA / "csc", "Url.csc")
    rec("AC-414", "una destinazione `https://example.org/x`: la voce è un URL, non letta, apribile dal solo clic; nessun codice di rete in edrif",
      voce(xu, "e:Sito")["t"].getStr == "url" and apribili.getOrDefault("Url.csc\0e:Sito") == "https://example.org/x" and
      not readFile(root / "editor" / "edrif.nim").contains("httpclient") and not readFile(root / "editor" / "edrif.nim").contains("nativesockets") and
      not readFile(root / "editor" / "edrif.nim").contains("std/net"), $xu["voci"])
    # P2 (AC-415): il primo libero è 1 + il massimo fra le righe del registro e i RATIFIED BY dei file che usano quel registro
    let dP = newWd0()
    scrivi(dP / "WORK_REGISTER.md", "| D-419 | decisione | ultima |\n| D-3 | decisione | tre |\n")
    scrivi(dP / "csc" / "A.csc", cscCon("", "uno"))
    scrivi(dP / "csc" / "B.csc", "CSC B VERSION 0.1\n  STATUS RATIFIED BY D-425\n  PURPOSE \"due\"\nEND\n")
    let xp = extFiles(dP / "csc", @["A.csc", "B.csc"])
    rec("AC-415", "registro con massimo D-419 e una CSC con `RATIFIED BY D-425`: primo libero D-426, per tutti i file di quel registro", xp["A.csc"]["libero"].getInt == 426 and xp["B.csc"]["libero"].getInt == 426, $xp["A.csc"]["libero"])
    let dQ = newWd0()
    scrivi(dQ / "csc" / "A.csc", cscCon("", "senza registro né numeri"))
    rec("AC-415", "senza alcun numero: D-1", extDi(dQ / "csc", "A.csc")["libero"].getInt == 1, "")
    # E4 (AC-416): un file `.md` si legge una volta per caricamento; Ricarica (azzeraRif) lo rilegge
    let dE = newWd0()
    scrivi(dE / "docs" / "m.md", "<a id=\"m\"></a>testo vecchio\n")
    scrivi(dE / "csc" / "E.csc", cscCon("-- [Mm]: ../docs/m.md#m\n", "[Mm]"))
    azzeraRif()
    let e1 = voce(extDi(dE / "csc", "E.csc"), "e:Mm")["testo"].getStr
    scrivi(dE / "docs" / "m.md", "<a id=\"m\"></a>testo nuovo\n")
    let e2 = voce(extDi(dE / "csc", "E.csc"), "e:Mm")["testo"].getStr
    azzeraRif()
    let e3 = voce(extDi(dE / "csc", "E.csc"), "e:Mm")["testo"].getStr
    rec("AC-416", "dopo la modifica del `.md`, senza Ricarica il testo è quello vecchio; dopo Ricarica (azzeraRif) è quello nuovo", e1 == "testo vecchio" and e2 == "testo vecchio" and e3 == "testo nuovo", e1 & "/" & e2 & "/" & e3)
    let fin = readFile(root / "editor" / "edfinestra.nim")
    let iR = fin.find("if az == \"ricarica\":")
    rec("AC-416", "il comando Ricarica azzera la memoria dei `.md` e del registro; lo stesso fa il cambio di cartelle; nessun timer né osservatore", iR > 0 and "azzeraRif()" in fin[iR ..< iR + 400] and
      "azzeraRif()" in fin[fin.find("proc gestisciCartelle") ..< fin.find("proc gestisciCartelle") + 900] and not readFile(root / "editor" / "edrif.nim").contains("timeout") and
      not readFile(root / "editor" / "edrif.nim").contains("monitor"), "")
    # E6: il controllo dei link non blocca niente: i contatori non entrano in nessuna condizione di blocco della pagina
    let js6 = readFile(root / "editor" / "pagina" / "pagina.js")
    var rottiBlocca = false
    for r in js6.splitLines:
      if ("fx.rotti" in r or ".rotti" in r) and "disabled" in r: rottiBlocca = true
    rec("AC-406", "i link rotti non bloccano salvataggio, Completa, Approva né bcdd: `rotti` serve solo al contatore e nessun `disabled` ne dipende (E6)",
      js6.count("rotti") >= 3 and not rottiBlocca, "")
    let jsr = readFile(root / "editor" / "pagina" / "pagina.js")
    let r1 = jsr.find("// ---- i riferimenti a documenti esterni:")
    let r2 = jsr.find("function creaRiga(")
    let parteR = if r1 > 0 and r2 > r1: jsr[r1 ..< r2] else: ""
    rec("AC-410", "il codice dei riferimenti esterni non usa innerHTML, né timer, né rete, né il menu del tasto destro; il testo mostrato entra con textContent o nodi di testo",
      parteR.len > 1500 and "innerHTML" notin parteR and "setTimeout" notin parteR and "setInterval" notin parteR and "fetch" notin parteR and "contextmenu" notin parteR and "XMLHttpRequest" notin parteR, $parteR.len)

    # -- la finestra: il passaggio del mouse, il clic con la finestrella fissa, il pulsante, il contatore e il modulo Approva (sotto Xvfb)
    scrivi(dA / "csc" / "Fin.csc", "-- [Sez]: ../docs/doc.md#sez\n-- [Html]: ../docs/html.md#html\n-- [Sito]: https://example.org/x\n-- [NoId]: ../docs/doc.md#nonce\n" &
      "CSC Fin VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"Vedi [Sez] e [Html] e [Sito] e [NoId] e [Manca]\"\nEND\n")
    scrivi(dA / "csc" / "Radice.csc", "ENTITY Radice VERSION 0.1\n  PURPOSE \"La radice\"\n  OFFERS Fin\nEND\n")
    block:
      if not xvfbOk: senzaXvfb("AC-403", "sessione con Xvfb")
      else:
        var s = nuovaSessione()
        s.avviaEditor(@["--lang", "it", "--dir", dA / "csc", "Radice"], root,
          @[("BCDD_EDITOR_PROVA_CLIC", "#c-Fin|(e:Sez|(e:Html|(e:Sito|(e:NoId|(e:Manca|)e:Sito|>rife-apri|?scheda-rotti|)e:Sez|?rif-tip")])
        let pronto = attendi(s.trace, "pagina 1", 40)
        sleep(900)
        raccogli(s)
        let q = sondeDi(s)
        rec("AC-403", "la sessione risponde a tutte le sonde", pronto and q.len >= 9, $q.len & " " & cut($q, 1500))
        if q.len >= 9:
          rec("AC-403", "al passaggio del mouse la finestrella mostra l'intestazione (etichetta, percorso, #ID, riga) e il blocco dell'ancora, dentro la finestra",
            "(e:Sez visibile dentro=true" in q[0] and "Sez · ../docs/doc.md#sez · riga 3" in q[0] and "testo sotto" in q[0] and "testo altra" notin q[0], cut(q[0], 500))
          rec("AC-410", "il blocco con `<b>x</b>` e `<script>` si mostra come testo: nessun elemento creato nella pagina",
            "<b>x</b>" in q[1] and "<script>alert(1)</script>" in q[1] and "[elementi=0]" in q[1], cut(q[1], 500))
          rec("AC-414", "l'URL: la finestrella mostra l'indirizzo, senza leggerlo", "https://example.org/x" in q[2] and "visibile" in q[2], cut(q[2]))
          rec("AC-406", "un riferimento rotto ha il motivo con il suo codice nella finestrella (RF-2 e RF-3)",
            "Riferimento non risolto (RF-2)" in q[3] and "né un blocco che comincia con **nonce**" in q[3] and "Riferimento non risolto (RF-3)" in q[4] and "l'etichetta [Manca] non ha una definizione" in q[4], cut(q[3] & " / " & q[4], 600))
          rec("AC-414", "il clic su un URL lascia la finestrella fissa con «Apri nel browser»; il pulsante manda `apri_rif` e la versione di prova non lancia niente",
            "fissa=true" in q[5] and "pulsante=Apri nel browser" in q[5] and "apri_rif https://example.org/x" in leggiSe(s.trace), q[5] & " " & cut(leggiSe(s.trace), 300))
          rec("AC-406", "il contatore «riferimenti non risolti: N» conta i due riferimenti non risolti del file (RF-2 e RF-3)", "visibile riferimenti non risolti: 2" in q[6], q[6])
          rec("AC-403", "il clic su un riferimento a un file lascia la finestrella fissa con «Apri il file»", "fissa=true" in q[7] and "pulsante=Apri il file" in q[7], q[7])
        s.finisci()
        # la copia congelata del gruppo di licenze nella finestra: le righe che l'operatore proverà
        var s2 = nuovaSessione()
        s2.avviaEditor(@["--lang", "it", "--dir", fz, "Impianto"], root,
          @[("BCDD_EDITOR_PROVA_CLIC", "#c-TrasportoLicenza|(e:RC-LI-9|(d:413|(e:C8-OP-4|)e:RC-LI-9|>rife-apri")])
        let pronto2 = attendi(s2.trace, "pagina 1", 40)
        sleep(900)
        raccogli(s2)
        let q2 = sondeDi(s2)
        rec("AC-403", "la copia congelata del gruppo di licenze nella finestra: la sessione risponde", pronto2 and q2.len >= 4, $q2.len & " " & cut(leggiSe(s2.trace)))
        if q2.len >= 4:
          rec("AC-403", "passaggio su `[RC-LI-9]` (nel commento iniziale della scheda): intestazione con riga 40 e punti 1-6; su `[C8-OP-4]` la riga 11",
            "riga 40" in q2[0] and "6. esito della libreria" in q2[0] and "riga 11C8-OP-4" in q2[2], cut(q2[0], 400))
          rec("AC-412", "passaggio su D-413 (STATUS RATIFIED BY D-413): la riga del registro del progetto, con il percorso del registro", "D-413 · registro delle decisioni: ../../../WORK_REGISTER.md" in q2[1] and "TrasportoLicenza 0.2" in q2[1], cut(q2[1], 400))
          rec("AC-403", "«Apri il file» manda `apri_rif` col percorso del documento letto (mai uno scelto dalla pagina)",
            leggiSe(s2.trace).contains("apri_rif " & fz.parentDir.parentDir.parentDir / "docs" / "contracts" / "protocollo" / "PROTOCOL_CONTRACT_1.2.md"), cut(leggiSe(s2.trace), 400))
        s2.finisci()
        # W-22: il primo D-nnn libero accanto al campo, non scritto nel campo, e la riga del registro se il numero c'è già
        let dW = newWd0()
        scrivi(dW / "WORK_REGISTER.md", "| D-419 | decisione | quattrocentodiciannove |\n")
        scrivi(dW / "Luce.csc", "CSC Luce VERSION 0.1\n  STATUS HYPOTHESIS\n  PURPOSE \"La luce\"\n  EVENT IN accendi()\n  GUARANTEE g1: VERBAL \"La luce si accende\"\n                VERIFY BY INSPECTION \"il registro\"\nEND\n")
        scrivi(dW / "Altra.csc", "CSC Altra VERSION 0.1\n  STATUS RATIFIED BY D-425\n  PURPOSE \"altro\"\nEND\n")
        scrivi(dW / "Lampada.csc", "ENTITY Lampada VERSION 0.1\n  PURPOSE \"La lampada\"\n  OFFERS Luce\nEND\n")
        var s3 = nuovaSessione()
        s3.avviaEditor(@["--lang", "it", "--dir", dW, "Lampada"], root,
          @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|@b-approva-intero|?a-num-libero|!a-num|=a-num:D-419|?a-num-reg|=a-num:D-500|?a-num-reg|!a-ok")])
        let pronto3 = attendi(s3.trace, "pagina 1", 40)
        sleep(900)
        raccogli(s3)
        let q3 = sondeDi(s3)
        rec("AC-415", "il modulo Approva risponde a tutte le sonde", pronto3 and q3.len >= 5, $q3.len & " " & cut(leggiSe(s3.trace)))
        if q3.len >= 5:
          rec("AC-415", "il modulo mostra «Primo numero libero: D-426» accanto al campo e il campo resta vuoto (P3, D-185)", "Primo numero libero: D-426" in q3[0] and "Non è prenotato" in q3[0] and "valore=" in q3[1] and "valore=D" notin q3[1], q3[0] & " / " & q3[1])
          rec("AC-415", "un numero già nel registro (D-419): se ne mostra la riga, come informazione; un numero che non c'è: niente; Approva non è bloccato",
            "D-419 è già nel registro" in q3[2] and "quattrocentodiciannove" in q3[2] and "già nel registro" notin q3[3] and "a-ok" in q3[4], q3[2] & " / " & q3[3] & " / " & q3[4])
        s3.finisci()

# 080:9:1 AC-443..AC-451: «Rinomina…» in bcdd-editor, sulla cartella sintetica di prove/rinomina (copia, mai i file vivi).
# Il motore è `bcdd rename` (provato da tests/trinomina.nim); qui si prova la finestra: il modulo, l'anteprima, la conferma, i casi di rifiuto, il giornale.
block:
  let sint = root / "prove" / "rinomina" / "sintetica"
  let fintoLlm9 = root / "prove" / "f2" / "ULlmFinto.sh"
  let rf9 = root / "prove" / "f2" / "refine"
  proc copiaSint(): string =
    result = newWd0()
    copyDir(sint, result)
  proc tuttoSint(d: string): Table[string, string] =
    for sub in ["luce", "comuni"]:
      for f in walkDirRec(d / sub, yieldFilter = {pcFile}, relative = true): result[sub / f] = readFile(d / sub / f)
  proc nomiSint(d: string): seq[string] =
    for k in tuttoSint(d).keys: result.add k
    result.sort()
  proc anteprimaRef(d: string, args: seq[string]): JsonNode =
    ## L'anteprima di `bcdd rename` lanciata direttamente, con le stesse cartelle dell'editor (`luce` poi `comuni`)
    let r = runExe(bcddProva, @["rename", "Luce.csc", "--dir", ".", "--dir", d / "comuni", "--dry-run", "--json"] & args, d / "luce", envPulito())
    try: result = parseJson(r.output)
    except CatchableError: result = nil
  proc lanciRen(s: Sess): seq[string] = righe(s.lanci).filterIt(it.startsWith("rename "))
  proc argsEditor(d: string, nome: string): seq[string] = @["--lang", "it", "--dir", d / "luce", "--dir", d / "comuni", nome]
  if not xvfbOk: senzaXvfb("AC-443", "sessione con Xvfb")
  else:
    # ---- AC-443, AC-444, AC-445: la scheda di Luce, il modulo, l'anteprima, la conferma con un testo tolto
    block:
      let d = copiaSint()
      let ref0 = anteprimaRef(d, @["csc", "Luce", "Lampadina"])
      var nr0, nf0 = 0
      if ref0 != nil and ref0.kind == JObject and ref0.hasKey("file"):
        for f in ref0["file"]:
          nr0 += f["modifiche"].len
          if f["modifiche"].len > 0 or f["nome_nuovo"].kind == JString: inc nf0
      let sintesi = "Cambiano " & $nr0 & " righe in " & $nf0 & " file."
      var s = nuovaSessione()
      let clic = "@b-nuova|=f-nome:Zeta|=f-scopo:una prova|@f-ok|!b-annulla|#alb:LuceScale|#c-Luce|?scheda-nome|@b-rinomina|?f-rin-nome|!f-rin-nome|!rin-mostra|" &
        "=f-rin-nome:END|?e-f-rin-nome|!rin-mostra|=f-rin-nome:Luce-2|?e-f-rin-nome|!rin-mostra|=f-rin-nome:Luce|?e-f-rin-nome|!rin-mostra|" &
        "=f-rin-nome:Lampadina|?e-f-rin-nome|!rin-mostra|@rin-mostra|?rin-sintesi|?rin-righe|?rin-testi|?rin-b-t5|?rin-cartelle|?rin-controllo|!rin-ok|" &
        "@rin-t-t1|!rin-t-t1|@rin-ok|?scheda-nome|!b-annulla|?esito"
      s.avviaEditor(argsEditor(d, "LuceScale"), root, @[("BCDD_EDITOR_PROVA_CLIC", clic)])
      let fine = attendi(s.trace, "pagina 4", 60)
      sleep(500)
      raccogli(s)
      let q = sondeDi(s)
      rec("AC-443", "la sessione risponde a tutte le sonde e disegna quattro volte (apertura, Zeta, anteprima, scrittura con Ricarica)", fine and q.len >= 24 and ref0 != nil,
        $q.len & " " & cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 600))
      if q.len >= 24:
        rec("AC-443", "prima di cominciare «Torna indietro» è acceso (la creazione di Zeta), la scheda è quella di Luce", "acceso" in q[0] and "Luce" in q[1], q[0] & " / " & q[1])
        rec("AC-443", "il modulo ha il campo «Nome nuovo» già riempito con «Luce»; «Mostra che cosa cambia» è spento (nome uguale)", "valore=Luce" in q[3] and "spento" in q[4] and "visibile" in q[2], q[2] & " / " & q[3] & " / " & q[4])
        rec("AC-443", "«END»: sotto il campo il motivo (parola riservata) e il bottone spento", "riservata" in q[5] and "spento" in q[6], q[5] & " / " & q[6])
        rec("AC-443", "«Luce-2»: il nome non è valido, bottone spento", "non è valido" in q[7] and "spento" in q[8], q[7] & " / " & q[8])
        rec("AC-443", "«Luce»: è uguale a quello di adesso, bottone spento", "uguale" in q[9] and "spento" in q[10], q[9] & " / " & q[10])
        rec("AC-443", "«Lampadina»: nessun motivo e «Mostra che cosa cambia» acceso", q[11].endsWith("visibile ") and "acceso" in q[12], q[11] & " / " & q[12])
        rec("AC-444", "la sintesi dice quante righe e quanti file cambiano (come li conta bcdd rename)", sintesi in q[13], q[13] & " vs " & sintesi)
        rec("AC-444", "le righe per file con prima e dopo: «CSC Luce VERSION 0.1» diventa «CSC Lampadina VERSION 0.1», anche in comuni/Corridoio.csc",
          "luce/Luce.csc" in q[14] and "CSC Luce VERSION 0.1" in q[14] and "CSC Lampadina VERSION 0.1" in q[14] and "comuni/Corridoio.csc" in q[14], cut(q[14], 400))
        rec("AC-444", "i testi: t1, t2, t3, t4, t6 con la casella; t5 (riga approvata) senza casella, in grigio, «resta Luce: riga approvata»",
          "t1 " in q[15] and "t2 " in q[15] and "t3 " in q[15] and "t4 " in q[15] and "t6 " in q[15] and "visibile" in q[16] and "t5 [=]" in q[16] and "resta Luce: riga approvata" in q[16], cut(q[15], 300) & " / " & q[16])
        rec("AC-444", "la riga fissa sulle cartelle aperte e «il controllo di bcdd resta uguale»", "Solo le cartelle aperte" in q[17] and "resta uguale su" in q[18], q[17] & " / " & q[18])
        rec("AC-445", "il bottone Rinomina c'è; t1 era scelto e dopo il clic non lo è più", "acceso" in q[19] and "scelto=false" in q[20], q[19] & " / " & q[20])
        let lr = lanciRen(s)
        rec("AC-444", "il primo comando è l'anteprima: --dry-run --json, con la cartella corrente (.) e l'altra per intero (le --dir di check)",
          lr.len >= 2 and ("--dir . --dir " & d / "comuni") in lr[0] and "--dry-run --json csc Luce Lampadina" in lr[0] and lr[0].startsWith("rename Luce.csc"), $lr)
        rec("AC-445", "il secondo comando ha --expect, i testi scelti uno per uno (t2 t3 t4 t6, non t1 né t5) e nessun --text default",
          lr.len >= 2 and "--expect sha256:" in lr[1] and "--text-at t2 --text-at t3 --text-at t4 --text-at t6" in lr[1] and "t1" notin lr[1] and "--text default" notin lr[1] and "--dry-run" notin lr[1], $lr)
        rec("AC-445", "Ricarica fatta: la scheda è quella di Lampadina; «Torna indietro» svuotato; lo Stato dice come tornare indietro",
          "Lampadina" in q[21] and "spento" in q[22] and "Rinominato Luce in Lampadina" in q[23] and "Per tornare indietro rinomina Lampadina in Luce." in q[23], q[21] & " / " & q[22] & " / " & q[23])
      let dopo = tuttoSint(d)
      rec("AC-445", "i file: Lampadina.csc c'è, Luce.csc no; la riga 1 di Lampadina.csc ha ancora «Luce» (t1 tolto), la 4 ha «Lampadina» (t2)",
        "luce/Lampadina.csc" in dopo and "luce/Luce.csc" notin dopo and dopo.getOrDefault("luce/Lampadina.csc").splitLines()[0].contains("-- Luce:") and
        dopo.getOrDefault("luce/Lampadina.csc").splitLines()[3].contains("La Lampadina si accende"), $nomiSint(d))
      rec("AC-445", "nessun file di lavoro né giornale rimasti, nessun save oltre alla creazione di Zeta", nomiSint(d).allIt(not it.contains(".bcdd-rinomina") and not it.contains(".rinomina-")) and
        azioniLanci(s).count("save") == 1 and azioniLanci(s).count("rename") == 2, $azioniLanci(s))
      s.finisci()
    # ---- AC-446: un elemento approvato: la spiegazione e «Nuova versione…», nessuna scrittura
    block:
      let d = copiaSint()
      let prima = tuttoSint(d)
      var s = nuovaSessione()
      s.avviaEditor(argsEditor(d, "Pulsante"), root, @[("BCDD_EDITOR_PROVA_CLIC",
        "#c-Comando|?scheda-nome|@b-rinomina|=f-rin-nome:Interruttore|@rin-mostra|?rin-approvato|?rin-bloccanti|?rin-versione|!rin-ok|!f-rin-nome|!rin-mostra")])
      let fine = attendi(s.trace, "pagina 2", 60)
      sleep(400)
      raccogli(s)
      let q = sondeDi(s)
      rec("AC-446", "la sessione risponde a tutte le sonde", fine and q.len >= 7, $q.len & " " & cut(leggiSe(s.trace), 600))
      if q.len >= 7:
        rec("AC-446", "il riquadro dice che il nome è contratto e serve una versione nuova con una decisione nuova",
          "Il nome fa parte del contratto approvato: non si cambia con un clic. Serve una versione nuova, con una decisione nuova." in q[1], q[1])
        rec("AC-446", "l'elenco dei bloccanti ha la riga 1 di Comando.csc e D-5", "Comando.csc, riga 1: CSC Comando VERSION 0.1" in q[2] and "D-5" in q[2], q[2])
        rec("AC-446", "c'è «Nuova versione…»; non c'è il bottone Rinomina; il campo e «Mostra» sono spenti", "visibile Nuova versione…" in q[3] and "assente" in q[4] and "spento" in q[5] and "spento" in q[6], $q)
      rec("AC-446", "nessuna scrittura: solo l'anteprima, file identici", lanciRen(s).len == 1 and "--dry-run" in lanciRen(s)[0] and azioniLanci(s).count("save") == 0 and tuttoSint(d) == prima, $lanciRen(s))
      s.finisci()
    # ---- AC-447: una modifica non salvata, poi «Rinomina…»
    block:
      let d = copiaSint()
      var s = nuovaSessione()
      s.avviaEditor(argsEditor(d, "LuceScale"), root, @[("BCDD_EDITOR_PROVA_CLIC",
        "#c-Luce|@b-promessa|=f-frase:Una promessa non salvata|@b-rinomina|?avviso|@f-rinomina-no|!f-frase|?avviso|@b-rinomina|@f-rinomina-si|!f-frase|?f-rin-nome|!f-rin-nome|?avviso")])
      let fine = attendi(s.trace, "pagina 2", 60)
      sleep(500)
      raccogli(s)
      let q = sondeDi(s)
      rec("AC-447", "la sessione risponde a tutte le sonde e disegna due volte (apertura e Ricarica)", fine and q.len >= 7 and nDisegni(s) == 2, $q.len & " " & $nDisegni(s) & " " & cut(leggiSe(s.trace), 600))
      if q.len >= 7:
        rec("AC-447", "con la modifica non salvata la striscia ha le due scelte", "visibile" in q[0] and "C'è una modifica non salvata: rinominando la perdi." in q[0] and
          "Rinomina e perdi la modifica" in q[0] and "Annulla e tieni la modifica" in q[0], cut(q[0]))
        rec("AC-447", "«Annulla e tieni la modifica» lascia il testo e chiude la striscia", "Una promessa non salvata" in q[1] and "nascosto" in q[2] and nDisegni(s) >= 1, q[1] & " / " & q[2])
        rec("AC-447", "«Rinomina e perdi la modifica»: la modifica è scartata (il campo non c'è più), il modulo di rinomina è aperto con il nome di adesso",
          "assente" in q[3] and "visibile" in q[4] and "valore=Luce" in q[5] and "nascosto" in q[6], q[3] & " / " & q[4] & " / " & q[5] & " / " & q[6])
      rec("AC-447", "bcdd è stato rilanciato dalla Ricarica; niente è scritto", azioniLanci(s).count("save") == 0 and azioniLanci(s).count("rename") == 0, $azioniLanci(s))
      s.finisci()
    # ---- AC-448: l'anteprima, un file cambiato da fuori, la conferma
    block:
      let d = copiaSint()
      var s = nuovaSessione()
      s.avviaEditor(argsEditor(d, "LuceScale"), root, @[("BCDD_EDITOR_PROVA_CLIC",
        "~|#c-Luce|@b-rinomina|=f-rin-nome:Lampadina|@rin-mostra|~|@rin-ok|?rin-esito|?rin-ricarica|!rin-ok|!f-rin-nome")])
      let pronto = attendi(s.trace, "attesa_fuoco", 40)
      rec("AC-448", "la finestra si apre e aspetta il ritorno del fuoco", pronto, cut(leggiSe(s.dir / "errori")))
      if pronto:
        let w = trovaFinestra(display, "bcdd-editor")
        focusAltrove(display, w)                       # il primo ritorno del fuoco: niente è cambiato
        let seconda = attendi(s.trace, "pagina 2", 40)
        var att2 = false
        let fineAtt = epochTime() + 40.0
        while epochTime() < fineAtt and not att2:
          att2 = righe(s.trace).countIt("attesa_fuoco" in it) >= 2
          sleep(50)
        rec("AC-448", "l'anteprima è mostrata e la finestra aspetta il secondo ritorno del fuoco", seconda and att2, cut(leggiSe(s.trace), 600))
        if att2:
          writeFile(d / "luce" / "Pressione.csc", readFile(d / "luce" / "Pressione.csc") & "-- cambiato da fuori\n")
          let dopo = tuttoSint(d)
          focusAltrove(display, w)
          let fine = attendi(s.trace, "pagina 3", 40)      # il ritorno del fuoco rilegge (un commento in fondo non cambia il modello: nessun ridisegno)
          sleep(400)
          raccogli(s)
          let q = sondeDi(s)
          rec("AC-448", "la sessione risponde a tutte le sonde (apertura, anteprima, esito)", fine and q.len >= 4, $q.len & " " & cut(leggiSe(s.trace), 600))
          if q.len >= 4:
            rec("AC-448", "il riquadro dice che i file sono cambiati dopo l'anteprima e offre «Ricarica»", "sono cambiati dopo l'anteprima" in q[0] and "visibile" in q[1] and "Ricarica" in q[1], q[0] & " / " & q[1])
            rec("AC-448", "il bottone Rinomina non c'è più e il campo è spento", "assente" in q[2] and "spento" in q[3], q[2] & " / " & q[3])
          rec("AC-448", "nessun file scritto: i file sono quelli di prima della conferma, nessun giornale", tuttoSint(d) == dopo and azioniLanci(s).count("rename") == 2, $azioniLanci(s))
      s.finisci()
    # ---- AC-449: un giornale lasciato da una rinomina interrotta (bcdd_prova ferma dopo 3 operazioni): la striscia, le azioni spente, Ripristina
    block:
      let d = copiaSint()
      let prima = tuttoSint(d)
      let p0 = anteprimaRef(d, @["csc", "Luce", "Lampadina"])
      let imp = if p0 != nil and p0.hasKey("impronta"): p0["impronta"].getStr else: ""
      let rI = runExe(bcddProva, @["rename", "Luce.csc", "--dir", ".", "--dir", d / "comuni", "--expect", imp, "--json", "csc", "Luce", "Lampadina"], d / "luce",
        envPulito([("BCDD_RINOMINA_PROVA_FERMA", "3")]))
      rec("AC-449", "la rinomina di prova si ferma dopo tre operazioni (codice 99) e lascia i giornali in luce/ e in comuni/",
        rI.code == 99 and fileExists(d / "luce" / ".bcdd-rinomina") and fileExists(d / "comuni" / ".bcdd-rinomina"), $rI.code & " " & cut(rI.errout))
      let interrotto = tuttoSint(d)
      var s = nuovaSessione()
      s.avviaEditor(argsEditor(d, "LuceScale"), root, @[("BCDD_EDITOR_PROVA_CLIC",
        "?avviso|!b-nuova|!b-pubblico|!b-versione|!b-rinomina|!b-promessa|!b-ricarica|@f-ripristina|?avviso|!b-nuova|!b-rinomina")])
      let fine = attendi(s.trace, "pagina 2", 60)
      sleep(500)
      raccogli(s)
      let q = sondeDi(s)
      rec("AC-449", "la sessione risponde a tutte le sonde e disegna due volte (apertura, Ripristina)", fine and q.len >= 10 and nDisegni(s) == 2, $q.len & " " & $nDisegni(s) & " " & cut(leggiSe(s.trace), 600))
      if q.len >= 10:
        rec("AC-449", "all'apertura la striscia dice quale rinomina si è fermata (Luce → Lampadina) e che non si scrive nulla; c'è «Ripristina»",
          "visibile" in q[0] and "Una rinomina si è fermata a metà (Luce → Lampadina): finché non la ripristini non si scrive nulla." in q[0] and "Ripristina" in q[0], cut(q[0]))
        rec("AC-449", "le azioni che scrivono sono spente (Nuova entità, connettore pubblico, Promessa, Rinomina…); Ricarica resta accesa",
          "spento" in q[1] and "spento" in q[2] and "spento" in q[4] and "spento" in q[5] and "acceso" in q[6], $q[1 .. 6])
        rec("AC-449", "Ripristina: la striscia sparisce e le azioni tornano accese", "nascosto" in q[7] and "acceso" in q[8] and "acceso" in q[9], q[7] & " / " & q[8] & " / " & q[9])
      rec("AC-449", "i file sono com'erano prima della rinomina; nessun giornale né file di lavoro", tuttoSint(d) == prima and interrotto != prima and not fileExists(d / "luce" / ".bcdd-rinomina") and
        not fileExists(d / "comuni" / ".bcdd-rinomina"), $nomiSint(d))
      rec("AC-449", "il ripristino è `bcdd rename --recover CARTELLA` (e nessuna scrittura dell'editor)", righe(s.lanci).anyIt(it.startsWith("rename --recover ")) and azioniLanci(s).count("save") == 0, $azioniLanci(s))
      s.finisci()
    # ---- AC-450: il posto dal Banco, l'identificativo dal modulo di una promessa e dalla casella di una storia
    block:
      # il posto
      let d = copiaSint()
      var s = nuovaSessione()
      s.avviaEditor(argsEditor(d, "LuceScale"), root, @[("BCDD_EDITOR_PROVA_CLIC",
        "@t-dentro|#p-lampada|!b-rinomina-posto|@b-rinomina-posto|=f-rin-nome:plafoniera|@rin-mostra|@rin-ok")])
      let fine = attendi(s.trace, "pagina 3", 60)
      sleep(500)
      raccogli(s)
      let q = sondeDi(s)
      rec("AC-450", "il posto: la sessione risponde e disegna tre volte (apertura, anteprima, scrittura); «Rinomina il posto…» c'è accanto a «Togli»", fine and q.len >= 1 and "acceso" in q[0], $q.len & " " & $nDisegni(s) & " " & cut(leggiSe(s.trace), 600))
      let lr = lanciRen(s)
      rec("AC-450", "il comando è `part lampada plafoniera` con --csc LuceScale (anteprima e scrittura)", lr.len == 2 and lr.allIt(" --csc LuceScale " in it and it.endsWith("part lampada plafoniera")), $lr)
      let dopo = tuttoSint(d)
      let ls = dopo.getOrDefault("luce/LuceScale.csc").splitLines()
      rec("AC-450", "come AC-429: solo la riga 7 di LuceScale.csc (`plafoniera  : Lampada`); Corridoio.csc invariato",
        ls.len >= 7 and ls[6] == "    plafoniera  : Lampada" and dopo["comuni/Corridoio.csc"] == tuttoSint(sint)["comuni/Corridoio.csc"], cut(ls.join("|")))
      s.finisci()
      # l'identificativo dal modulo di la1
      let d2 = copiaSint()
      var s2 = nuovaSessione()
      s2.avviaEditor(argsEditor(d2, "LuceScale"), root, @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|#r-6|@f-rinomina-id|=f-rin-nome:la-base|@rin-mostra|@rin-ok")])
      let fine2 = attendi(s2.trace, "pagina 3", 60)
      sleep(500)
      raccogli(s2)
      let lr2 = lanciRen(s2)
      rec("AC-450", "l'identificativo dal modulo: il comando è `id la1 la-base` con --csc Luce", fine2 and lr2.len == 2 and lr2.allIt(" --csc Luce " in it and it.endsWith("id la1 la-base")), $lr2 & " " & cut(leggiSe(s2.trace), 600))
      let l2 = tuttoSint(d2).getOrDefault("luce/Luce.csc").splitLines()
      rec("AC-450", "come AC-428: righe 6 e 8 di Luce.csc", l2.len >= 8 and l2[5].contains("GUARANTEE la-base:") and l2[7].contains("DETAILS la-base:"), cut(l2.join("|")))
      s2.finisci()
      # l'identificativo dalla casella di una storia (s1)
      let d3 = copiaSint()
      var s3 = nuovaSessione()
      s3.avviaEditor(argsEditor(d3, "LuceScale"), root, @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|#r-10|@f-rinomina-id|=f-rin-nome:s-spenta|@rin-mostra|@rin-ok")])
      let fine3 = attendi(s3.trace, "pagina 3", 60)
      sleep(500)
      raccogli(s3)
      let lr3 = lanciRen(s3)
      rec("AC-450", "l'identificativo dalla casella di una storia: il comando è `id s1 s-spenta` con --csc Luce", fine3 and lr3.len == 2 and lr3.allIt(" --csc Luce " in it and it.endsWith("id s1 s-spenta")), $lr3 & " " & cut(leggiSe(s3.trace), 600))
      let l3 = tuttoSint(d3)
      rec("AC-450", "come AC-428: riga 10 di Luce.csc e riga 3 di LuceProva.csc", l3.getOrDefault("luce/Luce.csc").splitLines()[9].contains("SCENARIO s-spenta") and
        l3.getOrDefault("luce/LuceProva.csc").splitLines()[2].contains("TRANSLATES s-spenta"), "")
      s3.finisci()
    # ---- AC-451: un giro di Completa aperto: i bottoni di rinomina spenti (l'LLM finto, lento, e «Ferma»)
    block:
      let d = newWd0()
      copyFile(rf9 / "Luce.csc", d / "Luce.csc")
      writeFile(d / "Lampada.csc", "ENTITY Lampada VERSION 0.1\n  PURPOSE \"La lampada\"\n  OFFERS Luce\nEND\n")
      var s = nuovaSessione()
      createDir s.dir / "aux"
      let amb = @[("BCDD_LLM", fintoLlm9), ("BCDD_ATTESA_LLM", "30"), ("BCDD_ORA", "2026-10-16T18:00:00+02:00"), ("BCDD_REGISTRO", s.dir / "chiamate.tsv"),
        ("BCDD_FINTO_CONTA", s.dir / "aux" / "conta"), ("BCDD_FINTO_RISPOSTA", rf9 / "risposte" / "buona.json"), ("BCDD_FINTO_RISPOSTA_2", rf9 / "risposte" / "buona_seconda.json"),
        ("BCDD_FINTO_ATTESA", "25")]
      s.avviaEditor(@["--lang", "it", "--dir", d, "Lampada"], root, amb & @[("BCDD_EDITOR_PROVA_CLIC", "#c-Luce|!b-rinomina|>b-completa|!b-rinomina|>c-ferma")])
      let fine = attendi(s.trace, "pagina 2", 40)
      sleep(400)
      raccogli(s)
      let q = sondeDi(s)
      rec("AC-451", "la sessione risponde a tutte le sonde", fine and q.len >= 2, $q.len & " " & cut(leggiSe(s.trace), 600))
      if q.len >= 2:
        rec("AC-451", "prima di Completa «Rinomina…» è acceso; con il giro aperto è spento", "acceso" in q[0] and "spento" in q[1], $q)
      s.finisci()
    # ---- AC-473: «scrittura» con ripristino riuscito (R2): il messaggio nel riquadro e «Ricarica», nessuna Ricarica automatica
    block:
      let d = copiaSint()
      let prima = tuttoSint(d)
      var s = nuovaSessione()
      s.avviaEditor(argsEditor(d, "LuceScale"), root, @[("BCDD_RINOMINA_PROVA_ERRORE", "3"), ("BCDD_EDITOR_PROVA_CLIC",
        "#c-Luce|@b-rinomina|=f-rin-nome:Lampadina|@rin-mostra|@rin-ok|?rin-esito|!f-rin-nome|!rin-mostra|?rin-ricarica|!rin-ok")])
      let fine = attendi(s.trace, "pagina 3", 60)
      sleep(700)
      raccogli(s)
      let q = sondeDi(s)
      rec("AC-473", "la sessione risponde a tutte le sonde: tre disegni (apertura, anteprima, esito) e nessuno in più, cioè nessuna Ricarica automatica",
        fine and q.len >= 5 and nDisegni(s) == 3, $q.len & " " & $nDisegni(s) & " " & cut(leggiSe(s.trace), 600))
      if q.len >= 5:
        rec("AC-473", "il riquadro ha il messaggio di bcdd senza il prefisso «bcdd rename: »: «non riesco a scrivere …; i file già scritti sono tornati com'erano»",
          "non riesco a scrivere" in q[0] and "i file già scritti sono tornati com'erano" in q[0] and "bcdd rename: " notin q[0], q[0])
        rec("AC-473", "campo e «Mostra che cosa cambia» spenti, il bottone «Ricarica» c'è, «Rinomina» non c'è più", "spento" in q[1] and "spento" in q[2] and "visibile Ricarica" in q[3] and "assente" in q[4], $q)
      rec("AC-473", "tutti i file della cartella sintetica sono identici a prima; nessun giornale né file di lavoro", tuttoSint(d) == prima and
        not fileExists(d / "luce" / ".bcdd-rinomina") and not fileExists(d / "comuni" / ".bcdd-rinomina") and nomiSint(d).allIt(not it.contains(".rinomina-")), $nomiSint(d))
      s.finisci()
      # il clic su «Ricarica»: un disegno in più, il modulo chiuso, la scheda di Luce
      let d2 = copiaSint()
      var s2 = nuovaSessione()
      s2.avviaEditor(argsEditor(d2, "LuceScale"), root, @[("BCDD_RINOMINA_PROVA_ERRORE", "3"), ("BCDD_EDITOR_PROVA_CLIC",
        "#c-Luce|@b-rinomina|=f-rin-nome:Lampadina|@rin-mostra|@rin-ok|@rin-ricarica|?scheda-modulo|?scheda-nome")])
      let fine2 = attendi(s2.trace, "pagina 4", 60)
      sleep(500)
      raccogli(s2)
      let q2 = sondeDi(s2)
      rec("AC-473", "dopo il clic su «Ricarica»: un disegno in più (quattro), il modulo chiuso, la scheda di Luce",
        fine2 and q2.len >= 2 and nDisegni(s2) == 4 and "nascosto" in q2[0] and "Luce" in q2[1], $q2.len & " " & $nDisegni(s2) & " " & $q2 & " " & cut(leggiSe(s2.trace), 400))
      s2.finisci()
    # ---- AC-474: cartelle omonime: le etichette del riquadro; con una sola cartella sintetica come in AC-444
    block:
      let d = copiaSint()
      let altro = d / "altro" / "luce"
      createDir(altro)
      writeFile(altro / "Atrio.csc", readFile(d / "comuni" / "Corridoio.csc").replace("Corridoio", "Atrio"))
      let eL = lastPathPart(d) & "/luce"                  # d/luce e d/altro/luce: l'ultimo segmento è uguale, il penultimo no
      var s = nuovaSessione()
      s.avviaEditor(@["--lang", "it", "--dir", d / "luce", "--dir", d / "comuni", "--dir", altro, "LuceScale"], root, @[("BCDD_EDITOR_PROVA_CLIC",
        "#c-Luce|@b-rinomina|=f-rin-nome:Lampadina|@rin-mostra|*#rin-righe .rin-file|*#rin-pannello .rin-file-nuovo|?rin-testi")])
      let fine = attendi(s.trace, "pagina 2", 60)
      sleep(500)
      raccogli(s)
      let q = sondeDi(s)
      rec("AC-474", "la sessione risponde a tutte le sonde", fine and q.len >= 3, $q.len & " " & cut(leggiSe(s.dir / "errori")) & " " & cut(leggiSe(s.trace), 600))
      if q.len >= 3:
        rec("AC-474", "le due cartelle `luce` hanno etichette diverse, il più breve tratto che le distingue: «" & eL & "» e «altro/luce»; `comuni` resta «comuni»",
          (eL & "/Luce.csc => " & d / "luce") in q[0] and ("comuni/Corridoio.csc => " & d / "comuni") in q[0] and ("altro/luce/Atrio.csc => " & altro) in q[0], q[0])
        rec("AC-474", "nessuna etichetta è il solo ultimo segmento ambiguo (`luce/…`)", not q[0].contains(" | luce/") and not q[0].startsWith("Q:") and q[0].find("] luce/") < 0, q[0])
        rec("AC-474", "anche il file rinominato (Luce.csc → Lampadina.csc) porta l'etichetta e il percorso assoluto nel titolo", (eL & "/Luce.csc") in q[1] and ("=> " & d / "luce") in q[1], q[1])
        rec("AC-474", "le righe dei testi portano la stessa etichetta", eL & "/" in q[2] or "luce/" in q[2], cut(q[2]))
      s.finisci()
    # ---- AC-475: il modulo di rinomina non è una modifica non salvata
    block:
      let d = copiaSint()
      let prima = tuttoSint(d)
      var s = nuovaSessione()
      s.avviaEditor(argsEditor(d, "LuceScale"), root, @[("BCDD_EDITOR_PROVA_CLIC",
        "#c-Luce|@b-rinomina|=f-rin-nome:Lampadina|!l-en|@rin-mostra|@rin-t-t1|!rin-t-t1|!l-en|@b-ricarica|?avviso|?scheda-modulo|" &
        "#c-Luce|@b-rinomina|=f-rin-nome:Lampadina|!l-en|#c-Pressione|@b-rinomina|?avviso|!f-rin-nome|=f-rin-nome:Interruttore|!l-en|@l-en|?scheda-modulo|!f-rin-nome|?avviso")])
      let fine = attendi(s.trace, "pagina 4", 60)
      sleep(600)
      raccogli(s)
      let q = sondeDi(s)
      rec("AC-475", "la sessione risponde a tutte le sonde e disegna quattro volte (apertura, anteprima, Ricarica, cambio di lingua)", fine and q.len >= 12 and nDisegni(s) == 4,
        $q.len & " " & $nDisegni(s) & " " & cut(leggiSe(s.trace), 600))
      if q.len >= 12:
        rec("AC-475", "scrivendo il nome la lingua resta cambiabile; anche dopo l'anteprima e dopo il clic sulla casella di t1",
          "acceso" in q[0] and "scelto=false" in q[1] and "acceso" in q[2], q[0] & " / " & q[1] & " / " & q[2])
        rec("AC-475", "(a) Ricarica: nessuna striscia di conferma, il modulo è chiuso", "nascosto" in q[3] and "nascosto" in q[4], q[3] & " / " & q[4])
        rec("AC-475", "(b) «Rinomina…» di un altro connettore con il modulo scritto: la lingua restava cambiabile, nessuna striscia di E1, si apre il modulo di Pressione",
          "acceso" in q[5] and "nascosto" in q[6] and "acceso" in q[7] and "valore=Pressione" in q[7], q[5] & " / " & q[6] & " / " & q[7])
        rec("AC-475", "(c) cambio di lingua con il nome scritto: nessun rifiuto, modulo chiuso, campo assente, nessuna striscia",
          "acceso" in q[8] and "nascosto" in q[9] and "assente" in q[10] and "nascosto" in q[11], $q[8 .. 11])
      rec("AC-475", "nessuna scrittura lanciata (solo l'anteprima) e file identici", lanciRen(s).len == 1 and "--dry-run" in lanciRen(s)[0] and azioniLanci(s).count("save") == 0 and tuttoSint(d) == prima, $lanciRen(s))
      s.finisci()
    # ---- AC-476: l'elenco delle cartelle e il riferimento interno mostrano le cartelle come il riquadro di rinomina
    block:
      let d = copiaSint()
      let altro = d / "altro" / "luce"
      createDir(altro)
      writeFile(altro / "Atrio.csc", readFile(d / "comuni" / "Corridoio.csc").replace("Corridoio", "Atrio"))
      let eL = lastPathPart(d) & "/luce"
      var s = nuovaSessione()
      s.avviaEditor(@["--lang", "it", "--dir", d / "luce", "--dir", d / "comuni", "--dir", altro, "LuceScale"], root, @[("BCDD_EDITOR_PROVA_CLIC",
        "@b-cartelle|*#cartelle-elenco .car-testa")])
      let fine = attendi(s.trace, "pagina 1", 60)
      sleep(500)
      raccogli(s)
      let q = sondeDi(s)
      rec("AC-476", "la sessione risponde", fine and q.len >= 1, $q.len & " " & cut(leggiSe(s.trace), 400))
      if q.len >= 1:
        rec("AC-476", "l'elenco delle cartelle ha le etichette «" & eL & "», «comuni» e «altro/luce», ciascuna con il percorso assoluto nel titolo",
          (eL & " => " & d / "luce") in q[0] and ("comuni => " & d / "comuni") in q[0] and ("altro/luce => " & altro) in q[0], q[0])
      s.finisci()
    # ---- il codice: nessun timer, nessuna rete, nessun innerHTML nella parte nuova; i testi nelle due lingue; la rinomina non entra in Torna indietro
    block:
      let js = readFile(root / "editor" / "pagina" / "pagina.js")
      let i0 = js.find("// ---- : «Rinomina")
      let i1 = js.find("// ---- l'ultima cosa")
      let parte = if i0 >= 0 and i1 > i0: js[i0 ..< i1] else: ""
      rec("AC-450", "la parte della pagina per la rinomina non usa innerHTML, timer, rete né il menu del tasto destro", parte.len > 3000 and "innerHTML" notin parte and "setTimeout" notin parte and
        "setInterval" notin parte and "fetch(" notin parte and "XMLHttpRequest" notin parte and "contextmenu" notin parte, $parte.len)
      let tj = readFile(root / "editor" / "pagina" / "testi.js")
      rec("AC-450", "i testi nuovi ci sono nelle due lingue", tj.count("\"rinom_approvato\"") == 2 and tj.count("\"giornale_avviso\"") == 2 and tj.count("\"b_rinomina_posto\"") == 2 and
        tj.count("\"rinom_sporco_si\"") == 2, "")
      let fin = readFile(root / "editor" / "edfinestra.nim")
      let k0 = fin.find("proc eseguiRinomina(")
      let k1 = fin.find("proc alCambioFuoco(")
      let blocchi = if k0 >= 0 and k1 > k0: fin[k0 ..< k1] else: ""
      rec("AC-445", "la rinomina non entra in «Torna indietro» (ultima e descrUltima si svuotano), non lancia save, né timer né osservatori", blocchi.len > 1500 and "ultima = @[]" in blocchi and
        "\"save\"" notin blocchi and "timeout" notin blocchi and "monitor" notin blocchi.toLowerAscii and "\"rename\"" in blocchi, $blocchi.len)

spegni(xvfb)
removeDir(tmpBase)
var acFail0 = 0
for ac in acOrder:
  if acPass[ac] != acTotal[ac]: inc acFail0
rec("AC-199", "nessun criterio dell'editor è fallito", acFail0 == 0, $acFail0 & " criteri non riusciti")
var totalPass, totalAll, acFail = 0
acOrder.sort(proc(a, b: string): int = cmp(parseInt(a[3 .. ^1]), parseInt(b[3 .. ^1])))
for ac in acOrder:
  let ok = acPass[ac] == acTotal[ac]
  totalPass += acPass[ac]
  totalAll += acTotal[ac]
  if not ok: inc acFail
  echo align(ac, 5) & "  " & (if ok: "PASS " else: "FAIL ") & $acPass[ac] & "/" & $acTotal[ac]
  if not ok:
    for d in details[ac]: echo "        - " & d
for n in nonEsercitati: echo "non esercitato " & n
echo "controlli: " & $totalPass & "/" & $totalAll & " PASS; criteri non riusciti: " & $acFail &
  "; non esercitati: " & $nonEsercitati.len & "; durata suite: " & formatFloat(epochTime() - t0, ffDecimal, 2) & " s"
quit(if totalPass == totalAll: 0 else: 1)

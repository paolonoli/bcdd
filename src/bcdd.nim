# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 040:1:1 bcdd: strumento a riga di comando per scrivere CSC BCDD: `new`, `check`, `ratify`, `refine`.
# 040:1:2 Codici d'uscita: 0 bene, 1 errori (o file esistente per `new`), 2 uso o file non leggibile,
# 040:1:3 3 solo righe non riconosciute con --strict (GRAMMATICA_F1 sezioni 10 e 11).
import std/os
import bcddcheck, bcddprog, bcddnew, bcddsafe, bcddratify, bcddrefine, bcddsave, bcddtesti, bcddsys

proc fail(msg: string, code: int) = die(msg, code)

proc runCheck(args: seq[string]) =
  var strict = false
  var json = false
  var file = ""
  var haveFile = false
  var dirs: seq[string]
  var i = 0
  while i < args.len:
    let a = args[i]
    if a == "--strict":
      if strict: fail(testo(kUsoCheck), 2)
      strict = true
      inc i
    elif a == "--json":
      # 040:2:1 (F4a) l'uscita per programmi; la stessa opzione due volte è un uso sbagliato, come --strict
      if json: fail(testo(kUsoCheck), 2)
      json = true
      inc i
    elif a == "--dir":
      if i + 1 >= args.len: fail(testo(kUsoCheck), 2)
      if args[i + 1] in dirs: fail(testo(kUsoCheck), 2)
      dirs.add args[i + 1]
      i += 2
    elif a.len > 0 and a[0] == '-':
      fail(testo(kUsoCheck), 2)
    elif haveFile:
      fail(testo(kUsoCheck), 2)
    else:
      file = a
      haveFile = true
      inc i
  if not haveFile: fail(testo(kUsoCheck), 2)
  let raw = loadSource("bcdd check", file)
  for d in dirs: checkDirArg("bcdd check", d)
  var rep = analyze(raw)
  resolveCitations(rep, file, dirs)
  let code = exitCodeFor(rep, strict)
  if json:
    stdout.write renderJson(rep, extractFilename(file), raw, strict, code)
  else:
    stdout.write render(rep, extractFilename(file), strict)
  stdout.flushFile()
  quit(code)

proc runNew(args: seq[string]) =
  if args.len != 1: fail(testo(kNewUso), 2)
  let name = args[0]
  if not validName(name): fail(testo(kNewNomeNonValido, name), 2)
  if isDeviceName(name): fail(testo(kNewNomeDispositivo, name), 2)
  let target = name & ".csc"
  var why = ""
  case createExclusive(target, skeleton(name), why)
  of crCreated:
    stdout.write testo(kNewCreato, target) & "\n"
    stdout.flushFile()
    quit(0)
  of crExists:
    fail(testo(kNewEsiste, target), 1)
  of crFailed:
    fail(testo(kNewNonRiescoCreare, target, why), 1)

proc setupLang(args: seq[string]): seq[string] =
  ## 040:3:1: `--lang it|en` solo prima del comando, poi BCDD_LANG, poi l'inglese; LANG non si legge.
  ## La lingua si imposta qui, una volta, prima di ogni lettura di file e di ogni analisi. Restituisce gli argomenti senza `--lang`.
  let ev = getEnv("BCDD_LANG")
  var envLang = lgEn
  var envValid = true
  if ev == "it": envLang = lgIt
  elif ev == "en" or ev == "": discard
  else: envValid = false
  if args.len > 0 and args[0] == "--lang":
    lingua = if envValid: envLang else: lgEn
    if args.len == 1: fail(testo(kUsoGenerale), 2)
    if args[1] notin ["it", "en"]: fail(testo(kLangAccetta, args[1]), 2)
    lingua = if args[1] == "it": lgIt else: lgEn
    if args.len == 2: fail(testo(kUsoGenerale), 2)
    return args[2 .. ^1]
  if not envValid:
    lingua = lgEn
    fail(testo(kLangEnvNonValida, ev), 2)
  lingua = envLang
  args

proc main() =
  prepareStreams()      # 040:4:1 su Windows flussi in binario e console in UTF-8; su Linux niente
  let args = setupLang(commandLineParams())
  if args.len == 0: fail(testo(kUsoGenerale), 2)
  case args[0]
  of "new": runNew(args[1 .. ^1])
  of "check": runCheck(args[1 .. ^1])
  of "ratify": runRatify(args[1 .. ^1])
  of "refine": runRefine(args[1 .. ^1])
  of "save": runSave(args[1 .. ^1])
  else: fail(testo(kUsoGenerale), 2)

main()

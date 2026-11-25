# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 001:1:1 LLM finto per le prove di bcdd refine su Windows: fa quello che fa prove/f2/ULlmFinto.sh, ma è un eseguibile,
# 001:1:2 perché Windows non lancia uno script di shell con CreateProcessW. Si compila con `nim c -d:release llmfinto.nim`
# 001:1:3 e si usa con BCDD_LLM=percorso\ULlmFinto.exe (solo nell'eseguibile di prova -d:bcddProva).
# 001:1:4 Variabili (le stesse dello script, con suffisso _2 dalla seconda chiamata): BCDD_FINTO_CONTA, _PID, _RICHIESTA, _TOCCA,
# 001:1:5 _ATTESA (secondi), _RISPOSTA (file da restituire), _CODICE (codice d'uscita).
import std/[os, strutils]

proc leggiTutto(): string =
  var buf = newString(65536)
  while true:
    let n = stdin.readBuffer(addr buf[0], buf.len)
    if n <= 0: break
    result.add buf[0 ..< n]

proc main() =
  # 001:2:1 con ARGS_OUT scrive gli argomenti ricevuti, uno per riga (anche quello vuoto), per provare la ricerca di `claude`
  let argsOut = getEnv("ARGS_OUT")
  if argsOut.len > 0:
    var a = ""
    for i in 1 .. paramCount(): a.add paramStr(i) & "\n"
    writeFile(argsOut, a)
  var n = 1
  let conta = getEnv("BCDD_FINTO_CONTA")
  if conta.len > 0:
    var c = 0
    if fileExists(conta):
      try: c = parseInt(readFile(conta).strip())
      except ValueError: c = 0
    n = c + 1
    writeFile(conta, $n & "\n")
  let suf = if n >= 2: "_2" else: ""
  let fPid = getEnv("BCDD_FINTO_PID" & suf)
  let fRichiesta = getEnv("BCDD_FINTO_RICHIESTA" & suf)
  let fTocca = getEnv("BCDD_FINTO_TOCCA" & suf)
  let fAttesa = getEnv("BCDD_FINTO_ATTESA" & suf)
  let fRisposta = getEnv("BCDD_FINTO_RISPOSTA" & suf)
  let fCodice = getEnv("BCDD_FINTO_CODICE" & suf)
  if fPid.len > 0: writeFile(fPid, $getCurrentProcessId() & "\n")
  let richiesta = leggiTutto()
  if fRichiesta.len > 0: writeFile(fRichiesta, richiesta)
  if fTocca.len > 0:
    let f = open(fTocca, fmAppend)
    f.write "-- riga aggiunta da un altro programma durante il giro\n"
    f.close()
  if fAttesa.len > 0: sleep(parseInt(fAttesa) * 1000)
  if fRisposta.len > 0:
    let r = readFile(fRisposta)
    discard stdout.writeBuffer(unsafeAddr r[0], r.len)
    stdout.flushFile()
  quit(if fCodice.len > 0: parseInt(fCodice) else: 0)

main()

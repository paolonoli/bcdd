# Package
version       = "0.9.0"
author        = "Noli Paolo"
description   = "bcdd 1.0-beta: command-line tool that checks and refines BCDD CSC files (new, check, refine, ratify)"
license       = "BSD-3-Clause"
srcDir        = "src"
bin           = @["bcdd"]

# Dependencies
requires "nim >= 2.0.0"
requires "checksums >= 0.2.0"

# 001:1:1 `nimble test`: compila il binario di rilascio, quello di prova e lancia la suite degli AC-1..AC-80.
# 001:1:2 L'eseguibile di prova (-d:bcddProva) è l'unico che legge BCDD_LLM per sostituire `claude`:
# 001:1:3 serve alle sole prove di `bcdd refine` e non si distribuisce. Il simbolo di compilazione è `bcddProva`.
# 001:2:1 nimble 0.22.2 (nimble.nim, `when isMainModule`) esce con 0 quando un task solleva un'eccezione: solo
# 001:2:2 `NimbleQuit` imposta il codice d'uscita e uno script .nimble non può sollevarla (`quit` ed `exec` fallito
# 001:2:3 finiscono in un errore catturato). Nimble 0.24.1 esce con 1. Per non dare un falso verde, se un passo fallisce
# 001:2:4 il task manda SIGTERM al processo `nimble` che lo esegue (uscita 143): un codice diverso da 0.
const terminaNimble = "p=$$; while [ -n \"$p\" ] && [ \"$(ps -o comm= -p $p | tr -d ' ')\" != nimble ]; do " &
  "p=$(ps -o ppid= -p $p | tr -d ' '); done; [ -n \"$p\" ] && kill -TERM $p"

# 003:1:1 con nimble 0.26 (quello di Nim 2.4.0) `gorgeEx` su una stringa costante è valutato dal compilatore mentre
# 003:1:2 legge il .nimble: nimble riceveva SIGTERM (143) già in `nimble build`, senza compilare. `exec` agisce solo a task eseguito.
proc passo(cmd: string) =
  ## 001:3:1 Esegue un passo; se fallisce lo dice e fa uscire nimble con un codice diverso da 0.
  try:
    exec cmd
  except OSError:
    echo "BcddTool.nimble: passo fallito: " & cmd
    try:
      exec terminaNimble
    except OSError:
      discard
    raise

task test, "compila bcdd e l'eseguibile di prova e lancia la suite dei criteri di accettazione":
  passo "nimble build -d:release"
  passo "nim c -d:release -d:bcddProva --hints:off --verbosity:0 --nimcache:nimcache/prova --out:tests/bcdd_prova src/bcdd.nim"
  passo "nim c -r --hints:off --verbosity:0 --out:tests/tbcdd tests/tbcdd.nim"

# 002:1:1 F4b: `bcdd-editor`, l'eseguibile a parte con la finestra. `nimble build` e `nimble test` non toccano `editor/`.
# 002:1:2 `nimble editor` compila bcdd-editor (release) accanto a bcdd e tests/bcdd-editor_prova (-d:bcddEditorProva), la sola
# 002:1:3 versione che legge BCDD_EDITOR_TRACCIA, BCDD_EDITOR_PROVA_CLIC e BCDD_EDITOR_SONDA_RETE.
task editor, "compila bcdd-editor accanto a bcdd e l'editor di prova":
  passo "nim c -d:release --hints:off --verbosity:0 --nimcache:nimcache/editor --out:bcdd-editor editor/bcddeditor.nim"
  passo "nim c -d:release -d:bcddEditorProva --hints:off --verbosity:0 --nimcache:nimcache/editorprova --out:tests/bcdd-editor_prova editor/bcddeditor.nim"

# 002:2:1 `nimble testeditor`: compila bcdd, bcdd_prova e i due editor e lancia tests/teditor (AC-184..AC-186, AC-196, AC-210..AC-214, con Xvfb).
# 002:2:2 Come per `test`, un passo fallito o una suite con un criterio non riuscito dà un codice d'uscita diverso da 0.
task testeditor, "compila tutto e lancia la suite dell'editor (AC-184..AC-214) sotto Xvfb":
  passo "nimble build -d:release"
  passo "nim c -d:release -d:bcddProva --hints:off --verbosity:0 --nimcache:nimcache/prova --out:tests/bcdd_prova src/bcdd.nim"
  passo "nimble editor"
  passo "nim c -r --hints:off --verbosity:0 --out:tests/teditor tests/teditor.nim"

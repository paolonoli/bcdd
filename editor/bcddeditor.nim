# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 006:1:1 bcdd-editor: l'eseguibile a parte con la finestra. Uso: bcdd-editor [--lang it|en] --dir CARTELLA [NOME].
# Uso sbagliato: messaggio sullo standard error e codice 2, prima di gtk_init (quindi anche senza display).
# 006:1:2 La lingua: `--lang` > scelta ricordata > BCDD_LANG > inglese, fissata prima di ogni messaggio; il messaggio di
# un `--lang` sbagliato esce nella lingua che varrebbe senza quell'opzione.
import std/os
import edtesti, edbcdd, edfinestra
when defined(windows):
  import edprocwin
  collegaConsolePadre()      # 006:1:3 eseguibile grafico: gli errori d'uso vanno alla console che l'ha lanciato, se c'è

let a = leggiArgomenti(commandLineParams())
let senzaOpzione = sceltaLingua("", leggiLinguaRicordata(), getEnv("BCDD_LANG"))
if a.linguaErrata:
  lingua = senzaOpzione
  stderr.writeLine tx(kLangNonValida, a.erroreLingua)
  quit(2)
if not a.ok:
  lingua = senzaOpzione
  stderr.writeLine usoEditor()
  quit(2)
lingua = sceltaLingua(a.lingua, if a.lingua.len > 0: "" else: leggiLinguaRicordata(), getEnv("BCDD_LANG"))
apriFinestra(a)
quit(0)

# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 006:1:1 bcdd-editor: l'eseguibile a parte con la finestra. Uso: bcdd-editor [--lang it|en] [--dir CARTELLA] [NOME].
# 006:1:4 senza `--dir` si apre la scelta della cartella del sistema (parte dall'ultima usata); annullare esce con 0, senza messaggi.
# Uso sbagliato: messaggio sullo standard error e codice 2, prima di gtk_init (quindi anche senza display).
# 006:1:2 La lingua: `--lang` > scelta ricordata > BCDD_LANG > lingua del sistema > inglese, fissata prima di ogni messaggio; il messaggio di
# un `--lang` sbagliato esce nella lingua che varrebbe senza quell'opzione.
import std/os
import edtesti, edbcdd, edfinestra, edfin
when defined(windows):
  import edprocwin
  collegaConsolePadre()      # 006:1:3 eseguibile grafico: gli errori d'uso vanno alla console che l'ha lanciato, se c'è

let a = leggiArgomenti(commandLineParams())
let senzaOpzione = sceltaLingua("", leggiLinguaRicordata(), getEnv("BCDD_LANG"), linguaSistema())
if a.linguaErrata:
  lingua = senzaOpzione
  segnalaErrore tx(kLangNonValida, a.erroreLingua) & "\n"
  quit(2)
if not a.ok:
  lingua = senzaOpzione
  segnalaErrore usoEditor() & "\n"
  quit(2)
lingua = sceltaLingua(a.lingua, if a.lingua.len > 0: "" else: leggiLinguaRicordata(), getEnv("BCDD_LANG"), linguaSistema())
var apri = a
if a.scegli:
  let (ok, cartella) = scegliCartella(tx(kScegliCartella), tx(kScegliAnnulla), tx(kScegliApri), leggiCartellaRicordata())
  if not ok:
    segnalaErrore tx(kEsciDisplay) & "\n"
    quit(2)
  if cartella.len == 0: quit(0)           # annullato: nessun messaggio
  apri.dir = cartella
if dirExists(apri.dir): discard ricordaCartella(apri.dir)     # l'ultima cartella; la lingua ha il suo file accanto
apriFinestra(apri)
quit(0)

# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 007:4:1 edfin: sceglie il livello di piattaforma. Stessa interfaccia, un solo livello per eseguibile.
when defined(windows):
  import edwebview2
  export edwebview2
else:
  import edgtkfin
  export edgtkfin

import std/strutils
import edtesti

proc segnalaErrore*(testo: string) =
  ## un errore d'avvio. Sullo standard error (con il fine riga di `testo`, se c'è) e, su Windows, anche in una finestra: un programma
  ## grafico lanciato da Esplora file non ha console. Prima lo standard error (una scrittura fallita è ignorata), poi la finestra:
  ## la finestra attende un clic e, senza desktop (servizio sshd), non si chiude; il testo su standard error c'è già.
  try:
    stderr.write testo
    stderr.flushFile
  except IOError: discard
  mostraErrore(tx(kTitoloErrore), testo.strip)

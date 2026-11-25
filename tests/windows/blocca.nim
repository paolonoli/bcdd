# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 001:1:1 Prova W-10: tiene aperto un file senza consentire la sostituzione né la cancellazione (solo lettura condivisa),
# 001:1:2 come farebbe un altro programma, finché non compare il file di sblocco o scade l'attesa. Solo Windows.
# 001:1:3 Uso: blocca FILE SBLOCCO [SECONDI]; scrive «bloccato» sullo standard output quando il file è tenuto.
import std/[os, strutils, winlean]
proc main() =
  let f = paramStr(1)
  let sblocco = paramStr(2)
  let sec = if paramCount() >= 3: parseInt(paramStr(3)) else: 30
  let h = createFileW(newWideCString(f), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0)
  if h == INVALID_HANDLE_VALUE:
    echo "non riesco ad aprire ", f
    quit(2)
  echo "bloccato"
  stdout.flushFile()
  for _ in 0 ..< sec * 10:
    if fileExists(sblocco): break
    sleep 100
  discard closeHandle(h)
main()

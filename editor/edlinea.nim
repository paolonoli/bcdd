# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 008:1:1 edlinea: le regole di Windows che servono all'editor e si provano anche su Linux. Puro: nessuna chiamata di sistema.
import std/[strutils, sequtils]

proc citaArgomento*(a: string): string =
  ## 008:1:2 Un argomento nella riga di comando di Windows, con le regole del lettore di `CommandLineToArgvW` e dell'ambiente C: niente virgolette se
  ## l'argomento non ha spazi, tabulazioni, a capo o virgolette; altrimenti fra virgolette, con le barre inverse prima di una virgoletta (o prima
  ## della virgoletta di chiusura) raddoppiate e la virgoletta preceduta da una barra inversa.
  if a.len > 0 and not a.anyIt(it in {' ', '\t', '\n', '\v', '"'}): return a
  result = "\""
  var barre = 0
  for c in a:
    if c == '\\':
      inc barre
    elif c == '"':
      result.add repeat('\\', barre * 2 + 1)
      result.add '"'
      barre = 0
    else:
      result.add repeat('\\', barre)
      result.add c
      barre = 0
  result.add repeat('\\', barre * 2)
  result.add '"'

proc lineaComando*(argv: seq[string]): string =
  ## 008:1:3 La riga di comando intera per `CreateProcessW`: gli argomenti uno per uno, separati da uno spazio.
  argv.mapIt(citaArgomento(it)).join(" ")

proc nomeDispositivoWindows*(nome: string): bool =
  ## 008:1:4 Su Windows `CON`, `PRN`, `AUX`, `NUL`, `COM1`…`COM9`, `LPT1`…`LPT9` (in qualunque combinazione di maiuscole e minuscole, con o senza
  ## estensione) indicano un dispositivo, non un file: `bcdd new` li rifiuta su ogni sistema e l'editor non li accetta
  ## come nome di file.
  var base = nome
  let p = base.find('.')
  if p >= 0: base = base[0 ..< p]
  base = base.strip(leading = false, chars = {' '}).toUpperAscii
  if base in ["CON", "PRN", "AUX", "NUL"]: return true
  base.len == 4 and (base.startsWith("COM") or base.startsWith("LPT")) and base[3] in {'1' .. '9'}

proc nomeFileAccettabile*(file: string): bool =
  ## 008:1:5 Un nome di file della cartella, senza percorso: né `/` né `\` né `:` (l'unità o un flusso alternativo di Windows) e non un nome
  ## di dispositivo. Vale su ogni sistema: la stessa cartella deve passare da Linux a Windows.
  file.len > 0 and not file.anyIt(it in {'/', '\\', ':'}) and not nomeDispositivoWindows(file)

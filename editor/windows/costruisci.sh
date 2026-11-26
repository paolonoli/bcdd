#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 010:3:1 Costruisce bcdd-editor.exe (e la versione di prova) con MSYS2 MinGW64, da questa cartella (BcddTool/). Non fa altro.
# Uso, dalla shell MSYS2 MinGW64:  bash editor/windows/costruisci.sh [--solo-rilascio]
# Prerequisiti: Nim 2.2.x, gcc/g++ di MinGW64, windres; il pacchetto Nim `checksums` già in ~/.nimble/pkgs2 (nimble non scarica sul PC).
set -e
cd "$(dirname "$0")/../.."
INC=editor/windows/include/WebView2.h
if [ ! -f "$INC" ]; then
  # l'intestazione di WebView2 (Microsoft.Web.WebView2 1.0.2739.15, licenza BSD-3 di Microsoft) non sta nel repository: si scarica una volta
  mkdir -p editor/windows/include editor/windows/nupkg
  curl -sL -o editor/windows/nupkg/webview2.zip https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2/1.0.2739.15
  unzip -o -q -j editor/windows/nupkg/webview2.zip build/native/include/WebView2.h -d editor/windows/include
fi
# la libreria `webview` (C++) e il gestore di WebView2: due oggetti in una libreria statica
W=editor/windows
mkdir -p $W/build
FL="-std=c++17 -O2 -w -DWEBVIEW_STATIC -I$W/include -I$W/webview/core/include"
g++ -c $FL $W/webview/core/src/webview.cc -o $W/build/webview.o
g++ -c $FL $W/edwv2.cc -o $W/build/edwv2.o
rm -f $W/build/libedwv.a
ar rcs $W/build/libedwv.a $W/build/webview.o $W/build/edwv2.o
CHK=$(ls -d ~/.nimble/pkgs2/checksums-* | head -1)
# l'icona e le informazioni di versione (risorsa PE)
windres editor/windows/edicona.rc --include-dir editor/windows -O coff -o editor/windows/edicona.res
mkdir -p nimcache
nim c -d:release --app:gui --dynlibOverrideAll --hints:off --verbosity:0 --path:"$CHK" --nimcache:nimcache/editorwin \
  --passL:"editor/windows/edicona.res" --out:bcdd-editor.exe editor/bcddeditor.nim
[ "$1" = "--solo-rilascio" ] || nim c -d:release -d:bcddEditorProva --app:gui --dynlibOverrideAll --hints:off --verbosity:0 --path:"$CHK" \
  --nimcache:nimcache/editorwinprova --passL:"editor/windows/edicona.res" --out:tests/bcdd-editor_prova.exe editor/bcddeditor.nim
# elenca solo i file che la modalità ha prodotto (set -e: un passo fallito esce prima con codice diverso da 0)
if [ "$1" = "--solo-rilascio" ]; then ls -l bcdd-editor.exe; else ls -l bcdd-editor.exe tests/bcdd-editor_prova.exe; fi

#!/usr/bin/env bash
# UConfrontoCartelle.sh - confronta byte per byte due cartelle di uscite (Linux e Windows)
# Execution mode: Unattended
# Description: ogni file deve esistere in entrambe ed essere identico, dopo le sole normalizzazioni ammesse da
#              `\` → `/` nei percorsi costruiti (opzione --barre), (il LLM finto si chiama ULlmFinto.exe su entrambe).
#              Verdetto compatto, dettaglio solo per i file diversi.
# Example call: ./UConfrontoCartelle.sh [--barre] out_linux out_windows
# Expected output: «file confrontati: N, diversi: M» ed elenco dei diversi; exit 0 se M = 0
set -u
norm() { cat; }
if [ "${1:-}" = "--barre" ]; then norm() { sed -e 's,\\,/,g'; }; shift; fi
A=$1; B=$2; n=0; d=0
for f in $(cd "$A" && ls); do
  n=$((n+1))
  if [ ! -e "$B/$f" ]; then echo "manca in $B: $f"; d=$((d+1)); continue; fi
  if ! cmp -s <(norm <"$A/$f") <(norm <"$B/$f"); then d=$((d+1)); echo "DIVERSO: $f"; fi
done
for f in $(cd "$B" && ls); do [ -e "$A/$f" ] || { echo "manca in $A: $f"; d=$((d+1)); }; done
echo "file confrontati: $n, diversi: $d"
[ $d -eq 0 ]

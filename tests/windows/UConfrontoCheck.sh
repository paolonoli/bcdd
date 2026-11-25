#!/usr/bin/env bash
# UConfrontoCheck.sh - raccoglie le uscite di `bcdd check` su una copia di prove/ (criterio W-1)
# Execution mode: Unattended
# Description: per ogni .csc sotto CARTELLA esegue check, check --strict, check --json con --lang it ed en;
#              salva stdout, stderr e codice d'uscita in OUT/. Lo stesso script gira su Linux e su Windows (MSYS2),
#              poi UConfrontoCheck.py confronta le due cartelle OUT.
# Example call: ./UConfrontoCheck.sh ./bcdd prove out_linux
# Expected output: una riga «raccolte: N esecuzioni»
set -u
BCDD=$(cd "$(dirname "$1")" && pwd)/$(basename "$1"); SRC=$2; OUT=$3
mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)
cd "$SRC" || exit 2
n=0
while IFS= read -r f; do
  for lang in it en; do
    for modo in "" "--strict" "--json"; do
      tag=$(echo "${f#./}" | tr '/' '_')_${lang}_${modo#--}
      "$BCDD" --lang $lang check $modo "${f#./}" >"$OUT/$tag.out" 2>"$OUT/$tag.err"
      echo $? >"$OUT/$tag.rc"
      n=$((n+1))
    done
  done
done < <(find . -name '*.csc' | LC_ALL=C sort)
echo "raccolte: $n esecuzioni"

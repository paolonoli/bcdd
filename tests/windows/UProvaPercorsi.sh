#!/usr/bin/env bash
# UProvaPercorsi.sh - nomi non ASCII, percorsi e nomi di dispositivo identici su Linux e su Windows (W-5, W-6, W-7, W-8)
# Execution mode: Unattended
# Description: esegue check su nomi con accenti e spazi, su percorsi relativi con `/` (e con `\` su Windows), sui casi di
#              prove/w397 (nome esatto, dispositivo). Le uscite sono in OUT; su Linux la forma con `\` è sostituita da quella con `/`,
#              così UConfrontoCartelle.sh --barre confronta le due cartelle.
# Example call: ./UProvaPercorsi.sh ./bcdd prove /tmp/lavoro out_linux
# Expected output: una riga «percorsi: N esecuzioni»
set -u
BCDD=$(cd "$(dirname "$1")" && pwd)/$(basename "$1"); PROVE=$(cd "$2" && pwd); W=$3; OUT=$4
rm -rf "$W" "$OUT"; mkdir -p "$W" "$OUT"; W=$(cd "$W" && pwd); OUT=$(cd "$OUT" && pwd); n=0
win=0; case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) win=1;; esac
r() { local nome=$1 dir=$2; shift 2
  ( cd "$dir" && "$BCDD" --lang it "$@" </dev/null >"$OUT/$nome.out" 2>"$OUT/$nome.err"; echo $? >"$OUT/$nome.rc" ); n=$((n+1)); }
bs() { if [ $win -eq 1 ]; then echo "$1" | tr '/' '\\'; else echo "$1"; fi; }   # forma con `\` solo su Windows
# W-5: nomi non ASCII
mkdir -p "$W/a/Città Uso"; cp "$PROVE/01_minima.csc" "$W/a/Città.csc"; cp "$PROVE/01_minima.csc" "$W/a/Città Uso/Perché è.csc"
r w5_nome "$W/a" check "Città.csc"
r w5_nome_spazi "$W/a" check "Città Uso/Perché è.csc"
r w5_dir "$W/a" check --dir "Città Uso" "Città.csc"
r w5_json "$W/a" check --json "Città.csc"
# W-6: cartella del file, con `/` e con `\`
cp -r "$PROVE/f3" "$W/copia"   # la copia di prove/f3: Uso.csc, Pulsante.csc, luce/...
r w6_barra "$W" check "copia/Uso.csc"
r w6_retro "$W" check "$(bs copia/Uso.csc)"
r w6_dir_retro "$W" check --dir "$(bs copia/luce)" "$(bs copia/Uso.csc)"
r w6_dir_barra "$W" check --dir copia/luce copia/Uso.csc
r w6_dir_fine "$W" check --dir "$(bs copia/luce/)" "copia/Uso.csc"
# W-7, W-8: nome esatto e dispositivo
cp -r "$PROVE/w397" "$W/w397"
r w7_maiuscole "$W/w397" check Maiuscole.csc
r w8_dispositivo "$W/w397" check Dispositivo.csc
r w8_dispositivo_json "$W/w397" check --json Dispositivo.csc
r w8_file_con "$W/w397" check CON
r w8_file_nul "$W/w397" check nul.csc
echo "percorsi: $n esecuzioni"

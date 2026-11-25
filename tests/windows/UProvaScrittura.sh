#!/usr/bin/env bash
# UProvaScrittura.sh - prove di scrittura di bcdd identiche su Linux e su Windows (criteri W-2, W-3, W-8, W-9)
# Execution mode: Unattended
# Description: esegue new, ratify, save su copie di prove/ in una cartella di lavoro nuova e mette in OUT i byte
#              dei file scritti e, per ogni comando, stdout, stderr e codice d'uscita. Si lancia su Linux e su Windows (MSYS2);
#              UConfrontoCartelle.sh confronta le due cartelle OUT.
# Example call: ./UProvaScrittura.sh ./bcdd prove /tmp/lavoro out_linux
# Expected output: una riga «scritte: N esecuzioni»
set -u
BCDD=$(cd "$(dirname "$1")" && pwd)/$(basename "$1"); PROVE=$(cd "$2" && pwd); W=$3; OUT=$4
rm -rf "$W" "$OUT"; mkdir -p "$W" "$OUT"; W=$(cd "$W" && pwd); OUT=$(cd "$OUT" && pwd)
n=0
# r NOME CARTELLA ARGOMENTI...: esegue bcdd in CARTELLA, salva stdout, stderr, codice (stdin = $IN se impostato)
r() { local nome=$1 dir=$2; shift 2
  if [ -n "${IN:-}" ]; then ( cd "$dir" && "$BCDD" --lang it "$@" <"$IN" >"$OUT/$nome.out" 2>"$OUT/$nome.err"; echo $? >"$OUT/$nome.rc" )
  else ( cd "$dir" && "$BCDD" --lang it "$@" </dev/null >"$OUT/$nome.out" 2>"$OUT/$nome.err"; echo $? >"$OUT/$nome.rc" ); fi
  n=$((n+1)); }
# new
mkdir "$W/n"; r new_Esempio "$W/n" new Esempio; cp "$W/n/Esempio.csc" "$OUT/new_Esempio.csc"
r new_Esempio_ancora "$W/n" new Esempio
i=0
for nome in CON PRN AUX NUL COM1 LPT9 con nul Con COM10 CONSOLE; do
  i=$((i+1))   # il numero evita che nomi diversi per sole maiuscole collidano nei file di uscita su Windows
  r new_${i}_$nome "$W/n" new $nome; ls "$W/n" | LC_ALL=C sort >"$OUT/new_${i}_$nome.ls"
done
# nome esatto: new luce quando c'è Luce.csc
mkdir "$W/e"; r new_Luce_maiuscolo "$W/e" new Luce; r new_luce_minuscolo "$W/e" new luce; ls "$W/e" | LC_ALL=C sort >"$OUT/new_luce_minuscolo.ls"
# ratify
mkdir "$W/rat"; cp "$PROVE/f2/ratify/"*.csc "$W/rat/"
r rat_R01_all "$W/rat" ratify R01_Luce.csc --all D-130
r rat_R03_g1 "$W/rat" ratify R03_righe.csc g1 D-130
r rat_R06_all "$W/rat" ratify R06_crlf.csc --all D-130
cp "$W/rat/R01_Luce.csc" "$OUT/rat_R01_all.csc"; cp "$W/rat/R03_righe.csc" "$OUT/rat_R03_g1.csc"; cp "$W/rat/R06_crlf.csc" "$OUT/rat_R06_all.csc"
r rat_R06_ancora "$W/rat" ratify R06_crlf.csc --all D-131
# save: file nuovo con CR LF, impronta, sostituzione di un file esistente, annulla
mkdir "$W/sv"
printf 'CSC Sv VERSION 1\r\nPURPOSE "uno"\r\nEND CSC\r\n' >"$W/sv.in1"
printf '\xef\xbb\xbfCSC Sv VERSION 1\r\nPURPOSE "due \xc3\xa8"\r\nEND CSC\r\n' >"$W/sv.in2"
IN="$W/sv.in1" r save_nuovo "$W/sv" save Sv.csc --expect nuovo; cp "$W/sv/Sv.csc" "$OUT/save_nuovo.csc"
imp=$(sed -n 's/.*"impronta": "\([^"]*\)".*/\1/p' "$OUT/save_nuovo.out")
IN="$W/sv.in2" r save_sostituisce "$W/sv" save Sv.csc --expect "$imp"; cp "$W/sv/Sv.csc" "$OUT/save_sostituisce.csc"
ls "$W/sv" | LC_ALL=C sort >"$OUT/save_sostituisce.ls"; [ -f "$W/sv/Sv.csc.prima" ] && cp "$W/sv/Sv.csc.prima" "$OUT/save_sostituisce.prima"
imp2=$(sed -n 's/.*"impronta": "\([^"]*\)".*/\1/p' "$OUT/save_sostituisce.out")
IN="$W/sv.in1" r save_impronta_vecchia "$W/sv" save Sv.csc --expect "$imp"
r save_undo "$W/sv" save Sv.csc --undo --expect "$imp2"; cp "$W/sv/Sv.csc" "$OUT/save_undo.csc"
ls "$W/sv" | LC_ALL=C sort >"$OUT/save_undo.ls"
echo "scritte: $n esecuzioni"

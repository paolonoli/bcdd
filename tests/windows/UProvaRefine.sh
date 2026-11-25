#!/usr/bin/env bash
# UProvaRefine.sh - refine con LLM finto identico su Linux e su Windows (criteri W-9 senza console, scadenza)
# Execution mode: Unattended
# Description: ripete la prova T01 (prove/f2/refine) e la scadenza con BCDD_ATTESA_LLM breve e il finto che dorme.
#              Salva in OUT i byte di Luce.csc, del dialogo, della richiesta e del registro (senza la data e la durata).
#              Il finto è un eseguibile, copiato come ULlmFinto.exe su Windows e ULlmFinto.sh non serve: su Linux
#              si usa llmfinto compilato da llmfinto.nim, in modo che le due uscite siano confrontabili.
# Example call: ./UProvaRefine.sh ./tests/bcdd_prova ./llmfinto prove /tmp/lavoro out_linux
# Expected output: una riga «refine: N esecuzioni»
set -u
BCDD=$(cd "$(dirname "$1")" && pwd)/$(basename "$1"); FINTO=$(cd "$(dirname "$2")" && pwd)/$(basename "$2"); PROVE=$(cd "$3" && pwd); W=$4; OUT=$5
rm -rf "$W" "$OUT"; mkdir -p "$W" "$OUT"; W=$(cd "$W" && pwd); OUT=$(cd "$OUT" && pwd)
RF="$PROVE/f2/refine"; n=0
amb() { # ambiente comune
  export BCDD_LLM="$FINTO" BCDD_ATTESA_LLM="${ATT:-30}" BCDD_ORA="2026-10-16T22:00:00+02:00"
  export BCDD_REGISTRO="$W/$1/chiamate.tsv" BCDD_FINTO_CONTA="$W/$1.aux/conta"; }
# T01
mkdir -p "$W/t01" "$W/t01.aux"; cp "$RF/Luce.csc" "$W/t01/"
( amb t01; export BCDD_FINTO_RISPOSTA="$RF/risposte/buona.json" BCDD_FINTO_RICHIESTA="$W/t01.aux/richiesta" \
    BCDD_FINTO_RICHIESTA_2="$W/t01.aux/richiesta2" BCDD_FINTO_RISPOSTA_2="$RF/risposte/buona_seconda.json"
  cd "$W/t01" && "$BCDD" --lang it refine Luce.csc <"$RF/T01_buona.ingresso" >"$OUT/t01.out" 2>"$OUT/t01.err"; echo $? >"$OUT/t01.rc" )
cp "$W/t01/Luce.csc" "$OUT/t01.Luce.csc"; cp "$W/t01/Luce.csc.dialogo" "$OUT/t01.dialogo"
cp "$W/t01.aux/richiesta" "$OUT/t01.richiesta"; cp "$W/t01.aux/richiesta2" "$OUT/t01.richiesta2"; cp "$W/t01.aux/conta" "$OUT/t01.conta"
ls "$W/t01" | LC_ALL=C sort >"$OUT/t01.ls"
# il registro: senza il campo della durata (colonna 4) e senza il nome del fornitore
cut -f1,3,5-8 "$W/t01/chiamate.tsv" >"$OUT/t01.registro"
n=$((n+1))
# scadenza: il finto dorme 5 s, il limite è 1 s
mkdir -p "$W/sc" "$W/sc.aux"; cp "$RF/Luce.csc" "$W/sc/"
( ATT=1; amb sc; export BCDD_FINTO_RISPOSTA="$RF/risposte/buona.json" BCDD_FINTO_ATTESA=5 BCDD_FINTO_PID="$W/sc.aux/pid"
  cd "$W/sc" && "$BCDD" --lang it refine Luce.csc </dev/null >"$OUT/sc.out" 2>"$OUT/sc.err"; echo $? >"$OUT/sc.rc" )
cmp -s "$W/sc/Luce.csc" "$RF/Luce.csc" && echo "uguale" >"$OUT/sc.luce" || echo "CAMBIATO" >"$OUT/sc.luce"
ls "$W/sc" | LC_ALL=C sort >"$OUT/sc.ls"; cut -f1,3,5-8 "$W/sc/chiamate.tsv" >"$OUT/sc.registro"
n=$((n+1))
echo "refine: $n esecuzioni"

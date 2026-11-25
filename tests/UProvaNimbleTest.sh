#!/usr/bin/env bash
# UProvaNimbleTest.sh - prova: `nimble test` deve uscire con codice diverso da 0 se la suite fallisce
# Execution mode: Unattended (compila due volte: alcuni minuti)
#
# Description: copia il pacchetto (src, tests, prove, csc, modelli, .nimble) in una cartella nuova di /tmp, vi lancia
#              `nimble test` con BCDD=/bin/false (tbcdd parte e si interrompe al primo uso del binario finto, uscita diversa da 0) e
#              confronta il codice d'uscita di nimble. L'albero sotto prova non si tocca: binari, nimcache e
#              tests/tbcdd nascono nella copia, che si cancella alla fine. Con un secondo argomento usa quel file
#              .nimble al posto di quello del pacchetto (per la prova di regressione sul .nimble di prima).
# Example call: tests/UProvaNimbleTest.sh                       (atteso: PASS, codice di nimble != 0)
#               git show b04820e1:BehaviouralDesign/BcddTool/BcddTool.nimble > /tmp/Vecchio.nimble
#               tests/UProvaNimbleTest.sh /tmp/Vecchio.nimble   (atteso: FAIL, codice 0)
# Expected output: una riga "PASS|FAIL: nimble test con suite fallita ha codice N"; exit 0 se PASS, 1 se FAIL.

# 001:1:1 Controlli d'avvio
set -u
if [ "$(id -u)" -eq 0 ]; then echo "UProvaNimbleTest.sh: non va lanciato come root" >&2; exit 2; fi
export PATH="$HOME/.nimble/bin:$PATH"
radice="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
nimblefile="${1:-$radice/BcddTool.nimble}"
[ -f "$nimblefile" ] || { echo "UProvaNimbleTest.sh: file non trovato: $nimblefile" >&2; exit 2; }
command -v nimble >/dev/null || { echo "UProvaNimbleTest.sh: nimble non trovato" >&2; exit 2; }

# 001:2:1 Copia nuova, mai l'albero reale
copia="$(mktemp -d /tmp/BcddNimbleTest_XXXXXX)"
log="/tmp/UProvaNimbleTest_$(date +%y%m%d%H%M%S).log"
trap 'rm -rf "$copia"' EXIT
mkdir "$copia/tests"
for d in src prove csc modelli; do [ -d "$radice/$d" ] && cp -r "$radice/$d" "$copia/"; done
cp "$radice/tests/tbcdd.nim" "$copia/tests/"
cp "$nimblefile" "$copia/BcddTool.nimble"

# 001:3:1 Suite fatta fallire: BCDD=/bin/false, nessun criterio può riuscire
( cd "$copia" && BCDD=/bin/false nimble test >"$log" 2>&1 )
codice=$?
grep -a "controlli:" "$log" | tail -1
if [ "$codice" -ne 0 ]; then
  echo "PASS: nimble test con suite fallita ha codice $codice (log: $log)"; exit 0
fi
echo "FAIL: nimble test con suite fallita ha codice 0 (log: $log)"; exit 1

#!/bin/sh
# 001:1:1 LLM finto per le prove di bcdd refine. Modalità Unattended.
# 001:1:2 Si comporta come l'interfaccia ModelloLinguistico: legge la richiesta sullo standard input,
# 001:1:3 scrive una risposta preparata sullo standard output. Tutto si sceglie con variabili d'ambiente:
# 001:1:4   BCDD_FINTO_PID        file in cui scrivere il proprio PID (per controllare che sia stato fermato)
# 001:1:5   BCDD_FINTO_RICHIESTA  file in cui copiare la richiesta ricevuta (per confrontarla con quella attesa)
# 001:1:6   BCDD_FINTO_TOCCA      file CSC a cui aggiungere una riga di commento (file cambiato durante il giro)
# 001:1:7   BCDD_FINTO_ATTESA     secondi da aspettare prima di rispondere (LLM lento)
# 001:1:8   BCDD_FINTO_RISPOSTA   file da restituire; se manca, nessuna risposta
# 001:1:9   BCDD_FINTO_CODICE     codice d'uscita (0 se manca)
# 001:2:1 Prima e seconda chiamata: BCDD_FINTO_CONTA è un file contatore. Se c'è, il finto lo legge
# 001:2:2 (0 se non esiste), aggiunge 1, lo riscrive e chiama n il risultato; se non c'è, n vale 1.
# 001:2:3 Con n = 1 usa le sei variabili sopra; con n >= 2 usa solo quelle con suffisso _2 (una _2 mancante = niente).
n=1
if [ -n "$BCDD_FINTO_CONTA" ]; then
  c=0
  if [ -f "$BCDD_FINTO_CONTA" ]; then read c < "$BCDD_FINTO_CONTA" || true; fi
  n=$(( ${c:-0} + 1 ))
  echo "$n" > "$BCDD_FINTO_CONTA"
fi
if [ "$n" -ge 2 ]; then
  f_pid=$BCDD_FINTO_PID_2; f_richiesta=$BCDD_FINTO_RICHIESTA_2; f_tocca=$BCDD_FINTO_TOCCA_2
  f_attesa=$BCDD_FINTO_ATTESA_2; f_risposta=$BCDD_FINTO_RISPOSTA_2; f_codice=$BCDD_FINTO_CODICE_2
else
  f_pid=$BCDD_FINTO_PID; f_richiesta=$BCDD_FINTO_RICHIESTA; f_tocca=$BCDD_FINTO_TOCCA
  f_attesa=$BCDD_FINTO_ATTESA; f_risposta=$BCDD_FINTO_RISPOSTA; f_codice=$BCDD_FINTO_CODICE
fi
if [ -n "$f_pid" ]; then echo $$ > "$f_pid"; fi
if [ -n "$f_richiesta" ]; then cat > "$f_richiesta"; else cat > /dev/null; fi
if [ -n "$f_tocca" ]; then echo "-- riga aggiunta da un altro programma durante il giro" >> "$f_tocca"; fi
if [ -n "$f_attesa" ]; then sleep "$f_attesa"; fi
if [ -n "$f_risposta" ]; then cat "$f_risposta"; fi
exit "${f_codice:-0}"

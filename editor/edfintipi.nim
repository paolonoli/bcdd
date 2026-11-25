# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 007:2:1 edfintipi: i tipi dell'interfaccia fra `edfinestra` e il livello di piattaforma. Il livello è uno solo per eseguibile:
# `edgtkfin` (GTK3 + WebKit2GTK 4.1, Linux) oppure `edwebview2` (WebView2, Windows); entrambi offrono le stesse procedure, le sole che
# `edfinestra` usa per la finestra, la vista web e i processi. Nessuna chiusura: gli ascoltatori sono procedure `nimcall` senza ambiente.
type
  RispostaJs* = proc(valore: string, haValore: bool, errore: string, dato: int) {.nimcall.}
    ## Come è finita una valutazione di JavaScript nella pagina: `valore` è il risultato in testo (se `haValore`), `errore` il messaggio
    ## se la pagina ha lanciato un'eccezione, `dato` il numero passato a `valuta`.
  FineProcesso* = proc(uscita, errori: string, codice: int, segnalato: bool) {.nimcall.}
    ## La fine del processo asincrono: standard output, standard error, codice d'uscita (255 se non è uscito da sé) e se è morto per un segnale.
  Gestori* = object
    ## Quello che la finestra vuole sapere dalla vista.
    messaggio*: proc(testo: string) {.nimcall.}     ## un messaggio della pagina, come JSON in testo
    attiva*: proc(attiva: bool) {.nimcall.}         ## la finestra è diventata attiva o inattiva
    caricata*: proc() {.nimcall.}                   ## la pagina è stata caricata (una volta)
    chiusa*: proc() {.nimcall.}                     ## la finestra è stata chiusa dalla persona
  Scheda* = object
    ## Come aprire la finestra.
    titolo*: string
    html*: string                                   ## la pagina, senza i programmi JavaScript
    script*: seq[string]                            ## i programmi JavaScript da eseguire a pagina costruita, in ordine
    dimensioniProva*: string                        ## solo la versione di prova: "LxA" (BCDD_EDITOR_PROVA_DIM), vuoto per quella di partenza

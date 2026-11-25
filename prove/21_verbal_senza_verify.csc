-- Prova 21, errore E13 (grammatica 1.2): una proprietà VERBAL senza VERIFY.
-- P4: ogni proprietà dice come si verifica. La riga è riconosciuta, il grado è verbale, ed è un errore.

CSC SenzaVerifica VERSION 0.1
  PURPOSE "Prova della verifica mancante"

  EVENT IN pressione

  GUARANTEE g1: VERBAL "Una pressione accende la luce"
  ASSUME    a1:
            VERBAL "Il pulsante non resta premuto
                    per più di un minuto"
  GUARANTEE g1a DETAILS g1: VERBAL "Il dettaglio vale come la riga che dettaglia"
  GUARANTEE g2: VERBAL "Questa ha la verifica: nessun errore" VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g3: VERBAL "Verifica scritta male: non riconosciuta, non E13"
                VERIFY BY MAGIC "nessuno"
  GUARANTEE g4: VERBAL "Qualcosa dopo la stringa che non è VERIFY: non riconosciuta" PERCHÉ

  SCENARIO s1 EXPECT ADMITTED
    @0 pressione   VERBAL "nei passi VERBAL non chiede VERIFY: nessun errore"
END

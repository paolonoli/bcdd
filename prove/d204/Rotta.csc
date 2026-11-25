-- Prova D-203, D-204 (grammatica 1.14): intestazione non valida (E09) seguita da STATUS RATIFIED BY.
-- Ogni riga è ipotesi (punto 0 della sezione 7.1), anche g2, che ha un suo STATUS RATIFIED BY.
CSC Rotta VERSIONE 0.1
  STATUS RATIFIED BY D-1
  PURPOSE "intestazione scritta male"
  GUARANTEE g1: VERBAL "senza STATUS: punto 4"
                VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g1a DETAILS g1: VERBAL "dettaglio senza STATUS: punto 3"
                VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g2 STATUS RATIFIED BY D-2: VERBAL "STATUS suo: punto 1"
                VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g3 STATUS HYPOTHESIS: VERBAL "STATUS suo: punto 2"
                VERIFY BY JUDGEMENT "l'operatore"
  ASSUME a1: VERBAL "condizione senza STATUS: punto 4"
             VERIFY BY JUDGEMENT "l'operatore"
END

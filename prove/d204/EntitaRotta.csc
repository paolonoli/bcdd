-- Prova D-206 (grammatica 1.15): un'entità con intestazione non valida (E09).
-- Ogni garanzia è ipotesi (punto 0 della sezione 7.1), anche g2, che ha un suo STATUS RATIFIED BY.
ENTITY Rotta VERSIONE 0.1
  STATUS RATIFIED BY D-1
  PURPOSE "entità con intestazione scritta male"
  GUARANTEE g1: VERBAL "senza STATUS"
                VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g2 STATUS RATIFIED BY D-2: VERBAL "STATUS suo"
                VERIFY BY JUDGEMENT "l'operatore"
END

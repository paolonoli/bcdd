-- Prova D-203, D-204 (grammatica 1.14): intestazione non valida (E09) con STATUS RATIFIED senza BY (E04).
-- g1 era già ipotesi; g2, con un suo STATUS RATIFIED BY, diventa ipotesi (punto 0).
CSC Rotta VERSIONE 0.1
  STATUS RATIFIED
  PURPOSE "intestazione scritta male, ratifica senza decisione"
  GUARANTEE g1: VERBAL "senza STATUS: punto 4"
                VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g2 STATUS RATIFIED BY D-2: VERBAL "STATUS suo: punto 1"
                VERIFY BY JUDGEMENT "l'operatore"
END

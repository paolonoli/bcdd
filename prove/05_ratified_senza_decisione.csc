-- Prova 05, errore E04: STATUS RATIFIED senza il riferimento a una decisione.
-- Nell'intestazione e su una riga; la terza forma (BY senza D-numero) è un errore anche lei.

CSC Ratifiche VERSION 0.1
  STATUS RATIFIED
  PURPOSE "Prova della ratifica senza decisione"

  GUARANTEE g1: VERBAL "ratificata bene" VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g2 STATUS RATIFIED: VERBAL "senza decisione" VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g3 STATUS RATIFIED BY operatore: VERBAL "decisione non nel formato D-numero"
               VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g4 STATUS RATIFIED BY D-7: VERBAL "questa sì" VERIFY BY JUDGEMENT "l'operatore"
END

-- Prova F2 di ratify: righe con e senza STATUS.

CSC Righe VERSION 0.1
  STATUS RATIFIED BY D-130
  PURPOSE "Prova della ratifica di una riga"

  GUARANTEE g1: VERBAL "senza STATUS" VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g1a DETAILS g1 STATUS RATIFIED BY D-130: VERBAL "dettaglio con STATUS"   -- commento che resta
                VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g3 : VERBAL "spazio prima dei due punti" VERIFY BY INSPECTION "il file"
  ASSUME a1 DETAILS g1 STATUS RATIFIED BY D-130: VERBAL "dettaglio senza STATUS"
            VERIFY BY JUDGEMENT "l'operatore"
END

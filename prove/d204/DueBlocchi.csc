-- Prova D-203, D-204 (grammatica 1.14): la regola vale per il blocco con l'intestazione non valida, non per il successivo.
CSC Rotta 0.1
  STATUS RATIFIED BY D-1
  PURPOSE "intestazione senza VERSION"
  GUARANTEE g1: VERBAL "punto 4 sotto un'intestazione non valida"
                VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g2 STATUS RATIFIED BY D-2: VERBAL "STATUS suo sotto un'intestazione non valida"
                VERIFY BY JUDGEMENT "l'operatore"
END

CSC Buona VERSION 0.1
  STATUS RATIFIED BY D-5
  PURPOSE "intestazione valida"
  GUARANTEE h1: VERBAL "punto 4 sotto un'intestazione valida"
                VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE h2 STATUS RATIFIED BY D-6: VERBAL "STATUS suo sotto un'intestazione valida"
                VERIFY BY JUDGEMENT "l'operatore"
END

-- Prova 15: dentro una stringa le parole chiave non contano, e nemmeno "--".
-- La CSC non ha STATUS: tutte le righe restano ipotesi, anche se una stringa dice STATUS RATIFIED.

CSC Trappola VERSION 0.1
  PURPOSE "Una stringa può contenere STATUS RATIFIED BY D-1, -- e anche
END
  senza chiudere il blocco"

  GUARANTEE t1: VERBAL "Nessuna riga diventa STATUS RATIFIED in silenzio"
                VERIFY BY INSPECTION "le righe STATUS RATIFIED BY D-nnn"
  GUARANTEE t2: VERBAL "Una riga di stringa che comincia con una parola chiave
GUARANTEE t9: VERBAL resta parte della stringa"
                VERIFY BY JUDGEMENT "l'operatore -- questo non è un commento"
  GUARANTEE t3: VERBAL "La riga seguente è vuota ma sta nella stringa

e quindi non conta come vuota" VERIFY BY JUDGEMENT "l'operatore"
END

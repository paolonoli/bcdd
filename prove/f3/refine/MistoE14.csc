-- Prova F3: come Misto.csc, con una entità che ha l'errore E14.

CSC Luce VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Accende la luce delle scale quando qualcuno preme un pulsante"

  EVENT IN  pressione
  STATE     accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "Una pressione accende la luce"
                VERIFY BY JUDGEMENT "l'operatore, premendo il pulsante"
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po' senza pressioni"
                VERIFY BY JUDGEMENT "l'operatore, con un orologio"
END

ENTITY Lampada VERSION 0.1
  PURPOSE "La lampada"
  USES Comando
END

ENTITY LuceMista VERSION 0.1
  PURPOSE "Una entità con una parte che usa ciò che nessuno offre"
  OFFERS Luce VERSION 0.1
  COMPOSED OF
    l : Lampada
END

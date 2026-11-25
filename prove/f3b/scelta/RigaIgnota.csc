-- Prova F3b: come EntitaPrima.csc, con una riga non riconosciuta nell'entità.

ENTITY LuceMista VERSION 0.1
  PURPOSE "Una entità che offre la luce"
  OFFERS Luce VERSION 0.1
  FOO bar
END

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

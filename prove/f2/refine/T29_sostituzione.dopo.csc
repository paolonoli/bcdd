-- Prova F2: la luce delle scale, file di partenza di bcdd refine.

CSC Luce VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Accende la luce delle scale quando qualcuno preme un pulsante"

  EVENT IN  pressione
  STATE     accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "Una pressione accende la luce"
                VERIFY BY JUDGEMENT "l'operatore, premendo il pulsante"
  GUARANTEE g1a DETAILS g1 STATUS HYPOTHESIS: VERBAL "La luce si accende entro mezzo secondo dalla pressione"
                                              VERIFY BY INSPECTION "il registro delle pressioni e dell'accensione"
  GUARANTEE g2: VERBAL "La luce si spegne da sola fra 170 e 190 secondi dopo l'ultima pressione"
                VERIFY BY JUDGEMENT "l'operatore, con un cronometro"
END

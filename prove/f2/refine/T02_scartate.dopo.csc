-- Prova F2: la luce delle scale, file di partenza di bcdd refine.

CSC Luce VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Accende la luce delle scale quando qualcuno preme un pulsante"

  EVENT IN  pressione
  STATE     accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "Una pressione accende la luce"
                VERIFY BY JUDGEMENT "l'operatore, premendo il pulsante"
  ASSUME a1 DETAILS g1 STATUS HYPOTHESIS: VERBAL "Il pulsante non resta premuto per più di un minuto"
                                          VERIFY BY INSPECTION "il registro delle pressioni"
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po' senza pressioni"
                VERIFY BY JUDGEMENT "l'operatore, con un orologio"
END

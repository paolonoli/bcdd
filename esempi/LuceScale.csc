-- Prova d'uso di bcdd refine su un caso vero (D-132): la luce delle scale, scritta volutamente vaga.

CSC LuceScale VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Accende la luce delle scale quando qualcuno preme un pulsante, e la spegne da sola"

  EVENT IN  pressione
  STATE     accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "Una pressione accende la luce"
                VERIFY BY JUDGEMENT "l'operatore, premendo il pulsante"
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "l'operatore, con un orologio"
  GUARANTEE g3: VERBAL "Chi è ancora sulle scale non resta al buio"
                VERIFY BY JUDGEMENT "l'operatore"
  ASSUME    a1: VERBAL "Il pulsante funziona"
                VERIFY BY JUDGEMENT "l'elettricista"
END

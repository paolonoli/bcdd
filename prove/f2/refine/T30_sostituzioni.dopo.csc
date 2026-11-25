-- Prova F2 1.5: quali righe si possono sostituire (D-140).

CSC Sostituzioni VERSION 0.1
  STATUS RATIFIED BY D-1
  PURPOSE "Accende la luce delle scale quando qualcuno preme un pulsante"

  EVENT IN  pressione
  STATE     accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "Una pressione accende la luce"
                VERIFY BY JUDGEMENT "l'operatore, premendo il pulsante"
  GUARANTEE g1a DETAILS g1 STATUS HYPOTHESIS: VERBAL "La luce si accende entro un secondo dalla pressione"
                                              VERIFY BY JUDGEMENT "l'operatore, con un cronometro"
  GUARANTEE g1a1 DETAILS g1a STATUS HYPOTHESIS: VERBAL "Subito vuol dire entro un secondo"
                                                VERIFY BY JUDGEMENT "l'operatore, con un cronometro"
  GUARANTEE g1b DETAILS g1 STATUS RATIFIED BY D-2: VERBAL "Una pressione a luce accesa non la spegne"
                                                   VERIFY BY JUDGEMENT "l'operatore, premendo a luce accesa"
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "l'operatore, con un orologio"
  GUARANTEE g2a DETAILS g2: VERBAL "La luce si spegne fra 55 e 65 secondi dopo l'ultima pressione"
                            VERIFY BY INSPECTION "il registro delle accensioni"
  GUARANTEE g2b DETAILS g2: ALWAYS accesa
END

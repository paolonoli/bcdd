-- Prova F2 1.4: al più due livelli di DETAILS sotto una riga base (D-138).

CSC Livelli VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Accende la luce delle scale quando qualcuno preme un pulsante"

  EVENT IN  pressione
  STATE     accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "Una pressione accende la luce"
                VERIFY BY JUDGEMENT "l'operatore, premendo il pulsante"
  GUARANTEE g1a DETAILS g1 STATUS HYPOTHESIS: VERBAL "La luce si accende entro un secondo"
                                              VERIFY BY JUDGEMENT "l'operatore, con un orologio"
  GUARANTEE g1a1 DETAILS g1a STATUS HYPOTHESIS: VERBAL "Il secondo si conta dalla pressione"
                                                VERIFY BY JUDGEMENT "l'operatore, con un cronometro"
  GUARANTEE g1a1a DETAILS g1a1 STATUS HYPOTHESIS: VERBAL "Anche quando il pulsante resta premuto"
                                                  VERIFY BY JUDGEMENT "l'operatore, con un cronometro"
  ASSUME    a1: VERBAL "Il pulsante funziona"
                VERIFY BY JUDGEMENT "l'elettricista"
END

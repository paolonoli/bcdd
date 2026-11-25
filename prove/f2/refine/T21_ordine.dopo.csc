-- Prova F2 1.3: dove si inseriscono le righe accettate (D-134 (a2)).

CSC Ordine VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Accende la luce delle scale quando qualcuno preme un pulsante"

  EVENT IN  pressione
  STATE     accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "Una pressione accende la luce"
                VERIFY BY JUDGEMENT "l'operatore, premendo il pulsante"
  GUARANTEE g1a DETAILS g1 STATUS HYPOTHESIS: VERBAL "La luce si accende entro un secondo"
                                              VERIFY BY JUDGEMENT "l'operatore, con un orologio"
  GUARANTEE g1b DETAILS g1a STATUS HYPOTHESIS: VERBAL "Anche quando la scala è al buio"
                                               VERIFY BY JUDGEMENT "l'operatore, di notte"
  GUARANTEE g1d DETAILS g1a STATUS HYPOTHESIS: VERBAL "Il secondo si conta dalla pressione"
                                               VERIFY BY JUDGEMENT "l'operatore, con un cronometro"
  GUARANTEE g1c DETAILS g1 STATUS HYPOTHESIS: VERBAL "Ogni pulsante accende la luce allo stesso modo"
                                              VERIFY BY JUDGEMENT "l'operatore, premendo ogni pulsante"
  GUARANTEE g1e DETAILS g1 STATUS HYPOTHESIS: VERBAL "Una pressione a luce accesa non la spegne"
                                              VERIFY BY JUDGEMENT "l'operatore, premendo a luce accesa"
  -- commento dopo i dettagli di g1

  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po' senza pressioni"
                VERIFY BY JUDGEMENT "l'operatore, con un orologio"
  GUARANTEE g2a DETAILS g2 STATUS HYPOTHESIS: VERBAL "La luce si spegne fra 170 e 190 secondi dopo l'ultima pressione"
                                              VERIFY BY JUDGEMENT "l'operatore, con un cronometro"
END

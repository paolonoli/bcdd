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
  -- commento dopo i dettagli di g1

  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po' senza pressioni"
                VERIFY BY JUDGEMENT "l'operatore, con un orologio"
END

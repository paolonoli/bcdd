-- La luce delle scale dopo tre giri di bcdd refine con sostituzioni (P-R8) e la ratifica per intero (D-142). Partenza: LuceScale.csc.

CSC LuceScale VERSION 0.1
  STATUS RATIFIED BY D-142
  PURPOSE "Accende la luce delle scale quando qualcuno preme un pulsante, e la spegne da sola"

  EVENT IN  pressione
  STATE     accesa : Boolean INITIAL false

  GUARANTEE g1: VERBAL "Una pressione accende la luce"
                VERIFY BY JUDGEMENT "l'operatore, premendo il pulsante"
  GUARANTEE g1a DETAILS g1 STATUS RATIFIED BY D-142: VERBAL "Tenere il pulsante premuto a lungo conta come una sola pressione, e il tempo di accensione si conta dall'istante in cui il pulsante viene premuto"
                                              VERIFY BY JUDGEMENT "l'operatore, che tiene premuto il pulsante per 10 s e misura con un cronometro che la luce si spegne del tutto 60 s ± 5 s dopo l'istante in cui l'ha premuto"
  GUARANTEE g1b DETAILS g1 STATUS RATIFIED BY D-142: VERBAL "Una pressione a luce spenta accende la luce a luminosità piena entro 1 s"
                                              VERIFY BY JUDGEMENT "l'operatore, che preme il pulsante a luce spenta e osserva quanto tempo passa prima che la luce si accenda"
  GUARANTEE g1c DETAILS g1 STATUS RATIFIED BY D-142: VERBAL "Una pressione su uno qualunque dei pulsanti dei piani ha sulla luce lo stesso effetto di una pressione su ogni altro pulsante"
                                              VERIFY BY JUDGEMENT "l'operatore, che preme a luce spenta il pulsante di ciascun piano e osserva che la luce si accende e si spegne allo stesso modo"
  GUARANTEE g2: VERBAL "La luce si spegne del tutto da sola 60 s ± 5 s dopo l'ultima pressione, compreso il tempo a luminosità ridotta che precede lo spegnimento"
                VERIFY BY JUDGEMENT "l'operatore, che misura con un cronometro il tempo fra l'ultima pressione e lo spegnimento completo della luce"
  GUARANTEE g3: VERBAL "Chi è ancora sulle scale non resta al buio"
                VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g3a DETAILS g3 STATUS RATIFIED BY D-142: VERBAL "Una pressione mentre la luce è accesa fa ripartire da capo il tempo di accensione, che termina 60 s ± 5 s dopo questa ultima pressione"
                                              VERIFY BY JUDGEMENT "l'operatore, che preme di nuovo il pulsante a luce accesa e misura con un cronometro il tempo fino allo spegnimento"
  GUARANTEE g3b DETAILS g3 STATUS RATIFIED BY D-142: VERBAL "Negli ultimi 10 s ± 2 s del tempo di accensione la luce resta accesa a circa metà della luminosità piena, e si spegne del tutto 60 s ± 5 s dopo l'ultima pressione"
                                              VERIFY BY JUDGEMENT "l'operatore, che dopo una pressione misura con un cronometro quando la luce passa a circa metà della luminosità e quando si spegne del tutto"
  GUARANTEE g3c DETAILS g3 STATUS RATIFIED BY D-142: VERBAL "Una pressione mentre la luce è a luminosità ridotta la riporta alla luminosità piena entro 1 s e fa ripartire da capo il tempo di accensione, che termina 60 s ± 5 s dopo questa pressione"
                                              VERIFY BY JUDGEMENT "l'operatore, che preme il pulsante durante la luce ridotta e misura con un cronometro il ritorno alla luminosità piena e lo spegnimento completo"
  ASSUME    a1: VERBAL "Su ogni piano delle scale c'è un pulsante che funziona"
                VERIFY BY JUDGEMENT "l'elettricista, che prova il pulsante di ciascun piano"
END

-- La luce delle scale, fatta di un pulsante e di una lampada.
-- Il connettore Comando fra le due parti è interno: da fuori non si vede.

ENTITY LuceScale VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale preme il pulsante e ha luce per salire o scendere"

  OFFERS Pressione
  OFFERS Luce
  USES   Alimentazione

  COMPOSED OF
    pulsante : Pulsante
    lampada  : Lampada

  GUARANTEE ls1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                 VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
  GUARANTEE ls2: VERBAL "La luce si spegne 90 s dopo l'ultima pressione, con una tolleranza di 5 s"
                 VERIFY BY JUDGEMENT "una persona che misura con un cronometro il tempo fra l'ultima pressione e lo spegnimento"
END

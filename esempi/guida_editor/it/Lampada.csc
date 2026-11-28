-- La lampada delle scale, una delle due parti della luce.
-- [REQ-2]: IMPIANTO.md#REQ-2

ENTITY Lampada VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La lampada si accende al comando e si spegne da sola"

  USES   Comando
  USES   Alimentazione
  OFFERS Luce

  GUARANTEE la1: VERBAL "Dopo un accendi la luce si accende entro 0,5 s"
                 VERIFY BY JUDGEMENT "una persona che osserva la lampada mentre si invia il comando"
  -- la2 viene dal requisito [REQ-2] dell'impianto.
  GUARANTEE la2: VERBAL "La luce si spegne 90 s dopo l'ultimo accendi, con una tolleranza di 5 s"
                 VERIFY BY JUDGEMENT "una persona con un cronometro"
END

ENTITY Lampada VERSION 0.1
  PURPOSE "La lampada delle scale"
  USES   Comando
  OFFERS Luce
  GUARANTEE la1: VERBAL "Dopo un accendi la luce è piena entro 0,5 s e si spegne del tutto 60 s dopo l'ultimo accendi"
                 VERIFY BY JUDGEMENT "l'operatore, con un cronometro"
END

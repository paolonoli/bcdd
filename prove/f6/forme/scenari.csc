CSC Ax VERSION 0.1
  PURPOSE "prima CSC"
  EVENT IN a
END
CSC Bx VERSION 0.1
  PURPOSE "seconda CSC"
  EVENT IN b
END
ENTITY Scenari VERSION 0.1
  PURPOSE "prova"
  OFFERS Ax
  SCENARIO comune EXPECT ADMITTED
    @0 s   Ax.a
    @1 s   Bx.b
  VARIANT modo = uno
    OFFERS Bx
    SCENARIO solo_uno EXPECT ADMITTED
      @0 s   Bx.b
  VARIANT modo = due
    GUARANTEE d1: VERBAL "una promessa"
      VERIFY BY JUDGEMENT "l'operatore"
END

ENTITY Uno VERSION 0.1
  PURPOSE "La prima"
  GUARANTEE u1: VERBAL "La prima promessa"
                VERIFY BY INSPECTION "il rapporto"
END

ENTITY Altra VERSION 0.1
  PURPOSE "La seconda"
  COMPOSED OF
    p : Uno
  GUARANTEE a1 STATUS RATIFIED BY D-1: VERBAL "La seconda promessa"
                VERIFY BY INSPECTION "il rapporto"
END

ENTITY Ratificata VERSION 0.1
  STATUS RATIFIED BY D-1
  PURPOSE "Un'entità con STATUS RATIFIED scritto a mano"
  GUARANTEE r1: VERBAL "La prima resta un'ipotesi"
                VERIFY BY INSPECTION "il rapporto"
  GUARANTEE r2 STATUS RATIFIED BY D-2: VERBAL "La seconda non si legge"
                VERIFY BY INSPECTION "il rapporto"
  GUARANTEE r3 STATUS RATIFIED: VERBAL "La terza non si legge"
                VERIFY BY INSPECTION "il rapporto"
END

ENTITY Ipotesi VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Un'entità con STATUS HYPOTHESIS"
  GUARANTEE h1 STATUS HYPOTHESIS: VERBAL "Questa è un'ipotesi"
                VERIFY BY INSPECTION "il rapporto"
END

CSC Luce VERSION 0.1
  IMPORT PROFILE Segnale VERSION 0.3
  PURPOSE "La luce delle scale"
  STATE accesa : Boolean INITIAL false
  STATE modo : Boolean INITIAL false
  STATE livello : Real INITIAL 0.0
  EVENT IN pressione
  EVENT OUT accendi
  DEFINE K := livello + 1.0
  DEFINE K2 DETAILS K := livello + 2.0
  GUARANTEE l1: WHENEVER pressione THEN accesa WITHIN 1 s
  GUARANTEE l2: ALWAYS (accesa AND
                        modo)
  GUARANTEE l3: VERBAL "La luce si vede"
                VERIFY BY JUDGEMENT "l'operatore, guardando"
  GUARANTEE l4: VERBAL "Tenere premuto conta una volta"
                VERIFY BY JUDGEMENT "l'operatore"
  SCENARIO s1 EXPECT ADMITTED
    @0 s     pressione
    REPEAT FOREVER EVERY 1 s
    @0.5 s   accendi
END
BINDING Luce VERSION 0.1 AS forme
  STATUS HYPOTHESIS
  BIND accesa: VERBAL "la plafoniera è piena"
END
VERIFICATION Luce VERSION 0.1
  MEANS telecamera OBSERVES accesa RESOLUTION 40 ms
END

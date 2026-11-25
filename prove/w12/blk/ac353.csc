CSC Luce VERSION 0.1
  PURPOSE "Luce"
  STATE accesa : Boolean INITIAL false
  STATE modo : Boolean INITIAL false
  GUARANTEE l1: ALWAYS accesa
  GUARANTEE l2: ALWAYS modo
  SCENARIO s1 EXPECT ADMITTED
END
VERIFICATION Luce VERSION 0.1
  MEANS telecamera OBSERVES accesa RESOLUTION 40 ms
  SCENARIO s1-sonda TRANSLATES s1
    @0 s     VERBAL "il dito preme il pulsante"
    @0.5 s   VERBAL "la plafoniera è accesa"
END

CSC Luce VERSION 0.1
  PURPOSE "Luce"
  STATE accesa : Boolean INITIAL false
  STATE modo : Boolean INITIAL false
  GUARANTEE l1: ALWAYS accesa
  GUARANTEE l2: ALWAYS modo
  SCENARIO s1 EXPECT ADMITTED
END
BINDING Luce VERSION 0.1
  STATUS HYPOTHESIS
  BIND accesa: VERBAL "la plafoniera emette luce piena"
END

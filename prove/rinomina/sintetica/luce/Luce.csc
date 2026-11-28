-- Luce: la plafoniera vista da chi la comanda (vedi LuceScale).
CSC Luce VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La Luce si accende e si spegne"
  STATE accesa : Boolean INITIAL false
  GUARANTEE la1: VERBAL "Una pressione accende la Luce"
                 VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE la1a DETAILS la1: VERBAL "Entro 1 s da una pressione"
                 VERIFY BY JUDGEMENT "l'operatore, con un cronometro"
  SCENARIO s1 GIVEN accesa = false EXPECT ADMITTED
    @0 s   accesa = true
END

BINDING Luce VERSION 0.1
  STATUS HYPOTHESIS
  BIND accesa: VERBAL "la plafoniera emette luce piena"
END

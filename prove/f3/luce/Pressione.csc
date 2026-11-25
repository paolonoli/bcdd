CSC Pressione VERSION 0.1
  PURPOSE "Il confine fra chi sta sulle scale e il pulsante"
  EVENT IN pressione
  GUARANTEE p1: VERBAL "Tenere premuto a lungo conta come una sola pressione"
                VERIFY BY JUDGEMENT "l'operatore, che tiene premuto 10 s"
  ASSUME    p-a1: VERBAL "Chi preme tiene premuto almeno 0,1 s"
                  VERIFY BY JUDGEMENT "l'operatore"
END

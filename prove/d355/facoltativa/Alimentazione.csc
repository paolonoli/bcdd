-- La rete elettrica del condominio, vista dall'impianto della luce.

CSC Alimentazione VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La rete elettrica del condominio fornisce la tensione all'impianto della luce delle scale"

  STATE      presente : Boolean INITIAL true

  GUARANTEE r1: VERBAL "La tensione è presente, salvo le interruzioni della rete"
                VERIFY BY INSPECTION "il registro delle interruzioni del condominio"
  ASSUME    r-a1: VERBAL "L'impianto della luce delle scale assorbe al più 100 W"
                  VERIFY BY INSPECTION "i dati di targa delle lampade installate"
END

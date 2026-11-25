ENTITY Modulo VERSION 0.1
  PURPOSE "Un modulo con la batteria o alimentato da fuori"
  OFFERS Uscita
  VARIANT tipo = batteria
    GUARANTEE m1: VERBAL "Con la batteria carica il modulo funziona 8 ore"
                  VERIFY BY JUDGEMENT "l'operatore"
  VARIANT tipo = alimentato
    USES Rete
    GUARANTEE m2: VERBAL "Con la rete presente il modulo funziona senza limite di tempo"
                  VERIFY BY JUDGEMENT "l'operatore"
END

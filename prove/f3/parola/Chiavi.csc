ENTITY Chiavi VERSION 0.1
  PURPOSE "Quali righe chiudono l'elenco delle parti"
  OFFERS Luce
  COMPOSED OF
    lampada : Lampada
    VERIFY BY INSPECTION "dopo una parte"
    VERBAL "dopo una parte"
    offers Luce
    OFFERS : Pulsante
    VERSION 0.1
    LINK a b
    END X
    -- un commento

    extra : "una stringa
END
che va a capo"
    pulsante : Pulsante
    OFFERS Pressione
    altro : Pulsante
END

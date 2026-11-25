ENTITY DueParole VERSION 0.1
  PURPOSE "Due parole prima dei due punti"
  COMPOSED OF
    pulsante uno : Pulsante
    lampada : Lampada
END

ENTITY SenzaDuePunti VERSION 0.1
  PURPOSE "Mancano i due punti"
  COMPOSED OF
    pulsante Pulsante
    lampada : Lampada
END

ENTITY Assegna VERSION 0.1
  PURPOSE "Il segno := non è il segno dei due punti"
  COMPOSED OF
    pulsante := Pulsante
    lampada : Lampada
END

ENTITY Stringa VERSION 0.1
  PURPOSE "Una stringa non è una parola"
  COMPOSED OF
    "pulsante" : Pulsante
    lampada : Lampada
END

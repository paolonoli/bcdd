-- Prova W-11: dentro un blocco non letto le stringhe valgono; un END dentro una stringa non chiude.
PROFILE Segnale VERSION 0.3
  EXTENSION FADE
    MEANING "una riga
END
             dentro la stringa"
  END
END
CSC Dopo VERSION 0.1
  PURPOSE "p"
END

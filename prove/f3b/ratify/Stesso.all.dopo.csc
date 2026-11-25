CSC Canale VERSION 0.3
  STATUS RATIFIED BY D-1
  PURPOSE "Un canale"
  EVENT OUT dato
END

ENTITY Nodo VERSION 0.1
  PURPOSE "Un nodo sul canale"
  OFFERS Canale VERSION 0.2
  GUARANTEE n1: VERBAL "Ogni dato arriva una volta sola"
                VERIFY BY INSPECTION "i dati registrati"
END

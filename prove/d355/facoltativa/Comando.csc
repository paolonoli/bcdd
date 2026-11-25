-- Il comando che il pulsante invia alla lampada.

CSC Comando VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il pulsante comanda alla lampada di accendersi"

  EVENT OUT  accendi

  GUARANTEE c1: VERBAL "Fra due accendi passano almeno 0,2 s"
                VERIFY BY INSPECTION "i comandi registrati"
END

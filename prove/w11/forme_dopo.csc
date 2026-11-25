-- Prova W-11: BINDING e VERIFICATION dopo la CSC (D-367, D-369, D-371).

CSC Comando VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il pulsante comanda alla lampada di accendersi"

  EVENT OUT  accendi

  GUARANTEE c1: VERBAL "Fra due accendi passano almeno 0,2 s"
                VERIFY BY INSPECTION "i comandi registrati"
END

BINDING Comando VERSION 0.1 filo   -- un elemento in più dopo la versione (D-371)
  -- forme concrete: la specifica non ne stabilisce ancora la scrittura
  riga inventata, che nessuno legge

END

VERIFICATION Comando VERSION 0.1
  EXTENSION Annidata
  END
END

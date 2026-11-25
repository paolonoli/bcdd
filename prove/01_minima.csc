-- Prova 01: la CSC minima della guida (luce delle scale, passo 1), con nomi accentati.
-- Attesa: nessun errore, due righe verbali, entrambe ipotesi (nessuno STATUS).

CSC LuceScale VERSION 1
  PURPOSE "Accende la luce delle scale quando qualcuno preme il pulsante
           e la spegne da sola dopo un po'"

  EVENT IN  pressione                 -- qualcuno preme il pulsante
  STATE     accesa : Boolean INITIAL false
  STATE     intensità : Real [0.0 .. 1.0] INITIAL 0.0

  GUARANTEE g1: VERBAL "Una pressione accende la luce"
                VERIFY BY JUDGEMENT "l'operatore, provando"
  GUARANTEE g2: VERBAL "La luce si spegne da sola circa tre minuti dopo l'ultima pressione"
                VERIFY BY JUDGEMENT "l'operatore, con un orologio"
END

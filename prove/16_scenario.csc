-- Prova 16: uno scenario completo, senza errori. Copre GIVEN, durate, eventi con e senza
-- argomenti, il ciclo di vita delle capacità, "_", asserzioni di stato e asserzioni a parole.

CSC LuceScale VERSION 2
  STATUS RATIFIED BY D-1
  PURPOSE "Luce delle scale con un conto alla rovescia"

  CAPABILITY Spegni
  CAPABILITY Diagnosi AUTONOMOUS
  EVENT IN   pressione(tasto: Integer [1..4])
  EVENT OUT  avviso(testo: String, livello: Integer)
  STATE      accesa : Boolean INITIAL false
  STATE      resto : Duration INITIAL 0 s
  DEFINE     DURATA := 180 s

  GUARANTEE g1: VERBAL "Una pressione accende la luce" VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g1a DETAILS g1 STATUS HYPOTHESIS:
                VERBAL "La luce è accesa nello stesso passo della pressione"
                VERIFY BY INSPECTION "la traccia"
  GUARANTEE g1b DETAILS g1 STATUS RATIFIED BY D-2: VERBAL "Il tasto premuto non conta"
                VERIFY BY JUDGEMENT "l'operatore"
  GUARANTEE g1c DETAILS g1: VERBAL "Un figlio senza STATUS resta un'ipotesi"
                VERIFY BY JUDGEMENT "l'operatore"
  ASSUME    a1: VERBAL "Il pulsante non resta premuto" VERIFY BY JUDGEMENT "l'installatore"

  SCENARIO duePressioni GIVEN accesa = false, resto = 0 s EXPECT ADMITTED
    @0 s     pressione(tasto: 1)           accesa = true
    @100 s   pressione(tasto: _)           accesa = true, resto = 180 s
    @250 s   accesa = true
    @280 s   accesa = false                VERBAL "la luce è spenta da poco"
  SCENARIO spentaAMano EXPECT REJECTED
    @0       requested(Spegni), accepted(Spegni), pressione
    @1       completed(Spegni), avviso(testo: "spenta", livello: 2)   accesa = true
    @1       accepted(Diagnosi)
END

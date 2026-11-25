-- La luce delle scale, vista da chi sta sulle scale e dal custode.

CSC Luce VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale vede la luce accesa per il tempo necessario a salire o scendere"

  TYPE       Modo := {spenta, accesa, in_pulizia}

  CAPABILITY Pulizie(durata: Duration)
  EVENT OUT  avviso
  STATE      modo : Modo INITIAL spenta

  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "una persona con un orologio"
  GUARANTEE g3: VERBAL "Poco prima di spegnersi, la luce dà un avviso a chi sta sulle scale"
                VERIFY BY JUDGEMENT "una persona sulle scale che attende lo spegnimento"
  GUARANTEE g4: VERBAL "Una richiesta di pulizie è rifiutata se la durata chiesta supera le due ore; altrimenti è accettata"
                VERIFY BY JUDGEMENT "il custode, che chiede le pulizie con durate diverse"
  GUARANTEE g5: VERBAL "Dopo una richiesta accettata la luce resta accesa per tutta la durata chiesta; allo scadere la richiesta è riuscita"
                VERIFY BY JUDGEMENT "il custode, con un orologio"
  GUARANTEE g6: VERBAL "Se la luce non può restare accesa fino allo scadere, la richiesta è fallita"
                VERIFY BY JUDGEMENT "il custode, che toglie la lampada durante le pulizie"

  SCENARIO s4 EXPECT ADMITTED
    @0 s     requested(Pulizie)   VERBAL "il custode chiede tre ore di pulizie"
    @0 s     rejected(Pulizie)
END

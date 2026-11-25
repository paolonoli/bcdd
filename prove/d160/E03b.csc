-- La luce delle scale, vista da chi sta sulle scale e dal custode.
-- VERSION 0.2: aggiunti gli scenari s1-s4. Da approvare.

CSC UsoLuce VERSION 0.2
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale preme un pulsante e ha luce per salire o scendere"

  TYPE       Modo := {spenta, accesa, in_pulizia}

  CAPABILITY Pulizie(durata: Duration)
  EVENT IN   premuto
  EVENT OUT  avviso
  STATE      modo : Modo INITIAL spenta

  GUARANTEE g1: VERBAL "Quando qualcuno preme il pulsante, la luce si accende"
                VERIFY BY JUDGEMENT "una persona che preme il pulsante e guarda"
  GUARANTEE g2: VERBAL "La luce si spegne da sola dopo un po'"
                VERIFY BY JUDGEMENT "una persona con un orologio"
  GUARANTEE g2a DETAILS g2 STATUS RATIFIED BY D-9: VERBAL "La luce si spegne 60 s dopo l'ultima pressione, con una tolleranza di 5 s"
                                              VERIFY BY JUDGEMENT "una persona che misura con un cronometro il tempo fra l'ultima pressione e lo spegnimento"
  GUARANTEE g2b DETAILS g2 STATUS RATIFIED BY D-9: VERBAL "Una pressione mentre la luce è accesa fa ripartire da capo il conteggio dei 60 s"
                                              VERIFY BY JUDGEMENT "una persona che preme di nuovo il pulsante a luce accesa e misura con un cronometro il tempo fino allo spegnimento"
  GUARANTEE g3: VERBAL "Poco prima di spegnersi, la luce dà un avviso a chi sta sulle scale"
                VERIFY BY JUDGEMENT "una persona sulle scale che attende lo spegnimento"
  GUARANTEE g4: VERBAL "Una richiesta di pulizie è rifiutata se la durata chiesta supera le due ore; altrimenti è accettata"
                VERIFY BY JUDGEMENT "il custode, che chiede le pulizie con durate diverse"
  GUARANTEE g5: VERBAL "Dopo una richiesta accettata la luce resta accesa per tutta la durata chiesta; allo scadere la richiesta è riuscita"
                VERIFY BY JUDGEMENT "il custode, con un orologio"
  GUARANTEE g6: VERBAL "Se la luce non può restare accesa fino allo scadere, la richiesta è fallita"
                VERIFY BY JUDGEMENT "il custode, che toglie la lampada durante le pulizie"
  GUARANTEE g7: VERBAL "Durante le pulizie il modo è in_pulizia, e una pressione del pulsante non lo cambia"
                VERIFY BY JUDGEMENT "il custode, che preme il pulsante durante le pulizie"
  ASSUME    a1: VERBAL "Chi preme il pulsante lo tiene premuto per almeno un decimo di secondo"
                VERIFY BY JUDGEMENT "una persona che osserva come viene premuto il pulsante"

  SCENARIO s1 EXPECT ADMITTED
    @0 s     premuto    modo = accesa
    @55 s    avviso
    @60 s    modo = spenta
    @100 s   premuto    modo = accesa
  SCENARIO s2 EXPECT REJECTED
    @0 s     premuto    modo = accesa
    @30 s    modo = buia
  SCENARIO s3 GIVEN modo = in_pulizia EXPECT ADMITTED
    @0 s     premuto    modo = in_pulizia
  SCENARIO s4 EXPECT ADMITTED
    @0 s     requested(Pulizie)   VERBAL "il custode chiede tre ore di pulizie"
    @0 s     rejected(Pulizie)
END

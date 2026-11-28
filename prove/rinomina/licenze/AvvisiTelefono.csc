-- Che cosa l'app del telefono mostra a chi la usa sulla licenza. Lato del team telefono: non è un'interfaccia
-- fra due team, ma il confine del gruppo verso la persona.
-- Fonte: lettera sul modello (avviso sullo stato; custode e telecomando ben distinti).

CSC AvvisiTelefono VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il telefono dice a chi lo usa se è il custode o un telecomando, e come sta la licenza dell'impianto"
  GUARANTEE at1: VERBAL "Si vede sempre se il telefono è il custode dell'impianto o un telecomando"
                 VERIFY BY JUDGEMENT "l'operatore, con il telefono custode e con un secondo telefono"
  GUARANTEE at2: VERBAL "Con la licenza in scadenza o in bypass il telefono lo dice"
                 VERIFY BY JUDGEMENT "l'operatore, con una licenza vicina alla scadenza"
END

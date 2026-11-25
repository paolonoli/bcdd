-- I cursori della pagina «Controlli creativi», il salvataggio della configurazione, i controlli non salvati.
-- Fonte: contratto 1.13, §10.9, §10.11, §10.13 (RC-CT-29..35, RC-CT-37, RC-CT-45).

CSC ControlliCreativi VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il telefono muove i cursori della pagina creativa come a video, ne vede i valori, e chiede di salvare la configurazione caricata"
  EVENT IN  imposta(controllo: String, valore: Real)
  EVENT IN  salva
  EVENT OUT valori
  GUARANTEE cc1: VERBAL "Il telefono imposta il valore di uno dei 21 controlli della pagina creativa, uno alla volta, come muovere il cursore; un valore fuori intervallo o fuori passo si rifiuta e non viene mai tagliato o arrotondato in silenzio"
                 VERIFY BY JUDGEMENT "l'operatore, che manda un valore oltre il massimo e uno fra due passi"
  GUARANTEE cc2: VERBAL "I cursori si muovono dal telefono solo quando sono raggiungibili nella finestra, cioè nella vista creativa e con i pulsanti premibili; il telefono sa sempre se lo sono e perché"
                 VERIFY BY JUDGEMENT "l'operatore, che prova a muovere un cursore nella vista correzioni"
  GUARANTEE cc3: VERBAL "A ogni cambio di un valore, da qualunque parte arrivi, tutti i telefoni ricevono i valori di tutti i controlli"
                 VERIFY BY JUDGEMENT "l'operatore, che muove un cursore col mouse e guarda i telefoni"
  GUARANTEE cc4: VERBAL "Il telefono chiede di salvare i controlli nella configurazione caricata, come il pulsante della finestra; se nessuna è caricata, se il salvataggio fallisce o se c'è una taratura, una misura o una finestra modale, si rifiuta dicendo il perché"
                 VERIFY BY JUDGEMENT "l'operatore, che salva dal telefono senza configurazione caricata"
  GUARANTEE cc5: VERBAL "Il telefono sa quali controlli sono diversi dalla configurazione caricata"
                 VERIFY BY JUDGEMENT "l'operatore, che cambia un controllo e guarda il segno sul telefono"
END

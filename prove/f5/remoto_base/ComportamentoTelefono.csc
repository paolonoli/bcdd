-- Che cosa promette il telefono al computer: gli obblighi del client del contratto 1.13.
-- Per SPECIFICA_02 §3.3.5 un obbligo della controparte è un'ASSUME solo se una garanzia ne dipende;
-- altrimenti è una garanzia di una CSC offerta da quella parte. Gli obblighi da cui dipende
-- l'accettazione della lettura restano ASSUME di Taratura (ta-a1, ta-a2).
-- Fonte: contratto 1.13, RC-DI-7, RC-DI-9, RC-SE-5, RC-LC-2, RC-LC-3, RC-LC-6, RC-SM-1, RC-CT-21,
-- RC-CT-34, RC-CT-43, RC-CT-52, RC-CT-59, RC-CT-66, RC-CT-72.

CSC ComportamentoTelefono VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Come si comporta il telefono verso il computer: quando cerca, quando si fa sentire, quando manda un comando e che cosa mostra"
  GUARANTEE te1: VERBAL "Il telefono raccoglie le risposte alla ricerca per un po' e ripete la domanda, perché qualcuna si può perdere; poi mostra ogni computer una volta sola"
                 VERIFY BY INSPECTION "il registro del telefono durante una ricerca"
  GUARANTEE te2: VERBAL "Se la ricerca non trova niente, l'utente può sempre scrivere a mano l'indirizzo del computer"
                 VERIFY BY JUDGEMENT "l'operatore, sul telefono, con la ricerca bloccata"
  GUARANTEE te3: VERBAL "Il telefono accetta il codice come l'utente lo scrive, con le maiuscole o le minuscole e con le lettere che si confondono, e lo usa nella forma che il computer mostra"
                 VERIFY BY JUDGEMENT "l'operatore, che scrive il codice in minuscolo sul telefono"
  GUARANTEE te4: VERBAL "Il telefono si fa sentire almeno ogni 10 s, e chiude da sé se dal computer non arriva più niente per 30 s dopo che si è fatto sentire"
                 VERIFY BY INSPECTION "il registro del telefono, a schermo fermo e con il computer staccato"
  GUARANTEE te5: VERBAL "Se la risposta a una lettura non arriva, il telefono non la rimanda alla cieca: prima chiede lo stato, e la rimanda solo se la taratura aspetta ancora"
                 VERIFY BY INSPECTION "il registro del telefono, togliendo la risposta a una consegna"
  GUARANTEE te6: VERBAL "Il telefono manda campioni del flusso solo dopo una richiesta del computer e dopo aver aperto il flusso, uno al secondo e in ordine, così che il computer riconosca quelli mancanti"
                 VERIFY BY INSPECTION "il registro del telefono senza nessuna richiesta del computer"
  GUARANTEE te7: VERBAL "Il telefono usa una funzione solo se il computer ha dichiarato una versione che la contiene, e dichiara una versione solo se la realizza per intero"
                 VERIFY BY INSPECTION "le funzioni attive sul telefono con un computer di versione più vecchia"
  GUARANTEE te8: VERBAL "Il telefono manda un comando solo per un gesto esplicito dell'utente, mai da solo, nemmeno per rimettere dopo una riconnessione ciò che aveva chiesto prima; ha al più un comando in attesa di risposta, e se la risposta non arriva non resta bloccato"
                 VERIFY BY INSPECTION "il registro del telefono dopo una riconnessione e con una risposta tolta"
  GUARANTEE te9: VERBAL "Il telefono decide sull'ultimo stato ricevuto: attiva un pulsante, un cursore o una procedura solo quando la finestra li permetterebbe (il MUTE sempre), e fino al primo stato non comanda niente"
                 VERIFY BY JUDGEMENT "l'operatore, che guarda il telefono mentre la finestra cambia"
  GUARANTEE te10: VERBAL "Il telefono mostra lo stato che arriva dal computer, non quello che ha chiesto; un rifiuto non cambia ciò che mostra e non viene ripetuto da solo; un valore che non capisce lo mostra come sconosciuto"
                  VERIFY BY JUDGEMENT "l'operatore, che guarda il telefono mentre un altro telefono comanda"
  GUARANTEE te11: VERBAL "Fra due stati della corsa del volume il telefono la anima da sé, senza chiedere niente al computer"
                  VERIFY BY JUDGEMENT "l'operatore, che guarda il cursore del telefono durante una corsa"
END

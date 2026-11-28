-- Che cosa l'applicazione mostra sulla licenza a chi sta davanti all'impianto. Lato del team applicazione:
-- non è un'interfaccia fra due team, ma il confine del gruppo verso la persona, come AvvisiTelefono.
-- Fonte: risposta del team applicazione alle domande sull'impianto,
-- decisioni di principio dell'operatore: il codice della licenza nell'applicazione non c'è ancora.
-- Il token del servizio remoto leggibile anche senza schermo si decide con l'API di licenza.
-- 0.2: rimando al catalogo unico dei testi del contratto del servizio, di cui è
-- responsabile il team licenze; la libreria lo espone all'applicazione (ApiLicenza
-- c8-6). Versione del contratto citata: bozza, non congelata, allineata
-- al protocollo di controllo remoto ratificato, che contiene anche le voci usate dall'API di licenza.
-- (nota di versione: nessun altro cambiamento).

CSC AvvisiImpianto VERSION 0.2
  STATUS RATIFIED BY D-390
  PURPOSE "L'applicazione dice a chi sta davanti all'impianto come sta la licenza e perché una funzione non è abilitata"
  GUARANTEE ai1: VERBAL "Con uno schermo (PC, oppure Raspberry Pi con monitor) l'applicazione mostra una riga di stato della licenza e, quando serve, un avviso con il motivo; riga e avviso sono voci del catalogo di C9 §14 date dalla libreria (C8-OP-5, C8-CA-2, C8-CA-4)"
                 VERIFY BY JUDGEMENT "l'operatore, sul PC con una licenza in scadenza"
  GUARANTEE ai2: VERBAL "I testi dell'avviso e dei motivi sono quelli del catalogo unico di C9 §14, che la libreria espone: l'applicazione li mostra e non li riscrive, compreso l'avviso licenza in verifica (AV-32, AV-33) quando la libreria non è disponibile (C8-CA-4, C8-CA-7)"
                 VERIFY BY INSPECTION "i testi a schermo confrontati con quelli restituiti dalla libreria e con C9 §14 (C8-AC-13)"
  GUARANTEE ai3: VERBAL "Senza schermo (Raspberry Pi usato solo come DSP) lo stato della licenza arriva al telefono attraverso il controllo remoto"
                 VERIFY BY JUDGEMENT "l'operatore, con un Raspberry Pi senza monitor e il telefono"
  GUARANTEE ai4: VERBAL "Una funzione non abilitata resta visibile ma disattivata, con accanto il motivo preso dalla voce del catalogo che dà la libreria; il suo stadio audio è escluso e la musica non si interrompe (C8-OP-6, C8-FN-3)"
                 VERIFY BY JUDGEMENT "l'operatore, con una licenza senza una delle funzioni"
  GUARANTEE ai5: VERBAL "Se la libreria rifiuta un documento, l'applicazione tiene lo stato di licenza valido precedente, mostra il motivo del rifiuto con la voce del catalogo data dalla libreria (AV-40..AV-50) e lo scrive nel log (C8-CA-3)"
                 VERIFY BY INSPECTION "il log dell'applicazione dopo la consegna di un documento rifiutato"
END

-- L'API della libreria di licenza verso l'applicazione.
-- Redattore: il team dei contratti. Il lato libreria è del team licenze, il lato applicazione del team applicazione.
-- Confine interno all'impianto, ma fra due team.
-- Fonte: contratto dell'API di licenza, versione 1.0, e intestazione della libreria. Fra parentesi, nelle righe
-- qui sotto, le clausole del contratto che danno il dettaglio.
-- Alto livello: solo che cosa si promette sul confine. Firme, tipi e formati stanno nel contratto.
-- 0.2: allineata alla versione 1.0 del contratto. L'esito di una consegna ha tre valori, non due:
-- la 0.1 non distingueva il rifiuto dalla libreria non disponibile.
-- «Stato per l'elaborazione»: lo stato che decide l'audio, fissato all'avvio e solo migliorato.
-- «Letture per l'elaborazione»: stato per l'elaborazione, funzione abilitata e nomi dei valori.

CSC ApiLicenza VERSION 0.2
  STATUS RATIFIED BY D-390
  PURPOSE "L'applicazione chiede alla libreria se e come può funzionare, le passa i documenti di licenza arrivati dal telefono e le fa fare la manutenzione periodica"
  TYPE DocumentoLicenza := VERBAL "un documento di licenza firmato dal servizio; il contenuto è del team licenze e per l'applicazione è opaco"
  TYPE EsitoConsegna := {confermato, rifiutato, non_disponibile}
  EVENT IN  consegna(documento: DocumentoLicenza)
  EVENT OUT esito(risultato: EsitoConsegna)
  GUARANTEE c8-1: VERBAL "L'applicazione può sempre leggere dalla libreria lo stato attuale della licenza, lo stato per l'elaborazione e le funzioni abilitate, anche durante una consegna o una manutenzione, senza aspettarle (C8-OP-2, C8-OP-5, C8-OP-6, C8-OP-11, C8-CC-2, C8-CC-3)"
                  VERIFY BY INSPECTION "la prova del team licenze con una scrittura trattenuta e letture da un altro thread (C8-AC-7)"
  GUARANTEE c8-2: VERBAL "Le letture per l'elaborazione si possono fare dal thread audio: non aspettano, non allocano memoria, non fanno chiamate di sistema e durano al più un tempo fisso (C8-CC-1)"
                  VERIFY BY INSPECTION "la misura del team licenze sulle due piattaforme (C8-AC-16)"
  GUARANTEE c8-3: VERBAL "Durante l'esercizio lo stato per l'elaborazione non peggiora: una scadenza, una revoca o una licenza con meno funzioni toccano l'audio solo al riavvio, un'attivazione subito; intanto lo stato attuale e la vista dicono subito il cambiamento e l'effetto che avrà il riavvio (C8-OP-0, C8-OP-11, D-344)"
                  VERIFY BY INSPECTION "le prove del team licenze con l'orologio simulato (C8-AC-15, C8-AC-19, C8-AC-20)"
  GUARANTEE c8-4: VERBAL "Ogni documento consegnato riceve esattamente un esito: confermato, rifiutato o libreria non disponibile; ogni parte scartata porta il suo codice di rifiuto e, dopo un rifiuto, lo stato salvato non cambia (C8-OP-4, C8-ER-2)"
                  VERIFY BY INSPECTION "i casi di consegna del team licenze (C8-AC-9)"
  GUARANTEE c8-5: VERBAL "La libreria risponde non disponibile solo se non è inizializzata, se l'inizializzazione è fallita o, per la sola richiesta pendente, se non legge nessun fattore d'impronta; e nessuna lettura risponde disponibile prima che lo stato per l'elaborazione sia pubblicato (C8-ER-1, C8-CC-5)"
                  VERIFY BY INSPECTION "le prove del team licenze prima dell'inizializzazione, dopo un fallimento e in ogni stato (C8-AC-11)"
  GUARANTEE c8-6: VERBAL "I testi per la persona che la libreria espone, stati, motivi e rifiuti, sono le voci del catalogo unico di C9 §14, con il loro identificativo AV-nn, nella forma per l'impianto (C8-CA-1..C8-CA-7)"
                  VERIFY BY INSPECTION "il confronto delle stringhe esposte con C9 §14 (C8-AC-10)"
  GUARANTEE c8-7: VERBAL "La libreria non chiama l'applicazione e non crea thread: scrive solo dentro l'inizializzazione, la consegna e la manutenzione, che l'applicazione chiama (C8-OP-9)"
                  VERIFY BY INSPECTION "il codice della libreria"
  ASSUME    c8-a1: VERBAL "L'applicazione passa i documenti così come le arrivano dal telefono, senza leggerli né cambiarli (C8-OP-4 punto 1)"
                   VERIFY BY INSPECTION "il codice dell'applicazione che riceve i documenti dal telefono"
  ASSUME    c8-a2: VERBAL "L'applicazione abilita gli stadi soggetti a licenza solo dopo una lettura per l'elaborazione che risponde disponibile; prima si comporta come in bypass, e non tiene copie proprie dello stato (C8-ER-1 punto 2, C8-OP-0 punto 1)"
                   VERIFY BY INSPECTION "la prova d'integrazione dell'ordine di avvio dell'applicazione (C8-AC-21)"
  ASSUME    c8-a3: VERBAL "L'applicazione chiama la manutenzione periodica almeno ogni 60 secondi finché il processo è attivo, mai dal thread audio (C8-OP-10 punto 2)"
                   VERIFY BY INSPECTION "il codice dell'applicazione e una prova di durata (C8-AC-18)"
  ASSUME    c8-a4: VERBAL "Dal thread audio l'applicazione chiama solo le letture per l'elaborazione; inizializzazione, consegna, manutenzione e le altre letture partono da altri thread (C8-CC-1, C8-CC-2, C8-OP-4 punto 9)"
                   VERIFY BY INSPECTION "il codice dell'applicazione (C8-AC-14)"
END

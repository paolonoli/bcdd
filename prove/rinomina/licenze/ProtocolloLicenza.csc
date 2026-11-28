-- Il protocollo fra la libreria di licenza e il servizio: attivazione e documenti firmati.
-- Redattore: team licenze (interfaccia con i due capi suoi). Il contenuto è suo e per gli altri è opaco.
-- Lo usano la libreria e, come corriere, l'app del telefono: l'impianto di norma non ha Internet.
-- Fonte: lettera sul funzionamento (fiducia, istante, rinnovo, attivazione, fine servizio);
-- lettera sul modello in breve.

CSC ProtocolloLicenza VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La libreria e il servizio si scambiano i documenti di licenza (fiducia, istante, rinnovo, attivazione, fine servizio), anche portati dal telefono"
  TYPE DocumentoLicenza := VERBAL "un documento di licenza; il formato lo fissa il team licenze nel contratto della fase 2"
  EVENT IN  richiesta(documento: DocumentoLicenza)
  EVENT OUT documento(documento: DocumentoLicenza)
  GUARANTEE pl1: VERBAL "I documenti per l'impianto (lease, istante firmato, certificati delle chiavi subordinate, elenco di revoca) li firma il servizio"
                 VERIFY BY INSPECTION "i documenti emessi dal servizio"
  GUARANTEE pl2: VERBAL "La firma del telefono custode sulla richiesta di rinnovo la verifica solo il servizio"
                 VERIFY BY INSPECTION "il contratto della fase 2 del team licenze"
  GUARANTEE pl3: VERBAL "Per il telefono che fa da corriere ogni documento è opaco: lo ritira e lo porta"
                 VERIFY BY INSPECTION "il contratto della fase 2: nessun campo che l'app debba leggere"
  ASSUME    pl-a1: VERBAL "Chi porta un documento lo consegna senza cambiarlo"
                   VERIFY BY INSPECTION "gli esiti di verifica dei documenti portati dal telefono"
END

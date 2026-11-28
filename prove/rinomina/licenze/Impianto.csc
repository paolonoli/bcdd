-- L'impianto (Raspberry Pi o PC): un gruppo annidato con due parti di due team diversi.
-- L'API di licenza (ApiLicenza) resta dentro: interna all'impianto, ma fra team applicazione e team licenze.
-- Di norma l'impianto non ha Internet: verso il servizio i documenti li porta il telefono (vedi TelefonoCustode).
-- Un'entità non può scrivere un ASSUME (E18): la frase sopra resta un commento.
ENTITY Impianto VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "L'impianto con l'applicazione e la libreria di licenza"
  OFFERS Sessione
  OFFERS TrasportoLicenza
  OFFERS AvvisiImpianto
  USES   ProtocolloLicenza
  COMPOSED OF
    applicazione : Applicazione
    libreria     : LibreriaLicenza
END

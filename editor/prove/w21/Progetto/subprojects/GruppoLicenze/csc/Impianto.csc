-- L'impianto: un gruppo annidato con due parti.
-- L'interfaccia verso il servizio resta dentro: interna all'impianto.
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

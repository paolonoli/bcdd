-- La parte computer: AudioProcessor, il programma che fa la taratura e ha i pulsanti.

ENTITY AudioProcessor VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il programma sul computer: si fa trovare dal telefono, tiene la taratura e i pulsanti della finestra, e dice al telefono come stanno"
  OFFERS Postazione
  OFFERS Scoperta
  OFFERS Abbinamento
  OFFERS Sessione
  OFFERS Taratura
  OFFERS Flusso
  OFFERS Pulsanti
  OFFERS ControlliCreativi
  OFFERS Volume
  OFFERS Procedure
  USES   ComportamentoTelefono
END

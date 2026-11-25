-- La parte telefono: l'app LevelMeter su Android.

ENTITY LevelMeter VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "L'app del telefono: misura il livello del suono, lo consegna al computer per la taratura e fa da telecomando per alcuni pulsanti della finestra"
  USES   Scoperta
  USES   Abbinamento
  USES   Sessione
  USES   Taratura
  USES   Flusso
  USES   Pulsanti
  USES   ControlliCreativi
  USES   Volume
  USES   Procedure
  OFFERS ComportamentoTelefono
  GUARANTEE sm1: VERBAL "Il riferimento per tarare il microfono del telefono è sempre uno strumento esterno, mai AudioProcessor stesso"
                 VERIFY BY INSPECTION "la provenienza della taratura mostrata dall'app"
END

-- Il telefono e il servizio licenze, solo per gli endpoint dell'app.
-- Redattore: team licenze, con revisione formale del team telefono.
-- Qui compare solo come connettore del gruppo; il testo vero sarà il loro.
-- Fonte: lettera sul servizio; politica dei lease nella lettera sul modello.
-- Fuori: le regole crittografiche (sfida, firma, verifica dell'attestazione), che restano del team licenze.

CSC RegistroTelefono VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "L'app del telefono ha un account sul servizio licenze, vi abbina il telefono come custode e vede le richieste del portale che aspettano la sua firma"
  GUARANTEE c9-1: VERBAL "Il telefono abbinato registra la sua chiave pubblica direttamente sul servizio, non attraverso l'impianto"
                  VERIFY BY INSPECTION "il registro degli abbinamenti del servizio"
  GUARANTEE c9-2: VERBAL "Un abbinamento si può fare, sostituire, approvare e annullare"
                  VERIFY BY JUDGEMENT "l'operatore, con un telefono di prova"
  GUARANTEE c9-3: VERBAL "Ogni telefono è accettato come custode, anche senza attestazione hardware; il servizio ne registra il livello di attestazione"
                  VERIFY BY INSPECTION "il registro degli abbinamenti, con un telefono senza attestazione hardware"
  GUARANTEE c9-4: VERBAL "Il telefono vede l'elenco delle richieste del portale che aspettano la sua firma"
                  VERIFY BY JUDGEMENT "l'operatore, che fa una richiesta sul portale e guarda il telefono"
  ASSUME    c9-a1: VERBAL "Reinstallare l'app o cambiare telefono vuol dire un nuovo abbinamento, fatto con l'account del cliente"
                   VERIFY BY JUDGEMENT "l'operatore, che reinstalla l'app"
END

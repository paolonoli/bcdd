-- Il telefono custode con l'app (team telefono). Solo il custode: i telecomandi sono fuori.
-- 0.2: esito_consegna di TrasportoLicenza 0.2 ha tre valori; lo scenario
-- usa confermato al posto di accettata: true. Nessun altro cambiamento.
ENTITY TelefonoCustode VERSION 0.2
  STATUS HYPOTHESIS
  PURPOSE "Il telefono custode: abbinato sul servizio, porta i documenti di licenza fra servizio e impianto e avvisa chi lo usa"
  USES   Sessione
  USES   TrasportoLicenza
  USES   RegistroTelefono
  USES   ProtocolloLicenza
  OFFERS AvvisiTelefono
  GUARANTEE tc1: VERBAL "Quando si collega al servizio il custode ritira tre lease consecutivi, e li consegna all'impianto uno alla volta"
                 VERIFY BY INSPECTION "i lease ritirati e consegnati registrati dall'app"
  -- Il tratto telefono del cammino. Lettura nostra di «consegnati uno alla volta» (domanda LM-3 in ESITO.md):
  -- un lease per ogni richiesta di rinnovo; la seconda richiesta non passa dal servizio.
  SCENARIO tc-s1 GIVEN Sessione.pronta = true EXPECT ADMITTED
    @0 s      TrasportoLicenza.richiesta_rinnovo(documento: "rinnovo1")
    @60 s     ProtocolloLicenza.richiesta(documento: "rinnovo1")
    @61 s     ProtocolloLicenza.documento(documento: "lease1")
    @61 s     ProtocolloLicenza.documento(documento: "lease2")
    @61 s     ProtocolloLicenza.documento(documento: "lease3")
    @120 s    TrasportoLicenza.consegna(documento: "lease1")
    @120 s    TrasportoLicenza.esito_consegna(risultato: confermato)
    @5000000 s TrasportoLicenza.richiesta_rinnovo(documento: "rinnovo2")
    @5000001 s TrasportoLicenza.consegna(documento: "lease2")
    @5000001 s TrasportoLicenza.esito_consegna(risultato: confermato)
END

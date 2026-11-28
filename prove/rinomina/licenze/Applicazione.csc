-- L'applicazione vista dal sistema di licenze.
-- Nome diverso da quello dell'applicazione in altri casi (un nome, una cosa): qui conta solo la licenza.
-- Sessione è la CSC della sessione di controllo remoto: citata, non copiata.
-- 0.2: lo scenario segue l'esito a tre valori di ApiLicenza 0.2.
-- 0.3: anche TrasportoLicenza 0.2 ha l'esito a tre valori; ap-l1 lo usa, ap-l2 copre la
-- libreria non disponibile, che il servizio riporta al telefono come non_disponibile.
ENTITY Applicazione VERSION 0.3
  STATUS HYPOTHESIS
  PURPOSE "L'applicazione sull'impianto: riceve dal telefono i documenti di licenza, li passa alla libreria e mostra lo stato della licenza"
  OFFERS Sessione
  OFFERS TrasportoLicenza
  OFFERS AvvisiImpianto
  USES   ApiLicenza
  -- Il tratto impianto del cammino di un documento: dal telefono alla libreria, e l'esito indietro.
  SCENARIO ap-l1 EXPECT ADMITTED
    @0 s   TrasportoLicenza.consegna(documento: "lease1")
    @0 s   ApiLicenza.consegna(documento: "lease1")
    @1 s   ApiLicenza.esito(risultato: confermato)
    @1 s   TrasportoLicenza.esito_consegna(risultato: confermato)
  -- Libreria non disponibile (non inizializzata o inizializzazione fallita, C8-ER-1): nulla è consegnato.
  SCENARIO ap-l2 EXPECT ADMITTED
    @0 s   TrasportoLicenza.consegna(documento: "lease1")
    @0 s   ApiLicenza.consegna(documento: "lease1")
    @1 s   ApiLicenza.esito(risultato: non_disponibile)
    @1 s   TrasportoLicenza.esito_consegna(risultato: non_disponibile)
END

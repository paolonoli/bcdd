-- Il trasporto dei documenti di licenza nel protocollo di controllo remoto, fra l'impianto e l'app del telefono.
-- Redattore: team contratti. Entrerà nel contratto del controllo remoto quando il team licenze
-- avrà consolidato il contratto della fase 2; qui è una CSC a sé perché il caso di partenza non lo ha.
-- Fonte: lettera del team licenze, parte A.
-- Il fattore telefono (parte B) non è interfaccia del protocollo: sta fra team licenze e team telefono.
-- 0.2: l'esito di consegna ha tre valori, come EsitoConsegna di ApiLicenza 0.2.
-- Sul filo del protocollo ratificato i tre valori sono distinti, con la
-- corrispondenza seguente: confermato = risposta finale ok:true con `confirm`, rifiutato = ok:true con
-- `refuse`, non_disponibile = ok:false con LIC_UNAVAILABLE.
-- Gli errori del trasporto (LIC_DIGEST, LIC_SEQUENCE, BAD_REQUEST: nulla arriva alla libreria)
-- non sono esiti di consegna e restano fuori da questa CSC, come nella 0.1.
-- Nota: LIC_UNAVAILABLE può rispondere anche a un
-- frammento intermedio, non solo alla consegna completa: il controllo del sottosistema precede quelli di sequenza
-- e d'impronta e non tocca la consegna in corso.
-- Riferimenti:
-- [C8-OP-4]: contratti/api_licenza.md#C8-OP-4
-- [C8-RC-3]: contratti/api_licenza.md#C8-RC-3
-- [RC-LI-6]: contratti/controllo_remoto.md#RC-LI-6
-- [RC-LI-7]: contratti/controllo_remoto.md#RC-LI-7
-- [RC-LI-8]: contratti/controllo_remoto.md#RC-LI-8
-- [RC-LI-9]: contratti/controllo_remoto.md#RC-LI-9

CSC TrasportoLicenza VERSION 0.2
  STATUS RATIFIED BY D-413
  PURPOSE "L'impianto chiede al telefono il rinnovo della licenza, il telefono gli consegna i documenti, e l'impianto gli dice come sta la licenza e se lui è il custode"
  TYPE DocumentoLicenza := VERBAL "un documento di licenza, richiesta di rinnovo compresa; per il protocollo è opaco"
  TYPE StatoLicenza := {valida, in_scadenza, in_bypass}
  TYPE EsitoConsegna := {confermato, rifiutato, non_disponibile}
  EVENT OUT richiesta_rinnovo(documento: DocumentoLicenza)
  EVENT IN  consegna(documento: DocumentoLicenza)
  EVENT OUT esito_consegna(risultato: EsitoConsegna)
  EVENT OUT stato_licenza(stato: StatoLicenza)
  EVENT OUT ruolo(custode: Boolean)
  GUARANTEE tl1: VERBAL "Il protocollo porta i documenti di licenza senza leggerli: ne vede solo il tipo e la lunghezza. Li firma il servizio e li verificano solo l'applicazione e il servizio"
                 VERIFY BY INSPECTION "il contratto controllo remoto: per un documento di licenza nessun campo oltre il tipo e la lunghezza"
  GUARANTEE tl2: VERBAL "Ogni consegna completa riceve esattamente un esito: confermato, rifiutato o libreria non disponibile"
                 VERIFY BY INSPECTION "le consegne e gli esiti registrati sul telefono"
  GUARANTEE tl3: VERBAL "Il telefono sa dall'impianto se è il custode di quell'impianto o solo un telecomando"
                 VERIFY BY JUDGEMENT "l'operatore, con il telefono custode e con un secondo telefono collegati"
  GUARANTEE tl4: VERBAL "Il telefono riceve lo stato della licenza (valida, in scadenza, in bypass), per poterlo mostrare"
                 VERIFY BY JUDGEMENT "l'operatore, con una licenza vicina alla scadenza"
  ASSUME    tl-a1: VERBAL "Il telefono e l'impianto hanno una sessione pronta del controllo remoto (CSC Sessione)"
                   VERIFY BY INSPECTION "lo stato della sessione al momento della richiesta"
END

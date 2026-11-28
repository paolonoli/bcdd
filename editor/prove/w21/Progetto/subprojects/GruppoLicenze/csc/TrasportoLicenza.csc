-- Il trasporto dei documenti di licenza nel protocollo, fra l'impianto e l'app del telefono.
-- 0.2: l'esito di consegna ha tre valori, come l'esito dell'interfaccia di licenza ([C8-OP-4] punto 2).
-- Sul filo del protocollo i tre valori sono distinti, con la corrispondenza di [C8-RC-3]:
-- confermato = risposta finale ok:true con `confirm`, rifiutato = ok:true con `refuse` ([RC-LI-6] punto 5,
-- [RC-LI-7] punto 1), non_disponibile = ok:false con LIC_UNAVAILABLE ([RC-LI-9] punto 3).
-- Gli errori del trasporto (LIC_DIGEST, LIC_SEQUENCE, BAD_REQUEST: nulla arriva alla libreria, [RC-LI-8] punto 6)
-- non sono esiti di consegna e restano fuori da questa CSC.
-- Nota: LIC_UNAVAILABLE può rispondere anche a un frammento intermedio, non solo alla consegna completa:
-- il controllo del sottosistema precede quelli di sequenza e d'impronta ([RC-LI-9], punti 3-5).
-- Riferimenti:
-- [C8-OP-4]: ../../../docs/contracts/api/API_CONTRACT_1.0.md#C8-OP-4
-- [C8-RC-3]: ../../../docs/contracts/api/API_CONTRACT_1.0.md#C8-RC-3
-- [RC-LI-6]: ../../../docs/contracts/protocollo/PROTOCOL_CONTRACT_1.2.md#RC-LI-6
-- [RC-LI-7]: ../../../docs/contracts/protocollo/PROTOCOL_CONTRACT_1.2.md#RC-LI-7
-- [RC-LI-8]: ../../../docs/contracts/protocollo/PROTOCOL_CONTRACT_1.2.md#RC-LI-8
-- [RC-LI-9]: ../../../docs/contracts/protocollo/PROTOCOL_CONTRACT_1.2.md#RC-LI-9

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
  GUARANTEE tl1: VERBAL "Il protocollo porta i documenti di licenza senza leggerli: ne vede solo il tipo e la lunghezza"
                 VERIFY BY INSPECTION "il contratto del protocollo: per un documento di licenza nessun campo oltre il tipo e la lunghezza"
  GUARANTEE tl2: VERBAL "Ogni consegna completa riceve esattamente un esito: confermato, rifiutato o libreria non disponibile"
                 VERIFY BY INSPECTION "le consegne e gli esiti registrati sul telefono"
  GUARANTEE tl3: VERBAL "Il telefono sa dall'impianto se è il custode di quell'impianto o solo un telecomando"
                 VERIFY BY JUDGEMENT "l'operatore, con il telefono custode e con un secondo telefono collegati"
  GUARANTEE tl4: VERBAL "Il telefono riceve lo stato della licenza (valida, in scadenza, in bypass), per poterlo mostrare"
                 VERIFY BY JUDGEMENT "l'operatore, con una licenza vicina alla scadenza"
  ASSUME    tl-a1: VERBAL "Il telefono e l'impianto hanno una sessione pronta del controllo remoto (CSC Sessione)"
                   VERIFY BY INSPECTION "lo stato della sessione al momento della richiesta"
END

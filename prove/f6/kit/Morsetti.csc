-- Il confine ai morsetti dei diffusori passivi: l'uscita di potenza dell'amplificatore, dove si collega la DI.
-- Diffusori attivi fuori dal primo esempio (A-01; operatore, D-336): vedi l'ESITO.
-- Amplificatori a ponte: mt-a1 (D-341, regola del tester da D-342). Che un'uscita a ponte escluda la parte DirectBox non si può scrivere
-- come condizione sull'amplificatore (lacuna L8 dell'ESITO): qui è un'assunzione.
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §1 R-AMP, R-SPK, §5 «Diffusori passivi»; Q-AK-2, Q-AK-4; v0.5 A-11 (AP-R3); v0.6 A-11 (AP-R4 §8).

CSC Morsetti VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Ai morsetti di un diffusore passivo c'è l'uscita di potenza dell'amplificatore, accessibile per la DI"
  GUARANTEE mt1 STATUS RATIFIED BY D-338: VERBAL "I diffusori sono passivi e i loro morsetti sono accessibili: la DI vi si collega con il cavo dai morsetti al suo ingresso jack (fonte: §1 R-SPK, §5; Q-AK-2, Q-AK-4)"
                 VERIFY BY INSPECTION "i morsetti dei diffusori dell'utente"
  ASSUME    mt-a1 STATUS RATIFIED BY D-342: VERBAL "L'uscita dell'amplificatore non è a ponte (BTL). Prima di collegare la DI, con l'amplificatore acceso e in riproduzione, si misura col tester in tensione alternata fra il morsetto nero (−) di un diffusore e la massa dell'amplificatore (telaio o schermo di un ingresso RCA): se la tensione è praticamente zero la DI si collega con GROUND su LIFT; se c'è tensione l'uscita è a ponte, niente DI, e il sensore di livello è il microfono. Non dipende dal modello dell'amplificatore (fonte: AP-R4 §8, regola decisa dall'operatore, MODELLO_SISTEMA_FATTI v0.6 A-11, AudioKits D-34)"
                   VERIFY BY INSPECTION "la prova del tester sul morsetto nero, ad amplificatore acceso e in riproduzione"
END

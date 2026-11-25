-- Il volume visto dal telefono: livello stimato, livello voluto, richiamo, corsa, livello mantenuto.
-- Fonte: contratto 1.13, §10.8, §10.12, §10.16, §10.17 (RC-CT-25..28, RC-CT-38..44, RC-CT-57..68).

CSC Volume VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il telefono vede il livello d'ascolto stimato, imposta il livello voluto, richiama il volume, muove il volume come il cursore del PC e vede il «Livello mantenuto»"
  EVENT OUT livello_ascolto(valido: Boolean)
  EVENT IN  imposta_voluto(livello: Integer [45 .. 90])
  EVENT IN  richiama
  EVENT IN  muovi(di_quanto: Real)
  EVENT IN  tieni_fisso(acceso: Boolean)
  EVENT OUT stato_volume
  EVENT OUT stato_corsa
  EVENT OUT stato_mantenuto
  GUARANTEE vo1: VERBAL "Il computer manda al telefono il livello d'ascolto stimato a ogni cambio e appena la sessione è pronta; quando la stima non è valida lo dice, e il telefono mostra due trattini"
                 VERIFY BY JUDGEMENT "l'operatore, che spegne l'audio e guarda il telefono"
  GUARANTEE vo2: VERBAL "Il telefono imposta il livello voluto da 45 a 90 dB(A), a passi di 1, e preme «Richiama volume»: il computer applica una volta sola la differenza con la stima, mai sopra 0 dB e mai sotto -40 dB di attenuazione, e dice se è arrivato o se è rimasto corto o lungo"
                 VERIFY BY JUDGEMENT "l'operatore, che richiama il volume dal telefono con un livello voluto lontano dalla stima"
  GUARANTEE vo3: VERBAL "A ogni cambio il telefono riceve livello voluto, attenuazione ed esito dell'ultimo richiamo, come li mostra la finestra"
                 VERIFY BY JUDGEMENT "l'operatore, che cambia il livello voluto dal PC e guarda il telefono"
  GUARANTEE vo4: VERBAL "Il telefono muove il volume come il cursore del PC: dice di quanto, al più 20 dB in su o in giù, e il computer ci arriva a 2 dB al secondo; il telefono vede il resto della corsa quando parte, cambia o finisce, e l'esito dell'arrivo"
                 VERIFY BY JUDGEMENT "l'operatore, che alza di 10 dB dal telefono e misura il tempo"
  GUARANTEE vo5: VERBAL "Il telefono vede se il «Livello mantenuto» è attivo, se è automatico o manuale e perché la misura non è affidabile; accende e spegne il «Tieni volume fisso» solo quando è disponibile, e non comanda il mantenimento automatico"
                 VERIFY BY JUDGEMENT "l'operatore, che accende il «Tieni volume fisso» dal telefono"
  GUARANTEE vo6: VERBAL "Gli stati che cambiano con la misura o con la corsa arrivano al più una volta al secondo per telefono, con l'ultimo valore"
                 VERIFY BY INSPECTION "il registro degli eventi durante una corsa"
END

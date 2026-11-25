-- La scoperta: come il telefono trova i computer con il controllo remoto acceso.
-- Fonte: contratto 1.13, §2.3 (RC-DI-*).

CSC Scoperta VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il telefono trova sulla rete di casa i computer con il controllo remoto acceso e ne sceglie uno"
  EVENT IN  cerca
  EVENT OUT trovato(nome: String)
  GUARANTEE sc1: VERBAL "Alla ricerca rispondono solo i computer con il controllo remoto acceso; spento, il computer tace del tutto"
                 VERIFY BY INSPECTION "le risposte alla ricerca, con un computer acceso e uno spento"
  GUARANTEE sc2: VERBAL "La risposta non contiene il codice, niente che lo faccia indovinare né lo stato della taratura; dice solo come chiamare il computer e come collegarsi"
                 VERIFY BY INSPECTION "le risposte alla ricerca"
  GUARANTEE sc3: VERBAL "Il computer risponde solo ad apparecchi della rete di casa o allo stesso computer, e non risponde a una ricerca malformata"
                 VERIFY BY INSPECTION "le risposte a ricerche da fuori della rete di casa e a ricerche scritte male"
  GUARANTEE sc4: VERBAL "La ricerca non si può usare per moltiplicare il traffico verso qualcun altro: la risposta è piccola e mai molto più grande della domanda"
                 VERIFY BY INSPECTION "le misure di domanda e risposta"
  GUARANTEE sc5: VERBAL "Se sulla rete ci sono più computer accesi, rispondono tutti e il telefono li distingue; una risposta alla ricerca non vale come abbinamento"
                 VERIFY BY JUDGEMENT "l'operatore, con due computer accesi"
END

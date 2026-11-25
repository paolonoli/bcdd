-- La sessione: versioni, tempi, numero di telefoni, chiusura.
-- Fonte: contratto 1.13, §1 (RC-SC-2), §2.2, §3, §5, §7, §9.

CSC Sessione VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il collegamento fra il telefono abbinato e il computer: quando è pronto, che cosa vi si può chiedere, quanto dura, come finisce"
  EVENT IN  collega
  EVENT IN  chiudi
  EVENT OUT chiuso(motivo: String)
  STATE pronta : Boolean INITIAL false
  GUARANTEE se1: VERBAL "Telefono e computer si parlano solo se hanno la stessa versione principale del protocollo; altrimenti il computer lo dice e chiude, e il telefono non riprova finché non è aggiornato"
                 VERIFY BY JUDGEMENT "l'operatore, con un telefono di versione principale diversa"
  GUARANTEE se2: VERBAL "Con versioni secondarie diverse si usano solo le cose che conoscono tutti e due; ciò che uno dei due non conosce l'altro lo ignora, e una richiesta sconosciuta riceve un rifiuto che lo dice"
                 VERIFY BY JUDGEMENT "l'operatore, con un telefono più vecchio e uno più nuovo del computer"
  GUARANTEE se3: VERBAL "Il telefono ha 5 s per presentarsi e abbinarsi; scaduti, il computer chiude. Prima dell'abbinamento si può solo presentarsi e abbinarsi"
                 VERIFY BY INSPECTION "il registro dei collegamenti, con un telefono che si ferma dopo il collegamento"
  GUARANTEE se4: VERBAL "A sessione pronta, 30 s senza niente dal telefono fanno chiudere il computer"
                 VERIFY BY JUDGEMENT "l'operatore, che mette il telefono in aereo e misura con un cronometro"
  GUARANTEE se5: VERBAL "A ogni richiesta il computer risponde una volta sola, entro 2 s; un rifiuto non è mai silenzioso e dice sempre il perché"
                 VERIFY BY INSPECTION "i tempi e i rifiuti registrati fra richiesta e risposta"
  GUARANTEE se6: VERBAL "Al massimo 4 telefoni collegati insieme; il quinto riceve un rifiuto che lo dice e viene chiuso"
                 VERIFY BY JUDGEMENT "l'operatore, con cinque collegamenti di prova"
  GUARANTEE se7: VERBAL "Niente sopravvive alla sessione: dopo una nuova connessione il telefono riparte da capo e riceve subito lo stato corrente, senza ripetere da solo le richieste di prima"
                 VERIFY BY JUDGEMENT "l'operatore, che spegne e riaccende il Wi-Fi del telefono"
  GUARANTEE se8: VERBAL "Il computer accetta collegamenti solo dalla rete di casa o dallo stesso computer; gli altri li chiude subito, senza rispondere"
                 VERIFY BY INSPECTION "il registro dei collegamenti, provando da un indirizzo fuori dalla rete di casa"
  GUARANTEE se9: VERBAL "Quando chiude di sua iniziativa (spegnimento, servizio spento, codice rigenerato) il computer avvisa il telefono pronto e dice il motivo; quando il telefono chiede di chiudere, il computer risponde e chiude"
                 VERIFY BY JUDGEMENT "l'operatore, che spegne il servizio con il telefono collegato"
END

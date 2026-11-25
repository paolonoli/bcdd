-- Il gesto dell'utente fra le fasi: che cosa collega agli ingressi L e R della scheda di cattura, e dove mette il
-- microfono. L = ingresso 1, XLR con phantom; R = ingresso 2, linea (§3). Connettori, livelli e phantom sono la
-- fase 2. Sull'ingresso L si alternano due FUNZIONI, misura dell'ambiente (Misure) e rilevamento del livello
-- (Riproduzione), mai nella stessa fase (k3 del kit; D-337). Con la DI come sensore il gesto è un
-- ricablaggio; con il microfono come sensore il dispositivo su L resta lo stesso e il gesto è uno spostamento.
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md (§2, §3, §6 R-CAP); Q-AK-3, Q-AK-4, Q-AK-5; operatore, D-336, D-337.

CSC Ricablaggio VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "L'utente collega, scollega e sposta a mano ciò che entra negli ingressi L e R della scheda di cattura quando passa da una fase all'altra"
  TYPE Ingresso := {ingresso_L, ingresso_R}
  TYPE Ospite := {microfono, di, loop}
  TYPE Posizione := {punto_di_misura, vicino_al_diffusore}
  EVENT IN  collega(ingresso: Ingresso, ospite: Ospite)
  EVENT IN  scollega(ingresso: Ingresso)
  EVENT IN  sposta_microfono(posizione: Posizione)
  GUARANTEE ri1 STATUS RATIFIED BY D-338: VERBAL "L'ingresso L ospita un solo dispositivo per volta: il microfono oppure la DI, mai tutti e due insieme (fonte: G-05 [O], D-26; §3)"
                 VERIFY BY INSPECTION "l'ingresso L della scheda di cattura in ciascuna fase"
  GUARANTEE ri2 STATUS RATIFIED BY D-338: VERBAL "AP non collega, non scollega e non sposta niente e non se ne accorge: ricablaggio e spostamento li fa l'utente, e se non li fa AP non lo rileva (fonte: §2 «Ricablaggio fra fasi» [O], D-26, AP-W94; operatore, D-336; per lo spostamento, D-337 come riportato dal coordinatore)"
                 VERIFY BY JUDGEMENT "l'operatore, che entra in Riproduzione senza fare il gesto richiesto e guarda se AP lo segnala"
  GUARANTEE ri3 STATUS RATIFIED BY D-338: VERBAL "Calcolo Correzione non chiede nessun collegamento audio (fonte: §3, AP-W155; Q-AK-3)"
                 VERIFY BY JUDGEMENT "l'operatore, che calcola la correzione con gli ingressi scollegati"
  ASSUME    ri-a1 STATUS RATIFIED BY D-338: VERBAL "Prima di entrare in Misure l'utente mette sull'ingresso L il microfono, al punto di misura (togliendo la DI, se c'era), e collega il riferimento all'ingresso R: il loop (D-10), oppure la DI come riferimento (AP-W94) (fonte: §2, §3; Q-AK-3, Q-AK-4)"
                   VERIFY BY JUDGEMENT "l'operatore, che controlla cavi e microfono prima di avviare le misure"
  ASSUME    ri-a2 STATUS RATIFIED BY D-338: VERBAL "Prima di entrare in Riproduzione l'utente mette sull'ingresso L il sensore di livello: la DI collegata ai morsetti di un diffusore, oppure il microfono spostato fermo vicino al diffusore (alternativa di D-337, supporto di AP da confermare); l'ingresso R in Riproduzione non serve (fonte: §2, §3; Q-AK-3, Q-AK-5; operatore, D-337)"
                   VERIFY BY JUDGEMENT "l'operatore, che controlla il sensore di livello prima della Taratura"
  ASSUME    ri-a3 STATUS RATIFIED BY D-338: VERBAL "Con il microfono come sensore di livello, dopo la Taratura il microfono non si sposta più: se si sposta, l'ancora della Taratura non vale più e AP non lo sa (fonte: operatore, D-337)"
                   VERIFY BY JUDGEMENT "l'operatore, che segna la posizione del microfono alla Taratura e la ricontrolla"
  -- ri-a1, ri-a2, ri-a3 sono obblighi dell'utente, non controlli di AP: AP è cieco ai gesti (D-336).
  -- La DI esce con un segnale sostanzialmente di linea e può entrare in un ingresso di linea (D-336: parte
  -- elettrica di A-02 risolta). La DI come riferimento in Misure è una terza funzione, Riferimento, non il sensore
  -- di livello; resta aperto (A-02) quando la si usa al posto del loop.
  -- Microfono su L, poi DI su L dopo averlo tolto: un solo ingresso XLR basta (ri1).
  SCENARIO ri-s1 EXPECT ADMITTED
    @0 s     collega(ingresso: ingresso_L, ospite: microfono)
    @0 s     collega(ingresso: ingresso_R, ospite: loop)
    @600 s   scollega(ingresso: ingresso_L)
    @600 s   scollega(ingresso: ingresso_R)
    @610 s   collega(ingresso: ingresso_L, ospite: di)
  -- La DI su L mentre c'è ancora il microfono: viola ri1.
  SCENARIO ri-s2 EXPECT REJECTED
    @0 s     collega(ingresso: ingresso_L, ospite: microfono)
    @10 s    collega(ingresso: ingresso_L, ospite: di)
END

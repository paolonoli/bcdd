-- Prova della SPECIFICA_02 0.6 (BCDD/W-09), sintassi ILLUSTRATIVA: bcdd non conosce VARIANT ne' [0 .. 1].
-- Prende il posto di Kit1bDueSchede e Kit1bDueSchedeMicrofono: k1 = km1, k2 = km3, k4 = km4 (stesso testo).
-- Copre tre composizioni: DI presente, DI assente (G-06, oggi non scritta), microfono come sensore.

ENTITY Kit1b VERSION 0.2
  STATUS HYPOTHESIS
  PURPOSE "Il kit per il passthrough DSP su Raspberry Pi 4 con due schede: una porta il programma, l'altra cattura microfono, sensore di livello e riferimento"
  OFFERS Modalita
  OFFERS Misura
  OFFERS LetturaLivello
  OFFERS Ricablaggio
  OFFERS RilevamentoLivello
  USES   Programma
  USES   IngressoAmplificatore
  COMPOSED OF
    computer  : Calcolatore1b
    flusso    : SchedaFlusso
    cattura   : SchedaCattura
    loop      : CavoLoop
  GUARANTEE k1 STATUS RATIFIED BY D-338: VERBAL "In Misure microfono e riferimento entrano nella stessa scheda, la scheda di cattura, quindi sono sullo stesso clock e AP ne misura il ritardo (fonte: G-01 [B], D-10; Q-AK-8 «vero per costruzione»)"
                VERIFY BY INSPECTION "la composizione: la sola parte cattura usa sia SegnaleMisura sia Riferimento"
  GUARANTEE k2 STATUS RATIFIED BY D-338: VERBAL "L'uscita verso l'amplificatore sta sulla scheda del flusso, con un clock diverso da quello della cattura: è ammesso (fonte: G-02 [B], banco U24XL + UMC22, D-10)"
                VERIFY BY JUDGEMENT "l'operatore, che esegue una misura con le due schede"
  GUARANTEE k4 STATUS RATIFIED BY D-338: VERBAL "Il programma passa dall'ingresso all'uscita con al più 100 ms di ritardo (fonte: G-12 [O], D-15)"
                VERIFY BY JUDGEMENT "l'operatore, che misura il ritardo fra l'ingresso della scheda del flusso e la sua uscita"
  -- Una misura dell'ambiente senza riferimento sull'ingresso R: rifiutata (mi3, G-04). Vale per la misura
  -- dell'ambiente, non per la serie di verifica né per la sonda di livello (AP-R2 D2).
  SCENARIO k-s4 EXPECT REJECTED
    @0 s     Ricablaggio.collega(ingresso: ingresso_L, ospite: microfono)
    @10 s    Modalita.scegli(modalita: misure)
    @10 s    Modalita.attiva(modalita: misure)
    @20 s    Misura.sweep
    @40 s    Misura.risposta_ambiente
  -- Il telefono manda una lettura in Misure e AP la accetta: rifiutato (le2).
  SCENARIO k-s5 EXPECT REJECTED
    @0 s     Modalita.scegli(modalita: misure)
    @0 s     Modalita.attiva(modalita: misure)
    @10 s    LetturaLivello.lettura(valore: _)
    @10 s    LetturaLivello.esito_lettura(accettata: true)
  -- Il sensore di livello: la DI ai morsetti, facoltativa (senza, niente Loudness: rl3, G-06), oppure
  -- lo stesso microfono, fermo vicino al diffusore (D-337). La scelta si fa quando si compone il kit.
  VARIANT sensore = di
    USES   Morsetti
    COMPOSED OF
      microfono : MicrofonoMisura
      di        : DirectBox [0 .. 1]   -- senza DI niente Loudness (rl3)
    GUARANTEE k3 STATUS RATIFIED BY D-338: VERBAL "La misura dell'ambiente e il rilevamento del livello d'uscita non stanno mai nella stessa fase, quindi usano lo stesso ingresso L: un solo ingresso XLR con phantom basta e un secondo XLR non è un requisito. La mutua esclusione è fra funzioni, non fra dispositivi (fonte: G-05 [O], D-26, riformulato fra funzioni da D-337; §6 R-CAP)"
                  VERIFY BY INSPECTION "la tabella dei collegamenti per fase (§3): nessuna fase chiede insieme microfono e DI sull'ingresso L"
    -- Il caso della scheda con un solo XLR: microfono su L in Misure, DI su L in Riproduzione. Ammesso (k3, ri1).
    SCENARIO k-s1 EXPECT ADMITTED
      @0 s     Ricablaggio.collega(ingresso: ingresso_L, ospite: microfono)
      @0 s     Ricablaggio.collega(ingresso: ingresso_R, ospite: loop)
      @10 s    Modalita.scegli(modalita: misure)
      @10 s    Modalita.attiva(modalita: misure)
      @20 s    Misura.sweep
      @40 s    Misura.risposta_ambiente
      @50 s    Modalita.scegli(modalita: calcolo)
      @50 s    Modalita.attiva(modalita: calcolo)
      @120 s   Ricablaggio.scollega(ingresso: ingresso_L)
      @120 s   Ricablaggio.scollega(ingresso: ingresso_R)
      @130 s   Ricablaggio.collega(ingresso: ingresso_L, ospite: di)
      @140 s   Modalita.scegli(modalita: riproduzione)
      @140 s   Modalita.attiva(modalita: riproduzione)
      @150 s   Modalita.avvia(procedura: taratura)
      @150 s   Modalita.avviata(procedura: taratura)
      @180 s   LetturaLivello.lettura(valore: _)
      @180 s   LetturaLivello.esito_lettura(accettata: true)
      @190 s   Modalita.chiudi(procedura: taratura)
    -- Microfono e DI insieme sull'ingresso L nella stessa fase: rifiutato (ri1, k3). Con un solo XLR è anche
    -- impossibile; il punto è che misura e rilevamento del livello non stanno mai nella stessa fase, quindi due XLR
    -- non servono.
    SCENARIO k-s2 EXPECT REJECTED
      @0 s     Ricablaggio.collega(ingresso: ingresso_L, ospite: microfono)
      @0 s     Ricablaggio.collega(ingresso: ingresso_R, ospite: loop)
      @5 s     Ricablaggio.collega(ingresso: ingresso_L, ospite: di)
      @10 s    Modalita.scegli(modalita: misure)
      @10 s    Modalita.attiva(modalita: misure)
    -- Ricablaggio non fatto: in Riproduzione il microfono è ancora su L. Rifiutato perché l'utente non rispetta
    -- ri-a2; AP non se ne accorge (ri2; operatore, D-336) e niente lo segnala.
    SCENARIO k-s3 EXPECT REJECTED
      @0 s     Ricablaggio.collega(ingresso: ingresso_L, ospite: microfono)
      @10 s    Modalita.scegli(modalita: riproduzione)
      @10 s    Modalita.attiva(modalita: riproduzione)
      @20 s    Modalita.avvia(procedura: taratura)
      @20 s    Modalita.avviata(procedura: taratura)
  VARIANT sensore = microfono
    COMPOSED OF
      microfono : MicrofonoMisura          -- un solo dispositivo, due funzioni in fasi diverse (L3)
    GUARANTEE km2 STATUS RATIFIED BY D-338: VERBAL "La misura dell'ambiente e il rilevamento del livello d'uscita non stanno mai nella stessa fase: qui li svolge lo stesso microfono sull'ingresso L, spostato fra le due fasi, e non serve né una DI né un secondo XLR (fonte: G-05 [O], D-26, riformulato fra funzioni da D-337)"
                   VERIFY BY INSPECTION "la tabella dei collegamenti per fase (§3) letta per funzioni"
    -- Il microfono misura l'ambiente, poi viene spostato vicino al diffusore e fa da sensore di livello: ammesso.
    -- Il cavo sull'ingresso L non si tocca; si toglie solo il loop dall'ingresso R.
    SCENARIO km-s1 EXPECT ADMITTED
      @0 s     Ricablaggio.collega(ingresso: ingresso_L, ospite: microfono)
      @0 s     Ricablaggio.collega(ingresso: ingresso_R, ospite: loop)
      @0 s     Ricablaggio.sposta_microfono(posizione: punto_di_misura)
      @10 s    Modalita.scegli(modalita: misure)
      @10 s    Modalita.attiva(modalita: misure)
      @20 s    Misura.sweep
      @40 s    Misura.risposta_ambiente
      @120 s   Ricablaggio.scollega(ingresso: ingresso_R)
      @130 s   Ricablaggio.sposta_microfono(posizione: vicino_al_diffusore)
      @140 s   Modalita.scegli(modalita: riproduzione)
      @140 s   Modalita.attiva(modalita: riproduzione)
      @150 s   Modalita.avvia(procedura: taratura)
      @150 s   Modalita.avviata(procedura: taratura)
      @180 s   LetturaLivello.lettura(valore: _)
      @180 s   LetturaLivello.esito_lettura(accettata: true)
      @190 s   Modalita.chiudi(procedura: taratura)
    -- Il microfono si sposta dopo la Taratura, senza una Taratura nuova: rifiutato, perché l'utente non rispetta
    -- ri-a3 e l'ancora non vale più; AP non se ne accorge (ri2). Scelta dichiarata: REJECTED, come k-s3.
    SCENARIO km-s2 EXPECT REJECTED
      @0 s     Ricablaggio.collega(ingresso: ingresso_L, ospite: microfono)
      @0 s     Ricablaggio.sposta_microfono(posizione: vicino_al_diffusore)
      @10 s    Modalita.scegli(modalita: riproduzione)
      @10 s    Modalita.attiva(modalita: riproduzione)
      @20 s    Modalita.avvia(procedura: taratura)
      @20 s    Modalita.avviata(procedura: taratura)
      @50 s    LetturaLivello.lettura(valore: _)
      @50 s    LetturaLivello.esito_lettura(accettata: true)
      @60 s    Modalita.chiudi(procedura: taratura)
      @300 s   Ricablaggio.sposta_microfono(posizione: punto_di_misura)
END

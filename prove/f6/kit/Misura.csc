-- La misura dell'ambiente: che cosa fa AP in Misure Ambientali.
-- «Stesso clock» fra microfono e riferimento è una garanzia della composizione: sta nelle entità del kit.
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md (§2 S-MIS, §4 G-01, G-04, G-07); risposta di AudioKits Q-AK-5.

CSC Misura VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "In Misure Ambientali AP manda lo sweep all'amplificatore, registra insieme microfono e riferimento e ne ricava la risposta d'ambiente"
  EVENT OUT sweep
  EVENT OUT risposta_ambiente
  GUARANTEE mi1 STATUS RATIFIED BY D-338: VERBAL "In Misure AP emette lo sweep verso l'amplificatore e registra insieme il microfono e il riferimento; dalla registrazione ricava la risposta d'ambiente (fonte: §2 S-MIS, AP-R §2 [B])"
                 VERIFY BY JUDGEMENT "l'operatore, che esegue una misura e guarda la risposta d'ambiente"
  GUARANTEE mi2 STATUS RATIFIED BY D-338: VERBAL "AP misura il ritardo fra microfono e riferimento (fonte: G-01 [B], deriva 0,136 ppm il 13/09)"
                 VERIFY BY INSPECTION "il ritardo riportato da AP dopo una misura"
  GUARANTEE mi3 STATUS RATIFIED BY D-341: VERBAL "Ogni misura dell'ambiente ha il suo riferimento elettrico, il loop oppure la DI come riferimento: AP la rifiuta prima dell'avvio se il riferimento dichiarato è «Nessuno», e scarta la posizione se dopo la cattura il riferimento è assente o muto. La serie di verifica e la sonda di livello non hanno bisogno del riferimento (fonte: G-04 [C], decisione di AP del 21/10, ristretta al gruppo principale di misure da AP-R2 D2 [C], senza prova al banco)"
                 VERIFY BY JUDGEMENT "l'operatore, che prova una misura con l'ingresso R scollegato"
  ASSUME    mi-a1 STATUS RATIFIED BY D-338: VERBAL "Durante le misure il monitoraggio diretto della scheda di cattura è spento (fonte: G-07, avvertenza del 14/09, AP-R §8.6)"
                   VERIFY BY JUDGEMENT "l'operatore, che controlla il monitor diretto prima della misura"
  -- Che cosa fa AP davanti a una misura senza riferimento (rifiuta, avvisa?) è una domanda (D2 dell'ESITO).
END

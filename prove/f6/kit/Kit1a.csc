-- Prova della SPECIFICA_02 0.6 (BCDD/W-09), sintassi ILLUSTRATIVA: bcdd non conosce VARIANT ne' [0 .. 1].
-- Prende il posto di Kit1aSchedaUnica e Kit1aSchedaUnicaMicrofono: a1 = am1 (stesso testo).
-- a3 (loop dall'uscita cuffie) resta nella scelta di come nell'originale: la forma mostra che il kit col
-- microfono non la dice. Se vale per tutti e due lo decide l'operatore.

ENTITY Kit1a VERSION 0.2
  STATUS HYPOTHESIS
  PURPOSE "Il kit per l'ascolto su PC con una sola scheda, che porta il programma del PC all'amplificatore e cattura microfono, sensore di livello e riferimento"
  OFFERS Modalita
  OFFERS Misura
  OFFERS LetturaLivello
  OFFERS Ricablaggio
  OFFERS RilevamentoLivello
  USES   IngressoAmplificatore
  COMPOSED OF
    computer  : Calcolatore1a
    scheda    : SchedaUnica
    loop      : CavoLoop
  GUARANTEE a1 STATUS RATIFIED BY D-340: VERBAL "Microfono e riferimento entrano nella stessa scheda, quindi sono sullo stesso clock; anche l'uscita verso l'amplificatore sta su quella scheda (fonte: G-01 [B]; §5 «1.a» [B], AP-R §2)"
                VERIFY BY INSPECTION "la composizione: la sola parte scheda usa SegnaleMisura e Riferimento e offre UscitaAnalogica"
  -- Il sensore di livello: la DI ai morsetti, facoltativa (senza, niente Loudness: rl3, G-06), oppure
  -- lo stesso microfono, fermo vicino al diffusore (D-337). La scelta si fa quando si compone il kit.
  VARIANT sensore = di
    USES   Morsetti
    COMPOSED OF
      microfono : MicrofonoMisura
      di        : DirectBox [0 .. 1]   -- senza DI niente Loudness (rl3)
    GUARANTEE a2 STATUS RATIFIED BY D-340: VERBAL "La misura dell'ambiente e il rilevamento del livello d'uscita non stanno mai nella stessa fase, quindi usano lo stesso ingresso L: un solo ingresso XLR con phantom basta e un secondo XLR non è un requisito (fonte: G-05 [O], D-26, fra funzioni da D-337; §5 «1.a»)"
                  VERIFY BY INSPECTION "la tabella dei collegamenti per fase (§3)"
    GUARANTEE a3 STATUS RATIFIED BY D-340: VERBAL "Il riferimento si può prendere da una seconda uscita della stessa scheda, anche l'uscita cuffie, riportata con il cavo di loop sull'ingresso R; l'uscita principale va all'amplificatore (fonte: §5 «1.a» [B], AP-R §2, taratura del 28/08; §6 «R-CAP nell'1.a e scheda unica»)"
                  VERIFY BY JUDGEMENT "l'operatore, che esegue una misura con il loop preso dall'uscita cuffie"
    GUARANTEE a4 STATUS RATIFIED BY D-341: VERBAL "La DI si collega ai morsetti come nella 1.b ed è in uso su Windows: DI20 su una PreSonus AudioBox iTwo, la stessa scheda della taratura del 28/08, da settimane (fonte: operatore, D-339; modello confermato da AudioKits, loro D-31)"
                  VERIFY BY JUDGEMENT "l'operatore, che usa la DI con AP su Windows"
  VARIANT sensore = microfono
    COMPOSED OF
      microfono : MicrofonoMisuraELivello   -- un solo dispositivo, due funzioni in fasi diverse (L3)
    GUARANTEE am2 STATUS RATIFIED BY D-340: VERBAL "La misura dell'ambiente e il rilevamento del livello d'uscita non stanno mai nella stessa fase: li svolge lo stesso microfono sull'ingresso L, spostato fra le due fasi, e non serve né una DI né un secondo XLR (fonte: G-05 [O], D-26, fra funzioni da D-337)"
                   VERIFY BY INSPECTION "la tabella dei collegamenti per fase (§3) letta per funzioni"
END

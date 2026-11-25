-- La funzione «rilevamento del livello d'uscita» vista dal lato di AP: che cosa ne fa in Riproduzione.
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §2 S-RIP, S-TAR, S-VER, §4 G-06; operatore, D-337.

CSC RilevamentoLivello VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "In Riproduzione AP segue il livello d'uscita con un sensore di livello, ancorato dall'ultima Taratura, per il volume e il Loudness"
  GUARANTEE rl1 STATUS RATIFIED BY D-338: VERBAL "In Riproduzione AP segue il livello d'uscita con il sensore di livello, a partire dall'ancora dell'ultima Taratura, per il volume e il Loudness (fonte: §2 S-RIP e S-TAR, AP-W155 [C]; operatore, D-337)"
                 VERIFY BY JUDGEMENT "l'operatore, che dopo la Taratura cambia il volume e confronta con un fonometro"
  GUARANTEE rl2 STATUS RATIFIED BY D-338: VERBAL "Il sensore di livello è la DI ai morsetti di un diffusore oppure lo stesso microfono di misura, fermo vicino al diffusore per ridurre i rumori di fondo, con la Taratura fatta sul microfono stesso. Scelta di progetto dell'operatore (D-337); il supporto di AP all'alternativa microfono è da confermare: oggi AP parla solo della DI (AP-W94, G-06)"
                 VERIFY BY JUDGEMENT "l'operatore, che fa la Taratura e poi segue il volume una volta con la DI e una con il microfono"
  GUARANTEE rl3 STATUS RATIFIED BY D-338: VERBAL "Senza un sensore di livello il Loudness non si usa e il resto funziona (fonte: G-06 [C], che oggi lo dice della DI; generalizzato al sensore da D-337)"
                 VERIFY BY JUDGEMENT "l'operatore, che prova il Loudness senza DI e senza microfono sull'ingresso L"
END

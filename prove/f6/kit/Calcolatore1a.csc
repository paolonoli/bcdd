-- R-CPU nella configurazione 1.a: un PC con AudioProcessor (oggi solo Windows 11; Linux e macOS dopo il porting).
-- È anche la sorgente del programma (c3, D-342). Un ruolo, non un modello di calcolatore. Offre gli stessi confini di Calcolatore1b: nei kit i due si scambiano.
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §5 «1.a», §6 R-CPU e R-CAP (D-17, D-20).

ENTITY Calcolatore1a VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il calcolatore del kit 1.a, un PC Windows 11 con AudioProcessor: tiene le modalità, fa le misure, segue il livello d'uscita e riceve la lettura del telefono"
  OFFERS Modalita
  OFFERS Misura
  OFFERS LetturaLivello
  OFFERS RilevamentoLivello
  USES   AudioUsb
  GUARANTEE c1 STATUS RATIFIED BY D-340: VERBAL "Su Windows AP apre la scheda in WASAPI esclusivo, a 48 o 44,1 kHz, in uscita e in cattura insieme (fonte: §5 «1.a» [B], AP-R §3; §6 R-CAP [O], D-17)"
                VERIFY BY JUDGEMENT "l'operatore, che avvia AP sul PC alle due frequenze e controlla che la scheda non sia condivisa con altri programmi"
  GUARANTEE c2 STATUS RATIFIED BY D-340: VERBAL "Il PC ha almeno un processore x86-64 a due core da 1,6 GHz e 4 GB di memoria: è una stima provvisoria, non un minimo provato (fonte: §6 R-CPU [O], D-20)"
                VERIFY BY INSPECTION "la scheda tecnica del PC"
  GUARANTEE c3 STATUS RATIFIED BY D-342: VERBAL "La sorgente è solo il PC stesso: il programma è lo streaming sul PC e arriva ad AP dentro il PC, attraverso un dispositivo di uscita muto (VB-Cable), non dall'ingresso della scheda; una sorgente esterna è fuori specifica (fonte: AudioKits D-38, §5 «1.a» [O]; AP-R §3 [C]; MODELLO_SISTEMA_FATTI v0.6)"
                VERIFY BY JUDGEMENT "l'operatore, che avvia lo streaming sul PC con VB-Cable come uscita e controlla che AP riceva il programma"
END

-- R-CPU nella configurazione 1.b: Raspberry Pi 4 con AudioProcessor. Un ruolo, non un modello di calcolatore.
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §1 R-CPU, §2, §5 «1.b».

ENTITY Calcolatore1b VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il calcolatore del kit 1.b, un Raspberry Pi 4 con AudioProcessor: tiene le modalità, fa le misure, segue il livello d'uscita e riceve la lettura del telefono"
  OFFERS Modalita
  OFFERS Misura
  OFFERS LetturaLivello
  OFFERS RilevamentoLivello
  USES   AudioUsb
END

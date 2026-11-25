-- Il confine fra la sorgente dell'utente e il kit. La sorgente non è del kit: qui c'è solo la sua interfaccia.
-- Fase 2, non qui: S/PDIF a 48 o 44,1 kHz oppure linea (D-17). Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §1 R-SRC; Q-AK-2.

CSC Programma VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La sorgente dell'utente porta al kit il programma da ascoltare, in digitale o in analogico"
  GUARANTEE pr1 STATUS RATIFIED BY D-338: VERBAL "La sorgente porta il programma in S/PDIF ottico o coassiale oppure da un'uscita di linea (fonte: §1 R-SRC, AP-R §2, §3; Q-AK-2)"
                 VERIFY BY INSPECTION "le uscite della sorgente dell'utente"
END

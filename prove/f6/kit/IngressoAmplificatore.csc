-- Il confine fra il kit e l'amplificatore dell'utente. L'amplificatore non è del kit: qui c'è solo la sua interfaccia.
-- Fase 2, non qui: l'ingresso di linea accetta 0, +4 o +10 dB secondo il modello, con l'unità di riferimento
-- (dBu o dBV) da precisare con AudioKits (operatore, D-336). Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §1 R-AMP; Q-AK-2, Q-AK-4.

CSC IngressoAmplificatore VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "L'amplificatore dell'utente riceve dal kit il programma corretto, lo sweep o il rumore di prova, e lo porta ai diffusori"
  GUARANTEE ia1 STATUS RATIFIED BY D-338: VERBAL "L'amplificatore ha un ingresso S/PDIF oppure di linea e porta ai diffusori ciò che riceve (fonte: §1 R-AMP, AP-R §2; Q-AK-2)"
                 VERIFY BY INSPECTION "gli ingressi dell'amplificatore dell'utente"
END

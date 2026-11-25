-- Il confine fra una scheda audio e il calcolatore con AP (USB). Le offrono la scheda del flusso e la scheda
-- di cattura, oppure la scheda unica; la usa il calcolatore.
-- Fase 2, non qui: class compliant, nome ALSA, formati, corrente dal bus (§6). Le schede si alimentano di
-- preferenza dal bus USB del Raspberry Pi, con un alimentatore adeguato; alcune hanno un'alimentazione
-- separata, USB o propria (operatore, D-336). Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §1 R-CPU, §4 G-10.

CSC AudioUsb VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "La scheda porta al calcolatore i suoi ingressi e riceve da lui le sue uscite, via USB"
  GUARANTEE au1 STATUS RATIFIED BY D-338: VERBAL "AP riconosce ogni scheda per nome, mai per indice ALSA (fonte: G-10 [C], AP-R §8.4)"
                 VERIFY BY JUDGEMENT "l'operatore, che scambia le prese USB delle due schede e riavvia AP"
END

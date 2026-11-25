-- La scheda unica della 1.a: uscita e cattura sulla stessa scheda, che su Windows funziona perché in WASAPI uscita
-- e ingresso sono due endpoint distinti. Non è più una variante della 1.b (D-341; AudioKits D-32, AP-R3):
-- sul Raspberry Pi 4 con jackd AP rifiuta la cattura sulla scheda che suona. Nessuna sorgente sul suo ingresso:
-- nella 1.a il programma viene dal PC (AudioKits D-38, D-342).
-- Fonti: fonti/MODELLO_SISTEMA_FATTI_v0.2.md §5 «1.a», §6 «R-CAP nell'1.a e scheda unica»; v0.5 (AP-R3).

ENTITY SchedaUnica VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Una sola scheda che porta all'amplificatore il programma ricevuto dal PC e cattura misura dell'ambiente, sensore di livello e riferimento"
  USES   IngressoAmplificatore
  USES   SegnaleMisura
  USES   SegnaleLivello
  USES   Riferimento
  OFFERS UscitaAnalogica
  OFFERS Ricablaggio
  OFFERS AudioUsb
END

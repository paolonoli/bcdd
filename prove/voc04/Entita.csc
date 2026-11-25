-- Prova D-168 (grammatica 1.10): una parola riservata nuova non è un nome neanche in un'entità.

ENTITY Insieme VERSION 0.1
  PURPOSE "Le parole riservate nuove nei posti di un'entità"
  OFFERS WHEN
  USES ALL
  ON : Parte
  parte : MAX
  GUARANTEE e1: VERBAL "le quattro righe sopra non sono citazioni" VERIFY BY INSPECTION "il rapporto"
END

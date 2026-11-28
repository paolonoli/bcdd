-- The staircase lamp, one of the two parts of the light.
-- [REQ-2]: IMPIANTO.md#REQ-2

ENTITY Lampada VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The lamp switches on at the command and switches off by itself"

  USES   Comando
  USES   Alimentazione
  OFFERS Luce

  GUARANTEE la1: VERBAL "After an accendi the light switches on within 0.5 s"
                 VERIFY BY JUDGEMENT "a person who observes the lamp while the command is sent"
  -- la2 comes from requirement [REQ-2] of the installation.
  GUARANTEE la2: VERBAL "The light switches off 90 s after the last accendi, with a tolerance of 5 s"
                 VERIFY BY JUDGEMENT "a person with a stopwatch"
END

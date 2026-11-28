-- The staircase light, made of a button and a lamp.
-- The connector Comando between the two parts is internal: it is not visible from outside.

ENTITY LuceScale VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The person on the stairs presses the button and has light to go up or down"

  OFFERS Pressione
  OFFERS Luce
  USES   Alimentazione

  COMPOSED OF
    pulsante : Pulsante
    lampada  : Lampada

  GUARANTEE ls1: VERBAL "When someone presses the button, the light switches on"
                 VERIFY BY JUDGEMENT "a person who presses the button and watches"
  GUARANTEE ls2: VERBAL "The light switches off 90 s after the last press, with a tolerance of 5 s"
                 VERIFY BY JUDGEMENT "a person who measures with a stopwatch the time between the last press and switch-off"
END

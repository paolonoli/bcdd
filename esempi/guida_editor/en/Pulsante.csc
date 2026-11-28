-- The staircase button, one of the two parts of the light.

ENTITY Pulsante VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The button receives the press and commands the lamp"

  OFFERS Pressione
  OFFERS Comando

  GUARANTEE pu1: VERBAL "Each press is followed by an accendi within 0.1 s"
                 VERIFY BY INSPECTION "the recorded presses and commands"
END

-- The staircase light, as seen by the person on the stairs.

CSC Luce VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The person on the stairs sees the light on for the time needed to go up or down"

  STATE      accesa : Boolean INITIAL false

  GUARANTEE g2: VERBAL "The light switches off by itself after a while"
                VERIFY BY JUDGEMENT "a person with a watch"
END

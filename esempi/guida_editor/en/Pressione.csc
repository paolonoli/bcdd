-- The staircase button, as seen by whoever presses it.

CSC Pressione VERSION 0.1
  STATUS RATIFIED BY D-1
  PURPOSE "The person on the stairs presses the button to ask for light"

  EVENT IN   premuto

  ASSUME    a1: VERBAL "Whoever presses the button holds it down for at least a tenth of a second"
                VERIFY BY JUDGEMENT "a person who observes how the button is pressed"
END

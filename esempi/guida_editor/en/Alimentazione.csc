-- The electrical mains of the block of flats, as seen by the lighting installation.

CSC Alimentazione VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The electrical mains of the block of flats supplies voltage to the staircase lighting installation"

  STATE      presente : Boolean INITIAL true

  GUARANTEE r1: VERBAL "The voltage is present, except for interruptions of the mains"
                VERIFY BY INSPECTION "the register of interruptions of the block of flats"
  ASSUME    r-a1: VERBAL "The staircase lighting installation draws at most 100 W"
                  VERIFY BY INSPECTION "the rating plate data of the installed lamps"
END

-- The command that the button sends to the lamp.

CSC Comando VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "The button commands the lamp to switch on"

  EVENT OUT  accendi

  GUARANTEE c1: VERBAL "At least 0.2 s pass between two accendi"
                VERIFY BY INSPECTION "the recorded commands"
END

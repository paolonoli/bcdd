CSC Light VERSION 0.1
  IMPORT PROFILE Absent VERSION 0.1
  PURPOSE "to be filled in: what Light is responsible for"
  STATE on : Boolean INITIAL false
  EVENT IN press
  GUARANTEE g1: VERBAL "The light can be seen"
                VERIFY BY JUDGEMENT "the operator"
  GUARANTEE g2: ALWAYS on
  GUARANTEE g2a DETAILS g2: VERBAL "It stays on"
                VERIFY BY JUDGEMENT "the operator"
END
BINDING Light VERSION 0.1 AS forms
  STATUS HYPOTHESIS
END
VERIFICATION Light VERSION 0.1
  MEANS camera OBSERVES on RESOLUTION 40 ms
END
BINDING Ghost VERSION 0.1 AS forms
  STATUS HYPOTHESIS
END

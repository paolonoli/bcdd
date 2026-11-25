PROFILE T VERSION 0.1
  PURPOSE "p"
  EXTENSION B
    KIND FUNCTION
    LEVEL CSC
    PARAMS (s: Real) : Real
    FORM "B s"
    MEANING "m"
    VERIFY V1 C1
    SOURCE "s"
    REDUCES TO ABS(s)
  END
  EXTENSION C
    KIND PATTERN
    LEVEL CSC
    PARAMS (p: Condition, s: Duration)
    FORM "C p s"
    MEANING "m"
    VERIFY V1 C1
    SOURCE "s"
    REDUCES TO EVENTUALLY p WITHIN 1 s
  END
  EXTENSION D
    KIND PATTERN
    LEVEL CSC
    PARAMS (p: Condition, s: Duration)
    FORM "D p s"
    MEANING "m"
    VERIFY V1 C1
    SOURCE "s"
    REDUCES TO EVENTUALLY p WITHIN s
  END
END

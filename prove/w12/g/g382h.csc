PROFILE T VERSION 0.1
  PURPOSE "p"
  EXTENSION A
    KIND FUNCTION
    LEVEL CSC
    PARAMS (c: Condition, a: Expression, b: Expression) : Real
    FORM "A c a b"
    MEANING "m"
    VERIFY V1 C1
    SOURCE "s"
    REDUCES TO (IF c THEN a ELSE b)
  END
END

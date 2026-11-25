PROFILE T VERSION 0.1
  PURPOSE "p"
  EXTENSION A
    KIND FUNCTION
    LEVEL CSC
    PARAMS (p: Event, d: Duration) : Integer
    FORM "A p d"
    MEANING "m"
    VERIFY V1 C1
    SOURCE "s"
    REDUCES TO COUNT(p) IN LAST d
  END
END

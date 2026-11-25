PROFILE Senza VERSION 0.1
END
PROFILE Segnale VERSION 0.3
  PURPOSE "p"
  EXTENSION SenzaSource
    KIND PATTERN
    LEVEL CSC
    PARAMS (s: Expression)
    FORM "SenzaSource s"
    MEANING "m"
    VERIFY V1 C1
  END
  EXTENSION Kind
    KIND pattern
    LEVEL Core
    PARAMS (s: Expression)
    FORM "Kind s"
    MEANING "m"
    VERIFY V1 C1
    SOURCE "s"
  END
  EXTENSION Fun
    KIND FUNCTION
    LEVEL CSC
    PARAMS (s: Expression)
    FORM "Fun s"
    MEANING "m"
    VERIFY V1 C1
    SOURCE "s"
  END
  EXTENSION FADE
    KIND PATTERN
    LEVEL CSC
    PARAMS (s: Expression, d: Duration)
    FORM "X s"
    MEANING "m"
    VERIFY V1 C1
    SOURCE "s"
  END
  EXTENSION Par
    KIND PATTERN
    LEVEL CSC
    PARAMS (s: Expression, d: Duration)
    FORM "Par s"
    MEANING "m"
    VERIFY V1 C9
    SOURCE "s"
  END
  EXTENSION Rip
    KIND PATTERN
    KIND PATTERN
    LEVEL CSC
    PARAMS (s: Expression)
    FORM "Rip s"
    MEANING "m"
    VERIFY V1 C1
    SOURCE "s"
  END
END

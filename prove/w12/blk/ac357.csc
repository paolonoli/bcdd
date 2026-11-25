PROFILE Segnale VERSION 0.3
  PURPOSE "p"
  EXTENSION FADE
    KIND PATTERN
    LEVEL CSC
    PARAMS (s: Expression)
    FORM "FADE s"
    MEANING "m"
    VERIFY V1 C1
    SOURCE "s"
  END
  EXTENSION FADE
    KIND PATTERN
    LEVEL CSC
    PARAMS (s: Expression)
    FORM "FADE s"
    MEANING "m"
    VERIFY V1 C1
    SOURCE "s"
  END
  EXTENSION ALWAYS
    KIND PATTERN
    LEVEL CSC
    PARAMS (s: Expression)
    FORM "ALWAYS s"
    MEANING "m"
    VERIFY V1 C1
    SOURCE "s"
  END
  EXTENSION Rid
    KIND PATTERN
    LEVEL CSC
    PARAMS (s: Expression)
    FORM "Rid s"
    MEANING "m"
    REDUCES TO pippo s
    VERIFY V1 C1
    SOURCE "s"
  END
  EXTENSION Mai
    KIND PATTERN
    LEVEL CSC
    PARAMS (p: Condition)
    FORM "Mai p"
    MEANING "m"
    REDUCES TO NEVER p
    VERIFY V1 C1
    SOURCE "s"
  END
END

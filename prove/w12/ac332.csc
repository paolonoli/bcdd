CSC T VERSION 0.1
  PURPOSE "p"
  TYPE Campione := Record {L: Real, R: Real}
  EVENT OUT frame(x: Campione)
  GUARANTEE g1: ALWAYS (frame IMPLIES LAST(frame).x.L <= 1.0)
  GUARANTEE g2: ALWAYS (frame IMPLIES LAST(frame).x.Z <= 1.0)
END

CSC T VERSION 0.1
  PURPOSE "p"
  EVENT IN accendi
  EVENT IN spegni
  SCENARIO lampeggio EXPECT ADMITTED
    @0 s accendi
    REPEAT FOREVER EVERY 1 s
    @0 s spegni
    @0.5 s accendi
END

CSC T VERSION 0.1
  PURPOSE "p"
  CAPABILITY Avvio
  DEFINE EVENT riavvio := accepted(Avvio)
  GUARANTEE g1: ALWAYS COUNT(riavvio) > 1
  SCENARIO s1 EXPECT ADMITTED
    @0 s riavvio
END

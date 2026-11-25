CSC T VERSION 0.1
  PURPOSE "p"
  EVENT IN imposta(livello: String)
  STATE volume : Integer INITIAL 0 FOLLOWS imposta.livello
END

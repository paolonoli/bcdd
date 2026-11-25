-- Prova F5 (GRAMMATICA_F1 1.20, L4-L6): g-1 resta una parola, --20 è un commento, x=-3 dà il numero -3,
-- «- 3» è un carattere estraneo, 0.5 è un numero, a.b sono tre elementi.
CSC Lettura VERSION 0.1
  PURPOSE "Lettura dei numeri con segno e dei segni nuovi"
  DEFINE A := 0.5
  DEFINE B := 5 --20
  STATE x : Integer INITIAL 0
  GUARANTEE g-1: VERBAL "Una parola con il trattino"
                 VERIFY BY JUDGEMENT "chi guarda"
  DEFINE E := - 3
  DEFINE F := a.b
  SCENARIO s1 EXPECT ADMITTED
    @0 s   x=-3
END

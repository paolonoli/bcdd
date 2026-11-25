-- Prova delle forme di ENTITY (DESIGN_F3 B.1, B.2)
ENTITY Forme VERSION 0.1
  PURPOSE "Tutte le forme dentro un'entità"
  OFFERS Alfa VERSION 0.1
  OFFERS Alfa VERSION 0.2
  OFFERS Beta
  USES Beta
  USES Gamma
  USES Gamma VERSION 0.3
  GUARANTEE g1: VERBAL "Prima promessa"
                VERIFY BY JUDGEMENT "chi guarda"
  GUARANTEE g1a DETAILS g1: VERBAL "Dettaglio della prima promessa"
                VERIFY BY INSPECTION "il registro"
  GUARANTEE g2: ALWAYS true
  GUARANTEE g3: VERBAL "Senza verifica"
  ASSUME a1: VERBAL "Una assunzione"
             VERIFY BY JUDGEMENT "chi guarda"
  GUARANTEE g4 DETAILS a1: VERBAL "Dettaglio di una assunzione"
                VERIFY BY JUDGEMENT "chi guarda"
  CAPABILITY Accendi
  STATE acceso : Boolean INITIAL false
  DEFINE N := 1
  EVENT IN USES
  COMPOSED OF
    uno : Alfa
    g1 : Beta
  COMPOSED OF
    due : Gamma
END

ENTITY Rotta
  PURPOSE "Intestazione scritta male"
  OFFERS Delta
END

ENTITY SenzaScopo VERSION 0.1
END

CSC Doppio VERSION 0.1
  PURPOSE "Una CSC con lo stesso nome di una entità"
END
ENTITY Doppio VERSION 0.1
  PURPOSE "Una entità con lo stesso nome di una CSC"
END

CSC Mista VERSION 0.1
  PURPOSE "Una CSC che contiene una forma da entità"
  OFFERS Epsilon
ENTITY Dentro VERSION 0.1
  PURPOSE "Una entità che chiude la CSC"
END

ENTITY Aperta VERSION 0.1
  PURPOSE "Una entità senza END"

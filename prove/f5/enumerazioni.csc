-- Prova F5 (GRAMMATICA_F1 1.20, G37): le quattro forme non riconosciute, un valore ripetuto, un valore uguale a uno STATE.
CSC Enumerazioni VERSION 0.1
  PURPOSE "Le enumerazioni"
  TYPE X1 := {}
  TYPE X2 := {c d}
  TYPE X3 := {e,}
  TYPE Boolean := {f, g}
  TYPE Dup := {a, a}
  STATE acceso : Boolean INITIAL false
  TYPE Fase := {inattiva, acceso}
END

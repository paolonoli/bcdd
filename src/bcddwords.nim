# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 090:1:1 Le parole chiave e riservate (GRAMMATICA_F1 1.0-beta, sezione 2.3): una sola lista per check, new, ratify e refine.
import std/sets

const
  # 022:1:1 Una sola lista di parole (sezione 2.3): la usano check, new, ratify e refine
  Keywords* = ["CSC", "VERSION", "END", "STATUS", "HYPOTHESIS", "RATIFIED", "BY", "PURPOSE",
    "CAPABILITY", "AUTONOMOUS", "EVENT", "IN", "OUT", "STATE", "INITIAL", "DEFINE", "UNDECIDED",
    "GUARANTEE", "ASSUME", "DETAILS", "VERBAL", "VERIFY", "JUDGEMENT", "INSPECTION", "SCENARIO",
    "GIVEN", "EXPECT", "ADMITTED", "REJECTED", "COMPOSED", "OF",
    "TYPE", "ENTITY", "OFFERS", "USES", "VARIANT",
    "IMPORT", "PROFILE", "BINDING", "VERIFICATION", "EXTENSION"]     # 022:1:5 da riservate a parole chiave
  ReservedLater* = ["WHILE", "ALWAYS", "EVENTUALLY", "WHENEVER", "THEN", "WITHIN",
    "AT", "ONCE", "REPEAT", "FOREVER", "AND", "OR", "NOT", "IMPLIES", "IF", "ELSE", "COUNT", "LAST",
    "TIME", "SINCE", "PREV", "WITH", "ABSENT", "PRESENT",
    "REFINED", "REFINES", "NEVER",
    "AFTER", "BEFORE", "BETWEEN", "UNTIL", "PRECEDES", "FOR", "LEAST", "ACCEPTS", "ONLY", "REQUIRES",
    "ENSURES", "RESOLVES", "CHANGED", "TRANSITION", "ON", "WHEN", "FOLLOWS", "ALL",
    "ABS", "MIN", "MAX", "LOG10", "ROUND", "FLOOR", "CEIL",
    "KIND", "LEVEL", "PARAMS", "FORM", "MEANING", "REDUCES", "TO", "SOURCE",
    "PATTERN", "SCOPE", "FUNCTION", "DECLARATION", "RELATION", "SCENARIO-FORM",     # 022:1:6 i valori di KIND
    # 022:1:8 (1.0-beta, 2.3, C-04) sedici parole riservate nuove
    "Record", "EVERY", "Name", "Type", "Event", "Condition", "Expression", "Duration", "Property",
    "BIND", "AS", "MEANS", "OBSERVES", "RESOLUTION", "USING", "TRANSLATES"]
  ReservedOut* = ["FACE", "LINK", "MAP", "REFINEMENT", "VIEW"]
  ReservedLower* = ["true", "false", "requested", "accepted", "rejected", "completed", "failed", "_"]
  CycleWords* = ["requested", "accepted", "rejected", "completed", "failed"]

let reservedSet* = block:
  var s = initHashSet[string]()
  for k in Keywords: s.incl k
  for k in ReservedLater: s.incl k
  for k in ReservedOut: s.incl k
  for k in ReservedLower: s.incl k
  s

proc isReservedWord*(w: string): bool = w in reservedSet


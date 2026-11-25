# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 007:4:1 edfin: sceglie il livello di piattaforma. Stessa interfaccia, un solo livello per eseguibile.
when defined(windows):
  import edwebview2
  export edwebview2
else:
  import edgtkfin
  export edgtkfin

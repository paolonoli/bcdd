-- Il pulsante delle scale, visto da chi lo preme.

CSC Pressione VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Chi sta sulle scale preme il pulsante per chiedere luce"

  EVENT IN   premuto

  ASSUME    a1: VERBAL "Chi preme il pulsante lo tiene premuto per almeno un decimo di secondo"
                VERIFY BY JUDGEMENT "una persona che osserva come viene premuto il pulsante"
END

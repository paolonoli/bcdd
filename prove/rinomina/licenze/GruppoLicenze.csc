-- Il sistema di licenze come entità di gruppo, ad alto livello.
-- Fonti: lettere del team licenze. Tutto ipotesi, metodo leggero.
-- Redattori dei connettori:
--   ApiLicenza               team contratti        libreria -> applicazione, dentro l'impianto
--   TrasportoLicenza         team contratti        impianto -> telefono, nel controllo remoto
--   Sessione                 team contratti        impianto -> telefono, citata e non copiata
--   RegistroTelefono         team licenze, revisione team telefono   servizio -> telefono
--   ProtocolloLicenza        team licenze          servizio -> libreria e telefono (corriere)
--   RichiestePortale         team licenze          servizio -> portale
--   PortaleCliente           team licenze          portale -> cliente (pubblico)
--   AvvisiTelefono           team telefono         telefono -> chi lo usa (pubblico)
--   AvvisiImpianto           team applicazione     applicazione -> chi sta davanti all'impianto (pubblico)
-- La persona (cliente, operatore) sta fuori, come nel controllo remoto.
ENTITY GruppoLicenze VERSION 0.1
  STATUS HYPOTHESIS
  PURPOSE "Il sistema di licenze dell'applicazione: l'impianto, il telefono custode, il servizio licenze e il portale"
  OFFERS PortaleCliente
  OFFERS AvvisiTelefono
  OFFERS AvvisiImpianto
  COMPOSED OF
    impianto : Impianto
    telefono : TelefonoCustode
    servizio : ServizioLicenze
    portale  : Portale
  GUARANTEE sl1: VERBAL "Ogni licenza è legata a un impianto e a un solo telefono custode; gli altri telefoni sono solo telecomandi"
                 VERIFY BY INSPECTION "il registro delle licenze del servizio"
  GUARANTEE sl2: VERBAL "L'impianto resta al più 180 giorni senza che il servizio ne abbia notizia: un lease vale 60 giorni e il custode ne porta tre"
                 VERIFY BY INSPECTION "le scadenze dei lease emessi per una licenza"
END

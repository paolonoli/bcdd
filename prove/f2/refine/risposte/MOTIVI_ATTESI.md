# Motivi attesi per le risposte malformate

| risposta | motivo atteso |
|---|---|
| `non_json.txt` | `non è un oggetto JSON` |
| `recintata.txt` | `non è un oggetto JSON` |
| `formato_errato.json` | `formato diverso da bcdd-refine-5` |
| `chiave_ignota.json` | `chiave sconosciuta: note` |
| `chiave_mancante.json` | `manca la chiave: proposte` |
| `chiave_doppia.json` | `chiave ripetuta: domande` |
| `tipo_errato.json` | `tipo sbagliato per domande` |
| `campo_mancante.json` | `manca la chiave: proposte[1].verifica_testo` |
| `controllo.json` | `carattere di controllo in domande[1].testo` |
| `bidi.json` | `carattere di controllo in proposte[1].testo` |
| `troppe.json` | `troppe proposte: 11, al più 10` |
| `non_utf8.txt` | `non è UTF-8 valido` |
| `troppe_domande.json` | `troppe domande: 6, al più 5` |
| `domanda_stringa.json` | `tipo sbagliato per domande[1]` |
| `domanda_senza_scelte.json` | `manca la chiave: domande[1].scelte` |
| `poche_scelte.json` | `poche scelte in domande[1]: 1, almeno 2` |
| `troppe_scelte.json` | `troppe scelte in domande[1]: 6, al più 5` |
| `scelta_vuota.json` | `scelta vuota: domande[1].scelte[2]` |
| `scelta_a_capo.json` | `scelta su più righe: domande[1].scelte[2]` |
| `scelte_ripetute.json` | `scelta ripetuta: domande[1].scelte[3]` |
| `csc_tipo.json` | `tipo sbagliato per nuove_csc` |
| `csc_stringa.json` | `tipo sbagliato per nuove_csc[1]` |
| `csc_senza_motivo.json` | `manca la chiave: nuove_csc[1].motivo` |
| `csc_chiave_ignota.json` | `chiave sconosciuta: nuove_csc[1].file` |
| `csc_nome.json` | `nome non valido: nuove_csc[1].nome` |
| `csc_motivo_vuoto.json` | `motivo vuoto: nuove_csc[1].motivo` |
| `csc_motivo_a_capo.json` | `motivo su più righe: nuove_csc[1].motivo` |
| `csc_motivo_lungo.json` | `motivo troppo lungo in nuove_csc[1].motivo: 301 caratteri, al più 300` |
| `csc_troppe.json` | `troppe CSC a parte: 4, al più 3` |
| `csc_ripetuta.json` | `nome ripetuto: nuove_csc[2].nome` |
| `senza_nuove_csc.json` | `manca la chiave: nuove_csc` |
| `sost_tipo.json` | `tipo sbagliato per sostituzioni` |
| `sost_stringa.json` | `tipo sbagliato per sostituzioni[1]` |
| `sost_chiave_ignota.json` | `chiave sconosciuta: sostituzioni[1].dettaglia` |
| `sost_campo_mancante.json` | `manca la chiave: sostituzioni[1].verifica_testo` |
| `sost_tipo_campo.json` | `tipo sbagliato per sostituzioni[1].id` |
| `sost_troppe.json` | `troppe sostituzioni: 11, al più 10` |
| `sost_controllo.json` | `carattere di controllo in sostituzioni[1].testo` |
| `senza_sostituzioni.json` | `manca la chiave: sostituzioni` |
| `formato4.json` | `manca la chiave: interfaccia` |
| `ifc_tipo.json` | `tipo sbagliato per interfaccia` |
| `ifc_voce_stringa.json` | `tipo sbagliato per interfaccia[1]` |
| `ifc_troppe.json` | `troppe righe d'interfaccia: 11, al più 10` |
| `ifc_senza_motivo.json` | `manca la chiave: interfaccia[1].motivo` |
| `ifc_chiave_ignota.json` | `chiave sconosciuta: interfaccia[1].tipo` |
| `ifc_riga_numero.json` | `tipo sbagliato per interfaccia[1].riga` |
| `ifc_motivo_vuoto.json` | `motivo vuoto: interfaccia[1].motivo` |
| `ifc_motivo_a_capo.json` | `motivo su più righe: interfaccia[1].motivo` |
| `ifc_controllo.json` | `carattere di controllo in interfaccia[1].riga` |

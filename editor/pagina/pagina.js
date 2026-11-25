// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Noli Paolo
// 003:1:1 Il JavaScript del programma: entra come WebKitUserScript, non è nella pagina. Disegna il modello
// ricevuto dal programma e manda le azioni del banco; non scrive niente da solo. Testo solo con textContent.
'use strict';
var SVGNS = 'http://www.w3.org/2000/svg';
var M = null;                // il modello del banco, come l'ultimo disegno
var corrente = null;         // il nome dell'entità sul banco
var vista = 'fuori';
var sel = null;              // {tipo: 'entita' | 'csc', nome}: che cosa mostra la scheda
var scomposte = {};          // entità scomposte a mano (vista da dentro anche senza parti)
var moduloAperto = null;
var puntato = null;          // ciò che si può togliere con un clic: {tipo: 'parte' | 'pubblico' | 'passaggio' | 'acc', ...}
var NOME = /^[A-Za-z][A-Za-z0-9_]{0,63}$/;
// 003:1:2 E-4: la lingua della pagina (it | en) e il catalogo TESTI (testi.js, caricato prima di questo file). La lingua viene da
// <html lang> alla partenza e da M.lingua a ogni modello; i testi per la persona stanno tutti nel catalogo, qui solo le chiavi.
var LINGUA = (document.documentElement.getAttribute('lang') === 'it') ? 'it' : 'en';
function T(chiave) {
  var tab = TESTI[LINGUA] || TESTI.en, s = tab[chiave];
  if (s === undefined) s = TESTI.en[chiave];
  if (s === undefined) return chiave;
  var a = arguments;
  return s.replace(/\{(\d+)\}/g, (m, n) => (a[Number(n)] === undefined ? m : String(a[Number(n)])));
}
// 003:1:2 E-4: la lingua della pagina (it | en) e il catalogo TESTI (testi.js, caricato prima di questo file). La lingua viene da
// <html lang> alla partenza e da M.lingua a ogni modello; i testi per la persona stanno tutti nel catalogo, qui solo le chiavi.
var LINGUA = (document.documentElement.getAttribute('lang') === 'it') ? 'it' : 'en';
function T(chiave) {
  var tab = TESTI[LINGUA] || TESTI.en, s = tab[chiave];
  if (s === undefined) s = TESTI.en[chiave];
  if (s === undefined) return chiave;
  var a = arguments;
  return s.replace(/\{(\d+)\}/g, (m, n) => (a[Number(n)] === undefined ? m : String(a[Number(n)])));
}
// 003:1:2 E-4: la lingua della pagina (it | en) e il catalogo TESTI (testi.js, caricato prima di questo file). La lingua viene da
// <html lang> alla partenza e da M.lingua a ogni modello; i testi per la persona stanno tutti nel catalogo, qui solo le chiavi.
var LINGUA = (document.documentElement.getAttribute('lang') === 'it') ? 'it' : 'en';
function T(chiave) {
  var tab = TESTI[LINGUA] || TESTI.en, s = tab[chiave];
  if (s === undefined) s = TESTI.en[chiave];
  if (s === undefined) return chiave;
  var a = arguments;
  return s.replace(/\{(\d+)\}/g, (m, n) => (a[Number(n)] === undefined ? m : String(a[Number(n)])));
}
// 003:1:2 E-4: la lingua della pagina (it | en) e il catalogo TESTI (testi.js, caricato prima di questo file). La lingua viene da
// <html lang> alla partenza e da M.lingua a ogni modello; i testi per la persona stanno tutti nel catalogo, qui solo le chiavi.
var LINGUA = (document.documentElement.getAttribute('lang') === 'it') ? 'it' : 'en';
function T(chiave) {
  var tab = TESTI[LINGUA] || TESTI.en, s = tab[chiave];
  if (s === undefined) s = TESTI.en[chiave];
  if (s === undefined) return chiave;
  var a = arguments;
  return s.replace(/\{(\d+)\}/g, (m, n) => (a[Number(n)] === undefined ? m : String(a[Number(n)])));
}
// 003:1:2 E-4: la lingua della pagina (it | en) e il catalogo TESTI (testi.js, caricato prima di questo file). La lingua viene da
// <html lang> alla partenza e da M.lingua a ogni modello; i testi per la persona stanno tutti nel catalogo, qui solo le chiavi.
var LINGUA = (document.documentElement.getAttribute('lang') === 'it') ? 'it' : 'en';
function T(chiave) {
  var tab = TESTI[LINGUA] || TESTI.en, s = tab[chiave];
  if (s === undefined) s = TESTI.en[chiave];
  if (s === undefined) return chiave;
  var a = arguments;
  return s.replace(/\{(\d+)\}/g, (m, n) => (a[Number(n)] === undefined ? m : String(a[Number(n)])));
}

function svuota(n) { while (n.firstChild) n.removeChild(n.firstChild); }
function el(tag, cls, testo) {
  var e = document.createElement(tag);
  if (cls) e.className = cls;
  if (testo !== undefined && testo !== null) e.textContent = testo;
  return e;
}
function sv(tag, attrs) {
  var e = document.createElementNS(SVGNS, tag);
  for (var k in attrs) e.setAttribute(k, String(attrs[k]));
  return e;
}
function svt(attrs, testo) {
  var t = sv('text', attrs);
  t.textContent = testo;
  return t;
}
function $(id) { return document.getElementById(id); }
function invia(msg) {
  window.__nim = true;
  window.webkit.messageHandlers.nimBridge.postMessage(msg);
}
function entita(nome) {
  if (!M) return null;
  for (var i = 0; i < M.entita.length; i++) if (M.entita[i].nome === nome) return M.entita[i];
  return null;
}
function cscDi(nome) {
  if (!M) return null;
  for (var i = 0; i < M.csc.length; i++) if (M.csc[i].nome === nome) return M.csc[i];
  return null;
}

// ---- tema
function applicaTema(notte) {
  document.body.classList.remove('tema-notte', 'tema-giorno');
  document.body.classList.add(notte ? 'tema-notte' : 'tema-giorno');
  $('b-tema').setAttribute('aria-pressed', notte ? 'false' : 'true');
}
function cambiaTema() {
  var notte = !document.body.classList.contains('tema-notte');
  applicaTema(notte);
  try { localStorage.setItem('bcdd-tema', notte ? 'notte' : 'giorno'); } catch (e) { /* la pagina funziona anche senza */ }
}
try { if (localStorage.getItem('bcdd-tema') === 'giorno') applicaTema(false); } catch (e) { /* idem */ }
$('b-tema').addEventListener('click', cambiaTema);

// ---- la lingua dell'interfaccia: le etichette fisse della pagina portano data-t (testo), data-t-title,
// data-t-aria, data-t-ph; il cambio lo fa il programma (azione 'lingua'), che rilancia bcdd e rimanda il modello con M.lingua
var sporco = false;          // un campo di un modulo, della casella o di Approva è stato toccato e non ancora salvato
function applicaLingua() {
  document.documentElement.setAttribute('lang', LINGUA);
  [['data-t', 'textContent'], ['data-t-title', 'title'], ['data-t-aria', 'aria-label'], ['data-t-ph', 'placeholder']].forEach((a) => {
    var l = document.querySelectorAll('[' + a[0] + ']');
    for (var i = 0; i < l.length; i++) {
      var t = T(l[i].getAttribute(a[0]));
      if (a[1] === 'textContent') l[i].textContent = t; else if (a[1] === 'title') l[i].title = t; else l[i].setAttribute(a[1], t);
    }
  });
  applicaAlbero();
  aggiornaLingua();
}
function linguaBloccata() { return completa !== null ? 'lingua_no_giro' : (sporco ? 'lingua_no_modifiche' : ''); }
function aggiornaLingua() {
  var perche = linguaBloccata();
  ['en', 'it'].forEach((l) => {
    var b = $('l-' + l);
    b.className = 'tab' + (LINGUA === l ? ' on' : '');
    b.setAttribute('aria-pressed', LINGUA === l ? 'true' : 'false');
    b.disabled = perche !== '' && LINGUA !== l;
    b.title = perche !== '' && LINGUA !== l ? T(perche) : T('lingua_aiuto');
  });
}
['en', 'it'].forEach((l) => $('l-' + l).addEventListener('click', () => { if (l !== LINGUA && linguaBloccata() === '') invia({azione: 'lingua', lingua: l}); }));
document.addEventListener('input', (ev) => {
  var t = ev.target;
  if (t && t.closest && t.closest('#modulo, #scheda-modulo, #scheda-approva, #scheda-completa')) { sporco = true; aggiornaLingua(); }
}, true);

// ---- i divisori (001:2:1): fra Entità e Banco e fra Banco e Scheda. Si ridisegna solo durante il trascinamento, la posizione non si salva
(function () {
  var col = document.querySelector('.colonne'), minL = 300, minA = 160, giu = null;
  function muoviBS(ev) {
    var rb = $('banco').getBoundingClientRect(), rs = $('scheda').getBoundingClientRect(), tot = rb.width + rs.width;
    if (tot < 2 * minL) return;
    var l = Math.max(minL, Math.min(tot - minL, ev.clientX - rb.left));
    col.style.setProperty('--quota-banco', String(Math.round(l)));
    col.style.setProperty('--quota-scheda', String(Math.round(tot - l)));
  }
  function muoviEB(ev) {
    var r = col.getBoundingClientRect(), ra = $('entita-pannello').getBoundingClientRect();
    var max = r.width - 2 * minL - 16 - 6 * 4;
    if (max < minA) return;
    col.style.setProperty('--larg-albero', Math.round(Math.max(minA, Math.min(max, ev.clientX - ra.left))) + 'px');
  }
  [['divisore', muoviBS], ['divisore-e', muoviEB]].forEach((x) => {
    var dv = $(x[0]);
    dv.addEventListener('mousedown', (ev) => { giu = x[1]; dv.classList.add('trascina'); ev.preventDefault(); });
    document.addEventListener('mouseup', () => { if (giu === x[1]) { giu = null; dv.classList.remove('trascina'); } });
  });
  document.addEventListener('mousemove', (ev) => { if (giu) giu(ev); });
})();

// ---- il banco
function statoEntitaTesto(s) { return T('stato_' + s); }
// le parole dell'interfaccia per il lato di un connettore: il valore OFFERS/USES resta solo nel ponte
function latoVoce(lato) { return T(lato === 'OFFERS' ? 'lato_voce_OFFERS' : 'lato_voce_USES'); }
function latoPart(lato) { return T(lato === 'OFFERS' ? 'lato_part_OFFERS' : 'lato_part_USES'); }

function scegliEntita(nome, chiave) {
  albSel = chiave || null;
  corrente = nome;
  puntato = null;
  sel = {tipo: 'entita', nome: nome};
  vista = 'fuori';
  chiudiModulo();
  ridisegna();
}
function scegliCsc(nome) {
  if (!cscDi(nome)) return;
  sel = {tipo: 'csc', nome: nome};
  ridisegna();
}
function selezionaScheda(tipo, nome) {
  sel = {tipo: tipo, nome: nome};
  ridisegna();
}
function punta(p, dopo) { puntato = p; dopo(); }
function puntatoValido(e) {
  if (!puntato || !e) return false;
  var i, p = puntato;
  if (p.tipo === 'parte') { for (i = 0; i < e.parti.length; i++) if (e.parti[i].parte === p.parte) return vista === 'dentro'; return false; }
  if (p.tipo === 'pubblico') return (p.lato === 'OFFERS' ? e.offre : e.usa).indexOf(p.csc) >= 0;
  if (p.tipo === 'passaggio') { for (i = 0; i < e.passaggi.length; i++) if (e.passaggi[i].csc === p.csc && e.passaggi[i].parte === p.parte && e.passaggi[i].lato === p.lato) return vista === 'dentro'; return false; }
  if (p.tipo === 'acc') { for (i = 0; i < e.accoppiamenti.length; i++) if (e.accoppiamenti[i].csc === p.csc && e.accoppiamenti[i].da === p.da && e.accoppiamenti[i].a === p.a) return vista === 'dentro'; return false; }
  return false;
}
function tipoDi(e, parte) { for (var i = 0; i < e.parti.length; i++) if (e.parti[i].parte === parte) return e.parti[i].entita; return parte; }
// la frase di conferma e il messaggio per il programma, per ciò che è puntato
function perTogliere(e) {
  var p = puntato;
  if (p.tipo === 'parte') return {testo: T('togli_parte_voce', p.parte), frase: T('togli_parte_frase', p.parte, tipoDi(e, p.parte), e.nome),
    msg: {azione: 'togli_parte', entita: e.nome, parte: p.parte}};
  if (p.tipo === 'pubblico') return {testo: T('togli_pubblico_voce', p.csc, latoVoce(p.lato)), frase: T('togli_pubblico_frase', p.csc, latoPart(p.lato), e.nome),
    msg: {azione: 'togli_pubblico', entita: e.nome, csc: p.csc, lato: p.lato}};
  if (p.tipo === 'passaggio') return {testo: T('scollega_passaggio_voce', p.csc, p.parte), frase: T('scollega_passaggio_frase', p.csc, p.parte, latoPart(p.lato), tipoDi(e, p.parte)),
    msg: {azione: 'scollega_passaggio', entita: e.nome, csc: p.csc, lato: p.lato, parte: p.parte}};
  return {testo: T('scollega_acc_voce', p.csc), frase: T(tipoDi(e, p.da) === tipoDi(e, p.a) ? 'scollega_acc_frase_una' : 'scollega_acc_frase_due', p.csc, p.da, p.a, tipoDi(e, p.da), tipoDi(e, p.a)),
    msg: {azione: 'scollega_accoppiamento', entita: e.nome, csc: p.csc, offre: p.da, usa: p.a}};
}
function apriConferma(frase, msg) {
  var m = $('modulo');
  svuota(m);
  m.hidden = false;
  moduloAperto = 'conferma';
  m.appendChild(el('div', 'titolo', frase));
  var riga = el('div', 'riga-btn');
  riga.appendChild(pulsante('f-ok', T('si'), 'primario', () => { chiudiModulo(); puntato = null; invia(msg); }));
  riga.appendChild(pulsante('f-annulla', T('no'), '', () => chiudiModulo()));
  m.appendChild(riga);
}
function haVistaDentro(e) { return e && (e.parti.length > 0 || scomposte[e.nome]); }

function pulsante(id, testo, cls, onclick, disabilitato) {
  var b = el('button', 'btn' + (cls ? ' ' + cls : ''), testo);
  b.id = id;
  if (disabilitato) b.disabled = true;
  b.addEventListener('click', onclick);
  return b;
}

// ---- l'albero delle entità: si ricalcola dal modello a ogni ridisegno, nessun file di stato
var aperti = {};           // chiave del ramo -> aperto o chiuso a mano; si ricorda finché la finestra resta aperta
var albSel = null;         // la chiave della riga scelta nell'albero (se no, la prima riga che mostra l'entità sul Banco)
var filtro = '';           // il testo della ricerca, in minuscolo
var trascinato = null;     // la riga che si sta trascinando
var nodiAlbero = {};       // chiave -> nodo, dell'ultimo disegno
var primoTrovato = null;   // il primo nodo che combacia con la ricerca (Invio lo sceglie)
var alberoChiuso = false;

function cmpNome(a, b) { var x = a.toLowerCase(), y = b.toLowerCase(); return x < y ? -1 : (x > y ? 1 : (a < b ? -1 : (a > b ? 1 : 0))); }
// «posto — Entità»; se posto ed entità hanno lo stesso nome a meno delle maiuscole, solo l'entità (8.1)
function etichettaPosto(posto, ent) { return posto.toLowerCase() === ent.toLowerCase() ? ent : posto + ' — ' + ent; }
// la molteplicità di un posto (GRAMMATICA_F1 1.20, G35): «[1 .. 4]» dopo il nome, o niente se il posto non la scrive
function moltDi(contenitore, parte) {
  var e = contenitore ? entita(contenitore) : null;
  if (e) for (var i = 0; i < e.parti.length; i++) if (e.parti[i].parte === parte && e.parti[i].molteplicita) return ' [' + e.parti[i].molteplicita + ']';
  return '';
}
function postiDi(nome) {
  var r = [];
  M.entita.forEach((e) => e.parti.forEach((p) => { if (p.entita === nome) r.push({c: e.nome, posto: p.parte}); }));
  return r;
}
function radiciAlbero() {
  var occ = {}, visti = {};
  M.entita.forEach((e) => e.parti.forEach((p) => { occ[p.entita] = true; }));
  var r = M.entita.map((e) => e.nome).filter((n) => !occ[n]).sort(cmpNome);
  function visita(n) {
    if (visti[n]) return;
    visti[n] = true;
    var e = entita(n);
    if (e) e.parti.forEach((p) => visita(p.entita));
  }
  r.forEach(visita);
  // un giro che nessuna radice raggiunge entra comunque, una volta, per nome
  M.entita.map((e) => e.nome).sort(cmpNome).forEach((n) => { if (!visti[n]) { r.push(n); visita(n); } });
  return r;
}
function nodoAlbero(entNome, posto, contenitore, antenati, chiave, prof) {
  var e = entita(entNome);
  var n = {chiave: chiave, prof: prof, tipo: posto === null ? 'entita' : 'posto', entita: entNome, posto: posto, contenitore: contenitore, mancante: !e, giro: false, figli: []};
  nodiAlbero[chiave] = n;
  if (!e) return n;
  if (antenati.indexOf(entNome) >= 0) { n.giro = true; return n; }
  var anc = antenati.concat([entNome]);
  e.parti.forEach((p) => n.figli.push(nodoAlbero(p.entita, p.parte, entNome, anc, chiave + '/' + p.parte, prof + 1)));
  return n;
}
function combacia(n, f) { return n.entita.toLowerCase().indexOf(f) >= 0 || (n.posto !== null && n.posto.toLowerCase().indexOf(f) >= 0); }
function marcaTrovati(n, f) {
  var fig = false;
  n.figli.forEach((c) => { if (marcaTrovati(c, f)) fig = true; });
  n.mio = combacia(n, f);
  n.vis = n.mio || fig;
  n.forzaApri = fig;
  return n.vis;
}
// il testo di una riga con la parte che combacia evidenziata (mark), a pezzi di testo
function scriviEtichetta(box, testo, f) {
  var k = f ? testo.toLowerCase().indexOf(f) : -1;
  if (k < 0 || testo.toLowerCase().length !== testo.length) { box.textContent = testo; return; }
  box.appendChild(document.createTextNode(testo.slice(0, k)));
  box.appendChild(el('mark', null, testo.slice(k, k + f.length)));
  box.appendChild(document.createTextNode(testo.slice(k + f.length)));
}
// gli altri posti della stessa entità: i contenitori, e fra parentesi i posti quando ce n'è più d'uno nello stesso contenitore
function altriPosti(n) {
  var perC = {}, ordine = [];
  postiDi(n.entita).forEach((q) => {
    if (q.c === n.contenitore && q.posto === n.posto) return;
    if (!(q.c in perC)) { perC[q.c] = []; ordine.push(q.c); }
    perC[q.c].push(q.posto);
  });
  return ordine.map((c) => (c === n.contenitore || perC[c].length > 1) ? c + ' (' + perC[c].join(', ') + ')' : c);
}
function chiaveMarcata(radici) {
  if (albSel && nodiAlbero[albSel]) return albSel;
  var prima = null;
  (function giu(lista) {
    lista.forEach((n) => { if (prima === null && n.entita === corrente) prima = n.chiave; if (prima === null) giu(n.figli); });
  })(radici);
  return prima;
}
function rientroAlbero() { var v = parseInt(getComputedStyle(document.documentElement).getPropertyValue('--ind-albero'), 10); return v > 0 ? v : 10; }
function ridisegnaAlbero() {
  var box = $('albero');
  svuota(box);
  nodiAlbero = {};
  primoTrovato = null;
  if (!M) return;
  $('albero-conto').textContent = M.entita.length === 1 ? T('n_entita_una') : T('n_entita', M.entita.length);
  var radici = radiciAlbero().map((nome) => nodoAlbero(nome, null, '', [], nome, 0));
  if (filtro) radici.forEach((n) => marcaTrovati(n, filtro));
  var marcata = chiaveMarcata(radici);
  var visibili = 0;
  function riga(n) {
    if (filtro && !n.vis) return;
    visibili++;
    var haFigli = n.figli.length > 0;
    var aperto = filtro ? n.forzaApri : (n.chiave in aperti ? aperti[n.chiave] : n.prof === 0);
    if (filtro && n.mio && primoTrovato === null) primoTrovato = n;
    var e = entita(n.entita);
    var testo = etichettaPosto(n.posto === null ? n.entita : n.posto, n.entita) + (n.posto === null ? '' : moltDi(n.contenitore, n.posto));
    var r = el('div', 'nodo' + (n.mancante ? ' mancante' : '') + (n.chiave === marcata ? ' on' : ''));
    r.setAttribute('role', 'treeitem');
    r.setAttribute('aria-level', String(n.prof + 1));
    if (haFigli) r.setAttribute('aria-expanded', aperto ? 'true' : 'false');
    r.setAttribute('aria-selected', n.chiave === marcata ? 'true' : 'false');
    r.tabIndex = n.chiave === marcata ? 0 : -1;
    r.draggable = true;
    r.style.paddingLeft = (n.prof * rientroAlbero() + 2) + 'px';
    r.setAttribute('data-id', 'alb:' + n.chiave);
    if (haFigli) {
      var t = el('button', 'tri', aperto ? '▾' : '▸');
      t.type = 'button';
      t.tabIndex = -1;
      t.setAttribute('aria-label', T(aperto ? 'chiudi_ramo' : 'apri_ramo'));
      t.setAttribute('data-id', 'tri:' + n.chiave);
      t.addEventListener('click', (ev) => { ev.stopPropagation(); aperti[n.chiave] = !aperto; ridisegnaAlbero(); });
      r.appendChild(t);
    } else r.appendChild(el('span', 'tri'));
    var pal = el('span', 'pallino ' + (e ? e.stato : 'mancante'));
    if (e) pal.title = statoEntitaTesto(e.stato);
    r.appendChild(pal);
    var nome = el('span', 'nome-nodo');
    scriviEtichetta(nome, testo, filtro);
    r.appendChild(nome);
    var titolo = testo;
    if (n.mancante) { r.appendChild(el('span', 'segno a-capo', T('parte_mancante'))); titolo += T('parte_mancante_titolo', n.entita); }
    if (n.giro) {
      var g = el('span', 'segno', '↻');
      g.title = T('giro_titolo', n.entita);
      r.appendChild(g);
      titolo += T('giro_sigla');
    }
    if (n.tipo === 'posto' && !n.mancante) {
      var altri = altriPosti(n);
      if (altri.length > 0) {
        var s = el('span', 'segno', '≡');
        s.title = T('anche_in', altri.join(', '));
        r.appendChild(s);
        titolo += T('anche_in_titolo', altri.join(', '));
      }
    }
    r.title = titolo;
    r.addEventListener('click', () => scegliNodo(n));
    r.addEventListener('keydown', (ev) => tastoNodo(ev, n, haFigli, aperto));
    r.addEventListener('dragstart', (ev) => {
      trascinato = n;
      if (n.tipo === 'posto') { var ff = $('fascia-fuori'); ff.style.top = $('albero-cerca').offsetTop + 'px'; ff.hidden = false; }
      try { ev.dataTransfer.setData('text/plain', n.chiave); ev.dataTransfer.effectAllowed = 'move'; } catch (x) { /* senza dati il trascinamento parte lo stesso */ }
    });
    r.addEventListener('dragend', () => { trascinato = null; togliBersagli(); $('fascia-fuori').hidden = true; });
    r.addEventListener('dragover', (ev) => {
      if (!bersaglioValido(trascinato, n)) return;
      ev.preventDefault();
      try { ev.dataTransfer.dropEffect = 'move'; } catch (x) { /* idem */ }
      if (!r.classList.contains('bersaglio')) { togliBersagli(); r.classList.add('bersaglio'); }
    });
    r.addEventListener('dragleave', () => r.classList.remove('bersaglio'));
    r.addEventListener('drop', (ev) => {
      ev.preventDefault();
      var d = trascinato;
      trascinato = null;
      togliBersagli();
      if (d && bersaglioValido(d, n)) lasciaSu(d, n);
    });
    box.appendChild(r);
    if (haFigli && aperto) n.figli.forEach(riga);
  }
  radici.forEach(riga);
  // A-8: i gruppi «Profili (N)» e «Blocchi senza connettore (N)», prima dei connettori non usati
  var gruppoVoci = (chiaveG, titolo, aiuto, voci) => {
    var visti = filtro ? voci.filter((v) => v.nome.toLowerCase().indexOf(filtro) >= 0) : voci;
    if (voci.length === 0 || (filtro && visti.length === 0)) return;
    var aperto = filtro ? true : (aperti[chiaveG] === true);
    var rg = el('div', 'nodo gruppo');
    rg.setAttribute('role', 'treeitem');
    rg.setAttribute('aria-level', '1');
    rg.setAttribute('aria-expanded', aperto ? 'true' : 'false');
    rg.tabIndex = -1;
    rg.setAttribute('data-id', 'alb:' + chiaveG);
    var tg = el('button', 'tri', aperto ? '▾' : '▸');
    tg.type = 'button';
    tg.tabIndex = -1;
    tg.setAttribute('aria-label', T(aperto ? 'chiudi_gruppo' : 'apri_gruppo'));
    tg.setAttribute('data-id', 'tri:' + chiaveG);
    rg.appendChild(tg);
    rg.appendChild(el('span', 'nome-nodo', titolo + ' (' + voci.length + ')'));
    rg.title = aiuto;
    var apriChiudi = () => { if (!filtro) { aperti[chiaveG] = !aperto; ridisegnaAlbero(); } };
    rg.addEventListener('click', apriChiudi);
    rg.addEventListener('keydown', (ev) => { if (ev.key === 'Enter' || ev.key === ' ') { apriChiudi(); ev.preventDefault(); } });
    box.appendChild(rg);
    visibili++;
    if (aperto) visti.forEach((v) => {
      var nn = {tipo: v.tipo, entita: v.id, posto: null, contenitore: '', chiave: chiaveG + '/' + v.id};
      if (filtro && primoTrovato === null) primoTrovato = nn;
      var on = sel && sel.tipo === v.tipo && sel.nome === v.id;
      var rc = el('div', 'nodo' + (on ? ' on' : ''));
      rc.setAttribute('role', 'treeitem');
      rc.setAttribute('aria-level', '2');
      rc.setAttribute('aria-selected', on ? 'true' : 'false');
      rc.tabIndex = -1;
      rc.style.paddingLeft = '16px';
      rc.setAttribute('data-id', 'alb:' + chiaveG + '/' + v.id);
      rc.appendChild(el('span', 'tri'));
      var ncs = el('span', 'nome-nodo');
      scriviEtichetta(ncs, v.nome, filtro);
      rc.appendChild(ncs);
      rc.title = v.titolo;
      rc.addEventListener('click', () => scegliNodo(nn));
      rc.addEventListener('keydown', (ev) => { if (ev.key === 'Enter' || ev.key === ' ') { scegliNodo(nn); ev.preventDefault(); } else tastoNodo(ev, nn, false, false); });
      box.appendChild(rc);
      visibili++;
    });
  };
  gruppoVoci('@pro', T('gruppo_profili'), T('gruppo_profili_aiuto'), (M.profili || []).map((p) => ({tipo: 'profilo', id: p.nome, nome: p.nome, titolo: T('profilo_versione', p.nome, p.versione)})));
  gruppoVoci('@sc', T('gruppo_senza_connettore'), T('gruppo_senza_connettore_aiuto'),
    (M.senza_connettore || []).map((b) => ({tipo: 'blocco', id: chiaveBlocco(b), nome: T(b.tipo === 'BINDING' ? 'forme_di' : 'piano_di', b.nome), titolo: motivoBlocco(b)})));
  // in fondo, i connettori che nessuna entità nomina; chiuso all'inizio, la ricerca lo apre
  var nonUsati = M.csc.filter((c) => c.offerta_da.length === 0 && c.usata_da.length === 0).map((c) => c.nome).sort(cmpNome);
  var visti2 = filtro ? nonUsati.filter((n) => n.toLowerCase().indexOf(filtro) >= 0) : nonUsati;
  if (nonUsati.length > 0 && (!filtro || visti2.length > 0)) {
    var gAperto = filtro ? true : (aperti['@csc'] === true);
    var rg = el('div', 'nodo gruppo');
    rg.setAttribute('role', 'treeitem');
    rg.setAttribute('aria-level', '1');
    rg.setAttribute('aria-expanded', gAperto ? 'true' : 'false');
    rg.tabIndex = -1;
    rg.setAttribute('data-id', 'alb:@csc');
    var tg = el('button', 'tri', gAperto ? '▾' : '▸');
    tg.type = 'button';
    tg.tabIndex = -1;
    tg.setAttribute('aria-label', T(gAperto ? 'chiudi_gruppo' : 'apri_gruppo'));
    tg.setAttribute('data-id', 'tri:@csc');
    rg.appendChild(tg);
    rg.appendChild(el('span', 'nome-nodo', T('connettori_non_usati', nonUsati.length)));
    rg.title = T('connettori_non_usati_aiuto');
    var apriChiudiG = () => { if (!filtro) { aperti['@csc'] = !gAperto; ridisegnaAlbero(); } };
    rg.addEventListener('click', apriChiudiG);
    rg.addEventListener('keydown', (ev) => { if (ev.key === 'Enter' || ev.key === ' ') { apriChiudiG(); ev.preventDefault(); } });
    box.appendChild(rg);
    visibili++;
    if (gAperto) visti2.forEach((nc) => {
      var nn = {tipo: 'csc', entita: nc, posto: null, contenitore: '', chiave: '@csc/' + nc};
      if (filtro && primoTrovato === null) primoTrovato = nn;
      var on = sel && sel.tipo === 'csc' && sel.nome === nc;
      var rc = el('div', 'nodo' + (on ? ' on' : ''));
      rc.setAttribute('role', 'treeitem');
      rc.setAttribute('aria-level', '2');
      rc.setAttribute('aria-selected', on ? 'true' : 'false');
      rc.tabIndex = -1;
      rc.style.paddingLeft = '16px';
      rc.setAttribute('data-id', 'alb:@csc/' + nc);
      rc.appendChild(el('span', 'tri'));
      var ncs = el('span', 'nome-nodo');
      scriviEtichetta(ncs, nc, filtro);
      rc.appendChild(ncs);
      rc.title = T('connettore_non_usato_titolo', nc);
      rc.addEventListener('click', () => scegliNodo(nn));
      rc.addEventListener('keydown', (ev) => { if (ev.key === 'Enter' || ev.key === ' ') { scegliNodo(nn); ev.preventDefault(); } else tastoNodo(ev, nn, false, false); });
      box.appendChild(rc);
      visibili++;
    });
  }
  if (visibili === 0) box.appendChild(el('div', 'vuoto', T(M.entita.length === 0 ? 'cartella_senza_entita' : 'nessuna_entita_con', $('albero-cerca').value.trim())));
}
// la fascia «Fuori da tutte» (8.8): c'è solo mentre si trascina un posto; lasciarci un posto apre la conferma di «Porta fuori…»
(function () {
  var f = $('fascia-fuori');
  f.addEventListener('dragover', (ev) => {
    if (!trascinato || trascinato.tipo !== 'posto') return;
    ev.preventDefault();
    try { ev.dataTransfer.dropEffect = 'move'; } catch (x) { /* idem */ }
    f.classList.add('bersaglio');
  });
  f.addEventListener('dragleave', () => f.classList.remove('bersaglio'));
  f.addEventListener('drop', (ev) => {
    ev.preventDefault();
    var d = trascinato;
    trascinato = null;
    f.classList.remove('bersaglio');
    f.hidden = true;
    if (d && d.tipo === 'posto') { scegliNodo(d); apriPortaFuori(d.contenitore, d.posto); }
  });
})();
$('albero').addEventListener('dblclick', (ev) => {
  var r = ev.target.closest ? ev.target.closest('.nodo[data-id]') : null;
  if (!r || ev.target.closest('.tri')) return;
  var id = r.getAttribute('data-id');
  if (id.indexOf('alb:') !== 0) return;
  var n = nodiAlbero[id.substring(4)];
  if (n && n.tipo === 'posto') apriNodo(n);
});
$('tela').addEventListener('dblclick', (ev) => {
  var g = ev.target.closest ? ev.target.closest('[data-id^="p-"]') : null;
  var ec = entita(corrente);
  if (!g || !ec || vista !== 'dentro') return;
  var parte = g.getAttribute('data-id').substring(2);
  for (var i = 0; i < ec.parti.length; i++) if (ec.parti[i].parte === parte) { apriNodo(nodoDelPosto(parte)); return; }
});
function togliBersagli() {
  var l = document.querySelectorAll('.nodo.bersaglio');
  for (var i = 0; i < l.length; i++) l[i].classList.remove('bersaglio');
}
// ---- aprire l'entità di un posto. Un doppio clic produce anche due clic singoli: il primo sceglie il posto come sempre,
// poi il doppio clic riscrive da solo tutto lo stato (albero, entità, posto puntato, vista, moduli): non resta niente del primo clic.
function apriNodo(n) {
  if (!n || n.tipo === 'csc' || n.tipo === 'profilo' || n.tipo === 'blocco' || n.mancante) return;
  var e = entita(n.entita);
  if (!e) return;
  chiudiModulo();
  albSel = n.chiave || null;
  corrente = n.entita;
  puntato = null;
  sel = {tipo: 'entita', nome: n.entita};
  vista = haVistaDentro(e) ? 'dentro' : 'fuori';
  ridisegna();
}
// la chiave dell'albero dell'entità che il Banco mostra: la riga scelta se è lei, oppure il suo contenitore, oppure la prima che la mostra
function chiaveCorrente() {
  if (!corrente) return null;
  var k = albSel && nodiAlbero[albSel] ? albSel : null;
  if (k) {
    if (nodiAlbero[k].entita === corrente) return k;
    var su = k.lastIndexOf('/');
    if (su > 0 && nodiAlbero[k.substring(0, su)] && nodiAlbero[k.substring(0, su)].entita === corrente) return k.substring(0, su);
  }
  if (nodiAlbero[corrente] && nodiAlbero[corrente].entita === corrente) return corrente;
  var prima = null;
  Object.keys(nodiAlbero).forEach((c) => { if (prima === null && nodiAlbero[c].entita === corrente && c.charAt(0) !== '@') prima = c; });
  return prima;
}
function nodoDelPosto(parte) {
  var kc = chiaveCorrente();
  var n = kc ? nodiAlbero[kc + '/' + parte] : null;
  if (n) return n;
  var ec = entita(corrente);
  return {tipo: 'posto', entita: ec ? tipoDi(ec, parte) : parte, posto: parte, contenitore: corrente, chiave: null, mancante: !(ec && entita(tipoDi(ec, parte)))};
}
// il percorso in alto: la catena dell'albero fino all'entità mostrata, ogni elemento (tranne l'ultimo) riporta lì
function ridisegnaPercorso(cartellaBreve) {
  var box = $('percorso');
  svuota(box);
  box.title = M.cartella + (corrente ? ' / ' + corrente : '');
  box.appendChild(el('span', null, cartellaBreve));
  if (!corrente) return;
  var kc = chiaveCorrente();
  var segs = kc ? kc.split('/') : [corrente];
  var catena = [];
  for (var i = 0; i < segs.length; i++) {
    var chiave = segs.slice(0, i + 1).join('/');
    var n = nodiAlbero[chiave];
    catena.push({nome: n ? n.entita : corrente, nodo: n});
  }
  catena.forEach((c, i) => {
    box.appendChild(el('span', 'sep', ' / '));
    if (i === catena.length - 1 || !c.nodo) box.appendChild(el('span', i === catena.length - 1 ? 'pc-ora' : null, c.nome));
    else {
      var b = el('button', 'pc', c.nome);
      b.type = 'button';
      b.setAttribute('data-id', 'pc:' + i);
      b.title = T('torna_a', c.nome);
      b.addEventListener('click', () => apriNodo(c.nodo));
      box.appendChild(b);
    }
  });
}
function scegliNodo(n) {
  if (n.tipo === 'csc') { chiudiModulo(); scegliCsc(n.entita); return; }
  if (n.tipo === 'profilo' || n.tipo === 'blocco') { chiudiModulo(); sel = {tipo: n.tipo, nome: n.entita}; ling = ''; ridisegna(); return; }
  if (n.tipo === 'entita') { scegliEntita(n.entita, n.chiave); return; }
  var c = entita(n.contenitore);
  if (!c) return;
  albSel = n.chiave;
  corrente = n.contenitore;
  vista = 'dentro';
  chiudiModulo();
  puntato = {tipo: 'parte', parte: n.posto};
  sel = {tipo: 'entita', nome: entita(n.entita) ? n.entita : n.contenitore};
  ridisegna();
}
// la tastiera sull'albero: su e giù fra le righe, destra e sinistra per aprire e chiudere, Invio sceglie
function tastoNodo(ev, n, haFigli, aperto) {
  var righe = Array.prototype.slice.call(document.querySelectorAll('#albero .nodo'));
  var i = righe.indexOf(ev.currentTarget);
  var vai = (k) => { if (k >= 0 && k < righe.length) { righe[k].tabIndex = 0; ev.currentTarget.tabIndex = -1; righe[k].focus(); } };
  if (ev.key === 'ArrowDown') { vai(i + 1); ev.preventDefault(); }
  else if (ev.key === 'ArrowUp') { vai(i - 1); ev.preventDefault(); }
  else if (ev.key === 'ArrowRight' && haFigli && !aperto && !filtro) { aperti[n.chiave] = true; ridisegnaAlbero(); ev.preventDefault(); }
  else if (ev.key === 'ArrowLeft' && haFigli && aperto && !filtro) { aperti[n.chiave] = false; ridisegnaAlbero(); ev.preventDefault(); }
  else if (ev.key === 'Enter' && n.tipo === 'posto' && !n.mancante) { apriNodo(n); ev.preventDefault(); }
  else if (ev.key === 'Enter' || ev.key === ' ') { scegliNodo(n); ev.preventDefault(); }
}
(function () {
  var c = $('albero-cerca');
  c.addEventListener('input', () => { filtro = c.value.trim().toLowerCase(); ridisegnaAlbero(); });
  c.addEventListener('keydown', (ev) => {
    if (ev.key === 'Enter') { if (filtro && primoTrovato) scegliNodo(primoTrovato); ev.preventDefault(); }
    else if (ev.key === 'Escape') { c.value = ''; filtro = ''; ridisegnaAlbero(); ev.preventDefault(); }
  });
})();
// il bottone che chiude e riapre il riquadro (a 1024 px lo spazio serve al Banco)
function applicaAlbero() {
  $('entita-pannello').hidden = alberoChiuso;
  $('divisore-e').hidden = alberoChiuso;
  var b = $('b-albero');
  b.textContent = T(alberoChiuso ? 'entita_btn_chiuso' : 'entita_btn_aperto');
  b.title = T(alberoChiuso ? 'mostra_entita' : 'nascondi_entita');
  b.setAttribute('aria-expanded', alberoChiuso ? 'false' : 'true');
}
$('b-albero').addEventListener('click', () => { alberoChiuso = !alberoChiuso; applicaAlbero(); });

// ---- mettere dentro, spostare, togliere: la pagina controlla prima di scrivere, scrive il programma
function dentroDi(radice, cercata) {
  var visti = {}, pila = [radice];
  while (pila.length) {
    var x = pila.pop();
    if (x === cercata) return true;
    if (visti[x]) continue;
    visti[x] = true;
    var e = entita(x);
    if (e) e.parti.forEach((p) => pila.push(p.entita));
  }
  return false;
}
function erroreDentro(ent, contenitore) {
  if (ent === contenitore) return T('non_dentro_se_stessa', ent);
  if (dentroDi(ent, contenitore)) return T('gia_dentro_giro', contenitore, ent);
  return '';
}
function proponiPosto(ent) { return ent.charAt(0).toLowerCase() + ent.slice(1); }
function erroreNomePosto(c, nome) {
  if (!nome) return T('scrivi_nome_posto');
  if (!NOME.test(nome)) return T('nome_non_valido', nome);
  if (M.riservate.indexOf(nome) >= 0) return T('parola_riservata', nome);
  var e = entita(c);
  if (e) for (var i = 0; i < e.parti.length; i++) if (e.parti[i].parte === nome) return T('posto_gia_esiste', c, nome);
  return '';
}
// il trascinamento: un'entità (riga in cima) si mette dentro quella su cui si lascia, un posto (riga sotto un'altra) si sposta
function bersaglioValido(d, n) {
  if (!d || !M || n.mancante) return false;
  if (d.tipo === 'entita') return erroreDentro(d.entita, n.entita) === '';
  if (n.entita === d.contenitore) return false;
  return erroreDentro(d.entita, n.entita) === '';
}
function lasciaSu(d, n) {
  scegliNodo(d);
  if (d.tipo === 'entita') apriMettiDentro(d.entita, n.entita);
  else apriSposta(d.contenitore, d.posto, n.entita);
}
function schedaVuota(titolo) {
  chiudiModulo();
  var m = $('scheda-modulo');
  svuota(m);
  notaScheda('');
  m.hidden = false;
  m.className = 'modulo';
  moduloScheda = {tipo: sel ? sel.tipo : 'entita', nome: sel ? sel.nome : ''};
  m.appendChild(el('div', 'titolo', titolo));
  return m;
}
// l'elenco per scegliere dove: le entità che vanno bene, con la ricerca
function elencoDove(m, valide, scelto, dopoScelta) {
  var cerca = campo(m, 'f-cerca', T('dove_entita'));
  var lista = el('div', 'lista-csc');
  lista.id = 'f-elenco';
  m.insertBefore(lista, cerca.parentNode.nextSibling);
  var ridisegnaLista = () => {
    svuota(lista);
    var f = cerca.value.trim().toLowerCase(), n = 0;
    valide.forEach((nome) => {
      if (f && nome.toLowerCase().indexOf(f) < 0) return;
      n++;
      var b = el('button', 'btn neutro voce-csc' + (scelto.v === nome ? ' scelto' : ''), nome);
      b.id = 'f-dove-' + nome;
      b.type = 'button';
      b.setAttribute('aria-pressed', scelto.v === nome ? 'true' : 'false');
      b.addEventListener('click', () => { scelto.v = nome; ridisegnaLista(); dopoScelta(); });
      lista.appendChild(b);
    });
    if (n === 0) lista.appendChild(el('div', 'muto piccolo', T(valide.length === 0 ? 'nessuna_entita_dove' : 'nessuna_entita_nome')));
  };
  cerca.addEventListener('input', ridisegnaLista);
  ridisegnaLista();
  return cerca;
}
// il modulo comune di «Metti dentro…» e «Sposta in…»: la frase, il nome del posto, Sì e No
function moduloPosto(m, scelto, frase, proposto, ent, invio) {
  var fr = el('div', null, '');
  fr.id = 'f-frase';
  m.appendChild(fr);
  var cp = campoV(m, 'f-posto', T('nome_del_posto'), proposto, () => '');
  var ok = null;
  var aggiorna = () => {
    fr.textContent = frase(scelto.v);
    var errC = scelto.v ? erroreDentro(ent, scelto.v) : '';
    var errN = scelto.v && !errC ? erroreNomePosto(scelto.v, cp.campo.value.trim()) : '';
    $('e-f-posto').textContent = errC || errN;
    if (ok) ok.disabled = !scelto.v || errC !== '' || errN !== '';
  };
  cp.campo.addEventListener('input', aggiorna);
  var riga = el('div', 'riga-btn');
  ok = pulsante('f-ok', T('si'), 'primario', () => {
    var nuovo = cp.campo.value.trim();
    if (!scelto.v || erroreDentro(ent, scelto.v) !== '' || erroreNomePosto(scelto.v, nuovo) !== '') { aggiorna(); return; }
    chiudiScheda();
    invia(invio(scelto.v, nuovo));
  });
  riga.appendChild(ok);
  riga.appendChild(pulsante('f-annulla', T('no'), '', () => chiudiScheda()));
  m.appendChild(riga);
  aggiorna();
  return aggiorna;
}
function apriMettiDentro(ent, dentro) {
  if (!entita(ent)) return;
  var valide = M.entita.map((e) => e.nome).filter((n) => erroreDentro(ent, n) === '').sort(cmpNome);
  var m = schedaVuota(T('metti_dentro_titolo', ent));
  var scelto = {v: dentro || ''};
  var aggiorna = null;
  if (!dentro) m.appendChild(el('div', 'muto piccolo', T('metti_dentro_nota', ent)));
  if (!dentro) elencoDove(m, valide, scelto, () => { if (aggiorna) aggiorna(); });
  aggiorna = moduloPosto(m, scelto, (c) => c ? T('metto_dentro', ent, c) : T('scegli_dentro'), proponiPosto(ent), ent,
    (c, nuovo) => ({azione: 'metti_dentro', entita: ent, dentro: c, posto: nuovo}));
}
function apriSposta(da, posto, verso) {
  var e0 = entita(da);
  if (!e0) return;
  var ent = tipoDi(e0, posto);
  if (e0.approvata) {
    var m0 = schedaVuota(T('sposta_titolo', posto));
    var f0 = el('div', null, T('righe_approvate_posto', da, posto));
    f0.id = 'f-frase';
    m0.appendChild(f0);
    var rb = el('div', 'riga-btn');
    rb.appendChild(pulsante('f-annulla', T('chiudi'), '', () => chiudiScheda()));
    m0.appendChild(rb);
    return;
  }
  var valide = M.entita.map((e) => e.nome).filter((n) => n !== da && erroreDentro(ent, n) === '').sort(cmpNome);
  var m = schedaVuota(T('sposta_titolo_lungo', posto, ent, da));
  var scelto = {v: verso || ''};
  var aggiorna = null;
  if (!verso) elencoDove(m, valide, scelto, () => { if (aggiorna) aggiorna(); });
  aggiorna = moduloPosto(m, scelto, (c) => c ? T('sposto_posto', posto, ent, da, c) : T('scegli_spostarlo'), posto, ent,
    (c, nuovo) => ({azione: 'sposta', da: da, posto: posto, a: c, nuovo: nuovo}));
}
// «Crea il connettore X» di una proposta «a parte» (10.3): lo scopo parte dalla prima frase del motivo dell'LLM, modificabile
function primaFrase(motivo) {
  var t = String(motivo || '').replace(/[\u0000-\u001f\u007f]+/g, ' ').replace(/"/g, '\'').replace(/\s+/g, ' ').trim();
  var k = t.search(/\.(\s|$)/);
  if (k >= 0) t = t.substring(0, k);
  return t.substring(0, 200).trim();
}
function apriCreaCsc(nome, motivo) {
  var m = schedaVuota(T('crea_connettore_titolo', nome));
  var cs = campoV(m, 'f-scopo', T('scopo_una_frase'), primaFrase(motivo), vFrase(200, false));
  m.appendChild(el('div', 'muto piccolo', T('motivo_llm', motivo)));
  var riga = el('div', 'riga-btn');
  riga.appendChild(pulsante('f-ok', T('crea'), 'primario', () => {
    if (!cs.verifica()) return;
    chiudiScheda();
    invia({azione: 'csc_nuova', nome: nome, scopo: cs.campo.value.trim()});
  }));
  riga.appendChild(pulsante('f-annulla', T('no'), '', () => chiudiScheda()));
  m.appendChild(riga);
  cs.verifica();
}
// «Togli il connettore…» (10.2): solo per un connettore che nessuna entità nomina; righe approvate: niente si scrive
function apriTogliCsc(nome) {
  var c = cscDi(nome);
  if (!c) return;
  var m = schedaVuota(T('togli_connettore_titolo', nome));
  var riga = el('div', 'riga-btn');
  var fr = el('div', null, T(c.approvata ? 'csc_approvata_non_si_toglie' : 'togli_connettore_frase', nome));
  fr.id = 'f-frase';
  m.appendChild(fr);
  if (c.approvata) riga.appendChild(pulsante('f-annulla', T('chiudi'), '', () => chiudiScheda()));
  else {
    riga.appendChild(pulsante('f-ok', T('si'), 'primario', () => { chiudiScheda(); invia({azione: 'togli_csc', nome: nome}); }));
    riga.appendChild(pulsante('f-annulla', T('no'), '', () => chiudiScheda()));
  }
  m.appendChild(riga);
}
// «Porta fuori…» (8.8): toglie la riga del posto dall'entità che lo contiene; se quella ha righe approvate non si scrive niente
function apriPortaFuori(da, posto) {
  var e0 = entita(da);
  if (!e0) return;
  var ent = tipoDi(e0, posto);
  var m = schedaVuota(T('porta_fuori_titolo', posto));
  var testo, riga = el('div', 'riga-btn');
  if (e0.approvata) testo = T('righe_approvate_posto', da, posto);
  else {
    testo = T('porto_fuori', ent, da, posto);
    var resta = [];
    postiDi(ent).forEach((q) => { if (!(q.c === da && q.posto === posto) && resta.indexOf(q.c) < 0) resta.push(q.c); });
    if (resta.length > 0) testo += T('resta_in', ent, resta.join(', '));
  }
  var fr = el('div', null, testo);
  fr.id = 'f-frase';
  m.appendChild(fr);
  if (e0.approvata) riga.appendChild(pulsante('f-annulla', T('chiudi'), '', () => chiudiScheda()));
  else {
    riga.appendChild(pulsante('f-ok', T('si'), 'primario', () => { chiudiScheda(); invia({azione: 'porta_fuori', entita: da, parte: posto}); }));
    riga.appendChild(pulsante('f-annulla', T('no'), '', () => chiudiScheda()));
  }
  m.appendChild(riga);
}
// «Togli l'entità…»: la conferma elenca i posti; se un'entità coinvolta ha righe approvate non si scrive niente e si dice perché
function elencoPosti(posti) {
  var perC = {}, ordine = [];
  posti.forEach((q) => { if (!(q.c in perC)) { perC[q.c] = []; ordine.push(q.c); } perC[q.c].push(q.posto); });
  return ordine.map((c) => {
    var l = perC[c];
    return T('posti_in', l.length > 1 ? l.slice(0, -1).join(', ') + T('e_congiunzione') + l[l.length - 1] : l[0], c);
  }).join(', ');
}
function apriTogliEntita(nome) {
  var e = entita(nome);
  if (!e) return;
  var posti = postiDi(nome).filter((q) => q.c !== nome);
  var m = schedaVuota(T('togli_entita_titolo', nome));
  var riga = el('div', 'riga-btn');
  var blocco = '';
  if (e.approvata) blocco = T('csc_approvata_non_si_toglie', nome);
  else for (var i = 0; i < posti.length && !blocco; i++) {
    var c = entita(posti[i].c);
    if (c && c.approvata) blocco = T('togli_entita_non_si_toglie_posto', c.nome, posti[i].posto, nome);
  }
  if (blocco) {
    var fb = el('div', null, blocco);
    fb.id = 'f-frase';
    m.appendChild(fb);
    riga.appendChild(pulsante('f-annulla', T('chiudi'), '', () => chiudiScheda()));
  } else {
    var frase;
    if (posti.length === 0) frase = T('togli_entita_frase', nome);
    else frase = T('togli_entita_posti', nome, posti.length === 1 ? T('occupa_un_posto') : T('occupa_posti', posti.length), elencoPosti(posti), T(posti.length === 1 ? 'questo_posto' : 'questi_posti'));
    var fr = el('div', null, frase);
    fr.id = 'f-frase';
    m.appendChild(fr);
    riga.appendChild(pulsante('f-ok', T('si'), 'primario', () => { chiudiScheda(); invia({azione: 'togli_entita', entita: nome}); }));
    riga.appendChild(pulsante('f-annulla', T('no'), '', () => chiudiScheda()));
  }
  m.appendChild(riga);
}
applicaAlbero();

function ridisegnaAzioni() {
  var a = $('azioni');
  svuota(a);
  var e = entita(corrente);
  a.appendChild(pulsante('b-nuova', T('b_nuova_entita'), '', () => apriModulo('nuova')));
  if (!e) { aggiungiAnnulla(a); if (inAttesa()) for (var j = 0; j < a.childNodes.length; j++) a.childNodes[j].disabled = true; return; }
  var bp = pulsante('b-pubblico', T('b_connettore_pubblico'), '', () => apriModulo('pubblico'));
  bp.title = T('b_connettore_pubblico_aiuto');
  a.appendChild(bp);
  if (vista === 'fuori') {
    var bc = pulsante('b-collega', T('b_collega'), '', () => apriModulo('collega'), M.entita.length < 2);
    bc.title = T('b_collega_aiuto');
    a.appendChild(bc);
    a.appendChild(pulsante('b-scomponi', T('b_dividi'), 'primario', () => { scomposte[e.nome] = true; vista = 'dentro'; puntato = null; ridisegna(); }));
  } else {
    a.appendChild(pulsante('b-parte', T('b_parte'), '', () => apriModulo('parte')));
    a.appendChild(pulsante('b-passa', T('b_affida'), '', () => apriModulo('passa'), e.parti.length === 0 || daPassare(e).length === 0));
    a.appendChild(pulsante('b-connettore', T('b_nuovo_conn_parti'), 'primario', () => apriModulo('connettore'), e.parti.length < 2));
  }
  if (puntatoValido(e)) {
    var t = perTogliere(e);
    a.appendChild(pulsante('b-togli', t.testo, 'togli dx', () => apriConferma(t.frase, t.msg)));
  }
  aggiungiAnnulla(a);
  if (inAttesa()) for (var k = 0; k < a.childNodes.length; k++) a.childNodes[k].disabled = true;
  azOrdine = Array.prototype.slice.call(a.children);
  adattaAzioni();
}

// ---- la barra dei bottoni del Banco sta su una riga: quelli che non ci stanno passano in «Altro…»
// Restano gli stessi bottoni, con le stesse parole, gli stessi id e gli stessi gestori: cambia solo dove stanno.
// Si lasciano per primi quelli di sotto, nell'ordine; «Nuova entità», «Dividi in parti» e «Nuovo connettore fra due parti» restano sempre in barra.
var azOrdine = [];
var azCedi = ['b-passa', 'b-togli', 'b-annulla', 'b-pubblico', 'b-collega', 'b-parte'];
var azLarg = -1;
function adattaAzioni() {
  var a = $('azioni');
  if (!a) return;
  var vecchio = $('b-altro');
  if (vecchio) vecchio.remove();
  var vm = $('menu-altro');
  if (vm) vm.remove();
  azOrdine.forEach((b) => a.appendChild(b));
  var gap = 8;
  var larghi = (lista) => lista.reduce((s, b) => s + b.offsetWidth, 0) + gap * Math.max(0, lista.length - 1);
  azLarg = a.clientWidth;
  if (azOrdine.length < 2 || larghi(azOrdine) <= azLarg) return;
  var menu = el('div', 'menu-altro');
  menu.id = 'menu-altro';
  menu.hidden = true;
  var altro = pulsante('b-altro', T('b_altro'), '', () => { menu.hidden = !menu.hidden; });
  altro.setAttribute('aria-haspopup', 'true');
  a.appendChild(altro);
  a.appendChild(menu);
  var inBarra = azOrdine.slice();
  var ceduti = [];
  for (var i = 0; i < azCedi.length && larghi(inBarra) + gap + altro.offsetWidth > azLarg; i++) {
    var b = $(azCedi[i]);
    if (!b || inBarra.indexOf(b) < 0) continue;
    inBarra.splice(inBarra.indexOf(b), 1);
    ceduti.push(b);
  }
  // se nemmeno così ci sta, passano anche gli altri, dall'ultimo
  while (inBarra.length > 1 && larghi(inBarra) + gap + altro.offsetWidth > azLarg) ceduti.push(inBarra.pop());
  azOrdine.forEach((b) => { if (ceduti.indexOf(b) >= 0) menu.appendChild(b); });
  if (!ceduti.length) { altro.remove(); menu.remove(); }
}
document.addEventListener('click', (ev) => {
  var m = $('menu-altro');
  if (m && !m.hidden && ev.target !== $('b-altro')) m.hidden = true;
});
document.addEventListener('keydown', (ev) => {
  var m = $('menu-altro');
  if (m && !m.hidden && ev.key === 'Escape') m.hidden = true;
});
if (window.ResizeObserver) new ResizeObserver(() => {
  var a = $('azioni');
  if (M && a && a.clientWidth !== azLarg) adattaAzioni();
}).observe($('azioni') || document.body);

function aggiungiAnnulla(a) {
  var d = ultimoEsito && ultimoEsito.annulla ? ultimoEsito.annulla : '';
  var b = pulsante('b-annulla', T('b_indietro'), a.querySelector('.togli') ? 'neutro' : 'neutro dx', () => apriConferma(T('conferma_annulla', d), {azione: 'annulla'}), d === '');
  if (d) b.title = d;
  // l'annullamento non è un'azione che distrugge: un bottone neutro, con la freccia che torna indietro
  var fr = sv('svg', {width: 14, height: 14, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': 2.2, 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'aria-hidden': 'true'});
  fr.appendChild(sv('path', {d: 'M9 14L4 9l5-5'}));
  fr.appendChild(sv('path', {d: 'M4 9h10.5a5.5 5.5 0 0 1 0 11H11'}));
  b.insertBefore(fr, b.firstChild);
  a.appendChild(b);
}

function daPassare(e) {
  var r = [];
  var l = [];
  for (var i = 0; i < e.offre.length; i++) l.push(['OFFERS', e.offre[i]]);
  for (i = 0; i < e.usa.length; i++) l.push(['USES', e.usa[i]]);
  for (i = 0; i < l.length; i++) {
    var tenuta = false;
    for (var k = 0; k < e.passaggi.length; k++) if (e.passaggi[k].csc === l[i][1] && e.passaggi[k].lato === l[i][0]) tenuta = true;
    if (!tenuta) r.push(l[i]);
  }
  return r;
}

// ---- i moduli delle azioni
function chiudiModulo() {
  moduloAperto = null;
  sporco = false;
  aggiornaLingua();
  var m = $('modulo');
  m.hidden = true;
  svuota(m);
}
function campo(m, id, etichetta, tipo, valore) {
  var l = el('label', null, etichetta);
  var i = el('input');
  i.id = id;
  i.type = 'text';
  if (valore) i.value = valore;
  l.appendChild(i);
  m.appendChild(l);
  return i;
}
function scelta(m, id, etichetta, opzioni) {
  var l = el('label', null, etichetta);
  var s = el('select');
  s.id = id;
  for (var i = 0; i < opzioni.length; i++) {
    var o = el('option', null, opzioni[i][1]);
    o.value = opzioni[i][0];
    s.appendChild(o);
  }
  l.appendChild(s);
  m.appendChild(l);
  return s;
}
function nomiParti(e) { return e.parti.map((p) => [p.parte, p.parte + ' : ' + p.entita]); }

// : chi offre e chi usa una CSC fra le entità della cartella, letto dal banco già calcolato
function chiHa(csc) {
  var o = [], u = [];
  for (var i = 0; i < M.entita.length; i++) {
    if (M.entita[i].offre.indexOf(csc) >= 0) o.push(M.entita[i].nome);
    if (M.entita[i].usa.indexOf(csc) >= 0) u.push(M.entita[i].nome);
  }
  return {offre: o, usa: u};
}
function descrizioneCsc(csc) {
  var h = chiHa(csc);
  return T('descrizione_csc', csc, h.offre.length ? T('offerto_da', h.offre.join(', ')) : T('nessuno_offre'), h.usa.length ? T('usato_da', h.usa.join(', ')) : T('nessuno_usa'));
}
// il lato che manca: offerta e non usata -> Usa; usata e non offerta -> Offre; altrimenti nessuna proposta
function latoProposto(csc) {
  var h = chiHa(csc);
  if (h.offre.length && !h.usa.length) return 'USES';
  if (h.usa.length && !h.offre.length) return 'OFFERS';
  return '';
}
function elencoCsc(m, campoNome, campoLato) {
  var box = el('div', 'lista-csc');
  box.id = 'f-elenco';
  if (M.csc.length === 0) box.appendChild(el('div', 'muto piccolo', T('cartella_senza_connettori')));
  for (var i = 0; i < M.csc.length; i++) {
    var nome = M.csc[i].nome;
    var b = el('button', 'btn neutro voce-csc', descrizioneCsc(nome));
    b.id = 'f-el-' + nome;
    b.type = 'button';
    b.addEventListener('click', ((n) => () => {
      campoNome.value = n;
      var l = latoProposto(n);
      if (l) campoLato.value = l;
    })(nome));
    box.appendChild(b);
  }
  return box;
}
// la regola di «Collega a…»: chi offre (m.offre) e l'altra entità che usa; ritorna {errore} oppure {frase}
function pianoCollega(m) {
  var usa = m.offre === m.entita ? m.altra : m.entita;
  var O = entita(m.offre), U = entita(usa);
  if (!O || !U || O === U) return {errore: T('scegli_due_entita')};
  var oO = O.offre.indexOf(m.csc) >= 0, oU = O.usa.indexOf(m.csc) >= 0, uO = U.offre.indexOf(m.csc) >= 0, uU = U.usa.indexOf(m.csc) >= 0;
  if (oO && uU) return {errore: T('gia_collegate', O.nome, U.nome, m.csc)};
  if (uO) return {errore: T('offre_gia', U.nome, m.csc)};
  if (oU) return {errore: T('usa_gia', O.nome, m.csc)};
  return {frase: T('collego_frase', m.entita, m.altra, m.csc, O.nome, U.nome) + (cscDi(m.csc) ? '' : T('collego_crea', m.csc))};
}
function riempi(sel, opzioni) {
  svuota(sel);
  for (var i = 0; i < opzioni.length; i++) {
    var o = el('option', null, opzioni[i][1]);
    o.value = opzioni[i][0];
    sel.appendChild(o);
  }
}

function apriModulo(quale) {
  var e = entita(corrente);
  chiudiScheda();
  var m = $('modulo');
  svuota(m);
  m.hidden = false;
  moduloAperto = quale;
  var en0 = e ? e.nome : '';
  var titoli = {nuova: T('mod_nuova'), pubblico: T('mod_pubblico', en0), parte: T('mod_parte', en0),
    passa: T('b_affida'), collega: T('mod_collega', en0), connettore: T('mod_connettore', en0)};
  m.appendChild(el('div', 'titolo', titoli[quale]));
  var err = el('div', 'errore-modulo');
  err.id = 'f-err';
  var invio = null;
  if (quale === 'nuova') {
    campo(m, 'f-nome', T('f_nome'));
    campo(m, 'f-scopo', T('scopo_una_frase'));
    invio = () => ({azione: 'nuova_entita', nome: $('f-nome').value.trim(), scopo: $('f-scopo').value.trim()});
  } else if (quale === 'pubblico') {
    var fc = campo(m, 'f-csc', T('f_nome_connettore'));
    var fl = scelta(m, 'f-lato', T('f_offre_usa'), [['OFFERS', T('f_lato_offre')], ['USES', T('f_lato_usa')]]);
    m.insertBefore(el('div', 'muto piccolo', T('f_scegline')), fc.parentNode);
    m.insertBefore(elencoCsc(m, fc, fl), fc.parentNode);
    invio = () => ({azione: 'pubblico', entita: e.nome, csc: $('f-csc').value.trim(), lato: $('f-lato').value});
  } else if (quale === 'parte') {
    campo(m, 'f-parte', T('f_nome_parte'));
    var opz = [['', T('f_entita_nuova_opz')]];
    for (var i = 0; i < M.entita.length; i++) if (M.entita[i].nome !== e.nome) opz.push([M.entita[i].nome, M.entita[i].nome]);
    var s = scelta(m, 'f-tipo', T('f_di_che_entita'), opz);
    var nuova = campo(m, 'f-nuova', T('f_nome_entita_nuova'));
    var scopo = campo(m, 'f-scopo', T('f_scopo_entita_nuova'));
    var mostra = () => { nuova.parentNode.hidden = scopo.parentNode.hidden = s.value !== ''; };
    s.addEventListener('change', mostra);
    mostra();
    invio = () => ({azione: 'parte', entita: e.nome, parte: $('f-parte').value.trim(),
      tipo: s.value !== '' ? s.value : nuova.value.trim(), scopo: s.value !== '' ? '' : scopo.value.trim()});
  } else if (quale === 'passa') {
    var dp = daPassare(e);
    scelta(m, 'f-passa', T('f_quale_connettore'), dp.map((x) => [x[0] + ' ' + x[1], x[1] + ' (' + latoPart(x[0]) + ')']));
    scelta(m, 'f-parte', T('f_a_quale_parte'), nomiParti(e));
    invio = () => {
      var q = $('f-passa').value.split(' ');
      return {azione: 'passa', entita: e.nome, csc: q[1], lato: q[0], parte: $('f-parte').value};
    };
  } else if (quale === 'collega') {
    var altre = [];
    for (var ia = 0; ia < M.entita.length; ia++) if (M.entita[ia].nome !== e.nome) altre.push([M.entita[ia].nome, M.entita[ia].nome]);
    var sb = scelta(m, 'f-altra', T('f_con_quale_entita'), altre);
    var sc = scelta(m, 'f-conn', T('f_con_quale_connettore'), []);
    var nuovoC = campo(m, 'f-csc', T('f_nome_connettore_nuovo'));
    var chi = scelta(m, 'f-chi', T('f_chi_offre'), []);
    var rifai = () => {
      var b = entita(sb.value), op = [];
      var aggiungi = (x, dove, nome) => {
        for (var q = 0; q < x.offre.length; q++) op.push([dove + ':OFFERS:' + x.offre[q], T('x_offre', x.offre[q], nome)]);
        for (q = 0; q < x.usa.length; q++) op.push([dove + ':USES:' + x.usa[q], T('x_usa', x.usa[q], nome)]);
      };
      aggiungi(e, 'a', e.nome);
      if (b) aggiungi(b, 'b', b.nome);
      op.push(['', T('un_connettore_nuovo')]);
      riempi(sc, op);
      riempi(chi, [[e.nome, T('chi_offre_voce', e.nome)], [sb.value, T('chi_offre_voce', sb.value)]]);
      var nuovo = sc.value === '';
      nuovoC.parentNode.hidden = chi.parentNode.hidden = !nuovo;
    };
    sb.addEventListener('change', rifai);
    sc.addEventListener('change', () => { nuovoC.parentNode.hidden = chi.parentNode.hidden = sc.value !== ''; });
    rifai();
    invio = () => {
      var b = sb.value, v = sc.value, csc, offre;
      if (v === '') { csc = nuovoC.value.trim(); offre = chi.value; }
      else {
        var q = v.split(':');
        csc = q[2];
        var di = q[0] === 'a' ? e.nome : b, altro = q[0] === 'a' ? b : e.nome;
        offre = q[1] === 'OFFERS' ? di : altro;
      }
      return {azione: 'collega', entita: e.nome, altra: b, csc: csc, offre: offre};
    };
  } else if (quale === 'connettore') {
    campo(m, 'f-csc', T('f_nome_connettore'));
    scelta(m, 'f-offre', T('f_chi_offre'), nomiParti(e));
    scelta(m, 'f-usa', T('f_chi_usa'), nomiParti(e));
    if (e.parti.length > 1) $('f-usa').selectedIndex = 1;
    invio = () => ({azione: 'connettore', entita: e.nome, csc: $('f-csc').value.trim(), offre: $('f-offre').value, usa: $('f-usa').value});
  }
  m.appendChild(err);
  var riga = el('div', 'riga-btn');
  var ok = pulsante('f-ok', T('ok'), 'primario', () => {
    var msg = invio();
    var campi = ['nome', 'entita', 'altra', 'csc', 'parte', 'tipo', 'offre', 'usa'];
    for (var k = 0; k < campi.length; k++) {
      if (campi[k] in msg && msg[campi[k]] !== undefined && !NOME.test(msg[campi[k]])) {
        err.textContent = T('nome_non_valido', msg[campi[k]]);
        return;
      }
    }
    if ('scopo' in msg && (msg.scopo.indexOf('"') >= 0 || (msg.azione === 'nuova_entita' && msg.scopo === '') ||
        (msg.azione === 'parte' && msg.tipo !== '' && !entita(msg.tipo) && msg.scopo === ''))) {
      err.textContent = T('serve_scopo');
      return;
    }
    if (msg.azione === 'collega') {
      var pc = pianoCollega(msg);
      if (pc.errore) { err.textContent = pc.errore; return; }
      chiudiModulo();
      apriConferma(pc.frase, msg);
      return;
    }
    chiudiModulo();
    invia(msg);
  });
  riga.appendChild(ok);
  riga.appendChild(pulsante('f-annulla', T('annulla'), '', () => chiudiModulo()));
  m.appendChild(riga);
}

// ---- la tela: il disegno si calcola sulla larghezza e sull'altezza reali del riquadro, in pixel e senza viewBox.
// I testi hanno la dimensione che dichiara il CSS (mai sotto 11 px) e le scatole si misurano sul testo che contengono.
var PAD = 16;                // margine del disegno
var SR = 7;                  // raggio di una presa (cerchio dell'offerta, semicerchio dell'uso)
var memoMisure = {};
function misura(svg, testo, cls) {
  var k = cls + '|' + testo;
  if (memoMisure[k] !== undefined) return memoMisure[k];
  var t = svt({x: 0, y: 0, 'class': cls}, testo);
  svg.appendChild(t);
  var w = t.getComputedTextLength();
  svg.removeChild(t);
  if (!(w > 0)) return testo.length * 7;           // riquadro non ancora disposto: stima, e non si ricorda
  memoMisure[k] = w;
  return w;
}
function maxLarg(svg, lista, cls) {
  var m = 0;
  for (var i = 0; i < lista.length; i++) m = Math.max(m, misura(svg, lista[i], cls));
  return m;
}
function tronca(svg, testo, cls, maxW) {
  if (misura(svg, testo, cls) <= maxW) return testo;
  var lo = 0, hi = testo.length;
  while (lo < hi) {
    var mid = (lo + hi + 1) >> 1;
    if (misura(svg, testo.slice(0, mid) + '…', cls) <= maxW) lo = mid; else hi = mid - 1;
  }
  return lo > 0 ? testo.slice(0, lo) + '…' : '…';
}
function aCapo(svg, testo, cls, maxW, maxRighe) {
  var parole = testo.split(/\s+/).filter((x) => x), righe = [], cur = '', i;
  for (i = 0; i < parole.length; i++) {
    var prova = cur ? cur + ' ' + parole[i] : parole[i];
    if (cur && misura(svg, prova, cls) > maxW) { righe.push(cur); cur = parole[i]; } else cur = prova;
  }
  if (cur) righe.push(cur);
  if (righe.length > maxRighe) {
    righe = righe.slice(0, maxRighe);
    righe[maxRighe - 1] = tronca(svg, righe[maxRighe - 1] + '…', cls, maxW);
  }
  return righe.map((r) => tronca(svg, r, cls, maxW));
}
function gruppoTela(id, onclick) {
  var g = sv('g', {'class': 'cliccabile'});
  g.setAttribute('data-id', id);
  if (onclick) g.addEventListener('click', onclick);
  return g;
}
// la presa di un connettore: cerchio pieno se lo offre, semicerchio aperto verso sinistra se lo usa (come ◗ nella legenda)
function presa(g, lato, x, y, rosso) {
  if (lato === 'OFFERS') {
    g.appendChild(sv('circle', {cx: x, cy: y, r: SR, 'stroke-width': 2.5, fill: rosso ? 'var(--surface)' : 'var(--offer)', stroke: rosso ? 'var(--bad)' : 'var(--offer)'}));
  } else {
    g.appendChild(sv('path', {d: 'M ' + x + ' ' + (y - SR) + ' A ' + SR + ' ' + SR + ' 0 0 1 ' + x + ' ' + (y + SR), fill: 'none',
      stroke: rosso ? 'var(--bad)' : 'var(--use)', 'stroke-width': 3.5}));
  }
}
function selCsc(nome) { return sel && sel.tipo === 'csc' && sel.nome === nome; }
function selEnt(nome) { return sel && sel.tipo === 'entita' && sel.nome === nome; }
function connettore(g, x, y, lato, csc, rosso, conAnello, puntabile, idParte) {
  var gc = sv('g', {'class': 'cliccabile'});
  gc.setAttribute('data-id', idParte ? 'cp-' + idParte + '-' + csc : 'c-' + csc);
  if (conAnello) gc.appendChild(sv('circle', {cx: x, cy: y, r: SR + 6, 'class': 'sel-anello'}));
  gc.appendChild(sv('circle', {cx: x, cy: y, r: SR + 6, fill: 'transparent', 'class': 'zona'}));
  presa(gc, lato, x, y, rosso);
  gc.addEventListener('click', () => { if (puntabile) puntato = {tipo: 'pubblico', csc: csc, lato: lato}; scegliCsc(csc); });
  g.appendChild(gc);
}
function ripartisci(n, centro, passo) {
  var r = [];
  for (var i = 0; i < n; i++) r.push(centro + (i - (n - 1) / 2) * passo);
  return r;
}
// una linea ad angoli retti con gli spigoli arrotondati
function percorso(pts, r) {
  var p = [pts[0]], i;
  for (i = 1; i < pts.length; i++) if (pts[i][0] !== p[p.length - 1][0] || pts[i][1] !== p[p.length - 1][1]) p.push(pts[i]);
  var d = 'M ' + p[0][0] + ' ' + p[0][1];
  for (i = 1; i < p.length - 1; i++) {
    var a = p[i - 1], b = p[i], c = p[i + 1];
    var l1 = Math.abs(b[0] - a[0]) + Math.abs(b[1] - a[1]), l2 = Math.abs(c[0] - b[0]) + Math.abs(c[1] - b[1]);
    var rr = Math.min(r, l1 / 2, l2 / 2);
    var u1 = [Math.sign(b[0] - a[0]), Math.sign(b[1] - a[1])], u2 = [Math.sign(c[0] - b[0]), Math.sign(c[1] - b[1])];
    d += ' L ' + (b[0] - u1[0] * rr) + ' ' + (b[1] - u1[1] * rr) + ' Q ' + b[0] + ' ' + b[1] + ' ' + (b[0] + u2[0] * rr) + ' ' + (b[1] + u2[1] * rr);
  }
  return d + ' L ' + p[p.length - 1][0] + ' ' + p[p.length - 1][1];
}

// Le funzioni di tracciamento ritornano {w, h}: la misura che serve davvero (più grande del riquadro = scorre)
function tracciaCartella(svg, W, H) {
  // senza un'entità scelta: le entità della cartella in vista da fuori, in una griglia che segue la larghezza
  var n = M.entita.length, i;
  if (n === 0) {
    var righe = aCapo(svg, T('cartella_vuota_tela'), 'nota', W - 2 * PAD, 3);
    for (i = 0; i < righe.length; i++) svg.appendChild(svt({x: W / 2, y: H / 2 + i * 18, 'text-anchor': 'middle', 'class': 'nota'}, righe[i]));
    return {w: W, h: H};
  }
  var nomeW = 0;
  for (i = 0; i < n; i++) nomeW = Math.max(nomeW, misura(svg, M.entita[i].nome, 'cartella-n'));
  var w = Math.max(130, Math.min(Math.max(170, nomeW + 32), 210, W - 2 * PAD)), h = 84, gap = 12;
  var cols = Math.max(1, Math.floor((W - 2 * PAD + gap) / (w + gap)));
  cols = Math.min(cols, n);
  var rows = Math.ceil(n / cols);
  var x0 = (W - (cols * w + (cols - 1) * gap)) / 2;
  var y0 = Math.max(PAD, (H - (rows * h + (rows - 1) * gap)) / 2 - 20);
  for (i = 0; i < n; i++) {
    var en = M.entita[i], x = x0 + (i % cols) * (w + gap), y = y0 + Math.floor(i / cols) * (h + gap);
    var g = gruppoTela('x-' + en.nome, ((nm) => () => scegliEntita(nm))(en.nome));
    g.appendChild(sv('rect', {x: x, y: y, width: w, height: h, rx: 12, fill: 'var(--box)', stroke: 'var(--boxb)', 'stroke-width': 2, 'class': 'bordo'}));
    g.appendChild(svt({x: x + w / 2, y: y + 20, 'text-anchor': 'middle', 'class': 'scatola-e'}, (statoEntitaTesto(en.stato)).toUpperCase()));
    g.appendChild(svt({x: x + w / 2, y: y + 40, 'text-anchor': 'middle', 'class': 'cartella-n'}, tronca(svg, en.nome, 'cartella-n', w - 24)));
    var sc = aCapo(svg, en.scopo || '', 'scatola-s', w - 24, 2);
    for (var j = 0; j < sc.length; j++) g.appendChild(svt({x: x + w / 2, y: y + 58 + j * 13, 'text-anchor': 'middle', 'class': 'scatola-s'}, sc[j]));
    svg.appendChild(g);
  }
  return {w: W, h: y0 + rows * h + (rows - 1) * gap + PAD};
}

function etichettaPubblica(svg, g, testo, x, y, ancora, csc, lato, puntabile) {
  var t = svt({x: x, y: y + 4, 'text-anchor': ancora, 'class': 'cliccabile conn'}, testo);
  t.setAttribute('data-id', 'l-' + csc);
  t.addEventListener('click', () => { if (puntabile) puntato = {tipo: 'pubblico', csc: csc, lato: lato}; scegliCsc(csc); });
  g.appendChild(t);
}

function tracciaFuori(svg, W, H, e) {
  var labMax = Math.max(70, Math.floor(W * 0.22)), i;
  var etU = e.usa.map((c) => tronca(svg, c, 'conn', labMax)), etO = e.offre.map((c) => tronca(svg, c, 'conn', labMax));
  // accanto a ogni connettore pubblico, l'entità (o le entità) che lo prende dall'altro lato
  var dal = (c, lato) => { var h = chiHa(c), l = (lato === 'USES' ? h.offre : h.usa).filter((n) => n !== e.nome); return l.length ? tronca(svg, T('con_elenco', l.join(', ')), 'nota', labMax) : ''; };
  var noU = e.usa.map((c) => dal(c, 'USES')), noO = e.offre.map((c) => dal(c, 'OFFERS'));
  var Lw = Math.max(maxLarg(svg, etU, 'conn'), maxLarg(svg, noU, 'nota')), Rw = Math.max(maxLarg(svg, etO, 'conn'), maxLarg(svg, noO, 'nota'));
  var latoS = Lw ? Lw + SR + 14 : SR + 6, latoD = Rw ? Rw + SR + 14 : SR + 6;
  var voglio = Math.max(190, misura(svg, e.nome, 'scatola') + 44);
  var w = Math.max(140, Math.min(voglio, W - 2 * PAD - latoS - latoD));
  var tot = latoS + w + latoD;
  var bx = Math.max(PAD, (W - tot) / 2) + latoS;
  var scopo = aCapo(svg, e.scopo || '', 'scatola-s', w - 40, 3);
  var nr = Math.max(e.usa.length, e.offre.length);
  var h = Math.max(104, 22 + 34 + scopo.length * 15 + 22, nr * 36 + 28);
  var by = Math.max(PAD, (H - h) / 2 - 16);
  var box = gruppoTela('x-' + e.nome, () => selezionaScheda('entita', e.nome));
  if (selEnt(e.nome)) box.appendChild(sv('rect', {x: bx - 6, y: by - 6, width: w + 12, height: h + 12, rx: 17, 'class': 'sel-anello'}));
  box.appendChild(sv('rect', {x: bx, y: by, width: w, height: h, rx: 12, fill: 'var(--box)', stroke: 'var(--boxb)', 'stroke-width': 2, 'class': 'bordo'}));
  box.appendChild(svt({x: bx + w / 2, y: by + 24, 'text-anchor': 'middle', 'class': 'scatola-e'}, T('scatola_entita')));
  box.appendChild(svt({x: bx + w / 2, y: by + 52, 'text-anchor': 'middle', 'class': 'scatola'}, tronca(svg, e.nome, 'scatola', w - 32)));
  for (i = 0; i < scopo.length; i++) box.appendChild(svt({x: bx + w / 2, y: by + 72 + i * 15, 'text-anchor': 'middle', 'class': 'scatola-s'}, scopo[i]));
  svg.appendChild(box);
  var ys = ripartisci(e.usa.length, by + h / 2, 36);
  for (i = 0; i < e.usa.length; i++) {
    connettore(svg, bx, ys[i], 'USES', e.usa[i], false, selCsc(e.usa[i]), true);
    etichettaPubblica(svg, svg, etU[i], bx - SR - 10, ys[i], 'end', e.usa[i], 'USES', true);
    if (noU[i]) svg.appendChild(svt({x: bx - SR - 10, y: ys[i] + 20, 'text-anchor': 'end', 'class': 'nota', 'data-id': 'n-' + e.usa[i]}, noU[i]));
  }
  ys = ripartisci(e.offre.length, by + h / 2, 36);
  for (i = 0; i < e.offre.length; i++) {
    connettore(svg, bx + w, ys[i], 'OFFERS', e.offre[i], false, selCsc(e.offre[i]), true);
    etichettaPubblica(svg, svg, etO[i], bx + w + SR + 10, ys[i], 'start', e.offre[i], 'OFFERS', true);
    if (noO[i]) svg.appendChild(svt({x: bx + w + SR + 10, y: ys[i] + 20, 'text-anchor': 'start', 'class': 'nota', 'data-id': 'n-' + e.offre[i]}, noO[i]));
  }
  var fine = by + h + PAD;
  if (e.usa.length === 0 && e.offre.length === 0) {
    svg.appendChild(svt({x: bx + w / 2, y: by + h + 30, 'text-anchor': 'middle', 'class': 'nota'}, T('nessun_pubblico')));
    fine += 30;
  }
  return {w: W, h: fine};
}

function tracciaDentro(svg, W, H, e) {
  var n = e.parti.length, i, k, c, r;
  var RIGA = 22, TESTA = 44;
  var labMax = Math.max(60, Math.floor(W * 0.16));
  var etU = e.usa.map((x) => tronca(svg, x, 'conn', labMax)), etO = e.offre.map((x) => tronca(svg, x, 'conn', labMax));
  var Lw = maxLarg(svg, etU, 'conn'), Rw = maxLarg(svg, etO, 'conn');
  var margS = Lw ? Lw + SR + 12 : SR + 6, margD = Rw ? Rw + SR + 12 : SR + 6;
  var fx0 = PAD + margS, fx1 = W - PAD - margD;
  // le parti, misurate sul testo che contengono (i nomi delle prese si accorciano a labW pixel)
  var P = [];
  function costruisciParti(labW) {
    P = e.parti.map((p) => {
      var u = p.usa.map((x) => tronca(svg, x, 'dentro-s', labW)), o = p.offre.map((x) => tronca(svg, x, 'dentro-s', labW));
      var wTesta = Math.max(misura(svg, p.entita, 'parte-n'), misura(svg, T('parte_et', p.parte + (p.molteplicita ? ' [' + p.molteplicita + ']' : '')), 'parte-et')) + 28;
      var wPrese = maxLarg(svg, u, 'dentro-s') + maxLarg(svg, o, 'dentro-s') + 2 * (SR + 8) + 16;
      var nr = Math.max(p.usa.length, p.offre.length);
      return {p: p, u: u, o: o, w: Math.max(120, Math.min(260, Math.max(wTesta, wPrese))), h: Math.max(76, TESTA + 14 + nr * RIGA)};
    });
  }
  costruisciParti(110);
  function idxParte(nome) { for (var j = 0; j < n; j++) if (e.parti[j].parte === nome) return j; return -1; }
  // i fili: collegamenti fra due parti e connettori pubblici affidati a una parte
  var fili = [];
  for (i = 0; i < e.accoppiamenti.length; i++) {
    var a = e.accoppiamenti[i], ia = idxParte(a.da), ib = idxParte(a.a);
    if (ia < 0 || ib < 0) continue;
    var sa = e.parti[ia].offre.indexOf(a.csc), sb = e.parti[ib].usa.indexOf(a.csc);
    if (sa < 0 || sb < 0) continue;
    fili.push({t: 'acc', csc: a.csc, da: a.da, a: a.a, ia: ia, ib: ib, sa: sa, sb: sb, lw: misura(svg, a.csc, 'filo-et')});
  }
  for (i = 0; i < e.passaggi.length; i++) {
    var ps = e.passaggi[i], ip = idxParte(ps.parte);
    if (ip < 0) continue;
    var pl = ps.lato === 'OFFERS' ? e.parti[ip].offre : e.parti[ip].usa, sp = pl.indexOf(ps.csc);
    var pub = (ps.lato === 'OFFERS' ? e.offre : e.usa).indexOf(ps.csc);
    if (sp < 0 || pub < 0) continue;
    fili.push({t: 'pas', csc: ps.csc, lato: ps.lato, parte: ps.parte, ip: ip, sp: sp, pub: pub, lw: 0});
  }
  // la disposizione per C colonne: classifica i fili, conta quanti passano in ogni corridoio, somma le larghezze
  function disponi(C) {
    var R = Math.ceil(n / C), colW = [], minCor = [], uso = [];
    for (c = 0; c < C; c++) colW[c] = 0;
    for (i = 0; i < n; i++) colW[i % C] = Math.max(colW[i % C], P[i].w);
    for (c = 0; c <= C; c++) { minCor[c] = (c === 0 || c === C) ? 44 : 64; uso[c] = 0; }
    fili.forEach((f) => {
      var cA, rA, cB, rB;
      if (f.t === 'acc') {
        cA = f.ia % C; rA = Math.floor(f.ia / C); cB = f.ib % C; rB = Math.floor(f.ib / C);
        f.sCor = cA + 1; f.eCor = cB; f.ch = -1;
        if (rA === rB && cB === cA + 1) f.tipo = 'diretto';
        else if (f.sCor === f.eCor) f.tipo = 'verticale';
        else {
          f.tipo = 'canale';
          f.ch = rB > rA ? rA + 1 : (rB < rA ? rA : (cB > cA + 1 ? rA : rA + 1));
        }
      } else if (f.lato === 'USES') {
        cB = f.ip % C; rB = Math.floor(f.ip / C);
        f.sCor = 0; f.eCor = cB; f.ch = -1;
        if (f.sCor === f.eCor) f.tipo = 'verticale'; else { f.tipo = 'canale'; f.ch = rB; }
      } else {
        cA = f.ip % C; rA = Math.floor(f.ip / C);
        f.sCor = cA + 1; f.eCor = C; f.ch = -1;
        if (f.sCor === f.eCor) f.tipo = 'verticale'; else { f.tipo = 'canale'; f.ch = rA + 1; }
      }
      f.slotS = uso[f.sCor]++;
      f.slotE = f.eCor === f.sCor ? f.slotS : uso[f.eCor]++;
      if (f.t === 'acc' && f.tipo !== 'canale') minCor[f.sCor] = Math.max(minCor[f.sCor], f.lw + 34);
    });
    var tot = 0;
    for (c = 0; c < C; c++) tot += colW[c];
    for (c = 0; c <= C; c++) { minCor[c] = Math.max(minCor[c], 26 + 9 * uso[c]); tot += minCor[c]; }
    return {C: C, R: R, colW: colW, minCor: minCor, tot: tot};
  }
  var L = {C: 1, R: 0, colW: [], minCor: [44, 44], tot: 88};
  function provaColonne() {
    for (var C0 = n; C0 >= 1; C0--) { var Lc = disponi(C0); if (Lc.tot <= fx1 - fx0 || C0 === 1) return Lc; }
  }
  if (n > 0) {
    L = provaColonne();
    if (L.C === 1 && n > 1) {                          // una colonna sola: con i nomi delle prese più corti forse ne entrano due
      costruisciParti(64);
      var L2 = provaColonne();
      if (L2.C > 1) L = L2; else { costruisciParti(110); L = provaColonne(); }
    }
  }
  var C = L.C, R = L.R;
  var extra = Math.max(0, fx1 - fx0 - L.tot);
  if (L.tot > fx1 - fx0) fx1 = fx0 + L.tot;                       // non entra nemmeno in una colonna: il disegno scorre di lato
  var Wsvg = Math.max(W, fx1 + margD + PAD);
  var cw = [], xl = [], colX = [], x = fx0;
  for (c = 0; c <= C; c++) {
    cw[c] = L.minCor[c] + extra / (C + 1);
    xl[c] = x;
    x += cw[c];
    if (c < C) { colX[c] = x; x += L.colW[c]; }
  }
  function xv(cor, slot) { return xl[cor] + 13 + slot * 9; }
  // le corsie nei canali (il canale k sta sopra la riga k): intervalli che non si toccano dividono la stessa corsia
  var corsie = [], nCors = [];
  for (k = 0; k <= R; k++) { corsie.push([]); nCors.push(0); }
  var canali = fili.filter((f) => f.tipo === 'canale');
  canali.forEach((f) => {
    var x1 = xv(f.sCor, f.slotS), x2 = xv(f.eCor, f.slotE);
    f.lo = Math.min(x1, x2); f.hi = Math.max(x1, x2);
    if (f.t === 'acc') {
      var mid = (f.lo + f.hi) / 2;
      f.lo = Math.min(f.lo, mid - f.lw / 2 - 6); f.hi = Math.max(f.hi, mid + f.lw / 2 + 6);
    }
  });
  canali.sort((p, q) => p.lo - q.lo);
  canali.forEach((f) => {
    var fine = corsie[f.ch], j = 0;
    while (j < fine.length && fine[j] + 10 > f.lo) j++;
    fine[j] = f.hi;
    f.corsia = j;
    nCors[f.ch] = Math.max(nCors[f.ch], j + 1);
  });
  // le altezze: canali (con le loro corsie) e righe
  var chH = [], rowH = [];
  for (k = 0; k <= R; k++) chH[k] = (k === 0 ? 40 : 30) + (nCors[k] ? nCors[k] * 18 + 6 : 0);
  for (r = 0; r < R; r++) {
    rowH[r] = 0;
    for (i = r * C; i < Math.min(n, (r + 1) * C); i++) rowH[r] = Math.max(rowH[r], P[i].h);
  }
  var nPub = Math.max(e.usa.length, e.offre.length);
  var alt = 0;
  for (k = 0; k <= R; k++) alt += chH[k] + (k < R ? rowH[k] : 0);
  var minAlt = n === 0 ? Math.max(180, nPub * 40 + 70) : nPub * 40 + 70;
  if (alt < minAlt) { chH[R] += minAlt - alt; alt = minAlt; }
  var fy0 = PAD + Math.max(0, (H - alt - 2 * PAD) / 2 * 0.85), fy1 = fy0 + alt;
  var chTop = [], rowTop = [], cur = fy0;
  for (k = 0; k <= R; k++) { chTop[k] = cur; cur += chH[k]; if (k < R) { rowTop[k] = cur; cur += rowH[k]; } }
  function laneY(f) { return chTop[f.ch] + (f.ch === 0 ? 34 : 12) + f.corsia * 18 + 6; }
  // il telaio dell'entità
  svg.appendChild(sv('rect', {x: fx0, y: fy0, width: fx1 - fx0, height: alt, rx: 12, fill: 'none', stroke: 'var(--frame)', 'stroke-width': 2, 'stroke-dasharray': '7 6'}));
  var tit = svt({x: fx0 + 14, y: fy0 + 24, 'class': 'nota cliccabile'}, T('vista_da_dentro_titolo', e.nome));
  tit.setAttribute('data-id', 'x-' + e.nome);
  tit.addEventListener('click', () => selezionaScheda('entita', e.nome));
  svg.appendChild(tit);
  // le parti
  var pos = [];                                       // per parte: {x, y, w, h}
  for (i = 0; i < n; i++) {
    var pc = i % C, pr = Math.floor(i / C), q = P[i], p = q.p;
    var px = colX[pc] + (L.colW[pc] - q.w) / 2, py = rowTop[pr];
    pos.push({x: px, y: py, w: q.w, h: q.h});
    var g = gruppoTela('p-' + p.parte, ((en, pa) => () => punta({tipo: 'parte', parte: pa}, () => selezionaScheda('entita', en)))(p.entita, p.parte));
    if (selEnt(p.entita)) g.appendChild(sv('rect', {x: px - 5, y: py - 5, width: q.w + 10, height: q.h + 10, rx: 15, 'class': 'sel-anello'}));
    g.appendChild(sv('rect', {x: px, y: py, width: q.w, height: q.h, rx: 10, fill: 'var(--surface)', stroke: p.trovata ? 'var(--text)' : 'var(--bad)', 'stroke-width': 2, 'class': 'bordo'}));
    g.appendChild(svt({x: px + q.w / 2, y: py + 19, 'text-anchor': 'middle', 'class': 'parte-et'}, tronca(svg, T('parte_et', p.parte + (p.molteplicita ? ' [' + p.molteplicita + ']' : '')), 'parte-et', q.w - 16)));
    g.appendChild(svt({x: px + q.w / 2, y: py + 38, 'text-anchor': 'middle', 'class': 'parte-n'}, tronca(svg, p.entita, 'parte-n', q.w - 16)));
    for (k = 0; k < p.usa.length; k++) g.appendChild(svt({x: px + SR + 8, y: py + TESTA + 14 + k * RIGA + 4, 'class': 'dentro-s'}, q.u[k]));
    for (k = 0; k < p.offre.length; k++) g.appendChild(svt({x: px + q.w - SR - 8, y: py + TESTA + 14 + k * RIGA + 4, 'text-anchor': 'end', 'class': 'dentro-s'}, q.o[k]));
    svg.appendChild(g);
  }
  function presaParte(i2, lato, idx) { var b = pos[i2]; return [lato === 'OFFERS' ? b.x + b.w : b.x, b.y + TESTA + 14 + idx * RIGA]; }
  // le prese pubbliche sul bordo del telaio: USES a sinistra, OFFERS a destra, al centro dell'altezza
  var mezzo = fy0 + alt / 2, yU = ripartisci(e.usa.length, mezzo, 40), yO = ripartisci(e.offre.length, mezzo, 40);
  // i fili, sotto le prese
  fili.forEach((f) => {
    var S, E, pts, g2, lp;
    if (f.t === 'acc') {
      S = presaParte(f.ia, 'OFFERS', f.sa); E = presaParte(f.ib, 'USES', f.sb);
    } else if (f.lato === 'USES') {
      S = [fx0, yU[f.pub]]; E = presaParte(f.ip, 'USES', f.sp);
    } else {
      S = presaParte(f.ip, 'OFFERS', f.sp); E = [fx1, yO[f.pub]];
    }
    var xs = xv(f.sCor, f.slotS), xe = xv(f.eCor, f.slotE);
    if (f.tipo === 'canale') { var ly = laneY(f); pts = [S, [xs, S[1]], [xs, ly], [xe, ly], [xe, E[1]], E]; }
    else pts = [S, [xs, S[1]], [xs, E[1]], E];
    var d = percorso(pts, 7);
    if (f.t === 'acc') {
      lp = ((x2) => () => punta({tipo: 'acc', csc: x2.csc, da: x2.da, a: x2.a}, () => scegliCsc(x2.csc)))(f);
      g2 = gruppoTela('acc-' + f.csc, lp);
      g2.appendChild(sv('path', {d: d, fill: 'none', stroke: 'var(--text)', 'stroke-width': 2.5, 'class': 'filo'}));
      g2.appendChild(sv('path', {d: d, fill: 'none', stroke: 'transparent', 'stroke-width': 14}));
      svg.appendChild(g2);
      var lx, ly2, anc = 'middle';
      if (f.tipo === 'canale') { lx = (Math.min(xs, xe) + Math.max(xs, xe)) / 2; ly2 = laneY(f) - 6; }
      else if (f.tipo === 'diretto') { lx = (xs + E[0]) / 2 + 4; ly2 = Math.min(S[1], E[1]) - 7; }
      else { lx = xs + 7; ly2 = (S[1] + E[1]) / 2 + 4; anc = 'start'; }
      var t = svt({x: lx, y: ly2, 'text-anchor': anc, 'class': 'cliccabile filo-et'}, f.csc);
      t.setAttribute('data-id', 'l-' + f.csc);
      t.addEventListener('click', lp);
      svg.appendChild(t);
    } else {
      g2 = gruppoTela('pas-' + f.csc + '-' + f.parte, ((x2) => () => punta({tipo: 'passaggio', csc: x2.csc, lato: x2.lato, parte: x2.parte}, () => scegliCsc(x2.csc)))(f));
      g2.appendChild(sv('path', {d: d, fill: 'none', stroke: 'var(--offer)', 'stroke-width': 2, 'stroke-dasharray': '6 5', 'class': 'filo'}));
      g2.appendChild(sv('path', {d: d, fill: 'none', stroke: 'transparent', 'stroke-width': 14}));
      svg.appendChild(g2);
    }
  });
  // le prese delle parti, in rosso se libere e non pubbliche
  var rossi = {};
  for (i = 0; i < e.liberi.length; i++) if (!e.liberi[i].pubblico) rossi[e.liberi[i].parte + '|' + e.liberi[i].lato + '|' + e.liberi[i].csc] = true;
  for (i = 0; i < n; i++) {
    var pp = e.parti[i];
    for (k = 0; k < pp.offre.length; k++) { var so = presaParte(i, 'OFFERS', k); connettore(svg, so[0], so[1], 'OFFERS', pp.offre[k], !!rossi[pp.parte + '|OFFERS|' + pp.offre[k]], false, false, pp.parte); }
    for (k = 0; k < pp.usa.length; k++) { var su = presaParte(i, 'USES', k); connettore(svg, su[0], su[1], 'USES', pp.usa[k], !!rossi[pp.parte + '|USES|' + pp.usa[k]], false, false, pp.parte); }
  }
  // le prese pubbliche, con il nome fuori dal telaio
  function tenuta(csc, lato) { for (var j = 0; j < e.passaggi.length; j++) if (e.passaggi[j].csc === csc && e.passaggi[j].lato === lato) return true; return false; }
  for (i = 0; i < e.usa.length; i++) {
    connettore(svg, fx0, yU[i], 'USES', e.usa[i], !tenuta(e.usa[i], 'USES'), selCsc(e.usa[i]), true);
    etichettaPubblica(svg, svg, etU[i], fx0 - SR - 10, yU[i], 'end', e.usa[i], 'USES', true);
  }
  for (i = 0; i < e.offre.length; i++) {
    connettore(svg, fx1, yO[i], 'OFFERS', e.offre[i], !tenuta(e.offre[i], 'OFFERS'), selCsc(e.offre[i]), true);
    etichettaPubblica(svg, svg, etO[i], fx1 + SR + 10, yO[i], 'start', e.offre[i], 'OFFERS', true);
  }
  if (n === 0) {
    var righe = aCapo(svg, T('nessuna_parte'), 'nota', Math.max(120, fx1 - fx0 - 40), 2);
    for (i = 0; i < righe.length; i++) svg.appendChild(svt({x: (fx0 + fx1) / 2, y: fy0 + alt / 2 + i * 18, 'text-anchor': 'middle', 'class': 'nota'}, righe[i]));
  }
  return {w: Wsvg, h: fy1 + PAD};
}

// la legenda sta sotto il disegno, in HTML (va a capo da sola) con le stesse forme del disegno
function voceLegenda(forma, testo) {
  var s = el('span', 'leg-voce');
  var g = sv('svg', {width: 28, height: 16, viewBox: '0 0 28 16'});
  if (forma === 'offre') g.appendChild(sv('circle', {cx: 14, cy: 8, r: 5.5, fill: 'var(--offer)', stroke: 'var(--offer)', 'stroke-width': 2}));
  else if (forma === 'usa') g.appendChild(sv('path', {d: 'M 14 2.5 A 5.5 5.5 0 0 1 14 13.5', fill: 'none', stroke: 'var(--use)', 'stroke-width': 3.5}));
  else if (forma === 'filo') g.appendChild(sv('path', {d: 'M 2 8 L 26 8', stroke: 'var(--text)', 'stroke-width': 2.5}));
  else if (forma === 'pas') g.appendChild(sv('path', {d: 'M 2 8 L 26 8', stroke: 'var(--offer)', 'stroke-width': 2, 'stroke-dasharray': '5 4'}));
  else g.appendChild(sv('circle', {cx: 14, cy: 8, r: 5.5, fill: 'var(--surface)', stroke: 'var(--bad)', 'stroke-width': 2.5}));
  s.appendChild(g);
  s.appendChild(el('span', null, testo));
  return s;
}
function ridisegnaLegenda(e) {
  var l = $('legenda-tela');
  svuota(l);
  l.hidden = !e;
  if (!e) return;
  l.appendChild(voceLegenda('offre', T('leg_offre')));
  l.appendChild(voceLegenda('usa', T('leg_usa')));
  if (vista === 'dentro') {
    l.appendChild(voceLegenda('filo', T('leg_filo')));
    l.appendChild(voceLegenda('pas', T('leg_pas')));
    l.appendChild(voceLegenda('rosso', T('leg_rosso')));
  }
}

function ridisegnaTela() {
  var t = $('tela'), s = $('tela-scroll');
  svuota(t);
  if (!M) return;
  var e = entita(corrente);
  ridisegnaLegenda(e);
  var W = s.offsetWidth - 2, H = s.offsetHeight - 2;
  if (W < 200 || H < 100) return;                     // il riquadro non è ancora disposto
  if (Object.keys(memoMisure).length > 3000) memoMisure = {};
  function una(w) {
    svuota(t);
    var svg = sv('svg', {width: w, height: H});
    t.appendChild(svg);
    var m = !e ? tracciaCartella(svg, w, H) : (vista === 'dentro' ? tracciaDentro(svg, w, H, e) : tracciaFuori(svg, w, H, e));
    svg.setAttribute('width', Math.max(w, m.w));
    svg.setAttribute('height', Math.max(H, m.h));
    return m;
  }
  var m = una(W);
  if (m.h > H) una(W - 12);                           // comparirà la barra verticale: il disegno si ricalcola senza di essa
}
(function () {
  var s = $('tela-scroll');
  if (window.ResizeObserver) new ResizeObserver(() => { if (M) ridisegnaTela(); }).observe(s);
})();

// ---- la scheda e lo stato
function ridisegnaScheda() {
  var nome = '', tipo = '', lati = '';
  var chiave = chiaveSel();
  if (chiave !== chiaveScheda) { chiaveScheda = chiave; chiudiScheda(); appr = null; }
  var base = sel ? oggettoDi(sel.tipo, sel.nome) : null;
  ridisegnaLinguette(base && sel.tipo === 'csc' ? base : null);
  var oggetto = oggettoSel();
  if (oggetto && esBlocco(oggetto)) {
    nome = titoloBlocco(oggetto);
    tipo = tipoBlocco(oggetto);
    lati = latiBlocco(oggetto);
  } else if (oggetto && sel.tipo === 'entita') {
    nome = oggetto.nome;
    tipo = T(oggetto.nome === corrente ? 'tipo_entita_nera' : 'tipo_entita_parte');
    var s = [];
    oggetto.offre.forEach((x) => s.push(T('x_offre_lato', x)));
    oggetto.usa.forEach((x) => s.push(T('x_usa_lato', x)));
    lati = s.length ? T('espone', s.length > 1 ? s.slice(0, -1).join(', ') + T('e_congiunzione') + s[s.length - 1] : s[0]) : T('non_espone');
  } else if (oggetto) {
    nome = oggetto.nome;
    tipo = T('tipo_csc');
    lati = T('lati_csc', oggetto.offerta_da.length ? oggetto.offerta_da.join(', ') : T('nessuno'), oggetto.usata_da.length ? oggetto.usata_da.join(', ') : T('nessuno'));
  }
  $('scheda-tipo').textContent = tipo;
  $('scheda-tipo').title = tipo;
  $('scheda-nome').textContent = nome;
  $('scheda-lati').textContent = lati;
  var vn = $('scheda-vers');
  vn.hidden = !(oggetto && oggetto.scheda.versione_nuova);
  vn.textContent = vn.hidden ? '' : T('versione_nuova');
  ridisegnaAzioniScheda(oggetto);
  var c = $('scheda-righe');
  svuota(c);
  if (oggetto) {
    for (var i = 0; i < oggetto.scheda.righe.length; i++) c.appendChild(creaRiga(oggetto, oggetto.scheda.righe[i]));
  } else {
    c.appendChild(el('div', 'vuoto', T('fai_clic_scheda')));
  }
  ridisegnaRapporto(oggetto);
  ridisegnaCompleta();
  ridisegnaApprova();
}

// ---- la scheda che scrive: moduli, mai la grammatica
var chiaveScheda = '';
var moduloScheda = null;     // {tipo, nome}: la scheda a cui appartiene il modulo aperto
function tipiD() { return [['Boolean', T('tipo_bool')], ['Integer', T('tipo_int')], ['Real', T('tipo_real')], ['String', T('tipo_str')], ['Duration', T('tipo_dur')]]; }

function notaScheda(testo) {
  var n = $('scheda-nota');
  n.hidden = !testo;
  n.textContent = testo || '';
}
function chiudiScheda() {
  moduloScheda = null;
  sporco = false;
  aggiornaLingua();
  var m = $('scheda-modulo');
  m.hidden = true;
  svuota(m);
  notaScheda('');
}
function oggettoDi(tipo, nome) {
  if (tipo === 'entita') return entita(nome);
  if (tipo === 'csc') return cscDi(nome);
  if (tipo === 'profilo') return profiloDi(nome);
  if (tipo === 'blocco') return bloccoSenzaCsc(nome);
  return null;
}
function oggettoSel() {
  if (!sel) return null;
  return bloccoAttivo() || oggettoDi(sel.tipo, sel.nome);
}
function dichiarazioni() {
  var o = oggettoSel();
  return o ? o.scheda.dich : [];
}
function lunghezza(s) { return Array.from(s).length; }   // i caratteri, non i byte: lo stesso conto di edazioni.nim (runeLen)
function vFrase(max, vuotoOk) {
  return (s) => {
    var t = s.trim();
    if (!t) return vuotoOk ? '' : T('v_scrivi_frase');
    if (lunghezza(t) > max) return T('v_troppo_lunga', max);
    if (t.indexOf('"') >= 0) return T('v_virgolette');
    if (/[\u0000-\u001f\u007f]/.test(t)) return T('v_una_riga');
    return '';
  };
}
function vNomeD(altri) {
  return (s) => {
    if (!s) return T('scrivi_nome');
    if (!NOME.test(s)) return T('nome_non_valido', s);
    if (M.riservate.indexOf(s) >= 0) return T('parola_riservata', s);
    if (s === 's' || s === 'ms') return T('unita_tempo', s);
    if (altri.indexOf(s) >= 0) return T('nome_gia_esiste');
    return '';
  };
}
function vValore(tipo, v, unita) {
  var num = /^[0-9]+(\.[0-9]+)?$/;
  var numS = /^-?[0-9]+(\.[0-9]+)?$/;   // con segno (GRAMMATICA_F1 1.20): solo Integer e Real; il tempo resta senza segno
  if (tipo === 'Boolean') return v === 'true' || v === 'false' ? '' : T('v_scegli_si_no');
  if (tipo === 'Integer') return /^-?[0-9]{1,18}$/.test(v) ? '' : T('v_intero');
  if (tipo === 'Real') return numS.test(v) && v.length <= 24 ? '' : T('v_reale');
  if (tipo === 'String') return v.indexOf('"') >= 0 ? T('v_virgolette') :
    (/[\u0000-\u001f\u007f]/.test(v) ? T('v_una_riga') : (lunghezza(v) > 400 ? T('v_troppo_lungo_400') : ''));
  if (tipo === 'Duration') return !num.test(v) || v.length > 24 ? T('v_numero_60') : (unita !== 's' && unita !== 'ms' ? T('v_scegli_unita') : '');
  return T('v_scegli_tipo');
}
// un campo di testo con il suo controllo sotto: il messaggio compare mentre si scrive e di nuovo prima di salvare
function campoV(m, id, etichetta, valore, controlla) {
  var l = el('label', null, etichetta);
  var i = el('input');
  i.id = id;
  i.type = 'text';
  if (valore) i.value = valore;
  l.appendChild(i);
  var e = el('div', 'campo-err');
  e.id = 'e-' + id;
  l.appendChild(e);
  var verifica = () => { var t = controlla(i.value); e.textContent = t; return t === ''; };
  i.addEventListener('input', verifica);
  m.appendChild(l);
  return {campo: i, riga: l, verifica: verifica};
}

function ridisegnaAzioniScheda(oggetto) {
  var a = $('scheda-azioni');
  svuota(a);
  if (!oggetto) return;
  if (esBlocco(oggetto)) { azioniBlocco(a, oggetto); return; }
  var ec0 = entita(corrente);
  if (ec0 && puntato && puntato.tipo === 'parte' && puntatoValido(ec0) && sel && sel.tipo === 'entita') {
    var ent0 = tipoDi(ec0, puntato.parte), pp0 = puntato.parte;
    if (sel.nome === ent0 || !entita(ent0)) {
      var mancaE = !entita(ent0);
      var bo = pulsante('b-apri', T('b_apri', ent0), '', () => apriNodo(nodoDelPosto(pp0)), mancaE);
      bo.title = mancaE ? T('b_apri_manca', ent0) : T('b_apri_aiuto', ent0, pp0);
      a.appendChild(bo);
    }
  }
  a.appendChild(pulsante('b-completa', T('b_completa'), 'accento', avviaCompleta, completa !== null));
  var gm = el('span', 'gruppo-modello');
  gm.setAttribute('role', 'group');
  gm.setAttribute('aria-label', T('modello_gruppo'));
  gm.title = T('modello_aiuto');
  ['veloce', 'accurato'].forEach((k) => {
    var bm = el('button', 'scelta' + (modelloScelto === k ? ' on' : ''), T('modello_nome_' + k));
    bm.id = 'm-' + k;
    bm.type = 'button';
    bm.title = T('modello_aiuto');
    bm.setAttribute('aria-pressed', modelloScelto === k ? 'true' : 'false');
    bm.disabled = completa !== null;
    bm.addEventListener('click', () => { modelloScelto = k; ridisegna(); });
    gm.appendChild(bm);
  });
  a.appendChild(gm);
  a.appendChild(pulsante('b-scopo', T('b_scopo'), '', () => {
    var d = null, ds = dichiarazioni();
    for (var i = 0; i < ds.length; i++) if (ds[i].genere === 'scopo') d = ds[i];
    apriModuloScheda('scopo', d);
  }));
  a.appendChild(pulsante('b-promessa', T('b_promessa'), '', () => apriModuloScheda('promessa', null)));
  if (sel.tipo === 'csc') {
    a.appendChild(pulsante('b-ipotesi', T('b_ipotesi'), '', () => apriModuloScheda('ipotesi', null)));
    a.appendChild(pulsante('b-evento', T('b_evento'), '', () => apriModuloScheda('evento', null)));
    a.appendChild(pulsante('b-stato', T('b_stato'), '', () => apriModuloScheda('stato', null)));
    var nomeCsc0 = sel.nome;
    a.appendChild(pulsante('b-forme-nuove', T('b_forme'), '', () => apriNuoveForme(nomeCsc0)));
    a.appendChild(pulsante('b-piano-nuovo', T('b_piano'), '', () => apriNuovoPiano(nomeCsc0)));
  }
  if (sel.tipo === 'csc') {
    var bi = pulsante('b-approva-intero', T('b_approva_intero'), '', () => {
      chiudiScheda();
      appr = {chiave: sel.tipo + ':' + sel.nome, modo: 'intero', scelte: {}, ids: [], numero: ''};
      ridisegna();
    }, oggetto.scheda.intero === null);
    if (oggetto.scheda.intero === null) bi.title = T('intestazione_gia');
    a.appendChild(bi);
  }
  if (oggetto.scheda.nv) {
    var bv = pulsante('b-versione', T('b_nuova_versione'), '', () => apriVersione(oggettoSel()));
    bv.title = T('b_nuova_versione_aiuto');
    a.appendChild(bv);
  }
  if (sel.tipo === 'entita') {
    // : mettere dentro, spostare il posto scelto sul Banco, togliere l'entità
    var nomeS = sel.nome;
    var possibili = M.entita.filter((x) => erroreDentro(nomeS, x.nome) === '').length;
    var bm = pulsante('b-metti', T('b_metti_dentro'), '', () => apriMettiDentro(nomeS, ''), possibili === 0);
    bm.title = T('b_metti_aiuto', nomeS);
    a.appendChild(bm);
    var ec = entita(corrente);
    if (ec && puntato && puntato.tipo === 'parte' && puntatoValido(ec) && (nomeS === tipoDi(ec, puntato.parte) || !entita(tipoDi(ec, puntato.parte)))) {
      var pp = puntato.parte, cc = ec.nome;
      var bs = pulsante('b-sposta', T('b_sposta'), '', () => apriSposta(cc, pp, ''));
      bs.title = T('b_sposta_aiuto', pp, cc);
      a.appendChild(bs);
      var bf = pulsante('b-porta-fuori', T('b_porta_fuori'), '', () => apriPortaFuori(cc, pp));
      bf.title = T('b_porta_fuori_aiuto', pp, cc);
      a.appendChild(bf);
    }
    a.appendChild(pulsante('b-togli-entita', T('b_togli_entita'), 'togli', () => apriTogliEntita(nomeS)));
  } else if (sel.tipo === 'csc' && oggetto.offerta_da && oggetto.offerta_da.length === 0 && oggetto.usata_da.length === 0) {
    var nomeCsc = sel.nome;
    var bt = pulsante('b-togli-csc', T('b_togli_csc'), 'togli', () => apriTogliCsc(nomeCsc));
    bt.title = T('b_togli_csc_aiuto', nomeCsc);
    a.appendChild(bt);
  }
  if (completa !== null) for (var k = 0; k < a.childNodes.length; k++) a.childNodes[k].disabled = true;
}

function GIA_APPROVATA() { return T('gia_approvata'); }
function clicRiga(oggetto, r) {
  if (r.g >= 0) {
    var d = oggetto.scheda.dich[r.g];
    if (d.contratto) { chiudiScheda(); notaScheda(GIA_APPROVATA()); return; }
    apriModuloScheda(d.genere, d);
    return;
  }
  if (r.nota === 'testo') { apriCasella(oggetto, r.ca, r.cb); return; }
  chiudiScheda();
  notaScheda(r.nota === 'contratto' ? GIA_APPROVATA() : T('riga_dal_banco'));
}

// ---- la casella di testo: dove i moduli non arrivano, si cambia il testo delle righe di una dichiarazione
var MAX_CASELLA = 8000;
function apriCasella(o, da, a, iniz, titolo) {
  var testi = [];
  for (var n = da; n <= a; n++) {
    var t = null;
    for (var i = 0; i < o.scheda.righe.length; i++) if (o.scheda.righe[i].n === n) t = o.scheda.righe[i].testo;
    if (t === null) return;
    testi.push(t);
  }
  chiudiModulo();
  var m = $('scheda-modulo');
  svuota(m);
  notaScheda('');
  m.hidden = false;
  m.className = 'modulo';
  moduloScheda = {tipo: sel.tipo, nome: sel.nome};
  var base = {tipo: sel.tipo, nome: sel.nome};
  var prima = testi.join('\n');
  var chi = titolo || ((da === a ? T('casella_riga', da, esBlocco(o) ? titoloBlocco(o) : o.nome) : T('casella_righe', da, a, esBlocco(o) ? titoloBlocco(o) : o.nome)));
  m.appendChild(el('div', 'titolo', chi));
  var l = el('label', null, T('casella_testo'));
  var ta = el('textarea', 'casella');
  ta.id = 'f-testo';
  ta.rows = Math.min(14, Math.max(2, testi.length + 1));
  ta.spellcheck = false;
  ta.value = iniz !== undefined ? iniz : prima;
  l.appendChild(ta);
  var err = el('div', 'campo-err');
  err.id = 'e-f-testo';
  l.appendChild(err);
  m.appendChild(l);
  // A-3: il testo colorato si vede sotto, in anteprima, mentre si scrive; A-6: l'avviso della riga che chiede un seguito
  var seguito = el('div', 'cc-nota');
  seguito.id = 'f-seguito';
  m.appendChild(seguito);
  var anteprima = el('div', 'codice anteprima');
  anteprima.id = 'f-anteprima';
  m.appendChild(anteprima);
  var primaRiga = o.scheda.righe.length ? o.scheda.righe[0].n : 0;
  var controlla = () => {
    var t = '';
    if (ta.value.length > MAX_CASELLA) t = T('casella_troppo_lungo', MAX_CASELLA);
    else if (da === primaRiga && !esBlocco(o)) {
      var mm = /^\s*(?:CSC|ENTITY)\s+(\S+)/.exec(ta.value.split('\n')[0]);
      if (mm && mm[1] !== o.nome) t = T('casella_nome_cambiato', o.file);
    }
    err.textContent = t;
    var sg = chiedeSeguito(ta.value);
    seguito.textContent = sg ? T('casella_seguito', sg) : '';
    svuota(anteprima);
    coloraTesto(ta.value).forEach((segs) => { var d = el('div'); if (segs.length === 1 && segs[0][0] === '') d.textContent = ' '; else spanSegmenti(d, segs); anteprima.appendChild(d); });
    return ta.value.length <= MAX_CASELLA;
  };
  ta.addEventListener('input', controlla);
  var riga = el('div', 'riga-btn');
  riga.appendChild(pulsante('f-ok', T('b_scrivi'), 'primario', () => {
    if (!controlla()) return;
    var testo = ta.value;
    if (testo === prima) { chiudiScheda(); notaScheda(T('testo_non_cambiato')); return; }
    var msg = esBlocco(o) ? {azione: 'blocco_scrivi', 'file': o.file, da: String(da), a: String(a), prima: prima, testo: testo} :
      {azione: 'casella_scrivi', tipo: base.tipo, nome: base.nome, da: String(da), a: String(a), prima: prima, testo: testo};
    if (testo.trim() === '') {
      confermaScheda(da === a ? T('casella_togli_una', da, esBlocco(o) ? titoloBlocco(o) : o.nome) : T('casella_togli_piu', da, a, esBlocco(o) ? titoloBlocco(o) : o.nome), msg);
    } else {
      chiudiScheda();
      invia(msg);
    }
  }));
  riga.appendChild(pulsante('f-annulla', T('annulla'), '', () => chiudiScheda()));
  m.appendChild(riga);
  controlla();
}

// ---- Nuova versione: una cosa approvata non si cambia, se ne prepara una versione nuova nello stesso file
var NUMERO_VERSIONE = /^[0-9]{1,6}(\.[0-9]{1,6})*$/;
function apriVersione(o) {
  var nv = o.scheda.nv;
  if (!nv) return;
  chiudiModulo();
  var m = $('scheda-modulo');
  svuota(m);
  notaScheda('');
  m.hidden = false;
  m.className = 'modulo';
  moduloScheda = {tipo: sel.tipo, nome: sel.nome};
  var base = {tipo: sel.tipo, nome: sel.nome};
  m.appendChild(el('div', 'titolo', T('versione_titolo', o.nome)));
  m.appendChild(el('div', 'muto piccolo', T(nv.intestazione ? 'versione_nota_int' : 'versione_nota')));
  var cf = campoV(m, 'f-frase', T('che_cosa_cambia'), '', (s) => {
    var t = s.trim();
    if (!t) return T('v_scrivi_cambia');
    if (lunghezza(t) > 200) return T('v_troppo_lunga_200');
    if (/[\u0000-\u001f\u007f]/.test(t)) return T('v_una_riga');
    return '';
  });
  var cv = campoV(m, 'f-versione', T('numero_versione'), nv.proposta, (s) => {
    var t = s.trim();
    if (!NUMERO_VERSIONE.test(t) || t.length > 24) return T('v_numero_versione');
    if (t === nv.attuale) return T('v_numero_attuale', nv.attuale);
    return '';
  });
  var scelte = {};
  if (nv.righe.length > 0) {
    m.appendChild(el('div', null, T('rimetti_da_approvare')));
    var lista = el('div', 'ap-elenco');
    nv.righe.forEach((x) => {
      var lb = el('label', 'ap-voce');
      var c = el('input');
      c.type = 'checkbox';
      c.id = 'v-sel-' + x.id;
      c.addEventListener('change', () => { scelte[x.id] = c.checked; });
      lb.appendChild(c);
      lb.appendChild(el('span', null, T(x.genere === 'promessa' ? 'voce_promessa' : 'voce_presupposto', x.id, x.frase ? ': «' + x.frase + '»' : '')));
      lista.appendChild(lb);
    });
    m.appendChild(lista);
  }
  var riga = el('div', 'riga-btn');
  riga.appendChild(pulsante('f-ok', T('b_prepara_versione'), 'primario', () => {
    var a1 = cf.verifica(), a2 = cv.verifica();
    if (!a1 || !a2) return;
    var ids = [];
    nv.righe.forEach((x) => { if (scelte[x.id]) ids.push(x.id); });
    var msg = {azione: 'nuova_versione', tipo: base.tipo, nome: base.nome, versione: cv.campo.value.trim(), frase: cf.campo.value.trim(), righe: ids};
    chiudiScheda();
    invia(msg);
  }));
  riga.appendChild(pulsante('f-annulla', T('annulla'), '', () => chiudiScheda()));
  m.appendChild(riga);
}

function confermaScheda(frase, msg) {
  var m = $('scheda-modulo');
  svuota(m);
  m.className = 'modulo';
  m.appendChild(el('div', 'titolo', frase));
  var riga = el('div', 'riga-btn');
  riga.appendChild(pulsante('f-ok', T('si'), 'primario', () => { chiudiScheda(); invia(msg); }));
  riga.appendChild(pulsante('f-annulla', T('no'), '', () => chiudiScheda()));
  m.appendChild(riga);
}

function apriModuloScheda(genere, d) {
  var o = oggettoSel();
  if (!o) return;
  chiudiModulo();
  var m = $('scheda-modulo');
  svuota(m);
  notaScheda('');
  m.hidden = false;
  m.className = 'modulo' + (genere === 'promessa' || genere === 'ipotesi' ? ' dich' : '');
  moduloScheda = {tipo: sel.tipo, nome: sel.nome};
  var base = {tipo: sel.tipo, nome: sel.nome};
  var nuovo = !d;
  var tit = genere === 'scopo' ? T('mod_scopo', o.nome) : (nuovo ? T('mod_nuovo_' + genere, o.nome) : T('mod_vecchio_' + genere, o.nome, d.id));
  m.appendChild(el('div', 'titolo', tit));
  var verifiche = [];
  var invio = null;
  var altri = [];
  dichiarazioni().forEach((x) => { if ((x.genere === 'evento' || x.genere === 'stato') && !(d && x.da === d.da)) altri.push(x.id); });
  if (genere === 'scopo') {
    var cs = campoV(m, 'f-frase', T('scopo_una_frase'), d ? d.frase : (o.scopo || ''), vFrase(200, false));
    verifiche.push(cs.verifica);
    invio = () => ({azione: 'scheda_scopo', tipo: base.tipo, nome: base.nome, frase: cs.campo.value.trim()});
  } else if (genere === 'promessa' || genere === 'ipotesi') {
    var cf = campoV(m, 'f-frase', T(genere === 'promessa' ? 'f_cosa_promette' : 'f_cosa_si_suppone'), d ? d.frase : '', vFrase(400, false));
    var opzioni = [['JUDGEMENT', T('come_giudizio')], ['INSPECTION', T('come_ispezione')]];
    if (nuovo) opzioni.push(['FORMULA', T('come_formula')]);      // A-15
    var sc = scelta(m, 'f-come', T('f_come_si_controlla'), opzioni);
    if (d) sc.value = d.come;
    var cc = campoV(m, 'f-chi', T('f_chi_giudica'), d ? d.chi : '', vFrase(400, false));
    // la formula: campo a spaziatura fissa su più righe; il campo «Chi lo giudica» sparisce (una formula non ha VERIFY)
    var lf = el('label', null, T('f_formula'));
    var tf = el('textarea', 'casella');
    tf.id = 'f-formula';
    tf.rows = 3;
    tf.spellcheck = false;
    lf.appendChild(tf);
    var ef = el('div', 'campo-err');
    ef.id = 'e-f-formula';
    lf.appendChild(ef);
    var verFormula = () => {
      var t = tf.value, r = '';
      if (t.trim() === '') r = T('v_scrivi_formula');
      else if (lunghezza(t) > 400) r = T('v_troppo_lunga_400');
      else if (/[\u0000-\u0009\u000b-\u001f\u007f]/.test(t)) r = T('v_formula_carattere');
      else if (t.replace(/^\n+|\n+$/g, '').split('\n').some((x) => x.trim() === '')) r = T('v_formula_vuote');
      ef.textContent = r;
      return r === '';
    };
    tf.addEventListener('input', verFormula);
    var comeFormula = () => sc.value === 'FORMULA';
    var mostraFormula = () => {
      cf.riga.hidden = comeFormula();
      cc.riga.hidden = comeFormula();
      lf.hidden = !comeFormula();
    };
    sc.addEventListener('change', mostraFormula);
    m.appendChild(lf);
    mostraFormula();
    verifiche.push(() => comeFormula() ? verFormula() : cf.verifica(), () => comeFormula() || cc.verifica());
    invio = () => ({azione: nuovo ? 'scheda_aggiungi' : 'scheda_cambia', tipo: base.tipo, nome: base.nome, genere: genere,
      riga: d ? String(d.da) : '', vecchio: d ? d.id : '', frase: comeFormula() ? tf.value.replace(/^\n+|\n+$/g, '') : cf.campo.value.trim(), come: sc.value,
      chi: comeFormula() ? '' : cc.campo.value.trim(), nomeD: '', verso: '', tipoD: '', valore: '', unita: ''});
  } else if (genere === 'evento') {
    var cn = campoV(m, 'f-nome-d', T('f_nome_evento'), d ? d.id : '', vNomeD(altri));
    var sv2 = scelta(m, 'f-verso', T('f_direzione'), [['IN', T('dir_in')], ['OUT', T('dir_out')]]);
    if (d) sv2.value = d.verso;
    verifiche.push(cn.verifica);
    invio = () => ({azione: nuovo ? 'scheda_aggiungi' : 'scheda_cambia', tipo: base.tipo, nome: base.nome, genere: genere,
      riga: d ? String(d.da) : '', vecchio: d ? d.id : '', frase: '', come: '', chi: '', nomeD: cn.campo.value, verso: sv2.value,
      tipoD: '', valore: '', unita: ''});
  } else {
    var cn2 = campoV(m, 'f-nome-d', T('f_nome_stato'), d ? d.id : '', vNomeD(altri));
    var st = scelta(m, 'f-tipo-d', T('f_tipo'), tipiD());
    var vb = scelta(m, 'f-valore-b', T('f_valore_iniziale'), [['true', T('si_min')], ['false', T('no_min')]]);
    var vt = campoV(m, 'f-valore', T('f_valore_iniziale'), d ? d.valore : '', (v) => vValore(st.value, st.value === 'Boolean' ? vb.value : v, un.value));
    var un = scelta(m, 'f-unita', T('f_unita'), [['s', T('secondi')], ['ms', T('millisecondi')]]);
    if (d) { st.value = d.tipoDato; if (d.tipoDato === 'Boolean') vb.value = d.valore; if (d.unita) un.value = d.unita; }
    var mostra = () => {
      vb.parentNode.hidden = st.value !== 'Boolean';
      vt.riga.hidden = st.value === 'Boolean';
      un.parentNode.hidden = st.value !== 'Duration';
      vt.verifica();
    };
    st.addEventListener('change', () => { vt.campo.value = ''; mostra(); document.getElementById('e-f-valore').textContent = ''; });
    un.addEventListener('change', () => vt.verifica());
    mostra();
    document.getElementById('e-f-valore').textContent = '';
    verifiche.push(cn2.verifica, () => st.value === 'Boolean' || vt.verifica());
    invio = () => ({azione: nuovo ? 'scheda_aggiungi' : 'scheda_cambia', tipo: base.tipo, nome: base.nome, genere: genere,
      riga: d ? String(d.da) : '', vecchio: d ? d.id : '', frase: '', come: '', chi: '', nomeD: cn2.campo.value, verso: '',
      tipoD: st.value, valore: st.value === 'Boolean' ? vb.value : vt.campo.value, unita: st.value === 'Duration' ? un.value : ''});
  }
  var riga = el('div', 'riga-btn');
  riga.appendChild(pulsante('f-ok', T('salva'), 'primario', () => {
    var ok = true;
    verifiche.forEach((v) => { if (!v()) ok = false; });
    if (!ok) return;
    var msg = invio();
    chiudiScheda();
    invia(msg);
  }));
  if (d && (genere === 'promessa' || genere === 'ipotesi')) {
    riga.appendChild(pulsante('f-approva', T('b_approva'), 'accento', () => {
      chiudiScheda();
      appr = {chiave: base.tipo + ':' + base.nome, modo: 'riga', scelte: {}, ids: [d.id], numero: ''};
      ridisegna();
    }));
  }
  if (d && genere !== 'scopo') {
    riga.appendChild(pulsante('f-togli', T('b_togli'), 'togli', () => {
      confermaScheda(T('togli_dich_' + genere, d.id, o.nome),
        {azione: 'scheda_togli', tipo: base.tipo, nome: base.nome, genere: genere, riga: String(d.da), vecchio: d.id});
    }));
  }
  riga.appendChild(pulsante('f-annulla', T('annulla'), '', () => chiudiScheda()));
  m.appendChild(riga);
}

function ridisegnaStato(esito) {
  var e = entita(corrente);
  var chip = $('stato-chip');
  var msg = '';
  var problemi = [];
  chip.className = 'chip';
  if (!e) {
    chip.textContent = T('nessuna_entita_scelta');
    msg = T(M.entita.length === 0 ? 'cartella_senza_entita' : 'n_entita_scegline', M.entita.length);
  } else {
    var np = e.offre.length + e.usa.length;
    var st = e.stato;
    var gia = [];
    // Scomposta a mano ma ancora senza parti: nel file non c'è un gruppo, quindi bcdd non segnala niente;
    // ogni connettore pubblico è però senza nessuno che lo mantenga (il disegno lo mostra in rosso)
    if (st === 'non_scomposta' && scomposte[e.nome] && np > 0) {
      st = 'zoppa';
      e.offre.forEach((x) => gia.push(T('pub_non_affidato_offerto', x, e.nome)));
      e.usa.forEach((x) => gia.push(T('pub_non_affidato_usato', x, e.nome)));
    }
    chip.textContent = statoEntitaTesto(st);
    if (st !== 'non_scomposta') chip.className = 'chip ' + st;
    gia.forEach((m) => problemi.push(m));
    if (st === 'non_scomposta') msg = T(np === 1 ? 'stato_da_fuori_uno' : 'stato_da_fuori', e.nome, np);
    else if (e.stato === 'chiusa') msg = T('stato_chiusa_msg', e.nome);
    else if (e.stato === 'sospesa') msg = T('stato_sospesa_msg');
    else msg = T('stato_zoppa_msg', e.nome);
    e.messaggi.forEach((m) => problemi.push(m));
    e.errori.forEach((x) => problemi.push(T('riga_n_msg', x.riga, x.messaggio)));
  }
  if (sel && sel.tipo === 'csc') {
    var cs = cscDi(sel.nome);
    if (cs) cs.errori.forEach((x) => problemi.push(T('csc_riga_n_msg', cs.nome, x.riga, x.messaggio)));
  }
  if (problemi.length === 0 && formuleNonValutate()) msg += (msg ? ' ' : '') + T('nessun_errore_formule', T('sez_non_eseguiti'));
  $('stato-msg').textContent = msg;
  var p = $('stato-problemi');
  svuota(p);
  problemi.forEach((t) => p.appendChild(el('div', null, '● ' + t)));
  var ex = $('esito');
  if (esito && esito.testo) {
    ex.hidden = false;
    ex.className = esito.ok ? 'esito' : 'esito no';
    ex.textContent = esito.ok ? esito.testo : T('non_riuscito', esito.testo);
  } else {
    ex.hidden = true;
    ex.textContent = '';
  }
}

var ultimoEsito = null;
function ridisegna() {
  if (!M) return;
  if (corrente && !entita(corrente)) corrente = null;
  if (sel && !oggettoDi(sel.tipo, sel.nome)) sel = null;
  // il riquadro di Completa appartiene a ciò che è scelto; scegliendo altro si chiude (il giro resta in FILE.giro: si riprende
  // con Completa, «Riprendi»). Una chiamata all'LLM in corso non si interrompe: il riquadro si nasconde e, a risposta arrivata, si chiude.
  if (completa !== null && completa.fase !== 'attesa' && !completaQui()) completa = null;
  var e = entita(corrente);
  if (vista === 'dentro' && !haVistaDentro(e)) vista = 'fuori';
  var cartellaBreve = M.cartella.replace(/\/+$/, '').split('/').pop() || M.cartella;
  $('banco-hint').textContent = !e ? T('banco_hint_scegli') : (vista === 'fuori' ?
    T('fai_clic_scheda') : T('banco_hint_dentro', e.nome));
  $('banco-hint').title = $('banco-hint').textContent;
  $('t-fuori').className = 'tab' + (vista === 'fuori' ? ' on' : '');
  $('t-dentro').className = 'tab' + (vista === 'dentro' ? ' on' : '');
  $('t-fuori').disabled = !e;
  $('t-dentro').disabled = !haVistaDentro(e);
  ridisegnaAlbero();
  ridisegnaPercorso(cartellaBreve);
  ridisegnaAzioni();
  if (moduloAperto && !e && moduloAperto !== 'nuova') chiudiModulo();
  ridisegnaTela();
  ridisegnaScheda();
  ridisegnaStato(ultimoEsito);
  aggiornaLingua();
}

$('t-fuori').addEventListener('click', () => { vista = 'fuori'; puntato = null; chiudiModulo(); ridisegna(); });
$('t-dentro').addEventListener('click', () => { if (haVistaDentro(entita(corrente))) { vista = 'dentro'; puntato = null; chiudiModulo(); ridisegna(); } });

// ---- le chiamate dal programma
function bcddDisegna(testo, ora, esito, seleziona) {
  M = JSON.parse(testo);
  if (M.lingua && M.lingua !== LINGUA) {
    // il cambio di lingua: i moduli aperti (senza modifiche, altrimenti il comando era spento) si chiudono, la pagina prende il dizionario nuovo
    LINGUA = M.lingua;
    chiudiModulo();
    chiudiScheda();
    appr = null;
    memoMisure = {};
    applicaLingua();
  }
  puntato = null;
  ultimoEsito = esito ? JSON.parse(esito) : null;
  if (ultimoEsito && ultimoEsito.completa) esitoCompleta(ultimoEsito.completa);
  scegliRigheNuove();
  if (seleziona && entita(seleziona)) {
    albSel = null;
    corrente = seleziona;
    sel = {tipo: 'entita', nome: seleziona};
    vista = ultimoEsito && ultimoEsito.dentro && haVistaDentro(entita(seleziona)) ? 'dentro' : 'fuori';
  } else if (!corrente && M.entita.length === 1) {
    corrente = M.entita[0].nome;
    sel = {tipo: 'entita', nome: corrente};
  }
  $('letto').textContent = T('letto_alle', ora);
  $('controllato').textContent = '';
  $('avviso').hidden = true;
  ridisegna();
  // un errore che parla di righe precise: la casella di testo si apre su quelle righe
  if (ultimoEsito && ultimoEsito.casella) {
    var cz = ultimoEsito.casella;
    var ob = oggettoDi(cz.tipo, cz.nome);
    if (ob) {
      sel = {tipo: cz.tipo, nome: cz.nome};
      ridisegna();
      apriCasella(ob, cz.da, cz.a);
    }
  }
}
function bcddControllato(ora) {
  $('controllato').textContent = T('controllato_alle', ora);
}
function bcddAvviso(msg) {
  var a = $('avviso');
  a.hidden = false;
  a.textContent = msg;
}

// ---- Completa: domande, proposte, scrittura. Le righe le compone bcdd: da qui partono solo
// i numeri delle proposte accettate e le risposte. Parole di 4.3; le parole della grammatica compaiono solo nel testo delle righe proposte.
var modelloScelto = 'veloce';   // vale per la finestra aperta, nessun file di stato
function modelloNome(k) { return T('modello_nome_' + k); }
var completa = null;   // {tipo, nome, fase, ...}; fasi: bloccato, attesa, domande, proposte, precisa, aperto, fallita, copia, errore
function completaQui() { return completa !== null && sel !== null && sel.tipo === completa.tipo && sel.nome === completa.nome; }
function inAttesa() { return completa !== null && completa.fase === 'attesa'; }
function cosa(c) { return T(c.tipo === 'entita' ? 'cosa_entita' : 'cosa_csc', c.nome); }
function elencoErrori(o) {
  var r = [], i;
  for (i = 0; i < o.errori.length; i++) r.push(T('riga_n_msg', o.errori[i].riga, o.errori[i].messaggio));
  if (o.messaggi) for (i = 0; i < o.messaggi.length; i++) r.push(o.messaggi[i]);
  return r;
}
function avviaCompleta() {
  var o = oggettoSel();
  if (!o || completa !== null) return;
  if (sel.tipo === 'csc' && o.scopo_da_compilare) { apriScopoPrima(); return; }
  chiudiScheda();
  chiudiModulo();
  completa = {tipo: sel.tipo, nome: sel.nome, fase: 'attesa', tempo: 1, nota: '', messaggio: '', elenco: [], domande: [], risp: [],
    proposte: [], sostituzioni: [], cscAParte: [], interfaccia: [], scelta: {}, copia: null, giroAperto: false};
  var errs = (o.errori.length > 0 || o.stato === 'zoppa') ? elencoErrori(o) : [];
  if (errs.length > 0) {
    completa.fase = 'bloccato';
    completa.elenco = errs;
    ridisegna();
    return;
  }
  ridisegna();
  completa.modello = modelloScelto;
  invia({azione: 'completa_avvia', tipo: completa.tipo, nome: completa.nome, modello: modelloScelto});
}
// Completa parte dallo scopo; se è ancora quello di `bcdd new` si apre «Cambia lo scopo» con la frase che dice perché
function apriScopoPrima() {
  var d = null, ds = dichiarazioni();
  for (var i = 0; i < ds.length; i++) if (ds[i].genere === 'scopo') d = ds[i];
  apriModuloScheda('scopo', d);
  var m = $('scheda-modulo');
  var f = el('div', 'cc-msg', T('scopo_prima'));
  f.id = 'f-scopo-prima';
  m.insertBefore(f, m.children.length > 1 ? m.children[1] : null);
}
function chiudiCompleta() { completa = null; ridisegna(); }
function nuoveRisposte(domande) {
  var r = [];
  for (var i = 0; i < domande.length; i++) r.push({scelta: 0, testo: '', salta: false});
  return r;
}
function riempiProposte(u) {
  completa.proposte = u.proposte;
  completa.sostituzioni = u.sostituzioni;
  completa.cscAParte = u.csc_a_parte;
  completa.interfaccia = u.interfaccia || [];
  completa.scelta = {};
  completa.fase = 'proposte';
}
function dopoTempo1(u) {
  if (u.precisa) completa.fase = 'precisa';
  else if (u.domande.length > 0) {
    completa.fase = 'domande';
    completa.domande = u.domande;
    completa.risp = nuoveRisposte(u.domande);
  } else riempiProposte(u);
}
// la risposta di bcdd a un tempo che chiama l'LLM (tempo 1 o 2), arrivata dal programma
function bcddCompleta(testo) {
  var p = JSON.parse(testo);
  if (completa === null) return;
  var u = p.uscita;
  if (p.tempo === 1 && p.codice === 1 && u && u.errore === 'scopo_da_scrivere') { completa = null; ridisegna(); apriScopoPrima(); return; }
  if (u && (u.modello === 'veloce' || u.modello === 'accurato')) completa.modello = u.modello, completa.modelloGiro = true;
  var msg = p.errore || T('bcdd_non_ha_risposto');
  var fd = u && u.errore === 'fase_diversa' ? u.fase : '';       // C-11: la fase che non va, dal campo di bcdd (mai dal testo del messaggio)
  completa.nota = '';
  if (p.fermato || p.codice === 130) {
    if (p.tempo === 2) {
      completa.fase = 'domande';
      completa.nota = T('fermato_risposte');
    } else {
      completa.fase = 'errore';
      completa.messaggio = T('fermato');
    }
  } else if (p.tempo === 0) {
    // «Riprendi» (`bcdd refine --json --show`): rimostra il punto a cui il giro era fermo, senza chiamare l'LLM
    if (p.codice === 0 && u && u.tempo === 1) dopoTempo1(u);
    else if (p.codice === 0 && u && u.tempo === 2) {
      riempiProposte(u);
      if (u.domande_ignorate > 0) completa.nota = T('domande_ignorate', u.domande_ignorate);
    } else if (p.codice === 1 && u && u.errore === 'file_cambiato') {
      completa.fase = 'copia';
      completa.copia = u;
      completa.messaggio = T('file_cambiato_giro');
    } else if (p.codice === 2 && fd === 'risposte_fallite') {
      completa.fase = 'fallita';
      completa.giroAperto = true;
      completa.messaggio = T('giro_rimasto');
    } else {
      completa.fase = 'errore';
      completa.messaggio = msg;
    }
  } else if (p.tempo === 1) {
    if (p.codice === 1 && u && u.errore === 'giro_aperto') {
      completa.fase = 'aperto';
    } else if (p.codice === 0 && u && u.tempo === 1) {
      dopoTempo1(u);
    } else {
      completa.fase = 'errore';
      completa.messaggio = msg;
    }
  } else {
    if (p.codice === 0 && u && u.tempo === 2) {
      riempiProposte(u);
      if (u.domande_ignorate > 0) completa.nota = T('domande_ignorate', u.domande_ignorate);
    } else if (p.codice === 4 || fd === 'risposte_fallite') {
      completa.fase = 'fallita';
      completa.messaggio = msg;
    } else if (p.codice === 1 && u && u.errore === 'file_cambiato') {
      completa.fase = 'copia';
      completa.copia = u;
      completa.messaggio = T('file_cambiato_attesa');
    } else if (fd === 'proposte') {
      completa.fase = 'errore';
      completa.giroAperto = true;
      completa.messaggio = T('giro_gia_proposte');
    } else {
      completa.fase = 'errore';
      completa.giroAperto = true;
      completa.messaggio = msg;
    }
  }
  ridisegna();
}
// l'esito di un'azione che riguarda Completa (scrittura, chiusura del giro)
function esitoCompleta(c) {
  if (completa === null) return;
  if (c.stato === 'chiuso') completa = null;
  else if (c.stato === 'copia') {
    completa.fase = 'copia';
    completa.copia = c.uscita;
    completa.messaggio = c.uscita.errore === 'file_cambiato' ?
      T('file_cambiato_righe') :
      T('dialogo_non_scritto');
  }
}
function cartaCompleta(cls, titolo) {
  var d = el('div', 'cc-carta ' + cls);
  d.appendChild(el('div', 'cc-titolo', titolo));
  return d;
}
function righeBlocco(righe) {
  var b = el('div', 'cc-righe');
  var cs = coloraTesto(righe.join('\n'));
  for (var i = 0; i < righe.length; i++) {
    var d = el('div');
    if (righe[i] === '') d.textContent = ' ';
    else spanSegmenti(d, cs[i]);
    b.appendChild(d);
  }
  return b;
}
// le ragioni con cui bcdd scarta una proposta, con le parole dell'interfaccia al posto di quelle della grammatica
function ragionePiana(x) {
  // C-12: la frase per la persona dalla chiave della ragione (ragione_chiave) e dai suoi argomenti; chiave senza frase propria: il testo di bcdd com'è
  var k = 'rg_' + (x.ragione_chiave || '');
  var tab = TESTI[LINGUA] || TESTI.en;
  if (!x.ragione_chiave || tab[k] === undefined) return x.ragione;
  return T.apply(null, [k].concat(x.ragione_argomenti || []));
}
function verificaParole(v) { return v === 'JUDGEMENT' ? T('come_giudizio') : (v === 'INSPECTION' ? T('come_ispezione') : v); }

function ridisegnaCompleta() {
  var box = $('scheda-completa');
  svuota(box);
  if (completa === null || !completaQui() || bloccoAttivo() !== null) { box.hidden = true; return; }
  box.hidden = false;
  var c = completa, i, k, b;
  box.appendChild(el('div', 'cc-testa', T('cc_testa', cosa(c))));
  if (c.modelloGiro && c.fase !== 'attesa') box.appendChild(el('div', 'cc-eti', T('cc_modello_giro', modelloNome(c.modello))));
  if (c.nota) box.appendChild(el('div', 'cc-nota', c.nota));
  var riga = el('div', 'riga-btn');
  if (c.fase === 'bloccato') {
    box.appendChild(el('div', 'cc-msg', T('cc_bloccato', cosa(c))));
    var l = el('div', 'cc-elenco');
    c.elenco.forEach((x) => l.appendChild(el('div', null, '● ' + x)));
    box.appendChild(l);
    riga.appendChild(pulsante('c-chiudi', T('chiudi'), '', chiudiCompleta));
  } else if (c.fase === 'attesa') {
    var mod = c.modello ? ' (' + modelloNome(c.modello) + ')' : '';
    if (c.tempo === 0) box.appendChild(el('div', 'cc-msg', T('cc_riprendo')));
    else {
      box.appendChild(el('div', 'cc-msg', T(c.tempo === 1 ? 'cc_chiedo' : 'cc_chiedo_risposte', mod)));
      box.appendChild(el('div', 'cc-nota', T('cc_un_po')));
      riga.appendChild(pulsante('c-ferma', T('b_ferma'), 'togli', () => invia({azione: 'completa_ferma'})));
    }
  } else if (c.fase === 'precisa') {
    box.appendChild(el('div', 'cc-fatto', T(c.tipo === 'entita' ? 'cc_precisa_entita' : 'cc_precisa_csc', c.nome)));
    riga.appendChild(pulsante('c-chiudi', T('chiudi'), '', chiudiCompleta));
  } else if (c.fase === 'aperto') {
    box.appendChild(el('div', 'cc-msg', T('cc_aperto', cosa(c))));
    riga.appendChild(pulsante('c-riprendi', T('b_riprendi'), 'primario', () => {
      c.fase = 'attesa';
      c.tempo = 0;
      ridisegna();
      invia({azione: 'completa_riprendi', tipo: c.tipo, nome: c.nome});
    }));
    riga.appendChild(pulsante('c-chiudi-giro', T('b_chiudi_giro'), '', () => invia({azione: 'completa_chiudi', tipo: c.tipo, nome: c.nome})));
  } else if (c.fase === 'errore') {
    box.appendChild(el('div', 'cc-msg cc-err', c.messaggio));
    if (c.giroAperto) riga.appendChild(pulsante('c-chiudi-giro', T('b_chiudi_giro'), '', () => invia({azione: 'completa_chiudi', tipo: c.tipo, nome: c.nome})));
    riga.appendChild(pulsante('c-chiudi', T('chiudi'), '', chiudiCompleta));
  } else if (c.fase === 'fallita') {
    box.appendChild(el('div', 'cc-msg cc-err', T('cc_fallita', c.messaggio)));
    box.appendChild(el('div', 'cc-nota', T('cc_fallita_nota')));
    riga.appendChild(pulsante('c-scrivi', T('b_scrivi_risposte'), 'primario', () => invia({azione: 'completa_scrivi', tipo: c.tipo, nome: c.nome, accettate: []})));
    riga.appendChild(pulsante('c-lascia', T('b_lascia'), '', () => invia({azione: 'completa_chiudi', tipo: c.tipo, nome: c.nome})));
  } else if (c.fase === 'copia') {
    box.appendChild(el('div', 'cc-msg cc-err', c.messaggio));
    var u = c.copia;
    if (u.risposte && u.risposte.length > 0) {
      var cr = cartaCompleta('cc-q', T('cc_le_tue_risposte'));
      u.risposte.forEach((x) => { cr.appendChild(el('div', 'cc-testo', x.domanda)); cr.appendChild(righeBlocco(['→ ' + x.risposta])); });
      box.appendChild(cr);
    }
    (u.proposte_accettate || []).forEach((x) => {
      var cp = cartaCompleta('cc-p', T('cc_riga_accettata', x.n));
      cp.appendChild(righeBlocco(x.righe));
      box.appendChild(cp);
    });
    (u.interfaccia_accettate || []).forEach((x) => {
      var cf = cartaCompleta('cc-p', T('cc_riga_if_accettata', x.n));
      cf.appendChild(righeBlocco([x.riga]));
      box.appendChild(cf);
    });
    (u.sostituzioni_accettate || []).forEach((x) => {
      var cs = cartaCompleta('cc-p', T('cc_riga_cambiare_accettata', x.n));
      cs.appendChild(el('div', 'cc-testo', T('cc_diventa', x.id, x.testo, verificaParole(x.verifica), x.verifica_testo)));
      box.appendChild(cs);
    });
    riga.appendChild(pulsante('c-chiudi', T('chiudi'), '', chiudiCompleta));
  } else if (c.fase === 'domande') {
    for (i = 0; i < c.domande.length; i++) {
      var q = c.domande[i], r = c.risp[i];
      var carta = cartaCompleta('cc-q' + (r.salta ? ' cc-salta' : ''), (c.domande.length > 1 ? T('cc_domanda_n', i + 1, c.domande.length) : T('cc_domanda_llm')));
      carta.appendChild(el('div', 'cc-domanda', q.testo));
      var sc = el('div', 'cc-scelte');
      for (k = 0; k < q.scelte.length; k++) {
        b = el('button', 'cc-scelta' + (r.scelta === k + 1 ? ' on' : ''), q.scelte[k]);
        b.id = 'c-scelta-' + (i + 1) + '-' + (k + 1);
        b.addEventListener('click', ((ii, kk) => () => { c.risp[ii] = {scelta: kk, testo: '', salta: false}; ridisegna(); })(i, k + 1));
        sc.appendChild(b);
      }
      carta.appendChild(sc);
      var lab = el('label', null, T('cc_oppure'));
      var inp = el('input');
      inp.type = 'text';
      inp.id = 'c-testo-' + (i + 1);
      inp.value = r.testo;
      inp.maxLength = 400;
      // niente ridisegno mentre si scrive (si perderebbero il fuoco e il clic): si aggiorna a mano ciò che si vede
      inp.addEventListener('input', ((ii, campo, scelte, cartaQ) => () => {
        c.risp[ii].testo = campo.value;
        if (campo.value !== '') {
          c.risp[ii].scelta = 0;
          c.risp[ii].salta = false;
          for (var m = 0; m < scelte.childNodes.length; m++) scelte.childNodes[m].className = 'cc-scelta';
          cartaQ.className = cartaQ.className.replace(' cc-salta', '');
          var bs = $('c-salta-' + (ii + 1));
          if (bs) bs.textContent = T('b_salta');
        }
      })(i, inp, sc, carta));
      lab.appendChild(inp);
      carta.appendChild(lab);
      var rb = el('div', 'riga-btn');
      rb.appendChild(pulsante('c-salta-' + (i + 1), T(r.salta ? 'b_saltata' : 'b_salta'), '', ((ii) => () => { c.risp[ii] = {scelta: 0, testo: '', salta: true}; ridisegna(); })(i)));
      carta.appendChild(rb);
      box.appendChild(carta);
    }
    riga.appendChild(pulsante('c-avanti', T('b_avanti'), 'primario', () => {
      var ris = [];
      for (var j = 0; j < c.domande.length; j++) {
        var x = c.risp[j];
        if (x.scelta > 0) ris.push({n: j + 1, scelta: x.scelta});
        else if (x.testo.trim() !== '') ris.push({n: j + 1, testo: x.testo.trim()});
      }
      c.fase = 'attesa';
      c.tempo = 2;
      ridisegna();
      invia({azione: 'completa_risposte', tipo: c.tipo, nome: c.nome, risposte: ris});
    }));
    riga.appendChild(pulsante('c-lascia', T('b_lascia'), '', () => invia({azione: 'completa_chiudi', tipo: c.tipo, nome: c.nome})));
  } else if (c.fase === 'proposte') {
    var nAcc = 0;
    var sceltaBtn = (n, valida, carta) => {
      if (!valida) return;
      var rr = el('div', 'riga-btn');
      var ba = pulsante('c-acc-' + n, T(c.scelta[n] === 'acc' ? 'b_accettata' : 'b_accetta'), c.scelta[n] === 'acc' ? 'primario' : '', () => { c.scelta[n] = 'acc'; ridisegna(); });
      var bs = pulsante('c-sca-' + n, T(c.scelta[n] === 'sca' ? 'b_scartata' : 'b_scarta'), '', () => { c.scelta[n] = 'sca'; ridisegna(); });
      ba.setAttribute('aria-pressed', c.scelta[n] === 'acc' ? 'true' : 'false');
      bs.setAttribute('aria-pressed', c.scelta[n] === 'sca' ? 'true' : 'false');
      rr.appendChild(ba);
      rr.appendChild(bs);
      carta.appendChild(rr);
    };
    for (i = 0; i < c.sostituzioni.length; i++) {
      var s = c.sostituzioni[i];
      var cs2 = cartaCompleta('cc-p' + (c.scelta[s.n] === 'sca' ? ' cc-salta' : ''), T('cc_riga_da_cambiare'));
      if (s.valida) {
        cs2.appendChild(el('div', 'cc-testo', T('cc_cambia_riga', s.id)));
        cs2.appendChild(el('div', 'cc-eti', T('cc_adesso')));
        cs2.appendChild(righeBlocco(s.adesso));
        cs2.appendChild(el('div', 'cc-eti', T('cc_diventa_eti')));
        cs2.appendChild(righeBlocco(s.diventa));
        if (s.dettagli.length > 0) cs2.appendChild(el('div', 'cc-nota', T('cc_da_rileggere', s.dettagli.join(', '))));
        if (c.scelta[s.n] === 'acc') nAcc++;
      } else {
        cs2.appendChild(el('div', 'cc-testo', T('cc_cambierebbe', s.id, s.testo, ragionePiana(s))));
      }
      sceltaBtn(s.n, s.valida, cs2);
      box.appendChild(cs2);
    }
    for (i = 0; i < c.interfaccia.length; i++) {
      var f = c.interfaccia[i];
      var ci = cartaCompleta('cc-p' + (c.scelta[f.n] === 'sca' ? ' cc-salta' : ''), T('cc_riga_if'));
      if (f.valida) {
        ci.appendChild(righeBlocco([f.riga]));
        ci.appendChild(el('div', 'cc-nota', f.motivo));
        if (c.scelta[f.n] === 'acc') nAcc++;
      } else {
        ci.appendChild(el('div', 'cc-testo', T('cc_if_no', ragionePiana(f))));
        ci.appendChild(righeBlocco(['«' + f.riga + '»']));
      }
      sceltaBtn(f.n, f.valida, ci);
      box.appendChild(ci);
    }
    for (i = 0; i < c.proposte.length; i++) {
      var p = c.proposte[i];
      var base = p.dettaglia === '';
      var cp2 = cartaCompleta('cc-p' + (c.scelta[p.n] === 'sca' ? ' cc-salta' : ''), base ? T(p.tipo === 'ASSUME' ? 'cc_ass_nuovo' : 'cc_gar_nuova') : T('cc_riga_proposta'));
      if (p.valida) {
        if (!base) cp2.appendChild(el('div', 'cc-testo', T(p.tipo === 'ASSUME' ? 'cc_precisa_ass' : 'cc_precisa_gar', p.dettaglia)));
        cp2.appendChild(righeBlocco(p.righe));
        if (c.scelta[p.n] === 'acc') nAcc++;
      } else {
        cp2.appendChild(el('div', 'cc-testo', T('cc_proposta_no', ragionePiana(p))));
        cp2.appendChild(righeBlocco(['«' + p.testo + '»']));
      }
      sceltaBtn(p.n, p.valida, cp2);
      box.appendChild(cp2);
    }
    for (i = 0; i < c.cscAParte.length; i++) {
      var cn = c.cscAParte[i];
      var cc3 = cartaCompleta('cc-q', T('cc_csc_a_parte', cn.nome));
      cc3.appendChild(el('div', 'cc-testo', cn.motivo));
      var esiste = cscDi(cn.nome) !== null || !NOME.test(cn.nome);
      var rb2 = el('div', 'riga-btn');
      rb2.appendChild(pulsante('c-crea-' + cn.nome, cscDi(cn.nome) !== null ? T('cc_csc_c_e_gia', cn.nome) : T('cc_crea_csc', cn.nome), '',
        ((nn, mm) => () => apriCreaCsc(nn, mm))(cn.nome, cn.motivo), esiste));
      cc3.appendChild(rb2);
      box.appendChild(cc3);
    }
    if (c.sostituzioni.length + c.proposte.length + c.cscAParte.length + c.interfaccia.length === 0)
      box.appendChild(el('div', 'cc-msg', T('cc_nessuna_riga')));
    var nR = 0;
    for (i = 0; i < c.risp.length; i++) if (c.risp[i].scelta > 0 || c.risp[i].testo.trim() !== '') nR++;
    box.appendChild(el('div', 'cc-nota', nAcc === 0 ? T('cc_nessuna_acc') + (nR > 0 ? T('cc_nessuna_acc_risp') : '') :
      (nAcc === 1 ? T('cc_una_acc') : T('cc_n_acc', nAcc))));
    riga.appendChild(pulsante('c-scrivi', T('b_scrivi_accettate'), 'primario', () => {
      var acc = [];
      c.sostituzioni.forEach((x) => { if (x.valida && c.scelta[x.n] === 'acc') acc.push(x.n); });
      c.interfaccia.forEach((x) => { if (x.valida && c.scelta[x.n] === 'acc') acc.push(x.n); });
      c.proposte.forEach((x) => { if (x.valida && c.scelta[x.n] === 'acc') acc.push(x.n); });
      ricordaPerApprova(c, acc);
      invia({azione: 'completa_scrivi', tipo: c.tipo, nome: c.nome, accettate: acc});
    }, nAcc === 0 && nR === 0));
    riga.appendChild(pulsante('c-lascia', T('b_lascia'), '', () => invia({azione: 'completa_chiudi', tipo: c.tipo, nome: c.nome})));
  }
  box.appendChild(riga);
}

// ---- Approva: una riga, le righe scelte, il connettore intero. Il numero della decisione si scrive a mano:
// la pagina non lo propone e non lo ricorda. Gli elenchi vengono dai dati di check (scheda.da_approvare, scheda.intero), mai dal testo.
var appr = null;       // {chiave, modo: 'elenco' | 'riga' | 'intero', scelte: {id: true}, ids: [id], numero}
var preAppr = null;    // dopo «Scrivi le righe accettate» di Completa: {chiave, prima: [id], sost: [id]}
var DECISIONE = /^D-[0-9]{1,6}$/;

function ricordaPerApprova(c, accettate) {
  var o = c.tipo === 'entita' ? entita(c.nome) : cscDi(c.nome);
  var prima = [], sost = [];
  if (o) o.scheda.da_approvare.forEach((x) => prima.push(x.id));
  c.sostituzioni.forEach((x) => { if (x.valida && accettate.indexOf(x.n) >= 0) sost.push(x.id); });
  preAppr = {chiave: c.tipo + ':' + c.nome, prima: prima, sost: sost};
}
// dopo la scrittura di Completa: le righe appena scritte (nuove, o cambiate) sono già scelte nell'elenco «Da approvare»
function scegliRigheNuove() {
  if (!preAppr) return;
  var p = preAppr;
  preAppr = null;
  if (!ultimoEsito || !ultimoEsito.ok) return;
  var i = p.chiave.indexOf(':');
  var o = p.chiave.substring(0, i) === 'entita' ? entita(p.chiave.substring(i + 1)) : cscDi(p.chiave.substring(i + 1));
  if (!o) return;
  var scelte = {}, n = 0;
  o.scheda.da_approvare.forEach((x) => {
    if (p.prima.indexOf(x.id) < 0 || p.sost.indexOf(x.id) >= 0) { scelte[x.id] = true; n++; }
  });
  if (n > 0) appr = {chiave: p.chiave, modo: 'elenco', scelte: scelte, ids: [], numero: ''};
}
function voceTesto(x) {
  if (x.genere === 'intestazione') return T('ap_intestazione', x.nome);
  if (x.genere === 'dettaglio') return T('ap_dettaglio', x.id);
  var fr = x.frase ? ': «' + x.frase + '»' : '';
  if (x.genere === 'promessa') return T('ap_voce_promessa', x.id, fr);
  if (x.genere === 'presupposto') return T('ap_voce_presupposto', x.id, fr);
  if (x.genere === 'evento') return T('ap_voce_evento', x.nome);
  if (x.genere === 'stato') return T('ap_voce_stato', x.nome);
  return T('ap_voce_' + x.genere, x.nome);
}
function numeroValido() { return appr !== null && DECISIONE.test(appr.numero.trim()); }
function campoNumero(box, aggiorna) {
  var l = el('label', null, T('ap_numero'));
  var i = el('input');
  i.id = 'a-num';
  i.type = 'text';
  i.maxLength = 8;
  i.value = appr.numero;
  var err = el('div', 'campo-err');
  err.id = 'a-num-err';
  var mostra = () => { err.textContent = appr.numero.trim() !== '' && !numeroValido() ? T('ap_numero_err') : ''; };
  i.addEventListener('input', () => { appr.numero = i.value; mostra(); aggiorna(); });
  l.appendChild(i);
  l.appendChild(err);
  box.appendChild(l);
  mostra();
}
function elencoVoci(box, voci, cls) {
  var l = el('div', 'ap-elenco' + (cls ? ' ' + cls : ''));
  voci.forEach((x) => l.appendChild(el('div', null, '● ' + voceTesto(x))));
  box.appendChild(l);
}

function ridisegnaApprova() {
  var box = $('scheda-approva');
  svuota(box);
  var o = oggettoSel();
  var chiave = chiaveSel();
  if (appr && appr.chiave !== chiave) appr = null;
  if (!o || completa !== null) { box.hidden = true; return; }
  if (esBlocco(o)) { ridisegnaApprovaBlocco(o, box, chiave); return; }
  var da = o.scheda.da_approvare;
  if (appr && appr.modo === 'elenco') {
    // le righe scelte che non sono più da approvare (approvate da fuori, o tolte) si perdono
    var ancora = {};
    da.forEach((x) => { ancora[x.id] = true; });
    for (var k in appr.scelte) if (!ancora[k]) delete appr.scelte[k];
  }
  var modo = appr ? appr.modo : 'elenco';
  if (modo === 'elenco' && da.length === 0) { box.hidden = true; return; }
  if (modo === 'intero' && o.scheda.intero === null) { appr = null; box.hidden = true; return; }
  box.hidden = false;
  var riga = el('div', 'riga-btn');
  var blocca = o.scheda.blocca;
  var cosaTesto = T(sel.tipo === 'entita' ? 'ap_cosa_entita' : 'ap_cosa_csc', o.nome);
  if (modo === 'riga') {
    var x1 = null;
    da.forEach((x) => { if (x.id === appr.ids[0]) x1 = x; });
    if (x1 === null) { appr = null; box.hidden = true; return; }
    box.appendChild(el('div', 'cc-testa', T(x1.genere === 'promessa' ? 'ap_testa_gar' : 'ap_testa_ass', x1.id, o.nome)));
    if (x1.frase) box.appendChild(el('div', 'cc-testo', '«' + x1.frase + '»'));
  } else if (modo === 'intero') {
    box.appendChild(el('div', 'cc-testa', T('ap_testa_intero', o.nome)));
    if (blocca.length === 0) {
      box.appendChild(el('div', 'cc-msg', T('ap_saranno')));
      elencoVoci(box, o.scheda.intero.diventano, 'ap-si');
      if (o.scheda.intero.restano.length > 0) {
        box.appendChild(el('div', 'cc-msg', T('ap_restano')));
        elencoVoci(box, o.scheda.intero.restano, 'ap-no');
      }
    }
  } else {
    box.appendChild(el('div', 'cc-testa', T('ap_da_approvare')));
  }
  if (blocca.length > 0) {
    box.appendChild(el('div', 'cc-msg cc-err', T('ap_prima_errori')));
    var lb = el('div', 'cc-elenco');
    blocca.forEach((t) => lb.appendChild(el('div', null, '● ' + t)));
    box.appendChild(lb);
    if (modo !== 'elenco') riga.appendChild(pulsante('a-annulla', T('chiudi'), '', () => { appr = null; ridisegna(); }));
    box.appendChild(riga);
    return;
  }
  var ok;
  var aggiorna = () => {
    if (!ok) return;
    var n = 0;
    for (var kk in appr.scelte) if (appr.scelte[kk]) n++;
    ok.disabled = !numeroValido() || (modo === 'elenco' && n === 0);
  };
  if (modo === 'elenco') {
    if (!appr) appr = {chiave: chiave, modo: 'elenco', scelte: {}, ids: [], numero: ''};
    var lista = el('div', 'ap-elenco');
    da.forEach((x) => {
      var l = el('label', 'ap-voce');
      var c = el('input');
      c.type = 'checkbox';
      c.id = 'a-sel-' + x.id;
      c.checked = !!appr.scelte[x.id];
      c.addEventListener('change', () => { appr.scelte[x.id] = c.checked; aggiorna(); });
      l.appendChild(c);
      l.appendChild(el('span', null, voceTesto(x)));
      lista.appendChild(l);
    });
    box.appendChild(lista);
  }
  campoNumero(box, aggiorna);
  var testoOk = modo === 'elenco' ? T('ap_approva_scelte') : T('b_approva');
  ok = pulsante('a-ok', testoOk, 'primario', () => {
    var ids = [];
    if (modo === 'elenco') da.forEach((x) => { if (appr.scelte[x.id]) ids.push(x.id); });
    else ids = appr.ids;
    var numero = appr.numero.trim();
    ok.disabled = true;
    appr = null;
    if (modo === 'intero') invia({azione: 'approva_intero', tipo: sel.tipo, nome: sel.nome, decisione: numero});
    else invia({azione: 'approva_righe', tipo: sel.tipo, nome: sel.nome, decisione: numero, righe: ids});
  });
  riga.appendChild(ok);
  if (modo !== 'elenco') riga.appendChild(pulsante('a-annulla', T('annulla'), '', () => { appr = null; ridisegna(); }));
  box.appendChild(riga);
  aggiorna();
}

// ==== BCDD 1.0-beta: colorazione, forme concrete, piano di prova, profili, rapporto ====
var ling = '';                // la linguetta aperta nella scheda di un connettore: '' (il connettore) o 'bN' (N-esimo blocco legato)
function chiaveSel() { return sel ? sel.tipo + ':' + sel.nome + (sel.tipo === 'csc' && ling ? ':' + ling : '') : ''; }
function profiloDi(nome) { if (!M || !M.profili) return null; for (var i = 0; i < M.profili.length; i++) if (M.profili[i].nome === nome) return M.profili[i]; return null; }
function chiaveBlocco(b) { return b.file + ':' + b.riga; }
function bloccoSenzaCsc(k) { if (!M || !M.senza_connettore) return null; for (var i = 0; i < M.senza_connettore.length; i++) if (chiaveBlocco(M.senza_connettore[i]) === k) return M.senza_connettore[i]; return null; }
function bloccoAttivo() {
  if (!sel || sel.tipo !== 'csc' || !ling) return null;
  var c = cscDi(sel.nome);
  var i = parseInt(ling.substring(1), 10);
  return c && c.blocchi && c.blocchi[i] ? c.blocchi[i] : null;
}
function esBlocco(o) { return !!o && (o.tipo === 'BINDING' || o.tipo === 'VERIFICATION' || o.tipo === 'PROFILE'); }
function motivoBlocco(b) { return b.trovata ? '' : T('csc_non_in_cartella', b.nome); }
function titoloBlocco(b) {
  if (b.tipo === 'PROFILE') return b.nome;
  return b.tipo === 'BINDING' ? (b.nome_proprio ? T('blocco_forme_np', b.nome_proprio, b.nome) : T('blocco_forme', b.nome)) : T('blocco_piano', b.nome);
}
function tipoBlocco(b) { return b.tipo === 'PROFILE' ? T('tipo_profilo', b.versione) : T(b.tipo === 'BINDING' ? 'tipo_forme' : 'tipo_piano'); }
function statoTesto(b) { return b.stato === 'contratto' ? T('blocco_approvate') : (b.stato === 'ipotesi' ? T('blocco_da_approvare') : ''); }
function latiBlocco(b) {
  if (b.tipo === 'PROFILE') return (b.scopo ? b.scopo + ' · ' : '') + T(b.stato === 'contratto' ? 'profilo_approvato' : 'blocco_da_approvare') + ' · ' + T(b.estensioni.length === 1 ? 'profilo_una_est' : 'profilo_n_est', b.estensioni.length);
  var t = (b.trovata ? T('del_connettore', b.nome) : motivoBlocco(b)) + (b.tipo === 'BINDING' && statoTesto(b) ? ' · ' + statoTesto(b) : '');
  return t;
}
function gradoTesto(g) { return T('grado_' + g); }

// ---- A-3 (14.2): la colorazione. Stessa regola di `coloraRighe` in edmodello.nim, senza i due contesti che chiedono il file intero
// (VERIFY di un'estensione, nomi di estensione importati): qui servono per l'anteprima della casella e per le carte di Completa.
var RITIRATE = ['REFINED', 'REFINES', 'FACE', 'LINK', 'MAP', 'REFINEMENT', 'VIEW'];
function coloraTesto(testo) {
  var ris = {}, i;
  ((M && M.riservate) || []).forEach((w) => { ris[w] = true; });
  var righe = testo.split('\n'), out = [], inStr = false;
  righe.forEach((r) => {
    var segs = [], cur = '', cls = '';
    var emetti = (t, c) => { if (c !== cls) { if (cur) segs.push([cur, cls]); cur = ''; cls = c; } cur += t; };
    i = 0;
    while (i < r.length) {
      var ch = r.charAt(i);
      if (inStr) {
        var z = r.indexOf('"', i);
        if (z < 0) { emetti(r.substring(i), 'stringa'); i = r.length; } else { emetti(r.substring(i, z + 1), 'stringa'); i = z + 1; inStr = false; }
        continue;
      }
      if (ch === '"') { inStr = true; emetti('"', 'stringa'); i++; }
      else if (ch === '-' && r.charAt(i + 1) === '-') { emetti(r.substring(i), 'commento'); i = r.length; }
      else if (/[A-Za-z_]/.test(ch)) {
        var k = i;
        while (k < r.length && (/[A-Za-z0-9_]/.test(r.charAt(k)) || (r.charAt(k) === '-' && k > i && /[A-Za-z0-9_]/.test(r.charAt(k + 1) || '')))) k++;
        var w = r.substring(i, k);
        emetti(w, RITIRATE.indexOf(w) >= 0 ? 'ritirata' : (ris[w] ? 'chiave' : ''));
        i = k;
      } else if (/[0-9]/.test(ch)) {
        var n = i;
        while (n < r.length && /[0-9]/.test(r.charAt(n))) n++;
        if (r.charAt(n) === '.' && /[0-9]/.test(r.charAt(n + 1) || '')) { n++; while (n < r.length && /[0-9]/.test(r.charAt(n))) n++; }
        var u = n;
        while (u < r.length && r.charAt(u) === ' ') u++;
        var uz = u;
        while (uz < r.length && /[a-z]/.test(r.charAt(uz))) uz++;
        var un = r.substring(u, uz);
        if ((un === 's' || un === 'ms') && !(uz < r.length && /[A-Za-z0-9_]/.test(r.charAt(uz)))) n = uz;
        emetti(r.substring(i, n), 'numero');
        i = n;
      } else if ('<>+-*/^;'.indexOf(ch) >= 0) {
        var e2 = i + 1, nx = r.charAt(i + 1);
        if ((ch === '<' && (nx === '=' || nx === '>')) || (ch === '>' && nx === '=') || (ch === '-' && nx === '>')) e2 = i + 2;
        emetti(r.substring(i, e2), 'segno');
        i = e2;
      } else { emetti(ch, ''); i++; }
    }
    if (cur) segs.push([cur, cls]);
    if (segs.length === 0) segs.push(['', '']);
    out.push(segs);
  });
  return out;
}
function spanSegmenti(box, segs) {
  segs.forEach((s) => {
    if (s[1]) box.appendChild(el('span', 'hl-' + s[1], s[0]));
    else box.appendChild(document.createTextNode(s[0]));
  });
}
// A-6 (14.3.1, U5): l'ultima riga (senza commento) chiede un seguito: una delle parole o dei segni di U5
var SEGUITO_PAROLE = ['THEN', 'WITHIN', 'AND', 'OR', 'IMPLIES', 'NOT', 'IN'];
var SEGUITO_SEGNI = [':=', '->', '<=', '>=', '<>', ':', ',', '=', '<', '>', '+', '-', '*', '/', '^', ';'];
function chiedeSeguito(testo) {
  var righe = testo.split('\n'), i = righe.length - 1;
  var cs = coloraTesto(testo), ultimo = null;
  for (; i >= 0; i--) {
    var segs = cs[i].filter((s) => s[1] !== 'commento');
    var t = segs.map((s) => s[0]).join('').replace(/\s+$/, '');
    if (t.trim() !== '') { ultimo = {t: t, segs: segs}; break; }
  }
  if (!ultimo) return '';
  var graffe = 0;
  cs.forEach((segs) => segs.forEach((s) => { if (s[1] !== 'stringa' && s[1] !== 'commento') for (var k = 0; k < s[0].length; k++) { var c = s[0].charAt(k); if ('([{'.indexOf(c) >= 0) graffe++; else if (')]}'.indexOf(c) >= 0) graffe--; } }));
  var m = /([A-Za-z]+)$/.exec(ultimo.t);
  if (m && SEGUITO_PAROLE.indexOf(m[1]) >= 0 && ultimo.segs[ultimo.segs.length - 1][1] !== 'stringa') return m[1];
  for (var q = 0; q < SEGUITO_SEGNI.length; q++) if (ultimo.t.slice(-SEGUITO_SEGNI[q].length) === SEGUITO_SEGNI[q] && ultimo.segs[ultimo.segs.length - 1][1] !== 'stringa') return SEGUITO_SEGNI[q];
  if (graffe > 0) return '(';
  return '';
}

// ---- le righe della scheda: colorate, con le etichette di grado, di ripetizione, di citazione, e la marca di quelle non riconosciute
// C-13: la citazione trovata o no dai dati di check (trovata, tipo, dove, stato_blocco, motivo, nome), la frase qui
function testoCita(c) {
  if (c.trovata) {
    var s = T('cita_trovato_in', c.dove ? c.dove : T('in_questo_file'));
    if (c.tipo !== 'LEGATA') s += ', ' + T(c.stato_blocco === 'contratto' ? 'cita_stato_contratto' : (c.stato_blocco === 'ipotesi' ? 'cita_stato_ipotesi' : (c.stato_blocco === 'non_valido' ? 'cita_stato_non_valido' : 'cita_stato_senza')));
    return s;
  }
  if (c.tipo === 'IMPORT') return T('cita_non_trovato', T('cita_profilo', c.nome));
  return T('cita_non_trovato', c.motivo ? c.motivo : c.nome);
}
function creaRiga(oggetto, r) {
  var cl = r.colore === 'verde' ? 'verde' : (r.colore === 'giallo' ? 'ipo' : (r.colore === 'rosso' ? 'rosso' : ''));
  var rd = el('div', cl + (r.g >= 0 || r.nota ? ' riga-cl' : '') + (r.nonric !== undefined ? ' nonric' : '') + (r.ripetuto ? ' ripetuto' : ''));
  if (r.seg) spanSegmenti(rd, r.seg);
  else rd.appendChild(document.createTextNode(r.testo === '' ? ' ' : r.testo));
  rd.setAttribute('data-id', 'r-' + r.n);
  if (r.approvata) rd.appendChild(el('span', 'et', T('et_approvata', r.approvata)));
  if (r.grado) rd.appendChild(el('span', 'et grado', gradoTesto(r.grado)));
  if (r.ripete) rd.appendChild(el('span', 'et rip', r.ripete.sempre ? T('rip_sempre', r.ripete.ogni) : T('rip_volte', r.ripete.da, r.ripete.a, r.ripete.ogni)));
  if (r.cita) rd.appendChild(el('span', 'et cita' + (r.cita.trovata ? '' : ' manca'), testoCita(r.cita)));
  if (r.nonric !== undefined) rd.appendChild(el('div', 'nonric-nota', r.nonric ? T('nonric_nota_motivo', r.nonric) : T('nonric_nota')));
  if (r.g >= 0 || r.nota || r.nonric !== undefined) rd.addEventListener('click', () => clicRiga(oggetto, r));
  return rd;
}
// portare alla riga di una voce di un riquadro: la riga si evidenzia (fino al prossimo ridisegno) e si porta in vista
function portaARiga(n) {
  var e = document.querySelector('#scheda-righe [data-id="r-' + n + '"]');
  if (!e) return;
  var l = document.querySelectorAll('#scheda-righe .evidenza');
  for (var i = 0; i < l.length; i++) l[i].classList.remove('evidenza');
  e.classList.add('evidenza');
  if (e.scrollIntoView) e.scrollIntoView({block: 'nearest'});
}

// ---- le linguette del connettore: il connettore, le sue forme concrete, il suo piano di prova
function ridisegnaLinguette(c) {
  var box = $('scheda-linguette');
  svuota(box);
  var bl = c && c.blocchi ? c.blocchi : [];
  if (!c || bl.length === 0) { box.hidden = true; ling = ''; return; }
  if (ling && !bl[parseInt(ling.substring(1), 10)]) ling = '';
  box.hidden = false;
  var g = el('div', 'gruppo');
  g.setAttribute('role', 'tablist');
  var voci = [['', T('ling_connettore')]];
  bl.forEach((b, i) => voci.push(['b' + i, b.tipo === 'BINDING' ? (b.nome_proprio ? T('ling_forme_np', b.nome_proprio) : T('tipo_forme')) : T('tipo_piano')]));
  voci.forEach((v) => {
    var t = el('button', 'tab' + (ling === v[0] ? ' on' : ''), v[1]);
    t.id = 'lg-' + (v[0] || 'c');
    t.type = 'button';
    t.setAttribute('role', 'tab');
    t.setAttribute('aria-selected', ling === v[0] ? 'true' : 'false');
    t.addEventListener('click', () => { ling = v[0]; ridisegna(); });
    g.appendChild(t);
  });
  box.appendChild(g);
}

// ---- A-11 (14.5): i riquadri delle sezioni 12-15, neutri, nel posto della cosa a cui si riferiscono
function riquadro(titolo, id) {
  var b = el('div', 'riq');
  b.id = id;
  b.appendChild(el('div', 'riq-titolo', titolo));
  return b;
}
function vociRiga(box, voci) { voci.forEach((t) => box.appendChild(el('div', 'riq-voce', t))); }
function ridisegnaRapporto(o) {
  var box = $('scheda-rapporto');
  svuota(box);
  box.hidden = true;
  if (!o) return;
  var aggiungi = (b) => { box.appendChild(b); box.hidden = false; };
  if (o.tipo === 'BINDING') {
    var q = riquadro(T('rq_senza_forma'), 'rq-forme');
    if (!o.trovata) q.appendChild(el('div', 'riq-voce', T('rq_conn_non_trovato_el')));
    else if (o.senza_forma.length === 0) q.appendChild(el('div', 'riq-voce', T('rq_ogni_el')));
    else vociRiga(q, [T('rq_senza_forma_elenco', o.senza_forma.join(', '))]);
    q.removeChild(q.firstChild);
    aggiungi(q);
  } else if (o.tipo === 'VERIFICATION') {
    var qc = riquadro(T('rq_copertura'), 'rq-copertura');
    qc.removeChild(qc.firstChild);
    if (!o.copertura.csc_trovata) qc.appendChild(el('div', 'riq-voce', T('rq_conn_non_trovato_cop')));
    else {
      // C-6: i mezzi e le promesse non eseguite arrivano come dati (copertura.mezzi, copertura.non_eseguite); le frasi si compongono qui
      var riga13 = (testa, ids) => {
        var d = el('div', 'riq-voce');
        d.appendChild(document.createTextNode(testa));
        if (ids.length === 0) d.appendChild(document.createTextNode(T('nessuna_parola')));
        else ids.forEach((id, k) => {
          if (k > 0) d.appendChild(document.createTextNode(', '));
          var bt = el('button', 'btn neutro mini riq-nome', id);
          bt.type = 'button';
          bt.setAttribute('data-id', 'cp-' + id);
          bt.addEventListener('click', () => {
            var c = cscDi(o.nome);
            ling = '';
            ridisegna();
            if (c && c.scheda.ids && c.scheda.ids[id]) portaARiga(c.scheda.ids[id]);
          });
          d.appendChild(bt);
        });
        qc.appendChild(d);
      };
      o.copertura.mezzi.forEach((mz) => riga13(T('cop_osserva', mz.nome), mz.promesse));
      riga13(T('cop_non_eseguite'), o.copertura.non_eseguite);
    }
    aggiungi(qc);
  }
  if (o.tipo === 'PROFILE' && o.estensioni.length > 0) {
    // O-3 (14.7): «specie» per KIND e «livello dell'estensione» per LEVEL, solo come etichette; il testo dei campi è colorato
    var qe = riquadro(T('rq_estensioni', o.estensioni.length), 'rq-estensioni');
    o.estensioni.forEach((e) => {
      var carta = el('div', 'riq-ext');
      var th = el('div', 'riq-voce');
      th.appendChild(el('strong', null, e.nome));
      th.appendChild(document.createTextNode(T('rq_est_dettagli', e.kind, e.level, e.riduzione ? T('rq_est_forma_estesa') : '')));
      carta.appendChild(th);
      var cod = el('div', 'codice');
      var cs = coloraTesto(e.campi.map((c) => c.testo).join('\n'));
      e.campi.forEach((c, k) => { var d = el('div'); spanSegmenti(d, cs[k]); cod.appendChild(d); });
      carta.appendChild(cod);
      qe.appendChild(carta);
    });
    aggiungi(qe);
  }
  var s = o.scheda;
  if (s && s.da_giudicare && s.da_giudicare.length > 0) {
    var qg = riquadro(T('rq_giudicare', s.da_giudicare.length), 'rq-giudicare');
    s.da_giudicare.forEach((v) => {
      var d = el('div', 'riq-voce riq-clic', T('riga_n_msg', v.riga, v.voce));
      d.addEventListener('click', () => portaARiga(v.riga));
      qg.appendChild(d);
    });
    aggiungi(qg);
  }
  if (s && s.non_eseguiti && s.non_eseguiti.length > 0 && !esBlocco(o)) {
    var qn = riquadro(T('rq_non_eseguiti', T('sez_non_eseguiti'), s.non_eseguiti.length), 'rq-non-eseguiti');
    s.non_eseguiti.forEach((v) => qn.appendChild(el('div', 'riq-voce', T(v.righe.length === 1 ? 'ne_riga' : 'ne_righe', v.nome, v.righe.join(', ')))));
    aggiungi(qn);
  }
}
// «formule non valutate» accanto a «nessun errore» (14.5, esiti onesti): solo per ciò che la scheda scelta mostra
function formuleNonValutate() {
  var o = oggettoSel();
  return !!(o && o.scheda && o.scheda.non_eseguiti && o.scheda.non_eseguiti.length > 0);
}

// ---- le azioni delle schede dei blocchi
function preparaModuloBlocco(titolo) {
  chiudiModulo();
  var m = $('scheda-modulo');
  svuota(m);
  notaScheda('');
  m.hidden = false;
  m.className = 'modulo';
  moduloScheda = {tipo: sel ? sel.tipo : '', nome: sel ? sel.nome : ''};
  if (titolo) m.appendChild(el('div', 'titolo', titolo));
  return m;
}
function vNomeBlocco(altri) {
  return (s) => {
    var t = s.trim();
    if (!NOME.test(t)) return T('nome_blocco_err');
    if (M.riservate.indexOf(t) >= 0) return T('parola_linguaggio');
    if (altri.indexOf(t) >= 0) return T('nome_esiste_altro');
    return '';
  };
}
function rigaDi(o, n) { for (var i = 0; i < o.scheda.righe.length; i++) if (o.scheda.righe[i].n === n) return o.scheda.righe[i]; return null; }
// scrive UNA riga in un blocco: nuova (dopo l'ultima riga dello stesso genere, o prima di END) o al posto di quella cliccata
function scriviRigaBlocco(o, esistente, ultimaDelGenere, testo) {
  var ra, da, prima, nuovo;
  if (esistente) { da = esistente.n; prima = esistente.testo; nuovo = testo; }
  else if (ultimaDelGenere) { da = ultimaDelGenere; prima = rigaDi(o, da).testo; nuovo = prima + '\n' + testo; }
  else { da = o.a; ra = rigaDi(o, da); if (!ra) return; prima = ra.testo; nuovo = testo + '\n' + prima; }
  chiudiScheda();
  invia({azione: 'blocco_scrivi', 'file': o.file, da: String(da), a: String(da), prima: prima, testo: nuovo});
}
function elementiOpz(o, soloSenza) {
  var senza = o.elementi.filter((e) => e.senza_forma), altri = o.elementi.filter((e) => !e.senza_forma);
  return (soloSenza ? senza : senza.concat(altri));
}
function apriFormaConcreta(o, esistente) {
  var m = preparaModuloBlocco(esistente ? T('fc_di', esistente.elemento) : T('fc_nuova', o.nome));
  var opz = elementiOpz(o).map((e) => [e.nome, e.senza_forma ? T('senza_forma_opz', e.nome) : e.nome]);
  if (opz.length === 0) { m.appendChild(el('div', 'cc-msg', T('nessun_elemento_fc'))); m.appendChild(pulsante('f-annulla', T('chiudi'), '', () => chiudiScheda())); return; }
  var se = scelta(m, 'f-elemento', T('f_elemento'), opz);
  if (esistente) se.value = esistente.elemento;
  var cf = campoV(m, 'f-frase', T('f_cosa_si_vede'), esistente ? esistente.frase : '', vFrase(400, false));
  var riga = el('div', 'riga-btn');
  riga.appendChild(pulsante('f-ok', T('salva'), 'primario', () => {
    if (!cf.verifica()) return;
    var testo = '  BIND ' + se.value + ': VERBAL "' + cf.campo.value.trim() + '"';
    var ult = 0;
    o.righe_forma.forEach((r) => { ult = Math.max(ult, r.n); });
    scriviRigaBlocco(o, esistente ? rigaDi(o, esistente.n) : null, ult, testo);
  }));
  riga.appendChild(pulsante('f-annulla', T('annulla'), '', () => chiudiScheda()));
  m.appendChild(riga);
}
function apriMezzo(o, esistente) {
  var m = preparaModuloBlocco(esistente ? T('mezzo_titolo', esistente.nome) : T('mezzo_nuovo', o.nome));
  var altri = o.righe_forma.filter((r) => !esistente || r.n !== esistente.n).map((r) => r.nome);
  var cn = campoV(m, 'f-nome', T('f_nome'), esistente ? esistente.nome : '', vNomeBlocco(altri));
  m.appendChild(el('div', 'cc-eti', T('f_cosa_osserva')));
  var lista = el('div', 'ap-elenco');
  var caselle = [];
  o.elementi.forEach((e) => {
    var l = el('label', 'ap-voce');
    var c = el('input');
    c.type = 'checkbox';
    c.id = 'f-oss-' + e.nome;
    c.checked = !!esistente && esistente.osserva.indexOf(e.nome) >= 0;
    l.appendChild(c);
    l.appendChild(el('span', null, e.nome));
    lista.appendChild(l);
    caselle.push([e.nome, c]);
  });
  m.appendChild(lista);
  var eo = el('div', 'campo-err');
  eo.id = 'e-f-osserva';
  m.appendChild(eo);
  var cr = campoV(m, 'f-risoluzione', T('f_risoluzione'), esistente ? esistente.risoluzione : '', (v) => /^[0-9]+(\.[0-9]+)?$/.test(v.trim()) && parseFloat(v) > 0 ? '' : T('v_risoluzione'));
  var su = scelta(m, 'f-unita-r', T('f_unita_risoluzione'), [['s', T('secondi')], ['ms', T('millisecondi')]]);
  if (esistente && esistente.unita) su.value = esistente.unita;
  var us = scelta(m, 'f-usando', T('f_con_forme'), [['', T('nessuna_parola')]].concat(o.binding_nomi.map((n) => [n, n])));
  if (esistente && esistente.usando) us.value = esistente.usando;
  var riga = el('div', 'riga-btn');
  riga.appendChild(pulsante('f-ok', T('salva'), 'primario', () => {
    var a1 = cn.verifica(), a2 = cr.verifica();
    var oss = caselle.filter((x) => x[1].checked).map((x) => x[0]);
    eo.textContent = oss.length === 0 ? T('v_almeno_un_elemento') : '';
    if (!a1 || !a2 || oss.length === 0) return;
    var testo = '  MEANS ' + cn.campo.value.trim() + ' OBSERVES ' + oss.join(', ') + ' RESOLUTION ' + cr.campo.value.trim() + ' ' + su.value + (us.value ? ' USING ' + us.value : '');
    var ult = 0;
    o.righe_forma.forEach((r) => { ult = Math.max(ult, r.n); });
    scriviRigaBlocco(o, esistente ? rigaDi(o, esistente.n) : null, ult, testo);
  }));
  riga.appendChild(pulsante('f-annulla', T('annulla'), '', () => chiudiScheda()));
  m.appendChild(riga);
}
function apriNuoveForme(cscNome) {
  var c = cscDi(cscNome);
  if (!c) return;
  var m = preparaModuloBlocco(T('nuove_forme_titolo', cscNome));
  var usati = (c.blocchi || []).filter((b) => b.tipo === 'BINDING' && b.nome_proprio).map((b) => b.nome_proprio);
  var cn = campoV(m, 'f-nome', T('f_nome_forme'), usati.indexOf(T('nome_forme')) < 0 ? T('nome_forme') : '', vNomeBlocco(usati));
  var riga = el('div', 'riga-btn');
  riga.appendChild(pulsante('f-ok', T('crea'), 'primario', () => {
    if (!cn.verifica()) return;
    var nome = cn.campo.value.trim();
    chiudiScheda();
    invia({azione: 'blocco_crea', cosa: 'forme', csc: cscNome, nome: nome});
  }));
  riga.appendChild(pulsante('f-annulla', T('annulla'), '', () => chiudiScheda()));
  m.appendChild(riga);
  cn.verifica();
}
function apriNuovoPiano(cscNome) {
  var m = preparaModuloBlocco(T('nuovo_piano_titolo', cscNome));
  var riga = el('div', 'riga-btn');
  riga.appendChild(pulsante('f-ok', T('si'), 'primario', () => { chiudiScheda(); invia({azione: 'blocco_crea', cosa: 'piano', csc: cscNome, nome: ''}); }));
  riga.appendChild(pulsante('f-annulla', T('no'), '', () => chiudiScheda()));
  m.appendChild(riga);
}
function apriNuovoProfilo() {
  var m = preparaModuloBlocco(T('nuovo_profilo'));
  var usati = (M.profili || []).map((p) => p.nome);
  var cn = campoV(m, 'f-nome', T('f_nome_profilo'), '', vNomeBlocco(usati));
  var cs = campoV(m, 'f-frase', T('scopo_una_frase'), '', vFrase(200, false));
  var riga = el('div', 'riga-btn');
  riga.appendChild(pulsante('f-ok', T('crea'), 'primario', () => {
    var a1 = cn.verifica(), a2 = cs.verifica();
    if (!a1 || !a2) return;
    var msg = {azione: 'profilo_crea', nome: cn.campo.value.trim(), scopo: cs.campo.value.trim()};
    chiudiScheda();
    invia(msg);
  }));
  riga.appendChild(pulsante('f-annulla', T('annulla'), '', () => chiudiScheda()));
  m.appendChild(riga);
}
function scheletroEstensione() {
  return ['  EXTENSION ' + T('sk_nome'), '    KIND     FUNCTION', '    LEVEL    CSC', '    PARAMS   (x: Real) : Boolean', '    FORM     "' + T('sk_nome') + ' x"',
    '    MEANING  "' + T('sk_da_completare') + '"', '    VERIFY   V1 C1', '    SOURCE   "' + T('sk_da_completare') + '"', '  END'].join('\n');
}
function azioniBlocco(a, o) {
  var contratto = o.stato === 'contratto';
  var tolto = (id, testo, perche, fn) => { var b = pulsante(id, testo, 'togli', fn, !!perche); if (perche) b.title = perche; a.appendChild(b); };
  if (o.tipo === 'BINDING') {
    a.appendChild(pulsante('b-forma', T('b_forma'), '', () => apriFormaConcreta(o, null), contratto));
    if (contratto) a.lastChild.title = T('tt_forme_approvate');
    var bi = pulsante('b-approva-forme', T('b_approva_forme'), '', () => {
      chiudiScheda();
      appr = {chiave: chiaveSel(), modo: 'blocco', scelte: {}, ids: [], numero: ''};
      ridisegna();
    }, contratto || !!(o.senza_nome ? T('senza_nome_motivo') : '') || o.stato !== 'ipotesi');
    bi.title = contratto ? T('gia_approvate') : ((o.senza_nome ? T('senza_nome_motivo') : '') || (o.stato !== 'ipotesi' ? T('tt_forme_non_ipotesi') : ''));
    a.appendChild(bi);
    if (!o.nome_proprio && (o.senza_nome ? T('senza_nome_motivo') : '')) {
      a.appendChild(pulsante('b-nome', T('b_dai_nome'), '', () => {
        var r = rigaDi(o, o.riga);
        if (r) apriCasella(o, o.riga, o.riga, r.testo + ' AS ', T('dai_nome_titolo'));
      }));
      var nt = el('div', 'cc-nota', (o.senza_nome ? T('senza_nome_motivo') : ''));
      nt.id = 'nota-senza-nome';
      a.appendChild(nt);
    }
    tolto('b-togli-blocco', T('b_togli_forme'), contratto ? T('tt_forme_righe_appr') : '', () => {
      confermaScheda(T('togli_forme_conf', o.nome_proprio ? T('forme_nome_prefisso', o.nome_proprio) : '', o.nome, o.file),
        {azione: 'blocco_scrivi', 'file': o.file, da: String(o.riga), a: String(o.a), prima: o.scheda.righe.map((r) => r.testo).join('\n'), testo: ''});
    });
  } else if (o.tipo === 'VERIFICATION') {
    a.appendChild(pulsante('b-mezzo', T('b_mezzo'), '', () => apriMezzo(o, null)));
    var np = el('span', 'cc-nota', T('nota_piano'));
    np.id = 'nota-piano';
    a.appendChild(np);
    tolto('b-togli-blocco', T('b_togli_piano'), '', () => {
      confermaScheda(T('togli_piano_conf', o.nome, o.file),
        {azione: 'blocco_scrivi', 'file': o.file, da: String(o.riga), a: String(o.a), prima: o.scheda.righe.map((r) => r.testo).join('\n'), testo: ''});
    });
  } else {
    a.appendChild(pulsante('b-estensione', T('b_estensione'), '', () => {
      var r = rigaDi(o, o.a);
      if (r) apriCasella(o, o.a, o.a, scheletroEstensione() + '\n' + r.testo, T('est_titolo', o.nome));
    }, contratto));
    var bp = pulsante('b-approva-profilo', T('b_approva_profilo'), '', () => {
      chiudiScheda();
      appr = {chiave: chiaveSel(), modo: 'blocco', scelte: {}, ids: [], numero: ''};
      ridisegna();
    }, contratto);
    if (contratto) bp.title = T('gia_approvato');
    a.appendChild(bp);
    var perche = o.importato_da.length > 0 ? T('tt_importato_da', o.importato_da.join(', ')) : (contratto ? T('tt_approvato_no_togli') : '');
    tolto('b-togli-profilo', T('b_togli_profilo'), perche, () => {
      confermaScheda(T('togli_profilo_conf', o.nome, o.file), {azione: 'profilo_togli', nome: o.nome});
    });
  }
}
// click su una riga di un blocco con un modulo (14.3.4): la riga BIND e la riga MEANS aprono il loro modulo; le altre la casella
var clicRigaTesto = clicRiga;
clicRiga = function (oggetto, r) {
  if (esBlocco(oggetto) && r.nota === 'testo' && !(oggetto.stato === 'contratto' && oggetto.tipo !== 'VERIFICATION')) {
    var f = oggetto.righe_forma ? oggetto.righe_forma.filter((x) => x.n === r.n)[0] : null;
    if (f && oggetto.tipo === 'BINDING') { apriFormaConcreta(oggetto, f); return; }
    if (f && oggetto.tipo === 'VERIFICATION') { apriMezzo(oggetto, f); return; }
  }
  if (esBlocco(oggetto) && r.nota === 'testo' && oggetto.stato === 'contratto' && oggetto.tipo !== 'VERIFICATION') { chiudiScheda(); notaScheda(GIA_APPROVATA()); return; }
  if (r.nonric !== undefined && !r.nota && r.g < 0) { chiudiScheda(); return; }
  clicRigaTesto(oggetto, r);
};

// ---- Approva le forme concrete e Approva il profilo (14.6): l'elenco prima del numero
function ridisegnaApprovaBlocco(o, box, chiave) {
  if (!appr || appr.modo !== 'blocco') { box.hidden = true; return; }
  box.hidden = false;
  var profilo = o.tipo === 'PROFILE';
  box.appendChild(el('div', 'cc-testa', profilo ? T('apb_profilo', o.nome) : T('apb_forme', o.nome_proprio ? T('forme_nome_prefisso', o.nome_proprio) : '', o.nome)));
  var riga = el('div', 'riga-btn');
  var blocca = o.scheda.blocca;
  if (blocca.length > 0) {
    box.appendChild(el('div', 'cc-msg cc-err', T('ap_prima_errori')));
    var lb = el('div', 'cc-elenco');
    blocca.forEach((t) => lb.appendChild(el('div', null, '● ' + t)));
    box.appendChild(lb);
    riga.appendChild(pulsante('a-annulla', T('chiudi'), '', () => { appr = null; ridisegna(); }));
    box.appendChild(riga);
    return;
  }
  box.appendChild(el('div', 'cc-msg', T('ap_saranno')));
  var voci = [];
  if (profilo) {
    voci.push(T('apb_voce_profilo', o.nome, o.versione));
    o.estensioni.forEach((e) => voci.push(T('apb_voce_est', e.nome)));
  } else {
    voci.push(T('apb_voce_forme', o.nome_proprio ? T('forme_nome_prefisso', o.nome_proprio) : '', o.nome));
    o.righe_forma.forEach((r) => voci.push(T('apb_voce_fc', r.elemento)));
  }
  var l = el('div', 'ap-elenco ap-si');
  voci.forEach((t) => l.appendChild(el('div', null, '● ' + t)));
  box.appendChild(l);
  var ok;
  var aggiorna = () => { if (ok) ok.disabled = !numeroValido(); };
  campoNumero(box, aggiorna);
  ok = pulsante('a-ok', T(profilo ? 'b_approva_profilo' : 'b_approva_forme'), 'primario', () => {
    var numero = appr.numero.trim();
    ok.disabled = true;
    appr = null;
    invia({azione: 'approva_blocco', 'file': o.file, csc: o.csc_arg, modo: profilo ? 'profilo' : 'forme', decisione: numero});
  });
  riga.appendChild(ok);
  riga.appendChild(pulsante('a-annulla', T('annulla'), '', () => { appr = null; ridisegna(); }));
  box.appendChild(riga);
  aggiorna();
}
$('b-profilo').addEventListener('click', () => apriNuovoProfilo());

// ---- l'ultima cosa: le etichette fisse nella lingua della pagina (<html lang>)
applicaLingua();

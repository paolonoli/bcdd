// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Noli Paolo
// 010:1:1 edwv2: le impostazioni di WebView2 che la libreria `webview` non offre: niente menu del tasto destro, niente tasti del browser
// (F5, Ctrl+P, F12, zoom), nessuna navigazione oltre la prima (la pagina è quella incorporata), nessuna finestra nuova; più la finestra
// principale (icona, massimizzata, avviso di finestra attiva/inattiva). Solo Windows; si compila con `webview.cc` (vedi `edwebview2.nim`).
#include <windows.h>
#include <commctrl.h>
#include <shellapi.h>
#include <atomic>
#include "WebView2.h"
#include "webview/api.h"

namespace {

// 010:1:1b Gli identificatori delle interfacce (WebView2.h li dichiara soltanto; qui sono scritti una volta, dall'intestazione).
const GUID kIidSettings3 = {0xfdb5ab74, 0xaf33, 0x4854, {0x84, 0xf0, 0x0a, 0x63, 0x1d, 0xeb, 0x5e, 0xba}};
const GUID kIidSettings4 = {0xcb56846c, 0x4168, 0x4d53, {0xb0, 0x4f, 0x03, 0xb6, 0xd6, 0x79, 0x6f, 0xf2}};
const GUID kIidNav = {0x9adbe429, 0xf36d, 0x432b, {0x9d, 0xdc, 0xf8, 0x88, 0x1f, 0xbd, 0x76, 0xe3}};
const GUID kIidNuova = {0xd4c185fe, 0xc81c, 0x4989, {0x97, 0xaf, 0x2d, 0x3f, 0xa7, 0xab, 0x56, 0x51}};
const GUID kIidPerm = {0x15e1c6a3, 0xc72a, 0x4df3, {0x91, 0xd7, 0xd0, 0x97, 0xfb, 0xec, 0x6b, 0xfd}};

typedef void (*attiva_cb)(int attiva);
attiva_cb g_attiva = nullptr;
int g_prima = 1;

// 010:1:2 Un gestore COM minimo: un solo oggetto, conteggio finto (vive quanto il processo).
template <typename I, const GUID *IID_I> struct Gestore : public I {
  ULONG STDMETHODCALLTYPE AddRef() override { return 2; }
  ULONG STDMETHODCALLTYPE Release() override { return 1; }
  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void **ppv) override {
    if (IsEqualGUID(riid, *IID_I) || IsEqualGUID(riid, IID_IUnknown)) {
      *ppv = this;
      return S_OK;
    }
    *ppv = nullptr;
    return E_NOINTERFACE;
  }
};

struct Navigazione : Gestore<ICoreWebView2NavigationStartingEventHandler, &kIidNav> {
  HRESULT STDMETHODCALLTYPE Invoke(ICoreWebView2 *, ICoreWebView2NavigationStartingEventArgs *a) override {
    // la sola navigazione ammessa è la prima (il caricamento della pagina incorporata)
    if (g_prima) {
      g_prima = 0;
    } else {
      a->put_Cancel(TRUE);
    }
    return S_OK;
  }
};

struct FinestraNuova : Gestore<ICoreWebView2NewWindowRequestedEventHandler, &kIidNuova> {
  HRESULT STDMETHODCALLTYPE Invoke(ICoreWebView2 *, ICoreWebView2NewWindowRequestedEventArgs *a) override {
    a->put_Handled(TRUE);
    return S_OK;
  }
};

struct Permesso : Gestore<ICoreWebView2PermissionRequestedEventHandler, &kIidPerm> {
  HRESULT STDMETHODCALLTYPE Invoke(ICoreWebView2 *, ICoreWebView2PermissionRequestedEventArgs *a) override {
    a->put_State(COREWEBVIEW2_PERMISSION_STATE_DENY);
    return S_OK;
  }
};

Navigazione g_nav;
FinestraNuova g_nuova;
Permesso g_perm;

LRESULT CALLBACK sottoclasse(HWND h, UINT m, WPARAM w, LPARAM l, UINT_PTR, DWORD_PTR) {
  if (m == WM_ACTIVATE && g_attiva) g_attiva(LOWORD(w) != WA_INACTIVE ? 1 : 0);
  return DefSubclassProc(h, m, w, l);
}

} // namespace

extern "C" {

// 010:1:3 Configura la vista dopo `webview_create`: ritorna 0 se tutto è andato a posto, altrimenti il numero del passo che non è riuscito.
int bcdd_wv2_configura(webview_t w) {
  auto *ctl = static_cast<ICoreWebView2Controller *>(
      webview_get_native_handle(w, WEBVIEW_NATIVE_HANDLE_KIND_BROWSER_CONTROLLER));
  if (!ctl) return 1;
  ICoreWebView2 *wv = nullptr;
  if (FAILED(ctl->get_CoreWebView2(&wv)) || !wv) return 2;
  ICoreWebView2Settings *s = nullptr;
  if (FAILED(wv->get_Settings(&s)) || !s) return 3;
  s->put_AreDefaultContextMenusEnabled(FALSE);
  s->put_IsZoomControlEnabled(FALSE);
  s->put_IsStatusBarEnabled(FALSE);
  s->put_IsBuiltInErrorPageEnabled(FALSE);
  s->put_AreHostObjectsAllowed(FALSE);
  ICoreWebView2Settings3 *s3 = nullptr;
  if (SUCCEEDED(s->QueryInterface(kIidSettings3, reinterpret_cast<void **>(&s3))) && s3) s3->put_AreBrowserAcceleratorKeysEnabled(FALSE);
  ICoreWebView2Settings4 *s4 = nullptr;
  if (SUCCEEDED(s->QueryInterface(kIidSettings4, reinterpret_cast<void **>(&s4))) && s4) {
    s4->put_IsGeneralAutofillEnabled(FALSE);
    s4->put_IsPasswordAutosaveEnabled(FALSE);
  }
  EventRegistrationToken t;
  wv->add_NavigationStarting(&g_nav, &t);
  wv->add_NewWindowRequested(&g_nuova, &t);
  wv->add_PermissionRequested(&g_perm, &t);
  return 0;
}

// 010:1:4 La finestra principale: icona (la risorsa 1 dell'eseguibile, se c'è), avviso di attivazione, e massimizzata se `massimizza`.
void bcdd_wv2_finestra(webview_t w, attiva_cb cb, int massimizza) {
  g_attiva = cb;
  HWND h = static_cast<HWND>(webview_get_window(w));
  if (!h) return;
  HINSTANCE hi = GetModuleHandleW(nullptr);
  HICON grande = (HICON)LoadImageW(hi, MAKEINTRESOURCEW(1), IMAGE_ICON, GetSystemMetrics(SM_CXICON), GetSystemMetrics(SM_CYICON), LR_DEFAULTCOLOR);
  HICON piccola = (HICON)LoadImageW(hi, MAKEINTRESOURCEW(1), IMAGE_ICON, GetSystemMetrics(SM_CXSMICON), GetSystemMetrics(SM_CYSMICON), LR_DEFAULTCOLOR);
  if (grande) SendMessageW(h, WM_SETICON, ICON_BIG, (LPARAM)grande);
  if (piccola) SendMessageW(h, WM_SETICON, ICON_SMALL, (LPARAM)piccola);
  SetWindowSubclass(h, sottoclasse, 1, 0);
  if (massimizza) {
    WINDOWPLACEMENT p = {};
    p.length = sizeof(p);
    GetWindowPlacement(h, &p);
    p.showCmd = SW_SHOWMAXIMIZED;
    SetWindowPlacement(h, &p);
  }
}

// 010:1:5 Per le prove: 1 se la finestra è massimizzata, e il suo rettangolo (sinistra, alto, destra, basso) in `r`.
int bcdd_wv2_stato(webview_t w, int *r) {
  HWND h = static_cast<HWND>(webview_get_window(w));
  if (!h) return -1;
  RECT q;
  GetWindowRect(h, &q);
  r[0] = q.left; r[1] = q.top; r[2] = q.right; r[3] = q.bottom;
  return IsZoomed(h) ? 1 : 0;
}

} // extern "C"

# Third-party code in `editor/`

`bcdd-editor` is distributed under BSD-3-Clause (Copyright 2026 Noli Paolo). The Windows build contains the following code of others.

| Component | Where | Licence | Use |
|---|---|---|---|
| `webview` 0.12.0 (Serge Zaitsev, Steffen Andre Langnes) | `editor/windows/webview/` (core headers and `webview.cc` only; its `LICENSE` is kept) | MIT | window and WebView2 binding, compiled into `bcdd-editor.exe`. One change: `win32_edge.hh`, `embed()`: the WebView2 user data folder is `%LOCALAPPDATA%\bcdd-editor` (local, never roaming) with a fixed name instead of the executable name. |
| WebView2 SDK 1.0.2739.15 (Microsoft), header `WebView2.h` | not in the repository: `editor/windows/costruisci.sh` downloads it from nuget.org into `editor/windows/include/` | BSD-3-Clause (Microsoft) | compile-time header only. |
| WebView2 Runtime (Microsoft Edge) | installed in Windows 11 (Evergreen) | Microsoft licence, not redistributed | renders the page. |

`WebView2Loader.dll` is **not** needed: the `webview` library is compiled with its built-in loader, which finds the installed Runtime. libstdc++ and libgcc are linked statically; `bcdd-editor.exe` needs only system DLLs.

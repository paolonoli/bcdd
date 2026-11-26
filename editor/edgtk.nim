# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026, Noli Paolo
# 004:1:1 edgtk: le dichiarazioni `importc` di GLib/GIO, GTK3, WebKit2GTK 4.1 e JavaScriptCore.
# Solo la 4.1: nessun ripiego sulla 4.0. Schema dichiarativo come in Security-Scanner (letto, non copiato): niente pacchetti
# Nimble, i flag vengono da pkg-config.
{.passC: gorge("pkg-config --cflags gtk+-3.0 webkit2gtk-4.1 javascriptcoregtk-4.1").}
{.passL: gorge("pkg-config --libs gtk+-3.0 webkit2gtk-4.1 javascriptcoregtk-4.1").}

type
  GError* {.bycopy.} = object
    domain*: uint32
    code*: cint
    message*: cstring
  GAsyncReadyCallback* = proc(source, res, data: pointer) {.cdecl.}
  GCallback* = pointer
  GdkRGBA* {.bycopy.} = object
    red*, green*, blue*, alpha*: cdouble

const
  G_SUBPROCESS_FLAGS_STDIN_PIPE* = 1.cint
  G_SUBPROCESS_FLAGS_STDOUT_PIPE* = 4.cint
  G_SUBPROCESS_FLAGS_STDERR_PIPE* = 16.cint
  GTK_WINDOW_TOPLEVEL* = 0.cint
  WEBKIT_LOAD_FINISHED* = 3.cint
  WEBKIT_POLICY_DECISION_TYPE_NAVIGATION_ACTION* = 0.cint
  WEBKIT_USER_CONTENT_INJECT_TOP_FRAME* = 1.cint
  WEBKIT_USER_SCRIPT_INJECT_AT_DOCUMENT_END* = 1.cint
  # WebKitHardwareAccelerationPolicy, riletto in webkit/WebKitSettings.h: ON_DEMAND = 0, ALWAYS = 1, NEVER = 2
  WEBKIT_HW_POLICY_ON_DEMAND* = 0.cint
  WEBKIT_HW_POLICY_ALWAYS* = 1.cint
  WEBKIT_HW_POLICY_NEVER* = 2.cint

# GLib, GObject, GIO
proc g_free*(mem: pointer) {.importc, cdecl.}
proc g_error_free*(e: ptr GError) {.importc, cdecl.}
proc g_main_loop_new*(ctx: pointer, running: cint): pointer {.importc, cdecl.}
proc g_main_loop_run*(l: pointer) {.importc, cdecl.}
proc g_main_loop_quit*(l: pointer) {.importc, cdecl.}
proc g_main_loop_unref*(l: pointer) {.importc, cdecl.}
proc g_object_unref*(o: pointer) {.importc, cdecl.}
proc g_object_set*(o: pointer, prop: cstring) {.importc, cdecl, varargs.}
proc g_signal_connect_data*(instance: pointer, signal: cstring, handler: GCallback, data: pointer,
    destroy: pointer, flags: cint): culong {.importc, cdecl.}
proc g_bytes_get_data*(b: pointer, size: ptr csize_t): pointer {.importc, cdecl.}
proc g_bytes_unref*(b: pointer) {.importc, cdecl.}
proc g_bytes_new*(data: pointer, size: csize_t): pointer {.importc, cdecl.}
proc g_subprocess_newv*(argv: cstringArray, flags: cint, err: ptr ptr GError): pointer {.importc, cdecl.}
proc g_subprocess_communicate_async*(sub, stdinBuf, cancellable: pointer, cb: GAsyncReadyCallback,
    data: pointer) {.importc, cdecl.}
proc g_subprocess_communicate*(sub, stdinBuf, cancellable: pointer, stdoutBuf, stderrBuf: ptr pointer,
    err: ptr ptr GError): cint {.importc, cdecl.}
proc g_subprocess_communicate_finish*(sub, res: pointer, stdoutBuf, stderrBuf: ptr pointer,
    err: ptr ptr GError): cint {.importc, cdecl.}
proc g_subprocess_send_signal*(sub: pointer, sig: cint) {.importc, cdecl.}
proc g_subprocess_get_if_exited*(sub: pointer): cint {.importc, cdecl.}
proc g_subprocess_get_if_signaled*(sub: pointer): cint {.importc, cdecl.}
proc g_subprocess_get_exit_status*(sub: pointer): cint {.importc, cdecl.}

# GTK3
proc gtk_init_check*(argc: ptr cint, argv: pointer): cint {.importc, cdecl.}
proc gtk_main*() {.importc, cdecl.}
proc gtk_main_quit*() {.importc, cdecl.}
proc gtk_window_new*(t: cint): pointer {.importc, cdecl.}
proc gtk_window_set_title*(w: pointer, title: cstring) {.importc, cdecl.}
proc gtk_window_set_default_size*(w: pointer, width, height: cint) {.importc, cdecl.}
proc gtk_window_is_active*(w: pointer): cint {.importc, cdecl.}
proc gtk_settings_get_default*(): pointer {.importc, cdecl.}
proc gtk_container_add*(c, w: pointer) {.importc, cdecl.}
proc gtk_widget_override_background_color*(w: pointer, state: cint, c: ptr GdkRGBA) {.importc, cdecl.}
proc gtk_widget_show_all*(w: pointer) {.importc, cdecl.}

# 001:10:1 la finestra di scelta della cartella
type GSListNodo* = object
  data*: pointer
  next*: ptr GSListNodo
const
  GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER* = 2.cint
  GTK_RESPONSE_CANCEL* = -6.cint
  GTK_RESPONSE_ACCEPT* = -3.cint
proc gtk_file_chooser_dialog_new*(title: cstring, parent: pointer, action: cint, b1: cstring, r1: cint, b2: cstring,
    r2: cint, fine: pointer): pointer {.importc, cdecl.}
proc gtk_dialog_run*(d: pointer): cint {.importc, cdecl.}
proc gtk_file_chooser_set_current_folder*(c: pointer, path: cstring): cint {.importc, cdecl.}
proc gtk_file_chooser_get_filename*(c: pointer): cstring {.importc, cdecl.}
proc gtk_window_set_transient_for*(w, padre: pointer) {.importc, cdecl.}
proc gtk_file_chooser_set_select_multiple*(c: pointer, v: cint) {.importc, cdecl.}
proc gtk_file_chooser_set_local_only*(c: pointer, v: cint) {.importc, cdecl.}
proc gtk_file_chooser_get_files*(c: pointer): ptr GSListNodo {.importc, cdecl.}      # una GSList di GFile (da liberare)
proc g_file_get_path*(f: pointer): cstring {.importc, cdecl.}                        # nil se il file non ha un percorso locale (gvfs non montato)
proc g_file_get_uri*(f: pointer): cstring {.importc, cdecl.}
proc g_slist_free*(l: ptr GSListNodo) {.importc, cdecl.}
proc gtk_widget_destroy*(w: pointer) {.importc, cdecl.}
proc gtk_events_pending*(): cint {.importc, cdecl.}
proc gtk_main_iteration*(): cint {.importc, cdecl.}

# WebKit2GTK 4.1
proc webkit_web_context_new_ephemeral*(): pointer {.importc, cdecl.}
proc webkit_web_view_new_with_context*(ctx: pointer): pointer {.importc, cdecl.}
proc webkit_web_view_get_user_content_manager*(v: pointer): pointer {.importc, cdecl.}
proc webkit_web_view_get_settings*(v: pointer): pointer {.importc, cdecl.}
proc webkit_web_view_set_background_color*(v: pointer, c: ptr GdkRGBA) {.importc, cdecl.}
proc webkit_web_view_load_html*(v: pointer, content: cstring, baseUri: cstring) {.importc, cdecl.}
proc webkit_web_view_evaluate_javascript*(v: pointer, script: cstring, length: int, worldName, sourceUri: cstring,
    cancellable: pointer, cb: GAsyncReadyCallback, data: pointer) {.importc, cdecl.}
proc webkit_web_view_evaluate_javascript_finish*(v, res: pointer, err: ptr ptr GError): pointer {.importc, cdecl.}
proc webkit_settings_set_enable_developer_extras*(s: pointer, v: cint) {.importc, cdecl.}
proc webkit_settings_set_javascript_can_open_windows_automatically*(s: pointer, v: cint) {.importc, cdecl.}
proc webkit_settings_set_enable_html5_local_storage*(s: pointer, v: cint) {.importc, cdecl.}
proc webkit_settings_set_enable_html5_database*(s: pointer, v: cint) {.importc, cdecl.}
proc webkit_settings_set_enable_page_cache*(s: pointer, v: cint) {.importc, cdecl.}
proc webkit_settings_set_allow_file_access_from_file_urls*(s: pointer, v: cint) {.importc, cdecl.}
proc webkit_settings_set_allow_universal_access_from_file_urls*(s: pointer, v: cint) {.importc, cdecl.}
proc webkit_settings_set_enable_webgl*(s: pointer, v: cint) {.importc, cdecl.}
proc webkit_settings_set_enable_webaudio*(s: pointer, v: cint) {.importc, cdecl.}
proc webkit_settings_set_hardware_acceleration_policy*(s: pointer, v: cint) {.importc, cdecl.}
proc webkit_settings_set_enable_smooth_scrolling*(s: pointer, v: cint) {.importc, cdecl.}
proc webkit_user_script_new*(source: cstring, frames, time: cint, allow, deny: pointer): pointer {.importc, cdecl.}
proc webkit_user_content_manager_add_script*(m, script: pointer) {.importc, cdecl.}
proc webkit_user_content_manager_register_script_message_handler*(m: pointer, name: cstring): cint {.importc, cdecl.}
proc webkit_policy_decision_use*(d: pointer) {.importc, cdecl.}
proc webkit_policy_decision_ignore*(d: pointer) {.importc, cdecl.}
proc webkit_javascript_result_get_js_value*(r: pointer): pointer {.importc, cdecl.}

# JavaScriptCore
proc jsc_value_to_string*(v: pointer): cstring {.importc, cdecl.}
proc jsc_value_to_json*(v: pointer, indent: cuint): cstring {.importc, cdecl.}

# 001:9:1 la misura dello schermo, per non aprire una finestra più alta dello schermo (1366x768).
proc gdk_screen_get_default*(): pointer {.importc, cdecl.}
proc gdk_screen_get_width*(s: pointer): cint {.importc, cdecl.}
proc gdk_screen_get_height*(s: pointer): cint {.importc, cdecl.}
proc gtk_window_maximize*(w: pointer) {.importc, cdecl.}

@echo off
rem UProvaConsole.bat - W-9: refine nella console di Windows con l'LLM finto
rem Si lancia da una console (anche con ssh -tt) dopo aver copiato nella cartella B: bcdd_prova.exe, ULlmFinto.exe e prove; si digita: fra tre minuti circa, s, n, s.
set B=%USERPROFILE%\bcdd-build
set PATH=C:\Windows\system32;C:\Windows
rd /s /q %B%\wc 2>nul
rd /s /q %B%\wc.aux 2>nul
md %B%\wc
md %B%\wc.aux
copy /y %B%\prove\f2\refine\Luce.csc %B%\wc\Luce.csc >nul
set BCDD_LLM=%B%\ULlmFinto.exe
set BCDD_ATTESA_LLM=30
set BCDD_ORA=2026-10-16T18:00:00+02:00
set BCDD_REGISTRO=%B%\wc\chiamate.tsv
set BCDD_FINTO_CONTA=%B%\wc.aux\conta
set BCDD_FINTO_RISPOSTA=%B%\prove\f2\refine\risposte\buona.json
set BCDD_FINTO_RISPOSTA_2=%B%\prove\f2\refine\risposte\buona_seconda.json
cd /d %B%\wc
%B%\bcdd_prova.exe --lang it refine Luce.csc
echo codice=%errorlevel%

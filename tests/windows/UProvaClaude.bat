@echo off
rem 001:1:1 UProvaClaude.bat - ricerca di `claude` e avvio su Windows, senza chiamare il claude vero. Modalità Unattended.
rem 001:1:2 Uso: UProvaClaude.bat <cartella con bcdd.exe, llmfinto.exe, prove\> ; scrive tutto in <cartella>\t401 e stampa una riga PASS/FAIL per prova.
rem 001:1:3 Il finto `claude.cmd` e il finto `claude.exe` (copia di llmfinto.exe) scrivono gli argomenti ricevuti in ARGS_OUT.
setlocal EnableDelayedExpansion
set B=%~1
set T=%B%\t401
set SYS=C:\Windows\system32;C:\Windows
set RF=%B%\prove\f2\refine
rmdir /s /q "%T%" 2>nul
mkdir "%T%\fakebin" "%T%\home\.local\bin" "%T%\xdg"
(echo @echo off& echo "%%~dp0..\..\llmfinto.exe" %%*) > "%T%\fakebin\claude.cmd"
copy /y "%B%\llmfinto.exe" "%T%\home\.local\bin\claude.exe" >nul
set XDG_STATE_HOME=%T%\xdg
set BCDD_FINTO_RISPOSTA=%RF%\risposte\buona.json
set BCDD_FINTO_RISPOSTA_2=%RF%\risposte\buona_seconda.json
set OLDPATH=%PATH%
set OLDUP=%USERPROFILE%
rem --- 1: claude.cmd in testa al PATH (shim di npm)
call :pronto a
set PATH=%T%\fakebin;%SYS%
set USERPROFILE=%T%\home_vuota
set ARGS_OUT=%T%\a\args.txt
set BCDD_FINTO_CONTA=%T%\a\conta
"%B%\bcdd.exe" --lang it refine Luce.csc < "%RF%\T01_buona.ingresso" > "%T%\a\out.txt" 2> "%T%\a\err.txt"
set RC=!errorlevel!
call :giudica 1 "claude.cmd nel PATH: refine riuscito, 8 argomenti (il vuoto resta vuoto), file cambiato" a
rem --- 2: solo nella posizione standard (USERPROFILE finto)
call :pronto b
set PATH=%SYS%
set USERPROFILE=%T%\home
set ARGS_OUT=%T%\b\args.txt
set BCDD_FINTO_CONTA=%T%\b\conta
"%B%\bcdd.exe" --lang it refine Luce.csc < "%RF%\T01_buona.ingresso" > "%T%\b\out.txt" 2> "%T%\b\err.txt"
set RC=!errorlevel!
call :giudica 2 "claude.exe solo in USERPROFILE\.local\bin: refine riuscito" b
rem --- 3: da nessuna parte
call :pronto c
set PATH=%SYS%
set USERPROFILE=%T%\home_vuota
"%B%\bcdd.exe" --lang it refine Luce.csc < nul > "%T%\c\out.txt" 2> "%T%\c\err.txt"
set RC=!errorlevel!
echo --- 3: stderr e codice
type "%T%\c\err.txt"
echo rc=!RC!
fc /b "%T%\c\Luce.csc" "%RF%\Luce.csc" >nul && echo PASS 3 file invariato || echo FAIL 3 file cambiato
rem --- 4 e 5: scadenza, finto che dorme 30 s, limite 2 s; l'albero deve fermarsi
set BCDD_FINTO_CONTA=
set BCDD_ATTESA_LLM=2
set BCDD_FINTO_ATTESA=30
call :pronto d
set PATH=%T%\fakebin;%SYS%
set USERPROFILE=%T%\home_vuota
set BCDD_FINTO_PID=%T%\d\pid
"%B%\bcdd.exe" --lang it refine Luce.csc < nul > "%T%\d\out.txt" 2> "%T%\d\err.txt"
set RC=!errorlevel!
set /p PID=<"%T%\d\pid"
echo --- 4: scadenza con claude.cmd, rc=!RC! pid del finto !PID!
type "%T%\d\err.txt"
tasklist /fi "PID eq !PID!" | find "llmfinto" >nul && echo FAIL 4 il finto e ancora vivo || echo PASS 4 il finto e fermato
call :pronto e
set PATH=%SYS%
set USERPROFILE=%T%\home
set BCDD_FINTO_PID=%T%\e\pid
"%B%\bcdd.exe" --lang it refine Luce.csc < nul > "%T%\e\out.txt" 2> "%T%\e\err.txt"
set RC=!errorlevel!
set /p PID=<"%T%\e\pid"
echo --- 5: scadenza con claude.exe, rc=!RC! pid del finto !PID!
tasklist /fi "PID eq !PID!" | find "llmfinto" >nul && echo FAIL 5 il finto e ancora vivo || echo PASS 5 il finto e fermato
set PATH=%OLDPATH%
set USERPROFILE=%OLDUP%
goto :eof

:pronto
mkdir "%T%\%1"
copy /y "%RF%\Luce.csc" "%T%\%1\Luce.csc" >nul
pushd "%T%\%1"
exit /b 0

:giudica
popd
set OK=1
if not "!RC!"=="0" set OK=0
if not exist "%T%\%3\args.txt" set OK=0
fc /b "%T%\%3\Luce.csc" "%RF%\Luce.csc" >nul && set OK=0
echo --- %~1: %~2 [rc=!RC!]
type "%T%\%3\args.txt"
if "!OK!"=="1" (echo PASS %~1) else (echo FAIL %~1 & type "%T%\%3\err.txt")
exit /b 0

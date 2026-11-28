@echo off
rem 001:1:1 UProvaRinomina.bat - `bcdd rename` su Windows. Modalità Unattended. NON ancora eseguita: scritta da Linux.
rem 001:1:2 Uso: UProvaRinomina.bat <cartella con bcdd.exe e prove\rinomina\sintetica> ; lavora in <cartella>\t421 e stampa PASS/FAIL per prova.
rem 001:1:3 Prove: (1) rinomina con file rinominato e nessun file di lavoro; (2) rinomina delle sole maiuscole (Luce -> LUCE): il nome sul disco è LUCE.csc;
rem 001:1:4 (3) ritorno a Luce con la rinomina inversa; (4) il nome di Windows Lampadina.csc contro lampadina.csc (file_esiste).
setlocal EnableDelayedExpansion
set B=%~1
set T=%B%\t421
set S=%B%\prove\rinomina\sintetica
rmdir /s /q "%T%" 2>nul
mkdir "%T%"
xcopy /e /i /q "%S%" "%T%\w" >nul
cd /d "%T%\w"
rem --- 1: anteprima e scrittura
for /f "tokens=2 delims= " %%i in ('"%B%\bcdd.exe" --lang it rename luce\Luce.csc --dir comuni --dry-run csc Luce Lampadina ^| findstr /b "impronta:"') do set P=%%i
"%B%\bcdd.exe" --lang it rename luce\Luce.csc --dir comuni --expect !P! csc Luce Lampadina > "%T%\o1.txt" 2> "%T%\e1.txt"
set RC=!errorlevel!
if exist luce\Lampadina.csc if not exist luce\Luce.csc if !RC!==0 (echo PASS 1 rinomina scritta) else (echo FAIL 1 rc=!RC!)
if not exist luce\Lampadina.csc echo FAIL 1 manca luce\Lampadina.csc
dir /b /a luce comuni | findstr /i "rinomina bcdd-rinomina" >nul && echo FAIL 1b file di lavoro rimasti || echo PASS 1b nessun file di lavoro
rem --- 2: solo maiuscole
for /f "tokens=2 delims= " %%i in ('"%B%\bcdd.exe" --lang it rename luce\Lampadina.csc --dir comuni --dry-run csc Lampadina LAMPADINA ^| findstr /b "impronta:"') do set P=%%i
"%B%\bcdd.exe" --lang it rename luce\Lampadina.csc --dir comuni --expect !P! csc Lampadina LAMPADINA > "%T%\o2.txt" 2> "%T%\e2.txt"
set RC=!errorlevel!
dir /b luce | findstr /c:"LAMPADINA.csc" >nul && (if !RC!==0 (echo PASS 2 il nome sul disco e LAMPADINA.csc) else (echo FAIL 2 rc=!RC!)) || echo FAIL 2 nome sul disco diverso
rem --- 3: ritorno
for /f "tokens=2 delims= " %%i in ('"%B%\bcdd.exe" --lang it rename luce\LAMPADINA.csc --dir comuni --dry-run csc LAMPADINA Luce ^| findstr /b "impronta:"') do set P=%%i
"%B%\bcdd.exe" --lang it rename luce\LAMPADINA.csc --dir comuni --expect !P! --text all csc LAMPADINA Luce > "%T%\o3.txt" 2> "%T%\e3.txt"
set RC=!errorlevel!
dir /b luce | findstr /c:"Luce.csc" >nul && (if !RC!==0 (echo PASS 3 ritorno a Luce.csc) else (echo FAIL 3 rc=!RC!)) || echo FAIL 3 Luce.csc assente
rem --- 4: lo stesso nome con maiuscole diverse e un altro file
echo -- altro> luce\lampadina.csc
"%B%\bcdd.exe" --lang it rename luce\Luce.csc --dir comuni --dry-run csc Luce Lampadina > "%T%\o4.txt" 2> "%T%\e4.txt"
set RC=!errorlevel!
findstr /c:"che su Windows" "%T%\e4.txt" >nul && (if !RC!==1 (echo PASS 4 file_esiste) else (echo FAIL 4 rc=!RC!)) || echo FAIL 4 messaggio assente
endlocal

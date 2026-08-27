@echo off
rem ============================================================
rem  Build Araxia: Shadow of Etheros
rem  Works with EITHER fbc32.exe or fbc64.exe - music now uses
rem  Windows' built-in MIDI player (winmm), no DLLs needed.
rem  Edit the line below if your FreeBASIC is somewhere else.
rem ============================================================
set FBC=C:\FreeBASIC\fbc64.exe
if not exist %FBC% set FBC=C:\FreeBASIC\fbc32.exe

%FBC% -lang fblite -s gui ARAXIA.BAS
if errorlevel 1 (
    echo.
    echo *** Build failed - see errors above ***
    pause
    exit /b 1
)
echo.
echo Built ARAXIA.EXE successfully! Keep the data\ folder beside it.
pause

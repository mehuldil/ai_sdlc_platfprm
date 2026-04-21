@echo off
REM SDLC CLI — Windows wrapper (runs cli/sdlc.sh via Git Bash)
REM Usage: sdlc.bat ado show US-851789
REM Add this folder to PATH, or run: full\path\to\sdlc.bat ...

setlocal EnableDelayedExpansion

for %%i in ("%~dp0.") do set "SCRIPT_DIR=%%~fi"
set "SDLC_SH=%SCRIPT_DIR%\sdlc.sh"

if not exist "%SDLC_SH%" (
  echo Error: sdlc.sh not found at %SDLC_SH%
  exit /b 1
)

set "GIT_BASH="
for %%i in (
  "C:\Program Files\Git\bin\bash.exe"
  "C:\Program Files (x86)\Git\bin\bash.exe"
  "%LocalAppData%\Programs\Git\bin\bash.exe"
) do (
  if exist %%~i (
    set "GIT_BASH=%%~i"
    goto :found
  )
)

echo Error: Git for Windows not found. Install from https://git-scm.com/download/win
echo Then re-run this script.
exit /b 1

:found
REM UTF-8 so titles/descriptions print correctly in classic console
chcp 65001 >nul 2>&1

REM Avoid slow/hanging login: do not load ~/.bashrc or ~/.bash_profile
REM (otherwise batch can look "stuck" for many seconds with no output)
set "MSYS2_ARG_CONV_EXCL=*"

echo [sdlc] starting...
REM Run sdlc.sh as a script (do not use "source" — it breaks argv and main "$@")
"%GIT_BASH%" --noprofile --norc "%SDLC_SH%" %*
set ERR=%ERRORLEVEL%
if not %ERR%==0 echo [sdlc] exited with code %ERR%
exit /b %ERR%

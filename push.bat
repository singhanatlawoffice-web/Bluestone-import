@echo off
setlocal
cd /d "%~dp0"

echo ==========================================================
echo   Blue Stone Import - push to GitHub
echo   repo: singhanatlawoffice-web/Bluestone-import
echo ==========================================================
echo.

echo [0/6] remove 11 old example PDFs in ex\ (renamed set)
for %%F in (03-tisi-permit 04-import-declaration 05-tax-payment-slip 06-lao-shipping-bill 07-truck-list 08-car-manifest 09-car-manifest 09-factory-tax-invoice 10-factory-weigh-slip 10-lao-shipping-bill 11-truck-list) do (
  if exist "ex\%%F.pdf" (
    del /q "ex\%%F.pdf"
    echo    deleted %%F.pdf
  )
)
echo.

where git >nul 2>nul
if errorlevel 1 goto NOGIT

git --version
echo.

if exist ".git" goto HASGIT
echo [1/6] git init
git init -b main
if errorlevel 1 git init
goto REMOTE
:HASGIT
echo [1/6] repository already exists - skip init

:REMOTE
echo [2/6] set remote
git remote remove origin >nul 2>nul
git remote add origin https://github.com/singhanatlawoffice-web/Bluestone-import.git

echo [3/6] stage files
git add -A

echo [4/6] commit
git -c user.name="Blue Stone" -c user.email="singhanat.law.office@gmail.com" commit -m "update Blue Stone Import"

echo [5/6] branch main
git branch -M main

echo [6/6] push to GitHub
echo.
echo   First time: a GitHub window appears.
echo   Choose "Sign in with your browser" and log in.
echo   Upload is about 1 MB - usually 10 to 60 seconds.
echo.
git push -u origin main
if errorlevel 1 goto FAILED

echo.
echo [OK] Pushed to GitHub.
echo      Next: open https://vercel.com/new and import Bluestone-import
echo.
pause
exit /b 0

:FAILED
echo.
echo [X] Push failed. Copy the red text above and send it to Claude.
echo.
pause
exit /b 1

:NOGIT
echo [X] Git is not installed on this computer.
echo     Install it first: https://git-scm.com/download/win
echo     Click Next on every screen, then run this file again.
echo.
pause
exit /b 1

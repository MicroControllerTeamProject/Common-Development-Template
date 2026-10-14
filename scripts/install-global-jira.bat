@echo off
setlocal
where powershell.exe >nul 2>&1
if errorlevel 1 (
  echo ERROR: Windows PowerShell non trovato.
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-global-jira.ps1" %*
exit /b %ERRORLEVEL%

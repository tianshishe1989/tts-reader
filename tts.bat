@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
if "%~1"=="" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%tts.ps1"
) else if /i "%~1"=="-h" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Help '%SCRIPT_DIR%tts.ps1' -Detailed"
) else if /i "%~1"=="--help" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Help '%SCRIPT_DIR%tts.ps1' -Detailed"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%tts.ps1" %*
)
endlocal

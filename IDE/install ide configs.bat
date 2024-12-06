@echo off
echo Installing R configuration files...

set "DEST=%USERPROFILE%"
set "VSCODE_DEST=%APPDATA%\Code\User"

echo Copying .Renviron...
copy /Y "%~dp0.Renviron" "%DEST%\.Renviron"

echo Copying .Rprofile...
copy /Y "%~dp0.Rprofile" "%DEST%\.Rprofile"

echo Copying VS Code settings...
if not exist "%VSCODE_DEST%" mkdir "%VSCODE_DEST%"
copy /Y "%~dp0.vscode\settings.json" "%VSCODE_DEST%\settings.json"

echo Done! R configuration files have been installed to %DEST%
echo VS Code settings have been installed to %VSCODE_DEST%
pause
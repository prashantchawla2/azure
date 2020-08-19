@echo off

set SCRIPT_PATH="%~dp0"

rem // change to target directory to the current .bat file directory
pushd %SCRIPT_PATH%

powershell -file Upload-Templates.ps1 -storageAccountName %1 -directory %2

rem // Restore original directory
popd
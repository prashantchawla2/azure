@echo off

set SCRIPT_PATH="%~dp0"

rem // change to target directory to the current .bat file directory
pushd %SCRIPT_PATH%

powershell -file publish.ps1 -environment "dev"

rem // Restore original directory
popd

pause
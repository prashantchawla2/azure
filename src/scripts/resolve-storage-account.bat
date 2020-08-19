@echo off

set SCRIPT_PATH="%~dp0"

rem // change to target directory to the current .bat file directory
pushd %SCRIPT_PATH%

powershell -file GetOrCreate-DeploymentStorageAccount.ps1

rem // Restore original directory
popd
@echo off
setlocal

set SCRIPT_DIR=%~dp0
python "%SCRIPT_DIR%buildDatabase.py"

endlocal

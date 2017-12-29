@echo off

if "%OS%"=="Windows_NT" setlocal
if "%OS%"=="WINNT" setlocal
rem ---------------------------------------------------------------------------
rem Runner of MCRep Addon Builder
rem  >> run targets that are defined in Ant builder descriptor 
rem ---------------------------------------------------------------------------
cls
echo.


rem Find and set builder and project locations and resources
set _ADD_PATH=%~dp0
set _ENV_PATH=%_ADD_PATH%\tools
set _ANT_EXEC=%_ENV_PATH%\ant\bin\ant.bat
set _ANT_DESC=%_ADD_PATH%build.xml


rem Run command
%_ANT_EXEC% -buildfile %_ANT_DESC% xbt -Denv=windows
goto ok


:noTarget
echo No target specified..

:ok
rem End of program
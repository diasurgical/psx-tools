@echo off

echo Extracting all DIR/BIN files...
echo ==================================================

rem Main game files
call :EXTRACTBIN LUMP
rem English language
call :EXTRACTBIN STREAM1
rem French language
call :EXTRACTBIN STREAM2
rem German language
call :EXTRACTBIN STREAM3
rem Swedish language
call :EXTRACTBIN STREAM4
rem Japanese language
call :EXTRACTBIN STREAM5

echo.
echo Done.

pause
exit

:EXTRACTBIN
if exist %1.DIR (
echo Extracting %1.BIN...
mkdir %1 2>nul
cd %1
..\dstream.exe ..\%1.DIR ..\%1.BIN > ..\%1.log
cd ..
) else (
echo %1.DIR not found, skipping...
)
goto :EOF

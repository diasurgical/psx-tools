@echo off

echo Extracting all BOF/BNK files...
echo ==================================================

call :EXTRACTBNK LEVEL0
call :EXTRACTBNK LEVEL1
call :EXTRACTBNK LEVEL2
call :EXTRACTBNK LEVEL3
call :EXTRACTBNK LEVEL4
call :EXTRACTBNK LEVEL5
call :EXTRACTBNK LEVEL6
call :EXTRACTBNK LEVEL7
call :EXTRACTBNK LEVEL8
call :EXTRACTBNK LEVEL9
call :EXTRACTBNK LEVEL10
call :EXTRACTBNK LEVEL11
call :EXTRACTBNK LEVEL12
call :EXTRACTBNK LEVEL13
call :EXTRACTBNK LEVEL14
call :EXTRACTBNK LEVEL15
call :EXTRACTBNK LEVEL16
call :EXTRACTBNK LEVEL17

echo.
echo Done.

pause
exit

:EXTRACTBNK
if exist %1.BOF (
echo Extracting %1.BNK...
mkdir %1 2>nul
cd %1
..\dbank.exe ..\%1.BOF ..\%1.BNK > ..\%1.log
cd ..
) else (
echo %1.BOF not found, skipping...
)
goto :EOF

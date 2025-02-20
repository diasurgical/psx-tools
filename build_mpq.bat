@echo off

:: Variables created in for loops must be
:: referenced using !varname! instead of %varname%
setlocal enabledelayedexpansion

:: Get the directory of the script
:: %~dp0 is drive+path of %0 (e.g., C:\psx-tools\)
set "SCRIPTDIR=%~dp0"
set "PSXDIR=%SCRIPTDIR%ps1_assets"

set "DSTREAM=%SCRIPTDIR%dstream.exe"
set "DBANK=%SCRIPTDIR%dbank.exe"
set "VAG2WAV=%SCRIPTDIR%vag2wav.exe"

:: Create a temporary directory
set "TEMPDIR=%TEMP%\temp_dir_%RANDOM%"
mkdir "%TEMPDIR%"

pushd "%TEMPDIR%"

:: Iterate through each .dir file in the PSXDIR directory
for /r "%PSXDIR%" %%d in (*.dir) do (
    :: %%~nxd is filename+extension of %%d (e.g., stream1.dir)
    set "TMP=%%~nxd"
    mkdir "!TMP!"

    :: %%~dpnd is drive+path+filename of %%d, without extension (e.g., C:\Temp\stream1)
    set "DIR=%%d"
    set "BIN=%%~dpnd.bin"

    :: Run dstream.exe on the .dir file
    pushd "!TMP!"
    "%DSTREAM%" "!DIR!" "!BIN!" > nul
    popd

    :: Convert VAG files to WAV
    for %%v in (!TMP!\*.VAG) do (
        :: %%~dpnv is drive+path+filename of %%v, without extension (e.g., C:\Temp\stream1.dir\E0079)
        set "VAG=%%v"
        set "WAV=%%~dpnv.WAV"
        "%VAG2WAV%" "!VAG!" "!WAV!" > nul
    )

    :: (Optional) Handle .BOF to .BNK conversion (commented out in original)
    rem pushd "!TMP!"
    rem for %%b in (*.BOF) do (
    rem     set "BOF=%%b"
    rem     set "BNK=%%~dpnb.BNK"
    rem     "%DBANK%" "!BOF!" "!BNK!" > nul
    rem )
    rem popd
)

:: Handle MPQ file creation and stream file copying
for /d %%s in (stream*) do (
    :: %%~nxs is filename+extension of %%s (e.g., stream1.dir)
    rem Even though %%s is a path to a directory,
    rem the path will still be processed as though it is a path to a file
    set "STREAM=%%~nxs"
    mkdir "!STREAM!\mpq"

    :: Read from the .map file and copy files
    rem We are reading two tokens from each line in the .map file
    rem so those values are assigned to %%a and %%b respectively
    for /f "tokens=1,2" %%a in ('type "%SCRIPTDIR%%%~ns.map"') do (
        set "SRC=%%s\%%a"

        :: Convert forward slashes to backslashes
        set "DST=%%b"
        set "DST=!STREAM!\mpq\!DST:/=\!"

        :: %%~dpc is drive+path of %%c (e.g, C:\Temp\script1.dir\mpq\sfx\towners\)
        rem In order to parse drive+path from !DST!,
        rem we use a fake for loop to create variable %%c
        for /f "tokens=1 delims=" %%c in ("!DST!") do set "DSTDIR=%%~dpc"

        if not exist "!DSTDIR!" mkdir "!DSTDIR!"
        copy "!SRC!" "!DST!" > nul
    )

    :: %%~ns is the filename of %%s, without extension (e.g., stream1)
    set "MPQ=%%~ns.mpq"
    set "MPQ=%SCRIPTDIR%!MPQ!"

    :: Create the MPQ file
    smpq -M 1 -C none -c "!MPQ!"

    pushd "!STREAM!\mpq"
    for /r %%f in (*) do (
        :: %%f contains a full absolute path
        set FULL=%%f

        :: Use a fake for loop to create variable %%d with the value of !CD! (current directory),
        rem then use it to convert the full absolute path into a relative path
        for /f "tokens=1 delims=" %%d in ("!CD!") do set "REL=!FULL:%%d\=!"

        :: Add the file to the MPQ
        smpq -a -C none "!MPQ!" "!REL!"
    )
    popd
)

popd

:: Cleanup
rmdir /s /q "%TEMPDIR%"
endlocal

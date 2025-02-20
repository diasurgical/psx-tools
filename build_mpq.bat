@echo off

:: Variables created in for loops must be
:: referenced using !varname! instead of %varname%
setlocal enabledelayedexpansion

:: Get the directory of the script
:: %~dp0 is drive+path of %0
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
    :: %%~nxd is filename+extension of %%d
    set "TMP=%%~nxd"
    mkdir "!TMP!"

    :: Run dstream.exe on the .dir file
    :: %%~dpnd is drive+path+filename of %%d, without extension
    pushd "!TMP!"
    "%DSTREAM%" "%%d" "%%~dpnd.bin" > nul
    popd

    :: Convert VAG files to WAV
    :: %%~dnpv is drive+path+filename of %%v, without extension
    for /r "!TMP!" %%v in (*.VAG) do (
        "%VAG2WAV%" "%%v" "%%~dpnv.WAV" > nul
    )

    :: (Optional) Handle .BOF to .BNK conversion (commented out in original)
    rem for /r "%TEMPDIR%\!TMP!" %%b in (*.BOF) do (
    rem     pushd "!TMP!"
    rem     "%DBANK%" "%%b" "%%~dpnb.BNK" > nul
    rem     popd
    rem )
)

:: Handle MPQ file creation and stream file copying
for /d %%s in (stream*) do (
    :: %%~nxs is filename+extension of %%s
    :: Even though %%s is a path to a directory,
    :: the path will still be processed as though it is a path to a file
    set "STREAM=%%~nxs"
    mkdir "!STREAM!\mpq"

    :: Read from the .map file and copy files
    :: We are reading two tokens from each line in the .map file
    :: so those values are assigned to %%a and %%b respectively
    for /f "tokens=1,2" %%a in ('type "%SCRIPTDIR%!STREAM!.map"') do (
        :: Since %%~pb would expand the relative path using the current directory,
        :: we use a fake for loop to create variable %%c to get the path relative to !STREAM!\mpq instead
        for /f "tokens=1 delims=" %%c in ("!STREAM!\mpq\%%b") do mkdir "%%~dpc"
        copy "%%s\%%a" "!STREAM!\mpq\%%b" > nul
    )

    :: Create the MPQ file
    :: %%~ns is the filename of %%s, without extension
    set "MPQ=%SCRIPTDIR%%%~ns.mpq"
    smpq -M 1 -C none -c "!MPQ!"

    pushd "!STREAM!\mpq"
    for /r %%f in (*) do (
        :: %%f contains a full path,
        :: this hack uses %CD% (current directory)
        :: to convert it to a relative path
        set FULL=%%f
        smpq -a -C none "!MPQ!" "!FULL:%CD%\=!"
    )
    popd
)

popd

:: Cleanup
rmdir /s /q "%TEMPDIR%"
endlocal

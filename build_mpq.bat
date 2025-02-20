@echo off
setlocal enabledelayedexpansion

:: Get the directory of the script
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
    set "TMP=%%~nd"
    mkdir "!TMP!"

    :: Run dstream.exe on the .dir file
    pushd "!TMP!"
    "%DSTREAM%" "%%d" "%%~nd.bin" > nul
    popd

    :: Convert VAG files to WAV
    for /r "!TMP!" %%v in (*.VAG) do (
        "%VAG2WAV%" "%%v" "%%~nv.WAV" > nul
    )

    :: (Optional) Handle .BOF to .BNK conversion (commented out in original)
    rem for /r "%TEMPDIR%\!TMP!" %%b in (*.BOF) do (
    rem     "%DBANK%" "%%b" "%%~nb.BNK" > nul
    rem )
)

:: Handle MPQ file creation and stream file copying
for /r %%s in (stream*) do (
    set "STREAM=%%~ns"
    mkdir "!STREAM!\mpq"

    :: Read from the .map file and copy files
    for /f "tokens=1,2" %%a in ('type "%SCRIPTDIR%!STREAM!.map"') do (
        mkdir "!STREAM!\mpq\%%b"
        copy "%%s\%%a" "!STREAM!\mpq\%%b" > nul
    )

    :: Create the MPQ file
    set "MPQ=%SCRIPTDIR%!STREAM!.mpq"
    smpq -M 1 -C none -c "!MPQ!"

    pushd "!STREAM!\mpq"
    for /r %%f in (*) do (
        smpq -a -C none "!MPQ!" "%%f"
    )
    popd
)

popd

:: Cleanup
rmdir /s /q "%TEMPDIR%"
endlocal

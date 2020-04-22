# PSX-Tools
Tools for the Playstation port of Diablo.

### dstream
Dumps the contents of stream files (.DIR/.BIN pair). These contain all of the game data, including binary overlays.

Usage: dstream [dir] [bin] [types...]

- dir: .DIR index file.
- bin: .BIN data file.
- types: (optional) 3 letter file extension, up to 8 allowed. only extract files with these extenstions.

Two batch scripts are provided, **dump_all.bat** to extract all files and **dump_snd.bat** to only extract sound files (VAG and BANKS).

Note that both the US and European versions of Diablo contain English, French, German, and Swedish, but do not contain Japanese. The Japanese version is also needed to extract the Japanese files.

### dbank
Dumps the contents of sound bank files (.BOF/.BNK pair). These files are embedded in the stream files, and contain sound effects stored in VAG format.

Usage: dbank [bof] [bnk]

- bof: .BOF index file.
- bnk: .BNK data file.

A batch script **dump_all.bat** is provided to extract all bank files.

### vag2wav
Converts a PlayStation VAG sound file to a WAV file. VAG files are found in both the stream and bank files.

Usage: vag2wav [vag] [wav]

- vag: .VAG sound file.
- wav: .WAV sound file.

### textdump
Outputs strings from a game text data file as C/C++ quoted and escaped strings to stdout.

Usage: textdump [file]

- file: A game text data file, e.g.,  MAINTXT.ENG and MAINTXT.SWE.

## Compiling
A Visual Studio workspace is provided to compile the tools. Works with Visual C++ 5.0 and newer.
For POSIX-compatable OSes, a Makefile is provided.

## Creating Localized Audio MPQs
The bash-script `build_mpq.sh` creates patch MPQs for the PC version of Diablo where voice actors are speaking in
English (stream1.mpq), French (stream2.mpq), German (stream3.mpq), and Swedish (stream4.mpq). The script assumes
that the content of the PS1 CDROM is in the folder `ps1_assets`, and that `smpq` is installed on your system.
On Ubuntu-flavoured OSes, `smpq` can be installed by issuing the following command: `sudo apt-get install smpq`.

To use one of the patches with DevilutionX, rename it to `patch_rt.mpq` and place it in the same folder
as `diabdat.mpq`, then launch Diablo

# Credits
- **dstream** and **dbank** written by GalaXyHaXz
- **vag2wav** taken from the [psxsdk](https://github.com/ColdSauce/psxsdk)
- **textdump** written by John Törnblom
